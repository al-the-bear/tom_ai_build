import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model meta-data the Dart/Python emitter tests pin,
/// reused here so all three emitters are exercised against an identical model
/// covering every field kind. `modelVersion` is `0` so the generated `v0` model
/// version is the clean `0.0`.
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

/// A spec-model where a Dart field name is a Java reserved word (`class`,
/// `for`), and an enum constant is one too (`default`) — exercising the accessor
/// keyword-sanitiser while keeping the stored path segment / enum token intact.
Map<String, dynamic> _keywordJson() => {
      'modelVersion': 0,
      'roots': [
        {'type': 'Root', 'title': 'Root', 'sectionId': 'ROOT'},
      ],
      'classes': {
        'Root': {
          'name': 'Root',
          'sectionId': 'ROOT',
          'fields': [
            {
              'name': 'class',
              'kind': 'content',
              'sectionId': 'cls',
              'contentType': 'text',
            },
            {
              'name': 'mode',
              'kind': 'enum',
              'sectionId': 'mode',
              'enumType': 'Mode',
              'enumValues': ['default', 'custom'],
            },
          ],
        },
      },
    };

/// A spec-model where two distinct (class, form-field) pairs derive the same
/// generated form-class name, identical to the Dart/Python emitter's collision
/// case.
Map<String, dynamic> _formCollisionJson() => {
      'modelVersion': 0,
      'roots': [
        {'type': 'Root', 'title': 'Root', 'sectionId': 'ROOT'},
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

/// Locates a `javac` compiler, or `null` when none is on PATH.
String? _javac() {
  try {
    final r = Process.runSync('javac', ['-version']);
    if (r.exitCode == 0) return 'javac';
  } on ProcessException {
    // none on PATH
  }
  return null;
}

/// The `tom_som_java_runtime/src` directory, relative to the clitool root the
/// test runs from, or `null` when it cannot be located.
String? _runtimeSrc() {
  final candidate = p.normalize(p.join(
      Directory.current.path, '..', 'tom_som_java_runtime', 'src'));
  return Directory(candidate).existsSync() ? candidate : null;
}

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_java_v0_fixture.java.golden');
  final metaGoldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_java_v0_meta_fixture.java.golden');

  group('SomJavaEmitter', () {
    test('emitted output matches the committed golden files (facade + meta)',
        () {
      final source = SomJavaEmitter(_fixtureModel()).generateLibrary();
      final metaSource =
          SomJavaMetaEmitter(_fixtureModel()).generateLibrary();
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
          reason: 'run with UPDATE_GOLDEN=1 to create the golden file');
      expect(source, golden.readAsStringSync());
      expect(metaSource, metaGolden.readAsStringSync());
    });

    test('the generated source compiles against the runtime (javac)', () {
      final javac = _javac();
      if (javac == null) {
        markTestSkipped('no javac on PATH');
        return;
      }
      final runtimeSrc = _runtimeSrc();
      if (runtimeSrc == null) {
        markTestSkipped('tom_som_java_runtime/src not found');
        return;
      }
      final source = SomJavaEmitter(_fixtureModel()).generateLibrary();
      // The facade's loaders reference the sibling metadata module (SOM §8), so
      // the two compile together — exactly how the generator lays them out.
      final metaSource =
          SomJavaMetaEmitter(_fixtureModel()).generateLibrary();
      final dir = Directory.systemTemp.createTempSync('som_java_emit_');
      try {
        final pkgDir = Directory(p.join(dir.path, 'src', 'tom_som_java_v0'))
          ..createSync(recursive: true);
        File(p.join(pkgDir.path, 'TomSomV0.java')).writeAsStringSync(source);
        File(p.join(pkgDir.path, 'TomSomV0Meta.java'))
            .writeAsStringSync(metaSource);
        final outDir = Directory(p.join(dir.path, 'out'))..createSync();
        final sep = Platform.isWindows ? ';' : ':';
        final r = Process.runSync('javac', [
          '-Xlint:all',
          '-d',
          outDir.path,
          '-sourcepath',
          '${p.join(dir.path, 'src')}$sep$runtimeSrc',
          p.join(pkgDir.path, 'TomSomV0.java'),
          p.join(pkgDir.path, 'TomSomV0Meta.java'),
        ]);
        expect(r.exitCode, 0,
            reason: 'javac reported errors:\n${r.stdout}\n${r.stderr}');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the Java facade encodes.
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
      final emitter = SomJavaEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated source pins the same value as a class constant.
      expect(emitter.generateLibrary(),
          contains('MODEL_VERSION = "0.0";'));
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
      expect(
          SomJavaEmitter(stamped, versionLabel: 'v0').modelVersionString, '1.3');
      expect(
          SomJavaEmitter(stamped, versionLabel: 'v9').modelVersionString, '1.3');
    });

    test('Java reserved words are sanitised in accessors and enum constants, '
        'but path segments and tokens are preserved', () {
      final source =
          SomJavaEmitter(SpecModel.fromJson(_keywordJson())).generateLibrary();
      // Field `class` → method `class_()`, path segment `cls` untouched.
      expect(source, contains('public String class_()'));
      expect(source, contains('path + "/cls"'));
      expect(source, isNot(contains('public String class()')));
      // Enum constant `default` → identifier `default_`, token stays `default`.
      expect(source, contains('default_("default")'));
      expect(source, isNot(contains('\n      default(')));
    });

    test('colliding form-class names are disambiguated (no duplicates)', () {
      final source = SomJavaEmitter(SpecModel.fromJson(_formCollisionJson()))
          .generateLibrary();
      final decls =
          RegExp(r'class (\w+) extends SomNode', multiLine: true)
              .allMatches(source)
              .map((m) => m.group(1)!)
              .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty, reason: 'duplicate class declarations: $dupes');
      expect(source,
          contains('class MigrationRisksGovernanceContentForm extends SomNode'));
      expect(
          source,
          contains(
              'class MigrationRisksGovernanceContentForm2 extends SomNode'));
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomJavaEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('class CurrentLandscapeAssessment extends SomNode'));

      final justRoot = SomJavaEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(justRoot, contains('class CurrentLandscapeAssessment extends SomNode'));
    });

    test(
        'no flat path-constant holder is emitted; the loaders thread the '
        'generated metadata trees', () {
      final source = SomJavaEmitter(_fixtureModel()).generateLibrary();
      // Path addressing lives solely in the dot-notation / ID-tree surfaces
      // of the sibling meta module (SOM §8).
      expect(source, isNot(contains('Pd00Paths')));
      expect(source, isNot(contains('public static final String vision')));
      // The root loaders thread the root's generated SomMetaTree .
      expect(
          source,
          contains('SpecDocument.fromYaml(yaml, '
              'TomSomV0Meta.SolutionBlueprintMetaTree)'));
      expect(
          source,
          contains('SpecDocument.fromFile(path, '
              'TomSomV0Meta.SolutionBlueprintMetaTree)'));
    });
  });
}
