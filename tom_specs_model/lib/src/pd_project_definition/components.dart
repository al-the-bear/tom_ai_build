/// Section 12: Components to Use [PD00-COM]. Seeds → TR.
///
/// External and standard components planned for use.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 12. Components to Use [PD00-COM]. Seeds → TR.
@SectionId('PD00-COM')
@Comment('Seeds → TR')
class ComponentsToUse {
  @Unused()
  String? content;

  /// 12.1. Component Strategy [PD00-COM-STR].
  ComponentStrategy strategy = ComponentStrategy();

  /// 12.2. Component Catalog [PD00-COM-COM] — contains 0+× Component.
  @SectionIdPattern('PD00-COM-COM-xx')
  List<ComponentEntry> componentCatalog = [];

  /// Component Role In System.
  TextSection componentRoleInSystem = TextSection();

  /// 12.4. Runtime Dependencies [PD00-COM-RUN].
  RuntimeDependencies runtimeDependencies = RuntimeDependencies();

  /// 12.5. Maintenance Dependencies [PD00-COM-MAI].
  MaintenanceDependencies maintenanceDependencies = MaintenanceDependencies();

  /// 12.6. Risk Assessment [PD00-COM-RIS].
  ComponentRiskAssessment riskAssessment = ComponentRiskAssessment();
}

/// 12.1. Component Strategy [PD00-COM-STR].
@SectionId('PD00-COM-STR')
class ComponentStrategy {
  @Unused()
  String? content;

  /// 12.1.1. Reuse Goals [PD00-COM-STR-GOA] — contains 0+× ReuseGoal.
  @SectionIdPattern('PD00-COM-STR-GOA-xx')
  List<ReuseGoalEntry> reuseGoals = [];

  /// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
  EvaluationCriteria evaluationCriteria = EvaluationCriteria();
}

/// A reuse goal entry (form) [PD00-COM-STR-GOA-nn].
class ReuseGoalEntry {
  @Form([
    Field('goal', String, 'Goal', required: true),
    Field('rationale', String, 'Rationale'),
  ])
  String? content;
}

/// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
@SectionId('PD00-COM-STR-EVA')
class EvaluationCriteria {
  @Unused()
  String? content;

  /// Contains 0+× EvaluationCriterion.
  @SectionIdPattern('PD00-COM-STR-EVA-xx')
  List<EvaluationCriterionEntry> items = [];
}

/// An evaluation criterion entry (form) [PD00-COM-STR-EVA-nn].
class EvaluationCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('weight', String, 'Weight'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// 12.4. Runtime Dependencies [PD00-COM-RUN].
@SectionId('PD00-COM-RUN')
class RuntimeDependencies {
  @Unused()
  String? content;

  /// Contains 0+× Dependency.
  @SectionIdPattern('PD00-COM-RUN-xx')
  List<DependencyEntry> items = [];
}

/// 12.5. Maintenance Dependencies [PD00-COM-MAI].
@SectionId('PD00-COM-MAI')
class MaintenanceDependencies {
  @Unused()
  String? content;

  /// Contains 0+× Dependency.
  @SectionIdPattern('PD00-COM-MAI-xx')
  List<DependencyEntry> items = [];
}

/// A dependency entry (form) [PD00-COM-RUN-nn].
class DependencyEntry {
  @Form([
    Field('dependencyName', String, 'Dependency Name', required: true),
    Field('version', String, 'Version'),
    Field('purpose', String, 'Purpose'),
    Field('criticality', String, 'Criticality'),
    Field('alternative', String, 'Alternative'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// Component catalog entries
// ---------------------------------------------------------------------------

/// A component entry [PD00-COM-COM-nn] (form) with sub-entries.
class ComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name', required: true),
    Field('version', String, 'Version'),
    Field('category', String, 'Category'),
    Field('purpose', String, 'Purpose'),
    Field('documentation', String, 'Documentation'),
  ])
  String? content;

  /// Interfaces [PD00-COM-COM-nn-INT] — contains 0+× ComponentInterface.
  @SectionIdPattern('PD00-COM-COM-xx-INT-xx')
  List<ComponentInterfaceEntry> interfaces = [];

  /// Licensing [PD00-COM-COM-nn-LIC] (form).
  ComponentLicensingEntry? licensing;

  /// Usage Rights.
  TextSection usageRights = TextSection();

  /// Responsibilities [PD00-COM-COM-nn-RES] (form).
  ComponentResponsibilitiesEntry? responsibilities;
}

/// A component interface entry (form) [PD00-COM-COM-nn-INT-nn].
class ComponentInterfaceEntry {
  @Form([
    Field('interfaceName', String, 'Interface Name'),
    Field('interfaceType', String, 'Interface Type'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// Component licensing sub-entry [PD00-COM-COM-nn-LIC] (form).
class ComponentLicensingEntry {
  @Form([
    Field('licenseModel', String, 'License Model'),
    Field('annualCost', String, 'Annual Cost'),
    Field('renewal', String, 'Renewal'),
    Field('redistribution', String, 'Redistribution'),
  ])
  String? content;
}

/// Component responsibilities sub-entry [PD00-COM-COM-nn-RES] (form).
class ComponentResponsibilitiesEntry {
  @Form([
    Field('technicalContact', String, 'Technical Contact'),
    Field('supportModel', String, 'Support Model'),
    Field('escalation', String, 'Escalation'),
    Field('updateCadence', String, 'Update Cadence'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// Risk assessment
// ---------------------------------------------------------------------------

/// 12.6. Risk Assessment [PD00-COM-RIS].
@SectionId('PD00-COM-RIS')
class ComponentRiskAssessment {
  @Unused()
  String? content;

  /// 12.6.1. Component Risks [PD00-COM-RIS-RIS] — contains 0+× Risk.
  @SectionIdPattern('PD00-COM-RIS-RIS-xx')
  List<ComponentRiskEntry> risks = [];

  /// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
  ContingencyPlans contingencyPlans = ContingencyPlans();
}

/// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
@SectionId('PD00-COM-RIS-CON')
class ContingencyPlans {
  @Unused()
  String? content;

  /// Contains 0+× ContingencyPlan.
  @SectionIdPattern('PD00-COM-RIS-CON-xx')
  List<ContingencyPlanEntry> items = [];
}

/// A contingency plan entry (form) [PD00-COM-RIS-CON-nn].
class ContingencyPlanEntry {
  @Form([
    Field('component', String, 'Component'),
    Field('triggerCondition', String, 'Trigger Condition'),
    Field('action', String, 'Action'),
    Field('responsibleParty', String, 'Responsible Party'),
  ])
  String? content;
}

/// A component risk entry [PD00-COM-RIS-RIS-nn] (form).
class ComponentRiskEntry {
  @Form([
    Field('riskId', String, 'Risk Id', required: true),
    Field('component', String, 'Component'),
    Field('risk', String, 'Risk'),
    Field('probability', String, 'Probability'),
    Field('impact', String, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
    Field('contingencyTrigger', String, 'Contingency Trigger'),
  ])
  String? content;
}
