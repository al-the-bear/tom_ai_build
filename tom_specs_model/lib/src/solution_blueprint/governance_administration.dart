/// Administrative governance classes (SBP.4 children).
///
/// Project administration: team, distribution, change procedure, and
/// legal/contractual requirements. Covers organizational aspects of the
/// project including governance structure, staffing, communication channels,
/// and change management.
///
/// The former `Administrative` (`ADMN`) wrapper was dissolved in L34C-5; these
/// classes now hang directly off SBP.4 `StakeholdersAndGovernance`.
/// `ReferenceDocuments` was re-homed to SBP.1 `DocumentControl`.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

// The former `Administrative` (`ADMN`) wrapper was dissolved in L34C-5: its
// children now hang directly off SBP.4 `StakeholdersAndGovernance`
// (`ProjectOrganization`, `ProjectTeamStaffing`, `DistributionList`,
// `ChangeProcedure`, `LegalAndContractualRequirements`, and the
// `AdministrativeSummary` governance overview), and `ReferenceDocuments` was
// re-homed to SBP.1 `DocumentControl` (ISO/IEC/IEEE 29148 §6 front matter).
// The classes below remain here; only the wrapper class was removed.

// ---------------------------------------------------------------------------
// 3.1 Project Organization
// ---------------------------------------------------------------------------

/// Administrative overview summary statistics.
@StandardReferences(
  [
    'PMBOK — project governance & organizational structure',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'An at-a-glance roll-up of the project administration: team size, governance '
  'model, key decision-maker, and meeting cadence.',
)
@SectionId('ADMSM')
class AdministrativeSummary {
  @Form([
    Field('totalTeamMembers', int, 'Total Team Members',
        hint: 'Number of people assigned to the project'),
    Field('internalResources', int, 'Internal Resources',
        hint: 'Number of internal staff'),
    Field('externalResources', int, 'External Resources',
        hint: 'Number of contractors, consultants, vendors'),
    Field('steeringCommitteeSize', int, 'Steering Committee Size',
        hint: 'Number of steering committee members'),
    Field('distributionListSize', int, 'Distribution List Size',
        hint: 'Total recipients across all distribution lists'),
    Field('referenceDocumentsCount', int, 'Reference Documents Count',
        hint: 'Number of referenced documents'),
    Field('keyDecisionMaker', String, 'Key Decision Maker',
        hint: 'Primary authority for project decisions'),
    Field('projectManagerName', String, 'Project Manager',
        hint: 'Name of the project manager'),
    Field('governanceModel', String, 'Governance Model',
        hint: 'Type of governance structure in place'),
    Field('meetingCadenceOverview', String, 'Meeting Cadence Overview',
        hint: 'Summary of regular meetings and frequency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.1. Project Organization.
@StandardReferences(
  [
    'PMBOK — project governance & organizational structure',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'The root of §3.1: how the project is organized — reporting lines, governance '
  'arrangements, and the steering committee that oversees it.',
)
@SectionId('PRJOG')
class ProjectOrganization {
  @ContentHelp('''
Overview of project organization structure including reporting lines,
steering committee composition, and governance arrangements.
Describe the organizational model and key decision-making paths.
''')
  @SerializationOrder(0)
  String? content;

  /// 3.1.1. Organization Structure.
  @SerializationOrder(1)
  OrganizationStructure organizationStructure = OrganizationStructure();

  /// 3.1.2. Steering Committee.
  @SerializationOrder(2)
  SteeringCommittee steeringCommittee = SteeringCommittee();
}

/// 3.1.1. Organization Structure.
@StandardReferences(
  [
    'PMBOK — project governance & organizational structure',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'The project organization chart: reporting lines, governance model, decision '
  'rights, and escalation paths.',
)
@SectionId('ORGST')
class OrganizationStructure {
  @ContentType('description', 'Project organization chart with reporting '
      'lines, governance model, and escalation paths.')
  @ContentHelp('Insert project organization chart showing reporting lines. '
      'Describe the governance model: who decides what, escalation paths, '
      'meeting cadence.')
  @SerializationOrder(0)
  String? content;

  /// Governance model details.
  @SerializationOrder(1)
  GovernanceModel governanceModel = GovernanceModel();

  /// Organization chart diagram (e.g. Mermaid or image reference).
  @SerializationOrder(2)
  DiagramSection orgChartDiagram = DiagramSection();
}

/// Governance model details.
@StandardReferences(
  [
    'PMBOK — project governance & organizational structure',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'The decision-making framework for the project: how decisions are made and '
  'escalated, meeting cadence, and reporting frequency.',
)
@SectionId('GOVMD')
class GovernanceModel {
  @Form([
    Field('decisionFramework', String, 'Decision-Making Framework',
        hint: 'How project decisions are made — consensus, authority, RACI'),
    Field('escalationPaths', String, 'Escalation Paths',
        hint: 'How and to whom unresolved issues are escalated'),
    Field('meetingCadence', String, 'Meeting Cadence',
        hint: 'Frequency and type of governance meetings'),
    Field('reportingFrequency', String, 'Reporting Frequency',
        hint: 'How often status is reported to governance'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Decision authority matrix.
  @StandardReferences(
    [
      'PMBOK — RACI / responsibility assignment',
      'ISO 21500 — project management (governance, roles & responsibilities)',
    ],
    'The decision-authority matrix mapping decision areas to who decides and '
    'where each escalates.',
  )
  @SectionId('DCAUT-DECI-LST')
  @SectionIdPattern('DCAUT-DECI-xxx')
  @ContentHelp('Add one entry per decision area, naming its authority level, '
      'decision maker, escalation target, and expected response time.')
  @SerializationOrder(1)
  List<DecisionAuthorityEntry> decisionAuthorities = [];
}

/// A decision authority entry.
@StandardReferences(
  [
    'PMBOK — RACI / responsibility assignment',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'A single decision area: its authority level, who decides, who it escalates '
  'to, and the expected response time.',
)
@SectionId('DCAUT')
class DecisionAuthorityEntry {
  @Form([
    Field('decisionArea', String, 'Decision Area', required: true,
        hint: 'Area or category of decisions this authority covers'),
    Field('authorityLevel', String, 'Authority Level',
        hint: 'Level at which this decision can be made'),
    Field('decisionMaker', String, 'Decision Maker',
        hint: 'Role or person who makes this decision'),
    Field('escalationTo', String, 'Escalation To',
        hint: 'Who the decision escalates to if unresolved'),
    Field('responseTime', String, 'Expected Response Time',
        hint: 'Target turnaround for reaching this decision'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.1.2. Steering Committee.
///
/// Container for steering committee member descriptions.
@StandardReferences(
  [
    'PMBOK — project governance & organizational structure',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'The steering committee that governs the project: its charter and its '
  'members with their roles and decision authorities.',
)
@ContentHelp('List all steering committee members with their roles, '
    'responsibilities, and decision authorities.')
@SectionId('STCOM')
class SteeringCommittee {
  @ContentType('description', 'Overview of steering committee composition '
      'and responsibilities.')
  @SerializationOrder(0)
  String? content;

  /// Committee charter and rules.
  @SerializationOrder(1)
  CommitteeCharter charter = CommitteeCharter();

  /// Steering committee members — contains 1+× Committee Member.
  @StandardReferences(
    [
      'PMBOK — project governance & organizational structure',
      'ISO 21500 — project management (governance, roles & responsibilities)',
    ],
    'The roster of steering committee members and their governance roles.',
  )
  @SectionId('COMMB-MEMB-LST')
  @SectionIdPattern('COMMB-MEMB-xxx')
  @Min(1)
  @ContentHelp('Add one entry per steering committee member, capturing their '
      'organizational and committee role, decision authority, and contact.')
  @SerializationOrder(2)
  List<CommitteeMemberEntry> members = [];
}

/// Committee charter defining rules and procedures.
@StandardReferences(
  [
    'PMBOK — project governance & organizational structure',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'The steering committee charter: its purpose, meeting frequency, quorum, '
  'voting rules, and how minutes are distributed.',
)
@SectionId('COMCH')
class CommitteeCharter {
  @Form([
    Field('purpose', String, 'Purpose',
        hint: 'Why the committee exists and what it governs'),
    Field('meetingFrequency', String, 'Meeting Frequency',
        hint: 'How often the committee convenes'),
    Field('quorumRequirements', String, 'Quorum Requirements',
        hint: 'Minimum attendance needed for valid decisions'),
    Field('votingRules', String, 'Voting Rules',
        hint: 'How decisions are voted on and carried'),
    Field('minutesDistribution', String, 'Minutes Distribution',
        hint: 'Who receives the meeting minutes and how'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A steering committee member entry (form).
///
/// Detailed information about a steering committee member.
@StandardReferences(
  [
    'PMBOK — project governance & organizational structure',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'A single steering committee member: their organizational and committee '
  'role, decision authority, delegation rules, attendance, and contact.',
)
@ContentHelp('Document each committee member with their organizational role, '
    'committee responsibilities, and decision authority.')
@SectionId('CME')
class CommitteeMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true,
        hint: 'Full name of the committee member'),
    Field('organizationRole', String, 'Organization Role',
        hint: 'Their role within their home organization'),
    Field('department', String, 'Department',
        hint: 'Department or business unit they represent'),
    Field('committeeRole', String, 'Committee Role',
        hint: 'Their role on the steering committee'),
    Field('decisionAuthority', String, 'Decision Authority',
        hint: 'What decisions this member is empowered to make'),
    Field('delegationRules', String, 'Delegation Rules',
        hint: 'When and to whom they may delegate authority'),
    Field('meetingAttendance', String, 'Meeting Attendance (Mandatory/Optional)',
        hint: 'Whether attendance is mandatory or optional'),
    Field('contactInfo', String, 'Contact Information',
        hint: 'How to reach this committee member'),
    Field('substitute', String, 'Substitute/Deputy',
        hint: 'Designated stand-in when unavailable'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Specific responsibilities of this member.
  @StandardReferences(
    [
      'PMBOK — RACI / responsibility assignment',
      'ISO 21500 — project management (governance, roles & responsibilities)',
    ],
    'The specific governance responsibilities assigned to this committee member.',
  )
  @SectionId('COMRS-RESP-LST')
  @SectionIdPattern('COMRS-RESP-xxx')
  @ContentHelp('Add one entry per responsibility area this member owns, with '
      'its scope and escalation target.')
  @SerializationOrder(1)
  List<CommitteeResponsibilityEntry> responsibilities = [];
}

/// A committee member responsibility entry.
@StandardReferences(
  [
    'PMBOK — RACI / responsibility assignment',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'A single committee responsibility: its area, scope, and escalation target.',
)
@SectionId('COMRS')
class CommitteeResponsibilityEntry {
  @Form([
    Field('area', String, 'Responsibility Area', required: true,
        hint: 'Area of responsibility assigned to the committee'),
    Field('scope', String, 'Scope',
        hint: 'Boundaries of this responsibility'),
    Field('escalationTo', String, 'Escalation To',
        hint: 'Who issues in this area escalate to'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 3.2 Project Team Staffing
// ---------------------------------------------------------------------------

/// 3.2. Project Team Staffing.
///
/// Container for individual staff assignments including roles, responsibilities,
/// availability, and required competencies.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (resources)',
  ],
  'The root of §3.2: who staffs the project — the team structure, each assigned '
  'member, and any unfilled resource requirements.',
)
@ContentHelp('Document all team members assigned to the project with their '
    'roles, allocation percentages, and reporting relationships.')
@SectionId('PRJTS')
class ProjectTeamStaffing {
  @ContentType('description', 'Overview of team structure, staffing approach, '
      'and resource planning considerations.')
  @SerializationOrder(0)
  String? content;

  /// Team structure overview.
  @SerializationOrder(1)
  TeamStructureOverview teamStructure = TeamStructureOverview();

  /// Team members — contains 1+× Team Member.
  @StandardReferences(
    [
      'PMBOK — resource management (project team & staffing)',
      'ISO 21500 — project management (resources)',
    ],
    'The roster of team members assigned to the project.',
  )
  @SectionId('TMMBE-MEMB-LST')
  @SectionIdPattern('TMMBE-MEMB-xxx')
  @Min(1)
  @ContentHelp('Add one entry per assigned team member, with their role, '
      'allocation, contact, skills, availability, and responsibilities.')
  @SerializationOrder(2)
  List<TeamMemberEntry> members = [];

  /// Resource requirements not yet filled.
  @StandardReferences(
    [
      'PMBOK — resource management (project team & staffing)',
      'ISO 21500 — project management (resources)',
    ],
    'The open positions still to be filled to fully staff the project.',
  )
  @SectionId('RREQE-OPEN-LST')
  @SectionIdPattern('RREQE-OPEN-xxx')
  @ContentHelp('Add one entry per unfilled position, with its required skills, '
      'experience, allocation, target date, priority, and recruitment status.')
  @SerializationOrder(3)
  List<ResourceRequirementEntry> openRequirements = [];
}

/// Team structure overview.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (resources)',
  ],
  'A high-level view of the team: its size, internal/external split, location '
  'model, working hours, and reporting structure.',
)
@SectionId('TMSOV')
class TeamStructureOverview {
  @Form([
    Field('teamSize', int, 'Total Team Size',
        hint: 'Total number of people on the team'),
    Field('internalResources', int, 'Internal Resources',
        hint: 'Number of internal staff members'),
    Field('externalResources', int, 'External Resources',
        hint: 'Number of contractors, consultants, or vendors'),
    Field('teamLocationModel', String, 'Location Model (Co-located/Distributed/Hybrid)',
        hint: 'Co-located, distributed, or hybrid working model'),
    Field('coreHours', String, 'Core Working Hours',
        hint: 'Hours when the team is expected to overlap'),
    Field('reportingStructure', String, 'Reporting Structure',
        hint: 'How team members report within the project'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Team structure diagram.
  @SerializationOrder(1)
  DiagramSection teamDiagram = DiagramSection();
}

/// A resource requirement entry for unfilled positions.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (resources)',
  ],
  'A single unfilled position: the role needed, its required skills and '
  'experience, allocation, target date, priority, and recruitment status.',
)
@SectionId('RREQE')
class ResourceRequirementEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true,
        hint: 'Name of the role to be staffed'),
    Field('skillsRequired', String, 'Required Skills',
        hint: 'Skills the position requires'),
    Field('experience', String, 'Experience Level',
        hint: 'Seniority or years of experience needed'),
    Field('allocation', String, 'Allocation',
        hint: 'Expected allocation for the role'),
    Field('requiredBy', String, 'Required By Date',
        hint: 'When the position must be filled'),
    Field('priority', String, 'Priority (Critical/High/Medium/Low)',
        hint: 'Critical / High / Medium / Low'),
    Field('status', String, 'Recruitment Status',
        hint: 'Current recruitment progress for this position'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A team member entry (form).
///
/// Detailed information about a project team member including their role,
/// responsibilities, availability, and competencies.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (resources)',
  ],
  'A single team member: their role, allocation, contact, reporting and backup '
  'structure, skills, availability, and responsibilities.',
)
@ContentHelp('Document each team member with their role, allocation, skills, '
    'and availability. Include contact information and backup arrangements.')
@SectionId('TMMBE')
class TeamMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true,
        hint: 'Full name of the team member'),
    Field('projectRole', String, 'Project Role', required: true,
        hint: 'Role this person plays on the project'),
    Field('organization', String, 'Organization/Department',
        hint: 'Their home organization or department'),
    Field('jobTitle', String, 'Job Title',
        hint: 'Their substantive job title'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Allocation and scheduling details.
  @SerializationOrder(1)
  TeamMemberEntryAllocation allocationDetails =
      TeamMemberEntryAllocation();

  /// Work location and contact details.
  @SerializationOrder(2)
  TeamMemberEntryContact contact = TeamMemberEntryContact();

  /// Reporting and backup structure.
  @SerializationOrder(3)
  TeamMemberEntryGovernance governance = TeamMemberEntryGovernance();

  /// Special skills and certifications.
  @SerializationOrder(4)
  TeamMemberSkills skills = TeamMemberSkills();

  /// Availability constraints.
  @SerializationOrder(5)
  TeamMemberAvailability availability = TeamMemberAvailability();

  /// Role-specific responsibilities.
  @StandardReferences(
    [
      'PMBOK — resource management (project team & staffing)',
      'ISO 21500 — project management (resources)',
    ],
    'The specific responsibilities assigned to this team member.',
  )
  @SectionId('TMMRP-RESP-LST')
  @SectionIdPattern('TMMRP-RESP-xxx')
  @ContentHelp('Add one entry per responsibility area this member owns, with '
      'its description, key deliverables, and decision authority.')
  @SerializationOrder(6)
  List<TeamMemberResponsibilityEntry> responsibilities = [];
}

/// Allocation and scheduling details.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (resources)',
  ],
  'This team member\'s allocation to the project: percentage and start/end '
  'dates.',
)
@SectionId('TMMAL')
class TeamMemberEntryAllocation {
  @Form([
    Field('allocation', String, 'Allocation Percentage',
        hint: 'Percentage of time allocated to the project'),
    Field('startDate', String, 'Start Date',
        hint: 'When they join the project'),
    Field('endDate', String, 'End Date',
        hint: 'When their assignment ends'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Work location and contact details.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (resources)',
  ],
  'This team member\'s work location, time zone, and contact details.',
)
@SectionId('TMMCO')
class TeamMemberEntryContact {
  @Form([
    Field('workLocation', String, 'Work Location',
        hint: 'Where they primarily work from'),
    Field('timeZone', String, 'Time Zone',
        hint: 'Their working time zone'),
    Field('contactEmail', String, 'Contact Email',
        hint: 'Email address to reach them'),
    Field('contactPhone', String, 'Contact Phone',
        hint: 'Phone number to reach them'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting and backup structure.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (governance, roles & responsibilities)',
  ],
  'This team member\'s reporting line and designated backup/deputy.',
)
@SectionId('TMMGV')
class TeamMemberEntryGovernance {
  @Form([
    Field('reportingTo', String, 'Reporting To',
        hint: 'Who this member reports to on the project'),
    Field('backup', String, 'Backup/Deputy',
        hint: 'Designated backup or deputy for this member'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Team member skills and certifications.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'PMBOK — develop team / skills management',
    'ISO 21500 — project management (resources)',
  ],
  'This team member\'s competencies: primary and secondary skills, '
  'certifications, domain expertise, and years of experience.',
)
@SectionId('TMMSK')
class TeamMemberSkills {
  @Form([
    Field('primarySkills', String, 'Primary Skills',
        hint: 'Their core, most-relied-on skills'),
    Field('secondarySkills', String, 'Secondary Skills',
        hint: 'Supporting or supplementary skills'),
    Field('certifications', String, 'Certifications',
        hint: 'Relevant professional certifications held'),
    Field('domainExpertise', String, 'Domain Expertise',
        hint: 'Business or technical domains they know well'),
    Field('yearsExperience', int, 'Years of Experience',
        hint: 'Total years of professional experience'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Individual skill entries.
  @StandardReferences(
    [
      'PMBOK — develop team / skills management',
      'ISO 21500 — project management (resources)',
    ],
    'The itemized skills of this team member, each with a proficiency level.',
  )
  @SectionId('TMSKE-SKIL-LST')
  @SectionIdPattern('TMSKE-SKIL-xxx')
  @ContentHelp('Add one entry per individual skill, with its proficiency level, '
      'years using it, and when it was last used.')
  @SerializationOrder(1)
  List<TeamMemberSkillEntry> skillDetails = [];
}

/// A skill entry with proficiency level.
@StandardReferences(
  [
    'PMBOK — develop team / skills management',
    'ISO 21500 — project management (resources)',
  ],
  'A single skill: its name, proficiency level, years used, and last-used date.',
)
@SectionId('TMSKE')
class TeamMemberSkillEntry {
  @Form([
    Field('skillName', String, 'Skill Name', required: true,
        hint: 'Name of the skill or competency'),
    Field('proficiencyLevel', String, 'Proficiency (Expert/Advanced/Intermediate/Beginner)',
        hint: 'Expert / Advanced / Intermediate / Beginner'),
    Field('yearsUsing', int, 'Years Using',
        hint: 'How many years they have used this skill'),
    Field('lastUsed', String, 'Last Used',
        hint: 'When the skill was most recently applied'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Team member availability constraints.
@StandardReferences(
  [
    'PMBOK — resource management (project team & staffing)',
    'ISO 21500 — project management (resources)',
  ],
  'This team member\'s availability: the window they are available, planned '
  'absences, working hours, constraints, and on-call requirements.',
)
@SectionId('TMMAV')
class TeamMemberAvailability {
  @Form([
    Field('availableFrom', String, 'Available From',
        hint: 'Date they become available'),
    Field('availableUntil', String, 'Available Until',
        hint: 'Date their availability ends'),
    Field('plannedAbsences', String, 'Planned Absences',
        hint: 'Known leave or absences during the project'),
    Field('workingHours', String, 'Working Hours',
        hint: 'Their normal working hours'),
    Field('constraints', String, 'Availability Constraints',
        hint: 'Any limits on when they can work'),
    Field('onCallRequirements', String, 'On-Call Requirements',
        hint: 'Any on-call duties expected of them'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A team member responsibility entry.
@StandardReferences(
  [
    'PMBOK — RACI / responsibility assignment',
    'ISO 21500 — project management (resources)',
  ],
  'A single team member responsibility: its area, description, key '
  'deliverables, and decision authority.',
)
@SectionId('TMMRP')
class TeamMemberResponsibilityEntry {
  @Form([
    Field('area', String, 'Responsibility Area', required: true,
        hint: 'Area of responsibility for this team member'),
    Field('description', String, 'Description',
        hint: 'What this responsibility entails'),
    Field('deliverables', String, 'Key Deliverables',
        hint: 'Outputs this member is accountable for'),
    Field('authority', String, 'Decision Authority',
        hint: 'Decisions this member can make in this area'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 3.3 Distribution List
// ---------------------------------------------------------------------------

/// 3.3. Distribution List.
///
/// Defines who receives which project documents and communications.
/// Includes the communication matrix specifying information flow patterns,
/// notification preferences, and access levels for different stakeholder groups.
@StandardReferences(
  [
    'PMBOK — communications management (stakeholder communication & distribution)',
    'ISO/IEC/IEEE 29148 — front matter (distribution list)',
  ],
  'Defines who receives which project documents and communications, '
  'including the communication matrix and stakeholder distribution groups.',
)
@SectionId('DSTLS')
class DistributionList {
  @ContentHelp('''
Overview of project communication and distribution approach.
Describe the different stakeholder groups, their information needs,
and how documents and updates are distributed. Define the communication
channels and frequency for different types of information.
''')
  @SerializationOrder(0)
  String? content;

  /// Communication matrix overview.
  @SerializationOrder(1)
  CommunicationMatrix communicationMatrix = CommunicationMatrix();

  /// 3.3.1. Full Distribution.
  @SerializationOrder(2)
  FullDistribution fullDistribution = FullDistribution();

  /// 3.3.2. Executive Summary.
  @SerializationOrder(3)
  ExecutiveSummaryDistribution executiveSummary = ExecutiveSummaryDistribution();

  /// 3.3.3. Custom Distribution Groups — contains 0+× Group.
  @StandardReferences(
    ['PMBOK — communications management (stakeholder communication & distribution)'],
    'The set of custom distribution groups defined for specific stakeholder needs.',
  )
  @SectionId('CSDSGR-CUST-LST')
  @SectionIdPattern('CSDSGR-CUST-xxx')
  @ContentHelp('Add one entry per custom distribution group, capturing its '
      'purpose, information scope, frequency, channel, and members.')
  @SerializationOrder(4)
  List<CustomDistributionGroup> customGroups = [];
}

/// Communication matrix defining stakeholder communication patterns.
@StandardReferences(
  [
    'PMBOK — plan communications management (communication methods)',
    'PMBOK — communications management (stakeholder communication & distribution)',
  ],
  'The communication matrix specifying channels, tools, and information flow '
  'patterns between stakeholder groups.',
)
@SectionId('COMA')
class CommunicationMatrix {
  @Form([
    Field('defaultCommunicationChannel', String, 'Default Communication Channel',
        hint: 'Primary channel for project communications — Email / Portal / Teams'),
    Field('documentRepository', String, 'Document Repository',
        hint: 'Location where project documents are stored'),
    Field('notificationTool', String, 'Notification Tool',
        hint: 'Tool used for notifications — Email / Slack / Teams'),
    Field('meetingPlatform', String, 'Meeting Platform',
        hint: 'Platform for virtual meetings'),
    Field('escalationChannel', String, 'Escalation Channel',
        hint: 'Channel for urgent escalations'),
    Field('languageOfCommunication', String, 'Language of Communication',
        hint: 'Primary language for project documents and communications'),
    Field('translationProcess', String, 'Translation Process',
        hint: 'How documents are translated for non-primary speakers'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Communication matrix diagram.
  @ContentType('mermaid', 'Diagram showing communication flows between '
      'stakeholder groups and information types')
  @SerializationOrder(1)
  String? communicationFlowDiagram;

  /// Communication types and their distribution rules.
  @StandardReferences(
    ['PMBOK — plan communications management (communication methods)'],
    'The set of communication types defined for the project, each with its '
    'own distribution rules.',
  )
  @SectionId('COTY-COMM-LST')
  @SectionIdPattern('COTY-COMM-xxx')
  @ContentHelp('Add one entry per communication type, capturing its frequency, '
      'format, distribution scope, responsible role, and approval requirements.')
  @SerializationOrder(2)
  List<CommunicationTypeEntry> communicationTypes = [];
}

/// A communication type with distribution rules.
@StandardReferences(
  ['PMBOK — plan communications management (communication methods)'],
  'A single communication type with its frequency, format, distribution '
  'scope, and approval rules.',
)
@SectionId('COTY')
class CommunicationTypeEntry {
  @Form([
    Field('communicationType', String, 'Communication Type',
        hint: 'Type of communication — StatusReport / MilestoneAlert / IssueNotification / MeetingMinutes / ChangeRequest', required: true),
    Field('description', String, 'Description',
        hint: 'What this communication type covers'),
    Field('frequency', String, 'Frequency',
        hint: 'Daily / Weekly / Bi-weekly / Monthly / Ad-hoc / Event-driven'),
    Field('format', String, 'Format',
        hint: 'Document / Email / Presentation / Dashboard'),
    Field('distributionScope', String, 'Distribution Scope',
        hint: 'All / Executive / Technical / Operations'),
    Field('responsibleRole', String, 'Responsible Role',
        hint: 'Who prepares this communication'),
    Field('approvalRequired', String, 'Approval Required',
        hint: 'None / Manager / SteeringCommittee'),
    Field('retentionPeriod', String, 'Retention Period',
        hint: 'How long to keep this communication'),
    Field('confidentialityLevel', String, 'Confidentiality Level',
        hint: 'Public / Internal / Confidential / Restricted'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Custom distribution group for specific stakeholder needs.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  'A custom distribution group with its own purpose, information scope, '
  'channel, and member list.',
)
@SectionId('CSDSGR')
class CustomDistributionGroup {
  @Form([
    Field('groupName', String, 'Group Name', required: true,
        hint: 'Name of the distribution group'),
    Field('purpose', String, 'Purpose',
        hint: 'Why this group exists'),
    Field('informationScope', String, 'Information Scope',
        hint: 'What information this group receives'),
    Field('frequency', String, 'Communication Frequency',
        hint: 'How often this group is contacted'),
    Field('primaryChannel', String, 'Primary Channel',
        hint: 'Main distribution channel for this group'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Group members.
  @StandardReferences(
    ['PMBOK — communications management (stakeholder communication & distribution)'],
    'The set of recipients belonging to this custom distribution group.',
  )
  @SectionId('DSRC-MEMB-LST')
  @SectionIdPattern('DSRC-MEMB-xxx')
  @ContentHelp('Add one entry per recipient in this group, capturing their '
      'role, contact information, preferences, and access levels.')
  @SerializationOrder(1)
  List<DistributionRecipientEntry> members = [];
}

/// 3.3.1. Full Distribution.
///
/// Recipients who receive all project documents and communications.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  'The full-distribution group: recipients who receive complete project '
  'documentation and all communications.',
)
@SectionId('FUDI')
class FullDistribution {
  @ContentHelp('''
List of stakeholders who receive complete project documentation.
These are typically core team members and key stakeholders who need
full visibility into all project activities and decisions.
''')
  @SerializationOrder(0)
  String? content;

  /// Full distribution summary.
  @SerializationOrder(1)
  DistributionGroupSummary groupSummary = DistributionGroupSummary();

  /// Contains 0+× DistributionRecipient.
  @StandardReferences(
    ['PMBOK — communications management (stakeholder communication & distribution)'],
    'The set of recipients in the full-distribution group.',
  )
  @SectionId('DSRC-ITEM-LST')
  @SectionIdPattern('DSRC-ITEM-xxx')
  @ContentHelp('Add one entry per full-distribution recipient, capturing their '
      'role, contact information, preferences, and access levels.')
  @SerializationOrder(2)
  List<DistributionRecipientEntry> items = [];
}

/// 3.3.2. Executive Summary Distribution.
///
/// Recipients who receive only executive summaries and milestone reports.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  'The executive-summary distribution group: recipients who receive only '
  'high-level summaries and milestone reports.',
)
@SectionId('EXSUDI')
class ExecutiveSummaryDistribution {
  @ContentHelp('''
List of stakeholders who receive executive summaries only.
These are typically senior executives and sponsors who need
high-level progress updates without operational details.
''')
  @SerializationOrder(0)
  String? content;

  /// Executive distribution summary.
  @SerializationOrder(1)
  DistributionGroupSummary groupSummary = DistributionGroupSummary();

  /// Contains 0+× DistributionRecipient.
  @StandardReferences(
    ['PMBOK — communications management (stakeholder communication & distribution)'],
    'The set of recipients in the executive-summary distribution group.',
  )
  @SectionId('DSRC-ITEM-LST')
  @SectionIdPattern('DSRC-ITEM-xxx')
  @ContentHelp('Add one entry per executive-summary recipient, capturing their '
      'role, contact information, preferences, and access levels.')
  @SerializationOrder(2)
  List<DistributionRecipientEntry> items = [];
}

/// Summary statistics for a distribution group.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  'Summary statistics for a distribution group, such as recipient counts, '
  'language, and default frequency.',
)
@SectionId('DIGRSU')
class DistributionGroupSummary {
  @Form([
    Field('recipientCount', int, 'Recipient Count',
        hint: 'Number of recipients in this group'),
    Field('internalCount', int, 'Internal Recipients',
        hint: 'Number of internal recipients'),
    Field('externalCount', int, 'External Recipients',
        hint: 'Number of external recipients'),
    Field('primaryLanguage', String, 'Primary Language',
        hint: 'Primary language of this group'),
    Field('distributionFrequency', String, 'Distribution Frequency',
        hint: 'Default frequency for this group'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A distribution recipient entry (form).
///
/// Detailed information about a distribution list recipient including
/// their role, contact information, preferences, and access levels.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  'A single distribution recipient with their contact details, preferences, '
  'access scope, subscription period, and backup arrangements.',
)
@SectionId('DSRC')
class DistributionRecipientEntry {
  @Form([
    Field('name', String, 'Name', required: true,
        hint: 'Full name of the recipient'),
    Field('role', String, 'Role',
        hint: 'Project or organizational role'),
    Field('organization', String, 'Organization',
        hint: 'Department or company'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Contact information.
  @SerializationOrder(1)
  DistributionRecipientContact contact = DistributionRecipientContact();

  /// Distribution preferences.
  @StandardReferences(
    ['PMBOK — communications management (stakeholder communication & distribution)'],
    'The set of distribution preferences recorded for this recipient.',
  )
  @SectionId('DIREPR-PREF-LST')
  @SectionIdPattern('DIREPR-PREF-xxx')
  @ContentHelp('Add one entry per preference set, capturing the distribution '
      'method, format, language, digest, and notification preferences.')
  @SerializationOrder(2)
  List<DistributionRecipientPreferences> preferences = [];

  /// Access and information scope.
  @SerializationOrder(3)
  DistributionRecipientAccess access = DistributionRecipientAccess();

  /// Subscription period.
  @SerializationOrder(4)
  DistributionRecipientSubscription subscription =
      DistributionRecipientSubscription();

  /// Backup and delegation.
  @SerializationOrder(5)
  DistributionRecipientBackup backup = DistributionRecipientBackup();
}

/// Contact information.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  'Contact information for a distribution recipient, including email, phone, '
  'and preferred contact method.',
)
@SectionId('DIRECO')
class DistributionRecipientContact {
  @Form([
    Field('jobTitle', String, 'Job Title',
        hint: "Recipient's job title"),
    Field('primaryEmail', String, 'Primary Email',
        hint: 'Primary email address for distribution'),
    Field('secondaryEmail', String, 'Secondary Email',
        hint: 'Backup email if primary is unavailable'),
    Field('phoneNumber', String, 'Phone Number',
        hint: 'Phone for urgent communications'),
    Field('preferredContactMethod', String, 'Preferred Contact Method',
        hint: 'Email / Phone / Teams / Slack'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Distribution preferences.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  "A recipient's distribution preferences: method, format, language, digest, "
  'and notification settings.',
)
@SectionId('DIREPR')
class DistributionRecipientPreferences {
  @Form([
    Field('distributionMethod', String, 'Distribution Method',
        hint: 'Email / Portal / Physical'),
    Field('preferredFormat', String, 'Preferred Format',
        hint: 'PDF / Word / HTML / Link'),
    Field('preferredLanguage', String, 'Preferred Language',
        hint: 'Language preference for documents'),
    Field('digestPreference', String, 'Digest Preference',
        hint: 'Individual / Daily Digest / Weekly Digest'),
    Field('notificationPreference', String, 'Notification Preference',
        hint: 'Immediate / Batched / Manual Check'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access and information scope.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  "A recipient's access level and information scope, including which "
  'categories and document sections they receive.',
)
@SectionId('DIREAC')
class DistributionRecipientAccess {
  @Form([
    Field('accessLevel', String, 'Access Level',
        hint: 'Full / Summary / Specific Sections'),
    Field('informationCategories', String, 'Information Categories',
        hint: 'Categories of information received'),
    Field('excludedCategories', String, 'Excluded Categories',
        hint: 'Categories explicitly excluded'),
    Field('documentSections', String, 'Document Sections',
        hint: 'Specific sections received if not full document'),
    Field('confidentialityCleared', String, 'Confidentiality Cleared',
        hint: 'Public / Internal / Confidential / Restricted'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Subscription period.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  "A recipient's subscription period to the distribution list, including "
  'start/end dates and status.',
)
@SectionId('DIRESU')
class DistributionRecipientSubscription {
  @Form([
    Field('subscriptionStartDate', String, 'Subscription Start Date',
        hint: 'When this recipient joined the distribution list'),
    Field('subscriptionEndDate', String, 'Subscription End Date',
        hint: 'When distribution ends — ongoing if blank'),
    Field('subscriptionStatus', String, 'Subscription Status',
        hint: 'Active / Paused / Ended'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup and delegation.
@StandardReferences(
  ['PMBOK — communications management (stakeholder communication & distribution)'],
  "A recipient's backup and delegation arrangements, including deputy and "
  'out-of-office handling.',
)
@SectionId('DIREBA')
class DistributionRecipientBackup {
  @Form([
    Field('deputyName', String, 'Deputy Name',
        hint: 'Person to contact when recipient is unavailable'),
    Field('outOfOfficeHandling', String, 'Out of Office Handling',
        hint: 'Forward to Deputy / Hold / Continue'),
    Field('specialInstructions', String, 'Special Instructions',
        hint: 'Any special distribution requirements'),
    Field('notes', String, 'Notes',
        hint: 'Additional notes about this recipient'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 3.4 Change Procedure
// ---------------------------------------------------------------------------

/// 3.4. Change Procedure.
///
/// Procedure for requesting, evaluating, and approving changes to this
/// Solution Blueprint and other project documents. Defines the change
/// control workflow, impact assessment criteria, and approval authorities.
@StandardReferences(
  [
    'ISO 9001:2015 §8.5.6 — control of changes',
    'ISO/IEC/IEEE 12207 — software life cycle (change management)',
    'PMBOK — perform integrated change control',
  ],
  'The root of §3.4: the end-to-end change-control procedure for project '
  'documents — how changes are requested, impact-assessed, decided by the '
  'control board, and categorised.',
)
@SectionId('CHPR')
class ChangeProcedure {
  @ContentHelp('''
Overview of the change management process for project documents.
Describe the philosophy for change control, when formal change requests
are required, and how the process balances agility with governance needs.
''')
  @SerializationOrder(0)
  String? content;

  /// Change procedure summary.
  @SerializationOrder(1)
  ChangeProcedureSummary summary = ChangeProcedureSummary();

  /// 3.4.1. Change Process.
  @SerializationOrder(2)
  ChangeProcess changeProcess = ChangeProcess();

  /// 3.4.2. Change Impact Criteria.
  @SerializationOrder(3)
  ChangeImpactCriteria changeImpactCriteria = ChangeImpactCriteria();

  /// 3.4.3. Change Control Board.
  @SerializationOrder(4)
  ChangeControlBoard changeControlBoard = ChangeControlBoard();

  /// 3.4.4. Change Categories — contains 0+× Category.
  @StandardReferences(
    ['ISO 9001:2015 §8.5.6 — control of changes'],
    'The set of change categories, each with its own handling and approval '
    'rules.',
  )
  @SectionId('CHCA-CHAN-LST')
  @SectionIdPattern('CHCA-CHAN-xxx')
  @ContentHelp('Add one entry per change category, capturing its scope, '
      'default handling, approval path, and documentation requirements.')
  @SerializationOrder(5)
  List<ChangeCategoryEntry> changeCategories = [];
}

/// Change procedure summary and metrics.
@StandardReferences(
  ['ISO 9001:2015 §8.5.6 — control of changes'],
  'At-a-glance facts about the change procedure — request format, submission '
  'channel, processing time, emergency path, freeze periods, and retroactive '
  'policy.',
)
@SectionId('CHPRSU')
class ChangeProcedureSummary {
  @Form([
    Field('changeRequestFormat', String, 'Change Request Format',
        hint: 'Form / Email / Ticket / Document'),
    Field('submissionChannel', String, 'Submission Channel',
        hint: 'How change requests are submitted'),
    Field('averageProcessingTime', String, 'Average Processing Time',
        hint: 'Typical time from submission to decision'),
    Field('emergencyChangeProcess', String, 'Emergency Change Process',
        hint: 'How urgent changes are expedited'),
    Field('changeFreezePeriods', String, 'Change Freeze Periods',
        hint: 'Periods when changes are restricted'),
    Field('retroactiveChangePolicy', String, 'Retroactive Change Policy',
        hint: 'How already-implemented changes are documented'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.4.1. Change Process.
///
/// Detailed workflow for change request processing from submission
/// through evaluation, approval, implementation, and closure.
@StandardReferences(
  [
    'ISO 9001:2015 §8.5.6 — control of changes',
    'ISO/IEC/IEEE 12207 — software life cycle (change management)',
  ],
  'The step-by-step change-request workflow — its steps, roles, decision '
  'criteria, and notification rules from submission through closure.',
)
@SectionId('CP')
class ChangeProcess {
  @ContentHelp('''
Detailed description of the change request workflow.
Describe each step from submission through closure, including
decision points, parallel activities, and notification triggers.
''')
  @Form([
    Field('processVersion', String, 'Process Version',
        hint: 'Version of this change process'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When this process became effective'),
    Field('approvalAuthority', String, 'Approval Authority',
        hint: 'Default authority for change decisions'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation path for disputed or complex changes'),
    Field('defaultSla', String, 'Default SLA',
        hint: 'Standard processing time commitment'),
    Field('trackingTool', String, 'Tracking Tool',
        hint: 'Tool used to track change requests'),
    Field('auditRequirements', String, 'Audit Requirements',
        hint: 'Documentation requirements for audit trail'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Overview diagram (e.g. Mermaid or image reference).
  @SerializationOrder(1)
  FlowDiagramSection overviewDiagram = FlowDiagramSection();

  /// Process steps — ordered list of change process steps — contains 0+× ChangeStep.
  @StandardReferences(
    ['ISO/IEC/IEEE 12207 — software life cycle (change management)'],
    'The ordered sequence of steps that make up the change-process workflow.',
  )
  @SectionId('CHST-STEP-LST')
  @SectionIdPattern('CHST-STEP-xxx')
  @ContentHelp('Add one entry per step in the change process, in execution '
      'order, capturing its responsibilities, artifacts, criteria, and '
      'decision paths.')
  @SerializationOrder(2)
  List<ChangeStepEntry> steps = [];

  /// Roles involved in the change process — contains 0+× ChangeRole.
  @StandardReferences(
    ['ISO 9001:2015 §8.5.6 — control of changes'],
    'The set of roles that participate in the change process and their '
    'authority.',
  )
  @SectionId('CHRO-ROLE-LST')
  @SectionIdPattern('CHRO-ROLE-xxx')
  @ContentHelp('Add one entry per role involved in the change process, '
      'capturing its responsibility, authority, and assignment.')
  @SerializationOrder(3)
  List<ChangeRoleEntry> roles = [];

  /// Decision criteria for change approval.
  @SerializationOrder(4)
  ChangeDecisionCriteria decisionCriteria = ChangeDecisionCriteria();

  /// Notification rules during change process.
  @StandardReferences(
    ['ISO 9001:2015 §8.5.6 — control of changes'],
    'The rules for who is notified at each event in the change process.',
  )
  @SectionId('CHNORU-NOTI-LST')
  @SectionIdPattern('CHNORU-NOTI-xxx')
  @ContentHelp('Add one entry per notification rule, capturing who is '
      'notified at each stage of the change process.')
  @SerializationOrder(5)
  List<ChangeNotificationRules> notificationRules = [];
}

/// Decision criteria for evaluating change requests.
@StandardReferences(
  [
    'PMBOK — perform integrated change control',
    'ISO 9001:2015 §8.5.6 — control of changes',
  ],
  'The weighted criteria used to score a change request and decide whether it '
  'requires steering-committee approval.',
)
@SectionId('CHDECR')
class ChangeDecisionCriteria {
  @Form([
    Field('scopeImpactWeight', int, 'Scope Impact Weight',
        hint: 'Weight for scope impact in decision — 0-100'),
    Field('scheduleImpactWeight', int, 'Schedule Impact Weight',
        hint: 'Weight for schedule impact — 0-100'),
    Field('budgetImpactWeight', int, 'Budget Impact Weight',
        hint: 'Weight for budget impact — 0-100'),
    Field('qualityImpactWeight', int, 'Quality Impact Weight',
        hint: 'Weight for quality impact — 0-100'),
    Field('riskImpactWeight', int, 'Risk Impact Weight',
        hint: 'Weight for risk impact — 0-100'),
    Field('approvalThreshold', String, 'Approval Threshold',
        hint: 'When combined score requires steering committee'),
    Field('vetoPower', String, 'Veto Power',
        hint: 'Who can veto an approved change'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Notification rules for change process events.
@StandardReferences(
  ['ISO 9001:2015 §8.5.6 — control of changes'],
  'A single notification rule: who is informed at each event in the change '
  'process — submission, assessment, approval, implementation, closure, and '
  'escalation.',
)
@SectionId('CHNORU')
class ChangeNotificationRules {
  @Form([
    Field('submissionNotification', String, 'Submission Notification',
        hint: 'Who is notified when a change is submitted'),
    Field('assessmentNotification', String, 'Assessment Notification',
        hint: 'Who is notified during assessment'),
    Field('approvalNotification', String, 'Approval Notification',
        hint: 'Who is notified of approval/rejection'),
    Field('implementationNotification', String, 'Implementation Notification',
        hint: 'Who is notified when change is implemented'),
    Field('closureNotification', String, 'Closure Notification',
        hint: 'Who is notified when change is closed'),
    Field('escalationNotification', String, 'Escalation Notification',
        hint: 'Who is notified on escalation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A role involved in the change process (form).
@StandardReferences(
  ['ISO 9001:2015 §8.5.6 — control of changes'],
  'A single change-process role: its responsibility, decision authority, '
  'required competencies, assignment, and backup.',
)
@SectionId('CHRO')
class ChangeRoleEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true,
        hint: 'Name of the role in change process'),
    Field('responsibility', String, 'Responsibility',
        hint: 'What this role does in the process'),
    Field('authority', String, 'Authority Level',
        hint: 'Decision authority this role has'),
    Field('requiredCompetencies', String, 'Required Competencies',
        hint: 'Skills needed for this role'),
    Field('assignedTo', String, 'Assigned To',
        hint: 'Person or team fulfilling this role'),
    Field('backup', String, 'Backup',
        hint: 'Backup person for this role'),
    Field('availabilityRequirement', String, 'Availability Requirement',
        hint: 'Response time expectation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A change process step entry (form).
///
/// Detailed description of a single step in the change process workflow.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — software life cycle (change management)'],
  'A single step in the change-process workflow: its responsibilities, input '
  'and output artifacts, entry/exit criteria, and decision paths.',
)
@SectionId('CHST')
class ChangeStepEntry {
  @Form([
    Field('stepNumber', int, 'Step Number',
        hint: 'Order of this step in the process', required: true),
    Field('stepName', String, 'Step Name', required: true,
        hint: 'Name of the process step'),
    Field('description', String, 'Description',
        hint: 'Detailed description of what happens in this step'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Responsibility assignments.
  @SerializationOrder(1)
  ChangeStepEntryResponsibility responsibility =
    ChangeStepEntryResponsibility();

  /// Inputs and outputs.
  @SerializationOrder(2)
  ChangeStepEntryArtifacts artifacts = ChangeStepEntryArtifacts();

  /// Criteria and timing.
  @SerializationOrder(3)
  ChangeStepEntryCriteria criteria = ChangeStepEntryCriteria();

  /// Decision paths.
  @SerializationOrder(4)
  ChangeStepEntryDecision decision = ChangeStepEntryDecision();

  /// Subflow diagram for this step (e.g. Mermaid or image reference).
  @SerializationOrder(5)
  FlowDiagramSection? subflowDiagram;
}

/// Responsibility assignments for change step.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — software life cycle (change management)'],
  'The RACI assignment for a change step — who is responsible, accountable, '
  'consulted, and informed.',
)
@SectionId('CSER')
class ChangeStepEntryResponsibility {
  @Form([
  Field('responsibleRole', String, 'Responsible Role',
    hint: 'Role responsible for executing this step'),
  Field('accountableRole', String, 'Accountable Role',
    hint: 'Role accountable for step completion'),
  Field('consultedRoles', String, 'Consulted Roles',
    hint: 'Roles consulted during this step'),
  Field('informedRoles', String, 'Informed Roles',
    hint: 'Roles informed of step completion'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Inputs and outputs for change step.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — software life cycle (change management)'],
  'The artifacts a change step consumes and produces, plus the tools it uses.',
)
@SectionId('CSEA')
class ChangeStepEntryArtifacts {
  @Form([
  Field('inputArtifacts', String, 'Input Artifacts',
    hint: 'Documents or data required to start this step'),
  Field('outputArtifacts', String, 'Output Artifacts',
    hint: 'Documents or decisions produced by this step'),
  Field('tools', String, 'Tools Used',
    hint: 'Tools or systems used in this step'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Criteria and timing for change step.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — software life cycle (change management)'],
  'The entry/exit conditions, approval criteria, and timing bounds that gate '
  'a change step.',
)
@SectionId('CSEC')
class ChangeStepEntryCriteria {
  @Form([
  Field('entryConditions', String, 'Entry Conditions',
    hint: 'Conditions that must be met to start this step'),
  Field('exitConditions', String, 'Exit Conditions',
    hint: 'Conditions that must be met to complete this step'),
  Field('approvalCriteria', String, 'Approval Criteria',
    hint: 'Criteria for approval decisions in this step'),
  Field('targetDuration', String, 'Target Duration',
    hint: 'Expected time to complete this step'),
  Field('maximumDuration', String, 'Maximum Duration',
    hint: 'Maximum allowed time before escalation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Decision paths for change step.
@StandardReferences(
  [
    'ISO/IEC/IEEE 12207 — software life cycle (change management)',
    'PMBOK — perform integrated change control',
  ],
  'The decision logic for a change step — whether a decision is required, its '
  'options, the next step per outcome, and escalation triggers.',
)
@SectionId('CSED')
class ChangeStepEntryDecision {
  @Form([
  Field('decisionRequired', String, 'Decision Required',
    hint: 'Yes / No — whether this step involves a decision'),
  Field('decisionOptions', String, 'Decision Options',
    hint: 'Possible outcomes of the decision'),
  Field('nextStepIfApproved', String, 'Next Step If Approved',
    hint: 'Where to go if decision is positive'),
  Field('nextStepIfRejected', String, 'Next Step If Rejected',
    hint: 'Where to go if decision is negative'),
  Field('escalationTrigger', String, 'Escalation Trigger',
    hint: 'What triggers escalation from this step'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.4.2. Change Impact Criteria.
///
/// Criteria for determining the impact level of change requests,
/// which drives the approval path and stakeholder involvement.
@StandardReferences(
  [
    'ISO/IEC/IEEE 12207 — change impact analysis',
    'ISO 9001:2015 §8.5.6 — control of changes',
  ],
  'The criteria and thresholds that classify a change as minor, moderate, '
  'major, or critical, driving its approval path and stakeholder involvement.',
)
@SectionId('CHIMC1')
class ChangeImpactCriteria {
  @ContentHelp('''
Criteria for assessing change impact across different dimensions.
Define thresholds that determine whether a change is minor, moderate,
major, or critical, and the corresponding approval requirements.
''')
  @SerializationOrder(0)
  String? content;

  /// Impact level definitions.
  @StandardReferences(
    ['ISO/IEC/IEEE 12207 — change impact analysis'],
    'The definitions of each impact level (minor/moderate/major/critical) and '
    'the approval each requires.',
  )
  @SectionId('IMLEDE-IMPA-LST')
  @SectionIdPattern('IMLEDE-IMPA-xxx')
  @ContentHelp('Add one entry per impact-level definition set, mapping each '
      'level to its threshold meaning and approval authority.')
  @SerializationOrder(1)
  List<ImpactLevelDefinitions> impactLevels = [];

  /// Contains 0+× ChangeImpactCriterion.
  @StandardReferences(
    ['ISO/IEC/IEEE 12207 — change impact analysis'],
    'The set of individual impact-assessment criteria, one per impact '
    'dimension.',
  )
  @SectionId('CHIMCR-ITEM-LST')
  @SectionIdPattern('CHIMCR-ITEM-xxx')
  @ContentHelp('Add one entry per impact criterion, capturing its thresholds, '
      'measurement method, approval rules, and weighting.')
  @SerializationOrder(2)
  List<ChangeImpactCriterionEntry> items = [];
}

/// Impact level definitions.
@StandardReferences(
  [
    'ISO/IEC/IEEE 12207 — change impact analysis',
    'ISO 9001:2015 §8.5.6 — control of changes',
  ],
  'A single set of impact-level definitions mapping minor, moderate, major, '
  'and critical changes to their meaning and approval authority.',
)
@SectionId('IMLEDE')
class ImpactLevelDefinitions {
  @Form([
    Field('minorDefinition', String, 'Minor Impact Definition',
        hint: 'What constitutes a minor change'),
    Field('minorApproval', String, 'Minor Approval',
        hint: 'Who approves minor changes'),
    Field('moderateDefinition', String, 'Moderate Impact Definition',
        hint: 'What constitutes a moderate change'),
    Field('moderateApproval', String, 'Moderate Approval',
        hint: 'Who approves moderate changes'),
    Field('majorDefinition', String, 'Major Impact Definition',
        hint: 'What constitutes a major change'),
    Field('majorApproval', String, 'Major Approval',
        hint: 'Who approves major changes'),
    Field('criticalDefinition', String, 'Critical Impact Definition',
        hint: 'What constitutes a critical change'),
    Field('criticalApproval', String, 'Critical Approval',
        hint: 'Who approves critical changes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A change impact criterion entry (form).
///
/// Detailed criterion for assessing change impact in a specific dimension.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — change impact analysis'],
  'A single impact-assessment criterion for one dimension — its thresholds, '
  'measurement, approval rules, and weighting.',
)
@SectionId('CHIMCR')
class ChangeImpactCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier for this criterion', required: true),
    Field('criterion', String, 'Criterion Name', required: true,
        hint: 'Name of the impact dimension'),
    Field('category', String, 'Category',
        hint: 'Scope / Schedule / Budget / Quality / Risk / Resource'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Threshold levels.
  @SerializationOrder(1)
  ChangeImpactCriterionEntryThresholds thresholds =
    ChangeImpactCriterionEntryThresholds();

  /// Measurement configuration.
  @SerializationOrder(2)
  ChangeImpactCriterionEntryMeasurement measurement =
    ChangeImpactCriterionEntryMeasurement();

  /// Approval path rules.
  @SerializationOrder(3)
  ChangeImpactCriterionEntryApproval approval =
    ChangeImpactCriterionEntryApproval();

  /// Weighting and supporting notes.
  @SerializationOrder(4)
  ChangeImpactCriterionEntryGovernance governance =
    ChangeImpactCriterionEntryGovernance();
}

/// Threshold levels for change impact.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — change impact analysis'],
  'The minor/moderate/major/critical threshold values for one impact '
  'criterion.',
)
@SectionId('CICET')
class ChangeImpactCriterionEntryThresholds {
  @Form([
  Field('description', String, 'Description',
    hint: 'Detailed description of this criterion'),
  Field('minorThreshold', String, 'Minor Threshold',
    hint: 'Threshold for minor impact — e.g. <5% budget'),
  Field('moderateThreshold', String, 'Moderate Threshold',
    hint: 'Threshold for moderate impact — e.g. 5-15% budget'),
  Field('majorThreshold', String, 'Major Threshold',
    hint: 'Threshold for major impact — e.g. 15-30% budget'),
  Field('criticalThreshold', String, 'Critical Threshold',
    hint: 'Threshold for critical impact — e.g. >30% budget'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Measurement configuration for change impact.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — change impact analysis'],
  'How one impact criterion is measured — method, unit, and baseline '
  'reference.',
)
@SectionId('CICEM')
class ChangeImpactCriterionEntryMeasurement {
  @Form([
  Field('measurementMethod', String, 'Measurement Method',
    hint: 'How this criterion is measured or assessed'),
  Field('measurementUnit', String, 'Measurement Unit',
    hint: 'Unit of measurement — Days / Percentage / Currency'),
  Field('baselineReference', String, 'Baseline Reference',
    hint: 'What baseline this is measured against'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Approval path rules for change impact.
@StandardReferences(
  [
    'ISO/IEC/IEEE 12207 — change impact analysis',
    'PMBOK — perform integrated change control',
  ],
  'The approval and escalation rules triggered when one impact criterion '
  'exceeds a threshold.',
)
@SectionId('CICEA')
class ChangeImpactCriterionEntryApproval {
  @Form([
  Field('approvalRequired', String, 'Approval Required',
    hint: 'Level of approval required based on impact'),
  Field('escalationRule', String, 'Escalation Rule',
    hint: 'When to escalate based on this criterion'),
  Field('notificationRequired', String, 'Notification Required',
    hint: 'Who must be notified if threshold is exceeded'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Weighting and supporting notes for change impact.
@StandardReferences(
  ['ISO/IEC/IEEE 12207 — change impact analysis'],
  'The weighting, mandatory flag, examples, and notes that govern how one '
  'impact criterion contributes to the overall assessment.',
)
@SectionId('CICEG')
class ChangeImpactCriterionEntryGovernance {
  @Form([
  Field('weight', int, 'Weight',
    hint: 'Relative weight in overall impact calculation — 0-100'),
  Field('mandatory', String, 'Mandatory',
    hint: 'Yes / No — whether this criterion must always be assessed'),
  Field('examples', String, 'Examples',
    hint: 'Examples of changes at different impact levels'),
  Field('notes', String, 'Notes',
    hint: 'Additional notes about this criterion'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.4.3. Change Control Board.
///
/// Governance body responsible for major change decisions.
@StandardReferences(
  [
    'PMBOK — perform integrated change control',
    'ISO 9001:2015 §8.5.6 — control of changes',
  ],
  'The governance body that decides on major changes — its composition, '
  'meeting cadence, voting rules, records, and membership.',
)
@SectionId('CHCOBO')
class ChangeControlBoard {
  @ContentHelp('''
Description of the Change Control Board composition, authority,
and operating procedures. Define meeting schedule, quorum requirements,
and decision-making rules.
''')
  @Form([
    Field('boardName', String, 'Board Name',
        hint: 'Official name of the change control board'),
    Field('purpose', String, 'Purpose',
        hint: 'Primary purpose and authority of the board'),
    Field('meetingFrequency', String, 'Meeting Frequency',
        hint: 'How often the board meets — Weekly / Bi-weekly / Monthly'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Regular meeting cadence details.
    @SerializationOrder(1)
    ChangeControlBoardMeetings meetings = ChangeControlBoardMeetings();

    /// Decision-making and emergency governance.
    @SerializationOrder(2)
    ChangeControlBoardGovernance governance = ChangeControlBoardGovernance();

    /// Decision record distribution.
    @SerializationOrder(3)
    ChangeControlBoardRecords records = ChangeControlBoardRecords();

  /// CCB members — contains 1+× CCB Member.
  @StandardReferences(
    ['PMBOK — perform integrated change control'],
    'The roster of Change Control Board members and their voting rights.',
  )
  @SectionId('CCME-MEMB-LST')
  @SectionIdPattern('CCME-MEMB-xxx')
  @ContentHelp('Add one entry per Change Control Board member, capturing their '
      'CCB role, voting rights, represented area, and substitute.')
  @Min(1)
  @SerializationOrder(4)
  List<CcbMemberEntry> members = [];
}

/// Regular meeting cadence details.
@StandardReferences(
  ['PMBOK — perform integrated change control'],
  'The regular meeting cadence of the Change Control Board — day, time, and '
  'duration.',
)
@SectionId('CCBM')
class ChangeControlBoardMeetings {
  @Form([
    Field('meetingDay', String, 'Meeting Day',
        hint: 'Day of week for regular meetings'),
    Field('meetingTime', String, 'Meeting Time',
        hint: 'Standard meeting time'),
    Field('meetingDuration', String, 'Meeting Duration',
        hint: 'Standard meeting duration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Decision-making and emergency governance.
@StandardReferences(
  ['PMBOK — perform integrated change control'],
  'The decision-making rules of the Change Control Board — quorum, voting, and '
  'emergency procedure.',
)
@SectionId('CCBG')
class ChangeControlBoardGovernance {
  @Form([
    Field('quorumRequirement', String, 'Quorum Requirement',
        hint: 'Minimum attendance for valid decisions'),
    Field('votingRules', String, 'Voting Rules',
        hint: 'How decisions are made — Consensus / Majority / Chair decides'),
    Field('emergencyProcedure', String, 'Emergency Procedure',
        hint: 'How emergency decisions are handled outside meetings'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Decision record distribution.
@StandardReferences(
  ['PMBOK — perform integrated change control'],
  'How Change Control Board decisions are recorded and distributed — minutes '
  'and decision log.',
)
@SectionId('CCBR')
class ChangeControlBoardRecords {
  @Form([
    Field('minutesDistribution', String, 'Minutes Distribution',
        hint: 'How meeting minutes are distributed'),
    Field('decisionLog', String, 'Decision Log',
        hint: 'Where decisions are recorded'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A CCB member entry.
@StandardReferences(
  ['PMBOK — perform integrated change control'],
  'A single Change Control Board member: their role, voting rights, '
  'represented area, substitute, and quorum requirement.',
)
@SectionId('CCME')
class CcbMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true,
        hint: 'Name of the CCB member'),
    Field('role', String, 'Role',
        hint: 'Role in the organization'),
    Field('ccbRole', String, 'CCB Role',
        hint: 'Role on the CCB — Chair / Vice-Chair / Secretary / Member'),
    Field('votingRights', String, 'Voting Rights',
        hint: 'Voting / Advisory / Observer'),
    Field('representedArea', String, 'Represented Area',
        hint: 'Area or stakeholder group represented'),
    Field('substitute', String, 'Substitute',
        hint: 'Designated substitute when unavailable'),
    Field('requiredForQuorum', String, 'Required for Quorum',
        hint: 'Yes / No — whether this member is required for quorum'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A change category entry.
///
/// Defines a category of changes with specific handling rules.
@StandardReferences(
  ['ISO 9001:2015 §8.5.6 — control of changes'],
  'A single change category: the changes it covers, its scope, default '
  'handling and approval path, and documentation requirements.',
)
@SectionId('CHCA')
class ChangeCategoryEntry {
  @Form([
    // Identification
    Field('categoryId', String, 'Category ID',
        hint: 'Unique identifier for this category', required: true),
    Field('categoryName', String, 'Category Name', required: true,
        hint: 'Name of the change category'),
    Field('description', String, 'Description',
        hint: 'What types of changes fall into this category'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope and example changes.
  @SerializationOrder(1)
  ChangeCategoryEntryScope scopeDetails = ChangeCategoryEntryScope();

  /// Default handling and approval path.
  @SerializationOrder(2)
  ChangeCategoryEntryHandling handling = ChangeCategoryEntryHandling();

  /// Documentation and special considerations.
  @SerializationOrder(3)
  ChangeCategoryEntryGovernance governance = ChangeCategoryEntryGovernance();
}

/// Scope and example changes.
@StandardReferences(
  ['ISO 9001:2015 §8.5.6 — control of changes'],
  'What a change category affects and representative examples of changes that '
  'fall into it.',
)
@SectionId('CCES')
class ChangeCategoryEntryScope {
  @Form([
  Field('scope', String, 'Scope',
    hint: 'What is affected — Scope / Schedule / Budget / Quality / Technical'),
  Field('examples', String, 'Examples',
    hint: 'Examples of changes in this category'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Default handling and approval path.
@StandardReferences(
  [
    'ISO 9001:2015 §8.5.6 — control of changes',
    'PMBOK — perform integrated change control',
  ],
  'The default handling for a change category — its typical impact level, '
  'approval path, expedited eligibility, and lead/processing times.',
)
@SectionId('CCEH')
class ChangeCategoryEntryHandling {
  @Form([
  Field('defaultImpactLevel', String, 'Default Impact Level',
    hint: 'Typical impact level — Minor / Moderate / Major / Critical'),
  Field('approvalPath', String, 'Approval Path',
    hint: 'Who approves changes in this category'),
  Field('expeditedProcessAllowed', String, 'Expedited Process Allowed',
    hint: 'Yes / No — whether fast-track is available'),
  Field('minimumLeadTime', String, 'Minimum Lead Time',
    hint: 'Minimum time needed for assessment'),
  Field('typicalProcessingTime', String, 'Typical Processing Time',
    hint: 'Normal time for change processing'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation and special considerations.
@StandardReferences(
  ['ISO 9001:2015 §8.5.6 — control of changes'],
  'The documentation, assessment depth, and special handling required for a '
  'change category.',
)
@SectionId('CCEG')
class ChangeCategoryEntryGovernance {
  @Form([
  Field('requiredDocumentation', String, 'Required Documentation',
    hint: 'Documents required for this category'),
  Field('impactAssessmentDepth', String, 'Impact Assessment Depth',
    hint: 'Checklist / Brief / Detailed / Full'),
  Field('specialConsiderations', String, 'Special Considerations',
    hint: 'Special handling requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 3.5 Reference Documents
// ---------------------------------------------------------------------------

// `ReferenceDocuments` (`RD`) and its subtree (`RFDOC`, `RDEM`, `RDEG`, `RDEL`,
// `DORESE`, `RESEEN`, `DORE`, `REDOEN`) were re-homed to SBP.1
// `DocumentControl` in L34C-5 (referenced documents are 29148 §6 front matter).

// ---------------------------------------------------------------------------
// 3.6 Other Administrative Requirements
// ---------------------------------------------------------------------------

/// 3.6. Legal and Contractual Requirements.
///
/// Additional administrative agreements, constraints, or requirements not
/// covered by other sections: IP ownership, NDAs, regulatory compliance,
/// audit requirements, and other legal or organizational agreements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 — front matter (legal & contractual constraints)',
    'ISO 9001:2015 — documented information (contractual requirements)',
  ],
  'The root of §3.6: gathers all administrative agreements and constraints — '
  'IP, confidentiality, regulatory compliance, audit, insurance, and other '
  'legal agreements — not covered by earlier sections.',
)
@ContentHelp('Document any additional administrative requirements not covered '
    'elsewhere. Include legal agreements, compliance obligations, and '
    'organizational constraints that affect project execution.')
@SectionId('LCR')
class LegalAndContractualRequirements {
  @ContentType('description', 'Overview of additional administrative '
      'requirements and their impact on the project.')
  @SerializationOrder(0)
  String? content;

  /// 3.6.1. Intellectual Property.
  @SerializationOrder(1)
  IntellectualPropertyRequirements intellectualProperty =
      IntellectualPropertyRequirements();

  /// 3.6.2. Confidentiality and NDAs.
  @SerializationOrder(2)
  ConfidentialityRequirements confidentiality = ConfidentialityRequirements();

  /// 3.6.3. Regulatory Compliance.
  @SerializationOrder(3)
  RegulatoryComplianceRequirements regulatoryCompliance =
      RegulatoryComplianceRequirements();

  /// 3.6.4. Audit Requirements.
  @SerializationOrder(4)
  AuditRequirements auditRequirements = AuditRequirements();

  /// 3.6.5. Insurance and Liability.
  @SerializationOrder(5)
  InsuranceLiabilityRequirements insuranceLiability =
      InsuranceLiabilityRequirements();

  /// 3.6.6. Other Agreements — contains 0+× Agreement.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 — front matter (legal & contractual constraints)',
      'ISO 9001:2015 — documented information (contractual requirements)',
    ],
    'The set of miscellaneous legal or organizational agreements binding the '
    'project that are not captured by the dedicated sections above.',
  )
  @SectionId('OTAGR-OTHE-LST')
  @SectionIdPattern('OTAGR-OTHE-xxx')
  @ContentHelp('Add one entry per additional agreement, capturing its title, '
      'type, parties, validity dates, key terms, obligations, and location.')
  @SerializationOrder(6)
  List<OtherAgreementEntry> otherAgreements = [];
}

/// 3.6.1. Intellectual Property Requirements.
///
/// Defines ownership and usage rights for project deliverables and IP.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security (intellectual-property protection)',
    'WIPO — intellectual-property rights (ownership & licensing)',
  ],
  'Defines who owns the intellectual property created during the project, the '
  'licensing terms, and how pre-existing IP is incorporated and protected.',
)
@ContentHelp('Specify who owns intellectual property created during the project, '
    'licensing terms, and any pre-existing IP that will be incorporated.')
@SectionId('IPR')
class IntellectualPropertyRequirements {
  @Form([
    Field('ownershipModel', String, 'Ownership Model',
        required: true, hint: 'How IP ownership is allocated between parties'),
    Field('preExistingIp', String, 'Pre-existing IP',
        hint: 'IP brought into the project by either party'),
    Field('licensingTerms', String, 'Licensing Terms',
        hint: 'Terms under which IP may be used or licensed'),
    Field('transferConditions', String, 'Transfer Conditions',
        hint: 'Conditions under which IP ownership transfers'),
  ])
  @SerializationOrder(0)
  String? content;

  /// IP ownership details — contains 0+× IP Ownership Entry.
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security (intellectual-property protection)',
      'WIPO — intellectual-property rights (ownership & licensing)',
    ],
    'The set of individual IP-ownership records detailing each asset, its '
    'owner, and the associated usage rights and restrictions.',
  )
  @SectionId('IPOWN-OWNE-LST')
  @SectionIdPattern('IPOWN-OWNE-xxx')
  @ContentHelp('Add one entry per IP asset, capturing its type, description, '
      'owner, usage rights, and restrictions.')
  @SerializationOrder(1)
  List<IpOwnershipEntry> ownershipDetails = [];
}

/// An IP ownership entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001 — information security (intellectual-property protection)',
    'WIPO — intellectual-property rights (ownership & licensing)',
  ],
  'A single IP-ownership record: the asset, its owner, and the usage rights '
  'and restrictions that apply to it.',
)
@SectionId('IPOWN')
class IpOwnershipEntry {
  @Form([
    Field('assetType', String, 'Asset Type', required: true,
        hint: 'Kind of IP asset, e.g. source code, design, trademark'),
    Field('assetDescription', String, 'Description',
        hint: 'What the asset is'),
    Field('owner', String, 'Owner',
        hint: 'Party that owns the asset'),
    Field('usageRights', String, 'Usage Rights',
        hint: 'How the asset may be used'),
    Field('restrictions', String, 'Restrictions',
        hint: 'Limits on use of the asset'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.2. Confidentiality and NDA Requirements.
///
/// Non-disclosure agreements and confidentiality constraints.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management (confidentiality)',
    'ISO/IEC 27002 — information security controls (data handling)',
  ],
  'Captures all non-disclosure agreements and confidentiality constraints — '
  'what information is confidential, for how long, and how it is handled.',
)
@ContentHelp('Document all NDA and confidentiality requirements, including '
    'what information is confidential, duration, and handling procedures.')
@SectionId('CR')
class ConfidentialityRequirements {
  @Form([
    Field('ndaType', String, 'NDA Type (Mutual/One-way)',
        hint: 'Whether the NDA is mutual or one-way'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When the confidentiality obligation begins'),
    Field('expirationDate', String, 'Expiration Date',
        hint: 'When the confidentiality obligation ends'),
    Field('governingLaw', String, 'Governing Law',
        hint: 'Jurisdiction governing the agreement'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Confidential information categories.
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security management (confidentiality)',
      'ISO/IEC 27002 — information security controls (data handling)',
    ],
    'The set of categories of confidential information, each with its '
    'classification level and handling rules.',
  )
  @SectionId('COINCA-CATE-LST')
  @SectionIdPattern('COINCA-CATE-xxx')
  @ContentHelp('Add one entry per category of confidential information, '
      'capturing its name, classification level, handling instructions, and '
      'authorized personnel.')
  @SerializationOrder(1)
  List<ConfidentialInfoCategoryEntry> categories = [];

  /// Data handling procedures.
  @SerializationOrder(2)
  DataHandlingProcedures dataHandling = DataHandlingProcedures();
}

/// A confidential information category.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management (confidentiality)',
    'ISO/IEC 27002 — information security controls (data handling)',
  ],
  'A single category of confidential information: its classification level, '
  'handling instructions, and who is authorized to access it.',
)
@SectionId('COINCA')
class ConfidentialInfoCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true,
        hint: 'Name of the confidential information category'),
    Field('description', String, 'Description',
        hint: 'What information falls into this category'),
    Field('classificationLevel', String, 'Classification Level',
        hint: 'Sensitivity level, e.g. Public, Internal, Confidential'),
    Field('handlingInstructions', String, 'Handling Instructions',
        hint: 'How this category must be stored, shared, and disposed of'),
    Field('authorizedPersonnel', String, 'Authorized Personnel',
        hint: 'Who may access this category of information'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data handling procedures for confidential information.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management (confidentiality)',
    'ISO/IEC 27002 — information security controls (data handling)',
  ],
  'Defines how confidential data must be stored, transmitted, destroyed, and '
  'how breaches are notified.',
)
@SectionId('DAHAPR')
class DataHandlingProcedures {
  @Form([
    Field('storageRequirements', String, 'Storage Requirements',
        hint: 'How confidential data must be stored'),
    Field('transmissionRequirements', String, 'Transmission Requirements',
        hint: 'How confidential data must be transmitted'),
    Field('destructionProcedure', String, 'Destruction Procedure',
        hint: 'How confidential data must be destroyed when no longer needed'),
    Field('breachNotificationProcess', String, 'Breach Notification Process',
        hint: 'Steps to follow if confidential data is breached'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.3. Regulatory Compliance Requirements.
///
/// Regulatory and compliance obligations affecting the project.
@StandardReferences(
  [
    'ISO/IEC 27001 — compliance with legal & contractual requirements',
    'ISO 37301 — compliance management systems',
  ],
  'Captures the regulatory and compliance obligations the project must meet, '
  'with their deadlines, evidence requirements, and compliance milestones.',
)
@ContentHelp('List all regulatory requirements the project must comply with, '
    'including deadlines, evidence requirements, and responsible parties.')
@SectionId('RCR')
class RegulatoryComplianceRequirements {
  @ContentType('description', 'Overview of regulatory landscape and '
      'compliance approach.')
  @SerializationOrder(0)
  String? content;

  /// Regulatory requirements — contains 0+× Regulatory Requirement.
  @StandardReferences(
    [
      'ISO/IEC 27001 — compliance with legal & contractual requirements',
      'ISO 37301 — compliance management systems',
    ],
    'The set of individual regulatory requirements the project must satisfy, '
    'each with its regulatory body, jurisdiction, deadline, and evidence.',
  )
  @SectionId('REGRQ-REQU-LST')
  @SectionIdPattern('REGRQ-REQU-xxx')
  @ContentHelp('Add one entry per regulation the project must comply with, '
      'capturing its regulatory body, jurisdiction, applicability, deadline, '
      'evidence required, responsible party, and penalties.')
  @SerializationOrder(1)
  List<RegulatoryRequirementEntry> requirements = [];

  /// Compliance milestones.
  @StandardReferences(
    [
      'ISO/IEC 27001 — compliance with legal & contractual requirements',
      'ISO 37301 — compliance management systems',
    ],
    'The set of dated compliance milestones tracking progress toward meeting '
    'the regulatory requirements.',
  )
  @SectionId('CPML-MILE-LST')
  @SectionIdPattern('CPML-MILE-xxx')
  @ContentHelp('Add one entry per compliance milestone, capturing its related '
      'regulation, due date, deliverables, verification method, and status.')
  @SerializationOrder(2)
  List<ComplianceMilestoneEntry> milestones = [];
}

/// A regulatory requirement entry.
@StandardReferences(
  [
    'ISO/IEC 27001 — compliance with legal & contractual requirements',
    'ISO 37301 — compliance management systems',
  ],
  'A single regulatory requirement: the regulation, its governing body and '
  'jurisdiction, applicability, deadline, required evidence, and penalties.',
)
@SectionId('REGRQ')
class RegulatoryRequirementEntry {
  @Form([
    Field('regulationName', String, 'Regulation Name', required: true,
        hint: 'Name of the regulation that applies'),
    Field('regulatoryBody', String, 'Regulatory Body',
        hint: 'Authority that issues and enforces the regulation'),
    Field('jurisdiction', String, 'Jurisdiction',
        hint: 'Geographic or legal scope where the regulation applies'),
    Field('applicability', String, 'Applicability',
        hint: 'Why and how the regulation applies to this project'),
    Field('complianceDeadline', String, 'Compliance Deadline',
        hint: 'When compliance must be achieved'),
    Field('evidenceRequired', String, 'Evidence Required',
        hint: 'Proof needed to demonstrate compliance'),
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Who is accountable for compliance'),
    Field('penaltyForNonCompliance', String, 'Penalty for Non-compliance',
        hint: 'Consequences of failing to comply'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A compliance milestone entry.
@StandardReferences(
  [
    'ISO/IEC 27001 — compliance with legal & contractual requirements',
    'ISO 37301 — compliance management systems',
  ],
  'A single compliance milestone: the regulation it relates to, its due date, '
  'deliverables, verification method, and current status.',
)
@SectionId('CPML')
class ComplianceMilestoneEntry {
  @Form([
    Field('milestoneName', String, 'Milestone Name', required: true,
        hint: 'Name of the compliance milestone'),
    Field('regulation', String, 'Related Regulation',
        hint: 'Regulation this milestone supports'),
    Field('dueDate', String, 'Due Date',
        hint: 'When the milestone must be completed'),
    Field('deliverables', String, 'Deliverables',
        hint: 'Outputs produced to meet the milestone'),
    Field('verificationMethod', String, 'Verification Method',
        hint: 'How milestone completion is verified'),
    Field('status', String, 'Status',
        hint: 'Current state of the milestone'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.4. Audit Requirements.
///
/// Internal and external audit obligations.
@StandardReferences(
  ['ISO 19011:2018 — guidelines for auditing management systems'],
  'Captures the internal and external audit obligations for the project — '
  'their scope, frequency, auditors, and evidence requirements.',
)
@ContentHelp('Document audit requirements including scope, frequency, '
    'auditor selection, and deliverable requirements.')
@SectionId('AR')
class AuditRequirements {
  @ContentType('description', 'Overview of audit requirements and approach.')
  @SerializationOrder(0)
  String? content;

  /// Planned audits — contains 0+× Audit Entry.
  @StandardReferences(
    ['ISO 19011:2018 — guidelines for auditing management systems'],
    'The set of planned audits for the project, each with its type, auditor, '
    'scope, schedule, and applicable standards.',
  )
  @SectionId('AUD-AUDI-LST')
  @SectionIdPattern('AUD-AUDI-xxx')
  @ContentHelp('Add one entry per planned audit, capturing its type, auditor, '
      'scope, planned date, frequency, and applicable standards.')
  @SerializationOrder(1)
  List<AuditEntry> audits = [];

  /// Audit evidence requirements.
  @SerializationOrder(2)
  AuditEvidenceRequirements evidenceRequirements = AuditEvidenceRequirements();
}

/// An audit entry.
@StandardReferences(
  ['ISO 19011:2018 — guidelines for auditing management systems'],
  'A single planned audit: its type, auditor, scope, schedule, frequency, and '
  'the standards it audits against.',
)
@SectionId('AUD')
class AuditEntry {
  @Form([
    Field('auditName', String, 'Audit Name', required: true,
        hint: 'Name of the audit'),
    Field('auditType', String, 'Type (Internal/External)',
        hint: 'Whether the audit is internal or external'),
    Field('auditor', String, 'Auditor',
        hint: 'Person or body conducting the audit'),
    Field('scope', String, 'Scope',
        hint: 'What the audit covers'),
    Field('plannedDate', String, 'Planned Date',
        hint: 'When the audit is scheduled'),
    Field('frequency', String, 'Frequency',
        hint: 'How often the audit recurs'),
    Field('standards', String, 'Applicable Standards',
        hint: 'Standards the audit assesses compliance against'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Audit evidence requirements.
@StandardReferences(
  ['ISO 19011:2018 — guidelines for auditing management systems'],
  'Defines what evidence audits require — documentation standards, retention '
  'periods, traceability, sign-off, and the types of evidence to be produced.',
)
@SectionId('AUEVRE')
class AuditEvidenceRequirements {
  @Form([
    Field('documentationStandards', String, 'Documentation Standards',
        hint: 'Standards audit evidence documentation must follow'),
    Field('retentionPeriod', String, 'Retention Period',
        hint: 'How long audit evidence must be retained'),
    Field('traceabilityRequirements', String, 'Traceability Requirements',
        hint: 'How evidence must trace back to requirements or activities'),
    Field('signoffRequirements', String, 'Sign-off Requirements',
        hint: 'Who must sign off on audit evidence'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Evidence types required.
  @StandardReferences(
    ['ISO 19011:2018 — guidelines for auditing management systems'],
    'The set of evidence types that audits require, each with its format and '
    'the role responsible for producing it.',
  )
  @SectionId('AUEVTY-EVID-LST')
  @SectionIdPattern('AUEVTY-EVID-xxx')
  @ContentHelp('Add one entry per type of audit evidence, capturing its '
      'description, required format, and responsible role.')
  @SerializationOrder(1)
  List<AuditEvidenceTypeEntry> evidenceTypes = [];
}

/// An audit evidence type entry.
@StandardReferences(
  ['ISO 19011:2018 — guidelines for auditing management systems'],
  'A single type of audit evidence: what it is, the format it must take, and '
  'the role responsible for producing it.',
)
@SectionId('AUEVTY')
class AuditEvidenceTypeEntry {
  @Form([
    Field('evidenceType', String, 'Evidence Type', required: true,
        hint: 'Kind of audit evidence, e.g. logs, reports, sign-offs'),
    Field('description', String, 'Description',
        hint: 'What this evidence demonstrates'),
    Field('format', String, 'Required Format',
        hint: 'Format the evidence must be provided in'),
    Field('responsibleRole', String, 'Responsible Role',
        hint: 'Role accountable for producing this evidence'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.5. Insurance and Liability Requirements.
///
/// Insurance coverage and liability agreements.
@StandardReferences(
  ['ISO 31000:2018 — risk management (liability & risk transfer)'],
  'Captures the insurance coverage the project requires and the liability '
  'limitations agreed between parties as a form of risk transfer.',
)
@ContentHelp('Document insurance requirements and liability limitations '
    'applicable to the project.')
@SectionId('ILR')
class InsuranceLiabilityRequirements {
  @ContentType('description', 'Overview of insurance and liability framework.')
  @SerializationOrder(0)
  String? content;

  /// Insurance requirements — contains 0+× Insurance Entry.
  @StandardReferences(
    ['ISO 31000:2018 — risk management (liability & risk transfer)'],
    'The set of insurance coverages the project requires, each with its type, '
    'minimum coverage, insured party, and validity.',
  )
  @SectionId('INSURE-INSU-LST')
  @SectionIdPattern('INSURE-INSU-xxx')
  @ContentHelp('Add one entry per insurance coverage, capturing its type, '
      'minimum coverage, insured party, policy holder, validity period, and '
      'whether a certificate is required.')
  @SerializationOrder(1)
  List<InsuranceEntry> insuranceRequirements = [];

  /// Liability limitations.
  @StandardReferences(
    ['ISO 31000:2018 — risk management (liability & risk transfer)'],
    'The set of liability limitations agreed for the project — caps, '
    'exclusions, indemnification, and damage limits.',
  )
  @SectionId('LILI-LIAB-LST')
  @SectionIdPattern('LILI-LIAB-xxx')
  @ContentHelp('Add one entry per liability limitation, capturing its maximum '
      'liability, exclusions, indemnification clauses, and limitation of '
      'damages.')
  @SerializationOrder(2)
  List<LiabilityLimitations> liabilityLimitations = [];
}

/// An insurance requirement entry.
@StandardReferences(
  ['ISO 31000:2018 — risk management (liability & risk transfer)'],
  'A single insurance coverage: its type, minimum coverage, insured party, '
  'policy holder, validity, and whether a certificate is required.',
)
@SectionId('INSURE')
class InsuranceEntry {
  @Form([
    Field('insuranceType', String, 'Insurance Type', required: true,
        hint: 'Kind of insurance, e.g. liability, professional indemnity'),
    Field('minimumCoverage', String, 'Minimum Coverage',
        hint: 'Minimum coverage amount required'),
    Field('insuredParty', String, 'Insured Party',
        hint: 'Party covered by the insurance'),
    Field('policyHolder', String, 'Policy Holder',
        hint: 'Party that holds the policy'),
    Field('validityPeriod', String, 'Validity Period',
        hint: 'Period during which the coverage is valid'),
    Field('certificateRequired', bool, 'Certificate Required',
        hint: 'Whether a certificate of insurance must be provided'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Liability limitations.
@StandardReferences(
  ['ISO 31000:2018 — risk management (liability & risk transfer)'],
  'A single liability limitation: the liability cap, exclusions, '
  'indemnification clauses, and limitation of damages agreed.',
)
@SectionId('LILI')
class LiabilityLimitations {
  @Form([
    Field('maxLiability', String, 'Maximum Liability',
        hint: 'Cap on total liability'),
    Field('exclusions', String, 'Exclusions',
        hint: 'Categories of loss excluded from liability'),
    Field('indemnificationClauses', String, 'Indemnification Clauses',
        hint: 'Terms under which one party indemnifies another'),
    Field('limitationOfDamages', String, 'Limitation of Damages',
        hint: 'Limits on the types or amounts of recoverable damages'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An other agreement entry.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 — front matter (legal & contractual constraints)',
    'ISO 9001:2015 — documented information (contractual requirements)',
  ],
  'A single miscellaneous agreement: its title, type, parties, validity dates, '
  'key terms, obligations, and where the document is stored.',
)
@SectionId('OTAGR')
class OtherAgreementEntry {
  @Form([
    Field('agreementTitle', String, 'Agreement Title', required: true,
        hint: 'Title of the agreement'),
    Field('agreementType', String, 'Type',
        hint: 'Kind of agreement, e.g. MOU, SLA, partnership'),
    Field('parties', String, 'Parties',
        hint: 'Parties bound by the agreement'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When the agreement takes effect'),
    Field('expirationDate', String, 'Expiration Date',
        hint: 'When the agreement expires'),
    Field('keyTerms', String, 'Key Terms',
        hint: 'Principal terms of the agreement'),
    Field('obligations', String, 'Obligations',
        hint: 'Obligations the agreement imposes'),
    Field('location', String, 'Document Location',
        hint: 'Where the signed agreement is stored'),
  ])
  @SerializationOrder(0)
  String? content;
}
