/// Section 13: System Stage Plan [PD00-SSP]. Seeds → PPP.
///
/// System stages are meaningful subsets of the functional system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



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
  @Form([
    Field('rationale', String, 'Rationale'),
  ])

  String? content;

  /// Staging Approach.
  TextSection stagingApproach = TextSection();

}

/// 13.2. Stage Overview [PD00-SSP-STA].
class StageOverview {
  String? content;

  /// Stage Summary.
  TextSection stageSummary = TextSection();

  /// 13.2.2. Stage Timeline Diagram [PD00-SSP-STA-DIA] (mermaid).
  GanttDiagramSection timelineDiagram = GanttDiagramSection();
}

/// A stage entry [PD00-SSP-STG-nn] (form) with description subsections.
class StageEntry {
  @Form([
    Field('stageNumber', String, 'Stage Number', required: true),
    Field('stageName', String, 'Stage Name', required: true),
    Field('targetGoLive', String, 'Target Go Live'),
    Field('scopeSummary', String, 'Scope Summary'),
  ])

  String? content;
  /// Feature Scope.
  TextSection featureScope = TextSection();

  /// Sub-stages and Milestones [PD00-SSP-STG-nn-SUB] — contains 0+× SubStage.
  List<SubStageEntry> subStagesAndMilestones = [];

  /// Timeline.
  TextSection timeline = TextSection();

  /// Success Criteria [PD00-SSP-STG-nn-SUC] — contains 0+× StageSuccessCriterion.
  List<StageSuccessCriterionEntry> successCriteria = [];

  /// Rollout Plan.
  TextSection rolloutPlan = TextSection();
}

/// A sub-stage or milestone entry (form) [PD00-SSP-STG-nn-SUB-nn].
class SubStageEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('description', String, 'Short description'),
    Field('targetDate', String, 'Target Date'),
  ])

  String? content;
}

/// A success criterion entry (form) [PD00-SSP-STG-nn-SUC-nn].
class StageSuccessCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('measurementMethod', String, 'Measurement Method'),
  ])

  String? content;
}

/// 13.4. Feature Prioritization [PD00-SSP-FEA].
class FeaturePrioritization {
  String? content;

  /// Moscow Analysis.
  TextSection moscowAnalysis = TextSection();

  /// Feature Stage Matrix.
  TextSection featureStageMatrix = TextSection();
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
  /// Contains 0+× MigrationPhase.
  List<MigrationPhaseEntry> items = [];
}

/// A migration phase entry (form) [PD00-SSP-MIG-PHA-nn].
class MigrationPhaseEntry {
  @Form([
    Field('phaseName', String, 'Phase Name', required: true),
    Field('description', String, 'Short description'),
    Field('dataScope', String, 'Data Scope'),
    Field('targetStage', String, 'Target Stage'),
    Field('verificationApproach', String, 'Verification Approach'),
  ])

  String? content;
}

/// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
class StageMigrationRisks {
  String? content;
  /// Contains 0+× StageMigrationRisk.
  List<StageMigrationRiskEntry> items = [];
}

/// A stage migration risk entry (form) [PD00-SSP-MIG-RIS-nn].
class StageMigrationRiskEntry {
  @Form([
    Field('risk', String, 'Risk'),
    Field('probability', String, 'Probability'),
    Field('impact', String, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
  ])

  String? content;
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
  /// Contains 0+× PhaseGateReview.
  List<PhaseGateReviewEntry> items = [];
}

/// A phase gate review entry (form) [PD00-SSP-GOV-GAT-nn].
class PhaseGateReviewEntry {
  @Form([
    Field('gateName', String, 'Gate Name', required: true),
    Field('stage', String, 'Stage'),
    Field('decisionAuthority', String, 'Decision Authority'),
  ])

  String? content;
  /// Contains 0+× ReviewCriterion.
  List<ReviewCriterionEntry> reviewCriteria = [];
}

/// A review criterion entry (form) [PD00-SSP-GOV-GAT-nn-RCR-nn].
class ReviewCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('description', String, 'Short description'),
  ])

  String? content;
}

/// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
class DecisionPoints {
  String? content;
  /// Contains 0+× DecisionPoint.
  List<DecisionPointEntry> items = [];
}

/// A decision point entry (form) [PD00-SSP-GOV-DEC-nn].
class DecisionPointEntry {
  @Form([
    Field('decisionPoint', String, 'Decision Point'),
    Field('timing', String, 'Timing'),
    Field('criteria', String, 'Criteria'),
    Field('decisionAuthority', String, 'Decision Authority'),
  ])

  String? content;
  /// Contains 0+× DecisionOption.
  List<DecisionOptionEntry> options = [];
}

/// A decision option entry (form) [PD00-SSP-GOV-DEC-nn-OPT-nn].
class DecisionOptionEntry {
  @Form([
    Field('option', String, 'Option'),
    Field('description', String, 'Short description'),
    Field('implications', String, 'Implications'),
  ])

  String? content;
}
