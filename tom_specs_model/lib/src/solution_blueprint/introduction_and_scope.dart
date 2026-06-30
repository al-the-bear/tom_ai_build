/// Section 4: Introduction & Scope.
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment. This chapter provides the foundational
/// understanding of what the system is, why it's being built, and the
/// context in which it will operate.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 4. Introduction & Scope.
///
/// High-level overview of the system to be built: its purpose, goals,
/// scope boundaries, and the environment it operates in. This section
/// establishes the foundation for all subsequent specification work.
@SectionId('SYOV')
class IntroductionAndScope {
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
  @SerializationOrder(0)
  String? content;

  /// System overview summary statistics.
  @SerializationOrder(1)
  SystemSummary summary = SystemSummary();

  /// System context diagram showing major system boundaries.
  @ContentType('mermaid', 'High-level context diagram showing the system, '
      'its users, and external system interfaces')
  @SerializationOrder(2)
  String? systemContextDiagram;

  /// 4.1. System Description.
  @SerializationOrder(3)
  SystemDescription systemDescription = SystemDescription();

  /// 4.2. Goals.
  @SerializationOrder(4)
  Goals goals = Goals();

  /// 4.3. Requirements Overview. Seeds → RSP.
  @Comment('Seeds → RSP')
  @SerializationOrder(5)
  RequirementsOverview requirements = RequirementsOverview();

  /// 4.4. Systems to Replace. Seeds → CLA.
  @Comment('Seeds → CLA')
  @SerializationOrder(6)
  SystemsToReplace systemsToReplace = SystemsToReplace();

  /// 4.5. System Boundaries. Seeds → IIS.
  @Comment('Seeds → IIS')
  @SerializationOrder(7)
  SystemBoundaries systemBoundaries = SystemBoundaries();

  /// 4.6. Operating Environment.
  @SerializationOrder(8)
  OperatingEnvironment operatingEnvironment = OperatingEnvironment();

  /// 4.7. Risks and Assumptions.
  @SerializationOrder(9)
  RisksAndAssumptions risksAndAssumptions = RisksAndAssumptions();
}

/// System overview summary for quick reference.
@SectionId('SYSUM')
class SystemSummary {
  @Form([
    Field('systemName', String, 'System Name',
        hint: 'Official name of the system being built', required: true),
    Field('systemAcronym', String, 'System Acronym',
        hint: 'Short acronym if used'),
    Field('systemVersion', String, 'System Version',
        hint: 'Target version this specification covers'),
    Field('projectCodeName', String, 'Project Code Name',
        hint: 'Internal project code name if different'),
  ])
  @SerializationOrder(0)
  String? content;

  /// System classification.
  @SerializationOrder(1)
  SystemClassification classification =
      SystemClassification();

  /// Scale indicators.
  @SerializationOrder(2)
  SystemScale scale = SystemScale();

  /// Specification status.
  @SerializationOrder(3)
  SpecificationStatus status = SpecificationStatus();

  /// Complexity indicators.
  @SerializationOrder(4)
  SystemComplexity complexity =
      SystemComplexity();
}

/// System classification.
@SectionId('SYCLS')
class SystemClassification {
  @Form([
    Field('systemType', String, 'System Type',
        hint: 'Web Application / Mobile App / API / Desktop / Embedded / Hybrid'),
    Field('businessDomain', String, 'Business Domain',
        hint: 'Primary business domain — Finance / Healthcare / Retail / etc.'),
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'Cloud / On-premise / Hybrid / Edge'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scale indicators.
@SectionId('SYSCL')
class SystemScale {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Specification status.
@SectionId('SYSTA')
class SpecificationStatus {
  @Form([
    Field('specificationVersion', String, 'Specification Version',
        hint: 'Version of this specification document'),
    Field('specificationDate', String, 'Specification Date',
        hint: 'Date of this specification'),
    Field('specificationStatus', String, 'Specification Status',
        hint: 'Draft / Review / Approved / Superseded'),
    Field('targetGoLiveDate', String, 'Target Go-Live Date',
        hint: 'Planned production deployment date'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Complexity indicators.
@SectionId('SYCMX')
class SystemComplexity {
  @Form([
    Field('overallComplexity', String, 'Overall Complexity',
        hint: 'Low / Medium / High / Very High — based on scope and integrations'),
    Field('keyRisks', String, 'Key Risks Summary',
        hint: 'Brief list of top 3 risks'),
    Field('keyAssumptions', String, 'Key Assumptions Summary',
        hint: 'Brief list of critical assumptions'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1 System Description
// ---------------------------------------------------------------------------

/// 4.1. System Description.
///
/// Concise description of the system to be created, its primary purpose,
/// and the business domain it addresses. This section provides the
/// foundation for understanding what the system does and who uses it.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — system overview',
    'ISO/IEC/IEEE 29148 §9 — stakeholder needs & requirements',
  ],
  'The root of §4.1: captures what the system is, its primary purpose, and the '
  'business domain it serves, establishing a shared mental model for all '
  'stakeholders.',
)
@SectionId('SYDSC')
class SystemDescription {
  @ContentHelp('''
Concise description of the system to be created.
Describe the primary purpose of the system and the business domain it
addresses. Focus on WHAT the system does, not HOW it does it.
This section should establish a shared vocabulary and mental model
that all stakeholders can refer to.
''')
  @SerializationOrder(0)
  String? content;

  /// System description summary.
  @SerializationOrder(1)
  SystemDescriptionSummary descriptionSummary = SystemDescriptionSummary();

  /// 4.1.1. System Purpose.
  @SerializationOrder(2)
  SystemPurpose systemPurpose = SystemPurpose();

  /// 4.1.2. System Context.
  @SerializationOrder(3)
  SystemContext systemContext = SystemContext();

  /// 4.1.3. Description of Business Domain.
  @SerializationOrder(4)
  BusinessDomain businessDomain = BusinessDomain();

  /// 4.1.4. User Categories — contains 1+× User Category.
  @StandardReferences(
    [
      'BABOK v3 §10.43 — stakeholder list/map/personas',
      'ISO/IEC/IEEE 29148 §6 — stakeholders',
    ],
    'The set of distinct user categories that interact with the system.',
  )
  @SectionId('USCA-USER-LST')
  @SectionIdPattern('USCA-USER-xxx')
  @Min(1)
  @ContentHelp('Add one entry per distinct category of user, distinguished by '
      'role, access level, or interaction pattern with the system.')
  @SerializationOrder(5)
  List<UserCategoryEntry> userCategories = [];

  /// 4.1.5. User Interaction Model.
  @SerializationOrder(6)
  UserInteractionModel userInteractionModel = UserInteractionModel();
}

/// Summary statistics and classification for system description.
///
/// Provides structured classification of the system including its primary
/// function, domain classification, technology stack, and key characteristics.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §6 — system overview'],
  'A structured at-a-glance classification of the system — its function, '
  'domain, architecture, deployment, and key characteristics.',
)
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
@SectionId('SDSM')
class SystemDescriptionSummary {
  /// Summary content for system description classification.
  @ContentType('aggregation', 'Structured classification and characteristics '
      'of the system based on category, domain, architecture, and '
      'deployment model.')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.1 System Purpose
// ---------------------------------------------------------------------------

/// 4.1.1. System Purpose.
///
/// Describes the overarching purpose of the system including the problem it
/// solves, the opportunity it enables, and who the primary beneficiaries are.
/// This section establishes the fundamental justification for the project.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — system overview',
    'ISO/IEC/IEEE 29148 §9 — stakeholder needs & requirements',
  ],
  'Captures the fundamental justification for the system — the problem it '
  'solves, the opportunity it enables, its beneficiaries, and its strategic '
  'fit.',
)
@ContentHelp('Describe the overarching purpose of the system. Address: '
    'What problem does it solve? What opportunity does it enable? '
    'Who are the primary beneficiaries? How does it align with '
    'organizational strategy?')
@SectionId('SYPUP')
class SystemPurpose {
  @SerializationOrder(0)
  String? content;

  /// Vision Statement.
  @ContentType('description', 'A concise, memorable statement (1-3 sentences) '
      'that captures the essence of what the system will achieve.')
  @ContentHelp('Write a clear and inspiring vision statement that describes '
      'what success looks like when this system is fully operational.')
  @SerializationOrder(1)
  String? visionStatement;

  /// 4.1.1.1. Problem Statement.
  @SerializationOrder(2)
  ProblemStatement problemStatement = ProblemStatement();

  /// 4.1.1.2. Opportunity Statement.
  @SerializationOrder(3)
  OpportunityStatement opportunityStatement = OpportunityStatement();

  /// 4.1.1.3. Stakeholders and Beneficiaries.
  @SerializationOrder(4)
  StakeholdersAndBeneficiaries stakeholders = StakeholdersAndBeneficiaries();

  /// 4.1.1.4. Value Proposition.
  @SerializationOrder(5)
  ValueProposition valueProposition = ValueProposition();

  /// 4.1.1.5. Strategic Alignment.
  @SerializationOrder(6)
  StrategicAlignment strategicAlignment = StrategicAlignment();

  /// 4.1.1.6. Scope Boundaries.
  @SerializationOrder(7)
  ScopeBoundaries scopeBoundaries = ScopeBoundaries();
}

/// 4.1.1.1. Problem Statement.
///
/// Detailed description of the problem or pain point that this system will
/// address. Includes impact analysis and urgency assessment.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — problem space',
    'BABOK v3 §6 — strategy analysis (needs & business goals)',
  ],
  'Captures the problem or pain point the system addresses, with its impact, '
  'root causes, and urgency.',
)
@ContentHelp('Describe the problem in detail. What is the current state? '
    'What makes it a problem? Who is affected and how severely?')
@SectionId('PS')
class ProblemStatement {
  @SerializationOrder(0)
  String? content;

  /// Problem Description Form.
  @Form([
    Field('problemSummary', String, 'Problem Summary (one sentence)',
        required: true,
        hint: 'State the core problem in a single concise sentence'),
    Field('currentState', String,
        'Current State (describe the AS-IS situation that is problematic)',
        hint: 'Describe the current AS-IS situation that is problematic'),
    Field('affectedParties', String,
        'Affected Parties (who suffers from this problem)',
        hint: 'Who suffers from this problem and in what way'),
    Field('impactDescription', String,
        'Impact Description (business, financial, operational impacts)',
        hint: 'Business, financial, and operational impacts of the problem'),
    Field('impactSeverity', String,
        'Impact Severity (Critical, High, Medium, Low)',
        hint: 'Critical / High / Medium / Low'),
    Field('impactMetrics', String,
        'Impact Metrics (quantifiable measures of the problem\'s cost)',
        hint: 'Quantifiable measures of the problem\'s cost'),
    Field('rootCauses', String, 'Root Causes (underlying reasons for problem)',
        hint: 'Underlying reasons that cause the problem'),
    Field('urgency', String,
        'Urgency (Immediate, Short-term, Medium-term, Long-term)',
        hint: 'Immediate / Short-term / Medium-term / Long-term'),
    Field('urgencyJustification', String,
        'Urgency Justification (why this timeline is critical)',
        hint: 'Why the stated timeline is critical'),
    Field('consequencesOfInaction', String,
        'Consequences of Inaction (what happens if not addressed)',
        hint: 'What happens if the problem is not addressed'),
  ])
  @SerializationOrder(1)
  TextSection? problemDetails;

  /// Related pain points from Current State Analysis.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — problem space'],
    'The set of related pain points drawn from the Current State Analysis that '
    'this problem connects to.',
  )
  @SectionId('RPPE-RELA-LST')
  @SectionIdPattern('RPPE-RELA-xxx')
  @ContentHelp('Add one entry per related pain point identified in the Current '
      'State Analysis that this problem statement connects to.')
  @SerializationOrder(2)
  List<RelatedPainPointEntry> relatedPainPoints = [];
}

/// 4.1.1.2. Opportunity Statement.
///
/// Description of the opportunity this system enables — new capabilities,
/// competitive advantages, or improvements over current state.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — problem space',
    'BABOK v3 §6 — strategy analysis (needs & business goals)',
  ],
  'Captures the opportunity the system enables — the TO-BE state, new '
  'capabilities, and competitive advantages over the current state.',
)
@ContentHelp('Describe what the system will enable. What new capabilities '
    'will be available? What improvements over current state? What '
    'competitive advantages will it provide?')
@SectionId('OPPST')
class OpportunityStatement {
  @SerializationOrder(0)
  String? content;

  /// Opportunity Details Form.
  @Form([
    Field('opportunitySummary', String, 'Opportunity Summary (one sentence)',
        required: true,
        hint: 'State the core opportunity in a single concise sentence'),
    Field('futureState', String,
        'Future State (describe the TO-BE situation after implementation)',
        hint: 'Describe the TO-BE situation after implementation'),
    Field('newCapabilities', String,
        'New Capabilities (what becomes possible that wasn\'t before)',
        hint: 'What becomes possible that was not possible before'),
    Field('improvements', String,
        'Improvements (quantitative and qualitative improvements expected)',
        hint: 'Quantitative and qualitative improvements expected'),
    Field('competitiveAdvantage', String,
        'Competitive Advantage (market positioning benefits)',
        hint: 'Market positioning benefits the system provides'),
    Field('innovationAspects', String,
        'Innovation Aspects (novel or differentiating features)',
        hint: 'Novel or differentiating features'),
    Field('growthEnablement', String,
        'Growth Enablement (how this supports business growth)',
        hint: 'How the system supports business growth'),
    Field('efficiencyGains', String,
        'Efficiency Gains (productivity and cost improvements)',
        hint: 'Productivity and cost improvements expected'),
    Field('timeToValue', String,
        'Time to Value (when benefits will start being realized)',
        hint: 'When benefits will start being realized'),
  ])
  @SerializationOrder(1)
  TextSection? opportunityDetails;
}

/// 4.1.1.3. Stakeholders and Beneficiaries.
///
/// A scope-framing *benefits lens* over the stakeholder landscape: who
/// benefits from the system and what they gain. The canonical stakeholder
/// register — with role, interest, influence, concerns and engagement
/// strategy — lives in SBP.4 [StakeholderRegister]; those attributes are
/// recorded there once and are not restated here (L34C-6 / SR-15).
@StandardReferences(
  [
    'BABOK v3 §10.43 — stakeholder list/map/personas',
    'ISO/IEC/IEEE 29148 §6 — stakeholders',
  ],
  'Frames the stakeholder landscape through a benefits lens — who benefits '
  'from the system and the value they gain — while the canonical register '
  'lives in SBP.4.',
)
@ContentHelp('Identify the stakeholders and beneficiaries from a benefits '
    'perspective: who they are and the value they gain from the system. '
    'Record the canonical register (role, interest, influence, engagement) '
    'once, in SBP.4 StakeholderRegister — reference it here, do not restate it.')
@SectionId('SAB')
class StakeholdersAndBeneficiaries {
  @ContentType('description', 'Overview of the stakeholder landscape framed by '
      'benefit; reference the canonical SBP.4 StakeholderRegister for the full '
      'role/interest/influence/engagement attributes.')
  @SerializationOrder(0)
  String? content;

  /// Primary stakeholders — contains 1+× StakeholderEntry (benefits lens).
  @StandardReferences(
    ['BABOK v3 §10.43 — stakeholder list/map/personas'],
    'The set of primary stakeholders directly affected by the system, framed '
    'by the benefit each gains.',
  )
  @SectionId('STKNT-PRIM-LST')
  @SectionIdPattern('STKNT-PRIM-xxx')
  @Min(1)
  @ContentHelp('Add one entry per primary stakeholder or group, framed by the '
      'benefit they gain. Primary stakeholders are those directly affected.')
  @SerializationOrder(1)
  List<StakeholderEntry> primaryStakeholders = [];

  /// Secondary stakeholders — contains 0+× StakeholderEntry (benefits lens).
  @StandardReferences(
    ['BABOK v3 §10.43 — stakeholder list/map/personas'],
    'The set of secondary stakeholders indirectly affected by the system, '
    'framed by the benefit each gains.',
  )
  @SectionId('STKNT-SECO-LST')
  @SectionIdPattern('STKNT-SECO-xxx')
  @ContentHelp('Secondary stakeholders are indirectly affected by the system.')
  @SerializationOrder(2)
  List<StakeholderEntry> secondaryStakeholders = [];
}

/// A stakeholder or beneficiary entry — benefits lens (form).
///
/// Keeps only the scope-framing identity + benefit. Role, interest, influence,
/// concerns and engagement strategy are owned by the canonical SBP.4
/// [StakeholderRegisterEntry] and are not restated here (L34C-6 / SR-15).
@StandardReferences(
  ['BABOK v3 §10.43 — stakeholder list/map/personas'],
  'A single stakeholder or beneficiary, identified by name/type and the '
  'scope-framing benefit they gain from the system.',
)
@SectionId('STKNT')
class StakeholderEntry {
  @Form([
    Field('stakeholderName', String, 'Stakeholder Name or Group',
        required: true,
        hint: 'Name of the stakeholder individual or group'),
    Field('stakeholderType', String,
        'Stakeholder Type (Sponsor, User, Customer, Partner, Regulator, etc.)',
        hint: 'Sponsor, User, Customer, Partner, Regulator, etc.'),
    Field('expectedBenefits', String,
        'Expected Benefits (the scope-framing value this group gains from the '
            'system)',
        hint: 'The scope-framing value this group gains from the system'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.1.4. Value Proposition.
///
/// Clear articulation of the value this system provides, including
/// quantifiable benefits and return on investment analysis.
@StandardReferences(
  [
    'BABOK v3 §10 — business value',
    'ISO/IEC/IEEE 29148 §6 — business need/value',
  ],
  'Articulates the business value the system delivers — its core value '
  'statement, quantifiable and qualitative benefits, and how value is '
  'measured.',
)
@ContentHelp('Articulate the business value clearly. Include quantifiable '
    'benefits, ROI expectations, and how value will be measured.')
@SectionId('VALPX')
class ValueProposition {
  @SerializationOrder(0)
  String? content;

  /// Value Proposition Details (form).
  @Form([
    Field('valueStatement', String,
        'Value Statement (concise statement of value delivered)', required: true,
        hint: 'Concise statement of the value the system delivers'),
    Field('primaryBenefits', String,
        'Primary Benefits (top 3-5 benefits in priority order)',
        hint: 'Top 3-5 benefits in priority order'),
    Field('quantifiableBenefits', String,
        'Quantifiable Benefits (measurable improvements with targets)',
        hint: 'Measurable improvements with concrete targets'),
    Field('qualitativeBenefits', String,
        'Qualitative Benefits (non-quantifiable but important benefits)',
        hint: 'Non-quantifiable but important benefits'),
  ])
  @SerializationOrder(1)
  TextSection? valueDetails;

  /// Financial and efficiency benefits.
  @SerializationOrder(2)
  ValuePropositionBenefits benefits = ValuePropositionBenefits();

  /// ROI and realization timeline.
  @SerializationOrder(3)
  ValuePropositionReturnProfile returnProfile =
      ValuePropositionReturnProfile();

  /// Key Performance Indicators for value measurement.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — measures of effectiveness'],
    'The set of key performance indicators by which the system\'s delivered '
    'value will be measured.',
  )
  @SectionId('KPIEN-KPIS-LST')
  @SectionIdPattern('KPIEN-KPIS-xxx')
  @ContentHelp('Add one entry per KPI used to measure delivered value. '
      'Include the metric, its baseline, and its target.')
  @SerializationOrder(4)
  List<KpiEntry> kpis = [];
}

/// Financial and efficiency benefits.
@StandardReferences(
  ['BABOK v3 §10 — business value'],
  'The financial and efficiency benefits of the system — cost savings, '
  'revenue impact, productivity gains, and risk reduction.',
)
@SectionId('VALBN')
class ValuePropositionBenefits {
    @Form([
        Field('costSavings', String,
                'Cost Savings (expected cost reductions and where)',
                hint: 'Expected cost reductions and where they occur'),
        Field('revenueImpact', String,
                'Revenue Impact (how system affects revenue generation)',
                hint: 'How the system affects revenue generation'),
        Field('productivityGains', String,
                'Productivity Gains (efficiency improvements expected)',
                hint: 'Efficiency improvements expected from the system'),
        Field('riskReduction', String,
                'Risk Reduction (operational, compliance, security risks mitigated)',
                hint: 'Operational, compliance, and security risks mitigated'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// ROI and realization timeline.
@StandardReferences(
  ['BABOK v3 §10 — business value'],
  'The return profile of the system — estimated ROI, payback period, and the '
  'timeline over which value is realized.',
)
@SectionId('VALRP')
class ValuePropositionReturnProfile {
    @Form([
        Field('estimatedRoi', String,
                'Estimated ROI (return on investment calculation or estimate)',
                hint: 'Return-on-investment calculation or estimate'),
        Field('paybackPeriod', String,
                'Payback Period (time until investment is recovered)',
                hint: 'Time until the investment is recovered'),
        Field('valueRealizationTimeline', String,
                'Value Realization Timeline (when benefits start accruing)',
                hint: 'When benefits start accruing after delivery'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 4.1.1.5. Strategic Alignment.
///
/// How this system aligns with organizational strategy, goals, and
/// initiatives. Demonstrates strategic justification for the project.
@StandardReferences(
  ['BABOK v3 §6 — strategy analysis (alignment)'],
  'Demonstrates how the system aligns with organizational strategy — '
  'corporate goals, IT roadmap, and strategic initiatives — justifying the '
  'project strategically.',
)
@ContentHelp('Show how this project aligns with organizational strategy. '
    'Reference corporate goals, IT roadmap, and strategic initiatives.')
@SectionId('STRAL')
class StrategicAlignment {
  @SerializationOrder(0)
  String? content;

  /// Strategic Alignment Details (form).
  @Form([
    Field('alignedCorporateGoals', String,
        'Aligned Corporate Goals (which company goals this supports)',
        hint: 'Which company goals this initiative supports'),
    Field('alignedBusinessObjectives', String,
        'Aligned Business Objectives (specific objectives this serves)',
        hint: 'Specific business objectives this serves'),
    Field('alignedItStrategy', String,
        'Aligned IT Strategy (how this fits in the IT roadmap)',
        hint: 'How this fits within the IT roadmap'),
    Field('relatedInitiatives', String,
        'Related Initiatives (other projects or programs this connects to)',
        hint: 'Other projects or programs this connects to'),
    Field('digitizationContribution', String,
        'Digitization Contribution (how this advances digital transformation)',
        hint: 'How this advances digital transformation'),
    Field('innovationContribution', String,
        'Innovation Contribution (how this supports innovation goals)',
        hint: 'How this supports innovation goals'),
    Field('complianceContribution', String,
        'Compliance Contribution (regulatory or policy requirements met)',
        hint: 'Regulatory or policy requirements met'),
    Field('marketPositioning', String,
        'Market Positioning (how this affects competitive position)',
        hint: 'How this affects competitive market position'),
    Field('strategicTimingRationale', String,
        'Strategic Timing (why this is the right time for this initiative)',
        hint: 'Why now is the right time for this initiative'),
  ])
  @SerializationOrder(1)
  TextSection? alignmentDetails;
}

/// 4.1.1.6. Scope Boundaries.
///
/// Clear definition of what is in scope and out of scope for this system.
/// Helps set expectations and prevent scope creep.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — system scope & boundaries',
    'BABOK v3 §10.41 — scope modelling',
  ],
  'Defines the boundaries of the system — what is in scope, out of scope, '
  'and deferred — to set expectations and prevent scope creep.',
)
@ContentHelp('Define clear boundaries. What is included? What is explicitly '
    'excluded? What is deferred to future phases? This prevents scope creep '
    'and sets clear expectations.')
@SectionId('SCBND')
class ScopeBoundaries {
  @SerializationOrder(0)
  String? content;

  /// In-Scope Items — contains 1+× ScopeItem.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — system scope & boundaries'],
    'The set of items explicitly included within the scope of this project.',
  )
  @SectionId('SCITE-INSC-LST')
  @SectionIdPattern('SCITE-INSC-xxx')
  @Min(1)
  @ContentHelp('List all items that are explicitly in scope for this project. '
      'Be specific about features, processes, user groups, and systems.')
  @SerializationOrder(1)
  List<ScopeItemEntry> inScopeItems = [];

  /// Out-of-Scope Items — contains 0+× ScopeItem.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — system scope & boundaries'],
    'The set of items explicitly excluded from the scope of this project.',
  )
  @SectionId('SCITE-OUTO-LST')
  @SectionIdPattern('SCITE-OUTO-xxx')
  @ContentHelp('List items explicitly excluded. This is as important as '
      'in-scope items to prevent misunderstandings and scope creep.')
  @SerializationOrder(2)
  List<ScopeItemEntry> outOfScopeItems = [];

  /// Deferred Items — contains 0+× ScopeItem.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — system scope & boundaries'],
    'The set of items deferred to future phases rather than the current '
    'scope.',
  )
  @SectionId('DFSCP-DEFE-LST')
  @SectionIdPattern('DFSCP-DEFE-xxx')
  @ContentHelp('Items deferred to future phases. Include tentative timing.')
  @SerializationOrder(3)
  List<DeferredScopeItemEntry> deferredItems = [];

  /// Scope Assumptions.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — system scope & boundaries'],
    'The set of assumptions on which the defined scope boundaries depend.',
  )
  @SectionId('SCOPE-SCOP-LST')
  @SectionIdPattern('SCOPE-SCOP-xxx')
  @ContentHelp('Add one entry per assumption that underpins the scope '
      'boundaries. State what is assumed and the impact if it proves false.')
  @SerializationOrder(4)
  List<ScopeAssumptionEntry> scopeAssumptions = [];
}

/// A scope item entry (in-scope or out-of-scope).
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §6 — system scope & boundaries'],
  'A single scope item — its description, category, and the rationale for '
  'including or excluding it.',
)
@SectionId('SIE')
class ScopeItemEntry {
  @Form([
    Field('itemDescription', String, 'Item Description', required: true,
        hint: 'Describe the feature, process, or system in scope or excluded'),
    Field('category', String,
        'Category (Feature, Process, User Group, System, Data, Geography, etc.)',
        hint: 'Feature, Process, User Group, System, Data, Geography, etc.'),
    Field('rationale', String, 'Rationale (why included or excluded)',
        hint: 'Why this item is included or excluded'),
    Field('relatedRequirements', String,
        'Related Requirements (requirement IDs if applicable)',
        hint: 'Requirement IDs related to this item, if applicable'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A deferred scope item entry (for future phases).
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §6 — system scope & boundaries'],
  'A single deferred scope item — its description, target phase, deferral '
  'reason, dependencies, and estimated effort.',
)
@SectionId('DFSCP')
class DeferredScopeItemEntry {
  @Form([
    Field('itemDescription', String, 'Item Description', required: true,
        hint: 'Describe the item being deferred to a future phase'),
    Field('category', String, 'Category (Feature, Process, etc.)',
        hint: 'Feature, Process, etc.'),
    Field('targetPhase', String, 'Target Phase (when this will be addressed)',
        hint: 'Which future phase will address this item'),
    Field('deferralReason', String, 'Deferral Reason (why not in current scope)',
        hint: 'Why this item is not in the current scope'),
    Field('dependencies', String,
        'Dependencies (what must be done before this can be addressed)',
        hint: 'What must be done before this can be addressed'),
    Field('estimatedEffort', String,
        'Estimated Effort (rough sizing for planning purposes)',
        hint: 'Rough sizing for planning purposes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.2 System Context
// ---------------------------------------------------------------------------

/// 4.1.2. System Context.
///
/// Describes the system in its operational context: how it fits within the
/// organization's IT landscape, who interacts with it, and what external
/// systems it connects to. Based on UML context diagrams and IEEE 830.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description (context)',
    'ISO/IEC/IEEE 29148 §6 — system context & boundaries',
  ],
  'Captures the system in its operational context: how it fits the IT '
      'landscape, who interacts with it, and what external systems it '
      'connects to.',
)
@ContentHelp('Describe the system in its operational context. Include: '
    'how it fits in the IT landscape, who interacts with it, '
    'external systems it connects to, and a context diagram.')
@SectionId('SYCTX')
class SystemContext {
  @ContentType('description', 'High-level overview of the system context '
      'and its position in the overall enterprise architecture.')
  @SerializationOrder(0)
  String? content;

  /// 4.1.2.1. Context Diagram.
  @SerializationOrder(1)
  ContextDiagram contextDiagram = ContextDiagram();

  /// 4.1.2.2. IT Landscape Position.
  @SerializationOrder(2)
  ItLandscapePosition itLandscapePosition = ItLandscapePosition();

  /// 4.1.2.3. External Actors.
  @SerializationOrder(3)
  ExternalActors externalActors = ExternalActors();

  /// 4.1.2.4. External Systems.
  @SerializationOrder(4)
  ExternalSystemsContext externalSystems = ExternalSystemsContext();

  /// 4.1.2.5. Trust Boundaries.
  @SerializationOrder(5)
  TrustBoundaries trustBoundaries = TrustBoundaries();

  /// 4.1.2.6. Organizational Context.
  @SerializationOrder(6)
  OrganizationalContext organizationalContext = OrganizationalContext();

  /// 4.1.2.7. Deployment Context.
  @SerializationOrder(7)
  DeploymentContext deploymentContext = DeploymentContext();

  /// 4.1.2.8. Regulatory Context.
  @SerializationOrder(8)
  RegulatoryContext regulatoryContext = RegulatoryContext();
}

/// 4.1.2.1. Context Diagram.
///
/// Visual representation of the system as a black box showing external
/// entities and data flows (UML context diagram / DFD Level 0).
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description (context)',
    'C4 model — system context diagram',
  ],
  'Captures a black-box context diagram of the system showing external '
      'entities and the data flows between them.',
)
@ContentHelp('Provide a context diagram showing the system as a black box '
    'with all external entities (users, systems, organizations) and '
    'the data/control flows between them.')
@SectionId('CD')
class ContextDiagram {
  @ContentHelp('Provide a narrative overview of the context diagram and '
      'what the depicted black-box view represents.')
  @SerializationOrder(0)
  String? content;

  /// Context diagram in Mermaid format.
  @ContentType('mermaid-flowchart', 'Context diagram showing the system '
      'as a central node with external actors and systems connected by '
      'labeled data flows')
  @ContentHelp('Create a Mermaid flowchart with the system in the center '
      'and all external entities around it. Label edges with data flow '
      'descriptions (e.g., "orders", "payments", "notifications").')
  @SerializationOrder(1)
  String? diagram;

  /// Diagram legend and conventions.
  @ContentType('description', 'Legend explaining shapes, colors, and '
      'line styles used in the diagram.')
  @SerializationOrder(2)
  String? legend;
}

/// 4.1.2.2. IT Landscape Position.
///
/// How this system fits within the organization's overall IT architecture
/// and application portfolio.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — environment/context',
    'TOGAF — baseline architecture landscape',
  ],
  'Captures how this system fits the organization\'s overall IT '
      'architecture and application portfolio.',
)
@ContentHelp('Describe how this system fits in the overall IT architecture. '
    'What role does it play? What other systems does it complement or replace?')
@SectionId('ILP')
class ItLandscapePosition {
  @ContentHelp('Provide a narrative overview of the system\'s position '
      'within the IT landscape before the structured details below.')
  @SerializationOrder(0)
  String? content;

  /// IT Landscape Position Details (form).
  @Form([
    Field('architectureLayer', String,
        'Architecture Layer (Presentation, Business, Data, Integration)',
        hint: 'Which architecture layer this system primarily belongs to'),
    Field('applicationCategory', String,
        'Application Category (Core, Support, Management, Infrastructure)',
        hint: 'The portfolio category this application falls under'),
    Field('portfolioRole', String,
        'Portfolio Role (Strategic, Key Operational, Support, Legacy)',
        hint: 'The strategic role this system plays in the portfolio'),
    Field('replacedSystems', String,
        'Replaced Systems (systems this will replace or retire)',
        hint: 'Systems this will replace or retire'),
    Field('complementarySystems', String,
        'Complementary Systems (systems this works alongside)',
        hint: 'Systems this works alongside'),
    Field('dependsOnSystems', String,
        'Depends On Systems (systems this requires to operate)',
        hint: 'Systems this requires to operate'),
    Field('dependentSystems', String,
        'Dependent Systems (systems that will depend on this)',
        hint: 'Systems that will depend on this one'),
    Field('dataOwnership', String,
        'Data Ownership (what master data does this system own)',
        hint: 'What master data this system owns'),
    Field('integrationPattern', String,
        'Primary Integration Pattern (API, Event, Batch, Real-time)',
        hint: 'The primary integration pattern used'),
  ])
  @SerializationOrder(1)
  TextSection? positionDetails;
}

/// 4.1.2.3. External Actors.
///
/// Human users and organizational entities that interact with the system
/// from outside the system boundary.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
    'BABOK v3 §10.43 — stakeholder/actor analysis',
  ],
  'Captures the human users and organizational entities that interact '
      'with the system from outside its boundary.',
)
@ContentHelp('List all external actors (human users, organizations, '
    'external parties) that interact with the system.')
@SectionId('EA')
class ExternalActors {
  @ContentType('description', 'Overview of external actors and '
      'their interaction patterns with the system.')
  @SerializationOrder(0)
  String? content;

  /// Actor entries — contains 1+× ExternalActorEntry.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — external interfaces & actors'],
    'The set of individual external-actor entries for this system.',
  )
  @SectionId('EAE-ACTO-LST')
  @SectionIdPattern('EAE-ACTO-xxx')
  @Min(1)
  @ContentHelp('Add one entry per external actor or actor category '
      'that interacts with the system.')
  @SerializationOrder(1)
  List<ExternalActorEntry> actors = [];
}

/// An external actor entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
    'BABOK v3 §10.43 — stakeholder/actor analysis',
  ],
  'Captures a single external actor: its name, type, description, and '
      'why it interacts with the system.',
)
@SectionId('EAE')
class ExternalActorEntry {
  @Form([
    Field('actorName', String, 'Actor Name', required: true,
        hint: 'The name of this external actor'),
    Field('actorType', String,
        'Actor Type (Internal User, External User, Organization, '
            'Partner, Customer, Regulator, etc.)', required: true,
        hint: 'The category of actor'),
    Field('description', String, 'Actor Description',
        hint: 'A short description of this actor'),
    Field('interactionPurpose', String,
        'Interaction Purpose (why they interact with the system)',
        hint: 'Why this actor interacts with the system'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Interaction cadence and exchanged information.
  @SerializationOrder(1)
  ExternalActorEntryInteraction interaction = ExternalActorEntryInteraction();

  /// Access, authentication, and context details.
  @SerializationOrder(2)
  ExternalActorEntryContext context = ExternalActorEntryContext();

  /// Interaction scenarios for this actor.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — external interfaces & actors'],
    'The set of interaction-scenario entries for this actor.',
  )
  @SectionId('INTER-INTE-LST')
  @SectionIdPattern('INTER-INTE-xxx')
  @ContentHelp('Add one entry per interaction scenario between this actor '
      'and the system.')
  @SerializationOrder(3)
  List<InteractionScenarioEntry> interactionScenarios = [];
}

/// Interaction cadence and exchanged information.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
    'BABOK v3 §10.43 — stakeholder/actor analysis',
  ],
  'Captures the cadence and channel of an actor\'s interaction and the '
      'information exchanged with the system.',
)
@SectionId('EAEI')
class ExternalActorEntryInteraction {
  @Form([
    Field('interactionFrequency', String,
        'Interaction Frequency (Real-time, Daily, Weekly, On-demand)',
        hint: 'How often this actor interacts with the system'),
    Field('interactionChannel', String,
        'Interaction Channel (Web UI, Mobile App, API, Email, etc.)',
        hint: 'The channel through which the interaction occurs'),
    Field('dataExchanged', String,
        'Data Exchanged (what information flows to/from this actor)',
        hint: 'What information flows to and from this actor'),
    Field('accessLevel', String,
        'Access Level (Read, Write, Admin, API-only, etc.)',
        hint: 'The level of access this actor has'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access, authentication, and context details.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
    'ISO/IEC 27001 Annex A — access control',
  ],
  'Captures an actor\'s access, authentication, location, and volume '
      'context relative to the system.',
)
@SectionId('EAEC')
class ExternalActorEntryContext {
  @Form([
    Field('authenticationMethod', String,
        'Authentication Method (SSO, Password, Certificate, API Key, etc.)',
        hint: 'How this actor authenticates'),
    Field('location', String,
        'Location (On-site, Remote, Mobile, Global, etc.)',
        hint: 'Where this actor accesses the system from'),
    Field('volumeEstimate', String,
        'Volume Estimate (number of actors, transactions per day)',
        hint: 'Estimated number of actors or transactions per day'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.2.4. External Systems.
///
/// External systems, services, and APIs that the system integrates with.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external system interfaces',
    'ISO/IEC/IEEE 42010 — context',
  ],
  'Captures the external systems, services, and APIs the system '
      'integrates with, inbound and outbound.',
)
@ContentHelp('List all external systems, services, and APIs that this '
    'system will integrate with. Include both incoming and outgoing '
    'integrations.')
@SectionId('ESC')
class ExternalSystemsContext {
  @ContentType('description', 'Overview of external system integrations '
      'and integration architecture.')
  @SerializationOrder(0)
  String? content;

  /// External system entries — contains 0+× ExternalSystemContextEntry.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — external system interfaces'],
    'The set of individual external-system integration entries.',
  )
  @SectionId('EXSYCOEN-SYST-LST')
  @SectionIdPattern('EXSYCOEN-SYST-xxx')
  @ContentHelp('Add one entry per external system that this system '
      'integrates with.')
  @SerializationOrder(1)
  List<ExternalSystemContextEntry> systems = [];
}

/// An external system context entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external system interfaces',
    'ISO/IEC/IEEE 42010 — context',
  ],
  'Captures a single external system the platform integrates with: its '
      'name, owner, and type.',
)
@SectionId('EXSYCOEN')
class ExternalSystemContextEntry {
  @Form([
    Field('systemName', String, 'System Name', required: true,
        hint: 'The name of this external system'),
    Field('systemOwner', String, 'System Owner (organization/department)',
        hint: 'The organization or department that owns this system'),
    Field('systemType', String,
        'System Type (ERP, CRM, Database, API, SaaS, Legacy, etc.)',
        required: true, hint: 'The category of external system'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Integration intent and exchanged information.
  @SerializationOrder(1)
  ExternalSystemContextEntryIntegration integration =
      ExternalSystemContextEntryIntegration();

  /// Operational delivery characteristics.
  @SerializationOrder(2)
  ExternalSystemContextEntryOperations operations =
      ExternalSystemContextEntryOperations();

  /// Security and support contacts.
  @SerializationOrder(3)
  ExternalSystemContextEntryGovernance governance =
      ExternalSystemContextEntryGovernance();

  /// Data mapping details.
  @ContentType('description', 'Details of data transformation and '
      'mapping between systems.')
  @SerializationOrder(4)
  String? dataMapping;
}

/// Integration intent and exchanged information.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external system interfaces',
    'ISO/IEC/IEEE 42010 — context',
  ],
  'Captures the direction, purpose, data, and method of an external '
      'system integration.',
)
@SectionId('EXSYCOENIN')
class ExternalSystemContextEntryIntegration {
  @Form([
    Field('integrationDirection', String,
        'Integration Direction (Inbound, Outbound, Bidirectional)',
        required: true,
        hint: 'The direction in which data flows for this integration'),
    Field('integrationPurpose', String,
        'Integration Purpose (what business need does this serve)',
        hint: 'The business need this integration serves'),
    Field('dataExchanged', String,
        'Data Exchanged (what data flows between systems)',
        hint: 'What data flows between the systems'),
    Field('integrationMethod', String,
        'Integration Method (REST API, SOAP, File Transfer, Database, '
            'Message Queue, Event Stream, etc.)',
        hint: 'The technical method used for the integration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operational delivery characteristics for an external system context.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — external system interfaces',
    'ISO/IEC/IEEE 42010 — context',
  ],
  'Captures the operational delivery characteristics of an external '
      'system integration: frequency, volume, SLA, and error handling.',
)
@SectionId('ESCEO')
class ExternalSystemContextEntryOperations {
  @Form([
    Field('integrationFrequency', String,
        'Integration Frequency (Real-time, Near-real-time, Batch, '
            'On-demand)',
        hint: 'How often the integration runs'),
    Field('dataVolume', String,
        'Data Volume (estimated records/transactions per time period)',
        hint: 'Estimated records or transactions per time period'),
    Field('sla', String,
        'SLA (availability, response time requirements)',
        hint: 'Availability and response-time requirements'),
    Field('errorHandling', String,
        'Error Handling (retry, dead-letter, manual intervention)',
        hint: 'How integration errors are handled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security and support contacts for an external system context.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security boundaries',
    'ISO/IEC/IEEE 29148 §6 — external system interfaces',
  ],
  'Captures the security requirements and technical contact governing an '
      'external system integration.',
)
@SectionId('ESCEG')
class ExternalSystemContextEntryGovernance {
  @Form([
    Field('securityRequirements', String,
        'Security Requirements (encryption, authentication, network)',
        hint: 'Encryption, authentication, and network requirements'),
    Field('contactPerson', String, 'Contact Person (technical contact)',
        hint: 'The technical contact for this integration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.2.5. Trust Boundaries.
///
/// Security zones and trust boundaries that the system operates within
/// or crosses.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security boundaries',
    'ISO/IEC/IEEE 42010 — context',
  ],
  'Captures the security zones and trust boundaries the system operates '
      'within or crosses.',
)
@ContentHelp('Define the trust boundaries (security zones) that the system '
    'operates within and crosses. This is important for security design.')
@SectionId('TB')
class TrustBoundaries {
  @ContentType('description', 'Overview of trust boundaries and '
      'security zones relevant to this system.')
  @SerializationOrder(0)
  String? content;

  /// Trust boundary entries — contains 0+× TrustBoundaryEntry.
  @StandardReferences(
    ['ISO/IEC 27001 Annex A — security boundaries'],
    'The set of individual trust-boundary entries for this system.',
  )
  @SectionId('TRBN-BOUN-LST')
  @SectionIdPattern('TRBN-BOUN-xxx')
  @ContentHelp('Add one entry per trust boundary or security zone.')
  @SerializationOrder(1)
  List<TrustBoundaryEntry> boundaries = [];
}

/// A trust boundary entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security boundaries',
    'ISO/IEC/IEEE 42010 — context',
  ],
  'Captures a single trust boundary or security zone, what crosses it, '
      'and its protection mechanisms.',
)
@SectionId('TRBN')
class TrustBoundaryEntry {
  @Form([
    Field('boundaryName', String, 'Boundary Name', required: true,
        hint: 'The name of this trust boundary'),
    Field('boundaryType', String,
        'Boundary Type (Network Zone, Authentication Domain, '
            'Organizational, Legal/Regulatory, Cloud/On-Prem)', required: true,
        hint: 'The category of trust boundary'),
    Field('description', String, 'Description',
        hint: 'A short description of this boundary'),
    Field('componentsCrossing', String,
        'Components Crossing (which parts of the system cross this boundary)',
        hint: 'Which parts of the system cross this boundary'),
    Field('protectionMechanisms', String,
        'Protection Mechanisms (firewall, encryption, authentication, etc.)',
        hint: 'Mechanisms protecting this boundary'),
    Field('trustLevel', String,
        'Trust Level (Untrusted, Semi-trusted, Trusted, Highly Trusted)',
        hint: 'The trust level on the other side of this boundary'),
    Field('complianceImplications', String,
        'Compliance Implications (regulatory requirements for crossing)',
        hint: 'Regulatory requirements for crossing this boundary'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.2.6. Organizational Context.
///
/// Organizational units, departments, and business areas that the system
/// serves or interacts with.
@StandardReferences(
  [
    'TOGAF — organization context',
    'BABOK v3 §10 — organizational modelling',
  ],
  'Captures the organizational units, departments, and business areas the '
      'system serves or interacts with.',
)
@ContentHelp('Describe the organizational context: which departments, '
    'business units, and organizational structures are involved.')
@SectionId('OC')
class OrganizationalContext {
  @ContentHelp('Provide a narrative overview of the organizational context '
      'before the structured organizational-unit entries below.')
  @SerializationOrder(0)
  String? content;

  /// Organizational unit entries — contains 0+× OrganizationalUnitContextEntry.
  @StandardReferences(
    ['TOGAF — organization context'],
    'The set of individual organizational-unit entries for this system.',
  )
  @SectionId('OUCE-ORGA-LST')
  @SectionIdPattern('OUCE-ORGA-xxx')
  @ContentHelp('Add one entry per organizational unit that uses or '
      'is affected by the system.')
  @SerializationOrder(1)
  List<OrganizationalUnitContextEntry> organizationalUnits = [];

  /// Business process coverage.
  @ContentType('description', 'Which business processes does this system '
      'support or automate?')
  @SerializationOrder(2)
  String? businessProcessCoverage;
}

/// An organizational unit context entry (form).
@StandardReferences(
  [
    'TOGAF — organization context',
    'BABOK v3 §10 — organizational modelling',
  ],
  'Captures a single organizational unit that uses or is affected by the '
      'system, including its role and responsibilities.',
)
@SectionId('OUCE')
class OrganizationalUnitContextEntry {
  @Form([
    Field('unitName', String, 'Unit Name', required: true,
        hint: 'The name of this organizational unit'),
    Field('unitType', String,
        'Unit Type (Department, Division, Team, Business Unit, '
            'Subsidiary, External Partner)',
        hint: 'The category of organizational unit'),
    Field('role', String, 'Role (Primary User, Secondary User, '
        'Data Provider, Beneficiary, Sponsor)',
        hint: 'The role this unit plays relative to the system'),
    Field('responsibilities', String,
        'Responsibilities (what they do with/for the system)',
        hint: 'What this unit does with or for the system'),
    Field('headcount', String, 'Headcount (estimated number of users)',
        hint: 'Estimated number of users in this unit'),
    Field('location', String, 'Location (geographic location)',
        hint: 'The geographic location of this unit'),
    Field('timezone', String, 'Timezone (primary operating timezone)',
        hint: 'The primary operating timezone of this unit'),
    Field('keyContacts', String, 'Key Contacts (business contacts)',
        hint: 'Business contacts for this unit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.2.7. Deployment Context.
///
/// Where and how the system will be deployed in the infrastructure
/// landscape.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — deployment environment',
    'TOGAF — technology/deployment landscape',
  ],
  'Captures where and how the system will be deployed within the '
      'infrastructure landscape, including constraints.',
)
@ContentHelp('Describe the deployment context: where the system will be '
    'deployed, what infrastructure it will use, and deployment constraints.')
@SectionId('DC')
class DeploymentContext {
  @ContentHelp('Provide a narrative overview of the deployment context '
      'before the structured deployment details below.')
  @SerializationOrder(0)
  String? content;

  /// Deployment Context Details (form).
  @Form([
    Field('deploymentModel', String,
        'Deployment Model (On-Premises, Cloud, Hybrid, Multi-Cloud)',
        hint: 'The overall deployment model'),
    Field('cloudProvider', String,
        'Cloud Provider (AWS, Azure, GCP, Private Cloud, N/A)',
        hint: 'The cloud provider, if any'),
    Field('hostingEnvironment', String,
        'Hosting Environment (Containers, VMs, Serverless, Bare Metal)',
        hint: 'The hosting environment type'),
    Field('dataCenter', String,
        'Data Center (location, name, or identifier)',
        hint: 'The data center location, name, or identifier'),
    Field('geographicDistribution', String,
        'Geographic Distribution (Single region, Multi-region, Global)',
        hint: 'How the deployment is distributed geographically'),
    Field('availabilityZones', String,
        'Availability Zones (redundancy configuration)',
        hint: 'The redundancy / availability-zone configuration'),
    Field('networkZone', String,
        'Network Zone (DMZ, Internal, Private, Public)',
        hint: 'The network zone the system is deployed in'),
    Field('scalingModel', String,
        'Scaling Model (Horizontal, Vertical, Auto-scaling, Manual)',
        hint: 'The scaling model used'),
    Field('disasterRecovery', String,
        'Disaster Recovery (DR site, strategy)',
        hint: 'The disaster-recovery site and strategy'),
    Field('environmentTypes', String,
        'Environment Types (Dev, Test, Staging, Production, DR)',
        hint: 'Which environment types exist'),
  ])
  @SerializationOrder(1)
  TextSection? deploymentDetails;
}

/// 4.1.2.8. Regulatory Context.
///
/// Regulatory and compliance context that affects system design and
/// operations.
@StandardReferences(
  [
    'ISO/IEC 27001 — compliance with legal & contractual requirements',
    'ISO/IEC/IEEE 29148 §6 — regulatory constraints',
  ],
  'Captures the regulatory and compliance context affecting the system\'s '
      'design and operations.',
)
@ContentHelp('Describe the regulatory and compliance context: which '
    'regulations apply, what compliance requirements exist.')
@SectionId('RC1')
class RegulatoryContext {
  @ContentType('description', 'Overview of the regulatory environment '
      'and compliance requirements affecting this system.')
  @SerializationOrder(0)
  String? content;

  /// Applicable regulations — contains 0+× ApplicableRegulationEntry.
  @StandardReferences(
    ['ISO/IEC 27001 — compliance with legal & contractual requirements'],
    'The set of individual applicable-regulation entries for this system.',
  )
  @SectionId('ARE-REGU-LST')
  @SectionIdPattern('ARE-REGU-xxx')
  @ContentHelp('Add one entry per applicable regulation or compliance '
      'requirement.')
  @SerializationOrder(1)
  List<ApplicableRegulationEntry> regulations = [];
}

/// An applicable regulation entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001 — compliance with legal & contractual requirements',
    'ISO/IEC/IEEE 29148 §6 — regulatory constraints',
  ],
  'Captures a single applicable regulation or compliance requirement, '
      'its scope, key requirements, and compliance status.',
)
@SectionId('ARE')
class ApplicableRegulationEntry {
  @Form([
    Field('regulationName', String, 'Regulation Name', required: true,
        hint: 'The name of this regulation'),
    Field('regulationCode', String, 'Regulation Code / Reference',
        hint: 'The code or reference identifier for this regulation'),
    Field('regulationType', String,
        'Regulation Type (Privacy, Security, Financial, Industry, '
            'Data Retention, Accessibility)', required: true,
        hint: 'The category of regulation'),
    Field('jurisdiction', String,
        'Jurisdiction (Geographic or organizational scope)',
        hint: 'The geographic or organizational scope of this regulation'),
    Field('applicability', String,
        'Applicability (why this regulation applies to this system)',
        hint: 'Why this regulation applies to this system'),
    Field('keyRequirements', String,
        'Key Requirements (summary of main requirements)',
        hint: 'A summary of the main requirements'),
    Field('complianceStatus', String,
        'Compliance Status (Compliant, Partially Compliant, Non-Compliant, '
            'To Be Assessed)',
        hint: 'The current compliance status'),
    Field('complianceOwner', String,
        'Compliance Owner (who is responsible for compliance)',
        hint: 'Who is responsible for compliance'),
    Field('auditRequirements', String,
        'Audit Requirements (audit frequency, type)',
        hint: 'Audit frequency and type required'),
    Field('penalties', String,
        'Penalties (consequences of non-compliance)',
        hint: 'Consequences of non-compliance'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Specific compliance measures for this regulation.
  @StandardReferences(
    ['ISO/IEC 27001 — compliance with legal & contractual requirements'],
    'The set of specific compliance-measure entries for this regulation.',
  )
  @SectionId('COMPL-COMP-LST')
  @SectionIdPattern('COMPL-COMP-xxx')
  @ContentHelp('Add one entry per compliance measure taken to satisfy '
      'this regulation.')
  @SerializationOrder(1)
  List<ComplianceMeasureEntry> complianceMeasures = [];
}

// ---------------------------------------------------------------------------
// 4.1.3 Description of Business Domain
// ---------------------------------------------------------------------------

/// 4.1.3. Description of Business Domain.
///
/// Describes the business domain and task area the system addresses.
/// Defines the domain vocabulary and key concepts (ubiquitous language)
/// that will be used throughout the project. Based on Domain-Driven Design
/// principles for establishing a shared understanding.
@StandardReferences(
  [
    'BABOK v3 §10 — domain modelling',
    'ISO/IEC/IEEE 29148 §6 — business/problem domain',
  ],
  'Captures the business domain and task area the system addresses, '
      'establishing the ubiquitous language, key concepts, boundaries, '
      'rules, processes, and events of that domain.',
)
@ContentHelp('Describe the business domain and task area this system '
    'addresses. Define the domain vocabulary and key concepts that will '
    'be used throughout the project documentation. This establishes '
    'the ubiquitous language for the project.')
@SectionId('TA')
class BusinessDomain {
  @ContentType('description', 'High-level overview of the business domain '
      'and task area, explaining what business activities and processes '
      'this system will support.')
  @SerializationOrder(0)
  String? content;

  /// 4.1.3.1. Domain Overview.
  @SerializationOrder(1)
  DomainOverview domainOverview = DomainOverview();

  /// 4.1.3.2. Domain Vocabulary.
  @SerializationOrder(2)
  DomainVocabulary domainVocabulary = DomainVocabulary();

  /// 4.1.3.3. Key Concepts.
  @SerializationOrder(3)
  KeyConcepts keyConcepts = KeyConcepts();

  /// 4.1.3.4. Domain Boundaries.
  @SerializationOrder(4)
  DomainBoundaries domainBoundaries = DomainBoundaries();

  /// 4.1.3.5. Business Rules.
  @SerializationOrder(5)
  DomainBusinessRules businessRules = DomainBusinessRules();

  /// 4.1.3.6. Domain Processes.
  @SerializationOrder(6)
  DomainProcesses domainProcesses = DomainProcesses();

  /// 4.1.3.7. Domain Events.
  @SerializationOrder(7)
  DomainEvents domainEvents = DomainEvents();
}

/// 4.1.3.1. Domain Overview.
///
/// High-level description of the business domain including its purpose,
/// scope, and relationship to the overall business.
@StandardReferences(
  [
    'BABOK v3 §10 — domain modelling',
    'ISO/IEC/IEEE 29148 §6 — business/problem domain',
  ],
  'Gives a high-level overview of the business domain: its purpose, '
      'scope, importance, and relationship to other domains.',
)
@ContentHelp('Provide a comprehensive overview of the business domain: '
    'what area of business it covers, its importance to the organization, '
    'and how it relates to other business domains.')
@SectionId('DO')
class DomainOverview {
  @SerializationOrder(0)
  String? content;

  /// Domain Overview Details (form).
  @Form([
    Field('domainName', String, 'Domain Name', required: true,
        hint: 'Name of the business domain this section describes'),
    Field('domainDescription', String,
        'Domain Description (what this domain encompasses)',
        hint: 'What business activities and concepts this domain covers'),
    Field('businessImportance', String,
        'Business Importance (why this domain matters to the organization)',
        hint: 'Why this domain is important to the organization'),
    Field('industryContext', String,
        'Industry Context (how this domain fits in the industry)',
        hint: 'How this domain fits within the broader industry'),
    Field('relatedDomains', String,
        'Related Domains (other business domains this interacts with)',
        hint: 'Other business domains this one interacts with'),
    Field('domainOwner', String,
        'Domain Owner (business unit or person responsible)',
        hint: 'Business unit or person responsible for this domain'),
    Field('keyStakeholders', String,
        'Key Stakeholders (who has interest in this domain)',
        hint: 'Who has a stake or interest in this domain'),
    Field('domainMaturity', String,
        'Domain Maturity (Emerging, Established, Mature, Legacy)',
        hint: 'Emerging / Established / Mature / Legacy'),
    Field('changeFrequency', String,
        'Change Frequency (how often this domain changes)',
        hint: 'How often this domain is expected to change'),
  ])
  @SerializationOrder(1)
  TextSection? domainDetails;
}

/// 4.1.3.2. Domain Vocabulary.
///
/// Glossary of domain-specific terms and definitions establishing the
/// ubiquitous language for the project.
@StandardReferences(
  [
    'Domain-Driven Design — ubiquitous language',
    'ISO/IEC/IEEE 24765 — vocabulary/terms',
  ],
  'Captures the glossary of domain-specific terms and definitions that '
      'form the shared ubiquitous language for the project.',
)
@ContentHelp('Define all domain-specific terms and their meanings. '
    'This glossary establishes the ubiquitous language - the shared '
    'vocabulary that all team members and stakeholders will use.')
@SectionId('DV')
class DomainVocabulary {
  @ContentType('description', 'Introduction to the domain vocabulary '
      'and guidelines for using consistent terminology.')
  @SerializationOrder(0)
  String? content;

  /// Vocabulary entries — contains 1+× DomainTermEntry.
  @StandardReferences(
    [
      'Domain-Driven Design — ubiquitous language',
      'ISO/IEC/IEEE 24765 — vocabulary/terms',
    ],
    'The set of individual domain-term glossary entries.',
  )
  @SectionId('DTE-TERM-LST')
  @SectionIdPattern('DTE-TERM-xxx')
  @Min(1)
  @ContentHelp('Add one entry per domain term. Include all business-specific '
      'terms that may be unfamiliar or have domain-specific meanings.')
  @SerializationOrder(1)
  List<DomainTermEntry> terms = [];
}

/// A domain term entry (form).
@StandardReferences(
  [
    'Domain-Driven Design — ubiquitous language',
    'ISO/IEC/IEEE 24765 — vocabulary/terms',
  ],
  'A single domain-vocabulary term with its definition and usage detail.',
)
@SectionId('DTE')
class DomainTermEntry {
  @Form([
    Field('term', String, 'Term', required: true,
        hint: 'The domain term being defined'),
    Field('definition', String, 'Definition', required: true,
        hint: 'Precise meaning of the term in this domain'),
    Field('synonyms', String, 'Synonyms (alternative terms sometimes used)',
        hint: 'Alternative terms sometimes used for the same concept'),
    Field('antiPatterns', String,
        'Anti-Patterns (terms to avoid, incorrect usage)',
        hint: 'Terms to avoid or incorrect usages of this term'),
    Field('examples', String, 'Examples (usage examples)',
        hint: 'Concrete examples of the term in use'),
    Field('relatedTerms', String, 'Related Terms (linked concepts)',
        hint: 'Other terms or concepts linked to this one'),
    Field('category', String,
        'Category (Entity, Process, Role, Metric, Status, etc.)',
        hint: 'Entity / Process / Role / Metric / Status, etc.'),
    Field('source', String,
        'Source (where this definition comes from: industry, company, etc.)',
        hint: 'Where this definition originates (industry, company, etc.)'),
    Field('abbreviation', String, 'Abbreviation (if commonly abbreviated)',
        hint: 'Common abbreviation for the term, if any'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.3.3. Key Concepts.
///
/// Core business concepts and entities in the domain, their attributes,
/// and relationships (conceptual domain model).
@StandardReferences(
  [
    'Domain-Driven Design — domain model concepts',
    'BABOK v3 §10 — concept modelling',
  ],
  'Captures the core business concepts and entities of the domain, their '
      'attributes, and relationships as a conceptual domain model.',
)
@ContentHelp('Describe the key concepts (entities, value objects, aggregates) '
    'in the domain. This is the conceptual domain model showing core '
    'business objects and their relationships.')
@SectionId('KC')
class KeyConcepts {
  @SerializationOrder(0)
  String? content;

  /// Conceptual domain model diagram.
  @ContentType('mermaid-classDiagram', 'Conceptual domain model showing '
      'key entities and their relationships')
  @ContentHelp('Create a Mermaid class diagram showing the main domain '
      'concepts and their relationships. Focus on business concepts, '
      'not technical implementation.')
  @SerializationOrder(1)
  String? conceptualModelDiagram;

  /// Key concept entries — contains 1+× KeyConceptEntry.
  @StandardReferences(
    [
      'Domain-Driven Design — domain model concepts',
      'BABOK v3 §10 — concept modelling',
    ],
    'The set of individual key-concept entries for the domain.',
  )
  @SectionId('KECON-CONC-LST')
  @SectionIdPattern('KECON-CONC-xxx')
  @Min(1)
  @ContentHelp('Add one entry per key business concept or entity.')
  @SerializationOrder(2)
  List<KeyConceptEntry> concepts = [];
}

/// A key concept entry (form).
@StandardReferences(
  [
    'Domain-Driven Design — domain model concepts',
    'BABOK v3 §10 — concept modelling',
  ],
  'A single key domain concept or entity with its attributes, lifecycle, '
      'ownership, and relationships.',
)
@SectionId('KECON')
class KeyConceptEntry {
  @Form([
    Field('conceptName', String, 'Concept Name', required: true,
        hint: 'Name of the business concept or entity'),
    Field('conceptType', String,
        'Concept Type (Entity, Value Object, Aggregate Root, Event, Service)',
        required: true,
        hint: 'Entity / Value Object / Aggregate Root / Event / Service'),
    Field('description', String, 'Description', required: true,
        hint: 'What this concept represents in the domain'),
    Field('keyAttributes', String,
        'Key Attributes (main properties of this concept)',
        hint: 'Main properties or attributes of this concept'),
    Field('identifiedBy', String,
        'Identified By (what uniquely identifies instances)',
        hint: 'What uniquely identifies instances of this concept'),
    Field('lifecycle', String,
        'Lifecycle (how instances are created, modified, archived)',
        hint: 'How instances are created, modified, and archived'),
    Field('ownedBy', String,
        'Owned By (which business function owns this concept)',
        hint: 'Which business function owns this concept'),
    Field('relatedConcepts', String,
        'Related Concepts (other concepts this relates to)',
        hint: 'Other concepts this one relates to'),
    Field('businessRules', String,
        'Business Rules (rules that govern this concept)',
        hint: 'Business rules that govern this concept'),
    Field('volumeEstimate', String,
        'Volume Estimate (expected number of instances)',
        hint: 'Expected number of instances of this concept'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Detailed attribute definitions for this concept.
  @SerializationOrder(1)
  TextSection? attributeDetails;

  /// Relationships to other concepts.
  @SerializationOrder(2)
  TextSection? relationshipDetails;
}

/// 4.1.3.4. Domain Boundaries.
///
/// Clear definition of what is within and outside the domain scope,
/// based on bounded context principles.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts',
    'ISO/IEC/IEEE 42010 — context boundaries',
  ],
  'Defines what lies inside and outside this domain\'s scope and how it '
      'interfaces with adjacent domains, establishing its bounded context.',
)
@ContentHelp('Define clear boundaries for this domain: what concepts, '
    'processes, and responsibilities are within scope, and what belongs '
    'to adjacent domains. This establishes the bounded context.')
@SectionId('DB')
class DomainBoundaries {
  @SerializationOrder(0)
  String? content;

  /// Context map showing domain boundaries.
  @ContentType('mermaid-flowchart', 'Context map showing this domain '
      'and its relationships to adjacent domains')
  @ContentHelp('Create a context map showing this domain (bounded context) '
      'and how it relates to other domains/contexts.')
  @SerializationOrder(1)
  String? contextMap;

  /// Within-scope items.
  @ContentType('description', 'Concepts, processes, and responsibilities '
      'that are within this domain\'s scope.')
  @SerializationOrder(2)
  String? withinScope;

  /// Outside-scope items.
  @ContentType('description', 'Concepts and responsibilities that belong '
      'to other domains and are outside this domain\'s scope.')
  @SerializationOrder(3)
  String? outsideScope;

  /// Domain interfaces — contains 0+× DomainInterfaceEntry.
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts',
      'ISO/IEC/IEEE 42010 — context boundaries',
    ],
    'The set of interface entries describing how this domain connects to '
        'adjacent domains.',
  )
  @SectionId('DIE-INTE-LST')
  @SectionIdPattern('DIE-INTE-xxx')
  @ContentHelp('Define interfaces to adjacent domains - how this domain '
      'communicates with and shares data with other domains.')
  @SerializationOrder(4)
  List<DomainInterfaceEntry> interfaces = [];
}

/// A domain interface entry (form).
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts',
    'ISO/IEC/IEEE 42010 — context boundaries',
  ],
  'A single interface between this domain and an adjacent domain, '
      'describing its type, direction, data exchange, and ownership.',
)
@SectionId('DIE')
class DomainInterfaceEntry {
  @Form([
    Field('adjacentDomain', String, 'Adjacent Domain Name', required: true,
        hint: 'Name of the adjacent domain this interface connects to'),
    Field('interfaceType', String,
        'Interface Type (Shared Kernel, Customer-Supplier, '
            'Conformist, Anti-Corruption Layer, Published Language)',
        required: true,
        hint: 'Shared Kernel / Customer-Supplier / Conformist / '
            'Anti-Corruption Layer / Published Language'),
    Field('direction', String,
        'Direction (Upstream, Downstream, Bidirectional)',
        hint: 'Upstream / Downstream / Bidirectional'),
    Field('dataExchanged', String,
        'Data Exchanged (what information crosses the boundary)',
        hint: 'What information crosses this domain boundary'),
    Field('integrationMechanism', String,
        'Integration Mechanism (API, Events, Shared Database, etc.)',
        hint: 'API / Events / Shared Database, etc.'),
    Field('translationRequired', String,
        'Translation Required (does data need transformation?)',
        hint: 'Whether data needs transformation across the boundary'),
    Field('owner', String,
        'Owner (who owns this interface)',
        hint: 'Who owns and maintains this interface'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.3.5. Domain Business Rules.
///
/// Business rules, policies, and constraints that govern behavior
/// within this domain.
@StandardReferences(
  [
    'BABOK v3 §10.9 — business rules analysis',
    'ISO/IEC/IEEE 29148 §6 — business rules',
  ],
  'Captures the business rules, policies, and constraints that govern '
      'behavior within this domain.',
)
@ContentHelp('Document the business rules that govern this domain. '
    'Include policies, constraints, calculations, and decision logic.')
@SectionId('DBR')
class DomainBusinessRules {
  @ContentType('description', 'Overview of business rules and their '
      'importance in this domain.')
  @SerializationOrder(0)
  String? content;

  /// Business rule entries — contains 0+× BusinessRuleEntry.
  @StandardReferences(
    [
      'BABOK v3 §10.9 — business rules analysis',
      'ISO/IEC/IEEE 29148 §6 — business rules',
    ],
    'The set of individual business-rule entries for this domain.',
  )
  @SectionId('DOBIRU-RULE-LST')
  @SectionIdPattern('DOBIRU-RULE-xxx')
  @ContentHelp('Add one entry per business rule. Be specific and unambiguous.')
  @SerializationOrder(1)
  List<DomainBusinessRuleEntry> rules = [];
}

/// A domain business rule entry (form).
@StandardReferences(
  [
    'BABOK v3 §10.9 — business rules analysis',
    'ISO/IEC/IEEE 29148 §6 — business rules',
  ],
  'A single domain business rule with its type, plain-language description, '
      'formal definition, and governance metadata.',
)
@SectionId('DBRE')
class DomainBusinessRuleEntry {
  @Form([
    Field('ruleId', String, 'Rule ID', required: true,
        hint: 'Unique identifier for this business rule'),
    Field('ruleName', String, 'Rule Name', required: true,
        hint: 'Short descriptive name for this rule'),
    Field('ruleType', String,
        'Rule Type (Constraint, Calculation, Derivation, Action-Trigger, '
            'Authorization, Validation)', required: true,
        hint: 'Constraint / Calculation / Derivation / Action-Trigger / '
            'Authorization / Validation'),
    Field('description', String, 'Description (plain language)', required: true,
        hint: 'Plain-language statement of what this rule requires'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Formal definition and applicability.
  @SerializationOrder(1)
  DomainBusinessRuleEntryDefinition definition =
      DomainBusinessRuleEntryDefinition();

  /// Priority, provenance, and interpretation aids.
  @SerializationOrder(2)
  DomainBusinessRuleEntryGovernance governance =
      DomainBusinessRuleEntryGovernance();
}

/// Formal definition and applicability.
@StandardReferences(
  [
    'BABOK v3 §10.9 — business rules analysis',
    'ISO/IEC/IEEE 29148 §6 — business rules',
  ],
  'The formal, unambiguous statement of a business rule and the conditions '
      'under which it applies.',
)
@SectionId('DBRED')
class DomainBusinessRuleEntryDefinition {
  @Form([
    Field('formalStatement', String,
        'Formal Statement (precise, unambiguous statement)',
        hint: 'Precise, unambiguous statement of the rule'),
    Field('appliesTo', String,
        'Applies To (which concepts/processes this rule governs)',
        hint: 'Which concepts or processes this rule governs'),
    Field('conditions', String,
        'Conditions (when this rule applies)',
        hint: 'The conditions under which this rule applies'),
    Field('consequences', String,
        'Consequences (what happens when rule is triggered/violated)',
        hint: 'What happens when the rule is triggered or violated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Priority, provenance, and interpretation aids.
@StandardReferences(
  [
    'BABOK v3 §10.9 — business rules analysis',
    'ISO/IEC/IEEE 29148 §6 — business rules',
  ],
  'The governance metadata for a business rule: precedence, provenance, '
      'exceptions, and illustrative examples.',
)
@SectionId('DBREG')
class DomainBusinessRuleEntryGovernance {
  @Form([
    Field('priority', String,
        'Priority (if rules conflict, which takes precedence)',
        hint: 'Which rule takes precedence when rules conflict'),
    Field('source', String,
        'Source (regulation, policy, business decision)',
        hint: 'Origin of the rule: regulation, policy, business decision'),
    Field('exceptions', String,
        'Exceptions (when rule does not apply)',
        hint: 'Circumstances in which the rule does not apply'),
    Field('examples', String,
        'Examples (concrete examples of rule application)',
        hint: 'Concrete examples of the rule being applied'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.3.6. Domain Processes.
///
/// High-level business processes within this domain, showing the main
/// workflows and activities.
@StandardReferences(
  [
    'BABOK v3 §10.35 — process modelling',
    'ISO/IEC/IEEE 29148 §6 — business process context',
  ],
  'Captures the main high-level business processes within this domain, '
      'their workflows, and how they interact.',
)
@ContentHelp('Describe the main business processes within this domain. '
    'Focus on business activities, not system implementation.')
@SectionId('DP')
class DomainProcesses {
  @SerializationOrder(0)
  String? content;

  /// Process overview diagram.
  @ContentType('mermaid-flowchart', 'High-level process map showing '
      'main processes and their relationships')
  @ContentHelp('Create a process map showing the main business processes '
      'and how they interact.')
  @SerializationOrder(1)
  String? processOverviewDiagram;

  /// Domain process entries — contains 0+× DomainProcessEntry.
  @StandardReferences(
    [
      'BABOK v3 §10.35 — process modelling',
      'ISO/IEC/IEEE 29148 §6 — business process context',
    ],
    'The set of individual domain-process entries.',
  )
  @SectionId('DOPR-PROC-LST')
  @SectionIdPattern('DOPR-PROC-xxx')
  @ContentHelp('Add one entry per major business process in this domain.')
  @SerializationOrder(2)
  List<DomainProcessEntry> processes = [];
}

/// A domain process entry (form).
@StandardReferences(
  [
    'BABOK v3 §10.35 — process modelling',
    'ISO/IEC/IEEE 29148 §6 — business process context',
  ],
  'A single domain business process with its type, trigger, flow, and '
      'operating characteristics.',
)
@SectionId('DOPREN')
class DomainProcessEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true,
        hint: 'Name of the business process'),
    Field('processDescription', String, 'Process Description', required: true,
        hint: 'What this process does and why it exists'),
    Field('processType', String,
        'Process Type (Core, Support, Management)',
        hint: 'Core / Support / Management'),
    Field('trigger', String,
        'Trigger (what initiates this process)',
        hint: 'What event or condition initiates this process'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Inputs, outputs, and participant flow.
  @SerializationOrder(1)
  DomainProcessEntryFlow flow = DomainProcessEntryFlow();

  /// Operating cadence and coordination details.
  @SerializationOrder(2)
  DomainProcessEntryOperations operations = DomainProcessEntryOperations();

  /// Process flow details.
  @SerializationOrder(3)
  TextSection? processFlowDetails;
}

/// Inputs, outputs, and participant flow.
@StandardReferences(
  [
    'BABOK v3 §10.35 — process modelling',
    'ISO/IEC/IEEE 29148 §6 — business process context',
  ],
  'The inputs, outputs, participants, and related processes that make up '
      'a domain process\'s flow.',
)
@SectionId('DPEF')
class DomainProcessEntryFlow {
  @Form([
    Field('inputs', String,
        'Inputs (what data/artifacts are needed)',
        hint: 'Data or artifacts this process needs as input'),
    Field('outputs', String,
        'Outputs (what is produced)',
        hint: 'What this process produces'),
    Field('participants', String,
        'Participants (roles/actors involved)',
        hint: 'Roles or actors involved in this process'),
    Field('relatedProcesses', String,
        'Related Processes (processes that interact with this one)',
        hint: 'Other processes that interact with this one'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operating cadence and coordination details.
@StandardReferences(
  [
    'BABOK v3 §10.35 — process modelling',
    'ISO/IEC/IEEE 29148 §6 — business process context',
  ],
  'The operating cadence of a domain process: frequency, duration, success '
      'criteria, and key decision points.',
)
@SectionId('DPEO')
class DomainProcessEntryOperations {
  @Form([
    Field('frequency', String,
        'Frequency (how often this process runs)',
        hint: 'How often this process runs'),
    Field('duration', String,
        'Duration (typical time to complete)',
        hint: 'Typical time for the process to complete'),
    Field('successCriteria', String,
        'Success Criteria (what defines successful completion)',
        hint: 'What defines successful completion of the process'),
    Field('keyDecisions', String,
        'Key Decisions (decision points within the process)',
        hint: 'Decision points within the process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.3.7. Domain Events.
///
/// Significant business events that occur within this domain and
/// trigger actions or state changes.
@StandardReferences(
  [
    'Domain-Driven Design — domain events',
    'BABOK v3 §10 — event analysis',
  ],
  'Captures the significant business events that occur within this domain '
      'and trigger actions or state changes.',
)
@ContentHelp('Document significant business events within this domain. '
    'Events represent things that happen which are important to the '
    'business and may trigger reactions.')
@SectionId('DE')
class DomainEvents {
  @ContentType('description', 'Overview of key domain events and '
      'their significance.')
  @SerializationOrder(0)
  String? content;

  /// Domain event entries — contains 0+× DomainEventEntry.
  @StandardReferences(
    [
      'Domain-Driven Design — domain events',
      'BABOK v3 §10 — event analysis',
    ],
    'The set of individual domain-event entries.',
  )
  @SectionId('DOEV-EVEN-LST')
  @SectionIdPattern('DOEV-EVEN-xxx')
  @ContentHelp('Add one entry per significant business event.')
  @SerializationOrder(1)
  List<DomainEventEntry> events = [];
}

/// A domain event entry (form).
@StandardReferences(
  [
    'Domain-Driven Design — domain events',
    'BABOK v3 §10 — event analysis',
  ],
  'A single domain event with its trigger, source, payload, subscribers, '
      'reactions, and business impact.',
)
@SectionId('DOEV')
class DomainEventEntry {
  @Form([
    Field('eventName', String, 'Event Name (past tense, e.g., OrderPlaced)',
        required: true,
        hint: 'Past-tense event name, e.g., OrderPlaced'),
    Field('eventDescription', String, 'Event Description', required: true,
        hint: 'What this event represents in the business'),
    Field('eventType', String,
        'Event Type (State Change, Action Completed, Time-based, External)',
        hint: 'State Change / Action Completed / Time-based / External'),
    Field('trigger', String,
        'Trigger (what causes this event)',
        hint: 'What causes this event to occur'),
    Field('sourceEntity', String,
        'Source Entity (which concept generates this event)',
        hint: 'Which domain concept generates this event'),
    Field('eventData', String,
        'Event Data (what information is carried with the event)',
        hint: 'Information carried in the event payload'),
    Field('subscribers', String,
        'Subscribers (who/what reacts to this event)',
        hint: 'Who or what reacts to this event'),
    Field('reactions', String,
        'Reactions (what happens when this event occurs)',
        hint: 'What happens in response to this event'),
    Field('frequency', String,
        'Frequency (how often this event occurs)',
        hint: 'How often this event occurs'),
    Field('businessImpact', String,
        'Business Impact (significance of this event)',
        hint: 'Significance of this event to the business'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.5. User Interaction Model.
///
/// Describes how different user categories interact with the system including
/// access channels, interaction patterns, access levels, and session management.
/// Based on user experience best practices and multi-channel interaction design.
@StandardReferences(
  [
    'ISO 9241-210 — human-centred design for interactive systems',
    'ISO/IEC 25010 — usability quality characteristic',
  ],
  'Captures how each user category interacts with the system across channels, '
  'patterns, access levels, sessions, and notifications.',
)
@ContentHelp('Describe how different user categories interact with the system: '
    'access channels (web, mobile, API, CLI), interaction patterns (real-time, '
    'batch, notification-driven), access levels, session management, and '
    'multi-channel considerations.')
@SectionId('UIM')
class UserInteractionModel {
  @ContentType('description', 'High-level overview of user interaction model '
      'explaining how users access and interact with the system across '
      'different channels and contexts.')
  @SerializationOrder(0)
  String? content;

  /// Interaction model summary.
  @SerializationOrder(1)
  UserInteractionModelSummary summary = UserInteractionModelSummary();

  /// 4.1.5.1. Access Channels.
  @SerializationOrder(2)
  AccessChannels accessChannels = AccessChannels();

  /// 4.1.5.2. Interaction Patterns.
  @SerializationOrder(3)
  InteractionPatterns interactionPatterns = InteractionPatterns();

  /// 4.1.5.3. Access Levels.
  @SerializationOrder(4)
  AccessLevels accessLevels = AccessLevels();

  /// 4.1.5.4. Session Model.
  @SerializationOrder(5)
  SessionModel sessionModel = SessionModel();

  /// 4.1.5.5. Notification Model.
  @SerializationOrder(6)
  NotificationModel notificationModel = NotificationModel();

  /// 4.1.5.6. Multi-Channel Experience.
  @SerializationOrder(7)
  MultiChannelExperience multiChannelExperience = MultiChannelExperience();
}

/// Summary statistics for user interaction model.
@StandardReferences(
  [
    'ISO 9241-210 — human-centred design for interactive systems',
    'ISO/IEC 25010 — usability quality characteristic',
  ],
  'An at-a-glance summary of the user interaction model: primary channel, '
  'channel/pattern/level counts, and multi-channel posture.',
)
@Form([
  Field('primaryAccessChannel', String, 'Primary Access Channel',
      hint: 'Web, Mobile App, Desktop App, API, CLI'),
  Field('channelCount', int, 'Number of Access Channels',
      hint: 'Total count of access channels defined'),
  Field('interactionPatternCount', int, 'Number of Interaction Patterns',
      hint: 'Total count of interaction patterns defined'),
  Field('accessLevelCount', int, 'Number of Access Levels',
      hint: 'Total count of access levels defined'),
  Field('multiChannelSupport', String, 'Multi-Channel Support',
      hint: 'None, Limited, Full'),
  Field('offlineCapability', String, 'Offline Capability',
      hint: 'None, Read-only, Full'),
  Field('sessionManagement', String, 'Session Management Approach',
      hint: 'Server-side, Client-side, Hybrid, Stateless'),
  Field('notificationChannels', String, 'Notification Channels',
      hint: 'e.g., Email, SMS, Push, In-app'),
])
@SectionId('UIMS')
class UserInteractionModelSummary {
  /// Summary content for interaction model.
  @ContentType('aggregation', 'Key metrics and classifications for '
      'user interaction model.')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.1 Access Channels
// ---------------------------------------------------------------------------

/// 4.1.5.1. Access Channels.
///
/// Defines all channels through which users can access the system including
/// web, mobile, desktop applications, APIs, and other interfaces.
@StandardReferences(
  [
    'ISO 9241-210 — interaction design',
    'ISO/IEC 25010 — usability/operability',
  ],
  'The set of channels through which users access the system, each with its '
  'target users, features, and constraints.',
)
@ContentHelp('Define all channels through which users can access the system. '
    'For each channel, specify target users, features available, and '
    'any channel-specific constraints.')
@SectionId('AC1')
class AccessChannels {
  @ContentHelp('Provide an overview of the access channel landscape and how '
      'channels collectively serve the user base.')
  @SerializationOrder(0)
  String? content;

  /// Channel architecture diagram.
  @ContentType('mermaid-flowchart', 'Diagram showing access channels, '
      'their relationships, and user flows')
  @ContentHelp('Create a diagram showing how different channels connect '
      'to the system and serve different user categories.')
  @SerializationOrder(1)
  String? channelDiagram;

  /// Channel entries — contains 1+× InteractionChannelEntry.
  @StandardReferences(
    [
      'ISO 9241-210 — interaction design',
      'ISO/IEC 25010 — usability/operability',
    ],
    'The set of individual access-channel entries defined for the system.',
  )
  @SectionId('ICE-CHAN-LST')
  @SectionIdPattern('ICE-CHAN-xxx')
  @Min(1)
  @ContentHelp('Add one entry per access channel. Include both primary '
      'and secondary channels.')
  @SerializationOrder(2)
  List<InteractionChannelEntry> channels = [];
}

/// An interaction channel entry (form).
///
/// Comprehensive definition of an access channel including platform details,
/// features, constraints, and user experience considerations.
@StandardReferences(
  [
    'ISO 9241-210 — interaction design',
    'ISO/IEC 25010 — usability/operability',
  ],
  'A single access-channel definition: its platform, features, access, '
  'compliance, UX, and integrations.',
)
@SectionId('ICE')
class InteractionChannelEntry {
  @Form([
    Field('channelName', String, 'Channel Name', required: true,
        hint: 'e.g., Customer Web Portal, Mobile App, Admin API'),
    Field('channelId', String, 'Channel ID',
        hint: 'Unique identifier for the channel'),
    Field('channelType', String, 'Channel Type', required: true,
        hint: 'Web, Mobile Native, Mobile Hybrid, Desktop, API, CLI, Voice, '
            'Kiosk, Embedded, IoT'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Platform and targeting.
  @SerializationOrder(1)
  InteractionChannelEntryPlatform platform = InteractionChannelEntryPlatform();

  /// Feature scope.
  @SerializationOrder(2)
  InteractionChannelEntryFeatures features = InteractionChannelEntryFeatures();

  /// Access and sync.
  @SerializationOrder(3)
  InteractionChannelEntryAccess access = InteractionChannelEntryAccess();

  /// Compliance and requirements.
  @SerializationOrder(4)
  InteractionChannelEntryCompliance compliance =
      InteractionChannelEntryCompliance();

  /// Channel-specific UI/UX specifications.
  @SerializationOrder(5)
  ChannelUxSpecification uxSpecification = ChannelUxSpecification();

  /// Channel-specific integration requirements.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — external interfaces'],
    'The set of channel-specific integration entries (push, analytics, '
    'payments, etc.) for this channel.',
  )
  @SectionId('CI-INTE-LST')
  @SectionIdPattern('CI-INTE-xxx')
  @ContentHelp('Add one entry per channel-specific integration requirement.')
  @SerializationOrder(6)
  List<ChannelIntegrations> integrations = [];
}

/// Platform and targeting for interaction channel.
@StandardReferences(
  [
    'ISO 9241-210 — interaction design',
    'ISO/IEC 25010 — usability/operability',
  ],
  'The platform/technology and target-user details for an access channel.',
)
@SectionId('ICEP')
class InteractionChannelEntryPlatform {
  @Form([
    Field('platform', String, 'Platform/Technology',
        hint: 'e.g., Flutter Web, Flutter iOS/Android, REST API'),
    Field('targetUserCategories', String, 'Target User Categories',
        hint: 'List of user category IDs this channel serves'),
    Field('description', String, 'Description',
        hint: 'Purpose and scope of this channel'),
    Field('channelPriority', String, 'Channel Priority',
        hint: 'Primary, Secondary, Tertiary'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature scope for interaction channel.
@StandardReferences(
  [
    'ISO 9241-210 — interaction design',
    'ISO/IEC 25010 — usability/operability',
  ],
  'The feature scope of an access channel: what is included, excluded, and '
  'its breadth.',
)
@SectionId('ICEF')
class InteractionChannelEntryFeatures {
  @Form([
    Field('featureScope', String, 'Feature Scope',
        hint: 'Full, Limited, Read-only, Specialized'),
    Field('featuresIncluded', String, 'Features Included',
        hint: 'List of features available on this channel'),
    Field('featuresExcluded', String, 'Features Excluded',
        hint: 'Features not available on this channel'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access and sync for interaction channel.
@StandardReferences(
  [
    'ISO 9241-210 — interaction design',
    'ISO/IEC 25010 — usability/operability',
  ],
  'The availability, performance, offline, sync, and authentication '
  'characteristics of an access channel.',
)
@SectionId('ICEA')
class InteractionChannelEntryAccess {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance and requirements for interaction channel.
@StandardReferences(
  [
    'EN 301 549 — ICT accessibility',
    'ISO/IEC 27001 Annex A — access control',
  ],
  'The device, browser, accessibility, localization, branding, and analytics '
  'compliance requirements for an access channel.',
)
@SectionId('INCHENCO')
class InteractionChannelEntryCompliance {
  @Form([
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
  @SerializationOrder(0)
  String? content;
}

/// Channel-specific UX specification.
@StandardReferences(
  [
    'ISO 9241-210 — UX design',
    'Nielsen usability heuristics',
  ],
  'The channel-specific user-experience specification: navigation, input, '
  'screen sizes, and interaction affordances.',
)
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
@SectionId('CUS')
class ChannelUxSpecification {
  /// UX specification content.
  @ContentType('form', 'Channel-specific user experience specifications.')
  @SerializationOrder(0)
  String? content;
}

/// Channel-specific integration requirements.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §6 — external interfaces'],
  'A single channel-specific integration definition (push, analytics, '
  'crash reporting, payments, biometrics, etc.).',
)
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
@SectionId('CI')
class ChannelIntegrations {
  /// Integration requirements content.
  @ContentType('form', 'Channel-specific integration requirements.')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.2 Interaction Patterns
// ---------------------------------------------------------------------------

/// 4.1.5.2. Interaction Patterns.
///
/// Defines how users interact with the system including real-time interactions,
/// batch processing, workflow-driven tasks, and notification-driven actions.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO 9241-210 — interaction patterns',
  ],
  'The set of interaction patterns the system uses — real-time, batch, '
  'workflow, notification-driven, and scheduled.',
)
@ContentHelp('Define the interaction patterns used in the system: real-time '
    'interactions, batch processing, workflow-driven tasks, notification-driven '
    'actions, and scheduled operations.')
@SectionId('IP')
class InteractionPatterns {
  @ContentType('description', 'Overview of interaction patterns and when '
      'each pattern is used.')
  @SerializationOrder(0)
  String? content;

  /// Pattern entries — contains 1+× InteractionPatternEntry.
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO 9241-210 — interaction patterns',
    ],
    'The set of individual interaction-pattern entries defined for the system.',
  )
  @SectionId('INPTN-PATT-LST')
  @SectionIdPattern('INPTN-PATT-xxx')
  @Min(1)
  @ContentHelp('Add one entry per interaction pattern used in the system.')
  @SerializationOrder(1)
  List<InteractionPatternEntry> patterns = [];
}

/// An interaction pattern entry (form).
///
/// Definition of a specific interaction pattern including timing, triggers,
/// and user experience considerations.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO 9241-210 — interaction patterns',
  ],
  'A single interaction-pattern definition: its type, triggers, runtime '
  'behavior, and usage.',
)
@SectionId('INPTN')
class InteractionPatternEntry {
  @Form([
    Field('patternName', String, 'Pattern Name', required: true,
        hint: 'e.g., Real-time Form Submission, Batch Report Generation'),
    Field('patternId', String, 'Pattern ID',
        hint: 'Unique identifier'),
    Field('patternType', String, 'Pattern Type', required: true,
        hint: 'Synchronous, Asynchronous, Batch, Scheduled, Event-driven, '
            'Workflow, Polling, Streaming'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Narrative summary and typical scenarios.
  @SerializationOrder(1)
  InteractionPatternEntryDefinition definition =
      InteractionPatternEntryDefinition();

  /// Trigger conditions and cadence.
  @SerializationOrder(2)
  InteractionPatternEntryTrigger trigger = InteractionPatternEntryTrigger();

  /// User experience and runtime behavior.
  @SerializationOrder(3)
  InteractionPatternEntryBehavior behavior =
      InteractionPatternEntryBehavior();

  /// Applicability and operational priority.
  @SerializationOrder(4)
  InteractionPatternEntryUsage usage = InteractionPatternEntryUsage();
}

/// Narrative summary and typical scenarios.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO 9241-210 — interaction patterns',
  ],
  'The narrative description, use cases, and applicable user categories for '
  'an interaction pattern.',
)
@SectionId('IPED')
class InteractionPatternEntryDefinition {
  @Form([
    Field('description', String, 'Description',
        hint: 'What this pattern involves'),
    Field('useCases', String, 'Use Cases',
        hint: 'List of use cases that follow this pattern'),
    Field('userCategories', String, 'Applicable User Categories',
        hint: 'Which user categories use this pattern'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Trigger conditions and cadence.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO 9241-210 — interaction patterns',
  ],
  'The trigger type, conditions, and expected frequency for an interaction '
  'pattern.',
)
@SectionId('IPET')
class InteractionPatternEntryTrigger {
  @Form([
    Field('triggerType', String, 'Trigger Type',
        hint: 'User Action, System Event, Schedule, External Signal'),
    Field('triggerDetails', String, 'Trigger Details',
        hint: 'Specific conditions that trigger this pattern'),
    Field('frequency', String, 'Expected Frequency',
        hint: 'How often this pattern occurs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// User experience and runtime behavior.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO 9241-210 — interaction patterns',
  ],
  'The runtime behavior of an interaction pattern: response time, feedback, '
  'error handling, and concurrency.',
)
@SectionId('IPEB')
class InteractionPatternEntryBehavior {
  @Form([
    Field('responseTime', String, 'Expected Response Time',
        hint: 'Immediate, Seconds, Minutes, Hours, Days'),
    Field('feedbackMechanism', String, 'Feedback Mechanism',
        hint: 'Progress indicator, Status page, Email notification'),
    Field('errorHandling', String, 'Error Handling',
        hint: 'Retry, Rollback, Manual intervention, Notification'),
    Field('concurrencyHandling', String, 'Concurrency Handling',
        hint: 'How concurrent requests are handled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Applicability and operational priority.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO 9241-210 — interaction patterns',
  ],
  'The applicability and operational priority of an interaction pattern.',
)
@SectionId('IPEU')
class InteractionPatternEntryUsage {
  @Form([
    Field('priority', String, 'Priority',
        hint: 'High, Medium, Low - for resource allocation'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.3 Access Levels
// ---------------------------------------------------------------------------

/// 4.1.5.3. Access Levels.
///
/// Defines the access level hierarchy and how permissions are structured
/// across user categories and system functions.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — role-based access',
  ],
  'The access-level hierarchy and authorization framework relating user '
  'categories to permissions.',
)
@ContentHelp('Define access levels and how they relate to user categories, '
    'features, and data. This establishes the authorization framework.')
@SectionId('AL')
class AccessLevels {
  @ContentHelp('Provide an overview of the access-level model and how levels '
      'structure authorization across the system.')
  @SerializationOrder(0)
  String? content;

  /// Access level hierarchy diagram.
  @ContentType('mermaid-flowchart', 'Access level hierarchy showing '
      'inheritance and relationships')
  @ContentHelp('Create a diagram showing the access level hierarchy.')
  @SerializationOrder(1)
  String? accessLevelDiagram;

  /// Access level entries — contains 1+× AccessLevelEntry.
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A.9 — access control',
      'NIST RBAC — role-based access',
    ],
    'The set of individual access-level entries defined for the system.',
  )
  @SectionId('ACLV-LEVE-LST')
  @SectionIdPattern('ACLV-LEVE-xxx')
  @Min(1)
  @ContentHelp('Define each access level in the system.')
  @SerializationOrder(2)
  List<AccessLevelEntry> levels = [];

  /// Permission matrix linking access levels to features.
  @ContentType('description', 'Matrix showing which access levels have '
      'which permissions. Can be a table or detailed description.')
  @ContentHelp('Create a permission matrix showing the relationship between '
      'access levels, features, and permissions.')
  @SerializationOrder(3)
  String? permissionMatrix;
}

/// An access level entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — role-based access',
  ],
  'A single access-level definition: its scope, granted permissions, and '
  'governance.',
)
@SectionId('ACLV')
class AccessLevelEntry {
  @Form([
    Field('levelName', String, 'Access Level Name', required: true,
        hint: 'e.g., Administrator, Power User, Standard User, Guest'),
    Field('levelId', String, 'Level ID',
        hint: 'Unique identifier'),
    Field('levelRank', int, 'Level Rank',
        hint: 'Numeric rank (higher = more permissions)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope and hierarchy of this access level.
  @SerializationOrder(1)
  AccessLevelEntryScope scope = AccessLevelEntryScope();

  /// Permission surfaces granted by this level.
  @SerializationOrder(2)
  AccessLevelEntryPermissions permissions = AccessLevelEntryPermissions();

  /// Restrictions and governance for this level.
  @SerializationOrder(3)
  AccessLevelEntryGovernance governance = AccessLevelEntryGovernance();
}

/// Scope and hierarchy of an access level.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — role-based access',
  ],
  'The scope, inheritance, and applicable user categories of an access level.',
)
@SectionId('ALES')
class AccessLevelEntryScope {
  @Form([
    Field('description', String, 'Description',
        hint: 'What this access level provides'),
    Field('inheritsFrom', String, 'Inherits From',
        hint: 'Parent access level (if hierarchical)'),
    Field('userCategories', String, 'Applicable User Categories',
        hint: 'Which user categories can have this level'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Permission surfaces granted by an access level.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — role-based access',
  ],
  'The permission surfaces (features, data, admin, API) granted by an access '
  'level.',
)
@SectionId('ALEP')
class AccessLevelEntryPermissions {
  @Form([
    Field('featureAccess', String, 'Feature Access',
        hint: 'List of features accessible at this level'),
    Field('dataAccess', String, 'Data Access Scope',
        hint: 'Own data, Team data, Department data, All data'),
    Field('adminCapabilities', String, 'Administrative Capabilities',
        hint: 'Admin functions available at this level'),
    Field('apiAccess', String, 'API Access',
        hint: 'API endpoints accessible'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Restrictions and governance for an access level.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — role-based access',
  ],
  'The restrictions, audit requirements, and elevation process governing an '
  'access level.',
)
@SectionId('ALEG')
class AccessLevelEntryGovernance {
  @Form([
    Field('restrictions', String, 'Restrictions',
        hint: 'Explicit restrictions or limitations'),
    Field('auditRequirements', String, 'Audit Requirements',
        hint: 'Audit logging requirements for this level'),
    Field('elevationProcess', String, 'Elevation Process',
        hint: 'How users can request higher access'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.4 Session Model
// ---------------------------------------------------------------------------

/// 4.1.5.4. Session Model.
///
/// Defines session management including authentication, timeouts, and
/// multi-device session handling.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — session management',
    'OWASP ASVS — session management',
  ],
  'The session management model: lifecycle, timeouts, multi-device handling, '
  'and session security.',
)
@ContentHelp('Define session management: session lifecycle, timeouts, '
    'multi-device handling, and session security.')
@SectionId('SM')
class SessionModel {
  @ContentHelp('Provide an overview of the session management approach for '
      'the system.')
  @SerializationOrder(0)
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
  ])
  @SerializationOrder(1)
  String? sessionConfiguration;

  /// Refresh, concurrency, and termination behavior.
  @SerializationOrder(2)
  SessionModelLifecycle lifecycle = SessionModelLifecycle();

  /// Convenience features and security-trigger handling.
  @SerializationOrder(3)
  SessionModelSecurity security = SessionModelSecurity();
}

/// Refresh, concurrency, and termination behavior.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — session management',
    'OWASP ASVS — session management',
  ],
  'The session lifecycle: token refresh, multi-device policy, concurrency '
  'limits, and termination behavior.',
)
@SectionId('SEMOLI')
class SessionModelLifecycle {
  @Form([
    Field('refreshMechanism', String, 'Token Refresh Mechanism',
        hint: 'Sliding window, Explicit refresh, Re-authentication'),
    Field('multiDevicePolicy', String, 'Multi-Device Policy',
        hint: 'Single device, Multiple devices, Device limit'),
    Field('concurrentSessionLimit', int, 'Concurrent Session Limit',
        hint: 'Maximum simultaneous sessions'),
    Field('sessionTermination', String, 'Session Termination',
        hint: 'Manual logout, Timeout, Force logout'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Convenience features and security-trigger handling.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — session management',
    'OWASP ASVS — session management',
  ],
  'The session security and convenience features: remember-me, device trust, '
  'recovery, and security-event handling.',
)
@SectionId('SEMOSE')
class SessionModelSecurity {
  @Form([
    Field('rememberMeOption', String, 'Remember Me Option',
        hint: 'Available, Not available, Configurable'),
    Field('deviceTrust', String, 'Device Trust',
        hint: 'Trusted devices concept support'),
    Field('sessionRecovery', String, 'Session Recovery',
        hint: 'How interrupted sessions are handled'),
    Field('securityEvents', String, 'Security Events',
        hint: 'Events that trigger session review/termination'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.5 Notification Model
// ---------------------------------------------------------------------------

/// 4.1.5.5. Notification Model.
///
/// Defines how the system notifies users of events, updates, and actions
/// across different channels.
@StandardReferences(
  [
    'ISO 9241-210 — user feedback & notifications',
    'ISO/IEC 25010 — user-interface aesthetics/operability',
  ],
  'The notification strategy: channels, types, triggers, preferences, and '
  'delivery mechanisms.',
)
@ContentHelp('Define notification strategy: channels, triggers, preferences, '
    'and delivery mechanisms.')
@SectionId('NM')
class NotificationModel {
  @ContentType('description', 'Overview of notification strategy.')
  @SerializationOrder(0)
  String? content;

  /// Notification channel entries — contains 1+× NotificationChannelEntry.
  @StandardReferences(
    [
      'ISO 9241-210 — user feedback & notifications',
      'ISO/IEC 25010 — user-interface aesthetics/operability',
    ],
    'The set of individual notification-channel entries defined for the system.',
  )
  @SectionId('NTFCH-CHAN-LST')
  @SectionIdPattern('NTFCH-CHAN-xxx')
  @Min(1)
  @ContentHelp('Define each notification channel.')
  @SerializationOrder(1)
  List<NotificationChannelEntry> channels = [];

  /// Notification type entries — contains 1+× NotificationTypeEntry.
  @StandardReferences(
    [
      'ISO 9241-210 — user feedback & notifications',
      'ISO/IEC 25010 — user-interface aesthetics/operability',
    ],
    'The set of individual notification-type entries defined for the system.',
  )
  @SectionId('NTFTY-NOTI-LST')
  @SectionIdPattern('NTFTY-NOTI-xxx')
  @ContentHelp('Define each notification type.')
  @SerializationOrder(2)
  List<NotificationTypeEntry> notificationTypes = [];

  /// User notification preferences.
  @StandardReferences(
    [
      'ISO 9241-210 — user feedback & notifications',
      'ISO/IEC 25010 — user-interface aesthetics/operability',
    ],
    'The set of user notification-preference entries defined for the system.',
  )
  @SectionId('UNP-PREF-LST')
  @SectionIdPattern('UNP-PREF-xxx')
  @ContentHelp('Add one entry per user notification-preference profile.')
  @SerializationOrder(3)
  List<UserNotificationPreferences> preferences = [];
}

/// A notification channel entry.
@StandardReferences(
  [
    'ISO 9241-210 — user feedback & notifications',
    'ISO/IEC 25010 — user-interface aesthetics/operability',
  ],
  'A single notification-channel definition: its delivery, retry, fallback, '
  'and urgency characteristics.',
)
@SectionId('NTFCH')
class NotificationChannelEntry {
  @Form([
    Field('channelName', String, 'Channel Name', required: true,
        hint: 'Email, SMS, Push Notification, In-App, Slack, Teams'),
    Field('channelId', String, 'Channel ID',
        hint: 'Unique identifier for the notification channel'),
    Field('description', String, 'Description',
        hint: 'Purpose and scope of this notification channel'),
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
  @SerializationOrder(0)
  String? content;
}

/// A notification type entry.
@StandardReferences(
  [
    'ISO 9241-210 — user feedback & notifications',
    'ISO/IEC 25010 — user-interface aesthetics/operability',
  ],
  'A single notification-type definition: its category, urgency, channels, '
  'trigger, and content template.',
)
@SectionId('NTFTY')
class NotificationTypeEntry {
  @Form([
    Field('notificationType', String, 'Notification Type', required: true,
        hint: 'e.g., Order Confirmation, Password Reset, System Alert'),
    Field('typeId', String, 'Type ID',
        hint: 'Unique identifier for the notification type'),
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
  @SerializationOrder(0)
  String? content;
}

/// User notification preferences.
@StandardReferences(
  [
    'ISO 9241-210 — user feedback & notifications',
    'ISO/IEC 25010 — user-interface aesthetics/operability',
  ],
  'The user-configurable notification preference options: opt-out, per-type '
  'control, channel choice, frequency, and quiet hours.',
)
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
@SectionId('UNP')
class UserNotificationPreferences {
  /// Preferences content.
  @ContentType('form', 'User notification preference options.')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.1.5.6 Multi-Channel Experience
// ---------------------------------------------------------------------------

/// 4.1.5.6. Multi-Channel Experience.
///
/// Defines how the system provides a consistent experience across channels
/// and handles channel switching.
@StandardReferences(
  [
    'ISO 9241-210 — human-centred design for interactive systems',
    'ISO/IEC 25010 — usability quality characteristic',
  ],
  'The multi-channel experience model: context handoff, data synchronization, '
  'and experience consistency across channels.',
)
@ContentHelp('Define multi-channel experience: context handoff between '
    'channels, data synchronization, and experience consistency.')
@SectionId('MCE')
class MultiChannelExperience {
  @ContentHelp('Provide an overview of how a consistent experience is '
      'maintained across channels and during channel switching.')
  @SerializationOrder(0)
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
  @SerializationOrder(1)
  String? multiChannelConfiguration;
}

// ---------------------------------------------------------------------------
// 4.1.4 User Categories
// ---------------------------------------------------------------------------

/// 4.1.4. User Categories.
///
/// Container for user category definitions. Each user category describes a
/// distinct group of users with shared characteristics, access needs, and
/// system interaction patterns. Based on user persona methodology for
/// user-centered design.
@StandardReferences(
  [
    'ISO 9241-210 — user characteristics & context of use',
    'BABOK v3 §10.43 — stakeholder/user analysis',
  ],
  'The root of §4.1.4: captures every distinct user category (persona) that '
  'interacts with the system, with its shared characteristics, access needs, '
  'and interaction patterns.',
)
@ContentHelp('Define all user categories (personas) that will interact with '
    'the system. Each category represents a distinct group with shared '
    'characteristics, needs, and interaction patterns. Use this to drive '
    'user-centered design decisions.')
@SectionId('UC1')
class UserCategories {
  @ContentType('description', 'Overview of user categories and how they '
      'relate to the system. Include summary of user population and '
      'key differences between categories.')
  @SerializationOrder(0)
  String? content;

  /// User category overview diagram.
  @ContentType('mermaid-flowchart', 'User category hierarchy or relationship '
      'diagram showing how different user types relate')
  @ContentHelp('Create a diagram showing user categories, their '
      'relationships, and organizational hierarchy.')
  @SerializationOrder(1)
  String? userCategoryDiagram;

  /// User category entries — contains 1+× UserCategoryEntry.
  @StandardReferences(
    [
      'ISO 9241-210 — user characteristics & context of use',
      'BABOK v3 §10.43 — stakeholder/user analysis',
    ],
    'The set of individual user-category entries defined for this system.',
  )
  @SectionId('USCA-CATE-LST')
  @SectionIdPattern('USCA-CATE-xxx')
  @Min(1)
  @ContentHelp('Add one entry per distinct user category. Categories should '
      'be mutually exclusive where possible, with clear distinguishing '
      'characteristics.')
  @SerializationOrder(2)
  List<UserCategoryEntry> categories = [];
}

/// A user category entry.
///
/// Comprehensive user persona definition including demographics, goals,
/// frustrations, technical proficiency, and system interaction patterns.
@StandardReferences(
  [
    'ISO 9241-210 — personas & context of use',
    'BABOK v3 §10.43 — personas',
  ],
  'A single user-category persona, bundling its usage profile, importance, '
  'persona details, role, tasks, permissions, training, accessibility, and '
  'journey.',
)
@SectionId('UCE')
class UserCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name',
        required: true, hint: 'Descriptive name of this user category'),
    Field('categoryId', String, 'Category ID (unique identifier)',
        hint: 'Unique stable identifier for cross-referencing this category'),
    Field('description', String, 'Description (brief summary of this user type)',
        required: true, hint: 'One- or two-sentence summary of this user type'),
    Field('userType', String,
        'User Type (Internal, External, Partner, Customer, Administrator, etc.)',
        required: true,
        hint: 'Internal / External / Partner / Customer / Administrator'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Interaction profile and scale indicators.
  @SerializationOrder(1)
  UserCategoryEntryUsage usage = UserCategoryEntryUsage();

  /// Growth and prioritization profile.
  @SerializationOrder(2)
  UserCategoryEntryImportance importance = UserCategoryEntryImportance();

  /// 4.1.4.n.1. User Persona Details.
  @SerializationOrder(3)
  UserPersonaDetails personaDetails = UserPersonaDetails();

  /// 4.1.4.n.2. Role.
  @SerializationOrder(4)
  UserCategoryRoleEntry? role;

  /// 4.1.4.n.3. System Tasks — contains 1+× System Task.
  @StandardReferences(
    [
      'ISO 9241-11 — tasks & goals (usability)',
      'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
    ],
    'The set of system tasks this user category performs.',
  )
  @SectionId('SYTS-SYST-LST')
  @SectionIdPattern('SYTS-SYST-xxx')
  @Min(1)
  @ContentHelp('Add one entry per distinct task this user category performs '
      'with the system.')
  @SerializationOrder(5)
  List<SystemTaskEntry> systemTasks = [];

  /// 4.1.4.n.4. Access and Permissions.
  @SerializationOrder(6)
  UserAccessPermissions accessPermissions = UserAccessPermissions();

  /// 4.1.4.n.5. Training Requirements.
  @SerializationOrder(7)
  UserTrainingRequirements trainingRequirements = UserTrainingRequirements();

  /// 4.1.4.n.6. Accessibility Needs.
  @SerializationOrder(8)
  UserAccessibilityNeeds accessibilityNeeds = UserAccessibilityNeeds();

  /// 4.1.4.n.7. User Journey.
  @SerializationOrder(9)
  UserJourney userJourney = UserJourney();
}

/// Interaction profile and scale indicators.
@StandardReferences(
  [
    'ISO 9241-210 — user characteristics & context of use',
    'BABOK v3 §10.43 — stakeholder/user analysis',
  ],
  'Captures how this user category uses the system — proficiency, frequency, '
  'access channel, and population size.',
)
@SectionId('UCEU')
class UserCategoryEntryUsage {
    @Form([
        Field('technicalProficiency', String,
                'Technical Proficiency (Novice, Intermediate, Advanced, Expert)',
                hint: 'Novice / Intermediate / Advanced / Expert'),
        Field('frequencyOfUse', String,
                'Frequency of Use (Continuous, Daily, Weekly, Monthly, Occasional)',
                hint: 'Continuous / Daily / Weekly / Monthly / Occasional'),
        Field('accessChannel', String,
                'Primary Access Channel (Web, Mobile, Desktop, API, etc.)',
                hint: 'Web / Mobile / Desktop / API'),
        Field('estimatedUserCount', String,
                'Estimated User Count (current number or range)',
                hint: 'Current number or expected range of users'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Growth and prioritization profile.
@StandardReferences(
  [
    'ISO 9241-210 — user characteristics & context of use',
    'BABOK v3 §10.43 — stakeholder/user analysis',
  ],
  'Captures the strategic weight of this user category — expected growth, '
  'criticality, and design priority.',
)
@SectionId('UCEI')
class UserCategoryEntryImportance {
    @Form([
        Field('growthExpectation', String,
                'Growth Expectation (expected change in user count)',
                hint: 'Expected change in user count over time'),
        Field('criticality', String,
                'Criticality (how critical is this user group to the system)',
                hint: 'How critical this user group is to the system'),
        Field('priority', String,
                'Priority (High, Medium, Low - for design decisions)',
                hint: 'High / Medium / Low — for design decisions'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 4.1.4.n.1. User Persona Details.
///
/// Detailed persona information including demographics, goals, frustrations,
/// and behavioral characteristics for user-centered design.
@StandardReferences(
  [
    'ISO 9241-210 — personas & context of use',
    'BABOK v3 §10.43 — personas',
  ],
  'Captures the detailed persona for this user category — demographics, '
  'context, goals, and behavior — so designers can empathize with the user.',
)
@ContentHelp('Describe the persona in detail to help designers and developers '
    'understand and empathize with this user type.')
@SectionId('UPD')
class UserPersonaDetails {
  @SerializationOrder(0)
  String? content;

  /// Persona Details Form.
  @Form([
    Field('representativeName', String,
        'Representative Name (fictional name for this persona)',
        hint: 'A memorable fictional name to humanize the persona'),
    Field('ageRange', String, 'Age Range',
        hint: 'Typical age range for this persona'),
    Field('educationLevel', String, 'Education Level',
        hint: 'Highest education level typical for this persona'),
    Field('jobTitle', String, 'Job Title / Position',
        hint: 'Typical job title or position'),
  ])
  @SerializationOrder(1)
  String? personaForm;

  /// Experience and work context.
  @SerializationOrder(2)
  UserPersonaDetailsContext contextDetails = UserPersonaDetailsContext();

  /// Goals and drivers.
  @SerializationOrder(3)
  UserPersonaDetailsGoals goals = UserPersonaDetailsGoals();

  /// Preferences and behavior.
  @SerializationOrder(4)
  UserPersonaDetailsBehavior behavior = UserPersonaDetailsBehavior();

  /// Representative photo or avatar description.
  @ContentType('description', 'Description of a representative photo or '
      'avatar that embodies this persona (for design reference).')
  @SerializationOrder(5)
  String? visualRepresentation;

  /// Key quotes that represent this persona's mindset.
  @StandardReferences(
    [
      'ISO 9241-210 — personas & context of use',
      'BABOK v3 §10.43 — personas',
    ],
    'The set of representative quotes capturing this persona\'s mindset.',
  )
  @SectionId('REPRE-REPR-LST')
  @SectionIdPattern('REPRE-REPR-xxx')
  @ContentHelp('Add quotes that capture how this persona thinks and speaks, '
      'to make the persona vivid for designers.')
  @SerializationOrder(6)
  List<RepresentativeQuoteEntry> representativeQuotes = [];
}

/// Experience and work context.
@StandardReferences(
  [
    'ISO 9241-210 — personas & context of use',
    'BABOK v3 §10.43 — personas',
  ],
  'Captures the persona\'s working context — experience, environment, and '
  'typical workday.',
)
@SectionId('UPDC')
class UserPersonaDetailsContext {
    @Form([
        Field('yearsOfExperience', String, 'Years of Experience (in this role)',
                hint: 'Years of experience in this role'),
        Field('workEnvironment', String,
                'Work Environment (office, remote, field, etc.)',
                hint: 'Office / remote / field / hybrid'),
        Field('typicalWorkday', String,
                'Typical Workday (relevant aspects of daily routine)',
                hint: 'Relevant aspects of the persona\'s daily routine'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Goals and drivers.
@StandardReferences(
  [
    'ISO 9241-210 — personas & context of use',
    'BABOK v3 §10.43 — personas',
  ],
  'Captures what drives this persona — goals, frustrations, motivations, and '
  'fears.',
)
@SectionId('UPDG')
class UserPersonaDetailsGoals {
    @Form([
        Field('primaryGoals', String,
                'Primary Goals (what they want to achieve with the system)',
                hint: 'What this persona most wants to achieve with the system'),
        Field('secondaryGoals', String, 'Secondary Goals',
                hint: 'Less critical goals this persona also has'),
        Field('frustrations', String,
                'Frustrations (pain points with current solutions)',
                hint: 'Pain points with current solutions or workflows'),
        Field('motivations', String, 'Motivations (what drives them)',
                hint: 'What drives and motivates this persona'),
        Field('fears', String, 'Fears (concerns about new systems)',
                hint: 'Concerns or anxieties about adopting a new system'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Preferences and behavior.
@StandardReferences(
  [
    'ISO 9241-210 — personas & context of use',
    'BABOK v3 §10.43 — personas',
  ],
  'Captures this persona\'s behavioral traits — technology comfort, learning '
  'style, and decision-making style.',
)
@SectionId('UPDB')
class UserPersonaDetailsBehavior {
    @Form([
        Field('techComfort', String,
                'Technology Comfort Level (attitude toward technology)',
                hint: 'This persona\'s general attitude toward technology'),
        Field('preferredLearningStyle', String,
                'Preferred Learning Style (visual, hands-on, documentation, etc.)',
                hint: 'Visual / hands-on / documentation / video'),
        Field('decisionMakingStyle', String,
                'Decision Making Style (analytical, intuitive, collaborative)',
                hint: 'Analytical / intuitive / collaborative'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Role within a user category.
///
/// Organizational role and responsibilities associated with this user category.
@StandardReferences(
  [
    'NIST RBAC — role-based access',
    'BABOK v3 §10.43 — roles',
  ],
  'Captures the organizational role for this user category — its '
  'responsibilities, reporting lines, and decision/budget authority.',
)
@SectionId('UCRE')
class UserCategoryRoleEntry {
  @Form([
    Field('roleName', String, 'Role Name',
        required: true, hint: 'Name of the organizational role'),
    Field('roleDescription', String, 'Role Description',
        required: true, hint: 'Brief description of the role and its purpose'),
    Field('organizationUnit', String, 'Organization Unit',
        hint: 'Department or unit this role belongs to'),
    Field('reportsTo', String, 'Reports To (role or position)',
        hint: 'Role or position this role reports to'),
    Field('directReports', String, 'Direct Reports (roles reporting to this)',
        hint: 'Roles or positions that report to this role'),
    Field('responsibilities', String,
        'Key Responsibilities (main job functions)',
        hint: 'Main job functions and duties of this role'),
    Field('decisionAuthority', String,
        'Decision Authority (what decisions can they make)',
        hint: 'What decisions this role is authorized to make'),
    Field('budgetAuthority', String,
        'Budget Authority (financial approval limits)',
        hint: 'Financial approval limits for this role'),
    Field('collaborators', String,
        'Primary Collaborators (roles they work with)',
        hint: 'Roles this role regularly works with'),
    Field('performanceMetrics', String,
        'Performance Metrics (how their success is measured)',
        hint: 'How success is measured for this role'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A system task entry.
///
/// Describes one activity this user category performs with the system.
/// Tasks map to interaction scenarios in the ISC document.
@StandardReferences(
  [
    'ISO 9241-11 — tasks & goals (usability)',
    'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
  ],
  'A single activity this user category performs with the system, with its '
  'execution profile, data interaction, context, workflow, and variations.',
)
@SectionId('SYTS')
class SystemTaskEntry {
  @Form([
    Field('taskId', String, 'Task ID',
        required: true, hint: 'Unique identifier for this task'),
    Field('taskName', String, 'Task Name',
        required: true, hint: 'Short descriptive name of the task'),
    Field('description', String, 'Description (what the user does)',
        hint: 'What the user does when performing this task'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Timing, complexity, and trigger details.
    @SerializationOrder(1)
    SystemTaskEntryExecution execution = SystemTaskEntryExecution();

    /// Outcome and data interaction details.
    @SerializationOrder(2)
    SystemTaskEntryData data = SystemTaskEntryData();

    /// Tooling and linked artifacts.
    @SerializationOrder(3)
    SystemTaskEntryContext context = SystemTaskEntryContext();

  @Reference('Related Use Case')
  @SerializationOrder(4)
  String? relatedUseCase;

  /// Task workflow steps.
  @StandardReferences(
    [
      'ISO 9241-11 — tasks & goals (usability)',
      'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
    ],
    'The ordered set of workflow steps that make up this task.',
  )
  @SectionId('SYSTE-WORK-LST')
  @SectionIdPattern('SYSTE-WORK-xxx')
  @ContentHelp('Add one entry per step in the task workflow, in the order the '
      'user performs them.')
  @SerializationOrder(5)
  List<SystemTaskWorkflowStepEntry> workflowSteps = [];

  /// Variations and exceptions.
  @StandardReferences(
    [
      'ISO 9241-11 — tasks & goals (usability)',
      'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
    ],
    'The set of alternative flows and exceptions for this task.',
  )
  @SectionId('VARIA-VARI-LST')
  @SectionIdPattern('VARIA-VARI-xxx')
  @ContentHelp('Add one entry per variation or exception to the normal task '
      'flow.')
  @SerializationOrder(6)
  List<VariationsAndExceptionEntry> variationsAndExceptions = [];
}

/// Timing, complexity, and trigger details for a system task.
@StandardReferences(
  [
    'ISO 9241-11 — tasks & goals (usability)',
    'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
  ],
  'Captures the execution profile of a task — frequency, duration, complexity, '
  'importance, and trigger.',
)
@SectionId('STEE')
class SystemTaskEntryExecution {
    @Form([
        Field('frequency', String,
                'Frequency (how often: Continuous, Daily, Weekly, Monthly, Ad-hoc)',
                hint: 'Continuous / Daily / Weekly / Monthly / Ad-hoc'),
        Field('averageDuration', String,
                'Average Duration (typical time to complete)',
                hint: 'Typical time to complete this task'),
        Field('complexity', String, 'Complexity (Simple, Moderate, Complex)',
                hint: 'Simple / Moderate / Complex'),
        Field('importance', String,
                'Importance (Critical, High, Medium, Low)',
                hint: 'Critical / High / Medium / Low'),
        Field('trigger', String, 'Trigger (what initiates this task)',
                hint: 'Event or condition that initiates this task'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Outcome and data interaction details for a system task.
@StandardReferences(
  [
    'ISO 9241-11 — tasks & goals (usability)',
    'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
  ],
  'Captures the data interaction of a task — expected outcome, success '
  'criteria, and data accessed or modified.',
)
@SectionId('STED')
class SystemTaskEntryData {
    @Form([
        Field('expectedOutcome', String, 'Expected Outcome',
                hint: 'The result the user expects from completing the task'),
        Field('successCriteria', String, 'Success Criteria',
                hint: 'How to tell the task completed successfully'),
        Field('dataAccessed', String, 'Data Accessed (what information is needed)',
                hint: 'What information the task needs to read'),
        Field('dataModified', String, 'Data Modified (what information changes)',
                hint: 'What information the task creates or changes'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Tooling and linked artifacts for a system task.
@StandardReferences(
  [
    'ISO 9241-11 — tasks & goals (usability)',
    'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
  ],
  'Captures the tooling context of a task — the systems and tools involved in '
  'performing it.',
)
@SectionId('STEC')
class SystemTaskEntryContext {
    @Form([
        Field('toolsUsed', String, 'Tools Used (systems or tools involved)',
                hint: 'Systems or tools involved in performing this task'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 4.1.4.n.4. Access and Permissions.
///
/// Security and access control specifications for this user category.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — permissions',
  ],
  'Captures the access rights, authentication, restrictions, governance, and '
  'permission matrix for this user category.',
)
@ContentHelp('Define the access rights, permissions, and security '
    'constraints for this user category.')
@SectionId('UAP')
class UserAccessPermissions {
  @SerializationOrder(0)
  String? content;

  /// Access Permissions Form.
  @Form([
    Field('accessLevel', String,
        'Access Level (Guest, User, Power User, Administrator, Super Admin)',
        required: true,
        hint: 'Guest / User / Power User / Administrator / Super Admin'),
    Field('authenticationMethod', String,
        'Authentication Method (Password, SSO, MFA, Certificate, etc.)',
        required: true, hint: 'Password / SSO / MFA / Certificate'),
    Field('authorizationRoles', String,
        'Authorization Roles (system roles assigned to this category)',
        hint: 'System roles assigned to this user category'),
    Field('dataAccessScope', String,
        'Data Access Scope (all, department, team, own records)',
        hint: 'all / department / team / own records'),
  ])
  @SerializationOrder(1)
  String? permissionsForm;

  /// Functional and environmental restrictions.
  @SerializationOrder(2)
  UserAccessPermissionsRestrictions restrictionsProfile =
      UserAccessPermissionsRestrictions();

  /// Session and audit controls.
  @SerializationOrder(3)
  UserAccessPermissionsGovernance governance =
      UserAccessPermissionsGovernance();

  /// Permission matrix entries — contains 0+× PermissionMatrixEntry.
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A.9 — access control',
      'NIST RBAC — permissions',
    ],
    'The set of fine-grained permission entries for this user category.',
  )
  @SectionId('PRMTX-PERM-LST')
  @SectionIdPattern('PRMTX-PERM-xxx')
  @ContentHelp('Define specific permission entries for fine-grained access.')
  @SerializationOrder(4)
  List<PermissionMatrixEntry> permissionMatrix = [];
}

/// Functional and environmental restrictions.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — permissions',
  ],
  'Captures the functional and environmental restrictions on this user '
  'category — what they cannot do, and time/location/device constraints.',
)
@SectionId('UAPR')
class UserAccessPermissionsRestrictions {
    @Form([
        Field('functionalAccess', String,
                'Functional Access (what features they can use)',
                hint: 'Features and functions this category can use'),
        Field('restrictions', String,
                'Restrictions (what they cannot access or do)',
                hint: 'What this category cannot access or do'),
        Field('timeRestrictions', String,
                'Time Restrictions (business hours, specific times)',
                hint: 'Business hours or specific times access is allowed'),
        Field('locationRestrictions', String,
                'Location Restrictions (office only, VPN required, etc.)',
                hint: 'Office only / VPN required / geographic limits'),
        Field('deviceRestrictions', String,
                'Device Restrictions (managed devices only, etc.)',
                hint: 'Managed devices only / device type limits'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Session and audit controls.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — permissions',
  ],
  'Captures the session and audit governance for this user category — '
  'timeout behaviour and audit-logging requirements.',
)
@SectionId('UAPG')
class UserAccessPermissionsGovernance {
    @Form([
        Field('sessionTimeout', String,
                'Session Timeout (inactivity timeout duration)',
                hint: 'Inactivity timeout duration before re-authentication'),
        Field('auditRequirements', String,
                'Audit Requirements (what actions are logged)',
                hint: 'Which actions must be logged for audit'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A permission matrix entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — permissions',
  ],
  'A single fine-grained permission rule — a resource, an action, and whether '
  'it is allowed, denied, or conditional, with scope.',
)
@SectionId('PRMTX')
class PermissionMatrixEntry {
  @Form([
    Field('resource', String, 'Resource (what is being accessed)',
        required: true, hint: 'The resource or entity being accessed'),
    Field('action', String, 'Action (Create, Read, Update, Delete, Execute)',
        required: true, hint: 'Create / Read / Update / Delete / Execute'),
    Field('permission', String, 'Permission (Allowed, Denied, Conditional)',
        hint: 'Allowed / Denied / Conditional'),
    Field('condition', String, 'Condition (if conditional, what is required)',
        hint: 'If conditional, the condition that must hold'),
    Field('scope', String, 'Scope (all, own, department, etc.)',
        hint: 'all / own / department / team'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.4.n.5. Training Requirements.
///
/// Training and onboarding requirements for this user category.
@StandardReferences(
  [
    'ISO/IEC/IEEE 12207 — training/support processes',
    'ISO 9241-210 — user support',
  ],
  'Captures the training and onboarding needs for this user category — '
  'formats, certification, support level, and topics.',
)
@SectionId('USTRRE')
@ContentHelp('Define the training and support needs for this user category.')
class UserTrainingRequirements {
  @SerializationOrder(0)
  String? content;

  /// Training Requirements Form.
  @Form([
    Field('initialTrainingRequired', bool,
        'Initial Training Required (is formal training needed)',
        hint: 'Whether formal up-front training is needed'),
    Field('trainingFormat', String,
        'Training Format (In-person, Online, Self-paced, On-the-job)',
        hint: 'In-person / Online / Self-paced / On-the-job'),
    Field('estimatedTrainingDuration', String,
        'Estimated Training Duration',
        hint: 'Estimated time required to complete training'),
    Field('certificationRequired', bool,
        'Certification Required (must pass assessment)',
        hint: 'Whether users must pass an assessment to be certified'),
    Field('refresherFrequency', String,
        'Refresher Frequency (how often retraining is needed)',
        hint: 'How often retraining or refresher courses are needed'),
    Field('supportLevel', String,
        'Support Level Expected (Self-service, Help desk, Dedicated)',
        hint: 'Self-service / Help desk / Dedicated'),
    Field('documentationNeeds', String,
        'Documentation Needs (User guide, Quick reference, Video tutorials)',
        hint: 'User guide / Quick reference / Video tutorials'),
    Field('onboardingProcess', String,
        'Onboarding Process (steps to get started)',
        hint: 'Steps needed to get a new user started'),
    Field('mentoringRequired', bool,
        'Mentoring Required (paired with experienced user)',
        hint: 'Whether new users are paired with an experienced mentor'),
  ])
  @SerializationOrder(1)
  String? trainingForm;

  /// Training topics — contains 0+× TrainingTopicEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 12207 — training/support processes',
      'ISO 9241-210 — user support',
    ],
    'The set of specific training topics for this user category.',
  )
  @SectionId('TRTP-TRAI-LST')
  @SectionIdPattern('TRTP-TRAI-xxx')
  @ContentHelp('Define specific training topics for this user category.')
  @SerializationOrder(2)
  List<TrainingTopicEntry> trainingTopics = [];
}

/// A training topic entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 12207 — training/support processes',
    'ISO 9241-210 — user support',
  ],
  'A single training topic — its learning objectives, duration, prerequisites, '
  'and assessment method.',
)
@SectionId('TRTP')
class TrainingTopicEntry {
  @Form([
    Field('topicName', String, 'Topic Name',
        required: true, hint: 'Name of the training topic'),
    Field('description', String, 'Description',
        hint: 'Brief description of what this topic covers'),
    Field('learningObjectives', String, 'Learning Objectives',
        hint: 'What learners should be able to do after this topic'),
    Field('duration', String, 'Duration',
        hint: 'Estimated time to cover this topic'),
    Field('prerequisites', String, 'Prerequisites',
        hint: 'Knowledge or topics required before this one'),
    Field('assessmentMethod', String, 'Assessment Method',
        hint: 'How learning of this topic is assessed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.1.4.n.6. Accessibility Needs.
///
/// Accessibility requirements and accommodations for this user category.
@StandardReferences(
  [
    'WCAG 2.1 — web content accessibility',
    'EN 301 549 — ICT accessibility',
  ],
  'Captures the accessibility requirements and accommodations for this user '
  'category — visual, auditory, motor, cognitive, and language needs.',
)
@ContentHelp('Document any accessibility requirements or accommodations '
    'that should be considered for this user category.')
@SectionId('UAN')
class UserAccessibilityNeeds {
  @SerializationOrder(0)
  String? content;

  /// Accessibility Needs Form.
  @Form([
    Field('visualRequirements', String,
        'Visual Requirements (screen reader, high contrast, magnification)',
        hint: 'Screen reader / high contrast / magnification needs'),
    Field('auditoryRequirements', String,
        'Auditory Requirements (captions, visual alerts)',
        hint: 'Captions / visual alerts for auditory content'),
    Field('motorRequirements', String,
        'Motor Requirements (keyboard navigation, voice control)',
        hint: 'Keyboard navigation / voice control needs'),
    Field('cognitiveRequirements', String,
        'Cognitive Requirements (simple language, clear navigation)',
        hint: 'Simple language / clear navigation needs'),
    Field('languageRequirements', String,
        'Language Requirements (multiple languages, reading level)',
        hint: 'Multiple languages / reading level needs'),
    Field('deviceAccommodations', String,
        'Device Accommodations (large buttons, touch targets)',
        hint: 'Large buttons / touch target sizing needs'),
    Field('wcagLevel', String,
        'WCAG Conformance Level Required (A, AA, AAA)',
        hint: 'A / AA / AAA'),
    Field('additionalStandards', String,
        'Additional Standards (Section 508, EN 301 549, etc.)',
        hint: 'Section 508 / EN 301 549 / other accessibility standards'),
  ])
  @SerializationOrder(1)
  String? accessibilityForm;
}

/// 4.1.4.n.7. User Journey.
///
/// Key touchpoints and journey map for this user category's experience.
@StandardReferences(
  [
    'ISO 9241-210 — user journey & experience',
    'BABOK v3 §10 — customer journey mapping',
  ],
  'Captures the end-to-end journey for this user category — its stages, '
  'touchpoints, pain points, and opportunities for delight.',
)
@ContentHelp('Document the user journey - key touchpoints and stages '
    'in this user category\'s interaction with the system.')
@SectionId('UJ')
class UserJourney {
  @SerializationOrder(0)
  String? content;

  /// User journey diagram.
  @ContentType('mermaid-flowchart', 'User journey map showing stages, '
      'touchpoints, and emotional peaks/valleys')
  @ContentHelp('Create a journey map showing the user\'s experience '
      'from first contact through regular use.')
  @SerializationOrder(1)
  String? journeyDiagram;

  /// Journey stage entries — contains 0+× JourneyStageEntry.
  @StandardReferences(
    [
      'ISO 9241-210 — user journey & experience',
      'BABOK v3 §10 — customer journey mapping',
    ],
    'The ordered set of stages that make up this user journey.',
  )
  @SectionId('JRNST-STAG-LST')
  @SectionIdPattern('JRNST-STAG-xxx')
  @ContentHelp('Define each stage of the user journey.')
  @SerializationOrder(2)
  List<JourneyStageEntry> stages = [];

  /// Key touchpoints.
  @StandardReferences(
    [
      'ISO 9241-210 — user journey & experience',
      'BABOK v3 §10 — customer journey mapping',
    ],
    'The set of key touchpoints where this user category interacts with the '
    'system across the journey.',
  )
  @SectionId('KEYTO-KEYT-LST')
  @SectionIdPattern('KEYTO-KEYT-xxx')
  @ContentHelp('Add one entry per key touchpoint in the user journey.')
  @SerializationOrder(3)
  List<KeyTouchpointEntry> keyTouchpoints = [];

  /// Pain points in the journey.
  @StandardReferences(
    [
      'ISO 9241-210 — user journey & experience',
      'BABOK v3 §10 — customer journey mapping',
    ],
    'The set of pain points this user category encounters during the journey.',
  )
  @SectionId('USERJ-PAIN-LST')
  @SectionIdPattern('USERJ-PAIN-xxx')
  @ContentHelp('Add one entry per pain point or friction in the user journey.')
  @SerializationOrder(4)
  List<UserJourneyPainPointEntry> painPoints = [];

  /// Opportunities for delight.
  @ContentType('description', 'Opportunities to exceed user expectations '
      'and create positive experiences.')
  @SerializationOrder(5)
  String? opportunitiesForDelight;
}

/// A journey stage entry (form).
@StandardReferences(
  [
    'ISO 9241-210 — user journey & experience',
    'BABOK v3 §10 — customer journey mapping',
  ],
  'A single stage of the user journey — its goal, user actions, system '
  'response, emotions, touchpoints, and success metrics.',
)
@SectionId('JRNST')
class JourneyStageEntry {
  @Form([
    Field('stageName', String, 'Stage Name',
        required: true, hint: 'Name of this journey stage'),
    Field('stageDescription', String, 'Stage Description',
        hint: 'Brief description of what happens in this stage'),
    Field('userGoal', String, 'User Goal (what they want to achieve)',
        hint: 'What the user wants to achieve in this stage'),
    Field('userActions', String, 'User Actions (what they do)',
        hint: 'What the user does during this stage'),
    Field('systemResponse', String, 'System Response (what system does)',
        hint: 'How the system responds during this stage'),
    Field('userEmotions', String, 'User Emotions (expected feeling)',
        hint: 'The emotion the user is expected to feel here'),
    Field('touchpoints', String, 'Touchpoints (system interactions)',
        hint: 'System interactions or touchpoints in this stage'),
    Field('potentialIssues', String, 'Potential Issues',
        hint: 'Problems or friction the user may hit in this stage'),
    Field('successMetrics', String, 'Success Metrics',
        hint: 'How success is measured for this stage'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.2 Goals
// ---------------------------------------------------------------------------

/// 4.2. Goals.
///
/// Container for project goals organized by category. Goals provide measurable
/// objectives that guide project execution and define success. This section
/// supports OKR (Objectives and Key Results) methodology while also
/// accommodating traditional goal structures.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — system purpose & goals',
    'BABOK v3 §6 — strategy analysis (goals & objectives)',
  ],
  'Captures the measurable goals the project must achieve, organized by '
  'category, that define success and guide execution.',
)
@ContentHelp('Define clear, measurable goals that the project must achieve. '
    'Organize goals by category (business, technical) and ensure each goal '
    'has specific success metrics and target dates.')
@SectionId('GOALS')
class Goals {
  @SerializationOrder(0)
  String? content;

  /// Goal hierarchy diagram.
  @ContentType('mermaid-flowchart', 'Goal hierarchy and dependency diagram '
      'showing relationships between business and technical goals')
  @ContentHelp('Create a diagram showing goal categories, dependencies, '
      'and alignment to strategic objectives.')
  @SerializationOrder(1)
  String? goalHierarchyDiagram;

  /// 4.2.1. Business Goals.
  @SerializationOrder(2)
  BusinessGoals businessGoals = BusinessGoals();

  /// 4.2.2. Technical Goals.
  @SerializationOrder(3)
  TechnicalGoals technicalGoals = TechnicalGoals();

  /// 4.2.3. Success Criteria.
  @SerializationOrder(4)
  SuccessCriteria successCriteria = SuccessCriteria();
}

// ---------------------------------------------------------------------------
// 4.2.1 Business Goals
// ---------------------------------------------------------------------------

/// 4.2.1. Business Goals.
///
/// Container for business goal definitions. Business goals define what the
/// organization wants to achieve through this project in terms of business
/// outcomes, value delivery, and strategic advancement.
@StandardReferences(
  [
    'BABOK v3 §6.1 — business goals & objectives',
    'ISO/IEC/IEEE 29148 §6 — business need',
  ],
  'Captures the business outcomes the organization wants to achieve through '
  'this project, expressed as SMART goals with ownership and metrics.',
)
@ContentHelp('Define business goals that are specific, measurable, achievable, '
    'relevant, and time-bound (SMART). Each goal should have clear ownership '
    'and success metrics.')
@SectionId('BG')
class BusinessGoals {
  @ContentType('description', 'Overview of business goals and their '
      'relationship to organizational strategy. Explain how these goals '
      'support the business case and value proposition.')
  @SerializationOrder(0)
  String? content;

  /// Business goals list — contains 1+× Business Goal.
  @StandardReferences(
    [
      'BABOK v3 §6.1 — business goals & objectives',
      'ISO/IEC/IEEE 29148 §6 — business need',
    ],
    'The set of individual business goal entries defined for this project.',
  )
  @SectionId('BGE-GOAL-LST')
  @SectionIdPattern('BGE-GOAL-xxx')
  @Min(1)
  @ContentHelp('Add one entry per business goal. Goals should be mutually '
      'exclusive and collectively exhaustive for the project scope.')
  @SerializationOrder(1)
  List<BusinessGoalEntry> goals = [];
}

/// A business goal entry.
///
/// Comprehensive business goal definition following SMART criteria with
/// OKR-style key results, ownership, and tracking information.
@StandardReferences(
  [
    'BABOK v3 §6.1 — business goals & objectives',
    'ISO/IEC/IEEE 29148 §6 — business need',
  ],
  'Captures a single SMART business goal with OKR-style key results, '
  'ownership, and tracking information.',
)
@SectionId('BGE')
class BusinessGoalEntry {
  @Form([
    Field('goalId', String, 'Goal ID (unique identifier, e.g., BG-001)',
        required: true, hint: 'Unique goal identifier, e.g., BG-001'),
    Field('goalName', String, 'Goal Name (concise objective statement)',
        required: true, hint: 'Concise one-line objective statement'),
    Field('goalCategory', String,
        'Goal Category (Strategic, Tactical, Operational)', required: true,
        hint: 'Strategic, Tactical, or Operational'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Goal definition and priority.
  @SerializationOrder(1)
  BusinessGoalEntryDefinition definition = BusinessGoalEntryDefinition();

  /// Success metric and measurement.
  @SerializationOrder(2)
  BusinessGoalEntryMeasurement measurement = BusinessGoalEntryMeasurement();

  /// Ownership and timeline.
  @SerializationOrder(3)
  BusinessGoalEntryGovernance governance = BusinessGoalEntryGovernance();

  /// Business rationale and impact.
  @SerializationOrder(4)
  BusinessGoalEntryStrategy strategy = BusinessGoalEntryStrategy();

  /// 4.2.1.n.1. Key Results.
  @SerializationOrder(5)
  GoalKeyResults keyResults = GoalKeyResults();

  /// 4.2.1.n.2. Milestones.
  @SerializationOrder(6)
  GoalMilestones milestones = GoalMilestones();

  /// 4.2.1.n.3. Dependencies.
  @SerializationOrder(7)
  GoalDependencies dependencies = GoalDependencies();

  /// 4.2.1.n.4. Risks.
  @SerializationOrder(8)
  GoalRisks risks = GoalRisks();

  /// 4.2.1.n.5. Resources.
  @SerializationOrder(9)
  GoalResources resources = GoalResources();
}

/// Goal definition and priority.
@StandardReferences(
  [
    'BABOK v3 §6.1 — business goals & objectives',
    'ISO/IEC/IEEE 29148 §6 — business need',
  ],
  'Captures the detailed meaning, type, and priority of a single business '
  'goal.',
)
@SectionId('BGED')
class BusinessGoalEntryDefinition {
  @Form([
    Field('description', String,
        'Description (detailed explanation of what this goal means)',
        hint: 'Detailed explanation of what this goal means'),
    Field('goalType', String,
        'Goal Type (Revenue, Cost Reduction, Efficiency, Quality, Compliance, '
            'Growth, Customer Satisfaction, Market Position, Innovation)',
        hint: 'e.g., Revenue, Cost Reduction, Quality, Compliance, Growth'),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)',
        required: true, hint: 'Critical, High, Medium, or Low'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Success metric and measurement.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — measures of effectiveness',
    'SMART objectives — measurable goals',
  ],
  'Captures the measurable success metric, baseline, target, and measurement '
  'method for a business goal.',
)
@SectionId('BGEM')
class BusinessGoalEntryMeasurement {
  @Form([
    Field('successMetric', String,
        'Primary Success Metric (what is measured)', required: true,
        hint: 'The primary quantity measured to gauge success'),
    Field('currentValue', String,
        'Current Value (baseline measurement before project)',
        hint: 'Baseline measurement before the project starts'),
    Field('targetValue', String, 'Target Value (desired end state)',
        required: true, hint: 'Desired end-state value for the metric'),
    Field('measurementMethod', String,
        'Measurement Method (how the metric is captured)',
        hint: 'How the metric is captured or calculated'),
    Field('measurementFrequency', String,
        'Measurement Frequency (Daily, Weekly, Monthly, Quarterly)',
        hint: 'Daily, Weekly, Monthly, or Quarterly'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership and timeline.
@StandardReferences(
  [
    'ISO 21500 — governance',
    'BABOK v3 §6 — monitoring',
  ],
  'Captures ownership, timeline, contributing stakeholders, and current '
  'status for a business goal.',
)
@SectionId('BGEG')
class BusinessGoalEntryGovernance {
  @Form([
    Field('targetDate', String, 'Target Date (when goal should be achieved)',
        required: true, hint: 'Date by which the goal should be achieved'),
    Field('owner', String, 'Goal Owner (accountable person or role)',
        required: true, hint: 'Accountable person or role for this goal'),
    Field('stakeholders', String,
        'Contributing Stakeholders (roles involved in achieving this goal)',
        hint: 'Roles involved in achieving this goal'),
    Field('status', String,
        'Status (Not Started, In Progress, On Track, At Risk, Achieved)',
        hint: 'Not Started, In Progress, On Track, At Risk, or Achieved'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Business rationale and impact.
@StandardReferences(
  [
    'BABOK v3 §6.1 — business goals & objectives',
    'ISO/IEC/IEEE 29148 §6 — business need',
  ],
  'Captures the business rationale, strategic alignment, impact areas, and '
  'estimated value justifying a business goal.',
)
@SectionId('BGES')
class BusinessGoalEntryStrategy {
  @Form([
    Field('businessJustification', String,
        'Business Justification (why this goal matters)',
        hint: 'Why this goal matters to the business'),
    Field('strategicAlignment', String,
        'Strategic Alignment (link to corporate strategy or OKR)',
        hint: 'Link to corporate strategy or OKR'),
    Field('impactAreas', String,
        'Impact Areas (departments, processes, or systems affected)',
        hint: 'Departments, processes, or systems affected'),
    Field('estimatedValue', String,
        'Estimated Value (monetary or quantitative benefit)',
        hint: 'Monetary or quantitative benefit expected'),
    Field('riskOfNotAchieving', String,
        'Risk of Not Achieving (consequences of failure)',
        hint: 'Consequences if the goal is not achieved'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.2.1.n.1. Key Results.
///
/// OKR-style key results that indicate progress toward the goal.
/// Key results are specific, measurable outcomes that together constitute
/// achievement of the parent goal.
@StandardReferences(
  [
    'OKR — objectives & key results',
    'BABOK v3 §6 — objectives',
  ],
  'Captures the OKR-style key results that together indicate achievement of '
  'the parent business goal.',
)
@ContentHelp('Define 3-5 key results that together indicate goal achievement. '
    'Each key result should be independently measurable.')
@SectionId('GKR')
class GoalKeyResults {
  @ContentType('description', 'Overview of key results and how they '
      'collectively demonstrate goal achievement.')
  @SerializationOrder(0)
  String? content;

  /// Key result entries — contains 0+× KeyResultEntry.
  @StandardReferences(
    [
      'OKR — objectives & key results',
      'BABOK v3 §6 — objectives',
    ],
    'The set of individual key-result entries for a business goal.',
  )
  @SectionId('KRE-ITEM-LST')
  @SectionIdPattern('KRE-ITEM-xxx')
  @ContentHelp('Add 3-5 key results per goal. Each should be specific '
      'and measurable.')
  @SerializationOrder(1)
  List<KeyResultEntry> items = [];
}

/// A key result entry (form).
@StandardReferences(
  [
    'OKR — objectives & key results',
    'BABOK v3 §6 — objectives',
  ],
  'Captures a single measurable key result with its metric, baseline, target, '
  'progress, and status.',
)
@SectionId('KRE')
class KeyResultEntry {
  @Form([
    Field('keyResultId', String, 'Key Result ID', required: true,
        hint: 'Unique identifier for this key result'),
    Field('keyResult', String, 'Key Result (measurable outcome)', required: true,
        hint: 'The measurable outcome that signals progress'),
    Field('metric', String, 'Metric (what is measured)',
        hint: 'What quantity is measured'),
    Field('baselineValue', String, 'Baseline Value (starting point)',
        hint: 'Starting value before work begins'),
    Field('targetValue', String, 'Target Value (desired endpoint)',
        required: true, hint: 'Desired endpoint value'),
    Field('currentValue', String, 'Current Value (latest measurement)',
        hint: 'Latest measured value'),
    Field('progress', String, 'Progress (percentage toward target)',
        hint: 'Percentage of progress toward the target'),
    Field('owner', String, 'Owner (responsible person)',
        hint: 'Person responsible for this key result'),
    Field('dueDate', String, 'Due Date', hint: 'Date the key result is due'),
    Field('status', String, 'Status (Not Started, In Progress, Achieved, Missed)',
        hint: 'Not Started, In Progress, Achieved, or Missed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.2.1.n.2. Milestones.
///
/// Key milestones marking progress toward the goal.
@StandardReferences(
  [
    'ISO 21500 — project milestones',
    'PMBOK — schedule milestones',
  ],
  'Captures the key milestones that mark significant progress points toward '
  'achieving a business goal.',
)
@SectionId('GOMI')
@ContentHelp('Define milestones that mark significant progress points.')
class GoalMilestones {
  @ContentType('description', 'Overview of milestone approach and how '
      'milestones relate to goal progress.')
  @SerializationOrder(0)
  String? content;

  /// Milestone entries — contains 0+× GoalMilestoneEntry.
  @StandardReferences(
    [
      'ISO 21500 — project milestones',
      'PMBOK — schedule milestones',
    ],
    'The set of individual milestone entries marking progress toward a goal.',
  )
  @SectionId('GOLMS-ITEM-LST')
  @SectionIdPattern('GOLMS-ITEM-xxx')
  @ContentHelp('Add one entry per milestone, ordered by target date.')
  @SerializationOrder(1)
  List<GoalMilestoneEntry> items = [];
}

/// A goal milestone entry (form).
@StandardReferences(
  [
    'ISO 21500 — project milestones',
    'PMBOK — schedule milestones',
  ],
  'Captures a single milestone with its target date, completion criteria, '
  'deliverables, and status.',
)
@SectionId('GOLMS')
class GoalMilestoneEntry {
  @Form([
    Field('milestoneId', String, 'Milestone ID', required: true,
        hint: 'Unique identifier for this milestone'),
    Field('milestoneName', String, 'Milestone Name', required: true,
        hint: 'Short descriptive name for the milestone'),
    Field('description', String, 'Description',
        hint: 'What this milestone represents'),
    Field('targetDate', String, 'Target Date', required: true,
        hint: 'Planned date for reaching the milestone'),
    Field('completionCriteria', String, 'Completion Criteria',
        hint: 'How completion of the milestone is determined'),
    Field('deliverables', String, 'Deliverables (outputs of this milestone)',
        hint: 'Outputs produced at this milestone'),
    Field('dependencies', String, 'Dependencies (what must be done first)',
        hint: 'What must be completed before this milestone'),
    Field('status', String, 'Status (Planned, In Progress, Completed, Delayed)',
        hint: 'Planned, In Progress, Completed, or Delayed'),
    Field('actualDate', String, 'Actual Completion Date',
        hint: 'Date the milestone was actually completed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.2.1.n.3. Dependencies.
///
/// Dependencies that may affect goal achievement.
@StandardReferences(
  [
    'ISO 21500 — dependency management',
    'BABOK v3 §6 — dependencies',
  ],
  'Captures the dependencies on other goals, projects, or external factors '
  'that may affect achievement of a business goal.',
)
@SectionId('GODE')
@ContentHelp('Identify dependencies on other goals, projects, or external factors.')
class GoalDependencies {
  @ContentType('description', 'Overview of dependencies and their impact '
      'on goal achievement timeline.')
  @SerializationOrder(0)
  String? content;

  /// Dependency entries — contains 0+× GoalDependencyEntry.
  @StandardReferences(
    [
      'ISO 21500 — dependency management',
      'BABOK v3 §6 — dependencies',
    ],
    'The set of individual dependency entries affecting a business goal.',
  )
  @SectionId('GOLDE-ITEM-LST')
  @SectionIdPattern('GOLDE-ITEM-xxx')
  @ContentHelp('Add one entry per dependency, including its type and impact.')
  @SerializationOrder(1)
  List<GoalDependencyEntry> items = [];
}

/// A goal dependency entry (form).
@StandardReferences(
  [
    'ISO 21500 — dependency management',
    'BABOK v3 §6 — dependencies',
  ],
  'Captures a single dependency with its type, owner, impact, and mitigation '
  'for a business goal.',
)
@SectionId('GOLDE')
class GoalDependencyEntry {
  @Form([
    Field('dependencyId', String, 'Dependency ID', required: true,
        hint: 'Unique identifier for this dependency'),
    Field('dependencyType', String,
        'Dependency Type (Internal Goal, External Project, Resource, '
            'Regulatory, Technical, Organizational)',
        required: true,
        hint: 'e.g., Internal Goal, External Project, Resource, Regulatory'),
    Field('dependencyName', String, 'Dependency Name (what we depend on)',
        required: true, hint: 'Name of the thing this goal depends on'),
    Field('description', String, 'Description',
        hint: 'Details of the dependency'),
    Field('owner', String, 'Owner (who controls this dependency)',
        hint: 'Person or party who controls this dependency'),
    Field('expectedResolutionDate', String, 'Expected Resolution Date',
        hint: 'When the dependency is expected to be resolved'),
    Field('impact', String, 'Impact (how this affects our goal)',
        hint: 'How this dependency affects the goal'),
    Field('mitigationStrategy', String,
        'Mitigation Strategy (what if dependency is not resolved)',
        hint: 'Plan if the dependency is not resolved'),
    Field('status', String, 'Status (Open, In Progress, Resolved, Blocked)',
        hint: 'Open, In Progress, Resolved, or Blocked'),
  ])
  @SerializationOrder(0)
  String? content;

  @Reference('Related Goal')
  @SerializationOrder(1)
  String? relatedGoal;
}

/// 4.2.1.n.4. Risks.
///
/// Risks that may prevent or delay goal achievement.
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'BABOK v3 §6 — risks',
  ],
  'Captures the risks that may prevent or delay achievement of a business '
  'goal, together with their mitigation strategies.',
)
@SectionId('GORI')
@ContentHelp('Identify risks specific to this goal and mitigation strategies.')
class GoalRisks {
  @ContentType('description', 'Overview of risks affecting this goal '
      'and overall risk posture.')
  @SerializationOrder(0)
  String? content;

  /// Risk entries — contains 0+× GoalRiskEntry.
  @StandardReferences(
    [
      'ISO 31000:2018 — risk management',
      'BABOK v3 §6 — risks',
    ],
    'The set of individual risk entries affecting a business goal.',
  )
  @SectionId('GOLRS-ITEM-LST')
  @SectionIdPattern('GOLRS-ITEM-xxx')
  @ContentHelp('Add one entry per risk, with assessment and response details.')
  @SerializationOrder(1)
  List<GoalRiskEntry> items = [];
}

/// A goal risk entry (form).
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'BABOK v3 §6 — risks',
  ],
  'Captures a single risk to a business goal, including its category, '
  'assessment, and response.',
)
@SectionId('GOLRS')
class GoalRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID', required: true,
        hint: 'Unique identifier for this risk'),
    Field('riskName', String, 'Risk Name', required: true,
        hint: 'Short descriptive name for the risk'),
    Field('description', String, 'Description',
        hint: 'What the risk is and how it could materialize'),
    Field('riskCategory', String,
        'Risk Category (Market, Operational, Technical, Resource, '
            'Regulatory, External)',
        hint: 'e.g., Market, Operational, Technical, Resource, Regulatory'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Risk assessment details.
    @SerializationOrder(1)
    GoalRiskEntryAssessment assessment = GoalRiskEntryAssessment();

    /// Mitigation ownership and status.
    @SerializationOrder(2)
    GoalRiskEntryResponse response = GoalRiskEntryResponse();
}

/// Risk assessment details.
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'BABOK v3 §6 — risks',
  ],
  'Captures the probability, impact, score, and trigger conditions assessed '
  'for a goal risk.',
)
@SectionId('GREA')
class GoalRiskEntryAssessment {
    @Form([
        Field('probability', String, 'Probability (Low, Medium, High)',
            hint: 'Low, Medium, or High'),
        Field('impact', String, 'Impact (Low, Medium, High, Critical)',
            hint: 'Low, Medium, High, or Critical'),
        Field('riskScore', String, 'Risk Score (probability × impact)',
            hint: 'Computed as probability multiplied by impact'),
        Field('triggerConditions', String, 'Trigger Conditions (early warning signs)',
            hint: 'Early warning signs the risk is materializing'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Mitigation ownership and status.
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'BABOK v3 §6 — risks',
  ],
  'Captures the mitigation strategy, contingency plan, owner, and status of '
  'the response to a goal risk.',
)
@SectionId('GRER')
class GoalRiskEntryResponse {
    @Form([
        Field('mitigationStrategy', String, 'Mitigation Strategy',
            hint: 'Actions taken to reduce the risk'),
        Field('contingencyPlan', String, 'Contingency Plan (if risk occurs)',
            hint: 'What to do if the risk materializes'),
        Field('owner', String, 'Risk Owner',
            hint: 'Person accountable for managing the risk'),
        Field('status', String, 'Status (Identified, Mitigating, Occurred, Closed)',
            hint: 'Identified, Mitigating, Occurred, or Closed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 4.2.1.n.5. Resources.
///
/// Resources required to achieve the goal.
@StandardReferences(
  [
    'PMBOK — resource management',
    'ISO 21500 — resources',
  ],
  'Captures the people, budget, and tools required to achieve a business '
  'goal, including detailed resource allocations.',
)
@SectionId('GORE')
@ContentHelp('Define resources (people, budget, tools) needed for this goal.')
class GoalResources {
  @SerializationOrder(0)
  String? content;

  /// Resource requirement form.
  @Form([
    Field('totalBudget', String, 'Total Budget (estimated or allocated)',
        hint: 'Estimated or allocated total budget'),
    Field('fteRequired', String, 'FTE Required (full-time equivalent staff)',
        hint: 'Number of full-time-equivalent staff needed'),
    Field('keySkills', String, 'Key Skills Required',
        hint: 'Critical skills needed to achieve the goal'),
    Field('toolsRequired', String, 'Tools or Systems Required',
        hint: 'Tools or systems needed'),
    Field('externalSupport', String,
        'External Support (consultants, vendors)',
        hint: 'Consultants or vendors required'),
    Field('trainingNeeds', String, 'Training Needs',
        hint: 'Training the team needs to acquire'),
  ])
  @SerializationOrder(1)
  String? resourcesForm;

  /// Resource allocation entries — contains 0+× ResourceAllocationEntry.
  @StandardReferences(
    [
      'PMBOK — resource management',
      'ISO 21500 — resources',
    ],
    'The set of individual resource allocation entries for a business goal.',
  )
  @SectionId('REARS-ITEM-LST')
  @SectionIdPattern('REARS-ITEM-xxx')
  @ContentHelp('Add one entry per allocated resource (personnel, budget, tool).')
  @SerializationOrder(2)
  List<ResourceAllocationEntry> items = [];
}

/// A resource allocation entry (form).
@StandardReferences(
  [
    'PMBOK — resource management',
    'ISO 21500 — resources',
  ],
  'Captures a single allocated resource with its type, quantity, duration, '
  'cost, availability, and status.',
)
@SectionId('REARS')
class ResourceAllocationEntry {
  @Form([
    Field('resourceType', String,
        'Resource Type (Personnel, Budget, Tool, System, External)',
        required: true,
        hint: 'Personnel, Budget, Tool, System, or External'),
    Field('resourceName', String, 'Resource Name', required: true,
        hint: 'Name of the specific resource'),
    Field('quantity', String, 'Quantity or Allocation',
        hint: 'Amount or share of the resource allocated'),
    Field('duration', String, 'Duration (how long needed)',
        hint: 'How long the resource is needed'),
    Field('estimatedCost', String, 'Estimated Cost',
        hint: 'Estimated cost of the resource'),
    Field('availability', String, 'Availability (when available)',
        hint: 'When the resource becomes available'),
    Field('source', String, 'Source (internal, external, to be hired)',
        hint: 'Internal, external, or to be hired'),
    Field('status', String, 'Status (Requested, Allocated, Confirmed)',
        hint: 'Requested, Allocated, or Confirmed'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.2.2 Technical Goals
// ---------------------------------------------------------------------------

/// 4.2.2. Technical Goals.
///
/// Container for technical goal definitions. Technical goals define the
/// non-functional characteristics and technical capabilities the system
/// must achieve, such as performance, scalability, reliability, and security.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality goals',
    'ISO/IEC/IEEE 42010 — architecture goals',
  ],
  'The root of §4.2.2: captures the non-functional, quality-attribute goals '
  'the system must achieve (performance, scalability, reliability, security) '
  'with measurable criteria and verification methods.',
)
@ContentHelp('Define technical goals that establish the quality attributes '
    'and capabilities of the system. Each goal should have measurable '
    'criteria and clear verification methods.')
@SectionId('TG')
class TechnicalGoals {
  @ContentType('description', 'Overview of technical goals and their '
      'relationship to business requirements. Explain the technical '
      'vision and quality attribute priorities.')
  @SerializationOrder(0)
  String? content;

  /// Technical goals list — contains 1+× Technical Goal.
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality goals',
      'ISO/IEC/IEEE 42010 — architecture goals',
    ],
    'The list of individual technical-goal entries for this project.',
  )
  @SectionId('TGE-GOAL-LST')
  @SectionIdPattern('TGE-GOAL-xxx')
  @Min(1)
  @ContentHelp('Add one entry per technical goal. Cover key quality '
      'attributes: performance, scalability, reliability, security, '
      'usability, maintainability.')
  @SerializationOrder(1)
  List<TechnicalGoalEntry> goals = [];
}

/// A technical goal entry.
///
/// Comprehensive technical goal definition with quality attributes,
/// architectural impact, and verification approach.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality goals',
    'ISO/IEC/IEEE 42010 — architecture goals',
  ],
  'A single technical goal: its category, priority, measurement, governance, '
  'quality scenarios, test criteria, dependencies, and constraints.',
)
@SectionId('TGE')
class TechnicalGoalEntry {
  @Form([
    Field('goalId', String, 'Goal ID (unique identifier, e.g., TG-001)',
        required: true, hint: 'Unique identifier, e.g. TG-001'),
    Field('goalName', String, 'Goal Name (concise statement)', required: true,
        hint: 'Concise statement of the technical goal'),
    Field('description', String,
        'Description (detailed explanation of the technical objective)',
        hint: 'Detailed explanation of the technical objective'),
    Field('goalCategory', String,
        'Goal Category (Performance, Scalability, Reliability, Security, '
            'Usability, Accessibility, Maintainability, Portability, '
            'Interoperability, Compliance)',
        required: true,
        hint: 'Quality attribute category, e.g. Performance, Security'),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)',
        required: true, hint: 'Critical / High / Medium / Low'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Success measurement details.
  @SerializationOrder(1)
  TechnicalGoalEntryMeasurement measurement = TechnicalGoalEntryMeasurement();

  /// Scope and ownership details.
  @SerializationOrder(2)
  TechnicalGoalEntryGovernance governance = TechnicalGoalEntryGovernance();

  /// 4.2.2.n.1. Quality Scenarios.
  @SerializationOrder(3)
  QualityScenarios qualityScenarios = QualityScenarios();

  /// 4.2.2.n.2. Test Criteria.
  @SerializationOrder(4)
  TechnicalGoalTestCriteria testCriteria = TechnicalGoalTestCriteria();

  /// 4.2.2.n.3. Dependencies.
  @SerializationOrder(5)
  TechnicalGoalDependencies dependencies = TechnicalGoalDependencies();

  /// 4.2.2.n.4. Constraints.
  @SerializationOrder(6)
  TechnicalGoalConstraints constraints = TechnicalGoalConstraints();
}

/// Success measurement details.
@StandardReferences(
  [
    'ISO/IEC 25010 — quality measures',
    'ISO/IEC 25023 — quality measurement',
  ],
  'How achievement of the technical goal is measured: the success metric, '
  'baseline and target values, measurement method, tool, environment, and '
  'verification point.',
)
@SectionId('TGEM')
class TechnicalGoalEntryMeasurement {
    @Form([
        Field('successMetric', String,
                'Primary Success Metric (what is measured)', required: true,
                hint: 'The primary quantity measured for this goal'),
        Field('currentValue', String, 'Current/Baseline Value',
                hint: 'Current/baseline value before the project'),
        Field('targetValue', String, 'Target Value', required: true,
                hint: 'Target value to be achieved'),
        Field('measurementMethod', String,
                'Measurement Method (APM, load testing, security scan, etc.)',
                hint: 'APM, load testing, security scan, etc.'),
        Field('measurementTool', String,
                'Measurement Tool (specific tool or platform)',
                hint: 'Specific tool or platform used to measure'),
        Field('measurementEnvironment', String,
                'Measurement Environment (production, staging, load test)',
                hint: 'Production, staging, or load-test environment'),
        Field('verificationPoint', String,
                'Verification Point (when/how verified: unit test, integration, '
                        'acceptance, production monitoring)',
                hint: 'When/how verified: unit, integration, acceptance, '
                        'production monitoring'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Scope and ownership details.
@StandardReferences(
  ['ISO 21500 — governance'],
  'Scope and ownership of the technical goal: the system area affected, '
  'architecture impact, technical owner, and current status.',
)
@SectionId('TGEG')
class TechnicalGoalEntryGovernance {
    @Form([
        Field('systemArea', String,
                'System Area Affected (frontend, backend, database, network, all)',
                hint: 'Frontend, backend, database, network, or all'),
        Field('architectureImpact', String,
                'Architecture Impact (how this affects system design)',
                hint: 'How this goal affects system design'),
        Field('owner', String, 'Technical Owner',
                hint: 'Person accountable for achieving this goal'),
        Field('status', String,
                'Status (Not Started, In Progress, Verified, Failed)',
                hint: 'Not Started / In Progress / Verified / Failed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 4.2.2.n.1. Quality Scenarios.
///
/// Quality attribute scenarios that define concrete, testable situations
/// for verifying the technical goal (based on SEI quality attribute workshop).
@StandardReferences(
  [
    'ISO/IEC 25010 — quality attributes',
    'SEI ATAM — quality attribute scenarios',
  ],
  'Concrete, testable quality-attribute scenarios (source → stimulus → '
  'environment → artifact → response → response measure) that verify the '
  'parent technical goal.',
)
@ContentHelp('Define quality scenarios using: Source → Stimulus → Environment → '
    'Artifact → Response → Response Measure pattern.')
@SectionId('QS')
class QualityScenarios {
  @ContentType('description', 'Overview of quality scenarios and how '
      'they verify achievement of the parent technical goal.')
  @SerializationOrder(0)
  String? content;

  /// Quality scenario entries — contains 0+× QualityScenarioEntry.
  @StandardReferences(
    [
      'ISO/IEC 25010 — quality attributes',
      'SEI ATAM — quality attribute scenarios',
    ],
    'The list of individual quality-attribute scenario entries.',
  )
  @SectionId('QLSCN-ITEM-LST')
  @SectionIdPattern('QLSCN-ITEM-xxx')
  @ContentHelp('Add one entry per quality scenario covering a distinct '
      'stimulus and measurable response for the goal.')
  @SerializationOrder(1)
  List<QualityScenarioEntry> items = [];
}

/// A quality scenario entry (form) - SEI Quality Attribute Workshop format.
@StandardReferences(
  [
    'ISO/IEC 25010 — quality attributes',
    'SEI ATAM — quality attribute scenarios',
  ],
  'A single quality-attribute scenario in SEI workshop form: source, stimulus, '
  'environment, artifact, response, and response measure.',
)
@SectionId('QLSCN')
class QualityScenarioEntry {
  @Form([
    Field('scenarioId', String, 'Scenario ID', required: true,
        hint: 'Unique identifier for the scenario'),
    Field('scenarioName', String, 'Scenario Name', required: true,
        hint: 'Short descriptive name'),
    Field('source', String, 'Source (who/what generates the stimulus)',
        required: true, hint: 'Who/what generates the stimulus'),
    Field('stimulus', String,
        'Stimulus (event or condition that triggers the scenario)',
        required: true, hint: 'Event or condition that triggers the scenario'),
    Field('environment', String,
        'Environment (system state when stimulus occurs)',
        hint: 'System state when the stimulus occurs'),
    Field('artifact', String, 'Artifact (what part of system is affected)',
        hint: 'What part of the system is affected'),
    Field('response', String, 'Response (how the system should respond)',
        required: true, hint: 'How the system should respond'),
    Field('responseMeasure', String,
        'Response Measure (quantifiable success criterion)', required: true,
        hint: 'Quantifiable success criterion for the response'),
    Field('priority', String, 'Priority (Core, Important, Nice-to-have)',
        hint: 'Core / Important / Nice-to-have'),
    Field('testability', String,
        'Testability (how easy to test: Automated, Manual, Complex)',
        hint: 'How easy to test: Automated, Manual, Complex'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.2.2.n.2. Test Criteria.
///
/// Specific test criteria and acceptance thresholds for the technical goal.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'ISO/IEC 25010 — quality verification',
  ],
  'The test criteria and acceptance thresholds — test type, environment, '
  'tools, pass/fail thresholds, and test cases — used to verify the technical '
  'goal has been achieved.',
)
@ContentHelp('Define specific test criteria that will be used to verify '
    'the technical goal has been achieved.')
@SectionId('TGTC')
class TechnicalGoalTestCriteria {
  @ContentHelp('Summarize the overall testing approach for verifying this '
      'technical goal.')
  @SerializationOrder(0)
  String? content;

  /// Test criteria form.
  @Form([
    Field('testType', String,
        'Test Type (Performance, Load, Stress, Security, Penetration, '
            'Accessibility, Usability)',
        hint: 'Performance, Load, Stress, Security, Penetration, etc.'),
    Field('testEnvironment', String, 'Test Environment',
        hint: 'Environment in which tests run'),
    Field('testData', String, 'Test Data Requirements',
        hint: 'Data needed to execute the tests'),
    Field('testTools', String, 'Test Tools',
        hint: 'Tools used to run the tests'),
    Field('passThreshold', String, 'Pass Threshold',
        hint: 'Value at or above which the goal passes'),
    Field('failThreshold', String, 'Fail Threshold',
        hint: 'Value at which the goal is considered failed'),
    Field('testSchedule', String, 'Test Schedule (when tests will run)',
        hint: 'When the tests will run'),
    Field('retestPolicy', String, 'Retest Policy (when retesting is required)',
        hint: 'When retesting is required'),
  ])
  @SerializationOrder(1)
  String? testCriteriaForm;

  /// Test case entries — contains 0+× TechnicalGoalTestCaseEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing',
      'ISO/IEC 25010 — quality verification',
    ],
    'The list of individual test-case entries for verifying the technical goal.',
  )
  @SectionId('TEGOTS-ITEM-LST')
  @SectionIdPattern('TEGOTS-ITEM-xxx')
  @ContentHelp('Add one entry per test case covering procedure, expected '
      'result, and status for this goal.')
  @SerializationOrder(2)
  List<TechnicalGoalTestCaseEntry> items = [];
}

/// A test case entry for technical goal verification (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'ISO/IEC 25010 — quality verification',
  ],
  'A single test case verifying a technical goal: procedure, expected and '
  'actual results, and status.',
)
@SectionId('TEGOTS')
class TechnicalGoalTestCaseEntry {
  @Form([
    Field('testCaseId', String, 'Test Case ID', required: true,
        hint: 'Unique identifier for the test case'),
    Field('testCaseName', String, 'Test Case Name', required: true,
        hint: 'Short descriptive name'),
    Field('description', String, 'Description',
        hint: 'What this test case verifies'),
    Field('testProcedure', String, 'Test Procedure',
        hint: 'Steps to execute the test'),
    Field('expectedResult', String, 'Expected Result',
        hint: 'Result expected when the goal is met'),
    Field('actualResult', String, 'Actual Result',
        hint: 'Result observed when the test was run'),
    Field('status', String, 'Status (Planned, In Progress, Passed, Failed)',
        hint: 'Planned / In Progress / Passed / Failed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.2.2.n.3. Dependencies.
///
/// Technical dependencies affecting goal achievement.
@StandardReferences(
  ['ISO 21500 — dependency management'],
  'The technical dependencies — infrastructure, APIs, third-party services, '
  'other components — that affect achievement of this goal.',
)
@ContentHelp('Identify technical dependencies: infrastructure, APIs, '
    'third-party services, other system components.')
@SectionId('TGD')
class TechnicalGoalDependencies {
  @ContentType('description', 'Overview of technical dependencies and '
      'their impact on achieving this goal.')
  @SerializationOrder(0)
  String? content;

  /// Dependency entries — contains 0+× TechnicalDependencyEntry.
  @StandardReferences(
    ['ISO 21500 — dependency management'],
    'The list of individual technical-dependency entries for this goal.',
  )
  @SectionId('TEDE-ITEM-LST')
  @SectionIdPattern('TEDE-ITEM-xxx')
  @ContentHelp('Add one entry per technical dependency, capturing type, '
      'version, SLA, fallback, and status.')
  @SerializationOrder(1)
  List<TechnicalDependencyEntry> items = [];
}

/// A technical dependency entry (form).
@StandardReferences(
  ['ISO 21500 — dependency management'],
  'A single technical dependency: its type, version, SLA, fallback, and '
  'availability status.',
)
@SectionId('TEDE')
class TechnicalDependencyEntry {
  @Form([
    Field('dependencyId', String, 'Dependency ID', required: true,
        hint: 'Unique identifier for the dependency'),
    Field('dependencyName', String, 'Dependency Name', required: true,
        hint: 'Name of the dependency'),
    Field('dependencyType', String,
        'Dependency Type (Infrastructure, API, Library, Service, '
            'Hardware, Network, Third-party)',
        hint: 'Infrastructure, API, Library, Service, Hardware, etc.'),
    Field('description', String, 'Description',
        hint: 'What the dependency provides'),
    Field('version', String, 'Version (if applicable)',
        hint: 'Required version, if applicable'),
    Field('sla', String, 'SLA (if external service)',
        hint: 'Service-level agreement for external services'),
    Field('fallback', String, 'Fallback (what if unavailable)',
        hint: 'What happens if the dependency is unavailable'),
    Field('status', String, 'Status (Available, Pending, At Risk)',
        hint: 'Available / Pending / At Risk'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.2.2.n.4. Constraints.
///
/// Technical constraints that may limit or shape how the goal is achieved.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — constraints',
    'ISO/IEC/IEEE 42010 — architecture constraints',
  ],
  'The technical constraints — technology choices, standards, resource limits, '
  'compatibility requirements — that limit or shape how this goal is achieved.',
)
@ContentHelp('Document constraints: technology choices, standards, '
    'resource limits, compatibility requirements.')
@SectionId('TGC')
class TechnicalGoalConstraints {
  @ContentType('description', 'Overview of constraints affecting this '
      'technical goal.')
  @SerializationOrder(0)
  String? content;

  /// Constraint entries — contains 0+× TechnicalConstraintEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — constraints',
      'ISO/IEC/IEEE 42010 — architecture constraints',
    ],
    'The list of individual technical-constraint entries for this goal.',
  )
  @SectionId('TECN-ITEM-LST')
  @SectionIdPattern('TECN-ITEM-xxx')
  @ContentHelp('Add one entry per technical constraint, capturing type, '
      'source, rationale, impact, and flexibility.')
  @SerializationOrder(1)
  List<TechnicalConstraintEntry> items = [];
}

/// A technical constraint entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — constraints',
    'ISO/IEC/IEEE 42010 — architecture constraints',
  ],
  'A single technical constraint: its type, source, rationale, impact on the '
  'approach, and degree of flexibility.',
)
@SectionId('TECN')
class TechnicalConstraintEntry {
  @Form([
    Field('constraintId', String, 'Constraint ID', required: true,
        hint: 'Unique identifier for the constraint'),
    Field('constraintName', String, 'Constraint Name', required: true,
        hint: 'Short descriptive name'),
    Field('constraintType', String,
        'Constraint Type (Technology, Standard, Resource, '
            'Compatibility, Budget, Timeline, Regulatory)',
        hint: 'Technology, Standard, Resource, Compatibility, Budget, etc.'),
    Field('description', String, 'Description',
        hint: 'What the constraint requires'),
    Field('source', String, 'Source (who/what imposed this constraint)',
        hint: 'Who or what imposed this constraint'),
    Field('rationale', String, 'Rationale (why this constraint exists)',
        hint: 'Why this constraint exists'),
    Field('impact', String, 'Impact (how this affects our approach)',
        hint: 'How this affects our approach'),
    Field('flexibility', String,
        'Flexibility (Fixed, Negotiable, Preferred)',
        hint: 'Fixed / Negotiable / Preferred'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.2.3 Success Criteria
// ---------------------------------------------------------------------------

/// 4.2.3. Success Criteria.
///
/// Overall project success criteria that determine whether the project
/// has achieved its objectives. These criteria will be used during
/// acceptance testing and project closure. Based on SMART criteria,
/// Balanced Scorecard, and PRINCE2 benefits management principles.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — acceptance & verification criteria',
    'BABOK v3 — solution evaluation',
  ],
  'The root of §4.2.3: captures the objectively verifiable, measurable, '
  'time-bound criteria that collectively determine whether the project has '
  'achieved its objectives at acceptance and closure.',
)
@ContentHelp('Define criteria that collectively determine project success. '
    'Each criterion should be objectively verifiable, measurable, and '
    'time-bound. Criteria should cover business, technical, user, and '
    'compliance dimensions.')
@SectionId('SC')
class SuccessCriteria {
  @ContentHelp('Provide an overview of how project success is determined and '
      'which dimensions the criteria collectively cover.')
  @SerializationOrder(0)
  String? content;

  /// Success criteria summary.
  @SerializationOrder(1)
  SuccessCriteriaSummary summary = SuccessCriteriaSummary();

  /// Acceptance and evaluation framework.
  @SerializationOrder(2)
  SuccessCriteriaFramework framework = SuccessCriteriaFramework();

  /// Success criterion entries — contains 1+× SuccessCriterionEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — acceptance & verification criteria',
      'BABOK v3 — solution evaluation',
    ],
    'The list of individual success-criterion entries for this project.',
  )
  @SectionId('SCE-ITEM-LST')
  @SectionIdPattern('SCE-ITEM-xxx')
  @Min(1)
  @ContentHelp('Define individual success criteria. Include criteria for '
      'business outcomes, user satisfaction, technical quality, and '
      'compliance requirements.')
  @SerializationOrder(3)
  List<SuccessCriterionEntry> items = [];

  /// Success criteria by category.
  @SerializationOrder(4)
  SuccessCriteriaByCategory byCategory = SuccessCriteriaByCategory();

  /// Success criteria matrix — overall view.
  @ContentType('description', 'Success criteria matrix showing all criteria, '
      'their weights, and evaluation status.')
  @ContentHelp('Create a summary matrix of all success criteria.')
  @SerializationOrder(5)
  String? successCriteriaMatrix;

  /// Post-implementation review plan.
  @SerializationOrder(6)
  PostImplementationReview postImplementationReview = PostImplementationReview();
}

/// Summary metrics for success criteria.
@StandardReferences(
  ['BABOK v3 — solution evaluation (success measures)'],
  'Aggregate counts and thresholds across all success criteria — totals by '
  'priority and category, and the overall threshold for declaring success.',
)
@Form([
  Field('totalCriteria', int, 'Total Number of Criteria',
      hint: 'Total number of success criteria defined'),
  Field('criticalCount', int, 'Critical Criteria Count',
      hint: 'Number of critical-priority criteria'),
  Field('highPriorityCount', int, 'High Priority Count',
      hint: 'Number of high-priority criteria'),
  Field('mediumPriorityCount', int, 'Medium Priority Count',
      hint: 'Number of medium-priority criteria'),
  Field('lowPriorityCount', int, 'Low Priority Count',
      hint: 'Number of low-priority criteria'),
  Field('businessCriteriaCount', int, 'Business Criteria Count',
      hint: 'Number of business-focused criteria'),
  Field('technicalCriteriaCount', int, 'Technical Criteria Count',
      hint: 'Number of technical-quality criteria'),
  Field('userCriteriaCount', int, 'User Satisfaction Criteria Count',
      hint: 'Number of user-satisfaction criteria'),
  Field('complianceCriteriaCount', int, 'Compliance Criteria Count',
      hint: 'Number of compliance-related criteria'),
  Field('minCriteriaMet', String, 'Minimum Criteria for Success',
      hint: 'All critical + X% of others'),
  Field('successThreshold', String, 'Overall Success Threshold',
      hint: 'Percentage or formula for determining success'),
])
@SectionId('SCS')
class SuccessCriteriaSummary {
  /// Summary content.
  @ContentType('aggregation', 'Summary statistics for success criteria.')
  @SerializationOrder(0)
  String? content;
}

/// Framework for evaluating and accepting success criteria.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — acceptance & verification criteria',
    'BABOK v3 — solution evaluation',
  ],
  'The acceptance and evaluation framework: how and when criteria are '
  'evaluated, who signs off, the evidence required, and how disputes and '
  'partial success are handled.',
)
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
@SectionId('SCF')
class SuccessCriteriaFramework {
  /// Framework content.
  @ContentType('form', 'Acceptance and evaluation framework details.')
  @SerializationOrder(0)
  String? content;
}

/// Success criteria organized by category.
@StandardReferences(
  ['BABOK v3 — solution evaluation (success measures)'],
  'Success criteria grouped by dimension — business, technical, user, '
  'compliance, and project — for a category-by-category view of success.',
)
@SectionId('SCBC')
class SuccessCriteriaByCategory {
  /// Business outcome criteria overview.
  @ContentType('description', 'Overview of business-focused success criteria '
      'including ROI, market impact, and strategic alignment.')
  @ContentHelp('Describe how business outcomes will be measured.')
  @SerializationOrder(0)
  String? businessCriteria;

  /// Technical quality criteria overview.
  @ContentType('description', 'Overview of technical quality criteria '
      'including performance, reliability, and maintainability.')
  @ContentHelp('Describe how technical quality will be measured.')
  @SerializationOrder(1)
  String? technicalCriteria;

  /// User satisfaction criteria overview.
  @ContentType('description', 'Overview of user-focused success criteria '
      'including adoption, satisfaction, and productivity.')
  @ContentHelp('Describe how user satisfaction will be measured.')
  @SerializationOrder(2)
  String? userCriteria;

  /// Compliance criteria overview.
  @ContentType('description', 'Overview of compliance-related success criteria '
      'including regulatory, security, and audit requirements.')
  @ContentHelp('Describe how compliance will be verified.')
  @SerializationOrder(3)
  String? complianceCriteria;

  /// Timeline and budget criteria overview.
  @ContentType('description', 'Overview of project management criteria '
      'including timeline adherence, budget compliance, and scope management.')
  @ContentHelp('Describe how project execution will be measured.')
  @SerializationOrder(4)
  String? projectCriteria;
}

/// A success criterion entry (form).
///
/// Individual success criterion with comprehensive measurement details,
/// thresholds, and verification requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — acceptance & verification criteria',
    'BABOK v3 — solution evaluation',
  ],
  'A single success criterion: its identity, metric and thresholds, '
  'verification, importance, relationships, and current status.',
)
@SectionId('SCE')
class SuccessCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID', required: true,
        hint: 'Unique identifier (e.g., SC-001)'),
    Field('criterionName', String, 'Criterion Name', required: true,
        hint: 'Short descriptive name'),
    Field('category', String, 'Category', required: true,
        hint: 'Business, Technical, User, Compliance, Budget, Timeline'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Identification details.
  @SerializationOrder(1)
  SuccessCriterionIdentity identity = SuccessCriterionIdentity();

  /// Measurement.
  @SerializationOrder(2)
  SuccessCriterionMeasurement measurement = SuccessCriterionMeasurement();

  /// Verification.
  @SerializationOrder(3)
  SuccessCriterionVerification verification =
      SuccessCriterionVerification();

  /// Importance.
  @SerializationOrder(4)
  SuccessCriterionImportance importance = SuccessCriterionImportance();

  /// Relationships.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
    'The list of relationship entries linking this criterion to goals, '
    'requirements, dependencies, and stakeholders.',
  )
  @SectionId('SUCRRE-RELA-LST')
  @SectionIdPattern('SUCRRE-RELA-xxx')
  @ContentHelp('Add relationship entries tracing this criterion to related '
      'goals, requirements, dependencies, and stakeholders.')
  @SerializationOrder(5)
  List<SuccessCriterionRelationships> relationships = [];

  /// Status.
  @SerializationOrder(6)
  SuccessCriterionStatus status = SuccessCriterionStatus();
}

/// Identity for success criterion.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — acceptance & verification criteria',
    'BABOK v3 — solution evaluation',
  ],
  'Identifying detail for the criterion: its description of what success means '
  'and its subcategory.',
)
@SectionId('SUCRID')
class SuccessCriterionIdentity {
  @Form([
    Field('description', String, 'Description',
        hint: 'Detailed description of what success means'),
    Field('subcategory', String, 'Subcategory',
        hint: 'More specific categorization'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Measurement for success criterion.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — verification criteria',
    'ISO/IEC 25023 — measurement',
  ],
  'How the criterion is measured: the metric, baseline, minimum threshold, '
  'target, stretch goal, and unit of measurement.',
)
@SectionId('SUCRME')
class SuccessCriterionMeasurement {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification for success criterion.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — verification criteria',
    'ISO/IEC 25023 — measurement',
  ],
  'How the criterion is verified: measurement method, data source, frequency, '
  'responsible party, verification point, and evidence type.',
)
@SectionId('SUCRVE')
class SuccessCriterionVerification {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Importance for success criterion.
@StandardReferences(
  ['BABOK v3 — solution evaluation (success measures)'],
  'The importance of the criterion: its weight, whether it is mandatory, and '
  'the consequence if it is not met.',
)
@SectionId('SUCRIM')
class SuccessCriterionImportance {
  @Form([
    Field('weight', String, 'Weight',
        hint: 'Importance: Critical, High, Medium, Low'),
    Field('isMandatory', String, 'Mandatory',
        hint: 'Yes/No - is this required for overall success'),
    Field('consequenceIfNotMet', String, 'Consequence If Not Met',
        hint: 'Impact if this criterion is not met'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Relationships for success criterion.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'A single relationship entry tracing this criterion to related goals, '
  'requirements, dependencies, and key stakeholders.',
)
@SectionId('SUCRRE')
class SuccessCriterionRelationships {
  @Form([
    Field('relatedGoals', String, 'Related Goals',
        hint: 'Which business/technical goals this supports'),
    Field('relatedRequirements', String, 'Related Requirements',
        hint: 'Requirement IDs that contribute to this criterion'),
    Field('dependencies', String, 'Dependencies',
        hint: 'Other criteria this depends on'),
    Field('stakeholders', String, 'Key Stakeholders',
        hint: 'Who cares most about this criterion'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Status for success criterion.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — verification criteria',
    'BABOK v3 — solution evaluation',
  ],
  'The current evaluation status of the criterion: status, current value, '
  'trend, evidence, and evaluation notes.',
)
@SectionId('SUCRST')
class SuccessCriterionStatus {
  @Form([
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
  @SerializationOrder(0)
  String? content;
}

/// Post-implementation review plan for success criteria.
@StandardReferences(
  ['BABOK v3 — solution evaluation (success measures)'],
  'The plan for reviewing success after implementation: review schedule and '
  'owner, participants, reporting, lessons learned, benefits-tracking '
  'duration, and corrective action.',
)
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
@SectionId('PIR')
class PostImplementationReview {
  /// Post-implementation review content.
  @ContentType('form', 'Post-implementation review planning.')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.3 Requirements Overview (seeds → RSP)
// ---------------------------------------------------------------------------

/// 4.3. Requirements Overview. Seeds → RSP.
///
/// Initial requirements overview organized by category. Each requirement
/// receives a unique ID and will be expanded into the RSP (Requirements
/// Specification) document with full traceability. This section provides the
/// foundation for requirements management throughout the project lifecycle.
/// Based on IEEE 830, ISO 29148, BABOK, and Volere requirements shell.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §8/§9 — requirements specification (SRS overview)',
    'BABOK v3 §7 — requirements analysis & design definition',
  ],
  'The root of §4.3: captures the initial requirements overview organized by '
  'category, with each requirement uniquely identified and traceable into the '
  'full RSP for management across the project lifecycle.',
)
@Comment('Seeds → RSP')
@MapsTo(D04RequirementsSpecification)
@ContentHelp('Define initial requirements at a level sufficient for project '
    'scoping and planning. Each requirement should be traceable to business '
    'goals and verifiable through acceptance criteria.')
@SectionId('RO')
class RequirementsOverview {
  @SerializationOrder(0)
  String? content;

  /// Requirements overview form.
  @Form([
    Field('requirementsProcess', String,
        'Requirements Process (how requirements are elicited and managed)',
        hint: 'How requirements are elicited, analysed, and managed'),
    Field('traceabilityApproach', String,
        'Traceability Approach (how requirements are linked to goals, tests, code)',
        hint: 'How requirements are linked to goals, tests, and code'),
    Field('changeControlProcess', String,
        'Change Control Process (how requirement changes are handled)',
        hint: 'How requirement changes are proposed, reviewed, and approved'),
    Field('prioritizationMethod', String,
        'Prioritization Method (MoSCoW, Weighted, etc.)',
        hint: 'MoSCoW, weighted scoring, or other prioritisation scheme'),
    Field('totalRequirements', String,
        'Total Requirements Expected (estimated count)',
        hint: 'Estimated total number of requirements'),
    Field('mustHaveCount', String, 'Must-Have Requirements (estimated)',
        hint: 'Estimated count of Must-Have requirements'),
    Field('shouldHaveCount', String, 'Should-Have Requirements (estimated)',
        hint: 'Estimated count of Should-Have requirements'),
    Field('couldHaveCount', String, 'Could-Have Requirements (estimated)',
        hint: 'Estimated count of Could-Have requirements'),
  ])
  @SerializationOrder(1)
  String? requirementsForm;

  /// Traceability matrix overview.
  @ContentType('description', 'Summary of traceability matrix showing '
      'connections between requirements, goals, use cases, and tests.')
  @ContentHelp('Provide a high-level view of requirement traceability.')
  @SerializationOrder(2)
  String? traceabilityMatrix;

  /// 4.3.1. Functional Requirements.
  @SerializationOrder(3)
  FunctionalRequirements functionalRequirements = FunctionalRequirements();

  /// 4.3.2. Technical Requirements.
  @SerializationOrder(4)
  TechnicalRequirements technicalRequirements = TechnicalRequirements();

  /// 4.3.3. Security Requirements.
  @SerializationOrder(5)
  SecurityRequirements securityRequirements = SecurityRequirements();

  /// 4.3.4. Organizational Requirements.
  @SerializationOrder(6)
  OrganizationalRequirements organizationalRequirements =
      OrganizationalRequirements();

  /// 4.3.5. Requirement Relationships.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §5.2 — requirement dependencies',
      'BABOK v3 §7 — requirements analysis & design definition',
    ],
    'The set of relationship entries linking requirements to one another — '
    'dependencies, conflicts, and refinements across the requirement set.',
  )
  @SectionId('RERE-REQU-LST')
  @SectionIdPattern('RERE-REQU-xxx')
  @ContentHelp('Add one entry per relationship between requirements, capturing '
      'the linked requirements and the nature of their relationship.')
  @SerializationOrder(7)
  List<RequirementRelationships> requirementRelationships = [];

  /// 4.3.6. Requirement Coverage.
  @SerializationOrder(8)
  RequirementCoverage requirementCoverage = RequirementCoverage();
}

// ---------------------------------------------------------------------------
// 4.3.1 Functional Requirements
// ---------------------------------------------------------------------------

/// 4.3.1. Functional Requirements.
///
/// Container for functional requirements. Functional requirements describe
/// what the system must do — its features, behaviors, processing rules,
/// and user interactions. Each requirement is uniquely identified and
/// traceable to business goals and use cases.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.5 — functional requirements',
    'BABOK v3 §10 — functional requirements',
  ],
  'The container for functional requirements — what the system must do, its '
  'features, behaviors, processing rules, and user interactions, each uniquely '
  'identified and traceable to goals and use cases.',
)
@DetailedIn(D04RequirementsSpecification)
@SecondLevelSectionId(D04RequirementsSpecification, 'RSP-FUN')
@ContentHelp('Functional requirements describe system capabilities, behaviors, '
    'and features. Use clear, testable language. Each requirement should '
    'answer: What must the system do? For whom? Under what conditions?')
@SectionId('FR')
class FunctionalRequirements {
  @SerializationOrder(0)
  String? content;

  /// Functional requirements summary form.
  @Form([
    Field('totalFunctionalRequirements', String,
        'Total Functional Requirements',
        hint: 'Total count of functional requirements'),
    Field('mustHaveFunctional', String, 'Must-Have (count)',
        hint: 'Count of Must-Have functional requirements'),
    Field('shouldHaveFunctional', String, 'Should-Have (count)',
        hint: 'Count of Should-Have functional requirements'),
    Field('couldHaveFunctional', String, 'Could-Have (count)',
        hint: 'Count of Could-Have functional requirements'),
    Field('wontHaveThisTimeFunctional', String, 'Won\'t-Have-This-Time (count)',
        hint: 'Count of Won\'t-Have-This-Time functional requirements'),
    Field('coverageNote', String, 'Coverage Notes',
        hint: 'Notes on coverage and any gaps in the requirement set'),
  ])
  @SerializationOrder(1)
  String? summaryForm;

  /// Functional requirements list — contains 1+× Functional Requirement.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.5 — functional requirements',
      'BABOK v3 §10 — functional requirements',
    ],
    'The list of individual functional requirement entries, each atomic, '
    'testable, and accompanied by clear acceptance criteria.',
  )
  @SectionId('FRE-REQU-LST')
  @SectionIdPattern('FRE-REQU-xxx')
  @Min(1)
  @ContentHelp('Add one entry per functional requirement. Group related '
      'requirements together. Each requirement should be atomic, testable, '
      'and have clear acceptance criteria.')
  @SerializationOrder(2)
  List<FunctionalRequirementEntry> requirements = [];
}

/// A functional requirement entry.
///
/// Comprehensive functional requirement definition following IEEE 830,
/// ISO 29148, and Volere requirements shell. Includes traceability,
/// acceptance criteria, UI specification, and business rules.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.5 — functional requirements',
    'BABOK v3 §10 — functional requirements',
  ],
  'A single functional requirement: its identity, definition, priority, source, '
  'verification, constraints, and the acceptance criteria, business rules, data, '
  'UI, dependencies, traceability, and test cases that elaborate it.',
)
@SectionId('FRE')
class FunctionalRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-F001)', required: true,
        hint: 'Unique requirement identifier, e.g. REQ-F001'),
    Field('title', String, 'Title (concise statement)', required: true,
        hint: 'Concise one-line statement of the requirement'),
    Field('status', String,
        'Status (Draft, Proposed, Approved, Implemented, Verified, Deferred)',
        required: true,
        hint: 'Draft, Proposed, Approved, Implemented, Verified, or Deferred'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Requirement details: description, type, category.
  @SerializationOrder(1)
  FunctionalRequirementEntryDetails details =
      FunctionalRequirementEntryDetails();

  /// Priority and effort assessment.
  @SerializationOrder(2)
  FunctionalRequirementEntryPriority priority =
      FunctionalRequirementEntryPriority();

  /// Source and rationale.
  @SerializationOrder(3)
  FunctionalRequirementEntrySource source = FunctionalRequirementEntrySource();

  /// Verification criteria.
  @SerializationOrder(4)
  FunctionalRequirementEntryVerification verification =
      FunctionalRequirementEntryVerification();

  /// Assumptions and constraints.
  @SerializationOrder(5)
  FunctionalRequirementEntryConstraints constraints =
      FunctionalRequirementEntryConstraints();

  /// Version metadata.
  @SerializationOrder(6)
  FunctionalRequirementEntryMetadata metadata =
      FunctionalRequirementEntryMetadata();

  /// 4.3.1.n.1. Acceptance Criteria.
  @SerializationOrder(7)
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.1.n.2. Business Rules.
  @SerializationOrder(8)
  RequirementBusinessRules businessRules = RequirementBusinessRules();

  /// 4.3.1.n.3. Data Requirements.
  @SerializationOrder(9)
  RequirementDataRequirements dataRequirements = RequirementDataRequirements();

  /// 4.3.1.n.4. UI Specification.
  @SerializationOrder(10)
  RequirementUiSpecification uiSpecification = RequirementUiSpecification();

  /// 4.3.1.n.5. Dependencies.
  @SerializationOrder(11)
  RequirementDependencies dependencies = RequirementDependencies();

  /// 4.3.1.n.6. Traceability.
  @SerializationOrder(12)
  RequirementTraceability traceability = RequirementTraceability();

  /// 4.3.1.n.7. Test Cases.
  @SerializationOrder(13)
  RequirementTestCases testCases = RequirementTestCases();
}

/// Requirement details: description, type, category.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.5 — functional requirements',
    'BABOK v3 §10 — functional requirements',
  ],
  'The core definition of a functional requirement — its detailed "the system '
  'shall" statement, its type, and its functional-area category.',
)
@SectionId('FRED')
class FunctionalRequirementEntryDetails {
  @Form([
    Field('description', String,
        'Description (The system shall... detailed statement)', required: true,
        hint: 'Detailed "the system shall..." statement of the requirement'),
    Field('requirementType', String,
        'Requirement Type (Feature, User Story, Business Rule, Report, '
            'Integration, Calculation, Workflow, Notification, Search, '
            'Data Entry, Data Display, Data Export, Batch Process)',
        hint: 'Feature, User Story, Business Rule, Report, Integration, etc.'),
    Field('category', String,
        'Category (functional area grouping)',
        hint: 'Functional-area grouping for this requirement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Priority and effort assessment.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §5.2 — requirement prioritization',
    'MoSCoW — prioritization',
  ],
  'The priority, business value, effort, and risk assessment for a functional '
  'requirement — how it is ranked and what it costs and risks.',
)
@SectionId('FREP')
class FunctionalRequirementEntryPriority {
  @Form([
    Field('priority', String,
        'Priority (Must, Should, Could, Won\'t-This-Time)', required: true,
        hint: 'MoSCoW priority: Must, Should, Could, or Won\'t-This-Time'),
    Field('businessValue', String,
        'Business Value (High, Medium, Low) - benefit to business',
        hint: 'High / Medium / Low benefit to the business'),
    Field('effort', String,
        'Estimated Effort (Small, Medium, Large, XLarge)',
        hint: 'Estimated effort: Small, Medium, Large, or XLarge'),
    Field('riskLevel', String,
        'Risk Level (High, Medium, Low) - risk of not meeting',
        hint: 'High / Medium / Low risk of not meeting the requirement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Source and rationale for requirement.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'The provenance of a functional requirement — who requested it, when, and the '
  'rationale that justifies it, anchoring traceability back to its origin.',
)
@SectionId('FRES')
class FunctionalRequirementEntrySource {
  @Form([
    Field('source', String,
        'Source (who requested: stakeholder name, workshop, document)',
        required: true,
        hint: 'Who requested it: stakeholder name, workshop, or document'),
    Field('requestDate', String, 'Request Date',
        hint: 'Date the requirement was requested'),
    Field('rationale', String,
        'Rationale (why this requirement is needed)',
        hint: 'Why this requirement is needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification criteria for requirement.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6.5 — verification',
    'ISO/IEC/IEEE 29119 — testing',
  ],
  'How a functional requirement is verified — its measurable fit criterion and '
  'the customer satisfaction/dissatisfaction it drives.',
)
@SectionId('FREV')
class FunctionalRequirementEntryVerification {
  @Form([
    Field('fitCriterion', String,
        'Fit Criterion (measurable condition for acceptance)',
        hint: 'Measurable condition that must hold for acceptance'),
    Field('customerSatisfaction', String,
        'Customer Satisfaction (1-5 scale if delivered)',
        hint: '1-5 scale of satisfaction if the requirement is delivered'),
    Field('customerDissatisfaction', String,
        'Customer Dissatisfaction (1-5 scale if NOT delivered)',
        hint: '1-5 scale of dissatisfaction if it is NOT delivered'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Assumptions and constraints for requirement.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §9.5 — functional requirements'],
  'The assumptions a functional requirement relies on, the constraints it must '
  'respect, and the other requirements it conflicts with.',
)
@SectionId('FREC')
class FunctionalRequirementEntryConstraints {
  @Form([
    Field('assumptions', String,
        'Assumptions (conditions assumed to be true)',
        hint: 'Conditions assumed to be true for this requirement'),
    Field('constraints', String,
        'Constraints (limitations on implementation)',
        hint: 'Limitations on how the requirement may be implemented'),
    Field('conflictsWith', String,
        'Conflicts With (IDs of conflicting requirements)',
        hint: 'IDs of requirements this one conflicts with'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Version metadata for requirement.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'The version-control metadata for a functional requirement — its version, '
  'last-modified date, and last editor, supporting change traceability.',
)
@SectionId('FREM')
class FunctionalRequirementEntryMetadata {
  @Form([
    Field('version', String, 'Version',
        hint: 'Version number of this requirement'),
    Field('lastModified', String, 'Last Modified Date',
        hint: 'Date the requirement was last modified'),
    Field('modifiedBy', String, 'Modified By',
        hint: 'Who last modified the requirement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.3.1.n.1. Acceptance Criteria.
///
/// Testable conditions that must be met for the requirement to be accepted.
/// Uses Given-When-Then format for clarity.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — acceptance criteria',
    'Agile — acceptance criteria',
  ],
  'The testable conditions, in Given-When-Then form, that must be met for a '
  'functional requirement to be accepted.',
)
@ContentHelp('Define clear, testable acceptance criteria. Use Given-When-Then '
    'format: Given [context], When [action], Then [expected result].')
@SectionId('RAC')
class RequirementAcceptanceCriteria {
  @ContentType('description', 'Overview of acceptance approach and '
      'test coverage expectations.')
  @SerializationOrder(0)
  String? content;

  /// Acceptance criterion entries — contains 0+× AcceptanceCriterionEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — acceptance criteria',
      'Agile — acceptance criteria',
    ],
    'The list of individual acceptance-criterion entries, one per testable '
    'condition for the requirement.',
  )
  @SectionId('ACCR-CRIT-LST')
  @SectionIdPattern('ACCR-CRIT-xxx')
  @ContentHelp('Add one criterion per testable condition.')
  @SerializationOrder(1)
  List<AcceptanceCriterionEntry> criteria = [];
}

/// An acceptance criterion entry (form).
///
/// Uses Given-When-Then format (Gherkin style) for testable criteria.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — acceptance criteria',
    'Agile — acceptance criteria',
  ],
  'A single acceptance criterion in Given-When-Then form, with its verification '
  'method, test type, priority, and status.',
)
@SectionId('ACE')
class AcceptanceCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID', required: true,
        hint: 'Unique identifier for this criterion'),
    Field('criterionTitle', String, 'Criterion Title', required: true,
        hint: 'Short title describing the criterion'),
    Field('given', String, 'Given (precondition/context)',
        hint: 'Precondition or context that holds before the action'),
    Field('when', String, 'When (action/trigger)',
        hint: 'Action or trigger that occurs'),
    Field('then', String, 'Then (expected outcome)', required: true,
        hint: 'Expected outcome after the action'),
    Field('and', String, 'And (additional outcomes)',
        hint: 'Any additional expected outcomes'),
    Field('verificationMethod', String,
        'Verification Method (Manual, Automated, Inspection, Demo)',
        hint: 'Manual, Automated, Inspection, or Demo'),
    Field('testType', String,
        'Test Type (Unit, Integration, System, Acceptance, UAT)',
        hint: 'Unit, Integration, System, Acceptance, or UAT'),
    Field('priority', String, 'Priority (Critical, High, Medium, Low)',
        hint: 'Critical, High, Medium, or Low'),
    Field('status', String, 'Status (Draft, Ready, Passed, Failed, Blocked)',
        hint: 'Draft, Ready, Passed, Failed, or Blocked'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.3.1.n.2. Business Rules.
///
/// Business rules that constrain or guide this requirement's behavior.
@StandardReferences(
  [
    'BABOK v3 §10.9 — business rules analysis',
    'ISO/IEC/IEEE 29148 §9 — business rules',
  ],
  'The business rules — constraints, calculations, and policies from the '
  'business domain — that constrain or guide this requirement\'s behavior.',
)
@ContentHelp('Define business rules that affect this requirement. Business '
    'rules are constraints, calculations, or policies from the business domain.')
@SectionId('RBR')
class RequirementBusinessRules {
  @ContentType('description', 'Overview of business rules associated '
      'with this requirement.')
  @SerializationOrder(0)
  String? content;

    /// Business rule entries — contains 0+× RequirementBusinessRuleEntry.
  @StandardReferences(
    [
      'BABOK v3 §10.9 — business rules analysis',
      'ISO/IEC/IEEE 29148 §9 — business rules',
    ],
    'The list of individual business-rule entries applying to this requirement.',
  )
  @SectionId('RQBIRU-RULE-LST')
  @SectionIdPattern('RQBIRU-RULE-xxx')
  @ContentHelp('Add one entry per business rule that constrains or guides this '
      'requirement.')
    @SerializationOrder(1)
    List<RequirementBusinessRuleEntry> rules = [];
}

/// A business rule entry (form).
@StandardReferences(
  [
    'BABOK v3 §10.9 — business rules analysis',
    'ISO/IEC/IEEE 29148 §9 — business rules',
  ],
  'A single business rule: its identity, type, statement, source, validity '
  'period, exceptions, enforcement strength, and violation impact.',
)
@SectionId('RQBIRU')
class RequirementBusinessRuleEntry {
  @Form([
    Field('ruleId', String, 'Rule ID', required: true,
        hint: 'Unique identifier for this business rule'),
    Field('ruleName', String, 'Rule Name', required: true,
        hint: 'Short descriptive name for the rule'),
    Field('ruleType', String,
        'Rule Type (Constraint, Computation, Derivation, Inference, '
            'Condition, Action, Workflow, Authorization)',
        hint: 'Constraint, Computation, Derivation, Inference, Condition, etc.'),
    Field('ruleStatement', String,
        'Rule Statement (IF/WHEN condition THEN action)', required: true,
        hint: 'IF/WHEN condition THEN action statement'),
    Field('source', String, 'Source (policy, regulation, expert)',
        hint: 'Origin of the rule: policy, regulation, or expert'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'Date the rule takes effect'),
    Field('expirationDate', String, 'Expiration Date',
        hint: 'Date the rule expires, if any'),
    Field('exceptions', String, 'Exceptions (when rule does not apply)',
        hint: 'Cases in which the rule does not apply'),
    Field('enforcement', String,
        'Enforcement (Hard = system enforces, Soft = warning only)',
        hint: 'Hard (system enforces) or Soft (warning only)'),
    Field('impact', String, 'Impact (what happens if rule is violated)',
        hint: 'What happens if the rule is violated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.3.1.n.3. Data Requirements.
///
/// Data entities, attributes, and relationships needed by this requirement.
@StandardReferences(
  [
    'BABOK v3 §10.18 — data modelling',
    'ISO/IEC/IEEE 29148 §9 — data requirements',
  ],
  'The data entities, attributes, and relationships a requirement reads, '
  'creates, updates, or deletes.',
)
@ContentHelp('Define the data entities and attributes this requirement '
    'reads, creates, updates, or deletes.')
@SectionId('RDR')
class RequirementDataRequirements {
  @ContentType('description', 'Overview of data requirements and '
      'CRUD (Create, Read, Update, Delete) operations.')
  @SerializationOrder(0)
  String? content;

  /// Data entity entries — contains 0+× DataEntityReferenceEntry.
  @StandardReferences(
    [
      'BABOK v3 §10.18 — data modelling',
      'ISO/IEC/IEEE 29148 §9 — data requirements',
    ],
    'The list of individual data-entity references used by this requirement.',
  )
  @SectionId('DAENRE-ENTI-LST')
  @SectionIdPattern('DAENRE-ENTI-xxx')
  @ContentHelp('Add one entry per data entity this requirement reads, creates, '
      'updates, or deletes.')
  @SerializationOrder(1)
  List<DataEntityReferenceEntry> entities = [];
}

/// A reference to a data entity (form).
@StandardReferences(
  [
    'BABOK v3 §10.18 — data modelling',
    'ISO/IEC/IEEE 29148 §9 — data requirements',
  ],
  'A single data-entity reference: the entity, the CRUD operations performed on '
  'it, the attributes involved, volume, quality rules, and data owner.',
)
@SectionId('DAENRE')
class DataEntityReferenceEntry {
  @Form([
    Field('entityName', String, 'Entity Name', required: true,
        hint: 'Name of the data entity referenced'),
    Field('crudOperations', String,
        'CRUD Operations (Create, Read, Update, Delete)', required: true,
        hint: 'Which of Create, Read, Update, Delete are performed'),
    Field('attributes', String,
        'Attributes (specific fields involved)',
        hint: 'Specific fields/attributes involved'),
    Field('volumeEstimate', String,
        'Volume Estimate (records created/accessed)',
        hint: 'Estimated number of records created or accessed'),
    Field('dataQualityRules', String,
        'Data Quality Rules (validation, completeness)',
        hint: 'Validation and completeness rules for the data'),
    Field('dataOwner', String, 'Data Owner',
        hint: 'Owner accountable for this data entity'),
  ])
  @SerializationOrder(0)
  String? content;

  @Reference('Related Data Model Entity')
  @SerializationOrder(1)
  String? relatedEntity;
}

/// 4.3.1.n.4. UI Specification.
///
/// User interface specification for this requirement. Defines screens,
/// forms, and interactions needed to fulfill the requirement.
/// Uses Flutter/Tom UI framework concepts for specification.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'The user-interface specification for a requirement — the screens, forms, '
  'fields, actions, and behaviors needed to fulfil it.',
)
@ContentHelp('Define the UI elements needed to support this requirement. '
    'Specify screens, forms, fields, actions, and behaviors.')
@SectionId('RUS')
class RequirementUiSpecification {
  @SerializationOrder(0)
  String? content;

  /// UI specification form.
  @Form([
    Field('screenName', String, 'Screen/View Name',
        hint: 'Name of the screen or view'),
    Field('screenType', String,
        'Screen Type (List, Detail, Form, Dashboard, Dialog, Wizard)',
        hint: 'List, Detail, Form, Dashboard, Dialog, or Wizard'),
    Field('navigationPath', String, 'Navigation Path (how user reaches this)',
        hint: 'How the user navigates to reach this screen'),
    Field('userRoles', String, 'Allowed User Roles',
        hint: 'Roles allowed to access this screen'),
    Field('responsiveBreakpoints', String,
        'Responsive Breakpoints (mobile, tablet, desktop)',
        hint: 'Responsive breakpoints: mobile, tablet, desktop'),
  ])
  @SerializationOrder(1)
  String? uiForm;

  /// UI layout specification (D4rt Flutter code).
  @ContentType('code-dart', 'Flutter/D4rt code specifying the UI layout '
      'using tom_flutter_ui components.')
  @ContentHelp('Provide D4rt Flutter code for the UI layout, using '
      'tom_flutter_ui components. This can be rendered in documentation.')
  @SerializationOrder(2)
  String? layoutCode;

  /// UI mockup diagram (fallback if code not available).
  @ContentType('description', 'ASCII or text description of UI mockup '
      'if D4rt code is not available.')
  @SerializationOrder(3)
  String? mockupDescription;

  /// Screen field entries — contains 0+× ScreenFieldEntry.
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'The list of individual screen-field entries that make up this UI.',
  )
  @SectionId('SCFLD-FIEL-LST')
  @SectionIdPattern('SCFLD-FIEL-xxx')
  @ContentHelp('Define each field in the UI.')
  @SerializationOrder(4)
  List<ScreenFieldEntry> fields = [];

    /// Screen action entries — contains 0+× RequirementScreenActionEntry.
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'The list of individual screen-action entries available in this UI.',
  )
  @SectionId('RQSCAC-ACTI-LST')
  @SectionIdPattern('RQSCAC-ACTI-xxx')
  @ContentHelp('Define actions available in the UI.')
    @SerializationOrder(5)
    List<RequirementScreenActionEntry> actions = [];

  /// Screen behavior entries — contains 0+× ScreenBehaviorEntry.
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'The list of individual screen-behavior entries — dynamic behaviors and '
    'interactions of this UI.',
  )
  @SectionId('SCBHV-BEHA-LST')
  @SectionIdPattern('SCBHV-BEHA-xxx')
  @ContentHelp('Define dynamic behaviors and interactions.')
  @SerializationOrder(6)
  List<ScreenBehaviorEntry> behaviors = [];
}

/// A screen field entry (form).
///
/// Defines a field in the user interface with all its properties.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'A single UI field — its identity, label, type, and the data binding, '
  'conditions, validation, layout, and validation rules that govern it.',
)
@SectionId('SFE')
class ScreenFieldEntry {
  @Form([
    Field('fieldId', String, 'Field ID', required: true,
        hint: 'Unique identifier for this field'),
    Field('fieldLabel', String, 'Field Label (display text)', required: true,
        hint: 'Display text shown for the field'),
    Field('fieldType', String, 'Field Type', required: true,
        hint: 'Text, Number, Date, Dropdown, Checkbox, etc.'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data binding and defaults.
  @SerializationOrder(1)
  ScreenFieldDataBinding dataBinding = ScreenFieldDataBinding();

  /// Conditional behavior.
  @SerializationOrder(2)
  ScreenFieldConditions conditions = ScreenFieldConditions();

  /// Validation rules.
  @SerializationOrder(3)
  ScreenFieldValidation validation = ScreenFieldValidation();

  /// UI and layout.
  @SerializationOrder(4)
  ScreenFieldLayout layout = ScreenFieldLayout();

  /// Field validation rules — contains 0+× FieldValidationRule.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — input validation requirements',
      'OWASP ASVS — input validation',
    ],
    'The list of individual validation rules applied to this field\'s input.',
  )
  @SectionId('FLDVL-VALI-LST')
  @SectionIdPattern('FLDVL-VALI-xxx')
  @ContentHelp('Add one entry per validation rule applied to this field.')
  @SerializationOrder(5)
  List<FieldValidationRule> validationRules = [];
}

/// Data binding and defaults.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'How a screen field binds to data — its entity.attribute binding, default '
  'value, placeholder, and help text.',
)
@SectionId('SFDB')
class ScreenFieldDataBinding {
  @Form([
    Field('dataBinding', String, 'Data Binding (entity.attribute)',
        hint: 'Entity.attribute the field binds to'),
    Field('defaultValue', String, 'Default Value',
        hint: 'Default value for the field'),
    Field('placeholder', String, 'Placeholder Text',
        hint: 'Placeholder text shown when empty'),
    Field('helpText', String, 'Help Text / Tooltip',
        hint: 'Help text or tooltip for the field'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Conditional behavior.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'The conditional behavior of a screen field — when it is required, read-only, '
  'or visible, and the conditions that govern each.',
)
@SectionId('SCFICO')
class ScreenFieldConditions {
  @Form([
    Field('required', String, 'Required (Yes, No, Conditional)',
        hint: 'Yes, No, or Conditional'),
    Field('requiredCondition', String, 'Required Condition',
        hint: 'Condition under which the field is required'),
    Field('readOnly', String, 'Read Only (Yes, No, Conditional)',
        hint: 'Yes, No, or Conditional'),
    Field('readOnlyCondition', String, 'Read Only Condition',
        hint: 'Condition under which the field is read-only'),
    Field('visible', String, 'Visible (Yes, No, Conditional)',
        hint: 'Yes, No, or Conditional'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'Condition under which the field is visible'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Validation rules.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — input validation requirements',
    'OWASP ASVS — input validation',
  ],
  'The built-in validation constraints on a screen field — length and value '
  'bounds, regex pattern, and the custom validation message.',
)
@SectionId('SCFIVA')
class ScreenFieldValidation {
  @Form([
    Field('minLength', String, 'Minimum Length',
        hint: 'Minimum allowed input length'),
    Field('maxLength', String, 'Maximum Length',
        hint: 'Maximum allowed input length'),
    Field('minValue', String, 'Minimum Value',
        hint: 'Minimum allowed value'),
    Field('maxValue', String, 'Maximum Value',
        hint: 'Maximum allowed value'),
    Field('pattern', String, 'Validation Pattern (regex)',
        hint: 'Regular expression the input must match'),
    Field('validationMessage', String, 'Custom Validation Message',
        hint: 'Message shown when validation fails'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// UI and layout.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'The layout and presentation of a screen field — its dropdown source/values, '
  'dependencies, width, display order, and grouping.',
)
@SectionId('SCFILA')
class ScreenFieldLayout {
  @Form([
    Field('dropdownSource', String, 'Dropdown Source (static, API, entity)',
        hint: 'Where dropdown options come from: static, API, or entity'),
    Field('dropdownValues', String, 'Static Dropdown Values',
        hint: 'Static list of dropdown values'),
    Field('dependsOn', String, 'Depends On (field IDs that affect this)',
        hint: 'Field IDs that affect this field'),
    Field('width', String, 'Width (full, half, third, quarter, custom)',
        hint: 'full, half, third, quarter, or custom'),
    Field('order', String, 'Display Order',
        hint: 'Order in which the field is displayed'),
    Field('grouping', String, 'Field Grouping / Section',
        hint: 'Group or section the field belongs to'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A field validation rule (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9 — input validation requirements',
    'OWASP ASVS — input validation',
  ],
  'A single field validation rule: its type, expression, error message, '
  'severity, and the event that triggers it.',
)
@SectionId('FLDVL')
class FieldValidationRule {
  @Form([
    Field('ruleType', String,
        'Rule Type (Required, Pattern, Range, Length, Custom, CrossField)',
        required: true,
        hint: 'Required, Pattern, Range, Length, Custom, or CrossField'),
    Field('ruleExpression', String, 'Rule Expression / Formula',
        hint: 'Expression or formula implementing the rule'),
    Field('errorMessage', String, 'Error Message', required: true,
        hint: 'Message shown when the rule fails'),
    Field('severity', String, 'Severity (Error, Warning, Info)',
        hint: 'Error, Warning, or Info'),
    Field('triggerEvent', String,
        'Trigger Event (OnBlur, OnChange, OnSubmit)',
        hint: 'OnBlur, OnChange, or OnSubmit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A screen action entry (form).
///
/// Defines an action (button, link, menu item) in the user interface.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'A single UI action (button, link, menu item) — its identity, type, '
  'presentation, enablement, visibility, confirmation, messaging, target, '
  'permission, and audit behavior, plus its parameters.',
)
@SectionId('RQSCAC')
class RequirementScreenActionEntry {
  @Form([
    Field('actionId', String, 'Action ID', required: true,
        hint: 'Unique identifier for this action'),
    Field('actionLabel', String, 'Action Label (button text)', required: true,
        hint: 'Button or link text for the action'),
    Field('actionType', String,
        'Action Type (Submit, Cancel, Navigate, API Call, Dialog, '
            'Download, Print, Delete, Duplicate, Export, Import, Refresh, '
            'Save, SaveAndNew, SaveAndClose, Custom)',
        required: true,
        hint: 'Submit, Cancel, Navigate, API Call, Dialog, Save, etc.'),
    Field('icon', String, 'Icon (Material Icon name or custom)',
        hint: 'Material Icon name or custom icon'),
    Field('iconPosition', String, 'Icon Position (Left, Right, Only)',
        hint: 'Left, Right, or Only'),
    Field('buttonStyle', String,
        'Button Style (Primary, Secondary, Text, Outlined, Danger)',
        hint: 'Primary, Secondary, Text, Outlined, or Danger'),
    Field('placement', String,
        'Placement (Toolbar, Inline, Footer, ContextMenu, FAB)',
        hint: 'Toolbar, Inline, Footer, ContextMenu, or FAB'),
    Field('keyboardShortcut', String, 'Keyboard Shortcut',
        hint: 'Keyboard shortcut that triggers the action'),
    Field('enabled', String, 'Enabled (Yes, No, Conditional)',
        hint: 'Yes, No, or Conditional'),
    Field('enabledCondition', String, 'Enabled Condition',
        hint: 'Condition under which the action is enabled'),
    Field('visible', String, 'Visible (Yes, No, Conditional)',
        hint: 'Yes, No, or Conditional'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'Condition under which the action is visible'),
    Field('confirmationRequired', String, 'Confirmation Required (Yes, No)',
        hint: 'Whether the action requires confirmation'),
    Field('confirmationMessage', String, 'Confirmation Message',
        hint: 'Message shown to confirm the action'),
    Field('successMessage', String, 'Success Message',
        hint: 'Message shown on success'),
    Field('errorMessage', String, 'Error Message',
        hint: 'Message shown on error'),
    Field('navigationTarget', String, 'Navigation Target (if Navigate)',
        hint: 'Destination when the action navigates'),
    Field('apiEndpoint', String, 'API Endpoint (if API Call)',
        hint: 'API endpoint called by the action'),
    Field('requiredPermission', String, 'Required Permission',
        hint: 'Permission required to invoke the action'),
    Field('auditLogging', String, 'Audit Logging (Yes, No)',
        hint: 'Whether the action is audit-logged'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Action parameters — contains 0+× ActionParameterEntry.
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'The list of individual parameters passed to this action.',
  )
  @SectionId('ACPR-PARA-LST')
  @SectionIdPattern('ACPR-PARA-xxx')
  @ContentHelp('Add one entry per parameter passed to this action.')
  @SerializationOrder(1)
  List<ActionParameterEntry> parameters = [];
}

/// An action parameter entry (form).
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'A single action parameter — its name, where its value comes from, the source '
  'value, and whether it is required.',
)
@SectionId('ACPR')
class ActionParameterEntry {
  @Form([
    Field('parameterName', String, 'Parameter Name', required: true,
        hint: 'Name of the parameter'),
    Field('sourceType', String,
        'Source Type (Field, Constant, Context, User)', required: true,
        hint: 'Field, Constant, Context, or User'),
    Field('sourceValue', String, 'Source Value / Field ID',
        hint: 'Source value or field ID supplying the parameter'),
    Field('required', String, 'Required (Yes, No)',
        hint: 'Whether the parameter is required'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A screen behavior entry (form).
///
/// Defines dynamic behavior such as conditional visibility, calculations,
/// cascading selects, and other interactions.
@StandardReferences(
  [
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ],
  'A single dynamic screen behavior — conditional visibility, calculations, '
  'cascading selects, and similar interactions — with its trigger, condition, '
  'affected fields, and action.',
)
@SectionId('SCBHV')
class ScreenBehaviorEntry {
  @Form([
    Field('behaviorId', String, 'Behavior ID', required: true,
        hint: 'Unique identifier for this behavior'),
    Field('behaviorName', String, 'Behavior Name', required: true,
        hint: 'Short descriptive name for the behavior'),
    Field('behaviorType', String,
        'Behavior Type (ConditionalVisibility, ConditionalRequired, '
            'Calculation, CascadingSelect, AutoPopulate, CrossFieldValidation, '
            'DynamicDefault, FieldFormatting, LiveSearch, InlineEdit)',
        required: true,
        hint: 'ConditionalVisibility, Calculation, CascadingSelect, etc.'),
    Field('triggerEvent', String,
        'Trigger Event (OnLoad, OnChange, OnBlur, OnFocus, OnClick, '
            'OnSubmit, OnFieldChange)',
        hint: 'OnLoad, OnChange, OnBlur, OnFocus, OnClick, OnSubmit, etc.'),
    Field('triggerField', String, 'Trigger Field (if field-specific)',
        hint: 'Field that triggers the behavior, if field-specific'),
    Field('condition', String, 'Condition (when behavior applies)',
        hint: 'Condition under which the behavior applies'),
    Field('affectedFields', String, 'Affected Fields (field IDs)',
        hint: 'Field IDs affected by the behavior'),
    Field('action', String,
        'Action (Show, Hide, Enable, Disable, Calculate, Populate, Validate)',
        hint: 'Show, Hide, Enable, Disable, Calculate, Populate, or Validate'),
    Field('formula', String, 'Formula / Expression (for calculations)',
        hint: 'Formula or expression used for calculations'),
    Field('description', String, 'Behavior Description',
        hint: 'Description of what the behavior does'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.3.1.n.5. Dependencies.
///
/// Dependencies this requirement has on other requirements.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2 — requirement dependencies'],
  'The dependencies this requirement has on other requirements — what must be '
  'implemented before or alongside it, and the implementation order.',
)
@ContentHelp('Identify requirements that must be implemented before or '
    'alongside this requirement.')
@SectionId('REQDEP')
class RequirementDependencies {
  @ContentType('description', 'Overview of requirement dependencies '
      'and implementation order.')
  @SerializationOrder(0)
  String? content;

  /// Dependency entries — contains 0+× RequirementDependencyEntry.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §5.2 — requirement dependencies'],
    'The list of individual dependency entries linking this requirement to '
    'others.',
  )
  @SectionId('RQDEP-ITEM-LST')
  @SectionIdPattern('RQDEP-ITEM-xxx')
  @ContentHelp('Add one entry per dependency on another requirement.')
  @SerializationOrder(1)
  List<RequirementDependencyEntry> items = [];
}

/// A requirement dependency entry (form).
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2 — requirement dependencies'],
  'A single dependency on another requirement — its type, a description, and '
  'the impact of the dependency not being met.',
)
@SectionId('RQDEP')
class RequirementDependencyEntry {
  @Form([
    Field('dependencyType', String,
        'Dependency Type (Prerequisite, Bidirectional, Parent-Child, '
            'Conflict, Refinement)', required: true,
        hint: 'Prerequisite, Bidirectional, Parent-Child, Conflict, or '
            'Refinement'),
    Field('description', String, 'Description',
        hint: 'Description of the dependency'),
    Field('impact', String, 'Impact (what happens if dependency not met)',
        hint: 'What happens if the dependency is not met'),
  ])
  @SerializationOrder(0)
  String? content;

  @Reference('Related Requirement')
  @SerializationOrder(1)
  String? relatedRequirement;
}

/// 4.3.1.n.6. Traceability.
///
/// Traceability links to goals, use cases, processes, and other artifacts.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'The traceability links of a requirement to goals, use cases, processes, '
  'stories, and other artifacts that maintain visibility across the lifecycle.',
)
@ContentHelp('Document traceability links to maintain visibility of '
    'requirements throughout the project lifecycle.')
@SectionId('RT')
class RequirementTraceability {
  @SerializationOrder(0)
  String? content;

  /// Traceability links form.
  @Form([
    Field('relatedGoals', String, 'Related Business Goals (IDs)',
        hint: 'IDs of related business goals'),
    Field('relatedUseCases', String, 'Related Use Cases (IDs)',
        hint: 'IDs of related use cases'),
    Field('relatedProcesses', String, 'Related Business Processes (IDs)',
        hint: 'IDs of related business processes'),
    Field('relatedUserStories', String, 'Related User Stories (if Agile)',
        hint: 'Related user stories, if using Agile'),
  ])
  @SerializationOrder(1)
  String? traceabilityForm;

    /// Linked artifacts and test coverage references.
    @SerializationOrder(2)
    RequirementTraceabilityArtifacts artifacts =
            RequirementTraceabilityArtifacts();

    /// Implementation and deployment tracking.
    @SerializationOrder(3)
    RequirementTraceabilityImplementation implementation =
            RequirementTraceabilityImplementation();
}

/// Linked artifacts and test coverage references.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'The artifacts a requirement is linked to — UI screens, data entities, test '
  'cases, and related documents — for coverage and traceability.',
)
@SectionId('RETRAR')
class RequirementTraceabilityArtifacts {
    @Form([
        Field('relatedScreens', String, 'Related UI Screens/Views',
            hint: 'UI screens or views related to this requirement'),
        Field('relatedDataEntities', String, 'Related Data Entities',
            hint: 'Data entities related to this requirement'),
        Field('relatedTestCases', String, 'Related Test Cases (IDs)',
            hint: 'IDs of test cases covering this requirement'),
        Field('relatedDocuments', String, 'Related Documents or Artifacts',
            hint: 'Related documents or other artifacts'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Implementation and deployment tracking.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'How a requirement is realised — the implementing component, its '
  'implementation status, and the deployment version that first delivers it.',
)
@SectionId('RETRIM')
class RequirementTraceabilityImplementation {
    @Form([
        Field('implementationComponent', String,
                'Implementation Component (module, service)',
            hint: 'Module or service that implements the requirement'),
        Field('implementationStatus', String,
                'Implementation Status (Not Started, In Progress, Done)',
            hint: 'Not Started, In Progress, or Done'),
        Field('deploymentVersion', String, 'Deployment Version (first release)',
            hint: 'Version in which the requirement first ships'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 4.3.1.n.7. Test Cases.
///
/// Test cases that verify this requirement is correctly implemented.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'ISO/IEC/IEEE 29148 §6.5 — verification',
  ],
  'The test cases that verify a requirement is correctly implemented — the test '
  'coverage that confirms its acceptance criteria are met.',
)
@SectionId('RETECA')
@ContentHelp('Define test cases that verify requirement implementation.')
class RequirementTestCases {
  @ContentType('description', 'Overview of test coverage for this requirement.')
  @SerializationOrder(0)
  String? content;

  /// Test case entries — contains 0+× RequirementTestCaseEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing',
      'ISO/IEC/IEEE 29148 §6.5 — verification',
    ],
    'The list of individual test-case entries verifying this requirement.',
  )
  @SectionId('RQTSC-TEST-LST')
  @SectionIdPattern('RQTSC-TEST-xxx')
  @ContentHelp('Add one entry per test case that verifies this requirement.')
  @SerializationOrder(1)
  List<RequirementTestCaseEntry> testCases = [];
}

/// A test case entry for requirement verification (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'ISO/IEC/IEEE 29148 §6.5 — verification',
  ],
  'A single test case verifying a requirement — its identity, type, category, '
  'preconditions, plus its execution and automation details.',
)
@SectionId('RQTSC')
class RequirementTestCaseEntry {
  @Form([
    Field('testCaseId', String, 'Test Case ID', required: true,
        hint: 'Unique identifier for the test case'),
    Field('testCaseName', String, 'Test Case Name', required: true,
        hint: 'Short descriptive name for the test case'),
    Field('testType', String,
        'Test Type (Unit, Integration, System, Acceptance, UAT, Regression)',
        hint: 'Unit, Integration, System, Acceptance, UAT, or Regression'),
    Field('testCategory', String,
        'Test Category (Positive, Negative, Boundary, Error, Performance)',
        hint: 'Positive, Negative, Boundary, Error, or Performance'),
    Field('preconditions', String, 'Preconditions',
        hint: 'Conditions that must hold before the test runs'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Test execution details.
    @SerializationOrder(1)
    RequirementTestCaseEntryExecution execution =
            RequirementTestCaseEntryExecution();

    /// Automation and prioritization details.
    @SerializationOrder(2)
    RequirementTestCaseEntryAutomation automation =
            RequirementTestCaseEntryAutomation();

  @Reference('Related Acceptance Criterion')
  @SerializationOrder(3)
  String? relatedCriterion;
}

/// Test execution details.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'ISO/IEC/IEEE 29148 §6.5 — verification',
  ],
  'The execution detail of a test case — the steps to perform, the test data '
  'used, and the expected result.',
)
@SectionId('RTCEE')
class RequirementTestCaseEntryExecution {
    @Form([
        Field('testSteps', String, 'Test Steps',
            hint: 'Ordered steps to execute the test'),
        Field('testData', String, 'Test Data',
            hint: 'Data used when running the test'),
        Field('expectedResult', String, 'Expected Result', required: true,
            hint: 'Expected outcome of the test'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Automation and prioritization details.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'ISO/IEC/IEEE 29148 §6.5 — verification',
  ],
  'The automation and prioritization of a test case — whether it is automated, '
  'the script that runs it, and its priority.',
)
@SectionId('RTCEA')
class RequirementTestCaseEntryAutomation {
    @Form([
        Field('automationStatus', String,
                'Automation Status (Automated, Manual, To Be Automated)',
            hint: 'Automated, Manual, or To Be Automated'),
        Field('automationScript', String, 'Automation Script Reference',
            hint: 'Reference to the automation script'),
        Field('priority', String, 'Priority (Critical, High, Medium, Low)',
            hint: 'Critical, High, Medium, or Low'),
    ])
    @SerializationOrder(0)
    String? content;
}

// ---------------------------------------------------------------------------
// 4.3.2 Technical Requirements
// ---------------------------------------------------------------------------

/// 4.3.2. Technical Requirements.
///
/// Container for technical requirements. Technical requirements describe
/// constraints on how the system is built — platform, performance,
/// scalability, reliability, and standards compliance. These requirements
/// often drive architectural decisions.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
    'ISO/IEC 25010 — product quality',
  ],
  'The root of §4.3.2: captures the technical, non-functional constraints on '
  'how the system is built — platform, performance, scalability, reliability, '
  'and standards compliance.',
)
@DetailedIn(D04RequirementsSpecification)
@SecondLevelSectionId(D04RequirementsSpecification, 'RSP-TEC')
@ContentHelp('Technical requirements describe non-functional aspects and '
    'constraints. Each should be measurable and testable. Common categories: '
    'Performance, Scalability, Availability, Security, Maintainability.')
@SectionId('TR1')
class TechnicalRequirements {
  @SerializationOrder(0)
  String? content;

  /// Technical requirements summary form.
  @Form([
    Field('totalTechnicalRequirements', String, 'Total Technical Requirements',
        hint: 'Total count of technical requirements captured'),
    Field('criticalCount', String, 'Critical (count)',
        hint: 'Number of requirements at Critical priority'),
    Field('highCount', String, 'High (count)',
        hint: 'Number of requirements at High priority'),
    Field('mediumCount', String, 'Medium (count)',
        hint: 'Number of requirements at Medium priority'),
    Field('lowCount', String, 'Low (count)',
        hint: 'Number of requirements at Low priority'),
    Field('architectureDrivers', String,
        'Architecture Drivers (top constraints shaping design)',
        hint: 'e.g., 99.99% availability, sub-100ms latency, 10k concurrent users'),
  ])
  @SerializationOrder(1)
  String? summaryForm;

  /// Technical requirements list — contains 0+× Technical Requirement.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
      'ISO/IEC 25010 — product quality',
    ],
    'The set of individual technical requirement entries that constrain how '
    'the system is built.',
  )
  @SectionId('TERQ-REQU-LST')
  @SectionIdPattern('TERQ-REQU-xxx')
  @ContentHelp('Add one entry per technical requirement.')
  @SerializationOrder(2)
  List<TechnicalRequirementEntry> requirements = [];
}

/// A technical requirement entry.
///
/// Comprehensive technical requirement definition following ISO 25010
/// quality characteristics and architecture decision records.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
    'ISO/IEC 25010 — product quality',
  ],
  'A single technical requirement — a measurable, testable non-functional '
  'constraint on how the system is built.',
)
@SectionId('TERQ')
class TechnicalRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-T001)', required: true,
        hint: 'Stable unique identifier, e.g., REQ-T001'),
    Field('title', String, 'Title', required: true,
        hint: 'Short descriptive name for the requirement'),
    Field('status', String,
        'Status (Draft, Proposed, Approved, Verified, Deferred)', required: true,
        hint: 'Draft, Proposed, Approved, Verified, or Deferred'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Requirement details: description, category, priority.
  @SerializationOrder(1)
  TechnicalRequirementEntryDetails details = TechnicalRequirementEntryDetails();

  /// Measurement specifications.
  @SerializationOrder(2)
  TechnicalRequirementEntryMeasurement measurement =
      TechnicalRequirementEntryMeasurement();

  /// Verification approach and tools.
  @SerializationOrder(3)
  TechnicalRequirementEntryVerification verification =
      TechnicalRequirementEntryVerification();

  /// Impact assessment.
  @SerializationOrder(4)
  TechnicalRequirementEntryImpact impact = TechnicalRequirementEntryImpact();

  /// Assumptions and constraints.
  @SerializationOrder(5)
  TechnicalRequirementEntryConstraints constraints =
      TechnicalRequirementEntryConstraints();

  /// 4.3.2.n.1. Acceptance Criteria.
  @SerializationOrder(6)
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.2.n.2. Dependencies.
  @SerializationOrder(7)
  RequirementDependencies dependencies = RequirementDependencies();

  /// 4.3.2.n.3. Traceability.
  @SerializationOrder(8)
  RequirementTraceability traceability = RequirementTraceability();
}

/// Technical requirement details: description, category, priority.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
    'ISO/IEC 25010 — product quality',
  ],
  'The descriptive core of a technical requirement — its statement, quality '
  'category, priority, and source.',
)
@SectionId('TRED')
class TechnicalRequirementEntryDetails {
  @Form([
    Field('description', String,
        'Description (The system shall... detailed statement)', required: true,
        hint: 'Full requirement statement, e.g., The system shall respond '
            'within 100ms'),
    Field('category', String,
        'Category (Performance, Scalability, Availability, Reliability, '
            'Security, Usability, Accessibility, Maintainability, Portability, '
            'Interoperability, Compliance, Capacity, Recoverability)',
        required: true,
        hint: 'ISO 25010 quality characteristic the requirement addresses'),
    Field('subcategory', String, 'Subcategory (specific aspect within category)',
        hint: 'More specific aspect, e.g., response time within Performance'),
    Field('priority', String,
        'Priority (Critical, High, Medium, Low)', required: true,
        hint: 'Critical, High, Medium, or Low'),
    Field('source', String, 'Source (who requested)', required: true,
        hint: 'Stakeholder, document, or standard that originated it'),
    Field('rationale', String, 'Rationale',
        hint: 'Why this requirement is needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Measurement specifications for technical requirement.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
    'ISO/IEC 25010 — product quality',
  ],
  'How the requirement is quantified and verified — the metric, target value, '
  'and measurement method that make it testable.',
)
@SectionId('TREM')
class TechnicalRequirementEntryMeasurement {
  @Form([
    Field('metric', String, 'Metric (what is measured)',
        hint: 'e.g., p95 response time, throughput, uptime percentage'),
    Field('currentValue', String, 'Current Value (baseline)',
        hint: 'Present-day measured value, if known'),
    Field('targetValue', String, 'Target Value', required: true,
        hint: 'Required threshold the metric must meet, e.g., < 100ms'),
    Field('measurementMethod', String, 'Measurement Method',
        hint: 'How the metric is captured, e.g., APM instrumentation'),
    Field('measurementEnvironment', String,
        'Measurement Environment (production, staging, load test)',
        hint: 'Where measured: production, staging, or load test'),
    Field('measurementFrequency', String, 'Measurement Frequency',
        hint: 'How often measured, e.g., continuous, per release'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification approach for technical requirement.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
    'ISO/IEC 25010 — product quality',
  ],
  'How conformance to the requirement is verified — the approach, tooling, and '
  'timing of verification.',
)
@SectionId('TREV')
class TechnicalRequirementEntryVerification {
  @Form([
    Field('verificationApproach', String,
        'Verification Approach (how verified: test, inspection, analysis)',
        hint: 'Test, inspection, analysis, or demonstration'),
    Field('verificationTool', String, 'Verification Tool',
        hint: 'Tool used to verify, e.g., load testing framework'),
    Field('verificationTiming', String,
        'Verification Timing (unit test, integration, acceptance, production)',
        hint: 'When verified: unit, integration, acceptance, or production'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Impact assessment for technical requirement.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
    'ISO/IEC 25010 — product quality',
  ],
  'The consequences of the requirement — its effect on architecture, the '
  'effort to satisfy it, and the risk of not meeting it.',
)
@SectionId('TREI')
class TechnicalRequirementEntryImpact {
  @Form([
    Field('architectureImpact', String,
        'Architecture Impact (how this affects system design)',
        hint: 'How satisfying this shapes the system design'),
    Field('estimatedEffort', String, 'Estimated Implementation Effort',
        hint: 'Rough effort to implement, e.g., 2 sprints'),
    Field('riskIfNotMet', String, 'Risk If Not Met',
        hint: 'Consequence if the requirement is not satisfied'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Assumptions and constraints for technical requirement.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
    'ISO/IEC 25010 — product quality',
  ],
  'The assumptions the requirement relies on and the constraints it imposes or '
  'operates under.',
)
@SectionId('TREC')
class TechnicalRequirementEntryConstraints {
  @Form([
    Field('assumptions', String, 'Assumptions',
        hint: 'Conditions assumed true for the requirement to hold'),
    Field('constraints', String, 'Constraints',
        hint: 'Limits or boundaries that apply, e.g., fixed infrastructure'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.3.3 Security Requirements
// ---------------------------------------------------------------------------

/// 4.3.3. Security Requirements.
///
/// Container for security requirements. Security requirements describe
/// information protection, access control, authentication, authorization,
/// audit, and compliance needs. Based on OWASP, ISO 27001, and common
/// security frameworks.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security controls',
    'ISO/IEC/IEEE 29148 §9 — security requirements',
  ],
  'The root of §4.3.3: captures information-protection, access-control, '
  'authentication, authorization, audit, and compliance needs for the system.',
)
@DetailedIn(D04RequirementsSpecification)
@SecondLevelSectionId(D04RequirementsSpecification, 'RSP-SEC')
@ContentHelp('Security requirements protect confidentiality, integrity, '
    'and availability of information. Include authentication, authorization, '
    'data protection, and compliance requirements.')
@SectionId('SR1')
class SecurityRequirements {
  @SerializationOrder(0)
  String? content;

  /// Security requirements summary form.
  @Form([
    Field('totalSecurityRequirements', String, 'Total Security Requirements',
        hint: 'Total count of security requirements captured'),
    Field('criticalCount', String, 'Critical (count)',
        hint: 'Number of requirements at Critical priority'),
    Field('highCount', String, 'High (count)',
        hint: 'Number of requirements at High priority'),
    Field('mediumCount', String, 'Medium (count)',
        hint: 'Number of requirements at Medium priority'),
    Field('securityFramework', String,
        'Security Framework (OWASP, NIST, ISO 27001, CIS, etc.)',
        hint: 'Primary framework guiding the requirements'),
    Field('complianceRequirements', String,
        'Compliance Requirements (GDPR, HIPAA, PCI-DSS, SOX, etc.)',
        hint: 'Regulations the system must comply with'),
    Field('threatCategories', String,
        'Threat Categories Addressed (Injection, XSS, CSRF, etc.)',
        hint: 'Classes of attack the requirements mitigate'),
  ])
  @SerializationOrder(1)
  String? summaryForm;

  /// Security requirements list — contains 0+× Security Requirement.
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — security controls',
      'ISO/IEC/IEEE 29148 §9 — security requirements',
    ],
    'The set of individual security requirement entries protecting the '
    'confidentiality, integrity, and availability of information.',
  )
  @SectionId('SECRQ-REQU-LST')
  @SectionIdPattern('SECRQ-REQU-xxx')
  @ContentHelp('Add one entry per security requirement.')
  @SerializationOrder(2)
  List<SecurityRequirementEntry> requirements = [];
}

/// A security requirement entry.
///
/// Comprehensive security requirement definition following OWASP ASVS,
/// ISO 27001, and security best practices.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security controls',
    'ISO/IEC/IEEE 29148 §9 — security requirements',
  ],
  'A single security requirement — a protection, access-control, or compliance '
  'need the system must satisfy.',
)
@SectionId('SECRQ')
class SecurityRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-S001)', required: true,
        hint: 'Stable unique identifier, e.g., REQ-S001'),
    Field('title', String, 'Title', required: true,
        hint: 'Short descriptive name for the requirement'),
    Field('description', String,
        'Description (The system shall... detailed statement)', required: true,
        hint: 'Full requirement statement, e.g., The system shall encrypt '
            'data at rest'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Category and classification.
  @SerializationOrder(1)
  SecurityRequirementEntryClassification classification =
      SecurityRequirementEntryClassification();

  /// Compliance framework mapping.
  @SerializationOrder(2)
  SecurityRequirementEntryCompliance compliance =
      SecurityRequirementEntryCompliance();

  /// Implementation and verification.
  @SerializationOrder(3)
  SecurityRequirementEntryVerification verification =
      SecurityRequirementEntryVerification();

  /// Status and ownership.
  @SerializationOrder(4)
  SecurityRequirementEntryStatus statusInfo =
      SecurityRequirementEntryStatus();

  /// 4.3.3.n.1. Acceptance Criteria.
  @SerializationOrder(5)
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.3.n.2. Security Controls.
  @SerializationOrder(6)
  SecurityControls controls = SecurityControls();

  /// 4.3.3.n.3. Dependencies.
  @SerializationOrder(7)
  RequirementDependencies dependencies = RequirementDependencies();

  /// 4.3.3.n.4. Traceability.
  @SerializationOrder(8)
  RequirementTraceability traceability = RequirementTraceability();
}

/// Category and classification for security requirement.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security controls',
    'ISO/IEC/IEEE 29148 §9 — security requirements',
  ],
  'The classification of a security requirement — its security category, '
  'priority, source, and the threat and data classification it concerns.',
)
@SectionId('SEREENCL')
class SecurityRequirementEntryClassification {
  @Form([
    Field('category', String,
        'Category (Authentication, Authorization, Data Protection, '
            'Encryption, Audit Logging, Input Validation, Session Management, '
            'Error Handling, Communication Security, Configuration, '
            'Cryptography, Data Retention, Privacy)',
        required: true,
        hint: 'Security domain the requirement falls under'),
    Field('subcategory', String, 'Subcategory',
        hint: 'More specific aspect within the category'),
    Field('priority', String,
        'Priority (Critical, High, Medium, Low)', required: true,
        hint: 'Critical, High, Medium, or Low'),
    Field('source', String, 'Source', required: true,
        hint: 'Stakeholder, standard, or document that originated it'),
    Field('rationale', String, 'Rationale',
        hint: 'Why this security requirement is needed'),
    Field('threatMitigated', String,
        'Threat Mitigated (what attack is prevented)',
        hint: 'Attack or risk this requirement prevents'),
    Field('dataClassification', String,
        'Data Classification Affected (Public, Internal, Confidential, '
            'Restricted, PII, PHI)',
        hint: 'Sensitivity of data the requirement protects'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance framework mapping for security requirement.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security controls',
    'ISO/IEC/IEEE 29148 §9 — security requirements',
  ],
  'The mapping of a security requirement onto external frameworks — OWASP, '
  'CIS, NIST, ISO 27001, and regulatory compliance references.',
)
@SectionId('SEREENCO')
class SecurityRequirementEntryCompliance {
  @Form([
    Field('owaspCategory', String,
        'OWASP Category (if applicable, e.g., A01:2021 Broken Access Control)',
        hint: 'OWASP Top 10 / ASVS category, if applicable'),
    Field('cisControl', String, 'CIS Control (if applicable)',
        hint: 'Matching CIS Control number, if applicable'),
    Field('nistControl', String, 'NIST Control (if applicable)',
        hint: 'Matching NIST SP 800-53 control, if applicable'),
    Field('iso27001Control', String, 'ISO 27001 Control (if applicable)',
        hint: 'Matching ISO 27001 Annex A control, if applicable'),
    Field('complianceReference', String,
        'Compliance Reference (GDPR Article, PCI-DSS requirement, etc.)',
        hint: 'Specific regulation clause, e.g., GDPR Art. 32'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Implementation and verification for security requirement.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security controls',
    'ISO/IEC/IEEE 29148 §9 — security requirements',
  ],
  'How a security requirement is implemented and verified — the approach, '
  'verification method, and frequency.',
)
@SectionId('SREV')
class SecurityRequirementEntryVerification {
  @Form([
    Field('implementationApproach', String, 'Implementation Approach',
        hint: 'How the requirement will be technically realized'),
    Field('verificationMethod', String,
        'Verification Method (Penetration test, Code review, Security scan)',
        hint: 'How conformance is checked, e.g., penetration test'),
    Field('verificationFrequency', String,
        'Verification Frequency (Continuous, Release, Quarterly, Annual)',
        hint: 'How often verified: continuous, release, quarterly, annual'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Status and ownership for security requirement.
@StandardReferences(
  [
    'ISO/IEC 27001 Annex A — security controls',
    'ISO/IEC/IEEE 29148 §9 — security requirements',
  ],
  'The lifecycle and ownership of a security requirement — residual risk after '
  'mitigation, the risk owner, and current status.',
)
@SectionId('SEREENST')
class SecurityRequirementEntryStatus {
  @Form([
    Field('residualRisk', String, 'Residual Risk (after mitigation)',
        hint: 'Risk remaining once controls are applied'),
    Field('riskOwner', String, 'Risk Owner',
        hint: 'Person or role accountable for the residual risk'),
    Field('status', String,
        'Status (Draft, Proposed, Approved, Implemented, Verified)',
        required: true,
        hint: 'Draft, Proposed, Approved, Implemented, or Verified'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.3.3.n.2. Security Controls.
///
/// Security controls that implement or support this requirement.
@StandardReferences(
  [
    'ISO/IEC 27002 — information security controls',
    'OWASP ASVS — security verification',
    'NIST SP 800-53 — security controls',
  ],
  'The root of §4.3.3.n.2: captures the security controls that implement or '
  'support a security requirement.',
)
@SectionId('SECO')
@ContentHelp('Define security controls that implement this requirement.')
class SecurityControls {
  @ContentType('description', 'Overview of security controls for this '
      'requirement.')
  @SerializationOrder(0)
  String? content;

  /// Security control entries — contains 0+× SecurityControlEntry.
  @StandardReferences(
    [
      'ISO/IEC 27002 — information security controls',
      'OWASP ASVS — security verification',
      'NIST SP 800-53 — security controls',
    ],
    'The set of individual security control entries implementing or supporting '
    'this security requirement.',
  )
  @SectionId('SECCT-CONT-LST')
  @SectionIdPattern('SECCT-CONT-xxx')
  @ContentHelp('Add one entry per security control implementing this '
      'requirement.')
  @SerializationOrder(1)
  List<SecurityControlEntry> controls = [];
}

/// A security control entry (form).
@StandardReferences(
  [
    'ISO/IEC 27002 — information security controls',
    'OWASP ASVS — security verification',
    'NIST SP 800-53 — security controls',
  ],
  'A single security control — a preventive, detective, or corrective measure '
  'implementing or supporting a security requirement.',
)
@SectionId('SECOEN')
class SecurityControlEntry {
  @Form([
    Field('controlId', String, 'Control ID', required: true,
        hint: 'Stable unique identifier for the control'),
    Field('controlName', String, 'Control Name', required: true,
        hint: 'Short descriptive name for the control'),
    Field('controlType', String,
        'Control Type (Preventive, Detective, Corrective, Deterrent, '
            'Compensating)',
        required: true,
        hint: 'Preventive, Detective, Corrective, Deterrent, or Compensating'),
    Field('implementationType', String,
        'Implementation Type (Technical, Administrative, Physical)',
        hint: 'Technical, Administrative, or Physical'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Control implementation details.
    @SerializationOrder(1)
    SecurityControlEntryImplementation implementation =
            SecurityControlEntryImplementation();

    /// Testing and lifecycle status.
    @SerializationOrder(2)
    SecurityControlEntryVerification verification =
            SecurityControlEntryVerification();
}

/// Control implementation details.
@StandardReferences(
  [
    'ISO/IEC 27002 — information security controls',
    'OWASP ASVS — security verification',
    'NIST SP 800-53 — security controls',
  ],
  'How a security control is implemented — its description, implementation '
  'details, and effective date.',
)
@SectionId('SCEI')
class SecurityControlEntryImplementation {
    @Form([
        Field('description', String, 'Description',
            hint: 'What the control does'),
        Field('implementationDetails', String, 'Implementation Details',
            hint: 'How the control is configured or deployed'),
        Field('effectiveDate', String, 'Effective Date',
            hint: 'Date the control becomes active'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Testing and lifecycle status.
@StandardReferences(
  [
    'ISO/IEC 27002 — information security controls',
    'OWASP ASVS — security verification',
    'NIST SP 800-53 — security controls',
  ],
  'The testing and lifecycle state of a security control — its test frequency, '
  'last test, result, and current status.',
)
@SectionId('SCEV')
class SecurityControlEntryVerification {
    @Form([
        Field('testFrequency', String, 'Test Frequency',
            hint: 'How often the control is tested'),
        Field('lastTestDate', String, 'Last Test Date',
            hint: 'Date the control was last tested'),
        Field('testResult', String, 'Last Test Result',
            hint: 'Outcome of the most recent test'),
        Field('status', String, 'Status (Planned, Implemented, Active, Retired)',
            hint: 'Planned, Implemented, Active, or Retired'),
    ])
    @SerializationOrder(0)
    String? content;
}

// ---------------------------------------------------------------------------
// 4.3.4 Organizational Requirements
// ---------------------------------------------------------------------------

/// 4.3.4. Organizational Requirements.
///
/// Container for organizational requirements. These describe needed changes
/// to organization, processes, training, or support that must be fulfilled
/// for the system to succeed. Based on change management and organizational
/// readiness assessment practices.
@StandardReferences(
  [
    'ISO 21500 — organizational project management',
    'BABOK v3 §10 — organizational readiness',
    'ISO/IEC/IEEE 29148 §9 — organizational requirements',
  ],
  'The root of §4.3.4: captures the non-technical changes to organization, '
  'processes, training, or support needed for the system to succeed.',
)
@DetailedIn(D04RequirementsSpecification)
@SecondLevelSectionId(D04RequirementsSpecification, 'RSP-ORG')
@ContentHelp('Organizational requirements describe non-technical changes '
    'needed for system success: training, process changes, role changes, '
    'support structures, and communication.')
@SectionId('OR')
class OrganizationalRequirements {
  @SerializationOrder(0)
  String? content;

  /// Organizational requirements summary form.
  @Form([
    Field('totalOrgRequirements', String, 'Total Organizational Requirements',
        hint: 'Total count of organizational requirements captured'),
    Field('trainingRequirements', String, 'Training Requirements (count)',
        hint: 'Number of training-related requirements'),
    Field('processChangeRequirements', String, 'Process Change (count)',
        hint: 'Number of process-change requirements'),
    Field('roleChangeRequirements', String, 'Role Change (count)',
        hint: 'Number of role-change requirements'),
    Field('supportRequirements', String, 'Support Requirements (count)',
        hint: 'Number of support-structure requirements'),
    Field('communicationRequirements', String, 'Communication (count)',
        hint: 'Number of communication requirements'),
    Field('changeReadinessScore', String,
        'Organizational Change Readiness Score',
        hint: 'Assessed readiness of the organization to adopt the change'),
  ])
  @SerializationOrder(1)
  String? summaryForm;

  /// Organizational requirements list — contains 0+× Organizational Requirement.
  @StandardReferences(
    [
      'ISO 21500 — organizational project management',
      'BABOK v3 §10 — organizational readiness',
      'ISO/IEC/IEEE 29148 §9 — organizational requirements',
    ],
    'The set of individual organizational requirement entries — the '
    'non-technical changes needed for the system to succeed.',
  )
  @SectionId('ORRQ-REQU-LST')
  @SectionIdPattern('ORRQ-REQU-xxx')
  @ContentHelp('Add one entry per organizational requirement.')
  @SerializationOrder(2)
  List<OrganizationalRequirementEntry> requirements = [];
}

/// An organizational requirement entry.
///
/// Comprehensive organizational requirement definition following change
/// management and organizational development best practices.
@StandardReferences(
  [
    'ISO 21500 — organizational project management',
    'BABOK v3 §10 — organizational readiness',
    'ISO/IEC/IEEE 29148 §9 — organizational requirements',
  ],
  'A single organizational requirement — a needed change to organization, '
  'process, training, or support for the system to succeed.',
)
@SectionId('ORRQ')
class OrganizationalRequirementEntry {
  @Form([
    Field('requirementId', String,
        'Requirement ID (unique, e.g., REQ-O001)', required: true,
        hint: 'Stable unique identifier, e.g., REQ-O001'),
    Field('title', String, 'Title', required: true,
        hint: 'Short descriptive name for the requirement'),
    Field('description', String,
        'Description (detailed statement)', required: true,
        hint: 'Full statement of the organizational change needed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Requirement classification and source.
  @SerializationOrder(1)
  OrganizationalRequirementEntryClassification classification =
      OrganizationalRequirementEntryClassification();

  /// Impact and change profile.
  @SerializationOrder(2)
  OrganizationalRequirementEntryImpact impact =
      OrganizationalRequirementEntryImpact();

  /// Planning, ownership, and success tracking.
  @SerializationOrder(3)
  OrganizationalRequirementEntryPlanning planning =
      OrganizationalRequirementEntryPlanning();

  /// 4.3.4.n.1. Acceptance Criteria.
  @SerializationOrder(4)
  RequirementAcceptanceCriteria acceptanceCriteria =
      RequirementAcceptanceCriteria();

  /// 4.3.4.n.2. Implementation Plan.
  @SerializationOrder(5)
  OrgRequirementImplementationPlan implementationPlan =
      OrgRequirementImplementationPlan();

  /// 4.3.4.n.3. Dependencies.
  @SerializationOrder(6)
  RequirementDependencies dependencies = RequirementDependencies();
}

/// Requirement classification and source.
@StandardReferences(
  [
    'ISO 21500 — organizational project management',
    'BABOK v3 §10 — organizational readiness',
    'ISO/IEC/IEEE 29148 §9 — organizational requirements',
  ],
  'The classification of an organizational requirement — its change category, '
  'priority, source, and rationale.',
)
@SectionId('OREC')
class OrganizationalRequirementEntryClassification {
    @Form([
        Field('category', String,
                'Category (Training, Process Change, Role Change, Support, '
                        'Communication, Policy, Governance, Culture, Staffing)',
                required: true,
                hint: 'Type of organizational change the requirement entails'),
        Field('subcategory', String, 'Subcategory',
                hint: 'More specific aspect within the category'),
        Field('priority', String,
                'Priority (Must, Should, Could, Won\'t-This-Time)', required: true,
                hint: 'MoSCoW priority: Must, Should, Could, or Won\'t-This-Time'),
        Field('source', String, 'Source', required: true,
                hint: 'Stakeholder or document that originated it'),
        Field('rationale', String, 'Rationale',
                hint: 'Why this organizational change is needed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Impact and change profile.
@StandardReferences(
  [
    'ISO 21500 — organizational project management',
    'BABOK v3 §10 — organizational readiness',
    'ISO/IEC/IEEE 29148 §9 — organizational requirements',
  ],
  'The impact profile of an organizational requirement — who is affected, the '
  'type and complexity of change, and expected resistance.',
)
@SectionId('OREI')
class OrganizationalRequirementEntryImpact {
    @Form([
        Field('impactedGroups', String,
                'Impacted Groups (departments, roles, user categories)',
                hint: 'Departments, roles, or user categories affected'),
        Field('impactedUserCount', String, 'Estimated Impacted Users',
                hint: 'Approximate number of people affected'),
        Field('changeType', String,
                'Change Type (Behavioral, Procedural, Structural, Cultural)',
                hint: 'Behavioral, Procedural, Structural, or Cultural'),
        Field('changeComplexity', String,
                'Change Complexity (Low, Medium, High)',
                hint: 'Low, Medium, or High'),
        Field('resistance', String,
                'Expected Resistance (Low, Medium, High)',
                hint: 'Anticipated resistance: Low, Medium, or High'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Planning, ownership, and success tracking.
@StandardReferences(
  [
    'ISO 21500 — organizational project management',
    'BABOK v3 §10 — organizational readiness',
    'ISO/IEC/IEEE 29148 §9 — organizational requirements',
  ],
  'The planning and ownership of an organizational requirement — its timeline, '
  'dependencies, owner, sponsor, success criteria, and status.',
)
@SectionId('OREP')
class OrganizationalRequirementEntryPlanning {
    @Form([
        Field('timeline', String, 'Timeline (when change must occur)',
                hint: 'When the change must be completed'),
        Field('dependencies', String, 'Dependencies (other changes needed first)',
                hint: 'Other changes that must happen first'),
        Field('owner', String, 'Change Owner',
                hint: 'Person or role accountable for the change'),
        Field('sponsor', String, 'Executive Sponsor',
                hint: 'Leadership sponsor backing the change'),
        Field('successCriteria', String, 'Success Criteria',
                hint: 'How success of the change is defined'),
        Field('measurementMethod', String, 'Measurement Method',
                hint: 'How success criteria are measured'),
        Field('status', String,
                'Status (Draft, Proposed, Approved, In Progress, Completed)',
                required: true,
                hint: 'Draft, Proposed, Approved, In Progress, or Completed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 4.3.4.n.2. Implementation Plan.
///
/// Implementation plan for this organizational requirement.
@StandardReferences(
  [
    'ISO 21500 — implementation activities',
    'PMBOK — change/implementation management',
  ],
  'The root of §4.3.4.n.2: captures the implementation approach for an '
  'organizational change requirement.',
)
@ContentHelp('Define the implementation approach for this organizational '
    'change requirement.')
@SectionId('ORIP')
class OrgRequirementImplementationPlan {
  @SerializationOrder(0)
  String? content;

  /// Implementation plan form.
  @Form([
    Field('approach', String,
        'Approach (Big Bang, Phased, Pilot, Parallel)',
        hint: 'Big Bang, Phased, Pilot, or Parallel rollout'),
    Field('phases', String, 'Phases (if phased rollout)',
        hint: 'Sequence of phases, if phased'),
    Field('pilotGroup', String, 'Pilot Group (if pilot approach)',
        hint: 'Group used for the pilot, if piloting'),
    Field('trainingApproach', String, 'Training Approach',
        hint: 'How affected people are trained'),
    Field('communicationPlan', String, 'Communication Plan',
        hint: 'How the change is communicated to stakeholders'),
    Field('supportPlan', String, 'Support Plan',
        hint: 'Support provided during and after the change'),
    Field('rollbackPlan', String, 'Rollback Plan',
        hint: 'How to revert if the change fails'),
    Field('resourcesNeeded', String, 'Resources Needed',
        hint: 'People, tools, or budget required'),
    Field('budget', String, 'Budget',
        hint: 'Estimated cost of the implementation'),
    Field('timeline', String, 'Timeline',
        hint: 'Schedule for the implementation'),
  ])
  @SerializationOrder(1)
  String? planForm;

  /// Implementation activities — contains 0+× OrgImplementationActivity.
  @StandardReferences(
    [
      'ISO 21500 — implementation activities',
      'PMBOK — change/implementation management',
    ],
    'The set of individual implementation activities that carry out the '
    'organizational change.',
  )
  @SectionId('ORGIM-ACTI-LST')
  @SectionIdPattern('ORGIM-ACTI-xxx')
  @ContentHelp('Add one entry per implementation activity for this '
      'organizational change.')
  @SerializationOrder(2)
  List<OrgImplementationActivity> activities = [];
}

/// An organizational implementation activity (form).
@StandardReferences(
  [
    'ISO 21500 — implementation activities',
    'PMBOK — change/implementation management',
  ],
  'A single implementation activity — a discrete, owned, scheduled task that '
  'carries out part of the organizational change.',
)
@SectionId('ORGIM')
class OrgImplementationActivity {
  @Form([
    Field('activityId', String, 'Activity ID', required: true,
        hint: 'Stable unique identifier for the activity'),
    Field('activityName', String, 'Activity Name', required: true,
        hint: 'Short descriptive name for the activity'),
    Field('description', String, 'Description',
        hint: 'What the activity entails'),
    Field('owner', String, 'Owner',
        hint: 'Person or role responsible for the activity'),
    Field('startDate', String, 'Start Date',
        hint: 'Planned start date'),
    Field('endDate', String, 'End Date',
        hint: 'Planned completion date'),
    Field('deliverable', String, 'Deliverable',
        hint: 'Output produced by the activity'),
    Field('status', String, 'Status (Planned, In Progress, Completed, Delayed)',
        hint: 'Planned, In Progress, Completed, or Delayed'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.4 Systems to Replace (seeds → CLA)
// ---------------------------------------------------------------------------

/// 4.4. Systems to Replace. Seeds → CLA.
///
/// Documents existing systems that will be replaced, migrated, or decommissioned
/// as part of the project. Follows TOGAF migration planning patterns and
/// Gartner application rationalization frameworks. Each system entry provides
/// comprehensive assessment for informed replacement decisions.
@SectionId('SYTOR1')
@Comment('Seeds → CLA')
@MapsTo(D01CurrentLandscapeAssessment)
class SystemsToReplace {
  /// Overview of the systems replacement scope and strategy.
  @ContentHelp('Provide executive summary of systems being replaced: '
      'portfolio count, replacement rationale, expected timeline, '
      'and overall migration approach.')
  @SerializationOrder(0)
  TextSection overview = TextSection();

  /// 4.4.1. Replacement Inventory — contains 0+×.
  @SerializationOrder(1)
  ReplacementInventory replacementInventory = ReplacementInventory();

  /// 4.4.2. Migration Considerations.
  @SerializationOrder(2)
  MigrationConsiderations migrationConsiderations = MigrationConsiderations();
}

// ---------------------------------------------------------------------------
// 4.4.1. Replacement Inventory
// ---------------------------------------------------------------------------

/// Container for systems to replace.
///
/// Provides a structured inventory of all systems targeted for replacement,
/// with portfolio-level metrics and prioritization guidance.
@SectionId('RI')
@DetailedIn(D01CurrentLandscapeAssessment)
@SecondLevelSectionId(D01CurrentLandscapeAssessment, 'CLA-INV')
class ReplacementInventory {
  /// Portfolio summary before listing individual systems.
  @ContentHelp('Summarize the replacement portfolio: total system count, '
      'technology categories, combined user base, and overall complexity.')
  @SerializationOrder(0)
  TextSection portfolioSummary = TextSection();

  /// Prioritization criteria for replacement sequencing.
  @ContentHelp('Describe how replacement order is determined: business value, '
      'technical debt, risk, dependency chains, resource availability.')
  @SerializationOrder(1)
  TextSection prioritizationCriteria = TextSection();

  /// Contains 0+× SystemToReplaceEntry.
  @SectionId('SYTORE-SYST-LST')
  @SectionIdPattern('SYTORE-SYST-xxx')
  @SerializationOrder(2)
  List<SystemToReplaceEntry> systems = [];
}

/// A system to replace entry (form).
///
/// Comprehensive documentation of a legacy system to be replaced, covering
/// technical assessment, business criticality, replacement strategy, and
/// migration planning. Follows Gartner's TIME (Tolerate, Invest, Migrate,
/// Eliminate) model and TOGAF application portfolio management patterns.
@SectionId('SYTORE')
class SystemToReplaceEntry {
  // -------------------------------------------------------------------------
  // System Identification
  // -------------------------------------------------------------------------

  @Form([
    Field('systemId', String, 'System ID (e.g., SYS-CRM-001)', required: true),
    Field('systemName', String, 'System Name', required: true),
    Field('officialName', String, 'Official/Vendor Name'),
    Field('systemDescription', String, 'Description'),
  ])
  @SerializationOrder(0)
  String? identificationContent;

    /// Classification and ownership details.
    @SerializationOrder(1)
    SystemToReplaceEntryProfile profile = SystemToReplaceEntryProfile();

    /// Vendor and contract status.
    @SerializationOrder(2)
    SystemToReplaceEntryVendor vendor = SystemToReplaceEntryVendor();

  /// Technical stack and architecture assessment.
  @SerializationOrder(3)
  SystemTechnicalAssessment technicalAssessment = SystemTechnicalAssessment();

  /// Business value and criticality assessment.
  @SerializationOrder(4)
  SystemBusinessCriticality businessCriticality = SystemBusinessCriticality();

  /// Detailed replacement approach.
  @SerializationOrder(5)
  SystemReplacementStrategy replacementStrategy = SystemReplacementStrategy();

  /// Data migration scope and assessment.
  @SerializationOrder(6)
  SystemDataScope dataScope = SystemDataScope();

    /// Contains 0+× ReplacementSystemDependencyEntry — integrations with other systems.
  @SectionId('REPSDEP-DEPE-LST')
  @SectionIdPattern('REPSDEP-DEPE-xxx')
    @SerializationOrder(7)
    List<ReplacementSystemDependencyEntry> dependencies = [];

  /// User impact and change management needs.
  @SerializationOrder(8)
  SystemUserImpact userImpact = SystemUserImpact();

  /// Financial analysis for replacement decision.
  @SerializationOrder(9)
  SystemCostAnalysis costAnalysis = SystemCostAnalysis();

  /// Per-system migration considerations.
  @SerializationOrder(10)
  SystemMigrationPlan migrationPlan = SystemMigrationPlan();

  /// Documentation and knowledge transfer status.
  @SerializationOrder(11)
  SystemKnowledgeTransfer knowledgeTransfer = SystemKnowledgeTransfer();
}

/// Classification and ownership details.
@SectionId('STREP')
class SystemToReplaceEntryProfile {
    @Form([
        Field('systemCategory', String, 'Category (CRM, ERP, HR, Finance, etc.)'),
        Field('applicationTier', String,
                'Tier (Mission Critical, Business Critical, Operational)'),
        Field('businessOwner', String, 'Business Owner'),
        Field('technicalOwner', String, 'Technical Owner'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Vendor and contract status.
@SectionId('STREV')
class SystemToReplaceEntryVendor {
    @Form([
        Field('vendorName', String, 'Vendor/Provider'),
        Field('contractStatus', String,
                'Contract Status (Active, Expired, Month-to-month)'),
        Field('contractEndDate', String, 'Contract End Date'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Technical assessment for a system to replace.
@SectionId('SYTEAS')
class SystemTechnicalAssessment {
  @Form([
    Field('primaryTechnology', String, 'Primary Technology/Platform'),
    Field('technologyVersion', String, 'Version'),
    Field('databasePlatform', String, 'Database Platform'),
    Field('hostingEnvironment', String,
        'Hosting (On-premises, Cloud, Hybrid, SaaS)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Platform and age details.
  @SerializationOrder(1)
  SystemTechnicalAssessmentPlatform platform =
      SystemTechnicalAssessmentPlatform();

  /// Support and lifecycle details.
  @SerializationOrder(2)
  SystemTechnicalAssessmentLifecycle lifecycle =
      SystemTechnicalAssessmentLifecycle();

  /// Technical quality indicators.
  @SerializationOrder(3)
  SystemTechnicalAssessmentQuality quality = SystemTechnicalAssessmentQuality();

  /// Known technical issues and deficiencies.
  @SectionId('KIE-KNOW-LST')
  @SectionIdPattern('KIE-KNOW-xxx')
  @SerializationOrder(4)
  List<KnownIssueEntry> knownIssues = [];

  /// Security vulnerabilities and compliance gaps.
  @SectionId('SECUR-SECU-LST')
  @SectionIdPattern('SECUR-SECU-xxx')
  @SerializationOrder(5)
  List<SecurityConcernEntry> securityConcerns = [];
}

/// Platform and age details.
@SectionId('STAP')
class SystemTechnicalAssessmentPlatform {
    @Form([
        Field('operatingSystem', String, 'Operating System'),
        Field('middlewareComponents', String, 'Middleware Components'),
        Field('deploymentDate', String, 'Initial Deployment Date'),
        Field('systemAge', int, 'System Age (Years)'),
        Field('lastMajorUpgrade', String, 'Last Major Upgrade'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Support and lifecycle details.
@SectionId('STAL')
class SystemTechnicalAssessmentLifecycle {
    @Form([
        Field('vendorSupportStatus', String,
                'Support Status (Full, Extended, End of Life)'),
        Field('endOfSupportDate', String, 'End of Support Date'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Technical quality indicators.
@SectionId('STAQ')
class SystemTechnicalAssessmentQuality {
    @Form([
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
    @SerializationOrder(0)
    String? content;
}

/// Business criticality assessment.
@SectionId('SYBUCR')
class SystemBusinessCriticality {
  @Form([
    Field('criticalityRating', String,
        'Criticality (1=Mission Critical, 2=Business, 3=Operational)',
        required: true),
    Field('businessValueScore', int, 'Business Value Score (1-10)'),
    Field('timeModelClassification', String,
        'TIME Classification (Tolerate, Invest, Migrate, Eliminate)'),
    Field('activeUsers', int, 'Active Users'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Usage scale and commercial impact.
  @SerializationOrder(1)
  SystemBusinessCriticalityOperations operations =
      SystemBusinessCriticalityOperations();

  /// Delivery and compliance constraints.
  @SerializationOrder(2)
  SystemBusinessCriticalityGovernance governance =
      SystemBusinessCriticalityGovernance();

  /// Business units and departments using this system.
  @SectionId('SBUE-BUSI-LST')
  @SectionIdPattern('SBUE-BUSI-xxx')
  @SerializationOrder(3)
  List<SystemBusinessUnitEntry> businessUnits = [];

  /// Business processes supported by this system.
  @SectionId('SBPE-SUPP-LST')
  @SectionIdPattern('SBPE-SUPP-xxx')
  @SerializationOrder(4)
  List<SystemBusinessProcessEntry> supportedProcesses = [];
}

/// Usage scale and commercial impact.
@SectionId('SBCO')
class SystemBusinessCriticalityOperations {
    @Form([
        Field('peakConcurrentUsers', int, 'Peak Concurrent Users'),
        Field('transactionVolume', String, 'Transaction Volume'),
        Field('dataVolume', String, 'Data Volume'),
        Field('revenueImpact', String, 'Revenue Impact (Direct, Indirect, None)'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Delivery and compliance constraints.
@SectionId('SBCG')
class SystemBusinessCriticalityGovernance {
    @Form([
        Field('operationsImpact', String,
                'Operations Impact (Severe, Moderate, Minor, None)'),
        Field('complianceRole', String, 'Compliance/Regulatory Role'),
        Field('maxDowntime', String, 'Max Acceptable Downtime (RTO)'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Business unit using the system.
@SectionId('SYBUUNEN')
class SystemBusinessUnitEntry {
  @Form([
    Field('unitName', String, 'Business Unit', required: true),
    Field('userCount', int, 'User Count'),
    Field('usagePattern', String, 'Usage Pattern (Daily, Weekly, etc.)'),
    Field('dependencyLevel', String,
        'Dependency Level (Primary, Secondary, Occasional)'),
    Field('impactIfRemoved', String, 'Impact if System Removed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Business process supported.
@SectionId('SYBUPREN')
class SystemBusinessProcessEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('processId', String, 'Process ID'),
    Field('systemRole', String, 'System Role (Primary, Data Source, etc.)'),
    Field('automationLevel', String, 'Automation Level'),
    Field('processFrequency', String, 'Execution Frequency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Replacement strategy details.
@SectionId('SYREST')
class SystemReplacementStrategy {
  @Form([
    Field('strategyType', String,
        'Strategy (Replace, Consolidate, Retire, Rehost, Replatform)',
        required: true),
    Field('strategyRationale', String, 'Rationale'),
    Field('targetSolution', String, 'Target Solution'),
    Field('targetSolutionType', String,
        'Target Type (COTS, SaaS, Custom, Platform)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Replacement timeline milestones.
  @SerializationOrder(1)
  SystemReplacementStrategyTimeline timeline =
      SystemReplacementStrategyTimeline();

  /// Cutover and rollback profile.
  @SerializationOrder(2)
  SystemReplacementStrategyCutover cutover =
      SystemReplacementStrategyCutover();

  /// Replacement phases if phased approach.
  @SectionId('REPPHS-PHAS-LST')
  @SectionIdPattern('REPPHS-PHAS-xxx')
  @SerializationOrder(3)
  List<ReplacementPhaseEntry> phases = [];

  /// Predecessor systems that must be addressed first.
  @SectionId('PREDE-PRED-LST')
  @SectionIdPattern('PREDE-PRED-xxx')
  @SerializationOrder(4)
  List<PredecessorDependencyEntry> predecessorDependencies = [];

  /// Success criteria for replacement completion.
  @SerializationOrder(5)
  TextSection successCriteria = TextSection();
}

/// Replacement timeline milestones.
@SectionId('SRST')
class SystemReplacementStrategyTimeline {
    @Form([
        Field('plannedStartDate', String, 'Planned Start Date'),
        Field('targetCutoverDate', String, 'Target Cutover Date'),
        Field('decommissionDate', String, 'Decommission Date'),
        Field('parallelRunPeriod', String, 'Parallel Run Period'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Cutover and rollback profile.
@SectionId('SRSC')
class SystemReplacementStrategyCutover {
    @Form([
        Field('cutoverStrategy', String,
                'Cutover (Big Bang, Phased, Parallel Run, Pilot)'),
        Field('rollbackCapability', String, 'Rollback Capability (Full, Partial)'),
        Field('rollbackWindow', String, 'Rollback Window'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A replacement phase entry.
@SectionId('REPPHS')
class ReplacementPhaseEntry {
  @Form([
    Field('phaseNumber', int, 'Phase Number', required: true),
    Field('phaseName', String, 'Phase Name', required: true),
    Field('phaseScope', String, 'Scope'),
    Field('startDate', String, 'Start Date'),
    Field('endDate', String, 'End Date'),
    Field('exitCriteria', String, 'Exit Criteria'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data scope and migration assessment.
@SectionId('SYDASC')
class SystemDataScope {
  @Form([
    Field('totalRecords', String, 'Total Records'),
    Field('dataSize', String, 'Data Size (GB/TB)'),
    Field('growthRate', String, 'Growth Rate'),
    Field('dataTypes', String, 'Data Types (Master, Transactional, etc.)'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Data sensitivity and quality posture.
    @SerializationOrder(1)
    SystemDataScopeGovernance governance = SystemDataScopeGovernance();

    /// Migration preparation and archive handling.
    @SerializationOrder(2)
    SystemDataScopeMigration migration = SystemDataScopeMigration();

  /// Data entities to migrate.
  @SectionId('DEME-ENTI-LST')
  @SectionIdPattern('DEME-ENTI-xxx')
  @SerializationOrder(3)
  List<DataEntityMigrationEntry> entities = [];

  /// Data quality issues to address.
  @SectionId('KNOWN-KNOW-LST')
  @SectionIdPattern('KNOWN-KNOW-xxx')
  @SerializationOrder(4)
  List<KnownQualityIssueEntry> knownQualityIssues = [];
}

/// Data sensitivity and quality posture.
@SectionId('SDSG')
class SystemDataScopeGovernance {
    @Form([
        Field('sensitivityLevel', String,
                'Sensitivity (Public, Internal, Confidential, PII)'),
        Field('retentionRequirements', String, 'Retention Requirements'),
        Field('dataQuality', String, 'Quality Rating (Excellent to Poor)'),
        Field('cleansingRequired', String, 'Cleansing Required'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Migration preparation and archive handling.
@SectionId('SYDASCMI')
class SystemDataScopeMigration {
    @Form([
        Field('deduplicationNeeded', bool, 'Deduplication Needed'),
        Field('transformationComplexity', String, 'Transformation Complexity'),
        Field('migrationScope', String,
                'Scope (Full, Recent, Active records, Reference)'),
        Field('archiveStrategy', String, 'Archive Strategy'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A data entity migration entry.
@SectionId('DAENMIEN')
class DataEntityMigrationEntry {
  @Form([
    Field('entityName', String, 'Entity Name', required: true),
    Field('recordCount', String, 'Record Count'),
    Field('targetMapping', String, 'Target Mapping'),
    Field('transformationNotes', String, 'Transformation Notes'),
    Field('validationRules', String, 'Validation Rules'),
    Field('migrationPriority', String, 'Priority'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A system dependency entry.
///
/// Documents integrations and dependencies with other systems.
@SectionId('REPSDEP')
class ReplacementSystemDependencyEntry {
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
  @SerializationOrder(0)
  String? content;
}

/// User impact assessment.
@SectionId('SYUSIM')
class SystemUserImpact {
  @Form([
    Field('totalUserCount', int, 'Total Users'),
    Field('activeUserCount', int, 'Active Users (last 30 days)'),
    Field('powerUsers', int, 'Power Users'),
    Field('userLocations', String, 'User Locations'),
  ])
  @SerializationOrder(0)
  String? content;

    /// User-facing change profile.
    @SerializationOrder(1)
    SystemUserImpactChangeProfile changeProfile =
            SystemUserImpactChangeProfile();

    /// Training and enablement plan.
    @SerializationOrder(2)
    SystemUserImpactEnablement enablement = SystemUserImpactEnablement();

    /// Communication and adoption support.
    @SerializationOrder(3)
    SystemUserImpactAdoption adoption = SystemUserImpactAdoption();

  /// User groups requiring specific handling.
  @SectionId('UGIE-USER-LST')
  @SectionIdPattern('UGIE-USER-xxx')
  @SerializationOrder(4)
  List<UserGroupImpactEntry> userGroups = [];
}

/// User-facing change profile for system replacement.
@SectionId('SUICP')
class SystemUserImpactChangeProfile {
    @Form([
        Field('workflowChange', String, 'Workflow Change Level'),
        Field('uiChange', String, 'UI Change Level'),
        Field('functionalityChange', String, 'Functionality Change'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Training and enablement plan for impacted users.
@SectionId('SUIE')
class SystemUserImpactEnablement {
    @Form([
        Field('trainingRequired', String, 'Training Required'),
        Field('estimatedTrainingHours', int, 'Training Hours per User'),
        Field('trainingApproach', String, 'Training Approach'),
        Field('trainingMaterials', String, 'Materials Needed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Communication and adoption support for impacted users.
@SectionId('SUIA')
class SystemUserImpactAdoption {
    @Form([
        Field('communicationPlan', String, 'Communication Plan'),
        Field('changeChampions', String, 'Change Champions'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// User group impact entry.
@SectionId('USGRIMEN')
class UserGroupImpactEntry {
  @Form([
    Field('groupName', String, 'User Group', required: true),
    Field('userCount', int, 'User Count'),
    Field('impactLevel', String, 'Impact Level (High, Medium, Low)'),
    Field('specialConsiderations', String, 'Special Considerations'),
    Field('trainingNeeds', String, 'Training Needs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cost analysis for replacement.
@SectionId('SYCOAN')
class SystemCostAnalysis {
  @Form([
    Field('annualLicenseCost', String, 'Annual License Cost'),
    Field('annualMaintenanceCost', String, 'Annual Maintenance Cost'),
    Field('annualOperationsCost', String, 'Annual Operations Cost'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Current-state support and total annual cost.
    @SerializationOrder(1)
    SystemCostAnalysisCurrentCosts currentCosts =
            SystemCostAnalysisCurrentCosts();

    /// One-time migration and transition investments.
    @SerializationOrder(2)
    SystemCostAnalysisMigration migration = SystemCostAnalysisMigration();

    /// Target-state cost and ROI indicators.
    @SerializationOrder(3)
    SystemCostAnalysisBenefits benefits = SystemCostAnalysisBenefits();

  /// Cost breakdown by category if detailed analysis available.
  @SerializationOrder(4)
  TextSection costBreakdown = TextSection();

  /// Non-financial benefits to include in ROI.
  @SectionId('NONFI-NONF-LST')
  @SectionIdPattern('NONFI-NONF-xxx')
  @SerializationOrder(5)
  List<NonFinancialBenefitEntry> nonFinancialBenefits = [];
}

/// Current-state support and total annual cost.
@SectionId('SCACC')
class SystemCostAnalysisCurrentCosts {
    @Form([
        Field('annualSupportCost', String, 'Annual Support Cost'),
        Field('totalCurrentAnnualCost', String, 'Total Current Annual Cost'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// One-time migration and transition investments.
@SectionId('SCAM')
class SystemCostAnalysisMigration {
    @Form([
        Field('migrationProjectCost', String, 'Migration Project Cost'),
        Field('dataConversionCost', String, 'Data Conversion Cost'),
        Field('integrationCost', String, 'Integration Rebuild Cost'),
        Field('trainingCost', String, 'Training Cost'),
        Field('parallelRunCost', String, 'Parallel Run Cost'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Target-state cost and ROI indicators.
@SectionId('SCAB')
class SystemCostAnalysisBenefits {
    @Form([
        Field('newSystemAnnualCost', String, 'New System Annual Cost'),
        Field('annualSavings', String, 'Annual Savings'),
        Field('paybackPeriod', String, 'Payback Period'),
        Field('fiveYearTco', String, '5-Year TCO'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Per-system migration plan.
@SectionId('SYMIPL')
class SystemMigrationPlan {
  @Form([
    Field('migrationApproach', String,
        'Approach (Big Bang, Phased, Parallel, Strangler)'),
    Field('dataTransformationNeeds', String, 'Data Transformation Needs'),
    Field('estimatedEffort', String, 'Estimated Effort'),
    Field('teamSize', String, 'Team Size'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Migration execution and validation details.
    @SerializationOrder(1)
    SystemMigrationPlanExecution execution = SystemMigrationPlanExecution();

    /// Cutover window and business fallback.
    @SerializationOrder(2)
    SystemMigrationPlanCutover cutover = SystemMigrationPlanCutover();

  /// Contains 0+× MigrationRiskEntry — per-system migration risks.
  @SectionId('SMRE-RISK-LST')
  @SectionIdPattern('SMRE-RISK-xxx')
  @SerializationOrder(3)
  List<SystemMigrationRiskEntry> risks = [];

  /// Rollback strategy and procedures.
  @SerializationOrder(4)
  TextSection rollbackStrategy = TextSection();

  /// Post-migration validation steps.
  @SerializationOrder(5)
  TextSection postMigrationValidation = TextSection();
}

/// Migration execution and validation details.
@SectionId('SMPE')
class SystemMigrationPlanExecution {
    @Form([
        Field('duration', String, 'Estimated Duration'),
        Field('testingApproach', String, 'Testing Approach'),
        Field('dataValidationMethod', String, 'Data Validation Method'),
        Field('uatScope', String, 'UAT Scope'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Cutover window and business fallback.
@SectionId('SMPC')
class SystemMigrationPlanCutover {
    @Form([
        Field('cutoverWindow', String, 'Cutover Window'),
        Field('cutoverDuration', String, 'Cutover Duration'),
        Field('businessContingency', String, 'Business Contingency'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A system migration risk entry.
@SectionId('SYMIRIEN')
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
  @SerializationOrder(0)
  String? content;
}

/// Knowledge transfer status.
@SectionId('SYKNTR')
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
  @SerializationOrder(0)
  String? content;

  /// Critical knowledge areas to preserve.
  @SectionId('CRITI-CRIT-LST')
  @SectionIdPattern('CRITI-CRIT-xxx')
  @SerializationOrder(1)
  List<CriticalKnowledgeAreaEntry> criticalKnowledgeAreas = [];

  /// Knowledge transfer plan if SME risk is high.
  @SerializationOrder(2)
  TextSection knowledgeTransferPlan = TextSection();
}

// ---------------------------------------------------------------------------
// 4.4.2. Migration Considerations (Global)
// ---------------------------------------------------------------------------

/// 4.4.2. Migration Considerations (global).
///
/// Cross-system migration concerns covering portfolio-wide strategy,
/// resource planning, and coordination. Complements per-system
/// migration details with global governance.
@SectionId('MIGCON')
@DetailedIn(D01CurrentLandscapeAssessment)
@SecondLevelSectionId(D01CurrentLandscapeAssessment, 'CLA-MIG')
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
  @SerializationOrder(0)
  String? strategyContent;

  /// Detailed strategy narrative.
  @SerializationOrder(1)
  TextSection strategyNarrative = TextSection();

  /// Resource requirements for migration program.
  @SerializationOrder(2)
  MigrationResources resources = MigrationResources();

  /// Migration risks.
  @SerializationOrder(3)
  MigrationRisks migrationRisks = MigrationRisks();

  /// High-level migration timeline.
  @SerializationOrder(4)
  TextSection timeline = TextSection();

  /// Migration milestones.
  @SectionId('MGMLS-MILE-LST')
  @SectionIdPattern('MGMLS-MILE-xxx')
  @SerializationOrder(5)
  List<MigrationMilestoneEntry> milestones = [];

  /// Cross-system data mapping considerations.
  @SerializationOrder(6)
  TextSection dataMapping = TextSection();

  /// Master data management approach during migration.
  @SerializationOrder(7)
  TextSection masterDataApproach = TextSection();

  /// Global rollback strategy and governance.
  @SerializationOrder(8)
  TextSection rollbackStrategy = TextSection();

  /// Go/No-Go decision criteria for each migration.
  @SerializationOrder(9)
  TextSection goNoGosCriteria = TextSection();

  /// Stakeholder communication plan for migration program.
  @SerializationOrder(10)
  TextSection communicationPlan = TextSection();

  /// Escalation procedures during migration.
  @SectionId('ESCAL-ESCA-LST')
  @SectionIdPattern('ESCAL-ESCA-xxx')
  @SerializationOrder(11)
  List<EscalationProcedureEntry> escalationProcedures = [];
}

/// Migration resource requirements.
@SectionId('MIRE')
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
  @SerializationOrder(0)
  String? content;

  /// Resource timeline by phase.
  @SerializationOrder(1)
  TextSection resourceTimeline = TextSection();
}

/// A migration milestone entry.
@SectionId('MGMLS')
class MigrationMilestoneEntry {
  @Form([
    Field('milestoneName', String, 'Milestone Name', required: true),
    Field('targetDate', String, 'Target Date'),
    Field('systemsIncluded', String, 'Systems Included'),
    Field('deliverables', String, 'Deliverables'),
    Field('successCriteria', String, 'Success Criteria'),
    Field('gateName', String, 'Gate Name'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Migration risks — program-level risks.
///
/// Comprehensive migration risk management framework for program-level
/// risks across the entire migration portfolio. Covers risk governance,
/// assessment methodology, monitoring, and escalation procedures.
/// Follows PMI risk management practices and enterprise risk frameworks.
@SectionId('MIRI')
class MigrationRisks {
  @Form([
    Field('riskGovernanceModel', String, 'Risk Governance Model',
        hint: 'Centralized, federated, hybrid approach'),
    Field('riskCommitteeCharter', String, 'Risk Committee Charter'),
    Field('riskReviewFrequency', String, 'Risk Review Frequency',
        hint: 'Weekly, bi-weekly, monthly cycles'),
  ])
  @SerializationOrder(0)
  String? governanceContent;

  /// Governance and decision authority.
  @SerializationOrder(1)
  MigrationRisksGovernance governance = MigrationRisksGovernance();

  /// Assessment methodology settings.
  @SerializationOrder(2)
  MigrationRisksAssessment assessment = MigrationRisksAssessment();

  /// Threshold and trigger settings.
  @SerializationOrder(3)
  MigrationRisksThresholds thresholds = MigrationRisksThresholds();

  /// Reporting settings.
  @SerializationOrder(4)
  MigrationRisksReporting reporting = MigrationRisksReporting();

  /// Risk overview at program level.
  @ContentHelp('Executive summary of migration risk landscape: '
      'critical risks, overall risk posture, trending analysis.')
  @SerializationOrder(5)
  TextSection riskOverview = TextSection();

  /// Risk assessment methodology narrative.
  @ContentHelp('Detailed description of risk assessment approach, '
      'including probability/impact criteria and scoring guidelines.')
  @SerializationOrder(6)
  TextSection assessmentMethodology = TextSection();

  /// Risk categories and taxonomy.
  @SectionId('RISKC-RISK-LST')
  @SectionIdPattern('RISKC-RISK-xxx')
  @SerializationOrder(7)
  List<RiskCategoryEntry> riskCategories = [];

  /// Risk-based decision making criteria.
  @SectionId('RISKB-RISK-LST')
  @SectionIdPattern('RISKB-RISK-xxx')
  @SerializationOrder(8)
  List<RiskBasedDecisionEntry> riskBasedDecisions = [];

  /// Risk monitoring and control procedures.
  @SectionId('MONIT-MONI-LST')
  @SectionIdPattern('MONIT-MONI-xxx')
  @SerializationOrder(9)
  List<MonitoringProcedureEntry> monitoringProcedures = [];

  /// Risk response strategies by category.
  @SectionId('RESPO-RESP-LST')
  @SectionIdPattern('RESPO-RESP-xxx')
  @SerializationOrder(10)
  List<ResponseStrategyEntry> responseStrategies = [];

  /// Risk aggregation and portfolio view.
  @ContentHelp('How individual system risks roll up to program level, '
      'correlation analysis, compound risk assessment.')
  @SerializationOrder(11)
  TextSection riskAggregation = TextSection();

  /// Risk matrix / heat map visualization.
  @ContentHelp('Probability × Impact matrix showing risk distribution.')
  @SerializationOrder(12)
  DiagramSection riskMatrix = DiagramSection();

  /// Risk timeline showing risk exposure over migration phases.
  @ContentHelp('Timeline showing when risks are highest and mitigation points.')
  @SerializationOrder(13)
  GanttDiagramSection riskTimeline = GanttDiagramSection();

  /// Contains 0+× MigrationRiskEntry.
  @SectionId('MGRSK-ITEM-LST')
  @SectionIdPattern('MGRSK-ITEM-xxx')
  @SerializationOrder(14)
  List<MigrationRiskEntry> items = [];
}

/// Governance and decision authority.
@SectionId('MIRIGO')
class MigrationRisksGovernance {
    @Form([
        Field('riskEscalationPath', String, 'Escalation Path',
                hint: 'PM → Steering Committee → Executive Sponsor'),
        Field('riskToleranceLevel', String, 'Risk Tolerance Level',
                hint: 'Enterprise risk appetite for migration'),
        Field('riskDecisionAuthority', String, 'Risk Decision Authority',
                hint: 'Who approves risk acceptance/transfer'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Assessment methodology settings.
@SectionId('MIRIAS')
class MigrationRisksAssessment {
    @Form([
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
    ])
    @SerializationOrder(0)
    String? content;
}

/// Threshold and trigger settings.
@SectionId('MIRITH')
class MigrationRisksThresholds {
    @Form([
        Field('criticalRiskThreshold', String, 'Critical Risk Threshold',
                hint: 'Score ≥ X requires executive attention'),
        Field('highRiskThreshold', String, 'High Risk Threshold'),
        Field('mediumRiskThreshold', String, 'Medium Risk Threshold'),
        Field('emergentRiskTriggers', String, 'Emergent Risk Triggers',
                hint: 'Indicators requiring immediate risk review'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Reporting settings.
@SectionId('MIRIRE')
class MigrationRisksReporting {
    @Form([
        Field('riskReportingCadence', String, 'Reporting Cadence'),
        Field('riskDashboardTools', String, 'Dashboard Tools',
                hint: 'Tools for risk visualization'),
        Field('riskRegisterRepository', String, 'Risk Register Repository',
                hint: 'Where risk register is maintained'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A migration risk entry (form).
///
/// Detailed migration risk documentation following enterprise risk
/// management practices. Captures full risk lifecycle from identification
/// through resolution.
@SectionId('MGRSK')
class MigrationRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID', required: true,
        hint: 'Unique identifier (e.g., MIG-RISK-001)'),
    Field('riskTitle', String, 'Risk Title', required: true,
        hint: 'Concise risk name'),
    Field('riskOwner', String, 'Risk Owner', required: true,
        hint: 'Accountable for risk management'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Risk identification details.
  @SerializationOrder(1)
  MigrationRiskIdentification identification =
      MigrationRiskIdentification();

  /// Probability assessment.
  @SerializationOrder(2)
  MigrationRiskProbability probability = MigrationRiskProbability();

  /// Impact assessment.
  @SerializationOrder(3)
  MigrationRiskImpact impact = MigrationRiskImpact();

  /// Risk quantification.
  @SerializationOrder(4)
  MigrationRiskQuantification quantification =
      MigrationRiskQuantification();

  /// Mitigation strategy.
  @SerializationOrder(5)
  MigrationRiskMitigation mitigation = MigrationRiskMitigation();

  /// Contingency planning.
  @SerializationOrder(6)
  MigrationRiskContingency contingency = MigrationRiskContingency();

  /// Risk indicators and monitoring.
  @SectionId('MIRIIN-INDI-LST')
  @SectionIdPattern('MIRIIN-INDI-xxx')
  @SerializationOrder(7)
  List<MigrationRiskIndicators> indicators = [];

  /// Ownership and tracking.
  @SerializationOrder(8)
  MigrationRiskTracking tracking = MigrationRiskTracking();

  /// Related items.
  @SerializationOrder(9)
  MigrationRiskRelated related = MigrationRiskRelated();

  /// History and lessons learned.
  @SerializationOrder(10)
  MigrationRiskHistory history = MigrationRiskHistory();

  /// Additional risk analysis narrative.
  @ContentHelp('Extended risk analysis, scenario modeling, '
      'or historical context.')
  @SerializationOrder(11)
  TextSection analysisNarrative = TextSection();

  /// Mitigation action items (detailed).
  @ContentHelp('Detailed breakdown of mitigation action items '
      'with owners and deadlines.')
  @SerializationOrder(12)
  TextSection mitigationDetails = TextSection();
}

/// Risk identification details.
@SectionId('MIRIID')
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
  @SerializationOrder(0)
  String? content;
}

/// Probability assessment for migration risk.
@SectionId('MIRIPR')
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
  @SerializationOrder(0)
  String? content;
}

/// Impact assessment for migration risk.
@SectionId('MIRIIM')
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
  @SerializationOrder(0)
  String? content;
}

/// Risk quantification for migration risk.
@SectionId('MIRIQU')
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
  @SerializationOrder(0)
  String? content;
}

/// Mitigation strategy for migration risk.
@SectionId('MIRIMI')
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
  @SerializationOrder(0)
  String? content;
}

/// Contingency planning for migration risk.
@SectionId('MIRICO')
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
  @SerializationOrder(0)
  String? content;
}

/// Risk indicators and monitoring.
@SectionId('MIRIIN')
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
  @SerializationOrder(0)
  String? content;
}

/// Ownership and tracking for migration risk.
@SectionId('MIRITR')
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
  @SerializationOrder(0)
  String? content;
}

/// Related items for migration risk.
@SectionId('MIRIR1')
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
  @SerializationOrder(0)
  String? content;
}

/// History and lessons learned for migration risk.
@SectionId('MIRIHI')
class MigrationRiskHistory {
  @Form([
    Field('previousScores', String, 'Previous Scores',
        hint: 'History of risk scores'),
    Field('previousStatuses', String, 'Previous Statuses',
        hint: 'Status change history'),
    Field('lessonsLearned', String, 'Lessons Learned',
        hint: 'Insights from risk handling'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5 System Boundaries (seeds → IIS)
// ---------------------------------------------------------------------------

/// 4.5. System Boundaries. Seeds → IIS.
///
/// Defines the scope boundaries of the system including external interfaces,
/// out-of-scope items, and operating assumptions. This section provides the
/// foundation for integration planning and scope management. Follows TOGAF
/// system context patterns and enterprise integration best practices.
@SectionId('SYBO')
@Comment('Seeds → IIS')
@MapsTo(D07IntegrationInterfaceSpecification)
class SystemBoundaries {
  /// Overview of system boundaries and scope definition approach.
  @ContentHelp('Provide executive summary of system boundaries: '
      'integration count, scope philosophy, and boundary governance approach.')
  @SerializationOrder(0)
  TextSection overview = TextSection();

  /// 4.5.1. Interfaces to External Systems — contains 0+×.
  @SerializationOrder(1)
  ExternalInterfaces externalInterfaces = ExternalInterfaces();

  /// 4.5.2. Out of Scope — contains 0+×.
  @SerializationOrder(2)
  OutOfScope outOfScope = OutOfScope();

  /// 4.5.3. Assumptions — contains 0+×.
  @SerializationOrder(3)
  BoundaryAssumptions assumptions = BoundaryAssumptions();

  /// 4.5.4. System Landscape Inventory. Covers IIS-LAN-INV.
  @SerializationOrder(4)
  SystemLandscapeInventory systemLandscapeInventory = SystemLandscapeInventory();

  /// 4.5.5. Boundary Interaction Patterns. Covers IIS-PAT.
  @SectionId('BOINPA-BOUN-LST')
  @SectionIdPattern('BOINPA-BOUN-xxx')
  @SerializationOrder(5)
  List<BoundaryInteractionPatterns> boundaryInteractionPatterns = [];

  /// 4.5.6. Interaction Testing Strategy. Covers IIS-TST.
  @SerializationOrder(6)
  InteractionTestingStrategy interactionTestingStrategy =
      InteractionTestingStrategy();

  /// 4.5.7. Interaction Dependency Analysis. Covers IIS-DEP.
  @SerializationOrder(7)
  InteractionDependencyAnalysis interactionDependencyAnalysis =
      InteractionDependencyAnalysis();

  /// 4.5.8. Migration Interactions. Covers IIS-MIG.
  @SectionId('MIIN-MIGR-LST')
  @SectionIdPattern('MIIN-MIGR-xxx')
  @SerializationOrder(8)
  List<MigrationInteractions> migrationInteractions = [];

  /// 4.5.9. Cross-Boundary Operational Considerations.
  @SectionId('CBOC-OPER-LST')
  @SectionIdPattern('CBOC-OPER-xxx')
  @SerializationOrder(9)
  List<CrossBoundaryOperationalConsiderations> operationalConsiderations = [];

  /// 4.5.10. Cross-Boundary Error Handling.
  @SerializationOrder(10)
  CrossBoundaryErrorHandling crossBoundaryErrorHandling =
      CrossBoundaryErrorHandling();
}

// ---------------------------------------------------------------------------
// 4.5.1. External Interfaces
// ---------------------------------------------------------------------------

/// Container for external interface definitions.
///
/// Provides structured inventory of all external system integrations with
/// categorization, prioritization, and governance information. Each interface
/// seeds detailed specification in the IIS (Integration & Interface
/// Specification) document. Follows enterprise integration patterns (EIP) and
/// API-first design principles.
@SectionId('EXIN')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-INT')
class ExternalInterfaces {
  /// Summary of the integration landscape.
  @ContentHelp('Summarize integration portfolio: total count by category, '
      'strategic vs tactical integrations, integration platform approach.')
  @SerializationOrder(0)
  TextSection integrationSummary = TextSection();

  /// Integration architecture approach.
  @ContentHelp('Describe integration patterns: point-to-point vs hub, '
      'synchronous vs async, API gateway usage, message broker approach.')
  @SerializationOrder(1)
  TextSection architectureApproach = TextSection();

  /// Integration governance model.
  @ContentHelp('Describe integration governance: ownership model, '
      'change control process, versioning strategy, deprecation policy.')
  @SerializationOrder(2)
  TextSection governanceModel = TextSection();

  /// Contains 0+× ExternalInterfaceEntry.
  @SectionId('EXINEN-INTE-LST')
  @SectionIdPattern('EXINEN-INTE-xxx')
  @SerializationOrder(3)
  List<ExternalInterfaceEntry> interfaces = [];
}

/// An external interface entry (form).
///
/// Comprehensive documentation of an external system interface covering
/// identification, technical details, data exchange specification, security,
/// operational characteristics, and contractual governance. Follows
/// OpenAPI/AsyncAPI patterns for API documentation and enterprise
/// integration best practices.
@SectionId('EIE')
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
  @SerializationOrder(0)
  String? identificationContent;

  /// Business purpose and value of this interface.
  @SerializationOrder(1)
  InterfaceBusinessContext businessContext = InterfaceBusinessContext();

  // -------------------------------------------------------------------------
  // Technical Specification
  // -------------------------------------------------------------------------

  /// Technical details of the interface.
  @SerializationOrder(2)
  InterfaceTechnicalSpec technicalSpec = InterfaceTechnicalSpec();

  // -------------------------------------------------------------------------
  // Data Specification
  // -------------------------------------------------------------------------

  /// Data exchange specification.
  @SerializationOrder(3)
  InterfaceDataSpec dataSpec = InterfaceDataSpec();

  // -------------------------------------------------------------------------
  // Security & Authentication
  // -------------------------------------------------------------------------

  /// Security and authentication requirements.
  @SerializationOrder(4)
  InterfaceSecurity security = InterfaceSecurity();

  // -------------------------------------------------------------------------
  // Operational Characteristics
  // -------------------------------------------------------------------------

  /// Operational and SLA requirements.
  @SerializationOrder(5)
  InterfaceOperational operational = InterfaceOperational();

  // -------------------------------------------------------------------------
  // Error Handling
  // -------------------------------------------------------------------------

  /// Error handling and resilience.
  @SerializationOrder(6)
  InterfaceErrorHandling errorHandling = InterfaceErrorHandling();

  // -------------------------------------------------------------------------
  // Governance & Contracts
  // -------------------------------------------------------------------------

  /// Contractual and governance information.
  @SerializationOrder(7)
  InterfaceGovernance governance = InterfaceGovernance();

  // -------------------------------------------------------------------------
  // Testing & Environments
  // -------------------------------------------------------------------------

  /// Testing and environment information.
  @SerializationOrder(8)
  InterfaceTesting testing = InterfaceTesting();
}

/// Business context for an interface.
@SectionId('INBUCO')
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
  @SerializationOrder(0)
  String? content;

  /// Business processes that depend on this interface.
  @SectionId('IBPE-DEPE-LST')
  @SectionIdPattern('IBPE-DEPE-xxx')
  @SerializationOrder(1)
  List<InterfaceBusinessProcessEntry> dependentProcesses = [];
}

/// Business process dependency entry.
@SectionId('INBUPREN')
class InterfaceBusinessProcessEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('processId', String, 'Process ID'),
    Field('dependencyType', String, 'Dependency (Critical Path, Supporting)'),
    Field('fallbackBehavior', String, 'Fallback if Interface Unavailable'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Technical specification for an interface.
@SectionId('INTESP')
class InterfaceTechnicalSpec {
  @Form([
    Field('protocol', String,
        'Protocol (REST/HTTPS, SOAP/HTTPS, gRPC, GraphQL, SFTP, etc.)'),
    Field('transportSecurity', String, 'Transport Security (TLS 1.2, TLS 1.3)'),
    Field('messageFormat', String, 'Message Format (JSON, XML, Protobuf, CSV)'),
    Field('encoding', String, 'Character Encoding (UTF-8, etc.)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Directionality and messaging pattern.
  @SerializationOrder(1)
  InterfaceTechnicalSpecCommunication communication =
      InterfaceTechnicalSpecCommunication();

  /// Endpoint and documentation references.
  @SerializationOrder(2)
  InterfaceTechnicalSpecEndpoints endpoints =
      InterfaceTechnicalSpecEndpoints();

  /// API operations/methods exposed or consumed.
  @SectionId('INOPEN-OPER-LST')
  @SectionIdPattern('INOPEN-OPER-xxx')
  @SerializationOrder(3)
  List<InterfaceOperationEntry> operations = [];

  /// Webhook/callback configurations if applicable.
  @SerializationOrder(4)
  InterfaceWebhookSpec webhookSpec = InterfaceWebhookSpec();
}

/// Directionality and messaging pattern.
@SectionId('ITSC')
class InterfaceTechnicalSpecCommunication {
    @Form([
        Field('direction', String, 'Direction (Inbound, Outbound, Bidirectional)'),
        Field('initiator', String, 'Initiator (Our System, External System)'),
        Field('communicationStyle', String,
                'Style (Synchronous, Asynchronous, Event-Driven)'),
        Field('deliveryGuarantee', String,
                'Delivery (At-most-once, At-least-once, Exactly-once)'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Endpoint and documentation references.
@SectionId('ITSE')
class InterfaceTechnicalSpecEndpoints {
    @Form([
        Field('baseEndpoint', String, 'Base URL/Endpoint'),
        Field('apiVersion', String, 'API Version'),
        Field('documentationUrl', String, 'API Documentation URL'),
        Field('sandboxEndpoint', String, 'Sandbox/Test Endpoint'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// API operation entry.
@SectionId('IOE')
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
  @SerializationOrder(0)
  String? content;
}

/// Webhook specification.
@SectionId('INWESP')
class InterfaceWebhookSpec {
  @Form([
    Field('webhooksUsed', bool, 'Webhooks/Callbacks Used'),
    Field('webhookEndpoint', String, 'Our Webhook Endpoint'),
    Field('eventTypes', String, 'Event Types Received'),
    Field('signatureVerification', String, 'Signature Verification Method'),
    Field('retryPolicy', String, 'External System Retry Policy'),
    Field('idempotencyHandling', String, 'Idempotency Handling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data specification for an interface.
@SectionId('INDASP')
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
  @SerializationOrder(0)
  String? content;

  /// Data entities exchanged.
  @SectionId('IDEE-DATA-LST')
  @SectionIdPattern('IDEE-DATA-xxx')
  @SerializationOrder(1)
  List<InterfaceDataEntityEntry> dataEntities = [];

  /// Data mapping and transformation rules.
  @SectionId('MAPPI-MAPP-LST')
  @SectionIdPattern('MAPPI-MAPP-xxx')
  @SerializationOrder(2)
  List<MappingRuleEntry> mappingRules = [];

  /// Data validation rules.
  @SectionId('VALID-VALI-LST')
  @SectionIdPattern('VALID-VALI-xxx')
  @SerializationOrder(3)
  List<ValidationRuleEntry> validationRules = [];
}

/// Data entity exchanged.
@SectionId('INDAENEN')
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
  @SerializationOrder(0)
  String? content;
}

/// Security specification for an interface.
@SectionId('IS')
class InterfaceSecurity {
  @Form([
    Field('authMethod', String,
        'Authentication (API Key, OAuth 2.0, mTLS, Basic, SAML, etc.)'),
    Field('authDetails', String, 'Authentication Details'),
    Field('credentialStorage', String, 'Credential Storage Method'),
    Field('credentialRotation', String, 'Credential Rotation Policy'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Authorization boundaries.
    @SerializationOrder(1)
    InterfaceSecurityAuthorization authorization =
            InterfaceSecurityAuthorization();

    /// Encryption controls.
    @SerializationOrder(2)
    InterfaceSecurityEncryption encryption = InterfaceSecurityEncryption();

    /// Compliance and audit expectations.
    @SerializationOrder(3)
    InterfaceSecurityCompliance compliance = InterfaceSecurityCompliance();

  /// Security contacts and escalation.
  @SerializationOrder(4)
  TextSection securityContacts = TextSection();
}

/// Authorization boundaries for an interface.
@SectionId('INSEAU')
class InterfaceSecurityAuthorization {
    @Form([
        Field('authorizationModel', String, 'Authorization Model'),
        Field('scopesPermissions', String, 'Scopes/Permissions Required'),
        Field('ipWhitelisting', String, 'IP Whitelisting Required'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Encryption controls for an interface.
@SectionId('INSEEN')
class InterfaceSecurityEncryption {
    @Form([
        Field('encryptionInTransit', String, 'Encryption in Transit'),
        Field('encryptionAtRest', String, 'Encryption at Rest (if applicable)'),
        Field('fieldLevelEncryption', String, 'Field-Level Encryption'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Compliance and audit expectations for an interface.
@SectionId('INSECO')
class InterfaceSecurityCompliance {
    @Form([
        Field('complianceRequirements', String,
                'Compliance (PCI-DSS, HIPAA, GDPR, SOC2, etc.)'),
        Field('auditLogging', String, 'Audit Logging Requirements'),
        Field('dataResidency', String, 'Data Residency Requirements'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Operational characteristics.
@SectionId('INOP')
class InterfaceOperational {
  @Form([
    Field('availabilitySla', String, 'Availability SLA (e.g., 99.9%)'),
    Field('scheduledDowntime', String, 'Scheduled Downtime Windows'),
    Field('responseTimeSla', String, 'Response Time SLA (e.g., p95 < 200ms)'),
    Field('throughputSla', String, 'Throughput SLA'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Rate limiting rules.
    @SerializationOrder(1)
    InterfaceOperationalRateLimiting rateLimiting =
            InterfaceOperationalRateLimiting();

    /// Monitoring configuration.
    @SerializationOrder(2)
    InterfaceOperationalMonitoring monitoring = InterfaceOperationalMonitoring();

    /// Support model.
    @SerializationOrder(3)
    InterfaceOperationalSupport support = InterfaceOperationalSupport();

  /// Operational dependencies.
  @SectionId('DEPEN-DEPE-LST')
  @SectionIdPattern('DEPEN-DEPE-xxx')
  @SerializationOrder(4)
  List<DependencyEntry> dependencies = [];
}

/// Rate limiting rules.
@SectionId('IORL')
class InterfaceOperationalRateLimiting {
    @Form([
        Field('rateLimits', String, 'Rate Limits (requests/minute)'),
        Field('quotaLimits', String, 'Quota Limits (requests/day)'),
        Field('burstCapacity', String, 'Burst Capacity'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Monitoring configuration.
@SectionId('INOPMO')
class InterfaceOperationalMonitoring {
    @Form([
        Field('healthCheckEndpoint', String, 'Health Check Endpoint'),
        Field('statusPageUrl', String, 'Status Page URL'),
        Field('monitoringApproach', String, 'Monitoring Approach'),
        Field('alertingThresholds', String, 'Alerting Thresholds'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Support model.
@SectionId('INOPSU')
class InterfaceOperationalSupport {
    @Form([
        Field('supportHours', String, 'Support Hours'),
        Field('supportContact', String, 'Support Contact'),
        Field('incidentProcess', String, 'Incident Process'),
        Field('escalationPath', String, 'Escalation Path'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Error handling specification.
@SectionId('INERHA')
class InterfaceErrorHandling {
  @Form([
    // Error Responses
    Field('errorFormat', String, 'Error Response Format'),
    Field('errorCodes', String, 'Error Codes Used'),
    Field('retryableErrors', String, 'Retryable Error Codes'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Non-retryable errors and retry strategy.
    @SerializationOrder(1)
    InterfaceErrorHandlingRetry retry = InterfaceErrorHandlingRetry();

    /// Fallback behavior and manual recovery.
    @SerializationOrder(2)
    InterfaceErrorHandlingFallback fallback = InterfaceErrorHandlingFallback();

    /// Connection and transaction timeouts.
    @SerializationOrder(3)
    InterfaceErrorHandlingTimeout timeout = InterfaceErrorHandlingTimeout();

  /// Error handling procedures.
  @SectionId('ERROR-ERRO-LST')
  @SectionIdPattern('ERROR-ERRO-xxx')
  @SerializationOrder(4)
  List<ErrorProcedureEntry> errorProcedures = [];
}

/// Non-retryable errors and retry strategy.
@SectionId('IEHR')
class InterfaceErrorHandlingRetry {
    @Form([
        Field('fatalErrors', String, 'Fatal/Non-Retryable Errors'),
        Field('retryStrategy', String, 'Retry Strategy (Exponential backoff, etc.)'),
        Field('maxRetries', int, 'Max Retries'),
        Field('retryInterval', String, 'Retry Interval'),
        Field('circuitBreakerConfig', String, 'Circuit Breaker Configuration'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Fallback behavior and manual recovery.
@SectionId('IEHF')
class InterfaceErrorHandlingFallback {
    @Form([
        Field('fallbackBehavior', String, 'Fallback Behavior'),
        Field('degradedMode', String, 'Degraded Mode Operation'),
        Field('manualRecovery', String, 'Manual Recovery Procedure'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Connection and transaction timeouts.
@SectionId('IEHT')
class InterfaceErrorHandlingTimeout {
    @Form([
        Field('connectionTimeout', String, 'Connection Timeout'),
        Field('readTimeout', String, 'Read Timeout'),
        Field('overallTimeout', String, 'Overall Transaction Timeout'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Governance and contracts.
@SectionId('INGO')
class InterfaceGovernance {
  @Form([
    Field('externalOwner', String, 'External System Owner'),
    Field('internalOwner', String, 'Internal Owner/Steward'),
    Field('technicalContact', String, 'Technical Contact'),
    Field('businessContact', String, 'Business Contact'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Contract and commercial terms.
    @SerializationOrder(1)
    InterfaceGovernanceContract contract = InterfaceGovernanceContract();

    /// Change management expectations.
    @SerializationOrder(2)
    InterfaceGovernanceLifecycle lifecycle = InterfaceGovernanceLifecycle();

  /// Integration changelog.
  @SerializationOrder(3)
  TextSection changelog = TextSection();
}

/// Contract and commercial terms for an interface.
@SectionId('INGOCO')
class InterfaceGovernanceContract {
    @Form([
        Field('contractType', String, 'Contract Type (SLA, Agreement, Partnership)'),
        Field('contractExpiry', String, 'Contract Expiry Date'),
        Field('renewalTerms', String, 'Renewal Terms'),
        Field('costModel', String, 'Cost Model (Per-call, Subscription, etc.)'),
        Field('estimatedCost', String, 'Estimated Monthly/Annual Cost'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Change management expectations for an interface.
@SectionId('INGOLI')
class InterfaceGovernanceLifecycle {
    @Form([
        Field('versioningStrategy', String, 'Versioning Strategy'),
        Field('deprecationPolicy', String, 'Deprecation Policy'),
        Field('changeNotificationLead', String, 'Change Notification Lead Time'),
        Field('breakingChangePolicy', String, 'Breaking Change Policy'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Testing specification.
@SectionId('INTE')
class InterfaceTesting {
  @Form([
    Field('sandboxAvailable', bool, 'Sandbox Environment Available'),
    Field('sandboxUrl', String, 'Sandbox URL'),
    Field('testCredentials', String, 'Test Credentials Approach'),
    Field('mockAvailable', bool, 'Mock/Stub Available'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Test data strategy.
    @SerializationOrder(1)
    InterfaceTestingData data = InterfaceTestingData();

    /// Validation approach across test layers.
    @SerializationOrder(2)
    InterfaceTestingStrategy strategy = InterfaceTestingStrategy();

  /// Test scenarios.
  @SectionId('ITSE1-TEST-LST')
  @SectionIdPattern('ITSE1-TEST-xxx')
  @SerializationOrder(3)
  List<InterfaceTestScenarioEntry> testScenarios = [];
}

/// Test data strategy.
@SectionId('INTEDA')
class InterfaceTestingData {
    @Form([
        Field('testDataApproach', String, 'Test Data Approach'),
        Field('syntheticDataSupport', bool, 'Synthetic Data Supported'),
        Field('productionMirror', bool, 'Production Data Mirroring'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Validation approach across test layers.
@SectionId('INTEST')
class InterfaceTestingStrategy {
    @Form([
        Field('unitTestApproach', String, 'Unit Test Approach'),
        Field('integrationTestApproach', String, 'Integration Test Approach'),
        Field('contractTestApproach', String, 'Contract Test Approach'),
        Field('e2eTestApproach', String, 'E2E Test Approach'),
        Field('performanceTestApproach', String, 'Performance Test Approach'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Test scenario entry.
@SectionId('INTESCEN')
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
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.2. Out of Scope
// ---------------------------------------------------------------------------

/// 4.5.2. Out of Scope.
///
/// Explicit documentation of functionality, systems, and integrations that
/// are excluded from the project scope. Provides clear boundaries and
/// rationale to prevent scope creep and manage stakeholder expectations.
@SectionId('OUOFSC')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-OUT')
class OutOfScope {
  /// Overview of scope exclusion approach.
  @ContentHelp('Describe the scope philosophy and how exclusions were '
      'determined. Reference any scope workshops or decision records.')
  @SerializationOrder(0)
  TextSection scopePhilosophy = TextSection();

  /// Contains 0+× OutOfScopeEntry.
  @SectionId('OOSE-ITEM-LST')
  @SectionIdPattern('OOSE-ITEM-xxx')
  @SerializationOrder(1)
  List<OutOfScopeEntry> items = [];
}

/// An out-of-scope entry (form).
@SectionId('OUOFSCEN')
class OutOfScopeEntry {
  @Form([
    Field('itemId', String, 'Item ID'),
    Field('item', String, 'Out of Scope Item', required: true),
    Field('itemType', String,
        'Type (Feature, Integration, System, Process, Data)'),
    Field('rationale', String, 'Exclusion Rationale'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Decision history and future reconsideration.
    @SerializationOrder(1)
    OutOfScopeEntryDecision decision = OutOfScopeEntryDecision();

    /// Alternatives and inclusion risk.
    @SerializationOrder(2)
    OutOfScopeEntryMitigation mitigation = OutOfScopeEntryMitigation();
}

/// Decision history and future reconsideration.
@SectionId('OOSED')
class OutOfScopeEntryDecision {
    @Form([
        Field('requestedBy', String, 'Originally Requested By'),
        Field('decisionMaker', String, 'Decision Maker'),
        Field('decisionDate', String, 'Decision Date'),
        Field('futureConsideration', String,
                'Future Consideration (Yes, No, Maybe)'),
        Field('targetPhase', String, 'Target Phase (if future)'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Alternatives and inclusion risk.
@SectionId('OOSEM')
class OutOfScopeEntryMitigation {
    @Form([
        Field('alternativeSolution', String, 'Alternative/Workaround'),
        Field('riskIfIncluded', String, 'Risk if Included'),
    ])
    @SerializationOrder(0)
    String? content;
}

// ---------------------------------------------------------------------------
// 4.5.3. Assumptions
// ---------------------------------------------------------------------------

/// 4.5.3. Assumptions.
///
/// Documents assumptions about external systems, data availability,
/// organizational readiness, and third-party services that must hold true
/// for the project to succeed. Each assumption should be validated and
/// tracked as a potential risk if proven incorrect.
@SectionId('BOAS')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-ASS')
class BoundaryAssumptions {
  /// Overview of assumption categories and validation approach.
  @ContentHelp('Describe assumption categories, validation timeline, '
      'and impact assessment approach for assumption failures.')
  @SerializationOrder(0)
  TextSection assumptionApproach = TextSection();

  /// Contains 0+× BoundaryAssumptionEntry.
  @SectionId('BOASEN-ITEM-LST')
  @SectionIdPattern('BOASEN-ITEM-xxx')
  @SerializationOrder(1)
  List<BoundaryAssumptionEntry> items = [];
}

/// A boundary assumption entry (form).
@SectionId('BAE')
class BoundaryAssumptionEntry {
  @Form([
    Field('assumptionId', String, 'Assumption ID'),
    Field('assumption', String, 'Assumption Statement', required: true),
    Field('category', String,
        'Category (Technical, Organizational, External, Data, Resource)'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Validation ownership and confidence.
    @SerializationOrder(1)
    BoundaryAssumptionEntryValidation validation =
            BoundaryAssumptionEntryValidation();

    /// Risk framing and contingency planning.
    @SerializationOrder(2)
    BoundaryAssumptionEntryRisk risk = BoundaryAssumptionEntryRisk();
}

/// Validation ownership and confidence for a boundary assumption.
@SectionId('BAEV')
class BoundaryAssumptionEntryValidation {
    @Form([
        Field('rationale', String, 'Basis for Assumption'),
        Field('owner', String, 'Assumption Owner'),
        Field('validationMethod', String, 'Validation Method'),
        Field('validationDate', String, 'Target Validation Date'),
        Field('validationStatus', String,
                'Status (Not Validated, Validated, Invalidated)'),
        Field('confidence', String, 'Confidence Level (High, Medium, Low)'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Risk framing and contingency planning for a boundary assumption.
@SectionId('BAER')
class BoundaryAssumptionEntryRisk {
    @Form([
        Field('riskIfWrong', String, 'Risk if Wrong'),
        Field('riskImpact', String, 'Impact Level (High, Medium, Low)'),
        Field('contingencyPlan', String, 'Contingency Plan'),
        Field('relatedRiskId', String, 'Related Risk ID'),
    ])
    @SerializationOrder(0)
    String? content;
}

// ---------------------------------------------------------------------------
// 4.6 Operating Environment
// ---------------------------------------------------------------------------

/// 4.6. Operating Environment.
///
/// Documents the organizational and technical environment in which the system
/// will operate. Covers organizational structure, functional responsibilities,
/// technical constraints, and external dependencies. Follows TOGAF enterprise
/// context patterns and PMBOK environmental factors analysis.
@SectionId('FRCO')
class OperatingEnvironment {
  /// Framework conditions overview.
  @ContentHelp('Provide executive summary of the operating environment: '
      'organizational context, technical landscape, key constraints, '
      'and critical dependencies affecting project execution.')
  @SerializationOrder(0)
  TextSection overview = TextSection();

  /// 4.6.1. Organizational Environment.
  @SerializationOrder(1)
  OrganizationalEnvironment organizationalEnvironment =
      OrganizationalEnvironment();

  /// 4.6.2. Functional Responsibilities — contains 0+×.
  @SerializationOrder(2)
  FunctionalResponsibilities functionalResponsibilities =
      FunctionalResponsibilities();

  /// 4.6.3. Technical Environment. Seeds → ATS.
  @Comment('Seeds → ATS')
  @SerializationOrder(3)
  TechnicalEnvironment technicalEnvironment =
      TechnicalEnvironment();

  /// 4.6.4. Constraints and Dependencies — contains 0+×.
  @SerializationOrder(4)
  ConstraintsAndDependencies constraintsAndDependencies =
      ConstraintsAndDependencies();
}

/// 4.6.1. Organizational Environment.
///
/// Describes the organizational context in which the system will operate,
/// including departments, reporting structures, decision authority, and
/// organizational constraints. Follows organizational design principles
/// and enterprise architecture governance patterns.
@SectionId('OREN')
class OrganizationalEnvironment {
  // -------------------------------------------------------------------------
  // Organizational Overview
  // -------------------------------------------------------------------------
  @Form([
    Field('organizationName', String, 'Organization Name'),
    Field('organizationType', String,
        'Organization Type (Enterprise, SMB, Startup, Government, Non-profit)'),
    Field('industryVertical', String,
        'Industry Vertical (Finance, Healthcare, Retail, Tech, etc.)'),
    Field('geographicFootprint', String,
        'Geographic Footprint (Local, National, Regional, Global)'),
    Field('employeeCount', String, 'Employee Count'),
    Field('revenueRange', String, 'Revenue Range'),
  ])
  @SerializationOrder(0)
  String? organizationContent;

  /// Organizational maturity indicators.
  @SerializationOrder(1)
  OrganizationalEnvironmentMaturity maturity =
      OrganizationalEnvironmentMaturity();

  /// Decision-making context.
  @SerializationOrder(2)
  OrganizationalEnvironmentDecisionMaking decisionMakingContext =
      OrganizationalEnvironmentDecisionMaking();

  // -------------------------------------------------------------------------
  // Organizational Structure
  // -------------------------------------------------------------------------

  /// Detailed organizational structure narrative.
  @ContentHelp('Describe the organizational structure: departments involved, '
      'reporting relationships, matrix structures, and how the project '
      'intersects with existing organization.')
  @SerializationOrder(3)
  TextSection structure = TextSection();

  /// Departments and business units affected.
  @SectionId('AFDEEN-AFFE-LST')
  @SectionIdPattern('AFDEEN-AFFE-xxx')
  @SerializationOrder(4)
  List<AffectedDepartmentEntry> affectedDepartments = [];

  // -------------------------------------------------------------------------
  // Decision Making & Governance
  // -------------------------------------------------------------------------

  /// Decision making processes and authority.
  @ContentHelp('Describe decision-making processes: governance boards, '
      'approval workflows, decision criteria, and timeline expectations '
      'for different decision types.')
  @SerializationOrder(5)
  TextSection decisionMaking = TextSection();

  /// Key decision makers and their roles.
  @SectionId('DEMAEN-DECI-LST')
  @SectionIdPattern('DEMAEN-DECI-xxx')
  @SerializationOrder(6)
  List<DecisionMakerEntry> decisionMakers = [];

  // -------------------------------------------------------------------------
  // Cultural Context
  // -------------------------------------------------------------------------

  /// Cultural considerations and organizational dynamics.
  @SectionId('CULTU-CULT-LST')
  @SectionIdPattern('CULTU-CULT-xxx')
  @SerializationOrder(7)
  List<CulturalConsiderationEntry> culturalConsiderations = [];

  /// Stakeholder communication preferences.
  @SectionId('COMMU-COMM-LST')
  @SectionIdPattern('COMMU-COMM-xxx')
  @SerializationOrder(8)
  List<CommunicationPreferenceEntry> communicationPreferences = [];

  // -------------------------------------------------------------------------
  // Political Landscape
  // -------------------------------------------------------------------------

  /// Political dynamics and influence patterns.
  @ContentHelp('Describe organizational politics: power centers, influence '
      'networks, historical project outcomes, and potential resistance points.')
  @SerializationOrder(9)
  TextSection politicalLandscape = TextSection();

  /// Change champions and sponsors.
  @SectionId('CHANG-CHAN-LST')
  @SectionIdPattern('CHANG-CHAN-xxx')
  @SerializationOrder(10)
  List<ChangeAdvocateEntry> changeAdvocates = [];
}

/// Organizational maturity indicators.
@SectionId('ORENMA')
class OrganizationalEnvironmentMaturity {
    @Form([
        Field('digitalMaturityLevel', String,
                'Digital Maturity (Nascent, Developing, Defined, Optimizing, Leading)'),
        Field('changeReadiness', String,
                'Change Readiness (Low, Medium, High)'),
        Field('projectManagementMaturity', String,
                'PM Maturity (Ad-hoc, Repeatable, Defined, Managed, Optimizing)'),
        Field('itGovernanceMaturity', String,
                'IT Governance Maturity (Initial, Repeatable, Defined, Managed)'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Decision-making context.
@SectionId('OEDM')
class OrganizationalEnvironmentDecisionMaking {
    @Form([
        Field('decisionMakingStyle', String,
                'Decision Style (Centralized, Federated, Consensus, Delegated)'),
        Field('approvalLevels', String, 'Approval Levels/Hierarchy'),
        Field('escalationPath', String, 'Escalation Path'),
        Field('budgetAuthority', String, 'Budget Authority Structure'),
        Field('procurementProcess', String, 'Procurement Process Type'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// An affected department entry.
@SectionId('ADE')
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
  @SerializationOrder(0)
  String? content;
}

/// A decision maker entry.
@SectionId('DME')
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
  @SerializationOrder(0)
  String? content;
}

/// 4.6.2. Functional Responsibilities.
///
/// Maps system functions to organizational units responsible for them.
/// Identifies domain owners, data stewards, and operational contacts for
/// each function area. Follows RACI matrix patterns and enterprise
/// accountability frameworks.
@SectionId('FURE')
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
  @SerializationOrder(0)
  String? content;

  /// Responsibility matrix overview narrative.
  @ContentHelp('Describe the overall approach to functional responsibility '
      'assignment: governance model, cross-functional coordination, '
      'conflict resolution, and ongoing maintenance.')
  @SerializationOrder(1)
  TextSection matrixOverview = TextSection();

  /// Contains 0+× Responsibility.
  @SectionId('REEN1-ITEM-LST')
  @SectionIdPattern('REEN1-ITEM-xxx')
  @SerializationOrder(2)
  List<ResponsibilityEntry> items = [];
}

/// A responsibility entry (form).
///
/// Documents responsibility assignment for a specific functional area,
/// following RACI principles (Responsible, Accountable, Consulted, Informed)
/// with additional operational details for clear accountability.
@SectionId('RE')
class ResponsibilityEntry {
  @Form([
    Field('functionId', String, 'Function ID', required: true,
        hint: 'Unique identifier, e.g. FUNC-001'),
    Field('functionName', String, 'Function Name', required: true,
        hint: 'Short descriptive name'),
    Field('functionArea', String, 'Functional Area',
        hint: 'Sales, Marketing, Finance, HR, Operations, IT'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Function details and scope.
  @SectionId('REFUDE-FUNC-LST')
  @SectionIdPattern('REFUDE-FUNC-xxx')
  @SerializationOrder(1)
  List<ResponsibilityFunctionDetails> functionDetails = [];

  /// RACI assignment.
  @SerializationOrder(2)
  ResponsibilityRaci raci = ResponsibilityRaci();

  /// Key contacts.
  @SectionId('RECO-CONT-LST')
  @SectionIdPattern('RECO-CONT-xxx')
  @SerializationOrder(3)
  List<ResponsibilityContacts> contacts = [];

  /// Related systems and data.
  @SectionId('RESY-SYST-LST')
  @SectionIdPattern('RESY-SYST-xxx')
  @SerializationOrder(4)
  List<ResponsibilitySystems> systems = [];

  /// Governance and transition.
  @SerializationOrder(5)
  ResponsibilityGovernance governance = ResponsibilityGovernance();
}

/// Function details and scope.
@SectionId('REFUDE')
class ResponsibilityFunctionDetails {
  @Form([
    Field('functionDescription', String, 'Description',
        hint: 'Detailed description of the functional responsibility'),
    Field('functionScope', String, 'Scope',
        hint: 'Boundaries of this functional responsibility'),
    Field('businessCriticality', String, 'Business Criticality',
        hint: 'Critical, High, Medium, Low'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// RACI assignment.
@SectionId('RERA')
class ResponsibilityRaci {
  @Form([
    Field('responsible', String, 'Responsible (R)',
        hint: 'Role/team who does the work', required: true),
    Field('accountable', String, 'Accountable (A)',
        hint: 'Role/person ultimately accountable'),
    Field('consulted', String, 'Consulted (C)',
        hint: 'Roles/teams who provide input'),
    Field('informed', String, 'Informed (I)',
        hint: 'Roles/teams who are kept updated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Key contacts.
@SectionId('RECO')
class ResponsibilityContacts {
  @Form([
    Field('domainOwner', String, 'Domain Owner',
        hint: 'Business owner for this functional area'),
    Field('datasteward', String, 'Data Steward',
        hint: 'Person responsible for data quality'),
    Field('operationalContact', String, 'Operational Contact',
        hint: 'Day-to-day operational contact'),
    Field('technicalContact', String, 'Technical Contact',
        hint: 'Technical SME for this area'),
    Field('escalationContact', String, 'Escalation Contact',
        hint: 'Contact for escalation of issues'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Related systems and data.
@SectionId('RESY')
class ResponsibilitySystems {
  @Form([
    Field('primarySystems', String, 'Primary Systems',
        hint: 'Systems primarily used for this function'),
    Field('dataOwnership', String, 'Data Ownership',
        hint: 'Data entities owned by this function'),
    Field('processOwnership', String, 'Process Ownership',
        hint: 'Business processes owned by this function'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance and transition.
@SectionId('REGO')
class ResponsibilityGovernance {
  @Form([
    Field('governanceLevel', String, 'Governance Level',
        hint: 'Central, federated, local'),
    Field('decisionAuthority', String, 'Decision Authority',
        hint: 'What decisions this function can make autonomously'),
    Field('approvalRequired', String, 'Approval Required',
        hint: 'What requires approval and from whom'),
    Field('complianceRole', String, 'Compliance Role',
        hint: 'Regulatory or compliance responsibilities'),
    Field('currentState', String, 'Current State',
        hint: 'How responsibility is handled currently'),
    Field('futureState', String, 'Future State',
        hint: 'How responsibility will be handled post-implementation'),
    Field('transitionPlan', String, 'Transition Plan',
        hint: 'Plan for transitioning responsibility'),
    Field('trainingNeeds', String, 'Training Needs',
        hint: 'Training required for responsibility transition'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.6.3. Technical Environment. Seeds → ATS.
///
/// Documents pre-existing technical constraints including mandated platforms,
/// network restrictions, compliance requirements, existing infrastructure
/// that must be reused, and technology standards to follow. Provides the
/// technical landscape in which the solution must operate. Seeds the detailed
/// Architecture & Technology Specification (ATS) document.
@SectionId('TEFRCO')
@Comment('Seeds → ATS')
@MapsTo(D06ArchitectureTechnologySpecification)
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-TEC')
class TechnicalEnvironment {
  // -------------------------------------------------------------------------
  // Technical Landscape Overview
  // -------------------------------------------------------------------------
  @Form([
    Field('architectureMaturity', String, 'Architecture Maturity',
        hint: 'TOGAF maturity level or equivalent'),
    Field('cloudStrategy', String, 'Cloud Strategy',
        hint: 'Cloud-first, hybrid, on-premises, multi-cloud'),
    Field('primaryCloudProvider', String, 'Primary Cloud Provider',
        hint: 'AWS, Azure, GCP, private cloud, none'),
  ])
  @SerializationOrder(0)
  String? technicalOverviewContent;

  /// Architecture governance context.
  @SerializationOrder(1)
  TechnicalEnvironmentGovernance governance =
      TechnicalEnvironmentGovernance();

  /// Platform standards and preferred technologies.
  @SerializationOrder(2)
  TechnicalEnvironmentStandards standards =
      TechnicalEnvironmentStandards();

  /// Security and compliance requirements.
  @SerializationOrder(3)
  TechnicalEnvironmentSecurity security =
      TechnicalEnvironmentSecurity();

  /// Network and infrastructure standards.
  @SerializationOrder(4)
  TechnicalEnvironmentNetwork network =
      TechnicalEnvironmentNetwork();

  // -------------------------------------------------------------------------
  // Existing Infrastructure
  // -------------------------------------------------------------------------

  /// Existing infrastructure that must be reused or integrated with.
  @ContentHelp('Describe existing infrastructure: data centers, servers, '
      'networks, storage, systems that cannot be replaced, and infrastructure '
      'that the new solution must integrate with or leverage.')
  @SerializationOrder(5)
  TextSection existingInfrastructure = TextSection();

  /// Data center and hosting environment details.
  @SectionId('DATAC-DATA-LST')
  @SectionIdPattern('DATAC-DATA-xxx')
  @SerializationOrder(6)
  List<DatacenterEntry> datacenters = [];

  /// Network topology and connectivity constraints.
  @ContentHelp('Describe network topology, bandwidth constraints, latency '
      'requirements, VPN/private connectivity, and firewall restrictions.')
  @SerializationOrder(7)
  TextSection networkTopology = TextSection();

  // -------------------------------------------------------------------------
  // Technology Standards
  // -------------------------------------------------------------------------

  /// Technology standards that must be followed.
  @ContentHelp('Overview of technology standards: adoption policy, '
      'exception process, standard review cycle, and compliance monitoring.')
  @SerializationOrder(8)
  TextSection standardsOverview = TextSection();

  /// Technology standards — contains 0+× TechnologyStandard.
  @SectionId('TESTEN-TECH-LST')
  @SectionIdPattern('TESTEN-TECH-xxx')
  @SerializationOrder(9)
  List<TechnologyStandardEntry> technologyStandards = [];

  // -------------------------------------------------------------------------
  // Integration Constraints
  // -------------------------------------------------------------------------

  /// Integration constraints overview.
  @ContentHelp('Overview of integration constraints: API standards, '
      'protocol restrictions, message format requirements, and '
      'integration platform mandates.')
  @SerializationOrder(10)
  TextSection integrationOverview = TextSection();

  /// Integration constraints — contains 0+× IntegrationConstraint.
  @SectionId('INCOE1-INTE-LST')
  @SectionIdPattern('INCOE1-INTE-xxx')
  @SerializationOrder(11)
  List<IntegrationConstraintEntry> integrationConstraints = [];

  // -------------------------------------------------------------------------
  // DevOps & Operations Standards
  // -------------------------------------------------------------------------

}

/// Architecture governance context.
@SectionId('TFCG')
class TechnicalEnvironmentGovernance {
    @Form([
        Field('secondaryCloudProviders', String, 'Secondary Cloud Providers'),
        Field('technologyGovernance', String, 'Technology Governance',
                hint: 'How technology decisions are governed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Platform standards and preferred technologies.
@SectionId('TFCS')
class TechnicalEnvironmentStandards {
    @Form([
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
    ])
    @SerializationOrder(0)
    String? content;
}

/// Security and compliance requirements.
@SectionId('TES')
class TechnicalEnvironmentSecurity {
    @Form([
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
    ])
    @SerializationOrder(0)
    String? content;
}

/// Network and infrastructure standards.
@SectionId('TFCN')
class TechnicalEnvironmentNetwork {
    @Form([
        Field('networkArchitecture', String, 'Network Architecture',
                hint: 'Network topology, DMZ, segmentation approach'),
        Field('firewallPolicies', String, 'Firewall Policies',
                hint: 'Standard firewall rules and policies'),
        Field('vpnRequirements', String, 'VPN Requirements',
                hint: 'VPN requirements for remote access'),
        Field('loadBalancingStandards', String, 'Load Balancing Standards'),
        Field('cdnStrategy', String, 'CDN Strategy'),
    ])
    @SerializationOrder(0)
    String? content;

  /// DevOps and deployment standards.
  @SectionId('DEVOP-DEVO-LST')
  @SectionIdPattern('DEVOP-DEVO-xxx')
  @SerializationOrder(1)
  List<DevopsStandardEntry> devopsStandards = [];

  /// Monitoring and observability requirements.
  @SectionId('OBSER-OBSE-LST')
  @SectionIdPattern('OBSER-OBSE-xxx')
  @SerializationOrder(2)
  List<ObservabilityRequirementEntry> observabilityRequirements = [];

  /// Disaster recovery and business continuity requirements.
  @ContentHelp('Describe DR/BC requirements: RTO, RPO, backup standards, '
      'failover requirements, and recovery testing.')
  @SerializationOrder(3)
  TextSection disasterRecovery = TextSection();
}

/// A technology standard entry (form).
///
/// Documents a mandated or preferred technology standard that the solution
/// must adhere to. Includes scope, compliance requirements, and exceptions.
@SectionId('TSE')
class TechnologyStandardEntry {
  @Form([
    Field('standardId', String, 'Standard ID', required: true,
        hint: 'Unique identifier, e.g. STD-SEC-001, STD-DEV-001'),
    Field('standardName', String, 'Standard Name', required: true,
        hint: 'Short descriptive name'),
    Field('standardCategory', String, 'Category',
        hint: 'Security, Development, Infrastructure, Integration, Data, DevOps'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Standard details and sources.
  @SerializationOrder(1)
  TechnologyStandardEntryDetails details = TechnologyStandardEntryDetails();

  /// Scope and applicability.
  @SerializationOrder(2)
  TechnologyStandardEntryScope scope = TechnologyStandardEntryScope();

  /// Compliance settings.
  @SerializationOrder(3)
  TechnologyStandardEntryCompliance compliance =
      TechnologyStandardEntryCompliance();

  /// Project impact notes.
  @SerializationOrder(4)
  TechnologyStandardEntryImpact impact = TechnologyStandardEntryImpact();
}

/// Standard details and sources.
@SectionId('TSED')
class TechnologyStandardEntryDetails {
  @Form([
    Field('standardDescription', String, 'Description',
        hint: 'Detailed description of the standard'),
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope and applicability.
@SectionId('TSES')
class TechnologyStandardEntryScope {
  @Form([
    Field('applicabilityScope', String, 'Applicability Scope',
        hint: 'Where the standard applies — all systems, specific domains, etc.'),
    Field('technologiesCovered', String, 'Technologies Covered',
        hint: 'Specific technologies this standard covers'),
    Field('exceptions', String, 'Known Exceptions',
        hint: 'Existing exceptions to this standard'),
    Field('exceptionProcess', String, 'Exception Process',
        hint: 'How to request an exception'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance settings.
@SectionId('TSEC')
class TechnologyStandardEntryCompliance {
  @Form([
    Field('complianceMethod', String, 'Compliance Method',
        hint: 'How compliance is verified — automated scan, review, audit'),
    Field('complianceOwner', String, 'Compliance Owner',
        hint: 'Role responsible for standard compliance'),
    Field('violationConsequence', String, 'Violation Consequence',
        hint: 'Consequences of non-compliance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Project impact notes.
@SectionId('TSEI')
class TechnologyStandardEntryImpact {
  @Form([
    Field('projectImpact', String, 'Project Impact',
        hint: 'How this standard impacts the project'),
    Field('implementationNotes', String, 'Implementation Notes',
        hint: 'Notes on implementing this standard'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An integration constraint entry (form).
///
/// Documents a technical constraint on system integration, including
/// protocol requirements, format restrictions, and platform mandates.
@SectionId('INTCONENT')
class IntegrationConstraintEntry {
  @Form([
    Field('constraintId', String, 'Constraint ID', required: true,
        hint: 'Unique identifier, e.g. INT-CON-001'),
    Field('constraintName', String, 'Constraint Name', required: true,
        hint: 'Short descriptive name'),
    Field('constraintDescription', String, 'Description',
        hint: 'Detailed description of the integration constraint'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Constraint details.
  @SerializationOrder(1)
  IntegrationConstraintEntryDetails details =
      IntegrationConstraintEntryDetails();

  /// Scope of impact.
  @SerializationOrder(2)
  IntegrationConstraintEntryScope scope = IntegrationConstraintEntryScope();

  /// Impact and mitigation.
  @SerializationOrder(3)
  IntegrationConstraintEntryMitigation mitigation =
      IntegrationConstraintEntryMitigation();

  /// Compliance rules.
  @SerializationOrder(4)
  IntegrationConstraintEntryCompliance compliance =
      IntegrationConstraintEntryCompliance();
}

/// Constraint details.
@SectionId('INCOENDE')
class IntegrationConstraintEntryDetails {
  @Form([
    Field('constraintType', String, 'Constraint Type',
        hint: 'Protocol, Format, Platform, Security, Performance, Availability'),
    Field('constraintValue', String, 'Constraint Value',
        hint: 'Specific constraint value or requirement'),
    Field('constraintSource', String, 'Source',
        hint: 'Source of the constraint — enterprise architecture, vendor, security'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope of impact.
@SectionId('ICES')
class IntegrationConstraintEntryScope {
  @Form([
    Field('impactedSystems', String, 'Impacted Systems',
        hint: 'Systems affected by this constraint'),
    Field('impactedInterfaces', String, 'Impacted Interfaces',
        hint: 'Specific interfaces affected'),
    Field('integrationPattern', String, 'Affected Patterns',
        hint: 'Integration patterns affected — sync, async, batch, event'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Impact and mitigation.
@SectionId('ICEM')
class IntegrationConstraintEntryMitigation {
  @Form([
    Field('impactLevel', String, 'Impact Level',
        hint: 'High, Medium, Low — impact on integration design'),
    Field('designImplications', String, 'Design Implications',
        hint: 'How this constraint affects integration design'),
    Field('workarounds', String, 'Workarounds',
        hint: 'Potential workarounds or alternatives'),
    Field('mitigationApproach', String, 'Mitigation Approach',
        hint: 'How to work within this constraint'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance rules.
@SectionId('INCOENCO')
class IntegrationConstraintEntryCompliance {
  @Form([
    Field('complianceRequired', bool, 'Compliance Required',
        hint: 'Whether compliance is mandatory'),
    Field('validationMethod', String, 'Validation Method',
        hint: 'How compliance is validated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 4.6.4. Constraints and Dependencies.
///
/// Operating-environment view of the constraints and dependencies that shape
/// project execution. The canonical register of constraints and dependencies
/// lives in SBP.6 (Assumptions, Constraints & Dependencies). This node does
/// **not** restate that register (L34C-4 consolidation, SR-10): it frames how
/// the framework conditions documented in SBP.2 §4.6 give rise to the entries
/// recorded in SBP.6, and points the reader there.
@SectionId('COANDE')
class ConstraintsAndDependencies {
  @ContentType('description', 'Summarize how the operating environment '
      'described in this section gives rise to constraints and dependencies, '
      'and reference the canonical register in SBP.6 (Assumptions, Constraints '
      '& Dependencies). Do not restate individual constraint or dependency '
      'entries here — record them once, in the SBP.6 register.')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.7 Risks and Assumptions
// ---------------------------------------------------------------------------

/// 4.7. Risks.
///
/// Documents identified project risks following ISO 31000 Risk Management and
/// PMBOK risk management best practices. Provides a structured framework for
/// risk identification, analysis, response planning, and ongoing monitoring
/// throughout the project lifecycle.
///
/// Assumptions are **not** held here (L34C-4 consolidation, SR-11): the
/// canonical assumptions register lives in SBP.6 (Assumptions, Constraints &
/// Dependencies). Only the risks half — unique to §4.7 — remains in this node.
/// (The class name remains `RisksAndAssumptions` pending the L34C-9 rename
/// sweep, which will rename it to `Risks`.)
@SectionId('RIANAS')
class RisksAndAssumptions {
  /// Overview of the risk management approach for this project.
  @SerializationOrder(0)
  RisksOverview overview = RisksOverview();

  /// 4.7.1. Key Risks — contains 0+× Risk.
  @SectionId('RIEN-KEYR-LST')
  @SectionIdPattern('RIEN-KEYR-xxx')
  @SerializationOrder(1)
  List<RiskEntry> keyRisks = [];
}

/// Overview of the risk management approach.
@SectionId('RIOV')
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
  @SerializationOrder(0)
  String? content;
}

/// A risk entry (form).
///
/// Comprehensive risk documentation following ISO 31000 and PMBOK guidelines.
/// Captures risk identification, analysis, response planning, ownership,
/// and monitoring information for systematic risk management.
@SectionId('RISENT')
class RiskEntry {
  /// Risk identification — unique identifier and basic description.
  @SerializationOrder(0)
  RiskIdentification identification = RiskIdentification();

  /// Risk analysis — probability, impact, and scoring.
  @SerializationOrder(1)
  RiskAnalysis analysis = RiskAnalysis();

  /// Risk response — strategy and planned actions.
  @SerializationOrder(2)
  RiskResponse response = RiskResponse();

  /// Risk ownership and governance.
  @SerializationOrder(3)
  RiskOwnership ownership = RiskOwnership();

  /// Risk monitoring and tracking details.
  @SerializationOrder(4)
  RiskMonitoring monitoring = RiskMonitoring();

  /// Business impact assessment.
  @SerializationOrder(5)
  RiskBusinessImpact businessImpact = RiskBusinessImpact();

  /// Relationships to other risks, assumptions, and project elements.
  @SectionId('RR-RELA-LST')
  @SectionIdPattern('RR-RELA-xxx')
  @SerializationOrder(6)
  List<RiskRelationships> relationships = [];
}

/// Risk identification details.
@SectionId('RIID')
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
  ])
  @SerializationOrder(0)
  String? content;

    /// Identification source and ownership metadata.
    @SerializationOrder(1)
    RiskIdentificationSource sourceDetails = RiskIdentificationSource();

    /// Trigger and root-cause details.
    @SerializationOrder(2)
    RiskIdentificationCause cause = RiskIdentificationCause();
}

/// Identification source and ownership metadata.
@SectionId('RIIDSO')
class RiskIdentificationSource {
    @Form([
        Field('source', String,
                'Risk Source — brainstorming, review, lessons learned'),
        Field('dateIdentified', String, 'Date Identified'),
        Field('identifiedBy', String, 'Identified By — person or team'),
        Field('riskType', String,
                'Risk Type — Threat (negative) or Opportunity (positive)'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Trigger and root-cause details.
@SectionId('RIIDCA')
class RiskIdentificationCause {
    @Form([
        Field('trigger', String,
                'Risk Trigger — events indicating risk is about to occur'),
        Field('rootCause', String,
                'Root Cause — underlying causes that could lead to this risk'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Risk analysis — probability, impact, and risk scoring.
@SectionId('RIAN')
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
  @SerializationOrder(0)
  String? content;
}

/// Risk response — strategy and planned actions.
@SectionId('RIRE')
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
  ])
  @SerializationOrder(0)
  String? content;

  /// Residual and secondary risk expectations.
  @SerializationOrder(1)
  RiskResponseResidual residual = RiskResponseResidual();

  /// Implementation effort and effectiveness.
  @SerializationOrder(2)
  RiskResponseImplementation implementation =
      RiskResponseImplementation();
}

/// Residual and secondary risk expectations.
@SectionId('RIRERE')
class RiskResponseResidual {
  @Form([
    Field('residualRisk', String,
        'Residual Risk — level remaining after mitigation'),
    Field('residualProbability', String,
        'Residual Probability — expected after mitigation'),
    Field('residualImpact', String,
        'Residual Impact — expected after mitigation'),
    Field('secondaryRisks', String,
        'Secondary Risks — new risks from implementing response'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Implementation effort and effectiveness.
@SectionId('RIREIM')
class RiskResponseImplementation {
  @Form([
    Field('responseEffectiveness', String,
        'Response Effectiveness — Low, Medium, High'),
    Field('implementationCost', String,
        'Implementation Cost — cost to implement response'),
    Field('implementationTimeline', String,
        'Implementation Timeline — for response actions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Risk ownership and governance.
@SectionId('RIOW')
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
  @SerializationOrder(0)
  String? content;
}

/// Risk monitoring and tracking.
@SectionId('RIMO')
class RiskMonitoring {
  @Form([
    Field('reviewFrequency', String,
        'Review Frequency — Daily, Weekly, Bi-weekly, Monthly'),
    Field('lastReviewDate', String, 'Last Review Date'),
    Field('nextReviewDate', String, 'Next Review Date'),
    Field('riskStatus', String,
        'Risk Status — Identified, Analyzing, Responding, Monitoring, Closed, Realized'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Trend and monitoring indicators.
    @SerializationOrder(1)
    RiskMonitoringTrend trendDetails = RiskMonitoringTrend();

    /// Closure tracking and lessons learned.
    @SerializationOrder(2)
    RiskMonitoringClosure closure = RiskMonitoringClosure();
}

/// Trend and monitoring indicators.
@SectionId('RIMOTR')
class RiskMonitoringTrend {
    @Form([
        Field('trend', String, 'Trend — Increasing, Stable, Decreasing'),
        Field('trendJustification', String,
                'Trend Justification — explanation for trend assessment'),
        Field('earlyWarningIndicators', String,
                'Early Warning Indicators — metrics signaling risk may materialize'),
        Field('monitoringMechanism', String,
                'Monitoring Mechanism — automated alerts, manual review, etc.'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Closure tracking and lessons learned.
@SectionId('RIMOCL')
class RiskMonitoringClosure {
    @Form([
        Field('closureDate', String, 'Closure Date'),
        Field('closureReason', String,
                'Closure Reason — Mitigated, Avoided, Accepted, Realized, No longer relevant'),
        Field('lessonsLearned', String,
                'Lessons Learned — key insights from managing this risk'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Business impact assessment for the risk.
@SectionId('RIBUIM')
class RiskBusinessImpact {
  @Form([
    Field('costImpact', String,
        'Cost Impact — potential cost if risk materializes'),
    Field('scheduleImpact', String,
        'Schedule Impact — potential delay (days, weeks, phases)'),
    Field('scopeImpact', String, 'Scope Impact — impact on deliverables'),
    Field('qualityImpact', String, 'Quality Impact'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Broader stakeholder and compliance impact.
  @SerializationOrder(1)
  RiskBusinessImpactStakeholders stakeholders =
      RiskBusinessImpactStakeholders();

  /// Operational and delivery consequences.
  @SerializationOrder(2)
  RiskBusinessImpactDelivery delivery = RiskBusinessImpactDelivery();
}

/// Broader stakeholder and compliance impact.
@SectionId('RBIS')
class RiskBusinessImpactStakeholders {
  @Form([
    Field('resourceImpact', String,
        'Resource Impact — impact on team resources'),
    Field('reputationImpact', String,
        'Reputation Impact — organizational or project'),
    Field('customerImpact', String,
        'Customer Impact — impact on customers or end users'),
    Field('regulatoryImpact', String,
        'Regulatory Impact — compliance implications'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operational and delivery consequences.
@SectionId('RBID')
class RiskBusinessImpactDelivery {
  @Form([
    Field('operationalImpact', String,
        'Operational Impact — impact on ongoing operations'),
    Field('strategicImpact', String,
        'Strategic Impact — impact on strategic objectives'),
    Field('affectedMilestones', String,
        'Affected Milestones — project milestones at risk'),
    Field('affectedDeliverables', String,
        'Affected Deliverables — specific deliverables at risk'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Relationships to other risks, assumptions, and project elements.
@SectionId('RR')
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
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.4 System Landscape Inventory
// ---------------------------------------------------------------------------

/// 4.5.4. System Landscape Inventory.
///
/// Complete external-system inventory covering IIS-LAN-INV content.
@SectionId('SYLAIN')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-INV')
class SystemLandscapeInventory {
  @ContentHelp('''
Enumerates every external system the target system interacts with, with
enough metadata to support dependency and impact analysis across the
organization's landscape.

**What to capture:**
- System name, owner, criticality tier
- Deployment footprint (cloud / on-prem / SaaS / vendor)
- Lifecycle status (active / planned retirement / replacement)
- Relationship class (upstream source, downstream consumer, peer)
- Technology and protocol fingerprint
- Data-sensitivity classification of the exchange
- Governance contacts and escalation routing
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.5 Boundary Interaction Patterns
// ---------------------------------------------------------------------------

/// 4.5.5. Boundary Interaction Patterns.
///
/// Sync / async / batch interaction-pattern catalog. Covers IIS-PAT.
/// Named `BoundaryInteractionPatterns` to avoid colliding with the
/// existing intra-system `InteractionPatterns` class.
@SectionId('BOINPA')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-PAT')
class BoundaryInteractionPatterns {
  @ContentHelp('''
Reusable interaction patterns applied at system boundaries. Distinct
from `InteractionPatterns` which documents patterns
within the target system.

**What to capture:**
- Pattern catalog (name, shape, rationale)
- Synchronous request-reply flavors (REST, gRPC, GraphQL)
- Asynchronous patterns (pub/sub, queue, event stream)
- Batch and scheduled-transfer patterns
- Pattern selection criteria per interaction
- Delivery guarantees per pattern (at-most-once / at-least-once / exactly-once)
- Idempotency and ordering expectations
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.6 Interaction Testing Strategy
// ---------------------------------------------------------------------------

/// 4.5.6. Interaction Testing Strategy.
///
/// Contract / integration / failure-mode testing for system boundaries.
/// Covers IIS-TST.
@SectionId('INTES1')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-TST')
class InteractionTestingStrategy {
  @ContentHelp('''
Strategy for testing boundary interactions specifically. Complements the
broader system-wide test strategy.

**What to capture:**
- Contract-testing approach (consumer-driven / provider-driven)
- Integration-test scope per boundary
- Failure-mode and chaos-style tests (partner down, slow, malformed)
- Stub / simulator strategy for non-prod environments
- Performance-envelope tests per interaction
- Test-data management for boundary tests
- CI/CD integration for contract verification
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.7 Interaction Dependency Analysis
// ---------------------------------------------------------------------------

/// 4.5.7. Interaction Dependency Analysis.
///
/// Critical-path and degraded-mode behavior analysis for system
/// dependencies. Covers IIS-DEP.
@SectionId('INDEAN')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-DEP')
class InteractionDependencyAnalysis {
  @ContentHelp('''
What happens when external interactions are slow or unavailable, and
which of them lie on the critical path of user-facing flows.

**What to capture:**
- Critical-path map per business flow
- Degraded-mode behavior (feature off, read-only, queue-and-retry)
- Cache strategies for graceful degradation
- Circuit-breaker / bulkhead configuration per interaction
- Timeout budgets and retry policies
- User-visible error handling for unavailable partners
- Recovery behavior when partners come back online
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.8 Migration Interactions
// ---------------------------------------------------------------------------

/// 4.5.8. Migration Interactions.
///
/// Interactions specific to the migration window — cutover bridges,
/// reconciliation endpoints, and temporary shims. Back-refs the
/// Systems to Replace inventory. Covers IIS-MIG.
@SectionId('MIIN')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-MIG')
class MigrationInteractions {
  @ContentHelp('''
Transitional interactions that exist only during the migration window:
dual-write bridges, reconciliation feeds, freeze/replay mechanisms.

**What to capture:**
- Bridge / shim catalog (purpose, lifetime, owner)
- Dual-run reconciliation endpoints and rules
- Data-replay mechanisms (forward, reverse, selective)
- Freeze windows and cutover ordering
- Decommission criteria for each transitional interaction
- Observability hooks specific to migration
- Risk and rollback plan per transitional interaction
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.3.5 Requirement Relationships
// ---------------------------------------------------------------------------

/// 4.3.5. Requirement Relationships.
///
/// Cross-requirement dependency and conflict graph.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability & relationships',
    'INCOSE Guide for Writing Requirements — requirement relationships',
  ],
  'The cross-requirement dependency, conflict, refinement, and derivation graph '
  'that ties individual functional/technical/security/organizational '
  'requirements into a coherent network.',
)
@SectionId('RERE')
@DetailedIn(D04RequirementsSpecification)
@SecondLevelSectionId(D04RequirementsSpecification, 'RSP-REL')
class RequirementRelationships {
  @ContentHelp('''
Explicit relationships between requirements: dependencies, conflicts,
refinements, and derivations. Ties individual requirement entries from
FUN/TEC/SEC/ORG into a network.

**What to capture:**
- Relationship catalog (depends-on, conflicts-with, refines, derived-from)
- Per-requirement neighborhood (incoming / outgoing edges)
- Conflict resolution outcomes and decisions
- Derivation chains from goals to requirements
- Visualizations (matrix, graph, layered view)
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.3.6 Requirement Coverage
// ---------------------------------------------------------------------------

/// 4.3.6. Requirement Coverage.
///
/// Coverage of requirements against goals, use cases, and tests.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability & coverage',
    'ISO/IEC/IEEE 29119 — software testing (test coverage)',
  ],
  'Reports how completely requirements are covered against goals, use cases, '
  'and tests, surfacing gaps where requirements lack owners, tests, or '
  'acceptance criteria.',
)
@SectionId('REQCOV')
@DetailedIn(D04RequirementsSpecification)
@SecondLevelSectionId(D04RequirementsSpecification, 'RSP-COV')
class RequirementCoverage {
  @ContentHelp('''
Reports coverage of requirements from multiple angles to ensure nothing
falls through.

**What to capture:**
- Goal coverage (every goal has ≥1 requirement supporting it)
- Use case coverage (every use case references its requirements)
- Test coverage (every requirement has ≥1 test scenario)
- Gap analysis (requirements without owners / tests / acceptance criteria)
- Coverage trend snapshot over the project timeline
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.9 Cross-Boundary Operational Considerations
// ---------------------------------------------------------------------------

/// 4.5.9. Cross-Boundary Operational Considerations.
///
/// SLA, rate-limit, and change-window considerations applied at system
/// boundaries. Distinct from per-interface operational data captured
/// inside individual interface entries.
@SectionId('CBOC')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-OPE')
class CrossBoundaryOperationalConsiderations {
  @ContentHelp('''
Operational considerations that span all boundary interactions rather
than being specific to one partner.

**What to capture:**
- Aggregate SLA expectations across partners
- Rate-limit budgeting (per-partner vs. system-wide)
- Change-window coordination (our releases vs. partners' releases)
- Observability conventions (metrics, log fields, trace IDs)
- Disaster-recovery posture for boundary interactions
- Capacity planning across partners
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 4.5.10 Cross-Boundary Error Handling
// ---------------------------------------------------------------------------

/// 4.5.10. Cross-Boundary Error Handling.
///
/// Failure-propagation policy that applies across system boundaries.
/// Distinct from per-interface error handling.
@SectionId('CBEH')
@DetailedIn(D07IntegrationInterfaceSpecification)
@SecondLevelSectionId(D07IntegrationInterfaceSpecification, 'IIS-ERR')
class CrossBoundaryErrorHandling {
  @ContentHelp('''
Policy for how failures propagate or are contained across boundary
interactions. Complements per-interface `InterfaceErrorHandling` which
captures partner-specific logic.

**What to capture:**
- Error-taxonomy shared across boundaries (network, protocol, business)
- Propagation policy (fail-fast / absorb / translate)
- Retry and backoff conventions
- Dead-letter and poison-message handling
- User-visible messaging for cross-boundary failures
- Alerting thresholds per error class
- Post-mortem and reconciliation procedures
''')
  @SerializationOrder(0)
  String? content;
}

/// A single compliance measure entry.
@SectionId('COMPL')
class ComplianceMeasureEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single interaction scenario entry.
@SectionId('INTER')
class InteractionScenarioEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single related pain point entry.
@SectionId('RPPE')
class RelatedPainPointEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single scope assumption entry.
@SectionId('SCOPE')
class ScopeAssumptionEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single workflow step entry.
@SectionId('SYSTE')
class SystemTaskWorkflowStepEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single variations and exception entry.
@SectionId('VARIA')
class VariationsAndExceptionEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single key touchpoint entry.
@SectionId('KEYTO')
class KeyTouchpointEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single pain point entry.
@SectionId('USERJ')
class UserJourneyPainPointEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single representative quote entry.
@SectionId('REPRE')
class RepresentativeQuoteEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single kpi entry.
@SectionId('KPIEN')
class KpiEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single mapping rule entry.
@SectionId('MAPPI')
class MappingRuleEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single validation rule entry.
@SectionId('VALID')
class ValidationRuleEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single error procedure entry.
@SectionId('ERROR')
class ErrorProcedureEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single dependency entry.
@SectionId('DEPEN')
class DependencyEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single escalation procedure entry.
@SectionId('ESCAL')
class EscalationProcedureEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single risk category entry.
@SectionId('RISKC')
class RiskCategoryEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single risk based decision entry.
@SectionId('RISKB')
class RiskBasedDecisionEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single monitoring procedure entry.
@SectionId('MONIT')
class MonitoringProcedureEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single response strategy entry.
@SectionId('RESPO')
class ResponseStrategyEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single cultural consideration entry.
@SectionId('CULTU')
class CulturalConsiderationEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single communication preference entry.
@SectionId('COMMU')
class CommunicationPreferenceEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single change advocate entry.
@SectionId('CHANG')
class ChangeAdvocateEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single non financial benefit entry.
@SectionId('NONFI')
class NonFinancialBenefitEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single known quality issue entry.
@SectionId('KNOWN')
class KnownQualityIssueEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single critical knowledge area entry.
@SectionId('CRITI')
class CriticalKnowledgeAreaEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single predecessor dependency entry.
@SectionId('PREDE')
class PredecessorDependencyEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single known issue entry.
@SectionId('KIE')
class KnownIssueEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single security concern entry.
@SectionId('SECUR')
class SecurityConcernEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single datacenter entry.
@SectionId('DATAC')
class DatacenterEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single devops standard entry.
@SectionId('DEVOP')
class DevopsStandardEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single observability requirement entry.
@SectionId('OBSER')
class ObservabilityRequirementEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}
