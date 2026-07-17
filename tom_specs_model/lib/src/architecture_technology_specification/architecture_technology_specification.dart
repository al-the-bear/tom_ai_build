/// D06 — Architecture & Technology Specification.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections projected
/// from the Solution Blueprint technical-framework, components,
/// technical-framework-conditions, and translation-handling sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
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
  description: 'Comprehensive technical requirements — platform, '
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

  // ─── Technical Framework Concept (flattened) ─────────────────────────────

  /// Basic technical requirements.
  @SerializationOrder(2)
  BasicTechnicalRequirements basicTechnicalRequirements =
      BasicTechnicalRequirements();

  /// Software design requirements.
  @SerializationOrder(3)
  SoftwareDesignRequirements softwareDesignRequirements =
      SoftwareDesignRequirements();

  /// Standard application software requirements.
  @SerializationOrder(4)
  StandardSoftwareRequirements standardSoftwareRequirements =
      StandardSoftwareRequirements();

  /// Hardware concept requirements.
  @SerializationOrder(5)
  HardwareRequirements hardwareRequirements = HardwareRequirements();

  /// Operations requirements.
  @SerializationOrder(6)
  OperationsRequirements operationsRequirements = OperationsRequirements();

  /// Communication requirements.
  @SerializationOrder(7)
  CommunicationRequirements communicationRequirements =
      CommunicationRequirements();

  /// System operation and monitoring.
  @SerializationOrder(8)
  SystemOperationAndMonitoring systemOperationAndMonitoring =
      SystemOperationAndMonitoring();

  /// Technical security requirements.
  @SerializationOrder(9)
  TechnicalSecurityRequirements technicalSecurityRequirements =
      TechnicalSecurityRequirements();

  /// System architecture (new in Phase A).
  @SerializationOrder(10)
  SystemArchitectureSpec systemArchitecture = SystemArchitectureSpec();

  // ─── Whole seeds from other SBP branches ────────────────────────────────

  /// Components to use (whole).
  @SerializationOrder(11)
  ComponentsAndDependencies componentsToUse = ComponentsAndDependencies();

  /// Technical framework conditions (whole).
  @SerializationOrder(12)
  TechnicalEnvironment technicalEnvironment =
      TechnicalEnvironment();

  /// Translation handling requirements (whole).
  @SerializationOrder(13)
  TranslationRequirements translationRequirements = TranslationRequirements();
}
