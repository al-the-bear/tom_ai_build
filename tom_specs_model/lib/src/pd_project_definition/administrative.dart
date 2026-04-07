/// Section 3: Administrative [PD00-ADM].
///
/// Project administration: team, distribution, change procedure, references.
library;


/// 3. Administrative [PD00-ADM].
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
class ProjectOrganization {
  final String? content;

  /// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
  final String? organizationStructure;

  /// 3.1.2. Steering Committee [PD00-ADM-PRO-STE] — contains 1+× Member.
  final List<CommitteeMemberEntry> steeringCommittee;

  const ProjectOrganization({
    this.content,
    this.organizationStructure,
    this.steeringCommittee = const [],
  });
}

/// A steering committee member entry [PD00-ADM-PRO-STE-nn] (form).
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
class DistributionList {
  final String? content;

  /// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
  final String? fullDistribution;

  /// 3.3.2. Executive Summary [PD00-ADM-DIS-EXE].
  final String? executiveSummary;

  const DistributionList({
    this.content,
    this.fullDistribution,
    this.executiveSummary,
  });
}

// ---------------------------------------------------------------------------
// 3.4 Change Procedure
// ---------------------------------------------------------------------------

/// 3.4. Change Procedure [PD00-ADM-CHA].
class ChangeProcedure {
  final String? content;

  /// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
  final String? changeProcess;

  /// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
  final String? changeImpactCriteria;

  const ChangeProcedure({
    this.content,
    this.changeProcess,
    this.changeImpactCriteria,
  });
}

// ---------------------------------------------------------------------------
// 3.5 Reference Documents
// ---------------------------------------------------------------------------

/// 3.5. Reference Documents [PD00-ADM-REF].
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
