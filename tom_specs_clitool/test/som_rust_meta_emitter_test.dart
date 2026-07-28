@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Tests for [SomRustMetaEmitter] (SOM §8) — the Rust counterpart of
/// `som_go_meta_emitter_test.dart`: textual shape assertions, a committed
/// golden, and a **functional** check that compiles the generated meta module
/// against the real `tom_som_rust_runtime` and runs a Rust program asserting
/// (a) the generated tree is field-for-field identical to the bridge-built
/// tree (`som_meta_node_diff`), (b) the dot-notation and ID-tree surfaces
/// resolve byte-identical paths and the same nodes, and (c) the cycle rule
/// (terminal re-entry) behaves like the bridge.
///
/// The fixture extends the shared emitter fixture with an id-less `details`
/// section (exercising SOM §8 hoisting) and a recursive `Risk.mitigation`
/// complex (exercising the cycle rule).
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
              // Id-less section — its target's ids hoist onto the root's
              // ID-tree accessor (SOM §8).
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
              // Recursive complex — the cycle rule yields a terminal
              // re-entry node here.
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

/// A model whose member name collides with a reserved accessor method name of
/// the generated Nav structs (`path`) — generation must fail loudly.
Map<String, dynamic> _reservedNameJson() => {
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
              'name': 'path',
              'kind': 'content',
              'sectionId': 'pth',
              'contentType': 'text',
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

/// The Rust program that functionally verifies the generated meta module: it
/// builds the bridge tree from the fixture model JSON, compares it against the
/// generated tree with `som_meta_node_diff`, and asserts the SOM §8 access
/// surfaces (paths, node identity, annotations, recursion, hoisting). Prints
/// `OK` on success — the Rust analogue of the Go test's `check.go`.
const String _checkMain = r'''
mod meta;

use std::rc::Rc;
use tom_som_rust_runtime as som;

fn main() {
    let json = std::fs::read_to_string("fixture.json").expect("read fixture.json");
    let model = som::SpecModel::from_json_str(&json).expect("parse model");
    let bridge = som::build_som_meta_tree(&model, "").expect("bridge tree");
    let generated = meta::solution_blueprint_meta_tree();

    // (a) generated static tree == runtime bridge tree, field for field.
    let d = som::som_meta_node_diff(&generated.root, &bridge.root);
    assert!(d.is_empty(), "generated tree != bridge tree: {}", d);

    // (b) dot-notation paths (SOM §8) — byte-identical to the other ports.
    let nav = meta::solution_blueprint_meta(&generated);
    assert_eq!(nav.path(), "PD00");
    assert_eq!(nav.vision().path, "PD00/vision");
    assert_eq!(nav.risks().item(2).title().path, "PD00/risks-2/title");
    assert_eq!(nav.tags().item(0).path, "PD00/tags-0");
    assert_eq!(nav.situation().summary().path, "PD00/situation/summary");
    assert_eq!(nav.details().summary().path, "PD00/details/summary");

    // .meta() resolves the same node instance as tree.by_path.
    let m = nav.situation().meta().expect("situation meta");
    let bp = generated.by_path("PD00/situation").expect("by_path situation");
    assert!(Rc::ptr_eq(&m, &bp), "meta() != by_path node");

    // Slotted annotations survive into the generated nodes.
    let risks = nav.risks().meta_ref.meta().expect("risks meta");
    assert_eq!(risks.min, Some(2));
    assert_eq!(risks.section_id_pattern, "RISK-ITEM-xxx");
    let owner = nav.owner().meta().expect("owner meta");
    let form = owner.form.as_ref().expect("owner form");
    assert_eq!(form.fields.len(), 2);

    // (c) cycle rule: `Risk.mitigation` re-enters `Risk` — a terminal
    // recursive node; paths beyond it stay valid while .meta() errors.
    let mit = nav.risks().item(0).mitigation();
    let mit_meta = mit.meta().expect("mitigation meta");
    assert!(mit_meta.recursive, "mitigation must be a recursive re-entry");
    let deeper = nav.risks().item(0).mitigation().mitigation();
    assert_eq!(deeper.path(), "PD00/risks-0/mitigation/mitigation");
    assert!(deeper.meta().is_err(), "meta past a re-entry must error");

    // ID-tree (SOM §8) agrees with the dot-notation surface, incl. hoisting
    // through the id-less `details` member.
    let id = meta::PD00(&generated);
    assert_eq!(id.path(), "PD00");
    assert_eq!(id.vision().path, "PD00/vision");
    assert_eq!(id.risks().item(2).title().path, "PD00/risks-2/title");
    assert_eq!(id.situation().summary().path, "PD00/situation/summary");
    assert_eq!(id.summary().path, "PD00/details/summary");
    let hoisted = id.summary().meta().expect("hoisted summary meta");
    let dot = nav.details().summary().meta().expect("dot summary meta");
    assert!(Rc::ptr_eq(&hoisted, &dot), "hoisted id != dot-notation node");

    println!("OK");
}
''';

void main() {
  final goldenPath = p.join(Directory.current.path, 'test', 'golden',
      'som_rust_v0_meta_fixture.rs.golden');

  group('SomRustMetaEmitter', () {
    test('emitted output matches the committed golden file', () {
      final source = SomRustMetaEmitter(_fixtureModel()).generateLibrary();
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

    test('emits per-root tree builders and both access-surface entry points',
        () {
      final source = SomRustMetaEmitter(_fixtureModel()).generateLibrary();
      // Per-call tree construction (SomMetaTree is Rc-based / not Sync, so no
      // statics) plus tree-borrowing entry points.
      expect(source,
          contains('pub fn solution_blueprint_meta_tree() -> '
              'som::SomMetaTree {'));
      expect(source,
          contains('pub fn solution_blueprint_meta(tree: &som::SomMetaTree) '
              '-> SolutionBlueprintNav<\'_> {'));
      expect(source,
          contains('pub fn PD00(tree: &som::SomMetaTree) -> '
              'SolutionBlueprintId<\'_> {'));
      // The verbatim-uppercase ID entry point needs the module-level allow.
      expect(source, contains('#![allow(non_snake_case)]'));
      expect(source, contains('#![allow(dead_code)]'));
    });

    test('emits Nav structs with typed member accessors (SOM §8)', () {
      final source = SomRustMetaEmitter(_fixtureModel()).generateLibrary();
      expect(source, contains('pub struct SolutionBlueprintNav<\'a> {'));
      expect(source, contains('pub struct RiskNav<\'a> {'));
      expect(source,
          contains('pub struct CurrentLandscapeAssessmentNav<\'a> {'));
      // Complex member → target Nav; complex-element list → SomListMetaRef
      // with the element Nav factory; scalar list → SomMetaRef elements.
      expect(source,
          contains('pub fn situation(&self) -> '
              'CurrentLandscapeAssessmentNav<\'a> {'));
      expect(source,
          contains('pub fn risks(&self) -> '
              'som::SomListMetaRef<\'a, RiskNav<\'a>> {'));
      expect(source, contains('RiskNav::new)'));
      expect(source,
          contains('pub fn tags(&self) -> '
              'som::SomListMetaRef<\'a, som::SomMetaRef<\'a>> {'));
      expect(source, contains('som::SomMetaRef::new)'));
      // Leaf member → SomMetaRef with the byte-identical path segment.
      expect(source, contains('pub fn vision(&self) -> som::SomMetaRef<\'a> {'));
      expect(source, contains('"vision"'));
    });

    test('emits Id structs with hoisted section-id accessors (SOM §8)', () {
      final source = SomRustMetaEmitter(_fixtureModel()).generateLibrary();
      expect(source, contains('pub struct SolutionBlueprintId<\'a> {'));
      expect(source, contains('pub struct RiskId<\'a> {'));
      // The id-less `details` member hoists its target's `summary` id one
      // step onto the root Id accessor, with the full relative path baked in.
      expect(source, contains('"details/summary"'));
      // Id-bearing complex members keep their own Id-typed step.
      expect(source,
          contains('pub fn situation(&self) -> '
              'CurrentLandscapeAssessmentId<\'a> {'));
    });

    test('builds metadata via the cycle helper with the bridge cycle rule',
        () {
      final source = SomRustMetaEmitter(_fixtureModel()).generateLibrary();
      expect(source, contains('fn meta_cx('));
      // The recursive `Risk.mitigation` complex is built through the helper,
      // keyed by the target class name on the descent stack.
      expect(source, contains('meta_cx("Risk", s, meta_children_risk,'));
      // Slotted annotations land in their dedicated node fields.
      expect(source, contains('min: Some(2)'));
      expect(source,
          contains('section_id_pattern: "RISK-ITEM-xxx".to_string()'));
      expect(source, contains('som::SomFormFieldMeta { name: '
          '"name".to_string()'));
      // A builder with no complex descent names its stack param `_s`
      // (warning-clean); one with descent uses `s`.
      expect(
          source,
          contains('fn meta_children_current_landscape_assessment(_s: &mut '
              'HashSet<String>)'));
      expect(source,
          contains('fn meta_children_solution_blueprint(s: &mut '
              'HashSet<String>)'));
    });

    test(
        'FUNCTIONAL: the generated module compiles and its trees/surfaces '
        'agree with the runtime bridge', () {
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
      final dir = Directory.systemTemp.createTempSync('som_rust_meta_fn_');
      try {
        Directory(p.join(dir.path, 'src')).createSync(recursive: true);
        File(p.join(dir.path, 'src', 'meta.rs')).writeAsStringSync(
            SomRustMetaEmitter(_fixtureModel()).generateLibrary());
        File(p.join(dir.path, 'src', 'main.rs')).writeAsStringSync(_checkMain);
        File(p.join(dir.path, 'fixture.json'))
            .writeAsStringSync(jsonEncode(_fixtureJson()));
        final depPath = runtimeDir.replaceAll('\\', '/');
        File(p.join(dir.path, 'Cargo.toml')).writeAsStringSync('[package]\n'
            'name = "som_rust_meta_check"\n'
            'version = "0.0.0"\n'
            'edition = "2021"\n'
            'publish = false\n'
            '\n'
            '[dependencies]\n'
            'tom_som_rust_runtime = { path = "$depPath" }\n');
        final run =
            Process.runSync(cargo, ['run', '--quiet'], workingDirectory: dir.path);
        expect(run.exitCode, 0,
            reason: 'functional check failed:\n${run.stdout}\n${run.stderr}');
        expect((run.stdout as String).trim(), 'OK');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('a member colliding with a reserved accessor name fails generation',
        () {
      final emitter = SomRustMetaEmitter(SpecModel.fromJson(_reservedNameJson()));
      expect(emitter.generateLibrary, throwsStateError);
    });

    test('documentRoots subsets the emitted root entry points', () {
      final json = _fixtureJson();
      (json['roots'] as List).add({
        'type': 'Aux',
        'title': 'Aux',
        'sectionId': 'AX00',
      });
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
      final model = SpecModel.fromJson(json);

      final all = SomRustMetaEmitter(model).generateLibrary();
      expect(all, contains('pub fn solution_blueprint_meta_tree()'));
      expect(all, contains('pub fn aux_meta_tree()'));

      final subset = SomRustMetaEmitter(model,
          documentRoots: ['SolutionBlueprint']).generateLibrary();
      expect(subset, contains('pub fn solution_blueprint_meta_tree()'));
      expect(subset, isNot(contains('pub fn aux_meta_tree()')));
      expect(subset, isNot(contains('pub fn AX00(')));
    });
    // The nine v0 meta-agreement suites read their root set from this
    // registry instead of hand-listing it, so an emitter that drops it
    // silently un-gates fourteen roots in nine languages at once.
    test('the document-root registry carries one entry per root (SOM §8)',
        () {
      final all = SomRustMetaEmitter(SpecModel.fromJson(_twoRootJson()))
          .generateLibrary();
      expect(all, contains('type_name: "SolutionBlueprint"'));
      expect(all, contains('type_name: "Aux"'));
      expect(all, contains('tree: solution_blueprint_meta_tree'));
      expect(all, contains('nav_ref: aux_nav_ref'));
      expect(all, contains('id_ref: aux_id_ref'));

      final subset = SomRustMetaEmitter(SpecModel.fromJson(_twoRootJson()),
              documentRoots: ['SolutionBlueprint'])
          .generateLibrary();
      expect(subset, isNot(contains('type_name: "Aux"')));
    });
  });
}
