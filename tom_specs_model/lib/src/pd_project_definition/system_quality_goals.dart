/// Section 11: System Quality Goals [PD00-SYQ]. Seeds → BQP.
///
/// Quality goals for acceptance testing, organized by quality category.
library;



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

  /// 11.1.1. Quality Objectives Overview [PD00-SYQ-FRA-OBJ].
  String? qualityObjectivesOverview;

  /// 11.1.2. Quality Categories [PD00-SYQ-FRA-CAT].
  List<QualityCategoryEntry> qualityCategories = [];
}

/// A quality category entry (form).
class QualityCategoryEntry {
  String? content;
  String? categoryName;
  String? description;
}

/// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
class UserQualityCriteria {
  String? content;

  /// 11.2.1. Usability [PD00-SYQ-USE-USA].
  String? usability;

  /// 11.2.2. Functional Completeness [PD00-SYQ-USE-FUN].
  String? functionalCompleteness;

  /// 11.2.3. Correctness [PD00-SYQ-USE-COR].
  String? correctness;
}

/// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
class TechnicalQualityCriteria {
  String? content;

  /// 11.3.1. Efficiency [PD00-SYQ-TEC-EFF].
  String? efficiency;

  /// 11.3.2. Portability [PD00-SYQ-TEC-POR].
  String? portability;

  /// 11.3.3. Flexibility [PD00-SYQ-TEC-FLE].
  String? flexibility;

  /// 11.3.4. Security [PD00-SYQ-TEC-SEC].
  String? security;

  /// 11.3.5. Maintainability [PD00-SYQ-TEC-MAI].
  String? maintainability;

  /// 11.3.6. Reliability [PD00-SYQ-TEC-REL].
  String? reliability;
}

/// 11.4. Operations Quality Criteria [PD00-SYQ-OPE].
class OperationsQualityCriteria {
  String? content;

  /// 11.4.1. Availability [PD00-SYQ-OPE-AVA].
  String? availability;

  /// 11.4.2. Service Level Requirements [PD00-SYQ-OPE-SER].
  String? serviceLevelRequirements;

  /// 11.4.3. Monitoring and Prevention [PD00-SYQ-OPE-MON].
  String? monitoringAndPrevention;

  /// 11.4.4. IT Security Operations [PD00-SYQ-OPE-ITS].
  String? itSecurityOperations;
}

/// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
class DocumentationQualityCriteria {
  String? content;

  /// 11.5.1. Readability [PD00-SYQ-DOC-REA].
  String? readability;

  /// 11.5.2. Completeness [PD00-SYQ-DOC-COM].
  String? completeness;

  /// 11.5.3. Correctness [PD00-SYQ-DOC-COR].
  String? correctness;

  /// 11.5.4. Changeability [PD00-SYQ-DOC-CHA].
  String? changeability;
}

/// 11.6. Quality Prioritization [PD00-SYQ-PRI].
class QualityPrioritization {
  String? content;

  /// 11.6.1. Weighted Quality Matrix [PD00-SYQ-PRI-WEI].
  String? weightedQualityMatrix;

  /// 11.6.2. Trade-off Decisions [PD00-SYQ-PRI-TRA].
  TradeOffDecisions tradeOffDecisions = TradeOffDecisions();
}

/// 11.6.2. Trade-off Decisions [PD00-SYQ-PRI-TRA].
class TradeOffDecisions {
  String? content;
  List<TradeOffDecisionEntry> items = [];
}

/// A trade-off decision entry (form).
class TradeOffDecisionEntry {
  String? content;
  String? decision;
  String? qualitiesInConflict;
  String? rationale;
  String? impact;
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
  List<MustPassCriterionEntry> items = [];
}

/// A must-pass criterion entry (form).
class MustPassCriterionEntry {
  String? content;
  String? criterion;
  String? verificationMethod;
  String? acceptanceThreshold;
}

/// 11.7.2. Quality Gate Checklist [PD00-SYQ-ACC-GAT].
class QualityGateChecklist {
  String? content;
  List<QualityGateCheckEntry> items = [];
}

/// A quality gate check entry (form).
class QualityGateCheckEntry {
  String? content;
  String? checkItem;
  String? qualityCategory;
  String? verificationMethod;
  String? responsibleParty;
}
