/// Section 5: Organizational Framework [PD00-ORG].
///
/// Organizational changes and structures required for the new system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 5. Organizational Framework [PD00-ORG].
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
class NewOrganizationStructure {
  String? content;

  /// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
  ChangesFromCurrentStructure changesFromCurrentStructure = ChangesFromCurrentStructure();

  /// Transition Timeline.
  TextSection transitionTimeline = TextSection();
}

/// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
class ChangesFromCurrentStructure {
  String? content;
  /// Contains 0+× OrganizationalChange.
  List<OrganizationalChangeEntry> items = [];
}

/// An organizational change entry (form) [PD00-ORG-STR-CHA-nn].
class OrganizationalChangeEntry {
  @Form([
    Field('area', String, 'Area'),
    Field('currentState', String, 'Current State'),
    Field('targetState', String, 'Target State'),
    Field('rationale', String, 'Rationale'),
    Field('impact', String, 'Impact assessment'),
  ])

  String? content;
}

// ---------------------------------------------------------------------------
// 5.2 Job Descriptions and Staffing Plans
// ---------------------------------------------------------------------------

/// 5.2. Job Descriptions and Staffing Plans [PD00-ORG-JOB].
class JobDescriptionsAndStaffing {
  String? content;

  /// 5.2.1. New Roles [PD00-ORG-JOB-NEW] — contains 0+× New Role.
  List<NewRoleEntry> newRoles = [];

  /// 5.2.2. Changed Roles [PD00-ORG-JOB-CHA] — contains 0+× Changed Role.
  List<ChangedRoleEntry> changedRoles = [];

  /// 5.2.3. Staffing Plan [PD00-ORG-JOB-STA].
  StaffingPlan staffingPlan = StaffingPlan();
}

/// 5.2.3. Staffing Plan [PD00-ORG-JOB-STA].
class StaffingPlan {
  String? content;
  /// Budget.
  TextSection budget = TextSection();
  /// Contains 0+× Staffing.
  List<StaffingEntry> items = [];
}

/// A staffing entry (form) [PD00-ORG-JOB-STA-nn].
class StaffingEntry {
  @Form([
    Field('roleTitle', String, 'Role Title', required: true),
    Field('department', String, 'Department'),
    Field('fteCount', String, 'Fte Count'),
    Field('recruitmentStatus', String, 'Recruitment Status'),
    Field('targetStartDate', String, 'Target Start Date'),
  ])

  String? content;
}

/// A new role entry [PD00-ORG-JOB-NEW-nn] (form).
class NewRoleEntry {
  @Form([
    Field('roleTitle', String, 'Role Title', required: true),
    Field('department', String, 'Department'),
    Field('reportingLine', String, 'Reporting Line'),
    Field('fteAllocation', String, 'Fte Allocation'),
    Field('startDate', String, 'Start Date'),
  ])

  String? content;
  /// Contains 0+× RoleResponsibility.
  List<RoleResponsibilityEntry> responsibilities = [];
  /// Contains 0+× Skill.
  List<SkillEntry> requiredSkills = [];
}

/// A responsibility entry (form) [PD00-ORG-JOB-nn-RSP-nn].
class RoleResponsibilityEntry {
  @Form([
    Field('responsibility', String, 'Responsibility'),
    Field('description', String, 'Short description'),
  ])

  String? content;
}

/// A skill entry (form) [PD00-ORG-JOB-nn-SKL-nn].
class SkillEntry {
  @Form([
    Field('skillName', String, 'Skill Name'),
    Field('proficiencyLevel', String, 'Proficiency Level'),
  ])

  String? content;
}

/// A changed role entry [PD00-ORG-JOB-CHA-nn] (form).
class ChangedRoleEntry {
  @Form([
    Field('roleTitle', String, 'Role Title', required: true),
    Field('currentDepartment', String, 'Current Department'),
    Field('changedReportingLine', String, 'Changed Reporting Line'),
    Field('trainingRequired', String, 'Training Required'),
  ])

  String? content;
  /// Contains 0+× RoleResponsibility.
  List<RoleResponsibilityEntry> addedResponsibilities = [];
  /// Contains 0+× RoleResponsibility.
  List<RoleResponsibilityEntry> removedResponsibilities = [];
  /// Contains 0+× Skill.
  List<SkillEntry> newSkillRequirements = [];
}

// ---------------------------------------------------------------------------
// 5.3 Workplace Descriptions
// ---------------------------------------------------------------------------

/// A workplace description entry [PD00-ORG-WOR-nn] (form, per user category).
class WorkplaceDescriptionEntry {
  @Form([
    Field('userCategory', String, 'User Category'),
  ])

  String? content;

  /// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
  EquipmentRequirements equipmentRequirements = EquipmentRequirements();

  /// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
  TrainingRequirements trainingRequirements = TrainingRequirements();
}

/// 5.3.1. Equipment Requirements [PD00-ORG-WOR-EQU].
class EquipmentRequirements {
  String? content;
  /// Contains 0+× EquipmentRequirement.
  List<EquipmentRequirementEntry> items = [];
}

/// An equipment requirement entry (form) [PD00-ORG-WOR-nn-EQU-nn].
class EquipmentRequirementEntry {
  @Form([
    Field('equipmentType', String, 'Equipment Type'),
    Field('specification', String, 'Specification'),
    Field('quantity', String, 'Quantity'),
    Field('purpose', String, 'Purpose'),
  ])

  String? content;
}

/// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
class TrainingRequirements {
  String? content;
  /// Contains 0+× TrainingRequirement.
  List<TrainingRequirementEntry> items = [];
}

/// A training requirement entry (form) [PD00-ORG-WOR-nn-TRA-nn].
class TrainingRequirementEntry {
  @Form([
    Field('trainingTopic', String, 'Training Topic'),
    Field('targetAudience', String, 'Target Audience'),
    Field('format', String, 'Format'),
    Field('duration', String, 'Duration'),
    Field('schedule', String, 'Schedule'),
  ])

  String? content;
}
