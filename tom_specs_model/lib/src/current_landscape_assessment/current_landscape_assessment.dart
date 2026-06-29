/// CS — Current Situation.
///
/// Phase 3 DocSpec root class. Aggregates 8 top-level sections projected
/// from the corresponding Solution Blueprint current-landscape and
/// systems-to-replace sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// CS00 Current Situation.
///
/// Detailed analysis of the current state: existing systems, business
/// processes, pain points, data landscape, operational metrics, risks,
/// and the inventory / migration plan for the systems being replaced.
@Document(
  name: 'Current Landscape Assessment',
  description: 'Detailed analysis of the current systems and processes the '
      'target system will replace — landscape, pain points, metrics, '
      'risks, replacement inventory, and migration considerations.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('CLA')
class D01CurrentLandscapeAssessment {
  @ContentHelp('Executive overview of the current-state analysis that '
      'motivates the project.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── Current State Analysis ──────────────────────────────────────────────

  /// Existing systems landscape.
  ExistingSystemsLandscape existingSystemsLandscape =
      ExistingSystemsLandscape();

  /// Current business processes.
  CurrentBusinessProcesses currentBusinessProcesses =
      CurrentBusinessProcesses();

  /// Pain points and gaps.
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// Current data landscape.
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();

  /// Current operational metrics.
  @SectionId('CUOPME-OPER-LST')
  @SectionIdPattern('CUOPME-OPER-xxx')
  List<CurrentOperationalMetrics> operationalMetrics = [];

  /// Current-state risk assessment.
  CurrentStateRiskAssessment currentStateRisks = CurrentStateRiskAssessment();

  // ─── Systems to Replace ──────────────────────────────────────────────────

  /// Replacement inventory.
  ReplacementInventory replacementInventory = ReplacementInventory();

  /// Migration considerations.
  MigrationConsiderations migrationConsiderations = MigrationConsiderations();
}
