/// D10 — Quality & Acceptance Plan.
///
/// Phase 3 DocSpec root class. Aggregates 14 top-level sections projected
/// (flattened) from the Solution Blueprint quality-goal and acceptance
/// sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// QAP00 Quality & Acceptance Plan.
///
/// Full quality plan combining quality goals and the acceptance plan.
@Document(
  name: 'Quality & Acceptance Plan',
  description: 'Business-facing quality plan — quality framework, '
      'user / technical / operations / documentation criteria, '
      'prioritization, acceptance criteria summary, test strategy, and '
      'the full acceptance plan (criteria, process, UAT, defects, '
      'sign-off, warranty).',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('QAP')
class D10QualityAcceptancePlan {
  @ContentHelp('Executive overview of the business quality plan.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── System Quality Goals (flattened) ────────────────────────────────────

  /// Quality framework.
  QualityFramework qualityFramework = QualityFramework();

  /// User-related quality criteria.
  UserQualityCriteria userQualityCriteria = UserQualityCriteria();

  /// Technical quality criteria.
  TechnicalQualityCriteria technicalQualityCriteria =
      TechnicalQualityCriteria();

  /// Operations quality criteria.
  OperationsQualityCriteria operationsQualityCriteria =
      OperationsQualityCriteria();

  /// Documentation quality criteria.
  DocumentationQualityCriteria documentationQualityCriteria =
      DocumentationQualityCriteria();

  /// Quality prioritization.
  QualityPrioritization qualityPrioritization = QualityPrioritization();

  /// Acceptance criteria summary.
  AcceptanceCriteriaSummary acceptanceCriteriaSummary =
      AcceptanceCriteriaSummary();

  /// Test strategy (new in Phase A).
  TestStrategy testStrategy = TestStrategy();

  // ─── Acceptance Plan (flattened) ─────────────────────────────────────────

  /// Acceptance criteria.
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// Acceptance process.
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// User acceptance testing.
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// Defect resolution.
  DefectResolution defectResolution = DefectResolution();

  /// Sign-off process.
  SignOffProcess signOffProcess = SignOffProcess();

  /// Warranty terms.
  WarrantyTerms warranty = WarrantyTerms();
}
