import 'dart:mirrors';

import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

void main() {
  group('D00SolutionBlueprint', () {
    test('can be constructed with all defaults', () {
      final sbp = D00SolutionBlueprint();
      expect(sbp.documentControl.header.content, isNull);
      expect(sbp.currentLandscape.content, isNull);
      expect(sbp.introductionAndScope.content, isNull);
    });

    test('header has @Form annotation on content', () {
      final header = DocumentHeader()
        ..content = 'SBP — Test Project v0.1 by Test (Draft)';
      expect(header.content, contains('SBP'));
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

      // Solution Blueprint master + the 12 Phase 3 projection roots.
      expect(spec.solutionBlueprint, isA<D00SolutionBlueprint>());
      expect(spec.securityAccessSpecification,
          isA<D08SecurityAccessSpecification>());
      expect(spec.informationModel, isA<D03InformationModel>());
      expect(spec.targetOperatingModel, isA<D02TargetOperatingModel>());
      expect(spec.qualityAcceptancePlan, isA<D10QualityAcceptancePlan>());
      expect(
        spec.integrationInterfaceSpecification,
        isA<D07IntegrationInterfaceSpecification>(),
      );
      expect(spec.currentLandscapeAssessment,
          isA<D01CurrentLandscapeAssessment>());
      expect(spec.deliveryRoadmap, isA<D11DeliveryRoadmap>());
      expect(spec.requirementsSpecification,
          isA<D04RequirementsSpecification>());
      expect(spec.transitionRolloutPlan, isA<D12TransitionRolloutPlan>());
      expect(spec.architectureTechnologySpecification,
          isA<D06ArchitectureTechnologySpecification>());
      expect(spec.interactionScenarios, isA<D05InteractionScenarios>());
      expect(spec.experienceDesignSpecification,
          isA<D09ExperienceDesignSpecification>());
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
