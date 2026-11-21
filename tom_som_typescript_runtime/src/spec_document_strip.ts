/**
 * Stripped renditions (SOM §11.10; the reading view's part *Stripped
 * renditions and the merge back*): a copy of a document with the secondary
 * prose of named kinds dropped, unmarked or moved to an appendix.
 *
 * The kinds are the four the reading notation registers as secondary
 * (`provenance`, `trace`, `editorial`, `aside`, DocSpecs RN-5) plus
 * `comments`, the review annotations (SOM §11.9). A citation shape counts as
 * a span of its kind. `refs`, `records` and `rejected` are never secondary:
 * no name drops or unmarks them (RN-11).
 *
 * The port of `spec_document_strip.dart`; `strip_cases.json` holds both to
 * the same results.
 */

import {
  DocSpecsSchema,
  DocSpecsValidator,
  DocSpecsViolation,
  stripOwnAnchor,
} from './docspecs_validator';
import { SpecDocument } from './spec_document';
import {
  MarkdownFenceTracker,
  SpecDocumentMarkdown,
} from './spec_document_markdown';
import type { SpecModel, SpecRoot } from './spec_model';
import {
  NotationElement,
  NotationFinding,
  NotationFindingCode,
  scanNotation,
} from './spec_notation';
import {
  countAnnotationsText,
  stripAnnotationsText,
} from './spec_review_annotations';
import { validateSpecDocument } from './spec_schema_validation';
import { validateDocument } from './spec_validator';

/** The kind names a strip takes, in report and header order. */
export const specStripKindNames: readonly string[] = [
  'provenance',
  'trace',
  'editorial',
  'aside',
  'comments',
];

/** The notation kinds a strip can drop, unmark or move to the appendix. */
export const specStripNotationKinds: readonly string[] = [
  'provenance',
  'trace',
  'editorial',
  'aside',
];

/** A strip asked for something it cannot do; the message says which. */
export class SpecStripUsageError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SpecStripUsageError';
  }
}

/** The options as sets; {@link SpecStripOptions.fromNames} is the checked form. */
export interface SpecStripOptionsInit {
  drop?: Set<string>;
  unmark?: Set<string>;
  appendix?: Set<string>;
  appendixReferences?: boolean;
  headingDivs?: boolean;
}

/** What a strip does with each kind. */
export class SpecStripOptions {
  /** The kinds removed with their content. */
  readonly drop: Set<string>;
  /** The kinds whose markers go and whose content stays. */
  readonly unmark: Set<string>;
  /** The kinds moved, with their content, into the appendix *Notes*. */
  readonly appendix: Set<string>;
  /** Whether each moved element leaves a link `[n]` to its entry. */
  readonly appendixReferences: boolean;
  /** Whether sections deeper than level 6 are styled-div headings. */
  readonly headingDivs: boolean;

  constructor(init: SpecStripOptionsInit = {}) {
    this.drop = init.drop ?? new Set();
    this.unmark = init.unmark ?? new Set();
    this.appendix = init.appendix ?? new Set();
    this.appendixReferences = init.appendixReferences === true;
    this.headingDivs = init.headingDivs === true;
  }

  /**
   * The options from the names a user gives, each item possibly
   * comma-joined. `all` stands for every kind the list can hold that no
   * other list names explicitly. Throws {@link SpecStripUsageError} for an
   * unknown name, a name in two lists, `comments` to unmark or move, and
   * appendix references without an appendix.
   */
  static fromNames(
    init: {
      drop?: Iterable<string>;
      unmark?: Iterable<string>;
      appendix?: Iterable<string>;
      appendixReferences?: boolean;
      headingDivs?: boolean;
    } = {},
  ): SpecStripOptions {
    const names = (list: Iterable<string> | undefined): string[] => {
      const out: string[] = [];
      for (const item of list ?? []) {
        for (const n of item.split(',')) {
          if (n.trim() !== '') out.push(n.trim());
        }
      }
      return out;
    };
    const lists: Record<string, string[]> = {
      drop: names(init.drop),
      unmark: names(init.unmark),
      appendix: names(init.appendix),
    };
    const known = [...specStripKindNames, 'all'];
    for (const key of Object.keys(lists)) {
      for (const n of lists[key]) {
        if (!known.includes(n)) {
          throw new SpecStripUsageError(
            `unknown kind name "${n}" in ${key}; known names: ${known.join(', ')}`,
          );
        }
      }
    }
    const keys = Object.keys(lists);
    for (let i = 0; i < keys.length; i++) {
      for (let j = i + 1; j < keys.length; j++) {
        for (const n of lists[keys[i]]) {
          if (lists[keys[j]].includes(n)) {
            throw new SpecStripUsageError(
              `kind name "${n}" is in both ${keys[i]} and ${keys[j]}`,
            );
          }
        }
      }
    }
    if (lists.unmark.includes('comments')) {
      throw new SpecStripUsageError(
        'comments cannot be unmarked: a review annotation has no reading ' +
          'without its markers; drop it or leave it',
      );
    }
    if (lists.appendix.includes('comments')) {
      throw new SpecStripUsageError(
        'comments cannot be moved to the appendix; drop them or leave them',
      );
    }
    const explicit = new Set<string>();
    for (const l of Object.values(lists)) {
      for (const n of l) if (n !== 'all') explicit.add(n);
    }
    const expand = (list: string, all: readonly string[]): Set<string> => {
      const out = new Set<string>();
      for (const n of lists[list]) {
        if (n === 'all') {
          for (const k of all) if (!explicit.has(k)) out.add(k);
        } else {
          out.add(n);
        }
      }
      return out;
    };
    const appendix = expand('appendix', specStripNotationKinds);
    if (init.appendixReferences === true && appendix.size === 0) {
      throw new SpecStripUsageError(
        'appendix references need an appendix: name its kinds',
      );
    }
    return new SpecStripOptions({
      drop: expand('drop', specStripKindNames),
      unmark: expand('unmark', specStripNotationKinds),
      appendix,
      appendixReferences: init.appendixReferences === true,
      headingDivs: init.headingDivs === true,
    });
  }

  /** The options of the emptying rule: what would go is unmarked instead. */
  get keeping(): SpecStripOptions {
    const unmark = new Set([...this.unmark, ...this.appendix]);
    for (const k of this.drop) if (k !== 'comments') unmark.add(k);
    return new SpecStripOptions({
      drop: this.drop.has('comments') ? new Set(['comments']) : new Set(),
      unmark,
      headingDivs: this.headingDivs,
    });
  }

  /** @internal The options an appendix entry's own content is stripped with. */
  get inEntry(): SpecStripOptions {
    const drop = new Set(this.drop);
    drop.delete('comments');
    return new SpecStripOptions({
      drop,
      unmark: new Set([...this.unmark, ...this.appendix]),
    });
  }

  /** `names` in the canonical order of {@link specStripKindNames}. */
  static ordered(names: Set<string>): string[] {
    return specStripKindNames.filter((k) => names.has(k));
  }
}

/** The source a readable rendition was made from, for its header. */
export class SpecReadableSource {
  constructor(
    readonly file: string,
    readonly revision: string | null = null,
    readonly commit: string | null = null,
    readonly dirty = false,
  ) {}
}

/**
 * The readable header line of a stripped rendition (SOM §11.1): `<!--
 * readable: drop=…; unmark=…; appendix=…; appendix-references;
 * headings=divs; of=<file>@<revision>; commit=<sha>[+dirty] -->`. Parts that
 * do not apply are left out; {@link format} and {@link parse} are inverse.
 */
export class SpecReadableHeader {
  constructor(
    readonly options: SpecStripOptions,
    readonly source: SpecReadableSource | null = null,
  ) {}

  /** The header line. */
  format(): string {
    const o = this.options;
    const s = this.source;
    const parts: string[] = [];
    if (o.drop.size > 0) parts.push(`drop=${SpecStripOptions.ordered(o.drop).join(',')}`);
    if (o.unmark.size > 0) {
      parts.push(`unmark=${SpecStripOptions.ordered(o.unmark).join(',')}`);
    }
    if (o.appendix.size > 0) {
      parts.push(`appendix=${SpecStripOptions.ordered(o.appendix).join(',')}`);
    }
    if (o.appendixReferences) parts.push('appendix-references');
    if (o.headingDivs) parts.push('headings=divs');
    if (s !== null) parts.push(`of=${s.file}${s.revision !== null ? `@${s.revision}` : ''}`);
    if (s !== null && s.commit !== null) {
      parts.push(`commit=${s.commit}${s.dirty ? '+dirty' : ''}`);
    }
    return parts.length === 0
      ? '<!-- readable: -->'
      : `<!-- readable: ${parts.join('; ')} -->`;
  }

  /** `line` read as a readable header, or null. */
  static parse(line: string): SpecReadableHeader | null {
    const m = /^<!--\s*readable:(.*)-->$/.exec(line.trim());
    if (m === null) return null;
    const drop: string[] = [];
    const unmark: string[] = [];
    const appendix: string[] = [];
    let refs = false;
    let divs = false;
    let file: string | null = null;
    let revision: string | null = null;
    let commit: string | null = null;
    let dirty = false;
    for (const raw of m[1].split(';')) {
      const part = raw.trim();
      if (part === '') continue;
      const eq = part.indexOf('=');
      const key = eq < 0 ? part : part.substring(0, eq);
      const value = eq < 0 ? '' : part.substring(eq + 1);
      if (key === 'drop') {
        drop.push(value);
      } else if (key === 'unmark') {
        unmark.push(value);
      } else if (key === 'appendix') {
        appendix.push(value);
      } else if (key === 'appendix-references' && eq < 0) {
        refs = true;
      } else if (key === 'headings' && value === 'divs') {
        divs = true;
      } else if (key === 'of') {
        const at = value.lastIndexOf('@');
        file = at < 0 ? value : value.substring(0, at);
        revision = at < 0 ? null : value.substring(at + 1);
      } else if (key === 'commit') {
        dirty = value.endsWith('+dirty');
        commit = dirty ? value.substring(0, value.length - 6) : value;
      } else {
        return null;
      }
    }
    if (file === null && commit !== null) return null;
    try {
      return new SpecReadableHeader(
        SpecStripOptions.fromNames({
          drop,
          unmark,
          appendix,
          appendixReferences: refs,
          headingDivs: divs,
        }),
        file === null ? null : new SpecReadableSource(file, revision, commit, dirty),
      );
    } catch (e) {
      if (e instanceof SpecStripUsageError) return null;
      throw e;
    }
  }
}

/** One piece a strip removed from a value, anchored in the stripped text. */
export class SpecStripPiece {
  constructor(
    /** The offset in the stripped text the piece stands at. */
    readonly anchor: number,
    /** The offset in the original text the piece starts at. */
    readonly origin: number,
    /** The original text the piece removed. */
    readonly removed: string,
    /** The text the stripped value holds in its place. */
    readonly inserted: string,
    /** What removed it, sorted. */
    readonly labels: string[],
  ) {}

  toJson(): Record<string, unknown> {
    return {
      anchor: this.anchor,
      origin: this.origin,
      removed: this.removed,
      inserted: this.inserted,
      labels: this.labels,
    };
  }
}

/** One entry of a stripped rendition's appendix *Notes*. */
export class SpecAppendixEntry {
  constructor(
    readonly number: number,
    readonly kind: string,
    readonly text: string,
    readonly value: SpecStripValueRef | null = null,
  ) {}

  toJson(): Record<string, unknown> {
    const out: Record<string, unknown> = {
      number: this.number,
      kind: this.kind,
      text: this.text,
    };
    if (this.value !== null) out.value = this.value.toJson();
    return out;
  }
}

/** The result of stripping one value ({@link stripNotationText}). */
export class SpecStripTextResult {
  constructor(
    readonly text: string,
    readonly pieces: SpecStripPiece[],
    readonly dropped: Map<string, number>,
    readonly unmarked: Map<string, number>,
    readonly appended: Map<string, number>,
    readonly marksDropped: number,
    readonly appendix: SpecAppendixEntry[],
    readonly findings: NotationFinding[],
  ) {}

  /** Whether the value was refused for its findings. */
  get refused(): boolean {
    return this.findings.length > 0;
  }

  toJson(): Record<string, unknown> {
    return {
      text: this.text,
      dropped: Object.fromEntries(this.dropped),
      unmarked: Object.fromEntries(this.unmarked),
      appended: Object.fromEntries(this.appended),
      marksDropped: this.marksDropped,
      appendix: this.appendix.map((e) => e.toJson()),
      pieces: this.pieces.map((p) => p.toJson()),
      refused: this.findings.map((f) => f.code),
    };
  }
}

/**
 * Strips one value with `options` (SOM §11.10): comments first, then the
 * notation from the outside in, then the whitespace the removals leave.
 * Appendix entries are numbered from 1. A value whose notation has an error
 * finding (other than `rejectedBlock`) is refused and returned unchanged.
 */
export function stripNotationText(
  value: string,
  options: SpecStripOptions,
): SpecStripTextResult {
  return new _Plan(value, options).finish((i) => i + 1);
}

/** A value of a document: its content, a form field or its headline. */
export class SpecStripValueRef {
  constructor(
    readonly path: string,
    readonly field: string | null = null,
    readonly headline = false,
  ) {}

  read(doc: SpecDocument): string {
    return (
      (this.headline
        ? doc.headline(this.path)
        : this.field !== null
          ? doc.formField(this.path, this.field)
          : doc.content(this.path)) ?? ''
    );
  }

  write(doc: SpecDocument, value: string): void {
    if (this.headline) {
      doc.setHeadline(this.path, value);
    } else if (this.field !== null) {
      doc.setFormField(this.path, this.field, value);
    } else {
      doc.setContent(this.path, value);
    }
  }

  get label(): string {
    return this.headline
      ? `${this.path} (headline)`
      : this.field !== null
        ? `${this.path}/${this.field}`
        : this.path;
  }

  toJson(): Record<string, unknown> {
    const out: Record<string, unknown> = { path: this.path };
    if (this.field !== null) out.field = this.field;
    if (this.headline) out.headline = true;
    return out;
  }

  toString(): string {
    return this.label;
  }
}

/** One value a strip changed, with what went. */
export class SpecStrippedValue {
  constructor(
    readonly ref: SpecStripValueRef,
    readonly original: string,
    readonly stripped: string,
    readonly pieces: SpecStripPiece[],
  ) {}
}

/** A value the emptying rule kept. */
export class SpecStripKept {
  constructor(
    readonly ref: SpecStripValueRef,
    readonly finding: string,
  ) {}

  toString(): string {
    return `KEPT (would empty a required value): ${this.ref} — ${this.finding}`;
  }
}

/** A reason a stripped document is not valid. */
export class SpecStripFinding {
  constructor(
    /** `notation`, `instance`, `schema` or `parse`. */
    readonly kind: string,
    readonly message: string,
    readonly ref: SpecStripValueRef | null = null,
  ) {}

  toString(): string {
    return `${this.kind}: ${this.ref !== null ? `${this.ref}: ` : ''}${this.message}`;
  }
}

/** The result of {@link SpecDocumentStrip.strip}. */
export class SpecStripResult {
  constructor(
    readonly document: SpecDocument,
    readonly values: SpecStrippedValue[],
    readonly kept: SpecStripKept[],
    readonly removedItems: string[],
    readonly appendix: SpecAppendixEntry[],
    readonly dropped: Map<string, number>,
    readonly unmarked: Map<string, number>,
    readonly appended: Map<string, number>,
    readonly marksDropped: number,
    readonly readableHeader: string,
    readonly readable: string | null,
    readonly findings: SpecStripFinding[],
  ) {}

  /** Whether the stripped document is valid and may be written. */
  get ok(): boolean {
    return this.findings.length === 0;
  }

  /** The report: what was dropped, unmarked, moved and kept per kind. */
  get report(): string[] {
    const out: string[] = [];
    for (const k of specStripKindNames) {
      const d = this.dropped.get(k) ?? 0;
      const u = this.unmarked.get(k) ?? 0;
      const a = this.appended.get(k) ?? 0;
      if (d + u + a > 0) out.push(`${k}: ${d} dropped, ${u} unmarked, ${a} moved`);
    }
    if (this.marksDropped > 0) {
      out.push(`review marks inside dropped elements: ${this.marksDropped}`);
    }
    for (const k of this.kept) out.push(`${k}`);
    return out;
  }
}

/** The options of {@link SpecDocumentStrip.strip} beyond the switches. */
export interface SpecDocumentStripOptions {
  model?: SpecModel | null;
  schema?: DocSpecsSchema | null;
  rootType?: string | null;
  fileStem?: string | null;
  documentFiles?: Record<string, string>;
  source?: SpecReadableSource | null;
}

/** Stripping a whole document (SOM §11.10). */
export class SpecDocumentStrip {
  /**
   * Strips every value of `document` — content, form-field values, scalar
   * list items and stored headlines — into a copy. Given a model it also
   * applies the emptying rule, removes list items left empty, numbers the
   * appendix through the rendition, renders the `.readable.md` and checks it.
   */
  static strip(
    document: SpecDocument,
    options: SpecStripOptions,
    extra: SpecDocumentStripOptions = {},
  ): SpecStripResult {
    const model = extra.model ?? null;
    const schema = extra.schema ?? null;
    const rootType = extra.rootType ?? null;
    const codecOptions = {
      fileStem: extra.fileStem ?? null,
      documentFiles: extra.documentFiles ?? {},
    };
    const refs = SpecDocumentStrip._valueRefs(document);
    const findings: SpecStripFinding[] = [];
    const plans = new Map<number, _Plan>();
    refs.forEach((ref, index) => {
      const text = ref.read(document);
      if (text === '') return;
      const plan = new _Plan(text, options);
      if (plan.findings.length > 0) {
        for (const f of plan.findings) {
          findings.push(new SpecStripFinding('notation', `${_findingText(f)}`, ref));
        }
        return;
      }
      if (plan.changes) plans.set(index, plan);
    });

    const copy = new SpecDocument();
    copy.loadJson(JSON.parse(JSON.stringify(document.toJson())));
    const provisional = new Map<string, number>();
    let next = 1;
    for (let index = 0; index < refs.length; index++) {
      const plan = plans.get(index);
      if (plan === undefined) continue;
      for (let i = 0; i < plan.entries.length; i++) provisional.set(`${index}:${i}`, next++);
    }
    const apply = (numbers: Map<string, number>): void => {
      for (const [index, plan] of plans) {
        refs[index].write(copy, plan.finish((i) => numbers.get(`${index}:${i}`) ?? 0).text);
      }
    };
    apply(provisional);
    const kept: SpecStripKept[] = [];
    const base =
      model === null
        ? new Map<string, string>()
        : SpecDocumentStrip._tierFindings(model, schema, rootType, document);
    const removedItems =
      model === null
        ? []
        : SpecDocumentStrip._emptyingRule(
            model,
            schema,
            rootType,
            base,
            document,
            copy,
            refs,
            plans,
            kept,
            options,
          );

    // The appendix, numbered through the rendition.
    const entries: [number, number][] = [];
    for (let index = 0; index < refs.length; index++) {
      const plan = plans.get(index);
      if (plan === undefined) continue;
      for (let i = 0; i < plan.entries.length; i++) entries.push([index, i]);
    }
    let root: SpecRoot | null = null;
    if (model !== null) {
      try {
        root = copy.rootToExport(model, rootType);
      } catch (e) {
        findings.push(new SpecStripFinding('parse', (e as Error).message));
      }
    }
    const titles = new Map<string, string>();
    if (entries.length > 0 && model !== null && root !== null) {
      const map = new SpecDocumentMarkdown(model, copy, codecOptions).exportRootWithMap(root);
      const lines = map.markdown.split('\n');
      const order = new Map<string, number>();
      for (const [line, path] of map.headingPaths) {
        order.set(path, line);
        titles.set(path, SpecDocumentStrip._headingTitle(lines[line - 1]));
      }
      const sectionLine = (ref: SpecStripValueRef): number => {
        let best = 0;
        let bestLength = -1;
        for (const [p, line] of order) {
          if ((ref.path === p || ref.path.startsWith(`${p}/`)) && p.length > bestLength) {
            best = line;
            bestLength = p.length;
          }
        }
        return best;
      };
      entries.sort((a, b) => {
        const c = sectionLine(refs[a[0]]) - sectionLine(refs[b[0]]);
        if (c !== 0) return c;
        const d = a[0] - b[0];
        return d !== 0 ? d : a[1] - b[1];
      });
    }
    const numbers = new Map<string, number>();
    entries.forEach(([index, i], k) => numbers.set(`${index}:${i}`, k + 1));
    apply(numbers);

    const values: SpecStrippedValue[] = [];
    const appendix: SpecAppendixEntry[] = [];
    const dropped = new Map<string, number>();
    const unmarked = new Map<string, number>();
    const appended = new Map<string, number>();
    let marksDropped = 0;
    const add = (into: Map<string, number>, from: Map<string, number>): void => {
      for (const [k, v] of from) into.set(k, (into.get(k) ?? 0) + v);
    };
    for (let index = 0; index < refs.length; index++) {
      const plan = plans.get(index);
      if (plan === undefined) continue;
      const r = plan.finish((i) => numbers.get(`${index}:${i}`) ?? 0);
      values.push(new SpecStrippedValue(refs[index], plan.o, r.text, r.pieces));
      add(dropped, r.dropped);
      add(unmarked, r.unmarked);
      add(appended, r.appended);
      marksDropped += r.marksDropped;
      for (const e of r.appendix) {
        appendix.push(new SpecAppendixEntry(e.number, e.kind, e.text, refs[index]));
      }
    }
    appendix.sort((a, b) => a.number - b.number);

    const header = new SpecReadableHeader(options, extra.source ?? null).format();
    let readable: string | null = null;
    if (model !== null && root !== null) {
      const rendition = new SpecDocumentMarkdown(model, copy, {
        ...codecOptions,
        headingDivs: options.headingDivs,
        readableHeader: header,
      }).exportRootWithMap(root);
      if (titles.size === 0 && appendix.length > 0) {
        const lines = rendition.markdown.split('\n');
        for (const [line, path] of rendition.headingPaths) {
          titles.set(path, SpecDocumentStrip._headingTitle(lines[line - 1]));
        }
      }
      readable =
        appendix.length === 0
          ? rendition.markdown
          : SpecDocumentStrip._withAppendix(
              rendition.markdown,
              appendix,
              titles,
              options.appendixReferences,
            );
      SpecDocumentStrip._checkOutput(
        model,
        schema,
        root,
        rootType,
        base,
        document,
        copy,
        readable,
        codecOptions,
        findings,
      );
    }
    return new SpecStripResult(
      copy,
      values,
      kept,
      removedItems,
      appendix,
      dropped,
      unmarked,
      appended,
      marksDropped,
      header,
      readable,
      findings,
    );
  }

  private static _valueRefs(doc: SpecDocument): SpecStripValueRef[] {
    const sorted = (it: Iterable<string>): string[] => Array.from(it).sort(_cmp);
    const out: SpecStripValueRef[] = [];
    for (const p of sorted(doc.headlinePaths)) out.push(new SpecStripValueRef(p, null, true));
    for (const p of sorted(doc.contentPaths)) out.push(new SpecStripValueRef(p));
    for (const p of sorted(doc.formPaths)) {
      for (const f of sorted(doc.formFieldNames(p))) out.push(new SpecStripValueRef(p, f));
    }
    return out;
  }

  private static _emptyingRule(
    model: SpecModel,
    schema: DocSpecsSchema | null,
    rootType: string | null,
    base: Map<string, string>,
    document: SpecDocument,
    copy: SpecDocument,
    refs: SpecStripValueRef[],
    plans: Map<number, _Plan>,
    kept: SpecStripKept[],
    options: SpecStripOptions,
  ): string[] {
    const keptRefs = new Set<number>();
    const keepItems = new Set<string>();
    const candidates = SpecDocumentStrip._itemsAbove(
      copy,
      Array.from(plans.keys()).map((i) => refs[i]),
    );
    const emptiedItems = (): string[] =>
      candidates.filter(
        (item) =>
          !keepItems.has(item) && document.hasValuesUnder(item) && !copy.hasValuesUnder(item),
      );
    const concerns = (findingPath: string, path: string): boolean =>
      findingPath === '' ||
      path === findingPath ||
      path.startsWith(`${findingPath}/`) ||
      path.startsWith(`${findingPath}-`) ||
      findingPath.startsWith(`${path}/`);
    for (let round = 0; round < 8; round++) {
      const items = emptiedItems();
      let scratch = copy;
      if (items.length > 0) {
        scratch = new SpecDocument();
        scratch.loadJson(JSON.parse(JSON.stringify(copy.toJson())));
      }
      for (const item of items) scratch.removeListItem(item);
      const now = SpecDocumentStrip._tierFindings(model, schema, rootType, scratch);
      const added = new Map<string, string>();
      for (const [k, v] of now) if (!base.has(k)) added.set(k, v);
      if (added.size === 0) break;
      const emptied: number[] = [];
      for (let index = 0; index < refs.length; index++) {
        if (plans.has(index) && !keptRefs.has(index) && refs[index].read(copy).trim() === '') {
          emptied.push(index);
        }
      }
      let changed = false;
      for (const [key, findingPath] of added) {
        for (const item of items) {
          if (concerns(findingPath, item) && !keepItems.has(item)) {
            keepItems.add(item);
            changed = true;
          }
        }
        for (const index of emptied) {
          const ref = refs[index];
          if (keptRefs.has(index) || !concerns(findingPath, ref.path)) continue;
          keptRefs.add(index);
          kept.push(new SpecStripKept(ref, key));
          const keeping = new _Plan(plans.get(index)!.o, options.keeping);
          const text = keeping.finish(() => 0).text;
          if (text.trim() === '') {
            plans.delete(index);
            ref.write(copy, ref.read(document));
          } else {
            plans.set(index, keeping);
            ref.write(copy, text);
          }
          changed = true;
        }
      }
      if (!changed) break;
    }
    const items = emptiedItems();
    for (const item of items) copy.removeListItem(item);
    return items;
  }

  private static _itemsAbove(doc: SpecDocument, refs: SpecStripValueRef[]): string[] {
    const items = new Set<string>();
    for (const list of doc.listPaths) for (const i of doc.listItems(list)) items.add(i);
    const out = new Set<string>();
    for (const ref of refs) {
      const p = ref.path;
      if (items.has(p)) out.add(p);
      for (let i = 0; i < p.length; i++) {
        if (p.charCodeAt(i) === 0x2f && items.has(p.substring(0, i))) out.add(p.substring(0, i));
      }
    }
    return Array.from(out).sort(_cmp);
  }

  private static _tierFindings(
    model: SpecModel,
    schema: DocSpecsSchema | null,
    rootType: string | null,
    doc: SpecDocument,
  ): Map<string, string> {
    const out = new Map<string, string>();
    for (const e of validateDocument(model, doc)) {
      out.set(`instance ${e.code} ${e.path}: ${e.message}`, e.path);
    }
    if (schema !== null) {
      try {
        for (const v of validateSpecDocument(model, doc, schema, rootType ?? undefined)) {
          out.set(`schema ${v.rule} ${v.sectionId ?? ''}: ${v.message}`, v.path ?? '');
        }
      } catch {
        // No single root to render: the schema tier cannot judge it.
      }
    }
    return out;
  }

  private static _checkOutput(
    model: SpecModel,
    schema: DocSpecsSchema | null,
    root: SpecRoot,
    rootType: string | null,
    before: Map<string, string>,
    document: SpecDocument,
    copy: SpecDocument,
    readable: string,
    codecOptions: { fileStem: string | null; documentFiles: Record<string, string> },
    findings: SpecStripFinding[],
  ): void {
    const parsed = new SpecDocumentMarkdown(model, new SpecDocument(), codecOptions).parse(
      readable,
    );
    for (const r of parsed.rejections) {
      findings.push(new SpecStripFinding('parse', `the rendition rejects: ${r}`));
    }
    const prefix = root.sectionId ?? root.type;
    const inRoot = (p: string): boolean => p === prefix || p.startsWith(`${prefix}/`);
    const compare = (
      what: string,
      want: Map<string, string>,
      got: Map<string, string>,
    ): void => {
      const keys = Array.from(new Set([...want.keys(), ...got.keys()])).sort(_cmp);
      for (const k of keys) {
        if (!inRoot(k) || want.get(k) === got.get(k)) continue;
        const g = got.get(k);
        const w = want.get(k);
        findings.push(
          new SpecStripFinding(
            'parse',
            `${what} at ${k} reads back as ${g === undefined ? 'nothing' : `"${g}"`}` +
              ` instead of ${w === undefined ? 'nothing' : `"${w}"`}`,
          ),
        );
      }
    };
    const wantContent = new Map<string, string>();
    for (const p of copy.contentPaths) wantContent.set(p, copy.content(p)!);
    compare('content', wantContent, new Map(Object.entries(parsed.content)));
    const wantForms = new Map<string, string>();
    for (const p of copy.formPaths) {
      for (const f of copy.formFieldNames(p)) wantForms.set(`${p}/${f}`, copy.formField(p, f)!);
    }
    const gotForms = new Map<string, string>();
    for (const [p, fields] of Object.entries(parsed.forms)) {
      for (const [f, v] of Object.entries(fields)) gotForms.set(`${p}/${f}`, v);
    }
    compare('the form field', wantForms, gotForms);
    for (const key of SpecDocumentStrip._tierFindings(model, schema, rootType, copy).keys()) {
      if (!before.has(key)) {
        findings.push(new SpecStripFinding(key.startsWith('schema') ? 'schema' : 'instance', key));
      }
    }
    if (schema !== null) {
      const original = new SpecDocumentMarkdown(model, document, codecOptions).exportRoot(root);
      const key = (v: DocSpecsViolation): string =>
        `${v.rule} ${v.sectionId ?? ''}: ${v.message}`;
      const validator = new DocSpecsValidator(schema, { tomSpecs: true });
      const had = new Set(validator.validateMarkdown(original).map(key));
      for (const v of validator.validateMarkdown(readable)) {
        if (!had.has(key(v))) {
          findings.push(
            new SpecStripFinding('schema', `the rendition: line ${v.line}: ${key(v)}`),
          );
        }
      }
    }
  }

  private static _headingTitle(line: string): string {
    const div = SpecDocumentMarkdown.headingDiv(line);
    let rest: string;
    if (div !== null) {
      rest = div[1];
    } else {
      const h = SpecDocumentMarkdown.headingLine.exec(line);
      rest = h !== null ? h[2] : line;
    }
    const c = SpecDocumentMarkdown.headlineComment.exec(rest.trim());
    const title = c === null ? rest.trim() : (c[3] || '').trim();
    return stripOwnAnchor(title, c !== null ? c[1] : '');
  }

  private static _withAppendix(
    markdown: string,
    entries: SpecAppendixEntry[],
    titles: Map<string, string>,
    references: boolean,
  ): string {
    const sectionOf = (ref: SpecStripValueRef): [string, string] => {
      let best = '';
      let title = ref.path;
      for (const [p, t] of titles) {
        if ((ref.path === p || ref.path.startsWith(`${p}/`)) && p.length > best.length) {
          best = p;
          title = t;
        }
      }
      return [best === '' ? ref.path : best, title];
    };
    let b =
      markdown.replace(/\n+$/, '') +
      `\n\n${SpecDocumentMarkdown.appendixMarker}\n\n## Notes\n`;
    let section: string | null = null;
    for (const e of entries) {
      const [path, title] = e.value === null ? ['', ''] : sectionOf(e.value);
      if (path !== section) {
        b += `\n### ${title}\n`;
        section = path;
      }
      const text = e.text
        .split('\n')
        .map((l) => (l.startsWith('#') ? `\\${l}` : l))
        .join('\n');
      b += references
        ? `\n<a id="note-${e.number}"></a>**[${e.number}]** ${text} ` +
          `[↩](#note-${e.number}-ref)\n`
        : `\n**[${e.number}]** ${text}\n`;
    }
    return b;
  }
}

function _cmp(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

function _findingText(f: NotationFinding): string {
  return `${f.code} (line ${f.line}): ${f.message}`;
}

// ---------------------------------------------------------------------------
// One value's strip.

interface _Insert {
  label: string;
  text?: string;
  entry?: number;
}

const _KEEP = 0;
const _DEL = 1;
const _INS = 2;

interface _Op {
  type: number;
  char: string;
  label: string | null;
}

function _space(c: string): boolean {
  return c === ' ' || c === '\t';
}

/** The strip of one value, planned once and finished for any numbering. */
class _Plan {
  readonly o: string;
  readonly options: SpecStripOptions;
  t: string;
  script1: _Op[] | null = null;
  del: (string | null)[];
  blockDel: boolean[] = [];
  ins = new Map<number, _Insert[]>();
  dropped = new Map<string, number>();
  unmarked = new Map<string, number>();
  appended = new Map<string, number>();
  marksDropped = 0;
  entries: { kind: string; text: string }[] = [];
  findings: NotationFinding[];

  constructor(o: string, options: SpecStripOptions) {
    this.o = o;
    this.options = options;
    this.findings = scanNotation(o, { tomSpecs: true }).findings.filter(
      (f) => f.severity === 'error' && f.code !== NotationFindingCode.REJECTED_BLOCK,
    );
    if (this.findings.length > 0) {
      this.t = o;
      this.del = new Array<string | null>(o.length).fill(null);
      return;
    }
    if (options.drop.has('comments')) {
      this.t = stripAnnotationsText(o);
      if (this.t !== o) {
        this.dropped.set('comments', countAnnotationsText(o));
        this.script1 = _diff(o, this.t, 'comments');
      }
    } else {
      this.t = o;
    }
    this.del = new Array<string | null>(this.t.length).fill(null);
    this.blockDel = new Array<boolean>(this.t.length).fill(false);
    this._process(scanNotation(this.t, { tomSpecs: true }).elements);
    if (!options.drop.has('comments')) this._marks();
    if (this.del.some((d) => d !== null)) this._normalise();
  }

  get changes(): boolean {
    return (
      this.findings.length === 0 &&
      (this.script1 !== null || this.del.some((d) => d !== null) || this.ins.size > 0)
    );
  }

  private _mark(s: number, e: number, label: string, block = false): void {
    for (let i = s; i < e && i < this.t.length; i++) {
      if (this.del[i] === null) this.del[i] = label;
      if (block) this.blockDel[i] = true;
    }
  }

  private _insert(at: number, i: _Insert): void {
    const list = this.ins.get(at);
    if (list === undefined) this.ins.set(at, [i]);
    else list.push(i);
  }

  private static _count(m: Map<string, number>, k: string): void {
    m.set(k, (m.get(k) ?? 0) + 1);
  }

  private _process(list: NotationElement[]): void {
    const t = this.t;
    for (const e of list) {
      const k = e.kind;
      const secondary = e.isRegistered && k !== null && specStripNotationKinds.includes(k);
      if (!secondary) {
        this._process(e.children);
        continue;
      }
      if (this.options.drop.has(k)) {
        this._remove(e, `${k}:drop`, null);
        _Plan._count(this.dropped, k);
        continue;
      }
      if (this.options.appendix.has(k)) {
        const content =
          e.type === 'citation'
            ? t.substring(e.start, e.end)
            : t.substring(e.contentStart, e.contentEnd).replace(/\n+$/, '');
        this.entries.push({
          kind: k,
          text: stripNotationText(content, this.options.inEntry).text,
        });
        this._remove(e, `${k}:appendix`, this.entries.length - 1);
        _Plan._count(this.appended, k);
        continue;
      }
      if (this.options.unmark.has(k)) {
        this._unmark(e, `${k}:unmark`);
        _Plan._count(this.unmarked, k);
      }
      this._process(e.children);
    }
  }

  private _remove(e: NotationElement, label: string, entry: number | null): void {
    const t = this.t;
    const reference = entry !== null && this.options.appendixReferences;
    if (e.type === 'div') {
      this._mark(e.start, e.end, label, true);
      if (reference) this._insert(e.start, { label, entry: entry! });
      return;
    }
    const s = e.start;
    if (s > 0 && _space(t[s - 1]) && this.del[s - 1] === null) {
      this.del[s - 1] = label;
    } else if (
      !reference &&
      (s === 0 || t[s - 1] === '\n') &&
      e.end < t.length &&
      _space(t[e.end])
    ) {
      this.del[e.end] = label;
    }
    this._mark(e.start, e.end, label);
    if (reference) this._insert(e.start, { label, entry: entry! });
  }

  private _unmark(e: NotationElement, label: string): void {
    if (e.type === 'div') {
      if (e.contentStart >= e.contentEnd) {
        this._mark(e.start, e.end, label, true);
      } else {
        this._mark(e.start, e.contentStart, label, true);
        this._mark(e.contentEnd - 1, e.end, label, true);
      }
    } else if (e.type === 'span') {
      this._mark(e.start, e.start + 1, label);
      this._mark(e.contentEnd, e.end, label);
    } else {
      this._mark(e.start + 1, e.contentStart, label);
    }
  }

  private _marks(): void {
    for (const m of _findMarks(this.t)) {
      if (this._allDeleted(m.start, m.end)) {
        this.marksDropped++;
        continue;
      }
      if (m.sep < 0) {
        if (this._hadText(m.bodyStart, m.bodyEnd) && !this._survives(m.bodyStart, m.bodyEnd)) {
          this._removeMark(m);
        }
        continue;
      }
      const oldHad = this._hadText(m.bodyStart, m.sep);
      const newHad = this._hadText(m.sep + 2, m.bodyEnd);
      const oldLeft = this._survives(m.bodyStart, m.sep);
      const newLeft = this._survives(m.sep + 2, m.bodyEnd);
      if (!oldLeft && !newLeft && (oldHad || newHad)) {
        this._removeMark(m);
      } else if (oldHad && !oldLeft) {
        this._convert(m, '++', m.bodyStart, m.sep + 2);
      } else if (newHad && !newLeft) {
        this._convert(m, '--', m.sep, m.bodyEnd);
      }
    }
  }

  private _removeMark(m: _MarkAt): void {
    const t = this.t;
    const s = m.start;
    if (s > 0 && _space(t[s - 1]) && this.del[s - 1] === null) {
      this.del[s - 1] = 'mark';
    } else if ((s === 0 || t[s - 1] === '\n') && m.end < t.length && _space(t[m.end])) {
      this.del[m.end] = 'mark';
    }
    this._mark(m.start, m.end, 'mark');
  }

  private _convert(m: _MarkAt, delimiter: string, s: number, e: number): void {
    this._mark(m.start + 1, m.start + 3, 'mark');
    this._insert(m.start + 3, { label: 'mark', text: delimiter });
    this._mark(s, e, 'mark');
    this._mark(m.end - 3, m.end - 1, 'mark');
    this._insert(m.end - 1, { label: 'mark', text: delimiter });
  }

  private _allDeleted(s: number, e: number): boolean {
    for (let i = s; i < e; i++) if (this.del[i] === null) return false;
    return true;
  }

  private _hadText(s: number, e: number): boolean {
    return this.t.substring(s, e).trim() !== '';
  }

  private _survives(s: number, e: number): boolean {
    for (let i = s; i < e; i++) {
      if (this.del[i] === null && this.t[i].trim() !== '') return true;
    }
    return false;
  }

  private _normalise(): void {
    const t = this.t;
    const del = this.del;
    const starts = [0];
    for (let i = 0; i < t.length; i++) if (t[i] === '\n') starts.push(i + 1);
    for (let l = 0; l < starts.length; l++) {
      const s = starts[l];
      const e = l + 1 < starts.length ? starts[l + 1] - 1 : t.length;
      if (t.substring(s, e).trim() === '') continue;
      let touched = false;
      let survives = false;
      let allBlock = true;
      for (let i = s; i < e; i++) {
        if (del[i] !== null) touched = true;
        else if (t[i].trim() !== '') survives = true;
        if (!this.blockDel[i]) allBlock = false;
      }
      for (let i = s; i <= e; i++) if (this.ins.has(i)) survives = true;
      if (!touched || survives || allBlock) continue;
      this._mark(s, e, 'whitespace');
      if (e < t.length) {
        if (del[e] === null) del[e] = 'whitespace';
      } else if (s > 0) {
        if (del[s - 1] === null) del[s - 1] = 'whitespace';
      }
    }
    // Blank-line runs, read on the text as it now stands.
    const kept: number[] = [];
    let b = '';
    for (let i = 0; i <= t.length; i++) {
      for (const x of this.ins.get(i) ?? []) {
        const s = x.text ?? 'x'; // a reference is never blank
        for (let k = 0; k < s.length; k++) kept.push(-1);
        b += s;
      }
      if (i < t.length && del[i] === null) {
        kept.push(i);
        b += t[i];
      }
    }
    const solid = (c: string): boolean => c.trim() !== '';
    let firstSolid = 0;
    while (firstSolid < b.length && !solid(b[firstSolid])) firstSolid++;
    if (firstSolid === b.length) {
      for (const i of kept) if (i >= 0 && del[i] === null) del[i] = 'whitespace';
      return;
    }
    let lastSolid = b.length - 1;
    while (!solid(b[lastSolid])) lastSolid--;
    const lead = b.lastIndexOf('\n', firstSolid);
    for (let k = 0; k <= lead; k++) {
      if (kept[k] >= 0 && del[kept[k]] === null) del[kept[k]] = 'whitespace';
    }
    const trail = b.indexOf('\n', lastSolid);
    if (trail >= 0) {
      for (let k = trail; k < b.length; k++) {
        if (kept[k] >= 0 && del[kept[k]] === null) del[kept[k]] = 'whitespace';
      }
    }
    let k = firstSolid;
    while (k < lastSolid) {
      if (solid(b[k])) {
        k++;
        continue;
      }
      const runStart = k;
      while (!solid(b[k])) k++;
      const runEnd = k;
      const breaks: number[] = [];
      for (let j = runStart; j < runEnd; j++) if (b[j] === '\n') breaks.push(j);
      if (breaks.length <= 2) continue;
      const from = kept[runStart - 1];
      const to = kept[runEnd];
      let atRemoval = false;
      if (from >= 0 && to >= 0) {
        for (let i = from + 1; i < to; i++) {
          if (del[i] !== null && del[i] !== 'whitespace') atRemoval = true;
        }
      } else {
        atRemoval = true;
      }
      if (!atRemoval) continue;
      for (let j = breaks[0] + 1; j <= breaks[breaks.length - 1] - 1; j++) {
        if (kept[j] >= 0 && del[kept[j]] === null) del[kept[j]] = 'whitespace';
      }
    }
  }

  finish(number: (entry: number) => number): SpecStripTextResult {
    if (this.findings.length > 0) {
      return new SpecStripTextResult(
        this.o,
        [],
        new Map(),
        new Map(),
        new Map(),
        0,
        [],
        this.findings,
      );
    }
    const t = this.t;
    const insertText = (x: _Insert): string => {
      if (x.text !== undefined) return x.text;
      const n = number(x.entry!);
      return `<a id="note-${n}-ref"></a>[\\[${n}\\]](#note-${n})`;
    };
    const script2: _Op[] = [];
    for (let i = 0; i <= t.length; i++) {
      for (const x of this.ins.get(i) ?? []) {
        const s = insertText(x);
        for (let k = 0; k < s.length; k++) script2.push({ type: _INS, char: s[k], label: x.label });
      }
      if (i < t.length) {
        script2.push(
          this.del[i] === null
            ? { type: _KEEP, char: t[i], label: null }
            : { type: _DEL, char: t[i], label: this.del[i] },
        );
      }
    }
    const ops = this.script1 === null ? script2 : _compose(this.script1, script2);
    let out = '';
    const pieces: SpecStripPiece[] = [];
    let oPos = 0;
    let bPos = 0;
    let i = 0;
    while (i < ops.length) {
      if (ops[i].type === _KEEP) {
        out += ops[i].char;
        oPos++;
        bPos++;
        i++;
        continue;
      }
      const anchor = bPos;
      const origin = oPos;
      let removed = '';
      let inserted = '';
      const labels = new Set<string>();
      while (i < ops.length && ops[i].type !== _KEEP) {
        const op = ops[i];
        if (op.label !== null) labels.add(op.label);
        if (op.type === _DEL) {
          removed += op.char;
          oPos++;
        } else {
          inserted += op.char;
          out += op.char;
          bPos++;
        }
        i++;
      }
      pieces.push(
        new SpecStripPiece(anchor, origin, removed, inserted, Array.from(labels).sort(_cmp)),
      );
    }
    return new SpecStripTextResult(
      out,
      pieces,
      new Map(this.dropped),
      new Map(this.unmarked),
      new Map(this.appended),
      this.marksDropped,
      this.entries.map((e, k) => new SpecAppendixEntry(number(k), e.kind, e.text)),
      [],
    );
  }
}

/** Composes the scripts original → middle (`s1`) and middle → result (`s2`). */
function _compose(s1: _Op[], s2: _Op[]): _Op[] {
  const out: _Op[] = [];
  let j = 0;
  const flushInserts = (): void => {
    while (j < s2.length && s2[j].type === _INS) out.push(s2[j++]);
  };
  for (const a of s1) {
    if (a.type === _DEL) {
      out.push(a);
      continue;
    }
    flushInserts();
    const b = s2[j++];
    if (a.type === _KEEP) {
      out.push(b.type === _KEEP ? a : { type: _DEL, char: a.char, label: b.label });
    } else if (b.type === _KEEP) {
      out.push(a);
    }
  }
  flushInserts();
  return out;
}

/** An edit script from `a` to `b`: Myers by line, then by word token. */
function _diff(a: string, b: string, label: string): _Op[] {
  const out: _Op[] = [];
  const chars = (type: number, s: string): void => {
    for (let k = 0; k < s.length; k++) {
      out.push({ type, char: s[k], label: type === _KEEP ? null : label });
    }
  };
  let deleted = '';
  let inserted = '';
  const flush = (): void => {
    if (deleted === '' && inserted === '') return;
    for (const [type, token] of _myers(_tokens(deleted), _tokens(inserted))) chars(type, token);
    deleted = '';
    inserted = '';
  };
  for (const [type, line] of _myers(_lines(a), _lines(b))) {
    if (type === _KEEP) {
      flush();
      chars(_KEEP, line);
    } else if (type === _DEL) {
      deleted += line;
    } else {
      inserted += line;
    }
  }
  flush();
  return out;
}

function _lines(s: string): string[] {
  const out: string[] = [];
  let i = 0;
  while (i < s.length) {
    const n = s.indexOf('\n', i);
    const e = n < 0 ? s.length : n + 1;
    out.push(s.substring(i, e));
    i = e;
  }
  return out;
}

function _tokenKind(c: number): number {
  if (c === 0x20 || c === 0x09 || c === 0x0a || c === 0x0d) return 2;
  if (
    (c >= 0x30 && c <= 0x39) ||
    (c >= 0x41 && c <= 0x5a) ||
    (c >= 0x61 && c <= 0x7a) ||
    c === 0x5f ||
    c >= 0x80
  ) {
    return 1;
  }
  return 0;
}

function _tokens(s: string): string[] {
  const out: string[] = [];
  let i = 0;
  while (i < s.length) {
    const k = _tokenKind(s.charCodeAt(i));
    let j = i + 1;
    if (k !== 0) {
      while (j < s.length && _tokenKind(s.charCodeAt(j)) === k) j++;
    }
    out.push(s.substring(i, j));
    i = j;
  }
  return out;
}

function _myers(a: string[], b: string[]): [number, string][] {
  const n = a.length;
  const m = b.length;
  const max = n + m;
  if (max === 0) return [];
  const cap = 2000;
  const off = max + 1;
  const v = new Int32Array(2 * max + 3);
  const trace: Int32Array[] = [];
  let found = -1;
  for (let d = 0; d <= max && d <= cap; d++) {
    if (d > 0) {
      const snap = new Int32Array(2 * d - 1);
      for (let k = -(d - 1); k <= d - 1; k++) snap[k + d - 1] = v[k + off];
      trace.push(snap);
    }
    for (let k = -d; k <= d; k += 2) {
      let x =
        k === -d || (k !== d && v[k - 1 + off] < v[k + 1 + off])
          ? v[k + 1 + off]
          : v[k - 1 + off] + 1;
      let y = x - k;
      while (x < n && y < m && a[x] === b[y]) {
        x++;
        y++;
      }
      v[k + off] = x;
      if (x >= n && y >= m) {
        found = d;
        break;
      }
    }
    if (found >= 0) break;
  }
  if (found < 0) {
    return [
      ...a.map((t): [number, string] => [_DEL, t]),
      ...b.map((t): [number, string] => [_INS, t]),
    ];
  }
  const rev: [number, string][] = [];
  let x = n;
  let y = m;
  for (let d = found; d > 0; d--) {
    const snap = trace[d - 1];
    const at = (k: number): number => snap[k + d - 1];
    const k = x - y;
    const prevK = k === -d || (k !== d && at(k - 1) < at(k + 1)) ? k + 1 : k - 1;
    const prevX = at(prevK);
    const prevY = prevX - prevK;
    while (x > prevX && y > prevY) {
      rev.push([_KEEP, a[x - 1]]);
      x--;
      y--;
    }
    if (x === prevX) rev.push([_INS, b[y - 1]]);
    else rev.push([_DEL, a[x - 1]]);
    x = prevX;
    y = prevY;
  }
  while (x > 0 && y > 0) {
    rev.push([_KEEP, a[x - 1]]);
    x--;
    y--;
  }
  return rev.reverse();
}

interface _MarkAt {
  start: number;
  end: number;
  bodyStart: number;
  bodyEnd: number;
  sep: number;
}

const _MARK_CLOSE: Record<string, string> = {
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
  '{==': '==}',
  '{>>': '<<}',
};

function _findMarks(t: string): _MarkAt[] {
  const code = new Array<boolean>(t.length).fill(false);
  const fence = new MarkdownFenceTracker();
  let s = 0;
  for (const line of t.split('\n')) {
    const inFence = fence.inFence;
    fence.feed(line);
    if (inFence || fence.inFence) {
      for (let i = s; i < s + line.length; i++) code[i] = true;
    } else {
      let i = 0;
      while (i < line.length) {
        if (line[i] !== '`') {
          i++;
          continue;
        }
        let j = i;
        while (j < line.length && line[j] === '`') j++;
        const ticks = line.substring(i, j);
        const close = line.indexOf(ticks, j);
        if (close < 0) {
          i = j;
          continue;
        }
        for (let k = s + i; k < s + close + ticks.length; k++) code[k] = true;
        i = close + ticks.length;
      }
    }
    s += line.length + 1;
  }
  const out: _MarkAt[] = [];
  let i = 0;
  while (i + 3 <= t.length) {
    const opener = t.substring(i, i + 3);
    const closer = _MARK_CLOSE[opener];
    if (closer === undefined || code[i]) {
      i++;
      continue;
    }
    const paragraphEnd = /\n[ \t]*\n/.exec(t.substring(i));
    const limit = paragraphEnd === null ? t.length : i + paragraphEnd.index;
    const close = t.indexOf(closer, i + 3);
    if (close < 0 || close + 3 > limit) {
      i++;
      continue;
    }
    let sep = -1;
    if (opener === '{~~') {
      sep = t.indexOf('~>', i + 3);
      if (sep < 0 || sep >= close) {
        i++;
        continue;
      }
    }
    out.push({ start: i, end: close + 3, bodyStart: i + 3, bodyEnd: close, sep });
    i = close + 3;
  }
  return out;
}
