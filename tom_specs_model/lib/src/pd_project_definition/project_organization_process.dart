/// Section 2: Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



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
  @Form([
    Field('roleName', String, 'Role Name', required: true),
    Field('adjustment', String, 'Adjustment'),
    Field('rationale', String, 'Rationale'),
  ])

  String? content;
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
  @Form([
    Field('gateName', String, 'Gate Name', required: true),
    Field('adjustment', String, 'Adjustment'),
    Field('rationale', String, 'Rationale'),
  ])

  String? content;
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
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('adjustment', String, 'Adjustment'),
    Field('rationale', String, 'Rationale'),
  ])

  String? content;
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
  @Form([
    Field('toolName', String, 'Tool Name', required: true),
    Field('purpose', String, 'Purpose'),
    Field('version', String, 'Version'),
    Field('category', String, 'Category'),
  ])

  String? content;
}

/// 2.4.2. Environments [PD00-POP-TOO-ENV].
class Environments {
  String? content;
  /// Contains 0+× Environment.
  List<EnvironmentEntry> items = [];
}

/// An environment entry (form) [PD00-POP-TOO-ENV-nn].
class EnvironmentEntry {
  @Form([
    Field('environmentName', String, 'Environment Name', required: true),
    Field('purpose', String, 'Purpose'),
    Field('infrastructure', String, 'Infrastructure'),
    Field('accessPolicy', String, 'Access Policy'),
    Field('dataPolicy', String, 'Data Policy'),
  ])

  String? content;
}
