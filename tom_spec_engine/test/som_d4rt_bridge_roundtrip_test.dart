import 'package:test/test.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/dartscript.b.dart';

/// Step 5 / `d4rt_and_llm_tools.md` §13.1 / multiplatform item 7c: the generated
/// D4rt bridge round-trip.
///
/// Proves a sandboxed D4rt script, importing only the generated bridge surface,
/// can drive the SOM API end to end **against the same in-memory representation
/// native code holds**:
///
///   * the script receives a native [SpecDocument] + [SpecModel] as arguments
///     (the objects native code created),
///   * writes through the *typed* `tom_som_dart_v0` facade
///     (`D00SolutionBlueprint(doc).content = …`),
///   * writes + reads through the *generic* runtime (`doc.setContent` /
///     `doc.content`),
///   * builds a [SpecQueryEngine] over the shared model+document and runs a
///     [SpecQuery], getting back a cursor whose first match it returns,
///
/// and then native code observes its *own* document object carrying every edit
/// the script made — the two access paths share one representation (§3).
SpecModel _fixtureModel() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'D00SolutionBlueprint', 'title': 'Solution Blueprint', 'sectionId': 'SBP00'},
      ],
      'classes': {
        'D00SolutionBlueprint': {
          'name': 'D00SolutionBlueprint',
          'sectionId': 'SBP00',
          'doc': 'Root of a solution blueprint document.',
          'fields': [
            {
              'name': 'vision',
              'kind': 'content',
              'sectionId': 'SBP00-VIS',
              'contentType': 'text',
              'doc': 'Why the system exists.',
            },
          ],
        },
      },
    });

/// The D4rt script: imports ONLY the bridged SOM packages (no engine-internal
/// access) and exercises the typed facade, the generic runtime, and the query
/// engine against the two arguments native code passes in.
const _script = r'''
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

main(doc, model) {
  // (1) Typed facade write — through the generated tom_som_dart_v0 surface.
  final sbp = D00SolutionBlueprint(doc);
  sbp.content = 'Vision via typed facade';

  // (2) Generic runtime write — at a model-aligned path so the query can see it.
  doc.setContent('SBP00/SBP00-VIS', 'Deliver a resilient rollout platform.');

  // (3) Generic read of what the typed facade just wrote (shared document).
  final typedReadBack = doc.content('SBP/content');

  // (4) Query / cursor — the lexical-structural facility (item 7a) over the
  //     shared (model, document) pair, returning a lazy cursor.
  final engine = SpecQueryEngine(model: model, document: doc);
  final cursor = engine.query(SpecQuery(text: 'resilient'));
  final match = cursor.next();
  final matchPath = match == null ? 'NONE' : match.path;

  return {'typedReadBack': typedReadBack, 'matchPath': matchPath};
}
''';

void main() {
  group('SOM D4rt bridge round-trip (step 5 / item 7c)', () {
    late D4rt d4rt;
    late SpecDocument doc;
    late SpecModel model;

    setUp(() {
      d4rt = D4rt();
      TomSomBridge.register(d4rt);
      doc = SpecDocument();
      model = _fixtureModel();
    });

    test('script drives typed + generic API and a query against the native '
        'document, and native code sees every edit', () {
      final result = d4rt.execute(
        source: _script,
        positionalArgs: [doc, model],
      ) as Map;

      // The script's own observations (read back inside the sandbox).
      expect(result['typedReadBack'], 'Vision via typed facade');
      expect(result['matchPath'], 'SBP00/SBP00-VIS');

      // The decisive check: native code's *own* document object carries the
      // edits the script made — same in-memory representation, both paths.
      expect(doc.content('SBP/content'), 'Vision via typed facade',
          reason: 'typed facade write must land in the native document');
      expect(doc.content('SBP00/SBP00-VIS'),
          'Deliver a resilient rollout platform.',
          reason: 'generic write must land in the native document');
    });

    test('a query the script runs returns a live cursor native code can also '
        'iterate over the same shared document', () {
      d4rt.execute(source: _script, positionalArgs: [doc, model]);

      // Native code runs the same query over its own objects and gets the cursor.
      final engine = SpecQueryEngine(model: model, document: doc);
      final cursor = engine.query(const SpecQuery(text: 'resilient'));
      final match = cursor.next();
      expect(match, isNotNull);
      expect(match!.path, 'SBP00/SBP00-VIS');
    });
  });
}
