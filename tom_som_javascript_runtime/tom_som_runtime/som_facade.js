'use strict';

const { generateListItemSectionId } = require('./spec_section_id');

/**
 * The hand-written runtime support for the generated typed object model
 * (`tom_som_javascript_v0`) — a faithful port of
 * `tom_som_dart_runtime/lib/src/som_facade.dart` (and `som_facade.py`).
 *
 * The generated classes are a thin **editing facade** over the generic
 * {@link SpecDocument}: every typed getter/setter reads or writes the path-keyed
 * memory representation directly, so a mutation made through the typed surface is
 * immediately visible through the generic path and vice-versa (§3 — the two
 * access paths share one document). These base types ({@link SomNode},
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
   * Whether this section holds no value at its {@link path} or nested beneath
   * it — the typed-facade view of "is this section filled?", kept in agreement
   * with the generic API by delegating to {@link SpecDocument#hasValuesUnder}
   * (§ item 5). Inherited by every generated section facade — intentional.
   *
   * @returns {boolean}
   */
  get isEmpty() {
    return !this.doc.hasValuesUnder(this.path);
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
    if (this.pattern === null || this.pattern === undefined) {
      return this._factory(this.doc, this.doc.addListItem(this.listPath));
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
    return this._factory(this.doc, this.doc.addListItem(this.listPath, id));
  }

  /** Removes the item at `index` and every value nested beneath it. */
  removeAt(index) {
    this.doc.removeListItem(this.doc.listItems(this.listPath)[index]);
  }
}

/**
 * Raised when a generated object model is instantiated against a document whose
 * authoring model version it must not edit (§2.2).
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
 * The instantiation-time version check every generated root facade performs
 * (§2.2). `generated` is the object model's own `major.minor` version;
 * `documentVersion` is the document's recorded authoring stamp (`null`/empty for
 * a brand-new, never-stamped document).
 *
 * Rules:
 *   * a `null`/empty document stamp is always accepted — a new document is
 *     stamped on first edit;
 *   * within the **same major** version, a document whose minor is **≤** the
 *     generated minor is editable (older or equal — upgraded on edit); a document
 *     whose minor is **greater** is rejected (an older model must not edit a newer
 *     document);
 *   * a **different major** version is always rejected (cross-major is
 *     read/convert only, never in-place edit).
 *
 * Throws {@link SomVersionError} on any rejection or an unparseable stamp.
 */
function checkSomModelVersion(generated, documentVersion) {
  if (!documentVersion) {
    return;
  }
  const gen = _SomVersion.parse(generated);
  const doc = _SomVersion.tryParse(documentVersion);
  if (doc === null) {
    throw new SomVersionError(
      `document model version "${documentVersion}" is not a valid major.minor`,
    );
  }
  if (doc.major !== gen.major) {
    throw new SomVersionError(
      `document major version ${doc.major} differs from the object model ` +
        `major version ${gen.major}; cross-major documents are read-only`,
    );
  }
  if (doc.minor > gen.minor) {
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
  checkSomModelVersion,
};
