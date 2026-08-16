'use strict';

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
 * {@link SpecQueryEngine#query} returns a {@link SpecQueryCursor} the caller
 * iterates lazily (`next` / `take` / `count`). The cursor captures the
 * **structural** candidate set when it is created, then **re-validates each
 * path against the live document on every step** — so a result whose list-item
 * ancestor was removed after the cursor was made is silently skipped (stable
 * against concurrent edits, llm_and_d4rt_tools.md §6).
 */

const { SpecFieldKind } = require('./spec_model');
const { specPathJoin, specPathSegments, splitListItemSegment } = require('./spec_paths');
const { SpecNodeKind, SpecReflection } = require('./spec_reflection');
const { SpecSerializationOrder } = require('./spec_serialization_order');
const { SomTextPattern } = require('./spec_text_pattern');

/** Whether a node currently holds a value, used by the `state` dimension. */
const SpecStateFilter = Object.freeze({
  /** The node (and everything beneath it) holds no value. */
  EMPTY: 'empty',

  /** The node holds at least one value at or beneath its path. */
  NON_EMPTY: 'nonEmpty',
});

/**
 * A flat, value-bearing projection of one document node — everything the
 * tier-1 structural/lexical index (`llm_and_d4rt_tools.md` §9.2) needs to
 * index a section **without re-walking the model itself**: its path, kind,
 * class, the structural facets (section id, `@MapsTo` / `@DetailedIn`), the
 * headline, the searchable strings (stored values + headline), and whether it
 * currently holds a value.
 *
 * Produced by {@link SpecQueryEngine#projectNodes} /
 * {@link SpecQueryEngine#projectNode}, which reuse the same structural-closure
 * walk and value-extraction the live query uses — so the index and the live
 * llm_and_d4rt_tools.md §6 search agree on what a node is and what text it
 * carries — with no model (LLM) calls.
 */
class SpecNodeProjection {
  constructor({
    path,
    kind,
    classId = null,
    sectionId = null,
    mapsTo = null,
    detailedIn = null,
    headline = null,
    searchableStrings = [],
    hasValue = false,
  }) {
    /** The globally-unique section-id path the node lives at. */
    this.path = path;
    /** What kind of node the path lands on. */
    this.kind = kind;
    /**
     * The model class the node *is* (`null` for value leaves and list
     * containers).
     */
    this.classId = classId;
    /** The node's `@SectionId` (field, class, or root), `null` when none. */
    this.sectionId = sectionId;
    /** The `@MapsTo` target on the node's class, `null` when none. */
    this.mapsTo = mapsTo;
    /** The `@DetailedIn` target on the node's class, `null` when none. */
    this.detailedIn = detailedIn;
    /**
     * The node's headline — the stored one when the author set it, else the
     * model's doc comment. `null` when neither exists.
     */
    this.headline = headline;
    /**
     * The strings a text search indexes for this node: stored values (content,
     * scalar item, every form-field value) followed by the headline. Empty for
     * a container node that carries no direct value and has no headline.
     * @type {string[]}
     */
    this.searchableStrings = searchableStrings;
    /**
     * Whether the node (or anything beneath it) currently holds a value — the
     * `state` facet (empty vs non-empty).
     */
    this.hasValue = hasValue;
  }

  toString() {
    return `SpecNodeProjection(${this.path}, ${this.kind})`;
  }
}

/**
 * One node matched by a {@link SpecQuery} (the llm_and_d4rt_tools.md §6 cursor
 * record).
 */
class SpecQueryMatch {
  constructor({ path, kind, classId = null, headline = null, snippet = null, matchSpans = [] }) {
    /** The globally-unique section-ID path the node lives at. */
    this.path = path;
    /** What kind of node the path lands on. */
    this.kind = kind;
    /**
     * The model class the node *is* (`null` for value leaves and list
     * containers).
     */
    this.classId = classId;
    /**
     * The node's headline — stored if the author set one, else the model's doc
     * comment (`null` when neither exists).
     */
    this.headline = headline;
    /**
     * The matched text, when the query carried a `text` dimension (`null`
     * otherwise) — the value/headline that the pattern hit.
     */
    this.snippet = snippet;
    /**
     * The spans within {@link snippet} the `text` pattern matched (empty for
     * non-text queries).
     * @type {import('./spec_text_pattern').SpecMatchSpan[]}
     */
    this.matchSpans = matchSpans;
  }

  toString() {
    return `SpecQueryMatch(${this.path}, ${this.kind})`;
  }
}

/**
 * An AND-combined lexical/structural query (llm_and_d4rt_tools.md §6). Every
 * supplied dimension must hold for a node to match; an all-`null` query matches
 * every node in the document's structural closure.
 */
class SpecQuery {
  constructor({
    text = null,
    regex = false,
    caseInsensitive = false,
    kinds = null,
    className = null,
    sectionIdExact = null,
    sectionIdPrefix = null,
    pathGlob = null,
    mapsTo = null,
    detailedIn = null,
    state = null,
  } = {}) {
    /**
     * Substring (or {@link regex} pattern) to find in content + form values and
     * the headline.
     */
    this.text = text;
    /**
     * Treat {@link text} as a {@link SomTextPattern} — the portable pattern
     * subset (`.`, `*`, `+`, `?`, `[…]`, `^`, `$`) — instead of a literal
     * substring. Named `regex` because that is what a caller reaches for it
     * expecting; the grammar is deliberately narrower than a full regex, and
     * {@link SomPatternError} says so rather than silently reinterpreting.
     */
    this.regex = regex;
    /** Match {@link text} case-insensitively. */
    this.caseInsensitive = caseInsensitive;
    /**
     * The node kinds to include (any-of); `null` admits every kind.
     * @type {?Set<string>}
     */
    this.kinds = kinds;
    /** The model class name a node must *be* (`SpecResolution.targetClass`). */
    this.className = className;
    /** The node's `@SectionId` must equal this exactly. */
    this.sectionIdExact = sectionIdExact;
    /** The node's `@SectionId` must start with this prefix. */
    this.sectionIdPrefix = sectionIdPrefix;
    /**
     * A glob over the node's path (`*` matches within one segment, `**` across
     * segments).
     */
    this.pathGlob = pathGlob;
    /** The node's class must carry `@MapsTo(<this>)`. */
    this.mapsTo = mapsTo;
    /** The node's class must carry `@DetailedIn(<this>)`. */
    this.detailedIn = detailedIn;
    /** The node's value-presence state must match this. */
    this.state = state;
  }
}

/**
 * Runs {@link SpecQuery}s over a ({@link SpecModel}, {@link SpecDocument}) pair,
 * producing {@link SpecQueryCursor}s.
 */
class SpecQueryEngine {
  /**
   * @param {{model: import('./spec_model').SpecModel,
   *          document: import('./spec_document').SpecDocument}} options
   */
  constructor({ model, document }) {
    /** The meta-model describing the document's structure. */
    this.model = model;
    /** The live document whose values are searched. */
    this.document = document;
    this._reflection = new SpecReflection(model);
    /** Model-declaration ordering for form fields — see `_searchableStrings`. */
    this._order = new SpecSerializationOrder(model);
  }

  /**
   * Builds a cursor over the nodes matching `query`. The structural candidate
   * set is computed now (document order); value-dependent filters and path
   * liveness are re-checked as the cursor advances.
   *
   * Throws {@link SomPatternError} when `query.regex` is set and `query.text` is
   * not in the portable subset. The pattern is compiled **here**, not on first
   * use, for two reasons: a malformed pattern is the caller's mistake and should
   * surface at the call that made it, and a cursor that happens to visit no
   * candidate would otherwise swallow the error entirely.
   *
   * @param {SpecQuery} query
   * @returns {SpecQueryCursor}
   */
  query(query) {
    const pattern = query.text === null || query.text === undefined ? null : _patternFor(query);
    const candidates = [];
    for (const path of this._enumeratePaths()) {
      const resolution = this._reflection.resolve(path);
      if (resolution === null) {
        continue;
      }
      if (this._matchesStructural(query, resolution)) {
        candidates.push(path);
      }
    }
    return new SpecQueryCursor({
      engine: this,
      query,
      pattern,
      candidatePaths: candidates,
    });
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
   * @returns {Generator<SpecNodeProjection>}
   */
  *projectNodes() {
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
   *
   * @param {string} path
   * @returns {?SpecNodeProjection}
   */
  projectNode(path) {
    const resolution = this._reflection.resolve(path);
    if (resolution === null) {
      return null;
    }
    const cls = resolution.targetClass;
    return new SpecNodeProjection({
      path,
      kind: resolution.kind,
      classId: cls !== null && cls !== undefined ? cls.name : null,
      sectionId: this._sectionIdOf(resolution),
      mapsTo: cls !== null && cls !== undefined ? cls.mapsTo : null,
      detailedIn: cls !== null && cls !== undefined ? cls.detailedIn : null,
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
   *
   * @returns {Generator<string>}
   */
  *_enumeratePaths() {
    for (const root of this.model.roots) {
      const segment = this._reflection.rootSegment(root);
      yield* this._walk(segment, this.model.classNamed(root.type), new Set([root.type]));
    }
  }

  /**
   * @param {string} path
   * @param {?import('./spec_model').SpecClass} cls
   * @param {Set<string>} ancestorTypes
   * @returns {Generator<string>}
   */
  *_walk(path, cls, ancestorTypes) {
    yield path; // the node itself (root / complex / section container)
    if (cls === null || cls === undefined) {
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
              field.elementType !== undefined &&
              !ancestorTypes.has(field.elementType)
            ) {
              yield* this._walk(
                itemPath,
                this.model.classNamed(field.elementType),
                new Set([...ancestorTypes, field.elementType]),
              );
            } else {
              yield itemPath; // scalar item, or a recursive/unknown element
            }
          }
          break;
        case SpecFieldKind.COMPLEX:
        case SpecFieldKind.SECTION:
          if (field.type !== null && field.type !== undefined && !ancestorTypes.has(field.type)) {
            yield* this._walk(
              fieldPath,
              this.model.classNamed(field.type),
              new Set([...ancestorTypes, field.type]),
            );
          } else {
            yield fieldPath; // recursive/unknown target: a terminal node
          }
          break;
        default:
          break;
      }
    }
  }

  // --- predicates ----------------------------------------------------------

  /**
   * The model-fixed dimensions (kind / class / id / path / mapsTo / detailedIn).
   *
   * @param {SpecQuery} query
   * @param {import('./spec_reflection').SpecResolution} resolution
   * @returns {boolean}
   */
  _matchesStructural(query, resolution) {
    const cls = resolution.targetClass;
    if (query.kinds !== null && query.kinds !== undefined && !query.kinds.has(resolution.kind)) {
      return false;
    }
    if (query.className !== null && query.className !== undefined) {
      if ((cls !== null && cls !== undefined ? cls.name : null) !== query.className) {
        return false;
      }
    }

    const sectionId = this._sectionIdOf(resolution);
    if (
      query.sectionIdExact !== null &&
      query.sectionIdExact !== undefined &&
      sectionId !== query.sectionIdExact
    ) {
      return false;
    }
    if (query.sectionIdPrefix !== null && query.sectionIdPrefix !== undefined) {
      if (sectionId === null || !sectionId.startsWith(query.sectionIdPrefix)) {
        return false;
      }
    }
    if (
      query.pathGlob !== null &&
      query.pathGlob !== undefined &&
      !this._globMatches(query.pathGlob, resolution.path)
    ) {
      return false;
    }
    if (query.mapsTo !== null && query.mapsTo !== undefined) {
      if ((cls !== null && cls !== undefined ? cls.mapsTo : null) !== query.mapsTo) {
        return false;
      }
    }
    if (query.detailedIn !== null && query.detailedIn !== undefined) {
      if ((cls !== null && cls !== undefined ? cls.detailedIn : null) !== query.detailedIn) {
        return false;
      }
    }
    return true;
  }

  /**
   * The value-reading dimensions (text / state), re-evaluated against the live
   * document. Returns the built match (with snippet/spans) or `null` when the
   * node no longer satisfies the query. Assumes the path is structurally valid.
   *
   * @param {SpecQuery} query
   * @param {?SomTextPattern} pattern
   * @param {string} path
   * @returns {?SpecQueryMatch}
   */
  _evaluateLive(query, pattern, path) {
    if (!this._isLivePath(path)) {
      return null;
    }
    const resolution = this._reflection.resolve(path);
    if (resolution === null) {
      return null;
    }

    if (query.state !== null && query.state !== undefined) {
      const hasValue = this.document.hasValuesUnder(path);
      const wantValue = query.state === SpecStateFilter.NON_EMPTY;
      if (hasValue !== wantValue) {
        return null;
      }
    }

    let snippet = null;
    let spans = [];
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
      classId: cls !== null && cls !== undefined ? cls.name : null,
      headline: this._headlineOf(resolution),
      snippet,
      matchSpans: spans,
    });
  }

  /**
   * @param {SomTextPattern} pattern
   * @param {import('./spec_reflection').SpecResolution} resolution
   * @returns {?{snippet: string, spans: import('./spec_text_pattern').SpecMatchSpan[]}}
   */
  _matchText(pattern, resolution) {
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
   *
   * Form fields are yielded in **model declaration order** (SOM §9,
   * "Form-field order"), never in the document's storage order, via
   * `SpecSerializationOrder.orderFormFields`. The order is observable: it
   * decides which string a `text` query reports as its snippet, and it is
   * pinned verbatim by `projection_cases.json`. A field the document holds but
   * the model does not declare is still yielded — dropping a stored value from
   * a text search would hide it — but last and sorted.
   *
   * @param {import('./spec_reflection').SpecResolution} resolution
   * @returns {Generator<string>}
   */
  *_searchableStrings(resolution) {
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
        for (const name of this._order.orderFormFields(
          path,
          this.document.formFieldNames(path),
        )) {
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

  /**
   * @param {SomTextPattern} pattern
   * @param {string} text
   * @returns {import('./spec_text_pattern').SpecMatchSpan[]}
   */
  _spansIn(pattern, text) {
    return pattern.allMatches(text);
  }

  // --- path liveness (cursor stability) -----------------------------------

  /**
   * Whether `path` still exists in the live document: every `-<seq>` list-item
   * segment must still be present in its parent list. Model-fixed segments
   * (root, complex/section, declared leaves) are always structurally live, so
   * only list items can go stale (via `SpecDocument#removeListItem`).
   *
   * @param {string} path
   * @returns {boolean}
   */
  _isLivePath(path) {
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
        !this.document.listItems(listPath).includes(prefix)
      ) {
        return false;
      }
    }
    return true;
  }

  // --- node descriptors ----------------------------------------------------

  /**
   * @param {import('./spec_reflection').SpecResolution} resolution
   * @returns {?string}
   */
  _sectionIdOf(resolution) {
    const fromField = resolution.field !== null ? resolution.field.sectionId : null;
    if (fromField !== null && fromField !== undefined) {
      return fromField;
    }
    const fromClass = resolution.targetClass !== null ? resolution.targetClass.sectionId : null;
    if (fromClass !== null && fromClass !== undefined) {
      return fromClass;
    }
    const fromRoot = resolution.root.sectionId;
    return fromRoot === undefined ? null : fromRoot;
  }

  /**
   * The headline a node actually shows: the document's **stored** headline when
   * the author set one, otherwise the model's doc comment.
   *
   * The stored value comes first because it is the one a reader sees and the one
   * an author would search for. Consulting only the doc comment made renamed
   * sections unfindable — `setHeadline('DEMO/SUM', 'Executive Summary')` stored
   * text that no query could reach and that never entered the search index built
   * from {@link SpecQueryEngine#projectNodes}.
   *
   * @param {import('./spec_reflection').SpecResolution} resolution
   * @returns {?string}
   */
  _headlineOf(resolution) {
    const stored = this.document.headline(resolution.path);
    if (stored !== null && stored !== undefined) {
      return stored;
    }
    const fieldDoc = resolution.field !== null ? resolution.field.doc : null;
    if (fieldDoc !== null && fieldDoc !== undefined) {
      return fieldDoc;
    }
    const classDoc = resolution.targetClass !== null ? resolution.targetClass.doc : null;
    if (classDoc !== null && classDoc !== undefined) {
      return classDoc;
    }
    if (resolution.kind === SpecNodeKind.ROOT) {
      const description = resolution.root.description;
      return description === undefined ? null : description;
    }
    return null;
  }

  /**
   * Glob match over a whole path: `**` spans `/`, a single `*` stays within one
   * segment, every other character is literal.
   *
   * Matched directly rather than compiled to a regex, because two of the nine
   * runtimes have no regex engine and because a wildcard walk is a smaller, more
   * obviously identical thing to transcribe than an escaping rule plus somebody
   * else's matcher (see {@link SomTextPattern}).
   *
   * @param {string} glob
   * @param {string} path
   * @returns {boolean}
   */
  _globMatches(glob, path) {
    return this._globAt(_codeUnits(glob), 0, _codeUnits(path), 0);
  }

  /**
   * Greedy wildcard walk with backtracking: at a `*`/`**` try the longest
   * remaining span first and give characters back until the tail fits.
   *
   * @param {number[]} glob
   * @param {number} g
   * @param {number[]} path
   * @param {number} p
   * @returns {boolean}
   */
  _globAt(glob, g, path, p) {
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

/**
 * The UTF-16 code units of `text` (the glob walk compares code units, as the
 * Dart reference does).
 *
 * @param {string} text
 * @returns {number[]}
 */
function _codeUnits(text) {
  const units = [];
  for (let i = 0; i < text.length; i++) {
    units.push(text.charCodeAt(i));
  }
  return units;
}

/**
 * @param {SpecQuery} query
 * @returns {SomTextPattern}
 */
function _patternFor(query) {
  return query.regex
    ? SomTextPattern.compile(query.text, { caseInsensitive: query.caseInsensitive })
    : SomTextPattern.literal(query.text, { caseInsensitive: query.caseInsensitive });
}

/**
 * A lazy, forward-only cursor over the nodes matching a {@link SpecQuery}
 * (llm_and_d4rt_tools.md §6).
 *
 * The cursor holds the structural candidate paths captured when it was created;
 * each step re-validates the path against the **live** document and re-applies
 * the value-dependent filters, so concurrent edits never surface stale or
 * newly-mismatching results. It is forward-only: {@link SpecQueryCursor#next} /
 * {@link SpecQueryCursor#take} consume matches; {@link SpecQueryCursor#count}
 * peeks the remaining matches without consuming.
 *
 * Built by {@link SpecQueryEngine#query}; not constructed directly.
 */
class SpecQueryCursor {
  /**
   * @param {{engine: SpecQueryEngine, query: SpecQuery,
   *          pattern: ?SomTextPattern, candidatePaths: string[]}} options
   */
  constructor({ engine, query, pattern, candidatePaths }) {
    this._engine = engine;
    this._query = query;
    /**
     * The query's `text` dimension, compiled once when the cursor was built.
     * `null` when the query has no text dimension at all.
     */
    this._pattern = pattern;
    this._candidatePaths = candidatePaths;
    this._position = 0;
  }

  /**
   * The next matching node, or `null` when the cursor is exhausted. Skips
   * candidates whose path went stale or no longer satisfies the live filters.
   *
   * @returns {?SpecQueryMatch}
   */
  next() {
    while (this._position < this._candidatePaths.length) {
      const path = this._candidatePaths[this._position++];
      const match = this._engine._evaluateLive(this._query, this._pattern, path);
      if (match !== null) {
        return match;
      }
    }
    return null;
  }

  /**
   * Up to `n` further matches (fewer when the cursor is exhausted first).
   *
   * @param {number} n
   * @returns {SpecQueryMatch[]}
   */
  take(n) {
    const out = [];
    for (let i = 0; i < n; i++) {
      const match = this.next();
      if (match === null) {
        break;
      }
      out.push(match);
    }
    return out;
  }

  /**
   * Every remaining match, draining the cursor.
   *
   * @returns {SpecQueryMatch[]}
   */
  toList() {
    const out = [];
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
   *
   * @returns {number}
   */
  get count() {
    let remaining = 0;
    for (let i = this._position; i < this._candidatePaths.length; i++) {
      if (this._engine._evaluateLive(this._query, this._pattern, this._candidatePaths[i]) !== null) {
        remaining++;
      }
    }
    return remaining;
  }
}

module.exports = {
  SpecStateFilter,
  SpecNodeProjection,
  SpecQueryMatch,
  SpecQuery,
  SpecQueryEngine,
  SpecQueryCursor,
};
