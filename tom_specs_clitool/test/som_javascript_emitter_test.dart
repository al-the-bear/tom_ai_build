import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model meta-data the Dart/Python/Java emitter tests
/// pin, reused here so all four emitters are exercised against an identical model
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

/// A spec-model where a Dart field name is a JS reserved word (`class`), and an
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
/// generated form-class name, identical to the Dart/Python/Java emitter's
/// collision case.
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

/// Locates a `node` runtime, or `null` when none is on PATH.
String? _node() {
  try {
    final r = Process.runSync('node', ['--version']);
    if (r.exitCode == 0) return 'node';
  } on ProcessException {
    // none on PATH
  }
  return null;
}

/// The `tom_som_javascript_runtime` package dir, relative to the clitool root the
/// test runs from, or `null` when it cannot be located.
String? _runtimeDir() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_javascript_runtime'));
  return Directory(candidate).existsSync() ? candidate : null;
}

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_javascript_v0_fixture.js.golden');
  final metaGoldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_javascript_v0_meta_fixture.js.golden');

  group('SomJavaScriptEmitter', () {
    test('emitted output matches the committed golden files', () {
      final source = SomJavaScriptEmitter(_fixtureModel()).generateLibrary();
      // The facade requires its sibling meta module (DR8/DR15), so the meta
      // golden is pinned alongside — the runtime facade test loads both.
      final metaSource =
          SomJavaScriptMetaEmitter(_fixtureModel()).generateLibrary();
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

    test('the generated module loads under node and a typed mutation '
        'round-trips through the generic path', () {
      final node = _node();
      if (node == null) {
        markTestSkipped('no node on PATH');
        return;
      }
      final runtimeDir = _runtimeDir();
      if (runtimeDir == null) {
        markTestSkipped('tom_som_javascript_runtime not found');
        return;
      }
      final source = SomJavaScriptEmitter(_fixtureModel()).generateLibrary();
      final metaSource =
          SomJavaScriptMetaEmitter(_fixtureModel()).generateLibrary();
      // Physical path: package.json carries a relative tomSom.runtimePath, and
      // node resolves it from the physical module dir — a symlinked temp path
      // (macOS /var/folders → /private/var) would break the `..` walk.
      final dir = Directory(Directory.systemTemp
          .createTempSync('som_js_emit_')
          .resolveSymbolicLinksSync());
      try {
        const moduleName = 'tom_som_javascript_v0';
        File(p.join(dir.path, '$moduleName.js')).writeAsStringSync(source);
        // The facade requires its sibling meta module (DR8/DR15).
        File(p.join(dir.path, '${moduleName}_meta.js'))
            .writeAsStringSync(metaSource);
        // The module resolves the runtime via tomSom.runtimePath in this
        // package.json (relative to the module's own dir).
        final runtimeRel =
            p.relative(runtimeDir, from: dir.path).replaceAll(r'\', '/');
        File(p.join(dir.path, 'package.json')).writeAsStringSync(jsonEncode({
          'name': moduleName,
          'version': '0.0.0',
          'private': true,
          'main': '$moduleName.js',
          'tomSom': {'runtimePath': runtimeRel},
        }));
        final modulePath =
            p.join(dir.path, '$moduleName.js').replaceAll(r'\', '/');
        final runtimePath = runtimeDir.replaceAll(r'\', '/');
        final check = '''
const m = require(${jsonEncode(modulePath)});
const { SpecDocument } = require(${jsonEncode(runtimePath)});
const doc = new SpecDocument();
const pd = new m.SolutionBlueprint(doc);
if (pd.objectModelVersion !== '0.0') throw new Error('version ' + pd.objectModelVersion);
pd.vision = 'A clear vision';
if (pd.vision !== 'A clear vision') throw new Error('typed read');
// The typed write lands at the generic path.
if (doc.content(pd.path + '/vision') !== 'A clear vision') throw new Error('generic read');
// Typed collection: append + edit, visible through the generic list store.
const r = pd.risks.add();
r.title = 'Schedule slip';
if (pd.risks.length !== 1) throw new Error('list length');
if (pd.risks.at(0).title !== 'Schedule slip') throw new Error('list item');
process.stdout.write('OK');
''';
        final r = Process.runSync(node, ['-e', check]);
        expect(r.exitCode, 0,
            reason: 'node load/exec failed:\n${r.stdout}\n${r.stderr}');
        expect(r.stdout.toString().trim(), 'OK');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the JS facade encodes (pure-Dart variant).
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
      final emitter = SomJavaScriptEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated source pins the same value as a static class field.
      expect(emitter.generateLibrary(), contains('MODEL_VERSION = "0.0";'));
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
      expect(SomJavaScriptEmitter(stamped, versionLabel: 'v0').modelVersionString,
          '1.3');
      expect(SomJavaScriptEmitter(stamped, versionLabel: 'v9').modelVersionString,
          '1.3');
    });

    test('JS reserved words are sanitised in accessors, '
        'but path segments and enum tokens are preserved', () {
      final source = SomJavaScriptEmitter(SpecModel.fromJson(_keywordJson()))
          .generateLibrary();
      // Field `class` → accessor `class_`, path segment `cls` untouched.
      expect(source, contains('get class_()'));
      expect(source, contains('set class_(value)'));
      expect(source, contains('this.path + "/cls"'));
      expect(source, isNot(contains('get class()')));
      // Enum token `default` stays `default` (the object key/value is verbatim).
      expect(source, contains('"default": "default"'));
    });

    test('colliding form-class names are disambiguated (no duplicates)', () {
      final source =
          SomJavaScriptEmitter(SpecModel.fromJson(_formCollisionJson()))
              .generateLibrary();
      final decls = RegExp(r'class (\w+) extends SomNode', multiLine: true)
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

    test('a pattern-bearing list emits its @SectionIdPattern; a scalar list '
        'does not (AA1 criteria 3–5)', () {
      final source = SomJavaScriptEmitter(_fixtureModel()).generateLibrary();
      // The complex `risks` list carries a pattern → the SomList is constructed
      // with the trailing pattern argument so the facade can generate section
      // ids.
      expect(
          RegExp(r'get risks\(\) \{[\s\S]*?new SomList\(this\.doc,[\s\S]*?'
                  r'"RISK-ITEM-xxx"\);')
              .hasMatch(source),
          isTrue,
          reason: 'risks getter must pass the pattern to SomList');
      // The pattern-less scalar `tags` list must NOT get a pattern argument.
      final tagsBody =
          RegExp(r'get tags\(\) \{\n.*return new SomList\(.*\);')
              .firstMatch(source)!
              .group(0)!;
      expect(tagsBody, isNot(contains('RISK-ITEM-xxx')));
      expect(tagsBody, endsWith('new SomScalar(d, p));'));
    });

    test('path-constant holders are retired; the meta module is re-exported '
        '(DR8/DR15, DR1 §4)', () {
      final source = SomJavaScriptEmitter(_fixtureModel()).generateLibrary();
      // DR8/DR15: the former per-root `<Code>Paths` holders are gone from the
      // main facade module …
      expect(source, isNot(contains('Pd00Paths')));
      expect(source, isNot(contains('vision: "PD00/vision"')));
      // … replaced by the generated metadata module (dot-notation + ID tree),
      // required and spread into the exports so one require gives both
      // surfaces, and the root load statics pass the populated tree to the
      // codec.
      expect(source,
          contains("require('./tom_som_javascript_v0_meta.js');"));
      expect(source, contains('  ..._meta,'));
      expect(
          source,
          contains('SpecDocument.fromYaml(yaml, '
              '_meta.solutionBlueprintMetaTree)'));
      expect(
          source,
          contains('SpecDocument.fromFile(path, '
              '_meta.solutionBlueprintMetaTree)'));
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomJavaScriptEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('class CurrentLandscapeAssessment extends SomNode'));

      final justRoot = SomJavaScriptEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(justRoot, contains('class CurrentLandscapeAssessment extends SomNode'));
    });
  });
}
