import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model meta-data the Dart/Python/Java/JavaScript
/// emitter tests pin, reused here so all five emitters are exercised against an
/// identical model covering every field kind. `modelVersion` is `0` so the
/// generated `v0` model version is the clean `0.0`.
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

/// A spec-model where a Dart field name is a TS reserved word (`class`), and an
/// enum constant is one too (`default`) — exercising the accessor
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
/// generated form-class name, identical to the Dart/Python/Java/JavaScript
/// emitter's collision case.
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

/// The `tom_som_typescript_runtime` package dir, relative to the clitool root the
/// test runs from, or `null` when it cannot be located.
String? _runtimeDir() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_typescript_runtime'));
  return Directory(candidate).existsSync() ? candidate : null;
}

/// The project-local `tsc` binary inside the runtime's `node_modules`, or `null`
/// when the runtime has not been `npm install`ed yet.
String? _tsc(String runtimeDir) {
  final bin = p.join(runtimeDir, 'node_modules', '.bin', 'tsc');
  return File(bin).existsSync() ? bin : null;
}

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_typescript_v0_fixture.ts.golden');
  final metaGoldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_typescript_v0_meta_fixture.ts.golden');

  group('SomTypeScriptEmitter', () {
    test('emitted output matches the committed golden files', () {
      final source = SomTypeScriptEmitter(_fixtureModel()).generateLibrary();
      // The facade imports its sibling meta module (SOM §8), so the meta
      // golden is pinned alongside — the compile test type-checks both.
      final metaSource =
          SomTypeScriptMetaEmitter(_fixtureModel()).generateLibrary();
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

    test('the generated module tsc-compiles clean against the runtime types',
        () {
      final runtimeDir = _runtimeDir();
      if (runtimeDir == null) {
        markTestSkipped('tom_som_typescript_runtime not found');
        return;
      }
      final tsc = _tsc(runtimeDir);
      if (tsc == null) {
        markTestSkipped('project-local tsc not installed in the runtime');
        return;
      }
      final source = SomTypeScriptEmitter(_fixtureModel()).generateLibrary();
      final metaSource =
          SomTypeScriptMetaEmitter(_fixtureModel()).generateLibrary();
      final dir = Directory.systemTemp.createTempSync('som_ts_emit_');
      try {
        File(p.join(dir.path, 'tom_som_typescript_v0.ts'))
            .writeAsStringSync(source);
        // The facade imports its sibling meta module (SOM §8).
        File(p.join(dir.path, 'tom_som_typescript_v0_meta.ts'))
            .writeAsStringSync(metaSource);
        // Resolve the bare `tom_som_typescript_runtime` specifier to the runtime
        // *source* (index.ts) via a compile-time `paths` mapping — a pure
        // type-check, no `node_modules` link or `node` run required.
        final runtimeIndex =
            p.join(runtimeDir, 'src', 'index.ts').replaceAll('\\', '/');
        // The runtime uses Node built-ins (e.g. `fs` in `fromFile`), so the
        // type-check needs `@types/node` just like the real `npm run build`
        // does. Point `typeRoots` at the runtime's own installed `@types` so
        // `node` resolves from the temp dir; anything less (`types: []`) would
        // fail on the runtime's legitimate built-in imports.
        final runtimeTypes =
            p.join(runtimeDir, 'node_modules', '@types').replaceAll('\\', '/');
        final tsconfig = <String, Object?>{
          'compilerOptions': <String, Object?>{
            'target': 'ES2020',
            'lib': <String>['ES2020'],
            'module': 'commonjs',
            'moduleResolution': 'node',
            'ignoreDeprecations': '6.0',
            'strict': true,
            'esModuleInterop': true,
            'skipLibCheck': true,
            'noEmit': true,
            'baseUrl': '.',
            'paths': <String, Object?>{
              'tom_som_typescript_runtime': <String>[runtimeIndex],
            },
            'typeRoots': <String>[runtimeTypes],
            'types': <String>['node'],
          },
          'include': <String>['*.ts'],
        };
        File(p.join(dir.path, 'tsconfig.json'))
            .writeAsStringSync(jsonEncode(tsconfig));
        final r = Process.runSync(tsc, ['-p', 'tsconfig.json'],
            workingDirectory: dir.path);
        expect(r.exitCode, 0,
            reason: 'tsc compile failed:\n${r.stdout}\n${r.stderr}');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the TS facade encodes (pure-Dart variant).
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
      final emitter = SomTypeScriptEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated source pins the same value as a static class field.
      expect(emitter.generateLibrary(),
          contains('MODEL_VERSION: string = "0.0";'));
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
      expect(SomTypeScriptEmitter(stamped, versionLabel: 'v0').modelVersionString,
          '1.3');
      expect(SomTypeScriptEmitter(stamped, versionLabel: 'v9').modelVersionString,
          '1.3');
    });

    test('TS reserved words are sanitised in accessors, '
        'but path segments and enum tokens are preserved', () {
      final source = SomTypeScriptEmitter(SpecModel.fromJson(_keywordJson()))
          .generateLibrary();
      // Field `class` → accessor `class_`, path segment `cls` untouched.
      expect(source, contains('get class_(): string'));
      expect(source, contains('set class_(value: string)'));
      expect(source, contains('this.path + "/cls"'));
      expect(source, isNot(contains('get class()')));
      // Enum token `default` stays `default` (the object key/value is verbatim).
      expect(source, contains('"default": "default"'));
    });

    test('colliding form-class names are disambiguated (no duplicates)', () {
      final source =
          SomTypeScriptEmitter(SpecModel.fromJson(_formCollisionJson()))
              .generateLibrary();
      final decls =
          RegExp(r'export class (\w+) extends SomNode', multiLine: true)
              .allMatches(source)
              .map((m) => m.group(1)!)
              .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty, reason: 'duplicate class declarations: $dupes');
      expect(
          source,
          contains('export class MigrationRisksGovernanceContentForm '
              'extends SomNode'));
      expect(
          source,
          contains('export class MigrationRisksGovernanceContentForm2 '
              'extends SomNode'));
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomTypeScriptEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('export class CurrentLandscapeAssessment extends SomNode'));

      final justRoot = SomTypeScriptEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(
          justRoot, contains('export class CurrentLandscapeAssessment extends SomNode'));
    });

    test('a pattern-bearing list emits its @SectionIdPattern; a scalar list '
        'does not (AA1 criteria 3–5)', () {
      final source = SomTypeScriptEmitter(_fixtureModel()).generateLibrary();
      // The complex `risks` list carries a pattern → the SomList is constructed
      // with the trailing pattern argument so the facade can generate section
      // ids.
      expect(
          RegExp(r'get risks\(\): SomList<Risk> \{[\s\S]*?new SomList\('
                  r'this\.doc,[\s\S]*?"RISK-ITEM-xxx"\);')
              .hasMatch(source),
          isTrue,
          reason: 'risks getter must pass the pattern to SomList');
      // The pattern-less scalar `tags` list must NOT get a pattern argument.
      final tagsBody =
          RegExp(r'get tags\(\): SomList<SomScalar> \{\n.*return new SomList\(.*\);')
              .firstMatch(source)!
              .group(0)!;
      expect(tagsBody, isNot(contains('RISK-ITEM-xxx')));
      expect(tagsBody, endsWith('new SomScalar(d, p));'));
    });

    test('no flat path-constant holder is emitted; the meta module is '
        're-exported (SOM §8)', () {
      final source = SomTypeScriptEmitter(_fixtureModel()).generateLibrary();
      // SOM §8: the facade module carries no per-root `<Code>Paths` holder
      // …
      expect(source, isNot(contains('Pd00Paths')));
      expect(source, isNot(contains('vision: "PD00/vision"')));
      // … replaced by the generated metadata module (dot-notation + ID tree),
      // imported and re-exported so one import gives both surfaces, and the
      // root load statics pass the populated tree to the codec.
      expect(source,
          contains("import * as _meta from './tom_som_typescript_v0_meta';"));
      expect(source,
          contains("export * from './tom_som_typescript_v0_meta';"));
      expect(
          source,
          contains('SpecDocument.fromYaml(yaml, '
              '_meta.solutionBlueprintMetaTree)'));
      expect(
          source,
          contains('SpecDocument.fromFile(path, '
              '_meta.solutionBlueprintMetaTree)'));
    });
  });
}
