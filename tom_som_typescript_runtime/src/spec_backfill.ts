/**
 * backfill: the accepted end state of the Phase 3 documents, carried into
 * the Blueprint (DP-part-operations-2).
 *
 * A port of `tom_som_dart_runtime/lib/src/spec_backfill.dart` (a `part of`
 * `spec_document_set.dart` there); it reads the comparison internals
 * {@link SpecSetCheck} and {@link SpecSetOrdered} the set exports.
 */

import { deriveFields } from './spec_derive_fields';
import { SpecDocument } from './spec_document';
import {
  SpecDocumentSet,
  SpecSetCheck,
  SpecSetOrdered,
  SpecSyncCode,
  SpecSyncFinding,
  SpecSyncHolder,
  SpecSyncPlace,
  SpecSyncResolution,
  specSyncCodeIndex,
} from './spec_document_set';
import { SpecFieldKind } from './spec_model';
import { specSectionPositions } from './spec_place';
import { SpecReflection } from './spec_reflection';
import { K_SPEC_HEADLINE_FIELD, SpecReviewAnnotations } from './spec_review_annotations';
import { effectiveListItemSectionId } from './spec_section_id';

/** Why {@link backfill} refuses a set. */
export class SpecBackfillError extends Error {
  /**
   * `setHasMarks`: a document holds an inline mark or an annotation block;
   * `noBlueprint`: the set has no Blueprint.
   */
  readonly code: string;
  /** The places holding them, in document order. */
  readonly places: SpecSyncPlace[];

  constructor(code: string, places: SpecSyncPlace[], message: string) {
    super(message);
    this.name = 'SpecBackfillError';
    this.code = code;
    this.places = places;
  }

  /** The canonical JSON form (no message). */
  toJson(): Record<string, unknown> {
    return { code: this.code, places: this.places.map((p) => p.toJson()) };
  }

  toString(): string {
    return `SpecBackfillError(${this.code}): ${this.message}`;
  }
}

/** One place {@link backfill} wrote in the Blueprint. */
export class SpecBackfillChange {
  /**
   * The pair the change belongs to; empty for the revision entry and the
   * derived places written after it.
   */
  readonly pair: string;
  /**
   * `value` (a value written or cleared), `elementAdded`, `elementRemoved`,
   * `revision` (the history entry), `derived` (a derived place rewritten).
   */
  readonly kind: string;
  /** The value's path, or the element's. */
  readonly path: string;
  /** The form field ({@link K_SPEC_HEADLINE_FIELD} for a headline), or null. */
  readonly field: string | null;
  /** The value before (for an element, its id before). */
  readonly oldValue: string;
  /** The value after (for an element, its id after). */
  readonly newValue: string;

  constructor(props: {
    pair: string;
    kind: string;
    path: string;
    field?: string | null;
    oldValue?: string;
    newValue?: string;
  }) {
    this.pair = props.pair;
    this.kind = props.kind;
    this.path = props.path;
    this.field = props.field != null ? props.field : null;
    this.oldValue = props.oldValue ?? '';
    this.newValue = props.newValue ?? '';
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return {
      pair: this.pair,
      kind: this.kind,
      path: this.path,
      ...(this.field !== null ? { field: this.field } : {}),
      old: this.oldValue,
      new: this.newValue,
    };
  }
}

/** A finding {@link backfill} left, with the reason. */
export class SpecBackfillLeft {
  constructor(
    /** The finding. */
    readonly finding: SpecSyncFinding,
    /**
     * `heldHere` (the Blueprint holds the value: the agent corrects the
     * Phase 3 document), `mayBeAdded` (under `subset`, not carried in), or
     * the finding's resolution (`agent`, `info`).
     */
    readonly reason: string,
  ) {}

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return { finding: this.finding.toJson(), reason: this.reason };
  }
}

/** What {@link backfill} did. */
export class SpecBackfillResult {
  /** The Blueprint written: the set's own, or its copy on a dry run. */
  readonly blueprint: SpecDocument;
  /** Every place written, in the order written. */
  readonly changes: SpecBackfillChange[];
  /** Every finding in scope it did not resolve, with the reason. */
  readonly left: SpecBackfillLeft[];

  constructor(props: {
    blueprint: SpecDocument;
    changes: SpecBackfillChange[];
    left: SpecBackfillLeft[];
  }) {
    this.blueprint = props.blueprint;
    this.changes = props.changes;
    this.left = props.left;
  }

  /** The canonical JSON form (the Blueprint as its stores). */
  toJson(): Record<string, unknown> {
    return {
      changes: this.changes.map((c) => c.toJson()),
      left: this.left.map((l) => l.toJson()),
      blueprint: this.blueprint.toJson(),
    };
  }
}

function _cmp(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

/**
 * Carries the end state of the Phase 3 documents into the Blueprint, as
 * plain values (DP-part-operations-2): for every shared place whose holder is
 * the Phase 3 document, the holder's value — a differing or missing value
 * written, a value the Phase 3 document emptied cleared, an element only in
 * the Phase 3 document added (with its stored section id, after its nearest
 * preceding neighbour the Blueprint holds, or first), an element only in the
 * Blueprint removed (DP-part-operations-3).
 *
 * It leaves `detailOnly` places, a `heldHere` place the documents disagree
 * on, an element that under `subset` may be added, and every finding across
 * two documents: each is listed in {@link SpecBackfillResult.left} with the
 * reason.
 *
 * It refuses a set holding any inline mark or annotation block
 * ({@link SpecBackfillError}, `setHasMarks`, the places named). It writes
 * only the Blueprint; when it changed anything it adds one entry to the
 * Blueprint's revision history (the `RVENT` list) naming the pairs, by
 * `author` on `date`, and rewrites the Blueprint's derived places
 * (`deriveFields`, plain). `pairs` and `path` (a Blueprint path) scope it;
 * `dryRun` writes a copy. A second run right after the first writes nothing.
 */
export function backfill(
  set: SpecDocumentSet,
  options: {
    pairs?: Iterable<string> | null;
    path?: string | null;
    dryRun?: boolean;
    author?: string | null;
    date?: string | null;
  } = {},
): SpecBackfillResult {
  const pairs = options.pairs != null ? new Set(options.pairs) : null;
  const path = options.path ?? null;
  const bpRoot = set.blueprintRoot;
  const bpName = bpRoot === null ? null : set.nameOf(bpRoot);
  if (bpName === null) {
    throw new SpecBackfillError('noBlueprint', [], 'the set holds no Blueprint');
  }
  const refl = set.refl;

  // No review in progress.
  const marked: SpecSyncPlace[] = [];
  for (const name of set.names) {
    const doc = set.get(name)!;
    const root = refl.rootSegment(refl.model.roots.find((r) => r.type === set.rootOf(name))!);
    const seen = new Set<string>();
    for (const a of new SpecReviewAnnotations(doc).list()) {
      const k = `${a.path}#${a.field ?? ''}`;
      if (seen.has(k)) {
        continue;
      }
      seen.add(k);
      marked.push(new SpecSyncPlace({ document: name, root, path: a.path, field: a.field }));
    }
  }
  if (marked.length > 0) {
    throw new SpecBackfillError(
      'setHasMarks',
      marked,
      `the set holds ${marked.length} value(s) with inline marks or ` +
        'annotation blocks; backfill carries the end state of an accepted ' +
        'review, so decide them first',
    );
  }

  let target: SpecDocument;
  if (options.dryRun === true) {
    target = new SpecDocument();
    target.loadJson(set.get(bpName)!.toJson());
  } else {
    target = set.get(bpName)!;
  }
  const c = new SpecSetCheck(set);
  let index = 0;
  for (const p of set.pairs) {
    if (pairs === null || pairs.has(p.sectionId)) {
      c.comparePair(p, index);
    }
    index++;
  }
  // The links across two documents are the agent's; they are listed as left.
  c.crossChecks(pairs, index);
  c.out.sort((a, b) => {
    if (a.order !== b.order) {
      return a.order - b.order;
    }
    const k = _cmp(a.key, b.key);
    return k !== 0 ? k : specSyncCodeIndex(a.finding.code) - specSyncCodeIndex(b.finding.code);
  });
  const inScope = (f: SpecSyncFinding): boolean =>
    path === null || f.blueprint.path === path || f.blueprint.path.startsWith(`${path}/`);

  const w = new _Backfill(set, target, bpName);
  const left: SpecBackfillLeft[] = [];
  const apply: SpecSetOrdered[] = [];
  for (const o of c.out) {
    const f = o.finding;
    if (!inScope(f)) {
      continue;
    }
    if (f.resolution === SpecSyncResolution.BACKFILL) {
      apply.push(o);
    } else {
      left.push(
        new SpecBackfillLeft(
          f,
          f.holder === SpecSyncHolder.BLUEPRINT
            ? 'heldHere'
            : f.code === SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED
              ? 'mayBeAdded'
              : f.resolution,
        ),
      );
    }
  }
  w.apply(apply);
  if (w.changes.length > 0) {
    w.revisionEntry(options.author ?? 'backfill', options.date ?? _today());
    for (const d of deriveFields(set.model, target, { marked: false }).changes) {
      w.changes.push(
        new SpecBackfillChange({
          pair: '',
          kind: 'derived',
          path: d.path,
          field: d.field,
          oldValue: d.oldValue,
          newValue: d.newValue,
        }),
      );
    }
  }
  return new SpecBackfillResult({ blueprint: target, changes: w.changes, left });
}

function _today(): string {
  const now = new Date();
  const two = (n: number) => String(n).padStart(2, '0');
  return `${now.getFullYear()}-${two(now.getMonth() + 1)}-${two(now.getDate())}`;
}

interface _Ids {
  pair: string;
  add: Set<string>;
  drop: Set<string>;
}

class _Backfill {
  readonly changes: SpecBackfillChange[] = [];
  private readonly _pairs = new Set<string>();

  constructor(
    readonly set: SpecDocumentSet,
    readonly doc: SpecDocument,
    readonly name: string,
  ) {}

  get refl(): SpecReflection {
    return this.set.refl;
  }

  private _get(path: string, field: string | null): string {
    return (
      (field === K_SPEC_HEADLINE_FIELD
        ? this.doc.headline(path)
        : field === null
          ? this.doc.content(path)
          : this.doc.formField(path, field)) ?? ''
    );
  }

  private _set(path: string, field: string | null, value: string): void {
    if (field === K_SPEC_HEADLINE_FIELD) {
      this.doc.setHeadline(path, value);
    } else if (field === null) {
      this.doc.setContent(path, value);
    } else {
      this.doc.setFormField(path, field, value);
    }
  }

  private _write(pair: string, path: string, field: string | null, value: string): void {
    const old = this._get(path, field);
    if (old.trim() === value.trim()) {
      return;
    }
    this._set(path, field, value);
    this._pairs.add(pair);
    this.changes.push(
      new SpecBackfillChange({ pair, kind: 'value', path, field, oldValue: old, newValue: value }),
    );
  }

  private _idOf(item: string): string {
    return this._idIn(this.doc, item);
  }

  private _idIn(doc: SpecDocument, item: string): string {
    const stored = doc.itemSectionId(item);
    if (stored !== null) {
      return stored;
    }
    const list = item.substring(0, item.lastIndexOf('-'));
    const res = this.refl.resolve(list);
    const field = res !== null ? res.field : null;
    const segs = list.split('/');
    return effectiveListItemSectionId(
      null,
      field !== null ? field.sectionIdPattern : null,
      doc.listItems(list).indexOf(item) + 1,
      field !== null ? field.name : segs[segs.length - 1],
    );
  }

  private static _rel(key: string): string {
    const body = key.substring(2);
    const hash = body.indexOf('#');
    return hash < 0 ? body : body.substring(0, hash);
  }

  apply(found: SpecSetOrdered[]): void {
    const doc = this.doc;
    // 1. Elements only in the Blueprint go, first.
    for (const o of found) {
      if (
        o.finding.code !== SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT ||
        !o.key.startsWith('i:')
      ) {
        continue;
      }
      const item = o.b!.items.get(o.key.substring(2));
      if (item === undefined || !doc.removeListItem(item)) {
        continue;
      }
      this._pairs.add(o.finding.pair);
      this.changes.push(
        new SpecBackfillChange({
          pair: o.finding.pair,
          kind: 'elementRemoved',
          path: item,
          oldValue: o.finding.blueprint.value ?? '',
        }),
      );
    }

    // 2. Values, and the ids of reference fields.
    const ids = new Map<string, _Ids>();
    const idsOf = (key: string, pair: string): _Ids => {
      let e = ids.get(key);
      if (e === undefined) {
        e = { pair, add: new Set(), drop: new Set() };
        ids.set(key, e);
      }
      return e;
    };
    for (const o of found) {
      const f = o.finding;
      if (o.key.startsWith('i:')) {
        continue;
      }
      const field = f.blueprint.field;
      switch (f.code) {
        case SpecSyncCode.SHARED_VALUE_DIFFERS:
        case SpecSyncCode.SHARED_VALUE_MISSING:
          this._write(f.pair, f.blueprint.path, field, o.d!.values.get(o.key)!.value);
          break;
        case SpecSyncCode.SHARED_VALUE_ONLY_IN_BLUEPRINT:
          this._write(f.pair, f.blueprint.path, field, '');
          break;
        case SpecSyncCode.SHARED_ELEMENT_MISSING:
          idsOf(`${f.blueprint.path}#${field}`, f.pair).add.add(f.detail.value!);
          break;
        case SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT:
          idsOf(`${f.blueprint.path}#${field}`, f.pair).drop.add(f.blueprint.value!);
          break;
        default:
          break;
      }
    }
    for (const [key, e] of ids) {
      const hash = key.lastIndexOf('#');
      const path = key.substring(0, hash);
      const field = key.substring(hash + 1);
      const now: string[] = [];
      for (const s of this._get(path, field).split(',')) {
        if (s.trim() !== '' && !e.drop.has(s.trim())) {
          now.push(s.trim());
        }
      }
      for (const x of e.add) {
        if (!now.includes(x)) {
          now.push(x);
        }
      }
      this._write(e.pair, path, field, now.join(', '));
    }

    // 3. Elements only in the Phase 3 document come in, each with every value
    // the pair shares beneath it, then take their place.
    const added: { list: string; id: string; order: string[] }[] = [];
    for (const o of found) {
      if (o.finding.code !== SpecSyncCode.SHARED_ELEMENT_MISSING || !o.key.startsWith('i:')) {
        continue;
      }
      const d = o.d!;
      const rel = o.key.substring(2);
      const id = rel.substring(rel.lastIndexOf('[') + 1, rel.length - 1);
      const list = o.finding.blueprint.path;
      const detailItem = d.items.get(rel)!;
      const item = doc.addListItem(list, id);
      this._pairs.add(o.finding.pair);
      this.changes.push(
        new SpecBackfillChange({ pair: o.finding.pair, kind: 'elementAdded', path: item, newValue: id }),
      );
      // Nested elements first (shortest key first), then the values.
      const mapped = new Map<string, string>([[detailItem, item]]);
      const nested = Array.from(d.items.keys())
        .filter((k) => k.startsWith(`${rel}/`))
        .sort((a, b) => a.length - b.length);
      for (const k of nested) {
        const dPath = d.items.get(k)!;
        let parent: [string, string] | null = null;
        for (const m of mapped) {
          if (dPath.startsWith(`${m[0]}/`) && (parent === null || m[0].length > parent[0].length)) {
            parent = m;
          }
        }
        if (parent === null) {
          continue;
        }
        const seg = dPath.substring(parent[0].length + 1);
        const nestedId = k.substring(k.lastIndexOf('[') + 1, k.length - 1);
        mapped.set(
          dPath,
          doc.addListItem(`${parent[1]}/${seg.substring(0, seg.lastIndexOf('-'))}`, nestedId),
        );
      }
      const into = (dPath: string): string | null => {
        let best: [string, string] | null = null;
        for (const m of mapped) {
          if (
            (dPath === m[0] || dPath.startsWith(`${m[0]}/`)) &&
            (best === null || m[0].length > best[0].length)
          ) {
            best = m;
          }
        }
        return best === null ? null : `${best[1]}${dPath.substring(best[0].length)}`;
      };

      for (const [k, v] of d.values) {
        const r = _Backfill._rel(k);
        if (r !== rel && !r.startsWith(`${rel}/`)) {
          continue;
        }
        const p = into(v.path);
        if (p === null || v.value === '') {
          continue;
        }
        this._set(p, v.field, v.value);
      }
      // The detail list's order, by id.
      const detailDoc = this.set.get(o.finding.detail.document!)!;
      const detailList = detailItem.substring(0, detailItem.lastIndexOf('-'));
      added.push({
        list,
        id,
        order: detailDoc.listItems(detailList).map((it) => this._idIn(detailDoc, it)),
      });
    }
    // Each list takes its new elements in one reorder: an element goes after
    // its nearest preceding neighbour (in the Phase 3 order) the Blueprint
    // holds, or first.
    const byList = new Map<string, { id: string; order: string[] }[]>();
    for (const a of added) {
      let l = byList.get(a.list);
      if (l === undefined) {
        l = [];
        byList.set(a.list, l);
      }
      l.push({ id: a.id, order: a.order });
    }
    const orders = new Map<string, string[]>();
    for (const [list, entries] of byList) {
      const newIds = new Set(entries.map((a) => a.id));
      const items = doc.listItems(list);
      const order = items.filter((i) => !newIds.has(this._idOf(i)));
      for (const a of entries) {
        const item = items.find((i) => this._idOf(i) === a.id)!;
        const before = a.order.slice(0, a.order.indexOf(a.id));
        let at = 0;
        for (let j = before.length - 1; j >= 0; j--) {
          const k = order.findIndex((x) => this._idOf(x) === before[j]);
          if (k >= 0) {
            at = k + 1;
            break;
          }
        }
        order.splice(at, 0, item);
      }
      orders.set(list, order);
    }
    this._reorder(orders);
    // Each added element is reported at the place it took.
    for (let i = 0; i < this.changes.length; i++) {
      const ch = this.changes[i];
      if (ch.kind !== 'elementAdded') {
        continue;
      }
      const list = ch.path.substring(0, ch.path.lastIndexOf('-'));
      const now = doc.listItems(list).find((x) => this._idOf(x) === ch.newValue);
      if (now === undefined || now === ch.path) {
        continue;
      }
      this.changes[i] = new SpecBackfillChange({
        pair: ch.pair,
        kind: ch.kind,
        path: now,
        newValue: ch.newValue,
      });
    }
  }

  /**
   * Puts the items of each list in `orders` in the order given, in one pass
   * over the document's stores: the lists renumbered `<list>-1 … <list>-n`,
   * every value beneath an item travelling with it, an anonymous item whose
   * positional id would change keeping its old id (as `moveListItem` does).
   * Inner lists go first, so an outer rename carries their new paths.
   */
  private _reorder(orders: Map<string, string[]>): void {
    if (orders.size === 0) {
      return;
    }
    const doc = this.doc;
    const lists = Array.from(orders.keys()).sort(
      (a, b) => b.split('/').length - a.split('/').length,
    );
    const ids = new Map<string, string>();
    for (const l of lists) {
      for (const i of doc.listItems(l)) {
        ids.set(i, this._idOf(i));
      }
    }
    const json: any = doc.toJson();
    const rename = (key: string, map: Map<string, string>): string => {
      for (const [from, to] of map) {
        if (key === from) {
          return to;
        }
        if (key.startsWith(`${from}/`)) {
          return `${to}${key.substring(from.length)}`;
        }
      }
      return key;
    };

    for (const list of lists) {
      const order = orders.get(list)!;
      const listJson = json.lists[list];
      const map = new Map<string, string>();
      for (let i = 0; i < order.length; i++) {
        const to = `${list}-${i + 1}`;
        if (order[i] !== to) {
          map.set(order[i], to);
        }
      }
      if (map.size === 0) {
        continue;
      }
      const storedIds: Record<string, string | null> = { ...(listJson.ids ?? {}) };
      const original = doc.listItems(list);
      for (let i = 0; i < order.length; i++) {
        if (original.indexOf(order[i]) !== i && !(order[i] in storedIds)) {
          storedIds[order[i]] = ids.get(order[i]) ?? null;
        }
      }
      for (const store of ['content', 'forms', 'headlines', 'codeSpecs', 'units']) {
        const m = json[store];
        if (m == null) {
          continue;
        }
        const next: Record<string, unknown> = {};
        for (const [k, v] of Object.entries(m)) {
          next[rename(k, map)] = v;
        }
        json[store] = next;
      }
      const newLists: Record<string, unknown> = {};
      for (const [key, value] of Object.entries(json.lists as Record<string, any>)) {
        const spec: any = { ...value };
        if (key === list) {
          spec.items = order.map((i) => rename(i, map));
          const nextIds: Record<string, string | null> = {};
          for (const i of order) {
            nextIds[rename(i, map)] = storedIds[i] ?? null;
          }
          spec.ids = nextIds;
        } else {
          spec.items = (spec.items as string[]).map((i) => rename(i, map));
          if (spec.ids !== null && typeof spec.ids === 'object') {
            const nextIds: Record<string, unknown> = {};
            for (const [k, v] of Object.entries(spec.ids)) {
              nextIds[rename(k, map)] = v;
            }
            spec.ids = nextIds;
          }
        }
        newLists[rename(key, map)] = spec;
      }
      json.lists = newLists;
    }
    doc.loadJson(json);
  }

  /** One entry in the Blueprint's revision history naming the pairs. */
  revisionEntry(author: string, date: string): void {
    const doc = this.doc;
    const refl = this.refl;
    const root = this.set.blueprintRoot!;
    let list: string | null = null;
    for (const p of specSectionPositions(refl, root)) {
      if (!p.isMember || p.member === null || p.member.kind !== SpecFieldKind.LIST) {
        continue;
      }
      if (p.path.includes('-*')) {
        continue;
      }
      const el = refl.classNamed(p.member.elementType);
      if (el === null || el.sectionId !== 'RVENT') {
        continue;
      }
      list = p.path;
      break;
    }
    if (list === null) {
      return;
    }
    const items = doc.listItems(list);
    const last =
      items.length === 0 ? '' : (doc.formField(`${items[items.length - 1]}/content`, 'version') ?? '');
    const version = _Backfill._bump(last);
    const item = doc.addListItem(list);
    const names = Array.from(
      new Set(this.set.pairs.filter((p) => this._pairs.has(p.sectionId)).map((p) => p.sectionId)),
    );
    const summary =
      `Backfilled from ${this.set.names.filter((n) => n !== this.name).join(', ')}: ` +
      names.join(', ');
    for (const [f, v] of [
      ['version', version],
      ['date', date],
      ['author', author],
      ['summary', summary],
    ] as const) {
      doc.setFormField(`${item}/content`, f, v);
    }
    this.changes.push(
      new SpecBackfillChange({ pair: '', kind: 'revision', path: item, newValue: version }),
    );
  }

  /**
   * The version after `v`: its last number raised by one (`1.2` → `1.3`),
   * `1` when it holds none.
   */
  private static _bump(v: string): string {
    const m = /(\d+)(?!.*\d)/.exec(v);
    if (m === null) {
      return v === '' ? '1' : `${v}.1`;
    }
    const n = parseInt(m[1], 10) + 1;
    return `${v.substring(0, m.index)}${n}${v.substring(m.index + m[0].length)}`;
  }
}
