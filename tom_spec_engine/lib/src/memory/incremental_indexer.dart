/// The **change-log-driven incremental re-indexer** (`d4rt_and_llm_tools.md`
/// §9.2; plan steps 9–11, item 14; closes D53).
///
/// Steps 9–11 delivered the two incremental *mechanisms* — tier-1
/// [StructuralLexicalIndex.update] (re-index only the changed sections, zero
/// model calls) and tier-2 [SpecDocumentMemory.indexChangedSections] (embed only
/// the sections whose content actually moved) — but left the **derivation** of
/// the changed-path set, and the async/debounce scheduling of the refresh,
/// explicitly deferred (D53): they belong with the live edit stream, not the
/// store. [SpecIncrementalIndexer] is that missing piece.
///
/// A caller [touch]es the indexer with the section-id paths an edit changed
/// (the editor derives them from its document change log — the `ChangeEntry`
/// section ids). The indexer **coalesces** a burst of touches and, after a quiet
/// [debounce] window, runs a single [flush] **off the edit path** so typing
/// never blocks on a re-embed. One flush:
///
///   * snapshots and clears the pending set;
///   * resolves each dirty path against the document's *current* projection —
///     a path still present is a **change**, a path now gone is a **removal**
///     (so a deleted section is dropped from both tiers without the caller
///     having to classify it);
///   * drives **tier 1** with [StructuralLexicalIndex.update] over just those
///     changed projections + removed paths;
///   * drives **tier 2**, when a [SpecTier2Reindex] is bound, with the current
///     [SpecRagGraph] and the same changed/removed split — the embed-changed-only
///     path. When no tier-2 callback is bound (degraded / tier-1-only) the
///     tier-2 result is `null`.
///
/// Flushes are **serialized**: each [flush] chains after the previous so two
/// tier-2 re-embeds never interleave, and each reads the pending set at the
/// moment it actually runs.
///
/// The same serialized chain backs the **manual** refresh: [reindexAll] (item
/// 16) reconciles an explicit path set (the document's current sections plus
/// everything previously indexed) so a `mem_refresh` is just one more entry on
/// the chain — it can never race an in-flight debounced flush, and both paths
/// drive the one [SpecDocumentMemory.indexChangedSections] entrypoint rather
/// than a parallel full rebuild.
library;

import 'dart:async';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecNodeProjection;

import '../index/structural_lexical_index.dart'
    show IndexUpdateStats, StructuralLexicalIndex;
import 'spec_memory.dart' show SpecDocumentMemory, SpecRagRefreshResult;
import 'spec_rag_graph.dart' show SpecRagGraph;

/// Re-embeds the changed sections of [graph] into the tier-2 vector store —
/// exactly [SpecDocumentMemory.indexChangedSections]'s shape, taken as a
/// callback so the indexer needs no live `vec0` store to be unit-tested and so
/// the editor can bind a lazily-opened document handle.
typedef SpecTier2Reindex = Future<SpecRagRefreshResult> Function(
  SpecRagGraph graph, {
  required Set<String> changedPaths,
  required Set<String> removedPaths,
});

/// Supplies the document's *current* node projection (post-edit). Called once
/// per [SpecIncrementalIndexer.flush]; the indexer keys it by path to resolve
/// the dirty set into changed (still present) vs removed (now gone) sections.
typedef SpecProjectionsProvider = List<SpecNodeProjection> Function();

/// What one [SpecIncrementalIndexer.flush] did, so callers (and tests) can
/// confirm the refresh was incremental and which paths it touched.
final class SpecReindexResult {
  /// The tier-1 [StructuralLexicalIndex.update] outcome.
  final IndexUpdateStats tier1;

  /// The tier-2 [SpecDocumentMemory.indexChangedSections] outcome, or `null`
  /// when no tier-2 callback is bound (tier-1-only / degraded).
  final SpecRagRefreshResult? tier2;

  /// Dirty paths that resolved to a live section (re-indexed, not removed).
  final Set<String> changedPaths;

  /// Dirty paths absent from the current projection (dropped from both tiers).
  final Set<String> removedPaths;

  const SpecReindexResult({
    required this.tier1,
    required this.tier2,
    required this.changedPaths,
    required this.removedPaths,
  });

  /// The no-op result of a flush with nothing pending.
  const SpecReindexResult.empty()
      : tier1 = const IndexUpdateStats(),
        tier2 = null,
        changedPaths = const <String>{},
        removedPaths = const <String>{};

  /// Whether the flush touched nothing.
  bool get isEmpty => changedPaths.isEmpty && removedPaths.isEmpty;

  @override
  String toString() => 'SpecReindexResult(changed: ${changedPaths.length}, '
      'removed: ${removedPaths.length}, tier2: ${tier2 == null ? 'off' : 'on'})';
}

/// Accumulates dirty section paths and, after a debounce, drives the tier-1 +
/// tier-2 incremental re-index off the edit path. See the library doc.
final class SpecIncrementalIndexer {
  /// The tier-1 inverted index this refreshes in place.
  final StructuralLexicalIndex index;

  /// Supplies the document's current projection on each [flush].
  final SpecProjectionsProvider projections;

  /// The tier-2 re-embed callback, or `null` for tier-1-only mode.
  final SpecTier2Reindex? tier2;

  /// How long a quiet window must pass after the last [touch] before the
  /// debounced [flush] fires.
  final Duration debounce;

  /// Invoked after every completed [flush] (including the auto-debounced ones),
  /// so a host can observe refreshes it did not explicitly await.
  final void Function(SpecReindexResult result)? onReindexed;

  final Set<String> _pending = <String>{};
  Timer? _timer;
  Future<void> _chain = Future<void>.value();
  bool _disposed = false;

  SpecIncrementalIndexer({
    required this.index,
    required this.projections,
    this.tier2,
    this.debounce = const Duration(milliseconds: 150),
    this.onReindexed,
  });

  /// Whether any touched paths are awaiting a flush.
  bool get hasPending => _pending.isNotEmpty;

  /// The paths awaiting the next flush (read-only snapshot).
  Set<String> get pendingPaths => Set<String>.unmodifiable(_pending);

  /// Marks [paths] dirty and (re-)arms the debounce timer. Non-blocking — the
  /// actual re-index runs later, off the edit path. A no-op after [dispose] or
  /// when every path is already pending.
  void touch(Iterable<String> paths) {
    if (_disposed) return;
    var added = false;
    for (final path in paths) {
      if (_pending.add(path)) added = true;
    }
    if (!added) return;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Flushes the pending set **now** (cancelling the debounce), returning what
  /// the re-index did. Safe to call concurrently: flushes serialize, and each
  /// reads the pending set at the moment it runs, so a flush invoked while
  /// another is in flight simply processes whatever remains (often nothing).
  Future<SpecReindexResult> flush() => _enqueue(() {
        final dirty = Set<String>.from(_pending);
        _pending.clear();
        return dirty;
      });

  /// Forces a **full current-state reconcile** of [paths] (a manual
  /// `mem_refresh`; item 16) through the **same serialized chain** as the
  /// debounced [flush], so a manual refresh can never race an in-flight
  /// incremental flush. Pass the union of the document's current section paths
  /// and the paths previously indexed, so sections that disappeared since the
  /// last index are reclassified as removals and dropped from both tiers. Any
  /// touches still pending are folded into this reconcile and cleared — this
  /// flush supersedes them. A no-op after [dispose].
  ///
  /// Unlike [flush] it does not depend on the pending set, so it returns the
  /// reconcile's real outcome even when no edits were queued.
  Future<SpecReindexResult> reindexAll(Iterable<String> paths) {
    if (_disposed) {
      return Future<SpecReindexResult>.value(const SpecReindexResult.empty());
    }
    final requested = Set<String>.from(paths);
    return _enqueue(() {
      final dirty = requested..addAll(_pending);
      _pending.clear();
      return dirty;
    });
  }

  /// Chains a single re-index onto the serialization chain. [dirtySource] is
  /// evaluated at the moment the chain reaches it (not at call time), so it
  /// snapshots the work set against the live pending state. The debounce timer
  /// is cancelled at call time so a queued auto-flush does not fire redundantly.
  Future<SpecReindexResult> _enqueue(Set<String> Function() dirtySource) {
    _timer?.cancel();
    _timer = null;
    final scheduled = _chain.then((_) => _runFlush(dirtySource()));
    // Advance the serialization chain, swallowing errors so one failed flush
    // does not poison every later flush.
    _chain = scheduled.then<void>((_) {}, onError: (_) {});
    return scheduled;
  }

  Future<SpecReindexResult> _runFlush(Set<String> dirty) async {
    if (dirty.isEmpty) return const SpecReindexResult.empty();

    final nodes = projections();
    final byPath = <String, SpecNodeProjection>{
      for (final node in nodes) node.path: node,
    };

    final changedProjections = <SpecNodeProjection>[];
    final changedPaths = <String>{};
    final removedPaths = <String>{};
    for (final path in dirty) {
      final node = byPath[path];
      if (node == null) {
        removedPaths.add(path);
      } else {
        changedProjections.add(node);
        changedPaths.add(path);
      }
    }

    final tier1 = index.update(changed: changedProjections, removed: removedPaths);

    SpecRagRefreshResult? tier2Result;
    final tier2Fn = tier2;
    if (tier2Fn != null) {
      final graph = SpecRagGraph.fromProjections(nodes);
      tier2Result = await tier2Fn(
        graph,
        changedPaths: changedPaths,
        removedPaths: removedPaths,
      );
    }

    final result = SpecReindexResult(
      tier1: tier1,
      tier2: tier2Result,
      changedPaths: changedPaths,
      removedPaths: removedPaths,
    );
    onReindexed?.call(result);
    return result;
  }

  /// Cancels any pending debounce and stops accepting touches. Does not flush;
  /// a caller that wants the pending set drained should [flush] before disposing.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
