/// D04 — Requirements Specification.
///
/// Phase 3 DocSpec root class. Aggregates 7 top-level sections projected
/// (flattened) from the Solution Blueprint requirements sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// RSP00 Requirements Specification.
///
/// Full requirements catalog covering functional, technical, security,
/// and organizational requirements, plus traceability, relationships,
/// and coverage analysis.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — software and system requirements specification'],
  'The complete requirements catalog covering functional, technical, security, and organizational requirements with traceability and coverage analysis.',
)
@Document(
  name: 'Requirements Specification',
  description: 'Complete requirements catalog — functional, technical, '
      'security, organizational — with traceability, relationships, and '
      'coverage against goals, use cases, and tests.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('RSP')
class D04RequirementsSpecification extends DocSpecsSection {
  @ContentHelp('Executive overview of the requirements catalog and its '
      'traceability model.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// Functional requirements.
  @SerializationOrder(2)
  FunctionalRequirements functionalRequirements = FunctionalRequirements();

  /// Technical (non-functional) requirements.
  @SerializationOrder(3)
  TechnicalRequirements technicalRequirements = TechnicalRequirements();

  /// Security requirements.
  @SerializationOrder(4)
  SecurityRequirements securityRequirements = SecurityRequirements();

  /// Organizational requirements.
  @SerializationOrder(5)
  OrganizationalRequirements organizationalRequirements =
      OrganizationalRequirements();

  /// Traceability matrix overview.
  ///
  /// Mirrors the flat field on RequirementsOverview so the RC outline
  /// reaches it directly. The authoritative content lives on the Solution
  /// Blueprint side.
  @SectionId('RSP-TRAC')
  @ContentType('description', 'Summary of traceability matrix showing '
      'connections between requirements, goals, use cases, and tests.')
  @SerializationOrder(6)
  DocSpecsSection? traceabilityMatrix;

  /// Requirement relationships.
  @SectionId('RERE-REQU-LST')
  @SectionIdPattern('RERE-REQU-xxx')
  @SerializationOrder(7)
  List<RequirementRelationships> requirementRelationships = [];

  /// Requirement coverage.
  @SerializationOrder(8)
  RequirementCoverage requirementCoverage = RequirementCoverage();
}
