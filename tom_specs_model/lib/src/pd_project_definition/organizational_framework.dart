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
@SectionId('PD00-ORG-JOB')
class JobDescriptionsAndStaffing {
  @Unused()
  String? content;

  /// 5.2.1. New Roles [PD00-ORG-JOB-NEW] — contains 0+× New Role.
  @SectionIdPattern('PD00-ORG-JOB-NEW-xx')
  List<NewRoleEntry> newRoles = [];

  /// 5.2.2. Changed Roles [PD00-ORG-JOB-CHA] — contains 0+× Changed Role.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx')
  List<ChangedRoleEntry> changedRoles = [];

  /// 5.2.3. Staffing Plan [PD00-ORG-JOB-STA].
  StaffingPlan staffingPlan = StaffingPlan();
}

/// 5.2.3. Staffing Plan [PD00-ORG-JOB-STA].
@SectionId('PD00-ORG-JOB-STA')
class StaffingPlan {
  @Unused()
  String? content;

  /// Budget.
  TextSection budget = TextSection();

  /// Contains 0+× Staffing.
  @SectionIdPattern('PD00-ORG-JOB-STA-xx')
  List<StaffingEntry> items = [];
}

/// A staffing entry (form) [PD00-ORG-JOB-STA-nn].
class StaffingEntry {
  @Form([
    Field('roleTitle', String, 'Role Title', required: true),
    Field('department', String, 'Department'),
    Field('fteCount', String, 'Fte Count'),
    Field('recruitmentStatus', String, 'Recruitment Status'),
    Field('targetStartDate', String, 'Target Start Date'),
  ])
  String? content;
}

/// A new role entry [PD00-ORG-JOB-NEW-nn] (form).
class NewRoleEntry {
  @Form([
    Field('roleTitle', String, 'Role Title', required: true),
    Field('department', String, 'Department'),
    Field('reportingLine', String, 'Reporting Line'),
    Field('fteAllocation', String, 'Fte Allocation'),
    Field('startDate', String, 'Start Date'),
  ])
  String? content;

  /// Contains 0+× RoleResponsibility.
  @SectionIdPattern('PD00-ORG-JOB-NEW-xx-RSP-xx')
  List<RoleResponsibilityEntry> responsibilities = [];

  /// Contains 0+× Skill.
  @SectionIdPattern('PD00-ORG-JOB-NEW-xx-SKL-xx')
  List<SkillEntry> requiredSkills = [];
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

/// A changed role entry [PD00-ORG-JOB-CHA-nn] (form).
class ChangedRoleEntry {
  @Form([
    Field('roleTitle', String, 'Role Title', required: true),
    Field('currentDepartment', String, 'Current Department'),
    Field('changedReportingLine', String, 'Changed Reporting Line'),
    Field('trainingRequired', String, 'Training Required'),
  ])
  String? content;

  /// Contains 0+× RoleResponsibility.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-RSP-xx')
  List<RoleResponsibilityEntry> addedResponsibilities = [];

  /// Contains 0+× RoleResponsibility.
  List<RoleResponsibilityEntry> removedResponsibilities = [];

  /// Contains 0+× Skill.
  @SectionIdPattern('PD00-ORG-JOB-CHA-xx-SKL-xx')
  List<SkillEntry> newSkillRequirements = [];
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
