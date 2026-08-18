/// The cross-check that `SpecYaml` and the nine SOM runtimes write **one** file
/// format (SOM §12), held over the real model rather than a stub.
///
/// `tom_specs_model`'s `SpecYaml` and `tom_som_dart_runtime`'s
/// `SpecDocumentYaml` used to be two independent encoders of the same format,
/// and they had drifted in six ways — preamble, `document:` wrapper, list
/// keying, sparseness, headlines and sibling order, scalar representability —
/// each of which alone made a `SpecYaml` file unloadable by any runtime.
/// `SpecYaml` is now a *projector* onto `SpecDocument` and hands the encoding
/// to `SpecDocumentYaml`, so there is only one encoder and the six cannot
/// recur. This test is what holds that claim: a document written by `SpecYaml`
/// must parse in the runtime and re-serialize **byte-identically**.
///
/// It runs over the whole `D00SolutionBlueprint` with every reachable content
/// leaf and every `@Form` section populated — a document of some 1200 sections,
/// not a stub — so a shape divergence anywhere in the model surfaces here
/// rather than at a user's round-trip. The metadata is the committed
/// `spec_model.meta.json`, which is the exact input the other eight runtimes
/// read, so the fixed point asserted is the *cross-language* one.
library;

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecDocumentYaml, SpecFieldKind, SpecModel;
import 'package:tom_specs_core/tom_specs_core.dart'
    show DocSpecsForm, DocSpecsSection;
import 'package:tom_specs_model/tom_specs_model.dart';

import 'support/real_model_tree.dart';

void main() {
  group('SpecYaml ⟷ SpecDocumentYaml on the real model (SOM §12)', () {
    late DocSpecsProject project;
    late _Filler filler;

    setUp(() {
      project = DocSpecsProject();
      filler = _Filler(realModel())..fill(project.solutionBlueprint);
    });

    test('a populated Solution Blueprint is a fixed point of the runtime codec',
        () {
      final written =
          SpecYaml.toYaml(project.solutionBlueprint, tree: treeFor(_sbp));

      // Non-triviality: this must be the real document, not an empty shell a
      // trivially-correct encoder would also round-trip.
      // 707 text sections and 233 forms: every section the default-constructed
      // tree reaches. The remaining model classes are list *element* types,
      // unreachable until a list has items — the third test covers those.
      //
      // Asserted exactly rather than as a floor, for the same reason
      // `registry_snapshot_test` asserts its class count exactly: a `>=` bound
      // is silent in the direction the model actually moves.
      expect(filler.contentLeaves, 707,
          reason: 'the fixture must exercise the whole reachable model');
      expect(filler.formSections, 233);
      expect(written.split('\n').length, greaterThan(3000));

      final reloaded = SpecDocumentYaml.decode(written, treeFor(_sbp));
      final rewritten = SpecDocumentYaml.encode(
          document: reloaded.document, tree: treeFor(_sbp));

      expect(rewritten, written,
          reason: 'a document SpecYaml wrote is not a fixed point of the '
              'runtime codec — the two derivations of SOM §12 have drifted');
    });

    test('every authored value survives the round trip, by path', () {
      final projected =
          SpecYaml.toDocument(project.solutionBlueprint, tree: treeFor(_sbp));
      final written =
          SpecYaml.toYaml(project.solutionBlueprint, tree: treeFor(_sbp));
      final reloaded = SpecDocumentYaml.decode(written, treeFor(_sbp)).document;

      // Path-for-path, not only byte-for-byte: a codec that dropped a whole
      // subtree symmetrically would still be a fixed point of itself.
      expect(reloaded.contentPaths.toSet(), projected.contentPaths.toSet(),
          reason: 'the reloaded document is keyed differently from the one '
              'SpecYaml projected');
      expect(reloaded.headlinePaths.toSet(), projected.headlinePaths.toSet());
      expect(reloaded.formPaths.toSet(), projected.formPaths.toSet());

      for (final path in projected.contentPaths) {
        expect(reloaded.content(path), projected.content(path),
            reason: 'content differs at $path');
      }
      for (final path in projected.formPaths) {
        expect(reloaded.formFieldNames(path).toSet(),
            projected.formFieldNames(path).toSet(),
            reason: 'form fields differ at $path');
        for (final field in projected.formFieldNames(path)) {
          expect(reloaded.formField(path, field),
              projected.formField(path, field),
              reason: 'form value differs at $path.$field');
        }
      }
    });

    test('list items keep their own section ids across the round trip', () {
      // Lists are the divergence with no fallback: `SpecYaml` used to emit YAML
      // sequences, which the runtimes reject outright. Three revisions with
      // explicit ids exercise both the indexed key and the id-keyed item.
      project.solutionBlueprint.documentControl.revisionHistory = [
        for (final v in ['1.0', '1.1', '2.0'])
          RevisionEntry()
            ..id = 'RVENT-REVS-${v.replaceAll('.', '')}'
            ..form = DocSpecsForm(values: {'version': v, 'author': 'test'}),
      ];

      final written =
          SpecYaml.toYaml(project.solutionBlueprint, tree: treeFor(_sbp));

      expect(written, isNot(contains('\n      - ')),
          reason: 'the v2 format keys list items, it never emits a sequence');
      for (final v in ['10', '11', '20']) {
        expect(written, contains('RVENT-REVS-$v:'));
      }

      final rewritten = SpecDocumentYaml.encode(
          document: SpecDocumentYaml.decode(written, treeFor(_sbp)).document,
          tree: treeFor(_sbp));
      expect(rewritten, written);
    });

    test('a projection root round-trips against its own metadata tree', () {
      // A per-root write runs the connect pass first, so it carries the live
      // SBP content but is keyed by the projection's own root (N11).
      const root = 'D08SecurityAccessSpecification';
      final written = project.toYamlForRoot(project.securityAccessSpecification,
          tree: treeFor(root));

      final rewritten = SpecDocumentYaml.encode(
          document: SpecDocumentYaml.decode(written, treeFor(root)).document,
          tree: treeFor(root));
      expect(rewritten, written);
    });
  });
}

const String _sbp = 'D00SolutionBlueprint';

/// Populates a live model tree with deterministic, path-derived values.
///
/// Drives the object tree through the same reflection-free contract `SpecYaml`
/// uses (`specSlotsOf`), and consults the exported [SpecModel] for the one
/// thing the objects do not carry: whether a class's `content` member is a
/// `@Form`.
///
/// **Every section gets free text, form or not.** A form's free text is its
/// preamble (SOM §11.4 rule 7) and rides in the same `content` key a plain
/// section's body uses (SOM §12.2), so the form-bearing sections — 233 of the
/// SBP's reachable sections — are filled through *both* [DocSpecsSection.content]
/// and [DocSpecsSection.form], and the round trip has to carry the pair.
class _Filler {
  _Filler(SpecModel model)
      : _formFields = {
          for (final cls in model.classes.values)
            for (final f in cls.fields)
              if (f.name == 'content' && f.kind == SpecFieldKind.form)
                cls.name: [for (final ff in f.formFields) ff.name],
        };

  /// Class name → the `@Form` field names of its `content` member.
  final Map<String, List<String>> _formFields;

  int contentLeaves = 0;
  int formSections = 0;

  void fill(Object node, [String path = '']) {
    if (node is DocSpecsSection) {
      final fields = _formFields[node.runtimeType.toString()];
      node.content = 'content at $path';
      if (fields == null) {
        contentLeaves++;
      } else if (fields.isNotEmpty) {
        node.form = DocSpecsForm(values: {fields.first: 'value at $path'});
        formSections++;
      }
    }
    for (final slot in specSlotsOf(node)) {
      final label = slot.label ?? '?';
      if (slot.isList) {
        final items = slot.list;
        for (var i = 0; i < items.length; i++) {
          fill(items[i], '$path/$label-${i + 1}');
        }
      } else {
        final child = slot.node;
        if (child != null) fill(child, '$path/$label');
      }
    }
  }
}
