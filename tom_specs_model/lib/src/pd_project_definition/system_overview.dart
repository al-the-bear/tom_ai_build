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
///
/// Container for project goals organized by category. Goals provide measurable
/// objectives that guide project execution and define success. This section
/// supports OKR (Objectives and Key Results) methodology while also
/// accommodating traditional goal structures.
@SectionId('PD00-SYO-GOA')
@ContentHelp('Define clear, measurable goals that the project must achieve. '
    'Organize goals by category (business, technical) and ensure each goal '
    'has specific success metrics and target dates.')
class Goals {
  @ContentType('description', 'Overview of project goals and how they '
      'align with organizational strategy. Summarize the goal hierarchy '
      'and key objectives.')
  String? content;

  /// Goal hierarchy diagram.
  @SectionId('PD00-SYO-GOA-DIA')
  @ContentType('mermaid-flowchart', 'Goal hierarchy and dependency diagram '
      'showing relationships between business and technical goals')
  @ContentHelp('Create a diagram showing goal categories, dependencies, '
      'and alignment to strategic objectives.')
  String? goalHierarchyDiagram;

  /// 4.2.1. Business Goals [PD00-SYO-GOA-BUS].
  BusinessGoals businessGoals = BusinessGoals();

  /// 4.2.2. Technical Goals [PD00-SYO-GOA-TEC].
  TechnicalGoals technicalGoals = TechnicalGoals();

  /// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC].
  SuccessCriteria successCriteria = SuccessCriteria();
}

// ---------------------------------------------------------------------------
// 4.2.1 Business Goals
// ---------------------------------------------------------------------------

/// 4.2.1. Business Goals [PD00-SYO-GOA-BUS].
///
/// Container for business goal definitions. Business goals define what the
/// organization wants to achieve through this project in terms of business
/// outcomes, value delivery, and strategic advancement.
@SectionId('PD00-SYO-GOA-BUS')
@ContentHelp('Define business goals that are specific, measurable, achievable, '
    'relevant, and time-bound (SMART). Each goal should have clear ownership '
    'and success metrics.')
class BusinessGoals {
  @ContentType('description', 'Overview of business goals and their '
      'relationship to organizational strategy. Explain how these goals '
      'support the business case and value proposition.')
  String? content;

  /// Business goals list — contains 1+× Business Goal.
  @SectionIdPattern('PD00-SYO-GOA-BUS-xx')
  @Min(1)
  @ContentHelp('Add one entry per business goal. Goals should be mutually '
      'exclusive and collectively exhaustive for the project scope.')
  List<BusinessGoalEntry> goals = [];
}

/// A business goal entry [PD00-SYO-GOA-BUS-nn].
///
/// Comprehensive business goal definition following SMART criteria with
/// OKR-style key results, ownership, and tracking information.
class BusinessGoalEntry {
  @Form([
    Field('goalId', String, 'Goal ID (unique identifier, e.g., BG-001)',
        required: true),
    Field('goalName', String, 'Goal Name (concise objective statement)',
        required: true),
    Field('description', String,
        'Description (detailed explanation of what this goal means)'),
    Field('goalCategory', String,
        'Goal Category (Strategic, Tactical, Operational)', required: true),
    Field('goalType', String,
        'Goal Type (Revenue, Cost Reduction, Efficiency, Quality, Compliance, '
            'Growth, Customer Satisfaction, Market Position, Innovation)'),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)',
        required: true),
    Field('successMetric', String,
        'Primary Success Metric (what is measured)', required: true),
    Field('currentValue', String,
        'Current Value (baseline measurement before project)'),
    Field('targetValue', String, 'Target Value (desired end state)',
        required: true),
    Field('measurementMethod', String,
        'Measurement Method (how the metric is captured)'),
    Field('measurementFrequency', String,
        'Measurement Frequency (Daily, Weekly, Monthly, Quarterly)'),
    Field('targetDate', String, 'Target Date (when goal should be achieved)',
        required: true),
    Field('owner', String, 'Goal Owner (accountable person or role)',
        required: true),
    Field('stakeholders', String,
        'Contributing Stakeholders (roles involved in achieving this goal)'),
    Field('businessJustification', String,
        'Business Justification (why this goal matters)'),
    Field('strategicAlignment', String,
        'Strategic Alignment (link to corporate strategy or OKR)'),
    Field('impactAreas', String,
        'Impact Areas (departments, processes, or systems affected)'),
    Field('estimatedValue', String,
        'Estimated Value (monetary or quantitative benefit)'),
    Field('riskOfNotAchieving', String,
        'Risk of Not Achieving (consequences of failure)'),
    Field('status', String,
        'Status (Not Started, In Progress, On Track, At Risk, Achieved)'),
  ])
  String? content;

  /// 4.2.1.n.1. Key Results [PD00-SYO-GOA-BUS-nn-KR].
  GoalKeyResults keyResults = GoalKeyResults();

  /// 4.2.1.n.2. Milestones [PD00-SYO-GOA-BUS-nn-MIL].
  GoalMilestones milestones = GoalMilestones();

  /// 4.2.1.n.3. Dependencies [PD00-SYO-GOA-BUS-nn-DEP].
  GoalDependencies dependencies = GoalDependencies();

  /// 4.2.1.n.4. Risks [PD00-SYO-GOA-BUS-nn-RSK].
  GoalRisks risks = GoalRisks();

  /// 4.2.1.n.5. Resources [PD00-SYO-GOA-BUS-nn-RES].
  GoalResources resources = GoalResources();
}

/// 4.2.1.n.1. Key Results [PD00-SYO-GOA-BUS-nn-KR].
///
/// OKR-style key results that indicate progress toward the goal.
/// Key results are specific, measurable outcomes that together constitute
/// achievement of the parent goal.
@SectionId('PD00-SYO-GOA-BUS-nn-KR')
@ContentHelp('Define 3-5 key results that together indicate goal achievement. '
    'Each key result should be independently measurable.')
class GoalKeyResults {
  @ContentType('description', 'Overview of key results and how they '
      'collectively demonstrate goal achievement.')
  String? content;

  /// Key result entries — contains 0+× KeyResultEntry.
  @SectionIdPattern('PD00-SYO-GOA-BUS-xx-KR-xx')
  @ContentHelp('Add 3-5 key results per goal. Each should be specific '
      'and measurable.')
  List<KeyResultEntry> items = [];
}

/// A key result entry (form).
class KeyResultEntry {
  @Form([
    Field('keyResultId', String, 'Key Result ID', required: true),
    Field('keyResult', String, 'Key Result (measurable outcome)', required: true),
    Field('metric', String, 'Metric (what is measured)'),
    Field('baselineValue', String, 'Baseline Value (starting point)'),
    Field('targetValue', String, 'Target Value (desired endpoint)',
        required: true),
    Field('currentValue', String, 'Current Value (latest measurement)'),
    Field('progress', String, 'Progress (percentage toward target)'),
    Field('owner', String, 'Owner (responsible person)'),
    Field('dueDate', String, 'Due Date'),
    Field('status', String, 'Status (Not Started, In Progress, Achieved, Missed)'),
  ])
  String? content;
}

/// 4.2.1.n.2. Milestones [PD00-SYO-GOA-BUS-nn-MIL].
///
/// Key milestones marking progress toward the goal.
@SectionId('PD00-SYO-GOA-BUS-nn-MIL')
@ContentHelp('Define milestones that mark significant progress points.')
class GoalMilestones {
  @ContentType('description', 'Overview of milestone approach and how '
      'milestones relate to goal progress.')
  String? content;

  /// Milestone entries — contains 0+× GoalMilestoneEntry.
  @SectionIdPattern('PD00-SYO-GOA-BUS-xx-MIL-xx')
  List<GoalMilestoneEntry> items = [];
}

/// A goal milestone entry (form).
class GoalMilestoneEntry {
  @Form([
    Field('milestoneId', String, 'Milestone ID', required: true),
    Field('milestoneName', String, 'Milestone Name', required: true),
    Field('description', String, 'Description'),
    Field('targetDate', String, 'Target Date', required: true),
    Field('completionCriteria', String, 'Completion Criteria'),
    Field('deliverables', String, 'Deliverables (outputs of this milestone)'),
    Field('dependencies', String, 'Dependencies (what must be done first)'),
    Field('status', String, 'Status (Planned, In Progress, Completed, Delayed)'),
    Field('actualDate', String, 'Actual Completion Date'),
  ])
  String? content;
}

/// 4.2.1.n.3. Dependencies [PD00-SYO-GOA-BUS-nn-DEP].
///
/// Dependencies that may affect goal achievement.
@SectionId('PD00-SYO-GOA-BUS-nn-DEP')
@ContentHelp('Identify dependencies on other goals, projects, or external factors.')
class GoalDependencies {
  @ContentType('description', 'Overview of dependencies and their impact '
      'on goal achievement timeline.')
  String? content;

  /// Dependency entries — contains 0+× GoalDependencyEntry.
  @SectionIdPattern('PD00-SYO-GOA-BUS-xx-DEP-xx')
  List<GoalDependencyEntry> items = [];
}

/// A goal dependency entry (form).
class GoalDependencyEntry {
  @Form([
    Field('dependencyId', String, 'Dependency ID', required: true),
    Field('dependencyType', String,
        'Dependency Type (Internal Goal, External Project, Resource, '
            'Regulatory, Technical, Organizational)',
        required: true),
    Field('dependencyName', String, 'Dependency Name (what we depend on)',
        required: true),
    Field('description', String, 'Description'),
    Field('owner', String, 'Owner (who controls this dependency)'),
    Field('expectedResolutionDate', String, 'Expected Resolution Date'),
    Field('impact', String, 'Impact (how this affects our goal)'),
    Field('mitigationStrategy', String,
        'Mitigation Strategy (what if dependency is not resolved)'),
    Field('status', String, 'Status (Open, In Progress, Resolved, Blocked)'),
  ])
  String? content;

  @Reference('Related Goal')
  String? relatedGoal;
}

/// 4.2.1.n.4. Risks [PD00-SYO-GOA-BUS-nn-RSK].
///
/// Risks that may prevent or delay goal achievement.
@SectionId('PD00-SYO-GOA-BUS-nn-RSK')
@ContentHelp('Identify risks specific to this goal and mitigation strategies.')
class GoalRisks {
  @ContentType('description', 'Overview of risks affecting this goal '
      'and overall risk posture.')
  String? content;

  /// Risk entries — contains 0+× GoalRiskEntry.
  @SectionIdPattern('PD00-SYO-GOA-BUS-xx-RSK-xx')
  List<GoalRiskEntry> items = [];
}

/// A goal risk entry (form).
class GoalRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID', required: true),
    Field('riskName', String, 'Risk Name', required: true),
    Field('description', String, 'Description'),
    Field('riskCategory', String,
        'Risk Category (Market, Operational, Technical, Resource, '
            'Regulatory, External)'),
    Field('probability', String, 'Probability (Low, Medium, High)'),
    Field('impact', String, 'Impact (Low, Medium, High, Critical)'),
    Field('riskScore', String, 'Risk Score (probability × impact)'),
    Field('triggerConditions', String, 'Trigger Conditions (early warning signs)'),
    Field('mitigationStrategy', String, 'Mitigation Strategy'),
    Field('contingencyPlan', String, 'Contingency Plan (if risk occurs)'),
    Field('owner', String, 'Risk Owner'),
    Field('status', String, 'Status (Identified, Mitigating, Occurred, Closed)'),
  ])
  String? content;
}

/// 4.2.1.n.5. Resources [PD00-SYO-GOA-BUS-nn-RES].
///
/// Resources required to achieve the goal.
@SectionId('PD00-SYO-GOA-BUS-nn-RES')
@ContentHelp('Define resources (people, budget, tools) needed for this goal.')
class GoalResources {
  @ContentType('description', 'Overview of resource requirements and '
      'allocation approach.')
  String? content;

  /// Resource requirement form.
  @Form([
    Field('totalBudget', String, 'Total Budget (estimated or allocated)'),
    Field('fteRequired', String, 'FTE Required (full-time equivalent staff)'),
    Field('keySkills', String, 'Key Skills Required'),
    Field('toolsRequired', String, 'Tools or Systems Required'),
    Field('externalSupport', String,
        'External Support (consultants, vendors)'),
    Field('trainingNeeds', String, 'Training Needs'),
  ])
  String? resourcesForm;

  /// Resource allocation entries — contains 0+× ResourceAllocationEntry.
  @SectionIdPattern('PD00-SYO-GOA-BUS-xx-RES-xx')
  List<ResourceAllocationEntry> items = [];
}

/// A resource allocation entry (form).
class ResourceAllocationEntry {
  @Form([
    Field('resourceType', String,
        'Resource Type (Personnel, Budget, Tool, System, External)',
        required: true),
    Field('resourceName', String, 'Resource Name', required: true),
    Field('quantity', String, 'Quantity or Allocation'),
    Field('duration', String, 'Duration (how long needed)'),
    Field('estimatedCost', String, 'Estimated Cost'),
    Field('availability', String, 'Availability (when available)'),
    Field('source', String, 'Source (internal, external, to be hired)'),
    Field('status', String, 'Status (Requested, Allocated, Confirmed)'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.2.2 Technical Goals
// ---------------------------------------------------------------------------

/// 4.2.2. Technical Goals [PD00-SYO-GOA-TEC].
///
/// Container for technical goal definitions. Technical goals define the
/// non-functional characteristics and technical capabilities the system
/// must achieve, such as performance, scalability, reliability, and security.
@SectionId('PD00-SYO-GOA-TEC')
@ContentHelp('Define technical goals that establish the quality attributes '
    'and capabilities of the system. Each goal should have measurable '
    'criteria and clear verification methods.')
class TechnicalGoals {
  @ContentType('description', 'Overview of technical goals and their '
      'relationship to business requirements. Explain the technical '
      'vision and quality attribute priorities.')
  String? content;

  /// Technical goals list — contains 1+× Technical Goal.
  @SectionIdPattern('PD00-SYO-GOA-TEC-xx')
  @Min(1)
  @ContentHelp('Add one entry per technical goal. Cover key quality '
      'attributes: performance, scalability, reliability, security, '
      'usability, maintainability.')
  List<TechnicalGoalEntry> goals = [];
}

/// A technical goal entry [PD00-SYO-GOA-TEC-nn].
///
/// Comprehensive technical goal definition with quality attributes,
/// architectural impact, and verification approach.
class TechnicalGoalEntry {
  @Form([
    Field('goalId', String, 'Goal ID (unique identifier, e.g., TG-001)',
        required: true),
    Field('goalName', String, 'Goal Name (concise statement)', required: true),
    Field('description', String,
        'Description (detailed explanation of the technical objective)'),
    Field('goalCategory', String,
        'Goal Category (Performance, Scalability, Reliability, Security, '
            'Usability, Accessibility, Maintainability, Portability, '
            'Interoperability, Compliance)',
        required: true),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)',
        required: true),
    Field('successMetric', String,
        'Primary Success Metric (what is measured)', required: true),
    Field('currentValue', String, 'Current/Baseline Value'),
    Field('targetValue', String, 'Target Value', required: true),
    Field('measurementMethod', String,
        'Measurement Method (APM, load testing, security scan, etc.)'),
    Field('measurementTool', String,
        'Measurement Tool (specific tool or platform)'),
    Field('measurementEnvironment', String,
        'Measurement Environment (production, staging, load test)'),
    Field('verificationPoint', String,
        'Verification Point (when/how verified: unit test, integration, '
            'acceptance, production monitoring)'),
    Field('systemArea', String,
        'System Area Affected (frontend, backend, database, network, all)'),
    Field('architectureImpact', String,
        'Architecture Impact (how this affects system design)'),
    Field('owner', String, 'Technical Owner'),
    Field('status', String,
        'Status (Not Started, In Progress, Verified, Failed)'),
  ])
  String? content;

  /// 4.2.2.n.1. Quality Scenarios [PD00-SYO-GOA-TEC-nn-QS].
  QualityScenarios qualityScenarios = QualityScenarios();

  /// 4.2.2.n.2. Test Criteria [PD00-SYO-GOA-TEC-nn-TST].
  TechnicalGoalTestCriteria testCriteria = TechnicalGoalTestCriteria();

  /// 4.2.2.n.3. Dependencies [PD00-SYO-GOA-TEC-nn-DEP].
  TechnicalGoalDependencies dependencies = TechnicalGoalDependencies();

  /// 4.2.2.n.4. Constraints [PD00-SYO-GOA-TEC-nn-CON].
  TechnicalGoalConstraints constraints = TechnicalGoalConstraints();
}

/// 4.2.2.n.1. Quality Scenarios [PD00-SYO-GOA-TEC-nn-QS].
///
/// Quality attribute scenarios that define concrete, testable situations
/// for verifying the technical goal (based on SEI quality attribute workshop).
@SectionId('PD00-SYO-GOA-TEC-nn-QS')
@ContentHelp('Define quality scenarios using: Source → Stimulus → Environment → '
    'Artifact → Response → Response Measure pattern.')
class QualityScenarios {
  @ContentType('description', 'Overview of quality scenarios and how '
      'they verify achievement of the parent technical goal.')
  String? content;

  /// Quality scenario entries — contains 0+× QualityScenarioEntry.
  @SectionIdPattern('PD00-SYO-GOA-TEC-xx-QS-xx')
  List<QualityScenarioEntry> items = [];
}

/// A quality scenario entry (form) - SEI Quality Attribute Workshop format.
class QualityScenarioEntry {
  @Form([
    Field('scenarioId', String, 'Scenario ID', required: true),
    Field('scenarioName', String, 'Scenario Name', required: true),
    Field('source', String, 'Source (who/what generates the stimulus)',
        required: true),
    Field('stimulus', String,
        'Stimulus (event or condition that triggers the scenario)',
        required: true),
    Field('environment', String,
        'Environment (system state when stimulus occurs)'),
    Field('artifact', String, 'Artifact (what part of system is affected)'),
    Field('response', String, 'Response (how the system should respond)',
        required: true),
    Field('responseMeasure', String,
        'Response Measure (quantifiable success criterion)', required: true),
    Field('priority', String, 'Priority (Core, Important, Nice-to-have)'),
    Field('testability', String,
        'Testability (how easy to test: Automated, Manual, Complex)'),
  ])
  String? content;
}

/// 4.2.2.n.2. Test Criteria [PD00-SYO-GOA-TEC-nn-TST].
///
/// Specific test criteria and acceptance thresholds for the technical goal.
@SectionId('PD00-SYO-GOA-TEC-nn-TST')
@ContentHelp('Define specific test criteria that will be used to verify '
    'the technical goal has been achieved.')
class TechnicalGoalTestCriteria {
  @ContentType('description', 'Overview of test approach and acceptance '
      'criteria for this technical goal.')
  String? content;

  /// Test criteria form.
  @Form([
    Field('testType', String,
        'Test Type (Performance, Load, Stress, Security, Penetration, '
            'Accessibility, Usability)'),
    Field('testEnvironment', String, 'Test Environment'),
    Field('testData', String, 'Test Data Requirements'),
    Field('testTools', String, 'Test Tools'),
    Field('passThreshold', String, 'Pass Threshold'),
    Field('failThreshold', String, 'Fail Threshold'),
    Field('testSchedule', String, 'Test Schedule (when tests will run)'),
    Field('retestPolicy', String, 'Retest Policy (when retesting is required)'),
  ])
  String? testCriteriaForm;

  /// Test case entries — contains 0+× TechnicalGoalTestCaseEntry.
  @SectionIdPattern('PD00-SYO-GOA-TEC-xx-TST-xx')
  List<TechnicalGoalTestCaseEntry> items = [];
}

/// A test case entry for technical goal verification (form).
class TechnicalGoalTestCaseEntry {
  @Form([
    Field('testCaseId', String, 'Test Case ID', required: true),
    Field('testCaseName', String, 'Test Case Name', required: true),
    Field('description', String, 'Description'),
    Field('testProcedure', String, 'Test Procedure'),
    Field('expectedResult', String, 'Expected Result'),
    Field('actualResult', String, 'Actual Result'),
    Field('status', String, 'Status (Planned, In Progress, Passed, Failed)'),
  ])
  String? content;
}

/// 4.2.2.n.3. Dependencies [PD00-SYO-GOA-TEC-nn-DEP].
///
/// Technical dependencies affecting goal achievement.
@SectionId('PD00-SYO-GOA-TEC-nn-DEP')
@ContentHelp('Identify technical dependencies: infrastructure, APIs, '
    'third-party services, other system components.')
class TechnicalGoalDependencies {
  @ContentType('description', 'Overview of technical dependencies and '
      'their impact on achieving this goal.')
  String? content;

  /// Dependency entries — contains 0+× TechnicalDependencyEntry.
  @SectionIdPattern('PD00-SYO-GOA-TEC-xx-DEP-xx')
  List<TechnicalDependencyEntry> items = [];
}

/// A technical dependency entry (form).
class TechnicalDependencyEntry {
  @Form([
    Field('dependencyId', String, 'Dependency ID', required: true),
    Field('dependencyName', String, 'Dependency Name', required: true),
    Field('dependencyType', String,
        'Dependency Type (Infrastructure, API, Library, Service, '
            'Hardware, Network, Third-party)'),
    Field('description', String, 'Description'),
    Field('version', String, 'Version (if applicable)'),
    Field('sla', String, 'SLA (if external service)'),
    Field('fallback', String, 'Fallback (what if unavailable)'),
    Field('status', String, 'Status (Available, Pending, At Risk)'),
  ])
  String? content;
}

/// 4.2.2.n.4. Constraints [PD00-SYO-GOA-TEC-nn-CON].
///
/// Technical constraints that may limit or shape how the goal is achieved.
@SectionId('PD00-SYO-GOA-TEC-nn-CON')
@ContentHelp('Document constraints: technology choices, standards, '
    'resource limits, compatibility requirements.')
class TechnicalGoalConstraints {
  @ContentType('description', 'Overview of constraints affecting this '
      'technical goal.')
  String? content;

  /// Constraint entries — contains 0+× TechnicalConstraintEntry.
  @SectionIdPattern('PD00-SYO-GOA-TEC-xx-CON-xx')
  List<TechnicalConstraintEntry> items = [];
}

/// A technical constraint entry (form).
class TechnicalConstraintEntry {
  @Form([
    Field('constraintId', String, 'Constraint ID', required: true),
    Field('constraintName', String, 'Constraint Name', required: true),
    Field('constraintType', String,
        'Constraint Type (Technology, Standard, Resource, '
            'Compatibility, Budget, Timeline, Regulatory)'),
    Field('description', String, 'Description'),
    Field('source', String, 'Source (who/what imposed this constraint)'),
    Field('rationale', String, 'Rationale (why this constraint exists)'),
    Field('impact', String, 'Impact (how this affects our approach)'),
    Field('flexibility', String,
        'Flexibility (Fixed, Negotiable, Preferred)'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.2.3 Success Criteria
// ---------------------------------------------------------------------------

/// 4.2.3. Success Criteria [PD00-SYO-GOA-SUC].
///
/// Overall project success criteria that determine whether the project
/// has achieved its objectives. These criteria will be used during
/// acceptance testing and project closure.
@SectionId('PD00-SYO-GOA-SUC')
@ContentHelp('Define criteria that collectively determine project success. '
    'Each criterion should be objectively verifiable.')
class SuccessCriteria {
  @ContentType('description', 'Overview of success criteria and how they '
      'relate to project objectives. Define the acceptance process and '
      'sign-off requirements.')
  String? content;

  /// Success criteria form.
  @Form([
    Field('acceptanceProcess', String,
        'Acceptance Process (how criteria will be evaluated)'),
    Field('signOffAuthority', String,
        'Sign-off Authority (who approves project success)'),
    Field('evaluationTiming', String,
        'Evaluation Timing (when criteria will be evaluated)'),
    Field('partialSuccessHandling', String,
        'Partial Success Handling (what if some criteria not met)'),
  ])
  String? successCriteriaForm;

  /// Success criterion entries — contains 0+× SuccessCriterionEntry.
  @SectionIdPattern('PD00-SYO-GOA-SUC-xx')
  List<SuccessCriterionEntry> items = [];

  /// Success criteria matrix — overall view.
  @SectionId('PD00-SYO-GOA-SUC-MAT')
  @ContentType('description', 'Success criteria matrix showing all criteria, '
      'their weights, and evaluation status.')
  @ContentHelp('Create a summary matrix of all success criteria.')
  String? successCriteriaMatrix;
}

/// A success criterion entry [PD00-SYO-GOA-SUC-nn] (form).
class SuccessCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID', required: true),
    Field('criterionName', String, 'Criterion Name', required: true),
    Field('description', String, 'Description'),
    Field('category', String,
        'Category (Business, Technical, User, Compliance, Budget, Timeline)'),
    Field('metric', String, 'Metric (what is measured)'),
    Field('targetValue', String, 'Target Value', required: true),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('verificationPoint', String,
        'Verification Point (when verified: go-live, 30 days, 90 days)'),
    Field('weight', String,
        'Weight (importance: Critical, High, Medium, Low)'),
    Field('relatedGoals', String, 'Related Goals (which goals this supports)'),
    Field('status', String, 'Status (Not Evaluated, Met, Not Met, Waived)'),
    Field('evidence', String, 'Evidence (proof that criterion is met)'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.3 Requirements Overview (seeds → RC)
// ---------------------------------------------------------------------------

/// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
///
/// Initial requirements overview organized by category. Each requirement
/// receives a unique ID and will be expanded into the RC (Requirements
/// Catalog) document with full traceability. This section provides the
/// foundation for requirements management throughout the project lifecycle.
/// Based on IEEE 830, ISO 29148, BABOK, and Volere requirements shell.
@SectionId('PD00-SYO-REQ')
@Comment('Seeds → RC')
@ContentHelp('Define initial requirements at a level sufficient for project '
    'scoping and planning. Each requirement should be traceable to business '
    'goals and verifiable through acceptance criteria.')
class RequirementsOverview {
  @ContentType('description', 'Overview of requirements approach, '
      'traceability strategy, and categorization scheme. Explain how '
      'requirements will be managed throughout the project lifecycle.')
  String? content;

  /// Requirements overview form.
  @Form([
    Field('requirementsProcess', String,
        'Requirements Process (how requirements are elicited and managed)'),
    Field('traceabilityApproach', String,
        'Traceability Approach (how requirements are linked to goals, tests, code)'),
    Field('changeControlProcess', String,
        'Change Control Process (how requirement changes are handled)'),
    Field('prioritizationMethod', String,
        'Prioritization Method (MoSCoW, Weighted, etc.)'),
    Field('totalRequirements', String,
        'Total Requirements Expected (estimated count)'),
    Field('mustHaveCount', String, 'Must-Have Requirements (estimated)'),
    Field('shouldHaveCount', String, 'Should-Have Requirements (estimated)'),
    Field('couldHaveCount', String, 'Could-Have Requirements (estimated)'),
  ])
  String? requirementsForm;

  /// Traceability matrix overview.
  @SectionId('PD00-SYO-REQ-TRC')
  @ContentType('description', 'Summary of traceability matrix showing '
      'connections between requirements, goals, use cases, and tests.')
  @ContentHelp('Provide a high-level view of requirement traceability.')
  String? traceabilityMatrix;

  /// 4.3.1. Functional Requirements [PD00-SYO-REQ-FUN].
  FunctionalRequirements functionalRequirements = FunctionalRequirements();

  /// 4.3.2. Technical Requirements [PD00-SYO-REQ-TEC].
  TechnicalRequirements technicalRequirements = TechnicalRequirements();

  /// 4.3.3. Security Requirements [PD00-SYO-REQ-SEC].
  SecurityRequirements securityRequirements = SecurityRequirements();

  /// 4.3.4. Organizational Requirements [PD00-SYO-REQ-ORG].
  OrganizationalRequirements organizationalRequirements =
      OrganizationalRequirements();
}

// ---------------------------------------------------------------------------
// 4.3.1 Functional Requirements
// ---------------------------------------------------------------------------

/// 4.3.1. Functional Requirements [PD00-SYO-REQ-FUN].
///
/// Container for functional requirements. Functional requirements describe
/// what the system must do — its features, behaviors, processing rules,
/// and user interactions. Each requirement is uniquely identified and
/// traceable to business goals and use cases.
@SectionId('PD00-SYO-REQ-FUN')
@ContentHelp('Functional requirements describe system capabilities, behaviors, '
    'and features. Use clear, testable language. Each requirement should '
    'answer: What must the system do? For whom? Under what conditions?')
class FunctionalRequirements {
  @ContentType('description', 'Overview of functional requirements scope, '
      'categorization, and coverage. Explain how functional requirements '
      'are organized and trace to use cases.')
  String? content;

  /// Functional requirements summary form.
  @Form([
    Field('totalFunctionalRequirements', String,
        'Total Functional Requirements'),
    Field('mustHaveFunctional', String, 'Must-Have (count)'),
    Field('shouldHaveFunctional', String, 'Should-Have (count)'),
    Field('couldHaveFunctional', String, 'Could-Have (count)'),
    Field('wontHaveThisTimeFunctional', String, 'Won\'t-Have-This-Time (count)'),
    Field('coverageNote', String, 'Coverage Notes'),
  ])
  String? summaryForm;

  /// Functional requirements list — contains 1+× Functional Requirement.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx')
  @Min(1)
  @ContentHelp('Add one entry per functional requirement. Group related '
      'requirements together. Each requirement should be atomic, testable, '
      'and have clear acceptance criteria.')
  List<FunctionalRequirementEntry> requirements = [];
}

/// A functional requirement entry [PD00-SYO-REQ-FUN-nn].
///
/// Comprehensive functional requirement definition following IEEE 830,
/// ISO 29148, and Volere requirements shell. Includes traceability,
/// acceptance criteria, UI specification, and business rules.
class FunctionalRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-F001)', required: true),
    Field('title', String, 'Title (concise statement)', required: true),
    Field('description', String,
        'Description (The system shall... detailed statement)', required: true),
    Field('requirementType', String,
        'Requirement Type (Feature, User Story, Business Rule, Report, '
            'Integration, Calculation, Workflow, Notification, Search, '
            'Data Entry, Data Display, Data Export, Batch Process)'),
    Field('category', String,
        'Category (functional area grouping)'),
    Field('priority', String,
        'Priority (Must, Should, Could, Won\'t-This-Time)', required: true),
    Field('businessValue', String,
        'Business Value (High, Medium, Low) - benefit to business'),
    Field('effort', String,
        'Estimated Effort (Small, Medium, Large, XLarge)'),
    Field('source', String,
        'Source (who requested: stakeholder name, workshop, document)',
        required: true),
    Field('requestDate', String, 'Request Date'),
    Field('rationale', String,
        'Rationale (why this requirement is needed)'),
    Field('fitCriterion', String,
        'Fit Criterion (measurable condition for acceptance)'),
    Field('customerSatisfaction', String,
        'Customer Satisfaction (1-5 scale if delivered)'),
    Field('customerDissatisfaction', String,
        'Customer Dissatisfaction (1-5 scale if NOT delivered)'),
    Field('assumptions', String,
        'Assumptions (conditions assumed to be true)'),
    Field('constraints', String,
        'Constraints (limitations on implementation)'),
    Field('riskLevel', String,
        'Risk Level (High, Medium, Low) - risk of not meeting'),
    Field('conflictsWith', String,
        'Conflicts With (IDs of conflicting requirements)'),
    Field('status', String,
        'Status (Draft, Proposed, Approved, Implemented, Verified, Deferred)',
        required: true),
    Field('version', String, 'Version'),
    Field('lastModified', String, 'Last Modified Date'),
    Field('modifiedBy', String, 'Modified By'),
  ])
  String? content;

  /// 4.3.1.n.1. Acceptance Criteria [PD00-SYO-REQ-FUN-nn-ACR].
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.1.n.2. Business Rules [PD00-SYO-REQ-FUN-nn-BRU].
  RequirementBusinessRules businessRules = RequirementBusinessRules();

  /// 4.3.1.n.3. Data Requirements [PD00-SYO-REQ-FUN-nn-DAT].
  RequirementDataRequirements dataRequirements = RequirementDataRequirements();

  /// 4.3.1.n.4. UI Specification [PD00-SYO-REQ-FUN-nn-UI].
  RequirementUiSpecification uiSpecification = RequirementUiSpecification();

  /// 4.3.1.n.5. Dependencies [PD00-SYO-REQ-FUN-nn-DEP].
  RequirementDependencies dependencies = RequirementDependencies();

  /// 4.3.1.n.6. Traceability [PD00-SYO-REQ-FUN-nn-TRC].
  RequirementTraceability traceability = RequirementTraceability();

  /// 4.3.1.n.7. Test Cases [PD00-SYO-REQ-FUN-nn-TST].
  RequirementTestCases testCases = RequirementTestCases();
}

/// 4.3.1.n.1. Acceptance Criteria [PD00-SYO-REQ-FUN-nn-ACR].
///
/// Testable conditions that must be met for the requirement to be accepted.
/// Uses Given-When-Then format for clarity.
@SectionId('PD00-SYO-REQ-FUN-nn-ACR')
@ContentHelp('Define clear, testable acceptance criteria. Use Given-When-Then '
    'format: Given [context], When [action], Then [expected result].')
class RequirementAcceptanceCriteria {
  @ContentType('description', 'Overview of acceptance approach and '
      'test coverage expectations.')
  String? content;

  /// Acceptance criterion entries — contains 0+× AcceptanceCriterionEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-ACR-xx')
  @ContentHelp('Add one criterion per testable condition.')
  List<AcceptanceCriterionEntry> criteria = [];
}

/// An acceptance criterion entry (form).
///
/// Uses Given-When-Then format (Gherkin style) for testable criteria.
class AcceptanceCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID', required: true),
    Field('criterionTitle', String, 'Criterion Title', required: true),
    Field('given', String, 'Given (precondition/context)'),
    Field('when', String, 'When (action/trigger)'),
    Field('then', String, 'Then (expected outcome)', required: true),
    Field('and', String, 'And (additional outcomes)'),
    Field('verificationMethod', String,
        'Verification Method (Manual, Automated, Inspection, Demo)'),
    Field('testType', String,
        'Test Type (Unit, Integration, System, Acceptance, UAT)'),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)'),
    Field('status', String, 'Status (Draft, Ready, Passed, Failed, Blocked)'),
  ])
  String? content;
}

/// 4.3.1.n.2. Business Rules [PD00-SYO-REQ-FUN-nn-BRU].
///
/// Business rules that constrain or guide this requirement's behavior.
@SectionId('PD00-SYO-REQ-FUN-nn-BRU')
@ContentHelp('Define business rules that affect this requirement. Business '
    'rules are constraints, calculations, or policies from the business domain.')
class RequirementBusinessRules {
  @ContentType('description', 'Overview of business rules associated '
      'with this requirement.')
  String? content;

  /// Business rule entries — contains 0+× BusinessRuleEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-BRU-xx')
  List<BusinessRuleEntry> rules = [];
}

/// A business rule entry (form).
class BusinessRuleEntry {
  @Form([
    Field('ruleId', String, 'Rule ID', required: true),
    Field('ruleName', String, 'Rule Name', required: true),
    Field('ruleType', String,
        'Rule Type (Constraint, Computation, Derivation, Inference, '
            'Condition, Action, Workflow, Authorization)'),
    Field('ruleStatement', String,
        'Rule Statement (IF/WHEN condition THEN action)', required: true),
    Field('source', String, 'Source (policy, regulation, expert)'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('expirationDate', String, 'Expiration Date'),
    Field('exceptions', String, 'Exceptions (when rule does not apply)'),
    Field('enforcement', String,
        'Enforcement (Hard = system enforces, Soft = warning only)'),
    Field('impact', String, 'Impact (what happens if rule is violated)'),
  ])
  String? content;
}

/// 4.3.1.n.3. Data Requirements [PD00-SYO-REQ-FUN-nn-DAT].
///
/// Data entities, attributes, and relationships needed by this requirement.
@SectionId('PD00-SYO-REQ-FUN-nn-DAT')
@ContentHelp('Define the data entities and attributes this requirement '
    'reads, creates, updates, or deletes.')
class RequirementDataRequirements {
  @ContentType('description', 'Overview of data requirements and '
      'CRUD (Create, Read, Update, Delete) operations.')
  String? content;

  /// Data entity entries — contains 0+× DataEntityReferenceEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-DAT-xx')
  List<DataEntityReferenceEntry> entities = [];
}

/// A reference to a data entity (form).
class DataEntityReferenceEntry {
  @Form([
    Field('entityName', String, 'Entity Name', required: true),
    Field('crudOperations', String,
        'CRUD Operations (Create, Read, Update, Delete)', required: true),
    Field('attributes', String,
        'Attributes (specific fields involved)'),
    Field('volumeEstimate', String,
        'Volume Estimate (records created/accessed)'),
    Field('dataQualityRules', String,
        'Data Quality Rules (validation, completeness)'),
    Field('dataOwner', String, 'Data Owner'),
  ])
  String? content;

  @Reference('Related Data Model Entity')
  String? relatedEntity;
}

/// 4.3.1.n.4. UI Specification [PD00-SYO-REQ-FUN-nn-UI].
///
/// User interface specification for this requirement. Defines screens,
/// forms, and interactions needed to fulfill the requirement.
/// Uses Flutter/Tom UI framework concepts for specification.
@SectionId('PD00-SYO-REQ-FUN-nn-UI')
@ContentHelp('Define the UI elements needed to support this requirement. '
    'Specify screens, forms, fields, actions, and behaviors.')
class RequirementUiSpecification {
  @ContentType('description', 'Overview of UI requirements and '
      'user interaction patterns.')
  String? content;

  /// UI specification form.
  @Form([
    Field('screenName', String, 'Screen/View Name'),
    Field('screenType', String,
        'Screen Type (List, Detail, Form, Dashboard, Dialog, Wizard)'),
    Field('navigationPath', String, 'Navigation Path (how user reaches this)'),
    Field('userRoles', String, 'Allowed User Roles'),
    Field('responsiveBreakpoints', String,
        'Responsive Breakpoints (mobile, tablet, desktop)'),
  ])
  String? uiForm;

  /// UI layout specification (D4rt Flutter code).
  @SectionId('PD00-SYO-REQ-FUN-nn-UI-LAY')
  @ContentType('code-dart', 'Flutter/D4rt code specifying the UI layout '
      'using tom_flutter_ui components.')
  @ContentHelp('Provide D4rt Flutter code for the UI layout, using '
      'tom_flutter_ui components. This can be rendered in documentation.')
  String? layoutCode;

  /// UI mockup diagram (fallback if code not available).
  @SectionId('PD00-SYO-REQ-FUN-nn-UI-MOC')
  @ContentType('description', 'ASCII or text description of UI mockup '
      'if D4rt code is not available.')
  String? mockupDescription;

  /// Screen field entries — contains 0+× ScreenFieldEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-UI-FLD-xx')
  @ContentHelp('Define each field in the UI.')
  List<ScreenFieldEntry> fields = [];

  /// Screen action entries — contains 0+× ScreenActionEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-UI-ACT-xx')
  @ContentHelp('Define actions available in the UI.')
  List<ScreenActionEntry> actions = [];

  /// Screen behavior entries — contains 0+× ScreenBehaviorEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-UI-BEH-xx')
  @ContentHelp('Define dynamic behaviors and interactions.')
  List<ScreenBehaviorEntry> behaviors = [];
}

/// A screen field entry (form).
///
/// Defines a field in the user interface with all its properties.
class ScreenFieldEntry {
  @Form([
    Field('fieldId', String, 'Field ID', required: true),
    Field('fieldLabel', String, 'Field Label (display text)', required: true),
    Field('fieldType', String,
        'Field Type (Text, Number, Date, DateTime, Dropdown, Checkbox, '
            'Radio, Switch, TextArea, RichText, File, Image, Lookup, '
            'Autocomplete, MultiSelect, Slider, Rating, Currency, '
            'Phone, Email, URL, Address, Signature)',
        required: true),
    Field('dataBinding', String, 'Data Binding (entity.attribute)'),
    Field('defaultValue', String, 'Default Value'),
    Field('placeholder', String, 'Placeholder Text'),
    Field('helpText', String, 'Help Text / Tooltip'),
    Field('required', String, 'Required (Yes, No, Conditional)'),
    Field('requiredCondition', String,
        'Required Condition (if conditional)'),
    Field('readOnly', String, 'Read Only (Yes, No, Conditional)'),
    Field('readOnlyCondition', String, 'Read Only Condition'),
    Field('visible', String, 'Visible (Yes, No, Conditional)'),
    Field('visibilityCondition', String, 'Visibility Condition'),
    Field('minLength', String, 'Minimum Length'),
    Field('maxLength', String, 'Maximum Length'),
    Field('minValue', String, 'Minimum Value'),
    Field('maxValue', String, 'Maximum Value'),
    Field('pattern', String, 'Validation Pattern (regex)'),
    Field('validationMessage', String, 'Custom Validation Message'),
    Field('dropdownSource', String, 'Dropdown Source (static, API, entity)'),
    Field('dropdownValues', String, 'Static Dropdown Values'),
    Field('dependsOn', String, 'Depends On (field IDs that affect this)'),
    Field('width', String, 'Width (full, half, third, quarter, custom)'),
    Field('order', String, 'Display Order'),
    Field('grouping', String, 'Field Grouping / Section'),
  ])
  String? content;

  /// Field validation rules — contains 0+× FieldValidationRule.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-UI-FLD-xx-VAL-xx')
  List<FieldValidationRule> validationRules = [];
}

/// A field validation rule (form).
class FieldValidationRule {
  @Form([
    Field('ruleType', String,
        'Rule Type (Required, Pattern, Range, Length, Custom, CrossField)',
        required: true),
    Field('ruleExpression', String, 'Rule Expression / Formula'),
    Field('errorMessage', String, 'Error Message', required: true),
    Field('severity', String, 'Severity (Error, Warning, Info)'),
    Field('triggerEvent', String,
        'Trigger Event (OnBlur, OnChange, OnSubmit)'),
  ])
  String? content;
}

/// A screen action entry (form).
///
/// Defines an action (button, link, menu item) in the user interface.
class ScreenActionEntry {
  @Form([
    Field('actionId', String, 'Action ID', required: true),
    Field('actionLabel', String, 'Action Label (button text)', required: true),
    Field('actionType', String,
        'Action Type (Submit, Cancel, Navigate, API Call, Dialog, '
            'Download, Print, Delete, Duplicate, Export, Import, Refresh, '
            'Save, SaveAndNew, SaveAndClose, Custom)',
        required: true),
    Field('icon', String, 'Icon (Material Icon name or custom)'),
    Field('iconPosition', String, 'Icon Position (Left, Right, Only)'),
    Field('buttonStyle', String,
        'Button Style (Primary, Secondary, Text, Outlined, Danger)'),
    Field('placement', String,
        'Placement (Toolbar, Inline, Footer, ContextMenu, FAB)'),
    Field('keyboardShortcut', String, 'Keyboard Shortcut'),
    Field('enabled', String, 'Enabled (Yes, No, Conditional)'),
    Field('enabledCondition', String, 'Enabled Condition'),
    Field('visible', String, 'Visible (Yes, No, Conditional)'),
    Field('visibilityCondition', String, 'Visibility Condition'),
    Field('confirmationRequired', String, 'Confirmation Required (Yes, No)'),
    Field('confirmationMessage', String, 'Confirmation Message'),
    Field('successMessage', String, 'Success Message'),
    Field('errorMessage', String, 'Error Message'),
    Field('navigationTarget', String, 'Navigation Target (if Navigate)'),
    Field('apiEndpoint', String, 'API Endpoint (if API Call)'),
    Field('requiredPermission', String, 'Required Permission'),
    Field('auditLogging', String, 'Audit Logging (Yes, No)'),
  ])
  String? content;

  /// Action parameters — contains 0+× ActionParameterEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-UI-ACT-xx-PAR-xx')
  List<ActionParameterEntry> parameters = [];
}

/// An action parameter entry (form).
class ActionParameterEntry {
  @Form([
    Field('parameterName', String, 'Parameter Name', required: true),
    Field('sourceType', String,
        'Source Type (Field, Constant, Context, User)', required: true),
    Field('sourceValue', String, 'Source Value / Field ID'),
    Field('required', String, 'Required (Yes, No)'),
  ])
  String? content;
}

/// A screen behavior entry (form).
///
/// Defines dynamic behavior such as conditional visibility, calculations,
/// cascading selects, and other interactions.
class ScreenBehaviorEntry {
  @Form([
    Field('behaviorId', String, 'Behavior ID', required: true),
    Field('behaviorName', String, 'Behavior Name', required: true),
    Field('behaviorType', String,
        'Behavior Type (ConditionalVisibility, ConditionalRequired, '
            'Calculation, CascadingSelect, AutoPopulate, CrossFieldValidation, '
            'DynamicDefault, FieldFormatting, LiveSearch, InlineEdit)',
        required: true),
    Field('triggerEvent', String,
        'Trigger Event (OnLoad, OnChange, OnBlur, OnFocus, OnClick, '
            'OnSubmit, OnFieldChange)'),
    Field('triggerField', String, 'Trigger Field (if field-specific)'),
    Field('condition', String, 'Condition (when behavior applies)'),
    Field('affectedFields', String, 'Affected Fields (field IDs)'),
    Field('action', String,
        'Action (Show, Hide, Enable, Disable, Calculate, Populate, Validate)'),
    Field('formula', String, 'Formula / Expression (for calculations)'),
    Field('description', String, 'Behavior Description'),
  ])
  String? content;
}

/// 4.3.1.n.5. Dependencies [PD00-SYO-REQ-FUN-nn-DEP].
///
/// Dependencies this requirement has on other requirements.
@SectionId('PD00-SYO-REQ-FUN-nn-DEP')
@ContentHelp('Identify requirements that must be implemented before or '
    'alongside this requirement.')
class RequirementDependencies {
  @ContentType('description', 'Overview of requirement dependencies '
      'and implementation order.')
  String? content;

  /// Dependency entries — contains 0+× RequirementDependencyEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-DEP-xx')
  List<RequirementDependencyEntry> items = [];
}

/// A requirement dependency entry (form).
class RequirementDependencyEntry {
  @Form([
    Field('dependencyType', String,
        'Dependency Type (Prerequisite, Bidirectional, Parent-Child, '
            'Conflict, Refinement)', required: true),
    Field('description', String, 'Description'),
    Field('impact', String, 'Impact (what happens if dependency not met)'),
  ])
  String? content;

  @Reference('Related Requirement')
  String? relatedRequirement;
}

/// 4.3.1.n.6. Traceability [PD00-SYO-REQ-FUN-nn-TRC].
///
/// Traceability links to goals, use cases, processes, and other artifacts.
@SectionId('PD00-SYO-REQ-FUN-nn-TRC')
@ContentHelp('Document traceability links to maintain visibility of '
    'requirements throughout the project lifecycle.')
class RequirementTraceability {
  @ContentType('description', 'Overview of traceability links for '
      'this requirement.')
  String? content;

  /// Traceability links form.
  @Form([
    Field('relatedGoals', String, 'Related Business Goals (IDs)'),
    Field('relatedUseCases', String, 'Related Use Cases (IDs)'),
    Field('relatedProcesses', String, 'Related Business Processes (IDs)'),
    Field('relatedUserStories', String, 'Related User Stories (if Agile)'),
    Field('relatedScreens', String, 'Related UI Screens/Views'),
    Field('relatedDataEntities', String, 'Related Data Entities'),
    Field('relatedTestCases', String, 'Related Test Cases (IDs)'),
    Field('relatedDocuments', String, 'Related Documents or Artifacts'),
    Field('implementationComponent', String,
        'Implementation Component (module, service)'),
    Field('implementationStatus', String,
        'Implementation Status (Not Started, In Progress, Done)'),
    Field('deploymentVersion', String, 'Deployment Version (first release)'),
  ])
  String? traceabilityForm;
}

/// 4.3.1.n.7. Test Cases [PD00-SYO-REQ-FUN-nn-TST].
///
/// Test cases that verify this requirement is correctly implemented.
@SectionId('PD00-SYO-REQ-FUN-nn-TST')
@ContentHelp('Define test cases that verify requirement implementation.')
class RequirementTestCases {
  @ContentType('description', 'Overview of test coverage for this requirement.')
  String? content;

  /// Test case entries — contains 0+× RequirementTestCaseEntry.
  @SectionIdPattern('PD00-SYO-REQ-FUN-xx-TST-xx')
  List<RequirementTestCaseEntry> testCases = [];
}

/// A test case entry for requirement verification (form).
class RequirementTestCaseEntry {
  @Form([
    Field('testCaseId', String, 'Test Case ID', required: true),
    Field('testCaseName', String, 'Test Case Name', required: true),
    Field('testType', String,
        'Test Type (Unit, Integration, System, Acceptance, UAT, Regression)'),
    Field('testCategory', String,
        'Test Category (Positive, Negative, Boundary, Error, Performance)'),
    Field('preconditions', String, 'Preconditions'),
    Field('testSteps', String, 'Test Steps'),
    Field('testData', String, 'Test Data'),
    Field('expectedResult', String, 'Expected Result', required: true),
    Field('automationStatus', String,
        'Automation Status (Automated, Manual, To Be Automated)'),
    Field('automationScript', String, 'Automation Script Reference'),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)'),
  ])
  String? content;

  @Reference('Related Acceptance Criterion')
  String? relatedCriterion;
}

// ---------------------------------------------------------------------------
// 4.3.2 Technical Requirements
// ---------------------------------------------------------------------------

/// 4.3.2. Technical Requirements [PD00-SYO-REQ-TEC].
///
/// Container for technical requirements. Technical requirements describe
/// constraints on how the system is built — platform, performance,
/// scalability, reliability, and standards compliance. These requirements
/// often drive architectural decisions.
@SectionId('PD00-SYO-REQ-TEC')
@ContentHelp('Technical requirements describe non-functional aspects and '
    'constraints. Each should be measurable and testable. Common categories: '
    'Performance, Scalability, Availability, Security, Maintainability.')
class TechnicalRequirements {
  @ContentType('description', 'Overview of technical requirements scope, '
      'categories, and quality attribute priorities.')
  String? content;

  /// Technical requirements summary form.
  @Form([
    Field('totalTechnicalRequirements', String, 'Total Technical Requirements'),
    Field('criticalCount', String, 'Critical (count)'),
    Field('highCount', String, 'High (count)'),
    Field('mediumCount', String, 'Medium (count)'),
    Field('lowCount', String, 'Low (count)'),
    Field('architectureDrivers', String,
        'Architecture Drivers (top constraints shaping design)'),
  ])
  String? summaryForm;

  /// Technical requirements list — contains 0+× Technical Requirement.
  @SectionIdPattern('PD00-SYO-REQ-TEC-xx')
  @ContentHelp('Add one entry per technical requirement.')
  List<TechnicalRequirementEntry> requirements = [];
}

/// A technical requirement entry [PD00-SYO-REQ-TEC-nn].
///
/// Comprehensive technical requirement definition following ISO 25010
/// quality characteristics and architecture decision records.
class TechnicalRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-T001)', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String,
        'Description (The system shall... detailed statement)', required: true),
    Field('category', String,
        'Category (Performance, Scalability, Availability, Reliability, '
            'Security, Usability, Accessibility, Maintainability, Portability, '
            'Interoperability, Compliance, Capacity, Recoverability)',
        required: true),
    Field('subcategory', String, 'Subcategory (specific aspect within category)'),
    Field('priority', String,
        'Priority (Critical, High, Medium, Low)', required: true),
    Field('source', String, 'Source (who requested)', required: true),
    Field('rationale', String, 'Rationale'),
    Field('metric', String, 'Metric (what is measured)'),
    Field('currentValue', String, 'Current Value (baseline)'),
    Field('targetValue', String, 'Target Value', required: true),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('measurementEnvironment', String,
        'Measurement Environment (production, staging, load test)'),
    Field('measurementFrequency', String, 'Measurement Frequency'),
    Field('verificationApproach', String,
        'Verification Approach (how verified: test, inspection, analysis)'),
    Field('verificationTool', String, 'Verification Tool'),
    Field('verificationTiming', String,
        'Verification Timing (unit test, integration, acceptance, production)'),
    Field('architectureImpact', String,
        'Architecture Impact (how this affects system design)'),
    Field('estimatedEffort', String, 'Estimated Implementation Effort'),
    Field('riskIfNotMet', String, 'Risk If Not Met'),
    Field('assumptions', String, 'Assumptions'),
    Field('constraints', String, 'Constraints'),
    Field('status', String,
        'Status (Draft, Proposed, Approved, Verified, Deferred)', required: true),
  ])
  String? content;

  /// 4.3.2.n.1. Acceptance Criteria [PD00-SYO-REQ-TEC-nn-ACR].
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.2.n.2. Dependencies [PD00-SYO-REQ-TEC-nn-DEP].
  RequirementDependencies dependencies = RequirementDependencies();

  /// 4.3.2.n.3. Traceability [PD00-SYO-REQ-TEC-nn-TRC].
  RequirementTraceability traceability = RequirementTraceability();
}

// ---------------------------------------------------------------------------
// 4.3.3 Security Requirements
// ---------------------------------------------------------------------------

/// 4.3.3. Security Requirements [PD00-SYO-REQ-SEC].
///
/// Container for security requirements. Security requirements describe
/// information protection, access control, authentication, authorization,
/// audit, and compliance needs. Based on OWASP, ISO 27001, and common
/// security frameworks.
@SectionId('PD00-SYO-REQ-SEC')
@ContentHelp('Security requirements protect confidentiality, integrity, '
    'and availability of information. Include authentication, authorization, '
    'data protection, and compliance requirements.')
class SecurityRequirements {
  @ContentType('description', 'Overview of security requirements scope, '
      'threat landscape, and compliance context.')
  String? content;

  /// Security requirements summary form.
  @Form([
    Field('totalSecurityRequirements', String, 'Total Security Requirements'),
    Field('criticalCount', String, 'Critical (count)'),
    Field('highCount', String, 'High (count)'),
    Field('mediumCount', String, 'Medium (count)'),
    Field('securityFramework', String,
        'Security Framework (OWASP, NIST, ISO 27001, CIS, etc.)'),
    Field('complianceRequirements', String,
        'Compliance Requirements (GDPR, HIPAA, PCI-DSS, SOX, etc.)'),
    Field('threatCategories', String,
        'Threat Categories Addressed (Injection, XSS, CSRF, etc.)'),
  ])
  String? summaryForm;

  /// Security requirements list — contains 0+× Security Requirement.
  @SectionIdPattern('PD00-SYO-REQ-SEC-xx')
  @ContentHelp('Add one entry per security requirement.')
  List<SecurityRequirementEntry> requirements = [];
}

/// A security requirement entry [PD00-SYO-REQ-SEC-nn].
///
/// Comprehensive security requirement definition following OWASP ASVS,
/// ISO 27001, and security best practices.
class SecurityRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-S001)', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String,
        'Description (The system shall... detailed statement)', required: true),
    Field('category', String,
        'Category (Authentication, Authorization, Data Protection, '
            'Encryption, Audit Logging, Input Validation, Session Management, '
            'Error Handling, Communication Security, Configuration, '
            'Cryptography, Data Retention, Privacy)',
        required: true),
    Field('subcategory', String, 'Subcategory'),
    Field('priority', String,
        'Priority (Critical, High, Medium, Low)', required: true),
    Field('source', String, 'Source', required: true),
    Field('rationale', String, 'Rationale'),
    Field('threatMitigated', String,
        'Threat Mitigated (what attack is prevented)'),
    Field('owaspCategory', String,
        'OWASP Category (if applicable, e.g., A01:2021 Broken Access Control)'),
    Field('cisControl', String, 'CIS Control (if applicable)'),
    Field('nistControl', String, 'NIST Control (if applicable)'),
    Field('iso27001Control', String, 'ISO 27001 Control (if applicable)'),
    Field('complianceReference', String,
        'Compliance Reference (GDPR Article, PCI-DSS requirement, etc.)'),
    Field('dataClassification', String,
        'Data Classification Affected (Public, Internal, Confidential, '
            'Restricted, PII, PHI)'),
    Field('implementationApproach', String, 'Implementation Approach'),
    Field('verificationMethod', String,
        'Verification Method (Penetration test, Code review, Security scan)'),
    Field('verificationFrequency', String,
        'Verification Frequency (Continuous, Release, Quarterly, Annual)'),
    Field('residualRisk', String, 'Residual Risk (after mitigation)'),
    Field('riskOwner', String, 'Risk Owner'),
    Field('status', String,
        'Status (Draft, Proposed, Approved, Implemented, Verified)',
        required: true),
  ])
  String? content;

  /// 4.3.3.n.1. Acceptance Criteria [PD00-SYO-REQ-SEC-nn-ACR].
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.3.n.2. Security Controls [PD00-SYO-REQ-SEC-nn-CTL].
  SecurityControls controls = SecurityControls();

  /// 4.3.3.n.3. Dependencies [PD00-SYO-REQ-SEC-nn-DEP].
  RequirementDependencies dependencies = RequirementDependencies();

  /// 4.3.3.n.4. Traceability [PD00-SYO-REQ-SEC-nn-TRC].
  RequirementTraceability traceability = RequirementTraceability();
}

/// 4.3.3.n.2. Security Controls [PD00-SYO-REQ-SEC-nn-CTL].
///
/// Security controls that implement or support this requirement.
@SectionId('PD00-SYO-REQ-SEC-nn-CTL')
@ContentHelp('Define security controls that implement this requirement.')
class SecurityControls {
  @ContentType('description', 'Overview of security controls for this '
      'requirement.')
  String? content;

  /// Security control entries — contains 0+× SecurityControlEntry.
  @SectionIdPattern('PD00-SYO-REQ-SEC-xx-CTL-xx')
  List<SecurityControlEntry> controls = [];
}

/// A security control entry (form).
class SecurityControlEntry {
  @Form([
    Field('controlId', String, 'Control ID', required: true),
    Field('controlName', String, 'Control Name', required: true),
    Field('controlType', String,
        'Control Type (Preventive, Detective, Corrective, Deterrent, '
            'Compensating)',
        required: true),
    Field('implementationType', String,
        'Implementation Type (Technical, Administrative, Physical)'),
    Field('description', String, 'Description'),
    Field('implementationDetails', String, 'Implementation Details'),
    Field('effectiveDate', String, 'Effective Date'),
    Field('testFrequency', String, 'Test Frequency'),
    Field('lastTestDate', String, 'Last Test Date'),
    Field('testResult', String, 'Last Test Result'),
    Field('status', String, 'Status (Planned, Implemented, Active, Retired)'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.3.4 Organizational Requirements
// ---------------------------------------------------------------------------

/// 4.3.4. Organizational Requirements [PD00-SYO-REQ-ORG].
///
/// Container for organizational requirements. These describe needed changes
/// to organization, processes, training, or support that must be fulfilled
/// for the system to succeed. Based on change management and organizational
/// readiness assessment practices.
@SectionId('PD00-SYO-REQ-ORG')
@ContentHelp('Organizational requirements describe non-technical changes '
    'needed for system success: training, process changes, role changes, '
    'support structures, and communication.')
class OrganizationalRequirements {
  @ContentType('description', 'Overview of organizational requirements scope '
      'and change management context.')
  String? content;

  /// Organizational requirements summary form.
  @Form([
    Field('totalOrgRequirements', String, 'Total Organizational Requirements'),
    Field('trainingRequirements', String, 'Training Requirements (count)'),
    Field('processChangeRequirements', String, 'Process Change (count)'),
    Field('roleChangeRequirements', String, 'Role Change (count)'),
    Field('supportRequirements', String, 'Support Requirements (count)'),
    Field('communicationRequirements', String, 'Communication (count)'),
    Field('changeReadinessScore', String,
        'Organizational Change Readiness Score'),
  ])
  String? summaryForm;

  /// Organizational requirements list — contains 0+× Organizational Requirement.
  @SectionIdPattern('PD00-SYO-REQ-ORG-xx')
  @ContentHelp('Add one entry per organizational requirement.')
  List<OrganizationalRequirementEntry> requirements = [];
}

/// An organizational requirement entry [PD00-SYO-REQ-ORG-nn].
///
/// Comprehensive organizational requirement definition following change
/// management and organizational development best practices.
class OrganizationalRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-O001)', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String,
        'Description (detailed statement)', required: true),
    Field('category', String,
        'Category (Training, Process Change, Role Change, Support, '
            'Communication, Policy, Governance, Culture, Staffing)',
        required: true),
    Field('subcategory', String, 'Subcategory'),
    Field('priority', String,
        'Priority (Must, Should, Could, Won\'t-This-Time)', required: true),
    Field('source', String, 'Source', required: true),
    Field('rationale', String, 'Rationale'),
    Field('impactedGroups', String,
        'Impacted Groups (departments, roles, user categories)'),
    Field('impactedUserCount', String, 'Estimated Impacted Users'),
    Field('changeType', String,
        'Change Type (Behavioral, Procedural, Structural, Cultural)'),
    Field('changeComplexity', String,
        'Change Complexity (Low, Medium, High)'),
    Field('resistance', String,
        'Expected Resistance (Low, Medium, High)'),
    Field('timeline', String, 'Timeline (when change must occur)'),
    Field('dependencies', String, 'Dependencies (other changes needed first)'),
    Field('owner', String, 'Change Owner'),
    Field('sponsor', String, 'Executive Sponsor'),
    Field('successCriteria', String, 'Success Criteria'),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('status', String,
        'Status (Draft, Proposed, Approved, In Progress, Completed)',
        required: true),
  ])
  String? content;

  /// 4.3.4.n.1. Acceptance Criteria [PD00-SYO-REQ-ORG-nn-ACR].
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.4.n.2. Implementation Plan [PD00-SYO-REQ-ORG-nn-IMP].
  OrgRequirementImplementationPlan implementationPlan =
      OrgRequirementImplementationPlan();

  /// 4.3.4.n.3. Dependencies [PD00-SYO-REQ-ORG-nn-DEP].
  RequirementDependencies dependencies = RequirementDependencies();
}

/// 4.3.4.n.2. Implementation Plan [PD00-SYO-REQ-ORG-nn-IMP].
///
/// Implementation plan for this organizational requirement.
@SectionId('PD00-SYO-REQ-ORG-nn-IMP')
@ContentHelp('Define the implementation approach for this organizational '
    'change requirement.')
class OrgRequirementImplementationPlan {
  @ContentType('description', 'Overview of implementation approach.')
  String? content;

  /// Implementation plan form.
  @Form([
    Field('approach', String,
        'Approach (Big Bang, Phased, Pilot, Parallel)'),
    Field('phases', String, 'Phases (if phased rollout)'),
    Field('pilotGroup', String, 'Pilot Group (if pilot approach)'),
    Field('trainingApproach', String, 'Training Approach'),
    Field('communicationPlan', String, 'Communication Plan'),
    Field('supportPlan', String, 'Support Plan'),
    Field('rollbackPlan', String, 'Rollback Plan'),
    Field('resourcesNeeded', String, 'Resources Needed'),
    Field('budget', String, 'Budget'),
    Field('timeline', String, 'Timeline'),
  ])
  String? planForm;

  /// Implementation activities — contains 0+× OrgImplementationActivity.
  @SectionIdPattern('PD00-SYO-REQ-ORG-xx-IMP-xx')
  List<OrgImplementationActivity> activities = [];
}

/// An organizational implementation activity (form).
class OrgImplementationActivity {
  @Form([
    Field('activityId', String, 'Activity ID', required: true),
    Field('activityName', String, 'Activity Name', required: true),
    Field('description', String, 'Description'),
    Field('owner', String, 'Owner'),
    Field('startDate', String, 'Start Date'),
    Field('endDate', String, 'End Date'),
    Field('deliverable', String, 'Deliverable'),
    Field('status', String, 'Status (Planned, In Progress, Completed, Delayed)'),
  ])
  String? content;
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
