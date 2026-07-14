import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model the Dart/Python/JavaScript/TypeScript
/// meta-emitter tests pin — every field kind **plus recursion**
/// (`Risk.mitigation: Risk`) and an id-less section (`details`) so the
/// ID-tree hoisting rule is exercised.
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
/// compares the generated tree against `BuildSomMetaTree` (field for field
/// via `SomMetaNodeDiff`) and asserts the dot-notation and ID-tree surfaces
/// agree — the Go port of the TypeScript meta-emitter check program. The meta
/// module is emitted as `package main` for this test so the check can call
/// the fixture's lowercase (unexported) ID getters, then run with `go run .`.
const String _checkProgram = r'''
package main

import (
	"fmt"
	"os"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func fail(msg string) {
	fmt.Fprintf(os.Stderr, "CHECK FAILED: %s\n", msg)
	os.Exit(1)
}

func expectEq(a, b interface{}, what string) {
	if a != b {
		fail(fmt.Sprintf("%s: %v != %v", what, a, b))
	}
}

func mustMeta(r interface {
	Meta() (*som.SomMetaNode, error)
}, what string) *som.SomMetaNode {
	n, err := r.Meta()
	if err != nil {
		fail(what + ": " + err.Error())
	}
	return n
}

func main() {
	raw, err := os.ReadFile("fixture.json")
	if err != nil {
		fail(err.Error())
	}
	model, err := som.SpecModelFromJSON(raw)
	if err != nil {
		fail(err.Error())
	}
	bridge, err := som.BuildSomMetaTree(model, "")
	if err != nil {
		fail(err.Error())
	}

	// (a) generated tree == bridge tree, field for field.
	if diff := som.SomMetaNodeDiff(SolutionBlueprintMetaTree.Root, bridge.Root); diff != "" {
		fail("generated tree != bridge tree: " + diff)
	}

	// (b) dot-notation paths.
	expectEq(SolutionBlueprintMeta.Path, "PD00", "root path")
	expectEq(SolutionBlueprintMeta.Vision().Path, "PD00/vision", "vision path")
	expectEq(SolutionBlueprintMeta.Owner().Path, "PD00/owner", "owner path")
	expectEq(SolutionBlueprintMeta.Risks().Path, "PD00/risks", "risks path")
	expectEq(SolutionBlueprintMeta.Risks().Item(2).Title().Path,
		"PD00/risks-2/title", "list item path")
	expectEq(SolutionBlueprintMeta.Situation().Summary().Path,
		"PD00/situation/summary", "collapsed complex path")
	expectEq(SolutionBlueprintMeta.Details().Summary().Path,
		"PD00/details/summary", "id-less section path")

	// (b) .Meta() resolves to the same nodes the dynamic lookups find.
	vision := mustMeta(SolutionBlueprintMeta.Vision(), "vision .Meta()")
	if vision != SolutionBlueprintMetaTree.ByPath("PD00/vision") {
		fail("vision .Meta() is not the ByPath node")
	}
	expectEq(vision.SectionID, "vision", "vision id")
	risks := mustMeta(SolutionBlueprintMeta.Risks(), "risks .Meta()")
	if risks.Min == nil || *risks.Min != 2 {
		fail("risks @Min must be 2")
	}
	expectEq(risks.SectionIDPattern, "RISK-ITEM-xxx", "risks pattern")
	owner := mustMeta(SolutionBlueprintMeta.Owner(), "owner .Meta()")
	if owner.Form == nil || len(owner.Form.Fields) != 2 {
		fail("owner form must carry 2 fields")
	}

	// (b) recursion: `.Path` chains stay valid past the re-entry, `.Meta()`
	// resolves at the re-entry itself and errors beyond it (DR1 §4.1).
	mitigation := SolutionBlueprintMeta.Risks().Item(0).Mitigation()
	expectEq(mitigation.Path, "PD00/risks-0/mitigation", "recursive path")
	if !mustMeta(mitigation, "mitigation .Meta()").Recursive {
		fail("mitigation node must be recursive")
	}
	beyond := mitigation.Mitigation()
	expectEq(beyond.Path, "PD00/risks-0/mitigation/mitigation",
		"path beyond re-entry")
	if _, err := beyond.Meta(); err == nil {
		fail(".Meta() beyond a recursive re-entry must error")
	}

	// (c) ID-tree agrees with dot-notation for every surfaced position.
	expectEq(PD00.Path, SolutionBlueprintMeta.Path, "root id path")
	expectEq(PD00.vision().Path, SolutionBlueprintMeta.Vision().Path,
		"vision id path")
	expectEq(PD00.owner().Path, SolutionBlueprintMeta.Owner().Path,
		"owner id path")
	expectEq(PD00.risks().Path, SolutionBlueprintMeta.Risks().Path,
		"risks id path")
	expectEq(PD00.risks().Item(2).title().Path,
		SolutionBlueprintMeta.Risks().Item(2).Title().Path, "item id path")
	expectEq(PD00.situation().summary().Path,
		SolutionBlueprintMeta.Situation().Summary().Path, "situation id path")
	// Hoisted through the id-less `details` section.
	expectEq(PD00.summary().Path, SolutionBlueprintMeta.Details().Summary().Path,
		"hoisted id path")
	if mustMeta(PD00.vision(), "id vision .Meta()") != vision {
		fail("id-tree and dot-notation .Meta() must be the same node")
	}

	fmt.Print("OK")
}
''';

/// Locates a `go` toolchain — on PATH, or the conventional `~/.local/go/bin/go`
/// install used on the fleet's Linux build hosts. Returns `null` when none.
String? _go() {
  try {
    final r = Process.runSync('go', ['version']);
    if (r.exitCode == 0) return 'go';
  } on ProcessException {
    // not on PATH
  }
  final home = Platform.environment['HOME'];
  if (home != null) {
    final cand = p.join(home, '.local', 'go', 'bin', 'go');
    if (File(cand).existsSync()) return cand;
  }
  return null;
}

/// The `tom_som_go_runtime` module dir, relative to the clitool root the test
/// runs from, or `null` when it cannot be located.
String? _runtimeDir() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_go_runtime'));
  return Directory(candidate).existsSync() ? candidate : null;
}

void main() {
  group('SomGoMetaEmitter', () {
    late String source;

    setUpAll(() {
      source = SomGoMetaEmitter(_fixtureModel()).generateLibrary();
    });

    test('emits per-root tree, dot-notation and ID-tree entry points', () {
      expect(source,
          contains('var SolutionBlueprintMetaTree = mustMetaTree('));
      expect(
          source,
          contains('var SolutionBlueprintMeta = newSolutionBlueprintNav('
              'SolutionBlueprintMetaTree, "PD00")'));
      expect(
          source,
          contains('var PD00 = newSolutionBlueprintID('
              'SolutionBlueprintMetaTree, "PD00")'));
    });

    test('emits one Nav struct per model class with member-named accessors',
        () {
      expect(source, contains('type SolutionBlueprintNav struct {'));
      expect(source, contains('type RiskNav struct {'));
      expect(source, contains('type CurrentLandscapeAssessmentNav struct {'));
      // A list accessor is a SomListMetaRef parameterised by an element
      // factory function.
      expect(
          source,
          contains('som.NewSomListMetaRef(x.Tree, x.Path+"/risks", '
              'func(t *som.SomMetaTree, p string) *RiskNav {'));
      // A scalar list's items are plain refs (no element accessor struct).
      expect(
          source,
          contains('som.NewSomListMetaRef(x.Tree, x.Path+"/tags", '
              'func(t *som.SomMetaTree, p string) *som.SomMetaRef {'));
    });

    test('ID-tree accessors are named by section id and hoist through '
        'id-less members', () {
      expect(source, contains('type SolutionBlueprintID struct {'));
      expect(source, contains('type RiskID struct {'));
      // Hoisted: CurrentLandscapeAssessment.summary surfaces on the root's
      // ID struct through the id-less `details` section.
      expect(source, contains('x.Path + "/details/summary"'));
    });

    test('cycle handling emits the metaCx re-entry helper and uses it for '
        'complex fields', () {
      expect(source, contains('func metaCx('));
      expect(source, contains('if stack[cls] {'));
      expect(source, contains('return build(true, nil)'));
      // Risk.mitigation (recursive) goes through metaCx like any complex
      // field.
      expect(source, contains('metaCx("Risk", s, metaChildrenRisk,'));
    });

    test('generated tree == bridge tree; dot-notation and ID-tree agree '
        '(functional, go run)', () async {
      final go = _go();
      if (go == null) {
        markTestSkipped('no go toolchain found');
        return;
      }
      final runtimeDir = _runtimeDir();
      if (runtimeDir == null) {
        markTestSkipped('tom_som_go_runtime not found');
        return;
      }
      // Emitted as `package main` so the check program (same package) can
      // call the fixture's lowercase (unexported) ID-tree getters.
      final mainSource =
          SomGoMetaEmitter(_fixtureModel(), packageName: 'main')
              .generateLibrary();
      final dir = await Directory.systemTemp.createTemp('som_go_meta_emit_');
      try {
        File(p.join(dir.path, 'generated_meta.go'))
            .writeAsStringSync(mainSource);
        File(p.join(dir.path, 'fixture.json'))
            .writeAsStringSync(jsonEncode(_fixtureJson()));
        File(p.join(dir.path, 'check.go')).writeAsStringSync(_checkProgram);
        final replaceTarget = runtimeDir.replaceAll('\\', '/');
        const runtimeModule =
            'github.com/al-the-bear/tom_ai_build/tom_som_go_runtime';
        File(p.join(dir.path, 'go.mod')).writeAsStringSync(
            'module github.com/al-the-bear/tom_ai_build/som_go_meta_check\n\n'
            'go 1.21\n\n'
            'require $runtimeModule v0.0.0\n\n'
            'replace $runtimeModule => $replaceTarget\n');

        final vet = await Process.run(go, ['vet', './...'],
            workingDirectory: dir.path);
        expect(vet.exitCode, 0,
            reason: 'go vet failed:\n${vet.stdout}\n${vet.stderr}');

        final run =
            await Process.run(go, ['run', '.'], workingDirectory: dir.path);
        expect(run.exitCode, 0,
            reason: 'check program failed:\n${run.stdout}\n${run.stderr}');
        expect(run.stdout.toString().trim(), 'OK');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('the emitted module is gofmt-stable by construction', () {
      final go = _go();
      if (go == null) {
        markTestSkipped('no go toolchain found');
        return;
      }
      // gofmt ships inside GOROOT/bin next to the located go binary.
      final goroot =
          Process.runSync(go, ['env', 'GOROOT']).stdout.toString().trim();
      final gofmtBin = p.join(goroot, 'bin', 'gofmt');
      if (!File(gofmtBin).existsSync()) {
        markTestSkipped('gofmt not found under GOROOT');
        return;
      }
      final dir = Directory.systemTemp.createTempSync('som_go_meta_fmt_');
      try {
        final file = File(p.join(dir.path, 'generated_meta.go'))
          ..writeAsStringSync(source);
        final gofmt = Process.runSync(gofmtBin, ['-l', file.path]);
        expect(gofmt.exitCode, 0,
            reason: 'gofmt failed:\n${gofmt.stdout}\n${gofmt.stderr}');
        expect(gofmt.stdout.toString().trim(), isEmpty,
            reason: 'gofmt would reformat the emitted module');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

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
      expect(
          () => SomGoMetaEmitter(bad).generateLibrary(), throwsStateError);
    });

    test('documentRoots subsets the emitted roots but accessor structs stay '
        'complete', () {
      final all = SomGoMetaEmitter(_fixtureModel()).generateLibrary();
      final subset = SomGoMetaEmitter(_fixtureModel(),
          documentRoots: ['SolutionBlueprint']).generateLibrary();
      expect(all, contains('SolutionBlueprintMetaTree'));
      expect(subset, contains('SolutionBlueprintMetaTree'));
    });
  });
}
