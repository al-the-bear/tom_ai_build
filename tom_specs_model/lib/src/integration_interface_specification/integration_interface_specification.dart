/// BSI — Business System Interactions.
///
/// Phase 3 DocSpec root class. Aggregates 10 top-level sections projected
/// from the corresponding Solution Blueprint system-boundary sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// BSI00 Business System Interactions.
///
/// Complete interaction specification between the target system and
/// external systems: inventory, patterns, testing, dependencies,
/// migration, operational concerns, and cross-boundary error handling.
@Document(
  name: 'Integration & Interface Specification',
  description: 'Complete specification of interactions between the target '
      'system and external systems — inventory, patterns, testing, '
      'dependencies, migration, operations, and error handling.',
  basedOn: [SolutionBlueprint],
)
@SectionId('IIS')
class IntegrationInterfaceSpecification {
  @ContentHelp('Executive overview of the system-boundary interaction '
      'specification.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// External interfaces.
  ExternalInterfaces externalInterfaces = ExternalInterfaces();

  /// Out of scope.
  OutOfScope outOfScope = OutOfScope();

  /// Boundary assumptions.
  BoundaryAssumptions boundaryAssumptions = BoundaryAssumptions();

  /// System landscape inventory.
  SystemLandscapeInventory systemInventory = SystemLandscapeInventory();

  /// Boundary interaction patterns.
  @SectionId('BOINPA-INTE-LST')
  @SectionIdPattern('BOINPA-INTE-xxx')
  List<BoundaryInteractionPatterns> interactionPatterns = [];

  /// Interaction testing strategy.
  InteractionTestingStrategy testingStrategy = InteractionTestingStrategy();

  /// Interaction dependency analysis.
  InteractionDependencyAnalysis dependencyAnalysis =
      InteractionDependencyAnalysis();

  /// Migration interactions.
  @SectionId('MIIN-MIGR-LST')
  @SectionIdPattern('MIIN-MIGR-xxx')
  List<MigrationInteractions> migrationInteractions = [];

  /// Cross-boundary operational considerations.
  @SectionId('CBOC-OPER-LST')
  @SectionIdPattern('CBOC-OPER-xxx')
  List<CrossBoundaryOperationalConsiderations> operationalConsiderations = [];

  /// Cross-boundary error handling.
  CrossBoundaryErrorHandling crossBoundaryErrorHandling =
      CrossBoundaryErrorHandling();
}
