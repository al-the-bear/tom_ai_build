/// D01 — Current Landscape Assessment.
///
/// Phase 3 DocSpec root class. Aggregates 8 top-level sections projected
/// from the corresponding Solution Blueprint current-landscape and
/// systems-to-replace sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// CLA00 Current Landscape Assessment.
///
/// Detailed analysis of the current state: existing systems, business
/// processes, pain points, data landscape, operational metrics, risks,
/// and the inventory / migration plan for the systems being replaced.
@StandardReferences(
  [
    'BABOK v3 — current-state analysis',
    'ISO/IEC/IEEE 29148:2018 — as-is system constraints',
  ],
  'The current-state analysis of the systems and processes the target system will replace, covering landscape, pain points, metrics, risks, and replacement inventory.',
)
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
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  // ─── Current State Analysis ──────────────────────────────────────────────

  /// Existing systems landscape.
  @SerializationOrder(2)
  ExistingSystemsLandscape existingSystemsLandscape =
      ExistingSystemsLandscape();

  /// Current business processes.
  @SerializationOrder(3)
  CurrentBusinessProcesses currentBusinessProcesses =
      CurrentBusinessProcesses();

  /// Pain points and gaps.
  @SerializationOrder(4)
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// Current data landscape.
  @SerializationOrder(5)
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();

  /// Current operational metrics.
  @SectionId('CUOPME-OPER-LST')
  @SectionIdPattern('CUOPME-OPER-xxx')
  @SerializationOrder(6)
  List<CurrentOperationalMetric> operationalMetrics = [];

  /// Current-state risk assessment.
  @SerializationOrder(7)
  CurrentStateRiskAssessment currentStateRisks = CurrentStateRiskAssessment();

  // ─── Systems to Replace ──────────────────────────────────────────────────

  /// Replacement inventory.
  @SerializationOrder(8)
  ReplacementInventory replacementInventory = ReplacementInventory();

  /// Migration considerations.
  @SerializationOrder(9)
  MigrationConsiderations migrationConsiderations = MigrationConsiderations();
}
