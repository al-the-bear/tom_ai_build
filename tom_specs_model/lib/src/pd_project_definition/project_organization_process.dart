/// Section 2: Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
library;



/// 2. Project Organization and Process [PD00-POP].
class ProjectOrganizationAndProcess {
  String? content;

  /// 2.1. Role Adjustments [PD00-POP-ROL].
  RoleAdjustments roleAdjustments = RoleAdjustments();

  /// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
  QualityGateAdjustments qualityGateAdjustments = QualityGateAdjustments();

  /// 2.3. Process Adjustments [PD00-POP-PRC].
  ProcessAdjustments processAdjustments = ProcessAdjustments();

  /// 2.4. Tooling and Environments [PD00-POP-TOO].
  ToolingAndEnvironments toolingAndEnvironments = ToolingAndEnvironments();
}

// ---------------------------------------------------------------------------
// 2.1 Role Adjustments
// ---------------------------------------------------------------------------

/// 2.1. Role Adjustments [PD00-POP-ROL].
class RoleAdjustments {
  String? content;
  /// Contains 0+× RoleAdjustment.
  List<RoleAdjustmentEntry> items = [];
}

/// A role adjustment entry (form) [PD00-POP-ROL-nn].
class RoleAdjustmentEntry {
  String? content;
  String? roleName;
  String? adjustment;
  String? rationale;
}

// ---------------------------------------------------------------------------
// 2.2 Quality Gate Adjustments
// ---------------------------------------------------------------------------

/// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
class QualityGateAdjustments {
  String? content;
  /// Contains 0+× QualityGateAdjustment.
  List<QualityGateAdjustmentEntry> items = [];
}

/// A quality gate adjustment entry (form) [PD00-POP-QGA-nn].
class QualityGateAdjustmentEntry {
  String? content;
  String? gateName;
  String? adjustment;
  String? rationale;
}

// ---------------------------------------------------------------------------
// 2.3 Process Adjustments
// ---------------------------------------------------------------------------

/// 2.3. Process Adjustments [PD00-POP-PRC].
class ProcessAdjustments {
  String? content;
  /// Contains 0+× ProcessAdjustment.
  List<ProcessAdjustmentEntry> items = [];
}

/// A process adjustment entry (form) [PD00-POP-PRC-nn].
class ProcessAdjustmentEntry {
  String? content;
  String? processName;
  String? adjustment;
  String? rationale;
}

// ---------------------------------------------------------------------------
// 2.4 Tooling and Environments
// ---------------------------------------------------------------------------

/// 2.4. Tooling and Environments [PD00-POP-TOO].
class ToolingAndEnvironments {
  String? content;

  /// 2.4.1. Tooling [PD00-POP-TOO-TOO].
  Tooling tooling = Tooling();

  /// 2.4.2. Environments [PD00-POP-TOO-ENV].
  Environments environments = Environments();
}

/// 2.4.1. Tooling [PD00-POP-TOO-TOO].
class Tooling {
  String? content;
  /// Contains 0+× Tool.
  List<ToolEntry> items = [];
}

/// A tool entry (form) [PD00-POP-TOO-TOO-nn].
class ToolEntry {
  String? content;
  String? toolName;
  String? purpose;
  String? version;
  String? category;
}

/// 2.4.2. Environments [PD00-POP-TOO-ENV].
class Environments {
  String? content;
  /// Contains 0+× Environment.
  List<EnvironmentEntry> items = [];
}

/// An environment entry (form) [PD00-POP-TOO-ENV-nn].
class EnvironmentEntry {
  String? content;
  String? environmentName;
  String? purpose;
  String? infrastructure;
  String? accessPolicy;
  String? dataPolicy;
}
