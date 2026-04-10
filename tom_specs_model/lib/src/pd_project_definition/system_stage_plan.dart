/// Section 13: System Stage Plan [PD00-SSP]. Seeds → PPP.
///
/// System stages are meaningful subsets of the functional system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 13. System Stage Plan [PD00-SSP]. Seeds → PPP.
@SectionId('PD00-SSP')
@Comment('Seeds → PPP')
class SystemStagePlan {
  @Unused()
  String? content;

  /// 13.1. Staging Strategy [PD00-SSP-STR].
  StagingStrategy strategy = StagingStrategy();

  /// 13.2. Stage Overview [PD00-SSP-STA].
  StageOverview stageOverview = StageOverview();

  /// 13.3. Stages [PD00-SSP-STG] — contains 1+× Stage.
  @SectionIdPattern('PD00-SSP-STG-xx')
  @Min(1)
  List<StageEntry> stages = [];

  /// 13.4. Feature Prioritization [PD00-SSP-FEA].
  FeaturePrioritization featurePrioritization = FeaturePrioritization();

  /// 13.5. Data Migration Strategy [PD00-SSP-MIG].
  DataMigrationStrategy dataMigration = DataMigrationStrategy();

  /// 13.6. Governance [PD00-SSP-GOV].
  StageGovernance governance = StageGovernance();
}

/// 13.1. Staging Strategy [PD00-SSP-STR].
@SectionId('PD00-SSP-STR')
class StagingStrategy {
  @Form([
    Field('rationale', String, 'Rationale'),
  ])
  String? content;

  /// Staging Approach.
  TextSection stagingApproach = TextSection();
}

/// 13.2. Stage Overview [PD00-SSP-STA].
@SectionId('PD00-SSP-STA')
class StageOverview {
  @Unused()
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
  @SectionIdPattern('PD00-SSP-STG-xx-SUB-xx')
  List<SubStageEntry> subStagesAndMilestones = [];

  /// Timeline.
  TextSection timeline = TextSection();

  /// Success Criteria [PD00-SSP-STG-nn-SUC] — contains 0+× StageSuccessCriterion.
  @SectionIdPattern('PD00-SSP-STG-xx-SUC-xx')
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
@SectionId('PD00-SSP-FEA')
class FeaturePrioritization {
  @Unused()
  String? content;

  /// Moscow Analysis.
  TextSection moscowAnalysis = TextSection();

  /// Feature Stage Matrix.
  TextSection featureStageMatrix = TextSection();
}

/// 13.5. Data Migration Strategy [PD00-SSP-MIG].
@SectionId('PD00-SSP-MIG')
class DataMigrationStrategy {
  @Unused()
  String? content;

  /// 13.5.1. Migration Phases [PD00-SSP-MIG-PHA].
  MigrationPhases migrationPhases = MigrationPhases();

  /// 13.5.2. Migration Risks [PD00-SSP-MIG-RIS].
  StageMigrationRisks migrationRisks = StageMigrationRisks();
}

/// 13.5.1. Migration Phases [PD00-SSP-MIG-PHA].
@SectionId('PD00-SSP-MIG-PHA')
class MigrationPhases {
  @Unused()
  String? content;

  /// Contains 0+× MigrationPhase.
  @SectionIdPattern('PD00-SSP-MIG-PHA-xx')
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
@SectionId('PD00-SSP-MIG-RIS')
class StageMigrationRisks {
  @Unused()
  String? content;

  /// Contains 0+× StageMigrationRisk.
  @SectionIdPattern('PD00-SSP-MIG-RIS-xx')
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
@SectionId('PD00-SSP-GOV')
class StageGovernance {
  @Unused()
  String? content;

  /// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
  PhaseGateReviews phaseGateReviews = PhaseGateReviews();

  /// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
  DecisionPoints decisionPoints = DecisionPoints();
}

/// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
@SectionId('PD00-SSP-GOV-GAT')
class PhaseGateReviews {
  @Unused()
  String? content;

  /// Contains 0+× PhaseGateReview.
  @SectionIdPattern('PD00-SSP-GOV-GAT-xx')
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
  @SectionIdPattern('PD00-SSP-GOV-GAT-xx-RCR-xx')
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
@SectionId('PD00-SSP-GOV-DEC')
class DecisionPoints {
  @Unused()
  String? content;

  /// Contains 0+× DecisionPoint.
  @SectionIdPattern('PD00-SSP-GOV-DEC-xx')
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
  @SectionIdPattern('PD00-SSP-GOV-DEC-xx-OPT-xx')
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
