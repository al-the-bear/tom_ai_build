/// The projection connect pass (N11, N12) on the real model.
///
/// A spec is one document with fourteen entry points: the [D00SolutionBlueprint]
/// master plus thirteen projection roots that are *views* over the same SBP
/// sections. Each projection root default-constructs its own children, so
/// serializing one without first re-pointing those references at the live SBP
/// emits a document full of empty sections that look plausible — a silent
/// wrong answer rather than a failure. `SpecClassOps.connect` is what prevents
/// that, and these tests hold it to the root count so a binding dropped by the
/// codegen fails here instead of degrading the output.
library;

import 'package:test/test.dart';
import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  group('projection connect bindings (N11)', () {
    /// The thirteen projection roots: every entry point of the container
    /// except the [D00SolutionBlueprint] master it projects from.
    List<Object> projectionRootsOf(DocSpecsProject project) => [
          for (final slot in specSlotsOf(project))
            if (slot.node case final node?
                when !identical(node, project.solutionBlueprint))
              node,
        ];

    test('every projection root has a connect binding', () {
      final project = DocSpecsProject();
      final roots = projectionRootsOf(project);

      // The count is asserted, not just the per-root outcome: a codegen change
      // that stops recognizing a root would otherwise shrink both sides
      // together and still pass.
      expect(roots, hasLength(13),
          reason: 'the container carries the SBP master plus thirteen '
              'projection roots');

      final unbound = [
        for (final root in roots)
          if (!connectProjection(root, project.solutionBlueprint))
            root.runtimeType.toString(),
      ];
      expect(unbound, isEmpty,
          reason: 'these projection roots serialize unresolved '
              'default-constructed sections');
    });

    test('connect re-points a projection at the live Solution Blueprint', () {
      final project = DocSpecsProject();
      final sbp = project.solutionBlueprint;
      final projection = project.securityAccessSpecification;

      // Before the pass the projection holds its own default instance.
      expect(
          identical(projection.userManagement,
              sbp.securityAndAccessModel.accessControl.userManagement),
          isFalse);

      connectProjection(projection, sbp);

      expect(
          identical(projection.userManagement,
              sbp.securityAndAccessModel.accessControl.userManagement),
          isTrue,
          reason: 'the projection must reference the SBP section, not a copy');
    });

    test('toYamlForRoot emits content authored on the Solution Blueprint', () {
      final project = DocSpecsProject();
      project.solutionBlueprint.securityAndAccessModel.accessControl
          .userManagement.content = 'user-management: authored-in-sbp';

      final yaml = project.toYamlForRoot(project.securityAccessSpecification);

      expect(yaml, contains('user-management: authored-in-sbp'),
          reason: 'a per-root write runs the connect pass first, so it '
              'reflects current SBP content (N11)');
    });

    test('an edit made through a projection lands in the shared SBP section',
        () {
      final project = DocSpecsProject();
      final projection = project.securityAccessSpecification;
      connectProjection(projection, project.solutionBlueprint);

      projection.userManagement.content = 'edited-through-the-projection';

      expect(
          project.solutionBlueprint.securityAndAccessModel.accessControl
              .userManagement.content,
          'edited-through-the-projection',
          reason: 'projections do not own copies — one shared tree (N12)');
    });

    test('the D13 CodeSpecs projection is bound like the other twelve', () {
      // D13 is `@CodeSpecsProjection()`-marked, which exempts it from the
      // validator's detail-count check only. It is still a
      // `@Document(basedOn: [D00SolutionBlueprint])` view, and it is the
      // Phase-4 generation input — an unbound D13 would feed the CodeSpecs
      // generator empty sections.
      final project = DocSpecsProject();
      final sbp = project.solutionBlueprint;

      expect(connectProjection(project.codeSpecsProjection, sbp), isTrue);
      expect(
          identical(project.codeSpecsProjection.dataModel,
              sbp.informationAndDataModel.dataModel),
          isTrue);
    });

    test('a document header stays document-local', () {
      // Each of the fourteen entry points is a document in its own right, with
      // its own id, version and author. The header resolves structurally to the
      // SBP's `documentControl.header`, so only the explicit exclusion in the
      // codegen keeps the fourteen from sharing one front matter block.
      final project = DocSpecsProject();
      final sbp = project.solutionBlueprint;
      connectProjection(project.securityAccessSpecification, sbp);

      expect(
          identical(project.securityAccessSpecification.header,
              sbp.documentControl.header),
          isFalse);
    });
  });
}
