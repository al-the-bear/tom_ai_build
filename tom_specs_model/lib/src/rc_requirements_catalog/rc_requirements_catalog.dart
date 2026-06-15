/// RC — Requirements Catalog.
///
/// Phase 3 DocSpec root class. Aggregates 7 top-level sections from
/// PD00-SYO-REQ (single seed, flattened) per §5.2 of
/// second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// RC00 Requirements Catalog.
///
/// Full requirements catalog covering functional, technical, security,
/// and organizational requirements, plus traceability, relationships,
/// and coverage analysis.
@Document(
  name: 'Requirements Catalog',
  description: 'Complete requirements catalog — functional, technical, '
      'security, organizational — with traceability, relationships, and '
      'coverage against goals, use cases, and tests.',
  basedOn: [ProjectDefinition],
)
@SectionId('RC')
class RequirementsCatalog {
  @ContentHelp('Executive overview of the requirements catalog and its '
      'traceability model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Functional requirements — PD00-SYO-REQ-FUN.
  FunctionalRequirements functionalRequirements = FunctionalRequirements();

  /// Technical (non-functional) requirements — PD00-SYO-REQ-TEC.
  TechnicalRequirements technicalRequirements = TechnicalRequirements();

  /// Security requirements — PD00-SYO-REQ-SEC.
  SecurityRequirements securityRequirements = SecurityRequirements();

  /// Organizational requirements — PD00-SYO-REQ-ORG.
  OrganizationalRequirements organizationalRequirements =
      OrganizationalRequirements();

  /// Traceability matrix overview — PD00-SYO-REQ-TRC.
  ///
  /// Mirrors the PD00-side flat field on RequirementsOverview so the RC
  /// outline reaches it directly. The authoritative content lives on the
  /// PD00 side.
  @ContentType('description', 'Summary of traceability matrix showing '
      'connections between requirements, goals, use cases, and tests.')
  String? traceabilityMatrix;

  /// Requirement relationships — PD00-SYO-REQ-REL.
  @SectionId('RERE-REQU-LST')
  @SectionIdPattern('RERE-REQU-xxx')
  List<RequirementRelationships> requirementRelationships = [];

  /// Requirement coverage — PD00-SYO-REQ-COV.
  RequirementCoverage requirementCoverage = RequirementCoverage();
}
