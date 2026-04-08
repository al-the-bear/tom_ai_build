/// Section 13: System Stage Plan [PD00-SSP]. Seeds → PPP.
///
/// System stages are meaningful subsets of the functional system.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 13. System Stage Plan [PD00-SSP]. Seeds → PPP.
@tomReflector
class SystemStagePlan {
  final String? content;

  /// 13.1. Staging Strategy [PD00-SSP-STR].
  final StagingStrategy strategy;

  /// 13.2. Stage Overview [PD00-SSP-STA].
  final StageOverview stageOverview;

  /// 13.3. Stages [PD00-SSP-STG] — contains 1+× Stage.
  final List<StageEntry> stages;

  /// 13.4. Feature Prioritization [PD00-SSP-FEA].
  final FeaturePrioritization featurePrioritization;

  /// 13.5. Data Migration Strategy [PD00-SSP-MIG].
  final DataMigrationStrategy dataMigration;

  /// 13.6. Governance [PD00-SSP-GOV].
  final StageGovernance governance;

  const SystemStagePlan({
    this.content,
    this.strategy = const StagingStrategy(),
    this.stageOverview = const StageOverview(),
    this.stages = const [],
    this.featurePrioritization = const FeaturePrioritization(),
    this.dataMigration = const DataMigrationStrategy(),
    this.governance = const StageGovernance(),
  });
}

/// 13.1. Staging Strategy [PD00-SSP-STR].
@tomReflector
class StagingStrategy {
  final String? content;

  /// 13.1.1. Staging Approach [PD00-SSP-STR-APP].
  final String? stagingApproach;

  /// 13.1.2. Rationale [PD00-SSP-STR-RAT].
  final String? rationale;

  const StagingStrategy({
    this.content,
    this.stagingApproach,
    this.rationale,
  });
}

/// 13.2. Stage Overview [PD00-SSP-STA].
@tomReflector
class StageOverview {
  final String? content;

  /// 13.2.1. Stage Summary [PD00-SSP-STA-SUM].
  final String? stageSummary;

  /// 13.2.2. Stage Timeline Diagram [PD00-SSP-STA-DIA] (mermaid).
  final String? timelineDiagram;

  const StageOverview({
    this.content,
    this.stageSummary,
    this.timelineDiagram,
  });
}

/// A stage entry [PD00-SSP-STG-nn] (form) with description subsections.
@tomReflector
class StageEntry {
  final String? content;
  final String? stageNumber;
  final String? stageName;
  final String? targetGoLive;
  final String? scopeSummary;

  /// Feature Scope [PD00-SSP-STG-nn-FEA] (description).
  final String? featureScope;

  /// Sub-stages and Milestones [PD00-SSP-STG-nn-SUB] (description).
  final String? subStagesAndMilestones;

  /// Timeline [PD00-SSP-STG-nn-TIM] (description).
  final String? timeline;

  /// Success Criteria [PD00-SSP-STG-nn-SUC] (description).
  final String? successCriteria;

  /// Rollout Plan [PD00-SSP-STG-nn-ROL] (description).
  final String? rolloutPlan;

  const StageEntry({
    this.content,
    this.stageNumber,
    this.stageName,
    this.targetGoLive,
    this.scopeSummary,
    this.featureScope,
    this.subStagesAndMilestones,
    this.timeline,
    this.successCriteria,
    this.rolloutPlan,
  });
}

/// 13.4. Feature Prioritization [PD00-SSP-FEA].
@tomReflector
class FeaturePrioritization {
  final String? content;

  /// 13.4.1. MoSCoW Analysis [PD00-SSP-FEA-MOS].
  final String? moscowAnalysis;

  /// 13.4.2. Feature-Stage Matrix [PD00-SSP-FEA-MAT].
  final String? featureStageMatrix;

  const FeaturePrioritization({
    this.content,
    this.moscowAnalysis,
    this.featureStageMatrix,
  });
}

/// 13.5. Data Migration Strategy [PD00-SSP-MIG].
@tomReflector
class DataMigrationStrategy {
  final String? content;

  /// 13.5.1. Migration Phases [PD00-SSP-MIG-PHA].
  final String? migrationPhases;

  /// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
  final String? migrationRisks;

  const DataMigrationStrategy({
    this.content,
    this.migrationPhases,
    this.migrationRisks,
  });
}

/// 13.6. Governance [PD00-SSP-GOV].
@tomReflector
class StageGovernance {
  final String? content;

  /// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
  final String? phaseGateReviews;

  /// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
  final String? decisionPoints;

  const StageGovernance({
    this.content,
    this.phaseGateReviews,
    this.decisionPoints,
  });
}
