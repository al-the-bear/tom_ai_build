'use strict';

const { SpecSectionIdCollision } = require('./spec_section_id');

/**
 * A sparse, live instance of a TomSpecs document — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_document.dart` (and `spec_document.py`).
 *
 * The structure is defined by the `SpecModel` class graph; this holds only the
 * *values* the user/agent has actually set, keyed by the globally-unique
 * section-ID path. Nothing is materialised until written, so an untouched
 * document is empty (the "empty = no value" rule).
 *
 * Four sparse stores cover the writable field kinds:
 *
 *   * `_content` — `content`/`scalar` leaves: path → string value;
 *   * `_form` — `@Form` sections: path → (form-field name → value);
 *   * `_listItems` — lists: list path → ordered item paths;
 *   * `_headline` — stored headlines (YRD3): path → headline text overriding
 *     the derived default title at that section's heading.
 *
 * List item paths are `"<listPath>-<seq>"` where `seq` is a per-list monotonic
 * counter that never reuses a number.
 *
 * Each list item also carries a **section id** (AA1 criteria 3–6): the
 * document-semantic identity generated from the list field's
 * `@SectionIdPattern`. This is distinct from the internal `-<seq>` path key:
 * the seq path keeps nested values attached across edits (never renumbered),
 * while the section id is what the document exposes and may be overridden
 * ({@link setItemSectionId}, criterion 5) or reused same-day after the last
 * item is deleted (criterion 6). Section ids live in `_itemSectionId`, keyed by
 * the internal item path.
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
    /** @type {Map<string, string>} */
    this._itemSectionId = new Map();
    /** @type {Map<string, string>} */
    this._headline = new Map();
    /**
     * The stored `codeSpec` forward-link per path (csmc8, §9.2): a comma-joined
     * list of code locations. Structural mirror of {@link _headline}.
     * @type {Map<string, string>}
     */
    this._codeSpec = new Map();
    /**
     * The authoring object-model version (`major.minor`) this document was
     * loaded from, or `null` for a brand-new / unstamped document. Retained
     * here by {@link SpecDocument.fromYaml} so a consumer need not thread
     * `decoded.modelVersion` to the typed facade by hand (the "forgot the
     * stamp" class of bug); the generated `loadYaml` / `loadFile` statics apply
     * it automatically.
     *
     * @type {string|null}
     */
    this.modelVersion = null;
  }

  // --- loading ------------------------------------------------------------

  /**
   * Loads a hierarchical v2 `*.docspecs.yaml` document in one call: decode
   * the YAML against the document's {@link SomMetaTree} and return the
   * populated document (with {@link modelVersion} already threaded by the
   * codec). Collapses the former three-step `decode` → `loadJson` →
   * thread-`documentVersion` incantation (§ item 4).
   *
   * The yaml codec is required lazily to sidestep any load-order/circular
   * require between this module and `spec_document_yaml.js`.
   *
   * @param {string} yaml
   * @param {import('./spec_meta').SomMetaTree} tree
   * @returns {SpecDocument}
   */
  static fromYaml(yaml, tree) {
    const { decode } = require('./spec_document_yaml');
    return decode(yaml, tree).document;
  }

  /**
   * Loads a `*.docspecs.yaml` document from the file at `path` — the file
   * companion to {@link fromYaml} the generated `loadFile` static delegates to.
   *
   * @param {string} path
   * @param {import('./spec_meta').SomMetaTree} tree
   * @returns {SpecDocument}
   */
  static fromFile(path, tree) {
    return SpecDocument.fromYaml(require('fs').readFileSync(path, 'utf8'), tree);
  }

  // --- markdown export ----------------------------------------------------

  /**
   * Renders this document to Markdown in one call (§ item 12).
   *
   * Collapses the former `new SpecDocumentMarkdown(model, doc).exportRoot(
   * model.roots.find((r) => r.type === …))` incantation. When `rootType` is
   * given, that root is exported (via {@link SpecModel.rootByType}); when
   * omitted, the document's single **populated** root is used — a root is
   * populated when it has any value beneath its segment
   * ({@link hasValuesUnder}). Throws an {@link Error} when the default is
   * ambiguous — zero populated roots, or more than one — so the caller names
   * the `rootType` explicitly.
   *
   * The markdown codec is required lazily to sidestep any load-order/circular
   * require between this module and `spec_document_markdown.js`.
   *
   * @param {import('./spec_model').SpecModel} model
   * @param {string|null} [rootType]
   * @returns {string}
   */
  toMarkdown(model, rootType = null) {
    const { SpecDocumentMarkdown } = require('./spec_document_markdown');
    const root =
      rootType !== null && rootType !== undefined
        ? model.rootByType(rootType)
        : this._singlePopulatedRoot(model);
    return new SpecDocumentMarkdown(model, this).exportRoot(root);
  }

  /**
   * The one root under which this document holds any value, for
   * {@link toMarkdown}'s default. Throws an {@link Error} when zero or more
   * than one root is populated.
   *
   * @param {import('./spec_model').SpecModel} model
   * @returns {import('./spec_model').SpecRoot}
   */
  _singlePopulatedRoot(model) {
    const populated = model.roots.filter((r) =>
      this.hasValuesUnder(r.sectionId != null ? r.sectionId : r.type),
    );
    if (populated.length === 1) {
      return populated[0];
    }
    if (populated.length === 0) {
      throw new Error(
        'document has no populated root to export; pass rootType to choose one',
      );
    }
    const types = populated.map((r) => r.type).join(', ');
    throw new Error(
      `document has ${populated.length} populated roots (${types}); ` +
        'pass rootType to choose one',
    );
  }

  // --- content ------------------------------------------------------------

  /** @returns {string|null} */
  content(path) {
    return this._content.has(path) ? this._content.get(path) : null;
  }

  /**
   * Whether a non-empty content-leaf value exists at *exactly* `path` — a
   * null-free, leaf-exact companion to {@link content} (§ item 5). A value
   * nested beneath `path` does **not** count (use {@link hasValuesUnder} for
   * the structural test).
   *
   * @returns {boolean}
   */
  hasContent(path) {
    const v = this._content.has(path) ? this._content.get(path) : null;
    return typeof v === 'string' && v.length > 0;
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

  // --- headlines (YRD3) ---------------------------------------------------

  /**
   * The stored headline at `path`, or `null` when none is stored (the
   * exporter then derives the default title).
   *
   * @returns {string|null}
   */
  headline(path) {
    return this._headline.has(path) ? this._headline.get(path) : null;
  }

  /** Sets the stored headline at `path`. An empty value clears it. */
  setHeadline(path, value) {
    if (value === '') {
      this._headline.delete(path);
    } else {
      this._headline.set(path, value);
    }
  }

  /** @returns {Iterable<string>} */
  get headlinePaths() {
    return this._headline.keys();
  }

  /**
   * The stored `codeSpec` at `path`, or `null` when none is stored (csmc8,
   * §9.2). Structural mirror of {@link headline}.
   *
   * @returns {string|null}
   */
  codeSpec(path) {
    return this._codeSpec.has(path) ? this._codeSpec.get(path) : null;
  }

  /** Sets the stored codeSpec at `path`. An empty value clears it. */
  setCodeSpec(path, value) {
    if (value === '') {
      this._codeSpec.delete(path);
    } else {
      this._codeSpec.set(path, value);
    }
  }

  /** @returns {Iterable<string>} */
  get codeSpecPaths() {
    return this._codeSpec.keys();
  }

  // --- lists --------------------------------------------------------------

  /** @returns {string[]} */
  listItems(listPath) {
    const items = this._listItems.get(listPath);
    return items ? items.slice() : [];
  }

  /**
   * Appends a new item to the list at `listPath` and returns its stable path.
   *
   * When `sectionId` is given it becomes the item's section id after a
   * uniqueness check against the list's other items (AA1 criterion 5); a
   * collision throws {@link SpecSectionIdCollision}. Section-id *generation*
   * from a `@SectionIdPattern` lives in the caller (it needs the pattern); this
   * layer only stores and guards uniqueness.
   *
   * @param {string} listPath
   * @param {string|null} [sectionId]
   * @returns {string}
   */
  addListItem(listPath, sectionId = null) {
    if (sectionId !== null && sectionId !== undefined) {
      this._assertSectionIdFree(listPath, sectionId, null);
    }
    const seq = (this._listSeq.get(listPath) || 0) + 1;
    this._listSeq.set(listPath, seq);
    const itemPath = `${listPath}-${seq}`;
    let items = this._listItems.get(listPath);
    if (!items) {
      items = [];
      this._listItems.set(listPath, items);
    }
    items.push(itemPath);
    if (sectionId !== null && sectionId !== undefined) {
      this._itemSectionId.set(itemPath, sectionId);
    }
    return itemPath;
  }

  /**
   * The section id assigned to the list item at `itemPath`, or `null` if none
   * has been set (AA1 criterion 1 read path).
   *
   * @param {string} itemPath
   * @returns {string|null}
   */
  itemSectionId(itemPath) {
    return this._itemSectionId.has(itemPath) ? this._itemSectionId.get(itemPath) : null;
  }

  /**
   * Overrides the section id of the list item at `itemPath` (AA1 criterion 5).
   *
   * Validates that the new `id` is unique among the *other* items of the same
   * owning list; a collision throws {@link SpecSectionIdCollision}. Assigning
   * an id equal to the item's current id is a no-op. Throws if `itemPath` is
   * not a live list item.
   *
   * @param {string} itemPath
   * @param {string} id
   */
  setItemSectionId(itemPath, id) {
    const owningList = this._owningListOf(itemPath);
    if (owningList === null) {
      throw new Error(`'${itemPath}' is not a live list item`);
    }
    if (this._itemSectionId.get(itemPath) === id) {
      return;
    }
    this._assertSectionIdFree(owningList, id, itemPath);
    this._itemSectionId.set(itemPath, id);
  }

  /**
   * The section ids currently assigned within the list at `listPath`, in item
   * order (items without an id are skipped). Feeds both id generation
   * (`existingIds`) and uniqueness checks.
   *
   * @param {string} listPath
   * @returns {string[]}
   */
  listItemSectionIds(listPath) {
    const items = this._listItems.get(listPath) || [];
    const out = [];
    for (const itemPath of items) {
      if (this._itemSectionId.has(itemPath)) {
        out.push(this._itemSectionId.get(itemPath));
      }
    }
    return out;
  }

  /**
   * The internal `_listItems` entry that owns `itemPath`, or `null`.
   *
   * @param {string} itemPath
   * @returns {string|null}
   */
  _owningListOf(itemPath) {
    for (const [key, items] of this._listItems) {
      if (items.includes(itemPath)) {
        return key;
      }
    }
    return null;
  }

  /**
   * Throws {@link SpecSectionIdCollision} if `id` is already used by an item of
   * `listPath` other than `exceptItemPath`.
   *
   * @param {string} listPath
   * @param {string} id
   * @param {string|null} exceptItemPath
   */
  _assertSectionIdFree(listPath, id, exceptItemPath) {
    const items = this._listItems.get(listPath) || [];
    for (const itemPath of items) {
      if (itemPath === exceptItemPath) {
        continue;
      }
      if (this._itemSectionId.get(itemPath) === id) {
        throw new SpecSectionIdCollision(id, listPath);
      }
    }
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
    for (const store of [
      this._content,
      this._form,
      this._listItems,
      this._listSeq,
      this._itemSectionId,
      this._headline,
      this._codeSpec,
    ]) {
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
      this._listItems.size === 0 &&
      this._headline.size === 0 &&
      this._codeSpec.size === 0
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
    for (const k of this._headline.keys()) {
      if (isUnder(k)) return true;
    }
    for (const k of this._codeSpec.keys()) {
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
        const entry = {
          seq: this._listSeq.has(k) ? this._listSeq.get(k) : items.length,
          items: items.slice(),
        };
        const ids = {};
        let hasIds = false;
        for (const itemPath of items) {
          if (this._itemSectionId.has(itemPath)) {
            ids[itemPath] = this._itemSectionId.get(itemPath);
            hasIds = true;
          }
        }
        if (hasIds) {
          entry.ids = ids;
        }
        lists[k] = entry;
      }
      out.lists = lists;
    }
    if (this._headline.size > 0) {
      const headlines = {};
      for (const k of Array.from(this._headline.keys()).sort()) {
        headlines[k] = this._headline.get(k);
      }
      out.headlines = headlines;
    }
    if (this._codeSpec.size > 0) {
      const codeSpecs = {};
      for (const k of Array.from(this._codeSpec.keys()).sort()) {
        codeSpecs[k] = this._codeSpec.get(k);
      }
      out.codeSpecs = codeSpecs;
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
    this._itemSectionId.clear();
    this._headline.clear();
    this._codeSpec.clear();

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
          const ids = spec.ids;
          if (ids && typeof ids === 'object') {
            for (const [itemPath, id] of Object.entries(ids)) {
              if (id !== null && id !== undefined) {
                this._itemSectionId.set(String(itemPath), String(id));
              }
            }
          }
        }
      }
    }

    const headlines = json ? json.headlines : null;
    if (headlines && typeof headlines === 'object') {
      for (const [k, v] of Object.entries(headlines)) {
        if (v !== null && v !== undefined && String(v) !== '') {
          this._headline.set(String(k), String(v));
        }
      }
    }

    const codeSpecs = json ? json.codeSpecs : null;
    if (codeSpecs && typeof codeSpecs === 'object') {
      for (const [k, v] of Object.entries(codeSpecs)) {
        if (v !== null && v !== undefined && String(v) !== '') {
          this._codeSpec.set(String(k), String(v));
        }
      }
    }
  }
}

module.exports = { SpecDocument };
