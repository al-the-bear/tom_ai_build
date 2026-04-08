/// Section 12: Components to Use [PD00-COM]. Seeds → TR.
///
/// External and standard components planned for use.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 12. Components to Use [PD00-COM]. Seeds → TR.
@tomReflector
class ComponentsToUse {
  final String? content;

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
    this.content,
    this.strategy = const ComponentStrategy(),
    this.componentCatalog = const [],
    this.componentRoleInSystem,
    this.runtimeDependencies,
    this.maintenanceDependencies,
    this.riskAssessment = const ComponentRiskAssessment(),
  });
}

/// 12.1. Component Strategy [PD00-COM-STR].
@tomReflector
class ComponentStrategy {
  final String? content;

  /// 12.1.1. Reuse Goals [PD00-COM-STR-GOA].
  final String? reuseGoals;

  /// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
  final String? evaluationCriteria;

  const ComponentStrategy({
    this.content,
    this.reuseGoals,
    this.evaluationCriteria,
  });
}

// ---------------------------------------------------------------------------
// Component catalog entries
// ---------------------------------------------------------------------------

/// A component entry [PD00-COM-COM-nn] (form) with sub-entries.
@tomReflector
class ComponentEntry {
  final String? content;
  final String? componentName;
  final String? version;
  final String? category;
  final String? purpose;
  final String? documentation;

  /// Interfaces [PD00-COM-COM-nn-INT] (description).
  final String? interfaces;

  /// Licensing [PD00-COM-COM-nn-LIC] (form).
  final ComponentLicensingEntry? licensing;

  /// Usage Rights [PD00-COM-COM-nn-USE] (description).
  final String? usageRights;

  /// Responsibilities [PD00-COM-COM-nn-RES] (form).
  final ComponentResponsibilitiesEntry? responsibilities;

  const ComponentEntry({
    this.content,
    this.componentName,
    this.version,
    this.category,
    this.purpose,
    this.documentation,
    this.interfaces,
    this.licensing,
    this.usageRights,
    this.responsibilities,
  });
}

/// Component licensing sub-entry [PD00-COM-COM-nn-LIC] (form).
@tomReflector
class ComponentLicensingEntry {
  final String? content;
  final String? licenseModel;
  final String? annualCost;
  final String? renewal;
  final String? redistribution;

  const ComponentLicensingEntry({
    this.content,
    this.licenseModel,
    this.annualCost,
    this.renewal,
    this.redistribution,
  });
}

/// Component responsibilities sub-entry [PD00-COM-COM-nn-RES] (form).
@tomReflector
class ComponentResponsibilitiesEntry {
  final String? content;
  final String? technicalContact;
  final String? supportModel;
  final String? escalation;
  final String? updateCadence;

  const ComponentResponsibilitiesEntry({
    this.content,
    this.technicalContact,
    this.supportModel,
    this.escalation,
    this.updateCadence,
  });
}

// ---------------------------------------------------------------------------
// Risk assessment
// ---------------------------------------------------------------------------

/// 12.6. Risk Assessment [PD00-COM-RIS].
@tomReflector
class ComponentRiskAssessment {
  final String? content;

  /// 12.6.1. Component Risks [PD00-COM-RIS-RIS] — contains 0+× Risk.
  final List<ComponentRiskEntry> risks;

  /// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
  final String? contingencyPlans;

  const ComponentRiskAssessment({
    this.content,
    this.risks = const [],
    this.contingencyPlans,
  });
}

/// A component risk entry [PD00-COM-RIS-RIS-nn] (form).
@tomReflector
class ComponentRiskEntry {
  final String? content;
  final String? riskId;
  final String? component;
  final String? risk;
  final String? probability;
  final String? impact;
  final String? mitigation;
  final String? contingencyTrigger;

  const ComponentRiskEntry({
    this.content,
    this.riskId,
    this.component,
    this.risk,
    this.probability,
    this.impact,
    this.mitigation,
    this.contingencyTrigger,
  });
}
