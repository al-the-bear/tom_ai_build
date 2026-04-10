/// Section 11: System Quality Goals [PD00-SYQ]. Seeds → BQP.
///
/// Quality goals for acceptance testing, organized by quality category.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 11. System Quality Goals [PD00-SYQ]. Seeds → BQP.
class SystemQualityGoals {
  String? content;

  /// 11.1. Quality Framework [PD00-SYQ-FRA].
  QualityFramework framework = QualityFramework();

  /// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
  UserQualityCriteria userQuality = UserQualityCriteria();

  /// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
  TechnicalQualityCriteria technicalQuality = TechnicalQualityCriteria();

  /// 11.4. Operations Quality Criteria [PD00-SYQ-OPE].
  OperationsQualityCriteria operationsQuality = OperationsQualityCriteria();

  /// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
  DocumentationQualityCriteria documentationQuality = DocumentationQualityCriteria();

  /// 11.6. Quality Prioritization [PD00-SYQ-PRI].
  QualityPrioritization prioritization = QualityPrioritization();

  /// 11.7. Acceptance Criteria Summary [PD00-SYQ-ACC].
  AcceptanceCriteriaSummary acceptanceCriteria = AcceptanceCriteriaSummary();
}

/// 11.1. Quality Framework [PD00-SYQ-FRA].
class QualityFramework {
  String? content;

  /// Quality Objectives Overview.
  TextSection qualityObjectivesOverview = TextSection();

  /// 11.1.2. Quality Categories [PD00-SYQ-FRA-CAT] — contains 0+× QualityCategory.
  List<QualityCategoryEntry> qualityCategories = [];
}

/// A quality category entry (form) [PD00-SYQ-FRA-CAT-nn].
class QualityCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Short description'),
  ])

  String? content;
}

/// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
class UserQualityCriteria {
  String? content;

  /// Usability.
  TextSection usability = TextSection();

  /// Functional Completeness.
  TextSection functionalCompleteness = TextSection();

  /// Correctness.
  TextSection correctness = TextSection();
}

/// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
class TechnicalQualityCriteria {
  String? content;

  /// Efficiency.
  TextSection efficiency = TextSection();

  /// Portability.
  TextSection portability = TextSection();

  /// Flexibility.
  TextSection flexibility = TextSection();

  /// Security.
  TextSection security = TextSection();

  /// Maintainability.
  TextSection maintainability = TextSection();

  /// Reliability.
  TextSection reliability = TextSection();
}

/// 11.4. Operations Quality Criteria [PD00-SYQ-OPE].
class OperationsQualityCriteria {
  String? content;

  /// Availability.
  TextSection availability = TextSection();

  /// Service Level Requirements.
  TextSection serviceLevelRequirements = TextSection();

  /// Monitoring And Prevention.
  TextSection monitoringAndPrevention = TextSection();

  /// It Security Operations.
  TextSection itSecurityOperations = TextSection();
}

/// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
class DocumentationQualityCriteria {
  String? content;

  /// Readability.
  TextSection readability = TextSection();

  /// Completeness.
  TextSection completeness = TextSection();

  /// Correctness.
  TextSection correctness = TextSection();

  /// Changeability.
  TextSection changeability = TextSection();
}

/// 11.6. Quality Prioritization [PD00-SYQ-PRI].
class QualityPrioritization {
  String? content;

  /// Weighted Quality Matrix.
  TextSection weightedQualityMatrix = TextSection();

  /// 11.6.2. Trade-off Decisions [PD00-SYQ-PRI-TRA].
  TradeOffDecisions tradeOffDecisions = TradeOffDecisions();
}

/// 11.6.2. Trade-off Decisions [PD00-SYQ-PRI-TRA].
class TradeOffDecisions {
  String? content;
  /// Contains 0+× TradeOffDecision.
  List<TradeOffDecisionEntry> items = [];
}

/// A trade-off decision entry (form) [PD00-SYQ-PRI-TRA-nn].
class TradeOffDecisionEntry {
  @Form([
    Field('decision', String, 'Decision'),
    Field('qualitiesInConflict', String, 'Qualities In Conflict'),
    Field('rationale', String, 'Rationale'),
    Field('impact', String, 'Impact assessment'),
  ])

  String? content;
}

/// 11.7. Acceptance Criteria Summary [PD00-SYQ-ACC].
class AcceptanceCriteriaSummary {
  String? content;

  /// 11.7.1. Must-Pass Criteria [PD00-SYQ-ACC-MUS].
  MustPassCriteria mustPassCriteria = MustPassCriteria();

  /// 11.7.2. Quality Gate Checklist [PD00-SYQ-ACC-GAT].
  QualityGateChecklist qualityGateChecklist = QualityGateChecklist();
}

/// 11.7.1. Must-Pass Criteria [PD00-SYQ-ACC-MUS].
class MustPassCriteria {
  String? content;
  /// Contains 0+× MustPassCriterion.
  List<MustPassCriterionEntry> items = [];
}

/// A must-pass criterion entry (form) [PD00-SYQ-ACC-MUS-nn].
class MustPassCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('verificationMethod', String, 'Verification Method'),
    Field('acceptanceThreshold', String, 'Acceptance Threshold'),
  ])

  String? content;
}

/// 11.7.2. Quality Gate Checklist [PD00-SYQ-ACC-GAT].
class QualityGateChecklist {
  String? content;
  /// Contains 0+× QualityGateCheck.
  List<QualityGateCheckEntry> items = [];
}

/// A quality gate check entry (form) [PD00-SYQ-ACC-GAT-nn].
class QualityGateCheckEntry {
  @Form([
    Field('checkItem', String, 'Check Item'),
    Field('qualityCategory', String, 'Quality Category'),
    Field('verificationMethod', String, 'Verification Method'),
    Field('responsibleParty', String, 'Responsible Party'),
  ])

  String? content;
}
