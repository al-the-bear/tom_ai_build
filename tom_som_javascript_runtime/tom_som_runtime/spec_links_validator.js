'use strict';

/**
 * The link checks of one document (`tom_specs_model_rules.md` §9.7):
 * {@link validateLinks} holds a document's values to the link annotations of
 * the model — derived values to their sources, summaries to their detail
 * lists, each end of a link to the other, the ids named in a text to the link
 * rows, and a `@SameAs` copy to its holder. A port of
 * `tom_som_dart_runtime/lib/src/spec_links_validator.dart`.
 *
 * Values are read in their reviewed state: a value holding pending change
 * marks is read with every mark rejected, and listed as
 * `linkValuePending`. A `@SummaryOf` naming another document is skipped here;
 * the document set checks it.
 */

const { SpecFieldKind } = require('./spec_model');
const {
  SpecPlace,
  SpecPlaceException,
  SpecPlaceFilter,
  SpecPlaceKind,
  SpecPlaceResolution,
  specSameAsBindings,
} = require('./spec_place');
const { SpecNodeKind, SpecReflection } = require('./spec_reflection');
const { K_SPEC_HEADLINE_FIELD, applyInlineMarksText } = require('./spec_review_annotations');
const { K_SECTION_ID_SLOT, effectiveListItemSectionId } = require('./spec_section_id');
const { SpecValidationCode, SpecValidationError, specValidationCodeIndex } = require('./spec_validator');

/**
 * Runs the link checks of `doc` against `model`; the findings sorted by path,
 * then by code (declaration order), then by message.
 */
function validateLinks(model, doc) {
  const v = new SpecLinkValidator(model, doc);
  v.run();
  return v.errors.slice().sort((a, b) => {
    const p = _compare(a.path, b.path);
    if (p !== 0) {
      return p;
    }
    const c = specValidationCodeIndex(a.code) - specValidationCodeIndex(b.code);
    return c !== 0 ? c : _compare(a.message, b.message);
  });
}

/**
 * Every concrete path of `pattern` in `doc`: each `<list>-*` segment expanded
 * over the document's items.
 */
function specExpandPattern(doc, pattern) {
  let paths = [''];
  for (const seg of pattern.split('/')) {
    const next = [];
    for (const p of paths) {
      const base = p === '' ? seg : `${p}/${seg}`;
      if (seg.endsWith('-*')) {
        next.push(...doc.listItems(base.substring(0, base.length - 2)));
      } else {
        next.push(base);
      }
    }
    paths = next;
  }
  return paths;
}

/** `place` resolved under `anchor`, or `null` when it does not resolve. */
function specResolvePlaceAt(refl, place, anchor) {
  try {
    return SpecPlace.parse(place).resolve(refl, anchor);
  } catch (e) {
    if (e instanceof SpecPlaceException) {
      return null;
    }
    throw e;
  }
}

/**
 * `place` resolved for a link annotated at `anchor`, as the link checks and
 * the rendition's `linked` marker (SOM §11.11) read it: a `./` place beneath
 * the nearest list element of `anchor`; any other place inside `anchor`'s
 * subtree when it is there, else anywhere beneath the document root `root` —
 * a bare id wherever it is reached once, a `/` path from the section its
 * first segment names, through the first item `doc` holds of a list there
 * (no `doc`: such a path does not resolve).
 */
function specResolveLinkPlace(refl, doc, place, root, anchor) {
  if (place.startsWith('./')) {
    return specResolvePlaceAt(refl, place, anchor);
  }
  // The grammar's own scope first: the subtree of the annotated section.
  const local = anchor === root ? null : specResolvePlaceAt(refl, place, anchor);
  if (local !== null) {
    return local;
  }
  const slash = place.indexOf('/');
  if (slash < 0) {
    return specResolvePlaceAt(refl, place, root);
  }
  const head = specResolvePlaceAt(refl, place.substring(0, slash), root);
  if (head === null) {
    return null;
  }
  const scope = head.kind === SpecPlaceKind.LIST ? `${head.path}-*` : head.path;
  // A pattern anchor resolves through its first concrete instance; the rest
  // of the place is relative, so the pattern is rebuilt below.
  const concrete =
    doc === null
      ? scope.includes('-*')
        ? []
        : [scope]
      : specExpandPattern(doc, scope);
  if (concrete.length === 0) {
    return null;
  }
  const rest = specResolvePlaceAt(refl, place.substring(slash + 1), concrete[0]);
  if (rest === null) {
    return null;
  }
  return new SpecPlaceResolution({
    place: rest.place,
    kind: rest.kind,
    path: scope + rest.path.substring(concrete[0].length),
    className: rest.className,
    sectionIds: rest.sectionIds,
    formField: rest.formField,
  });
}

/**
 * What `deriveFields` would write for one link finding (internal to the
 * runtime; collected by {@link SpecLinkValidator} beside the finding).
 *
 * Kinds: `set` (the value at `path` / `field`, `null` field: content),
 * `append` (add `value` to the ids of the reference field), `addRow` (add a
 * row to the list at `path`: `<member>#<field>` → value), `removeRow` (the
 * row at `path`; `empty`: it holds no value already), `list` (make the list
 * at `path` hold one element per tuple), `copy` (write the copy at `path`
 * from `holder`).
 */
class SpecLinkFix {
  constructor(props) {
    this.step = props.step;
    this.kind = props.kind;
    this.path = props.path;
    this.field = props.field != null ? props.field : null;
    this.value = props.value != null ? props.value : null;
    this.values = props.values != null ? props.values : null;
    this.tuples = props.tuples != null ? props.tuples : null;
    this.holder = props.holder != null ? props.holder : null;
    this.empty = props.empty === true;
  }

  /** Set the value at `path` / `field` to `value`. */
  static set(step, path, field, value) {
    return new SpecLinkFix({ step, kind: 'set', path, field, value });
  }

  /** Add `value` to the ids of the reference field at `path` / `field`. */
  static append(path, field, value) {
    return new SpecLinkFix({ step: 1, kind: 'append', path, field, value });
  }

  /**
   * Add a row to the list at `path`: `<member>#<field>` (or `<member>`, a
   * content value) → value.
   */
  static addRow(step, path, values) {
    return new SpecLinkFix({ step, kind: 'addRow', path, values });
  }

  /** Remove the row at `path`; `empty`: it holds no value already. */
  static removeRow(path, empty = false) {
    return new SpecLinkFix({ step: 1, kind: 'removeRow', path, empty });
  }

  /** Make the list at `path` hold one element per tuple (target place → value). */
  static list(path, tuples) {
    return new SpecLinkFix({ step: 2, kind: 'list', path, tuples });
  }

  /** Write the copy at `path` from the `holder`. */
  static copy(path, holder) {
    return new SpecLinkFix({ step: 2, kind: 'copy', path, holder });
  }
}

function _compare(a, b) {
  return a < b ? -1 : a > b ? 1 : 0;
}

function _sortedStrings(values) {
  return Array.from(values).sort(_compare);
}

/** Dart's `num.tryParse` (decimal forms; surrounding whitespace allowed). */
function _numTryParse(text) {
  const t = text.trim();
  if (/^[+-]?\d+$/.test(t)) {
    return parseInt(t, 10);
  }
  if (/^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/.test(t)) {
    return parseFloat(t);
  }
  if (/^0[xX][0-9a-fA-F]+$/.test(t)) {
    return parseInt(t, 16);
  }
  if (t === 'NaN') {
    return NaN;
  }
  if (t === 'Infinity' || t === '-Infinity') {
    return t === 'Infinity' ? Infinity : -Infinity;
  }
  return null;
}

/**
 * The link checker of one document (internal to the runtime: `validateLinks`
 * runs it, `deriveFields` reads its {@link fixes} and value readers).
 */
class SpecLinkValidator {
  constructor(model, doc, options = {}) {
    /** What `deriveFields` would write for each finding, collected beside it. */
    this.fixes = [];
    this.errors = [];
    this._reported = new Set();
    this._pending = new Set();

    /**
     * Derived values computed so far (`path#field` → value), read before the
     * stored value so a derivation from a derived place sees its derived value.
     */
    this._derived = new Map();

    /** The effective section id per list item path (writable by `deriveFields`). */
    this.itemIds = new Map();
    this._items = new Map();
    this._formsByOwner = null;
    this._entriesCache = new Map();
    this._valued = null;
    this.model = model;
    this.doc = doc;
    this.refl = new SpecReflection(model);
    /**
     * Read values with their pending marks accepted (the proposal), as
     * `deriveFields` does in a document under review, instead of the reviewed
     * state; no value is then listed as pending.
     */
    this.readProposed = options.readProposed === true;
  }

  report(code, path, message) {
    const key = `${code} ${path} ${message}`;
    if (!this._reported.has(key)) {
      this._reported.add(key);
      this.errors.push(new SpecValidationError(path, code, message));
    }
  }

  // -------------------------------------------------------------------------
  // The document's instances
  // -------------------------------------------------------------------------

  run() {
    const instances = [];
    for (const root of this.model.roots) {
      const seg = this.refl.rootSegment(root);
      if (!this._populated(seg)) {
        continue;
      }
      const cls = this.refl.classNamed(root.type);
      if (cls === null) {
        continue;
      }
      this._walk(cls, seg, seg, instances, new Set());
    }
    this._checkDerivations(instances);
    for (const i of instances) {
      for (const f of i.cls.fields) {
        this._checkSummary(i, f);
        this._checkExtracts(i, f);
        for (const ff of f.formFields) {
          const form = this._formPath(i, f);
          if (ff.inverseOf !== null) {
            this._checkInverse(form, ff);
          }
          if (ff.summaryOf !== null) {
            this._checkFieldSummary(i, form, ff);
          }
        }
      }
    }
    for (const root of this.model.roots) {
      const seg = this.refl.rootSegment(root);
      if (this._populated(seg)) {
        this._checkSameAs(root.type);
      }
    }
    return this;
  }

  _populated(seg) {
    const under = (paths) => {
      for (const p of paths) {
        if (p === seg || p.startsWith(`${seg}/`)) {
          return true;
        }
      }
      return false;
    };
    return (
      under(this.doc.contentPaths) ||
      under(this.doc.formPaths) ||
      under(this.doc.listPaths) ||
      under(this.doc.headlinePaths)
    );
  }

  _walk(cls, path, root, out, onPath) {
    out.push({ path, cls, root });
    for (const f of cls.fields) {
      const memberPath = `${path}/${this.refl.fieldSegment(f)}`;
      if (f.hasAnnotation('Reference')) {
        continue;
      }
      if (f.kind === SpecFieldKind.LIST && f.elementIsComplex) {
        const el = this.refl.classNamed(f.elementType);
        if (el === null) {
          continue;
        }
        for (const item of this.doc.listItems(memberPath)) {
          this._walk(el, item, root, out, new Set());
        }
      } else if (f.kind === SpecFieldKind.COMPLEX || f.kind === SpecFieldKind.SECTION) {
        const child = this.refl.classNamed(f.type !== null ? f.type.split('?').join('') : null);
        if (child === null || onPath.has(child.name)) {
          continue;
        }
        this._walk(child, memberPath, root, out, new Set([...onPath, cls.name]));
      }
    }
  }

  _formPath(i, f) {
    return `${i.path}/${this.refl.fieldSegment(f)}`;
  }

  // -------------------------------------------------------------------------
  // Reading values
  // -------------------------------------------------------------------------

  /** The reviewed reading of a raw value; a value with pending marks is listed once. */
  _reviewed(raw, path, what) {
    if (raw === null) {
      return '';
    }
    if (this.readProposed) {
      return applyInlineMarksText(raw, { accept: true }).trim();
    }
    const rejected = applyInlineMarksText(raw, { accept: false });
    const key = `${path} ${what}`;
    if (applyInlineMarksText(raw, { accept: true }) !== rejected && !this._pending.has(key)) {
      this._pending.add(key);
      this.report(
        SpecValidationCode.LINK_VALUE_PENDING,
        path,
        `${what} holds pending change marks; it is read with every mark ` + 'rejected',
      );
    }
    return rejected.trim();
  }

  /** The value of form field `field` at `path` (derived first, then reviewed). */
  formValue(path, field) {
    const derived = this._derived.get(`${path}#${field}`);
    if (derived !== undefined) {
      return derived;
    }
    return this._reviewed(this.doc.formField(path, field), path, `form field "${field}"`);
  }

  /** The content value at `path` (derived first, then reviewed). */
  contentValue(path) {
    const derived = this._derived.get(`${path}#`);
    if (derived !== undefined) {
      return derived;
    }
    return this._reviewed(this.doc.content(path), path, 'the content');
  }

  /** The headline at `path`, reviewed. */
  headlineValue(path) {
    return this._reviewed(this.doc.headline(path), path, 'the headline');
  }

  /** The effective section id of the list item at `itemPath`. */
  itemId(itemPath) {
    let id = this.itemIds.get(itemPath);
    if (id === undefined) {
      id = this._computeItemId(itemPath);
      this.itemIds.set(itemPath, id);
    }
    return id;
  }

  _computeItemId(itemPath) {
    const stored = this.doc.itemSectionId(itemPath);
    if (stored !== null) {
      return stored;
    }
    const dash = itemPath.lastIndexOf('-');
    const list = itemPath.substring(0, dash);
    const items = this.doc.listItems(list);
    const res = this.refl.resolve(list);
    const field = res !== null ? res.field : null;
    const segs = list.split('/');
    return effectiveListItemSectionId(
      null,
      field !== null ? field.sectionIdPattern : null,
      items.indexOf(itemPath) + 1,
      field !== null ? field.name : segs[segs.length - 1],
    );
  }

  /** Whether `path` is a complex list item. */
  isItem(path) {
    let hit = this._items.get(path);
    if (hit === undefined) {
      const r = this.refl.resolve(path);
      hit = r !== null && r.kind === SpecNodeKind.LIST_ITEM_COMPLEX;
      this._items.set(path, hit);
    }
    return hit;
  }

  /** The value a resolved place holds at its concrete `path`. */
  value(r, path) {
    switch (r.kind) {
      case SpecPlaceKind.FORM_FIELD:
        return this.formValue(path, r.field);
      case SpecPlaceKind.CONTENT:
        return this.contentValue(path);
      case SpecPlaceKind.HEADLINE:
        return this.headlineValue(path);
      case SpecPlaceKind.SECTION_ID:
        return this.isItem(path) ? this.itemId(path) : '';
      default:
        return '';
    }
  }

  /** Every concrete path of a resolved pattern. */
  expand(pattern) {
    return specExpandPattern(this.doc, pattern);
  }

  /** `place` resolved under `anchor`, or `null` when it does not resolve. */
  at(place, anchor) {
    return specResolvePlaceAt(this.refl, place, anchor);
  }

  /** `place` resolved for a link annotated at `anchor` ({@link specResolveLinkPlace}). */
  _global(place, root, anchor) {
    return specResolveLinkPlace(this.refl, this.doc, place, root, anchor);
  }

  /** The values a row's own forms (`<row>/<member>`) hold in `field`. */
  ownValues(row, field) {
    if (this._formsByOwner === null) {
      const out = new Map();
      for (const p of this.doc.formPaths) {
        const slash = p.lastIndexOf('/');
        if (slash > 0) {
          const owner = p.substring(0, slash);
          let list = out.get(owner);
          if (list === undefined) {
            list = [];
            out.set(owner, list);
          }
          list.push(p);
        }
      }
      this._formsByOwner = out;
    }
    const out = [];
    for (const p of this._formsByOwner.get(row) || []) {
      if (this.doc.formField(p, field) !== null) {
        out.push(this.formValue(p, field));
      }
    }
    return out;
  }

  _passes(where, row) {
    if (where === null) {
      return true;
    }
    const filter = SpecPlaceFilter.tryParse(where);
    if (filter === null || filter.field === null) {
      return true;
    }
    return filter.matches(this.ownValues(row, filter.field));
  }

  /** The nearest list item at or above `path` (itself included). */
  nearestItem(path) {
    let p = path;
    for (;;) {
      if (this.isItem(p)) {
        return p;
      }
      const slash = p.lastIndexOf('/');
      if (slash < 0) {
        return null;
      }
      p = p.substring(0, slash);
    }
  }

  /** The comma-separated ids of `value`, trimmed, empty ones dropped. */
  static ids(value) {
    const out = [];
    for (const s of value.split(',')) {
      if (s.trim() !== '') {
        out.push(s.trim());
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // @DerivedFrom and derivedFrom:
  // -------------------------------------------------------------------------

  _checkDerivations(instances) {
    const scalar = [];
    for (const i of instances) {
      for (const f of i.cls.fields) {
        const d = f.derivedFrom;
        const memberPath = this._formPath(i, f);
        if (d !== null) {
          if (f.kind === SpecFieldKind.LIST) {
            this._checkDerivedList(i, memberPath, d);
          } else if (f.kind === SpecFieldKind.CONTENT) {
            scalar.push({ path: memberPath, field: null, d, anchor: i.path, root: i.root, spec: null });
          }
        }
        for (const ff of f.formFields) {
          const q = ff.derivedFrom;
          if (q === null) {
            continue;
          }
          scalar.push({ path: memberPath, field: ff.name, d: q, anchor: i.path, root: i.root, spec: ff });
        }
      }
    }
    // Dependency order: every derivation is recomputed from the values the
    // ones before it gave, until nothing moves. DERIVE-ACYCLIC bounds the
    // rounds by the number of derivations.
    const expected = new Map();
    for (let round = 0; round <= scalar.length; round++) {
      let moved = false;
      for (let k = 0; k < scalar.length; k++) {
        const t = scalar[k];
        const value = this._derive(t.d, t.anchor, t.root, t.spec, t.path);
        // Dart's `expected[k] != value`: an absent key reads as null.
        const had = expected.has(k) ? expected.get(k) : null;
        if (had !== value) {
          expected.set(k, value);
          moved = true;
          if (value !== null) {
            this._derived.set(`${t.path}#${t.field !== null ? t.field : ''}`, value);
          }
        }
      }
      if (!moved) {
        break;
      }
    }
    this._derived.clear();
    for (let k = 0; k < scalar.length; k++) {
      const t = scalar[k];
      const want = expected.has(k) ? expected.get(k) : null;
      if (want === null) {
        continue;
      }
      const have = t.field === null ? this.contentValue(t.path) : this.formValue(t.path, t.field);
      if (!SpecLinkValidator._sameValue(have, want, t.spec)) {
        this.fixes.push(SpecLinkFix.set(2, t.path, t.field, want));
      }
      if (have === '') {
        continue; // not derived yet: deriveFields writes it
      }
      if (!SpecLinkValidator._sameValue(have, want, t.spec)) {
        this.report(
          SpecValidationCode.DERIVED_VALUE_MISMATCH,
          t.path,
          `${t.field === null ? 'the content' : `form field "${t.field}"`} is ` +
            `derived (${t.d.kind} of ${t.d.source}) as "${want}", but holds ` +
            `"${have}"`,
        );
      }
    }
  }

  static _sameValue(a, b, spec) {
    if (spec !== null && spec.multiple && spec.refersTo.length > 0) {
      const x = new Set(SpecLinkValidator.ids(a));
      const y = new Set(SpecLinkValidator.ids(b));
      for (const v of x) {
        if (!y.has(v)) {
          return false;
        }
      }
      for (const v of y) {
        if (!x.has(v)) {
          return false;
        }
      }
      return true;
    }
    const t = spec !== null ? spec.type : null;
    if (t === 'int' || t === 'double' || t === 'num') {
      const x = _numTryParse(a);
      const y = _numTryParse(b);
      if (x !== null && y !== null) {
        return x === y;
      }
    }
    const norm = (s) =>
      s
        .split('\n')
        .map((l) => l.replace(/\s+$/, ''))
        .join('\n')
        .trim();
    return norm(a) === norm(b);
  }

  /**
   * The rows a `rows` / `lookup` derivation reads, in document order; `null`
   * when the document's root does not reach the source (undecidable here).
   */
  _rows(d, anchor, root) {
    const src = this._global(d.source, root, anchor);
    if (src === null) {
      return null;
    }
    const keyBy = d.key !== null && d.by !== null;
    const byValue = keyBy ? this.placeValue(d.by, anchor) : null;
    return this.expand(src.path).filter(
      (row) => this._passes(d.where, row) && (!keyBy || this.placeValue(d.key, row) === byValue),
    );
  }

  /** The value of `place` resolved under the concrete `anchor`. */
  placeValue(place, anchor) {
    const r = this.at(place, anchor);
    if (r === null) {
      return '';
    }
    const paths = this.expand(r.path);
    return paths.length === 1 ? this.value(r, paths[0]) : '';
  }

  /** The value a scalar derivation gives, or `null` when undecidable. */
  _derive(d, anchor, root, spec, targetPath) {
    switch (d.kind) {
      case 'copy': {
        const src = this._global(d.source, root, anchor);
        if (src === null) {
          return null;
        }
        const paths = this.expand(src.path);
        return paths.length === 1 ? this.value(src, paths[0]) : null;
      }
      case 'rows': {
        const rows = this._rows(d, anchor, root);
        if (rows === null) {
          return null;
        }
        if (spec !== null && spec.multiple) {
          const out = [];
          for (const row of rows) {
            for (const t of d.take) {
              out.push(...SpecLinkValidator.ids(this.placeValue(t, row)));
            }
          }
          return out.join(', ');
        }
        return rows
          .map((row) =>
            d.take
              .map((t) => this.placeValue(t, row))
              .filter((s) => s !== '')
              .join(' — '),
          )
          .filter((s) => s !== '')
          .join('\n');
      }
      case 'lookup': {
        const rows = this._rows(d, anchor, root);
        if (rows === null) {
          return null;
        }
        const keyBy = d.key !== null && d.by !== null;
        if (keyBy && rows.length !== 1) {
          this.report(
            SpecValidationCode.DERIVED_LOOKUP_MISS,
            targetPath,
            `the lookup in ${d.source} by ${d.key} = ` +
              `"${this.placeValue(d.by, anchor)}" finds ${rows.length} rows, not ` +
              'one',
          );
          return null;
        }
        if (rows.length === 0) {
          return '';
        }
        const row = rows[rows.length - 1];
        return d.take
          .map((t) => this.placeValue(t, row))
          .filter((s) => s !== '')
          .join(' — ');
      }
    }
    return null;
  }

  /** A `@DerivedFrom.rows` with `map` on a list: one element per row. */
  _checkDerivedList(i, listPath, d) {
    const mapEntries = Object.entries(d.map);
    if (d.kind !== 'rows' || mapEntries.length === 0) {
      return;
    }
    const elements = this.doc.listItems(listPath);
    const rows = this._rows(d, i.path, i.root);
    if (rows === null) {
      return; // the source is not in this document
    }
    const wanted = rows.map((row) => {
      const t = {};
      for (const [k, v] of mapEntries) {
        t[k] = this.placeValue(v, row);
      }
      return t;
    });
    const current = elements.map((el) => {
      const t = {};
      for (const [k] of mapEntries) {
        t[k] = this.placeValue(k, el);
      }
      return t;
    });
    const key = (t) =>
      mapEntries.map(([k]) => (t[k] !== undefined ? t[k] : 'null')).join(' | ');
    if (
      _sortedStrings(wanted.map(key)).join('\n') !== _sortedStrings(current.map(key)).join('\n')
    ) {
      this.fixes.push(SpecLinkFix.list(listPath, wanted));
    }
    if (elements.length === 0) {
      return; // not derived yet
    }
    const want = _sortedStrings(
      rows.map((row) => mapEntries.map(([, v]) => this.placeValue(v, row)).join(' | ')),
    );
    const have = _sortedStrings(
      elements.map((el) => mapEntries.map(([k]) => this.placeValue(k, el)).join(' | ')),
    );
    if (want.join('\n') !== have.join('\n')) {
      this.report(
        SpecValidationCode.DERIVED_VALUE_MISMATCH,
        listPath,
        `the list is derived (rows of ${d.source}) as [${want.join('; ')}], ` +
          `but holds [${have.join('; ')}]`,
      );
    }
  }

  // -------------------------------------------------------------------------
  // @SummaryOf and summaryOf:
  // -------------------------------------------------------------------------

  /** The detail elements of a summary: item path → id. */
  _detailElements(s, root) {
    const r = this._global(s.detail, root, root);
    if (r === null || r.kind !== SpecPlaceKind.LIST) {
      return null;
    }
    const out = new Map();
    for (const list of this.expand(r.path)) {
      for (const item of this.doc.listItems(list)) {
        out.set(item, this.itemId(item));
      }
    }
    return out;
  }

  _checkSummary(i, f) {
    const s = f.summaryOf;
    if (s === null || s.document !== null || f.kind !== SpecFieldKind.LIST) {
      return;
    }
    const detail = this._detailElements(s, i.root);
    if (detail === null) {
      return;
    }
    const byId = new Map();
    for (const [item, id] of detail) {
      byId.set(id, item);
    }
    const named = new Map();
    for (const el of this.doc.listItems(this._formPath(i, f))) {
      const ids =
        s.match === null ? [this.itemId(el)] : SpecLinkValidator.ids(this.placeValue(s.match, el));
      for (const id of ids) {
        const target = byId.get(id);
        if (target === undefined) {
          this.report(
            SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
            el,
            `the summary row names ${id}, which is no element of ${s.detail}`,
          );
          continue;
        }
        if (named.has(id)) {
          this.report(
            SpecValidationCode.SUMMARY_DUPLICATE,
            el,
            `the summary row names ${id}, which ${named.get(id)} names already`,
          );
          continue;
        }
        named.set(id, el);
        this._checkRepeats(s, el, target);
      }
    }
    if (s.relation === 'equal') {
      for (const [item, id] of detail) {
        if (!named.has(id)) {
          this.report(
            SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
            item,
            `the detail element ${id} is named by no row of the summary ` +
              `${this._formPath(i, f)} (relation: equal)`,
          );
        }
      }
    }
  }

  /** The values a summary row repeats agree with its detail element's. */
  _checkRepeats(s, row, detail) {
    for (const [mineAt, theirsAt] of Object.entries(s.repeats)) {
      const mine = this.at(mineAt, row);
      const theirs = this.at(theirsAt, detail);
      if (mine === null || theirs === null) {
        continue;
      }
      const mp = this.expand(mine.path);
      const tp = this.expand(theirs.path);
      if (mp.length !== 1 || tp.length !== 1) {
        continue;
      }
      const have = this.value(mine, mp[0]);
      const want = this.value(theirs, tp[0]);
      if (have !== want) {
        this.fixes.push(SpecLinkFix.set(2, mp[0], SpecLinkValidator.fieldOf(mine), want));
      }
      if (have === '') {
        continue; // not repeated yet: deriveFields writes it
      }
      if (have !== want) {
        this.report(
          SpecValidationCode.DERIVED_VALUE_MISMATCH,
          mp[0],
          `${mineAt} repeats ${theirsAt} of ${detail} as "${have}", but the detail ` +
            `element holds "${want}"`,
        );
      }
    }
  }

  _checkFieldSummary(i, form, ff) {
    const s = ff.summaryOf;
    if (s.document !== null) {
      return;
    }
    const raw = this.doc.formField(form, ff.name);
    if (raw === null) {
      return;
    }
    const detail = this._detailElements(s, i.root);
    if (detail === null) {
      return;
    }
    const known = new Set(detail.values());
    const seen = new Set();
    for (const id of SpecLinkValidator.ids(this.formValue(form, ff.name))) {
      if (!known.has(id)) {
        this.report(
          SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
          form,
          `form field "${ff.name}" names ${id}, which is no element of ` + `${s.detail}`,
        );
      } else if (seen.has(id)) {
        this.report(
          SpecValidationCode.SUMMARY_DUPLICATE,
          form,
          `form field "${ff.name}" names ${id} twice`,
        );
      } else {
        seen.add(id);
      }
    }
    if (s.relation === 'equal') {
      for (const [item, id] of detail) {
        if (!seen.has(id)) {
          this.report(
            SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
            item,
            `the detail element ${id} is not named in "${ff.name}" of ` +
              `${form} (relation: equal)`,
          );
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // inverseOf:
  // -------------------------------------------------------------------------

  /**
   * The entries a reference field names, by its `refersTo` registries: id →
   * item path. An entry of `<X>.@sectionId` is named by its section id, one of
   * `<X>.<field>` by the value its own forms hold in that field.
   */
  entries(refersTo) {
    const key = refersTo.join(',');
    let hit = this._entriesCache.get(key);
    if (hit === undefined) {
      hit = this._computeEntries(refersTo);
      this._entriesCache.set(key, hit);
    }
    return hit;
  }

  _computeEntries(refersTo) {
    const out = new Map();
    for (const list of _sortedStrings(this.doc.listPaths)) {
      for (const item of this.doc.listItems(list)) {
        const r = this.refl.resolve(item);
        const id = r !== null && r.targetClass !== null ? r.targetClass.sectionId : null;
        if (id === null || id === undefined) {
          continue;
        }
        for (const t of refersTo) {
          if (t.split('.')[0] !== id) {
            continue;
          }
          const name = this.identity(item, t);
          if (name !== null && name !== '' && !out.has(name)) {
            out.set(name, item);
          }
        }
      }
    }
    return out;
  }

  /**
   * How the registry key `target` (`<X>.@sectionId` or `<X>.<field>`) names
   * the entry at `item`.
   */
  identity(item, target) {
    const field = target.substring(target.indexOf('.') + 1);
    if (field === K_SECTION_ID_SLOT) {
      return this.itemId(item);
    }
    const values = this.ownValues(item, field);
    return values.length === 0 ? null : values[0];
  }

  /** The nearest item at or above `path` whose class is one of `classes`. */
  _owner(path, classes) {
    let p = this.nearestItem(path);
    while (p !== null) {
      const r = this.refl.resolve(p);
      const id = r !== null && r.targetClass !== null ? r.targetClass.sectionId : null;
      if (id !== null && id !== undefined && classes.has(id)) {
        return p;
      }
      const slash = p.lastIndexOf('/');
      if (slash < 0) {
        return null;
      }
      p = this.nearestItem(p.substring(0, slash));
    }
    return null;
  }

  static _registryClasses(refersTo) {
    return new Set(refersTo.map((t) => t.split('.')[0]));
  }

  _firstIdentity(owner, refersTo) {
    for (const t of refersTo) {
      const id = this.identity(owner, t);
      if (id !== null) {
        return id;
      }
    }
    return null;
  }

  _checkInverse(form, ff) {
    const raw = this.doc.formField(form, ff.name);
    if (raw === null) {
      return;
    }
    const value = this.formValue(form, ff.name);
    if (value === '') {
      return;
    }
    const inv = ff.inverseOf;
    const entries = this.entries(ff.refersTo);
    if (inv.symmetric) {
      this._checkSymmetric(form, ff, inv, value, entries);
      return;
    }
    // The entry this field belongs to, as the other ends name it.
    for (const b of SpecLinkValidator.ids(value)) {
      const bPath = entries.get(b);
      if (bPath === undefined) {
        continue; // a registry this document does not hold
      }
      let resolved = false;
      let namesBack = false;
      let aId = null;
      let writable = null;
      for (const end of inv.fields) {
        const r = this.at(end, bPath);
        if (r === null || r.formField === null) {
          continue;
        }
        const owner = this._owner(form, SpecLinkValidator._registryClasses(r.formField.refersTo));
        if (owner === null) {
          continue;
        }
        if (inv.where !== null && !this._passes(inv.where, owner)) {
          return;
        }
        aId = this._firstIdentity(owner, r.formField.refersTo);
        if (aId === null) {
          continue;
        }
        resolved = true;
        const ends = this.expand(r.path);
        if (ends.length > 0 && writable === null) {
          writable = [ends[0], r.field];
        }
        for (const p of ends) {
          if (SpecLinkValidator.ids(this.formValue(p, r.field)).includes(aId)) {
            namesBack = true;
          }
        }
      }
      if (resolved && !namesBack && writable !== null) {
        this.fixes.push(SpecLinkFix.append(writable[0], writable[1], aId));
      }
      if (resolved && !namesBack) {
        this.report(
          SpecValidationCode.INVERSE_MISSING,
          form,
          `form field "${ff.name}" names ${b}, but ${b} does not name ${aId} back ` +
            `(${inv.fields.join(', ')})`,
        );
      }
    }
  }

  _checkSymmetric(form, ff, inv, value, entries) {
    const row = this.nearestItem(form);
    if (row === null || !this._passes(inv.where, row)) {
      return;
    }
    const a = this._owner(
      row.substring(0, row.lastIndexOf('/')),
      SpecLinkValidator._registryClasses(ff.refersTo),
    );
    if (a === null) {
      return;
    }
    const aId = this._firstIdentity(a, ff.refersTo);
    if (aId === null) {
      return;
    }
    const filter = inv.where === null ? null : SpecPlaceFilter.tryParse(inv.where);
    const filterField = filter !== null ? filter.field : null;
    const whereValues =
      filterField === null ? new Set() : new Set(this.ownValues(row, filterField));
    // The same place beneath the named entry, every row of it.
    const rel = form
      .substring(a.length)
      .split('/')
      .map((s) => {
        const dash = s.lastIndexOf('-');
        return dash > 0 && _intTryParse(s.substring(dash + 1)) !== null
          ? `${s.substring(0, dash)}-*`
          : s;
      })
      .join('/');
    for (const b of SpecLinkValidator.ids(value)) {
      const bPath = entries.get(b);
      if (bPath === undefined || bPath === a) {
        continue;
      }
      const counterpart = this.expand(`${bPath}${rel}`).some((p) => {
        const r = this.nearestItem(p);
        if (r === null || !this._passes(inv.where, r)) {
          return false;
        }
        if (filterField !== null) {
          const own = new Set(this.ownValues(r, filterField));
          for (const v of whereValues) {
            if (!own.has(v)) {
              return false;
            }
          }
        }
        return SpecLinkValidator.ids(this.formValue(p, ff.name)).includes(aId);
      });
      if (!counterpart) {
        const star = rel.indexOf('-*');
        if (star > 0) {
          const list = `${bPath}${rel.substring(0, star)}`;
          const below = rel.substring(star + 3);
          const values = { [`${below}#${ff.name}`]: aId };
          if (filterField !== null) {
            for (const p of this._ownForms(row)) {
              if (this.doc.formField(p, filterField) !== null) {
                values[`${p.substring(row.length + 1)}#${filterField}`] = this.formValue(
                  p,
                  filterField,
                );
              }
            }
          }
          this.fixes.push(SpecLinkFix.addRow(1, list, values));
        }
        this.report(
          SpecValidationCode.INVERSE_MISSING,
          form,
          `the row names ${b}, but ${b} holds no row naming ${aId} back` +
            `${inv.where === null ? '' : ` (${inv.where})`}`,
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // @ExtractsLinks and the link rows
  // -------------------------------------------------------------------------

  _checkExtracts(i, f) {
    const all = f.extractsLinks;
    if (all.length === 0 || f.kind !== SpecFieldKind.LIST) {
      return;
    }
    const listPath = this._formPath(i, f);
    const rows = this.doc.listItems(listPath);
    const element = this.nearestItem(i.path);
    const own = element === null ? null : this.itemId(element);

    // A link row holding no value at all (what accepting the marked removal
    // of a row leaves) is removed.
    for (const row of rows) {
      if (!this.holdsValue(row)) {
        this.fixes.push(SpecLinkFix.removeRow(row, true));
      }
    }

    // The ids each row names, and its type (the values `set` writes).
    const setKeySet = new Set();
    for (const e of all) {
      for (const k of Object.keys(e.set)) {
        setKeySet.add(k);
      }
    }
    const setKeys = _sortedStrings(setKeySet);
    const named = new Map();
    const seen = new Map();
    for (const row of rows) {
      const ids = [];
      for (const e of all) {
        const r = this.at(e.ref, row);
        if (r === null) {
          continue;
        }
        for (const p of this.expand(r.path)) {
          ids.push(...SpecLinkValidator.ids(this.value(r, p)));
        }
      }
      const unique = Array.from(new Set(ids));
      named.set(row, unique);
      const type = setKeys.map((k) => this.placeValue(k, row)).join(' | ');
      for (const id of unique) {
        const key = `${id} // ${type}`;
        const first = seen.get(key);
        if (first !== undefined) {
          this.report(
            SpecValidationCode.DUPLICATE_LINK_ROW,
            row,
            `the row names ${id} with the type "${type}", as ${first} does`,
          );
        } else {
          seen.set(key, row);
        }
      }
    }
    const rowed = new Set();
    for (const ids of named.values()) {
      for (const id of ids) {
        rowed.add(id);
      }
    }

    for (const e of all) {
      let refSpec;
      if (rows.length === 0) {
        refSpec = this._refSpecFromModel(f, e.ref);
      } else {
        const r = this.at(e.ref, rows[0]);
        refSpec = r !== null ? r.formField : null;
      }
      if (refSpec === null) {
        continue;
      }
      const registry = new Set(this.entries(refSpec.refersTo).keys());
      const found = [];
      for (const place of e.from) {
        const p = place.startsWith('./') ? place : `./${place}`;
        const r = this.at(p, i.path);
        if (r === null) {
          continue;
        }
        for (const path of this.expand(r.path)) {
          for (const id of SpecLinkValidator._idsIn(this.value(r, path), registry)) {
            if (id !== own && !found.includes(id)) {
              found.push(id);
            }
          }
        }
      }
      for (const id of found) {
        if (rowed.has(id)) {
          continue;
        }
        if (e.mode === 'generate') {
          const values = {};
          const writes = new Map([[e.ref, id]]);
          for (const [k, v] of Object.entries(e.set)) {
            writes.set(k, v);
          }
          for (const [k, v] of writes) {
            const r = this.at(k, `${listPath}-0`);
            if (r === null || r.field === null) {
              continue;
            }
            const rel = r.path.substring(`${listPath}-0`.length + 1);
            values[`${rel}#${r.field}`] = v;
          }
          this.fixes.push(SpecLinkFix.addRow(1, listPath, values));
        }
        this.report(
          SpecValidationCode.EXTRACTED_LINK_MISSING,
          listPath,
          `${id} is named in ${e.from.join(' / ')} but has no row` +
            `${e.mode === 'warn' ? ' (warn: the agent adds it)' : ''}`,
        );
      }
    }
    // A generated row: every `set` value of a generate-mode use matches.
    for (const e of all.filter((x) => x.mode === 'generate')) {
      const mine = new Set();
      for (const place of e.from) {
        const p = place.startsWith('./') ? place : `./${place}`;
        const r = this.at(p, i.path);
        if (r === null) {
          continue;
        }
        const refR = rows.length === 0 ? null : this.at(e.ref, rows[0]);
        const refSpec = refR !== null ? refR.formField : null;
        const registry =
          refSpec === null ? new Set() : new Set(this.entries(refSpec.refersTo).keys());
        for (const path of this.expand(r.path)) {
          for (const id of SpecLinkValidator._idsIn(this.value(r, path), registry)) {
            mine.add(id);
          }
        }
      }
      for (const row of rows) {
        const generated = Object.entries(e.set).every(([k, v]) => this.placeValue(k, row) === v);
        if (!generated) {
          continue;
        }
        for (const id of named.get(row)) {
          if (!mine.has(id)) {
            this.fixes.push(SpecLinkFix.removeRow(row));
            this.report(
              SpecValidationCode.EXTRACTED_LINK_STALE,
              row,
              `the generated row names ${id}, which ${e.from.join(' / ')} no ` + 'longer names',
            );
          }
        }
      }
    }
  }

  _refSpecFromModel(list, ref) {
    const el = this.refl.classNamed(list.elementType);
    if (el === null) {
      return null;
    }
    const dot = ref.indexOf('.');
    if (dot < 0) {
      return null;
    }
    const id = ref.substring(0, dot);
    const name = ref.substring(dot + 1);
    for (const f of el.fields) {
      const fid = f.name === 'content' ? el.sectionId : f.sectionId;
      if (fid !== id) {
        continue;
      }
      for (const ff of f.formFields) {
        if (ff.name === name) {
          return ff;
        }
      }
    }
    return null;
  }

  /**
   * The ids of `registry` named in `text`, each matched exactly (not as a part
   * of a longer id), in order of first appearance.
   */
  static _idsIn(text, registry) {
    const out = [];
    const token = /[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]|[A-Za-z0-9]/g;
    for (const m of text.matchAll(token)) {
      const id = m[0];
      if (registry.has(id) && !out.includes(id)) {
        out.push(id);
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // @SameAs
  // -------------------------------------------------------------------------

  _checkSameAs(rootType) {
    for (const b of specSameAsBindings(this.refl, rootType)) {
      if (b.holderPath === null) {
        continue;
      }
      const copies = this.expand(b.copyPath);
      const holders = this.expand(b.holderPath);
      if (copies.length !== holders.length) {
        continue;
      }
      for (let k = 0; k < copies.length; k++) {
        if (this._compareSubtrees(copies[k], holders[k])) {
          this.fixes.push(SpecLinkFix.copy(copies[k], holders[k]));
        }
      }
    }
  }

  /**
   * Every value beneath `root` (itself included), keyed by its path relative
   * to `root` with list items written by their section id, so two subtrees
   * compare element by element.
   */
  subtree(root) {
    const key = (path) => {
      const rel = path === root ? '' : path.substring(root.length + 1);
      if (rel === '') {
        return '';
      }
      const out = [];
      let at = root;
      for (const seg of rel.split('/')) {
        at = `${at}/${seg}`;
        out.push(
          this.isItem(at) ? `${seg.substring(0, seg.lastIndexOf('-'))}[${this.itemId(at)}]` : seg,
        );
      }
      return out.join('/');
    };
    const under = (p) => p === root || p.startsWith(`${root}/`);
    const out = new Map();
    for (const p of this.doc.contentPaths) {
      if (under(p)) {
        out.set(`c:${key(p)}`, { path: p, value: this.contentValue(p) });
      }
    }
    for (const p of this.doc.formPaths) {
      if (!under(p)) {
        continue;
      }
      for (const field of this.doc.formFieldNames(p)) {
        out.set(`f:${key(p)}#${field}`, { path: p, value: this.formValue(p, field) });
      }
    }
    for (const p of this.doc.headlinePaths) {
      if (under(p)) {
        out.set(`h:${key(p)}`, { path: p, value: this.headlineValue(p) });
      }
    }
    for (const l of this.doc.listPaths) {
      if (!under(l)) {
        continue;
      }
      for (const item of this.doc.listItems(l)) {
        out.set(`i:${key(item)}`, { path: item, value: this.itemId(item) });
      }
    }
    for (const [k, v] of Array.from(out)) {
      if (v.value === '') {
        out.delete(k);
      }
    }
    return out;
  }

  /** Reports every difference of `copy` from `holder`; whether there is one. */
  _compareSubtrees(copy, holder) {
    const mine = this.subtree(copy);
    const theirs = this.subtree(holder);
    const keys = _sortedStrings(new Set([...mine.keys(), ...theirs.keys()]));
    // An element on one side only is one finding; its values are not compared.
    const oneSided = keys
      .filter((k) => k.startsWith('i:') && mine.has(k) !== theirs.has(k))
      .map((k) => k.substring(2));
    const beneath = (k) => {
      const rel = k.substring(2).split('#')[0];
      return !k.startsWith('i:') && oneSided.some((o) => rel === o || rel.startsWith(`${o}/`));
    };

    let differs = false;
    for (const k of keys) {
      const a = mine.get(k);
      const b = theirs.get(k);
      const av = a !== undefined ? a.value : null;
      const bv = b !== undefined ? b.value : null;
      if (av === bv || beneath(k)) {
        continue;
      }
      differs = true;
      const what = k.startsWith('i:')
        ? `element ${(a !== undefined ? a : b).value}`
        : k.startsWith('h:')
          ? 'the headline'
          : k.startsWith('c:')
            ? 'the content'
            : `form field "${k.substring(k.indexOf('#') + 1)}"`;
      this.report(
        SpecValidationCode.SAME_AS_MISMATCH,
        a !== undefined ? a.path : copy,
        `the copy of ${holder} differs in ${what}: the copy holds ` +
          `"${av !== null ? av : ''}", the holder "${bv !== null ? bv : ''}"`,
      );
    }
    return differs;
  }

  // -------------------------------------------------------------------------
  // Helpers of the fixes
  // -------------------------------------------------------------------------

  /**
   * The field a resolved value place names for a write: the form field, the
   * headline's reserved field, or `null` for content.
   */
  static fieldOf(r) {
    switch (r.kind) {
      case SpecPlaceKind.FORM_FIELD:
        return r.field;
      case SpecPlaceKind.HEADLINE:
        return K_SPEC_HEADLINE_FIELD;
      default:
        return null;
    }
  }

  /** The forms directly beneath `row` (`<row>/<member>`). */
  _ownForms(row) {
    const out = [];
    for (const p of this.doc.formPaths) {
      if (p.startsWith(`${row}/`) && !p.substring(row.length + 1).includes('/')) {
        out.push(p);
      }
    }
    return out;
  }

  /** Whether anything beneath `path` holds a value (marks included). */
  holdsValue(path) {
    if (this._valued === null) {
      const out = new Set();
      const up = (p, self = true) => {
        let cur = self ? p : p.includes('/') ? p.substring(0, p.lastIndexOf('/')) : '';
        while (cur !== '' && !out.has(cur)) {
          out.add(cur);
          const slash = cur.lastIndexOf('/');
          cur = slash < 0 ? '' : cur.substring(0, slash);
        }
      };
      const doc = this.doc;
      for (const p of doc.contentPaths) {
        if ((doc.content(p) || '').trim() !== '') {
          up(p);
        }
      }
      for (const p of doc.formPaths) {
        let any = false;
        for (const f of doc.formFieldNames(p)) {
          if ((doc.formField(p, f) || '').trim() !== '') {
            any = true;
            break;
          }
        }
        if (any) {
          up(p);
        }
      }
      for (const p of doc.headlinePaths) {
        if ((doc.headline(p) || '') !== '') {
          up(p, false);
        }
      }
      for (const l of doc.listPaths) {
        if (doc.listItems(l).length > 0) {
          up(l);
        }
      }
      this._valued = out;
    }
    return this._valued.has(path);
  }
}

/** Dart's `int.tryParse` (decimal, optional sign, surrounding whitespace). */
function _intTryParse(text) {
  const t = text.trim();
  return /^[+-]?\d+$/.test(t) ? parseInt(t, 10) : null;
}

module.exports = {
  validateLinks,
  specExpandPattern,
  specResolvePlaceAt,
  specResolveLinkPlace,
  SpecLinkFix,
  SpecLinkValidator,
};
