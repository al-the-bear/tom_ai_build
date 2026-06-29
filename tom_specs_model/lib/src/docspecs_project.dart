import 'generated/spec_ops.g.dart';
import 'serialization/spec_yaml.dart';

import 'security_access_specification/security_access_specification.dart';
import 'information_model/information_model.dart';
import 'target_operating_model/target_operating_model.dart';
import 'quality_acceptance_plan/quality_acceptance_plan.dart';
import 'integration_interface_specification/integration_interface_specification.dart';
import 'current_landscape_assessment/current_landscape_assessment.dart';
import 'solution_blueprint/solution_blueprint.dart';
import 'delivery_roadmap/delivery_roadmap.dart';
import 'requirements_specification/requirements_specification.dart';
import 'transition_rollout_plan/transition_rollout_plan.dart';
import 'architecture_technology_specification/architecture_technology_specification.dart';
import 'interaction_scenarios/interaction_scenarios.dart';
import 'experience_design_specification/experience_design_specification.dart';

/// Canonical container root for the whole TomSpecs object model (V2, N9).
///
/// A spec is **one document** with thirteen entry points: the
/// [D00SolutionBlueprint] master plus the twelve Phase 3 projection roots. This
/// class gives that document a **single true root** — every document root hangs
/// off one object, so the editor can load, serialize, snapshot, and undo the
/// entire spec by operating on a single [DocSpecsProject] instance instead of
/// thirteen disconnected entry points.
///
/// **Not a document node (N9).** The container carries **no `@SectionId`** and
/// **no `@Document`** annotation: it is the tree root the tooling walks, *not* a
/// fourteenth sibling document. It never renders in the root navigator as
/// content — the navigator lists [projectDefinition] first, then the twelve
/// projection roots. Tooling (`ModelJsonExporter`, the §8.6 validator, the
/// outliner) treats it as the canonical root and exempts it from `@SectionId`
/// coverage/uniqueness (T1).
///
/// **The D00SolutionBlueprint is the source of truth.** The twelve Phase 3 roots
/// are `@Document(basedOn: [D00SolutionBlueprint])` *projections* that reference
/// the same SBP sections through their `@MapsTo` / `@DetailedIn` links; they do
/// not own copies. Editing through any projection edits the shared underlying
/// PD sections (§14).
///
/// This class is the structural anchor only. The global `toYaml` save (PD-only,
/// §15.1) and the projection connect pass (N11) are added in a later step; here
/// the container simply wires the thirteen roots onto one tree.
class DocSpecsProject {
  /// Constructs the container and ensures the generated snapshot/serialization
  /// ops are registered (idempotent), so [toYaml] / [toYamlForRoot] and the
  /// snapshot engine can drive the model classes without `dart:mirrors` (OE-2).
  DocSpecsProject() {
    registerSpecOps();
  }

  /// SBP — the Project Definition master and source of truth for all shared
  /// content. Listed first in the root navigator (§14).
  D00SolutionBlueprint projectDefinition = D00SolutionBlueprint();

  /// AC — Authorization Concept (Phase 3 projection).
  D08SecurityAccessSpecification authorizationConcept = D08SecurityAccessSpecification();

  /// BDM — Business Data Model (Phase 3 projection).
  D03InformationModel businessDataModel = D03InformationModel();

  /// BP — Business Processes (Phase 3 projection).
  D02TargetOperatingModel businessProcesses = D02TargetOperatingModel();

  /// BQP — Business Quality Plan (Phase 3 projection).
  D10QualityAcceptancePlan businessQualityPlan = D10QualityAcceptancePlan();

  /// BSI — Business System Interactions (Phase 3 projection).
  D07IntegrationInterfaceSpecification businessSystemInteractions =
      D07IntegrationInterfaceSpecification();

  /// CS — Current Situation (Phase 3 projection).
  D01CurrentLandscapeAssessment currentSituation = D01CurrentLandscapeAssessment();

  /// PPP — Project Phase Plan (Phase 3 projection).
  D11DeliveryRoadmap projectPhasePlan = D11DeliveryRoadmap();

  /// RC — Requirements Catalog (Phase 3 projection).
  D04RequirementsSpecification requirementsCatalog = D04RequirementsSpecification();

  /// SR — System Rollout (Phase 3 projection).
  D12TransitionRolloutPlan systemRollout = D12TransitionRolloutPlan();

  /// TR — Technical Requirements (Phase 3 projection).
  D06ArchitectureTechnologySpecification technicalRequirementsSpec =
      D06ArchitectureTechnologySpecification();

  /// UC — Use Cases (Phase 3 projection).
  D05InteractionScenarios useCases = D05InteractionScenarios();

  /// UP — UI Prototype (Phase 3 projection).
  D09ExperienceDesignSpecification uiPrototype = D09ExperienceDesignSpecification();

  /// The global `document:` save (§15.1): serializes the [projectDefinition]
  /// master alone. Because the twelve projection roots are views over the same
  /// SBP sections, the PD tree contains every section exactly once, so the
  /// output never duplicates a subtree.
  String toYaml() => SpecYaml.toYaml(projectDefinition);

  /// Per-root save. For [projectDefinition] this is the global [toYaml]; for a
  /// projection root it runs the connect pass first — re-pointing the
  /// projection's references onto the live PD sections (§15.2) — when a connect
  /// binding is registered for that root, then serializes it.
  ///
  /// The twelve per-root `connect` bindings are not yet generated (they require
  /// resolving each projection's `@MapsTo` / `@DetailedIn` links onto PD field
  /// paths); until then a projection serializes whatever references it already
  /// holds. See the OE-2 questions note.
  String toYamlForRoot(Object root) {
    if (identical(root, projectDefinition)) return toYaml();
    return SpecYaml.toYamlForProjection(root, projectDefinition);
  }
}
