/// D07 — Integration & Interface Specification.
///
/// Phase 3 DocSpec root class. Aggregates 10 top-level sections projected
/// from the corresponding Solution Blueprint system-boundary sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// IIS00 Integration & Interface Specification.
///
/// Complete interaction specification between the target system and
/// external systems: inventory, patterns, testing, dependencies,
/// migration, operational concerns, and cross-boundary error handling.
@Document(
  name: 'Integration & Interface Specification',
  description: 'Complete specification of interactions between the target '
      'system and external systems — inventory, patterns, testing, '
      'dependencies, migration, operations, and error handling.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('IIS')
class D07IntegrationInterfaceSpecification {
  @ContentHelp('Executive overview of the system-boundary interaction '
      'specification.')
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// External interfaces.
  @SerializationOrder(2)
  ExternalInterfaces externalInterfaces = ExternalInterfaces();

  /// Out of scope.
  @SerializationOrder(3)
  OutOfScope outOfScope = OutOfScope();

  /// Boundary assumptions.
  @SerializationOrder(4)
  BoundaryAssumptions boundaryAssumptions = BoundaryAssumptions();

  /// System landscape inventory.
  @SerializationOrder(5)
  SystemLandscapeInventory systemInventory = SystemLandscapeInventory();

  /// Boundary interaction patterns.
  @SectionId('BOINPA-INTE-LST')
  @SectionIdPattern('BOINPA-INTE-xxx')
  @SerializationOrder(6)
  List<BoundaryInteractionPatterns> interactionPatterns = [];

  /// Interaction testing strategy.
  @SerializationOrder(7)
  InteractionTestingStrategy testingStrategy = InteractionTestingStrategy();

  /// Interaction dependency analysis.
  @SerializationOrder(8)
  InteractionDependencyAnalysis dependencyAnalysis =
      InteractionDependencyAnalysis();

  /// Migration interactions.
  @SectionId('MIIN-MIGR-LST')
  @SectionIdPattern('MIIN-MIGR-xxx')
  @SerializationOrder(9)
  List<MigrationInteractions> migrationInteractions = [];

  /// Cross-boundary operational considerations.
  @SectionId('CBOC-OPER-LST')
  @SectionIdPattern('CBOC-OPER-xxx')
  @SerializationOrder(10)
  List<CrossBoundaryOperationalConsiderations> operationalConsiderations = [];

  /// Cross-boundary error handling.
  @SerializationOrder(11)
  CrossBoundaryErrorHandling crossBoundaryErrorHandling =
      CrossBoundaryErrorHandling();
}
