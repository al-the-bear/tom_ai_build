'use strict';

/**
 * A sparse, live instance of a TomSpecs document — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_document.dart` (and `spec_document.py`).
 *
 * The structure is defined by the `SpecModel` class graph; this holds only the
 * *values* the user/agent has actually set, keyed by the globally-unique
 * section-ID path. Nothing is materialised until written, so an untouched
 * document is empty (the "empty = no value" rule).
 *
 * Three sparse stores cover the writable field kinds:
 *
 *   * `_content` — `content`/`scalar` leaves: path → string value;
 *   * `_form` — `@Form` sections: path → (form-field name → value);
 *   * `_listItems` — lists: list path → ordered item paths.
 *
 * List item paths are `"<listPath>-<seq>"` where `seq` is a per-list monotonic
 * counter that never reuses a number.
 */
class SpecDocument {
  constructor() {
    /** @type {Map<string, string>} */
    this._content = new Map();
    /** @type {Map<string, Map<string, string>>} */
    this._form = new Map();
    /** @type {Map<string, string[]>} */
    this._listItems = new Map();
    /** @type {Map<string, number>} */
    this._listSeq = new Map();
  }

  // --- content ------------------------------------------------------------

  /** @returns {string|null} */
  content(path) {
    return this._content.has(path) ? this._content.get(path) : null;
  }

  /** Sets the content string at `path`. An empty value clears it. */
  setContent(path, value) {
    if (value === '') {
      this._content.delete(path);
    } else {
      this._content.set(path, value);
    }
  }

  // --- forms --------------------------------------------------------------

  /** @returns {string|null} */
  formField(path, fieldName) {
    const fields = this._form.get(path);
    if (!fields || !fields.has(fieldName)) {
      return null;
    }
    return fields.get(fieldName);
  }

  /**
   * Sets form `fieldName` at `path`. An empty value clears that field (and the
   * whole form entry once its last field is gone).
   */
  setFormField(path, fieldName, value) {
    let fields = this._form.get(path);
    if (value === '') {
      if (fields) {
        fields.delete(fieldName);
        if (fields.size === 0) {
          this._form.delete(path);
        }
      }
    } else {
      if (!fields) {
        fields = new Map();
        this._form.set(path, fields);
      }
      fields.set(fieldName, value);
    }
  }

  // --- lists --------------------------------------------------------------

  /** @returns {string[]} */
  listItems(listPath) {
    const items = this._listItems.get(listPath);
    return items ? items.slice() : [];
  }

  /** Appends a new item to the list at `listPath` and returns its stable path. */
  addListItem(listPath) {
    const seq = (this._listSeq.get(listPath) || 0) + 1;
    this._listSeq.set(listPath, seq);
    const itemPath = `${listPath}-${seq}`;
    let items = this._listItems.get(listPath);
    if (!items) {
      items = [];
      this._listItems.set(listPath, items);
    }
    items.push(itemPath);
    return itemPath;
  }

  /**
   * Removes the list item at `itemPath` along with every value nested beneath it.
   * The counter is left untouched so future items keep getting fresh sequence
   * numbers (no renumbering).
   *
   * @returns {boolean}
   */
  removeListItem(itemPath) {
    let owningList = null;
    for (const [key, items] of this._listItems) {
      if (items.includes(itemPath)) {
        owningList = key;
        break;
      }
    }
    if (owningList === null) {
      return false;
    }
    const items = this._listItems.get(owningList);
    const at = items.indexOf(itemPath);
    items.splice(at, 1);
    if (items.length === 0) {
      this._listItems.delete(owningList);
    }
    this._purgeUnder(itemPath);
    return true;
  }

  _purgeUnder(prefix) {
    const isUnder = (key) =>
      key === prefix ||
      key.startsWith(`${prefix}/`) ||
      key.startsWith(`${prefix}-`);
    for (const store of [this._content, this._form, this._listItems, this._listSeq]) {
      for (const key of Array.from(store.keys())) {
        if (isUnder(key)) {
          store.delete(key);
        }
      }
    }
  }

  // --- queries ------------------------------------------------------------

  get isEmpty() {
    return (
      this._content.size === 0 &&
      this._form.size === 0 &&
      this._listItems.size === 0
    );
  }

  /**
   * Whether any value exists at `prefix` or nested beneath it — the structural
   * "empty = no value" test (the exact inverse of the purge predicate, so
   * emptiness and purge stay in lock-step).
   */
  hasValuesUnder(prefix) {
    const isUnder = (key) =>
      key === prefix ||
      key.startsWith(`${prefix}/`) ||
      key.startsWith(`${prefix}-`);
    for (const k of this._content.keys()) {
      if (isUnder(k)) return true;
    }
    for (const k of this._form.keys()) {
      if (isUnder(k)) return true;
    }
    for (const k of this._listItems.keys()) {
      if (isUnder(k)) return true;
    }
    return false;
  }

  /** @returns {Iterable<string>} */
  get contentPaths() {
    return this._content.keys();
  }

  /** @returns {Iterable<string>} */
  get formPaths() {
    return this._form.keys();
  }

  /** @returns {Iterable<string>} */
  get listPaths() {
    return this._listItems.keys();
  }

  /** @returns {Iterable<string>} */
  formFieldNames(path) {
    const fields = this._form.get(path);
    return fields ? fields.keys() : [];
  }

  /** @returns {number} */
  listItemCount(listPath) {
    const items = this._listItems.get(listPath);
    return items ? items.length : 0;
  }

  // --- persistence --------------------------------------------------------

  /**
   * A plain-data view of every value held, for persistence. Only non-empty
   * stores are included, and each is sorted by full section-ID path so the saved
   * file diffs/merges cleanly. The inverse of {@link loadJson}.
   *
   * @returns {Object}
   */
  toJson() {
    const out = {};
    if (this._content.size > 0) {
      const content = {};
      for (const k of Array.from(this._content.keys()).sort()) {
        content[k] = this._content.get(k);
      }
      out.content = content;
    }
    if (this._form.size > 0) {
      const forms = {};
      for (const k of Array.from(this._form.keys()).sort()) {
        const fields = this._form.get(k);
        const entry = {};
        for (const f of Array.from(fields.keys()).sort()) {
          entry[f] = fields.get(f);
        }
        forms[k] = entry;
      }
      out.forms = forms;
    }
    if (this._listItems.size > 0) {
      const lists = {};
      for (const k of Array.from(this._listItems.keys()).sort()) {
        const items = this._listItems.get(k);
        lists[k] = {
          seq: this._listSeq.has(k) ? this._listSeq.get(k) : items.length,
          items: items.slice(),
        };
      }
      out.lists = lists;
    }
    return out;
  }

  /**
   * Replaces every store from a {@link toJson}-shaped object. Coerces leaf
   * values to strings and skips unknown/empty entries.
   */
  loadJson(json) {
    this._content.clear();
    this._form.clear();
    this._listItems.clear();
    this._listSeq.clear();

    const content = json ? json.content : null;
    if (content && typeof content === 'object') {
      for (const [k, v] of Object.entries(content)) {
        if (v !== null && v !== undefined) {
          this._content.set(String(k), String(v));
        }
      }
    }

    const forms = json ? json.forms : null;
    if (forms && typeof forms === 'object') {
      for (const [k, fields] of Object.entries(forms)) {
        if (fields && typeof fields === 'object') {
          const entry = new Map();
          for (const [f, v] of Object.entries(fields)) {
            if (v !== null && v !== undefined) {
              entry.set(String(f), String(v));
            }
          }
          if (entry.size > 0) {
            this._form.set(String(k), entry);
          }
        }
      }
    }

    const lists = json ? json.lists : null;
    if (lists && typeof lists === 'object') {
      for (const [k, spec] of Object.entries(lists)) {
        if (spec && typeof spec === 'object') {
          const items = spec.items;
          const itemList = Array.isArray(items) ? items.map((it) => String(it)) : [];
          if (itemList.length > 0) {
            this._listItems.set(String(k), itemList);
          }
          const seq = spec.seq;
          if (typeof seq === 'number' && Number.isInteger(seq)) {
            this._listSeq.set(String(k), seq);
          } else if (typeof seq === 'string' && /^-?[0-9]+$/.test(seq)) {
            this._listSeq.set(String(k), parseInt(seq, 10));
          } else {
            this._listSeq.set(String(k), itemList.length);
          }
        }
      }
    }
  }
}

module.exports = { SpecDocument };
