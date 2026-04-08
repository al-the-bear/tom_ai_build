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

  /// Sub-stages and Milestones [PD00-SSP-STG-nn-SUB].
  final List<SubStageEntry> subStagesAndMilestones;

  /// Timeline [PD00-SSP-STG-nn-TIM] (description).
  final String? timeline;

  /// Success Criteria [PD00-SSP-STG-nn-SUC].
  final List<StageSuccessCriterionEntry> successCriteria;

  /// Rollout Plan [PD00-SSP-STG-nn-ROL] (description).
  final String? rolloutPlan;

  const StageEntry({
    this.content,
    this.stageNumber,
    this.stageName,
    this.targetGoLive,
    this.scopeSummary,
    this.featureScope,
    this.subStagesAndMilestones = const [],
    this.timeline,
    this.successCriteria = const [],
    this.rolloutPlan,
  });
}

/// A sub-stage or milestone entry (form).
@tomReflector
class SubStageEntry {
  final String? content;
  final String? name;
  final String? description;
  final String? targetDate;

  const SubStageEntry({
    this.content,
    this.name,
    this.description,
    this.targetDate,
  });
}

/// A success criterion entry (form).
@tomReflector
class StageSuccessCriterionEntry {
  final String? content;
  final String? criterion;
  final String? measurementMethod;

  const StageSuccessCriterionEntry({
    this.content,
    this.criterion,
    this.measurementMethod,
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
  final MigrationPhases migrationPhases;

  /// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
  final StageMigrationRisks migrationRisks;

  const DataMigrationStrategy({
    this.content,
    this.migrationPhases = const MigrationPhases(),
    this.migrationRisks = const StageMigrationRisks(),
  });
}

/// 13.5.1. Migration Phases [PD00-SSP-MIG-PHA].
@tomReflector
class MigrationPhases {
  final String? content;
  final List<MigrationPhaseEntry> items;

  const MigrationPhases({this.content, this.items = const []});
}

/// A migration phase entry (form).
@tomReflector
class MigrationPhaseEntry {
  final String? content;
  final String? phaseName;
  final String? description;
  final String? dataScope;
  final String? targetStage;
  final String? verificationApproach;

  const MigrationPhaseEntry({
    this.content,
    this.phaseName,
    this.description,
    this.dataScope,
    this.targetStage,
    this.verificationApproach,
  });
}

/// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
@tomReflector
class StageMigrationRisks {
  final String? content;
  final List<StageMigrationRiskEntry> items;

  const StageMigrationRisks({this.content, this.items = const []});
}

/// A stage migration risk entry (form).
@tomReflector
class StageMigrationRiskEntry {
  final String? content;
  final String? risk;
  final String? probability;
  final String? impact;
  final String? mitigation;

  const StageMigrationRiskEntry({
    this.content,
    this.risk,
    this.probability,
    this.impact,
    this.mitigation,
  });
}

/// 13.6. Governance [PD00-SSP-GOV].
@tomReflector
class StageGovernance {
  final String? content;

  /// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
  final PhaseGateReviews phaseGateReviews;

  /// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
  final DecisionPoints decisionPoints;

  const StageGovernance({
    this.content,
    this.phaseGateReviews = const PhaseGateReviews(),
    this.decisionPoints = const DecisionPoints(),
  });
}

/// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
@tomReflector
class PhaseGateReviews {
  final String? content;
  final List<PhaseGateReviewEntry> items;

  const PhaseGateReviews({this.content, this.items = const []});
}

/// A phase gate review entry (form).
@tomReflector
class PhaseGateReviewEntry {
  final String? content;
  final String? gateName;
  final String? stage;
  final List<ReviewCriterionEntry> reviewCriteria;
  final String? decisionAuthority;

  const PhaseGateReviewEntry({
    this.content,
    this.gateName,
    this.stage,
    this.reviewCriteria = const [],
    this.decisionAuthority,
  });
}

/// A review criterion entry (form).
@tomReflector
class ReviewCriterionEntry {
  final String? content;
  final String? criterion;
  final String? description;

  const ReviewCriterionEntry({
    this.content,
    this.criterion,
    this.description,
  });
}

/// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
@tomReflector
class DecisionPoints {
  final String? content;
  final List<DecisionPointEntry> items;

  const DecisionPoints({this.content, this.items = const []});
}

/// A decision point entry (form).
@tomReflector
class DecisionPointEntry {
  final String? content;
  final String? decisionPoint;
  final String? timing;
  final String? criteria;
  final String? decisionAuthority;
  final List<DecisionOptionEntry> options;

  const DecisionPointEntry({
    this.content,
    this.decisionPoint,
    this.timing,
    this.criteria,
    this.decisionAuthority,
    this.options = const [],
  });
}

/// A decision option entry (form).
@tomReflector
class DecisionOptionEntry {
  final String? content;
  final String? option;
  final String? description;
  final String? implications;

  const DecisionOptionEntry({
    this.content,
    this.option,
    this.description,
    this.implications,
  });
}
