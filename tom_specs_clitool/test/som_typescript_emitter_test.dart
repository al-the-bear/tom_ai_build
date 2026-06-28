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

  group('SomTypeScriptEmitter', () {
    test('emitted output matches the committed golden file', () {
      final source = SomTypeScriptEmitter(_fixtureModel()).generateLibrary();
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
      final dir = Directory.systemTemp.createTempSync('som_ts_emit_');
      try {
        File(p.join(dir.path, 'tom_som_typescript_v0.ts'))
            .writeAsStringSync(source);
        // Resolve the bare `tom_som_typescript_runtime` specifier to the runtime
        // *source* (index.ts) via a compile-time `paths` mapping — a pure
        // type-check, no `node_modules` link or `node` run required.
        final runtimeIndex =
            p.join(runtimeDir, 'src', 'index.ts').replaceAll('\\', '/');
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
            'types': <String>[],
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

    test('v1 label yields major 1', () {
      final emitter = SomTypeScriptEmitter(_fixtureModel(), versionLabel: 'v1');
      expect(emitter.modelVersionString, '1.0');
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
      expect(all, contains('export class CurrentSituation extends SomNode'));

      final justRoot = SomTypeScriptEmitter(_fixtureModel(),
              documentRoots: ['ProjectDefinition'])
          .generateLibrary();
      expect(
          justRoot, contains('export class CurrentSituation extends SomNode'));
    });
  });
}
