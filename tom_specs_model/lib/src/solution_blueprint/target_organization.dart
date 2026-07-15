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
  @SerializationOrder(0)
  TextSection overview = TextSection();

  /// 5.1. New Organization Structure.
  @SerializationOrder(1)
  NewOrganizationStructure organizationStructure = NewOrganizationStructure();

  /// 5.2. Job Descriptions and Staffing Plans.
  ///
  /// Single composite section: the role multiplicity is carried by the inner
  /// new/changed/removed-role lists, so this is one section, not a catalog of
  /// sections (collapsed from `List<JobDescriptionsAndStaffing>`, L34C-12 SR-23).
  @SerializationOrder(2)
  JobDescriptionsAndStaffing jobDescriptions = JobDescriptionsAndStaffing();

  /// 5.3. Workplace Descriptions — contains 1+× per user category.
  @SectionId('WPDE-WORK-LST')
  @SectionIdPattern('WPDE-WORK-xxx')
  @Min(1)
  @Comment('per user category')
  @SerializationOrder(3)
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
@StandardReferences(
  [
    'McKinsey 7-S — organizational design',
    'Galbraith Star Model — organization design',
    'BABOK v3 — future-state analysis',
  ],
  'Defines the target organizational structure required by the new system — '
  'teams, departments, responsibilities, and communication channels in the '
  'future state.',
)
@SectionId('NORGS')
class NewOrganizationStructure {
  /// Overview of the target organization structure.
  @ContentHelp('Describe the vision for the new organization structure: '
      'design principles, key structural changes, governance model, '
      'decision-making framework, and expected benefits.')
  @SerializationOrder(0)
  TextSection overview = TextSection();

  /// 5.1.1. Changes from Current Structure.
  @SerializationOrder(1)
  ChangesFromCurrentStructure changesFromCurrentStructure =
      ChangesFromCurrentStructure();

  /// 5.1.2. Organizational Transition Timeline.
  @SerializationOrder(2)
  OrganizationalTransitionTimeline transitionTimeline =
      OrganizationalTransitionTimeline();
}

/// 5.1.1. Changes from Current Structure.
///
/// Explicitly documents what changes from the current organization structure.
/// Identifies affected departments, changed reporting lines, and new roles
/// that need to be created. Provides traceability from current to future state.
@StandardReferences(
  [
    'BABOK v3 — future-state analysis',
    'McKinsey 7-S — organizational design',
  ],
  'Captures the explicit delta between the current and target organization '
  'structures — affected departments, changed reporting lines, and new roles — '
  'providing current-to-future-state traceability.',
)
@SectionId('OCCHG')
class ChangesFromCurrentStructure {
  // -------------------------------------------------------------------------
  // Change Overview
  // -------------------------------------------------------------------------
  @SectionId('OCCHG-OVER')
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
  @SerializationOrder(0)
  String? overviewContent;

  /// Detailed description of structural changes.
  @ContentHelp('Provide narrative description of the organizational '
      'transformation: what the current structure looks like, what the '
      'target structure will be, and how the transition will be managed.')
  @SerializationOrder(1)
  TextSection changeNarrative = TextSection();

  /// Organization chart comparison (current vs future).
  @ContentHelp('Visual representation comparing current and target '
      'organization structures - attach or embed org chart diagrams.')
  @SerializationOrder(2)
  DiagramSection orgChartComparison = DiagramSection();

  /// Contains 0+× OrganizationalChange.
  @StandardReferences(
    [
      'BABOK v3 — future-state analysis',
      'PMBOK — resource management (organizational roles & responsibilities)',
    ],
    'The set of discrete structural changes that together transform the '
    'current organization into the target structure.',
  )
  @SectionId('ORGCE-ITEM-LST')
  @SectionIdPattern('ORGCE-ITEM-xxx')
  @ContentHelp('Add one entry per discrete organizational change — each with '
      'its current state, target state, rationale, impact, and transition.')
  @SerializationOrder(3)
  List<OrganizationalChangeEntry> items = [];
}

/// An organizational change entry (form).
///
/// Documents a specific structural change including current state, target
/// state, rationale, impact assessment, and transition requirements.
@StandardReferences(
  [
    'BABOK v3 — future-state analysis',
    'PROSCI ADKAR — change management',
  ],
  'Documents a single structural change — its current state, target state, '
  'rationale, impact, transition, and risks — as one unit of the '
  'organizational transformation.',
)
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
  @SerializationOrder(0)
  String? content;

  /// Change identification details.
  @SerializationOrder(1)
  OrgChangeIdentification identification = OrgChangeIdentification();

  /// Scope of the change.
  @SerializationOrder(2)
  OrgChangeScope scope = OrgChangeScope();

  /// Rationale for the change.
  @SerializationOrder(3)
  OrgChangeRationale rationale = OrgChangeRationale();

  /// Impact assessment.
  @SerializationOrder(4)
  OrgChangeImpact impact = OrgChangeImpact();

  /// Transition planning.
  @SerializationOrder(5)
  OrgChangeTransition transition = OrgChangeTransition();

  /// Risks and mitigations.
  @StandardReferences(
    [
      'ISO 31000 — risk management',
      'PROSCI ADKAR — change management',
    ],
    'The risks arising from this structural change together with their '
    'mitigations and dependencies.',
  )
  @SectionId('OCRSK-RISK-LST')
  @SectionIdPattern('OCRSK-RISK-xxx')
  @ContentHelp('Add one entry per risk associated with this change, each with '
      'its mitigation and any dependencies on other changes.')
  @SerializationOrder(6)
  List<OrgChangeRisks> risks = [];

  /// Status tracking.
  @SerializationOrder(7)
  OrgChangeStatus status = OrgChangeStatus();
}

/// Identification details for organizational change.
@StandardReferences(
  ['BABOK v3 — future-state analysis'],
  'Categorizes and prioritizes a structural change for tracking and '
  'sequencing within the transformation.',
)
@SectionId('OCIDN')
class OrgChangeIdentification {
  @Form([
    Field('changeCategory', String, 'Change Category',
        hint: 'Reporting Lines, Team Structure, Department, Division'),
    Field('priority', String, 'Priority',
        hint: 'Critical, High, Medium, Low'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope for organizational change.
@StandardReferences(
  [
    'BABOK v3 — future-state analysis',
    'PMBOK — resource management (organizational roles & responsibilities)',
  ],
  'Bounds the affected area of a structural change and quantifies the '
  'current-to-target shift, including the headcount delta.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Rationale for organizational change.
@StandardReferences(
  [
    'BABOK v3 — future-state analysis',
    'ISO 21500 — project management (governance & process tailoring)',
  ],
  'States the business justification and expected benefits for a structural '
  'change and how it aligns to the new system and processes.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Impact assessment for organizational change.
@StandardReferences(
  [
    'PROSCI ADKAR — change management',
    'PMBOK — resource management (organizational roles & responsibilities)',
  ],
  'Assesses the disruption a structural change causes to roles, people, '
  'reporting lines, decision rights, communication, and collaboration.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Transition for organizational change.
@StandardReferences(
  [
    'Kotter 8-Step — leading change',
    'ISO/IEC/IEEE 29148 §6 — transition',
  ],
  'Plans how a structural change is brought into effect — timing, ownership, '
  'and the communication, training, HR, and IT actions it requires.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Risks for organizational change.
@StandardReferences(
  [
    'ISO 31000 — risk management',
    'PROSCI ADKAR — change management',
  ],
  'A single risk for a structural change paired with its mitigation and '
  'dependencies.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Status for organizational change.
@StandardReferences(
  [
    'ISO 21500 — project management (governance & process tailoring)',
    'PMBOK — resource management (organizational roles & responsibilities)',
  ],
  'Tracks the approval and implementation status of a structural change, '
  'including who must approve it.',
)
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
  @SerializationOrder(0)
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
@StandardReferences(
  [
    'PROSCI ADKAR — change management',
    'Kotter 8-Step — leading change',
    'ISO/IEC/IEEE 29148 §6 — transition',
  ],
  'Defines when organizational changes take effect, how the transition is '
  'managed, and the phasing, milestones, and risks that govern cutover.',
)
@SectionId('OTTML')
class OrganizationalTransitionTimeline {
  /// Overview of the transition approach and guiding principles.
  @SerializationOrder(0)
  TransitionOverview overview = TransitionOverview();

  /// Transition phases with milestones and durations.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — transition',
      'PMBOK — schedule management',
    ],
    'The ordered set of distinct transition phases, each with its own '
    'timeline, activities, and milestones.',
  )
  @SectionId('TRPHE-PHAS-LST')
  @SectionIdPattern('TRPHE-PHAS-xxx')
  @ContentHelp('Add one entry per transition phase, in sequence — e.g. '
      'Preparation, Pilot, Rollout, Stabilization, Closure.')
  @SerializationOrder(1)
  List<TransitionPhaseEntry> phases = [];

  /// Key transition milestones and decision gates.
  @StandardReferences(
    [
      'PMBOK — schedule management',
      'ITIL 4 — service transition',
    ],
    'The set of key transition milestones and decision gates that mark '
    'progress and Go/No-Go points across the transition.',
  )
  @SectionId('TRMIL-MILE-LST')
  @SectionIdPattern('TRMIL-MILE-xxx')
  @ContentHelp('Add one entry per transition milestone or decision gate — '
      'e.g. checkpoints, go-live, closure.')
  @SerializationOrder(2)
  List<TransitionMilestoneEntry> milestones = [];

  /// Change readiness assessment approach.
  @SerializationOrder(3)
  ChangeReadinessAssessment changeReadiness = ChangeReadinessAssessment();

  /// Communication plan for the transition.
  @SerializationOrder(4)
  TransitionCommunicationPlan communicationPlan = TransitionCommunicationPlan();

  /// Support structure during transition.
  @SerializationOrder(5)
  TransitionSupportStructure supportStructure = TransitionSupportStructure();

  /// Success metrics and measurement approach.
  @SerializationOrder(6)
  TransitionSuccessMetrics successMetrics = TransitionSuccessMetrics();

  /// Risks specific to the organizational transition.
  @StandardReferences(
    ['ISO 31000 — risk management'],
    'The set of risks specific to the organizational transition, each with '
    'its likelihood, impact, and mitigation.',
  )
  @SectionId('TRRS-TRAN-LST')
  @SectionIdPattern('TRRS-TRAN-xxx')
  @ContentHelp('Add one entry per transition-specific risk, with its '
      'likelihood, impact, and planned mitigation.')
  @SerializationOrder(7)
  List<TransitionRiskEntry> transitionRisks = [];
}

/// Overview of the organizational transition approach.
@StandardReferences(
  [
    'PROSCI ADKAR — change management',
    'Kotter 8-Step — leading change',
  ],
  'Captures the overall transition approach, change-management methodology, '
  'and the high-level start and completion dates for the transition.',
)
@SectionId('TROVW')
class TransitionOverview {
  @Form([
    Field('transitionApproach', String,
        'Transition Approach — phased, big-bang, parallel run, pilot',
        hint: 'Overall approach to the transition: phased rollout, big-bang '
            'cutover, parallel run, or pilot-first'),
    Field('changeManagementMethodology', String,
        'Change Management Methodology — PROSCI ADKAR, Kotter, Lewin, custom',
        hint: 'The change-management framework guiding the transition: PROSCI '
            'ADKAR, Kotter 8-step, Lewin, or a custom methodology'),
    Field('transitionStartDate', String, 'Transition Start Date',
        hint: 'The date on which the organizational transition begins'),
    Field('targetCompletionDate', String, 'Target Completion Date',
        hint: 'The target date by which the transition should be fully '
            'complete'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Timeline and cutover planning.
  @SerializationOrder(1)
  TransitionOverviewTimeline timeline = TransitionOverviewTimeline();

  /// Governance and change ownership.
  @SerializationOrder(2)
  TransitionOverviewGovernance governance = TransitionOverviewGovernance();
}

/// Timeline and cutover planning.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — transition',
    'ITIL 4 — service transition',
  ],
  'Defines the overall transition duration, parallel-operation window, '
  'cutover strategy, and rollback plan for the go-live moment.',
)
@SectionId('TROML')
class TransitionOverviewTimeline {
  @Form([
    Field('transitionDuration', String,
        'Overall Transition Duration — weeks/months',
        hint: 'Total expected duration of the transition, expressed in weeks '
            'or months'),
    Field('parallelOperationPeriod', String,
        'Parallel Operation Period — duration of overlap with old processes',
        hint: 'How long old and new processes run side by side before the old '
            'ones are retired'),
    Field('cutoverStrategy', String,
        'Cutover Strategy — planning for go-live moment',
        hint: 'How the go-live moment is planned and executed, including '
            'sequencing and timing of the switchover'),
    Field('rollbackPlan', String,
        'Rollback Plan — fallback if transition fails',
        hint: 'The fallback procedure to revert to the prior state if the '
            'transition fails'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance and change ownership.
@StandardReferences(
  [
    'PMBOK — resource management',
    'PROSCI ADKAR — change management',
  ],
  'Establishes the transition governance structure, the accountable '
  'transition owner, and the change champions who drive adoption.',
)
@SectionId('TROGV')
class TransitionOverviewGovernance {
  @Form([
    Field('transitionGovernance', String,
        'Transition Governance — oversight structure and decision authority',
        hint: 'The oversight structure and where decision authority sits for '
            'the transition'),
    Field('transitionOwner', String,
        'Transition Owner — accountable person/role',
        hint: 'The single person or role accountable for the overall '
            'transition'),
    Field('changeChampions', String,
        'Change Champions — advocates in each affected area',
        hint: 'The advocates within each affected area who champion the change '
            'and support adoption'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A transition phase entry (form).
///
/// Defines a distinct phase in the organizational transition sequence.
@StandardReferences(
  [
    'PMBOK — schedule management',
    'PROSCI ADKAR — change management',
  ],
  'Represents one distinct phase in the organizational transition sequence, '
  'with its identification, activities, stakeholders, and exit criteria.',
)
@SectionId('TRPHE')
class TransitionPhaseEntry {
  /// Phase identification and timeline.
  @SerializationOrder(0)
  TransitionPhaseIdentification identification =
      TransitionPhaseIdentification();

  /// Activities and deliverables for this phase.
  @StandardReferences(
    ['PMBOK — schedule management'],
    'The set of activities and deliverables to be completed within this '
    'transition phase.',
  )
  @SectionId('TPACT-ACTI-LST')
  @SectionIdPattern('TPACT-ACTI-xxx')
  @ContentHelp('Add one entry per group of activities and deliverables for '
      'this phase — e.g. training, communication, system, and process work.')
  @SerializationOrder(1)
  List<TransitionPhaseActivities> activities = [];

  /// Stakeholder engagement for this phase.
  @StandardReferences(
    ['PMBOK — resource management'],
    'The stakeholders engaged in this transition phase and how they are '
    'involved.',
  )
  @SectionId('TPSTK-STAK-LST')
  @SectionIdPattern('TPSTK-STAK-xxx')
  @ContentHelp('Add one entry per stakeholder group engaged in this phase, '
      'with the engagement and feedback approach for each.')
  @SerializationOrder(2)
  List<TransitionPhaseStakeholders> stakeholders = [];

  /// Exit criteria and phase completion conditions.
  @SerializationOrder(3)
  TransitionPhaseExitCriteria exitCriteria = TransitionPhaseExitCriteria();
}

/// Phase identification and timeline.
@StandardReferences(
  [
    'PMBOK — schedule management',
    'ISO/IEC/IEEE 29148 §6 — transition',
  ],
  'Identifies a transition phase by ID, name, type, and owner as the anchor '
  'for its timeline and scope.',
)
@SectionId('TPIDN')
class TransitionPhaseIdentification {
  @Form([
    Field('phaseId', String, 'Phase ID (e.g., PH-01)', required: true,
        hint: 'Unique identifier for the phase, e.g. PH-01'),
    Field('phaseName', String, 'Phase Name', required: true,
        hint: 'Short descriptive name for the transition phase'),
    Field('phaseType', String,
        'Phase Type — Preparation, Pilot, Rollout, Stabilization, Closure',
        hint: 'The kind of phase: Preparation, Pilot, Rollout, '
            'Stabilization, or Closure'),
    Field('phaseOwner', String, 'Phase Owner',
        hint: 'The person or role accountable for delivering this phase'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Timeline and sequencing details.
    @SerializationOrder(1)
    TransitionPhaseIdentificationTimeline timeline =
            TransitionPhaseIdentificationTimeline();

    /// Scope of organizational impact.
    @SerializationOrder(2)
    TransitionPhaseIdentificationScope scope =
            TransitionPhaseIdentificationScope();
}

/// Timeline and sequencing details.
@StandardReferences(
  [
    'PMBOK — schedule management',
    'ISO/IEC/IEEE 29148 §6 — transition',
  ],
  'Captures the start/end dates, duration, and sequencing dependencies that '
  'place this phase within the transition timeline.',
)
@SectionId('TPIML')
class TransitionPhaseIdentificationTimeline {
    @Form([
        Field('startDate', String, 'Start Date',
            hint: 'The planned start date for this phase'),
        Field('endDate', String, 'End Date',
            hint: 'The planned end date for this phase'),
        Field('duration', String, 'Duration — weeks',
            hint: 'Expected duration of the phase, expressed in weeks'),
        Field('precedingPhase', String, 'Preceding Phase — phase ID',
            hint: 'The phase ID that must complete before this phase begins'),
        Field('dependsOnMilestone', String, 'Depends on Milestone — milestone ID',
            hint: 'The milestone ID this phase depends on before it can start'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Scope of organizational impact.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — transition',
    'PMBOK — resource management',
  ],
  'Defines the organizational scope of this phase — which locations, '
  'departments, and how many users it affects.',
)
@SectionId('TPISC')
class TransitionPhaseIdentificationScope {
    @Form([
        Field('affectedLocations', String,
                'Affected Locations — sites/regions in scope',
            hint: 'The sites or regions that fall within the scope of this '
                'phase'),
        Field('affectedDepartments', String,
                'Affected Departments — organizational units',
            hint: 'The organizational units or departments impacted by this '
                'phase'),
        Field('affectedUserCount', int, 'Affected User Count',
            hint: 'The number of users affected by this phase'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Activities and deliverables for a transition phase.
@StandardReferences(
  [
    'PMBOK — schedule management',
    'PROSCI ADKAR — change management',
  ],
  'Enumerates the activities and deliverables — key tasks, training, '
  'communication, system, and process work — produced within a transition '
  'phase.',
)
@SectionId('TPACT')
class TransitionPhaseActivities {
  @Form([
    Field('keyActivities', String,
        'Key Activities — main tasks to complete in this phase',
        hint: 'The main tasks that must be completed during this phase'),
    Field('trainingActivities', String,
        'Training Activities — training to deliver',
        hint: 'The training sessions or materials to be delivered in this '
            'phase'),
    Field('communicationActivities', String,
        'Communication Activities — announcements, meetings',
        hint: 'The announcements, meetings, and other communications planned '
            'for this phase'),
    Field('systemActivities', String,
        'System Activities — technical preparations, data migration',
        hint: 'The technical preparations and data-migration work required in '
            'this phase'),
    Field('processActivities', String,
        'Process Activities — process rollout, SOP distribution',
        hint: 'The process rollout and SOP distribution work for this phase'),
    Field('deliverables', String, 'Phase Deliverables — outputs to produce',
        hint: 'The concrete outputs the phase must produce'),
    Field('resourceRequirements', String,
        'Resource Requirements — people, budget, tools',
        hint: 'The people, budget, and tools required to execute the phase'),
    Field('externalSupport', String,
        'External Support — consultants, vendors needed',
        hint: 'Any consultants or vendors needed to support this phase'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Stakeholder engagement for a transition phase.
@StandardReferences(
  [
    'PMBOK — resource management',
    'PROSCI ADKAR — change management',
  ],
  'Describes how stakeholders are engaged in a transition phase — who is '
  'involved, how feedback flows, and how issues escalate.',
)
@SectionId('TPSTK')
class TransitionPhaseStakeholders {
  @Form([
    Field('primaryStakeholders', String,
        'Primary Stakeholders — directly impacted groups',
        hint: 'The groups directly impacted by this phase'),
    Field('engagementApproach', String,
        'Engagement Approach — how stakeholders are involved',
        hint: 'How stakeholders are involved and engaged during this phase'),
    Field('feedbackMechanism', String,
        'Feedback Mechanism — how input is collected',
        hint: 'The mechanism used to collect stakeholder input during this '
            'phase'),
    Field('escalationPath', String,
        'Escalation Path — for issues during this phase',
        hint: 'The path for escalating issues that arise during this phase'),
    Field('sponsorInvolvement', String,
        'Sponsor Involvement — executive actions needed',
        hint: 'The executive sponsor actions needed to support this phase'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Exit criteria for a transition phase.
@StandardReferences(
  [
    'PMBOK — schedule management',
    'ITIL 4 — service transition',
  ],
  'Specifies the exit criteria, sign-offs, and quality gates that must be '
  'met before a transition phase is considered complete.',
)
@SectionId('TPEXT')
class TransitionPhaseExitCriteria {
  @Form([
    Field('exitCriteria', String,
        'Exit Criteria — conditions to complete phase',
        hint: 'The conditions that must be satisfied for the phase to be '
            'considered complete'),
    Field('signOffRequired', String,
        'Sign-Off Required — who must approve phase completion',
        hint: 'Who must approve phase completion before moving on'),
    Field('qualityGates', String, 'Quality Gates — checks to pass',
        hint: 'The quality checks that must pass before the phase can close'),
    Field('successIndicators', String,
        'Success Indicators — measurable outcomes',
        hint: 'The measurable outcomes that indicate the phase succeeded'),
    Field('knownIssuesResolution', String,
        'Known Issues Resolution — outstanding items allowed',
        hint: 'Which outstanding items are permitted to remain unresolved at '
            'phase exit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A transition milestone entry (form).
@StandardReferences(
  [
    'PMBOK — schedule management',
    'ITIL 4 — service transition',
  ],
  'Represents a single transition milestone or decision gate, with its type, '
  'target/actual dates, and status.',
)
@SectionId('TRMIL')
class TransitionMilestoneEntry {
  @Form([
    Field('milestoneId', String, 'Milestone ID (e.g., MS-01)', required: true,
        hint: 'Unique identifier for the milestone, e.g. MS-01'),
    Field('milestoneName', String, 'Milestone Name', required: true,
        hint: 'Short descriptive name for the milestone'),
    Field('milestoneType', String,
        'Milestone Type — Decision Gate, Checkpoint, Go-Live, Closure',
        hint: 'The kind of milestone: Decision Gate, Checkpoint, Go-Live, or '
            'Closure'),
    Field('targetDate', String, 'Target Date',
        hint: 'The planned date by which the milestone should be achieved'),
    Field('actualDate', String, 'Actual Date — when achieved',
        hint: 'The actual date on which the milestone was achieved'),
    Field('status', String,
        'Status — Planned, On Track, At Risk, Delayed, Achieved',
        hint: 'Current status of the milestone: Planned, On Track, At Risk, '
            'Delayed, or Achieved'),
    Field('description', String, 'Description',
        hint: 'A short description of what the milestone represents'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Deliverables and decisioning.
    @SerializationOrder(1)
    TransitionMilestoneEntryGovernance governance =
            TransitionMilestoneEntryGovernance();

    /// Dependencies and criticality.
    @SerializationOrder(2)
    TransitionMilestoneEntryDependencies dependencies =
            TransitionMilestoneEntryDependencies();

    /// Recognition activities.
    @SerializationOrder(3)
    TransitionMilestoneEntryRecognition recognition =
            TransitionMilestoneEntryRecognition();
}

/// Deliverables and decisioning.
@StandardReferences(
  [
    'PMBOK — schedule management',
    'PMBOK — resource management',
  ],
  'Captures the deliverables required for a milestone and the Go/No-Go '
  'decision and decision owner attached to it.',
)
@SectionId('TMLGV')
class TransitionMilestoneEntryGovernance {
    @Form([
        Field('deliverables', String, 'Deliverables — required for milestone',
            hint: 'The deliverables that must be in place for the milestone to '
                'be reached'),
        Field('decisionRequired', String,
                'Decision Required — Go/No-Go decision at this point',
            hint: 'The Go/No-Go or other decision that must be made at this '
                'milestone'),
        Field('decisionOwner', String, 'Decision Owner',
            hint: 'The person or role accountable for making the decision at '
                'this milestone'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Dependencies and criticality.
@StandardReferences(
  [
    'PMBOK — schedule management',
    'ISO 31000 — risk management',
  ],
  'Records the phases and prior milestones a milestone depends on and its '
  'criticality to the transition.',
)
@SectionId('TMED')
class TransitionMilestoneEntryDependencies {
    @Form([
        Field('dependsOnPhases', String,
                'Depends on Phases — phases that must complete',
            hint: 'The phases that must complete before this milestone can be '
                'achieved'),
        Field('dependsOnMilestones', String,
                'Depends on Milestones — prior milestones required',
            hint: 'The prior milestones required before this milestone can be '
                'reached'),
        Field('criticality', String, 'Criticality — High, Medium, Low',
            hint: 'How critical this milestone is to the transition: High, '
                'Medium, or Low'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Recognition activities.
@StandardReferences(
  [
    'PROSCI ADKAR — change management',
    'Kotter 8-Step — leading change',
  ],
  'Captures the recognition and celebration activities used to reinforce '
  'achievement of a transition milestone.',
)
@SectionId('TMER')
class TransitionMilestoneEntryRecognition {
    @Form([
        Field('celebrationActivities', String,
                'Celebration Activities — recognition for achieving milestone',
            hint: 'The recognition or celebration activities planned for '
                'achieving this milestone'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Change readiness assessment approach.
@StandardReferences(
  [
    'PROSCI ADKAR — change readiness assessment',
    'Kotter 8-Step — leading change',
  ],
  'Defines how the organization gauges whether stakeholder groups are ready '
  'to adopt the change before the transition proceeds.',
)
@SectionId('CHREAS')
class ChangeReadinessAssessment {
  /// Overview of readiness assessment approach.
  @SerializationOrder(0)
  ChangeReadinessOverview overview = ChangeReadinessOverview();

  /// Readiness criteria per stakeholder group.
  @StandardReferences(
    [
      'PROSCI ADKAR — change readiness assessment',
      'ITIL 4 — organizational change management',
    ],
    'The set of readiness criteria evaluated per stakeholder group to judge '
    'their preparedness for the change.',
  )
  @SectionId('RDRCE-READ-LST')
  @SectionIdPattern('RDRCE-READ-xxx')
  @ContentHelp('Add one entry per stakeholder group whose readiness is being '
      'assessed, capturing ADKAR levels, resistance factors, and status.')
  @SerializationOrder(1)
  List<ReadinessCriteriaEntry> readinessCriteria = [];
}

/// Overview of change readiness assessment.
@StandardReferences(
  [
    'PROSCI ADKAR — change readiness assessment',
    'Kotter 8-Step — leading change',
  ],
  'Summarizes the overall method, cadence, ownership, and thresholds used to '
  'assess organizational readiness for the change.',
)
@SectionId('CHREOV')
class ChangeReadinessOverview {
  @Form([
    Field('assessmentMethod', String,
        'Assessment Method — surveys, interviews, observations, readiness gates',
        hint: 'The techniques used to assess readiness: surveys, interviews, '
            'observations, or formal readiness gates'),
    Field('assessmentFrequency', String,
        'Assessment Frequency — how often readiness is evaluated',
        hint: 'How frequently readiness is re-evaluated, e.g. weekly, per '
            'phase, or at each milestone gate'),
    Field('readinessOwner', String,
        'Readiness Owner — who tracks readiness',
        hint: 'The person or role accountable for tracking and reporting '
            'change readiness'),
    Field('minimumReadinessLevel', String,
        'Minimum Readiness Level — threshold to proceed',
        hint: 'The minimum readiness score or level required before the '
            'transition is allowed to proceed'),
    Field('escalationTrigger', String,
        'Escalation Trigger — when to escalate readiness concerns',
        hint: 'The conditions under which readiness concerns must be '
            'escalated to leadership'),
    Field('readinessTooling', String,
        'Readiness Tooling — tools/surveys used for assessment',
        hint: 'The tools, survey platforms, or instruments used to collect '
            'and analyze readiness data'),
    Field('adkarFocus', String,
        'ADKAR Focus — Awareness, Desire, Knowledge, Ability, Reinforcement status',
        hint: 'Which ADKAR dimensions (Awareness, Desire, Knowledge, Ability, '
            'Reinforcement) are the current focus and their status'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Readiness criteria entry (form).
@StandardReferences(
  [
    'PROSCI ADKAR — change readiness assessment',
    'Kotter 8-Step — leading change',
  ],
  'Captures the readiness of a single stakeholder group across the ADKAR '
  'dimensions together with resistance factors and mitigation actions.',
)
@SectionId('RDRCE')
class ReadinessCriteriaEntry {
  @Form([
    Field('stakeholderGroup', String, 'Stakeholder Group', required: true,
        hint: 'The stakeholder group whose change readiness this entry '
            'assesses'),
    Field('awarenessLevel', String,
        'Awareness Level — understanding of change (1-5)',
        hint: 'The group\'s level of awareness of the change, rated 1 (none) '
            'to 5 (full understanding)'),
    Field('desireLevel', String, 'Desire Level — willingness to participate (1-5)',
        hint: 'The group\'s willingness to participate in the change, rated 1 '
            '(resistant) to 5 (fully committed)'),
    Field('knowledgeLevel', String,
        'Knowledge Level — skills/knowledge acquired (1-5)',
        hint: 'The skills and knowledge the group has acquired to operate in '
            'the new state, rated 1 to 5'),
    Field('abilityLevel', String,
        'Ability Level — demonstrated capability (1-5)',
        hint: 'The group\'s demonstrated capability to perform in the new '
            'state, rated 1 to 5'),
    Field('reinforcementNeeded', String,
        'Reinforcement Needed — support to sustain change',
        hint: 'The reinforcement or ongoing support required to sustain the '
            'change for this group'),
    Field('resistanceFactors', String,
        'Resistance Factors — barriers to adoption',
        hint: 'The specific barriers, concerns, or sources of resistance to '
            'adoption within this group'),
    Field('mitigationActions', String,
        'Mitigation Actions — how to address resistance',
        hint: 'The actions planned to address the identified resistance '
            'factors for this group'),
    Field('readinessStatus', String,
        'Readiness Status — Ready, Needs Work, At Risk, Not Ready',
        hint: 'The overall readiness status of the group: Ready, Needs Work, '
            'At Risk, or Not Ready'),
    Field('assessmentDate', String, 'Last Assessment Date',
        hint: 'The date on which this group\'s readiness was last assessed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication plan for the transition.
@StandardReferences(
  [
    'PMBOK — communications management',
    'PROSCI ADKAR — change communications',
  ],
  'Defines how the transition is communicated to stakeholders — the strategy, '
  'the specific events, and the channels through which messages flow.',
)
@SectionId('TRCOPL')
class TransitionCommunicationPlan {
  /// Communication strategy overview.
  @SerializationOrder(0)
  TransitionCommunicationStrategy strategy = TransitionCommunicationStrategy();

  /// Specific communication events/activities.
  @StandardReferences(
    [
      'PMBOK — communications management',
      'PROSCI ADKAR — change communications',
    ],
    'The scheduled communication events and activities that deliver the '
    'transition messages to their target audiences.',
  )
  @SectionId('COEV-COMM-LST')
  @SectionIdPattern('COEV-COMM-xxx')
  @ContentHelp('Add one entry per planned communication event, such as a town '
      'hall, announcement, workshop, or newsletter.')
  @SerializationOrder(1)
  List<CommunicationEventEntry> communicationEvents = [];

  /// Communication channels and their use.
  @StandardReferences(
    [
      'PMBOK — communications management',
      'PROSCI ADKAR — change communications',
    ],
    'The communication channels used during the transition and how each is '
    'owned, accessed, and applied.',
  )
  @SectionId('TRCOCH-CHAN-LST')
  @SectionIdPattern('TRCOCH-CHAN-xxx')
  @ContentHelp('Add one entry per communication channel describing its '
      'purpose, ownership, and accessibility.')
  @SerializationOrder(2)
  List<TransitionCommunicationChannels> channels = [];
}

/// Communication strategy overview.
@StandardReferences(
  [
    'PMBOK — communications management',
    'PROSCI ADKAR — change communications',
  ],
  'Captures the overall communication approach, key messages, ownership, and '
  'cadence that govern all transition communications.',
)
@SectionId('TRCOST')
class TransitionCommunicationStrategy {
  @Form([
    Field('communicationStrategy', String,
        'Communication Strategy — overall approach',
        hint: 'The overarching approach to transition communications, '
            'including tone, principles, and objectives'),
    Field('keyMessages', String,
        'Key Messages — core messages to convey throughout',
        hint: 'The core messages to be reinforced consistently across all '
            'communications throughout the transition'),
    Field('messagingOwner', String,
        'Messaging Owner — who controls/approves communications',
        hint: 'The person or role that owns and approves the content of all '
            'transition communications'),
    Field('feedbackChannels', String,
        'Feedback Channels — how stakeholders can respond',
        hint: 'The mechanisms through which stakeholders can ask questions, '
            'raise concerns, or provide feedback'),
    Field('communicationCadence', String,
        'Communication Cadence — frequency of updates',
        hint: 'How often transition updates are issued, e.g. weekly digests '
            'or per-milestone bulletins'),
    Field('brandingGuidelines', String,
        'Branding Guidelines — visual identity for change',
        hint: 'The visual identity, naming, and branding standards applied to '
            'change communications'),
    Field('languageRequirements', String,
        'Language Requirements — languages/translations needed',
        hint: 'The languages and translation requirements needed to reach all '
            'affected audiences'),
    Field('accessibilityRequirements', String,
        'Accessibility Requirements — accessibility considerations',
        hint: 'The accessibility considerations (formats, captions, screen '
            'reader support) communications must meet'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication event entry (form).
@StandardReferences(
  [
    'PMBOK — communications management',
    'PROSCI ADKAR — change communications',
  ],
  'Describes a single planned communication event — its type, audience, '
  'timing, and the messages it delivers.',
)
@SectionId('COEV')
class CommunicationEventEntry {
  @Form([
    Field('eventId', String, 'Event ID', required: true,
        hint: 'A unique identifier for this communication event'),
    Field('eventName', String, 'Event Name', required: true,
        hint: 'A short descriptive name for this communication event'),
    Field('eventType', String,
        'Event Type — Announcement, Town Hall, Email, Workshop, Newsletter',
        hint: 'The kind of communication event: Announcement, Town Hall, '
            'Email, Workshop, Newsletter, etc.'),
    Field('targetAudience', String, 'Target Audience',
        hint: 'The stakeholder group or audience this event is intended to '
            'reach'),
    Field('scheduledDate', String, 'Scheduled Date',
        hint: 'The date on which this communication event is scheduled to '
            'occur'),
    Field('phase', String, 'Phase — which transition phase',
        hint: 'The transition phase during which this event takes place'),
    Field('keyMessages', String, 'Key Messages — specific to this event',
        hint: 'The specific messages this particular event is designed to '
            'convey'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Delivery ownership.
    @SerializationOrder(1)
    CommunicationEventEntryDelivery delivery = CommunicationEventEntryDelivery();

    /// Follow-up and measurement.
    @SerializationOrder(2)
    CommunicationEventEntryOutcome outcome = CommunicationEventEntryOutcome();
}

/// Delivery ownership.
@StandardReferences(
  [
    'PMBOK — communications management',
    'PROSCI ADKAR — change communications',
  ],
  'Records who prepares, approves, and delivers a communication event, and '
  'through which channel and materials.',
)
@SectionId('CEED')
class CommunicationEventEntryDelivery {
    @Form([
        Field('channel', String, 'Channel — delivery method',
            hint: 'The channel or medium through which this event is '
                'delivered, e.g. email, intranet, in-person'),
        Field('owner', String, 'Owner — who prepares/delivers',
            hint: 'The person or role responsible for preparing and '
                'delivering this event'),
        Field('approver', String, 'Approver — who approves content',
            hint: 'The person or role who must approve the content before it '
                'is delivered'),
        Field('materialsRequired', String, 'Materials Required — slides, scripts, etc.',
            hint: 'The materials needed to deliver this event, such as slides, '
                'scripts, handouts, or recordings'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Follow-up and measurement.
@StandardReferences(
  [
    'PMBOK — communications management',
    'PROSCI — adoption metrics',
  ],
  'Captures the follow-up actions, effectiveness measures, and delivery '
  'status for a communication event.',
)
@SectionId('CEEO')
class CommunicationEventEntryOutcome {
    @Form([
        Field('followUpActions', String, 'Follow-Up Actions — after event',
            hint: 'The actions to be taken after the event, such as sharing '
                'recordings or following up on questions'),
        Field('successMeasure', String, 'Success Measure — how effectiveness is measured',
            hint: 'How the effectiveness of this communication event is '
                'measured, e.g. attendance, survey scores, reach'),
        Field('status', String, 'Status — Planned, In Preparation, Delivered, Cancelled',
            hint: 'The current status of this event: Planned, In Preparation, '
                'Delivered, or Cancelled'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Communication channels definition.
@StandardReferences(
  [
    'PMBOK — communications management',
    'PROSCI ADKAR — change communications',
  ],
  'Defines a communication channel used during the transition — its purpose, '
  'urgency, ownership, and who can access it.',
)
@SectionId('TRCOCH')
class TransitionCommunicationChannels {
  @Form([
    Field('primaryChannels', String,
        'Primary Channels — main communication methods',
        hint: 'The main channels used for routine transition communications, '
            'e.g. email, intranet, team meetings'),
    Field('urgentChannels', String,
        'Urgent Channels — for time-sensitive communications',
        hint: 'The channels reserved for time-sensitive or urgent '
            'communications, e.g. SMS, alerts, calls'),
    Field('feedbackChannels', String,
        'Feedback Channels — for two-way communication',
        hint: 'The channels enabling two-way communication so stakeholders '
            'can respond and provide feedback'),
    Field('documentationRepository', String,
        'Documentation Repository — where materials are stored',
        hint: 'The location where communication materials and documentation '
            'are stored and accessed'),
    Field('channelOwnership', String,
        'Channel Ownership — who manages each channel',
        hint: 'Who owns and manages each communication channel'),
    Field('channelAccessibility', String,
        'Channel Accessibility — who can access what',
        hint: 'Which audiences can access each channel and any access '
            'restrictions that apply'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Support structure during transition.
@StandardReferences(
  [
    'ITIL 4 — service transition / early life support',
    'PMBOK — resource management',
  ],
  'Defines the support organization that helps users through the transition — '
  'its model, the resources provided, and how issues escalate.',
)
@SectionId('TRSUST')
class TransitionSupportStructure {
  /// Support organization overview.
  @SerializationOrder(0)
  TransitionSupportOverview overview = TransitionSupportOverview();

  /// Support resources available.
  @StandardReferences(
    [
      'ITIL 4 — service transition / early life support',
      'PMBOK — resource management',
    ],
    'The support resources made available during the transition, such as help '
    'desks, super users, floor walkers, and coaches.',
  )
  @SectionId('TRSPRE-SUPP-LST')
  @SectionIdPattern('TRSPRE-SUPP-xxx')
  @ContentHelp('Add one entry per support resource describing its type, '
      'coverage, capacity, and ownership.')
  @SerializationOrder(1)
  List<TransitionSupportResourceEntry> supportResources = [];

  /// Escalation paths for support.
  @StandardReferences(
    [
      'ITIL 4 — service transition / early life support',
      'PMBOK — resource management',
    ],
    'The escalation paths that route support issues from first-line help '
    'through to specialist, expert, and management levels.',
  )
  @SectionId('TRESPA-ESCA-LST')
  @SectionIdPattern('TRESPA-ESCA-xxx')
  @ContentHelp('Add one entry per escalation path describing its levels, '
      'criteria, and response-time targets.')
  @SerializationOrder(2)
  List<TransitionEscalationPaths> escalationPaths = [];
}

/// Support structure overview.
@StandardReferences(
  [
    'ITIL 4 — service transition / early life support',
    'PMBOK — resource management',
  ],
  'Summarizes the support model, hours, channels, capacity, and duration that '
  'frame how users are supported through the transition.',
)
@SectionId('TRSUOV')
class TransitionSupportOverview {
  @Form([
    Field('supportModel', String,
        'Support Model — tiered support, buddy system, floor walkers',
        hint: 'How transition support is organized: tiered help desk, buddy '
            'system, floor walkers, super-users'),
    Field('supportHours', String,
        'Support Hours — when support is available',
        hint: 'The hours and days during which transition support is '
            'available to users'),
    Field('supportChannels', String,
        'Support Channels — help desk, chat, in-person, phone',
        hint: 'The channels through which users can reach support: help desk, '
            'chat, in-person, phone'),
    Field('supportCapacity', String,
        'Support Capacity — expected volumes and staffing',
        hint: 'The expected support volumes and the staffing provisioned to '
            'meet them'),
    Field('supportDuration', String,
        'Support Duration — how long enhanced support lasts',
        hint: 'How long the period of enhanced transition support will last '
            'before scaling back'),
    Field('transitionToBAU', String,
        'Transition to BAU — when/how support moves to business-as-usual',
        hint: 'When and how support hands over to the business-as-usual '
            'support organization'),
    Field('knowledgeBase', String,
        'Knowledge Base — self-service resources available',
        hint: 'The self-service resources (FAQs, guides, knowledge base) '
            'available to users'),
    Field('superUserNetwork', String,
        'Super-User Network — local experts in each area',
        hint: 'The network of local super-users or champions who provide '
            'peer support in each area'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Support resource entry (form).
@StandardReferences(
  [
    'ITIL 4 — service transition / early life support',
    'PMBOK — resource management',
  ],
  'Describes a single support resource provided during the transition — its '
  'type, coverage, capacity, skills, and ownership.',
)
@SectionId('TRSPRE')
class TransitionSupportResourceEntry {
  @Form([
    Field('resourceType', String,
        'Resource Type — Help Desk, Super User, Floor Walker, Coach, FAQ',
        required: true,
        hint: 'The kind of support resource: Help Desk, Super User, Floor '
            'Walker, Coach, FAQ, etc.'),
    Field('resourceName', String, 'Resource Name/Title',
        hint: 'The name or title of this support resource'),
    Field('availabilityPeriod', String,
        'Availability Period — start/end dates',
        hint: 'The start and end dates during which this resource is '
            'available'),
    Field('coverage', String, 'Coverage — locations/departments covered',
        hint: 'The locations, departments, or groups this resource covers'),
    Field('contactInfo', String, 'Contact Info — how to reach',
        hint: 'How users can reach this support resource'),
    Field('capacity', String, 'Capacity — how many can be supported',
        hint: 'The number of users or volume this resource can support'),
    Field('skills', String, 'Skills — expertise areas',
        hint: 'The areas of expertise or skills this resource provides'),
    Field('owner', String, 'Owner — who manages this resource',
        hint: 'The person or role that manages this support resource'),
    Field('costCenter', String, 'Cost Center — budget allocation',
        hint: 'The cost center or budget against which this resource is '
            'allocated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Escalation paths for transition support.
@StandardReferences(
  [
    'ITIL 4 — service transition / early life support',
    'PMBOK — resource management',
  ],
  'Defines how support issues escalate through tiered levels, with criteria '
  'and response-time targets for each.',
)
@SectionId('TRESPA')
class TransitionEscalationPaths {
  @Form([
    Field('level1', String, 'Level 1 — first-line support',
        hint: 'The first-line support tier that handles initial user '
            'requests'),
    Field('level2', String, 'Level 2 — specialist support',
        hint: 'The specialist support tier that issues escalate to from '
            'first-line'),
    Field('level3', String, 'Level 3 — expert/vendor support',
        hint: 'The expert or vendor support tier for issues that specialists '
            'cannot resolve'),
    Field('emergencyContact', String, 'Emergency Contact — critical issues',
        hint: 'The contact to use for critical or emergency issues requiring '
            'immediate attention'),
    Field('escalationCriteria', String,
        'Escalation Criteria — when to escalate',
        hint: 'The conditions that determine when an issue must be escalated '
            'to the next level'),
    Field('responseTimeTargets', String,
        'Response Time Targets — per severity level',
        hint: 'The target response times for each severity level of support '
            'issue'),
    Field('managementEscalation', String,
        'Management Escalation — for organizational issues',
        hint: 'The path for escalating organizational or non-technical issues '
            'to management'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Success metrics for the transition.
@StandardReferences(
  [
    'PMBOK — monitoring & controlling',
    'PROSCI — adoption metrics',
  ],
  'Defines how the success of the transition is measured — the overall '
  'measurement approach and the specific metrics tracked.',
)
@SectionId('TRSUME')
class TransitionSuccessMetrics {
  /// Metrics overview.
  @SerializationOrder(0)
  TransitionMetricsOverview overview = TransitionMetricsOverview();

  /// Specific success metrics.
  @StandardReferences(
    [
      'PMBOK — monitoring & controlling',
      'ISO/IEC 25010 — quality measurement',
    ],
    'The specific success metrics tracked to evaluate adoption, performance, '
    'quality, and satisfaction during the transition.',
  )
  @SectionId('TRME-METR-LST')
  @SectionIdPattern('TRME-METR-xxx')
  @ContentHelp('Add one entry per success metric describing its category, '
      'measurement method, baseline, and target.')
  @SerializationOrder(1)
  List<TransitionMetricEntry> metrics = [];
}

/// Metrics overview.
@StandardReferences(
  [
    'PMBOK — monitoring & controlling',
    'PROSCI — adoption metrics',
  ],
  'Summarizes how transition success is measured and reported — the approach, '
  'cadence, ownership, audience, and baseline.',
)
@SectionId('TRMEOV')
class TransitionMetricsOverview {
  @Form([
    Field('measurementApproach', String,
        'Measurement Approach — how success is evaluated',
        hint: 'The overall approach to evaluating transition success, '
            'including data collection and analysis methods'),
    Field('reportingCadence', String,
        'Reporting Cadence — how often metrics are reported',
        hint: 'How often metrics are compiled and reported, e.g. weekly, '
            'monthly, per milestone'),
    Field('reportingOwner', String,
        'Reporting Owner — who produces reports',
        hint: 'The person or role responsible for producing the metrics '
            'reports'),
    Field('reportingAudience', String,
        'Reporting Audience — who receives reports',
        hint: 'The audience who receives the metrics reports, e.g. steering '
            'committee, sponsors, teams'),
    Field('dashboardLocation', String,
        'Dashboard Location — where metrics are visible',
        hint: 'Where the metrics dashboard or reports can be viewed'),
    Field('baselinePeriod', String,
        'Baseline Period — when baseline was established',
        hint: 'The period during which the baseline values were established '
            'for comparison'),
    Field('targetAchievementDate', String,
        'Target Achievement Date — when targets should be met',
        hint: 'The date by which the metric targets are expected to be met'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Transition metric entry (form).
@StandardReferences(
  [
    'PMBOK — monitoring & controlling',
    'ISO/IEC 25010 — quality measurement',
  ],
  'Describes a single transition success metric — its category, measurement '
  'method, baseline, and target value.',
)
@SectionId('TRME')
class TransitionMetricEntry {
  @Form([
    Field('metricId', String, 'Metric ID', required: true,
        hint: 'A unique identifier for this success metric'),
    Field('metricName', String, 'Metric Name', required: true,
        hint: 'A short descriptive name for this success metric'),
    Field('category', String,
        'Category — Adoption, Performance, Quality, Satisfaction, Efficiency',
        hint: 'The category of this metric: Adoption, Performance, Quality, '
            'Satisfaction, or Efficiency'),
    Field('description', String, 'Description',
        hint: 'A description of what this metric measures and why it matters'),
    Field('measurementMethod', String, 'Measurement Method',
        hint: 'How this metric is measured, including the data source and '
            'calculation'),
    Field('baseline', String, 'Baseline Value',
        hint: 'The baseline value of this metric before the transition, used '
            'as a comparison point'),
    Field('target', String, 'Target Value',
        hint: 'The target value this metric should reach to indicate success'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Measurement operations.
    @SerializationOrder(1)
    TransitionMetricEntryOperations operations = TransitionMetricEntryOperations();

    /// Current status.
    @SerializationOrder(2)
    TransitionMetricEntryStatus statusSection = TransitionMetricEntryStatus();
}

/// Measurement operations.
@StandardReferences(
  [
    'PMBOK — monitoring & controlling',
    'ISO/IEC 25010 — quality measurement',
  ],
  'Captures the operational details of measuring a metric — its threshold, '
  'current value, frequency, data source, and owner.',
)
@SectionId('TMEO')
class TransitionMetricEntryOperations {
    @Form([
        Field('threshold', String, 'Threshold — minimum acceptable',
            hint: 'The minimum acceptable value for this metric below which '
                'action is required'),
        Field('currentValue', String, 'Current Value',
            hint: 'The most recently measured value of this metric'),
        Field('measurementFrequency', String, 'Measurement Frequency',
            hint: 'How often this metric is measured, e.g. daily, weekly, '
                'monthly'),
        Field('dataSource', String, 'Data Source',
            hint: 'The system or source from which this metric\'s data is '
                'collected'),
        Field('owner', String, 'Owner',
            hint: 'The person or role responsible for measuring and reporting '
                'this metric'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Current status.
@StandardReferences(
  [
    'PMBOK — monitoring & controlling',
    'PROSCI — adoption metrics',
  ],
  'Records the current status and trend of a metric against its target.',
)
@SectionId('TMES')
class TransitionMetricEntryStatus {
    @Form([
        Field('status', String, 'Status — On Track, At Risk, Below Target, Achieved',
            hint: 'The current status of this metric: On Track, At Risk, '
                'Below Target, or Achieved'),
        Field('trend', String, 'Trend — Improving, Stable, Declining',
            hint: 'The direction this metric is trending: Improving, Stable, '
                'or Declining'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Transition risk entry (form).
@StandardReferences(
  [
    'ISO 31000 — risk management',
    'PMBOK — risk management',
  ],
  'Describes a single transition risk — its category and nature — as the '
  'header for its assessment and response details.',
)
@SectionId('TRRS')
class TransitionRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID', required: true,
        hint: 'A unique identifier for this transition risk'),
    Field('riskName', String, 'Risk Name', required: true,
        hint: 'A short descriptive name for this transition risk'),
    Field('riskCategory', String,
        'Risk Category — Resistance, Capacity, Timing, Resources, Dependencies',
        hint: 'The category of this risk: Resistance, Capacity, Timing, '
            'Resources, or Dependencies'),
    Field('description', String, 'Description',
        hint: 'A description of the risk, including what could go wrong and '
            'its potential consequences'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Risk assessment and exposure details.
    @SerializationOrder(1)
    TransitionRiskEntryAssessment assessment = TransitionRiskEntryAssessment();

    /// Mitigation ownership and monitoring.
    @SerializationOrder(2)
    TransitionRiskEntryResponse response = TransitionRiskEntryResponse();
}

/// Risk assessment and exposure details.
@StandardReferences(
  [
    'ISO 31000 — risk management',
    'PMBOK — risk management',
  ],
  'Captures the probability, impact, affected phases, and early-warning '
  'indicators that quantify a transition risk\'s exposure.',
)
@SectionId('TREA')
class TransitionRiskEntryAssessment {
    @Form([
        Field('probability', String, 'Probability — Low, Medium, High',
            hint: 'The likelihood that this risk materializes: Low, Medium, '
                'or High'),
        Field('impact', String, 'Impact — Low, Medium, High',
            hint: 'The severity of the consequences if this risk occurs: Low, '
                'Medium, or High'),
        Field('affectedPhases', String, 'Affected Phases',
            hint: 'The transition phases that would be affected if this risk '
                'materializes'),
        Field('earlyWarningIndicator', String, 'Early Warning Indicator',
            hint: 'The signals or indicators that would warn the team this '
                'risk is emerging'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Mitigation ownership and monitoring.
@StandardReferences(
  [
    'ISO 31000 — risk management',
    'PMBOK — risk management',
  ],
  'Records how a transition risk is responded to — its mitigation strategy, '
  'contingency plan, owner, and current status.',
)
@SectionId('TRER')
class TransitionRiskEntryResponse {
    @Form([
        Field('mitigationStrategy', String, 'Mitigation Strategy',
            hint: 'The planned actions to reduce the probability or impact of '
                'this risk'),
        Field('contingencyPlan', String, 'Contingency Plan',
            hint: 'The fallback plan to execute if this risk materializes '
                'despite mitigation'),
        Field('owner', String, 'Risk Owner',
            hint: 'The person or role accountable for managing and monitoring '
                'this risk'),
        Field('status', String, 'Status — Active, Mitigated, Realized, Closed',
            hint: 'The current status of this risk: Active, Mitigated, '
                'Realized, or Closed'),
    ])
    @SerializationOrder(0)
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
@StandardReferences(
  [
    'O*NET — occupational job analysis (tasks, skills, knowledge)',
    'SHRM — HR best practices (job design, staffing, workforce planning)',
    'CIPD — competency frameworks and people management',
  ],
  'Documents the new, changed, and removed roles that result from introducing '
  'the system, together with the staffing plan and competency framework needed '
  'to fill them.',
)
@SectionId('JDAS')
class JobDescriptionsAndStaffing {
  /// Overview of the job architecture and role design approach.
  @SerializationOrder(0)
  JobDescriptionsOverview overview = JobDescriptionsOverview();

  /// 5.2.1. New Roles — contains 0+× New Role.
  @StandardReferences(
    ['O*NET — occupational job analysis (tasks, skills, knowledge)'],
    'The set of brand-new roles the system introduces, each defined through '
    'job analysis (tasks, skills, and knowledge requirements).',
  )
  @SectionId('NWROL-NEWR-LST')
  @SectionIdPattern('NWROL-NEWR-xxx')
  @ContentHelp('Add one entry per new role being created.')
  @SerializationOrder(1)
  List<NewRoleEntry> newRoles = [];

  /// 5.2.2. Changed Roles — contains 0+× Changed Role.
  @StandardReferences(
    ['SHRM — HR best practices (job design, staffing, workforce planning)'],
    'The set of existing roles whose responsibilities, skills, or grading '
    'change as a result of the system introduction.',
  )
  @SectionId('CHAROL-CHAN-LST')
  @SectionIdPattern('CHAROL-CHAN-xxx')
  @ContentHelp('Add one entry per existing role whose definition changes.')
  @SerializationOrder(2)
  List<ChangedRoleEntry> changedRoles = [];

  /// 5.2.3. Removed Roles — contains 0+× role being eliminated.
  @StandardReferences(
    ['SHRM — HR best practices (job design, staffing, workforce planning)'],
    'The set of roles being eliminated by the system introduction, with the '
    'rationale and people-impact for each.',
  )
  @SectionId('REMROL-REMO-LST')
  @SectionIdPattern('REMROL-REMO-xxx')
  @ContentHelp('Add one entry per role being eliminated.')
  @SerializationOrder(3)
  List<RemovedRoleEntry> removedRoles = [];

  /// 5.2.4. Staffing Plan.
  @SerializationOrder(4)
  StaffingPlan staffingPlan = StaffingPlan();

  /// 5.2.5. Competency Framework.
  @SerializationOrder(5)
  CompetencyFramework competencyFramework = CompetencyFramework();
}

/// Overview of job descriptions and staffing approach.
@StandardReferences(
  [
    'SHRM — HR best practices (job design, staffing, workforce planning)',
    'CIPD — competency frameworks and people management',
  ],
  'Summarises the overall approach to designing roles — the job architecture, '
  'competency model, grading, net headcount impact, and the HR/legal '
  'considerations that govern the role changes.',
)
@SectionId('JODEOV')
class JobDescriptionsOverview {
  @Form([
    Field('roleDesignApproach', String,
        'Role Design Approach — methodology for defining roles',
        hint: 'Methodology used to define and structure roles'),
    Field('jobArchitectureModel', String,
        'Job Architecture Model — job families, levels, career paths',
        hint: 'Job families, levels, and career paths'),
    Field('competencyModel', String,
        'Competency Model — framework for defining skills/competencies',
        hint: 'Framework used to define skills and competencies'),
    Field('gradingStructure', String,
        'Grading Structure — how roles are graded/leveled',
        hint: 'How roles are graded or leveled'),
    Field('totalRoleImpact', String,
        'Total Role Impact — summary of new/changed/removed roles',
        hint: 'Summary count of new, changed, and removed roles'),
    Field('totalFteChange', String,
        'Total FTE Change — net headcount impact',
        hint: 'Net headcount impact across all role changes'),
    Field('hrPartner', String, 'HR Partner — HR contact for role changes',
        hint: 'HR contact responsible for these role changes'),
    Field('unionConsiderations', String,
        'Union/Works Council Considerations — labor relations impact',
        hint: 'Labor relations and works council impact'),
    Field('legalRequirements', String,
        'Legal Requirements — employment law considerations',
        hint: 'Employment law considerations affecting role changes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 5.2.4. Staffing Plan.
@StandardReferences(
  [
    'PMBOK — resource management (acquire/develop/manage team)',
    'SHRM — HR best practices (job design, staffing, workforce planning)',
  ],
  'Sets out how the roles will actually be staffed — the sourcing strategy, '
  'budget, individual position entries, and recruitment timeline.',
)
@SectionId('STPL')
class StaffingPlan {
  /// Staffing plan overview.
  @SerializationOrder(0)
  StaffingPlanOverview overview = StaffingPlanOverview();

  /// Budget details.
  @SerializationOrder(1)
  StaffingBudget budget = StaffingBudget();

  /// Contains 0+× Staffing entry.
  @StandardReferences(
    ['PMBOK — resource management (acquire/develop/manage team)'],
    'The set of individual staffing positions to be filled, each with its '
    'role, capacity, sourcing, budget, and timeline.',
  )
  @SectionId('STFE-ITEM-LST')
  @SectionIdPattern('STFE-ITEM-xxx')
  @ContentHelp('Add one entry per staffing position to be filled.')
  @SerializationOrder(2)
  List<StaffingEntry> items = [];

  /// Recruitment timeline.
  @SerializationOrder(3)
  RecruitmentTimeline recruitmentTimeline = RecruitmentTimeline();
}

/// Staffing plan overview.
@StandardReferences(
  [
    'SHRM — HR best practices (job design, staffing, workforce planning)',
    'PMBOK — resource management (acquire/develop/manage team)',
  ],
  'Describes the overall staffing strategy — how positions will be sourced, '
  'selected, onboarded, and retained, plus geographic, diversity, and '
  'compliance constraints.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Staffing budget details.
@StandardReferences(
  ['PMBOK — cost/resource budgeting'],
  'Captures the overall financial envelope for staffing — total budget, '
  'salary and benefits costs, and the currency in which they are expressed.',
)
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
  @SerializationOrder(0)
  String? content;

  /// Recruitment and enablement cost categories.
  @SerializationOrder(1)
  StaffingBudgetAllocations allocations = StaffingBudgetAllocations();

  /// Budget ownership and approval controls.
  @SerializationOrder(2)
  StaffingBudgetGovernance governance = StaffingBudgetGovernance();
}

/// Recruitment and enablement cost categories.
@StandardReferences(
  ['PMBOK — cost/resource budgeting'],
  'Breaks the staffing budget into the cost categories that enable hiring — '
  'recruitment, training, relocation, and contingency.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Budget ownership and approval controls.
@StandardReferences(
  [
    'PMBOK — cost/resource budgeting',
    'RACI — responsibility assignment',
  ],
  'Defines who owns the staffing budget, who must approve spend, and how the '
  'budget aligns to the fiscal timeline.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// A staffing entry (form).
///
/// Represents one staffing position including role, competency requirements,
/// sourcing method, budget, timeline, and approval status.
@StandardReferences(
  [
    'O*NET — occupational job analysis (tasks, skills, knowledge)',
    'PMBOK — resource management (acquire/develop/manage team)',
  ],
  'Represents a single staffing position to be filled, capturing its role, '
  'organization, capacity, recruitment workflow, and ownership.',
)
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
  @SerializationOrder(0)
  String? content;

  /// Organization and employment placement.
  @SerializationOrder(1)
  StaffingEntryOrganization organization = StaffingEntryOrganization();

  /// Capacity and competency requirements.
  @SerializationOrder(2)
  StaffingEntryCapacity capacity = StaffingEntryCapacity();

  /// Recruitment workflow and urgency.
  @SerializationOrder(3)
  StaffingEntryRecruitment recruitment = StaffingEntryRecruitment();

  /// Ownership and compensation details.
  @SerializationOrder(4)
  StaffingEntryOwnership ownership = StaffingEntryOwnership();
}

/// Organization and employment placement.
@StandardReferences(
  ['SHRM — HR best practices (job design, staffing, workforce planning)'],
  'Places the staffing position within the organization — the department, '
  'location, and employment type under which it is hired.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Capacity and competency requirements.
@StandardReferences(
  [
    'O*NET — occupational job analysis (tasks, skills, knowledge)',
    'ISO 9001 — competence, awareness & resourcing',
  ],
  'Quantifies the capacity needed for the position — FTE, headcount, required '
  'skills, and whether it backfills an existing person.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Recruitment workflow and urgency.
@StandardReferences(
  ['SHRM — talent acquisition / time-to-fill'],
  'Tracks the recruitment workflow for the position — approval, sourcing '
  'method, current status, target start date, and urgency.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Ownership and compensation details.
@StandardReferences(
  [
    'RACI — responsibility assignment',
    'SHRM — HR best practices (job design, staffing, workforce planning)',
  ],
  'Identifies who owns the position — hiring manager and recruiter — together '
  'with its salary range and any special notes.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// Recruitment timeline.
@StandardReferences(
  [
    'SHRM — talent acquisition / time-to-fill',
    'PMBOK — resource management (acquire/develop/manage team)',
  ],
  'Lays out the schedule for hiring — start and end dates, critical hires, '
  'hiring and onboarding waves, lead-time assumptions, and external '
  'dependencies that gate fill dates.',
)
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
  @SerializationOrder(0)
  String? content;
}

/// 5.2.5. Competency Framework.
@StandardReferences(
  [
    'CIPD — competency frameworks',
    'ISO 9001 §7.2 — competence',
  ],
  'Defines the competency framework that underpins hiring and development — '
  'the core, technical, and leadership competencies the target organization '
  'requires.',
)
@SectionId('COFR')
class CompetencyFramework {
  /// Framework overview.
  @SerializationOrder(0)
  CompetencyFrameworkOverview overview = CompetencyFrameworkOverview();

  /// Core competencies required across all roles.
  @StandardReferences(
    ['CIPD — competency frameworks'],
    'The set of core competencies expected of every role across the target '
    'organization.',
  )
  @SectionId('COMPE-CORE-LST')
  @SectionIdPattern('COMPE-CORE-xxx')
  @ContentHelp('Add one entry per core competency required across all roles.')
  @SerializationOrder(1)
  List<CompetencyEntry> coreCompetencies = [];

  /// Technical/functional competencies by role family.
  @StandardReferences(
    [
      'CIPD — competency frameworks',
      'ISO 9001 §7.2 — competence',
    ],
    'The set of technical or functional competencies specific to particular '
    'role families.',
  )
  @SectionId('COMPE-TECH-LST')
  @SectionIdPattern('COMPE-TECH-xxx')
  @ContentHelp('Add one entry per technical or functional competency.')
  @SerializationOrder(2)
  List<CompetencyEntry> technicalCompetencies = [];

  /// Leadership competencies for management roles.
  @StandardReferences(
    ['CIPD — competency frameworks'],
    'The set of leadership competencies expected of management and supervisory '
    'roles.',
  )
  @SectionId('COMPE-LEAD-LST')
  @SectionIdPattern('COMPE-LEAD-xxx')
  @ContentHelp('Add one entry per leadership competency for management roles.')
  @SerializationOrder(3)
  List<CompetencyEntry> leadershipCompetencies = [];
}

/// Competency framework overview.
@StandardReferences(
  [
    'CIPD — competency frameworks',
    'ISO 9001 §7.2 — competence',
  ],
  'Summarises the competency framework — its purpose, the model it is based '
  'on, the proficiency scale, how competencies are assessed, and how gaps are '
  'developed.',
)
@SectionId('COFROV')
class CompetencyFrameworkOverview {
  @Form([
    Field('frameworkPurpose', String,
        'Framework Purpose — how competencies guide hiring/development',
        hint: 'How the framework guides hiring and development'),
    Field('competencyModel', String,
        'Competency Model — model name/source (SHRM, custom, etc.)',
        hint: 'Model name or source — e.g. SHRM, CIPD, custom'),
    Field('proficiencyLevels', String,
        'Proficiency Levels — scale used (1-5, Novice to Expert, etc.)',
        hint: 'Scale used — e.g. 1-5, Novice to Expert'),
    Field('assessmentMethod', String,
        'Assessment Method — how competencies are measured',
        hint: 'How competencies are measured'),
    Field('developmentApproach', String,
        'Development Approach — how gaps are addressed',
        hint: 'How competency gaps are addressed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A competency entry (form).
@StandardReferences(
  [
    'CIPD — competency frameworks',
    'ISO 9001 §7.2 — competence',
  ],
  'Represents a single competency in the framework, defining its category, '
  'behavioral indicators, proficiency levels, applicable roles, and how it is '
  'developed and assessed.',
)
@SectionId('COMPE')
class CompetencyEntry {
  @Form([
    Field('competencyId', String, 'Competency ID',
        hint: 'Unique identifier for this competency', required: true),
    Field('competencyName', String, 'Competency Name',
        hint: 'Short name of the competency', required: true),
    Field('category', String,
        'Category — Core, Technical, Leadership, Behavioral',
        hint: 'Core / Technical / Leadership / Behavioral'),
    Field('description', String, 'Description',
        hint: 'What this competency means in practice'),
    Field('behavioralIndicators', String,
        'Behavioral Indicators — observable behaviors',
        hint: 'Observable behaviors that demonstrate the competency'),
    Field('proficiencyLevels', String,
        'Proficiency Levels — what each level looks like',
        hint: 'What each proficiency level looks like'),
    Field('applicableRoles', String,
        'Applicable Roles — which roles need this competency',
        hint: 'Which roles require this competency'),
    Field('requiredLevel', String,
        'Required Level — minimum proficiency for the role',
        hint: 'Minimum proficiency level required for the role'),
    Field('developmentResources', String,
        'Development Resources — training, coaching, experiences',
        hint: 'Training, coaching, or experiences that build it'),
    Field('assessmentTools', String,
        'Assessment Tools — tests, interviews, simulations',
        hint: 'Tests, interviews, or simulations used to assess it'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A new role entry (form).
///
/// Comprehensive new role definition following HR job analysis best practices.
/// Includes competencies, responsibilities, system access, and success metrics.
@StandardReferences(
  [
    'O*NET — occupational job analysis (tasks, skills, knowledge)',
    'SHRM — HR best practices (job design, role definition)',
  ],
  'Defines a brand-new role end to end — identity, organizational placement, '
  'responsibilities, qualifications, access, performance and onboarding.',
)
@SectionId('NRE')
class NewRoleEntry {
  /// Role identification and overview.
  @SerializationOrder(0)
  NewRoleIdentification identification = NewRoleIdentification();

  /// Role positioning in organization.
  @SerializationOrder(1)
  NewRoleOrganization organization = NewRoleOrganization();

  /// Responsibilities breakdown.
  @SerializationOrder(2)
  NewRoleResponsibilities responsibilities = NewRoleResponsibilities();

  /// Required competencies and qualifications.
  @SerializationOrder(3)
  NewRoleQualifications qualifications = NewRoleQualifications();

  /// System access and tools.
  @SerializationOrder(4)
  NewRoleSystemAccess systemAccess = NewRoleSystemAccess();

  /// Performance and success metrics.
  @SerializationOrder(5)
  NewRolePerformance performance = NewRolePerformance();

  /// Onboarding and development.
  @SerializationOrder(6)
  NewRoleOnboarding onboarding = NewRoleOnboarding();
}

/// New role identification.
@StandardReferences(
  [
    'SHRM — HR best practices (job design, role definition)',
    'O*NET — occupational job analysis (tasks, skills, knowledge)',
  ],
  'Identifies the new role and records the business case that justifies '
  'creating it.',
)
@SectionId('NEROID')
class NewRoleIdentification {
  @Form([
    Field('roleId', String, 'Role ID (e.g., NR-001)', required: true,
        hint: 'Unique identifier for this new role'),
    Field('roleTitle', String, 'Role Title', required: true,
        hint: 'Official job title for the role'),
    Field('roleFamily', String, 'Job Family',
        hint: 'Broader job family or category this role belongs to'),
    Field('jobLevel', String, 'Job Level/Grade',
        hint: 'Seniority level or pay grade'),
    Field('rolePurpose', String, 'Role Purpose — why this role exists',
        hint: 'Core mission the role fulfils'),
    Field('roleJustification', String,
        'Role Justification — business case for new role',
        hint: 'Why creating this role is needed now'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When the role becomes active'),
    Field('roleStatus', String,
        'Role Status — draft, approved, posted, filled',
        hint: 'Current lifecycle stage of the role'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// New role organizational positioning.
@StandardReferences(
  [
    'ISO 21500 — project management (organizational roles)',
    'PMBOK — resource management (roles & responsibilities)',
  ],
  'Places the role within the organization — its reporting lines, team, '
  'location and the network of people it works with.',
)
@SectionId('NEROOR')
class NewRoleOrganization {
  @Form([
    Field('department', String, 'Department',
        hint: 'Department the role sits in'),
    Field('division', String, 'Division/Business Unit',
        hint: 'Division or business unit'),
    Field('team', String, 'Team — immediate team',
        hint: 'Immediate team the role joins'),
    Field('location', String, 'Location — primary work location',
        hint: 'Primary physical or office location'),
    Field('workModel', String,
        'Work Model — on-site, remote, hybrid',
        hint: 'On-site, remote, or hybrid arrangement'),
    Field('reportsTo', String, 'Reports To — direct manager title',
        hint: 'Title of the direct manager'),
    Field('directReports', String, 'Direct Reports — roles reporting to this',
        hint: 'Roles that report into this one'),
    Field('matrixRelationships', String,
        'Matrix Relationships — dotted-line reporting',
        hint: 'Dotted-line or matrix reporting links'),
    Field('keyStakeholders', String,
        'Key Stakeholders — internal/external contacts',
        hint: 'Important internal/external contacts'),
    Field('collaborationScope', String,
        'Collaboration Scope — teams/departments interacted with',
        hint: 'Teams or departments regularly interacted with'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// New role responsibilities.
@StandardReferences(
  [
    'O*NET — occupational job analysis (tasks, skills, knowledge)',
    'RACI — responsibility assignment',
  ],
  'Breaks the role down into its primary and secondary responsibilities and '
  'the decision-making authority that comes with it.',
)
@SectionId('NERORE')
class NewRoleResponsibilities {
  /// Primary responsibilities (key accountabilities).
  @StandardReferences(
    ['O*NET — task statements (core duties)'],
    'The set of primary duties that define the core accountabilities of the '
    'role.',
  )
  @SectionId('RSPDT-PRIM-LST')
  @SectionIdPattern('RSPDT-PRIM-xxx')
  @ContentHelp('Add one entry per primary responsibility.')
  @SerializationOrder(0)
  List<ResponsibilityDetailEntry> primaryResponsibilities = [];

  /// Secondary responsibilities (supporting duties).
  @StandardReferences(
    ['O*NET — supplemental task statements'],
    'Supporting duties the role performs beyond its core accountabilities.',
  )
  @SectionId('RSPDT-SECO-LST')
  @SectionIdPattern('RSPDT-SECO-xxx')
  @ContentHelp('Add one entry per secondary responsibility.')
  @SerializationOrder(1)
  List<ResponsibilityDetailEntry> secondaryResponsibilities = [];

  /// Decision-making authority.
  @SerializationOrder(2)
  RoleDecisionAuthority decisionAuthority = RoleDecisionAuthority();
}

/// Detailed responsibility entry (form).
@StandardReferences(
  [
    'O*NET — task statements (tasks, deliverables)',
    'RACI — responsibility assignment',
  ],
  'Describes a single responsibility in detail — its deliverables, time '
  'allocation, frequency and quality standards.',
)
@SectionId('RSPDT')
class ResponsibilityDetailEntry {
  @Form([
    Field('responsibilityId', String, 'Responsibility ID',
        hint: 'Unique identifier for this responsibility'),
    Field('responsibility', String, 'Responsibility', required: true,
        hint: 'Short statement of the duty'),
    Field('description', String, 'Description — detailed explanation',
        hint: 'Detailed explanation of what is done'),
    Field('timeAllocation', String,
        'Time Allocation — percentage of time spent',
        hint: 'Approximate share of working time'),
    Field('frequency', String, 'Frequency — daily, weekly, monthly, ad-hoc',
        hint: 'How often the duty is performed'),
    Field('deliverables', String, 'Deliverables — outputs expected',
        hint: 'Tangible outputs the duty produces'),
    Field('qualityStandards', String, 'Quality Standards — success criteria',
        hint: 'Criteria that define success'),
    Field('relatedProcesses', String,
        'Related Processes — business processes involved',
        hint: 'Business processes this duty touches'),
    Field('toolsUsed', String, 'Tools Used — systems/applications',
        hint: 'Systems or applications used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Role decision-making authority.
@StandardReferences(
  [
    'RACI — accountable/responsible',
    'PMBOK — resource management (roles & responsibilities)',
  ],
  'Defines the decisions the role can make on its own — approval, budget, '
  'hiring, policy and contract authority — and when escalation is required.',
)
@SectionId('RODEAU')
class RoleDecisionAuthority {
  @Form([
    Field('approvalAuthority', String,
        'Approval Authority — what can be approved without escalation',
        hint: 'What may be approved without escalating'),
    Field('budgetAuthority', String,
        'Budget Authority — spending limits',
        hint: 'Spending limits the role can authorize'),
    Field('hiringAuthority', String,
        'Hiring Authority — ability to hire/terminate',
        hint: 'Authority to hire or terminate staff'),
    Field('policyAuthority', String,
        'Policy Authority — ability to set/change policies',
        hint: 'Authority to set or change policies'),
    Field('contractAuthority', String,
        'Contract Authority — signing limits for agreements',
        hint: 'Signing limits for agreements'),
    Field('exceptionAuthority', String,
        'Exception Authority — ability to grant exceptions',
        hint: 'Authority to grant exceptions to rules'),
    Field('escalationRequired', String,
        'Escalation Required — when must escalate',
        hint: 'Situations that must be escalated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// New role qualifications and competencies.
@StandardReferences(
  [
    'ISO 9001 §7.2 — competence',
    'CIPD — competency frameworks and people management',
  ],
  'Captures what a candidate must bring to the role — education, experience, '
  'credentials, screening and the required competencies.',
)
@SectionId('NEROQU')
class NewRoleQualifications {
  @Form([
    Field('education', String,
        'Education — minimum education requirement',
        hint: 'Minimum education level required'),
    Field('preferredEducation', String,
        'Preferred Education — ideal education',
        hint: 'Ideal but non-mandatory education'),
    Field('experience', String,
        'Experience — years and type of experience required',
        hint: 'Years and type of experience required'),
    Field('preferredExperience', String,
        'Preferred Experience — ideal experience',
        hint: 'Ideal but non-mandatory experience'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Credential and mobility requirements.
  @SerializationOrder(1)
  NewRoleQualificationsCredentials credentials =
      NewRoleQualificationsCredentials();

  /// Screening and clearance requirements.
  @SerializationOrder(2)
  NewRoleQualificationsScreening screening =
      NewRoleQualificationsScreening();

  /// Contains 0+× required competency.
  @StandardReferences(
    [
      'CIPD — competency frameworks and people management',
      'ISO 9001 §7.2 — competence',
    ],
    'The competencies a candidate must demonstrate to be qualified for the '
    'role.',
  )
  @SectionId('ROLCP-REQU-LST')
  @SectionIdPattern('ROLCP-REQU-xxx')
  @ContentHelp('Add one entry per required competency.')
  @SerializationOrder(3)
  List<RoleCompetencyEntry> requiredCompetencies = [];
}

/// Credential and mobility requirements.
@StandardReferences(
  [
    'ISO 9001 §7.2 — competence',
    'SHRM — HR best practices (job design, role definition)',
  ],
  'Records the formal credentials, language abilities and travel/mobility '
  'requirements a candidate must hold.',
)
@SectionId('NRQC')
class NewRoleQualificationsCredentials {
  @Form([
    Field('certifications', String,
        'Certifications — required certifications',
        hint: 'Certifications that are required'),
    Field('licensure', String,
        'Licensure — professional licenses needed',
        hint: 'Professional licenses needed'),
    Field('languageRequirements', String,
        'Language Requirements — languages needed',
        hint: 'Languages the role requires'),
    Field('travelRequirements', String,
        'Travel Requirements — percentage, destinations',
        hint: 'Expected travel frequency and destinations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Screening and clearance requirements.
@StandardReferences(
  [
    'SHRM — HR best practices (job design, role definition)',
    'ISO/IEC 27001 — access control / least privilege',
  ],
  'Captures pre-employment screening needs — physical requirements, '
  'background checks and any security clearance.',
)
@SectionId('NRQS')
class NewRoleQualificationsScreening {
  @Form([
    Field('physicalRequirements', String,
        'Physical Requirements — if applicable',
        hint: 'Physical demands of the role, if any'),
    Field('backgroundCheck', String,
        'Background Check — type required',
        hint: 'Type of background check required'),
    Field('securityClearance', String,
        'Security Clearance — if required',
        hint: 'Security clearance level needed, if any'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Role competency entry (form).
@StandardReferences(
  [
    'CIPD — competency frameworks and people management',
    'ISO 9001 §7.2 — competence',
  ],
  'Describes a single competency the role needs — its type, required and '
  'preferred proficiency, and how it is assessed.',
)
@SectionId('ROLCP')
class RoleCompetencyEntry {
  @Form([
    Field('competencyId', String, 'Competency ID',
        hint: 'Unique identifier for this competency'),
    Field('competencyName', String, 'Competency Name', required: true,
        hint: 'Name of the competency'),
    Field('competencyType', String,
        'Competency Type — Core, Technical, Leadership',
        hint: 'Category such as core, technical or leadership'),
    Field('requiredLevel', String,
        'Required Level — minimum proficiency',
        hint: 'Minimum proficiency that is mandatory'),
    Field('preferredLevel', String, 'Preferred Level — ideal proficiency',
        hint: 'Ideal proficiency level'),
    Field('assessmentMethod', String,
        'Assessment Method — how evaluated during hiring',
        hint: 'How the competency is evaluated when hiring'),
    Field('developmentPriority', String,
        'Development Priority — if gap exists',
        hint: 'Priority for developing this if a gap exists'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// New role system access requirements.
@StandardReferences(
  [
    'ISO/IEC 27001 — access control / least privilege',
    'SHRM — HR best practices (job design, role definition)',
  ],
  'Specifies the systems, data and tools the role needs and how that access '
  'is granted, applying least-privilege principles.',
)
@SectionId('NRSA')
class NewRoleSystemAccess {
  @Form([
    Field('primarySystems', String,
        'Primary Systems — main applications used daily',
        hint: 'Main applications used every day'),
    Field('secondarySystems', String,
        'Secondary Systems — occasionally used applications',
        hint: 'Applications used occasionally'),
    Field('dataAccess', String,
        'Data Access — data domains accessible',
        hint: 'Data domains the role may access'),
    Field('securityRole', String,
        'Security Role — role in access control system',
        hint: 'Role assigned in the access control system'),
    Field('privilegedAccess', String,
        'Privileged Access — admin/elevated rights needed',
        hint: 'Any admin or elevated rights required'),
    Field('mobileAccess', String,
        'Mobile Access — mobile app/device requirements',
        hint: 'Mobile app or device requirements'),
    Field('remoteAccessTools', String,
        'Remote Access Tools — VPN, virtual desktop',
        hint: 'Remote access such as VPN or virtual desktop'),
    Field('communicationTools', String,
        'Communication Tools — email, chat, video',
        hint: 'Email, chat and video tools needed'),
    Field('reportingTools', String,
        'Reporting Tools — BI, dashboards, analytics',
        hint: 'BI, dashboard or analytics tools needed'),
    Field('accessProvisioning', String,
        'Access Provisioning — how access is granted',
        hint: 'How and when access is provisioned'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// New role performance metrics.
@StandardReferences(
  [
    'SHRM — performance management',
    'CIPD — competency frameworks and people management',
  ],
  'Defines how success in the role is measured — objectives, KPIs, review '
  'cadence, milestones and the path to advancement.',
)
@SectionId('NEROPE')
class NewRolePerformance {
  @Form([
    Field('performanceObjectives', String,
        'Performance Objectives — key goals',
        hint: 'Key goals the role is expected to achieve'),
    Field('kpis', String, 'KPIs — quantitative metrics',
        hint: 'Quantitative metrics used to gauge success'),
    Field('qualitativeMetrics', String,
        'Qualitative Metrics — behavioral/quality measures',
        hint: 'Behavioral or quality-based measures'),
    Field('reviewFrequency', String,
        'Review Frequency — performance review cadence',
        hint: 'How often performance is reviewed'),
    Field('probationPeriod', String,
        'Probation Period — initial review period',
        hint: 'Length of the initial probation period'),
    Field('successMilestones', String,
        'Success Milestones — 30/60/90 day goals',
        hint: 'Early milestones such as 30/60/90 day goals'),
    Field('careerPath', String,
        'Career Path — typical progression from this role',
        hint: 'Typical progression from this role'),
    Field('promotionCriteria', String,
        'Promotion Criteria — requirements for advancement',
        hint: 'Requirements for advancement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// New role onboarding plan.
@StandardReferences(
  [
    'SHRM — onboarding',
    'CIPD — competency frameworks and people management',
  ],
  'Lays out how a new hire is brought up to speed — orientation, training, '
  'mentoring, shadowing, check-ins and ramp-up expectations.',
)
@SectionId('NEROON')
class NewRoleOnboarding {
  @Form([
    Field('onboardingDuration', String,
        'Onboarding Duration — weeks to full productivity',
        hint: 'Time expected to reach full productivity'),
    Field('orientationTopics', String,
        'Orientation Topics — company/department intro',
        hint: 'Company and department introduction topics'),
    Field('requiredTraining', String,
        'Required Training — mandatory courses',
        hint: 'Mandatory training courses'),
    Field('systemTraining', String,
        'System Training — application-specific training',
        hint: 'Application-specific training needed'),
    Field('processTraining', String,
        'Process Training — business process training',
        hint: 'Training on relevant business processes'),
    Field('mentorAssignment', String,
        'Mentor Assignment — buddy/mentor program',
        hint: 'Buddy or mentor assigned to the new hire'),
    Field('shadowingPlan', String,
        'Shadowing Plan — observation opportunities',
        hint: 'Opportunities to observe experienced staff'),
    Field('checkpointMeetings', String,
        'Checkpoint Meetings — scheduled check-ins',
        hint: 'Scheduled check-in meetings'),
    Field('rampUpExpectations', String,
        'Ramp-Up Expectations — productivity expectations over time',
        hint: 'Productivity expectations over the ramp-up period'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A changed role entry (form).
///
/// Documents modifications to existing roles with impact assessment,
/// transition planning, and incumbent management.
@StandardReferences(
  [
    'SHRM — HR best practices (role change management, workforce transition)',
    'O*NET — occupational job analysis (tasks, skills)',
    'ADKAR / Kotter — change management',
  ],
  'Captures a single existing role that is being modified — what changes in '
  'its responsibilities, competencies, access, and how affected incumbents '
  'are transitioned.',
)
@SectionId('CHAROL')
class ChangedRoleEntry {
  /// Changed role identification.
  @SerializationOrder(0)
  ChangedRoleIdentification identification = ChangedRoleIdentification();

  /// Responsibility changes.
  @SerializationOrder(1)
  ChangedRoleResponsibilities responsibilities = ChangedRoleResponsibilities();

  /// Competency changes.
  @SerializationOrder(2)
  ChangedRoleCompetencies competencies = ChangedRoleCompetencies();

  /// System access changes.
  @SerializationOrder(3)
  ChangedRoleSystemAccess systemAccess = ChangedRoleSystemAccess();

  /// Impact on incumbents.
  @SerializationOrder(4)
  ChangedRoleIncumbentImpact incumbentImpact = ChangedRoleIncumbentImpact();

  /// Transition planning.
  @SerializationOrder(5)
  ChangedRoleTransition transition = ChangedRoleTransition();
}

/// Changed role identification.
@StandardReferences(
  [
    'SHRM — HR best practices (role change management)',
    'O*NET — occupational job analysis (tasks, skills)',
  ],
  'Identifies the role being changed and the rationale for the change, '
  'including any title or placement adjustment.',
)
@SectionId('CHROID')
class ChangedRoleIdentification {
  @Form([
    Field('roleId', String, 'Role ID (e.g., CR-001)', required: true,
        hint: 'Unique identifier for this changed role'),
    Field('roleTitle', String, 'Current Role Title', required: true,
        hint: 'The role title before the change'),
    Field('newRoleTitle', String, 'New Role Title — if title changes',
        hint: 'The role title after the change, if it differs'),
    Field('changeRationale', String,
        'Change Rationale — why this role is changing',
        hint: 'The business reason driving this role change'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Current and future organizational placement.
    @SerializationOrder(1)
    ChangedRoleIdentificationStructure structure =
            ChangedRoleIdentificationStructure();

    /// Change implementation state and affected population.
    @SerializationOrder(2)
    ChangedRoleIdentificationTransition transition =
            ChangedRoleIdentificationTransition();
}

/// Current and future organizational placement.
@StandardReferences(
  [
    'ISO 21500 — project management (organizational roles)',
    'SHRM — HR best practices (role change management)',
  ],
  'Records where the role sits in the organization today and where it will '
  'sit after the change — department and job-level moves.',
)
@SectionId('CRIS')
class ChangedRoleIdentificationStructure {
    @Form([
        Field('currentDepartment', String, 'Current Department',
            hint: 'Department the role currently reports into'),
        Field('newDepartment', String, 'New Department — if moving',
            hint: 'Department the role will move to, if it changes'),
        Field('currentJobLevel', String, 'Current Job Level',
            hint: 'Job grade or level before the change'),
        Field('newJobLevel', String, 'New Job Level — if changing',
            hint: 'Job grade or level after the change, if it differs'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Change implementation state and affected population.
@StandardReferences(
  [
    'SHRM — HR best practices (workforce transition)',
    'ADKAR / Kotter — change management',
  ],
  'Tracks the kind of change, its rollout state, the effective date, and how '
  'many incumbents are affected.',
)
@SectionId('CRIT')
class ChangedRoleIdentificationTransition {
    @Form([
        Field('changeType', String,
                'Change Type — expanded, reduced, restructured, upgraded, downgraded',
            hint: 'Nature of the change to the role'),
        Field('effectiveDate', String, 'Effective Date',
            hint: 'Date the role change takes effect'),
        Field('changeStatus', String,
                'Change Status — proposed, approved, communicated, implemented',
            hint: 'Current stage of the change rollout'),
        Field('incumbentCount', int, 'Incumbent Count — people in this role',
            hint: 'Number of people currently holding the role'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Changed role responsibilities.
@StandardReferences(
  [
    'O*NET — occupational job analysis (tasks)',
    'RACI — responsibility assignment',
  ],
  'Groups the responsibility changes for the role — those added, removed, and '
  'modified — plus a net-impact summary.',
)
@SectionId('CHRORE')
class ChangedRoleResponsibilities {
  /// Responsibilities being added.
  @StandardReferences(
    ['O*NET — task statements'],
    'The duties newly assigned to this role as part of the change.',
  )
  @SectionId('RSPCH-ADDE-LST')
  @SectionIdPattern('RSPCH-ADDE-xxx')
  @ContentHelp('Add one entry per responsibility being added to the role.')
  @SerializationOrder(0)
  List<ResponsibilityChangeEntry> addedResponsibilities = [];

  /// Responsibilities being removed.
  @StandardReferences(
    ['O*NET — task statements'],
    'The duties removed from this role as part of the change.',
  )
  @SectionId('RSPCH-REMO-LST')
  @SectionIdPattern('RSPCH-REMO-xxx')
  @ContentHelp('Add one entry per responsibility being removed from the role.')
  @SerializationOrder(1)
  List<ResponsibilityChangeEntry> removedResponsibilities = [];

  /// Responsibilities being modified.
  @StandardReferences(
    ['O*NET — task statements'],
    'The duties whose scope or nature changes within this role.',
  )
  @SectionId('RSPCH-MODI-LST')
  @SectionIdPattern('RSPCH-MODI-xxx')
  @ContentHelp('Add one entry per responsibility being modified in the role.')
  @SerializationOrder(2)
  List<ResponsibilityChangeEntry> modifiedResponsibilities = [];

  /// Net impact summary.
  @SerializationOrder(3)
  ResponsibilityImpactSummary impactSummary = ResponsibilityImpactSummary();
}

/// Responsibility change entry (form).
@StandardReferences(
  [
    'O*NET — task statements',
    'SHRM — HR best practices (role change management)',
  ],
  'A single responsibility being added, removed, or modified, with its '
  'current/future state, impact, and how it is transitioned.',
)
@SectionId('RSPCH')
class ResponsibilityChangeEntry {
  @Form([
    Field('responsibility', String, 'Responsibility', required: true,
        hint: 'The responsibility affected by this change'),
    Field('changeType', String, 'Change Type — add, remove, modify',
        hint: 'Whether this responsibility is added, removed, or modified'),
    Field('currentState', String, 'Current State — how done today',
        hint: 'How this responsibility is handled before the change'),
    Field('futureState', String, 'Future State — how done after change',
        hint: 'How this responsibility will be handled after the change'),
    Field('reason', String, 'Reason — why this change',
        hint: 'The reason this responsibility is changing'),
    Field('impactLevel', String, 'Impact Level — high, medium, low',
        hint: 'How significant the impact of this change is'),
    Field('trainingNeeded', String, 'Training Needed',
        hint: 'Training required to perform the changed responsibility'),
    Field('toolsAffected', String, 'Tools Affected — systems involved',
        hint: 'Systems or tools impacted by this change'),
    Field('transitionApproach', String,
        'Transition Approach — how responsibility is handed over',
        hint: 'How the responsibility is transferred or phased in'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Summary of responsibility impact.
@StandardReferences(
  [
    'SHRM — HR best practices (role change management)',
    'O*NET — occupational job analysis',
  ],
  'Summarizes the aggregate effect of the responsibility changes on the '
  'role — workload, complexity, scope, authority, classification, and pay.',
)
@SectionId('REIMSU')
class ResponsibilityImpactSummary {
  @Form([
    Field('netTimeImpact', String,
        'Net Time Impact — increase/decrease in workload',
        hint: 'Overall change in time or workload for the role'),
    Field('complexityChange', String,
        'Complexity Change — simpler, same, more complex',
        hint: 'Whether the role becomes simpler or more complex'),
    Field('scopeChange', String,
        'Scope Change — narrower, same, broader',
        hint: 'Whether the scope of the role narrows or broadens'),
    Field('authorityChange', String,
        'Authority Change — less, same, more',
        hint: 'Whether the role gains or loses authority'),
    Field('classificationImpact', String,
        'Classification Impact — should job grade change',
        hint: 'Whether the job grade or classification should change'),
    Field('compensationImpact', String,
        'Compensation Impact — salary implications',
        hint: 'Salary or compensation implications of the change'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Changed role competency requirements.
@StandardReferences(
  [
    'CIPD — competency frameworks and people management',
    'ISO 9001 §7.2 — competence',
  ],
  'Groups how the competency requirements of the role change — competencies '
  'newly required, no longer required, or shifted in proficiency level.',
)
@SectionId('CHROCO')
class ChangedRoleCompetencies {
  /// New competencies required.
  @StandardReferences(
    ['CIPD — competency frameworks and people management'],
    'Competencies that become required for the role after the change.',
  )
  @SectionId('ROLCP-NEWC-LST')
  @SectionIdPattern('ROLCP-NEWC-xxx')
  @ContentHelp('Add one entry per competency newly required by the role.')
  @SerializationOrder(0)
  List<RoleCompetencyEntry> newCompetencies = [];

  /// Competencies no longer required.
  @StandardReferences(
    ['CIPD — competency frameworks and people management'],
    'Competencies that are no longer required by the role after the change.',
  )
  @SectionId('ROLCP-REMO-LST')
  @SectionIdPattern('ROLCP-REMO-xxx')
  @ContentHelp('Add one entry per competency no longer required by the role.')
  @SerializationOrder(1)
  List<RoleCompetencyEntry> removedCompetencies = [];

  /// Competencies with changed proficiency levels.
  @StandardReferences(
    ['CIPD — competency frameworks and people management'],
    'Competencies retained by the role but at a different required '
    'proficiency level.',
  )
  @SectionId('COLVCH-CHAN-LST')
  @SectionIdPattern('COLVCH-CHAN-xxx')
  @ContentHelp('Add one entry per competency whose required level changes.')
  @SerializationOrder(2)
  List<CompetencyLevelChangeEntry> changedLevels = [];

  /// Overall competency gap assessment.
  @SerializationOrder(3)
  CompetencyGapAssessment gapAssessment = CompetencyGapAssessment();
}

/// Competency level change entry.
@StandardReferences(
  [
    'CIPD — competency frameworks and people management',
    'ISO 9001 §7.2 — competence',
  ],
  'A single competency whose required proficiency level changes, with the '
  'reason, development path, and timeframe to reach the new level.',
)
@SectionId('COLVCH')
class CompetencyLevelChangeEntry {
  @Form([
    Field('competencyName', String, 'Competency Name', required: true,
        hint: 'The competency whose required level is changing'),
    Field('currentLevel', String, 'Current Required Level',
        hint: 'Proficiency level required before the change'),
    Field('newLevel', String, 'New Required Level',
        hint: 'Proficiency level required after the change'),
    Field('reason', String, 'Reason — why level is changing',
        hint: 'Why the required proficiency level is changing'),
    Field('developmentPath', String,
        'Development Path — how to close gap',
        hint: 'How incumbents can reach the new proficiency level'),
    Field('timeframe', String, 'Timeframe — when level needed',
        hint: 'When the new proficiency level must be reached'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Competency gap assessment.
@StandardReferences(
  [
    'CIPD — competency gap analysis',
    'ISO 9001 §7.2 — competence',
  ],
  'Assesses the overall competency gap for the changed role and the strategy, '
  'timeline, and interim measures to close it.',
)
@SectionId('COGAAS')
class CompetencyGapAssessment {
  @Form([
    Field('overallGapSeverity', String,
        'Overall Gap Severity — critical, significant, moderate, minor',
        hint: 'How severe the overall competency gap is'),
    Field('criticalGaps', String,
        'Critical Gaps — competencies where gap is most severe',
        hint: 'The competencies with the largest or most urgent gaps'),
    Field('developmentStrategy', String,
        'Development Strategy — training, coaching, hiring',
        hint: 'The approach chosen to close the competency gaps'),
    Field('developmentTimeline', String,
        'Development Timeline — when gaps will be closed',
        hint: 'When the competency gaps are expected to be closed'),
    Field('interimMeasures', String,
        'Interim Measures — how to manage until gaps closed',
        hint: 'How the role is covered until the gaps are closed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Changed role system access.
@StandardReferences(
  [
    'ISO/IEC 27001 — access control / least privilege',
    'SHRM — HR best practices (role change management)',
  ],
  'Records how the role\'s system and data access rights change — access '
  'added, removed, or re-permissioned — and when the change takes effect.',
)
@SectionId('CRSA')
class ChangedRoleSystemAccess {
  @Form([
    Field('newSystemAccess', String,
        'New System Access — additional systems needed',
        hint: 'Systems the role newly needs access to'),
    Field('removedSystemAccess', String,
        'Removed System Access — systems no longer needed',
        hint: 'Systems the role no longer needs access to'),
    Field('changedPermissions', String,
        'Changed Permissions — modified access levels',
        hint: 'Permission or access-level changes on existing systems'),
    Field('securityRoleChanges', String,
        'Security Role Changes — updated security roles',
        hint: 'Security roles or groups reassigned to the role'),
    Field('dataAccessChanges', String,
        'Data Access Changes — modified data domains',
        hint: 'Changes to which data domains the role can access'),
    Field('trainingOnNewSystems', String,
        'Training on New Systems — training required',
        hint: 'Training needed for the newly accessible systems'),
    Field('accessTransitionDate', String,
        'Access Transition Date — when access changes',
        hint: 'Date the access changes take effect'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Impact on current role incumbents.
@StandardReferences(
  [
    'SHRM — change impact / employee relations',
    'ADKAR / Kotter — change management',
  ],
  'Assesses how the role change affects the people currently in it — their '
  'readiness, retention risk, individual plans, support, and acceptance.',
)
@SectionId('CRII')
class ChangedRoleIncumbentImpact {
  @Form([
    Field('incumbentCount', int, 'Incumbent Count — people affected',
        hint: 'Number of current incumbents affected by the change'),
    Field('impactAssessment', String,
        'Impact Assessment — how incumbents are affected',
        hint: 'How the change affects the current incumbents'),
    Field('competencyGapAnalysis', String,
        'Competency Gap Analysis — where incumbents have gaps',
        hint: 'Where current incumbents fall short of new requirements'),
    Field('readinessAssessment', String,
        'Readiness Assessment — incumbent preparedness',
        hint: 'How prepared incumbents are for the changed role'),
    Field('retentionRisk', String,
        'Retention Risk — flight risk due to changes',
        hint: 'Risk of losing incumbents because of the change'),
    Field('individualTransitionPlans', String,
        'Individual Transition Plans — personalized plans',
        hint: 'Personalized transition plans for affected incumbents'),
    Field('supportProvided', String,
        'Support Provided — coaching, mentoring, training',
        hint: 'Support offered to help incumbents adapt'),
    Field('alternativePaths', String,
        'Alternative Paths — if incumbent cannot adapt',
        hint: 'Options for incumbents who cannot adapt to the change'),
    Field('communicationApproach', String,
        'Communication Approach — how changes are communicated',
        hint: 'How the change is communicated to incumbents'),
    Field('changeAcceptanceStatus', String,
        'Change Acceptance Status — incumbent reactions',
        hint: 'How incumbents are responding to the change'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Changed role transition planning.
@StandardReferences(
  [
    'ADKAR / Kotter — change management',
    'PMBOK — resource management (roles & responsibilities)',
  ],
  'Plans the timeline over which the role change is rolled out, including any '
  'parallel period, and links to training and support plans.',
)
@SectionId('CHROTR')
class ChangedRoleTransition {
  @Form([
    Field('transitionStart', String, 'Transition Start Date',
        hint: 'Date the role transition begins'),
    Field('transitionEnd', String, 'Transition End Date',
        hint: 'Date the role transition completes'),
    Field('parallelPeriod', String,
        'Parallel Period — overlap of old/new ways',
        hint: 'Period where old and new ways of working overlap'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Training preparation for the transition.
  @SerializationOrder(1)
  ChangedRoleTransitionTraining training = ChangedRoleTransitionTraining();

  /// Support expectations and success checkpoints.
  @SerializationOrder(2)
  ChangedRoleTransitionSupport support = ChangedRoleTransitionSupport();
}

/// Training preparation for the transition.
@StandardReferences(
  [
    'CIPD — competency frameworks and people management',
    'ISO 9001 §7.2 — competence',
  ],
  'Details the training that prepares incumbents for the changed role — its '
  'schedule, duration, format, and hands-on practice opportunities.',
)
@SectionId('CRTT')
class ChangedRoleTransitionTraining {
  @Form([
    Field('trainingSchedule', String,
        'Training Schedule — when training occurs',
        hint: 'When the transition training takes place'),
    Field('trainingDuration', String,
        'Training Duration — hours/days of training',
        hint: 'Total length of the transition training'),
    Field('trainingFormat', String,
        'Training Format — classroom, online, OJT',
        hint: 'The delivery format of the training'),
    Field('practiceOpportunities', String,
        'Practice Opportunities — sandbox, pilot',
        hint: 'Hands-on opportunities to practice the new role'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Support expectations and success checkpoints.
@StandardReferences(
  [
    'ADKAR / Kotter — change management',
    'SHRM — HR best practices (workforce transition)',
  ],
  'Sets out the support available during the transition, adjusted performance '
  'expectations, milestones, and the criteria for a successful transition.',
)
@SectionId('CRTS')
class ChangedRoleTransitionSupport {
  @Form([
    Field('supportDuringTransition', String,
        'Support During Transition — help available',
        hint: 'Help available to incumbents during the transition'),
    Field('performanceExpectations', String,
        'Performance Expectations — adjusted goals during transition',
        hint: 'Adjusted performance goals during the transition'),
    Field('transitionMilestones', String,
        'Transition Milestones — key checkpoints',
        hint: 'Key checkpoints marking transition progress'),
    Field('successCriteria', String,
        'Success Criteria — how successful transition is measured',
        hint: 'How a successful transition is measured'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A removed role entry (form).
///
/// Documents roles being eliminated with transition planning for incumbents.
@StandardReferences(
  [
    'SHRM — workforce reduction / redeployment',
    'ADKAR / Kotter — change management',
  ],
  'Captures a role being eliminated — the reason, effective date, and affected '
  'population — plus transition, governance, and continuity planning.',
)
@SectionId('REMROL')
class RemovedRoleEntry {
  @Form([
    Field('roleId', String, 'Role ID', required: true,
        hint: 'Unique identifier for the role being removed'),
    Field('roleTitle', String, 'Role Title', required: true,
        hint: 'Title of the role being removed'),
    Field('department', String, 'Department',
        hint: 'Department the removed role belongs to'),
    Field('removalReason', String,
        'Removal Reason — automation, restructuring, outsourcing, redundancy',
        hint: 'Why the role is being eliminated'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'Date the role removal takes effect'),
    Field('incumbentCount', int, 'Incumbent Count — people affected',
        hint: 'Number of people currently in the role being removed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Incumbent transition planning.
  @SerializationOrder(1)
  RemovedRoleEntryTransition transition = RemovedRoleEntryTransition();

  /// Legal and communication considerations.
  @SerializationOrder(2)
  RemovedRoleEntryGovernance governance = RemovedRoleEntryGovernance();

  /// Work continuity.
  @SerializationOrder(3)
  RemovedRoleEntryContinuity continuity = RemovedRoleEntryContinuity();
}

/// Incumbent transition planning.
@StandardReferences(
  [
    'SHRM — workforce reduction / redeployment',
    'ADKAR / Kotter — change management',
  ],
  'Plans what happens to the people in a removed role — redeployment, '
  'reassignment options, support, and severance.',
)
@SectionId('RRET')
class RemovedRoleEntryTransition {
  @Form([
    Field('incumbentDisposition', String,
        'Incumbent Disposition — redeployment, separation, retraining',
        hint: 'What happens to incumbents of the removed role'),
    Field('reassignmentOptions', String,
        'Reassignment Options — alternative roles available',
        hint: 'Alternative roles available to affected incumbents'),
    Field('transitionSupport', String,
        'Transition Support — outplacement, retraining',
        hint: 'Support provided to incumbents during the transition'),
    Field('severanceConsiderations', String,
        'Severance Considerations — if applicable',
        hint: 'Severance arrangements where separation applies'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Legal and communication considerations.
@StandardReferences(
  [
    'SHRM — workforce reduction / redeployment',
    'ISO 21500 — project management (organizational roles)',
  ],
  'Covers the legal and communication considerations of removing a role — '
  'employment law, works-council or union obligations, and how the removal '
  'is communicated.',
)
@SectionId('RREG')
class RemovedRoleEntryGovernance {
  @Form([
    Field('legalConsiderations', String,
        'Legal Considerations — employment law, union agreements',
        hint: 'Employment-law, works-council, or union obligations'),
    Field('communicationPlan', String,
        'Communication Plan — how removal is communicated',
        hint: 'How the role removal is communicated to stakeholders'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Work continuity.
@StandardReferences(
  [
    'SHRM — workforce reduction / redeployment',
    'PMBOK — resource management (roles & responsibilities)',
  ],
  'Ensures the work of a removed role continues — how institutional knowledge '
  'is captured and where its responsibilities are reassigned.',
)
@SectionId('RREC')
class RemovedRoleEntryContinuity {
  @Form([
    Field('knowledgeTransfer', String,
        'Knowledge Transfer — preserving institutional knowledge',
        hint: 'How the role\'s institutional knowledge is preserved'),
    Field('workReassignment', String,
        'Work Reassignment — where responsibilities go',
        hint: 'Where the removed role\'s responsibilities are reassigned'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A responsibility entry (form).
@StandardReferences(
  [
    'O*NET — occupational job analysis (tasks)',
    'RACI — responsibility assignment',
  ],
  'A single responsibility of a role, with a short description of what it '
  'entails.',
)
@SectionId('ROREEN')
class RoleResponsibilityEntry {
  @Form([
    Field('responsibility', String, 'Responsibility',
        hint: 'The responsibility assigned to the role'),
    Field('description', String, 'Short description',
        hint: 'A brief description of the responsibility'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A skill entry (form).
@StandardReferences(
  [
    'O*NET — occupational job analysis (skills)',
    'CIPD — competency frameworks and people management',
  ],
  'A single skill required by a role, together with the proficiency level '
  'expected.',
)
@SectionId('SKEN')
class SkillEntry {
  @Form([
    Field('skillName', String, 'Skill Name',
        hint: 'The name of the required skill'),
    Field('proficiencyLevel', String, 'Proficiency Level',
        hint: 'The proficiency level expected for this skill'),
  ])
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  WorkplaceUserCategory userCategory = WorkplaceUserCategory();

  /// Physical workplace layout and environment.
  @SerializationOrder(1)
  PhysicalWorkplaceRequirements physicalRequirements =
      PhysicalWorkplaceRequirements();

  /// 5.3.1. Equipment Requirements.
  @SerializationOrder(2)
  EquipmentRequirements equipmentRequirements = EquipmentRequirements();

  /// Technical infrastructure requirements.
  @SerializationOrder(3)
  TechnicalInfrastructure technicalInfrastructure = TechnicalInfrastructure();

  /// 5.3.2. Training Requirements.
  @SerializationOrder(4)
  TrainingRequirements trainingRequirements = TrainingRequirements();

  /// Support resources available to users.
  @SerializationOrder(5)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Environmental conditions and controls.
  @SerializationOrder(1)
  PhysicalWorkplaceRequirementsEnvironment environment =
      PhysicalWorkplaceRequirementsEnvironment();

  /// Accessibility, privacy, and shared-space needs.
  @SerializationOrder(2)
  PhysicalWorkplaceRequirementsUsage usage =
      PhysicalWorkplaceRequirementsUsage();
}

/// Environmental conditions and controls.
@SectionId('PHWOREEN')
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;
}

/// 5.3.1. Equipment Requirements.
///
/// Hardware and peripheral requirements per workplace type.
@SectionId('EQRE')
class EquipmentRequirements {
  /// Equipment overview.
  @SerializationOrder(0)
  EquipmentOverview overview = EquipmentOverview();

  /// Primary computing equipment.
  @SectionId('COEQ-PRIM-LST')
  @SectionIdPattern('COEQ-PRIM-xxx')
  @SerializationOrder(1)
  List<ComputingEquipmentEntry> primaryComputing = [];

  /// Display and monitors.
  @SectionId('DSEQ-DISP-LST')
  @SectionIdPattern('DSEQ-DISP-xxx')
  @SerializationOrder(2)
  List<DisplayEquipmentEntry> displays = [];

  /// Input devices.
  @SectionId('INPDE-INPU-LST')
  @SectionIdPattern('INPDE-INPU-xxx')
  @SerializationOrder(3)
  List<InputDeviceEntry> inputDevices = [];

  /// Peripheral equipment.
  @SectionId('PEREQ-PERI-LST')
  @SectionIdPattern('PEREQ-PERI-xxx')
  @SerializationOrder(4)
  List<PeripheralEquipmentEntry> peripherals = [];

  /// Mobile devices.
  @SectionId('MOBDE-MOBI-LST')
  @SectionIdPattern('MOBDE-MOBI-xxx')
  @SerializationOrder(5)
  List<MobileDeviceEntry> mobileDevices = [];

  /// Specialized equipment.
  @SectionId('SPEQ-SPEC-LST')
  @SectionIdPattern('SPEQ-SPEC-xxx')
  @SerializationOrder(6)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

    /// Hardware specifications.
    @SerializationOrder(1)
    ComputingEquipmentEntryHardware hardware = ComputingEquipmentEntryHardware();

    /// Platform and security requirements.
    @SerializationOrder(2)
    ComputingEquipmentEntryPlatform platform = ComputingEquipmentEntryPlatform();

    /// Deployment and justification.
    @SerializationOrder(3)
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
    @SerializationOrder(0)
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
    @SerializationOrder(0)
    String? content;
}

/// Deployment and justification.
@SectionId('COEQENPL')
class ComputingEquipmentEntryPlanning {
    @Form([
        Field('quantityNeeded', int, 'Quantity Needed'),
        Field('priorityLevel', String,
                'Priority Level — critical, standard, optional'),
        Field('justification', String, 'Justification — why this specification'),
    ])
    @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

    /// Display quality and connection properties.
    @SerializationOrder(1)
    DisplayEquipmentEntryVisual visual = DisplayEquipmentEntryVisual();

    /// Ergonomic and placement considerations.
    @SerializationOrder(2)
    DisplayEquipmentEntryErgonomics ergonomics =
            DisplayEquipmentEntryErgonomics();

    /// Quantity planning and justification.
    @SerializationOrder(3)
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
    @SerializationOrder(0)
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
    @SerializationOrder(0)
    String? content;
}

/// Quantity planning and justification for display equipment.
@SectionId('DIEQENPL')
class DisplayEquipmentEntryPlanning {
    @Form([
        Field('quantityPerUser', int, 'Quantity Per User — number of monitors'),
        Field('justification', String, 'Justification'),
    ])
    @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

    /// Technical and management requirements.
    @SerializationOrder(1)
    MobileDeviceEntryCapabilities capabilities = MobileDeviceEntryCapabilities();

    /// Deployment planning and supporting accessories.
    @SerializationOrder(2)
    MobileDeviceEntryPlanning planning = MobileDeviceEntryPlanning();
}

/// Technical and management requirements.
@SectionId('MODEENCA')
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
    @SerializationOrder(0)
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
    @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

    /// Technical and compliance characteristics.
    @SerializationOrder(1)
    SpecializedEquipmentEntryTechnical technical =
            SpecializedEquipmentEntryTechnical();

    /// Quantity and business justification.
    @SerializationOrder(2)
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
    @SerializationOrder(0)
    String? content;
}

/// Quantity and business justification.
@SectionId('SEEP')
class SpecializedEquipmentEntryPlanning {
    @Form([
        Field('quantityNeeded', int, 'Quantity Needed'),
        Field('justification', String, 'Justification'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Technical infrastructure requirements.
@SectionId('TEIN')
class TechnicalInfrastructure {
  /// Network connectivity requirements.
  @SerializationOrder(0)
  NetworkConnectivity networkConnectivity = NetworkConnectivity();

  /// Software requirements.
  @SerializationOrder(1)
  WorkplaceSoftwareRequirements softwareRequirements =
      WorkplaceSoftwareRequirements();

  /// Remote access requirements.
  @SerializationOrder(2)
  RemoteAccessRequirements remoteAccess = RemoteAccessRequirements();

  /// Communication tools.
  @SectionId('COTORE-COMM-LST')
  @SectionIdPattern('COTORE-COMM-xxx')
  @SerializationOrder(3)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Security and collaboration software stack.
  @SerializationOrder(1)
  WorkplaceSoftwareRequirementsPlatform platform =
      WorkplaceSoftwareRequirementsPlatform();

  /// Business application set and deployment model.
  @SerializationOrder(2)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;
}

/// 5.3.2. Training Requirements.
///
/// Comprehensive training program requirements following adult learning
/// principles (ADDIE, Kirkpatrick evaluation model).
@SectionId('TRRE')
class TrainingRequirements {
  /// Training overview and strategy.
  @SerializationOrder(0)
  TrainingOverview overview = TrainingOverview();

  /// Initial/onboarding training.
  @SectionId('INITR-INIT-LST')
  @SectionIdPattern('INITR-INIT-xxx')
  @SerializationOrder(1)
  List<InitialTrainingEntry> initialTraining = [];

  /// Ongoing/refresher training.
  @SectionId('ONGTR-ONGO-LST')
  @SectionIdPattern('ONGTR-ONGO-xxx')
  @SerializationOrder(2)
  List<OngoingTrainingEntry> ongoingTraining = [];

  /// System-specific training.
  @SectionId('SYTR-SYST-LST')
  @SectionIdPattern('SYTR-SYST-xxx')
  @SerializationOrder(3)
  List<SystemTrainingEntry> systemTraining = [];

  /// Certification requirements.
  @SectionId('CRT-CERT-LST')
  @SectionIdPattern('CRT-CERT-xxx')
  @SerializationOrder(4)
  List<CertificationEntry> certifications = [];

  /// Training materials and resources.
  @SerializationOrder(5)
  TrainingMaterials trainingMaterials = TrainingMaterials();

  /// Assessment and evaluation.
  @SerializationOrder(6)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Target and prerequisites.
  @SerializationOrder(1)
  InitialTrainingAudience audience = InitialTrainingAudience();

  /// Learning content.
  @SerializationOrder(2)
  InitialTrainingContent learningContent = InitialTrainingContent();

  /// Delivery details.
  @SerializationOrder(3)
  InitialTrainingDelivery delivery = InitialTrainingDelivery();

  /// Schedule information.
  @SerializationOrder(4)
  InitialTrainingSchedule schedule = InitialTrainingSchedule();

  /// Assessment and certification.
  @SerializationOrder(5)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Scheduling and delivery.
  @SerializationOrder(1)
  OngoingTrainingEntrySchedule schedule = OngoingTrainingEntrySchedule();

  /// Content maintenance.
  @SerializationOrder(2)
  OngoingTrainingEntryContent contentManagement =
      OngoingTrainingEntryContent();

  /// Tracking and compliance.
  @SerializationOrder(3)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;
}

/// Tracking and compliance.
@SectionId('ONTRENCO')
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Functional training coverage.
  @SerializationOrder(1)
  SystemTrainingEntryFunctional functional = SystemTrainingEntryFunctional();

  /// Practical exercises.
  @SerializationOrder(2)
  SystemTrainingEntryPractice practice = SystemTrainingEntryPractice();

  /// Support and environment.
  @SerializationOrder(3)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

    /// Description and audience.
    @SerializationOrder(1)
    CertificationEntryOverview overview = CertificationEntryOverview();

    /// Preparation requirements.
    @SerializationOrder(2)
    CertificationEntryPreparation preparation = CertificationEntryPreparation();

    /// Exam details.
    @SerializationOrder(3)
    CertificationEntryExam exam = CertificationEntryExam();

    /// Validity and renewal details.
    @SerializationOrder(4)
    CertificationEntryMaintenance maintenance =
            CertificationEntryMaintenance();

    /// Sponsorship and consequences.
    @SerializationOrder(5)
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
    @SerializationOrder(0)
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
    @SerializationOrder(0)
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
    @SerializationOrder(0)
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
    @SerializationOrder(0)
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
    @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Practice and reference resources.
  @SerializationOrder(1)
  TrainingMaterialsPractice practice = TrainingMaterialsPractice();

  /// Knowledge distribution.
  @SerializationOrder(2)
  TrainingMaterialsKnowledge knowledge = TrainingMaterialsKnowledge();

  /// Publishing and accessibility.
  @SerializationOrder(3)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Retention and effectiveness evaluation.
  @SerializationOrder(1)
  TrainingAssessmentEffectiveness effectiveness =
      TrainingAssessmentEffectiveness();

  /// Competency and remediation management.
  @SerializationOrder(2)
  TrainingAssessmentImprovement improvement =
      TrainingAssessmentImprovement();

  /// Progress reporting.
  @SerializationOrder(3)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;

  /// Extended support channels.
  @SerializationOrder(1)
  WorkplaceSupportResourcesChannels channels =
      WorkplaceSupportResourcesChannels();

  /// Self-service and feedback.
  @SerializationOrder(2)
  WorkplaceSupportResourcesSelfService selfService =
      WorkplaceSupportResourcesSelfService();

  /// Incident and emergency support.
  @SerializationOrder(3)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
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
  @SerializationOrder(0)
  String? content;
}
