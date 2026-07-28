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
/// generated form-class name (`<class><Pascal(field)>Form`):
///   - `MigrationRisks.governanceContent` → `MigrationRisksGovernanceContentForm`
///   - `MigrationRisksGovernance.content`  → `MigrationRisksGovernanceContentForm`
/// The emitter must disambiguate so the generated library has no duplicate
/// class declarations.
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
        // The facade exports its sibling meta library (SOM §8), so write both —
        // the export in the facade is by the committed package file name.
        File(p.join(libDir.path, 'tom_som_dart_v0.dart'))
            .writeAsStringSync(source);
        File(p.join(libDir.path, 'tom_som_dart_v0_meta.dart')).writeAsStringSync(
            SomDartMetaEmitter(_fixtureModel()).generateLibrary());
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

    test('the model version comes from the model stamp, not the version label',
        () {
      // A stamped model reports its real major.minor (SOM §4.2) regardless of
      // the project version label — the label only names the output project.
      final stamped = SpecModel.fromJson({
        ..._fixtureJson(),
        'modelVersion': 1,
        'modelVersionLabel': '1.3.0+7.abc1234',
      });
      expect(SomDartEmitter(stamped, versionLabel: 'v0').modelVersionString,
          '1.3');
      expect(SomDartEmitter(stamped, versionLabel: 'v9').modelVersionString,
          '1.3');
    });

    test('colliding form-class names are disambiguated (no duplicates)', () {
      final source =
          SomDartEmitter(SpecModel.fromJson(_formCollisionJson()))
              .generateLibrary();
      // Collect every emitted class declaration name.
      final decls = RegExp(r'^class (\w+) extends SomNode', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty,
          reason: 'duplicate class declarations: $dupes');
      // The base name is used once; the colliding one gets a numeric suffix.
      expect(source, contains('class MigrationRisksGovernanceContentForm '));
      expect(source, contains('class MigrationRisksGovernanceContentForm2 '));
      // Each form getter references a declared form class (no dangling type).
      for (final m in RegExp(r'(\w+Form) get \w+ =>').allMatches(source)) {
        final typeName = m.group(1)!;
        expect(decls, contains(typeName),
            reason: 'getter references undeclared form class $typeName');
      }
    });

    test('a pattern-bearing list emits its @SectionIdPattern; a scalar list '
        'does not (AA1 criteria 3–5)', () {
      final source = SomDartEmitter(_fixtureModel()).generateLibrary();
      // The complex `risks` list carries a pattern → the SomList is constructed
      // with the `pattern:` argument so the facade can generate section ids.
      expect(source,
          contains("SomList<Risk> get risks => SomList<Risk>(doc, "));
      expect(
          RegExp(r"get risks =>.*pattern: 'RISK-ITEM-xxx'\)").hasMatch(source),
          isTrue,
          reason: 'risks getter must pass pattern: to SomList');
      // The pattern-less scalar `tags` list must NOT get a pattern argument.
      final tagsLine = RegExp(r'get tags =>.*;').firstMatch(source)!.group(0)!;
      expect(tagsLine, isNot(contains('pattern:')));
    });

    test('no flat path-constant holder is emitted; the meta library is '
        'exported (SOM §8)', () {
      final source = SomDartEmitter(_fixtureModel()).generateLibrary();
      // SOM §8: the facade library carries no per-root `<Code>Paths` holder
      // …
      expect(source, isNot(contains('Pd00Paths')));
      expect(source, isNot(contains('static const String vision =')));
      // … replaced by the generated metadata library (dot-notation + ID tree),
      // re-exported from the facade so one import gives both surfaces.
      expect(source, contains("export 'tom_som_dart_v0_meta.dart';"));
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomDartEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('class CurrentLandscapeAssessment extends SomNode'));

      // CurrentLandscapeAssessment is only reachable via SolutionBlueprint; an empty
      // subset still includes it (it is reachable from the single root).
      final justRoot = SomDartEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(justRoot, contains('class CurrentLandscapeAssessment extends SomNode'));
    });
  });
}
