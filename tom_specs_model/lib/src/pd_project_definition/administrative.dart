/// Section 3: Administrative [PD00-ADM].
///
/// Project administration: team, distribution, change procedure, references.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 3. Administrative [PD00-ADM].
@tomReflector
class Administrative {
  final String? content;

  /// 3.1. Project Organization [PD00-ADM-PRO].
  final ProjectOrganization projectOrganization;

  /// 3.2. Project Team Staffing [PD00-ADM-TEA] — contains 1+× Team Member.
  final ProjectTeamStaffing projectTeamStaffing;

  /// 3.3. Distribution List [PD00-ADM-DIS].
  final DistributionList distributionList;

  /// 3.4. Change Procedure [PD00-ADM-CHA].
  final ChangeProcedure changeProcedure;

  /// 3.5. Reference Documents [PD00-ADM-REF] — contains 0+× Reference Document.
  final ReferenceDocuments referenceDocuments;

  /// 3.6. Other Administrative Requirements [PD00-ADM-OTH].
  final String? otherAdministrative;

  const Administrative({
    this.content,
    this.projectOrganization = const ProjectOrganization(),
    this.projectTeamStaffing = const ProjectTeamStaffing(),
    this.distributionList = const DistributionList(),
    this.changeProcedure = const ChangeProcedure(),
    this.referenceDocuments = const ReferenceDocuments(),
    this.otherAdministrative,
  });
}

// ---------------------------------------------------------------------------
// 3.1 Project Organization
// ---------------------------------------------------------------------------

/// 3.1. Project Organization [PD00-ADM-PRO].
@tomReflector
class ProjectOrganization {
  final String? content;

  /// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
  final OrganizationStructure organizationStructure;

  /// 3.1.2. Steering Committee [PD00-ADM-PRO-STE] — contains 1+× Member.
  final List<CommitteeMemberEntry> steeringCommittee;

  const ProjectOrganization({
    this.content,
    this.organizationStructure = const OrganizationStructure(),
    this.steeringCommittee = const [],
  });
}

/// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
@tomReflector
class OrganizationStructure {
  final String? content;

  /// Explanation of the organization chart.
  final String? orgChartExplanation;

  /// Organization chart diagram (e.g. Mermaid or image reference).
  final String? orgChartDiagram;

  const OrganizationStructure({
    this.content,
    this.orgChartExplanation,
    this.orgChartDiagram,
  });
}

/// A steering committee member entry [PD00-ADM-PRO-STE-nn] (form).
@tomReflector
class CommitteeMemberEntry {
  final String? content;
  final String? name;
  final String? organizationRole;
  final String? committeeRole;
  final String? decisionAuthority;
  final String? meetingAttendance;

  const CommitteeMemberEntry({
    this.content,
    this.name,
    this.organizationRole,
    this.committeeRole,
    this.decisionAuthority,
    this.meetingAttendance,
  });
}

// ---------------------------------------------------------------------------
// 3.2 Project Team Staffing
// ---------------------------------------------------------------------------

/// 3.2. Project Team Staffing [PD00-ADM-TEA].
@tomReflector
class ProjectTeamStaffing {
  final String? content;

  /// Team members — contains 1+× Team Member.
  final List<TeamMemberEntry> members;

  const ProjectTeamStaffing({
    this.content,
    this.members = const [],
  });
}

/// A team member entry [PD00-ADM-TEA-nn] (form).
@tomReflector
class TeamMemberEntry {
  final String? content;
  final String? name;
  final String? projectRole;
  final String? organization;
  final String? allocation;
  final String? startDate;
  final String? endDate;
  final String? specialSkills;
  final String? reportingTo;

  const TeamMemberEntry({
    this.content,
    this.name,
    this.projectRole,
    this.organization,
    this.allocation,
    this.startDate,
    this.endDate,
    this.specialSkills,
    this.reportingTo,
  });
}

// ---------------------------------------------------------------------------
// 3.3 Distribution List
// ---------------------------------------------------------------------------

/// 3.3. Distribution List [PD00-ADM-DIS].
@tomReflector
class DistributionList {
  final String? content;

  /// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
  final FullDistribution fullDistribution;

  /// 3.3.2. Executive Summary [PD00-ADM-DIS-EXE].
  final ExecutiveSummaryDistribution executiveSummary;

  const DistributionList({
    this.content,
    this.fullDistribution = const FullDistribution(),
    this.executiveSummary = const ExecutiveSummaryDistribution(),
  });
}

/// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
@tomReflector
class FullDistribution {
  final String? content;
  final List<DistributionRecipientEntry> items;

  const FullDistribution({this.content, this.items = const []});
}

/// 3.3.2. Executive Summary Distribution [PD00-ADM-DIS-EXE].
@tomReflector
class ExecutiveSummaryDistribution {
  final String? content;
  final List<DistributionRecipientEntry> items;

  const ExecutiveSummaryDistribution({this.content, this.items = const []});
}

/// A distribution recipient entry (form).
@tomReflector
class DistributionRecipientEntry {
  final String? content;
  final String? name;
  final String? role;
  final String? organization;
  final String? distributionMethod;

  const DistributionRecipientEntry({
    this.content,
    this.name,
    this.role,
    this.organization,
    this.distributionMethod,
  });
}

// ---------------------------------------------------------------------------
// 3.4 Change Procedure
// ---------------------------------------------------------------------------

/// 3.4. Change Procedure [PD00-ADM-CHA].
@tomReflector
class ChangeProcedure {
  final String? content;

  /// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
  final ChangeProcess changeProcess;

  /// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
  final ChangeImpactCriteria changeImpactCriteria;

  const ChangeProcedure({
    this.content,
    this.changeProcess = const ChangeProcess(),
    this.changeImpactCriteria = const ChangeImpactCriteria(),
  });
}

/// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
@tomReflector
class ChangeProcess {
  final String? content;
  final String? steps;
  final String? roles;
  final String? approvalAuthority;
  final String? escalationPath;

  const ChangeProcess({
    this.content,
    this.steps,
    this.roles,
    this.approvalAuthority,
    this.escalationPath,
  });
}

/// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
@tomReflector
class ChangeImpactCriteria {
  final String? content;
  final List<ChangeImpactCriterionEntry> items;

  const ChangeImpactCriteria({this.content, this.items = const []});
}

/// A change impact criterion entry (form).
@tomReflector
class ChangeImpactCriterionEntry {
  final String? content;
  final String? criterion;
  final String? impactLevel;
  final String? description;
  final String? approvalRequired;

  const ChangeImpactCriterionEntry({
    this.content,
    this.criterion,
    this.impactLevel,
    this.description,
    this.approvalRequired,
  });
}

// ---------------------------------------------------------------------------
// 3.5 Reference Documents
// ---------------------------------------------------------------------------

/// 3.5. Reference Documents [PD00-ADM-REF].
@tomReflector
class ReferenceDocuments {
  final String? content;

  /// Reference document entries — contains 0+× Reference Document.
  final List<ReferenceDocumentEntry> documents;

  const ReferenceDocuments({
    this.content,
    this.documents = const [],
  });
}

/// A reference document entry [PD00-ADM-REF-nn] (form).
@tomReflector
class ReferenceDocumentEntry {
  final String? content;
  final String? documentTitle;
  final String? version;
  final String? author;
  final String? date;
  final String? purpose;
  final String? location;

  const ReferenceDocumentEntry({
    this.content,
    this.documentTitle,
    this.version,
    this.author,
    this.date,
    this.purpose,
    this.location,
  });
}
