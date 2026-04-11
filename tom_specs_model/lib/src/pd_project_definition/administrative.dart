/// Section 3: Administrative [PD00-ADM].
///
/// Project administration: team, distribution, change procedure, references.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 3. Administrative [PD00-ADM].
@SectionId('PD00-ADM')
class Administrative {
  @Unused()
  String? content;

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

/// 3.1. Project Organization [PD00-ADM-PRO].
@SectionId('PD00-ADM-PRO')
class ProjectOrganization {
  @Unused()
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
@SectionId('PD00-ADM-DIS')
class DistributionList {
  @Unused()
  String? content;

  /// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
  FullDistribution fullDistribution = FullDistribution();

  /// 3.3.2. Executive Summary [PD00-ADM-DIS-EXE].
  ExecutiveSummaryDistribution executiveSummary = ExecutiveSummaryDistribution();
}

/// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
@SectionId('PD00-ADM-DIS-FUL')
class FullDistribution {
  @Unused()
  String? content;

  /// Contains 0+× DistributionRecipient.
  @SectionIdPattern('PD00-ADM-DIS-FUL-xx')
  List<DistributionRecipientEntry> items = [];
}

/// 3.3.2. Executive Summary Distribution [PD00-ADM-DIS-EXE].
@SectionId('PD00-ADM-DIS-EXE')
class ExecutiveSummaryDistribution {
  @Unused()
  String? content;

  /// Contains 0+× DistributionRecipient.
  @SectionIdPattern('PD00-ADM-DIS-EXE-xx')
  List<DistributionRecipientEntry> items = [];
}

/// A distribution recipient entry (form) [PD00-ADM-DIS-nn].
class DistributionRecipientEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('role', String, 'Role'),
    Field('organization', String, 'Organization'),
    Field('distributionMethod', String, 'Distribution Method'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.4 Change Procedure
// ---------------------------------------------------------------------------

/// 3.4. Change Procedure [PD00-ADM-CHA].
@SectionId('PD00-ADM-CHA')
class ChangeProcedure {
  @Unused()
  String? content;

  /// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
  ChangeProcess changeProcess = ChangeProcess();

  /// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
  ChangeImpactCriteria changeImpactCriteria = ChangeImpactCriteria();
}

/// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
@SectionId('PD00-ADM-CHA-PRO')
class ChangeProcess {
  @Form([
    Field('approvalAuthority', String, 'Approval Authority'),
    Field('escalationPath', String, 'Escalation Path'),
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

}

/// A role involved in the change process (form) [PD00-ADM-CHA-PRO-ROL-nn].
class ChangeRoleEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true),
    Field('responsibility', String, 'Responsibility'),
  ])
  String? content;
}

/// A change process step entry (form) [PD00-ADM-CHA-PRO-STP-nn].
class ChangeStepEntry {
  @Form([
    Field('stepName', String, 'Step Name', required: true),
    Field('description', String, 'Short description'),
    Field('responsibleRole', String, 'Responsible Role'),
    Field('inputArtifacts', String, 'Input Artifacts'),
    Field('outputArtifacts', String, 'Output Artifacts'),
    Field('approvalCriteria', String, 'Approval Criteria'),
  ])
  String? content;

  /// Subflow diagram for this step (e.g. Mermaid or image reference).
  FlowDiagramSection? subflowDiagram;
}

/// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
@SectionId('PD00-ADM-CHA-CRI')
class ChangeImpactCriteria {
  @Unused()
  String? content;

  /// Contains 0+× ChangeImpactCriterion.
  @SectionIdPattern('PD00-ADM-CHA-CRI-xx')
  List<ChangeImpactCriterionEntry> items = [];
}

/// A change impact criterion entry (form) [PD00-ADM-CHA-CRI-nn].
class ChangeImpactCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('impactLevel', String, 'Impact Level'),
    Field('description', String, 'Short description'),
    Field('approvalRequired', String, 'Approval Required'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.5 Reference Documents
// ---------------------------------------------------------------------------

/// 3.5. Reference Documents [PD00-ADM-REF].
@SectionId('PD00-ADM-REF')
class ReferenceDocuments {
  @Unused()
  String? content;

  /// Reference document entries — contains 0+× Reference Document.
  @SectionIdPattern('PD00-ADM-REF-xx')
  List<ReferenceDocumentEntry> documents = [];
}

/// A reference document entry [PD00-ADM-REF-nn] (form).
class ReferenceDocumentEntry {
  @Form([
    Field('documentTitle', String, 'Document Title', required: true),
    Field('version', String, 'Version'),
    Field('author', String, 'Author'),
    Field('date', String, 'Date'),
    Field('purpose', String, 'Purpose'),
    Field('location', String, 'Location'),
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
