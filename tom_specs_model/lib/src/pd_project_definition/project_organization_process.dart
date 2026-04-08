/// Section 2: Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 2. Project Organization and Process [PD00-POP].
@tomReflector
class ProjectOrganizationAndProcess {
  final String? content;

  /// 2.1. Role Adjustments [PD00-POP-ROL].
  final RoleAdjustments roleAdjustments;

  /// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
  final QualityGateAdjustments qualityGateAdjustments;

  /// 2.3. Process Adjustments [PD00-POP-PRC].
  final ProcessAdjustments processAdjustments;

  /// 2.4. Tooling and Environments [PD00-POP-TOO].
  final ToolingAndEnvironments toolingAndEnvironments;

  const ProjectOrganizationAndProcess({
    this.content,
    this.roleAdjustments = const RoleAdjustments(),
    this.qualityGateAdjustments = const QualityGateAdjustments(),
    this.processAdjustments = const ProcessAdjustments(),
    this.toolingAndEnvironments = const ToolingAndEnvironments(),
  });
}

// ---------------------------------------------------------------------------
// 2.1 Role Adjustments
// ---------------------------------------------------------------------------

/// 2.1. Role Adjustments [PD00-POP-ROL].
@tomReflector
class RoleAdjustments {
  final String? content;
  final List<RoleAdjustmentEntry> items;

  const RoleAdjustments({this.content, this.items = const []});
}

/// A role adjustment entry (form).
@tomReflector
class RoleAdjustmentEntry {
  final String? content;
  final String? roleName;
  final String? adjustment;
  final String? rationale;

  const RoleAdjustmentEntry({
    this.content,
    this.roleName,
    this.adjustment,
    this.rationale,
  });
}

// ---------------------------------------------------------------------------
// 2.2 Quality Gate Adjustments
// ---------------------------------------------------------------------------

/// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
@tomReflector
class QualityGateAdjustments {
  final String? content;
  final List<QualityGateAdjustmentEntry> items;

  const QualityGateAdjustments({this.content, this.items = const []});
}

/// A quality gate adjustment entry (form).
@tomReflector
class QualityGateAdjustmentEntry {
  final String? content;
  final String? gateName;
  final String? adjustment;
  final String? rationale;

  const QualityGateAdjustmentEntry({
    this.content,
    this.gateName,
    this.adjustment,
    this.rationale,
  });
}

// ---------------------------------------------------------------------------
// 2.3 Process Adjustments
// ---------------------------------------------------------------------------

/// 2.3. Process Adjustments [PD00-POP-PRC].
@tomReflector
class ProcessAdjustments {
  final String? content;
  final List<ProcessAdjustmentEntry> items;

  const ProcessAdjustments({this.content, this.items = const []});
}

/// A process adjustment entry (form).
@tomReflector
class ProcessAdjustmentEntry {
  final String? content;
  final String? processName;
  final String? adjustment;
  final String? rationale;

  const ProcessAdjustmentEntry({
    this.content,
    this.processName,
    this.adjustment,
    this.rationale,
  });
}

// ---------------------------------------------------------------------------
// 2.4 Tooling and Environments
// ---------------------------------------------------------------------------

/// 2.4. Tooling and Environments [PD00-POP-TOO].
@tomReflector
class ToolingAndEnvironments {
  final String? content;
  final List<ToolingEntry> items;

  const ToolingAndEnvironments({this.content, this.items = const []});
}

/// A tooling entry (form).
@tomReflector
class ToolingEntry {
  final String? content;
  final String? toolName;
  final String? purpose;
  final String? environment;
  final String? version;

  const ToolingEntry({
    this.content,
    this.toolName,
    this.purpose,
    this.environment,
    this.version,
  });
}
