/// Section 4: System Overview [PD00-SYO].
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



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

  /// System Purpose.
  TextSection systemPurpose = TextSection();

  /// System Context.
  TextSection systemContext = TextSection();

  /// Task Area.
  TextSection taskArea = TextSection();

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

  /// Session Model.
  TextSection sessionModel = TextSection();

  /// Concurrency Model.
  TextSection concurrencyModel = TextSection();
}

/// An interaction pattern entry (form) [PD00-SYO-SYD-USI-PAT-nn].
class InteractionPatternEntry {
  @Form([
    Field('patternName', String, 'Pattern Name', required: true),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// An interaction channel entry (form) [PD00-SYO-SYD-USI-CHA-nn].
class InteractionChannelEntry {
  @Form([
    Field('channelName', String, 'Channel Name', required: true),
    Field('channelType', String, 'Channel Type'),
    Field('targetUserCategories', String, 'Target User Categories'),
    Field('description', String, 'Short description'),
    Field('availabilityRequirement', String, 'Availability Requirement'),
  ])
  String? content;
}

/// A user category entry [PD00-SYO-SYD-USR-nn] (form).
class UserCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Short description'),
    Field('technicalProficiency', String, 'Technical Proficiency'),
    Field('frequencyOfUse', String, 'Frequency Of Use'),
    Field('accessChannel', String, 'Access Channel'),
    Field('estimatedUserCount', String, 'Estimated User Count'),
  ])
  String? content;
  /// Role subsection [PD00-SYO-SYD-USR-nn-ROL] (form, singular).
  UserCategoryRoleEntry? role;

  /// System Tasks [PD00-SYO-SYD-USR-nn-TSK] — contains 1+× System Task.
  List<SystemTaskEntry> systemTasks = [];
}

/// Role within a user category [PD00-SYO-SYD-USR-nn-ROL] (form).
class UserCategoryRoleEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true),
    Field('roleDescription', String, 'Role Description'),
    Field('organizationUnit', String, 'Organization Unit'),
    Field('reportsTo', String, 'Reports To'),
  ])
  String? content;
}

/// A system task entry [PD00-SYO-SYD-USR-nn-TSK] (form, repeatable).
class SystemTaskEntry {
  @Form([
    Field('taskName', String, 'Task Name', required: true),
    Field('description', String, 'Short description'),
    Field('frequency', String, 'Frequency'),
  ])
  String? content;
  @Reference('Related Use Case')
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
  @Form([
    Field('goalId', String, 'Goal Id', required: true),
    Field('goalName', String, 'Goal Name', required: true),
    Field('description', String, 'Short description'),
    Field('successMetric', String, 'Success Metric'),
    Field('currentValue', String, 'Current Value'),
    Field('targetValue', String, 'Target Value'),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('targetDate', String, 'Target Date'),
  ])
  String? content;
}

/// A technical goal entry [PD00-SYO-GOA-TEC-nn] (form).
class TechnicalGoalEntry {
  @Form([
    Field('goalId', String, 'Goal Id', required: true),
    Field('goalName', String, 'Goal Name', required: true),
    Field('description', String, 'Short description'),
    Field('successMetric', String, 'Success Metric'),
    Field('targetValue', String, 'Target Value'),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('verificationPoint', String, 'Verification Point'),
  ])
  String? content;
}

/// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC].
class SuccessCriteria {
  String? content;
  /// Contains 0+× SuccessCriterion.
  List<SuccessCriterionEntry> items = [];
}

/// A success criterion entry [PD00-SYO-GOA-SUC-nn] (form).
class SuccessCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('metric', String, 'Metric'),
    Field('targetValue', String, 'Target Value'),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('verificationPoint', String, 'Verification Point'),
  ])
  String? content;
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
  @Form([
    Field('requirementId', String, 'Requirement Id', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String, 'Short description'),
    Field('priority', String, 'Priority level'),
    Field('source', String, 'Source'),
    Field('rationale', String, 'Rationale'),
    Field('status', String, 'Current status'),
  ])
  String? content;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
  @Reference('Related Use Case')
  String? relatedUseCase;
  @Reference('Related Business Process')
  String? relatedBusinessProcess;
  /// Contains 0+× DataEntityReference.
  List<DataEntityReferenceEntry> affectedDataEntities = [];
}

/// An acceptance criterion entry (form). Shared across requirement types [PD00-SYO-REQ-FUN-nn-ACR-nn].
class AcceptanceCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('verificationMethod', String, 'Verification Method'),
  ])
  String? content;
}

/// A reference to a data entity (form) [PD00-SYO-REQ-FUN-nn-DER-nn].
class DataEntityReferenceEntry {
  @Form([
    Field('entityName', String, 'Entity Name', required: true),
    Field('relationship', String, 'Relationship'),
  ])
  String? content;
}

/// A technical requirement entry [PD00-SYO-REQ-TEC-nn] (form).
class TechnicalRequirementEntry {
  @Form([
    Field('requirementId', String, 'Requirement Id', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String, 'Short description'),
    Field('priority', String, 'Priority level'),
    Field('source', String, 'Source'),
    Field('rationale', String, 'Rationale'),
    Field('verificationApproach', String, 'Verification Approach'),
    Field('status', String, 'Current status'),
  ])
  String? content;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
}

/// A security requirement entry [PD00-SYO-REQ-SEC-nn] (form).
class SecurityRequirementEntry {
  @Form([
    Field('requirementId', String, 'Requirement Id', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String, 'Short description'),
    Field('priority', String, 'Priority level'),
    Field('source', String, 'Source'),
    Field('rationale', String, 'Rationale'),
    Field('status', String, 'Current status'),
  ])
  String? content;
  @Reference('Compliance Reference')
  String? complianceReference;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
}

/// An organizational requirement entry [PD00-SYO-REQ-ORG-nn] (form).
class OrganizationalRequirementEntry {
  @Form([
    Field('requirementId', String, 'Requirement Id', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String, 'Short description'),
    Field('priority', String, 'Priority level'),
    Field('source', String, 'Source'),
    Field('rationale', String, 'Rationale'),
    Field('status', String, 'Current status'),
  ])
  String? content;
  /// Contains 0+× AcceptanceCriterion.
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
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
  @Form([
    Field('systemName', String, 'System Name', required: true),
    Field('currentTechnology', String, 'Current Technology'),
    Field('replacementStrategy', String, 'Replacement Strategy'),
    Field('dataMigrationScope', String, 'Data Migration Scope'),
    Field('migrationComplexity', String, 'Migration Complexity'),
    Field('decommissionDate', String, 'Decommission Date'),
  ])
  String? content;
  /// Contains 0+× SystemDependencyReference.
  List<SystemDependencyReferenceEntry> dependencies = [];

  /// Per-system migration considerations.
  SystemMigrationConsiderations systemMigration = SystemMigrationConsiderations();
}

/// A system dependency reference entry (form) [PD00-SYO-SYR-INV-nn-DEP-nn].
class SystemDependencyReferenceEntry {
  @Form([
    Field('dependencyType', String, 'Dependency Type'),
  ])
  String? content;
  @Reference('Dependency Name')
  String? dependencyName;
}

/// Per-system migration considerations [PD00-SYO-SYR-INV-nn-MIG].
class SystemMigrationConsiderations {
  @Form([
    Field('migrationApproach', String, 'Migration Approach'),
    Field('dataTransformationNeeds', String, 'Data Transformation Needs'),
    Field('estimatedEffort', String, 'Estimated Effort'),
  ])
  String? content;
  /// Contains 0+× MigrationRiskReference.
  List<MigrationRiskReferenceEntry> risks = [];
  /// Rollback Strategy.
  TextSection rollbackStrategy = TextSection();
}

/// A migration risk reference entry (form) [PD00-SYO-SYR-INV-nn-MRR-nn].
class MigrationRiskReferenceEntry {
  @Form([
    Field('riskDescription', String, 'Risk Description'),
    Field('mitigation', String, 'Mitigation strategy'),
  ])
  String? content;
}

/// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG] (global).
class MigrationConsiderations {
  String? content;

  /// Strategy.
  TextSection strategy = TextSection();

  /// Migration risks [PD00-SYO-SYR-MIG-RIS].
  MigrationRisks migrationRisks = MigrationRisks();

  /// Timeline.
  TextSection timeline = TextSection();

  /// Data Mapping.
  TextSection dataMapping = TextSection();

  /// Rollback Strategy.
  TextSection rollbackStrategy = TextSection();
}

/// Migration risks [PD00-SYO-SYR-MIG-RIS].
class MigrationRisks {
  String? content;
  /// Contains 0+× MigrationRisk.
  List<MigrationRiskEntry> items = [];
}

/// A migration risk entry (form) [PD00-SYO-SYR-MIG-RIS-nn].
class MigrationRiskEntry {
  @Form([
    Field('riskDescription', String, 'Risk Description'),
    Field('probability', String, 'Probability'),
    Field('impact', String, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
  ])
  String? content;
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
  @Form([
    Field('interfaceId', String, 'Interface Id', required: true),
    Field('externalSystem', String, 'External System'),
    Field('direction', String, 'Direction'),
    Field('purpose', String, 'Purpose'),
    Field('dataExchanged', String, 'Data Exchanged'),
    Field('protocol', String, 'Protocol'),
    Field('frequency', String, 'Frequency'),
    Field('volume', String, 'Volume'),
    Field('authentication', String, 'Authentication'),
  ])
  String? content;
}

/// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT].
class OutOfScope {
  String? content;
  /// Contains 0+× OutOfScope.
  List<OutOfScopeEntry> items = [];
}

/// An out-of-scope entry [PD00-SYO-SYB-OUT-nn] (form).
class OutOfScopeEntry {
  @Form([
    Field('item', String, 'Item'),
    Field('rationale', String, 'Rationale'),
    Field('futureConsideration', String, 'Future Consideration'),
  ])
  String? content;
}

/// 4.5.3. Assumptions [PD00-SYO-SYB-ASS].
class BoundaryAssumptions {
  String? content;
  /// Contains 0+× Assumption.
  List<AssumptionEntry> items = [];
}

/// An assumption entry [PD00-SYO-SYB-ASS-nn] (form).
class AssumptionEntry {
  @Form([
    Field('assumption', String, 'Assumption', required: true),
    Field('rationale', String, 'Rationale'),
    Field('riskIfWrong', String, 'Risk If Wrong'),
    Field('validationApproach', String, 'Validation Approach'),
  ])
  String? content;
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

  /// Structure.
  TextSection structure = TextSection();

  /// Decision Making.
  TextSection decisionMaking = TextSection();

  /// Cultural Considerations.
  TextSection culturalConsiderations = TextSection();
}

/// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN].
class FunctionalResponsibilities {
  String? content;
  /// Contains 0+× Responsibility.
  List<ResponsibilityEntry> items = [];
}

/// A responsibility entry [PD00-SYO-RES-FUN-nn] (form).
class ResponsibilityEntry {
  @Form([
    Field('area', String, 'Area'),
    Field('owner', String, 'Owner'),
    Field('description', String, 'Short description'),
    Field('scope', String, 'Scope'),
  ])
  String? content;
}

/// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
class TechnicalFrameworkConditions {
  String? content;

  /// Existing Infrastructure.
  TextSection existingInfrastructure = TextSection();

  /// Technology standards [PD00-SYO-RES-TEC-STD] — contains 0+× TechnologyStandard.
  List<TechnologyStandardEntry> technologyStandards = [];

  /// Integration constraints [PD00-SYO-RES-TEC-INT] — contains 0+× IntegrationConstraint.
  List<IntegrationConstraintEntry> integrationConstraints = [];
}

/// A technology standard entry (form) [PD00-SYO-RES-TEC-STD-nn].
class TechnologyStandardEntry {
  @Form([
    Field('standard', String, 'Standard'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// An integration constraint entry (form) [PD00-SYO-RES-TEC-INT-nn].
class IntegrationConstraintEntry {
  @Form([
    Field('constraint', String, 'Constraint'),
    Field('impactedSystem', String, 'Impacted System'),
  ])
  String? content;
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
  @Form([
    Field('constraint', String, 'Constraint'),
    Field('type', String, 'Type'),
    Field('impact', String, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
  ])
  String? content;
}

/// 4.6.4.2. Dependencies [PD00-SYO-RES-CON-DEP].
class FrameworkDependencies {
  String? content;
  /// Contains 0+× FrameworkDependency.
  List<FrameworkDependencyEntry> items = [];
}

/// A framework dependency entry [PD00-SYO-RES-CON-DEP-nn] (form).
class FrameworkDependencyEntry {
  @Form([
    Field('dependency', String, 'Dependency'),
    Field('type', String, 'Type'),
    Field('impact', String, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
  ])
  String? content;
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
  @Form([
    Field('riskId', String, 'Risk Id', required: true),
    Field('riskName', String, 'Risk Name'),
    Field('description', String, 'Short description'),
    Field('probability', String, 'Probability'),
    Field('impact', String, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
    Field('riskOwner', String, 'Risk Owner'),
    Field('reviewFrequency', String, 'Review Frequency'),
  ])
  String? content;
}

/// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS].
class KeyAssumptions {
  String? content;
  /// Contains 0+× Assumption.
  List<AssumptionEntry> items = [];
}
