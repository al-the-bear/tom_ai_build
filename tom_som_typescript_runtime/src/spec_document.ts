/**
 * A sparse, live instance of a TomSpecs document — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_document.dart` (and the JavaScript
 * `spec_document.js`).
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
 *   * `_headline` — stored headlines (YRD3): path → headline text.
 *
 * List item paths are `"<listPath>-<seq>"` where `seq` is a per-list monotonic
 * counter that never reuses a number.
 *
 * Each list item also carries a **section id** (AA1 criteria 3–6): the
 * document-semantic identity generated from the list field's
 * `@SectionIdPattern`. This is distinct from the internal `-<seq>` path key:
 * the seq path keeps nested values attached across edits (never renumbered),
 * while the section id is what the document exposes and may be overridden
 * ({@link SpecDocument.setItemSectionId}, criterion 5) or reused same-day after
 * the last item is deleted (criterion 6). Section ids live in `_itemSectionId`,
 * keyed by the internal item path.
 */

import { readFileSync } from 'fs';
import {
  SpecSectionIdCollision,
  effectiveListItemSectionId,
} from './spec_section_id';
import { SpecFieldKind, SpecModel, SpecRoot } from './spec_model';
import { SpecReflection } from './spec_reflection';
import {
  SpecDocumentMarkdown,
  SpecMarkdownImport,
} from './spec_document_markdown';
import type {
  SpecMarkdownRendition,
  SpecMarkdownResult,
} from './spec_document_markdown';
import type { SomMetaTree } from './spec_meta';
import { assembleSpecDocuments } from './spec_document_assembly';
import type {
  SpecDocumentAssembly,
  SpecDocumentFragments,
} from './spec_document_assembly';

/** The plain-data shape of a single list store entry. */
export interface ListJson {
  seq: number;
  items: string[];
  ids?: Record<string, string>;
}

/** A {@link SpecDocument.toJson}-shaped plain-data view of a document. */
export interface DocumentJson {
  content?: Record<string, string>;
  forms?: Record<string, Record<string, string>>;
  lists?: Record<string, ListJson>;
  headlines?: Record<string, string>;
  codeSpecs?: Record<string, string>;
}

export class SpecDocument {
  private _content: Map<string, string> = new Map();
  private _form: Map<string, Map<string, string>> = new Map();
  private _listItems: Map<string, string[]> = new Map();
  private _listSeq: Map<string, number> = new Map();
  private _itemSectionId: Map<string, string> = new Map();
  private _headline: Map<string, string> = new Map();

  /**
   * The concrete instance-level forward DocSpecs→CodeSpecs link
   * (codespecs_mapping.md §9.2): any section path → the comma-joined list of
   * CodeSpecs code locations that section maps to. Sparse like `_headline`:
   * unset means "no code mapping".
   */
  private _codeSpec: Map<string, string> = new Map();

  /**
   * The authoring object-model version (`major.minor`) this document was loaded
   * from, or `null` for a brand-new / unstamped document. Retained here by
   * {@link fromYaml} so a consumer need not thread `decoded.modelVersion` to the
   * typed facade by hand (the "forgot the stamp" class of bug); the generated
   * `loadYaml` / `loadFile` statics apply it automatically.
   */
  modelVersion: string | null = null;

  /**
   * Loads a hierarchical v2 `*.docspecs.yaml` document in one call: decode
   * the YAML against the document's {@link SomMetaTree} and return the
   * populated document (with {@link modelVersion} already threaded by the
   * codec). Collapses the former three-step `decode` → `loadJson` →
   * thread-`documentVersion` incantation (SOM §21).
   *
   * The yaml codec is required lazily to sidestep any load-order/circular
   * require between this module and `spec_document_yaml.ts`.
   */
  static fromYaml(yaml: string, tree: SomMetaTree): SpecDocument {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { decode } =
      require('./spec_document_yaml') as typeof import('./spec_document_yaml');
    return decode(yaml, tree).document;
  }

  /**
   * Loads a `*.docspecs.yaml` document from the file at `path` — the file
   * companion to {@link fromYaml} the generated `loadFile` static delegates to.
   */
  static fromFile(path: string, tree: SomMetaTree): SpecDocument {
    return SpecDocument.fromYaml(readFileSync(path, 'utf8'), tree);
  }

  /**
   * Renders this document to Markdown in one call (SOM §21).
   *
   * Collapses the former `new SpecDocumentMarkdown(model, doc).exportRoot(
   * model.roots.find((r) => r.type === …))` incantation. When `rootType` is
   * given, that root is exported (via {@link SpecModel.rootByType}); when
   * omitted, the document's single **populated** root is used — a root is
   * populated when it has any value beneath its segment ({@link hasValuesUnder}).
   * Throws an {@link Error} when the default is ambiguous — zero populated roots,
   * or more than one — so the caller names the `rootType` explicitly.
   */
  toMarkdown(model: SpecModel, rootType?: string): string {
    const root =
      rootType !== undefined && rootType !== null
        ? model.rootByType(rootType)
        : this._singlePopulatedRoot(model);
    return new SpecDocumentMarkdown(model, this).exportRoot(root);
  }

  /**
   * {@link toMarkdown}, plus the document path behind every heading
   * ({@link SpecDocumentMarkdown.exportRootWithMap}). Root selection is the
   * same as {@link toMarkdown}'s.
   */
  toMarkdownWithMap(model: SpecModel, rootType?: string): SpecMarkdownRendition {
    const root =
      rootType !== undefined && rootType !== null
        ? model.rootByType(rootType)
        : this._singlePopulatedRoot(model);
    return new SpecDocumentMarkdown(model, this).exportRootWithMap(root);
  }

  /**
   * The one root under which this document holds any value, for
   * {@link toMarkdown}'s default. Throws when zero or more than one root is
   * populated.
   */
  private _singlePopulatedRoot(model: SpecModel): SpecRoot {
    const populated: SpecRoot[] = [];
    for (const r of model.roots) {
      if (this.hasValuesUnder(r.sectionId !== null ? r.sectionId : r.type)) {
        populated.push(r);
      }
    }
    if (populated.length === 1) {
      return populated[0];
    }
    if (populated.length === 0) {
      throw new Error(
        'document has no populated root to export; pass rootType to choose one',
      );
    }
    throw new Error(
      `document has ${populated.length} populated roots ` +
        `(${populated.map((r) => r.type).join(', ')}); ` +
        'pass rootType to choose one',
    );
  }

  /**
   * Assembles one document from `fragments` — name → document, in order (a
   * `Map` or an iterable of `[name, document]` pairs) — each holding a subset
   * of the sections (`spec_document_assembly.ts`). Refusing: a place two
   * fragments both write is an overlap, and an assembly with any overlap
   * carries no document.
   */
  static assemble(fragments: SpecDocumentFragments): SpecDocumentAssembly {
    return assembleSpecDocuments(fragments);
  }

  /**
   * Loads a SOM-rendered Markdown document (SOM §11.7) into a fresh document
   * in one call: parse, then {@link applyMarkdownResult}.
   *
   * Blocks the parser rejects are not loaded, and are returned with the
   * document, so a caller can show them or refuse to save: re-exporting a
   * document whose source had rejections drops those blocks for good.
   */
  static fromMarkdown(text: string, model: SpecModel): SpecMarkdownImport {
    const document = new SpecDocument();
    const result = new SpecDocumentMarkdown(model, document).parse(text);
    document.applyMarkdownResult(result, true);
    return new SpecMarkdownImport(document, result);
  }

  /**
   * Applies a parsed Markdown import as a **full overwrite** of the roots it
   * covers (SOM §11.7): every value under each of
   * {@link SpecMarkdownResult.rootPrefixes} is removed, then the parsed
   * content, forms, lists, headlines and codeSpecs are written. Other roots are
   * left as they are.
   *
   * A result with rejections is refused with an {@link Error} — and the
   * document left unchanged — unless `allowRejections` is true: the blocks it
   * rejected would otherwise vanish from a document the caller believes it
   * imported whole.
   *
   * Store-agnostic on both halves: the purge goes through
   * {@link removeValuesUnder}, which clears every store, and the carry-over is
   * whatever {@link toJson} emits. This port keys its stores by the raw path
   * (it has no path normalizer), so the parsed paths are written as they are.
   */
  applyMarkdownResult(
    result: SpecMarkdownResult,
    allowRejections = false,
  ): void {
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
    const lists: Record<string, ListJson> = { ...(held.lists || {}) };
    for (const [listPath, spec] of Object.entries(result.lists)) {
      const entry: ListJson = {
        seq: spec.seq,
        items: Array.isArray(spec.items)
          ? spec.items.map((i) => String(i))
          : [],
      };
      if (spec.ids && typeof spec.ids === 'object') {
        const ids: Record<string, string> = {};
        for (const [itemPath, id] of Object.entries(spec.ids)) {
          ids[String(itemPath)] = id;
        }
        entry.ids = ids;
      }
      lists[listPath] = entry;
    }

    this.loadJson({
      content: { ...(held.content || {}), ...result.content },
      forms: { ...(held.forms || {}), ...result.forms },
      lists,
      headlines: { ...(held.headlines || {}), ...result.headlines },
      codeSpecs: { ...(held.codeSpecs || {}), ...result.codeSpecs },
    });
  }

  // --- content ------------------------------------------------------------

  content(path: string): string | null {
    return this._content.has(path) ? (this._content.get(path) as string) : null;
  }

  /**
   * Whether a non-empty content-leaf value exists at *exactly* `path` — the
   * leaf-exact "is this section filled?" test (SOM §21). A value nested beneath
   * `path` does **not** count (that is {@link hasValuesUnder}); this is the
   * null-free companion to {@link content}.
   */
  hasContent(path: string): boolean {
    const v = this._content.has(path) ? (this._content.get(path) as string) : null;
    return v !== null && v.length > 0;
  }

  /** Sets the content string at `path`. An empty value clears it. */
  setContent(path: string, value: string): void {
    if (value === '') {
      this._content.delete(path);
    } else {
      this._content.set(path, value);
    }
  }

  // --- forms --------------------------------------------------------------

  formField(path: string, fieldName: string): string | null {
    const fields = this._form.get(path);
    if (!fields || !fields.has(fieldName)) {
      return null;
    }
    return fields.get(fieldName) as string;
  }

  /**
   * Sets form `fieldName` at `path`. An empty value clears that field (and the
   * whole form entry once its last field is gone).
   */
  setFormField(path: string, fieldName: string, value: string): void {
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

  // --- headlines (YRD3) -----------------------------------------------------

  /**
   * The stored headline at `path`, or `null` when the section renders its
   * derived default title (YRD3).
   */
  headline(path: string): string | null {
    return this._headline.has(path)
      ? (this._headline.get(path) as string)
      : null;
  }

  /** Sets the stored headline at `path`. An empty value clears it. */
  setHeadline(path: string, value: string): void {
    if (value === '') {
      this._headline.delete(path);
    } else {
      this._headline.set(path, value);
    }
  }

  /** Every path with a stored headline. */
  get headlinePaths(): Iterable<string> {
    return this._headline.keys();
  }

  // --- codeSpec (codespecs_mapping.md §9.2)
  // ------------------------------------------------------

  /**
   * The stored codeSpec mapping at `path` as the comma-joined list of
   * CodeSpecs code locations, or `null` when the section carries no mapping
   * (codespecs_mapping.md §9.2 — codeSpec is sparse like the headline).
   */
  codeSpec(path: string): string | null {
    return this._codeSpec.has(path)
      ? (this._codeSpec.get(path) as string)
      : null;
  }

  /**
   * Sets the stored codeSpec mapping at `path` (the comma-joined list of
   * CodeSpecs code locations). An empty value clears it, returning the section
   * to "no code mapping" (codespecs_mapping.md §9.2).
   */
  setCodeSpec(path: string, value: string): void {
    if (value === '') {
      this._codeSpec.delete(path);
    } else {
      this._codeSpec.set(path, value);
    }
  }

  /** Every path with a stored codeSpec mapping. */
  get codeSpecPaths(): Iterable<string> {
    return this._codeSpec.keys();
  }

  // --- lists --------------------------------------------------------------

  listItems(listPath: string): string[] {
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
   */
  addListItem(listPath: string, sectionId: string | null = null): string {
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
   */
  itemSectionId(itemPath: string): string | null {
    return this._itemSectionId.has(itemPath)
      ? (this._itemSectionId.get(itemPath) as string)
      : null;
  }

  /**
   * Overrides the section id of the list item at `itemPath` (AA1 criterion 5).
   *
   * Validates that the new `id` is unique among the *other* items of the same
   * owning list; a collision throws {@link SpecSectionIdCollision}. Assigning
   * an id equal to the item's current id is a no-op. Throws if `itemPath` is
   * not a live list item.
   */
  setItemSectionId(itemPath: string, id: string): void {
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
   */
  listItemSectionIds(listPath: string): string[] {
    const items = this._listItems.get(listPath) || [];
    const out: string[] = [];
    for (const itemPath of items) {
      if (this._itemSectionId.has(itemPath)) {
        out.push(this._itemSectionId.get(itemPath) as string);
      }
    }
    return out;
  }

  /** The internal `_listItems` entry that owns `itemPath`, or `null`. */
  private _owningListOf(itemPath: string): string | null {
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
   */
  private _assertSectionIdFree(
    listPath: string,
    id: string,
    exceptItemPath: string | null,
  ): void {
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
   */
  moveListItem(
    model: SpecModel,
    itemPath: string,
    toIndex: number,
    toList: string | null = null,
  ): SpecListItemMove {
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
      ? (this._itemSectionId.get(item) as string)
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
    const fromOld = this._listItems.get(from) as string[];
    const fromItems = fromOld.filter((p) => p !== item);
    const toItems =
      to === from ? fromItems : (this._listItems.get(to) || []).slice();
    if (!Number.isInteger(toIndex) || toIndex < 0 || toIndex > toItems.length) {
      throw new RangeError(
        `toIndex ${toIndex} is not in the range 0..${toItems.length}`,
      );
    }
    toItems.splice(toIndex, 0, item);

    const fieldOf = (list: string) => (list === from ? fromField : toField);
    const stemOf = (list: string): string => {
      const field = fieldOf(list);
      return field ? field.name : list.split('/').pop() as string;
    };

    // Each affected item's effective id before the move, so an anonymous
    // item keeps its identity when its position changes.
    const before = new Map<string, string>();
    const record = (list: string, items: string[]): void => {
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
    const renamed = new Map<string, string>();
    const pinned = new Map<string, string>();
    const renumber = (list: string, items: string[]): void => {
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
        const was = before.get(old) as string;
        if (positional !== was) pinned.set(old, was);
      });
    };
    renumber(from, fromItems);
    if (to !== from) renumber(to, toItems);

    const remap = (key: string): string => _remapUnder(key, renamed);
    const rekey = <V>(store: Map<string, V>): Map<string, V> => {
      const out = new Map<string, V>();
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
    const lists = new Map<string, string[]>();
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

    const pinnedIds = new Map<string, string>();
    for (const [old, id] of pinned) pinnedIds.set(remap(old), id);
    return new SpecListItemMove(remap(item), renamed, pinnedIds);
  }

  /**
   * Removes the list item at `itemPath` along with every value nested beneath it.
   * The counter is left untouched so future items keep getting fresh sequence
   * numbers (no renumbering).
   */
  removeListItem(itemPath: string): boolean {
    let owningList: string | null = null;
    for (const [key, items] of this._listItems) {
      if (items.includes(itemPath)) {
        owningList = key;
        break;
      }
    }
    if (owningList === null) {
      return false;
    }
    const items = this._listItems.get(owningList) as string[];
    const at = items.indexOf(itemPath);
    items.splice(at, 1);
    if (items.length === 0) {
      this._listItems.delete(owningList);
    }
    this._purgeUnder(itemPath);
    return true;
  }

  private _purgeUnder(prefix: string): void {
    const isUnder = (key: string): boolean =>
      key === prefix ||
      key.startsWith(`${prefix}/`) ||
      key.startsWith(`${prefix}-`);
    const stores: Map<string, unknown>[] = [
      this._content,
      this._form,
      this._listItems,
      this._listSeq,
      this._itemSectionId,
      this._headline,
      this._codeSpec,
    ];
    for (const store of stores) {
      for (const key of Array.from(store.keys())) {
        if (isUnder(key)) {
          store.delete(key);
        }
      }
    }
  }

  /**
   * Drops every value at `prefix` or nested beneath it — content, form entries,
   * list items (with their nested values, ids and counters), and stored
   * headlines (YRD7 generic modification API: "clear section").
   *
   * The predicate is the same one {@link hasValuesUnder} uses, so after this
   * call `hasValuesUnder(prefix)` is `false`. Note this clears *values under a
   * section path*; removing a single list item from its owning list is
   * {@link removeListItem}.
   */
  removeValuesUnder(prefix: string): void {
    this._purgeUnder(prefix);
  }

  // --- queries ------------------------------------------------------------

  get isEmpty(): boolean {
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
  hasValuesUnder(prefix: string): boolean {
    const isUnder = (key: string): boolean =>
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

  get contentPaths(): Iterable<string> {
    return this._content.keys();
  }

  get formPaths(): Iterable<string> {
    return this._form.keys();
  }

  get listPaths(): Iterable<string> {
    return this._listItems.keys();
  }

  formFieldNames(path: string): Iterable<string> {
    const fields = this._form.get(path);
    return fields ? fields.keys() : [];
  }

  listItemCount(listPath: string): number {
    const items = this._listItems.get(listPath);
    return items ? items.length : 0;
  }

  // --- persistence --------------------------------------------------------

  /**
   * A plain-data view of every value held, for persistence. Only non-empty
   * stores are included, and each is sorted by full section-ID path so the saved
   * file diffs/merges cleanly. The inverse of {@link loadJson}.
   */
  toJson(): DocumentJson {
    const out: DocumentJson = {};
    if (this._content.size > 0) {
      const content: Record<string, string> = {};
      for (const k of Array.from(this._content.keys()).sort()) {
        content[k] = this._content.get(k) as string;
      }
      out.content = content;
    }
    if (this._form.size > 0) {
      const forms: Record<string, Record<string, string>> = {};
      for (const k of Array.from(this._form.keys()).sort()) {
        const fields = this._form.get(k) as Map<string, string>;
        const entry: Record<string, string> = {};
        for (const f of Array.from(fields.keys()).sort()) {
          entry[f] = fields.get(f) as string;
        }
        forms[k] = entry;
      }
      out.forms = forms;
    }
    if (this._listItems.size > 0) {
      const lists: Record<string, ListJson> = {};
      for (const k of Array.from(this._listItems.keys()).sort()) {
        const items = this._listItems.get(k) as string[];
        const entry: ListJson = {
          seq: this._listSeq.has(k)
            ? (this._listSeq.get(k) as number)
            : items.length,
          items: items.slice(),
        };
        const ids: Record<string, string> = {};
        let hasIds = false;
        for (const itemPath of items) {
          if (this._itemSectionId.has(itemPath)) {
            ids[itemPath] = this._itemSectionId.get(itemPath) as string;
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
      const headlines: Record<string, string> = {};
      for (const k of Array.from(this._headline.keys()).sort()) {
        headlines[k] = this._headline.get(k) as string;
      }
      out.headlines = headlines;
    }
    if (this._codeSpec.size > 0) {
      const codeSpecs: Record<string, string> = {};
      for (const k of Array.from(this._codeSpec.keys()).sort()) {
        codeSpecs[k] = this._codeSpec.get(k) as string;
      }
      out.codeSpecs = codeSpecs;
    }
    return out;
  }

  /**
   * Replaces every store from a {@link toJson}-shaped object. Coerces leaf
   * values to strings and skips unknown/empty entries.
   */
  loadJson(json: any): void {
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
          const entry = new Map<string, string>();
          for (const [f, v] of Object.entries(fields as Record<string, unknown>)) {
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
      for (const [k, spec] of Object.entries(lists as Record<string, any>)) {
        if (spec && typeof spec === 'object') {
          const items = spec.items;
          const itemList: string[] = Array.isArray(items)
            ? items.map((it: unknown) => String(it))
            : [];
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
            for (const [itemPath, id] of Object.entries(
              ids as Record<string, unknown>,
            )) {
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
export class SpecListItemMove {
  /** The moved item's path after the move. */
  readonly path: string;

  /**
   * Every item path the move changed, old → new: the moved item and each
   * sibling whose position moved. Values under a renamed item moved with it.
   */
  readonly renamed: ReadonlyMap<string, string>;

  /**
   * The items (by new path) that were anonymous and now store the id they had
   * by position, so their identity did not change with their position.
   */
  readonly pinnedIds: ReadonlyMap<string, string>;

  constructor(
    path: string,
    renamed: ReadonlyMap<string, string> = new Map(),
    pinnedIds: ReadonlyMap<string, string> = new Map(),
  ) {
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
 */
export function _remapUnder(
  key: string,
  renamed: ReadonlyMap<string, string>,
): string {
  for (const [old, now] of renamed) {
    if (key === old) return now;
    if (key.startsWith(`${old}/`) || key.startsWith(`${old}-`)) {
      return now + key.substring(old.length);
    }
  }
  return key;
}

/** Whether `id` fits `pattern`, its `xxx` slot standing for any non-empty run. */
function _sectionIdFitsPattern(pattern: string, id: string): boolean {
  const escape = (s: string): string =>
    s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(
    `^${pattern.split('xxx').map(escape).join('.+')}$`,
  ).test(id);
}

/** Replaces the entries of `target` with those of `source`, in order. */
function _replaceWith<V>(target: Map<string, V>, source: Map<string, V>): void {
  target.clear();
  for (const [k, v] of source) target.set(k, v);
}
