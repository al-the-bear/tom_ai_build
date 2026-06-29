/// D11 — Delivery Roadmap.
///
/// Phase 3 DocSpec root class. Aggregates 9 top-level sections projected
/// (with governance flattened) from the Solution Blueprint system-stage
/// sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// DRM00 Delivery Roadmap.
///
/// Full project phase plan — staging strategy, stage overview, per-stage
/// entries, feature prioritization, data migration, gate criteria,
/// decision processes, initial development flow, and upgrade cycle
/// framework.
@Document(
  name: 'Delivery Roadmap',
  description: 'Comprehensive project phase plan — staging strategy, '
      'stages, feature prioritization, migration, gates, decisions, '
      'initial development flow, and upgrade cycle framework (bridge '
      'to tom_system_upgrade.md).',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('DRM')
class D11DeliveryRoadmap {
  @ContentHelp('Executive overview of the phase plan and its gate model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Staging strategy.
  StagingStrategy stagingStrategy = StagingStrategy();

  /// Stage overview.
  StageOverview stageOverview = StageOverview();

  /// Stages (list).
  @SectionId('STAGE-STAG-LST')
  @SectionIdPattern('STAGE-STAG-xxx')
  @Min(1)
  List<StageEntry> stages = [];

  /// Feature prioritization.
  FeaturePrioritization featurePrioritization = FeaturePrioritization();

  /// Data migration strategy.
  DataMigrationStrategy dataMigrationStrategy = DataMigrationStrategy();

  /// Gate criteria (promoted from GOV).
  PhaseGateReviews gateCriteria = PhaseGateReviews();

  /// Decision processes (promoted from GOV).
  DecisionPoints decisionProcesses = DecisionPoints();

  /// Initial development flow.
  InitialDevelopmentFlow initialDevelopmentFlow = InitialDevelopmentFlow();

  /// Upgrade cycle framework (links tom_system_upgrade.md).
  UpgradeCycleFramework upgradeCycleFramework = UpgradeCycleFramework();
}
