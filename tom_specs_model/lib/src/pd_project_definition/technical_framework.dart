/// Section 8: Technical Framework Concept [PD00-TEC]. Seeds → TR.
///
/// Technical framework requirements and constraints.
class TechnicalFrameworkConcept {
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
class BasicTechnicalRequirements {
  final String? platformAndLanguage;
  final String? architectureStyle;
  final String? designPatternsAndStandards;

  const BasicTechnicalRequirements({
    this.platformAndLanguage,
    this.architectureStyle,
    this.designPatternsAndStandards,
  });
}

/// 8.2. Software Design Requirements [PD00-TEC-SOF].
class SoftwareDesignRequirements {
  final String? layeringAndModuleStructure;
  final String? developmentEnvironment;
  final String? reusableComponents;

  const SoftwareDesignRequirements({
    this.layeringAndModuleStructure,
    this.developmentEnvironment,
    this.reusableComponents,
  });
}

/// 8.3. Standard Application Software Requirements [PD00-TEC-STA].
class StandardSoftwareRequirements {
  final String? compatibilityRequirements;
  final String? standardsCompliance;

  const StandardSoftwareRequirements({
    this.compatibilityRequirements,
    this.standardsCompliance,
  });
}

/// 8.4. Hardware Concept Requirements [PD00-TEC-HAR].
class HardwareRequirements {
  final String? serverRequirements;
  final String? clientRequirements;
  final String? networkRequirements;

  const HardwareRequirements({
    this.serverRequirements,
    this.clientRequirements,
    this.networkRequirements,
  });
}

/// 8.5. Operations Requirements [PD00-TEC-OPE].
class OperationsRequirements {
  final String? backupAndRecovery;
  final String? deploymentStrategy;
  final String? monitoringAndAlerting;
  final String? maintenanceWindows;

  const OperationsRequirements({
    this.backupAndRecovery,
    this.deploymentStrategy,
    this.monitoringAndAlerting,
    this.maintenanceWindows,
  });
}

/// 8.6. Communication Requirements [PD00-TEC-COM].
class CommunicationRequirements {
  final String? protocolsAndStandards;
  final String? externalConnectivity;

  const CommunicationRequirements({
    this.protocolsAndStandards,
    this.externalConnectivity,
  });
}

/// 8.7. System Operation and Monitoring [PD00-TEC-SYS].
class SystemOperationAndMonitoring {
  final String? administrationRequirements;
  final String? healthChecksAndDiagnostics;
  final String? capacityPlanning;

  const SystemOperationAndMonitoring({
    this.administrationRequirements,
    this.healthChecksAndDiagnostics,
    this.capacityPlanning,
  });
}

/// 8.8. Security Requirements [PD00-TEC-SEC].
class TechnicalSecurityRequirements {
  final String? itSecurityStandards;
  final String? dataProtectionAndPrivacy;
  final String? securityAuditRequirements;

  const TechnicalSecurityRequirements({
    this.itSecurityStandards,
    this.dataProtectionAndPrivacy,
    this.securityAuditRequirements,
  });
}
