/// UC — Use Cases.
///
/// Phase 3 DocSpec root class. Aggregates 7 top-level sections from
/// PD00-TAR-STP (single seed, flattened) per §5.4 of
/// second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// UC00 Use Cases.
///
/// Detailed use cases derived from the target process steps and actor
/// interactions — Cockburn-style catalog, scenarios, end-to-end tests,
/// and traceability.
@Document(
  name: 'Use Cases',
  description: 'Use cases derived from the target process steps and actor '
      'interactions — catalog, scenarios, diagrams, end-to-end test '
      'scenarios (HBSG AS24), and traceability.',
  basedOn: [ProjectDefinition],
)
@SectionId('UC00')
class UseCases {
  @ContentHelp('Executive overview of the use-case model and its coverage.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Process steps overview — PD00-TAR-STP-OVE.
  ProcessStepsOverview processStepsOverview = ProcessStepsOverview();

  /// Actor overview — PD00-TAR-STP-ACT.
  ActorOverview actorOverview = ActorOverview();

  /// Interaction catalog — PD00-TAR-STP-INT.
  InteractionCatalog interactionCatalog = InteractionCatalog();

  /// Key scenarios — PD00-TAR-STP-SCE.
  KeyScenarios keyScenarios = KeyScenarios();

  /// Actor relationship diagram — PD00-TAR-STP-DIA.
  ActorRelationshipDiagram actorRelationshipDiagram =
      ActorRelationshipDiagram();

  /// End-to-end test scenarios — PD00-TAR-STP-E2E (covers HBSG AS24).
  EndToEndTestScenarios endToEndTestScenarios = EndToEndTestScenarios();

  /// Use case traceability — PD00-TAR-STP-TRC.
  UseCaseTraceability useCaseTraceability = UseCaseTraceability();
}
