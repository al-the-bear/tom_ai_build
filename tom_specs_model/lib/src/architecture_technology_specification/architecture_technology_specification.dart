/// TR — Technical Requirements.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections projected
/// from the Solution Blueprint technical-framework, components,
/// technical-framework-conditions, and translation-handling sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// TR00 Technical Requirements.
///
/// Comprehensive technical requirements: basic / software / standard-
/// software / hardware / operations / communication / system-operation
/// / security / architecture, plus components, framework conditions,
/// and translation handling.
@Document(
  name: 'Architecture & Technology Specification',
  description: 'Comprehensive technical requirements — platform, '
      'software design, standard software, hardware, operations, '
      'communication, system operation, security, architecture, '
      'components, framework conditions, and translation handling.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('ATS')
class D06ArchitectureTechnologySpecification {
  @ContentHelp('Executive overview of the technical-requirements set.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── Technical Framework Concept (flattened) ─────────────────────────────

  /// Basic technical requirements.
  BasicTechnicalRequirements basicTechnicalRequirements =
      BasicTechnicalRequirements();

  /// Software design requirements.
  SoftwareDesignRequirements softwareDesignRequirements =
      SoftwareDesignRequirements();

  /// Standard application software requirements.
  StandardSoftwareRequirements standardSoftwareRequirements =
      StandardSoftwareRequirements();

  /// Hardware concept requirements.
  HardwareRequirements hardwareRequirements = HardwareRequirements();

  /// Operations requirements.
  OperationsRequirements operationsRequirements = OperationsRequirements();

  /// Communication requirements.
  CommunicationRequirements communicationRequirements =
      CommunicationRequirements();

  /// System operation and monitoring.
  SystemOperationAndMonitoring systemOperationAndMonitoring =
      SystemOperationAndMonitoring();

  /// Technical security requirements.
  TechnicalSecurityRequirements technicalSecurityRequirements =
      TechnicalSecurityRequirements();

  /// System architecture (new in Phase A).
  SystemArchitectureSpec systemArchitecture = SystemArchitectureSpec();

  // ─── Whole seeds from other SBP branches ────────────────────────────────

  /// Components to use (whole).
  ComponentsToUse componentsToUse = ComponentsToUse();

  /// Technical framework conditions (whole).
  TechnicalFrameworkConditions technicalFrameworkConditions =
      TechnicalFrameworkConditions();

  /// Translation handling requirements (whole).
  TranslationRequirements translationRequirements = TranslationRequirements();
}
