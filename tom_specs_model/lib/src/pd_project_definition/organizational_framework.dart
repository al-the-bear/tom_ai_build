/// Section 5: Organizational Framework [PD00-ORG].
///
/// Organizational changes and structures required for the new system.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 5. Organizational Framework [PD00-ORG].
@tomReflector
class OrganizationalFramework {
  String? content;

  /// 5.1. New Organization Structure [PD00-ORG-STR].
  NewOrganizationStructure organizationStructure = NewOrganizationStructure();

  /// 5.2. Job Descriptions and Staffing Plans [PD00-ORG-JOB].
  JobDescriptionsAndStaffing jobDescriptions = JobDescriptionsAndStaffing();

  /// 5.3. Workplace Descriptions [PD00-ORG-WOR] — contains 1+× per user category.
  List<WorkplaceDescriptionEntry> workplaceDescriptions = [];
}

// ---------------------------------------------------------------------------
// 5.1 New Organization Structure
// ---------------------------------------------------------------------------

/// 5.1. New Organization Structure [PD00-ORG-STR].
@tomReflector
class NewOrganizationStructure {
  String? content;

  /// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
  ChangesFromCurrentStructure changesFromCurrentStructure = ChangesFromCurrentStructure();

  /// 5.1.2. Organizational Transition Timeline [PD00-ORG-STR-TIM].
  String? transitionTimeline;
}

/// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
@tomReflector
class ChangesFromCurrentStructure {
  String? content;
  List<OrganizationalChangeEntry> items = [];
}

/// An organizational change entry (form).
@tomReflector
class OrganizationalChangeEntry {
  String? content;
  String? area;
  String? currentState;
  String? targetState;
  String? rationale;
  String? impact;
}

// ---------------------------------------------------------------------------
// 5.2 Job Descriptions and Staffing Plans
// ---------------------------------------------------------------------------

/// 5.2. Job Descriptions and Staffing Plans [PD00-ORG-JOB].
@tomReflector
class JobDescriptionsAndStaffing {
  String? content;

  /// 5.2.1. New Roles [PD00-ORG-JOB-NEW] — contains 0+× New Role.
  List<NewRoleEntry> newRoles = [];

  /// 5.2.2. Changed Roles [PD00-ORG-JOB-CHA] — contains 0+× Changed Role.
  List<ChangedRoleEntry> changedRoles = [];
}

/// A new role entry [PD00-ORG-JOB-NEW-nn] (form).
@tomReflector
class NewRoleEntry {
  String? content;
  String? roleTitle;
  String? department;
  List<RoleResponsibilityEntry> responsibilities = [];
  List<SkillEntry> requiredSkills = [];
  String? reportingLine;
  String? fteAllocation;
  String? startDate;
}

/// A responsibility entry (form).
@tomReflector
class RoleResponsibilityEntry {
  String? content;
  String? responsibility;
  String? description;
}

/// A skill entry (form).
@tomReflector
class SkillEntry {
  String? content;
  String? skillName;
  String? proficiencyLevel;
}

/// A changed role entry [PD00-ORG-JOB-CHA-nn] (form).
@tomReflector
class ChangedRoleEntry {
  String? content;
  String? roleTitle;
  String? currentDepartment;
  List<RoleResponsibilityEntry> addedResponsibilities = [];
  List<RoleResponsibilityEntry> removedResponsibilities = [];
  List<SkillEntry> newSkillRequirements = [];
  String? changedReportingLine;
  String? trainingRequired;
}

// ---------------------------------------------------------------------------
// 5.3 Workplace Descriptions
// ---------------------------------------------------------------------------

/// A workplace description entry [PD00-ORG-WOR-nn] (form, per user category).
@tomReflector
class WorkplaceDescriptionEntry {
  String? content;

  /// Target user category this workplace description applies to.
  String? userCategory;

  /// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
  EquipmentRequirements equipmentRequirements = EquipmentRequirements();

  /// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
  TrainingRequirements trainingRequirements = TrainingRequirements();
}

/// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
@tomReflector
class EquipmentRequirements {
  String? content;
  List<EquipmentRequirementEntry> items = [];
}

/// An equipment requirement entry (form).
@tomReflector
class EquipmentRequirementEntry {
  String? content;
  String? equipmentType;
  String? specification;
  String? quantity;
  String? purpose;
}

/// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
@tomReflector
class TrainingRequirements {
  String? content;
  List<TrainingRequirementEntry> items = [];
}

/// A training requirement entry (form).
@tomReflector
class TrainingRequirementEntry {
  String? content;
  String? trainingTopic;
  String? targetAudience;
  String? format;
  String? duration;
  String? schedule;
}
