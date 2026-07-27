import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecNodeKind, SpecNodeProjection;
import 'package:tom_spec_engine/memory.dart';

/// `llm_and_d4rt_tools.md` §9.2: the
/// **change-log-driven incremental re-indexer**. A host [touch]es the indexer
/// with the section paths an edit changed; the indexer coalesces a burst, runs
/// one debounced [flush] off the edit path, and drives **both tiers**
/// incrementally — tier-1 [StructuralLexicalIndex.update] over the changed
/// projections + removed paths, and (when bound) the tier-2 re-embed callback
/// over the same changed/removed split.
///
/// These are host-independent: tier 1 is the real index, and the tier-2 side is
/// a **fake** [SpecTier2Reindex] recording its arguments — so the orchestration,
/// the changed-vs-removed derivation, the debounce, and the coalescing assert
/// deterministically without a `vec0` binary.
void main() {
  /// A content node at [path] whose searchable text is [text].
  SpecNodeProjection node(String path, String text) => SpecNodeProjection(
        path: path,
        kind: SpecNodeKind.content,
        sectionId: path.split('/').last,
        searchableStrings: [text],
        hasValue: text.isNotEmpty,
      );

  late List<SpecNodeProjection> current;
  late StructuralLexicalIndex index;

  /// Records every tier-2 re-index call so a test can assert what the indexer
  /// asked the vector tier to do.
  late List<({SpecRagGraph graph, Set<String> changed, Set<String> removed})>
      tier2Calls;

  SpecTier2Reindex recordingTier2() {
    tier2Calls = [];
    return (graph, {required changedPaths, required removedPaths}) async {
      tier2Calls.add((graph: graph, changed: changedPaths, removed: removedPaths));
      return SpecRagRefreshResult(
        embedded: changedPaths.length,
        unchanged: 0,
        edgeCount: 0,
        removed: removedPaths.length,
      );
    };
  }

  setUp(() {
    current = [
      node('PD00/VIS', 'resilient rollout platform'),
      node('PD00/SUM', 'platform overview summary'),
    ];
    index = StructuralLexicalIndex()..rebuild(current);
  });

  SpecIncrementalIndexer makeIndexer({
    SpecTier2Reindex? tier2,
    Duration debounce = const Duration(milliseconds: 20),
    void Function(SpecReindexResult)? onReindexed,
  }) =>
      SpecIncrementalIndexer(
        index: index,
        projections: () => current,
        tier2: tier2,
        debounce: debounce,
        onReindexed: onReindexed,
      );

  List<String> searchPaths(String text) =>
      [for (final h in index.search(IndexQuery(text: text))) h.path];

  group('flush drives tier 1 incrementally', () {
    test('a changed section is re-indexed in place; new terms become findable',
        () async {
      final indexer = makeIndexer();
      // The edit: VIS now talks about "kubernetes".
      current = [
        node('PD00/VIS', 'kubernetes operator platform'),
        node('PD00/SUM', 'platform overview summary'),
      ];
      indexer.touch(['PD00/VIS']);

      final result = await indexer.flush();

      expect(searchPaths('kubernetes'), ['PD00/VIS']);
      // The stale term is gone from VIS (only VIS changed).
      expect(searchPaths('resilient'), isEmpty);
      expect(result.tier1.updated, 1);
      expect(result.tier1.added, 0);
      expect(result.changedPaths, {'PD00/VIS'});
      expect(result.removedPaths, isEmpty);
    });

    test('only the touched section is re-indexed — untouched postings survive',
        () async {
      final indexer = makeIndexer();
      current = [
        node('PD00/VIS', 'kubernetes operator platform'),
        node('PD00/SUM', 'platform overview summary'),
      ];
      indexer.touch(['PD00/VIS']);
      await indexer.flush();

      // SUM was never touched, so its original terms are intact.
      expect(searchPaths('overview'), ['PD00/SUM']);
    });

    test('a dirty path absent from the projection is reclassified as a removal',
        () async {
      final indexer = makeIndexer();
      // SUM disappeared from the document (e.g. a removed list item).
      current = [node('PD00/VIS', 'resilient rollout platform')];
      indexer.touch(['PD00/SUM']);

      final result = await indexer.flush();

      expect(result.removedPaths, {'PD00/SUM'});
      expect(result.changedPaths, isEmpty);
      expect(result.tier1.removed, 1);
      expect(searchPaths('summary'), isEmpty);
    });

    test('a flush with nothing pending is an empty no-op', () async {
      final indexer = makeIndexer();
      final result = await indexer.flush();
      expect(result.isEmpty, isTrue);
      expect(result.tier2, isNull);
    });
  });

  group('flush drives tier 2 when a callback is bound', () {
    test('the changed/removed split and the current graph reach the callback',
        () async {
      final indexer = makeIndexer(tier2: recordingTier2());
      current = [
        node('PD00/VIS', 'kubernetes operator platform'),
        // SUM removed.
      ];
      indexer.touch(['PD00/VIS', 'PD00/SUM']);

      final result = await indexer.flush();

      expect(tier2Calls, hasLength(1));
      expect(tier2Calls.single.changed, {'PD00/VIS'});
      expect(tier2Calls.single.removed, {'PD00/SUM'});
      // The graph carries the current projection (VIS only).
      expect(
        tier2Calls.single.graph.nodes.map((n) => n.path),
        ['PD00/VIS'],
      );
      expect(result.tier2, isNotNull);
      expect(result.tier2!.embedded, 1);
      expect(result.tier2!.removed, 1);
    });

    test('with no tier-2 callback the tier-2 result is null (tier-1-only)',
        () async {
      final indexer = makeIndexer();
      indexer.touch(['PD00/VIS']);
      final result = await indexer.flush();
      expect(result.tier2, isNull);
      expect(result.changedPaths, {'PD00/VIS'});
    });
  });

  group('debounce + coalescing (async, off the edit path)', () {
    test('a burst of touches coalesces into one debounced flush', () async {
      final results = <SpecReindexResult>[];
      final indexer = makeIndexer(
        tier2: recordingTier2(),
        onReindexed: results.add,
      );

      // Three touches inside one debounce window.
      indexer.touch(['PD00/VIS']);
      indexer.touch(['PD00/SUM']);
      indexer.touch(['PD00/VIS']); // duplicate — already pending.

      expect(indexer.hasPending, isTrue);
      expect(indexer.pendingPaths, {'PD00/VIS', 'PD00/SUM'});

      // Wait past the debounce for the single auto-flush to fire.
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(results, hasLength(1), reason: 'one coalesced flush');
      expect(results.single.changedPaths, {'PD00/VIS', 'PD00/SUM'});
      expect(tier2Calls, hasLength(1));
      expect(indexer.hasPending, isFalse);
    });

    test('the debounce re-arms on each touch (only the quiet window fires)',
        () async {
      final results = <SpecReindexResult>[];
      final indexer = makeIndexer(
        debounce: const Duration(milliseconds: 40),
        onReindexed: results.add,
      );

      indexer.touch(['PD00/VIS']);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Re-arm before the first window elapsed.
      indexer.touch(['PD00/SUM']);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Still inside the re-armed window — no flush yet.
      expect(results, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(results, hasLength(1));
      expect(results.single.changedPaths, {'PD00/VIS', 'PD00/SUM'});
    });
  });

  group('reindexAll — manual full reconcile through the serialized chain '
      '(item 16)', () {
    test('reconciles every current section and drops paths now gone', () async {
      final indexer = makeIndexer(tier2: recordingTier2());
      // SUM disappeared; VIS rewritten. The caller passes the union of current
      // paths and the previously-indexed set so the removal is caught.
      current = [node('PD00/VIS', 'kubernetes operator platform')];

      final result = await indexer.reindexAll(['PD00/VIS', 'PD00/SUM']);

      expect(result.changedPaths, {'PD00/VIS'});
      expect(result.removedPaths, {'PD00/SUM'});
      // Tier 1 reconciled in place: the new term is findable, the removed
      // section's terms are gone.
      expect(searchPaths('kubernetes'), ['PD00/VIS']);
      expect(searchPaths('summary'), isEmpty);
      // Tier 2 got the same split + current graph.
      expect(tier2Calls, hasLength(1));
      expect(tier2Calls.single.changed, {'PD00/VIS'});
      expect(tier2Calls.single.removed, {'PD00/SUM'});
      expect(result.tier2, isNotNull);
    });

    test('returns the real outcome with nothing pending (unlike flush)',
        () async {
      final indexer = makeIndexer(tier2: recordingTier2());
      // Nothing touched: a bare flush would be an empty no-op...
      final empty = await indexer.flush();
      expect(empty.isEmpty, isTrue);
      // ...but reindexAll reconciles the explicit set regardless.
      final result = await indexer.reindexAll(['PD00/VIS', 'PD00/SUM']);
      expect(result.changedPaths, {'PD00/VIS', 'PD00/SUM'});
      expect(result.tier2, isNotNull);
    });

    test('folds any pending touches into the reconcile and clears them',
        () async {
      final indexer = makeIndexer(tier2: recordingTier2());
      indexer.touch(['PD00/VIS']);
      expect(indexer.hasPending, isTrue);

      final result = await indexer.reindexAll(['PD00/SUM']);

      // Both the explicit SUM and the pending VIS were reconciled in one run.
      expect(result.changedPaths, {'PD00/VIS', 'PD00/SUM'});
      expect(indexer.hasPending, isFalse, reason: 'pending folded + cleared');
    });

    test('serializes with an in-flight flush — no interleave', () async {
      final order = <String>[];
      final indexer = makeIndexer(
        tier2: recordingTier2(),
        onReindexed: (r) => order.add(
          r.removedPaths.isNotEmpty ? 'reindexAll' : 'flush',
        ),
      );
      indexer.touch(['PD00/VIS']);
      // Drop SUM so the reindexAll run carries a removal (its marker above).
      current = [node('PD00/VIS', 'kubernetes operator platform')];

      // Fire both without awaiting the first: they must run in chain order.
      final f1 = indexer.flush();
      final f2 = indexer.reindexAll(['PD00/VIS', 'PD00/SUM']);
      await Future.wait([f1, f2]);

      expect(order, ['flush', 'reindexAll']);
      // Two distinct tier-2 calls, never interleaved.
      expect(tier2Calls, hasLength(2));
    });

    test('after dispose, reindexAll is an empty no-op', () async {
      final indexer = makeIndexer(tier2: recordingTier2());
      indexer.dispose();
      final result = await indexer.reindexAll(['PD00/VIS', 'PD00/SUM']);
      expect(result.isEmpty, isTrue);
      expect(tier2Calls, isEmpty);
    });
  });

  group('lifecycle', () {
    test('touching the same paths again is a no-op (no new arming)', () {
      final indexer = makeIndexer();
      indexer.touch(['PD00/VIS']);
      final before = indexer.pendingPaths;
      indexer.touch(['PD00/VIS']);
      expect(indexer.pendingPaths, before);
    });

    test('after dispose, touch is ignored and no flush fires', () async {
      final results = <SpecReindexResult>[];
      final indexer = makeIndexer(onReindexed: results.add);
      indexer.dispose();
      indexer.touch(['PD00/VIS']);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(indexer.hasPending, isFalse);
      expect(results, isEmpty);
    });
  });
}
