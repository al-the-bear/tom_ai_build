/// Section 2: Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
class ProjectOrganizationAndProcess {
  /// 2.1. Role Adjustments [PD00-POP-ROL].
  final String? roleAdjustments;

  /// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
  final String? qualityGateAdjustments;

  /// 2.3. Process Adjustments [PD00-POP-PRC].
  final String? processAdjustments;

  /// 2.4. Tooling and Environments [PD00-POP-TOO].
  final String? toolingAndEnvironments;

  const ProjectOrganizationAndProcess({
    this.roleAdjustments,
    this.qualityGateAdjustments,
    this.processAdjustments,
    this.toolingAndEnvironments,
  });
}
