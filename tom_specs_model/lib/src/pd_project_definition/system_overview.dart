/// Section 4: System Overview [PD00-SYO].
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment.
library;



/// 4. System Overview [PD00-SYO].
class SystemOverview {
  String? content;

  /// 4.1. System Description [PD00-SYO-SYD].
  SystemDescription systemDescription = SystemDescription();

  /// 4.2. Goals [PD00-SYO-GOA].
  Goals goals = Goals();

  /// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
  RequirementsOverview requirements = RequirementsOverview();

  /// 4.4. Systems to Replace [PD00-SYO-SYR]. Seeds → CS.
  SystemsToReplace systemsToReplace = SystemsToReplace();

  /// 4.5. System Boundaries [PD00-SYO-SYB]. Seeds → BSI.
  SystemBoundaries systemBoundaries = SystemBoundaries();

  /// 4.6. Framework Conditions [PD00-SYO-RES].
  FrameworkConditions frameworkConditions = FrameworkConditions();

  /// 4.7. Risks and Assumptions [PD00-SYO-RIS].
  RisksAndAssumptions risksAndAssumptions = RisksAndAssumptions();
}

// ---------------------------------------------------------------------------
// 4.1 System Description
// ---------------------------------------------------------------------------

/// 4.1. System Description [PD00-SYO-SYD].
class SystemDescription {
  String? content;

  /// 4.1.1. System Purpose [PD00-SYO-SYD-PUR].
  String? systemPurpose;

  /// 4.1.2. System Context [PD00-SYO-SYD-CON].
  String? systemContext;

  /// 4.1.3. Description of Task Area [PD00-SYO-SYD-DES].
  String? taskArea;

  /// 4.1.4. User Categories [PD00-SYO-SYD-USR] — contains 1+× User Category.
  List<UserCategoryEntry> userCategories = [];

  /// 4.1.5. User Interaction Model [PD00-SYO-SYD-USI].
  UserInteractionModel userInteractionModel = UserInteractionModel();
}

/// 4.1.5. User Interaction Model [PD00-SYO-SYD-USI].
class UserInteractionModel {
  String? content;

  /// Interaction channels (web, mobile, API, CLI, etc.) — contains 0+× InteractionChannel.
  List<InteractionChannelEntry> channels = [];

  /// Interaction patterns (workflow, self-service, batch, etc.) — contains 0+× InteractionPattern.
  List<InteractionPatternEntry> interactionPatterns = [];

  /// Session model (stateful/stateless, session duration, etc.).
  String? sessionModel;

  /// Concurrency model (single-user, multi-user, collaborative).
  String? concurrencyModel;
}

/// An interaction pattern entry (form) [PD00-SYO-SYD-USI-PAT-nn].
class InteractionPatternEntry {
  String? content;
  String? patternName;
  String? description;
}

/// An interaction channel entry (form) [PD00-SYO-SYD-USI-CHA-nn].
class InteractionChannelEntry {
  String? content;
  String? channelName;
  String? channelType;
  String? targetUserCategories;
  String? description;
  String? availabilityRequirement;
}

/// A user category entry [PD00-SYO-SYD-USR-nn] (form).
class UserCategoryEntry {
  String? content;
  String? categoryName;
  String? description;
  String? technicalProficiency;
  String? frequencyOfUse;
  String? accessChannel;
  String? estimatedUserCount;

  /// Role subsection [PD00-SYO-SYD-USR-nn-ROL] (form, singular).
  UserCategoryRoleEntry? role;

  /// System Tasks [PD00-SYO-SYD-USR-nn-TSK] — contains 1+× System Task.
  List<SystemTaskEntry> systemTasks = [];
}

/// Role within a user category [PD00-SYO-SYD-USR-nn-ROL] (form).
class UserCategoryRoleEntry {
  String? content;
  String? roleName;
  String? roleDescription;
  String? organizationUnit;
  String? reportsTo;
}

/// A system task entry [PD00-SYO-SYD-USR-nn-TSK] (form, repeatable).
class SystemTaskEntry {
  String? content;
  String? taskName;
  String? description;
  String? frequency;
  String? relatedUseCase;
}

// ---------------------------------------------------------------------------
// 4.2 Goals
// ---------------------------------------------------------------------------

/// 4.2. Goals [PD00-SYO-GOA].
class Goals {
  String? content;

  /// 4.2.1. Business Goals [PD00-SYO-GOA-BUS] — contains 1+× Business Goal.
  List<BusinessGoalEntry> businessGoals = [];

  /// 4.2.2. Technical Goals [PD00-SYO-GOA-TEC] — contains 1+× Technical Goal.
  List<TechnicalGoalEntry> technicalGoals = [];

  /// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC] — contains 1+×.
  SuccessCriteria successCriteria = SuccessCriteria();
}

/// A business goal entry [PD00-SYO-GOA-BUS-nn] (form).
class BusinessGoalEntry {
  String? content;
  String? goalId;
  String? goalName;
  String? description;
  String? successMetric;
  String? currentValue;
  String? targetValue;
  String? measurementMethod;
  String? targetDate;
}

/// A technical goal entry [PD00-SYO-GOA-TEC-nn] (form).
class TechnicalGoalEntry {
  String? content;
  String? goalId;
  String? goalName;
  String? description;
  String? successMetric;
  String? targetValue;
  String? measurementMethod;
  String? verificationPoint;
}

/// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC].
class SuccessCriteria {
  String? content;
  /// Contains 0+× SuccessCriterion.
  List<SuccessCriterionEntry> items = [];
}

/// A success criterion entry [PD00-SYO-GOA-SUC-nn] (form).
class SuccessCriterionEntry {
  String? content;
  String? criterion;
  String? metric;
  String? targetValue;
  String? measurementMethod;
  String? verificationPoint;
}

// ---------------------------------------------------------------------------
// 4.3 Requirements Overview (seeds → RC)
// ---------------------------------------------------------------------------

/// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
class RequirementsOverview {
  String? content;

  /// 4.3.1. Functional Requirements [PD00-SYO-REQ-FUN] — contains 1+×.
  List<FunctionalRequirementEntry> functionalRequirements = [];

  /// 4.3.2. Technical Requirements [PD00-SYO-REQ-TEC] — contains 0+×.
  List<TechnicalRequirementEntry> technicalRequirements = [];

  /// 4.3.3. Security Requirements [PD00-SYO-REQ-SEC] — contains 0+×.
  List<SecurityRequirementEntry> securityRequirements = [];

  /// 4.3.4. Organizational Requirements [PD00-SYO-REQ-ORG] — contains 0+×.
  List<OrganizationalRequirementEntry> organizationalRequirements = [];
}

/// A functional requirement entry [PD00-SYO-REQ-FUN-nn] (form).
class FunctionalRequirementEntry {
  String? content;
  String? requirementId;
  String? title;
  String? description;
  String? priority;
  String? source;
  String? rationale;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
  String? relatedUseCase;
  String? relatedBusinessProcess;
  /// Contains 0+× DataEntityReference.
  List<DataEntityReferenceEntry> affectedDataEntities = [];
  String? status;
}

/// An acceptance criterion entry (form). Shared across requirement types [PD00-SYO-REQ-FUN-nn-ACR-nn].
class AcceptanceCriterionEntry {
  String? content;
  String? criterion;
  String? verificationMethod;
}

/// A reference to a data entity (form) [PD00-SYO-REQ-FUN-nn-DER-nn].
class DataEntityReferenceEntry {
  String? content;
  String? entityName;
  String? relationship;
}

/// A technical requirement entry [PD00-SYO-REQ-TEC-nn] (form).
class TechnicalRequirementEntry {
  String? content;
  String? requirementId;
  String? title;
  String? description;
  String? priority;
  String? source;
  String? rationale;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
  String? verificationApproach;
  String? status;
}

/// A security requirement entry [PD00-SYO-REQ-SEC-nn] (form).
class SecurityRequirementEntry {
  String? content;
  String? requirementId;
  String? title;
  String? description;
  String? priority;
  String? source;
  String? rationale;
  String? complianceReference;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
  String? status;
}

/// An organizational requirement entry [PD00-SYO-REQ-ORG-nn] (form).
class OrganizationalRequirementEntry {
  String? content;
  String? requirementId;
  String? title;
  String? description;
  String? priority;
  String? source;
  String? rationale;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
  String? status;
}

// ---------------------------------------------------------------------------
// 4.4 Systems to Replace (seeds → CS)
// ---------------------------------------------------------------------------

/// 4.4. Systems to Replace [PD00-SYO-SYR]. Seeds → CS.
class SystemsToReplace {
  String? content;

  /// 4.4.1. Replacement Inventory [PD00-SYO-SYR-INV] — contains 0+×.
  List<SystemToReplaceEntry> replacementInventory = [];

  /// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG].
  MigrationConsiderations migrationConsiderations = MigrationConsiderations();
}

/// A system to replace entry [PD00-SYO-SYR-INV-nn] (form).
class SystemToReplaceEntry {
  String? content;
  String? systemName;
  String? currentTechnology;
  String? replacementStrategy;
  String? dataMigrationScope;
  String? migrationComplexity;
  String? decommissionDate;
  /// Contains 0+× SystemDependencyReference.
  List<SystemDependencyReferenceEntry> dependencies = [];

  /// Per-system migration considerations.
  SystemMigrationConsiderations systemMigration = SystemMigrationConsiderations();
}

/// A system dependency reference entry (form) [PD00-SYO-SYR-INV-nn-DEP-nn].
class SystemDependencyReferenceEntry {
  String? content;
  String? dependencyName;
  String? dependencyType;
}

/// Per-system migration considerations [PD00-SYO-SYR-INV-nn-MIG].
class SystemMigrationConsiderations {
  String? content;
  String? migrationApproach;
  String? dataTransformationNeeds;
  /// Contains 0+× MigrationRiskReference.
  List<MigrationRiskReferenceEntry> risks = [];
  String? estimatedEffort;
  String? rollbackStrategy;
}

/// A migration risk reference entry (form) [PD00-SYO-SYR-INV-nn-MRR-nn].
class MigrationRiskReferenceEntry {
  String? content;
  String? riskDescription;
  String? mitigation;
}

/// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG] (global).
class MigrationConsiderations {
  String? content;

  /// Migration strategy [PD00-SYO-SYR-MIG-STR].
  String? strategy;

  /// Migration risks [PD00-SYO-SYR-MIG-RIS].
  MigrationRisks migrationRisks = MigrationRisks();

  /// Migration timeline [PD00-SYO-SYR-MIG-TIM].
  String? timeline;

  /// Data mapping [PD00-SYO-SYR-MIG-DAT].
  String? dataMapping;

  /// Rollback strategy [PD00-SYO-SYR-MIG-ROL].
  String? rollbackStrategy;
}

/// Migration risks [PD00-SYO-SYR-MIG-RIS].
class MigrationRisks {
  String? content;
  /// Contains 0+× MigrationRisk.
  List<MigrationRiskEntry> items = [];
}

/// A migration risk entry (form) [PD00-SYO-SYR-MIG-RIS-nn].
class MigrationRiskEntry {
  String? content;
  String? riskDescription;
  String? probability;
  String? impact;
  String? mitigation;
}

// ---------------------------------------------------------------------------
// 4.5 System Boundaries (seeds → BSI)
// ---------------------------------------------------------------------------

/// 4.5. System Boundaries [PD00-SYO-SYB]. Seeds → BSI.
class SystemBoundaries {
  String? content;

  /// 4.5.1. Interfaces to External Systems [PD00-SYO-SYB-INT] — contains 0+×.
  List<ExternalInterfaceEntry> externalInterfaces = [];

  /// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT] — contains 0+×.
  OutOfScope outOfScope = OutOfScope();

  /// 4.5.3. Assumptions [PD00-SYO-SYB-ASS] — contains 0+×.
  BoundaryAssumptions assumptions = BoundaryAssumptions();
}

/// An external interface entry [PD00-SYO-SYB-INT-nn] (form).
class ExternalInterfaceEntry {
  String? content;
  String? interfaceId;
  String? externalSystem;
  String? direction;
  String? purpose;
  String? dataExchanged;
  String? protocol;
  String? frequency;
  String? volume;
  String? authentication;
}

/// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT].
class OutOfScope {
  String? content;
  /// Contains 0+× OutOfScope.
  List<OutOfScopeEntry> items = [];
}

/// An out-of-scope entry [PD00-SYO-SYB-OUT-nn] (form).
class OutOfScopeEntry {
  String? content;
  String? item;
  String? rationale;
  String? futureConsideration;
}

/// 4.5.3. Assumptions [PD00-SYO-SYB-ASS].
class BoundaryAssumptions {
  String? content;
  /// Contains 0+× Assumption.
  List<AssumptionEntry> items = [];
}

/// An assumption entry [PD00-SYO-SYB-ASS-nn] (form).
class AssumptionEntry {
  String? content;
  String? assumption;
  String? rationale;
  String? riskIfWrong;
  String? validationApproach;
}

// ---------------------------------------------------------------------------
// 4.6 Framework Conditions
// ---------------------------------------------------------------------------

/// 4.6. Framework Conditions [PD00-SYO-RES].
class FrameworkConditions {
  String? content;

  /// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
  OrganizationalEnvironment organizationalEnvironment = OrganizationalEnvironment();

  /// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN] — contains 0+×.
  FunctionalResponsibilities functionalResponsibilities = FunctionalResponsibilities();

  /// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
  TechnicalFrameworkConditions technicalFrameworkConditions = TechnicalFrameworkConditions();

  /// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON] — contains 0+×.
  ConstraintsAndDependencies constraintsAndDependencies = ConstraintsAndDependencies();
}

/// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
class OrganizationalEnvironment {
  String? content;

  /// Organizational structure [PD00-SYO-RES-ORG-STR].
  String? structure;

  /// Decision-making processes [PD00-SYO-RES-ORG-DEC].
  String? decisionMaking;

  /// Cultural considerations [PD00-SYO-RES-ORG-CUL].
  String? culturalConsiderations;
}

/// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN].
class FunctionalResponsibilities {
  String? content;
  /// Contains 0+× Responsibility.
  List<ResponsibilityEntry> items = [];
}

/// A responsibility entry [PD00-SYO-RES-FUN-nn] (form).
class ResponsibilityEntry {
  String? content;
  String? area;
  String? owner;
  String? description;
  String? scope;
}

/// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
class TechnicalFrameworkConditions {
  String? content;

  /// Existing infrastructure [PD00-SYO-RES-TEC-INF].
  String? existingInfrastructure;

  /// Technology standards [PD00-SYO-RES-TEC-STD] — contains 0+× TechnologyStandard.
  List<TechnologyStandardEntry> technologyStandards = [];

  /// Integration constraints [PD00-SYO-RES-TEC-INT] — contains 0+× IntegrationConstraint.
  List<IntegrationConstraintEntry> integrationConstraints = [];
}

/// A technology standard entry (form) [PD00-SYO-RES-TEC-STD-nn].
class TechnologyStandardEntry {
  String? content;
  String? standard;
  String? description;
}

/// An integration constraint entry (form) [PD00-SYO-RES-TEC-INT-nn].
class IntegrationConstraintEntry {
  String? content;
  String? constraint;
  String? impactedSystem;
}

/// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON].
class ConstraintsAndDependencies {
  String? content;

  /// 4.6.4.1. Constraints [PD00-SYO-RES-CON-CON].
  Constraints constraints = Constraints();

  /// 4.6.4.2. Dependencies [PD00-SYO-RES-CON-DEP].
  FrameworkDependencies frameworkDependencies = FrameworkDependencies();
}

/// 4.6.4.1. Constraints [PD00-SYO-RES-CON-CON].
class Constraints {
  String? content;
  /// Contains 0+× Constraint.
  List<ConstraintEntry> items = [];
}

/// A constraint entry [PD00-SYO-RES-CON-CON-nn] (form).
class ConstraintEntry {
  String? content;
  String? constraint;
  String? type;
  String? impact;
  String? mitigation;
}

/// 4.6.4.2. Dependencies [PD00-SYO-RES-CON-DEP].
class FrameworkDependencies {
  String? content;
  /// Contains 0+× FrameworkDependency.
  List<FrameworkDependencyEntry> items = [];
}

/// A framework dependency entry [PD00-SYO-RES-CON-DEP-nn] (form).
class FrameworkDependencyEntry {
  String? content;
  String? dependency;
  String? type;
  String? impact;
  String? mitigation;
}

// ---------------------------------------------------------------------------
// 4.7 Risks and Assumptions
// ---------------------------------------------------------------------------

/// 4.7. Risks and Assumptions [PD00-SYO-RIS].
class RisksAndAssumptions {
  String? content;

  /// 4.7.1. Key Risks [PD00-SYO-RIS-RIS] — contains 0+× Risk.
  List<RiskEntry> keyRisks = [];

  /// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS] — contains 0+×.
  KeyAssumptions keyAssumptions = KeyAssumptions();
}

/// A risk entry [PD00-SYO-RIS-RIS-nn] (form).
class RiskEntry {
  String? content;
  String? riskId;
  String? riskName;
  String? description;
  String? probability;
  String? impact;
  String? mitigation;
  String? riskOwner;
  String? reviewFrequency;
}

/// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS].
class KeyAssumptions {
  String? content;
  /// Contains 0+× Assumption.
  List<AssumptionEntry> items = [];
}
