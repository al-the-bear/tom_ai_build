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
import { SpecSectionIdCollision } from './spec_section_id';
import { SpecModel, SpecRoot } from './spec_model';
import { SpecDocumentMarkdown } from './spec_document_markdown';
import type { SomMetaTree } from './spec_meta';

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
}

export class SpecDocument {
  private _content: Map<string, string> = new Map();
  private _form: Map<string, Map<string, string>> = new Map();
  private _listItems: Map<string, string[]> = new Map();
  private _listSeq: Map<string, number> = new Map();
  private _itemSectionId: Map<string, string> = new Map();
  private _headline: Map<string, string> = new Map();

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
   * thread-`documentVersion` incantation (§ item 4).
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
   * Renders this document to Markdown in one call (§ item 12).
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

  // --- content ------------------------------------------------------------

  content(path: string): string | null {
    return this._content.has(path) ? (this._content.get(path) as string) : null;
  }

  /**
   * Whether a non-empty content-leaf value exists at *exactly* `path` — the
   * leaf-exact "is this section filled?" test (§ item 5). A value nested beneath
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
    ];
    for (const store of stores) {
      for (const key of Array.from(store.keys())) {
        if (isUnder(key)) {
          store.delete(key);
        }
      }
    }
  }

  // --- queries ------------------------------------------------------------

  get isEmpty(): boolean {
    return (
      this._content.size === 0 &&
      this._form.size === 0 &&
      this._listItems.size === 0 &&
      this._headline.size === 0
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
  }
}
