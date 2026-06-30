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
  ///
  /// One whole-catalog content section; collapsed from `List<UserManual>`
  /// (L34C-12 SR-57).
  UserManual userManuals = UserManual();

  /// Training materials.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<RolloutTrainingMaterial>` (L34C-12 SR-57).
  RolloutTrainingMaterial trainingMaterials = RolloutTrainingMaterial();

  /// Pilot plan.
  PilotPlan pilotPlan = PilotPlan();

  /// Cutover procedures.
  ///
  /// One whole-catalog content section; collapsed from `List<CutoverProcedure>`
  /// (L34C-12 SR-57).
  CutoverProcedure cutoverProcedures = CutoverProcedure();

  /// Knowledge transfer.
  KnowledgeTransfer knowledgeTransfer = KnowledgeTransfer();

  /// Warranty and support.
  WarrantyAndSupport warrantyAndSupport = WarrantyAndSupport();
}
