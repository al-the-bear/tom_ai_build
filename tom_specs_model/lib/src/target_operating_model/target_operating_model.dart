/// D02 — Target Operating Model.
///
/// Phase 3 DocSpec root class. Aggregates 10 top-level sections projected
/// (flattened) from the Solution Blueprint target-process sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
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
  description: 'Target business process specification — vision, design '
      'principles, catalog, diagrams, improvements, relationships, '
      'workflows, cross-process analysis, exceptions, and KPIs.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('TOM')
class D02TargetOperatingModel {
  @ContentHelp('Executive overview of the target business process model.')
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// Process vision.
  @SerializationOrder(2)
  ProcessVision processVision = ProcessVision();

  /// Design principles.
  @SerializationOrder(3)
  ProcessDesignPrinciples designPrinciples = ProcessDesignPrinciples();

  /// Process catalog.
  @SerializationOrder(4)
  ProcessCatalog processCatalog = ProcessCatalog();

  /// Process overview diagram.
  @SerializationOrder(5)
  ProcessOverviewDiagram processOverviewDiagram = ProcessOverviewDiagram();

  /// Improvement summary.
  @SerializationOrder(6)
  ProcessImprovementSummary improvementSummary = ProcessImprovementSummary();

  /// Process relationships.
  @SerializationOrder(7)
  ProcessRelationships processRelationships = ProcessRelationships();

  /// Detailed process workflows.
  @SectionId('DEPRWO-DETA-LST')
  @SectionIdPattern('DEPRWO-DETA-xxx')
  @SerializationOrder(8)
  List<DetailedProcessWorkflow> detailedWorkflows = [];

  /// Cross-process analysis.
  @SerializationOrder(9)
  CrossProcessAnalysis crossProcessAnalysis = CrossProcessAnalysis();

  /// Process exception handling.
  @SerializationOrder(10)
  ProcessExceptionHandling exceptionHandling = ProcessExceptionHandling();

  /// Process metrics and KPIs.
  @SectionId('PMAK-PROC-LST')
  @SectionIdPattern('PMAK-PROC-xxx')
  @SerializationOrder(11)
  List<ProcessMetric> processMetricsAndKpis = [];
}
