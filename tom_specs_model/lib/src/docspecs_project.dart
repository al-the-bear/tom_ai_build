import 'ac_authorization_concept/ac_authorization_concept.dart';
import 'bdm_business_data_model/bdm_business_data_model.dart';
import 'bp_business_processes/bp_business_processes.dart';
import 'bqp_business_quality_plan/bqp_business_quality_plan.dart';
import 'bsi_business_system_interactions/bsi_business_system_interactions.dart';
import 'cs_current_situation/cs_current_situation.dart';
import 'pd_project_definition/pd_project_definition.dart';
import 'ppp_project_phase_plan/ppp_project_phase_plan.dart';
import 'rc_requirements_catalog/rc_requirements_catalog.dart';
import 'sr_system_rollout/sr_system_rollout.dart';
import 'tr_technical_requirements/tr_technical_requirements.dart';
import 'uc_use_cases/uc_use_cases.dart';
import 'up_ui_prototype/up_ui_prototype.dart';

/// Canonical container root for the whole TomSpecs object model (V2, N9).
///
/// A spec is **one document** with thirteen entry points: the
/// [ProjectDefinition] master plus the twelve Phase 3 projection roots. This
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
/// **The ProjectDefinition is the source of truth.** The twelve Phase 3 roots
/// are `@Document(basedOn: [ProjectDefinition])` *projections* that reference
/// the same PD00 sections through their `@MapsTo` / `@DetailedIn` links; they do
/// not own copies. Editing through any projection edits the shared underlying
/// PD sections (§14).
///
/// This class is the structural anchor only. The global `toYaml` save (PD-only,
/// §15.1) and the projection connect pass (N11) are added in a later step; here
/// the container simply wires the thirteen roots onto one tree.
class DocSpecsProject {
  /// PD00 — the Project Definition master and source of truth for all shared
  /// content. Listed first in the root navigator (§14).
  ProjectDefinition projectDefinition = ProjectDefinition();

  /// AC — Authorization Concept (Phase 3 projection over PD00).
  AuthorizationConcept authorizationConcept = AuthorizationConcept();

  /// BDM — Business Data Model (Phase 3 projection over PD00).
  BusinessDataModel businessDataModel = BusinessDataModel();

  /// BP — Business Processes (Phase 3 projection over PD00).
  BusinessProcesses businessProcesses = BusinessProcesses();

  /// BQP — Business Quality Plan (Phase 3 projection over PD00).
  BusinessQualityPlan businessQualityPlan = BusinessQualityPlan();

  /// BSI — Business System Interactions (Phase 3 projection over PD00).
  BusinessSystemInteractions businessSystemInteractions =
      BusinessSystemInteractions();

  /// CS — Current Situation (Phase 3 projection over PD00).
  CurrentSituation currentSituation = CurrentSituation();

  /// PPP — Project Phase Plan (Phase 3 projection over PD00).
  ProjectPhasePlan projectPhasePlan = ProjectPhasePlan();

  /// RC — Requirements Catalog (Phase 3 projection over PD00).
  RequirementsCatalog requirementsCatalog = RequirementsCatalog();

  /// SR — System Rollout (Phase 3 projection over PD00).
  SystemRollout systemRollout = SystemRollout();

  /// TR — Technical Requirements (Phase 3 projection over PD00).
  TechnicalRequirementsSpec technicalRequirementsSpec =
      TechnicalRequirementsSpec();

  /// UC — Use Cases (Phase 3 projection over PD00).
  UseCases useCases = UseCases();

  /// UP — UI Prototype (Phase 3 projection over PD00).
  UiPrototype uiPrototype = UiPrototype();
}
