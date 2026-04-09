/// Section 13: System Stage Plan [PD00-SSP]. Seeds → PPP.
///
/// System stages are meaningful subsets of the functional system.
library;



/// 13. System Stage Plan [PD00-SSP]. Seeds → PPP.
class SystemStagePlan {
  String? content;

  /// 13.1. Staging Strategy [PD00-SSP-STR].
  StagingStrategy strategy = StagingStrategy();

  /// 13.2. Stage Overview [PD00-SSP-STA].
  StageOverview stageOverview = StageOverview();

  /// 13.3. Stages [PD00-SSP-STG] — contains 1+× Stage.
  List<StageEntry> stages = [];

  /// 13.4. Feature Prioritization [PD00-SSP-FEA].
  FeaturePrioritization featurePrioritization = FeaturePrioritization();

  /// 13.5. Data Migration Strategy [PD00-SSP-MIG].
  DataMigrationStrategy dataMigration = DataMigrationStrategy();

  /// 13.6. Governance [PD00-SSP-GOV].
  StageGovernance governance = StageGovernance();
}

/// 13.1. Staging Strategy [PD00-SSP-STR].
class StagingStrategy {
  String? content;

  /// 13.1.1. Staging Approach [PD00-SSP-STR-APP].
  String? stagingApproach;

  /// 13.1.2. Rationale [PD00-SSP-STR-RAT].
  String? rationale;
}

/// 13.2. Stage Overview [PD00-SSP-STA].
class StageOverview {
  String? content;

  /// 13.2.1. Stage Summary [PD00-SSP-STA-SUM].
  String? stageSummary;

  /// 13.2.2. Stage Timeline Diagram [PD00-SSP-STA-DIA] (mermaid).
  String? timelineDiagram;
}

/// A stage entry [PD00-SSP-STG-nn] (form) with description subsections.
class StageEntry {
  String? content;
  String? stageNumber;
  String? stageName;
  String? targetGoLive;
  String? scopeSummary;

  /// Feature Scope [PD00-SSP-STG-nn-FEA] (description).
  String? featureScope;

  /// Sub-stages and Milestones [PD00-SSP-STG-nn-SUB].
  List<SubStageEntry> subStagesAndMilestones = [];

  /// Timeline [PD00-SSP-STG-nn-TIM] (description).
  String? timeline;

  /// Success Criteria [PD00-SSP-STG-nn-SUC].
  List<StageSuccessCriterionEntry> successCriteria = [];

  /// Rollout Plan [PD00-SSP-STG-nn-ROL] (description).
  String? rolloutPlan;
}

/// A sub-stage or milestone entry (form).
class SubStageEntry {
  String? content;
  String? name;
  String? description;
  String? targetDate;
}

/// A success criterion entry (form).
class StageSuccessCriterionEntry {
  String? content;
  String? criterion;
  String? measurementMethod;
}

/// 13.4. Feature Prioritization [PD00-SSP-FEA].
class FeaturePrioritization {
  String? content;

  /// 13.4.1. MoSCoW Analysis [PD00-SSP-FEA-MOS].
  String? moscowAnalysis;

  /// 13.4.2. Feature-Stage Matrix [PD00-SSP-FEA-MAT].
  String? featureStageMatrix;
}

/// 13.5. Data Migration Strategy [PD00-SSP-MIG].
class DataMigrationStrategy {
  String? content;

  /// 13.5.1. Migration Phases [PD00-SSP-MIG-PHA].
  MigrationPhases migrationPhases = MigrationPhases();

  /// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
  StageMigrationRisks migrationRisks = StageMigrationRisks();
}

/// 13.5.1. Migration Phases [PD00-SSP-MIG-PHA].
class MigrationPhases {
  String? content;
  List<MigrationPhaseEntry> items = [];
}

/// A migration phase entry (form).
class MigrationPhaseEntry {
  String? content;
  String? phaseName;
  String? description;
  String? dataScope;
  String? targetStage;
  String? verificationApproach;
}

/// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
class StageMigrationRisks {
  String? content;
  List<StageMigrationRiskEntry> items = [];
}

/// A stage migration risk entry (form).
class StageMigrationRiskEntry {
  String? content;
  String? risk;
  String? probability;
  String? impact;
  String? mitigation;
}

/// 13.6. Governance [PD00-SSP-GOV].
class StageGovernance {
  String? content;

  /// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
  PhaseGateReviews phaseGateReviews = PhaseGateReviews();

  /// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
  DecisionPoints decisionPoints = DecisionPoints();
}

/// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
class PhaseGateReviews {
  String? content;
  List<PhaseGateReviewEntry> items = [];
}

/// A phase gate review entry (form).
class PhaseGateReviewEntry {
  String? content;
  String? gateName;
  String? stage;
  List<ReviewCriterionEntry> reviewCriteria = [];
  String? decisionAuthority;
}

/// A review criterion entry (form).
class ReviewCriterionEntry {
  String? content;
  String? criterion;
  String? description;
}

/// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
class DecisionPoints {
  String? content;
  List<DecisionPointEntry> items = [];
}

/// A decision point entry (form).
class DecisionPointEntry {
  String? content;
  String? decisionPoint;
  String? timing;
  String? criteria;
  String? decisionAuthority;
  List<DecisionOptionEntry> options = [];
}

/// A decision option entry (form).
class DecisionOptionEntry {
  String? content;
  String? option;
  String? description;
  String? implications;
}
