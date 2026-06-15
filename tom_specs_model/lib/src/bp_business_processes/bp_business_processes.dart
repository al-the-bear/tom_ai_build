/// BP — Business Processes.
///
/// Phase 3 DocSpec root class. Aggregates 10 top-level sections from
/// PD00-TAR-PRO (single seed, flattened) per §5.3 of
/// second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// BP00 Business Processes.
///
/// Target business process specification — vision, principles, catalog,
/// diagrams, improvements, relationships, detailed workflows,
/// cross-process analysis, exception handling, and KPIs.
@Document(
  name: 'Business Processes',
  description: 'Target business process specification — vision, design '
      'principles, catalog, diagrams, improvements, relationships, '
      'workflows, cross-process analysis, exceptions, and KPIs.',
  basedOn: [ProjectDefinition],
)
@SectionId('BP')
class BusinessProcesses {
  @ContentHelp('Executive overview of the target business process model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Process vision — PD00-TAR-PRO-VIS.
  ProcessVision processVision = ProcessVision();

  /// Design principles — PD00-TAR-PRO-PRI.
  ProcessDesignPrinciples designPrinciples = ProcessDesignPrinciples();

  /// Process catalog — PD00-TAR-PRO-CAT.
  ProcessCatalog processCatalog = ProcessCatalog();

  /// Process overview diagram — PD00-TAR-PRO-FLO.
  ProcessOverviewDiagram processOverviewDiagram = ProcessOverviewDiagram();

  /// Improvement summary — PD00-TAR-PRO-IMP.
  ProcessImprovementSummary improvementSummary = ProcessImprovementSummary();

  /// Process relationships — PD00-TAR-PRO-REL.
  ProcessRelationships processRelationships = ProcessRelationships();

  /// Detailed process workflows — PD00-TAR-PRO-DET.
  @SectionId('DEPRWO-DETA-LST')
  @SectionIdPattern('DEPRWO-DETA-xxx')
  List<DetailedProcessWorkflows> detailedWorkflows = [];

  /// Cross-process analysis — PD00-TAR-PRO-CRO.
  CrossProcessAnalysis crossProcessAnalysis = CrossProcessAnalysis();

  /// Process exception handling — PD00-TAR-PRO-EXC.
  ProcessExceptionHandling exceptionHandling = ProcessExceptionHandling();

  /// Process metrics and KPIs — PD00-TAR-PRO-MET.
  @SectionId('PMAK-PROC-LST')
  @SectionIdPattern('PMAK-PROC-xxx')
  List<ProcessMetricsAndKpis> processMetricsAndKpis = [];
}
