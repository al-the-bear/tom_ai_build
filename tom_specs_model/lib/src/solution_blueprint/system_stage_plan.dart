/// Section 13: System Stage Plan. Seeds → PPP.
///
/// System stages are meaningful subsets of the functional system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';



/// 13. System Stage Plan. Seeds → PPP.
///
/// Define the overall staging strategy for the system rollout. A stage
/// is a meaningful, self-contained subset of the complete system that
/// delivers measurable business value. Stages build upon each other
/// progressively until the full system is operational. Aligns with
/// PMBOK phase-gate methodology, SAFe PI planning, and PRINCE2 stage
/// boundary management.
@SectionId('SSPL')
@Comment('Seeds → PPP')
@MapsTo(D11DeliveryRoadmap)
class SystemStagePlan {
  @Form([
    // --- Strategic Overview ---
    Field('totalStagesPlanned', String, 'Total Stages Planned',
        hint: 'Number of major stages in the rollout plan',
        required: true),
    Field('stagingPhilosophy', String, 'Overall Staging Philosophy',
        hint:
            'BigBang / PhasedByFunction / PhasedByGeography / '
            'PhasedByUserGroup / Incremental / Hybrid'),
    Field('parallelismApproach', String, 'Parallelism Approach',
        hint:
            'Sequential / PartialOverlap / FullyParallel — '
            'whether stages can overlap in execution'),
  ])
  String? content;

  /// Overall schedule and buffer model.
  SystemStagePlanTimeline timeline = SystemStagePlanTimeline();

  /// Dependencies, risks, and compliance constraints across stages.
  SystemStagePlanCoordination coordination = SystemStagePlanCoordination();

  /// Organizational capacity and plan confidence.
  SystemStagePlanReadiness readiness = SystemStagePlanReadiness();

  /// 13.1. Staging Strategy.
  StagingStrategy strategy = StagingStrategy();

  /// 13.2. Stage Overview.
  StageOverview stageOverview = StageOverview();

  /// 13.3. Stages — contains 1+× Stage.
  @SectionId('STAGE-STAG-LST')
  @SectionIdPattern('STAGE-STAG-xxx')
  @Min(1)
  List<StageEntry> stages = [];

  /// 13.4. Feature Prioritization.
  FeaturePrioritization featurePrioritization = FeaturePrioritization();

  /// 13.5. Data Migration Strategy.
  DataMigrationStrategy dataMigration = DataMigrationStrategy();

  /// 13.6. Governance.
  StageGovernance governance = StageGovernance();

  /// 13.7. Initial Development Flow. Covers PPP-IDV.
  InitialDevelopmentFlow initialDevelopmentFlow = InitialDevelopmentFlow();

  /// 13.8. Upgrade Cycle Framework. Covers PPP-UPG.
  UpgradeCycleFramework upgradeCycleFramework = UpgradeCycleFramework();
}

/// Overall schedule and buffer model.
@SectionId('SSPTM')
class SystemStagePlanTimeline {
    @Form([
        Field('overallPlannedStart', String, 'Overall Planned Start Date',
                hint: 'Start date of the first stage'),
        Field('overallTargetCompletion', String,
                'Overall Target Completion Date',
                hint: 'Target completion of the final stage'),
        Field('totalDuration', String, 'Total Planned Duration',
                hint: 'End-to-end duration across all stages, e.g. 18 months'),
        Field('bufferStrategy', String, 'Buffer Strategy',
                hint:
                        'How schedule buffers are allocated — PerStage / '
                        'Aggregated / CriticalChain'),
    ])
    String? content;
}

/// Dependencies, risks, and compliance constraints across stages.
@SectionId('SSPCO')
class SystemStagePlanCoordination {
    @Form([
        Field('crossStageDependencySummary', String,
                'Cross-Stage Dependency Summary',
                hint:
                        'Key dependencies between stages that affect sequencing'),
        Field('crossStageRiskSummary', String, 'Cross-Stage Risk Summary',
                hint:
                        'Top risks that span multiple stages or affect staging '
                        'order'),
        Field('regulatoryComplianceConsiderations', String,
                'Regulatory/Compliance Considerations',
                hint:
                        'Regulatory requirements affecting staging order or '
                        'timing — e.g. SOX, GDPR data readiness, PCI-DSS'),
    ])
    String? content;
}

/// Organizational capacity and plan confidence.
@SectionId('SSPRD')
class SystemStagePlanReadiness {
    @Form([
        Field('organizationalReadinessLevel', String,
                'Organizational Readiness Level',
                hint:
                        'High / Medium / Low — organization preparedness for '
                        'staged rollout'),
        Field('changeAbsorptionCapacity', String,
                'Change Absorption Capacity',
                hint:
                        'How much change the organization can absorb per '
                        'period'),
        Field('confidenceLevel', String, 'Plan Confidence Level',
                hint:
                        'High / Medium / Low — overall confidence in staging '
                        'plan feasibility'),
        Field('lastPlanReviewDate', String, 'Last Plan Review Date',
                hint: 'When the staging plan was last formally reviewed'),
    ])
    String? content;
}

/// 13.1. Staging Strategy.
///
/// Document the rationale behind the chosen staging approach. Consider
/// PMBOK phase-gate methodology, SAFe PI planning cadence, PRINCE2
/// stage boundaries, and organizational change management constraints.
/// The staging strategy addresses how the system will be deployed in
/// controlled increments, balancing risk mitigation with early value
/// delivery.
@SectionId('STAGST')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-STR')
class StagingStrategy {
  @Form([
    Field('stagingApproachType', String, 'Staging Approach Type',
        hint: 'BigBang / PhasedByFunction / PhasedByGeography / Hybrid / Pilot',
        required: true),
    Field('primaryRationale', String, 'Primary Rationale',
        hint: 'Main reason for choosing this staging approach',
        required: true),
    Field('overallRiskLevel', String, 'Overall Risk Level',
        hint: 'Low / Medium / High / Critical'),
  ])
  String? content;

  /// Approach selection details.
  StagingApproachSelection approachSelection = StagingApproachSelection();

  /// Rationale and justification.
  StagingRationale rationale = StagingRationale();

  /// Key drivers and constraints.
  @SectionId('STAGDR-DRIV-LST')
  @SectionIdPattern('STAGDR-DRIV-xxx')
  List<StagingDrivers> drivers = [];

  /// Risk assessment.
  StagingRiskAssessment riskAssessment = StagingRiskAssessment();

  /// Complexity assessment.
  StagingComplexity complexity = StagingComplexity();

  /// Readiness and resources.
  StagingReadiness readiness = StagingReadiness();

  /// Rollback and cutover strategy.
  StagingCutover cutover = StagingCutover();

  /// Success criteria and metrics.
  StagingSuccessCriteria successCriteria = StagingSuccessCriteria();

  /// Communication and change management.
  StagingCommunication communication = StagingCommunication();

  /// Framework alignment.
  StagingFrameworkAlignment frameworkAlignment = StagingFrameworkAlignment();

  /// Dependencies and prerequisites.
  @SectionId('STAGDP-DEPE-LST')
  @SectionIdPattern('STAGDP-DEPE-xxx')
  List<StagingDependencies> dependencies = [];

  /// Governance and approvals.
  StagingGovernance governance = StagingGovernance();

  /// 13.1.1. Staging Approach.
  @ContentHelp('Detailed description of the staging approach: how stages '
      'are defined, sequenced, and executed. Cover big bang vs phased '
      'rollout, geography-based vs function-based staging, pilot groups, '
      'parallel operation periods, and cutover methodologies.')
  TextSection stagingApproach = TextSection();

  /// 13.1.2. Rationale.
  @ContentHelp('Justification for the chosen staging approach: risk '
      'reduction benefits, early value delivery opportunities, resource '
      'optimization factors, alternatives considered and why rejected, '
      'alignment with organizational change capacity.')
  TextSection rationaleNarrative = TextSection();

  /// 13.1.3. Key Assumptions.
  @SectionId('KEYAS-KEYA-LST')
  @SectionIdPattern('KEYAS-KEYA-xxx')
  List<KeyAssumptionEntry> keyAssumptions = [];

  /// 13.1.4. Constraints.
  @SectionId('STAGI-CONS-LST')
  @SectionIdPattern('STAGI-CONS-xxx')
  List<StagingStrategyConstraintEntry> constraints = [];
}

/// Approach selection for staging strategy.
@SectionId('STAGAS')
class StagingApproachSelection {
  @Form([
    Field('approachDescription', String, 'Approach Description',
        hint: 'Brief description of how the staging approach will be applied'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other staging approaches evaluated and why rejected'),
    Field('selectionCriteria', String, 'Selection Criteria',
        hint: 'Criteria used to select this approach'),
  ])
  String? content;
}

/// Rationale and justification for staging strategy.
@SectionId('STAGRT')
class StagingRationale {
  @Form([
    Field('riskReductionRationale', String, 'Risk Reduction Rationale',
        hint: 'How this approach reduces project and deployment risk'),
    Field('earlyValueRationale', String, 'Early Value Rationale',
        hint: 'How this approach enables early value delivery'),
    Field('resourceOptimizationRationale', String, 'Resource Optimization Rationale',
        hint: 'How this approach optimizes resource utilization'),
    Field('businessContinuityRationale', String, 'Business Continuity Rationale',
        hint: 'How this approach ensures business operations continue'),
  ])
  String? content;
}

/// Key drivers for staging strategy.
@SectionId('STAGDR')
class StagingDrivers {
  @Form([
    Field('primaryDrivers', String, 'Primary Drivers',
        hint: 'Key factors driving the staging approach'),
    Field('businessConstraints', String, 'Business Constraints',
        hint: 'Business factors constraining staging'),
    Field('technicalConstraints', String, 'Technical Constraints',
        hint: 'Technical factors constraining staging'),
    Field('regulatoryConstraints', String, 'Regulatory Constraints',
        hint: 'Regulatory or compliance factors'),
    Field('geographicConstraints', String, 'Geographic Constraints',
        hint: 'Regional or geographic factors'),
    Field('seasonalConsiderations', String, 'Seasonal Considerations',
        hint: 'Seasonal business factors'),
  ])
  String? content;
}

/// Risk assessment for staging strategy.
@SectionId('STAGRK')
class StagingRiskAssessment {
  @Form([
    Field('riskTolerance', String, 'Risk Tolerance',
        hint: 'Low / Medium / High — acceptable level of risk'),
    Field('deploymentRiskFactors', String, 'Deployment Risk Factors',
        hint: 'Key risk factors specific to deployment'),
    Field('mitigationStrategies', String, 'Mitigation Strategies',
        hint: 'Risk mitigation strategies'),
    Field('contingencyPlans', String, 'Contingency Plans',
        hint: 'Backup plans if primary approach fails'),
    Field('rollbackTriggers', String, 'Rollback Triggers',
        hint: 'Criteria that would trigger a rollback'),
  ])
  String? content;
}

/// Complexity assessment for staging strategy.
@SectionId('STAGCX')
class StagingComplexity {
  @Form([
    Field('complexityAssessment', String, 'Complexity Assessment',
        hint: 'Low / Medium / High / VeryHigh'),
    Field('complexityFactors', String, 'Key Complexity Factors',
        hint: 'Primary sources of complexity'),
    Field('integrationComplexity', String, 'Integration Complexity',
        hint: 'Level of integration needed during staging'),
    Field('dataMigrationComplexity', String, 'Data Migration Complexity',
        hint: 'Complexity of data migration'),
    Field('userImpactComplexity', String, 'User Impact Complexity',
        hint: 'Complexity of user impact management'),
  ])
  String? content;
}

/// Readiness and resources for staging strategy.
@SectionId('STAGRD')
class StagingReadiness {
  @Form([
    Field('organizationalReadinessFactors', String, 'Organizational Readiness Factors',
        hint: 'Key readiness factors'),
    Field('organizationalReadinessLevel', String, 'Organizational Readiness Level',
        hint: 'Low / Medium / High'),
    Field('resourceConstraints', String, 'Resource Constraints',
        hint: 'Staffing, budget, or infrastructure limits'),
    Field('skillAvailability', String, 'Skill Availability',
        hint: 'Critical skills needed and their availability'),
    Field('trainingRequirements', String, 'Training Requirements',
        hint: 'Training needed per stage'),
    Field('supportCapacity', String, 'Support Capacity',
        hint: 'Support team capacity during transition'),
  ])
  String? content;
}

/// Rollback and cutover strategy for staging.
@SectionId('STAGCO')
class StagingCutover {
  @Form([
    Field('rollbackStrategyType', String, 'Rollback Strategy Type',
        hint: 'FullRollback / PartialRollback / ForwardFix / NoRollback'),
    Field('rollbackProcedure', String, 'Rollback Procedure',
        hint: 'Overview of rollback procedure'),
    Field('rollbackTimeWindow', String, 'Rollback Time Window',
        hint: 'Maximum duration for rollback after deployment'),
    Field('parallelOperationDuration', String, 'Parallel Operation Duration',
        hint: 'Expected duration of parallel system operation'),
    Field('parallelOperationStrategy', String, 'Parallel Operation Strategy',
        hint: 'How parallel systems will operate'),
    Field('cutoverMethodology', String, 'Cutover Methodology',
        hint: 'PilotThenExpand / InstantCutover / BlueGreen / Canary'),
    Field('cutoverWindowPreference', String, 'Cutover Window Preference',
        hint: 'Preferred timing for cutovers'),
    Field('cutoverDuration', String, 'Cutover Duration',
        hint: 'Expected duration of cutover activities'),
    Field('cutoverCriteria', String, 'Cutover Criteria',
        hint: 'Criteria that must be met before cutover'),
  ])
  String? content;
}

/// Success criteria for staging strategy.
@SectionId('STAGSC')
class StagingSuccessCriteria {
  @Form([
    Field('successCriteria', String, 'Success Criteria',
        hint: 'Criteria for declaring a stage successful'),
    Field('keyMetrics', String, 'Key Metrics',
        hint: 'Metrics to track during staging'),
    Field('stabilizationPeriod', String, 'Stabilization Period',
        hint: 'Time period after deployment to monitor'),
    Field('goNoGoCheckpoints', String, 'Go/No-Go Checkpoints',
        hint: 'Key decision points before each stage'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Formal acceptance criteria for stage completion'),
  ])
  String? content;
}

/// Communication and change management for staging.
@SectionId('STAGCM')
class StagingCommunication {
  @Form([
    Field('communicationStrategyOverview', String, 'Communication Strategy Overview',
        hint: 'How staging progress will be communicated'),
    Field('communicationChannels', String, 'Communication Channels',
        hint: 'Channels for communication'),
    Field('communicationCadence', String, 'Communication Cadence',
        hint: 'Frequency of communications'),
    Field('changeManagementAlignment', String, 'Change Management Alignment',
        hint: 'How staging aligns with change management plan'),
    Field('changeChampions', String, 'Change Champions',
        hint: 'Roles who will champion the change'),
    Field('feedbackMechanisms', String, 'Feedback Mechanisms',
        hint: 'How user feedback will be collected'),
  ])
  String? content;
}

/// Framework alignment for staging strategy.
@SectionId('STAGFA')
class StagingFrameworkAlignment {
  @Form([
    Field('pmMethodologyAlignment', String, 'PM Methodology Alignment',
        hint: 'PMBOK / PRINCE2 / SAFe / Scrum / Hybrid'),
    Field('piCadence', String, 'PI Planning Cadence',
        hint: 'SAFe Program Increment cadence if applicable'),
    Field('stageBoundaryApproach', String, 'Stage Boundary Approach',
        hint: 'PRINCE2 stage boundary management'),
    Field('iterationCadence', String, 'Iteration Cadence',
        hint: 'Iteration or sprint cadence within stages'),
    Field('releaseTrainCadence', String, 'Release Train Cadence',
        hint: 'SAFe release train cadence if applicable'),
  ])
  String? content;
}

/// Dependencies for staging strategy.
@SectionId('STAGDP')
class StagingDependencies {
  @Form([
    Field('criticalPrerequisites', String, 'Critical Prerequisites',
        hint: 'Prerequisites before staged deployment can begin'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'Dependencies on external parties'),
    Field('internalDependencies', String, 'Internal Dependencies',
        hint: 'Dependencies on internal projects or teams'),
    Field('dependencyRisks', String, 'Dependency Risks',
        hint: 'Risks associated with dependencies'),
  ])
  String? content;
}

/// Governance for staging strategy.
@SectionId('STAGGV')
class StagingGovernance {
  @Form([
    Field('governanceApproach', String, 'Governance Approach',
        hint: 'How staging decisions will be governed'),
    Field('approvalAuthority', String, 'Approval Authority',
        hint: 'Who has authority to approve stage transitions'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation path for issues and decisions'),
    Field('exceptionHandling', String, 'Exception Handling',
        hint: 'How exceptions to the staging plan will be handled'),
  ])
  String? content;
}

/// 13.2. Stage Overview.
///
/// High-level summary across all planned stages including aggregate
/// metrics, critical-path identification, resource allocation patterns,
/// budget distribution, schedule analytics, quality targets, risk
/// profile, and plan health. Draws from PMBOK phase-gate discipline,
/// SAFe PI planning cadence, PRINCE2 stage boundary management, and
/// TOGAF architecture road-mapping.
@SectionId('STAGOV')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-STA')
class StageOverview {
  @Form([
    Field('numberOfStages', String, 'Number of Stages',
        hint: 'Total number of major stages in the plan, e.g. 4',
        required: true),
    Field('totalDurationMonths', String, 'Total Duration',
        hint:
            'End-to-end planned duration from first stage start '
            'to last stage completion, e.g. 18 months'),
    Field('totalBudgetAllocation', String, 'Total Budget Allocation',
        hint:
            'Aggregate budget across all stages including '
            'contingency, e.g. EUR 2.4M'),
  ])
  String? content;

  /// Summary metrics across all stages.
  StageOverviewMetrics metrics = StageOverviewMetrics();

  /// Planning baseline and revision history.
  StageOverviewBaseline baseline = StageOverviewBaseline();

  /// Cross-stage dependencies and critical path.
  StageOverviewDependencies dependencies = StageOverviewDependencies();

  /// Resource allocation patterns.
  StageOverviewResources resources = StageOverviewResources();

  /// Budget distribution across stages.
  StageOverviewBudget budget = StageOverviewBudget();

  /// Schedule analytics and float.
  StageOverviewSchedule schedule = StageOverviewSchedule();

  /// Quality and compliance targets.
  StageOverviewQuality quality = StageOverviewQuality();

  /// Risk profile summary.
  StageOverviewRisk risk = StageOverviewRisk();

  /// Plan status and health indicators.
  StageOverviewStatus status = StageOverviewStatus();

  /// Stakeholder communication approach.
  StageOverviewCommunication communication = StageOverviewCommunication();

  /// Assumptions and constraints.
  StageOverviewConstraints constraints = StageOverviewConstraints();

  /// 13.2.1. Stage Summary — contains 1+× Stage
  /// Summary Entry.
  @SectionId('STAGSE-STAG-LST')
  @SectionIdPattern('STAGSE-STAG-xxx')
  @Min(1)
  List<StageSummaryEntry> stageSummaries = [];

  /// Stage Summary narrative.
  @ContentHelp('Free-text overview complementing the structured stage '
      'summaries: overall staging philosophy, key milestones across stages, '
      'critical path highlights, aggregate risk profile, '
      'resource allocation patterns, and major dependencies.')
  TextSection stageSummaryNarrative = TextSection();

  /// 13.2.2. Stage Timeline Diagram (mermaid-gantt).
  @ContentHelp('Gantt chart showing all stages with start/end dates, '
      'milestones, parallel activities, critical path, buffer allocations, '
      'and key decision points. Show dependencies between stages.')
  GanttDiagramSection timelineDiagram = GanttDiagramSection();

  /// 13.2.3. Resource Allocation Diagram
  /// (mermaid-gantt).
  @ContentHelp('Gantt-style resource allocation across stages: '
      'team assignments, role transitions, ramp-up/ramp-down periods, '
      'shared resources, external consultants, training periods.')
  GanttDiagramSection resourceAllocationDiagram = GanttDiagramSection();

  /// 13.2.4. Budget Distribution Diagram
  /// (mermaid-flow).
  @ContentHelp('Visual budget distribution: percentage per stage, '
      'capital vs operational split, contingency allocation, '
      'major cost drivers per stage, cumulative spend curve.')
  FlowDiagramSection budgetDistributionDiagram = FlowDiagramSection();

  /// 13.2.5. Dependency Map (mermaid-flow).
  @ContentHelp('Visual map of cross-stage dependencies and critical paths: '
      'mandatory sequencing, shared resources, data dependencies, '
      'integration touchpoints, and external milestones.')
  FlowDiagramSection dependencyMap = FlowDiagramSection();
}

/// Summary metrics for stage overview.
@SectionId('SGOVM')
class StageOverviewMetrics {
  @Form([
    Field('totalFeaturesPlanned', String, 'Total Features Planned',
        hint:
            'Total number of features or capabilities across all '
            'stages, e.g. 87 features'),
    Field('totalEpicsPlanned', String, 'Total Epics Planned',
        hint:
            'Total number of epics or major work packages '
            'across all stages'),
    Field('totalStoriesEstimated', String, 'Total Stories Estimated',
        hint:
            'Total user stories or work items estimated '
            'across all stages'),
    Field('totalEffortPersonMonths', String,
        'Total Effort (Person-Months)',
        hint:
            'Aggregate effort across all stages in person-months, '
            'e.g. 240 person-months'),
    Field('averageStageDuration', String, 'Average Stage Duration',
        hint: 'Average duration of a single stage, e.g. 4.5 months'),
    Field('shortestStageDuration', String, 'Shortest Stage Duration',
        hint: 'Duration of the shortest stage and which stage it is'),
    Field('longestStageDuration', String, 'Longest Stage Duration',
        hint: 'Duration of the longest stage and which stage it is'),
  ])
  String? content;
}

/// Planning baseline for stage overview.
@SectionId('SGOVBS')
class StageOverviewBaseline {
  @Form([
    Field('baselineVersion', String, 'Baseline Version',
        hint: 'Version identifier of the current baseline plan, e.g. v2.1'),
    Field('baselineApprovalDate', String, 'Baseline Approval Date',
        hint: 'Date the current baseline was formally approved, e.g. 2026-03-15'),
    Field('baselineApprovedBy', String, 'Baseline Approved By',
        hint: 'Name or role of the person/board who approved the baseline'),
    Field('plannedStartDate', String, 'Planned Start Date',
        hint: 'Overall programme start date from baseline, e.g. 2026-04-01'),
    Field('plannedEndDate', String, 'Planned End Date',
        hint: 'Overall programme end date from baseline, e.g. 2027-09-30'),
    Field('lastPlanRevisionDate', String, 'Last Plan Revision Date',
        hint: 'Date the staging plan was last revised, e.g. 2026-06-01'),
    Field('revisionCount', String, 'Revision Count',
        hint: 'Number of baseline revisions since initial approval'),
    Field('nextScheduledReview', String, 'Next Scheduled Review',
        hint: 'Date of the next formal plan review, e.g. 2026-07-15'),
  ])
  String? content;
}

/// Cross-stage dependencies for stage overview.
@SectionId('SGOVDP')
class StageOverviewDependencies {
  @Form([
    Field('criticalPathSummary', String, 'Critical Path Summary',
        hint: 'Key activities on the critical path that determine overall duration'),
    Field('criticalPathLength', String, 'Critical Path Length',
        hint: 'Duration of the critical path in weeks/months, e.g. 14 months'),
    Field('crossStageDependencyCount', String, 'Cross-Stage Dependency Count',
        hint: 'Total number of dependencies between stages, e.g. 12 dependencies'),
    Field('highRiskDependencies', String, 'High-Risk Dependencies',
        hint: 'Cross-stage dependencies with highest risk of delay'),
    Field('externalDependencyCount', String, 'External Dependency Count',
        hint: 'Number of dependencies on external parties'),
    Field('longestLeadTimeItem', String, 'Longest Lead-Time Item',
        hint: 'Activity or procurement with the longest lead time across all stages'),
    Field('interStagebufferDays', String, 'Inter-Stage Buffer (Days)',
        hint: 'Average buffer time between consecutive stages, e.g. 10 working days'),
  ])
  String? content;
}

/// Resource allocation for stage overview.
@SectionId('SGOVRS')
class StageOverviewResources {
  @Form([
    Field('peakTeamSize', String, 'Peak Team Size',
        hint: 'Maximum team size across all stages, e.g. 24 FTEs'),
    Field('minimumTeamSize', String, 'Minimum Team Size',
        hint: 'Minimum team size during any stage, e.g. 8 FTEs'),
    Field('averageTeamSize', String, 'Average Team Size',
        hint: 'Average team size weighted by stage duration'),
    Field('resourceAllocationPattern', String, 'Resource Allocation Pattern',
        hint: 'FrontLoaded / EvenlyDistributed / BackLoaded / BellCurve'),
    Field('internalResourcePercent', String, 'Internal Resource Percentage',
        hint: 'Percentage of effort from internal staff vs external contractors'),
    Field('keyRolesRequired', String, 'Key Roles Required',
        hint: 'Critical roles needed across stages'),
    Field('sharedResourceConflicts', String, 'Shared Resource Conflicts',
        hint: 'Key resources shared across stages that may cause contention'),
    Field('resourceOnboardingLeadTime', String, 'Resource Onboarding Lead Time',
        hint: 'Average time needed to onboard new team members, e.g. 2-3 weeks'),
  ])
  String? content;
}

/// Budget distribution for stage overview.
@SectionId('SGOVBD')
class StageOverviewBudget {
  @Form([
    Field('budgetDistributionPattern', String, 'Budget Distribution Pattern',
        hint: 'FrontLoaded / EvenlyDistributed / BackLoaded'),
    Field('contingencyReservePercent', String, 'Contingency Reserve Percentage',
        hint: 'Percentage of total budget reserved for contingency, e.g. 15%'),
    Field('contingencyReserveAmount', String, 'Contingency Reserve Amount',
        hint: 'Absolute contingency amount, e.g. EUR 360K'),
    Field('managementReservePercent', String, 'Management Reserve Percentage',
        hint: 'Percentage held back as management reserve for unknown risks'),
    Field('expectedBurnRatePerMonth', String, 'Expected Burn Rate Per Month',
        hint: 'Average monthly expenditure, e.g. EUR 130K/month'),
    Field('peakBurnRateMonth', String, 'Peak Burn Rate Month',
        hint: 'Month with highest expenditure and which stage drives it'),
    Field('capitalVsOperationalSplit', String, 'Capital vs Operational Split',
        hint: 'Ratio of capital to operational expenditure, e.g. 60% CAPEX / 40% OPEX'),
  ])
  String? content;
}

/// Schedule analytics for stage overview.
@SectionId('SGOVSC')
class StageOverviewSchedule {
  @Form([
    Field('totalFloatDays', String, 'Total Float (Days)',
        hint: 'Total float available across the project, e.g. 30 days'),
    Field('freeFloatDistribution', String, 'Free Float Distribution',
        hint: 'How free float is distributed across stages'),
    Field('scheduleCompressionOptions', String, 'Schedule Compression Options',
        hint: 'Crashing / FastTracking / ScopeReduction'),
    Field('scheduleCompressionLimit', String, 'Schedule Compression Limit',
        hint: 'Maximum compression possible without unacceptable risk'),
    Field('bufferAllocationPolicy', String, 'Buffer Allocation Policy',
        hint: 'How buffers are allocated — per-stage / project-level / critical-chain'),
    Field('milestoneCount', String, 'Milestone Count',
        hint: 'Total number of key milestones across all stages'),
  ])
  String? content;
}

/// Quality and compliance targets for stage overview.
@SectionId('STOVQU')
class StageOverviewQuality {
  @Form([
    Field('aggregateQualityTarget', String, 'Aggregate Quality Target',
        hint: 'Overall quality target — defect density, test coverage, pass rate'),
    Field('complianceMilestoneCount', String, 'Compliance Milestone Count',
        hint: 'Number of regulatory or compliance milestones across all stages'),
    Field('auditPointCount', String, 'Audit Point Count',
        hint: 'Number of planned audit checkpoints, e.g. 6 audits'),
    Field('qualityGateCount', String, 'Quality Gate Count',
        hint: 'Total number of quality gates across all stages'),
    Field('regressionTestingApproach', String, 'Regression Testing Approach',
        hint: 'How regression testing is managed across stages'),
  ])
  String? content;
}

/// Risk profile for stage overview.
@SectionId('STOVRI')
class StageOverviewRisk {
  @Form([
    Field('overallScheduleRisk', String, 'Overall Schedule Risk',
        hint: 'Low / Medium / High / Critical — aggregate schedule risk'),
    Field('overallBudgetRisk', String, 'Overall Budget Risk',
        hint: 'Low / Medium / High / Critical — aggregate budget overrun risk'),
    Field('overallScopeRisk', String, 'Overall Scope Risk',
        hint: 'Low / Medium / High / Critical — risk of scope creep'),
    Field('stageWithHighestRisk', String, 'Stage with Highest Risk',
        hint: 'Which stage carries the most risk and why'),
    Field('riskMitigationInvestment', String, 'Risk Mitigation Investment',
        hint: 'Budget allocated to risk mitigation activities, e.g. EUR 200K'),
    Field('topThreeRisks', String, 'Top Three Risks',
        hint: 'Three most significant risks to the overall staging plan'),
    Field('riskReviewCadence', String, 'Risk Review Cadence',
        hint: 'How often risks are formally reviewed'),
  ])
  String? content;
}

/// Plan status and health for stage overview.
@SectionId('STOVST')
class StageOverviewStatus {
  @Form([
    Field('overallPlanStatus', String, 'Overall Plan Status',
        hint: 'Green / Amber / Red — traffic-light status'),
    Field('scheduleVariancePercent', String, 'Schedule Variance Percentage',
        hint: 'Current schedule variance vs baseline, e.g. +5% behind'),
    Field('budgetVariancePercent', String, 'Budget Variance Percentage',
        hint: 'Current budget variance vs baseline, e.g. +3% over budget'),
    Field('scopeCompletionPercent', String, 'Scope Completion Percentage',
        hint: 'Overall scope completion across all stages, e.g. 35% complete'),
    Field('earnedValueCPI', String, 'Earned Value CPI',
        hint: 'Cost Performance Index — ratio of earned value to actual cost'),
    Field('earnedValueSPI', String, 'Earned Value SPI',
        hint: 'Schedule Performance Index — ratio of earned value to planned value'),
    Field('planConfidenceLevel', String, 'Plan Confidence Level',
        hint: 'High / Medium / Low — confidence in the overall timeline and budget'),
    Field('confidenceBasis', String, 'Confidence Basis',
        hint: 'Basis for confidence level — analogous / expert / parametric / Monte Carlo'),
  ])
  String? content;
}

/// Stakeholder communication for stage overview.
@SectionId('STOVCO')
class StageOverviewCommunication {
  @Form([
    Field('reportingCadence', String, 'Reporting Cadence',
        hint: 'How often stage plan progress is reported'),
    Field('primaryReportingAudience', String, 'Primary Reporting Audience',
        hint: 'Primary audience for stage plan reports'),
    Field('escalationThreshold', String, 'Escalation Threshold',
        hint: 'When variances require escalation'),
    Field('dashboardAvailability', String, 'Dashboard Availability',
        hint: 'Where the live plan status is available'),
  ])
  String? content;
}

/// Assumptions and constraints for stage overview.
@SectionId('STOVC1')
class StageOverviewConstraints {
  @Form([
    Field('keyPlanningAssumptions', String, 'Key Planning Assumptions',
        hint: 'Top assumptions the staging plan relies on'),
    Field('externalConstraints', String, 'External Constraints',
        hint: 'Constraints imposed by external factors'),
    Field('internalConstraints', String, 'Internal Constraints',
        hint: 'Internal organizational constraints'),
    Field('stageOverlapPolicy', String, 'Stage Overlap Policy',
        hint: 'NoOverlap / MinimalOverlap / AggressiveOverlap'),
    Field('stageOverlapMaxPercent', String, 'Stage Overlap Max Percentage',
        hint: 'Maximum allowed overlap between consecutive stages, e.g. 20%'),
  ])
  String? content;
}

/// A stage summary entry (form).
///
/// Quick-reference record for a single stage within the overview. Each
/// entry captures the essential identification, timeline, scope, and
/// status of a stage to enable at-a-glance comparison across the full
/// staging plan. This is the high-level summary — detailed stage
/// information is captured in the individual StageEntry classes under
/// section 13.3.
@SectionId('STAGSE')
class StageSummaryEntry {
  @Form([
    Field('stageNumber', String, 'Stage Number',
        hint: '1, 2, 3… — sequential stage number', required: true),
    Field('stageName', String, 'Stage Name',
        hint: 'Descriptive name, e.g. Foundation / Core Operations',
        required: true),
    Field('scopeSummary', String, 'Scope Summary',
        hint: 'One-line summary of what this stage delivers', required: true),
  ])
  String? content;

  /// Identity and theme.
  StageSummaryIdentity identity = StageSummaryIdentity();

  /// Timeline.
  StageSummaryTimeline timeline = StageSummaryTimeline();

  /// Scope.
  StageSummaryScope scope = StageSummaryScope();

  /// Resources and budget.
  @SectionId('STSURE-RESO-LST')
  @SectionIdPattern('STSURE-RESO-xxx')
  List<StageSummaryResources> resources = [];

  /// Dependencies and risks.
  @SectionId('STSUDE-DEPE-LST')
  @SectionIdPattern('STSUDE-DEPE-xxx')
  List<StageSummaryDependencies> dependencies = [];

  /// Quality and acceptance.
  StageSummaryQuality quality = StageSummaryQuality();

  /// Status.
  StageSummaryStatus status = StageSummaryStatus();
}

/// Identity for stage summary.
@SectionId('STSUID')
class StageSummaryIdentity {
  @Form([
    Field('stageCodename', String, 'Stage Codename',
        hint: 'Optional internal codename'),
    Field('stageTheme', String, 'Stage Theme',
        hint: 'High-level theme — Infrastructure / CoreBusiness'),
  ])
  String? content;
}

/// Timeline for stage summary.
@SectionId('STSUTI')
class StageSummaryTimeline {
  @Form([
    Field('plannedStartDate', String, 'Planned Start Date',
        hint: 'Planned start date, e.g. 2026-04-01', required: true),
    Field('plannedEndDate', String, 'Planned End Date',
        hint: 'Planned end date, e.g. 2026-07-31', required: true),
    Field('durationWeeks', String, 'Duration (Weeks)',
        hint: 'Planned duration in weeks'),
    Field('bufferWeeks', String, 'Buffer (Weeks)',
        hint: 'Buffer time included at end'),
    Field('overlapWithPrevious', String, 'Overlap with Previous Stage',
        hint: 'Duration of overlap with preceding stage'),
  ])
  String? content;
}

/// Scope for stage summary.
@SectionId('STSUSC')
class StageSummaryScope {
  @Form([
    Field('featureCount', String, 'Feature Count',
        hint: 'Number of features delivered'),
    Field('epicCount', String, 'Epic Count',
        hint: 'Number of epics or major work packages'),
    Field('storyPointEstimate', String, 'Story Point Estimate',
        hint: 'Total estimated story points'),
    Field('keyDeliverables', String, 'Key Deliverables',
        hint: 'Top 3-5 deliverables — comma-separated'),
    Field('outOfScopeItems', String, 'Out of Scope Items',
        hint: 'Key items excluded from this stage'),
  ])
  String? content;
}

/// Resources for stage summary.
@SectionId('STSURE')
class StageSummaryResources {
  @Form([
    Field('teamSize', String, 'Team Size',
        hint: 'Number of team members, e.g. 12 FTEs'),
    Field('keyRoles', String, 'Key Roles',
        hint: 'Critical roles — architect, UX designer, backend lead'),
    Field('estimatedBudget', String, 'Estimated Budget',
        hint: 'Budget for this stage, e.g. EUR 600K'),
    Field('budgetPercentOfTotal', String, 'Budget Percentage of Total',
        hint: 'Stage budget as percentage of total'),
    Field('externalCostPercent', String, 'External Cost Percentage',
        hint: 'Percentage going to external vendors'),
  ])
  String? content;
}

/// Dependencies for stage summary.
@SectionId('STSUDE')
class StageSummaryDependencies {
  @Form([
    Field('predecessorStages', String, 'Predecessor Stages',
        hint: 'Stages that must complete before this one'),
    Field('successorStages', String, 'Successor Stages',
        hint: 'Stages that depend on this one'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'External factors this stage depends on'),
    Field('primaryRisk', String, 'Primary Risk',
        hint: 'Single biggest risk for this stage'),
    Field('riskLevel', String, 'Risk Level',
        hint: 'Low / Medium / High / Critical'),
  ])
  String? content;
}

/// Quality for stage summary.
@SectionId('STSUQU')
class StageSummaryQuality {
  @Form([
    Field('qualityTarget', String, 'Quality Target',
        hint: 'Specific quality target — defect density, test pass rate'),
    Field('acceptanceCriteriaCount', String, 'Acceptance Criteria Count',
        hint: 'Number of formal acceptance criteria'),
    Field('gateReviewType', String, 'Gate Review Type',
        hint: 'Formal / Informal / Automated'),
  ])
  String? content;
}

/// Status for stage summary.
@SectionId('STSUST')
class StageSummaryStatus {
  @Form([
    Field('currentStatus', String, 'Current Status',
        hint: 'NotStarted / InPlanning / InProgress / Completed'),
    Field('percentComplete', String, 'Percent Complete',
        hint: 'Completion percentage'),
    Field('statusComment', String, 'Status Comment',
        hint: 'Brief comment on current status'),
    Field('trafficLightStatus', String, 'Traffic Light Status',
        hint: 'Green / Amber / Red'),
  ])
  String? content;
}

/// A stage entry (form) with description subsections.
///
/// Represents a single delivery stage — a self-contained increment of the
/// system that delivers measurable business value. Each stage has clear
/// entry/exit criteria, assigned resources, quality gates, and a
/// deployment plan. Draws from PMBOK phase-gate discipline, SAFe PI
/// planning, and PRINCE2 stage boundary management.
@SectionId('STAGE')
class StageEntry {
  @Form([
    Field('stageNumber', String, 'Stage Number',
        hint: '1, 2, 3… — sequential stage number',
        required: true),
    Field('stageName', String, 'Stage Name',
        hint: 'Descriptive name, e.g. Foundation, Core Operations',
        required: true),
    Field('currentStatus', String, 'Current Status',
        hint: 'Planned / Active / Completed / OnHold / Cancelled'),
  ])
  String? content;

  /// Identity and classification.
  StageIdentity identity = StageIdentity();

  /// Timeline and schedule.
  StageTimeline timeline = StageTimeline();

  /// Scope and features.
  StageScope scope = StageScope();

  /// Dependencies.
  @SectionId('STDE-DEPE-LST')
  @SectionIdPattern('STDE-DEPE-xxx')
  List<StageDependencies> dependencies = [];

  /// Resources and budget.
  @SectionId('STRE-RESO-LST')
  @SectionIdPattern('STRE-RESO-xxx')
  List<StageResources> resources = [];

  /// Quality and governance.
  StageQuality quality = StageQuality();

  /// Deployment and rollout.
  StageDeployment deployment = StageDeployment();

  /// Stakeholders and communication.
  @SectionId('STST-STAK-LST')
  @SectionIdPattern('STST-STAK-xxx')
  List<StageStakeholders> stakeholders = [];

  /// Risk.
  StageRisk risk = StageRisk();

  /// Status and metrics.
  StageMetrics metrics = StageMetrics();

  /// Feature Scope narrative.
  @ContentHelp('Detailed feature scope for this stage: what is included '
      'and explicitly excluded, minimum viable scope, dependencies on '
      'prior stages, features deferred to future stages, acceptance '
      'criteria for scope completeness.')
  TextSection featureScope = TextSection();

  /// Sub-stages and Milestones — contains 0+× SubStage.
  @SectionId('SUSST-SUBS-LST')
  @SectionIdPattern('SUSST-SUBS-xxx')
  List<SubStageEntry> subStagesAndMilestones = [];

  /// Timeline narrative.
  @ContentHelp('Stage timeline details: key milestones, buffer allocation, '
      'critical path activities, dependencies on other stages, '
      'schedule risks, compression options, and go/no-go checkpoints.')
  TextSection timelineNarrative = TextSection();

  /// Success Criteria — contains 0+× StageSuccessCriterion.
  @SectionId('STGSUC-SUCC-LST')
  @SectionIdPattern('STGSUC-SUCC-xxx')
  List<StageSuccessCriterionEntry> successCriteria = [];

  /// Rollout Plan narrative.
  @ContentHelp('Stage rollout approach: user migration strategy, '
      'data cutover procedure, parallel operation period, '
      'rollback triggers and procedures, hypercare support model, '
      'communication plan, and user training schedule.')
  TextSection rolloutPlan = TextSection();
}

/// Identity and classification for a stage entry.
@SectionId('STID')
class StageIdentity {
  @Form([
    Field('stageCodename', String, 'Codename',
        hint: 'Optional internal codename, e.g. Atlas, Phoenix'),
    Field('stageDescription', String, 'Description',
        hint: 'Brief description of what this stage delivers'),
    Field('businessObjective', String, 'Business Objective',
        hint: 'Primary business outcome this stage achieves'),
    Field('stageType', String, 'Stage Type',
        hint: 'Foundation / Incremental / Enhancement / Optimization / Migration'),
  ])
  String? content;
}

/// Timeline and schedule for a stage entry.
@SectionId('STTI')
class StageTimeline {
  @Form([
    Field('plannedStartDate', String, 'Planned Start Date',
        required: true),
    Field('plannedEndDate', String, 'Planned End Date',
        required: true),
    Field('targetGoLiveDate', String, 'Target Go-Live Date',
        hint: 'Date when stage deliverables go live',
        required: true),
    Field('actualStartDate', String, 'Actual Start Date',
        hint: 'Populated when stage begins'),
    Field('actualEndDate', String, 'Actual End Date',
        hint: 'Populated when stage completes'),
    Field('durationPlanned', String, 'Planned Duration',
        hint: 'e.g. 12 weeks, 3 months'),
    Field('bufferDays', String, 'Buffer Days',
        hint: 'Schedule buffer allocated to this stage'),
    Field('leadTimeDays', String, 'Lead Time',
        hint: 'Required lead time before stage can begin'),
    Field('freezePeriods', String, 'Freeze Periods',
        hint: 'Periods during which no changes can be deployed'),
  ])
  String? content;
}

/// Scope and features for a stage entry.
@SectionId('STSC')
class StageScope {
  @Form([
    Field('scopeSummary', String, 'Scope Summary',
        hint: 'High-level summary of features included in this stage'),
    Field('includedFeatures', String, 'Included Features',
        hint: 'Key features explicitly included'),
    Field('excludedDeferred', String, 'Excluded/Deferred Items',
        hint: 'Features explicitly excluded and deferred'),
    Field('mvpScope', String, 'MVP Scope',
        hint: 'Minimum viable scope if schedule compression is needed'),
    Field('stretchGoals', String, 'Stretch Goals',
        hint: 'Additional scope if the stage runs ahead of schedule'),
    Field('featureCount', String, 'Feature Count',
        hint: 'Number of features or user stories in this stage'),
    Field('storyPointEstimate', String, 'Story Point Estimate',
        hint: 'Total estimated effort in story points'),
    Field('technicalDebtItems', String, 'Technical Debt Items',
        hint: 'Known technical debt to be addressed'),
  ])
  String? content;
}

/// Dependencies for a stage entry.
@SectionId('STDE')
class StageDependencies {
  @Form([
    Field('prerequisiteStages', String, 'Prerequisite Stages',
        hint: 'Stages that must complete before this stage can start'),
    Field('parallelStages', String, 'Parallel Stages',
        hint: 'Stages running concurrently with this stage'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'Dependencies on external systems, vendors, or approvals'),
    Field('blockingRisks', String, 'Blocking Risks',
        hint: 'Risks that could block stage start or completion'),
  ])
  String? content;
}

/// Resources and budget for a stage entry.
@SectionId('STRE')
class StageResources {
  @Form([
    Field('teamSize', String, 'Team Size',
        hint: 'Number of team members allocated'),
    Field('keyRoles', String, 'Key Roles Required',
        hint: 'Critical roles needed'),
    Field('budgetAllocation', String, 'Budget Allocation',
        hint: 'Budget allocated to this stage'),
    Field('infrastructureNeeds', String, 'Infrastructure Needs',
        hint: 'Environments, servers, cloud resources needed'),
    Field('toolingRequirements', String, 'Tooling Requirements',
        hint: 'Software licenses or third-party services needed'),
  ])
  String? content;
}

/// Quality and governance for a stage entry.
@SectionId('STQU')
class StageQuality {
  @Form([
    Field('entryCriteria', String, 'Entry Criteria',
        hint: 'Conditions that must be met before the stage can begin'),
    Field('exitCriteria', String, 'Exit Criteria',
        hint: 'Conditions that must be met for stage completion'),
    Field('qualityGates', String, 'Quality Gates',
        hint: 'Formal checkpoints within the stage'),
    Field('testingStrategy', String, 'Testing Strategy',
        hint: 'Testing approach for this stage'),
    Field('acceptanceCriteriaSummary', String, 'Acceptance Criteria Summary',
        hint: 'High-level criteria for business acceptance'),
    Field('toleranceLevels', String, 'Tolerance Levels',
        hint: 'PRINCE2 tolerances — time, cost, scope, quality'),
  ])
  String? content;
}

/// Deployment and rollout for a stage entry.
@SectionId('STDE1')
class StageDeployment {
  @Form([
    Field('deploymentApproach', String, 'Deployment Approach',
        hint: 'BlueGreen / Canary / RollingUpdate / BigBang'),
    Field('rollbackPlan', String, 'Rollback Plan',
        hint: 'Strategy if deployment fails'),
    Field('rollbackTriggers', String, 'Rollback Triggers',
        hint: 'Conditions that trigger a rollback'),
    Field('parallelOperationPeriod', String, 'Parallel Operation Period',
        hint: 'Duration of old and new system running in parallel'),
    Field('dataMigrationScope', String, 'Data Migration Scope',
        hint: 'Data entities and volumes to be migrated'),
    Field('cutoverPlanSummary', String, 'Cutover Plan Summary',
        hint: 'Key steps for switching from old to new system'),
    Field('hypercarePeriod', String, 'Hypercare Period',
        hint: 'Duration of intensive post-go-live support'),
  ])
  String? content;
}

/// Stakeholders and communication for a stage entry.
@SectionId('STST')
class StageStakeholders {
  @Form([
    Field('stageOwner', String, 'Stage Owner',
        hint: 'Person accountable for stage delivery'),
    Field('businessSponsor', String, 'Business Sponsor',
        hint: 'Business stakeholder sponsoring this stage'),
    Field('technicalLead', String, 'Technical Lead',
        hint: 'Technical authority for this stage'),
    Field('qaLead', String, 'QA Lead',
        hint: 'Quality assurance lead'),
    Field('changeManager', String, 'Change Manager',
        hint: 'Person managing organizational change'),
    Field('announcementPlan', String, 'Announcement Plan',
        hint: 'How and when go-live will be communicated'),
    Field('trainingRequirements', String, 'Training Requirements',
        hint: 'Training needed for end users and support staff'),
    Field('documentationUpdates', String, 'Documentation Updates',
        hint: 'User guides, runbooks, SOPs requiring updates'),
  ])
  String? content;
}

/// Risk for a stage entry.
@SectionId('STRI')
class StageRisk {
  @Form([
    Field('topRisks', String, 'Top Risks',
        hint: 'Key risks specific to this stage'),
    Field('riskMitigationStrategies', String, 'Risk Mitigation Strategies',
        hint: 'Planned responses to top risks'),
    Field('contingencyTriggers', String, 'Contingency Triggers',
        hint: 'Conditions that activate contingency plans'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation process for critical issues'),
  ])
  String? content;
}

/// Status and metrics for a stage entry.
@SectionId('STME')
class StageMetrics {
  @Form([
    Field('completionPercentage', String, 'Completion %',
        hint: '0-100 — current progress'),
    Field('healthIndicator', String, 'Health Indicator',
        hint: 'Green / Amber / Red'),
    Field('scheduleVariance', String, 'Schedule Variance',
        hint: 'Days ahead or behind plan'),
    Field('keyPerformanceIndicators', String, 'Key Performance Indicators',
        hint: 'KPIs to measure stage success'),
    Field('successThreshold', String, 'Success Threshold',
        hint: 'Minimum outcome required to declare success'),
  ])
  String? content;
}

/// A sub-stage or milestone entry (form).
///
/// Represents a discrete phase within a stage — alpha, beta, release
/// candidate, pilot, GA — or a key milestone. Sub-stages provide finer
/// scheduling granularity and quality gates within a stage.
@SectionId('SUSST')
class SubStageEntry {
  @Form([
    Field('name', String, 'Name',
        hint: 'Descriptive name for this sub-stage or milestone',
        required: true),
    Field('subStageType', String, 'Type',
        hint:
            'Alpha / Beta / RC / Pilot / GA / Milestone / Sprint '
            '/ Iteration / Hardening'),
    Field('sequenceNumber', String, 'Sequence Number',
        hint: 'Order within the parent stage — 1, 2, 3…'),
  ])
  String? content;

  /// Description and objectives.
  SubStageEntryOverview overview = SubStageEntryOverview();

  /// Timeline and sequencing.
  SubStageEntryTimeline timeline = SubStageEntryTimeline();

  /// Scope and deliverables.
  SubStageEntryScope scope = SubStageEntryScope();

  /// Resources and quality focus.
  SubStageEntryExecution execution = SubStageEntryExecution();

  /// Current status.
  SubStageEntryStatus status = SubStageEntryStatus();
}

/// Description and objectives.
@SectionId('SSEO')
class SubStageEntryOverview {
  @Form([
    Field('description', String, 'Description',
        hint: 'Brief description of this sub-stage or milestone'),
    Field('objective', String, 'Objective',
        hint: 'What this sub-stage aims to achieve'),
  ])
  String? content;
}

/// Timeline and sequencing.
@SectionId('SSET')
class SubStageEntryTimeline {
  @Form([
    Field('targetStartDate', String, 'Target Start Date'),
    Field('targetEndDate', String, 'Target End Date'),
    Field('actualStartDate', String, 'Actual Start Date'),
    Field('actualEndDate', String, 'Actual End Date'),
    Field('durationDays', String, 'Duration (days)',
        hint: 'Planned duration in working days'),
    Field('predecessorSubStage', String, 'Predecessor',
        hint:
            'Name or number of the sub-stage that must complete '
            'before this one'),
  ])
  String? content;
}

/// Scope and deliverables.
@SectionId('SSES')
class SubStageEntryScope {
  @Form([
    Field('deliverables', String, 'Deliverables',
        hint:
            'Key outputs expected from this sub-stage — '
            'comma-separated'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Criteria for sign-off of this sub-stage'),
    Field('userGroupScope', String, 'User Group Scope',
        hint:
            'Which user groups are included — e.g. internal only, '
            'pilot group, beta testers, all users'),
  ])
  String? content;
}

/// Resources and quality focus.
@SectionId('SSEE')
class SubStageEntryExecution {
  @Form([
    Field('assignedTeam', String, 'Assigned Team',
        hint: 'Team or team members assigned to this sub-stage'),
    Field('environmentNeeded', String, 'Environment Needed',
        hint:
            'Environment required — e.g. dev, staging, UAT, '
            'production-like, production'),
    Field('qualityGate', String, 'Quality Gate',
        hint:
            'Quality checkpoint at the end of this sub-stage — '
            'what must be verified'),
    Field('testingFocus', String, 'Testing Focus',
        hint:
            'Primary testing activities — smoke, regression, '
            'performance, UAT, security'),
  ])
  String? content;
}

/// Current status.
@SectionId('SSES1')
class SubStageEntryStatus {
  @Form([
    Field('currentStatus', String, 'Current Status',
        hint:
            'NotStarted / InProgress / Completed / Blocked / '
            'Cancelled'),
    Field('completionPercentage', String, 'Completion %',
        hint: '0-100 — current progress'),
  ])
  String? content;
}

/// A success criterion entry (form).
///
/// Defines a measurable criterion that determines whether a stage has
/// achieved its objectives. Each criterion has a target metric,
/// measurement method, threshold, and verification process.
@SectionId('STGSUC')
class StageSuccessCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier — e.g. SC-01, SC-02'),
    Field('criterion', String, 'Criterion',
        hint: 'Description of the success criterion',
        required: true),
    Field('category', String, 'Category',
        hint:
            'Functional / Performance / Adoption / Quality / '
            'Security / Compliance / Operational'),
    Field('priority', String, 'Priority',
        hint:
            'MustMeet / ShouldMeet / NiceToHave — importance for '
            'stage sign-off'),
  ])
  String? content;

  /// Measurement targets.
  StageSuccessCriterionEntryMeasurement measurement =
      StageSuccessCriterionEntryMeasurement();

  /// Verification planning.
  StageSuccessCriterionEntryVerification verification =
      StageSuccessCriterionEntryVerification();

  /// Current status and results.
  StageSuccessCriterionEntryStatus status = StageSuccessCriterionEntryStatus();
}

/// Measurement targets.
@SectionId('SSCEM')
class StageSuccessCriterionEntryMeasurement {
  @Form([
    Field('measurementMethod', String, 'Measurement Method',
        hint: 'How this criterion will be measured',
        required: true),
    Field('metric', String, 'Metric',
        hint:
            'Specific metric to track — e.g. response time, adoption rate, error rate, throughput'),
    Field('targetValue', String, 'Target Value',
        hint: 'Target metric value for success — e.g. <200ms, >95%'),
    Field('minimumThreshold', String, 'Minimum Threshold',
        hint:
            'Minimum acceptable value — below this, the stage fails this criterion'),
    Field('tolerance', String, 'Tolerance',
        hint: 'Acceptable variance from target — e.g. +/-5%, +/-10ms'),
    Field('baselineValue', String, 'Baseline Value',
        hint: 'Current baseline before the stage, for comparison'),
  ])
  String? content;
}

/// Verification planning.
@SectionId('SSCEV')
class StageSuccessCriterionEntryVerification {
  @Form([
    Field('verificationMethod', String, 'Verification Method',
        hint:
            'Automated / Manual / Audit / Survey / Report / LoadTest'),
    Field('verifier', String, 'Verifier',
        hint: 'Person or role responsible for verification'),
    Field('verificationDate', String, 'Verification Date',
        hint: 'When verification will be performed'),
  ])
  String? content;
}

/// Current status and results.
@SectionId('SSCES')
class StageSuccessCriterionEntryStatus {
  @Form([
    Field('currentStatus', String, 'Status',
        hint: 'Pending / Measuring / Met / NotMet / Waived'),
    Field('actualValue', String, 'Actual Value',
        hint: 'Measured value — populated during or after stage'),
  ])
  String? content;
}

/// 13.4. Feature Prioritization.
///
/// Comprehensive feature prioritization framework for staged delivery.
/// Covers prioritization methodology, MoSCoW analysis, feature-stage
/// mapping, individual feature priority scoring, and cross-feature
/// dependency tracking. Aligns with SAFe WSJF, PMBOK value-driven
/// delivery, MoSCoW (DSDM), and Kano model classification.
@SectionId('FEPR')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-FEA')
class FeaturePrioritization {
  @Form([
    Field('prioritizationMethodology', String,
        'Prioritization Methodology',
        hint: 'MoSCoW / WSJF / ValueVsEffort / Kano / Hybrid',
        required: true),
    Field('prioritizationOwner', String, 'Prioritization Owner',
        hint: 'Role or person with final authority', required: true),
    Field('reviewCadence', String, 'Review Cadence',
        hint: 'How often prioritization is reviewed', required: true),
  ])
  String? content;

  /// Methodology and scoring.
  FeaturePrioritizationMethodology methodology =
      FeaturePrioritizationMethodology();

  /// Stakeholder involvement.
  FeaturePrioritizationStakeholder stakeholder =
      FeaturePrioritizationStakeholder();

  /// Cadence and triggers.
  FeaturePrioritizationCadence cadence =
      FeaturePrioritizationCadence();

  /// Capacity constraints.
  FeaturePrioritizationCapacity capacity =
      FeaturePrioritizationCapacity();

  /// Backlog health.
  FeaturePrioritizationBacklog backlog =
      FeaturePrioritizationBacklog();

  /// Traceability.
  FeaturePrioritizationTraceability traceability =
      FeaturePrioritizationTraceability();

  /// Prioritization rationale narrative.
  @ContentHelp('Rationale behind feature prioritization approach: '
      'stakeholder input process, business value criteria, '
      'technical feasibility factors, risk considerations, '
      'trade-offs made, and how priorities map to stage planning.')
  TextSection prioritizationRationale = TextSection();

  /// 13.4.1. MoSCoW Analysis.
  MoscowAnalysis moscowAnalysis = MoscowAnalysis();

  /// 13.4.2. Feature-Stage Matrix.
  FeatureStageMatrix featureStageMatrix = FeatureStageMatrix();

  /// 13.4.3. Feature Priority Register.
  FeaturePriorityRegister featurePriorityRegister =
      FeaturePriorityRegister();

  /// 13.4.4. Feature Dependencies.
  FeatureDependencies featureDependencies = FeatureDependencies();
}

/// Methodology and scoring.
@SectionId('FEPRME')
class FeaturePrioritizationMethodology {
  @Form([
    Field('secondaryMethodology', String, 'Secondary Methodology',
        hint: 'Optional complementary method'),
    Field('scoringModelDescription', String, 'Scoring Model Description',
        hint: 'How priority scores are calculated'),
    Field('prioritizationCriteria', String, 'Prioritization Criteria',
        hint: 'Comma-separated criteria — BusinessValue, CostOfDelay, Risk'),
    Field('criteriaWeights', String, 'Criteria Weights',
        hint: 'Weight per criterion'),
  ])
  String? content;
}

/// Stakeholder involvement.
@SectionId('FEPRST')
class FeaturePrioritizationStakeholder {
  @Form([
    Field('stakeholderParticipants', String, 'Stakeholder Participants',
        hint: 'Roles involved — PM, Architects, Business Analysts'),
    Field('stakeholderVotingMethod', String, 'Stakeholder Voting Method',
        hint: 'DotVoting / PlanningPoker / ConsensusBuilding'),
    Field('conflictResolutionProcess', String, 'Conflict Resolution Process',
        hint: 'How disagreements are resolved'),
  ])
  String? content;
}

/// Cadence and triggers.
@SectionId('FEPRCA')
class FeaturePrioritizationCadence {
  @Form([
    Field('rePrioritizationTriggers', String, 'Re-Prioritization Triggers',
        hint: 'Events forcing re-prioritization'),
    Field('lastPrioritizationDate', String, 'Last Prioritization Date',
        hint: 'When features were last formally prioritized'),
    Field('nextReviewDate', String, 'Next Scheduled Review',
        hint: 'Next planned prioritization review session'),
  ])
  String? content;
}

/// Capacity constraints.
@SectionId('FEPRC1')
class FeaturePrioritizationCapacity {
  @Form([
    Field('teamVelocity', String, 'Team Velocity',
        hint: 'Current velocity in story points per sprint'),
    Field('budgetCap', String, 'Budget Cap',
        hint: 'Total budget available for feature delivery'),
    Field('maxFeaturesPerStage', String, 'Max Features Per Stage',
        hint: 'Capacity limit based on team size and velocity'),
    Field('resourceBottlenecks', String, 'Resource Bottlenecks',
        hint: 'Scarce resources constraining delivery'),
  ])
  String? content;
}

/// Backlog health.
@SectionId('FEPRBA')
class FeaturePrioritizationBacklog {
  @Form([
    Field('totalFeaturesInBacklog', String, 'Total Features in Backlog',
        hint: 'Total feature count across all priority tiers'),
    Field('featuresFullyPrioritized', String, 'Features Fully Prioritized',
        hint: 'Count with complete priority scoring'),
    Field('featuresUnprioritized', String, 'Features Unprioritized',
        hint: 'Features awaiting prioritization'),
    Field('backlogGroomingStatus', String, 'Backlog Grooming Status',
        hint: 'Current / Stale / NeedsReview'),
    Field('averageFeatureAge', String, 'Average Feature Age',
        hint: 'Mean time features spend in backlog'),
  ])
  String? content;
}

/// Traceability.
@SectionId('FEPRTR')
class FeaturePrioritizationTraceability {
  @Form([
    Field('traceabilityToBusinessCase', String,
        'Traceability to Business Case',
        hint: 'How features link to business case'),
    Field('traceabilityToRequirements', String,
        'Traceability to Requirements',
        hint: 'How features map to requirements'),
  ])
  String? content;
}

/// 13.4.1. MoSCoW Analysis.
///
/// Classifies every feature using the MoSCoW method (Must / Should /
/// Could / Won't) and maps each to its target delivery stage.
@SectionId('MOAN')
class MoscowAnalysis {
  @Form([
    // --- Summary Statistics ---
    Field('mustHaveCount', String, 'Must-Have Count',
        hint: 'Number of Must-have features'),
    Field('shouldHaveCount', String, 'Should-Have Count',
        hint: 'Number of Should-have features'),
    Field('couldHaveCount', String, 'Could-Have Count',
        hint: 'Number of Could-have features'),
    Field('wontHaveCount', String, 'Won\'t-Have Count',
        hint: 'Number of Won\'t-have features'),
    Field('mustHaveEffortPercentage', String, 'Must-Have Effort %',
        hint:
            'Percentage of total effort consumed by Must-haves — '
            'DSDM recommends ≤60%'),
    Field('shouldHaveEffortPercentage', String,
        'Should-Have Effort %',
        hint: 'Percentage of total effort for Should-haves — ≤20%'),
    Field('classificationRationale', String,
        'Classification Rationale',
        hint:
            'High-level rationale for the MoSCoW balance — '
            'risk-averse, value-first, regulatory-driven'),
    Field('classificationDate', String, 'Classification Date',
        hint: 'When the MoSCoW classification was last performed'),
    Field('classificationApprovedBy', String,
        'Classification Approved By',
        hint: 'Person or body who approved the classification'),
  ])
  String? content;

  /// MoSCoW rationale narrative.
  @ContentHelp('Rationale for MoSCoW classification decisions: '
      'criteria used to assign categories, stakeholder alignment '
      'process, handling of contested classifications, '
      'relationship to stage boundaries and MVP definition.')
  TextSection moscowRationale = TextSection();

  /// Contains 0+× MoscowEntry.
  @SectionId('MOEN-ITEM-LST')
  @SectionIdPattern('MOEN-ITEM-xxx')
  List<MoscowEntry> items = [];
}

/// A MoSCoW classification entry (form).
///
/// Maps a single feature or feature group to its MoSCoW category and
/// target delivery stage, with justification and cross-references.
@SectionId('ME')
class MoscowEntry {
  @Form([
    Field('featureId', String, 'Feature ID',
        hint:
            'Unique feature identifier — e.g. FEA-001, or '
            'reference to feature register entry',
        required: true),
    Field('featureName', String, 'Feature Name',
        hint: 'Short descriptive name of the feature',
        required: true),
    Field('featureGroup', String, 'Feature Group',
        hint:
            'Logical grouping — e.g. Authentication, Reporting, '
            'Payments, User Management'),
  ])
  String? content;

  /// MoSCoW classification details.
  MoscowEntryClassification classification = MoscowEntryClassification();

  /// Value and effort estimates.
  MoscowEntryValue value = MoscowEntryValue();

  /// Stage assignment.
  MoscowEntryStageAssignment stageAssignment = MoscowEntryStageAssignment();

  /// Traceability and notes.
  MoscowEntryTraceability traceability = MoscowEntryTraceability();
}

/// MoSCoW classification details.
@SectionId('MOENCL')
class MoscowEntryClassification {
  @Form([
    Field('moscowCategory', String, 'MoSCoW Category',
        hint: 'Must / Should / Could / Wont',
        required: true),
    Field('justification', String, 'Justification',
        hint:
            'Why this feature has this classification — business rationale, regulatory need, user demand',
        required: true),
    Field('reclassificationRisk', String, 'Reclassification Risk',
        hint:
            'Low / Medium / High — likelihood the category will change before delivery'),
  ])
  String? content;
}

/// Value and effort estimates.
@SectionId('MOENVA')
class MoscowEntryValue {
  @Form([
    Field('businessValue', String, 'Business Value',
        hint:
            'Relative business value — 1-10, Fibonacci, or qualitative High/Medium/Low'),
    Field('effortEstimate', String, 'Effort Estimate',
        hint:
            'Relative effort — story points, T-shirt size, or person-days'),
    Field('costOfDelay', String, 'Cost of Delay',
        hint:
            'Impact of not delivering on time — revenue loss, penalty, competitive risk'),
  ])
  String? content;
}

/// Stage assignment.
@SectionId('MESA')
class MoscowEntryStageAssignment {
  @Form([
    Field('targetStage', String, 'Target Stage',
        hint:
            'Stage in which this feature is planned for delivery',
        required: true),
    Field('earliestPossibleStage', String,
        'Earliest Possible Stage',
        hint:
            'Earliest stage where prerequisites allow delivery'),
  ])
  String? content;
}

/// Traceability and notes.
@SectionId('MOENTR')
class MoscowEntryTraceability {
  @Form([
    Field('linkedRequirements', String, 'Linked Requirements',
        hint:
            'Requirement IDs this feature traces to — comma-separated'),
    Field('linkedUseCases', String, 'Linked Use Cases',
        hint: 'Use case IDs this feature implements'),
    Field('dependsOnFeatures', String, 'Depends on Features',
        hint:
            'Feature IDs that must be delivered before this one'),
    Field('notes', String, 'Notes',
        hint: 'Additional notes or caveats'),
  ])
  String? content;
}

/// 13.4.2. Feature-Stage Matrix.
///
/// Maps every feature or feature group to the delivery stage, tracking
/// readiness, confidence, dependencies, and acceptance criteria.
@SectionId('FESTMA')
class FeatureStageMatrix {
  @Form([
    // --- Matrix Summary ---
    Field('totalMappedFeatures', String, 'Total Mapped Features',
        hint: 'Number of features mapped to stages'),
    Field('unmappedFeatures', String, 'Unmapped Features',
        hint: 'Features not yet assigned to any stage'),
    Field('stageCapacityUtilization', String,
        'Stage Capacity Utilization',
        hint:
            'Per-stage capacity summary — e.g. Stage 1: 85%, '
            'Stage 2: 60%'),
    Field('crossStageDependencyCount', String,
        'Cross-Stage Dependency Count',
        hint:
            'Feature dependencies crossing stage boundaries'),
    Field('matrixLastUpdated', String, 'Matrix Last Updated',
        hint: 'Date the feature-stage matrix was last updated'),
    Field('matrixApprovedBy', String, 'Matrix Approved By',
        hint: 'Person or body who approved the current matrix'),
  ])
  String? content;

  /// Feature-Stage matrix narrative.
  @ContentHelp('Explanation of feature-to-stage mapping logic: '
      'allocation criteria, dependency constraints, capacity '
      'considerations, cross-stage feature splitting, '
      'handling of scope changes and re-prioritizations.')
  TextSection matrixNarrative = TextSection();

  /// Contains 0+× FeatureStageMapping.
  @SectionId('FESTM1-ITEM-LST')
  @SectionIdPattern('FESTM1-ITEM-xxx')
  List<FeatureStageMapping> items = [];
}

/// A feature-to-stage mapping entry (form).
///
/// Maps a single feature or feature group to its delivery stage with
/// readiness, confidence, and dependency information.
@SectionId('FSM')
class FeatureStageMapping {
  @Form([
    Field('featureId', String, 'Feature ID',
        hint:
            'Feature identifier — matches MoSCoW entry or '
            'register',
        required: true),
    Field('featureName', String, 'Feature Name',
        hint: 'Short descriptive name',
        required: true),
    Field('featureGroup', String, 'Feature Group',
        hint: 'Logical grouping for this feature'),
  ])
  String? content;

  /// Stage assignment details.
  FeatureStageMappingAssignment assignment = FeatureStageMappingAssignment();

  /// Readiness and confidence.
  FeatureStageMappingReadiness readiness = FeatureStageMappingReadiness();

  /// Dependencies.
  FeatureStageMappingDependencies dependencies =
      FeatureStageMappingDependencies();

  /// Acceptance and notes.
  FeatureStageMappingAcceptance acceptance = FeatureStageMappingAcceptance();
}

/// Stage assignment details.
@SectionId('FSMA')
class FeatureStageMappingAssignment {
  @Form([
    Field('targetStage', String, 'Target Stage',
        hint: 'Stage in which this feature will be delivered',
        required: true),
    Field('stagePhase', String, 'Stage Phase',
        hint:
            'Sub-phase within the stage — Alpha / Beta / GA / Full rollout'),
    Field('fallbackStage', String, 'Fallback Stage',
        hint:
            'Stage to which this feature moves if cut from target stage'),
  ])
  String? content;
}

/// Readiness and confidence.
@SectionId('FSMR')
class FeatureStageMappingReadiness {
  @Form([
    Field('readinessStatus', String, 'Readiness Status',
        hint:
            'NotReady / InProgress / DesignComplete / ReadyForDev / ReadyForTest / ReadyForRelease',
        required: true),
    Field('deliveryConfidence', String, 'Delivery Confidence',
        hint:
            'High / Medium / Low — confidence that this feature will be delivered in the target stage'),
    Field('confidenceRationale', String, 'Confidence Rationale',
        hint:
            'Why confidence is at this level — blockers, unknowns, resource gaps'),
  ])
  String? content;
}

/// Dependencies.
@SectionId('FSMD')
class FeatureStageMappingDependencies {
  @Form([
    Field('prerequisiteFeatures', String, 'Prerequisite Features',
        hint:
            'Feature IDs that must complete first — comma-separated'),
    Field('blockedByExternalDependency', String,
        'Blocked by External Dependency',
        hint:
            'External systems, vendors, or approvals — None, or description'),
    Field('crossStageDependency', String,
        'Cross-Stage Dependency',
        hint:
            'Does this feature depend on something from a prior stage — Yes/No, plus which stage'),
  ])
  String? content;
}

/// Acceptance and notes.
@SectionId('FSMA1')
class FeatureStageMappingAcceptance {
  @Form([
    Field('acceptanceCriteriaSummary', String,
        'Acceptance Criteria Summary',
        hint:
            'High-level criteria for this feature to be accepted'),
    Field('definitionOfDone', String, 'Definition of Done',
        hint:
            'DoD for this feature — code complete, tests pass, docs updated, deployed'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or caveats'),
  ])
  String? content;
}

/// 13.4.3. Feature Priority Register.
///
/// Master register of all features with comprehensive priority scoring,
/// business value analysis, effort estimates, stakeholder ownership,
/// and traceability. Single source of truth for feature identity.
@SectionId('FEPRRE')
class FeaturePriorityRegister {
  @Form([
    Field('totalRegisteredFeatures', String,
        'Total Registered Features',
        hint: 'Total number of features in the register'),
    Field('registerLastUpdated', String, 'Register Last Updated',
        hint: 'Date the register was last fully reviewed'),
    Field('registerOwner', String, 'Register Owner',
        hint:
            'Person responsible for maintaining the register — '
            'typically Product Owner'),
  ])
  String? content;

  /// Contains 1+× FeaturePriorityEntry.
  @SectionId('FEPREN-ITEM-LST')
  @SectionIdPattern('FEPREN-ITEM-xxx')
  @Min(1)
  List<FeaturePriorityEntry> items = [];
}

/// An individual feature priority entry (form).
///
/// Comprehensive record covering identity, classification, business
/// value, effort, priority scoring, stage assignment, dependencies,
/// stakeholders, traceability, and status.
@SectionId('FPE')
class FeaturePriorityEntry {
  @Form([
    Field('featureId', String, 'Feature ID',
        hint: 'Unique identifier — e.g. FEA-001',
        required: true),
    Field('featureName', String, 'Feature Name',
        hint: 'Short descriptive name',
        required: true),
    Field('priorityRank', String, 'Priority Rank',
        hint: 'Ordinal rank — 1 = highest',
        required: true),
  ])
  String? content;

  /// Feature identity.
  FeatureIdentity identity = FeatureIdentity();

  /// Business value.
  FeatureBusinessValue businessValue = FeatureBusinessValue();

  /// Effort and complexity.
  FeatureEffort effort = FeatureEffort();

  /// Priority scoring.
  FeaturePriorityScoring priorityScoring = FeaturePriorityScoring();

  /// Stage assignment.
  FeatureStageAssignment stageAssignment = FeatureStageAssignment();

  /// Dependencies.
  FeatureDependenciesInfo dependencies = FeatureDependenciesInfo();

  /// Stakeholders.
  @SectionId('FEST-STAK-LST')
  @SectionIdPattern('FEST-STAK-xxx')
  List<FeatureStakeholders> stakeholders = [];

  /// Traceability.
  FeatureTraceability traceability = FeatureTraceability();

  /// Status.
  FeatureStatus status = FeatureStatus();
}

/// Feature identity for a feature priority entry.
@SectionId('FEID')
class FeatureIdentity {
  @Form([
    Field('featureDescription', String, 'Description',
        hint: 'Detailed description of the feature capability'),
    Field('featureCategory', String, 'Category',
        hint: 'Functional / NonFunctional / Regulatory / UX / Infrastructure',
        required: true),
    Field('featureSubCategory', String, 'Sub-Category',
        hint: 'Finer classification'),
    Field('featureType', String, 'Feature Type',
        hint: 'New / Enhancement / BugFix / TechnicalDebt / Enabler'),
    Field('featureSize', String, 'Feature Size',
        hint: 'XS / S / M / L / XL — T-shirt sizing'),
    Field('epicLink', String, 'Epic Link',
        hint: 'Parent epic or theme'),
  ])
  String? content;
}

/// Business value for a feature priority entry.
@SectionId('FEBUVA')
class FeatureBusinessValue {
  @Form([
    Field('businessValueScore', String, 'Business Value Score',
        hint: 'Numeric score — 1-10 or Fibonacci',
        required: true),
    Field('revenueImpact', String, 'Revenue Impact',
        hint: 'None / Low / Medium / High / Critical'),
    Field('revenueEstimate', String, 'Revenue Estimate',
        hint: 'Estimated revenue or savings'),
    Field('costOfDelay', String, 'Cost of Delay',
        hint: 'Cost of not delivering'),
    Field('costOfDelayCategory', String, 'Cost of Delay Category',
        hint: 'StandardDecay / FixedDate / UrgentPenalty / None'),
    Field('strategicAlignment', String, 'Strategic Alignment',
        hint: 'Low / Medium / High / Critical',
        required: true),
    Field('strategicObjectiveLink', String, 'Strategic Objective Link',
        hint: 'Which business objective or OKR this supports'),
    Field('customerImpact', String, 'Customer Impact',
        hint: 'Low / Medium / High'),
    Field('userBaseAffected', String, 'User Base Affected',
        hint: 'Percentage or count of users'),
    Field('marketCompetitiveness', String, 'Market Competitiveness',
        hint: 'TableStakes / Differentiator / Innovative / CatchUp'),
    Field('regulatoryRequirement', String, 'Regulatory Requirement',
        hint: 'None / Recommended / Mandatory'),
    Field('regulatoryDeadline', String, 'Regulatory Deadline',
        hint: 'Hard compliance deadline'),
  ])
  String? content;
}

/// Effort and complexity for a feature priority entry.
@SectionId('FEEF')
class FeatureEffort {
  @Form([
    Field('estimatedEffort', String, 'Estimated Effort',
        hint: 'Story points, person-days, or T-shirt size',
        required: true),
    Field('complexityRating', String, 'Complexity Rating',
        hint: 'Low / Medium / High / VeryHigh'),
    Field('complexityFactors', String, 'Complexity Factors',
        hint: 'Key sources of complexity'),
    Field('riskLevel', String, 'Risk Level',
        hint: 'Low / Medium / High',
        required: true),
    Field('riskFactors', String, 'Risk Factors',
        hint: 'Specific risks'),
    Field('technicalDebtImpact', String, 'Technical Debt Impact',
        hint: 'Creates / Reduces / Neutral'),
    Field('dependencyCount', String, 'Dependency Count',
        hint: 'Number of features this depends on or blocks'),
    Field('integrationComplexity', String, 'Integration Complexity',
        hint: 'None / Low / Medium / High'),
  ])
  String? content;
}

/// Priority scoring for a feature priority entry.
@SectionId('FEPRSC')
class FeaturePriorityScoring {
  @Form([
    Field('weightedPriorityScore', String, 'Weighted Priority Score',
        hint: 'Calculated score from weighted criteria',
        required: true),
    Field('moscowTier', String, 'MoSCoW Tier',
        hint: 'Must / Should / Could / Wont',
        required: true),
    Field('wsjfScore', String, 'WSJF Score',
        hint: 'Weighted Shortest Job First score — CoD / JobSize'),
    Field('kanoClassification', String, 'Kano Classification',
        hint: 'Basic / Performance / Excitement / Indifferent'),
    Field('prioritizationNotes', String, 'Prioritization Notes',
        hint: 'Justification or context for the scoring'),
  ])
  String? content;
}

/// Stage assignment for a feature priority entry.
@SectionId('FESTAS')
class FeatureStageAssignment {
  @Form([
    Field('targetStage', String, 'Target Stage',
        hint: 'Planned delivery stage',
        required: true),
    Field('earliestPossibleStage', String, 'Earliest Possible Stage',
        hint: 'Earliest stage prerequisites allow'),
    Field('fallbackStage', String, 'Fallback Stage',
        hint: 'Stage to defer to if cut from target'),
    Field('stageAssignmentRationale', String, 'Stage Assignment Rationale',
        hint: 'Why this stage'),
  ])
  String? content;
}

/// Dependencies info for a feature priority entry.
@SectionId('FEDEIN')
class FeatureDependenciesInfo {
  @Form([
    Field('dependsOnFeatures', String, 'Depends on Features',
        hint: 'Feature IDs this requires'),
    Field('blocksFeatures', String, 'Blocks Features',
        hint: 'Feature IDs blocked until this completes'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'External systems, APIs, vendors, or approvals'),
    Field('dependencyCriticalPath', String, 'On Dependency Critical Path',
        hint: 'Yes / No'),
  ])
  String? content;
}

/// Stakeholders for a feature priority entry.
@SectionId('FEST')
class FeatureStakeholders {
  @Form([
    Field('requestedBy', String, 'Requested By',
        hint: 'Person, team, or customer who requested this'),
    Field('businessOwner', String, 'Business Owner',
        hint: 'Business stakeholder accountable',
        required: true),
    Field('productOwner', String, 'Product Owner',
        hint: 'Product owner for backlog management'),
    Field('technicalOwner', String, 'Technical Owner',
        hint: 'Engineer or architect for delivery'),
    Field('approvalStatus', String, 'Approval Status',
        hint: 'Proposed / Approved / ConditionallyApproved / Rejected'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Person or body who approved'),
    Field('approvalDate', String, 'Approval Date',
        hint: 'When approval was granted'),
  ])
  String? content;
}

/// Traceability for a feature priority entry.
@SectionId('FETR')
class FeatureTraceability {
  @Form([
    Field('linkedRequirements', String, 'Linked Requirements',
        hint: 'Requirement IDs'),
    Field('linkedUseCases', String, 'Linked Use Cases',
        hint: 'Use case IDs'),
    Field('linkedBusinessProcesses', String, 'Linked Business Processes',
        hint: 'Business process IDs'),
    Field('linkedUserStories', String, 'Linked User Stories',
        hint: 'User story IDs in the backlog'),
    Field('linkedArchitectureDecisions', String, 'Linked Architecture Decisions',
        hint: 'ADR IDs affected by or affecting this feature'),
  ])
  String? content;
}

/// Status for a feature priority entry.
@SectionId('FEST1')
class FeatureStatus {
  @Form([
    Field('prioritizationStatus', String, 'Prioritization Status',
        hint: 'Draft / UnderReview / Prioritized / Deferred / Dropped',
        required: true),
    Field('deliveryStatus', String, 'Delivery Status',
        hint: 'Backlog / Planned / InDevelopment / InTest / Delivered'),
    Field('confidenceLevel', String, 'Confidence Level',
        hint: 'High / Medium / Low'),
    Field('lastReviewedDate', String, 'Last Reviewed Date',
        hint: 'When last reviewed in prioritization'),
    Field('changeHistory', String, 'Change History',
        hint: 'Brief log of priority/stage changes'),
  ])
  String? content;
}

/// 13.4.4. Feature Dependencies.
///
/// Cross-feature dependencies affecting staging order, critical path
/// analysis, and delivery sequencing.
@SectionId('FEDE')
class FeatureDependencies {
  @Form([
    Field('totalDependencyCount', String, 'Total Dependency Count',
        hint: 'Total number of inter-feature dependencies'),
    Field('crossStageDependencyCount', String,
        'Cross-Stage Dependency Count',
        hint:
            'Dependencies spanning stage boundaries — highest '
            'scheduling risk'),
    Field('criticalPathLength', String, 'Critical Path Length',
        hint:
            'Longest dependency chain — number of features on '
            'the critical path'),
    Field('circularDependenciesDetected', String,
        'Circular Dependencies Detected',
        hint:
            'Yes / No — whether any circular chains exist '
            '(must be resolved)'),
    Field('dependencyMapLastUpdated', String,
        'Dependency Map Last Updated',
        hint: 'When the dependency map was last analyzed'),
  ])
  String? content;

  /// Dependency analysis narrative.
  @ContentHelp('Analysis of feature dependencies: dependency types, '
      'impact assessment methodology, critical dependency chains, '
      'circular dependency resolution, cross-stage dependencies, '
      'external system dependencies.')
  TextSection dependencyAnalysis = TextSection();

  /// Contains 0+× FeatureDependencyEntry.
  @SectionId('FEDEEN-ITEM-LST')
  @SectionIdPattern('FEDEEN-ITEM-xxx')
  List<FeatureDependencyEntry> items = [];
}

/// A feature dependency entry (form).
///
/// Describes a single directional dependency between two features,
/// including type, impact, and resolution strategy.
@SectionId('FDE')
class FeatureDependencyEntry {
  @Form([
    // --- Dependency Relationship ---
    Field('sourceFeatureId', String, 'Source Feature ID',
        hint: 'Feature that has the dependency (the dependent)',
        required: true),
    Field('targetFeatureId', String, 'Target Feature ID',
        hint:
            'Feature that must be delivered first (the '
            'prerequisite)',
        required: true),
    Field('dependencyType', String, 'Dependency Type',
        hint:
            'FinishToStart / StartToStart / FinishToFinish / '
            'Technical / Data / Interface / Regulatory',
        required: true),
    Field('dependencyStrength', String, 'Dependency Strength',
        hint:
            'Hard / Soft — Hard = strict ordering, Soft = '
            'preferred but can be broken with workaround'),
    // --- Impact & Risk ---
    Field('impactIfBroken', String, 'Impact if Broken',
        hint:
            'Consequence if not satisfied — rework, partial '
            'functionality, blocking'),
    Field('schedulingImpact', String, 'Scheduling Impact',
        hint:
            'Days of delay if target feature slips — e.g. '
            '1:1 day-for-day, or buffered'),
    Field('crossStageDependency', String, 'Cross-Stage',
        hint:
            'Yes / No — whether source and target are in '
            'different stages'),
    // --- Resolution ---
    Field('mitigationStrategy', String, 'Mitigation Strategy',
        hint:
            'How to handle if at risk — stub/mock, parallel '
            'development, interface contract'),
    Field('resolutionStatus', String, 'Resolution Status',
        hint:
            'Open / Mitigated / Resolved / Accepted — current '
            'state'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or constraints'),
  ])
  String? content;
}

/// 13.5. Data Migration Strategy.
///
/// Comprehensive data migration strategy covering approach, methodology,
/// tooling, environment strategy, data quality governance, cutover
/// planning, rollback mechanisms, compliance requirements (GDPR, HIPAA),
/// and stakeholder sign-off. Aligns with DAMA-DMBOK data management
/// principles, TOGAF migration planning, and PMBOK risk-aware delivery.
@SectionId('DAMIST')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-MIG')
class DataMigrationStrategy {
  @Form([
    Field('migrationApproach', String, 'Migration Approach',
        hint: 'BigBang / Trickle / ParallelRun / Phased / Hybrid',
        required: true),
    Field('migrationMethodology', String, 'Migration Methodology',
        hint: 'ETL-Centric / API-First / CDC-Based / ReplicationBased / Hybrid',
        required: true),
    Field('migrationLead', String, 'Migration Lead',
        hint: 'Person accountable for end-to-end migration',
        required: true),
  ])
  String? content;

  /// Strategic approach details.
  MigrationApproach approach = MigrationApproach();

  /// Scope and data landscape.
  MigrationScope scope = MigrationScope();

  /// Source and target system details.
  @SectionId('MISY-SYST-LST')
  @SectionIdPattern('MISY-SYST-xxx')
  List<MigrationSystems> systems = [];

  /// Data quality strategy.
  MigrationDataQuality dataQuality = MigrationDataQuality();

  /// Tooling and technology stack.
  MigrationTooling tooling = MigrationTooling();

  /// Environment strategy.
  @SectionId('MIEN-ENVI-LST')
  @SectionIdPattern('MIEN-ENVI-xxx')
  List<MigrationEnvironments> environments = [];

  /// Cutover planning.
  MigrationCutover cutover = MigrationCutover();

  /// Rollback and recovery strategy.
  MigrationRollback rollback = MigrationRollback();

  /// Compliance and governance.
  MigrationCompliance compliance = MigrationCompliance();

  /// Success metrics.
  MigrationMetrics metrics = MigrationMetrics();

  /// Stakeholder communication.
  @SectionId('MIST-STAK-LST')
  @SectionIdPattern('MIST-STAK-xxx')
  List<MigrationStakeholders> stakeholders = [];

  /// Budget and resources.
    @SectionId('STMIRE-RESO-LST')
  @SectionIdPattern('STMIRE-RESO-xxx')
  List<StageMigrationResources> resources = [];

  /// Schedule overview.
  MigrationSchedule schedule = MigrationSchedule();

  /// Migration strategy narrative.
  @ContentHelp('Overall data migration approach: migration methodology, '
      'tool selection rationale, phasing strategy, dry run plan, '
      'data quality assurance approach, rollback mechanisms, '
      'parallel operation strategy, and hypercare support model.')
  TextSection migrationStrategyNarrative = TextSection();

  /// 13.5.1. Migration Phases.
  MigrationPhases migrationPhases = MigrationPhases();

  /// 13.5.2. Migration Risks.
  StageMigrationRisks migrationRisks = StageMigrationRisks();
}

/// Strategic approach for data migration.
@SectionId('MIAP')
class MigrationApproach {
  @Form([
    Field('migrationRationale', String, 'Approach Rationale',
        hint: 'Why this approach was chosen — risk tolerance, downtime constraints'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other approaches evaluated and why rejected'),
  ])
  String? content;
}

/// Scope and data landscape for migration.
@SectionId('MISC')
class MigrationScope {
  @Form([
    Field('dataLandscapeOverview', String, 'Data Landscape Overview',
        hint: 'High-level description of the data ecosystem',
        required: true),
    Field('totalSourceSystems', String, 'Total Source Systems',
        hint: 'Number of source systems involved',
        required: true),
    Field('totalDataVolume', String, 'Total Data Volume',
        hint: 'Aggregate data volume across all sources'),
    Field('totalEntitiesInScope', String, 'Total Entities in Scope',
        hint: 'Number of distinct data entities/tables to migrate'),
    Field('dataClassificationSummary', String, 'Data Classification Summary',
        hint: 'Breakdown by classification — Public, Internal, Confidential'),
    Field('excludedFromMigration', String, 'Excluded from Migration',
        hint: 'Data explicitly out of scope'),
  ])
  String? content;
}

/// Source and target systems for migration.
@SectionId('MISY')
class MigrationSystems {
  @Form([
    Field('sourceSystemInventory', String, 'Source System Inventory',
        hint: 'List of source systems'),
    Field('targetSystemDescription', String, 'Target System Description',
        hint: 'Target platform and architecture'),
    Field('schemaTransformationComplexity', String, 'Schema Transformation Complexity',
        hint: 'Low / Medium / High / VeryHigh',
        required: true),
    Field('dataModelChangeSummary', String, 'Data Model Change Summary',
        hint: 'Key structural changes — table splits/merges, normalization'),
  ])
  String? content;
}

/// Data quality strategy for migration.
@SectionId('MIDAQU')
class MigrationDataQuality {
  @Form([
    Field('dataQualityBaselineStatus', String, 'Data Quality Baseline Status',
        hint: 'NotStarted / InProgress / Complete',
        required: true),
    Field('dataQualityProfileTool', String, 'Data Quality Profiling Tool',
        hint: 'Tool used for profiling'),
    Field('knownDataQualityIssues', String, 'Known Data Quality Issues',
        hint: 'Critical issues discovered'),
    Field('dataCleansingStrategy', String, 'Data Cleansing Strategy',
        hint: 'PreMigration / DuringMigration / PostMigration / Hybrid'),
    Field('dataQualityThresholds', String, 'Data Quality Thresholds',
        hint: 'Minimum quality metrics for migration approval'),
  ])
  String? content;
}

/// Tooling and technology for migration.
@SectionId('MITO')
class MigrationTooling {
  @Form([
    Field('primaryMigrationTool', String, 'Primary Migration Tool',
        hint: 'Main tool or platform',
        required: true),
    Field('secondaryTools', String, 'Secondary Tools',
        hint: 'Supporting tools'),
    Field('cdcTool', String, 'CDC Tool',
        hint: 'Change Data Capture tool if applicable'),
    Field('orchestrationPlatform', String, 'Orchestration Platform',
        hint: 'Workflow orchestration — Airflow, Step Functions'),
    Field('scriptingLanguage', String, 'Scripting Language',
        hint: 'Primary language for custom migration logic'),
    Field('versionControlForMigrations', String, 'Version Control for Migrations',
        hint: 'How migration scripts are versioned'),
  ])
  String? content;
}

/// Environment strategy for migration.
@SectionId('MIEN')
class MigrationEnvironments {
  @Form([
    Field('migrationEnvironments', String, 'Migration Environments',
        hint: 'Environments used for migration',
        required: true),
    Field('environmentDataSubsetting', String, 'Environment Data Subsetting',
        hint: 'Data subsetting strategy for lower environments'),
    Field('productionLikeEnvironmentReady', String, 'Production-Like Environment Ready',
        hint: 'Yes / No / InProgress'),
    Field('environmentRefreshCadence', String, 'Environment Refresh Cadence',
        hint: 'How often test environments are refreshed'),
  ])
  String? content;
}

/// Cutover planning for migration.
@SectionId('MICU')
class MigrationCutover {
  @Form([
    Field('cutoverStrategy', String, 'Cutover Strategy',
        hint: 'BigBang / PhaseByEntity / BlueGreenSwitch / CanaryRollout',
        required: true),
    Field('cutoverWindowDuration', String, 'Cutover Window Duration',
        hint: 'Maximum allowed downtime',
        required: true),
    Field('cutoverWindowTiming', String, 'Cutover Window Timing',
        hint: 'Preferred timing'),
    Field('cutoverRunbook', String, 'Cutover Runbook Status',
        hint: 'NotStarted / InProgress / Complete / Tested'),
    Field('preFlightChecklist', String, 'Pre-Flight Checklist Status',
        hint: 'NotStarted / InProgress / Complete'),
    Field('goNoGoDecisionOwner', String, 'Go/No-Go Decision Owner',
        hint: 'Person with final cutover authority'),
    Field('goNoGoCriteria', String, 'Go/No-Go Criteria',
        hint: 'Key criteria for cutover approval'),
  ])
  String? content;
}

/// Rollback and recovery for migration.
@SectionId('MIRO')
class MigrationRollback {
  @Form([
    Field('rollbackStrategy', String, 'Rollback Strategy',
        hint: 'FullRollback / PartialRollback / ForwardFix / DualWrite',
        required: true),
    Field('rollbackTimeBudget', String, 'Rollback Time Budget',
        hint: 'Maximum time to complete rollback'),
    Field('rollbackTriggers', String, 'Rollback Triggers',
        hint: 'Conditions that activate rollback'),
    Field('rollbackTested', String, 'Rollback Tested',
        hint: 'Yes / No / Partially'),
    Field('pointOfNoReturn', String, 'Point of No Return',
        hint: 'Step after which rollback is no longer viable'),
  ])
  String? content;
}

/// Compliance and governance for migration.
@SectionId('MICO')
class MigrationCompliance {
  @Form([
    Field('dataPrivacyCompliance', String, 'Data Privacy Compliance',
        hint: 'GDPR / CCPA / HIPAA / SOX / PCI-DSS / None',
        required: true),
    Field('gdprDataHandling', String, 'GDPR Data Handling',
        hint: 'How personal data is handled during migration'),
    Field('dataResidencyRequirements', String, 'Data Residency Requirements',
        hint: 'Geographic constraints'),
    Field('auditTrailRequirements', String, 'Audit Trail Requirements',
        hint: 'Logging requirements'),
    Field('dataRetentionDuringMigration', String, 'Data Retention During Migration',
        hint: 'How long source data is retained post-migration'),
    Field('migrationGovernanceBody', String, 'Migration Governance Body',
        hint: 'Who oversees migration quality'),
  ])
  String? content;
}

/// Success metrics for migration.
@SectionId('MIME')
class MigrationMetrics {
  @Form([
    Field('successMetrics', String, 'Success Metrics',
        hint: 'Key metrics defining migration success',
        required: true),
    Field('dataCompletenessTarget', String, 'Data Completeness Target',
        hint: 'Target percentage'),
    Field('dataAccuracyTarget', String, 'Data Accuracy Target',
        hint: 'Target accuracy'),
    Field('performanceBenchmark', String, 'Performance Benchmark',
        hint: 'Target throughput'),
    Field('maxAcceptableDowntime', String, 'Max Acceptable Downtime',
        hint: 'Business-defined downtime limit'),
  ])
  String? content;
}

/// Stakeholder communication for migration.
@SectionId('MIST')
class MigrationStakeholders {
  @Form([
    Field('dataOwnerSignoffRequired', String, 'Data Owner Sign-off Required',
        hint: 'Yes / No'),
    Field('businessSignoffProcess', String, 'Business Sign-off Process',
        hint: 'How business validates migration'),
    Field('communicationPlan', String, 'Communication Plan',
        hint: 'Stakeholder communication approach'),
    Field('trainingForMigrationTeam', String, 'Training for Migration Team',
        hint: 'Training needed'),
  ])
  String? content;
}

/// Budget and resources for migration.
@SectionId('STMIRE')
class StageMigrationResources {
  @Form([
    Field('migrationBudget', String, 'Migration Budget',
        hint: 'Total budget for migration activities'),
    Field('teamComposition', String, 'Team Composition',
        hint: 'Key roles'),
    Field('externalVendorSupport', String, 'External Vendor Support',
        hint: 'Third-party support'),
  ])
  String? content;
}

/// Schedule overview for migration.
@SectionId('MISC1')
class MigrationSchedule {
  @Form([
    Field('overallMigrationStart', String, 'Overall Migration Start',
        hint: 'Planned start date of migration activities'),
    Field('overallMigrationEnd', String, 'Overall Migration End',
        hint: 'Planned completion date including hypercare'),
    Field('dryRunCount', String, 'Planned Dry Run Count',
        hint: 'Number of full dress rehearsals planned'),
    Field('dryRunSchedule', String, 'Dry Run Schedule',
        hint: 'Dates for each dry run'),
    Field('hypercareDuration', String, 'Hypercare Duration',
        hint: 'Post-migration intensive support period'),
  ])
  String? content;
}

/// 13.5.1. Migration Phases.
///
/// Staged migration phases defining the sequential or overlapping
/// execution plan. Each phase targets a specific data domain or source
/// system, with defined methods, transformation rules, validation
/// criteria, and dry run expectations.
@SectionId('MIPH')
class MigrationPhases {
  @Form([
    // --- Phase Summary ---
    Field('totalPhases', String, 'Total Phases',
        hint:
            'Number of distinct migration phases — e.g. 5 phases '
            'covering 3 source systems',
        required: true),
    Field('phaseExecutionModel', String, 'Phase Execution Model',
        hint:
            'Sequential / Overlapping / Parallel / '
            'WaterfallWithinAgileAcross — how phases relate '
            'temporally',
        required: true),
    Field('longestPhase', String, 'Longest Phase',
        hint:
            'Phase with longest duration and its expected '
            'timeframe — e.g. Phase 2 (ERP data): 6 weeks'),
    Field('criticalPathPhases', String, 'Critical Path Phases',
        hint:
            'Phases on the critical path that determine overall '
            'migration timeline'),
    Field('totalDataVolumeAcrossPhases', String,
        'Total Data Volume Across Phases',
        hint:
            'Aggregate data volume — e.g. 2.1 TB structured + '
            '400 GB documents'),
    Field('overallValidationStrategy', String,
        'Overall Validation Strategy',
        hint:
            'Cross-phase validation approach — automated '
            'reconciliation, business rule suites, sampling '
            'methodology'),
    Field('phaseDependencySummary', String,
        'Phase Dependency Summary',
        hint:
            'Key inter-phase dependencies — e.g. Phase 2 requires '
            'master data from Phase 1, Phase 4 requires Phase 3 '
            'reference data'),
    Field('dryRunStrategy', String, 'Dry Run Strategy',
        hint:
            'How dry runs are organized — per phase, combined, '
            'incremental buildup, production-equivalent'),
  ])
  String? content;

  /// Phase overview narrative.
  @ContentHelp('Overview of migration phases: sequencing rationale, '
      'parallel vs sequential execution, phase dependencies, '
      'resource allocation across phases, quality gates between '
      'phases, aggregate validation approach.')
  TextSection phaseOverview = TextSection();

  /// Contains 1+× MigrationPhaseEntry.
  @SectionId('MGPHS-ITEM-LST')
  @SectionIdPattern('MGPHS-ITEM-xxx')
  @Min(1)
  List<MigrationPhaseEntry> items = [];
}

/// A migration phase entry (form).
///
/// Represents a single migration phase targeting a specific data domain,
/// source system, or entity group. Covers data scope analysis, migration
/// method selection, transformation mapping, scheduling, dependency
/// tracking, validation approach, acceptance criteria, and dry run
/// results.
@SectionId('MGPHS')
class MigrationPhaseEntry {
  @Form([
    Field('phaseNumber', String, 'Phase Number',
        hint: '1, 2, 3… — sequential phase ordering',
        required: true),
    Field('phaseName', String, 'Phase Name',
        hint: 'Descriptive name — e.g. Master Data, Transactional History',
        required: true),
    Field('phaseType', String, 'Phase Type',
        hint: 'MasterData / ReferenceData / Transactional / Historical / Documents',
        required: true),
  ])
  String? content;

  /// Phase identity details.
  MigrationPhaseIdentity identity = MigrationPhaseIdentity();

  /// Data scope.
  MigrationPhaseDataScope dataScope = MigrationPhaseDataScope();

  /// Migration method.
  MigrationPhaseMethod method = MigrationPhaseMethod();

  /// Transformation and mapping.
  MigrationPhaseTransformation transformation = MigrationPhaseTransformation();

  /// Schedule and dependencies.
  MigrationPhaseSchedule schedule = MigrationPhaseSchedule();

  /// Dry runs.
  @SectionId('MPDR-DRYR-LST')
  @SectionIdPattern('MPDR-DRYR-xxx')
  List<MigrationPhaseDryRuns> dryRuns = [];

  /// Validation and reconciliation.
  MigrationPhaseValidation validation = MigrationPhaseValidation();

  /// Acceptance criteria.
  MigrationPhaseAcceptance acceptance = MigrationPhaseAcceptance();

  /// Rollback.
  MigrationPhaseRollback rollback = MigrationPhaseRollback();

  /// Resources.
  @SectionId('MIPHRE-RESO-LST')
  @SectionIdPattern('MIPHRE-RESO-xxx')
  List<MigrationPhaseResources> resources = [];

  /// Status.
  MigrationPhaseStatus status = MigrationPhaseStatus();
}

/// Phase identity for migration phase.
@SectionId('MIPHID')
class MigrationPhaseIdentity {
  @Form([
    Field('phaseDescription', String, 'Phase Description',
        hint: 'Detailed description of what this phase migrates'),
    Field('phaseObjective', String, 'Phase Objective',
        hint: 'Primary goal of this migration phase'),
    Field('linkedProjectStage', String, 'Linked Project Stage',
        hint: 'Which system stage this phase supports'),
  ])
  String? content;
}

/// Data scope for migration phase.
@SectionId('MPDS')
class MigrationPhaseDataScope {
  @Form([
    Field('sourceSystems', String, 'Source Systems',
        hint: 'Source system(s) for this phase',
        required: true),
    Field('sourceDatabase', String, 'Source Database / Store',
        hint: 'Specific database, file store, or API'),
    Field('tablesOrEntities', String, 'Tables / Entities',
        hint: 'List of tables, collections, or entities',
        required: true),
    Field('totalRecordCount', String, 'Total Record Count',
        hint: 'Aggregate record count for this phase',
        required: true),
    Field('dataVolumeGB', String, 'Data Volume (GB)',
        hint: 'Total data volume'),
    Field('dataFormats', String, 'Data Formats',
        hint: 'Source data formats'),
    Field('targetDestination', String, 'Target Destination',
        hint: 'Target system and location'),
    Field('dataClassification', String, 'Data Classification',
        hint: 'Public / Internal / Confidential / Restricted / PII / PHI',
        required: true),
    Field('piiFields', String, 'PII Fields Identified',
        hint: 'Personal data fields requiring special handling'),
    Field('dataOwner', String, 'Data Owner',
        hint: 'Business owner of this data domain'),
  ])
  String? content;
}

/// Migration method for migration phase.
@SectionId('MIPHME')
class MigrationPhaseMethod {
  @Form([
    Field('migrationMethod', String, 'Migration Method',
        hint: 'ETL / ELT / API / CDC / BulkLoad / DatabaseReplication',
        required: true),
    Field('etlToolUsed', String, 'ETL/Migration Tool',
        hint: 'Specific tool used for migration'),
    Field('extractionMethod', String, 'Extraction Method',
        hint: 'FullExtract / IncrementalExtract / CDC / LogicalReplication',
        required: true),
    Field('extractionSchedule', String, 'Extraction Schedule',
        hint: 'When extraction runs'),
    Field('loadStrategy', String, 'Load Strategy',
        hint: 'BulkInsert / UpsertMerge / TruncateAndReload / AppendOnly'),
  ])
  String? content;
}

/// Transformation and mapping for migration phase.
@SectionId('MIPHTR')
class MigrationPhaseTransformation {
  @Form([
    Field('transformationRulesSummary', String, 'Transformation Rules Summary',
        hint: 'Key transformations applied'),
    Field('mappingComplexity', String, 'Mapping Complexity',
        hint: 'Low / Medium / High / VeryHigh',
        required: true),
    Field('totalFieldMappings', String, 'Total Field Mappings',
        hint: 'Number of field-level mappings'),
    Field('mappingDocumentLocation', String, 'Mapping Document Location',
        hint: 'Where field mapping specifications are stored'),
    Field('dataCleansingRules', String, 'Data Cleansing Rules',
        hint: 'Cleansing rules applied'),
    Field('dataEnrichmentRules', String, 'Data Enrichment Rules',
        hint: 'Enrichment during migration'),
    Field('defaultValueRules', String, 'Default Value Rules',
        hint: 'Defaults for null or missing data'),
    Field('characterEncodingHandling', String, 'Character Encoding Handling',
        hint: 'Encoding conversion approach'),
  ])
  String? content;
}

/// Schedule and dependencies for migration phase.
@SectionId('MIPHSC')
class MigrationPhaseSchedule {
  @Form([
    Field('plannedStartDate', String, 'Planned Start Date',
        required: true),
    Field('plannedEndDate', String, 'Planned End Date',
        required: true),
    Field('estimatedDuration', String, 'Estimated Duration',
        hint: 'e.g. 3 weeks, 10 business days'),
    Field('actualStartDate', String, 'Actual Start Date',
        hint: 'Populated when phase begins'),
    Field('actualEndDate', String, 'Actual End Date',
        hint: 'Populated when phase completes'),
    Field('prerequisitePhases', String, 'Prerequisite Phases',
        hint: 'Phases that must complete first'),
    Field('parallelPhases', String, 'Parallel Phases',
        hint: 'Phases that can run concurrently'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'Dependencies outside migration'),
    Field('infrastructureDependencies', String, 'Infrastructure Dependencies',
        hint: 'Required infrastructure'),
  ])
  String? content;
}

/// Dry runs for migration phase.
@SectionId('MPDR')
class MigrationPhaseDryRuns {
  @Form([
    Field('dryRunsPlanned', String, 'Dry Runs Planned',
        hint: 'Number of rehearsals'),
    Field('dryRunSchedule', String, 'Dry Run Schedule',
        hint: 'Dates for rehearsals'),
    Field('lastDryRunDate', String, 'Last Dry Run Date',
        hint: 'Date of the most recent dry run'),
    Field('lastDryRunDuration', String, 'Last Dry Run Duration',
        hint: 'How long the last dry run took'),
    Field('lastDryRunResult', String, 'Last Dry Run Result',
        hint: 'Passed / PassedWithIssues / Failed'),
    Field('dryRunIssuesFound', String, 'Dry Run Issues Found',
        hint: 'Issues discovered'),
    Field('dryRunIssuesResolved', String, 'Dry Run Issues Resolved',
        hint: 'How many issues were fixed'),
  ])
  String? content;
}

/// Validation and reconciliation for migration phase.
@SectionId('MIPHVA')
class MigrationPhaseValidation {
  @Form([
    Field('validationApproach', String, 'Validation Approach',
        hint: 'Automated / Manual / Hybrid',
        required: true),
    Field('rowCountReconciliation', String, 'Row Count Reconciliation',
        hint: 'Source vs target row count comparison'),
    Field('checksumValidation', String, 'Checksum Validation',
        hint: 'Hash/checksum approach'),
    Field('businessRuleValidation', String, 'Business Rule Validation',
        hint: 'Business logic checks'),
    Field('samplingStrategy', String, 'Sampling Strategy',
        hint: 'Statistical sampling approach'),
    Field('dataIntegrityChecks', String, 'Data Integrity Checks',
        hint: 'Referential integrity validation'),
    Field('nullAnalysis', String, 'Null/Missing Data Analysis',
        hint: 'How nulls are tracked'),
    Field('validationToolUsed', String, 'Validation Tool',
        hint: 'Tool for validation'),
    Field('validationReportLocation', String, 'Validation Report Location',
        hint: 'Where validation results are stored'),
  ])
  String? content;
}

/// Acceptance criteria for migration phase.
@SectionId('MIPHAC')
class MigrationPhaseAcceptance {
  @Form([
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Conditions for phase sign-off',
        required: true),
    Field('acceptanceSignoffOwner', String, 'Acceptance Sign-off Owner',
        hint: 'Person who signs off on phase completion'),
    Field('acceptanceSignoffDate', String, 'Acceptance Sign-off Date',
        hint: 'Date when sign-off was granted'),
  ])
  String? content;
}

/// Rollback for migration phase.
@SectionId('MIPHRO')
class MigrationPhaseRollback {
  @Form([
    Field('phaseRollbackStrategy', String, 'Phase Rollback Strategy',
        hint: 'TruncateAndRevert / RestoreFromBackup / ReverseTransform'),
    Field('phaseRollbackTimeBudget', String, 'Rollback Time Budget',
        hint: 'Maximum time to rollback this phase'),
  ])
  String? content;
}

/// Resources for migration phase.
@SectionId('MIPHRE')
class MigrationPhaseResources {
  @Form([
    Field('assignedTeamMembers', String, 'Assigned Team Members',
        hint: 'Team members for this phase'),
    Field('estimatedEffort', String, 'Estimated Effort',
        hint: 'Person-days of effort'),
  ])
  String? content;
}

/// Status for migration phase.
@SectionId('MIPHST')
class MigrationPhaseStatus {
  @Form([
    Field('currentStatus', String, 'Current Status',
        hint: 'NotStarted / InDesign / InDevelopment / InTesting / Completed'),
    Field('completionPercentage', String, 'Completion %',
        hint: '0-100 — current progress'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or special instructions'),
  ])
  String? content;
}

/// 13.5.2. Migration Risks.
///
/// Risk register specific to data migration activities. Covers data
/// loss, corruption, downtime overrun, compliance violations,
/// performance degradation, and organizational readiness risks.
@SectionId('STMIRI')
class StageMigrationRisks {
  @Form([
    // --- Risk Summary ---
    Field('totalIdentifiedRisks', String,
        'Total Identified Risks',
        hint:
            'Number of migration-specific risks — e.g. 18 risks '
            'across 5 categories',
        required: true),
    Field('criticalRiskCount', String, 'Critical Risk Count',
        hint:
            'Number of risks rated Critical or High — requiring '
            'active mitigation'),
    Field('topRiskSummary', String, 'Top Risk Summary',
        hint:
            'Brief summary of highest-priority risks — e.g. data '
            'loss during cutover, downtime overrun, PII exposure'),
    Field('riskAssessmentMethodology', String,
        'Risk Assessment Methodology',
        hint:
            'QuantitativeMatrix / QualitativeScale / '
            'BowtieAnalysis / FMEA / Custom — how risks are '
            'scored'),
    Field('riskTolerancePolicy', String,
        'Risk Tolerance Policy',
        hint:
            'Organizational risk tolerance — no Critical risks '
            'accepted, High must have mitigation plan, Medium '
            'monitored'),
    Field('riskReviewFrequency', String, 'Risk Review Frequency',
        hint:
            'How often risks are reviewed — weekly during active '
            'migration, biweekly during planning, daily during '
            'cutover'),
    Field('riskRegisterOwner', String, 'Risk Register Owner',
        hint:
            'Person maintaining the migration risk register — '
            'typically Migration Lead or Project Manager'),
    Field('lastRiskReviewDate', String, 'Last Risk Review Date',
        hint: 'Date risks were last formally reviewed'),
    Field('overallMigrationRiskRating', String,
        'Overall Migration Risk Rating',
        hint:
            'Low / Medium / High / Critical — aggregate risk '
            'assessment for the entire migration'),
  ])
  String? content;

  /// Risk summary narrative.
  @ContentHelp('Executive summary of migration risks: top risk categories, '
      'aggregate risk level, key mitigation strategies, '
      'contingency approaches, risk monitoring plan, '
      'escalation triggers and paths.')
  TextSection riskSummary = TextSection();

  /// Contains 1+× StageMigrationRiskEntry.
  @SectionId('STGMRS-ITEM-LST')
  @SectionIdPattern('STGMRS-ITEM-xxx')
  @Min(1)
  List<StageMigrationRiskEntry> items = [];
}

/// A stage migration risk entry (form).
///
/// Individual risk in the data migration risk register. Covers risk
/// identification, categorization, probability/impact scoring,
/// mitigation planning, contingency actions, trigger indicators,
/// ownership, monitoring approach, and residual risk after mitigation.
@SectionId('STGMRS')
class StageMigrationRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID',
        hint: 'Unique identifier — e.g. MIG-R001, MIG-R002',
        required: true),
    Field('riskName', String, 'Risk Name',
        hint: 'Short descriptive name — e.g. Data Loss During Cutover',
        required: true),
    Field('riskCategory', String, 'Risk Category',
        hint: 'DataLoss / DataCorruption / DowntimeOverrun / SecurityBreach',
        required: true),
  ])
  String? content;

  /// Risk identity and description.
  StageMigrationRiskIdentity identity = StageMigrationRiskIdentity();

  /// Probability and impact assessment.
  StageMigrationRiskProbabilityImpact probabilityImpact =
      StageMigrationRiskProbabilityImpact();

  /// Mitigation planning.
  StageMigrationRiskMitigation mitigation =
      StageMigrationRiskMitigation();

  /// Contingency actions.
  StageMigrationRiskContingency contingency =
      StageMigrationRiskContingency();

  /// Monitoring and detection.
  StageMigrationRiskMonitoring monitoring =
      StageMigrationRiskMonitoring();

  /// Ownership and accountability.
  StageMigrationRiskOwnership ownership = StageMigrationRiskOwnership();

  /// Residual risk assessment.
  StageMigrationRiskResidual residual = StageMigrationRiskResidual();

  /// Status and review.
  StageMigrationRiskStatus status = StageMigrationRiskStatus();
}

/// Risk identity and description.
@SectionId('SMRI')
class StageMigrationRiskIdentity {
  @Form([
    Field('riskDescription', String, 'Risk Description',
        hint: 'Detailed description of the risk scenario',
        required: true),
  ])
  String? content;
}

/// Probability and impact assessment.
@SectionId('SMRPI')
class StageMigrationRiskProbabilityImpact {
  @Form([
    Field('probability', String, 'Probability',
        hint: 'VeryLow / Low / Medium / High / VeryHigh',
        required: true),
    Field('impact', String, 'Impact',
        hint: 'Negligible / Minor / Moderate / Major / Critical',
        required: true),
    Field('riskScore', String, 'Risk Score',
        hint: 'Calculated risk rating — Probability x Impact'),
    Field('impactAreas', String, 'Impact Areas',
        hint: 'DataIntegrity / SystemAvailability / Compliance / Budget'),
    Field('affectedPhases', String, 'Affected Phases',
        hint: 'Which migration phases are exposed'),
  ])
  String? content;
}

/// Mitigation planning.
@SectionId('SMRM')
class StageMigrationRiskMitigation {
  @Form([
    Field('mitigationStrategy', String, 'Mitigation Strategy',
        hint: 'Planned actions to reduce probability or impact',
        required: true),
    Field('mitigationOwner', String, 'Mitigation Owner',
        hint: 'Person responsible for implementing mitigation'),
    Field('mitigationStatus', String, 'Mitigation Status',
        hint: 'NotStarted / InProgress / Implemented / Verified'),
    Field('mitigationDeadline', String, 'Mitigation Deadline',
        hint: 'Date by which mitigation must be in place'),
  ])
  String? content;
}

/// Contingency actions.
@SectionId('SMRC')
class StageMigrationRiskContingency {
  @Form([
    Field('contingencyPlan', String, 'Contingency Plan',
        hint: 'Actions if risk materializes despite mitigation',
        required: true),
    Field('contingencyTrigger', String, 'Contingency Trigger',
        hint: 'Measurable condition that activates contingency'),
    Field('contingencyBudget', String, 'Contingency Budget',
        hint: 'Reserved budget for contingency'),
  ])
  String? content;
}

/// Monitoring and detection.
@SectionId('SMRM1')
class StageMigrationRiskMonitoring {
  @Form([
    Field('triggerIndicators', String, 'Trigger Indicators',
        hint: 'Early warning signs — dry run failures, error counts'),
    Field('monitoringApproach', String, 'Monitoring Approach',
        hint: 'How risk is tracked — dashboards, status checks'),
    Field('monitoringFrequency', String, 'Monitoring Frequency',
        hint: 'Continuous / Daily / Weekly / PerPhase / PerDryRun'),
    Field('alertThresholds', String, 'Alert Thresholds',
        hint: 'Thresholds triggering alerts'),
  ])
  String? content;
}

/// Ownership and accountability.
@SectionId('SMRO')
class StageMigrationRiskOwnership {
  @Form([
    Field('riskOwner', String, 'Risk Owner',
        hint: 'Person accountable for managing this risk',
        required: true),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation chain if risk materializes'),
  ])
  String? content;
}

/// Residual risk assessment.
@SectionId('SMRR')
class StageMigrationRiskResidual {
  @Form([
    Field('residualProbability', String, 'Residual Probability',
        hint: 'VeryLow / Low / Medium / High — after mitigation'),
    Field('residualImpact', String, 'Residual Impact',
        hint: 'Negligible / Minor / Moderate / Major — after mitigation'),
    Field('residualRiskAcceptable', String, 'Residual Risk Acceptable',
        hint: 'Yes / No / Conditional'),
  ])
  String? content;
}

/// Status and review.
@SectionId('SMRS')
class StageMigrationRiskStatus {
  @Form([
    Field('currentStatus', String, 'Current Status',
        hint: 'Open / Mitigated / Materialized / Closed / Accepted'),
    Field('lastReviewDate', String, 'Last Review Date',
        hint: 'When this risk was last reviewed'),
    Field('notes', String, 'Notes',
        hint: 'Additional context — lessons learned, related incidents'),
  ])
  String? content;
}

/// 13.6. Governance.
///
/// Governance framework for stage transitions, phase gate reviews,
/// and key decision points. Covers governance structure, authority
/// model, escalation paths, compliance requirements, and the
/// ceremonies that control stage advancement. Aligns with PMBOK
/// governance gates, SAFe Program Increment boundaries, PRINCE2
/// stage gates, and TOGAF architecture governance.
@SectionId('STGO')
@MapsTo(D11DeliveryRoadmap)
class StageGovernance {
  @Form([
    Field('governanceModel', String, 'Governance Model',
        hint: 'PhaseGate / Agile / Hybrid / Continuous / Federated',
        required: true),
    Field('governanceFramework', String, 'Governance Framework',
        hint: 'PMBOK / PRINCE2 / SAFe / DAD / Custom',
        required: true),
    Field('decisionMakingModel', String, 'Decision-Making Model',
        hint: 'Consensus / MajorityVote / DelegatedAuthority / RACI-based',
        required: true),
  ])
  String? content;

  /// Governance model details.
  StageGovernanceModel model = StageGovernanceModel();

  /// Authority and oversight.
  StageGovernanceAuthority authority = StageGovernanceAuthority();

  /// Escalation paths and triggers.
  StageGovernanceEscalation escalation = StageGovernanceEscalation();

  /// Meeting cadence and process.
  StageGovernanceCadence cadence = StageGovernanceCadence();

  /// Compliance and audit requirements.
  StageGovernanceCompliance compliance = StageGovernanceCompliance();

  /// Metrics and reporting.
  StageGovernanceMetrics metrics = StageGovernanceMetrics();

  /// Stage transition rules.
  StageGovernanceTransition transition = StageGovernanceTransition();

  /// Governance narrative and rationale.
  @ContentHelp('Stage governance philosophy: decision-making framework, '
      'authority levels, escalation paths, review cadence, '
      'documentation requirements, communication protocols, '
      'emergency bypass procedures.')
  TextSection governanceNarrative = TextSection();

  /// 13.6.1. Phase Gate Reviews.
  PhaseGateReviews phaseGateReviews = PhaseGateReviews();

  /// 13.6.2. Decision Points.
  DecisionPoints decisionPoints = DecisionPoints();
}

/// Governance model details.
@SectionId('STGOMO')
class StageGovernanceModel {
  @Form([
    Field('governanceCharter', String, 'Governance Charter',
        hint: 'Name or reference to the formal governance charter document'),
  ])
  String? content;
}

/// Authority and oversight.
@SectionId('STGOAU')
class StageGovernanceAuthority {
  @Form([
    Field('governanceBoardName', String, 'Governance Board Name',
        hint: 'Steering Committee, PMO, Architecture Review Board'),
    Field('governanceBoardChair', String, 'Governance Board Chair',
        hint: 'Person chairing the governance body'),
    Field('boardMembers', String, 'Board Members',
        hint: 'Roles or names on the board — comma-separated'),
    Field('quorumRequirement', String, 'Quorum Requirement',
        hint: 'Minimum attendance for valid decisions'),
    Field('delegatedAuthorityThreshold', String,
        'Delegated Authority Threshold',
        hint: 'Decisions the PM can make without board'),
  ])
  String? content;
}

/// Escalation paths and triggers.
@SectionId('STGOES')
class StageGovernanceEscalation {
  @Form([
    Field('escalationPath', String, 'Escalation Path',
        hint: 'PM → Program Manager → Steering Committee'),
    Field('escalationTriggers', String, 'Escalation Triggers',
        hint: 'Conditions requiring escalation'),
    Field('escalationTimeframe', String, 'Escalation Timeframe',
        hint: 'Maximum time before escalation'),
  ])
  String? content;
}

/// Meeting cadence and process.
@SectionId('STGOCA')
class StageGovernanceCadence {
  @Form([
    Field('governanceMeetingCadence', String, 'Governance Meeting Cadence',
        hint: 'PerStage / Monthly / Quarterly / OnDemand',
        required: true),
    Field('meetingDuration', String, 'Meeting Duration',
        hint: 'Typical meeting length'),
    Field('meetingFormat', String, 'Meeting Format',
        hint: 'InPerson / Virtual / Hybrid'),
    Field('agendaTemplate', String, 'Agenda Template',
        hint: 'Standard agenda structure'),
    Field('minutesDistribution', String, 'Minutes Distribution',
        hint: 'How minutes are distributed'),
  ])
  String? content;
}

/// Compliance and audit requirements.
@SectionId('STGOCO')
class StageGovernanceCompliance {
  @Form([
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint: 'SOX, ISO 27001, GDPR, internal audit policies'),
    Field('auditTrailRequirement', String, 'Audit Trail Requirement',
        hint: 'What must be recorded — decisions, rationale, attendance',
        required: true),
    Field('documentRetentionPolicy', String, 'Document Retention Policy',
        hint: 'How long governance records are retained'),
    Field('externalAuditIntegration', String, 'External Audit Integration',
        hint: 'None / Annual / PerMajorGate'),
  ])
  String? content;
}

/// Metrics and reporting.
@SectionId('STGOME')
class StageGovernanceMetrics {
  @Form([
    Field('governanceKpis', String, 'Governance KPIs',
        hint: 'Gate pass rate, decision cycle time, escalation frequency'),
    Field('reportingFrequency', String, 'Reporting Frequency',
        hint: 'Weekly / Monthly / PerGate'),
    Field('dashboardLocation', String, 'Dashboard Location',
        hint: 'Where governance status is visible'),
  ])
  String? content;
}

/// Stage transition rules.
@SectionId('STGOTR')
class StageGovernanceTransition {
  @Form([
    Field('stageTransitionPolicy', String, 'Stage Transition Policy',
        hint: 'Rules for moving between stages',
        required: true),
    Field('conditionalAdvancementRules', String,
        'Conditional Advancement Rules',
        hint: 'Conditions for advancing with open items'),
    Field('rollbackPolicy', String, 'Rollback Policy',
        hint: 'Rules for reverting to a prior stage'),
    Field('emergencyBypassProcess', String, 'Emergency Bypass Process',
        hint: 'Expedited review, post-hoc ratification'),
  ])
  String? content;
}

/// 13.6.1. Phase Gate Reviews.
///
/// Defines the phase gate review process: what is reviewed at each
/// gate, who participates, what evidence is required, and what
/// outcomes are possible (proceed, rework, cancel, conditional).
@SectionId('PHGARE')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-GAT')
class PhaseGateReviews {
  @Form([
    Field('gateNamingConvention', String,
        'Gate Naming Convention',
        hint:
            'How gates are named — G0/G1/G2, Alpha/Beta/GA, '
            'or stage-aligned like Stage1Exit'),
    Field('totalGateCount', String, 'Total Gate Count',
        hint: 'Number of formal gates in the stage plan'),
    Field('gateReviewDuration', String,
        'Typical Gate Review Duration',
        hint:
            'Default duration for a gate review session — '
            'e.g. 2 hours, half-day'),
    Field('gateReviewFormat', String, 'Gate Review Format',
        hint:
            'Presentation / Checklist / DemoAndReview / '
            'DocumentReview / Mixed'),
  ])
  String? content;

  /// Standard participants and evidence package.
  PhaseGateReviewsPreparation preparation = PhaseGateReviewsPreparation();

  /// Gate decision outcomes and follow-up rules.
  PhaseGateReviewsOutcomes outcomes = PhaseGateReviewsOutcomes();

  /// Phase gate review process narrative.
  @ContentHelp('Phase gate process description: gate objectives, '
      'review rhythm, participant roles, evidence gathering, '
      'decision criteria, proceed/rework/cancel definitions, '
      'conditional approval handling.')
  TextSection gateReviewNarrative = TextSection();

  /// Contains 0+× PhaseGateReviewEntry.
  @SectionId('PGRE-ITEM-LST')
  @SectionIdPattern('PGRE-ITEM-xxx')
  List<PhaseGateReviewEntry> items = [];
}

/// Standard participants and evidence package.
@SectionId('PGRP')
class PhaseGateReviewsPreparation {
  @Form([
    Field('mandatoryAttendees', String, 'Mandatory Attendees',
        hint:
            'Roles required at every gate — Sponsor, PM, '
            'TechLead, QA Lead, Business Owner'),
    Field('optionalAttendees', String, 'Optional Attendees',
        hint:
            'Roles invited as needed — Security, Legal, UX, '
            'Operations'),
    Field('standardEvidencePackage', String,
        'Standard Evidence Package',
        hint:
            'Artifacts required at every gate — status report, '
            'test results, risk register, budget actuals, '
            'demo recording'),
    Field('evidenceSubmissionDeadline', String,
        'Evidence Submission Deadline',
        hint:
            'When evidence must be submitted before the gate — '
            'e.g. 3 business days prior'),
  ])
  String? content;
}

/// Gate decision outcomes and follow-up rules.
@SectionId('PGRO')
class PhaseGateReviewsOutcomes {
  @Form([
    Field('possibleOutcomes', String, 'Possible Outcomes',
        hint:
            'Proceed / ConditionalProceed / Rework / Hold / '
            'Cancel — possible gate decisions',
        required: true),
    Field('conditionalProceedRules', String,
        'Conditional Proceed Rules',
        hint:
            'Conditions under which conditional approval is '
            'allowed — time-boxed remediation, risk accepted'),
    Field('reworkProcessDefinition', String,
        'Rework Process Definition',
        hint:
            'What happens on rework decision — scope, timeline, '
            're-review scheduling'),
    Field('cancelProcessDefinition', String,
        'Cancel Process Definition',
        hint:
            'What happens on cancel — asset disposition, team '
            'reassignment, lessons learned'),
  ])
  String? content;
}

/// A phase gate review entry (form).
///
/// Defines a single phase gate with its criteria, participants,
/// required evidence, entry/exit conditions, and review schedule.
@SectionId('PGRE1')
class PhaseGateReviewEntry {
  @Form([
    Field('gateName', String, 'Gate Name',
        hint: 'Formal gate name — e.g. G1-ConceptApproval', required: true),
    Field('gateId', String, 'Gate ID',
        hint: 'Unique gate identifier — e.g. G1, G2, G3'),
    Field('stage', String, 'Stage',
        hint: 'Stage this gate is associated with', required: true),
  ])
  String? content;

  /// Gate identity.
  PhaseGateIdentity identity = PhaseGateIdentity();

  /// Authority and participants.
  PhaseGateAuthority authority = PhaseGateAuthority();

  /// Schedule.
  PhaseGateSchedule schedule = PhaseGateSchedule();

  /// Entry conditions.
  PhaseGateEntry entry = PhaseGateEntry();

  /// Evidence.
  PhaseGateEvidence evidence = PhaseGateEvidence();

  /// Exit conditions and outcome.
  PhaseGateExit exit = PhaseGateExit();

  /// Gate-specific narrative and context.
  @ContentHelp('Context for this specific gate: strategic importance, '
      'relationship to prior and subsequent gates, '
      'unique considerations, historical lessons applied.')
  TextSection gateNarrative = TextSection();

  /// Contains 0+× ReviewCriterionEntry.
  @SectionId('RVCRI-REVI-LST')
  @SectionIdPattern('RVCRI-REVI-xxx')
  List<ReviewCriterionEntry> reviewCriteria = [];
}

/// Gate identity.
@SectionId('PHGAID')
class PhaseGateIdentity {
  @Form([
    Field('gateDescription', String, 'Gate Description',
        hint: 'Purpose of this gate — what it validates'),
    Field('gatePosition', String, 'Gate Position',
        hint: 'StageEntry / MidStage / StageExit / CrossStage'),
  ])
  String? content;
}

/// Authority and participants.
@SectionId('PHGAAU')
class PhaseGateAuthority {
  @Form([
    Field('decisionAuthority', String, 'Decision Authority',
        hint: 'Person or body with final decision power', required: true),
    Field('mandatoryParticipants', String, 'Mandatory Participants',
        hint: 'Roles who must attend — comma-separated'),
    Field('advisoryParticipants', String, 'Advisory Participants',
        hint: 'Roles who participate in advisory capacity'),
    Field('externalParticipants', String, 'External Participants',
        hint: 'External stakeholders — auditors, customer reps'),
  ])
  String? content;
}

/// Schedule.
@SectionId('PHGASC')
class PhaseGateSchedule {
  @Form([
    Field('scheduledDate', String, 'Scheduled Date',
        hint: 'Planned date for this gate review'),
    Field('preparationLeadTime', String, 'Preparation Lead Time',
        hint: 'Days needed to prepare — e.g. 5 business days'),
    Field('reviewDuration', String, 'Review Duration',
        hint: 'Expected duration — e.g. 2 hours, 4 hours'),
  ])
  String? content;
}

/// Entry conditions.
@SectionId('PHGAEN')
class PhaseGateEntry {
  @Form([
    Field('entryCriteria', String, 'Entry Criteria',
        hint: 'Conditions that must be met before the gate'),
    Field('entryChecklistComplete', String, 'Entry Checklist Complete',
        hint: 'Yes / No / Partial — whether entry conditions verified'),
  ])
  String? content;
}

/// Evidence.
@SectionId('PHGAEV')
class PhaseGateEvidence {
  @Form([
    Field('requiredEvidence', String, 'Required Evidence',
        hint: 'Artifacts to be presented — test reports, demo'),
    Field('evidenceFormat', String, 'Evidence Format',
        hint: 'How evidence is presented — slide deck, live demo'),
    Field('evidenceLocation', String, 'Evidence Location',
        hint: 'Where evidence is stored — SharePoint folder, wiki'),
  ])
  String? content;
}

/// Exit conditions and outcome.
@SectionId('PHGAEX')
class PhaseGateExit {
  @Form([
    Field('exitCriteria', String, 'Exit Criteria',
        hint: 'What must be true for the gate to pass', required: true),
    Field('minimumPassThreshold', String, 'Minimum Pass Threshold',
        hint: 'Quantified threshold — e.g. ≥80% criteria met'),
    Field('gateOutcome', String, 'Gate Outcome',
        hint: 'Proceed / ConditionalProceed / Rework / Hold / Cancel'),
    Field('outcomeRationale', String, 'Outcome Rationale',
        hint: 'Why this decision was made'),
    Field('conditionalItems', String, 'Conditional Items',
        hint: 'Open items for conditional advancement'),
    Field('followUpActions', String, 'Follow-Up Actions',
        hint: 'Actions assigned during review'),
    Field('nextGateReference', String, 'Next Gate Reference',
        hint: 'Gate ID of the next gate in sequence'),
  ])
  String? content;
}

/// A review criterion entry (form).
///
/// A single criterion evaluated at a phase gate, with weight,
/// evidence linkage, and assessment result.
@SectionId('RVCRI')
class ReviewCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion',
        hint:
            'What is being evaluated — e.g. All unit tests pass, '
            'Security review complete, UX approval obtained',
        required: true),
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier — e.g. GRC-01'),
    Field('description', String, 'Description',
        hint:
            'Detailed description of what this criterion covers'),
    Field('category', String, 'Category',
        hint:
            'Quality / Security / Compliance / Performance / '
            'Completeness / Business / Operational'),
  ])
  String? content;

  /// How this criterion is measured and weighted.
  ReviewCriterionEntryAssessment assessment =
      ReviewCriterionEntryAssessment();

  /// Post-review result and remediation status.
  ReviewCriterionEntryResult result = ReviewCriterionEntryResult();
}

/// How this criterion is measured and weighted.
@SectionId('RCEA')
class ReviewCriterionEntryAssessment {
  @Form([
    Field('weight', String, 'Weight',
        hint:
            'Relative importance — percentage, 1-10, or '
            'Critical/Major/Minor'),
    Field('isMandatory', String, 'Is Mandatory',
        hint:
            'Yes / No — whether failure blocks gate passage '
            'regardless of other criteria'),
    Field('measurementMethod', String, 'Measurement Method',
        hint:
            'How this criterion is measured — automated test, '
            'manual review, checklist, metric threshold'),
    Field('acceptableThreshold', String, 'Acceptable Threshold',
        hint:
            'Pass threshold — e.g. ≥95% test coverage, 0 '
            'critical defects, all stakeholders signed off'),
    Field('evidenceRequired', String, 'Evidence Required',
        hint:
            'What evidence proves this criterion — test report, '
            'sign-off email, audit log, screenshot'),
  ])
  String? content;
}

/// Post-review result and remediation status.
@SectionId('RCER')
class ReviewCriterionEntryResult {
  @Form([
    Field('assessmentResult', String, 'Assessment Result',
        hint:
            'Pass / Fail / ConditionalPass / NotAssessed — '
            'actual result after review'),
    Field('assessmentNotes', String, 'Assessment Notes',
        hint:
            'Reviewer notes — findings, concerns, conditions'),
    Field('remediationRequired', String, 'Remediation Required',
        hint:
            'What must be fixed if failed — description and '
            'deadline'),
  ])
  String? content;
}

/// 13.6.2. Decision Points.
///
/// Key decision points in the stage plan including go/no-go
/// decisions, scope adjustments, resource reallocations, and
/// technology selections. Each decision point has defined timing,
/// criteria, authority, options, and impact analysis.
@SectionId('DEPO')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-DEC')
class DecisionPoints {
  @Form([
    // --- Decision Framework ---
    Field('totalDecisionPoints', String, 'Total Decision Points',
        hint: 'Number of formal decision points defined'),
    Field('decisionRecordingMethod', String,
        'Decision Recording Method',
        hint:
            'How decisions are documented — ADR, decision log, '
            'meeting minutes, wiki'),
    Field('decisionTemplateReference', String,
        'Decision Template Reference',
        hint:
            'Reference to the decision record template — ADR '
            'template, DACI template'),
    Field('decisionCategories', String, 'Decision Categories',
        hint:
            'GoNoGo / ScopeChange / ResourceReallocation / '
            'TechnologySelection / VendorSelection / '
            'ArchitectureChange / RiskResponse — comma-separated'),
    Field('decisionTrackingTool', String,
        'Decision Tracking Tool',
        hint:
            'Tool used to track decisions — Jira, Confluence, '
            'ADR repository, DOORS'),
    Field('decisionReviewCadence', String,
        'Decision Review Cadence',
        hint:
            'How often past decisions are reviewed for '
            'validity — Never / Quarterly / PerStage / '
            'OnDemand'),
  ])
  String? content;

  /// Decision framework narrative.
  @ContentHelp('Decision-making framework: authority matrix, '
      'decision types and their governance levels, '
      'RACI for key decisions, documentation requirements, '
      'appeal processes, decision review cadence.')
  TextSection decisionFrameworkNarrative = TextSection();

  /// Contains 0+× DecisionPointEntry.
  @SectionId('DEPOEN-ITEM-LST')
  @SectionIdPattern('DEPOEN-ITEM-xxx')
  List<DecisionPointEntry> items = [];
}

/// A decision point entry (form).
///
/// A single formal decision point with defined timing, criteria,
/// authority, available options with impact analysis, and recording
/// of the actual decision and its rationale.
@SectionId('DPE')
class DecisionPointEntry {
  @Form([
    Field('decisionId', String, 'Decision ID',
        hint: 'Unique identifier — e.g. DEC-001, DP-G2-01',
        required: true),
    Field('decisionPoint', String, 'Decision Point',
        hint: 'Short name — e.g. Go/No-Go for Production, '
            'Technology Stack Selection',
        required: true),
    Field('decisionCategory', String, 'Decision Category',
        hint: 'GoNoGo / ScopeChange / ResourceReallocation / '
            'TechnologySelection / VendorSelection / '
            'ArchitectureChange / RiskResponse',
        required: true),
  ])
  String? content;

  /// Context and timing information.
  DecisionPointEntryContext context = DecisionPointEntryContext();

  /// Stakeholder assignments.
  DecisionPointEntryStakeholders stakeholders =
      DecisionPointEntryStakeholders();

  /// Criteria and required inputs.
  DecisionPointEntryCriteria criteria = DecisionPointEntryCriteria();

  /// Resolution details (filled when decided).
  DecisionPointEntryResolution resolution = DecisionPointEntryResolution();
}

/// Context and timing for decision point.
@SectionId('DPEC')
class DecisionPointEntryContext {
  @Form([
    Field('decisionDescription', String, 'Decision Description',
        hint: 'Detailed description of what needs to be decided'),
    Field('stage', String, 'Stage',
        hint: 'Stage where this decision occurs'),
    Field('timing', String, 'Timing',
        hint: 'When in the stage — StageEntry / MidStage / '
            'StageExit / BeforeGate / AfterGate / OnDemand',
        required: true),
    Field('deadline', String, 'Decision Deadline',
        hint: 'Latest date by which decision must be made — '
            'after this date, default option applies'),
    Field('triggerEvent', String, 'Trigger Event',
        hint: 'What triggers this decision point — gate outcome, '
            'risk materialization, milestone reached, '
            'stakeholder request'),
  ])
  String? content;
}

/// Stakeholder assignments for decision point.
@SectionId('DPES')
class DecisionPointEntryStakeholders {
  @Form([
    Field('decisionAuthority', String, 'Decision Authority',
        hint: 'Person or body making the final decision — DACI: '
            'Driver, Approver, Contributor, Informed',
        required: true),
    Field('decisionDriver', String, 'Decision Driver',
        hint: 'Person responsible for driving the decision to '
            'conclusion — typically PM or Product Owner'),
    Field('contributors', String, 'Contributors',
        hint: 'People providing input — architects, analysts, '
            'domain experts — comma-separated'),
    Field('informedParties', String, 'Informed Parties',
        hint: 'Stakeholders informed of the outcome — '
            'comma-separated'),
  ])
  String? content;
}

/// Criteria and inputs for decision point.
@SectionId('DPEC1')
class DecisionPointEntryCriteria {
  @Form([
    Field('decisionCriteria', String, 'Decision Criteria',
        hint: 'Criteria for making this decision — cost, risk, '
            'time, quality, strategic alignment, feasibility',
        required: true),
    Field('requiredInputs', String, 'Required Inputs',
        hint: 'Information or artifacts needed — cost analysis, '
            'risk assessment, prototype results, vendor '
            'proposals'),
    Field('constraintFactors', String, 'Constraint Factors',
        hint: 'Constraints limiting the decision space — budget, '
            'regulatory, technology, timeline'),
    Field('riskIfDelayed', String, 'Risk if Delayed',
        hint: 'Consequence of not making the decision on time — '
            'schedule slip, cost increase, missed window'),
  ])
  String? content;
}

/// Resolution details for decision point.
@SectionId('DPER')
class DecisionPointEntryResolution {
  @Form([
    Field('selectedOption', String, 'Selected Option',
        hint: 'Which option was chosen — references option ID '
            'or name'),
    Field('decisionRationale', String, 'Decision Rationale',
        hint: 'Why this option was selected — trade-off analysis '
            'summary'),
    Field('decisionDate', String, 'Decision Date',
        hint: 'When the decision was formally made'),
    Field('decisionRecordReference', String,
        'Decision Record Reference',
        hint: 'Link to the formal decision record — ADR number, '
            'meeting minutes reference'),
    Field('revisitDate', String, 'Revisit Date',
        hint: 'When this decision should be revisited — if '
            'conditions change, or after a defined period'),
    Field('impactSummary', String, 'Impact Summary',
        hint: 'Impact of the decision — affected stages, teams, '
            'budget, schedule'),
  ])
  String? content;

  /// Decision context narrative.
  @ContentHelp('Context for this decision point: strategic background, '
      'prior related decisions, constraints shaping options, '
      'stakeholder perspectives, risk considerations, '
      'organizational readiness factors.')
  TextSection decisionNarrative = TextSection();

  /// Contains 0+× DecisionOptionEntry.
  @SectionId('DEOPEN-OPTI-LST')
  @SectionIdPattern('DEOPEN-OPTI-xxx')
  List<DecisionOptionEntry> options = [];
}

/// A decision option entry (form).
///
/// One of the available options for a decision point, with full
/// impact analysis, feasibility assessment, and trade-off evaluation.
@SectionId('DOE')
class DecisionOptionEntry {
  @Form([
    Field('optionId', String, 'Option ID',
        hint: 'Unique within the decision — e.g. A, B, C',
        required: true),
    Field('option', String, 'Option Name',
        hint:
            'Short name — e.g. Build In-House, Buy Commercial, '
            'Open Source + Customize',
        required: true),
    Field('description', String, 'Description',
        hint: 'Detailed description of what this option entails'),
  ])
  String? content;

  /// Recommendation flags.
  DecisionOptionEntrySelection selection = DecisionOptionEntrySelection();

  /// Impact analysis.
  DecisionOptionEntryImpact impact = DecisionOptionEntryImpact();

  /// Feasibility assessment.
  DecisionOptionEntryFeasibility feasibility =
      DecisionOptionEntryFeasibility();

  /// Trade-offs and reversibility.
  DecisionOptionEntryTradeOffs tradeOffs = DecisionOptionEntryTradeOffs();
}

/// Recommendation flags.
@SectionId('DOES')
class DecisionOptionEntrySelection {
  @Form([
    Field('isDefault', String, 'Is Default Option',
        hint:
            'Yes / No — whether this is the fallback if no '
            'decision is reached by deadline'),
    Field('isRecommended', String, 'Is Recommended',
        hint:
            'Yes / No — whether the analysis team recommends '
            'this option'),
  ])
  String? content;
}

/// Impact analysis.
@SectionId('DOEI')
class DecisionOptionEntryImpact {
  @Form([
    Field('costImpact', String, 'Cost Impact',
        hint:
            'Estimated cost — one-time and recurring, relative '
            'or absolute'),
    Field('scheduleImpact', String, 'Schedule Impact',
        hint:
            'Effect on timeline — days/weeks of delay or '
            'acceleration, or no impact'),
    Field('qualityImpact', String, 'Quality Impact',
        hint:
            'Effect on quality — better/worse test coverage, '
            'performance, reliability'),
    Field('riskImpact', String, 'Risk Impact',
        hint:
            'New risks introduced or existing risks mitigated'),
    Field('scopeImpact', String, 'Scope Impact',
        hint:
            'Features added, removed, or modified by this '
            'choice'),
    Field('resourceImpact', String, 'Resource Impact',
        hint:
            'Team changes — additional hires, skill gaps, '
            'vendor engagement'),
  ])
  String? content;
}

/// Feasibility assessment.
@SectionId('DOEF')
class DecisionOptionEntryFeasibility {
  @Form([
    Field('technicalFeasibility', String, 'Technical Feasibility',
        hint:
            'High / Medium / Low — assessed technical '
            'feasibility'),
    Field('organizationalFeasibility', String,
        'Organizational Feasibility',
        hint:
            'High / Medium / Low — organizational readiness '
            'for this option'),
    Field('feasibilityNotes', String, 'Feasibility Notes',
        hint:
            'Key factors — skill availability, technology '
            'maturity, vendor reliability'),
  ])
  String? content;
}

/// Trade-offs and reversibility.
@SectionId('DOETO')
class DecisionOptionEntryTradeOffs {
  @Form([
    Field('advantages', String, 'Advantages',
        hint: 'Key benefits of this option — comma-separated'),
    Field('disadvantages', String, 'Disadvantages',
        hint:
            'Key drawbacks of this option — comma-separated'),
    Field('assumptions', String, 'Assumptions',
        hint:
            'Assumptions this option depends on — if invalid, '
            'option may not be viable'),
    Field('implications', String, 'Implications',
        hint:
            'Downstream consequences — architectural, '
            'contractual, operational, political'),
    Field('reversibility', String, 'Reversibility',
        hint:
            'Reversible / PartiallyReversible / Irreversible — '
            'can the decision be undone'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 13.7 Initial Development Flow
// ---------------------------------------------------------------------------

/// 13.7. Initial Development Flow.
///
/// Inter-phase dependencies during the initial build (Phases 1–7 of
/// `tom_system_creation.md`). Covers PPP-IDV content the mapping calls out
/// as "new in PPP".
@SectionId('INDEFL')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-IDV')
class InitialDevelopmentFlow {
  @ContentHelp('''
Describes how the initial-development phases hand off to each other:
dependencies, parallel work streams, and synchronization points.

**What to capture:**
- Phase dependency graph (which phase must end before another begins)
- Parallelization opportunities (work streams that can proceed concurrently)
- Synchronization points / integration checkpoints
- Shared artifact touchpoints (same document updated in multiple phases)
- Team coordination model during the initial build
- Transition criteria to post-development (where PPP-UPG takes over)
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 13.8 Upgrade Cycle Framework
// ---------------------------------------------------------------------------

/// 13.8. Upgrade Cycle Framework.
///
/// Post-development upgrade cycle framework. Links the upgrade process
/// defined in `_ai/quests/tom_specs/tom_system_upgrade.md`.
@SectionId('UPCYFR')
@DetailedIn(D11DeliveryRoadmap)
@SecondLevelSectionId(D11DeliveryRoadmap, 'PPP-UPG')
class UpgradeCycleFramework {
  @ContentHelp('''
Framework that governs the upgrade cycle once initial development
finishes. Provides the project-specific bridge to the static
`tom_system_upgrade.md` process (UC-1 … UC-7).

**What to capture:**
- Transition trigger from initial build to upgrade cycles
- Cadence / scheduling of upgrade cycles
- Change-classification policy (minor / major / emergency / hotfix)
- Gate integration with `tom_quality_gates.md`
- Regression-testing expectations per upgrade type
- Rollout strategy differences for upgrades vs. initial launch
- Version and numbering scheme
''')
  String? content;
}

/// A single key assumption entry.
@SectionId('KEYAS')
class KeyAssumptionEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}

/// A single constraint entry.
@SectionId('STAGI')
class StagingStrategyConstraintEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}
