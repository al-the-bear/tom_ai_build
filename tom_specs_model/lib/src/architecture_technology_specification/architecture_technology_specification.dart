/// TR — Technical Requirements.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections from
/// four PD00 seeds (multi-source) per §5.7 of second_wave_documents.md:
/// PD00-TEC (flattened), PD00-COM (whole), PD00-SYO-RES-TEC (whole),
/// and PD00-USE-MUL-REQ (whole).
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
  name: 'Technical Requirements',
  description: 'Comprehensive technical requirements — platform, '
      'software design, standard software, hardware, operations, '
      'communication, system operation, security, architecture, '
      'components, framework conditions, and translation handling.',
  basedOn: [ProjectDefinition],
)
@SectionId('TR')
class TechnicalRequirementsSpec {
  @ContentHelp('Executive overview of the technical-requirements set.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── From PD00-TEC (Technical Framework Concept), flattened ──────────────

  /// Basic technical requirements — PD00-TEC-BAS.
  BasicTechnicalRequirements basicTechnicalRequirements =
      BasicTechnicalRequirements();

  /// Software design requirements — PD00-TEC-SOF.
  SoftwareDesignRequirements softwareDesignRequirements =
      SoftwareDesignRequirements();

  /// Standard application software requirements — PD00-TEC-STA.
  StandardSoftwareRequirements standardSoftwareRequirements =
      StandardSoftwareRequirements();

  /// Hardware concept requirements — PD00-TEC-HAR.
  HardwareRequirements hardwareRequirements = HardwareRequirements();

  /// Operations requirements — PD00-TEC-OPE.
  OperationsRequirements operationsRequirements = OperationsRequirements();

  /// Communication requirements — PD00-TEC-COM.
  CommunicationRequirements communicationRequirements =
      CommunicationRequirements();

  /// System operation and monitoring — PD00-TEC-SYS.
  SystemOperationAndMonitoring systemOperationAndMonitoring =
      SystemOperationAndMonitoring();

  /// Technical security requirements — PD00-TEC-SEC.
  TechnicalSecurityRequirements technicalSecurityRequirements =
      TechnicalSecurityRequirements();

  /// System architecture — PD00-TEC-ARC (new in Phase A, HBSG AS09-SOF/DR30).
  SystemArchitectureSpec systemArchitecture = SystemArchitectureSpec();

  // ─── Whole seeds from other PD00 branches ────────────────────────────────

  /// Components to use — PD00-COM (whole).
  ComponentsToUse componentsToUse = ComponentsToUse();

  /// Technical framework conditions — PD00-SYO-RES-TEC (whole).
  TechnicalFrameworkConditions technicalFrameworkConditions =
      TechnicalFrameworkConditions();

  /// Translation handling requirements — PD00-USE-MUL-REQ (whole).
  TranslationRequirements translationRequirements = TranslationRequirements();
}
