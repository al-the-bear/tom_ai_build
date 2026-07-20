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
import 'codespecs_projection/codespecs_projection.dart';
import 'package:tom_specs_core/tom_specs_core.dart';

/// Canonical container root for the whole TomSpecs object model (V2, N9).
///
/// A spec is **one document** with fourteen entry points: the
/// [D00SolutionBlueprint] master, the twelve Phase 3 projection roots, and the
/// [D13CodeSpecsProjection] Phase-4 generation projection. This class gives that
/// document a **single true root** — every document root hangs off one object,
/// so the editor can load, serialize, snapshot, and undo the entire spec by
/// operating on a single [DocSpecsProject] instance instead of fourteen
/// disconnected entry points.
///
/// **Not a document node (N9).** The container carries **no `@SectionId`** and
/// **no `@Document`** annotation: it is the tree root the tooling walks, *not* a
/// fifteenth sibling document. It never renders in the root navigator as
/// content — the navigator lists [solutionBlueprint] first, then the twelve
/// Phase-3 projection roots, then the [D13CodeSpecsProjection]. Tooling
/// (`ModelJsonExporter`, the §8.6 validator, the outliner) treats it as the
/// canonical root and exempts it from `@SectionId` coverage/uniqueness (T1).
///
/// **The D00SolutionBlueprint is the source of truth.** The twelve Phase 3 roots
/// and the [D13CodeSpecsProjection] are `@Document(basedOn: [D00SolutionBlueprint])`
/// *projections* that reference the same SBP sections through their `@MapsTo` /
/// `@DetailedIn` links (Phase-3) or `@CodeSpecKind` tags (D13); they do not own
/// copies. Editing through any projection edits the shared underlying Solution
/// Blueprint sections (§14).
///
/// This class is the structural anchor only. The global `toYaml` save
/// (Solution-Blueprint-only, §15.1) and the projection connect pass (N11) are
/// added in a later step; here the container simply wires the fourteen roots
/// onto one tree.
class DocSpecsProject extends DocSpecsSection {
  /// Constructs the container and ensures the generated snapshot/serialization
  /// ops are registered (idempotent), so [toYaml] / [toYamlForRoot] and the
  /// snapshot engine can drive the model classes without `dart:mirrors` (OE-2).
  DocSpecsProject() {
    registerSpecOps();
  }

  /// D00 — the Solution Blueprint master and source of truth for all shared
  /// content. Listed first in the root navigator (§14).
  @SerializationOrder(0)
  D00SolutionBlueprint solutionBlueprint = D00SolutionBlueprint();

  /// D08 — Security & Access Specification (Phase 3 projection).
  @SerializationOrder(1)
  D08SecurityAccessSpecification securityAccessSpecification =
      D08SecurityAccessSpecification();

  /// D03 — Information Model (Phase 3 projection).
  @SerializationOrder(2)
  D03InformationModel informationModel = D03InformationModel();

  /// D02 — Target Operating Model (Phase 3 projection).
  @SerializationOrder(3)
  D02TargetOperatingModel targetOperatingModel = D02TargetOperatingModel();

  /// D10 — Quality & Acceptance Plan (Phase 3 projection).
  @SerializationOrder(4)
  D10QualityAcceptancePlan qualityAcceptancePlan = D10QualityAcceptancePlan();

  /// D07 — Integration & Interface Specification (Phase 3 projection).
  @SerializationOrder(5)
  D07IntegrationInterfaceSpecification integrationInterfaceSpecification =
      D07IntegrationInterfaceSpecification();

  /// D01 — Current Landscape Assessment (Phase 3 projection).
  @SerializationOrder(6)
  D01CurrentLandscapeAssessment currentLandscapeAssessment =
      D01CurrentLandscapeAssessment();

  /// D11 — Delivery Roadmap (Phase 3 projection).
  @SerializationOrder(7)
  D11DeliveryRoadmap deliveryRoadmap = D11DeliveryRoadmap();

  /// D04 — Requirements Specification (Phase 3 projection).
  @SerializationOrder(8)
  D04RequirementsSpecification requirementsSpecification =
      D04RequirementsSpecification();

  /// D12 — Transition & Rollout Plan (Phase 3 projection).
  @SerializationOrder(9)
  D12TransitionRolloutPlan transitionRolloutPlan = D12TransitionRolloutPlan();

  /// D06 — Architecture & Technology Specification (Phase 3 projection).
  @SerializationOrder(10)
  D06ArchitectureTechnologySpecification architectureTechnologySpecification =
      D06ArchitectureTechnologySpecification();

  /// D05 — Interaction Scenarios (Phase 3 projection).
  @SerializationOrder(11)
  D05InteractionScenarios interactionScenarios = D05InteractionScenarios();

  /// D09 — Experience Design Specification (Phase 3 projection).
  @SerializationOrder(12)
  D09ExperienceDesignSpecification experienceDesignSpecification =
      D09ExperienceDesignSpecification();

  /// D13 — CodeSpecs Generation Projection (Phase 4 generation input).
  ///
  /// A `@Document(basedOn: [D00SolutionBlueprint])` projection like the twelve
  /// Phase-3 roots, but `@CodeSpecKind`-driven: it reaches only the isolated
  /// CodeSpecs subtrees the Phase-4 generator consumes, grouped by
  /// shared/client/server locus. Marked `@CodeSpecsProjection()`.
  @SerializationOrder(13)
  D13CodeSpecsProjection codeSpecsProjection = D13CodeSpecsProjection();

  /// The global `document:` save (§15.1): serializes the [solutionBlueprint]
  /// master alone. Because the twelve projection roots are views over the same
  /// SBP sections, the Solution Blueprint tree contains every section exactly
  /// once, so the output never duplicates a subtree.
  String toYaml() => SpecYaml.toYaml(solutionBlueprint);

  /// Per-root save. For [solutionBlueprint] this is the global [toYaml]; for a
  /// projection root it runs the connect pass first — re-pointing the
  /// projection's references onto the live Solution Blueprint sections (§15.2) —
  /// when a connect binding is registered for that root, then serializes it.
  ///
  /// The twelve per-root `connect` bindings are not yet generated (they require
  /// resolving each projection's `@MapsTo` / `@DetailedIn` links onto Solution
  /// Blueprint field paths); until then a projection serializes whatever
  /// references it already holds. See the OE-2 questions note.
  String toYamlForRoot(Object root) {
    if (identical(root, solutionBlueprint)) return toYaml();
    return SpecYaml.toYamlForProjection(root, solutionBlueprint);
  }
}
