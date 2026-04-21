/// BQP — Business Quality Plan.
///
/// Phase 3 DocSpec root class. Aggregates 14 top-level sections from
/// two PD00 seeds (both flattened) per §5.10 of
/// second_wave_documents.md: PD00-SYQ (7 existing + TST new) and
/// PD00-DEL-ACC (6 children).
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// BQP00 Business Quality Plan.
///
/// Full quality plan combining quality goals (PD00-SYQ) and the
/// acceptance plan (PD00-DEL-ACC). Replaces HBSG AS11 + AS23 + partial
/// AS14 coverage.
@Document(
  name: 'Business Quality Plan',
  description: 'Business-facing quality plan — quality framework, '
      'user / technical / operations / documentation criteria, '
      'prioritization, acceptance criteria summary, test strategy, and '
      'the full acceptance plan (criteria, process, UAT, defects, '
      'sign-off, warranty).',
  basedOn: [ProjectDefinition],
)
@SectionId('BQP')
class BusinessQualityPlan {
  @ContentHelp('Executive overview of the business quality plan.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── From PD00-SYQ (System Quality Goals), flattened ─────────────────────

  /// Quality framework — PD00-SYQ-FRA.
  QualityFramework qualityFramework = QualityFramework();

  /// User-related quality criteria — PD00-SYQ-USE.
  UserQualityCriteria userQualityCriteria = UserQualityCriteria();

  /// Technical quality criteria — PD00-SYQ-TEC.
  TechnicalQualityCriteria technicalQualityCriteria =
      TechnicalQualityCriteria();

  /// Operations quality criteria — PD00-SYQ-OPE.
  OperationsQualityCriteria operationsQualityCriteria =
      OperationsQualityCriteria();

  /// Documentation quality criteria — PD00-SYQ-DOC.
  DocumentationQualityCriteria documentationQualityCriteria =
      DocumentationQualityCriteria();

  /// Quality prioritization — PD00-SYQ-PRI.
  QualityPrioritization qualityPrioritization = QualityPrioritization();

  /// Acceptance criteria summary — PD00-SYQ-ACC.
  AcceptanceCriteriaSummary acceptanceCriteriaSummary =
      AcceptanceCriteriaSummary();

  /// Test strategy — PD00-SYQ-TST (new in Phase A, HBSG AS23).
  TestStrategy testStrategy = TestStrategy();

  // ─── From PD00-DEL-ACC (Acceptance Plan), flattened ──────────────────────

  /// Acceptance criteria — PD00-DEL-ACC-CRI.
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// Acceptance process — PD00-DEL-ACC-PRO.
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// User acceptance testing — PD00-DEL-ACC-UAT.
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// Defect resolution — PD00-DEL-ACC-DEF.
  DefectResolution defectResolution = DefectResolution();

  /// Sign-off process — PD00-DEL-ACC-SIG.
  SignOffProcess signOffProcess = SignOffProcess();

  /// Warranty terms — PD00-DEL-ACC-WAR.
  WarrantyTerms warranty = WarrantyTerms();
}
