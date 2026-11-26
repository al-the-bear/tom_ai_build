'use strict';

/**
 * deriveFields: the derived places of one document, written
 * (`tom_specs_model_rules.md` §9.7). A port of
 * `tom_som_dart_runtime/lib/src/spec_derive_fields.dart`.
 */

const { SpecDocument } = require('./spec_document');
const { SpecLinkValidator } = require('./spec_links_validator');
const {
  K_SPEC_HEADLINE_FIELD,
  SpecReviewAnnotations,
  applyInlineMarksText,
  markChangeText,
} = require('./spec_review_annotations');
const {
  SpecValidationCode,
  SpecValidationError,
  specDerivedNumbers,
} = require('./spec_validator');

/** One place {@link deriveFields} wrote. */
class SpecDeriveChange {
  constructor(props) {
    /**
     * The step that wrote it: 1 (link ends and rows), 2 (derived values,
     * repeats, `@SameAs` copies), 3 (counts, products, ranks).
     */
    this.step = props.step;
    /** `value` (a value written), `rowAdded`, `rowRemoved`. */
    this.kind = props.kind;
    /** The value's path, or the row's. */
    this.path = props.path;
    /** The form field ({@link K_SPEC_HEADLINE_FIELD} for a headline), or null. */
    this.field = props.field != null ? props.field : null;
    /** The value before (for a row, empty). */
    this.oldValue = props.oldValue ?? '';
    /** The value after (for a row, empty). */
    this.newValue = props.newValue ?? '';
  }

  /** The canonical JSON form. */
  toJson() {
    return {
      step: this.step,
      kind: this.kind,
      path: this.path,
      ...(this.field !== null ? { field: this.field } : {}),
      old: this.oldValue,
      new: this.newValue,
    };
  }
}

/** What {@link deriveFields} did. */
class SpecDeriveResult {
  constructor(props) {
    /** The document written: the one given, or its copy on a dry run. */
    this.document = props.document;
    /** Every place written, in the order written. */
    this.changes = props.changes;
    /**
     * What it could not write, with the code: `unmarkable` (a change it cannot
     * mark exactly in a document under review, left as it was),
     * `derivedLookupMiss` (a lookup without exactly one row).
     */
    this.unresolved = props.unresolved;
  }

  /** The canonical JSON form (the document as its stores). */
  toJson() {
    return {
      changes: this.changes.map((c) => c.toJson()),
      unresolved: this.unresolved.map((e) => ({
        path: e.path,
        code: e.code,
        message: e.message,
      })),
      document: this.document.toJson(),
    };
  }
}

/**
 * Recomputes the derived places of `doc` (`tom_specs_model_rules.md` §9.7)
 * in three steps, each reading the result of the one before:
 *
 * 1. the missing `inverseOf` ends inside the document, the missing
 *    `@ExtractsLinks` rows in `generate` mode, and the stale generated rows
 *    removed (a link row left with no value at all goes too);
 * 2. `@DerivedFrom` values and lists, `@SummaryOf` `repeats`, and every
 *    `@SameAs` copy from its holder;
 * 3. `countOf`, `productOf` and `rankOf`.
 *
 * `marked` (default true; a document under review) writes every change as
 * inline marks (SOM §11.9.3) attributed to `author` at `at`, and reads values
 * as proposed (pending marks accepted). Without it values are written plain.
 * A change it cannot mark exactly is left as it was and listed as
 * `unmarkable`. It never writes another document. A second run right after
 * the first writes nothing. `dryRun` works on a copy.
 */
function deriveFields(
  model,
  doc,
  options = {},
) {
  let target = doc;
  if (options.dryRun === true) {
    target = new SpecDocument();
    target.loadJson(doc.toJson());
  }
  const d = new _Deriver(
    model,
    target,
    options.marked !== false,
    options.author ?? null,
    options.at ?? null,
  );
  d.run();
  return new SpecDeriveResult({
    document: target,
    changes: d.changes,
    unresolved: d.unresolved,
  });
}

function _sorted(values) {
  return Array.from(values).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}

class _Deriver {
  changes = [];
  unresolved = [];
  _unresolvedKeys = new Set();

  constructor(
    model,
    doc,
    marked,
    author,
    at,
  ) {
    this.model = model;
    this.doc = doc;
    this.marked = marked;
    this.author = author;
    this.at = at;
    const fixed = at;
    this.api = new SpecReviewAnnotations(doc, {
      clock: fixed === null ? null : () => fixed,
    });
  }

  _check() {
    return new SpecLinkValidator(this.model, this.doc, { readProposed: this.marked }).run();
  }

  run() {
    // Step 1: link ends and rows. Removals first, so a row removed and a row
    // added for the same id do not cancel out.
    let v = this._check();
    const step1 = v.fixes.filter((f) => f.step === 1);
    for (const f of step1.filter((f) => f.kind === 'removeRow')) {
      this._removeRow(1, f.path, f.empty);
    }
    for (const f of step1.filter((f) => f.kind !== 'removeRow')) {
      this._apply(f, v);
    }

    // Step 2: derived values and lists, then (reading them) the repeats and
    // the copies; again until nothing moves, which DERIVE-ACYCLIC bounds.
    for (let round = 0; round < 4; round++) {
      v = this._check();
      const before = this.changes.length;
      for (const f of v.fixes.filter((f) => f.step === 2 && f.kind !== 'copy')) {
        this._apply(f, v);
      }
      v = this._check();
      for (const f of v.fixes.filter((f) => f.kind === 'copy')) {
        this._apply(f, v);
      }
      if (this.changes.length === before) {
        break;
      }
    }
    for (const e of v.errors) {
      if (e.code === SpecValidationCode.DERIVED_LOOKUP_MISS) {
        this._unresolved(e);
      }
    }

    // Step 3: counts, products, ranks.
    for (const n of specDerivedNumbers(this.model, this.doc, { readProposed: this.marked })) {
      this._write(3, n.path, n.field, n.value);
    }
  }

  _unresolved(e) {
    const key = `${e.code} ${e.path} ${e.message}`;
    if (!this._unresolvedKeys.has(key)) {
      this._unresolvedKeys.add(key);
      this.unresolved.push(e);
    }
  }

  // --- the writes ----------------------------------------------------------

  _get(path, field) {
    const v =
      field === K_SPEC_HEADLINE_FIELD
        ? this.doc.headline(path)
        : field === null
          ? this.doc.content(path)
          : this.doc.formField(path, field);
    return v ?? '';
  }

  _setPlain(path, field, value) {
    if (field === K_SPEC_HEADLINE_FIELD) {
      this.doc.setHeadline(path, value);
    } else if (field === null) {
      this.doc.setContent(path, value);
    } else {
      this.doc.setFormField(path, field, value);
    }
  }

  /**
   * Writes `value` at `path` / `field`: plainly, or marked against the value
   * there (compared from its original, so a change already proposed is not
   * proposed again).
   */
  _write(step, path, field, value) {
    const current = this._get(path, field);
    if (!this.marked) {
      if (current.trim() === value.trim()) {
        return;
      }
      this._setPlain(path, field, value);
    } else {
      if (applyInlineMarksText(current, { accept: true }).trim() === value.trim()) {
        return;
      }
      const original = applyInlineMarksText(current, { accept: false });
      if (!markChangeText(original, value).exact) {
        this._unresolved(
          new SpecValidationError(
            path,
            SpecValidationCode.UNMARKABLE,
            `${field === null ? 'the content' : `form field "${field}"`} ` +
              `would become "${value}", a change that cannot be marked ` +
              'exactly; it is left for the agent',
          ),
        );
        return;
      }
      this.api.setMarked({ path, field, text: value, author: this.author, at: this.at });
    }
    const now = this._get(path, field);
    if (now !== current) {
      this.changes.push(
        new SpecDeriveChange({ step, kind: 'value', path, field, oldValue: current, newValue: now }),
      );
    }
  }

  _addRow(
    step,
    list,
    values,
    sectionId = null,
  ) {
    const item = this.doc.addListItem(list, sectionId);
    this.changes.push(new SpecDeriveChange({ step, kind: 'rowAdded', path: item }));
    for (const [k, value] of Object.entries(values)) {
      const hash = k.indexOf('#');
      const rel = hash < 0 ? k : k.substring(0, hash);
      const field = hash < 0 ? null : k.substring(hash + 1);
      this._write(step, `${item}/${rel}`, field, value);
    }
  }

  _removeRow(step, row, empty = false) {
    if (!this.marked || empty) {
      if (!this.doc.removeListItem(row)) {
        return;
      }
      this.changes.push(new SpecDeriveChange({ step, kind: 'rowRemoved', path: row }));
      return;
    }
    // Under review: every value of the row is proposed for deletion; once
    // accepted, the empty row goes with the next run.
    const before = this.changes.length;
    const under = (p) => p === row || p.startsWith(`${row}/`);
    for (const p of _sorted(this.doc.contentPaths)) {
      if (under(p)) {
        this._write(step, p, null, '');
      }
    }
    for (const p of _sorted(this.doc.formPaths)) {
      if (!under(p)) {
        continue;
      }
      for (const f of _sorted(this.doc.formFieldNames(p))) {
        this._write(step, p, f, '');
      }
    }
    if (this.changes.length > before) {
      this.changes.splice(
        before,
        0,
        new SpecDeriveChange({ step, kind: 'rowRemoved', path: row }),
      );
    }
  }

  _apply(f, v) {
    switch (f.kind) {
      case 'set':
        this._write(f.step, f.path, f.field, f.value);
        return;
      case 'append': {
        const ids = SpecLinkValidator.ids(v.formValue(f.path, f.field));
        if (ids.includes(f.value)) {
          return;
        }
        this._write(f.step, f.path, f.field, [...ids, f.value].join(', '));
        return;
      }
      case 'addRow':
        this._addRow(f.step, f.path, f.values);
        return;
      case 'removeRow':
        this._removeRow(f.step, f.path, f.empty);
        return;
      case 'list':
        this._applyList(f, v);
        return;
      case 'copy':
        this._applyCopy(f.path, f.holder, v);
        return;
    }
  }

  /**
   * Makes the list hold one element per wanted tuple: elements matching no
   * tuple removed, tuples matching no element added.
   */
  _applyList(f, v) {
    const tuples = f.tuples;
    const places = tuples.length === 0 ? [] : Object.keys(tuples[0]);
    const key = (t) => places.map((p) => t[p]).join(' | ');
    const wanted = tuples.map(key);
    const keep = [];
    for (const el of this.doc.listItems(f.path).slice()) {
      const t = {};
      for (const p of places) {
        t[p] = v.placeValue(p, el);
      }
      const k = key(t);
      const i = wanted.indexOf(k);
      if (i < 0) {
        this._removeRow(2, el);
      } else {
        wanted.splice(i, 1);
        keep.push(k);
      }
    }
    for (const t of tuples) {
      const k = key(t);
      const ki = keep.indexOf(k);
      if (ki >= 0) {
        keep.splice(ki, 1);
        continue;
      }
      const values = {};
      const probe = `${f.path}-0`;
      for (const p of places) {
        const r = v.at(p, probe);
        if (r === null) {
          continue;
        }
        const rel = r.path.substring(probe.length + 1);
        values[r.field === null ? rel : `${rel}#${r.field}`] = t[p];
      }
      this._addRow(2, f.path, values);
    }
  }

  /**
   * Writes the copy at `copy` from its `holder`: every value and element
   * the holder has, in the copy, and nothing else.
   */
  _applyCopy(copy, holder, v) {
    const theirs = v.subtree(holder);
    const mine = v.subtree(copy);
    const doc = this.doc;
    const pathIn = (rel, create) => {
      let cur = copy;
      if (rel === '') {
        return cur;
      }
      for (const seg of rel.split('/')) {
        const bracket = seg.indexOf('[');
        if (bracket < 0) {
          cur = `${cur}/${seg}`;
          continue;
        }
        const list = `${cur}/${seg.substring(0, bracket)}`;
        const id = seg.substring(bracket + 1, seg.length - 1);
        const found = doc.listItems(list).find((i) => v.itemId(i) === id);
        if (found !== undefined) {
          cur = found;
        } else if (!create) {
          return null;
        } else {
          cur = doc.addListItem(list, id);
          v.itemIds.set(cur, id);
          this.changes.push(new SpecDeriveChange({ step: 2, kind: 'rowAdded', path: cur }));
        }
      }
      return cur;
    };

    const split = (key) => {
      const kind = key[0];
      const body = key.substring(2);
      switch (kind) {
        case 'f':
          return [body.substring(0, body.indexOf('#')), body.substring(body.indexOf('#') + 1)];
        case 'c':
          return [body, null];
        case 'h':
          return [body, K_SPEC_HEADLINE_FIELD];
        default:
          return null;
      }
    };

    // Elements the holder lacks go first, and nothing beneath them is
    // written.
    const gone = [];
    for (const k of _sorted(mine.keys())) {
      if (!k.startsWith('i:') || theirs.has(k)) {
        continue;
      }
      const rel = k.substring(2);
      if (gone.some((g) => rel.startsWith(`${g}/`))) {
        continue;
      }
      gone.push(rel);
      this._removeRow(2, mine.get(k).path);
    }
    const beneathGone = (rel) =>
      gone.some((g) => rel === g || rel.startsWith(`${g}/`));

    for (const k of _sorted(theirs.keys())) {
      if (k.startsWith('i:')) {
        pathIn(k.substring(2), true);
        continue;
      }
      const s = split(k);
      if (s === null) {
        continue;
      }
      const path = pathIn(s[0], true);
      if (path === null) {
        continue;
      }
      this._write(2, path, s[1], theirs.get(k).value);
    }
    for (const k of _sorted(mine.keys())) {
      if (theirs.has(k) || k.startsWith('i:')) {
        continue;
      }
      const s = split(k);
      if (s === null || beneathGone(s[0])) {
        continue;
      }
      const path = pathIn(s[0], false);
      if (path !== null) {
        this._write(2, path, s[1], '');
      }
    }
  }
}

module.exports = {
  SpecDeriveChange,
  SpecDeriveResult,
  deriveFields,
};
