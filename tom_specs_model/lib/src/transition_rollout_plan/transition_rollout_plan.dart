/// D12 — Transition & Rollout Plan.
///
/// Phase 3 DocSpec root class. Aggregates 11 top-level sections projected
/// from the Solution Blueprint localization, translation, and
/// documentation sections plus the system-rollout-concept subtree.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// TRP00 Transition & Rollout Plan.
///
/// End-to-end rollout specification — localization, translation,
/// documentation and training, plus rollout plan, migration plan,
/// user manuals, training materials, pilot, cutover, knowledge
/// transfer, and warranty/support.
@Document(
  name: 'Transition & Rollout Plan',
  description: 'End-to-end rollout specification — localization, '
      'translation, documentation and training, rollout plan, migration '
      'plan, user manuals, training materials, pilot, cutover, knowledge '
      'transfer, and warranty/support.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('TRP')
class D12TransitionRolloutPlan {
  @ContentHelp('Executive overview of the rollout approach.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── Localization, Translation & Documentation ───────────────────────────

  /// Localization process.
  LocalizationProcess localizationProcess = LocalizationProcess();

  /// Translation process.
  TranslationProcess translationProcess = TranslationProcess();

  /// User documentation requirements (doc half of the former DOANTR;
  /// split in L34C-7).
  UserDocumentationRequirements userDocumentation =
      UserDocumentationRequirements();

  /// Training deliverable requirements (training half of the former DOANTR;
  /// split in L34C-7).
  TrainingDeliverableRequirements trainingDeliverables =
      TrainingDeliverableRequirements();

  // ─── System Rollout Concept (flattened) ──────────────────────────────────

  /// Rollout plan.
  RolloutPlan rolloutPlan = RolloutPlan();

  /// Migration plan.
  MigrationPlan migrationPlan = MigrationPlan();

  /// User manuals.
  @SectionId('USRMAN-USER-LST')
  @SectionIdPattern('USRMAN-USER-xxx')
  List<UserManuals> userManuals = [];

  /// Training materials.
  @SectionId('RLTTM-TRAI-LST')
  @SectionIdPattern('RLTTM-TRAI-xxx')
  List<RolloutTrainingMaterials> trainingMaterials = [];

  /// Pilot plan.
  PilotPlan pilotPlan = PilotPlan();

  /// Cutover procedures.
  @SectionId('CUTPRC-CUTO-LST')
  @SectionIdPattern('CUTPRC-CUTO-xxx')
  List<CutoverProcedures> cutoverProcedures = [];

  /// Knowledge transfer.
  KnowledgeTransfer knowledgeTransfer = KnowledgeTransfer();

  /// Warranty and support.
  WarrantyAndSupport warrantyAndSupport = WarrantyAndSupport();
}
