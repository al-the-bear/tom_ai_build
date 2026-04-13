/// Section 3: Administrative [PD00-ADM].
///
/// Project administration: team, distribution, change procedure, references.
/// Covers organizational aspects of the project including governance structure,
/// staffing, communication channels, change management, and reference materials.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// 3. Administrative [PD00-ADM].
///
/// Project-specific administrative information including team composition,
/// distribution channels, procedural agreements, and reference documentation.
/// This section defines WHO is involved, HOW they communicate, and WHAT
/// procedures govern changes to project documentation.
@SectionId('PD00-ADM')
class Administrative {
  @ContentHelp('''
Executive summary of project administrative arrangements.
Describe the overall governance model, communication approach, and key
administrative agreements that govern this project. Highlight any deviations
from standard organizational project governance procedures.
''')
  String? content;

  /// Administrative overview summary.
  AdministrativeSummary summary = AdministrativeSummary();

  /// 3.1. Project Organization [PD00-ADM-PRO].
  ProjectOrganization projectOrganization = ProjectOrganization();

  /// 3.2. Project Team Staffing [PD00-ADM-TEA] — contains 1+× Team Member.
  ProjectTeamStaffing projectTeamStaffing = ProjectTeamStaffing();

  /// 3.3. Distribution List [PD00-ADM-DIS].
  DistributionList distributionList = DistributionList();

  /// 3.4. Change Procedure [PD00-ADM-CHA].
  ChangeProcedure changeProcedure = ChangeProcedure();

  /// 3.5. Reference Documents [PD00-ADM-REF] — contains 0+× Reference Document.
  ReferenceDocuments referenceDocuments = ReferenceDocuments();

  /// 3.6. Other Administrative Requirements [PD00-ADM-OTH].
  OtherAdministrativeRequirements otherAdministrative =
      OtherAdministrativeRequirements();
}

// ---------------------------------------------------------------------------
// 3.1 Project Organization
// ---------------------------------------------------------------------------

/// Administrative overview summary statistics.
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
  String? content;
}

/// 3.1. Project Organization [PD00-ADM-PRO].
@SectionId('PD00-ADM-PRO')
class ProjectOrganization {
  @ContentHelp('''
Overview of project organization structure including reporting lines,
steering committee composition, and governance arrangements.
Describe the organizational model and key decision-making paths.
''')
  String? content;

  /// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
  OrganizationStructure organizationStructure = OrganizationStructure();

  /// 3.1.2. Steering Committee [PD00-ADM-PRO-STE].
  SteeringCommittee steeringCommittee = SteeringCommittee();
}

/// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
@SectionId('PD00-ADM-PRO-STR')
class OrganizationStructure {
  @ContentType('description', 'Project organization chart with reporting '
      'lines, governance model, and escalation paths.')
  @ContentHelp('Insert project organization chart showing reporting lines. '
      'Describe the governance model: who decides what, escalation paths, '
      'meeting cadence.')
  String? content;

  /// Governance model details.
  GovernanceModel governanceModel = GovernanceModel();

  /// Organization chart diagram (e.g. Mermaid or image reference).
  DiagramSection orgChartDiagram = DiagramSection();
}

/// Governance model details.
class GovernanceModel {
  @Form([
    Field('decisionFramework', String, 'Decision-Making Framework'),
    Field('escalationPaths', String, 'Escalation Paths'),
    Field('meetingCadence', String, 'Meeting Cadence'),
    Field('reportingFrequency', String, 'Reporting Frequency'),
  ])
  String? content;

  /// Decision authority matrix.
  @SectionIdPattern('PD00-ADM-PRO-STR-DEC-xx')
  List<DecisionAuthorityEntry> decisionAuthorities = [];
}

/// A decision authority entry.
class DecisionAuthorityEntry {
  @Form([
    Field('decisionArea', String, 'Decision Area', required: true),
    Field('authorityLevel', String, 'Authority Level'),
    Field('decisionMaker', String, 'Decision Maker'),
    Field('escalationTo', String, 'Escalation To'),
    Field('responseTime', String, 'Expected Response Time'),
  ])
  String? content;
}

/// 3.1.2. Steering Committee [PD00-ADM-PRO-STE].
///
/// Container for steering committee member descriptions.
@SectionId('PD00-ADM-PRO-STE')
@ContentHelp('List all steering committee members with their roles, '
    'responsibilities, and decision authorities.')
class SteeringCommittee {
  @ContentType('description', 'Overview of steering committee composition '
      'and responsibilities.')
  String? content;

  /// Committee charter and rules.
  CommitteeCharter charter = CommitteeCharter();

  /// Steering committee members — contains 1+× Committee Member.
  @SectionIdPattern('PD00-ADM-PRO-STE-xx')
  @Min(1)
  List<CommitteeMemberEntry> members = [];
}

/// Committee charter defining rules and procedures.
class CommitteeCharter {
  @Form([
    Field('purpose', String, 'Purpose'),
    Field('meetingFrequency', String, 'Meeting Frequency'),
    Field('quorumRequirements', String, 'Quorum Requirements'),
    Field('votingRules', String, 'Voting Rules'),
    Field('minutesDistribution', String, 'Minutes Distribution'),
  ])
  String? content;
}

/// A steering committee member entry [PD00-ADM-PRO-STE-nn] (form).
///
/// Detailed information about a steering committee member.
@ContentHelp('Document each committee member with their organizational role, '
    'committee responsibilities, and decision authority.')
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
  String? content;

  /// Specific responsibilities of this member.
  List<CommitteeResponsibilityEntry> responsibilities = [];
}

/// A committee member responsibility entry.
class CommitteeResponsibilityEntry {
  @Form([
    Field('area', String, 'Responsibility Area', required: true),
    Field('scope', String, 'Scope'),
    Field('escalationTo', String, 'Escalation To'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.2 Project Team Staffing
// ---------------------------------------------------------------------------

/// 3.2. Project Team Staffing [PD00-ADM-TEA].
///
/// Container for individual staff assignments including roles, responsibilities,
/// availability, and required competencies.
@SectionId('PD00-ADM-TEA')
@ContentHelp('Document all team members assigned to the project with their '
    'roles, allocation percentages, and reporting relationships.')
class ProjectTeamStaffing {
  @ContentType('description', 'Overview of team structure, staffing approach, '
      'and resource planning considerations.')
  String? content;

  /// Team structure overview.
  TeamStructureOverview teamStructure = TeamStructureOverview();

  /// Team members — contains 1+× Team Member.
  @SectionIdPattern('PD00-ADM-TEA-xx')
  @Min(1)
  List<TeamMemberEntry> members = [];

  /// Resource requirements not yet filled.
  @SectionIdPattern('PD00-ADM-TEA-REQ-xx')
  List<ResourceRequirementEntry> openRequirements = [];
}

/// Team structure overview.
class TeamStructureOverview {
  @Form([
    Field('teamSize', int, 'Total Team Size'),
    Field('internalResources', int, 'Internal Resources'),
    Field('externalResources', int, 'External Resources'),
    Field('teamLocationModel', String, 'Location Model (Co-located/Distributed/Hybrid)'),
    Field('coreHours', String, 'Core Working Hours'),
    Field('reportingStructure', String, 'Reporting Structure'),
  ])
  String? content;

  /// Team structure diagram.
  DiagramSection teamDiagram = DiagramSection();
}

/// A resource requirement entry for unfilled positions.
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
  String? content;
}

/// A team member entry [PD00-ADM-TEA-nn] (form).
///
/// Detailed information about a project team member including their role,
/// responsibilities, availability, and competencies.
@ContentHelp('Document each team member with their role, allocation, skills, '
    'and availability. Include contact information and backup arrangements.')
class TeamMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('projectRole', String, 'Project Role', required: true),
    Field('organization', String, 'Organization/Department'),
    Field('jobTitle', String, 'Job Title'),
    Field('allocation', String, 'Allocation Percentage'),
    Field('startDate', String, 'Start Date'),
    Field('endDate', String, 'End Date'),
    Field('workLocation', String, 'Work Location'),
    Field('timeZone', String, 'Time Zone'),
    Field('contactEmail', String, 'Contact Email'),
    Field('contactPhone', String, 'Contact Phone'),
    Field('reportingTo', String, 'Reporting To'),
    Field('backup', String, 'Backup/Deputy'),
  ])
  String? content;

  /// Special skills and certifications.
  TeamMemberSkills skills = TeamMemberSkills();

  /// Availability constraints.
  TeamMemberAvailability availability = TeamMemberAvailability();

  /// Role-specific responsibilities.
  @SectionIdPattern('PD00-ADM-TEA-xx-RES-xx')
  List<TeamMemberResponsibilityEntry> responsibilities = [];
}

/// Team member skills and certifications.
class TeamMemberSkills {
  @Form([
    Field('primarySkills', String, 'Primary Skills'),
    Field('secondarySkills', String, 'Secondary Skills'),
    Field('certifications', String, 'Certifications'),
    Field('domainExpertise', String, 'Domain Expertise'),
    Field('yearsExperience', int, 'Years of Experience'),
  ])
  String? content;

  /// Individual skill entries.
  List<SkillEntry> skillDetails = [];
}

/// A skill entry with proficiency level.
class SkillEntry {
  @Form([
    Field('skillName', String, 'Skill Name', required: true),
    Field('proficiencyLevel', String, 'Proficiency (Expert/Advanced/Intermediate/Beginner)'),
    Field('yearsUsing', int, 'Years Using'),
    Field('lastUsed', String, 'Last Used'),
  ])
  String? content;
}

/// Team member availability constraints.
class TeamMemberAvailability {
  @Form([
    Field('availableFrom', String, 'Available From'),
    Field('availableUntil', String, 'Available Until'),
    Field('plannedAbsences', String, 'Planned Absences'),
    Field('workingHours', String, 'Working Hours'),
    Field('constraints', String, 'Availability Constraints'),
    Field('onCallRequirements', String, 'On-Call Requirements'),
  ])
  String? content;
}

/// A team member responsibility entry.
class TeamMemberResponsibilityEntry {
  @Form([
    Field('area', String, 'Responsibility Area', required: true),
    Field('description', String, 'Description'),
    Field('deliverables', String, 'Key Deliverables'),
    Field('authority', String, 'Decision Authority'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.3 Distribution List
// ---------------------------------------------------------------------------

/// 3.3. Distribution List [PD00-ADM-DIS].
///
/// Defines who receives which project documents and communications.
/// Includes the communication matrix specifying information flow patterns,
/// notification preferences, and access levels for different stakeholder groups.
@SectionId('PD00-ADM-DIS')
class DistributionList {
  @ContentHelp('''
Overview of project communication and distribution approach.
Describe the different stakeholder groups, their information needs,
and how documents and updates are distributed. Define the communication
channels and frequency for different types of information.
''')
  String? content;

  /// Communication matrix overview.
  CommunicationMatrix communicationMatrix = CommunicationMatrix();

  /// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
  FullDistribution fullDistribution = FullDistribution();

  /// 3.3.2. Executive Summary [PD00-ADM-DIS-EXE].
  ExecutiveSummaryDistribution executiveSummary = ExecutiveSummaryDistribution();

  /// 3.3.3. Custom Distribution Groups [PD00-ADM-DIS-CUS] — contains 0+× Group.
  @SectionIdPattern('PD00-ADM-DIS-CUS-xx')
  List<CustomDistributionGroup> customGroups = [];
}

/// Communication matrix defining stakeholder communication patterns.
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
  String? content;

  /// Communication matrix diagram.
  @ContentType('mermaid', 'Diagram showing communication flows between '
      'stakeholder groups and information types')
  String? communicationFlowDiagram;

  /// Communication types and their distribution rules.
  @SectionIdPattern('PD00-ADM-DIS-COM-xx')
  List<CommunicationTypeEntry> communicationTypes = [];
}

/// A communication type with distribution rules.
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
  String? content;
}

/// Custom distribution group for specific stakeholder needs.
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
  String? content;

  /// Group members.
  @SectionIdPattern('PD00-ADM-DIS-CUS-xx-MEM-xx')
  List<DistributionRecipientEntry> members = [];
}

/// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
///
/// Recipients who receive all project documents and communications.
@SectionId('PD00-ADM-DIS-FUL')
class FullDistribution {
  @ContentHelp('''
List of stakeholders who receive complete project documentation.
These are typically core team members and key stakeholders who need
full visibility into all project activities and decisions.
''')
  String? content;

  /// Full distribution summary.
  DistributionGroupSummary groupSummary = DistributionGroupSummary();

  /// Contains 0+× DistributionRecipient.
  @SectionIdPattern('PD00-ADM-DIS-FUL-xx')
  List<DistributionRecipientEntry> items = [];
}

/// 3.3.2. Executive Summary Distribution [PD00-ADM-DIS-EXE].
///
/// Recipients who receive only executive summaries and milestone reports.
@SectionId('PD00-ADM-DIS-EXE')
class ExecutiveSummaryDistribution {
  @ContentHelp('''
List of stakeholders who receive executive summaries only.
These are typically senior executives and sponsors who need
high-level progress updates without operational details.
''')
  String? content;

  /// Executive distribution summary.
  DistributionGroupSummary groupSummary = DistributionGroupSummary();

  /// Contains 0+× DistributionRecipient.
  @SectionIdPattern('PD00-ADM-DIS-EXE-xx')
  List<DistributionRecipientEntry> items = [];
}

/// Summary statistics for a distribution group.
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
  String? content;
}

/// A distribution recipient entry (form) [PD00-ADM-DIS-nn].
///
/// Detailed information about a distribution list recipient including
/// their role, contact information, preferences, and access levels.
class DistributionRecipientEntry {
  @Form([
    // Identity
    Field('name', String, 'Name', required: true,
        hint: 'Full name of the recipient'),
    Field('role', String, 'Role',
        hint: 'Project or organizational role'),
    Field('organization', String, 'Organization',
        hint: 'Department or company'),
    Field('jobTitle', String, 'Job Title',
        hint: "Recipient's job title"),

    // Contact Information
    Field('primaryEmail', String, 'Primary Email',
        hint: 'Primary email address for distribution'),
    Field('secondaryEmail', String, 'Secondary Email',
        hint: 'Backup email if primary is unavailable'),
    Field('phoneNumber', String, 'Phone Number',
        hint: 'Phone for urgent communications'),
    Field('preferredContactMethod', String, 'Preferred Contact Method',
        hint: 'Email / Phone / Teams / Slack'),

    // Distribution Preferences
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

    // Access and Information Scope
    Field('accessLevel', String, 'Access Level',
        hint: 'Full / Summary / Specific Sections'),
    Field('informationCategories', String, 'Information Categories',
        hint: 'Categories of information received — comma-separated'),
    Field('excludedCategories', String, 'Excluded Categories',
        hint: 'Categories explicitly excluded — comma-separated'),
    Field('documentSections', String, 'Document Sections',
        hint: 'Specific sections received if not full document'),
    Field('confidentialityCleared', String, 'Confidentiality Cleared',
        hint: 'Cleared levels — Public / Internal / Confidential / Restricted'),

    // Subscription Period
    Field('subscriptionStartDate', String, 'Subscription Start Date',
        hint: 'When this recipient joined the distribution list'),
    Field('subscriptionEndDate', String, 'Subscription End Date',
        hint: 'When distribution ends — ongoing if blank'),
    Field('subscriptionStatus', String, 'Subscription Status',
        hint: 'Active / Paused / Ended'),

    // Backup and Delegation
    Field('deputyName', String, 'Deputy Name',
        hint: 'Person to contact or copy when recipient is unavailable'),
    Field('outOfOfficeHandling', String, 'Out of Office Handling',
        hint: 'Forward to Deputy / Hold / Continue'),

    // Notes
    Field('specialInstructions', String, 'Special Instructions',
        hint: 'Any special distribution requirements'),
    Field('notes', String, 'Notes',
        hint: 'Additional notes about this recipient'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.4 Change Procedure
// ---------------------------------------------------------------------------

/// 3.4. Change Procedure [PD00-ADM-CHA].
///
/// Procedure for requesting, evaluating, and approving changes to this
/// Project Definition and other project documents. Defines the change
/// control workflow, impact assessment criteria, and approval authorities.
@SectionId('PD00-ADM-CHA')
class ChangeProcedure {
  @ContentHelp('''
Overview of the change management process for project documents.
Describe the philosophy for change control, when formal change requests
are required, and how the process balances agility with governance needs.
''')
  String? content;

  /// Change procedure summary.
  ChangeProcedureSummary summary = ChangeProcedureSummary();

  /// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
  ChangeProcess changeProcess = ChangeProcess();

  /// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
  ChangeImpactCriteria changeImpactCriteria = ChangeImpactCriteria();

  /// 3.4.3. Change Control Board [PD00-ADM-CHA-CCB].
  ChangeControlBoard changeControlBoard = ChangeControlBoard();

  /// 3.4.4. Change Categories [PD00-ADM-CHA-CAT] — contains 0+× Category.
  @SectionIdPattern('PD00-ADM-CHA-CAT-xx')
  List<ChangeCategoryEntry> changeCategories = [];
}

/// Change procedure summary and metrics.
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
  String? content;
}

/// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
///
/// Detailed workflow for change request processing from submission
/// through evaluation, approval, implementation, and closure.
@SectionId('PD00-ADM-CHA-PRO')
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
  String? content;

  /// Overview diagram (e.g. Mermaid or image reference).
  FlowDiagramSection overviewDiagram = FlowDiagramSection();

  /// Process steps — ordered list of change process steps — contains 0+× ChangeStep.
  @SectionIdPattern('PD00-ADM-CHA-PRO-STP-xx')
  List<ChangeStepEntry> steps = [];

  /// Roles involved in the change process — contains 0+× ChangeRole.
  @SectionIdPattern('PD00-ADM-CHA-PRO-ROL-xx')
  List<ChangeRoleEntry> roles = [];

  /// Decision criteria for change approval.
  ChangeDecisionCriteria decisionCriteria = ChangeDecisionCriteria();

  /// Notification rules during change process.
  ChangeNotificationRules notificationRules = ChangeNotificationRules();
}

/// Decision criteria for evaluating change requests.
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
  String? content;
}

/// Notification rules for change process events.
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
  String? content;
}

/// A role involved in the change process (form) [PD00-ADM-CHA-PRO-ROL-nn].
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
  String? content;
}

/// A change process step entry (form) [PD00-ADM-CHA-PRO-STP-nn].
///
/// Detailed description of a single step in the change process workflow.
class ChangeStepEntry {
  @Form([
    // Identification
    Field('stepNumber', int, 'Step Number',
        hint: 'Order of this step in the process', required: true),
    Field('stepName', String, 'Step Name', required: true,
        hint: 'Name of the process step'),
    Field('description', String, 'Description',
        hint: 'Detailed description of what happens in this step'),

    // Responsibility
    Field('responsibleRole', String, 'Responsible Role',
        hint: 'Role responsible for executing this step'),
    Field('accountableRole', String, 'Accountable Role',
        hint: 'Role accountable for step completion'),
    Field('consultedRoles', String, 'Consulted Roles',
        hint: 'Roles consulted during this step'),
    Field('informedRoles', String, 'Informed Roles',
        hint: 'Roles informed of step completion'),

    // Inputs and Outputs
    Field('inputArtifacts', String, 'Input Artifacts',
        hint: 'Documents or data required to start this step'),
    Field('outputArtifacts', String, 'Output Artifacts',
        hint: 'Documents or decisions produced by this step'),
    Field('tools', String, 'Tools Used',
        hint: 'Tools or systems used in this step'),

    // Criteria and Timing
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

    // Decision Points
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
  String? content;

  /// Subflow diagram for this step (e.g. Mermaid or image reference).
  FlowDiagramSection? subflowDiagram;
}

/// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
///
/// Criteria for determining the impact level of change requests,
/// which drives the approval path and stakeholder involvement.
@SectionId('PD00-ADM-CHA-CRI')
class ChangeImpactCriteria {
  @ContentHelp('''
Criteria for assessing change impact across different dimensions.
Define thresholds that determine whether a change is minor, moderate,
major, or critical, and the corresponding approval requirements.
''')
  String? content;

  /// Impact level definitions.
  ImpactLevelDefinitions impactLevels = ImpactLevelDefinitions();

  /// Contains 0+× ChangeImpactCriterion.
  @SectionIdPattern('PD00-ADM-CHA-CRI-xx')
  List<ChangeImpactCriterionEntry> items = [];
}

/// Impact level definitions.
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
  String? content;
}

/// A change impact criterion entry (form) [PD00-ADM-CHA-CRI-nn].
///
/// Detailed criterion for assessing change impact in a specific dimension.
class ChangeImpactCriterionEntry {
  @Form([
    // Identification
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier for this criterion', required: true),
    Field('criterion', String, 'Criterion Name', required: true,
        hint: 'Name of the impact dimension'),
    Field('description', String, 'Description',
        hint: 'Detailed description of this criterion'),
    Field('category', String, 'Category',
        hint: 'Scope / Schedule / Budget / Quality / Risk / Resource'),

    // Thresholds
    Field('minorThreshold', String, 'Minor Threshold',
        hint: 'Threshold for minor impact — e.g. <5% budget'),
    Field('moderateThreshold', String, 'Moderate Threshold',
        hint: 'Threshold for moderate impact — e.g. 5-15% budget'),
    Field('majorThreshold', String, 'Major Threshold',
        hint: 'Threshold for major impact — e.g. 15-30% budget'),
    Field('criticalThreshold', String, 'Critical Threshold',
        hint: 'Threshold for critical impact — e.g. >30% budget'),

    // Measurement
    Field('measurementMethod', String, 'Measurement Method',
        hint: 'How this criterion is measured or assessed'),
    Field('measurementUnit', String, 'Measurement Unit',
        hint: 'Unit of measurement — Days / Percentage / Currency'),
    Field('baselineReference', String, 'Baseline Reference',
        hint: 'What baseline this is measured against'),

    // Approval Path
    Field('approvalRequired', String, 'Approval Required',
        hint: 'Level of approval required based on impact'),
    Field('escalationRule', String, 'Escalation Rule',
        hint: 'When to escalate based on this criterion'),
    Field('notificationRequired', String, 'Notification Required',
        hint: 'Who must be notified if threshold is exceeded'),

    // Weighting
    Field('weight', int, 'Weight',
        hint: 'Relative weight in overall impact calculation — 0-100'),
    Field('mandatory', String, 'Mandatory',
        hint: 'Yes / No — whether this criterion must always be assessed'),

    // Notes
    Field('examples', String, 'Examples',
        hint: 'Examples of changes at different impact levels'),
    Field('notes', String, 'Notes',
        hint: 'Additional notes about this criterion'),
  ])
  String? content;
}

/// 3.4.3. Change Control Board [PD00-ADM-CHA-CCB].
///
/// Governance body responsible for major change decisions.
@SectionId('PD00-ADM-CHA-CCB')
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
    Field('meetingDay', String, 'Meeting Day',
        hint: 'Day of week for regular meetings'),
    Field('meetingTime', String, 'Meeting Time',
        hint: 'Standard meeting time'),
    Field('meetingDuration', String, 'Meeting Duration',
        hint: 'Standard meeting duration'),
    Field('quorumRequirement', String, 'Quorum Requirement',
        hint: 'Minimum attendance for valid decisions'),
    Field('votingRules', String, 'Voting Rules',
        hint: 'How decisions are made — Consensus / Majority / Chair decides'),
    Field('emergencyProcedure', String, 'Emergency Procedure',
        hint: 'How emergency decisions are handled outside meetings'),
    Field('minutesDistribution', String, 'Minutes Distribution',
        hint: 'How meeting minutes are distributed'),
    Field('decisionLog', String, 'Decision Log',
        hint: 'Where decisions are recorded'),
  ])
  String? content;

  /// CCB members — contains 1+× CCB Member.
  @SectionIdPattern('PD00-ADM-CHA-CCB-xx')
  @Min(1)
  List<CcbMemberEntry> members = [];
}

/// A CCB member entry.
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
  String? content;
}

/// A change category entry [PD00-ADM-CHA-CAT-nn].
///
/// Defines a category of changes with specific handling rules.
class ChangeCategoryEntry {
  @Form([
    // Identification
    Field('categoryId', String, 'Category ID',
        hint: 'Unique identifier for this category', required: true),
    Field('categoryName', String, 'Category Name', required: true,
        hint: 'Name of the change category'),
    Field('description', String, 'Description',
        hint: 'What types of changes fall into this category'),

    // Scope
    Field('scope', String, 'Scope',
        hint: 'What is affected — Scope / Schedule / Budget / Quality / Technical'),
    Field('examples', String, 'Examples',
        hint: 'Examples of changes in this category'),

    // Handling
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

    // Documentation
    Field('requiredDocumentation', String, 'Required Documentation',
        hint: 'Documents required for this category'),
    Field('impactAssessmentDepth', String, 'Impact Assessment Depth',
        hint: 'Checklist / Brief / Detailed / Full'),

    // Notes
    Field('specialConsiderations', String, 'Special Considerations',
        hint: 'Special handling requirements'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.5 Reference Documents
// ---------------------------------------------------------------------------

/// 3.5. Reference Documents [PD00-ADM-REF].
///
/// Catalog of all documents referenced by this project specification,
/// including enterprise standards, technical guidelines, regulatory
/// requirements, and related project documentation.
@SectionId('PD00-ADM-REF')
@ContentHelp('List all documents that provide context, requirements, '
    'constraints, or guidance for this project. Include enterprise '
    'architecture documents, standards, policies, regulations, '
    'and related project specifications.')
class ReferenceDocuments {
  @ContentType('description', 'Overview of reference document categories and '
      'their relevance to the project.')
  String? content;

  /// Reference document entries — contains 0+× Reference Document.
  @SectionIdPattern('PD00-ADM-REF-xx')
  List<ReferenceDocumentEntry> documents = [];
}

/// A reference document entry [PD00-ADM-REF-nn] (form).
///
/// Detailed metadata for a single referenced document including
/// identification, classification, status, and applicability.
class ReferenceDocumentEntry {
  @Form([
    Field('documentTitle', String, 'Document Title', required: true),
    Field('documentId', String, 'Document ID (internal reference number)'),
    Field('version', String, 'Version'),
    Field('author', String, 'Author / Issuing Organization'),
    Field('date', String, 'Publication / Effective Date'),
    Field('purpose', String, 'Purpose / Relevance to Project'),
    Field('location', String, 'Location (URL, repository, or physical)'),
    Field('documentType', String,
        'Document Type (Standard, Policy, Regulation, Specification, etc.)'),
    Field('classification', String,
        'Classification (Public, Internal, Confidential, Restricted)'),
    Field('status', String,
        'Status (Current, Draft, Under Review, Superseded, Archived)'),
    Field('applicability', String,
        'Applicability (which project phases or components this applies to)'),
    Field('supersedes', String, 'Supersedes Document (if replacing older doc)'),
    Field('supersededBy', String, 'Superseded By (if this doc is deprecated)'),
    Field('validUntil', String, 'Valid Until (expiration or review date)'),
    Field('lastReviewedDate', String, 'Last Reviewed Date'),
    Field('accessRestrictions', String,
        'Access Restrictions (who can access, special permissions required)'),
    Field('language', String, 'Language'),
    Field('format', String, 'Format (PDF, Word, HTML, Confluence, etc.)'),
    Field('notes', String, 'Additional Notes'),
  ])
  String? content;

  /// Key sections or chapters within the document relevant to this project.
  DocumentRelevantSections relevantSections = DocumentRelevantSections();

  /// Relationship to other reference documents.
  DocumentRelationships relationships = DocumentRelationships();
}

/// Key sections within a reference document relevant to the project.
class DocumentRelevantSections {
  @Form([
    Field('sectionReference', String,
        'Section Reference (chapter, section, or page number)', required: true),
    Field(
        'sectionTitle', String, 'Section Title or Description', required: true),
    Field('relevance', String, 'Relevance to Project'),
    Field('extractSummary', String,
        'Summary / Key Extract (brief summary of applicable content)'),
  ])
  String? content;

  /// Individual relevant section entries.
  List<RelevantSectionEntry> sections = [];
}

/// A single relevant section entry within a reference document.
class RelevantSectionEntry {
  @Form([
    Field('sectionReference', String,
        'Section Reference (chapter, section, or page number)', required: true),
    Field(
        'sectionTitle', String, 'Section Title or Description', required: true),
    Field('relevance', String,
        'Relevance (how this section applies to the project)'),
    Field('extractSummary', String,
        'Summary / Key Extract (brief summary of applicable content)'),
    Field('complianceRequired', bool,
        'Compliance Required (must project comply with this section?)'),
  ])
  String? content;
}

/// Relationships between reference documents.
class DocumentRelationships {
  @ContentType('description', 'Describe how this document relates to '
      'other reference documents in the catalog.')
  String? content;

  /// Related document entries.
  List<RelatedDocumentEntry> relatedDocuments = [];
}

/// A relationship to another reference document.
class RelatedDocumentEntry {
  @Form([
    Field('relatedDocumentId', String, 'Related Document ID', required: true),
    Field('relatedDocumentTitle', String, 'Related Document Title'),
    Field('relationshipType', String,
        'Relationship Type (Depends On, Referenced By, Supersedes, '
            'Complements, Conflicts With, Parent Of, Child Of)'),
    Field('relationshipDescription', String,
        'Relationship Description (explain the connection)'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.6 Other Administrative Requirements
// ---------------------------------------------------------------------------

/// 3.6. Other Administrative Requirements [PD00-ADM-OTH].
///
/// Additional administrative agreements, constraints, or requirements not
/// covered by other sections: IP ownership, NDAs, regulatory compliance,
/// audit requirements, and other legal or organizational agreements.
@SectionId('PD00-ADM-OTH')
@ContentHelp('Document any additional administrative requirements not covered '
    'elsewhere. Include legal agreements, compliance obligations, and '
    'organizational constraints that affect project execution.')
class OtherAdministrativeRequirements {
  @ContentType('description', 'Overview of additional administrative '
      'requirements and their impact on the project.')
  String? content;

  /// 3.6.1. Intellectual Property [PD00-ADM-OTH-IPR].
  IntellectualPropertyRequirements intellectualProperty =
      IntellectualPropertyRequirements();

  /// 3.6.2. Confidentiality and NDAs [PD00-ADM-OTH-NDA].
  ConfidentialityRequirements confidentiality = ConfidentialityRequirements();

  /// 3.6.3. Regulatory Compliance [PD00-ADM-OTH-REG].
  RegulatoryComplianceRequirements regulatoryCompliance =
      RegulatoryComplianceRequirements();

  /// 3.6.4. Audit Requirements [PD00-ADM-OTH-AUD].
  AuditRequirements auditRequirements = AuditRequirements();

  /// 3.6.5. Insurance and Liability [PD00-ADM-OTH-INS].
  InsuranceLiabilityRequirements insuranceLiability =
      InsuranceLiabilityRequirements();

  /// 3.6.6. Other Agreements [PD00-ADM-OTH-AGR] — contains 0+× Agreement.
  @SectionIdPattern('PD00-ADM-OTH-AGR-xx')
  List<OtherAgreementEntry> otherAgreements = [];
}

/// 3.6.1. Intellectual Property Requirements [PD00-ADM-OTH-IPR].
///
/// Defines ownership and usage rights for project deliverables and IP.
@SectionId('PD00-ADM-OTH-IPR')
@ContentHelp('Specify who owns intellectual property created during the project, '
    'licensing terms, and any pre-existing IP that will be incorporated.')
class IntellectualPropertyRequirements {
  @Form([
    Field('ownershipModel', String, 'Ownership Model',
        required: true),
    Field('preExistingIp', String, 'Pre-existing IP'),
    Field('licensingTerms', String, 'Licensing Terms'),
    Field('transferConditions', String, 'Transfer Conditions'),
  ])
  String? content;

  /// IP ownership details — contains 0+× IP Ownership Entry.
  @SectionIdPattern('PD00-ADM-OTH-IPR-xx')
  List<IpOwnershipEntry> ownershipDetails = [];
}

/// An IP ownership entry (form).
class IpOwnershipEntry {
  @Form([
    Field('assetType', String, 'Asset Type', required: true),
    Field('assetDescription', String, 'Description'),
    Field('owner', String, 'Owner'),
    Field('usageRights', String, 'Usage Rights'),
    Field('restrictions', String, 'Restrictions'),
  ])
  String? content;
}

/// 3.6.2. Confidentiality and NDA Requirements [PD00-ADM-OTH-NDA].
///
/// Non-disclosure agreements and confidentiality constraints.
@SectionId('PD00-ADM-OTH-NDA')
@ContentHelp('Document all NDA and confidentiality requirements, including '
    'what information is confidential, duration, and handling procedures.')
class ConfidentialityRequirements {
  @Form([
    Field('ndaType', String, 'NDA Type (Mutual/One-way)'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('expirationDate', String, 'Expiration Date'),
    Field('governingLaw', String, 'Governing Law'),
  ])
  String? content;

  /// Confidential information categories.
  @SectionIdPattern('PD00-ADM-OTH-NDA-xx')
  List<ConfidentialInfoCategoryEntry> categories = [];

  /// Data handling procedures.
  DataHandlingProcedures dataHandling = DataHandlingProcedures();
}

/// A confidential information category.
class ConfidentialInfoCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Description'),
    Field('classificationLevel', String, 'Classification Level'),
    Field('handlingInstructions', String, 'Handling Instructions'),
    Field('authorizedPersonnel', String, 'Authorized Personnel'),
  ])
  String? content;
}

/// Data handling procedures for confidential information.
class DataHandlingProcedures {
  @Form([
    Field('storageRequirements', String, 'Storage Requirements'),
    Field('transmissionRequirements', String, 'Transmission Requirements'),
    Field('destructionProcedure', String, 'Destruction Procedure'),
    Field('breachNotificationProcess', String, 'Breach Notification Process'),
  ])
  String? content;
}

/// 3.6.3. Regulatory Compliance Requirements [PD00-ADM-OTH-REG].
///
/// Regulatory and compliance obligations affecting the project.
@SectionId('PD00-ADM-OTH-REG')
@ContentHelp('List all regulatory requirements the project must comply with, '
    'including deadlines, evidence requirements, and responsible parties.')
class RegulatoryComplianceRequirements {
  @ContentType('description', 'Overview of regulatory landscape and '
      'compliance approach.')
  String? content;

  /// Regulatory requirements — contains 0+× Regulatory Requirement.
  @SectionIdPattern('PD00-ADM-OTH-REG-xx')
  List<RegulatoryRequirementEntry> requirements = [];

  /// Compliance milestones.
  @SectionIdPattern('PD00-ADM-OTH-REG-MIL-xx')
  List<ComplianceMilestoneEntry> milestones = [];
}

/// A regulatory requirement entry.
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
  String? content;
}

/// A compliance milestone entry.
class ComplianceMilestoneEntry {
  @Form([
    Field('milestoneName', String, 'Milestone Name', required: true),
    Field('regulation', String, 'Related Regulation'),
    Field('dueDate', String, 'Due Date'),
    Field('deliverables', String, 'Deliverables'),
    Field('verificationMethod', String, 'Verification Method'),
    Field('status', String, 'Status'),
  ])
  String? content;
}

/// 3.6.4. Audit Requirements [PD00-ADM-OTH-AUD].
///
/// Internal and external audit obligations.
@SectionId('PD00-ADM-OTH-AUD')
@ContentHelp('Document audit requirements including scope, frequency, '
    'auditor selection, and deliverable requirements.')
class AuditRequirements {
  @ContentType('description', 'Overview of audit requirements and approach.')
  String? content;

  /// Planned audits — contains 0+× Audit Entry.
  @SectionIdPattern('PD00-ADM-OTH-AUD-xx')
  List<AuditEntry> audits = [];

  /// Audit evidence requirements.
  AuditEvidenceRequirements evidenceRequirements = AuditEvidenceRequirements();
}

/// An audit entry.
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
  String? content;
}

/// Audit evidence requirements.
class AuditEvidenceRequirements {
  @Form([
    Field('documentationStandards', String, 'Documentation Standards'),
    Field('retentionPeriod', String, 'Retention Period'),
    Field('traceabilityRequirements', String, 'Traceability Requirements'),
    Field('signoffRequirements', String, 'Sign-off Requirements'),
  ])
  String? content;

  /// Evidence types required.
  @SectionIdPattern('PD00-ADM-OTH-AUD-EVI-xx')
  List<AuditEvidenceTypeEntry> evidenceTypes = [];
}

/// An audit evidence type entry.
class AuditEvidenceTypeEntry {
  @Form([
    Field('evidenceType', String, 'Evidence Type', required: true),
    Field('description', String, 'Description'),
    Field('format', String, 'Required Format'),
    Field('responsibleRole', String, 'Responsible Role'),
  ])
  String? content;
}

/// 3.6.5. Insurance and Liability Requirements [PD00-ADM-OTH-INS].
///
/// Insurance coverage and liability agreements.
@SectionId('PD00-ADM-OTH-INS')
@ContentHelp('Document insurance requirements and liability limitations '
    'applicable to the project.')
class InsuranceLiabilityRequirements {
  @ContentType('description', 'Overview of insurance and liability framework.')
  String? content;

  /// Insurance requirements — contains 0+× Insurance Entry.
  @SectionIdPattern('PD00-ADM-OTH-INS-xx')
  List<InsuranceEntry> insuranceRequirements = [];

  /// Liability limitations.
  LiabilityLimitations liabilityLimitations = LiabilityLimitations();
}

/// An insurance requirement entry.
class InsuranceEntry {
  @Form([
    Field('insuranceType', String, 'Insurance Type', required: true),
    Field('minimumCoverage', String, 'Minimum Coverage'),
    Field('insuredParty', String, 'Insured Party'),
    Field('policyHolder', String, 'Policy Holder'),
    Field('validityPeriod', String, 'Validity Period'),
    Field('certificateRequired', bool, 'Certificate Required'),
  ])
  String? content;
}

/// Liability limitations.
class LiabilityLimitations {
  @Form([
    Field('maxLiability', String, 'Maximum Liability'),
    Field('exclusions', String, 'Exclusions'),
    Field('indemnificationClauses', String, 'Indemnification Clauses'),
    Field('limitationOfDamages', String, 'Limitation of Damages'),
  ])
  String? content;
}

/// An other agreement entry.
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
  String? content;
}
