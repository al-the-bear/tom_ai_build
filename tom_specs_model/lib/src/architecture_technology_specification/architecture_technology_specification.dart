/// D06 — Architecture & Technology Specification.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections projected
/// from the Solution Blueprint technical-framework, components,
/// technical-framework-conditions, and translation-handling sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// ATS00 Architecture & Technology Specification.
///
/// Comprehensive technical requirements: basic / software / standard-
/// software / hardware / operations / communication / system-operation
/// / security / architecture, plus components, framework conditions,
/// and translation handling.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The comprehensive technical requirements and architecture specification covering platform, software design, hardware, operations, communication, security, and components.',
)
@Document(
  name: 'Architecture & Technology Specification',
  description:
      'Comprehensive technical requirements — platform, '
      'software design, standard software, hardware, operations, '
      'communication, system operation, security, architecture, '
      'components, framework conditions, and translation handling.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('ATS')
class D06ArchitectureTechnologySpecification extends DocSpecsSection {
  @ContentHelp('Executive overview of the technical-requirements set.')
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

  // ─── Technical Framework Concept (flattened) ─────────────────────────────

  /// Basic technical requirements.
  @SerializationOrder(4)
  BasicTechnicalRequirements basicTechnicalRequirements =
      BasicTechnicalRequirements();

  /// Software design requirements.
  @SerializationOrder(5)
  SoftwareDesignRequirements softwareDesignRequirements =
      SoftwareDesignRequirements();

  /// Standard application software requirements.
  @SerializationOrder(6)
  StandardSoftwareRequirements standardSoftwareRequirements =
      StandardSoftwareRequirements();

  /// Hardware concept requirements.
  @SerializationOrder(7)
  HardwareRequirements hardwareRequirements = HardwareRequirements();

  /// Operations requirements.
  @SerializationOrder(8)
  OperationsRequirements operationsRequirements = OperationsRequirements();

  /// Communication requirements.
  @SerializationOrder(9)
  CommunicationRequirements communicationRequirements =
      CommunicationRequirements();

  /// System operation and monitoring.
  @SerializationOrder(10)
  SystemOperationAndMonitoring systemOperationAndMonitoring =
      SystemOperationAndMonitoring();

  /// Technical security requirements.
  @SerializationOrder(11)
  TechnicalSecurityRequirements technicalSecurityRequirements =
      TechnicalSecurityRequirements();

  /// System architecture (new in Phase A).
  @SerializationOrder(12)
  SystemArchitectureSpec systemArchitecture = SystemArchitectureSpec();

  // ─── Whole seeds from other SBP branches ────────────────────────────────

  /// Components to use (whole).
  @SerializationOrder(13)
  ComponentsAndDependencies componentsToUse = ComponentsAndDependencies();

  /// Technical framework conditions (whole).
  @SerializationOrder(14)
  TechnicalEnvironment technicalEnvironment = TechnicalEnvironment();

  /// Translation handling requirements (whole).
  @SerializationOrder(15)
  TranslationRequirements translationRequirements = TranslationRequirements();
}
