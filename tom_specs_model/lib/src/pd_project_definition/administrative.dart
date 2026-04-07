import '../common/enums.dart';

/// Section 3: Administrative [PD00-ADM].
///
/// Project administration: team, distribution, change procedure, references.
class Administrative {
  /// 3.1. Project Organization [PD00-ADM-PRO].
  final String? projectOrganization;

  /// 3.1.1. Organization Structure [PD00-ADM-PRO-STR].
  final String? organizationStructure;

  /// 3.1.2. Steering Committee [PD00-ADM-PRO-STE] — contains 1+× CommitteeMember.
  final List<CommitteeMember> steeringCommittee;

  /// 3.2. Project Team Staffing [PD00-ADM-TEA] — contains 1+× TeamMember.
  final List<TeamMember> projectTeam;

  /// 3.3.1. Full Distribution [PD00-ADM-DIS-FUL].
  final String? fullDistribution;

  /// 3.3.2. Executive Summary [PD00-ADM-DIS-EXE].
  final String? executiveSummary;

  /// 3.4.1. Change Process [PD00-ADM-CHA-PRO].
  final String? changeProcess;

  /// 3.4.2. Change Impact Criteria [PD00-ADM-CHA-CRI].
  final String? changeImpactCriteria;

  /// 3.5. Reference Documents [PD00-ADM-REF] — contains 0+× ReferenceDocument.
  final List<ReferenceDocument> referenceDocuments;

  /// 3.6. Other Administrative Requirements [PD00-ADM-OTH].
  final String? otherAdministrative;

  const Administrative({
    this.projectOrganization,
    this.organizationStructure,
    this.steeringCommittee = const [],
    this.projectTeam = const [],
    this.fullDistribution,
    this.executiveSummary,
    this.changeProcess,
    this.changeImpactCriteria,
    this.referenceDocuments = const [],
    this.otherAdministrative,
  });
}

/// Steering committee member [PD00-ADM-PRO-STE-nn].
class CommitteeMember {
  final String name;
  final String organizationRole;
  final String committeeRole;
  final String decisionAuthority;
  final AttendanceRequirement meetingAttendance;

  const CommitteeMember({
    required this.name,
    required this.organizationRole,
    required this.committeeRole,
    required this.decisionAuthority,
    this.meetingAttendance = AttendanceRequirement.mandatory,
  });
}

/// Project team member [PD00-ADM-TEA-nn].
class TeamMember {
  final String name;
  final String projectRole;
  final String organization;
  final String allocation;
  final String startDate;
  final String? endDate;
  final String? specialSkills;
  final String? reportingTo;

  const TeamMember({
    required this.name,
    required this.projectRole,
    required this.organization,
    required this.allocation,
    required this.startDate,
    this.endDate,
    this.specialSkills,
    this.reportingTo,
  });
}

/// Referenced document [PD00-ADM-REF-nn].
class ReferenceDocument {
  final String documentTitle;
  final String version;
  final String author;
  final String date;
  final String purpose;
  final String location;

  const ReferenceDocument({
    required this.documentTitle,
    required this.version,
    required this.author,
    required this.date,
    required this.purpose,
    required this.location,
  });
}
