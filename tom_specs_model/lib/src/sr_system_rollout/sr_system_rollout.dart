/// SR — System Rollout.
///
/// Phase 3 DocSpec root class. Aggregates 11 top-level sections from
/// multi-source seeds per §5.9 of second_wave_documents.md:
/// PD00-USE-MUL-{LOC, TRA, DOC} (whole each) plus the Phase-A-new
/// PD00-ROL and its 8 children.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// SR00 System Rollout.
///
/// End-to-end rollout specification — localization, translation,
/// documentation and training, plus rollout plan, migration plan,
/// user manuals, training materials, pilot, cutover, knowledge
/// transfer, and warranty/support.
@Document(
  name: 'System Rollout',
  description: 'End-to-end rollout specification — localization, '
      'translation, documentation and training, rollout plan, migration '
      'plan, user manuals, training materials, pilot, cutover, knowledge '
      'transfer, and warranty/support.',
  basedOn: [ProjectDefinition],
)
@SectionId('SR00')
class SystemRollout {
  @ContentHelp('Executive overview of the rollout approach.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── From PD00-USE-MUL-{LOC,TRA,DOC} (whole each) ────────────────────────

  /// Localization process — PD00-USE-MUL-LOC.
  LocalizationProcess localizationProcess = LocalizationProcess();

  /// Translation process — PD00-USE-MUL-TRA.
  TranslationProcess translationProcess = TranslationProcess();

  /// Documentation and training — PD00-USE-MUL-DOC.
  DocumentationAndTraining documentationAndTraining =
      DocumentationAndTraining();

  // ─── From PD00-ROL (new in Phase A, flattened) ───────────────────────────

  /// Rollout plan — PD00-ROL-PLN.
  RolloutPlan rolloutPlan = RolloutPlan();

  /// Migration plan — PD00-ROL-MIG.
  MigrationPlan migrationPlan = MigrationPlan();

  /// User manuals — PD00-ROL-DOC.
  UserManuals userManuals = UserManuals();

  /// Training materials — PD00-ROL-TRN.
  RolloutTrainingMaterials trainingMaterials = RolloutTrainingMaterials();

  /// Pilot plan — PD00-ROL-PIL.
  PilotPlan pilotPlan = PilotPlan();

  /// Cutover procedures — PD00-ROL-CUT.
  CutoverProcedures cutoverProcedures = CutoverProcedures();

  /// Knowledge transfer — PD00-ROL-KNO.
  KnowledgeTransfer knowledgeTransfer = KnowledgeTransfer();

  /// Warranty and support — PD00-ROL-WAR.
  WarrantyAndSupport warrantyAndSupport = WarrantyAndSupport();
}
