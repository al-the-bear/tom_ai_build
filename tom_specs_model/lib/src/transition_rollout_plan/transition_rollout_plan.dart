/// D12 — Transition & Rollout Plan.
///
/// Phase 3 DocSpec root class. Aggregates 11 top-level sections projected
/// from the Solution Blueprint localization, translation, and
/// documentation sections plus the system-rollout-concept subtree.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// TRP00 Transition & Rollout Plan.
///
/// End-to-end rollout specification — localization, translation,
/// documentation and training, plus rollout plan, migration plan,
/// user manuals, training materials, pilot, cutover, knowledge
/// transfer, and warranty/support.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148:2018 — transition requirements',
    'ITIL 4 — release and change management',
  ],
  'The end-to-end rollout specification covering localization, translation, documentation, training, rollout, migration, pilot, cutover, knowledge transfer, and warranty.',
)
@Document(
  name: 'Transition & Rollout Plan',
  description:
      'End-to-end rollout specification — localization, '
      'translation, documentation and training, rollout plan, migration '
      'plan, user manuals, training materials, pilot, cutover, knowledge '
      'transfer, and warranty/support.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('TRP')
class D12TransitionRolloutPlan extends DocSpecsSection {
  @ContentHelp('Executive overview of the rollout approach.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// This document's own review team; when it has members it replaces the
  /// Solution Blueprint's team for this document type and its default team.
  @SerializationOrder(2)
  ReviewTeam reviewTeam = ReviewTeam();

  /// Chronological revision history of this document, with the reviewers of
  /// each revision.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (revision history)',
  ], 'The ordered set of published revisions of this document.')
  @SectionId('RVENT-REVS-LST')
  @SectionIdPattern('RVENT-REVS-xxx')
  @ContentHelp(
    'Add one entry per revision, newest last: version, date, author, a short '
    'summary, the review team the round started with and the reviewers who '
    'returned a copy.',
  )
  @SerializationOrder(3)
  List<RevisionEntry> revisionHistory = [];

  // ─── Localization, Translation & Documentation ───────────────────────────

  /// Localization process.
  @SerializationOrder(4)
  LocalizationProcess localizationProcess = LocalizationProcess();

  /// Translation process.
  @SerializationOrder(5)
  TranslationProcess translationProcess = TranslationProcess();

  /// User documentation requirements (doc half of the former DOANTR;
  /// split in L34C-7).
  @SerializationOrder(6)
  UserDocumentationRequirements userDocumentation =
      UserDocumentationRequirements();

  /// Training deliverable requirements (training half of the former DOANTR;
  /// split in L34C-7).
  @SerializationOrder(7)
  TrainingDeliverableRequirements trainingDeliverables =
      TrainingDeliverableRequirements();

  // ─── System Rollout Concept (flattened) ──────────────────────────────────

  /// Rollout plan.
  @SerializationOrder(8)
  RolloutPlan rolloutPlan = RolloutPlan();

  /// Migration plan.
  @SerializationOrder(9)
  MigrationPlan migrationPlan = MigrationPlan();

  /// User manuals.
  ///
  /// One whole-catalog content section; collapsed from `List<UserManual>`
  /// (L34C-12 SR-57).
  @SerializationOrder(10)
  UserManual userManuals = UserManual();

  /// Training materials.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<RolloutTrainingMaterial>` (L34C-12 SR-57).
  @SerializationOrder(11)
  RolloutTrainingMaterial trainingMaterials = RolloutTrainingMaterial();

  /// Pilot plan.
  @SerializationOrder(12)
  PilotPlan pilotPlan = PilotPlan();

  /// Cutover procedures.
  ///
  /// One whole-catalog content section; collapsed from `List<CutoverProcedure>`
  /// (L34C-12 SR-57).
  @SerializationOrder(13)
  CutoverProcedure cutoverProcedures = CutoverProcedure();

  /// Knowledge transfer.
  @SerializationOrder(14)
  KnowledgeTransfer knowledgeTransfer = KnowledgeTransfer();

  /// Warranty and support.
  @SerializationOrder(15)
  WarrantyAndSupport warrantyAndSupport = WarrantyAndSupport();
}
