import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 11 / `d4rt_and_llm_tools.md` §9.2 + §9.3 — **fused two-tier
/// recall**. These are the **host-independent** half: the tier-1
/// [StructuralLexicalIndex] is real (built from the object model, zero LLM), the
/// section graph is real, and the tier-2 vector mode is a **fake**
/// [SpecVectorRecall] returning canned hits — so the fusion (RRF), the
/// symbolic/graphWalk modes, and the graceful degradation can be asserted
/// deterministically without a vec0 binary.
///
/// Done-criterion (plan step 11): *recall fuses both tiers and degrades
/// gracefully.*
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
            {'name': 'situation', 'kind': 'complex', 'sectionId': 'SIT', 'type': 'CurrentSituation'},
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'mapsTo': 'PD00',
          'fields': [
            {'name': 'detail', 'kind': 'content', 'sectionId': 'DET'},
          ],
        },
      },
    });

void main() {
  late SpecQueryEngine engine;
  late StructuralLexicalIndex index;
  late SpecRagGraph graph;

  setUp(() {
    final doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'platform overview summary');
    doc.setContent('PD00/SIT/DET', 'current situation analysis');
    engine = SpecQueryEngine(model: _model(), document: doc);
    index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
    graph = SpecRagGraph.fromProjections(engine.projectNodes());
  });

  /// A canned vector tier: returns [paths] (in order) as exact section hits.
  SpecVectorRecall fakeVector(List<String> paths) =>
      (String query, {int k = 10}) async => [
            for (final p in paths.take(k)) SpecRagHit(path: p, text: p),
          ];

  SpecRecallHit hitFor(SpecRecallResult r, String path) =>
      r.hits.firstWhere((h) => h.path == path);

  group('fusion (RRF over tier-1 + tier-2)', () {
    test('a section found by lexical AND vector outranks a lexical-only one',
        () async {
      // "platform" matches VIS and SUM lexically; the vector tier returns SUM
      // only, so SUM is surfaced by two modes and must rank first.
      final recall = SpecRecall(
        index: index,
        vectorRecall: fakeVector(['PD00/SUM']),
      );
      final result = await recall.recall(const SpecRecallQuery(text: 'platform'));

      expect(result.tier2Warm, isTrue);
      expect(result.degraded, isFalse);
      expect(result.hits.first.path, 'PD00/SUM');
      expect(hitFor(result, 'PD00/SUM').modes,
          containsAll(<SpecRecallMode>{SpecRecallMode.lexical, SpecRecallMode.vector}));
      expect(hitFor(result, 'PD00/VIS').modes, {SpecRecallMode.lexical});
    });
  });

  group('graceful degradation to tier 1', () {
    test('no vector tier bound → degraded, lexical hits still returned',
        () async {
      final recall = SpecRecall(index: index);
      final result = await recall.recall(const SpecRecallQuery(text: 'platform'));

      expect(result.tier2Warm, isFalse);
      expect(result.degraded, isTrue);
      expect(result.hits.map((h) => h.path),
          containsAll(<String>['PD00/VIS', 'PD00/SUM']));
    });

    test('vector tier bound but cold (empty) → still degrades to tier 1',
        () async {
      final recall = SpecRecall(index: index, vectorRecall: fakeVector(const []));
      final result = await recall.recall(const SpecRecallQuery(text: 'platform'));

      expect(result.degraded, isTrue);
      expect(result.hits.map((h) => h.path), contains('PD00/VIS'));
    });
  });

  group('symbolic (facet) mode', () {
    test('a facet query surfaces a section with no lexical match', () async {
      final recall = SpecRecall(index: index);
      // Text matches nothing; the className facet selects the CurrentSituation
      // container via the symbolic mode.
      final result = await recall.recall(const SpecRecallQuery(
        text: 'zzznotaword',
        facets: IndexQuery(className: 'CurrentSituation'),
      ));

      expect(result.hits.map((h) => h.path), contains('PD00/SIT'));
      expect(hitFor(result, 'PD00/SIT').modes, contains(SpecRecallMode.symbolic));
    });
  });

  group('GraphWalk mode', () {
    test('expands from the relevance seeds along the section graph', () async {
      final recall = SpecRecall(index: index, graph: graph);
      // Seeds VIS + SUM; a one-hop walk reaches their parent PD00, which no
      // other mode surfaced.
      final result = await recall.recall(const SpecRecallQuery(
        text: 'platform',
        graphWalk: true,
        graphWalkDepth: 1,
      ));

      expect(result.hits.map((h) => h.path), contains('PD00'));
      expect(hitFor(result, 'PD00').modes, contains(SpecRecallMode.graphWalk));
    });

    test('GraphWalk is off by default', () async {
      final recall = SpecRecall(index: index, graph: graph);
      final result = await recall.recall(const SpecRecallQuery(text: 'platform'));
      expect(result.hits.map((h) => h.path), isNot(contains('PD00')));
    });
  });
}
