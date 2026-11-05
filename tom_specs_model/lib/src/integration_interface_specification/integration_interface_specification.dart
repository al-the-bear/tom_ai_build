/// D07 — Integration & Interface Specification.
///
/// Phase 3 DocSpec root class. Aggregates 10 top-level sections projected
/// from the corresponding Solution Blueprint system-boundary sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// IIS00 Integration & Interface Specification.
///
/// Complete interaction specification between the target system and
/// external systems: inventory, patterns, testing, dependencies,
/// migration, operational concerns, and cross-boundary error handling.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — interface requirements'],
  'The complete specification of interactions between the target system and external systems, covering inventory, patterns, testing, dependencies, migration, and error handling.',
)
@Document(
  name: 'Integration & Interface Specification',
  description:
      'Complete specification of interactions between the target '
      'system and external systems — inventory, patterns, testing, '
      'dependencies, migration, operations, and error handling.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('IIS')
class D07IntegrationInterfaceSpecification extends DocSpecsSection {
  @ContentHelp(
    'Executive overview of the system-boundary interaction '
    'specification.',
  )
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

  /// External interfaces.
  @SerializationOrder(4)
  ExternalInterfaces externalInterfaces = ExternalInterfaces();

  /// Out of scope.
  @SerializationOrder(5)
  OutOfScope outOfScope = OutOfScope();

  /// Boundary assumptions.
  @SerializationOrder(6)
  BoundaryAssumptions boundaryAssumptions = BoundaryAssumptions();

  /// System landscape inventory.
  @SerializationOrder(7)
  SystemLandscapeInventory systemInventory = SystemLandscapeInventory();

  /// Boundary interaction patterns.
  @SectionId('BOINPA-INTE-LST')
  @SectionIdPattern('BOINPA-INTE-xxx')
  @SerializationOrder(8)
  List<BoundaryInteractionPatterns> interactionPatterns = [];

  /// Interaction testing strategy.
  @SerializationOrder(9)
  InteractionTestingStrategy testingStrategy = InteractionTestingStrategy();

  /// Interaction dependency analysis.
  @SerializationOrder(10)
  InteractionDependencyAnalysis dependencyAnalysis =
      InteractionDependencyAnalysis();

  /// Migration interactions.
  @SectionId('MIIN-MIGR-LST')
  @SectionIdPattern('MIIN-MIGR-xxx')
  @SerializationOrder(11)
  List<MigrationInteractions> migrationInteractions = [];

  /// Cross-boundary operational considerations.
  @SectionId('CBOC-OPER-LST')
  @SectionIdPattern('CBOC-OPER-xxx')
  @SerializationOrder(12)
  List<CrossBoundaryOperationalConsiderations> operationalConsiderations = [];

  /// Cross-boundary error handling.
  @SerializationOrder(13)
  CrossBoundaryErrorHandling crossBoundaryErrorHandling =
      CrossBoundaryErrorHandling();
}
