import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model meta-data the Dart/Python/Java/JavaScript/
/// TypeScript emitter tests pin, reused here so every emitter is exercised
/// against an identical model covering every field kind. `modelVersion` is `0`
/// so the generated `v0` model version is the clean `0.0`.
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

/// A spec-model whose field names Pascal-case onto the embedded `SomNode`'s
/// promoted `Doc()` / `Path()` methods — the Go-specific shadowing hazard the
/// emitter guards against by appending a trailing underscore.
Map<String, dynamic> _guardJson() => {
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
              'name': 'doc',
              'kind': 'content',
              'sectionId': 'doc',
              'contentType': 'text',
            },
            {
              'name': 'path',
              'kind': 'content',
              'sectionId': 'pth',
              'contentType': 'text',
            },
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'sum',
              'contentType': 'text',
            },
          ],
        },
      },
    };

/// A spec-model where two distinct field names Pascal-case to the same exported
/// accessor (`my_field` and `myField` → `MyField`) — exercising the per-struct
/// accessor de-duplication that camelCase-preserving emitters never trigger.
Map<String, dynamic> _accessorCollisionJson() => {
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
              'name': 'my_field',
              'kind': 'content',
              'sectionId': 'mf1',
              'contentType': 'text',
            },
            {
              'name': 'myField',
              'kind': 'content',
              'sectionId': 'mf2',
              'contentType': 'text',
            },
          ],
        },
      },
    };

/// A spec-model where two distinct (class, form-field) pairs derive the same
/// generated form-class name, identical to the other emitters' collision case.
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

/// A spec-model with two classes `OrganizationStructure` and
/// `NewOrganizationStructure` — the real collision the full PD model hits. In
/// Go the idiomatic constructor `func NewOrganizationStructure` shares the flat
/// package namespace with the *type* `NewOrganizationStructure`, so the emitter
/// must rename one. Sibling languages never trip this (constructors are methods
/// / `new`-expressions, not package-level functions).
Map<String, dynamic> _newPrefixCollisionJson() => {
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
              'name': 'current',
              'kind': 'complex',
              'sectionId': 'cur',
              'type': 'OrganizationStructure',
            },
            {
              'name': 'proposed',
              'kind': 'complex',
              'sectionId': 'pro',
              'type': 'NewOrganizationStructure',
            },
          ],
        },
        'OrganizationStructure': {
          'name': 'OrganizationStructure',
          'sectionId': 'OS00',
          'fields': [
            {
              'name': 'content',
              'kind': 'content',
              'sectionId': 'c',
              'contentType': 'text',
            },
          ],
        },
        'NewOrganizationStructure': {
          'name': 'NewOrganizationStructure',
          'sectionId': 'NOS0',
          'fields': [
            {
              'name': 'content',
              'kind': 'content',
              'sectionId': 'c',
              'contentType': 'text',
            },
          ],
        },
      },
    };

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

/// Compiles [source] plus its sibling metadata module [metaSource] as a
/// `tom_som_go_v0` module against the local runtime via a `replace` directive,
/// asserting `go build` + `go vet` both succeed. The facade's root load
/// functions reference the per-root `<Root>MetaTree` vars from the meta module
/// (SOM §8), so both files always compile together. A no-op (with a skip
/// note) when the toolchain or runtime cannot be located.
void _expectGoBuilds(String source, String metaSource) {
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
  final dir = Directory.systemTemp.createTempSync('som_go_emit_');
  try {
    File(p.join(dir.path, 'tom_som_go_v0.go')).writeAsStringSync(source);
    // The facade references the meta module's `<Root>MetaTree` vars (SOM §8).
    File(p.join(dir.path, 'tom_som_go_v0_meta.go'))
        .writeAsStringSync(metaSource);
    final replaceTarget = runtimeDir.replaceAll('\\', '/');
    const runtimeModule =
        'github.com/al-the-bear/tom_ai_build/tom_som_go_runtime';
    File(p.join(dir.path, 'go.mod')).writeAsStringSync(
        'module github.com/al-the-bear/tom_ai_build/tom_som_go_v0\n\n'
        'go 1.21\n\n'
        'require $runtimeModule v0.0.0\n\n'
        'replace $runtimeModule => $replaceTarget\n');
    final build =
        Process.runSync(go, ['build', './...'], workingDirectory: dir.path);
    expect(build.exitCode, 0,
        reason: 'go build failed:\n${build.stdout}\n${build.stderr}');
    final vet =
        Process.runSync(go, ['vet', './...'], workingDirectory: dir.path);
    expect(vet.exitCode, 0,
        reason: 'go vet failed:\n${vet.stdout}\n${vet.stderr}');
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_go_v0_fixture.go.golden');
  final metaGoldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_go_v0_meta_fixture.go.golden');

  group('SomGoEmitter', () {
    test('emitted output matches the committed golden files', () {
      final source = SomGoEmitter(_fixtureModel()).generateLibrary();
      // The facade references its sibling meta module (SOM §8), so the meta
      // golden is pinned alongside — the compile test builds both.
      final metaSource = SomGoMetaEmitter(_fixtureModel()).generateLibrary();
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
      expect(source, golden.readAsStringSync());
      expect(metaGolden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the meta golden file');
      expect(metaSource, metaGolden.readAsStringSync());
    });

    test('the generated module go-builds and go-vets clean against the runtime',
        () {
      _expectGoBuilds(SomGoEmitter(_fixtureModel()).generateLibrary(),
          SomGoMetaEmitter(_fixtureModel()).generateLibrary());
    });

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
      final dir = Directory.systemTemp.createTempSync('som_go_fmt_');
      try {
        final file = File(p.join(dir.path, 'generated.go'))
          ..writeAsStringSync(SomGoEmitter(_fixtureModel()).generateLibrary());
        final gofmt = Process.runSync(gofmtBin, ['-l', file.path]);
        expect(gofmt.exitCode, 0,
            reason: 'gofmt failed:\n${gofmt.stdout}\n${gofmt.stderr}');
        expect(gofmt.stdout.toString().trim(), isEmpty,
            reason: 'gofmt would reformat the emitted module');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('a New-prefixed type name does not collide with a constructor', () {
      final source = SomGoEmitter(SpecModel.fromJson(_newPrefixCollisionJson()))
          .generateLibrary();
      // The type `NewOrganizationStructure` exists, so `OrganizationStructure`'s
      // idiomatic constructor `NewOrganizationStructure` is renamed; both the
      // type and the (now-renamed) constructor must be declared exactly once.
      final funcs = RegExp(r'^func (New\w+)\(', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
      final types = RegExp(r'^type (\w+) struct \{', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
      final all = [...funcs, ...types];
      final seen = <String>{};
      final dupes = <String>[];
      for (final n in all) {
        if (!seen.add(n)) dupes.add(n);
      }
      expect(dupes, isEmpty,
          reason: 'colliding package-level identifiers: $dupes');
      // And it must actually compile (the original failure was a go build error).
      _expectGoBuilds(
          source,
          SomGoMetaEmitter(SpecModel.fromJson(_newPrefixCollisionJson()))
              .generateLibrary());
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the Go facade encodes (pure-Dart variant).
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
      final emitter = SomGoEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated source pins the same value as a package-level constant.
      expect(emitter.generateLibrary(),
          contains('const SolutionBlueprintModelVersion = "0.0"'));
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
      expect(
          SomGoEmitter(stamped, versionLabel: 'v0').modelVersionString, '1.3');
      expect(
          SomGoEmitter(stamped, versionLabel: 'v9').modelVersionString, '1.3');
    });

    test('Doc/Path-shadowing field names are guarded, '
        'but path segments are preserved', () {
      final source =
          SomGoEmitter(SpecModel.fromJson(_guardJson())).generateLibrary();
      // Field `doc` → accessor `Doc_()` (a `Doc()` would shadow the promoted
      // SomNode.Doc() and self-recurse); path segment `doc` is untouched.
      expect(source, contains('func (x *Root) Doc_() string'));
      expect(source, contains('func (x *Root) SetDoc_(value string)'));
      expect(source, contains('x.Path() + "/doc"'));
      expect(source, isNot(contains('func (x *Root) Doc() string')));
      // Field `path` → accessor `Path_()`; segment `pth` preserved.
      expect(source, contains('func (x *Root) Path_() string'));
      expect(source, contains('x.Path() + "/pth"'));
      expect(source, isNot(contains('func (x *Root) Path() string')));
    });

    test('accessors colliding under Pascal-casing are de-duplicated', () {
      final source = SomGoEmitter(SpecModel.fromJson(_accessorCollisionJson()))
          .generateLibrary();
      // `my_field` and `myField` both Pascal-case to `MyField`; the second
      // gets a numeric suffix so getter and setter never collide.
      expect(source, contains('func (x *Root) MyField() string'));
      expect(source, contains('func (x *Root) MyField2() string'));
      // Both stored segments are preserved verbatim.
      expect(source, contains('x.Path() + "/mf1"'));
      expect(source, contains('x.Path() + "/mf2"'));
    });

    test('enum tokens are preserved as exported constants', () {
      final source = SomGoEmitter(_fixtureModel()).generateLibrary();
      // Token stays byte-identical; only the constant identifier is derived.
      // Names are padded so the `=` column-aligns (gofmt const-group style).
      expect(source, contains('ProbabilityLow    = "low"'));
      expect(source, contains('ProbabilityMedium = "medium"'));
      expect(source, contains('ProbabilityHigh   = "high"'));
      expect(source, contains('func parseProbability(token string) string'));
    });

    test('a pattern-bearing list emits its @SectionIdPattern; a scalar list '
        'does not (AA1 criteria 3–5)', () {
      final source = SomGoEmitter(_fixtureModel()).generateLibrary();
      // The complex `risks` list carries a pattern → NewSomList is constructed
      // with the trailing pattern argument so the facade can generate ids.
      expect(
          RegExp(r'func \(x \*SolutionBlueprint\) Risks\(\)[\s\S]*?'
                  r'som\.NewSomList\([\s\S]*?\}, "RISK-ITEM-xxx"\)')
              .hasMatch(source),
          isTrue,
          reason: 'risks getter must pass the pattern to NewSomList');
      // The pattern-less scalar `tags` list must pass an empty pattern string.
      final tagsBody = RegExp(
              r'func \(x \*SolutionBlueprint\) Tags\(\)[\s\S]*?som\.NewSomList\('
              r'[\s\S]*?\}, ""\)')
          .firstMatch(source);
      expect(tagsBody, isNotNull,
          reason: 'scalar tags list must pass an empty pattern string');
      expect(tagsBody!.group(0)!, isNot(contains('RISK-ITEM-xxx')));
    });

    test('colliding form-struct names are disambiguated (no duplicates)', () {
      final source = SomGoEmitter(SpecModel.fromJson(_formCollisionJson()))
          .generateLibrary();
      final decls = RegExp(r'type (\w+) struct \{', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty, reason: 'duplicate type declarations: $dupes');
      expect(source,
          contains('type MigrationRisksGovernanceContentForm struct {'));
      expect(source,
          contains('type MigrationRisksGovernanceContentForm2 struct {'));
    });

    test('documentRoots subsets the generated structs', () {
      final all = SomGoEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('type CurrentLandscapeAssessment struct {'));

      final justRoot = SomGoEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(justRoot, contains('type CurrentLandscapeAssessment struct {'));
    });

    test('no flat path-constant holder is emitted; the meta trees are '
        'threaded (SOM §8)', () {
      final source = SomGoEmitter(_fixtureModel()).generateLibrary();
      // SOM §8: the facade module carries no per-root `<Code>Paths` holder
      // …
      expect(source, isNot(contains('Pd00Paths')));
      expect(source, isNot(contains('Vision: "PD00/vision"')));
      // … replaced by the generated metadata module (dot-notation + ID tree,
      // a sibling file in the same flat package — no import needed), and the
      // root load functions pass the populated tree to the codec.
      expect(source,
          contains('som.FromYaml(yaml, SolutionBlueprintMetaTree)'));
      expect(source,
          contains('som.FromFile(path, SolutionBlueprintMetaTree)'));
    });
  });
}
