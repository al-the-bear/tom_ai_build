/// Section 5: Organizational Framework.
///
/// Organizational changes and structures required for the new system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 5. Organizational Framework.
///
/// Organizational changes and structures required for the new system.
/// Covers organization structure changes, new and changed roles, staffing
/// plans, competency frameworks, and workplace requirements. Follows
/// organizational design best practices (McKinsey 7-S, Galbraith Star Model)
/// and HR management standards (SHRM, CIPD).
@SectionId('ORGF')
class OrganizationalFramework {
  /// Overview of organizational changes required for the new system.
  @ContentHelp('Provide executive summary of organizational impact: '
      'scope of restructuring, number of affected roles, key organizational '
      'design principles, change management approach, and timeline overview.')
  TextSection overview = TextSection();

  /// 5.1. New Organization Structure.
  NewOrganizationStructure organizationStructure = NewOrganizationStructure();

  /// 5.2. Job Descriptions and Staffing Plans.
  @SectionId('JDAS-JOBD-LST')
  @SectionIdPattern('JDAS-JOBD-xxx')
  List<JobDescriptionsAndStaffing> jobDescriptions = [];

  /// 5.3. Workplace Descriptions — contains 1+× per user category.
  @SectionId('WPDE-WORK-LST')
  @SectionIdPattern('WPDE-WORK-xxx')
  @Min(1)
  @Comment('per user category')
  List<WorkplaceDescriptionEntry> workplaceDescriptions = [];
}

// ---------------------------------------------------------------------------
// 5.1 New Organization Structure
// ---------------------------------------------------------------------------

/// 5.1. New Organization Structure.
///
/// Organizational changes required by the new system including new teams,
/// restructured departments, changed responsibilities, and new communication
/// channels. Follows organizational design principles (span of control,
/// decision rights, coordination mechanisms) and change management patterns.
@SectionId('NORGS')
class NewOrganizationStructure {
  /// Overview of the target organization structure.
  @ContentHelp('Describe the vision for the new organization structure: '
      'design principles, key structural changes, governance model, '
      'decision-making framework, and expected benefits.')
  TextSection overview = TextSection();

  /// 5.1.1. Changes from Current Structure.
  ChangesFromCurrentStructure changesFromCurrentStructure =
      ChangesFromCurrentStructure();

  /// 5.1.2. Organizational Transition Timeline.
  OrganizationalTransitionTimeline transitionTimeline =
      OrganizationalTransitionTimeline();
}

/// 5.1.1. Changes from Current Structure.
///
/// Explicitly documents what changes from the current organization structure.
/// Identifies affected departments, changed reporting lines, and new roles
/// that need to be created. Provides traceability from current to future state.
@SectionId('OCCHG')
class ChangesFromCurrentStructure {
  // -------------------------------------------------------------------------
  // Change Overview
  // -------------------------------------------------------------------------
  @Form([
    Field('changeScope', String, 'Change Scope',
        hint: 'Departments and functions affected by restructuring'),
    Field('changeDriver', String, 'Change Driver',
        hint: 'System implementation, process optimization, strategy shift'),
    Field('impactSummary', String, 'Impact Summary',
        hint: 'Total affected headcount, key structural shifts'),
    Field('designPrinciples', String, 'Design Principles',
        hint: 'Guiding principles for organizational design changes'),
    Field('governanceChanges', String, 'Governance Changes',
        hint: 'Changes to decision-making authority and oversight'),
    Field('reportingLineChanges', String, 'Reporting Line Changes',
        hint: 'Summary of reporting relationship modifications'),
    Field('communicationChannelChanges', String, 'Communication Channel Changes',
        hint: 'New or modified formal communication flows'),
    Field('collaborationModelChanges', String, 'Collaboration Model Changes',
        hint: 'How teams will work together differently'),
  ])
  String? overviewContent;

  /// Detailed description of structural changes.
  @ContentHelp('Provide narrative description of the organizational '
      'transformation: what the current structure looks like, what the '
      'target structure will be, and how the transition will be managed.')
  TextSection changeNarrative = TextSection();

  /// Organization chart comparison (current vs future).
  @ContentHelp('Visual representation comparing current and target '
      'organization structures - attach or embed org chart diagrams.')
  DiagramSection orgChartComparison = DiagramSection();

  /// Contains 0+× OrganizationalChange.
  @SectionId('ORGCE-ITEM-LST')
  @SectionIdPattern('ORGCE-ITEM-xxx')
  List<OrganizationalChangeEntry> items = [];
}

/// An organizational change entry (form).
///
/// Documents a specific structural change including current state, target
/// state, rationale, impact assessment, and transition requirements.
@SectionId('ORGCE')
class OrganizationalChangeEntry {
  @Form([
    Field('changeId', String, 'Change ID (e.g., OC-001)', required: true,
        hint: 'Unique identifier for this structural change'),
    Field('changeName', String, 'Change Name', required: true,
        hint: 'Short descriptive name for the change'),
    Field('changeType', String, 'Change Type',
        hint: 'Restructure, Merge, Split, Create, Eliminate, Relocate'),
  ])
  String? content;

  /// Change identification details.
  OrgChangeIdentification identification = OrgChangeIdentification();

  /// Scope of the change.
  OrgChangeScope scope = OrgChangeScope();

  /// Rationale for the change.
  OrgChangeRationale rationale = OrgChangeRationale();

  /// Impact assessment.
  OrgChangeImpact impact = OrgChangeImpact();

  /// Transition planning.
  OrgChangeTransition transition = OrgChangeTransition();

  /// Risks and mitigations.
  @SectionId('OCRSK-RISK-LST')
  @SectionIdPattern('OCRSK-RISK-xxx')
  List<OrgChangeRisks> risks = [];

  /// Status tracking.
  OrgChangeStatus status = OrgChangeStatus();
}

/// Identification details for organizational change.
@SectionId('OCIDN')
class OrgChangeIdentification {
  @Form([
    Field('changeCategory', String, 'Change Category',
        hint: 'Reporting Lines, Team Structure, Department, Division'),
    Field('priority', String, 'Priority',
        hint: 'Critical, High, Medium, Low'),
  ])
  String? content;
}

/// Scope for organizational change.
@SectionId('OCSCP')
class OrgChangeScope {
  @Form([
    Field('affectedArea', String, 'Affected Area',
        hint: 'Department, team, or function being changed'),
    Field('currentState', String, 'Current State',
        hint: 'How the area is currently organized'),
    Field('targetState', String, 'Target State',
        hint: 'How the area will be organized after change'),
    Field('currentHeadcount', int, 'Current Headcount',
        hint: 'Number of people in current structure'),
    Field('targetHeadcount', int, 'Target Headcount',
        hint: 'Number of people in target structure'),
    Field('headcountDelta', int, 'Headcount Delta',
        hint: 'Net change in headcount'),
  ])
  String? content;
}

/// Rationale for organizational change.
@SectionId('OCRAT')
class OrgChangeRationale {
  @Form([
    Field('rationale', String, 'Rationale',
        hint: 'Business justification for this change'),
    Field('expectedBenefits', String, 'Expected Benefits',
        hint: 'Anticipated improvements from this change'),
    Field('systemAlignment', String, 'System Alignment',
        hint: 'How this change supports the new system'),
    Field('processAlignment', String, 'Process Alignment',
        hint: 'How this change supports new business processes'),
  ])
  String? content;
}

/// Impact assessment for organizational change.
@SectionId('OCIMP')
class OrgChangeImpact {
  @Form([
    Field('impactLevel', String, 'Impact Level',
        hint: 'High, Medium, Low — severity of disruption'),
    Field('affectedRoles', String, 'Affected Roles',
        hint: 'Job titles impacted by this change'),
    Field('affectedPeople', String, 'Affected People',
        hint: 'Key individuals or groups affected'),
    Field('reportingLineImpact', String, 'Reporting Line Impact',
        hint: 'Changes to who reports to whom'),
    Field('decisionRightsImpact', String, 'Decision Rights Impact',
        hint: 'Changes to decision-making authority'),
    Field('communicationImpact', String, 'Communication Impact',
        hint: 'Changes to information flow'),
    Field('collaborationImpact', String, 'Collaboration Impact',
        hint: 'Changes to how people work together'),
  ])
  String? content;
}

/// Transition for organizational change.
@SectionId('OCTRS')
class OrgChangeTransition {
  @Form([
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When this change takes effect'),
    Field('transitionPeriod', String, 'Transition Period',
        hint: 'Duration of transition'),
    Field('transitionOwner', String, 'Transition Owner',
        hint: 'Person accountable for implementing'),
    Field('communicationRequired', String, 'Communication Required',
        hint: 'Announcements and messaging needed'),
    Field('trainingRequired', String, 'Training Required',
        hint: 'Training or enablement needed'),
    Field('hrActionsRequired', String, 'HR Actions Required',
        hint: 'Contract changes, promotions, transfers'),
    Field('itActionsRequired', String, 'IT Actions Required',
        hint: 'System access, email groups, org hierarchy'),
  ])
  String? content;
}

/// Risks for organizational change.
@SectionId('OCRSK')
class OrgChangeRisks {
  @Form([
    Field('risks', String, 'Risks',
        hint: 'Potential risks from this change'),
    Field('mitigations', String, 'Mitigations',
        hint: 'Actions to reduce risks'),
    Field('dependencies', String, 'Dependencies',
        hint: 'Other changes this depends on or enables'),
  ])
  String? content;
}

/// Status for organizational change.
@SectionId('OCSTA')
class OrgChangeStatus {
  @Form([
    Field('status', String, 'Status',
        hint: 'Proposed, Approved, In Progress, Completed, Cancelled'),
    Field('approvalRequired', String, 'Approval Required',
        hint: 'Who must approve this change'),
    Field('approvalStatus', String, 'Approval Status',
        hint: 'Pending, Approved, Rejected'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or considerations'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 5.1.2 Organizational Transition Timeline
// ---------------------------------------------------------------------------

/// 5.1.2. Organizational Transition Timeline.
///
/// Describes when organizational changes take effect, how the transition is
/// managed, and what training or communication is needed. Follows change
/// management best practices (PROSCI ADKAR, Kotter's 8-step model).
@SectionId('OTTML')
class OrganizationalTransitionTimeline {
  /// Overview of the transition approach and guiding principles.
  TransitionOverview overview = TransitionOverview();

  /// Transition phases with milestones and durations.
  @SectionId('TRPHE-PHAS-LST')
  @SectionIdPattern('TRPHE-PHAS-xxx')
  List<TransitionPhaseEntry> phases = [];

  /// Key transition milestones and decision gates.
  @SectionId('TRMIL-MILE-LST')
  @SectionIdPattern('TRMIL-MILE-xxx')
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
  @SectionId('TRRS-TRAN-LST')
  @SectionIdPattern('TRRS-TRAN-xxx')
  List<TransitionRiskEntry> transitionRisks = [];
}

/// Overview of the organizational transition approach.
@SectionId('TROVW')
class TransitionOverview {
  @Form([
    Field('transitionApproach', String,
        'Transition Approach — phased, big-bang, parallel run, pilot'),
    Field('changeManagementMethodology', String,
        'Change Management Methodology — PROSCI ADKAR, Kotter, Lewin, custom'),
    Field('transitionStartDate', String, 'Transition Start Date'),
    Field('targetCompletionDate', String, 'Target Completion Date'),
  ])
  String? content;

  /// Timeline and cutover planning.
  TransitionOverviewTimeline timeline = TransitionOverviewTimeline();

  /// Governance and change ownership.
  TransitionOverviewGovernance governance = TransitionOverviewGovernance();
}

/// Timeline and cutover planning.
@SectionId('TROML')
class TransitionOverviewTimeline {
  @Form([
    Field('transitionDuration', String,
        'Overall Transition Duration — weeks/months'),
    Field('parallelOperationPeriod', String,
        'Parallel Operation Period — duration of overlap with old processes'),
    Field('cutoverStrategy', String,
        'Cutover Strategy — planning for go-live moment'),
    Field('rollbackPlan', String,
        'Rollback Plan — fallback if transition fails'),
  ])
  String? content;
}

/// Governance and change ownership.
@SectionId('TROGV')
class TransitionOverviewGovernance {
  @Form([
    Field('transitionGovernance', String,
        'Transition Governance — oversight structure and decision authority'),
    Field('transitionOwner', String,
        'Transition Owner — accountable person/role'),
    Field('changeChampions', String,
        'Change Champions — advocates in each affected area'),
  ])
  String? content;
}

/// A transition phase entry (form).
///
/// Defines a distinct phase in the organizational transition sequence.
@SectionId('TRPHE')
class TransitionPhaseEntry {
  /// Phase identification and timeline.
  TransitionPhaseIdentification identification =
      TransitionPhaseIdentification();

  /// Activities and deliverables for this phase.
  @SectionId('TPACT-ACTI-LST')
  @SectionIdPattern('TPACT-ACTI-xxx')
  List<TransitionPhaseActivities> activities = [];

  /// Stakeholder engagement for this phase.
  @SectionId('TPSTK-STAK-LST')
  @SectionIdPattern('TPSTK-STAK-xxx')
  List<TransitionPhaseStakeholders> stakeholders = [];

  /// Exit criteria and phase completion conditions.
  TransitionPhaseExitCriteria exitCriteria = TransitionPhaseExitCriteria();
}

/// Phase identification and timeline.
@SectionId('TPIDN')
class TransitionPhaseIdentification {
  @Form([
    Field('phaseId', String, 'Phase ID (e.g., PH-01)', required: true),
    Field('phaseName', String, 'Phase Name', required: true),
    Field('phaseType', String,
        'Phase Type — Preparation, Pilot, Rollout, Stabilization, Closure'),
    Field('phaseOwner', String, 'Phase Owner'),
  ])
  String? content;

    /// Timeline and sequencing details.
    TransitionPhaseIdentificationTimeline timeline =
            TransitionPhaseIdentificationTimeline();

    /// Scope of organizational impact.
    TransitionPhaseIdentificationScope scope =
            TransitionPhaseIdentificationScope();
}

/// Timeline and sequencing details.
@SectionId('TPIML')
class TransitionPhaseIdentificationTimeline {
    @Form([
        Field('startDate', String, 'Start Date'),
        Field('endDate', String, 'End Date'),
        Field('duration', String, 'Duration — weeks'),
        Field('precedingPhase', String, 'Preceding Phase — phase ID'),
        Field('dependsOnMilestone', String, 'Depends on Milestone — milestone ID'),
    ])
    String? content;
}

/// Scope of organizational impact.
@SectionId('TPISC')
class TransitionPhaseIdentificationScope {
    @Form([
        Field('affectedLocations', String,
                'Affected Locations — sites/regions in scope'),
        Field('affectedDepartments', String,
                'Affected Departments — organizational units'),
        Field('affectedUserCount', int, 'Affected User Count'),
    ])
    String? content;
}

/// Activities and deliverables for a transition phase.
@SectionId('TPACT')
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
@SectionId('TPSTK')
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
@SectionId('TPEXT')
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

/// A transition milestone entry (form).
@SectionId('TRMIL')
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
  ])
  String? content;

    /// Deliverables and decisioning.
    TransitionMilestoneEntryGovernance governance =
            TransitionMilestoneEntryGovernance();

    /// Dependencies and criticality.
    TransitionMilestoneEntryDependencies dependencies =
            TransitionMilestoneEntryDependencies();

    /// Recognition activities.
    TransitionMilestoneEntryRecognition recognition =
            TransitionMilestoneEntryRecognition();
}

/// Deliverables and decisioning.
@SectionId('TMLGV')
class TransitionMilestoneEntryGovernance {
    @Form([
        Field('deliverables', String, 'Deliverables — required for milestone'),
        Field('decisionRequired', String,
                'Decision Required — Go/No-Go decision at this point'),
        Field('decisionOwner', String, 'Decision Owner'),
    ])
    String? content;
}

/// Dependencies and criticality.
@SectionId('TMED')
class TransitionMilestoneEntryDependencies {
    @Form([
        Field('dependsOnPhases', String,
                'Depends on Phases — phases that must complete'),
        Field('dependsOnMilestones', String,
                'Depends on Milestones — prior milestones required'),
        Field('criticality', String, 'Criticality — High, Medium, Low'),
    ])
    String? content;
}

/// Recognition activities.
@SectionId('TMER')
class TransitionMilestoneEntryRecognition {
    @Form([
        Field('celebrationActivities', String,
                'Celebration Activities — recognition for achieving milestone'),
    ])
    String? content;
}

/// Change readiness assessment approach.
@SectionId('CHREAS')
class ChangeReadinessAssessment {
  /// Overview of readiness assessment approach.
  ChangeReadinessOverview overview = ChangeReadinessOverview();

  /// Readiness criteria per stakeholder group.
  @SectionId('RDRCE-READ-LST')
  @SectionIdPattern('RDRCE-READ-xxx')
  List<ReadinessCriteriaEntry> readinessCriteria = [];
}

/// Overview of change readiness assessment.
@SectionId('CHREOV')
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

/// Readiness criteria entry (form).
@SectionId('RDRCE')
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
@SectionId('TRCOPL')
class TransitionCommunicationPlan {
  /// Communication strategy overview.
  TransitionCommunicationStrategy strategy = TransitionCommunicationStrategy();

  /// Specific communication events/activities.
  @SectionId('COEV-COMM-LST')
  @SectionIdPattern('COEV-COMM-xxx')
  List<CommunicationEventEntry> communicationEvents = [];

  /// Communication channels and their use.
  @SectionId('TRCOCH-CHAN-LST')
  @SectionIdPattern('TRCOCH-CHAN-xxx')
  List<TransitionCommunicationChannels> channels = [];
}

/// Communication strategy overview.
@SectionId('TRCOST')
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

/// Communication event entry (form).
@SectionId('COEV')
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
  ])
  String? content;

    /// Delivery ownership.
    CommunicationEventEntryDelivery delivery = CommunicationEventEntryDelivery();

    /// Follow-up and measurement.
    CommunicationEventEntryOutcome outcome = CommunicationEventEntryOutcome();
}

/// Delivery ownership.
@SectionId('CEED')
class CommunicationEventEntryDelivery {
    @Form([
        Field('channel', String, 'Channel — delivery method'),
        Field('owner', String, 'Owner — who prepares/delivers'),
        Field('approver', String, 'Approver — who approves content'),
        Field('materialsRequired', String, 'Materials Required — slides, scripts, etc.'),
    ])
    String? content;
}

/// Follow-up and measurement.
@SectionId('CEEO')
class CommunicationEventEntryOutcome {
    @Form([
        Field('followUpActions', String, 'Follow-Up Actions — after event'),
        Field('successMeasure', String, 'Success Measure — how effectiveness is measured'),
        Field('status', String, 'Status — Planned, In Preparation, Delivered, Cancelled'),
    ])
    String? content;
}

/// Communication channels definition.
@SectionId('TRCOCH')
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
@SectionId('TRSUST')
class TransitionSupportStructure {
  /// Support organization overview.
  TransitionSupportOverview overview = TransitionSupportOverview();

  /// Support resources available.
  @SectionId('TRSPRE-SUPP-LST')
  @SectionIdPattern('TRSPRE-SUPP-xxx')
  List<TransitionSupportResourceEntry> supportResources = [];

  /// Escalation paths for support.
  @SectionId('TRESPA-ESCA-LST')
  @SectionIdPattern('TRESPA-ESCA-xxx')
  List<TransitionEscalationPaths> escalationPaths = [];
}

/// Support structure overview.
@SectionId('TRSUOV')
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

/// Support resource entry (form).
@SectionId('TRSPRE')
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
@SectionId('TRESPA')
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
@SectionId('TRSUME')
class TransitionSuccessMetrics {
  /// Metrics overview.
  TransitionMetricsOverview overview = TransitionMetricsOverview();

  /// Specific success metrics.
  @SectionId('TRME-METR-LST')
  @SectionIdPattern('TRME-METR-xxx')
  List<TransitionMetricEntry> metrics = [];
}

/// Metrics overview.
@SectionId('TRMEOV')
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

/// Transition metric entry (form).
@SectionId('TRME')
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
  ])
  String? content;

    /// Measurement operations.
    TransitionMetricEntryOperations operations = TransitionMetricEntryOperations();

    /// Current status.
    TransitionMetricEntryStatus statusSection = TransitionMetricEntryStatus();
}

/// Measurement operations.
@SectionId('TMEO')
class TransitionMetricEntryOperations {
    @Form([
        Field('threshold', String, 'Threshold — minimum acceptable'),
        Field('currentValue', String, 'Current Value'),
        Field('measurementFrequency', String, 'Measurement Frequency'),
        Field('dataSource', String, 'Data Source'),
        Field('owner', String, 'Owner'),
    ])
    String? content;
}

/// Current status.
@SectionId('TMES')
class TransitionMetricEntryStatus {
    @Form([
        Field('status', String, 'Status — On Track, At Risk, Below Target, Achieved'),
        Field('trend', String, 'Trend — Improving, Stable, Declining'),
    ])
    String? content;
}

/// Transition risk entry (form).
@SectionId('TRRS')
class TransitionRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID', required: true),
    Field('riskName', String, 'Risk Name', required: true),
    Field('riskCategory', String,
        'Risk Category — Resistance, Capacity, Timing, Resources, Dependencies'),
    Field('description', String, 'Description'),
  ])
  String? content;

    /// Risk assessment and exposure details.
    TransitionRiskEntryAssessment assessment = TransitionRiskEntryAssessment();

    /// Mitigation ownership and monitoring.
    TransitionRiskEntryResponse response = TransitionRiskEntryResponse();
}

/// Risk assessment and exposure details.
@SectionId('TREA')
class TransitionRiskEntryAssessment {
    @Form([
        Field('probability', String, 'Probability — Low, Medium, High'),
        Field('impact', String, 'Impact — Low, Medium, High'),
        Field('affectedPhases', String, 'Affected Phases'),
        Field('earlyWarningIndicator', String, 'Early Warning Indicator'),
    ])
    String? content;
}

/// Mitigation ownership and monitoring.
@SectionId('TRER')
class TransitionRiskEntryResponse {
    @Form([
        Field('mitigationStrategy', String, 'Mitigation Strategy'),
        Field('contingencyPlan', String, 'Contingency Plan'),
        Field('owner', String, 'Risk Owner'),
        Field('status', String, 'Status — Active, Mitigated, Realized, Closed'),
    ])
    String? content;
}

// ---------------------------------------------------------------------------
// 5.2 Job Descriptions and Staffing Plans
// ---------------------------------------------------------------------------

/// 5.2. Job Descriptions and Staffing Plans.
///
/// Documents new and changed roles resulting from the system introduction,
/// following HR best practices and job analysis methodologies (O*NET, SHRM).
/// Includes competency frameworks, staffing projections, and recruitment planning.
@SectionId('JDAS')
class JobDescriptionsAndStaffing {
  /// Overview of the job architecture and role design approach.
  JobDescriptionsOverview overview = JobDescriptionsOverview();

  /// 5.2.1. New Roles — contains 0+× New Role.
  @SectionId('NWROL-NEWR-LST')
  @SectionIdPattern('NWROL-NEWR-xxx')
  List<NewRoleEntry> newRoles = [];

  /// 5.2.2. Changed Roles — contains 0+× Changed Role.
  @SectionId('CHAROL-CHAN-LST')
  @SectionIdPattern('CHAROL-CHAN-xxx')
  List<ChangedRoleEntry> changedRoles = [];

  /// 5.2.3. Removed Roles — contains 0+× role being eliminated.
  @SectionId('REMROL-REMO-LST')
  @SectionIdPattern('REMROL-REMO-xxx')
  List<RemovedRoleEntry> removedRoles = [];

  /// 5.2.4. Staffing Plan.
  StaffingPlan staffingPlan = StaffingPlan();

  /// 5.2.5. Competency Framework.
  CompetencyFramework competencyFramework = CompetencyFramework();
}

/// Overview of job descriptions and staffing approach.
@SectionId('JODEOV')
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

/// 5.2.4. Staffing Plan.
@SectionId('STPL')
class StaffingPlan {
  /// Staffing plan overview.
  StaffingPlanOverview overview = StaffingPlanOverview();

  /// Budget details.
  StaffingBudget budget = StaffingBudget();

  /// Contains 0+× Staffing entry.
  @SectionId('STFE-ITEM-LST')
  @SectionIdPattern('STFE-ITEM-xxx')
  List<StaffingEntry> items = [];

  /// Recruitment timeline.
  RecruitmentTimeline recruitmentTimeline = RecruitmentTimeline();
}

/// Staffing plan overview.
@SectionId('STPLOV')
class StaffingPlanOverview {
  @Form([
    Field('staffingStrategy', String,
        'Staffing Strategy',
        hint:
            'Hire / Promote / Contract / Outsource mix — overall approach'),
    Field('sourcingChannels', String,
        'Sourcing Channels',
        hint: 'Internal / External / Agencies / Referrals'),
    Field('selectionProcess', String,
        'Selection Process',
        hint:
            'Interviews, assessments, background checks — selection steps'),
    Field('onboardingApproach', String,
        'Onboarding Approach',
        hint: 'New hire integration plan and timeline'),
    Field('retentionStrategy', String,
        'Retention Strategy',
        hint: 'How to keep critical talent — compensation, growth, culture'),
    Field('successionPlanning', String,
        'Succession Planning',
        hint: 'Backup for key positions — deputies, knowledge transfer'),
    Field('contingentWorkforce', String,
        'Contingent Workforce',
        hint: 'Contractors, temps, consultants — scope and governance'),
    Field('geographicDistribution', String,
        'Geographic Distribution',
        hint: 'Locations where hires are needed — remote/on-site split'),
    Field('diversityTargets', String,
        'Diversity & Inclusion Targets',
        hint:
            'DEI hiring goals and constraints on sourcing/selection process'),
    Field('complianceRequirements', String,
        'Labor Compliance Requirements',
        hint:
            'Labor law, visa/work-permit constraints, union agreements, works council obligations'),
  ])
  String? content;
}

/// Staffing budget details.
@SectionId('STBU')
class StaffingBudget {
  @Form([
    Field('totalBudget', String, 'Total Staffing Budget',
        hint: 'Overall budget for all staffing activities'),
    Field('currencyCode', String, 'Currency',
        hint: 'Budget currency code — e.g. EUR, USD, GBP'),
    Field('salaryBudget', String, 'Salary Budget',
        hint: 'Base compensation for all positions'),
    Field('benefitsBudget', String, 'Benefits Budget',
        hint: 'Insurance, retirement, perks'),
  ])
  String? content;

  /// Recruitment and enablement cost categories.
  StaffingBudgetAllocations allocations = StaffingBudgetAllocations();

  /// Budget ownership and approval controls.
  StaffingBudgetGovernance governance = StaffingBudgetGovernance();
}

/// Recruitment and enablement cost categories.
@SectionId('STBUAL')
class StaffingBudgetAllocations {
  @Form([
    Field('recruitmentBudget', String, 'Recruitment Budget',
        hint: 'Agencies, advertising, travel'),
    Field('trainingBudget', String, 'Training Budget',
        hint: 'Onboarding and development costs'),
    Field('relocationBudget', String, 'Relocation Budget',
        hint: 'Relocation assistance if applicable'),
    Field('contingencyBudget', String, 'Contingency Budget',
        hint: 'Buffer for unforeseen staffing needs'),
  ])
  String? content;
}

/// Budget ownership and approval controls.
@SectionId('STBUGO')
class StaffingBudgetGovernance {
  @Form([
    Field('budgetOwner', String, 'Budget Owner',
        hint: 'Person accountable for staffing budget'),
    Field('approvalRequired', String, 'Approval Required',
        hint: 'Who must approve budget and individual positions'),
    Field('budgetTimeline', String, 'Budget Timeline',
        hint: 'Fiscal year alignment and spending schedule'),
  ])
  String? content;
}

/// A staffing entry (form).
///
/// Represents one staffing position including role, competency requirements,
/// sourcing method, budget, timeline, and approval status.
@SectionId('STFE')
class StaffingEntry {
  @Form([
    Field('roleTitle', String, 'Role Title',
        hint: 'Job title for this position', required: true),
    Field('jobFamily', String, 'Job Family',
        hint: 'Job family or career track — e.g. Engineering, Finance'),
    Field('jobLevel', String, 'Job Level',
        hint: 'Grade or level — e.g. Senior, L5, Manager'),
  ])
  String? content;

  /// Organization and employment placement.
  StaffingEntryOrganization organization = StaffingEntryOrganization();

  /// Capacity and competency requirements.
  StaffingEntryCapacity capacity = StaffingEntryCapacity();

  /// Recruitment workflow and urgency.
  StaffingEntryRecruitment recruitment = StaffingEntryRecruitment();

  /// Ownership and compensation details.
  StaffingEntryOwnership ownership = StaffingEntryOwnership();
}

/// Organization and employment placement.
@SectionId('STENOR')
class StaffingEntryOrganization {
  @Form([
    Field('department', String, 'Department',
        hint: 'Organizational unit'),
    Field('location', String, 'Location',
        hint: 'Site, region, or remote designation'),
    Field('employmentType', String, 'Employment Type',
        hint: 'Permanent / Contract / PartTime / Temporary'),
  ])
  String? content;
}

/// Capacity and competency requirements.
@SectionId('STENCA')
class StaffingEntryCapacity {
  @Form([
    Field('fteCount', double, 'FTE Count',
        hint: 'Full-time equivalent — e.g. 1.0, 0.5'),
    Field('headcount', int, 'Headcount',
        hint: 'Number of positions to fill'),
    Field('requiredSkills', String, 'Required Skills & Competencies',
        hint:
            'Key skills, certifications, and competencies — e.g. SQL, GDPR awareness, PMP'),
    Field('backfillRequired', String, 'Backfill Required',
        hint:
            'Yes / No — whether this replaces an existing person (affects knowledge transfer)'),
  ])
  String? content;
}

/// Recruitment workflow and urgency.
@SectionId('STENRE')
class StaffingEntryRecruitment {
  @Form([
    Field('approvalStatus', String, 'Approval Status',
        hint: 'Draft / Approved / OnHold / Cancelled'),
    Field('sourcingMethod', String, 'Sourcing Method',
        hint: 'Internal / External / Agency / Mixed'),
    Field('recruitmentStatus', String, 'Recruitment Status',
        hint:
            'Approved / Posted / Interviewing / Offered / Filled'),
    Field('targetStartDate', String, 'Target Start Date',
        hint: 'When this position should be filled'),
    Field('urgency', String, 'Urgency',
        hint: 'Critical / High / Medium / Low'),
  ])
  String? content;
}

/// Ownership and compensation details.
@SectionId('STENOW')
class StaffingEntryOwnership {
  @Form([
    Field('hiringManager', String, 'Hiring Manager',
        hint: 'Name or role of the hiring manager'),
    Field('recruiter', String, 'Recruiter',
        hint: 'HR point of contact'),
    Field('salaryRange', String, 'Salary Range',
        hint: 'Compensation range for this position'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or special requirements'),
  ])
  String? content;
}

/// Recruitment timeline.
@SectionId('RETI')
class RecruitmentTimeline {
  @Form([
    Field('recruitmentStart', String, 'Recruitment Start Date',
        hint: 'When recruitment activities begin'),
    Field('recruitmentEnd', String, 'Recruitment End Date',
        hint: 'Target date for completing all hiring'),
    Field('criticalHires', String, 'Critical Hires',
        hint: 'Roles that must be filled first — blocking dependencies'),
    Field('hiringWaves', String, 'Hiring Waves',
        hint: 'Phased recruitment approach — wave 1, wave 2, etc.'),
    Field('leadTimeAssumptions', String, 'Lead Time Assumptions',
        hint: 'Expected time to hire per role type — e.g. 8 weeks for senior'),
    Field('onboardingWaves', String, 'Onboarding Waves',
        hint: 'Start date cohorts for coordinated onboarding'),
    Field('externalDependencies', String, 'External Dependencies',
        hint:
            'Notice periods, visa processing, security clearance lead times — blockers outside your control'),
  ])
  String? content;
}

/// 5.2.5. Competency Framework.
@SectionId('COFR')
class CompetencyFramework {
  /// Framework overview.
  CompetencyFrameworkOverview overview = CompetencyFrameworkOverview();

  /// Core competencies required across all roles.
  @SectionId('COMPE-CORE-LST')
  @SectionIdPattern('COMPE-CORE-xxx')
  List<CompetencyEntry> coreCompetencies = [];

  /// Technical/functional competencies by role family.
  @SectionId('COMPE-TECH-LST')
  @SectionIdPattern('COMPE-TECH-xxx')
  List<CompetencyEntry> technicalCompetencies = [];

  /// Leadership competencies for management roles.
  @SectionId('COMPE-LEAD-LST')
  @SectionIdPattern('COMPE-LEAD-xxx')
  List<CompetencyEntry> leadershipCompetencies = [];
}

/// Competency framework overview.
@SectionId('COFROV')
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

/// A competency entry (form).
@SectionId('COMPE')
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

/// A new role entry (form).
///
/// Comprehensive new role definition following HR job analysis best practices.
/// Includes competencies, responsibilities, system access, and success metrics.
@SectionId('NRE')
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
@SectionId('NEROID')
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
@SectionId('NEROOR')
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
@SectionId('NERORE')
class NewRoleResponsibilities {
  /// Primary responsibilities (key accountabilities).
  @SectionId('RSPDT-PRIM-LST')
  @SectionIdPattern('RSPDT-PRIM-xxx')
  List<ResponsibilityDetailEntry> primaryResponsibilities = [];

  /// Secondary responsibilities (supporting duties).
  @SectionId('RSPDT-SECO-LST')
  @SectionIdPattern('RSPDT-SECO-xxx')
  List<ResponsibilityDetailEntry> secondaryResponsibilities = [];

  /// Decision-making authority.
  RoleDecisionAuthority decisionAuthority = RoleDecisionAuthority();
}

/// Detailed responsibility entry (form).
@SectionId('RSPDT')
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
@SectionId('RODEAU')
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
@SectionId('NEROQU')
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
  ])
  String? content;

  /// Credential and mobility requirements.
  NewRoleQualificationsCredentials credentials =
      NewRoleQualificationsCredentials();

  /// Screening and clearance requirements.
  NewRoleQualificationsScreening screening =
      NewRoleQualificationsScreening();

  /// Contains 0+× required competency.
  @SectionId('ROLCP-REQU-LST')
  @SectionIdPattern('ROLCP-REQU-xxx')
  List<RoleCompetencyEntry> requiredCompetencies = [];
}

/// Credential and mobility requirements.
@SectionId('NRQC')
class NewRoleQualificationsCredentials {
  @Form([
    Field('certifications', String,
        'Certifications — required certifications'),
    Field('licensure', String,
        'Licensure — professional licenses needed'),
    Field('languageRequirements', String,
        'Language Requirements — languages needed'),
    Field('travelRequirements', String,
        'Travel Requirements — percentage, destinations'),
  ])
  String? content;
}

/// Screening and clearance requirements.
@SectionId('NRQS')
class NewRoleQualificationsScreening {
  @Form([
    Field('physicalRequirements', String,
        'Physical Requirements — if applicable'),
    Field('backgroundCheck', String,
        'Background Check — type required'),
    Field('securityClearance', String,
        'Security Clearance — if required'),
  ])
  String? content;
}

/// Role competency entry (form).
@SectionId('ROLCP')
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
@SectionId('NRSA')
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
@SectionId('NEROPE')
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
@SectionId('NEROON')
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

/// A changed role entry (form).
///
/// Documents modifications to existing roles with impact assessment,
/// transition planning, and incumbent management.
@SectionId('CHAROL')
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
@SectionId('CHROID')
class ChangedRoleIdentification {
  @Form([
    Field('roleId', String, 'Role ID (e.g., CR-001)', required: true),
    Field('roleTitle', String, 'Current Role Title', required: true),
    Field('newRoleTitle', String, 'New Role Title — if title changes'),
    Field('changeRationale', String,
        'Change Rationale — why this role is changing'),
  ])
  String? content;

    /// Current and future organizational placement.
    ChangedRoleIdentificationStructure structure =
            ChangedRoleIdentificationStructure();

    /// Change implementation state and affected population.
    ChangedRoleIdentificationTransition transition =
            ChangedRoleIdentificationTransition();
}

/// Current and future organizational placement.
@SectionId('CRIS')
class ChangedRoleIdentificationStructure {
    @Form([
        Field('currentDepartment', String, 'Current Department'),
        Field('newDepartment', String, 'New Department — if moving'),
        Field('currentJobLevel', String, 'Current Job Level'),
        Field('newJobLevel', String, 'New Job Level — if changing'),
    ])
    String? content;
}

/// Change implementation state and affected population.
@SectionId('CRIT')
class ChangedRoleIdentificationTransition {
    @Form([
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
@SectionId('CHRORE')
class ChangedRoleResponsibilities {
  /// Responsibilities being added.
  @SectionId('RSPCH-ADDE-LST')
  @SectionIdPattern('RSPCH-ADDE-xxx')
  List<ResponsibilityChangeEntry> addedResponsibilities = [];

  /// Responsibilities being removed.
  @SectionId('RSPCH-REMO-LST')
  @SectionIdPattern('RSPCH-REMO-xxx')
  List<ResponsibilityChangeEntry> removedResponsibilities = [];

  /// Responsibilities being modified.
  @SectionId('RSPCH-MODI-LST')
  @SectionIdPattern('RSPCH-MODI-xxx')
  List<ResponsibilityChangeEntry> modifiedResponsibilities = [];

  /// Net impact summary.
  ResponsibilityImpactSummary impactSummary = ResponsibilityImpactSummary();
}

/// Responsibility change entry (form).
@SectionId('RSPCH')
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
@SectionId('REIMSU')
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
@SectionId('CHROCO')
class ChangedRoleCompetencies {
  /// New competencies required.
  @SectionId('ROLCP-NEWC-LST')
  @SectionIdPattern('ROLCP-NEWC-xxx')
  List<RoleCompetencyEntry> newCompetencies = [];

  /// Competencies no longer required.
  @SectionId('ROLCP-REMO-LST')
  @SectionIdPattern('ROLCP-REMO-xxx')
  List<RoleCompetencyEntry> removedCompetencies = [];

  /// Competencies with changed proficiency levels.
  @SectionId('COLVCH-CHAN-LST')
  @SectionIdPattern('COLVCH-CHAN-xxx')
  List<CompetencyLevelChangeEntry> changedLevels = [];

  /// Overall competency gap assessment.
  CompetencyGapAssessment gapAssessment = CompetencyGapAssessment();
}

/// Competency level change entry.
@SectionId('COLVCH')
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
@SectionId('COGAAS')
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
@SectionId('CRSA')
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
@SectionId('CRII')
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
@SectionId('CHROTR')
class ChangedRoleTransition {
  @Form([
    Field('transitionStart', String, 'Transition Start Date'),
    Field('transitionEnd', String, 'Transition End Date'),
    Field('parallelPeriod', String,
        'Parallel Period — overlap of old/new ways'),
  ])
  String? content;

  /// Training preparation for the transition.
  ChangedRoleTransitionTraining training = ChangedRoleTransitionTraining();

  /// Support expectations and success checkpoints.
  ChangedRoleTransitionSupport support = ChangedRoleTransitionSupport();
}

/// Training preparation for the transition.
@SectionId('CRTT')
class ChangedRoleTransitionTraining {
  @Form([
    Field('trainingSchedule', String,
        'Training Schedule — when training occurs'),
    Field('trainingDuration', String,
        'Training Duration — hours/days of training'),
    Field('trainingFormat', String,
        'Training Format — classroom, online, OJT'),
    Field('practiceOpportunities', String,
        'Practice Opportunities — sandbox, pilot'),
  ])
  String? content;
}

/// Support expectations and success checkpoints.
@SectionId('CRTS')
class ChangedRoleTransitionSupport {
  @Form([
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

/// A removed role entry (form).
///
/// Documents roles being eliminated with transition planning for incumbents.
@SectionId('REMROL')
class RemovedRoleEntry {
  @Form([
    Field('roleId', String, 'Role ID', required: true),
    Field('roleTitle', String, 'Role Title', required: true),
    Field('department', String, 'Department'),
    Field('removalReason', String,
        'Removal Reason — automation, restructuring, outsourcing, redundancy'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('incumbentCount', int, 'Incumbent Count — people affected'),
  ])
  String? content;

  /// Incumbent transition planning.
  RemovedRoleEntryTransition transition = RemovedRoleEntryTransition();

  /// Legal and communication considerations.
  RemovedRoleEntryGovernance governance = RemovedRoleEntryGovernance();

  /// Work continuity.
  RemovedRoleEntryContinuity continuity = RemovedRoleEntryContinuity();
}

/// Incumbent transition planning.
@SectionId('RRET')
class RemovedRoleEntryTransition {
  @Form([
    Field('incumbentDisposition', String,
        'Incumbent Disposition — redeployment, separation, retraining'),
    Field('reassignmentOptions', String,
        'Reassignment Options — alternative roles available'),
    Field('transitionSupport', String,
        'Transition Support — outplacement, retraining'),
    Field('severanceConsiderations', String,
        'Severance Considerations — if applicable'),
  ])
  String? content;
}

/// Legal and communication considerations.
@SectionId('RREG')
class RemovedRoleEntryGovernance {
  @Form([
    Field('legalConsiderations', String,
        'Legal Considerations — employment law, union agreements'),
    Field('communicationPlan', String,
        'Communication Plan — how removal is communicated'),
  ])
  String? content;
}

/// Work continuity.
@SectionId('RREC')
class RemovedRoleEntryContinuity {
  @Form([
    Field('knowledgeTransfer', String,
        'Knowledge Transfer — preserving institutional knowledge'),
    Field('workReassignment', String,
        'Work Reassignment — where responsibilities go'),
  ])
  String? content;
}

/// A responsibility entry (form).
@SectionId('ROREEN')
class RoleResponsibilityEntry {
  @Form([
    Field('responsibility', String, 'Responsibility'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// A skill entry (form).
@SectionId('SKEN')
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

/// A workplace description entry (form, per user category).
///
/// Comprehensive workplace requirements following workplace design best
/// practices (OSHA, ISO 9001, ergonomic standards). Covers physical,
/// technical, and training aspects per user category.
@Comment('per user category')
@SectionId('WPDE')
class WorkplaceDescriptionEntry {
  /// User category identification.
  WorkplaceUserCategory userCategory = WorkplaceUserCategory();

  /// Physical workplace layout and environment.
  PhysicalWorkplaceRequirements physicalRequirements =
      PhysicalWorkplaceRequirements();

  /// 5.3.1. Equipment Requirements.
  EquipmentRequirements equipmentRequirements = EquipmentRequirements();

  /// Technical infrastructure requirements.
  TechnicalInfrastructure technicalInfrastructure = TechnicalInfrastructure();

  /// 5.3.2. Training Requirements.
  TrainingRequirements trainingRequirements = TrainingRequirements();

  /// Support resources available to users.
  WorkplaceSupportResources supportResources = WorkplaceSupportResources();
}

/// User category identification for workplace definition.
@SectionId('WOUSCA')
class WorkplaceUserCategory {
  @Form([
    Field('categoryId', String, 'Category ID (e.g., WP-001)', required: true),
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Description — what defines this category'),
    Field('headcount', int, 'Headcount — number of users in this category'),
    Field('roles', String, 'Roles — job titles in this category'),
    Field('workPatterns', String,
        'Work Patterns — shift work, flex time, standard hours'),
    Field('workLocations', String,
        'Work Locations — office, remote, hybrid, field'),
    Field('primaryResponsibilities', String,
        'Primary Responsibilities — main work tasks'),
    Field('systemUsageIntensity', String,
        'System Usage Intensity — constant, frequent, occasional, rare'),
    Field('criticalityLevel', String,
        'Criticality Level — how critical is system access for this category'),
  ])
  String? content;
}

/// Physical workplace layout and environment requirements.
@SectionId('PHWORE')
class PhysicalWorkplaceRequirements {
  @Form([
    Field('workplaceType', String,
        'Workplace Type — office, cubicle, open plan, home office, mobile'),
    Field('workstationLayout', String,
        'Workstation Layout — desk configuration, monitor arrangement'),
    Field('spaceRequirements', String,
        'Space Requirements — square footage, accessibility'),
    Field('ergonomicStandards', String,
        'Ergonomic Standards — chair, desk height, monitor position'),
  ])
  String? content;

  /// Environmental conditions and controls.
  PhysicalWorkplaceRequirementsEnvironment environment =
      PhysicalWorkplaceRequirementsEnvironment();

  /// Accessibility, privacy, and shared-space needs.
  PhysicalWorkplaceRequirementsUsage usage =
      PhysicalWorkplaceRequirementsUsage();
}

/// Environmental conditions and controls.
@SectionId('PWRE1')
class PhysicalWorkplaceRequirementsEnvironment {
  @Form([
    Field('lightingRequirements', String,
        'Lighting Requirements — natural light, task lighting, glare reduction'),
    Field('noiseLevel', String,
        'Noise Level — acceptable dB, sound dampening needs'),
    Field('temperatureControl', String,
        'Temperature Control — HVAC requirements'),
    Field('ventilation', String, 'Ventilation — air quality requirements'),
  ])
  String? content;
}

/// Accessibility, privacy, and shared-space needs.
@SectionId('PWRU')
class PhysicalWorkplaceRequirementsUsage {
  @Form([
    Field('accessibilityFeatures', String,
        'Accessibility Features — ADA compliance, wheelchair access'),
    Field('privacyRequirements', String,
        'Privacy Requirements — visual privacy, sound isolation'),
    Field('collaborationSpaces', String,
        'Collaboration Spaces — meeting rooms, huddle spaces access'),
    Field('storageNeeds', String,
        'Storage Needs — physical document/material storage'),
  ])
  String? content;
}

/// 5.3.1. Equipment Requirements.
///
/// Hardware and peripheral requirements per workplace type.
@SectionId('EQRE')
class EquipmentRequirements {
  /// Equipment overview.
  EquipmentOverview overview = EquipmentOverview();

  /// Primary computing equipment.
  @SectionId('COEQ-PRIM-LST')
  @SectionIdPattern('COEQ-PRIM-xxx')
  List<ComputingEquipmentEntry> primaryComputing = [];

  /// Display and monitors.
  @SectionId('DSEQ-DISP-LST')
  @SectionIdPattern('DSEQ-DISP-xxx')
  List<DisplayEquipmentEntry> displays = [];

  /// Input devices.
  @SectionId('INPDE-INPU-LST')
  @SectionIdPattern('INPDE-INPU-xxx')
  List<InputDeviceEntry> inputDevices = [];

  /// Peripheral equipment.
  @SectionId('PEREQ-PERI-LST')
  @SectionIdPattern('PEREQ-PERI-xxx')
  List<PeripheralEquipmentEntry> peripherals = [];

  /// Mobile devices.
  @SectionId('MOBDE-MOBI-LST')
  @SectionIdPattern('MOBDE-MOBI-xxx')
  List<MobileDeviceEntry> mobileDevices = [];

  /// Specialized equipment.
  @SectionId('SPEQ-SPEC-LST')
  @SectionIdPattern('SPEQ-SPEC-xxx')
  List<SpecializedEquipmentEntry> specializedEquipment = [];
}

/// Equipment overview and standards.
@SectionId('EQOV')
class EquipmentOverview {
  @Form([
    Field('equipmentStandard', String,
        'Equipment Standard — corporate standard, premium, basic'),
    Field('refreshCycle', String,
        'Refresh Cycle — replacement frequency (e.g., 3 years)'),
    Field('procurementProcess', String,
        'Procurement Process — how equipment is ordered'),
    Field('assetTracking', String,
        'Asset Tracking — how equipment is tracked'),
    Field('supportModel', String,
        'Support Model — warranty, maintenance, break-fix'),
    Field('disposalProcess', String,
        'Disposal Process — end-of-life handling'),
    Field('budgetAllocation', String,
        'Budget Allocation — equipment budget per user'),
  ])
  String? content;
}

/// Computing equipment entry (form).
@SectionId('COEQ')
class ComputingEquipmentEntry {
  @Form([
    Field('equipmentId', String, 'Equipment ID'),
    Field('deviceType', String,
        'Device Type — desktop, laptop, workstation, thin client'),
    Field('brand', String, 'Brand — manufacturer preference'),
    Field('modelSpecification', String, 'Model/Specification — exact model'),
  ])
  String? content;

    /// Hardware specifications.
    ComputingEquipmentEntryHardware hardware = ComputingEquipmentEntryHardware();

    /// Platform and security requirements.
    ComputingEquipmentEntryPlatform platform = ComputingEquipmentEntryPlatform();

    /// Deployment and justification.
    ComputingEquipmentEntryPlanning planning = ComputingEquipmentEntryPlanning();
}

/// Hardware specifications.
@SectionId('CEEH')
class ComputingEquipmentEntryHardware {
    @Form([
        Field('processor', String, 'Processor — CPU requirements'),
        Field('memory', String, 'Memory — RAM requirements'),
        Field('storage', String, 'Storage — HDD/SSD requirements'),
        Field('graphicsCard', String, 'Graphics Card — if required'),
    ])
    String? content;
}

/// Platform and security requirements.
@SectionId('CEEP')
class ComputingEquipmentEntryPlatform {
    @Form([
        Field('operatingSystem', String, 'Operating System — OS version'),
        Field('securityFeatures', String,
                'Security Features — TPM, biometric, encryption'),
        Field('portRequirements', String,
                'Port Requirements — USB, HDMI, network ports'),
        Field('formFactor', String,
                'Form Factor — tower, small form factor, all-in-one'),
    ])
    String? content;
}

/// Deployment and justification.
@SectionId('CEEP1')
class ComputingEquipmentEntryPlanning {
    @Form([
        Field('quantityNeeded', int, 'Quantity Needed'),
        Field('priorityLevel', String,
                'Priority Level — critical, standard, optional'),
        Field('justification', String, 'Justification — why this specification'),
    ])
    String? content;
}

/// Display equipment entry (form).
@SectionId('DSEQ')
class DisplayEquipmentEntry {
  @Form([
    Field('displayId', String, 'Display ID'),
    Field('displayType', String,
        'Display Type — monitor, projector, video wall'),
    Field('screenSize', String, 'Screen Size — diagonal inches'),
    Field('resolution', String, 'Resolution — HD, FHD, QHD, 4K'),
  ])
  String? content;

    /// Display quality and connection properties.
    DisplayEquipmentEntryVisual visual = DisplayEquipmentEntryVisual();

    /// Ergonomic and placement considerations.
    DisplayEquipmentEntryErgonomics ergonomics =
            DisplayEquipmentEntryErgonomics();

    /// Quantity planning and justification.
    DisplayEquipmentEntryPlanning planning = DisplayEquipmentEntryPlanning();
}

/// Display quality and connection properties.
@SectionId('DEEV')
class DisplayEquipmentEntryVisual {
    @Form([
        Field('panelType', String, 'Panel Type — IPS, VA, TN, OLED'),
        Field('refreshRate', String, 'Refresh Rate — Hz'),
        Field('colorAccuracy', String,
                'Color Accuracy — sRGB coverage, if color-critical'),
        Field('connectivity', String,
                'Connectivity — HDMI, DisplayPort, USB-C'),
    ])
    String? content;
}

/// Ergonomic and placement considerations.
@SectionId('DEEE')
class DisplayEquipmentEntryErgonomics {
    @Form([
        Field('adjustability', String,
                'Adjustability — height, tilt, swivel, pivot'),
        Field('ergonomicFeatures', String,
                'Ergonomic Features — blue light filter, flicker-free'),
        Field('mounting', String, 'Mounting — stand, arm, wall mount'),
    ])
    String? content;
}

/// Quantity planning and justification for display equipment.
@SectionId('DEEP1')
class DisplayEquipmentEntryPlanning {
    @Form([
        Field('quantityPerUser', int, 'Quantity Per User — number of monitors'),
        Field('justification', String, 'Justification'),
    ])
    String? content;
}

/// Input device entry (form).
@SectionId('IDE')
class InputDeviceEntry {
  @Form([
    Field('deviceId', String, 'Device ID'),
    Field('deviceType', String,
        'Device Type — keyboard, mouse, trackpad, stylus, touchscreen'),
    Field('ergonomicDesign', String,
        'Ergonomic Design — split keyboard, vertical mouse'),
    Field('connectivity', String,
        'Connectivity — wired, wireless, Bluetooth'),
    Field('specialFeatures', String,
        'Special Features — programmable keys, precision'),
    Field('accessibilityFeatures', String,
        'Accessibility Features — large keys, one-handed'),
    Field('quantityPerUser', int, 'Quantity Per User'),
    Field('justification', String, 'Justification'),
  ])
  String? content;
}

/// Peripheral equipment entry (form).
@SectionId('PEREQ')
class PeripheralEquipmentEntry {
  @Form([
    Field('peripheralId', String, 'Peripheral ID'),
    Field('peripheralType', String,
        'Peripheral Type — printer, scanner, webcam, headset, docking station'),
    Field('brand', String, 'Brand'),
    Field('model', String, 'Model'),
    Field('specifications', String, 'Specifications — key specs'),
    Field('connectivity', String, 'Connectivity — USB, network, Bluetooth'),
    Field('sharedOrPersonal', String,
        'Shared/Personal — dedicated or shared device'),
    Field('location', String, 'Location — workstation, print room, etc.'),
    Field('quantityNeeded', int, 'Quantity Needed'),
    Field('justification', String, 'Justification'),
  ])
  String? content;
}

/// Mobile device entry (form).
@SectionId('MOBDE')
class MobileDeviceEntry {
  @Form([
    Field('deviceId', String, 'Device ID'),
    Field('deviceType', String,
        'Device Type — smartphone, tablet, rugged device'),
    Field('operatingSystem', String, 'Operating System — iOS, Android'),
    Field('screenSize', String, 'Screen Size'),
  ])
  String? content;

    /// Technical and management requirements.
    MobileDeviceEntryCapabilities capabilities = MobileDeviceEntryCapabilities();

    /// Deployment planning and supporting accessories.
    MobileDeviceEntryPlanning planning = MobileDeviceEntryPlanning();
}

/// Technical and management requirements.
@SectionId('MDEC1')
class MobileDeviceEntryCapabilities {
    @Form([
        Field('storageCapacity', String, 'Storage Capacity'),
        Field('cellularConnectivity', String,
                'Cellular Connectivity — 4G, 5G, none'),
        Field('durabilityRating', String,
                'Durability Rating — IP rating, drop protection'),
        Field('mdmEnrollment', String,
                'MDM Enrollment — mobile device management requirements'),
    ])
    String? content;
}

/// Deployment planning and supporting accessories.
@SectionId('MDEP')
class MobileDeviceEntryPlanning {
    @Form([
        Field('dataCarrier', String,
                'Data Carrier — carrier, plan type'),
        Field('accessories', String,
                'Accessories — case, screen protector, car mount'),
        Field('quantityNeeded', int, 'Quantity Needed'),
        Field('justification', String, 'Justification'),
    ])
    String? content;
}

/// Specialized equipment entry (form).
@SectionId('SPEQ')
class SpecializedEquipmentEntry {
  @Form([
    Field('equipmentId', String, 'Equipment ID'),
    Field('equipmentType', String,
        'Equipment Type — barcode scanner, card reader, signature pad'),
    Field('brand', String, 'Brand'),
    Field('model', String, 'Model'),
    Field('purpose', String, 'Purpose — business function supported'),
  ])
  String? content;

    /// Technical and compliance characteristics.
    SpecializedEquipmentEntryTechnical technical =
            SpecializedEquipmentEntryTechnical();

    /// Quantity and business justification.
    SpecializedEquipmentEntryPlanning planning =
            SpecializedEquipmentEntryPlanning();
}

/// Technical and compliance characteristics.
@SectionId('SEET')
class SpecializedEquipmentEntryTechnical {
    @Form([
        Field('specifications', String, 'Specifications'),
        Field('connectivity', String, 'Connectivity'),
        Field('driverSoftware', String,
                'Driver/Software — software requirements'),
        Field('certifications', String,
                'Certifications — PCI, EMV, etc.'),
    ])
    String? content;
}

/// Quantity and business justification.
@SectionId('SEEP')
class SpecializedEquipmentEntryPlanning {
    @Form([
        Field('quantityNeeded', int, 'Quantity Needed'),
        Field('justification', String, 'Justification'),
    ])
    String? content;
}

/// Technical infrastructure requirements.
@SectionId('TEIN')
class TechnicalInfrastructure {
  /// Network connectivity requirements.
  NetworkConnectivity networkConnectivity = NetworkConnectivity();

  /// Software requirements.
  WorkplaceSoftwareRequirements softwareRequirements =
      WorkplaceSoftwareRequirements();

  /// Remote access requirements.
  RemoteAccessRequirements remoteAccess = RemoteAccessRequirements();

  /// Communication tools.
  @SectionId('COTORE-COMM-LST')
  @SectionIdPattern('COTORE-COMM-xxx')
  List<CommunicationToolsRequirements> communicationTools = [];
}

/// Network connectivity requirements.
@SectionId('NECO')
class NetworkConnectivity {
  @Form([
    Field('connectionType', String,
        'Connection Type — wired ethernet, Wi-Fi, both'),
    Field('bandwidthRequirement', String,
        'Bandwidth Requirement — minimum Mbps'),
    Field('latencyRequirement', String,
        'Latency Requirement — maximum acceptable ms'),
    Field('vpnRequirement', String,
        'VPN Requirement — always-on, on-demand, none'),
    Field('networkSegment', String,
        'Network Segment — VLAN, security zone'),
    Field('firewallRules', String,
        'Firewall Rules — ports, protocols needed'),
    Field('proxyConfiguration', String,
        'Proxy Configuration — if required'),
    Field('dnsRequirements', String,
        'DNS Requirements — internal DNS, split DNS'),
    Field('redundancyRequirement', String,
        'Redundancy Requirement — failover connectivity'),
    Field('guestNetworkAccess', String,
        'Guest Network Access — if needed'),
  ])
  String? content;
}

/// Workplace software requirements.
@SectionId('WOSORE')
class WorkplaceSoftwareRequirements {
  @Form([
    Field('operatingSystem', String, 'Operating System — version, edition'),
    Field('productivitySuite', String,
        'Productivity Suite — Office 365, Google Workspace'),
    Field('browser', String, 'Browser — Chrome, Edge, Firefox'),
    Field('emailClient', String, 'Email Client — Outlook, web-based'),
  ])
  String? content;

  /// Security and collaboration software stack.
  WorkplaceSoftwareRequirementsPlatform platform =
      WorkplaceSoftwareRequirementsPlatform();

  /// Business application set and deployment model.
  WorkplaceSoftwareRequirementsDelivery delivery =
      WorkplaceSoftwareRequirementsDelivery();
}

/// Security and collaboration software stack.
@SectionId('WSRP')
class WorkplaceSoftwareRequirementsPlatform {
  @Form([
    Field('securitySoftware', String,
        'Security Software — antivirus, EDR, firewall'),
    Field('encryptionSoftware', String,
        'Encryption Software — disk encryption, file encryption'),
    Field('collaborationTools', String,
        'Collaboration Tools — Teams, Slack, Zoom'),
    Field('documentManagement', String,
        'Document Management — SharePoint, OneDrive'),
  ])
  String? content;
}

/// Business application set and deployment model.
@SectionId('WSRD')
class WorkplaceSoftwareRequirementsDelivery {
  @Form([
    Field('businessApplications', String,
        'Business Applications — specific apps needed'),
    Field('developmentTools', String,
        'Development Tools — if applicable'),
    Field('licenseType', String,
        'License Type — per user, per device, concurrent'),
    Field('installationMethod', String,
        'Installation Method — SCCM, Intune, manual'),
  ])
  String? content;
}

/// Remote access requirements.
@SectionId('REACRE')
class RemoteAccessRequirements {
  @Form([
    Field('remoteAccessType', String,
        'Remote Access Type — VPN, VDI, direct access'),
    Field('vpnClient', String, 'VPN Client — specific client software'),
    Field('vdiPlatform', String,
        'VDI Platform — Citrix, VMware Horizon, AVD'),
    Field('mfaRequirement', String,
        'MFA Requirement — hardware token, app, SMS'),
    Field('homeNetworkRequirements', String,
        'Home Network Requirements — minimum internet speed'),
    Field('splitTunnel', String,
        'Split Tunnel — allowed, required, prohibited'),
    Field('sessionTimeout', String,
        'Session Timeout — idle timeout, max session'),
    Field('localPrintingAllowed', String,
        'Local Printing Allowed — yes, no, restricted'),
    Field('localDriveAccess', String,
        'Local Drive Access — allowed, restricted, blocked'),
    Field('remoteSupport', String,
        'Remote Support — how IT supports remote users'),
  ])
  String? content;
}

/// Communication tools requirements.
@SectionId('COTORE')
class CommunicationToolsRequirements {
  @Form([
    Field('unifiedComms', String,
        'Unified Communications Platform — Teams, Zoom, Webex'),
    Field('voiceCapability', String,
        'Voice Capability — softphone, desk phone, mobile'),
    Field('videoConferencing', String,
        'Video Conferencing — external meetings, capabilities'),
    Field('instantMessaging', String,
        'Instant Messaging — chat platform'),
    Field('presenceIndicator', String,
        'Presence Indicator — availability status requirements'),
    Field('screenSharing', String,
        'Screen Sharing — capabilities, security controls'),
    Field('recordingCapability', String,
        'Recording Capability — meeting recording, compliance'),
    Field('integrations', String,
        'Integrations — calendar, CRM, ticketing system'),
    Field('externalCommunication', String,
        'External Communication — ability to call/message externally'),
    Field('emergencyContact', String,
        'Emergency Contact — emergency calling, E911'),
  ])
  String? content;
}

/// 5.3.2. Training Requirements.
///
/// Comprehensive training program requirements following adult learning
/// principles (ADDIE, Kirkpatrick evaluation model).
@SectionId('TRRE')
class TrainingRequirements {
  /// Training overview and strategy.
  TrainingOverview overview = TrainingOverview();

  /// Initial/onboarding training.
  @SectionId('INITR-INIT-LST')
  @SectionIdPattern('INITR-INIT-xxx')
  List<InitialTrainingEntry> initialTraining = [];

  /// Ongoing/refresher training.
  @SectionId('ONGTR-ONGO-LST')
  @SectionIdPattern('ONGTR-ONGO-xxx')
  List<OngoingTrainingEntry> ongoingTraining = [];

  /// System-specific training.
  @SectionId('SYTR-SYST-LST')
  @SectionIdPattern('SYTR-SYST-xxx')
  List<SystemTrainingEntry> systemTraining = [];

  /// Certification requirements.
  @SectionId('CRT-CERT-LST')
  @SectionIdPattern('CRT-CERT-xxx')
  List<CertificationEntry> certifications = [];

  /// Training materials and resources.
  TrainingMaterials trainingMaterials = TrainingMaterials();

  /// Assessment and evaluation.
  TrainingAssessment assessment = TrainingAssessment();
}

/// Training overview and strategy.
@SectionId('TROV')
class TrainingOverview {
  @Form([
    Field('trainingStrategy', String,
        'Training Strategy — overall approach to training'),
    Field('learningManagementSystem', String,
        'Learning Management System — LMS platform used'),
    Field('blendedLearningApproach', String,
        'Blended Learning Approach — mix of methods'),
    Field('trainingBudget', String,
        'Training Budget — per user, total'),
    Field('trainingTimeline', String,
        'Training Timeline — when training occurs'),
    Field('trainingOwner', String,
        'Training Owner — department/person responsible'),
    Field('trainerResources', String,
        'Trainer Resources — internal trainers, external vendors'),
    Field('trainingFacilities', String,
        'Training Facilities — classrooms, labs, online'),
    Field('successCriteria', String,
        'Success Criteria — how training success is measured'),
    Field('feedbackMechanism', String,
        'Feedback Mechanism — how feedback is collected'),
  ])
  String? content;
}

/// Initial training entry (form).
@SectionId('ITE')
class InitialTrainingEntry {
  @Form([
    Field('trainingId', String, 'Training ID', required: true),
    Field('trainingName', String, 'Training Name', required: true),
    Field('description', String, 'Description'),
  ])
  String? content;

  /// Target and prerequisites.
  InitialTrainingAudience audience = InitialTrainingAudience();

  /// Learning content.
  InitialTrainingContent learningContent = InitialTrainingContent();

  /// Delivery details.
  InitialTrainingDelivery delivery = InitialTrainingDelivery();

  /// Schedule information.
  InitialTrainingSchedule schedule = InitialTrainingSchedule();

  /// Assessment and certification.
  InitialTrainingAssessment assessment = InitialTrainingAssessment();
}

/// Target and prerequisites.
@SectionId('INTRAU')
class InitialTrainingAudience {
  @Form([
    Field('targetAudience', String, 'Target Audience — who takes this'),
    Field('prerequisiteTraining', String,
        'Prerequisite Training — training required first'),
    Field('prerequisiteKnowledge', String,
        'Prerequisite Knowledge — skills needed'),
  ])
  String? content;
}

/// Learning content.
@SectionId('INTRCO')
class InitialTrainingContent {
  @Form([
    Field('learningObjectives', String,
        'Learning Objectives — what participants will learn'),
    Field('materials', String, 'Materials — what is provided'),
    Field('practiceEnvironment', String,
        'Practice Environment — sandbox, simulation'),
  ])
  String? content;
}

/// Delivery details.
@SectionId('INTRDE')
class InitialTrainingDelivery {
  @Form([
    Field('format', String,
        'Format — classroom, online, hands-on, blended'),
    Field('duration', String, 'Duration — hours/days'),
    Field('deliveryMethod', String,
        'Delivery Method — live, self-paced, instructor-led'),
    Field('classSize', int, 'Class Size — max participants'),
    Field('location', String, 'Location — training site, virtual'),
    Field('trainer', String, 'Trainer — who delivers'),
    Field('mandatory', String, 'Mandatory — required or optional'),
  ])
  String? content;
}

/// Schedule information.
@SectionId('INTRSC')
class InitialTrainingSchedule {
  @Form([
    Field('schedule', String,
        'Schedule — when offered relative to go-live'),
    Field('frequency', String, 'Frequency — one-time, recurring schedule'),
  ])
  String? content;
}

/// Assessment and certification.
@SectionId('INTRAS')
class InitialTrainingAssessment {
  @Form([
    Field('assessmentMethod', String,
        'Assessment Method — test, practical, none'),
    Field('passingCriteria', String, 'Passing Criteria — minimum score'),
    Field('retakePolicy', String, 'Retake Policy — if assessment failed'),
    Field('competencyEarned', String,
        'Competency Earned — skill/competency certified'),
    Field('expirationPeriod', String,
        'Expiration Period — when refresher needed'),
    Field('costPerParticipant', String,
        'Cost Per Participant — training cost'),
  ])
  String? content;
}

/// Ongoing training entry (form).
@SectionId('ONGTR')
class OngoingTrainingEntry {
  @Form([
    Field('trainingId', String, 'Training ID', required: true),
    Field('trainingName', String, 'Training Name', required: true),
    Field('description', String, 'Description'),
    Field('targetAudience', String, 'Target Audience'),
  ])
  String? content;

  /// Scheduling and delivery.
  OngoingTrainingEntrySchedule schedule = OngoingTrainingEntrySchedule();

  /// Content maintenance.
  OngoingTrainingEntryContent contentManagement =
      OngoingTrainingEntryContent();

  /// Tracking and compliance.
  OngoingTrainingEntryCompliance compliance =
      OngoingTrainingEntryCompliance();
}

/// Scheduling and delivery.
@SectionId('OTES')
class OngoingTrainingEntrySchedule {
  @Form([
    Field('trainingType', String,
        'Training Type — refresher, update, advanced, cross-training'),
    Field('triggerCondition', String,
        'Trigger Condition — time-based, event-based, performance-based'),
    Field('frequency', String,
        'Frequency — annual, quarterly, as-needed'),
    Field('format', String, 'Format'),
    Field('duration', String, 'Duration'),
  ])
  String? content;
}

/// Content maintenance.
@SectionId('OTEC')
class OngoingTrainingEntryContent {
  @Form([
    Field('learningObjectives', String, 'Learning Objectives'),
    Field('contentUpdates', String,
        'Content Updates — how content is kept current'),
  ])
  String? content;
}

/// Tracking and compliance.
@SectionId('OTEC1')
class OngoingTrainingEntryCompliance {
  @Form([
    Field('mandatory', String, 'Mandatory'),
    Field('trackingMethod', String,
        'Tracking Method — how completion is tracked'),
    Field('complianceRequirement', String,
        'Compliance Requirement — regulatory requirement'),
    Field('reminderProcess', String,
        'Reminder Process — how users are notified'),
    Field('noncompliance', String,
        'Non-compliance — consequences of missing training'),
  ])
  String? content;
}

/// System training entry (form).
@SectionId('SYTR')
class SystemTrainingEntry {
  @Form([
    Field('trainingId', String, 'Training ID', required: true),
    Field('systemName', String, 'System Name', required: true),
    Field('modulesCovered', String,
        'Modules Covered — system modules in scope'),
    Field('userRoleFocus', String,
        'User Role Focus — specific role training'),
  ])
  String? content;

  /// Functional training coverage.
  SystemTrainingEntryFunctional functional = SystemTrainingEntryFunctional();

  /// Practical exercises.
  SystemTrainingEntryPractice practice = SystemTrainingEntryPractice();

  /// Support and environment.
  SystemTrainingEntrySupport support = SystemTrainingEntrySupport();
}

/// Functional training coverage.
@SectionId('STEF')
class SystemTrainingEntryFunctional {
  @Form([
    Field('functionalScope', String,
        'Functional Scope — functions covered'),
    Field('taskBasedLearning', String,
        'Task-Based Learning — specific tasks taught'),
    Field('navigationTraining', String,
        'Navigation Training — general system navigation'),
    Field('reportingTraining', String,
        'Reporting Training — reports, dashboards'),
    Field('workflowTraining', String,
        'Workflow Training — business workflows'),
  ])
  String? content;
}

/// Practical exercises.
@SectionId('STEP')
class SystemTrainingEntryPractice {
  @Form([
    Field('dataEntryPractice', String,
        'Data Entry Practice — hands-on data entry'),
    Field('integrationAwareness', String,
        'Integration Awareness — related systems'),
    Field('scenarioBased', String,
        'Scenario-Based — realistic scenarios practiced'),
  ])
  String? content;
}

/// Support and environment.
@SectionId('STES')
class SystemTrainingEntrySupport {
  @Form([
    Field('troubleshootingBasics', String,
        'Troubleshooting Basics — common issues'),
    Field('helpResources', String,
        'Help Resources — where to get help'),
    Field('sandboxEnvironment', String,
        'Sandbox Environment — practice system'),
  ])
  String? content;
}

/// Certification entry (form).
@SectionId('CRT')
class CertificationEntry {
  @Form([
    Field('certificationId', String, 'Certification ID', required: true),
    Field('certificationName', String, 'Certification Name', required: true),
    Field('issuingBody', String, 'Issuing Body — who certifies'),
  ])
  String? content;

    /// Description and audience.
    CertificationEntryOverview overview = CertificationEntryOverview();

    /// Preparation requirements.
    CertificationEntryPreparation preparation = CertificationEntryPreparation();

    /// Exam details.
    CertificationEntryExam exam = CertificationEntryExam();

    /// Validity and renewal details.
    CertificationEntryMaintenance maintenance =
            CertificationEntryMaintenance();

    /// Sponsorship and consequences.
    CertificationEntrySupport support = CertificationEntrySupport();
}

/// Description and audience.
@SectionId('CEENOV')
class CertificationEntryOverview {
    @Form([
        Field('description', String, 'Description'),
        Field('targetRoles', String, 'Target Roles — who needs this'),
        Field('mandatory', String, 'Mandatory — required or recommended'),
    ])
    String? content;
}

/// Preparation requirements.
@SectionId('CEENPR')
class CertificationEntryPreparation {
    @Form([
        Field('prerequisites', String, 'Prerequisites'),
        Field('preparationPath', String,
                'Preparation Path — how to prepare'),
    ])
    String? content;
}

/// Exam details.
@SectionId('CEENEX')
class CertificationEntryExam {
    @Form([
        Field('examFormat', String,
                'Exam Format — multiple choice, practical, etc.'),
        Field('examDuration', String, 'Exam Duration'),
        Field('passingScore', String, 'Passing Score'),
        Field('examCost', String, 'Exam Cost'),
        Field('examLocation', String,
                'Exam Location — testing center, online'),
    ])
    String? content;
}

/// Validity and renewal details.
@SectionId('CEENMA')
class CertificationEntryMaintenance {
    @Form([
        Field('validityPeriod', String, 'Validity Period — how long valid'),
        Field('renewalRequirements', String,
                'Renewal Requirements — CEUs, retake'),
    ])
    String? content;
}

/// Sponsorship and consequences.
@SectionId('CEENSU')
class CertificationEntrySupport {
    @Form([
        Field('companySponsored', String,
                'Company Sponsored — paid by company'),
        Field('studyTimeAllotted', String,
                'Study Time Allotted — work time for study'),
        Field('failureConsequence', String,
                'Failure Consequence — impact on role'),
    ])
    String? content;
}

/// Training materials and resources.
@SectionId('TRMA')
class TrainingMaterials {
  @Form([
    Field('userGuides', String,
        'User Guides — printed/digital manuals'),
    Field('quickReferenceCards', String,
        'Quick Reference Cards — job aids'),
    Field('videoTutorials', String,
        'Video Tutorials — recorded demonstrations'),
    Field('elearningModules', String,
        'E-Learning Modules — interactive online courses'),
  ])
  String? content;

  /// Practice and reference resources.
  TrainingMaterialsPractice practice = TrainingMaterialsPractice();

  /// Knowledge distribution.
  TrainingMaterialsKnowledge knowledge = TrainingMaterialsKnowledge();

  /// Publishing and accessibility.
  TrainingMaterialsOperations operations = TrainingMaterialsOperations();
}

/// Practice and reference resources.
@SectionId('TRMAPR')
class TrainingMaterialsPractice {
  @Form([
    Field('simulationEnvironment', String,
        'Simulation Environment — sandbox for practice'),
    Field('practiceExercises', String,
        'Practice Exercises — hands-on exercises'),
    Field('cheatSheets', String,
        'Cheat Sheets — shortcuts, tips'),
    Field('processFlowcharts', String,
        'Process Flowcharts — visual process guides'),
    Field('screenRecordings', String,
        'Screen Recordings — step-by-step demos'),
  ])
  String? content;
}

/// Knowledge distribution.
@SectionId('TRMAKN')
class TrainingMaterialsKnowledge {
  @Form([
    Field('knowledgeBase', String,
        'Knowledge Base — searchable help articles'),
    Field('faq', String, 'FAQ — frequently asked questions'),
    Field('accessMethod', String,
        'Access Method — LMS, intranet, SharePoint'),
  ])
  String? content;
}

/// Publishing and accessibility.
@SectionId('TRMAOP')
class TrainingMaterialsOperations {
  @Form([
    Field('updateProcess', String,
        'Update Process — how materials are updated'),
    Field('translationNeeds', String,
        'Translation Needs — languages required'),
    Field('accessibilityFormat', String,
        'Accessibility Format — screen reader, captions'),
  ])
  String? content;
}

/// Training assessment and evaluation.
@SectionId('TRAS')
class TrainingAssessment {
  @Form([
    Field('assessmentStrategy', String,
        'Assessment Strategy — how learning is measured'),
    Field('preAssessment', String,
        'Pre-Assessment — baseline knowledge check'),
    Field('postAssessment', String,
        'Post-Assessment — end-of-training test'),
    Field('practicalEvaluation', String,
        'Practical Evaluation — hands-on demonstration'),
  ])
  String? content;

  /// Retention and effectiveness evaluation.
  TrainingAssessmentEffectiveness effectiveness =
      TrainingAssessmentEffectiveness();

  /// Competency and remediation management.
  TrainingAssessmentImprovement improvement =
      TrainingAssessmentImprovement();

  /// Progress reporting.
  TrainingAssessmentReporting reporting = TrainingAssessmentReporting();
}

/// Retention and effectiveness evaluation.
@SectionId('TRASEF')
class TrainingAssessmentEffectiveness {
  @Form([
    Field('knowledgeRetention', String,
        'Knowledge Retention — follow-up assessments'),
    Field('kirkpatrickLevel1', String,
        'Level 1 (Reaction) — satisfaction surveys'),
    Field('kirkpatrickLevel2', String,
        'Level 2 (Learning) — knowledge/skill gain'),
    Field('kirkpatrickLevel3', String,
        'Level 3 (Behavior) — on-the-job application'),
    Field('kirkpatrickLevel4', String,
        'Level 4 (Results) — business impact'),
  ])
  String? content;
}

/// Competency and remediation management.
@SectionId('TRASIM')
class TrainingAssessmentImprovement {
  @Form([
    Field('competencyMapping', String,
        'Competency Mapping — linking training to competencies'),
    Field('gapAnalysis', String,
        'Gap Analysis — identifying remaining gaps'),
    Field('remediation', String,
        'Remediation — addressing failed assessments'),
  ])
  String? content;
}

/// Progress reporting.
@SectionId('TRASRE')
class TrainingAssessmentReporting {
  @Form([
    Field('progressTracking', String,
        'Progress Tracking — individual progress visibility'),
    Field('reportingDashboard', String,
        'Reporting Dashboard — training metrics'),
    Field('managementVisibility', String,
        'Management Visibility — supervisor access to progress'),
  ])
  String? content;
}

/// Support resources available to users.
@SectionId('WOSURE')
class WorkplaceSupportResources {
  @Form([
    Field('helpDeskAccess', String,
        'Help Desk Access — phone, email, chat, portal'),
    Field('helpDeskHours', String,
        'Help Desk Hours — support availability'),
    Field('escalationPath', String,
        'Escalation Path — how issues escalate'),
    Field('onSiteSupport', String,
        'On-Site Support — deskside support availability'),
  ])
  String? content;

  /// Extended support channels.
  WorkplaceSupportResourcesChannels channels =
      WorkplaceSupportResourcesChannels();

  /// Self-service and feedback.
  WorkplaceSupportResourcesSelfService selfService =
      WorkplaceSupportResourcesSelfService();

  /// Incident and emergency support.
  WorkplaceSupportResourcesIncidents incidents =
      WorkplaceSupportResourcesIncidents();
}

/// Extended support channels.
@SectionId('WSRC')
class WorkplaceSupportResourcesChannels {
  @Form([
    Field('remoteSupport', String,
        'Remote Support — remote troubleshooting'),
    Field('superUserNetwork', String,
        'Super User Network — power users for first-line help'),
  ])
  String? content;
}

/// Self-service and feedback.
@SectionId('WSRSS')
class WorkplaceSupportResourcesSelfService {
  @Form([
    Field('knowledgeBase', String,
        'Knowledge Base — self-service help articles'),
    Field('communityForum', String,
        'Community Forum — user community for help'),
    Field('chatbot', String, 'Chatbot — AI-assisted support'),
    Field('feedbackChannel', String,
        'Feedback Channel — how to submit suggestions'),
  ])
  String? content;
}

/// Incident and emergency support.
@SectionId('WSRI')
class WorkplaceSupportResourcesIncidents {
  @Form([
    Field('incidentReporting', String,
        'Incident Reporting — how to report issues'),
    Field('slaExpectations', String,
        'SLA Expectations — response/resolution times'),
    Field('afterHoursSupport', String,
        'After-Hours Support — out-of-hours help'),
    Field('emergencyProcedures', String,
        'Emergency Procedures — for critical issues'),
  ])
  String? content;
}
