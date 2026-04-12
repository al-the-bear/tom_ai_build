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
///
/// Comprehensive feature prioritization framework for staged delivery.
/// Covers prioritization methodology, MoSCoW analysis, feature-stage
/// mapping, individual feature priority scoring, and cross-feature
/// dependency tracking. Aligns with SAFe WSJF, PMBOK value-driven
/// delivery, MoSCoW (DSDM), and Kano model classification.
@SectionId('PD00-SSP-FEA')
class FeaturePrioritization {
  @Form([
    // --- Methodology & Approach ---
    Field('prioritizationMethodology', String,
        'Prioritization Methodology',
        hint:
            'MoSCoW / WSJF / ValueVsEffort / Kano / '
            'WeightedScoring / StackRank / Hybrid',
        required: true),
    Field('secondaryMethodology', String, 'Secondary Methodology',
        hint:
            'Optional complementary method — e.g. Kano for UX '
            'features alongside MoSCoW for core'),
    Field('scoringModelDescription', String,
        'Scoring Model Description',
        hint:
            'How priority scores are calculated — criteria, '
            'weights, scale (1-5, Fibonacci, T-shirt)'),
    Field('prioritizationCriteria', String,
        'Prioritization Criteria',
        hint:
            'Comma-separated criteria — BusinessValue, '
            'CostOfDelay, Risk, Effort, StrategicAlignment, '
            'Urgency, Dependency'),
    Field('criteriaWeights', String, 'Criteria Weights',
        hint:
            'Weight per criterion — e.g. BusinessValue:30%, '
            'CostOfDelay:25%, Risk:20%, Effort:15%, '
            'Alignment:10%'),
    // --- Stakeholder Involvement ---
    Field('prioritizationOwner', String, 'Prioritization Owner',
        hint:
            'Role or person with final authority — Product Owner, '
            'Steering Committee'),
    Field('stakeholderParticipants', String,
        'Stakeholder Participants',
        hint:
            'Roles involved — PM, Architects, Business Analysts, '
            'UX, Customer Reps'),
    Field('stakeholderVotingMethod', String,
        'Stakeholder Voting Method',
        hint:
            'DotVoting / PlanningPoker / ConsensusBuilding / '
            'DelegatedAuthority / Delphi'),
    Field('conflictResolutionProcess', String,
        'Conflict Resolution Process',
        hint:
            'How disagreements are resolved — escalation to '
            'sponsor, majority vote, data-driven'),
    // --- Cadence & Triggers ---
    Field('reviewCadence', String, 'Review Cadence',
        hint:
            'How often prioritization is reviewed — EveryPI / '
            'Monthly / PerStage / OnDemand',
        required: true),
    Field('rePrioritizationTriggers', String,
        'Re-Prioritization Triggers',
        hint:
            'Events forcing re-prioritization — budget change, '
            'regulatory mandate, competitive pressure, scope '
            'change, dependency failure'),
    Field('lastPrioritizationDate', String,
        'Last Prioritization Date',
        hint: 'When features were last formally prioritized'),
    Field('nextReviewDate', String, 'Next Scheduled Review',
        hint: 'Next planned prioritization review session'),
    // --- Capacity Constraints ---
    Field('teamVelocity', String, 'Team Velocity',
        hint:
            'Current velocity in story points per sprint or '
            'features per PI'),
    Field('budgetCap', String, 'Budget Cap',
        hint:
            'Total budget available for feature delivery across '
            'all stages'),
    Field('maxFeaturesPerStage', String, 'Max Features Per Stage',
        hint:
            'Capacity limit based on team size and velocity'),
    Field('resourceBottlenecks', String, 'Resource Bottlenecks',
        hint:
            'Scarce resources constraining delivery — e.g. DBA, '
            'Security review, UX design'),
    // --- Backlog Health ---
    Field('totalFeaturesInBacklog', String,
        'Total Features in Backlog',
        hint: 'Total feature count across all priority tiers'),
    Field('featuresFullyPrioritized', String,
        'Features Fully Prioritized',
        hint: 'Count with complete priority scoring'),
    Field('featuresUnprioritized', String,
        'Features Unprioritized',
        hint: 'Features awaiting prioritization'),
    Field('backlogGroomingStatus', String,
        'Backlog Grooming Status',
        hint:
            'Current / Stale / NeedsReview — health of the '
            'feature backlog'),
    Field('averageFeatureAge', String, 'Average Feature Age',
        hint:
            'Mean time features spend in backlog before delivery '
            'or removal — e.g. 3 months'),
    // --- Traceability ---
    Field('traceabilityToBusinessCase', String,
        'Traceability to Business Case',
        hint:
            'How features link to business case — tagging, OKR '
            'mapping, epic hierarchy'),
    Field('traceabilityToRequirements', String,
        'Traceability to Requirements',
        hint:
            'How features map to requirements — by ID, by use '
            'case, by business process'),
  ])
  String? content;

  /// Prioritization rationale narrative.
  TextSection prioritizationRationale = TextSection();

  /// 13.4.1. MoSCoW Analysis [PD00-SSP-FEA-MOS].
  MoscowAnalysis moscowAnalysis = MoscowAnalysis();

  /// 13.4.2. Feature-Stage Matrix [PD00-SSP-FEA-MAT].
  FeatureStageMatrix featureStageMatrix = FeatureStageMatrix();

  /// 13.4.3. Feature Priority Register [PD00-SSP-FEA-REG].
  FeaturePriorityRegister featurePriorityRegister =
      FeaturePriorityRegister();

  /// 13.4.4. Feature Dependencies [PD00-SSP-FEA-DEP].
  FeatureDependencies featureDependencies = FeatureDependencies();
}

/// 13.4.1. MoSCoW Analysis [PD00-SSP-FEA-MOS].
///
/// Classifies every feature using the MoSCoW method (Must / Should /
/// Could / Won't) and maps each to its target delivery stage.
@SectionId('PD00-SSP-FEA-MOS')
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
  TextSection moscowRationale = TextSection();

  /// Contains 0+× MoscowEntry.
  @SectionIdPattern('PD00-SSP-FEA-MOS-xx')
  List<MoscowEntry> items = [];
}

/// A MoSCoW classification entry (form) [PD00-SSP-FEA-MOS-nn].
///
/// Maps a single feature or feature group to its MoSCoW category and
/// target delivery stage, with justification and cross-references.
class MoscowEntry {
  @Form([
    // --- Feature Identity ---
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
    // --- MoSCoW Classification ---
    Field('moscowCategory', String, 'MoSCoW Category',
        hint: 'Must / Should / Could / Wont',
        required: true),
    Field('justification', String, 'Justification',
        hint:
            'Why this feature has this classification — business '
            'rationale, regulatory need, user demand',
        required: true),
    Field('reclassificationRisk', String, 'Reclassification Risk',
        hint:
            'Low / Medium / High — likelihood the category will '
            'change before delivery'),
    // --- Value & Effort ---
    Field('businessValue', String, 'Business Value',
        hint:
            'Relative business value — 1-10, Fibonacci, or '
            'qualitative High/Medium/Low'),
    Field('effortEstimate', String, 'Effort Estimate',
        hint:
            'Relative effort — story points, T-shirt size, or '
            'person-days'),
    Field('costOfDelay', String, 'Cost of Delay',
        hint:
            'Impact of not delivering on time — revenue loss, '
            'penalty, competitive risk'),
    // --- Stage Assignment ---
    Field('targetStage', String, 'Target Stage',
        hint:
            'Stage in which this feature is planned for delivery',
        required: true),
    Field('earliestPossibleStage', String,
        'Earliest Possible Stage',
        hint:
            'Earliest stage where prerequisites allow delivery'),
    // --- Cross-References ---
    Field('linkedRequirements', String, 'Linked Requirements',
        hint:
            'Requirement IDs this feature traces to — '
            'comma-separated'),
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

/// 13.4.2. Feature-Stage Matrix [PD00-SSP-FEA-MAT].
///
/// Maps every feature or feature group to the delivery stage, tracking
/// readiness, confidence, dependencies, and acceptance criteria.
@SectionId('PD00-SSP-FEA-MAT')
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
  TextSection matrixNarrative = TextSection();

  /// Contains 0+× FeatureStageMapping.
  @SectionIdPattern('PD00-SSP-FEA-MAT-xx')
  List<FeatureStageMapping> items = [];
}

/// A feature-to-stage mapping entry (form) [PD00-SSP-FEA-MAT-nn].
///
/// Maps a single feature or feature group to its delivery stage with
/// readiness, confidence, and dependency information.
class FeatureStageMapping {
  @Form([
    // --- Feature Identity ---
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
    // --- Stage Assignment ---
    Field('targetStage', String, 'Target Stage',
        hint: 'Stage in which this feature will be delivered',
        required: true),
    Field('stagePhase', String, 'Stage Phase',
        hint:
            'Sub-phase within the stage — Alpha / Beta / GA / '
            'Full rollout'),
    Field('fallbackStage', String, 'Fallback Stage',
        hint:
            'Stage to which this feature moves if cut from '
            'target stage'),
    // --- Readiness & Confidence ---
    Field('readinessStatus', String, 'Readiness Status',
        hint:
            'NotReady / InProgress / DesignComplete / '
            'ReadyForDev / ReadyForTest / ReadyForRelease',
        required: true),
    Field('deliveryConfidence', String, 'Delivery Confidence',
        hint:
            'High / Medium / Low — confidence that this feature '
            'will be delivered in the target stage'),
    Field('confidenceRationale', String, 'Confidence Rationale',
        hint:
            'Why confidence is at this level — blockers, '
            'unknowns, resource gaps'),
    // --- Dependencies ---
    Field('prerequisiteFeatures', String, 'Prerequisite Features',
        hint:
            'Feature IDs that must complete first — '
            'comma-separated'),
    Field('blockedByExternalDependency', String,
        'Blocked by External Dependency',
        hint:
            'External systems, vendors, or approvals — None, '
            'or description'),
    Field('crossStageDependency', String,
        'Cross-Stage Dependency',
        hint:
            'Does this feature depend on something from a prior '
            'stage — Yes/No, plus which stage'),
    // --- Acceptance ---
    Field('acceptanceCriteriaSummary', String,
        'Acceptance Criteria Summary',
        hint:
            'High-level criteria for this feature to be accepted'),
    Field('definitionOfDone', String, 'Definition of Done',
        hint:
            'DoD for this feature — code complete, tests pass, '
            'docs updated, deployed'),
    // --- Notes ---
    Field('notes', String, 'Notes',
        hint: 'Additional context or caveats'),
  ])
  String? content;
}

/// 13.4.3. Feature Priority Register [PD00-SSP-FEA-REG].
///
/// Master register of all features with comprehensive priority scoring,
/// business value analysis, effort estimates, stakeholder ownership,
/// and traceability. Single source of truth for feature identity.
@SectionId('PD00-SSP-FEA-REG')
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
  @SectionIdPattern('PD00-SSP-FEA-REG-xx')
  @Min(1)
  List<FeaturePriorityEntry> items = [];
}

/// An individual feature priority entry (form) [PD00-SSP-FEA-REG-nn].
///
/// Comprehensive record covering identity, classification, business
/// value, effort, priority scoring, stage assignment, dependencies,
/// stakeholders, traceability, and status.
class FeaturePriorityEntry {
  @Form([
    // --- Feature Identity ---
    Field('featureId', String, 'Feature ID',
        hint: 'Unique identifier — e.g. FEA-001',
        required: true),
    Field('featureName', String, 'Feature Name',
        hint: 'Short descriptive name',
        required: true),
    Field('featureDescription', String, 'Description',
        hint: 'Detailed description of the feature capability'),
    Field('featureCategory', String, 'Category',
        hint:
            'Functional / NonFunctional / Regulatory / UX / '
            'Infrastructure / Security / DataManagement / '
            'Integration',
        required: true),
    Field('featureSubCategory', String, 'Sub-Category',
        hint:
            'Finer classification — e.g. Authentication, '
            'Reporting, Caching'),
    Field('featureType', String, 'Feature Type',
        hint:
            'New / Enhancement / BugFix / TechnicalDebt / '
            'Enabler / Exploration'),
    Field('featureSize', String, 'Feature Size',
        hint: 'XS / S / M / L / XL — T-shirt sizing'),
    Field('epicLink', String, 'Epic Link',
        hint:
            'Parent epic or theme — for portfolio-level '
            'tracking'),
    // --- Business Value ---
    Field('businessValueScore', String, 'Business Value Score',
        hint:
            'Numeric score — 1-10 or Fibonacci — used in '
            'weighted scoring',
        required: true),
    Field('revenueImpact', String, 'Revenue Impact',
        hint:
            'None / Low / Medium / High / Critical — expected '
            'revenue impact'),
    Field('revenueEstimate', String, 'Revenue Estimate',
        hint:
            'Estimated revenue or savings — e.g. \$50K/year, '
            '5% conversion increase'),
    Field('costOfDelay', String, 'Cost of Delay',
        hint:
            'Daily/weekly/monthly cost of not delivering — '
            'financial or qualitative'),
    Field('costOfDelayCategory', String,
        'Cost of Delay Category',
        hint:
            'StandardDecay / FixedDate / UrgentPenalty / None '
            '— SAFe CoD categorization'),
    Field('strategicAlignment', String, 'Strategic Alignment',
        hint:
            'Low / Medium / High / Critical — alignment with '
            'business strategy and OKRs',
        required: true),
    Field('strategicObjectiveLink', String,
        'Strategic Objective Link',
        hint:
            'Which business objective or OKR this supports — '
            'e.g. O1-KR3'),
    Field('customerImpact', String, 'Customer Impact',
        hint:
            'Low / Medium / High — impact on customer '
            'experience or satisfaction'),
    Field('userBaseAffected', String, 'User Base Affected',
        hint:
            'Percentage or count of users — e.g. 80% of active '
            'users, 500 enterprises'),
    Field('marketCompetitiveness', String,
        'Market Competitiveness',
        hint:
            'TableStakes / Differentiator / Innovative / '
            'CatchUp — market positioning'),
    Field('regulatoryRequirement', String,
        'Regulatory Requirement',
        hint:
            'None / Recommended / Mandatory — whether compliance '
            'depends on this feature'),
    Field('regulatoryDeadline', String, 'Regulatory Deadline',
        hint:
            'Hard compliance deadline — e.g. GDPR by 2025-Q2'),
    // --- Effort & Complexity ---
    Field('estimatedEffort', String, 'Estimated Effort',
        hint:
            'Story points, person-days, or T-shirt size — '
            'primary effort metric',
        required: true),
    Field('complexityRating', String, 'Complexity Rating',
        hint:
            'Low / Medium / High / VeryHigh — technical and '
            'organizational complexity'),
    Field('complexityFactors', String, 'Complexity Factors',
        hint:
            'Key sources — integration count, data migration, '
            'UI complexity, algorithm difficulty'),
    Field('riskLevel', String, 'Risk Level',
        hint:
            'Low / Medium / High — delivery risk for this '
            'feature',
        required: true),
    Field('riskFactors', String, 'Risk Factors',
        hint:
            'Specific risks — novel technology, unclear reqs, '
            'external dependency, performance'),
    Field('technicalDebtImpact', String, 'Technical Debt Impact',
        hint:
            'Creates / Reduces / Neutral — effect on technical '
            'debt'),
    Field('dependencyCount', String, 'Dependency Count',
        hint: 'Number of features this depends on or blocks'),
    Field('integrationComplexity', String,
        'Integration Complexity',
        hint:
            'None / Low / Medium / High — integrations required'),
    // --- Priority Scoring ---
    Field('weightedPriorityScore', String,
        'Weighted Priority Score',
        hint:
            'Calculated score from weighted criteria — e.g. '
            '8.5 out of 10',
        required: true),
    Field('priorityRank', String, 'Priority Rank',
        hint: 'Ordinal rank — 1 = highest',
        required: true),
    Field('moscowTier', String, 'MoSCoW Tier',
        hint: 'Must / Should / Could / Wont',
        required: true),
    Field('wsjfScore', String, 'WSJF Score',
        hint:
            'Weighted Shortest Job First score — CoD / JobSize'),
    Field('kanoClassification', String, 'Kano Classification',
        hint:
            'Basic / Performance / Excitement / Indifferent / '
            'Reverse'),
    Field('prioritizationNotes', String, 'Prioritization Notes',
        hint: 'Justification or context for the scoring'),
    // --- Stage Assignment ---
    Field('targetStage', String, 'Target Stage',
        hint: 'Planned delivery stage',
        required: true),
    Field('earliestPossibleStage', String,
        'Earliest Possible Stage',
        hint:
            'Earliest stage prerequisites allow — may differ '
            'from target due to capacity'),
    Field('fallbackStage', String, 'Fallback Stage',
        hint: 'Stage to defer to if cut from target'),
    Field('stageAssignmentRationale', String,
        'Stage Assignment Rationale',
        hint:
            'Why this stage — dependency, value, risk, capacity'),
    // --- Dependencies ---
    Field('dependsOnFeatures', String, 'Depends on Features',
        hint: 'Feature IDs this requires — comma-separated'),
    Field('blocksFeatures', String, 'Blocks Features',
        hint:
            'Feature IDs blocked until this completes — '
            'comma-separated'),
    Field('externalDependencies', String, 'External Dependencies',
        hint:
            'External systems, APIs, vendors, or approvals — '
            'comma-separated'),
    Field('dependencyCriticalPath', String,
        'On Dependency Critical Path',
        hint:
            'Yes / No — whether on the critical dependency '
            'chain'),
    // --- Stakeholders ---
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
        hint:
            'Proposed / Approved / ConditionallyApproved / '
            'Rejected / Deferred'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Person or body who approved'),
    Field('approvalDate', String, 'Approval Date',
        hint: 'When approval was granted'),
    // --- Traceability ---
    Field('linkedRequirements', String, 'Linked Requirements',
        hint: 'Requirement IDs — comma-separated'),
    Field('linkedUseCases', String, 'Linked Use Cases',
        hint: 'Use case IDs — comma-separated'),
    Field('linkedBusinessProcesses', String,
        'Linked Business Processes',
        hint: 'Business process IDs — comma-separated'),
    Field('linkedUserStories', String, 'Linked User Stories',
        hint: 'User story IDs in the backlog'),
    Field('linkedArchitectureDecisions', String,
        'Linked Architecture Decisions',
        hint: 'ADR IDs affected by or affecting this feature'),
    // --- Status ---
    Field('prioritizationStatus', String, 'Prioritization Status',
        hint:
            'Draft / UnderReview / Prioritized / Deferred / '
            'Dropped',
        required: true),
    Field('deliveryStatus', String, 'Delivery Status',
        hint:
            'Backlog / Planned / InDevelopment / InTest / '
            'Delivered / Cancelled'),
    Field('confidenceLevel', String, 'Confidence Level',
        hint:
            'High / Medium / Low — confidence feature can be '
            'delivered as scoped and on time'),
    Field('lastReviewedDate', String, 'Last Reviewed Date',
        hint: 'When last reviewed in prioritization'),
    Field('changeHistory', String, 'Change History',
        hint:
            'Brief log of priority/stage changes — e.g. '
            '"Moved Must→Should Q1, re-staged 2→3"'),
  ])
  String? content;
}

/// 13.4.4. Feature Dependencies [PD00-SSP-FEA-DEP].
///
/// Cross-feature dependencies affecting staging order, critical path
/// analysis, and delivery sequencing.
@SectionId('PD00-SSP-FEA-DEP')
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
  TextSection dependencyAnalysis = TextSection();

  /// Contains 0+× FeatureDependencyEntry.
  @SectionIdPattern('PD00-SSP-FEA-DEP-xx')
  List<FeatureDependencyEntry> items = [];
}

/// A feature dependency entry (form) [PD00-SSP-FEA-DEP-nn].
///
/// Describes a single directional dependency between two features,
/// including type, impact, and resolution strategy.
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
///
/// Governance framework for stage transitions, phase gate reviews,
/// and key decision points. Covers governance structure, authority
/// model, escalation paths, compliance requirements, and the
/// ceremonies that control stage advancement. Aligns with PMBOK
/// governance gates, SAFe Program Increment boundaries, PRINCE2
/// stage gates, and TOGAF architecture governance.
@SectionId('PD00-SSP-GOV')
class StageGovernance {
  @Form([
    // --- Governance Model ---
    Field('governanceModel', String, 'Governance Model',
        hint:
            'PhaseGate / Agile / Hybrid / Continuous / '
            'Federated — overall governance approach',
        required: true),
    Field('governanceFramework', String, 'Governance Framework',
        hint:
            'PMBOK / PRINCE2 / SAFe / DAD / Custom — reference '
            'framework',
        required: true),
    Field('governanceCharter', String, 'Governance Charter',
        hint:
            'Name or reference to the formal governance charter '
            'document — defines authority, scope, and '
            'accountability'),
    // --- Authority & Oversight ---
    Field('governanceBoardName', String, 'Governance Board Name',
        hint:
            'Name of the governing body — Steering Committee, '
            'PMO, Architecture Review Board'),
    Field('governanceBoardChair', String,
        'Governance Board Chair',
        hint:
            'Person chairing the governance body — typically '
            'sponsor, CTO, or program director'),
    Field('boardMembers', String, 'Board Members',
        hint:
            'Roles or names on the board — comma-separated, '
            'e.g. Sponsor, Product Owner, Enterprise Architect, '
            'QA Lead'),
    Field('decisionMakingModel', String, 'Decision-Making Model',
        hint:
            'Consensus / MajorityVote / DelegatedAuthority / '
            'RACI-based / Unanimous',
        required: true),
    Field('quorumRequirement', String, 'Quorum Requirement',
        hint:
            'Minimum attendance for valid decisions — e.g. 3 of '
            '5 members, or 60%'),
    Field('delegatedAuthorityThreshold', String,
        'Delegated Authority Threshold',
        hint:
            'Decisions the PM can make without board — e.g. '
            'budget ≤\$10K, schedule ≤1 week, no scope change'),
    // --- Escalation ---
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'Escalation chain — PM → Program Manager → Steering '
            'Committee → Executive Sponsor'),
    Field('escalationTriggers', String, 'Escalation Triggers',
        hint:
            'Conditions requiring escalation — budget overrun '
            '≥10%, schedule slip ≥2 weeks, critical risk '
            'materialized, scope dispute'),
    Field('escalationTimeframe', String, 'Escalation Timeframe',
        hint:
            'Maximum time before escalation — e.g. 48 hours '
            'for critical, 5 business days for advisory'),
    // --- Cadence & Process ---
    Field('governanceMeetingCadence', String,
        'Governance Meeting Cadence',
        hint:
            'PerStage / Monthly / Quarterly / OnDemand — how '
            'often the board convenes',
        required: true),
    Field('meetingDuration', String, 'Meeting Duration',
        hint:
            'Typical meeting length — e.g. 2 hours, half-day '
            'for major gates'),
    Field('meetingFormat', String, 'Meeting Format',
        hint:
            'InPerson / Virtual / Hybrid — preferred format'),
    Field('agendaTemplate', String, 'Agenda Template',
        hint:
            'Standard agenda structure — StatusReview, '
            'RiskReview, DecisionItems, ActionItems'),
    Field('minutesDistribution', String, 'Minutes Distribution',
        hint:
            'How minutes are distributed — email, wiki, '
            'SharePoint, within 24/48 hours'),
    // --- Compliance & Audit ---
    Field('complianceRequirements', String,
        'Compliance Requirements',
        hint:
            'Regulatory or organizational compliance that '
            'governance must satisfy — SOX, ISO 27001, GDPR, '
            'internal audit policies'),
    Field('auditTrailRequirement', String,
        'Audit Trail Requirement',
        hint:
            'What must be recorded — decisions, rationale, '
            'attendance, votes, action items',
        required: true),
    Field('documentRetentionPolicy', String,
        'Document Retention Policy',
        hint:
            'How long governance records are retained — e.g. '
            '7 years, project lifetime + 2 years'),
    Field('externalAuditIntegration', String,
        'External Audit Integration',
        hint:
            'Whether external auditors participate — None, '
            'Annual, PerMajorGate'),
    // --- Metrics & Reporting ---
    Field('governanceKpis', String, 'Governance KPIs',
        hint:
            'Metrics tracked — gate pass rate, decision cycle '
            'time, escalation frequency, rework rate'),
    Field('reportingFrequency', String, 'Reporting Frequency',
        hint:
            'How often governance reports are published — '
            'Weekly / Monthly / PerGate'),
    Field('dashboardLocation', String, 'Dashboard Location',
        hint:
            'Where governance status is visible — URL, tool, '
            'or distribution list'),
    // --- Stage Transition Rules ---
    Field('stageTransitionPolicy', String,
        'Stage Transition Policy',
        hint:
            'Rules for moving between stages — all gates must '
            'pass, conditional advancement allowed, rollback '
            'policy',
        required: true),
    Field('conditionalAdvancementRules', String,
        'Conditional Advancement Rules',
        hint:
            'Under what conditions a stage may advance with '
            'open items — risk accepted, time-boxed remediation'),
    Field('rollbackPolicy', String, 'Rollback Policy',
        hint:
            'Rules for reverting to a prior stage — triggers, '
            'process, authority required'),
    Field('emergencyBypassProcess', String,
        'Emergency Bypass Process',
        hint:
            'How governance is handled in emergencies — '
            'expedited review, post-hoc ratification, '
            'emergency authority delegation'),
  ])
  String? content;

  /// Governance narrative and rationale.
  TextSection governanceNarrative = TextSection();

  /// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
  PhaseGateReviews phaseGateReviews = PhaseGateReviews();

  /// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
  DecisionPoints decisionPoints = DecisionPoints();
}

/// 13.6.1. Phase Gate Reviews [PD00-SSP-GOV-GAT].
///
/// Defines the phase gate review process: what is reviewed at each
/// gate, who participates, what evidence is required, and what
/// outcomes are possible (proceed, rework, cancel, conditional).
@SectionId('PD00-SSP-GOV-GAT')
class PhaseGateReviews {
  @Form([
    // --- Gate Framework ---
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
    // --- Standard Attendees ---
    Field('mandatoryAttendees', String, 'Mandatory Attendees',
        hint:
            'Roles required at every gate — Sponsor, PM, '
            'TechLead, QA Lead, Business Owner'),
    Field('optionalAttendees', String, 'Optional Attendees',
        hint:
            'Roles invited as needed — Security, Legal, UX, '
            'Operations'),
    // --- Standard Evidence ---
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
    // --- Outcomes ---
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

  /// Phase gate review process narrative.
  TextSection gateReviewNarrative = TextSection();

  /// Contains 0+× PhaseGateReviewEntry.
  @SectionIdPattern('PD00-SSP-GOV-GAT-xx')
  List<PhaseGateReviewEntry> items = [];
}

/// A phase gate review entry (form) [PD00-SSP-GOV-GAT-nn].
///
/// Defines a single phase gate with its criteria, participants,
/// required evidence, entry/exit conditions, and review schedule.
class PhaseGateReviewEntry {
  @Form([
    // --- Gate Identity ---
    Field('gateName', String, 'Gate Name',
        hint:
            'Formal gate name — e.g. G1-ConceptApproval, '
            'G3-ReadyForRelease',
        required: true),
    Field('gateId', String, 'Gate ID',
        hint: 'Unique gate identifier — e.g. G1, G2, G3'),
    Field('gateDescription', String, 'Gate Description',
        hint:
            'Purpose of this gate — what it validates and why '
            'it exists'),
    Field('stage', String, 'Stage',
        hint:
            'Stage this gate is associated with — typically '
            'at stage exit',
        required: true),
    Field('gatePosition', String, 'Gate Position',
        hint:
            'StageEntry / MidStage / StageExit / CrossStage — '
            'when in the stage this gate occurs'),
    // --- Authority & Participants ---
    Field('decisionAuthority', String, 'Decision Authority',
        hint:
            'Person or body with final decision power — '
            'Steering Committee, PM, Sponsor',
        required: true),
    Field('mandatoryParticipants', String,
        'Mandatory Participants',
        hint:
            'Roles who must attend — comma-separated, e.g. '
            'PM, TechLead, QA Lead, Business Owner'),
    Field('advisoryParticipants', String,
        'Advisory Participants',
        hint:
            'Roles who participate in advisory capacity — '
            'not required for quorum'),
    Field('externalParticipants', String,
        'External Participants',
        hint:
            'External stakeholders — auditors, customer reps, '
            'vendor contacts'),
    // --- Schedule ---
    Field('scheduledDate', String, 'Scheduled Date',
        hint: 'Planned date for this gate review'),
    Field('preparationLeadTime', String, 'Preparation Lead Time',
        hint:
            'Days needed to prepare — e.g. 5 business days '
            'for evidence assembly'),
    Field('reviewDuration', String, 'Review Duration',
        hint:
            'Expected duration — e.g. 2 hours, 4 hours, '
            'full day'),
    // --- Entry Conditions ---
    Field('entryCriteria', String, 'Entry Criteria',
        hint:
            'Conditions that must be met before the gate can '
            'be held — all evidence submitted, no P1 defects '
            'open, prior gate passed'),
    Field('entryChecklistComplete', String,
        'Entry Checklist Complete',
        hint:
            'Yes / No / Partial — whether entry conditions '
            'have been verified'),
    // --- Evidence ---
    Field('requiredEvidence', String, 'Required Evidence',
        hint:
            'Artifacts to be presented — test reports, demo, '
            'architecture review, risk register update, '
            'budget actuals'),
    Field('evidenceFormat', String, 'Evidence Format',
        hint:
            'How evidence is presented — slide deck, live demo, '
            'document review, dashboard walkthrough'),
    Field('evidenceLocation', String, 'Evidence Location',
        hint:
            'Where evidence is stored — SharePoint folder, '
            'wiki page, CI/CD artifacts'),
    // --- Exit Conditions ---
    Field('exitCriteria', String, 'Exit Criteria',
        hint:
            'What must be true for the gate to pass — '
            'all criteria green, no critical open items, '
            'stakeholder sign-off',
        required: true),
    Field('minimumPassThreshold', String,
        'Minimum Pass Threshold',
        hint:
            'Quantified threshold — e.g. ≥80% criteria met, '
            'no critical items, all Must-haves complete'),
    // --- Outcome ---
    Field('gateOutcome', String, 'Gate Outcome',
        hint:
            'Proceed / ConditionalProceed / Rework / Hold / '
            'Cancel — actual decision (filled post-review)'),
    Field('outcomeRationale', String, 'Outcome Rationale',
        hint:
            'Why this decision was made — captured in minutes'),
    Field('conditionalItems', String, 'Conditional Items',
        hint:
            'Open items that must be resolved for conditional '
            'advancement — with deadlines'),
    Field('followUpActions', String, 'Follow-Up Actions',
        hint:
            'Actions assigned during review — owner, deadline, '
            'status tracking'),
    Field('nextGateReference', String, 'Next Gate Reference',
        hint:
            'Gate ID of the next gate in sequence — for '
            'traceability'),
  ])
  String? content;

  /// Gate-specific narrative and context.
  TextSection gateNarrative = TextSection();

  /// Contains 0+× ReviewCriterionEntry.
  @SectionIdPattern('PD00-SSP-GOV-GAT-xx-RCR-xx')
  List<ReviewCriterionEntry> reviewCriteria = [];
}

/// A review criterion entry (form) [PD00-SSP-GOV-GAT-nn-RCR-nn].
///
/// A single criterion evaluated at a phase gate, with weight,
/// evidence linkage, and assessment result.
class ReviewCriterionEntry {
  @Form([
    // --- Criterion Definition ---
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
    // --- Assessment ---
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
    // --- Result (filled post-review) ---
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

/// 13.6.2. Decision Points [PD00-SSP-GOV-DEC].
///
/// Key decision points in the stage plan including go/no-go
/// decisions, scope adjustments, resource reallocations, and
/// technology selections. Each decision point has defined timing,
/// criteria, authority, options, and impact analysis.
@SectionId('PD00-SSP-GOV-DEC')
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
  TextSection decisionFrameworkNarrative = TextSection();

  /// Contains 0+× DecisionPointEntry.
  @SectionIdPattern('PD00-SSP-GOV-DEC-xx')
  List<DecisionPointEntry> items = [];
}

/// A decision point entry (form) [PD00-SSP-GOV-DEC-nn].
///
/// A single formal decision point with defined timing, criteria,
/// authority, available options with impact analysis, and recording
/// of the actual decision and its rationale.
class DecisionPointEntry {
  @Form([
    // --- Decision Identity ---
    Field('decisionId', String, 'Decision ID',
        hint: 'Unique identifier — e.g. DEC-001, DP-G2-01',
        required: true),
    Field('decisionPoint', String, 'Decision Point',
        hint:
            'Short name — e.g. Go/No-Go for Production, '
            'Technology Stack Selection',
        required: true),
    Field('decisionDescription', String, 'Decision Description',
        hint:
            'Detailed description of what needs to be decided'),
    Field('decisionCategory', String, 'Decision Category',
        hint:
            'GoNoGo / ScopeChange / ResourceReallocation / '
            'TechnologySelection / VendorSelection / '
            'ArchitectureChange / RiskResponse',
        required: true),
    // --- Context & Timing ---
    Field('stage', String, 'Stage',
        hint: 'Stage where this decision occurs'),
    Field('timing', String, 'Timing',
        hint:
            'When in the stage — StageEntry / MidStage / '
            'StageExit / BeforeGate / AfterGate / OnDemand',
        required: true),
    Field('deadline', String, 'Decision Deadline',
        hint:
            'Latest date by which decision must be made — '
            'after this date, default option applies'),
    Field('triggerEvent', String, 'Trigger Event',
        hint:
            'What triggers this decision point — gate outcome, '
            'risk materialization, milestone reached, '
            'stakeholder request'),
    // --- Stakeholders ---
    Field('decisionAuthority', String, 'Decision Authority',
        hint:
            'Person or body making the final decision — DACI: '
            'Driver, Approver, Contributor, Informed',
        required: true),
    Field('decisionDriver', String, 'Decision Driver',
        hint:
            'Person responsible for driving the decision to '
            'conclusion — typically PM or Product Owner'),
    Field('contributors', String, 'Contributors',
        hint:
            'People providing input — architects, analysts, '
            'domain experts — comma-separated'),
    Field('informedParties', String, 'Informed Parties',
        hint:
            'Stakeholders informed of the outcome — '
            'comma-separated'),
    // --- Criteria & Inputs ---
    Field('decisionCriteria', String, 'Decision Criteria',
        hint:
            'Criteria for making this decision — cost, risk, '
            'time, quality, strategic alignment, feasibility',
        required: true),
    Field('requiredInputs', String, 'Required Inputs',
        hint:
            'Information or artifacts needed — cost analysis, '
            'risk assessment, prototype results, vendor '
            'proposals'),
    Field('constraintFactors', String, 'Constraint Factors',
        hint:
            'Constraints limiting the decision space — budget, '
            'regulatory, technology, timeline'),
    Field('riskIfDelayed', String, 'Risk if Delayed',
        hint:
            'Consequence of not making the decision on time — '
            'schedule slip, cost increase, missed window'),
    // --- Resolution (filled when decided) ---
    Field('selectedOption', String, 'Selected Option',
        hint:
            'Which option was chosen — references option ID '
            'or name'),
    Field('decisionRationale', String, 'Decision Rationale',
        hint:
            'Why this option was selected — trade-off analysis '
            'summary'),
    Field('decisionDate', String, 'Decision Date',
        hint: 'When the decision was formally made'),
    Field('decisionRecordReference', String,
        'Decision Record Reference',
        hint:
            'Link to the formal decision record — ADR number, '
            'meeting minutes reference'),
    Field('revisitDate', String, 'Revisit Date',
        hint:
            'When this decision should be revisited — if '
            'conditions change, or after a defined period'),
    Field('impactSummary', String, 'Impact Summary',
        hint:
            'Impact of the decision — affected stages, teams, '
            'budget, schedule'),
  ])
  String? content;

  /// Decision context narrative.
  TextSection decisionNarrative = TextSection();

  /// Contains 0+× DecisionOptionEntry.
  @SectionIdPattern('PD00-SSP-GOV-DEC-xx-OPT-xx')
  List<DecisionOptionEntry> options = [];
}

/// A decision option entry (form) [PD00-SSP-GOV-DEC-nn-OPT-nn].
///
/// One of the available options for a decision point, with full
/// impact analysis, feasibility assessment, and trade-off evaluation.
class DecisionOptionEntry {
  @Form([
    // --- Option Identity ---
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
    Field('isDefault', String, 'Is Default Option',
        hint:
            'Yes / No — whether this is the fallback if no '
            'decision is reached by deadline'),
    Field('isRecommended', String, 'Is Recommended',
        hint:
            'Yes / No — whether the analysis team recommends '
            'this option'),
    // --- Impact Analysis ---
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
    // --- Feasibility ---
    Field('technicalFeasibility', String,
        'Technical Feasibility',
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
    // --- Trade-offs ---
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
