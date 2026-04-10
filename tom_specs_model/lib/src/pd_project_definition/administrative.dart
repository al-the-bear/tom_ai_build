/// Section 3: Administrative [PD00-ADM].
///
/// Project administration: team, distribution, change procedure, references.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 3. Administrative [PD00-ADM].
class Administrative {
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

  /// Other Administrative.
  TextSection otherAdministrative = TextSection();
}

// ---------------------------------------------------------------------------
// 3.1 Project Organization
// ---------------------------------------------------------------------------

/// 3.1. Project Organization [PD00-ADM-PRO].
class ProjectOrganization {
  String? content;

  /// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
  OrganizationStructure organizationStructure = OrganizationStructure();

  /// 3.1.2. Steering Committee [PD00-ADM-PRO-STE] — contains 1+× Member.
  List<CommitteeMemberEntry> steeringCommittee = [];
}

/// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
class OrganizationStructure {
  String? content;

  /// Org Chart Explanation.
  TextSection orgChartExplanation = TextSection();

  /// Organization chart diagram (e.g. Mermaid or image reference).
  DiagramSection orgChartDiagram = DiagramSection();
}

/// A steering committee member entry [PD00-ADM-PRO-STE-nn] (form).
class CommitteeMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('organizationRole', String, 'Organization Role'),
    Field('committeeRole', String, 'Committee Role'),
    Field('decisionAuthority', String, 'Decision Authority'),
    Field('meetingAttendance', String, 'Meeting Attendance'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.2 Project Team Staffing
// ---------------------------------------------------------------------------

/// 3.2. Project Team Staffing [PD00-ADM-TEA].
class ProjectTeamStaffing {
  String? content;

  /// Team members — contains 1+× Team Member.
  List<TeamMemberEntry> members = [];
}

/// A team member entry [PD00-ADM-TEA-nn] (form).
class TeamMemberEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('projectRole', String, 'Project Role'),
    Field('organization', String, 'Organization'),
    Field('allocation', String, 'Allocation'),
    Field('startDate', String, 'Start Date'),
    Field('endDate', String, 'End Date'),
    Field('specialSkills', String, 'Special Skills'),
    Field('reportingTo', String, 'Reporting To'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 3.3 Distribution List
// ---------------------------------------------------------------------------

/// 3.3. Distribution List [PD00-ADM-DIS].
class DistributionList {
  String? content;

  /// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
  FullDistribution fullDistribution = FullDistribution();

  /// 3.3.2. Executive Summary [PD00-ADM-DIS-EXE].
  ExecutiveSummaryDistribution executiveSummary = ExecutiveSummaryDistribution();
}

/// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
class FullDistribution {
  String? content;
  /// Contains 0+× DistributionRecipient.
  List<DistributionRecipientEntry> items = [];
}

/// 3.3.2. Executive Summary Distribution [PD00-ADM-DIS-EXE].
class ExecutiveSummaryDistribution {
  String? content;
  /// Contains 0+× DistributionRecipient.
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
class ChangeProcedure {
  String? content;

  /// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
  ChangeProcess changeProcess = ChangeProcess();

  /// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
  ChangeImpactCriteria changeImpactCriteria = ChangeImpactCriteria();
}

/// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
class ChangeProcess {
  @Form([
    Field('approvalAuthority', String, 'Approval Authority'),
    Field('escalationPath', String, 'Escalation Path'),
  ])
  String? content;

  /// Overview diagram (e.g. Mermaid or image reference).
  FlowDiagramSection overviewDiagram = FlowDiagramSection();

  /// Process steps — ordered list of change process steps — contains 0+× ChangeStep.
  List<ChangeStepEntry> steps = [];

  /// Roles involved in the change process — contains 0+× ChangeRole.
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
class ChangeImpactCriteria {
  String? content;
  /// Contains 0+× ChangeImpactCriterion.
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
class ReferenceDocuments {
  String? content;

  /// Reference document entries — contains 0+× Reference Document.
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
