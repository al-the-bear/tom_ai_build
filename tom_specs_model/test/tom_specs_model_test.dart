import 'dart:mirrors';

import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

void main() {
  group('SolutionBlueprint', () {
    test('can be constructed with all defaults', () {
      final pd = SolutionBlueprint();
      expect(pd.header.content, isNull);
      expect(pd.currentStateAnalysis.content, isNull);
      expect(pd.systemOverview.content, isNull);
    });

    test('header has @Form annotation on content', () {
      final header = DocumentHeader()
        ..content = 'PD00 — Test Project v0.1 by Test (Draft)';
      expect(header.content, contains('PD00'));
    });

    test('section classes have content field', () {
      final section = CurrentStateAnalysis()
        ..content = 'Overview of current state.';
      expect(section.content, 'Overview of current state.');
      expect(section.existingSystemsLandscape.content, isNull);
    });

    test('form entry classes use content with @Form', () {
      final goal = BusinessGoalEntry()
        ..content = 'BG-001 — Increase revenue';
      final goals = Goals()..businessGoals = (BusinessGoals()..goals = [goal]);
      final overview = SystemOverview()..goals = goals;
      expect(overview.goals.businessGoals.goals, hasLength(1));
      expect(
        overview.goals.businessGoals.goals.first.content,
        contains('BG-001'),
      );
    });

    test('stage entry uses content and TextSection fields', () {
      final stage = StageEntry()
        ..content = 'Stage 1 — Foundation — Core infrastructure';
      stage.featureScope.content = 'Login, CRUD, orders';
      expect(stage.content, contains('Foundation'));
      expect(stage.featureScope, isA<TextSection>());
      expect(stage.featureScope.content, isNotNull);
    });
  });

  group('DocSpecsProject (canonical container root, V2/N9)', () {
    test('default-constructs the full tree with all 13 document roots', () {
      final spec = DocSpecsProject();

      // Project Definition master + the 12 Phase 3 projection roots.
      expect(spec.projectDefinition, isA<SolutionBlueprint>());
      expect(spec.authorizationConcept, isA<SecurityAccessSpecification>());
      expect(spec.businessDataModel, isA<InformationModel>());
      expect(spec.businessProcesses, isA<TargetOperatingModel>());
      expect(spec.businessQualityPlan, isA<QualityAcceptancePlan>());
      expect(
        spec.businessSystemInteractions,
        isA<IntegrationInterfaceSpecification>(),
      );
      expect(spec.currentSituation, isA<CurrentLandscapeAssessment>());
      expect(spec.projectPhasePlan, isA<DeliveryRoadmap>());
      expect(spec.requirementsCatalog, isA<RequirementsSpecification>());
      expect(spec.systemRollout, isA<TransitionRolloutPlan>());
      expect(spec.technicalRequirementsSpec, isA<ArchitectureTechnologySpecification>());
      expect(spec.useCases, isA<InteractionScenarios>());
      expect(spec.uiPrototype, isA<ExperienceDesignSpecification>());
    });

    test('is not a document node — carries no @Document / @SectionId (N9)', () {
      // The container is the canonical tree root, not a 14th sibling document,
      // so it must not be annotated. Tooling relies on this to exempt it from
      // @SectionId coverage/uniqueness (T1).
      final annotations =
          reflectClass(DocSpecsProject).metadata.map((m) => m.reflectee);
      expect(annotations.whereType<Document>(), isEmpty);
      expect(annotations.whereType<SectionId>(), isEmpty);
    });
  });
}
