/// The **fused recall** behind the two-tier memory (`d4rt_and_llm_tools.md`
/// §9.2 / §9.3, plan step 11).
///
/// Step 9 built **tier 1** — the model-derived [StructuralLexicalIndex] (BM25 +
/// structural facets, zero LLM calls, refreshed after every prompt). Step 10
/// built **tier 2** — the section-level vector store in Tom Brain named memory.
/// This step fuses them: [SpecRecall.recall] runs the tier-1 lexical (BM25) and
/// symbolic (facet) modes, the tier-2 vector mode, and an optional GraphWalk
/// over the section graph, then combines the per-mode ranked lists with
/// **Reciprocal Rank Fusion** and (optionally) diversifies with **MMR** — the
/// `tom_brain_memory` recall contract (§9.3), applied at the engine layer so the
/// always-available tier-1 index can be fused with the tier-2 vectors.
///
/// **Graceful degradation (§9.2).** Tier 1 is built directly from the object
/// model and is available the instant the document is projected; tier 2 lags,
/// because embeddings are computed incrementally and out of band. When the
/// vector tier returns nothing — no vector recall bound, or none embedded yet —
/// [recall] falls back to tier-1 + symbolic (+ optional GraphWalk) and reports
/// [SpecRecallResult.degraded]. The result is still exact and useful; it simply
/// lacks semantic matches until tier 2 warms.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart' show SpecNodeKind;

import '../index/structural_lexical_index.dart';
import 'spec_memory.dart' show SpecRagHit;
import 'spec_rag_graph.dart';

/// Recalls the sections most relevant to a query from the tier-2 vector store.
///
/// The fused [SpecRecall] is decoupled from the store behind this signature:
/// bind it to `SpecDocumentMemory.recallSections` for the real vector tier, or
/// leave it `null` (the tier-2-cold case) to exercise tier-1-only degradation.
typedef SpecVectorRecall = Future<List<SpecRagHit>> Function(
  String query, {
  int k,
});

/// Which retrieval mode surfaced a section in a fused recall.
enum SpecRecallMode {
  /// Tier-1 BM25 full-text match over the indexed section text.
  lexical,

  /// Tier-1 structural facet match (kind / class / section-id / `@MapsTo` /
  /// `@DetailedIn` / state) — the "symbolic" mode of the recall contract.
  symbolic,

  /// Tier-2 vector / semantic match from the Tom Brain named-memory store.
  vector,

  /// Bounded-depth walk over the section graph's tree + projection edges,
  /// expanding from the seeds the other modes surfaced.
  graphWalk,
}

/// One fused-recall hit: a section path, its fused (RRF) score, and which modes
/// surfaced it.
final class SpecRecallHit {
  /// The section-id path of the recalled section.
  final String path;

  /// The fused Reciprocal-Rank-Fusion score (higher = more relevant). After an
  /// MMR diversity pass this remains the pre-MMR fused score; only the order
  /// reflects the diversification.
  final double score;

  /// The modes that surfaced this section. A section found by more than one
  /// mode (e.g. lexical *and* vector) carries every contributing mode.
  final Set<SpecRecallMode> modes;

  /// The node kind (from the tier-1 index), `null` when the section is known
  /// only from the vector tier.
  final SpecNodeKind? kind;

  /// The doc-comment / label headline (from the tier-1 index), `null` when
  /// unknown.
  final String? headline;

  const SpecRecallHit({
    required this.path,
    required this.score,
    required this.modes,
    this.kind,
    this.headline,
  });

  @override
  String toString() =>
      'SpecRecallHit($path, ${score.toStringAsFixed(4)}, '
      '{${modes.map((m) => m.name).join(',')}})';
}

/// The fused-recall result: the ranked hits plus whether the vector tier
/// contributed.
final class SpecRecallResult {
  /// The fused, optionally MMR-diversified hits, best first, at most `k`.
  final List<SpecRecallHit> hits;

  /// Whether tier 2 (vector) surfaced at least one candidate. When `false` the
  /// recall ran in degraded (tier-1 + symbolic + GraphWalk) mode.
  final bool tier2Warm;

  const SpecRecallResult({required this.hits, required this.tier2Warm});

  /// Whether the recall degraded to tier 1 because the vector tier was cold.
  bool get degraded => !tier2Warm;

  @override
  String toString() =>
      'SpecRecallResult(${hits.length} hits, '
      'tier2=${tier2Warm ? 'warm' : 'cold'})';
}

/// A fused-recall request: the query text, optional structural facets, the
/// result cap, and the RRF / MMR / GraphWalk knobs.
final class SpecRecallQuery {
  /// Free text scored by tier-1 BM25 and (when bound) the tier-2 vector model.
  final String text;

  /// Structural constraints shared by the lexical and symbolic modes. Its own
  /// `text` field is ignored — [text] is the query text; this carries the
  /// facets (kind / class / section-id / `@MapsTo` / `@DetailedIn` / state).
  final IndexQuery facets;

  /// Post-fusion cap on the returned hits.
  final int k;

  /// Per-mode candidate cap, before fusion.
  final int perModeK;

  /// RRF smoothing constant (the `tom_brain_memory` default is 60).
  final int rrfK;

  /// Per-mode fusion weight. Modes absent from the map default to
  /// [defaultWeights].
  final Map<SpecRecallMode, double> weights;

  /// Whether to run the optional GraphWalk mode (needs a graph on [SpecRecall]).
  final bool graphWalk;

  /// Maximum hop count for the GraphWalk mode.
  final int graphWalkDepth;

  /// Whether to apply the MMR diversity pass over the fused list.
  final bool diversify;

  /// MMR's lambda: 1.0 favours pure relevance, 0.0 favours pure diversity.
  final double mmrLambda;

  const SpecRecallQuery({
    required this.text,
    this.facets = const IndexQuery(),
    this.k = 10,
    this.perModeK = 64,
    this.rrfK = 60,
    this.weights = const <SpecRecallMode, double>{},
    this.graphWalk = false,
    this.graphWalkDepth = 1,
    this.diversify = true,
    this.mmrLambda = 0.7,
  });

  /// Default per-mode weights: the two primary relevance modes (lexical,
  /// vector) full weight, the supporting modes (symbolic, GraphWalk) half.
  static const Map<SpecRecallMode, double> defaultWeights =
      <SpecRecallMode, double>{
    SpecRecallMode.lexical: 1.0,
    SpecRecallMode.vector: 1.0,
    SpecRecallMode.symbolic: 0.5,
    SpecRecallMode.graphWalk: 0.5,
  };

  double weightOf(SpecRecallMode mode) =>
      weights[mode] ?? defaultWeights[mode] ?? 1.0;
}

/// Fuses the tier-1 index, the tier-2 vector store, and the section graph into
/// one ranked recall.
final class SpecRecall {
  /// The tier-1 structural/lexical index (BM25 + facets), always available.
  final StructuralLexicalIndex index;

  /// The optional vector tier. `null` keeps recall in tier-1-only mode.
  final SpecVectorRecall? vectorRecall;

  /// The optional section graph, used by the GraphWalk mode.
  final SpecRagGraph? graph;

  SpecRecall({required this.index, this.vectorRecall, this.graph});

  /// Runs the fused recall for [query].
  ///
  /// Each mode produces a ranked list of section paths; the lists are combined
  /// by weighted RRF, then (when [SpecRecallQuery.diversify]) reordered by MMR.
  /// The vector tier is consulted only when [vectorRecall] is bound; an empty
  /// vector result degrades the recall to tier 1.
  Future<SpecRecallResult> recall(SpecRecallQuery query) async {
    final ranked = <SpecRecallMode, List<String>>{};

    // Tier-1 lexical (BM25) — the query text AND-combined with the facets.
    final lexicalHits = index.search(_lexicalQuery(query));
    if (lexicalHits.isNotEmpty) {
      ranked[SpecRecallMode.lexical] =
          lexicalHits.map((h) => h.path).toList(growable: false);
    }

    // Tier-1 symbolic — facet-only, run only when the query carries facets, so
    // a plain text query does not pull in every section as a symbolic match.
    if (_hasFacets(query.facets)) {
      final symbolicHits = index.search(_symbolicQuery(query));
      if (symbolicHits.isNotEmpty) {
        ranked[SpecRecallMode.symbolic] =
            symbolicHits.map((h) => h.path).toList(growable: false);
      }
    }

    // Tier-2 vector — only when bound; an empty result leaves tier 2 cold.
    var tier2Warm = false;
    final vector = vectorRecall;
    if (vector != null) {
      final vectorHits = await vector(query.text, k: query.perModeK);
      if (vectorHits.isNotEmpty) {
        tier2Warm = true;
        ranked[SpecRecallMode.vector] =
            vectorHits.map((h) => h.path).toList(growable: false);
      }
    }

    // GraphWalk — expand from whatever the relevance modes already surfaced.
    if (query.graphWalk && graph != null) {
      final seeds = <String>{
        ...?ranked[SpecRecallMode.lexical],
        ...?ranked[SpecRecallMode.vector],
      };
      final walked = _graphWalk(seeds, query.graphWalkDepth);
      if (walked.isNotEmpty) {
        ranked[SpecRecallMode.graphWalk] = walked;
      }
    }

    final fused = _fuse(ranked, query);
    final ordered = query.diversify ? _mmr(fused, query) : fused;
    final hits = ordered.take(query.k).toList(growable: false);
    return SpecRecallResult(hits: hits, tier2Warm: tier2Warm);
  }

  // --- per-mode query construction -----------------------------------------

  IndexQuery _lexicalQuery(SpecRecallQuery q) => _withText(q.facets, q.text);

  IndexQuery _symbolicQuery(SpecRecallQuery q) => _withText(q.facets, null);

  /// Rebuilds [base] with its facets preserved and a fresh [text].
  static IndexQuery _withText(IndexQuery base, String? text) => IndexQuery(
        text: text,
        kinds: base.kinds,
        className: base.className,
        sectionIdExact: base.sectionIdExact,
        sectionIdPrefix: base.sectionIdPrefix,
        mapsTo: base.mapsTo,
        detailedIn: base.detailedIn,
        state: base.state,
      );

  static bool _hasFacets(IndexQuery q) =>
      q.kinds != null ||
      q.className != null ||
      q.sectionIdExact != null ||
      q.sectionIdPrefix != null ||
      q.mapsTo != null ||
      q.detailedIn != null ||
      q.state != null;

  // --- GraphWalk -----------------------------------------------------------

  /// BFS over the section graph's edges (both directions) from [seeds], up to
  /// [maxDepth] hops, returning the reached non-seed paths ordered by hop
  /// distance (nearer first, then path-stable). Empty when no graph / no seeds.
  List<String> _graphWalk(Set<String> seeds, int maxDepth) {
    final g = graph;
    if (g == null || seeds.isEmpty || maxDepth <= 0) return const <String>[];

    final neighbours = <String, Set<String>>{};
    for (final edge in g.edges) {
      (neighbours[edge.fromPath] ??= <String>{}).add(edge.toPath);
      (neighbours[edge.toPath] ??= <String>{}).add(edge.fromPath);
    }

    final depthOf = <String, int>{for (final s in seeds) s: 0};
    var frontier = seeds.toList(growable: false);
    for (var depth = 1; depth <= maxDepth && frontier.isNotEmpty; depth++) {
      final next = <String>[];
      for (final node in frontier) {
        for (final neighbour in neighbours[node] ?? const <String>{}) {
          if (depthOf.containsKey(neighbour)) continue;
          depthOf[neighbour] = depth;
          next.add(neighbour);
        }
      }
      frontier = next;
    }

    final reached = depthOf.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) {
        final byDepth = a.value.compareTo(b.value);
        return byDepth != 0 ? byDepth : a.key.compareTo(b.key);
      });
    return reached.map((e) => e.key).toList(growable: false);
  }

  // --- fusion --------------------------------------------------------------

  /// Weighted Reciprocal Rank Fusion (§6.2): each mode contributes
  /// `weight / (rrfK + rank)` for every path it ranked; the contributions sum,
  /// and the modes that surfaced each path are recorded.
  List<SpecRecallHit> _fuse(
    Map<SpecRecallMode, List<String>> ranked,
    SpecRecallQuery query,
  ) {
    final scores = <String, double>{};
    final modesByPath = <String, Set<SpecRecallMode>>{};

    ranked.forEach((mode, paths) {
      final weight = query.weightOf(mode);
      for (var rank = 0; rank < paths.length; rank++) {
        final path = paths[rank];
        scores[path] = (scores[path] ?? 0) + weight / (query.rrfK + rank + 1);
        (modesByPath[path] ??= <SpecRecallMode>{}).add(mode);
      }
    });

    final hits = [
      for (final entry in scores.entries)
        _hitFor(entry.key, entry.value, modesByPath[entry.key]!),
    ]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.path.compareTo(b.path);
      });
    return hits;
  }

  SpecRecallHit _hitFor(String path, double score, Set<SpecRecallMode> modes) {
    // The index is the structural source of truth; a vector-only hit may have
    // no index record (e.g. recalled across an incremental gap), so kind and
    // headline are best-effort.
    final indexed = index.lookup(path);
    return SpecRecallHit(
      path: path,
      score: score,
      modes: modes,
      kind: indexed?.kind,
      headline: indexed?.headline,
    );
  }

  // --- MMR -----------------------------------------------------------------

  /// Maximal Marginal Relevance over the fused list: greedily pick the
  /// candidate maximising `lambda * relevance - (1 - lambda) * maxSim`, where
  /// relevance is the fused score (normalised to its max) and similarity is the
  /// Jaccard overlap of the two sections' tier-1 term sets. Diversifies the
  /// order without changing the reported scores.
  List<SpecRecallHit> _mmr(List<SpecRecallHit> fused, SpecRecallQuery query) {
    if (fused.length <= 2) return fused;
    final maxScore = fused.first.score;
    final norm = maxScore == 0 ? 1.0 : maxScore;
    final lambda = query.mmrLambda;

    final remaining = [...fused];
    final selected = <SpecRecallHit>[];
    // Seed with the top-relevance hit so the best match always leads.
    selected.add(remaining.removeAt(0));

    while (remaining.isNotEmpty) {
      var bestIndex = 0;
      var bestMmr = double.negativeInfinity;
      for (var i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        final relevance = candidate.score / norm;
        var maxSim = 0.0;
        for (final picked in selected) {
          final sim = _jaccard(candidate.path, picked.path);
          if (sim > maxSim) maxSim = sim;
        }
        final mmr = lambda * relevance - (1 - lambda) * maxSim;
        if (mmr > bestMmr) {
          bestMmr = mmr;
          bestIndex = i;
        }
      }
      selected.add(remaining.removeAt(bestIndex));
    }
    return selected;
  }

  double _jaccard(String a, String b) {
    final ta = index.termsOf(a);
    final tb = index.termsOf(b);
    if (ta.isEmpty && tb.isEmpty) return 0.0;
    final intersection = ta.where(tb.contains).length;
    final union = ta.length + tb.length - intersection;
    return union == 0 ? 0.0 : intersection / union;
  }
}
