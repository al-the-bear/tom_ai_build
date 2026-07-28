import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model the Dart/Python meta-emitter tests pin —
/// every field kind **plus recursion** (`Risk.mitigation: Risk`) and an
/// id-less section (`details`) so the ID-tree hoisting rule is exercised.
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

/// The functional agreement program run against the generated module: it
/// compares the generated tree against `buildSomMetaTree` (field for field
/// via `somMetaNodeDiff`) and asserts the dot-notation and ID-tree surfaces
/// agree — the JavaScript port of the Dart/Python meta-emitter check program.
const String _checkProgram = r'''
'use strict';

const fs = require('fs');
const path = require('path');

const meta = require('./generated_meta.js');
const {
  SpecModel,
  buildSomMetaTree,
  somMetaNodeDiff,
} = require(path.resolve(__dirname, JSON.parse(fs.readFileSync(
    path.join(__dirname, 'package.json'), 'utf8')).tomSom.runtimePath));

function fail(msg) {
  process.stderr.write(`CHECK FAILED: ${msg}\n`);
  process.exit(1);
}

function expectEq(a, b, what) {
  if (a !== b) {
    fail(`${what}: ${JSON.stringify(a)} !== ${JSON.stringify(b)}`);
  }
}

const fixture = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'fixture.json'), 'utf8'));
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
expectEq(solutionBlueprint.owner.meta.form.fields.length, 2, 'form fields');

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
  group('SomJavaScriptMetaEmitter', () {
    late String source;

    setUpAll(() {
      source = SomJavaScriptMetaEmitter(_fixtureModel()).generateLibrary();
    });

    test('emits per-root tree, dot-notation and ID-tree entry points', () {
      expect(source,
          contains('const solutionBlueprintMetaTree = new SomMetaTree('));
      expect(source,
          contains(r'const solutionBlueprint = new SolutionBlueprint$Nav('));
      expect(source, contains(r'const PD00 = new SolutionBlueprint$Id('));
    });

    test('emits one Nav class per model class with member-named getters', () {
      expect(source,
          contains(r'class SolutionBlueprint$Nav extends SomMetaRef {'));
      expect(source, contains(r'class Risk$Nav extends SomMetaRef {'));
      expect(
          source,
          contains(
              r'class CurrentLandscapeAssessment$Nav extends SomMetaRef {'));
      // A list getter is a SomListMetaRef parameterised by an element factory
      // function (JS classes are not callable without `new`).
      expect(
          source,
          contains('new SomListMetaRef(this.tree, this.path + "/risks", '
              r'(t, p) => new Risk$Nav(t, p))'));
      // A scalar list's items are plain refs (no element accessor class).
      expect(
          source,
          contains('new SomListMetaRef(this.tree, this.path + "/tags", '
              '(t, p) => new SomMetaRef(t, p))'));
    });

    test('ID-tree getters are named by section id and hoist through id-less '
        'members', () {
      expect(source,
          contains(r'class SolutionBlueprint$Id extends SomMetaRef {'));
      expect(source, contains(r'class Risk$Id extends SomMetaRef {'));
      // Hoisted: CurrentLandscapeAssessment.summary surfaces on the root's
      // Id class through the id-less `details` section.
      expect(source, contains('this.path + "/details/summary"'));
    });

    test('cycle handling emits the _cx re-entry helper and uses it for '
        'complex fields', () {
      expect(source, contains('function _cx(cls, stack, kids, make) {'));
      expect(source, contains('if (stack.has(cls)) {'));
      expect(source, contains('return make(true, []);'));
      // Risk.mitigation (recursive) goes through _cx like any complex field.
      expect(source, contains('_cx("Risk", s, _mc_Risk,'));
    });

    test('generated tree == bridge tree; dot-notation and ID-tree agree '
        '(functional, node)', () async {
      final node = _node();
      if (node == null) {
        markTestSkipped('no node on PATH');
        return;
      }
      // Physical path: package.json carries a relative tomSom.runtimePath, and
      // node resolves it from the physical module dir — a symlinked temp path
      // (macOS /var/folders → /private/var) would break the `..` walk.
      final dir = Directory(
          (await Directory.systemTemp.createTemp('som_js_meta_emit_'))
              .resolveSymbolicLinksSync());
      try {
        final runtimePath = p.normalize(p.join(
            Directory.current.path, '..', 'tom_som_javascript_runtime'));
        final runtimeRel =
            p.relative(runtimePath, from: dir.path).replaceAll(r'\', '/');
        File(p.join(dir.path, 'generated_meta.js')).writeAsStringSync(source);
        // The meta module resolves the runtime via tomSom.runtimePath in the
        // sibling package.json (same mechanism as the facade module).
        File(p.join(dir.path, 'package.json')).writeAsStringSync(jsonEncode({
          'name': 'generated_meta_check',
          'version': '0.0.0',
          'private': true,
          'tomSom': {'runtimePath': runtimeRel},
        }));
        File(p.join(dir.path, 'fixture.json'))
            .writeAsStringSync(jsonEncode(_fixtureJson()));
        File(p.join(dir.path, 'check.js')).writeAsStringSync(_checkProgram);

        final run = await Process.run(node, ['check.js'],
            workingDirectory: dir.path);
        expect(run.exitCode, 0,
            reason: 'check program failed:\n${run.stdout}\n${run.stderr}');
        expect(run.stdout.toString().trim(), 'OK');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

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
      expect(() => SomJavaScriptMetaEmitter(bad).generateLibrary(),
          throwsStateError);
    });

    test('documentRoots subsets the emitted roots but accessor classes stay '
        'complete', () {
      final all = SomJavaScriptMetaEmitter(_fixtureModel()).generateLibrary();
      final subset = SomJavaScriptMetaEmitter(_fixtureModel(),
          documentRoots: ['SolutionBlueprint']).generateLibrary();
      expect(all, contains('solutionBlueprintMetaTree'));
      expect(subset, contains('solutionBlueprintMetaTree'));
    });
  });
}
