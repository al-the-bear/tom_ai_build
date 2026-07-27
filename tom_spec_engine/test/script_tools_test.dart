import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 13 / `llm_and_d4rt_tools.md` §8.1 — the **script tools**: the
/// engine-side logic behind the editor's `script_author` / `script_validate` /
/// `script_run` / `script_list` / `script_get` MCP tools.
///
/// `script_author` stores a named `*.d4rt.dart` under `agent/scripts/` (recording
/// the scopes it targets); `script_validate` parse/type-checks against the
/// granted scope **without** running; `script_run` executes via `D4rt.execute`
/// under the named scopes and captures **all three output channels** — stdout,
/// the auto-awaited `main()` return, and any error/stack. Mutations during a run
/// route through the same controller a tool mutation does (req c).
///
/// Done-criterion (plan step 13): author → validate → run round-trips, capturing
/// all three output channels.
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

/// A controller that records every effective mutation (the run-mutation tests
/// assert a script edit lands here exactly like a tool edit).
class _RecordingController implements SpecController {
  _RecordingController(this.document);

  final SpecDocument document;
  final List<String> log = [];

  @override
  String? content(String path) => document.content(path);

  @override
  String? formField(String path, String field) =>
      document.formField(path, field);

  @override
  List<String> listItems(String listPath) => document.listItems(listPath);

  @override
  void setContent(String path, String value) {
    document.setContent(path, value);
    log.add('setContent $path=$value');
  }

  @override
  void setFormField(String path, String field, String value) {
    document.setFormField(path, field, value);
    log.add('setFormField $path.$field=$value');
  }

  @override
  String addListItem(String listPath) {
    final itemPath = document.addListItem(listPath);
    log.add('addListItem $itemPath');
    return itemPath;
  }

  @override
  bool removeListItem(String itemPath) {
    final removed = document.removeListItem(itemPath);
    if (removed) log.add('removeListItem $itemPath');
    return removed;
  }

  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) =>
      throw UnimplementedError();
}

void main() {
  late _RecordingController controller;
  late ScriptTools tools;
  late String workspaceRoot;

  setUp(() {
    final tmp = Directory.systemTemp.createTempSync('tse_step13_');
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
    workspaceRoot = tmp.path;

    final doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'platform overview summary');
    controller = _RecordingController(doc);

    final engine = SpecQueryEngine(model: _model(), document: doc);
    final index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
    final recall = SpecRecall(index: index);

    final registry = ScopeRegistry()
      ..register(specScope(controller))
      ..register(memoryScope(recall));

    tools = ScriptTools(
      registry: registry,
      store: FileScriptStore(workspaceRoot),
    );
  });

  group('script_author', () {
    test('stores a *.d4rt.dart under agent/scripts and records its scopes', () {
      final authored = tools.author('x', 'main() {}', scopes: ['spec', 'memory']);
      expect(authored.name, 'x');
      expect(authored.scopes, ['spec', 'memory']);
      expect(authored.path, endsWith('agent/scripts/x.d4rt.dart'));
      expect(File(authored.path).existsSync(), isTrue);
    });

    test('rejects a name with path separators', () {
      expect(() => tools.author('../escape', 'main() {}'),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('script_list / script_get', () {
    test('lists authored scripts and fetches one with its recorded scopes', () {
      tools.author('alpha', 'main() {}', scopes: ['spec']);
      tools.author('beta', 'main() {}', scopes: ['memory']);

      expect(tools.list().map((s) => s.name), containsAll(['alpha', 'beta']));

      final got = tools.get('beta');
      expect(got.name, 'beta');
      expect(got.scopes, ['memory']);
      expect(got.source, contains('main() {}'));
    });

    test('get on an unknown script throws', () {
      expect(() => tools.get('nope'), throwsA(anything));
    });
  });

  group('script_validate (no run)', () {
    test('a well-formed script validates ok with no diagnostics', () {
      final v = tools.validate(
        source: "import 'package:tom_spec_engine/spec_api.dart';\nmain() {}",
        scopes: ['spec'],
      );
      expect(v.ok, isTrue);
      expect(v.diagnostics, isEmpty);
    });

    test('a syntactically broken script reports diagnostics and does not run',
        () {
      final v = tools.validate(
        source: "main() { this is not valid );",
        scopes: ['spec'],
      );
      expect(v.ok, isFalse);
      expect(v.diagnostics, isNotEmpty);
      // Validation never executes main, so nothing reached the controller.
      expect(controller.log, isEmpty);
    });

    test('validating a mutating script does not perform the mutation', () {
      tools.validate(
        source: '''
import 'package:tom_spec_engine/spec_api.dart';
main() { spec.setContent('PD00/VIS', 'should not happen'); }
''',
        scopes: ['spec'],
      );
      expect(controller.log, isEmpty);
      expect(controller.content('PD00/VIS'), 'resilient rollout platform');
    });
  });

  group('script_validate (deeper type-checking — F19)', () {
    test('reports a missing main() entrypoint', () {
      final v = tools.validate(source: 'int answer() => 42;', scopes: ['spec']);
      expect(v.ok, isFalse);
      expect(v.diagnostics.single, contains('no `main()`'));
      expect(v.entrypoint, isNotNull);
      expect(v.entrypoint!.exists, isFalse);
      expect(v.toJson()['entrypoint'], {'exists': false});
    });

    test('introspects the entrypoint argument contract', () {
      final v = tools.validate(
        source: 'main(String topic, [int depth = 1]) {}',
        scopes: ['spec'],
      );
      expect(v.ok, isTrue);
      final ep = v.entrypoint!;
      expect(ep.exists, isTrue);
      expect(ep.requiredPositional, 1);
      expect(ep.maxPositional, 2);
      final json = v.toJson()['entrypoint'] as Map<String, Object?>;
      expect(json['requiredPositional'], 1);
      expect(json['maxPositional'], 2);
    });

    test('flags an async entrypoint in the contract', () {
      final v = tools.validate(source: 'main() async => 1;', scopes: ['spec']);
      expect(v.entrypoint!.isAsync, isTrue);
    });

    test('rejects too few positional args against the contract', () {
      final v = tools.validate(
        source: 'main(String topic) {}',
        scopes: ['spec'],
        args: const [],
      );
      expect(v.ok, isFalse);
      expect(v.diagnostics.single, contains('at least 1'));
    });

    test('rejects too many positional args against the contract', () {
      final v = tools.validate(
        source: 'main() {}',
        scopes: ['spec'],
        args: const ['extra'],
      );
      expect(v.ok, isFalse);
      expect(v.diagnostics.single, contains('at most 0'));
    });

    test('accepts args that fit the optional-positional contract', () {
      final v = tools.validate(
        source: 'main(String topic, [int depth = 1]) {}',
        scopes: ['spec'],
        args: const ['rollout', 3],
      );
      expect(v.ok, isTrue);
      expect(v.diagnostics, isEmpty);
    });

    test('a syntactically broken script yields a null entrypoint', () {
      final v = tools.validate(source: 'main( {', scopes: ['spec']);
      expect(v.ok, isFalse);
      expect(v.entrypoint, isNull);
      expect(v.toJson().containsKey('entrypoint'), isFalse);
    });
  });

  group('script_run (captures three channels)', () {
    test('captures stdout and the auto-awaited main() return value', () async {
      final run = await tools.run(
        source: '''
main() {
  print('line one');
  print('line two');
  return 42;
}
''',
        scopes: ['spec'],
      );
      expect(run.error, isNull);
      expect(run.stdout.trim().split('\n'), ['line one', 'line two']);
      expect(run.result, 42);
    });

    test('awaits an async main() return', () async {
      final run = await tools.run(
        source: 'main() async => 7 * 6;',
        scopes: ['spec'],
      );
      expect(run.error, isNull);
      expect(run.result, 42);
    });

    test('captures an error and stack, with a null result', () async {
      final run = await tools.run(
        source: "main() { throw StateError('boom'); }",
        scopes: ['spec'],
      );
      expect(run.error, contains('boom'));
      expect(run.stack, isNotNull);
      expect(run.result, isNull);
    });

    test('a run mutation lands in the controller change log', () async {
      final run = await tools.run(
        source: '''
import 'package:tom_spec_engine/spec_api.dart';
main() { spec.setContent('PD00/VIS', 'via script'); }
''',
        scopes: ['spec'],
      );
      expect(run.error, isNull);
      expect(controller.log, contains('setContent PD00/VIS=via script'));
      expect(controller.content('PD00/VIS'), 'via script');
    });

    test('passes positional args to main() when the contract fits', () async {
      final run = await tools.run(
        source: 'main(String topic) => topic.toUpperCase();',
        scopes: ['spec'],
        args: const ['rollout'],
      );
      expect(run.error, isNull);
      expect(run.result, 'ROLLOUT');
    });

    test('fails fast on an arg-contract mismatch instead of an opaque error',
        () async {
      final run = await tools.run(
        source: 'main() {}',
        scopes: ['spec'],
        args: const ['unexpected'],
      );
      expect(run.ok, isFalse);
      expect(run.error, contains('at most 0'));
      expect(run.stack, isNull);
      expect(run.result, isNull);
      // The contract is checked before execution — nothing reached stdout.
      expect(run.stdout, isEmpty);
    });

    test('run by name uses the script\'s recorded scopes', () async {
      tools.author('recallit', '''
import 'package:tom_spec_engine/memory.dart';
main() async => await memory.recallPaths('resilient rollout platform');
''', scopes: ['memory']);

      // No scopes passed → the recorded `memory` scope must be applied, so the
      // `memory` global resolves.
      final run = await tools.run(name: 'recallit');
      expect(run.error, isNull);
      expect((run.result as List).cast<String>(), contains('PD00/VIS'));
    });
  });

  group('round-trip (done-criterion)', () {
    test('author -> validate -> run captures all three channels', () async {
      final authored = tools.author('greet', '''
import 'package:tom_spec_engine/spec_api.dart';
main() {
  print('hello from script');
  spec.setContent('PD00/VIS', 'authored vision');
  return spec.content('PD00/VIS');
}
''', scopes: ['spec']);
      expect(authored.path, endsWith('agent/scripts/greet.d4rt.dart'));

      final validation = tools.validate(name: 'greet');
      expect(validation.ok, isTrue);

      final run = await tools.run(name: 'greet');
      expect(run.stdout.trim(), 'hello from script');
      expect(run.result, 'authored vision');
      expect(run.error, isNull);
      expect(controller.content('PD00/VIS'), 'authored vision');
    });
  });
}
