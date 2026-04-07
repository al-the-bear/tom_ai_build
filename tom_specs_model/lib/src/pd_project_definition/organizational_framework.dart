/// Section 5: Organizational Framework [PD00-ORG].
///
/// Organizational changes and structures required for the new system.
class OrganizationalFramework {
  /// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
  final String? changesFromCurrentStructure;

  /// 5.1.2. Organizational Transition Timeline [PD00-ORG-STR-TIM].
  final String? transitionTimeline;

  /// 5.2.1. New Roles [PD00-ORG-JOB-NEW] — contains 0+× NewRole.
  final List<NewRole> newRoles;

  /// 5.2.2. Changed Roles [PD00-ORG-JOB-CHA] — contains 0+× ChangedRole.
  final List<ChangedRole> changedRoles;

  /// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
  final String? equipmentRequirements;

  /// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
  final String? trainingRequirements;

  const OrganizationalFramework({
    this.changesFromCurrentStructure,
    this.transitionTimeline,
    this.newRoles = const [],
    this.changedRoles = const [],
    this.equipmentRequirements,
    this.trainingRequirements,
  });
}

/// A new role created by the system introduction [PD00-ORG-JOB-NEW-nn].
class NewRole {
  final String roleTitle;
  final String department;
  final String responsibilities;
  final String? requiredSkills;
  final String? reportingLine;
  final double? fteAllocation;
  final String? startDate;

  const NewRole({
    required this.roleTitle,
    required this.department,
    required this.responsibilities,
    this.requiredSkills,
    this.reportingLine,
    this.fteAllocation,
    this.startDate,
  });
}

/// An existing role changed by the system introduction [PD00-ORG-JOB-CHA-nn].
class ChangedRole {
  final String roleTitle;
  final String currentDepartment;
  final String? addedResponsibilities;
  final String? removedResponsibilities;
  final String? newSkillRequirements;
  final String? changedReportingLine;
  final String? trainingRequired;

  const ChangedRole({
    required this.roleTitle,
    required this.currentDepartment,
    this.addedResponsibilities,
    this.removedResponsibilities,
    this.newSkillRequirements,
    this.changedReportingLine,
    this.trainingRequired,
  });
}
