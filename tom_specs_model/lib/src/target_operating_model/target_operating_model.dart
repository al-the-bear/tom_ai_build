/// D02 — Target Operating Model.
///
/// Phase 3 DocSpec root class. Aggregates 10 top-level sections projected
/// (flattened) from the Solution Blueprint target-process sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// TOM00 Target Operating Model.
///
/// Target business process specification — vision, principles, catalog,
/// diagrams, improvements, relationships, detailed workflows,
/// cross-process analysis, exception handling, and KPIs.
@StandardReferences(
  [
    'BABOK v3 — future-state definition',
    'BPMN 2.0 — business process modeling',
  ],
  'The target business process specification defining the future-state operating model, from process vision and design principles through detailed workflows and KPIs.',
)
@Document(
  name: 'Target Operating Model',
  description:
      'Target business process specification — vision, design '
      'principles, catalog, diagrams, improvements, relationships, '
      'workflows, cross-process analysis, exceptions, and KPIs.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('TOM')
class D02TargetOperatingModel extends DocSpecsSection {
  @ContentHelp('Executive overview of the target business process model.')
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

  /// Process vision.
  @SerializationOrder(4)
  ProcessVision processVision = ProcessVision();

  /// Design principles.
  @SerializationOrder(5)
  ProcessDesignPrinciples designPrinciples = ProcessDesignPrinciples();

  /// Process catalog.
  @SerializationOrder(6)
  ProcessCatalog processCatalog = ProcessCatalog();

  /// Process overview diagram.
  @SerializationOrder(7)
  ProcessOverviewDiagram processOverviewDiagram = ProcessOverviewDiagram();

  /// Improvement summary.
  @SerializationOrder(8)
  ProcessImprovementSummary improvementSummary = ProcessImprovementSummary();

  /// Process relationships.
  @SerializationOrder(9)
  ProcessRelationships processRelationships = ProcessRelationships();

  /// Detailed process workflows.
  @SectionId('DEPRWO-DETA-LST')
  @SectionIdPattern('DEPRWO-DETA-xxx')
  @SerializationOrder(10)
  List<DetailedProcessWorkflow> detailedWorkflows = [];

  /// Cross-process analysis.
  @SerializationOrder(11)
  CrossProcessAnalysis crossProcessAnalysis = CrossProcessAnalysis();

  /// Process exception handling.
  @SerializationOrder(12)
  ProcessExceptionHandling exceptionHandling = ProcessExceptionHandling();

  /// Process metrics and KPIs.
  @SectionId('PMAK-PROC-LST')
  @SectionIdPattern('PMAK-PROC-xxx')
  @SerializationOrder(13)
  List<ProcessMetric> processMetricsAndKpis = [];
}
