/// The **memory tools** — the engine-side logic behind the `mem_*` MCP tools
/// (`llm_and_d4rt_tools.md` §8.2).
///
/// [MemoryTools] is the in-process surface the editor's `AgentToolsModule`
/// wraps as `mem_recall` and `mem_refresh`. It binds the
/// `llm_and_d4rt_tools.md` §9 [SpecRecall] (the fused two-tier recall,
/// `llm_and_d4rt_tools.md` §9.2) for recall, and an injected [MemRefreshFn] —
/// wired by the editor to its change-tracking
/// `SpecDocumentMemory.indexChangedSections` — for the manual re-index. Both
/// return a typed value with a compact `toJson()`.
///
/// `mem_recall(query, {mode})` runs the fused recall and, for a non-`fused`
/// [MemRecallMode], **filters** the result to the hits that mode surfaced — an
/// honest "recall via mode X" without a second retrieval path. `mem_refresh()`
/// delegates to the bound callback, or reports `refreshed: false` when none is
/// bound (the headless / not-yet-warm case).
/// @docImport '../memory/spec_memory.dart';
library;

import '../memory/spec_recall.dart';

/// Which retrieval mode `mem_recall` restricts its hits to.
enum MemRecallMode {
  /// The full fused recall (lexical + symbolic + vector + GraphWalk).
  fused,

  /// Only hits the tier-1 BM25 lexical mode surfaced.
  lexical,

  /// Only hits the tier-1 structural facet ("symbolic") mode surfaced.
  symbolic,

  /// Only hits the tier-2 vector mode surfaced.
  vector,
}

/// One `mem_recall` hit projected to JSON.
final class MemRecallHit {
  /// The recalled section's path.
  final String path;

  /// The fused Reciprocal-Rank-Fusion score (higher = more relevant).
  final double score;

  /// The retrieval modes that surfaced this section.
  final List<String> modes;

  /// The node kind (`null` when known only from the vector tier).
  final String? kind;

  /// The doc-comment / label headline (`null` when unknown).
  final String? headline;

  /// Records one hit in its JSON-projected form.
  ///
  /// [modes] and [kind] are `String`s here rather than the engine's enums: this is
  /// the wire shape an MCP tool returns, so the values are the enum *names* and a
  /// consumer must not assume the set is closed — a mode added to
  /// [SpecRecallMode] later appears as a new string rather than breaking the
  /// parse (`llm_and_d4rt_tools.md` §8.2).
  const MemRecallHit({
    required this.path,
    required this.score,
    required this.modes,
    this.kind,
    this.headline,
  });

  factory MemRecallHit._from(SpecRecallHit h) => MemRecallHit(
        path: h.path,
        score: h.score,
        modes: [for (final m in h.modes) m.name],
        kind: h.kind?.name,
        headline: h.headline,
      );

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'path': path,
        'score': score,
        'modes': modes,
        if (kind != null) 'kind': kind,
        if (headline != null) 'headline': headline,
      };
}

/// The `mem_recall` result: the ranked hits and whether the recall degraded to
/// tier 1 (the vector tier was cold).
final class MemRecallResult {
  /// The ranked hits, best first.
  final List<MemRecallHit> hits;

  /// Whether the recall ran in degraded (tier-1-only) mode.
  final bool degraded;

  /// Records a completed `mem_recall`.
  ///
  /// [degraded] is the inverted `tier2Warm` of the underlying recall: `true` says
  /// the vector tier contributed nothing — no store bound, or nothing embedded
  /// yet — so the hits are exact but lack semantic matches until tier 2 warms.
  /// Surfacing it in the tool result is what lets an agent tell "no such section"
  /// apart from "the index is still cold" (`llm_and_d4rt_tools.md` §9.2).
  const MemRecallResult({required this.hits, required this.degraded});

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'hits': [for (final h in hits) h.toJson()],
        'degraded': degraded,
      };
}

/// The `mem_refresh` result: what the manual re-index did.
final class MemRefreshResult {
  /// Whether a refresh actually ran (a callback was bound).
  final bool refreshed;

  /// Sections re-embedded (content actually changed).
  final int embedded;

  /// Sections skipped because their content hash was unchanged.
  final int unchanged;

  /// Edges (re-)linked for the touched sections.
  final int edges;

  /// Sections forgotten (removed from memory).
  final int removed;

  /// Records a `mem_refresh`.
  ///
  /// [refreshed] `false` with all four counters at zero is the **headless /
  /// not-yet-warm** case — no re-index callback was bound — and is deliberately
  /// reported as a successful call rather than an error, so an agent running
  /// without a live memory plane is not derailed by it. The counters default to
  /// zero for exactly that construction; when [refreshed] is `true` they mirror
  /// the underlying [SpecRagRefreshResult] section-for-section.
  const MemRefreshResult({
    required this.refreshed,
    this.embedded = 0,
    this.unchanged = 0,
    this.edges = 0,
    this.removed = 0,
  });

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'refreshed': refreshed,
        'embedded': embedded,
        'unchanged': unchanged,
        'edges': edges,
        'removed': removed,
      };
}

/// Performs the `mem_refresh` re-index, returning what it did. The editor wires
/// this to its change-tracking `SpecDocumentMemory.indexChangedSections`.
typedef MemRefreshFn = Future<MemRefreshResult> Function();

/// Recalls from, and refreshes, a document's memory under the
/// `llm_and_d4rt_tools.md` §8.2 `mem_*` tools.
final class MemoryTools {
  /// Creates the toolset over the fused [recall] and an optional [onRefresh]
  /// re-index callback.
  MemoryTools({required this.recall, this.onRefresh});

  /// The fused two-tier recall (`llm_and_d4rt_tools.md` §9).
  final SpecRecall recall;

  /// The manual re-index callback, or `null` when none is bound.
  final MemRefreshFn? onRefresh;

  /// `mem_recall` — recalls the sections most relevant to [query]. For a
  /// non-[MemRecallMode.fused] [mode] the fused hits are filtered to the ones
  /// that mode surfaced; an enlarged internal cap keeps the post-filter result
  /// at [k] where possible.
  Future<MemRecallResult> recallQuery(
    String query, {
    MemRecallMode mode = MemRecallMode.fused,
    int k = 10,
  }) async {
    // When filtering by a single mode, recall a wider candidate set so the
    // post-filter top-[k] is not starved by the other modes' hits.
    final internalK = mode == MemRecallMode.fused ? k : (k < 50 ? 50 : k);
    final result = await recall.recall(SpecRecallQuery(text: query, k: internalK));

    var hits = result.hits;
    if (mode != MemRecallMode.fused) {
      final want = _modeFor(mode);
      hits = [for (final h in hits) if (h.modes.contains(want)) h];
    }
    return MemRecallResult(
      hits: [for (final h in hits.take(k)) MemRecallHit._from(h)],
      degraded: result.degraded,
    );
  }

  /// `mem_refresh` — runs the bound re-index callback, or reports
  /// `refreshed: false` when none is bound.
  Future<MemRefreshResult> refresh() async {
    final fn = onRefresh;
    if (fn == null) return const MemRefreshResult(refreshed: false);
    return fn();
  }

  static SpecRecallMode _modeFor(MemRecallMode mode) => switch (mode) {
        MemRecallMode.fused => SpecRecallMode.lexical, // unreachable
        MemRecallMode.lexical => SpecRecallMode.lexical,
        MemRecallMode.symbolic => SpecRecallMode.symbolic,
        MemRecallMode.vector => SpecRecallMode.vector,
      };
}
