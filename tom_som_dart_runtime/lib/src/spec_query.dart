/// Lexical/structural query + lazy cursor over a live [SpecDocument]
/// (`llm_and_d4rt_tools.md` §6, `som_multiplatform_spec_model.md` §15).
///
/// This is the **grep-like** facility the downstream D4rt scripting layer and
/// the editor's search tools reuse. It is **embedding-free** — exact substring
/// or [SomTextPattern] match plus structural filters — so it is always current
/// and needs no model calls.
///
/// A [SpecQuery] composes (AND-combined) over five dimensions:
///   * **text** — substring or [SomTextPattern] over content + form-field
///     values and over a node's headline, stored or doc-comment (optionally
///     case-insensitive);
///   * **kind** — one or more [SpecNodeKind]s;
///   * **class** — the model class a node *is* (by class name);
///   * **id / path** — exact `@SectionId`, `@SectionId` prefix, path glob, or a
///     `@MapsTo` / `@DetailedIn` target on the node's class;
///   * **state** — empty / non-empty (the structural "empty = no value" test).
///
/// [SpecQueryEngine.query] returns a [SpecQueryCursor] the caller iterates
/// lazily (`next` / `take` / `count`). The cursor captures the **structural**
/// candidate set when it is created, then **re-validates each path against the
/// live document on every step** — so a result whose list-item ancestor was
/// removed after the cursor was made is silently skipped (stable against
/// concurrent edits, llm_and_d4rt_tools.md §6).
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';
import 'spec_text_pattern.dart';

/// Whether a node currently holds a value, used by the `state` dimension.
enum SpecStateFilter {
  /// The node (and everything beneath it) holds no value.
  empty,

  /// The node holds at least one value at or beneath its path.
  nonEmpty,
}

/// A flat, value-bearing projection of one document node — everything the
/// tier-1 structural/lexical index (`llm_and_d4rt_tools.md` §9.2) needs to
/// index a section **without re-walking the model itself**: its path, kind,
/// class, the structural facets (section id, `@MapsTo` / `@DetailedIn`), the
/// headline, the searchable strings (stored values + headline), and whether it
/// currently holds a value.
///
/// Produced by [SpecQueryEngine.projectNodes] / [SpecQueryEngine.projectNode],
/// which reuse the same structural-closure walk and value-extraction the live
/// query uses — so the index and the live llm_and_d4rt_tools.md §6 search agree
/// on what a node is and what text it carries — with no model (LLM) calls.
class SpecNodeProjection {
  /// The globally-unique section-id path the node lives at.
  final String path;

  /// What kind of node the path lands on.
  final SpecNodeKind kind;

  /// The model class the node *is* (`null` for value leaves and list
  /// containers).
  final String? classId;

  /// The node's `@SectionId` (field, class, or root), `null` when none.
  final String? sectionId;

  /// The `@MapsTo` target on the node's class, `null` when none.
  final String? mapsTo;

  /// The `@DetailedIn` target on the node's class, `null` when none.
  final String? detailedIn;

  /// The node's headline — the stored one when the author set it, else the
  /// model's doc comment. `null` when neither exists.
  final String? headline;

  /// The strings a text search indexes for this node: stored values (content,
  /// scalar item, every form-field value) followed by the headline. Empty for a
  /// container node that carries no direct value and has no headline.
  final List<String> searchableStrings;

  /// Whether the node (or anything beneath it) currently holds a value — the
  /// `state` facet (empty vs non-empty).
  final bool hasValue;

  const SpecNodeProjection({
    required this.path,
    required this.kind,
    this.classId,
    this.sectionId,
    this.mapsTo,
    this.detailedIn,
    this.headline,
    this.searchableStrings = const [],
    this.hasValue = false,
  });

  @override
  String toString() => 'SpecNodeProjection($path, $kind)';
}

/// One node matched by a [SpecQuery] (the llm_and_d4rt_tools.md §6 cursor
/// record).
class SpecQueryMatch {
  /// The globally-unique section-ID path the node lives at.
  final String path;

  /// What kind of node the path lands on.
  final SpecNodeKind kind;

  /// The model class the node *is* (`null` for value leaves and list
  /// containers).
  final String? classId;

  /// The node's headline — stored if the author set one, else the model's doc
  /// comment (`null` when neither exists).
  final String? headline;

  /// The matched text, when the query carried a `text` dimension (`null`
  /// otherwise) — the value/headline that the pattern hit.
  final String? snippet;

  /// The spans within [snippet] the `text` pattern matched (empty for
  /// non-text queries).
  final List<SpecMatchSpan> matchSpans;

  const SpecQueryMatch({
    required this.path,
    required this.kind,
    this.classId,
    this.headline,
    this.snippet,
    this.matchSpans = const [],
  });

  @override
  String toString() => 'SpecQueryMatch($path, $kind)';
}

/// An AND-combined lexical/structural query (llm_and_d4rt_tools.md §6). Every
/// supplied dimension must hold for a node to match; an all-`null` query
/// matches every node in the document's structural closure.
class SpecQuery {
  /// Substring (or [regex] pattern) to find in content + form values and the
  /// headline.
  final String? text;

  /// Treat [text] as a [SomTextPattern] — the portable pattern subset (`.`,
  /// `*`, `+`, `?`, `[…]`, `^`, `$`) — instead of a literal substring. Named
  /// `regex` because that is what a caller reaches for it expecting; the
  /// grammar is deliberately narrower than a full regex, and
  /// [SomPatternError] says so rather than silently reinterpreting.
  final bool regex;

  /// Match [text] case-insensitively.
  final bool caseInsensitive;

  /// The node kinds to include (any-of); `null` admits every kind.
  final Set<SpecNodeKind>? kinds;

  /// The model class name a node must *be* (`SpecResolution.targetClass`).
  final String? className;

  /// The node's `@SectionId` must equal this exactly.
  final String? sectionIdExact;

  /// The node's `@SectionId` must start with this prefix.
  final String? sectionIdPrefix;

  /// A glob over the node's path (`*` matches within one segment, `**` across
  /// segments).
  final String? pathGlob;

  /// The node's class must carry `@MapsTo(<this>)`.
  final String? mapsTo;

  /// The node's class must carry `@DetailedIn(<this>)`.
  final String? detailedIn;

  /// The node's value-presence state must match this.
  final SpecStateFilter? state;

  const SpecQuery({
    this.text,
    this.regex = false,
    this.caseInsensitive = false,
    this.kinds,
    this.className,
    this.sectionIdExact,
    this.sectionIdPrefix,
    this.pathGlob,
    this.mapsTo,
    this.detailedIn,
    this.state,
  });
}

/// Runs [SpecQuery]s over a ([SpecModel], [SpecDocument]) pair, producing
/// [SpecQueryCursor]s.
class SpecQueryEngine {
  /// The meta-model describing the document's structure.
  final SpecModel model;

  /// The live document whose values are searched.
  final SpecDocument document;

  final SpecReflection _reflection;

  SpecQueryEngine({required this.model, required this.document})
      : _reflection = SpecReflection(model);

  /// Builds a cursor over the nodes matching [query]. The structural candidate
  /// set is computed now (document order); value-dependent filters and path
  /// liveness are re-checked as the cursor advances.
  ///
  /// Throws [SomPatternError] when `query.regex` is set and `query.text` is not
  /// in the portable subset. The pattern is compiled **here**, not on first
  /// use, for two reasons: a malformed pattern is the caller's mistake and
  /// should surface at the call that made it, and a cursor that happens to
  /// visit no candidate would otherwise swallow the error entirely.
  SpecQueryCursor query(SpecQuery query) {
    final pattern = query.text == null ? null : _patternFor(query);
    final candidates = <String>[];
    for (final path in _enumeratePaths()) {
      final resolution = _reflection.resolve(path);
      if (resolution == null) continue;
      if (_matchesStructural(query, resolution)) candidates.add(path);
    }
    return SpecQueryCursor._(
      engine: this,
      query: query,
      pattern: pattern,
      candidatePaths: candidates,
    );
  }

  // --- flat node projection (tier-1 index source) -------------------------

  /// Projects every indexable node of the live document (the
  /// llm_and_d4rt_tools.md §6 structural closure) as a flat
  /// [SpecNodeProjection], in document order. Reuses the same walk and value
  /// extraction the query uses, so the index built from these projections and
  /// the live llm_and_d4rt_tools.md §6 search agree on what a node is and what
  /// text it carries. Pure object-model traversal — no model (LLM) calls.
  Iterable<SpecNodeProjection> projectNodes() sync* {
    for (final path in _enumeratePaths()) {
      final projection = projectNode(path);
      if (projection != null) yield projection;
    }
  }

  /// Projects the single node at [path], or `null` when the path no longer
  /// resolves against the model. Used for the index's incremental refresh: a
  /// caller re-projects only the changed section paths.
  SpecNodeProjection? projectNode(String path) {
    final resolution = _reflection.resolve(path);
    if (resolution == null) return null;
    return SpecNodeProjection(
      path: path,
      kind: resolution.kind,
      classId: resolution.targetClass?.name,
      sectionId: _sectionIdOf(resolution),
      mapsTo: resolution.targetClass?.mapsTo,
      detailedIn: resolution.targetClass?.detailedIn,
      headline: _headlineOf(resolution),
      searchableStrings: _searchableStrings(resolution).toList(growable: false),
      hasValue: document.hasValuesUnder(path),
    );
  }

  // --- structural-closure enumeration -------------------------------------

  /// Every addressable node of the document in document order: the root, each
  /// singular complex/section node on the spine (bounded by cycle detection),
  /// each list container, each *existing* list item, and every declared leaf.
  Iterable<String> _enumeratePaths() sync* {
    for (final root in model.roots) {
      final segment = _reflection.rootSegment(root);
      yield* _walk(segment, model.classNamed(root.type), {root.type});
    }
  }

  Iterable<String> _walk(
    String path,
    SpecClass? cls,
    Set<String> ancestorTypes,
  ) sync* {
    yield path; // the node itself (root / complex / section container)
    if (cls == null) return;
    for (final field in cls.fields) {
      final fieldPath = specPathJoin(path, _reflection.fieldSegment(field));
      switch (field.kind) {
        case SpecFieldKind.content:
        case SpecFieldKind.enumValue:
        case SpecFieldKind.scalar:
        case SpecFieldKind.form:
          yield fieldPath; // a value leaf
        case SpecFieldKind.list:
          yield fieldPath; // the list container node
          for (final itemPath in document.listItems(fieldPath)) {
            if (field.elementIsComplex &&
                field.elementType != null &&
                !ancestorTypes.contains(field.elementType)) {
              yield* _walk(
                itemPath,
                model.classNamed(field.elementType),
                {...ancestorTypes, field.elementType!},
              );
            } else {
              yield itemPath; // scalar item, or a recursive/unknown element
            }
          }
        case SpecFieldKind.complex:
        case SpecFieldKind.section:
          if (field.type != null && !ancestorTypes.contains(field.type)) {
            yield* _walk(
              fieldPath,
              model.classNamed(field.type),
              {...ancestorTypes, field.type!},
            );
          } else {
            yield fieldPath; // recursive/unknown target: a terminal node
          }
      }
    }
  }

  // --- predicates ----------------------------------------------------------

  /// The model-fixed dimensions (kind / class / id / path / mapsTo / detailedIn).
  bool _matchesStructural(SpecQuery query, SpecResolution resolution) {
    if (query.kinds != null && !query.kinds!.contains(resolution.kind)) {
      return false;
    }
    if (query.className != null &&
        resolution.targetClass?.name != query.className) {
      return false;
    }

    final sectionId = _sectionIdOf(resolution);
    if (query.sectionIdExact != null && sectionId != query.sectionIdExact) {
      return false;
    }
    if (query.sectionIdPrefix != null &&
        !(sectionId?.startsWith(query.sectionIdPrefix!) ?? false)) {
      return false;
    }
    if (query.pathGlob != null &&
        !_globMatches(query.pathGlob!, resolution.path)) {
      return false;
    }
    if (query.mapsTo != null && resolution.targetClass?.mapsTo != query.mapsTo) {
      return false;
    }
    if (query.detailedIn != null &&
        resolution.targetClass?.detailedIn != query.detailedIn) {
      return false;
    }
    return true;
  }

  /// The value-reading dimensions (text / state), re-evaluated against the live
  /// document. Returns the built match (with snippet/spans) or `null` when the
  /// node no longer satisfies the query. Assumes the path is structurally valid.
  SpecQueryMatch? _evaluateLive(
      SpecQuery query, SomTextPattern? pattern, String path) {
    if (!_isLivePath(path)) return null;
    final resolution = _reflection.resolve(path);
    if (resolution == null) return null;

    if (query.state != null) {
      final hasValue = document.hasValuesUnder(path);
      final wantValue = query.state == SpecStateFilter.nonEmpty;
      if (hasValue != wantValue) return null;
    }

    String? snippet;
    var spans = const <SpecMatchSpan>[];
    if (pattern != null) {
      final hit = _matchText(pattern, resolution);
      if (hit == null) return null;
      snippet = hit.snippet;
      spans = hit.spans;
    }

    return SpecQueryMatch(
      path: path,
      kind: resolution.kind,
      classId: resolution.targetClass?.name,
      headline: _headlineOf(resolution),
      snippet: snippet,
      matchSpans: spans,
    );
  }

  ({String snippet, List<SpecMatchSpan> spans})? _matchText(
    SomTextPattern pattern,
    SpecResolution resolution,
  ) {
    // Search each candidate string in turn; the first that hits wins, so the
    // snippet is the actual text the pattern matched.
    for (final text in _searchableStrings(resolution)) {
      final spans = _spansIn(pattern, text);
      if (spans.isNotEmpty) return (snippet: text, spans: spans);
    }
    return null;
  }

  /// The strings a `text` query searches at [resolution]: stored values first
  /// (content leaf, scalar list item, every form field), then the node's
  /// headline.
  ///
  /// Form fields are yielded in **model declaration order**, never in the
  /// document's storage order. The order is observable — it decides which
  /// string a `text` query reports as its snippet, and it is pinned verbatim by
  /// `projection_cases.json` — so it has to be a property of the model, which
  /// all nine runtimes hold identically. Storage order is not: the same
  /// document reaches memory field-by-field when it is authored but
  /// alphabetically when it is loaded from `state.json`, which would make the
  /// projection depend on how the document arrived.
  ///
  /// A field the document holds but the model does not declare is still
  /// yielded — dropping a stored value from a text search would hide it — but
  /// last and sorted, so an undeclared field cannot make the order arbitrary
  /// either.
  Iterable<String> _searchableStrings(SpecResolution resolution) sync* {
    final path = resolution.path;
    switch (resolution.kind) {
      case SpecNodeKind.content:
      case SpecNodeKind.enumValue:
      case SpecNodeKind.scalar:
      case SpecNodeKind.listItemScalar:
        final value = document.content(path);
        if (value != null) yield value;
      case SpecNodeKind.form:
        for (final name in _formFieldOrder(resolution)) {
          final value = document.formField(path, name);
          if (value != null) yield value;
        }
      case SpecNodeKind.root:
      case SpecNodeKind.complex:
      case SpecNodeKind.section:
      case SpecNodeKind.list:
      case SpecNodeKind.listItemComplex:
        break; // container nodes carry no direct value
    }
    final headline = _headlineOf(resolution);
    if (headline != null) yield headline;
  }

  /// The form-field names at [resolution], model-declared ones first in
  /// declaration order, then any the document holds but the model does not
  /// declare, sorted. See [_searchableStrings] for why the order is fixed here
  /// rather than taken from the document.
  Iterable<String> _formFieldOrder(SpecResolution resolution) sync* {
    final declared = resolution.field?.formFields ?? const <FormFieldSpec>[];
    final seen = <String>{};
    for (final ff in declared) {
      seen.add(ff.name);
      yield ff.name;
    }
    final extra = document
        .formFieldNames(resolution.path)
        .where((n) => !seen.contains(n))
        .toList()
      ..sort();
    yield* extra;
  }

  SomTextPattern _patternFor(SpecQuery query) => query.regex
      ? SomTextPattern.compile(query.text!,
          caseInsensitive: query.caseInsensitive)
      : SomTextPattern.literal(query.text!,
          caseInsensitive: query.caseInsensitive);

  List<SpecMatchSpan> _spansIn(SomTextPattern pattern, String text) =>
      pattern.allMatches(text);

  // --- path liveness (cursor stability) -----------------------------------

  /// Whether [path] still exists in the live document: every `-<seq>` list-item
  /// segment must still be present in its parent list. Model-fixed segments
  /// (root, complex/section, declared leaves) are always structurally live, so
  /// only list items can go stale (via [SpecDocument.removeListItem]).
  bool _isLivePath(String path) {
    final segments = specPathSegments(path);
    var prefix = '';
    for (var i = 0; i < segments.length; i++) {
      final previous = prefix;
      prefix = i == 0 ? segments[i] : specPathJoin(prefix, segments[i]);
      final split = splitListItemSegment(segments[i]);
      if (split == null) continue;
      final listPath = i == 0 ? split.base : specPathJoin(previous, split.base);
      final resolution = _reflection.resolve(listPath);
      if (resolution?.kind == SpecNodeKind.list &&
          !document.listItems(listPath).contains(prefix)) {
        return false;
      }
    }
    return true;
  }

  // --- node descriptors ----------------------------------------------------

  String? _sectionIdOf(SpecResolution resolution) =>
      resolution.field?.sectionId ??
      resolution.targetClass?.sectionId ??
      resolution.root.sectionId;

  /// The headline a node actually shows: the document's **stored** headline
  /// when the author set one, otherwise the model's doc comment.
  ///
  /// The stored value comes first because it is the one a reader sees and the
  /// one an author would search for. Consulting only the doc comment made
  /// renamed sections unfindable — `setHeadline('DEMO/SUM', 'Executive
  /// Summary')` stored text that no query could reach and that never entered
  /// the search index built from [projectNodes].
  String? _headlineOf(SpecResolution resolution) =>
      document.headline(resolution.path) ??
      resolution.field?.doc ??
      resolution.targetClass?.doc ??
      (resolution.kind == SpecNodeKind.root ? resolution.root.description : null);

  /// Glob match over a whole path: `**` spans `/`, a single `*` stays within
  /// one segment, every other character is literal.
  ///
  /// Matched directly rather than compiled to a regex, because two of the nine
  /// runtimes have no regex engine and because a wildcard walk is a smaller,
  /// more obviously identical thing to transcribe than an escaping rule plus
  /// somebody else's matcher (see [SomTextPattern]).
  bool _globMatches(String glob, String path) =>
      _globAt(glob.codeUnits, 0, path.codeUnits, 0);

  /// Greedy wildcard walk with backtracking: at a `*`/`**` try the longest
  /// remaining span first and give characters back until the tail fits.
  bool _globAt(List<int> glob, int g, List<int> path, int p) {
    while (g < glob.length) {
      if (glob[g] != _kAsterisk) {
        if (p >= path.length || path[p] != glob[g]) return false;
        g++;
        p++;
        continue;
      }
      final crossesSegments = g + 1 < glob.length && glob[g + 1] == _kAsterisk;
      final afterWildcard = g + (crossesSegments ? 2 : 1);
      // Longest first, so `*` behaves greedily exactly as the regex did.
      var limit = path.length;
      if (!crossesSegments) {
        for (var i = p; i < path.length; i++) {
          if (path[i] == _kSlash) {
            limit = i;
            break;
          }
        }
      }
      for (var take = limit; take >= p; take--) {
        if (_globAt(glob, afterWildcard, path, take)) return true;
      }
      return false;
    }
    return p == path.length;
  }
}

const int _kAsterisk = 0x2A; // *
const int _kSlash = 0x2F; // /

/// A lazy, forward-only cursor over the nodes matching a [SpecQuery]
/// (llm_and_d4rt_tools.md §6).
///
/// The cursor holds the structural candidate paths captured when it was created;
/// each step re-validates the path against the **live** document and re-applies
/// the value-dependent filters, so concurrent edits never surface stale or
/// newly-mismatching results. It is forward-only: [next] / [take] consume
/// matches; [count] peeks the remaining matches without consuming.
class SpecQueryCursor {
  final SpecQueryEngine _engine;
  final SpecQuery _query;

  /// The query's `text` dimension, compiled once when the cursor was built.
  /// `null` when the query has no text dimension at all.
  final SomTextPattern? _pattern;
  final List<String> _candidatePaths;
  int _position = 0;

  SpecQueryCursor._({
    required SpecQueryEngine engine,
    required SpecQuery query,
    required SomTextPattern? pattern,
    required List<String> candidatePaths,
  })  : _engine = engine,
        _query = query,
        _pattern = pattern,
        _candidatePaths = candidatePaths;

  /// The next matching node, or `null` when the cursor is exhausted. Skips
  /// candidates whose path went stale or no longer satisfies the live filters.
  SpecQueryMatch? next() {
    while (_position < _candidatePaths.length) {
      final path = _candidatePaths[_position++];
      final match = _engine._evaluateLive(_query, _pattern, path);
      if (match != null) return match;
    }
    return null;
  }

  /// Up to [n] further matches (fewer when the cursor is exhausted first).
  List<SpecQueryMatch> take(int n) {
    final out = <SpecQueryMatch>[];
    for (var i = 0; i < n; i++) {
      final match = next();
      if (match == null) break;
      out.add(match);
    }
    return out;
  }

  /// Every remaining match, draining the cursor.
  List<SpecQueryMatch> toList() {
    final out = <SpecQueryMatch>[];
    SpecQueryMatch? match;
    while ((match = next()) != null) {
      out.add(match!);
    }
    return out;
  }

  /// How many matches remain from the current position, without consuming any.
  /// Re-validates each remaining candidate against the live document, so the
  /// count reflects the document as it is *now*.
  int get count {
    var remaining = 0;
    for (var i = _position; i < _candidatePaths.length; i++) {
      if (_engine._evaluateLive(_query, _pattern, _candidatePaths[i]) != null) {
        remaining++;
      }
    }
    return remaining;
  }
}
