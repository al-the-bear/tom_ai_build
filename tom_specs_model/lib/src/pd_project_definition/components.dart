import '../common/common.dart';

/// Section 12: Components to Use [PD00-COM]. Seeds → TR.
///
/// External and standard components planned for use.
class ComponentsToUse {
  /// 12.1. Component Strategy [PD00-COM-STR].
  final ComponentStrategy strategy;

  /// 12.2. Component Catalog [PD00-COM-COM] — contains 0+× Component.
  final List<ComponentEntry> componentCatalog;

  /// 12.3. Component Role in System [PD00-COM-ROL].
  final String? componentRoleInSystem;

  /// 12.4. Runtime Dependencies [PD00-COM-RUN].
  final String? runtimeDependencies;

  /// 12.5. Maintenance Dependencies [PD00-COM-MAI].
  final String? maintenanceDependencies;

  /// 12.6. Risk Assessment [PD00-COM-RIS].
  final ComponentRiskAssessment riskAssessment;

  const ComponentsToUse({
    this.strategy = const ComponentStrategy(),
    this.componentCatalog = const [],
    this.componentRoleInSystem,
    this.runtimeDependencies,
    this.maintenanceDependencies,
    this.riskAssessment = const ComponentRiskAssessment(),
  });
}

/// 12.1. Component Strategy [PD00-COM-STR].
class ComponentStrategy {
  final String? reuseGoals;
  final String? evaluationCriteria;

  const ComponentStrategy({
    this.reuseGoals,
    this.evaluationCriteria,
  });
}

/// A component entry with its sub-entries [PD00-COM-COM-nn].
class ComponentEntry {
  final String componentName;
  final String version;
  final ComponentCategory category;
  final String purpose;
  final String? documentation;

  /// Interfaces description [PD00-COM-COM-nn-INT].
  final String? interfaces;

  /// Licensing [PD00-COM-COM-nn-LIC].
  final ComponentLicensing? licensing;

  /// Usage rights [PD00-COM-COM-nn-USE].
  final String? usageRights;

  /// Responsibilities [PD00-COM-COM-nn-RES].
  final ComponentResponsibilities? responsibilities;

  const ComponentEntry({
    required this.componentName,
    required this.version,
    required this.category,
    required this.purpose,
    this.documentation,
    this.interfaces,
    this.licensing,
    this.usageRights,
    this.responsibilities,
  });
}

/// Component licensing information [PD00-COM-COM-nn-LIC].
class ComponentLicensing {
  final String licenseModel;
  final String annualCost;
  final String? renewal;
  final String? redistribution;

  const ComponentLicensing({
    required this.licenseModel,
    required this.annualCost,
    this.renewal,
    this.redistribution,
  });
}

/// Component responsibilities [PD00-COM-COM-nn-RES].
class ComponentResponsibilities {
  final String technicalContact;
  final String supportModel;
  final String? escalation;
  final String? updateCadence;

  const ComponentResponsibilities({
    required this.technicalContact,
    required this.supportModel,
    this.escalation,
    this.updateCadence,
  });
}

/// 12.6. Risk Assessment [PD00-COM-RIS].
class ComponentRiskAssessment {
  /// 12.6.1. Component Risks — contains 0+× ComponentRisk.
  final List<ComponentRisk> risks;

  /// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
  final String? contingencyPlans;

  const ComponentRiskAssessment({
    this.risks = const [],
    this.contingencyPlans,
  });
}

/// A component risk [PD00-COM-RIS-RIS-nn].
class ComponentRisk {
  final String riskId;
  final String component;
  final String risk;
  final Probability probability;
  final Impact impact;
  final String mitigation;
  final String? contingencyTrigger;

  const ComponentRisk({
    required this.riskId,
    required this.component,
    required this.risk,
    required this.probability,
    required this.impact,
    required this.mitigation,
    this.contingencyTrigger,
  });
}
