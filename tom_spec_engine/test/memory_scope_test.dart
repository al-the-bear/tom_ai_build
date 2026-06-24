import 'package:test/test.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 12 (`d4rt_and_llm_tools_plan.md`) / §4: the `memory` base scope binds a
/// **read-only** recall surface (`memory`) over the document's fused two-tier
/// recall ([SpecRecall], step 11). A script under this scope can *recall* but
/// has **no mutation path** — the scope registers only the `memory_api` library
/// (no `spec` editing API, no filesystem grants).
///
/// Done-criterion (plan step 12): a script in the `memory` scope can recall and
/// cannot mutate.
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
  late SpecRecall recall;

  setUp(() {
    final doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'platform overview summary');
    doc.setContent('PD00/SIT/DET', 'current situation analysis');
    final engine = SpecQueryEngine(model: _model(), document: doc);
    final index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
    // Tier-1-only recall: no vector tier bound. Recall still resolves lexical
    // hits, which is all this scope needs to prove read access works.
    recall = SpecRecall(index: index);
  });

  /// Runs [source] in a fresh interpreter granted [scope], awaiting the
  /// auto-awaited `main()` result (recall is async).
  Future<Object?> run(ScriptScope scope, String source) async {
    final registry = ScopeRegistry()..register(scope);
    final env = registry.build([scope.name]);
    final d4rt = D4rt();
    env.applyTo(d4rt);
    return await d4rt.execute(source: source);
  }

  const memImport = "import 'package:tom_spec_engine/memory.dart';";

  group('memoryScope shape', () {
    test('is a scope named "memory" exposing the memory_api library', () {
      final scope = memoryScope(recall);
      expect(scope.name, 'memory');
      expect(scope.libraries.map((l) => l.name), contains('memory_api'));
    });

    test('grants no filesystem/network permission (read-only, §4)', () {
      final scope = memoryScope(recall);
      expect(scope.grants, isEmpty);
    });
  });

  group('a script can recall', () {
    test('recallPaths returns the section paths a query surfaces', () async {
      final result = await run(memoryScope(recall), '''
$memImport
main() async => await memory.recallPaths('resilient rollout platform');
''');
      expect(result, isA<List<dynamic>>());
      expect((result as List).cast<String>(), contains('PD00/VIS'));
    });

    test('recall returns hit maps with path/score/modes', () async {
      final result = await run(memoryScope(recall), '''
$memImport
main() async {
  final hits = await memory.recall('resilient rollout platform');
  return hits.first;
}
''');
      final hit = (result as Map).cast<String, Object?>();
      expect(hit['path'], 'PD00/VIS');
      expect(hit['modes'], contains('lexical'));
      expect(hit['score'], isA<num>());
    });

    test('honours the k cap', () async {
      final result = await run(memoryScope(recall), '''
$memImport
main() async => await memory.recallPaths('platform', k: 1);
''');
      expect((result as List), hasLength(1));
    });
  });

  group('a script cannot mutate', () {
    test('the memory global exposes no mutating method', () async {
      // `setContent` is the spec-editing surface; it must not exist on `memory`.
      expect(
        () => run(memoryScope(recall), '''
$memImport
main() async => memory.setContent('PD00/VIS', 'hacked');
'''),
        throwsA(anything),
      );
    });

    test('the spec editing API is not importable under the memory scope',
        () async {
      // The `spec` global / spec_api library is never registered, so a script
      // reaching for it fails — the memory scope is read-only.
      expect(
        () => run(memoryScope(recall), '''
import 'package:tom_spec_engine/spec_api.dart';
main() => spec.setContent('PD00/VIS', 'hacked');
'''),
        throwsA(anything),
      );
    });
  });
}
