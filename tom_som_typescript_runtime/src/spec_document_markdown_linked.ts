/**
 * Navigation between linked places of a rendition (SOM §11.2 qualified
 * anchors, SOM §11.11 the `linked` marker) — a port of
 * `tom_som_dart_runtime/lib/src/spec_document_markdown_linked.dart`.
 *
 * Both are written from the model and the document's own values, and nothing
 * of either is stored: the parser removes the anchors and the marker.
 *
 * Internal to {@link SpecDocumentMarkdown}.
 *
 * @internal
 */

import type { SpecDocument } from './spec_document';
import type { SpecDocumentMarkdown } from './spec_document_markdown';
import {
  specExpandPattern,
  specResolveLinkPlace,
  specResolvePlaceAt,
} from './spec_links_validator';
import { SomMetaKind, type SomMetaNode, type SomMetaTree } from './spec_meta';
import type {
  FormFieldSpec,
  SpecModel,
  SpecRoot,
  SpecSummaryOf,
  SpecSync,
} from './spec_model';
import { scanNotation } from './spec_notation';
import { splitListItemSegment } from './spec_paths';
import { SpecPlaceFilter, specSameAsBindings, type SpecSameAsBinding } from './spec_place';
import { SpecReflection } from './spec_reflection';
import { effectiveListItemSectionId } from './spec_section_id';

/**
 * Written by the emitter where a markable place has no entry: replaced by
 * `[]{.linked}` when the value written after it begins with a `linked` span,
 * else removed with its blank line (SOM §11.11).
 */
export const _kLinkedPlaceholder = '\u0000linked\u0000';

/**
 * The anchor of a heading `id` and the scope its descendants are qualified
 * with (SOM §11.2): below a list item, and below a `@SameAs` copy, a heading's
 * anchor is the `/`-joined ids from the outermost item (or from the copy's
 * nearest enclosing section) down to it, list containers left out of the
 * descendants' anchors. `scope` is the parent's scope, `section` the id of
 * the nearest heading above that is no list container.
 */
export function _qualifyAnchor(
  scope: string[] | null,
  section: string | null,
  id: string,
  opts: { container?: boolean; item?: boolean; copy?: boolean } = {},
): [string, string[] | null] {
  const joined = (s: string[] | null): string =>
    s === null ? id : [...s, id].join('/');
  if (opts.container === true) return [joined(scope), scope];
  if (opts.item === true) return [joined(scope), [...(scope ?? []), id]];
  if (opts.copy === true) {
    const s = [...(scope ?? (section === null ? [] : [section])), id];
    return [s.join('/'), s];
  }
  return [joined(scope), scope === null ? null : [...scope, id]];
}

/** Where a path lands in a root's tree: the heading at or above it. */
export interface _Walk {
  /** The anchor of the heading at or above the path. */
  anchor: string;
  /** That heading's section id. */
  headingId: string;
  /** That heading's path (the path itself when it has a heading). */
  headingPath: string;
  /** The path with every list item written `<list>-*`. */
  pattern: string;
  /** The ids of the list items on the way, in order. */
  itemIds: string[];
  /** The node the whole path reaches, or null when it reaches none. */
  node: SomMetaNode | null;
}

/** One `@SyncedWith` pair side. */
export interface _Side {
  mine: string;
  other: SpecRoot;
  theirs: string;
  holder: boolean;
  sync: SpecSync;
}

/** One root's navigation: anchors, markable places and marker entries. */
export class _Navigation {
  readonly codec: SpecDocumentMarkdown;
  readonly root: SpecRoot;
  readonly refl: SpecReflection;
  readonly tree: SomMetaTree;

  constructor(codec: SpecDocumentMarkdown, root: SpecRoot) {
    this.codec = codec;
    this.root = root;
    this.refl = new SpecReflection(codec.model);
    this.tree = codec._treeFor(root.type);
  }

  get model(): SpecModel {
    return this.codec.model;
  }

  get doc(): SpecDocument {
    return this.codec.document;
  }

  get rootSeg(): string {
    return this.refl.rootSegment(this.root);
  }

  // --- anchors -------------------------------------------------------------

  private _walks = new Map<string, _Walk>();

  /** Whether `node` is a `@SameAs` copy (its member carries the annotation). */
  isCopy(node: SomMetaNode): boolean {
    return this.codec._isCopyNode(node);
  }

  /** The heading id of the item at `itemPath` of `listNode` in `d`, as the
   *  emitter writes it. */
  itemId(d: SpecDocument | null, listNode: SomMetaNode, itemPath: string): string {
    const split = splitListItemSegment(itemPath.split('/').pop()!)!;
    const listPath =
      itemPath.substring(0, itemPath.lastIndexOf('/') + 1) + split.base;
    const pos = d === null ? 0 : d.listItems(listPath).indexOf(itemPath) + 1;
    return effectiveListItemSectionId(
      d === null ? null : d.itemSectionId(itemPath),
      listNode.sectionIdPattern ?? listNode.elementNode?.sectionIdPattern ?? null,
      pos === 0 ? split.seq : pos,
      listNode.memberName ?? listNode.segment,
    );
  }

  /**
   * Walks `path` (concrete, or a pattern whose `<list>-*` segments take
   * `ids` in order) through `inTree`, the items' ids read from `d`.
   */
  walk(
    path: string,
    opts: { inTree?: SomMetaTree; d?: SpecDocument | null; ids?: string[] } = {},
  ): _Walk {
    const t = opts.inTree ?? this.tree;
    const d = opts.d ?? null;
    const ids = opts.ids ?? [];
    const cacheable = opts.inTree === undefined && ids.length === 0 && d === this.doc;
    if (cacheable) {
      const hit = this._walks.get(path);
      if (hit !== undefined) return hit;
    }
    const queue = [...ids];
    const segs = path.split('/');
    let node = t.root;
    let cur = segs[0];
    let pattern = segs[0];
    let anchor = node.segment;
    let headingId = node.segment;
    let headingPath = cur;
    let scope: string[] | null = null;
    let section: string | null = node.segment;
    const itemIds: string[] = [];
    let reached: SomMetaNode | null = node;
    for (let i = 1; i < segs.length; i++) {
      const seg = segs[i];
      const child = node.childBySegment(seg);
      if (child !== null) {
        cur = `${cur}/${seg}`;
        pattern = `${pattern}/${seg}`;
        node = child;
        reached = child;
        if (
          this.codec._isTransparentSection(child) ||
          (this.codec.constructor as typeof SpecDocumentMarkdown)._isTransparentValue(child)
        ) {
          continue;
        }
        const id = this.codec._headingIdOf(child);
        const container = child.kind === SomMetaKind.LIST;
        const [a, s] = _qualifyAnchor(scope, section, id, {
          container,
          copy: !container && this.isCopy(child),
        });
        anchor = a;
        scope = s;
        headingId = id;
        headingPath = cur;
        if (!container) section = id;
        continue;
      }
      const star = seg.endsWith('-*');
      const base = star
        ? seg.substring(0, seg.length - 2)
        : (splitListItemSegment(seg)?.base ?? null);
      const listNode = base === null ? null : node.childBySegment(base);
      if (listNode === null || listNode.kind !== SomMetaKind.LIST) {
        reached = null;
        break;
      }
      const itemPath = `${cur}/${seg}`;
      const id = star
        ? queue.length === 0
          ? ''
          : queue.shift()!
        : this.itemId(d, listNode, itemPath);
      itemIds.push(id);
      const [a, s] = _qualifyAnchor(scope, section, id, { item: true });
      anchor = a;
      scope = s;
      headingId = id;
      section = id;
      cur = itemPath;
      headingPath = itemPath;
      pattern = `${pattern}/${base}-*`;
      const element = listNode.elementNode ?? null;
      node = element ?? listNode;
      reached = node;
      if (element === null && i < segs.length - 1) {
        reached = null;
        break;
      }
    }
    const w: _Walk = {
      anchor,
      headingId,
      headingPath,
      pattern,
      itemIds,
      node: reached,
    };
    if (cacheable) this._walks.set(path, w);
    return w;
  }

  /** The anchor of the heading `path` names in this document. */
  anchorOf(path: string): string {
    return this.walk(path, { d: this.doc }).anchor;
  }

  /** `path` cut before its first `<list>-*` segment, that list's path. */
  static cutPattern(path: string): string {
    const i = path.indexOf('-*');
    return i < 0 ? path : path.substring(0, i);
  }

  // --- the model's links, per root -----------------------------------------

  private _sides: _Side[] | null = null;

  /**
   * Every `@SyncedWith` pair this root is a side of: its anchor here, the
   * other root, the anchor there, whether this side holds the values, the
   * sync.
   */
  get sides(): _Side[] {
    if (this._sides !== null) return this._sides;
    const out: _Side[] = [];
    this._sides = out;
    const [bp, pairs] = this.codec._syncPairs;
    if (bp === null) return out;
    const rootOf = (type: string): SpecRoot | null =>
      this.model.roots.find((r) => r.type === type) ?? null;
    for (const p of pairs) {
      const sync = p.sync;
      if (sync === null) continue;
      if (this.root.type === bp) {
        const other = rootOf(p.detailRoot);
        if (other === null) continue;
        out.push({
          mine: p.blueprintAnchor,
          other,
          theirs: p.detailAnchor,
          holder: false,
          sync,
        });
      } else if (this.root.type === p.detailRoot) {
        const other = rootOf(bp);
        if (other === null) continue;
        out.push({
          mine: p.detailAnchor,
          other,
          theirs: p.blueprintAnchor,
          holder: true,
          sync,
        });
      }
    }
    return out;
  }

  private _sameAs: SpecSameAsBinding[] | null = null;

  /** The `@SameAs` copies of this root with their holders. */
  get sameAs(): SpecSameAsBinding[] {
    if (this._sameAs === null) {
      this._sameAs = specSameAsBindings(this.refl, this.root.type);
    }
    return this._sameAs;
  }

  private _underCopy(pattern: string): boolean {
    return this.sameAs.some(
      (b) => pattern === b.copyPath || pattern.startsWith(`${b.copyPath}/`),
    );
  }

  /**
   * The side whose shared list `listPattern` is: the innermost pair anchor
   * holding it, when the list lies directly beneath it (not below an item of
   * it), outside a copy and outside the pair's `detailOnly` places.
   */
  sharedListSide(listPattern: string, concreteList: string): _Side | null {
    if (this._underCopy(listPattern)) return null;
    let best: _Side | null = null;
    for (const s of this.sides) {
      if (!listPattern.startsWith(`${s.mine}/`)) continue;
      if (best === null || s.mine.length > best.mine.length) best = s;
    }
    if (best === null) return null;
    const rel = listPattern.substring(best.mine.length + 1);
    if (rel.includes('-*')) return null;
    // The anchor's concrete path: the list's as long as the anchor is.
    const depth = best.mine.split('/').length;
    const anchor = concreteList.split('/').slice(0, depth).join('/');
    for (const place of best.sync.detailOnly) {
      const r = specResolvePlaceAt(this.refl, place, anchor);
      if (r === null) continue;
      const p = this.walk(r.path, { d: this.doc }).pattern;
      if (listPattern === p || listPattern.startsWith(`${p}/`)) return null;
    }
    return best;
  }

  /** The `@SummaryOf` of the list member at `listPath`, if any. */
  summaryOfList(listPath: string): SpecSummaryOf | null {
    return this.refl.resolve(listPath)?.field?.summaryOf ?? null;
  }

  /** Whether a summary names its detail elements in this document. */
  private _sameDocument(s: SpecSummaryOf): boolean {
    return s.document === null || s.document === this.root.type;
  }

  private _detailLists: Map<string, string[]> | null = null;

  /** Detail-list pattern → the summary lists (patterns) of this document
   *  naming its elements. */
  get detailLists(): Map<string, string[]> {
    if (this._detailLists !== null) return this._detailLists;
    const out = new Map<string, string[]>();
    for (const n of this.tree.allNodes) {
      const np = n.path;
      if (n.kind !== SomMetaKind.LIST || np === null) continue;
      const s = this.summaryOfList(np);
      if (s === null || !this._sameDocument(s)) continue;
      const owner = np.substring(0, np.lastIndexOf('/'));
      const r = specResolveLinkPlace(this.refl, null, s.detail, this.rootSeg, owner);
      if (r === null) continue;
      const key = this.walk(_Navigation.cutPattern(r.path), { d: this.doc }).pattern;
      let l = out.get(key);
      if (l === undefined) {
        l = [];
        out.set(key, l);
      }
      l.push(np);
    }
    this._detailLists = out;
    return out;
  }

  // --- markable places (structural: the parser and the emitter agree) -----

  private _markable = new Map<string, boolean>();

  /**
   * Whether the heading at `path` carries one of the links of SOM §11.11:
   * a `@SyncedWith` anchor or an element of one of its shared lists, an
   * element of a summary list or of a detail list a summary of this
   * document names, a heading holding a derived value, a list of link rows
   * extracted from text, a `@SameAs` copy or its holder.
   */
  markable(path: string): boolean {
    let v = this._markable.get(path);
    if (v === undefined) {
      v = this._computeMarkable(path);
      this._markable.set(path, v);
    }
    return v;
  }

  private _computeMarkable(path: string): boolean {
    const w = this.walk(path, { d: this.doc });
    const node = w.node;
    if (node === null || w.headingPath !== path) return false;
    const pattern = w.pattern;
    if (this.sides.some((s) => s.mine === pattern)) return true;
    const item = this._itemParts(path);
    if (item !== null) {
      const listPattern = _Navigation._listPatternOf(pattern);
      if (this.sharedListSide(listPattern, item[0]) !== null) return true;
      if (this.summaryOfList(item[0]) !== null) return true;
      if (this.detailLists.has(listPattern)) return true;
    }
    if (this._derivedSources(path, node, { probe: true }).length > 0) return true;
    if (node.kind === SomMetaKind.LIST && this._extractFrom(path).length > 0) {
      return true;
    }
    if (this.sameAs.some((b) => b.copyPath === pattern || b.holderPath === pattern)) {
      return true;
    }
    return false;
  }

  /** For an item path, [its list's path, its segment]; null otherwise. */
  _itemParts(path: string): [string, string] | null {
    const slash = path.lastIndexOf('/');
    if (slash < 0) return null;
    const seg = path.substring(slash + 1);
    const split = splitListItemSegment(seg);
    if (split === null) return null;
    const parent = path.substring(0, slash);
    const node = this.tree.byPath(parent);
    if (node !== null && node.childBySegment(seg) !== null) return null;
    const listPath = `${parent}/${split.base}`;
    if (this.tree.byPath(listPath)?.kind !== SomMetaKind.LIST) return null;
    return [listPath, seg];
  }

  /** An item pattern's list pattern (`a/L-*` → `a/L`). */
  private static _listPatternOf(itemPattern: string): string {
    return itemPattern.endsWith('-*')
      ? itemPattern.substring(0, itemPattern.length - 2)
      : itemPattern;
  }

  // --- the marker ------------------------------------------------------------

  /** A link to `anchor` in `other` (null: this document), its text `id`
   *  prefixed by the other root's id. */
  private _link(id: string, anchor: string, other: SpecRoot | null = null): string {
    if (other === null) return `[${id}](#${anchor})`;
    const file = this.codec._fileOfRoot(other);
    return `[${other.sectionId ?? other.type} ${id}](${file}#${anchor})`;
  }

  /**
   * The marker's entries at the heading `path`, in the order of SOM §11.11;
   * empty when `path` is not markable or carries no link this time.
   * `sectionTable`: the heading's children are written as a section table.
   */
  entries(path: string, sectionTable = false): string[] {
    if (!this.markable(path)) return [];
    const w = this.walk(path, { d: this.doc });
    const node = w.node!;
    const pattern = w.pattern;
    const out: string[] = [];

    // Also in (@SyncedWith).
    const note = (s: _Side): string => {
      const held = s.holder ? 'held here' : 'held there';
      return s.sync.heldHere.length === 0
        ? held
        : `${held} except ${s.sync.heldHere.join(', ')}`;
    };

    for (const s of this.sides) {
      if (s.mine !== pattern) continue;
      const there = this.walk(s.theirs, {
        inTree: this.codec._treeFor(s.other.type),
        ids: w.itemIds,
      });
      out.push(`Also in ${this._link(w.headingId, there.anchor, s.other)}, ${note(s)}`);
    }
    const item = this._itemParts(path);
    if (item !== null) {
      const listPattern = _Navigation._listPatternOf(pattern);
      const s = this.sharedListSide(listPattern, item[0]);
      if (s !== null) {
        const rel = listPattern.substring(s.mine.length);
        const there = this.walk(`${s.theirs}${rel}-*`, {
          inTree: this.codec._treeFor(s.other.type),
          ids: w.itemIds,
        });
        out.push(`Also in ${this._link(w.headingId, there.anchor, s.other)}, ${note(s)}`);
      }

      // Summary of (@SummaryOf on the list).
      const summary = this.summaryOfList(item[0]);
      if (summary !== null) {
        const links = this._summaryTargets(path, item[0], w.headingId, summary);
        if (links.length > 0) out.push(`Summary of ${links.join(', ')}`);
      }

      // Summarised in: the summary elements of this document naming it.
      const named = this.summaryLinks.get(`${item[0]}#${w.headingId}`);
      if (named !== undefined) out.push(`Summarised in ${named.join(', ')}`);
    }

    // Derived from.
    const derived = this._derivedSources(path, node, { sectionTable });
    if (derived.length > 0) {
      const links: string[] = [];
      const fields: string[] = [];
      for (const [link, field] of derived) {
        if (link !== null && !links.includes(link)) links.push(link);
        if (field !== null && !fields.includes(field)) fields.push(field);
      }
      if (links.length > 0) {
        out.push(
          `Derived from ${links.join(', ')}` +
            (fields.length === 0 ? '' : `: ${fields.join(', ')}`),
        );
      }
    }

    // Extracted from (@ExtractsLinks, generate).
    if (node.kind === SomMetaKind.LIST) {
      const from = this._extractFrom(path);
      if (from.length > 0) out.push(`Extracted from ${from.join(', ')}`);
    }

    // Copy of / Copied to (@SameAs).
    for (const b of this.sameAs) {
      if (b.copyPath !== pattern || b.holderPath === null) continue;
      const h = this.walk(b.holderPath, { d: this.doc, ids: w.itemIds });
      out.push(`Copy of ${this._link(h.headingId, h.anchor)}, edit it there`);
    }
    const copies = this.sameAs.filter((b) => b.holderPath === pattern);
    if (copies.length > 0) {
      out.push(
        `Copied to ${copies
          .map((b) => {
            const c = this.walk(b.copyPath, { d: this.doc, ids: w.itemIds });
            return this._link(c.headingId, c.anchor);
          })
          .join(', ')}`,
      );
    }
    return out;
  }

  private _summaryLinks: Map<string, string[]> | null = null;

  /** `<detail list path>#<element id>` → the links to the summary elements
   *  of this document naming that element, in document order. */
  get summaryLinks(): Map<string, string[]> {
    if (this._summaryLinks !== null) return this._summaryLinks;
    const out = new Map<string, string[]>();
    const summaries = new Set<string>();
    for (const lists of this.detailLists.values()) {
      for (const l of lists) summaries.add(l);
    }
    const doc = this.doc;
    for (const summaryList of summaries) {
      for (const concrete of specExpandPattern(doc, summaryList)) {
        const s = this.summaryOfList(concrete);
        if (s === null) continue;
        const owner = concrete.substring(0, concrete.lastIndexOf('/'));
        const r = specResolveLinkPlace(this.refl, doc, s.detail, this.rootSeg, owner);
        if (r === null) continue;
        const detail = _Navigation.cutPattern(r.path);
        for (const e of doc.listItems(concrete)) {
          const ew = this.walk(e, { d: doc });
          for (const id of this._summaryIds(e, s, ew.headingId)) {
            const key = `${detail}#${id}`;
            let links = out.get(key);
            if (links === undefined) {
              links = [];
              out.set(key, links);
            }
            const link = this._link(ew.headingId, ew.anchor);
            if (!links.includes(link)) links.push(link);
          }
        }
      }
    }
    this._summaryLinks = out;
    return out;
  }

  /** The ids summary element `element` names: its `match` field's ids, else
   *  its own `ownId`. */
  private _summaryIds(element: string, s: SpecSummaryOf, ownId: string): string[] {
    const match = s.match;
    if (match === null) return [ownId];
    const r = specResolvePlaceAt(this.refl, match, element);
    if (r === null || r.field === null) return [];
    const raw = this.doc.formField(r.path, r.field);
    if (raw === null) return [];
    return raw
      .split(',')
      .map((id) => id.trim())
      .filter((id) => id !== '');
  }

  /** The `Summary of` links of summary element `element` of `listPath`. */
  private _summaryTargets(
    element: string,
    listPath: string,
    ownId: string,
    s: SpecSummaryOf,
  ): string[] {
    return this.summaryTargets(element, listPath, ownId, s).map(([id, anchor, other]) =>
      this._link(id, anchor, other),
    );
  }

  /** The detail elements summary element `element` of `listPath` names: each
   *  id, its anchor and the other root it is in (null: this document). */
  summaryTargets(
    element: string,
    listPath: string,
    ownId: string,
    s: SpecSummaryOf,
  ): Array<[string, string, SpecRoot | null]> {
    const ids = this._summaryIds(element, s, ownId);
    if (ids.length === 0) return [];
    const owner = listPath.substring(0, listPath.lastIndexOf('/'));
    if (this._sameDocument(s)) {
      const r = specResolveLinkPlace(this.refl, this.doc, s.detail, this.rootSeg, owner);
      if (r === null) return [];
      const list = _Navigation.cutPattern(r.path);
      return ids.map((id): [string, string, SpecRoot | null] => [
        id,
        this.walk(`${list}-*`, { d: this.doc, ids: [id] }).anchor,
        null,
      ]);
    }
    const other = this.model.roots.find((r) => r.type === s.document) ?? null;
    if (other === null) return [];
    const r = specResolveLinkPlace(
      this.refl,
      null,
      s.detail,
      this.refl.rootSegment(other),
      this.refl.rootSegment(other),
    );
    return ids.map((id): [string, string, SpecRoot | null] => [
      id,
      r === null || r.path.includes('-*')
        ? id
        : this.walk(`${r.path}-*`, {
            inTree: this.codec._treeFor(other.type),
            ids: [id],
          }).anchor,
      other,
    ]);
  }

  /**
   * The `Id` cell of a records row standing for summary element `item` of
   * `listPath` whose `@SummaryOf` has no `match` (SOM §11.5, §11.11): its
   * anchor, then its id as a link to the detail element it names. Null when
   * the list is no such summary.
   */
  summaryIdCell(item: string, listPath: string, id: string): string | null {
    const s = this.summaryOfList(listPath);
    if (s === null || s.match !== null) return null;
    const targets = this.summaryTargets(item, listPath, id, s);
    if (targets.length === 0) return null;
    if (targets.length !== 1) throw new Error('Bad state: Too many elements');
    const [, anchor, other] = targets[0];
    const href = other === null ? `#${anchor}` : `${this.codec._fileOfRoot(other)}#${anchor}`;
    return `<a id="${this.anchorOf(item)}"></a>[${id}](${href})`;
  }

  /**
   * The derived values at the heading `path`: [a link to a source, or null;
   * the derived field's name, or null for a derived section] per source.
   * `probe`: answer whether there is any, structurally (no links built).
   */
  _derivedSources(
    path: string,
    node: SomMetaNode,
    opts: { probe?: boolean; sectionTable?: boolean } = {},
  ): Array<[string | null, string | null]> {
    const probe = opts.probe === true;
    const sectionTable = opts.sectionTable === true;
    const doc = this.doc;
    const out: Array<[string | null, string | null]> = [];
    const linkTo = (target: string): string => {
      const t = this.walk(_Navigation.cutPattern(target), { d: doc });
      return this._link(t.headingId, t.anchor);
    };
    const source = (place: string, owner: string): string | null => {
      if (probe) return null;
      const r = specResolveLinkPlace(this.refl, doc, place, this.rootSeg, owner);
      return r === null ? null : linkTo(r.path);
    };
    const form = (formPath: string, prefix: string | null): void => {
      const owner = formPath.substring(0, formPath.lastIndexOf('/'));
      const spec = this.refl.resolve(formPath)?.field ?? null;
      const ffs: FormFieldSpec[] = spec?.formFields ?? [];
      for (const ff of ffs) {
        const name = prefix === null ? ff.name : `${prefix}.${ff.name}`;
        const d = ff.derivedFrom;
        if (d !== null) out.push([source(d.source, owner), name]);
        for (const t of ff.countOf) {
          const f = SpecPlaceFilter.tryParse(t);
          if (f === null) continue;
          out.push([source(f.scoped ? `./${f.sectionId}` : f.sectionId, owner), name]);
        }
        for (const operand of ff.productOf) {
          const dot = operand.indexOf('.');
          out.push([
            probe
              ? null
              : linkTo(dot < 0 ? formPath : `${owner}/${operand.substring(0, dot)}`),
            name,
          ]);
        }
        if (ff.rankOf !== null) {
          const item = this._itemParts(owner);
          out.push([probe ? null : linkTo(item !== null ? item[0] : formPath), name]);
        }
      }
    };
    // A member carrying `@DerivedFrom`: `name` for one written in its
    // owner's body (no heading of its own), null for the heading itself.
    const member = (memberPath: string, name: string | null): void => {
      const d = this.refl.resolve(memberPath)?.field?.derivedFrom ?? null;
      if (d === null) return;
      const owner = memberPath.substring(0, memberPath.lastIndexOf('/'));
      out.push([source(d.source, owner), name]);
    };

    const isItem = this._itemParts(path) !== null;
    if (node.kind === SomMetaKind.FORM) form(path, null);
    if (!isItem && path.includes('/')) member(path, null);
    if (node.kind === SomMetaKind.SECTION || node.kind === SomMetaKind.COMPLEX || isItem) {
      for (const [slot, rel] of this.codec._bodySlots(node)) {
        const slotPath = `${path}/${rel}`;
        if (slot.kind === SomMetaKind.FORM) {
          form(slotPath, null);
        } else {
          member(slotPath, slot.memberName ?? slot.segment);
        }
      }
      if (sectionTable || probe) {
        for (const [child, rel] of this.codec._effectiveChildren(node)) {
          if (child.kind !== SomMetaKind.FORM) continue;
          if (probe || doc.hasValuesUnder(`${path}/${rel}`)) {
            form(`${path}/${rel}`, this.codec._headingIdOf(child));
          }
        }
      }
    }
    return out;
  }

  /** The `Extracted from` links of the link-row list at `path`: the text
   *  places of its `@ExtractsLinks` in `generate` mode. */
  private _extractFrom(path: string): string[] {
    const f = this.refl.resolve(path)?.field ?? null;
    if (f === null) return [];
    const owner = path.substring(0, path.lastIndexOf('/'));
    const out: string[] = [];
    for (const e of f.extractsLinks) {
      if (e.mode !== 'generate') continue;
      for (const place of e.from) {
        const r = specResolveLinkPlace(this.refl, this.doc, place, this.rootSeg, owner);
        if (r === null) continue;
        const t = this.walk(_Navigation.cutPattern(r.path), { d: this.doc });
        const link = this._link(t.headingId, t.anchor);
        if (!out.includes(link)) out.push(link);
      }
    }
    return out;
  }
}

/** Whether `paragraph` is exactly one span of kind `linked`. */
export function _isLinkedParagraph(paragraph: string): boolean {
  const text = paragraph.trim();
  if (!text.startsWith('[') || !text.endsWith('{.linked}')) return false;
  const scan = scanNotation(text);
  if (scan.elements.length !== 1) return false;
  const e = scan.elements[0];
  return e.type === 'span' && e.kind === 'linked' && e.start === 0 && e.end === text.length;
}

/**
 * `markdown` with every placeholder resolved: `[]{.linked}` where the
 * paragraph after it is a `linked` span, else removed with its blank line.
 */
export function _resolveLinkedPlaceholders(markdown: string): string {
  if (!markdown.includes(_kLinkedPlaceholder)) return markdown;
  const lines = markdown.split('\n');
  const out: string[] = [];
  for (let i = 0; i < lines.length; i++) {
    if (lines[i] !== _kLinkedPlaceholder) {
      out.push(lines[i]);
      continue;
    }
    // The placeholder, its blank line, then the paragraph that follows.
    let k = i + 1;
    while (k < lines.length && lines[k].trim() === '') k++;
    const para: string[] = [];
    for (let j = k; j < lines.length && lines[j].trim() !== ''; j++) {
      para.push(lines[j]);
    }
    if (para.length > 0 && _isLinkedParagraph(para.join('\n'))) {
      out.push('[]{.linked}');
    } else {
      i++; // the blank line after the placeholder goes with it
    }
  }
  return out.join('\n');
}
