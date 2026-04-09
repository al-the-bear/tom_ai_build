/// Section 5: Organizational Framework [PD00-ORG].
///
/// Organizational changes and structures required for the new system.
library;



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

  /// 5.1.2. Organizational Transition Timeline [PD00-ORG-STR-TIM].
  String? transitionTimeline;
}

/// 5.1.1. Changes from Current Structure [PD00-ORG-STR-CHA].
class ChangesFromCurrentStructure {
  String? content;
  List<OrganizationalChangeEntry> items = [];
}

/// An organizational change entry (form).
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
  String? headcountSummary;
  String? recruitmentTimeline;
  String? budget;
  List<StaffingEntry> items = [];
}

/// A staffing entry (form).
class StaffingEntry {
  String? content;
  String? roleTitle;
  String? department;
  String? fteCount;
  String? recruitmentStatus;
  String? targetStartDate;
}

/// A new role entry [PD00-ORG-JOB-NEW-nn] (form).
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
class RoleResponsibilityEntry {
  String? content;
  String? responsibility;
  String? description;
}

/// A skill entry (form).
class SkillEntry {
  String? content;
  String? skillName;
  String? proficiencyLevel;
}

/// A changed role entry [PD00-ORG-JOB-CHA-nn] (form).
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
class EquipmentRequirements {
  String? content;
  List<EquipmentRequirementEntry> items = [];
}

/// An equipment requirement entry (form).
class EquipmentRequirementEntry {
  String? content;
  String? equipmentType;
  String? specification;
  String? quantity;
  String? purpose;
}

/// 5.3.2. Training Requirements [PD00-ORG-WOR-TRA].
class TrainingRequirements {
  String? content;
  List<TrainingRequirementEntry> items = [];
}

/// A training requirement entry (form).
class TrainingRequirementEntry {
  String? content;
  String? trainingTopic;
  String? targetAudience;
  String? format;
  String? duration;
  String? schedule;
}
