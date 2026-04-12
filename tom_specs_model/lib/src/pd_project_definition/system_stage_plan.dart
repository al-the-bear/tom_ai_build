/// Section 13: System Stage Plan [PD00-SSP]. Seeds → PPP.
///
/// System stages are meaningful subsets of the functional system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 13. System Stage Plan [PD00-SSP]. Seeds → PPP.
///
/// Define the overall staging strategy for the system rollout. A stage
/// is a meaningful, self-contained subset of the complete system that
/// delivers measurable business value. Stages build upon each other
/// progressively until the full system is operational. Aligns with
/// PMBOK phase-gate methodology, SAFe PI planning, and PRINCE2 stage
/// boundary management.
@SectionId('PD00-SSP')
@Comment('Seeds → PPP')
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
    // --- Overall Timeline ---
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
    // --- Cross-Stage Coordination ---
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
    // --- Organizational Context ---
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
///
/// Document the rationale behind the chosen staging approach. Consider
/// PMBOK phase-gate methodology, SAFe PI planning cadence, PRINCE2
/// stage boundaries, and organizational change management constraints.
@SectionId('PD00-SSP-STR')
class StagingStrategy {
  @Form([
    // --- Approach Selection ---
    Field('stagingApproachType', String, 'Staging Approach Type',
        hint:
            'BigBang / PhasedByFunction / PhasedByGeography / '
            'PhasedByUserGroup / PhasedByBusinessUnit / Hybrid',
        required: true),
    Field('rationale', String, 'Rationale',
        hint: 'Primary reasons for choosing this staging approach',
        required: true),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint:
            'Other staging approaches evaluated and why they were '
            'rejected'),
    // --- Key Drivers ---
    Field('primaryDrivers', String, 'Key Drivers',
        hint:
            'Primary factors driving the staging approach — risk '
            'reduction, early business value, regulatory deadlines'),
    Field('businessConstraints', String, 'Business Constraints',
        hint:
            'Business factors constraining staging — fiscal year, '
            'seasonal cycles, market windows, contract dates'),
    Field('technicalConstraints', String, 'Technical Constraints',
        hint:
            'Technical factors constraining staging — infrastructure '
            'readiness, integration dependencies, data readiness'),
    // --- Risk & Complexity ---
    Field('riskTolerance', String, 'Risk Tolerance',
        hint:
            'Low / Medium / High — acceptable level of risk per '
            'stage transition'),
    Field('complexityAssessment', String, 'Complexity Assessment',
        hint:
            'Low / Medium / High / VeryHigh — overall complexity '
            'of the staging plan'),
    Field('complexityFactors', String, 'Key Complexity Factors',
        hint:
            'Primary sources of complexity — data migration volume, '
            'integration count, user base size, geographic spread'),
    // --- Readiness & Resources ---
    Field('organizationalReadinessFactors', String,
        'Organizational Readiness Factors',
        hint:
            'Key readiness factors — change management maturity, '
            'training capacity, executive sponsorship strength'),
    Field('resourceConstraints', String, 'Resource Constraints',
        hint:
            'Staffing, budget, or infrastructure limits affecting '
            'staging timeline'),
    Field('skillAvailability', String, 'Skill Availability',
        hint:
            'Critical skills needed and their availability across '
            'stages — e.g. DBA, cloud architect, UX designer'),
    // --- Rollback & Cutover ---
    Field('rollbackStrategyOverview', String,
        'Rollback Strategy Overview',
        hint:
            'High-level approach to rollback if a stage fails — '
            'FullRollback / PartialRollback / ForwardFix'),
    Field('parallelOperationDuration', String,
        'Parallel Operation Duration',
        hint:
            'Expected duration of parallel system operation during '
            'transitions, e.g. 2 weeks per stage'),
    Field('cutoverMethodology', String, 'Cutover Methodology',
        hint:
            'PilotThenExpand / InstantCutover / GradualMigration / '
            'BlueGreen / Canary'),
    Field('cutoverWindowPreference', String,
        'Cutover Window Preference',
        hint:
            'Preferred timing for cutovers — weekends, holidays, '
            'off-peak hours, maintenance windows'),
    // --- Communication & Change ---
    Field('communicationStrategyOverview', String,
        'Communication Strategy Overview',
        hint:
            'How staging progress and transitions will be '
            'communicated to stakeholders'),
    Field('changeManagementAlignment', String,
        'Change Management Alignment',
        hint:
            'How staging aligns with organizational change '
            'management plan — ADKAR, Kotter, Prosci'),
    // --- Framework Alignment ---
    Field('pmMethodologyAlignment', String, 'PM Methodology Alignment',
        hint:
            'PMBOK / PRINCE2 / SAFe / Scrum / Hybrid — project '
            'management framework guiding stage gates'),
    Field('piCadence', String, 'PI Planning Cadence',
        hint:
            'SAFe Program Increment cadence if applicable — e.g. '
            '10-week PI, 5 iterations per PI'),
    Field('stageBoundaryApproach', String, 'Stage Boundary Approach',
        hint:
            'PRINCE2 stage boundary management — formal review, '
            'exception reporting, tolerance levels'),
  ])
  String? content;

  /// Staging Approach narrative.
  TextSection stagingApproach = TextSection();
}

/// 13.2. Stage Overview [PD00-SSP-STA].
///
/// High-level summary across all stages including aggregate metrics,
/// critical path identification, and resource allocation patterns.
@SectionId('PD00-SSP-STA')
class StageOverview {
  @Form([
    // --- Summary Metrics ---
    Field('numberOfStages', String, 'Number of Stages',
        hint: 'Total number of major stages in the plan',
        required: true),
    Field('totalFeaturesPlanned', String, 'Total Features Planned',
        hint:
            'Total number of features or capabilities across all '
            'stages'),
    Field('totalDurationMonths', String, 'Total Duration',
        hint: 'End-to-end planned duration, e.g. 18 months'),
    Field('totalBudgetAllocation', String, 'Total Budget Allocation',
        hint: 'Aggregate budget across all stages'),
    // --- Cross-Stage Analysis ---
    Field('criticalPathSummary', String, 'Critical Path Summary',
        hint:
            'Key activities on the critical path that determine '
            'overall duration'),
    Field('crossStageDependencyCount', String,
        'Cross-Stage Dependency Count',
        hint: 'Number of dependencies between stages'),
    Field('longestLeadTimeItem', String, 'Longest Lead-Time Item',
        hint:
            'Activity or procurement with the longest lead time '
            'across all stages'),
    // --- Resource Overview ---
    Field('peakTeamSize', String, 'Peak Team Size',
        hint: 'Maximum team size across all stages'),
    Field('resourceAllocationPattern', String,
        'Resource Allocation Pattern',
        hint:
            'FrontLoaded / EvenlyDistributed / BackLoaded / '
            'BellCurve — how resources are distributed'),
    Field('sharedResourceConflicts', String,
        'Shared Resource Conflicts',
        hint:
            'Key resources shared across stages that may cause '
            'contention'),
    // --- Risk & Confidence ---
    Field('overallScheduleRisk', String, 'Overall Schedule Risk',
        hint:
            'Low / Medium / High — aggregate schedule risk '
            'assessment'),
    Field('stageWithHighestRisk', String, 'Stage with Highest Risk',
        hint: 'Which stage carries the most risk and why'),
    Field('planConfidenceLevel', String, 'Plan Confidence Level',
        hint:
            'High / Medium / Low — confidence in the overall '
            'timeline'),
  ])
  String? content;

  /// Stage Summary narrative.
  TextSection stageSummary = TextSection();

  /// 13.2.2. Stage Timeline Diagram [PD00-SSP-STA-DIA] (mermaid).
  GanttDiagramSection timelineDiagram = GanttDiagramSection();
}

/// A stage entry [PD00-SSP-STG-nn] (form) with description subsections.
///
/// Represents a single delivery stage — a self-contained increment of the
/// system that delivers measurable business value. Each stage has clear
/// entry/exit criteria, assigned resources, quality gates, and a
/// deployment plan. Draws from PMBOK phase-gate discipline, SAFe PI
/// planning, and PRINCE2 stage boundary management.
class StageEntry {
  @Form([
    // --- Identity & Classification ---
    Field('stageNumber', String, 'Stage Number',
        hint: '1, 2, 3… — sequential stage number',
        required: true),
    Field('stageName', String, 'Stage Name',
        hint:
            'Descriptive name, e.g. Foundation, Core Operations, '
            'Analytics',
        required: true),
    Field('stageCodename', String, 'Codename',
        hint: 'Optional internal codename, e.g. Atlas, Phoenix'),
    Field('stageDescription', String, 'Description',
        hint:
            'Brief description of what this stage delivers and why'),
    Field('businessObjective', String, 'Business Objective',
        hint:
            'Primary business outcome this stage achieves — ties '
            'to project business case'),
    Field('stageType', String, 'Stage Type',
        hint:
            'Foundation / Incremental / Enhancement / Optimization '
            '/ Migration / Decommissioning'),
    // --- Timeline & Schedule ---
    Field('plannedStartDate', String, 'Planned Start Date',
        required: true),
    Field('plannedEndDate', String, 'Planned End Date',
        required: true),
    Field('targetGoLiveDate', String, 'Target Go-Live Date',
        hint: 'Date when stage deliverables go live to end users',
        required: true),
    Field('actualStartDate', String, 'Actual Start Date',
        hint: 'Populated when stage begins'),
    Field('actualEndDate', String, 'Actual End Date',
        hint: 'Populated when stage completes'),
    Field('durationPlanned', String, 'Planned Duration',
        hint: 'e.g. 12 weeks, 3 months'),
    Field('bufferDays', String, 'Buffer Days',
        hint:
            'Schedule buffer allocated to this stage — management '
            'reserve or feeding buffer'),
    Field('leadTimeDays', String, 'Lead Time',
        hint:
            'Required lead time before stage can begin — '
            'procurement, approvals, environment setup'),
    Field('freezePeriods', String, 'Freeze Periods',
        hint:
            'Periods during which no changes can be deployed — '
            'holiday freeze, audit periods'),
    // --- Scope & Features ---
    Field('scopeSummary', String, 'Scope Summary',
        hint:
            'High-level summary of features and capabilities '
            'included in this stage'),
    Field('includedFeatures', String, 'Included Features',
        hint:
            'Key features/capabilities explicitly included — '
            'comma-separated or numbered'),
    Field('excludedDeferred', String, 'Excluded/Deferred Items',
        hint:
            'Features explicitly excluded and deferred to later '
            'stages'),
    Field('mvpScope', String, 'MVP Scope',
        hint:
            'Minimum viable scope if schedule compression is '
            'needed — what must ship'),
    Field('stretchGoals', String, 'Stretch Goals',
        hint:
            'Additional scope if the stage runs ahead of schedule'),
    Field('featureCount', String, 'Feature Count',
        hint:
            'Number of features, user stories, or epics in this '
            'stage'),
    Field('storyPointEstimate', String, 'Story Point Estimate',
        hint: 'Total estimated effort in story points — SAFe PI'),
    Field('technicalDebtItems', String, 'Technical Debt Items',
        hint:
            'Known technical debt to be addressed in this stage'),
    // --- Dependencies ---
    Field('prerequisiteStages', String, 'Prerequisite Stages',
        hint:
            'Stages that must complete before this stage can '
            'start — e.g. Stage 1, Stage 2'),
    Field('parallelStages', String, 'Parallel Stages',
        hint: 'Stages running concurrently with this stage'),
    Field('externalDependencies', String, 'External Dependencies',
        hint:
            'Dependencies on external systems, vendors, third '
            'parties, or regulatory approvals'),
    Field('blockingRisks', String, 'Blocking Risks',
        hint:
            'Risks that could block stage start or completion'),
    // --- Resources & Budget ---
    Field('teamSize', String, 'Team Size',
        hint: 'Number of team members allocated to this stage'),
    Field('keyRoles', String, 'Key Roles Required',
        hint:
            'Critical roles needed — e.g. Solution Architect, '
            'DBA, UX Designer, Security Engineer'),
    Field('budgetAllocation', String, 'Budget Allocation',
        hint: 'Budget allocated to this stage'),
    Field('infrastructureNeeds', String, 'Infrastructure Needs',
        hint:
            'Environments, servers, cloud resources, licenses '
            'needed'),
    Field('toolingRequirements', String, 'Tooling Requirements',
        hint:
            'Software licenses, development tools, or third-party '
            'services needed'),
    // --- Quality & Governance ---
    Field('entryCriteria', String, 'Entry Criteria',
        hint:
            'Conditions that must be met before the stage can '
            'begin — predecessor sign-off, environment ready'),
    Field('exitCriteria', String, 'Exit Criteria',
        hint:
            'Conditions that must be met for the stage to be '
            'considered complete — all tests pass, UAT signed off'),
    Field('qualityGates', String, 'Quality Gates',
        hint:
            'Formal checkpoints within the stage — design review, '
            'code review, security review, UAT signoff'),
    Field('testingStrategy', String, 'Testing Strategy',
        hint:
            'Testing approach for this stage — unit, integration, '
            'E2E, UAT, performance, security, accessibility'),
    Field('acceptanceCriteriaSummary', String,
        'Acceptance Criteria Summary',
        hint:
            'High-level criteria for business acceptance of this '
            'stage'),
    Field('toleranceLevels', String, 'Tolerance Levels',
        hint:
            'PRINCE2 tolerances — time ±X days, cost ±Y%, '
            'scope flexibility, quality thresholds'),
    // --- Deployment & Rollout ---
    Field('deploymentApproach', String, 'Deployment Approach',
        hint:
            'BlueGreen / Canary / RollingUpdate / BigBang / '
            'DarkLaunch / FeatureFlags'),
    Field('rollbackPlan', String, 'Rollback Plan',
        hint:
            'Strategy if deployment fails — automated rollback, '
            'manual procedure, forward-fix'),
    Field('rollbackTriggers', String, 'Rollback Triggers',
        hint:
            'Conditions that trigger a rollback — error rate '
            'threshold, SLA breach, data corruption'),
    Field('parallelOperationPeriod', String,
        'Parallel Operation Period',
        hint:
            'Duration of old and new system running in parallel'),
    Field('dataMigrationScope', String, 'Data Migration Scope',
        hint:
            'Data entities and volumes to be migrated in this '
            'stage'),
    Field('cutoverPlanSummary', String, 'Cutover Plan Summary',
        hint: 'Key steps for switching from old to new system'),
    Field('hypercarePeriod', String, 'Hypercare Period',
        hint:
            'Duration and scope of intensive post-go-live support '
            '— e.g. 2 weeks, 24x7 on-call'),
    // --- Stakeholders & Communication ---
    Field('stageOwner', String, 'Stage Owner',
        hint: 'Person accountable for stage delivery'),
    Field('businessSponsor', String, 'Business Sponsor',
        hint:
            'Business stakeholder sponsoring and funding this '
            'stage'),
    Field('technicalLead', String, 'Technical Lead',
        hint: 'Technical authority for this stage'),
    Field('qaLead', String, 'QA Lead',
        hint: 'Quality assurance lead for this stage'),
    Field('changeManager', String, 'Change Manager',
        hint:
            'Person managing organizational change for this stage'),
    Field('announcementPlan', String, 'Announcement Plan',
        hint:
            'How and when the stage and go-live will be '
            'communicated to affected users'),
    Field('trainingRequirements', String, 'Training Requirements',
        hint:
            'Training needed for end users, support staff, '
            'and operators'),
    Field('documentationUpdates', String, 'Documentation Updates',
        hint:
            'User guides, runbooks, SOPs requiring updates for '
            'this stage'),
    // --- Risk ---
    Field('topRisks', String, 'Top Risks',
        hint:
            'Key risks specific to this stage — comma-separated'),
    Field('riskMitigationStrategies', String,
        'Risk Mitigation Strategies',
        hint: 'Planned responses to top risks'),
    Field('contingencyTriggers', String, 'Contingency Triggers',
        hint:
            'Conditions that activate contingency plans — e.g. '
            'schedule slip >2 weeks, budget overrun >10%'),
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'Escalation process if stage encounters critical '
            'issues — who to contact, decision authority'),
    // --- Status & Metrics ---
    Field('currentStatus', String, 'Current Status',
        hint:
            'Planned / Active / Completed / OnHold / Cancelled'),
    Field('completionPercentage', String, 'Completion %',
        hint: '0-100 — current progress'),
    Field('healthIndicator', String, 'Health Indicator',
        hint:
            'Green / Amber / Red — overall stage health based on '
            'schedule, budget, scope, quality'),
    Field('scheduleVariance', String, 'Schedule Variance',
        hint:
            'Days ahead or behind plan — e.g. +5 days, -3 days'),
    Field('keyPerformanceIndicators', String,
        'Key Performance Indicators',
        hint:
            'KPIs to measure stage success — adoption rate, error '
            'rate, throughput, user satisfaction'),
    Field('successThreshold', String, 'Success Threshold',
        hint:
            'Minimum measurable outcome required to declare stage '
            'successful'),
  ])
  String? content;

  /// Feature Scope narrative.
  TextSection featureScope = TextSection();

  /// Sub-stages and Milestones [PD00-SSP-STG-nn-SUB] — contains 0+× SubStage.
  @SectionIdPattern('PD00-SSP-STG-xx-SUB-xx')
  List<SubStageEntry> subStagesAndMilestones = [];

  /// Timeline narrative.
  TextSection timeline = TextSection();

  /// Success Criteria [PD00-SSP-STG-nn-SUC] — contains 0+× StageSuccessCriterion.
  @SectionIdPattern('PD00-SSP-STG-xx-SUC-xx')
  List<StageSuccessCriterionEntry> successCriteria = [];

  /// Rollout Plan narrative.
  TextSection rolloutPlan = TextSection();
}

/// A sub-stage or milestone entry (form) [PD00-SSP-STG-nn-SUB-nn].
///
/// Represents a discrete phase within a stage — alpha, beta, release
/// candidate, pilot, GA — or a key milestone. Sub-stages provide finer
/// scheduling granularity and quality gates within a stage.
class SubStageEntry {
  @Form([
    // --- Identity ---
    Field('name', String, 'Name',
        hint: 'Descriptive name for this sub-stage or milestone',
        required: true),
    Field('subStageType', String, 'Type',
        hint:
            'Alpha / Beta / RC / Pilot / GA / Milestone / Sprint '
            '/ Iteration / Hardening'),
    Field('sequenceNumber', String, 'Sequence Number',
        hint: 'Order within the parent stage — 1, 2, 3…'),
    Field('description', String, 'Description',
        hint: 'Brief description of this sub-stage or milestone'),
    Field('objective', String, 'Objective',
        hint: 'What this sub-stage aims to achieve'),
    // --- Timeline ---
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
    // --- Scope & Deliverables ---
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
    // --- Resources & Environment ---
    Field('assignedTeam', String, 'Assigned Team',
        hint: 'Team or team members assigned to this sub-stage'),
    Field('environmentNeeded', String, 'Environment Needed',
        hint:
            'Environment required — e.g. dev, staging, UAT, '
            'production-like, production'),
    // --- Quality ---
    Field('qualityGate', String, 'Quality Gate',
        hint:
            'Quality checkpoint at the end of this sub-stage — '
            'what must be verified'),
    Field('testingFocus', String, 'Testing Focus',
        hint:
            'Primary testing activities — smoke, regression, '
            'performance, UAT, security'),
    // --- Status ---
    Field('currentStatus', String, 'Current Status',
        hint:
            'NotStarted / InProgress / Completed / Blocked / '
            'Cancelled'),
    Field('completionPercentage', String, 'Completion %',
        hint: '0-100 — current progress'),
  ])
  String? content;
}

/// A success criterion entry (form) [PD00-SSP-STG-nn-SUC-nn].
///
/// Defines a measurable criterion that determines whether a stage has
/// achieved its objectives. Each criterion has a target metric,
/// measurement method, threshold, and verification process.
class StageSuccessCriterionEntry {
  @Form([
    // --- Identity ---
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
    // --- Measurement ---
    Field('measurementMethod', String, 'Measurement Method',
        hint: 'How this criterion will be measured',
        required: true),
    Field('metric', String, 'Metric',
        hint:
            'Specific metric to track — e.g. response time, '
            'adoption rate, error rate, throughput'),
    Field('targetValue', String, 'Target Value',
        hint: 'Target metric value for success — e.g. <200ms, >95%'),
    Field('minimumThreshold', String, 'Minimum Threshold',
        hint:
            'Minimum acceptable value — below this, the stage '
            'fails this criterion'),
    Field('tolerance', String, 'Tolerance',
        hint: 'Acceptable variance from target — e.g. ±5%, ±10ms'),
    Field('baselineValue', String, 'Baseline Value',
        hint: 'Current baseline before the stage, for comparison'),
    // --- Verification ---
    Field('verificationMethod', String, 'Verification Method',
        hint:
            'Automated / Manual / Audit / Survey / Report / '
            'LoadTest'),
    Field('verifier', String, 'Verifier',
        hint: 'Person or role responsible for verification'),
    Field('verificationDate', String, 'Verification Date',
        hint: 'When verification will be performed'),
    // --- Status ---
    Field('currentStatus', String, 'Status',
        hint: 'Pending / Measuring / Met / NotMet / Waived'),
    Field('actualValue', String, 'Actual Value',
        hint: 'Measured value — populated during or after stage'),
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
