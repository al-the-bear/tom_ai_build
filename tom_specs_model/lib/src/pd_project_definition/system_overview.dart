/// Section 4: System Overview [PD00-SYO].
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 4. System Overview [PD00-SYO].
@SectionId('PD00-SYO')
class SystemOverview {
  @Unused()
  String? content;

  /// 4.1. System Description [PD00-SYO-SYD].
  SystemDescription systemDescription = SystemDescription();

  /// 4.2. Goals [PD00-SYO-GOA].
  Goals goals = Goals();

  /// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
  @Comment('Seeds → RC')
  RequirementsOverview requirements = RequirementsOverview();

  /// 4.4. Systems to Replace [PD00-SYO-SYR]. Seeds → CS.
  @Comment('Seeds → CS')
  SystemsToReplace systemsToReplace = SystemsToReplace();

  /// 4.5. System Boundaries [PD00-SYO-SYB]. Seeds → BSI.
  @Comment('Seeds → BSI')
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
@SectionId('PD00-SYO-SYD')
class SystemDescription {
  @Unused()
  String? content;

  /// 4.1.1. System Purpose [PD00-SYO-SYD-PUR].
  SystemPurpose systemPurpose = SystemPurpose();

  /// 4.1.2. System Context [PD00-SYO-SYD-CON].
  TextSection systemContext = TextSection();

  /// 4.1.3. Task Area [PD00-SYO-SYD-DES].
  TextSection taskArea = TextSection();

  /// 4.1.4. User Categories [PD00-SYO-SYD-USR] — contains 1+× User Category.
  @SectionIdPattern('PD00-SYO-SYD-USR-xx')
  @Min(1)
  List<UserCategoryEntry> userCategories = [];

  /// 4.1.5. User Interaction Model [PD00-SYO-SYD-USI].
  UserInteractionModel userInteractionModel = UserInteractionModel();
}

// ---------------------------------------------------------------------------
// 4.1.1 System Purpose
// ---------------------------------------------------------------------------

/// 4.1.1. System Purpose [PD00-SYO-SYD-PUR].
///
/// Describes the overarching purpose of the system including the problem it
/// solves, the opportunity it enables, and who the primary beneficiaries are.
/// This section establishes the fundamental justification for the project.
@SectionId('PD00-SYO-SYD-PUR')
@ContentHelp('Describe the overarching purpose of the system. Address: '
    'What problem does it solve? What opportunity does it enable? '
    'Who are the primary beneficiaries? How does it align with '
    'organizational strategy?')
class SystemPurpose {
  @ContentType('description', 'High-level overview of the system purpose. '
      'Provide a brief executive summary of why this system is being built.')
  String? content;

  /// Vision Statement [PD00-SYO-SYD-PUR-VIS].
  @SectionId('PD00-SYO-SYD-PUR-VIS')
  @ContentType('description', 'A concise, memorable statement (1-3 sentences) '
      'that captures the essence of what the system will achieve.')
  @ContentHelp('Write a clear and inspiring vision statement that describes '
      'what success looks like when this system is fully operational.')
  String? visionStatement;

  /// 4.1.1.1. Problem Statement [PD00-SYO-SYD-PUR-PRO].
  ProblemStatement problemStatement = ProblemStatement();

  /// 4.1.1.2. Opportunity Statement [PD00-SYO-SYD-PUR-OPP].
  OpportunityStatement opportunityStatement = OpportunityStatement();

  /// 4.1.1.3. Stakeholders and Beneficiaries [PD00-SYO-SYD-PUR-STA].
  StakeholdersAndBeneficiaries stakeholders = StakeholdersAndBeneficiaries();

  /// 4.1.1.4. Value Proposition [PD00-SYO-SYD-PUR-VAL].
  ValueProposition valueProposition = ValueProposition();

  /// 4.1.1.5. Strategic Alignment [PD00-SYO-SYD-PUR-ALI].
  StrategicAlignment strategicAlignment = StrategicAlignment();

  /// 4.1.1.6. Scope Boundaries [PD00-SYO-SYD-PUR-SCO].
  ScopeBoundaries scopeBoundaries = ScopeBoundaries();
}

/// 4.1.1.1. Problem Statement [PD00-SYO-SYD-PUR-PRO].
///
/// Detailed description of the problem or pain point that this system will
/// address. Includes impact analysis and urgency assessment.
@SectionId('PD00-SYO-SYD-PUR-PRO')
@ContentHelp('Describe the problem in detail. What is the current state? '
    'What makes it a problem? Who is affected and how severely?')
class ProblemStatement {
  @ContentType('description', 'Narrative description of the problem, its '
      'causes, and why it needs to be addressed now.')
  String? content;

  /// Problem Description Form [PD00-SYO-SYD-PUR-PRO-DES].
  @Form([
    Field('problemSummary', String, 'Problem Summary (one sentence)',
        required: true),
    Field('currentState', String,
        'Current State (describe the AS-IS situation that is problematic)'),
    Field('affectedParties', String,
        'Affected Parties (who suffers from this problem)'),
    Field('impactDescription', String,
        'Impact Description (business, financial, operational impacts)'),
    Field('impactSeverity', String,
        'Impact Severity (Critical, High, Medium, Low)'),
    Field('impactMetrics', String,
        'Impact Metrics (quantifiable measures of the problem\'s cost)'),
    Field('rootCauses', String, 'Root Causes (underlying reasons for problem)'),
    Field('urgency', String,
        'Urgency (Immediate, Short-term, Medium-term, Long-term)'),
    Field('urgencyJustification', String,
        'Urgency Justification (why this timeline is critical)'),
    Field('consequencesOfInaction', String,
        'Consequences of Inaction (what happens if not addressed)'),
  ])
  String? problemDetails;

  /// Related pain points from Current State Analysis.
  @ContentType('description', 'Cross-references to specific pain points '
      'documented in the Current State Analysis section (PD00-CUR-PAI).')
  String? relatedPainPoints;
}

/// 4.1.1.2. Opportunity Statement [PD00-SYO-SYD-PUR-OPP].
///
/// Description of the opportunity this system enables — new capabilities,
/// competitive advantages, or improvements over current state.
@SectionId('PD00-SYO-SYD-PUR-OPP')
@ContentHelp('Describe what the system will enable. What new capabilities '
    'will be available? What improvements over current state? What '
    'competitive advantages will it provide?')
class OpportunityStatement {
  @ContentType('description', 'Narrative description of the opportunity '
      'and the positive outcomes enabled by the new system.')
  String? content;

  /// Opportunity Details Form [PD00-SYO-SYD-PUR-OPP-DES].
  @Form([
    Field('opportunitySummary', String, 'Opportunity Summary (one sentence)',
        required: true),
    Field('futureState', String,
        'Future State (describe the TO-BE situation after implementation)'),
    Field('newCapabilities', String,
        'New Capabilities (what becomes possible that wasn\'t before)'),
    Field('improvements', String,
        'Improvements (quantitative and qualitative improvements expected)'),
    Field('competitiveAdvantage', String,
        'Competitive Advantage (market positioning benefits)'),
    Field('innovationAspects', String,
        'Innovation Aspects (novel or differentiating features)'),
    Field('growthEnablement', String,
        'Growth Enablement (how this supports business growth)'),
    Field('efficiencyGains', String,
        'Efficiency Gains (productivity and cost improvements)'),
    Field('timeToValue', String,
        'Time to Value (when benefits will start being realized)'),
  ])
  String? opportunityDetails;
}

/// 4.1.1.3. Stakeholders and Beneficiaries [PD00-SYO-SYD-PUR-STA].
///
/// Lists all stakeholders and beneficiaries of the system with their
/// interests, influence level, and expected benefits.
@SectionId('PD00-SYO-SYD-PUR-STA')
@ContentHelp('Identify all stakeholders and beneficiaries. Include their '
    'role, interests, level of influence, and expected benefits. '
    'Distinguish between direct users, sponsors, and indirect beneficiaries.')
class StakeholdersAndBeneficiaries {
  @ContentType('description', 'Overview of stakeholder landscape and '
      'how different groups will benefit from the system.')
  String? content;

  /// Primary stakeholders — contains 1+× StakeholderEntry.
  @SectionIdPattern('PD00-SYO-SYD-PUR-STA-xx')
  @Min(1)
  @ContentHelp('Add one entry per primary stakeholder or stakeholder group. '
      'Primary stakeholders are those directly affected by the system.')
  List<StakeholderEntry> primaryStakeholders = [];

  /// Secondary stakeholders — contains 0+× StakeholderEntry.
  @ContentHelp('Secondary stakeholders are indirectly affected by the system.')
  List<StakeholderEntry> secondaryStakeholders = [];
}

/// A stakeholder or beneficiary entry (form).
class StakeholderEntry {
  @Form([
    Field('stakeholderName', String, 'Stakeholder Name or Group',
        required: true),
    Field('stakeholderType', String,
        'Stakeholder Type (Sponsor, User, Customer, Partner, Regulator, etc.)',
        required: true),
    Field('role', String, 'Role (organizational role or relationship)'),
    Field('interests', String,
        'Interests (what they care about regarding this system)'),
    Field('influenceLevel', String,
        'Influence Level (High, Medium, Low - decision-making power)'),
    Field('impactLevel', String,
        'Impact Level (High, Medium, Low - how much system affects them)'),
    Field('expectedBenefits', String,
        'Expected Benefits (what they will gain from the system)'),
    Field('potentialConcerns', String,
        'Potential Concerns (risks or issues from their perspective)'),
    Field('engagementStrategy', String,
        'Engagement Strategy (how to keep them informed and involved)'),
    Field('communicationChannel', String,
        'Communication Channel (preferred way to communicate with them)'),
    Field('successCriteriaFromPerspective', String,
        'Success Criteria (what makes this project successful from their view)'),
  ])
  String? content;
}

/// 4.1.1.4. Value Proposition [PD00-SYO-SYD-PUR-VAL].
///
/// Clear articulation of the value this system provides, including
/// quantifiable benefits and return on investment analysis.
@SectionId('PD00-SYO-SYD-PUR-VAL')
@ContentHelp('Articulate the business value clearly. Include quantifiable '
    'benefits, ROI expectations, and how value will be measured.')
class ValueProposition {
  @ContentType('description', 'Summary of the value proposition and '
      'key benefits of the system.')
  String? content;

  /// Value Proposition Details (form).
  @Form([
    Field('valueStatement', String,
        'Value Statement (concise statement of value delivered)', required: true),
    Field('primaryBenefits', String,
        'Primary Benefits (top 3-5 benefits in priority order)'),
    Field('quantifiableBenefits', String,
        'Quantifiable Benefits (measurable improvements with targets)'),
    Field('qualitativeBenefits', String,
        'Qualitative Benefits (non-quantifiable but important benefits)'),
    Field('costSavings', String,
        'Cost Savings (expected cost reductions and where)'),
    Field('revenueImpact', String,
        'Revenue Impact (how system affects revenue generation)'),
    Field('productivityGains', String,
        'Productivity Gains (efficiency improvements expected)'),
    Field('riskReduction', String,
        'Risk Reduction (operational, compliance, security risks mitigated)'),
    Field('estimatedRoi', String,
        'Estimated ROI (return on investment calculation or estimate)'),
    Field('paybackPeriod', String,
        'Payback Period (time until investment is recovered)'),
    Field('valueRealizationTimeline', String,
        'Value Realization Timeline (when benefits start accruing)'),
  ])
  String? valueDetails;

  /// Key Performance Indicators for value measurement.
  @ContentType('description', 'KPIs that will be used to measure the '
      'realization of the value proposition.')
  String? kpis;
}

/// 4.1.1.5. Strategic Alignment [PD00-SYO-SYD-PUR-ALI].
///
/// How this system aligns with organizational strategy, goals, and
/// initiatives. Demonstrates strategic justification for the project.
@SectionId('PD00-SYO-SYD-PUR-ALI')
@ContentHelp('Show how this project aligns with organizational strategy. '
    'Reference corporate goals, IT roadmap, and strategic initiatives.')
class StrategicAlignment {
  @ContentType('description', 'Overview of how the system supports '
      'organizational strategy and priorities.')
  String? content;

  /// Strategic Alignment Details (form).
  @Form([
    Field('alignedCorporateGoals', String,
        'Aligned Corporate Goals (which company goals this supports)'),
    Field('alignedBusinessObjectives', String,
        'Aligned Business Objectives (specific objectives this serves)'),
    Field('alignedItStrategy', String,
        'Aligned IT Strategy (how this fits in the IT roadmap)'),
    Field('relatedInitiatives', String,
        'Related Initiatives (other projects or programs this connects to)'),
    Field('digitizationContribution', String,
        'Digitization Contribution (how this advances digital transformation)'),
    Field('innovationContribution', String,
        'Innovation Contribution (how this supports innovation goals)'),
    Field('complianceContribution', String,
        'Compliance Contribution (regulatory or policy requirements met)'),
    Field('marketPositioning', String,
        'Market Positioning (how this affects competitive position)'),
    Field('strategicTimingRationale', String,
        'Strategic Timing (why this is the right time for this initiative)'),
  ])
  String? alignmentDetails;
}

/// 4.1.1.6. Scope Boundaries [PD00-SYO-SYD-PUR-SCO].
///
/// Clear definition of what is in scope and out of scope for this system.
/// Helps set expectations and prevent scope creep.
@SectionId('PD00-SYO-SYD-PUR-SCO')
@ContentHelp('Define clear boundaries. What is included? What is explicitly '
    'excluded? What is deferred to future phases? This prevents scope creep '
    'and sets clear expectations.')
class ScopeBoundaries {
  @ContentType('description', 'Overview of the scope boundaries and '
      'the rationale for in/out decisions.')
  String? content;

  /// In-Scope Items [PD00-SYO-SYD-PUR-SCO-IN] — contains 1+× ScopeItem.
  @SectionIdPattern('PD00-SYO-SYD-PUR-SCO-IN-xx')
  @Min(1)
  @ContentHelp('List all items that are explicitly in scope for this project. '
      'Be specific about features, processes, user groups, and systems.')
  List<ScopeItemEntry> inScopeItems = [];

  /// Out-of-Scope Items [PD00-SYO-SYD-PUR-SCO-OUT] — contains 0+× ScopeItem.
  @SectionIdPattern('PD00-SYO-SYD-PUR-SCO-OUT-xx')
  @ContentHelp('List items explicitly excluded. This is as important as '
      'in-scope items to prevent misunderstandings and scope creep.')
  List<ScopeItemEntry> outOfScopeItems = [];

  /// Deferred Items [PD00-SYO-SYD-PUR-SCO-DEF] — contains 0+× ScopeItem.
  @SectionIdPattern('PD00-SYO-SYD-PUR-SCO-DEF-xx')
  @ContentHelp('Items deferred to future phases. Include tentative timing.')
  List<DeferredScopeItemEntry> deferredItems = [];

  /// Scope Assumptions.
  @ContentType('description', 'Key assumptions that scope decisions are '
      'based on. If assumptions change, scope may need revisiting.')
  String? scopeAssumptions;
}

/// A scope item entry (in-scope or out-of-scope).
class ScopeItemEntry {
  @Form([
    Field('itemDescription', String, 'Item Description', required: true),
    Field('category', String,
        'Category (Feature, Process, User Group, System, Data, Geography, etc.)'),
    Field('rationale', String, 'Rationale (why included or excluded)'),
    Field('relatedRequirements', String,
        'Related Requirements (requirement IDs if applicable)'),
  ])
  String? content;
}

/// A deferred scope item entry (for future phases).
class DeferredScopeItemEntry {
  @Form([
    Field('itemDescription', String, 'Item Description', required: true),
    Field('category', String, 'Category (Feature, Process, etc.)'),
    Field('targetPhase', String, 'Target Phase (when this will be addressed)'),
    Field('deferralReason', String, 'Deferral Reason (why not in current scope)'),
    Field('dependencies', String,
        'Dependencies (what must be done before this can be addressed)'),
    Field('estimatedEffort', String,
        'Estimated Effort (rough sizing for planning purposes)'),
  ])
  String? content;
}

/// 4.1.5. User Interaction Model [PD00-SYO-SYD-USI].
@SectionId('PD00-SYO-SYD-USI')
class UserInteractionModel {
  @Unused()
  String? content;

  /// Interaction channels (web, mobile, API, CLI, etc.) — contains 0+× InteractionChannel.
  @SectionIdPattern('PD00-SYO-SYD-USI-CHA-xx')
  List<InteractionChannelEntry> channels = [];

  /// Interaction patterns (workflow, self-service, batch, etc.) — contains 0+× InteractionPattern.
  @SectionIdPattern('PD00-SYO-SYD-USI-PAT-xx')
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
  @SectionIdPattern('PD00-SYO-SYD-USR-xx-TSK-xx')
  @Min(1)
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
@SectionId('PD00-SYO-GOA')
class Goals {
  @Unused()
  String? content;

  /// 4.2.1. Business Goals [PD00-SYO-GOA-BUS] — contains 1+× Business Goal.
  @SectionIdPattern('PD00-SYO-GOA-BUS-xx')
  @Min(1)
  List<BusinessGoalEntry> businessGoals = [];

  /// 4.2.2. Technical Goals [PD00-SYO-GOA-TEC] — contains 1+× Technical Goal.
  @SectionIdPattern('PD00-SYO-GOA-TEC-xx')
  @Min(1)
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
@SectionId('PD00-SYO-GOA-SUC')
class SuccessCriteria {
  @Unused()
  String? content;

  /// Contains 0+× SuccessCriterion.
  @SectionIdPattern('PD00-SYO-GOA-SUC-xx')
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
@SectionId('PD00-SYO-REQ')
@Comment('Seeds → RC')
class RequirementsOverview {
  @Unused()
  String? content;

  /// 4.3.1. Functional Requirements [PD00-SYO-REQ-FUN] — contains 1+×.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx')
  @Min(1)
  List<FunctionalRequirementEntry> functionalRequirements = [];

  /// 4.3.2. Technical Requirements [PD00-SYO-REQ-TEC] — contains 0+×.
  @SectionIdPattern('PD00-SYO-REQ-TEC-xx')
  List<TechnicalRequirementEntry> technicalRequirements = [];

  /// 4.3.3. Security Requirements [PD00-SYO-REQ-SEC] — contains 0+×.
  @SectionIdPattern('PD00-SYO-REQ-SEC-xx')
  List<SecurityRequirementEntry> securityRequirements = [];

  /// 4.3.4. Organizational Requirements [PD00-SYO-REQ-ORG] — contains 0+×.
  @SectionIdPattern('PD00-SYO-REQ-ORG-xx')
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
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-ACR-xx')
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];

  @Reference('Related Use Case')
  String? relatedUseCase;

  @Reference('Related Business Process')
  String? relatedBusinessProcess;

  /// Contains 0+× DataEntityReference.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-DER-xx')
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
  @SectionIdPattern('PD00-SYO-REQ-TEC-xx-ACR-xx')
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
  @SectionIdPattern('PD00-SYO-REQ-SEC-xx-ACR-xx')
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
  @SectionIdPattern('PD00-SYO-REQ-ORG-xx-ACR-xx')
  List<AcceptanceCriterionEntry> acceptanceCriteria = [];
}

// ---------------------------------------------------------------------------
// 4.4 Systems to Replace (seeds → CS)
// ---------------------------------------------------------------------------

/// 4.4. Systems to Replace [PD00-SYO-SYR]. Seeds → CS.
@SectionId('PD00-SYO-SYR')
@Comment('Seeds → CS')
class SystemsToReplace {
  @Unused()
  String? content;

  /// 4.4.1. Replacement Inventory [PD00-SYO-SYR-INV] — contains 0+×.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx')
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
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-DEP-xx')
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
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-MRR-xx')
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
@SectionId('PD00-SYO-SYR-MIG')
class MigrationConsiderations {
  @Unused()
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
@SectionId('PD00-SYO-SYR-MIG-RIS')
class MigrationRisks {
  @Unused()
  String? content;

  /// Contains 0+× MigrationRisk.
  @SectionIdPattern('PD00-SYO-SYR-MIG-RIS-xx')
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
@SectionId('PD00-SYO-SYB')
@Comment('Seeds → BSI')
class SystemBoundaries {
  @Unused()
  String? content;

  /// 4.5.1. Interfaces to External Systems [PD00-SYO-SYB-INT] — contains 0+×.
  @SectionIdPattern('PD00-SYO-SYB-INT-xx')
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
@SectionId('PD00-SYO-SYB-OUT')
class OutOfScope {
  @Unused()
  String? content;

  /// Contains 0+× OutOfScope.
  @SectionIdPattern('PD00-SYO-SYB-OUT-xx')
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
@SectionId('PD00-SYO-SYB-ASS')
class BoundaryAssumptions {
  @Unused()
  String? content;

  /// Contains 0+× Assumption.
  @SectionIdPattern('PD00-SYO-SYB-ASS-xx')
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
@SectionId('PD00-SYO-RES')
class FrameworkConditions {
  @Unused()
  String? content;

  /// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
  OrganizationalEnvironment organizationalEnvironment = OrganizationalEnvironment();

  /// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN] — contains 0+×.
  FunctionalResponsibilities functionalResponsibilities = FunctionalResponsibilities();

  /// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
  @Comment('Seeds → TR')
  TechnicalFrameworkConditions technicalFrameworkConditions = TechnicalFrameworkConditions();

  /// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON] — contains 0+×.
  ConstraintsAndDependencies constraintsAndDependencies = ConstraintsAndDependencies();
}

/// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
@SectionId('PD00-SYO-RES-ORG')
class OrganizationalEnvironment {
  @Unused()
  String? content;

  /// Structure.
  TextSection structure = TextSection();

  /// Decision Making.
  TextSection decisionMaking = TextSection();

  /// Cultural Considerations.
  TextSection culturalConsiderations = TextSection();
}

/// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN].
@SectionId('PD00-SYO-RES-FUN')
class FunctionalResponsibilities {
  @Unused()
  String? content;

  /// Contains 0+× Responsibility.
  @SectionIdPattern('PD00-SYO-RES-FUN-xx')
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
@SectionId('PD00-SYO-RES-TEC')
@Comment('Seeds → TR')
class TechnicalFrameworkConditions {
  @Unused()
  String? content;

  /// Existing Infrastructure.
  TextSection existingInfrastructure = TextSection();

  /// Technology standards [PD00-SYO-RES-TEC-STD] — contains 0+× TechnologyStandard.
  @SectionIdPattern('PD00-SYO-RES-TEC-STD-xx')
  List<TechnologyStandardEntry> technologyStandards = [];

  /// Integration constraints [PD00-SYO-RES-TEC-INT] — contains 0+× IntegrationConstraint.
  @SectionIdPattern('PD00-SYO-RES-TEC-INT-xx')
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
@SectionId('PD00-SYO-RES-CON')
class ConstraintsAndDependencies {
  @Unused()
  String? content;

  /// 4.6.4.1. Constraints [PD00-SYO-RES-CON-CON].
  Constraints constraints = Constraints();

  /// 4.6.4.2. Dependencies [PD00-SYO-RES-CON-DEP].
  FrameworkDependencies frameworkDependencies = FrameworkDependencies();
}

/// 4.6.4.1. Constraints [PD00-SYO-RES-CON-CON].
@SectionId('PD00-SYO-RES-CON-CON')
class Constraints {
  @Unused()
  String? content;

  /// Contains 0+× Constraint.
  @SectionIdPattern('PD00-SYO-RES-CON-CON-xx')
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
@SectionId('PD00-SYO-RES-CON-DEP')
class FrameworkDependencies {
  @Unused()
  String? content;

  /// Contains 0+× FrameworkDependency.
  @SectionIdPattern('PD00-SYO-RES-CON-DEP-xx')
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
@SectionId('PD00-SYO-RIS')
class RisksAndAssumptions {
  @Unused()
  String? content;

  /// 4.7.1. Key Risks [PD00-SYO-RIS-RIS] — contains 0+× Risk.
  @SectionIdPattern('PD00-SYO-RIS-RIS-xx')
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
@SectionId('PD00-SYO-RIS-ASS')
class KeyAssumptions {
  @Unused()
  String? content;

  /// Contains 0+× Assumption.
  @SectionIdPattern('PD00-SYO-RIS-ASS-xx')
  List<AssumptionEntry> items = [];
}
