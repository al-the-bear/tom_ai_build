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
  SystemContext systemContext = SystemContext();

  /// 4.1.3. Description of Task Area [PD00-SYO-SYD-DES].
  TaskArea taskArea = TaskArea();

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

// ---------------------------------------------------------------------------
// 4.1.2 System Context
// ---------------------------------------------------------------------------

/// 4.1.2. System Context [PD00-SYO-SYD-CON].
///
/// Describes the system in its operational context: how it fits within the
/// organization's IT landscape, who interacts with it, and what external
/// systems it connects to. Based on UML context diagrams and IEEE 830.
@SectionId('PD00-SYO-SYD-CON')
@ContentHelp('Describe the system in its operational context. Include: '
    'how it fits in the IT landscape, who interacts with it, '
    'external systems it connects to, and a context diagram.')
class SystemContext {
  @ContentType('description', 'High-level overview of the system context '
      'and its position in the overall enterprise architecture.')
  String? content;

  /// 4.1.2.1. Context Diagram [PD00-SYO-SYD-CON-DIA].
  ContextDiagram contextDiagram = ContextDiagram();

  /// 4.1.2.2. IT Landscape Position [PD00-SYO-SYD-CON-ITP].
  ItLandscapePosition itLandscapePosition = ItLandscapePosition();

  /// 4.1.2.3. External Actors [PD00-SYO-SYD-CON-ACT].
  ExternalActors externalActors = ExternalActors();

  /// 4.1.2.4. External Systems [PD00-SYO-SYD-CON-SYS].
  ExternalSystemsContext externalSystems = ExternalSystemsContext();

  /// 4.1.2.5. Trust Boundaries [PD00-SYO-SYD-CON-TRU].
  TrustBoundaries trustBoundaries = TrustBoundaries();

  /// 4.1.2.6. Organizational Context [PD00-SYO-SYD-CON-ORG].
  OrganizationalContext organizationalContext = OrganizationalContext();

  /// 4.1.2.7. Deployment Context [PD00-SYO-SYD-CON-DEP].
  DeploymentContext deploymentContext = DeploymentContext();

  /// 4.1.2.8. Regulatory Context [PD00-SYO-SYD-CON-REG].
  RegulatoryContext regulatoryContext = RegulatoryContext();
}

/// 4.1.2.1. Context Diagram [PD00-SYO-SYD-CON-DIA].
///
/// Visual representation of the system as a black box showing external
/// entities and data flows (UML context diagram / DFD Level 0).
@SectionId('PD00-SYO-SYD-CON-DIA')
@ContentHelp('Provide a context diagram showing the system as a black box '
    'with all external entities (users, systems, organizations) and '
    'the data/control flows between them.')
class ContextDiagram {
  @ContentType('description', 'Explanation of the context diagram, '
      'key relationships, and data flow patterns.')
  String? content;

  /// Context diagram in Mermaid format.
  @SectionId('PD00-SYO-SYD-CON-DIA-MER')
  @ContentType('mermaid-flowchart', 'Context diagram showing the system '
      'as a central node with external actors and systems connected by '
      'labeled data flows')
  @ContentHelp('Create a Mermaid flowchart with the system in the center '
      'and all external entities around it. Label edges with data flow '
      'descriptions (e.g., "orders", "payments", "notifications").')
  String? diagram;

  /// Diagram legend and conventions.
  @ContentType('description', 'Legend explaining shapes, colors, and '
      'line styles used in the diagram.')
  String? legend;
}

/// 4.1.2.2. IT Landscape Position [PD00-SYO-SYD-CON-ITP].
///
/// How this system fits within the organization's overall IT architecture
/// and application portfolio.
@SectionId('PD00-SYO-SYD-CON-ITP')
@ContentHelp('Describe how this system fits in the overall IT architecture. '
    'What role does it play? What other systems does it complement or replace?')
class ItLandscapePosition {
  @ContentType('description', 'Overview of the system\'s role in the '
      'IT landscape and application portfolio.')
  String? content;

  /// IT Landscape Position Details (form).
  @Form([
    Field('architectureLayer', String,
        'Architecture Layer (Presentation, Business, Data, Integration)'),
    Field('applicationCategory', String,
        'Application Category (Core, Support, Management, Infrastructure)'),
    Field('portfolioRole', String,
        'Portfolio Role (Strategic, Key Operational, Support, Legacy)'),
    Field('replacedSystems', String,
        'Replaced Systems (systems this will replace or retire)'),
    Field('complementarySystems', String,
        'Complementary Systems (systems this works alongside)'),
    Field('dependsOnSystems', String,
        'Depends On Systems (systems this requires to operate)'),
    Field('dependentSystems', String,
        'Dependent Systems (systems that will depend on this)'),
    Field('dataOwnership', String,
        'Data Ownership (what master data does this system own)'),
    Field('integrationPattern', String,
        'Primary Integration Pattern (API, Event, Batch, Real-time)'),
  ])
  String? positionDetails;
}

/// 4.1.2.3. External Actors [PD00-SYO-SYD-CON-ACT].
///
/// Human users and organizational entities that interact with the system
/// from outside the system boundary.
@SectionId('PD00-SYO-SYD-CON-ACT')
@ContentHelp('List all external actors (human users, organizations, '
    'external parties) that interact with the system.')
class ExternalActors {
  @ContentType('description', 'Overview of external actors and '
      'their interaction patterns with the system.')
  String? content;

  /// Actor entries — contains 1+× ExternalActorEntry.
  @SectionIdPattern('PD00-SYO-SYD-CON-ACT-xx')
  @Min(1)
  @ContentHelp('Add one entry per external actor or actor category '
      'that interacts with the system.')
  List<ExternalActorEntry> actors = [];
}

/// An external actor entry (form).
class ExternalActorEntry {
  @Form([
    Field('actorName', String, 'Actor Name', required: true),
    Field('actorType', String,
        'Actor Type (Internal User, External User, Organization, '
            'Partner, Customer, Regulator, etc.)', required: true),
    Field('description', String, 'Actor Description'),
    Field('interactionPurpose', String,
        'Interaction Purpose (why they interact with the system)'),
    Field('interactionFrequency', String,
        'Interaction Frequency (Real-time, Daily, Weekly, On-demand)'),
    Field('interactionChannel', String,
        'Interaction Channel (Web UI, Mobile App, API, Email, etc.)'),
    Field('dataExchanged', String,
        'Data Exchanged (what information flows to/from this actor)'),
    Field('accessLevel', String,
        'Access Level (Read, Write, Admin, API-only, etc.)'),
    Field('authenticationMethod', String,
        'Authentication Method (SSO, Password, Certificate, API Key, etc.)'),
    Field('location', String,
        'Location (On-site, Remote, Mobile, Global, etc.)'),
    Field('volumeEstimate', String,
        'Volume Estimate (number of actors, transactions per day)'),
  ])
  String? content;

  /// Interaction scenarios for this actor.
  @ContentType('description', 'Key interaction scenarios describing '
      'typical workflows for this actor.')
  String? interactionScenarios;
}

/// 4.1.2.4. External Systems [PD00-SYO-SYD-CON-SYS].
///
/// External systems, services, and APIs that the system integrates with.
@SectionId('PD00-SYO-SYD-CON-SYS')
@ContentHelp('List all external systems, services, and APIs that this '
    'system will integrate with. Include both incoming and outgoing '
    'integrations.')
class ExternalSystemsContext {
  @ContentType('description', 'Overview of external system integrations '
      'and integration architecture.')
  String? content;

  /// External system entries — contains 0+× ExternalSystemContextEntry.
  @SectionIdPattern('PD00-SYO-SYD-CON-SYS-xx')
  @ContentHelp('Add one entry per external system that this system '
      'integrates with.')
  List<ExternalSystemContextEntry> systems = [];
}

/// An external system context entry (form).
class ExternalSystemContextEntry {
  @Form([
    Field('systemName', String, 'System Name', required: true),
    Field('systemOwner', String, 'System Owner (organization/department)'),
    Field('systemType', String,
        'System Type (ERP, CRM, Database, API, SaaS, Legacy, etc.)',
        required: true),
    Field('integrationDirection', String,
        'Integration Direction (Inbound, Outbound, Bidirectional)',
        required: true),
    Field('integrationPurpose', String,
        'Integration Purpose (what business need does this serve)'),
    Field('dataExchanged', String,
        'Data Exchanged (what data flows between systems)'),
    Field('integrationMethod', String,
        'Integration Method (REST API, SOAP, File Transfer, Database, '
            'Message Queue, Event Stream, etc.)'),
    Field('integrationFrequency', String,
        'Integration Frequency (Real-time, Near-real-time, Batch, '
            'On-demand)'),
    Field('dataVolume', String,
        'Data Volume (estimated records/transactions per time period)'),
    Field('sla', String,
        'SLA (availability, response time requirements)'),
    Field('errorHandling', String,
        'Error Handling (retry, dead-letter, manual intervention)'),
    Field('securityRequirements', String,
        'Security Requirements (encryption, authentication, network)'),
    Field('contactPerson', String, 'Contact Person (technical contact)'),
  ])
  String? content;

  /// Data mapping details.
  @ContentType('description', 'Details of data transformation and '
      'mapping between systems.')
  String? dataMapping;
}

/// 4.1.2.5. Trust Boundaries [PD00-SYO-SYD-CON-TRU].
///
/// Security zones and trust boundaries that the system operates within
/// or crosses.
@SectionId('PD00-SYO-SYD-CON-TRU')
@ContentHelp('Define the trust boundaries (security zones) that the system '
    'operates within and crosses. This is important for security design.')
class TrustBoundaries {
  @ContentType('description', 'Overview of trust boundaries and '
      'security zones relevant to this system.')
  String? content;

  /// Trust boundary entries — contains 0+× TrustBoundaryEntry.
  @SectionIdPattern('PD00-SYO-SYD-CON-TRU-xx')
  @ContentHelp('Add one entry per trust boundary or security zone.')
  List<TrustBoundaryEntry> boundaries = [];
}

/// A trust boundary entry (form).
class TrustBoundaryEntry {
  @Form([
    Field('boundaryName', String, 'Boundary Name', required: true),
    Field('boundaryType', String,
        'Boundary Type (Network Zone, Authentication Domain, '
            'Organizational, Legal/Regulatory, Cloud/On-Prem)', required: true),
    Field('description', String, 'Description'),
    Field('componentsCrossing', String,
        'Components Crossing (which parts of the system cross this boundary)'),
    Field('protectionMechanisms', String,
        'Protection Mechanisms (firewall, encryption, authentication, etc.)'),
    Field('trustLevel', String,
        'Trust Level (Untrusted, Semi-trusted, Trusted, Highly Trusted)'),
    Field('complianceImplications', String,
        'Compliance Implications (regulatory requirements for crossing)'),
  ])
  String? content;
}

/// 4.1.2.6. Organizational Context [PD00-SYO-SYD-CON-ORG].
///
/// Organizational units, departments, and business areas that the system
/// serves or interacts with.
@SectionId('PD00-SYO-SYD-CON-ORG')
@ContentHelp('Describe the organizational context: which departments, '
    'business units, and organizational structures are involved.')
class OrganizationalContext {
  @ContentType('description', 'Overview of the organizational context '
      'and business units served by the system.')
  String? content;

  /// Organizational unit entries — contains 0+× OrganizationalUnitContextEntry.
  @SectionIdPattern('PD00-SYO-SYD-CON-ORG-xx')
  @ContentHelp('Add one entry per organizational unit that uses or '
      'is affected by the system.')
  List<OrganizationalUnitContextEntry> organizationalUnits = [];

  /// Business process coverage.
  @ContentType('description', 'Which business processes does this system '
      'support or automate?')
  String? businessProcessCoverage;
}

/// An organizational unit context entry (form).
class OrganizationalUnitContextEntry {
  @Form([
    Field('unitName', String, 'Unit Name', required: true),
    Field('unitType', String,
        'Unit Type (Department, Division, Team, Business Unit, '
            'Subsidiary, External Partner)'),
    Field('role', String, 'Role (Primary User, Secondary User, '
        'Data Provider, Beneficiary, Sponsor)'),
    Field('responsibilities', String,
        'Responsibilities (what they do with/for the system)'),
    Field('headcount', String, 'Headcount (estimated number of users)'),
    Field('location', String, 'Location (geographic location)'),
    Field('timezone', String, 'Timezone (primary operating timezone)'),
    Field('keyContacts', String, 'Key Contacts (business contacts)'),
  ])
  String? content;
}

/// 4.1.2.7. Deployment Context [PD00-SYO-SYD-CON-DEP].
///
/// Where and how the system will be deployed in the infrastructure
/// landscape.
@SectionId('PD00-SYO-SYD-CON-DEP')
@ContentHelp('Describe the deployment context: where the system will be '
    'deployed, what infrastructure it will use, and deployment constraints.')
class DeploymentContext {
  @ContentType('description', 'Overview of the deployment environment '
      'and infrastructure context.')
  String? content;

  /// Deployment Context Details (form).
  @Form([
    Field('deploymentModel', String,
        'Deployment Model (On-Premises, Cloud, Hybrid, Multi-Cloud)'),
    Field('cloudProvider', String,
        'Cloud Provider (AWS, Azure, GCP, Private Cloud, N/A)'),
    Field('hostingEnvironment', String,
        'Hosting Environment (Containers, VMs, Serverless, Bare Metal)'),
    Field('dataCenter', String,
        'Data Center (location, name, or identifier)'),
    Field('geographicDistribution', String,
        'Geographic Distribution (Single region, Multi-region, Global)'),
    Field('availabilityZones', String,
        'Availability Zones (redundancy configuration)'),
    Field('networkZone', String,
        'Network Zone (DMZ, Internal, Private, Public)'),
    Field('scalingModel', String,
        'Scaling Model (Horizontal, Vertical, Auto-scaling, Manual)'),
    Field('disasterRecovery', String,
        'Disaster Recovery (DR site, strategy)'),
    Field('environmentTypes', String,
        'Environment Types (Dev, Test, Staging, Production, DR)'),
  ])
  String? deploymentDetails;
}

/// 4.1.2.8. Regulatory Context [PD00-SYO-SYD-CON-REG].
///
/// Regulatory and compliance context that affects system design and
/// operations.
@SectionId('PD00-SYO-SYD-CON-REG')
@ContentHelp('Describe the regulatory and compliance context: which '
    'regulations apply, what compliance requirements exist.')
class RegulatoryContext {
  @ContentType('description', 'Overview of the regulatory environment '
      'and compliance requirements affecting this system.')
  String? content;

  /// Applicable regulations — contains 0+× ApplicableRegulationEntry.
  @SectionIdPattern('PD00-SYO-SYD-CON-REG-xx')
  @ContentHelp('Add one entry per applicable regulation or compliance '
      'requirement.')
  List<ApplicableRegulationEntry> regulations = [];
}

/// An applicable regulation entry (form).
class ApplicableRegulationEntry {
  @Form([
    Field('regulationName', String, 'Regulation Name', required: true),
    Field('regulationCode', String, 'Regulation Code / Reference'),
    Field('regulationType', String,
        'Regulation Type (Privacy, Security, Financial, Industry, '
            'Data Retention, Accessibility)', required: true),
    Field('jurisdiction', String,
        'Jurisdiction (Geographic or organizational scope)'),
    Field('applicability', String,
        'Applicability (why this regulation applies to this system)'),
    Field('keyRequirements', String,
        'Key Requirements (summary of main requirements)'),
    Field('complianceStatus', String,
        'Compliance Status (Compliant, Partially Compliant, Non-Compliant, '
            'To Be Assessed)'),
    Field('complianceOwner', String,
        'Compliance Owner (who is responsible for compliance)'),
    Field('auditRequirements', String,
        'Audit Requirements (audit frequency, type)'),
    Field('penalties', String,
        'Penalties (consequences of non-compliance)'),
  ])
  String? content;

  /// Specific compliance measures for this regulation.
  @ContentType('description', 'Detailed compliance measures and controls '
      'implemented for this regulation.')
  String? complianceMeasures;
}

// ---------------------------------------------------------------------------
// 4.1.3 Description of Task Area
// ---------------------------------------------------------------------------

/// 4.1.3. Description of Task Area [PD00-SYO-SYD-DES].
///
/// Describes the business domain and task area the system addresses.
/// Defines the domain vocabulary and key concepts (ubiquitous language)
/// that will be used throughout the project. Based on Domain-Driven Design
/// principles for establishing a shared understanding.
@SectionId('PD00-SYO-SYD-DES')
@ContentHelp('Describe the business domain and task area this system '
    'addresses. Define the domain vocabulary and key concepts that will '
    'be used throughout the project documentation. This establishes '
    'the ubiquitous language for the project.')
class TaskArea {
  @ContentType('description', 'High-level overview of the business domain '
      'and task area, explaining what business activities and processes '
      'this system will support.')
  String? content;

  /// 4.1.3.1. Domain Overview [PD00-SYO-SYD-DES-OVE].
  DomainOverview domainOverview = DomainOverview();

  /// 4.1.3.2. Domain Vocabulary [PD00-SYO-SYD-DES-VOC].
  DomainVocabulary domainVocabulary = DomainVocabulary();

  /// 4.1.3.3. Key Concepts [PD00-SYO-SYD-DES-CON].
  KeyConcepts keyConcepts = KeyConcepts();

  /// 4.1.3.4. Domain Boundaries [PD00-SYO-SYD-DES-BOU].
  DomainBoundaries domainBoundaries = DomainBoundaries();

  /// 4.1.3.5. Business Rules [PD00-SYO-SYD-DES-RUL].
  DomainBusinessRules businessRules = DomainBusinessRules();

  /// 4.1.3.6. Domain Processes [PD00-SYO-SYD-DES-PRO].
  DomainProcesses domainProcesses = DomainProcesses();

  /// 4.1.3.7. Domain Events [PD00-SYO-SYD-DES-EVE].
  DomainEvents domainEvents = DomainEvents();
}

/// 4.1.3.1. Domain Overview [PD00-SYO-SYD-DES-OVE].
///
/// High-level description of the business domain including its purpose,
/// scope, and relationship to the overall business.
@SectionId('PD00-SYO-SYD-DES-OVE')
@ContentHelp('Provide a comprehensive overview of the business domain: '
    'what area of business it covers, its importance to the organization, '
    'and how it relates to other business domains.')
class DomainOverview {
  @ContentType('description', 'Narrative description of the business domain, '
      'its purpose, and significance to the organization.')
  String? content;

  /// Domain Overview Details (form).
  @Form([
    Field('domainName', String, 'Domain Name', required: true),
    Field('domainDescription', String,
        'Domain Description (what this domain encompasses)'),
    Field('businessImportance', String,
        'Business Importance (why this domain matters to the organization)'),
    Field('industryContext', String,
        'Industry Context (how this domain fits in the industry)'),
    Field('relatedDomains', String,
        'Related Domains (other business domains this interacts with)'),
    Field('domainOwner', String,
        'Domain Owner (business unit or person responsible)'),
    Field('keyStakeholders', String,
        'Key Stakeholders (who has interest in this domain)'),
    Field('domainMaturity', String,
        'Domain Maturity (Emerging, Established, Mature, Legacy)'),
    Field('changeFrequency', String,
        'Change Frequency (how often this domain changes)'),
  ])
  String? domainDetails;
}

/// 4.1.3.2. Domain Vocabulary [PD00-SYO-SYD-DES-VOC].
///
/// Glossary of domain-specific terms and definitions establishing the
/// ubiquitous language for the project.
@SectionId('PD00-SYO-SYD-DES-VOC')
@ContentHelp('Define all domain-specific terms and their meanings. '
    'This glossary establishes the ubiquitous language - the shared '
    'vocabulary that all team members and stakeholders will use.')
class DomainVocabulary {
  @ContentType('description', 'Introduction to the domain vocabulary '
      'and guidelines for using consistent terminology.')
  String? content;

  /// Vocabulary entries — contains 1+× DomainTermEntry.
  @SectionIdPattern('PD00-SYO-SYD-DES-VOC-xx')
  @Min(1)
  @ContentHelp('Add one entry per domain term. Include all business-specific '
      'terms that may be unfamiliar or have domain-specific meanings.')
  List<DomainTermEntry> terms = [];
}

/// A domain term entry (form).
class DomainTermEntry {
  @Form([
    Field('term', String, 'Term', required: true),
    Field('definition', String, 'Definition', required: true),
    Field('synonyms', String, 'Synonyms (alternative terms sometimes used)'),
    Field('antiPatterns', String,
        'Anti-Patterns (terms to avoid, incorrect usage)'),
    Field('examples', String, 'Examples (usage examples)'),
    Field('relatedTerms', String, 'Related Terms (linked concepts)'),
    Field('category', String,
        'Category (Entity, Process, Role, Metric, Status, etc.)'),
    Field('source', String,
        'Source (where this definition comes from: industry, company, etc.)'),
    Field('abbreviation', String, 'Abbreviation (if commonly abbreviated)'),
  ])
  String? content;
}

/// 4.1.3.3. Key Concepts [PD00-SYO-SYD-DES-CON].
///
/// Core business concepts and entities in the domain, their attributes,
/// and relationships (conceptual domain model).
@SectionId('PD00-SYO-SYD-DES-CON')
@ContentHelp('Describe the key concepts (entities, value objects, aggregates) '
    'in the domain. This is the conceptual domain model showing core '
    'business objects and their relationships.')
class KeyConcepts {
  @ContentType('description', 'Overview of the key concepts in the domain '
      'and how they relate to each other.')
  String? content;

  /// Conceptual domain model diagram.
  @SectionId('PD00-SYO-SYD-DES-CON-DIA')
  @ContentType('mermaid-classDiagram', 'Conceptual domain model showing '
      'key entities and their relationships')
  @ContentHelp('Create a Mermaid class diagram showing the main domain '
      'concepts and their relationships. Focus on business concepts, '
      'not technical implementation.')
  String? conceptualModelDiagram;

  /// Key concept entries — contains 1+× KeyConceptEntry.
  @SectionIdPattern('PD00-SYO-SYD-DES-CON-xx')
  @Min(1)
  @ContentHelp('Add one entry per key business concept or entity.')
  List<KeyConceptEntry> concepts = [];
}

/// A key concept entry (form).
class KeyConceptEntry {
  @Form([
    Field('conceptName', String, 'Concept Name', required: true),
    Field('conceptType', String,
        'Concept Type (Entity, Value Object, Aggregate Root, Event, Service)',
        required: true),
    Field('description', String, 'Description', required: true),
    Field('keyAttributes', String,
        'Key Attributes (main properties of this concept)'),
    Field('identifiedBy', String,
        'Identified By (what uniquely identifies instances)'),
    Field('lifecycle', String,
        'Lifecycle (how instances are created, modified, archived)'),
    Field('ownedBy', String,
        'Owned By (which business function owns this concept)'),
    Field('relatedConcepts', String,
        'Related Concepts (other concepts this relates to)'),
    Field('businessRules', String,
        'Business Rules (rules that govern this concept)'),
    Field('volumeEstimate', String,
        'Volume Estimate (expected number of instances)'),
  ])
  String? content;

  /// Detailed attribute definitions for this concept.
  @ContentType('description', 'Detailed description of attributes, '
      'their types, constraints, and business meaning.')
  String? attributeDetails;

  /// Relationships to other concepts.
  @ContentType('description', 'Detailed description of how this concept '
      'relates to other concepts in the domain.')
  String? relationshipDetails;
}

/// 4.1.3.4. Domain Boundaries [PD00-SYO-SYD-DES-BOU].
///
/// Clear definition of what is within and outside the domain scope,
/// based on bounded context principles.
@SectionId('PD00-SYO-SYD-DES-BOU')
@ContentHelp('Define clear boundaries for this domain: what concepts, '
    'processes, and responsibilities are within scope, and what belongs '
    'to adjacent domains. This establishes the bounded context.')
class DomainBoundaries {
  @ContentType('description', 'Overview of domain boundaries and '
      'how this domain interfaces with others.')
  String? content;

  /// Context map showing domain boundaries.
  @SectionId('PD00-SYO-SYD-DES-BOU-MAP')
  @ContentType('mermaid-flowchart', 'Context map showing this domain '
      'and its relationships to adjacent domains')
  @ContentHelp('Create a context map showing this domain (bounded context) '
      'and how it relates to other domains/contexts.')
  String? contextMap;

  /// Within-scope items.
  @ContentType('description', 'Concepts, processes, and responsibilities '
      'that are within this domain\'s scope.')
  String? withinScope;

  /// Outside-scope items.
  @ContentType('description', 'Concepts and responsibilities that belong '
      'to other domains and are outside this domain\'s scope.')
  String? outsideScope;

  /// Domain interfaces — contains 0+× DomainInterfaceEntry.
  @SectionIdPattern('PD00-SYO-SYD-DES-BOU-INT-xx')
  @ContentHelp('Define interfaces to adjacent domains - how this domain '
      'communicates with and shares data with other domains.')
  List<DomainInterfaceEntry> interfaces = [];
}

/// A domain interface entry (form).
class DomainInterfaceEntry {
  @Form([
    Field('adjacentDomain', String, 'Adjacent Domain Name', required: true),
    Field('interfaceType', String,
        'Interface Type (Shared Kernel, Customer-Supplier, '
            'Conformist, Anti-Corruption Layer, Published Language)',
        required: true),
    Field('direction', String,
        'Direction (Upstream, Downstream, Bidirectional)'),
    Field('dataExchanged', String,
        'Data Exchanged (what information crosses the boundary)'),
    Field('integrationMechanism', String,
        'Integration Mechanism (API, Events, Shared Database, etc.)'),
    Field('translationRequired', String,
        'Translation Required (does data need transformation?)'),
    Field('owner', String,
        'Owner (who owns this interface)'),
  ])
  String? content;
}

/// 4.1.3.5. Domain Business Rules [PD00-SYO-SYD-DES-RUL].
///
/// Business rules, policies, and constraints that govern behavior
/// within this domain.
@SectionId('PD00-SYO-SYD-DES-RUL')
@ContentHelp('Document the business rules that govern this domain. '
    'Include policies, constraints, calculations, and decision logic.')
class DomainBusinessRules {
  @ContentType('description', 'Overview of business rules and their '
      'importance in this domain.')
  String? content;

  /// Business rule entries — contains 0+× BusinessRuleEntry.
  @SectionIdPattern('PD00-SYO-SYD-DES-RUL-xx')
  @ContentHelp('Add one entry per business rule. Be specific and unambiguous.')
  List<DomainBusinessRuleEntry> rules = [];
}

/// A domain business rule entry (form).
class DomainBusinessRuleEntry {
  @Form([
    Field('ruleId', String, 'Rule ID', required: true),
    Field('ruleName', String, 'Rule Name', required: true),
    Field('ruleType', String,
        'Rule Type (Constraint, Calculation, Derivation, Action-Trigger, '
            'Authorization, Validation)', required: true),
    Field('description', String, 'Description (plain language)', required: true),
    Field('formalStatement', String,
        'Formal Statement (precise, unambiguous statement)'),
    Field('appliesTo', String,
        'Applies To (which concepts/processes this rule governs)'),
    Field('conditions', String,
        'Conditions (when this rule applies)'),
    Field('consequences', String,
        'Consequences (what happens when rule is triggered/violated)'),
    Field('priority', String,
        'Priority (if rules conflict, which takes precedence)'),
    Field('source', String,
        'Source (regulation, policy, business decision)'),
    Field('exceptions', String,
        'Exceptions (when rule does not apply)'),
    Field('examples', String,
        'Examples (concrete examples of rule application)'),
  ])
  String? content;
}

/// 4.1.3.6. Domain Processes [PD00-SYO-SYD-DES-PRO].
///
/// High-level business processes within this domain, showing the main
/// workflows and activities.
@SectionId('PD00-SYO-SYD-DES-PRO')
@ContentHelp('Describe the main business processes within this domain. '
    'Focus on business activities, not system implementation.')
class DomainProcesses {
  @ContentType('description', 'Overview of the key business processes '
      'that operate within this domain.')
  String? content;

  /// Process overview diagram.
  @SectionId('PD00-SYO-SYD-DES-PRO-DIA')
  @ContentType('mermaid-flowchart', 'High-level process map showing '
      'main processes and their relationships')
  @ContentHelp('Create a process map showing the main business processes '
      'and how they interact.')
  String? processOverviewDiagram;

  /// Domain process entries — contains 0+× DomainProcessEntry.
  @SectionIdPattern('PD00-SYO-SYD-DES-PRO-xx')
  @ContentHelp('Add one entry per major business process in this domain.')
  List<DomainProcessEntry> processes = [];
}

/// A domain process entry (form).
class DomainProcessEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('processDescription', String, 'Process Description', required: true),
    Field('processType', String,
        'Process Type (Core, Support, Management)'),
    Field('trigger', String,
        'Trigger (what initiates this process)'),
    Field('inputs', String,
        'Inputs (what data/artifacts are needed)'),
    Field('outputs', String,
        'Outputs (what is produced)'),
    Field('participants', String,
        'Participants (roles/actors involved)'),
    Field('frequency', String,
        'Frequency (how often this process runs)'),
    Field('duration', String,
        'Duration (typical time to complete)'),
    Field('successCriteria', String,
        'Success Criteria (what defines successful completion)'),
    Field('keyDecisions', String,
        'Key Decisions (decision points within the process)'),
    Field('relatedProcesses', String,
        'Related Processes (processes that interact with this one)'),
  ])
  String? content;

  /// Process flow details.
  @ContentType('description', 'Detailed description of process steps, '
      'decision points, and variations.')
  String? processFlowDetails;
}

/// 4.1.3.7. Domain Events [PD00-SYO-SYD-DES-EVE].
///
/// Significant business events that occur within this domain and
/// trigger actions or state changes.
@SectionId('PD00-SYO-SYD-DES-EVE')
@ContentHelp('Document significant business events within this domain. '
    'Events represent things that happen which are important to the '
    'business and may trigger reactions.')
class DomainEvents {
  @ContentType('description', 'Overview of key domain events and '
      'their significance.')
  String? content;

  /// Domain event entries — contains 0+× DomainEventEntry.
  @SectionIdPattern('PD00-SYO-SYD-DES-EVE-xx')
  @ContentHelp('Add one entry per significant business event.')
  List<DomainEventEntry> events = [];
}

/// A domain event entry (form).
class DomainEventEntry {
  @Form([
    Field('eventName', String, 'Event Name (past tense, e.g., OrderPlaced)',
        required: true),
    Field('eventDescription', String, 'Event Description', required: true),
    Field('eventType', String,
        'Event Type (State Change, Action Completed, Time-based, External)'),
    Field('trigger', String,
        'Trigger (what causes this event)'),
    Field('sourceEntity', String,
        'Source Entity (which concept generates this event)'),
    Field('eventData', String,
        'Event Data (what information is carried with the event)'),
    Field('subscribers', String,
        'Subscribers (who/what reacts to this event)'),
    Field('reactions', String,
        'Reactions (what happens when this event occurs)'),
    Field('frequency', String,
        'Frequency (how often this event occurs)'),
    Field('businessImpact', String,
        'Business Impact (significance of this event)'),
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

// ---------------------------------------------------------------------------
// 4.1.4 User Categories
// ---------------------------------------------------------------------------

/// 4.1.4. User Categories [PD00-SYO-SYD-USR].
///
/// Container for user category definitions. Each user category describes a
/// distinct group of users with shared characteristics, access needs, and
/// system interaction patterns. Based on user persona methodology for
/// user-centered design.
@SectionId('PD00-SYO-SYD-USR')
@ContentHelp('Define all user categories (personas) that will interact with '
    'the system. Each category represents a distinct group with shared '
    'characteristics, needs, and interaction patterns. Use this to drive '
    'user-centered design decisions.')
class UserCategories {
  @ContentType('description', 'Overview of user categories and how they '
      'relate to the system. Include summary of user population and '
      'key differences between categories.')
  String? content;

  /// User category overview diagram.
  @SectionId('PD00-SYO-SYD-USR-DIA')
  @ContentType('mermaid-flowchart', 'User category hierarchy or relationship '
      'diagram showing how different user types relate')
  @ContentHelp('Create a diagram showing user categories, their '
      'relationships, and organizational hierarchy.')
  String? userCategoryDiagram;

  /// User category entries — contains 1+× UserCategoryEntry.
  @SectionIdPattern('PD00-SYO-SYD-USR-xx')
  @Min(1)
  @ContentHelp('Add one entry per distinct user category. Categories should '
      'be mutually exclusive where possible, with clear distinguishing '
      'characteristics.')
  List<UserCategoryEntry> categories = [];
}

/// A user category entry [PD00-SYO-SYD-USR-nn].
///
/// Comprehensive user persona definition including demographics, goals,
/// frustrations, technical proficiency, and system interaction patterns.
class UserCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('categoryId', String, 'Category ID (unique identifier)'),
    Field('description', String, 'Description (brief summary of this user type)',
        required: true),
    Field('userType', String,
        'User Type (Internal, External, Partner, Customer, Administrator, etc.)',
        required: true),
    Field('technicalProficiency', String,
        'Technical Proficiency (Novice, Intermediate, Advanced, Expert)'),
    Field('frequencyOfUse', String,
        'Frequency of Use (Continuous, Daily, Weekly, Monthly, Occasional)'),
    Field('accessChannel', String,
        'Primary Access Channel (Web, Mobile, Desktop, API, etc.)'),
    Field('estimatedUserCount', String,
        'Estimated User Count (current number or range)'),
    Field('growthExpectation', String,
        'Growth Expectation (expected change in user count)'),
    Field('criticality', String,
        'Criticality (how critical is this user group to the system)'),
    Field('priority', String,
        'Priority (High, Medium, Low - for design decisions)'),
  ])
  String? content;

  /// 4.1.4.n.1. User Persona Details [PD00-SYO-SYD-USR-nn-PER].
  UserPersonaDetails personaDetails = UserPersonaDetails();

  /// 4.1.4.n.2. Role [PD00-SYO-SYD-USR-nn-ROL].
  UserCategoryRoleEntry? role;

  /// 4.1.4.n.3. System Tasks [PD00-SYO-SYD-USR-nn-TSK] — contains 1+× System Task.
  @SectionIdPattern('PD00-SYO-SYD-USR-xx-TSK-xx')
  @Min(1)
  List<SystemTaskEntry> systemTasks = [];

  /// 4.1.4.n.4. Access and Permissions [PD00-SYO-SYD-USR-nn-ACC].
  UserAccessPermissions accessPermissions = UserAccessPermissions();

  /// 4.1.4.n.5. Training Requirements [PD00-SYO-SYD-USR-nn-TRA].
  UserTrainingRequirements trainingRequirements = UserTrainingRequirements();

  /// 4.1.4.n.6. Accessibility Needs [PD00-SYO-SYD-USR-nn-ACS].
  UserAccessibilityNeeds accessibilityNeeds = UserAccessibilityNeeds();

  /// 4.1.4.n.7. User Journey [PD00-SYO-SYD-USR-nn-JOU].
  UserJourney userJourney = UserJourney();
}

/// 4.1.4.n.1. User Persona Details [PD00-SYO-SYD-USR-nn-PER].
///
/// Detailed persona information including demographics, goals, frustrations,
/// and behavioral characteristics for user-centered design.
@SectionId('PD00-SYO-SYD-USR-nn-PER')
@ContentHelp('Describe the persona in detail to help designers and developers '
    'understand and empathize with this user type.')
class UserPersonaDetails {
  @ContentType('description', 'Narrative description of the persona, '
      'written from a human perspective.')
  String? content;

  /// Persona Details Form.
  @Form([
    Field('representativeName', String,
        'Representative Name (fictional name for this persona)'),
    Field('ageRange', String, 'Age Range'),
    Field('educationLevel', String, 'Education Level'),
    Field('jobTitle', String, 'Job Title / Position'),
    Field('yearsOfExperience', String, 'Years of Experience (in this role)'),
    Field('workEnvironment', String,
        'Work Environment (office, remote, field, etc.)'),
    Field('primaryGoals', String,
        'Primary Goals (what they want to achieve with the system)'),
    Field('secondaryGoals', String, 'Secondary Goals'),
    Field('frustrations', String,
        'Frustrations (pain points with current solutions)'),
    Field('motivations', String, 'Motivations (what drives them)'),
    Field('fears', String, 'Fears (concerns about new systems)'),
    Field('techComfort', String,
        'Technology Comfort Level (attitude toward technology)'),
    Field('preferredLearningStyle', String,
        'Preferred Learning Style (visual, hands-on, documentation, etc.)'),
    Field('typicalWorkday', String,
        'Typical Workday (relevant aspects of daily routine)'),
    Field('decisionMakingStyle', String,
        'Decision Making Style (analytical, intuitive, collaborative)'),
  ])
  String? personaForm;

  /// Representative photo or avatar description.
  @ContentType('description', 'Description of a representative photo or '
      'avatar that embodies this persona (for design reference).')
  String? visualRepresentation;

  /// Key quotes that represent this persona's mindset.
  @ContentType('description', 'Representative quotes that capture this '
      'persona\'s attitude, needs, or concerns.')
  String? representativeQuotes;
}

/// Role within a user category [PD00-SYO-SYD-USR-nn-ROL].
///
/// Organizational role and responsibilities associated with this user category.
class UserCategoryRoleEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true),
    Field('roleDescription', String, 'Role Description', required: true),
    Field('organizationUnit', String, 'Organization Unit'),
    Field('reportsTo', String, 'Reports To (role or position)'),
    Field('directReports', String, 'Direct Reports (roles reporting to this)'),
    Field('responsibilities', String,
        'Key Responsibilities (main job functions)'),
    Field('decisionAuthority', String,
        'Decision Authority (what decisions can they make)'),
    Field('budgetAuthority', String,
        'Budget Authority (financial approval limits)'),
    Field('collaborators', String,
        'Primary Collaborators (roles they work with)'),
    Field('performanceMetrics', String,
        'Performance Metrics (how their success is measured)'),
  ])
  String? content;
}

/// A system task entry [PD00-SYO-SYD-USR-nn-TSK-mm].
///
/// Describes one activity this user category performs with the system.
/// Tasks map to Use Cases in the UC document.
class SystemTaskEntry {
  @Form([
    Field('taskId', String, 'Task ID', required: true),
    Field('taskName', String, 'Task Name', required: true),
    Field('description', String, 'Description (what the user does)'),
    Field('frequency', String,
        'Frequency (how often: Continuous, Daily, Weekly, Monthly, Ad-hoc)'),
    Field('averageDuration', String,
        'Average Duration (typical time to complete)'),
    Field('complexity', String, 'Complexity (Simple, Moderate, Complex)'),
    Field('importance', String,
        'Importance (Critical, High, Medium, Low)'),
    Field('trigger', String, 'Trigger (what initiates this task)'),
    Field('expectedOutcome', String, 'Expected Outcome'),
    Field('successCriteria', String, 'Success Criteria'),
    Field('dataAccessed', String, 'Data Accessed (what information is needed)'),
    Field('dataModified', String, 'Data Modified (what information changes)'),
    Field('toolsUsed', String, 'Tools Used (systems or tools involved)'),
  ])
  String? content;

  @Reference('Related Use Case')
  String? relatedUseCase;

  /// Task workflow steps.
  @ContentType('description', 'Detailed steps for completing this task.')
  String? workflowSteps;

  /// Variations and exceptions.
  @ContentType('description', 'Alternative paths and exception handling.')
  String? variationsAndExceptions;
}

/// 4.1.4.n.4. Access and Permissions [PD00-SYO-SYD-USR-nn-ACC].
///
/// Security and access control specifications for this user category.
@SectionId('PD00-SYO-SYD-USR-nn-ACC')
@ContentHelp('Define the access rights, permissions, and security '
    'constraints for this user category.')
class UserAccessPermissions {
  @ContentType('description', 'Overview of access permissions and '
      'security context for this user category.')
  String? content;

  /// Access Permissions Form.
  @Form([
    Field('accessLevel', String,
        'Access Level (Guest, User, Power User, Administrator, Super Admin)',
        required: true),
    Field('authenticationMethod', String,
        'Authentication Method (Password, SSO, MFA, Certificate, etc.)',
        required: true),
    Field('authorizationRoles', String,
        'Authorization Roles (system roles assigned to this category)'),
    Field('dataAccessScope', String,
        'Data Access Scope (all, department, team, own records)'),
    Field('functionalAccess', String,
        'Functional Access (what features they can use)'),
    Field('restrictions', String,
        'Restrictions (what they cannot access or do)'),
    Field('timeRestrictions', String,
        'Time Restrictions (business hours, specific times)'),
    Field('locationRestrictions', String,
        'Location Restrictions (office only, VPN required, etc.)'),
    Field('deviceRestrictions', String,
        'Device Restrictions (managed devices only, etc.)'),
    Field('sessionTimeout', String,
        'Session Timeout (inactivity timeout duration)'),
    Field('auditRequirements', String,
        'Audit Requirements (what actions are logged)'),
  ])
  String? permissionsForm;

  /// Permission matrix entries — contains 0+× PermissionMatrixEntry.
  @SectionIdPattern('PD00-SYO-SYD-USR-xx-ACC-PER-xx')
  @ContentHelp('Define specific permission entries for fine-grained access.')
  List<PermissionMatrixEntry> permissionMatrix = [];
}

/// A permission matrix entry (form).
class PermissionMatrixEntry {
  @Form([
    Field('resource', String, 'Resource (what is being accessed)', required: true),
    Field('action', String, 'Action (Create, Read, Update, Delete, Execute)',
        required: true),
    Field('permission', String, 'Permission (Allowed, Denied, Conditional)'),
    Field('condition', String, 'Condition (if conditional, what is required)'),
    Field('scope', String, 'Scope (all, own, department, etc.)'),
  ])
  String? content;
}

/// 4.1.4.n.5. Training Requirements [PD00-SYO-SYD-USR-nn-TRA].
///
/// Training and onboarding requirements for this user category.
@SectionId('PD00-SYO-SYD-USR-nn-TRA')
@ContentHelp('Define the training and support needs for this user category.')
class UserTrainingRequirements {
  @ContentType('description', 'Overview of training requirements and '
      'support mechanisms for this user category.')
  String? content;

  /// Training Requirements Form.
  @Form([
    Field('initialTrainingRequired', bool,
        'Initial Training Required (is formal training needed)'),
    Field('trainingFormat', String,
        'Training Format (In-person, Online, Self-paced, On-the-job)'),
    Field('estimatedTrainingDuration', String,
        'Estimated Training Duration'),
    Field('certificationRequired', bool,
        'Certification Required (must pass assessment)'),
    Field('refresherFrequency', String,
        'Refresher Frequency (how often retraining is needed)'),
    Field('supportLevel', String,
        'Support Level Expected (Self-service, Help desk, Dedicated)'),
    Field('documentationNeeds', String,
        'Documentation Needs (User guide, Quick reference, Video tutorials)'),
    Field('onboardingProcess', String,
        'Onboarding Process (steps to get started)'),
    Field('mentoringRequired', bool,
        'Mentoring Required (paired with experienced user)'),
  ])
  String? trainingForm;

  /// Training topics — contains 0+× TrainingTopicEntry.
  @SectionIdPattern('PD00-SYO-SYD-USR-xx-TRA-TOP-xx')
  @ContentHelp('Define specific training topics for this user category.')
  List<TrainingTopicEntry> trainingTopics = [];
}

/// A training topic entry (form).
class TrainingTopicEntry {
  @Form([
    Field('topicName', String, 'Topic Name', required: true),
    Field('description', String, 'Description'),
    Field('learningObjectives', String, 'Learning Objectives'),
    Field('duration', String, 'Duration'),
    Field('prerequisites', String, 'Prerequisites'),
    Field('assessmentMethod', String, 'Assessment Method'),
  ])
  String? content;
}

/// 4.1.4.n.6. Accessibility Needs [PD00-SYO-SYD-USR-nn-ACS].
///
/// Accessibility requirements and accommodations for this user category.
@SectionId('PD00-SYO-SYD-USR-nn-ACS')
@ContentHelp('Document any accessibility requirements or accommodations '
    'that should be considered for this user category.')
class UserAccessibilityNeeds {
  @ContentType('description', 'Overview of accessibility needs and '
      'accommodations for this user category.')
  String? content;

  /// Accessibility Needs Form.
  @Form([
    Field('visualRequirements', String,
        'Visual Requirements (screen reader, high contrast, magnification)'),
    Field('auditoryRequirements', String,
        'Auditory Requirements (captions, visual alerts)'),
    Field('motorRequirements', String,
        'Motor Requirements (keyboard navigation, voice control)'),
    Field('cognitiveRequirements', String,
        'Cognitive Requirements (simple language, clear navigation)'),
    Field('languageRequirements', String,
        'Language Requirements (multiple languages, reading level)'),
    Field('deviceAccommodations', String,
        'Device Accommodations (large buttons, touch targets)'),
    Field('wcagLevel', String,
        'WCAG Conformance Level Required (A, AA, AAA)'),
    Field('additionalStandards', String,
        'Additional Standards (Section 508, EN 301 549, etc.)'),
  ])
  String? accessibilityForm;
}

/// 4.1.4.n.7. User Journey [PD00-SYO-SYD-USR-nn-JOU].
///
/// Key touchpoints and journey map for this user category's experience.
@SectionId('PD00-SYO-SYD-USR-nn-JOU')
@ContentHelp('Document the user journey - key touchpoints and stages '
    'in this user category\'s interaction with the system.')
class UserJourney {
  @ContentType('description', 'Overview of the user journey and '
      'key experience stages.')
  String? content;

  /// User journey diagram.
  @SectionId('PD00-SYO-SYD-USR-nn-JOU-DIA')
  @ContentType('mermaid-flowchart', 'User journey map showing stages, '
      'touchpoints, and emotional peaks/valleys')
  @ContentHelp('Create a journey map showing the user\'s experience '
      'from first contact through regular use.')
  String? journeyDiagram;

  /// Journey stage entries — contains 0+× JourneyStageEntry.
  @SectionIdPattern('PD00-SYO-SYD-USR-xx-JOU-STG-xx')
  @ContentHelp('Define each stage of the user journey.')
  List<JourneyStageEntry> stages = [];

  /// Key touchpoints.
  @ContentType('description', 'List of key system touchpoints in '
      'the user journey.')
  String? keyTouchpoints;

  /// Pain points in the journey.
  @ContentType('description', 'Known or anticipated pain points in '
      'the user journey that should be addressed.')
  String? painPoints;

  /// Opportunities for delight.
  @ContentType('description', 'Opportunities to exceed user expectations '
      'and create positive experiences.')
  String? opportunitiesForDelight;
}

/// A journey stage entry (form).
class JourneyStageEntry {
  @Form([
    Field('stageName', String, 'Stage Name', required: true),
    Field('stageDescription', String, 'Stage Description'),
    Field('userGoal', String, 'User Goal (what they want to achieve)'),
    Field('userActions', String, 'User Actions (what they do)'),
    Field('systemResponse', String, 'System Response (what system does)'),
    Field('userEmotions', String, 'User Emotions (expected feeling)'),
    Field('touchpoints', String, 'Touchpoints (system interactions)'),
    Field('potentialIssues', String, 'Potential Issues'),
    Field('successMetrics', String, 'Success Metrics'),
  ])
  String? content;
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
