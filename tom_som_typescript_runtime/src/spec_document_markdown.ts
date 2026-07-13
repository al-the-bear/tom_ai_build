/**
 * DocSpecs-conform Markdown codec for a TomSpecs document (DR1 §1) — a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_document_markdown.dart`
 * (and the JavaScript `spec_document_markdown.js`).
 *
 * The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
 * the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is one markdown heading whose machine-readable identity is the
 * DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
 * human-readable Title-Case member name. Content values are **normal markdown
 * text** under their heading (no fences, no anchors); `@Form` sections use the
 * DocSpecs plain-text `FieldName: value` format; list items are sub-headings
 * carrying the item's section id (stored id, else the `@SectionIdPattern`
 * resolved with the 1-based position — `GOAL-ITEM-xxx` → `GOAL-ITEM-1` — else
 * `<member>-<pos>`) directly under the owning section — the list container
 * gets no heading of its own. Id-less members are **transparent** (mirroring
 * the DR3 schema generator): a transparent value member's text or form block
 * is the owner's body region, emitted without a heading and bound at its own
 * path; a transparent section/complex member never heads — its id-bearing
 * descendants hoist to the owner's child level (paths keep the transparent
 * segments). Section/complex headings without a field-level `@SectionId`
 * carry the target class's `@SectionId`.
 *
 * Escaping (DR1 §1.3): a content line starting with `#` at column 0 is
 * emitted as `\#` (and a leading `\#`… run gains one more backslash), except
 * inside fenced code blocks, which shield their lines verbatim. Consecutive
 * blank lines are collapsed to one on emit; parse trims each value of
 * leading/trailing blank lines and does not re-collapse.
 *
 * The codec is free of any UI: it reads from / resolves against a
 * {@link SpecModel} (through the {@link buildSomMetaTree} metadata tree) and a
 * {@link SpecDocument}. {@link SpecDocumentMarkdown.parse} does **not** mutate
 * the document — it returns staged values keyed exactly like
 * {@link SpecDocument.toJson} plus a rejection report; the caller applies
 * them. Anything that cannot be mapped — an unknown section id, a child
 * heading under a value leaf, orphaned text — is collected into
 * {@link SpecMarkdownResult.rejections} rather than dropped (DR1 §1.7).
 */

import type { ListJson, SpecDocument } from './spec_document';
import type { SpecModel } from './spec_model';
import { SomMetaKind, SomMetaNode, SomMetaTree, SomMetaKindValue } from './spec_meta';
import { buildSomMetaTree } from './spec_meta_bridge';

/** Why an imported Markdown block was rejected (DR1 §1.7 rejection protocol). */
export const SpecMarkdownRejectReason = {
  /** The heading's section id does not resolve against the schema tree at its
   *  nesting position. */
  UNKNOWN_SECTION: 'unknownSection',
  /** A structurally impossible combination — e.g. a child heading nested
   *  under a value-leaf (content/scalar/enum) section. */
  KIND_MISMATCH: 'kindMismatch',
  /** Body text with no owning value slot — e.g. prose inside a `@Form`
   *  section before the first `FieldName:` line. */
  ORPHAN_CONTENT: 'orphanContent',
  /** A value-leaf section heading with an empty body. */
  MISSING_VALUE: 'missingValue',
  /** A heading line without a parseable `<!--[id]-->` headline comment. */
  MALFORMED_HEADING: 'malformedHeading',
} as const;

export type SpecMarkdownRejectReasonValue =
  (typeof SpecMarkdownRejectReason)[keyof typeof SpecMarkdownRejectReason];

/**
 * One rejected block in a Markdown import (DR1 §1.7). Reported, never silently
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
 * The outcome of parsing a Markdown document (DR1 §1.7): the staged values
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
  /** Every rejected block, in source order. */
  rejections: SpecMarkdownRejection[] = [];
  /** The root segment(s) the import covers (the first segment of each
   *  accepted path) — the scope a full-overwrite apply purges first. */
  rootPrefixes: Set<string> = new Set();

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

/** A body slot / effective child: the node plus its relative path. */
type _NodeRel = [SomMetaNode, string];

/**
 * Codec binding a {@link SpecModel} and a concrete {@link SpecDocument} to the
 * DocSpecs Markdown import/export format (DR1 §1).
 */
export class SpecDocumentMarkdown {
  model: SpecModel;
  document: SpecDocument;
  // Metadata trees per root type, built lazily (DR8's generated facades
  // will hand these in directly; until then the bridge derives them).
  private _trees: Map<string, SomMetaTree> = new Map();

  // Shared with the parser and the DocSpecs validator.
  static headingLine = /^(#+)\s+(.*)$/;
  static headlineComment = /^<!--\[([^\]]+)\]-->\s*(.*)$/;
  static docspecComment = /^<!--\s*docspec:.*-->\s*$/;

  constructor(model: SpecModel, document: SpecDocument) {
    this.model = model;
    this.document = document;
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

  // --- Naming helpers (DR1 §1.2 / §1.5) ------------------------------------

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
   * `@Document` name (DR1 §1.1).
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
   * trailing `Entry` dropped (DR1 §1.5, normative).
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
   * the first letter upper-cased (DR1 §1.4.1).
   */
  static formLabel(fieldName: string): string {
    if (!fieldName) {
      return fieldName;
    }
    return fieldName.charAt(0).toUpperCase() + fieldName.slice(1);
  }

  // --- Export (DR1 §1.1–§1.6) ----------------------------------------------

  /**
   * The section id written into (and matched from) a heading for `node`
   * (DR1 §1.2/§1.6): the field-level `@SectionId` when present; for
   * section/complex nodes whose field carries none, the target **class**'s
   * `@SectionId` (the id the DR3 schema types are keyed by); else the path
   * segment (the member name).
   *
   * @internal
   */
  _headingIdOf(node: SomMetaNode): string {
    if (node.sectionId !== null && node.sectionId !== undefined) {
      return node.sectionId;
    }
    if (node.kind === SomMetaKind.SECTION || node.kind === SomMetaKind.COMPLEX) {
      const cls = this.model.classNamed(node.className);
      if (cls !== null && cls.sectionId !== null && cls.sectionId !== undefined) {
        return cls.sectionId;
      }
    }
    return node.segment;
  }

  // --- Transparency (DR1 §1.2, mirroring the DR3 schema generator) ---------
  //
  // The DR3 `docspecs-schema` generator is normative: only **section-bearing**
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
  //   * lists are never transparent — the container never heads, the items
  //     always do (stored id / `@SectionIdPattern` / `<member>-<pos>`).
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
    const cls = this.model.classNamed(n.className);
    return cls === null || cls.sectionId === null || cls.sectionId === undefined;
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
   * headings (and item-heading owners) the DR3 schema knows at this position.
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
   * document. Throws an {@link Error} when a content value contains an
   * unterminated fenced code block (which would shield the remainder of the
   * document from heading detection and break the round-trip).
   */
  exportRoot(root: import('./spec_model').SpecRoot): string {
    const tree = this._treeFor(root.type);
    const node = tree.root;
    const b = new _Buffer();
    b.writeln(
      `<!-- docspec: ${SpecDocumentMarkdown.kebabCase(root.title)}/` +
        `${this.model.modelVersionString} -->`,
    );
    const rootSeg = node.segment;
    SpecDocumentMarkdown._writeHeading(b, 1, rootSeg, root.title);
    this._writeSectionBody(b, node, rootSeg);
    this._writeChildren(b, node, rootSeg, 2);
    return b.toString();
  }

  /**
   * Writes the body region of a section heading: the section path's own
   * content value plus every transparent body slot (id-less content text and
   * form blocks, hoisted through transparent sections) in model order.
   */
  private _writeSectionBody(b: _Buffer, node: SomMetaNode, path: string): void {
    this._writeBody(b, this.document.content(path), path);
    for (const [slot, rel] of this._bodySlots(node)) {
      const slotPath = `${path}/${rel}`;
      if (slot.kind === SomMetaKind.FORM) {
        if (this._formHasValues(slot, slotPath)) {
          this._writeForm(b, slot, slotPath);
        }
      } else {
        this._writeBody(b, this.document.content(slotPath), slotPath);
      }
    }
  }

  private _writeChildren(
    b: _Buffer,
    node: SomMetaNode,
    basePath: string,
    depth: number,
  ): void {
    for (const [child, rel] of this._effectiveChildren(node)) {
      const path = `${basePath}/${rel}`;
      if (!this.document.hasValuesUnder(path)) {
        continue;
      }
      const kind = child.kind;
      if (
        kind === SomMetaKind.CONTENT ||
        kind === SomMetaKind.SCALAR ||
        kind === SomMetaKind.ENUM_VALUE
      ) {
        const value = this.document.content(path);
        if (value === null) {
          continue;
        }
        SpecDocumentMarkdown._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          SpecDocumentMarkdown._titleOf(child),
        );
        this._writeBody(b, value, path);
      } else if (kind === SomMetaKind.FORM) {
        if (!this._formHasValues(child, path)) {
          continue;
        }
        SpecDocumentMarkdown._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          SpecDocumentMarkdown._titleOf(child),
        );
        this._writeForm(b, child, path);
      } else if (kind === SomMetaKind.SECTION || kind === SomMetaKind.COMPLEX) {
        SpecDocumentMarkdown._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          SpecDocumentMarkdown._titleOf(child),
        );
        this._writeSectionBody(b, child, path);
        this._writeChildren(b, child, path, depth + 1);
      } else if (kind === SomMetaKind.LIST) {
        this._writeListItems(b, child, path, depth);
      }
    }
  }

  /**
   * Emits the items of list `node` as headings **at the owner's child level**
   * — the container itself gets no heading (DR1 §1.2).
   */
  private _writeListItems(
    b: _Buffer,
    node: SomMetaNode,
    listPath: string,
    depth: number,
  ): void {
    const items = this.document.listItems(listPath);
    const element = node.elementNode;
    const stem = SpecDocumentMarkdown.itemTitleStem(
      element !== null && element !== undefined
        ? element.className
        : node.typeName,
    );
    const pattern =
      node.sectionIdPattern ||
      (element !== null && element !== undefined
        ? element.sectionIdPattern
        : null) ||
      null;
    for (let i = 0; i < items.length; i++) {
      const itemPath = items[i];
      const pos = i + 1;
      // DR1 §1.2: an anonymous item's heading id is the resolved
      // `@SectionIdPattern` id (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`); only
      // pattern-less lists fall back to `<member>-<pos>`.
      const stored = this.document.itemSectionId(itemPath);
      let itemId: string;
      if (stored !== null && stored !== undefined) {
        itemId = stored;
      } else if (pattern !== null) {
        itemId = pattern.split('xxx').join(String(pos));
      } else {
        itemId = `${node.memberName || node.segment}-${pos}`;
      }
      SpecDocumentMarkdown._writeHeading(b, depth, itemId, `${stem} ${pos}`);
      if (element === null || element === undefined) {
        // Scalar list: the item's value is its body.
        this._writeBody(b, this.document.content(itemPath) || '', itemPath);
      } else {
        this._writeSectionBody(b, element, itemPath);
        if (!element.recursive) {
          this._writeChildren(b, element, itemPath, depth + 1);
        }
      }
    }
  }

  private _formHasValues(node: SomMetaNode, path: string): boolean {
    const fields =
      node.form !== null && node.form !== undefined ? node.form.fields : [];
    for (const f of fields) {
      if (this.document.formField(path, f.name) !== null) {
        return true;
      }
    }
    return false;
  }

  private _writeForm(b: _Buffer, node: SomMetaNode, path: string): void {
    const fields =
      node.form !== null && node.form !== undefined ? node.form.fields : [];
    for (const f of fields) {
      const value = this.document.formField(path, f.name);
      if (value === null) {
        continue;
      }
      const lines = this._prepareValue(value, path).split('\n');
      b.writeln(`${SpecDocumentMarkdown.formLabel(f.name)}: ${lines[0]}`);
      for (const line of lines.slice(1)) {
        // §1.4.3 generalised: any continuation line that could be mistaken
        // for a field-label line gains one leading space; parse strips it.
        b.writeln(_LABEL_SHAPED.test(line) ? ` ${line}` : line);
      }
    }
    b.writeln();
  }

  /**
   * `## <!--[ID]--> Title` at `depth`. DR1 §1.2 is normative — heading level
   * = 1 + section depth, **uncapped**: deep models (the Solution Blueprint
   * nests past markdown's native 6 levels) keep their structure; the parse
   * grammar accepts `#{7,}` accordingly. Capping would silently flatten
   * distinct nesting positions into siblings and break schema validation.
   */
  private static _writeHeading(
    b: _Buffer,
    depth: number,
    id: string,
    title: string,
  ): void {
    b.writeln(`${'#'.repeat(depth)} <!--[${id}]--> ${title}`);
    b.writeln();
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
   * Emit-side value normalisation (DR1 §1.3): collapse 2+ blank lines to one,
   * trim leading/trailing blank lines, escape heading-like lines outside
   * fences. Throws an {@link Error} for an unterminated fence.
   */
  private _prepareValue(value: string, path: string): string {
    let collapsed = value.replace(/\n{3,}/g, '\n\n');
    collapsed = collapsed.replace(/^\n+/, '');
    collapsed = collapsed.replace(/\n+$/, '');
    const fence = new MarkdownFenceTracker();
    const out: string[] = [];
    for (const line of collapsed.split('\n')) {
      if (fence.inFence) {
        out.push(line); // §1.3.4: fences shield their lines.
      } else if (_ESCAPABLE.test(line)) {
        out.push(`\\${line}`);
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

  private static _titleOf(node: SomMetaNode): string {
    return SpecDocumentMarkdown.titleCase(node.memberName || node.className);
  }

  // --- Import (DR1 §1.7) ----------------------------------------------------

  /**
   * Parses `text` into staged values + a rejection report, **without**
   * mutating the document. The caller applies the result as a full overwrite.
   */
  parse(text: string): SpecMarkdownResult {
    const p = new _Parser(this);
    p.run(text.split('\n'));
    const result = new SpecMarkdownResult();
    result.content = p.content;
    result.forms = p.forms;
    result.lists = p.listsJson();
    result.rejections = p.rejections;
    result.rootPrefixes = p.rootPrefixes;
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
  rejections: SpecMarkdownRejection[] = [];
  rootPrefixes: Set<string> = new Set();
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
    for (let i = 0; i < lines.length; i++) {
      const raw = lines[i];
      const lineNo = i + 1;
      const trimmed = raw.replace(/\s+$/, '');

      if (!this._fence.inFence) {
        if (
          this._stack.length === 0 &&
          SpecDocumentMarkdown.docspecComment.test(trimmed)
        ) {
          continue; // §1.1 header — informational.
        }
        const h = SpecDocumentMarkdown.headingLine.exec(trimmed);
        if (h !== null) {
          this._closeTo(h[1].length);
          this._openHeading(h[1].length, h[2], lineNo);
          continue;
        }
      }
      if (this._stack.length > 0) {
        this._stack[this._stack.length - 1].body.push(raw);
      } else if (trimmed) {
        this.rejections.push(
          new SpecMarkdownRejection(
            lineNo,
            SpecMarkdownRejectReason.ORPHAN_CONTENT,
            'text before the document root heading',
          ),
        );
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

    if (this._stack.length === 0) {
      this._openRoot(level, id, lineNo);
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

    // 1. A regular (non-list) *effective* child — section-bearing children
    //    hoisted through transparent sections — whose heading id (field/class
    //    section id) matches. Transparent value members never head, so they
    //    never match here; the bound path runs through transparent segments.
    const effective = this.codec._effectiveChildren(pNode);
    for (const [c, rel] of effective) {
      if (c.kind !== SomMetaKind.LIST && this.codec._headingIdOf(c) === id) {
        this._stack.push(
          new _Frame(level, c, `${parent.path}/${rel}`, lineNo),
        );
        return;
      }
    }

    // 2. A list item: anonymous (`<member>-<n>` or the pattern with a numeric
    //    sequence, e.g. `GOAL-ITEM-3`), pattern-shaped stored id, or
    //    (fallback) any id when the parent has exactly one effective list.
    const listChildren = effective.filter(
      ([c]) => c.kind === SomMetaKind.LIST,
    );
    for (const [lc, rel] of listChildren) {
      const listPath = `${parent.path}/${rel}`;
      const anon = new RegExp(
        '^' + _escapeRegExp(lc.memberName || lc.segment) + '-([0-9]+)$',
      ).exec(id);
      if (anon !== null) {
        this._openItem(
          level,
          listPath,
          lc,
          parseInt(anon[1], 10),
          null,
          lineNo,
        );
        return;
      }
      const element = lc.elementNode;
      const pattern =
        lc.sectionIdPattern ||
        (element !== null && element !== undefined
          ? element.sectionIdPattern
          : null) ||
        null;
      if (pattern !== null) {
        // Canonical anonymous id: the pattern with `xxx` as a number — parses
        // back as item <n>, NOT as a stored id (DR1 §1.2 round-trip).
        const parts = pattern.split('xxx');
        if (parts.length === 2) {
          const numbered = new RegExp(
            '^' + parts.map(_escapeRegExp).join('([0-9]+)') + '$',
          ).exec(id);
          if (numbered !== null) {
            this._openItem(
              level,
              listPath,
              lc,
              parseInt(numbered[1], 10),
              null,
              lineNo,
            );
            return;
          }
        }
        if (_Parser._patternMatches(pattern, id)) {
          this._openItem(level, listPath, lc, null, id, lineNo);
          return;
        }
      }
    }
    if (listChildren.length === 1) {
      const [lc, rel] = listChildren[0];
      this._openItem(level, `${parent.path}/${rel}`, lc, null, id, lineNo);
      return;
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

  private _openRoot(level: number, id: string, lineNo: number): void {
    for (const root of this.codec.model.roots) {
      const seg = root.sectionId || root.type;
      if (seg === id) {
        const tree = this.codec._treeFor(root.type);
        this.rootPrefixes.add(seg);
        this._stack.push(new _Frame(level, tree.root, seg, lineNo));
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
    lineNo: number,
  ): void {
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
    if (storedId !== null) {
      state.ids[itemPath] = storedId;
    }
    this._stack.push(new _Frame(level, listNode.elementNode, itemPath, lineNo));
  }

  /**
   * `GOAL-ITEM-xxx` → `^GOAL-ITEM-.+$` — the `@SectionIdPattern` wildcard.
   */
  private static _patternMatches(pattern: string, id: string): boolean {
    const regex = new RegExp(
      '^' + pattern.split('xxx').map(_escapeRegExp).join('.+') + '$',
    );
    return regex.test(id);
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
      return;
    }
    const node = frame.node;
    if (node !== null && node.kind === SomMetaKind.FORM) {
      this._finalizeForm(frame, node, frame.path);
      return;
    }
    const slots = node === null ? [] : this.codec._bodySlots(node);
    if (slots.length === 0) {
      const value = _Parser._restoreValue(frame.body);
      if (value) {
        this.content[frame.path] = value;
      } else if (node !== null && _Parser._isValueLeaf(node.kind)) {
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

  /**
   * Binds a heading's body region against the owner's transparent body slots
   * (DR1 §1.2 transparency): `FieldName:` lines matching a transparent form's
   * fields route to that form (nearest form in slot order, wrapping); all
   * other text binds to the first non-form slot — or to the owner's own path
   * when no such slot exists.
   */
  private _finalizeBodySlots(frame: _Frame, slots: _NodeRel[]): void {
    const formSlots = slots.filter(([s]) => s.kind === SomMetaKind.FORM);
    const contentSlots = slots.filter(([s]) => s.kind !== SomMetaKind.FORM);
    const contentPath =
      contentSlots.length > 0
        ? `${frame.path}/${contentSlots[0][1]}`
        : frame.path;

    if (formSlots.length === 0) {
      const value = _Parser._restoreValue(frame.body);
      if (value) {
        this.content[contentPath] = value;
      }
      return;
    }

    const findField = (label: string): [number, string] | null => {
      const lower = label.toLowerCase();
      for (let k = 0; k < formSlots.length; k++) {
        const idx = (this._currentFormIdx + k) % formSlots.length;
        const form = formSlots[idx][0].form;
        const fields = form !== null && form !== undefined ? form.fields : [];
        for (const f of fields) {
          if (f.name.toLowerCase() === lower) {
            return [idx, f.name];
          }
        }
      }
      return null;
    };

    const fence = new MarkdownFenceTracker();
    let currentField: string | null = null;
    let currentFormPath: string | null = null;
    let currentLines: string[] = [];
    const contentLines: string[] = [];

    const flush = (): void => {
      if (currentField !== null && currentFormPath !== null) {
        const value = _Parser._restoreValue(currentLines);
        if (value) {
          if (!this.forms[currentFormPath]) {
            this.forms[currentFormPath] = {};
          }
          this.forms[currentFormPath][currentField] = value;
        }
      }
      currentLines = [];
    };

    this._currentFormIdx = 0;
    for (const line of frame.body) {
      if (!fence.inFence) {
        const m = _FIELD_LABEL.exec(line);
        if (m !== null) {
          const hit = findField(m[1]);
          if (hit !== null) {
            flush();
            this._currentFormIdx = hit[0];
            currentField = hit[1];
            currentFormPath = `${frame.path}/${formSlots[hit[0]][1]}`;
            currentLines = [m[2]];
            fence.feed(line);
            continue;
          }
        }
      }
      const target = currentField === null ? contentLines : currentLines;
      // Continuation: strip the one escape space of a label-shaped line.
      if (
        !fence.inFence &&
        currentField !== null &&
        _CONTINUATION_LABEL.test(line)
      ) {
        target.push(line.slice(1));
      } else {
        target.push(line);
      }
      fence.feed(line);
    }
    flush();
    const value = _Parser._restoreValue(contentLines);
    if (value) {
      this.content[contentPath] = value;
    }
  }

  private _finalizeForm(frame: _Frame, node: SomMetaNode, path: string): void {
    const form = node.form;
    const fields = form !== null && form !== undefined ? form.fields : [];
    const fieldsByLower = new Map<string, string>(
      fields.map((f) => [f.name.toLowerCase(), f.name]),
    );
    const fence = new MarkdownFenceTracker();
    let currentField: string | null = null;
    let currentLines: string[] = [];

    const flush = (lineNo: number): void => {
      if (currentField !== null) {
        const value = _Parser._restoreValue(currentLines);
        if (value) {
          if (!this.forms[path]) {
            this.forms[path] = {};
          }
          this.forms[path][currentField] = value;
        }
      } else if (currentLines.some((l) => l.trim())) {
        this.rejections.push(
          new SpecMarkdownRejection(
            lineNo,
            SpecMarkdownRejectReason.ORPHAN_CONTENT,
            'text in a @Form section before the first field label',
            path,
          ),
        );
      }
      currentLines = [];
    };

    for (let i = 0; i < frame.body.length; i++) {
      const line = frame.body[i];
      if (!fence.inFence) {
        const m = _FIELD_LABEL.exec(line);
        const fieldName =
          m !== null ? fieldsByLower.get(m[1].toLowerCase()) : undefined;
        if (fieldName !== undefined && m !== null) {
          flush(frame.line + i);
          currentField = fieldName;
          currentLines = [m[2]];
          fence.feed(line);
          continue;
        }
      }
      // Continuation: strip the one escape space of a label-shaped line.
      if (!fence.inFence && _CONTINUATION_LABEL.test(line)) {
        currentLines.push(line.slice(1));
      } else {
        currentLines.push(line);
      }
      fence.feed(line);
    }
    flush(frame.line + frame.body.length);
  }

  /**
   * Parse-side value restoration (DR1 §1.3): trim leading/trailing blank
   * lines and unescape `\#`-escaped heading lines outside fences.
   */
  private static _restoreValue(body: string[]): string {
    const fence = new MarkdownFenceTracker();
    const out: string[] = [];
    for (const line of body) {
      if (!fence.inFence && _ESCAPED_HEADING.test(line)) {
        out.push(line.slice(1));
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
