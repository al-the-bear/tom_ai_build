/// D11 — Delivery Roadmap.
///
/// Phase 3 DocSpec root class. Aggregates 9 top-level sections projected
/// (with governance flattened) from the Solution Blueprint system-stage
/// sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
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
  description:
      'Comprehensive project phase plan — staging strategy, '
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

  /// This document's own review team; when it has members it replaces the
  /// Solution Blueprint's team for this document type and its default team.
  @SerializationOrder(2)
  ReviewTeam reviewTeam = ReviewTeam();

  /// Chronological revision history of this document, with the reviewers of
  /// each revision.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (revision history)',
  ], 'The ordered set of published revisions of this document.')
  @SectionId('RVENT-REVS-LST')
  @SectionIdPattern('RVENT-REVS-xxx')
  @ContentHelp(
    'Add one entry per revision, newest last: version, date, author, a short '
    'summary, the review team the round started with and the reviewers who '
    'returned a copy.',
  )
  @SerializationOrder(3)
  List<RevisionEntry> revisionHistory = [];

  /// Staging strategy.
  @SerializationOrder(4)
  StagingStrategy stagingStrategy = StagingStrategy();

  /// Stage overview.
  @SerializationOrder(5)
  StageOverview stageOverview = StageOverview();

  /// Stages (list).
  @SectionId('STAGE-STAG-LST')
  @SectionIdPattern('STAGE-STAG-xxx')
  @Min(1)
  @SerializationOrder(6)
  List<StageEntry> stages = [];

  /// Feature prioritization.
  @SerializationOrder(7)
  FeaturePrioritization featurePrioritization = FeaturePrioritization();

  /// Data migration strategy.
  @SerializationOrder(8)
  DataMigrationStrategy dataMigrationStrategy = DataMigrationStrategy();

  /// Gate criteria (promoted from GOV).
  @SerializationOrder(9)
  PhaseGateReviews gateCriteria = PhaseGateReviews();

  /// Decision processes (promoted from GOV).
  @SerializationOrder(10)
  DecisionPoints decisionProcesses = DecisionPoints();

  /// Initial development flow.
  @SerializationOrder(11)
  InitialDevelopmentFlow initialDevelopmentFlow = InitialDevelopmentFlow();

  /// Upgrade cycle framework (links tom_specs_project_flow.md §PF-UPG).
  @SerializationOrder(12)
  UpgradeCycleFramework upgradeCycleFramework = UpgradeCycleFramework();
}
