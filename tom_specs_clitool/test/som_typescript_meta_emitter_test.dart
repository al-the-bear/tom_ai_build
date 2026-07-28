import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model the Dart/Python/JavaScript meta-emitter
/// tests pin — every field kind **plus recursion** (`Risk.mitigation: Risk`)
/// and an id-less section (`details`) so the ID-tree hoisting rule is
/// exercised.
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
            {
              // Id-less section: the ID-tree hoists through it (its target's
              // id-bearing fields surface at the root, path-prefixed).
              'name': 'details',
              'kind': 'section',
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
            {
              // Recursive: Risk inside Risk — becomes a terminal re-entry.
              'name': 'mitigation',
              'kind': 'complex',
              'sectionId': 'mitigation',
              'type': 'Risk',
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

/// [_fixtureJson] plus a **second** document root, so an assertion about the
/// generated root registry (SOM §8) proves it carries one entry *per root*
/// rather than a single hard-wired one.
Map<String, dynamic> _twoRootJson() {
  final json = _fixtureJson();
  (json['roots'] as List)
      .add({'type': 'Aux', 'title': 'Aux', 'sectionId': 'AX00'});
  (json['classes'] as Map<String, dynamic>)['Aux'] = {
    'name': 'Aux',
    'sectionId': 'AX00',
    'fields': [
      {
        'name': 'note',
        'kind': 'content',
        'sectionId': 'note',
        'contentType': 'text',
      },
    ],
  };
  return json;
}

/// The functional agreement program run against the generated module: it
/// compares the generated tree against `buildSomMetaTree` (field for field
/// via `somMetaNodeDiff`) and asserts the dot-notation and ID-tree surfaces
/// agree — the TypeScript port of the Dart/Python/JavaScript meta-emitter
/// check program. Compiled to `dist/` (so `fixture.json` lives one level up
/// from `__dirname`) and run under `node`.
const String _checkProgram = r'''
import * as fs from 'fs';
import * as path from 'path';

import * as meta from './generated_meta';
import {
  SpecModel,
  buildSomMetaTree,
  somMetaNodeDiff,
} from 'tom_som_typescript_runtime';

function fail(msg: string): never {
  process.stderr.write(`CHECK FAILED: ${msg}\n`);
  process.exit(1);
}

function expectEq(a: unknown, b: unknown, what: string): void {
  if (a !== b) {
    fail(`${what}: ${JSON.stringify(a)} !== ${JSON.stringify(b)}`);
  }
}

const fixture = JSON.parse(
    fs.readFileSync(path.join(__dirname, '..', 'fixture.json'), 'utf8'));
const bridge = buildSomMetaTree(SpecModel.fromJson(fixture));

const { PD00, solutionBlueprint, solutionBlueprintMetaTree } = meta;

// (a) generated tree == bridge tree, field for field.
const diff = somMetaNodeDiff(solutionBlueprintMetaTree.root, bridge.root);
if (diff !== null) {
  fail(`generated tree != bridge tree: ${diff}`);
}

// (b) dot-notation paths.
expectEq(solutionBlueprint.path, 'PD00', 'root path');
expectEq(solutionBlueprint.vision.path, 'PD00/vision', 'vision path');
expectEq(solutionBlueprint.owner.path, 'PD00/owner', 'owner path');
expectEq(solutionBlueprint.risks.path, 'PD00/risks', 'risks path');
expectEq(
    solutionBlueprint.risks.item(2).title.path,
    'PD00/risks-2/title',
    'list item path');
expectEq(
    solutionBlueprint.situation.summary.path,
    'PD00/situation/summary',
    'collapsed complex path');
expectEq(
    solutionBlueprint.details.summary.path,
    'PD00/details/summary',
    'id-less section path');

// (b) .meta resolves to the same nodes the dynamic lookups find.
if (solutionBlueprint.vision.meta !==
    solutionBlueprintMetaTree.byPath('PD00/vision')) {
  fail('vision .meta is not the byPath node');
}
expectEq(solutionBlueprint.vision.meta.sectionId, 'vision', 'vision id');
expectEq(solutionBlueprint.risks.meta.min, 2, 'risks @Min');
expectEq(
    solutionBlueprint.risks.meta.sectionIdPattern,
    'RISK-ITEM-xxx',
    'risks pattern');
expectEq(
    solutionBlueprint.owner.meta.form?.fields.length, 2, 'form fields');

// (b) recursion: `.path` chains stay valid past the re-entry, `.meta`
// resolves at the re-entry itself and throws beyond it (SOM §8 cycle rule).
const mitigation = solutionBlueprint.risks.item(0).mitigation;
expectEq(mitigation.path, 'PD00/risks-0/mitigation', 'recursive path');
if (!mitigation.meta.recursive) {
  fail('mitigation node must be recursive');
}
const beyond = mitigation.mitigation;
expectEq(
    beyond.path, 'PD00/risks-0/mitigation/mitigation', 'path beyond re-entry');
let threw = false;
try {
  void beyond.meta;
} catch (e) {
  threw = true;
}
if (!threw) {
  fail('.meta beyond a recursive re-entry must throw');
}

// (c) ID-tree agrees with dot-notation for every surfaced position.
expectEq(PD00.path, solutionBlueprint.path, 'root id path');
expectEq(PD00.vision.path, solutionBlueprint.vision.path, 'vision id path');
expectEq(PD00.owner.path, solutionBlueprint.owner.path, 'owner id path');
expectEq(PD00.risks.path, solutionBlueprint.risks.path, 'risks id path');
expectEq(
    PD00.risks.item(2).title.path,
    solutionBlueprint.risks.item(2).title.path,
    'item id path');
expectEq(
    PD00.situation.summary.path,
    solutionBlueprint.situation.summary.path,
    'situation id path');
// Hoisted through the id-less `details` section.
expectEq(
    PD00.summary.path, solutionBlueprint.details.summary.path,
    'hoisted id path');
if (PD00.vision.meta !== solutionBlueprint.vision.meta) {
  fail('id-tree and dot-notation .meta must be the same node');
}

process.stdout.write('OK');
''';

/// The `tom_som_typescript_runtime` package dir, relative to the clitool root
/// the test runs from, or `null` when it cannot be located.
String? _runtimeDir() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_typescript_runtime'));
  return Directory(candidate).existsSync() ? candidate : null;
}

/// The project-local `tsc` binary inside the runtime's `node_modules`, or
/// `null` when the runtime has not been `npm install`ed yet.
String? _tsc(String runtimeDir) {
  final bin = p.join(runtimeDir, 'node_modules', '.bin', 'tsc');
  return File(bin).existsSync() ? bin : null;
}

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

void main() {
  group('SomTypeScriptMetaEmitter', () {
    late String source;

    setUpAll(() {
      source = SomTypeScriptMetaEmitter(_fixtureModel()).generateLibrary();
    });

    test('emits per-root tree, dot-notation and ID-tree entry points', () {
      expect(
          source,
          contains('export const solutionBlueprintMetaTree: SomMetaTree = '
              'new SomMetaTree('));
      expect(
          source,
          contains(r'export const solutionBlueprint: SolutionBlueprint$Nav = '
              r'new SolutionBlueprint$Nav('));
      expect(
          source,
          contains(r'export const PD00: SolutionBlueprint$Id = '
              r'new SolutionBlueprint$Id('));
    });

    test('emits one Nav class per model class with member-named getters', () {
      expect(
          source,
          contains(
              r'export class SolutionBlueprint$Nav extends SomMetaRef {'));
      expect(source, contains(r'export class Risk$Nav extends SomMetaRef {'));
      expect(
          source,
          contains(r'export class CurrentLandscapeAssessment$Nav '
              'extends SomMetaRef {'));
      // A list getter is a SomListMetaRef parameterised by a fully-annotated
      // element factory function (strict tsc).
      expect(
          source,
          contains('new SomListMetaRef(this.tree, this.path + "/risks", '
              r'(t: SomMetaTree, p: string) => new Risk$Nav(t, p))'));
      // A scalar list's items are plain refs (no element accessor class).
      expect(
          source,
          contains('new SomListMetaRef(this.tree, this.path + "/tags", '
              '(t: SomMetaTree, p: string) => new SomMetaRef(t, p))'));
    });

    test('ID-tree getters are named by section id and hoist through id-less '
        'members', () {
      expect(source,
          contains(r'export class SolutionBlueprint$Id extends SomMetaRef {'));
      expect(source, contains(r'export class Risk$Id extends SomMetaRef {'));
      // Hoisted: CurrentLandscapeAssessment.summary surfaces on the root's
      // Id class through the id-less `details` section.
      expect(source, contains('this.path + "/details/summary"'));
    });

    test('cycle handling emits the _cx re-entry helper and uses it for '
        'complex fields', () {
      expect(source, contains('function _cx('));
      expect(source, contains('if (stack.has(cls)) {'));
      expect(source, contains('return make(true, []);'));
      // Risk.mitigation (recursive) goes through _cx like any complex field.
      expect(source, contains('_cx("Risk", s, _mc_Risk,'));
    });

    test('generated tree == bridge tree; dot-notation and ID-tree agree '
        '(functional, tsc + node)', () async {
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
      final node = _node();
      if (node == null) {
        markTestSkipped('no node on PATH');
        return;
      }
      // Node resolves the runtime's compiled entry (`dist/src/index.js`)
      // through the node_modules link below, so the runtime dist must exist.
      if (!File(p.join(runtimeDir, 'dist', 'src', 'index.js')).existsSync()) {
        final build = await Process.run('npm', ['run', 'build'],
            workingDirectory: runtimeDir);
        if (build.exitCode != 0) {
          markTestSkipped('runtime dist build failed:\n${build.stdout}\n'
              '${build.stderr}');
          return;
        }
      }
      final dir = await Directory.systemTemp.createTemp('som_ts_meta_emit_');
      try {
        File(p.join(dir.path, 'generated_meta.ts')).writeAsStringSync(source);
        File(p.join(dir.path, 'fixture.json'))
            .writeAsStringSync(jsonEncode(_fixtureJson()));
        File(p.join(dir.path, 'check.ts')).writeAsStringSync(_checkProgram);
        // Both modules import the runtime by bare specifier — wire resolution
        // for `tsc` (types) and `node` (compiled js) through a node_modules
        // link onto the real runtime package.
        final nm = Directory(p.join(dir.path, 'node_modules'))
          ..createSync(recursive: true);
        Link(p.join(nm.path, 'tom_som_typescript_runtime'))
            .createSync(runtimeDir);
        // `@types/node` resolves from the runtime's own node_modules (the
        // temp dir carries only the runtime link) — same as the facade
        // compile test.
        final runtimeTypes =
            p.join(runtimeDir, 'node_modules', '@types').replaceAll('\\', '/');
        final tsconfig = <String, Object?>{
          'compilerOptions': <String, Object?>{
            'target': 'ES2020',
            'lib': <String>['ES2020'],
            'module': 'commonjs',
            'moduleResolution': 'node',
            'ignoreDeprecations': '6.0',
            'rootDir': '.',
            'outDir': 'dist',
            'strict': true,
            'esModuleInterop': true,
            'skipLibCheck': true,
            'typeRoots': <String>[runtimeTypes],
            'types': <String>['node'],
          },
          'include': <String>['*.ts'],
        };
        File(p.join(dir.path, 'tsconfig.json'))
            .writeAsStringSync(jsonEncode(tsconfig));

        final compile = await Process.run(tsc, ['-p', 'tsconfig.json'],
            workingDirectory: dir.path);
        expect(compile.exitCode, 0,
            reason: 'tsc compile failed:\n${compile.stdout}\n'
                '${compile.stderr}');

        final run = await Process.run(node, [p.join('dist', 'check.js')],
            workingDirectory: dir.path);
        expect(run.exitCode, 0,
            reason: 'check program failed:\n${run.stdout}\n${run.stderr}');
        expect(run.stdout.toString().trim(), 'OK');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('a reserved member name in the model is rejected loudly', () {
      final bad = SpecModel.fromJson({
        'modelVersion': 0,
        'roots': [
          {'type': 'Root', 'title': 'Root', 'sectionId': 'R0'},
        ],
        'classes': {
          'Root': {
            'name': 'Root',
            'sectionId': 'R0',
            'fields': [
              {'name': 'path', 'kind': 'content', 'sectionId': 'p'},
            ],
          },
        },
      });
      expect(() => SomTypeScriptMetaEmitter(bad).generateLibrary(),
          throwsStateError);
    });

    test('documentRoots subsets the emitted roots but accessor classes stay '
        'complete', () {
      final all = SomTypeScriptMetaEmitter(_fixtureModel()).generateLibrary();
      final subset = SomTypeScriptMetaEmitter(_fixtureModel(),
          documentRoots: ['SolutionBlueprint']).generateLibrary();
      expect(all, contains('solutionBlueprintMetaTree'));
      expect(subset, contains('solutionBlueprintMetaTree'));
    });
    // The nine v0 meta-agreement suites read their root set from this
    // registry instead of hand-listing it, so an emitter that drops it
    // silently un-gates fourteen roots in nine languages at once.
    test('the document-root registry carries one entry per root (SOM §8)',
        () {
      final all = SomTypeScriptMetaEmitter(SpecModel.fromJson(_twoRootJson()))
          .generateLibrary();
      expect(all, contains('"SolutionBlueprint": {type: "SolutionBlueprint", segment: "PD00", '
              'tree: solutionBlueprintMetaTree, nav: solutionBlueprint, id: PD00}'));
      expect(all, contains('"Aux": {type: "Aux", segment: "AX00", tree: auxMetaTree, '
              'nav: aux, id: AX00}'));

      final subset = SomTypeScriptMetaEmitter(SpecModel.fromJson(_twoRootJson()),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(subset, isNot(contains('"Aux": {type: "Aux"')));
    });
  });
}
