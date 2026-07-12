// HAND-AUTHORED — not generated. Preserved across `generate_som` runs (the
// generator only rewrites lib/, meta/, schemas/ and pubspec.yaml).
//
// DR8 agreement suite for the generated metadata library
// (`tom_som_dart_v0_meta.dart`, DR1 §3.2/§4). Two guarantees over the *real*
// committed model:
//
//   1. EXHAUSTIVE TREE AGREEMENT — for every one of the 13 document roots the
//      generated static `SomMetaTree` is field-for-field identical (via
//      `somMetaNodeDiff`) to the tree `buildSomMetaTree` derives from the
//      committed `meta/spec_model.meta.json` at runtime. Since the emitter
//      writes the dot-notation / ID-tree accessor paths from the same node
//      walk, this also anchors every `.path` the accessors can produce.
//   2. SURFACE AGREEMENT — the dot-notation entry points, the ID-tree entry
//      points, and the dynamic `byPath` lookups all resolve to the *same*
//      node instances for representative positions (root, nested section,
//      content leaf, list, list element, hoisted id).
//
// Run with `dart test` from this package (`tom_som_dart_v0`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';
import 'package:test/test.dart';

void main() {
  final model = SpecModel.fromJson(
      jsonDecode(File('meta/spec_model.meta.json').readAsStringSync())
          as Map<String, dynamic>);

  // Every generated per-root static tree, keyed by its root type.
  final generatedTrees = <String, SomMetaTree>{
    'D00SolutionBlueprint': d00SolutionBlueprintMetaTree,
    'D01CurrentLandscapeAssessment': d01CurrentLandscapeAssessmentMetaTree,
    'D02TargetOperatingModel': d02TargetOperatingModelMetaTree,
    'D03InformationModel': d03InformationModelMetaTree,
    'D04RequirementsSpecification': d04RequirementsSpecificationMetaTree,
    'D05InteractionScenarios': d05InteractionScenariosMetaTree,
    'D06ArchitectureTechnologySpecification':
        d06ArchitectureTechnologySpecificationMetaTree,
    'D07IntegrationInterfaceSpecification':
        d07IntegrationInterfaceSpecificationMetaTree,
    'D08SecurityAccessSpecification': d08SecurityAccessSpecificationMetaTree,
    'D09ExperienceDesignSpecification': d09ExperienceDesignSpecificationMetaTree,
    'D10QualityAcceptancePlan': d10QualityAcceptancePlanMetaTree,
    'D11DeliveryRoadmap': d11DeliveryRoadmapMetaTree,
    'D12TransitionRolloutPlan': d12TransitionRolloutPlanMetaTree,
  };

  group('generated metadata trees == bridge trees (all 13 roots)', () {
    test('the generated map covers exactly the model roots', () {
      expect(generatedTrees.keys.toSet(),
          model.roots.map((r) => r.type).toSet());
    });

    for (final rootType in generatedTrees.keys) {
      test('$rootType tree agrees field-for-field with buildSomMetaTree', () {
        final bridge = buildSomMetaTree(model, rootType: rootType);
        final diff =
            somMetaNodeDiff(generatedTrees[rootType]!.root, bridge.root);
        expect(diff, isNull, reason: diff);
      });
    }
  });

  group('dot-notation surface (DR1 §4.1)', () {
    test('root, nested-section and leaf paths', () {
      expect(d00SolutionBlueprint.path, 'SBP');
      expect(d00SolutionBlueprint.introductionAndScope.path,
          'SBP/introductionAndScope');
      expect(d00SolutionBlueprint.requirements.content.path,
          'SBP/requirements/content');
      expect(d00SolutionBlueprint.introductionAndScope.goals.content.path,
          'SBP/introductionAndScope/goals/content');
    });

    test('.meta resolves to the same node byPath finds', () {
      final viaDot = d00SolutionBlueprint.introductionAndScope.meta;
      final viaPath =
          d00SolutionBlueprintMetaTree.byPath('SBP/introductionAndScope');
      expect(identical(viaDot, viaPath), isTrue);
      expect(viaDot.memberName, 'introductionAndScope');
    });

    test('list positions expose item() with element accessors', () {
      final revs = d00SolutionBlueprint.documentControl.revisionHistory.revisions;
      expect(revs.path, 'SBP/documentControl/revisionHistory/RVHST-REVS-LST');
      expect(revs.item(3).path,
          'SBP/documentControl/revisionHistory/RVHST-REVS-LST-3');
      // The list node's metadata carries the section-id pattern.
      expect(revs.meta.sectionIdPattern, isNotNull);
    });

    test('a second root has its own entry point and segment', () {
      expect(d01CurrentLandscapeAssessment.path, isNot('SBP'));
      expect(
          identical(d01CurrentLandscapeAssessment.meta,
              d01CurrentLandscapeAssessmentMetaTree.root),
          isTrue);
    });
  });

  group('ID-tree surface (DR1 §4.2)', () {
    test('the Id root shares the dot root position', () {
      expect(SBP.path, d00SolutionBlueprint.path);
      expect(identical(SBP.meta, d00SolutionBlueprint.meta), isTrue);
    });

    test('a hoisted list id agrees with the dot-notation position', () {
      // RVHST_REVS_LST is hoisted onto the root Id class through the id-less
      // documentControl/revisionHistory members.
      expect(SBP.RVHST_REVS_LST.path,
          d00SolutionBlueprint.documentControl.revisionHistory.revisions.path);
      expect(
          identical(
              SBP.RVHST_REVS_LST.meta,
              d00SolutionBlueprint
                  .documentControl.revisionHistory.revisions.meta),
          isTrue);
      // Element access agrees too.
      expect(SBP.RVHST_REVS_LST.item(0).path,
          d00SolutionBlueprint.documentControl.revisionHistory.revisions
              .item(0)
              .path);
    });

    test('every root has a distinct Id entry point at its own segment', () {
      final idRoots = <String, SomMetaRef>{
        'D00SolutionBlueprint': SBP,
        'D01CurrentLandscapeAssessment': CLA,
        'D02TargetOperatingModel': TOM,
        'D03InformationModel': IFM,
        'D04RequirementsSpecification': RSP,
        'D05InteractionScenarios': ISC,
        'D06ArchitectureTechnologySpecification': ATS,
        'D07IntegrationInterfaceSpecification': IIS,
        'D08SecurityAccessSpecification': SAS,
        'D09ExperienceDesignSpecification': XDS,
        'D10QualityAcceptancePlan': QAP,
        'D11DeliveryRoadmap': DRM,
        'D12TransitionRolloutPlan': TRP,
      };
      expect(idRoots.keys.toSet(), generatedTrees.keys.toSet());
      for (final e in idRoots.entries) {
        final tree = generatedTrees[e.key]!;
        expect(e.value.path, tree.root.sectionId, reason: e.key);
        expect(identical(e.value.meta, tree.root), isTrue, reason: e.key);
      }
    });
  });
}
