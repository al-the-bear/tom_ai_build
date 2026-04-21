/// BSI — Business System Interactions.
///
/// Phase 3 DocSpec root class. Aggregates 10 top-level sections, all
/// reachable from PD00-SYO-SYB per §5.12 of second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// BSI00 Business System Interactions.
///
/// Complete interaction specification between the target system and
/// external systems: inventory, patterns, testing, dependencies,
/// migration, operational concerns, and cross-boundary error handling.
@Document(
  name: 'Business System Interactions',
  description: 'Complete specification of interactions between the target '
      'system and external systems — inventory, patterns, testing, '
      'dependencies, migration, operations, and error handling.',
  basedOn: [ProjectDefinition],
)
@SectionId('BSI')
class BusinessSystemInteractions {
  @ContentHelp('Executive overview of the system-boundary interaction '
      'specification.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// External interfaces — PD00-SYO-SYB-INT.
  ExternalInterfaces externalInterfaces = ExternalInterfaces();

  /// Out of scope — PD00-SYO-SYB-OUT.
  OutOfScope outOfScope = OutOfScope();

  /// Boundary assumptions — PD00-SYO-SYB-ASS.
  BoundaryAssumptions boundaryAssumptions = BoundaryAssumptions();

  /// System landscape inventory — PD00-SYO-SYB-INV.
  SystemLandscapeInventory systemInventory = SystemLandscapeInventory();

  /// Boundary interaction patterns — PD00-SYO-SYB-PAT.
  BoundaryInteractionPatterns interactionPatterns =
      BoundaryInteractionPatterns();

  /// Interaction testing strategy — PD00-SYO-SYB-TST.
  InteractionTestingStrategy testingStrategy = InteractionTestingStrategy();

  /// Interaction dependency analysis — PD00-SYO-SYB-DEP.
  InteractionDependencyAnalysis dependencyAnalysis =
      InteractionDependencyAnalysis();

  /// Migration interactions — PD00-SYO-SYB-MIG.
  MigrationInteractions migrationInteractions = MigrationInteractions();

  /// Cross-boundary operational considerations — PD00-SYO-SYB-OPE.
  CrossBoundaryOperationalConsiderations operationalConsiderations =
      CrossBoundaryOperationalConsiderations();

  /// Cross-boundary error handling — PD00-SYO-SYB-ERR.
  CrossBoundaryErrorHandling crossBoundaryErrorHandling =
      CrossBoundaryErrorHandling();
}
