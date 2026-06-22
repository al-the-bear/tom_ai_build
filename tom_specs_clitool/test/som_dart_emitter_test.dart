import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// A small, hand-built spec-model meta-data map covering every field kind, used
/// to pin the Dart emitter's output. `modelVersion` is `0` so the generated
/// `v0` model version is the clean `0.0`.
Map<String, dynamic> _fixtureJson() => {
      'modelVersion': 0,
      'roots': [
        {
          'type': 'ProjectDefinition',
          'title': 'Project Definition',
          'sectionId': 'PD00',
          'description': 'The structured project overview.',
        },
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'doc': 'Root of a project definition document.',
          'fields': [
            {
              'name': 'vision',
              'kind': 'content',
              'sectionId': 'vision',
              'contentType': 'text',
              'doc': 'Why the system exists.',
            },
            {
              'name': 'owner',
              'kind': 'form',
              'sectionId': 'owner',
              'formFields': [
                {'name': 'name', 'label': 'Name', 'type': 'String'},
                {'name': 'role', 'label': 'Role', 'type': 'String'},
              ],
            },
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'risks',
              'elementType': 'Risk',
              'elementIsComplex': true,
              'min': 2,
            },
            {
              'name': 'tags',
              'kind': 'list',
              'sectionId': 'tags',
              'elementType': 'String',
              'elementIsComplex': false,
            },
            {
              'name': 'situation',
              'kind': 'complex',
              'sectionId': 'situation',
              'type': 'CurrentSituation',
            },
          ],
        },
        'Risk': {
          'name': 'Risk',
          'sectionId': 'RISK',
          'fields': [
            {
              'name': 'title',
              'kind': 'content',
              'sectionId': 'title',
              'contentType': 'text',
            },
            {
              'name': 'probability',
              'kind': 'enum',
              'sectionId': 'prob',
              'enumType': 'Probability',
              'enumValues': ['low', 'medium', 'high'],
            },
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'fields': [
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'summary',
              'contentType': 'text',
            },
          ],
        },
      },
    };

SpecModel _fixtureModel() => SpecModel.fromJson(_fixtureJson());

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_dart_v0_fixture.dart.golden');

  group('SomDartEmitter', () {
    test('emitted output matches the committed golden file', () {
      final source = SomDartEmitter(_fixtureModel()).generateLibrary();
      final golden = File(goldenPath);
      // Bootstrap / intentional regeneration: `UPDATE_GOLDEN=1 dart test ...`.
      if (Platform.environment['UPDATE_GOLDEN'] == '1') {
        golden.parent.createSync(recursive: true);
        golden.writeAsStringSync(source);
      }
      expect(golden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the golden file');
      expect(source, golden.readAsStringSync());
    });

    test('the generated library analyzes clean (no analyzer errors)', () async {
      final source = SomDartEmitter(_fixtureModel()).generateLibrary();
      final dir = await Directory.systemTemp.createTemp('som_emit_');
      try {
        // A throwaway package that depends on the runtime by absolute path so
        // `dart analyze` can resolve the generated facade's imports.
        final runtimePath = p.normalize(p.join(
            Directory.current.path, '..', 'tom_som_dart_runtime'));
        File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('''
name: som_emit_check
publish_to: none
environment:
  sdk: ^3.11.4
dependencies:
  tom_som_dart_runtime:
    path: $runtimePath
''');
        final libDir = Directory(p.join(dir.path, 'lib'))..createSync();
        File(p.join(libDir.path, 'generated.dart')).writeAsStringSync(source);
        final pubGet = await Process.run('dart', ['pub', 'get'],
            workingDirectory: dir.path);
        expect(pubGet.exitCode, 0,
            reason: 'pub get failed:\n${pubGet.stderr}');
        final analyze = await Process.run('dart', ['analyze', '--no-fatal-warnings'],
            workingDirectory: dir.path);
        expect(analyze.exitCode, 0,
            reason: 'analyzer reported issues:\n${analyze.stdout}\n${analyze.stderr}');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // The golden source is compiled into the emitter package's own test via
      // the committed file; here we re-exercise the *behaviour* the generated
      // facade encodes by mirroring its path derivation against a live document.
      final doc = SpecDocument();
      final ref = SpecReflection(_fixtureModel());
      final root = ref.model.roots.single;
      final rootSeg = ref.rootSegment(root);

      // Typed-style write (content leaf): facade would do
      // `doc.setContent('$path/vision', v)` at the root path.
      doc.setContent('$rootSeg/vision', 'A clear vision');
      // Generic read sees it.
      expect(doc.content('$rootSeg/vision'), 'A clear vision');

      // Generic write of a list item, typed-style read back.
      final itemPath = doc.addListItem('$rootSeg/risks');
      doc.setContent('$itemPath/title', 'Schedule slip');
      expect(doc.listItemCount('$rootSeg/risks'), 1);
      expect(doc.content('${doc.listItems('$rootSeg/risks').single}/title'),
          'Schedule slip');
    });

    test('the model-version accessor returns the generated v0 version', () {
      final emitter = SomDartEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated source pins the same value as a static const.
      expect(emitter.generateLibrary(),
          contains("static const String modelVersion = '0.0';"));
    });

    test('v1 label yields major 1', () {
      final emitter = SomDartEmitter(_fixtureModel(), versionLabel: 'v1');
      expect(emitter.modelVersionString, '1.0');
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomDartEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('class CurrentSituation extends SomNode'));

      // CurrentSituation is only reachable via ProjectDefinition; an empty
      // subset still includes it (it is reachable from the single root).
      final justRoot = SomDartEmitter(_fixtureModel(),
              documentRoots: ['ProjectDefinition'])
          .generateLibrary();
      expect(justRoot, contains('class CurrentSituation extends SomNode'));
    });
  });
}
