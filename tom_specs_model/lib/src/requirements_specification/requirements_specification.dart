/// RC — Requirements Catalog.
///
/// Phase 3 DocSpec root class. Aggregates 7 top-level sections projected
/// (flattened) from the Solution Blueprint requirements sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// RC00 Requirements Catalog.
///
/// Full requirements catalog covering functional, technical, security,
/// and organizational requirements, plus traceability, relationships,
/// and coverage analysis.
@Document(
  name: 'Requirements Specification',
  description: 'Complete requirements catalog — functional, technical, '
      'security, organizational — with traceability, relationships, and '
      'coverage against goals, use cases, and tests.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('RSP')
class D04RequirementsSpecification {
  @ContentHelp('Executive overview of the requirements catalog and its '
      'traceability model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Functional requirements.
  FunctionalRequirements functionalRequirements = FunctionalRequirements();

  /// Technical (non-functional) requirements.
  TechnicalRequirements technicalRequirements = TechnicalRequirements();

  /// Security requirements.
  SecurityRequirements securityRequirements = SecurityRequirements();

  /// Organizational requirements.
  OrganizationalRequirements organizationalRequirements =
      OrganizationalRequirements();

  /// Traceability matrix overview.
  ///
  /// Mirrors the flat field on RequirementsOverview so the RC outline
  /// reaches it directly. The authoritative content lives on the Solution
  /// Blueprint side.
  @ContentType('description', 'Summary of traceability matrix showing '
      'connections between requirements, goals, use cases, and tests.')
  String? traceabilityMatrix;

  /// Requirement relationships.
  @SectionId('RERE-REQU-LST')
  @SectionIdPattern('RERE-REQU-xxx')
  List<RequirementRelationships> requirementRelationships = [];

  /// Requirement coverage.
  RequirementCoverage requirementCoverage = RequirementCoverage();
}
