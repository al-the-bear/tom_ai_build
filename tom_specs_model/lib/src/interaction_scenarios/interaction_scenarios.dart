/// D05 — Interaction Scenarios.
///
/// Phase 3 DocSpec root class. Aggregates 7 top-level sections projected
/// (flattened) from the Solution Blueprint target-process-step sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// ISC00 Interaction Scenarios.
///
/// Detailed use cases derived from the target process steps and actor
/// interactions — Cockburn-style catalog, scenarios, end-to-end tests,
/// and traceability.
@StandardReferences(
  [
    'Cockburn — writing effective use cases',
    'BABOK v3 — future-state actor interactions',
  ],
  'The use-case model derived from the target process steps and actor interactions, with scenarios, end-to-end test scenarios, and traceability.',
)
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
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// Process steps overview.
  @SerializationOrder(2)
  ProcessStepsOverview processStepsOverview = ProcessStepsOverview();

  /// Actor overview.
  @SerializationOrder(3)
  ActorOverview actorOverview = ActorOverview();

  /// Interaction catalog.
  @SerializationOrder(4)
  InteractionCatalog interactionCatalog = InteractionCatalog();

  /// Key scenarios.
  @SerializationOrder(5)
  KeyScenarios keyScenarios = KeyScenarios();

  /// Actor relationship diagram.
  @SerializationOrder(6)
  ActorRelationshipDiagram actorRelationshipDiagram =
      ActorRelationshipDiagram();

  /// End-to-end test scenarios.
  @SectionId('ETETS-ENDT-LST')
  @SectionIdPattern('ETETS-ENDT-xxx')
  @SerializationOrder(7)
  List<EndToEndTestScenario> endToEndTestScenarios = [];

  /// Use case traceability.
  @SerializationOrder(8)
  UseCaseTraceability useCaseTraceability = UseCaseTraceability();
}
