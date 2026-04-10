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

  /// 3.6. Other Administrative Requirements [PD00-ADM-OTH].
  String? otherAdministrative;
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

  /// Explanation of the organization chart.
  String? orgChartExplanation;

  /// Organization chart diagram (e.g. Mermaid or image reference).
  DiagramSection orgChartDiagram = DiagramSection();
}

/// A steering committee member entry [PD00-ADM-PRO-STE-nn] (form).
class CommitteeMemberEntry {
  String? content;
  String? name;
  String? organizationRole;
  String? committeeRole;
  String? decisionAuthority;
  String? meetingAttendance;
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
  String? content;
  String? name;
  String? projectRole;
  String? organization;
  String? allocation;
  String? startDate;
  String? endDate;
  String? specialSkills;
  String? reportingTo;
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
  String? content;
  String? name;
  String? role;
  String? organization;
  String? distributionMethod;
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
  String? content;

  /// Overview diagram (e.g. Mermaid or image reference).
  FlowDiagramSection overviewDiagram = FlowDiagramSection();

  /// Process steps — ordered list of change process steps — contains 0+× ChangeStep.
  List<ChangeStepEntry> steps = [];

  /// Roles involved in the change process — contains 0+× ChangeRole.
  List<ChangeRoleEntry> roles = [];

  String? approvalAuthority;
  String? escalationPath;
}

/// A role involved in the change process (form) [PD00-ADM-CHA-PRO-ROL-nn].
class ChangeRoleEntry {
  String? content;
  String? roleName;
  String? responsibility;
}

/// A change process step entry (form) [PD00-ADM-CHA-PRO-STP-nn].
class ChangeStepEntry {
  String? content;
  String? stepName;
  String? description;
  String? responsibleRole;
  String? inputArtifacts;
  String? outputArtifacts;
  String? approvalCriteria;

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
  String? content;
  String? criterion;
  String? impactLevel;
  String? description;
  String? approvalRequired;
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
  String? content;
  String? documentTitle;
  String? version;
  String? author;
  String? date;
  String? purpose;
  String? location;
}
