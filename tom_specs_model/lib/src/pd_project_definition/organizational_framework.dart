/// Section 5: Organizational Framework [PD00-ORG].
///
/// Organizational changes and structures required for the new system.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 5. Organizational Framework [PD00-ORG].
@tomReflector
class OrganizationalFramework {
  final String? content;

  /// 5.1. New Organization Structure [PD00-ORG-STR].
  final NewOrganizationStructure organizationStructure;

  /// 5.2. Job Descriptions and Staffing Plans [PD00-ORG-JOB].
  final JobDescriptionsAndStaffing jobDescriptions;

  /// 5.3. Workplace Description [PD00-ORG-WOR].
  final WorkplaceDescription workplaceDescription;

  const OrganizationalFramework({
    this.content,
    this.organizationStructure = const NewOrganizationStructure(),
    this.jobDescriptions = const JobDescriptionsAndStaffing(),
    this.workplaceDescription = const WorkplaceDescription(),
  });
}

// ---------------------------------------------------------------------------
// 5.1 New Organization Structure
// ---------------------------------------------------------------------------

/// 5.1. New Organization Structure [PD00-ORG-STR].
@tomReflector
class NewOrganizationStructure {
  final String? content;

  /// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
  final String? changesFromCurrentStructure;

  /// 5.1.2. Organizational Transition Timeline [PD00-ORG-STR-TIM].
  final String? transitionTimeline;

  const NewOrganizationStructure({
    this.content,
    this.changesFromCurrentStructure,
    this.transitionTimeline,
  });
}

// ---------------------------------------------------------------------------
// 5.2 Job Descriptions and Staffing Plans
// ---------------------------------------------------------------------------

/// 5.2. Job Descriptions and Staffing Plans [PD00-ORG-JOB].
@tomReflector
class JobDescriptionsAndStaffing {
  final String? content;

  /// 5.2.1. New Roles [PD00-ORG-JOB-NEW] — contains 0+× New Role.
  final List<NewRoleEntry> newRoles;

  /// 5.2.2. Changed Roles [PD00-ORG-JOB-CHA] — contains 0+× Changed Role.
  final List<ChangedRoleEntry> changedRoles;

  const JobDescriptionsAndStaffing({
    this.content,
    this.newRoles = const [],
    this.changedRoles = const [],
  });
}

/// A new role entry [PD00-ORG-JOB-NEW-nn] (form).
@tomReflector
class NewRoleEntry {
  final String? content;
  final String? roleTitle;
  final String? department;
  final String? responsibilities;
  final String? requiredSkills;
  final String? reportingLine;
  final String? fteAllocation;
  final String? startDate;

  const NewRoleEntry({
    this.content,
    this.roleTitle,
    this.department,
    this.responsibilities,
    this.requiredSkills,
    this.reportingLine,
    this.fteAllocation,
    this.startDate,
  });
}

/// A changed role entry [PD00-ORG-JOB-CHA-nn] (form).
@tomReflector
class ChangedRoleEntry {
  final String? content;
  final String? roleTitle;
  final String? currentDepartment;
  final String? addedResponsibilities;
  final String? removedResponsibilities;
  final String? newSkillRequirements;
  final String? changedReportingLine;
  final String? trainingRequired;

  const ChangedRoleEntry({
    this.content,
    this.roleTitle,
    this.currentDepartment,
    this.addedResponsibilities,
    this.removedResponsibilities,
    this.newSkillRequirements,
    this.changedReportingLine,
    this.trainingRequired,
  });
}

// ---------------------------------------------------------------------------
// 5.3 Workplace Description
// ---------------------------------------------------------------------------

/// 5.3. Workplace Description [PD00-ORG-WOR].
@tomReflector
class WorkplaceDescription {
  final String? content;

  /// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
  final String? equipmentRequirements;

  /// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
  final String? trainingRequirements;

  const WorkplaceDescription({
    this.content,
    this.equipmentRequirements,
    this.trainingRequirements,
  });
}
