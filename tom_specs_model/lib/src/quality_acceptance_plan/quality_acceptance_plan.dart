/// D10 — Quality & Acceptance Plan.
///
/// Phase 3 DocSpec root class. Aggregates the top-level sections projected
/// (flattened) from the Solution Blueprint quality-goal and acceptance
/// sections. The quality-goal projection follows the ISO/IEC 25010:2023
/// eight-characteristic spine (L34C-8) plus the ISO/IEC 26514 documentation
/// annex.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// QAP00 Quality & Acceptance Plan.
///
/// Full quality plan combining quality goals and the acceptance plan.
@Document(
  name: 'Quality & Acceptance Plan',
  description: 'Business-facing quality plan — quality framework, the '
      'eight ISO/IEC 25010:2023 product-quality characteristics plus an '
      'ISO/IEC 26514 documentation annex, prioritization, acceptance '
      'criteria summary, test strategy, and the full acceptance plan '
      '(criteria, process, UAT, defects, sign-off, warranty).',
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

  // ─── ISO/IEC 25010:2023 product-quality characteristics ──────────────────

  /// Functional suitability (ISO/IEC 25010:2023).
  FunctionalSuitabilityCharacteristic functionalSuitability =
      FunctionalSuitabilityCharacteristic();

  /// Performance efficiency (ISO/IEC 25010:2023).
  PerformanceEfficiencyCharacteristic performanceEfficiency =
      PerformanceEfficiencyCharacteristic();

  /// Compatibility (ISO/IEC 25010:2023).
  CompatibilityCharacteristic compatibility = CompatibilityCharacteristic();

  /// Interaction capability (ISO/IEC 25010:2023; formerly Usability).
  InteractionCapabilityCharacteristic interactionCapability =
      InteractionCapabilityCharacteristic();

  /// Reliability (ISO/IEC 25010:2023).
  ReliabilityCharacteristic reliability = ReliabilityCharacteristic();

  /// Security (ISO/IEC 25010:2023).
  SecurityCharacteristic security = SecurityCharacteristic();

  /// Maintainability (ISO/IEC 25010:2023).
  MaintainabilityCharacteristic maintainability =
      MaintainabilityCharacteristic();

  /// Flexibility (ISO/IEC 25010:2023; absorbs the former Portability).
  FlexibilityCharacteristic flexibility = FlexibilityCharacteristic();

  /// Documentation quality (ISO/IEC 26514 annex).
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
