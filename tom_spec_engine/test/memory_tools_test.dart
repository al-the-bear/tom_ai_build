import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 14 / `d4rt_and_llm_tools.md` §8.2 — the **memory** tools:
/// `mem_recall(query, {mode})` over the fused [SpecRecall] (§9) and
/// `mem_refresh()` (the manual re-index). Both return compact JSON. The tier-1
/// index is real (object-model derived, zero LLM); the tier-2 vector mode is a
/// canned fake, so the fusion and the `mode` filter assert deterministically.
SpecModel _model() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition', 'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS'},
            {'name': 'summary', 'kind': 'content', 'sectionId': 'SUM'},
          ],
        },
      },
    });

void main() {
  late StructuralLexicalIndex index;

  setUp(() {
    final doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'platform overview summary');
    final engine = SpecQueryEngine(model: _model(), document: doc);
    index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
  });

  SpecVectorRecall fakeVector(List<String> paths) =>
      (String query, {int k = 10}) async => [
            for (final p in paths.take(k)) SpecRagHit(path: p, text: p),
          ];

  group('mem_recall', () {
    test('a fused recall returns compact-JSON hits', () async {
      final tools = MemoryTools(
        recall: SpecRecall(index: index, vectorRecall: fakeVector(['PD00/SUM'])),
      );
      final result = await tools.recallQuery('platform');

      expect(result.hits.map((h) => h.path), containsAll(['PD00/VIS', 'PD00/SUM']));
      // SUM is surfaced by lexical AND vector → ranks first.
      expect(result.hits.first.path, 'PD00/SUM');
      expect(result.degraded, isFalse);

      final json = result.toJson();
      expect(json['degraded'], isFalse);
      final first = (json['hits'] as List).first as Map<String, Object?>;
      expect(first['path'], 'PD00/SUM');
      expect(first['modes'], containsAll(['lexical', 'vector']));
    });

    test('mode:vector filters to hits the vector tier surfaced', () async {
      final tools = MemoryTools(
        recall: SpecRecall(index: index, vectorRecall: fakeVector(['PD00/SUM'])),
      );
      final result =
          await tools.recallQuery('platform', mode: MemRecallMode.vector);

      expect(result.hits.map((h) => h.path), ['PD00/SUM']);
    });

    test('degrades to tier 1 when no vector tier is bound', () async {
      final tools = MemoryTools(recall: SpecRecall(index: index));
      final result = await tools.recallQuery('platform');

      expect(result.degraded, isTrue);
      expect(result.hits.map((h) => h.path), containsAll(['PD00/VIS', 'PD00/SUM']));
    });
  });

  group('mem_refresh', () {
    test('with no refresh bound reports refreshed:false', () async {
      final tools = MemoryTools(recall: SpecRecall(index: index));
      final result = await tools.refresh();
      expect(result.refreshed, isFalse);
      expect(result.toJson()['refreshed'], isFalse);
    });

    test('delegates to the bound refresh callback', () async {
      final tools = MemoryTools(
        recall: SpecRecall(index: index),
        onRefresh: () async => const MemRefreshResult(
          refreshed: true,
          embedded: 3,
          unchanged: 7,
          edges: 2,
          removed: 1,
        ),
      );
      final result = await tools.refresh();
      expect(result.refreshed, isTrue);
      expect(result.embedded, 3);
      expect(result.toJson()['unchanged'], 7);
    });
  });
}
