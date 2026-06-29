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
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Process vision.
  ProcessVision processVision = ProcessVision();

  /// Design principles.
  ProcessDesignPrinciples designPrinciples = ProcessDesignPrinciples();

  /// Process catalog.
  ProcessCatalog processCatalog = ProcessCatalog();

  /// Process overview diagram.
  ProcessOverviewDiagram processOverviewDiagram = ProcessOverviewDiagram();

  /// Improvement summary.
  ProcessImprovementSummary improvementSummary = ProcessImprovementSummary();

  /// Process relationships.
  ProcessRelationships processRelationships = ProcessRelationships();

  /// Detailed process workflows.
  @SectionId('DEPRWO-DETA-LST')
  @SectionIdPattern('DEPRWO-DETA-xxx')
  List<DetailedProcessWorkflows> detailedWorkflows = [];

  /// Cross-process analysis.
  CrossProcessAnalysis crossProcessAnalysis = CrossProcessAnalysis();

  /// Process exception handling.
  ProcessExceptionHandling exceptionHandling = ProcessExceptionHandling();

  /// Process metrics and KPIs.
  @SectionId('PMAK-PROC-LST')
  @SectionIdPattern('PMAK-PROC-xxx')
  List<ProcessMetricsAndKpis> processMetricsAndKpis = [];
}
