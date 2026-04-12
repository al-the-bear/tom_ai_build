/// Section 5: Organizational Framework [PD00-ORG].
///
/// Organizational changes and structures required for the new system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 5. Organizational Framework [PD00-ORG].
@SectionId('PD00-ORG')
class OrganizationalFramework {
  @Unused()
  String? content;

  /// 5.1. New Organization Structure [PD00-ORG-STR].
  NewOrganizationStructure organizationStructure = NewOrganizationStructure();

  /// 5.2. Job Descriptions and Staffing Plans [PD00-ORG-JOB].
  JobDescriptionsAndStaffing jobDescriptions = JobDescriptionsAndStaffing();

  /// 5.3. Workplace Descriptions [PD00-ORG-WOR] — contains 1+× per user category.
  @SectionIdPattern('PD00-ORG-WOR-xx')
  @Min(1)
  @Comment('per user category')
  List<WorkplaceDescriptionEntry> workplaceDescriptions = [];
}

// ---------------------------------------------------------------------------
// 5.1 New Organization Structure
// ---------------------------------------------------------------------------

/// 5.1. New Organization Structure [PD00-ORG-STR].
@SectionId('PD00-ORG-STR')
class NewOrganizationStructure {
  @Unused()
  String? content;

  /// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
  ChangesFromCurrentStructure changesFromCurrentStructure =
      ChangesFromCurrentStructure();

  /// 5.1.2. Organizational Transition Timeline [PD00-ORG-STR-TIM].
  OrganizationalTransitionTimeline transitionTimeline =
      OrganizationalTransitionTimeline();
}

/// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
@SectionId('PD00-ORG-STR-CHA')
class ChangesFromCurrentStructure {
  @Unused()
  String? content;

  /// Contains 0+× OrganizationalChange.
  @SectionIdPattern('PD00-ORG-STR-CHA-xx')
  List<OrganizationalChangeEntry> items = [];
}

/// An organizational change entry (form) [PD00-ORG-STR-CHA-nn].
class OrganizationalChangeEntry {
  @Form([
    Field('area', String, 'Area'),
    Field('currentState', String, 'Current State'),
    Field('targetState', String, 'Target State'),
    Field('rationale', String, 'Rationale'),
    Field('impact', String, 'Impact assessment'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 5.1.2 Organizational Transition Timeline
// ---------------------------------------------------------------------------

/// 5.1.2. Organizational Transition Timeline [PD00-ORG-STR-TIM].
///
/// Describes when organizational changes take effect, how the transition is
/// managed, and what training or communication is needed. Follows change
/// management best practices (PROSCI ADKAR, Kotter's 8-step model).
@SectionId('PD00-ORG-STR-TIM')
class OrganizationalTransitionTimeline {
  /// Overview of the transition approach and guiding principles.
  TransitionOverview overview = TransitionOverview();

  /// Transition phases with milestones and durations.
  @SectionIdPattern('PD00-ORG-STR-TIM-PHA-xx')
  List<TransitionPhaseEntry> phases = [];

  /// Key transition milestones and decision gates.
  @SectionIdPattern('PD00-ORG-STR-TIM-MIL-xx')
  List<TransitionMilestoneEntry> milestones = [];

  /// Change readiness assessment approach.
  ChangeReadinessAssessment changeReadiness = ChangeReadinessAssessment();

  /// Communication plan for the transition.
  TransitionCommunicationPlan communicationPlan = TransitionCommunicationPlan();

  /// Support structure during transition.
  TransitionSupportStructure supportStructure = TransitionSupportStructure();

  /// Success metrics and measurement approach.
  TransitionSuccessMetrics successMetrics = TransitionSuccessMetrics();

  /// Risks specific to the organizational transition.
  @SectionIdPattern('PD00-ORG-STR-TIM-RSK-xx')
  List<TransitionRiskEntry> transitionRisks = [];
}

/// Overview of the organizational transition approach.
class TransitionOverview {
  @Form([
    Field('transitionApproach', String,
        'Transition Approach — phased, big-bang, parallel run, pilot'),
    Field('changeManagementMethodology', String,
        'Change Management Methodology — PROSCI ADKAR, Kotter, Lewin, custom'),
    Field('transitionStartDate', String, 'Transition Start Date'),
    Field('targetCompletionDate', String, 'Target Completion Date'),
    Field('transitionDuration', String,
        'Overall Transition Duration — weeks/months'),
    Field('parallelOperationPeriod', String,
        'Parallel Operation Period — duration of overlap with old processes'),
    Field('cutoverStrategy', String,
        'Cutover Strategy — planning for go-live moment'),
    Field('rollbackPlan', String,
        'Rollback Plan — fallback if transition fails'),
    Field('transitionGovernance', String,
        'Transition Governance — oversight structure and decision authority'),
    Field('transitionOwner', String,
        'Transition Owner — accountable person/role'),
    Field('changeChampions', String,
        'Change Champions — advocates in each affected area'),
  ])
  String? content;
}

/// A transition phase entry [PD00-ORG-STR-TIM-PHA-nn] (form).
///
/// Defines a distinct phase in the organizational transition sequence.
class TransitionPhaseEntry {
  /// Phase identification and timeline.
  TransitionPhaseIdentification identification =
      TransitionPhaseIdentification();

  /// Activities and deliverables for this phase.
  TransitionPhaseActivities activities = TransitionPhaseActivities();

  /// Stakeholder engagement for this phase.
  TransitionPhaseStakeholders stakeholders = TransitionPhaseStakeholders();

  /// Exit criteria and phase completion conditions.
  TransitionPhaseExitCriteria exitCriteria = TransitionPhaseExitCriteria();
}

/// Phase identification and timeline.
class TransitionPhaseIdentification {
  @Form([
    Field('phaseId', String, 'Phase ID (e.g., PH-01)', required: true),
    Field('phaseName', String, 'Phase Name', required: true),
    Field('phaseType', String,
        'Phase Type — Preparation, Pilot, Rollout, Stabilization, Closure'),
    Field('startDate', String, 'Start Date'),
    Field('endDate', String, 'End Date'),
    Field('duration', String, 'Duration — weeks'),
    Field('precedingPhase', String, 'Preceding Phase — phase ID'),
    Field('dependsOnMilestone', String, 'Depends on Milestone — milestone ID'),
    Field('phaseOwner', String, 'Phase Owner'),
    Field('affectedLocations', String,
        'Affected Locations — sites/regions in scope'),
    Field('affectedDepartments', String,
        'Affected Departments — organizational units'),
    Field('affectedUserCount', int, 'Affected User Count'),
  ])
  String? content;
}

/// Activities and deliverables for a transition phase.
class TransitionPhaseActivities {
  @Form([
    Field('keyActivities', String,
        'Key Activities — main tasks to complete in this phase'),
    Field('trainingActivities', String,
        'Training Activities — training to deliver'),
    Field('communicationActivities', String,
        'Communication Activities — announcements, meetings'),
    Field('systemActivities', String,
        'System Activities — technical preparations, data migration'),
    Field('processActivities', String,
        'Process Activities — process rollout, SOP distribution'),
    Field('deliverables', String, 'Phase Deliverables — outputs to produce'),
    Field('resourceRequirements', String,
        'Resource Requirements — people, budget, tools'),
    Field('externalSupport', String,
        'External Support — consultants, vendors needed'),
  ])
  String? content;
}

/// Stakeholder engagement for a transition phase.
class TransitionPhaseStakeholders {
  @Form([
    Field('primaryStakeholders', String,
        'Primary Stakeholders — directly impacted groups'),
    Field('engagementApproach', String,
        'Engagement Approach — how stakeholders are involved'),
    Field('feedbackMechanism', String,
        'Feedback Mechanism — how input is collected'),
    Field('escalationPath', String,
        'Escalation Path — for issues during this phase'),
    Field('sponsorInvolvement', String,
        'Sponsor Involvement — executive actions needed'),
  ])
  String? content;
}

/// Exit criteria for a transition phase.
class TransitionPhaseExitCriteria {
  @Form([
    Field('exitCriteria', String,
        'Exit Criteria — conditions to complete phase'),
    Field('signOffRequired', String,
        'Sign-Off Required — who must approve phase completion'),
    Field('qualityGates', String, 'Quality Gates — checks to pass'),
    Field('successIndicators', String,
        'Success Indicators — measurable outcomes'),
    Field('knownIssuesResolution', String,
        'Known Issues Resolution — outstanding items allowed'),
  ])
  String? content;
}

/// A transition milestone entry [PD00-ORG-STR-TIM-MIL-nn] (form).
class TransitionMilestoneEntry {
  @Form([
    Field('milestoneId', String, 'Milestone ID (e.g., MS-01)', required: true),
    Field('milestoneName', String, 'Milestone Name', required: true),
    Field('milestoneType', String,
        'Milestone Type — Decision Gate, Checkpoint, Go-Live, Closure'),
    Field('targetDate', String, 'Target Date'),
    Field('actualDate', String, 'Actual Date — when achieved'),
    Field('status', String,
        'Status — Planned, On Track, At Risk, Delayed, Achieved'),
    Field('description', String, 'Description'),
    Field('deliverables', String, 'Deliverables — required for milestone'),
    Field('decisionRequired', String,
        'Decision Required — Go/No-Go decision at this point'),
    Field('decisionOwner', String, 'Decision Owner'),
    Field('dependsOnPhases', String,
        'Depends on Phases — phases that must complete'),
    Field('dependsOnMilestones', String,
        'Depends on Milestones — prior milestones required'),
    Field('criticality', String, 'Criticality — High, Medium, Low'),
    Field('celebrationActivities', String,
        'Celebration Activities — recognition for achieving milestone'),
  ])
  String? content;
}

/// Change readiness assessment approach.
class ChangeReadinessAssessment {
  /// Overview of readiness assessment approach.
  ChangeReadinessOverview overview = ChangeReadinessOverview();

  /// Readiness criteria per stakeholder group.
  @SectionIdPattern('PD00-ORG-STR-TIM-RDY-xx')
  List<ReadinessCriteriaEntry> readinessCriteria = [];
}

/// Overview of change readiness assessment.
class ChangeReadinessOverview {
  @Form([
    Field('assessmentMethod', String,
        'Assessment Method — surveys, interviews, observations, readiness gates'),
    Field('assessmentFrequency', String,
        'Assessment Frequency — how often readiness is evaluated'),
    Field('readinessOwner', String,
        'Readiness Owner — who tracks readiness'),
    Field('minimumReadinessLevel', String,
        'Minimum Readiness Level — threshold to proceed'),
    Field('escalationTrigger', String,
        'Escalation Trigger — when to escalate readiness concerns'),
    Field('readinessTooling', String,
        'Readiness Tooling — tools/surveys used for assessment'),
    Field('adkarFocus', String,
        'ADKAR Focus — Awareness, Desire, Knowledge, Ability, Reinforcement status'),
  ])
  String? content;
}

/// Readiness criteria entry [PD00-ORG-STR-TIM-RDY-nn] (form).
class ReadinessCriteriaEntry {
  @Form([
    Field('stakeholderGroup', String, 'Stakeholder Group', required: true),
    Field('awarenessLevel', String,
        'Awareness Level — understanding of change (1-5)'),
    Field('desireLevel', String, 'Desire Level — willingness to participate (1-5)'),
    Field('knowledgeLevel', String,
        'Knowledge Level — skills/knowledge acquired (1-5)'),
    Field('abilityLevel', String,
        'Ability Level — demonstrated capability (1-5)'),
    Field('reinforcementNeeded', String,
        'Reinforcement Needed — support to sustain change'),
    Field('resistanceFactors', String,
        'Resistance Factors — barriers to adoption'),
    Field('mitigationActions', String,
        'Mitigation Actions — how to address resistance'),
    Field('readinessStatus', String,
        'Readiness Status — Ready, Needs Work, At Risk, Not Ready'),
    Field('assessmentDate', String, 'Last Assessment Date'),
  ])
  String? content;
}

/// Communication plan for the transition.
class TransitionCommunicationPlan {
  /// Communication strategy overview.
  TransitionCommunicationStrategy strategy = TransitionCommunicationStrategy();

  /// Specific communication events/activities.
  @SectionIdPattern('PD00-ORG-STR-TIM-COM-xx')
  List<CommunicationEventEntry> communicationEvents = [];

  /// Communication channels and their use.
  TransitionCommunicationChannels channels = TransitionCommunicationChannels();
}

/// Communication strategy overview.
class TransitionCommunicationStrategy {
  @Form([
    Field('communicationStrategy', String,
        'Communication Strategy — overall approach'),
    Field('keyMessages', String,
        'Key Messages — core messages to convey throughout'),
    Field('messagingOwner', String,
        'Messaging Owner — who controls/approves communications'),
    Field('feedbackChannels', String,
        'Feedback Channels — how stakeholders can respond'),
    Field('communicationCadence', String,
        'Communication Cadence — frequency of updates'),
    Field('brandingGuidelines', String,
        'Branding Guidelines — visual identity for change'),
    Field('languageRequirements', String,
        'Language Requirements — languages/translations needed'),
    Field('accessibilityRequirements', String,
        'Accessibility Requirements — accessibility considerations'),
  ])
  String? content;
}

/// Communication event entry [PD00-ORG-STR-TIM-COM-nn] (form).
class CommunicationEventEntry {
  @Form([
    Field('eventId', String, 'Event ID', required: true),
    Field('eventName', String, 'Event Name', required: true),
    Field('eventType', String,
        'Event Type — Announcement, Town Hall, Email, Workshop, Newsletter'),
    Field('targetAudience', String, 'Target Audience'),
    Field('scheduledDate', String, 'Scheduled Date'),
    Field('phase', String, 'Phase — which transition phase'),
    Field('keyMessages', String, 'Key Messages — specific to this event'),
    Field('channel', String, 'Channel — delivery method'),
    Field('owner', String, 'Owner — who prepares/delivers'),
    Field('approver', String, 'Approver — who approves content'),
    Field('materialsRequired', String, 'Materials Required — slides, scripts, etc.'),
    Field('followUpActions', String, 'Follow-Up Actions — after event'),
    Field('successMeasure', String, 'Success Measure — how effectiveness is measured'),
    Field('status', String, 'Status — Planned, In Preparation, Delivered, Cancelled'),
  ])
  String? content;
}

/// Communication channels definition.
class TransitionCommunicationChannels {
  @Form([
    Field('primaryChannels', String,
        'Primary Channels — main communication methods'),
    Field('urgentChannels', String,
        'Urgent Channels — for time-sensitive communications'),
    Field('feedbackChannels', String,
        'Feedback Channels — for two-way communication'),
    Field('documentationRepository', String,
        'Documentation Repository — where materials are stored'),
    Field('channelOwnership', String,
        'Channel Ownership — who manages each channel'),
    Field('channelAccessibility', String,
        'Channel Accessibility — who can access what'),
  ])
  String? content;
}

/// Support structure during transition.
class TransitionSupportStructure {
  /// Support organization overview.
  TransitionSupportOverview overview = TransitionSupportOverview();

  /// Support resources available.
  @SectionIdPattern('PD00-ORG-STR-TIM-SUP-xx')
  List<TransitionSupportResourceEntry> supportResources = [];

  /// Escalation paths for support.
  TransitionEscalationPaths escalationPaths = TransitionEscalationPaths();
}

/// Support structure overview.
class TransitionSupportOverview {
  @Form([
    Field('supportModel', String,
        'Support Model — tiered support, buddy system, floor walkers'),
    Field('supportHours', String,
        'Support Hours — when support is available'),
    Field('supportChannels', String,
        'Support Channels — help desk, chat, in-person, phone'),
    Field('supportCapacity', String,
        'Support Capacity — expected volumes and staffing'),
    Field('supportDuration', String,
        'Support Duration — how long enhanced support lasts'),
    Field('transitionToBAU', String,
        'Transition to BAU — when/how support moves to business-as-usual'),
    Field('knowledgeBase', String,
        'Knowledge Base — self-service resources available'),
    Field('superUserNetwork', String,
        'Super-User Network — local experts in each area'),
  ])
  String? content;
}

/// Support resource entry [PD00-ORG-STR-TIM-SUP-nn] (form).
class TransitionSupportResourceEntry {
  @Form([
    Field('resourceType', String,
        'Resource Type — Help Desk, Super User, Floor Walker, Coach, FAQ',
        required: true),
    Field('resourceName', String, 'Resource Name/Title'),
    Field('availabilityPeriod', String,
        'Availability Period — start/end dates'),
    Field('coverage', String, 'Coverage — locations/departments covered'),
    Field('contactInfo', String, 'Contact Info — how to reach'),
    Field('capacity', String, 'Capacity — how many can be supported'),
    Field('skills', String, 'Skills — expertise areas'),
    Field('owner', String, 'Owner — who manages this resource'),
    Field('costCenter', String, 'Cost Center — budget allocation'),
  ])
  String? content;
}

/// Escalation paths for transition support.
class TransitionEscalationPaths {
  @Form([
    Field('level1', String, 'Level 1 — first-line support'),
    Field('level2', String, 'Level 2 — specialist support'),
    Field('level3', String, 'Level 3 — expert/vendor support'),
    Field('emergencyContact', String, 'Emergency Contact — critical issues'),
    Field('escalationCriteria', String,
        'Escalation Criteria — when to escalate'),
    Field('responseTimeTargets', String,
        'Response Time Targets — per severity level'),
    Field('managementEscalation', String,
        'Management Escalation — for organizational issues'),
  ])
  String? content;
}

/// Success metrics for the transition.
class TransitionSuccessMetrics {
  /// Metrics overview.
  TransitionMetricsOverview overview = TransitionMetricsOverview();

  /// Specific success metrics.
  @SectionIdPattern('PD00-ORG-STR-TIM-MET-xx')
  List<TransitionMetricEntry> metrics = [];
}

/// Metrics overview.
class TransitionMetricsOverview {
  @Form([
    Field('measurementApproach', String,
        'Measurement Approach — how success is evaluated'),
    Field('reportingCadence', String,
        'Reporting Cadence — how often metrics are reported'),
    Field('reportingOwner', String,
        'Reporting Owner — who produces reports'),
    Field('reportingAudience', String,
        'Reporting Audience — who receives reports'),
    Field('dashboardLocation', String,
        'Dashboard Location — where metrics are visible'),
    Field('baselinePeriod', String,
        'Baseline Period — when baseline was established'),
    Field('targetAchievementDate', String,
        'Target Achievement Date — when targets should be met'),
  ])
  String? content;
}

/// Transition metric entry [PD00-ORG-STR-TIM-MET-nn] (form).
class TransitionMetricEntry {
  @Form([
    Field('metricId', String, 'Metric ID', required: true),
    Field('metricName', String, 'Metric Name', required: true),
    Field('category', String,
        'Category — Adoption, Performance, Quality, Satisfaction, Efficiency'),
    Field('description', String, 'Description'),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('baseline', String, 'Baseline Value'),
    Field('target', String, 'Target Value'),
    Field('threshold', String, 'Threshold — minimum acceptable'),
    Field('currentValue', String, 'Current Value'),
    Field('measurementFrequency', String, 'Measurement Frequency'),
    Field('dataSource', String, 'Data Source'),
    Field('owner', String, 'Owner'),
    Field('status', String, 'Status — On Track, At Risk, Below Target, Achieved'),
    Field('trend', String, 'Trend — Improving, Stable, Declining'),
  ])
  String? content;
}

/// Transition risk entry [PD00-ORG-STR-TIM-RSK-nn] (form).
class TransitionRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID', required: true),
    Field('riskName', String, 'Risk Name', required: true),
    Field('riskCategory', String,
        'Risk Category — Resistance, Capacity, Timing, Resources, Dependencies'),
    Field('description', String, 'Description'),
    Field('probability', String, 'Probability — Low, Medium, High'),
    Field('impact', String, 'Impact — Low, Medium, High'),
    Field('affectedPhases', String, 'Affected Phases'),
    Field('mitigationStrategy', String, 'Mitigation Strategy'),
    Field('contingencyPlan', String, 'Contingency Plan'),
    Field('owner', String, 'Risk Owner'),
    Field('status', String, 'Status — Active, Mitigated, Realized, Closed'),
    Field('earlyWarningIndicator', String, 'Early Warning Indicator'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 5.2 Job Descriptions and Staffing Plans
// ---------------------------------------------------------------------------

/// 5.2. Job Descriptions and Staffing Plans [PD00-ORG-JOB].
///
/// Documents new and changed roles resulting from the system introduction,
/// following HR best practices and job analysis methodologies (O*NET, SHRM).
/// Includes competency frameworks, staffing projections, and recruitment planning.
@SectionId('PD00-ORG-JOB')
class JobDescriptionsAndStaffing {
  /// Overview of the job architecture and role design approach.
  JobDescriptionsOverview overview = JobDescriptionsOverview();

  /// 5.2.1. New Roles [PD00-ORG-JOB-NEW] — contains 0+× New Role.
  @SectionIdPattern('PD00-ORG-JOB-NEW-xx')
  List<NewRoleEntry> newRoles = [];

  /// 5.2.2. Changed Roles [PD00-ORG-JOB-CHA] — contains 0+× Changed Role.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx')
  List<ChangedRoleEntry> changedRoles = [];

  /// 5.2.3. Removed Roles [PD00-ORG-JOB-REM] — contains 0+× role being eliminated.
  @SectionIdPattern('PD00-ORG-JOB-REM-xx')
  List<RemovedRoleEntry> removedRoles = [];

  /// 5.2.4. Staffing Plan [PD00-ORG-JOB-STA].
  StaffingPlan staffingPlan = StaffingPlan();

  /// 5.2.5. Competency Framework [PD00-ORG-JOB-CMP].
  CompetencyFramework competencyFramework = CompetencyFramework();
}

/// Overview of job descriptions and staffing approach.
class JobDescriptionsOverview {
  @Form([
    Field('roleDesignApproach', String,
        'Role Design Approach — methodology for defining roles'),
    Field('jobArchitectureModel', String,
        'Job Architecture Model — job families, levels, career paths'),
    Field('competencyModel', String,
        'Competency Model — framework for defining skills/competencies'),
    Field('gradingStructure', String,
        'Grading Structure — how roles are graded/leveled'),
    Field('totalRoleImpact', String,
        'Total Role Impact — summary of new/changed/removed roles'),
    Field('totalFteChange', String,
        'Total FTE Change — net headcount impact'),
    Field('hrPartner', String, 'HR Partner — HR contact for role changes'),
    Field('unionConsiderations', String,
        'Union/Works Council Considerations — labor relations impact'),
    Field('legalRequirements', String,
        'Legal Requirements — employment law considerations'),
  ])
  String? content;
}

/// 5.2.4. Staffing Plan [PD00-ORG-JOB-STA].
@SectionId('PD00-ORG-JOB-STA')
class StaffingPlan {
  /// Staffing plan overview.
  StaffingPlanOverview overview = StaffingPlanOverview();

  /// Budget details.
  StaffingBudget budget = StaffingBudget();

  /// Contains 0+× Staffing entry.
  @SectionIdPattern('PD00-ORG-JOB-STA-xx')
  List<StaffingEntry> items = [];

  /// Recruitment timeline.
  RecruitmentTimeline recruitmentTimeline = RecruitmentTimeline();
}

/// Staffing plan overview.
class StaffingPlanOverview {
  @Form([
    Field('staffingStrategy', String,
        'Staffing Strategy — hire, promote, contract, outsource mix'),
    Field('sourcingChannels', String,
        'Sourcing Channels — internal, external, agencies, referrals'),
    Field('selectionProcess', String,
        'Selection Process — interviews, assessments, background checks'),
    Field('onboardingApproach', String,
        'Onboarding Approach — new hire integration plan'),
    Field('retentionStrategy', String,
        'Retention Strategy — how to keep critical talent'),
    Field('successionPlanning', String,
        'Succession Planning — backup for key positions'),
    Field('contingentWorkforce', String,
        'Contingent Workforce — contractors, temps, consultants'),
    Field('geographicDistribution', String,
        'Geographic Distribution — locations where hires are needed'),
  ])
  String? content;
}

/// Staffing budget details.
class StaffingBudget {
  @Form([
    Field('totalBudget', String, 'Total Staffing Budget'),
    Field('salaryBudget', String, 'Salary Budget — base compensation'),
    Field('benefitsBudget', String, 'Benefits Budget — insurance, retirement'),
    Field('recruitmentBudget', String,
        'Recruitment Budget — agencies, advertising, travel'),
    Field('trainingBudget', String, 'Training Budget — onboarding, development'),
    Field('relocatonBudget', String, 'Relocation Budget — if applicable'),
    Field('contingencyBudget', String,
        'Contingency Budget — buffer for unforeseen needs'),
    Field('budgetOwner', String, 'Budget Owner'),
    Field('approvalRequired', String, 'Approval Required — who must approve'),
    Field('budgetTimeline', String, 'Budget Timeline — fiscal year alignment'),
  ])
  String? content;
}

/// A staffing entry (form) [PD00-ORG-JOB-STA-nn].
class StaffingEntry {
  @Form([
    Field('roleTitle', String, 'Role Title', required: true),
    Field('jobFamily', String, 'Job Family'),
    Field('jobLevel', String, 'Job Level — grade/level'),
    Field('department', String, 'Department'),
    Field('location', String, 'Location — site/region'),
    Field('fteCount', double, 'FTE Count'),
    Field('headcount', int, 'Headcount — number of positions'),
    Field('employmentType', String,
        'Employment Type — permanent, contract, part-time'),
    Field('sourcingMethod', String,
        'Sourcing Method — internal, external, agency'),
    Field('recruitmentStatus', String,
        'Recruitment Status — approved, posted, interviewing, offered, filled'),
    Field('targetStartDate', String, 'Target Start Date'),
    Field('urgency', String, 'Urgency — critical, high, medium, low'),
    Field('hiringManager', String, 'Hiring Manager'),
    Field('recruiter', String, 'Recruiter — HR contact'),
    Field('salaryRange', String, 'Salary Range'),
    Field('notes', String, 'Notes'),
  ])
  String? content;
}

/// Recruitment timeline.
class RecruitmentTimeline {
  @Form([
    Field('recruitmentStart', String, 'Recruitment Start Date'),
    Field('recruitmentEnd', String, 'Recruitment End Date'),
    Field('criticalHires', String,
        'Critical Hires — roles that must be filled first'),
    Field('hiringWaves', String,
        'Hiring Waves — phased recruitment approach'),
    Field('leadTimeAssumptions', String,
        'Lead Time Assumptions — time to hire per role type'),
    Field('onboardingWaves', String, 'Onboarding Waves — start date cohorts'),
  ])
  String? content;
}

/// 5.2.5. Competency Framework [PD00-ORG-JOB-CMP].
@SectionId('PD00-ORG-JOB-CMP')
class CompetencyFramework {
  /// Framework overview.
  CompetencyFrameworkOverview overview = CompetencyFrameworkOverview();

  /// Core competencies required across all roles.
  @SectionIdPattern('PD00-ORG-JOB-CMP-COR-xx')
  List<CompetencyEntry> coreCompetencies = [];

  /// Technical/functional competencies by role family.
  @SectionIdPattern('PD00-ORG-JOB-CMP-TEC-xx')
  List<CompetencyEntry> technicalCompetencies = [];

  /// Leadership competencies for management roles.
  @SectionIdPattern('PD00-ORG-JOB-CMP-LED-xx')
  List<CompetencyEntry> leadershipCompetencies = [];
}

/// Competency framework overview.
class CompetencyFrameworkOverview {
  @Form([
    Field('frameworkPurpose', String,
        'Framework Purpose — how competencies guide hiring/development'),
    Field('competencyModel', String,
        'Competency Model — model name/source (SHRM, custom, etc.)'),
    Field('proficiencyLevels', String,
        'Proficiency Levels — scale used (1-5, Novice to Expert, etc.)'),
    Field('assessmentMethod', String,
        'Assessment Method — how competencies are measured'),
    Field('developmentApproach', String,
        'Development Approach — how gaps are addressed'),
  ])
  String? content;
}

/// A competency entry (form) [PD00-ORG-JOB-CMP-xx-nn].
class CompetencyEntry {
  @Form([
    Field('competencyId', String, 'Competency ID', required: true),
    Field('competencyName', String, 'Competency Name', required: true),
    Field('category', String,
        'Category — Core, Technical, Leadership, Behavioral'),
    Field('description', String, 'Description'),
    Field('behavioralIndicators', String,
        'Behavioral Indicators — observable behaviors'),
    Field('proficiencyLevels', String,
        'Proficiency Levels — what each level looks like'),
    Field('applicableRoles', String,
        'Applicable Roles — which roles need this competency'),
    Field('requiredLevel', String,
        'Required Level — minimum proficiency for the role'),
    Field('developmentResources', String,
        'Development Resources — training, coaching, experiences'),
    Field('assessmentTools', String,
        'Assessment Tools — tests, interviews, simulations'),
  ])
  String? content;
}

/// A new role entry [PD00-ORG-JOB-NEW-nn] (form).
///
/// Comprehensive new role definition following HR job analysis best practices.
/// Includes competencies, responsibilities, system access, and success metrics.
class NewRoleEntry {
  /// Role identification and overview.
  NewRoleIdentification identification = NewRoleIdentification();

  /// Role positioning in organization.
  NewRoleOrganization organization = NewRoleOrganization();

  /// Responsibilities breakdown.
  NewRoleResponsibilities responsibilities = NewRoleResponsibilities();

  /// Required competencies and qualifications.
  NewRoleQualifications qualifications = NewRoleQualifications();

  /// System access and tools.
  NewRoleSystemAccess systemAccess = NewRoleSystemAccess();

  /// Performance and success metrics.
  NewRolePerformance performance = NewRolePerformance();

  /// Onboarding and development.
  NewRoleOnboarding onboarding = NewRoleOnboarding();
}

/// New role identification.
class NewRoleIdentification {
  @Form([
    Field('roleId', String, 'Role ID (e.g., NR-001)', required: true),
    Field('roleTitle', String, 'Role Title', required: true),
    Field('roleFamily', String, 'Job Family'),
    Field('jobLevel', String, 'Job Level/Grade'),
    Field('rolePurpose', String, 'Role Purpose — why this role exists'),
    Field('roleJustification', String,
        'Role Justification — business case for new role'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('roleStatus', String,
        'Role Status — draft, approved, posted, filled'),
  ])
  String? content;
}

/// New role organizational positioning.
class NewRoleOrganization {
  @Form([
    Field('department', String, 'Department'),
    Field('division', String, 'Division/Business Unit'),
    Field('team', String, 'Team — immediate team'),
    Field('location', String, 'Location — primary work location'),
    Field('workModel', String,
        'Work Model — on-site, remote, hybrid'),
    Field('reportsTo', String, 'Reports To — direct manager title'),
    Field('directReports', String, 'Direct Reports — roles reporting to this'),
    Field('matrixRelationships', String,
        'Matrix Relationships — dotted-line reporting'),
    Field('keyStakeholders', String,
        'Key Stakeholders — internal/external contacts'),
    Field('collaborationScope', String,
        'Collaboration Scope — teams/departments interacted with'),
  ])
  String? content;
}

/// New role responsibilities.
class NewRoleResponsibilities {
  /// Primary responsibilities (key accountabilities).
  @SectionIdPattern('PD00-ORG-JOB-NEW-xx-RSP-xx')
  List<ResponsibilityDetailEntry> primaryResponsibilities = [];

  /// Secondary responsibilities (supporting duties).
  List<ResponsibilityDetailEntry> secondaryResponsibilities = [];

  /// Decision-making authority.
  RoleDecisionAuthority decisionAuthority = RoleDecisionAuthority();
}

/// Detailed responsibility entry [PD00-ORG-JOB-NEW-nn-RSP-nn] (form).
class ResponsibilityDetailEntry {
  @Form([
    Field('responsibilityId', String, 'Responsibility ID'),
    Field('responsibility', String, 'Responsibility', required: true),
    Field('description', String, 'Description — detailed explanation'),
    Field('timeAllocation', String,
        'Time Allocation — percentage of time spent'),
    Field('frequency', String, 'Frequency — daily, weekly, monthly, ad-hoc'),
    Field('deliverables', String, 'Deliverables — outputs expected'),
    Field('qualityStandards', String, 'Quality Standards — success criteria'),
    Field('relatedProcesses', String,
        'Related Processes — business processes involved'),
    Field('toolsUsed', String, 'Tools Used — systems/applications'),
  ])
  String? content;
}

/// Role decision-making authority.
class RoleDecisionAuthority {
  @Form([
    Field('approvalAuthority', String,
        'Approval Authority — what can be approved without escalation'),
    Field('budgetAuthority', String,
        'Budget Authority — spending limits'),
    Field('hiringAuthority', String,
        'Hiring Authority — ability to hire/terminate'),
    Field('policyAuthority', String,
        'Policy Authority — ability to set/change policies'),
    Field('contractAuthority', String,
        'Contract Authority — signing limits for agreements'),
    Field('exceptionAuthority', String,
        'Exception Authority — ability to grant exceptions'),
    Field('escalationRequired', String,
        'Escalation Required — when must escalate'),
  ])
  String? content;
}

/// New role qualifications and competencies.
class NewRoleQualifications {
  @Form([
    Field('education', String,
        'Education — minimum education requirement'),
    Field('preferredEducation', String,
        'Preferred Education — ideal education'),
    Field('experience', String,
        'Experience — years and type of experience required'),
    Field('preferredExperience', String,
        'Preferred Experience — ideal experience'),
    Field('certifications', String,
        'Certifications — required certifications'),
    Field('licensure', String,
        'Licensure — professional licenses needed'),
    Field('languageRequirements', String,
        'Language Requirements — languages needed'),
    Field('travelRequirements', String,
        'Travel Requirements — percentage, destinations'),
    Field('physicalRequirements', String,
        'Physical Requirements — if applicable'),
    Field('backgroundCheck', String,
        'Background Check — type required'),
    Field('securityClearance', String,
        'Security Clearance — if required'),
  ])
  String? content;

  /// Contains 0+× required competency.
  @SectionIdPattern('PD00-ORG-JOB-NEW-xx-CMP-xx')
  List<RoleCompetencyEntry> requiredCompetencies = [];
}

/// Role competency entry [PD00-ORG-JOB-NEW-nn-CMP-nn] (form).
class RoleCompetencyEntry {
  @Form([
    Field('competencyId', String, 'Competency ID'),
    Field('competencyName', String, 'Competency Name', required: true),
    Field('competencyType', String,
        'Competency Type — Core, Technical, Leadership'),
    Field('requiredLevel', String,
        'Required Level — minimum proficiency'),
    Field('preferredLevel', String, 'Preferred Level — ideal proficiency'),
    Field('assessmentMethod', String,
        'Assessment Method — how evaluated during hiring'),
    Field('developmentPriority', String,
        'Development Priority — if gap exists'),
  ])
  String? content;
}

/// New role system access requirements.
class NewRoleSystemAccess {
  @Form([
    Field('primarySystems', String,
        'Primary Systems — main applications used daily'),
    Field('secondarySystems', String,
        'Secondary Systems — occasionally used applications'),
    Field('dataAccess', String,
        'Data Access — data domains accessible'),
    Field('securityRole', String,
        'Security Role — role in access control system'),
    Field('privilegedAccess', String,
        'Privileged Access — admin/elevated rights needed'),
    Field('mobileAccess', String,
        'Mobile Access — mobile app/device requirements'),
    Field('remoteAccessTools', String,
        'Remote Access Tools — VPN, virtual desktop'),
    Field('communicationTools', String,
        'Communication Tools — email, chat, video'),
    Field('reportingTools', String,
        'Reporting Tools — BI, dashboards, analytics'),
    Field('accessProvisioning', String,
        'Access Provisioning — how access is granted'),
  ])
  String? content;
}

/// New role performance metrics.
class NewRolePerformance {
  @Form([
    Field('performanceObjectives', String,
        'Performance Objectives — key goals'),
    Field('kpis', String, 'KPIs — quantitative metrics'),
    Field('qualitativeMetrics', String,
        'Qualitative Metrics — behavioral/quality measures'),
    Field('reviewFrequency', String,
        'Review Frequency — performance review cadence'),
    Field('probationPeriod', String,
        'Probation Period — initial review period'),
    Field('successMilestones', String,
        'Success Milestones — 30/60/90 day goals'),
    Field('careerPath', String,
        'Career Path — typical progression from this role'),
    Field('promotionCriteria', String,
        'Promotion Criteria — requirements for advancement'),
  ])
  String? content;
}

/// New role onboarding plan.
class NewRoleOnboarding {
  @Form([
    Field('onboardingDuration', String,
        'Onboarding Duration — weeks to full productivity'),
    Field('orientationTopics', String,
        'Orientation Topics — company/department intro'),
    Field('requiredTraining', String,
        'Required Training — mandatory courses'),
    Field('systemTraining', String,
        'System Training — application-specific training'),
    Field('processTraining', String,
        'Process Training — business process training'),
    Field('mentorAssignment', String,
        'Mentor Assignment — buddy/mentor program'),
    Field('shadowingPlan', String,
        'Shadowing Plan — observation opportunities'),
    Field('checkpointMeetings', String,
        'Checkpoint Meetings — scheduled check-ins'),
    Field('rampUpExpectations', String,
        'Ramp-Up Expectations — productivity expectations over time'),
  ])
  String? content;
}

/// A changed role entry [PD00-ORG-JOB-CHA-nn] (form).
///
/// Documents modifications to existing roles with impact assessment,
/// transition planning, and incumbent management.
class ChangedRoleEntry {
  /// Changed role identification.
  ChangedRoleIdentification identification = ChangedRoleIdentification();

  /// Responsibility changes.
  ChangedRoleResponsibilities responsibilities = ChangedRoleResponsibilities();

  /// Competency changes.
  ChangedRoleCompetencies competencies = ChangedRoleCompetencies();

  /// System access changes.
  ChangedRoleSystemAccess systemAccess = ChangedRoleSystemAccess();

  /// Impact on incumbents.
  ChangedRoleIncumbentImpact incumbentImpact = ChangedRoleIncumbentImpact();

  /// Transition planning.
  ChangedRoleTransition transition = ChangedRoleTransition();
}

/// Changed role identification.
class ChangedRoleIdentification {
  @Form([
    Field('roleId', String, 'Role ID (e.g., CR-001)', required: true),
    Field('roleTitle', String, 'Current Role Title', required: true),
    Field('newRoleTitle', String, 'New Role Title — if title changes'),
    Field('currentDepartment', String, 'Current Department'),
    Field('newDepartment', String, 'New Department — if moving'),
    Field('currentJobLevel', String, 'Current Job Level'),
    Field('newJobLevel', String, 'New Job Level — if changing'),
    Field('changeRationale', String,
        'Change Rationale — why this role is changing'),
    Field('changeType', String,
        'Change Type — expanded, reduced, restructured, upgraded, downgraded'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('changeStatus', String,
        'Change Status — proposed, approved, communicated, implemented'),
    Field('incumbentCount', int, 'Incumbent Count — people in this role'),
  ])
  String? content;
}

/// Changed role responsibilities.
class ChangedRoleResponsibilities {
  /// Responsibilities being added.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-ADD-xx')
  List<ResponsibilityChangeEntry> addedResponsibilities = [];

  /// Responsibilities being removed.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-REM-xx')
  List<ResponsibilityChangeEntry> removedResponsibilities = [];

  /// Responsibilities being modified.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-MOD-xx')
  List<ResponsibilityChangeEntry> modifiedResponsibilities = [];

  /// Net impact summary.
  ResponsibilityImpactSummary impactSummary = ResponsibilityImpactSummary();
}

/// Responsibility change entry [PD00-ORG-JOB-CHA-nn-xxx-nn] (form).
class ResponsibilityChangeEntry {
  @Form([
    Field('responsibility', String, 'Responsibility', required: true),
    Field('changeType', String, 'Change Type — add, remove, modify'),
    Field('currentState', String, 'Current State — how done today'),
    Field('futureState', String, 'Future State — how done after change'),
    Field('reason', String, 'Reason — why this change'),
    Field('impactLevel', String, 'Impact Level — high, medium, low'),
    Field('trainingNeeded', String, 'Training Needed'),
    Field('toolsAffected', String, 'Tools Affected — systems involved'),
    Field('transitionApproach', String,
        'Transition Approach — how responsibility is handed over'),
  ])
  String? content;
}

/// Summary of responsibility impact.
class ResponsibilityImpactSummary {
  @Form([
    Field('netTimeImpact', String,
        'Net Time Impact — increase/decrease in workload'),
    Field('complexityChange', String,
        'Complexity Change — simpler, same, more complex'),
    Field('scopeChange', String,
        'Scope Change — narrower, same, broader'),
    Field('authorityChange', String,
        'Authority Change — less, same, more'),
    Field('classificationImpact', String,
        'Classification Impact — should job grade change'),
    Field('compensationImpact', String,
        'Compensation Impact — salary implications'),
  ])
  String? content;
}

/// Changed role competency requirements.
class ChangedRoleCompetencies {
  /// New competencies required.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-CMP-ADD-xx')
  List<RoleCompetencyEntry> newCompetencies = [];

  /// Competencies no longer required.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-CMP-REM-xx')
  List<RoleCompetencyEntry> removedCompetencies = [];

  /// Competencies with changed proficiency levels.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-CMP-CHG-xx')
  List<CompetencyLevelChangeEntry> changedLevels = [];

  /// Overall competency gap assessment.
  CompetencyGapAssessment gapAssessment = CompetencyGapAssessment();
}

/// Competency level change entry.
class CompetencyLevelChangeEntry {
  @Form([
    Field('competencyName', String, 'Competency Name', required: true),
    Field('currentLevel', String, 'Current Required Level'),
    Field('newLevel', String, 'New Required Level'),
    Field('reason', String, 'Reason — why level is changing'),
    Field('developmentPath', String,
        'Development Path — how to close gap'),
    Field('timeframe', String, 'Timeframe — when level needed'),
  ])
  String? content;
}

/// Competency gap assessment.
class CompetencyGapAssessment {
  @Form([
    Field('overallGapSeverity', String,
        'Overall Gap Severity — critical, significant, moderate, minor'),
    Field('criticalGaps', String,
        'Critical Gaps — competencies where gap is most severe'),
    Field('developmentStrategy', String,
        'Development Strategy — training, coaching, hiring'),
    Field('developmentTimeline', String,
        'Development Timeline — when gaps will be closed'),
    Field('interimMeasures', String,
        'Interim Measures — how to manage until gaps closed'),
  ])
  String? content;
}

/// Changed role system access.
class ChangedRoleSystemAccess {
  @Form([
    Field('newSystemAccess', String,
        'New System Access — additional systems needed'),
    Field('removedSystemAccess', String,
        'Removed System Access — systems no longer needed'),
    Field('changedPermissions', String,
        'Changed Permissions — modified access levels'),
    Field('securityRoleChanges', String,
        'Security Role Changes — updated security roles'),
    Field('dataAccessChanges', String,
        'Data Access Changes — modified data domains'),
    Field('trainingOnNewSystems', String,
        'Training on New Systems — training required'),
    Field('accessTransitionDate', String,
        'Access Transition Date — when access changes'),
  ])
  String? content;
}

/// Impact on current role incumbents.
class ChangedRoleIncumbentImpact {
  @Form([
    Field('incumbentCount', int, 'Incumbent Count — people affected'),
    Field('impactAssessment', String,
        'Impact Assessment — how incumbents are affected'),
    Field('competencyGapAnalysis', String,
        'Competency Gap Analysis — where incumbents have gaps'),
    Field('readinessAssessment', String,
        'Readiness Assessment — incumbent preparedness'),
    Field('retentionRisk', String,
        'Retention Risk — flight risk due to changes'),
    Field('individualTransitionPlans', String,
        'Individual Transition Plans — personalized plans'),
    Field('supportProvided', String,
        'Support Provided — coaching, mentoring, training'),
    Field('alternativePaths', String,
        'Alternative Paths — if incumbent cannot adapt'),
    Field('communicationApproach', String,
        'Communication Approach — how changes are communicated'),
    Field('changeAcceptanceStatus', String,
        'Change Acceptance Status — incumbent reactions'),
  ])
  String? content;
}

/// Changed role transition planning.
class ChangedRoleTransition {
  @Form([
    Field('transitionStart', String, 'Transition Start Date'),
    Field('transitionEnd', String, 'Transition End Date'),
    Field('parallelPeriod', String,
        'Parallel Period — overlap of old/new ways'),
    Field('trainingSchedule', String,
        'Training Schedule — when training occurs'),
    Field('trainingDuration', String,
        'Training Duration — hours/days of training'),
    Field('trainingFormat', String,
        'Training Format — classroom, online, OJT'),
    Field('practiceOpportunities', String,
        'Practice Opportunities — sandbox, pilot'),
    Field('supportDuringTransition', String,
        'Support During Transition — help available'),
    Field('performanceExpectations', String,
        'Performance Expectations — adjusted goals during transition'),
    Field('transitionMilestones', String,
        'Transition Milestones — key checkpoints'),
    Field('successCriteria', String,
        'Success Criteria — how successful transition is measured'),
  ])
  String? content;
}

/// A removed role entry [PD00-ORG-JOB-REM-nn] (form).
///
/// Documents roles being eliminated with transition planning for incumbents.
class RemovedRoleEntry {
  @Form([
    Field('roleId', String, 'Role ID', required: true),
    Field('roleTitle', String, 'Role Title', required: true),
    Field('department', String, 'Department'),
    Field('removalReason', String,
        'Removal Reason — automation, restructuring, outsourcing, redundancy'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('incumbentCount', int, 'Incumbent Count — people affected'),
    Field('incumbentDisposition', String,
        'Incumbent Disposition — redeployment, separation, retraining'),
    Field('reassignmentOptions', String,
        'Reassignment Options — alternative roles available'),
    Field('transitionSupport', String,
        'Transition Support — outplacement, retraining'),
    Field('severanceConsiderations', String,
        'Severance Considerations — if applicable'),
    Field('legalConsiderations', String,
        'Legal Considerations — employment law, union agreements'),
    Field('communicationPlan', String,
        'Communication Plan — how removal is communicated'),
    Field('knowledgeTransfer', String,
        'Knowledge Transfer — preserving institutional knowledge'),
    Field('workReassignment', String,
        'Work Reassignment — where responsibilities go'),
  ])
  String? content;
}

/// A responsibility entry (form) [PD00-ORG-JOB-nn-RSP-nn].
class RoleResponsibilityEntry {
  @Form([
    Field('responsibility', String, 'Responsibility'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// A skill entry (form) [PD00-ORG-JOB-nn-SKL-nn].
class SkillEntry {
  @Form([
    Field('skillName', String, 'Skill Name'),
    Field('proficiencyLevel', String, 'Proficiency Level'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 5.3 Workplace Descriptions
// ---------------------------------------------------------------------------

/// A workplace description entry [PD00-ORG-WOR-nn] (form, per user category).
@Comment('per user category')
class WorkplaceDescriptionEntry {
  @Form([
    Field('userCategory', String, 'User Category'),
  ])
  String? content;

  /// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
  EquipmentRequirements equipmentRequirements = EquipmentRequirements();

  /// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
  TrainingRequirements trainingRequirements = TrainingRequirements();
}

/// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
@SectionId('PD00-ORG-WOR-EQU')
class EquipmentRequirements {
  @Unused()
  String? content;

  /// Contains 0+× EquipmentRequirement.
  @SectionIdPattern('PD00-ORG-WOR-xx-EQU-xx')
  List<EquipmentRequirementEntry> items = [];
}

/// An equipment requirement entry (form) [PD00-ORG-WOR-nn-EQU-nn].
class EquipmentRequirementEntry {
  @Form([
    Field('equipmentType', String, 'Equipment Type'),
    Field('specification', String, 'Specification'),
    Field('quantity', String, 'Quantity'),
    Field('purpose', String, 'Purpose'),
  ])
  String? content;
}

/// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
@SectionId('PD00-ORG-WOR-TRA')
class TrainingRequirements {
  @Unused()
  String? content;

  /// Contains 0+× TrainingRequirement.
  @SectionIdPattern('PD00-ORG-WOR-xx-TRA-xx')
  List<TrainingRequirementEntry> items = [];
}

/// A training requirement entry (form) [PD00-ORG-WOR-nn-TRA-nn].
class TrainingRequirementEntry {
  @Form([
    Field('trainingTopic', String, 'Training Topic'),
    Field('targetAudience', String, 'Target Audience'),
    Field('format', String, 'Format'),
    Field('duration', String, 'Duration'),
    Field('schedule', String, 'Schedule'),
  ])
  String? content;
}
