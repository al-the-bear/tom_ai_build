/**
 * DocSpecs-conform Markdown codec for a TomSpecs document (SOM §11) — a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_document_markdown.dart`
 * (and the JavaScript `spec_document_markdown.js`).
 *
 * The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
 * the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is one markdown heading whose machine-readable identity is the
 * DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
 * human-readable Title-Case member name. Content values are **normal markdown
 * text** under their heading (no fences, no anchors); `@Form` sections use the
 * DocSpecs plain-text `FieldName: value` format; a list emits its `-LST`
 * **container heading** (the id the generated schema keys its container type by),
 * with the numbered items one level deeper, each carrying the item's
 * **anonymous positional** section id — the `@SectionIdPattern` resolved with
 * the 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`), else `<member>-<pos>`
 * for a pattern-less list. The container carries no content of its own; a
 * stored `@SectionId` is **not** surfaced in md (it lives losslessly in the
 * `*.tomspecs.yaml` format, SOM §12) so the generated schema's `pattern-check-id`
 * stays a clean `^<stem>-[0-9]+$`. Id-less members are **transparent** (mirroring
 * the schema generator , SOM §13): a transparent value member's text or form block
 * is the owner's body region, emitted without a heading and bound at its own
 * path; a transparent section/complex member never heads — its id-bearing
 * descendants hoist to the owner's child level (paths keep the transparent
 * segments). Section/complex headings without a field-level `@SectionId`
 * carry the target class's `@SectionId`.
 *
 * Escaping (SOM §11.3): a content line starting with `#` at column 0 is
 * emitted as `\#` (and a leading `\#`… run gains one more backslash), except
 * inside fenced code blocks, which shield their lines verbatim. Blank lines
 * inside a value are kept as written; parse trims each value of
 * leading/trailing blank lines only.
 *
 * The codec is free of any UI: it reads from / resolves against a
 * {@link SpecModel} (through the {@link buildSomMetaTree} metadata tree) and a
 * {@link SpecDocument}. {@link SpecDocumentMarkdown.parse} does **not** mutate
 * the document — it returns staged values keyed exactly like
 * {@link SpecDocument.toJson} plus a rejection report; {@link SpecDocument.applyMarkdownResult} applies
 * them. Anything that cannot be mapped — an unknown section id, a child
 * heading under a value leaf, orphaned text — is collected into
 * {@link SpecMarkdownResult.rejections} rather than dropped (SOM §11.7).
 */

import type { ListJson, SpecDocument } from './spec_document';
import type { SpecModel } from './spec_model';
import {
  SomFormFieldMeta,
  SomMetaKind,
  SomMetaNode,
  SomMetaTree,
  SomMetaKindValue,
} from './spec_meta';
import { buildSomMetaTree } from './spec_meta_bridge';
import { effectiveListItemSectionId } from './spec_section_id';
import {
  SpecDocumentSet,
  SpecDocumentSetError,
  type SpecSyncPair,
} from './spec_document_set';
import {
  _Navigation,
  _isLinkedParagraph,
  _kLinkedPlaceholder,
  _qualifyAnchor,
  _resolveLinkedPlaceholders,
} from './spec_document_markdown_linked';
import {
  _Generated,
  _kDerivedPlaceholder,
  _opensDerived,
  _resolveDerivedPlaceholders,
} from './spec_document_markdown_generated';

/** Why an imported Markdown block was rejected (SOM §11.7 rejection protocol). */
export const SpecMarkdownRejectReason = {
  /** The heading's section id does not resolve against the schema tree at its
   *  nesting position. */
  UNKNOWN_SECTION: 'unknownSection',
  /** A structurally impossible combination — e.g. a child heading nested
   *  under a value-leaf (content/scalar/enum) section. */
  KIND_MISMATCH: 'kindMismatch',
  /** Body text with no owning value slot — text before the document root
   *  heading. */
  ORPHAN_CONTENT: 'orphanContent',
  /** A value-leaf section heading with an empty body. */
  MISSING_VALUE: 'missingValue',
  /** A heading line without a parseable `<!--[id]-->` headline comment. */
  MALFORMED_HEADING: 'malformedHeading',
  /** A form-table row, a section-table row or a records column names no
   *  field the form declares. */
  UNKNOWN_FIELD: 'unknownField',
  /** A block that breaks the layout grammar: a table without its delimiter
   *  row or with a row of another cell count, a field given twice, a `refs` /
   *  `records` div beside other text or item headings or not holding what it
   *  should, an unclosed `refs` / `records` fence. The message says which. */
  MALFORMED_BLOCK: 'malformedBlock',
} as const;

export type SpecMarkdownRejectReasonValue =
  (typeof SpecMarkdownRejectReason)[keyof typeof SpecMarkdownRejectReason];

/**
 * One rejected block in a Markdown import (SOM §11.7). Reported, never silently
 * dropped: each carries the source `line`, the offending `anchor` (section
 * path or id), the `reason`, and a human-readable `message`.
 */
export class SpecMarkdownRejection {
  line: number;
  reason: SpecMarkdownRejectReasonValue;
  message: string;
  anchor: string | null;

  constructor(
    line: number,
    reason: SpecMarkdownRejectReasonValue,
    message: string,
    anchor: string | null = null,
  ) {
    this.line = line;
    this.reason = reason;
    this.message = message;
    this.anchor = anchor;
  }

  toString(): string {
    const anchor = this.anchor !== null ? ` (${this.anchor})` : '';
    return `line ${this.line}: ${this.reason}${anchor} — ${this.message}`;
  }
}

/**
 * The outcome of parsing a Markdown document (SOM §11.7): the staged values
 * plus every rejected block. The values are keyed exactly like
 * {@link SpecDocument.toJson} so a caller can merge them into a live document
 * as a full overwrite of the covered scope.
 */
export class SpecMarkdownResult {
  /** Content/scalar/enum leaf values (and section body text): path → value. */
  content: Record<string, string> = {};
  /** Form values: form path → (field name → value). */
  forms: Record<string, Record<string, string>> = {};
  /** List membership: list path → `{seq, items, ids?}` (the
   *  {@link SpecDocument.toJson} shape), recovered from the item headings. */
  lists: Record<string, ListJson> = {};
  /** Stored headlines recovered from headings (YRD3): path → headline.
   *  Only headings whose text differs from the effective default title are
   *  staged, so a default-rendered document stays byte-stable. */
  headlines: Record<string, string> = {};
  /** Stored codeSpec mappings (codespecs_mapping.md §9.2): path → the comma-joined list of
   *  CodeSpecs code locations parsed from the `codeSpec="…"` key in the
   *  heading comment. Staged whenever present (codeSpec has no default). */
  codeSpecs: Record<string, string> = {};
  /** Stored generation units (SOM §11.2): path → the comma-joined list of
   *  generation-unit ids parsed from the `units="…"` key in the heading
   *  comment. Staged whenever present (absent means the default). */
  units: Record<string, string> = {};
  /** Every rejected block, in source order. */
  rejections: SpecMarkdownRejection[] = [];
  /** The root segment(s) the import covers (the first segment of each
   *  accepted path) — the scope a full-overwrite apply purges first. */
  rootPrefixes: Set<string> = new Set();
  /** The rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): for
   *  every path whose text a rejected block stood in, the value with each
   *  such block written as a `rejected` div at its place. An import that
   *  accepts rejections ({@link SpecDocument.applyMarkdownResult} with
   *  `allowRejections`) writes these over {@link content}, so nothing written
   *  is lost; one that refuses them never reads it. An empty value removes the
   *  path's text: a list container's lines that went into a block its parent
   *  holds. Empty for a clean parse. */
  keptContent: Record<string, string> = {};
  /** The readable header line of a stripped rendition (SOM §11.1, `<!--
   *  readable: … -->`), as written, when the text carried one before its
   *  root heading; null otherwise. The parser skips the line and stages
   *  nothing from it; {@link SpecReadableHeader.parse} reads it. */
  readableHeader: string | null = null;

  /** Whether the parse was clean (no rejections). */
  get isClean(): boolean {
    return this.rejections.length === 0;
  }

  /** The number of leaf values successfully parsed (content + form fields). */
  get appliedCount(): number {
    let n = Object.keys(this.content).length;
    for (const m of Object.values(this.forms)) {
      n += Object.keys(m).length;
    }
    return n;
  }
}

/**
 * What {@link SpecDocument.fromMarkdown} hands back: the loaded document and
 * the parse report it came from. The rejected blocks are not in the document —
 * a caller shows them or refuses to save, since re-exporting the document drops
 * them for good.
 */
export class SpecMarkdownImport {
  /** The document holding every value the parse accepted. */
  readonly document: SpecDocument;

  /** The parse report, rejections included. */
  readonly result: SpecMarkdownResult;

  /** Both are set by the import that produced them. */
  constructor(document: SpecDocument, result: SpecMarkdownResult) {
    this.document = document;
    this.result = result;
  }

  /** The blocks the parse rejected, in source order; they are not in
   *  {@link document}. */
  get rejections(): SpecMarkdownRejection[] {
    return this.result.rejections;
  }
}

/**
 * Fence state machine (CommonMark-ish): a line whose first non-space run (up
 * to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
 * same-character run at least as long closes it.
 *
 * Public so other markdown-processing modules (the DocSpecs validator's
 * generic parser) share exactly the same fence semantics as this codec.
 */
export class MarkdownFenceTracker {
  private _char: string | null = null;
  private _len = 0;

  get inFence(): boolean {
    return this._char !== null;
  }

  feed(line: string): void {
    const m = /^ {0,3}(`{3,}|~{3,})/.exec(line);
    if (m === null) {
      return;
    }
    const run = m[1];
    if (this._char === null) {
      this._char = run.charAt(0);
      this._len = run.length;
    } else if (
      run.charAt(0) === this._char &&
      run.length >= this._len &&
      line.trim() === this._char.repeat(line.trim().length)
    ) {
      this._char = null;
      this._len = 0;
    }
  }
}

/** A tiny StringBuffer with Dart-style `writeln` semantics. */
class _Buffer {
  private _parts: string[] = [];

  writeln(text = ''): void {
    this._parts.push(text);
    this._parts.push('\n');
  }

  /** Appends text verbatim — no trailing newline. Used to splice an
   *  already-terminated buffer (a form's field block) into its owner. */
  write(text: string): void {
    this._parts.push(text);
  }

  toString(): string {
    return this._parts.join('');
  }
}

function _escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// A line the emitter must escape: an optional run of backslashes followed by
// `#` at column 0 (the escape itself must survive the round-trip).
const _ESCAPABLE = /^\\*#/;

// A line that would parse as a form-field label: `Word:` at column 0
// (optionally already space-prefixed — each emit pass adds one more space).
const _LABEL_SHAPED = /^ *[A-Za-z][A-Za-z0-9_]*:/;

const _FIELD_LABEL = /^([A-Za-z][A-Za-z0-9_]*): ?(.*)$/;
const _CONTINUATION_LABEL = /^ +[A-Za-z][A-Za-z0-9_]*:/;
const _ESCAPED_HEADING = /^\\+#/;

// A slot marker line (SOM §11.6): `<!-- slot: <rel> -->`, `<rel>` a body
// slot's path relative to its owner, or `.` for the owner itself.
const _SLOT_MARKER = /^<!-- slot: (\S+) -->$/;

// Reading view (SOM §11.4, §11.5): a value line shaped like a layout table
// header is escaped with one space on emit, and loses it on parse.
const _TABLE_HEADER_SHAPED =
  /^ *\|\s*(?:Section\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$/i;
const _ESCAPED_TABLE_HEADER =
  /^ +\|\s*(?:Section\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$/i;
// A line that starts a table row: `|` after up to three spaces.
const _TABLE_LINE = /^ {0,3}\|/;
const _DELIMITER_CELL = /^:?-+:?$/;
const _LINK_CELL = /^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$/;
const _LINK_TEXT = /\[([^\]]+)\]\([^)]*\)/;
const _LIST_DIV_OPEN = /^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$/;
const _DIV_CLOSE = /^:{3,}\s*$/;
// A section id as a reference holds it: upper-case segments joined by `-`.
const _ID_SHAPE = /^[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$/;
// A one-line value that Markdown reads as a block: a list item, a block quote
// (review comment and question blocks among them), a fence or a fenced div. A
// table needs two lines, so it is caught by the line break.
const _BLOCK_START = /^\s*([-*+]\s|\d+[.)]\s|>|```|~~~|:::)/;

/**
 * A line that is a block of its own, or would make the line above one, beyond
 * `_BLOCK_START`: a table row, an ATX heading, a setext underline or a
 * thematic break, an HTML block.
 */
const _WRAPPED_LINE_BLOCK = /^(?:\||#{1,6}(?:\s|$)|=+$|(?:[-*_]\s*){3,}$|<)/;

/**
 * The keys of `sorted` at or below `prefix`: a binary search to the first key
 * not before it, then the run sharing it as a prefix, so a large document is
 * not scanned once per list item.
 */
function _under(sorted: string[], prefix: string): string[] {
  let lo = 0;
  let hi = sorted.length;
  while (lo < hi) {
    const mid = (lo + hi) >> 1;
    if (sorted[mid] < prefix) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  const out: string[] = [];
  for (let i = lo; i < sorted.length && sorted[i].startsWith(prefix); i++) {
    const k = sorted[i];
    if (k.length === prefix.length || k.charCodeAt(prefix.length) === 0x2f) {
      out.push(k);
    }
  }
  return out;
}

/** Options of {@link SpecDocumentMarkdown}. */
export interface SpecDocumentMarkdownOptions {
  /**
   * The stem of the document set's file names (`tom_uam` of
   * `tom_uam.rsp.tomspecs.md`); absent writes `<root id>.tomspecs.md`.
   */
  fileStem?: string | null;
  /**
   * File names for roots that do not follow the
   * `<fileStem>.<root id>.tomspecs.md` convention, keyed by the root's section
   * id or type.
   */
  documentFiles?: Record<string, string>;
  /**
   * Writes every section deeper than level 6 as a styled-div heading
   * (`<div class="heading<N>" style="…">…</div>`, SOM §11.2); the parser
   * reads both forms whatever this says.
   */
  headingDivs?: boolean;
  /**
   * The readable header line of a stripped rendition, written after the
   * `docspec` declaration (SOM §11.1); the parser skips it.
   */
  readableHeader?: string | null;
  /**
   * Whether the `linked` marker is written after a markable heading (SOM
   * §11.11); a stripped rendition dropping `linked` turns it off. The parser
   * removes the marker either way. Default true.
   */
  linkedMarkers?: boolean;
  /**
   * Whether the generated parts (SOM §11.12) are written at their sections;
   * a stripped rendition dropping `derived` turns it off. The parser removes
   * them either way. Default true.
   */
  generatedParts?: boolean;
}

/**
 * Whether a code field's `value` is written as an inline code span: it is
 * non-empty and on one line. A multi-line value keeps the prose rendering — a
 * code span cannot cross a line break without markdown joining the lines.
 */
function _isInlineCode(value: string): boolean {
  return value !== '' && !value.includes('\n');
}

/**
 * `value` as a CommonMark inline code span: delimited by one backtick more
 * than the longest backtick run inside it, and padded with one space on each
 * side when it begins or ends with a backtick or a space — the padding
 * CommonMark strips again, so the span's content is exactly `value`.
 */
function _encodeCodeSpan(value: string): string {
  let longest = 0;
  for (const m of value.matchAll(/`+/g)) {
    if (m[0].length > longest) {
      longest = m[0].length;
    }
  }
  const fence = '`'.repeat(longest + 1);
  const pad = /^[` ]|[` ]$/.test(value) ? ' ' : '';
  return `${fence}${pad}${value}${pad}${fence}`;
}

/**
 * The inverse of the emitter's code span (SOM §11.4 rule 8): a single-line
 * `value` delimited by equal backtick runs loses them, and one padding space
 * on each side when both are present. Anything else — a value written by hand
 * without a span — is kept as written.
 */
function _decodeCodeSpan(value: string): string {
  if (value.includes('\n')) {
    return value;
  }
  const m = /^(`+)([\s\S]*[^`])(`+)$/.exec(value);
  if (m === null || m[1].length !== m[3].length) {
    return value;
  }
  const inner = m[2];
  if (
    inner.length >= 2 &&
    inner.startsWith(' ') &&
    inner.endsWith(' ') &&
    inner.trim() !== ''
  ) {
    return inner.substring(1, inner.length - 1);
  }
  return inner;
}

/** A body slot / effective child: the node plus its relative path. */
type _NodeRel = [SomMetaNode, string];

/**
 * Codec binding a {@link SpecModel} and a concrete {@link SpecDocument} to the
 * DocSpecs Markdown import/export format (SOM §11).
 */
export class SpecDocumentMarkdown {
  model: SpecModel;
  document: SpecDocument;
  // Metadata trees per root type, built lazily (the generated facades
  // will hand these in directly; until then the bridge derives them).
  private _trees: Map<string, SomMetaTree> = new Map();

  // Shared with the parser and the DocSpecs validator.
  static headingLine = /^(#+)\s+(.*)$/;
  /**
   * The heading HTML comment: `<!--[ID]--> Title` with an optional key=value
   * region between the id bracket and the closing `-->` (codespecs_mapping.md
   * §9.2 `codeSpec`). Group 1 = the section id, group 2 = the raw key=value
   * region (possibly empty), group 3 = the heading title. The middle group is
   * `[^>]*` — safe because the region's only values are quoted code locations /
   * identifiers, never a raw `>`.
   */
  static headlineComment = /^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$/;
  static docspecComment = /^<!--\s*docspec:.*-->\s*$/;
  /** Matches the readable header line of a stripped rendition (SOM §11.1). */
  static readableComment = /^<!--\s*readable:.*-->$/;
  /** The line a stripped rendition's appendix begins with (SOM §11.1):
   *  after a readable header, the parsers stop reading at it. */
  static appendixMarker = '<!-- readable-appendix -->';
  /** The fixed start of a styled-div heading's style, up to its indent. */
  static headingDivStyleStart = 'margin:1em 0 0.5em;padding-left:';
  /** A styled-div heading line (DocSpecs *Styled-div headings*): group 1 the
   *  level, group 2 the inner text. A level below 7 is content. */
  static headingDivLine = /^<div class="heading([0-9]+)"[^>]*>(.*)<\/div>$/;

  /** A styled-div heading's indent at `depth`: `(depth − 6) × 0.75`,
   *  written without a trailing `.0` (`0.75`, `1.5`, `3`). */
  static headingDivIndent(depth: number): string {
    const quarter = (depth - 6) * 3;
    const whole = Math.floor(quarter / 4);
    switch (quarter % 4) {
      case 0:
        return `${whole}`;
      case 1:
        return `${whole}.25`;
      case 2:
        return `${whole}.5`;
      default:
        return `${whole}.75`;
    }
  }

  /** `line` read as a styled-div heading: its level (7 or more) and its
   *  inner text with `&lt;`, `&gt;` and `&amp;` decoded, or null. */
  static headingDiv(line: string): [number, string] | null {
    const m = SpecDocumentMarkdown.headingDivLine.exec(line);
    if (m === null) return null;
    const level = parseInt(m[1], 10);
    if (level < 7) return null;
    return [
      level,
      m[2].replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&'),
    ];
  }

  /** Whether `line` would read as a styled-div heading after any run of
   *  backslashes (SOM §11.3): written `\<div …` as a `#` line is `\#`. */
  static escapableDiv(line: string): boolean {
    let k = 0;
    while (k < line.length && line.charCodeAt(k) === 0x5c) k++;
    return SpecDocumentMarkdown.headingDiv(line.slice(k).replace(/\s+$/, '')) !== null;
  }
  /**
   * A line that reads as the header of a form table or a section table (SOM
   * §11.4, §11.5): `| TomSpecField | Value |` or
   * `| Section | TomSpecField | Value |` at column 0, any case; group 1 is
   * `Section` for a section table. The header alone makes a table layout.
   */
  static layoutTableHeader =
    /^\|\s*(?:(Section)\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$/i;
  private static _codeSpecPattern =
    /codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))/;
  private static _unitsPattern =
    /(?:^|\s)units=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))/;

  /** See {@link SpecDocumentMarkdownOptions.fileStem}. */
  readonly fileStem: string | null;
  /** See {@link SpecDocumentMarkdownOptions.documentFiles}. */
  readonly documentFiles: Record<string, string>;
  /** See {@link SpecDocumentMarkdownOptions.headingDivs}. */
  readonly headingDivs: boolean;
  /** See {@link SpecDocumentMarkdownOptions.readableHeader}. */
  readonly readableHeader: string | null;
  /** The document's keys of one kind, sorted once per export for `_under`. */
  private _sortedKeys: Map<string, string[]> = new Map();

  private _sorted(kind: string, keys: Iterable<string>): string[] {
    let s = this._sortedKeys.get(kind);
    if (s === undefined) {
      s = Array.from(keys).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
      this._sortedKeys.set(kind, s);
    }
    return s;
  }
  /** The root the current export renders (the target of same-document links). */
  private _currentRoot: import('./spec_model').SpecRoot | null = null;
  /** See {@link SpecDocumentMarkdownOptions.linkedMarkers}. */
  readonly linkedMarkers: boolean;
  /** See {@link SpecDocumentMarkdownOptions.generatedParts}. */
  readonly generatedParts: boolean;
  /** The navigation of the root the current export renders (SOM §11.11). */
  private _nav: _Navigation | null = null;
  /** The generated parts of the root the current export renders (SOM §11.12). */
  private _gen: _Generated | null = null;

  /** Whether a generated part stands at or beneath `path` of the current
   *  export, which writes its heading even without a value. */
  private _forced(path: string): boolean {
    return this._gen !== null && this._gen.forces(path);
  }

  private _syncPairsCache: [string | null, readonly SpecSyncPair[]] | null = null;

  /**
   * The Blueprint's root and the model's anchor pairs, from the model alone;
   * none when the model's synced positions cannot be paired.
   *
   * @internal
   */
  get _syncPairs(): [string | null, readonly SpecSyncPair[]] {
    if (this._syncPairsCache === null) {
      try {
        const set = new SpecDocumentSet(this.model, []);
        this._syncPairsCache = [set.blueprintRoot, set.pairs];
      } catch (e) {
        if (!(e instanceof SpecDocumentSetError)) throw e;
        this._syncPairsCache = [null, []];
      }
    }
    return this._syncPairsCache;
  }

  /**
   * Whether `n` is a `@SameAs` copy: its member carries the annotation.
   *
   * @internal
   */
  _isCopyNode(n: SomMetaNode): boolean {
    const member = n.memberName;
    const parent = n.parent;
    if (member === null || parent === null) return false;
    const f = this.model.classNamed(parent.className)?.fieldNamed(member);
    return (f?.sameAs ?? null) !== null;
  }

  /**
   * The emitter writes the reading-view layout (SOM §11.4, §11.5): form tables
   * between `Field:` paragraphs, reference lines, record tables, section
   * tables and an HTML anchor in every heading. {@link parse} reads it and the
   * older layout of `Field:` lines alike.
   *
   * `options.fileStem` and `options.documentFiles` name the files
   * cross-document reference links point at: a root's rendition is
   * `<fileStem>.<root id in lower case>.tomspecs.md` unless `documentFiles`
   * maps the root (by section id or type) to another file name.
   */
  constructor(
    model: SpecModel,
    document: SpecDocument,
    options: SpecDocumentMarkdownOptions = {},
  ) {
    this.model = model;
    this.document = document;
    this.fileStem =
      options.fileStem !== undefined && options.fileStem !== null
        ? options.fileStem
        : null;
    this.documentFiles = options.documentFiles || {};
    this.headingDivs = options.headingDivs === true;
    this.readableHeader =
      options.readableHeader === undefined ? null : options.readableHeader;
    this.linkedMarkers = options.linkedMarkers !== false;
    this.generatedParts = options.generatedParts !== false;
  }

  /**
   * Extracts the `codeSpec="…"` value from a heading-comment key=value region
   * (codespecs_mapping.md §9.2), mirroring the tom_doc_scanner key=value
   * grammar. Returns the empty string when the region carries no `codeSpec`
   * key.
   */
  static codeSpecOf(region: string): string {
    const m = SpecDocumentMarkdown._codeSpecPattern.exec(region);
    if (m === null) {
      return '';
    }
    return (m[1] || m[2] || m[3] || '').trim();
  }

  /**
   * Extracts the `units="…"` value from a heading-comment key=value region
   * (SOM §11.2): the same quoting rules as {@link codeSpecOf} — double-quoted,
   * single-quoted or bare. The key must start the region or follow
   * whitespace, so a `units=` inside a quoted codeSpec value is not read as
   * the key. Returns the empty string when the region carries no `units` key.
   */
  static unitsOf(region: string): string {
    const m = SpecDocumentMarkdown._unitsPattern.exec(region);
    if (m === null) {
      return '';
    }
    return (m[1] || m[2] || m[3] || '').trim();
  }

  /** @internal */
  _treeFor(rootType: string): SomMetaTree {
    let tree = this._trees.get(rootType);
    if (!tree) {
      tree = buildSomMetaTree(this.model, rootType);
      this._trees.set(rootType, tree);
    }
    return tree;
  }

  // --- Naming helpers (SOM §11.2 / §11.5) ----------------------------------

  /**
   * `introductionAndScope` / `DemoItem` → `Introduction And Scope` /
   * `Demo Item`: a camel/Pascal-case identifier expanded into Title Case.
   */
  static titleCase(name: string): string {
    const words: string[] = [];
    let buf = '';
    for (const c of name) {
      const isUpper = c.toUpperCase() === c && c.toLowerCase() !== c;
      if (isUpper && buf) {
        words.push(buf);
        buf = '';
      }
      buf += c;
    }
    if (buf) {
      words.push(buf);
    }
    return words
      .map((w) => (w ? w.charAt(0).toUpperCase() + w.slice(1) : w))
      .join(' ');
  }

  /**
   * `Demo Document` → `demo-document`: the DocSpecs schema id of a
   * `@Document` name (SOM §11.1).
   */
  static kebabCase(title: string): string {
    return title
      .trim()
      .replace(/[\s_]+/g, '-')
      .replace(/[^A-Za-z0-9-]/g, '')
      .toLowerCase();
  }

  /**
   * The item heading title stem: Title-Case element class name with a
   * trailing `Entry` dropped (SOM §11.5, normative).
   */
  static itemTitleStem(elementClassName: string): string {
    let stem = elementClassName;
    if (stem.length > 5 && stem.endsWith('Entry')) {
      stem = stem.slice(0, -5);
    }
    return SpecDocumentMarkdown.titleCase(stem);
  }

  /**
   * The `FieldName` label written for a form field: the model field name with
   * the first letter upper-cased (SOM §11.4).
   */
  static formLabel(fieldName: string): string {
    if (!fieldName) {
      return fieldName;
    }
    return fieldName.charAt(0).toUpperCase() + fieldName.slice(1);
  }

  // --- Export (SOM §11.1–§11.8) --------------------------------------------

  /**
   * The section id written into (and matched from) a heading for `node`
   * (SOM §11.2/§11.8): the field-level `@SectionId` when present; for
   * section/complex nodes whose field carries none, the target **class**'s
   * `@SectionId` (the id the generated schema types are keyed by); else the path
   * segment (the member name).
   *
   * @internal
   */
  _headingIdOf(node: SomMetaNode): string {
    if (node.sectionId !== null && node.sectionId !== undefined) {
      return node.sectionId;
    }
    // The class id is the node's classSectionId, as the YAML key uses — never
    // `classNamed(node.className)`: a wrapper section (TextSection, …) carries
    // its OWNER's class name, and that lookup returned the owner's id.
    if (node.kind === SomMetaKind.SECTION || node.kind === SomMetaKind.COMPLEX) {
      if (node.classSectionId !== null && node.classSectionId !== undefined) {
        return node.classSectionId;
      }
    }
    return node.segment;
  }

  // --- Transparency (SOM §11.2, mirroring the schema generator , SOM §13) ---------
  //
  // The `docspecs-schema` generator (SOM §13) is normative: only **section-bearing**
  // nodes (those with a real `@SectionId`, field- or class-level) become
  // section types; id-less members are *transparent* — they are not sections
  // of their own. The markdown format mirrors that exactly:
  //
  //   * a transparent value member (content/scalar/enum/form without an id)
  //     is emitted headinglessly into its owner's *body region* (text, or a
  //     `FieldName: value` form block);
  //   * a transparent section/complex member gets no heading; its id-bearing
  //     descendants surface as the owner's direct child headings (the
  //     schema's "nearest section-bearing descendant" hoisting), with document
  //     paths still running through the transparent segments;
  //   * lists are never transparent — the `-LST` container always heads (its
  //     `@SectionId`, else the member segment) and its numbered items head one
  //     level deeper (pattern-numbered / `<member>-<pos>`).
  //
  // Principled canonicalisation losses (documented, accepted): multiple
  // transparent content members of one owner merge into the first on parse,
  // and a form-field label colliding across an owner's transparent forms
  // binds to the nearest form in slot order.

  /**
   * A section/complex member with no field- or class-level `@SectionId`:
   * heading-less, its children hoist to the owner.
   *
   * @internal
   */
  _isTransparentSection(n: SomMetaNode): boolean {
    if (n.kind !== SomMetaKind.SECTION && n.kind !== SomMetaKind.COMPLEX) {
      return false;
    }
    if (n.sectionId !== null && n.sectionId !== undefined) {
      return false;
    }
    // classSectionId, not classNamed(n.className): see _headingIdOf. A wrapper
    // section (TextSection, …) has neither id, so it is transparent (SOM §11.6).
    return n.classSectionId === null || n.classSectionId === undefined;
  }

  /**
   * A value member (content/scalar/enum/form) with no `@SectionId`: emitted
   * into the owner's body region instead of under an own heading.
   */
  static _isTransparentValue(n: SomMetaNode): boolean {
    return (
      (n.sectionId === null || n.sectionId === undefined) &&
      (n.kind === SomMetaKind.CONTENT ||
        n.kind === SomMetaKind.SCALAR ||
        n.kind === SomMetaKind.ENUM_VALUE ||
        n.kind === SomMetaKind.FORM)
    );
  }

  /**
   * The ordered *body slots* of `node`: every transparent value member and
   * every transparent section (whose own path may carry body text), collected
   * depth-first through transparent sections. These are the value positions
   * that share the owner's heading body.
   *
   * @internal
   */
  _bodySlots(node: SomMetaNode): _NodeRel[] {
    const out: _NodeRel[] = [];
    const collect = (n: SomMetaNode, prefix: string): void => {
      for (const c of n.children) {
        if (c.recursive) {
          continue;
        }
        const rel = prefix ? `${prefix}/${c.segment}` : c.segment;
        if (SpecDocumentMarkdown._isTransparentValue(c)) {
          out.push([c, rel]);
        } else if (this._isTransparentSection(c)) {
          out.push([c, rel]);
          collect(c, rel);
        }
      }
    };
    collect(node, '');
    return out;
  }

  /**
   * The ordered *effective children* of `node`: every section-bearing child
   * and every list, hoisted through transparent sections — exactly the
   * headings (and item-heading owners) the generated schema knows at this position.
   * Each entry carries the relative path from `node` (which runs through the
   * transparent segments).
   *
   * @internal
   */
  _effectiveChildren(node: SomMetaNode): _NodeRel[] {
    const out: _NodeRel[] = [];
    const collect = (n: SomMetaNode, prefix: string): void => {
      for (const c of n.children) {
        if (c.recursive) {
          continue;
        }
        const rel = prefix ? `${prefix}/${c.segment}` : c.segment;
        if (SpecDocumentMarkdown._isTransparentValue(c)) {
          continue; // body region
        }
        if (this._isTransparentSection(c)) {
          collect(c, rel);
        } else {
          out.push([c, rel]);
        }
      }
    };
    collect(node, '');
    return out;
  }

  /**
   * Renders the populated subtree of `root` as a DocSpecs-conform Markdown
   * document. Throws an {@link Error} on the two conditions this format cannot
   * represent without losing the round-trip: a content value containing an
   * unterminated fenced code block (which would shield the remainder of the
   * document from heading detection), and a form holding a field the model does
   * not declare (SOM §9, "Form-field order").
   */
  exportRoot(root: import('./spec_model').SpecRoot): string {
    return this.exportRootWithMap(root).markdown;
  }

  /**
   * {@link exportRoot}, plus the document path behind every heading it wrote —
   * the one place that knows which node a heading came from.
   *
   * A caller holding a rendition line (a DocSpecs schema finding, an editor
   * cursor) resolves it through {@link SpecMarkdownRendition.pathAtLine}
   * instead of re-deriving the renderer's layout. Section ids repeat across a
   * document, so the id alone does not say which node a line belongs to.
   */
  exportRootWithMap(
    root: import('./spec_model').SpecRoot,
  ): SpecMarkdownRendition {
    this._headingPaths = [];
    const markdown = this._exportRoot(root);
    const headingPaths = new Map<number, string>();
    const fence = new MarkdownFenceTracker();
    const lines = markdown.split('\n');
    let next = 0;
    for (let i = 0; i < lines.length && next < this._headingPaths.length; i++) {
      const line = lines[i];
      if (!fence.inFence && SpecDocumentMarkdown._emittedHeading.test(line)) {
        headingPaths.set(i + 1, this._headingPaths[next++]);
      }
      fence.feed(line);
    }
    return new SpecMarkdownRendition(markdown, headingPaths);
  }

  /**
   * A heading line as {@link _writeHeading} writes it. Body text never
   * matches: heading-like body lines are escaped (SOM §11.3) and fenced ones
   * skipped.
   */
  private static _emittedHeading =
    /^(?:#+ <!--\[|<div class="heading[0-9]+"[^>]*><!--\[)/;

  /** The paths of the headings written by the current export, in order. */
  private _headingPaths: string[] = [];

  private _exportRoot(root: import('./spec_model').SpecRoot): string {
    this._currentRoot = root;
    this._nav = new _Navigation(this, root);
    this._gen = this.generatedParts ? new _Generated(this._nav) : null;
    this._sortedKeys.clear();
    const tree = this._treeFor(root.type);
    const node = tree.root;
    const b = new _Buffer();
    b.writeln(
      `<!-- docspec: ${SpecDocumentMarkdown.kebabCase(root.title)}/` +
        `${this.model.modelVersionString} -->`,
    );
    if (this.readableHeader !== null) b.writeln(this.readableHeader);
    const rootSeg = node.segment;
    this._writeHeading(
      b,
      1,
      rootSeg,
      this.document.headline(rootSeg) || node.headline || root.title,
      rootSeg,
      this.document.codeSpec(rootSeg),
      this.document.units(rootSeg),
    );
    this._writeSectionBody(b, node, rootSeg);
    this._writeChildren(b, node, rootSeg, 2);
    this._nav = null;
    this._gen = null;
    return _resolveLinkedPlaceholders(_resolveDerivedPlaceholders(b.toString()));
  }

  /**
   * Writes the body region of a section heading: the section path's own
   * content value plus every transparent body slot (id-less content text and
   * form blocks, hoisted through transparent sections) in model order.
   *
   * A slot whose text the parser would otherwise bind elsewhere is preceded
   * by a slot marker (SOM §11.6): text after anything already written, a form
   * preamble that is not the region's default target, and a form whose labels
   * another form of the region shares. A body the parser reads correctly
   * without markers gets none, so such documents render as before.
   */
  private _writeSectionBody(b: _Buffer, node: SomMetaNode, path: string): void {
    const slots = this._bodySlots(node);
    if (slots.length === 0) {
      this._writeBody(b, this.document.content(path), path);
      return;
    }
    const formSlots = slots.filter(([s]) => s.kind === SomMetaKind.FORM);
    const hasForms = formSlots.length > 0;
    const defaultRel = this._defaultBodyRel(slots);
    let written = false;

    const marker = (rel: string): void => {
      b.writeln(`<!-- slot: ${rel} -->`);
      b.writeln();
    };

    const text = (
      rel: string,
      value: string | null | undefined,
      valuePath: string,
    ): void => {
      if (value === null || value === undefined) {
        return;
      }
      const prepared = this._prepareValue(value, valuePath);
      if (prepared === '') {
        return;
      }
      if (written || rel !== defaultRel) {
        marker(rel);
      }
      for (const line of prepared.split('\n')) {
        b.writeln(hasForms && _LABEL_SHAPED.test(line) ? ` ${line}` : line);
      }
      b.writeln();
      written = true;
    };

    text('.', this.document.content(path), path);
    for (const [slot, rel] of slots) {
      const slotPath = `${path}/${rel}`;
      if (slot.kind !== SomMetaKind.FORM) {
        text(rel, this.document.content(slotPath), slotPath);
        continue;
      }
      if (!this._formHasValues(slot, slotPath)) {
        continue;
      }
      const preamble = this.document.content(slotPath);
      const hasPreamble =
        preamble !== null &&
        preamble !== undefined &&
        this._prepareValue(preamble, slotPath) !== '';
      const fieldsOf = (n: SomMetaNode): SomFormFieldMeta[] =>
        n.form !== null && n.form !== undefined ? n.form.fields : [];
      const labels = new Set(fieldsOf(slot).map((f) => f.name.toLowerCase()));
      const collides = formSlots.some(
        ([o, oRel]) =>
          oRel !== rel &&
          fieldsOf(o).some((f) => labels.has(f.name.toLowerCase())),
      );
      const needsMarker = hasPreamble
        ? written || rel !== defaultRel
        : collides && (written || formSlots[0][1] !== rel);
      if (needsMarker) {
        marker(rel);
      }
      this._writeForm(b, slot, slotPath);
      written = true;
    }
  }

  /**
   * The body slot unmarked body text binds to on import (SOM §11.6): the
   * first non-form slot; with none, the form on the `content` member, else
   * the first form; with no slot at all the owner itself (`.`).
   *
   * @internal
   */
  /**
   * The item class's own form (its class-level `@Form`, a transparent body
   * slot), or `null` when the class carries none or more than one.
   */
  _itemForm(element: SomMetaNode): _NodeRel | null {
    const forms = this._bodySlots(element).filter(
      ([s]) => s.kind === SomMetaKind.FORM,
    );
    return forms.length === 1 ? forms[0] : null;
  }

  _defaultBodyRel(slots: _NodeRel[]): string {
    for (const [slot, rel] of slots) {
      if (slot.kind !== SomMetaKind.FORM) {
        return rel;
      }
    }
    for (const [, rel] of slots) {
      if (rel === 'content') {
        return rel;
      }
    }
    return slots.length === 0 ? '.' : slots[0][1];
  }

  private _writeChildren(
    b: _Buffer,
    node: SomMetaNode,
    basePath: string,
    depth: number,
  ): void {
    for (const [child, rel] of this._effectiveChildren(node)) {
      const path = `${basePath}/${rel}`;
      if (!this.document.hasValuesUnder(path) && !this._forced(path)) {
        continue;
      }
      const kind = child.kind;
      if (
        kind === SomMetaKind.CONTENT ||
        kind === SomMetaKind.SCALAR ||
        kind === SomMetaKind.ENUM_VALUE
      ) {
        const value = this.document.content(path);
        if (value === null && !this._forced(path)) {
          continue;
        }
        this._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          this.document.headline(path) || SpecDocumentMarkdown._titleOf(child),
          path,
          this.document.codeSpec(path),
          this.document.units(path),
        );
        this._writeBody(b, value, path);
      } else if (kind === SomMetaKind.FORM) {
        if (!this._formHasValues(child, path)) {
          continue;
        }
        this._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          this.document.headline(path) || SpecDocumentMarkdown._titleOf(child),
          path,
          this.document.codeSpec(path),
          this.document.units(path),
        );
        this._writeForm(b, child, path);
      } else if (kind === SomMetaKind.SECTION || kind === SomMetaKind.COMPLEX) {
        this._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          this.document.headline(path) || SpecDocumentMarkdown._titleOf(child),
          path,
          this.document.codeSpec(path),
          this.document.units(path),
          this._writeSectionTable(new _Buffer(), child, path),
        );
        this._writeSectionBody(b, child, path);
        if (!this._writeSectionTable(b, child, path)) {
          this._writeChildren(b, child, path, depth + 1);
        }
      } else if (kind === SomMetaKind.LIST) {
        this._writeListItems(b, child, path, depth);
      }
    }
  }

  /**
   * Emits list `node` as its `-LST` container heading (SOM §11.2/§11.5) at
   * `depth`, wrapping the numbered item headings one level deeper. The
   * container is a real section — the id the generated schema keys its container
   * type by — but carries **no content of its own** (schema content
   * min/max-text-length 0). Item identity is purely positional.
   */
  private _writeListItems(
    b: _Buffer,
    node: SomMetaNode,
    listPath: string,
    depth: number,
  ): void {
    const items = this.document.listItems(listPath);
    if (items.length === 0 && !this._forced(listPath)) return;
    // The container heading: its id is the list's `-LST` `@SectionId` (else the
    // member segment for a pattern-less list); its title is the member name.
    this._writeHeading(
      b,
      depth,
      this._headingIdOf(node),
      this.document.headline(listPath) || SpecDocumentMarkdown._titleOf(node),
      listPath,
      this.document.codeSpec(listPath),
      this.document.units(listPath),
    );
    // Item heading stem. Complex lists derive it from the element class name
    // (SOM §11.5, `Entry` dropped). A scalar list (shape 6) has no element class
    // — its element `typeName` is literally `String`, which would render
    // "String 1", "String 2". Derive the stem from the list FIELD instead (its
    // member name, Title-Cased like the container heading) so a populated
    // scalar list gets meaningful per-item headings (YRC5).
    const element = node.elementNode;
    const stem = SpecDocumentMarkdown._itemStemOf(node);
    const pattern =
      node.sectionIdPattern ||
      (element !== null && element !== undefined
        ? element.sectionIdPattern
        : null) ||
      null;
    if (
      this._writeReferenceLine(b, node, items, pattern) ||
      this._writeRecordTable(b, node, items, pattern)
    ) {
      return;
    }
    for (let i = 0; i < items.length; i++) {
      const itemPath = items[i];
      const pos = i + 1;
      // YRD3: a stored `@SectionId` (AA1 generated or a criterion-5 override)
      // IS the item's heading id — it round-trips through md as well as yaml.
      // Anonymous items fall back to the `@SectionIdPattern` resolved with the
      // 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`); pattern-less lists
      // fall back to `<member>-<pos>`. Items sit one level below the container.
      const itemId = effectiveListItemSectionId(
        this.document.itemSectionId(itemPath),
        pattern,
        pos,
        node.memberName || node.segment,
      );
      this._writeHeading(
        b,
        depth + 1,
        itemId,
        this.document.headline(itemPath) || `${stem} ${pos}`,
        itemPath,
        this.document.codeSpec(itemPath),
        this.document.units(itemPath),
        element !== null &&
          element !== undefined &&
          !element.recursive &&
          this._writeSectionTable(new _Buffer(), element, itemPath),
      );
      if (element === null || element === undefined) {
        // Scalar list: the item's value is its body.
        this._writeBody(b, this.document.content(itemPath) || '', itemPath);
      } else {
        this._writeSectionBody(b, element, itemPath);
        if (
          !element.recursive &&
          !this._writeSectionTable(b, element, itemPath)
        ) {
          this._writeChildren(b, element, itemPath, depth + 2);
        }
      }
    }
  }

  // --- Reading view: reference lines, record tables, section tables --------

  private _hasKeys(path: string): boolean {
    const codeSpec = this.document.codeSpec(path);
    const units = this.document.units(path);
    return (
      (codeSpec !== null && codeSpec !== undefined && codeSpec !== '') ||
      (units !== null && units !== undefined && units !== '')
    );
  }

  /**
   * The id of item `pos` (1-based) of `node` at `itemPath`, as its heading
   * carries it.
   */
  private _itemId(
    node: SomMetaNode,
    itemPath: string,
    pos: number,
    pattern: string | null,
  ): string {
    return effectiveListItemSectionId(
      this.document.itemSectionId(itemPath),
      pattern,
      pos,
      node.memberName || node.segment,
    );
  }

  /**
   * Whether the item at `itemPath` holds values only in its form at
   * `formPath`, all of them table cells: no preamble, no other content, form
   * or list, no `codeSpec` / `units`, no headline other than the item's own
   * when `allowHeadline`.
   */
  private _isFormOnlyItem(
    form: SomMetaNode,
    itemPath: string,
    formPath: string,
    allowHeadline: boolean,
  ): boolean {
    const doc = this.document;
    if (_under(this._sorted('content', doc.contentPaths), itemPath).length > 0) return false;
    if (_under(this._sorted('lists', doc.listPaths), itemPath).length > 0) return false;
    if (_under(this._sorted('units', doc.unitsPaths), itemPath).length > 0) return false;
    if (_under(this._sorted('forms', doc.formPaths), itemPath).some((k) => k !== formPath)) {
      return false;
    }
    for (const h of _under(this._sorted('headlines', doc.headlinePaths), itemPath)) {
      if (!allowHeadline || h !== itemPath) return false;
    }
    if (this._hasKeys(itemPath) || this._hasKeys(formPath)) return false;
    if (this._undeclaredFormFields(form, formPath).length > 0) return false;
    let any = false;
    for (const f of form.form !== null && form.form !== undefined
      ? form.form.fields
      : []) {
      const value = doc.formField(formPath, f.name);
      if (value === null) continue;
      if (!SpecDocumentMarkdown._isCellValue(f, value)) return false;
      any = true;
    }
    return any;
  }

  /**
   * A list whose every item holds only one reference id becomes one `refs`
   * div of links in list order (BP-11). All or nothing; returns whether it was
   * written.
   */
  private _writeReferenceLine(
    b: _Buffer,
    node: SomMetaNode,
    items: string[],
    pattern: string | null,
  ): boolean {
    const element = node.elementNode;
    if (element === null || element === undefined || element.recursive) {
      return false;
    }
    let ref: _NodeRel | null = null;
    for (const [child, rel] of this._effectiveChildren(element)) {
      const fields =
        child.form !== null && child.form !== undefined ? child.form.fields : [];
      if (
        child.kind === SomMetaKind.FORM &&
        fields.length === 1 &&
        fields[0].refersTo.length > 0 &&
        child.extra.some((e) => e.annotation === 'Reference')
      ) {
        ref = [child, rel];
        break;
      }
    }
    if (ref === null) return false;
    const field = ref[0].form!.fields[0];
    const doc = this.document;
    const links: string[] = [];
    for (let i = 0; i < items.length; i++) {
      const itemPath = items[i];
      const refPath = `${itemPath}/${ref[1]}`;
      const stored = doc.itemSectionId(itemPath);
      const positional = effectiveListItemSectionId(
        null,
        pattern,
        i + 1,
        node.memberName || node.segment,
      );
      if (stored !== null && stored !== undefined && stored !== positional) {
        return false;
      }
      if (
        _under(this._sorted('content', doc.contentPaths), itemPath).length > 0 ||
        _under(this._sorted('lists', doc.listPaths), itemPath).length > 0 ||
        _under(this._sorted('units', doc.unitsPaths), itemPath).length > 0 ||
        _under(this._sorted('headlines', doc.headlinePaths), itemPath).length > 0 ||
        _under(this._sorted('forms', doc.formPaths), itemPath).some((k) => k !== refPath) ||
        this._hasKeys(itemPath) ||
        this._hasKeys(refPath)
      ) {
        return false;
      }
      const names = [...doc.formFieldNames(refPath)];
      if (names.length !== 1 || names[0] !== field.name) return false;
      const id = (doc.formField(refPath, field.name) || '').trim();
      if (!_ID_SHAPE.test(id)) return false;
      links.push(this._link(field, id) || id);
    }
    b.writeln('::: {.refs}');
    b.writeln(links.join(', '));
    b.writeln(':::');
    b.writeln();
    return true;
  }

  /**
   * A list whose every item is one form of table cells becomes a `records`
   * div with one table: `Id` (with its anchor), `Title` when any item has a
   * stored headline, one column per declared field any item populates
   * (BP-11). All or nothing; returns whether it was written.
   */
  private _writeRecordTable(
    b: _Buffer,
    node: SomMetaNode,
    items: string[],
    pattern: string | null,
  ): boolean {
    const element = node.elementNode;
    if (element === null || element === undefined || element.recursive) {
      return false;
    }
    const formSlot = this._itemForm(element);
    if (formSlot === null) return false;
    const [form, rel] = formSlot;
    for (const itemPath of items) {
      if (!this._isFormOnlyItem(form, itemPath, `${itemPath}/${rel}`, true)) {
        return false;
      }
    }
    const doc = this.document;
    const declared =
      form.form !== null && form.form !== undefined ? form.form.fields : [];
    const columns = declared.filter((f) =>
      items.some((i) => doc.formField(`${i}/${rel}`, f.name) !== null),
    );
    const withTitle = items.some((i) => doc.headline(i) !== null);
    const header = [
      'Id',
      ...(withTitle ? ['Title'] : []),
      ...columns.map((f) => SpecDocumentMarkdown.formLabel(f.name)),
    ];
    b.writeln('::: {.records}');
    b.writeln(`| ${header.join(' | ')} |`);
    b.writeln(`| ${header.map(() => '---').join(' | ')} |`);
    for (let i = 0; i < items.length; i++) {
      const itemPath = items[i];
      const id = this._itemId(node, itemPath, i + 1, pattern);
      // A summary naming its detail element by its own id links it from
      // the Id cell (SOM §11.5, §11.11).
      const listPath = itemPath.substring(0, itemPath.lastIndexOf('-'));
      const cells = [
        this._nav?.summaryIdCell(itemPath, listPath, id) ??
          `<a id="${this._nav?.anchorOf(itemPath) ?? id}"></a>${id}`,
      ];
      if (withTitle) {
        cells.push(
          (doc.headline(itemPath) || '')
            .replace(/\n/g, '<br>')
            .replace(/\|/g, '\\|'),
        );
      }
      for (const f of columns) {
        const v = doc.formField(`${itemPath}/${rel}`, f.name);
        cells.push(v === null ? '' : this._linkedCellText(f, v));
      }
      b.writeln(`| ${cells.join(' | ')} |`);
    }
    b.writeln(':::');
    b.writeln();
    return true;
  }

  /**
   * A section whose populated children are all single forms of table cells
   * with default headlines (or lists of such single-form items) becomes one
   * `| Section | TomSpecField | Value |` table after its own body; the
   * children's headings are not written (DP-part-renditions-4). All or
   * nothing; returns whether it was written.
   */
  /** @internal */
  _writeSectionTable(
    b: _Buffer,
    node: SomMetaNode,
    path: string,
  ): boolean {
    const doc = this.document;
    const rows: string[] = [];
    let children = 0;
    const addRows = (
      sectionCell: string,
      form: SomMetaNode,
      formPath: string,
    ): void => {
      let first = true;
      for (const f of form.form !== null && form.form !== undefined
        ? form.form.fields
        : []) {
        const value = doc.formField(formPath, f.name);
        if (value === null) continue;
        rows.push(
          `| ${first ? sectionCell : ''} | ` +
            `${SpecDocumentMarkdown.formLabel(f.name)} | ` +
            `${this._linkedCellText(f, value)} |`,
        );
        first = false;
      }
    };

    for (const [child, rel] of this._effectiveChildren(node)) {
      const childPath = `${path}/${rel}`;
      if (!doc.hasValuesUnder(childPath)) continue;
      children++;
      const childId = this._headingIdOf(child);
      if (child.kind === SomMetaKind.FORM) {
        if (!this._isFormOnlyItem(child, childPath, childPath, false)) {
          return false;
        }
        addRows(
          `<a id="${this._nav?.anchorOf(childPath) ?? childId}"></a>${childId}`,
          child,
          childPath,
        );
      } else if (child.kind === SomMetaKind.LIST) {
        const element = child.elementNode;
        if (element === null || element === undefined || element.recursive) {
          return false;
        }
        if (doc.headline(childPath) !== null || this._hasKeys(childPath)) {
          return false;
        }
        const formSlot = this._itemForm(element);
        if (formSlot === null) return false;
        const [form, rel2] = formSlot;
        const items = doc.listItems(childPath);
        const pattern = child.sectionIdPattern || element.sectionIdPattern || null;
        for (let i = 0; i < items.length; i++) {
          const itemPath = items[i];
          if (
            !this._isFormOnlyItem(form, itemPath, `${itemPath}/${rel2}`, false)
          ) {
            return false;
          }
          const itemId = this._itemId(child, itemPath, i + 1, pattern);
          addRows(
            `<a id="${this._nav?.anchorOf(itemPath) ?? itemId}"></a>` +
              `${childId} / ${itemId}`,
            form,
            `${itemPath}/${rel2}`,
          );
        }
      } else {
        return false;
      }
    }
    if (children === 0 || rows.length === 0) return false;
    b.writeln('| Section | TomSpecField | Value |');
    b.writeln('| --- | --- | --- |');
    for (const row of rows) {
      b.writeln(row);
    }
    b.writeln();
    return true;
  }

  /**
   * `value` as a table cell, every reference id of a `refersTo` field written
   * as a link to its section (reading view, DI-14).
   */
  /** @internal */
  _linkedCellText(f: SomFormFieldMeta, value: string): string {
    if (f.refersTo.length === 0 || f.code) {
      return SpecDocumentMarkdown._cellText(f, value);
    }
    value = SpecDocumentMarkdown.wrappedParagraphJoined(value) ?? value;
    const ids = value.split(',').map((v) => v.trim());
    if (ids.length === 0 || !ids.every((id) => _ID_SHAPE.test(id))) {
      return SpecDocumentMarkdown._cellText(f, value);
    }
    const links = ids.map((id) => this._link(f, id));
    if (links.some((l) => l === null)) {
      return SpecDocumentMarkdown._cellText(f, value);
    }
    return links.join(', ');
  }

  /**
   * `[ID](<file>#ID)` for a reference id of form field `f`, `[ID](#ID)` when
   * the target lives in the document being rendered; `null` when no target of
   * `f` names a section id (`<SECTIONID>.@sectionId`), which has no anchor.
   */
  private _link(f: SomFormFieldMeta, id: string): string | null {
    const classIds = f.refersTo
      .filter((t) => t.endsWith('.@sectionId'))
      .map((t) => t.substring(0, t.length - 11));
    if (classIds.length === 0) return null;
    const current = this._currentRoot;
    for (const classId of classIds) {
      const className = this._classBySectionId(classId);
      if (
        className !== null &&
        current !== null &&
        this._reachedBy(current).has(className)
      ) {
        return `[${id}](#${id})`;
      }
    }
    const file = this._fileFor(this._classBySectionId(classIds[0]));
    return file === null ? `[${id}](#${id})` : `[${id}](${file}#${id})`;
  }

  private _classBySectionId(sectionId: string): string | null {
    for (const c of this.model.classes.values()) {
      if (c.sectionId === sectionId) return c.name;
    }
    return null;
  }

  private _reach = new Map<string, Set<string>>();

  /** The class names the meta tree of `root` reaches. */
  private _reachedBy(root: import('./spec_model').SpecRoot): Set<string> {
    let names = this._reach.get(root.type);
    if (names !== undefined) return names;
    const found = new Set<string>();
    const walk = (n: SomMetaNode): void => {
      found.add(n.className);
      if (n.recursive) return;
      for (const c of n.children) {
        walk(c);
      }
      const e = n.elementNode;
      if (e !== null && e !== undefined) walk(e);
    };
    walk(this._treeFor(root.type).root);
    names = found;
    this._reach.set(root.type, names);
    return names;
  }

  /**
   * The rendition file of the root a reference to `className` points into:
   * the root other than the current one that reaches the class, the most
   * specific (fewest classes) first, so a detailed document wins over a
   * projection such as the Solution Blueprint. The CodeSpecs projection is
   * no document anyone renders, so it is never a target.
   */
  private _fileFor(className: string | null): string | null {
    if (className === null) return null;
    const currentType =
      this._currentRoot !== null ? this._currentRoot.type : null;
    const candidates = this.model.roots
      .filter(
        (r) =>
          r.type !== currentType &&
          !(this.model.classNamed(r.type)?.isCodeSpecsProjection ?? false) &&
          this._reachedBy(r).has(className),
      )
      .sort((a, b) => this._reachedBy(a).size - this._reachedBy(b).size);
    if (candidates.length === 0) return null;
    return this._fileOfRoot(candidates[0]);
  }

  /**
   * The rendition file of `root`: `<fileStem>.<root id>.tomspecs.md`, or the
   * name {@link documentFiles} gives it.
   *
   * @internal
   */
  _fileOfRoot(root: import('./spec_model').SpecRoot): string {
    const id = root.sectionId !== null ? root.sectionId : root.type;
    const mapped =
      this.documentFiles[id] !== undefined
        ? this.documentFiles[id]
        : this.documentFiles[root.type];
    if (mapped !== undefined) return mapped;
    const stem = this.fileStem;
    const name = `${id.toLowerCase()}.tomspecs.md`;
    return stem === null || stem === '' ? name : `${stem}.${name}`;
  }

  /**
   * Whether `value` of form field `f` is written as a table row (reading
   * view, part *What the model says about reading*): not when the model flags
   * the field `multiParagraph`, nor when the value holds a line break other
   * than the soft breaks of one wrapped paragraph (`wrappedParagraphJoined`;
   * a `code` value keeps every line break), is a block of Markdown, holds a
   * backslash directly before `|`, or holds `<!--`. There is no length limit.
   */
  private static _isCellValue(f: SomFormFieldMeta, value: string): boolean {
    if (f.multiParagraph) return false;
    if (value.includes('\\|') || value.includes('<!--')) return false;
    if (
      value.includes('\n') &&
      (f.code || SpecDocumentMarkdown.wrappedParagraphJoined(value) === null)
    ) {
      return false;
    }
    return !_BLOCK_START.test(value);
  }

  /**
   * `value` on one line when it is one paragraph wrapped over several lines
   * — no blank line, and no line that Markdown reads as a block or a block's
   * start (a list item, a quote, a fence, a fenced div, a table row, a
   * heading, a setext underline or a thematic break), that ends in a hard
   * break (a trailing backslash or spaces) or that starts with a space: its
   * soft line breaks, which Markdown reads as spaces, become spaces (SOM
   * §11.4). Null for any other value, a one-line value among them.
   */
  static wrappedParagraphJoined(value: string): string | null {
    if (!value.includes('\n')) return null;
    const lines = value.split('\n');
    for (const l of lines) {
      if (
        l === '' ||
        l !== l.trim() ||
        l.endsWith('\\') ||
        _BLOCK_START.test(l) ||
        _WRAPPED_LINE_BLOCK.test(l)
      ) {
        return null;
      }
    }
    return lines.join(' ');
  }

  /**
   * The table cell for `value`: a `code: true` value as its inline code span,
   * every `|` written `\|`.
   */
  private static _cellText(f: SomFormFieldMeta, value: string): string {
    value = SpecDocumentMarkdown.wrappedParagraphJoined(value) ?? value;
    const text =
      f.code && _isInlineCode(value) ? _encodeCodeSpan(value) : value;
    return text.replace(/\|/g, '\\|');
  }

  /**
   * The stored field names at form `path` that `node` does not declare, sorted
   * (SOM §9, "Form-field order").
   *
   * The emit walk is meta-driven — it iterates the model's declared fields —
   * so a stored field the model does not know is invisible to it and cannot be
   * dropped *loudly*. Seeing it at all needs this deliberate reverse check:
   * store keys minus meta keys, which is the check the yaml codec already has
   * (SOM §12.8).
   */
  private _undeclaredFormFields(node: SomMetaNode, path: string): string[] {
    const fields =
      node.form !== null && node.form !== undefined ? node.form.fields : [];
    const declared = new Set(fields.map((f) => f.name));
    const out: string[] = [];
    for (const name of this.document.formFieldNames(path)) {
      if (!declared.has(name)) {
        out.push(name);
      }
    }
    out.sort();
    return out;
  }

  /**
   * Throws when the form at `path` holds a field the model does not declare
   * (SOM §9, "Form-field order" — md refuses, matching yaml).
   *
   * Emitting it is impossible: the DocSpecs markdown grammar has no spelling
   * for a field outside the model, and omitting it would lose a stored value in
   * a file that looks complete. On import a partial document is normal and the
   * codec reports-and-skips (SOM §11.7); on export the document is complete and
   * a lossy rendering is a trap, so the codec refuses instead.
   */
  private _checkFormDeclared(node: SomMetaNode, path: string): void {
    const undeclared = this._undeclaredFormFields(node, path);
    if (undeclared.length === 0) {
      return;
    }
    throw new Error(
      `form at "${path}" holds a field "${undeclared[0]}" unknown to the ` +
        'model; it cannot be represented in the DocSpecs markdown format',
    );
  }

  /**
   * Whether the `@Form` node at `path` has anything to emit: its preamble
   * content (SOM §11.4 rule 7 — the DocSpecs `${text[]}` region), or any
   * populated field.
   *
   * An undeclared stored field counts too — not because it can be emitted, but
   * so the section is still *visited* and {@link _writeForm} refuses. Without
   * it a form holding nothing but undeclared fields would vanish unseen, which
   * is the silent drop this check exists to prevent.
   */
  private _formHasValues(node: SomMetaNode, path: string): boolean {
    if (this.document.hasContent(path)) {
      return true;
    }
    const fields =
      node.form !== null && node.form !== undefined ? node.form.fields : [];
    for (const f of fields) {
      if (this.document.formField(path, f.name) !== null) {
        return true;
      }
    }
    return this._undeclaredFormFields(node, path).length > 0;
  }

  /**
   * Writes a `@Form` section body (SOM §11.4): the preamble, then the
   * declared fields in model order — each run of consecutive cell values one
   * `| TomSpecField | Value |` table, each paragraph value a `Field:` group at
   * its place (table – text – table). Groups are one blank line apart. A value
   * line that would read as a table header is escaped by
   * {@link _prepareValue}. Throws when the form holds a field the model does
   * not declare.
   */
  private _writeForm(b: _Buffer, node: SomMetaNode, path: string): void {
    this._checkFormDeclared(node, path);
    const fields =
      node.form !== null && node.form !== undefined ? node.form.fields : [];
    const groups: string[][] = [];
    let table: string[] | null = null;
    for (const f of fields) {
      const value = this.document.formField(path, f.name);
      if (value === null) {
        continue;
      }
      const label = SpecDocumentMarkdown.formLabel(f.name);
      if (SpecDocumentMarkdown._isCellValue(f, value)) {
        if (table === null) {
          table = ['| TomSpecField | Value |', '| --- | --- |'];
          groups.push(table);
        }
        table.push(`| ${label} | ${this._linkedCellText(f, value)} |`);
        continue;
      }
      table = null;
      // SOM §11.4 rule 8: a single-line code value is written as an inline
      // code span, so markdown leaves it literal (`](` is not a link).
      const lines =
        f.code && _isInlineCode(value)
          ? [_encodeCodeSpan(value)]
          : this._prepareValue(value, path).split('\n');
      groups.push([
        `${label}: ${lines[0]}`,
        // Any continuation line that could be mistaken for a field-label line
        // gains one leading space; parse strips it.
        ...lines
          .slice(1)
          .map((line) => (_LABEL_SHAPED.test(line) ? ` ${line}` : line)),
      ]);
    }

    const preamble = this.document.content(path);
    if (preamble !== null && preamble !== undefined) {
      const prepared = this._prepareValue(preamble, path);
      if (prepared !== '') {
        // Every preamble line gets the same label-shaped escape a continuation
        // line gets: the parser reaches a field label before it knows which
        // text is preamble, so a `Word:` line at column 0 would mis-split.
        for (const line of prepared.split('\n')) {
          b.writeln(_LABEL_SHAPED.test(line) ? ` ${line}` : line);
        }
        if (groups.length > 0) {
          b.writeln();
        }
      }
    }
    for (let i = 0; i < groups.length; i++) {
      if (i > 0) {
        b.writeln();
      }
      for (const line of groups[i]) {
        b.writeln(line);
      }
    }
    b.writeln();
  }

  /**
   * `## <!--[ID]--> Title` at `depth`. SOM §11.2 is normative — heading level
   * = 1 + section depth, **uncapped**: deep models (the Solution Blueprint
   * nests past markdown's native 6 levels) keep their structure; the parse
   * grammar accepts `#{7,}` accordingly. Capping would silently flatten
   * distinct nesting positions into siblings and break schema validation.
   *
   * When `codeSpec` is non-empty it is emitted as a `codeSpec="…"` key inside
   * the same headline comment (codespecs_mapping.md §9.2): `## <!--[ID]
   * codeSpec="A,B"--> Title`. When `units` is non-empty it follows as a
   * second key, `units="…"`, after `codeSpec` (SOM §11.2).
   */
  private _writeHeading(
    b: _Buffer,
    depth: number,
    id: string,
    title: string,
    path: string,
    codeSpec: string | null = null,
    units: string | null = null,
    sectionTable = false,
  ): void {
    this._headingPaths.push(path);
    // SOM §11.2: below a list item or a `@SameAs` copy the anchor is
    // qualified; SOM §11.11: the `linked` marker follows the heading.
    const nav = this._nav;
    const anchor = nav !== null ? nav.anchorOf(path) : id;
    // SOM §11.12: a generated table opens its section, after the marker.
    const derived = (): void => {
      const gen = this._gen;
      if (gen === null || !gen.isPlace(path)) return;
      const block = gen.blocks.get(path);
      if (block !== undefined) {
        for (const line of block) b.writeln(line);
      } else {
        b.writeln(_kDerivedPlaceholder);
      }
      b.writeln();
    };
    const marker = (): void => {
      if (nav === null || !this.linkedMarkers) return;
      const entries = nav.entries(path, sectionTable);
      if (entries.length > 0) {
        b.writeln(`[${entries.join('; ')}]{.linked}`);
        b.writeln();
      } else if (nav.markable(path)) {
        b.writeln(_kLinkedPlaceholder);
        b.writeln();
      }
    };
    let code =
      codeSpec !== null && codeSpec !== undefined && codeSpec !== ''
        ? ` codeSpec="${codeSpec}"`
        : '';
    if (units !== null && units !== undefined && units !== '') {
      code += ` units="${units}"`;
    }
    // A heading is one line: a stored headline's line breaks travel as `<br>`.
    // Reading view (DI-3): the section id as an HTML anchor after the id
    // comment and its keys, so `#<ID>` links jump in every viewer.
    if (this.headingDivs && depth > 6) {
      // A styled-div heading (SOM §11.2, DocSpecs *Styled-div headings*): one
      // line, the title HTML-escaped, the indent growing with the depth.
      const escaped = title
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/\n/g, '<br>');
      b.writeln(
        `<div class="heading${depth}" style="${SpecDocumentMarkdown.headingDivStyleStart}` +
          `${SpecDocumentMarkdown.headingDivIndent(depth)}em;font-weight:bold">` +
          `<!--[${id}]${code}--> <a id="${anchor}"></a> ${escaped}</div>`,
      );
      b.writeln();
      marker();
      derived();
      return;
    }
    b.writeln(
      `${'#'.repeat(depth)} <!--[${id}]${code}--> <a id="${anchor}"></a> ` +
        title.replace(/\n/g, '<br>'),
    );
    b.writeln();
    marker();
    derived();
  }

  /**
   * Writes `value` as a section body followed by a blank line; no-op for
   * `null`/blank values.
   */
  private _writeBody(b: _Buffer, value: string | null, path: string): void {
    if (value === null || value === undefined) {
      return;
    }
    const prepared = this._prepareValue(value, path);
    if (!prepared) {
      return;
    }
    b.writeln(prepared);
    b.writeln();
  }

  /**
   * Emit-side value normalisation (SOM §11.3): blank lines are kept as written;
   * trim leading/trailing blank lines, escape heading-like lines and lines
   * shaped like a layout table header (SOM §11.4) outside fences. Throws an
   * {@link Error} for an unterminated fence.
   */
  private _prepareValue(value: string, path: string): string {
    let collapsed = value.replace(/^\n+/, '');
    collapsed = collapsed.replace(/\n+$/, '');
    const fence = new MarkdownFenceTracker();
    const out: string[] = [];
    for (const line of collapsed.split('\n')) {
      if (fence.inFence) {
        out.push(line); // SOM §11.3: fences shield their lines.
      } else if (_ESCAPABLE.test(line) || SpecDocumentMarkdown.escapableDiv(line)) {
        out.push(`\\${line}`);
      } else if (_TABLE_HEADER_SHAPED.test(line)) {
        out.push(` ${line}`); // DI-2: a value line is never a layout table.
      } else {
        out.push(line);
      }
      fence.feed(line);
    }
    if (fence.inFence) {
      throw new Error(
        `content at "${path}" contains an unterminated fenced code block; ` +
          'it cannot be represented in the DocSpecs markdown format',
      );
    }
    return out.join('\n');
  }

  /**
   * The effective DEFAULT title of `node` (YRD4): the `@Headline` default
   * when authored, else the name derivation. The stored headline (checked by
   * callers first) always wins over this.
   */
  static _titleOf(node: SomMetaNode): string {
    return (
      node.headline ||
      SpecDocumentMarkdown.titleCase(node.memberName || node.className)
    );
  }

  /**
   * The effective default item-title stem of list `node` (YRD4): the element
   * class's `@Headline` default when authored, else the SOM §11.5 derivation
   * (element class name with `Entry` dropped; member name for scalar lists).
   */
  static _itemStemOf(node: SomMetaNode): string {
    const element = node.elementNode;
    return element !== null && element !== undefined
      ? element.headline ||
          SpecDocumentMarkdown.itemTitleStem(element.className)
      : SpecDocumentMarkdown.titleCase(node.memberName || node.segment);
  }

  // --- Import (SOM §11.7) ---------------------------------------------------

  /**
   * Parses `text` into staged values + a rejection report, **without**
   * mutating the document. {@link SpecDocument.applyMarkdownResult} applies the result as a full overwrite.
   */
  parse(text: string): SpecMarkdownResult {
    const p = new _Parser(this);
    p.run(text.split('\n'));
    const result = new SpecMarkdownResult();
    result.content = p.content;
    result.forms = p.forms;
    result.lists = p.listsJson();
    result.headlines = p.headlines;
    result.codeSpecs = p.codeSpecs;
    result.units = p.units;
    result.rejections = p.rejections;
    result.rootPrefixes = p.rootPrefixes;
    result.keptContent = p.keptContent;
    result.readableHeader = p.readableHeader;
    return result;
  }
}

/**
 * One open section during the parse: its heading level, resolved node (`null`
 * for an unresolvable/ignored section), path, and accumulated body lines.
 */
class _Frame {
  level: number;
  node: SomMetaNode | null;
  path: string;
  line: number;
  ignored: boolean;
  body: string[] = [];
  /** Rejected blocks to keep in this frame's text (RN-11): the body index
   *  they stand before, the block, and the end of the body lines it replaces
   *  (the index itself when it replaces none). */
  kept: Array<[number, _KeptBlock, number]> = [];
  /** For an ignored frame: the blocks of its ignored children, kept after its
   *  own block wherever that lands. */
  deferred: _KeptBlock[] = [];
  /** The scope this heading's descendants' anchors are qualified with, and
   *  the id of the nearest heading at or above it that is no list container
   *  (SOM §11.2, {@link _qualifyAnchor}). */
  anchorScope: string[] | null = null;
  anchorSection: string | null = null;
  /** Whether its body opened with a generated block (SOM §11.12): the
   *  heading stands for the block, so an empty value is no rejection. */
  generated = false;

  constructor(
    level: number,
    node: SomMetaNode | null,
    path: string,
    line: number,
    ignored = false,
  ) {
    this.level = level;
    this.node = node;
    this.path = path;
    this.line = line;
    this.ignored = ignored;
  }
}

const _KEPT_DIV_OPEN = /^ {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*$/;
const _KEPT_DIV_CLOSE = /^ {0,3}:{3,}[ \t]*$/;
const _KEPT_COLONS = /^ {0,3}(:{3,})/;

/**
 * A rejected block an import that accepts rejections keeps for review
 * (SOM §11.7, DocSpecs RN-11): the source lines it held and what its
 * `rejected` div records for a resolution.
 */
class _KeptBlock {
  rejection: SpecMarkdownRejection;
  /** The source lines of the block, as written. */
  lines: string[];
  /** The field given twice, or the declared field a near-miss label names. */
  field: string | null;
  /** The child section a near-miss section-table cell names. */
  section: string | null;
  /** For a field given twice: the path of the form holding the kept value. */
  kept: string | null;

  constructor(
    rejection: SpecMarkdownRejection,
    lines: string[],
    field: string | null = null,
    section: string | null = null,
    kept: string | null = null,
  ) {
    this.rejection = rejection;
    this.lines = lines;
    this.field = field;
    this.section = section;
    this.kept = kept;
  }

  /**
   * The block as a `rejected` div: `reason`, `line`, then `field` /
   * `section` / `kept` where they apply, then `label` (the report's message,
   * its double quotes written as single ones). A fence the block does not
   * close, or closes without opening, would pair with the div's own fences,
   * so it is written escaped (`\:::`, RN-9); the div's fences are longer than
   * any fence inside it, for the eye (RN-7).
   */
  div(): string[] {
    const inner = [...this.lines];
    while (inner.length > 0 && inner[0].trim() === '') inner.shift();
    while (inner.length > 0 && inner[inner.length - 1].trim() === '') inner.pop();
    const fence = new MarkdownFenceTracker();
    const open: number[] = [];
    const unpaired = new Set<number>();
    for (let k = 0; k < inner.length; k++) {
      const line = inner[k];
      if (!fence.inFence) {
        if (_KEPT_DIV_CLOSE.test(line)) {
          if (open.length === 0) {
            unpaired.add(k);
          } else {
            open.pop();
          }
        } else if (_KEPT_DIV_OPEN.test(line)) {
          open.push(k);
        }
      }
      fence.feed(line);
    }
    for (const k of open) unpaired.add(k);
    let longest = 0;
    for (let k = 0; k < inner.length; k++) {
      if (unpaired.has(k)) {
        inner[k] = inner[k].replace(/^( {0,3}):/, '$1\\:');
        continue;
      }
      const m = _KEPT_COLONS.exec(inner[k]);
      const run = m !== null ? m[1].length : 0;
      if (run > longest) longest = run;
    }
    const colons = ':'.repeat(longest >= 3 ? longest + 1 : 3);
    const q = (s: string): string => s.split('"').join("'");
    const attributes = [
      `reason="${this.rejection.reason}"`,
      `line="${this.rejection.line}"`,
      ...(this.field !== null ? [`field="${q(this.field)}"`] : []),
      ...(this.section !== null ? [`section="${q(this.section)}"`] : []),
      ...(this.kept !== null ? [`kept="${q(this.kept)}"`] : []),
      `label="${q(this.rejection.message)}"`,
    ].join(' ');
    return [`${colons} {.rejected ${attributes}}`, ...inner, colons];
  }
}

/**
 * Where the rejected blocks of one frame's body go (RN-11): each content
 * line list of the frame and the divs written into it, by position.
 */
class _Keeper {
  private _marks: Array<[number, _KeptBlock, number]>;
  private _next = 0;
  private _inserts = new Map<string[], Array<[number, string[]]>>();

  constructor(frame: _Frame) {
    this._marks = frame.kept
      .map((m, s): [[number, _KeptBlock, number], number] => [m, s])
      .sort((a, b) => (a[0][0] !== b[0][0] ? a[0][0] - b[0][0] : a[1] - b[1]))
      .map(([m]) => m);
  }

  /** Writes `b` into `into` at its current end. */
  keep(into: string[], b: _KeptBlock): void {
    let list = this._inserts.get(into);
    if (list === undefined) {
      list = [];
      this._inserts.set(into, list);
    }
    list.push([into.length, b.div()]);
  }

  /** Writes the frame's blocks standing before body index `upTo` into `into`. */
  drain(upTo: number, into: string[]): void {
    while (this._next < this._marks.length && this._marks[this._next][0] <= upTo) {
      this.keep(into, this._marks[this._next][1]);
      this._next++;
    }
  }

  /** The value of `parts` with the kept divs written in, joined as the parts
   *  are; null when no part holds one. */
  keptValue(parts: string[][]): string | null {
    if (!parts.some((p) => this._inserts.has(p))) return null;
    return parts
      .map((p) => {
        const ins = this._inserts.get(p);
        return _Parser._restoreValue(ins === undefined ? p : _Parser._merge(p, ins));
      })
      .filter((v) => v !== '')
      .join('\n\n');
  }
}

/**
 * Per-list bookkeeping while parsing: ordered item paths, stored ids, and the
 * highest item number handed out (drives both fresh numbers for stored-id
 * items and the resulting `seq`).
 */
class _ListState {
  items: string[] = [];
  ids: Record<string, string> = {};
  maxN = 0;
}

class _Parser {
  codec: SpecDocumentMarkdown;
  content: Record<string, string> = {};
  forms: Record<string, Record<string, string>> = {};
  lists: Map<string, _ListState> = new Map();
  // Stored headlines staged during the parse (SOM §11.7): a heading's text is
  // recorded only when it differs from the effective default, so a default
  // export re-imports byte-stable with an empty headline store.
  headlines: Record<string, string> = {};
  // Stored codeSpec mappings staged during the parse (codespecs_mapping.md
  // §9.2): a heading's `codeSpec="…"` value is recorded whenever present (no
  // effective default).
  codeSpecs: Record<string, string> = {};
  // Stored generation units staged during the parse (SOM §11.2): staged
  // exactly like codeSpec.
  units: Record<string, string> = {};
  rejections: SpecMarkdownRejection[] = [];
  rootPrefixes: Set<string> = new Set();
  /** The readable header line read before the root heading, or null. */
  readableHeader: string | null = null;
  keptContent: Record<string, string> = {};
  /** The source lines, for the text of a rejected block. */
  private _lines: string[] = [];
  /** Blocks reported by `_reject` and not yet placed. */
  private _pending: _KeptBlock[] = [];
  /** Text before the root heading, kept at the start of the root's text. */
  private _orphans: _KeptBlock[] = [];

  /**
   * Reports `r` and holds its block for an import that keeps rejected
   * blocks (RN-11): `lines` are the source lines it held, its own line by
   * default.
   */
  private _reject(
    r: SpecMarkdownRejection,
    opts: {
      lines?: string[];
      field?: string | null;
      section?: string | null;
      kept?: string | null;
    } = {},
  ): _KeptBlock {
    this.rejections.push(r);
    const b = new _KeptBlock(
      r,
      opts.lines ?? [this._lines[r.line - 1]],
      opts.field ?? null,
      opts.section ?? null,
      opts.kept ?? null,
    );
    this._pending.push(b);
    return b;
  }

  /** The held blocks in source order, the hold emptied. */
  private _takePending(): _KeptBlock[] {
    const out = this._pending
      .map((b, s): [_KeptBlock, number] => [b, s])
      .sort((a, b) =>
        a[0].rejection.line !== b[0].rejection.line
          ? a[0].rejection.line - b[0].rejection.line
          : a[1] - b[1],
      )
      .map(([b]) => b);
    this._pending = [];
    return out;
  }

  /** Places the held blocks before `frame`'s body index `at`; with
   *  `replaceEnd` they take the place of the body lines up to it. */
  private _markPending(frame: _Frame, at: number, replaceEnd: number | null = null): void {
    for (const b of this._takePending()) {
      frame.kept.push([at, b, replaceEnd ?? at]);
    }
  }

  /** The declared name one edit (or only case and separators) away from
   *  `label`, when exactly one is: what a *Rename to* choice offers (RN-11). */
  private static _nearMiss(label: string, names: Iterable<string>): string | null {
    const norm = (s: string): string => s.toLowerCase().replace(/[\s_-]/g, '');
    const hits = new Set<string>();
    for (const n of names) {
      if (
        n !== label &&
        (norm(n) === norm(label) || _Parser._oneEdit(n.toLowerCase(), label.toLowerCase()))
      ) {
        hits.add(n);
      }
    }
    return hits.size === 1 ? [...hits][0] : null;
  }

  /** Whether `a` becomes `b` by at most one insertion, deletion or substitution. */
  private static _oneEdit(a: string, b: string): boolean {
    if (Math.abs(a.length - b.length) > 1) return false;
    let i = 0;
    let j = 0;
    let edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] === b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }

  /**
   * `part` with the divs of `ins` (position → div lines) written in at their
   * positions, a blank line between a div and the text around it; the lines
   * at `replaced` positions are left out (a div took their place).
   */
  static _merge(
    part: string[],
    ins: Array<[number, string[]]>,
    replaced: Set<number> = new Set(),
  ): string[] {
    const out: string[] = [];
    let blankDue = false;
    for (let k = 0; k <= part.length; k++) {
      for (const [at, div] of ins) {
        if (at !== k) continue;
        if (out.length > 0 && out[out.length - 1].trim() !== '') out.push('');
        out.push(...div);
        blankDue = true;
      }
      if (k === part.length || replaced.has(k)) continue;
      const line = part[k];
      if (blankDue && line.trim() !== '') out.push('');
      blankDue = false;
      out.push(line);
    }
    return out;
  }

  /** Whether a frame of `node` passes its rejected blocks to its parent: a
   *  list container, which holds no text, and a scalar or enum value, whose
   *  text is a typed value (RN-11). */
  private static _keptInParent(node: SomMetaNode | null): boolean {
    return (
      node !== null &&
      (node.kind === SomMetaKind.LIST ||
        node.kind === SomMetaKind.SCALAR ||
        node.kind === SomMetaKind.ENUM_VALUE)
    );
  }

  /**
   * An ignored frame's heading and body, with its ignored children's blocks
   * after it, go to the text of the nearest section above it that was read,
   * after that section's own text (RN-11); with none above (an unknown root)
   * nothing holds them and only the report remains.
   */
  private _keepIgnored(frame: _Frame): void {
    const own = this.rejections.filter((r) => r.line === frame.line).pop();
    const blocks = [
      ...(own !== undefined
        ? [new _KeptBlock(own, [this._lines[frame.line - 1], ...frame.body])]
        : []),
      ...frame.deferred,
    ];
    if (this._stack.length === 0 || blocks.length === 0) return;
    const parent = this._stack[this._stack.length - 1];
    if (parent.ignored) {
      parent.deferred.push(...blocks);
      return;
    }
    for (const b of blocks) {
      parent.kept.push([parent.body.length, b, parent.body.length]);
    }
  }
  private _stack: _Frame[] = [];
  private _fence = new MarkdownFenceTracker();
  // Rolling pointer into a body region's transparent form slots — labels
  // bind to the nearest form at or after the last hit (wrapping), so
  // repeated field names across an owner's transparent forms follow emit
  // order.
  private _currentFormIdx = 0;

  constructor(codec: SpecDocumentMarkdown) {
    this.codec = codec;
  }

  run(lines: string[]): void {
    this._lines = lines;
    for (let i = 0; i < lines.length; i++) {
      const raw = lines[i];
      const lineNo = i + 1;
      const trimmed = raw.replace(/\s+$/, '');

      if (!this._fence.inFence) {
        if (
          this._stack.length === 0 &&
          SpecDocumentMarkdown.docspecComment.test(trimmed)
        ) {
          continue; // SOM §11.1 header — informational.
        }
        if (
          this._stack.length === 0 &&
          this.readableHeader === null &&
          SpecDocumentMarkdown.readableComment.test(trimmed)
        ) {
          this.readableHeader = trimmed; // SOM §11.1 readable header — skipped.
          continue;
        }
        if (
          this.readableHeader !== null &&
          trimmed === SpecDocumentMarkdown.appendixMarker
        ) {
          break; // A stripped rendition's appendix is not the document.
        }
        const h = SpecDocumentMarkdown.headingLine.exec(trimmed);
        if (h !== null) {
          this._closeTo(h[1].length);
          this._openHeading(h[1].length, h[2], lineNo);
          continue;
        }
        const div = SpecDocumentMarkdown.headingDiv(trimmed);
        if (div !== null) {
          this._closeTo(div[0]);
          this._openHeading(div[0], div[1], lineNo);
          continue;
        }
      }
      if (this._stack.length > 0) {
        this._stack[this._stack.length - 1].body.push(raw);
      } else if (trimmed) {
        const r = new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.ORPHAN_CONTENT,
          'text before the document root heading',
        );
        this.rejections.push(r);
        this._orphans.push(new _KeptBlock(r, [raw]));
      }
      this._fence.feed(raw);
    }
    this._closeTo(1);
    if (this._stack.length > 0) {
      this._finalize(this._stack.pop() as _Frame);
    }
  }

  /** Pops (and finalizes) every frame at `level` or deeper. */
  private _closeTo(level: number): void {
    while (
      this._stack.length > 0 &&
      this._stack[this._stack.length - 1].level >= level
    ) {
      this._finalize(this._stack.pop() as _Frame);
    }
  }

  private _openHeading(level: number, rest: string, lineNo: number): void {
    const m = SpecDocumentMarkdown.headlineComment.exec(rest.trim());
    if (m === null) {
      this.rejections.push(
        new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.MALFORMED_HEADING,
          'heading carries no <!--[SECTION-ID]--> headline comment',
          rest.trim(),
        ),
      );
      this._stack.push(new _Frame(level, null, '', lineNo, true));
      return;
    }
    const id = m[1];
    const codeSpec = SpecDocumentMarkdown.codeSpecOf(m[2]);
    const unitIds = SpecDocumentMarkdown.unitsOf(m[2]);
    // Reading view (DI-3): an anchor equal to the section id after the id
    // comment, or to its qualified form (SOM §11.2), is the renderer's, not
    // part of the title.
    const rawTitle = m[3].trim();
    const titleWith = (anchor: string): string =>
      rawTitle
        .replace(
          new RegExp(
            '^<a id="(?:' +
              _escapeRegExp(id) +
              '|' +
              _escapeRegExp(anchor) +
              ')"></a>\\s*',
          ),
          '',
        )
        .replace(/<br>/g, '\n');
    const title = titleWith(id);

    if (this._stack.length === 0) {
      this._openRoot(level, id, title, codeSpec, unitIds, lineNo);
      return;
    }

    const parent = this._stack[this._stack.length - 1];
    if (parent.ignored) {
      this.rejections.push(
        new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.UNKNOWN_SECTION,
          'section nested under an unresolvable parent',
          id,
        ),
      );
      this._stack.push(new _Frame(level, null, '', lineNo, true));
      return;
    }
    const pNode = parent.node;
    if (pNode === null || _Parser._isValueLeaf(pNode.kind)) {
      this.rejections.push(
        new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.KIND_MISMATCH,
          'child heading under a value-leaf or form section',
          id,
        ),
      );
      this._stack.push(new _Frame(level, null, '', lineNo, true));
      return;
    }

    // 1. Under a `-LST` container frame (SOM §11.2), every child heading is one
    //    of that list's items — resolved positionally, not by the schema tree.
    if (pNode.kind === SomMetaKind.LIST) {
      const [anchor, scope] = _qualifyAnchor(
        parent.anchorScope,
        parent.anchorSection,
        id,
        { item: true },
      );
      this._openItemHeading(
        level, parent, pNode, id, titleWith(anchor), codeSpec, unitIds, lineNo,
      );
      const last = this._stack[this._stack.length - 1];
      last.anchorScope = scope;
      last.anchorSection = id;
      return;
    }

    // 2. A regular (non-list) or list-**container** *effective* child —
    //    section-bearing children hoisted through transparent sections — whose
    //    heading id matches. A list heads its `-LST` container here; its items
    //    are resolved above once the container frame is open. Transparent value
    //    members never head, so they never match; the bound path runs through
    //    the transparent segments.
    const effective = this.codec._effectiveChildren(pNode);
    for (const [c, rel] of effective) {
      if (this.codec._headingIdOf(c) === id) {
        const path = `${parent.path}/${rel}`;
        const container = c.kind === SomMetaKind.LIST;
        const [anchor, scope] = _qualifyAnchor(
          parent.anchorScope,
          parent.anchorSection,
          id,
          { container, copy: !container && this.codec._isCopyNode(c) },
        );
        const title = titleWith(anchor);
        if (title && title !== SpecDocumentMarkdown._titleOf(c)) {
          this.headlines[path] = title;
        }
        // codespecs_mapping.md §9.2: stage the codeSpec mapping whenever
        // present (no default).
        if (codeSpec) {
          this.codeSpecs[path] = codeSpec;
        }
        // SOM §11.2: `units` is staged exactly like codeSpec.
        if (unitIds) {
          this.units[path] = unitIds;
        }
        const frame = new _Frame(level, c, path, lineNo);
        frame.anchorScope = scope;
        frame.anchorSection = container ? parent.anchorSection : id;
        this._stack.push(frame);
        return;
      }
    }

    this.rejections.push(
      new SpecMarkdownRejection(
        lineNo,
        SpecMarkdownRejectReason.UNKNOWN_SECTION,
        'section id does not resolve against the schema tree at this ' +
          `position (under "${parent.path}")`,
        id,
      ),
    );
    this._stack.push(new _Frame(level, null, '', lineNo, true));
  }

  /**
   * Opens a list-item frame under a `-LST` container frame (SOM §11.2). The
   * heading `id` is matched positionally against the container's list: the
   * `<member>-<n>` fallback id (positional, nothing stored), the
   * `@SectionIdPattern` resolved with a number (`GOAL-ITEM-3`, parses back as
   * item `<n>` carrying that id), a pattern-shaped stored id, or — for any
   * other id — an anonymous next item carrying the stored id.
   */
  private _openItemHeading(
    level: number,
    container: _Frame,
    listNode: SomMetaNode,
    id: string,
    title: string,
    codeSpec: string,
    unitIds: string,
    lineNo: number,
  ): void {
    const [n, storedId] = this._itemIdentity(listNode, id);
    this._openItem(
      level, container.path, listNode, n, storedId, title, codeSpec, unitIds,
      lineNo,
    );
  }

  /**
   * How an item `id` of `listNode` is read, as a heading's, a records row's or
   * a section-table row's: the item number it names (or `null` for the next
   * free one) and the id it stores (or `null`). The `<member>-<n>` fallback id
   * is positional and stores nothing; the `@SectionIdPattern` resolved with a
   * number names item `<n>` and is stored (SOM §11.6); any other id is the
   * next item, carrying it (YRD3).
   */
  private _itemIdentity(
    listNode: SomMetaNode,
    id: string,
  ): [number | null, string | null] {
    const anon = new RegExp(
      '^' + _escapeRegExp(listNode.memberName || listNode.segment) + '-([0-9]+)$',
    ).exec(id);
    if (anon !== null) {
      return [parseInt(anon[1], 10), null];
    }
    const element = listNode.elementNode;
    const pattern =
      listNode.sectionIdPattern ||
      (element !== null && element !== undefined
        ? element.sectionIdPattern
        : null) ||
      null;
    if (pattern !== null) {
      const parts = pattern.split('xxx');
      if (parts.length === 2) {
        const numbered = new RegExp(
          '^' + parts.map(_escapeRegExp).join('([0-9]+)') + '$',
        ).exec(id);
        if (numbered !== null) {
          return [parseInt(numbered[1], 10), id];
        }
      }
    }
    return [null, id];
  }

  private _openRoot(
    level: number,
    id: string,
    title: string,
    codeSpec: string,
    unitIds: string,
    lineNo: number,
  ): void {
    for (const root of this.codec.model.roots) {
      const seg = root.sectionId || root.type;
      if (seg === id) {
        const tree = this.codec._treeFor(root.type);
        this.rootPrefixes.add(seg);
        // YRD3: stage a renamed root heading as a stored headline —
        // "renamed" relative to the effective default (YRD4: `@Headline`
        // default, else the `@Document` title).
        if (title && title !== (tree.root.headline || root.title)) {
          this.headlines[seg] = title;
        }
        if (codeSpec) {
          this.codeSpecs[seg] = codeSpec;
        }
        // SOM §11.2: `units` is staged exactly like codeSpec.
        if (unitIds) {
          this.units[seg] = unitIds;
        }
        const frame = new _Frame(level, tree.root, seg, lineNo);
        frame.anchorSection = seg;
        // Text before the root heading is kept at the start of its text.
        for (const b of this._orphans) frame.kept.push([0, b, 0]);
        this._orphans = [];
        this._stack.push(frame);
        return;
      }
    }
    const known = this.codec.model.roots
      .map((r) => r.sectionId || r.type)
      .join(', ');
    this.rejections.push(
      new SpecMarkdownRejection(
        lineNo,
        SpecMarkdownRejectReason.UNKNOWN_SECTION,
        `no document root with this section id (known: ${known})`,
        id,
      ),
    );
    this._stack.push(new _Frame(level, null, '', lineNo, true));
  }

  /**
   * Opens a list-item frame. `n` is the anonymous heading number (also the
   * path number); a stored-id item gets the next free number instead.
   */
  private _openItem(
    level: number,
    listPath: string,
    listNode: SomMetaNode,
    n: number | null,
    storedId: string | null,
    title: string,
    codeSpec: string,
    unitIds: string,
    lineNo: number,
    push = true,
  ): string {
    let state = this.lists.get(listPath);
    if (!state) {
      state = new _ListState();
      this.lists.set(listPath, state);
    }
    const number = n !== null ? n : state.maxN + 1;
    if (number > state.maxN) {
      state.maxN = number;
    }
    const itemPath = `${listPath}-${number}`;
    state.items.push(itemPath);
    const stem = SpecDocumentMarkdown._itemStemOf(listNode);
    if (title && title !== `${stem} ${number}`) {
      this.headlines[itemPath] = title;
    }
    if (codeSpec) {
      this.codeSpecs[itemPath] = codeSpec;
    }
    // SOM §11.2: `units` is staged exactly like codeSpec.
    if (unitIds) {
      this.units[itemPath] = unitIds;
    }
    if (storedId !== null) {
      state.ids[itemPath] = storedId;
    }
    if (push) {
      this._stack.push(new _Frame(level, listNode.elementNode, itemPath, lineNo));
    }
    return itemPath;
  }

  /** The navigation of each root parsed, for its markable places. */
  private _navs = new Map<string, _Navigation>();

  private _navFor(frame: _Frame): _Navigation | null {
    const seg = frame.path.split('/')[0];
    const root = this.codec.model.roots.find((r) => (r.sectionId ?? r.type) === seg);
    if (root === undefined) return null;
    let nav = this._navs.get(root.type);
    if (nav === undefined) {
      nav = new _Navigation(this.codec, root);
      this._navs.set(root.type, nav);
    }
    return nav;
  }

  /**
   * Removes the `linked` marker (SOM §11.11): the first paragraph of the
   * body of a markable heading when it is one `linked` span. Its lines are
   * blanked, not removed, so the body indices kept blocks refer to hold.
   */
  private _stripLinkedMarker(frame: _Frame): void {
    const nav = this._navFor(frame);
    if (nav === null || !nav.markable(frame.path)) return;
    const body = frame.body;
    let k = 0;
    while (k < body.length && body[k].trim() === '') k++;
    let end = k;
    while (end < body.length && body[end].trim() !== '') end++;
    if (end === k || !_isLinkedParagraph(body.slice(k, end).join('\n'))) {
      return;
    }
    for (let i = k; i < end; i++) body[i] = '';
  }

  /**
   * Removes a generated part (SOM §11.12): the first block of a generated
   * place's body, after its marker, when it is a `derived` block. Its lines
   * are blanked, as the marker's are.
   */
  private _stripGenerated(frame: _Frame): void {
    const nav = this._navFor(frame);
    if (nav === null) return;
    if (!new _Generated(nav).isPlace(frame.path)) return;
    const body = frame.body;
    let k = 0;
    while (k < body.length && body[k].trim() === '') k++;
    if (k >= body.length || !_opensDerived(body[k])) return;
    const fence = /^ {0,3}(:{3,})/.exec(body[k])![1];
    const close = new RegExp(`^ {0,3}:{${fence.length},}[ \t]*$`);
    let end = k + 1;
    while (end < body.length && !close.test(body[end])) end++;
    if (end >= body.length) return; // unclosed: the value's, reported there
    for (let i = k; i <= end; i++) body[i] = '';
    frame.generated = true;
  }

  private static _isValueLeaf(kind: SomMetaKindValue): boolean {
    return (
      kind === SomMetaKind.CONTENT ||
      kind === SomMetaKind.SCALAR ||
      kind === SomMetaKind.ENUM_VALUE
    );
  }

  // --- Body finalisation ----------------------------------------------------

  private _finalize(frame: _Frame): void {
    if (frame.ignored) {
      this._keepIgnored(frame);
      return;
    }
    const node = frame.node;
    // A scalar list item's frame has no node; it is markable all the same.
    this._stripLinkedMarker(frame);
    this._stripGenerated(frame);
    if (node !== null && node.kind === SomMetaKind.FORM) {
      this._finalizeForm(frame, node, frame.path);
      return;
    }
    if (node !== null && node.kind === SomMetaKind.LIST) {
      this._finalizeListBody(frame, node);
    } else if (
      node !== null &&
      (node.kind === SomMetaKind.SECTION || node.kind === SomMetaKind.COMPLEX)
    ) {
      this._extractSectionTables(frame, node);
    }
    const slots = node === null ? [] : this.codec._bodySlots(node);
    if (slots.length === 0) {
      const value = _Parser._restoreValue(frame.body);
      if (frame.kept.length > 0) {
        const replaced = new Set<number>();
        for (const [at, , end] of frame.kept) {
          for (let k = at; k < end; k++) replaced.add(k);
        }
        const parent = this._stack.length > 0 ? this._stack[this._stack.length - 1] : null;
        if (_Parser._keptInParent(node) && parent !== null) {
          // A list container (no text of its own, SOM §11.5) or a typed value
          // has no place for a block: its parent takes them, after its own
          // text (RN-11); the lines they replace leave this frame's text.
          const own = _Parser._restoreValue(_Parser._merge(frame.body, [], replaced));
          if (own !== value) this.keptContent[frame.path] = own;
          for (const [, b] of frame.kept) {
            parent.kept.push([parent.body.length, b, parent.body.length]);
          }
        } else {
          const kept = _Parser._restoreValue(
            _Parser._merge(
              frame.body,
              frame.kept.map(([at, b]): [number, string[]] => [at, b.div()]),
              replaced,
            ),
          );
          if (kept) this.keptContent[frame.path] = kept;
        }
      }
      if (value) {
        this.content[frame.path] = value;
      } else if (node !== null && _Parser._isValueLeaf(node.kind) && !frame.generated) {
        this.rejections.push(
          new SpecMarkdownRejection(
            frame.line,
            SpecMarkdownRejectReason.MISSING_VALUE,
            'no value text under this section heading',
            frame.path,
          ),
        );
      }
      return;
    }
    this._finalizeBodySlots(frame, slots);
  }

  // --- Layout tables (SOM §11.4, §11.5) -------------------------------------

  /** The 1-based source line of `frame`'s body line `i`. */
  private static _bodyLine(frame: _Frame, i: number): number {
    return frame.line + 1 + i;
  }

  /**
   * The cells of a table row: split on every `|` not preceded by a backslash,
   * the outer pipes dropped, each cell trimmed; `\|` stays in the cell.
   */
  private static _rowCells(line: string): string[] {
    let t = line.trim();
    if (t.startsWith('|')) t = t.slice(1);
    if (t.endsWith('|') && !t.endsWith('\\|')) t = t.slice(0, -1);
    const cells: string[] = [];
    let b = '';
    for (let i = 0; i < t.length; i++) {
      const c = t[i];
      if (c === '\\' && i + 1 < t.length && t[i + 1] === '|') {
        b += '\\|';
        i++;
      } else if (c === '|') {
        cells.push(b.trim());
        b = '';
      } else {
        b += c;
      }
    }
    cells.push(b.trim());
    return cells;
  }

  /**
   * Reads the table whose header is `lines[start]`: the header cells, the body
   * rows with their line indexes, and the index after the table; a broken
   * delimiter row or a row of another cell count is a `malformedBlock`.
   */
  private _readTable(
    lines: string[],
    start: number,
    lineOf: (k: number) => number,
    anchor: string,
  ): { header: string[]; rows: Array<[number, string[]]>; end: number } {
    let end = start + 1;
    while (end < lines.length && _TABLE_LINE.test(lines[end])) {
      end++;
    }
    const header = _Parser._rowCells(lines[start]);
    const delimiter = start + 1 < end ? _Parser._rowCells(lines[start + 1]) : null;
    const isDelimiter =
      delimiter !== null && delimiter.every((c) => _DELIMITER_CELL.test(c));
    if (!isDelimiter || (delimiter as string[]).length !== header.length) {
      this._reject(
        new SpecMarkdownRejection(
          lineOf(start),
          SpecMarkdownRejectReason.MALFORMED_BLOCK,
          !isDelimiter
            ? 'table without its delimiter row'
            : 'table whose delimiter row does not match its header',
          anchor,
        ),
        { lines: lines.slice(start, end) },
      );
      return { header, rows: [], end };
    }
    const rows: Array<[number, string[]]> = [];
    for (let i = start + 2; i < end; i++) {
      const cells = _Parser._rowCells(lines[i]);
      if (cells.length !== header.length) {
        this._reject(
          new SpecMarkdownRejection(
            lineOf(i),
            SpecMarkdownRejectReason.MALFORMED_BLOCK,
            `table row with ${cells.length} cells, the header has ${header.length}`,
            anchor,
          ),
          { lines: [lines[i]] },
        );
        continue;
      }
      rows.push([i, cells]);
    }
    return { header, rows, end };
  }

  /**
   * A cell's value for field `f`: `\|` unescaped, a reference field's links
   * read as their link texts, a `code` field's code span decoded.
   */
  private static _cellValue(cell: string, f: SomFormFieldMeta): string {
    const text = cell.split('\\|').join('|');
    if (f.refersTo.length > 0 && !f.code && _LINK_CELL.test(text)) {
      const texts: string[] = [];
      const re = new RegExp(_LINK_TEXT.source, 'g');
      let m: RegExpExecArray | null;
      while ((m = re.exec(text)) !== null) texts.push(m[1]);
      return texts.join(', ');
    }
    return f.code ? _decodeCodeSpan(text) : text;
  }

  /** A cell's id with the renderer's anchor (`<a id="X"></a>X`) removed and
   *  a link the cell is read as its text (`[X](<file>#X)`, SOM §11.5). */
  private static _cellId(cell: string): string {
    const id = cell.replace(/^<a id="[^"]*"><\/a>\s*/, '');
    const m = /^\[([^\]]+)\]\([^)\s]*\)$/.exec(id);
    return m !== null ? m[1] : id;
  }

  /** The fields given so far per form path, for the given-twice rule. */
  private _given = new Map<string, Set<string>>();

  /**
   * Whether `field` of the form at `formPath` was given before; reports the
   * repeat (`malformedBlock`, the first occurrence kept) when it was. The
   * repeat's held block names the field and the form holding the kept value
   * (RN-11).
   */
  private _givenTwice(formPath: string, field: string, line: number): boolean {
    let given = this._given.get(formPath);
    if (given === undefined) {
      given = new Set();
      this._given.set(formPath, given);
    }
    if (!given.has(field)) {
      given.add(field);
      return false;
    }
    this._reject(
      new SpecMarkdownRejection(
        line,
        SpecMarkdownRejectReason.MALFORMED_BLOCK,
        `field "${field}" given twice`,
        formPath,
      ),
      { field, kept: formPath },
    );
    return true;
  }

  private _setField(formPath: string, field: string, value: string): void {
    if (!this.forms[formPath]) {
      this.forms[formPath] = {};
    }
    this.forms[formPath][field] = value;
  }

  /** Stages one row of a form table (or a section table). */
  private _stageRow(
    formPath: string,
    fields: SomFormFieldMeta[],
    label: string,
    cell: string,
    line: number,
  ): void {
    const lower = label.toLowerCase();
    const f = fields.find((x) => x.name.toLowerCase() === lower);
    if (f === undefined) {
      this._reject(
        new SpecMarkdownRejection(
          line,
          SpecMarkdownRejectReason.UNKNOWN_FIELD,
          `row "${label}" names no field of this form`,
          formPath,
        ),
        { field: _Parser._nearMiss(label, fields.map((x) => x.name)) },
      );
      return;
    }
    const value = _Parser._cellValue(cell, f);
    if (!value) return;
    if (this._givenTwice(formPath, f.name, line)) return;
    this._setField(formPath, f.name, value);
  }

  /** Reads and removes every section table of `frame`'s body (SOM §11.5). */
  private _extractSectionTables(frame: _Frame, node: SomMetaNode): void {
    const body = frame.body;
    const fence = new MarkdownFenceTracker();
    for (let i = 0; i < body.length; i++) {
      const line = body[i];
      const h = fence.inFence ? null : SpecDocumentMarkdown.layoutTableHeader.exec(line);
      if (h === null || h[1] === undefined) {
        fence.feed(line);
        continue;
      }
      const table = this._readTable(
        body,
        i,
        (k) => _Parser._bodyLine(frame, k),
        frame.path,
      );
      let formPath: string | null = null;
      let fields: SomFormFieldMeta[] = [];
      let skip = false;
      // The rejected section's block: its row and the rows continuing it.
      let skipped: _KeptBlock | null = null;
      for (const [k, cells] of table.rows) {
        const section = _Parser._cellId(cells[0]);
        if (!section && skip) {
          if (skipped !== null) skipped.lines.push(body[k]);
          continue;
        }
        if (section) {
          const target = this._sectionTableTarget(frame, node, section);
          skip = target === null;
          if (target === null) {
            skipped = this._reject(
              new SpecMarkdownRejection(
                _Parser._bodyLine(frame, k),
                SpecMarkdownRejectReason.UNKNOWN_SECTION,
                `section-table row names no child section of "${frame.path}"`,
                section,
              ),
              { lines: [body[k]], section: this._nearSection(node, section) },
            );
            continue;
          }
          [formPath, fields] = target;
        } else if (formPath === null) {
          this._reject(
            new SpecMarkdownRejection(
              _Parser._bodyLine(frame, k),
              SpecMarkdownRejectReason.UNKNOWN_SECTION,
              'section-table row names no section',
              frame.path,
            ),
            { lines: [body[k]] },
          );
          continue;
        }
        if (skip) continue;
        this._stageRow(formPath, fields, cells[1], cells[2], _Parser._bodyLine(frame, k));
      }
      for (let k = i; k < table.end; k++) {
        body[k] = '';
      }
      // What the table rejected is kept where the table stood.
      this._markPending(frame, i);
      i = table.end - 1;
    }
  }

  /** The child a section-table `Section` cell naming none is a near miss of
   *  (RN-11): a child form section's id, or `<LIST> / <ITEM>` with a near
   *  list id. */
  private _nearSection(node: SomMetaNode, section: string): string | null {
    const parts = section.split(/\s*\/\s*/);
    const children = this.codec._effectiveChildren(node);
    const ids = (kind: SomMetaKindValue): string[] =>
      children
        .filter(([c]) => c.kind === kind)
        .map(([c]) => this.codec._headingIdOf(c))
        .filter((id): id is string => id !== null && id !== undefined);
    if (parts.length === 1) return _Parser._nearMiss(section, ids(SomMetaKind.FORM));
    if (parts.length !== 2) return null;
    const list = _Parser._nearMiss(parts[0], ids(SomMetaKind.LIST));
    return list === null ? null : `${list} / ${parts[1]}`;
  }

  /** The form a section-table `Section` cell names under `node`. */
  private _sectionTableTarget(
    frame: _Frame,
    node: SomMetaNode,
    section: string,
  ): [string, SomFormFieldMeta[]] | null {
    const parts = section.split(/\s*\/\s*/);
    for (const [child, rel] of this.codec._effectiveChildren(node)) {
      const childId = this.codec._headingIdOf(child);
      if (parts.length === 1 && child.kind === SomMetaKind.FORM && childId === section) {
        return [`${frame.path}/${rel}`, child.form ? child.form.fields : []];
      }
      if (parts.length === 2 && child.kind === SomMetaKind.LIST && childId === parts[0]) {
        const element = child.elementNode;
        const form = element ? this.codec._itemForm(element) : null;
        if (form === null) return null;
        const [n, storedId] = this._itemIdentity(child, parts[1]);
        const listPath = `${frame.path}/${rel}`;
        const state = this.lists.get(listPath);
        const existing = state
          ? state.items.find(
              (p) => (state.ids[p] ?? p.slice(listPath.length + 1)) === parts[1],
            )
          : undefined;
        const itemPath =
          existing !== undefined
            ? existing
            : this._openItem(0, listPath, child, n, storedId, '', '', '', frame.line, false);
        return [`${itemPath}/${form[1]}`, form[0].form ? form[0].form.fields : []];
      }
    }
    return null;
  }

  // --- List bodies: `refs` and `records` (SOM §11.5) -------------------------

  /** A list container's body: one `refs` or `records` div stands for its items. */
  private _finalizeListBody(frame: _Frame, listNode: SomMetaNode): void {
    const body = frame.body;
    const fence = new MarkdownFenceTracker();
    for (let i = 0; i < body.length; i++) {
      const line = body[i];
      const open = fence.inFence ? null : _LIST_DIV_OPEN.exec(line);
      if (open === null) {
        fence.feed(line);
        continue;
      }
      const kind = open[1] !== undefined ? open[1] : open[2];
      let close = -1;
      for (let k = i + 1; k < body.length; k++) {
        if (_DIV_CLOSE.test(body[k])) {
          close = k;
          break;
        }
      }
      const reject = (
        reason: SpecMarkdownRejectReasonValue,
        message: string,
        lines: string[],
      ): void => {
        this._reject(
          new SpecMarkdownRejection(_Parser._bodyLine(frame, i), reason, message, frame.path),
          { lines },
        );
      };
      if (close < 0) {
        // The fence's lines read as text; kept, they are the rejected div
        // (the container's parent holds it, see _finalize).
        reject(SpecMarkdownRejectReason.MALFORMED_BLOCK, `unclosed ${kind} fence`, body.slice(i));
        this._markPending(frame, i, body.length);
        return;
      }
      const divLines = body.slice(i, close + 1);
      let besideText = false;
      for (let k = 0; k < body.length; k++) {
        if ((k < i || k > close) && body[k].trim() !== '') besideText = true;
      }
      const state = this.lists.get(frame.path);
      const hasItems = state !== undefined && state.items.length > 0;
      if (besideText || hasItems) {
        reject(
          SpecMarkdownRejectReason.MALFORMED_BLOCK,
          `a ${kind} div beside ${hasItems ? 'item headings' : 'other text'} in a list container`,
          divLines,
        );
        for (let k = i; k <= close; k++) body[k] = '';
        this._markPending(frame, close + 1);
        return;
      }
      const inner = body.slice(i + 1, close);
      if (kind === 'refs') {
        this._stageReferenceLine(frame, listNode, inner, i, divLines);
      } else {
        this._stageRecordTable(frame, listNode, inner, i, divLines);
      }
      for (let k = i; k <= close; k++) body[k] = '';
      // What the div rejected is kept after it.
      this._markPending(frame, close + 1);
      return;
    }
  }

  /** The reference field of `element`'s items, with the rel of its form. */
  private _referenceField(element: SomMetaNode): [string, SomFormFieldMeta] | null {
    const isRef = (n: SomMetaNode): boolean =>
      n.kind === SomMetaKind.FORM &&
      !!n.form &&
      n.form.fields.length === 1 &&
      n.form.fields[0].refersTo.length > 0 &&
      n.extra.some((e) => e.annotation === 'Reference');
    for (const [slot, rel] of this.codec._bodySlots(element)) {
      if (isRef(slot)) return [rel, (slot.form as { fields: SomFormFieldMeta[] }).fields[0]];
    }
    for (const [child, rel] of this.codec._effectiveChildren(element)) {
      if (isRef(child)) return [rel, (child.form as { fields: SomFormFieldMeta[] }).fields[0]];
    }
    return null;
  }

  /** A `refs` div: ids split on commas and whitespace, links read as their texts. */
  private _stageReferenceLine(
    frame: _Frame,
    listNode: SomMetaNode,
    inner: string[],
    at: number,
    divLines: string[],
  ): void {
    const element = listNode.elementNode;
    const ref = element ? this._referenceField(element) : null;
    if (ref === null) {
      this._reject(
        new SpecMarkdownRejection(
          _Parser._bodyLine(frame, at),
          SpecMarkdownRejectReason.MALFORMED_BLOCK,
          'a refs div in a list whose items are not references',
          frame.path,
        ),
        { lines: divLines },
      );
      return;
    }
    const ids = inner
      .join(' ')
      .split(/[,\s]+/)
      .filter((t) => t !== '')
      .map((t) => {
        const m = _LINK_TEXT.exec(t);
        return m !== null ? m[1] : t;
      });
    if (ids.length === 0) {
      this._reject(
        new SpecMarkdownRejection(
          _Parser._bodyLine(frame, at),
          SpecMarkdownRejectReason.MISSING_VALUE,
          'an empty refs div',
          frame.path,
        ),
        { lines: divLines },
      );
      return;
    }
    const pattern =
      listNode.sectionIdPattern || (element ? element.sectionIdPattern : null) || null;
    for (let n = 1; n <= ids.length; n++) {
      const positional = effectiveListItemSectionId(
        null,
        pattern,
        n,
        listNode.memberName || listNode.segment,
      );
      const [number, storedId] = this._itemIdentity(listNode, positional);
      const itemPath = this._openItem(
        0, frame.path, listNode, number, storedId, '', '', '', frame.line, false,
      );
      const formPath = ref[0] === '.' ? itemPath : `${itemPath}/${ref[0]}`;
      this._setField(formPath, ref[1].name, ids[n - 1]);
    }
  }

  /** A `records` div: one table, `Id` first, `Title` optionally second. */
  private _stageRecordTable(
    frame: _Frame,
    listNode: SomMetaNode,
    inner: string[],
    at: number,
    divLines: string[],
  ): void {
    const lineOf = (k: number): number => _Parser._bodyLine(frame, at + 1 + k);
    const reject = (message: string): void => {
      this._reject(
        new SpecMarkdownRejection(
          _Parser._bodyLine(frame, at),
          SpecMarkdownRejectReason.MALFORMED_BLOCK,
          message,
          frame.path,
        ),
        { lines: divLines },
      );
    };
    const start = inner.findIndex((l) => l.trim() !== '');
    if (start < 0 || !_TABLE_LINE.test(inner[start])) {
      reject('a records div holding no table');
      return;
    }
    const header = _Parser._rowCells(inner[start]);
    if (header[0] !== 'Id') {
      reject('a records table whose first column is not Id');
      return;
    }
    const element = listNode.elementNode;
    const form = element ? this.codec._itemForm(element) : null;
    if (form === null) {
      reject('a records div in a list whose items have no single form');
      return;
    }
    const fields = form[0].form ? form[0].form.fields : [];
    const withTitle = header.length > 1 && header[1] === 'Title';
    const columns: SomFormFieldMeta[] = [];
    for (const label of header.slice(withTitle ? 2 : 1)) {
      const lower = label.toLowerCase();
      const f = fields.find((x) => x.name.toLowerCase() === lower);
      if (f === undefined) {
        // The table is skipped whole, so the whole div is kept.
        this._reject(
          new SpecMarkdownRejection(
            lineOf(start),
            SpecMarkdownRejectReason.UNKNOWN_FIELD,
            `records column "${label}" names no field of the items`,
            frame.path,
          ),
          { lines: divLines, field: _Parser._nearMiss(label, fields.map((x) => x.name)) },
        );
        return;
      }
      columns.push(f);
    }
    const table = this._readTable(inner, start, lineOf, frame.path);
    const stem = SpecDocumentMarkdown._itemStemOf(listNode);
    for (const [k, cells] of table.rows) {
      const id = _Parser._cellId(cells[0]);
      const [n, storedId] = this._itemIdentity(listNode, id);
      const itemPath = this._openItem(
        0, frame.path, listNode, n, storedId, '', '', '', lineOf(k), false,
      );
      if (withTitle) {
        const title = cells[1].split('\\|').join('|').split('<br>').join('\n');
        const number = itemPath.slice(frame.path.length + 1);
        if (title && title !== `${stem} ${number}`) {
          this.headlines[itemPath] = title;
        }
      }
      const formPath = `${itemPath}/${form[1]}`;
      for (let c = 0; c < columns.length; c++) {
        const value = _Parser._cellValue(cells[(withTitle ? 2 : 1) + c], columns[c]);
        if (!value) continue;
        this._setField(formPath, columns[c].name, value);
      }
    }
  }

  /**
   * Binds a heading's body region against the owner's transparent body slots
   * (SOM §11.6): `FieldName:` lines and form-table rows matching a
   * transparent form's fields route to that form (nearest form in slot order,
   * wrapping); a slot marker (`<!-- slot: <rel> -->`, SOM §11.6) sends the
   * text after it to the named slot — a content slot, a form's preamble, or
   * the owner itself (`.`) — and ends any open field. Unmarked text binds to
   * the first content slot; with no content slot it is a form's **preamble**
   * (SOM §11.4 rule 7) — the class-level `@Form` on the `content` member, else
   * the first form — which is where the YAML codec keeps it; only an owner
   * with no slot at all takes it on its own path.
   */
  private _finalizeBodySlots(frame: _Frame, slots: _NodeRel[]): void {
    const formSlots = slots.filter(([s]) => s.kind === SomMetaKind.FORM);
    const defaultRel = this.codec._defaultBodyRel(slots);
    const pathOf = (rel: string): string =>
      rel === '.' ? frame.path : `${frame.path}/${rel}`;

    const findField = (label: string): [number, SomFormFieldMeta] | null => {
      const lower = label.toLowerCase();
      for (let k = 0; k < formSlots.length; k++) {
        const idx = (this._currentFormIdx + k) % formSlots.length;
        const form = formSlots[idx][0].form;
        const fields = form !== null && form !== undefined ? form.fields : [];
        for (const f of fields) {
          if (f.name.toLowerCase() === lower) {
            return [idx, f];
          }
        }
      }
      return null;
    };

    const fence = new MarkdownFenceTracker();
    let currentField: string | null = null;
    let currentFormPath: string | null = null;
    let currentCode = false;
    let discard = false;
    let currentLines: string[] = [];
    // Unlabelled text per target path, in the order the targets were opened;
    // a target opened twice gets its parts joined by a blank line.
    const textParts = new Map<string, string[][]>();
    const openText = (targetPath: string): string[] => {
      const lines: string[] = [];
      let parts = textParts.get(targetPath);
      if (parts === undefined) {
        parts = [];
        textParts.set(targetPath, parts);
      }
      parts.push(lines);
      return lines;
    };
    let contentLines = openText(pathOf(defaultRel));
    // Rejected blocks go to the unlabelled text at their place (RN-11); a
    // field given twice is kept whole, its label line and continuation.
    const keeper = new _Keeper(frame);
    let discarded: _KeptBlock | null = null;
    let discardStart = 0;
    let at = 0;

    const flush = (): void => {
      if (currentField !== null && currentFormPath !== null && !discard) {
        const restored = _Parser._restoreValue(currentLines);
        const value = currentCode ? _decodeCodeSpan(restored) : restored;
        if (value) {
          this._setField(currentFormPath, currentField, value);
        }
      }
      if (discard && discarded !== null) {
        discarded.lines = frame.body.slice(discardStart, at);
        keeper.keep(contentLines, discarded);
        discarded = null;
      }
      currentLines = [];
      discard = false;
    };

    this._currentFormIdx = 0;
    for (let i = 0; i < frame.body.length; i++) {
      const line = frame.body[i];
      at = i;
      keeper.drain(i, contentLines);
      if (!fence.inFence) {
        const marker = _SLOT_MARKER.exec(line);
        if (marker !== null) {
          const rel = marker[1];
          const slot =
            rel === '.' ? undefined : slots.find(([, r]) => r === rel);
          if (rel === '.' || slot !== undefined) {
            flush();
            currentField = null;
            currentFormPath = null;
            if (slot !== undefined && slot[0].kind === SomMetaKind.FORM) {
              this._currentFormIdx = formSlots.indexOf(slot);
            }
            contentLines = openText(pathOf(rel));
            continue;
          }
        }
        const header = SpecDocumentMarkdown.layoutTableHeader.exec(line);
        if (header !== null && header[1] === undefined && formSlots.length > 0) {
          // A form table ends the open field (SOM §11.4); its rows bind like
          // `Field:` labels, each to the nearest form declaring it.
          flush();
          currentField = null;
          currentFormPath = null;
          const table = this._readTable(
            frame.body,
            i,
            (k) => _Parser._bodyLine(frame, k),
            frame.path,
          );
          for (const [k, cells] of table.rows) {
            const hit = findField(cells[0]);
            if (hit === null) {
              this._reject(
                new SpecMarkdownRejection(
                  _Parser._bodyLine(frame, k),
                  SpecMarkdownRejectReason.UNKNOWN_FIELD,
                  `row "${cells[0]}" names no field of this form`,
                  frame.path,
                ),
                {
                  lines: [frame.body[k]],
                  field: _Parser._nearMiss(
                    cells[0],
                    formSlots.flatMap(([slot]) =>
                      slot.form !== null && slot.form !== undefined
                        ? slot.form.fields.map((f) => f.name)
                        : [],
                    ),
                  ),
                },
              );
              continue;
            }
            this._currentFormIdx = hit[0];
            this._stageRow(
              `${frame.path}/${formSlots[hit[0]][1]}`,
              [hit[1]],
              cells[0],
              cells[1],
              _Parser._bodyLine(frame, k),
            );
          }
          // What the table rejected is kept where the table stood.
          for (const b of this._takePending()) keeper.keep(contentLines, b);
          i = table.end - 1;
          continue;
        }
        const m = _FIELD_LABEL.exec(line);
        if (m !== null) {
          const hit = findField(m[1]);
          if (hit !== null) {
            flush();
            this._currentFormIdx = hit[0];
            currentField = hit[1].name;
            currentCode = hit[1].code;
            currentFormPath = `${frame.path}/${formSlots[hit[0]][1]}`;
            discard = this._givenTwice(
              currentFormPath,
              currentField,
              _Parser._bodyLine(frame, i),
            );
            if (discard) {
              discarded = this._pending.pop() ?? null;
              discardStart = i;
            }
            currentLines = [m[2]];
            fence.feed(line);
            continue;
          }
        }
      }
      const target = currentField === null ? contentLines : currentLines;
      // In a region with forms every label-shaped text line carries the one
      // escape space the emitter adds (SOM §11.4 rule 3); strip it.
      if (
        !fence.inFence &&
        formSlots.length > 0 &&
        _CONTINUATION_LABEL.test(line)
      ) {
        target.push(line.slice(1));
      } else {
        target.push(line);
      }
      fence.feed(line);
    }
    at = frame.body.length;
    flush();
    keeper.drain(at, contentLines);
    for (const [targetPath, parts] of textParts) {
      const value = parts
        .map((part) => _Parser._restoreValue(part))
        .filter((v) => v !== '')
        .join('\n\n');
      if (value) {
        this.content[targetPath] = value;
      }
      const kept = keeper.keptValue(parts);
      if (kept !== null && kept !== '') this.keptContent[targetPath] = kept;
    }
  }

  /**
   * Parses an id-bearing `@Form` section's body: `FieldName:` paragraphs and
   * form-table rows bind to the named fields wherever they stand (SOM §11.4);
   * the text that belongs to no field — before the first field, or after a
   * table — is the form's preamble, its own `content` (rule 7).
   */
  private _finalizeForm(frame: _Frame, node: SomMetaNode, path: string): void {
    const form = node.form;
    const declared = form !== null && form !== undefined ? form.fields : [];
    const fieldsByLower = new Map<string, SomFormFieldMeta>(
      declared.map((f) => [f.name.toLowerCase(), f]),
    );
    const fence = new MarkdownFenceTracker();
    let currentField: SomFormFieldMeta | null = null;
    let discard = false;
    let currentLines: string[] = [];
    // The preamble's parts: the text before the first field, and text a table
    // interrupts; joined by one blank line.
    const preambleParts: string[][] = [[]];
    const last = (): string[] => preambleParts[preambleParts.length - 1];
    // Rejected blocks go to the preamble at their place (RN-11).
    const keeper = new _Keeper(frame);
    let discarded: _KeptBlock | null = null;
    let discardStart = 0;
    let at = 0;

    const flush = (): void => {
      const f = currentField;
      if (f !== null && !discard) {
        const restored = _Parser._restoreValue(currentLines);
        const value = f.code ? _decodeCodeSpan(restored) : restored;
        if (value) {
          this._setField(path, f.name, value);
        }
      }
      if (discard && discarded !== null) {
        discarded.lines = frame.body.slice(discardStart, at);
        keeper.keep(last(), discarded);
        discarded = null;
      }
      currentLines = [];
      discard = false;
    };

    for (let i = 0; i < frame.body.length; i++) {
      const line = frame.body[i];
      at = i;
      keeper.drain(i, last());
      if (!fence.inFence) {
        const header = SpecDocumentMarkdown.layoutTableHeader.exec(line);
        if (header !== null && header[1] === undefined) {
          flush();
          currentField = null;
          preambleParts.push([]);
          const table = this._readTable(
            frame.body,
            i,
            (k) => _Parser._bodyLine(frame, k),
            path,
          );
          for (const [k, cells] of table.rows) {
            this._stageRow(path, declared, cells[0], cells[1], _Parser._bodyLine(frame, k));
          }
          for (const b of this._takePending()) keeper.keep(last(), b);
          i = table.end - 1;
          continue;
        }
        const m = _FIELD_LABEL.exec(line);
        const field =
          m !== null ? fieldsByLower.get(m[1].toLowerCase()) : undefined;
        if (field !== undefined && m !== null) {
          flush();
          currentField = field;
          discard = this._givenTwice(path, field.name, _Parser._bodyLine(frame, i));
          if (discard) {
            discarded = this._pending.pop() ?? null;
            discardStart = i;
          }
          currentLines = [m[2]];
          fence.feed(line);
          continue;
        }
      }
      // Continuation: strip the one escape space of a label-shaped line.
      const target =
        currentField === null ? preambleParts[preambleParts.length - 1] : currentLines;
      if (!fence.inFence && _CONTINUATION_LABEL.test(line)) {
        target.push(line.slice(1));
      } else {
        target.push(line);
      }
      fence.feed(line);
    }
    at = frame.body.length;
    flush();
    keeper.drain(at, last());
    const value = preambleParts
      .map((part) => _Parser._restoreValue(part))
      .filter((v) => v !== '')
      .join('\n\n');
    if (value) {
      this.content[path] = value;
    }
    const kept = keeper.keptValue(preambleParts);
    if (kept !== null && kept !== '') this.keptContent[path] = kept;
  }

  /**
   * Parse-side value restoration (SOM §11.3): trim leading/trailing blank
   * lines, unescape `\#`-escaped heading lines and strip the one escape space
   * of a line shaped like a layout table header (SOM §11.4), outside fences.
   */
  static _restoreValue(body: string[]): string {
    const fence = new MarkdownFenceTracker();
    const out: string[] = [];
    for (const line of body) {
      if (
        !fence.inFence &&
        (_ESCAPED_HEADING.test(line) ||
          (line.startsWith('\\') && SpecDocumentMarkdown.escapableDiv(line)))
      ) {
        out.push(line.slice(1));
      } else if (!fence.inFence && _ESCAPED_TABLE_HEADER.test(line)) {
        out.push(line.slice(1)); // DI-2: the emitter's one escape space.
      } else {
        out.push(line);
      }
      fence.feed(line);
    }
    let joined = out.join('\n');
    joined = joined.replace(/^([ \t]*\n)+/, '');
    joined = joined.replace(/(\n[ \t]*)+$/, '');
    return joined;
  }

  listsJson(): Record<string, ListJson> {
    const out: Record<string, ListJson> = {};
    for (const [key, state] of this.lists) {
      const entry: ListJson = { seq: state.maxN, items: state.items.slice() };
      if (Object.keys(state.ids).length > 0) {
        entry.ids = { ...state.ids };
      }
      out[key] = entry;
    }
    return out;
  }
}

/**
 * A Markdown rendition of a document and the document path behind each of its
 * headings ({@link SpecDocumentMarkdown.exportRootWithMap}).
 */
export class SpecMarkdownRendition {
  /** The rendered Markdown, identical to {@link SpecDocumentMarkdown.exportRoot}. */
  readonly markdown: string;

  /** Every heading line (1-based) and the document path it renders. */
  readonly headingPaths: Map<number, string>;

  /** The rendition and its heading map — 1-based line → document path. */
  constructor(markdown: string, headingPaths: Map<number, string>) {
    this.markdown = markdown;
    this.headingPaths = headingPaths;
  }

  /**
   * The document path of the section `line` belongs to: the path of the
   * heading on that line, else of the nearest heading above it. `null` for a
   * line before the first heading.
   */
  pathAtLine(line: number): string | null {
    for (let l = line; l >= 1; l--) {
      const p = this.headingPaths.get(l);
      if (p !== undefined) return p;
    }
    return null;
  }
}
