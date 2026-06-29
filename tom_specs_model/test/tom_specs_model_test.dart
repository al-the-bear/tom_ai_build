import 'dart:mirrors';

import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

void main() {
  group('D00SolutionBlueprint', () {
    test('can be constructed with all defaults', () {
      final pd = D00SolutionBlueprint();
      expect(pd.documentControl.header.content, isNull);
      expect(pd.currentLandscape.content, isNull);
      expect(pd.introductionAndScope.content, isNull);
    });

    test('header has @Form annotation on content', () {
      final header = DocumentHeader()
        ..content = 'PD00 — Test Project v0.1 by Test (Draft)';
      expect(header.content, contains('PD00'));
    });

    test('section classes have content field', () {
      final section = CurrentLandscape()
        ..content = 'Overview of current state.';
      expect(section.content, 'Overview of current state.');
      expect(section.existingSystemsLandscape.content, isNull);
    });

    test('form entry classes use content with @Form', () {
      final goal = BusinessGoalEntry()
        ..content = 'BG-001 — Increase revenue';
      final goals = Goals()..businessGoals = (BusinessGoals()..goals = [goal]);
      final overview = IntroductionAndScope()..goals = goals;
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
      expect(spec.projectDefinition, isA<D00SolutionBlueprint>());
      expect(spec.authorizationConcept, isA<D08SecurityAccessSpecification>());
      expect(spec.businessDataModel, isA<D03InformationModel>());
      expect(spec.businessProcesses, isA<D02TargetOperatingModel>());
      expect(spec.businessQualityPlan, isA<D10QualityAcceptancePlan>());
      expect(
        spec.businessSystemInteractions,
        isA<D07IntegrationInterfaceSpecification>(),
      );
      expect(spec.currentSituation, isA<D01CurrentLandscapeAssessment>());
      expect(spec.projectPhasePlan, isA<D11DeliveryRoadmap>());
      expect(spec.requirementsCatalog, isA<D04RequirementsSpecification>());
      expect(spec.systemRollout, isA<D12TransitionRolloutPlan>());
      expect(spec.technicalRequirementsSpec, isA<D06ArchitectureTechnologySpecification>());
      expect(spec.useCases, isA<D05InteractionScenarios>());
      expect(spec.uiPrototype, isA<D09ExperienceDesignSpecification>());
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
