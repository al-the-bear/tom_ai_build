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
@SectionId('GOVMD')
class GovernanceModel {
  @Form([
    Field('decisionFramework', String, 'Decision-Making Framework'),
    Field('escalationPaths', String, 'Escalation Paths'),
    Field('meetingCadence', String, 'Meeting Cadence'),
    Field('reportingFrequency', String, 'Reporting Frequency'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Decision authority matrix.
  @SectionId('DCAUT-DECI-LST')
  @SectionIdPattern('DCAUT-DECI-xxx')
  @SerializationOrder(1)
  List<DecisionAuthorityEntry> decisionAuthorities = [];
}

/// A decision authority entry.
@SectionId('DCAUT')
class DecisionAuthorityEntry {
  @Form([
    Field('decisionArea', String, 'Decision Area', required: true),
    Field('authorityLevel', String, 'Authority Level'),
    Field('decisionMaker', String, 'Decision Maker'),
    Field('escalationTo', String, 'Escalation To'),
    Field('responseTime', String, 'Expected Response Time'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.1.2. Steering Committee.
///
/// Container for steering committee member descriptions.
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
  @SectionId('COMMB-MEMB-LST')
  @SectionIdPattern('COMMB-MEMB-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<CommitteeMemberEntry> members = [];
}

/// Committee charter defining rules and procedures.
@SectionId('COMCH')
class CommitteeCharter {
  @Form([
    Field('purpose', String, 'Purpose'),
    Field('meetingFrequency', String, 'Meeting Frequency'),
    Field('quorumRequirements', String, 'Quorum Requirements'),
    Field('votingRules', String, 'Voting Rules'),
    Field('minutesDistribution', String, 'Minutes Distribution'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A steering committee member entry (form).
///
/// Detailed information about a steering committee member.
@ContentHelp('Document each committee member with their organizational role, '
    'committee responsibilities, and decision authority.')
@SectionId('CME')
class CommitteeMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('organizationRole', String, 'Organization Role'),
    Field('department', String, 'Department'),
    Field('committeeRole', String, 'Committee Role'),
    Field('decisionAuthority', String, 'Decision Authority'),
    Field('delegationRules', String, 'Delegation Rules'),
    Field('meetingAttendance', String, 'Meeting Attendance (Mandatory/Optional)'),
    Field('contactInfo', String, 'Contact Information'),
    Field('substitute', String, 'Substitute/Deputy'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Specific responsibilities of this member.
  @SectionId('COMRS-RESP-LST')
  @SectionIdPattern('COMRS-RESP-xxx')
  @SerializationOrder(1)
  List<CommitteeResponsibilityEntry> responsibilities = [];
}

/// A committee member responsibility entry.
@SectionId('COMRS')
class CommitteeResponsibilityEntry {
  @Form([
    Field('area', String, 'Responsibility Area', required: true),
    Field('scope', String, 'Scope'),
    Field('escalationTo', String, 'Escalation To'),
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
  @SectionId('TMMBE-MEMB-LST')
  @SectionIdPattern('TMMBE-MEMB-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<TeamMemberEntry> members = [];

  /// Resource requirements not yet filled.
  @SectionId('RREQE-OPEN-LST')
  @SectionIdPattern('RREQE-OPEN-xxx')
  @SerializationOrder(3)
  List<ResourceRequirementEntry> openRequirements = [];
}

/// Team structure overview.
@SectionId('TMSOV')
class TeamStructureOverview {
  @Form([
    Field('teamSize', int, 'Total Team Size'),
    Field('internalResources', int, 'Internal Resources'),
    Field('externalResources', int, 'External Resources'),
    Field('teamLocationModel', String, 'Location Model (Co-located/Distributed/Hybrid)'),
    Field('coreHours', String, 'Core Working Hours'),
    Field('reportingStructure', String, 'Reporting Structure'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Team structure diagram.
  @SerializationOrder(1)
  DiagramSection teamDiagram = DiagramSection();
}

/// A resource requirement entry for unfilled positions.
@SectionId('RREQE')
class ResourceRequirementEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true),
    Field('skillsRequired', String, 'Required Skills'),
    Field('experience', String, 'Experience Level'),
    Field('allocation', String, 'Allocation'),
    Field('requiredBy', String, 'Required By Date'),
    Field('priority', String, 'Priority (Critical/High/Medium/Low)'),
    Field('status', String, 'Recruitment Status'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A team member entry (form).
///
/// Detailed information about a project team member including their role,
/// responsibilities, availability, and competencies.
@ContentHelp('Document each team member with their role, allocation, skills, '
    'and availability. Include contact information and backup arrangements.')
@SectionId('TMMBE')
class TeamMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('projectRole', String, 'Project Role', required: true),
    Field('organization', String, 'Organization/Department'),
    Field('jobTitle', String, 'Job Title'),
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
  @SectionId('TMMRP-RESP-LST')
  @SectionIdPattern('TMMRP-RESP-xxx')
  @SerializationOrder(6)
  List<TeamMemberResponsibilityEntry> responsibilities = [];
}

/// Allocation and scheduling details.
@SectionId('TMMAL')
class TeamMemberEntryAllocation {
  @Form([
    Field('allocation', String, 'Allocation Percentage'),
    Field('startDate', String, 'Start Date'),
    Field('endDate', String, 'End Date'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Work location and contact details.
@SectionId('TMMCO')
class TeamMemberEntryContact {
  @Form([
    Field('workLocation', String, 'Work Location'),
    Field('timeZone', String, 'Time Zone'),
    Field('contactEmail', String, 'Contact Email'),
    Field('contactPhone', String, 'Contact Phone'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting and backup structure.
@SectionId('TMMGV')
class TeamMemberEntryGovernance {
  @Form([
    Field('reportingTo', String, 'Reporting To'),
    Field('backup', String, 'Backup/Deputy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Team member skills and certifications.
@SectionId('TMMSK')
class TeamMemberSkills {
  @Form([
    Field('primarySkills', String, 'Primary Skills'),
    Field('secondarySkills', String, 'Secondary Skills'),
    Field('certifications', String, 'Certifications'),
    Field('domainExpertise', String, 'Domain Expertise'),
    Field('yearsExperience', int, 'Years of Experience'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Individual skill entries.
  @SectionId('TMSKE-SKIL-LST')
  @SectionIdPattern('TMSKE-SKIL-xxx')
  @SerializationOrder(1)
  List<TeamMemberSkillEntry> skillDetails = [];
}

/// A skill entry with proficiency level.
@SectionId('TMSKE')
class TeamMemberSkillEntry {
  @Form([
    Field('skillName', String, 'Skill Name', required: true),
    Field('proficiencyLevel', String, 'Proficiency (Expert/Advanced/Intermediate/Beginner)'),
    Field('yearsUsing', int, 'Years Using'),
    Field('lastUsed', String, 'Last Used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Team member availability constraints.
@SectionId('TMMAV')
class TeamMemberAvailability {
  @Form([
    Field('availableFrom', String, 'Available From'),
    Field('availableUntil', String, 'Available Until'),
    Field('plannedAbsences', String, 'Planned Absences'),
    Field('workingHours', String, 'Working Hours'),
    Field('constraints', String, 'Availability Constraints'),
    Field('onCallRequirements', String, 'On-Call Requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A team member responsibility entry.
@SectionId('TMMRP')
class TeamMemberResponsibilityEntry {
  @Form([
    Field('area', String, 'Responsibility Area', required: true),
    Field('description', String, 'Description'),
    Field('deliverables', String, 'Key Deliverables'),
    Field('authority', String, 'Decision Authority'),
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
  @SectionId('CSDSGR-CUST-LST')
  @SectionIdPattern('CSDSGR-CUST-xxx')
  @SerializationOrder(4)
  List<CustomDistributionGroup> customGroups = [];
}

/// Communication matrix defining stakeholder communication patterns.
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
  @SectionId('COTY-COMM-LST')
  @SectionIdPattern('COTY-COMM-xxx')
  @SerializationOrder(2)
  List<CommunicationTypeEntry> communicationTypes = [];
}

/// A communication type with distribution rules.
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
  @SectionId('DSRC-MEMB-LST')
  @SectionIdPattern('DSRC-MEMB-xxx')
  @SerializationOrder(1)
  List<DistributionRecipientEntry> members = [];
}

/// 3.3.1. Full Distribution.
///
/// Recipients who receive all project documents and communications.
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
  @SectionId('DSRC-ITEM-LST')
  @SectionIdPattern('DSRC-ITEM-xxx')
  @SerializationOrder(2)
  List<DistributionRecipientEntry> items = [];
}

/// 3.3.2. Executive Summary Distribution.
///
/// Recipients who receive only executive summaries and milestone reports.
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
  @SectionId('DSRC-ITEM-LST')
  @SectionIdPattern('DSRC-ITEM-xxx')
  @SerializationOrder(2)
  List<DistributionRecipientEntry> items = [];
}

/// Summary statistics for a distribution group.
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
  @SectionId('DIREPR-PREF-LST')
  @SectionIdPattern('DIREPR-PREF-xxx')
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
/// Project Definition and other project documents. Defines the change
/// control workflow, impact assessment criteria, and approval authorities.
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
  @SectionId('CHCA-CHAN-LST')
  @SectionIdPattern('CHCA-CHAN-xxx')
  @SerializationOrder(5)
  List<ChangeCategoryEntry> changeCategories = [];
}

/// Change procedure summary and metrics.
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
  @SectionId('CHST-STEP-LST')
  @SectionIdPattern('CHST-STEP-xxx')
  @SerializationOrder(2)
  List<ChangeStepEntry> steps = [];

  /// Roles involved in the change process — contains 0+× ChangeRole.
  @SectionId('CHRO-ROLE-LST')
  @SectionIdPattern('CHRO-ROLE-xxx')
  @SerializationOrder(3)
  List<ChangeRoleEntry> roles = [];

  /// Decision criteria for change approval.
  @SerializationOrder(4)
  ChangeDecisionCriteria decisionCriteria = ChangeDecisionCriteria();

  /// Notification rules during change process.
  @SectionId('CHNORU-NOTI-LST')
  @SectionIdPattern('CHNORU-NOTI-xxx')
  @SerializationOrder(5)
  List<ChangeNotificationRules> notificationRules = [];
}

/// Decision criteria for evaluating change requests.
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
  @SectionId('IMLEDE-IMPA-LST')
  @SectionIdPattern('IMLEDE-IMPA-xxx')
  @SerializationOrder(1)
  List<ImpactLevelDefinitions> impactLevels = [];

  /// Contains 0+× ChangeImpactCriterion.
  @SectionId('CHIMCR-ITEM-LST')
  @SectionIdPattern('CHIMCR-ITEM-xxx')
  @SerializationOrder(2)
  List<ChangeImpactCriterionEntry> items = [];
}

/// Impact level definitions.
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
  @SectionId('CCME-MEMB-LST')
  @SectionIdPattern('CCME-MEMB-xxx')
  @Min(1)
  @SerializationOrder(4)
  List<CcbMemberEntry> members = [];
}

/// Regular meeting cadence details.
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

/// 3.6. Other Administrative Requirements.
///
/// Additional administrative agreements, constraints, or requirements not
/// covered by other sections: IP ownership, NDAs, regulatory compliance,
/// audit requirements, and other legal or organizational agreements.
@ContentHelp('Document any additional administrative requirements not covered '
    'elsewhere. Include legal agreements, compliance obligations, and '
    'organizational constraints that affect project execution.')
@SectionId('OAR')
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
  @SectionId('OTAGR-OTHE-LST')
  @SectionIdPattern('OTAGR-OTHE-xxx')
  @SerializationOrder(6)
  List<OtherAgreementEntry> otherAgreements = [];
}

/// 3.6.1. Intellectual Property Requirements.
///
/// Defines ownership and usage rights for project deliverables and IP.
@ContentHelp('Specify who owns intellectual property created during the project, '
    'licensing terms, and any pre-existing IP that will be incorporated.')
@SectionId('IPR')
class IntellectualPropertyRequirements {
  @Form([
    Field('ownershipModel', String, 'Ownership Model',
        required: true),
    Field('preExistingIp', String, 'Pre-existing IP'),
    Field('licensingTerms', String, 'Licensing Terms'),
    Field('transferConditions', String, 'Transfer Conditions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// IP ownership details — contains 0+× IP Ownership Entry.
  @SectionId('IPOWN-OWNE-LST')
  @SectionIdPattern('IPOWN-OWNE-xxx')
  @SerializationOrder(1)
  List<IpOwnershipEntry> ownershipDetails = [];
}

/// An IP ownership entry (form).
@SectionId('IPOWN')
class IpOwnershipEntry {
  @Form([
    Field('assetType', String, 'Asset Type', required: true),
    Field('assetDescription', String, 'Description'),
    Field('owner', String, 'Owner'),
    Field('usageRights', String, 'Usage Rights'),
    Field('restrictions', String, 'Restrictions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.2. Confidentiality and NDA Requirements.
///
/// Non-disclosure agreements and confidentiality constraints.
@ContentHelp('Document all NDA and confidentiality requirements, including '
    'what information is confidential, duration, and handling procedures.')
@SectionId('CR')
class ConfidentialityRequirements {
  @Form([
    Field('ndaType', String, 'NDA Type (Mutual/One-way)'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('expirationDate', String, 'Expiration Date'),
    Field('governingLaw', String, 'Governing Law'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Confidential information categories.
  @SectionId('COINCA-CATE-LST')
  @SectionIdPattern('COINCA-CATE-xxx')
  @SerializationOrder(1)
  List<ConfidentialInfoCategoryEntry> categories = [];

  /// Data handling procedures.
  @SerializationOrder(2)
  DataHandlingProcedures dataHandling = DataHandlingProcedures();
}

/// A confidential information category.
@SectionId('COINCA')
class ConfidentialInfoCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Description'),
    Field('classificationLevel', String, 'Classification Level'),
    Field('handlingInstructions', String, 'Handling Instructions'),
    Field('authorizedPersonnel', String, 'Authorized Personnel'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data handling procedures for confidential information.
@SectionId('DAHAPR')
class DataHandlingProcedures {
  @Form([
    Field('storageRequirements', String, 'Storage Requirements'),
    Field('transmissionRequirements', String, 'Transmission Requirements'),
    Field('destructionProcedure', String, 'Destruction Procedure'),
    Field('breachNotificationProcess', String, 'Breach Notification Process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.3. Regulatory Compliance Requirements.
///
/// Regulatory and compliance obligations affecting the project.
@ContentHelp('List all regulatory requirements the project must comply with, '
    'including deadlines, evidence requirements, and responsible parties.')
@SectionId('RCR')
class RegulatoryComplianceRequirements {
  @ContentType('description', 'Overview of regulatory landscape and '
      'compliance approach.')
  @SerializationOrder(0)
  String? content;

  /// Regulatory requirements — contains 0+× Regulatory Requirement.
  @SectionId('REGRQ-REQU-LST')
  @SectionIdPattern('REGRQ-REQU-xxx')
  @SerializationOrder(1)
  List<RegulatoryRequirementEntry> requirements = [];

  /// Compliance milestones.
  @SectionId('CPML-MILE-LST')
  @SectionIdPattern('CPML-MILE-xxx')
  @SerializationOrder(2)
  List<ComplianceMilestoneEntry> milestones = [];
}

/// A regulatory requirement entry.
@SectionId('REGRQ')
class RegulatoryRequirementEntry {
  @Form([
    Field('regulationName', String, 'Regulation Name', required: true),
    Field('regulatoryBody', String, 'Regulatory Body'),
    Field('jurisdiction', String, 'Jurisdiction'),
    Field('applicability', String, 'Applicability'),
    Field('complianceDeadline', String, 'Compliance Deadline'),
    Field('evidenceRequired', String, 'Evidence Required'),
    Field('responsibleParty', String, 'Responsible Party'),
    Field('penaltyForNonCompliance', String, 'Penalty for Non-compliance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A compliance milestone entry.
@SectionId('CPML')
class ComplianceMilestoneEntry {
  @Form([
    Field('milestoneName', String, 'Milestone Name', required: true),
    Field('regulation', String, 'Related Regulation'),
    Field('dueDate', String, 'Due Date'),
    Field('deliverables', String, 'Deliverables'),
    Field('verificationMethod', String, 'Verification Method'),
    Field('status', String, 'Status'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.4. Audit Requirements.
///
/// Internal and external audit obligations.
@ContentHelp('Document audit requirements including scope, frequency, '
    'auditor selection, and deliverable requirements.')
@SectionId('AR')
class AuditRequirements {
  @ContentType('description', 'Overview of audit requirements and approach.')
  @SerializationOrder(0)
  String? content;

  /// Planned audits — contains 0+× Audit Entry.
  @SectionId('AUD-AUDI-LST')
  @SectionIdPattern('AUD-AUDI-xxx')
  @SerializationOrder(1)
  List<AuditEntry> audits = [];

  /// Audit evidence requirements.
  @SerializationOrder(2)
  AuditEvidenceRequirements evidenceRequirements = AuditEvidenceRequirements();
}

/// An audit entry.
@SectionId('AUD')
class AuditEntry {
  @Form([
    Field('auditName', String, 'Audit Name', required: true),
    Field('auditType', String, 'Type (Internal/External)'),
    Field('auditor', String, 'Auditor'),
    Field('scope', String, 'Scope'),
    Field('plannedDate', String, 'Planned Date'),
    Field('frequency', String, 'Frequency'),
    Field('standards', String, 'Applicable Standards'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Audit evidence requirements.
@SectionId('AUEVRE')
class AuditEvidenceRequirements {
  @Form([
    Field('documentationStandards', String, 'Documentation Standards'),
    Field('retentionPeriod', String, 'Retention Period'),
    Field('traceabilityRequirements', String, 'Traceability Requirements'),
    Field('signoffRequirements', String, 'Sign-off Requirements'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Evidence types required.
  @SectionId('AUEVTY-EVID-LST')
  @SectionIdPattern('AUEVTY-EVID-xxx')
  @SerializationOrder(1)
  List<AuditEvidenceTypeEntry> evidenceTypes = [];
}

/// An audit evidence type entry.
@SectionId('AUEVTY')
class AuditEvidenceTypeEntry {
  @Form([
    Field('evidenceType', String, 'Evidence Type', required: true),
    Field('description', String, 'Description'),
    Field('format', String, 'Required Format'),
    Field('responsibleRole', String, 'Responsible Role'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 3.6.5. Insurance and Liability Requirements.
///
/// Insurance coverage and liability agreements.
@ContentHelp('Document insurance requirements and liability limitations '
    'applicable to the project.')
@SectionId('ILR')
class InsuranceLiabilityRequirements {
  @ContentType('description', 'Overview of insurance and liability framework.')
  @SerializationOrder(0)
  String? content;

  /// Insurance requirements — contains 0+× Insurance Entry.
  @SectionId('INSURE-INSU-LST')
  @SectionIdPattern('INSURE-INSU-xxx')
  @SerializationOrder(1)
  List<InsuranceEntry> insuranceRequirements = [];

  /// Liability limitations.
  @SectionId('LILI-LIAB-LST')
  @SectionIdPattern('LILI-LIAB-xxx')
  @SerializationOrder(2)
  List<LiabilityLimitations> liabilityLimitations = [];
}

/// An insurance requirement entry.
@SectionId('INSURE')
class InsuranceEntry {
  @Form([
    Field('insuranceType', String, 'Insurance Type', required: true),
    Field('minimumCoverage', String, 'Minimum Coverage'),
    Field('insuredParty', String, 'Insured Party'),
    Field('policyHolder', String, 'Policy Holder'),
    Field('validityPeriod', String, 'Validity Period'),
    Field('certificateRequired', bool, 'Certificate Required'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Liability limitations.
@SectionId('LILI')
class LiabilityLimitations {
  @Form([
    Field('maxLiability', String, 'Maximum Liability'),
    Field('exclusions', String, 'Exclusions'),
    Field('indemnificationClauses', String, 'Indemnification Clauses'),
    Field('limitationOfDamages', String, 'Limitation of Damages'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An other agreement entry.
@SectionId('OTAGR')
class OtherAgreementEntry {
  @Form([
    Field('agreementTitle', String, 'Agreement Title', required: true),
    Field('agreementType', String, 'Type'),
    Field('parties', String, 'Parties'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('expirationDate', String, 'Expiration Date'),
    Field('keyTerms', String, 'Key Terms'),
    Field('obligations', String, 'Obligations'),
    Field('location', String, 'Document Location'),
  ])
  @SerializationOrder(0)
  String? content;
}
