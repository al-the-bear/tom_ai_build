/// Section 12: Components to Use [PD00-COM]. Seeds → TR.
///
/// External and standard components planned for use.
library;



/// 12. Components to Use [PD00-COM]. Seeds → TR.
class ComponentsToUse {
  String? content;

  /// 12.1. Component Strategy [PD00-COM-STR].
  ComponentStrategy strategy = ComponentStrategy();

  /// 12.2. Component Catalog [PD00-COM-COM] — contains 0+× Component.
  List<ComponentEntry> componentCatalog = [];

  /// 12.3. Component Role in System [PD00-COM-ROL].
  String? componentRoleInSystem;

  /// 12.4. Runtime Dependencies [PD00-COM-RUN].
  RuntimeDependencies runtimeDependencies = RuntimeDependencies();

  /// 12.5. Maintenance Dependencies [PD00-COM-MAI].
  MaintenanceDependencies maintenanceDependencies = MaintenanceDependencies();

  /// 12.6. Risk Assessment [PD00-COM-RIS].
  ComponentRiskAssessment riskAssessment = ComponentRiskAssessment();
}

/// 12.1. Component Strategy [PD00-COM-STR].
class ComponentStrategy {
  String? content;

  /// 12.1.1. Reuse Goals [PD00-COM-STR-GOA] — contains 0+× ReuseGoal.
  List<ReuseGoalEntry> reuseGoals = [];

  /// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
  EvaluationCriteria evaluationCriteria = EvaluationCriteria();
}

/// A reuse goal entry (form) [PD00-COM-STR-GOA-nn].
class ReuseGoalEntry {
  String? content;
  String? goal;
  String? rationale;
}

/// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
class EvaluationCriteria {
  String? content;
  /// Contains 0+× EvaluationCriterion.
  List<EvaluationCriterionEntry> items = [];
}

/// An evaluation criterion entry (form) [PD00-COM-STR-EVA-nn].
class EvaluationCriterionEntry {
  String? content;
  String? criterion;
  String? weight;
  String? description;
}

/// 12.4. Runtime Dependencies [PD00-COM-RUN].
class RuntimeDependencies {
  String? content;
  /// Contains 0+× Dependency.
  List<DependencyEntry> items = [];
}

/// 12.5. Maintenance Dependencies [PD00-COM-MAI].
class MaintenanceDependencies {
  String? content;
  /// Contains 0+× Dependency.
  List<DependencyEntry> items = [];
}

/// A dependency entry (form) [PD00-COM-RUN-nn].
class DependencyEntry {
  String? content;
  String? dependencyName;
  String? version;
  String? purpose;
  String? criticality;
  String? alternative;
}

// ---------------------------------------------------------------------------
// Component catalog entries
// ---------------------------------------------------------------------------

/// A component entry [PD00-COM-COM-nn] (form) with sub-entries.
class ComponentEntry {
  String? content;
  String? componentName;
  String? version;
  String? category;
  String? purpose;
  String? documentation;

  /// Interfaces [PD00-COM-COM-nn-INT] — contains 0+× ComponentInterface.
  List<ComponentInterfaceEntry> interfaces = [];

  /// Licensing [PD00-COM-COM-nn-LIC] (form).
  ComponentLicensingEntry? licensing;

  /// Usage Rights [PD00-COM-COM-nn-USE] (description).
  String? usageRights;

  /// Responsibilities [PD00-COM-COM-nn-RES] (form).
  ComponentResponsibilitiesEntry? responsibilities;
}

/// A component interface entry (form) [PD00-COM-COM-nn-INT-nn].
class ComponentInterfaceEntry {
  String? content;
  String? interfaceName;
  String? interfaceType;
  String? description;
}

/// Component licensing sub-entry [PD00-COM-COM-nn-LIC] (form).
class ComponentLicensingEntry {
  String? content;
  String? licenseModel;
  String? annualCost;
  String? renewal;
  String? redistribution;
}

/// Component responsibilities sub-entry [PD00-COM-COM-nn-RES] (form).
class ComponentResponsibilitiesEntry {
  String? content;
  String? technicalContact;
  String? supportModel;
  String? escalation;
  String? updateCadence;
}

// ---------------------------------------------------------------------------
// Risk assessment
// ---------------------------------------------------------------------------

/// 12.6. Risk Assessment [PD00-COM-RIS].
class ComponentRiskAssessment {
  String? content;

  /// 12.6.1. Component Risks [PD00-COM-RIS-RIS] — contains 0+× Risk.
  List<ComponentRiskEntry> risks = [];

  /// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
  ContingencyPlans contingencyPlans = ContingencyPlans();
}

/// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
class ContingencyPlans {
  String? content;
  /// Contains 0+× ContingencyPlan.
  List<ContingencyPlanEntry> items = [];
}

/// A contingency plan entry (form) [PD00-COM-RIS-CON-nn].
class ContingencyPlanEntry {
  String? content;
  String? component;
  String? triggerCondition;
  String? action;
  String? responsibleParty;
}

/// A component risk entry [PD00-COM-RIS-RIS-nn] (form).
class ComponentRiskEntry {
  String? content;
  String? riskId;
  String? component;
  String? risk;
  String? probability;
  String? impact;
  String? mitigation;
  String? contingencyTrigger;
}
