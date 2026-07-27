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
@StandardReferences(
  [
    'PMBOK Guide — project phasing and delivery roadmap',
    'ISO/IEC/IEEE 29148:2018 — transition planning',
  ],
  'The comprehensive project phase plan covering staging strategy, stages, feature prioritization, migration, gates, decisions, and the upgrade cycle framework.',
)
@Document(
  name: 'Delivery Roadmap',
  description: 'Comprehensive project phase plan — staging strategy, '
      'stages, feature prioritization, migration, gates, decisions, '
      'initial development flow, and upgrade cycle framework (bridge '
      'to tom_specs_project_flow.md §PF-UPG).',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('DRM')
class D11DeliveryRoadmap extends DocSpecsSection {
  @ContentHelp('Executive overview of the phase plan and its gate model.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// Staging strategy.
  @SerializationOrder(2)
  StagingStrategy stagingStrategy = StagingStrategy();

  /// Stage overview.
  @SerializationOrder(3)
  StageOverview stageOverview = StageOverview();

  /// Stages (list).
  @SectionId('STAGE-STAG-LST')
  @SectionIdPattern('STAGE-STAG-xxx')
  @Min(1)
  @SerializationOrder(4)
  List<StageEntry> stages = [];

  /// Feature prioritization.
  @SerializationOrder(5)
  FeaturePrioritization featurePrioritization = FeaturePrioritization();

  /// Data migration strategy.
  @SerializationOrder(6)
  DataMigrationStrategy dataMigrationStrategy = DataMigrationStrategy();

  /// Gate criteria (promoted from GOV).
  @SerializationOrder(7)
  PhaseGateReviews gateCriteria = PhaseGateReviews();

  /// Decision processes (promoted from GOV).
  @SerializationOrder(8)
  DecisionPoints decisionProcesses = DecisionPoints();

  /// Initial development flow.
  @SerializationOrder(9)
  InitialDevelopmentFlow initialDevelopmentFlow = InitialDevelopmentFlow();

  /// Upgrade cycle framework (links tom_specs_project_flow.md §PF-UPG).
  @SerializationOrder(10)
  UpgradeCycleFramework upgradeCycleFramework = UpgradeCycleFramework();
}
