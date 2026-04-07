import '../common/enums.dart';

/// Section 13: System Stage Plan [PD00-SSP]. Seeds → PPP.
///
/// System stages are meaningful subsets of the functional system.
class SystemStagePlan {
  /// 13.1. Staging Strategy [PD00-SSP-STR].
  final StagingStrategy strategy;

  /// 13.2. Stage Overview [PD00-SSP-STA].
  final StageOverview stageOverview;

  /// 13.3. Stages [PD00-SSP-STG] — contains 1+× Stage.
  final List<Stage> stages;

  /// 13.4. Feature Prioritization [PD00-SSP-FEA].
  final FeaturePrioritization featurePrioritization;

  /// 13.5. Data Migration Strategy [PD00-SSP-MIG].
  final DataMigrationStrategy dataMigration;

  /// 13.6. Governance [PD00-SSP-GOV].
  final StageGovernance governance;

  const SystemStagePlan({
    this.strategy = const StagingStrategy(),
    this.stageOverview = const StageOverview(),
    this.stages = const [],
    this.featurePrioritization = const FeaturePrioritization(),
    this.dataMigration = const DataMigrationStrategy(),
    this.governance = const StageGovernance(),
  });
}

/// 13.1. Staging Strategy [PD00-SSP-STR].
class StagingStrategy {
  /// 13.1.1. Staging Approach [PD00-SSP-STR-APP].
  final StagingApproach? approach;

  /// Approach description text.
  final String? approachDescription;

  /// 13.1.2. Rationale [PD00-SSP-STR-RAT].
  final String? rationale;

  const StagingStrategy({
    this.approach,
    this.approachDescription,
    this.rationale,
  });
}

/// 13.2. Stage Overview [PD00-SSP-STA].
class StageOverview {
  /// 13.2.1. Stage Summary [PD00-SSP-STA-SUM].
  final String? stageSummary;

  /// 13.2.2. Stage Timeline Diagram [PD00-SSP-STA-DIA] (mermaid).
  final String? timelineDiagram;

  const StageOverview({
    this.stageSummary,
    this.timelineDiagram,
  });
}

/// A system stage [PD00-SSP-STG-nn].
class Stage {
  final int stageNumber;
  final String stageName;
  final String? targetGoLive;
  final String scopeSummary;

  /// Feature scope description [PD00-SSP-STG-nn-FEA].
  final String? featureScope;

  /// Sub-stages and milestones [PD00-SSP-STG-nn-SUB].
  final String? subStagesAndMilestones;

  /// Timeline [PD00-SSP-STG-nn-TIM].
  final String? timeline;

  /// Success criteria [PD00-SSP-STG-nn-SUC].
  final String? successCriteria;

  /// Rollout plan [PD00-SSP-STG-nn-ROL].
  final String? rolloutPlan;

  const Stage({
    required this.stageNumber,
    required this.stageName,
    this.targetGoLive,
    required this.scopeSummary,
    this.featureScope,
    this.subStagesAndMilestones,
    this.timeline,
    this.successCriteria,
    this.rolloutPlan,
  });
}

/// 13.4. Feature Prioritization [PD00-SSP-FEA].
class FeaturePrioritization {
  /// 13.4.1. MoSCoW Analysis [PD00-SSP-FEA-MOS].
  final String? moscowAnalysis;

  /// 13.4.2. Feature-Stage Matrix [PD00-SSP-FEA-MAT].
  final String? featureStageMatrix;

  const FeaturePrioritization({
    this.moscowAnalysis,
    this.featureStageMatrix,
  });
}

/// 13.5. Data Migration Strategy [PD00-SSP-MIG].
class DataMigrationStrategy {
  /// 13.5.1. Migration Phases [PD00-SSP-MIG-PHA].
  final String? migrationPhases;

  /// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
  final String? migrationRisks;

  const DataMigrationStrategy({
    this.migrationPhases,
    this.migrationRisks,
  });
}

/// 13.6. Governance [PD00-SSP-GOV].
class StageGovernance {
  /// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
  final String? phaseGateReviews;

  /// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
  final String? decisionPoints;

  const StageGovernance({
    this.phaseGateReviews,
    this.decisionPoints,
  });
}
