/// Section 8: Technical Framework Concept [PD00-TEC]. Seeds → TR.
///
/// Technical framework requirements and constraints.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 8. Technical Framework Concept [PD00-TEC]. Seeds → TR.
@tomReflector
class TechnicalFrameworkConcept {
  final String? content;

  /// 8.1. Basic Technical Requirements [PD00-TEC-BAS].
  final BasicTechnicalRequirements basicRequirements;

  /// 8.2. Software Design Requirements [PD00-TEC-SOF].
  final SoftwareDesignRequirements softwareDesign;

  /// 8.3. Standard Application Software Requirements [PD00-TEC-STA].
  final StandardSoftwareRequirements standardSoftware;

  /// 8.4. Hardware Concept Requirements [PD00-TEC-HAR].
  final HardwareRequirements hardware;

  /// 8.5. Operations Requirements [PD00-TEC-OPE].
  final OperationsRequirements operations;

  /// 8.6. Communication Requirements [PD00-TEC-COM].
  final CommunicationRequirements communication;

  /// 8.7. System Operation and Monitoring [PD00-TEC-SYS].
  final SystemOperationAndMonitoring systemOperation;

  /// 8.8. Security Requirements [PD00-TEC-SEC].
  final TechnicalSecurityRequirements security;

  const TechnicalFrameworkConcept({
    this.content,
    this.basicRequirements = const BasicTechnicalRequirements(),
    this.softwareDesign = const SoftwareDesignRequirements(),
    this.standardSoftware = const StandardSoftwareRequirements(),
    this.hardware = const HardwareRequirements(),
    this.operations = const OperationsRequirements(),
    this.communication = const CommunicationRequirements(),
    this.systemOperation = const SystemOperationAndMonitoring(),
    this.security = const TechnicalSecurityRequirements(),
  });
}

/// 8.1. Basic Technical Requirements [PD00-TEC-BAS].
@tomReflector
class BasicTechnicalRequirements {
  final String? content;

  /// 8.1.1. Platform and Language [PD00-TEC-BAS-PLA].
  final String? platformAndLanguage;

  /// 8.1.2. Architecture Style [PD00-TEC-BAS-ARC].
  final String? architectureStyle;

  /// 8.1.3. Design Patterns and Standards [PD00-TEC-BAS-PAT].
  final List<DesignPatternEntry> designPatternsAndStandards;

  const BasicTechnicalRequirements({
    this.content,
    this.platformAndLanguage,
    this.architectureStyle,
    this.designPatternsAndStandards = const [],
  });
}

/// A design pattern or standard entry (form).
@tomReflector
class DesignPatternEntry {
  final String? content;
  final String? patternName;
  final String? purpose;

  const DesignPatternEntry({this.content, this.patternName, this.purpose});
}

/// 8.2. Software Design Requirements [PD00-TEC-SOF].
@tomReflector
class SoftwareDesignRequirements {
  final String? content;

  /// 8.2.1. Layering and Module Structure [PD00-TEC-SOF-LAY].
  final String? layeringAndModuleStructure;

  /// 8.2.2. Development Environment [PD00-TEC-SOF-DEV].
  final String? developmentEnvironment;

  /// 8.2.3. Reusable Components [PD00-TEC-SOF-REU].
  final List<ReusableComponentEntry> reusableComponents;

  const SoftwareDesignRequirements({
    this.content,
    this.layeringAndModuleStructure,
    this.developmentEnvironment,
    this.reusableComponents = const [],
  });
}

/// A reusable component entry (form).
@tomReflector
class ReusableComponentEntry {
  final String? content;
  final String? componentName;
  final String? source;
  final String? purpose;

  const ReusableComponentEntry({
    this.content,
    this.componentName,
    this.source,
    this.purpose,
  });
}

/// 8.3. Standard Application Software Requirements [PD00-TEC-STA].
@tomReflector
class StandardSoftwareRequirements {
  final String? content;

  /// 8.3.1. Compatibility Requirements [PD00-TEC-STA-COM].
  final List<CompatibilityRequirementEntry> compatibilityRequirements;

  /// 8.3.2. Standards Compliance [PD00-TEC-STA-STD].
  final String? standardsCompliance;

  const StandardSoftwareRequirements({
    this.content,
    this.compatibilityRequirements = const [],
    this.standardsCompliance,
  });
}

/// A compatibility requirement entry (form).
@tomReflector
class CompatibilityRequirementEntry {
  final String? content;
  final String? requirement;
  final String? system;

  const CompatibilityRequirementEntry({
    this.content,
    this.requirement,
    this.system,
  });
}

/// 8.4. Hardware Concept Requirements [PD00-TEC-HAR].
@tomReflector
class HardwareRequirements {
  final String? content;

  /// 8.4.1. Server Requirements [PD00-TEC-HAR-SRV].
  final String? serverRequirements;

  /// 8.4.2. Client Requirements [PD00-TEC-HAR-CLI].
  final String? clientRequirements;

  /// 8.4.3. Network Requirements [PD00-TEC-HAR-NET].
  final String? networkRequirements;

  const HardwareRequirements({
    this.content,
    this.serverRequirements,
    this.clientRequirements,
    this.networkRequirements,
  });
}

/// 8.5. Operations Requirements [PD00-TEC-OPE].
@tomReflector
class OperationsRequirements {
  final String? content;

  /// 8.5.1. Backup and Recovery [PD00-TEC-OPE-BAC].
  final String? backupAndRecovery;

  /// 8.5.2. Deployment Strategy [PD00-TEC-OPE-DEP].
  final String? deploymentStrategy;

  /// 8.5.3. Monitoring and Alerting [PD00-TEC-OPE-MON].
  final String? monitoringAndAlerting;

  /// 8.5.4. Maintenance Windows [PD00-TEC-OPE-MAI].
  final String? maintenanceWindows;

  const OperationsRequirements({
    this.content,
    this.backupAndRecovery,
    this.deploymentStrategy,
    this.monitoringAndAlerting,
    this.maintenanceWindows,
  });
}

/// 8.6. Communication Requirements [PD00-TEC-COM].
@tomReflector
class CommunicationRequirements {
  final String? content;

  /// 8.6.1. Protocols and Standards [PD00-TEC-COM-PRO].
  final List<ProtocolEntry> protocolsAndStandards;

  /// 8.6.2. External Connectivity [PD00-TEC-COM-EXT].
  final String? externalConnectivity;

  const CommunicationRequirements({
    this.content,
    this.protocolsAndStandards = const [],
    this.externalConnectivity,
  });
}

/// A protocol or standard entry (form).
@tomReflector
class ProtocolEntry {
  final String? content;
  final String? protocolName;
  final String? purpose;

  const ProtocolEntry({this.content, this.protocolName, this.purpose});
}

/// 8.7. System Operation and Monitoring [PD00-TEC-SYS].
@tomReflector
class SystemOperationAndMonitoring {
  final String? content;

  /// 8.7.1. Administration Requirements [PD00-TEC-SYS-ADM].
  final String? administrationRequirements;

  /// 8.7.2. Health Checks and Diagnostics [PD00-TEC-SYS-HEA].
  final String? healthChecksAndDiagnostics;

  /// 8.7.3. Capacity Planning [PD00-TEC-SYS-CAP].
  final String? capacityPlanning;

  const SystemOperationAndMonitoring({
    this.content,
    this.administrationRequirements,
    this.healthChecksAndDiagnostics,
    this.capacityPlanning,
  });
}

/// 8.8. Security Requirements [PD00-TEC-SEC].
@tomReflector
class TechnicalSecurityRequirements {
  final String? content;

  /// 8.8.1. IT Security Standards [PD00-TEC-SEC-ITS].
  final List<SecurityStandardEntry> itSecurityStandards;

  /// 8.8.2. Data Protection and Privacy [PD00-TEC-SEC-PRI].
  final String? dataProtectionAndPrivacy;

  /// 8.8.3. Security Audit Requirements [PD00-TEC-SEC-AUD].
  final List<SecurityAuditEntry> securityAuditRequirements;

  const TechnicalSecurityRequirements({
    this.content,
    this.itSecurityStandards = const [],
    this.dataProtectionAndPrivacy,
    this.securityAuditRequirements = const [],
  });
}

/// A security standard entry (form).
@tomReflector
class SecurityStandardEntry {
  final String? content;
  final String? standardName;
  final String? version;
  final String? scope;

  const SecurityStandardEntry({
    this.content,
    this.standardName,
    this.version,
    this.scope,
  });
}

/// A security audit requirement entry (form).
@tomReflector
class SecurityAuditEntry {
  final String? content;
  final String? requirement;
  final String? frequency;

  const SecurityAuditEntry({
    this.content,
    this.requirement,
    this.frequency,
  });
}
