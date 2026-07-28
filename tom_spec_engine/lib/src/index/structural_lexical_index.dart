/// The **tier-1 structural/lexical index** behind the `llm_and_d4rt_tools.md`
/// §6 search facility (`llm_and_d4rt_tools.md` §9.2).
///
/// An inverted text index (BM25) plus structural facets (section id, kind,
/// class, `@MapsTo` / `@DetailedIn`, value state) built **directly from the
/// object model** — via [SpecNodeProjection]s produced by
/// [SpecQueryEngine.projectNodes] — with **zero model (LLM) calls**. It is the
/// "always current, cheap" half of the two-tier memory: refreshed
/// **incrementally** over the sections that changed after each prompt
/// ([update]), never a full re-embed, never a model call.
///
/// Search ([search]) ranks text matches by BM25 and AND-combines them with the
/// structural facet filters; a facet-only query returns its matches in document
/// (path) order with a zero score.
library;

import 'dart:math' as math;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The value-presence facet of an [IndexQuery].
enum IndexStateFilter {
  /// The node currently holds no value.
  empty,

  /// The node currently holds at least one value.
  nonEmpty,
}

/// An AND-combined query over the tier-1 index: an optional BM25 [text] match
/// plus structural facet filters. An all-`null` query matches every indexed
/// section.
class IndexQuery {
  /// Free text; tokenised and scored by BM25 over the indexed section text.
  final String? text;

  /// The node kinds to include (any-of); `null` admits every kind.
  final Set<SpecNodeKind>? kinds;

  /// The model class a node must *be*.
  final String? className;

  /// The node's `@SectionId` must equal this exactly.
  final String? sectionIdExact;

  /// The node's `@SectionId` must start with this prefix.
  final String? sectionIdPrefix;

  /// The node's class must carry `@MapsTo(<this>)`.
  final String? mapsTo;

  /// The node's class must carry `@DetailedIn(<this>)`.
  final String? detailedIn;

  /// The node's value-presence state must match this.
  final IndexStateFilter? state;

  /// Cap the number of hits returned (`null` = no cap).
  final int? limit;

  const IndexQuery({
    this.text,
    this.kinds,
    this.className,
    this.sectionIdExact,
    this.sectionIdPrefix,
    this.mapsTo,
    this.detailedIn,
    this.state,
    this.limit,
  });
}

/// One ranked match from [StructuralLexicalIndex.search].
class IndexHit {
  /// The section-id path of the matched node.
  final String path;

  /// The node kind.
  final SpecNodeKind kind;

  /// The model class the node *is* (`null` for leaves / containers).
  final String? classId;

  /// The node's doc-comment / label headline (`null` when none).
  final String? headline;

  /// The BM25 relevance score (`0.0` for facet-only matches).
  final double score;

  const IndexHit({
    required this.path,
    required this.kind,
    this.classId,
    this.headline,
    required this.score,
  });

  @override
  String toString() => 'IndexHit($path, ${score.toStringAsFixed(3)})';
}

/// What an [StructuralLexicalIndex.update] changed, so callers (and tests) can
/// verify the refresh was incremental.
class IndexUpdateStats {
  /// Sections newly indexed (a path not previously present).
  final int added;

  /// Sections re-indexed in place (a path already present).
  final int updated;

  /// Sections dropped from the index.
  final int removed;

  const IndexUpdateStats({this.added = 0, this.updated = 0, this.removed = 0});
}

/// The indexed record for one section: its facets and its per-term frequencies.
class _Section {
  final SpecNodeKind kind;
  final String? classId;
  final String? sectionId;
  final String? mapsTo;
  final String? detailedIn;
  final String? headline;
  final bool hasValue;

  /// term -> frequency within this section.
  final Map<String, int> termFreqs;

  /// Total token count (`sum(termFreqs.values)`).
  final int length;

  _Section({
    required this.kind,
    required this.classId,
    required this.sectionId,
    required this.mapsTo,
    required this.detailedIn,
    required this.headline,
    required this.hasValue,
    required this.termFreqs,
  }) : length = termFreqs.values.fold(0, (a, b) => a + b);
}

/// The tier-1 inverted index + structural facet store.
class StructuralLexicalIndex {
  // BM25 parameters (Robertson/Spärck-Jones defaults).
  static const double _k1 = 1.2;
  static const double _b = 0.75;

  static final RegExp _tokenSplit = RegExp(r'[^a-z0-9]+');

  /// path -> section record.
  final Map<String, _Section> _sections = {};

  /// term -> (path -> tf). The inverted index.
  final Map<String, Map<String, int>> _postings = {};

  /// Running sum of all section lengths (for `avgdl`).
  int _totalTokens = 0;

  /// The number of indexed sections.
  int get sectionCount => _sections.length;

  /// The distinct lexical terms indexed for the section at [path] (empty when
  /// the path is not indexed). Exposed so a fused-recall diversity pass (MMR)
  /// can measure lexical overlap between two candidate sections without
  /// re-tokenising their text — the index already holds the term sets.
  Set<String> termsOf(String path) {
    final section = _sections[path];
    if (section == null) return const <String>{};
    return section.termFreqs.keys.toSet();
  }

  /// The indexed hit (kind / class / headline, zero score) for the section at
  /// [path], or `null` when the path is not indexed. A direct O(1) lookup so a
  /// fused recall can attach structural facets to candidates that other tiers
  /// (vector, GraphWalk) surfaced without re-running [search].
  IndexHit? lookup(String path) =>
      _sections.containsKey(path) ? _hit(path, 0.0) : null;

  /// Replaces the entire index with [nodes] (a full rebuild).
  void rebuild(Iterable<SpecNodeProjection> nodes) {
    _sections.clear();
    _postings.clear();
    _totalTokens = 0;
    for (final node in nodes) {
      _add(node);
    }
  }

  /// Incrementally refreshes the index: drops [removed] paths, then re-indexes
  /// each [changed] projection (replacing an existing record or adding a new
  /// one). Only the named sections are touched — every other posting is left
  /// intact — so the per-prompt refresh stays cheap and never re-scans the whole
  /// document.
  IndexUpdateStats update({
    Iterable<SpecNodeProjection> changed = const [],
    Iterable<String> removed = const [],
  }) {
    var removedCount = 0;
    var addedCount = 0;
    var updatedCount = 0;

    for (final path in removed) {
      if (_remove(path)) removedCount++;
    }
    for (final node in changed) {
      final existed = _remove(node.path);
      _add(node);
      if (existed) {
        updatedCount++;
      } else {
        addedCount++;
      }
    }
    return IndexUpdateStats(
      added: addedCount,
      updated: updatedCount,
      removed: removedCount,
    );
  }

  /// Searches the index, returning hits ranked by BM25 (text queries) or in
  /// path order (facet-only queries), after AND-combining all facet filters.
  List<IndexHit> search(IndexQuery query) {
    final candidates = <String>[
      for (final entry in _sections.entries)
        if (_matchesFacets(query, entry.value)) entry.key,
    ];

    final terms = query.text == null ? const <String>[] : _tokenize(query.text!);
    if (terms.isEmpty) {
      candidates.sort();
      final hits = [for (final path in candidates) _hit(path, 0.0)];
      return _capped(hits, query.limit);
    }

    final candidateSet = candidates.toSet();
    final scores = <String, double>{};
    for (final term in terms) {
      final postings = _postings[term];
      if (postings == null) continue;
      final idf = _idf(postings.length);
      final avgdl = _avgdl;
      for (final entry in postings.entries) {
        final path = entry.key;
        if (!candidateSet.contains(path)) continue;
        final tf = entry.value;
        final dl = _sections[path]!.length;
        final norm = tf + _k1 * (1 - _b + _b * (avgdl == 0 ? 0 : dl / avgdl));
        scores[path] = (scores[path] ?? 0) + idf * (tf * (_k1 + 1)) / norm;
      }
    }

    final hits = [
      for (final entry in scores.entries) _hit(entry.key, entry.value),
    ]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.path.compareTo(b.path);
      });
    return _capped(hits, query.limit);
  }

  // --- mutation --------------------------------------------------------------

  void _add(SpecNodeProjection node) {
    final termFreqs = <String, int>{};
    for (final text in node.searchableStrings) {
      for (final token in _tokenize(text)) {
        termFreqs[token] = (termFreqs[token] ?? 0) + 1;
      }
    }
    final section = _Section(
      kind: node.kind,
      classId: node.classId,
      sectionId: node.sectionId,
      mapsTo: node.mapsTo,
      detailedIn: node.detailedIn,
      headline: node.headline,
      hasValue: node.hasValue,
      termFreqs: termFreqs,
    );
    _sections[node.path] = section;
    _totalTokens += section.length;
    for (final entry in termFreqs.entries) {
      (_postings[entry.key] ??= {})[node.path] = entry.value;
    }
  }

  /// Removes [path]'s record and postings; returns whether it was present.
  bool _remove(String path) {
    final section = _sections.remove(path);
    if (section == null) return false;
    _totalTokens -= section.length;
    for (final term in section.termFreqs.keys) {
      final postings = _postings[term];
      if (postings == null) continue;
      postings.remove(path);
      if (postings.isEmpty) _postings.remove(term);
    }
    return true;
  }

  // --- scoring helpers -------------------------------------------------------

  double get _avgdl => _sections.isEmpty ? 0 : _totalTokens / _sections.length;

  double _idf(int df) {
    final n = _sections.length;
    return math.log(1 + (n - df + 0.5) / (df + 0.5));
  }

  IndexHit _hit(String path, double score) {
    final section = _sections[path]!;
    return IndexHit(
      path: path,
      kind: section.kind,
      classId: section.classId,
      headline: section.headline,
      score: score,
    );
  }

  List<IndexHit> _capped(List<IndexHit> hits, int? limit) =>
      (limit != null && limit < hits.length)
          ? hits.sublist(0, limit)
          : hits;

  bool _matchesFacets(IndexQuery query, _Section section) {
    if (query.kinds != null && !query.kinds!.contains(section.kind)) {
      return false;
    }
    if (query.className != null && section.classId != query.className) {
      return false;
    }
    if (query.sectionIdExact != null &&
        section.sectionId != query.sectionIdExact) {
      return false;
    }
    if (query.sectionIdPrefix != null &&
        !(section.sectionId?.startsWith(query.sectionIdPrefix!) ?? false)) {
      return false;
    }
    if (query.mapsTo != null && section.mapsTo != query.mapsTo) {
      return false;
    }
    if (query.detailedIn != null && section.detailedIn != query.detailedIn) {
      return false;
    }
    if (query.state != null) {
      final wantValue = query.state == IndexStateFilter.nonEmpty;
      if (section.hasValue != wantValue) return false;
    }
    return true;
  }

  List<String> _tokenize(String text) => text
      .toLowerCase()
      .split(_tokenSplit)
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}
