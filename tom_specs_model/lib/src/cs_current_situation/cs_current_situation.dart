/// CS — Current Situation.
///
/// Phase 3 DocSpec root class. Aggregates 8 top-level sections from two
/// PD00 seeds — PD00-CUR (whole) and PD00-SYO-SYR (whole) — per §5.1 of
/// second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// CS00 Current Situation.
///
/// Detailed analysis of the current state: existing systems, business
/// processes, pain points, data landscape, operational metrics, risks,
/// and the inventory / migration plan for the systems being replaced.
@Document(
  name: 'Current Situation',
  description: 'Detailed analysis of the current systems and processes the '
      'target system will replace — landscape, pain points, metrics, '
      'risks, replacement inventory, and migration considerations.',
  basedOn: [ProjectDefinition],
)
@SectionId('CS00')
class CurrentSituation {
  @ContentHelp('Executive overview of the current-state analysis that '
      'motivates the project.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── From PD00-CUR (Current State Analysis) ──────────────────────────────

  /// Existing systems landscape — PD00-CUR-SYS.
  ExistingSystemsLandscape existingSystemsLandscape =
      ExistingSystemsLandscape();

  /// Current business processes — PD00-CUR-PRO.
  CurrentBusinessProcesses currentBusinessProcesses =
      CurrentBusinessProcesses();

  /// Pain points and gaps — PD00-CUR-PAI.
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// Current data landscape — PD00-CUR-DAT.
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();

  /// Current operational metrics — PD00-CUR-MET.
  CurrentOperationalMetrics operationalMetrics = CurrentOperationalMetrics();

  /// Current-state risk assessment — PD00-CUR-RIS.
  CurrentStateRiskAssessment currentStateRisks = CurrentStateRiskAssessment();

  // ─── From PD00-SYO-SYR (Systems to Replace) ──────────────────────────────

  /// Replacement inventory — PD00-SYO-SYR-INV.
  ReplacementInventory replacementInventory = ReplacementInventory();

  /// Migration considerations — PD00-SYO-SYR-MIG.
  MigrationConsiderations migrationConsiderations = MigrationConsiderations();
}
