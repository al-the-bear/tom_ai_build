/// Section 11: System Quality Goals [PD00-SYQ]. Seeds → BQP.
///
/// Quality goals for acceptance testing, organized by quality category.
library;


/// 11. System Quality Goals [PD00-SYQ]. Seeds → BQP.
class SystemQualityGoals {
  final String? content;

  /// 11.1. Quality Framework [PD00-SYQ-FRA].
  final QualityFramework framework;

  /// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
  final UserQualityCriteria userQuality;

  /// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
  final TechnicalQualityCriteria technicalQuality;

  /// 11.4. Operations Quality Criteria [PD00-SYQ-OPE].
  final OperationsQualityCriteria operationsQuality;

  /// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
  final DocumentationQualityCriteria documentationQuality;

  /// 11.6. Quality Prioritization [PD00-SYQ-PRI].
  final QualityPrioritization prioritization;

  /// 11.7. Acceptance Criteria Summary [PD00-SYQ-ACC].
  final AcceptanceCriteriaSummary acceptanceCriteria;

  const SystemQualityGoals({
    this.content,
    this.framework = const QualityFramework(),
    this.userQuality = const UserQualityCriteria(),
    this.technicalQuality = const TechnicalQualityCriteria(),
    this.operationsQuality = const OperationsQualityCriteria(),
    this.documentationQuality = const DocumentationQualityCriteria(),
    this.prioritization = const QualityPrioritization(),
    this.acceptanceCriteria = const AcceptanceCriteriaSummary(),
  });
}

/// 11.1. Quality Framework [PD00-SYQ-FRA].
class QualityFramework {
  final String? content;

  /// 11.1.1. Quality Objectives Overview [PD00-SYQ-FRA-OBJ].
  final String? qualityObjectivesOverview;

  /// 11.1.2. Quality Categories [PD00-SYQ-FRA-CAT].
  final String? qualityCategories;

  const QualityFramework({
    this.content,
    this.qualityObjectivesOverview,
    this.qualityCategories,
  });
}

/// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
class UserQualityCriteria {
  final String? content;

  /// 11.2.1. Usability [PD00-SYQ-USE-USA].
  final String? usability;

  /// 11.2.2. Functional Completeness [PD00-SYQ-USE-FUN].
  final String? functionalCompleteness;

  /// 11.2.3. Correctness [PD00-SYQ-USE-COR].
  final String? correctness;

  const UserQualityCriteria({
    this.content,
    this.usability,
    this.functionalCompleteness,
    this.correctness,
  });
}

/// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
class TechnicalQualityCriteria {
  final String? content;

  /// 11.3.1. Efficiency [PD00-SYQ-TEC-EFF].
  final String? efficiency;

  /// 11.3.2. Portability [PD00-SYQ-TEC-POR].
  final String? portability;

  /// 11.3.3. Flexibility [PD00-SYQ-TEC-FLE].
  final String? flexibility;

  /// 11.3.4. Security [PD00-SYQ-TEC-SEC].
  final String? security;

  /// 11.3.5. Maintainability [PD00-SYQ-TEC-MAI].
  final String? maintainability;

  /// 11.3.6. Reliability [PD00-SYQ-TEC-REL].
  final String? reliability;

  const TechnicalQualityCriteria({
    this.content,
    this.efficiency,
    this.portability,
    this.flexibility,
    this.security,
    this.maintainability,
    this.reliability,
  });
}

/// 11.4. Operations Quality Criteria [PD00-SYQ-OPE].
class OperationsQualityCriteria {
  final String? content;

  /// 11.4.1. Availability [PD00-SYQ-OPE-AVA].
  final String? availability;

  /// 11.4.2. Service Level Requirements [PD00-SYQ-OPE-SER].
  final String? serviceLevelRequirements;

  /// 11.4.3. Monitoring and Prevention [PD00-SYQ-OPE-MON].
  final String? monitoringAndPrevention;

  /// 11.4.4. IT Security Operations [PD00-SYQ-OPE-ITS].
  final String? itSecurityOperations;

  const OperationsQualityCriteria({
    this.content,
    this.availability,
    this.serviceLevelRequirements,
    this.monitoringAndPrevention,
    this.itSecurityOperations,
  });
}

/// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
class DocumentationQualityCriteria {
  final String? content;

  /// 11.5.1. Readability [PD00-SYQ-DOC-REA].
  final String? readability;

  /// 11.5.2. Completeness [PD00-SYQ-DOC-COM].
  final String? completeness;

  /// 11.5.3. Correctness [PD00-SYQ-DOC-COR].
  final String? correctness;

  /// 11.5.4. Changeability [PD00-SYQ-DOC-CHA].
  final String? changeability;

  const DocumentationQualityCriteria({
    this.content,
    this.readability,
    this.completeness,
    this.correctness,
    this.changeability,
  });
}

/// 11.6. Quality Prioritization [PD00-SYQ-PRI].
class QualityPrioritization {
  final String? content;

  /// 11.6.1. Weighted Quality Matrix [PD00-SYQ-PRI-WEI].
  final String? weightedQualityMatrix;

  /// 11.6.2. Trade-off Decisions [PD00-SYQ-PRI-TRA].
  final String? tradeOffDecisions;

  const QualityPrioritization({
    this.content,
    this.weightedQualityMatrix,
    this.tradeOffDecisions,
  });
}

/// 11.7. Acceptance Criteria Summary [PD00-SYQ-ACC].
class AcceptanceCriteriaSummary {
  final String? content;

  /// 11.7.1. Must-Pass Criteria [PD00-SYQ-ACC-MUS].
  final String? mustPassCriteria;

  /// 11.7.2. Quality Gate Checklist [PD00-SYQ-ACC-GAT].
  final String? qualityGateChecklist;

  const AcceptanceCriteriaSummary({
    this.content,
    this.mustPassCriteria,
    this.qualityGateChecklist,
  });
}
