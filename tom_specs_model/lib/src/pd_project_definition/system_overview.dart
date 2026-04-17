/// Section 4: System Overview [PD00-SYO].
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment. This chapter provides the foundational
/// understanding of what the system is, why it's being built, and the
/// context in which it will operate.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// 4. System Overview [PD00-SYO].
///
/// High-level overview of the system to be built: its purpose, goals,
/// scope boundaries, and the environment it operates in. This section
/// establishes the foundation for all subsequent specification work.
@SectionId('PD00-SYO')
class SystemOverview {
  @ContentHelp('''
Executive summary of the system being specified.
Provide a high-level overview that allows readers to quickly understand:
- What system is being built
- Why it is being built (business drivers)
- Who will use it
- What are the major scope boundaries
- What are the key risks and assumptions

This section should be readable by executives and stakeholders who need
a quick understanding without reading the full specification.
''')
  String? content;

  /// System overview summary statistics.
  SystemOverviewSummary summary = SystemOverviewSummary();

  /// System context diagram showing major system boundaries.
  @ContentType('mermaid', 'High-level context diagram showing the system, '
      'its users, and external system interfaces')
  String? systemContextDiagram;

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

/// System overview summary for quick reference.
class SystemOverviewSummary {
  @Form([
    // Identity
    Field('systemName', String, 'System Name',
        hint: 'Official name of the system being built', required: true),
    Field('systemAcronym', String, 'System Acronym',
        hint: 'Short acronym if used'),
    Field('systemVersion', String, 'System Version',
        hint: 'Target version this specification covers'),
    Field('projectCodeName', String, 'Project Code Name',
        hint: 'Internal project code name if different'),

    // Classification
    Field('systemType', String, 'System Type',
        hint: 'Web Application / Mobile App / API / Desktop / Embedded / Hybrid'),
    Field('businessDomain', String, 'Business Domain',
        hint: 'Primary business domain — Finance / Healthcare / Retail / etc.'),
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'Cloud / On-premise / Hybrid / Edge'),

    // Scale
    Field('estimatedUserCount', int, 'Estimated User Count',
        hint: 'Expected number of users at steady state'),
    Field('userCategoryCount', int, 'User Category Count',
        hint: 'Number of distinct user categories'),
    Field('externalInterfaceCount', int, 'External Interface Count',
        hint: 'Number of external system integrations'),
    Field('functionalRequirementCount', int, 'Functional Requirement Count',
        hint: 'Number of functional requirements identified'),
    Field('nonFunctionalRequirementCount', int, 'Non-Functional Requirement Count',
        hint: 'Number of non-functional requirements identified'),

    // Status
    Field('specificationVersion', String, 'Specification Version',
        hint: 'Version of this specification document'),
    Field('specificationDate', String, 'Specification Date',
        hint: 'Date of this specification'),
    Field('specificationStatus', String, 'Specification Status',
        hint: 'Draft / Review / Approved / Superseded'),
    Field('targetGoLiveDate', String, 'Target Go-Live Date',
        hint: 'Planned production deployment date'),

    // Complexity Indicators
    Field('overallComplexity', String, 'Overall Complexity',
        hint: 'Low / Medium / High / Very High — based on scope and integrations'),
    Field('keyRisks', String, 'Key Risks Summary',
        hint: 'Brief list of top 3 risks'),
    Field('keyAssumptions', String, 'Key Assumptions Summary',
        hint: 'Brief list of critical assumptions'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1 System Description
// ---------------------------------------------------------------------------

/// 4.1. System Description [PD00-SYO-SYD].
///
/// Concise description of the system to be created, its primary purpose,
/// and the business domain it addresses. This section provides the
/// foundation for understanding what the system does and who uses it.
@SectionId('PD00-SYO-SYD')
class SystemDescription {
  @ContentHelp('''
Concise description of the system to be created.
Describe the primary purpose of the system and the business domain it
addresses. Focus on WHAT the system does, not HOW it does it.
This section should establish a shared vocabulary and mental model
that all stakeholders can refer to.
''')
  String? content;

  /// System description summary.
  SystemDescriptionSummary descriptionSummary = SystemDescriptionSummary();

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

/// Summary statistics and classification for system description.
///
/// Provides structured classification of the system including its primary
/// function, domain classification, technology stack, and key characteristics.
@Form([
  Field('primaryFunction', String, 'Primary function the system performs',
      hint: 'e.g., Enterprise resource planning and management'),
  Field('systemCategory', String, 'High-level category classification',
      hint: 'Business Application, Consumer Application, Infrastructure, '
          'Embedded, Platform/Framework, Data Processing, Integration, '
          'Monitoring/Management, AI/ML, IoT, Development Tool, Security'),
  Field('domainClassification', String, 'Primary business or technical domain',
      hint: 'e.g., Healthcare, Finance, Manufacturing, E-commerce'),
  Field('deploymentModel', String, 'Primary deployment approach',
      hint: 'Cloud-native SaaS, Cloud-hosted PaaS, Hybrid Cloud, '
          'On-premises, Edge/Distributed, Mobile-first, Desktop, Embedded'),
  Field('architectureStyle', String, 'Primary architectural pattern',
      hint: 'Microservices, Monolithic, Serverless, Event-driven, Layered, '
          'Modular Monolith, Service-oriented, Peer-to-peer, Client-server'),
  Field('primaryTechnologyStack', String, 'Main technologies and frameworks',
      hint: 'e.g., Flutter/Dart, Firebase, PostgreSQL'),
  Field('interfaceTypes', List, 'Types of user and system interfaces',
      hint: 'Web UI, Mobile App, Desktop App, REST API, GraphQL API, '
          'gRPC API, CLI, Voice Interface, Chat/Bot Interface, Hardware'),
  Field('dataCharacteristics', String, 'Key data handling characteristics',
      hint: 'e.g., Real-time processing, batch analytics, ACID transactions'),
  Field('securityClassification', String, 'Overall security posture requirement',
      hint: 'Public/Open, Internal Use, Confidential, Highly Confidential, '
          'Regulated (HIPAA/GDPR/SOX), Government/Classified'),
  Field('availabilityRequirement', String, 'Target availability level',
      hint: '99.999% (Five 9s), 99.99% (Four 9s), 99.9% (Three 9s), '
          '99%, Business Hours Only, Best Effort'),
  Field('scalabilityModel', String, 'How the system scales',
      hint: 'Horizontal Auto-scaling, Vertical Scaling, Manual Scaling, '
          'Fixed Capacity, Edge Distribution, Federation'),
  Field('expectedUserLoad', String, 'Anticipated concurrent user volume',
      hint: 'Single User, Team (<100), Enterprise (100-1000), '
          'Large Enterprise (1000-10000), Consumer (10000+)'),
  Field('keyDifferentiators', String, 'What makes this system unique',
      hint: 'e.g., AI-powered recommendations, real-time collaboration'),
  Field('criticalCapabilities', String, 'Most important system capabilities',
      hint: 'e.g., Multi-tenant data isolation, offline-first sync'),
])
class SystemDescriptionSummary {
  /// Summary content for system description classification.
  @ContentType('aggregation', 'Structured classification and characteristics '
      'of the system based on category, domain, architecture, and '
      'deployment model.')
  String? content;
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
///
/// Describes how different user categories interact with the system including
/// access channels, interaction patterns, access levels, and session management.
/// Based on user experience best practices and multi-channel interaction design.
@SectionId('PD00-SYO-SYD-USI')
@ContentHelp('Describe how different user categories interact with the system: '
    'access channels (web, mobile, API, CLI), interaction patterns (real-time, '
    'batch, notification-driven), access levels, session management, and '
    'multi-channel considerations.')
class UserInteractionModel {
  @ContentType('description', 'High-level overview of user interaction model '
      'explaining how users access and interact with the system across '
      'different channels and contexts.')
  String? content;

  /// Interaction model summary.
  UserInteractionModelSummary summary = UserInteractionModelSummary();

  /// 4.1.5.1. Access Channels [PD00-SYO-SYD-USI-CHA].
  AccessChannels accessChannels = AccessChannels();

  /// 4.1.5.2. Interaction Patterns [PD00-SYO-SYD-USI-PAT].
  InteractionPatterns interactionPatterns = InteractionPatterns();

  /// 4.1.5.3. Access Levels [PD00-SYO-SYD-USI-ACC].
  AccessLevels accessLevels = AccessLevels();

  /// 4.1.5.4. Session Model [PD00-SYO-SYD-USI-SES].
  SessionModel sessionModel = SessionModel();

  /// 4.1.5.5. Notification Model [PD00-SYO-SYD-USI-NOT].
  NotificationModel notificationModel = NotificationModel();

  /// 4.1.5.6. Multi-Channel Experience [PD00-SYO-SYD-USI-MUL].
  MultiChannelExperience multiChannelExperience = MultiChannelExperience();
}

/// Summary statistics for user interaction model.
@Form([
  Field('primaryAccessChannel', String, 'Primary Access Channel',
      hint: 'Web, Mobile App, Desktop App, API, CLI'),
  Field('channelCount', int, 'Number of Access Channels'),
  Field('interactionPatternCount', int, 'Number of Interaction Patterns'),
  Field('accessLevelCount', int, 'Number of Access Levels'),
  Field('multiChannelSupport', String, 'Multi-Channel Support',
      hint: 'None, Limited, Full'),
  Field('offlineCapability', String, 'Offline Capability',
      hint: 'None, Read-only, Full'),
  Field('sessionManagement', String, 'Session Management Approach',
      hint: 'Server-side, Client-side, Hybrid, Stateless'),
  Field('notificationChannels', String, 'Notification Channels',
      hint: 'e.g., Email, SMS, Push, In-app'),
])
class UserInteractionModelSummary {
  /// Summary content for interaction model.
  @ContentType('aggregation', 'Key metrics and classifications for '
      'user interaction model.')
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.1 Access Channels
// ---------------------------------------------------------------------------

/// 4.1.5.1. Access Channels [PD00-SYO-SYD-USI-CHA].
///
/// Defines all channels through which users can access the system including
/// web, mobile, desktop applications, APIs, and other interfaces.
@SectionId('PD00-SYO-SYD-USI-CHA')
@ContentHelp('Define all channels through which users can access the system. '
    'For each channel, specify target users, features available, and '
    'any channel-specific constraints.')
class AccessChannels {
  @ContentType('description', 'Overview of access channels and how they '
      'relate to different user categories and use cases.')
  String? content;

  /// Channel architecture diagram.
  @SectionId('PD00-SYO-SYD-USI-CHA-DIA')
  @ContentType('mermaid-flowchart', 'Diagram showing access channels, '
      'their relationships, and user flows')
  @ContentHelp('Create a diagram showing how different channels connect '
      'to the system and serve different user categories.')
  String? channelDiagram;

  /// Channel entries — contains 1+× InteractionChannelEntry.
  @SectionIdPattern('PD00-SYO-SYD-USI-CHA-xx')
  @Min(1)
  @ContentHelp('Add one entry per access channel. Include both primary '
      'and secondary channels.')
  List<InteractionChannelEntry> channels = [];
}

/// An interaction channel entry (form) [PD00-SYO-SYD-USI-CHA-nn].
///
/// Comprehensive definition of an access channel including platform details,
/// features, constraints, and user experience considerations.
class InteractionChannelEntry {
  @Form([
    Field('channelName', String, 'Channel Name', required: true,
        hint: 'e.g., Customer Web Portal, Mobile App, Admin API'),
    Field('channelId', String, 'Channel ID',
        hint: 'Unique identifier for the channel'),
    Field('channelType', String, 'Channel Type', required: true,
        hint: 'Web, Mobile Native, Mobile Hybrid, Desktop, API, CLI, Voice, '
            'Kiosk, Embedded, IoT'),
    Field('platform', String, 'Platform/Technology',
        hint: 'e.g., Flutter Web, Flutter iOS/Android, REST API'),
    Field('targetUserCategories', String, 'Target User Categories',
        hint: 'List of user category IDs this channel serves'),
    Field('description', String, 'Description',
        hint: 'Purpose and scope of this channel'),
    Field('channelPriority', String, 'Channel Priority',
        hint: 'Primary, Secondary, Tertiary'),
    Field('featureScope', String, 'Feature Scope',
        hint: 'Full, Limited, Read-only, Specialized'),
    Field('featuresIncluded', String, 'Features Included',
        hint: 'List of features available on this channel'),
    Field('featuresExcluded', String, 'Features Excluded',
        hint: 'Features not available on this channel'),
    Field('availabilityRequirement', String, 'Availability Requirement',
        hint: '24/7, Business Hours, On-demand'),
    Field('performanceTarget', String, 'Performance Target',
        hint: 'Response time, throughput expectations'),
    Field('offlineCapability', String, 'Offline Capability',
        hint: 'None, Read-only, Limited Write, Full'),
    Field('syncStrategy', String, 'Data Sync Strategy',
        hint: 'Real-time, Periodic, On-demand, Background'),
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'OAuth, SAML, API Key, JWT, Biometric, MFA'),
    Field('deviceRequirements', String, 'Device Requirements',
        hint: 'Minimum specifications, supported OS versions'),
    Field('browserSupport', String, 'Browser Support',
        hint: 'Supported browsers and versions (for web)'),
    Field('accessibilityLevel', String, 'Accessibility Level',
        hint: 'WCAG 2.1 Level A, AA, AAA'),
    Field('localizationSupport', String, 'Localization Support',
        hint: 'Languages supported on this channel'),
    Field('brandingRequirements', String, 'Branding Requirements',
        hint: 'Visual identity requirements for this channel'),
    Field('analyticsRequirements', String, 'Analytics Requirements',
        hint: 'Tracking and analytics needed'),
  ])
  String? content;

  /// Channel-specific UI/UX specifications.
  ChannelUxSpecification uxSpecification = ChannelUxSpecification();

  /// Channel-specific integration requirements.
  ChannelIntegrations integrations = ChannelIntegrations();
}

/// Channel-specific UX specification.
@Form([
  Field('navigationModel', String, 'Navigation Model',
      hint: 'Tab-based, Drawer, Bottom Nav, Sidebar, etc.'),
  Field('inputMethods', String, 'Input Methods',
      hint: 'Touch, Keyboard, Voice, Gesture, Camera'),
  Field('screenSizes', String, 'Screen Sizes Supported',
      hint: 'Phone, Tablet, Desktop, TV, Watch'),
  Field('orientationSupport', String, 'Orientation Support',
      hint: 'Portrait, Landscape, Both'),
  Field('darkModeSupport', String, 'Dark Mode Support',
      hint: 'None, Optional, System-adaptive'),
  Field('hapticFeedback', String, 'Haptic Feedback',
      hint: 'Required, Optional, None'),
  Field('gestureSupport', String, 'Gesture Support',
      hint: 'Swipe, Pinch, Long-press, etc.'),
  Field('keyboardShortcuts', String, 'Keyboard Shortcuts',
      hint: 'List of required keyboard shortcuts'),
])
class ChannelUxSpecification {
  /// UX specification content.
  @ContentType('form', 'Channel-specific user experience specifications.')
  String? content;
}

/// Channel-specific integration requirements.
@Form([
  Field('pushNotificationService', String, 'Push Notification Service',
      hint: 'FCM, APNs, Web Push'),
  Field('analyticsService', String, 'Analytics Service',
      hint: 'Firebase Analytics, Mixpanel, etc.'),
  Field('crashReporting', String, 'Crash Reporting',
      hint: 'Crashlytics, Sentry, etc.'),
  Field('deepLinking', String, 'Deep Linking',
      hint: 'URL scheme, Universal Links, App Links'),
  Field('socialIntegration', String, 'Social Integration',
      hint: 'Social login, sharing capabilities'),
  Field('paymentIntegration', String, 'Payment Integration',
      hint: 'Apple Pay, Google Pay, Stripe, etc.'),
  Field('biometricIntegration', String, 'Biometric Integration',
      hint: 'Face ID, Touch ID, Fingerprint'),
])
class ChannelIntegrations {
  /// Integration requirements content.
  @ContentType('form', 'Channel-specific integration requirements.')
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.2 Interaction Patterns
// ---------------------------------------------------------------------------

/// 4.1.5.2. Interaction Patterns [PD00-SYO-SYD-USI-PAT].
///
/// Defines how users interact with the system including real-time interactions,
/// batch processing, workflow-driven tasks, and notification-driven actions.
@SectionId('PD00-SYO-SYD-USI-PAT')
@ContentHelp('Define the interaction patterns used in the system: real-time '
    'interactions, batch processing, workflow-driven tasks, notification-driven '
    'actions, and scheduled operations.')
class InteractionPatterns {
  @ContentType('description', 'Overview of interaction patterns and when '
      'each pattern is used.')
  String? content;

  /// Pattern entries — contains 1+× InteractionPatternEntry.
  @SectionIdPattern('PD00-SYO-SYD-USI-PAT-xx')
  @Min(1)
  @ContentHelp('Add one entry per interaction pattern used in the system.')
  List<InteractionPatternEntry> patterns = [];
}

/// An interaction pattern entry (form) [PD00-SYO-SYD-USI-PAT-nn].
///
/// Definition of a specific interaction pattern including timing, triggers,
/// and user experience considerations.
class InteractionPatternEntry {
  @Form([
    Field('patternName', String, 'Pattern Name', required: true,
        hint: 'e.g., Real-time Form Submission, Batch Report Generation'),
    Field('patternId', String, 'Pattern ID',
        hint: 'Unique identifier'),
    Field('patternType', String, 'Pattern Type', required: true,
        hint: 'Synchronous, Asynchronous, Batch, Scheduled, Event-driven, '
            'Workflow, Polling, Streaming'),
    Field('description', String, 'Description',
        hint: 'What this pattern involves'),
    Field('triggerType', String, 'Trigger Type',
        hint: 'User Action, System Event, Schedule, External Signal'),
    Field('triggerDetails', String, 'Trigger Details',
        hint: 'Specific conditions that trigger this pattern'),
    Field('responseTime', String, 'Expected Response Time',
        hint: 'Immediate, Seconds, Minutes, Hours, Days'),
    Field('feedbackMechanism', String, 'Feedback Mechanism',
        hint: 'Progress indicator, Status page, Email notification'),
    Field('errorHandling', String, 'Error Handling',
        hint: 'Retry, Rollback, Manual intervention, Notification'),
    Field('useCases', String, 'Use Cases',
        hint: 'List of use cases that follow this pattern'),
    Field('userCategories', String, 'Applicable User Categories',
        hint: 'Which user categories use this pattern'),
    Field('frequency', String, 'Expected Frequency',
        hint: 'How often this pattern occurs'),
    Field('concurrencyHandling', String, 'Concurrency Handling',
        hint: 'How concurrent requests are handled'),
    Field('priority', String, 'Priority',
        hint: 'High, Medium, Low - for resource allocation'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.3 Access Levels
// ---------------------------------------------------------------------------

/// 4.1.5.3. Access Levels [PD00-SYO-SYD-USI-ACC].
///
/// Defines the access level hierarchy and how permissions are structured
/// across user categories and system functions.
@SectionId('PD00-SYO-SYD-USI-ACC')
@ContentHelp('Define access levels and how they relate to user categories, '
    'features, and data. This establishes the authorization framework.')
class AccessLevels {
  @ContentType('description', 'Overview of access level architecture and '
      'how permissions are structured.')
  String? content;

  /// Access level hierarchy diagram.
  @SectionId('PD00-SYO-SYD-USI-ACC-DIA')
  @ContentType('mermaid-flowchart', 'Access level hierarchy showing '
      'inheritance and relationships')
  @ContentHelp('Create a diagram showing the access level hierarchy.')
  String? accessLevelDiagram;

  /// Access level entries — contains 1+× AccessLevelEntry.
  @SectionIdPattern('PD00-SYO-SYD-USI-ACC-xx')
  @Min(1)
  @ContentHelp('Define each access level in the system.')
  List<AccessLevelEntry> levels = [];

  /// Permission matrix linking access levels to features.
  @SectionId('PD00-SYO-SYD-USI-ACC-MAT')
  @ContentType('description', 'Matrix showing which access levels have '
      'which permissions. Can be a table or detailed description.')
  @ContentHelp('Create a permission matrix showing the relationship between '
      'access levels, features, and permissions.')
  String? permissionMatrix;
}

/// An access level entry (form) [PD00-SYO-SYD-USI-ACC-nn].
class AccessLevelEntry {
  @Form([
    Field('levelName', String, 'Access Level Name', required: true,
        hint: 'e.g., Administrator, Power User, Standard User, Guest'),
    Field('levelId', String, 'Level ID',
        hint: 'Unique identifier'),
    Field('levelRank', int, 'Level Rank',
        hint: 'Numeric rank (higher = more permissions)'),
    Field('description', String, 'Description',
        hint: 'What this access level provides'),
    Field('inheritsFrom', String, 'Inherits From',
        hint: 'Parent access level (if hierarchical)'),
    Field('userCategories', String, 'Applicable User Categories',
        hint: 'Which user categories can have this level'),
    Field('featureAccess', String, 'Feature Access',
        hint: 'List of features accessible at this level'),
    Field('dataAccess', String, 'Data Access Scope',
        hint: 'Own data, Team data, Department data, All data'),
    Field('adminCapabilities', String, 'Administrative Capabilities',
        hint: 'Admin functions available at this level'),
    Field('apiAccess', String, 'API Access',
        hint: 'API endpoints accessible'),
    Field('restrictions', String, 'Restrictions',
        hint: 'Explicit restrictions or limitations'),
    Field('auditRequirements', String, 'Audit Requirements',
        hint: 'Audit logging requirements for this level'),
    Field('elevationProcess', String, 'Elevation Process',
        hint: 'How users can request higher access'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.4 Session Model
// ---------------------------------------------------------------------------

/// 4.1.5.4. Session Model [PD00-SYO-SYD-USI-SES].
///
/// Defines session management including authentication, timeouts, and
/// multi-device session handling.
@SectionId('PD00-SYO-SYD-USI-SES')
@ContentHelp('Define session management: session lifecycle, timeouts, '
    'multi-device handling, and session security.')
class SessionModel {
  @ContentType('description', 'Overview of session management approach.')
  String? content;

  /// Session configuration.
  @Form([
    Field('sessionType', String, 'Session Type',
        hint: 'Server-side, Client-side (JWT), Hybrid'),
    Field('sessionStorage', String, 'Session Storage',
        hint: 'Cookie, LocalStorage, Secure Storage'),
    Field('sessionTimeout', String, 'Session Timeout',
        hint: 'Idle timeout duration'),
    Field('absoluteTimeout', String, 'Absolute Timeout',
        hint: 'Maximum session duration'),
    Field('refreshMechanism', String, 'Token Refresh Mechanism',
        hint: 'Sliding window, Explicit refresh, Re-authentication'),
    Field('multiDevicePolicy', String, 'Multi-Device Policy',
        hint: 'Single device, Multiple devices, Device limit'),
    Field('concurrentSessionLimit', int, 'Concurrent Session Limit',
        hint: 'Maximum simultaneous sessions'),
    Field('sessionTermination', String, 'Session Termination',
        hint: 'Manual logout, Timeout, Force logout'),
    Field('rememberMeOption', String, 'Remember Me Option',
        hint: 'Available, Not available, Configurable'),
    Field('deviceTrust', String, 'Device Trust',
        hint: 'Trusted devices concept support'),
    Field('sessionRecovery', String, 'Session Recovery',
        hint: 'How interrupted sessions are handled'),
    Field('securityEvents', String, 'Security Events',
        hint: 'Events that trigger session review/termination'),
  ])
  String? sessionConfiguration;
}

// ---------------------------------------------------------------------------
// 4.1.5.5 Notification Model
// ---------------------------------------------------------------------------

/// 4.1.5.5. Notification Model [PD00-SYO-SYD-USI-NOT].
///
/// Defines how the system notifies users of events, updates, and actions
/// across different channels.
@SectionId('PD00-SYO-SYD-USI-NOT')
@ContentHelp('Define notification strategy: channels, triggers, preferences, '
    'and delivery mechanisms.')
class NotificationModel {
  @ContentType('description', 'Overview of notification strategy.')
  String? content;

  /// Notification channel entries — contains 1+× NotificationChannelEntry.
  @SectionIdPattern('PD00-SYO-SYD-USI-NOT-CHA-xx')
  @Min(1)
  @ContentHelp('Define each notification channel.')
  List<NotificationChannelEntry> channels = [];

  /// Notification type entries — contains 1+× NotificationTypeEntry.
  @SectionIdPattern('PD00-SYO-SYD-USI-NOT-TYP-xx')
  @ContentHelp('Define each notification type.')
  List<NotificationTypeEntry> notificationTypes = [];

  /// User notification preferences.
  UserNotificationPreferences preferences = UserNotificationPreferences();
}

/// A notification channel entry.
class NotificationChannelEntry {
  @Form([
    Field('channelName', String, 'Channel Name', required: true,
        hint: 'Email, SMS, Push Notification, In-App, Slack, Teams'),
    Field('channelId', String, 'Channel ID'),
    Field('description', String, 'Description'),
    Field('deliveryMethod', String, 'Delivery Method',
        hint: 'Immediate, Batched, Digest'),
    Field('retryPolicy', String, 'Retry Policy',
        hint: 'Retry attempts and intervals'),
    Field('fallbackChannel', String, 'Fallback Channel',
        hint: 'Alternative channel if delivery fails'),
    Field('quietHoursSupport', String, 'Quiet Hours Support',
        hint: 'Respects user quiet hours settings'),
    Field('urgencyLevels', String, 'Supported Urgency Levels',
        hint: 'Which urgency levels use this channel'),
  ])
  String? content;
}

/// A notification type entry.
class NotificationTypeEntry {
  @Form([
    Field('notificationType', String, 'Notification Type', required: true,
        hint: 'e.g., Order Confirmation, Password Reset, System Alert'),
    Field('typeId', String, 'Type ID'),
    Field('category', String, 'Category',
        hint: 'Transactional, Marketing, System, Security'),
    Field('urgency', String, 'Urgency Level',
        hint: 'Critical, High, Medium, Low'),
    Field('defaultChannels', String, 'Default Channels',
        hint: 'Channels used by default'),
    Field('userConfigurable', String, 'User Configurable',
        hint: 'Can user change notification preferences for this type'),
    Field('mandatoryChannels', String, 'Mandatory Channels',
        hint: 'Channels that cannot be disabled'),
    Field('triggerEvent', String, 'Trigger Event',
        hint: 'System event that triggers this notification'),
    Field('contentTemplate', String, 'Content Template',
        hint: 'Template ID or description'),
    Field('localized', String, 'Localized',
        hint: 'Available in multiple languages'),
  ])
  String? content;
}

/// User notification preferences.
@Form([
  Field('globalOptOut', String, 'Global Opt-Out Support',
      hint: 'Can users opt out of all non-essential notifications'),
  Field('perTypeControl', String, 'Per-Type Control',
      hint: 'Can users control individual notification types'),
  Field('channelPreferences', String, 'Channel Preferences',
      hint: 'Can users choose preferred channels'),
  Field('frequencyControl', String, 'Frequency Control',
      hint: 'Can users control notification frequency'),
  Field('quietHours', String, 'Quiet Hours',
      hint: 'Can users set do-not-disturb hours'),
  Field('digestOption', String, 'Digest Option',
      hint: 'Can users opt for daily/weekly digests'),
])
class UserNotificationPreferences {
  /// Preferences content.
  @ContentType('form', 'User notification preference options.')
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.6 Multi-Channel Experience
// ---------------------------------------------------------------------------

/// 4.1.5.6. Multi-Channel Experience [PD00-SYO-SYD-USI-MUL].
///
/// Defines how the system provides a consistent experience across channels
/// and handles channel switching.
@SectionId('PD00-SYO-SYD-USI-MUL')
@ContentHelp('Define multi-channel experience: context handoff between '
    'channels, data synchronization, and experience consistency.')
class MultiChannelExperience {
  @ContentType('description', 'Overview of multi-channel strategy.')
  String? content;

  /// Multi-channel configuration.
  @Form([
    Field('channelHandoff', String, 'Channel Handoff',
        hint: 'How users switch between channels seamlessly'),
    Field('contextPreservation', String, 'Context Preservation',
        hint: 'What context is preserved when switching channels'),
    Field('dataSynchronization', String, 'Data Synchronization',
        hint: 'Real-time, Near-real-time, Eventual'),
    Field('conflictResolution', String, 'Conflict Resolution',
        hint: 'How conflicts from multi-channel edits are resolved'),
    Field('consistentBranding', String, 'Consistent Branding',
        hint: 'Brand consistency requirements across channels'),
    Field('featureParity', String, 'Feature Parity',
        hint: 'Degree of feature consistency across channels'),
    Field('responsiveDesign', String, 'Responsive Design',
        hint: 'Approach to responsive/adaptive design'),
    Field('progressiveEnhancement', String, 'Progressive Enhancement',
        hint: 'How features degrade on limited channels'),
    Field('offlineFirst', String, 'Offline-First Strategy',
        hint: 'Offline-first approach for applicable channels'),
  ])
  String? multiChannelConfiguration;
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
/// acceptance testing and project closure. Based on SMART criteria,
/// Balanced Scorecard, and PRINCE2 benefits management principles.
@SectionId('PD00-SYO-GOA-SUC')
@ContentHelp('Define criteria that collectively determine project success. '
    'Each criterion should be objectively verifiable, measurable, and '
    'time-bound. Criteria should cover business, technical, user, and '
    'compliance dimensions.')
class SuccessCriteria {
  @ContentType('description', 'Overview of success criteria and how they '
      'relate to project objectives. Define the acceptance process and '
      'sign-off requirements.')
  String? content;

  /// Success criteria summary.
  SuccessCriteriaSummary summary = SuccessCriteriaSummary();

  /// Acceptance and evaluation framework.
  SuccessCriteriaFramework framework = SuccessCriteriaFramework();

  /// Success criterion entries — contains 1+× SuccessCriterionEntry.
  @SectionIdPattern('PD00-SYO-GOA-SUC-xx')
  @Min(1)
  @ContentHelp('Define individual success criteria. Include criteria for '
      'business outcomes, user satisfaction, technical quality, and '
      'compliance requirements.')
  List<SuccessCriterionEntry> items = [];

  /// Success criteria by category.
  SuccessCriteriaByCategory byCategory = SuccessCriteriaByCategory();

  /// Success criteria matrix — overall view.
  @SectionId('PD00-SYO-GOA-SUC-MAT')
  @ContentType('description', 'Success criteria matrix showing all criteria, '
      'their weights, and evaluation status.')
  @ContentHelp('Create a summary matrix of all success criteria.')
  String? successCriteriaMatrix;

  /// Post-implementation review plan.
  PostImplementationReview postImplementationReview = PostImplementationReview();
}

/// Summary metrics for success criteria.
@Form([
  Field('totalCriteria', int, 'Total Number of Criteria'),
  Field('criticalCount', int, 'Critical Criteria Count'),
  Field('highPriorityCount', int, 'High Priority Count'),
  Field('mediumPriorityCount', int, 'Medium Priority Count'),
  Field('lowPriorityCount', int, 'Low Priority Count'),
  Field('businessCriteriaCount', int, 'Business Criteria Count'),
  Field('technicalCriteriaCount', int, 'Technical Criteria Count'),
  Field('userCriteriaCount', int, 'User Satisfaction Criteria Count'),
  Field('complianceCriteriaCount', int, 'Compliance Criteria Count'),
  Field('minCriteriaMet', String, 'Minimum Criteria for Success',
      hint: 'All critical + X% of others'),
  Field('successThreshold', String, 'Overall Success Threshold',
      hint: 'Percentage or formula for determining success'),
])
class SuccessCriteriaSummary {
  /// Summary content.
  @ContentType('aggregation', 'Summary statistics for success criteria.')
  String? content;
}

/// Framework for evaluating and accepting success criteria.
@Form([
  Field('acceptanceProcess', String, 'Acceptance Process',
      hint: 'How criteria will be evaluated'),
  Field('signOffAuthority', String, 'Sign-off Authority',
      hint: 'Who approves project success'),
  Field('escalationPath', String, 'Escalation Path',
      hint: 'Who to escalate when criteria not met'),
  Field('evaluationTiming', String, 'Evaluation Timing',
      hint: 'When criteria will be evaluated'),
  Field('evaluationMilestones', String, 'Evaluation Milestones',
      hint: 'Go-live, 30 days, 90 days, 1 year'),
  Field('partialSuccessHandling', String, 'Partial Success Handling',
      hint: 'What if some criteria not met'),
  Field('criteriaWaiverProcess', String, 'Criteria Waiver Process',
      hint: 'How criteria can be waived or modified'),
  Field('evidenceRequirements', String, 'Evidence Requirements',
      hint: 'What evidence is needed to prove criteria met'),
  Field('independentVerification', String, 'Independent Verification',
      hint: 'Whether third-party verification is required'),
  Field('disputeResolution', String, 'Dispute Resolution',
      hint: 'How disputes about criteria are resolved'),
])
class SuccessCriteriaFramework {
  /// Framework content.
  @ContentType('form', 'Acceptance and evaluation framework details.')
  String? content;
}

/// Success criteria organized by category.
class SuccessCriteriaByCategory {
  /// Business outcome criteria overview.
  @SectionId('PD00-SYO-GOA-SUC-BUS')
  @ContentType('description', 'Overview of business-focused success criteria '
      'including ROI, market impact, and strategic alignment.')
  @ContentHelp('Describe how business outcomes will be measured.')
  String? businessCriteria;

  /// Technical quality criteria overview.
  @SectionId('PD00-SYO-GOA-SUC-TEC')
  @ContentType('description', 'Overview of technical quality criteria '
      'including performance, reliability, and maintainability.')
  @ContentHelp('Describe how technical quality will be measured.')
  String? technicalCriteria;

  /// User satisfaction criteria overview.
  @SectionId('PD00-SYO-GOA-SUC-USR')
  @ContentType('description', 'Overview of user-focused success criteria '
      'including adoption, satisfaction, and productivity.')
  @ContentHelp('Describe how user satisfaction will be measured.')
  String? userCriteria;

  /// Compliance criteria overview.
  @SectionId('PD00-SYO-GOA-SUC-COM')
  @ContentType('description', 'Overview of compliance-related success criteria '
      'including regulatory, security, and audit requirements.')
  @ContentHelp('Describe how compliance will be verified.')
  String? complianceCriteria;

  /// Timeline and budget criteria overview.
  @SectionId('PD00-SYO-GOA-SUC-PRJ')
  @ContentType('description', 'Overview of project management criteria '
      'including timeline adherence, budget compliance, and scope management.')
  @ContentHelp('Describe how project execution will be measured.')
  String? projectCriteria;
}

/// A success criterion entry [PD00-SYO-GOA-SUC-nn] (form).
///
/// Individual success criterion with comprehensive measurement details,
/// thresholds, and verification requirements.
class SuccessCriterionEntry {
  @Form([
    // Identification
    Field('criterionId', String, 'Criterion ID', required: true,
        hint: 'Unique identifier (e.g., SC-001)'),
    Field('criterionName', String, 'Criterion Name', required: true,
        hint: 'Short descriptive name'),
    Field('description', String, 'Description',
        hint: 'Detailed description of what success means'),
    Field('category', String, 'Category', required: true,
        hint: 'Business, Technical, User, Compliance, Budget, Timeline'),
    Field('subcategory', String, 'Subcategory',
        hint: 'More specific categorization'),

    // Measurement
    Field('metric', String, 'Metric', required: true,
        hint: 'What is measured (e.g., response time, satisfaction score)'),
    Field('baselineValue', String, 'Baseline Value',
        hint: 'Current value before project'),
    Field('minimumThreshold', String, 'Minimum Acceptable Threshold',
        hint: 'Minimum value to be considered success'),
    Field('targetValue', String, 'Target Value', required: true,
        hint: 'Desired target value'),
    Field('stretchGoal', String, 'Stretch Goal',
        hint: 'Optimal value exceeding target'),
    Field('unit', String, 'Unit of Measurement',
        hint: 'e.g., %, seconds, count, currency'),

    // Verification
    Field('measurementMethod', String, 'Measurement Method',
        hint: 'How metric will be measured'),
    Field('dataSource', String, 'Data Source',
        hint: 'Where measurement data comes from'),
    Field('measurementFrequency', String, 'Measurement Frequency',
        hint: 'How often measurement is taken'),
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Who is responsible for measurement'),
    Field('verificationPoint', String, 'Verification Point',
        hint: 'When verified: go-live, 30 days, 90 days'),
    Field('evidenceType', String, 'Evidence Type',
        hint: 'What evidence proves criterion met'),

    // Importance
    Field('weight', String, 'Weight',
        hint: 'Importance: Critical, High, Medium, Low'),
    Field('isMandatory', String, 'Mandatory',
        hint: 'Yes/No - is this required for overall success'),
    Field('consequenceIfNotMet', String, 'Consequence If Not Met',
        hint: 'Impact if this criterion is not met'),

    // Relationships
    Field('relatedGoals', String, 'Related Goals',
        hint: 'Which business/technical goals this supports'),
    Field('relatedRequirements', String, 'Related Requirements',
        hint: 'Requirement IDs that contribute to this criterion'),
    Field('dependencies', String, 'Dependencies',
        hint: 'Other criteria this depends on'),
    Field('stakeholders', String, 'Key Stakeholders',
        hint: 'Who cares most about this criterion'),

    // Status
    Field('status', String, 'Status',
        hint: 'Not Evaluated, Met, Not Met, Waived'),
    Field('currentValue', String, 'Current Value',
        hint: 'Latest measured value'),
    Field('trend', String, 'Trend',
        hint: 'Improving, Stable, Declining'),
    Field('evidence', String, 'Evidence',
        hint: 'Proof that criterion is met'),
    Field('evaluationNotes', String, 'Evaluation Notes',
        hint: 'Notes from evaluation'),
  ])
  String? content;
}

/// Post-implementation review plan for success criteria.
@Form([
  Field('reviewSchedule', String, 'Review Schedule',
      hint: 'When post-implementation reviews occur'),
  Field('reviewOwner', String, 'Review Owner',
      hint: 'Who is responsible for organizing reviews'),
  Field('participantRoles', String, 'Participant Roles',
      hint: 'Who should participate in reviews'),
  Field('reportingRequirements', String, 'Reporting Requirements',
      hint: 'What reports are produced'),
  Field('lessonsLearnedProcess', String, 'Lessons Learned Process',
      hint: 'How lessons learned are captured'),
  Field('benefitsTrackingDuration', String, 'Benefits Tracking Duration',
      hint: 'How long benefits are tracked'),
  Field('correctionActionProcess', String, 'Corrective Action Process',
      hint: 'How shortfalls are addressed'),
])
class PostImplementationReview {
  /// Post-implementation review content.
  @ContentType('form', 'Post-implementation review planning.')
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
///
/// Documents existing systems that will be replaced, migrated, or decommissioned
/// as part of the project. Follows TOGAF migration planning patterns and
/// Gartner application rationalization frameworks. Each system entry provides
/// comprehensive assessment for informed replacement decisions.
@SectionId('PD00-SYO-SYR')
@Comment('Seeds → CS')
class SystemsToReplace {
  /// Overview of the systems replacement scope and strategy.
  @ContentHelp('Provide executive summary of systems being replaced: '
      'portfolio count, replacement rationale, expected timeline, '
      'and overall migration approach.')
  TextSection overview = TextSection();

  /// 4.4.1. Replacement Inventory [PD00-SYO-SYR-INV] — contains 0+×.
  ReplacementInventory replacementInventory = ReplacementInventory();

  /// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG].
  MigrationConsiderations migrationConsiderations = MigrationConsiderations();
}

// ---------------------------------------------------------------------------
// 4.4.1. Replacement Inventory
// ---------------------------------------------------------------------------

/// Container for systems to replace [PD00-SYO-SYR-INV].
///
/// Provides a structured inventory of all systems targeted for replacement,
/// with portfolio-level metrics and prioritization guidance.
@SectionId('PD00-SYO-SYR-INV')
class ReplacementInventory {
  /// Portfolio summary before listing individual systems.
  @ContentHelp('Summarize the replacement portfolio: total system count, '
      'technology categories, combined user base, and overall complexity.')
  TextSection portfolioSummary = TextSection();

  /// Prioritization criteria for replacement sequencing.
  @ContentHelp('Describe how replacement order is determined: business value, '
      'technical debt, risk, dependency chains, resource availability.')
  TextSection prioritizationCriteria = TextSection();

  /// Contains 0+× SystemToReplaceEntry.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx')
  List<SystemToReplaceEntry> systems = [];
}

/// A system to replace entry [PD00-SYO-SYR-INV-nn] (form).
///
/// Comprehensive documentation of a legacy system to be replaced, covering
/// technical assessment, business criticality, replacement strategy, and
/// migration planning. Follows Gartner's TIME (Tolerate, Invest, Migrate,
/// Eliminate) model and TOGAF application portfolio management patterns.
class SystemToReplaceEntry {
  // -------------------------------------------------------------------------
  // System Identification
  // -------------------------------------------------------------------------

  @Form([
    Field('systemId', String, 'System ID (e.g., SYS-CRM-001)', required: true),
    Field('systemName', String, 'System Name', required: true),
    Field('officialName', String, 'Official/Vendor Name'),
    Field('systemDescription', String, 'Description'),
    Field('systemCategory', String, 'Category (CRM, ERP, HR, Finance, etc.)'),
    Field('applicationTier', String,
        'Tier (Mission Critical, Business Critical, Operational)'),
    Field('businessOwner', String, 'Business Owner'),
    Field('technicalOwner', String, 'Technical Owner'),
    Field('vendorName', String, 'Vendor/Provider'),
    Field('contractStatus', String,
        'Contract Status (Active, Expired, Month-to-month)'),
    Field('contractEndDate', String, 'Contract End Date'),
  ])
  String? identificationContent;

  /// Technical stack and architecture assessment.
  SystemTechnicalAssessment technicalAssessment = SystemTechnicalAssessment();

  /// Business value and criticality assessment.
  SystemBusinessCriticality businessCriticality = SystemBusinessCriticality();

  /// Detailed replacement approach.
  SystemReplacementStrategy replacementStrategy = SystemReplacementStrategy();

  /// Data migration scope and assessment.
  SystemDataScope dataScope = SystemDataScope();

  /// Contains 0+× SystemDependencyEntry — integrations with other systems.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-DEP-xx')
  List<SystemDependencyEntry> dependencies = [];

  /// User impact and change management needs.
  SystemUserImpact userImpact = SystemUserImpact();

  /// Financial analysis for replacement decision.
  SystemCostAnalysis costAnalysis = SystemCostAnalysis();

  /// Per-system migration considerations.
  SystemMigrationPlan migrationPlan = SystemMigrationPlan();

  /// Documentation and knowledge transfer status.
  SystemKnowledgeTransfer knowledgeTransfer = SystemKnowledgeTransfer();
}

/// Technical assessment for a system to replace [PD00-SYO-SYR-INV-nn-TEC].
@SectionId('PD00-SYO-SYR-INV-xx-TEC')
class SystemTechnicalAssessment {
  @Form([
    Field('primaryTechnology', String, 'Primary Technology/Platform'),
    Field('technologyVersion', String, 'Version'),
    Field('databasePlatform', String, 'Database Platform'),
    Field('hostingEnvironment', String,
        'Hosting (On-premises, Cloud, Hybrid, SaaS)'),
    Field('operatingSystem', String, 'Operating System'),
    Field('middlewareComponents', String, 'Middleware Components'),
    Field('deploymentDate', String, 'Initial Deployment Date'),
    Field('systemAge', int, 'System Age (Years)'),
    Field('lastMajorUpgrade', String, 'Last Major Upgrade'),
    Field('vendorSupportStatus', String,
        'Support Status (Full, Extended, End of Life)'),
    Field('endOfSupportDate', String, 'End of Support Date'),
    Field('technicalDebtRating', String,
        'Technical Debt (Low, Medium, High, Critical)'),
    Field('securityPosture', String, 'Security Posture'),
    Field('performanceStatus', String,
        'Performance (Acceptable, Degraded, Poor)'),
    Field('scalabilityLimitations', String, 'Scalability Limitations'),
    Field('maintainability', String, 'Maintainability Rating'),
    Field('documentationQuality', String,
        'Documentation (Complete, Partial, Outdated, Missing)'),
  ])
  String? content;

  /// Known technical issues and deficiencies.
  TextSection knownIssues = TextSection();

  /// Security vulnerabilities and compliance gaps.
  TextSection securityConcerns = TextSection();
}

/// Business criticality assessment [PD00-SYO-SYR-INV-nn-BUS].
@SectionId('PD00-SYO-SYR-INV-xx-BUS')
class SystemBusinessCriticality {
  @Form([
    Field('criticalityRating', String,
        'Criticality (1=Mission Critical, 2=Business, 3=Operational)',
        required: true),
    Field('businessValueScore', int, 'Business Value Score (1-10)'),
    Field('timeModelClassification', String,
        'TIME Classification (Tolerate, Invest, Migrate, Eliminate)'),
    Field('activeUsers', int, 'Active Users'),
    Field('peakConcurrentUsers', int, 'Peak Concurrent Users'),
    Field('transactionVolume', String, 'Transaction Volume'),
    Field('dataVolume', String, 'Data Volume'),
    Field('revenueImpact', String, 'Revenue Impact (Direct, Indirect, None)'),
    Field('operationsImpact', String,
        'Operations Impact (Severe, Moderate, Minor, None)'),
    Field('complianceRole', String, 'Compliance/Regulatory Role'),
    Field('maxDowntime', String, 'Max Acceptable Downtime (RTO)'),
  ])
  String? content;

  /// Business units and departments using this system.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-BUS-BU-xx')
  List<SystemBusinessUnitEntry> businessUnits = [];

  /// Business processes supported by this system.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-BUS-BP-xx')
  List<SystemBusinessProcessEntry> supportedProcesses = [];
}

/// Business unit using the system [PD00-SYO-SYR-INV-nn-BUS-BU-nn].
class SystemBusinessUnitEntry {
  @Form([
    Field('unitName', String, 'Business Unit', required: true),
    Field('userCount', int, 'User Count'),
    Field('usagePattern', String, 'Usage Pattern (Daily, Weekly, etc.)'),
    Field('dependencyLevel', String,
        'Dependency Level (Primary, Secondary, Occasional)'),
    Field('impactIfRemoved', String, 'Impact if System Removed'),
  ])
  String? content;
}

/// Business process supported [PD00-SYO-SYR-INV-nn-BUS-BP-nn].
class SystemBusinessProcessEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('processId', String, 'Process ID'),
    Field('systemRole', String, 'System Role (Primary, Data Source, etc.)'),
    Field('automationLevel', String, 'Automation Level'),
    Field('processFrequency', String, 'Execution Frequency'),
  ])
  String? content;
}

/// Replacement strategy details [PD00-SYO-SYR-INV-nn-STR].
@SectionId('PD00-SYO-SYR-INV-xx-STR')
class SystemReplacementStrategy {
  @Form([
    Field('strategyType', String,
        'Strategy (Replace, Consolidate, Retire, Rehost, Replatform)',
        required: true),
    Field('strategyRationale', String, 'Rationale'),
    Field('targetSolution', String, 'Target Solution'),
    Field('targetSolutionType', String,
        'Target Type (COTS, SaaS, Custom, Platform)'),
    Field('plannedStartDate', String, 'Planned Start Date'),
    Field('targetCutoverDate', String, 'Target Cutover Date'),
    Field('decommissionDate', String, 'Decommission Date'),
    Field('parallelRunPeriod', String, 'Parallel Run Period'),
    Field('cutoverStrategy', String,
        'Cutover (Big Bang, Phased, Parallel Run, Pilot)'),
    Field('rollbackCapability', String, 'Rollback Capability (Full, Partial)'),
    Field('rollbackWindow', String, 'Rollback Window'),
  ])
  String? content;

  /// Replacement phases if phased approach.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-STR-PH-xx')
  List<ReplacementPhaseEntry> phases = [];

  /// Predecessor systems that must be addressed first.
  TextSection predecessorDependencies = TextSection();

  /// Success criteria for replacement completion.
  TextSection successCriteria = TextSection();
}

/// A replacement phase entry [PD00-SYO-SYR-INV-nn-STR-PH-nn].
class ReplacementPhaseEntry {
  @Form([
    Field('phaseNumber', int, 'Phase Number', required: true),
    Field('phaseName', String, 'Phase Name', required: true),
    Field('phaseScope', String, 'Scope'),
    Field('startDate', String, 'Start Date'),
    Field('endDate', String, 'End Date'),
    Field('exitCriteria', String, 'Exit Criteria'),
  ])
  String? content;
}

/// Data scope and migration assessment [PD00-SYO-SYR-INV-nn-DAT].
@SectionId('PD00-SYO-SYR-INV-xx-DAT')
class SystemDataScope {
  @Form([
    Field('totalRecords', String, 'Total Records'),
    Field('dataSize', String, 'Data Size (GB/TB)'),
    Field('growthRate', String, 'Growth Rate'),
    Field('dataTypes', String, 'Data Types (Master, Transactional, etc.)'),
    Field('sensitivityLevel', String,
        'Sensitivity (Public, Internal, Confidential, PII)'),
    Field('retentionRequirements', String, 'Retention Requirements'),
    Field('dataQuality', String, 'Quality Rating (Excellent to Poor)'),
    Field('cleansingRequired', String, 'Cleansing Required'),
    Field('deduplicationNeeded', bool, 'Deduplication Needed'),
    Field('transformationComplexity', String, 'Transformation Complexity'),
    Field('migrationScope', String,
        'Scope (Full, Recent, Active records, Reference)'),
    Field('archiveStrategy', String, 'Archive Strategy'),
  ])
  String? content;

  /// Data entities to migrate.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-DAT-ENT-xx')
  List<DataEntityMigrationEntry> entities = [];

  /// Data quality issues to address.
  TextSection knownQualityIssues = TextSection();
}

/// A data entity migration entry [PD00-SYO-SYR-INV-nn-DAT-ENT-nn].
class DataEntityMigrationEntry {
  @Form([
    Field('entityName', String, 'Entity Name', required: true),
    Field('recordCount', String, 'Record Count'),
    Field('targetMapping', String, 'Target Mapping'),
    Field('transformationNotes', String, 'Transformation Notes'),
    Field('validationRules', String, 'Validation Rules'),
    Field('migrationPriority', String, 'Priority'),
  ])
  String? content;
}

/// A system dependency entry [PD00-SYO-SYR-INV-nn-DEP-nn].
///
/// Documents integrations and dependencies with other systems.
class SystemDependencyEntry {
  @Form([
    Field('integrationId', String, 'Integration ID'),
    Field('connectedSystem', String, 'Connected System', required: true),
    Field('systemStatus', String,
        'Status (Also being replaced, Remaining, External)'),
    Field('direction', String, 'Direction (Inbound, Outbound, Bidirectional)'),
    Field('integrationType', String, 'Type (API, File, Database, Message)'),
    Field('protocol', String, 'Protocol'),
    Field('dataExchanged', String, 'Data Exchanged'),
    Field('frequency', String, 'Frequency'),
    Field('volume', String, 'Volume'),
    Field('criticality', String, 'Criticality (Critical, Important)'),
    Field('impactIfBroken', String, 'Impact if Broken'),
    Field('owningSystem', String, 'Integration Owner'),
    Field('replacementMapping', String, 'Replacement Mapping'),
    Field('migrationApproach', String,
        'Migration Approach (Rebuild, Adapt, Bridge, Eliminate)'),
  ])
  String? content;
}

/// User impact assessment [PD00-SYO-SYR-INV-nn-USR].
@SectionId('PD00-SYO-SYR-INV-xx-USR')
class SystemUserImpact {
  @Form([
    Field('totalUserCount', int, 'Total Users'),
    Field('activeUserCount', int, 'Active Users (last 30 days)'),
    Field('powerUsers', int, 'Power Users'),
    Field('userLocations', String, 'User Locations'),
    Field('workflowChange', String, 'Workflow Change Level'),
    Field('uiChange', String, 'UI Change Level'),
    Field('functionalityChange', String, 'Functionality Change'),
    Field('trainingRequired', String, 'Training Required'),
    Field('estimatedTrainingHours', int, 'Training Hours per User'),
    Field('trainingApproach', String, 'Training Approach'),
    Field('trainingMaterials', String, 'Materials Needed'),
    Field('communicationPlan', String, 'Communication Plan'),
    Field('changeChampions', String, 'Change Champions'),
  ])
  String? content;

  /// User groups requiring specific handling.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-USR-GR-xx')
  List<UserGroupImpactEntry> userGroups = [];
}

/// User group impact entry [PD00-SYO-SYR-INV-nn-USR-GR-nn].
class UserGroupImpactEntry {
  @Form([
    Field('groupName', String, 'User Group', required: true),
    Field('userCount', int, 'User Count'),
    Field('impactLevel', String, 'Impact Level (High, Medium, Low)'),
    Field('specialConsiderations', String, 'Special Considerations'),
    Field('trainingNeeds', String, 'Training Needs'),
  ])
  String? content;
}

/// Cost analysis for replacement [PD00-SYO-SYR-INV-nn-CST].
@SectionId('PD00-SYO-SYR-INV-xx-CST')
class SystemCostAnalysis {
  @Form([
    Field('annualLicenseCost', String, 'Annual License Cost'),
    Field('annualMaintenanceCost', String, 'Annual Maintenance Cost'),
    Field('annualOperationsCost', String, 'Annual Operations Cost'),
    Field('annualSupportCost', String, 'Annual Support Cost'),
    Field('totalCurrentAnnualCost', String, 'Total Current Annual Cost'),
    Field('migrationProjectCost', String, 'Migration Project Cost'),
    Field('dataConversionCost', String, 'Data Conversion Cost'),
    Field('integrationCost', String, 'Integration Rebuild Cost'),
    Field('trainingCost', String, 'Training Cost'),
    Field('parallelRunCost', String, 'Parallel Run Cost'),
    Field('newSystemAnnualCost', String, 'New System Annual Cost'),
    Field('annualSavings', String, 'Annual Savings'),
    Field('paybackPeriod', String, 'Payback Period'),
    Field('fiveYearTco', String, '5-Year TCO'),
  ])
  String? content;

  /// Cost breakdown by category if detailed analysis available.
  TextSection costBreakdown = TextSection();

  /// Non-financial benefits to include in ROI.
  TextSection nonFinancialBenefits = TextSection();
}

/// Per-system migration plan [PD00-SYO-SYR-INV-nn-MIG].
@SectionId('PD00-SYO-SYR-INV-xx-MIG')
class SystemMigrationPlan {
  @Form([
    Field('migrationApproach', String,
        'Approach (Big Bang, Phased, Parallel, Strangler)'),
    Field('dataTransformationNeeds', String, 'Data Transformation Needs'),
    Field('estimatedEffort', String, 'Estimated Effort'),
    Field('teamSize', String, 'Team Size'),
    Field('duration', String, 'Estimated Duration'),
    Field('testingApproach', String, 'Testing Approach'),
    Field('dataValidationMethod', String, 'Data Validation Method'),
    Field('uatScope', String, 'UAT Scope'),
    Field('cutoverWindow', String, 'Cutover Window'),
    Field('cutoverDuration', String, 'Cutover Duration'),
    Field('businessContingency', String, 'Business Contingency'),
  ])
  String? content;

  /// Contains 0+× MigrationRiskEntry — per-system migration risks.
  @SectionIdPattern('PD00-SYO-SYR-INV-xx-MIG-RSK-xx')
  List<SystemMigrationRiskEntry> risks = [];

  /// Rollback strategy and procedures.
  TextSection rollbackStrategy = TextSection();

  /// Post-migration validation steps.
  TextSection postMigrationValidation = TextSection();
}

/// A system migration risk entry [PD00-SYO-SYR-INV-nn-MIG-RSK-nn].
class SystemMigrationRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID'),
    Field('riskDescription', String, 'Risk Description', required: true),
    Field('probability', String, 'Probability (High, Medium, Low)'),
    Field('impact', String, 'Impact (High, Medium, Low)'),
    Field('riskScore', String, 'Risk Score'),
    Field('mitigation', String, 'Mitigation Strategy'),
    Field('contingency', String, 'Contingency Plan'),
    Field('owner', String, 'Risk Owner'),
  ])
  String? content;
}

/// Knowledge transfer status [PD00-SYO-SYR-INV-nn-KNW].
@SectionId('PD00-SYO-SYR-INV-xx-KNW')
class SystemKnowledgeTransfer {
  @Form([
    Field('technicalDocStatus', String,
        'Technical Doc Status (Complete, Partial, Outdated, Missing)'),
    Field('businessDocStatus', String, 'Business Documentation Status'),
    Field('dataDocStatus', String, 'Data Documentation Status'),
    Field('primarySme', String, 'Primary SME'),
    Field('smeAvailability', String,
        'SME Availability (Available, Partial, Leaving)'),
    Field('smeRiskLevel', String, 'SME Risk Level'),
    Field('backupSme', String, 'Backup SME'),
    Field('knowledgeCaptureNeeded', bool, 'Knowledge Capture Needed'),
    Field('captureApproach', String, 'Capture Approach'),
    Field('captureDeadline', String, 'Capture Deadline'),
  ])
  String? content;

  /// Critical knowledge areas to preserve.
  TextSection criticalKnowledgeAreas = TextSection();

  /// Knowledge transfer plan if SME risk is high.
  TextSection knowledgeTransferPlan = TextSection();
}

// ---------------------------------------------------------------------------
// 4.4.2. Migration Considerations (Global)
// ---------------------------------------------------------------------------

/// 4.4.2. Migration Considerations [PD00-SYO-SYR-MIG] (global).
///
/// Cross-system migration concerns covering portfolio-wide strategy,
/// resource planning, and coordination. Complements per-system
/// migration details with global governance.
@SectionId('PD00-SYO-SYR-MIG')
class MigrationConsiderations {
  @Form([
    Field('overallStrategy', String,
        'Overall Strategy (Big Bang, Phased, Parallel, Strangler)'),
    Field('sequencingApproach', String, 'Sequencing Approach'),
    Field('interdependencyHandling', String, 'Interdependency Handling'),
    Field('migrationWindowStrategy', String, 'Migration Window Strategy'),
    Field('blackoutPeriods', String, 'Blackout Periods'),
    Field('parallelRunDuration', String, 'Parallel Run Duration'),
  ])
  String? strategyContent;

  /// Detailed strategy narrative.
  TextSection strategyNarrative = TextSection();

  /// Resource requirements for migration program.
  MigrationResources resources = MigrationResources();

  /// Migration risks [PD00-SYO-SYR-MIG-RIS].
  MigrationRisks migrationRisks = MigrationRisks();

  /// High-level migration timeline.
  TextSection timeline = TextSection();

  /// Migration milestones.
  @SectionIdPattern('PD00-SYO-SYR-MIG-MIL-xx')
  List<MigrationMilestoneEntry> milestones = [];

  /// Cross-system data mapping considerations.
  TextSection dataMapping = TextSection();

  /// Master data management approach during migration.
  TextSection masterDataApproach = TextSection();

  /// Global rollback strategy and governance.
  TextSection rollbackStrategy = TextSection();

  /// Go/No-Go decision criteria for each migration.
  TextSection goNoGosCriteria = TextSection();

  /// Stakeholder communication plan for migration program.
  TextSection communicationPlan = TextSection();

  /// Escalation procedures during migration.
  TextSection escalationProcedures = TextSection();
}

/// Migration resource requirements [PD00-SYO-SYR-MIG-RES].
@SectionId('PD00-SYO-SYR-MIG-RES')
class MigrationResources {
  @Form([
    Field('migrationLead', String, 'Migration Lead'),
    Field('technicalResources', String, 'Technical Resources'),
    Field('businessResources', String, 'Business Resources'),
    Field('testingResources', String, 'Testing Resources'),
    Field('vendorSupport', String, 'Vendor Support'),
    Field('consultingSupport', String, 'Consulting Support'),
    Field('contractorNeeds', String, 'Contractor Needs'),
    Field('migrationEnvironments', String, 'Migration Environments'),
    Field('dataStorageNeeds', String, 'Data Storage'),
    Field('networkBandwidth', String, 'Network Bandwidth'),
  ])
  String? content;

  /// Resource timeline by phase.
  TextSection resourceTimeline = TextSection();
}

/// A migration milestone entry [PD00-SYO-SYR-MIG-MIL-nn].
class MigrationMilestoneEntry {
  @Form([
    Field('milestoneName', String, 'Milestone Name', required: true),
    Field('targetDate', String, 'Target Date'),
    Field('systemsIncluded', String, 'Systems Included'),
    Field('deliverables', String, 'Deliverables'),
    Field('successCriteria', String, 'Success Criteria'),
    Field('gateName', String, 'Gate Name'),
  ])
  String? content;
}

/// Migration risks [PD00-SYO-SYR-MIG-RIS] — program-level risks.
///
/// Comprehensive migration risk management framework for program-level
/// risks across the entire migration portfolio. Covers risk governance,
/// assessment methodology, monitoring, and escalation procedures.
/// Follows PMI risk management practices and enterprise risk frameworks.
@SectionId('PD00-SYO-SYR-MIG-RIS')
class MigrationRisks {
  // ─────────────────────────────────────────────────────────────────────────
  // Risk Governance
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Risk governance structure
    Field('riskGovernanceModel', String, 'Risk Governance Model',
        hint: 'Centralized, federated, hybrid approach'),
    Field('riskCommitteeCharter', String, 'Risk Committee Charter'),
    Field('riskReviewFrequency', String, 'Risk Review Frequency',
        hint: 'Weekly, bi-weekly, monthly cycles'),
    Field('riskEscalationPath', String, 'Escalation Path',
        hint: 'PM → Steering Committee → Executive Sponsor'),
    Field('riskToleranceLevel', String, 'Risk Tolerance Level',
        hint: 'Enterprise risk appetite for migration'),
    Field('riskDecisionAuthority', String, 'Risk Decision Authority',
        hint: 'Who approves risk acceptance/transfer'),
    // Assessment methodology
    Field('riskAssessmentFramework', String, 'Assessment Framework',
        hint: 'PMBOK, ISO 31000, COSO, custom'),
    Field('probabilityScale', String, 'Probability Scale',
        hint: '1-5, percentage bands, qualitative'),
    Field('impactScale', String, 'Impact Scale',
        hint: '1-5, monetary, qualitative'),
    Field('riskScoringMethod', String, 'Risk Scoring Method',
        hint: 'P×I matrix, expected value, Monte Carlo'),
    Field('riskCategoryTaxonomy', String, 'Risk Category Taxonomy',
        hint: 'Technical, schedule, resource, business'),
    // Thresholds and triggers
    Field('criticalRiskThreshold', String, 'Critical Risk Threshold',
        hint: 'Score ≥ X requires executive attention'),
    Field('highRiskThreshold', String, 'High Risk Threshold'),
    Field('mediumRiskThreshold', String, 'Medium Risk Threshold'),
    Field('emergentRiskTriggers', String, 'Emergent Risk Triggers',
        hint: 'Indicators requiring immediate risk review'),
    // Reporting
    Field('riskReportingCadence', String, 'Reporting Cadence'),
    Field('riskDashboardTools', String, 'Dashboard Tools',
        hint: 'Tools for risk visualization'),
    Field('riskRegisterRepository', String, 'Risk Register Repository',
        hint: 'Where risk register is maintained'),
  ])
  String? governanceContent;

  /// Risk overview at program level.
  @ContentHelp('Executive summary of migration risk landscape: '
      'critical risks, overall risk posture, trending analysis.')
  TextSection riskOverview = TextSection();

  /// Risk assessment methodology narrative.
  @ContentHelp('Detailed description of risk assessment approach, '
      'including probability/impact criteria and scoring guidelines.')
  TextSection assessmentMethodology = TextSection();

  /// Risk categories and taxonomy.
  @ContentHelp('Definition of risk categories used: technical, '
      'organizational, schedule, budget, business, regulatory.')
  TextSection riskCategories = TextSection();

  /// Risk-based decision making criteria.
  @ContentHelp('How risk scores influence Go/No-Go decisions, '
      'resource allocation, and scheduling.')
  TextSection riskBasedDecisions = TextSection();

  /// Risk monitoring and control procedures.
  @ContentHelp('Ongoing risk monitoring activities, status reviews, '
      'and control effectiveness assessments.')
  TextSection monitoringProcedures = TextSection();

  /// Risk response strategies by category.
  @ContentHelp('Standard response approaches: avoid, mitigate, '
      'transfer, accept — with criteria for each.')
  TextSection responseStrategies = TextSection();

  /// Risk aggregation and portfolio view.
  @ContentHelp('How individual system risks roll up to program level, '
      'correlation analysis, compound risk assessment.')
  TextSection riskAggregation = TextSection();

  /// Risk matrix / heat map visualization.
  @ContentHelp('Probability × Impact matrix showing risk distribution.')
  DiagramSection riskMatrix = DiagramSection();

  /// Risk timeline showing risk exposure over migration phases.
  @ContentHelp('Timeline showing when risks are highest and mitigation points.')
  GanttDiagramSection riskTimeline = GanttDiagramSection();

  /// Contains 0+× MigrationRiskEntry.
  @SectionIdPattern('PD00-SYO-SYR-MIG-RIS-xx')
  List<MigrationRiskEntry> items = [];
}

/// A migration risk entry (form) [PD00-SYO-SYR-MIG-RIS-nn].
///
/// Detailed migration risk documentation following enterprise risk
/// management practices. Captures full risk lifecycle from identification
/// through resolution.
class MigrationRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID', required: true,
        hint: 'Unique identifier (e.g., MIG-RISK-001)'),
    Field('riskTitle', String, 'Risk Title', required: true,
        hint: 'Concise risk name'),
    Field('riskOwner', String, 'Risk Owner', required: true,
        hint: 'Accountable for risk management'),
  ])
  String? content;

  /// Risk identification details.
  final MigrationRiskIdentification identification =
      MigrationRiskIdentification();

  /// Probability assessment.
  final MigrationRiskProbability probability = MigrationRiskProbability();

  /// Impact assessment.
  final MigrationRiskImpact impact = MigrationRiskImpact();

  /// Risk quantification.
  final MigrationRiskQuantification quantification =
      MigrationRiskQuantification();

  /// Mitigation strategy.
  final MigrationRiskMitigation mitigation = MigrationRiskMitigation();

  /// Contingency planning.
  final MigrationRiskContingency contingency = MigrationRiskContingency();

  /// Risk indicators and monitoring.
  final MigrationRiskIndicators indicators = MigrationRiskIndicators();

  /// Ownership and tracking.
  final MigrationRiskTracking tracking = MigrationRiskTracking();

  /// Related items.
  final MigrationRiskRelated related = MigrationRiskRelated();

  /// History and lessons learned.
  final MigrationRiskHistory history = MigrationRiskHistory();

  /// Additional risk analysis narrative.
  @ContentHelp('Extended risk analysis, scenario modeling, '
      'or historical context.')
  TextSection analysisNarrative = TextSection();

  /// Mitigation action items (detailed).
  @ContentHelp('Detailed breakdown of mitigation action items '
      'with owners and deadlines.')
  TextSection mitigationDetails = TextSection();
}

/// Risk identification details.
class MigrationRiskIdentification {
  @Form([
    Field('riskDescription', String, 'Risk Description', required: true,
        hint: 'Detailed description of the risk event'),
    Field('riskCategory', String, 'Risk Category',
        hint: 'Technical, schedule, resource, business, regulatory'),
    Field('riskSubcategory', String, 'Risk Subcategory',
        hint: 'More specific categorization'),
    Field('identifiedDate', String, 'Identified Date'),
    Field('identifiedBy', String, 'Identified By',
        hint: 'Person/role who identified the risk'),
    Field('identificationMethod', String, 'Identification Method',
        hint: 'Workshop, review, incident, expert judgment'),
    Field('affectedSystems', String, 'Affected Systems',
        hint: 'List of systems impacted'),
    Field('affectedPhases', String, 'Affected Phases',
        hint: 'Migration phases where risk applies'),
    Field('affectedStreams', String, 'Affected Workstreams',
        hint: 'Data, application, infrastructure, etc.'),
  ])
  String? content;
}

/// Probability assessment for migration risk.
class MigrationRiskProbability {
  @Form([
    Field('probabilityRating', String, 'Probability Rating',
        hint: 'Very High (>80%), High (60-80%), Medium (40-60%), Low (20-40%), Very Low (<20%)'),
    Field('probabilityScore', int, 'Probability Score (1-5)',
        hint: 'Numeric score for calculations'),
    Field('probabilityRationale', String, 'Probability Rationale',
        hint: 'Why this probability was assigned'),
    Field('probabilityTrend', String, 'Probability Trend',
        hint: 'Increasing, stable, decreasing'),
  ])
  String? content;
}

/// Impact assessment for migration risk.
class MigrationRiskImpact {
  @Form([
    Field('overallImpactRating', String, 'Overall Impact Rating',
        hint: 'Critical, High, Medium, Low, Minimal'),
    Field('overallImpactScore', int, 'Overall Impact Score (1-5)'),
    Field('scheduleImpact', String, 'Schedule Impact',
        hint: 'Days/weeks delay if risk materializes'),
    Field('scheduleImpactScore', int, 'Schedule Impact Score'),
    Field('costImpact', String, 'Cost Impact',
        hint: 'Budget impact if risk materializes'),
    Field('costImpactScore', int, 'Cost Impact Score'),
    Field('businessImpact', String, 'Business Impact',
        hint: 'Business disruption level'),
    Field('businessImpactScore', int, 'Business Impact Score'),
    Field('reputationImpact', String, 'Reputation Impact',
        hint: 'Customer/market perception impact'),
    Field('dataIntegrityImpact', String, 'Data Integrity Impact',
        hint: 'Risk to data quality/completeness'),
    Field('complianceImpact', String, 'Compliance Impact',
        hint: 'Regulatory/audit implications'),
    Field('impactRationale', String, 'Impact Rationale',
        hint: 'Justification for impact assessment'),
  ])
  String? content;
}

/// Risk quantification for migration risk.
class MigrationRiskQuantification {
  @Form([
    Field('riskScore', int, 'Risk Score',
        hint: 'Probability × Impact (1-25)'),
    Field('riskPriority', String, 'Risk Priority',
        hint: 'Critical, High, Medium, Low'),
    Field('expectedMonetaryValue', String, 'Expected Monetary Value (EMV)',
        hint: 'P × Cost Impact'),
    Field('worstCaseScenario', String, 'Worst Case Scenario',
        hint: 'Maximum potential impact'),
    Field('bestCaseScenario', String, 'Best Case Scenario',
        hint: 'Minimum impact if mitigated'),
    Field('mostLikelyScenario', String, 'Most Likely Scenario'),
  ])
  String? content;
}

/// Mitigation strategy for migration risk.
class MigrationRiskMitigation {
  @Form([
    Field('responseStrategy', String, 'Response Strategy',
        hint: 'Avoid, mitigate, transfer, accept'),
    Field('mitigationDescription', String, 'Mitigation Strategy',
        hint: 'Primary mitigation approach'),
    Field('mitigationActions', String, 'Mitigation Actions',
        hint: 'Specific actions to reduce risk'),
    Field('mitigationOwner', String, 'Mitigation Owner',
        hint: 'Responsible for mitigation execution'),
    Field('mitigationDueDate', String, 'Mitigation Due Date'),
    Field('mitigationCost', String, 'Mitigation Cost',
        hint: 'Cost to implement mitigation'),
    Field('mitigationStatus', String, 'Mitigation Status',
        hint: 'Not started, in progress, completed'),
    Field('residualProbability', String, 'Residual Probability',
        hint: 'Probability after mitigation'),
    Field('residualImpact', String, 'Residual Impact',
        hint: 'Impact after mitigation'),
    Field('residualRiskScore', int, 'Residual Risk Score',
        hint: 'Risk score after mitigation'),
  ])
  String? content;
}

/// Contingency planning for migration risk.
class MigrationRiskContingency {
  @Form([
    Field('contingencyPlan', String, 'Contingency Plan',
        hint: 'Actions if risk materializes'),
    Field('contingencyTrigger', String, 'Contingency Trigger',
        hint: 'What triggers contingency execution'),
    Field('contingencyOwner', String, 'Contingency Owner'),
    Field('contingencyBudget', String, 'Contingency Budget',
        hint: 'Reserved budget for contingency'),
    Field('rollbackProcedure', String, 'Rollback Procedure',
        hint: 'Steps to revert if risk realized'),
    Field('recoveryTimeObjective', String, 'Recovery Time Objective',
        hint: 'Time to recover from risk event'),
  ])
  String? content;
}

/// Risk indicators and monitoring.
class MigrationRiskIndicators {
  @Form([
    Field('earlyWarningIndicators', String, 'Early Warning Indicators',
        hint: 'Signs risk is about to materialize'),
    Field('riskTriggers', String, 'Risk Triggers',
        hint: 'Events that would realize the risk'),
    Field('keyRiskIndicators', String, 'Key Risk Indicators (KRIs)',
        hint: 'Metrics to monitor risk'),
    Field('monitoringFrequency', String, 'Monitoring Frequency',
        hint: 'How often KRIs are checked'),
    Field('thresholdValues', String, 'Threshold Values',
        hint: 'Limits that trigger escalation'),
  ])
  String? content;
}

/// Ownership and tracking for migration risk.
class MigrationRiskTracking {
  @Form([
    Field('riskDelegate', String, 'Risk Delegate',
        hint: 'Day-to-day risk monitoring'),
    Field('escalationContact', String, 'Escalation Contact',
        hint: 'Escalation point if risk increases'),
    Field('status', String, 'Risk Status',
        hint: 'Open, mitigating, closed, realized, transferred'),
    Field('statusDate', String, 'Status Date',
        hint: 'Last status update'),
    Field('statusNotes', String, 'Status Notes',
        hint: 'Current status commentary'),
    Field('nextReviewDate', String, 'Next Review Date'),
    Field('closureDate', String, 'Closure Date',
        hint: 'When risk was closed'),
    Field('closureReason', String, 'Closure Reason',
        hint: 'Why risk was closed: mitigated, accepted, transferred, expired'),
  ])
  String? content;
}

/// Related items for migration risk.
class MigrationRiskRelated {
  @Form([
    Field('relatedRisks', String, 'Related Risks',
        hint: 'Risk IDs that are correlated'),
    Field('relatedIssues', String, 'Related Issues',
        hint: 'Issue IDs linked to this risk'),
    Field('relatedRequirements', String, 'Related Requirements',
        hint: 'Requirements impacted by risk'),
    Field('relatedDecisions', String, 'Related Decisions',
        hint: 'Decisions affecting this risk'),
    Field('dependencyChain', String, 'Dependency Chain',
        hint: 'Other risks this depends on'),
  ])
  String? content;
}

/// History and lessons learned for migration risk.
class MigrationRiskHistory {
  @Form([
    Field('previousScores', String, 'Previous Scores',
        hint: 'History of risk scores'),
    Field('previousStatuses', String, 'Previous Statuses',
        hint: 'Status change history'),
    Field('lessonsLearned', String, 'Lessons Learned',
        hint: 'Insights from risk handling'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5 System Boundaries (seeds → BSI)
// ---------------------------------------------------------------------------

/// 4.5. System Boundaries [PD00-SYO-SYB]. Seeds → BSI.
///
/// Defines the scope boundaries of the system including external interfaces,
/// out-of-scope items, and operating assumptions. This section provides the
/// foundation for integration planning and scope management. Follows TOGAF
/// system context patterns and enterprise integration best practices.
@SectionId('PD00-SYO-SYB')
@Comment('Seeds → BSI')
class SystemBoundaries {
  /// Overview of system boundaries and scope definition approach.
  @ContentHelp('Provide executive summary of system boundaries: '
      'integration count, scope philosophy, and boundary governance approach.')
  TextSection overview = TextSection();

  /// 4.5.1. Interfaces to External Systems [PD00-SYO-SYB-INT] — contains 0+×.
  ExternalInterfaces externalInterfaces = ExternalInterfaces();

  /// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT] — contains 0+×.
  OutOfScope outOfScope = OutOfScope();

  /// 4.5.3. Assumptions [PD00-SYO-SYB-ASS] — contains 0+×.
  BoundaryAssumptions assumptions = BoundaryAssumptions();
}

// ---------------------------------------------------------------------------
// 4.5.1. External Interfaces
// ---------------------------------------------------------------------------

/// Container for external interface definitions [PD00-SYO-SYB-INT].
///
/// Provides structured inventory of all external system integrations with
/// categorization, prioritization, and governance information. Each interface
/// seeds detailed specification in the BSI (Business System Interactions)
/// document. Follows enterprise integration patterns (EIP) and API-first
/// design principles.
@SectionId('PD00-SYO-SYB-INT')
class ExternalInterfaces {
  /// Summary of the integration landscape.
  @ContentHelp('Summarize integration portfolio: total count by category, '
      'strategic vs tactical integrations, integration platform approach.')
  TextSection integrationSummary = TextSection();

  /// Integration architecture approach.
  @ContentHelp('Describe integration patterns: point-to-point vs hub, '
      'synchronous vs async, API gateway usage, message broker approach.')
  TextSection architectureApproach = TextSection();

  /// Integration governance model.
  @ContentHelp('Describe integration governance: ownership model, '
      'change control process, versioning strategy, deprecation policy.')
  TextSection governanceModel = TextSection();

  /// Contains 0+× ExternalInterfaceEntry.
  @SectionIdPattern('PD00-SYO-SYB-INT-xx')
  List<ExternalInterfaceEntry> interfaces = [];
}

/// An external interface entry [PD00-SYO-SYB-INT-nn] (form).
///
/// Comprehensive documentation of an external system interface covering
/// identification, technical details, data exchange specification, security,
/// operational characteristics, and contractual governance. Follows
/// OpenAPI/AsyncAPI patterns for API documentation and enterprise
/// integration best practices.
class ExternalInterfaceEntry {
  // -------------------------------------------------------------------------
  // Interface Identification
  // -------------------------------------------------------------------------

  @Form([
    Field('interfaceId', String, 'Interface ID (e.g., IF-PAY-001)',
        required: true),
    Field('interfaceName', String, 'Interface Name', required: true),
    Field('externalSystem', String, 'External System Name', required: true),
    Field('externalSystemVendor', String, 'Vendor/Provider'),
    Field('interfaceCategory', String,
        'Category (Payment, Identity, Data, Messaging, etc.)'),
    Field('integrationPattern', String,
        'Pattern (Request-Reply, Fire-and-Forget, Pub-Sub, Event-Driven)'),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)'),
    Field('status', String, 'Status (Existing, New, To be replaced)'),
  ])
  String? identificationContent;

  /// Business purpose and value of this interface.
  InterfaceBusinessContext businessContext = InterfaceBusinessContext();

  // -------------------------------------------------------------------------
  // Technical Specification
  // -------------------------------------------------------------------------

  /// Technical details of the interface.
  InterfaceTechnicalSpec technicalSpec = InterfaceTechnicalSpec();

  // -------------------------------------------------------------------------
  // Data Specification
  // -------------------------------------------------------------------------

  /// Data exchange specification.
  InterfaceDataSpec dataSpec = InterfaceDataSpec();

  // -------------------------------------------------------------------------
  // Security & Authentication
  // -------------------------------------------------------------------------

  /// Security and authentication requirements.
  InterfaceSecurity security = InterfaceSecurity();

  // -------------------------------------------------------------------------
  // Operational Characteristics
  // -------------------------------------------------------------------------

  /// Operational and SLA requirements.
  InterfaceOperational operational = InterfaceOperational();

  // -------------------------------------------------------------------------
  // Error Handling
  // -------------------------------------------------------------------------

  /// Error handling and resilience.
  InterfaceErrorHandling errorHandling = InterfaceErrorHandling();

  // -------------------------------------------------------------------------
  // Governance & Contracts
  // -------------------------------------------------------------------------

  /// Contractual and governance information.
  InterfaceGovernance governance = InterfaceGovernance();

  // -------------------------------------------------------------------------
  // Testing & Environments
  // -------------------------------------------------------------------------

  /// Testing and environment information.
  InterfaceTesting testing = InterfaceTesting();
}

/// Business context for an interface [PD00-SYO-SYB-INT-nn-BUS].
@SectionId('PD00-SYO-SYB-INT-xx-BUS')
class InterfaceBusinessContext {
  @Form([
    Field('businessPurpose', String, 'Business Purpose'),
    Field('businessValue', String, 'Business Value'),
    Field('businessOwner', String, 'Business Owner'),
    Field('useCases', String, 'Primary Use Cases'),
    Field('businessCriticality', String,
        'Criticality (Mission Critical, Business Critical, Operational)'),
    Field('revenueImpact', String, 'Revenue Impact (Direct, Indirect, None)'),
    Field('regulatoryDriver', String, 'Regulatory/Compliance Driver'),
  ])
  String? content;

  /// Business processes that depend on this interface.
  @SectionIdPattern('PD00-SYO-SYB-INT-xx-BUS-BP-xx')
  List<InterfaceBusinessProcessEntry> dependentProcesses = [];
}

/// Business process dependency entry [PD00-SYO-SYB-INT-nn-BUS-BP-nn].
class InterfaceBusinessProcessEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('processId', String, 'Process ID'),
    Field('dependencyType', String, 'Dependency (Critical Path, Supporting)'),
    Field('fallbackBehavior', String, 'Fallback if Interface Unavailable'),
  ])
  String? content;
}

/// Technical specification for an interface [PD00-SYO-SYB-INT-nn-TEC].
@SectionId('PD00-SYO-SYB-INT-xx-TEC')
class InterfaceTechnicalSpec {
  @Form([
    // Protocol & Transport
    Field('protocol', String,
        'Protocol (REST/HTTPS, SOAP/HTTPS, gRPC, GraphQL, SFTP, etc.)'),
    Field('transportSecurity', String, 'Transport Security (TLS 1.2, TLS 1.3)'),
    Field('messageFormat', String, 'Message Format (JSON, XML, Protobuf, CSV)'),
    Field('encoding', String, 'Character Encoding (UTF-8, etc.)'),

    // Direction & Pattern
    Field('direction', String, 'Direction (Inbound, Outbound, Bidirectional)'),
    Field('initiator', String, 'Initiator (Our System, External System)'),
    Field('communicationStyle', String,
        'Style (Synchronous, Asynchronous, Event-Driven)'),
    Field('deliveryGuarantee', String,
        'Delivery (At-most-once, At-least-once, Exactly-once)'),

    // Endpoints
    Field('baseEndpoint', String, 'Base URL/Endpoint'),
    Field('apiVersion', String, 'API Version'),
    Field('documentationUrl', String, 'API Documentation URL'),
    Field('sandboxEndpoint', String, 'Sandbox/Test Endpoint'),
  ])
  String? content;

  /// API operations/methods exposed or consumed.
  @SectionIdPattern('PD00-SYO-SYB-INT-xx-TEC-OP-xx')
  List<InterfaceOperationEntry> operations = [];

  /// Webhook/callback configurations if applicable.
  InterfaceWebhookSpec webhookSpec = InterfaceWebhookSpec();
}

/// API operation entry [PD00-SYO-SYB-INT-nn-TEC-OP-nn].
class InterfaceOperationEntry {
  @Form([
    Field('operationId', String, 'Operation ID', required: true),
    Field('operationName', String, 'Operation Name', required: true),
    Field('httpMethod', String, 'HTTP Method (GET, POST, PUT, DELETE, etc.)'),
    Field('path', String, 'Path/Endpoint'),
    Field('purpose', String, 'Purpose'),
    Field('idempotent', bool, 'Idempotent'),
    Field('requestFormat', String, 'Request Format'),
    Field('responseFormat', String, 'Response Format'),
    Field('paginationSupport', bool, 'Pagination Supported'),
    Field('filteringSupport', String, 'Filtering/Query Parameters'),
  ])
  String? content;
}

/// Webhook specification [PD00-SYO-SYB-INT-nn-TEC-WH].
@SectionId('PD00-SYO-SYB-INT-xx-TEC-WH')
class InterfaceWebhookSpec {
  @Form([
    Field('webhooksUsed', bool, 'Webhooks/Callbacks Used'),
    Field('webhookEndpoint', String, 'Our Webhook Endpoint'),
    Field('eventTypes', String, 'Event Types Received'),
    Field('signatureVerification', String, 'Signature Verification Method'),
    Field('retryPolicy', String, 'External System Retry Policy'),
    Field('idempotencyHandling', String, 'Idempotency Handling'),
  ])
  String? content;
}

/// Data specification for an interface [PD00-SYO-SYB-INT-nn-DAT].
@SectionId('PD00-SYO-SYB-INT-xx-DAT')
class InterfaceDataSpec {
  @Form([
    // Data Exchange Overview
    Field('dataExchangeSummary', String, 'Data Exchange Summary'),
    Field('dataDirection', String,
        'Data Flow (Send, Receive, Bidirectional)'),
    Field('dataSensitivity', String,
        'Sensitivity (Public, Internal, Confidential, PII/PHI)'),
    Field('dataRetentionExternal', String, 'External System Data Retention'),

    // Volume & Frequency
    Field('frequency', String,
        'Frequency (Real-time, Near real-time, Batch, On-demand)'),
    Field('batchSchedule', String, 'Batch Schedule (if applicable)'),
    Field('volumePerTransaction', String, 'Volume per Transaction'),
    Field('dailyVolume', String, 'Expected Daily Volume'),
    Field('peakVolume', String, 'Peak Volume'),
    Field('payloadSizeLimit', String, 'Payload Size Limit'),
  ])
  String? content;

  /// Data entities exchanged.
  @SectionIdPattern('PD00-SYO-SYB-INT-xx-DAT-ENT-xx')
  List<InterfaceDataEntityEntry> dataEntities = [];

  /// Data mapping and transformation rules.
  TextSection mappingRules = TextSection();

  /// Data validation rules.
  TextSection validationRules = TextSection();
}

/// Data entity exchanged [PD00-SYO-SYB-INT-nn-DAT-ENT-nn].
class InterfaceDataEntityEntry {
  @Form([
    Field('entityName', String, 'Entity Name', required: true),
    Field('direction', String, 'Direction (Send, Receive)'),
    Field('fieldCount', int, 'Field Count'),
    Field('requiredFields', String, 'Required Fields'),
    Field('sensitiveFields', String, 'Sensitive Fields (PII, etc.)'),
    Field('internalMapping', String, 'Maps to Internal Entity'),
    Field('transformationNeeded', String, 'Transformation Required'),
  ])
  String? content;
}

/// Security specification for an interface [PD00-SYO-SYB-INT-nn-SEC].
@SectionId('PD00-SYO-SYB-INT-xx-SEC')
class InterfaceSecurity {
  @Form([
    // Authentication
    Field('authMethod', String,
        'Authentication (API Key, OAuth 2.0, mTLS, Basic, SAML, etc.)'),
    Field('authDetails', String, 'Authentication Details'),
    Field('credentialStorage', String, 'Credential Storage Method'),
    Field('credentialRotation', String, 'Credential Rotation Policy'),

    // Authorization
    Field('authorizationModel', String, 'Authorization Model'),
    Field('scopesPermissions', String, 'Scopes/Permissions Required'),
    Field('ipWhitelisting', String, 'IP Whitelisting Required'),

    // Encryption
    Field('encryptionInTransit', String, 'Encryption in Transit'),
    Field('encryptionAtRest', String, 'Encryption at Rest (if applicable)'),
    Field('fieldLevelEncryption', String, 'Field-Level Encryption'),

    // Compliance
    Field('complianceRequirements', String,
        'Compliance (PCI-DSS, HIPAA, GDPR, SOC2, etc.)'),
    Field('auditLogging', String, 'Audit Logging Requirements'),
    Field('dataResidency', String, 'Data Residency Requirements'),
  ])
  String? content;

  /// Security contacts and escalation.
  TextSection securityContacts = TextSection();
}

/// Operational characteristics [PD00-SYO-SYB-INT-nn-OPS].
@SectionId('PD00-SYO-SYB-INT-xx-OPS')
class InterfaceOperational {
  @Form([
    // Availability & SLA
    Field('availabilitySla', String, 'Availability SLA (e.g., 99.9%)'),
    Field('scheduledDowntime', String, 'Scheduled Downtime Windows'),
    Field('responseTimeSla', String, 'Response Time SLA (e.g., p95 < 200ms)'),
    Field('throughputSla', String, 'Throughput SLA'),

    // Rate Limiting
    Field('rateLimits', String, 'Rate Limits (requests/minute)'),
    Field('quotaLimits', String, 'Quota Limits (requests/day)'),
    Field('burstCapacity', String, 'Burst Capacity'),

    // Monitoring
    Field('healthCheckEndpoint', String, 'Health Check Endpoint'),
    Field('statusPageUrl', String, 'Status Page URL'),
    Field('monitoringApproach', String, 'Monitoring Approach'),
    Field('alertingThresholds', String, 'Alerting Thresholds'),

    // Support
    Field('supportHours', String, 'Support Hours'),
    Field('supportContact', String, 'Support Contact'),
    Field('incidentProcess', String, 'Incident Process'),
    Field('escalationPath', String, 'Escalation Path'),
  ])
  String? content;

  /// Operational dependencies.
  TextSection dependencies = TextSection();
}

/// Error handling specification [PD00-SYO-SYB-INT-nn-ERR].
@SectionId('PD00-SYO-SYB-INT-xx-ERR')
class InterfaceErrorHandling {
  @Form([
    // Error Responses
    Field('errorFormat', String, 'Error Response Format'),
    Field('errorCodes', String, 'Error Codes Used'),
    Field('retryableErrors', String, 'Retryable Error Codes'),
    Field('fatalErrors', String, 'Fatal/Non-Retryable Errors'),

    // Retry Strategy
    Field('retryStrategy', String, 'Retry Strategy (Exponential backoff, etc.)'),
    Field('maxRetries', int, 'Max Retries'),
    Field('retryInterval', String, 'Retry Interval'),
    Field('circuitBreakerConfig', String, 'Circuit Breaker Configuration'),

    // Fallback
    Field('fallbackBehavior', String, 'Fallback Behavior'),
    Field('degradedMode', String, 'Degraded Mode Operation'),
    Field('manualRecovery', String, 'Manual Recovery Procedure'),

    // Timeout
    Field('connectionTimeout', String, 'Connection Timeout'),
    Field('readTimeout', String, 'Read Timeout'),
    Field('overallTimeout', String, 'Overall Transaction Timeout'),
  ])
  String? content;

  /// Error handling procedures.
  TextSection errorProcedures = TextSection();
}

/// Governance and contracts [PD00-SYO-SYB-INT-nn-GOV].
@SectionId('PD00-SYO-SYB-INT-xx-GOV')
class InterfaceGovernance {
  @Form([
    // Ownership
    Field('externalOwner', String, 'External System Owner'),
    Field('internalOwner', String, 'Internal Owner/Steward'),
    Field('technicalContact', String, 'Technical Contact'),
    Field('businessContact', String, 'Business Contact'),

    // Contracts
    Field('contractType', String, 'Contract Type (SLA, Agreement, Partnership)'),
    Field('contractExpiry', String, 'Contract Expiry Date'),
    Field('renewalTerms', String, 'Renewal Terms'),
    Field('costModel', String, 'Cost Model (Per-call, Subscription, etc.)'),
    Field('estimatedCost', String, 'Estimated Monthly/Annual Cost'),

    // Change Management
    Field('versioningStrategy', String, 'Versioning Strategy'),
    Field('deprecationPolicy', String, 'Deprecation Policy'),
    Field('changeNotificationLead', String, 'Change Notification Lead Time'),
    Field('breakingChangePolicy', String, 'Breaking Change Policy'),
  ])
  String? content;

  /// Integration changelog.
  TextSection changelog = TextSection();
}

/// Testing specification [PD00-SYO-SYB-INT-nn-TST].
@SectionId('PD00-SYO-SYB-INT-xx-TST')
class InterfaceTesting {
  @Form([
    // Test Environments
    Field('sandboxAvailable', bool, 'Sandbox Environment Available'),
    Field('sandboxUrl', String, 'Sandbox URL'),
    Field('testCredentials', String, 'Test Credentials Approach'),
    Field('mockAvailable', bool, 'Mock/Stub Available'),

    // Test Data
    Field('testDataApproach', String, 'Test Data Approach'),
    Field('syntheticDataSupport', bool, 'Synthetic Data Supported'),
    Field('productionMirror', bool, 'Production Data Mirroring'),

    // Testing Strategy
    Field('unitTestApproach', String, 'Unit Test Approach'),
    Field('integrationTestApproach', String, 'Integration Test Approach'),
    Field('contractTestApproach', String, 'Contract Test Approach'),
    Field('e2eTestApproach', String, 'E2E Test Approach'),
    Field('performanceTestApproach', String, 'Performance Test Approach'),
  ])
  String? content;

  /// Test scenarios.
  @SectionIdPattern('PD00-SYO-SYB-INT-xx-TST-SC-xx')
  List<InterfaceTestScenarioEntry> testScenarios = [];
}

/// Test scenario entry [PD00-SYO-SYB-INT-nn-TST-SC-nn].
class InterfaceTestScenarioEntry {
  @Form([
    Field('scenarioId', String, 'Scenario ID', required: true),
    Field('scenarioName', String, 'Scenario Name', required: true),
    Field('scenarioType', String, 'Type (Happy Path, Error, Edge Case)'),
    Field('preconditions', String, 'Preconditions'),
    Field('testSteps', String, 'Test Steps'),
    Field('expectedResult', String, 'Expected Result'),
    Field('automated', bool, 'Automated'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.2. Out of Scope
// ---------------------------------------------------------------------------

/// 4.5.2. Out of Scope [PD00-SYO-SYB-OUT].
///
/// Explicit documentation of functionality, systems, and integrations that
/// are excluded from the project scope. Provides clear boundaries and
/// rationale to prevent scope creep and manage stakeholder expectations.
@SectionId('PD00-SYO-SYB-OUT')
class OutOfScope {
  /// Overview of scope exclusion approach.
  @ContentHelp('Describe the scope philosophy and how exclusions were '
      'determined. Reference any scope workshops or decision records.')
  TextSection scopePhilosophy = TextSection();

  /// Contains 0+× OutOfScopeEntry.
  @SectionIdPattern('PD00-SYO-SYB-OUT-xx')
  List<OutOfScopeEntry> items = [];
}

/// An out-of-scope entry [PD00-SYO-SYB-OUT-nn] (form).
class OutOfScopeEntry {
  @Form([
    Field('itemId', String, 'Item ID'),
    Field('item', String, 'Out of Scope Item', required: true),
    Field('itemType', String,
        'Type (Feature, Integration, System, Process, Data)'),
    Field('rationale', String, 'Exclusion Rationale'),
    Field('requestedBy', String, 'Originally Requested By'),
    Field('decisionMaker', String, 'Decision Maker'),
    Field('decisionDate', String, 'Decision Date'),
    Field('futureConsideration', String,
        'Future Consideration (Yes, No, Maybe)'),
    Field('targetPhase', String, 'Target Phase (if future)'),
    Field('alternativeSolution', String, 'Alternative/Workaround'),
    Field('riskIfIncluded', String, 'Risk if Included'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.3. Assumptions
// ---------------------------------------------------------------------------

/// 4.5.3. Assumptions [PD00-SYO-SYB-ASS].
///
/// Documents assumptions about external systems, data availability,
/// organizational readiness, and third-party services that must hold true
/// for the project to succeed. Each assumption should be validated and
/// tracked as a potential risk if proven incorrect.
@SectionId('PD00-SYO-SYB-ASS')
class BoundaryAssumptions {
  /// Overview of assumption categories and validation approach.
  @ContentHelp('Describe assumption categories, validation timeline, '
      'and impact assessment approach for assumption failures.')
  TextSection assumptionApproach = TextSection();

  /// Contains 0+× BoundaryAssumptionEntry.
  @SectionIdPattern('PD00-SYO-SYB-ASS-xx')
  List<BoundaryAssumptionEntry> items = [];
}

/// A boundary assumption entry [PD00-SYO-SYB-ASS-nn] (form).
class BoundaryAssumptionEntry {
  @Form([
    Field('assumptionId', String, 'Assumption ID'),
    Field('assumption', String, 'Assumption Statement', required: true),
    Field('category', String,
        'Category (Technical, Organizational, External, Data, Resource)'),
    Field('rationale', String, 'Basis for Assumption'),
    Field('owner', String, 'Assumption Owner'),
    Field('validationMethod', String, 'Validation Method'),
    Field('validationDate', String, 'Target Validation Date'),
    Field('validationStatus', String,
        'Status (Not Validated, Validated, Invalidated)'),
    Field('confidence', String, 'Confidence Level (High, Medium, Low)'),
    Field('riskIfWrong', String, 'Risk if Wrong'),
    Field('riskImpact', String, 'Impact Level (High, Medium, Low)'),
    Field('contingencyPlan', String, 'Contingency Plan'),
    Field('relatedRiskId', String, 'Related Risk ID'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.6 Framework Conditions
// ---------------------------------------------------------------------------

/// 4.6. Framework Conditions [PD00-SYO-RES].
///
/// Documents the organizational and technical environment in which the system
/// will operate. Covers organizational structure, functional responsibilities,
/// technical constraints, and external dependencies. Follows TOGAF enterprise
/// context patterns and PMBOK environmental factors analysis.
@SectionId('PD00-SYO-RES')
class FrameworkConditions {
  /// Framework conditions overview.
  @ContentHelp('Provide executive summary of the operating environment: '
      'organizational context, technical landscape, key constraints, '
      'and critical dependencies affecting project execution.')
  TextSection overview = TextSection();

  /// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
  OrganizationalEnvironment organizationalEnvironment =
      OrganizationalEnvironment();

  /// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN] — contains 0+×.
  FunctionalResponsibilities functionalResponsibilities =
      FunctionalResponsibilities();

  /// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
  @Comment('Seeds → TR')
  TechnicalFrameworkConditions technicalFrameworkConditions =
      TechnicalFrameworkConditions();

  /// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON] — contains 0+×.
  ConstraintsAndDependencies constraintsAndDependencies =
      ConstraintsAndDependencies();
}

/// 4.6.1. Organizational Environment [PD00-SYO-RES-ORG].
///
/// Describes the organizational context in which the system will operate,
/// including departments, reporting structures, decision authority, and
/// organizational constraints. Follows organizational design principles
/// and enterprise architecture governance patterns.
@SectionId('PD00-SYO-RES-ORG')
class OrganizationalEnvironment {
  // -------------------------------------------------------------------------
  // Organizational Overview
  // -------------------------------------------------------------------------
  @Form([
    // Enterprise Context
    Field('organizationName', String, 'Organization Name'),
    Field('organizationType', String,
        'Organization Type (Enterprise, SMB, Startup, Government, Non-profit)'),
    Field('industryVertical', String,
        'Industry Vertical (Finance, Healthcare, Retail, Tech, etc.)'),
    Field('geographicFootprint', String,
        'Geographic Footprint (Local, National, Regional, Global)'),
    Field('employeeCount', String, 'Employee Count'),
    Field('revenueRange', String, 'Revenue Range'),

    // Organizational Maturity
    Field('digitalMaturityLevel', String,
        'Digital Maturity (Nascent, Developing, Defined, Optimizing, Leading)'),
    Field('changeReadiness', String,
        'Change Readiness (Low, Medium, High)'),
    Field('projectManagementMaturity', String,
        'PM Maturity (Ad-hoc, Repeatable, Defined, Managed, Optimizing)'),
    Field('itGovernanceMaturity', String,
        'IT Governance Maturity (Initial, Repeatable, Defined, Managed)'),

    // Decision Making Context
    Field('decisionMakingStyle', String,
        'Decision Style (Centralized, Federated, Consensus, Delegated)'),
    Field('approvalLevels', String, 'Approval Levels/Hierarchy'),
    Field('escalationPath', String, 'Escalation Path'),
    Field('budgetAuthority', String, 'Budget Authority Structure'),
    Field('procurementProcess', String, 'Procurement Process Type'),
  ])
  String? organizationContent;

  // -------------------------------------------------------------------------
  // Organizational Structure
  // -------------------------------------------------------------------------

  /// Detailed organizational structure narrative.
  @ContentHelp('Describe the organizational structure: departments involved, '
      'reporting relationships, matrix structures, and how the project '
      'intersects with existing organization.')
  TextSection structure = TextSection();

  /// Departments and business units affected.
  @SectionIdPattern('PD00-SYO-RES-ORG-DEP-xx')
  List<AffectedDepartmentEntry> affectedDepartments = [];

  // -------------------------------------------------------------------------
  // Decision Making & Governance
  // -------------------------------------------------------------------------

  /// Decision making processes and authority.
  @ContentHelp('Describe decision-making processes: governance boards, '
      'approval workflows, decision criteria, and timeline expectations '
      'for different decision types.')
  TextSection decisionMaking = TextSection();

  /// Key decision makers and their roles.
  @SectionIdPattern('PD00-SYO-RES-ORG-DEC-xx')
  List<DecisionMakerEntry> decisionMakers = [];

  // -------------------------------------------------------------------------
  // Cultural Context
  // -------------------------------------------------------------------------

  /// Cultural considerations and organizational dynamics.
  @ContentHelp('Describe cultural factors: risk tolerance, innovation appetite, '
      'collaboration patterns, communication preferences, and change '
      'management considerations.')
  TextSection culturalConsiderations = TextSection();

  /// Stakeholder communication preferences.
  @ContentHelp('Describe stakeholder communication preferences: formal vs '
      'informal, frequency, channels, and reporting expectations.')
  TextSection communicationPreferences = TextSection();

  // -------------------------------------------------------------------------
  // Political Landscape
  // -------------------------------------------------------------------------

  /// Political dynamics and influence patterns.
  @ContentHelp('Describe organizational politics: power centers, influence '
      'networks, historical project outcomes, and potential resistance points.')
  TextSection politicalLandscape = TextSection();

  /// Change champions and sponsors.
  @ContentHelp('Identify change champions, executive sponsors, and influential '
      'stakeholders who can advocate for the project.')
  TextSection changeAdvocates = TextSection();
}

/// An affected department entry [PD00-SYO-RES-ORG-DEP-nn].
class AffectedDepartmentEntry {
  @Form([
    Field('departmentName', String, 'Department Name', required: true),
    Field('departmentHead', String, 'Department Head'),
    Field('employeeCount', int, 'Employee Count'),
    Field('impactLevel', String, 'Impact Level (High, Medium, Low)'),
    Field('roleInProject', String,
        'Role (Sponsor, User, Data Owner, Operations, Support)'),
    Field('currentSystems', String, 'Current Systems Used'),
    Field('changeReadiness', String, 'Change Readiness (High, Medium, Low)'),
    Field('keyContacts', String, 'Key Contacts'),
    Field('specialConsiderations', String, 'Special Considerations'),
  ])
  String? content;
}

/// A decision maker entry [PD00-SYO-RES-ORG-DEC-nn].
class DecisionMakerEntry {
  @Form([
    Field('name', String, 'Name', required: true),
    Field('title', String, 'Title/Role'),
    Field('department', String, 'Department'),
    Field('decisionAuthority', String,
        'Authority (Executive Sponsor, Steering Committee, Budget Owner, etc.)'),
    Field('decisionDomains', String,
        'Decision Domains (Scope, Budget, Timeline, Technology, Resources)'),
    Field('influenceLevel', String, 'Influence Level (High, Medium, Low)'),
    Field('approvalRequired', String, 'Approval Required For'),
    Field('availabilityConstraints', String, 'Availability/Constraints'),
    Field('stakeholderAlignment', String,
        'Stakeholder Alignment (Supportive, Neutral, Skeptical)'),
    Field('communicationPreference', String, 'Communication Preference'),
  ])
  String? content;
}

/// 4.6.2. Functional Responsibilities [PD00-SYO-RES-FUN].
///
/// Maps system functions to organizational units responsible for them.
/// Identifies domain owners, data stewards, and operational contacts for
/// each function area. Follows RACI matrix patterns and enterprise
/// accountability frameworks.
@SectionId('PD00-SYO-RES-FUN')
class FunctionalResponsibilities {
  @Form([
    // Overview
    Field('responsibilityMatrixApproach', String,
        'Responsibility Matrix Approach',
        hint: 'RACI, RASCI, DACI — methodology used for responsibility assignment'),
    Field('governanceModel', String, 'Governance Model',
        hint: 'Centralized, federated, distributed — how responsibilities are governed'),
    Field('escalationProcess', String, 'Escalation Process',
        hint: 'How responsibility conflicts or gaps are escalated'),
    Field('reviewCadence', String, 'Review Cadence',
        hint: 'How often responsibility assignments are reviewed'),
    Field('totalFunctionCount', int, 'Total Function Count',
        hint: 'Number of functional areas with assigned responsibilities'),
    Field('unassignedAreas', String, 'Unassigned Areas',
        hint: 'Functional areas without clear ownership'),
  ])
  String? content;

  /// Responsibility matrix overview narrative.
  @ContentHelp('Describe the overall approach to functional responsibility '
      'assignment: governance model, cross-functional coordination, '
      'conflict resolution, and ongoing maintenance.')
  TextSection matrixOverview = TextSection();

  /// Contains 0+× Responsibility.
  @SectionIdPattern('PD00-SYO-RES-FUN-xx')
  List<ResponsibilityEntry> items = [];
}

/// A responsibility entry [PD00-SYO-RES-FUN-nn] (form).
///
/// Documents responsibility assignment for a specific functional area,
/// following RACI principles (Responsible, Accountable, Consulted, Informed)
/// with additional operational details for clear accountability.
class ResponsibilityEntry {
  @Form([
    // Function Identification
    Field('functionId', String, 'Function ID', required: true,
        hint: 'Unique identifier, e.g. FUNC-001, FUNC-CRM-001'),
    Field('functionName', String, 'Function Name', required: true,
        hint: 'Short descriptive name, e.g. Customer Data Management'),
    Field('functionArea', String, 'Functional Area',
        hint: 'Business area — Sales, Marketing, Finance, HR, Operations, IT'),
    Field('functionDescription', String, 'Description',
        hint: 'Detailed description of the functional responsibility'),
    Field('functionScope', String, 'Scope',
        hint: 'Boundaries of this functional responsibility'),
    Field('businessCriticality', String, 'Business Criticality',
        hint: 'Critical, High, Medium, Low — importance to business'),

    // RACI Assignment
    Field('responsible', String, 'Responsible (R)',
        hint: 'Role/team who does the work', required: true),
    Field('accountable', String, 'Accountable (A)',
        hint: 'Role/person ultimately accountable (one per function)'),
    Field('consulted', String, 'Consulted (C)',
        hint: 'Roles/teams who provide input'),
    Field('informed', String, 'Informed (I)',
        hint: 'Roles/teams who are kept updated'),

    // Key Contacts
    Field('domainOwner', String, 'Domain Owner',
        hint: 'Business owner for this functional area'),
    Field('datasteward', String, 'Data Steward',
        hint: 'Person responsible for data quality and governance'),
    Field('operationalContact', String, 'Operational Contact',
        hint: 'Day-to-day operational contact'),
    Field('technicalContact', String, 'Technical Contact',
        hint: 'Technical SME for this area'),
    Field('escalationContact', String, 'Escalation Contact',
        hint: 'Contact for escalation of issues'),

    // Related Systems
    Field('primarySystems', String, 'Primary Systems',
        hint: 'Systems primarily used for this function'),
    Field('dataOwnership', String, 'Data Ownership',
        hint: 'Data entities owned by this function'),
    Field('processOwnership', String, 'Process Ownership',
        hint: 'Business processes owned by this function'),

    // Governance
    Field('governanceLevel', String, 'Governance Level',
        hint: 'Central, federated, local — where decisions are made'),
    Field('decisionAuthority', String, 'Decision Authority',
        hint: 'What decisions this function can make autonomously'),
    Field('approvalRequired', String, 'Approval Required',
        hint: 'What requires approval and from whom'),
    Field('complianceRole', String, 'Compliance Role',
        hint: 'Regulatory or compliance responsibilities'),

    // Transition
    Field('currentState', String, 'Current State',
        hint: 'How responsibility is handled currently'),
    Field('futureState', String, 'Future State',
        hint: 'How responsibility will be handled post-implementation'),
    Field('transitionPlan', String, 'Transition Plan',
        hint: 'Plan for transitioning responsibility'),
    Field('trainingNeeds', String, 'Training Needs',
        hint: 'Training required for responsibility transition'),
  ])
  String? content;
}

/// 4.6.3. Technical Framework Conditions [PD00-SYO-RES-TEC]. Seeds → TR.
///
/// Documents pre-existing technical constraints including mandated platforms,
/// network restrictions, compliance requirements, existing infrastructure
/// that must be reused, and technology standards to follow. Provides the
/// technical landscape in which the solution must operate. Seeds detailed
/// Technical Requirements (TR) document.
@SectionId('PD00-SYO-RES-TEC')
@Comment('Seeds → TR')
class TechnicalFrameworkConditions {
  // -------------------------------------------------------------------------
  // Technical Landscape Overview
  // -------------------------------------------------------------------------
  @Form([
    // Enterprise Architecture Context
    Field('architectureMaturity', String, 'Architecture Maturity',
        hint: 'TOGAF maturity level or equivalent'),
    Field('cloudStrategy', String, 'Cloud Strategy',
        hint: 'Cloud-first, hybrid, on-premises, multi-cloud'),
    Field('primaryCloudProvider', String, 'Primary Cloud Provider',
        hint: 'AWS, Azure, GCP, private cloud, none'),
    Field('secondaryCloudProviders', String, 'Secondary Cloud Providers'),
    Field('technologyGovernance', String, 'Technology Governance',
        hint: 'How technology decisions are governed'),

    // Platform Standards
    Field('preferredLanguages', String, 'Preferred Languages',
        hint: 'Mandated or preferred programming languages'),
    Field('preferredFrameworks', String, 'Preferred Frameworks',
        hint: 'Mandated or preferred frameworks'),
    Field('preferredDatabases', String, 'Preferred Databases',
        hint: 'Mandated or preferred database platforms'),
    Field('messagingPlatforms', String, 'Messaging Platforms',
        hint: 'Enterprise messaging/queue platforms'),
    Field('integrationPlatforms', String, 'Integration Platforms',
        hint: 'ESB, API gateway, iPaaS solutions'),

    // Security & Compliance
    Field('securityFramework', String, 'Security Framework',
        hint: 'NIST, ISO 27001, SOC2, CIS — security framework used'),
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint: 'GDPR, HIPAA, PCI-DSS, SOX, industry-specific'),
    Field('dataClassificationScheme', String, 'Data Classification',
        hint: 'Public, internal, confidential, restricted'),
    Field('encryptionStandards', String, 'Encryption Standards',
        hint: 'Required encryption algorithms and key lengths'),
    Field('identityProvider', String, 'Identity Provider',
        hint: 'Enterprise identity platform (Azure AD, Okta, etc.)'),

    // Network & Infrastructure
    Field('networkArchitecture', String, 'Network Architecture',
        hint: 'Network topology, DMZ, segmentation approach'),
    Field('firewallPolicies', String, 'Firewall Policies',
        hint: 'Standard firewall rules and policies'),
    Field('vpnRequirements', String, 'VPN Requirements',
        hint: 'VPN requirements for remote access'),
    Field('loadBalancingStandards', String, 'Load Balancing Standards'),
    Field('cdnStrategy', String, 'CDN Strategy'),
  ])
  String? technicalOverviewContent;

  // -------------------------------------------------------------------------
  // Existing Infrastructure
  // -------------------------------------------------------------------------

  /// Existing infrastructure that must be reused or integrated with.
  @ContentHelp('Describe existing infrastructure: data centers, servers, '
      'networks, storage, systems that cannot be replaced, and infrastructure '
      'that the new solution must integrate with or leverage.')
  TextSection existingInfrastructure = TextSection();

  /// Data center and hosting environment details.
  @ContentHelp('Describe data center locations, capacity, connectivity, '
      'disaster recovery setup, and hosting environment constraints.')
  TextSection datacenters = TextSection();

  /// Network topology and connectivity constraints.
  @ContentHelp('Describe network topology, bandwidth constraints, latency '
      'requirements, VPN/private connectivity, and firewall restrictions.')
  TextSection networkTopology = TextSection();

  // -------------------------------------------------------------------------
  // Technology Standards
  // -------------------------------------------------------------------------

  /// Technology standards that must be followed.
  @ContentHelp('Overview of technology standards: adoption policy, '
      'exception process, standard review cycle, and compliance monitoring.')
  TextSection standardsOverview = TextSection();

  /// Technology standards [PD00-SYO-RES-TEC-STD] — contains 0+× TechnologyStandard.
  @SectionIdPattern('PD00-SYO-RES-TEC-STD-xx')
  List<TechnologyStandardEntry> technologyStandards = [];

  // -------------------------------------------------------------------------
  // Integration Constraints
  // -------------------------------------------------------------------------

  /// Integration constraints overview.
  @ContentHelp('Overview of integration constraints: API standards, '
      'protocol restrictions, message format requirements, and '
      'integration platform mandates.')
  TextSection integrationOverview = TextSection();

  /// Integration constraints [PD00-SYO-RES-TEC-INT] — contains 0+× IntegrationConstraint.
  @SectionIdPattern('PD00-SYO-RES-TEC-INT-xx')
  List<IntegrationConstraintEntry> integrationConstraints = [];

  // -------------------------------------------------------------------------
  // DevOps & Operations Standards
  // -------------------------------------------------------------------------

  /// DevOps and deployment standards.
  @ContentHelp('Describe DevOps standards: CI/CD requirements, deployment '
      'pipelines, environment management, and release processes.')
  TextSection devopsStandards = TextSection();

  /// Monitoring and observability requirements.
  @ContentHelp('Describe monitoring requirements: logging standards, '
      'metrics collection, alerting, and observability platforms.')
  TextSection observabilityRequirements = TextSection();

  /// Disaster recovery and business continuity requirements.
  @ContentHelp('Describe DR/BC requirements: RTO, RPO, backup standards, '
      'failover requirements, and recovery testing.')
  TextSection disasterRecovery = TextSection();
}

/// A technology standard entry (form) [PD00-SYO-RES-TEC-STD-nn].
///
/// Documents a mandated or preferred technology standard that the solution
/// must adhere to. Includes scope, compliance requirements, and exceptions.
class TechnologyStandardEntry {
  @Form([
    // Standard Identification
    Field('standardId', String, 'Standard ID', required: true,
        hint: 'Unique identifier, e.g. STD-SEC-001, STD-DEV-001'),
    Field('standardName', String, 'Standard Name', required: true,
        hint: 'Short descriptive name'),
    Field('standardCategory', String, 'Category',
        hint: 'Security, Development, Infrastructure, Integration, Data, DevOps'),
    Field('standardDescription', String, 'Description',
        hint: 'Detailed description of the standard'),

    // Standard Details
    Field('mandateLevel', String, 'Mandate Level',
        hint: 'Mandatory, Strongly Preferred, Preferred, Optional'),
    Field('standardVersion', String, 'Version',
        hint: 'Version of the standard'),
    Field('sourceReference', String, 'Source Reference',
        hint: 'Policy document, framework reference, or authority'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'Date the standard became effective'),
    Field('reviewDate', String, 'Next Review Date',
        hint: 'When standard will be reviewed'),

    // Scope & Applicability
    Field('applicabilityScope', String, 'Applicability Scope',
        hint: 'Where the standard applies — all systems, specific domains, etc.'),
    Field('technologiesCovered', String, 'Technologies Covered',
        hint: 'Specific technologies this standard covers'),
    Field('exceptions', String, 'Known Exceptions',
        hint: 'Existing exceptions to this standard'),
    Field('exceptionProcess', String, 'Exception Process',
        hint: 'How to request an exception'),

    // Compliance
    Field('complianceMethod', String, 'Compliance Method',
        hint: 'How compliance is verified — automated scan, review, audit'),
    Field('complianceOwner', String, 'Compliance Owner',
        hint: 'Role responsible for standard compliance'),
    Field('violationConsequence', String, 'Violation Consequence',
        hint: 'Consequences of non-compliance'),

    // Impact
    Field('projectImpact', String, 'Project Impact',
        hint: 'How this standard impacts the project'),
    Field('implementationNotes', String, 'Implementation Notes',
        hint: 'Notes on implementing this standard'),
  ])
  String? content;
}

/// An integration constraint entry (form) [PD00-SYO-RES-TEC-INT-nn].
///
/// Documents a technical constraint on system integration, including
/// protocol requirements, format restrictions, and platform mandates.
class IntegrationConstraintEntry {
  @Form([
    // Constraint Identification
    Field('constraintId', String, 'Constraint ID', required: true,
        hint: 'Unique identifier, e.g. INT-CON-001'),
    Field('constraintName', String, 'Constraint Name', required: true,
        hint: 'Short descriptive name'),
    Field('constraintDescription', String, 'Description',
        hint: 'Detailed description of the integration constraint'),

    // Constraint Details
    Field('constraintType', String, 'Constraint Type',
        hint: 'Protocol, Format, Platform, Security, Performance, Availability'),
    Field('constraintValue', String, 'Constraint Value',
        hint: 'Specific constraint value or requirement'),
    Field('constraintSource', String, 'Source',
        hint: 'Source of the constraint — enterprise architecture, vendor, security'),

    // Scope
    Field('impactedSystems', String, 'Impacted Systems',
        hint: 'Systems affected by this constraint'),
    Field('impactedInterfaces', String, 'Impacted Interfaces',
        hint: 'Specific interfaces affected'),
    Field('integrationPattern', String, 'Affected Patterns',
        hint: 'Integration patterns affected — sync, async, batch, event'),

    // Impact & Mitigation
    Field('impactLevel', String, 'Impact Level',
        hint: 'High, Medium, Low — impact on integration design'),
    Field('designImplications', String, 'Design Implications',
        hint: 'How this constraint affects integration design'),
    Field('workarounds', String, 'Workarounds',
        hint: 'Potential workarounds or alternatives'),
    Field('mitigationApproach', String, 'Mitigation Approach',
        hint: 'How to work within this constraint'),

    // Compliance
    Field('complianceRequired', bool, 'Compliance Required',
        hint: 'Whether compliance is mandatory'),
    Field('validationMethod', String, 'Validation Method',
        hint: 'How compliance is validated'),
  ])
  String? content;
}

/// 4.6.4. Constraints and Dependencies [PD00-SYO-RES-CON].
///
/// Documents external constraints (regulatory, contractual, budgetary,
/// timeline) and dependencies on other projects, teams, or organizational
/// initiatives. Follows PMBOK constraint management and dependency
/// analysis best practices for comprehensive project planning.
@SectionId('PD00-SYO-RES-CON')
class ConstraintsAndDependencies {
  @Form([
    // --- Overview ---
    Field('constraintDependencyOverview', String,
        'Constraints and Dependencies Overview',
        hint:
            'High-level summary of the key constraints and '
            'dependencies affecting this project'),
    Field('totalConstraintCount', String, 'Total Constraint Count',
        hint:
            'Total number of identified constraints across all '
            'categories'),
    Field('totalDependencyCount', String, 'Total Dependency Count',
        hint:
            'Total number of identified dependencies on external '
            'parties, projects, or systems'),
    Field('criticalConstraintCount', String,
        'Critical Constraint Count',
        hint:
            'Number of constraints classified as critical or '
            'high-impact'),
    Field('criticalDependencyCount', String,
        'Critical Dependency Count',
        hint:
            'Number of dependencies on the critical path or with '
            'high risk'),
    // --- Management Approach ---
    Field('constraintManagementApproach', String,
        'Constraint Management Approach',
        hint:
            'How constraints are identified, tracked, and '
            'managed throughout the project'),
    Field('dependencyManagementApproach', String,
        'Dependency Management Approach',
        hint:
            'How dependencies are tracked, coordinated, and '
            'escalated when at risk'),
    Field('monitoringFrequency', String, 'Monitoring Frequency',
        hint:
            'Weekly / Biweekly / Monthly / PerMilestone — how '
            'often constraints and dependencies are reviewed'),
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'Escalation path when constraints are violated or '
            'dependencies are at risk'),
  ])
  String? content;

  /// 4.6.4.1. Constraints [PD00-SYO-RES-CON-CON].
  Constraints constraints = Constraints();

  /// 4.6.4.2. Dependencies [PD00-SYO-RES-CON-DEP].
  FrameworkDependencies frameworkDependencies = FrameworkDependencies();
}

/// 4.6.4.1. Constraints [PD00-SYO-RES-CON-CON].
///
/// External constraints limiting project scope, schedule, budget, or
/// approach. Includes regulatory, contractual, organizational, technical,
/// and resource constraints. Each constraint must be analysed for impact
/// and monitored throughout the project lifecycle.
@SectionId('PD00-SYO-RES-CON-CON')
class Constraints {
  @Form([
    // --- Overview ---
    Field('constraintSummary', String, 'Constraint Summary',
        hint:
            'Summary of the major constraint categories affecting '
            'this project'),
    Field('primaryConstraintCategory', String,
        'Primary Constraint Category',
        hint:
            'Budget / Timeline / Resources / Regulatory / '
            'Technical / Organizational — dominant constraint type'),
    Field('constraintImpactLevel', String,
        'Overall Constraint Impact Level',
        hint:
            'Low / Medium / High / Critical — aggregate impact '
            'of all constraints on project flexibility'),
    Field('flexibilityAssessment', String, 'Flexibility Assessment',
        hint:
            'Where project has flexibility to absorb constraint '
            'changes — scope, timeline, budget, quality'),
    // --- Categories ---
    Field('regulatoryConstraintCount', String,
        'Regulatory Constraint Count',
        hint:
            'Number of regulatory or compliance constraints'),
    Field('contractualConstraintCount', String,
        'Contractual Constraint Count',
        hint:
            'Number of contractual or legal constraints'),
    Field('budgetaryConstraintCount', String,
        'Budgetary Constraint Count',
        hint:
            'Number of budget or financial constraints'),
    Field('timelineConstraintCount', String,
        'Timeline Constraint Count',
        hint:
            'Number of timeline or deadline constraints'),
    Field('resourceConstraintCount', String,
        'Resource Constraint Count',
        hint:
            'Number of resource or staffing constraints'),
    Field('technicalConstraintCount', String,
        'Technical Constraint Count',
        hint:
            'Number of technical or technology constraints'),
  ])
  String? content;

  /// Contains 0+× Constraint.
  @SectionIdPattern('PD00-SYO-RES-CON-CON-xx')
  List<ConstraintEntry> items = [];

  /// Constraint Summary narrative.
  @Comment('Free-text narrative providing context and analysis '
      'of the constraint landscape')
  TextSection constraintNarrative = TextSection();
}

/// A constraint entry [PD00-SYO-RES-CON-CON-nn] (form).
///
/// Represents a single external constraint limiting project degrees of
/// freedom. Common constraint types include regulatory requirements,
/// contractual obligations, budget limits, timeline deadlines, resource
/// caps, and technology mandates. Each constraint should be tracked,
/// monitored, and have mitigation strategies where possible.
class ConstraintEntry {
  @Form([
    // --- Constraint Identity ---
    Field('constraintId', String, 'Constraint ID',
        hint:
            'Unique identifier, e.g. CON-001, CON-REG-001',
        required: true),
    Field('constraintName', String, 'Constraint Name',
        hint:
            'Short descriptive name for the constraint, e.g. '
            'GDPR Compliance Deadline',
        required: true),
    Field('constraintDescription', String, 'Description',
        hint:
            'Detailed description of the constraint and what '
            'it limits or requires'),

    // --- Constraint Classification ---
    Field('constraintCategory', String, 'Constraint Category',
        hint:
            'Regulatory / Contractual / Budgetary / Timeline / '
            'Resource / Technical / Organizational / Policy / '
            'Environmental / Geographic',
        required: true),
    Field('constraintType', String, 'Constraint Type',
        hint:
            'Hard / Soft — hard constraints cannot be violated, '
            'soft constraints can be negotiated'),
    Field('constraintSource', String, 'Constraint Source',
        hint:
            'Source of the constraint — regulator, contract, '
            'executive, legal, technical team, vendor'),
    Field('sourceReference', String, 'Source Reference',
        hint:
            'Reference to the source document — regulation '
            'number, contract clause, policy document'),

    // --- Constraint Details ---
    Field('constraintValue', String, 'Constraint Value',
        hint:
            'Specific value or limit — e.g. EUR 500K max, '
            '6 months deadline, 10 FTE cap'),
    Field('constraintEffectiveDate', String,
        'Constraint Effective Date',
        hint:
            'Date from which the constraint applies, '
            'e.g. 2026-01-01'),
    Field('constraintExpiryDate', String, 'Constraint Expiry Date',
        hint:
            'Date until which the constraint applies, if '
            'applicable — may be ongoing'),
    Field('geographicScope', String, 'Geographic Scope',
        hint:
            'Geographic regions where constraint applies — '
            'Global / EU / US / APAC / specific countries'),
    Field('affectedDomains', String, 'Affected Domains',
        hint:
            'Business or technical domains affected — scope, '
            'timeline, budget, technology, resources, quality'),

    // --- Impact Assessment ---
    Field('impactLevel', String, 'Impact Level',
        hint:
            'Low / Medium / High / Critical — impact on project '
            'if constraint is violated or not met',
        required: true),
    Field('impactDescription', String, 'Impact Description',
        hint:
            'Description of what happens if constraint is '
            'violated — penalties, delays, legal action'),
    Field('affectedWorkPackages', String, 'Affected Work Packages',
        hint:
            'Work packages or deliverables directly affected '
            'by this constraint'),
    Field('affectedMilestones', String, 'Affected Milestones',
        hint:
            'Project milestones affected by this constraint'),
    Field('scheduleImpact', String, 'Schedule Impact',
        hint:
            'How constraint affects project schedule — fixed '
            'deadline, limited work window, blackout periods'),
    Field('budgetImpact', String, 'Budget Impact',
        hint:
            'How constraint affects project budget — caps, '
            'additional costs, penalties'),
    Field('scopeImpact', String, 'Scope Impact',
        hint:
            'How constraint limits project scope — excluded '
            'features, mandatory features, technology limits'),

    // --- Mitigation & Response ---
    Field('mitigationStrategy', String, 'Mitigation Strategy',
        hint:
            'Strategies to work within the constraint — '
            'workarounds, alternatives, buffering'),
    Field('negotiationPossibility', String,
        'Negotiation Possibility',
        hint:
            'None / Limited / Possible — whether constraint '
            'can be negotiated or relaxed'),
    Field('negotiationApproach', String, 'Negotiation Approach',
        hint:
            'If negotiation is possible, describe the approach '
            'and timing'),
    Field('fallbackPlan', String, 'Fallback Plan',
        hint:
            'Contingency plan if constraint cannot be met — '
            'descope, delay, alternative approach'),
    Field('violationConsequences', String,
        'Violation Consequences',
        hint:
            'Consequences of violating this constraint — '
            'legal, financial, reputational'),

    // --- Tracking & Monitoring ---
    Field('trackingMethod', String, 'Tracking Method',
        hint:
            'How the constraint is monitored — dashboards, '
            'reports, automated alerts, manual reviews'),
    Field('reviewFrequency', String, 'Review Frequency',
        hint:
            'Weekly / Biweekly / Monthly / PerMilestone — '
            'how often constraint status is reviewed'),
    Field('constraintOwner', String, 'Constraint Owner',
        hint:
            'Person or role responsible for monitoring and '
            'managing this constraint'),
    Field('currentStatus', String, 'Current Status',
        hint:
            'OnTrack / AtRisk / Violated / Resolved / Expired — '
            'current status of the constraint'),
    Field('statusNotes', String, 'Status Notes',
        hint:
            'Notes on current status and recent changes'),

    // --- Linkages ---
    Field('relatedConstraints', String, 'Related Constraints',
        hint:
            'Other constraints that interact with or depend '
            'on this one'),
    Field('relatedRisks', String, 'Related Risks',
        hint:
            'Risks associated with this constraint — risk IDs'),
    Field('relatedDependencies', String, 'Related Dependencies',
        hint:
            'Dependencies that relate to this constraint'),
  ])
  String? content;
}

/// 4.6.4.2. Dependencies [PD00-SYO-RES-CON-DEP].
///
/// External dependencies on other projects, teams, vendors, systems, or
/// organizational initiatives. Each dependency represents a point where
/// this project relies on external parties to deliver. Dependencies
/// should be tracked, risks assessed, and contingencies planned.
@SectionId('PD00-SYO-RES-CON-DEP')
class FrameworkDependencies {
  @Form([
    // --- Overview ---
    Field('dependencySummary', String, 'Dependency Summary',
        hint:
            'Summary of the major dependency categories affecting '
            'this project'),
    Field('primaryDependencyCategory', String,
        'Primary Dependency Category',
        hint:
            'Project / Team / Vendor / System / Regulatory / '
            'Infrastructure — dominant dependency type'),
    Field('dependencyRiskLevel', String,
        'Overall Dependency Risk Level',
        hint:
            'Low / Medium / High / Critical — aggregate risk '
            'from all dependencies'),
    Field('criticalPathDependencyCount', String,
        'Critical Path Dependency Count',
        hint:
            'Number of dependencies on the project critical path'),
    // --- Categories ---
    Field('projectDependencyCount', String,
        'Project Dependency Count',
        hint:
            'Number of dependencies on other projects'),
    Field('teamDependencyCount', String, 'Team Dependency Count',
        hint:
            'Number of dependencies on other internal teams'),
    Field('vendorDependencyCount', String,
        'Vendor Dependency Count',
        hint:
            'Number of dependencies on external vendors'),
    Field('systemDependencyCount', String,
        'System Dependency Count',
        hint:
            'Number of dependencies on existing systems'),
    Field('regulatoryDependencyCount', String,
        'Regulatory Dependency Count',
        hint:
            'Number of dependencies on regulatory approvals'),
    Field('infrastructureDependencyCount', String,
        'Infrastructure Dependency Count',
        hint:
            'Number of dependencies on infrastructure delivery'),
    // --- Management ---
    Field('dependencyCoordinationApproach', String,
        'Dependency Coordination Approach',
        hint:
            'How dependencies are coordinated — regular syncs, '
            'shared boards, liaison roles, escalation process'),
    Field('earlyWarningMechanism', String,
        'Early Warning Mechanism',
        hint:
            'How risks to dependencies are detected early — '
            'status reports, automated monitoring, trigger criteria'),
  ])
  String? content;

  /// Contains 0+× FrameworkDependency.
  @SectionIdPattern('PD00-SYO-RES-CON-DEP-xx')
  List<FrameworkDependencyEntry> items = [];

  /// Dependency Summary narrative.
  @Comment('Free-text narrative providing context and analysis '
      'of the dependency landscape')
  TextSection dependencyNarrative = TextSection();
}

/// A framework dependency entry [PD00-SYO-RES-CON-DEP-nn] (form).
///
/// Represents a single external dependency where this project relies on
/// another party (project, team, vendor, system) to deliver something.
/// Dependencies should be actively managed with clear expectations,
/// tracking, and contingency plans for delays or failures.
class FrameworkDependencyEntry {
  @Form([
    Field('dependencyId', String, 'Dependency ID',
        hint: 'Unique identifier, e.g. DEP-001', required: true),
    Field('dependencyName', String, 'Dependency Name',
        hint: 'Short descriptive name for the dependency', required: true),
    Field('criticalityLevel', String, 'Criticality Level',
        hint: 'Low / Medium / High / Critical', required: true),
  ])
  String? content;

  /// Dependency identity details.
  final DependencyIdentity identity = DependencyIdentity();

  /// Dependency classification.
  final DependencyClassification classification = DependencyClassification();

  /// External party details.
  final DependencyExternalParty externalParty = DependencyExternalParty();

  /// Deliverable details.
  final DependencyDeliverable deliverable = DependencyDeliverable();

  /// Timeline.
  final DependencyTimeline timeline = DependencyTimeline();

  /// Risk assessment.
  final DependencyRisk risk = DependencyRisk();

  /// Mitigation and contingency.
  final DependencyMitigation mitigation = DependencyMitigation();

  /// Coordination and tracking.
  final DependencyTracking tracking = DependencyTracking();

  /// Linkages.
  final DependencyLinkages linkages = DependencyLinkages();
}

/// Dependency identity details.
class DependencyIdentity {
  @Form([
    Field('dependencyDescription', String, 'Description',
        hint: 'Detailed description of what is being depended upon'),
  ])
  String? content;
}

/// Dependency classification.
class DependencyClassification {
  @Form([
    Field('dependencyCategory', String, 'Dependency Category',
        hint: 'Project / Team / Vendor / System / Regulatory / Infrastructure',
        required: true),
    Field('dependencyType', String, 'Dependency Type',
        hint: 'Finish-to-Start / Start-to-Start / Finish-to-Finish'),
    Field('onCriticalPath', String, 'On Critical Path',
        hint: 'Yes / No — whether this dependency is on the critical path'),
  ])
  String? content;
}

/// External party details.
class DependencyExternalParty {
  @Form([
    Field('externalPartyName', String, 'External Party Name',
        hint: 'Name of the project, team, vendor, or system', required: true),
    Field('externalPartyType', String, 'External Party Type',
        hint: 'InternalProject / InternalTeam / ExternalVendor / Regulator'),
    Field('contactPerson', String, 'Contact Person',
        hint: 'Primary contact at the external party'),
    Field('contactEmail', String, 'Contact Email',
        hint: 'Email address for the primary contact'),
    Field('escalationContact', String, 'Escalation Contact',
        hint: 'Escalation contact if primary is unresponsive'),
  ])
  String? content;
}

/// Deliverable details.
class DependencyDeliverable {
  @Form([
    Field('deliverableDescription', String, 'Deliverable Description',
        hint: 'Description of what must be delivered'),
    Field('deliverableSpecification', String, 'Deliverable Specification',
        hint: 'Link to or reference for detailed specifications'),
    Field('qualityCriteria', String, 'Quality Criteria',
        hint: 'Quality criteria the deliverable must meet'),
    Field('deliveryFormat', String, 'Delivery Format',
        hint: 'Format of the deliverable — API, data file, documentation'),
  ])
  String? content;
}

/// Dependency timeline.
class DependencyTimeline {
  @Form([
    Field('expectedDeliveryDate', String, 'Expected Delivery Date',
        hint: 'Date when deliverable is expected', required: true),
    Field('latestAcceptableDate', String, 'Latest Acceptable Date',
        hint: 'Latest date deliverable can be received without impact'),
    Field('leadTimeRequired', String, 'Lead Time Required',
        hint: 'Time needed after delivery to integrate'),
    Field('bufferDays', String, 'Buffer Days',
        hint: 'Buffer built into schedule for potential delays'),
    Field('dependentMilestones', String, 'Dependent Milestones',
        hint: 'Project milestones that depend on this delivery'),
  ])
  String? content;
}

/// Dependency risk assessment.
class DependencyRisk {
  @Form([
    Field('deliveryRiskLevel', String, 'Delivery Risk Level',
        hint: 'Low / Medium / High / Critical', required: true),
    Field('primaryRiskFactors', String, 'Primary Risk Factors',
        hint: 'Key factors driving delivery risk'),
    Field('riskIndicators', String, 'Risk Indicators',
        hint: 'Early warning indicators'),
    Field('impactOfDelay', String, 'Impact of Delay',
        hint: 'Impact on project if delivery is delayed'),
    Field('impactOfFailure', String, 'Impact of Failure',
        hint: 'Impact on project if delivery fails entirely'),
  ])
  String? content;
}

/// Dependency mitigation and contingency.
class DependencyMitigation {
  @Form([
    Field('mitigationStrategy', String, 'Mitigation Strategy',
        hint: 'Strategies to reduce delivery risk'),
    Field('contingencyPlan', String, 'Contingency Plan',
        hint: 'Backup plan if dependency fails or is delayed'),
    Field('contingencyTimeline', String, 'Contingency Timeline',
        hint: 'When contingency plan would need to be activated'),
    Field('contractualProtection', String, 'Contractual Protection',
        hint: 'Contractual protections in place — SLAs, penalties'),
    Field('alternativeOptions', String, 'Alternative Options',
        hint: 'Alternative sources or approaches if primary fails'),
  ])
  String? content;
}

/// Dependency coordination and tracking.
class DependencyTracking {
  @Form([
    Field('coordinationMechanism', String, 'Coordination Mechanism',
        hint: 'How coordination occurs — weekly syncs, shared board'),
    Field('communicationFrequency', String, 'Communication Frequency',
        hint: 'Daily / Weekly / Biweekly / Monthly'),
    Field('trackingMethod', String, 'Tracking Method',
        hint: 'How progress is tracked'),
    Field('dependencyOwner', String, 'Dependency Owner',
        hint: 'Person or role responsible for managing this dependency'),
    Field('currentStatus', String, 'Current Status',
        hint: 'OnTrack / Delayed / AtRisk / Delivered / Failed'),
    Field('statusLastUpdated', String, 'Status Last Updated',
        hint: 'Date of the most recent status update'),
    Field('statusNotes', String, 'Status Notes',
        hint: 'Notes on current status, recent progress, or concerns'),
  ])
  String? content;
}

/// Dependency linkages.
class DependencyLinkages {
  @Form([
    Field('relatedConstraints', String, 'Related Constraints',
        hint: 'Constraints that relate to this dependency'),
    Field('relatedRisks', String, 'Related Risks',
        hint: 'Risks associated with this dependency — risk IDs'),
    Field('relatedDependencies', String, 'Related Dependencies',
        hint: 'Other dependencies that interact with this one'),
    Field('affectedWorkPackages', String, 'Affected Work Packages',
        hint: 'Work packages that depend on this delivery'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 4.7 Risks and Assumptions
// ---------------------------------------------------------------------------

/// 4.7. Risks and Assumptions [PD00-SYO-RIS].
///
/// Documents identified project risks and underlying assumptions following
/// ISO 31000 Risk Management and PMBOK risk management best practices.
/// Provides structured framework for risk identification, analysis, response
/// planning, and ongoing monitoring throughout the project lifecycle.
@SectionId('PD00-SYO-RIS')
class RisksAndAssumptions {
  /// Overview of the risk management approach for this project.
  RisksOverview overview = RisksOverview();

  /// 4.7.1. Key Risks [PD00-SYO-RIS-RIS] — contains 0+× Risk.
  @SectionIdPattern('PD00-SYO-RIS-RIS-xx')
  List<RiskEntry> keyRisks = [];

  /// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS] — contains 0+×.
  KeyAssumptions keyAssumptions = KeyAssumptions();
}

/// Overview of the risk management approach.
class RisksOverview {
  @Form([
    Field('riskManagementApproach', String,
        'Risk Management Approach — overall methodology and framework'),
    Field('riskAppetite', String,
        'Risk Appetite — organization tolerance (risk-averse, risk-neutral, risk-seeking)'),
    Field('riskThresholds', String,
        'Risk Thresholds — quantitative escalation levels (e.g., cost > \$50K)'),
    Field('riskReviewCadence', String,
        'Risk Review Cadence — frequency of review meetings'),
    Field('escalationPath', String,
        'Escalation Path — hierarchy for escalating high-severity risks'),
    Field('riskTooling', String,
        'Risk Management Tooling — tools used to track risks'),
    Field('riskCategories', String,
        'Risk Categories — Technical, Schedule, Cost, Resource, External, etc.'),
    Field('probabilityScale', String,
        'Probability Scale — Very Low (<10%), Low (10-30%), Medium (30-50%), High (50-70%), Very High (>70%)'),
    Field('impactScale', String,
        'Impact Scale — Negligible, Minor, Moderate, Major, Catastrophic with criteria'),
  ])
  String? content;
}

/// A risk entry [PD00-SYO-RIS-RIS-nn] (form).
///
/// Comprehensive risk documentation following ISO 31000 and PMBOK guidelines.
/// Captures risk identification, analysis, response planning, ownership,
/// and monitoring information for systematic risk management.
class RiskEntry {
  /// Risk identification — unique identifier and basic description.
  RiskIdentification identification = RiskIdentification();

  /// Risk analysis — probability, impact, and scoring.
  RiskAnalysis analysis = RiskAnalysis();

  /// Risk response — strategy and planned actions.
  RiskResponse response = RiskResponse();

  /// Risk ownership and governance.
  RiskOwnership ownership = RiskOwnership();

  /// Risk monitoring and tracking details.
  RiskMonitoring monitoring = RiskMonitoring();

  /// Business impact assessment.
  RiskBusinessImpact businessImpact = RiskBusinessImpact();

  /// Relationships to other risks, assumptions, and project elements.
  RiskRelationships relationships = RiskRelationships();
}

/// Risk identification details.
class RiskIdentification {
  @Form([
    Field('riskId', String, 'Risk ID (e.g., RISK-001, TR-001)', required: true),
    Field('riskName', String, 'Risk Name — short descriptive name', required: true),
    Field('description', String,
        'Description — detailed risk event and potential causes'),
    Field('category', String,
        'Category — Technical, Schedule, Cost, Resource, External, Legal, Organizational'),
    Field('subcategory', String,
        'Subcategory — more specific categorization'),
    Field('source', String,
        'Risk Source — brainstorming, review, lessons learned'),
    Field('dateIdentified', String, 'Date Identified'),
    Field('identifiedBy', String, 'Identified By — person or team'),
    Field('riskType', String,
        'Risk Type — Threat (negative) or Opportunity (positive)'),
    Field('trigger', String,
        'Risk Trigger — events indicating risk is about to occur'),
    Field('rootCause', String,
        'Root Cause — underlying causes that could lead to this risk'),
  ])
  String? content;
}

/// Risk analysis — probability, impact, and risk scoring.
class RiskAnalysis {
  @Form([
    Field('probability', String,
        'Probability — Very Low, Low, Medium, High, Very High'),
    Field('probabilityValue', double,
        'Probability Value — numeric (0.0-1.0) for quantitative analysis'),
    Field('impact', String,
        'Impact — Negligible, Minor, Moderate, Major, Catastrophic'),
    Field('impactValue', double,
        'Impact Value — numeric score (1-5 or monetary value)'),
    Field('riskScore', double,
        'Risk Score — calculated (probability × impact)'),
    Field('riskLevel', String, 'Risk Level — Low, Medium, High, Critical'),
    Field('riskRanking', int, 'Risk Ranking — priority relative to other risks'),
    Field('analysisMethod', String,
        'Analysis Method — Qualitative, Semi-quantitative, Quantitative'),
    Field('confidenceLevel', String,
        'Confidence Level — in probability/impact estimates'),
    Field('analysisNotes', String, 'Analysis Notes — methodology and findings'),
  ])
  String? content;
}

/// Risk response — strategy and planned actions.
class RiskResponse {
  @Form([
    Field('responseStrategy', String,
        'Response Strategy — Avoid, Transfer, Mitigate, Accept (or Exploit, Share, Enhance for opportunities)'),
    Field('responseDescription', String,
        'Response Description — planned approach'),
    Field('mitigationActions', String,
        'Mitigation Actions — actions to reduce probability or impact'),
    Field('contingencyPlan', String,
        'Contingency Plan — actions if risk materializes'),
    Field('residualRisk', String,
        'Residual Risk — level remaining after mitigation'),
    Field('residualProbability', String,
        'Residual Probability — expected after mitigation'),
    Field('residualImpact', String,
        'Residual Impact — expected after mitigation'),
    Field('secondaryRisks', String,
        'Secondary Risks — new risks from implementing response'),
    Field('responseEffectiveness', String,
        'Response Effectiveness — Low, Medium, High'),
    Field('implementationCost', String,
        'Implementation Cost — cost to implement response'),
    Field('implementationTimeline', String,
        'Implementation Timeline — for response actions'),
  ])
  String? content;
}

/// Risk ownership and governance.
class RiskOwnership {
  @Form([
    Field('riskOwner', String,
        'Risk Owner — person accountable for monitoring'),
    Field('riskOwnerRole', String, 'Owner Role — role/title'),
    Field('actionOwners', String,
        'Action Owners — people responsible for mitigation actions'),
    Field('escalationContact', String,
        'Escalation Contact — who to escalate to if risk worsens'),
    Field('stakeholdersInformed', String,
        'Stakeholders Informed — who needs to be kept informed'),
    Field('approvalRequired', bool,
        'Approval Required — whether response actions need approval'),
    Field('approver', String,
        'Approver — person who must approve response actions'),
    Field('decisionAuthority', String,
        'Decision Authority — authority level for decisions'),
  ])
  String? content;
}

/// Risk monitoring and tracking.
class RiskMonitoring {
  @Form([
    Field('reviewFrequency', String,
        'Review Frequency — Daily, Weekly, Bi-weekly, Monthly'),
    Field('lastReviewDate', String, 'Last Review Date'),
    Field('nextReviewDate', String, 'Next Review Date'),
    Field('riskStatus', String,
        'Risk Status — Identified, Analyzing, Responding, Monitoring, Closed, Realized'),
    Field('trend', String, 'Trend — Increasing, Stable, Decreasing'),
    Field('trendJustification', String,
        'Trend Justification — explanation for trend assessment'),
    Field('earlyWarningIndicators', String,
        'Early Warning Indicators — metrics signaling risk may materialize'),
    Field('monitoringMechanism', String,
        'Monitoring Mechanism — automated alerts, manual review, etc.'),
    Field('closureDate', String, 'Closure Date'),
    Field('closureReason', String,
        'Closure Reason — Mitigated, Avoided, Accepted, Realized, No longer relevant'),
    Field('lessonsLearned', String,
        'Lessons Learned — key insights from managing this risk'),
  ])
  String? content;
}

/// Business impact assessment for the risk.
class RiskBusinessImpact {
  @Form([
    Field('costImpact', String,
        'Cost Impact — potential cost if risk materializes'),
    Field('scheduleImpact', String,
        'Schedule Impact — potential delay (days, weeks, phases)'),
    Field('scopeImpact', String, 'Scope Impact — impact on deliverables'),
    Field('qualityImpact', String, 'Quality Impact'),
    Field('resourceImpact', String,
        'Resource Impact — impact on team resources'),
    Field('reputationImpact', String,
        'Reputation Impact — organizational or project'),
    Field('customerImpact', String,
        'Customer Impact — impact on customers or end users'),
    Field('regulatoryImpact', String,
        'Regulatory Impact — compliance implications'),
    Field('operationalImpact', String,
        'Operational Impact — impact on ongoing operations'),
    Field('strategicImpact', String,
        'Strategic Impact — impact on strategic objectives'),
    Field('affectedMilestones', String,
        'Affected Milestones — project milestones at risk'),
    Field('affectedDeliverables', String,
        'Affected Deliverables — specific deliverables at risk'),
  ])
  String? content;
}

/// Relationships to other risks, assumptions, and project elements.
class RiskRelationships {
  @Form([
    Field('relatedRisks', String,
        'Related Risks — other risks that are related or dependent'),
    Field('relatedAssumptions', String,
        'Related Assumptions — assumptions that could affect this risk'),
    Field('relatedIssues', String,
        'Related Issues — issues arising from this risk'),
    Field('relatedRequirements', String,
        'Related Requirements — requirements affected'),
    Field('affectedComponents', String,
        'Affected Components — system components or modules'),
    Field('affectedStakeholders', String,
        'Affected Stakeholders — groups impacted if risk occurs'),
    Field('externalDependencies', String,
        'External Dependencies — external factors related to risk'),
    Field('documentReferences', String,
        'Document References — related documentation'),
  ])
  String? content;
}

// ────────────────────────────────────────────────────────────────
// Key Assumptions
// ────────────────────────────────────────────────────────────────

/// 4.7.2. Key Assumptions [PD00-SYO-RIS-ASS].
///
/// Documents project assumptions that must hold true for success.
/// Tracks validation status and contingency plans if assumptions prove false.
@SectionId('PD00-SYO-RIS-ASS')
class KeyAssumptions {
  /// Overview of assumptions management approach.
  AssumptionsOverview overview = AssumptionsOverview();

  /// Contains 0+× Assumption.
  @SectionIdPattern('PD00-SYO-RIS-ASS-xx')
  List<AssumptionEntry> items = [];
}

/// Overview of assumptions management.
class AssumptionsOverview {
  @Form([
    Field('assumptionsApproach', String,
        'Assumptions Management Approach — process for documenting and validating'),
    Field('validationCadence', String,
        'Validation Cadence — how often reviewed and validated'),
    Field('assumptionCategories', String,
        'Assumption Categories — Technical, Resource, Schedule, Budget, External, Organizational'),
    Field('escalationProcess', String,
        'Escalation Process — when critical assumption proves false'),
  ])
  String? content;
}

/// An assumption entry [PD00-SYO-RIS-ASS-nn] (form).
///
/// Documents a project assumption including its basis, validation approach,
/// and contingency plans if the assumption proves false.
class AssumptionEntry {
  /// Assumption identification and description.
  AssumptionIdentification identification = AssumptionIdentification();

  /// Assumption validation details.
  AssumptionValidation validation = AssumptionValidation();

  /// Impact and contingency if assumption is false.
  AssumptionImpact impact = AssumptionImpact();

  /// Relationships to other project elements.
  AssumptionRelationships relationships = AssumptionRelationships();
}

/// Assumption identification details.
class AssumptionIdentification {
  @Form([
    Field('assumptionId', String,
        'Assumption ID (e.g., ASSUM-001, TA-001)', required: true),
    Field('assumptionName', String,
        'Assumption Name — short descriptive name', required: true),
    Field('description', String,
        'Description — detailed statement of what is assumed'),
    Field('category', String,
        'Category — Technical, Resource, Schedule, Budget, External, Organizational'),
    Field('basis', String,
        'Basis — evidence or reasoning supporting this assumption'),
    Field('dateIdentified', String, 'Date Identified'),
    Field('identifiedBy', String, 'Identified By'),
    Field('criticality', String,
        'Criticality — Low, Medium, High, Critical'),
    Field('confidence', String,
        'Confidence Level — that assumption will hold'),
  ])
  String? content;
}

/// Assumption validation details.
class AssumptionValidation {
  @Form([
    Field('validationMethod', String,
        'Validation Method — testing, confirmation, analysis'),
    Field('validationCriteria', String,
        'Validation Criteria — determines if assumption is valid'),
    Field('validationDate', String,
        'Validation Date — target date for validation'),
    Field('validationStatus', String,
        'Validation Status — Unvalidated, In Progress, Validated, Invalid, N/A'),
    Field('lastValidationDate', String, 'Last Validation Date'),
    Field('validatedBy', String, 'Validated By'),
    Field('validationNotes', String, 'Validation Notes'),
    Field('validationOwner', String, 'Validation Owner — responsible person'),
  ])
  String? content;
}

/// Impact assessment if assumption proves false.
class AssumptionImpact {
  @Form([
    Field('impactIfFalse', String,
        'Impact If False — consequences if incorrect'),
    Field('impactSeverity', String,
        'Impact Severity — Low, Medium, High, Critical'),
    Field('affectedAreas', String,
        'Affected Areas — Scope, Schedule, Cost, Quality, Resources'),
    Field('contingencyPlan', String,
        'Contingency Plan — actions if assumption proves false'),
    Field('contingencyOwner', String, 'Contingency Owner'),
    Field('contingencyCost', String,
        'Contingency Cost — estimated cost of executing'),
    Field('contingencyTimeline', String,
        'Contingency Timeline — time required to execute'),
    Field('relatedRisks', String,
        'Related Risks — triggered if assumption is false'),
  ])
  String? content;
}

/// Relationships to other project elements.
class AssumptionRelationships {
  @Form([
    Field('relatedAssumptions', String,
        'Related Assumptions — other dependent assumptions'),
    Field('relatedRisks', String, 'Related Risks'),
    Field('relatedRequirements', String,
        'Related Requirements — that depend on this'),
    Field('affectedDecisions', String,
        'Affected Decisions — based on this assumption'),
    Field('documentReferences', String,
        'Document References — supporting documentation'),
    Field('stakeholderOwner', String,
        'Stakeholder Owner — accountable stakeholder'),
    Field('reviewFrequency', String,
        'Review Frequency — how often reviewed'),
  ])
  String? content;
}
