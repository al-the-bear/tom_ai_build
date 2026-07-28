import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model meta-data the Dart/Python/Java/JavaScript/
/// TypeScript/Go emitter tests pin, reused here so every emitter is exercised
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

/// A spec-model whose field names snake-case onto Rust **keywords** (`type`,
/// `match`, `move`) — the Rust-specific hazard the emitter guards against by
/// appending a trailing underscore. The path segments stay untouched.
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
              'name': 'type',
              'kind': 'content',
              'sectionId': 'typ',
              'contentType': 'text',
            },
            {
              'name': 'match',
              'kind': 'content',
              'sectionId': 'mat',
              'contentType': 'text',
            },
            {
              'name': 'move',
              'kind': 'content',
              'sectionId': 'mov',
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

/// A spec-model where two distinct field names snake-case to the same accessor
/// (`my_field` and `myField` → `my_field`) — exercising the per-impl accessor
/// de-duplication.
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
/// generated form-struct name, identical to the other emitters' collision case.
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

/// Locates a `cargo` toolchain — on PATH, or the conventional `~/.cargo/bin/cargo`
/// rustup install used on the fleet's build hosts. Returns `null` when none.
String? _cargo() {
  try {
    final r = Process.runSync('cargo', ['--version']);
    if (r.exitCode == 0) return 'cargo';
  } on ProcessException {
    // not on PATH
  }
  final home = Platform.environment['HOME'];
  if (home != null) {
    final cand = p.join(home, '.cargo', 'bin', 'cargo');
    if (File(cand).existsSync()) return cand;
  }
  return null;
}

/// The `tom_som_rust_runtime` crate dir, relative to the clitool root the test
/// runs from, or `null` when it cannot be located.
String? _runtimeDir() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_rust_runtime'));
  return Directory(candidate).existsSync() ? candidate : null;
}

/// Compiles [source] as a `tom_som_rust_v0` crate against the local runtime via
/// a relative `path` dependency, asserting `cargo build` succeeds. The facade
/// crate root declares `pub mod meta;`, so the sibling [metaSource] module is
/// written alongside it. A no-op (with a skip note) when the toolchain or
/// runtime cannot be located.
void _expectRustBuilds(String source, String metaSource) {
  final cargo = _cargo();
  if (cargo == null) {
    markTestSkipped('no cargo toolchain found');
    return;
  }
  final runtimeDir = _runtimeDir();
  if (runtimeDir == null) {
    markTestSkipped('tom_som_rust_runtime not found');
    return;
  }
  final dir = Directory.systemTemp.createTempSync('som_rust_emit_');
  try {
    Directory(p.join(dir.path, 'src')).createSync(recursive: true);
    File(p.join(dir.path, 'src', 'lib.rs')).writeAsStringSync(source);
    File(p.join(dir.path, 'src', 'meta.rs')).writeAsStringSync(metaSource);
    final depPath = runtimeDir.replaceAll('\\', '/');
    File(p.join(dir.path, 'Cargo.toml')).writeAsStringSync('[package]\n'
        'name = "tom_som_rust_v0"\n'
        'version = "0.0.0"\n'
        'edition = "2021"\n'
        'publish = false\n'
        '\n'
        '[dependencies]\n'
        'tom_som_rust_runtime = { path = "$depPath" }\n');
    final build = Process.runSync(cargo, ['build'], workingDirectory: dir.path);
    expect(build.exitCode, 0,
        reason: 'cargo build failed:\n${build.stdout}\n${build.stderr}');
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_rust_v0_fixture.rs.golden');

  group('SomRustEmitter', () {
    test('emitted output matches the committed golden file', () {
      final source = SomRustEmitter(_fixtureModel()).generateLibrary();
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

    test('the generated crate cargo-builds clean against the runtime', () {
      final model = _fixtureModel();
      _expectRustBuilds(SomRustEmitter(model).generateLibrary(),
          SomRustMetaEmitter(model).generateLibrary());
    });

    test('struct and impl declarations are unique', () {
      final source = SomRustEmitter(_fixtureModel()).generateLibrary();
      final structs = RegExp(r'^pub struct (\w+) \{', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final n in structs) {
        if (!seen.add(n)) dupes.add(n);
      }
      expect(dupes, isEmpty, reason: 'duplicate struct declarations: $dupes');
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the Rust facade encodes (pure-Dart variant).
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
      final emitter = SomRustEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated source pins the same value as a module-level constant.
      expect(emitter.generateLibrary(),
          contains('pub const SOLUTION_BLUEPRINT_MODEL_VERSION: &str = "0.0";'));
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
          SomRustEmitter(stamped, versionLabel: 'v0').modelVersionString, '1.3');
      expect(
          SomRustEmitter(stamped, versionLabel: 'v9').modelVersionString, '1.3');
    });

    test('keyword field names gain a trailing underscore, '
        'but path segments are preserved', () {
      final source =
          SomRustEmitter(SpecModel.fromJson(_keywordJson())).generateLibrary();
      // Field `type` → accessor `type_()` (a bare `type` is a Rust keyword);
      // path segment `typ` is untouched.
      expect(source, contains('pub fn type_(&self) -> String'));
      expect(source, contains('pub fn set_type_(&self, value: &str)'));
      expect(source, contains('"typ"'));
      expect(source, contains('pub fn match_(&self) -> String'));
      expect(source, contains('"mat"'));
      expect(source, contains('pub fn move_(&self) -> String'));
      expect(source, contains('"mov"'));
      // A non-keyword field is untouched.
      expect(source, contains('pub fn summary(&self) -> String'));
    });

    test('accessors colliding under snake-casing are de-duplicated', () {
      final source = SomRustEmitter(SpecModel.fromJson(_accessorCollisionJson()))
          .generateLibrary();
      // `my_field` and `myField` both snake-case to `my_field`; the second gets
      // a numeric suffix so getter and setter never collide.
      expect(source, contains('pub fn my_field(&self) -> String'));
      expect(source, contains('pub fn my_field_2(&self) -> String'));
      // Both stored segments are preserved verbatim.
      expect(source, contains('"mf1"'));
      expect(source, contains('"mf2"'));
    });

    test('enum tokens are preserved as module-level constants', () {
      final source = SomRustEmitter(_fixtureModel()).generateLibrary();
      // Token stays byte-identical; only the constant identifier is derived.
      expect(source, contains('pub const PROBABILITY_LOW: &str = "low";'));
      expect(source, contains('pub const PROBABILITY_MEDIUM: &str = "medium";'));
      expect(source, contains('pub const PROBABILITY_HIGH: &str = "high";'));
      expect(source, contains('pub fn parse_probability(token: &str) -> String'));
    });

    test('colliding form-struct names are disambiguated (no duplicates)', () {
      final source = SomRustEmitter(SpecModel.fromJson(_formCollisionJson()))
          .generateLibrary();
      final decls = RegExp(r'pub struct (\w+) \{', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty, reason: 'duplicate struct declarations: $dupes');
      expect(source,
          contains('pub struct MigrationRisksGovernanceContentForm {'));
      expect(source,
          contains('pub struct MigrationRisksGovernanceContentForm2 {'));
    });

    test('a pattern-bearing list emits its @SectionIdPattern; a scalar list '
        'does not (AA1 criteria 3–5)', () {
      final source = SomRustEmitter(_fixtureModel()).generateLibrary();
      // The complex `risks` list carries a pattern → SomList::new is constructed
      // with the trailing pattern argument so the facade can generate ids.
      expect(
          RegExp(r'pub fn risks\(&self\) -> som::SomList<Risk>[\s\S]*?'
                  r'som::SomList::new\([\s\S]*?'
                  r'"RISK-ITEM-xxx"\.to_string\(\),')
              .hasMatch(source),
          isTrue,
          reason: 'risks getter must pass the pattern to SomList::new');
      // The pattern-less scalar `tags` list must pass an empty pattern string.
      final tagsBody = RegExp(
              r'pub fn tags\(&self\) -> som::SomList<som::SomScalar>[\s\S]*?'
              r'som::SomList::new\([\s\S]*?""\.to_string\(\),')
          .firstMatch(source);
      expect(tagsBody, isNotNull,
          reason: 'scalar tags list must pass an empty pattern string');
      expect(tagsBody!.group(0)!, isNot(contains('RISK-ITEM-xxx')));
    });

    test('documentRoots subsets the generated structs', () {
      final all = SomRustEmitter(_fixtureModel()).generateLibrary();
      expect(all, contains('pub struct CurrentLandscapeAssessment {'));

      final justRoot = SomRustEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(justRoot, contains('pub struct CurrentLandscapeAssessment {'));
    });

    test('the flat path-constant holders are retired (SOM §8)', () {
      final source = SomRustEmitter(_fixtureModel()).generateLibrary();
      // The `Pd00Paths` holder is replaced by the meta module's navigation
      // surfaces (dot-notation + ID-tree) in `src/meta.rs`.
      expect(source, isNot(contains('Pd00Paths')));
      expect(source, contains('pub mod meta;'));
    });

    test('the one-call loaders thread the generated metadata tree through the '
        'tree-based codec', () {
      final source = SomRustEmitter(_fixtureModel()).generateLibrary();
      expect(source,
          contains('let tree = meta::solution_blueprint_meta_tree();'));
      expect(source,
          contains('som::SpecDocument::from_yaml(yaml, &tree)'
              '.map_err(SomLoadError::Yaml)?;'));
      expect(source,
          contains('som::SpecDocument::from_file(path, &tree)'
              '.map_err(SomLoadError::Yaml)?;'));
      // The loaders surface both failure modes through one generated sum type.
      expect(source, contains('pub enum SomLoadError {'));
      expect(source, contains('Yaml(som::SpecYamlError),'));
      expect(source, contains('Version(som::SomVersionError),'));
      expect(source,
          contains('pub fn load_yaml(yaml: &str) '
              '-> Result<SolutionBlueprint, SomLoadError> {'));
      expect(source, contains('impl std::error::Error for SomLoadError {}'));
    });
  });
}
