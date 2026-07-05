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
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — product quality model',
    'ISO/IEC/IEEE 29119 — software testing',
  ],
  'The business-facing quality plan combining the eight product-quality characteristics, prioritization, acceptance criteria, test strategy, and the full acceptance plan.',
)
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
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  // ─── System Quality Goals (flattened) ────────────────────────────────────

  /// Quality framework.
  @SerializationOrder(2)
  QualityFramework qualityFramework = QualityFramework();

  // ─── ISO/IEC 25010:2023 product-quality characteristics ──────────────────

  /// Functional suitability (ISO/IEC 25010:2023).
  @SerializationOrder(3)
  FunctionalSuitabilityCharacteristic functionalSuitability =
      FunctionalSuitabilityCharacteristic();

  /// Performance efficiency (ISO/IEC 25010:2023).
  @SerializationOrder(4)
  PerformanceEfficiencyCharacteristic performanceEfficiency =
      PerformanceEfficiencyCharacteristic();

  /// Compatibility (ISO/IEC 25010:2023).
  @SerializationOrder(5)
  CompatibilityCharacteristic compatibility = CompatibilityCharacteristic();

  /// Interaction capability (ISO/IEC 25010:2023; formerly Usability).
  @SerializationOrder(6)
  InteractionCapabilityCharacteristic interactionCapability =
      InteractionCapabilityCharacteristic();

  /// Reliability (ISO/IEC 25010:2023).
  @SerializationOrder(7)
  ReliabilityCharacteristic reliability = ReliabilityCharacteristic();

  /// Security (ISO/IEC 25010:2023).
  @SerializationOrder(8)
  SecurityCharacteristic security = SecurityCharacteristic();

  /// Maintainability (ISO/IEC 25010:2023).
  @SerializationOrder(9)
  MaintainabilityCharacteristic maintainability =
      MaintainabilityCharacteristic();

  /// Flexibility (ISO/IEC 25010:2023; absorbs the former Portability).
  @SerializationOrder(10)
  FlexibilityCharacteristic flexibility = FlexibilityCharacteristic();

  /// Documentation quality (ISO/IEC 26514 annex).
  @SerializationOrder(11)
  DocumentationQualityCriteria documentationQualityCriteria =
      DocumentationQualityCriteria();

  /// Quality prioritization.
  @SerializationOrder(12)
  QualityPrioritization qualityPrioritization = QualityPrioritization();

  /// Acceptance criteria summary.
  @SerializationOrder(13)
  AcceptanceCriteriaSummary acceptanceCriteriaSummary =
      AcceptanceCriteriaSummary();

  /// Test strategy (new in Phase A).
  @SerializationOrder(14)
  TestStrategy testStrategy = TestStrategy();

  // ─── Acceptance Plan (flattened) ─────────────────────────────────────────

  /// Acceptance criteria.
  @SerializationOrder(15)
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// Acceptance process.
  @SerializationOrder(16)
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// User acceptance testing.
  @SerializationOrder(17)
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// Defect resolution.
  @SerializationOrder(18)
  DefectResolution defectResolution = DefectResolution();

  /// Sign-off process.
  @SerializationOrder(19)
  SignOffProcess signOffProcess = SignOffProcess();

  /// Warranty terms.
  @SerializationOrder(20)
  WarrantyTerms warranty = WarrantyTerms();
}
