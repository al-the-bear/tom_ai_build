/// Section 4: Introduction & Scope.
///
/// High-level overview of the system: purpose, goals, scope, requirements,
/// boundaries, and environment. This chapter provides the foundational
/// understanding of what the system is, why it's being built, and the
/// context in which it will operate.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// The closed set of requirement-side screen field types (`ScreenFieldEntry`,
/// csra4).
///
/// The discriminator enum for the `ScreenFieldEntry` `@OneOf` group: it picks
/// which type-specific constraint and presentation subsections apply — a text
/// field carries `textConstraints`, a numeric one `numericConstraints`, a
/// temporal one `temporalConstraints`, a choice field `choiceOptions`, an
/// upload `fileConstraints`. `boolean` carries no per-kind attributes and so
/// binds no case. Replaces the former free-text `fieldType`.
///
/// This is the *requirement-side* vocabulary (RSP, D04). The authoritative UI
/// element vocabulary is `ScreenElementFieldKind` in the D09 Experience Design
/// pass; the two are deliberately separate because a requirement names the kind
/// of value a user supplies, while the design names the concrete control.
enum ScreenFieldKind {
  // Text facet.
  text,
  multilineText,
  email,
  phone,
  url,
  password,
  // Numeric facet.
  integer,
  decimal,
  currency,
  // Temporal facet.
  date,
  dateTime,
  time,
  // Choice facet.
  singleSelect,
  multiSelect,
  // Upload facet.
  file,
  // No per-kind attributes.
  boolean,
}

/// 4. Introduction & Scope.
///
/// High-level overview of the system to be built: its purpose, goals,
/// scope boundaries, and the environment it operates in. This section
/// establishes the foundation for all subsequent specification work.
@FollowUpKind([FollowUpProcess.doc])
@SectionId('INSC')
class IntroductionAndScope extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// System overview summary statistics.
  @SerializationOrder(1)
  SystemSummary summary = SystemSummary();

  /// System context diagram showing major system boundaries.
  @SectionId('INSC-SYST')
  @ContentType(
    'mermaid',
    'High-level context diagram showing the system, '
        'its users, and external system interfaces',
  )
  @SerializationOrder(2)
  DocSpecsSection? systemContextDiagram;

  /// 4.1. System Description.
  @SerializationOrder(3)
  SystemDescription systemDescription = SystemDescription();

  /// 4.2. Goals.
  // YRD4: field-level `@Headline` — the default heading title for this
  // section; it wins over the target class's class-level `@Headline`, and a
  // stored headline in a document wins over both.
  @Headline('Project Goals')
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
class SystemSummary extends DocSpecsSection {
  @Form([
    Field(
      'systemName',
      String,
      'System Name',
      hint: 'Official name of the system being built',
      required: true,
    ),
    Field(
      'systemAcronym',
      String,
      'System Acronym',
      hint: 'Short acronym if used',
    ),
    Field(
      'systemVersion',
      String,
      'System Version',
      hint: 'Target version this specification covers',
    ),
    Field(
      'projectCodeName',
      String,
      'Project Code Name',
      hint: 'Internal project code name if different',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// System classification.
  @SectionId('SYCLS')
  @Form([
    Field(
      'systemType',
      String,
      'System Type',
      hint: 'Web Application / Mobile App / API / Desktop / Embedded / Hybrid',
    ),
    Field(
      'businessDomain',
      String,
      'Business Domain',
      hint: 'Primary business domain — Finance / Healthcare / Retail / etc.',
    ),
    Field(
      'deploymentModel',
      String,
      'Deployment Model',
      hint: 'Cloud / On-premise / Hybrid / Edge',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Scale indicators.
  @SectionId('SYSCL')
  @Form([
    Field(
      'estimatedUserCount',
      int,
      'Estimated User Count',
      hint: 'Expected number of users at steady state',
    ),
    Field(
      'userCategoryCount',
      int,
      'User Category Count',
      hint: 'Number of distinct user categories',
    ),
    Field(
      'externalInterfaceCount',
      int,
      'External Interface Count',
      hint: 'Number of external system integrations',
    ),
    Field(
      'functionalRequirementCount',
      int,
      'Functional Requirement Count',
      hint: 'Number of functional requirements identified',
    ),
    Field(
      'nonFunctionalRequirementCount',
      int,
      'Non-Functional Requirement Count',
      hint: 'Number of non-functional requirements identified',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scale;

  /// Specification status.
  @SectionId('SPSTA')
  @Form([
    Field(
      'specificationVersion',
      String,
      'Specification Version',
      hint: 'Version of this specification document',
    ),
    Field(
      'specificationDate',
      String,
      'Specification Date',
      hint: 'Date of this specification',
    ),
    Field(
      'specificationStatus',
      String,
      'Specification Status',
      hint: 'Draft / Review / Approved / Superseded',
    ),
    Field(
      'targetGoLiveDate',
      String,
      'Target Go-Live Date',
      hint: 'Planned production deployment date',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? status;

  /// Complexity indicators.
  @SectionId('SYCMX')
  @Form([
    Field(
      'overallComplexity',
      String,
      'Overall Complexity',
      hint: 'Low / Medium / High / Very High — based on scope and integrations',
    ),
    Field(
      'keyRisks',
      String,
      'Key Risks Summary',
      hint: 'Brief list of top 3 risks',
    ),
    Field(
      'keyAssumptions',
      String,
      'Key Assumptions Summary',
      hint: 'Brief list of critical assumptions',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? complexity;
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
class SystemDescription extends DocSpecsSection {
  @ContentHelp('''
Concise description of the system to be created.
Describe the primary purpose of the system and the business domain it
addresses. Focus on WHAT the system does, not HOW it does it.
This section should establish a shared vocabulary and mental model
that all stakeholders can refer to.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// System description summary.
  @SectionId('SDSM')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — system overview'],
    'A structured at-a-glance classification of the system — its function, '
    'domain, architecture, deployment, and key characteristics.',
  )
  @Form([
    Field(
      'primaryFunction',
      String,
      'Primary function the system performs',
      hint: 'e.g., Enterprise resource planning and management',
    ),
    Field(
      'systemCategory',
      String,
      'High-level category classification',
      hint:
          'Business Application, Consumer Application, Infrastructure, '
          'Embedded, Platform/Framework, Data Processing, Integration, '
          'Monitoring/Management, AI/ML, IoT, Development Tool, Security',
    ),
    Field(
      'domainClassification',
      String,
      'Primary business or technical domain',
      hint: 'e.g., Healthcare, Finance, Manufacturing, E-commerce',
    ),
    Field(
      'deploymentModel',
      String,
      'Primary deployment approach',
      hint:
          'Cloud-native SaaS, Cloud-hosted PaaS, Hybrid Cloud, '
          'On-premises, Edge/Distributed, Mobile-first, Desktop, Embedded',
    ),
    Field(
      'architectureStyle',
      String,
      'Primary architectural pattern',
      hint:
          'Microservices, Monolithic, Serverless, Event-driven, Layered, '
          'Modular Monolith, Service-oriented, Peer-to-peer, Client-server',
    ),
    Field(
      'primaryTechnologyStack',
      String,
      'Main technologies and frameworks',
      hint: 'e.g., Flutter/Dart, Firebase, PostgreSQL',
    ),
    Field(
      'interfaceTypes',
      String,
      'Types of user and system interfaces',
      hint:
          'Web UI, Mobile App, Desktop App, REST API, GraphQL API, '
          'gRPC API, CLI, Voice Interface, Chat/Bot Interface, Hardware',
    ),
    Field(
      'dataCharacteristics',
      String,
      'Key data handling characteristics',
      hint: 'e.g., Real-time processing, batch analytics, ACID transactions',
    ),
    Field(
      'securityClassification',
      String,
      'Overall security posture requirement',
      hint:
          'Public/Open, Internal Use, Confidential, Highly Confidential, '
          'Regulated (HIPAA/GDPR/SOX), Government/Classified',
    ),
    Field(
      'availabilityRequirement',
      String,
      'Target availability level',
      hint:
          '99.999% (Five 9s), 99.99% (Four 9s), 99.9% (Three 9s), '
          '99%, Business Hours Only, Best Effort',
    ),
    Field(
      'scalabilityModel',
      String,
      'How the system scales',
      hint:
          'Horizontal Auto-scaling, Vertical Scaling, Manual Scaling, '
          'Fixed Capacity, Edge Distribution, Federation',
    ),
    Field(
      'expectedUserLoad',
      String,
      'Anticipated concurrent user volume',
      hint:
          'Single User, Team (<100), Enterprise (100-1000), '
          'Large Enterprise (1000-10000), Consumer (10000+)',
    ),
    Field(
      'keyDifferentiators',
      String,
      'What makes this system unique',
      hint: 'e.g., AI-powered recommendations, real-time collaboration',
    ),
    Field(
      'criticalCapabilities',
      String,
      'Most important system capabilities',
      hint: 'e.g., Multi-tenant data isolation, offline-first sync',
    ),
  ])
  @ContentType(
    'aggregation',
    'Structured classification and characteristics '
        'of the system based on category, domain, architecture, and '
        'deployment model.',
  )
  @SerializationOrder(1)
  DocSpecsSection? descriptionSummary;

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
  @StandardReferences([
    'BABOK v3 §10.43 — stakeholder list/map/personas',
    'ISO/IEC/IEEE 29148 §6 — stakeholders',
  ], 'The set of distinct user categories that interact with the system.')
  @SectionId('USCA-USER-LST')
  @SectionIdPattern('USCA-USER-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per distinct category of user, distinguished by '
    'role, access level, or interaction pattern with the system.',
  )
  @SerializationOrder(5)
  List<UserCategoryEntry> userCategories = [];

  /// 4.1.5. User Interaction Model.
  @SerializationOrder(6)
  UserInteractionModel userInteractionModel = UserInteractionModel();
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
@ContentHelp(
  'Describe the overarching purpose of the system. Address: '
  'What problem does it solve? What opportunity does it enable? '
  'Who are the primary beneficiaries? How does it align with '
  'organizational strategy?',
)
@SectionId('SYPUP')
class SystemPurpose extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Vision Statement.
  @SectionId('SYPUP-VISI')
  @ContentType(
    'description',
    'A concise, memorable statement (1-3 sentences) '
        'that captures the essence of what the system will achieve.',
  )
  @ContentHelp(
    'Write a clear and inspiring vision statement that describes '
    'what success looks like when this system is fully operational.',
  )
  @SerializationOrder(1)
  DocSpecsSection? visionStatement;

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
@ContentHelp(
  'Describe the problem in detail. What is the current state? '
  'What makes it a problem? Who is affected and how severely?',
)
@SectionId('PS')
class ProblemStatement extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Problem Description Form.
  @Form([
    Field(
      'problemSummary',
      String,
      'Problem Summary (one sentence)',
      required: true,
      hint: 'State the core problem in a single concise sentence',
    ),
    Field(
      'currentState',
      String,
      'Current State (describe the AS-IS situation that is problematic)',
      hint: 'Describe the current AS-IS situation that is problematic',
    ),
    Field(
      'affectedParties',
      String,
      'Affected Parties (who suffers from this problem)',
      hint: 'Who suffers from this problem and in what way',
    ),
    Field(
      'impactDescription',
      String,
      'Impact Description (business, financial, operational impacts)',
      hint: 'Business, financial, and operational impacts of the problem',
    ),
    Field(
      'impactSeverity',
      String,
      'Impact Severity (Critical, High, Medium, Low)',
      hint: 'Critical / High / Medium / Low',
    ),
    Field(
      'impactMetrics',
      String,
      'Impact Metrics (quantifiable measures of the problem\'s cost)',
      hint: 'Quantifiable measures of the problem\'s cost',
    ),
    Field(
      'rootCauses',
      String,
      'Root Causes (underlying reasons for problem)',
      hint: 'Underlying reasons that cause the problem',
    ),
    Field(
      'urgency',
      String,
      'Urgency (Immediate, Short-term, Medium-term, Long-term)',
      hint: 'Immediate / Short-term / Medium-term / Long-term',
    ),
    Field(
      'urgencyJustification',
      String,
      'Urgency Justification (why this timeline is critical)',
      hint: 'Why the stated timeline is critical',
    ),
    Field(
      'consequencesOfInaction',
      String,
      'Consequences of Inaction (what happens if not addressed)',
      hint: 'What happens if the problem is not addressed',
    ),
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
  @ContentHelp(
    'Add one entry per related pain point identified in the Current '
    'State Analysis that this problem statement connects to.',
  )
  @SerializationOrder(2)
  List<DocSpecsSection> relatedPainPoints = [];
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
@ContentHelp(
  'Describe what the system will enable. What new capabilities '
  'will be available? What improvements over current state? What '
  'competitive advantages will it provide?',
)
@SectionId('OPPST')
class OpportunityStatement extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Opportunity Details Form.
  @Form([
    Field(
      'opportunitySummary',
      String,
      'Opportunity Summary (one sentence)',
      required: true,
      hint: 'State the core opportunity in a single concise sentence',
    ),
    Field(
      'futureState',
      String,
      'Future State (describe the TO-BE situation after implementation)',
      hint: 'Describe the TO-BE situation after implementation',
    ),
    Field(
      'newCapabilities',
      String,
      'New Capabilities (what becomes possible that wasn\'t before)',
      hint: 'What becomes possible that was not possible before',
    ),
    Field(
      'improvements',
      String,
      'Improvements (quantitative and qualitative improvements expected)',
      hint: 'Quantitative and qualitative improvements expected',
    ),
    Field(
      'competitiveAdvantage',
      String,
      'Competitive Advantage (market positioning benefits)',
      hint: 'Market positioning benefits the system provides',
    ),
    Field(
      'innovationAspects',
      String,
      'Innovation Aspects (novel or differentiating features)',
      hint: 'Novel or differentiating features',
    ),
    Field(
      'growthEnablement',
      String,
      'Growth Enablement (how this supports business growth)',
      hint: 'How the system supports business growth',
    ),
    Field(
      'efficiencyGains',
      String,
      'Efficiency Gains (productivity and cost improvements)',
      hint: 'Productivity and cost improvements expected',
    ),
    Field(
      'timeToValue',
      String,
      'Time to Value (when benefits will start being realized)',
      hint: 'When benefits will start being realized',
    ),
  ])
  @SerializationOrder(1)
  TextSection? opportunityDetails;
}

/// 4.1.1.3. Stakeholders and Beneficiaries.
///
/// A scope-framing *benefits lens* over the stakeholder landscape: who
/// benefits from the system and what they gain. The canonical stakeholder
/// register — with role, interest, influence, concerns and engagement
/// strategy — lives in SBP.4 ([StakeholderRegisterEntry] list); those attributes are
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
@ContentHelp(
  'Identify the stakeholders and beneficiaries from a benefits '
  'perspective: who they are and the value they gain from the system. '
  'Record the canonical register (role, interest, influence, engagement) '
  'once, in SBP.4 StakeholderRegister — reference it here, do not restate it.',
)
@SectionId('SAB')
class StakeholdersAndBeneficiaries extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of the stakeholder landscape framed by '
        'benefit; reference the canonical SBP.4 StakeholderRegister for the full '
        'role/interest/influence/engagement attributes.',
  )
  @override
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
  @ContentHelp(
    'Add one entry per primary stakeholder or group, framed by the '
    'benefit they gain. Primary stakeholders are those directly affected.',
  )
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
class StakeholderEntry extends DocSpecsSection {
  @Form([
    Field(
      'stakeholderName',
      String,
      'Stakeholder Name or Group',
      required: true,
      hint: 'Name of the stakeholder individual or group',
    ),
    Field(
      'stakeholderType',
      String,
      'Stakeholder Type (Sponsor, User, Customer, Partner, Regulator, etc.)',
      hint: 'Sponsor, User, Customer, Partner, Regulator, etc.',
    ),
    Field(
      'expectedBenefits',
      String,
      'Expected Benefits (the scope-framing value this group gains from the '
          'system)',
      hint: 'The scope-framing value this group gains from the system',
    ),
  ])
  @override
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
@ContentHelp(
  'Articulate the business value clearly. Include quantifiable '
  'benefits, ROI expectations, and how value will be measured.',
)
@SectionId('VALPX')
class ValueProposition extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Value Proposition Details (form).
  @Form([
    Field(
      'valueStatement',
      String,
      'Value Statement (concise statement of value delivered)',
      required: true,
      hint: 'Concise statement of the value the system delivers',
    ),
    Field(
      'primaryBenefits',
      String,
      'Primary Benefits (top 3-5 benefits in priority order)',
      hint: 'Top 3-5 benefits in priority order',
    ),
    Field(
      'quantifiableBenefits',
      String,
      'Quantifiable Benefits (measurable improvements with targets)',
      hint: 'Measurable improvements with concrete targets',
    ),
    Field(
      'qualitativeBenefits',
      String,
      'Qualitative Benefits (non-quantifiable but important benefits)',
      hint: 'Non-quantifiable but important benefits',
    ),
  ])
  @SerializationOrder(1)
  TextSection? valueDetails;

  /// Financial and efficiency benefits.
  @SectionId('VALBN')
  @StandardReferences(
    ['BABOK v3 §10 — business value'],
    'The financial and efficiency benefits of the system — cost savings, '
    'revenue impact, productivity gains, and risk reduction.',
  )
  @Form([
    Field(
      'costSavings',
      String,
      'Cost Savings (expected cost reductions and where)',
      hint: 'Expected cost reductions and where they occur',
    ),
    Field(
      'revenueImpact',
      String,
      'Revenue Impact (how system affects revenue generation)',
      hint: 'How the system affects revenue generation',
    ),
    Field(
      'productivityGains',
      String,
      'Productivity Gains (efficiency improvements expected)',
      hint: 'Efficiency improvements expected from the system',
    ),
    Field(
      'riskReduction',
      String,
      'Risk Reduction (operational, compliance, security risks mitigated)',
      hint: 'Operational, compliance, and security risks mitigated',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? benefits;

  /// ROI and realization timeline.
  @SectionId('VALRP')
  @StandardReferences(
    ['BABOK v3 §10 — business value'],
    'The return profile of the system — estimated ROI, payback period, and the '
    'timeline over which value is realized.',
  )
  @Form([
    Field(
      'estimatedRoi',
      String,
      'Estimated ROI (return on investment calculation or estimate)',
      hint: 'Return-on-investment calculation or estimate',
    ),
    Field(
      'paybackPeriod',
      String,
      'Payback Period (time until investment is recovered)',
      hint: 'Time until the investment is recovered',
    ),
    Field(
      'valueRealizationTimeline',
      String,
      'Value Realization Timeline (when benefits start accruing)',
      hint: 'When benefits start accruing after delivery',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? returnProfile;

  /// Key Performance Indicators for value measurement.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — measures of effectiveness'],
    'The set of key performance indicators by which the system\'s delivered '
    'value will be measured.',
  )
  @SectionId('KPIEN-KPIS-LST')
  @SectionIdPattern('KPIEN-KPIS-xxx')
  @ContentHelp(
    'Add one entry per KPI used to measure delivered value. '
    'Include the metric, its baseline, and its target.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> kpis = [];
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
@ContentHelp(
  'Show how this project aligns with organizational strategy. '
  'Reference corporate goals, IT roadmap, and strategic initiatives.',
)
@SectionId('STRAL')
class StrategicAlignment extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Strategic Alignment Details (form).
  @Form([
    Field(
      'alignedCorporateGoals',
      String,
      'Aligned Corporate Goals (which company goals this supports)',
      hint: 'Which company goals this initiative supports',
    ),
    Field(
      'alignedBusinessObjectives',
      String,
      'Aligned Business Objectives (specific objectives this serves)',
      hint: 'Specific business objectives this serves',
    ),
    Field(
      'alignedItStrategy',
      String,
      'Aligned IT Strategy (how this fits in the IT roadmap)',
      hint: 'How this fits within the IT roadmap',
    ),
    Field(
      'relatedInitiatives',
      String,
      'Related Initiatives (other projects or programs this connects to)',
      hint: 'Other projects or programs this connects to',
    ),
    Field(
      'digitizationContribution',
      String,
      'Digitization Contribution (how this advances digital transformation)',
      hint: 'How this advances digital transformation',
    ),
    Field(
      'innovationContribution',
      String,
      'Innovation Contribution (how this supports innovation goals)',
      hint: 'How this supports innovation goals',
    ),
    Field(
      'complianceContribution',
      String,
      'Compliance Contribution (regulatory or policy requirements met)',
      hint: 'Regulatory or policy requirements met',
    ),
    Field(
      'marketPositioning',
      String,
      'Market Positioning (how this affects competitive position)',
      hint: 'How this affects competitive market position',
    ),
    Field(
      'strategicTimingRationale',
      String,
      'Strategic Timing (why this is the right time for this initiative)',
      hint: 'Why now is the right time for this initiative',
    ),
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
@ContentHelp(
  'Define clear boundaries. What is included? What is explicitly '
  'excluded? What is deferred to future phases? This prevents scope creep '
  'and sets clear expectations.',
)
@SectionId('SCBND')
class ScopeBoundaries extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// In-Scope Items — contains 1+× ScopeItem.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §6 — system scope & boundaries',
  ], 'The set of items explicitly included within the scope of this project.')
  @SectionId('SCITE-INSC-LST')
  @SectionIdPattern('SCITE-INSC-xxx')
  @Min(1)
  @ContentHelp(
    'List all items that are explicitly in scope for this project. '
    'Be specific about features, processes, user groups, and systems.',
  )
  @SerializationOrder(1)
  List<ScopeItemEntry> inScopeItems = [];

  /// Out-of-Scope Items — contains 0+× ScopeItem.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §6 — system scope & boundaries',
  ], 'The set of items explicitly excluded from the scope of this project.')
  @SectionId('SCITE-OUTO-LST')
  @SectionIdPattern('SCITE-OUTO-xxx')
  @ContentHelp(
    'List items explicitly excluded. This is as important as '
    'in-scope items to prevent misunderstandings and scope creep.',
  )
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
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §6 — system scope & boundaries',
  ], 'The set of assumptions on which the defined scope boundaries depend.')
  @SectionId('SCOPE-SCOP-LST')
  @SectionIdPattern('SCOPE-SCOP-xxx')
  @ContentHelp(
    'Add one entry per assumption that underpins the scope '
    'boundaries. State what is assumed and the impact if it proves false.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> scopeAssumptions = [];
}

/// A scope item entry (in-scope or out-of-scope).
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §6 — system scope & boundaries'],
  'A single scope item — its description, category, and the rationale for '
  'including or excluding it.',
)
@SectionId('SIE')
class ScopeItemEntry extends DocSpecsSection {
  @Form([
    Field(
      'itemDescription',
      String,
      'Item Description',
      required: true,
      hint: 'Describe the feature, process, or system in scope or excluded',
    ),
    Field(
      'category',
      String,
      'Category (Feature, Process, User Group, System, Data, Geography, etc.)',
      hint: 'Feature, Process, User Group, System, Data, Geography, etc.',
    ),
    Field(
      'rationale',
      String,
      'Rationale (why included or excluded)',
      hint: 'Why this item is included or excluded',
    ),
    Field(
      'relatedRequirements',
      String,
      'Related Requirements (requirement IDs if applicable)',
      hint: 'Requirement IDs related to this item, if applicable',
    ),
  ])
  @override
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
class DeferredScopeItemEntry extends DocSpecsSection {
  @Form([
    Field(
      'itemDescription',
      String,
      'Item Description',
      required: true,
      hint: 'Describe the item being deferred to a future phase',
    ),
    Field(
      'category',
      String,
      'Category (Feature, Process, etc.)',
      hint: 'Feature, Process, etc.',
    ),
    Field(
      'targetPhase',
      String,
      'Target Phase (when this will be addressed)',
      hint: 'Which future phase will address this item',
    ),
    Field(
      'deferralReason',
      String,
      'Deferral Reason (why not in current scope)',
      hint: 'Why this item is not in the current scope',
    ),
    Field(
      'dependencies',
      String,
      'Dependencies (what must be done before this can be addressed)',
      hint: 'What must be done before this can be addressed',
    ),
    Field(
      'estimatedEffort',
      String,
      'Estimated Effort (rough sizing for planning purposes)',
      hint: 'Rough sizing for planning purposes',
    ),
  ])
  @override
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
@ContentHelp(
  'Describe the system in its operational context. Include: '
  'how it fits in the IT landscape, who interacts with it, '
  'external systems it connects to, and a context diagram.',
)
@SectionId('SYCTX')
class SystemContext extends DocSpecsSection {
  @ContentType(
    'description',
    'High-level overview of the system context '
        'and its position in the overall enterprise architecture.',
  )
  @override
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
@ContentHelp(
  'Provide a context diagram showing the system as a black box '
  'with all external entities (users, systems, organizations) and '
  'the data/control flows between them.',
)
@SectionId('CD')
class ContextDiagram extends DocSpecsSection {
  @ContentHelp(
    'Provide a narrative overview of the context diagram and '
    'what the depicted black-box view represents.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Context diagram in Mermaid format.
  @SectionId('CD-DIAG')
  @ContentType(
    'mermaid-flowchart',
    'Context diagram showing the system '
        'as a central node with external actors and systems connected by '
        'labeled data flows',
  )
  @ContentHelp(
    'Create a Mermaid flowchart with the system in the center '
    'and all external entities around it. Label edges with data flow '
    'descriptions (e.g., "orders", "payments", "notifications").',
  )
  @SerializationOrder(1)
  DocSpecsSection? diagram;

  /// Diagram legend and conventions.
  @SectionId('CD-LEGE')
  @ContentType(
    'description',
    'Legend explaining shapes, colors, and '
        'line styles used in the diagram.',
  )
  @SerializationOrder(2)
  DocSpecsSection? legend;
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
@ContentHelp(
  'Describe how this system fits in the overall IT architecture. '
  'What role does it play? What other systems does it complement or replace?',
)
@SectionId('ILP')
class ItLandscapePosition extends DocSpecsSection {
  @ContentHelp(
    'Provide a narrative overview of the system\'s position '
    'within the IT landscape before the structured details below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// IT Landscape Position Details (form).
  @Form([
    Field(
      'architectureLayer',
      String,
      'Architecture Layer (Presentation, Business, Data, Integration)',
      hint: 'Which architecture layer this system primarily belongs to',
    ),
    Field(
      'applicationCategory',
      String,
      'Application Category (Core, Support, Management, Infrastructure)',
      hint: 'The portfolio category this application falls under',
    ),
    Field(
      'portfolioRole',
      String,
      'Portfolio Role (Strategic, Key Operational, Support, Legacy)',
      hint: 'The strategic role this system plays in the portfolio',
    ),
    Field(
      'replacedSystems',
      String,
      'Replaced Systems (systems this will replace or retire)',
      hint: 'Systems this will replace or retire',
    ),
    Field(
      'complementarySystems',
      String,
      'Complementary Systems (systems this works alongside)',
      hint: 'Systems this works alongside',
    ),
    Field(
      'dependsOnSystems',
      String,
      'Depends On Systems (systems this requires to operate)',
      hint: 'Systems this requires to operate',
    ),
    Field(
      'dependentSystems',
      String,
      'Dependent Systems (systems that will depend on this)',
      hint: 'Systems that will depend on this one',
    ),
    Field(
      'dataOwnership',
      String,
      'Data Ownership (what master data does this system own)',
      hint: 'What master data this system owns',
    ),
    Field(
      'integrationPattern',
      String,
      'Primary Integration Pattern (API, Event, Batch, Real-time)',
      hint: 'The primary integration pattern used',
    ),
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
@ContentHelp(
  'List all external actors (human users, organizations, '
  'external parties) that interact with the system.',
)
@SectionId('EA')
class ExternalActors extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of external actors and '
        'their interaction patterns with the system.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Actor entries — contains 1+× ExternalActorEntry.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
  ], 'The set of individual external-actor entries for this system.')
  @SectionId('EAE-ACTO-LST')
  @SectionIdPattern('EAE-ACTO-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per external actor or actor category '
    'that interacts with the system.',
  )
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
class ExternalActorEntry extends DocSpecsSection {
  @Form([
    Field(
      'actorName',
      String,
      'Actor Name',
      required: true,
      hint: 'The name of this external actor',
    ),
    Field(
      'actorType',
      String,
      'Actor Type (Internal User, External User, Organization, '
          'Partner, Customer, Regulator, etc.)',
      required: true,
      hint: 'The category of actor',
    ),
    Field(
      'description',
      String,
      'Actor Description',
      hint: 'A short description of this actor',
    ),
    Field(
      'interactionPurpose',
      String,
      'Interaction Purpose (why they interact with the system)',
      hint: 'Why this actor interacts with the system',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Interaction cadence and exchanged information.
  @SectionId('EAEI')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
      'BABOK v3 §10.43 — stakeholder/actor analysis',
    ],
    'Captures the cadence and channel of an actor\'s interaction and the '
    'information exchanged with the system.',
  )
  @Form([
    Field(
      'interactionFrequency',
      String,
      'Interaction Frequency (Real-time, Daily, Weekly, On-demand)',
      hint: 'How often this actor interacts with the system',
    ),
    Field(
      'interactionChannel',
      String,
      'Interaction Channel (Web UI, Mobile App, API, Email, etc.)',
      hint: 'The channel through which the interaction occurs',
    ),
    Field(
      'dataExchanged',
      String,
      'Data Exchanged (what information flows to/from this actor)',
      hint: 'What information flows to and from this actor',
    ),
    Field(
      'accessLevel',
      String,
      'Access Level (Read, Write, Admin, API-only, etc.)',
      hint: 'The level of access this actor has',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? interaction;

  /// Access, authentication, and context details.
  @SectionId('EAEC')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
      'ISO/IEC 27001 Annex A — access control',
    ],
    'Captures an actor\'s access, authentication, location, and volume '
    'context relative to the system.',
  )
  @Form([
    Field(
      'authenticationMethod',
      String,
      'Authentication Method (SSO, Password, Certificate, API Key, etc.)',
      hint: 'How this actor authenticates',
    ),
    Field(
      'location',
      String,
      'Location (On-site, Remote, Mobile, Global, etc.)',
      hint: 'Where this actor accesses the system from',
    ),
    Field(
      'volumeEstimate',
      String,
      'Volume Estimate (number of actors, transactions per day)',
      hint: 'Estimated number of actors or transactions per day',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? context;

  /// Interaction scenarios for this actor.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §6 — external interfaces & actors',
  ], 'The set of interaction-scenario entries for this actor.')
  @SectionId('INTER-INTE-LST')
  @SectionIdPattern('INTER-INTE-xxx')
  @ContentHelp(
    'Add one entry per interaction scenario between this actor '
    'and the system.',
  )
  @SerializationOrder(3)
  List<DocSpecsSection> interactionScenarios = [];
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
@ContentHelp(
  'List all external systems, services, and APIs that this '
  'system will integrate with. Include both incoming and outgoing '
  'integrations.',
)
@SectionId('ESC')
class ExternalSystemsContext extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of external system integrations '
        'and integration architecture.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// External system entries — contains 0+× ExternalSystemContextEntry.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §6 — external system interfaces',
  ], 'The set of individual external-system integration entries.')
  @SectionId('EXSYCOEN-SYST-LST')
  @SectionIdPattern('EXSYCOEN-SYST-xxx')
  @ContentHelp(
    'Add one entry per external system that this system '
    'integrates with.',
  )
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
class ExternalSystemContextEntry extends DocSpecsSection {
  @Form([
    Field(
      'systemName',
      String,
      'System Name',
      required: true,
      hint: 'The name of this external system',
    ),
    Field(
      'systemOwner',
      String,
      'System Owner (organization/department)',
      hint: 'The organization or department that owns this system',
    ),
    Field(
      'systemType',
      String,
      'System Type (ERP, CRM, Database, API, SaaS, Legacy, etc.)',
      required: true,
      hint: 'The category of external system',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Integration intent and exchanged information.
  @SectionId('EXSYCOENIN')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — external system interfaces',
      'ISO/IEC/IEEE 42010 — context',
    ],
    'Captures the direction, purpose, data, and method of an external '
    'system integration.',
  )
  @Form([
    Field(
      'integrationDirection',
      String,
      'Integration Direction (Inbound, Outbound, Bidirectional)',
      required: true,
      hint: 'The direction in which data flows for this integration',
    ),
    Field(
      'integrationPurpose',
      String,
      'Integration Purpose (what business need does this serve)',
      hint: 'The business need this integration serves',
    ),
    Field(
      'dataExchanged',
      String,
      'Data Exchanged (what data flows between systems)',
      hint: 'What data flows between the systems',
    ),
    Field(
      'integrationMethod',
      String,
      'Integration Method (REST API, SOAP, File Transfer, Database, '
          'Message Queue, Event Stream, etc.)',
      hint: 'The technical method used for the integration',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? integration;

  /// Operational delivery characteristics.
  @SectionId('ESCEO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — external system interfaces',
      'ISO/IEC/IEEE 42010 — context',
    ],
    'Captures the operational delivery characteristics of an external '
    'system integration: frequency, volume, SLA, and error handling.',
  )
  @Form([
    Field(
      'integrationFrequency',
      String,
      'Integration Frequency (Real-time, Near-real-time, Batch, '
          'On-demand)',
      hint: 'How often the integration runs',
    ),
    Field(
      'dataVolume',
      String,
      'Data Volume (estimated records/transactions per time period)',
      hint: 'Estimated records or transactions per time period',
    ),
    Field(
      'sla',
      String,
      'SLA (availability, response time requirements)',
      hint: 'Availability and response-time requirements',
    ),
    Field(
      'errorHandling',
      String,
      'Error Handling (retry, dead-letter, manual intervention)',
      hint: 'How integration errors are handled',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;

  /// Security and support contacts.
  @SectionId('ESCEG')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — security boundaries',
      'ISO/IEC/IEEE 29148 §6 — external system interfaces',
    ],
    'Captures the security requirements and technical contact governing an '
    'external system integration.',
  )
  @Form([
    Field(
      'securityRequirements',
      String,
      'Security Requirements (encryption, authentication, network)',
      hint: 'Encryption, authentication, and network requirements',
    ),
    Field(
      'contactPerson',
      String,
      'Contact Person (technical contact)',
      hint: 'The technical contact for this integration',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// Data mapping details.
  @SectionId('EXSYCOEN-DATA')
  @ContentType(
    'description',
    'Details of data transformation and '
        'mapping between systems.',
  )
  @SerializationOrder(4)
  DocSpecsSection? dataMapping;
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
@ContentHelp(
  'Define the trust boundaries (security zones) that the system '
  'operates within and crosses. This is important for security design.',
)
@SectionId('TB')
class TrustBoundaries extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of trust boundaries and '
        'security zones relevant to this system.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Trust boundary entries — contains 0+× TrustBoundaryEntry.
  @StandardReferences([
    'ISO/IEC 27001 Annex A — security boundaries',
  ], 'The set of individual trust-boundary entries for this system.')
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
class TrustBoundaryEntry extends DocSpecsSection {
  @Form([
    Field(
      'boundaryName',
      String,
      'Boundary Name',
      required: true,
      hint: 'The name of this trust boundary',
    ),
    Field(
      'boundaryType',
      String,
      'Boundary Type (Network Zone, Authentication Domain, '
          'Organizational, Legal/Regulatory, Cloud/On-Prem)',
      required: true,
      hint: 'The category of trust boundary',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'A short description of this boundary',
    ),
    Field(
      'componentsCrossing',
      String,
      'Components Crossing (which parts of the system cross this boundary)',
      hint: 'Which parts of the system cross this boundary',
    ),
    Field(
      'protectionMechanisms',
      String,
      'Protection Mechanisms (firewall, encryption, authentication, etc.)',
      hint: 'Mechanisms protecting this boundary',
    ),
    Field(
      'trustLevel',
      String,
      'Trust Level (Untrusted, Semi-trusted, Trusted, Highly Trusted)',
      hint: 'The trust level on the other side of this boundary',
    ),
    Field(
      'complianceImplications',
      String,
      'Compliance Implications (regulatory requirements for crossing)',
      hint: 'Regulatory requirements for crossing this boundary',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 4.1.2.6. Organizational Context.
///
/// Organizational units, departments, and business areas that the system
/// serves or interacts with.
@StandardReferences(
  ['TOGAF — organization context', 'BABOK v3 §10 — organizational modelling'],
  'Captures the organizational units, departments, and business areas the '
  'system serves or interacts with.',
)
@ContentHelp(
  'Describe the organizational context: which departments, '
  'business units, and organizational structures are involved.',
)
@SectionId('OC')
class OrganizationalContext extends DocSpecsSection {
  @ContentHelp(
    'Provide a narrative overview of the organizational context '
    'before the structured organizational-unit entries below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Organizational unit entries — contains 0+× OrganizationalUnitContextEntry.
  @StandardReferences([
    'TOGAF — organization context',
  ], 'The set of individual organizational-unit entries for this system.')
  @SectionId('OUCE-ORGA-LST')
  @SectionIdPattern('OUCE-ORGA-xxx')
  @ContentHelp(
    'Add one entry per organizational unit that uses or '
    'is affected by the system.',
  )
  @SerializationOrder(1)
  List<OrganizationalUnitContextEntry> organizationalUnits = [];

  /// Business process coverage.
  @SectionId('OC-BUSI')
  @ContentType(
    'description',
    'Which business processes does this system '
        'support or automate?',
  )
  @SerializationOrder(2)
  DocSpecsSection? businessProcessCoverage;
}

/// An organizational unit context entry (form).
@StandardReferences(
  ['TOGAF — organization context', 'BABOK v3 §10 — organizational modelling'],
  'Captures a single organizational unit that uses or is affected by the '
  'system, including its role and responsibilities.',
)
@SectionId('OUCE')
class OrganizationalUnitContextEntry extends DocSpecsSection {
  @Form([
    Field(
      'unitName',
      String,
      'Unit Name',
      required: true,
      hint: 'The name of this organizational unit',
    ),
    Field(
      'unitType',
      String,
      'Unit Type (Department, Division, Team, Business Unit, '
          'Subsidiary, External Partner)',
      hint: 'The category of organizational unit',
    ),
    Field(
      'role',
      String,
      'Role (Primary User, Secondary User, '
          'Data Provider, Beneficiary, Sponsor)',
      hint: 'The role this unit plays relative to the system',
    ),
    Field(
      'responsibilities',
      String,
      'Responsibilities (what they do with/for the system)',
      hint: 'What this unit does with or for the system',
    ),
    Field(
      'headcount',
      String,
      'Headcount (estimated number of users)',
      hint: 'Estimated number of users in this unit',
    ),
    Field(
      'location',
      String,
      'Location (geographic location)',
      hint: 'The geographic location of this unit',
    ),
    Field(
      'timezone',
      String,
      'Timezone (primary operating timezone)',
      hint: 'The primary operating timezone of this unit',
    ),
    Field(
      'keyContacts',
      String,
      'Key Contacts (business contacts)',
      hint: 'Business contacts for this unit',
    ),
  ])
  @override
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
@ContentHelp(
  'Describe the deployment context: where the system will be '
  'deployed, what infrastructure it will use, and deployment constraints.',
)
@SectionId('DC')
class DeploymentContext extends DocSpecsSection {
  @ContentHelp(
    'Provide a narrative overview of the deployment context '
    'before the structured deployment details below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Deployment Context Details (form).
  @Form([
    Field(
      'deploymentModel',
      String,
      'Deployment Model (On-Premises, Cloud, Hybrid, Multi-Cloud)',
      hint: 'The overall deployment model',
    ),
    Field(
      'cloudProvider',
      String,
      'Cloud Provider (AWS, Azure, GCP, Private Cloud, N/A)',
      hint: 'The cloud provider, if any',
    ),
    Field(
      'hostingEnvironment',
      String,
      'Hosting Environment (Containers, VMs, Serverless, Bare Metal)',
      hint: 'The hosting environment type',
    ),
    Field(
      'dataCenter',
      String,
      'Data Center (location, name, or identifier)',
      hint: 'The data center location, name, or identifier',
    ),
    Field(
      'geographicDistribution',
      String,
      'Geographic Distribution (Single region, Multi-region, Global)',
      hint: 'How the deployment is distributed geographically',
    ),
    Field(
      'availabilityZones',
      String,
      'Availability Zones (redundancy configuration)',
      hint: 'The redundancy / availability-zone configuration',
    ),
    Field(
      'networkZone',
      String,
      'Network Zone (DMZ, Internal, Private, Public)',
      hint: 'The network zone the system is deployed in',
    ),
    Field(
      'scalingModel',
      String,
      'Scaling Model (Horizontal, Vertical, Auto-scaling, Manual)',
      hint: 'The scaling model used',
    ),
    Field(
      'disasterRecovery',
      String,
      'Disaster Recovery (DR site, strategy)',
      hint: 'The disaster-recovery site and strategy',
    ),
    Field(
      'environmentTypes',
      String,
      'Environment Types (Dev, Test, Staging, Production, DR)',
      hint: 'Which environment types exist',
    ),
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
@ContentHelp(
  'Describe the regulatory and compliance context: which '
  'regulations apply, what compliance requirements exist.',
)
@SectionId('RC1')
class RegulatoryContext extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of the regulatory environment '
        'and compliance requirements affecting this system.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Applicable regulations — contains 0+× ApplicableRegulationEntry.
  @StandardReferences([
    'ISO/IEC 27001 — compliance with legal & contractual requirements',
  ], 'The set of individual applicable-regulation entries for this system.')
  @SectionId('ARE-REGU-LST')
  @SectionIdPattern('ARE-REGU-xxx')
  @ContentHelp(
    'Add one entry per applicable regulation or compliance '
    'requirement.',
  )
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
class ApplicableRegulationEntry extends DocSpecsSection {
  @Form([
    Field(
      'regulationName',
      String,
      'Regulation Name',
      required: true,
      hint: 'The name of this regulation',
    ),
    Field(
      'regulationCode',
      String,
      'Regulation Code / Reference',
      hint: 'The code or reference identifier for this regulation',
    ),
    Field(
      'regulationType',
      String,
      'Regulation Type (Privacy, Security, Financial, Industry, '
          'Data Retention, Accessibility)',
      required: true,
      hint: 'The category of regulation',
    ),
    Field(
      'jurisdiction',
      String,
      'Jurisdiction (Geographic or organizational scope)',
      hint: 'The geographic or organizational scope of this regulation',
    ),
    Field(
      'applicability',
      String,
      'Applicability (why this regulation applies to this system)',
      hint: 'Why this regulation applies to this system',
    ),
    Field(
      'keyRequirements',
      String,
      'Key Requirements (summary of main requirements)',
      hint: 'A summary of the main requirements',
    ),
    Field(
      'complianceStatus',
      String,
      'Compliance Status (Compliant, Partially Compliant, Non-Compliant, '
          'To Be Assessed)',
      hint: 'The current compliance status',
    ),
    Field(
      'complianceOwner',
      String,
      'Compliance Owner (who is responsible for compliance)',
      hint: 'Who is responsible for compliance',
    ),
    Field(
      'auditRequirements',
      String,
      'Audit Requirements (audit frequency, type)',
      hint: 'Audit frequency and type required',
    ),
    Field(
      'penalties',
      String,
      'Penalties (consequences of non-compliance)',
      hint: 'Consequences of non-compliance',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Specific compliance measures for this regulation.
  @StandardReferences([
    'ISO/IEC 27001 — compliance with legal & contractual requirements',
  ], 'The set of specific compliance-measure entries for this regulation.')
  @SectionId('COMPL-COMP-LST')
  @SectionIdPattern('COMPL-COMP-xxx')
  @ContentHelp(
    'Add one entry per compliance measure taken to satisfy '
    'this regulation.',
  )
  @SerializationOrder(1)
  List<DocSpecsSection> complianceMeasures = [];
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
@ContentHelp(
  'Describe the business domain and task area this system '
  'addresses. Define the domain vocabulary and key concepts that will '
  'be used throughout the project documentation. This establishes '
  'the ubiquitous language for the project.',
)
@SectionId('BD')
class BusinessDomain extends DocSpecsSection {
  @ContentType(
    'description',
    'High-level overview of the business domain '
        'and task area, explaining what business activities and processes '
        'this system will support.',
  )
  @override
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
@ContentHelp(
  'Provide a comprehensive overview of the business domain: '
  'what area of business it covers, its importance to the organization, '
  'and how it relates to other business domains.',
)
@SectionId('DO')
class DomainOverview extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Domain Overview Details (form).
  @Form([
    Field(
      'domainName',
      String,
      'Domain Name',
      required: true,
      hint: 'Name of the business domain this section describes',
    ),
    Field(
      'domainDescription',
      String,
      'Domain Description (what this domain encompasses)',
      hint: 'What business activities and concepts this domain covers',
    ),
    Field(
      'businessImportance',
      String,
      'Business Importance (why this domain matters to the organization)',
      hint: 'Why this domain is important to the organization',
    ),
    Field(
      'industryContext',
      String,
      'Industry Context (how this domain fits in the industry)',
      hint: 'How this domain fits within the broader industry',
    ),
    Field(
      'relatedDomains',
      String,
      'Related Domains (other business domains this interacts with)',
      hint: 'Other business domains this one interacts with',
    ),
    Field(
      'domainOwner',
      String,
      'Domain Owner (business unit or person responsible)',
      hint: 'Business unit or person responsible for this domain',
    ),
    Field(
      'keyStakeholders',
      String,
      'Key Stakeholders (who has interest in this domain)',
      hint: 'Who has a stake or interest in this domain',
    ),
    Field(
      'domainMaturity',
      String,
      'Domain Maturity (Emerging, Established, Mature, Legacy)',
      hint: 'Emerging / Established / Mature / Legacy',
    ),
    Field(
      'changeFrequency',
      String,
      'Change Frequency (how often this domain changes)',
      hint: 'How often this domain is expected to change',
    ),
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
@ContentHelp(
  'Define all domain-specific terms and their meanings. '
  'This glossary establishes the ubiquitous language - the shared '
  'vocabulary that all team members and stakeholders will use.',
)
@SectionId('DV')
class DomainVocabulary extends DocSpecsSection {
  @ContentType(
    'description',
    'Introduction to the domain vocabulary '
        'and guidelines for using consistent terminology.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Vocabulary entries — contains 1+× DomainTermEntry.
  @StandardReferences([
    'Domain-Driven Design — ubiquitous language',
    'ISO/IEC/IEEE 24765 — vocabulary/terms',
  ], 'The set of individual domain-term glossary entries.')
  @SectionId('DTE-TERM-LST')
  @SectionIdPattern('DTE-TERM-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per domain term. Include all business-specific '
    'terms that may be unfamiliar or have domain-specific meanings.',
  )
  @SerializationOrder(1)
  List<DomainTermEntry> terms = [];
}

/// A domain term entry (form).
@StandardReferences([
  'Domain-Driven Design — ubiquitous language',
  'ISO/IEC/IEEE 24765 — vocabulary/terms',
], 'A single domain-vocabulary term with its definition and usage detail.')
@SectionId('DTE')
class DomainTermEntry extends DocSpecsSection {
  @Form([
    Field(
      'term',
      String,
      'Term',
      required: true,
      hint: 'The domain term being defined',
    ),
    Field(
      'definition',
      String,
      'Definition',
      required: true,
      hint: 'Precise meaning of the term in this domain',
    ),
    Field(
      'synonyms',
      String,
      'Synonyms (alternative terms sometimes used)',
      hint: 'Alternative terms sometimes used for the same concept',
    ),
    Field(
      'antiPatterns',
      String,
      'Anti-Patterns (terms to avoid, incorrect usage)',
      hint: 'Terms to avoid or incorrect usages of this term',
    ),
    Field(
      'examples',
      String,
      'Examples (usage examples)',
      hint: 'Concrete examples of the term in use',
    ),
    Field(
      'relatedTerms',
      String,
      'Related Terms (linked concepts)',
      hint: 'Other terms or concepts linked to this one',
    ),
    Field(
      'category',
      String,
      'Category (Entity, Process, Role, Metric, Status, etc.)',
      hint: 'Entity / Process / Role / Metric / Status, etc.',
    ),
    Field(
      'source',
      String,
      'Source (where this definition comes from: industry, company, etc.)',
      hint: 'Where this definition originates (industry, company, etc.)',
    ),
    Field(
      'abbreviation',
      String,
      'Abbreviation (if commonly abbreviated)',
      hint: 'Common abbreviation for the term, if any',
    ),
  ])
  @override
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
@ContentHelp(
  'Describe the key concepts (entities, value objects, aggregates) '
  'in the domain. This is the conceptual domain model showing core '
  'business objects and their relationships.',
)
@SectionId('KC')
class KeyConcepts extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Conceptual domain model diagram.
  @SectionId('KC-CONC')
  @ContentType(
    'mermaid-classDiagram',
    'Conceptual domain model showing '
        'key entities and their relationships',
  )
  @ContentHelp(
    'Create a Mermaid class diagram showing the main domain '
    'concepts and their relationships. Focus on business concepts, '
    'not technical implementation.',
  )
  @SerializationOrder(1)
  DocSpecsSection? conceptualModelDiagram;

  /// Key concept entries — contains 1+× KeyConceptEntry.
  @StandardReferences([
    'Domain-Driven Design — domain model concepts',
    'BABOK v3 §10 — concept modelling',
  ], 'The set of individual key-concept entries for the domain.')
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
class KeyConceptEntry extends DocSpecsSection {
  @Form([
    Field(
      'conceptName',
      String,
      'Concept Name',
      required: true,
      hint: 'Name of the business concept or entity',
    ),
    Field(
      'conceptType',
      String,
      'Concept Type (Entity, Value Object, Aggregate Root, Event, Service)',
      required: true,
      hint: 'Entity / Value Object / Aggregate Root / Event / Service',
    ),
    Field(
      'description',
      String,
      'Description',
      required: true,
      hint: 'What this concept represents in the domain',
    ),
    Field(
      'keyAttributes',
      String,
      'Key Attributes (main properties of this concept)',
      hint: 'Main properties or attributes of this concept',
    ),
    Field(
      'identifiedBy',
      String,
      'Identified By (what uniquely identifies instances)',
      hint: 'What uniquely identifies instances of this concept',
    ),
    Field(
      'lifecycle',
      String,
      'Lifecycle (how instances are created, modified, archived)',
      hint: 'How instances are created, modified, and archived',
    ),
    Field(
      'ownedBy',
      String,
      'Owned By (which business function owns this concept)',
      hint: 'Which business function owns this concept',
    ),
    Field(
      'relatedConcepts',
      String,
      'Related Concepts (other concepts this relates to)',
      hint: 'Other concepts this one relates to',
    ),
    Field(
      'businessRules',
      String,
      'Business Rules (rules that govern this concept)',
      hint: 'Business rules that govern this concept',
    ),
    Field(
      'volumeEstimate',
      String,
      'Volume Estimate (expected number of instances)',
      hint: 'Expected number of instances of this concept',
    ),
  ])
  @override
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
@ContentHelp(
  'Define clear boundaries for this domain: what concepts, '
  'processes, and responsibilities are within scope, and what belongs '
  'to adjacent domains. This establishes the bounded context.',
)
@SectionId('DB')
class DomainBoundaries extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Context map showing domain boundaries.
  @SectionId('DB-CONT')
  @ContentType(
    'mermaid-flowchart',
    'Context map showing this domain '
        'and its relationships to adjacent domains',
  )
  @ContentHelp(
    'Create a context map showing this domain (bounded context) '
    'and how it relates to other domains/contexts.',
  )
  @SerializationOrder(1)
  DocSpecsSection? contextMap;

  /// Within-scope items.
  @SectionId('DB-WITH')
  @ContentType(
    'description',
    'Concepts, processes, and responsibilities '
        'that are within this domain\'s scope.',
  )
  @SerializationOrder(2)
  DocSpecsSection? withinScope;

  /// Outside-scope items.
  @SectionId('DB-OUTS')
  @ContentType(
    'description',
    'Concepts and responsibilities that belong '
        'to other domains and are outside this domain\'s scope.',
  )
  @SerializationOrder(3)
  DocSpecsSection? outsideScope;

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
  @ContentHelp(
    'Define interfaces to adjacent domains - how this domain '
    'communicates with and shares data with other domains.',
  )
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
class DomainInterfaceEntry extends DocSpecsSection {
  @Form([
    Field(
      'adjacentDomain',
      String,
      'Adjacent Domain Name',
      required: true,
      hint: 'Name of the adjacent domain this interface connects to',
    ),
    Field(
      'interfaceType',
      String,
      'Interface Type (Shared Kernel, Customer-Supplier, '
          'Conformist, Anti-Corruption Layer, Published Language)',
      required: true,
      hint:
          'Shared Kernel / Customer-Supplier / Conformist / '
          'Anti-Corruption Layer / Published Language',
    ),
    Field(
      'direction',
      String,
      'Direction (Upstream, Downstream, Bidirectional)',
      hint: 'Upstream / Downstream / Bidirectional',
    ),
    Field(
      'dataExchanged',
      String,
      'Data Exchanged (what information crosses the boundary)',
      hint: 'What information crosses this domain boundary',
    ),
    Field(
      'integrationMechanism',
      String,
      'Integration Mechanism (API, Events, Shared Database, etc.)',
      hint: 'API / Events / Shared Database, etc.',
    ),
    Field(
      'translationRequired',
      String,
      'Translation Required (does data need transformation?)',
      hint: 'Whether data needs transformation across the boundary',
    ),
    Field(
      'owner',
      String,
      'Owner (who owns this interface)',
      hint: 'Who owns and maintains this interface',
    ),
  ])
  @override
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
@ContentHelp(
  'Document the business rules that govern this domain. '
  'Include policies, constraints, calculations, and decision logic.',
)
@SectionId('DBR')
class DomainBusinessRules extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of business rules and their '
        'importance in this domain.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Business rule entries — contains 0+× BusinessRuleEntry.
  @StandardReferences([
    'BABOK v3 §10.9 — business rules analysis',
    'ISO/IEC/IEEE 29148 §6 — business rules',
  ], 'The set of individual business-rule entries for this domain.')
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
class DomainBusinessRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'ruleId',
      String,
      'Rule ID',
      required: true,
      hint: 'Unique identifier for this business rule',
    ),
    Field(
      'ruleName',
      String,
      'Rule Name',
      required: true,
      hint: 'Short descriptive name for this rule',
    ),
    Field(
      'ruleType',
      String,
      'Rule Type (Constraint, Calculation, Derivation, Action-Trigger, '
          'Authorization, Validation)',
      required: true,
      hint:
          'Constraint / Calculation / Derivation / Action-Trigger / '
          'Authorization / Validation',
    ),
    Field(
      'description',
      String,
      'Description (plain language)',
      required: true,
      hint: 'Plain-language statement of what this rule requires',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Formal definition and applicability.
  @SectionId('DBRED')
  @StandardReferences(
    [
      'BABOK v3 §10.9 — business rules analysis',
      'ISO/IEC/IEEE 29148 §6 — business rules',
    ],
    'The formal, unambiguous statement of a business rule and the conditions '
    'under which it applies.',
  )
  @Form([
    Field(
      'formalStatement',
      String,
      'Formal Statement (precise, unambiguous statement)',
      hint: 'Precise, unambiguous statement of the rule',
    ),
    Field(
      'appliesTo',
      String,
      'Applies To (which concepts/processes this rule governs)',
      hint: 'Which concepts or processes this rule governs',
    ),
    Field(
      'conditions',
      String,
      'Conditions (when this rule applies)',
      hint: 'The conditions under which this rule applies',
    ),
    Field(
      'consequences',
      String,
      'Consequences (what happens when rule is triggered/violated)',
      hint: 'What happens when the rule is triggered or violated',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Priority, provenance, and interpretation aids.
  @SectionId('DBREG')
  @StandardReferences(
    [
      'BABOK v3 §10.9 — business rules analysis',
      'ISO/IEC/IEEE 29148 §6 — business rules',
    ],
    'The governance metadata for a business rule: precedence, provenance, '
    'exceptions, and illustrative examples.',
  )
  @Form([
    Field(
      'priority',
      String,
      'Priority (if rules conflict, which takes precedence)',
      hint: 'Which rule takes precedence when rules conflict',
    ),
    Field(
      'source',
      String,
      'Source (regulation, policy, business decision)',
      hint: 'Origin of the rule: regulation, policy, business decision',
    ),
    Field(
      'exceptions',
      String,
      'Exceptions (when rule does not apply)',
      hint: 'Circumstances in which the rule does not apply',
    ),
    Field(
      'examples',
      String,
      'Examples (concrete examples of rule application)',
      hint: 'Concrete examples of the rule being applied',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;
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
@ContentHelp(
  'Describe the main business processes within this domain. '
  'Focus on business activities, not system implementation.',
)
@SectionId('DP')
class DomainProcesses extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Process overview diagram.
  @SectionId('DP-PROC')
  @ContentType(
    'mermaid-flowchart',
    'High-level process map showing '
        'main processes and their relationships',
  )
  @ContentHelp(
    'Create a process map showing the main business processes '
    'and how they interact.',
  )
  @SerializationOrder(1)
  DocSpecsSection? processOverviewDiagram;

  /// Domain process entries — contains 0+× DomainProcessEntry.
  @StandardReferences([
    'BABOK v3 §10.35 — process modelling',
    'ISO/IEC/IEEE 29148 §6 — business process context',
  ], 'The set of individual domain-process entries.')
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
class DomainProcessEntry extends DocSpecsSection {
  @Form([
    Field(
      'processName',
      String,
      'Process Name',
      required: true,
      hint: 'Name of the business process',
    ),
    Field(
      'processDescription',
      String,
      'Process Description',
      required: true,
      hint: 'What this process does and why it exists',
    ),
    Field(
      'processType',
      String,
      'Process Type (Core, Support, Management)',
      hint: 'Core / Support / Management',
    ),
    Field(
      'trigger',
      String,
      'Trigger (what initiates this process)',
      hint: 'What event or condition initiates this process',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Inputs, outputs, and participant flow.
  @SectionId('DPEF')
  @StandardReferences(
    [
      'BABOK v3 §10.35 — process modelling',
      'ISO/IEC/IEEE 29148 §6 — business process context',
    ],
    'The inputs, outputs, participants, and related processes that make up '
    'a domain process\'s flow.',
  )
  @Form([
    Field(
      'inputs',
      String,
      'Inputs (what data/artifacts are needed)',
      hint: 'Data or artifacts this process needs as input',
    ),
    Field(
      'outputs',
      String,
      'Outputs (what is produced)',
      hint: 'What this process produces',
    ),
    Field(
      'participants',
      String,
      'Participants (roles/actors involved)',
      hint: 'Roles or actors involved in this process',
    ),
    Field(
      'relatedProcesses',
      String,
      'Related Processes (processes that interact with this one)',
      hint: 'Other processes that interact with this one',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? flow;

  /// Operating cadence and coordination details.
  @SectionId('DPEO')
  @StandardReferences(
    [
      'BABOK v3 §10.35 — process modelling',
      'ISO/IEC/IEEE 29148 §6 — business process context',
    ],
    'The operating cadence of a domain process: frequency, duration, success '
    'criteria, and key decision points.',
  )
  @Form([
    Field(
      'frequency',
      String,
      'Frequency (how often this process runs)',
      hint: 'How often this process runs',
    ),
    Field(
      'duration',
      String,
      'Duration (typical time to complete)',
      hint: 'Typical time for the process to complete',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria (what defines successful completion)',
      hint: 'What defines successful completion of the process',
    ),
    Field(
      'keyDecisions',
      String,
      'Key Decisions (decision points within the process)',
      hint: 'Decision points within the process',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;

  /// Process flow details.
  @SerializationOrder(3)
  TextSection? processFlowDetails;
}

/// 4.1.3.7. Domain Events.
///
/// Significant business events that occur within this domain and
/// trigger actions or state changes.
@StandardReferences(
  ['Domain-Driven Design — domain events', 'BABOK v3 §10 — event analysis'],
  'Captures the significant business events that occur within this domain '
  'and trigger actions or state changes.',
)
@ContentHelp(
  'Document significant business events within this domain. '
  'Events represent things that happen which are important to the '
  'business and may trigger reactions.',
)
@SectionId('DE')
class DomainEvents extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of key domain events and '
        'their significance.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Domain event entries — contains 0+× DomainEventEntry.
  @StandardReferences([
    'Domain-Driven Design — domain events',
    'BABOK v3 §10 — event analysis',
  ], 'The set of individual domain-event entries.')
  @SectionId('DOEV-EVEN-LST')
  @SectionIdPattern('DOEV-EVEN-xxx')
  @ContentHelp('Add one entry per significant business event.')
  @SerializationOrder(1)
  List<DomainEventEntry> events = [];
}

/// A domain event entry (form).
@StandardReferences(
  ['Domain-Driven Design — domain events', 'BABOK v3 §10 — event analysis'],
  'A single domain event with its trigger, source, payload, subscribers, '
  'reactions, and business impact.',
)
@SectionId('DOEV')
class DomainEventEntry extends DocSpecsSection {
  @Form([
    Field(
      'eventName',
      String,
      'Event Name (past tense, e.g., OrderPlaced)',
      required: true,
      hint: 'Past-tense event name, e.g., OrderPlaced',
    ),
    Field(
      'eventDescription',
      String,
      'Event Description',
      required: true,
      hint: 'What this event represents in the business',
    ),
    Field(
      'eventType',
      String,
      'Event Type (State Change, Action Completed, Time-based, External)',
      hint: 'State Change / Action Completed / Time-based / External',
    ),
    Field(
      'trigger',
      String,
      'Trigger (what causes this event)',
      hint: 'What causes this event to occur',
    ),
    Field(
      'sourceEntity',
      String,
      'Source Entity (which concept generates this event)',
      hint: 'Which domain concept generates this event',
    ),
    Field(
      'eventData',
      String,
      'Event Data (what information is carried with the event)',
      hint: 'Information carried in the event payload',
    ),
    Field(
      'subscribers',
      String,
      'Subscribers (who/what reacts to this event)',
      hint: 'Who or what reacts to this event',
    ),
    Field(
      'reactions',
      String,
      'Reactions (what happens when this event occurs)',
      hint: 'What happens in response to this event',
    ),
    Field(
      'frequency',
      String,
      'Frequency (how often this event occurs)',
      hint: 'How often this event occurs',
    ),
    Field(
      'businessImpact',
      String,
      'Business Impact (significance of this event)',
      hint: 'Significance of this event to the business',
    ),
  ])
  @override
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
@ContentHelp(
  'Describe how different user categories interact with the system: '
  'access channels (web, mobile, API, CLI), interaction patterns (real-time, '
  'batch, notification-driven), access levels, session management, and '
  'multi-channel considerations.',
)
@SectionId('UIM')
class UserInteractionModel extends DocSpecsSection {
  @ContentType(
    'description',
    'High-level overview of user interaction model '
        'explaining how users access and interact with the system across '
        'different channels and contexts.',
  )
  @override
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
  Field(
    'primaryAccessChannel',
    String,
    'Primary Access Channel',
    hint: 'Web, Mobile App, Desktop App, API, CLI',
  ),
  Field(
    'channelCount',
    int,
    'Number of Access Channels',
    hint: 'Total count of access channels defined',
  ),
  Field(
    'interactionPatternCount',
    int,
    'Number of Interaction Patterns',
    hint: 'Total count of interaction patterns defined',
  ),
  Field(
    'accessLevelCount',
    int,
    'Number of Access Levels',
    hint: 'Total count of access levels defined',
  ),
  Field(
    'multiChannelSupport',
    String,
    'Multi-Channel Support',
    hint: 'None, Limited, Full',
  ),
  Field(
    'offlineCapability',
    String,
    'Offline Capability',
    hint: 'None, Read-only, Full',
  ),
  Field(
    'sessionManagement',
    String,
    'Session Management Approach',
    hint: 'Server-side, Client-side, Hybrid, Stateless',
  ),
  Field(
    'notificationChannels',
    String,
    'Notification Channels',
    hint: 'e.g., Email, SMS, Push, In-app',
  ),
])
@SectionId('UIMS')
class UserInteractionModelSummary extends DocSpecsSection {
  /// Summary content for interaction model.
  @ContentType(
    'aggregation',
    'Key metrics and classifications for '
        'user interaction model.',
  )
  @override
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
@ContentHelp(
  'Define all channels through which users can access the system. '
  'For each channel, specify target users, features available, and '
  'any channel-specific constraints.',
)
@SectionId('AC1')
class AccessChannels extends DocSpecsSection {
  @ContentHelp(
    'Provide an overview of the access channel landscape and how '
    'channels collectively serve the user base.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Channel architecture diagram.
  @SectionId('AC1-CHAN')
  @ContentType(
    'mermaid-flowchart',
    'Diagram showing access channels, '
        'their relationships, and user flows',
  )
  @ContentHelp(
    'Create a diagram showing how different channels connect '
    'to the system and serve different user categories.',
  )
  @SerializationOrder(1)
  DocSpecsSection? channelDiagram;

  /// Channel entries — contains 1+× InteractionChannelEntry.
  @StandardReferences([
    'ISO 9241-210 — interaction design',
    'ISO/IEC 25010 — usability/operability',
  ], 'The set of individual access-channel entries defined for the system.')
  @SectionId('ICE-CHAN-LST')
  @SectionIdPattern('ICE-CHAN-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per access channel. Include both primary '
    'and secondary channels.',
  )
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
class InteractionChannelEntry extends DocSpecsSection {
  @Form([
    Field(
      'channelName',
      String,
      'Channel Name',
      required: true,
      hint: 'e.g., Customer Web Portal, Mobile App, Admin API',
    ),
    Field(
      'channelId',
      String,
      'Channel ID',
      hint: 'Unique identifier for the channel',
    ),
    Field(
      'channelType',
      String,
      'Channel Type',
      required: true,
      hint:
          'Web, Mobile Native, Mobile Hybrid, Desktop, API, CLI, Voice, '
          'Kiosk, Embedded, IoT',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Platform and targeting.
  @SectionId('ICEP')
  @StandardReferences([
    'ISO 9241-210 — interaction design',
    'ISO/IEC 25010 — usability/operability',
  ], 'The platform/technology and target-user details for an access channel.')
  @Form([
    Field(
      'platform',
      String,
      'Platform/Technology',
      hint: 'e.g., Flutter Web, Flutter iOS/Android, REST API',
    ),
    Field(
      'targetUserCategories',
      String,
      'Target User Categories',
      hint: 'List of user category IDs this channel serves',
      refersTo: ['UCE.categoryId'],
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Purpose and scope of this channel',
    ),
    Field(
      'channelPriority',
      String,
      'Channel Priority',
      hint: 'Primary, Secondary, Tertiary',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? platform;

  /// Feature scope.
  @SectionId('ICEF')
  @StandardReferences(
    [
      'ISO 9241-210 — interaction design',
      'ISO/IEC 25010 — usability/operability',
    ],
    'The feature scope of an access channel: what is included, excluded, and '
    'its breadth.',
  )
  @Form([
    Field(
      'featureScope',
      String,
      'Feature Scope',
      hint: 'Full, Limited, Read-only, Specialized',
    ),
    Field(
      'featuresIncluded',
      String,
      'Features Included',
      hint: 'List of features available on this channel',
    ),
    Field(
      'featuresExcluded',
      String,
      'Features Excluded',
      hint: 'Features not available on this channel',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? features;

  /// Access and sync.
  @SectionId('ICEA')
  @StandardReferences(
    [
      'ISO 9241-210 — interaction design',
      'ISO/IEC 25010 — usability/operability',
    ],
    'The availability, performance, offline, sync, and authentication '
    'characteristics of an access channel.',
  )
  @Form([
    Field(
      'availabilityRequirement',
      String,
      'Availability Requirement',
      hint: '24/7, Business Hours, On-demand',
    ),
    Field(
      'performanceTarget',
      String,
      'Performance Target',
      hint: 'Response time, throughput expectations',
    ),
    Field(
      'offlineCapability',
      String,
      'Offline Capability',
      hint: 'None, Read-only, Limited Write, Full',
    ),
    Field(
      'syncStrategy',
      String,
      'Data Sync Strategy',
      hint: 'Real-time, Periodic, On-demand, Background',
    ),
    Field(
      'authenticationMethod',
      String,
      'Authentication Method',
      hint: 'OAuth, SAML, API Key, JWT, Biometric, MFA',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? access;

  /// Compliance and requirements.
  @SectionId('INCHENCO')
  @StandardReferences(
    [
      'EN 301 549 — ICT accessibility',
      'ISO/IEC 27001 Annex A — access control',
    ],
    'The device, browser, accessibility, localization, branding, and analytics '
    'compliance requirements for an access channel.',
  )
  @Form([
    Field(
      'deviceRequirements',
      String,
      'Device Requirements',
      hint: 'Minimum specifications, supported OS versions',
    ),
    Field(
      'browserSupport',
      String,
      'Browser Support',
      hint: 'Supported browsers and versions (for web)',
    ),
    Field(
      'accessibilityLevel',
      String,
      'Accessibility Level',
      hint: 'WCAG 2.1 Level A, AA, AAA',
    ),
    Field(
      'localizationSupport',
      String,
      'Localization Support',
      hint: 'Languages supported on this channel',
    ),
    Field(
      'brandingRequirements',
      String,
      'Branding Requirements',
      hint: 'Visual identity requirements for this channel',
    ),
    Field(
      'analyticsRequirements',
      String,
      'Analytics Requirements',
      hint: 'Tracking and analytics needed',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compliance;

  /// Channel-specific UI/UX specifications.
  @SectionId('CUS')
  @StandardReferences(
    ['ISO 9241-210 — UX design', 'Nielsen usability heuristics'],
    'The channel-specific user-experience specification: navigation, input, '
    'screen sizes, and interaction affordances.',
  )
  @Form([
    Field(
      'navigationModel',
      String,
      'Navigation Model',
      hint: 'Tab-based, Drawer, Bottom Nav, Sidebar, etc.',
    ),
    Field(
      'inputMethods',
      String,
      'Input Methods',
      hint: 'Touch, Keyboard, Voice, Gesture, Camera',
    ),
    Field(
      'screenSizes',
      String,
      'Screen Sizes Supported',
      hint: 'Phone, Tablet, Desktop, TV, Watch',
    ),
    Field(
      'orientationSupport',
      String,
      'Orientation Support',
      hint: 'Portrait, Landscape, Both',
    ),
    Field(
      'darkModeSupport',
      String,
      'Dark Mode Support',
      hint: 'None, Optional, System-adaptive',
    ),
    Field(
      'hapticFeedback',
      String,
      'Haptic Feedback',
      hint: 'Required, Optional, None',
    ),
    Field(
      'gestureSupport',
      String,
      'Gesture Support',
      hint: 'Swipe, Pinch, Long-press, etc.',
    ),
    Field(
      'keyboardShortcuts',
      String,
      'Keyboard Shortcuts',
      hint: 'List of required keyboard shortcuts',
    ),
  ])
  @ContentType('form', 'Channel-specific user experience specifications.')
  @SerializationOrder(5)
  DocSpecsSection? uxSpecification;

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

/// Channel-specific integration requirements.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §6 — external interfaces'],
  'A single channel-specific integration definition (push, analytics, '
  'crash reporting, payments, biometrics, etc.).',
)
@Form([
  Field(
    'pushNotificationService',
    String,
    'Push Notification Service',
    hint: 'FCM, APNs, Web Push',
  ),
  Field(
    'analyticsService',
    String,
    'Analytics Service',
    hint: 'Firebase Analytics, Mixpanel, etc.',
  ),
  Field(
    'crashReporting',
    String,
    'Crash Reporting',
    hint: 'Crashlytics, Sentry, etc.',
  ),
  Field(
    'deepLinking',
    String,
    'Deep Linking',
    hint: 'URL scheme, Universal Links, App Links',
  ),
  Field(
    'socialIntegration',
    String,
    'Social Integration',
    hint: 'Social login, sharing capabilities',
  ),
  Field(
    'paymentIntegration',
    String,
    'Payment Integration',
    hint: 'Apple Pay, Google Pay, Stripe, etc.',
  ),
  Field(
    'biometricIntegration',
    String,
    'Biometric Integration',
    hint: 'Face ID, Touch ID, Fingerprint',
  ),
])
@SectionId('CI')
class ChannelIntegrations extends DocSpecsSection {
  /// Integration requirements content.
  @ContentType('form', 'Channel-specific integration requirements.')
  @override
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
  ['ISO 9241-110 — dialogue principles', 'ISO 9241-210 — interaction patterns'],
  'The set of interaction patterns the system uses — real-time, batch, '
  'workflow, notification-driven, and scheduled.',
)
@ContentHelp(
  'Define the interaction patterns used in the system: real-time '
  'interactions, batch processing, workflow-driven tasks, notification-driven '
  'actions, and scheduled operations.',
)
@SectionId('IP')
class InteractionPatterns extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of interaction patterns and when '
        'each pattern is used.',
  )
  @override
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
  ['ISO 9241-110 — dialogue principles', 'ISO 9241-210 — interaction patterns'],
  'A single interaction-pattern definition: its type, triggers, runtime '
  'behavior, and usage.',
)
@SectionId('INPTN')
class InteractionPatternEntry extends DocSpecsSection {
  @Form([
    Field(
      'patternName',
      String,
      'Pattern Name',
      required: true,
      hint: 'e.g., Real-time Form Submission, Batch Report Generation',
    ),
    Field('patternId', String, 'Pattern ID', hint: 'Unique identifier'),
    Field(
      'patternType',
      String,
      'Pattern Type',
      required: true,
      hint:
          'Synchronous, Asynchronous, Batch, Scheduled, Event-driven, '
          'Workflow, Polling, Streaming',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Narrative summary and typical scenarios.
  @SectionId('IPED')
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO 9241-210 — interaction patterns',
    ],
    'The narrative description, use cases, and applicable user categories for '
    'an interaction pattern.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'What this pattern involves',
    ),
    Field(
      'useCases',
      String,
      'Use Cases',
      hint: 'List of use cases that follow this pattern',
    ),
    Field(
      'userCategories',
      String,
      'Applicable User Categories',
      hint: 'Which user categories use this pattern',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Trigger conditions and cadence.
  @SectionId('IPET')
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO 9241-210 — interaction patterns',
    ],
    'The trigger type, conditions, and expected frequency for an interaction '
    'pattern.',
  )
  @Form([
    Field(
      'triggerType',
      String,
      'Trigger Type',
      hint: 'User Action, System Event, Schedule, External Signal',
    ),
    Field(
      'triggerDetails',
      String,
      'Trigger Details',
      hint: 'Specific conditions that trigger this pattern',
    ),
    Field(
      'frequency',
      String,
      'Expected Frequency',
      hint: 'How often this pattern occurs',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? trigger;

  /// User experience and runtime behavior.
  @SectionId('IPEB')
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO 9241-210 — interaction patterns',
    ],
    'The runtime behavior of an interaction pattern: response time, feedback, '
    'error handling, and concurrency.',
  )
  @Form([
    Field(
      'responseTime',
      String,
      'Expected Response Time',
      hint: 'Immediate, Seconds, Minutes, Hours, Days',
    ),
    Field(
      'feedbackMechanism',
      String,
      'Feedback Mechanism',
      hint: 'Progress indicator, Status page, Email notification',
    ),
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'Retry, Rollback, Manual intervention, Notification',
    ),
    Field(
      'concurrencyHandling',
      String,
      'Concurrency Handling',
      hint: 'How concurrent requests are handled',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? behavior;

  /// Applicability and operational priority.
  @SectionId('IPEU')
  @StandardReferences([
    'ISO 9241-110 — dialogue principles',
    'ISO 9241-210 — interaction patterns',
  ], 'The applicability and operational priority of an interaction pattern.')
  @Form([
    Field(
      'priority',
      String,
      'Priority',
      hint: 'High, Medium, Low - for resource allocation',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? usage;
}

// ---------------------------------------------------------------------------
// 4.1.5.3 Access Levels
// ---------------------------------------------------------------------------

/// 4.1.5.3. Access Levels.
///
/// Defines the access level hierarchy and how permissions are structured
/// across user categories and system functions.
@StandardReferences(
  ['ISO/IEC 27001 Annex A.9 — access control', 'NIST RBAC — role-based access'],
  'The access-level hierarchy and authorization framework relating user '
  'categories to permissions.',
)
@ContentHelp(
  'Define access levels and how they relate to user categories, '
  'features, and data. This establishes the authorization framework.',
)
@SectionId('AL')
class AccessLevels extends DocSpecsSection {
  @ContentHelp(
    'Provide an overview of the access-level model and how levels '
    'structure authorization across the system.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Access level hierarchy diagram.
  @SectionId('AL-ACCE')
  @ContentType(
    'mermaid-flowchart',
    'Access level hierarchy showing '
        'inheritance and relationships',
  )
  @ContentHelp('Create a diagram showing the access level hierarchy.')
  @SerializationOrder(1)
  DocSpecsSection? accessLevelDiagram;

  /// Access level entries — contains 1+× AccessLevelEntry.
  @StandardReferences([
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — role-based access',
  ], 'The set of individual access-level entries defined for the system.')
  @SectionId('ACLV-LEVE-LST')
  @SectionIdPattern('ACLV-LEVE-xxx')
  @Min(1)
  @ContentHelp('Define each access level in the system.')
  @SerializationOrder(2)
  List<AccessLevelEntry> levels = [];

  /// Permission matrix linking access levels to features.
  @SectionId('AL-PERM')
  @ContentType(
    'description',
    'Matrix showing which access levels have '
        'which permissions. Can be a table or detailed description.',
  )
  @ContentHelp(
    'Create a permission matrix showing the relationship between '
    'access levels, features, and permissions.',
  )
  @SerializationOrder(3)
  DocSpecsSection? permissionMatrix;
}

/// An access level entry (form).
@StandardReferences(
  ['ISO/IEC 27001 Annex A.9 — access control', 'NIST RBAC — role-based access'],
  'A single access-level definition: its scope, granted permissions, and '
  'governance.',
)
@SectionId('ACLV')
class AccessLevelEntry extends DocSpecsSection {
  @Form([
    Field(
      'levelName',
      String,
      'Access Level Name',
      required: true,
      hint: 'e.g., Administrator, Power User, Standard User, Guest',
    ),
    Field('levelId', String, 'Level ID', hint: 'Unique identifier'),
    Field(
      'levelRank',
      int,
      'Level Rank',
      hint: 'Numeric rank (higher = more permissions)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope and hierarchy of this access level.
  @SectionId('ALES')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A.9 — access control',
      'NIST RBAC — role-based access',
    ],
    'The scope, inheritance, and applicable user categories of an access level.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'What this access level provides',
    ),
    Field(
      'inheritsFrom',
      String,
      'Inherits From',
      hint: 'Parent access level (if hierarchical)',
    ),
    Field(
      'userCategories',
      String,
      'Applicable User Categories',
      hint: 'Which user categories can have this level',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Permission surfaces granted by this level.
  @SectionId('ALEP')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A.9 — access control',
      'NIST RBAC — role-based access',
    ],
    'The permission surfaces (features, data, admin, API) granted by an access '
    'level.',
  )
  @Form([
    Field(
      'featureAccess',
      String,
      'Feature Access',
      hint: 'List of features accessible at this level',
    ),
    Field(
      'dataAccess',
      String,
      'Data Access Scope',
      hint: 'Own data, Team data, Department data, All data',
    ),
    Field(
      'adminCapabilities',
      String,
      'Administrative Capabilities',
      hint: 'Admin functions available at this level',
    ),
    Field('apiAccess', String, 'API Access', hint: 'API endpoints accessible'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? permissions;

  /// Restrictions and governance for this level.
  @SectionId('ALEG')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A.9 — access control',
      'NIST RBAC — role-based access',
    ],
    'The restrictions, audit requirements, and elevation process governing an '
    'access level.',
  )
  @Form([
    Field(
      'restrictions',
      String,
      'Restrictions',
      hint: 'Explicit restrictions or limitations',
    ),
    Field(
      'auditRequirements',
      String,
      'Audit Requirements',
      hint: 'Audit logging requirements for this level',
    ),
    Field(
      'elevationProcess',
      String,
      'Elevation Process',
      hint: 'How users can request higher access',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
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
@ContentHelp(
  'Define session management: session lifecycle, timeouts, '
  'multi-device handling, and session security.',
)
@SectionId('SM')
class SessionModel extends DocSpecsSection {
  @ContentHelp(
    'Provide an overview of the session management approach for '
    'the system.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Session configuration.
  @SectionId('SM-SESS')
  @Form([
    Field(
      'sessionType',
      String,
      'Session Type',
      hint: 'Server-side, Client-side (JWT), Hybrid',
    ),
    Field(
      'sessionStorage',
      String,
      'Session Storage',
      hint: 'Cookie, LocalStorage, Secure Storage',
    ),
    Field(
      'sessionTimeout',
      String,
      'Session Timeout',
      hint: 'Idle timeout duration',
    ),
    Field(
      'absoluteTimeout',
      String,
      'Absolute Timeout',
      hint: 'Maximum session duration',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? sessionConfiguration;

  /// Refresh, concurrency, and termination behavior.
  @SectionId('SEMOLI')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — session management',
      'OWASP ASVS — session management',
    ],
    'The session lifecycle: token refresh, multi-device policy, concurrency '
    'limits, and termination behavior.',
  )
  @Form([
    Field(
      'refreshMechanism',
      String,
      'Token Refresh Mechanism',
      hint: 'Sliding window, Explicit refresh, Re-authentication',
    ),
    Field(
      'multiDevicePolicy',
      String,
      'Multi-Device Policy',
      hint: 'Single device, Multiple devices, Device limit',
    ),
    Field(
      'concurrentSessionLimit',
      int,
      'Concurrent Session Limit',
      hint: 'Maximum simultaneous sessions',
    ),
    Field(
      'sessionTermination',
      String,
      'Session Termination',
      hint: 'Manual logout, Timeout, Force logout',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? lifecycle;

  /// Convenience features and security-trigger handling.
  @SectionId('SEMOSE')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — session management',
      'OWASP ASVS — session management',
    ],
    'The session security and convenience features: remember-me, device trust, '
    'recovery, and security-event handling.',
  )
  @Form([
    Field(
      'rememberMeOption',
      String,
      'Remember Me Option',
      hint: 'Available, Not available, Configurable',
    ),
    Field(
      'deviceTrust',
      String,
      'Device Trust',
      hint: 'Trusted devices concept support',
    ),
    Field(
      'sessionRecovery',
      String,
      'Session Recovery',
      hint: 'How interrupted sessions are handled',
    ),
    Field(
      'securityEvents',
      String,
      'Security Events',
      hint: 'Events that trigger session review/termination',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? security;
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
@ContentHelp(
  'Define notification strategy: channels, triggers, preferences, '
  'and delivery mechanisms.',
)
@SectionId('NM')
@CodeSpecKind(
  [CodeSpecPart.notification],
  note:
      'CE-NT — outbound communications (email/push/SMS/webhooks) as a '
      'first-class effect. Active part (codespecs_mapping.md §4.1): the '
      'type/channel/preference '
      'declarations are realised as @CsNotification and '
      '@CsNotificationChannel over the tom_core_codespecs notification model '
      '(shared locus); delivery rides the tom_core_server messaging transport '
      '(server locus).',
)
class NotificationModel extends DocSpecsSection {
  @ContentType('description', 'Overview of notification strategy.')
  @override
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
  @StandardReferences([
    'ISO 9241-210 — user feedback & notifications',
    'ISO/IEC 25010 — user-interface aesthetics/operability',
  ], 'The set of individual notification-type entries defined for the system.')
  @SectionId('NTFTY-NOTI-LST')
  @SectionIdPattern('NTFTY-NOTI-xxx')
  @ContentHelp('Define each notification type.')
  @SerializationOrder(2)
  List<NotificationTypeEntry> notificationTypes = [];

  /// User notification preferences.
  @StandardReferences([
    'ISO 9241-210 — user feedback & notifications',
    'ISO/IEC 25010 — user-interface aesthetics/operability',
  ], 'The set of user notification-preference entries defined for the system.')
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
class NotificationChannelEntry extends DocSpecsSection {
  @Form([
    Field(
      'channelName',
      String,
      'Channel Name',
      required: true,
      hint: 'Email, SMS, Push Notification, In-App, Slack, Teams',
    ),
    Field(
      'channelId',
      String,
      'Channel ID',
      hint: 'Unique identifier for the notification channel',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Purpose and scope of this notification channel',
    ),
    Field(
      'deliveryMethod',
      String,
      'Delivery Method',
      hint: 'Immediate, Batched, Digest',
    ),
    Field(
      'retryPolicy',
      String,
      'Retry Policy',
      hint: 'Retry attempts and intervals',
    ),
    Field(
      'fallbackChannel',
      String,
      'Fallback Channel',
      hint: 'Alternative channel if delivery fails',
    ),
    Field(
      'quietHoursSupport',
      String,
      'Quiet Hours Support',
      hint: 'Respects user quiet hours settings',
    ),
    Field(
      'urgencyLevels',
      String,
      'Supported Urgency Levels',
      hint: 'Which urgency levels use this channel',
    ),
  ])
  @override
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
class NotificationTypeEntry extends DocSpecsSection {
  @Form([
    Field(
      'notificationType',
      String,
      'Notification Type',
      required: true,
      hint: 'e.g., Order Confirmation, Password Reset, System Alert',
    ),
    Field(
      'typeId',
      String,
      'Type ID',
      hint: 'Unique identifier for the notification type',
    ),
    Field(
      'category',
      String,
      'Category',
      hint: 'Transactional, Marketing, System, Security',
    ),
    Field(
      'urgency',
      String,
      'Urgency Level',
      hint: 'Critical, High, Medium, Low',
    ),
    Field(
      'defaultChannels',
      String,
      'Default Channels',
      hint: 'Channels used by default',
    ),
    Field(
      'userConfigurable',
      String,
      'User Configurable',
      hint: 'Can user change notification preferences for this type',
    ),
    Field(
      'mandatoryChannels',
      String,
      'Mandatory Channels',
      hint: 'Channels that cannot be disabled',
    ),
    Field(
      'triggerEvent',
      String,
      'Trigger Event',
      hint: 'System event that triggers this notification',
    ),
    Field(
      'contentTemplate',
      String,
      'Content Template',
      hint: 'Template ID or description',
    ),
    Field(
      'localized',
      String,
      'Localized',
      hint: 'Available in multiple languages',
    ),
  ])
  @override
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
  Field(
    'globalOptOut',
    String,
    'Global Opt-Out Support',
    hint: 'Can users opt out of all non-essential notifications',
  ),
  Field(
    'perTypeControl',
    String,
    'Per-Type Control',
    hint: 'Can users control individual notification types',
  ),
  Field(
    'channelPreferences',
    String,
    'Channel Preferences',
    hint: 'Can users choose preferred channels',
  ),
  Field(
    'frequencyControl',
    String,
    'Frequency Control',
    hint: 'Can users control notification frequency',
  ),
  Field(
    'quietHours',
    String,
    'Quiet Hours',
    hint: 'Can users set do-not-disturb hours',
  ),
  Field(
    'digestOption',
    String,
    'Digest Option',
    hint: 'Can users opt for daily/weekly digests',
  ),
])
@SectionId('UNP')
class UserNotificationPreferences extends DocSpecsSection {
  /// Preferences content.
  @ContentType('form', 'User notification preference options.')
  @override
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
@ContentHelp(
  'Define multi-channel experience: context handoff between '
  'channels, data synchronization, and experience consistency.',
)
@SectionId('MCE')
class MultiChannelExperience extends DocSpecsSection {
  @ContentHelp(
    'Provide an overview of how a consistent experience is '
    'maintained across channels and during channel switching.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Multi-channel configuration.
  @SectionId('MCE-MULT')
  @Form([
    Field(
      'channelHandoff',
      String,
      'Channel Handoff',
      hint: 'How users switch between channels seamlessly',
    ),
    Field(
      'contextPreservation',
      String,
      'Context Preservation',
      hint: 'What context is preserved when switching channels',
    ),
    Field(
      'dataSynchronization',
      String,
      'Data Synchronization',
      hint: 'Real-time, Near-real-time, Eventual',
    ),
    Field(
      'conflictResolution',
      String,
      'Conflict Resolution',
      hint: 'How conflicts from multi-channel edits are resolved',
    ),
    Field(
      'consistentBranding',
      String,
      'Consistent Branding',
      hint: 'Brand consistency requirements across channels',
    ),
    Field(
      'featureParity',
      String,
      'Feature Parity',
      hint: 'Degree of feature consistency across channels',
    ),
    Field(
      'responsiveDesign',
      String,
      'Responsive Design',
      hint: 'Approach to responsive/adaptive design',
    ),
    Field(
      'progressiveEnhancement',
      String,
      'Progressive Enhancement',
      hint: 'How features degrade on limited channels',
    ),
    Field(
      'offlineFirst',
      String,
      'Offline-First Strategy',
      hint: 'Offline-first approach for applicable channels',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? multiChannelConfiguration;
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
@ContentHelp(
  'Define all user categories (personas) that will interact with '
  'the system. Each category represents a distinct group with shared '
  'characteristics, needs, and interaction patterns. Use this to drive '
  'user-centered design decisions.',
)
@SectionId('UC1')
class UserCategories extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of user categories and how they '
        'relate to the system. Include summary of user population and '
        'key differences between categories.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// User category overview diagram.
  @ContentType(
    'mermaid-flowchart',
    'User category hierarchy or relationship '
        'diagram showing how different user types relate',
  )
  @ContentHelp(
    'Create a diagram showing user categories, their '
    'relationships, and organizational hierarchy.',
  )
  @SerializationOrder(1)
  DocSpecsSection? userCategoryDiagram;

  /// User category entries — contains 1+× UserCategoryEntry.
  @StandardReferences([
    'ISO 9241-210 — user characteristics & context of use',
    'BABOK v3 §10.43 — stakeholder/user analysis',
  ], 'The set of individual user-category entries defined for this system.')
  @SectionId('USCA-CATE-LST')
  @SectionIdPattern('USCA-CATE-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per distinct user category. Categories should '
    'be mutually exclusive where possible, with clear distinguishing '
    'characteristics.',
  )
  @SerializationOrder(2)
  List<UserCategoryEntry> categories = [];
}

/// A user category entry.
///
/// Comprehensive user persona definition including demographics, goals,
/// frustrations, technical proficiency, and system interaction patterns.
@StandardReferences(
  ['ISO 9241-210 — personas & context of use', 'BABOK v3 §10.43 — personas'],
  'A single user-category persona, bundling its usage profile, importance, '
  'persona details, role, tasks, permissions, training, accessibility, and '
  'journey.',
)
@SectionId('UCE')
class UserCategoryEntry extends DocSpecsSection {
  @Form([
    Field(
      'categoryName',
      String,
      'Category Name',
      required: true,
      hint: 'Descriptive name of this user category',
    ),
    Field(
      'categoryId',
      String,
      'Category ID (unique identifier)',
      // Why: this is the user-category registry key — ICEP.targetUserCategories
      // resolves against it, and an optional key could not be resolved against
      // at all (tom_specs_model_rules.md §6.2 rule 4).
      required: true,
      hint: 'Unique stable identifier for cross-referencing this category',
    ),
    Field(
      'description',
      String,
      'Description (brief summary of this user type)',
      required: true,
      hint: 'One- or two-sentence summary of this user type',
    ),
    Field(
      'userType',
      String,
      'User Type (Internal, External, Partner, Customer, Administrator, etc.)',
      required: true,
      hint: 'Internal / External / Partner / Customer / Administrator',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Interaction profile and scale indicators.
  @SectionId('UCEU')
  @StandardReferences(
    [
      'ISO 9241-210 — user characteristics & context of use',
      'BABOK v3 §10.43 — stakeholder/user analysis',
    ],
    'Captures how this user category uses the system — proficiency, frequency, '
    'access channel, and population size.',
  )
  @Form([
    Field(
      'technicalProficiency',
      String,
      'Technical Proficiency (Novice, Intermediate, Advanced, Expert)',
      hint: 'Novice / Intermediate / Advanced / Expert',
    ),
    Field(
      'frequencyOfUse',
      String,
      'Frequency of Use (Continuous, Daily, Weekly, Monthly, Occasional)',
      hint: 'Continuous / Daily / Weekly / Monthly / Occasional',
    ),
    Field(
      'accessChannel',
      String,
      'Primary Access Channel (Web, Mobile, Desktop, API, etc.)',
      hint: 'Web / Mobile / Desktop / API',
    ),
    Field(
      'estimatedUserCount',
      String,
      'Estimated User Count (current number or range)',
      hint: 'Current number or expected range of users',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? usage;

  /// Growth and prioritization profile.
  @SectionId('UCEI')
  @StandardReferences(
    [
      'ISO 9241-210 — user characteristics & context of use',
      'BABOK v3 §10.43 — stakeholder/user analysis',
    ],
    'Captures the strategic weight of this user category — expected growth, '
    'criticality, and design priority.',
  )
  @Form([
    Field(
      'growthExpectation',
      String,
      'Growth Expectation (expected change in user count)',
      hint: 'Expected change in user count over time',
    ),
    Field(
      'criticality',
      String,
      'Criticality (how critical is this user group to the system)',
      hint: 'How critical this user group is to the system',
    ),
    Field(
      'priority',
      String,
      'Priority (High, Medium, Low - for design decisions)',
      hint: 'High / Medium / Low — for design decisions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? importance;

  /// 4.1.4.n.1. User Persona Details.
  @SerializationOrder(3)
  UserPersonaDetails personaDetails = UserPersonaDetails();

  /// 4.1.4.n.2. Role.
  @SectionId('UCRE')
  @StandardReferences(
    ['NIST RBAC — role-based access', 'BABOK v3 §10.43 — roles'],
    'Captures the organizational role for this user category — its '
    'responsibilities, reporting lines, and decision/budget authority.',
  )
  @Form([
    Field(
      'roleName',
      String,
      'Role Name',
      required: true,
      hint: 'Name of the organizational role',
    ),
    Field(
      'roleDescription',
      String,
      'Role Description',
      required: true,
      hint: 'Brief description of the role and its purpose',
    ),
    Field(
      'organizationUnit',
      String,
      'Organization Unit',
      hint: 'Department or unit this role belongs to',
    ),
    Field(
      'reportsTo',
      String,
      'Reports To (role or position)',
      hint: 'Role or position this role reports to',
    ),
    Field(
      'directReports',
      String,
      'Direct Reports (roles reporting to this)',
      hint: 'Roles or positions that report to this role',
    ),
    Field(
      'responsibilities',
      String,
      'Key Responsibilities (main job functions)',
      hint: 'Main job functions and duties of this role',
    ),
    Field(
      'decisionAuthority',
      String,
      'Decision Authority (what decisions can they make)',
      hint: 'What decisions this role is authorized to make',
    ),
    Field(
      'budgetAuthority',
      String,
      'Budget Authority (financial approval limits)',
      hint: 'Financial approval limits for this role',
    ),
    Field(
      'collaborators',
      String,
      'Primary Collaborators (roles they work with)',
      hint: 'Roles this role regularly works with',
    ),
    Field(
      'performanceMetrics',
      String,
      'Performance Metrics (how their success is measured)',
      hint: 'How success is measured for this role',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? role;

  /// 4.1.4.n.3. System Tasks — contains 1+× System Task.
  @StandardReferences([
    'ISO 9241-11 — tasks & goals (usability)',
    'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
  ], 'The set of system tasks this user category performs.')
  @SectionId('SYTS-SYST-LST')
  @SectionIdPattern('SYTS-SYST-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per distinct task this user category performs '
    'with the system.',
  )
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

/// 4.1.4.n.1. User Persona Details.
///
/// Detailed persona information including demographics, goals, frustrations,
/// and behavioral characteristics for user-centered design.
@StandardReferences(
  ['ISO 9241-210 — personas & context of use', 'BABOK v3 §10.43 — personas'],
  'Captures the detailed persona for this user category — demographics, '
  'context, goals, and behavior — so designers can empathize with the user.',
)
@ContentHelp(
  'Describe the persona in detail to help designers and developers '
  'understand and empathize with this user type.',
)
@SectionId('UPD')
class UserPersonaDetails extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Persona Details Form.
  @SectionId('UPD-PERS')
  @Form([
    Field(
      'representativeName',
      String,
      'Representative Name (fictional name for this persona)',
      hint: 'A memorable fictional name to humanize the persona',
    ),
    Field(
      'ageRange',
      String,
      'Age Range',
      hint: 'Typical age range for this persona',
    ),
    Field(
      'educationLevel',
      String,
      'Education Level',
      hint: 'Highest education level typical for this persona',
    ),
    Field(
      'jobTitle',
      String,
      'Job Title / Position',
      hint: 'Typical job title or position',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? personaForm;

  /// Experience and work context.
  @SectionId('UPDC')
  @StandardReferences(
    ['ISO 9241-210 — personas & context of use', 'BABOK v3 §10.43 — personas'],
    'Captures the persona\'s working context — experience, environment, and '
    'typical workday.',
  )
  @Form([
    Field(
      'yearsOfExperience',
      String,
      'Years of Experience (in this role)',
      hint: 'Years of experience in this role',
    ),
    Field(
      'workEnvironment',
      String,
      'Work Environment (office, remote, field, etc.)',
      hint: 'Office / remote / field / hybrid',
    ),
    Field(
      'typicalWorkday',
      String,
      'Typical Workday (relevant aspects of daily routine)',
      hint: 'Relevant aspects of the persona\'s daily routine',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? contextDetails;

  /// Goals and drivers.
  @SectionId('UPDG')
  @StandardReferences(
    ['ISO 9241-210 — personas & context of use', 'BABOK v3 §10.43 — personas'],
    'Captures what drives this persona — goals, frustrations, motivations, and '
    'fears.',
  )
  @Form([
    Field(
      'primaryGoals',
      String,
      'Primary Goals (what they want to achieve with the system)',
      hint: 'What this persona most wants to achieve with the system',
    ),
    Field(
      'secondaryGoals',
      String,
      'Secondary Goals',
      hint: 'Less critical goals this persona also has',
    ),
    Field(
      'frustrations',
      String,
      'Frustrations (pain points with current solutions)',
      hint: 'Pain points with current solutions or workflows',
    ),
    Field(
      'motivations',
      String,
      'Motivations (what drives them)',
      hint: 'What drives and motivates this persona',
    ),
    Field(
      'fears',
      String,
      'Fears (concerns about new systems)',
      hint: 'Concerns or anxieties about adopting a new system',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? goals;

  /// Preferences and behavior.
  @SectionId('UPDB')
  @StandardReferences(
    ['ISO 9241-210 — personas & context of use', 'BABOK v3 §10.43 — personas'],
    'Captures this persona\'s behavioral traits — technology comfort, learning '
    'style, and decision-making style.',
  )
  @Form([
    Field(
      'techComfort',
      String,
      'Technology Comfort Level (attitude toward technology)',
      hint: 'This persona\'s general attitude toward technology',
    ),
    Field(
      'preferredLearningStyle',
      String,
      'Preferred Learning Style (visual, hands-on, documentation, etc.)',
      hint: 'Visual / hands-on / documentation / video',
    ),
    Field(
      'decisionMakingStyle',
      String,
      'Decision Making Style (analytical, intuitive, collaborative)',
      hint: 'Analytical / intuitive / collaborative',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? behavior;

  /// Representative photo or avatar description.
  @SectionId('UPD-VISU')
  @ContentType(
    'description',
    'Description of a representative photo or '
        'avatar that embodies this persona (for design reference).',
  )
  @SerializationOrder(5)
  DocSpecsSection? visualRepresentation;

  /// Key quotes that represent this persona's mindset.
  @StandardReferences([
    'ISO 9241-210 — personas & context of use',
    'BABOK v3 §10.43 — personas',
  ], 'The set of representative quotes capturing this persona\'s mindset.')
  @SectionId('REPRE-REPR-LST')
  @SectionIdPattern('REPRE-REPR-xxx')
  @ContentHelp(
    'Add quotes that capture how this persona thinks and speaks, '
    'to make the persona vivid for designers.',
  )
  @SerializationOrder(6)
  List<DocSpecsSection> representativeQuotes = [];
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
class SystemTaskEntry extends DocSpecsSection {
  @Form([
    Field(
      'taskId',
      String,
      'Task ID',
      required: true,
      hint: 'Unique identifier for this task',
    ),
    Field(
      'taskName',
      String,
      'Task Name',
      required: true,
      hint: 'Short descriptive name of the task',
    ),
    Field(
      'description',
      String,
      'Description (what the user does)',
      hint: 'What the user does when performing this task',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Timing, complexity, and trigger details.
  @SectionId('STEE')
  @StandardReferences(
    [
      'ISO 9241-11 — tasks & goals (usability)',
      'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
    ],
    'Captures the execution profile of a task — frequency, duration, complexity, '
    'importance, and trigger.',
  )
  @Form([
    Field(
      'frequency',
      String,
      'Frequency (how often: Continuous, Daily, Weekly, Monthly, Ad-hoc)',
      hint: 'Continuous / Daily / Weekly / Monthly / Ad-hoc',
    ),
    Field(
      'averageDuration',
      String,
      'Average Duration (typical time to complete)',
      hint: 'Typical time to complete this task',
    ),
    Field(
      'complexity',
      String,
      'Complexity (Simple, Moderate, Complex)',
      hint: 'Simple / Moderate / Complex',
    ),
    Field(
      'importance',
      String,
      'Importance (Critical, High, Medium, Low)',
      hint: 'Critical / High / Medium / Low',
    ),
    Field(
      'trigger',
      String,
      'Trigger (what initiates this task)',
      hint: 'Event or condition that initiates this task',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? execution;

  /// Outcome and data interaction details.
  @SectionId('STED')
  @StandardReferences(
    [
      'ISO 9241-11 — tasks & goals (usability)',
      'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
    ],
    'Captures the data interaction of a task — expected outcome, success '
    'criteria, and data accessed or modified.',
  )
  @Form([
    Field(
      'expectedOutcome',
      String,
      'Expected Outcome',
      hint: 'The result the user expects from completing the task',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'How to tell the task completed successfully',
    ),
    Field(
      'dataAccessed',
      String,
      'Data Accessed (what information is needed)',
      hint: 'What information the task needs to read',
    ),
    Field(
      'dataModified',
      String,
      'Data Modified (what information changes)',
      hint: 'What information the task creates or changes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? data;

  /// Tooling and linked artifacts.
  @SectionId('STEC')
  @StandardReferences(
    [
      'ISO 9241-11 — tasks & goals (usability)',
      'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
    ],
    'Captures the tooling context of a task — the systems and tools involved in '
    'performing it.',
  )
  @Form([
    Field(
      'toolsUsed',
      String,
      'Tools Used (systems or tools involved)',
      hint: 'Systems or tools involved in performing this task',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? context;

  @SectionId('SYTS-RELA-REF')
  @Reference('Related Use Case')
  @SerializationOrder(4)
  DocSpecsSection? relatedUseCase;

  /// Task workflow steps.
  @StandardReferences([
    'ISO 9241-11 — tasks & goals (usability)',
    'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
  ], 'The ordered set of workflow steps that make up this task.')
  @SectionId('SYSTE-WORK-LST')
  @SectionIdPattern('SYSTE-WORK-xxx')
  @ContentHelp(
    'Add one entry per step in the task workflow, in the order the '
    'user performs them.',
  )
  @SerializationOrder(5)
  List<DocSpecsSection> workflowSteps = [];

  /// Variations and exceptions.
  @StandardReferences([
    'ISO 9241-11 — tasks & goals (usability)',
    'ISO/IEC/IEEE 29148 §6 — user tasks/use cases',
  ], 'The set of alternative flows and exceptions for this task.')
  @SectionId('VARIA-VARI-LST')
  @SectionIdPattern('VARIA-VARI-xxx')
  @ContentHelp(
    'Add one entry per variation or exception to the normal task '
    'flow.',
  )
  @SerializationOrder(6)
  List<DocSpecsSection> variationsAndExceptions = [];
}

/// 4.1.4.n.4. Access and Permissions.
///
/// Security and access control specifications for this user category.
@StandardReferences(
  ['ISO/IEC 27001 Annex A.9 — access control', 'NIST RBAC — permissions'],
  'Captures the access rights, authentication, restrictions, governance, and '
  'permission matrix for this user category.',
)
@ContentHelp(
  'Define the access rights, permissions, and security '
  'constraints for this user category.',
)
@SectionId('UAP')
class UserAccessPermissions extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Access Permissions Form.
  @SectionId('UAP-PERM')
  @Form([
    Field(
      'accessLevel',
      String,
      'Access Level (Guest, User, Power User, Administrator, Super Admin)',
      required: true,
      hint: 'Guest / User / Power User / Administrator / Super Admin',
    ),
    Field(
      'authenticationMethod',
      String,
      'Authentication Method (Password, SSO, MFA, Certificate, etc.)',
      required: true,
      hint: 'Password / SSO / MFA / Certificate',
    ),
    Field(
      'authorizationRoles',
      String,
      'Authorization Roles (system roles assigned to this category)',
      hint: 'System roles assigned to this user category',
    ),
    Field(
      'dataAccessScope',
      String,
      'Data Access Scope (all, department, team, own records)',
      hint: 'all / department / team / own records',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? permissionsForm;

  /// Functional and environmental restrictions.
  @SectionId('UAPR')
  @StandardReferences(
    ['ISO/IEC 27001 Annex A.9 — access control', 'NIST RBAC — permissions'],
    'Captures the functional and environmental restrictions on this user '
    'category — what they cannot do, and time/location/device constraints.',
  )
  @Form([
    Field(
      'functionalAccess',
      String,
      'Functional Access (what features they can use)',
      hint: 'Features and functions this category can use',
    ),
    Field(
      'restrictions',
      String,
      'Restrictions (what they cannot access or do)',
      hint: 'What this category cannot access or do',
    ),
    Field(
      'timeRestrictions',
      String,
      'Time Restrictions (business hours, specific times)',
      hint: 'Business hours or specific times access is allowed',
    ),
    Field(
      'locationRestrictions',
      String,
      'Location Restrictions (office only, VPN required, etc.)',
      hint: 'Office only / VPN required / geographic limits',
    ),
    Field(
      'deviceRestrictions',
      String,
      'Device Restrictions (managed devices only, etc.)',
      hint: 'Managed devices only / device type limits',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? restrictionsProfile;

  /// Session and audit controls.
  @SectionId('UAPG')
  @StandardReferences(
    ['ISO/IEC 27001 Annex A.9 — access control', 'NIST RBAC — permissions'],
    'Captures the session and audit governance for this user category — '
    'timeout behaviour and audit-logging requirements.',
  )
  @Form([
    Field(
      'sessionTimeout',
      String,
      'Session Timeout (inactivity timeout duration)',
      hint: 'Inactivity timeout duration before re-authentication',
    ),
    Field(
      'auditRequirements',
      String,
      'Audit Requirements (what actions are logged)',
      hint: 'Which actions must be logged for audit',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// Permission matrix entries — contains 0+× PermissionMatrixEntry.
  @StandardReferences([
    'ISO/IEC 27001 Annex A.9 — access control',
    'NIST RBAC — permissions',
  ], 'The set of fine-grained permission entries for this user category.')
  @SectionId('PRMTX-PERM-LST')
  @SectionIdPattern('PRMTX-PERM-xxx')
  @ContentHelp('Define specific permission entries for fine-grained access.')
  @SerializationOrder(4)
  List<PermissionMatrixEntry> permissionMatrix = [];
}

/// A permission matrix entry (form).
@StandardReferences(
  ['ISO/IEC 27001 Annex A.9 — access control', 'NIST RBAC — permissions'],
  'A single fine-grained permission rule — a resource, an action, and whether '
  'it is allowed, denied, or conditional, with scope.',
)
@SectionId('PRMTX')
class PermissionMatrixEntry extends DocSpecsSection {
  @Form([
    Field(
      'resource',
      String,
      'Resource (what is being accessed)',
      required: true,
      hint: 'The resource or entity being accessed',
    ),
    Field(
      'action',
      String,
      'Action (Create, Read, Update, Delete, Execute)',
      required: true,
      hint: 'Create / Read / Update / Delete / Execute',
    ),
    Field(
      'permission',
      String,
      'Permission (Allowed, Denied, Conditional)',
      hint: 'Allowed / Denied / Conditional',
    ),
    Field(
      'condition',
      String,
      'Condition (if conditional, what is required)',
      hint: 'If conditional, the condition that must hold',
    ),
    Field(
      'scope',
      String,
      'Scope (all, own, department, etc.)',
      hint: 'all / own / department / team',
    ),
  ])
  @override
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
class UserTrainingRequirements extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Training Requirements Form.
  @SectionId('USTRRE-TRAI')
  @Form([
    Field(
      'initialTrainingRequired',
      bool,
      'Initial Training Required (is formal training needed)',
      hint: 'Whether formal up-front training is needed',
    ),
    Field(
      'trainingFormat',
      String,
      'Training Format (In-person, Online, Self-paced, On-the-job)',
      hint: 'In-person / Online / Self-paced / On-the-job',
    ),
    Field(
      'estimatedTrainingDuration',
      String,
      'Estimated Training Duration',
      hint: 'Estimated time required to complete training',
    ),
    Field(
      'certificationRequired',
      bool,
      'Certification Required (must pass assessment)',
      hint: 'Whether users must pass an assessment to be certified',
    ),
    Field(
      'refresherFrequency',
      String,
      'Refresher Frequency (how often retraining is needed)',
      hint: 'How often retraining or refresher courses are needed',
    ),
    Field(
      'supportLevel',
      String,
      'Support Level Expected (Self-service, Help desk, Dedicated)',
      hint: 'Self-service / Help desk / Dedicated',
    ),
    Field(
      'documentationNeeds',
      String,
      'Documentation Needs (User guide, Quick reference, Video tutorials)',
      hint: 'User guide / Quick reference / Video tutorials',
    ),
    Field(
      'onboardingProcess',
      String,
      'Onboarding Process (steps to get started)',
      hint: 'Steps needed to get a new user started',
    ),
    Field(
      'mentoringRequired',
      bool,
      'Mentoring Required (paired with experienced user)',
      hint: 'Whether new users are paired with an experienced mentor',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? trainingForm;

  /// Training topics — contains 0+× TrainingTopicEntry.
  @StandardReferences([
    'ISO/IEC/IEEE 12207 — training/support processes',
    'ISO 9241-210 — user support',
  ], 'The set of specific training topics for this user category.')
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
class TrainingTopicEntry extends DocSpecsSection {
  @Form([
    Field(
      'topicName',
      String,
      'Topic Name',
      required: true,
      hint: 'Name of the training topic',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Brief description of what this topic covers',
    ),
    Field(
      'learningObjectives',
      String,
      'Learning Objectives',
      hint: 'What learners should be able to do after this topic',
    ),
    Field(
      'duration',
      String,
      'Duration',
      hint: 'Estimated time to cover this topic',
    ),
    Field(
      'prerequisites',
      String,
      'Prerequisites',
      hint: 'Knowledge or topics required before this one',
    ),
    Field(
      'assessmentMethod',
      String,
      'Assessment Method',
      hint: 'How learning of this topic is assessed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 4.1.4.n.6. Accessibility Needs.
///
/// Accessibility requirements and accommodations for this user category.
@StandardReferences(
  ['WCAG 2.1 — web content accessibility', 'EN 301 549 — ICT accessibility'],
  'Captures the accessibility requirements and accommodations for this user '
  'category — visual, auditory, motor, cognitive, and language needs.',
)
@ContentHelp(
  'Document any accessibility requirements or accommodations '
  'that should be considered for this user category.',
)
@SectionId('UAN')
class UserAccessibilityNeeds extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Accessibility Needs Form.
  @SectionId('UAN-ACCE')
  @Form([
    Field(
      'visualRequirements',
      String,
      'Visual Requirements (screen reader, high contrast, magnification)',
      hint: 'Screen reader / high contrast / magnification needs',
    ),
    Field(
      'auditoryRequirements',
      String,
      'Auditory Requirements (captions, visual alerts)',
      hint: 'Captions / visual alerts for auditory content',
    ),
    Field(
      'motorRequirements',
      String,
      'Motor Requirements (keyboard navigation, voice control)',
      hint: 'Keyboard navigation / voice control needs',
    ),
    Field(
      'cognitiveRequirements',
      String,
      'Cognitive Requirements (simple language, clear navigation)',
      hint: 'Simple language / clear navigation needs',
    ),
    Field(
      'languageRequirements',
      String,
      'Language Requirements (multiple languages, reading level)',
      hint: 'Multiple languages / reading level needs',
    ),
    Field(
      'deviceAccommodations',
      String,
      'Device Accommodations (large buttons, touch targets)',
      hint: 'Large buttons / touch target sizing needs',
    ),
    Field(
      'wcagLevel',
      String,
      'WCAG Conformance Level Required (A, AA, AAA)',
      hint: 'A / AA / AAA',
    ),
    Field(
      'additionalStandards',
      String,
      'Additional Standards (Section 508, EN 301 549, etc.)',
      hint: 'Section 508 / EN 301 549 / other accessibility standards',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? accessibilityForm;
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
@ContentHelp(
  'Document the user journey - key touchpoints and stages '
  'in this user category\'s interaction with the system.',
)
@SectionId('UJ')
class UserJourney extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// User journey diagram.
  @SectionId('UJ-JOUR')
  @ContentType(
    'mermaid-flowchart',
    'User journey map showing stages, '
        'touchpoints, and emotional peaks/valleys',
  )
  @ContentHelp(
    'Create a journey map showing the user\'s experience '
    'from first contact through regular use.',
  )
  @SerializationOrder(1)
  DocSpecsSection? journeyDiagram;

  /// Journey stage entries — contains 0+× JourneyStageEntry.
  @StandardReferences([
    'ISO 9241-210 — user journey & experience',
    'BABOK v3 §10 — customer journey mapping',
  ], 'The ordered set of stages that make up this user journey.')
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
  List<DocSpecsSection> keyTouchpoints = [];

  /// Pain points in the journey.
  @StandardReferences([
    'ISO 9241-210 — user journey & experience',
    'BABOK v3 §10 — customer journey mapping',
  ], 'The set of pain points this user category encounters during the journey.')
  @SectionId('USERJ-PAIN-LST')
  @SectionIdPattern('USERJ-PAIN-xxx')
  @ContentHelp('Add one entry per pain point or friction in the user journey.')
  @SerializationOrder(4)
  List<DocSpecsSection> painPoints = [];

  /// Opportunities for delight.
  @SectionId('UJ-OPPO')
  @ContentType(
    'description',
    'Opportunities to exceed user expectations '
        'and create positive experiences.',
  )
  @SerializationOrder(5)
  DocSpecsSection? opportunitiesForDelight;
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
class JourneyStageEntry extends DocSpecsSection {
  @Form([
    Field(
      'stageName',
      String,
      'Stage Name',
      required: true,
      hint: 'Name of this journey stage',
    ),
    Field(
      'stageDescription',
      String,
      'Stage Description',
      hint: 'Brief description of what happens in this stage',
    ),
    Field(
      'userGoal',
      String,
      'User Goal (what they want to achieve)',
      hint: 'What the user wants to achieve in this stage',
    ),
    Field(
      'userActions',
      String,
      'User Actions (what they do)',
      hint: 'What the user does during this stage',
    ),
    Field(
      'systemResponse',
      String,
      'System Response (what system does)',
      hint: 'How the system responds during this stage',
    ),
    Field(
      'userEmotions',
      String,
      'User Emotions (expected feeling)',
      hint: 'The emotion the user is expected to feel here',
    ),
    Field(
      'touchpoints',
      String,
      'Touchpoints (system interactions)',
      hint: 'System interactions or touchpoints in this stage',
    ),
    Field(
      'potentialIssues',
      String,
      'Potential Issues',
      hint: 'Problems or friction the user may hit in this stage',
    ),
    Field(
      'successMetrics',
      String,
      'Success Metrics',
      hint: 'How success is measured for this stage',
    ),
  ])
  @override
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
@ContentHelp(
  'Define clear, measurable goals that the project must achieve. '
  'Organize goals by category (business, technical) and ensure each goal '
  'has specific success metrics and target dates.',
)
// YRD4: class-level `@Headline` — used when a referencing field carries no
// field-level `@Headline` (here the `goals` field does, so the field's
// 'Project Goals' wins; this one documents the precedence).
@Headline('Goals & Objectives')
@SectionId('GOALS')
class Goals extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Goal hierarchy diagram.
  @SectionId('GOALS-GOAL')
  @ContentType(
    'mermaid-flowchart',
    'Goal hierarchy and dependency diagram '
        'showing relationships between business and technical goals',
  )
  @ContentHelp(
    'Create a diagram showing goal categories, dependencies, '
    'and alignment to strategic objectives.',
  )
  @SerializationOrder(1)
  DocSpecsSection? goalHierarchyDiagram;

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
@ContentHelp(
  'Define business goals that are specific, measurable, achievable, '
  'relevant, and time-bound (SMART). Each goal should have clear ownership '
  'and success metrics.',
)
// YRD4: class-level `@Headline` with no competing field-level one — the
// referencing `businessGoals` field renders this default title.
@Headline('Business Goals & Value')
@SectionId('BG')
class BusinessGoals extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of business goals and their '
        'relationship to organizational strategy. Explain how these goals '
        'support the business case and value proposition.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Business goals list — contains 1+× Business Goal.
  @StandardReferences([
    'BABOK v3 §6.1 — business goals & objectives',
    'ISO/IEC/IEEE 29148 §6 — business need',
  ], 'The set of individual business goal entries defined for this project.')
  @SectionId('BGE-GOAL-LST')
  @SectionIdPattern('BGE-GOAL-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per business goal. Goals should be mutually '
    'exclusive and collectively exhaustive for the project scope.',
  )
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
class BusinessGoalEntry extends DocSpecsSection {
  @Form([
    Field(
      'goalId',
      String,
      'Goal ID (unique identifier, e.g., BG-001)',
      required: true,
      hint: 'Unique goal identifier, e.g., BG-001',
    ),
    Field(
      'goalName',
      String,
      'Goal Name (concise objective statement)',
      required: true,
      hint: 'Concise one-line objective statement',
    ),
    Field(
      'goalCategory',
      String,
      'Goal Category (Strategic, Tactical, Operational)',
      required: true,
      hint: 'Strategic, Tactical, or Operational',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Goal definition and priority.
  @SectionId('BGED')
  @StandardReferences(
    [
      'BABOK v3 §6.1 — business goals & objectives',
      'ISO/IEC/IEEE 29148 §6 — business need',
    ],
    'Captures the detailed meaning, type, and priority of a single business '
    'goal.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description (detailed explanation of what this goal means)',
      hint: 'Detailed explanation of what this goal means',
    ),
    Field(
      'goalType',
      String,
      'Goal Type (Revenue, Cost Reduction, Efficiency, Quality, Compliance, '
          'Growth, Customer Satisfaction, Market Position, Innovation)',
      hint: 'e.g., Revenue, Cost Reduction, Quality, Compliance, Growth',
    ),
    Field(
      'priority',
      String,
      'Priority (Critical, High, Medium, Low)',
      required: true,
      hint: 'Critical, High, Medium, or Low',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Success metric and measurement.
  @SectionId('BGEM')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — measures of effectiveness',
      'SMART objectives — measurable goals',
    ],
    'Captures the measurable success metric, baseline, target, and measurement '
    'method for a business goal.',
  )
  @Form([
    Field(
      'successMetric',
      String,
      'Primary Success Metric (what is measured)',
      required: true,
      hint: 'The primary quantity measured to gauge success',
    ),
    Field(
      'currentValue',
      String,
      'Current Value (baseline measurement before project)',
      hint: 'Baseline measurement before the project starts',
    ),
    Field(
      'targetValue',
      String,
      'Target Value (desired end state)',
      required: true,
      hint: 'Desired end-state value for the metric',
    ),
    Field(
      'measurementMethod',
      String,
      'Measurement Method (how the metric is captured)',
      hint: 'How the metric is captured or calculated',
    ),
    Field(
      'measurementFrequency',
      String,
      'Measurement Frequency (Daily, Weekly, Monthly, Quarterly)',
      hint: 'Daily, Weekly, Monthly, or Quarterly',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? measurement;

  /// Ownership and timeline.
  @SectionId('BGEG')
  @StandardReferences(
    ['ISO 21500 — governance', 'BABOK v3 §6 — monitoring'],
    'Captures ownership, timeline, contributing stakeholders, and current '
    'status for a business goal.',
  )
  @Form([
    Field(
      'targetDate',
      String,
      'Target Date (when goal should be achieved)',
      required: true,
      hint: 'Date by which the goal should be achieved',
    ),
    Field(
      'owner',
      String,
      'Goal Owner (accountable person or role)',
      required: true,
      hint: 'Accountable person or role for this goal',
    ),
    Field(
      'stakeholders',
      String,
      'Contributing Stakeholders (roles involved in achieving this goal)',
      hint: 'Roles involved in achieving this goal',
    ),
    Field(
      'status',
      String,
      'Status (Not Started, In Progress, On Track, At Risk, Achieved)',
      hint: 'Not Started, In Progress, On Track, At Risk, or Achieved',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// Business rationale and impact.
  @SectionId('BGES')
  @StandardReferences(
    [
      'BABOK v3 §6.1 — business goals & objectives',
      'ISO/IEC/IEEE 29148 §6 — business need',
    ],
    'Captures the business rationale, strategic alignment, impact areas, and '
    'estimated value justifying a business goal.',
  )
  @Form([
    Field(
      'businessJustification',
      String,
      'Business Justification (why this goal matters)',
      hint: 'Why this goal matters to the business',
    ),
    Field(
      'strategicAlignment',
      String,
      'Strategic Alignment (link to corporate strategy or OKR)',
      hint: 'Link to corporate strategy or OKR',
    ),
    Field(
      'impactAreas',
      String,
      'Impact Areas (departments, processes, or systems affected)',
      hint: 'Departments, processes, or systems affected',
    ),
    Field(
      'estimatedValue',
      String,
      'Estimated Value (monetary or quantitative benefit)',
      hint: 'Monetary or quantitative benefit expected',
    ),
    Field(
      'riskOfNotAchieving',
      String,
      'Risk of Not Achieving (consequences of failure)',
      hint: 'Consequences if the goal is not achieved',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? strategy;

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

/// 4.2.1.n.1. Key Results.
///
/// OKR-style key results that indicate progress toward the goal.
/// Key results are specific, measurable outcomes that together constitute
/// achievement of the parent goal.
@StandardReferences(
  ['OKR — objectives & key results', 'BABOK v3 §6 — objectives'],
  'Captures the OKR-style key results that together indicate achievement of '
  'the parent business goal.',
)
@ContentHelp(
  'Define 3-5 key results that together indicate goal achievement. '
  'Each key result should be independently measurable.',
)
@SectionId('GKR')
class GoalKeyResults extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of key results and how they '
        'collectively demonstrate goal achievement.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Key result entries — contains 0+× KeyResultEntry.
  @StandardReferences([
    'OKR — objectives & key results',
    'BABOK v3 §6 — objectives',
  ], 'The set of individual key-result entries for a business goal.')
  @SectionId('KRE-ITEM-LST')
  @SectionIdPattern('KRE-ITEM-xxx')
  @ContentHelp(
    'Add 3-5 key results per goal. Each should be specific '
    'and measurable.',
  )
  @SerializationOrder(1)
  List<KeyResultEntry> items = [];
}

/// A key result entry (form).
@StandardReferences(
  ['OKR — objectives & key results', 'BABOK v3 §6 — objectives'],
  'Captures a single measurable key result with its metric, baseline, target, '
  'progress, and status.',
)
@SectionId('KRE')
class KeyResultEntry extends DocSpecsSection {
  @Form([
    Field(
      'keyResultId',
      String,
      'Key Result ID',
      required: true,
      hint: 'Unique identifier for this key result',
    ),
    Field(
      'keyResult',
      String,
      'Key Result (measurable outcome)',
      required: true,
      hint: 'The measurable outcome that signals progress',
    ),
    Field(
      'metric',
      String,
      'Metric (what is measured)',
      hint: 'What quantity is measured',
    ),
    Field(
      'baselineValue',
      String,
      'Baseline Value (starting point)',
      hint: 'Starting value before work begins',
    ),
    Field(
      'targetValue',
      String,
      'Target Value (desired endpoint)',
      required: true,
      hint: 'Desired endpoint value',
    ),
    Field(
      'currentValue',
      String,
      'Current Value (latest measurement)',
      hint: 'Latest measured value',
    ),
    Field(
      'progress',
      String,
      'Progress (percentage toward target)',
      hint: 'Percentage of progress toward the target',
    ),
    Field(
      'owner',
      String,
      'Owner (responsible person)',
      hint: 'Person responsible for this key result',
    ),
    Field('dueDate', String, 'Due Date', hint: 'Date the key result is due'),
    Field(
      'status',
      String,
      'Status (Not Started, In Progress, Achieved, Missed)',
      hint: 'Not Started, In Progress, Achieved, or Missed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 4.2.1.n.2. Milestones.
///
/// Key milestones marking progress toward the goal.
@StandardReferences(
  ['ISO 21500 — project milestones', 'PMBOK — schedule milestones'],
  'Captures the key milestones that mark significant progress points toward '
  'achieving a business goal.',
)
@SectionId('GOMI')
@ContentHelp('Define milestones that mark significant progress points.')
class GoalMilestones extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of milestone approach and how '
        'milestones relate to goal progress.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Milestone entries — contains 0+× GoalMilestoneEntry.
  @StandardReferences([
    'ISO 21500 — project milestones',
    'PMBOK — schedule milestones',
  ], 'The set of individual milestone entries marking progress toward a goal.')
  @SectionId('GOLMS-ITEM-LST')
  @SectionIdPattern('GOLMS-ITEM-xxx')
  @ContentHelp('Add one entry per milestone, ordered by target date.')
  @SerializationOrder(1)
  List<GoalMilestoneEntry> items = [];
}

/// A goal milestone entry (form).
@StandardReferences(
  ['ISO 21500 — project milestones', 'PMBOK — schedule milestones'],
  'Captures a single milestone with its target date, completion criteria, '
  'deliverables, and status.',
)
@SectionId('GOLMS')
class GoalMilestoneEntry extends DocSpecsSection {
  @Form([
    Field(
      'milestoneId',
      String,
      'Milestone ID',
      required: true,
      hint: 'Unique identifier for this milestone',
    ),
    Field(
      'milestoneName',
      String,
      'Milestone Name',
      required: true,
      hint: 'Short descriptive name for the milestone',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this milestone represents',
    ),
    Field(
      'targetDate',
      String,
      'Target Date',
      required: true,
      hint: 'Planned date for reaching the milestone',
    ),
    Field(
      'completionCriteria',
      String,
      'Completion Criteria',
      hint: 'How completion of the milestone is determined',
    ),
    Field(
      'deliverables',
      String,
      'Deliverables (outputs of this milestone)',
      hint: 'Outputs produced at this milestone',
    ),
    Field(
      'dependencies',
      String,
      'Dependencies (what must be done first)',
      hint: 'What must be completed before this milestone',
    ),
    Field(
      'status',
      String,
      'Status (Planned, In Progress, Completed, Delayed)',
      hint: 'Planned, In Progress, Completed, or Delayed',
    ),
    Field(
      'actualDate',
      String,
      'Actual Completion Date',
      hint: 'Date the milestone was actually completed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 4.2.1.n.3. Dependencies.
///
/// Dependencies that may affect goal achievement.
@StandardReferences(
  ['ISO 21500 — dependency management', 'BABOK v3 §6 — dependencies'],
  'Captures the dependencies on other goals, projects, or external factors '
  'that may affect achievement of a business goal.',
)
@SectionId('GODE')
@ContentHelp(
  'Identify dependencies on other goals, projects, or external factors.',
)
class GoalDependencies extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of dependencies and their impact '
        'on goal achievement timeline.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Dependency entries — contains 0+× GoalDependencyEntry.
  @StandardReferences([
    'ISO 21500 — dependency management',
    'BABOK v3 §6 — dependencies',
  ], 'The set of individual dependency entries affecting a business goal.')
  @SectionId('GOLDE-ITEM-LST')
  @SectionIdPattern('GOLDE-ITEM-xxx')
  @ContentHelp('Add one entry per dependency, including its type and impact.')
  @SerializationOrder(1)
  List<GoalDependencyEntry> items = [];
}

/// A goal dependency entry (form).
@StandardReferences(
  ['ISO 21500 — dependency management', 'BABOK v3 §6 — dependencies'],
  'Captures a single dependency with its type, owner, impact, and mitigation '
  'for a business goal.',
)
@SectionId('GOLDE')
class GoalDependencyEntry extends DocSpecsSection {
  @Form([
    Field(
      'dependencyId',
      String,
      'Dependency ID',
      required: true,
      hint: 'Unique identifier for this dependency',
    ),
    Field(
      'dependencyType',
      String,
      'Dependency Type (Internal Goal, External Project, Resource, '
          'Regulatory, Technical, Organizational)',
      required: true,
      hint: 'e.g., Internal Goal, External Project, Resource, Regulatory',
    ),
    Field(
      'dependencyName',
      String,
      'Dependency Name (what we depend on)',
      required: true,
      hint: 'Name of the thing this goal depends on',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Details of the dependency',
    ),
    Field(
      'owner',
      String,
      'Owner (who controls this dependency)',
      hint: 'Person or party who controls this dependency',
    ),
    Field(
      'expectedResolutionDate',
      String,
      'Expected Resolution Date',
      hint: 'When the dependency is expected to be resolved',
    ),
    Field(
      'impact',
      String,
      'Impact (how this affects our goal)',
      hint: 'How this dependency affects the goal',
    ),
    Field(
      'mitigationStrategy',
      String,
      'Mitigation Strategy (what if dependency is not resolved)',
      hint: 'Plan if the dependency is not resolved',
    ),
    Field(
      'status',
      String,
      'Status (Open, In Progress, Resolved, Blocked)',
      hint: 'Open, In Progress, Resolved, or Blocked',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @SectionId('GOLDE-RELA-REF')
  @Reference('Related Goal')
  @SerializationOrder(1)
  DocSpecsSection? relatedGoal;
}

/// 4.2.1.n.4. Risks.
///
/// Risks that may prevent or delay goal achievement.
@StandardReferences(
  ['ISO 31000:2018 — risk management', 'BABOK v3 §6 — risks'],
  'Captures the risks that may prevent or delay achievement of a business '
  'goal, together with their mitigation strategies.',
)
@SectionId('GORI')
@ContentHelp('Identify risks specific to this goal and mitigation strategies.')
class GoalRisks extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of risks affecting this goal '
        'and overall risk posture.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Risk entries — contains 0+× GoalRiskEntry.
  @StandardReferences([
    'ISO 31000:2018 — risk management',
    'BABOK v3 §6 — risks',
  ], 'The set of individual risk entries affecting a business goal.')
  @SectionId('GOLRS-ITEM-LST')
  @SectionIdPattern('GOLRS-ITEM-xxx')
  @ContentHelp('Add one entry per risk, with assessment and response details.')
  @SerializationOrder(1)
  List<GoalRiskEntry> items = [];
}

/// A goal risk entry (form).
@StandardReferences(
  ['ISO 31000:2018 — risk management', 'BABOK v3 §6 — risks'],
  'Captures a single risk to a business goal, including its category, '
  'assessment, and response.',
)
@SectionId('GOLRS')
class GoalRiskEntry extends DocSpecsSection {
  @Form([
    Field(
      'riskId',
      String,
      'Risk ID',
      required: true,
      hint: 'Unique identifier for this risk',
    ),
    Field(
      'riskName',
      String,
      'Risk Name',
      required: true,
      hint: 'Short descriptive name for the risk',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What the risk is and how it could materialize',
    ),
    Field(
      'riskCategory',
      String,
      'Risk Category (Market, Operational, Technical, Resource, '
          'Regulatory, External)',
      hint: 'e.g., Market, Operational, Technical, Resource, Regulatory',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Risk assessment details.
  @SectionId('GREA')
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'BABOK v3 §6 — risks'],
    'Captures the probability, impact, score, and trigger conditions assessed '
    'for a goal risk.',
  )
  @Form([
    Field(
      'probability',
      String,
      'Probability (Low, Medium, High)',
      hint: 'Low, Medium, or High',
    ),
    Field(
      'impact',
      String,
      'Impact (Low, Medium, High, Critical)',
      hint: 'Low, Medium, High, or Critical',
    ),
    Field(
      'riskScore',
      String,
      'Risk Score (probability × impact)',
      hint: 'Computed as probability multiplied by impact',
    ),
    Field(
      'triggerConditions',
      String,
      'Trigger Conditions (early warning signs)',
      hint: 'Early warning signs the risk is materializing',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? assessment;

  /// Mitigation ownership and status.
  @SectionId('GRER')
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'BABOK v3 §6 — risks'],
    'Captures the mitigation strategy, contingency plan, owner, and status of '
    'the response to a goal risk.',
  )
  @Form([
    Field(
      'mitigationStrategy',
      String,
      'Mitigation Strategy',
      hint: 'Actions taken to reduce the risk',
    ),
    Field(
      'contingencyPlan',
      String,
      'Contingency Plan (if risk occurs)',
      hint: 'What to do if the risk materializes',
    ),
    Field(
      'owner',
      String,
      'Risk Owner',
      hint: 'Person accountable for managing the risk',
    ),
    Field(
      'status',
      String,
      'Status (Identified, Mitigating, Occurred, Closed)',
      hint: 'Identified, Mitigating, Occurred, or Closed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? response;
}

/// 4.2.1.n.5. Resources.
///
/// Resources required to achieve the goal.
@StandardReferences(
  ['PMBOK — resource management', 'ISO 21500 — resources'],
  'Captures the people, budget, and tools required to achieve a business '
  'goal, including detailed resource allocations.',
)
@SectionId('GORE')
@ContentHelp('Define resources (people, budget, tools) needed for this goal.')
class GoalResources extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Resource requirement form.
  @SectionId('GORE-RESO')
  @Form([
    Field(
      'totalBudget',
      String,
      'Total Budget (estimated or allocated)',
      hint: 'Estimated or allocated total budget',
    ),
    Field(
      'fteRequired',
      String,
      'FTE Required (full-time equivalent staff)',
      hint: 'Number of full-time-equivalent staff needed',
    ),
    Field(
      'keySkills',
      String,
      'Key Skills Required',
      hint: 'Critical skills needed to achieve the goal',
    ),
    Field(
      'toolsRequired',
      String,
      'Tools or Systems Required',
      hint: 'Tools or systems needed',
    ),
    Field(
      'externalSupport',
      String,
      'External Support (consultants, vendors)',
      hint: 'Consultants or vendors required',
    ),
    Field(
      'trainingNeeds',
      String,
      'Training Needs',
      hint: 'Training the team needs to acquire',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? resourcesForm;

  /// Resource allocation entries — contains 0+× ResourceAllocationEntry.
  @StandardReferences([
    'PMBOK — resource management',
    'ISO 21500 — resources',
  ], 'The set of individual resource allocation entries for a business goal.')
  @SectionId('REARS-ITEM-LST')
  @SectionIdPattern('REARS-ITEM-xxx')
  @ContentHelp(
    'Add one entry per allocated resource (personnel, budget, tool).',
  )
  @SerializationOrder(2)
  List<ResourceAllocationEntry> items = [];
}

/// A resource allocation entry (form).
@StandardReferences(
  ['PMBOK — resource management', 'ISO 21500 — resources'],
  'Captures a single allocated resource with its type, quantity, duration, '
  'cost, availability, and status.',
)
@SectionId('REARS')
class ResourceAllocationEntry extends DocSpecsSection {
  @Form([
    Field(
      'resourceType',
      String,
      'Resource Type (Personnel, Budget, Tool, System, External)',
      required: true,
      hint: 'Personnel, Budget, Tool, System, or External',
    ),
    Field(
      'resourceName',
      String,
      'Resource Name',
      required: true,
      hint: 'Name of the specific resource',
    ),
    Field(
      'quantity',
      String,
      'Quantity or Allocation',
      hint: 'Amount or share of the resource allocated',
    ),
    Field(
      'duration',
      String,
      'Duration (how long needed)',
      hint: 'How long the resource is needed',
    ),
    Field(
      'estimatedCost',
      String,
      'Estimated Cost',
      hint: 'Estimated cost of the resource',
    ),
    Field(
      'availability',
      String,
      'Availability (when available)',
      hint: 'When the resource becomes available',
    ),
    Field(
      'source',
      String,
      'Source (internal, external, to be hired)',
      hint: 'Internal, external, or to be hired',
    ),
    Field(
      'status',
      String,
      'Status (Requested, Allocated, Confirmed)',
      hint: 'Requested, Allocated, or Confirmed',
    ),
  ])
  @override
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
@ContentHelp(
  'Define technical goals that establish the quality attributes '
  'and capabilities of the system. Each goal should have measurable '
  'criteria and clear verification methods.',
)
@SectionId('TG')
class TechnicalGoals extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of technical goals and their '
        'relationship to business requirements. Explain the technical '
        'vision and quality attribute priorities.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Technical goals list — contains 1+× Technical Goal.
  @StandardReferences([
    'ISO/IEC 25010 — product quality goals',
    'ISO/IEC/IEEE 42010 — architecture goals',
  ], 'The list of individual technical-goal entries for this project.')
  @SectionId('TGE-GOAL-LST')
  @SectionIdPattern('TGE-GOAL-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per technical goal. Cover key quality '
    'attributes: performance, scalability, reliability, security, '
    'usability, maintainability.',
  )
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
class TechnicalGoalEntry extends DocSpecsSection {
  @Form([
    Field(
      'goalId',
      String,
      'Goal ID (unique identifier, e.g., TG-001)',
      required: true,
      hint: 'Unique identifier, e.g. TG-001',
    ),
    Field(
      'goalName',
      String,
      'Goal Name (concise statement)',
      required: true,
      hint: 'Concise statement of the technical goal',
    ),
    Field(
      'description',
      String,
      'Description (detailed explanation of the technical objective)',
      hint: 'Detailed explanation of the technical objective',
    ),
    Field(
      'goalCategory',
      String,
      'Goal Category (Performance, Scalability, Reliability, Security, '
          'Usability, Accessibility, Maintainability, Portability, '
          'Interoperability, Compliance)',
      required: true,
      hint: 'Quality attribute category, e.g. Performance, Security',
    ),
    Field(
      'priority',
      String,
      'Priority (Critical, High, Medium, Low)',
      required: true,
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Success measurement details.
  @SectionId('TGEM')
  @StandardReferences(
    ['ISO/IEC 25010 — quality measures', 'ISO/IEC 25023 — quality measurement'],
    'How achievement of the technical goal is measured: the success metric, '
    'baseline and target values, measurement method, tool, environment, and '
    'verification point.',
  )
  @Form([
    Field(
      'successMetric',
      String,
      'Primary Success Metric (what is measured)',
      required: true,
      hint: 'The primary quantity measured for this goal',
    ),
    Field(
      'currentValue',
      String,
      'Current/Baseline Value',
      hint: 'Current/baseline value before the project',
    ),
    Field(
      'targetValue',
      String,
      'Target Value',
      required: true,
      hint: 'Target value to be achieved',
    ),
    Field(
      'measurementMethod',
      String,
      'Measurement Method (APM, load testing, security scan, etc.)',
      hint: 'APM, load testing, security scan, etc.',
    ),
    Field(
      'measurementTool',
      String,
      'Measurement Tool (specific tool or platform)',
      hint: 'Specific tool or platform used to measure',
    ),
    Field(
      'measurementEnvironment',
      String,
      'Measurement Environment (production, staging, load test)',
      hint: 'Production, staging, or load-test environment',
    ),
    Field(
      'verificationPoint',
      String,
      'Verification Point (when/how verified: unit test, integration, '
          'acceptance, production monitoring)',
      hint:
          'When/how verified: unit, integration, acceptance, '
          'production monitoring',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? measurement;

  /// Scope and ownership details.
  @SectionId('TGEG')
  @StandardReferences(
    ['ISO 21500 — governance'],
    'Scope and ownership of the technical goal: the system area affected, '
    'architecture impact, technical owner, and current status.',
  )
  @Form([
    Field(
      'systemArea',
      String,
      'System Area Affected (frontend, backend, database, network, all)',
      hint: 'Frontend, backend, database, network, or all',
    ),
    Field(
      'architectureImpact',
      String,
      'Architecture Impact (how this affects system design)',
      hint: 'How this goal affects system design',
    ),
    Field(
      'owner',
      String,
      'Technical Owner',
      hint: 'Person accountable for achieving this goal',
    ),
    Field(
      'status',
      String,
      'Status (Not Started, In Progress, Verified, Failed)',
      hint: 'Not Started / In Progress / Verified / Failed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;

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
@ContentHelp(
  'Define quality scenarios using: Source → Stimulus → Environment → '
  'Artifact → Response → Response Measure pattern.',
)
@SectionId('QS')
class QualityScenarios extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of quality scenarios and how '
        'they verify achievement of the parent technical goal.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Quality scenario entries — contains 0+× QualityScenarioEntry.
  @StandardReferences([
    'ISO/IEC 25010 — quality attributes',
    'SEI ATAM — quality attribute scenarios',
  ], 'The list of individual quality-attribute scenario entries.')
  @SectionId('QLSCN-ITEM-LST')
  @SectionIdPattern('QLSCN-ITEM-xxx')
  @ContentHelp(
    'Add one entry per quality scenario covering a distinct '
    'stimulus and measurable response for the goal.',
  )
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
class QualityScenarioEntry extends DocSpecsSection {
  @Form([
    Field(
      'scenarioId',
      String,
      'Scenario ID',
      required: true,
      hint: 'Unique identifier for the scenario',
    ),
    Field(
      'scenarioName',
      String,
      'Scenario Name',
      required: true,
      hint: 'Short descriptive name',
    ),
    Field(
      'source',
      String,
      'Source (who/what generates the stimulus)',
      required: true,
      hint: 'Who/what generates the stimulus',
    ),
    Field(
      'stimulus',
      String,
      'Stimulus (event or condition that triggers the scenario)',
      required: true,
      hint: 'Event or condition that triggers the scenario',
    ),
    Field(
      'environment',
      String,
      'Environment (system state when stimulus occurs)',
      hint: 'System state when the stimulus occurs',
    ),
    Field(
      'artifact',
      String,
      'Artifact (what part of system is affected)',
      hint: 'What part of the system is affected',
    ),
    Field(
      'response',
      String,
      'Response (how the system should respond)',
      required: true,
      hint: 'How the system should respond',
    ),
    Field(
      'responseMeasure',
      String,
      'Response Measure (quantifiable success criterion)',
      required: true,
      hint: 'Quantifiable success criterion for the response',
    ),
    Field(
      'priority',
      String,
      'Priority (Core, Important, Nice-to-have)',
      hint: 'Core / Important / Nice-to-have',
    ),
    Field(
      'testability',
      String,
      'Testability (how easy to test: Automated, Manual, Complex)',
      hint: 'How easy to test: Automated, Manual, Complex',
    ),
  ])
  @override
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
@ContentHelp(
  'Define specific test criteria that will be used to verify '
  'the technical goal has been achieved.',
)
@SectionId('TGTC')
class TechnicalGoalTestCriteria extends DocSpecsSection {
  @ContentHelp(
    'Summarize the overall testing approach for verifying this '
    'technical goal.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Test criteria form.
  @SectionId('TGTC-TEST')
  @Form([
    Field(
      'testType',
      String,
      'Test Type (Performance, Load, Stress, Security, Penetration, '
          'Accessibility, Usability)',
      hint: 'Performance, Load, Stress, Security, Penetration, etc.',
    ),
    Field(
      'testEnvironment',
      String,
      'Test Environment',
      hint: 'Environment in which tests run',
    ),
    Field(
      'testData',
      String,
      'Test Data Requirements',
      hint: 'Data needed to execute the tests',
    ),
    Field(
      'testTools',
      String,
      'Test Tools',
      hint: 'Tools used to run the tests',
    ),
    Field(
      'passThreshold',
      String,
      'Pass Threshold',
      hint: 'Value at or above which the goal passes',
    ),
    Field(
      'failThreshold',
      String,
      'Fail Threshold',
      hint: 'Value at which the goal is considered failed',
    ),
    Field(
      'testSchedule',
      String,
      'Test Schedule (when tests will run)',
      hint: 'When the tests will run',
    ),
    Field(
      'retestPolicy',
      String,
      'Retest Policy (when retesting is required)',
      hint: 'When retesting is required',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? testCriteriaForm;

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
  @ContentHelp(
    'Add one entry per test case covering procedure, expected '
    'result, and status for this goal.',
  )
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
class TechnicalGoalTestCaseEntry extends DocSpecsSection {
  @Form([
    Field(
      'testCaseId',
      String,
      'Test Case ID',
      required: true,
      hint: 'Unique identifier for the test case',
    ),
    Field(
      'testCaseName',
      String,
      'Test Case Name',
      required: true,
      hint: 'Short descriptive name',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this test case verifies',
    ),
    Field(
      'testProcedure',
      String,
      'Test Procedure',
      hint: 'Steps to execute the test',
    ),
    Field(
      'expectedResult',
      String,
      'Expected Result',
      hint: 'Result expected when the goal is met',
    ),
    Field(
      'actualResult',
      String,
      'Actual Result',
      hint: 'Result observed when the test was run',
    ),
    Field(
      'status',
      String,
      'Status (Planned, In Progress, Passed, Failed)',
      hint: 'Planned / In Progress / Passed / Failed',
    ),
  ])
  @override
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
@ContentHelp(
  'Identify technical dependencies: infrastructure, APIs, '
  'third-party services, other system components.',
)
@SectionId('TGD')
class TechnicalGoalDependencies extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of technical dependencies and '
        'their impact on achieving this goal.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Dependency entries — contains 0+× TechnicalDependencyEntry.
  @StandardReferences([
    'ISO 21500 — dependency management',
  ], 'The list of individual technical-dependency entries for this goal.')
  @SectionId('TEDE-ITEM-LST')
  @SectionIdPattern('TEDE-ITEM-xxx')
  @ContentHelp(
    'Add one entry per technical dependency, capturing type, '
    'version, SLA, fallback, and status.',
  )
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
class TechnicalDependencyEntry extends DocSpecsSection {
  @Form([
    Field(
      'dependencyId',
      String,
      'Dependency ID',
      required: true,
      hint: 'Unique identifier for the dependency',
    ),
    Field(
      'dependencyName',
      String,
      'Dependency Name',
      required: true,
      hint: 'Name of the dependency',
    ),
    Field(
      'dependencyType',
      String,
      'Dependency Type (Infrastructure, API, Library, Service, '
          'Hardware, Network, Third-party)',
      hint: 'Infrastructure, API, Library, Service, Hardware, etc.',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What the dependency provides',
    ),
    Field(
      'version',
      String,
      'Version (if applicable)',
      hint: 'Required version, if applicable',
    ),
    Field(
      'sla',
      String,
      'SLA (if external service)',
      hint: 'Service-level agreement for external services',
    ),
    Field(
      'fallback',
      String,
      'Fallback (what if unavailable)',
      hint: 'What happens if the dependency is unavailable',
    ),
    Field(
      'status',
      String,
      'Status (Available, Pending, At Risk)',
      hint: 'Available / Pending / At Risk',
    ),
  ])
  @override
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
@ContentHelp(
  'Document constraints: technology choices, standards, '
  'resource limits, compatibility requirements.',
)
@SectionId('TGC')
class TechnicalGoalConstraints extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of constraints affecting this '
        'technical goal.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Constraint entries — contains 0+× TechnicalConstraintEntry.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §9 — constraints',
    'ISO/IEC/IEEE 42010 — architecture constraints',
  ], 'The list of individual technical-constraint entries for this goal.')
  @SectionId('TECN-ITEM-LST')
  @SectionIdPattern('TECN-ITEM-xxx')
  @ContentHelp(
    'Add one entry per technical constraint, capturing type, '
    'source, rationale, impact, and flexibility.',
  )
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
class TechnicalConstraintEntry extends DocSpecsSection {
  @Form([
    Field(
      'constraintId',
      String,
      'Constraint ID',
      required: true,
      hint: 'Unique identifier for the constraint',
    ),
    Field(
      'constraintName',
      String,
      'Constraint Name',
      required: true,
      hint: 'Short descriptive name',
    ),
    Field(
      'constraintType',
      String,
      'Constraint Type (Technology, Standard, Resource, '
          'Compatibility, Budget, Timeline, Regulatory)',
      hint: 'Technology, Standard, Resource, Compatibility, Budget, etc.',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What the constraint requires',
    ),
    Field(
      'source',
      String,
      'Source (who/what imposed this constraint)',
      hint: 'Who or what imposed this constraint',
    ),
    Field(
      'rationale',
      String,
      'Rationale (why this constraint exists)',
      hint: 'Why this constraint exists',
    ),
    Field(
      'impact',
      String,
      'Impact (how this affects our approach)',
      hint: 'How this affects our approach',
    ),
    Field(
      'flexibility',
      String,
      'Flexibility (Fixed, Negotiable, Preferred)',
      hint: 'Fixed / Negotiable / Preferred',
    ),
  ])
  @override
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
@ContentHelp(
  'Define criteria that collectively determine project success. '
  'Each criterion should be objectively verifiable, measurable, and '
  'time-bound. Criteria should cover business, technical, user, and '
  'compliance dimensions.',
)
@SectionId('SC')
class SuccessCriteria extends DocSpecsSection {
  @ContentHelp(
    'Provide an overview of how project success is determined and '
    'which dimensions the criteria collectively cover.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Success criteria summary.
  @SectionId('SCS')
  @StandardReferences(
    ['BABOK v3 — solution evaluation (success measures)'],
    'Aggregate counts and thresholds across all success criteria — totals by '
    'priority and category, and the overall threshold for declaring success.',
  )
  @Form([
    Field(
      'totalCriteria',
      int,
      'Total Number of Criteria',
      hint: 'Total number of success criteria defined',
    ),
    Field(
      'criticalCount',
      int,
      'Critical Criteria Count',
      hint: 'Number of critical-priority criteria',
    ),
    Field(
      'highPriorityCount',
      int,
      'High Priority Count',
      hint: 'Number of high-priority criteria',
    ),
    Field(
      'mediumPriorityCount',
      int,
      'Medium Priority Count',
      hint: 'Number of medium-priority criteria',
    ),
    Field(
      'lowPriorityCount',
      int,
      'Low Priority Count',
      hint: 'Number of low-priority criteria',
    ),
    Field(
      'businessCriteriaCount',
      int,
      'Business Criteria Count',
      hint: 'Number of business-focused criteria',
    ),
    Field(
      'technicalCriteriaCount',
      int,
      'Technical Criteria Count',
      hint: 'Number of technical-quality criteria',
    ),
    Field(
      'userCriteriaCount',
      int,
      'User Satisfaction Criteria Count',
      hint: 'Number of user-satisfaction criteria',
    ),
    Field(
      'complianceCriteriaCount',
      int,
      'Compliance Criteria Count',
      hint: 'Number of compliance-related criteria',
    ),
    Field(
      'minCriteriaMet',
      String,
      'Minimum Criteria for Success',
      hint: 'All critical + X% of others',
    ),
    Field(
      'successThreshold',
      String,
      'Overall Success Threshold',
      hint: 'Percentage or formula for determining success',
    ),
  ])
  @ContentType('aggregation', 'Summary statistics for success criteria.')
  @SerializationOrder(1)
  DocSpecsSection? summary;

  /// Acceptance and evaluation framework.
  @SectionId('SCF')
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
    Field(
      'acceptanceProcess',
      String,
      'Acceptance Process',
      hint: 'How criteria will be evaluated',
    ),
    Field(
      'signOffAuthority',
      String,
      'Sign-off Authority',
      hint: 'Who approves project success',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'Who to escalate when criteria not met',
    ),
    Field(
      'evaluationTiming',
      String,
      'Evaluation Timing',
      hint: 'When criteria will be evaluated',
    ),
    Field(
      'evaluationMilestones',
      String,
      'Evaluation Milestones',
      hint: 'Go-live, 30 days, 90 days, 1 year',
    ),
    Field(
      'partialSuccessHandling',
      String,
      'Partial Success Handling',
      hint: 'What if some criteria not met',
    ),
    Field(
      'criteriaWaiverProcess',
      String,
      'Criteria Waiver Process',
      hint: 'How criteria can be waived or modified',
    ),
    Field(
      'evidenceRequirements',
      String,
      'Evidence Requirements',
      hint: 'What evidence is needed to prove criteria met',
    ),
    Field(
      'independentVerification',
      String,
      'Independent Verification',
      hint: 'Whether third-party verification is required',
    ),
    Field(
      'disputeResolution',
      String,
      'Dispute Resolution',
      hint: 'How disputes about criteria are resolved',
    ),
  ])
  @ContentType('form', 'Acceptance and evaluation framework details.')
  @SerializationOrder(2)
  DocSpecsSection? framework;

  /// Success criterion entries — contains 1+× SuccessCriterionEntry.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §9 — acceptance & verification criteria',
    'BABOK v3 — solution evaluation',
  ], 'The list of individual success-criterion entries for this project.')
  @SectionId('SCE-ITEM-LST')
  @SectionIdPattern('SCE-ITEM-xxx')
  @Min(1)
  @ContentHelp(
    'Define individual success criteria. Include criteria for '
    'business outcomes, user satisfaction, technical quality, and '
    'compliance requirements.',
  )
  @SerializationOrder(3)
  List<SuccessCriterionEntry> items = [];

  /// Success criteria by category.
  @SerializationOrder(4)
  SuccessCriteriaByCategory byCategory = SuccessCriteriaByCategory();

  /// Success criteria matrix — overall view.
  @SectionId('SC-SUCC')
  @ContentType(
    'description',
    'Success criteria matrix showing all criteria, '
        'their weights, and evaluation status.',
  )
  @ContentHelp('Create a summary matrix of all success criteria.')
  @SerializationOrder(5)
  DocSpecsSection? successCriteriaMatrix;

  /// Post-implementation review plan.
  @SectionId('PIR')
  @StandardReferences(
    ['BABOK v3 — solution evaluation (success measures)'],
    'The plan for reviewing success after implementation: review schedule and '
    'owner, participants, reporting, lessons learned, benefits-tracking '
    'duration, and corrective action.',
  )
  @Form([
    Field(
      'reviewSchedule',
      String,
      'Review Schedule',
      hint: 'When post-implementation reviews occur',
    ),
    Field(
      'reviewOwner',
      String,
      'Review Owner',
      hint: 'Who is responsible for organizing reviews',
    ),
    Field(
      'participantRoles',
      String,
      'Participant Roles',
      hint: 'Who should participate in reviews',
    ),
    Field(
      'reportingRequirements',
      String,
      'Reporting Requirements',
      hint: 'What reports are produced',
    ),
    Field(
      'lessonsLearnedProcess',
      String,
      'Lessons Learned Process',
      hint: 'How lessons learned are captured',
    ),
    Field(
      'benefitsTrackingDuration',
      String,
      'Benefits Tracking Duration',
      hint: 'How long benefits are tracked',
    ),
    Field(
      'correctionActionProcess',
      String,
      'Corrective Action Process',
      hint: 'How shortfalls are addressed',
    ),
  ])
  @ContentType('form', 'Post-implementation review planning.')
  @SerializationOrder(6)
  DocSpecsSection? postImplementationReview;
}

/// Success criteria organized by category.
@StandardReferences(
  ['BABOK v3 — solution evaluation (success measures)'],
  'Success criteria grouped by dimension — business, technical, user, '
  'compliance, and project — for a category-by-category view of success.',
)
@SectionId('SCBC')
class SuccessCriteriaByCategory extends DocSpecsSection {
  /// Business outcome criteria overview.
  @SectionId('SCBC-BUSI')
  @ContentType(
    'description',
    'Overview of business-focused success criteria '
        'including ROI, market impact, and strategic alignment.',
  )
  @ContentHelp('Describe how business outcomes will be measured.')
  @SerializationOrder(0)
  DocSpecsSection? businessCriteria;

  /// Technical quality criteria overview.
  @SectionId('SCBC-TECH')
  @ContentType(
    'description',
    'Overview of technical quality criteria '
        'including performance, reliability, and maintainability.',
  )
  @ContentHelp('Describe how technical quality will be measured.')
  @SerializationOrder(1)
  DocSpecsSection? technicalCriteria;

  /// User satisfaction criteria overview.
  @SectionId('SCBC-USER')
  @ContentType(
    'description',
    'Overview of user-focused success criteria '
        'including adoption, satisfaction, and productivity.',
  )
  @ContentHelp('Describe how user satisfaction will be measured.')
  @SerializationOrder(2)
  DocSpecsSection? userCriteria;

  /// Compliance criteria overview.
  @SectionId('SCBC-COMP')
  @ContentType(
    'description',
    'Overview of compliance-related success criteria '
        'including regulatory, security, and audit requirements.',
  )
  @ContentHelp('Describe how compliance will be verified.')
  @SerializationOrder(3)
  DocSpecsSection? complianceCriteria;

  /// Timeline and budget criteria overview.
  @SectionId('SCBC-PROJ')
  @ContentType(
    'description',
    'Overview of project management criteria '
        'including timeline adherence, budget compliance, and scope management.',
  )
  @ContentHelp('Describe how project execution will be measured.')
  @SerializationOrder(4)
  DocSpecsSection? projectCriteria;
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
class SuccessCriterionEntry extends DocSpecsSection {
  @Form([
    Field(
      'criterionId',
      String,
      'Criterion ID',
      required: true,
      hint: 'Unique identifier (e.g., SC-001)',
    ),
    Field(
      'criterionName',
      String,
      'Criterion Name',
      required: true,
      hint: 'Short descriptive name',
    ),
    Field(
      'category',
      String,
      'Category',
      required: true,
      hint: 'Business, Technical, User, Compliance, Budget, Timeline',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identification details.
  @SectionId('SUCRID')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — acceptance & verification criteria',
      'BABOK v3 — solution evaluation',
    ],
    'Identifying detail for the criterion: its description of what success means '
    'and its subcategory.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed description of what success means',
    ),
    Field(
      'subcategory',
      String,
      'Subcategory',
      hint: 'More specific categorization',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  /// Measurement.
  @SectionId('SUCRME')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — verification criteria',
      'ISO/IEC 25023 — measurement',
    ],
    'How the criterion is measured: the metric, baseline, minimum threshold, '
    'target, stretch goal, and unit of measurement.',
  )
  @Form([
    Field(
      'metric',
      String,
      'Metric',
      required: true,
      hint: 'What is measured (e.g., response time, satisfaction score)',
    ),
    Field(
      'baselineValue',
      String,
      'Baseline Value',
      hint: 'Current value before project',
    ),
    Field(
      'minimumThreshold',
      String,
      'Minimum Acceptable Threshold',
      hint: 'Minimum value to be considered success',
    ),
    Field(
      'targetValue',
      String,
      'Target Value',
      required: true,
      hint: 'Desired target value',
    ),
    Field(
      'stretchGoal',
      String,
      'Stretch Goal',
      hint: 'Optimal value exceeding target',
    ),
    Field(
      'unit',
      String,
      'Unit of Measurement',
      hint: 'e.g., %, seconds, count, currency',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? measurement;

  /// Verification.
  @SectionId('SUCRVE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — verification criteria',
      'ISO/IEC 25023 — measurement',
    ],
    'How the criterion is verified: measurement method, data source, frequency, '
    'responsible party, verification point, and evidence type.',
  )
  @Form([
    Field(
      'measurementMethod',
      String,
      'Measurement Method',
      hint: 'How metric will be measured',
    ),
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Where measurement data comes from',
    ),
    Field(
      'measurementFrequency',
      String,
      'Measurement Frequency',
      hint: 'How often measurement is taken',
    ),
    Field(
      'responsibleParty',
      String,
      'Responsible Party',
      hint: 'Who is responsible for measurement',
    ),
    Field(
      'verificationPoint',
      String,
      'Verification Point',
      hint: 'When verified: go-live, 30 days, 90 days',
    ),
    Field(
      'evidenceType',
      String,
      'Evidence Type',
      hint: 'What evidence proves criterion met',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;

  /// Importance.
  @SectionId('SUCRIM')
  @StandardReferences(
    ['BABOK v3 — solution evaluation (success measures)'],
    'The importance of the criterion: its weight, whether it is mandatory, and '
    'the consequence if it is not met.',
  )
  @Form([
    Field(
      'weight',
      String,
      'Weight',
      hint: 'Importance: Critical, High, Medium, Low',
    ),
    Field(
      'isMandatory',
      String,
      'Mandatory',
      hint: 'Yes/No - is this required for overall success',
    ),
    Field(
      'consequenceIfNotMet',
      String,
      'Consequence If Not Met',
      hint: 'Impact if this criterion is not met',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? importance;

  /// Relationships.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
    'The list of relationship entries linking this criterion to goals, '
    'requirements, dependencies, and stakeholders.',
  )
  @SectionId('SUCRRE-RELA-LST')
  @SectionIdPattern('SUCRRE-RELA-xxx')
  @ContentHelp(
    'Add relationship entries tracing this criterion to related '
    'goals, requirements, dependencies, and stakeholders.',
  )
  @SerializationOrder(5)
  List<SuccessCriterionRelationships> relationships = [];

  /// Status.
  @SectionId('SUCRST')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — verification criteria',
      'BABOK v3 — solution evaluation',
    ],
    'The current evaluation status of the criterion: status, current value, '
    'trend, evidence, and evaluation notes.',
  )
  @Form([
    Field(
      'status',
      String,
      'Status',
      hint: 'Not Evaluated, Met, Not Met, Waived',
    ),
    Field(
      'currentValue',
      String,
      'Current Value',
      hint: 'Latest measured value',
    ),
    Field('trend', String, 'Trend', hint: 'Improving, Stable, Declining'),
    Field('evidence', String, 'Evidence', hint: 'Proof that criterion is met'),
    Field(
      'evaluationNotes',
      String,
      'Evaluation Notes',
      hint: 'Notes from evaluation',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? status;
}

/// Relationships for success criterion.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'A single relationship entry tracing this criterion to related goals, '
  'requirements, dependencies, and key stakeholders.',
)
@SectionId('SUCRRE')
class SuccessCriterionRelationships extends DocSpecsSection {
  @Form([
    Field(
      'relatedGoals',
      String,
      'Related Goals',
      hint: 'Which business/technical goals this supports',
    ),
    Field(
      'relatedRequirements',
      String,
      'Related Requirements',
      hint: 'Requirement IDs that contribute to this criterion',
    ),
    Field(
      'dependencies',
      String,
      'Dependencies',
      hint: 'Other criteria this depends on',
    ),
    Field(
      'stakeholders',
      String,
      'Key Stakeholders',
      hint: 'Who cares most about this criterion',
    ),
  ])
  @override
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
@ContentHelp(
  'Define initial requirements at a level sufficient for project '
  'scoping and planning. Each requirement should be traceable to business '
  'goals and verifiable through acceptance criteria.',
)
@SectionId('RO')
class RequirementsOverview extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Requirements overview form.
  @SectionId('RO-REQU')
  @Form([
    Field(
      'requirementsProcess',
      String,
      'Requirements Process (how requirements are elicited and managed)',
      hint: 'How requirements are elicited, analysed, and managed',
    ),
    Field(
      'traceabilityApproach',
      String,
      'Traceability Approach (how requirements are linked to goals, tests, code)',
      hint: 'How requirements are linked to goals, tests, and code',
    ),
    Field(
      'changeControlProcess',
      String,
      'Change Control Process (how requirement changes are handled)',
      hint: 'How requirement changes are proposed, reviewed, and approved',
    ),
    Field(
      'prioritizationMethod',
      String,
      'Prioritization Method (MoSCoW, Weighted, etc.)',
      hint: 'MoSCoW, weighted scoring, or other prioritisation scheme',
    ),
    Field(
      'totalRequirements',
      String,
      'Total Requirements Expected (estimated count)',
      hint: 'Estimated total number of requirements',
    ),
    Field(
      'mustHaveCount',
      String,
      'Must-Have Requirements (estimated)',
      hint: 'Estimated count of Must-Have requirements',
    ),
    Field(
      'shouldHaveCount',
      String,
      'Should-Have Requirements (estimated)',
      hint: 'Estimated count of Should-Have requirements',
    ),
    Field(
      'couldHaveCount',
      String,
      'Could-Have Requirements (estimated)',
      hint: 'Estimated count of Could-Have requirements',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? requirementsForm;

  /// Traceability matrix overview.
  @SectionId('RO-TRAC')
  @ContentType(
    'description',
    'Summary of traceability matrix showing '
        'connections between requirements, goals, use cases, and tests.',
  )
  @ContentHelp('Provide a high-level view of requirement traceability.')
  @SerializationOrder(2)
  DocSpecsSection? traceabilityMatrix;

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
  @ContentHelp(
    'Add one entry per relationship between requirements, capturing '
    'the linked requirements and the nature of their relationship.',
  )
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
@ContentHelp(
  'Functional requirements describe system capabilities, behaviors, '
  'and features. Use clear, testable language. Each requirement should '
  'answer: What must the system do? For whom? Under what conditions?',
)
@SectionId('FR')
class FunctionalRequirements extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Functional requirements summary form.
  @SectionId('FR-SUMM')
  @Form([
    Field(
      'totalFunctionalRequirements',
      String,
      'Total Functional Requirements',
      hint: 'Total count of functional requirements',
    ),
    Field(
      'mustHaveFunctional',
      String,
      'Must-Have (count)',
      hint: 'Count of Must-Have functional requirements',
    ),
    Field(
      'shouldHaveFunctional',
      String,
      'Should-Have (count)',
      hint: 'Count of Should-Have functional requirements',
    ),
    Field(
      'couldHaveFunctional',
      String,
      'Could-Have (count)',
      hint: 'Count of Could-Have functional requirements',
    ),
    Field(
      'wontHaveThisTimeFunctional',
      String,
      'Won\'t-Have-This-Time (count)',
      hint: 'Count of Won\'t-Have-This-Time functional requirements',
    ),
    Field(
      'coverageNote',
      String,
      'Coverage Notes',
      hint: 'Notes on coverage and any gaps in the requirement set',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? summaryForm;

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
  @ContentHelp(
    'Add one entry per functional requirement. Group related '
    'requirements together. Each requirement should be atomic, testable, '
    'and have clear acceptance criteria.',
  )
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
class FunctionalRequirementEntry extends DocSpecsSection {
  // Why: there is a single authoritative storage slot for each of the
  // requirement's title and id — the id lives solely in the item's stored
  // section id (the owning list's `@SectionIdPattern('FRE-REQU-xxx')`), the
  // title solely in the item heading. No form field restates either
  // (tom_specs_model_rules.md §8, YRD6 reversed).
  @Form([
    Field(
      'status',
      String,
      'Status (Draft, Proposed, Approved, Implemented, Verified, Deferred)',
      required: true,
      hint: 'Draft, Proposed, Approved, Implemented, Verified, or Deferred',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Requirement details: description, type, category.
  @SectionId('FRED')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.5 — functional requirements',
      'BABOK v3 §10 — functional requirements',
    ],
    'The core definition of a functional requirement — its detailed "the system '
    'shall" statement, its type, and its functional-area category.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description (The system shall... detailed statement)',
      required: true,
      hint: 'Detailed "the system shall..." statement of the requirement',
    ),
    Field(
      'requirementType',
      String,
      'Requirement Type (Feature, User Story, Business Rule, Report, '
          'Integration, Calculation, Workflow, Notification, Search, '
          'Data Entry, Data Display, Data Export, Batch Process)',
      hint: 'Feature, User Story, Business Rule, Report, Integration, etc.',
    ),
    Field(
      'category',
      String,
      'Category (functional area grouping)',
      hint: 'Functional-area grouping for this requirement',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? details;

  /// Priority and effort assessment.
  @SectionId('FREP')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §5.2 — requirement prioritization',
      'MoSCoW — prioritization',
    ],
    'The priority, business value, effort, and risk assessment for a functional '
    'requirement — how it is ranked and what it costs and risks.',
  )
  @Form([
    Field(
      'priority',
      String,
      'Priority (Must, Should, Could, Won\'t-This-Time)',
      required: true,
      hint: 'MoSCoW priority: Must, Should, Could, or Won\'t-This-Time',
    ),
    Field(
      'businessValue',
      String,
      'Business Value (High, Medium, Low) - benefit to business',
      hint: 'High / Medium / Low benefit to the business',
    ),
    Field(
      'effort',
      String,
      'Estimated Effort (Small, Medium, Large, XLarge)',
      hint: 'Estimated effort: Small, Medium, Large, or XLarge',
    ),
    Field(
      'riskLevel',
      String,
      'Risk Level (High, Medium, Low) - risk of not meeting',
      hint: 'High / Medium / Low risk of not meeting the requirement',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? priority;

  /// Source and rationale.
  @SectionId('FRES')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
    'The provenance of a functional requirement — who requested it, when, and the '
    'rationale that justifies it, anchoring traceability back to its origin.',
  )
  @Form([
    Field(
      'source',
      String,
      'Source (who requested: stakeholder name, workshop, document)',
      required: true,
      hint: 'Who requested it: stakeholder name, workshop, or document',
    ),
    Field(
      'requestDate',
      String,
      'Request Date',
      hint: 'Date the requirement was requested',
    ),
    Field(
      'rationale',
      String,
      'Rationale (why this requirement is needed)',
      hint: 'Why this requirement is needed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? source;

  /// Verification criteria.
  @SectionId('FREV')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6.5 — verification', 'ISO/IEC/IEEE 29119 — testing'],
    'How a functional requirement is verified — its measurable fit criterion and '
    'the customer satisfaction/dissatisfaction it drives.',
  )
  @Form([
    Field(
      'fitCriterion',
      String,
      'Fit Criterion (measurable condition for acceptance)',
      hint: 'Measurable condition that must hold for acceptance',
    ),
    Field(
      'customerSatisfaction',
      String,
      'Customer Satisfaction (1-5 scale if delivered)',
      hint: '1-5 scale of satisfaction if the requirement is delivered',
    ),
    Field(
      'customerDissatisfaction',
      String,
      'Customer Dissatisfaction (1-5 scale if NOT delivered)',
      hint: '1-5 scale of dissatisfaction if it is NOT delivered',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? verification;

  /// Assumptions and constraints.
  @SectionId('FREC')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §9.5 — functional requirements'],
    'The assumptions a functional requirement relies on, the constraints it must '
    'respect, and the other requirements it conflicts with.',
  )
  @Form([
    Field(
      'assumptions',
      String,
      'Assumptions (conditions assumed to be true)',
      hint: 'Conditions assumed to be true for this requirement',
    ),
    Field(
      'constraints',
      String,
      'Constraints (limitations on implementation)',
      hint: 'Limitations on how the requirement may be implemented',
    ),
    Field(
      'conflictsWith',
      String,
      'Conflicts With (IDs of conflicting requirements)',
      hint: 'IDs of requirements this one conflicts with',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? constraints;

  /// Version metadata.
  @SectionId('FREM')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
    'The version-control metadata for a functional requirement — its version, '
    'last-modified date, and last editor, supporting change traceability.',
  )
  @Form([
    Field(
      'version',
      String,
      'Version',
      hint: 'Version number of this requirement',
    ),
    Field(
      'lastModified',
      String,
      'Last Modified Date',
      hint: 'Date the requirement was last modified',
    ),
    Field(
      'modifiedBy',
      String,
      'Modified By',
      hint: 'Who last modified the requirement',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? metadata;

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
@ContentHelp(
  'Define clear, testable acceptance criteria. Use Given-When-Then '
  'format: Given [context], When [action], Then [expected result].',
)
@SectionId('RAC')
class RequirementAcceptanceCriteria extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of acceptance approach and '
        'test coverage expectations.',
  )
  @override
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
@CodeSpecKind(
  [CodeSpecPart.validation],
  note:
      'CE-VA — given/when/then acceptance criteria realised as verification rules',
)
class AcceptanceCriterionEntry extends DocSpecsSection {
  @Form([
    Field(
      'criterionId',
      String,
      'Criterion ID',
      required: true,
      hint: 'Unique identifier for this criterion',
    ),
    Field(
      'criterionTitle',
      String,
      'Criterion Title',
      required: true,
      hint: 'Short title describing the criterion',
    ),
    Field(
      'given',
      String,
      'Given (precondition/context)',
      hint: 'Precondition or context that holds before the action',
    ),
    Field(
      'when',
      String,
      'When (action/trigger)',
      hint: 'Action or trigger that occurs',
    ),
    Field(
      'then',
      String,
      'Then (expected outcome)',
      required: true,
      hint: 'Expected outcome after the action',
    ),
    Field(
      'and',
      String,
      'And (additional outcomes)',
      hint: 'Any additional expected outcomes',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method (Manual, Automated, Inspection, Demo)',
      hint: 'Manual, Automated, Inspection, or Demo',
    ),
    Field(
      'testType',
      String,
      'Test Type (Unit, Integration, System, Acceptance, UAT)',
      hint: 'Unit, Integration, System, Acceptance, or UAT',
    ),
    Field(
      'priority',
      String,
      'Priority (Critical, High, Medium, Low)',
      hint: 'Critical, High, Medium, or Low',
    ),
    Field(
      'status',
      String,
      'Status (Draft, Ready, Passed, Failed, Blocked)',
      hint: 'Draft, Ready, Passed, Failed, or Blocked',
    ),
  ])
  @override
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
@ContentHelp(
  'Define business rules that affect this requirement. Business '
  'rules are constraints, calculations, or policies from the business domain.',
)
@SectionId('RBR')
class RequirementBusinessRules extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of business rules associated '
        'with this requirement.',
  )
  @override
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
  @ContentHelp(
    'Add one entry per business rule that constrains or guides this '
    'requirement.',
  )
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
@CodeSpecKind(
  [CodeSpecPart.validation],
  note:
      'CE-VA — a requirement business rule (statement + enforcement) realised as a validation rule',
)
class RequirementBusinessRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'ruleId',
      String,
      'Rule ID',
      required: true,
      hint: 'Unique identifier for this business rule',
    ),
    Field(
      'ruleName',
      String,
      'Rule Name',
      required: true,
      hint: 'Short descriptive name for the rule',
    ),
    Field(
      'ruleType',
      String,
      'Rule Type (Constraint, Computation, Derivation, Inference, '
          'Condition, Action, Workflow, Authorization)',
      hint: 'Constraint, Computation, Derivation, Inference, Condition, etc.',
    ),
    Field(
      'ruleStatement',
      String,
      'Rule Statement (IF/WHEN condition THEN action)',
      required: true,
      hint: 'IF/WHEN condition THEN action statement',
    ),
    Field(
      'source',
      String,
      'Source (policy, regulation, expert)',
      hint: 'Origin of the rule: policy, regulation, or expert',
    ),
    Field(
      'effectiveDate',
      String,
      'Effective Date',
      hint: 'Date the rule takes effect',
    ),
    Field(
      'expirationDate',
      String,
      'Expiration Date',
      hint: 'Date the rule expires, if any',
    ),
    Field(
      'exceptions',
      String,
      'Exceptions (when rule does not apply)',
      hint: 'Cases in which the rule does not apply',
    ),
    Field(
      'enforcement',
      String,
      'Enforcement (Hard = system enforces, Soft = warning only)',
      hint: 'Hard (system enforces) or Soft (warning only)',
    ),
    Field(
      'impact',
      String,
      'Impact (what happens if rule is violated)',
      hint: 'What happens if the rule is violated',
    ),
  ])
  @override
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
@ContentHelp(
  'Define the data entities and attributes this requirement '
  'reads, creates, updates, or deletes.',
)
@SectionId('RDR')
class RequirementDataRequirements extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of data requirements and '
        'CRUD (Create, Read, Update, Delete) operations.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Data entity entries — contains 0+× DataEntityReferenceEntry.
  @StandardReferences([
    'BABOK v3 §10.18 — data modelling',
    'ISO/IEC/IEEE 29148 §9 — data requirements',
  ], 'The list of individual data-entity references used by this requirement.')
  @SectionId('DAENRE-ENTI-LST')
  @SectionIdPattern('DAENRE-ENTI-xxx')
  @ContentHelp(
    'Add one entry per data entity this requirement reads, creates, '
    'updates, or deletes.',
  )
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
@CodeSpecKind(
  [CodeSpecPart.dataAccess],
  note:
      'CE-DB — the entity + CRUD operations + data-quality rules a requirement touches, realised as data access',
)
class DataEntityReferenceEntry extends DocSpecsSection {
  @Form([
    Field(
      'entityName',
      String,
      'Entity Name',
      required: true,
      hint: 'Name of the data entity referenced',
    ),
    Field(
      'crudOperations',
      String,
      'CRUD Operations (Create, Read, Update, Delete)',
      required: true,
      hint: 'Which of Create, Read, Update, Delete are performed',
    ),
    Field(
      'attributes',
      String,
      'Attributes (specific fields involved)',
      hint: 'Specific fields/attributes involved',
    ),
    Field(
      'volumeEstimate',
      String,
      'Volume Estimate (records created/accessed)',
      hint: 'Estimated number of records created or accessed',
    ),
    Field(
      'dataQualityRules',
      String,
      'Data Quality Rules (validation, completeness)',
      hint: 'Validation and completeness rules for the data',
    ),
    Field(
      'dataOwner',
      String,
      'Data Owner',
      hint: 'Owner accountable for this data entity',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @SectionId('DAENRE-RELA-REF')
  @Reference('Related Data Model Entity')
  @SerializationOrder(1)
  DocSpecsSection? relatedEntity;
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
@ContentHelp(
  'Define the UI elements needed to support this requirement. '
  'Specify screens, forms, fields, actions, and behaviors.',
)
@SectionId('RUS')
class RequirementUiSpecification extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// UI specification form.
  @SectionId('RUS-UIFO')
  @Form([
    Field(
      'screenName',
      String,
      'Screen/View Name',
      hint: 'Name of the screen or view',
    ),
    Field(
      'screenType',
      String,
      'Screen Type (List, Detail, Form, Dashboard, Dialog, Wizard)',
      hint: 'List, Detail, Form, Dashboard, Dialog, or Wizard',
    ),
    Field(
      'navigationPath',
      String,
      'Navigation Path (how user reaches this)',
      hint: 'How the user navigates to reach this screen',
    ),
    Field(
      'userRoles',
      String,
      'Allowed User Roles',
      hint: 'Roles allowed to access this screen',
    ),
    Field(
      'responsiveBreakpoints',
      String,
      'Responsive Breakpoints (mobile, tablet, desktop)',
      hint: 'Responsive breakpoints: mobile, tablet, desktop',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? uiForm;

  /// UI layout specification (D4rt Flutter code).
  @SectionId('RUS-LAYO')
  @ContentType(
    'code-dart',
    'Flutter/D4rt code specifying the UI layout '
        'using tom_flutter_ui components.',
  )
  @ContentHelp(
    'Provide D4rt Flutter code for the UI layout, using '
    'tom_flutter_ui components. This can be rendered in documentation.',
  )
  @SerializationOrder(2)
  DocSpecsSection? layoutCode;

  /// UI mockup diagram (fallback if code not available).
  @SectionId('RUS-MOCK')
  @ContentType(
    'description',
    'ASCII or text description of UI mockup '
        'if D4rt code is not available.',
  )
  @SerializationOrder(3)
  DocSpecsSection? mockupDescription;

  /// Screen field entries — contains 0+× ScreenFieldEntry.
  @StandardReferences([
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ], 'The list of individual screen-field entries that make up this UI.')
  @SectionId('SCFLD-FIEL-LST')
  @SectionIdPattern('SCFLD-FIEL-xxx')
  @ContentHelp('Define each field in the UI.')
  @SerializationOrder(4)
  List<ScreenFieldEntry> fields = [];

  /// Screen action entries — contains 0+× RequirementScreenActionEntry.
  @StandardReferences([
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ], 'The list of individual screen-action entries available in this UI.')
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
@OneOf(
  discriminator: 'fieldType',
  note:
      'Screen field type closed choice (csra4): the field type selects its '
      'type-specific constraint and presentation subsections, so a Date field '
      'no longer carries a regex pattern and a Text field no longer carries a '
      'dropdown source.',
)
@CodeSpecKind(
  [CodeSpecPart.form],
  note:
      'CE-FM — a requirement-side form field spec (type, binding, layout); authoritative UI parts owned by the ExperienceDesign D09 pass',
)
class ScreenFieldEntry extends DocSpecsSection {
  @Form([
    Field(
      'fieldId',
      String,
      'Field ID',
      required: true,
      hint: 'Unique identifier for this field',
    ),
    Field(
      'fieldLabel',
      String,
      'Field Label (display text)',
      required: true,
      hint: 'Display text shown for the field',
    ),
    Field(
      'fieldType',
      ScreenFieldKind,
      'Field Type',
      required: true,
      hint: 'The kind of value the user supplies — selects the type-specific '
          'constraint and presentation subsections',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data binding and defaults.
  @SectionId('SFDB')
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'How a screen field binds to data — its entity.attribute binding, default '
    'value, placeholder, and help text.',
  )
  @Form([
    Field(
      'dataBinding',
      String,
      'Data Binding (entity.attribute)',
      hint: 'Entity.attribute the field binds to',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Default value for the field',
    ),
    Field(
      'placeholder',
      String,
      'Placeholder Text',
      hint: 'Placeholder text shown when empty',
    ),
    Field(
      'helpText',
      String,
      'Help Text / Tooltip',
      hint: 'Help text or tooltip for the field',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dataBinding;

  /// Conditional behavior.
  @SectionId('SCFICO')
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'The conditional behavior of a screen field — when it is required, read-only, '
    'or visible, and the conditions that govern each.',
  )
  @Form([
    Field(
      'required',
      String,
      'Required (Yes, No, Conditional)',
      hint: 'Yes, No, or Conditional',
    ),
    Field(
      'requiredCondition',
      String,
      'Required Condition',
      hint: 'Condition under which the field is required',
    ),
    Field(
      'readOnly',
      String,
      'Read Only (Yes, No, Conditional)',
      hint: 'Yes, No, or Conditional',
    ),
    Field(
      'readOnlyCondition',
      String,
      'Read Only Condition',
      hint: 'Condition under which the field is read-only',
    ),
    Field(
      'visible',
      String,
      'Visible (Yes, No, Conditional)',
      hint: 'Yes, No, or Conditional',
    ),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'Condition under which the field is visible',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? conditions;

  /// Validation rules that apply whatever the field type is.
  @SectionId('SCFIVA')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — input validation requirements',
      'OWASP ASVS — input validation',
    ],
    'The type-independent validation settings of a screen field — the custom '
    'message shown when any built-in constraint fails.',
  )
  @Form([
    Field(
      'validationMessage',
      String,
      'Custom Validation Message',
      hint: 'Message shown when validation fails',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? validation;

  /// Text-kind input constraints — a promoted `@OneOf` case (csra4).
  @SectionId('SCFIVT')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — input validation requirements',
      'OWASP ASVS — input validation',
    ],
    'The input constraints that only apply to a text-valued screen field — its '
    'length bounds and the regular expression the input must match.',
  )
  @Case(ScreenFieldKind.text)
  @Case(ScreenFieldKind.multilineText)
  @Case(ScreenFieldKind.email)
  @Case(ScreenFieldKind.phone)
  @Case(ScreenFieldKind.url)
  @Case(ScreenFieldKind.password)
  @Form([
    Field(
      'minLength',
      String,
      'Minimum Length',
      hint: 'Minimum allowed input length in characters',
    ),
    Field(
      'maxLength',
      String,
      'Maximum Length',
      hint: 'Maximum allowed input length in characters',
    ),
    Field(
      'pattern',
      String,
      'Validation Pattern (regex)',
      hint: 'Regular expression the input must match',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? textConstraints;

  /// Numeric-kind input constraints — a promoted `@OneOf` case (csra4).
  @SectionId('SCFIVN')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — input validation requirements',
      'OWASP ASVS — input validation',
    ],
    'The input constraints that only apply to a numeric screen field — its '
    'value bounds.',
  )
  @Case(ScreenFieldKind.integer)
  @Case(ScreenFieldKind.decimal)
  @Case(ScreenFieldKind.currency)
  @Form([
    Field(
      'minValue',
      String,
      'Minimum Value',
      hint: 'Smallest value the field accepts',
    ),
    Field(
      'maxValue',
      String,
      'Maximum Value',
      hint: 'Largest value the field accepts',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? numericConstraints;

  /// Temporal-kind input constraints — a promoted `@OneOf` case (csra4).
  ///
  /// Kept apart from [numericConstraints] because a date boundary is expressed
  /// as a date or a relative expression ("today + 30d"), not as a number.
  @SectionId('SCFIVD')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — input validation requirements',
      'ISO 8601 — date and time representation',
    ],
    'The input constraints that only apply to a temporal screen field — its '
    'earliest and latest accepted instant.',
  )
  @Case(ScreenFieldKind.date)
  @Case(ScreenFieldKind.dateTime)
  @Case(ScreenFieldKind.time)
  @Form([
    Field(
      'earliestValue',
      String,
      'Earliest Accepted Value',
      hint: 'Earliest accepted date/time, absolute or relative (e.g. today)',
    ),
    Field(
      'latestValue',
      String,
      'Latest Accepted Value',
      hint: 'Latest accepted date/time, absolute or relative (e.g. today + 30d)',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? temporalConstraints;

  /// Choice-kind option source — a promoted `@OneOf` case (csra4).
  @SectionId('SCFICH')
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'Where a choice field takes its options from — the option source and, for a '
    'static source, the values themselves.',
  )
  @Case(ScreenFieldKind.singleSelect)
  @Case(ScreenFieldKind.multiSelect)
  @Form([
    Field(
      'optionSource',
      String,
      'Option Source (static, API, entity)',
      hint: 'Where the options come from: static, API, or entity',
    ),
    Field(
      'staticOptions',
      String,
      'Static Option Values',
      hint: 'The option values, when the source is static',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? choiceOptions;

  /// File-kind input constraints — a promoted `@OneOf` case (csrb8).
  ///
  /// Constraints only. **How** the file is presented — link, dropzone or
  /// thumbnail — is the D09 design pass's `fileOptions`
  /// (`ScreenElementFieldSpec`), because a requirement names the kind of value
  /// a user supplies and the design names the concrete control. The storage
  /// group is neither side's: it is authored on the CE-DB file-reference column
  /// (`codespecs_mapping.md` §5.13.1).
  @SectionId('SCFIFI')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9 — input validation requirements',
      'ISO/IEC 2382:2015 — content and media type terminology',
    ],
    'The input constraints that only apply to a file-valued screen field — what '
    'content kinds it accepts and how large a file may be.',
  )
  @Case(ScreenFieldKind.file)
  @Form([
    Field(
      'acceptedContentKinds',
      String,
      'Accepted Content Kinds',
      hint:
          'What may be supplied: a content-kind family (any/image/video/audio) '
          'and/or the accepted file extensions',
    ),
    Field(
      'maxFileSize',
      String,
      'Maximum File Size',
      hint: 'Largest file the field accepts, e.g. 10 MB',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? fileConstraints;

  /// UI and layout.
  @SectionId('SCFILA')
  @StandardReferences(
    [
      'ISO 9241-110 — dialogue principles',
      'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
    ],
    'The layout and presentation of a screen field — its dependencies, width, '
    'display order, and grouping.',
  )
  @Form([
    Field(
      'dependsOn',
      String,
      'Depends On (field IDs that affect this)',
      hint: 'Field IDs that affect this field',
      refersTo: ['SFE.fieldId'],
    ),
    Field(
      'width',
      String,
      'Width (full, half, third, quarter, custom)',
      hint: 'full, half, third, quarter, or custom',
    ),
    Field(
      'order',
      String,
      'Display Order',
      hint: 'Order in which the field is displayed',
    ),
    Field(
      'grouping',
      String,
      'Field Grouping / Section',
      hint: 'Group or section the field belongs to',
    ),
  ])
  @SerializationOrder(9)
  DocSpecsSection? layout;

  /// Field validation rules — contains 0+× FieldValidationRule.
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §9 — input validation requirements',
    'OWASP ASVS — input validation',
  ], 'The list of individual validation rules applied to this field\'s input.')
  @SectionId('FLDVL-VALI-LST')
  @SectionIdPattern('FLDVL-VALI-xxx')
  @ContentHelp('Add one entry per validation rule applied to this field.')
  @SerializationOrder(10)
  List<FieldValidationRule> validationRules = [];
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
@CodeSpecKind(
  [CodeSpecPart.validation],
  note:
      'CE-VA — a field validation rule (expression, error code, severity, trigger)',
)
class FieldValidationRule extends DocSpecsSection {
  @Form([
    Field(
      'ruleType',
      String,
      'Rule Type (Required, Pattern, Range, Length, Custom, CrossField)',
      required: true,
      hint: 'Required, Pattern, Range, Length, Custom, or CrossField',
    ),
    Field(
      'ruleExpression',
      String,
      'Rule Expression / Formula',
      hint: 'Expression or formula implementing the rule',
    ),
    Field(
      'errorCode',
      String,
      'Error Code',
      hint:
          'The error code emitted on failure — reference into the error-code '
          'registry (ERCRG / ErrorCodeEntry.code), shared with CE-ER and CE-TX',
      refersTo: ['ERCEN.code'],
    ),
    Field(
      'errorMessage',
      String,
      'Error Message',
      required: true,
      hint: 'Message shown when the rule fails',
    ),
    Field(
      'severity',
      String,
      'Severity (Error, Warning, Info)',
      hint: 'Error, Warning, or Info',
    ),
    Field(
      'triggerEvent',
      String,
      'Trigger Event (OnBlur, OnChange, OnSubmit)',
      hint: 'OnBlur, OnChange, or OnSubmit',
    ),
  ])
  @override
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
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.serverCall, CodeSpecPart.navigation],
  note:
      'CE-AC/CE-SC/CE-NV — a screen action: actionType (action), apiEndpoint (server call) and/or navigationTarget (screen transition)',
)
class RequirementScreenActionEntry extends DocSpecsSection {
  @Form([
    Field(
      'actionId',
      String,
      'Action ID',
      required: true,
      hint: 'Unique identifier for this action',
    ),
    Field(
      'actionLabel',
      String,
      'Action Label (button text)',
      required: true,
      hint: 'Button or link text for the action',
    ),
    Field(
      'actionType',
      String,
      'Action Type (Submit, Cancel, Navigate, API Call, Dialog, '
          'Download, Print, Delete, Duplicate, Export, Import, Refresh, '
          'Save, SaveAndNew, SaveAndClose, Custom)',
      required: true,
      hint: 'Submit, Cancel, Navigate, API Call, Dialog, Save, etc.',
    ),
    Field(
      'icon',
      String,
      'Icon (Material Icon name or custom)',
      hint: 'Material Icon name or custom icon',
    ),
    Field(
      'iconPosition',
      String,
      'Icon Position (Left, Right, Only)',
      hint: 'Left, Right, or Only',
    ),
    Field(
      'buttonStyle',
      String,
      'Button Style (Primary, Secondary, Text, Outlined, Danger)',
      hint: 'Primary, Secondary, Text, Outlined, or Danger',
    ),
    Field(
      'placement',
      String,
      'Placement (Toolbar, Inline, Footer, ContextMenu, FAB)',
      hint: 'Toolbar, Inline, Footer, ContextMenu, or FAB',
    ),
    Field(
      'keyboardShortcut',
      String,
      'Keyboard Shortcut',
      hint: 'Keyboard shortcut that triggers the action',
    ),
    Field(
      'enabled',
      String,
      'Enabled (Yes, No, Conditional)',
      hint: 'Yes, No, or Conditional',
    ),
    Field(
      'enabledCondition',
      String,
      'Enabled Condition',
      hint: 'Condition under which the action is enabled',
    ),
    Field(
      'visible',
      String,
      'Visible (Yes, No, Conditional)',
      hint: 'Yes, No, or Conditional',
    ),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'Condition under which the action is visible',
    ),
    Field(
      'confirmationRequired',
      String,
      'Confirmation Required (Yes, No)',
      hint: 'Whether the action requires confirmation',
    ),
    Field(
      'confirmationMessage',
      String,
      'Confirmation Message',
      hint: 'Message shown to confirm the action',
    ),
    Field(
      'successMessage',
      String,
      'Success Message',
      hint: 'Message shown on success',
    ),
    Field(
      'errorMessage',
      String,
      'Error Message',
      hint: 'Message shown on error',
    ),
    Field(
      'navigationTarget',
      String,
      'Navigation Target (if Navigate)',
      hint: 'Destination when the action navigates',
    ),
    Field(
      'apiEndpoint',
      String,
      'API Endpoint (if API Call)',
      hint: 'API endpoint called by the action',
    ),
    Field(
      'requiredPermission',
      String,
      'Required Permission',
      hint: 'Permission required to invoke the action',
    ),
    Field(
      'auditLogging',
      String,
      'Audit Logging (Yes, No)',
      hint: 'Whether the action is audit-logged',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Action parameters — contains 0+× ActionParameterEntry.
  @StandardReferences([
    'ISO 9241-110 — dialogue principles',
    'ISO/IEC/IEEE 29148 §9.5 — UI functional requirements',
  ], 'The list of individual parameters passed to this action.')
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
@CodeSpecKind([
  CodeSpecPart.action,
], note: 'CE-AC — an input parameter binding of a screen action')
class ActionParameterEntry extends DocSpecsSection {
  @Form([
    Field(
      'parameterName',
      String,
      'Parameter Name',
      required: true,
      hint: 'Name of the parameter',
    ),
    Field(
      'sourceType',
      String,
      'Source Type (Field, Constant, Context, User)',
      required: true,
      hint: 'Field, Constant, Context, or User',
    ),
    Field(
      'sourceValue',
      String,
      'Source Value / Field ID',
      hint: 'Source value or field ID supplying the parameter',
    ),
    Field(
      'required',
      String,
      'Required (Yes, No)',
      hint: 'Whether the parameter is required',
    ),
  ])
  @override
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
@CodeSpecKind(
  [CodeSpecPart.validation],
  note:
      'CE-VA — a dynamic form behaviour (visibility/calculation/validation on trigger) realised as a form rule',
)
class ScreenBehaviorEntry extends DocSpecsSection {
  @Form([
    Field(
      'behaviorId',
      String,
      'Behavior ID',
      required: true,
      hint: 'Unique identifier for this behavior',
    ),
    Field(
      'behaviorName',
      String,
      'Behavior Name',
      required: true,
      hint: 'Short descriptive name for the behavior',
    ),
    Field(
      'behaviorType',
      String,
      'Behavior Type (ConditionalVisibility, ConditionalRequired, '
          'Calculation, CascadingSelect, AutoPopulate, CrossFieldValidation, '
          'DynamicDefault, FieldFormatting, LiveSearch, InlineEdit)',
      required: true,
      hint: 'ConditionalVisibility, Calculation, CascadingSelect, etc.',
    ),
    Field(
      'triggerEvent',
      String,
      'Trigger Event (OnLoad, OnChange, OnBlur, OnFocus, OnClick, '
          'OnSubmit, OnFieldChange)',
      hint: 'OnLoad, OnChange, OnBlur, OnFocus, OnClick, OnSubmit, etc.',
    ),
    Field(
      'triggerField',
      String,
      'Trigger Field (if field-specific)',
      hint: 'Field that triggers the behavior, if field-specific',
    ),
    Field(
      'condition',
      String,
      'Condition (when behavior applies)',
      hint: 'Condition under which the behavior applies',
    ),
    Field(
      'affectedFields',
      String,
      'Affected Fields (field IDs)',
      hint: 'Field IDs affected by the behavior',
      refersTo: ['SFE.fieldId'],
    ),
    Field(
      'action',
      String,
      'Action (Show, Hide, Enable, Disable, Calculate, Populate, Validate)',
      hint: 'Show, Hide, Enable, Disable, Calculate, Populate, or Validate',
    ),
    Field(
      'formula',
      String,
      'Formula / Expression (for calculations)',
      hint: 'Formula or expression used for calculations',
    ),
    Field(
      'description',
      String,
      'Behavior Description',
      hint: 'Description of what the behavior does',
    ),
  ])
  @override
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
@ContentHelp(
  'Identify requirements that must be implemented before or '
  'alongside this requirement.',
)
@SectionId('REQDEP')
class RequirementDependencies extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of requirement dependencies '
        'and implementation order.',
  )
  @override
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
class RequirementDependencyEntry extends DocSpecsSection {
  @Form([
    Field(
      'dependencyType',
      String,
      'Dependency Type (Prerequisite, Bidirectional, Parent-Child, '
          'Conflict, Refinement)',
      required: true,
      hint:
          'Prerequisite, Bidirectional, Parent-Child, Conflict, or '
          'Refinement',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Description of the dependency',
    ),
    Field(
      'impact',
      String,
      'Impact (what happens if dependency not met)',
      hint: 'What happens if the dependency is not met',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @SectionId('RQDEP-RELA-REF')
  @Reference('Related Requirement')
  @SerializationOrder(1)
  DocSpecsSection? relatedRequirement;
}

/// 4.3.1.n.6. Traceability.
///
/// Traceability links to goals, use cases, processes, and other artifacts.
@StandardReferences(
  ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
  'The traceability links of a requirement to goals, use cases, processes, '
  'stories, and other artifacts that maintain visibility across the lifecycle.',
)
@ContentHelp(
  'Document traceability links to maintain visibility of '
  'requirements throughout the project lifecycle.',
)
@SectionId('RT')
class RequirementTraceability extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Traceability links form.
  @SectionId('RT-TRAC')
  @Form([
    Field(
      'relatedGoals',
      String,
      'Related Business Goals (IDs)',
      hint: 'IDs of related business goals',
      refersTo: ['BGE.goalId'],
    ),
    Field(
      'relatedUseCases',
      String,
      'Related Use Cases (IDs)',
      hint: 'IDs of related use cases',
      refersTo: ['INEN.interactionId'],
    ),
    Field(
      'relatedProcesses',
      String,
      'Related Business Processes (IDs)',
      hint: 'IDs of related business processes',
      refersTo: ['PRIDN.processId'],
    ),
    Field(
      'relatedUserStories',
      String,
      'Related User Stories (if Agile)',
      hint: 'Related user stories, if using Agile',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? traceabilityForm;

  /// Linked artifacts and test coverage references.
  @SectionId('RETRAR')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
    'The artifacts a requirement is linked to — UI screens, data entities, test '
    'cases, and related documents — for coverage and traceability.',
  )
  @Form([
    Field(
      'relatedScreens',
      String,
      'Related UI Screens/Views',
      hint: 'UI screens or views related to this requirement',
    ),
    Field(
      'relatedDataEntities',
      String,
      'Related Data Entities',
      hint: 'Data entities related to this requirement',
    ),
    Field(
      'relatedTestCases',
      String,
      'Related Test Cases (IDs)',
      hint: 'IDs of test cases covering this requirement',
      refersTo: ['RQTSC.testCaseId', 'TEGOTS.testCaseId'],
    ),
    Field(
      'relatedDocuments',
      String,
      'Related Documents or Artifacts',
      hint: 'Related documents or other artifacts',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? artifacts;

  /// Implementation and deployment tracking.
  @SectionId('RETRIM')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §5.2.8 — requirements traceability'],
    'How a requirement is realised — the implementing component, its '
    'implementation status, and the deployment version that first delivers it.',
  )
  @Form([
    Field(
      'implementationComponent',
      String,
      'Implementation Component (module, service)',
      hint: 'Module or service that implements the requirement',
    ),
    Field(
      'implementationStatus',
      String,
      'Implementation Status (Not Started, In Progress, Done)',
      hint: 'Not Started, In Progress, or Done',
    ),
    Field(
      'deploymentVersion',
      String,
      'Deployment Version (first release)',
      hint: 'Version in which the requirement first ships',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? implementation;
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
class RequirementTestCases extends DocSpecsSection {
  @ContentType('description', 'Overview of test coverage for this requirement.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Test case entries — contains 0+× RequirementTestCaseEntry.
  @StandardReferences([
    'ISO/IEC/IEEE 29119 — software testing',
    'ISO/IEC/IEEE 29148 §6.5 — verification',
  ], 'The list of individual test-case entries verifying this requirement.')
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
class RequirementTestCaseEntry extends DocSpecsSection {
  @Form([
    Field(
      'testCaseId',
      String,
      'Test Case ID',
      required: true,
      hint: 'Unique identifier for the test case',
    ),
    Field(
      'testCaseName',
      String,
      'Test Case Name',
      required: true,
      hint: 'Short descriptive name for the test case',
    ),
    Field(
      'testType',
      String,
      'Test Type (Unit, Integration, System, Acceptance, UAT, Regression)',
      hint: 'Unit, Integration, System, Acceptance, UAT, or Regression',
    ),
    Field(
      'testCategory',
      String,
      'Test Category (Positive, Negative, Boundary, Error, Performance)',
      hint: 'Positive, Negative, Boundary, Error, or Performance',
    ),
    Field(
      'preconditions',
      String,
      'Preconditions',
      hint: 'Conditions that must hold before the test runs',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Test execution details.
  @SectionId('RTCEE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing',
      'ISO/IEC/IEEE 29148 §6.5 — verification',
    ],
    'The execution detail of a test case — the steps to perform, the test data '
    'used, and the expected result.',
  )
  @Form([
    Field(
      'testSteps',
      String,
      'Test Steps',
      hint: 'Ordered steps to execute the test',
    ),
    Field(
      'testData',
      String,
      'Test Data',
      hint: 'Data used when running the test',
    ),
    Field(
      'expectedResult',
      String,
      'Expected Result',
      required: true,
      hint: 'Expected outcome of the test',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? execution;

  /// Automation and prioritization details.
  @SectionId('RTCEA')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing',
      'ISO/IEC/IEEE 29148 §6.5 — verification',
    ],
    'The automation and prioritization of a test case — whether it is automated, '
    'the script that runs it, and its priority.',
  )
  @Form([
    Field(
      'automationStatus',
      String,
      'Automation Status (Automated, Manual, To Be Automated)',
      hint: 'Automated, Manual, or To Be Automated',
    ),
    Field(
      'automationScript',
      String,
      'Automation Script Reference',
      hint: 'Reference to the automation script',
    ),
    Field(
      'priority',
      String,
      'Priority (Critical, High, Medium, Low)',
      hint: 'Critical, High, Medium, or Low',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? automation;

  @SectionId('RQTSC-RELA-REF')
  @Reference('Related Acceptance Criterion')
  @SerializationOrder(3)
  DocSpecsSection? relatedCriterion;
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
@ContentHelp(
  'Technical requirements describe non-functional aspects and '
  'constraints. Each should be measurable and testable. Common categories: '
  'Performance, Scalability, Availability, Security, Maintainability.',
)
@SectionId('TR1')
class TechnicalRequirements extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Technical requirements summary form.
  @SectionId('TR1-SUMM')
  @Form([
    Field(
      'totalTechnicalRequirements',
      String,
      'Total Technical Requirements',
      hint: 'Total count of technical requirements captured',
    ),
    Field(
      'criticalCount',
      String,
      'Critical (count)',
      hint: 'Number of requirements at Critical priority',
    ),
    Field(
      'highCount',
      String,
      'High (count)',
      hint: 'Number of requirements at High priority',
    ),
    Field(
      'mediumCount',
      String,
      'Medium (count)',
      hint: 'Number of requirements at Medium priority',
    ),
    Field(
      'lowCount',
      String,
      'Low (count)',
      hint: 'Number of requirements at Low priority',
    ),
    Field(
      'architectureDrivers',
      String,
      'Architecture Drivers (top constraints shaping design)',
      hint:
          'e.g., 99.99% availability, sub-100ms latency, 10k concurrent users',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? summaryForm;

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
class TechnicalRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'requirementId',
      String,
      'Requirement ID (unique, e.g., REQ-T001)',
      required: true,
      hint: 'Stable unique identifier, e.g., REQ-T001',
    ),
    Field(
      'title',
      String,
      'Title',
      required: true,
      hint: 'Short descriptive name for the requirement',
    ),
    Field(
      'status',
      String,
      'Status (Draft, Proposed, Approved, Verified, Deferred)',
      required: true,
      hint: 'Draft, Proposed, Approved, Verified, or Deferred',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Requirement details: description, category, priority.
  @SectionId('TRED')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
      'ISO/IEC 25010 — product quality',
    ],
    'The descriptive core of a technical requirement — its statement, quality '
    'category, priority, and source.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description (The system shall... detailed statement)',
      required: true,
      hint:
          'Full requirement statement, e.g., The system shall respond '
          'within 100ms',
    ),
    Field(
      'category',
      String,
      'Category (Performance, Scalability, Availability, Reliability, '
          'Security, Usability, Accessibility, Maintainability, Portability, '
          'Interoperability, Compliance, Capacity, Recoverability)',
      required: true,
      hint: 'ISO 25010 quality characteristic the requirement addresses',
    ),
    Field(
      'subcategory',
      String,
      'Subcategory (specific aspect within category)',
      hint: 'More specific aspect, e.g., response time within Performance',
    ),
    Field(
      'priority',
      String,
      'Priority (Critical, High, Medium, Low)',
      required: true,
      hint: 'Critical, High, Medium, or Low',
    ),
    Field(
      'source',
      String,
      'Source (who requested)',
      required: true,
      hint: 'Stakeholder, document, or standard that originated it',
    ),
    Field(
      'rationale',
      String,
      'Rationale',
      hint: 'Why this requirement is needed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? details;

  /// Measurement specifications.
  @SectionId('TREM')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
      'ISO/IEC 25010 — product quality',
    ],
    'How the requirement is quantified and verified — the metric, target value, '
    'and measurement method that make it testable.',
  )
  @Form([
    Field(
      'metric',
      String,
      'Metric (what is measured)',
      hint: 'e.g., p95 response time, throughput, uptime percentage',
    ),
    Field(
      'currentValue',
      String,
      'Current Value (baseline)',
      hint: 'Present-day measured value, if known',
    ),
    Field(
      'targetValue',
      String,
      'Target Value',
      required: true,
      hint: 'Required threshold the metric must meet, e.g., < 100ms',
    ),
    Field(
      'measurementMethod',
      String,
      'Measurement Method',
      hint: 'How the metric is captured, e.g., APM instrumentation',
    ),
    Field(
      'measurementEnvironment',
      String,
      'Measurement Environment (production, staging, load test)',
      hint: 'Where measured: production, staging, or load test',
    ),
    Field(
      'measurementFrequency',
      String,
      'Measurement Frequency',
      hint: 'How often measured, e.g., continuous, per release',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? measurement;

  /// Verification approach and tools.
  @SectionId('TREV')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
      'ISO/IEC 25010 — product quality',
    ],
    'How conformance to the requirement is verified — the approach, tooling, and '
    'timing of verification.',
  )
  @Form([
    Field(
      'verificationApproach',
      String,
      'Verification Approach (how verified: test, inspection, analysis)',
      hint: 'Test, inspection, analysis, or demonstration',
    ),
    Field(
      'verificationTool',
      String,
      'Verification Tool',
      hint: 'Tool used to verify, e.g., load testing framework',
    ),
    Field(
      'verificationTiming',
      String,
      'Verification Timing (unit test, integration, acceptance, production)',
      hint: 'When verified: unit, integration, acceptance, or production',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;

  /// Impact assessment.
  @SectionId('TREI')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
      'ISO/IEC 25010 — product quality',
    ],
    'The consequences of the requirement — its effect on architecture, the '
    'effort to satisfy it, and the risk of not meeting it.',
  )
  @Form([
    Field(
      'architectureImpact',
      String,
      'Architecture Impact (how this affects system design)',
      hint: 'How satisfying this shapes the system design',
    ),
    Field(
      'estimatedEffort',
      String,
      'Estimated Implementation Effort',
      hint: 'Rough effort to implement, e.g., 2 sprints',
    ),
    Field(
      'riskIfNotMet',
      String,
      'Risk If Not Met',
      hint: 'Consequence if the requirement is not satisfied',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? impact;

  /// Assumptions and constraints.
  @SectionId('TREC')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §9.6 — performance & quality requirements',
      'ISO/IEC 25010 — product quality',
    ],
    'The assumptions the requirement relies on and the constraints it imposes or '
    'operates under.',
  )
  @Form([
    Field(
      'assumptions',
      String,
      'Assumptions',
      hint: 'Conditions assumed true for the requirement to hold',
    ),
    Field(
      'constraints',
      String,
      'Constraints',
      hint: 'Limits or boundaries that apply, e.g., fixed infrastructure',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? constraints;

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
@ContentHelp(
  'Security requirements protect confidentiality, integrity, '
  'and availability of information. Include authentication, authorization, '
  'data protection, and compliance requirements.',
)
@SectionId('SR1')
class SecurityRequirements extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Security requirements summary form.
  @SectionId('SR1-SUMM')
  @Form([
    Field(
      'totalSecurityRequirements',
      String,
      'Total Security Requirements',
      hint: 'Total count of security requirements captured',
    ),
    Field(
      'criticalCount',
      String,
      'Critical (count)',
      hint: 'Number of requirements at Critical priority',
    ),
    Field(
      'highCount',
      String,
      'High (count)',
      hint: 'Number of requirements at High priority',
    ),
    Field(
      'mediumCount',
      String,
      'Medium (count)',
      hint: 'Number of requirements at Medium priority',
    ),
    Field(
      'securityFramework',
      String,
      'Security Framework (OWASP, NIST, ISO 27001, CIS, etc.)',
      hint: 'Primary framework guiding the requirements',
    ),
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements (GDPR, HIPAA, PCI-DSS, SOX, etc.)',
      hint: 'Regulations the system must comply with',
    ),
    Field(
      'threatCategories',
      String,
      'Threat Categories Addressed (Injection, XSS, CSRF, etc.)',
      hint: 'Classes of attack the requirements mitigate',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? summaryForm;

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
class SecurityRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'requirementId',
      String,
      'Requirement ID (unique, e.g., REQ-S001)',
      required: true,
      hint: 'Stable unique identifier, e.g., REQ-S001',
    ),
    Field(
      'title',
      String,
      'Title',
      required: true,
      hint: 'Short descriptive name for the requirement',
    ),
    Field(
      'description',
      String,
      'Description (The system shall... detailed statement)',
      required: true,
      hint:
          'Full requirement statement, e.g., The system shall encrypt '
          'data at rest',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Category and classification.
  @SectionId('SEREENCL')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — security controls',
      'ISO/IEC/IEEE 29148 §9 — security requirements',
    ],
    'The classification of a security requirement — its security category, '
    'priority, source, and the threat and data classification it concerns.',
  )
  @Form([
    Field(
      'category',
      String,
      'Category (Authentication, Authorization, Data Protection, '
          'Encryption, Audit Logging, Input Validation, Session Management, '
          'Error Handling, Communication Security, Configuration, '
          'Cryptography, Data Retention, Privacy)',
      required: true,
      hint: 'Security domain the requirement falls under',
    ),
    Field(
      'subcategory',
      String,
      'Subcategory',
      hint: 'More specific aspect within the category',
    ),
    Field(
      'priority',
      String,
      'Priority (Critical, High, Medium, Low)',
      required: true,
      hint: 'Critical, High, Medium, or Low',
    ),
    Field(
      'source',
      String,
      'Source',
      required: true,
      hint: 'Stakeholder, standard, or document that originated it',
    ),
    Field(
      'rationale',
      String,
      'Rationale',
      hint: 'Why this security requirement is needed',
    ),
    Field(
      'threatMitigated',
      String,
      'Threat Mitigated (what attack is prevented)',
      hint: 'Attack or risk this requirement prevents',
    ),
    Field(
      'dataClassification',
      String,
      'Data Classification Affected (Public, Internal, Confidential, '
          'Restricted, PII, PHI)',
      hint: 'Sensitivity of data the requirement protects',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Compliance framework mapping.
  @SectionId('SEREENCO')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — security controls',
      'ISO/IEC/IEEE 29148 §9 — security requirements',
    ],
    'The mapping of a security requirement onto external frameworks — OWASP, '
    'CIS, NIST, ISO 27001, and regulatory compliance references.',
  )
  @Form([
    Field(
      'owaspCategory',
      String,
      'OWASP Category (if applicable, e.g., A01:2021 Broken Access Control)',
      hint: 'OWASP Top 10 / ASVS category, if applicable',
    ),
    Field(
      'cisControl',
      String,
      'CIS Control (if applicable)',
      hint: 'Matching CIS Control number, if applicable',
    ),
    Field(
      'nistControl',
      String,
      'NIST Control (if applicable)',
      hint: 'Matching NIST SP 800-53 control, if applicable',
    ),
    Field(
      'iso27001Control',
      String,
      'ISO 27001 Control (if applicable)',
      hint: 'Matching ISO 27001 Annex A control, if applicable',
    ),
    Field(
      'complianceReference',
      String,
      'Compliance Reference (GDPR Article, PCI-DSS requirement, etc.)',
      hint: 'Specific regulation clause, e.g., GDPR Art. 32',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? compliance;

  /// Implementation and verification.
  @SectionId('SREV')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — security controls',
      'ISO/IEC/IEEE 29148 §9 — security requirements',
    ],
    'How a security requirement is implemented and verified — the approach, '
    'verification method, and frequency.',
  )
  @Form([
    Field(
      'implementationApproach',
      String,
      'Implementation Approach',
      hint: 'How the requirement will be technically realized',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method (Penetration test, Code review, Security scan)',
      hint: 'How conformance is checked, e.g., penetration test',
    ),
    Field(
      'verificationFrequency',
      String,
      'Verification Frequency (Continuous, Release, Quarterly, Annual)',
      hint: 'How often verified: continuous, release, quarterly, annual',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;

  /// Status and ownership.
  @SectionId('SEREENST')
  @StandardReferences(
    [
      'ISO/IEC 27001 Annex A — security controls',
      'ISO/IEC/IEEE 29148 §9 — security requirements',
    ],
    'The lifecycle and ownership of a security requirement — residual risk after '
    'mitigation, the risk owner, and current status.',
  )
  @Form([
    Field(
      'residualRisk',
      String,
      'Residual Risk (after mitigation)',
      hint: 'Risk remaining once controls are applied',
    ),
    Field(
      'riskOwner',
      String,
      'Risk Owner',
      hint: 'Person or role accountable for the residual risk',
    ),
    Field(
      'status',
      String,
      'Status (Draft, Proposed, Approved, Implemented, Verified)',
      required: true,
      hint: 'Draft, Proposed, Approved, Implemented, or Verified',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? statusInfo;

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
class SecurityControls extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of security controls for this '
        'requirement.',
  )
  @override
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
  @ContentHelp(
    'Add one entry per security control implementing this '
    'requirement.',
  )
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
class SecurityControlEntry extends DocSpecsSection {
  @Form([
    Field(
      'controlId',
      String,
      'Control ID',
      required: true,
      hint: 'Stable unique identifier for the control',
    ),
    Field(
      'controlName',
      String,
      'Control Name',
      required: true,
      hint: 'Short descriptive name for the control',
    ),
    Field(
      'controlType',
      String,
      'Control Type (Preventive, Detective, Corrective, Deterrent, '
          'Compensating)',
      required: true,
      hint: 'Preventive, Detective, Corrective, Deterrent, or Compensating',
    ),
    Field(
      'implementationType',
      String,
      'Implementation Type (Technical, Administrative, Physical)',
      hint: 'Technical, Administrative, or Physical',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Control implementation details.
  @SectionId('SCEI')
  @StandardReferences(
    [
      'ISO/IEC 27002 — information security controls',
      'OWASP ASVS — security verification',
      'NIST SP 800-53 — security controls',
    ],
    'How a security control is implemented — its description, implementation '
    'details, and effective date.',
  )
  @Form([
    Field('description', String, 'Description', hint: 'What the control does'),
    Field(
      'implementationDetails',
      String,
      'Implementation Details',
      hint: 'How the control is configured or deployed',
    ),
    Field(
      'effectiveDate',
      String,
      'Effective Date',
      hint: 'Date the control becomes active',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? implementation;

  /// Testing and lifecycle status.
  @SectionId('SCEV')
  @StandardReferences(
    [
      'ISO/IEC 27002 — information security controls',
      'OWASP ASVS — security verification',
      'NIST SP 800-53 — security controls',
    ],
    'The testing and lifecycle state of a security control — its test frequency, '
    'last test, result, and current status.',
  )
  @Form([
    Field(
      'testFrequency',
      String,
      'Test Frequency',
      hint: 'How often the control is tested',
    ),
    Field(
      'lastTestDate',
      String,
      'Last Test Date',
      hint: 'Date the control was last tested',
    ),
    Field(
      'testResult',
      String,
      'Last Test Result',
      hint: 'Outcome of the most recent test',
    ),
    Field(
      'status',
      String,
      'Status (Planned, Implemented, Active, Retired)',
      hint: 'Planned, Implemented, Active, or Retired',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? verification;
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
@ContentHelp(
  'Organizational requirements describe non-technical changes '
  'needed for system success: training, process changes, role changes, '
  'support structures, and communication.',
)
@SectionId('OR')
class OrganizationalRequirements extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Organizational requirements summary form.
  @SectionId('OR-SUMM')
  @Form([
    Field(
      'totalOrgRequirements',
      String,
      'Total Organizational Requirements',
      hint: 'Total count of organizational requirements captured',
    ),
    Field(
      'trainingRequirements',
      String,
      'Training Requirements (count)',
      hint: 'Number of training-related requirements',
    ),
    Field(
      'processChangeRequirements',
      String,
      'Process Change (count)',
      hint: 'Number of process-change requirements',
    ),
    Field(
      'roleChangeRequirements',
      String,
      'Role Change (count)',
      hint: 'Number of role-change requirements',
    ),
    Field(
      'supportRequirements',
      String,
      'Support Requirements (count)',
      hint: 'Number of support-structure requirements',
    ),
    Field(
      'communicationRequirements',
      String,
      'Communication (count)',
      hint: 'Number of communication requirements',
    ),
    Field(
      'changeReadinessScore',
      String,
      'Organizational Change Readiness Score',
      hint: 'Assessed readiness of the organization to adopt the change',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? summaryForm;

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
class OrganizationalRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'requirementId',
      String,
      'Requirement ID (unique, e.g., REQ-O001)',
      required: true,
      hint: 'Stable unique identifier, e.g., REQ-O001',
    ),
    Field(
      'title',
      String,
      'Title',
      required: true,
      hint: 'Short descriptive name for the requirement',
    ),
    Field(
      'description',
      String,
      'Description (detailed statement)',
      required: true,
      hint: 'Full statement of the organizational change needed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Requirement classification and source.
  @SectionId('OREC')
  @StandardReferences(
    [
      'ISO 21500 — organizational project management',
      'BABOK v3 §10 — organizational readiness',
      'ISO/IEC/IEEE 29148 §9 — organizational requirements',
    ],
    'The classification of an organizational requirement — its change category, '
    'priority, source, and rationale.',
  )
  @Form([
    Field(
      'category',
      String,
      'Category (Training, Process Change, Role Change, Support, '
          'Communication, Policy, Governance, Culture, Staffing)',
      required: true,
      hint: 'Type of organizational change the requirement entails',
    ),
    Field(
      'subcategory',
      String,
      'Subcategory',
      hint: 'More specific aspect within the category',
    ),
    Field(
      'priority',
      String,
      'Priority (Must, Should, Could, Won\'t-This-Time)',
      required: true,
      hint: 'MoSCoW priority: Must, Should, Could, or Won\'t-This-Time',
    ),
    Field(
      'source',
      String,
      'Source',
      required: true,
      hint: 'Stakeholder or document that originated it',
    ),
    Field(
      'rationale',
      String,
      'Rationale',
      hint: 'Why this organizational change is needed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Impact and change profile.
  @SectionId('OREI')
  @StandardReferences(
    [
      'ISO 21500 — organizational project management',
      'BABOK v3 §10 — organizational readiness',
      'ISO/IEC/IEEE 29148 §9 — organizational requirements',
    ],
    'The impact profile of an organizational requirement — who is affected, the '
    'type and complexity of change, and expected resistance.',
  )
  @Form([
    Field(
      'impactedGroups',
      String,
      'Impacted Groups (departments, roles, user categories)',
      hint: 'Departments, roles, or user categories affected',
    ),
    Field(
      'impactedUserCount',
      String,
      'Estimated Impacted Users',
      hint: 'Approximate number of people affected',
    ),
    Field(
      'changeType',
      String,
      'Change Type (Behavioral, Procedural, Structural, Cultural)',
      hint: 'Behavioral, Procedural, Structural, or Cultural',
    ),
    Field(
      'changeComplexity',
      String,
      'Change Complexity (Low, Medium, High)',
      hint: 'Low, Medium, or High',
    ),
    Field(
      'resistance',
      String,
      'Expected Resistance (Low, Medium, High)',
      hint: 'Anticipated resistance: Low, Medium, or High',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? impact;

  /// Planning, ownership, and success tracking.
  @SectionId('OREP')
  @StandardReferences(
    [
      'ISO 21500 — organizational project management',
      'BABOK v3 §10 — organizational readiness',
      'ISO/IEC/IEEE 29148 §9 — organizational requirements',
    ],
    'The planning and ownership of an organizational requirement — its timeline, '
    'dependencies, owner, sponsor, success criteria, and status.',
  )
  @Form([
    Field(
      'timeline',
      String,
      'Timeline (when change must occur)',
      hint: 'When the change must be completed',
    ),
    Field(
      'dependencies',
      String,
      'Dependencies (other changes needed first)',
      hint: 'Other changes that must happen first',
    ),
    Field(
      'owner',
      String,
      'Change Owner',
      hint: 'Person or role accountable for the change',
    ),
    Field(
      'sponsor',
      String,
      'Executive Sponsor',
      hint: 'Leadership sponsor backing the change',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'How success of the change is defined',
    ),
    Field(
      'measurementMethod',
      String,
      'Measurement Method',
      hint: 'How success criteria are measured',
    ),
    Field(
      'status',
      String,
      'Status (Draft, Proposed, Approved, In Progress, Completed)',
      required: true,
      hint: 'Draft, Proposed, Approved, In Progress, or Completed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? planning;

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
@ContentHelp(
  'Define the implementation approach for this organizational '
  'change requirement.',
)
@SectionId('ORIP')
class OrgRequirementImplementationPlan extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Implementation plan form.
  @SectionId('ORIP-PLAN')
  @Form([
    Field(
      'approach',
      String,
      'Approach (Big Bang, Phased, Pilot, Parallel)',
      hint: 'Big Bang, Phased, Pilot, or Parallel rollout',
    ),
    Field(
      'phases',
      String,
      'Phases (if phased rollout)',
      hint: 'Sequence of phases, if phased',
    ),
    Field(
      'pilotGroup',
      String,
      'Pilot Group (if pilot approach)',
      hint: 'Group used for the pilot, if piloting',
    ),
    Field(
      'trainingApproach',
      String,
      'Training Approach',
      hint: 'How affected people are trained',
    ),
    Field(
      'communicationPlan',
      String,
      'Communication Plan',
      hint: 'How the change is communicated to stakeholders',
    ),
    Field(
      'supportPlan',
      String,
      'Support Plan',
      hint: 'Support provided during and after the change',
    ),
    Field(
      'rollbackPlan',
      String,
      'Rollback Plan',
      hint: 'How to revert if the change fails',
    ),
    Field(
      'resourcesNeeded',
      String,
      'Resources Needed',
      hint: 'People, tools, or budget required',
    ),
    Field(
      'budget',
      String,
      'Budget',
      hint: 'Estimated cost of the implementation',
    ),
    Field(
      'timeline',
      String,
      'Timeline',
      hint: 'Schedule for the implementation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? planForm;

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
  @ContentHelp(
    'Add one entry per implementation activity for this '
    'organizational change.',
  )
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
class OrgImplementationActivity extends DocSpecsSection {
  @Form([
    Field(
      'activityId',
      String,
      'Activity ID',
      required: true,
      hint: 'Stable unique identifier for the activity',
    ),
    Field(
      'activityName',
      String,
      'Activity Name',
      required: true,
      hint: 'Short descriptive name for the activity',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What the activity entails',
    ),
    Field(
      'owner',
      String,
      'Owner',
      hint: 'Person or role responsible for the activity',
    ),
    Field('startDate', String, 'Start Date', hint: 'Planned start date'),
    Field('endDate', String, 'End Date', hint: 'Planned completion date'),
    Field(
      'deliverable',
      String,
      'Deliverable',
      hint: 'Output produced by the activity',
    ),
    Field(
      'status',
      String,
      'Status (Planned, In Progress, Completed, Delayed)',
      hint: 'Planned, In Progress, Completed, or Delayed',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'TOGAF — migration planning & application portfolio management',
    'Gartner TIME model (Tolerate, Invest, Migrate, Eliminate) — application rationalization',
    'ISO/IEC/IEEE 29148 §6 — scope / systems to replace',
  ],
  'Captures the full portfolio of existing systems to be replaced, migrated, or '
  'decommissioned, anchoring informed replacement decisions for the project.',
)
@SectionId('SYTOR1')
@Comment('Seeds → CLA')
@MapsTo(D01CurrentLandscapeAssessment)
class SystemsToReplace extends DocSpecsSection {
  /// Overview of the systems replacement scope and strategy.
  @ContentHelp(
    'Provide executive summary of systems being replaced: '
    'portfolio count, replacement rationale, expected timeline, '
    'and overall migration approach.',
  )
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
@StandardReferences(
  [
    'TOGAF — application portfolio management',
    'Gartner TIME model (Tolerate, Invest, Migrate, Eliminate) — application rationalization',
  ],
  'Provides the structured inventory of all systems targeted for replacement, '
  'with portfolio-level metrics and prioritization sequencing.',
)
@SectionId('RI')
@DetailedIn(D01CurrentLandscapeAssessment)
class ReplacementInventory extends DocSpecsSection {
  /// Portfolio summary before listing individual systems.
  @ContentHelp(
    'Summarize the replacement portfolio: total system count, '
    'technology categories, combined user base, and overall complexity.',
  )
  @SerializationOrder(0)
  TextSection portfolioSummary = TextSection();

  /// Prioritization criteria for replacement sequencing.
  @ContentHelp(
    'Describe how replacement order is determined: business value, '
    'technical debt, risk, dependency chains, resource availability.',
  )
  @SerializationOrder(1)
  TextSection prioritizationCriteria = TextSection();

  /// Contains 0+× SystemToReplaceEntry.
  @StandardReferences(
    [
      'TOGAF — application portfolio management',
      'Gartner TIME model (Tolerate, Invest, Migrate, Eliminate) — application rationalization',
    ],
    'Lists each individual system to be replaced as a comprehensive '
    'assessment entry within the replacement portfolio.',
  )
  @SectionId('SYTORE-SYST-LST')
  @SectionIdPattern('SYTORE-SYST-xxx')
  @ContentHelp(
    'Add one entry per legacy system targeted for replacement; '
    'each entry captures its full technical, business, and migration assessment.',
  )
  @SerializationOrder(2)
  List<SystemToReplaceEntry> systems = [];
}

/// A system to replace entry (form).
///
/// Comprehensive documentation of a legacy system to be replaced, covering
/// technical assessment, business criticality, replacement strategy, and
/// migration planning. Follows Gartner's TIME (Tolerate, Invest, Migrate,
/// Eliminate) model and TOGAF application portfolio management patterns.
@StandardReferences(
  [
    'Gartner TIME model (Tolerate, Invest, Migrate, Eliminate) — application rationalization',
    'TOGAF — application portfolio management',
  ],
  'Captures the comprehensive assessment of a single legacy system — technical, '
  'business, replacement, data, and migration dimensions — for replacement decisions.',
)
@SectionId('SYTORE')
class SystemToReplaceEntry extends DocSpecsSection {
  // -------------------------------------------------------------------------
  // System Identification
  // -------------------------------------------------------------------------

  @SectionId('SYTORE-IDEN')
  @Form([
    Field(
      'systemId',
      String,
      'System ID (e.g., SYS-CRM-001)',
      required: true,
      hint: 'Stable identifier for the legacy system being replaced',
    ),
    Field(
      'systemName',
      String,
      'System Name',
      required: true,
      hint: 'Common name the organization uses for this system',
    ),
    Field(
      'officialName',
      String,
      'Official/Vendor Name',
      hint: 'Vendor/product name and edition, if a commercial system',
    ),
    Field(
      'systemDescription',
      String,
      'Description',
      hint: 'Brief description of what the system does and who uses it',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? identificationContent;

  /// Classification and ownership details.
  @SectionId('STREP')
  @StandardReferences(
    ['TOGAF — application portfolio management (classification & ownership)'],
    'Captures the system classification, application tier, and business/technical '
    'ownership used to position it within the portfolio.',
  )
  @Form([
    Field(
      'systemCategory',
      String,
      'Category (CRM, ERP, HR, Finance, etc.)',
      hint: 'Functional category of the system',
    ),
    Field(
      'applicationTier',
      String,
      'Tier (Mission Critical, Business Critical, Operational)',
      hint: 'Criticality tier of the application',
    ),
    Field(
      'businessOwner',
      String,
      'Business Owner',
      hint: 'Person or role accountable for the business function',
    ),
    Field(
      'technicalOwner',
      String,
      'Technical Owner',
      hint: 'Person or role accountable for the technical platform',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? profile;

  /// Vendor and contract status.
  @SectionId('STREV')
  @StandardReferences(
    ['TOGAF — application portfolio management (vendor & contract status)'],
    'Captures the vendor, contract status, and contract end date that constrain '
    'replacement timing and commercial decisions.',
  )
  @Form([
    Field(
      'vendorName',
      String,
      'Vendor/Provider',
      hint: 'Name of the supplying vendor or provider',
    ),
    Field(
      'contractStatus',
      String,
      'Contract Status (Active, Expired, Month-to-month)',
      hint: 'Current state of the vendor contract',
    ),
    Field(
      'contractEndDate',
      String,
      'Contract End Date',
      hint: 'Date the current contract expires',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? vendor;

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
  @StandardReferences(
    ['TOGAF — application portfolio management (integration dependencies)'],
    'Lists integrations and dependencies between this system and others, so '
    'replacement sequencing accounts for connected systems.',
  )
  @SectionId('REPSDEP-DEPE-LST')
  @SectionIdPattern('REPSDEP-DEPE-xxx')
  @ContentHelp(
    'Add one entry per integration or dependency; capture direction, '
    'criticality, and how the link will be rebuilt or eliminated.',
  )
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

/// Technical assessment for a system to replace.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality (technical assessment)',
    'TOGAF — application portfolio management',
  ],
  'Captures the technology stack, hosting, lifecycle, quality, and known '
  'technical/security issues of the system being replaced.',
)
@SectionId('SYTEAS')
class SystemTechnicalAssessment extends DocSpecsSection {
  @Form([
    Field(
      'primaryTechnology',
      String,
      'Primary Technology/Platform',
      hint: 'Core technology or platform the system runs on',
    ),
    Field(
      'technologyVersion',
      String,
      'Version',
      hint: 'Version of the primary technology',
    ),
    Field(
      'databasePlatform',
      String,
      'Database Platform',
      hint: 'Database engine and version backing the system',
    ),
    Field(
      'hostingEnvironment',
      String,
      'Hosting (On-premises, Cloud, Hybrid, SaaS)',
      hint: 'Where the system is currently hosted',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Platform and age details.
  @SectionId('STAP')
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (platform & maintainability)'],
    'Captures the operating environment, middleware, and age indicators that '
    'signal the platform obsolescence driving replacement.',
  )
  @Form([
    Field(
      'operatingSystem',
      String,
      'Operating System',
      hint: 'OS the system runs on',
    ),
    Field(
      'middlewareComponents',
      String,
      'Middleware Components',
      hint: 'Application servers, message brokers, or other middleware',
    ),
    Field(
      'deploymentDate',
      String,
      'Initial Deployment Date',
      hint: 'When the system was first put into production',
    ),
    Field(
      'systemAge',
      int,
      'System Age (Years)',
      hint: 'Age of the system in years',
    ),
    Field(
      'lastMajorUpgrade',
      String,
      'Last Major Upgrade',
      hint: 'Date or version of the most recent major upgrade',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? platform;

  /// Support and lifecycle details.
  @SectionId('STAL')
  @StandardReferences(
    [
      'TOGAF — application portfolio management (lifecycle status)',
      'ISO/IEC 25010 — product quality',
    ],
    'Captures vendor support status and end-of-support dates that bound the '
    'window in which the system must be replaced.',
  )
  @Form([
    Field(
      'vendorSupportStatus',
      String,
      'Support Status (Full, Extended, End of Life)',
      hint: 'Current vendor support level for the system',
    ),
    Field(
      'endOfSupportDate',
      String,
      'End of Support Date',
      hint: 'Date after which the vendor no longer supports the system',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? lifecycle;

  /// Technical quality indicators.
  @SectionId('STAQ')
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality (maintainability, performance, security)',
    ],
    'Captures technical-debt, performance, scalability, maintainability, and '
    'documentation quality indicators that justify replacement.',
  )
  @Form([
    Field(
      'technicalDebtRating',
      String,
      'Technical Debt (Low, Medium, High, Critical)',
      hint: 'Overall accumulated technical debt of the system',
    ),
    Field(
      'securityPosture',
      String,
      'Security Posture',
      hint: 'Overall security health of the system',
    ),
    Field(
      'performanceStatus',
      String,
      'Performance (Acceptable, Degraded, Poor)',
      hint: 'Current runtime performance state',
    ),
    Field(
      'scalabilityLimitations',
      String,
      'Scalability Limitations',
      hint: 'Known limits on scaling the system',
    ),
    Field(
      'maintainability',
      String,
      'Maintainability Rating',
      hint: 'How easily the system can be changed or maintained',
    ),
    Field(
      'documentationQuality',
      String,
      'Documentation (Complete, Partial, Outdated, Missing)',
      hint: 'Quality and completeness of system documentation',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? quality;

  /// Known technical issues and deficiencies.
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (defects & maintainability)'],
    'Lists known technical issues and deficiencies that strengthen the case '
    'for replacement and inform migration risk.',
  )
  @SectionId('KIE-KNOW-LST')
  @SectionIdPattern('KIE-KNOW-xxx')
  @ContentHelp(
    'Add one entry per significant known technical issue, defect, '
    'or deficiency affecting the system.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> knownIssues = [];

  /// Security vulnerabilities and compliance gaps.
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security (vulnerabilities & compliance gaps)',
    ],
    'Lists security vulnerabilities and compliance gaps in the system that '
    'raise replacement urgency and shape migration controls.',
  )
  @SectionId('SECUR-SECU-LST')
  @SectionIdPattern('SECUR-SECU-xxx')
  @ContentHelp(
    'Add one entry per security vulnerability or compliance gap; '
    'note severity and remediation status.',
  )
  @SerializationOrder(5)
  List<DocSpecsSection> securityConcerns = [];
}

/// Business criticality assessment.
@StandardReferences(
  [
    'Gartner TIME model (Tolerate, Invest, Migrate, Eliminate) — application rationalization',
    'TOGAF — application portfolio management (business value)',
  ],
  'Captures the business value, criticality rating, and TIME classification '
  'that drive prioritization of the system within the replacement portfolio.',
)
@SectionId('SYBUCR')
class SystemBusinessCriticality extends DocSpecsSection {
  @Form([
    Field(
      'criticalityRating',
      String,
      'Criticality (1=Mission Critical, 2=Business, 3=Operational)',
      required: true,
      hint: 'How critical the system is to business operations',
    ),
    Field(
      'businessValueScore',
      int,
      'Business Value Score (1-10)',
      hint: 'Relative business value on a 1-10 scale',
    ),
    Field(
      'timeModelClassification',
      String,
      'TIME Classification (Tolerate, Invest, Migrate, Eliminate)',
      hint: 'Gartner TIME disposition for the system',
    ),
    Field(
      'activeUsers',
      int,
      'Active Users',
      hint: 'Number of users actively using the system',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Usage scale and commercial impact.
  @SectionId('SBCO')
  @StandardReferences(
    [
      'TOGAF — application portfolio management (operational scale & revenue impact)',
    ],
    'Captures usage scale and commercial impact — concurrency, volumes, and '
    'revenue dependency — that weigh on the criticality assessment.',
  )
  @Form([
    Field(
      'peakConcurrentUsers',
      int,
      'Peak Concurrent Users',
      hint: 'Maximum simultaneous users observed',
    ),
    Field(
      'transactionVolume',
      String,
      'Transaction Volume',
      hint: 'Typical transaction throughput',
    ),
    Field(
      'dataVolume',
      String,
      'Data Volume',
      hint: 'Approximate volume of data handled',
    ),
    Field(
      'revenueImpact',
      String,
      'Revenue Impact (Direct, Indirect, None)',
      hint: 'How the system affects revenue',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? operations;

  /// Delivery and compliance constraints.
  @SectionId('SBCG')
  @StandardReferences(
    [
      'TOGAF — application portfolio management (governance constraints)',
      'ISO/IEC 27001 — information security (compliance role)',
    ],
    'Captures operational impact, compliance role, and recovery objectives that '
    'constrain how and when the system can be replaced.',
  )
  @Form([
    Field(
      'operationsImpact',
      String,
      'Operations Impact (Severe, Moderate, Minor, None)',
      hint: 'Severity of disruption if the system is unavailable',
    ),
    Field(
      'complianceRole',
      String,
      'Compliance/Regulatory Role',
      hint: 'Regulatory or compliance function the system serves',
    ),
    Field(
      'maxDowntime',
      String,
      'Max Acceptable Downtime (RTO)',
      hint: 'Maximum tolerable outage / recovery time objective',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;

  /// Business units and departments using this system.
  @StandardReferences(
    ['TOGAF — application portfolio management (business usage)'],
    'Lists the business units and departments that depend on the system, '
    'quantifying organizational reach for impact planning.',
  )
  @SectionId('SBUE-BUSI-LST')
  @SectionIdPattern('SBUE-BUSI-xxx')
  @ContentHelp(
    'Add one entry per business unit using the system; note user '
    'count and dependency level.',
  )
  @SerializationOrder(3)
  List<SystemBusinessUnitEntry> businessUnits = [];

  /// Business processes supported by this system.
  @StandardReferences(
    ['TOGAF — application portfolio management (business processes)'],
    'Lists the business processes the system supports, establishing the '
    'functional footprint that the replacement must preserve.',
  )
  @SectionId('SBPE-SUPP-LST')
  @SectionIdPattern('SBPE-SUPP-xxx')
  @ContentHelp(
    'Add one entry per business process the system supports; note '
    'its role and execution frequency.',
  )
  @SerializationOrder(4)
  List<SystemBusinessProcessEntry> supportedProcesses = [];
}

/// Business unit using the system.
@StandardReferences(
  ['TOGAF — application portfolio management (business usage)'],
  'Captures a single business unit that uses the system, with its usage '
  'pattern, dependency level, and impact if the system is removed.',
)
@SectionId('SYBUUNEN')
class SystemBusinessUnitEntry extends DocSpecsSection {
  @Form([
    Field(
      'unitName',
      String,
      'Business Unit',
      required: true,
      hint: 'Name of the business unit',
    ),
    Field('userCount', int, 'User Count', hint: 'Number of users in this unit'),
    Field(
      'usagePattern',
      String,
      'Usage Pattern (Daily, Weekly, etc.)',
      hint: 'How frequently the unit uses the system',
    ),
    Field(
      'dependencyLevel',
      String,
      'Dependency Level (Primary, Secondary, Occasional)',
      hint: 'How dependent the unit is on the system',
    ),
    Field(
      'impactIfRemoved',
      String,
      'Impact if System Removed',
      hint: 'Consequence to the unit if the system is removed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Business process supported.
@StandardReferences(
  ['TOGAF — application portfolio management (business processes)'],
  'Captures a single business process the system supports, with its role and '
  'execution frequency, defining functionality the replacement must cover.',
)
@SectionId('SYBUPREN')
class SystemBusinessProcessEntry extends DocSpecsSection {
  @Form([
    Field(
      'processName',
      String,
      'Process Name',
      required: true,
      hint: 'Name of the supported business process',
    ),
    Field(
      'processId',
      String,
      'Process ID',
      hint: 'Identifier for the process if one exists',
    ),
    Field(
      'systemRole',
      String,
      'System Role (Primary, Data Source, etc.)',
      hint: 'Role the system plays in the process',
    ),
    Field(
      'automationLevel',
      String,
      'Automation Level',
      hint: 'Degree to which the process is automated',
    ),
    Field(
      'processFrequency',
      String,
      'Execution Frequency',
      hint: 'How often the process runs',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Replacement strategy details.
@StandardReferences(
  [
    'Gartner TIME model (Tolerate, Invest, Migrate, Eliminate) — application rationalization',
    'TOGAF — migration planning',
  ],
  'Captures the chosen replacement strategy, target solution, timeline, '
  'cutover approach, phases, and success criteria for the system.',
)
@SectionId('SYREST')
class SystemReplacementStrategy extends DocSpecsSection {
  @Form([
    Field(
      'strategyType',
      String,
      'Strategy (Replace, Consolidate, Retire, Rehost, Replatform)',
      required: true,
      hint: 'Disposition strategy chosen for the system',
    ),
    Field(
      'strategyRationale',
      String,
      'Rationale',
      hint: 'Why this strategy was selected',
    ),
    Field(
      'targetSolution',
      String,
      'Target Solution',
      hint: 'The system or platform replacing this one',
    ),
    Field(
      'targetSolutionType',
      String,
      'Target Type (COTS, SaaS, Custom, Platform)',
      hint: 'Category of the target solution',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Replacement timeline milestones.
  @SectionId('SRST')
  @StandardReferences(
    [
      'TOGAF — migration planning (timeline & milestones)',
      'PMBOK — schedule management',
    ],
    'Captures the key replacement timeline milestones — start, cutover, '
    'decommission, and parallel-run period — for the system.',
  )
  @Form([
    Field(
      'plannedStartDate',
      String,
      'Planned Start Date',
      hint: 'When replacement work is scheduled to begin',
    ),
    Field(
      'targetCutoverDate',
      String,
      'Target Cutover Date',
      hint: 'Planned date to switch over to the new system',
    ),
    Field(
      'decommissionDate',
      String,
      'Decommission Date',
      hint: 'When the old system will be retired',
    ),
    Field(
      'parallelRunPeriod',
      String,
      'Parallel Run Period',
      hint: 'How long old and new systems run side by side',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? timeline;

  /// Cutover and rollback profile.
  @SectionId('SRSC')
  @StandardReferences(
    ['TOGAF — migration planning (cutover & rollback)'],
    'Captures the cutover approach and rollback capability that govern how the '
    'switch to the replacement is executed and reversed if needed.',
  )
  @Form([
    Field(
      'cutoverStrategy',
      String,
      'Cutover (Big Bang, Phased, Parallel Run, Pilot)',
      hint: 'How the switchover to the new system is performed',
    ),
    Field(
      'rollbackCapability',
      String,
      'Rollback Capability (Full, Partial)',
      hint: 'Extent to which the cutover can be reversed',
    ),
    Field(
      'rollbackWindow',
      String,
      'Rollback Window',
      hint: 'Time window during which rollback remains possible',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? cutover;

  /// Replacement phases if phased approach.
  @StandardReferences(
    ['TOGAF — migration planning (phased transition)'],
    'Lists the phases of a phased replacement approach, sequencing scope and '
    'exit criteria across the transition.',
  )
  @SectionId('REPPHS-PHAS-LST')
  @SectionIdPattern('REPPHS-PHAS-xxx')
  @ContentHelp(
    'Add one entry per replacement phase; capture scope, dates, and '
    'exit criteria for each.',
  )
  @SerializationOrder(3)
  List<ReplacementPhaseEntry> phases = [];

  /// Predecessor systems that must be addressed first.
  @StandardReferences(
    ['TOGAF — migration planning (dependency sequencing)'],
    'Lists predecessor systems that must be addressed before this one, '
    'capturing sequencing constraints in the replacement roadmap.',
  )
  @SectionId('PREDE-PRED-LST')
  @SectionIdPattern('PREDE-PRED-xxx')
  @ContentHelp(
    'Add one entry per predecessor system that must be replaced or '
    'addressed before this system can proceed.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> predecessorDependencies = [];

  /// Success criteria for replacement completion.
  @ContentHelp(
    'Describe the measurable criteria that confirm the replacement '
    'is complete and successful.',
  )
  @SerializationOrder(5)
  TextSection successCriteria = TextSection();
}

/// A replacement phase entry.
@StandardReferences(
  ['TOGAF — migration planning (phased transition)'],
  'Captures a single phase of a phased replacement, with its scope, dates, and '
  'exit criteria within the transition sequence.',
)
@SectionId('REPPHS')
class ReplacementPhaseEntry extends DocSpecsSection {
  @Form([
    Field(
      'phaseNumber',
      int,
      'Phase Number',
      required: true,
      hint: 'Ordinal position of the phase',
    ),
    Field(
      'phaseName',
      String,
      'Phase Name',
      required: true,
      hint: 'Descriptive name for the phase',
    ),
    Field('phaseScope', String, 'Scope', hint: 'What this phase covers'),
    Field('startDate', String, 'Start Date', hint: 'When the phase begins'),
    Field('endDate', String, 'End Date', hint: 'When the phase ends'),
    Field(
      'exitCriteria',
      String,
      'Exit Criteria',
      hint: 'Conditions that mark the phase complete',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Data scope and migration assessment.
@StandardReferences(
  ['DAMA-DMBOK2 — data migration', 'TOGAF — migration planning (data scope)'],
  'Captures the volume, sensitivity, quality, and entity scope of the data '
  'that must be migrated when the system is replaced.',
)
@SectionId('SYDASC')
class SystemDataScope extends DocSpecsSection {
  @Form([
    Field(
      'totalRecords',
      String,
      'Total Records',
      hint: 'Approximate total number of records',
    ),
    Field(
      'dataSize',
      String,
      'Data Size (GB/TB)',
      hint: 'Total size of the data set',
    ),
    Field(
      'growthRate',
      String,
      'Growth Rate',
      hint: 'Rate at which the data grows',
    ),
    Field(
      'dataTypes',
      String,
      'Data Types (Master, Transactional, etc.)',
      hint: 'Categories of data the system holds',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data sensitivity and quality posture.
  @SectionId('SDSG')
  @StandardReferences(
    [
      'DAMA-DMBOK2 — data governance & quality',
      'ISO/IEC 27001 — information security (data sensitivity)',
    ],
    'Captures data sensitivity, retention requirements, and quality posture that '
    'govern how the data must be handled during migration.',
  )
  @Form([
    Field(
      'sensitivityLevel',
      String,
      'Sensitivity (Public, Internal, Confidential, PII)',
      hint: 'Confidentiality classification of the data',
    ),
    Field(
      'retentionRequirements',
      String,
      'Retention Requirements',
      hint: 'Legal or policy retention obligations',
    ),
    Field(
      'dataQuality',
      String,
      'Quality Rating (Excellent to Poor)',
      hint: 'Overall quality of the data',
    ),
    Field(
      'cleansingRequired',
      String,
      'Cleansing Required',
      hint: 'Whether and what data cleansing is needed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Migration preparation and archive handling.
  @SectionId('SYDASCMI')
  @StandardReferences(
    ['DAMA-DMBOK2 — data migration (preparation & archiving)'],
    'Captures migration preparation choices — deduplication, transformation '
    'complexity, scope, and archive strategy — for the system data.',
  )
  @Form([
    Field(
      'deduplicationNeeded',
      bool,
      'Deduplication Needed',
      hint: 'Whether duplicate records must be removed',
    ),
    Field(
      'transformationComplexity',
      String,
      'Transformation Complexity',
      hint: 'How complex the data transformation will be',
    ),
    Field(
      'migrationScope',
      String,
      'Scope (Full, Recent, Active records, Reference)',
      hint: 'Which subset of data will be migrated',
    ),
    Field(
      'archiveStrategy',
      String,
      'Archive Strategy',
      hint: 'How non-migrated data will be archived',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? migration;

  /// Data entities to migrate.
  @StandardReferences(
    ['DAMA-DMBOK2 — data migration (entity mapping)'],
    'Lists the data entities to migrate, with target mappings and '
    'transformation notes that drive the data-migration work.',
  )
  @SectionId('DEME-ENTI-LST')
  @SectionIdPattern('DEME-ENTI-xxx')
  @ContentHelp(
    'Add one entry per data entity to migrate; capture record count, '
    'target mapping, and transformation rules.',
  )
  @SerializationOrder(3)
  List<DataEntityMigrationEntry> entities = [];

  /// Data quality issues to address.
  @StandardReferences(
    ['DAMA-DMBOK2 — data quality & migration'],
    'Lists known data-quality issues that must be cleansed or resolved before '
    'or during migration to the replacement system.',
  )
  @SectionId('KNOWN-KNOW-LST')
  @SectionIdPattern('KNOWN-KNOW-xxx')
  @ContentHelp(
    'Add one entry per data-quality issue to address; note severity '
    'and remediation approach.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> knownQualityIssues = [];
}

/// A data entity migration entry.
@StandardReferences(
  ['DAMA-DMBOK2 — data migration (entity mapping & validation)'],
  'Captures a single data entity to migrate, with its target mapping, '
  'transformation notes, and validation rules.',
)
@SectionId('DAENMIEN')
class DataEntityMigrationEntry extends DocSpecsSection {
  @Form([
    Field(
      'entityName',
      String,
      'Entity Name',
      required: true,
      hint: 'Name of the data entity',
    ),
    Field(
      'recordCount',
      String,
      'Record Count',
      hint: 'Approximate number of records for this entity',
    ),
    Field(
      'targetMapping',
      String,
      'Target Mapping',
      hint: 'Where the entity maps to in the target system',
    ),
    Field(
      'transformationNotes',
      String,
      'Transformation Notes',
      hint: 'Transformations required during migration',
    ),
    Field(
      'validationRules',
      String,
      'Validation Rules',
      hint: 'Rules to verify migrated data correctness',
    ),
    Field(
      'migrationPriority',
      String,
      'Priority',
      hint: 'Migration priority of this entity',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A system dependency entry.
///
/// Documents integrations and dependencies with other systems.
@StandardReferences(
  ['TOGAF — application portfolio management (integration dependencies)'],
  'Captures a single integration or dependency with another system, with '
  'direction, criticality, and how it will be migrated or eliminated.',
)
@SectionId('REPSDEP')
class ReplacementSystemDependencyEntry extends DocSpecsSection {
  @Form([
    Field(
      'integrationId',
      String,
      'Integration ID',
      hint: 'Identifier for the integration',
    ),
    Field(
      'connectedSystem',
      String,
      'Connected System',
      required: true,
      hint: 'The other system this one integrates with',
    ),
    Field(
      'systemStatus',
      String,
      'Status (Also being replaced, Remaining, External)',
      hint: 'Disposition of the connected system',
    ),
    Field(
      'direction',
      String,
      'Direction (Inbound, Outbound, Bidirectional)',
      hint: 'Flow direction of the integration',
    ),
    Field(
      'integrationType',
      String,
      'Type (API, File, Database, Message)',
      hint: 'Mechanism used for the integration',
    ),
    Field('protocol', String, 'Protocol', hint: 'Protocol or standard used'),
    Field(
      'dataExchanged',
      String,
      'Data Exchanged',
      hint: 'What data flows across the integration',
    ),
    Field(
      'frequency',
      String,
      'Frequency',
      hint: 'How often data is exchanged',
    ),
    Field('volume', String, 'Volume', hint: 'Volume of data exchanged'),
    Field(
      'criticality',
      String,
      'Criticality (Critical, Important)',
      hint: 'How critical the integration is',
    ),
    Field(
      'impactIfBroken',
      String,
      'Impact if Broken',
      hint: 'Consequence if the integration fails',
    ),
    Field(
      'owningSystem',
      String,
      'Integration Owner',
      hint: 'Who owns or maintains the integration',
    ),
    Field(
      'replacementMapping',
      String,
      'Replacement Mapping',
      hint: 'How the integration maps in the target state',
    ),
    Field(
      'migrationApproach',
      String,
      'Migration Approach (Rebuild, Adapt, Bridge, Eliminate)',
      hint: 'How the integration will be migrated',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// User impact assessment.
@StandardReferences(
  [
    'TOGAF — migration planning (stakeholder & change impact)',
    'PMBOK — stakeholder management',
  ],
  'Captures the scale and nature of user impact — population, change profile, '
  'training, and adoption — for the system being replaced.',
)
@SectionId('SYUSIM')
class SystemUserImpact extends DocSpecsSection {
  @Form([
    Field(
      'totalUserCount',
      int,
      'Total Users',
      hint: 'Total number of users of the system',
    ),
    Field(
      'activeUserCount',
      int,
      'Active Users (last 30 days)',
      hint: 'Users active within the last 30 days',
    ),
    Field(
      'powerUsers',
      int,
      'Power Users',
      hint: 'Number of advanced or heavy users',
    ),
    Field(
      'userLocations',
      String,
      'User Locations',
      hint: 'Geographic or organizational user locations',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// User-facing change profile.
  @SectionId('SUICP')
  @StandardReferences(
    ['PMBOK — stakeholder management (change impact)'],
    'Captures the degree of user-facing change — workflow, UI, and functionality '
    '— introduced by replacing the system.',
  )
  @Form([
    Field(
      'workflowChange',
      String,
      'Workflow Change Level',
      hint: 'How much user workflows change',
    ),
    Field(
      'uiChange',
      String,
      'UI Change Level',
      hint: 'How much the user interface changes',
    ),
    Field(
      'functionalityChange',
      String,
      'Functionality Change',
      hint: 'How much functionality changes for users',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? changeProfile;

  /// Training and enablement plan.
  @SectionId('SUIE')
  @StandardReferences(
    ['PMBOK — stakeholder management (training & enablement)'],
    'Captures the training and enablement plan needed to prepare impacted users '
    'for the replacement system.',
  )
  @Form([
    Field(
      'trainingRequired',
      String,
      'Training Required',
      hint: 'What training users will need',
    ),
    Field(
      'estimatedTrainingHours',
      int,
      'Training Hours per User',
      hint: 'Estimated training time per user',
    ),
    Field(
      'trainingApproach',
      String,
      'Training Approach',
      hint: 'How training will be delivered',
    ),
    Field(
      'trainingMaterials',
      String,
      'Materials Needed',
      hint: 'Training materials that must be produced',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? enablement;

  /// Communication and adoption support.
  @SectionId('SUIA')
  @StandardReferences(
    ['PMBOK — stakeholder management (communication & adoption)'],
    'Captures the communication plan and change-champion support that drive user '
    'adoption of the replacement system.',
  )
  @Form([
    Field(
      'communicationPlan',
      String,
      'Communication Plan',
      hint: 'How change will be communicated to users',
    ),
    Field(
      'changeChampions',
      String,
      'Change Champions',
      hint: 'People who will advocate for adoption',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? adoption;

  /// User groups requiring specific handling.
  @StandardReferences(
    ['PMBOK — stakeholder management (user groups)'],
    'Lists user groups that require specific handling during replacement, '
    'capturing impact level and tailored change considerations.',
  )
  @SectionId('UGIE-USER-LST')
  @SectionIdPattern('UGIE-USER-xxx')
  @ContentHelp(
    'Add one entry per user group needing special handling; note '
    'impact level and special considerations.',
  )
  @SerializationOrder(4)
  List<UserGroupImpactEntry> userGroups = [];
}

/// User group impact entry.
@StandardReferences(
  ['PMBOK — stakeholder management (user groups)'],
  'Captures a single user group, its impact level, and the special handling or '
  'training it requires during the replacement.',
)
@SectionId('USGRIMEN')
class UserGroupImpactEntry extends DocSpecsSection {
  @Form([
    Field(
      'groupName',
      String,
      'User Group',
      required: true,
      hint: 'Name of the user group',
    ),
    Field('userCount', int, 'User Count', hint: 'Number of users in the group'),
    Field(
      'impactLevel',
      String,
      'Impact Level (High, Medium, Low)',
      hint: 'How strongly the group is impacted',
    ),
    Field(
      'specialConsiderations',
      String,
      'Special Considerations',
      hint: 'Any special handling the group needs',
    ),
    Field(
      'trainingNeeds',
      String,
      'Training Needs',
      hint: 'Training specific to this group',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Cost analysis for replacement.
@StandardReferences(
  ['PMBOK — cost management', 'TOGAF — migration planning (cost/benefit)'],
  'Captures the financial case for replacement — current costs, migration '
  'investment, target-state cost, and ROI — driving the decision.',
)
@SectionId('SYCOAN')
class SystemCostAnalysis extends DocSpecsSection {
  @Form([
    Field(
      'annualLicenseCost',
      String,
      'Annual License Cost',
      hint: 'Yearly licensing cost of the current system',
    ),
    Field(
      'annualMaintenanceCost',
      String,
      'Annual Maintenance Cost',
      hint: 'Yearly maintenance cost of the current system',
    ),
    Field(
      'annualOperationsCost',
      String,
      'Annual Operations Cost',
      hint: 'Yearly operational cost of running the system',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Current-state support and total annual cost.
  @SectionId('SCACC')
  @StandardReferences(
    ['PMBOK — cost management (current-state baseline)'],
    'Captures the current-state support cost and total annual cost that form the '
    'baseline for the replacement business case.',
  )
  @Form([
    Field(
      'annualSupportCost',
      String,
      'Annual Support Cost',
      hint: 'Yearly support cost of the current system',
    ),
    Field(
      'totalCurrentAnnualCost',
      String,
      'Total Current Annual Cost',
      hint: 'Total yearly cost of operating the current system',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? currentCosts;

  /// One-time migration and transition investments.
  @SectionId('SCAM')
  @StandardReferences(
    ['PMBOK — cost management (project & transition costs)'],
    'Captures the one-time migration and transition investments — project, data, '
    'integration, training, and parallel-run costs — for the replacement.',
  )
  @Form([
    Field(
      'migrationProjectCost',
      String,
      'Migration Project Cost',
      hint: 'Cost of the migration project itself',
    ),
    Field(
      'dataConversionCost',
      String,
      'Data Conversion Cost',
      hint: 'Cost to convert and migrate data',
    ),
    Field(
      'integrationCost',
      String,
      'Integration Rebuild Cost',
      hint: 'Cost to rebuild integrations',
    ),
    Field(
      'trainingCost',
      String,
      'Training Cost',
      hint: 'Cost of user training',
    ),
    Field(
      'parallelRunCost',
      String,
      'Parallel Run Cost',
      hint: 'Cost of running old and new systems together',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? migration;

  /// Target-state cost and ROI indicators.
  @SectionId('SCAB')
  @StandardReferences(
    ['PMBOK — cost management (ROI & TCO)'],
    'Captures target-state cost and ROI indicators — annual savings, payback '
    'period, and five-year TCO — that justify the replacement.',
  )
  @Form([
    Field(
      'newSystemAnnualCost',
      String,
      'New System Annual Cost',
      hint: 'Expected yearly cost of the replacement system',
    ),
    Field(
      'annualSavings',
      String,
      'Annual Savings',
      hint: 'Expected yearly savings versus the current system',
    ),
    Field(
      'paybackPeriod',
      String,
      'Payback Period',
      hint: 'Time to recoup the migration investment',
    ),
    Field(
      'fiveYearTco',
      String,
      '5-Year TCO',
      hint: 'Total cost of ownership over five years',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? benefits;

  /// Cost breakdown by category if detailed analysis available.
  @ContentHelp(
    'Provide a detailed cost breakdown by category if available, '
    'beyond the summary fields above.',
  )
  @SerializationOrder(4)
  TextSection costBreakdown = TextSection();

  /// Non-financial benefits to include in ROI.
  @StandardReferences(
    ['PMBOK — cost management (benefits realization)'],
    'Lists non-financial benefits of the replacement that complement the '
    'monetary ROI in the investment decision.',
  )
  @SectionId('NONFI-NONF-LST')
  @SectionIdPattern('NONFI-NONF-xxx')
  @ContentHelp(
    'Add one entry per non-financial benefit (e.g. risk reduction, '
    'agility) to weigh in the ROI case.',
  )
  @SerializationOrder(5)
  List<DocSpecsSection> nonFinancialBenefits = [];
}

/// Per-system migration plan.
@StandardReferences(
  ['TOGAF — migration planning', 'PMBOK — project & risk management'],
  'Captures the per-system migration plan — approach, effort, execution, '
  'cutover, risks, rollback, and validation — for the replacement.',
)
@SectionId('SYMIPL')
class SystemMigrationPlan extends DocSpecsSection {
  @Form([
    Field(
      'migrationApproach',
      String,
      'Approach (Big Bang, Phased, Parallel, Strangler)',
      hint: 'Overall migration strategy for the system',
    ),
    Field(
      'dataTransformationNeeds',
      String,
      'Data Transformation Needs',
      hint: 'Data transformations the migration requires',
    ),
    Field(
      'estimatedEffort',
      String,
      'Estimated Effort',
      hint: 'Estimated effort to complete the migration',
    ),
    Field(
      'teamSize',
      String,
      'Team Size',
      hint: 'Size of the team needed for migration',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Migration execution and validation details.
  @SectionId('SMPE')
  @StandardReferences(
    [
      'TOGAF — migration planning (execution & validation)',
      'PMBOK — quality management',
    ],
    'Captures migration execution and validation details — duration, testing, '
    'data validation, and UAT scope — for the system migration.',
  )
  @Form([
    Field(
      'duration',
      String,
      'Estimated Duration',
      hint: 'Expected duration of the migration execution',
    ),
    Field(
      'testingApproach',
      String,
      'Testing Approach',
      hint: 'How the migration will be tested',
    ),
    Field(
      'dataValidationMethod',
      String,
      'Data Validation Method',
      hint: 'How migrated data will be validated',
    ),
    Field(
      'uatScope',
      String,
      'UAT Scope',
      hint: 'Scope of user acceptance testing',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? execution;

  /// Cutover window and business fallback.
  @SectionId('SMPC')
  @StandardReferences(
    [
      'TOGAF — migration planning (cutover & contingency)',
      'PMBOK — risk management',
    ],
    'Captures the cutover window, duration, and business contingency that govern '
    'the operational switch to the replacement system.',
  )
  @Form([
    Field(
      'cutoverWindow',
      String,
      'Cutover Window',
      hint: 'Scheduled window for performing the cutover',
    ),
    Field(
      'cutoverDuration',
      String,
      'Cutover Duration',
      hint: 'How long the cutover is expected to take',
    ),
    Field(
      'businessContingency',
      String,
      'Business Contingency',
      hint: 'Business fallback if the cutover fails',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? cutover;

  /// Contains 0+× MigrationRiskEntry — per-system migration risks.
  @StandardReferences(
    ['PMBOK — risk management'],
    'Lists the migration risks specific to this system, with probability, '
    'impact, mitigation, and contingency for each.',
  )
  @SectionId('SMRE-RISK-LST')
  @SectionIdPattern('SMRE-RISK-xxx')
  @ContentHelp(
    'Add one entry per migration risk; capture probability, impact, '
    'mitigation, and contingency.',
  )
  @SerializationOrder(3)
  List<SystemMigrationRiskEntry> risks = [];

  /// Rollback strategy and procedures.
  @ContentHelp(
    'Describe the rollback strategy and procedures to revert if the '
    'migration fails.',
  )
  @SerializationOrder(4)
  TextSection rollbackStrategy = TextSection();

  /// Post-migration validation steps.
  @ContentHelp(
    'Describe the validation steps performed after migration to '
    'confirm the new system works correctly.',
  )
  @SerializationOrder(5)
  TextSection postMigrationValidation = TextSection();
}

/// A system migration risk entry.
@StandardReferences(
  ['PMBOK — risk management'],
  'Captures a single migration risk with its probability, impact, score, '
  'mitigation, contingency, and owner.',
)
@SectionId('SYMIRIEN')
class SystemMigrationRiskEntry extends DocSpecsSection {
  @Form([
    Field('riskId', String, 'Risk ID', hint: 'Identifier for the risk'),
    Field(
      'riskDescription',
      String,
      'Risk Description',
      required: true,
      hint: 'What the risk is',
    ),
    Field(
      'probability',
      String,
      'Probability (High, Medium, Low)',
      hint: 'Likelihood the risk occurs',
    ),
    Field(
      'impact',
      String,
      'Impact (High, Medium, Low)',
      hint: 'Severity if the risk occurs',
    ),
    Field(
      'riskScore',
      String,
      'Risk Score',
      hint: 'Combined probability/impact score',
    ),
    Field(
      'mitigation',
      String,
      'Mitigation Strategy',
      hint: 'How the risk will be reduced',
    ),
    Field(
      'contingency',
      String,
      'Contingency Plan',
      hint: 'Fallback if the risk materializes',
    ),
    Field(
      'owner',
      String,
      'Risk Owner',
      hint: 'Person accountable for the risk',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Knowledge transfer status.
@StandardReferences(
  [
    'TOGAF — migration planning (knowledge transfer)',
    'PMBOK — resource & knowledge management',
  ],
  'Captures documentation status, SME availability, and knowledge-capture '
  'needs so critical system knowledge survives the replacement.',
)
@SectionId('SYKNTR')
class SystemKnowledgeTransfer extends DocSpecsSection {
  @Form([
    Field(
      'technicalDocStatus',
      String,
      'Technical Doc Status (Complete, Partial, Outdated, Missing)',
      hint: 'Completeness of technical documentation',
    ),
    Field(
      'businessDocStatus',
      String,
      'Business Documentation Status',
      hint: 'Completeness of business documentation',
    ),
    Field(
      'dataDocStatus',
      String,
      'Data Documentation Status',
      hint: 'Completeness of data documentation',
    ),
    Field(
      'primarySme',
      String,
      'Primary SME',
      hint: 'Main subject-matter expert for the system',
    ),
    Field(
      'smeAvailability',
      String,
      'SME Availability (Available, Partial, Leaving)',
      hint: 'How available the SME is for transfer',
    ),
    Field(
      'smeRiskLevel',
      String,
      'SME Risk Level',
      hint: 'Risk of losing SME knowledge',
    ),
    Field(
      'backupSme',
      String,
      'Backup SME',
      hint: 'Secondary expert who can cover',
    ),
    Field(
      'knowledgeCaptureNeeded',
      bool,
      'Knowledge Capture Needed',
      hint: 'Whether knowledge must be formally captured',
    ),
    Field(
      'captureApproach',
      String,
      'Capture Approach',
      hint: 'How knowledge will be captured',
    ),
    Field(
      'captureDeadline',
      String,
      'Capture Deadline',
      hint: 'When knowledge capture must be complete',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Critical knowledge areas to preserve.
  @StandardReferences(
    ['PMBOK — resource & knowledge management'],
    'Lists the critical knowledge areas that must be preserved before the '
    'system is decommissioned and its experts disperse.',
  )
  @SectionId('CRITI-CRIT-LST')
  @SectionIdPattern('CRITI-CRIT-xxx')
  @ContentHelp(
    'Add one entry per critical knowledge area at risk of being '
    'lost when the system is retired.',
  )
  @SerializationOrder(1)
  List<DocSpecsSection> criticalKnowledgeAreas = [];

  /// Knowledge transfer plan if SME risk is high.
  @ContentHelp(
    'Describe the knowledge-transfer plan to follow when SME risk is '
    'high, so expertise is retained before cutover.',
  )
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
@StandardReferences(
  [
    'TOGAF — migration & transition planning',
    'PMBOK — schedule / risk / cost management',
    'DAMA-DMBOK2 — data migration',
  ],
  'Captures the portfolio-wide migration strategy, sequencing, resourcing, '
  'risks, and coordination that govern moving from the current landscape to '
  'the target systems.',
)
@SectionId('MIGCON')
@DetailedIn(D01CurrentLandscapeAssessment)
class MigrationConsiderations extends DocSpecsSection {
  @SectionId('MIGCON-STRA')
  @Form([
    Field(
      'overallStrategy',
      String,
      'Overall Strategy (Big Bang, Phased, Parallel, Strangler)',
      hint: 'Chosen cutover pattern for the migration program',
    ),
    Field(
      'sequencingApproach',
      String,
      'Sequencing Approach',
      hint: 'Order in which systems are migrated and why',
    ),
    Field(
      'interdependencyHandling',
      String,
      'Interdependency Handling',
      hint: 'How cross-system dependencies are coordinated',
    ),
    Field(
      'migrationWindowStrategy',
      String,
      'Migration Window Strategy',
      hint: 'When migrations run, e.g. weekends, off-hours',
    ),
    Field(
      'blackoutPeriods',
      String,
      'Blackout Periods',
      hint: 'Times when no migration activity is permitted',
    ),
    Field(
      'parallelRunDuration',
      String,
      'Parallel Run Duration',
      hint: 'How long old and new run side by side',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? strategyContent;

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
  @StandardReferences(
    [
      'TOGAF — migration & transition planning',
      'PMBOK — schedule / risk / cost management',
    ],
    'The set of program-level migration milestones marking key gates and '
    'deliverables across the transition timeline.',
  )
  @SectionId('MGMLS-MILE-LST')
  @SectionIdPattern('MGMLS-MILE-xxx')
  @ContentHelp(
    'Add one entry per program milestone, with its target date, '
    'systems included, and the success/gate criteria that must be met.',
  )
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
  @StandardReferences(
    [
      'ITIL — service transition / change enablement',
      'ISO 31000 — risk management (migration risk)',
    ],
    'The defined escalation paths and triggers used to raise migration issues '
    'to the appropriate authority during the transition.',
  )
  @SectionId('ESCAL-ESCA-LST')
  @SectionIdPattern('ESCAL-ESCA-xxx')
  @ContentHelp(
    'Add one entry per escalation procedure, describing the trigger '
    'condition, the escalation path, and the responsible decision authority.',
  )
  @SerializationOrder(11)
  List<DocSpecsSection> escalationProcedures = [];
}

/// Migration resource requirements.
@StandardReferences(
  [
    'PMBOK — schedule / risk / cost management',
    'TOGAF — migration & transition planning',
  ],
  'Captures the people, vendors, environments, and infrastructure resources '
  'required to deliver the migration program.',
)
@SectionId('MIRE')
class MigrationResources extends DocSpecsSection {
  @Form([
    Field(
      'migrationLead',
      String,
      'Migration Lead',
      hint: 'Person accountable for the migration program',
    ),
    Field(
      'technicalResources',
      String,
      'Technical Resources',
      hint: 'Engineering staff and skills needed',
    ),
    Field(
      'businessResources',
      String,
      'Business Resources',
      hint: 'Business/SME staff supporting migration',
    ),
    Field(
      'testingResources',
      String,
      'Testing Resources',
      hint: 'QA staff and test capacity required',
    ),
    Field(
      'vendorSupport',
      String,
      'Vendor Support',
      hint: 'Vendor involvement and support agreements',
    ),
    Field(
      'consultingSupport',
      String,
      'Consulting Support',
      hint: 'External consulting engagement needs',
    ),
    Field(
      'contractorNeeds',
      String,
      'Contractor Needs',
      hint: 'Temporary or contract staffing required',
    ),
    Field(
      'migrationEnvironments',
      String,
      'Migration Environments',
      hint: 'Staging/test environments for migration',
    ),
    Field(
      'dataStorageNeeds',
      String,
      'Data Storage',
      hint: 'Storage capacity required during migration',
    ),
    Field(
      'networkBandwidth',
      String,
      'Network Bandwidth',
      hint: 'Bandwidth needed for data transfer',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Resource timeline by phase.
  @SerializationOrder(1)
  TextSection resourceTimeline = TextSection();
}

/// A migration milestone entry.
@StandardReferences(
  [
    'PMBOK — schedule / risk / cost management',
    'TOGAF — migration & transition planning',
  ],
  'Captures a single program migration milestone — its target date, scope, '
  'deliverables, and the gate criteria that mark its completion.',
)
@SectionId('MGMLS')
class MigrationMilestoneEntry extends DocSpecsSection {
  @Form([
    Field(
      'milestoneName',
      String,
      'Milestone Name',
      required: true,
      hint: 'Concise name for the milestone',
    ),
    Field(
      'targetDate',
      String,
      'Target Date',
      hint: 'Planned date the milestone is reached',
    ),
    Field(
      'systemsIncluded',
      String,
      'Systems Included',
      hint: 'Systems covered by this milestone',
    ),
    Field(
      'deliverables',
      String,
      'Deliverables',
      hint: 'Outputs produced at this milestone',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'Conditions that confirm milestone success',
    ),
    Field(
      'gateName',
      String,
      'Gate Name',
      hint: 'Associated stage-gate or checkpoint',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Migration risks — program-level risks.
///
/// Comprehensive migration risk management framework for program-level
/// risks across the entire migration portfolio. Covers risk governance,
/// assessment methodology, monitoring, and escalation procedures.
/// Follows PMI risk management practices and enterprise risk frameworks.
@StandardReferences(
  [
    'ISO 31000 — risk management (migration risk)',
    'PMBOK — schedule / risk / cost management',
  ],
  'Captures the program-level migration risk management framework — '
  'governance, assessment, monitoring, response, and escalation across the '
  'entire migration portfolio.',
)
@SectionId('MIRI')
class MigrationRisks extends DocSpecsSection {
  @SectionId('MIRI-GOVE')
  @Form([
    Field(
      'riskGovernanceModel',
      String,
      'Risk Governance Model',
      hint: 'Centralized, federated, hybrid approach',
    ),
    Field(
      'riskCommitteeCharter',
      String,
      'Risk Committee Charter',
      hint: 'Mandate and remit of the risk committee',
    ),
    Field(
      'riskReviewFrequency',
      String,
      'Risk Review Frequency',
      hint: 'Weekly, bi-weekly, monthly cycles',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? governanceContent;

  /// Governance and decision authority.
  @SectionId('MIRIGO')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the governance model and decision authority for accepting, '
    'transferring, or escalating migration risks.',
  )
  @Form([
    Field(
      'riskEscalationPath',
      String,
      'Escalation Path',
      hint: 'PM → Steering Committee → Executive Sponsor',
    ),
    Field(
      'riskToleranceLevel',
      String,
      'Risk Tolerance Level',
      hint: 'Enterprise risk appetite for migration',
    ),
    Field(
      'riskDecisionAuthority',
      String,
      'Risk Decision Authority',
      hint: 'Who approves risk acceptance/transfer',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Assessment methodology settings.
  @SectionId('MIRIAS')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the methodology used to assess migration risks, including the '
    'framework, probability/impact scales, and scoring approach.',
  )
  @Form([
    Field(
      'riskAssessmentFramework',
      String,
      'Assessment Framework',
      hint: 'PMBOK, ISO 31000, COSO, custom',
    ),
    Field(
      'probabilityScale',
      String,
      'Probability Scale',
      hint: '1-5, percentage bands, qualitative',
    ),
    Field(
      'impactScale',
      String,
      'Impact Scale',
      hint: '1-5, monetary, qualitative',
    ),
    Field(
      'riskScoringMethod',
      String,
      'Risk Scoring Method',
      hint: 'P×I matrix, expected value, Monte Carlo',
    ),
    Field(
      'riskCategoryTaxonomy',
      String,
      'Risk Category Taxonomy',
      hint: 'Technical, schedule, resource, business',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? assessment;

  /// Threshold and trigger settings.
  @SectionId('MIRITH')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the score thresholds and triggers that classify migration risk '
    'severity and prompt review or escalation.',
  )
  @Form([
    Field(
      'criticalRiskThreshold',
      String,
      'Critical Risk Threshold',
      hint: 'Score ≥ X requires executive attention',
    ),
    Field(
      'highRiskThreshold',
      String,
      'High Risk Threshold',
      hint: 'Score range classified as high risk',
    ),
    Field(
      'mediumRiskThreshold',
      String,
      'Medium Risk Threshold',
      hint: 'Score range classified as medium risk',
    ),
    Field(
      'emergentRiskTriggers',
      String,
      'Emergent Risk Triggers',
      hint: 'Indicators requiring immediate risk review',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? thresholds;

  /// Reporting settings.
  @SectionId('MIRIRE')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures how migration risk status is reported — cadence, dashboards, and '
    'where the risk register is maintained.',
  )
  @Form([
    Field(
      'riskReportingCadence',
      String,
      'Reporting Cadence',
      hint: 'How often risk reports are produced',
    ),
    Field(
      'riskDashboardTools',
      String,
      'Dashboard Tools',
      hint: 'Tools for risk visualization',
    ),
    Field(
      'riskRegisterRepository',
      String,
      'Risk Register Repository',
      hint: 'Where risk register is maintained',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? reporting;

  /// Risk overview at program level.
  @ContentHelp(
    'Executive summary of migration risk landscape: '
    'critical risks, overall risk posture, trending analysis.',
  )
  @SerializationOrder(5)
  TextSection riskOverview = TextSection();

  /// Risk assessment methodology narrative.
  @ContentHelp(
    'Detailed description of risk assessment approach, '
    'including probability/impact criteria and scoring guidelines.',
  )
  @SerializationOrder(6)
  TextSection assessmentMethodology = TextSection();

  /// Risk categories and taxonomy.
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'The taxonomy of migration risk categories used to classify and organize '
    'risks across the program.',
  )
  @SectionId('RISKC-RISK-LST')
  @SectionIdPattern('RISKC-RISK-xxx')
  @ContentHelp(
    'Add one entry per risk category, naming the category and the '
    'kinds of migration risks it groups.',
  )
  @SerializationOrder(7)
  List<DocSpecsSection> riskCategories = [];

  /// Risk-based decision making criteria.
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'The decision criteria that govern how migration risks drive go/no-go and '
    'acceptance choices.',
  )
  @SectionId('RISKB-RISK-LST')
  @SectionIdPattern('RISKB-RISK-xxx')
  @ContentHelp(
    'Add one entry per risk-based decision rule, describing the '
    'threshold or criterion and the decision it triggers.',
  )
  @SerializationOrder(8)
  List<DocSpecsSection> riskBasedDecisions = [];

  /// Risk monitoring and control procedures.
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'ITIL — service transition / change enablement',
    ],
    'The procedures used to monitor and control migration risks throughout the '
    'transition.',
  )
  @SectionId('MONIT-MONI-LST')
  @SectionIdPattern('MONIT-MONI-xxx')
  @ContentHelp(
    'Add one entry per monitoring procedure, describing what is '
    'tracked, how often, and the control action taken.',
  )
  @SerializationOrder(9)
  List<DocSpecsSection> monitoringProcedures = [];

  /// Risk response strategies by category.
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'The response strategies — avoid, mitigate, transfer, accept — applied per '
    'category of migration risk.',
  )
  @SectionId('RESPO-RESP-LST')
  @SectionIdPattern('RESPO-RESP-xxx')
  @ContentHelp(
    'Add one entry per response strategy, mapping a risk category to '
    'its chosen response approach and rationale.',
  )
  @SerializationOrder(10)
  List<DocSpecsSection> responseStrategies = [];

  /// Risk aggregation and portfolio view.
  @ContentHelp(
    'How individual system risks roll up to program level, '
    'correlation analysis, compound risk assessment.',
  )
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
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'The register of individual migration risk entries that make up the '
    'program-level risk portfolio.',
  )
  @SectionId('MGRSK-ITEM-LST')
  @SectionIdPattern('MGRSK-ITEM-xxx')
  @ContentHelp(
    'Add one entry per identified migration risk, each capturing its '
    'full lifecycle from identification through resolution.',
  )
  @SerializationOrder(14)
  List<MigrationRiskEntry> items = [];
}

/// A migration risk entry (form).
///
/// Detailed migration risk documentation following enterprise risk
/// management practices. Captures full risk lifecycle from identification
/// through resolution.
@StandardReferences(
  [
    'ISO 31000 — risk management (migration risk)',
    'PMBOK — schedule / risk / cost management',
  ],
  'Captures a single migration risk across its full lifecycle — '
  'identification, probability, impact, quantification, mitigation, '
  'contingency, and tracking.',
)
@SectionId('MGRSK')
class MigrationRiskEntry extends DocSpecsSection {
  @Form([
    Field(
      'riskId',
      String,
      'Risk ID',
      required: true,
      hint: 'Unique identifier (e.g., MIG-RISK-001)',
    ),
    Field(
      'riskTitle',
      String,
      'Risk Title',
      required: true,
      hint: 'Concise risk name',
    ),
    Field(
      'riskOwner',
      String,
      'Risk Owner',
      required: true,
      hint: 'Accountable for risk management',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Risk identification details.
  @SectionId('MIRIID')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures how a migration risk was identified — its description, category, '
    'source, and the systems, phases, and workstreams it affects.',
  )
  @Form([
    Field(
      'riskDescription',
      String,
      'Risk Description',
      required: true,
      hint: 'Detailed description of the risk event',
    ),
    Field(
      'riskCategory',
      String,
      'Risk Category',
      hint: 'Technical, schedule, resource, business, regulatory',
    ),
    Field(
      'riskSubcategory',
      String,
      'Risk Subcategory',
      hint: 'More specific categorization',
    ),
    Field(
      'identifiedDate',
      String,
      'Identified Date',
      hint: 'Date the risk was first recorded',
    ),
    Field(
      'identifiedBy',
      String,
      'Identified By',
      hint: 'Person/role who identified the risk',
    ),
    Field(
      'identificationMethod',
      String,
      'Identification Method',
      hint: 'Workshop, review, incident, expert judgment',
    ),
    Field(
      'affectedSystems',
      String,
      'Affected Systems',
      hint: 'List of systems impacted',
    ),
    Field(
      'affectedPhases',
      String,
      'Affected Phases',
      hint: 'Migration phases where risk applies',
    ),
    Field(
      'affectedStreams',
      String,
      'Affected Workstreams',
      hint: 'Data, application, infrastructure, etc.',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identification;

  /// Probability assessment.
  @SectionId('MIRIPR')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the likelihood that a migration risk will occur, including its '
    'rating, numeric score, rationale, and trend.',
  )
  @Form([
    Field(
      'probabilityRating',
      String,
      'Probability Rating',
      hint:
          'Very High (>80%), High (60-80%), Medium (40-60%), Low (20-40%), Very Low (<20%)',
    ),
    Field(
      'probabilityScore',
      int,
      'Probability Score (1-5)',
      hint: 'Numeric score for calculations',
    ),
    Field(
      'probabilityRationale',
      String,
      'Probability Rationale',
      hint: 'Why this probability was assigned',
    ),
    Field(
      'probabilityTrend',
      String,
      'Probability Trend',
      hint: 'Increasing, stable, decreasing',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? probability;

  /// Impact assessment.
  @SectionId('MIRIIM')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the consequences if a migration risk materializes across schedule, '
    'cost, business, data integrity, compliance, and reputation dimensions.',
  )
  @Form([
    Field(
      'overallImpactRating',
      String,
      'Overall Impact Rating',
      hint: 'Critical, High, Medium, Low, Minimal',
    ),
    Field(
      'overallImpactScore',
      int,
      'Overall Impact Score (1-5)',
      hint: 'Numeric overall impact for calculations',
    ),
    Field(
      'scheduleImpact',
      String,
      'Schedule Impact',
      hint: 'Days/weeks delay if risk materializes',
    ),
    Field(
      'scheduleImpactScore',
      int,
      'Schedule Impact Score',
      hint: 'Numeric schedule impact (1-5)',
    ),
    Field(
      'costImpact',
      String,
      'Cost Impact',
      hint: 'Budget impact if risk materializes',
    ),
    Field(
      'costImpactScore',
      int,
      'Cost Impact Score',
      hint: 'Numeric cost impact (1-5)',
    ),
    Field(
      'businessImpact',
      String,
      'Business Impact',
      hint: 'Business disruption level',
    ),
    Field(
      'businessImpactScore',
      int,
      'Business Impact Score',
      hint: 'Numeric business impact (1-5)',
    ),
    Field(
      'reputationImpact',
      String,
      'Reputation Impact',
      hint: 'Customer/market perception impact',
    ),
    Field(
      'dataIntegrityImpact',
      String,
      'Data Integrity Impact',
      hint: 'Risk to data quality/completeness',
    ),
    Field(
      'complianceImpact',
      String,
      'Compliance Impact',
      hint: 'Regulatory/audit implications',
    ),
    Field(
      'impactRationale',
      String,
      'Impact Rationale',
      hint: 'Justification for impact assessment',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? impact;

  /// Risk quantification.
  @SectionId('MIRIQU')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the quantified exposure of a migration risk — its score, priority, '
    'expected monetary value, and best/worst/most-likely scenarios.',
  )
  @Form([
    Field('riskScore', int, 'Risk Score', hint: 'Probability × Impact (1-25)'),
    Field(
      'riskPriority',
      String,
      'Risk Priority',
      hint: 'Critical, High, Medium, Low',
    ),
    Field(
      'expectedMonetaryValue',
      String,
      'Expected Monetary Value (EMV)',
      hint: 'P × Cost Impact',
    ),
    Field(
      'worstCaseScenario',
      String,
      'Worst Case Scenario',
      hint: 'Maximum potential impact',
    ),
    Field(
      'bestCaseScenario',
      String,
      'Best Case Scenario',
      hint: 'Minimum impact if mitigated',
    ),
    Field(
      'mostLikelyScenario',
      String,
      'Most Likely Scenario',
      hint: 'Expected impact under typical conditions',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? quantification;

  /// Mitigation strategy.
  @SectionId('MIRIMI')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the chosen response and actions to reduce a migration risk, '
    'including ownership, cost, status, and residual exposure after mitigation.',
  )
  @Form([
    Field(
      'responseStrategy',
      String,
      'Response Strategy',
      hint: 'Avoid, mitigate, transfer, accept',
    ),
    Field(
      'mitigationDescription',
      String,
      'Mitigation Strategy',
      hint: 'Primary mitigation approach',
    ),
    Field(
      'mitigationActions',
      String,
      'Mitigation Actions',
      hint: 'Specific actions to reduce risk',
    ),
    Field(
      'mitigationOwner',
      String,
      'Mitigation Owner',
      hint: 'Responsible for mitigation execution',
    ),
    Field(
      'mitigationDueDate',
      String,
      'Mitigation Due Date',
      hint: 'Target completion date for mitigation',
    ),
    Field(
      'mitigationCost',
      String,
      'Mitigation Cost',
      hint: 'Cost to implement mitigation',
    ),
    Field(
      'mitigationStatus',
      String,
      'Mitigation Status',
      hint: 'Not started, in progress, completed',
    ),
    Field(
      'residualProbability',
      String,
      'Residual Probability',
      hint: 'Probability after mitigation',
    ),
    Field(
      'residualImpact',
      String,
      'Residual Impact',
      hint: 'Impact after mitigation',
    ),
    Field(
      'residualRiskScore',
      int,
      'Residual Risk Score',
      hint: 'Risk score after mitigation',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? mitigation;

  /// Contingency planning.
  @SectionId('MIRICO')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the fallback plan if a migration risk materializes — its trigger, '
    'owner, reserved budget, rollback steps, and recovery objectives.',
  )
  @Form([
    Field(
      'contingencyPlan',
      String,
      'Contingency Plan',
      hint: 'Actions if risk materializes',
    ),
    Field(
      'contingencyTrigger',
      String,
      'Contingency Trigger',
      hint: 'What triggers contingency execution',
    ),
    Field(
      'contingencyOwner',
      String,
      'Contingency Owner',
      hint: 'Responsible for executing the contingency',
    ),
    Field(
      'contingencyBudget',
      String,
      'Contingency Budget',
      hint: 'Reserved budget for contingency',
    ),
    Field(
      'rollbackProcedure',
      String,
      'Rollback Procedure',
      hint: 'Steps to revert if risk realized',
    ),
    Field(
      'recoveryTimeObjective',
      String,
      'Recovery Time Objective',
      hint: 'Time to recover from risk event',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? contingency;

  /// Risk indicators and monitoring.
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'The early-warning indicators and key risk indicators used to monitor '
    'whether this migration risk is materializing.',
  )
  @SectionId('MIRIIN-INDI-LST')
  @SectionIdPattern('MIRIIN-INDI-xxx')
  @ContentHelp(
    'Add one entry per indicator set, describing the metrics, '
    'thresholds, and monitoring frequency that signal the risk.',
  )
  @SerializationOrder(7)
  List<MigrationRiskIndicators> indicators = [];

  /// Ownership and tracking.
  @SectionId('MIRITR')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the ownership, status, and review cadence used to track a '
    'migration risk from open through closure.',
  )
  @Form([
    Field(
      'riskDelegate',
      String,
      'Risk Delegate',
      hint: 'Day-to-day risk monitoring',
    ),
    Field(
      'escalationContact',
      String,
      'Escalation Contact',
      hint: 'Escalation point if risk increases',
    ),
    Field(
      'status',
      String,
      'Risk Status',
      hint: 'Open, mitigating, closed, realized, transferred',
    ),
    Field('statusDate', String, 'Status Date', hint: 'Last status update'),
    Field(
      'statusNotes',
      String,
      'Status Notes',
      hint: 'Current status commentary',
    ),
    Field(
      'nextReviewDate',
      String,
      'Next Review Date',
      hint: 'When the risk is next scheduled for review',
    ),
    Field('closureDate', String, 'Closure Date', hint: 'When risk was closed'),
    Field(
      'closureReason',
      String,
      'Closure Reason',
      hint: 'Why risk was closed: mitigated, accepted, transferred, expired',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? tracking;

  /// Related items.
  @SectionId('MIRIR1')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the relationships between this migration risk and other risks, '
    'issues, requirements, decisions, and dependency chains.',
  )
  @Form([
    Field(
      'relatedRisks',
      String,
      'Related Risks',
      hint: 'Risk IDs that are correlated',
      refersTo: ['MGRSK.riskId'],
    ),
    Field(
      'relatedIssues',
      String,
      'Related Issues',
      hint: 'Issue IDs linked to this risk',
    ),
    Field(
      'relatedRequirements',
      String,
      'Related Requirements',
      hint: 'Requirements impacted by risk',
    ),
    Field(
      'relatedDecisions',
      String,
      'Related Decisions',
      hint: 'Decisions affecting this risk',
    ),
    Field(
      'dependencyChain',
      String,
      'Dependency Chain',
      hint: 'Other risks this depends on',
    ),
  ])
  @SerializationOrder(9)
  DocSpecsSection? related;

  /// History and lessons learned.
  @SectionId('MIRIHI')
  @StandardReferences(
    [
      'ISO 31000 — risk management (migration risk)',
      'PMBOK — schedule / risk / cost management',
    ],
    'Captures the change history and lessons learned for a migration risk — its '
    'past scores, status changes, and insights from handling it.',
  )
  @Form([
    Field(
      'previousScores',
      String,
      'Previous Scores',
      hint: 'History of risk scores',
    ),
    Field(
      'previousStatuses',
      String,
      'Previous Statuses',
      hint: 'Status change history',
    ),
    Field(
      'lessonsLearned',
      String,
      'Lessons Learned',
      hint: 'Insights from risk handling',
    ),
  ])
  @SerializationOrder(10)
  DocSpecsSection? history;

  /// Additional risk analysis narrative.
  @ContentHelp(
    'Extended risk analysis, scenario modeling, '
    'or historical context.',
  )
  @SerializationOrder(11)
  TextSection analysisNarrative = TextSection();

  /// Mitigation action items (detailed).
  @ContentHelp(
    'Detailed breakdown of mitigation action items '
    'with owners and deadlines.',
  )
  @SerializationOrder(12)
  TextSection mitigationDetails = TextSection();
}

/// Risk indicators and monitoring.
@StandardReferences(
  [
    'ISO 31000 — risk management (migration risk)',
    'PMBOK — schedule / risk / cost management',
  ],
  'Captures the early-warning indicators, triggers, and key risk indicators '
  'used to monitor a migration risk and its escalation thresholds.',
)
@SectionId('MIRIIN')
class MigrationRiskIndicators extends DocSpecsSection {
  @Form([
    Field(
      'earlyWarningIndicators',
      String,
      'Early Warning Indicators',
      hint: 'Signs risk is about to materialize',
    ),
    Field(
      'riskTriggers',
      String,
      'Risk Triggers',
      hint: 'Events that would realize the risk',
    ),
    Field(
      'keyRiskIndicators',
      String,
      'Key Risk Indicators (KRIs)',
      hint: 'Metrics to monitor risk',
    ),
    Field(
      'monitoringFrequency',
      String,
      'Monitoring Frequency',
      hint: 'How often KRIs are checked',
    ),
    Field(
      'thresholdValues',
      String,
      'Threshold Values',
      hint: 'Limits that trigger escalation',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'TOGAF — system context & boundary definition',
    'ISO/IEC/IEEE 29148 §6 — scope & external interfaces',
    'Enterprise Integration Patterns (EIP) — integration styles',
  ],
  'Defines the overall system boundary and scope, anchoring integration planning and preventing scope ambiguity across the project.',
)
@SectionId('SYBO')
@Comment('Seeds → IIS')
@MapsTo(D07IntegrationInterfaceSpecification)
class SystemBoundaries extends DocSpecsSection {
  /// Overview of system boundaries and scope definition approach.
  @ContentHelp(
    'Provide executive summary of system boundaries: '
    'integration count, scope philosophy, and boundary governance approach.',
  )
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
  SystemLandscapeInventory systemLandscapeInventory =
      SystemLandscapeInventory();

  /// 4.5.5. Boundary Interaction Patterns. Covers IIS-PAT.
  @StandardReferences(
    [
      'Enterprise Integration Patterns (EIP) — integration styles',
      'TOGAF — system context & boundary definition',
    ],
    'Catalogs the recurring interaction patterns at the system boundary so integrations can be designed consistently.',
  )
  @SectionId('BOINPA-BOUN-LST')
  @SectionIdPattern('BOINPA-BOUN-xxx')
  @ContentHelp(
    'List the boundary interaction patterns used across '
    'integrations: request-reply, pub-sub, event-driven, batch, etc.',
  )
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
  @StandardReferences(
    [
      'TOGAF — system context & boundary definition',
      'Enterprise Integration Patterns (EIP) — integration styles',
    ],
    'Records interactions that exist only during migration so transitional integration work is planned and later retired.',
  )
  @SectionId('MIIN-MIGR-LST')
  @SectionIdPattern('MIIN-MIGR-xxx')
  @ContentHelp(
    'List interactions specific to the migration period, '
    'including data backfills, dual-run sync, and cutover handoffs.',
  )
  @SerializationOrder(8)
  List<MigrationInteractions> migrationInteractions = [];

  /// 4.5.9. Cross-Boundary Operational Considerations.
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality (operational considerations)',
      'Enterprise Integration Patterns (EIP) — integration styles',
    ],
    'Captures operational concerns that span the system boundary, such as monitoring, capacity, and support across integrations.',
  )
  @SectionId('CBOC-OPER-LST')
  @SectionIdPattern('CBOC-OPER-xxx')
  @ContentHelp(
    'List cross-boundary operational concerns: end-to-end '
    'monitoring, capacity planning, joint support, and run-book ownership.',
  )
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
@StandardReferences(
  [
    'Enterprise Integration Patterns (EIP) — integration styles',
    'OpenAPI / AsyncAPI — API specification',
    'TOGAF — system context & boundary definition',
  ],
  'Provides the structured inventory of external system integrations that seeds the detailed Integration & Interface Specification.',
)
@SectionId('EXIN')
@DetailedIn(D07IntegrationInterfaceSpecification)
class ExternalInterfaces extends DocSpecsSection {
  /// Summary of the integration landscape.
  @ContentHelp(
    'Summarize integration portfolio: total count by category, '
    'strategic vs tactical integrations, integration platform approach.',
  )
  @SerializationOrder(0)
  TextSection integrationSummary = TextSection();

  /// Integration architecture approach.
  @ContentHelp(
    'Describe integration patterns: point-to-point vs hub, '
    'synchronous vs async, API gateway usage, message broker approach.',
  )
  @SerializationOrder(1)
  TextSection architectureApproach = TextSection();

  /// Integration governance model.
  @ContentHelp(
    'Describe integration governance: ownership model, '
    'change control process, versioning strategy, deprecation policy.',
  )
  @SerializationOrder(2)
  TextSection governanceModel = TextSection();

  /// Contains 0+× ExternalInterfaceEntry.
  @StandardReferences(
    [
      'OpenAPI / AsyncAPI — API specification',
      'Enterprise Integration Patterns (EIP) — integration styles',
    ],
    'Holds one entry per external interface, the core inventory from which integration specifications are derived.',
  )
  @SectionId('EXINEN-INTE-LST')
  @SectionIdPattern('EXINEN-INTE-xxx')
  @ContentHelp(
    'Add one entry per external system interface, each '
    'documenting identification, technical, data, security, and governance details.',
  )
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
@StandardReferences(
  [
    'OpenAPI / AsyncAPI — API specification',
    'Enterprise Integration Patterns (EIP) — integration styles',
    'ISO/IEC 27001 — information security (interface security)',
  ],
  'Comprehensively documents a single external interface across identification, technical, data, security, operational, and governance facets.',
)
@SectionId('EIE')
@CodeSpecKind(
  [CodeSpecPart.serviceUnit],
  note:
      'One external interface = the integration boundary to a single '
      'external system: a cohesive grouping of operations to/from that '
      'system (CE-SU, codespecs_mapping.md §5.1/§8). Its individual '
      'operations carry serverApi/serverCall; the interface itself is the '
      'service-unit grouping.',
)
class ExternalInterfaceEntry extends DocSpecsSection {
  // -------------------------------------------------------------------------
  // Interface Identification
  // -------------------------------------------------------------------------

  @SectionId('EIE-IDEN')
  @Form([
    Field(
      'interfaceId',
      String,
      'Interface ID (e.g., IF-PAY-001)',
      required: true,
      hint: 'Unique stable identifier for this interface',
    ),
    Field(
      'interfaceName',
      String,
      'Interface Name',
      required: true,
      hint: 'Human-readable name of the interface',
    ),
    Field(
      'externalSystem',
      String,
      'External System Name',
      required: true,
      hint: 'Name of the external system being integrated',
    ),
    Field(
      'externalSystemVendor',
      String,
      'Vendor/Provider',
      hint: 'Vendor or provider that owns the external system',
    ),
    Field(
      'interfaceCategory',
      String,
      'Category (Payment, Identity, Data, Messaging, etc.)',
      hint: 'Functional category of the interface',
    ),
    Field(
      'integrationPattern',
      String,
      'Pattern (Request-Reply, Fire-and-Forget, Pub-Sub, Event-Driven)',
      hint: 'Primary integration pattern used',
    ),
    Field(
      'priority',
      String,
      'Priority (Critical, High, Medium, Low)',
      hint: 'Relative importance of this interface',
    ),
    Field(
      'status',
      String,
      'Status (Existing, New, To be replaced)',
      hint: 'Lifecycle status of the interface',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? identificationContent;

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
@StandardReferences(
  [
    'TOGAF — system context & boundary definition',
    'ISO/IEC/IEEE 29148 §6 — scope & external interfaces',
  ],
  'Captures why the interface exists in business terms, linking the integration to value, ownership, and regulatory drivers.',
)
@SectionId('INBUCO')
class InterfaceBusinessContext extends DocSpecsSection {
  @Form([
    Field(
      'businessPurpose',
      String,
      'Business Purpose',
      hint: 'What business need this interface serves',
    ),
    Field(
      'businessValue',
      String,
      'Business Value',
      hint: 'Value delivered by the integration',
    ),
    Field(
      'businessOwner',
      String,
      'Business Owner',
      hint: 'Business stakeholder accountable for the interface',
    ),
    Field(
      'useCases',
      String,
      'Primary Use Cases',
      hint: 'Main business use cases supported',
    ),
    Field(
      'businessCriticality',
      String,
      'Criticality (Mission Critical, Business Critical, Operational)',
      hint: 'How critical the interface is to the business',
    ),
    Field(
      'revenueImpact',
      String,
      'Revenue Impact (Direct, Indirect, None)',
      hint: 'How the interface affects revenue',
    ),
    Field(
      'regulatoryDriver',
      String,
      'Regulatory/Compliance Driver',
      hint: 'Regulatory or compliance reason for the interface',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Business processes that depend on this interface.
  @StandardReferences(
    ['TOGAF — system context & boundary definition'],
    'Lists the business processes that rely on this interface so dependency and fallback impact can be assessed.',
  )
  @SectionId('IBPE-DEPE-LST')
  @SectionIdPattern('IBPE-DEPE-xxx')
  @ContentHelp(
    'List business processes that depend on this interface, '
    'noting dependency type and fallback if the interface is unavailable.',
  )
  @SerializationOrder(1)
  List<InterfaceBusinessProcessEntry> dependentProcesses = [];
}

/// Business process dependency entry.
@StandardReferences(
  ['TOGAF — system context & boundary definition'],
  'Documents a single business process dependency on the interface and how it copes when the interface is unavailable.',
)
@SectionId('INBUPREN')
class InterfaceBusinessProcessEntry extends DocSpecsSection {
  @Form([
    Field(
      'processName',
      String,
      'Process Name',
      required: true,
      hint: 'Name of the dependent business process',
    ),
    Field(
      'processId',
      String,
      'Process ID',
      hint: 'Identifier of the business process',
      refersTo: ['PRIDN.processId'],
    ),
    Field(
      'dependencyType',
      String,
      'Dependency (Critical Path, Supporting)',
      hint: 'Nature of the dependency on the interface',
    ),
    Field(
      'fallbackBehavior',
      String,
      'Fallback if Interface Unavailable',
      hint: 'Process behavior when the interface is down',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Technical specification for an interface.
@StandardReferences(
  [
    'OpenAPI / AsyncAPI — API specification',
    'Enterprise Integration Patterns (EIP) — integration styles',
  ],
  'Captures the technical mechanics of the interface: protocol, transport security, message format, and encoding.',
)
@SectionId('INTESP')
class InterfaceTechnicalSpec extends DocSpecsSection {
  @Form([
    Field(
      'protocol',
      String,
      'Protocol (REST/HTTPS, SOAP/HTTPS, gRPC, GraphQL, SFTP, etc.)',
      hint: 'Transport/application protocol used',
    ),
    Field(
      'transportSecurity',
      String,
      'Transport Security (TLS 1.2, TLS 1.3)',
      hint: 'Transport-layer security applied',
    ),
    Field(
      'messageFormat',
      String,
      'Message Format (JSON, XML, Protobuf, CSV)',
      hint: 'Serialization format of exchanged messages',
    ),
    Field(
      'encoding',
      String,
      'Character Encoding (UTF-8, etc.)',
      hint: 'Character encoding of payloads',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Directionality and messaging pattern.
  @SectionId('ITSC')
  @StandardReferences(
    ['Enterprise Integration Patterns (EIP) — integration styles'],
    'Describes the direction, initiator, style, and delivery guarantee of communication across the interface.',
  )
  @Form([
    Field(
      'direction',
      String,
      'Direction (Inbound, Outbound, Bidirectional)',
      hint: 'Flow direction relative to our system',
    ),
    Field(
      'initiator',
      String,
      'Initiator (Our System, External System)',
      hint: 'Which side initiates the exchange',
    ),
    Field(
      'communicationStyle',
      String,
      'Style (Synchronous, Asynchronous, Event-Driven)',
      hint: 'Synchronicity style of communication',
    ),
    Field(
      'deliveryGuarantee',
      String,
      'Delivery (At-most-once, At-least-once, Exactly-once)',
      hint: 'Message delivery guarantee provided',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? communication;

  /// Endpoint and documentation references.
  @SectionId('ITSE')
  @StandardReferences(
    ['OpenAPI / AsyncAPI — API specification'],
    'Records the endpoints, version, and documentation references needed to locate and call the interface.',
  )
  @Form([
    Field(
      'baseEndpoint',
      String,
      'Base URL/Endpoint',
      hint: 'Primary base URL of the interface',
    ),
    Field(
      'apiVersion',
      String,
      'API Version',
      hint: 'Version of the API consumed',
    ),
    Field(
      'documentationUrl',
      String,
      'API Documentation URL',
      hint: 'Link to the external API documentation',
    ),
    Field(
      'sandboxEndpoint',
      String,
      'Sandbox/Test Endpoint',
      hint: 'Base URL of the sandbox/test environment',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? endpoints;

  /// API operations/methods exposed or consumed.
  @StandardReferences(
    ['OpenAPI / AsyncAPI — API specification'],
    'Enumerates the API operations exposed or consumed across this interface, the basis for contract documentation.',
  )
  @SectionId('INOPEN-OPER-LST')
  @SectionIdPattern('INOPEN-OPER-xxx')
  @ContentHelp(
    'List the API operations or methods used: each with method, '
    'path, purpose, and request/response formats.',
  )
  @SerializationOrder(3)
  List<InterfaceOperationEntry> operations = [];

  /// Webhook/callback configurations if applicable.
  @SectionId('INWESP')
  @StandardReferences(
    [
      'AsyncAPI — API specification',
      'Enterprise Integration Patterns (EIP) — integration styles',
    ],
    'Specifies inbound webhook/callback handling, including endpoints, signature verification, and idempotency.',
  )
  @Form([
    Field(
      'webhooksUsed',
      bool,
      'Webhooks/Callbacks Used',
      hint: 'Whether the interface uses webhooks/callbacks',
    ),
    Field(
      'webhookEndpoint',
      String,
      'Our Webhook Endpoint',
      hint: 'Our endpoint that receives callbacks',
    ),
    Field(
      'eventTypes',
      String,
      'Event Types Received',
      hint: 'Event types delivered via webhook',
    ),
    Field(
      'signatureVerification',
      String,
      'Signature Verification Method',
      hint: 'How webhook authenticity is verified',
    ),
    Field(
      'retryPolicy',
      String,
      'External System Retry Policy',
      hint: 'External retry behavior on delivery failure',
    ),
    Field(
      'idempotencyHandling',
      String,
      'Idempotency Handling',
      hint: 'How duplicate webhook deliveries are handled',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? webhookSpec;
}

/// An operation of an **external** interface.
///
/// One operation of a third-party system the application talks to, described in
/// that system's own terms — including its transport method and path, which a
/// foreign contract genuinely has.
///
/// This is **not** where the application's own operations are declared: those
/// live in the server operation registry (SVOPR), under the
/// `codespecs_mapping.md` §7 contract that fixes the transport shape and makes
/// the operation name the sole identifier.
@StandardReferences(
  ['OpenAPI / AsyncAPI — API specification'],
  'Documents a single operation of an external interface including method, path, idempotency, and request/response formats.',
)
@SectionId('IOE')
@CodeSpecKind(
  [CodeSpecPart.serverCall],
  note:
      'CE-SC — one operation of an **external** interface: a call the '
      'application makes on a third-party system, realised as a serverCall '
      "(CsServerCall). Deliberately not a serverApi — the application's own "
      'operations are declared in the server operation registry (SVOPR), '
      'where the codespecs_mapping.md §7 contract applies. Here the foreign '
      "system's method and path are part of the contract being described.",
)
class InterfaceOperationEntry extends DocSpecsSection {
  @Form([
    Field(
      'operationId',
      String,
      'Operation ID',
      required: true,
      hint: 'Unique identifier for the operation',
    ),
    Field(
      'operationName',
      String,
      'Operation Name',
      required: true,
      hint: 'Human-readable operation name',
    ),
    Field(
      'httpMethod',
      String,
      'HTTP Method (GET, POST, PUT, DELETE, etc.)',
      hint: 'HTTP verb used by the operation',
    ),
    Field(
      'path',
      String,
      'Path/Endpoint',
      hint: 'Resource path or endpoint for the operation',
    ),
    Field('purpose', String, 'Purpose', hint: 'What the operation does'),
    Field(
      'idempotent',
      bool,
      'Idempotent',
      hint: 'Whether repeated calls have the same effect',
    ),
    Field(
      'requestFormat',
      String,
      'Request Format',
      hint: 'Format/schema of the request payload',
    ),
    Field(
      'responseFormat',
      String,
      'Response Format',
      hint: 'Format/schema of the response payload',
    ),
    Field(
      'paginationSupport',
      bool,
      'Pagination Supported',
      hint: 'Whether the operation supports pagination',
    ),
    Field(
      'filteringSupport',
      String,
      'Filtering/Query Parameters',
      hint: 'Supported filtering or query parameters',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Data specification for an interface.
@StandardReferences(
  [
    'OpenAPI / AsyncAPI — API specification',
    'ISO/IEC 27001 — information security (data sensitivity)',
  ],
  'Specifies the data exchanged over the interface: entities, sensitivity, volume, mapping, and validation.',
)
@SectionId('INDASP')
class InterfaceDataSpec extends DocSpecsSection {
  @Form([
    // Data Exchange Overview
    Field(
      'dataExchangeSummary',
      String,
      'Data Exchange Summary',
      hint: 'High-level summary of data exchanged',
    ),
    Field(
      'dataDirection',
      String,
      'Data Flow (Send, Receive, Bidirectional)',
      hint: 'Direction of data flow',
    ),
    Field(
      'dataSensitivity',
      String,
      'Sensitivity (Public, Internal, Confidential, PII/PHI)',
      hint: 'Sensitivity classification of the data',
    ),
    Field(
      'dataRetentionExternal',
      String,
      'External System Data Retention',
      hint: 'How long the external system retains the data',
    ),

    // Volume & Frequency
    Field(
      'frequency',
      String,
      'Frequency (Real-time, Near real-time, Batch, On-demand)',
      hint: 'How often data is exchanged',
    ),
    Field(
      'batchSchedule',
      String,
      'Batch Schedule (if applicable)',
      hint: 'Schedule for batch exchanges',
    ),
    Field(
      'volumePerTransaction',
      String,
      'Volume per Transaction',
      hint: 'Typical data volume per transaction',
    ),
    Field(
      'dailyVolume',
      String,
      'Expected Daily Volume',
      hint: 'Expected daily data volume',
    ),
    Field(
      'peakVolume',
      String,
      'Peak Volume',
      hint: 'Peak data volume to plan for',
    ),
    Field(
      'payloadSizeLimit',
      String,
      'Payload Size Limit',
      hint: 'Maximum allowed payload size',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data entities exchanged.
  @StandardReferences(
    ['OpenAPI / AsyncAPI — API specification'],
    'Lists the data entities exchanged with their direction, required and sensitive fields, and internal mapping.',
  )
  @SectionId('IDEE-DATA-LST')
  @SectionIdPattern('IDEE-DATA-xxx')
  @ContentHelp(
    'List each data entity exchanged, noting direction, field '
    'count, sensitive fields, and the internal entity it maps to.',
  )
  @SerializationOrder(1)
  List<InterfaceDataEntityEntry> dataEntities = [];

  /// Data mapping and transformation rules.
  @StandardReferences(
    ['Enterprise Integration Patterns (EIP) — integration styles'],
    'Captures the mapping and transformation rules applied between external and internal data representations.',
  )
  @SectionId('MAPPI-MAPP-LST')
  @SectionIdPattern('MAPPI-MAPP-xxx')
  @ContentHelp(
    'List data mapping and transformation rules between external '
    'and internal representations.',
  )
  @SerializationOrder(2)
  List<DocSpecsSection> mappingRules = [];

  /// Data validation rules.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148 §6 — scope & external interfaces'],
    'Captures the validation rules applied to exchanged data to ensure integrity at the boundary.',
  )
  @SectionId('VALID-VALI-LST')
  @SectionIdPattern('VALID-VALI-xxx')
  @ContentHelp(
    'List data validation rules applied to inbound and outbound '
    'payloads at the interface boundary.',
  )
  @SerializationOrder(3)
  List<DocSpecsSection> validationRules = [];
}

/// Data entity exchanged.
@StandardReferences(
  ['OpenAPI / AsyncAPI — API specification'],
  'Documents a single data entity exchanged over the interface and how it maps to the internal model.',
)
@SectionId('INDAENEN')
class InterfaceDataEntityEntry extends DocSpecsSection {
  @Form([
    Field(
      'entityName',
      String,
      'Entity Name',
      required: true,
      hint: 'Name of the exchanged data entity',
    ),
    Field(
      'direction',
      String,
      'Direction (Send, Receive)',
      hint: 'Whether the entity is sent or received',
    ),
    Field(
      'fieldCount',
      int,
      'Field Count',
      hint: 'Number of fields in the entity',
    ),
    Field(
      'requiredFields',
      String,
      'Required Fields',
      hint: 'Fields that must be present',
    ),
    Field(
      'sensitiveFields',
      String,
      'Sensitive Fields (PII, etc.)',
      hint: 'Fields carrying sensitive data',
    ),
    Field(
      'internalMapping',
      String,
      'Maps to Internal Entity',
      hint: 'Internal entity this maps to',
    ),
    Field(
      'transformationNeeded',
      String,
      'Transformation Required',
      hint: 'Transformation needed between formats',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Security specification for an interface.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security (for interface security)',
    'OpenAPI / AsyncAPI — API specification',
  ],
  'Specifies authentication, credential handling, and the security posture governing access to the interface.',
)
@SectionId('IS')
class InterfaceSecurity extends DocSpecsSection {
  @Form([
    Field(
      'authMethod',
      String,
      'Authentication (API Key, OAuth 2.0, mTLS, Basic, SAML, etc.)',
      hint: 'Authentication mechanism used',
    ),
    Field(
      'authDetails',
      String,
      'Authentication Details',
      hint: 'Details of the authentication setup',
    ),
    Field(
      'credentialStorage',
      String,
      'Credential Storage Method',
      hint: 'Where and how credentials are stored',
    ),
    Field(
      'credentialRotation',
      String,
      'Credential Rotation Policy',
      hint: 'How often credentials are rotated',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Authorization boundaries.
  @SectionId('INSEAU')
  @StandardReferences(
    ['ISO/IEC 27001 — information security (for interface security)'],
    'Defines the authorization model, scopes, and network restrictions controlling who may use the interface.',
  )
  @Form([
    Field(
      'authorizationModel',
      String,
      'Authorization Model',
      hint: 'Authorization model governing access',
    ),
    Field(
      'scopesPermissions',
      String,
      'Scopes/Permissions Required',
      hint: 'Scopes or permissions required to call',
    ),
    Field(
      'ipWhitelisting',
      String,
      'IP Whitelisting Required',
      hint: 'Whether IP allowlisting is enforced',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? authorization;

  /// Encryption controls.
  @SectionId('INSEEN')
  @StandardReferences(
    ['ISO/IEC 27001 — information security (for interface security)'],
    'Specifies the encryption controls protecting data in transit, at rest, and at field level for the interface.',
  )
  @Form([
    Field(
      'encryptionInTransit',
      String,
      'Encryption in Transit',
      hint: 'Encryption applied to data in transit',
    ),
    Field(
      'encryptionAtRest',
      String,
      'Encryption at Rest (if applicable)',
      hint: 'Encryption applied to data at rest',
    ),
    Field(
      'fieldLevelEncryption',
      String,
      'Field-Level Encryption',
      hint: 'Field-level encryption for sensitive data',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? encryption;

  /// Compliance and audit expectations.
  @SectionId('INSECO')
  @StandardReferences(
    ['ISO/IEC 27001 — information security (for interface security)'],
    'Captures compliance, audit-logging, and data-residency expectations the interface must satisfy.',
  )
  @Form([
    Field(
      'complianceRequirements',
      String,
      'Compliance (PCI-DSS, HIPAA, GDPR, SOC2, etc.)',
      hint: 'Compliance regimes the interface must meet',
    ),
    Field(
      'auditLogging',
      String,
      'Audit Logging Requirements',
      hint: 'Audit logging the interface must produce',
    ),
    Field(
      'dataResidency',
      String,
      'Data Residency Requirements',
      hint: 'Geographic data residency constraints',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? compliance;

  /// Security contacts and escalation.
  @SerializationOrder(4)
  TextSection securityContacts = TextSection();
}

/// Operational characteristics.
@StandardReferences(
  ['ISO/IEC 25010 — product quality (operational/performance)'],
  'Captures the operational and SLA characteristics of the interface: availability, response time, and throughput.',
)
@SectionId('INOP')
class InterfaceOperational extends DocSpecsSection {
  @Form([
    Field(
      'availabilitySla',
      String,
      'Availability SLA (e.g., 99.9%)',
      hint: 'Committed availability target',
    ),
    Field(
      'scheduledDowntime',
      String,
      'Scheduled Downtime Windows',
      hint: 'Planned maintenance windows',
    ),
    Field(
      'responseTimeSla',
      String,
      'Response Time SLA (e.g., p95 < 200ms)',
      hint: 'Committed response-time target',
    ),
    Field(
      'throughputSla',
      String,
      'Throughput SLA',
      hint: 'Committed throughput target',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Rate limiting rules.
  @SectionId('IORL')
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (operational/performance)'],
    'Specifies the rate, quota, and burst limits the interface enforces or must respect.',
  )
  @Form([
    Field(
      'rateLimits',
      String,
      'Rate Limits (requests/minute)',
      hint: 'Sustained request-rate limit',
    ),
    Field(
      'quotaLimits',
      String,
      'Quota Limits (requests/day)',
      hint: 'Longer-period quota limit',
    ),
    Field(
      'burstCapacity',
      String,
      'Burst Capacity',
      hint: 'Short-term burst allowance',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? rateLimiting;

  /// Monitoring configuration.
  @SectionId('INOPMO')
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (operational/performance)'],
    'Defines how the interface is monitored, including health checks, status pages, and alerting thresholds.',
  )
  @Form([
    Field(
      'healthCheckEndpoint',
      String,
      'Health Check Endpoint',
      hint: 'Endpoint used for health checks',
    ),
    Field(
      'statusPageUrl',
      String,
      'Status Page URL',
      hint: 'External status page for the system',
    ),
    Field(
      'monitoringApproach',
      String,
      'Monitoring Approach',
      hint: 'How the interface is monitored',
    ),
    Field(
      'alertingThresholds',
      String,
      'Alerting Thresholds',
      hint: 'Thresholds that trigger alerts',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? monitoring;

  /// Support model.
  @SectionId('INOPSU')
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (operational/performance)'],
    'Captures the support model for the interface: hours, contacts, incident process, and escalation path.',
  )
  @Form([
    Field(
      'supportHours',
      String,
      'Support Hours',
      hint: 'Hours during which support is available',
    ),
    Field(
      'supportContact',
      String,
      'Support Contact',
      hint: 'Primary support contact',
    ),
    Field(
      'incidentProcess',
      String,
      'Incident Process',
      hint: 'Process for raising incidents',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'Escalation path for unresolved issues',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? support;

  /// Operational dependencies.
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (operational/performance)'],
    'Lists the operational dependencies the interface relies on, so availability and failure impact can be reasoned about.',
  )
  @SectionId('DEPEN-DEPE-LST')
  @SectionIdPattern('DEPEN-DEPE-xxx')
  @ContentHelp(
    'List operational dependencies of the interface, such as '
    'upstream services, network paths, and shared infrastructure.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> dependencies = [];
}

/// Error handling specification.
@StandardReferences(
  [
    'Enterprise Integration Patterns (EIP) — integration styles',
    'ISO/IEC 25010 — product quality (reliability)',
  ],
  'Specifies how errors from the interface are detected, classified, and handled to keep integrations resilient.',
)
@SectionId('INERHA')
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'Per-interface structured error handling — the application-level '
      'error outcomes carried in the CE-ER Result/ErrorResult envelope '
      '(codespecs_mapping.md §7 point 3), not 5xx transport failures.',
)
class InterfaceErrorHandling extends DocSpecsSection {
  @Form([
    // Error Responses
    Field(
      'errorFormat',
      String,
      'Error Response Format',
      hint: 'Format/schema of error responses',
    ),
    Field(
      'errorCodes',
      String,
      'Error Codes Used',
      hint: 'Error codes the interface returns',
      refersTo: ['ERCEN.code'],
    ),
    Field(
      'retryableErrors',
      String,
      'Retryable Error Codes',
      hint: 'Which error codes are safe to retry',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Non-retryable errors and retry strategy.
  @SectionId('IEHR')
  @StandardReferences(
    ['Enterprise Integration Patterns (EIP) — integration styles'],
    'Defines which errors are fatal versus retryable and the retry/circuit-breaker strategy for transient failures.',
  )
  @Form([
    Field(
      'fatalErrors',
      String,
      'Fatal/Non-Retryable Errors',
      hint: 'Errors that must not be retried',
    ),
    Field(
      'retryStrategy',
      String,
      'Retry Strategy (Exponential backoff, etc.)',
      hint: 'Strategy used when retrying',
    ),
    Field(
      'maxRetries',
      int,
      'Max Retries',
      hint: 'Maximum number of retry attempts',
    ),
    Field(
      'retryInterval',
      String,
      'Retry Interval',
      hint: 'Delay between retry attempts',
    ),
    Field(
      'circuitBreakerConfig',
      String,
      'Circuit Breaker Configuration',
      hint: 'Circuit-breaker thresholds and behavior',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? retry;

  /// Fallback behavior and manual recovery.
  @SectionId('IEHF')
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (reliability)'],
    'Describes fallback and degraded-mode behavior plus manual recovery when the interface is unavailable.',
  )
  @Form([
    Field(
      'fallbackBehavior',
      String,
      'Fallback Behavior',
      hint: 'Behavior when the interface fails',
    ),
    Field(
      'degradedMode',
      String,
      'Degraded Mode Operation',
      hint: 'How the system runs in degraded mode',
    ),
    Field(
      'manualRecovery',
      String,
      'Manual Recovery Procedure',
      hint: 'Manual steps to recover from failure',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? fallback;

  /// Connection and transaction timeouts.
  @SectionId('IEHT')
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (performance efficiency)'],
    'Specifies the connection, read, and overall transaction timeouts that bound interface calls.',
  )
  @Form([
    Field(
      'connectionTimeout',
      String,
      'Connection Timeout',
      hint: 'Timeout for establishing a connection',
    ),
    Field(
      'readTimeout',
      String,
      'Read Timeout',
      hint: 'Timeout for reading a response',
    ),
    Field(
      'overallTimeout',
      String,
      'Overall Transaction Timeout',
      hint: 'Total timeout for the whole transaction',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? timeout;

  /// Error handling procedures.
  @StandardReferences(
    ['Enterprise Integration Patterns (EIP) — integration styles'],
    'Lists concrete error-handling procedures so operators know how to respond to each failure mode of the interface.',
  )
  @SectionId('ERROR-ERRO-LST')
  @SectionIdPattern('ERROR-ERRO-xxx')
  @ContentHelp(
    'List error-handling procedures for the interface, mapping '
    'error conditions to detection and recovery steps.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> errorProcedures = [];
}

/// Governance and contracts.
@StandardReferences(
  [
    'TOGAF — system context & boundary definition',
    'ISO/IEC/IEEE 29148 §6 — scope & external interfaces',
  ],
  'Captures ownership, contacts, and contractual governance that keep the interface accountable over its lifecycle.',
)
@SectionId('INGO')
class InterfaceGovernance extends DocSpecsSection {
  @Form([
    Field(
      'externalOwner',
      String,
      'External System Owner',
      hint: 'Owner on the external system side',
    ),
    Field(
      'internalOwner',
      String,
      'Internal Owner/Steward',
      hint: 'Internal owner accountable for the interface',
    ),
    Field(
      'technicalContact',
      String,
      'Technical Contact',
      hint: 'Technical point of contact',
    ),
    Field(
      'businessContact',
      String,
      'Business Contact',
      hint: 'Business point of contact',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Contract and commercial terms.
  @SectionId('INGOCO')
  @StandardReferences(
    ['TOGAF — system context & boundary definition'],
    'Records the contractual and commercial terms governing the interface, including cost model and renewal.',
  )
  @Form([
    Field(
      'contractType',
      String,
      'Contract Type (SLA, Agreement, Partnership)',
      hint: 'Type of contract in place',
    ),
    Field(
      'contractExpiry',
      String,
      'Contract Expiry Date',
      hint: 'When the contract expires',
    ),
    Field(
      'renewalTerms',
      String,
      'Renewal Terms',
      hint: 'Terms governing renewal',
    ),
    Field(
      'costModel',
      String,
      'Cost Model (Per-call, Subscription, etc.)',
      hint: 'How usage is billed',
    ),
    Field(
      'estimatedCost',
      String,
      'Estimated Monthly/Annual Cost',
      hint: 'Estimated recurring cost',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? contract;

  /// Change management expectations.
  @SectionId('INGOLI')
  @StandardReferences(
    [
      'OpenAPI / AsyncAPI — API specification',
      'TOGAF — system context & boundary definition',
    ],
    'Defines versioning, deprecation, and breaking-change policies that govern how the interface evolves.',
  )
  @Form([
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'How the interface is versioned',
    ),
    Field(
      'deprecationPolicy',
      String,
      'Deprecation Policy',
      hint: 'Policy for deprecating versions',
    ),
    Field(
      'changeNotificationLead',
      String,
      'Change Notification Lead Time',
      hint: 'Notice given before changes',
    ),
    Field(
      'breakingChangePolicy',
      String,
      'Breaking Change Policy',
      hint: 'How breaking changes are handled',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? lifecycle;

  /// Integration changelog.
  @SerializationOrder(3)
  TextSection changelog = TextSection();
}

/// Testing specification.
@StandardReferences(
  ['ISO/IEC/IEEE 29119 — software testing'],
  'Specifies how the interface is tested, including sandbox availability, test credentials, and mocking.',
)
@SectionId('INTE')
class InterfaceTesting extends DocSpecsSection {
  @Form([
    Field(
      'sandboxAvailable',
      bool,
      'Sandbox Environment Available',
      hint: 'Whether a sandbox environment exists',
    ),
    Field(
      'sandboxUrl',
      String,
      'Sandbox URL',
      hint: 'Base URL of the sandbox environment',
    ),
    Field(
      'testCredentials',
      String,
      'Test Credentials Approach',
      hint: 'How test credentials are obtained',
    ),
    Field(
      'mockAvailable',
      bool,
      'Mock/Stub Available',
      hint: 'Whether a mock or stub is available',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Test data strategy.
  @SectionId('INTEDA')
  @StandardReferences(
    ['ISO/IEC/IEEE 29119 — software testing'],
    'Defines the test-data strategy for the interface, covering synthetic data and production mirroring.',
  )
  @Form([
    Field(
      'testDataApproach',
      String,
      'Test Data Approach',
      hint: 'How test data is sourced or generated',
    ),
    Field(
      'syntheticDataSupport',
      bool,
      'Synthetic Data Supported',
      hint: 'Whether synthetic test data is supported',
    ),
    Field(
      'productionMirror',
      bool,
      'Production Data Mirroring',
      hint: 'Whether production data is mirrored for tests',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? data;

  /// Validation approach across test layers.
  @SectionId('INTEST')
  @StandardReferences(
    ['ISO/IEC/IEEE 29119 — software testing'],
    'Describes the validation approach across unit, integration, contract, E2E, and performance test layers for the interface.',
  )
  @Form([
    Field(
      'unitTestApproach',
      String,
      'Unit Test Approach',
      hint: 'Approach to unit testing the interface',
    ),
    Field(
      'integrationTestApproach',
      String,
      'Integration Test Approach',
      hint: 'Approach to integration testing',
    ),
    Field(
      'contractTestApproach',
      String,
      'Contract Test Approach',
      hint: 'Approach to contract testing',
    ),
    Field(
      'e2eTestApproach',
      String,
      'E2E Test Approach',
      hint: 'Approach to end-to-end testing',
    ),
    Field(
      'performanceTestApproach',
      String,
      'Performance Test Approach',
      hint: 'Approach to performance testing',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? strategy;

  /// Test scenarios.
  @StandardReferences(
    ['ISO/IEC/IEEE 29119 — software testing'],
    'Lists the concrete test scenarios that validate the interface across happy-path, error, and edge cases.',
  )
  @SectionId('ITSE1-TEST-LST')
  @SectionIdPattern('ITSE1-TEST-xxx')
  @ContentHelp(
    'List test scenarios for the interface, each with type, '
    'preconditions, steps, and expected result.',
  )
  @SerializationOrder(3)
  List<InterfaceTestScenarioEntry> testScenarios = [];
}

/// Test scenario entry.
@StandardReferences(
  ['ISO/IEC/IEEE 29119 — software testing'],
  'Documents a single interface test scenario with its preconditions, steps, and expected result.',
)
@SectionId('INTESCEN')
class InterfaceTestScenarioEntry extends DocSpecsSection {
  @Form([
    Field(
      'scenarioId',
      String,
      'Scenario ID',
      required: true,
      hint: 'Unique identifier for the scenario',
    ),
    Field(
      'scenarioName',
      String,
      'Scenario Name',
      required: true,
      hint: 'Human-readable scenario name',
    ),
    Field(
      'scenarioType',
      String,
      'Type (Happy Path, Error, Edge Case)',
      hint: 'Category of the test scenario',
    ),
    Field(
      'preconditions',
      String,
      'Preconditions',
      hint: 'State required before running the scenario',
    ),
    Field(
      'testSteps',
      String,
      'Test Steps',
      hint: 'Steps to execute the scenario',
    ),
    Field(
      'expectedResult',
      String,
      'Expected Result',
      hint: 'Result expected on success',
    ),
    Field(
      'automated',
      bool,
      'Automated',
      hint: 'Whether the scenario is automated',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — scope definition & assumptions/dependencies',
    'PMBOK — scope management & assumption log',
    'BABOK v3 — requirements scope & constraints',
  ],
  'Captures what the project explicitly excludes so boundaries are unambiguous and scope creep is prevented.',
)
@SectionId('OUOFSC')
@DetailedIn(D07IntegrationInterfaceSpecification)
class OutOfScope extends DocSpecsSection {
  /// Overview of scope exclusion approach.
  @ContentHelp(
    'Describe the scope philosophy and how exclusions were '
    'determined. Reference any scope workshops or decision records.',
  )
  @SerializationOrder(0)
  TextSection scopePhilosophy = TextSection();

  /// Contains 0+× OutOfScopeEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — scope definition & assumptions/dependencies',
      'PMBOK — scope management & assumption log',
    ],
    'Lists each individually excluded item so every out-of-scope decision is recorded and traceable.',
  )
  @SectionId('OOSE-ITEM-LST')
  @SectionIdPattern('OOSE-ITEM-xxx')
  @ContentHelp(
    'Each entry records one excluded feature, system, or '
    'integration along with its exclusion rationale.',
  )
  @SerializationOrder(1)
  List<OutOfScopeEntry> items = [];
}

/// An out-of-scope entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — scope definition & assumptions/dependencies',
    'PMBOK — scope management & assumption log',
  ],
  'Captures a single excluded item with its type and rationale to keep scope boundaries explicit.',
)
@SectionId('OUOFSCEN')
class OutOfScopeEntry extends DocSpecsSection {
  @Form([
    Field(
      'itemId',
      String,
      'Item ID',
      hint: 'Unique identifier for this exclusion',
    ),
    Field(
      'item',
      String,
      'Out of Scope Item',
      required: true,
      hint: 'Name of the feature, system, or integration being excluded',
    ),
    Field(
      'itemType',
      String,
      'Type (Feature, Integration, System, Process, Data)',
      hint: 'Category of the excluded item',
    ),
    Field(
      'rationale',
      String,
      'Exclusion Rationale',
      hint: 'Why this item is excluded from scope',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Decision history and future reconsideration.
  @SectionId('OOSED')
  @StandardReferences(
    [
      'PMBOK — scope management & assumption log',
      'BABOK v3 — requirements scope & constraints',
    ],
    'Records who decided to exclude the item and whether it may be reconsidered in a future phase.',
  )
  @Form([
    Field(
      'requestedBy',
      String,
      'Originally Requested By',
      hint: 'Stakeholder who originally requested this item',
    ),
    Field(
      'decisionMaker',
      String,
      'Decision Maker',
      hint: 'Person who decided to exclude the item',
    ),
    Field(
      'decisionDate',
      String,
      'Decision Date',
      hint: 'When the exclusion decision was made',
    ),
    Field(
      'futureConsideration',
      String,
      'Future Consideration (Yes, No, Maybe)',
      hint: 'Whether the item may be revisited later',
    ),
    Field(
      'targetPhase',
      String,
      'Target Phase (if future)',
      hint: 'Project phase when the item might be reconsidered',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? decision;

  /// Alternatives and inclusion risk.
  @SectionId('OOSEM')
  @StandardReferences(
    [
      'ISO 31000 — risk management (assumption risk)',
      'PMBOK — scope management & assumption log',
    ],
    'Captures workarounds for the excluded item and the risk that would arise if it were brought back into scope.',
  )
  @Form([
    Field(
      'alternativeSolution',
      String,
      'Alternative/Workaround',
      hint: 'Substitute approach for the excluded capability',
    ),
    Field(
      'riskIfIncluded',
      String,
      'Risk if Included',
      hint: 'Risk that would arise if the item were added to scope',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? mitigation;
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
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — scope definition & assumptions/dependencies',
    'ISO 31000 — risk management (assumption risk)',
    'PMBOK — scope management & assumption log',
  ],
  'Captures the assumptions the project depends on so each can be validated and tracked as a risk if it fails.',
)
@SectionId('BOAS')
@DetailedIn(D07IntegrationInterfaceSpecification)
class BoundaryAssumptions extends DocSpecsSection {
  /// Overview of assumption categories and validation approach.
  @ContentHelp(
    'Describe assumption categories, validation timeline, '
    'and impact assessment approach for assumption failures.',
  )
  @SerializationOrder(0)
  TextSection assumptionApproach = TextSection();

  /// Contains 0+× BoundaryAssumptionEntry.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — scope definition & assumptions/dependencies',
      'ISO 31000 — risk management (assumption risk)',
    ],
    'Lists each individual assumption so it can be owned, validated, and risk-assessed.',
  )
  @SectionId('BOASEN-ITEM-LST')
  @SectionIdPattern('BOASEN-ITEM-xxx')
  @ContentHelp(
    'Each entry records one assumption with its category, '
    'validation status, and risk if proven incorrect.',
  )
  @SerializationOrder(1)
  List<BoundaryAssumptionEntry> items = [];
}

/// A boundary assumption entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — scope definition & assumptions/dependencies',
    'ISO 31000 — risk management (assumption risk)',
  ],
  'Captures a single assumption with its category so it can be tracked and validated independently.',
)
@SectionId('BAE')
class BoundaryAssumptionEntry extends DocSpecsSection {
  @Form([
    Field(
      'assumptionId',
      String,
      'Assumption ID',
      hint: 'Unique identifier for this assumption',
    ),
    Field(
      'assumption',
      String,
      'Assumption Statement',
      required: true,
      hint: 'The condition assumed to hold true for the project',
    ),
    Field(
      'category',
      String,
      'Category (Technical, Organizational, External, Data, Resource)',
      hint: 'Classification of the assumption',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Validation ownership and confidence.
  @SectionId('BAEV')
  @StandardReferences(
    [
      'PMBOK — scope management & assumption log',
      'BABOK v3 — requirements scope & constraints',
    ],
    'Records who owns an assumption and how and when it will be validated to confirm it holds.',
  )
  @Form([
    Field(
      'rationale',
      String,
      'Basis for Assumption',
      hint: 'Reasoning or evidence supporting the assumption',
    ),
    Field(
      'owner',
      String,
      'Assumption Owner',
      hint: 'Person responsible for validating the assumption',
    ),
    Field(
      'validationMethod',
      String,
      'Validation Method',
      hint: 'How the assumption will be checked',
    ),
    Field(
      'validationDate',
      String,
      'Target Validation Date',
      hint: 'When validation is expected to be completed',
    ),
    Field(
      'validationStatus',
      String,
      'Status (Not Validated, Validated, Invalidated)',
      hint: 'Current validation state of the assumption',
    ),
    Field(
      'confidence',
      String,
      'Confidence Level (High, Medium, Low)',
      hint: 'How confident the team is the assumption holds',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? validation;

  /// Risk framing and contingency planning.
  @SectionId('BAER')
  @StandardReferences(
    [
      'ISO 31000 — risk management (assumption risk)',
      'PMBOK — scope management & assumption log',
    ],
    'Captures the consequences if an assumption proves false and the contingency plan to address it.',
  )
  @Form([
    Field(
      'riskIfWrong',
      String,
      'Risk if Wrong',
      hint: 'What happens if the assumption proves false',
    ),
    Field(
      'riskImpact',
      String,
      'Impact Level (High, Medium, Low)',
      hint: 'Severity of the impact if the assumption fails',
    ),
    Field(
      'contingencyPlan',
      String,
      'Contingency Plan',
      hint: 'Planned response if the assumption is invalidated',
    ),
    Field(
      'relatedRiskId',
      String,
      'Related Risk ID',
      hint: 'Identifier of the linked risk register entry',
      refersTo: ['RIID.riskId'],
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? risk;
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
@StandardReferences(
  [
    'TOGAF — enterprise context & environment',
    'PMBOK — enterprise environmental factors (EEF)',
    'ISO/IEC/IEEE 29148 §6 — operating environment',
  ],
  'Captures the organizational and technical environment in which the system operates so that environmental factors and constraints inform the solution design.',
)
@SectionId('OPEN')
class OperatingEnvironment extends DocSpecsSection {
  /// Framework conditions overview.
  @ContentHelp(
    'Provide executive summary of the operating environment: '
    'organizational context, technical landscape, key constraints, '
    'and critical dependencies affecting project execution.',
  )
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
  TechnicalEnvironment technicalEnvironment = TechnicalEnvironment();

  /// 4.6.4. Constraints and Dependencies — contains 0+×.
  @SectionId('COANDE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
      'PMBOK — constraints, assumptions & dependency management',
    ],
    'Frames how the operating-environment conditions in §4.6 give rise to constraints and dependencies, pointing to the canonical SBP.6 register.',
  )
  @ContentType(
    'description',
    'Summarize how the operating environment '
        'described in this section gives rise to constraints and dependencies, '
        'and reference the canonical register in SBP.6 (Assumptions, Constraints '
        '& Dependencies). Do not restate individual constraint or dependency '
        'entries here — record them once, in the SBP.6 register.',
  )
  @SerializationOrder(4)
  DocSpecsSection? constraintsAndDependencies;
}

/// 4.6.1. Organizational Environment.
///
/// Describes the organizational context in which the system will operate,
/// including departments, reporting structures, decision authority, and
/// organizational constraints. Follows organizational design principles
/// and enterprise architecture governance patterns.
@StandardReferences(
  [
    'ISO 21500 — organizational roles & responsibilities',
    'TOGAF — enterprise context & environment',
    'PMBOK — enterprise environmental factors (EEF)',
  ],
  'Describes the organizational context, structures, and decision authority that shape how the project intersects with the existing organization.',
)
@SectionId('OREN')
class OrganizationalEnvironment extends DocSpecsSection {
  // -------------------------------------------------------------------------
  // Organizational Overview
  // -------------------------------------------------------------------------
  @SectionId('OREN-ORGA')
  @Form([
    Field(
      'organizationName',
      String,
      'Organization Name',
      hint: 'Legal or common name of the organization',
    ),
    Field(
      'organizationType',
      String,
      'Organization Type (Enterprise, SMB, Startup, Government, Non-profit)',
      hint: 'Category that best describes the organization',
    ),
    Field(
      'industryVertical',
      String,
      'Industry Vertical (Finance, Healthcare, Retail, Tech, etc.)',
      hint: 'Primary industry the organization operates in',
    ),
    Field(
      'geographicFootprint',
      String,
      'Geographic Footprint (Local, National, Regional, Global)',
      hint: 'Geographic reach of the organization',
    ),
    Field(
      'employeeCount',
      String,
      'Employee Count',
      hint: 'Approximate number of employees',
    ),
    Field(
      'revenueRange',
      String,
      'Revenue Range',
      hint: 'Approximate annual revenue band',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? organizationContent;

  /// Organizational maturity indicators.
  @SectionId('ORENMA')
  @StandardReferences(
    [
      'PMBOK — enterprise environmental factors (EEF)',
      'TOGAF — enterprise context & environment',
    ],
    'Captures organizational maturity indicators that signal readiness for change and the rigor of existing governance.',
  )
  @Form([
    Field(
      'digitalMaturityLevel',
      String,
      'Digital Maturity (Nascent, Developing, Defined, Optimizing, Leading)',
      hint: 'Overall digital capability stage of the organization',
    ),
    Field(
      'changeReadiness',
      String,
      'Change Readiness (Low, Medium, High)',
      hint: 'Organizational appetite and capacity for change',
    ),
    Field(
      'projectManagementMaturity',
      String,
      'PM Maturity (Ad-hoc, Repeatable, Defined, Managed, Optimizing)',
      hint: 'Maturity of project management practices',
    ),
    Field(
      'itGovernanceMaturity',
      String,
      'IT Governance Maturity (Initial, Repeatable, Defined, Managed)',
      hint: 'Maturity of IT governance and oversight',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? maturity;

  /// Decision-making context.
  @SectionId('OEDM')
  @StandardReferences(
    [
      'ISO 21500 — organizational roles & responsibilities',
      'PMBOK — enterprise environmental factors (EEF)',
    ],
    'Captures the decision-making context including style, approval hierarchy, and budget authority that govern project decisions.',
  )
  @Form([
    Field(
      'decisionMakingStyle',
      String,
      'Decision Style (Centralized, Federated, Consensus, Delegated)',
      hint: 'How decisions are typically made in the organization',
    ),
    Field(
      'approvalLevels',
      String,
      'Approval Levels/Hierarchy',
      hint: 'Layers of approval required for decisions',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'Route for escalating unresolved decisions',
    ),
    Field(
      'budgetAuthority',
      String,
      'Budget Authority Structure',
      hint: 'Who holds spending authority and at what thresholds',
    ),
    Field(
      'procurementProcess',
      String,
      'Procurement Process Type',
      hint: 'Nature of the procurement and purchasing process',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? decisionMakingContext;

  // -------------------------------------------------------------------------
  // Organizational Structure
  // -------------------------------------------------------------------------

  /// Detailed organizational structure narrative.
  @ContentHelp(
    'Describe the organizational structure: departments involved, '
    'reporting relationships, matrix structures, and how the project '
    'intersects with existing organization.',
  )
  @SerializationOrder(3)
  TextSection structure = TextSection();

  /// Departments and business units affected.
  @StandardReferences(
    [
      'ISO 21500 — organizational roles & responsibilities',
      'TOGAF — enterprise context & environment',
    ],
    'Lists the departments and business units affected by the project so their roles and impact levels are captured.',
  )
  @SectionId('AFDEEN-AFFE-LST')
  @SectionIdPattern('AFDEEN-AFFE-xxx')
  @ContentHelp(
    'List each affected department with its role, impact level, '
    'and key contacts so organizational reach is fully documented.',
  )
  @SerializationOrder(4)
  List<AffectedDepartmentEntry> affectedDepartments = [];

  // -------------------------------------------------------------------------
  // Decision Making & Governance
  // -------------------------------------------------------------------------

  /// Decision making processes and authority.
  @ContentHelp(
    'Describe decision-making processes: governance boards, '
    'approval workflows, decision criteria, and timeline expectations '
    'for different decision types.',
  )
  @SerializationOrder(5)
  TextSection decisionMaking = TextSection();

  /// Key decision makers and their roles.
  @StandardReferences(
    [
      'ISO 21500 — organizational roles & responsibilities',
      'PMBOK — enterprise environmental factors (EEF)',
    ],
    'Identifies the key decision makers and their authority so governance and approval paths are clear.',
  )
  @SectionId('DEMAEN-DECI-LST')
  @SectionIdPattern('DEMAEN-DECI-xxx')
  @ContentHelp(
    'List each decision maker with their decision authority, '
    'domains, and influence level to map governance and approval paths.',
  )
  @SerializationOrder(6)
  List<DecisionMakerEntry> decisionMakers = [];

  // -------------------------------------------------------------------------
  // Cultural Context
  // -------------------------------------------------------------------------

  /// Cultural considerations and organizational dynamics.
  @StandardReferences(
    [
      'PMBOK — enterprise environmental factors (EEF)',
      'TOGAF — enterprise context & environment',
    ],
    'Captures cultural considerations and organizational dynamics that may influence adoption and change.',
  )
  @SectionId('CULTU-CULT-LST')
  @SectionIdPattern('CULTU-CULT-xxx')
  @ContentHelp(
    'List cultural factors and organizational dynamics that could '
    'affect project adoption, collaboration, or change readiness.',
  )
  @SerializationOrder(7)
  List<DocSpecsSection> culturalConsiderations = [];

  /// Stakeholder communication preferences.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture environment & stakeholders',
      'PMBOK — enterprise environmental factors (EEF)',
    ],
    'Records stakeholder communication preferences so engagement and reporting fit the organizational context.',
  )
  @SectionId('COMMU-COMM-LST')
  @SectionIdPattern('COMMU-COMM-xxx')
  @ContentHelp(
    'List communication preferences per stakeholder group to guide '
    'engagement channels, frequency, and reporting style.',
  )
  @SerializationOrder(8)
  List<DocSpecsSection> communicationPreferences = [];

  // -------------------------------------------------------------------------
  // Political Landscape
  // -------------------------------------------------------------------------

  /// Political dynamics and influence patterns.
  @ContentHelp(
    'Describe organizational politics: power centers, influence '
    'networks, historical project outcomes, and potential resistance points.',
  )
  @SerializationOrder(9)
  TextSection politicalLandscape = TextSection();

  /// Change champions and sponsors.
  @StandardReferences(
    [
      'PMBOK — enterprise environmental factors (EEF)',
      'ISO 21500 — organizational roles & responsibilities',
    ],
    'Identifies change champions and sponsors who can drive adoption and overcome organizational resistance.',
  )
  @SectionId('CHANG-CHAN-LST')
  @SectionIdPattern('CHANG-CHAN-xxx')
  @ContentHelp(
    'List change champions and sponsors, noting their influence and '
    'role in driving adoption across the organization.',
  )
  @SerializationOrder(10)
  List<DocSpecsSection> changeAdvocates = [];
}

/// An affected department entry.
@StandardReferences(
  [
    'ISO 21500 — organizational roles & responsibilities',
    'TOGAF — enterprise context & environment',
  ],
  'Documents a single affected department, its role in the project, and its readiness to absorb change.',
)
@SectionId('ADE')
class AffectedDepartmentEntry extends DocSpecsSection {
  @Form([
    Field(
      'departmentName',
      String,
      'Department Name',
      required: true,
      hint: 'Name of the affected department or business unit',
    ),
    Field(
      'departmentHead',
      String,
      'Department Head',
      hint: 'Person leading the department',
    ),
    Field(
      'employeeCount',
      int,
      'Employee Count',
      hint: 'Number of employees in the department',
    ),
    Field(
      'impactLevel',
      String,
      'Impact Level (High, Medium, Low)',
      hint: 'Degree to which the project affects this department',
    ),
    Field(
      'roleInProject',
      String,
      'Role (Sponsor, User, Data Owner, Operations, Support)',
      hint: 'How this department participates in the project',
    ),
    Field(
      'currentSystems',
      String,
      'Current Systems Used',
      hint: 'Existing systems the department relies on',
    ),
    Field(
      'changeReadiness',
      String,
      'Change Readiness (High, Medium, Low)',
      hint: 'Department capacity and appetite for change',
    ),
    Field(
      'keyContacts',
      String,
      'Key Contacts',
      hint: 'Primary contacts within the department',
    ),
    Field(
      'specialConsiderations',
      String,
      'Special Considerations',
      hint: 'Any constraints or special factors to note',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A decision maker entry.
@StandardReferences(
  [
    'ISO 21500 — organizational roles & responsibilities',
    'PMBOK — enterprise environmental factors (EEF)',
  ],
  'Documents a single decision maker, their authority and domains, so approval and governance paths are explicit.',
)
@SectionId('DME')
class DecisionMakerEntry extends DocSpecsSection {
  @Form([
    Field(
      'name',
      String,
      'Name',
      required: true,
      hint: 'Full name of the decision maker',
    ),
    Field(
      'title',
      String,
      'Title/Role',
      hint: 'Formal title or organizational role',
    ),
    Field(
      'department',
      String,
      'Department',
      hint: 'Department the decision maker belongs to',
    ),
    Field(
      'decisionAuthority',
      String,
      'Authority (Executive Sponsor, Steering Committee, Budget Owner, etc.)',
      hint: 'Type of authority this person holds',
    ),
    Field(
      'decisionDomains',
      String,
      'Decision Domains (Scope, Budget, Timeline, Technology, Resources)',
      hint: 'Areas where this person makes decisions',
    ),
    Field(
      'influenceLevel',
      String,
      'Influence Level (High, Medium, Low)',
      hint: 'Degree of influence over project outcomes',
    ),
    Field(
      'approvalRequired',
      String,
      'Approval Required For',
      hint: 'What requires this person to sign off',
    ),
    Field(
      'availabilityConstraints',
      String,
      'Availability/Constraints',
      hint: 'Limits on availability or engagement',
    ),
    Field(
      'stakeholderAlignment',
      String,
      'Stakeholder Alignment (Supportive, Neutral, Skeptical)',
      hint: 'Current stance toward the project',
    ),
    Field(
      'communicationPreference',
      String,
      'Communication Preference',
      hint: 'Preferred channel and cadence for updates',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 4.6.2. Functional Responsibilities.
///
/// Maps system functions to organizational units responsible for them.
/// Identifies domain owners, data stewards, and operational contacts for
/// each function area. Follows RACI matrix patterns and enterprise
/// accountability frameworks.
@StandardReferences(
  [
    'RACI / responsibility assignment — functional responsibilities',
    'ISO 21500 — organizational roles & responsibilities',
    'TOGAF — enterprise context & environment',
  ],
  'Maps system functions to the organizational units accountable for them so ownership and accountability are unambiguous.',
)
@SectionId('FURE')
class FunctionalResponsibilities extends DocSpecsSection {
  @Form([
    // Overview
    Field(
      'responsibilityMatrixApproach',
      String,
      'Responsibility Matrix Approach',
      hint:
          'RACI, RASCI, DACI — methodology used for responsibility assignment',
    ),
    Field(
      'governanceModel',
      String,
      'Governance Model',
      hint:
          'Centralized, federated, distributed — how responsibilities are governed',
    ),
    Field(
      'escalationProcess',
      String,
      'Escalation Process',
      hint: 'How responsibility conflicts or gaps are escalated',
    ),
    Field(
      'reviewCadence',
      String,
      'Review Cadence',
      hint: 'How often responsibility assignments are reviewed',
    ),
    Field(
      'totalFunctionCount',
      int,
      'Total Function Count',
      hint: 'Number of functional areas with assigned responsibilities',
    ),
    Field(
      'unassignedAreas',
      String,
      'Unassigned Areas',
      hint: 'Functional areas without clear ownership',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Responsibility matrix overview narrative.
  @ContentHelp(
    'Describe the overall approach to functional responsibility '
    'assignment: governance model, cross-functional coordination, '
    'conflict resolution, and ongoing maintenance.',
  )
  @SerializationOrder(1)
  TextSection matrixOverview = TextSection();

  /// Contains 0+× Responsibility.
  @StandardReferences(
    [
      'RACI / responsibility assignment — functional responsibilities',
      'ISO 21500 — organizational roles & responsibilities',
    ],
    'Holds the per-function responsibility entries that make up the overall responsibility matrix.',
  )
  @SectionId('REEN1-ITEM-LST')
  @SectionIdPattern('REEN1-ITEM-xxx')
  @ContentHelp(
    'Add one entry per functional area, capturing its RACI '
    'assignment, contacts, and related systems.',
  )
  @SerializationOrder(2)
  List<ResponsibilityEntry> items = [];
}

/// A responsibility entry (form).
///
/// Documents responsibility assignment for a specific functional area,
/// following RACI principles (Responsible, Accountable, Consulted, Informed)
/// with additional operational details for clear accountability.
@StandardReferences(
  [
    'RACI / responsibility assignment — functional responsibilities',
    'ISO 21500 — organizational roles & responsibilities',
  ],
  'Documents the responsibility assignment for a single functional area following RACI principles for clear accountability.',
)
@SectionId('RE')
class ResponsibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'functionId',
      String,
      'Function ID',
      required: true,
      hint: 'Unique identifier, e.g. FUNC-001',
    ),
    Field(
      'functionName',
      String,
      'Function Name',
      required: true,
      hint: 'Short descriptive name',
    ),
    Field(
      'functionArea',
      String,
      'Functional Area',
      hint: 'Sales, Marketing, Finance, HR, Operations, IT',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Function details and scope.
  @StandardReferences(
    ['RACI / responsibility assignment — functional responsibilities'],
    'Captures the detailed description and scope of the function being assigned responsibility.',
  )
  @SectionId('REFUDE-FUNC-LST')
  @SectionIdPattern('REFUDE-FUNC-xxx')
  @ContentHelp(
    'Describe the function\'s scope, boundaries, and business '
    'criticality to frame its responsibility assignment.',
  )
  @SerializationOrder(1)
  List<ResponsibilityFunctionDetails> functionDetails = [];

  /// RACI assignment.
  @SectionId('RERA')
  @StandardReferences(
    [
      'RACI / responsibility assignment — functional responsibilities',
      'ISO 21500 — organizational roles & responsibilities',
    ],
    'Records the Responsible, Accountable, Consulted, and Informed roles for a function per the RACI model.',
  )
  @Form([
    Field(
      'responsible',
      String,
      'Responsible (R)',
      hint: 'Role/team who does the work',
      required: true,
    ),
    Field(
      'accountable',
      String,
      'Accountable (A)',
      hint: 'Role/person ultimately accountable',
    ),
    Field(
      'consulted',
      String,
      'Consulted (C)',
      hint: 'Roles/teams who provide input',
    ),
    Field(
      'informed',
      String,
      'Informed (I)',
      hint: 'Roles/teams who are kept updated',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? raci;

  /// Key contacts.
  @StandardReferences(
    [
      'RACI / responsibility assignment — functional responsibilities',
      'ISO 21500 — organizational roles & responsibilities',
    ],
    'Lists the key contacts (domain owner, data steward, operational and technical contacts) for the function.',
  )
  @SectionId('RECO-CONT-LST')
  @SectionIdPattern('RECO-CONT-xxx')
  @ContentHelp(
    'Identify the domain owner, data steward, and operational, '
    'technical, and escalation contacts for this function.',
  )
  @SerializationOrder(3)
  List<ResponsibilityContacts> contacts = [];

  /// Related systems and data.
  @StandardReferences(
    [
      'RACI / responsibility assignment — functional responsibilities',
      'TOGAF — enterprise context & environment',
    ],
    'Records the systems and data owned or used by the function so technical accountability is mapped.',
  )
  @SectionId('RESY-SYST-LST')
  @SectionIdPattern('RESY-SYST-xxx')
  @ContentHelp(
    'List the primary systems, data, and process ownership '
    'associated with this functional responsibility.',
  )
  @SerializationOrder(4)
  List<ResponsibilitySystems> systems = [];

  /// Governance and transition.
  @SectionId('REGO')
  @StandardReferences(
    [
      'RACI / responsibility assignment — functional responsibilities',
      'ISO 21500 — organizational roles & responsibilities',
      'TOGAF — enterprise context & environment',
    ],
    'Captures the governance level, decision authority, and transition plan for how a function\'s responsibility evolves through implementation.',
  )
  @Form([
    Field(
      'governanceLevel',
      String,
      'Governance Level',
      hint: 'Central, federated, local',
    ),
    Field(
      'decisionAuthority',
      String,
      'Decision Authority',
      hint: 'What decisions this function can make autonomously',
    ),
    Field(
      'approvalRequired',
      String,
      'Approval Required',
      hint: 'What requires approval and from whom',
    ),
    Field(
      'complianceRole',
      String,
      'Compliance Role',
      hint: 'Regulatory or compliance responsibilities',
    ),
    Field(
      'currentState',
      String,
      'Current State',
      hint: 'How responsibility is handled currently',
    ),
    Field(
      'futureState',
      String,
      'Future State',
      hint: 'How responsibility will be handled post-implementation',
    ),
    Field(
      'transitionPlan',
      String,
      'Transition Plan',
      hint: 'Plan for transitioning responsibility',
    ),
    Field(
      'trainingNeeds',
      String,
      'Training Needs',
      hint: 'Training required for responsibility transition',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? governance;
}

/// Function details and scope.
@StandardReferences(
  ['RACI / responsibility assignment — functional responsibilities'],
  'Captures the description, scope, and business criticality of a function under responsibility assignment.',
)
@SectionId('REFUDE')
class ResponsibilityFunctionDetails extends DocSpecsSection {
  @Form([
    Field(
      'functionDescription',
      String,
      'Description',
      hint: 'Detailed description of the functional responsibility',
    ),
    Field(
      'functionScope',
      String,
      'Scope',
      hint: 'Boundaries of this functional responsibility',
    ),
    Field(
      'businessCriticality',
      String,
      'Business Criticality',
      hint: 'Critical, High, Medium, Low',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Key contacts.
@StandardReferences(
  [
    'RACI / responsibility assignment — functional responsibilities',
    'ISO 21500 — organizational roles & responsibilities',
  ],
  'Identifies the named contacts accountable for a function across business, data, operational, and technical roles.',
)
@SectionId('RECO')
class ResponsibilityContacts extends DocSpecsSection {
  @Form([
    Field(
      'domainOwner',
      String,
      'Domain Owner',
      hint: 'Business owner for this functional area',
    ),
    Field(
      'datasteward',
      String,
      'Data Steward',
      hint: 'Person responsible for data quality',
    ),
    Field(
      'operationalContact',
      String,
      'Operational Contact',
      hint: 'Day-to-day operational contact',
    ),
    Field(
      'technicalContact',
      String,
      'Technical Contact',
      hint: 'Technical SME for this area',
    ),
    Field(
      'escalationContact',
      String,
      'Escalation Contact',
      hint: 'Contact for escalation of issues',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Related systems and data.
@StandardReferences(
  [
    'RACI / responsibility assignment — functional responsibilities',
    'TOGAF — enterprise context & environment',
  ],
  'Records the systems, data, and processes owned or used by a function to map technical accountability.',
)
@SectionId('RESY')
class ResponsibilitySystems extends DocSpecsSection {
  @Form([
    Field(
      'primarySystems',
      String,
      'Primary Systems',
      hint: 'Systems primarily used for this function',
    ),
    Field(
      'dataOwnership',
      String,
      'Data Ownership',
      hint: 'Data entities owned by this function',
    ),
    Field(
      'processOwnership',
      String,
      'Process Ownership',
      hint: 'Business processes owned by this function',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'TOGAF — technology architecture & environment',
    'ISO/IEC/IEEE 42010 — architecture description (environment)',
    'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
  ],
  'Captures the pre-existing technical landscape — mandated platforms, infrastructure, and standards — in which the solution must operate, seeding the ATS.',
)
@SectionId('TEEN')
@Comment('Seeds → ATS')
@MapsTo(D06ArchitectureTechnologySpecification)
@DetailedIn(D06ArchitectureTechnologySpecification)
class TechnicalEnvironment extends DocSpecsSection {
  // -------------------------------------------------------------------------
  // Technical Landscape Overview
  // -------------------------------------------------------------------------
  @SectionId('TEEN-TECH')
  @Form([
    Field(
      'architectureMaturity',
      String,
      'Architecture Maturity',
      hint: 'TOGAF maturity level or equivalent',
    ),
    Field(
      'cloudStrategy',
      String,
      'Cloud Strategy',
      hint: 'Cloud-first, hybrid, on-premises, multi-cloud',
    ),
    Field(
      'primaryCloudProvider',
      String,
      'Primary Cloud Provider',
      hint: 'AWS, Azure, GCP, private cloud, none',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? technicalOverviewContent;

  /// Architecture governance context.
  @SectionId('TEENGO')
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC/IEEE 42010 — architecture description (environment)',
    ],
    'Captures the governance context that shapes technology decisions, including cloud strategy and decision authority.',
  )
  @Form([
    Field(
      'secondaryCloudProviders',
      String,
      'Secondary Cloud Providers',
      hint: 'Additional or fallback cloud providers in use',
    ),
    Field(
      'technologyGovernance',
      String,
      'Technology Governance',
      hint: 'How technology decisions are governed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Platform standards and preferred technologies.
  @SectionId('TEENST')
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
    ],
    'Captures mandated or preferred platform technologies — languages, frameworks, databases, and integration platforms.',
  )
  @Form([
    Field(
      'preferredLanguages',
      String,
      'Preferred Languages',
      hint: 'Mandated or preferred programming languages',
    ),
    Field(
      'preferredFrameworks',
      String,
      'Preferred Frameworks',
      hint: 'Mandated or preferred frameworks',
    ),
    Field(
      'preferredDatabases',
      String,
      'Preferred Databases',
      hint: 'Mandated or preferred database platforms',
    ),
    Field(
      'messagingPlatforms',
      String,
      'Messaging Platforms',
      hint: 'Enterprise messaging/queue platforms',
    ),
    Field(
      'integrationPlatforms',
      String,
      'Integration Platforms',
      hint: 'ESB, API gateway, iPaaS solutions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? standards;

  /// Security and compliance requirements.
  @SectionId('TES')
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
    ],
    'Captures the security frameworks, compliance regimes, and encryption/identity standards the solution must satisfy.',
  )
  @Form([
    Field(
      'securityFramework',
      String,
      'Security Framework',
      hint: 'NIST, ISO 27001, SOC2, CIS — security framework used',
    ),
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements',
      hint: 'GDPR, HIPAA, PCI-DSS, SOX, industry-specific',
    ),
    Field(
      'dataClassificationScheme',
      String,
      'Data Classification',
      hint: 'Public, internal, confidential, restricted',
    ),
    Field(
      'encryptionStandards',
      String,
      'Encryption Standards',
      hint: 'Required encryption algorithms and key lengths',
    ),
    Field(
      'identityProvider',
      String,
      'Identity Provider',
      hint: 'Enterprise identity platform (Azure AD, Okta, etc.)',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? security;

  /// Network and infrastructure standards.
  @SerializationOrder(4)
  TechnicalEnvironmentNetwork network = TechnicalEnvironmentNetwork();

  // -------------------------------------------------------------------------
  // Existing Infrastructure
  // -------------------------------------------------------------------------

  /// Existing infrastructure that must be reused or integrated with.
  @ContentHelp(
    'Describe existing infrastructure: data centers, servers, '
    'networks, storage, systems that cannot be replaced, and infrastructure '
    'that the new solution must integrate with or leverage.',
  )
  @SerializationOrder(5)
  TextSection existingInfrastructure = TextSection();

  /// Data center and hosting environment details.
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC/IEEE 12207 — software life-cycle (technical infrastructure)',
    ],
    'Enumerates data center and hosting environments the solution must run on or integrate with.',
  )
  @SectionId('DATAC-DATA-LST')
  @SectionIdPattern('DATAC-DATA-xxx')
  @ContentHelp(
    'List data centers and hosting environments: location, '
    'ownership, capacity, and any reuse or integration constraints.',
  )
  @SerializationOrder(6)
  List<DocSpecsSection> datacenters = [];

  /// Network topology and connectivity constraints.
  @ContentHelp(
    'Describe network topology, bandwidth constraints, latency '
    'requirements, VPN/private connectivity, and firewall restrictions.',
  )
  @SerializationOrder(7)
  TextSection networkTopology = TextSection();

  // -------------------------------------------------------------------------
  // Technology Standards
  // -------------------------------------------------------------------------

  /// Technology standards that must be followed.
  @ContentHelp(
    'Overview of technology standards: adoption policy, '
    'exception process, standard review cycle, and compliance monitoring.',
  )
  @SerializationOrder(8)
  TextSection standardsOverview = TextSection();

  /// Technology standards — contains 0+× TechnologyStandard.
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
    ],
    'Lists mandated or preferred technology standards the solution must adhere to.',
  )
  @SectionId('TESTEN-TECH-LST')
  @SectionIdPattern('TESTEN-TECH-xxx')
  @ContentHelp(
    'List technology standards the solution must follow, with '
    'their scope, mandate level, and compliance expectations.',
  )
  @SerializationOrder(9)
  List<TechnologyStandardEntry> technologyStandards = [];

  // -------------------------------------------------------------------------
  // Integration Constraints
  // -------------------------------------------------------------------------

  /// Integration constraints overview.
  @ContentHelp(
    'Overview of integration constraints: API standards, '
    'protocol restrictions, message format requirements, and '
    'integration platform mandates.',
  )
  @SerializationOrder(10)
  TextSection integrationOverview = TextSection();

  /// Integration constraints — contains 0+× IntegrationConstraint.
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
    ],
    'Lists technical constraints on integration — protocols, formats, and platform mandates the solution must respect.',
  )
  @SectionId('INCOE1-INTE-LST')
  @SectionIdPattern('INCOE1-INTE-xxx')
  @ContentHelp(
    'List integration constraints: protocol and format '
    'requirements, platform mandates, and the interfaces they affect.',
  )
  @SerializationOrder(11)
  List<IntegrationConstraintEntry> integrationConstraints = [];

  // -------------------------------------------------------------------------
  // DevOps & Operations Standards
  // -------------------------------------------------------------------------
}

/// Network and infrastructure standards.
@StandardReferences(
  [
    'TOGAF — technology architecture & environment',
    'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
  ],
  'Captures network and infrastructure standards — topology, firewall and VPN policies, and load-balancing/CDN strategy.',
)
@SectionId('TEENNE')
class TechnicalEnvironmentNetwork extends DocSpecsSection {
  @Form([
    Field(
      'networkArchitecture',
      String,
      'Network Architecture',
      hint: 'Network topology, DMZ, segmentation approach',
    ),
    Field(
      'firewallPolicies',
      String,
      'Firewall Policies',
      hint: 'Standard firewall rules and policies',
    ),
    Field(
      'vpnRequirements',
      String,
      'VPN Requirements',
      hint: 'VPN requirements for remote access',
    ),
    Field(
      'loadBalancingStandards',
      String,
      'Load Balancing Standards',
      hint: 'Standard load-balancing approach and products',
    ),
    Field(
      'cdnStrategy',
      String,
      'CDN Strategy',
      hint: 'Content delivery network strategy and providers',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// DevOps and deployment standards.
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC/IEEE 12207 — software life-cycle (technical infrastructure)',
    ],
    'Lists mandated DevOps and deployment standards the delivery pipeline must follow.',
  )
  @SectionId('DEVOP-DEVO-LST')
  @SectionIdPattern('DEVOP-DEVO-xxx')
  @ContentHelp(
    'List DevOps and deployment standards: CI/CD tooling, '
    'release process, and environment promotion rules.',
  )
  @SerializationOrder(1)
  List<DocSpecsSection> devopsStandards = [];

  /// Monitoring and observability requirements.
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
      'ISO/IEC/IEEE 12207 — software life-cycle (technical infrastructure)',
    ],
    'Lists monitoring and observability requirements the solution must meet for operational visibility.',
  )
  @SectionId('OBSER-OBSE-LST')
  @SectionIdPattern('OBSER-OBSE-xxx')
  @ContentHelp(
    'List observability requirements: metrics, logging, tracing, '
    'alerting standards, and required monitoring platforms.',
  )
  @SerializationOrder(2)
  List<DocSpecsSection> observabilityRequirements = [];

  /// Disaster recovery and business continuity requirements.
  @ContentHelp(
    'Describe DR/BC requirements: RTO, RPO, backup standards, '
    'failover requirements, and recovery testing.',
  )
  @SerializationOrder(3)
  TextSection disasterRecovery = TextSection();
}

/// A technology standard entry (form).
///
/// Documents a mandated or preferred technology standard that the solution
/// must adhere to. Includes scope, compliance requirements, and exceptions.
@StandardReferences(
  [
    'TOGAF — technology architecture & environment',
    'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
  ],
  'Documents a single mandated or preferred technology standard the solution must comply with.',
)
@SectionId('TSE')
class TechnologyStandardEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardId',
      String,
      'Standard ID',
      required: true,
      hint: 'Unique identifier, e.g. STD-SEC-001, STD-DEV-001',
    ),
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'Short descriptive name',
    ),
    Field(
      'standardCategory',
      String,
      'Category',
      hint: 'Security, Development, Infrastructure, Integration, Data, DevOps',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard details and sources.
  @SectionId('TSED')
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC/IEEE 42010 — architecture description (environment)',
    ],
    'Captures the descriptive details and authoritative source of a technology standard.',
  )
  @Form([
    Field(
      'standardDescription',
      String,
      'Description',
      hint: 'Detailed description of the standard',
    ),
    Field(
      'mandateLevel',
      String,
      'Mandate Level',
      hint: 'Mandatory, Strongly Preferred, Preferred, Optional',
    ),
    Field(
      'standardVersion',
      String,
      'Version',
      hint: 'Version of the standard',
    ),
    Field(
      'sourceReference',
      String,
      'Source Reference',
      hint: 'Policy document, framework reference, or authority',
    ),
    Field(
      'effectiveDate',
      String,
      'Effective Date',
      hint: 'Date the standard became effective',
    ),
    Field(
      'reviewDate',
      String,
      'Next Review Date',
      hint: 'When standard will be reviewed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? details;

  /// Scope and applicability.
  @SectionId('TSES')
  @StandardReferences(
    [
      'TOGAF — technology architecture & environment',
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
    ],
    'Defines where a technology standard applies and the process for granting exceptions.',
  )
  @Form([
    Field(
      'applicabilityScope',
      String,
      'Applicability Scope',
      hint: 'Where the standard applies — all systems, specific domains, etc.',
    ),
    Field(
      'technologiesCovered',
      String,
      'Technologies Covered',
      hint: 'Specific technologies this standard covers',
    ),
    Field(
      'exceptions',
      String,
      'Known Exceptions',
      hint: 'Existing exceptions to this standard',
    ),
    Field(
      'exceptionProcess',
      String,
      'Exception Process',
      hint: 'How to request an exception',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scope;

  /// Compliance settings.
  @SectionId('TSEC')
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
    ],
    'Captures how compliance with a technology standard is verified, owned, and enforced.',
  )
  @Form([
    Field(
      'complianceMethod',
      String,
      'Compliance Method',
      hint: 'How compliance is verified — automated scan, review, audit',
    ),
    Field(
      'complianceOwner',
      String,
      'Compliance Owner',
      hint: 'Role responsible for standard compliance',
    ),
    Field(
      'violationConsequence',
      String,
      'Violation Consequence',
      hint: 'Consequences of non-compliance',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? compliance;

  /// Project impact notes.
  @SectionId('TSEI')
  @StandardReferences(
    [
      'PMBOK — constraints, assumptions & dependency management',
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
    ],
    'Records how a technology standard impacts this project and notes for implementing it.',
  )
  @Form([
    Field(
      'projectImpact',
      String,
      'Project Impact',
      hint: 'How this standard impacts the project',
    ),
    Field(
      'implementationNotes',
      String,
      'Implementation Notes',
      hint: 'Notes on implementing this standard',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? impact;
}

/// An integration constraint entry (form).
///
/// Documents a technical constraint on system integration, including
/// protocol requirements, format restrictions, and platform mandates.
@StandardReferences(
  [
    'TOGAF — technology architecture & environment',
    'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
  ],
  'Documents a single technical constraint on system integration that the solution must respect.',
)
@SectionId('INTCONENT')
class IntegrationConstraintEntry extends DocSpecsSection {
  @Form([
    Field(
      'constraintId',
      String,
      'Constraint ID',
      required: true,
      hint: 'Unique identifier, e.g. INT-CON-001',
    ),
    Field(
      'constraintName',
      String,
      'Constraint Name',
      required: true,
      hint: 'Short descriptive name',
    ),
    Field(
      'constraintDescription',
      String,
      'Description',
      hint: 'Detailed description of the integration constraint',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Constraint details.
  @SectionId('INCOENDE')
  @StandardReferences([
    'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
    'TOGAF — technology architecture & environment',
  ], 'Captures the type, value, and source of an integration constraint.')
  @Form([
    Field(
      'constraintType',
      String,
      'Constraint Type',
      hint: 'Protocol, Format, Platform, Security, Performance, Availability',
    ),
    Field(
      'constraintValue',
      String,
      'Constraint Value',
      hint: 'Specific constraint value or requirement',
    ),
    Field(
      'constraintSource',
      String,
      'Source',
      hint:
          'Source of the constraint — enterprise architecture, vendor, security',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? details;

  /// Scope of impact.
  @SectionId('ICES')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
      'PMBOK — constraints, assumptions & dependency management',
    ],
    'Identifies the systems, interfaces, and integration patterns affected by a constraint.',
  )
  @Form([
    Field(
      'impactedSystems',
      String,
      'Impacted Systems',
      hint: 'Systems affected by this constraint',
    ),
    Field(
      'impactedInterfaces',
      String,
      'Impacted Interfaces',
      hint: 'Specific interfaces affected',
    ),
    Field(
      'integrationPattern',
      String,
      'Affected Patterns',
      hint: 'Integration patterns affected — sync, async, batch, event',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scope;

  /// Impact and mitigation.
  @SectionId('ICEM')
  @StandardReferences(
    [
      'PMBOK — constraints, assumptions & dependency management',
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
    ],
    'Captures the severity of an integration constraint and the design implications and mitigations for it.',
  )
  @Form([
    Field(
      'impactLevel',
      String,
      'Impact Level',
      hint: 'High, Medium, Low — impact on integration design',
    ),
    Field(
      'designImplications',
      String,
      'Design Implications',
      hint: 'How this constraint affects integration design',
    ),
    Field(
      'workarounds',
      String,
      'Workarounds',
      hint: 'Potential workarounds or alternatives',
    ),
    Field(
      'mitigationApproach',
      String,
      'Mitigation Approach',
      hint: 'How to work within this constraint',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? mitigation;

  /// Compliance rules.
  @SectionId('INCOENCO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — operating environment & constraints',
      'ISO/IEC 25010 — product quality (infrastructure/platform quality)',
    ],
    'Captures whether compliance with an integration constraint is mandatory and how it is validated.',
  )
  @Form([
    Field(
      'complianceRequired',
      bool,
      'Compliance Required',
      hint: 'Whether compliance is mandatory',
    ),
    Field(
      'validationMethod',
      String,
      'Validation Method',
      hint: 'How compliance is validated',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compliance;
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
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'PMBOK — project risk management',
    'ISO/IEC 31010 — risk assessment techniques',
  ],
  'This section captures the project risk register and management approach so threats and opportunities are systematically identified, analyzed, and controlled.',
)
@SectionId('RIANAS')
class RisksAndAssumptions extends DocSpecsSection {
  /// Overview of the risk management approach for this project.
  @SectionId('RIOV')
  @StandardReferences(
    [
      'ISO 31000:2018 — risk management',
      'PMBOK — project risk management',
      'ISO/IEC 31010 — risk assessment techniques',
    ],
    'This section captures the overarching risk management methodology, appetite, and scales that frame how every individual risk is assessed.',
  )
  @Form([
    Field(
      'riskManagementApproach',
      String,
      'Risk Management Approach — overall methodology and framework',
      hint: 'Describe the methodology and framework used to manage risk',
    ),
    Field(
      'riskAppetite',
      String,
      'Risk Appetite — organization tolerance (risk-averse, risk-neutral, risk-seeking)',
      hint: 'State the organization tolerance level for risk',
    ),
    Field(
      'riskThresholds',
      String,
      'Risk Thresholds — quantitative escalation levels (e.g., cost > \$50K)',
      hint: 'Define quantitative thresholds that trigger escalation',
    ),
    Field(
      'riskReviewCadence',
      String,
      'Risk Review Cadence — frequency of review meetings',
      hint: 'How often risks are reviewed',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path — hierarchy for escalating high-severity risks',
      hint: 'Chain of escalation for high-severity risks',
    ),
    Field(
      'riskTooling',
      String,
      'Risk Management Tooling — tools used to track risks',
      hint: 'Tools or systems used to track and report risks',
    ),
    Field(
      'riskCategories',
      String,
      'Risk Categories — Technical, Schedule, Cost, Resource, External, etc.',
      hint: 'Categories used to classify risks',
    ),
    Field(
      'probabilityScale',
      String,
      'Probability Scale — Very Low (<10%), Low (10-30%), Medium (30-50%), High (50-70%), Very High (>70%)',
      hint: 'Scale used to rate likelihood of occurrence',
    ),
    Field(
      'impactScale',
      String,
      'Impact Scale — Negligible, Minor, Moderate, Major, Catastrophic with criteria',
      hint: 'Scale used to rate severity of impact',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? overview;

  /// 4.7.1. Key Risks — contains 0+× Risk.
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
    'This list holds the individual risk entries that make up the project risk register and drive prioritization and response planning.',
  )
  @SectionId('RIEN-KEYR-LST')
  @SectionIdPattern('RIEN-KEYR-xxx')
  @ContentHelp(
    'List of identified project risks, each capturing analysis, response, ownership, and monitoring detail.',
  )
  @SerializationOrder(1)
  List<RiskEntry> keyRisks = [];
}

/// A risk entry (form).
///
/// Comprehensive risk documentation following ISO 31000 and PMBOK guidelines.
/// Captures risk identification, analysis, response planning, ownership,
/// and monitoring information for systematic risk management.
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'PMBOK — project risk management',
    'ISO/IEC 31010 — risk assessment techniques',
  ],
  'This section captures a single risk in full — its identification, analysis, response, ownership, and monitoring — so it can be managed end to end.',
)
@SectionId('RISENT')
class RiskEntry extends DocSpecsSection {
  /// Risk identification — unique identifier and basic description.
  @SerializationOrder(0)
  RiskIdentification identification = RiskIdentification();

  /// Risk analysis — probability, impact, and scoring.
  @SectionId('RIAN')
  @StandardReferences(
    [
      'ISO/IEC 31010 — risk assessment techniques',
      'ISO 31000:2018 — risk management',
      'PMBOK — project risk management',
    ],
    'This section captures the probability, impact, and resulting score that quantify a risk and drive its prioritization.',
  )
  @Form([
    Field(
      'probability',
      String,
      'Probability — Very Low, Low, Medium, High, Very High',
      hint: 'Qualitative likelihood rating',
    ),
    Field(
      'probabilityValue',
      double,
      'Probability Value — numeric (0.0-1.0) for quantitative analysis',
      hint: 'Numeric likelihood between 0.0 and 1.0',
    ),
    Field(
      'impact',
      String,
      'Impact — Negligible, Minor, Moderate, Major, Catastrophic',
      hint: 'Qualitative severity rating',
    ),
    Field(
      'impactValue',
      double,
      'Impact Value — numeric score (1-5 or monetary value)',
      hint: 'Numeric severity score or monetary value',
    ),
    Field(
      'riskScore',
      double,
      'Risk Score — calculated (probability × impact)',
      hint: 'Computed score from probability times impact',
    ),
    Field(
      'riskLevel',
      String,
      'Risk Level — Low, Medium, High, Critical',
      hint: 'Overall risk level classification',
    ),
    Field(
      'riskRanking',
      int,
      'Risk Ranking — priority relative to other risks',
      hint: 'Priority rank relative to other risks',
    ),
    Field(
      'analysisMethod',
      String,
      'Analysis Method — Qualitative, Semi-quantitative, Quantitative',
      hint: 'Method used to assess the risk',
    ),
    Field(
      'confidenceLevel',
      String,
      'Confidence Level — in probability/impact estimates',
      hint: 'Confidence in the probability and impact estimates',
    ),
    Field(
      'analysisNotes',
      String,
      'Analysis Notes — methodology and findings',
      hint: 'Notes on methodology and findings',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? analysis;

  /// Risk response — strategy and planned actions.
  @SerializationOrder(2)
  RiskResponse response = RiskResponse();

  /// Risk ownership and governance.
  @SectionId('RIOW')
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
    'This section assigns accountability and approval authority for the risk so governance and escalation lines are unambiguous.',
  )
  @Form([
    Field(
      'riskOwner',
      String,
      'Risk Owner — person accountable for monitoring',
      hint: 'Person accountable for monitoring the risk',
    ),
    Field(
      'riskOwnerRole',
      String,
      'Owner Role — role/title',
      hint: 'Role or title of the risk owner',
    ),
    Field(
      'actionOwners',
      String,
      'Action Owners — people responsible for mitigation actions',
      hint: 'People responsible for mitigation actions',
    ),
    Field(
      'escalationContact',
      String,
      'Escalation Contact — who to escalate to if risk worsens',
      hint: 'Who to escalate to if the risk worsens',
    ),
    Field(
      'stakeholdersInformed',
      String,
      'Stakeholders Informed — who needs to be kept informed',
      hint: 'Stakeholders to keep informed',
    ),
    Field(
      'approvalRequired',
      bool,
      'Approval Required — whether response actions need approval',
      hint: 'Whether response actions require approval',
    ),
    Field(
      'approver',
      String,
      'Approver — person who must approve response actions',
      hint: 'Person who must approve response actions',
    ),
    Field(
      'decisionAuthority',
      String,
      'Decision Authority — authority level for decisions',
      hint: 'Authority level for risk decisions',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? ownership;

  /// Risk monitoring and tracking details.
  @SerializationOrder(4)
  RiskMonitoring monitoring = RiskMonitoring();

  /// Business impact assessment.
  @SerializationOrder(5)
  RiskBusinessImpact businessImpact = RiskBusinessImpact();

  /// Relationships to other risks, assumptions, and project elements.
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
    'This list links the risk to related risks, assumptions, requirements, and components so dependencies and ripple effects are visible.',
  )
  @SectionId('RR-RELA-LST')
  @SectionIdPattern('RR-RELA-xxx')
  @ContentHelp(
    'Relationships connecting this risk to other risks, assumptions, requirements, and affected project elements.',
  )
  @SerializationOrder(6)
  List<RiskRelationships> relationships = [];
}

/// Risk identification details.
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'PMBOK — project risk management',
    'ISO/IEC 31010 — risk assessment techniques',
  ],
  'This section captures the unique identifier, name, and categorization that uniquely distinguish a risk in the register.',
)
@SectionId('RIID')
class RiskIdentification extends DocSpecsSection {
  @Form([
    Field(
      'riskId',
      String,
      'Risk ID (e.g., RISK-001, TR-001)',
      required: true,
      hint: 'Unique identifier for this risk',
    ),
    Field(
      'riskName',
      String,
      'Risk Name — short descriptive name',
      required: true,
      hint: 'Short descriptive name for the risk',
    ),
    Field(
      'description',
      String,
      'Description — detailed risk event and potential causes',
      hint: 'Detailed description of the risk event and its causes',
    ),
    Field(
      'category',
      String,
      'Category — Technical, Schedule, Cost, Resource, External, Legal, Organizational',
      hint: 'Top-level risk category',
    ),
    Field(
      'subcategory',
      String,
      'Subcategory — more specific categorization',
      hint: 'More specific categorization within the category',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identification source and ownership metadata.
  @SectionId('RIIDSO')
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
    'This section records how and when the risk was identified and who raised it, supporting traceability of the risk register.',
  )
  @Form([
    Field(
      'source',
      String,
      'Risk Source — brainstorming, review, lessons learned',
      hint: 'How the risk was identified',
    ),
    Field(
      'dateIdentified',
      String,
      'Date Identified',
      hint: 'When the risk was first identified',
    ),
    Field(
      'identifiedBy',
      String,
      'Identified By — person or team',
      hint: 'Person or team who identified the risk',
    ),
    Field(
      'riskType',
      String,
      'Risk Type — Threat (negative) or Opportunity (positive)',
      hint: 'Whether this is a threat or an opportunity',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? sourceDetails;

  /// Trigger and root-cause details.
  @SectionId('RIIDCA')
  @StandardReferences(
    [
      'ISO 31000:2018 — risk management',
      'ISO/IEC 31010 — risk assessment techniques',
    ],
    'This section captures the triggering events and underlying root causes of the risk to support early detection and prevention.',
  )
  @Form([
    Field(
      'trigger',
      String,
      'Risk Trigger — events indicating risk is about to occur',
      hint: 'Events signaling the risk is about to occur',
    ),
    Field(
      'rootCause',
      String,
      'Root Cause — underlying causes that could lead to this risk',
      hint: 'Underlying causes that could lead to the risk',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? cause;
}

/// Risk response — strategy and planned actions.
@StandardReferences(
  ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
  'This section captures the chosen response strategy and the mitigation and contingency actions planned to treat the risk.',
)
@SectionId('RIRE')
class RiskResponse extends DocSpecsSection {
  @Form([
    Field(
      'responseStrategy',
      String,
      'Response Strategy — Avoid, Transfer, Mitigate, Accept (or Exploit, Share, Enhance for opportunities)',
      hint: 'Strategy chosen to treat the risk',
    ),
    Field(
      'responseDescription',
      String,
      'Response Description — planned approach',
      hint: 'Description of the planned response approach',
    ),
    Field(
      'mitigationActions',
      String,
      'Mitigation Actions — actions to reduce probability or impact',
      hint: 'Actions to reduce likelihood or impact',
    ),
    Field(
      'contingencyPlan',
      String,
      'Contingency Plan — actions if risk materializes',
      hint: 'Fallback actions if the risk materializes',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Residual and secondary risk expectations.
  @SectionId('RIRERE')
  @StandardReferences(
    [
      'ISO 31000:2018 — risk management',
      'ISO/IEC 31010 — risk assessment techniques',
    ],
    'This section captures the residual risk expected after treatment and any secondary risks introduced by the response.',
  )
  @Form([
    Field(
      'residualRisk',
      String,
      'Residual Risk — level remaining after mitigation',
      hint: 'Risk level remaining after mitigation',
    ),
    Field(
      'residualProbability',
      String,
      'Residual Probability — expected after mitigation',
      hint: 'Expected likelihood after mitigation',
    ),
    Field(
      'residualImpact',
      String,
      'Residual Impact — expected after mitigation',
      hint: 'Expected impact after mitigation',
    ),
    Field(
      'secondaryRisks',
      String,
      'Secondary Risks — new risks from implementing response',
      hint: 'New risks arising from the response',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? residual;

  /// Implementation effort and effectiveness.
  @SectionId('RIREIM')
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
    'This section captures the cost, timeline, and effectiveness of implementing the risk response so trade-offs can be weighed.',
  )
  @Form([
    Field(
      'responseEffectiveness',
      String,
      'Response Effectiveness — Low, Medium, High',
      hint: 'How effective the response is expected to be',
    ),
    Field(
      'implementationCost',
      String,
      'Implementation Cost — cost to implement response',
      hint: 'Cost to implement the response',
    ),
    Field(
      'implementationTimeline',
      String,
      'Implementation Timeline — for response actions',
      hint: 'Timeline for carrying out response actions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? implementation;
}

/// Risk monitoring and tracking.
@StandardReferences(
  ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
  'This section captures the cadence and current status of ongoing risk monitoring so the risk stays under active review.',
)
@SectionId('RIMO')
class RiskMonitoring extends DocSpecsSection {
  @Form([
    Field(
      'reviewFrequency',
      String,
      'Review Frequency — Daily, Weekly, Bi-weekly, Monthly',
      hint: 'How often the risk is reviewed',
    ),
    Field(
      'lastReviewDate',
      String,
      'Last Review Date',
      hint: 'Date of the most recent review',
    ),
    Field(
      'nextReviewDate',
      String,
      'Next Review Date',
      hint: 'Date of the next scheduled review',
    ),
    Field(
      'riskStatus',
      String,
      'Risk Status — Identified, Analyzing, Responding, Monitoring, Closed, Realized',
      hint: 'Current lifecycle status of the risk',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Trend and monitoring indicators.
  @SectionId('RIMOTR')
  @StandardReferences(
    [
      'ISO 31000:2018 — risk management',
      'ISO/IEC 31010 — risk assessment techniques',
    ],
    'This section captures the risk trend and early-warning indicators that signal whether the risk is growing or receding.',
  )
  @Form([
    Field(
      'trend',
      String,
      'Trend — Increasing, Stable, Decreasing',
      hint: 'Direction in which the risk is trending',
    ),
    Field(
      'trendJustification',
      String,
      'Trend Justification — explanation for trend assessment',
      hint: 'Rationale for the trend assessment',
    ),
    Field(
      'earlyWarningIndicators',
      String,
      'Early Warning Indicators — metrics signaling risk may materialize',
      hint: 'Metrics that signal the risk may materialize',
    ),
    Field(
      'monitoringMechanism',
      String,
      'Monitoring Mechanism — automated alerts, manual review, etc.',
      hint: 'Mechanism used to monitor the risk',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? trendDetails;

  /// Closure tracking and lessons learned.
  @SectionId('RIMOCL')
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
    'This section records when and why the risk was closed and the lessons learned to inform future risk management.',
  )
  @Form([
    Field(
      'closureDate',
      String,
      'Closure Date',
      hint: 'Date the risk was closed',
    ),
    Field(
      'closureReason',
      String,
      'Closure Reason — Mitigated, Avoided, Accepted, Realized, No longer relevant',
      hint: 'Why the risk was closed',
    ),
    Field(
      'lessonsLearned',
      String,
      'Lessons Learned — key insights from managing this risk',
      hint: 'Key insights gained from managing the risk',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? closure;
}

/// Business impact assessment for the risk.
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'PMBOK — project risk management',
    'ISO/IEC 31010 — risk assessment techniques',
  ],
  'This section captures the cost, schedule, scope, and quality consequences of the risk to inform business prioritization.',
)
@SectionId('RIBUIM')
class RiskBusinessImpact extends DocSpecsSection {
  @Form([
    Field(
      'costImpact',
      String,
      'Cost Impact — potential cost if risk materializes',
      hint: 'Potential cost if the risk materializes',
    ),
    Field(
      'scheduleImpact',
      String,
      'Schedule Impact — potential delay (days, weeks, phases)',
      hint: 'Potential schedule delay if the risk occurs',
    ),
    Field(
      'scopeImpact',
      String,
      'Scope Impact — impact on deliverables',
      hint: 'Impact on project scope and deliverables',
    ),
    Field(
      'qualityImpact',
      String,
      'Quality Impact',
      hint: 'Impact on product or deliverable quality',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Broader stakeholder and compliance impact.
  @SectionId('RBIS')
  @StandardReferences(
    [
      'ISO 31000:2018 — risk management',
      'ISO/IEC 27005 — information security risk management (for security-flavored risks)',
    ],
    'This section captures the resource, reputation, customer, and regulatory consequences of the risk on stakeholders and compliance.',
  )
  @Form([
    Field(
      'resourceImpact',
      String,
      'Resource Impact — impact on team resources',
      hint: 'Impact on team and resource availability',
    ),
    Field(
      'reputationImpact',
      String,
      'Reputation Impact — organizational or project',
      hint: 'Impact on organizational or project reputation',
    ),
    Field(
      'customerImpact',
      String,
      'Customer Impact — impact on customers or end users',
      hint: 'Impact on customers or end users',
    ),
    Field(
      'regulatoryImpact',
      String,
      'Regulatory Impact — compliance implications',
      hint: 'Compliance and regulatory implications',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? stakeholders;

  /// Operational and delivery consequences.
  @SectionId('RBID')
  @StandardReferences(
    ['ISO 31000:2018 — risk management', 'PMBOK — project risk management'],
    'This section captures the operational, strategic, and delivery consequences of the risk on milestones and deliverables.',
  )
  @Form([
    Field(
      'operationalImpact',
      String,
      'Operational Impact — impact on ongoing operations',
      hint: 'Impact on ongoing operations',
    ),
    Field(
      'strategicImpact',
      String,
      'Strategic Impact — impact on strategic objectives',
      hint: 'Impact on strategic objectives',
    ),
    Field(
      'affectedMilestones',
      String,
      'Affected Milestones — project milestones at risk',
      hint: 'Project milestones placed at risk',
    ),
    Field(
      'affectedDeliverables',
      String,
      'Affected Deliverables — specific deliverables at risk',
      hint: 'Specific deliverables placed at risk',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? delivery;
}

/// Relationships to other risks, assumptions, and project elements.
@StandardReferences(
  [
    'ISO 31000:2018 — risk management',
    'ISO/IEC/IEEE 29148 §6 — assumptions, dependencies & constraints (risk context)',
  ],
  'This section captures how the risk relates to other risks, assumptions, requirements, and components so interdependencies are tracked.',
)
@SectionId('RR')
class RiskRelationships extends DocSpecsSection {
  @Form([
    Field(
      'relatedRisks',
      String,
      'Related Risks — other risks that are related or dependent',
      hint: 'Other risks related to or dependent on this one',
    ),
    Field(
      'relatedAssumptions',
      String,
      'Related Assumptions — assumptions that could affect this risk',
      hint: 'Assumptions that could affect this risk',
    ),
    Field(
      'relatedIssues',
      String,
      'Related Issues — issues arising from this risk',
      hint: 'Issues arising from this risk',
    ),
    Field(
      'relatedRequirements',
      String,
      'Related Requirements — requirements affected',
      hint: 'Requirements affected by this risk',
    ),
    Field(
      'affectedComponents',
      String,
      'Affected Components — system components or modules',
      hint: 'System components or modules affected',
    ),
    Field(
      'affectedStakeholders',
      String,
      'Affected Stakeholders — groups impacted if risk occurs',
      hint: 'Stakeholder groups impacted if the risk occurs',
    ),
    Field(
      'externalDependencies',
      String,
      'External Dependencies — external factors related to risk',
      hint: 'External factors related to the risk',
    ),
    Field(
      'documentReferences',
      String,
      'Document References — related documentation',
      hint: 'Related documentation references',
    ),
  ])
  @override
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
class SystemLandscapeInventory extends DocSpecsSection {
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
  @override
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
class BoundaryInteractionPatterns extends DocSpecsSection {
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
  @override
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
class InteractionTestingStrategy extends DocSpecsSection {
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
  @override
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
class InteractionDependencyAnalysis extends DocSpecsSection {
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
  @override
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
class MigrationInteractions extends DocSpecsSection {
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
  @override
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
class RequirementRelationships extends DocSpecsSection {
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
  @override
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
class RequirementCoverage extends DocSpecsSection {
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
  @override
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
class CrossBoundaryOperationalConsiderations extends DocSpecsSection {
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
  @override
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
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'Cross-boundary failure-propagation policy shared by all interfaces '
      '— the canonical CE-ER error codes/envelope that propagate across '
      'boundaries (codespecs_mapping.md §7 points 3/4).',
)
class CrossBoundaryErrorHandling extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}
