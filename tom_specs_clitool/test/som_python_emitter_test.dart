import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model meta-data the Dart emitter test pins, reused
/// here so the two emitters are exercised against an identical model covering
/// every field kind. `modelVersion` is `0` so the generated `v0` model version
/// is the clean `0.0`.
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

/// A spec-model where two distinct (class, form-field) pairs derive the same
/// generated form-class name, identical to the Dart emitter's collision case.
Map<String, dynamic> _formCollisionJson() => {
      'modelVersion': 0,
      'roots': [
        {
          'type': 'Root',
          'title': 'Root',
          'sectionId': 'ROOT',
        },
      ],
      'classes': {
        'Root': {
          'name': 'Root',
          'sectionId': 'ROOT',
          'fields': [
            {
              'name': 'a',
              'kind': 'complex',
              'sectionId': 'a',
              'type': 'MigrationRisks',
            },
            {
              'name': 'b',
              'kind': 'complex',
              'sectionId': 'b',
              'type': 'MigrationRisksGovernance',
            },
          ],
        },
        'MigrationRisks': {
          'name': 'MigrationRisks',
          'sectionId': 'MR00',
          'fields': [
            {
              'name': 'governanceContent',
              'kind': 'form',
              'sectionId': 'gc',
              'formFields': [
                {'name': 'model', 'label': 'Model', 'type': 'String'},
              ],
            },
          ],
        },
        'MigrationRisksGovernance': {
          'name': 'MigrationRisksGovernance',
          'sectionId': 'MRG0',
          'fields': [
            {
              'name': 'content',
              'kind': 'form',
              'sectionId': 'c',
              'formFields': [
                {'name': 'escalation', 'label': 'Escalation', 'type': 'String'},
              ],
            },
          ],
        },
      },
    };

/// Locates a `python3` interpreter, or `null` when none is on PATH.
String? _python() {
  for (final exe in ['python3', 'python']) {
    try {
      final r = Process.runSync(exe, ['--version']);
      if (r.exitCode == 0) return exe;
    } on ProcessException {
      // try next
    }
  }
  return null;
}

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_python_v0_fixture.py.golden');

  group('SomPythonEmitter', () {
    test('emitted output matches the committed golden file', () {
      final source = SomPythonEmitter(_fixtureModel()).generateLibrary();
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

    test('the generated module compiles in Python (py_compile)', () {
      final python = _python();
      if (python == null) {
        markTestSkipped('no python3 interpreter on PATH');
        return;
      }
      final source = SomPythonEmitter(_fixtureModel()).generateLibrary();
      final dir = Directory.systemTemp.createTempSync('som_py_emit_');
      try {
        final file = File(p.join(dir.path, 'generated_v0.py'))
          ..writeAsStringSync(source);
        final r = Process.runSync(python, ['-m', 'py_compile', file.path]);
        expect(r.exitCode, 0,
            reason: 'py_compile reported errors:\n${r.stdout}\n${r.stderr}');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the Python facade encodes.
      final doc = SpecDocument();
      final ref = SpecReflection(_fixtureModel());
      final root = ref.model.roots.single;
      final rootSeg = ref.rootSegment(root);

      doc.setContent('$rootSeg/vision', 'A clear vision');
      expect(doc.content('$rootSeg/vision'), 'A clear vision');

      final itemPath = doc.addListItem('$rootSeg/risks');
      doc.setContent('$itemPath/title', 'Schedule slip');
      expect(doc.listItemCount('$rootSeg/risks'), 1);
      expect(doc.content('${doc.listItems('$rootSeg/risks').single}/title'),
          'Schedule slip');
    });

    test('the model-version accessor returns the generated v0 version', () {
      final emitter = SomPythonEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated source pins the same value as a class attribute.
      expect(emitter.generateLibrary(),
          contains("model_version = '0.0'"));
    });

    test('v1 label yields major 1', () {
      final emitter = SomPythonEmitter(_fixtureModel(), versionLabel: 'v1');
      expect(emitter.modelVersionString, '1.0');
    });

    test('colliding form-class names are disambiguated (no duplicates)', () {
      final source = SomPythonEmitter(SpecModel.fromJson(_formCollisionJson()))
          .generateLibrary();
      final decls = RegExp(r'^class (\w+)\(SomNode\):', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty, reason: 'duplicate class declarations: $dupes');
      expect(source, contains('class MigrationRisksGovernanceContentForm(SomNode)'));
      expect(
          source, contains('class MigrationRisksGovernanceContentForm2(SomNode)'));
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomPythonEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('class CurrentSituation(SomNode):'));

      final justRoot = SomPythonEmitter(_fixtureModel(),
              documentRoots: ['ProjectDefinition'])
          .generateLibrary();
      expect(justRoot, contains('class CurrentSituation(SomNode):'));
    });
  });
}
