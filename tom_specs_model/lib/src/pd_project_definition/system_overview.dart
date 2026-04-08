/// Section 4: System Overview [PD00-SYO].
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 4. System Overview [PD00-SYO].
@tomReflector
class SystemOverview {
  final String? content;

  /// 4.1. System Description [PD00-SYO-SYD].
  final SystemDescription systemDescription;

  /// 4.2. Goals [PD00-SYO-GOA].
  final Goals goals;

  /// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
  final RequirementsOverview requirements;

  /// 4.4. Systems to Replace [PD00-SYO-SYR]. Seeds → CS.
  final SystemsToReplace systemsToReplace;

  /// 4.5. System Boundaries [PD00-SYO-SYB]. Seeds → BSI.
  final SystemBoundaries systemBoundaries;

  /// 4.6. Framework Conditions [PD00-SYO-RES].
  final FrameworkConditions frameworkConditions;

  /// 4.7. Risks and Assumptions [PD00-SYO-RIS].
  final RisksAndAssumptions risksAndAssumptions;

  const SystemOverview({
    this.content,
    this.systemDescription = const SystemDescription(),
    this.goals = const Goals(),
    this.requirements = const RequirementsOverview(),
    this.systemsToReplace = const SystemsToReplace(),
    this.systemBoundaries = const SystemBoundaries(),
    this.frameworkConditions = const FrameworkConditions(),
    this.risksAndAssumptions = const RisksAndAssumptions(),
  });
}

// ---------------------------------------------------------------------------
// 4.1 System Description
// ---------------------------------------------------------------------------

/// 4.1. System Description [PD00-SYO-SYD].
@tomReflector
class SystemDescription {
  final String? content;

  /// 4.1.1. System Purpose [PD00-SYO-SYD-PUR].
  final String? systemPurpose;

  /// 4.1.2. System Context [PD00-SYO-SYD-CON].
  final String? systemContext;

  /// 4.1.3. Description of Task Area [PD00-SYO-SYD-DES].
  final String? taskArea;

  /// 4.1.4. User Categories [PD00-SYO-SYD-USR] — contains 1+× User Category.
  final List<UserCategoryEntry> userCategories;

  /// 4.1.5. User Interaction Model [PD00-SYO-SYD-USI].
  final String? userInteractionModel;

  const SystemDescription({
    this.content,
    this.systemPurpose,
    this.systemContext,
    this.taskArea,
    this.userCategories = const [],
    this.userInteractionModel,
  });
}

/// A user category entry [PD00-SYO-SYD-USR-nn] (form).
@tomReflector
class UserCategoryEntry {
  final String? content;
  final String? categoryName;
  final String? description;
  final String? technicalProficiency;
  final String? frequencyOfUse;
  final String? accessChannel;
  final String? estimatedUserCount;

  /// Role subsection [PD00-SYO-SYD-USR-nn-ROL] (form, singular).
  final UserCategoryRoleEntry? role;

  /// System Tasks [PD00-SYO-SYD-USR-nn-TSK] — contains 1+× System Task.
  final List<SystemTaskEntry> systemTasks;

  const UserCategoryEntry({
    this.content,
    this.categoryName,
    this.description,
    this.technicalProficiency,
    this.frequencyOfUse,
    this.accessChannel,
    this.estimatedUserCount,
    this.role,
    this.systemTasks = const [],
  });
}

/// Role within a user category [PD00-SYO-SYD-USR-nn-ROL] (form).
@tomReflector
class UserCategoryRoleEntry {
  final String? content;
  final String? roleName;
  final String? roleDescription;
  final String? organizationUnit;
  final String? reportsTo;

  const UserCategoryRoleEntry({
    this.content,
    this.roleName,
    this.roleDescription,
    this.organizationUnit,
    this.reportsTo,
  });
}

/// A system task entry [PD00-SYO-SYD-USR-nn-TSK] (form, repeatable).
@tomReflector
class SystemTaskEntry {
  final String? content;
  final String? taskName;
  final String? description;
  final String? frequency;
  final String? relatedUseCase;

  const SystemTaskEntry({
    this.content,
    this.taskName,
    this.description,
    this.frequency,
    this.relatedUseCase,
  });
}

// ---------------------------------------------------------------------------
// 4.2 Goals
// ---------------------------------------------------------------------------

/// 4.2. Goals [PD00-SYO-GOA].
@tomReflector
class Goals {
  final String? content;

  /// 4.2.1. Business Goals [PD00-SYO-GOA-BUS] — contains 1+× Business Goal.
  final List<BusinessGoalEntry> businessGoals;

  /// 4.2.2. Technical Goals [PD00-SYO-GOA-TEC] — contains 1+× Technical Goal.
  final List<TechnicalGoalEntry> technicalGoals;

  /// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC] — contains 1+×.
  final SuccessCriteria successCriteria;

  const Goals({
    this.content,
    this.businessGoals = const [],
    this.technicalGoals = const [],
    this.successCriteria = const SuccessCriteria(),
  });
}

/// A business goal entry [PD00-SYO-GOA-BUS-nn] (form).
@tomReflector
class BusinessGoalEntry {
  final String? content;
  final String? goalId;
  final String? goalName;
  final String? description;
  final String? successMetric;
  final String? currentValue;
  final String? targetValue;
  final String? measurementMethod;
  final String? targetDate;

  const BusinessGoalEntry({
    this.content,
    this.goalId,
    this.goalName,
    this.description,
    this.successMetric,
    this.currentValue,
    this.targetValue,
    this.measurementMethod,
    this.targetDate,
  });
}

/// A technical goal entry [PD00-SYO-GOA-TEC-nn] (form).
@tomReflector
class TechnicalGoalEntry {
  final String? content;
  final String? goalId;
  final String? goalName;
  final String? description;
  final String? successMetric;
  final String? targetValue;
  final String? measurementMethod;
  final String? verificationPoint;

  const TechnicalGoalEntry({
    this.content,
    this.goalId,
    this.goalName,
    this.description,
    this.successMetric,
    this.targetValue,
    this.measurementMethod,
    this.verificationPoint,
  });
}

/// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC].
@tomReflector
class SuccessCriteria {
  final String? content;
  final List<SuccessCriterionEntry> items;

  const SuccessCriteria({this.content, this.items = const []});
}

/// A success criterion entry [PD00-SYO-GOA-SUC-nn] (form).
@tomReflector
class SuccessCriterionEntry {
  final String? content;
  final String? criterion;
  final String? metric;
  final String? targetValue;
  final String? measurementMethod;
  final String? verificationPoint;

  const SuccessCriterionEntry({
    this.content,
    this.criterion,
    this.metric,
    this.targetValue,
    this.measurementMethod,
    this.verificationPoint,
  });
}

// ---------------------------------------------------------------------------
// 4.3 Requirements Overview (seeds → RC)
// ---------------------------------------------------------------------------

/// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
@tomReflector
class RequirementsOverview {
  final String? content;

  /// 4.3.1. Functional Requirements [PD00-SYO-REQ-FUN] — contains 1+×.
  final List<FunctionalRequirementEntry> functionalRequirements;

  /// 4.3.2. Technical Requirements [PD00-SYO-REQ-TEC] — contains 0+×.
  final List<TechnicalRequirementEntry> technicalRequirements;

  /// 4.3.3. Security Requirements [PD00-SYO-REQ-SEC] — contains 0+×.
  final List<SecurityRequirementEntry> securityRequirements;

  /// 4.3.4. Organizational Requirements [PD00-SYO-REQ-ORG] — contains 0+×.
  final List<OrganizationalRequirementEntry> organizationalRequirements;

  const RequirementsOverview({
    this.content,
    this.functionalRequirements = const [],
    this.technicalRequirements = const [],
    this.securityRequirements = const [],
    this.organizationalRequirements = const [],
  });
}

/// A functional requirement entry [PD00-SYO-REQ-FUN-nn] (form).
@tomReflector
class FunctionalRequirementEntry {
  final String? content;
  final String? requirementId;
  final String? title;
  final String? description;
  final String? priority;
  final String? source;
  final String? rationale;
  final List<String> acceptanceCriteria;
  final String? relatedUseCase;
  final String? relatedBusinessProcess;
  final String? affectedDataEntities;
  final String? status;

  const FunctionalRequirementEntry({
    this.content,
    this.requirementId,
    this.title,
    this.description,
    this.priority,
    this.source,
    this.rationale,
    this.acceptanceCriteria = const [],
    this.relatedUseCase,
    this.relatedBusinessProcess,
    this.affectedDataEntities,
    this.status,
  });
}

/// A technical requirement entry [PD00-SYO-REQ-TEC-nn] (form).
@tomReflector
class TechnicalRequirementEntry {
  final String? content;
  final String? requirementId;
  final String? title;
  final String? description;
  final String? priority;
  final String? source;
  final String? rationale;
  final List<String> acceptanceCriteria;
  final String? verificationApproach;
  final String? status;

  const TechnicalRequirementEntry({
    this.content,
    this.requirementId,
    this.title,
    this.description,
    this.priority,
    this.source,
    this.rationale,
    this.acceptanceCriteria = const [],
    this.verificationApproach,
    this.status,
  });
}

/// A security requirement entry [PD00-SYO-REQ-SEC-nn] (form).
@tomReflector
class SecurityRequirementEntry {
  final String? content;
  final String? requirementId;
  final String? title;
  final String? description;
  final String? priority;
  final String? source;
  final String? rationale;
  final String? complianceReference;
  final List<String> acceptanceCriteria;
  final String? status;

  const SecurityRequirementEntry({
    this.content,
    this.requirementId,
    this.title,
    this.description,
    this.priority,
    this.source,
    this.rationale,
    this.complianceReference,
    this.acceptanceCriteria = const [],
    this.status,
  });
}

/// An organizational requirement entry [PD00-SYO-REQ-ORG-nn] (form).
@tomReflector
class OrganizationalRequirementEntry {
  final String? content;
  final String? requirementId;
  final String? title;
  final String? description;
  final String? priority;
  final String? source;
  final String? rationale;
  final List<String> acceptanceCriteria;
  final String? status;

  const OrganizationalRequirementEntry({
    this.content,
    this.requirementId,
    this.title,
    this.description,
    this.priority,
    this.source,
    this.rationale,
    this.acceptanceCriteria = const [],
    this.status,
  });
}

// ---------------------------------------------------------------------------
// 4.4 Systems to Replace (seeds → CS)
// ---------------------------------------------------------------------------

/// 4.4. Systems to Replace [PD00-SYO-SYR]. Seeds → CS.
@tomReflector
class SystemsToReplace {
  final String? content;

  /// 4.4.1. Replacement Inventory [PD00-SYO-SYR-INV] — contains 0+×.
  final List<SystemToReplaceEntry> replacementInventory;

  /// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG].
  final MigrationConsiderations migrationConsiderations;

  const SystemsToReplace({
    this.content,
    this.replacementInventory = const [],
    this.migrationConsiderations = const MigrationConsiderations(),
  });
}

/// A system to replace entry [PD00-SYO-SYR-INV-nn] (form).
@tomReflector
class SystemToReplaceEntry {
  final String? content;
  final String? systemName;
  final String? currentTechnology;
  final String? replacementStrategy;
  final String? dataMigrationScope;
  final String? migrationComplexity;
  final String? decommissionDate;
  final String? dependencies;

  const SystemToReplaceEntry({
    this.content,
    this.systemName,
    this.currentTechnology,
    this.replacementStrategy,
    this.dataMigrationScope,
    this.migrationComplexity,
    this.decommissionDate,
    this.dependencies,
  });
}

/// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG].
@tomReflector
class MigrationConsiderations {
  final String? content;

  /// Migration strategy [PD00-SYO-SYR-MIG-STR].
  final String? strategy;

  /// Migration risks [PD00-SYO-SYR-MIG-RIS].
  final String? risks;

  /// Migration timeline [PD00-SYO-SYR-MIG-TIM].
  final String? timeline;

  /// Data mapping [PD00-SYO-SYR-MIG-DAT].
  final String? dataMapping;

  const MigrationConsiderations({
    this.content,
    this.strategy,
    this.risks,
    this.timeline,
    this.dataMapping,
  });
}

// ---------------------------------------------------------------------------
// 4.5 System Boundaries (seeds → BSI)
// ---------------------------------------------------------------------------

/// 4.5. System Boundaries [PD00-SYO-SYB]. Seeds → BSI.
@tomReflector
class SystemBoundaries {
  final String? content;

  /// 4.5.1. Interfaces to External Systems [PD00-SYO-SYB-INT] — contains 0+×.
  final List<ExternalInterfaceEntry> externalInterfaces;

  /// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT] — contains 0+×.
  final OutOfScope outOfScope;

  /// 4.5.3. Assumptions [PD00-SYO-SYB-ASS] — contains 0+×.
  final BoundaryAssumptions assumptions;

  const SystemBoundaries({
    this.content,
    this.externalInterfaces = const [],
    this.outOfScope = const OutOfScope(),
    this.assumptions = const BoundaryAssumptions(),
  });
}

/// An external interface entry [PD00-SYO-SYB-INT-nn] (form).
@tomReflector
class ExternalInterfaceEntry {
  final String? content;
  final String? interfaceId;
  final String? externalSystem;
  final String? direction;
  final String? purpose;
  final String? dataExchanged;
  final String? protocol;
  final String? frequency;
  final String? volume;
  final String? authentication;

  const ExternalInterfaceEntry({
    this.content,
    this.interfaceId,
    this.externalSystem,
    this.direction,
    this.purpose,
    this.dataExchanged,
    this.protocol,
    this.frequency,
    this.volume,
    this.authentication,
  });
}

/// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT].
@tomReflector
class OutOfScope {
  final String? content;
  final List<OutOfScopeEntry> items;

  const OutOfScope({this.content, this.items = const []});
}

/// An out-of-scope entry [PD00-SYO-SYB-OUT-nn] (form).
@tomReflector
class OutOfScopeEntry {
  final String? content;
  final String? item;
  final String? rationale;
  final String? futureConsideration;

  const OutOfScopeEntry({
    this.content,
    this.item,
    this.rationale,
    this.futureConsideration,
  });
}

/// 4.5.3. Assumptions [PD00-SYO-SYB-ASS].
@tomReflector
class BoundaryAssumptions {
  final String? content;
  final List<AssumptionEntry> items;

  const BoundaryAssumptions({this.content, this.items = const []});
}

/// An assumption entry [PD00-SYO-SYB-ASS-nn] (form).
@tomReflector
class AssumptionEntry {
  final String? content;
  final String? assumption;
  final String? rationale;
  final String? riskIfWrong;
  final String? validationApproach;

  const AssumptionEntry({
    this.content,
    this.assumption,
    this.rationale,
    this.riskIfWrong,
    this.validationApproach,
  });
}

// ---------------------------------------------------------------------------
// 4.6 Framework Conditions
// ---------------------------------------------------------------------------

/// 4.6. Framework Conditions [PD00-SYO-RES].
@tomReflector
class FrameworkConditions {
  final String? content;

  /// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
  final OrganizationalEnvironment organizationalEnvironment;

  /// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN] — contains 0+×.
  final FunctionalResponsibilities functionalResponsibilities;

  /// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
  final TechnicalFrameworkConditions technicalFrameworkConditions;

  /// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON] — contains 0+×.
  final ConstraintsAndDependencies constraintsAndDependencies;

  const FrameworkConditions({
    this.content,
    this.organizationalEnvironment = const OrganizationalEnvironment(),
    this.functionalResponsibilities = const FunctionalResponsibilities(),
    this.technicalFrameworkConditions = const TechnicalFrameworkConditions(),
    this.constraintsAndDependencies = const ConstraintsAndDependencies(),
  });
}

/// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
@tomReflector
class OrganizationalEnvironment {
  final String? content;

  /// Organizational structure [PD00-SYO-RES-ORG-STR].
  final String? structure;

  /// Decision-making processes [PD00-SYO-RES-ORG-DEC].
  final String? decisionMaking;

  /// Cultural considerations [PD00-SYO-RES-ORG-CUL].
  final String? culturalConsiderations;

  const OrganizationalEnvironment({
    this.content,
    this.structure,
    this.decisionMaking,
    this.culturalConsiderations,
  });
}

/// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN].
@tomReflector
class FunctionalResponsibilities {
  final String? content;
  final List<ResponsibilityEntry> items;

  const FunctionalResponsibilities({this.content, this.items = const []});
}

/// A responsibility entry [PD00-SYO-RES-FUN-nn] (form).
@tomReflector
class ResponsibilityEntry {
  final String? content;
  final String? area;
  final String? owner;
  final String? description;
  final String? scope;

  const ResponsibilityEntry({
    this.content,
    this.area,
    this.owner,
    this.description,
    this.scope,
  });
}

/// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
@tomReflector
class TechnicalFrameworkConditions {
  final String? content;

  /// Existing infrastructure [PD00-SYO-RES-TEC-INF].
  final String? existingInfrastructure;

  /// Technology standards [PD00-SYO-RES-TEC-STD].
  final String? technologyStandards;

  /// Integration constraints [PD00-SYO-RES-TEC-INT].
  final String? integrationConstraints;

  const TechnicalFrameworkConditions({
    this.content,
    this.existingInfrastructure,
    this.technologyStandards,
    this.integrationConstraints,
  });
}

/// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON].
@tomReflector
class ConstraintsAndDependencies {
  final String? content;
  final List<ConstraintEntry> items;

  const ConstraintsAndDependencies({this.content, this.items = const []});
}

/// A constraint or dependency entry [PD00-SYO-RES-CON-nn] (form).
@tomReflector
class ConstraintEntry {
  final String? content;
  final String? constraint;
  final String? type;
  final String? impact;
  final String? mitigation;

  const ConstraintEntry({
    this.content,
    this.constraint,
    this.type,
    this.impact,
    this.mitigation,
  });
}

// ---------------------------------------------------------------------------
// 4.7 Risks and Assumptions
// ---------------------------------------------------------------------------

/// 4.7. Risks and Assumptions [PD00-SYO-RIS].
@tomReflector
class RisksAndAssumptions {
  final String? content;

  /// 4.7.1. Key Risks [PD00-SYO-RIS-RIS] — contains 0+× Risk.
  final List<RiskEntry> keyRisks;

  /// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS] — contains 0+×.
  final KeyAssumptions keyAssumptions;

  const RisksAndAssumptions({
    this.content,
    this.keyRisks = const [],
    this.keyAssumptions = const KeyAssumptions(),
  });
}

/// A risk entry [PD00-SYO-RIS-RIS-nn] (form).
@tomReflector
class RiskEntry {
  final String? content;
  final String? riskId;
  final String? riskName;
  final String? description;
  final String? probability;
  final String? impact;
  final String? mitigation;
  final String? riskOwner;
  final String? reviewFrequency;

  const RiskEntry({
    this.content,
    this.riskId,
    this.riskName,
    this.description,
    this.probability,
    this.impact,
    this.mitigation,
    this.riskOwner,
    this.reviewFrequency,
  });
}

/// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS].
@tomReflector
class KeyAssumptions {
  final String? content;
  final List<AssumptionEntry> items;

  const KeyAssumptions({this.content, this.items = const []});
}
