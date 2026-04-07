/// Section 11: System Quality Goals [PD00-SYQ]. Seeds → BQP.
///
/// Quality goals for acceptance testing, organized by quality category.
class SystemQualityGoals {
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
  final String? qualityObjectivesOverview;
  final String? qualityCategories;

  const QualityFramework({
    this.qualityObjectivesOverview,
    this.qualityCategories,
  });
}

/// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
class UserQualityCriteria {
  final String? usability;
  final String? functionalCompleteness;
  final String? correctness;

  const UserQualityCriteria({
    this.usability,
    this.functionalCompleteness,
    this.correctness,
  });
}

/// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
class TechnicalQualityCriteria {
  final String? efficiency;
  final String? portability;
  final String? flexibility;
  final String? security;
  final String? maintainability;
  final String? reliability;

  const TechnicalQualityCriteria({
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
  final String? availability;
  final String? serviceLevelRequirements;
  final String? monitoringAndPrevention;
  final String? itSecurityOperations;

  const OperationsQualityCriteria({
    this.availability,
    this.serviceLevelRequirements,
    this.monitoringAndPrevention,
    this.itSecurityOperations,
  });
}

/// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
class DocumentationQualityCriteria {
  final String? readability;
  final String? completeness;
  final String? correctness;
  final String? changeability;

  const DocumentationQualityCriteria({
    this.readability,
    this.completeness,
    this.correctness,
    this.changeability,
  });
}

/// 11.6. Quality Prioritization [PD00-SYQ-PRI].
class QualityPrioritization {
  final String? weightedQualityMatrix;
  final String? tradeOffDecisions;

  const QualityPrioritization({
    this.weightedQualityMatrix,
    this.tradeOffDecisions,
  });
}

/// 11.7. Acceptance Criteria Summary [PD00-SYQ-ACC].
class AcceptanceCriteriaSummary {
  final String? mustPassCriteria;
  final String? qualityGateChecklist;

  const AcceptanceCriteriaSummary({
    this.mustPassCriteria,
    this.qualityGateChecklist,
  });
}
