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
          'type': 'SolutionBlueprint',
          'title': 'Project Definition',
          'sectionId': 'PD00',
          'description': 'The structured project overview.',
        },
      ],
      'classes': {
        'SolutionBlueprint': {
          'name': 'SolutionBlueprint',
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
              'sectionIdPattern': 'RISK-ITEM-xxx',
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
              'type': 'CurrentLandscapeAssessment',
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
        'CurrentLandscapeAssessment': {
          'name': 'CurrentLandscapeAssessment',
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
  final metaGoldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_python_v0_meta_fixture.py.golden');

  group('SomPythonEmitter', () {
    test('emitted output matches the committed golden files', () {
      final source = SomPythonEmitter(_fixtureModel()).generateLibrary();
      // The facade wildcard-imports its sibling meta module (SOM §8), so the
      // meta golden is pinned alongside — the runtime facade test loads both.
      final metaSource = SomPythonMetaEmitter(_fixtureModel()).generateLibrary();
      final golden = File(goldenPath);
      final metaGolden = File(metaGoldenPath);
      // Bootstrap / intentional regeneration: `UPDATE_GOLDEN=1 dart test ...`.
      if (Platform.environment['UPDATE_GOLDEN'] == '1') {
        golden.parent.createSync(recursive: true);
        golden.writeAsStringSync(source);
        metaGolden.writeAsStringSync(metaSource);
      }
      expect(golden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the golden file');
      expect(metaGolden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the meta golden file');
      expect(source, golden.readAsStringSync());
      expect(metaSource, metaGolden.readAsStringSync());
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

    test('the model version comes from the model stamp, not the version label',
        () {
      // A stamped model reports its real major.minor (§2.1) regardless of the
      // project version label — the label only names the output project.
      final stamped = SpecModel.fromJson({
        ..._fixtureJson(),
        'modelVersion': 1,
        'modelVersionLabel': '1.3.0+7.abc1234',
      });
      expect(SomPythonEmitter(stamped, versionLabel: 'v0').modelVersionString,
          '1.3');
      expect(SomPythonEmitter(stamped, versionLabel: 'v9').modelVersionString,
          '1.3');
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

    test('a pattern-bearing list emits its @SectionIdPattern; a scalar list '
        'does not (AA1 criteria 3–5)', () {
      final source = SomPythonEmitter(_fixtureModel()).generateLibrary();
      // The complex `risks` list carries a pattern → the SomList is constructed
      // with the `pattern=` argument so the facade can generate section ids.
      expect(
          RegExp(r'def risks\(self\):[\s\S]*?SomList\(self\.doc,[\s\S]*?'
                  r'pattern="RISK-ITEM-xxx"\)')
              .hasMatch(source),
          isTrue,
          reason: 'risks getter must pass pattern= to SomList');
      // The pattern-less scalar `tags` list must NOT get a pattern argument.
      final tagsBody = RegExp(r'def tags\(self\):\n.*return SomList\(.*\)')
          .firstMatch(source)!
          .group(0)!;
      expect(tagsBody, isNot(contains('pattern=')));
    });

    test('path-constant holders are retired; the meta module is re-exported '
        '(SOM §8)', () {
      final source = SomPythonEmitter(_fixtureModel()).generateLibrary();
      // SOM §8: the former per-root `<Code>Paths` holders are gone from the
      // main facade module …
      expect(source, isNot(contains('Pd00Paths')));
      expect(source, isNot(contains('vision = "PD00/vision"')));
      // … replaced by the generated metadata module (dot-notation + ID tree),
      // wildcard re-imported so one import gives both surfaces, and the root
      // load classmethods pass the populated tree to the codec.
      expect(source,
          contains('from tom_som_python_v0_meta import *  # noqa: F401,F403'));
      expect(source,
          contains('SpecDocument.from_yaml(yaml, solutionBlueprintMetaTree)'));
      expect(source,
          contains('SpecDocument.from_file(path, solutionBlueprintMetaTree)'));
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomPythonEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('class CurrentLandscapeAssessment(SomNode):'));

      final justRoot = SomPythonEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(justRoot, contains('class CurrentLandscapeAssessment(SomNode):'));
    });
  });
}
