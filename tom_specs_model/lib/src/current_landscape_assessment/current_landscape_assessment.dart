/// D01 — Current Landscape Assessment.
///
/// Phase 3 DocSpec root class. Aggregates 8 top-level sections projected
/// from the corresponding Solution Blueprint current-landscape and
/// systems-to-replace sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
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
  description:
      'Detailed analysis of the current systems and processes the '
      'target system will replace — landscape, pain points, metrics, '
      'risks, replacement inventory, and migration considerations.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('CLA')
class D01CurrentLandscapeAssessment extends DocSpecsSection {
  @ContentHelp(
    'Executive overview of the current-state analysis that '
    'motivates the project.',
  )
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

  // ─── Current State Analysis ──────────────────────────────────────────────

  /// Existing systems landscape.
  @SerializationOrder(4)
  ExistingSystemsLandscape existingSystemsLandscape =
      ExistingSystemsLandscape();

  /// Current business processes.
  @SerializationOrder(5)
  CurrentBusinessProcesses currentBusinessProcesses =
      CurrentBusinessProcesses();

  /// Pain points and gaps.
  @SerializationOrder(6)
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// Current data landscape.
  @SerializationOrder(7)
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();

  /// Current operational metrics.
  @SectionId('CUOPME-OPER-LST')
  @SectionIdPattern('CUOPME-OPER-xxx')
  @SerializationOrder(8)
  List<CurrentOperationalMetric> operationalMetrics = [];

  /// Current-state risk assessment.
  @SerializationOrder(9)
  CurrentStateRiskAssessment currentStateRisks = CurrentStateRiskAssessment();

  // ─── Systems to Replace ──────────────────────────────────────────────────

  /// Replacement inventory.
  @SerializationOrder(10)
  ReplacementInventory replacementInventory = ReplacementInventory();

  /// Migration considerations.
  @SerializationOrder(11)
  MigrationConsiderations migrationConsiderations = MigrationConsiderations();
}
