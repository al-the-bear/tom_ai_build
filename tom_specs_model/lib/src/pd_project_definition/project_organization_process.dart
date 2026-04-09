/// Section 2: Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 2. Project Organization and Process [PD00-POP].
@tomReflector
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
@tomReflector
class RoleAdjustments {
  String? content;
  List<RoleAdjustmentEntry> items = [];
}

/// A role adjustment entry (form).
@tomReflector
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
@tomReflector
class QualityGateAdjustments {
  String? content;
  List<QualityGateAdjustmentEntry> items = [];
}

/// A quality gate adjustment entry (form).
@tomReflector
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
@tomReflector
class ProcessAdjustments {
  String? content;
  List<ProcessAdjustmentEntry> items = [];
}

/// A process adjustment entry (form).
@tomReflector
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
@tomReflector
class ToolingAndEnvironments {
  String? content;
  List<ToolingEntry> items = [];
}

/// A tooling entry (form).
@tomReflector
class ToolingEntry {
  String? content;
  String? toolName;
  String? purpose;
  String? environment;
  String? version;
}
