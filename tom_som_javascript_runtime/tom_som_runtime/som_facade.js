'use strict';

const { generateListItemSectionId } = require('./spec_section_id');

/**
 * The hand-written runtime support for the generated typed object model
 * (`tom_som_javascript_v0`) — a faithful port of
 * `tom_som_dart_runtime/lib/src/som_facade.dart` (and `som_facade.py`).
 *
 * The generated classes are a thin **editing facade** over the generic {@link
 * SpecDocument}: every typed getter/setter reads or writes the path-keyed
 * memory representation directly, so a mutation made through the typed surface
 * is immediately visible through the generic path and vice-versa (SOM §6 — the
 * two access paths share one document). These base types ({@link SomNode},
 * {@link SomList}, {@link SomScalar}) hold no state of their own beyond the
 * document and a path; the generated subclasses only add typed accessors.
 */

/**
 * The base class every generated typed facade class extends.
 *
 * It binds a facade instance to the {@link SpecDocument} it edits and the `path`
 * it lives at (the globally-unique section path, per `spec_paths`). The generated
 * subclass adds typed field accessors that delegate to `doc` at paths derived
 * from `path`.
 */
class SomNode {
  constructor(doc, path) {
    this.doc = doc;
    this.path = path;
  }

  /**
   * This node's section id when it is a list item (AA1 criterion 1 read), or
   * `null` for non-list nodes (roots, complex/section children — their id is
   * the fixed `@SectionId` already embedded in {@link path}).
   *
   * Named `$sectionId` — a name the JavaScript emitter never produces for a
   * model field accessor (the emitter's identifier sanitiser only appends `_`
   * for keywords and never prefixes `$`) — so this structural accessor can
   * never collide with a typed field a generated subclass emits (mirrors the
   * Dart `$sectionId` collision-proofing, AA-4 decision AD-D1).
   *
   * @returns {string|null}
   */
  get $sectionId() {
    return this.doc.itemSectionId(this.path);
  }

  /**
   * Overrides this list item's section id (AA1 criterion 5): an arbitrary
   * suffix, validated unique within the owning list. Throws
   * {@link SpecSectionIdCollision} on a duplicate, or an `Error` if this node is
   * not a live list item. Assigning `null`/`undefined` is a no-op.
   *
   * @param {string|null} id
   */
  set $sectionId(id) {
    if (id === null || id === undefined) {
      return;
    }
    this.doc.setItemSectionId(this.path, id);
  }

  /**
   * This node's stored headline (YRD3), or `null` when none is stored (the
   * exporter then derives the default title). Named `$headline` for the same
   * collision-proofing reason as {@link SomNode#$sectionId}.
   *
   * @returns {string|null}
   */
  get $headline() {
    return this.doc.headline(this.path);
  }

  /**
   * Sets this node's stored headline. Assigning `null`/`undefined`/`''`
   * clears the stored value (the derived default applies again).
   *
   * @param {string|null} value
   */
  set $headline(value) {
    this.doc.setHeadline(this.path, value || '');
  }

  /**
   * This section's CodeSpecs forward link (`codespecs_mapping.md` §9.2) as the
   * comma-joined list of code locations, or `null` when the section carries no
   * mapping. Sparse exactly like {@link SomNode#$headline}, and named
   * `$codeSpec` for the same collision-proofing reason as
   * {@link SomNode#$sectionId}.
   *
   * @returns {string|null}
   */
  get $codeSpec() {
    return this.doc.codeSpec(this.path);
  }

  /**
   * Sets this section's CodeSpecs forward link (codespecs_mapping.md §9.2).
   * Assigning `null`/`undefined`/`''` clears the mapping.
   *
   * @param {string|null} value
   */
  set $codeSpec(value) {
    this.doc.setCodeSpec(this.path, value || '');
  }

  /**
   * Whether this section holds no value at its {@link path} or nested beneath
   * it — the typed-facade view of "is this section filled?", kept in agreement
   * with the generic API by delegating to {@link SpecDocument#hasValuesUnder}
   * (SOM §21). Inherited by every generated section facade — intentional.
   *
   * @returns {boolean}
   */
  get isEmpty() {
    return !this.doc.hasValuesUnder(this.path);
  }

  /**
   * Whether this section **type** declares the standard `content` text leaf —
   * i.e. whether the `.content` getter/setter exists on it: "can this section
   * hold body text?" (SOM §21). A **structural / schema** predicate answered
   * at the type level, without probing `.content`.
   *
   * The base returns `false` — the answer for a node type that declares no
   * `content` leaf, such as a scalar list item whose value *is* its item path.
   * Every generated **section** class overrides it to `true`, since
   * `tom_specs_model_rules.md` §10.2 requires `content: String?` on all of
   * them, pure containers included. It is deliberately distinct from the two
   * **state** predicates: {@link SpecDocument#hasContent} answers "is a value
   * present at this leaf *now*?" and {@link isEmpty} answers "is this subtree
   * empty *now*?". `canHaveContent` never looks at the document — it describes
   * the model, not the data.
   *
   * It is also distinct from the **authoring** statement `@Unused()`, which
   * marks a `content` member the model expects to stay empty
   * (`tom_specs_model_rules.md` §5.6). Those sections still report `true` — the
   * slot is declared and writable, and prose is possible even where it is not
   * expected. A consumer wanting "is prose expected here?" reads the content
   * node's `unused` flag in the metadata instead.
   *
   * @returns {boolean}
   */
  get canHaveContent() {
    return false;
  }
}

/**
 * A scalar list item — a bare string value held in the document's content store
 * at its own item `path`. Used as the element facade for non-complex
 * (`string`/scalar) lists.
 */
class SomScalar extends SomNode {
  /** The string value at this item's path (`''` when unset). */
  get value() {
    return this.doc.content(this.path) || '';
  }

  /** Sets the string value (an empty string clears it, per {@link SpecDocument}). */
  set value(v) {
    this.doc.setContent(this.path, v);
  }
}

/**
 * A typed view over a list field, layered over the document's list store.
 *
 * Items are addressed by their stable item paths ({@link SpecDocument#listItems});
 * each is wrapped in an element facade by `factory`. The wrapper holds no items
 * itself — every operation reads through the live document, so it always reflects
 * the current state.
 */
class SomList {
  /**
   * @param {SpecDocument} doc
   * @param {string} listPath
   * @param {(doc: SpecDocument, path: string) => any} factory
   * @param {string|null} [pattern] the list field's `@SectionIdPattern` (e.g.
   *   `DACEN-ITEM-xxx`), or `null` for a pattern-less (scalar) list. Drives
   *   section-id generation on {@link add} (AA1 criteria 3–5).
   */
  constructor(doc, listPath, factory, pattern = null) {
    this.doc = doc;
    this.listPath = listPath;
    this._factory = factory;
    this.pattern = pattern;
  }

  /** The number of items currently in the list. */
  get length() {
    return this.doc.listItemCount(this.listPath);
  }

  /** The element facades for every item, in order. */
  get items() {
    return this.doc.listItems(this.listPath).map((p) => this._factory(this.doc, p));
  }

  /** The element facade for the item at `index`. */
  at(index) {
    return this._factory(this.doc, this.doc.listItems(this.listPath)[index]);
  }

  /** The section ids currently assigned within this list, in item order. */
  get sectionIds() {
    return this.doc.listItemSectionIds(this.listPath);
  }

  /**
   * Appends a new item and returns its element facade.
   *
   * When the list has a {@link pattern}, the new item is assigned a section id
   * (AA1 criteria 3–5): `sectionId` if given (an override, validated unique —
   * throws {@link SpecSectionIdCollision} on a collision), otherwise one
   * generated from the pattern using `date` (a `Date`, defaulting to today) for
   * the two-letter-date component. A pattern-less list ignores both arguments.
   *
   * @param {string|null} [sectionId]
   * @param {Date|null} [date]
   */
  add(sectionId = null, date = null) {
    return this._factory(this.doc, this._addItemPath(sectionId, date));
  }

  /**
   * Appends a content-only item and sets its nested `<item>/content` leaf in one
   * call, returning the new item's element facade.
   *
   * Uses the *same* section-id logic as {@link add} (`sectionId`/`date` honour
   * the list {@link pattern} identically), then writes `content` to the item's
   * nested `content` leaf via {@link SpecDocument#setContent}. Targets the
   * **nested** `<item>/content` leaf — scalar lists (whose value lives on the
   * item path itself) are out of scope.
   *
   * @param {string} content
   * @param {string|null} [sectionId]
   * @param {Date|null} [date]
   */
  addContent(content, sectionId = null, date = null) {
    const itemPath = this._addItemPath(sectionId, date);
    this.doc.setContent(`${itemPath}/content`, content); // nested <item>/content leaf
    return this._factory(this.doc, itemPath);
  }

  /**
   * An ordered, read-only view of every item's nested `<item>/content` leaf, a
   * missing leaf coalescing to `''`. Targets the **nested** `content` leaf, so
   * scalar lists are out of scope.
   *
   * @returns {string[]}
   */
  get contents() {
    return this.doc
      .listItems(this.listPath)
      .map((p) => this.doc.content(`${p}/content`) || '');
  }

  /**
   * Derives the item path for an appended item, applying the list's section-id
   * logic (AA1 criteria 3–5). Shared by {@link add} and {@link addContent}: a
   * pattern-less list ignores both arguments; otherwise `sectionId` (an
   * override, validated unique — throws {@link SpecSectionIdCollision}) is used
   * when given, else one generated from the {@link pattern} using `date` (a
   * `Date`, defaulting to today).
   *
   * @param {string|null} [sectionId]
   * @param {Date|null} [date]
   * @returns {string}
   */
  _addItemPath(sectionId = null, date = null) {
    if (this.pattern === null || this.pattern === undefined) {
      return this.doc.addListItem(this.listPath);
    }
    let id;
    if (sectionId !== null && sectionId !== undefined) {
      id = sectionId;
    } else {
      const when = date || new Date();
      id = generateListItemSectionId(
        this.pattern,
        when.getMonth() + 1,
        when.getDate(),
        this.doc.listItemSectionIds(this.listPath),
      );
    }
    return this.doc.addListItem(this.listPath, id);
  }

  /** Removes the item at `index` and every value nested beneath it. */
  removeAt(index) {
    this.doc.removeListItem(this.doc.listItems(this.listPath)[index]);
  }
}

/**
 * Raised when a generated object model is instantiated against a document whose
 * authoring model version it must not edit (SOM §4.2).
 */
class SomVersionError extends Error {
  constructor(message) {
    super(message);
    this.name = 'SomVersionError';
    this.message = message;
  }

  toString() {
    return `SomVersionError: ${this.message}`;
  }
}

/**
 * The outcome of the SOM §4.2 version check, as a value a read-only viewer can
 * branch on instead of catching {@link SomVersionError} (SOM §21).
 *
 * It is the non-throwing companion to {@link checkSomModelVersion}: the
 * constructor throws on any value other than `editable`, while
 * {@link somEditabilityFor} returns the same classification without throwing so
 * a consumer can decide *open for edit* vs *open read-only* up front.
 *
 *   * `editable` — the object model may edit the document in place: a
 *     `null`/empty stamp (a brand-new document) or a same-major, minor-`≤` stamp.
 *   * `readOnlyCrossMajor` — the document was authored under a **different major**
 *     version; it may be read/converted but never edited in place.
 *   * `rejectedNewerMinor` — the document is same-major but a **newer minor** than
 *     the object model; an older model must not edit a newer document.
 *   * `invalidVersion` — one of the two versions is not a valid `major.minor`
 *     string: usually the document stamp, but a malformed *generated* version
 *     lands here too. One outcome with two causes; the refusal message thrown by
 *     {@link checkSomModelVersion} is where they separate.
 */
const SomEditability = Object.freeze({
  editable: 'editable',
  readOnlyCrossMajor: 'readOnlyCrossMajor',
  rejectedNewerMinor: 'rejectedNewerMinor',
  invalidVersion: 'invalidVersion',
});

function _tryInt(raw) {
  if (!/^-?[0-9]+$/.test(raw)) {
    return null;
  }
  return parseInt(raw, 10);
}

/** A parsed `major.minor` version pair. */
class _SomVersion {
  constructor(major, minor) {
    this.major = major;
    this.minor = minor;
  }

  static parse(raw) {
    const v = _SomVersion.tryParse(raw);
    if (v === null) {
      throw new SomVersionError(`"${raw}" is not a valid major.minor version`);
    }
    return v;
  }

  static tryParse(raw) {
    const parts = raw.split('.');
    if (parts.length !== 2) {
      return null;
    }
    const major = _tryInt(parts[0]);
    const minor = _tryInt(parts[1]);
    if (major === null || minor === null) {
      return null;
    }
    return new _SomVersion(major, minor);
  }
}

/**
 * Classifies a document's editability under the SOM §4.2 rules **without
 * throwing** (SOM §21). `generated` is the object model's own `major.minor`
 * version; `documentVersion` is the document's recorded authoring stamp
 * (`null`/empty for a brand-new, never-stamped document).
 *
 * This is the single definition of the version rules; {@link checkSomModelVersion}
 * throws based on the value returned here, so the two never diverge.
 *
 * **Total.** Every input pair is classified, including an unparseable
 * `generated` — a classifier a caller must still wrap in `try`/`catch` gives
 * that caller nothing over the throwing check it exists to replace, and the
 * throwing form is not expressible in all nine ports anyway.
 *
 * @param {string} generated
 * @param {string|null} documentVersion
 * @returns {string} a {@link SomEditability} value
 */
function somEditabilityFor(generated, documentVersion) {
  if (!documentVersion) {
    return SomEditability.editable;
  }
  const gen = _SomVersion.tryParse(generated);
  const doc = _SomVersion.tryParse(documentVersion);
  if (gen === null || doc === null) {
    return SomEditability.invalidVersion;
  }
  if (doc.major !== gen.major) {
    return SomEditability.readOnlyCrossMajor;
  }
  if (doc.minor > gen.minor) {
    return SomEditability.rejectedNewerMinor;
  }
  return SomEditability.editable;
}

/**
 * The instantiation-time version check every generated root facade performs
 * (SOM §4.2). `generated` is the object model's own `major.minor` version;
 * `documentVersion` is the document's recorded authoring stamp (`null`/empty
 * for a brand-new, never-stamped document).
 *
 * Rules (see {@link somEditabilityFor}, which this delegates to):
 *   * a `null`/empty document stamp is always accepted — a new document is
 *     stamped on first edit;
 *   * within the **same major** version, a document whose minor is **≤** the
 *     generated minor is editable (older or equal — upgraded on edit); a document
 *     whose minor is **greater** is rejected (an older model must not edit a newer
 *     document);
 *   * a **different major** version is always rejected (cross-major is
 *     read/convert only, never in-place edit).
 *
 * Throws {@link SomVersionError} on any rejection, or when either version is
 * unparseable — with a distinct message for each, since a malformed object model
 * constant is a different fault from a malformed document stamp.
 */
function checkSomModelVersion(generated, documentVersion) {
  switch (somEditabilityFor(generated, documentVersion)) {
    case SomEditability.editable:
      return;
    case SomEditability.invalidVersion:
      // One outcome, two causes — the message is where they separate, so a
      // malformed object-model constant does not masquerade as a bad document.
      if (_SomVersion.tryParse(generated) === null) {
        throw new SomVersionError(
          `"${generated}" is not a valid major.minor version`,
        );
      }
      throw new SomVersionError(
        `document model version "${documentVersion}" is not a valid major.minor`,
      );
    case SomEditability.readOnlyCrossMajor: {
      const gen = _SomVersion.parse(generated);
      const doc = _SomVersion.parse(documentVersion);
      throw new SomVersionError(
        `document major version ${doc.major} differs from the object model ` +
          `major version ${gen.major}; cross-major documents are read-only`,
      );
    }
    case SomEditability.rejectedNewerMinor:
      throw new SomVersionError(
        `document model version ${documentVersion} is newer than the object ` +
          `model version ${generated}; an older object model cannot edit a newer ` +
          'document',
      );
  }
}

module.exports = {
  SomNode,
  SomScalar,
  SomList,
  SomVersionError,
  SomEditability,
  somEditabilityFor,
  checkSomModelVersion,
};
