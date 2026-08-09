/**
 * Lexical/structural query + lazy cursor over a live {@link SpecDocument}
 * (`llm_and_d4rt_tools.md` §6, `som_multiplatform_spec_model.md` §15) — a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_query.dart`.
 *
 * This is the **grep-like** facility the downstream D4rt scripting layer and
 * the editor's search tools reuse. It is **embedding-free** — exact substring
 * or {@link SomTextPattern} match plus structural filters — so it is always
 * current and needs no model calls.
 *
 * A {@link SpecQuery} composes (AND-combined) over five dimensions:
 *   * **text** — substring or {@link SomTextPattern} over content + form-field
 *     values and over a node's headline, stored or doc-comment (optionally
 *     case-insensitive);
 *   * **kind** — one or more {@link SpecNodeKind}s;
 *   * **class** — the model class a node *is* (by class name);
 *   * **id / path** — exact `@SectionId`, `@SectionId` prefix, path glob, or a
 *     `@MapsTo` / `@DetailedIn` target on the node's class;
 *   * **state** — empty / non-empty (the structural "empty = no value" test).
 *
 * {@link SpecQueryEngine.query} returns a {@link SpecQueryCursor} the caller
 * iterates lazily (`next` / `take` / `count`). The cursor captures the
 * **structural** candidate set when it is created, then **re-validates each
 * path against the live document on every step** — so a result whose list-item
 * ancestor was removed after the cursor was made is silently skipped (stable
 * against concurrent edits, llm_and_d4rt_tools.md §6).
 */

import { SpecDocument } from './spec_document';
import { SpecClass, SpecField, SpecFieldKind, SpecModel } from './spec_model';
import { specPathJoin, specPathSegments, splitListItemSegment } from './spec_paths';
import { SpecNodeKind, SpecReflection, SpecResolution } from './spec_reflection';
import type { SpecNodeKindValue } from './spec_reflection';
import { SomTextPattern, SpecMatchSpan } from './spec_text_pattern';

/** Whether a node currently holds a value, used by the `state` dimension. */
export const SpecStateFilter = {
  /** The node (and everything beneath it) holds no value. */
  EMPTY: 'empty',

  /** The node holds at least one value at or beneath its path. */
  NON_EMPTY: 'nonEmpty',
} as const;

export type SpecStateFilterValue =
  (typeof SpecStateFilter)[keyof typeof SpecStateFilter];

/**
 * A flat, value-bearing projection of one document node — everything the
 * tier-1 structural/lexical index (`llm_and_d4rt_tools.md` §9.2) needs to
 * index a section **without re-walking the model itself**: its path, kind,
 * class, the structural facets (section id, `@MapsTo` / `@DetailedIn`), the
 * headline, the searchable strings (stored values + headline), and whether it
 * currently holds a value.
 *
 * Produced by {@link SpecQueryEngine.projectNodes} /
 * {@link SpecQueryEngine.projectNode}, which reuse the same structural-closure
 * walk and value-extraction the live query uses — so the index and the live
 * llm_and_d4rt_tools.md §6 search agree on what a node is and what text it
 * carries — with no model (LLM) calls.
 */
export class SpecNodeProjection {
  /** The globally-unique section-id path the node lives at. */
  path: string;

  /** What kind of node the path lands on. */
  kind: SpecNodeKindValue;

  /** The model class the node *is* (`null` for value leaves and list
   * containers). */
  classId: string | null;

  /** The node's `@SectionId` (field, class, or root), `null` when none. */
  sectionId: string | null;

  /** The `@MapsTo` target on the node's class, `null` when none. */
  mapsTo: string | null;

  /** The `@DetailedIn` target on the node's class, `null` when none. */
  detailedIn: string | null;

  /** The node's headline — the stored one when the author set it, else the
   * model's doc comment. `null` when neither exists. */
  headline: string | null;

  /** The strings a text search indexes for this node: stored values (content,
   * scalar item, every form-field value) followed by the headline. Empty for a
   * container node that carries no direct value and has no headline. */
  searchableStrings: string[];

  /** Whether the node (or anything beneath it) currently holds a value — the
   * `state` facet (empty vs non-empty). */
  hasValue: boolean;

  constructor(props: {
    path: string;
    kind: SpecNodeKindValue;
    classId?: string | null;
    sectionId?: string | null;
    mapsTo?: string | null;
    detailedIn?: string | null;
    headline?: string | null;
    searchableStrings?: string[];
    hasValue?: boolean;
  }) {
    this.path = props.path;
    this.kind = props.kind;
    this.classId = props.classId != null ? props.classId : null;
    this.sectionId = props.sectionId != null ? props.sectionId : null;
    this.mapsTo = props.mapsTo != null ? props.mapsTo : null;
    this.detailedIn = props.detailedIn != null ? props.detailedIn : null;
    this.headline = props.headline != null ? props.headline : null;
    this.searchableStrings =
      props.searchableStrings != null ? props.searchableStrings : [];
    this.hasValue = Boolean(props.hasValue);
  }

  toString(): string {
    return `SpecNodeProjection(${this.path}, ${this.kind})`;
  }
}

/**
 * One node matched by a {@link SpecQuery} (the llm_and_d4rt_tools.md §6 cursor
 * record).
 */
export class SpecQueryMatch {
  /** The globally-unique section-ID path the node lives at. */
  path: string;

  /** What kind of node the path lands on. */
  kind: SpecNodeKindValue;

  /** The model class the node *is* (`null` for value leaves and list
   * containers). */
  classId: string | null;

  /** The node's headline — stored if the author set one, else the model's doc
   * comment (`null` when neither exists). */
  headline: string | null;

  /** The matched text, when the query carried a `text` dimension (`null`
   * otherwise) — the value/headline that the pattern hit. */
  snippet: string | null;

  /** The spans within {@link snippet} the `text` pattern matched (empty for
   * non-text queries). */
  matchSpans: SpecMatchSpan[];

  constructor(props: {
    path: string;
    kind: SpecNodeKindValue;
    classId?: string | null;
    headline?: string | null;
    snippet?: string | null;
    matchSpans?: SpecMatchSpan[];
  }) {
    this.path = props.path;
    this.kind = props.kind;
    this.classId = props.classId != null ? props.classId : null;
    this.headline = props.headline != null ? props.headline : null;
    this.snippet = props.snippet != null ? props.snippet : null;
    this.matchSpans = props.matchSpans != null ? props.matchSpans : [];
  }

  toString(): string {
    return `SpecQueryMatch(${this.path}, ${this.kind})`;
  }
}

/**
 * The named-argument shape of the {@link SpecQuery} constructor.
 *
 * Every member is optional, and **omitting one means "dimension unset"** — not
 * "a default that happens to match". That distinction is part of the
 * cross-language wire contract: a decoder must not substitute a matching
 * default for an absent key.
 */
export interface SpecQueryInit {
  text?: string | null;
  regex?: boolean;
  caseInsensitive?: boolean;
  kinds?: Set<SpecNodeKindValue> | null;
  className?: string | null;
  sectionIdExact?: string | null;
  sectionIdPrefix?: string | null;
  pathGlob?: string | null;
  mapsTo?: string | null;
  detailedIn?: string | null;
  state?: SpecStateFilterValue | null;
}

/**
 * An AND-combined lexical/structural query (llm_and_d4rt_tools.md §6). Every
 * supplied dimension must hold for a node to match; an all-`null` query matches
 * every node in the document's structural closure.
 */
export class SpecQuery {
  /** Substring (or {@link regex} pattern) to find in content + form values and
   * the headline. */
  text: string | null;

  /** Treat {@link text} as a {@link SomTextPattern} — the portable pattern
   * subset (`.`, `*`, `+`, `?`, `[…]`, `^`, `$`) — instead of a literal
   * substring. Named `regex` because that is what a caller reaches for it
   * expecting; the grammar is deliberately narrower than a full regex, and
   * `SomPatternError` says so rather than silently reinterpreting. */
  regex: boolean;

  /** Match {@link text} case-insensitively. */
  caseInsensitive: boolean;

  /** The node kinds to include (any-of); `null` admits every kind. */
  kinds: Set<SpecNodeKindValue> | null;

  /** The model class name a node must *be* (`SpecResolution.targetClass`). */
  className: string | null;

  /** The node's `@SectionId` must equal this exactly. */
  sectionIdExact: string | null;

  /** The node's `@SectionId` must start with this prefix. */
  sectionIdPrefix: string | null;

  /** A glob over the node's path (`*` matches within one segment, `**` across
   * segments). */
  pathGlob: string | null;

  /** The node's class must carry `@MapsTo(<this>)`. */
  mapsTo: string | null;

  /** The node's class must carry `@DetailedIn(<this>)`. */
  detailedIn: string | null;

  /** The node's value-presence state must match this. */
  state: SpecStateFilterValue | null;

  constructor(props: SpecQueryInit = {}) {
    this.text = props.text != null ? props.text : null;
    this.regex = Boolean(props.regex);
    this.caseInsensitive = Boolean(props.caseInsensitive);
    this.kinds = props.kinds != null ? props.kinds : null;
    this.className = props.className != null ? props.className : null;
    this.sectionIdExact =
      props.sectionIdExact != null ? props.sectionIdExact : null;
    this.sectionIdPrefix =
      props.sectionIdPrefix != null ? props.sectionIdPrefix : null;
    this.pathGlob = props.pathGlob != null ? props.pathGlob : null;
    this.mapsTo = props.mapsTo != null ? props.mapsTo : null;
    this.detailedIn = props.detailedIn != null ? props.detailedIn : null;
    this.state = props.state != null ? props.state : null;
  }
}

/** The snippet + spans one searchable string contributed to a text match. */
interface _TextHit {
  snippet: string;
  spans: SpecMatchSpan[];
}

/**
 * Runs {@link SpecQuery}s over a ({@link SpecModel}, {@link SpecDocument})
 * pair, producing {@link SpecQueryCursor}s.
 */
export class SpecQueryEngine {
  /** The meta-model describing the document's structure. */
  model: SpecModel;

  /** The live document whose values are searched. */
  document: SpecDocument;

  private _reflection: SpecReflection;

  constructor(model: SpecModel, document: SpecDocument) {
    this.model = model;
    this.document = document;
    this._reflection = new SpecReflection(model);
  }

  /**
   * Builds a cursor over the nodes matching `query`. The structural candidate
   * set is computed now (document order); value-dependent filters and path
   * liveness are re-checked as the cursor advances.
   *
   * Throws `SomPatternError` when `query.regex` is set and `query.text` is not
   * in the portable subset. The pattern is compiled **here**, not on first
   * use, for two reasons: a malformed pattern is the caller's mistake and
   * should surface at the call that made it, and a cursor that happens to
   * visit no candidate would otherwise swallow the error entirely.
   */
  query(query: SpecQuery): SpecQueryCursor {
    const pattern = query.text === null ? null : this._patternFor(query);
    const candidates: string[] = [];
    for (const path of this._enumeratePaths()) {
      const resolution = this._reflection.resolve(path);
      if (resolution === null) {
        continue;
      }
      if (this._matchesStructural(query, resolution)) {
        candidates.push(path);
      }
    }
    return new SpecQueryCursor(this, query, pattern, candidates);
  }

  // --- flat node projection (tier-1 index source) -------------------------

  /**
   * Projects every indexable node of the live document (the
   * llm_and_d4rt_tools.md §6 structural closure) as a flat
   * {@link SpecNodeProjection}, in document order. Reuses the same walk and
   * value extraction the query uses, so the index built from these projections
   * and the live llm_and_d4rt_tools.md §6 search agree on what a node is and
   * what text it carries. Pure object-model traversal — no model (LLM) calls.
   *
   * Lazy (a generator), like the Dart `sync*` original: a caller that breaks
   * early never pays for projecting the rest of the document.
   */
  *projectNodes(): Generator<SpecNodeProjection> {
    for (const path of this._enumeratePaths()) {
      const projection = this.projectNode(path);
      if (projection !== null) {
        yield projection;
      }
    }
  }

  /**
   * Projects the single node at `path`, or `null` when the path no longer
   * resolves against the model. Used for the index's incremental refresh: a
   * caller re-projects only the changed section paths.
   */
  projectNode(path: string): SpecNodeProjection | null {
    const resolution = this._reflection.resolve(path);
    if (resolution === null) {
      return null;
    }
    const cls = resolution.targetClass;
    return new SpecNodeProjection({
      path,
      kind: resolution.kind,
      classId: cls !== null ? cls.name : null,
      sectionId: this._sectionIdOf(resolution),
      mapsTo: cls !== null ? cls.mapsTo : null,
      detailedIn: cls !== null ? cls.detailedIn : null,
      headline: this._headlineOf(resolution),
      searchableStrings: Array.from(this._searchableStrings(resolution)),
      hasValue: this.document.hasValuesUnder(path),
    });
  }

  // --- structural-closure enumeration -------------------------------------

  /**
   * Every addressable node of the document in document order: the root, each
   * singular complex/section node on the spine (bounded by cycle detection),
   * each list container, each *existing* list item, and every declared leaf.
   */
  private *_enumeratePaths(): Generator<string> {
    for (const root of this.model.roots) {
      const segment = this._reflection.rootSegment(root);
      yield* this._walk(
        segment,
        this.model.classNamed(root.type),
        new Set<string>([root.type]),
      );
    }
  }

  private *_walk(
    path: string,
    cls: SpecClass | null,
    ancestorTypes: Set<string>,
  ): Generator<string> {
    yield path; // the node itself (root / complex / section container)
    if (cls === null) {
      return;
    }
    for (const field of cls.fields) {
      const fieldPath = specPathJoin(path, this._reflection.fieldSegment(field));
      switch (field.kind) {
        case SpecFieldKind.CONTENT:
        case SpecFieldKind.ENUM:
        case SpecFieldKind.SCALAR:
        case SpecFieldKind.FORM:
          yield fieldPath; // a value leaf
          break;
        case SpecFieldKind.LIST:
          yield fieldPath; // the list container node
          for (const itemPath of this.document.listItems(fieldPath)) {
            if (
              field.elementIsComplex &&
              field.elementType !== null &&
              !ancestorTypes.has(field.elementType)
            ) {
              yield* this._walk(
                itemPath,
                this.model.classNamed(field.elementType),
                new Set<string>([...ancestorTypes, field.elementType]),
              );
            } else {
              yield itemPath; // scalar item, or a recursive/unknown element
            }
          }
          break;
        default:
          // complex / section
          if (field.type !== null && !ancestorTypes.has(field.type)) {
            yield* this._walk(
              fieldPath,
              this.model.classNamed(field.type),
              new Set<string>([...ancestorTypes, field.type]),
            );
          } else {
            yield fieldPath; // recursive/unknown target: a terminal node
          }
          break;
      }
    }
  }

  // --- predicates ----------------------------------------------------------

  /** The model-fixed dimensions (kind / class / id / path / mapsTo /
   * detailedIn). */
  private _matchesStructural(
    query: SpecQuery,
    resolution: SpecResolution,
  ): boolean {
    if (query.kinds !== null && !query.kinds.has(resolution.kind)) {
      return false;
    }
    const cls = resolution.targetClass;
    if (
      query.className !== null &&
      (cls === null ? null : cls.name) !== query.className
    ) {
      return false;
    }

    const sectionId = this._sectionIdOf(resolution);
    if (query.sectionIdExact !== null && sectionId !== query.sectionIdExact) {
      return false;
    }
    if (
      query.sectionIdPrefix !== null &&
      !(sectionId !== null && sectionId.startsWith(query.sectionIdPrefix))
    ) {
      return false;
    }
    if (
      query.pathGlob !== null &&
      !this._globMatches(query.pathGlob, resolution.path)
    ) {
      return false;
    }
    if (
      query.mapsTo !== null &&
      (cls === null ? null : cls.mapsTo) !== query.mapsTo
    ) {
      return false;
    }
    if (
      query.detailedIn !== null &&
      (cls === null ? null : cls.detailedIn) !== query.detailedIn
    ) {
      return false;
    }
    return true;
  }

  /**
   * The value-reading dimensions (text / state), re-evaluated against the live
   * document. Returns the built match (with snippet/spans) or `null` when the
   * node no longer satisfies the query. Assumes the path is structurally valid.
   *
   * @internal Library-private in the Dart reference (`_evaluateLive`); the
   * cursor in this module is its only caller.
   */
  _evaluateLive(
    query: SpecQuery,
    pattern: SomTextPattern | null,
    path: string,
  ): SpecQueryMatch | null {
    if (!this._isLivePath(path)) {
      return null;
    }
    const resolution = this._reflection.resolve(path);
    if (resolution === null) {
      return null;
    }

    if (query.state !== null) {
      const hasValue = this.document.hasValuesUnder(path);
      const wantValue = query.state === SpecStateFilter.NON_EMPTY;
      if (hasValue !== wantValue) {
        return null;
      }
    }

    let snippet: string | null = null;
    let spans: SpecMatchSpan[] = [];
    if (pattern !== null) {
      const hit = this._matchText(pattern, resolution);
      if (hit === null) {
        return null;
      }
      snippet = hit.snippet;
      spans = hit.spans;
    }

    const cls = resolution.targetClass;
    return new SpecQueryMatch({
      path,
      kind: resolution.kind,
      classId: cls !== null ? cls.name : null,
      headline: this._headlineOf(resolution),
      snippet,
      matchSpans: spans,
    });
  }

  private _matchText(
    pattern: SomTextPattern,
    resolution: SpecResolution,
  ): _TextHit | null {
    // Search each candidate string in turn; the first that hits wins, so the
    // snippet is the actual text the pattern matched.
    for (const text of this._searchableStrings(resolution)) {
      const spans = this._spansIn(pattern, text);
      if (spans.length > 0) {
        return { snippet: text, spans };
      }
    }
    return null;
  }

  /**
   * The strings a `text` query searches at `resolution`: stored values first
   * (content leaf, scalar list item, every form field), then the node's
   * headline.
   */
  private *_searchableStrings(resolution: SpecResolution): Generator<string> {
    const path = resolution.path;
    switch (resolution.kind) {
      case SpecNodeKind.CONTENT:
      case SpecNodeKind.ENUM_VALUE:
      case SpecNodeKind.SCALAR:
      case SpecNodeKind.LIST_ITEM_SCALAR: {
        const value = this.document.content(path);
        if (value !== null) {
          yield value;
        }
        break;
      }
      case SpecNodeKind.FORM:
        for (const name of this.document.formFieldNames(path)) {
          const value = this.document.formField(path, name);
          if (value !== null) {
            yield value;
          }
        }
        break;
      default:
        break; // container nodes carry no direct value
    }
    const headline = this._headlineOf(resolution);
    if (headline !== null) {
      yield headline;
    }
  }

  private _patternFor(query: SpecQuery): SomTextPattern {
    const text = query.text as string;
    return query.regex
      ? SomTextPattern.compile(text, query.caseInsensitive)
      : SomTextPattern.literal(text, query.caseInsensitive);
  }

  private _spansIn(pattern: SomTextPattern, text: string): SpecMatchSpan[] {
    return pattern.allMatches(text);
  }

  // --- path liveness (cursor stability) -----------------------------------

  /**
   * Whether `path` still exists in the live document: every `-<seq>` list-item
   * segment must still be present in its parent list. Model-fixed segments
   * (root, complex/section, declared leaves) are always structurally live, so
   * only list items can go stale (via {@link SpecDocument.removeListItem}).
   */
  private _isLivePath(path: string): boolean {
    const segments = specPathSegments(path);
    let prefix = '';
    for (let i = 0; i < segments.length; i++) {
      const previous = prefix;
      prefix = i === 0 ? segments[i] : specPathJoin(prefix, segments[i]);
      const split = splitListItemSegment(segments[i]);
      if (split === null) {
        continue;
      }
      const listPath = i === 0 ? split.base : specPathJoin(previous, split.base);
      const resolution = this._reflection.resolve(listPath);
      if (
        resolution !== null &&
        resolution.kind === SpecNodeKind.LIST &&
        this.document.listItems(listPath).indexOf(prefix) < 0
      ) {
        return false;
      }
    }
    return true;
  }

  // --- node descriptors ----------------------------------------------------

  private _sectionIdOf(resolution: SpecResolution): string | null {
    const field = resolution.field;
    if (field !== null && field.sectionId !== null) {
      return field.sectionId;
    }
    const cls = resolution.targetClass;
    if (cls !== null && cls.sectionId !== null) {
      return cls.sectionId;
    }
    return resolution.root.sectionId;
  }

  /**
   * The headline a node actually shows: the document's **stored** headline
   * when the author set one, otherwise the model's doc comment.
   *
   * The stored value comes first because it is the one a reader sees and the
   * one an author would search for. Consulting only the doc comment made
   * renamed sections unfindable — `setHeadline('DEMO/SUM', 'Executive
   * Summary')` stored text that no query could reach and that never entered
   * the search index built from {@link projectNodes}.
   */
  private _headlineOf(resolution: SpecResolution): string | null {
    const stored = this.document.headline(resolution.path);
    if (stored !== null) {
      return stored;
    }
    const field = resolution.field;
    if (field !== null && field.doc !== null) {
      return field.doc;
    }
    const cls = resolution.targetClass;
    if (cls !== null && cls.doc !== null) {
      return cls.doc;
    }
    return resolution.kind === SpecNodeKind.ROOT
      ? resolution.root.description
      : null;
  }

  /**
   * Glob match over a whole path: `**` spans `/`, a single `*` stays within
   * one segment, every other character is literal.
   *
   * Matched directly rather than compiled to a regex, because two of the nine
   * runtimes have no regex engine and because a wildcard walk is a smaller,
   * more obviously identical thing to transcribe than an escaping rule plus
   * somebody else's matcher (see {@link SomTextPattern}).
   */
  private _globMatches(glob: string, path: string): boolean {
    return this._globAt(_codeUnits(glob), 0, _codeUnits(path), 0);
  }

  /**
   * Greedy wildcard walk with backtracking: at a `*`/`**` try the longest
   * remaining span first and give characters back until the tail fits.
   */
  private _globAt(
    glob: number[],
    g: number,
    path: number[],
    p: number,
  ): boolean {
    while (g < glob.length) {
      if (glob[g] !== _K_ASTERISK) {
        if (p >= path.length || path[p] !== glob[g]) {
          return false;
        }
        g++;
        p++;
        continue;
      }
      const crossesSegments = g + 1 < glob.length && glob[g + 1] === _K_ASTERISK;
      const afterWildcard = g + (crossesSegments ? 2 : 1);
      // Longest first, so `*` behaves greedily exactly as the regex did.
      let limit = path.length;
      if (!crossesSegments) {
        for (let i = p; i < path.length; i++) {
          if (path[i] === _K_SLASH) {
            limit = i;
            break;
          }
        }
      }
      for (let take = limit; take >= p; take--) {
        if (this._globAt(glob, afterWildcard, path, take)) {
          return true;
        }
      }
      return false;
    }
    return p === path.length;
  }
}

const _K_ASTERISK = 0x2a; // *
const _K_SLASH = 0x2f; // /

/** The UTF-16 code units of `s` — the equivalent of Dart's `String.codeUnits`. */
function _codeUnits(s: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < s.length; i++) {
    out.push(s.charCodeAt(i));
  }
  return out;
}

/**
 * A lazy, forward-only cursor over the nodes matching a {@link SpecQuery}
 * (llm_and_d4rt_tools.md §6).
 *
 * The cursor holds the structural candidate paths captured when it was created;
 * each step re-validates the path against the **live** document and re-applies
 * the value-dependent filters, so concurrent edits never surface stale or
 * newly-mismatching results. It is forward-only: {@link next} / {@link take}
 * consume matches; {@link count} peeks the remaining matches without consuming.
 *
 * Constructed by {@link SpecQueryEngine.query} — the Dart reference's `._`
 * constructor, which TypeScript cannot express without also hiding it from the
 * engine.
 */
export class SpecQueryCursor {
  private _engine: SpecQueryEngine;
  private _query: SpecQuery;

  /** The query's `text` dimension, compiled once when the cursor was built.
   * `null` when the query has no text dimension at all. */
  private _pattern: SomTextPattern | null;
  private _candidatePaths: string[];
  private _position = 0;

  constructor(
    engine: SpecQueryEngine,
    query: SpecQuery,
    pattern: SomTextPattern | null,
    candidatePaths: string[],
  ) {
    this._engine = engine;
    this._query = query;
    this._pattern = pattern;
    this._candidatePaths = candidatePaths;
  }

  /**
   * The next matching node, or `null` when the cursor is exhausted. Skips
   * candidates whose path went stale or no longer satisfies the live filters.
   */
  next(): SpecQueryMatch | null {
    while (this._position < this._candidatePaths.length) {
      const path = this._candidatePaths[this._position++];
      const match = this._engine._evaluateLive(this._query, this._pattern, path);
      if (match !== null) {
        return match;
      }
    }
    return null;
  }

  /** Up to `n` further matches (fewer when the cursor is exhausted first). */
  take(n: number): SpecQueryMatch[] {
    const out: SpecQueryMatch[] = [];
    for (let i = 0; i < n; i++) {
      const match = this.next();
      if (match === null) {
        break;
      }
      out.push(match);
    }
    return out;
  }

  /** Every remaining match, draining the cursor. */
  toList(): SpecQueryMatch[] {
    const out: SpecQueryMatch[] = [];
    let match = this.next();
    while (match !== null) {
      out.push(match);
      match = this.next();
    }
    return out;
  }

  /**
   * How many matches remain from the current position, without consuming any.
   * Re-validates each remaining candidate against the live document, so the
   * count reflects the document as it is *now*.
   */
  get count(): number {
    let remaining = 0;
    for (let i = this._position; i < this._candidatePaths.length; i++) {
      if (
        this._engine._evaluateLive(
          this._query,
          this._pattern,
          this._candidatePaths[i],
        ) !== null
      ) {
        remaining++;
      }
    }
    return remaining;
  }
}
