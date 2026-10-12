'use strict';

const {
  SpecSectionIdCollision,
  effectiveListItemSectionId,
} = require('./spec_section_id');
const { SpecFieldKind } = require('./spec_model');
const { SpecReflection } = require('./spec_reflection');

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
     * The stored `codeSpec` forward-link per path (csmc8, codespecs_mapping.md §9.2): a comma-joined
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
   * thread-`documentVersion` incantation (SOM §21).
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

  // --- assembly -----------------------------------------------------------

  /**
   * Assembles one document from `fragments` — name → document, in order (a
   * `Map` or an iterable of `[name, document]` pairs) — each holding a subset
   * of the sections (`spec_document_assembly.js`). Refusing: a place two
   * fragments both write is an overlap, and an assembly with any overlap
   * carries no document.
   *
   * @param {Iterable<[string, SpecDocument]>} fragments
   * @returns {import('./spec_document_assembly').SpecDocumentAssembly}
   */
  static assemble(fragments) {
    const { assembleSpecDocuments } = require('./spec_document_assembly');
    return assembleSpecDocuments(fragments);
  }

  // --- markdown export ----------------------------------------------------

  /**
   * Renders this document to Markdown in one call (SOM §21).
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
   * Loads a SOM-rendered Markdown document (SOM §11.7) into a fresh document
   * in one call: parse, then {@link applyMarkdownResult}.
   *
   * Blocks the parser rejects are not loaded, and are returned with the
   * document, so a caller can show them or refuse to save: re-exporting a
   * document whose source had rejections drops those blocks for good.
   *
   * The markdown codec is required lazily (see {@link toMarkdown}).
   *
   * @param {string} text
   * @param {import('./spec_model').SpecModel} model
   * @returns {import('./spec_document_markdown').SpecMarkdownImport}
   */
  static fromMarkdown(text, model) {
    const { SpecDocumentMarkdown, SpecMarkdownImport } = require('./spec_document_markdown');
    const document = new SpecDocument();
    const result = new SpecDocumentMarkdown(model, document).parse(text);
    document.applyMarkdownResult(result, true);
    return new SpecMarkdownImport(document, result);
  }

  /**
   * Applies a parsed Markdown import as a **full overwrite** of the roots it
   * covers (SOM §11.7): every value under each of the result's
   * `rootPrefixes` is removed, then the parsed content, forms, lists,
   * headlines and codeSpecs are written. Other roots are left as they are.
   *
   * A result with rejections is refused with an {@link Error} — and the
   * document left unchanged — unless `allowRejections` is true: the blocks it
   * rejected would otherwise vanish from a document the caller believes it
   * imported whole.
   *
   * Store-agnostic on both halves: the purge goes through
   * {@link removeValuesUnder}, which clears every store, and the carry-over is
   * whatever {@link toJson} emits. This port has no path normalizer, so the
   * parsed paths are written as they are.
   *
   * @param {import('./spec_document_markdown').SpecMarkdownResult} result
   * @param {boolean} [allowRejections]
   */
  applyMarkdownResult(result, allowRejections = false) {
    if (!allowRejections && result.rejections.length > 0) {
      const first = result.rejections[0];
      throw new Error(
        `markdown import has ${result.rejections.length} rejected block(s); ` +
          `first at line ${first.line}: ${first.message}`,
      );
    }
    if (result.rootPrefixes.size === 0) {
      return;
    }
    for (const prefix of result.rootPrefixes) {
      this.removeValuesUnder(prefix);
    }

    const held = this.toJson();
    const store = (name) =>
      held[name] && typeof held[name] === 'object' ? { ...held[name] } : {};

    const lists = store('lists');
    for (const [key, spec] of Object.entries(result.lists)) {
      const entry = {
        seq: spec.seq,
        items: Array.isArray(spec.items) ? spec.items.map((i) => String(i)) : [],
      };
      if (spec.ids && typeof spec.ids === 'object') {
        entry.ids = { ...spec.ids };
      }
      lists[key] = entry;
    }

    this.loadJson({
      content: { ...store('content'), ...result.content },
      forms: { ...store('forms'), ...result.forms },
      lists,
      headlines: { ...store('headlines'), ...result.headlines },
      codeSpecs: { ...store('codeSpecs'), ...result.codeSpecs },
    });
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
   * null-free, leaf-exact companion to {@link content} (SOM §21). A value
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
   * codespecs_mapping.md §9.2). Structural mirror of {@link headline}.
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
   * Moves the list item at `itemPath` to position `toIndex` (0-based) of its
   * list, or of `toList`, another list of the same element class (vsctsa44).
   *
   * **A path is a position, the section id is the identity.** Every affected
   * list is renumbered to `<list>-1 … <list>-n` in its new order, and every
   * value under each item — content, forms, nested lists, headline, code-spec,
   * stored id — travels with it. An anonymous item whose positional id would
   * change has its old id stored, so its identity survives the renumbering.
   * The result maps every old item path to its new one; a caller holding
   * anything else keyed by path (the `review:` pass) re-keys it with
   * {@link SpecDocumentYaml.rekeyReview}.
   *
   * Across lists, the destination must hold the same element class, and an
   * item with a stored id keeps it only when the id fits the destination's
   * `@SectionIdPattern` and is free there; otherwise the move is refused
   * (`Error` / {@link SpecSectionIdCollision}) and nothing changes. An
   * anonymous item takes its positional id in the destination. A `toIndex`
   * outside `0..length` of the destination (after removing the item) throws a
   * `RangeError`, also without changing anything.
   *
   * @param {import('./spec_model').SpecModel} model
   * @param {string} itemPath
   * @param {number} toIndex
   * @param {string|null} [toList]
   * @returns {SpecListItemMove}
   */
  moveListItem(model, itemPath, toIndex, toList = null) {
    const item = itemPath;
    const from = this._owningListOf(item);
    if (from === null) {
      throw new Error(`'${itemPath}' is not a live list item`);
    }
    const to = toList === null || toList === undefined ? from : toList;
    const refl = new SpecReflection(model);
    const fromRes = refl.resolve(from);
    const fromField = fromRes ? fromRes.field : null;
    const toRes = refl.resolve(to);
    const toField = toRes ? toRes.field : null;
    if (toField === null || toField.kind !== SpecFieldKind.LIST) {
      throw new Error(`toList '${toList}' is not a list of the model`);
    }
    const fromElement = fromField ? fromField.elementType : null;
    if (to !== from && toField.elementType !== fromElement) {
      throw new Error(
        `toList '${toList}' holds ${toField.elementType}, but the item is a ` +
          `${fromElement} — an item moves only between lists of its own ` +
          'element class',
      );
    }
    const storedId = this._itemSectionId.has(item)
      ? (this._itemSectionId.get(item))
      : null;
    if (to !== from && storedId !== null) {
      const pattern = toField.sectionIdPattern;
      if (pattern !== null && !_sectionIdFitsPattern(pattern, storedId)) {
        throw new Error(
          `section id '${storedId}' does not fit the destination pattern ` +
            `${pattern} — set an id that does before moving the item`,
        );
      }
      this._assertSectionIdFree(to, storedId, null);
    }

    // The new orders.
    const fromOld = this._listItems.get(from);
    const fromItems = fromOld.filter((p) => p !== item);
    const toItems =
      to === from ? fromItems : (this._listItems.get(to) || []).slice();
    if (!Number.isInteger(toIndex) || toIndex < 0 || toIndex > toItems.length) {
      throw new RangeError(
        `toIndex ${toIndex} is not in the range 0..${toItems.length}`,
      );
    }
    toItems.splice(toIndex, 0, item);

    const fieldOf = (list) => (list === from ? fromField : toField);
    const stemOf = (list) => {
      const field = fieldOf(list);
      return field ? field.name : list.split('/').pop();
    };

    // Each affected item's effective id before the move, so an anonymous
    // item keeps its identity when its position changes.
    const before = new Map();
    const record = (list, items) => {
      const field = fieldOf(list);
      items.forEach((p, i) => {
        before.set(
          p,
          effectiveListItemSectionId(
            this._itemSectionId.get(p),
            field ? field.sectionIdPattern : null,
            i + 1,
            stemOf(list),
          ),
        );
      });
    };
    record(from, fromOld);
    if (to !== from) record(to, this._listItems.get(to) || []);

    // Old → new item paths, and the ids anonymous items must now store.
    const renamed = new Map();
    const pinned = new Map();
    const renumber = (list, items) => {
      const field = fieldOf(list);
      items.forEach((old, i) => {
        const now = `${list}-${i + 1}`;
        if (old !== now) renamed.set(old, now);
        const crossing = old === item && to !== from;
        if (this._itemSectionId.has(old) || crossing) return;
        const positional = effectiveListItemSectionId(
          null,
          field ? field.sectionIdPattern : null,
          i + 1,
          stemOf(list),
        );
        const was = before.get(old);
        if (positional !== was) pinned.set(old, was);
      });
    };
    renumber(from, fromItems);
    if (to !== from) renumber(to, toItems);

    const remap = (key) => _remapUnder(key, renamed);
    const rekey = (store) => {
      const out = new Map();
      for (const [k, v] of store) out.set(remap(k), v);
      return out;
    };

    const content = rekey(this._content);
    const form = rekey(this._form);
    const headline = rekey(this._headline);
    const codeSpec = rekey(this._codeSpec);
    const ids = rekey(this._itemSectionId);
    for (const [old, id] of pinned) ids.set(remap(old), id);
    const seq = rekey(this._listSeq);
    const lists = new Map();
    for (const [k, v] of this._listItems) {
      lists.set(remap(k), v.map(remap));
    }
    lists.set(remap(from), fromItems.map(remap));
    seq.set(remap(from), fromItems.length);
    if (to !== from) {
      lists.set(remap(to), toItems.map(remap));
      seq.set(remap(to), toItems.length);
    }
    for (const [k, v] of Array.from(lists)) {
      if (v.length === 0) lists.delete(k);
    }

    _replaceWith(this._content, content);
    _replaceWith(this._form, form);
    _replaceWith(this._headline, headline);
    _replaceWith(this._codeSpec, codeSpec);
    _replaceWith(this._itemSectionId, ids);
    _replaceWith(this._listSeq, seq);
    _replaceWith(this._listItems, lists);

    const pinnedIds = new Map();
    for (const [old, id] of pinned) pinnedIds.set(remap(old), id);
    return new SpecListItemMove(remap(item), renamed, pinnedIds);
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

  /**
   * Drops every value at `prefix` or nested beneath it — content, form
   * entries, list items (with their nested values, ids and counters), and
   * stored headlines (YRD7 generic modification API: "clear section").
   *
   * The predicate is the same one {@link hasValuesUnder} uses, so after this
   * call `hasValuesUnder(prefix)` is `false`. Note this clears *values under a
   * section path*; removing a single list item from its owning list is
   * {@link removeListItem}.
   *
   * @param {string} prefix
   */
  removeValuesUnder(prefix) {
    this._purgeUnder(prefix);
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

/** The result of {@link SpecDocument.moveListItem}. */
class SpecListItemMove {
  /**
   * @param {string} path the moved item's path after the move
   * @param {Map<string, string>} [renamed] every item path the move changed,
   *   old → new: the moved item and each sibling whose position moved. Values
   *   under a renamed item moved with it.
   * @param {Map<string, string>} [pinnedIds] the items (by new path) that were
   *   anonymous and now store the id they had by position, so their identity
   *   did not change with their position.
   */
  constructor(path, renamed = new Map(), pinnedIds = new Map()) {
    this.path = path;
    this.renamed = renamed;
    this.pinnedIds = pinnedIds;
  }
}

/**
 * `key` re-keyed by the first `old → new` entry of `renamed` it equals or lies
 * under (`old/…` for descendants, `old-…` for the item's own lists); `key`
 * itself when none applies. Shared by {@link SpecDocument.moveListItem} and
 * the `review:` re-keying in the YAML codec.
 *
 * @param {string} key
 * @param {Map<string, string>} renamed
 * @returns {string}
 */
function _remapUnder(key, renamed) {
  for (const [old, now] of renamed) {
    if (key === old) return now;
    if (key.startsWith(`${old}/`) || key.startsWith(`${old}-`)) {
      return now + key.substring(old.length);
    }
  }
  return key;
}

/** Whether `id` fits `pattern`, its `xxx` slot standing for any non-empty run. */
function _sectionIdFitsPattern(pattern, id) {
  const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`^${pattern.split('xxx').map(escape).join('.+')}$`).test(id);
}

/** Replaces the entries of `target` with those of `source`, in order. */
function _replaceWith(target, source) {
  target.clear();
  for (const [k, v] of source) target.set(k, v);
}

module.exports = { SpecDocument, SpecListItemMove, _remapUnder };
