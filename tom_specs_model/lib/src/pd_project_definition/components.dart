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
  final RuntimeDependencies runtimeDependencies;

  /// 12.5. Maintenance Dependencies [PD00-COM-MAI].
  final MaintenanceDependencies maintenanceDependencies;

  /// 12.6. Risk Assessment [PD00-COM-RIS].
  final ComponentRiskAssessment riskAssessment;

  const ComponentsToUse({
    this.content,
    this.strategy = const ComponentStrategy(),
    this.componentCatalog = const [],
    this.componentRoleInSystem,
    this.runtimeDependencies = const RuntimeDependencies(),
    this.maintenanceDependencies = const MaintenanceDependencies(),
    this.riskAssessment = const ComponentRiskAssessment(),
  });
}

/// 12.1. Component Strategy [PD00-COM-STR].
@tomReflector
class ComponentStrategy {
  final String? content;

  /// 12.1.1. Reuse Goals [PD00-COM-STR-GOA].
  final List<String> reuseGoals;

  /// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
  final EvaluationCriteria evaluationCriteria;

  const ComponentStrategy({
    this.content,
    this.reuseGoals = const [],
    this.evaluationCriteria = const EvaluationCriteria(),
  });
}

/// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
@tomReflector
class EvaluationCriteria {
  final String? content;
  final List<EvaluationCriterionEntry> items;

  const EvaluationCriteria({this.content, this.items = const []});
}

/// An evaluation criterion entry (form).
@tomReflector
class EvaluationCriterionEntry {
  final String? content;
  final String? criterion;
  final String? weight;
  final String? description;

  const EvaluationCriterionEntry({
    this.content,
    this.criterion,
    this.weight,
    this.description,
  });
}

/// 12.4. Runtime Dependencies [PD00-COM-RUN].
@tomReflector
class RuntimeDependencies {
  final String? content;
  final List<DependencyEntry> items;

  const RuntimeDependencies({this.content, this.items = const []});
}

/// 12.5. Maintenance Dependencies [PD00-COM-MAI].
@tomReflector
class MaintenanceDependencies {
  final String? content;
  final List<DependencyEntry> items;

  const MaintenanceDependencies({this.content, this.items = const []});
}

/// A dependency entry (form).
@tomReflector
class DependencyEntry {
  final String? content;
  final String? dependencyName;
  final String? version;
  final String? purpose;
  final String? criticality;
  final String? alternative;

  const DependencyEntry({
    this.content,
    this.dependencyName,
    this.version,
    this.purpose,
    this.criticality,
    this.alternative,
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

  /// Interfaces [PD00-COM-COM-nn-INT].
  final List<String> interfaces;

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
    this.interfaces = const [],
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
  final ContingencyPlans contingencyPlans;

  const ComponentRiskAssessment({
    this.content,
    this.risks = const [],
    this.contingencyPlans = const ContingencyPlans(),
  });
}

/// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
@tomReflector
class ContingencyPlans {
  final String? content;
  final List<ContingencyPlanEntry> items;

  const ContingencyPlans({this.content, this.items = const []});
}

/// A contingency plan entry (form).
@tomReflector
class ContingencyPlanEntry {
  final String? content;
  final String? component;
  final String? triggerCondition;
  final String? action;
  final String? responsibleParty;

  const ContingencyPlanEntry({
    this.content,
    this.component,
    this.triggerCondition,
    this.action,
    this.responsibleParty,
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
