/**
 * The hand-written runtime support for the generated typed object model
 * (`tom_som_typescript_v0`) — a faithful port of
 * `tom_som_dart_runtime/lib/src/som_facade.dart` (and the JavaScript
 * `som_facade.js`).
 *
 * The generated classes are a thin **editing facade** over the generic
 * {@link SpecDocument}: every typed getter/setter reads or writes the path-keyed
 * memory representation directly, so a mutation made through the typed surface is
 * immediately visible through the generic path and vice-versa (§3 — the two
 * access paths share one document). These base types ({@link SomNode},
 * {@link SomList}, {@link SomScalar}) hold no state of their own beyond the
 * document and a path; the generated subclasses only add typed accessors.
 */

import { SpecDocument } from './spec_document';
import { generateListItemSectionId } from './spec_section_id';

/**
 * The base class every generated typed facade class extends.
 *
 * It binds a facade instance to the {@link SpecDocument} it edits and the `path`
 * it lives at (the globally-unique section path, per `spec_paths`). The generated
 * subclass adds typed field accessors that delegate to `doc` at paths derived
 * from `path`.
 */
export class SomNode {
  doc: SpecDocument;
  path: string;

  constructor(doc: SpecDocument, path: string) {
    this.doc = doc;
    this.path = path;
  }

  /**
   * This node's section id when it is a list item (AA1 criterion 1 read), or
   * `null` for non-list nodes (roots, complex/section children — their id is
   * the fixed `@SectionId` already embedded in {@link path}).
   *
   * Named `$sectionId` — a name the TypeScript emitter never produces for a
   * model field accessor (the emitter's identifier sanitiser only appends `_`
   * for keywords/base members and never prefixes `$`) — so this structural
   * accessor can never collide with a typed field a generated subclass emits
   * (mirrors the Dart `$sectionId` collision-proofing, decision AE-D1).
   */
  get $sectionId(): string | null {
    return this.doc.itemSectionId(this.path);
  }

  /**
   * Whether this section holds no value at its path or nested beneath it — the
   * structural "empty = no value" test (§ item 5), delegating to
   * {@link SpecDocument.hasValuesUnder}. Inherited by every generated section
   * facade (intentional).
   */
  get isEmpty(): boolean {
    return !this.doc.hasValuesUnder(this.path);
  }

  /**
   * Whether this section **type** declares the standard `content` text leaf —
   * i.e. whether the `.content` getter/setter exists on it (§ item 10).
   *
   * This is a **structural / schema** predicate: a compile-time constant of the
   * section's type, answering "*can* this section hold body text?" without a
   * probe of `.content`. Container-only sections (e.g. `SystemsToReplace`,
   * which has no `content` leaf) inherit this `false` default; content-bearing
   * sections (e.g. `Goals`) override it to `true`.
   *
   * It is deliberately distinct from the two **state** predicates: the generic
   * {@link SpecDocument.hasContent} answers "is a value present at this leaf
   * *now*?" and {@link isEmpty} answers "is this subtree empty *now*?".
   * `canHaveContent` never looks at the document — it describes the model, not
   * the data.
   */
  get canHaveContent(): boolean {
    return false;
  }

  /**
   * Overrides this list item's section id (AA1 criterion 5): an arbitrary
   * suffix, validated unique within the owning list. Throws
   * {@link SpecSectionIdCollision} on a duplicate, or an `Error` if this node is
   * not a live list item. Assigning `null`/`undefined` is a no-op.
   */
  set $sectionId(id: string | null) {
    if (id === null || id === undefined) {
      return;
    }
    this.doc.setItemSectionId(this.path, id);
  }
}

/**
 * A scalar list item — a bare string value held in the document's content store
 * at its own item `path`. Used as the element facade for non-complex
 * (`string`/scalar) lists.
 */
export class SomScalar extends SomNode {
  /** The string value at this item's path (`''` when unset). */
  get value(): string {
    return this.doc.content(this.path) || '';
  }

  /** Sets the string value (an empty string clears it, per {@link SpecDocument}). */
  set value(v: string) {
    this.doc.setContent(this.path, v);
  }
}

/**
 * A typed view over a list field, layered over the document's list store.
 *
 * Items are addressed by their stable item paths
 * ({@link SpecDocument.listItems}); each is wrapped in an element facade by
 * `factory`. The wrapper holds no items itself — every operation reads through
 * the live document, so it always reflects the current state.
 */
export class SomList<T> {
  doc: SpecDocument;
  listPath: string;
  /**
   * The list field's `@SectionIdPattern` (e.g. `DACEN-ITEM-xxx`), or `null` for
   * a pattern-less (scalar) list. Drives section-id generation on {@link add}
   * (AA1 criteria 3–5).
   */
  pattern: string | null;
  private _factory: (doc: SpecDocument, path: string) => T;

  constructor(
    doc: SpecDocument,
    listPath: string,
    factory: (doc: SpecDocument, path: string) => T,
    pattern: string | null = null,
  ) {
    this.doc = doc;
    this.listPath = listPath;
    this._factory = factory;
    this.pattern = pattern;
  }

  /** The number of items currently in the list. */
  get length(): number {
    return this.doc.listItemCount(this.listPath);
  }

  /** The element facades for every item, in order. */
  get items(): T[] {
    return this.doc
      .listItems(this.listPath)
      .map((p) => this._factory(this.doc, p));
  }

  /** The element facade for the item at `index`. */
  at(index: number): T {
    return this._factory(this.doc, this.doc.listItems(this.listPath)[index]);
  }

  /** The section ids currently assigned within this list, in item order. */
  get sectionIds(): string[] {
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
   */
  add(sectionId: string | null = null, date: Date | null = null): T {
    return this._factory(this.doc, this._addItemPath(sectionId, date));
  }

  /**
   * Appends a content-only item and sets its content leaf in one call, then
   * returns the item's element facade.
   *
   * The section-id logic is identical to {@link add} (`sectionId`/`date` honour
   * the list {@link pattern}, AA1 criteria 3–5); `content` is written to the
   * item's **nested `<itemPath>/content` leaf**. Scalar (pattern-less) lists
   * still target that nested leaf — they are out of scope for this convenience.
   */
  addContent(
    content: string,
    sectionId: string | null = null,
    date: Date | null = null,
  ): T {
    const itemPath = this._addItemPath(sectionId, date);
    this.doc.setContent(`${itemPath}/content`, content); // nested <item>/content leaf
    return this._factory(this.doc, itemPath);
  }

  /**
   * An ordered, read-only view of every item's nested `<itemPath>/content` leaf,
   * coalescing a missing/unset leaf to `''`. Companion read to
   * {@link addContent}; scalar (pattern-less) lists are out of scope.
   */
  get contents(): string[] {
    return this.doc
      .listItems(this.listPath)
      .map((p) => this.doc.content(`${p}/content`) || '');
  }

  /**
   * Appends a new item and returns its stable item path, deriving the section id
   * exactly as {@link add}/{@link addContent} do: a pattern-less list appends
   * plainly, otherwise `sectionId` (an override) is used or one is generated
   * from the {@link pattern} using `date` (defaulting to today).
   */
  private _addItemPath(
    sectionId: string | null = null,
    date: Date | null = null,
  ): string {
    if (this.pattern === null || this.pattern === undefined) {
      return this.doc.addListItem(this.listPath);
    }
    let id: string;
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
  removeAt(index: number): void {
    this.doc.removeListItem(this.doc.listItems(this.listPath)[index]);
  }
}

/**
 * Raised when a generated object model is instantiated against a document whose
 * authoring model version it must not edit (§2.2).
 */
export class SomVersionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SomVersionError';
    this.message = message;
    // Restore the prototype chain across the ES5 `Error` boundary.
    Object.setPrototypeOf(this, SomVersionError.prototype);
  }

  toString(): string {
    return `SomVersionError: ${this.message}`;
  }
}

function _tryInt(raw: string): number | null {
  if (!/^-?[0-9]+$/.test(raw)) {
    return null;
  }
  return parseInt(raw, 10);
}

/** A parsed `major.minor` version pair. */
class _SomVersion {
  major: number;
  minor: number;

  constructor(major: number, minor: number) {
    this.major = major;
    this.minor = minor;
  }

  static parse(raw: string): _SomVersion {
    const v = _SomVersion.tryParse(raw);
    if (v === null) {
      throw new SomVersionError(`"${raw}" is not a valid major.minor version`);
    }
    return v;
  }

  static tryParse(raw: string): _SomVersion | null {
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
 * The outcome of the §2.2 version check, as a value a read-only viewer can
 * branch on instead of catching {@link SomVersionError} (§ item 8).
 *
 * It is the non-throwing companion to {@link checkSomModelVersion}: the
 * constructor throws on any value other than {@link SomEditability.editable},
 * while {@link somEditabilityFor} returns the same classification without
 * throwing so a consumer can decide *open for edit* vs *open read-only* up front.
 */
export enum SomEditability {
  /**
   * The object model may edit the document in place — a `null`/empty stamp
   * (a brand-new document) or a same-major, minor-`≤` stamp.
   */
  editable = 'editable',

  /**
   * The document was authored under a **different major** version; it may be
   * read/converted but never edited in place.
   */
  readOnlyCrossMajor = 'readOnlyCrossMajor',

  /**
   * The document is same-major but a **newer minor** than the object model; an
   * older model must not edit a newer document.
   */
  rejectedNewerMinor = 'rejectedNewerMinor',

  /** The document stamp is not a valid `major.minor` string. */
  invalidVersion = 'invalidVersion',
}

/**
 * Classifies a document's editability under the §2.2 rules **without throwing**
 * (§ item 8). `generated` is the object model's own `major.minor` version;
 * `documentVersion` is the document's recorded authoring stamp (`null`/empty for
 * a brand-new, never-stamped document).
 *
 * This is the single definition of the version rules; {@link checkSomModelVersion}
 * throws based on the value returned here, so the two never diverge.
 */
export function somEditabilityFor(
  generated: string,
  documentVersion: string | null | undefined,
): SomEditability {
  if (!documentVersion) {
    return SomEditability.editable;
  }
  const gen = _SomVersion.parse(generated);
  const doc = _SomVersion.tryParse(documentVersion);
  if (doc === null) {
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
 * (§2.2). `generated` is the object model's own `major.minor` version;
 * `documentVersion` is the document's recorded authoring stamp (`null`/empty for
 * a brand-new, never-stamped document).
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
 * Throws {@link SomVersionError} on any rejection or an unparseable stamp.
 */
export function checkSomModelVersion(
  generated: string,
  documentVersion: string | null | undefined,
): void {
  switch (somEditabilityFor(generated, documentVersion)) {
    case SomEditability.editable:
      return;
    case SomEditability.invalidVersion:
      throw new SomVersionError(
        `document model version "${documentVersion}" is not a valid major.minor`,
      );
    case SomEditability.readOnlyCrossMajor: {
      const gen = _SomVersion.parse(generated);
      const doc = _SomVersion.parse(documentVersion as string);
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
