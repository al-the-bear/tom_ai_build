import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model the Dart meta-emitter test pins — every
/// field kind **plus recursion** (`Risk.mitigation: Risk`) and an id-less
/// section (`details`) so the ID-tree hoisting rule is exercised.
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
/// compares the generated tree against `build_som_meta_tree` (field for field
/// via `som_meta_node_diff`) and asserts the dot-notation and ID-tree
/// surfaces agree — the Python port of the Dart meta-emitter check program.
const String _checkProgram = r'''
import json
import sys

from generated_meta import (
    PD00,
    solutionBlueprint,
    solutionBlueprintMetaTree,
)
from tom_som_runtime import (
    SpecModel,
    build_som_meta_tree,
    som_meta_node_diff,
)


def fail(msg):
    print(f"CHECK FAILED: {msg}", file=sys.stderr)
    sys.exit(1)


def expect_eq(a, b, what):
    if a != b:
        fail(f"{what}: {a!r} != {b!r}")


with open("fixture.json", encoding="utf-8") as f:
    fixture = json.load(f)
bridge = build_som_meta_tree(SpecModel.from_json(fixture))

# (a) generated tree == bridge tree, field for field.
diff = som_meta_node_diff(solutionBlueprintMetaTree.root, bridge.root)
if diff is not None:
    fail(f"generated tree != bridge tree: {diff}")

# (b) dot-notation paths.
expect_eq(solutionBlueprint.path, "PD00", "root path")
expect_eq(solutionBlueprint.vision.path, "PD00/vision", "vision path")
expect_eq(solutionBlueprint.owner.path, "PD00/owner", "owner path")
expect_eq(solutionBlueprint.risks.path, "PD00/risks", "risks path")
expect_eq(
    solutionBlueprint.risks.item(2).title.path,
    "PD00/risks-2/title",
    "list item path",
)
expect_eq(
    solutionBlueprint.situation.summary.path,
    "PD00/situation/summary",
    "collapsed complex path",
)
expect_eq(
    solutionBlueprint.details.summary.path,
    "PD00/details/summary",
    "id-less section path",
)

# (b) .meta resolves to the same nodes the dynamic lookups find.
if solutionBlueprint.vision.meta is not solutionBlueprintMetaTree.by_path(
    "PD00/vision"
):
    fail("vision .meta is not the by_path node")
expect_eq(solutionBlueprint.vision.meta.section_id, "vision", "vision id")
expect_eq(solutionBlueprint.risks.meta.min, 2, "risks @Min")
expect_eq(
    solutionBlueprint.risks.meta.section_id_pattern,
    "RISK-ITEM-xxx",
    "risks pattern",
)
expect_eq(len(solutionBlueprint.owner.meta.form.fields), 2, "form fields")

# (b) recursion: `.path` chains stay valid past the re-entry, `.meta`
# resolves at the re-entry itself and raises beyond it (DR1 §4.1 cycle rule).
mitigation = solutionBlueprint.risks.item(0).mitigation
expect_eq(mitigation.path, "PD00/risks-0/mitigation", "recursive path")
if not mitigation.meta.recursive:
    fail("mitigation node must be recursive")
beyond = mitigation.mitigation
expect_eq(
    beyond.path, "PD00/risks-0/mitigation/mitigation", "path beyond re-entry"
)
threw = False
try:
    beyond.meta
except RuntimeError:
    threw = True
if not threw:
    fail(".meta beyond a recursive re-entry must raise RuntimeError")

# (c) ID-tree agrees with dot-notation for every surfaced position.
expect_eq(PD00.path, solutionBlueprint.path, "root id path")
expect_eq(PD00.vision.path, solutionBlueprint.vision.path, "vision id path")
expect_eq(PD00.owner.path, solutionBlueprint.owner.path, "owner id path")
expect_eq(PD00.risks.path, solutionBlueprint.risks.path, "risks id path")
expect_eq(
    PD00.risks.item(2).title.path,
    solutionBlueprint.risks.item(2).title.path,
    "item id path",
)
expect_eq(
    PD00.situation.summary.path,
    solutionBlueprint.situation.summary.path,
    "situation id path",
)
# Hoisted through the id-less `details` section.
expect_eq(
    PD00.summary.path, solutionBlueprint.details.summary.path, "hoisted id path"
)
if PD00.vision.meta is not solutionBlueprint.vision.meta:
    fail("id-tree and dot-notation .meta must be the same node")

print("OK")
''';

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
  group('SomPythonMetaEmitter', () {
    late String source;

    setUpAll(() {
      source = SomPythonMetaEmitter(_fixtureModel()).generateLibrary();
    });

    test('emits per-root tree, dot-notation and ID-tree entry points', () {
      expect(source, contains('solutionBlueprintMetaTree = SomMetaTree('));
      expect(source,
          contains('solutionBlueprint = SolutionBlueprintNav('));
      expect(source, contains('PD00 = SolutionBlueprintId('));
    });

    test('emits one Nav class per model class with member-named getters', () {
      expect(source, contains('class SolutionBlueprintNav(SomMetaRef):'));
      expect(source, contains('class RiskNav(SomMetaRef):'));
      expect(source,
          contains('class CurrentLandscapeAssessmentNav(SomMetaRef):'));
      // A list getter is a SomListMetaRef parameterised by the element class.
      expect(source,
          contains('SomListMetaRef(self.tree, f"{self.path}/risks", RiskNav)'));
      // A scalar list's items are plain refs (no element accessor class).
      expect(
          source,
          contains(
              'SomListMetaRef(self.tree, f"{self.path}/tags", SomMetaRef)'));
    });

    test('ID-tree getters are named by section id and hoist through id-less '
        'members', () {
      expect(source, contains('class SolutionBlueprintId(SomMetaRef):'));
      expect(source, contains('class RiskId(SomMetaRef):'));
      // Hoisted: CurrentLandscapeAssessment.summary surfaces on the root's
      // Id class through the id-less `details` section.
      expect(source, contains('{self.path}/details/summary'));
    });

    test('cycle handling emits the _cx re-entry helper and uses it for '
        'complex fields', () {
      expect(source, contains('def _cx(cls, stack, kids, make):'));
      expect(source, contains('if cls in stack:'));
      expect(source, contains('return make(True, [])'));
      // Risk.mitigation (recursive) goes through _cx like any complex field.
      expect(source, contains('_cx("Risk", s, _mc_Risk,'));
    });

    test('generated tree == bridge tree; dot-notation and ID-tree agree '
        '(functional, python3)', () async {
      final python = _python();
      if (python == null) {
        markTestSkipped('no python3 interpreter on PATH');
        return;
      }
      final dir = await Directory.systemTemp.createTemp('som_py_meta_emit_');
      try {
        final runtimePath = p.normalize(p.join(
            Directory.current.path, '..', 'tom_som_python_runtime'));
        File(p.join(dir.path, 'generated_meta.py')).writeAsStringSync(source);
        File(p.join(dir.path, 'fixture.json'))
            .writeAsStringSync(jsonEncode(_fixtureJson()));
        File(p.join(dir.path, 'check.py')).writeAsStringSync(_checkProgram);

        final run = await Process.run(python, ['check.py'],
            workingDirectory: dir.path,
            environment: {'PYTHONPATH': runtimePath});
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
      expect(() => SomPythonMetaEmitter(bad).generateLibrary(),
          throwsStateError);
    });

    test('documentRoots subsets the emitted roots but accessor classes stay '
        'complete', () {
      final all = SomPythonMetaEmitter(_fixtureModel()).generateLibrary();
      final subset = SomPythonMetaEmitter(_fixtureModel(),
          documentRoots: ['SolutionBlueprint']).generateLibrary();
      expect(all, contains('solutionBlueprintMetaTree'));
      expect(subset, contains('solutionBlueprintMetaTree'));
    });
  });
}
