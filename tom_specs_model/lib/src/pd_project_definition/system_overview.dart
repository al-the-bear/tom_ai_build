import '../common/common.dart';

/// Section 4: System Overview [PD00-SYO].
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment. This is the largest PD section.
class SystemOverview {
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
class SystemDescription {
  /// 4.1.1. System Purpose [PD00-SYO-SYD-PUR].
  final String? systemPurpose;

  /// 4.1.2. System Context [PD00-SYO-SYD-CON].
  final String? systemContext;

  /// 4.1.3. Description of Task Area [PD00-SYO-SYD-DES].
  final String? taskArea;

  /// 4.1.4. User Categories [PD00-SYO-SYD-USR] — contains 1+× UserCategory.
  final List<UserCategory> userCategories;

  /// 4.1.5. User Interaction Model [PD00-SYO-SYD-USI].
  final String? userInteractionModel;

  const SystemDescription({
    this.systemPurpose,
    this.systemContext,
    this.taskArea,
    this.userCategories = const [],
    this.userInteractionModel,
  });
}

/// A user category with its roles and tasks [PD00-SYO-SYD-USR-nn].
class UserCategory {
  final String categoryName;
  final String description;
  final TechnicalProficiency? technicalProficiency;
  final String? frequencyOfUse;
  final AccessChannel? accessChannel;
  final int? estimatedUserCount;

  /// Roles within this user category.
  final List<UserRole> roles;

  /// System tasks this category performs.
  final List<SystemTask> systemTasks;

  const UserCategory({
    required this.categoryName,
    required this.description,
    this.technicalProficiency,
    this.frequencyOfUse,
    this.accessChannel,
    this.estimatedUserCount,
    this.roles = const [],
    this.systemTasks = const [],
  });
}

/// A role within a user category [PD00-SYO-SYD-USR-nn-ROL].
class UserRole {
  final String roleName;
  final String roleDescription;
  final String? organizationUnit;
  final String? reportsTo;

  const UserRole({
    required this.roleName,
    required this.roleDescription,
    this.organizationUnit,
    this.reportsTo,
  });
}

/// A system task performed by a user category [PD00-SYO-SYD-USR-nn-TSK].
class SystemTask {
  final String taskName;
  final String description;
  final String? frequency;
  final String? relatedUseCase;

  const SystemTask({
    required this.taskName,
    required this.description,
    this.frequency,
    this.relatedUseCase,
  });
}

// ---------------------------------------------------------------------------
// 4.2 Goals
// ---------------------------------------------------------------------------

/// 4.2. Goals [PD00-SYO-GOA].
class Goals {
  /// 4.2.1. Business Goals [PD00-SYO-GOA-BUS] — contains 1+× BusinessGoal.
  final List<BusinessGoal> businessGoals;

  /// 4.2.2. Technical Goals [PD00-SYO-GOA-TEC] — contains 1+× TechnicalGoal.
  final List<TechnicalGoal> technicalGoals;

  /// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC].
  final String? successCriteria;

  const Goals({
    this.businessGoals = const [],
    this.technicalGoals = const [],
    this.successCriteria,
  });
}

/// A business goal [PD00-SYO-GOA-BUS-nn].
class BusinessGoal {
  final String goalId;
  final String goalName;
  final String description;
  final String successMetric;
  final String? currentValue;
  final String targetValue;
  final String? measurementMethod;
  final String? targetDate;

  const BusinessGoal({
    required this.goalId,
    required this.goalName,
    required this.description,
    required this.successMetric,
    this.currentValue,
    required this.targetValue,
    this.measurementMethod,
    this.targetDate,
  });
}

/// A technical goal [PD00-SYO-GOA-TEC-nn].
class TechnicalGoal {
  final String goalId;
  final String goalName;
  final String description;
  final String successMetric;
  final String targetValue;
  final String? measurementMethod;
  final String? verificationPoint;

  const TechnicalGoal({
    required this.goalId,
    required this.goalName,
    required this.description,
    required this.successMetric,
    required this.targetValue,
    this.measurementMethod,
    this.verificationPoint,
  });
}

// ---------------------------------------------------------------------------
// 4.3 Requirements Overview (seeds → RC)
// ---------------------------------------------------------------------------

/// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
class RequirementsOverview {
  /// 4.3.1. Functional Requirements — contains 1+× FunctionalRequirement.
  final List<FunctionalRequirement> functional;

  /// 4.3.2. Technical Requirements — contains 0+× TechnicalRequirement.
  final List<TechnicalRequirement> technical;

  /// 4.3.3. Security Requirements — contains 0+× SecurityRequirement.
  final List<SecurityRequirement> security;

  /// 4.3.4. Organizational Requirements — contains 0+× OrganizationalRequirement.
  final List<Requirement> organizational;

  const RequirementsOverview({
    this.functional = const [],
    this.technical = const [],
    this.security = const [],
    this.organizational = const [],
  });
}

/// Functional requirement with use-case and data entity references.
class FunctionalRequirement extends Requirement {
  final String? relatedUseCase;
  final String? relatedBusinessProcess;
  final String? affectedDataEntities;

  const FunctionalRequirement({
    required super.requirementId,
    required super.title,
    required super.description,
    required super.priority,
    required super.source,
    super.rationale,
    required super.acceptanceCriteria,
    super.status,
    this.relatedUseCase,
    this.relatedBusinessProcess,
    this.affectedDataEntities,
  });
}

/// Technical requirement with verification approach.
class TechnicalRequirement extends Requirement {
  final String? verificationApproach;

  const TechnicalRequirement({
    required super.requirementId,
    required super.title,
    required super.description,
    required super.priority,
    required super.source,
    super.rationale,
    required super.acceptanceCriteria,
    super.status,
    this.verificationApproach,
  });
}

/// Security requirement with compliance reference.
class SecurityRequirement extends Requirement {
  final String? complianceReference;

  const SecurityRequirement({
    required super.requirementId,
    required super.title,
    required super.description,
    required super.priority,
    required super.source,
    super.rationale,
    required super.acceptanceCriteria,
    super.status,
    this.complianceReference,
  });
}

// ---------------------------------------------------------------------------
// 4.4 Systems to Replace (seeds → CS)
// ---------------------------------------------------------------------------

/// 4.4. Systems to Replace [PD00-SYO-SYR]. Seeds → CS.
class SystemsToReplace {
  /// 4.4.1. Replacement Inventory — contains 0+× SystemToReplace.
  final List<SystemToReplace> inventory;

  /// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG].
  final String? migrationConsiderations;

  const SystemsToReplace({
    this.inventory = const [],
    this.migrationConsiderations,
  });
}

/// A system to be replaced [PD00-SYO-SYR-INV-nn].
class SystemToReplace {
  final String systemName;
  final String currentTechnology;
  final ReplacementStrategy replacementStrategy;
  final String? dataMigrationScope;
  final String? migrationComplexity;
  final String? decommissionDate;
  final String? dependencies;

  const SystemToReplace({
    required this.systemName,
    required this.currentTechnology,
    required this.replacementStrategy,
    this.dataMigrationScope,
    this.migrationComplexity,
    this.decommissionDate,
    this.dependencies,
  });
}

// ---------------------------------------------------------------------------
// 4.5 System Boundaries (seeds → BSI)
// ---------------------------------------------------------------------------

/// 4.5. System Boundaries [PD00-SYO-SYB]. Seeds → BSI.
class SystemBoundaries {
  /// 4.5.1. Interfaces to External Systems — contains 0+× ExternalInterface.
  final List<ExternalInterface> externalInterfaces;

  /// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT].
  final String? outOfScope;

  /// 4.5.3. Assumptions [PD00-SYO-SYB-ASS].
  final String? assumptions;

  const SystemBoundaries({
    this.externalInterfaces = const [],
    this.outOfScope,
    this.assumptions,
  });
}

/// An external system interface [PD00-SYO-SYB-INT-nn].
class ExternalInterface {
  final String interfaceId;
  final String externalSystem;
  final InterfaceDirection direction;
  final String purpose;
  final String? dataExchanged;
  final String? protocol;
  final String? frequency;
  final String? volume;
  final String? authentication;

  const ExternalInterface({
    required this.interfaceId,
    required this.externalSystem,
    required this.direction,
    required this.purpose,
    this.dataExchanged,
    this.protocol,
    this.frequency,
    this.volume,
    this.authentication,
  });
}

// ---------------------------------------------------------------------------
// 4.6 Framework Conditions
// ---------------------------------------------------------------------------

/// 4.6. Framework Conditions [PD00-SYO-RES].
class FrameworkConditions {
  /// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
  final String? organizationalEnvironment;

  /// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN].
  final String? functionalResponsibilities;

  /// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
  final String? technicalFrameworkConditions;

  /// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON].
  final String? constraintsAndDependencies;

  const FrameworkConditions({
    this.organizationalEnvironment,
    this.functionalResponsibilities,
    this.technicalFrameworkConditions,
    this.constraintsAndDependencies,
  });
}

// ---------------------------------------------------------------------------
// 4.7 Risks and Assumptions
// ---------------------------------------------------------------------------

/// 4.7. Risks and Assumptions [PD00-SYO-RIS].
class RisksAndAssumptions {
  /// 4.7.1. Key Risks — contains 0+× Risk.
  final List<Risk> keyRisks;

  /// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS].
  final String? keyAssumptions;

  const RisksAndAssumptions({
    this.keyRisks = const [],
    this.keyAssumptions,
  });
}
