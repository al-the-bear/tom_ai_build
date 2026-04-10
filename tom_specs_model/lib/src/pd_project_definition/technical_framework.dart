/// Section 8: Technical Framework Concept [PD00-TEC]. Seeds → TR.
///
/// Technical framework requirements and constraints.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 8. Technical Framework Concept [PD00-TEC]. Seeds → TR.
class TechnicalFrameworkConcept {
  String? content;

  /// 8.1. Basic Technical Requirements [PD00-TEC-BAS].
  BasicTechnicalRequirements basicRequirements = BasicTechnicalRequirements();

  /// 8.2. Software Design Requirements [PD00-TEC-SOF].
  SoftwareDesignRequirements softwareDesign = SoftwareDesignRequirements();

  /// 8.3. Standard Application Software Requirements [PD00-TEC-STA].
  StandardSoftwareRequirements standardSoftware = StandardSoftwareRequirements();

  /// 8.4. Hardware Concept Requirements [PD00-TEC-HAR].
  HardwareRequirements hardware = HardwareRequirements();

  /// 8.5. Operations Requirements [PD00-TEC-OPE].
  OperationsRequirements operations = OperationsRequirements();

  /// 8.6. Communication Requirements [PD00-TEC-COM].
  CommunicationRequirements communication = CommunicationRequirements();

  /// 8.7. System Operation and Monitoring [PD00-TEC-SYS].
  SystemOperationAndMonitoring systemOperation = SystemOperationAndMonitoring();

  /// 8.8. Security Requirements [PD00-TEC-SEC].
  TechnicalSecurityRequirements security = TechnicalSecurityRequirements();
}

/// 8.1. Basic Technical Requirements [PD00-TEC-BAS].
class BasicTechnicalRequirements {
  String? content;

  /// Platform And Language.
  TextSection platformAndLanguage = TextSection();

  /// Architecture Style.
  TextSection architectureStyle = TextSection();

  /// 8.1.3. Design Patterns and Standards [PD00-TEC-BAS-PAT] — contains 0+× DesignPattern.
  List<DesignPatternEntry> designPatternsAndStandards = [];
}

/// A design pattern or standard entry (form) [PD00-TEC-BAS-PAT-nn].
class DesignPatternEntry {
  @Form([
    Field('patternName', String, 'Pattern Name', required: true),
    Field('purpose', String, 'Purpose'),
  ])

  String? content;
}

/// 8.2. Software Design Requirements [PD00-TEC-SOF].
class SoftwareDesignRequirements {
  String? content;

  /// Layering And Module Structure.
  TextSection layeringAndModuleStructure = TextSection();

  /// Development Environment.
  TextSection developmentEnvironment = TextSection();

  /// 8.2.3. Reusable Components [PD00-TEC-SOF-REU] — contains 0+× ReusableComponent.
  List<ReusableComponentEntry> reusableComponents = [];
}

/// A reusable component entry (form) [PD00-TEC-SOF-REU-nn].
class ReusableComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name', required: true),
    Field('source', String, 'Source'),
    Field('purpose', String, 'Purpose'),
  ])

  String? content;
}

/// 8.3. Standard Application Software Requirements [PD00-TEC-STA].
class StandardSoftwareRequirements {
  String? content;

  /// 8.3.1. Compatibility Requirements [PD00-TEC-STA-COM] — contains 0+× CompatibilityRequirement.
  List<CompatibilityRequirementEntry> compatibilityRequirements = [];

  /// Standards Compliance.
  TextSection standardsCompliance = TextSection();
}

/// A compatibility requirement entry (form) [PD00-TEC-STA-COM-nn].
class CompatibilityRequirementEntry {
  @Form([
    Field('requirement', String, 'Requirement'),
    Field('system', String, 'System'),
  ])

  String? content;
}

/// 8.4. Hardware Concept Requirements [PD00-TEC-HAR].
class HardwareRequirements {
  String? content;

  /// Server Requirements.
  TextSection serverRequirements = TextSection();

  /// Client Requirements.
  TextSection clientRequirements = TextSection();

  /// Network Requirements.
  TextSection networkRequirements = TextSection();
}

/// 8.5. Operations Requirements [PD00-TEC-OPE].
class OperationsRequirements {
  String? content;

  /// Backup And Recovery.
  TextSection backupAndRecovery = TextSection();

  /// Deployment Strategy.
  TextSection deploymentStrategy = TextSection();

  /// Monitoring And Alerting.
  TextSection monitoringAndAlerting = TextSection();

  /// Maintenance Windows.
  TextSection maintenanceWindows = TextSection();
}

/// 8.6. Communication Requirements [PD00-TEC-COM].
class CommunicationRequirements {
  String? content;

  /// 8.6.1. Protocols and Standards [PD00-TEC-COM-PRO] — contains 0+× Protocol.
  List<ProtocolEntry> protocolsAndStandards = [];

  /// External Connectivity.
  TextSection externalConnectivity = TextSection();
}

/// A protocol or standard entry (form) [PD00-TEC-COM-PRO-nn].
class ProtocolEntry {
  @Form([
    Field('protocolName', String, 'Protocol Name', required: true),
    Field('purpose', String, 'Purpose'),
  ])

  String? content;
}

/// 8.7. System Operation and Monitoring [PD00-TEC-SYS].
class SystemOperationAndMonitoring {
  String? content;

  /// 8.7.1. System Operation [PD00-TEC-SYS-OPE].
  SystemOperation systemOperation = SystemOperation();

  /// 8.7.2. Monitoring [PD00-TEC-SYS-MON].
  Monitoring monitoring = Monitoring();
}

/// 8.7.1. System Operation [PD00-TEC-SYS-OPE].
class SystemOperation {
  String? content;

  /// Administration Requirements.
  TextSection administrationRequirements = TextSection();

  /// Maintenance Procedures.
  TextSection maintenanceProcedures = TextSection();
}

/// 8.7.2. Monitoring [PD00-TEC-SYS-MON].
class Monitoring {
  String? content;

  /// Health Checks And Diagnostics.
  TextSection healthChecksAndDiagnostics = TextSection();

  /// Capacity Planning.
  TextSection capacityPlanning = TextSection();

  /// Alerting.
  TextSection alerting = TextSection();
}

/// 8.8. Security Requirements [PD00-TEC-SEC].
class TechnicalSecurityRequirements {
  String? content;

  /// 8.8.1. IT Security Standards [PD00-TEC-SEC-ITS] — contains 0+× SecurityStandard.
  List<SecurityStandardEntry> itSecurityStandards = [];

  /// Data Protection And Privacy.
  TextSection dataProtectionAndPrivacy = TextSection();

  /// 8.8.3. Security Audit Requirements [PD00-TEC-SEC-AUD] — contains 0+× SecurityAudit.
  List<SecurityAuditEntry> securityAuditRequirements = [];
}

/// A security standard entry (form) [PD00-TEC-SEC-ITS-nn].
class SecurityStandardEntry {
  @Form([
    Field('standardName', String, 'Standard Name', required: true),
    Field('version', String, 'Version'),
    Field('scope', String, 'Scope'),
  ])

  String? content;
}

/// A security audit requirement entry (form) [PD00-TEC-SEC-AUD-nn].
class SecurityAuditEntry {
  @Form([
    Field('requirement', String, 'Requirement'),
    Field('frequency', String, 'Frequency'),
  ])

  String? content;
}
