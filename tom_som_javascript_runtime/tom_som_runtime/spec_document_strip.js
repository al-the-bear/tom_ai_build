/**
 * Stripped renditions (SOM §11.10; the reading view's part *Stripped
 * renditions and the merge back*): a copy of a document with the secondary
 * prose of named kinds dropped, unmarked or moved to an appendix.
 *
 * The kinds are the four the reading notation registers as secondary
 * (`provenance`, `trace`, `editorial`, `aside`, DocSpecs RN-5), `linked`, the
 * navigation marker (SOM §11.11), and `derived`, the generated parts (SOM
 * §11.12) — both removed by `drop` and `unmark` alike, the rendition then
 * writing none —, and `comments`, the review annotations (SOM §11.9). A citation shape counts as
 * a span of its kind. `refs`, `records` and `rejected` are never secondary:
 * no name drops or unmarks them (RN-11).
 *
 * The port of `spec_document_strip.dart` / `.ts`; `strip_cases.json` holds them to
 * the same results.
 */

const {
  DocSpecsValidator,
  stripOwnAnchor,
} = require('./docspecs_validator');
const { SpecDocument } = require('./spec_document');
const {
  MarkdownFenceTracker,
  SpecDocumentMarkdown,
} = require('./spec_document_markdown');

const {
  NotationFindingCode,
  scanNotation,
} = require('./spec_notation');
const {
  countAnnotationsText,
  stripAnnotationsText,
} = require('./spec_review_annotations');
const { validateSpecDocument } = require('./spec_schema_validation');
const { validateDocument } = require('./spec_validator');

/** The kind names a strip takes, in report and header order. */
const specStripKindNames = [
  'provenance',
  'trace',
  'editorial',
  'aside',
  'linked',
  'derived',
  'comments',
];

/** The notation kinds a strip can drop, unmark or move to the appendix. */
const specStripNotationKinds = [
  'provenance',
  'trace',
  'editorial',
  'aside',
];

/** A strip asked for something it cannot do; the message says which. */
class SpecStripUsageError extends Error {
  constructor(message) {
    super(message);
    this.name = 'SpecStripUsageError';
  }
}

/** The options as sets; {@link SpecStripOptions.fromNames} is the checked form. */

/** What a strip does with each kind. */
class SpecStripOptions {
  /** The kinds removed with their content. */
           drop;
  /** The kinds whose markers go and whose content stays. */
           unmark;
  /** Whether the rendition leaves the `linked` markers out (SOM §11.11):
   *  `linked` dropped or unmarked. */
  get writesNoLinkedMarkers() {
    return this.drop.has('linked') || this.unmark.has('linked');
  }
  /** Whether the rendition leaves the generated parts out (SOM §11.12):
   *  `derived` dropped or unmarked. */
  get writesNoGeneratedParts() {
    return this.drop.has('derived') || this.unmark.has('derived');
  }
  /** The kinds moved, with their content, into the appendix *Notes*. */
           appendix;
  /** Whether each moved element leaves a link `[n]` to its entry. */
           appendixReferences;
  /** Whether sections deeper than level 6 are styled-div headings. */
           headingDivs;

  constructor(init = {}) {
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
    init   

      = {},
  ) {
    const names = (list) => {
      const out = [];
      for (const item of list ?? []) {
        for (const n of item.split(',')) {
          if (n.trim() !== '') out.push(n.trim());
        }
      }
      return out;
    };
    const lists = {
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
    for (const k of ['linked', 'derived']) {
      if (lists.appendix.includes(k)) {
        throw new SpecStripUsageError(
          `${k} cannot be moved to the appendix: the renderer writes it from ` +
            'the document; drop it or leave it',
        );
      }
    }
    const explicit = new Set();
    for (const l of Object.values(lists)) {
      for (const n of l) if (n !== 'all') explicit.add(n);
    }
    const expand = (list, all) => {
      const out = new Set();
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
      unmark: expand('unmark', [...specStripNotationKinds, 'linked', 'derived']),
      appendix,
      appendixReferences: init.appendixReferences === true,
      headingDivs: init.headingDivs === true,
    });
  }

  /** The options of the emptying rule: what would go is unmarked instead. */
  get keeping() {
    const unmark = new Set([...this.unmark, ...this.appendix]);
    for (const k of this.drop) if (k !== 'comments') unmark.add(k);
    return new SpecStripOptions({
      drop: this.drop.has('comments') ? new Set(['comments']) : new Set(),
      unmark,
      headingDivs: this.headingDivs,
    });
  }

  /** @internal The options an appendix entry's own content is stripped with. */
  get inEntry() {
    const drop = new Set(this.drop);
    drop.delete('comments');
    return new SpecStripOptions({
      drop,
      unmark: new Set([...this.unmark, ...this.appendix]),
    });
  }

  /** `names` in the canonical order of {@link specStripKindNames}. */
  static ordered(names) {
    return specStripKindNames.filter((k) => names.has(k));
  }
}

/** The source a readable rendition was made from, for its header. */
class SpecReadableSource {
  constructor(
    file,
    revision = null,
    commit = null,
    dirty = false,
  ) {
    this.file = file;
    this.revision = revision;
    this.commit = commit;
    this.dirty = dirty;
  }
}

/**
 * The readable header line of a stripped rendition (SOM §11.1): `<!--
 * readable: drop=…; unmark=…; appendix=…; appendix-references;
 * headings=divs; of=<file>@<revision>; commit=<sha>[+dirty] -->`. Parts that
 * do not apply are left out; {@link format} and {@link parse} are inverse.
 */
class SpecReadableHeader {
  constructor(
    options,
    source = null,
  ) {
    this.options = options;
    this.source = source;
  }

  /** The header line. */
  format() {
    const o = this.options;
    const s = this.source;
    const parts = [];
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
  static parse(line) {
    const m = /^<!--\s*readable:(.*)-->$/.exec(line.trim());
    if (m === null) return null;
    const drop = [];
    const unmark = [];
    const appendix = [];
    let refs = false;
    let divs = false;
    let file = null;
    let revision = null;
    let commit = null;
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
class SpecStripPiece {
  constructor(
    /** The offset in the stripped text the piece stands at. */
    anchor,
    /** The offset in the original text the piece starts at. */
    origin,
    /** The original text the piece removed. */
    removed,
    /** The text the stripped value holds in its place. */
    inserted,
    /** What removed it, sorted. */
    labels,
  ) {
    this.anchor = anchor;
    this.origin = origin;
    this.removed = removed;
    this.inserted = inserted;
    this.labels = labels;
  }

  toJson() {
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
class SpecAppendixEntry {
  constructor(
    number,
    kind,
    text,
    value = null,
  ) {
    this.number = number;
    this.kind = kind;
    this.text = text;
    this.value = value;
  }

  toJson() {
    const out = {
      number: this.number,
      kind: this.kind,
      text: this.text,
    };
    if (this.value !== null) out.value = this.value.toJson();
    return out;
  }
}

/** The result of stripping one value ({@link stripNotationText}). */
class SpecStripTextResult {
  constructor(
    text,
    pieces,
    dropped,
    unmarked,
    appended,
    marksDropped,
    appendix,
    findings,
  ) {
    this.text = text;
    this.pieces = pieces;
    this.dropped = dropped;
    this.unmarked = unmarked;
    this.appended = appended;
    this.marksDropped = marksDropped;
    this.appendix = appendix;
    this.findings = findings;
  }

  /** Whether the value was refused for its findings. */
  get refused() {
    return this.findings.length > 0;
  }

  toJson() {
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
function stripNotationText(
  value,
  options,
) {
  return new _Plan(value, options).finish((i) => i + 1);
}

/** A value of a document: its content, a form field or its headline. */
class SpecStripValueRef {
  constructor(
    path,
    field = null,
    headline = false,
  ) {
    this.path = path;
    this.field = field;
    this.headline = headline;
  }

  read(doc) {
    return (
      (this.headline
        ? doc.headline(this.path)
        : this.field !== null
          ? doc.formField(this.path, this.field)
          : doc.content(this.path)) ?? ''
    );
  }

  write(doc, value) {
    if (this.headline) {
      doc.setHeadline(this.path, value);
    } else if (this.field !== null) {
      doc.setFormField(this.path, this.field, value);
    } else {
      doc.setContent(this.path, value);
    }
  }

  get label() {
    return this.headline
      ? `${this.path} (headline)`
      : this.field !== null
        ? `${this.path}/${this.field}`
        : this.path;
  }

  toJson() {
    const out = { path: this.path };
    if (this.field !== null) out.field = this.field;
    if (this.headline) out.headline = true;
    return out;
  }

  toString() {
    return this.label;
  }
}

/** One value a strip changed, with what went. */
class SpecStrippedValue {
  constructor(
    ref,
    original,
    stripped,
    pieces,
  ) {
    this.ref = ref;
    this.original = original;
    this.stripped = stripped;
    this.pieces = pieces;
  }
}

/** A value the emptying rule kept. */
class SpecStripKept {
  constructor(
    ref,
    finding,
  ) {
    this.ref = ref;
    this.finding = finding;
  }

  toString() {
    return `KEPT (would empty a required value): ${this.ref} — ${this.finding}`;
  }
}

/** A reason a stripped document is not valid. */
class SpecStripFinding {
  constructor(
    /** `notation`, `instance`, `schema` or `parse`. */
    kind,
    message,
    ref = null,
  ) {
    this.kind = kind;
    this.message = message;
    this.ref = ref;
  }

  toString() {
    return `${this.kind}: ${this.ref !== null ? `${this.ref}: ` : ''}${this.message}`;
  }
}

/** The result of {@link SpecDocumentStrip.strip}. */
class SpecStripResult {
  constructor(
    document,
    values,
    kept,
    removedItems,
    appendix,
    dropped,
    unmarked,
    appended,
    marksDropped,
    readableHeader,
    readable,
    findings,
  ) {
    this.document = document;
    this.values = values;
    this.kept = kept;
    this.removedItems = removedItems;
    this.appendix = appendix;
    this.dropped = dropped;
    this.unmarked = unmarked;
    this.appended = appended;
    this.marksDropped = marksDropped;
    this.readableHeader = readableHeader;
    this.readable = readable;
    this.findings = findings;
  }

  /** Whether the stripped document is valid and may be written. */
  get ok() {
    return this.findings.length === 0;
  }

  /** The report: what was dropped, unmarked, moved and kept per kind. */
  get report() {
    const out = [];
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

/** Stripping a whole document (SOM §11.10). */
class SpecDocumentStrip {
  /**
   * Strips every value of `document` — content, form-field values, scalar
   * list items and stored headlines — into a copy. Given a model it also
   * applies the emptying rule, removes list items left empty, numbers the
   * appendix through the rendition, renders the `.readable.md` and checks it.
   */
  static strip(
    document,
    options,
    extra = {},
  ) {
    const model = extra.model ?? null;
    const schema = extra.schema ?? null;
    const rootType = extra.rootType ?? null;
    const codecOptions = {
      fileStem: extra.fileStem ?? null,
      documentFiles: extra.documentFiles ?? {},
    };
    const refs = SpecDocumentStrip._valueRefs(document);
    const findings = [];
    const plans = new Map();
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
    const provisional = new Map();
    let next = 1;
    for (let index = 0; index < refs.length; index++) {
      const plan = plans.get(index);
      if (plan === undefined) continue;
      for (let i = 0; i < plan.entries.length; i++) provisional.set(`${index}:${i}`, next++);
    }
    const apply = (numbers) => {
      for (const [index, plan] of plans) {
        refs[index].write(copy, plan.finish((i) => numbers.get(`${index}:${i}`) ?? 0).text);
      }
    };
    apply(provisional);
    const kept = [];
    const base =
      model === null
        ? new Map()
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
    const entries = [];
    for (let index = 0; index < refs.length; index++) {
      const plan = plans.get(index);
      if (plan === undefined) continue;
      for (let i = 0; i < plan.entries.length; i++) entries.push([index, i]);
    }
    let root = null;
    if (model !== null) {
      try {
        root = copy.rootToExport(model, rootType);
      } catch (e) {
        findings.push(new SpecStripFinding('parse', (e).message));
      }
    }
    const titles = new Map();
    if (entries.length > 0 && model !== null && root !== null) {
      const map = new SpecDocumentMarkdown(model, copy, codecOptions).exportRootWithMap(root);
      const lines = map.markdown.split('\n');
      const order = new Map();
      for (const [line, path] of map.headingPaths) {
        order.set(path, line);
        titles.set(path, SpecDocumentStrip._headingTitle(lines[line - 1]));
      }
      const sectionLine = (ref) => {
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
    const numbers = new Map();
    entries.forEach(([index, i], k) => numbers.set(`${index}:${i}`, k + 1));
    apply(numbers);

    const values = [];
    const appendix = [];
    const dropped = new Map();
    const unmarked = new Map();
    const appended = new Map();
    let marksDropped = 0;
    const add = (into, from) => {
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
    let readable = null;
    if (model !== null && root !== null) {
      const rendition = new SpecDocumentMarkdown(model, copy, {
        ...codecOptions,
        headingDivs: options.headingDivs,
        readableHeader: header,
        linkedMarkers: !options.writesNoLinkedMarkers,
        generatedParts: !options.writesNoGeneratedParts,
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

          static _valueRefs(doc) {
    const sorted = (it) => Array.from(it).sort(_cmp);
    const out = [];
    for (const p of sorted(doc.headlinePaths)) out.push(new SpecStripValueRef(p, null, true));
    for (const p of sorted(doc.contentPaths)) out.push(new SpecStripValueRef(p));
    for (const p of sorted(doc.formPaths)) {
      for (const f of sorted(doc.formFieldNames(p))) out.push(new SpecStripValueRef(p, f));
    }
    return out;
  }

          static _emptyingRule(
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
  ) {
    const keptRefs = new Set();
    const keepItems = new Set();
    const candidates = SpecDocumentStrip._itemsAbove(
      copy,
      Array.from(plans.keys()).map((i) => refs[i]),
    );
    const emptiedItems = () =>
      candidates.filter(
        (item) =>
          !keepItems.has(item) && document.hasValuesUnder(item) && !copy.hasValuesUnder(item),
      );
    const concerns = (findingPath, path) =>
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
      const added = new Map();
      for (const [k, v] of now) if (!base.has(k)) added.set(k, v);
      if (added.size === 0) break;
      const emptied = [];
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
          const keeping = new _Plan(plans.get(index).o, options.keeping);
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

          static _itemsAbove(doc, refs) {
    const items = new Set();
    for (const list of doc.listPaths) for (const i of doc.listItems(list)) items.add(i);
    const out = new Set();
    for (const ref of refs) {
      const p = ref.path;
      if (items.has(p)) out.add(p);
      for (let i = 0; i < p.length; i++) {
        if (p.charCodeAt(i) === 0x2f && items.has(p.substring(0, i))) out.add(p.substring(0, i));
      }
    }
    return Array.from(out).sort(_cmp);
  }

          static _tierFindings(
    model,
    schema,
    rootType,
    doc,
  ) {
    const out = new Map();
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

          static _checkOutput(
    model,
    schema,
    root,
    rootType,
    before,
    document,
    copy,
    readable,
    codecOptions,
    findings,
  ) {
    const parsed = new SpecDocumentMarkdown(model, new SpecDocument(), codecOptions).parse(
      readable,
    );
    for (const r of parsed.rejections) {
      findings.push(new SpecStripFinding('parse', `the rendition rejects: ${r}`));
    }
    const prefix = root.sectionId ?? root.type;
    const inRoot = (p) => p === prefix || p.startsWith(`${prefix}/`);
    const compare = (
      what,
      want,
      got,
    ) => {
      const keys = Array.from(new Set([...want.keys(), ...got.keys()])).sort(_cmp);
      for (const k of keys) {
        if (!inRoot(k) || want.get(k) === got.get(k)) continue;
        // A wrapped paragraph written in a table cell reads back on one line
        // (SOM §11.4).
        const wk = want.get(k);
        if (
          wk !== undefined &&
          SpecDocumentMarkdown.wrappedParagraphJoined(wk) === got.get(k)
        ) {
          continue;
        }
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
    const wantContent = new Map();
    for (const p of copy.contentPaths) wantContent.set(p, copy.content(p));
    compare('content', wantContent, new Map(Object.entries(parsed.content)));
    const wantForms = new Map();
    for (const p of copy.formPaths) {
      for (const f of copy.formFieldNames(p)) wantForms.set(`${p}/${f}`, copy.formField(p, f));
    }
    const gotForms = new Map();
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
      const key = (v) =>
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

          static _headingTitle(line) {
    const div = SpecDocumentMarkdown.headingDiv(line);
    let rest;
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

          static _withAppendix(
    markdown,
    entries,
    titles,
    references,
  ) {
    const sectionOf = (ref) => {
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
    let section = null;
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

function _cmp(a, b) {
  return a < b ? -1 : a > b ? 1 : 0;
}

function _findingText(f) {
  return `${f.code} (line ${f.line}): ${f.message}`;
}

// ---------------------------------------------------------------------------
// One value's strip.

const _KEEP = 0;
const _DEL = 1;
const _INS = 2;

function _space(c) {
  return c === ' ' || c === '\t';
}

/** The strip of one value, planned once and finished for any numbering. */
class _Plan {
           o;
           options;
  t;
  script1 = null;
  del;
  blockDel = [];
  ins = new Map();
  dropped = new Map();
  unmarked = new Map();
  appended = new Map();
  marksDropped = 0;
  entries = [];
  findings;

  constructor(o, options) {
    this.o = o;
    this.options = options;
    this.findings = scanNotation(o, { tomSpecs: true }).findings.filter(
      (f) => f.severity === 'error' && f.code !== NotationFindingCode.REJECTED_BLOCK,
    );
    if (this.findings.length > 0) {
      this.t = o;
      this.del = new Array(o.length).fill(null);
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
    this.del = new Array(this.t.length).fill(null);
    this.blockDel = new Array(this.t.length).fill(false);
    this._process(scanNotation(this.t, { tomSpecs: true }).elements);
    if (!options.drop.has('comments')) this._marks();
    if (this.del.some((d) => d !== null)) this._normalise();
  }

  get changes() {
    return (
      this.findings.length === 0 &&
      (this.script1 !== null || this.del.some((d) => d !== null) || this.ins.size > 0)
    );
  }

          _mark(s, e, label, block = false) {
    for (let i = s; i < e && i < this.t.length; i++) {
      if (this.del[i] === null) this.del[i] = label;
      if (block) this.blockDel[i] = true;
    }
  }

          _insert(at, i) {
    const list = this.ins.get(at);
    if (list === undefined) this.ins.set(at, [i]);
    else list.push(i);
  }

          static _count(m, k) {
    m.set(k, (m.get(k) ?? 0) + 1);
  }

          _process(list) {
    const t = this.t;
    for (const e of list) {
      const k = e.kind;
      // A `linked` span (SOM §11.11) or a `derived` block (SOM §11.12) is
      // removed by `-drop:` and `-unmark:` alike: its text without its
      // markers would read back as content.
      if (
        e.isRegistered &&
        (k === 'linked' || k === 'derived') &&
        (this.options.drop.has(k) || this.options.unmark.has(k))
      ) {
        this._remove(e, `${k}:drop`, null);
        _Plan._count(this.dropped, k);
        continue;
      }
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

          _remove(e, label, entry) {
    const t = this.t;
    const reference = entry !== null && this.options.appendixReferences;
    if (e.type === 'div') {
      this._mark(e.start, e.end, label, true);
      if (reference) this._insert(e.start, { label, entry: entry });
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
    if (reference) this._insert(e.start, { label, entry: entry });
  }

          _unmark(e, label) {
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

          _marks() {
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

          _removeMark(m) {
    const t = this.t;
    const s = m.start;
    if (s > 0 && _space(t[s - 1]) && this.del[s - 1] === null) {
      this.del[s - 1] = 'mark';
    } else if ((s === 0 || t[s - 1] === '\n') && m.end < t.length && _space(t[m.end])) {
      this.del[m.end] = 'mark';
    }
    this._mark(m.start, m.end, 'mark');
  }

          _convert(m, delimiter, s, e) {
    this._mark(m.start + 1, m.start + 3, 'mark');
    this._insert(m.start + 3, { label: 'mark', text: delimiter });
    this._mark(s, e, 'mark');
    this._mark(m.end - 3, m.end - 1, 'mark');
    this._insert(m.end - 1, { label: 'mark', text: delimiter });
  }

          _allDeleted(s, e) {
    for (let i = s; i < e; i++) if (this.del[i] === null) return false;
    return true;
  }

          _hadText(s, e) {
    return this.t.substring(s, e).trim() !== '';
  }

          _survives(s, e) {
    for (let i = s; i < e; i++) {
      if (this.del[i] === null && this.t[i].trim() !== '') return true;
    }
    return false;
  }

          _normalise() {
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
    const kept = [];
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
    const solid = (c) => c.trim() !== '';
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
      const breaks = [];
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

  finish(number) {
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
    const insertText = (x) => {
      if (x.text !== undefined) return x.text;
      const n = number(x.entry);
      return `<a id="note-${n}-ref"></a>[\\[${n}\\]](#note-${n})`;
    };
    const script2 = [];
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
    const pieces = [];
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
      const labels = new Set();
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
function _compose(s1, s2) {
  const out = [];
  let j = 0;
  const flushInserts = () => {
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
function _diff(a, b, label) {
  const out = [];
  const chars = (type, s) => {
    for (let k = 0; k < s.length; k++) {
      out.push({ type, char: s[k], label: type === _KEEP ? null : label });
    }
  };
  let deleted = '';
  let inserted = '';
  const flush = () => {
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

function _lines(s) {
  const out = [];
  let i = 0;
  while (i < s.length) {
    const n = s.indexOf('\n', i);
    const e = n < 0 ? s.length : n + 1;
    out.push(s.substring(i, e));
    i = e;
  }
  return out;
}

function _tokenKind(c) {
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

function _tokens(s) {
  const out = [];
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

function _myers(a, b) {
  const n = a.length;
  const m = b.length;
  const max = n + m;
  if (max === 0) return [];
  const cap = 2000;
  const off = max + 1;
  const v = new Int32Array(2 * max + 3);
  const trace = [];
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
      ...a.map((t) => [_DEL, t]),
      ...b.map((t) => [_INS, t]),
    ];
  }
  const rev = [];
  let x = n;
  let y = m;
  for (let d = found; d > 0; d--) {
    const snap = trace[d - 1];
    const at = (k) => snap[k + d - 1];
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

const _MARK_CLOSE = {
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
  '{==': '==}',
  '{>>': '<<}',
};

function _findMarks(t) {
  const code = new Array(t.length).fill(false);
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
  const out = [];
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

/**
 * The strip's internals the merge back (`spec_document_merge.ts`, SOM
 * §11.10) works with; not part of the package's public surface.
 * @internal
 */
const _stripInternals = {
  KEEP: _KEEP,
  DEL: _DEL,
  INS: _INS,
  diff: _diff,
  lines: _lines,
  myers: _myers,
  findMarks: _findMarks,
  valueRefs: (doc) => SpecDocumentStrip['_valueRefs'](doc),
  tierFindings: (
    model,
    schema,
    rootType,
    doc,
  ) => SpecDocumentStrip['_tierFindings'](model, schema, rootType, doc),
};

module.exports = {
  specStripKindNames,
  specStripNotationKinds,
  SpecStripUsageError,
  SpecStripOptions,
  SpecReadableSource,
  SpecReadableHeader,
  SpecStripPiece,
  SpecAppendixEntry,
  SpecStripTextResult,
  stripNotationText,
  SpecStripValueRef,
  SpecStrippedValue,
  SpecStripKept,
  SpecStripFinding,
  SpecStripResult,
  SpecDocumentStrip,
  _stripInternals,
};
