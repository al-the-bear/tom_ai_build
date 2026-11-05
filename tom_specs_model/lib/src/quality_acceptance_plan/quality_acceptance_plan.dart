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
import '../common/review_team.dart';
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
  description:
      'Business-facing quality plan — quality framework, the '
      'eight ISO/IEC 25010:2023 product-quality characteristics plus an '
      'ISO/IEC 26514 documentation annex, prioritization, acceptance '
      'criteria summary, test strategy, and the full acceptance plan '
      '(criteria, process, UAT, defects, sign-off, warranty).',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('QAP')
class D10QualityAcceptancePlan extends DocSpecsSection {
  @ContentHelp('Executive overview of the business quality plan.')
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

  // ─── System Quality Goals (flattened) ────────────────────────────────────

  /// Quality framework.
  @SerializationOrder(4)
  QualityFramework qualityFramework = QualityFramework();

  // ─── ISO/IEC 25010:2023 product-quality characteristics ──────────────────

  /// Functional suitability (ISO/IEC 25010:2023).
  @SerializationOrder(5)
  FunctionalSuitabilityCharacteristic functionalSuitability =
      FunctionalSuitabilityCharacteristic();

  /// Performance efficiency (ISO/IEC 25010:2023).
  @SerializationOrder(6)
  PerformanceEfficiencyCharacteristic performanceEfficiency =
      PerformanceEfficiencyCharacteristic();

  /// Compatibility (ISO/IEC 25010:2023).
  @SerializationOrder(7)
  CompatibilityCharacteristic compatibility = CompatibilityCharacteristic();

  /// Interaction capability (ISO/IEC 25010:2023; formerly Usability).
  @SerializationOrder(8)
  InteractionCapabilityCharacteristic interactionCapability =
      InteractionCapabilityCharacteristic();

  /// Reliability (ISO/IEC 25010:2023).
  @SerializationOrder(9)
  ReliabilityCharacteristic reliability = ReliabilityCharacteristic();

  /// Security (ISO/IEC 25010:2023).
  @SerializationOrder(10)
  SecurityCharacteristic security = SecurityCharacteristic();

  /// Maintainability (ISO/IEC 25010:2023).
  @SerializationOrder(11)
  MaintainabilityCharacteristic maintainability =
      MaintainabilityCharacteristic();

  /// Flexibility (ISO/IEC 25010:2023; absorbs the former Portability).
  @SerializationOrder(12)
  FlexibilityCharacteristic flexibility = FlexibilityCharacteristic();

  /// Documentation quality (ISO/IEC 26514 annex).
  @SerializationOrder(13)
  DocumentationQualityCriteria documentationQualityCriteria =
      DocumentationQualityCriteria();

  /// Quality prioritization.
  @SerializationOrder(14)
  QualityPrioritization qualityPrioritization = QualityPrioritization();

  /// Acceptance criteria summary.
  @SerializationOrder(15)
  AcceptanceCriteriaSummary acceptanceCriteriaSummary =
      AcceptanceCriteriaSummary();

  /// Test strategy (new in Phase A).
  @SerializationOrder(16)
  TestStrategy testStrategy = TestStrategy();

  // ─── Acceptance Plan (flattened) ─────────────────────────────────────────

  /// Acceptance criteria.
  @SerializationOrder(17)
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// Acceptance process.
  @SerializationOrder(18)
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// User acceptance testing.
  @SerializationOrder(19)
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// Defect resolution.
  @SerializationOrder(20)
  DefectResolution defectResolution = DefectResolution();

  /// Sign-off process.
  @SerializationOrder(21)
  SignOffProcess signOffProcess = SignOffProcess();

  /// Warranty terms.
  @SerializationOrder(22)
  WarrantyTerms warranty = WarrantyTerms();
}
