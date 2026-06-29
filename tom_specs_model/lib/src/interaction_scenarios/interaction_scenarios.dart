/// UC — Use Cases.
///
/// Phase 3 DocSpec root class. Aggregates 7 top-level sections projected
/// (flattened) from the Solution Blueprint target-process-step sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// UC00 Use Cases.
///
/// Detailed use cases derived from the target process steps and actor
/// interactions — Cockburn-style catalog, scenarios, end-to-end tests,
/// and traceability.
@Document(
  name: 'Interaction Scenarios',
  description: 'Use cases derived from the target process steps and actor '
      'interactions — catalog, scenarios, diagrams, end-to-end test '
      'scenarios, and traceability.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('ISC')
class D05InteractionScenarios {
  @ContentHelp('Executive overview of the use-case model and its coverage.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Process steps overview.
  ProcessStepsOverview processStepsOverview = ProcessStepsOverview();

  /// Actor overview.
  ActorOverview actorOverview = ActorOverview();

  /// Interaction catalog.
  InteractionCatalog interactionCatalog = InteractionCatalog();

  /// Key scenarios.
  KeyScenarios keyScenarios = KeyScenarios();

  /// Actor relationship diagram.
  ActorRelationshipDiagram actorRelationshipDiagram =
      ActorRelationshipDiagram();

  /// End-to-end test scenarios.
  @SectionId('ETETS-ENDT-LST')
  @SectionIdPattern('ETETS-ENDT-xxx')
  List<EndToEndTestScenarios> endToEndTestScenarios = [];

  /// Use case traceability.
  UseCaseTraceability useCaseTraceability = UseCaseTraceability();
}
