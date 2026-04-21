/// PPP — Project Phase Plan.
///
/// Phase 3 DocSpec root class. Aggregates 9 top-level sections from
/// PD00-SSP (single seed, GOV flattened) per §5.11 of
/// second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// PPP00 Project Phase Plan.
///
/// Full project phase plan — staging strategy, stage overview, per-stage
/// entries, feature prioritization, data migration, gate criteria,
/// decision processes, initial development flow, and upgrade cycle
/// framework.
@Document(
  name: 'Project Phase Plan',
  description: 'Comprehensive project phase plan — staging strategy, '
      'stages, feature prioritization, migration, gates, decisions, '
      'initial development flow, and upgrade cycle framework (bridge '
      'to tom_system_upgrade.md).',
  basedOn: [ProjectDefinition],
)
@SectionId('PPP')
class ProjectPhasePlan {
  @ContentHelp('Executive overview of the phase plan and its gate model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Staging strategy — PD00-SSP-STR.
  StagingStrategy stagingStrategy = StagingStrategy();

  /// Stage overview — PD00-SSP-STA.
  StageOverview stageOverview = StageOverview();

  /// Stages — PD00-SSP-STG (list).
  @SectionId('STAGE-LST')
  @SectionIdPattern('STAGE-xxx')
  @Min(1)
  List<StageEntry> stages = [];

  /// Feature prioritization — PD00-SSP-FEA.
  FeaturePrioritization featurePrioritization = FeaturePrioritization();

  /// Data migration strategy — PD00-SSP-MIG.
  DataMigrationStrategy dataMigrationStrategy = DataMigrationStrategy();

  /// Gate criteria — PD00-SSP-GOV-GAT (promoted from GOV).
  PhaseGateReviews gateCriteria = PhaseGateReviews();

  /// Decision processes — PD00-SSP-GOV-DEC (promoted from GOV).
  DecisionPoints decisionProcesses = DecisionPoints();

  /// Initial development flow — PD00-SSP-IDV.
  InitialDevelopmentFlow initialDevelopmentFlow = InitialDevelopmentFlow();

  /// Upgrade cycle framework — PD00-SSP-UPG (links tom_system_upgrade.md).
  UpgradeCycleFramework upgradeCycleFramework = UpgradeCycleFramework();
}
