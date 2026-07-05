/// Section 12: Components and Dependencies. Seeds → ATS.
///
/// External and standard components planned for use in the system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 12. Components and Dependencies. Seeds → ATS.
///
/// External and standard components planned for use in the system. All
/// subsections seed the ATS document, where component choices are expanded
/// into detailed dependency analysis, version requirements, licensing,
/// and integration patterns.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, their dependencies, and rationale are documented for stakeholders',
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing components, versions, licenses, and provenance',
  ],
  'Captures the components and dependencies chapter governing external and standard component selection and dependency management.',
)
@SectionId('COMP')
@Comment('Seeds → ATS')
@MapsTo(D06ArchitectureTechnologySpecification)
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-COM')
class ComponentsAndDependencies {
    @ContentHelp('''
## Components and Dependencies (Chapter 12)

External and standard components planned for the system.

### Subsections
- **12.1 Component Strategy** — Build vs buy, governance, evaluation cadence
- **12.2 Component Catalog** — Individual component specifications
- **12.3 Component Role in System** — Mapping to architecture
- **12.4 Runtime Dependencies** — Startup order, health checks, failover
- **12.5 Maintenance Dependencies** — Version matrix, update sequences
- **12.6 Risk Assessment** — Component risks and contingency plans

### Seeds
All subsections seed the **ATS (Architecture & Technology Specification)** document.

### Specification Depth
Each component should specify:
- Identity (name, version, vendor)
- Licensing and costs
- Integration interfaces
- Security baseline
- Support model
- Risk profile
''')
    @SerializationOrder(0)
    String? content;

    /// 12.1. Component Strategy.
    @SerializationOrder(1)
    ComponentStrategy strategy = ComponentStrategy();

    /// 12.2. Component Catalog — contains 0+× Component.
    @StandardReferences(
      [
        'ISO/IEC 5962:2021 — the SPDX specification records each cataloged component in the software bill of materials with identity and version metadata',
      ],
      'Lists the individual components cataloged for the system.',
    )
    @SectionId('CMPNT-COMP-LST')
    @SectionIdPattern('CMPNT-COMP-xxx')
    @ContentHelp('Add one entry per cataloged component.')
    @SerializationOrder(2)
    List<ComponentEntry> componentCatalog = [];

    /// 12.3. Component Role In System.
    @SerializationOrder(3)
    TextSection componentRoleInSystem = TextSection();

    /// 12.4. Runtime Dependencies.
    @SerializationOrder(4)
    RuntimeDependencies runtimeDependencies = RuntimeDependencies();

    /// 12.5. Maintenance Dependencies.
    @SerializationOrder(5)
    MaintenanceDependencies maintenanceDependencies = MaintenanceDependencies();

    /// 12.6. Risk Assessment.
    @SerializationOrder(6)
    ComponentRiskAssessment riskAssessment = ComponentRiskAssessment();
}

// ---------------------------------------------------------------------------
// 12.1. Component Strategy
// ---------------------------------------------------------------------------

/// 12.1. Component Strategy.
///
/// Overall component strategy: build-vs-buy philosophy, preferred vendors,
/// technology stack alignment, governance, evaluation cadence, and portfolio
/// management.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how component choices and their rationale are documented for stakeholders',
  ],
  'Captures the component strategy governing build-versus-buy philosophy, technology alignment, governance, portfolio, policies, and planning.',
)
@SectionId('CMSTR')
class ComponentStrategy {
    @Form([
        Field('buildVsBuyPhilosophy', String, 'Build vs. Buy Philosophy',
                hint:
                        'BuildFirst / BuyFirst / BestOfBreed / CaseByCase — default stance for component decisions'),
        Field('buildVsBuyThreshold', String, 'Build vs. Buy Decision Threshold',
                hint:
                        'Criteria for when to build, e.g. "Build if <40h and core differentiator"'),
        Field(
                'technologyStackAlignment', String, 'Technology Stack Alignment',
                hint:
                        'Target stack, e.g. Dart/Flutter, PostgreSQL, Redis, Kubernetes'),
    ])
    @SerializationOrder(0)
    String? content;

    /// Vendor preferences and exceptions.
    @SerializationOrder(1)
    ComponentStrategyVendors vendors = ComponentStrategyVendors();

    /// Governance and evaluation process.
    @SerializationOrder(2)
    ComponentStrategyGovernance governance = ComponentStrategyGovernance();

    /// Portfolio management settings.
    @SerializationOrder(3)
    ComponentStrategyPortfolio portfolio = ComponentStrategyPortfolio();

    /// Policy and baseline requirements.
    @SerializationOrder(4)
    ComponentStrategyPolicies policies = ComponentStrategyPolicies();

    /// Budget and pilot planning.
    @SerializationOrder(5)
    ComponentStrategyPlanning planning = ComponentStrategyPlanning();

    /// 12.1.1. Reuse Goals — contains 0+× ReuseGoal.
    @StandardReferences(
      [
        'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
      ],
      'Lists the reuse goals defined for the component strategy.',
    )
    @SectionId('RGUSE-REUS-LST')
    @SectionIdPattern('RGUSE-REUS-xxx')
    @ContentHelp('Add one entry per reuse goal.')
    @SerializationOrder(6)
    List<ReuseGoalEntry> reuseGoals = [];

    /// 12.1.2. Evaluation Criteria.
    @SerializationOrder(7)
    EvaluationCriteria evaluationCriteria = EvaluationCriteria();
}

/// Vendor preferences and exceptions.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme for procured components',
  ],
  'Holds the vendor preferences and exceptions including preferred and prohibited vendors and the stack deviation process.',
)
@SectionId('CSVND')
class ComponentStrategyVendors {
    @Form([
        Field('preferredVendors', String, 'Preferred Vendors',
                hint:
                        'Strategically aligned vendors, e.g. AWS, Confluent, Elastic'),
        Field('prohibitedVendors', String, 'Prohibited Vendors',
                hint:
                        'Vendors excluded for compliance, legal, or strategic reasons'),
        Field('stackDeviationProcess', String, 'Stack Deviation Process',
                hint:
                        'How to request approval for off-stack choices'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Governance and evaluation process.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how component choices and their rationale are documented for stakeholders',
  ],
  'Holds the governance model, review cadence, and evaluation cadence for component decisions.',
)
@SectionId('CSGOV')
class ComponentStrategyGovernance {
    @Form([
        Field('governanceModel', String, 'Governance Model',
                hint:
                        'How component decisions are made — Architecture Review Board, tech leads, etc.'),
        Field('governanceFrequency', String, 'Governance Review Cadence',
                hint:
                        'How often the component portfolio is reviewed, e.g. quarterly, biannually'),
        Field('evaluationCadence', String, 'Component Evaluation Cadence',
                hint:
                        'How often new/existing components are formally evaluated'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Portfolio management settings.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
  ],
  'Holds the portfolio management settings including catalog visibility, registry URL, overlap limits, and consolidation targets.',
)
@SectionId('CSPRT')
class ComponentStrategyPortfolio {
    @Form([
        Field('portfolioVisibility', String, 'Portfolio Visibility',
                hint:
                        'Where the component catalog is published — wiki, CMDB, internal portal'),
        Field('componentRegistryUrl', String, 'Component Registry URL',
                hint: 'Link to the authoritative component catalog'),
        Field('maxComponentOverlap', int, 'Max Allowed Overlap',
                hint:
                        'Maximum number of components for the same purpose, e.g. 2 DB engines'),
        Field('consolidationTargets', String, 'Consolidation Targets',
                hint:
                        'Components targeted for elimination or merger'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Policy and baseline requirements.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme for procured components',
  ],
  'Holds the policy and baseline requirements including open-source policy, security and compliance baselines, and sunset policy.',
)
@SectionId('CSPOL')
class ComponentStrategyPolicies {
    @Form([
        Field('openSourcePolicy', String, 'Open-Source Policy',
                hint:
                        'Permitted licenses, contribution policy, CLA stance'),
        Field('securityBaselineRequirement', String, 'Security Baseline',
                hint:
                        'Minimum security requirements all components must meet'),
        Field(
                'complianceBaselineRequirement', String, 'Compliance Baseline',
                hint:
                        'Minimum compliance certifications required for all components'),
        Field('vendorDiversityGoal', String, 'Vendor Diversity Goal',
                hint:
                        'Strategy to avoid over-reliance on a single vendor'),
        Field('sunsetPolicy', String, 'Sunset Policy',
                hint:
                        'How end-of-life components are retired — timeline, migration support'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Budget and pilot planning.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
  ],
  'Holds the budget and pilot planning for the component strategy including the pilot process and portfolio budget.',
)
@SectionId('CSPLN')
class ComponentStrategyPlanning {
    @Form([
        Field('pilotProcessDescription', String, 'Pilot Process',
                hint:
                        'How new components are piloted before full adoption'),
        Field('totalPortfolioBudget', String, 'Total Component Budget',
                hint:
                        'Annual budget ceiling for all component costs'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A reuse goal entry (form).
///
/// Defines a specific reuse target: what to reuse, why, at what percentage,
/// how to measure, and who owns the goal.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
  ],
  'Defines a single reuse goal covering what to reuse, why, at what percentage, how to measure, and who owns it.',
)
@SectionId('RGUSE')
class ReuseGoalEntry {
  @Form([
    Field('goalId', String, 'Goal ID',
        hint: 'Unique identifier, e.g. RG-001'),
    Field('goal', String, 'Reuse Goal',
        hint:
            'What should be reused, e.g. Centralize auth via shared login SDK',
        required: true),
    Field('rationale', String, 'Business Rationale',
        hint:
            'Why reuse matters here — cost savings, consistency, time-to-market'),
    Field('category', String, 'Reuse Category',
        hint:
            'UIComponents / DataLayer / Authentication / Infrastructure / APIs'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Measurement and scope.
  @SerializationOrder(1)
  ReuseGoalEntryMeasurement measurement = ReuseGoalEntryMeasurement();

  /// Governance and ownership.
  @SerializationOrder(2)
  ReuseGoalEntryGovernance governance = ReuseGoalEntryGovernance();

  /// Delivery support and assets.
  @SerializationOrder(3)
  ReuseGoalEntryEnablement enablement = ReuseGoalEntryEnablement();
}

/// Measurement and scope.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
  ],
  'Holds the measurement and scope for a reuse goal including target and current percentages and measurement method.',
)
@SectionId('RGUMS')
class ReuseGoalEntryMeasurement {
  @Form([
    Field('scope', String, 'Scope',
        hint: 'ProjectLevel / DivisionLevel / EnterpriseWide'),
    Field('targetPercentage', int, 'Target Reuse %',
        hint: 'Target percentage of reuse for this category'),
    Field('currentPercentage', int, 'Current Reuse %',
        hint: 'Measured current reuse percentage'),
    Field('measurementMethod', String, 'Measurement Method',
        hint:
            'How reuse % is measured — code analysis, component registry, survey'),
    Field('measurementFrequency', String, 'Measurement Frequency',
        hint: 'How often reuse is measured, e.g. sprint, quarterly, release'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance and ownership.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
  ],
  'Holds the governance and ownership for a reuse goal including priority, target date, and owner.',
)
@SectionId('RGUGV')
class ReuseGoalEntryGovernance {
  @Form([
    Field('priority', String, 'Priority',
        hint: 'Critical / High / Medium / Low'),
    Field('targetDate', String, 'Target Date',
        hint: 'When this goal should be achieved'),
    Field('owner', String, 'Goal Owner',
        hint: 'Person or team responsible for driving this goal'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Delivery support and assets.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics including reusability that guide build-versus-buy strategy',
  ],
  'Holds the delivery support for a reuse goal including blockers, enablers, and reusable assets.',
)
@SectionId('RGENB')
class ReuseGoalEntryEnablement {
  @Form([
    Field('blockers', String, 'Known Blockers',
        hint: 'What prevents higher reuse today'),
    Field('enablers', String, 'Enablers',
        hint: 'Actions or investments needed to reach the target'),
    Field('reusableAssets', String, 'Reusable Assets',
        hint:
            'Specific components, libraries, or services to be reused'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 12.1.2. Evaluation Criteria.
///
/// Container for component evaluation criteria used when assessing
/// candidate components for adoption.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the software product quality evaluation process defines how evaluation criteria are established and applied',
  ],
  'Container for the component evaluation criteria used when assessing candidate components for adoption.',
)
@SectionId('EVCRI')
class EvaluationCriteria {
  @ContentHelp('''
## Evaluation Criteria (12.1.2)

Criteria for evaluating candidate components.

### Standard Categories
- **Technical** — Performance, scalability, security, API quality
- **Commercial** — Cost, licensing, vendor stability
- **Operational** — Support model, documentation, update frequency
- **Strategic** — Alignment with stack, vendor relationship
- **Compliance** — Regulatory requirements, certifications

### Scoring Approach
Each criterion includes:
- Weight (% of total)
- Scoring scale (1-5, Pass/Fail)
- Minimum threshold
- Eliminatory flag
- Evidence requirements
- Evaluation method
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× EvaluationCriterion.
  @StandardReferences(
    [
      'ISO/IEC 25040:2011 — the software product quality evaluation process defines how evaluation criteria are established and applied',
    ],
    'Lists the evaluation criteria used to assess candidate components.',
  )
  @SectionId('EVCEN-ITEM-LST')
  @SectionIdPattern('EVCEN-ITEM-xxx')
  @ContentHelp('Add one entry per evaluation criterion.')
  @SerializationOrder(1)
  List<EvaluationCriterionEntry> items = [];
}

/// An evaluation criterion entry (form).
///
/// Defines one criterion for evaluating candidate components: scoring scale,
/// threshold, evidence requirements, and evaluation method.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the software product quality evaluation process defines how evaluation criteria are established and applied',
  ],
  'Defines a single evaluation criterion used when assessing candidate components for adoption.',
)
@SectionId('EVCEN')
class EvaluationCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier, e.g. EC-001'),
    Field('criterion', String, 'Criterion Name',
        hint: 'Short name, e.g. Vendor Stability', required: true),
    Field('description', String, 'Description',
        hint: 'What this criterion evaluates'),
    Field('category', String, 'Category',
        hint:
            'Technical / Commercial / Operational / Strategic / Compliance'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scoring settings.
  @SerializationOrder(1)
  EvaluationCriterionEntryScoring scoring = EvaluationCriterionEntryScoring();

  /// Evaluation process.
  @SerializationOrder(2)
  EvaluationCriterionEntryProcess process = EvaluationCriterionEntryProcess();

  /// Scoring guidelines and scope.
  @SerializationOrder(3)
  EvaluationCriterionEntryGuidelines guidelines =
      EvaluationCriterionEntryGuidelines();
}

/// Scoring settings.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the software product quality evaluation process defines how evaluation criteria are established and applied',
  ],
  'Holds the scoring settings for a criterion including weight, scoring scale, minimum threshold, and eliminatory flag.',
)
@SectionId('EVCES')
class EvaluationCriterionEntryScoring {
  @Form([
    Field('weight', int, 'Weight (%)',
        hint: 'Relative importance as percentage of total score'),
    Field('scoringScale', String, 'Scoring Scale',
        hint: 'Scale used, e.g. 1-5, 1-10, Pass/Fail'),
    Field('minimumThreshold', String, 'Minimum Threshold',
        hint: 'Minimum acceptable score, e.g. 3 out of 5'),
    Field('eliminatory', String, 'Eliminatory',
        hint:
            'Yes / No — does failing this criterion disqualify the component?'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Evaluation process.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the software product quality evaluation process defines how evaluation criteria are established and applied',
  ],
  'Holds the evaluation process for a criterion including evidence required, evaluation method, evaluator role, and duration.',
)
@SectionId('EVCEP')
class EvaluationCriterionEntryProcess {
  @Form([
    Field('evidenceRequired', String, 'Evidence Required',
        hint:
            'What proof is needed — benchmark report, vendor attestation, demo'),
    Field('evaluationMethod', String, 'Evaluation Method',
        hint:
            'ProofOfConcept / ReferenceCheck / DocumentReview / LoadTest'),
    Field('evaluator', String, 'Evaluator Role',
        hint:
            'Who performs this evaluation — architect, security, procurement'),
    Field('evaluationDuration', String, 'Evaluation Duration',
        hint: 'Expected time to complete this evaluation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scoring guidelines and scope.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the software product quality evaluation process defines how evaluation criteria are established and applied',
  ],
  'Holds the scoring guidelines describing low, mid, and high scores and the component categories a criterion applies to.',
)
@SectionId('EVCEG')
class EvaluationCriterionEntryGuidelines {
  @Form([
    Field('scoringGuidelineLow', String, 'Score Low — Poor',
        hint: 'What a lowest-tier score looks like'),
    Field('scoringGuidelineMid', String, 'Score Mid — Acceptable',
        hint: 'What a mid-tier score looks like'),
    Field('scoringGuidelineHigh', String, 'Score High — Excellent',
        hint: 'What the highest score looks like'),
    Field('applicableTo', String, 'Applicable To',
        hint:
            'Which component categories this criterion applies to'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 12.2. Component Catalog
// ---------------------------------------------------------------------------

/// A component entry (form) with sub-entries.
///
/// Describes a single external or standard component planned for use:
/// vendor assessment, maturity, security, cost, deployment model, licensing,
/// interfaces, and responsibilities.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing component identity, versions, and licenses',
  ],
  'Captures the catalog entry describing one component including identity, vendor, and support profile.',
)
@SectionId('CMPNT')
class ComponentEntry {
  @Form([
    Field('componentId', String, 'Component ID',
        hint: 'Unique identifier, e.g. CMP-DB-001'),
    Field('componentName', String, 'Component Name',
        hint: 'Official product/library name', required: true),
    Field('category', String, 'Category',
        hint: 'Database / Framework / Library / Service / Middleware'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Vendor information.
  @SerializationOrder(1)
  ComponentVendor vendor = ComponentVendor();

  /// Maturity and community.
  @SerializationOrder(2)
  ComponentMaturity maturity = ComponentMaturity();

  /// Support.
  @SerializationOrder(3)
  ComponentSupport support = ComponentSupport();

  /// Security and performance.
  @SerializationOrder(4)
  ComponentPerformance performance = ComponentPerformance();

  /// Deployment.
  @SerializationOrder(5)
  ComponentDeployment deployment = ComponentDeployment();

  /// Cost.
  @SerializationOrder(6)
  ComponentCost cost = ComponentCost();

  /// Compliance and training.
  @SerializationOrder(7)
  ComponentCompliance compliance = ComponentCompliance();

  /// Risk assessment.
  @SerializationOrder(8)
  ComponentRisk risk = ComponentRisk();

  /// Documentation.
  @StandardReferences(
    [
      'ISO/IEC 5962:2021 — the SPDX specification records component documentation and provenance metadata in the software bill of materials',
    ],
    'Lists the documentation artifacts associated with the component.',
  )
  @SectionId('CODO-DOCS-LST')
  @SectionIdPattern('CODO-DOCS-xxx')
  @ContentHelp('Add one entry per component document.')
  @SerializationOrder(9)
  List<ComponentDocs> docs = [];

  /// Interfaces — contains 0+× ComponentInterface.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, interfaces, and their relationships are documented for stakeholders',
    ],
    'Lists the interfaces exposed or consumed by the component.',
  )
  @SectionId('CMIF-INTE-LST')
  @SectionIdPattern('CMIF-INTE-xxx')
  @ContentHelp('Add one entry per component interface.')
  @SerializationOrder(10)
  List<ComponentInterfaceEntry> interfaces = [];

  /// Licensing (form).
  @SerializationOrder(11)
  ComponentLicensingEntry? licensing;

  /// Usage Rights.
  @SerializationOrder(12)
  TextSection usageRights = TextSection();

  /// Responsibilities (form).
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the product quality model frames the functional responsibilities a component is accountable for within the system',
    ],
    'Lists the responsibilities assigned to the component.',
  )
  @SectionId('COREEN-RESP-LST')
  @SectionIdPattern('COREEN-RESP-xxx')
  @ContentHelp('Add one entry per component responsibility.')
  @SerializationOrder(13)
  List<ComponentResponsibilitiesEntry> responsibilities = [];
}

/// Vendor for component.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing component identity, versions, and licenses',
  ],
  'Captures the version, business purpose, vendor identity, and vendor stability for a component.',
)
@SectionId('CMPVD')
class ComponentVendor {
  @Form([
    Field('version', String, 'Version',
        hint: 'Current version in use or targeted'),
    Field('purpose', String, 'Business Purpose',
        hint: 'Why this component is needed in business terms'),
    Field('vendorName', String, 'Vendor / Publisher',
        hint: 'Company or organization behind the component'),
    Field('vendorStability', String, 'Vendor Stability Assessment',
        hint: 'Financial health, market position, acquisition risk'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Maturity for component.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model frames maintainability characteristics such as component maturity and modifiability',
  ],
  'Captures the maturity level, community health, and release cadence of a component.',
)
@SectionId('CMPMT')
class ComponentMaturity {
  @Form([
    Field('maturityLevel', String, 'Maturity Level',
        hint: 'Emerging / Growing / Mature / Declining / EndOfLife'),
    Field('communitySize', String, 'Community Health',
        hint: 'GitHub stars, contributors, forum activity'),
    Field('releaseFrequency', String, 'Release Cadence',
        hint: 'How often new versions are published'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Support for component.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification records component support and security tracking metadata in the software bill of materials',
  ],
  'Captures the support model, support tier, and security advisory source for a component.',
)
@SectionId('CMPSP')
class ComponentSupport {
  @Form([
    Field('supportModel', String, 'Support Model',
        hint: 'CommunityOnly / VendorPaid / Hybrid / ManagedService'),
    Field('supportTier', String, 'Support Tier',
        hint: 'Contracted support level, e.g. Enterprise Gold 24/7'),
    Field('securityTrackingUrl', String, 'Security Advisory URL',
        hint: 'CVE feed or security bulletin URL'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance for component.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model frames performance efficiency characteristics such as throughput, latency, and scalability limits',
  ],
  'Captures the performance benchmarks and scalability ceiling of a component.',
)
@SectionId('CMPPF')
class ComponentPerformance {
  @Form([
    Field('performanceBenchmark', String, 'Performance Characteristics',
        hint: 'Key throughput/latency figures'),
    Field('scalabilityLimit', String, 'Scalability Ceiling',
        hint: 'Known upper limits'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deployment for component.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification captures component deployment and resource metadata in the software bill of materials',
  ],
  'Captures the deployment model and resource footprint of a component.',
)
@SectionId('CMPDP')
class ComponentDeployment {
  @Form([
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'OnPremise / SaaS / PaaS / Hybrid / Container / Serverless'),
    Field('resourceFootprint', String, 'Resource Requirements',
        hint: 'CPU, memory, disk, network baseline requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cost for component.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification catalogs component identity and metadata against which total cost of ownership is tracked in the software bill of materials',
  ],
  'Captures the first-year and ongoing total cost of ownership for a component.',
)
@SectionId('COCO')
class ComponentCost {
  @Form([
    Field('totalCostFirstYear', String, 'First-Year TCO',
        hint: 'Total cost including license, infra, integration, training'),
    Field('totalCostOngoing', String, 'Annual Ongoing TCO',
        hint: 'Recurring annual cost after first year'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance for component.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification records component compliance certifications alongside identity and licensing in the software bill of materials',
  ],
  'Captures the compliance certifications and training requirements associated with a component.',
)
@SectionId('CC')
class ComponentCompliance {
  @Form([
    Field('complianceCertifications', String, 'Compliance Certifications',
        hint: 'SOC2, ISO 27001, HIPAA, FedRAMP, PCI-DSS, etc.'),
    Field('trainingRequirement', String, 'Training Requirement',
        hint: 'Estimated ramp-up effort'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Risk for component.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how a component fits into the system through its replacement difficulty, lock-in, and integration relationships',
  ],
  'Captures the replacement difficulty, lock-in factors, and integration complexity of a component within the system.',
)
@SectionId('CORI')
class ComponentRisk {
  @Form([
    Field('replacementDifficulty', String, 'Replacement Difficulty',
        hint: 'Low / Medium / High / Extreme — with justification'),
    Field('lockInFactors', String, 'Lock-In Factors',
        hint: 'Proprietary formats, data migration cost'),
    Field('integrationComplexity', String, 'Integration Complexity',
        hint: 'Effort to integrate — Low / Medium / High'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Docs for component.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification captures component documentation quality, links, and provenance in the software bill of materials',
  ],
  'Captures the documentation quality, links, and approval status recorded for a component.',
)
@SectionId('CODO')
class ComponentDocs {
  @Form([
    Field('documentationQuality', String, 'Documentation Quality',
        hint: 'Poor / Adequate / Good / Excellent'),
    Field('documentationUrl', String, 'Documentation URL',
        hint: 'Link to official documentation'),
    Field('approvalStatus', String, 'Approval Status',
        hint: 'Proposed / UnderReview / Approved / Rejected / Deprecated'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Name/role of person who approved this component'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A component interface entry (form).
///
/// Describes one interface exposed or consumed by a component: protocol,
/// authentication, data format, rate limits, versioning, SLA, monitoring.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, interfaces, and their relationships are documented for stakeholders',
    'ISO/IEC 25010:2023 — the product quality model frames compatibility and maintainability characteristics relevant to component integration',
  ],
  'Captures one interface exposed or consumed by a component covering protocol, authentication, data format, rate limits, versioning, SLA, and monitoring.',
)
@SectionId('CMIF')
class ComponentInterfaceEntry {
  @Form([
    Field('interfaceName', String, 'Interface Name',
        hint: 'Human-readable name, e.g. Order Service REST API'),
    Field('interfaceType', String, 'Interface Type',
        hint: 'REST / GraphQL / gRPC / WebSocket / MessageQueue / SDK / CLI / File'),
    Field('protocol', String, 'Protocol',
        hint: 'HTTP/1.1 / HTTP/2 / AMQP / MQTT / TCP / UDP'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Network configuration.
  @SerializationOrder(1)
  ComponentInterfaceEntryNetwork network = ComponentInterfaceEntryNetwork();

  /// Security settings.
  @SerializationOrder(2)
  ComponentInterfaceEntrySecurity security = ComponentInterfaceEntrySecurity();

  /// Data format configuration.
  @SerializationOrder(3)
  ComponentInterfaceEntryData data = ComponentInterfaceEntryData();

  /// SLA and monitoring.
  @SerializationOrder(4)
  ComponentInterfaceEntrySla sla = ComponentInterfaceEntrySla();

  /// Operations and documentation.
  @SerializationOrder(5)
  ComponentInterfaceEntryOperations operations =
      ComponentInterfaceEntryOperations();
}

/// Network configuration for component interface.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, interfaces, and their relationships are documented for stakeholders',
  ],
  'Captures network configuration for a component interface covering the default port, base path or endpoint, and rate limit.',
)
@SectionId('CIEN')
class ComponentInterfaceEntryNetwork {
  @Form([
    Field('port', int, 'Default Port',
        hint: 'Default network port, e.g. 443, 5432, 6379'),
    Field('basePath', String, 'Base Path / Endpoint',
        hint: 'Root URL or queue name, e.g. /api/v2, orders.events'),
    Field('rateLimitRequests', int, 'Rate Limit (req/min)',
        hint: 'Maximum requests per minute allowed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security settings for component interface.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, interfaces, and their relationships are documented for stakeholders',
  ],
  'Captures security settings for a component interface covering authentication method, authorization model, and TLS requirement.',
)
@SectionId('CIES')
class ComponentInterfaceEntrySecurity {
  @Form([
    Field('authenticationMethod', String, 'Authentication',
        hint: 'OAuth2 / APIKey / mTLS / SAML / BasicAuth / None'),
    Field('authorizationModel', String, 'Authorization Model',
        hint: 'RBAC / ABAC / ScopeBased / ACL — how permissions are enforced'),
    Field('tlsRequired', String, 'TLS Requirement',
        hint: 'Required / Optional / NotSupported, minimum TLS version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data format configuration for component interface.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, interfaces, and their relationships are documented for stakeholders',
    'ISO/IEC 25010:2023 — the product quality model frames compatibility and maintainability characteristics relevant to component integration',
  ],
  'Captures data format configuration for a component interface covering request and response formats, versioning scheme, current API version, and backward compatibility policy.',
)
@SectionId('CIED')
class ComponentInterfaceEntryData {
  @Form([
    Field('dataFormatRequest', String, 'Request Format',
        hint: 'JSON / XML / Protobuf / Avro / CSV / Binary'),
    Field('dataFormatResponse', String, 'Response Format',
        hint: 'JSON / XML / Protobuf / Avro / CSV / Binary'),
    Field('versioningScheme', String, 'Versioning Scheme',
        hint: 'URLPath / Header / QueryParam / ContentNegotiation'),
    Field('currentApiVersion', String, 'Current API Version',
        hint: 'Currently active version, e.g. v2.3'),
    Field('backwardCompatibility', String, 'Backward Compatibility Policy',
        hint: 'How breaking changes are handled and communicated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// SLA and monitoring for component interface.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model frames compatibility and maintainability characteristics relevant to component integration',
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, interfaces, and their relationships are documented for stakeholders',
  ],
  'Captures SLA and monitoring for a component interface covering availability, P99 latency, health check endpoint, and metrics endpoint.',
)
@SectionId('COINENSL')
class ComponentInterfaceEntrySla {
  @Form([
    Field('slaAvailability', String, 'Availability SLA',
        hint: 'Target uptime, e.g. 99.95%'),
    Field('slaLatencyP99', String, 'P99 Latency SLA',
        hint: '99th percentile response time target, e.g. <200ms'),
    Field('healthCheckEndpoint', String, 'Health Check Endpoint',
        hint: 'URL or mechanism for liveness/readiness probes'),
    Field('monitoringEndpoint', String, 'Metrics Endpoint',
        hint: 'Prometheus, StatsD, or custom metrics endpoint'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operations and documentation for component interface.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how components, interfaces, and their relationships are documented for stakeholders',
  ],
  'Captures operations and documentation for a component interface covering the recommended retry policy, documentation URL, and description.',
)
@SectionId('CIEO')
class ComponentInterfaceEntryOperations {
  @Form([
    Field('retryPolicy', String, 'Recommended Retry Policy',
        hint: 'Exponential backoff params, max retries, idempotency'),
    Field('documentationUrl', String, 'API Documentation URL',
        hint: 'Link to OpenAPI spec, SDK docs, or integration guide'),
    Field('description', String, 'Description',
        hint: 'Purpose and usage context for this interface'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Component licensing sub-entry (form).
///
/// Detailed licensing information: model, cost, compliance, open-source
/// obligations, audit requirements, geographic restrictions, usage metrics.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme',
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing component identity, versions, and licenses',
  ],
  'Captures the component licensing model covering license model, name, contract term, costs, usage rights, compliance restrictions, capacity rules, and termination terms.',
)
@SectionId('COLIEN')
class ComponentLicensingEntry {
  @Form([
    Field('licenseModel', String, 'License Model',
        hint:
            'PerSeat / PerCore / PerInstance / Site / Metered / OpenSource'),
    Field('licenseName', String, 'License Name / SPDX',
        hint:
            'SPDX identifier or commercial license name, e.g. Apache-2.0, Enterprise v3'),
    Field('contractTermLength', String, 'Contract Term',
        hint: 'Duration of the agreement, e.g. 3 years'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Cost and renewal details.
  @SerializationOrder(1)
  ComponentLicensingEntryCosts costs = ComponentLicensingEntryCosts();

  /// Usage rights and obligations.
  @SerializationOrder(2)
  ComponentLicensingEntryRights rights = ComponentLicensingEntryRights();

  /// Compliance restrictions.
  @SerializationOrder(3)
  ComponentLicensingEntryCompliance compliance =
      ComponentLicensingEntryCompliance();

  /// Metering and capacity rules.
  @SerializationOrder(4)
  ComponentLicensingEntryCapacity capacity = ComponentLicensingEntryCapacity();

  /// Contract termination terms.
  @SerializationOrder(5)
  ComponentLicensingEntryContract contract = ComponentLicensingEntryContract();
}

/// Cost and renewal details.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme',
  ],
  'Captures cost and renewal details for a component license covering initial cost, recurring cost, renewal date, and auto-renewal terms.',
)
@SectionId('CLEC')
class ComponentLicensingEntryCosts {
  @Form([
    Field('costInitial', String, 'Initial License Cost',
        hint: 'One-time purchase or setup fee'),
    Field('costRecurring', String, 'Recurring Cost',
        hint: 'Annual/monthly renewal amount'),
    Field('renewalDate', String, 'Renewal Date',
        hint: 'Next renewal deadline'),
    Field('autoRenewal', String, 'Auto-Renewal',
        hint: 'Yes / No — and cancellation notice period'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Usage rights and obligations.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme',
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing component identity, versions, and licenses',
  ],
  'Captures usage rights and obligations for a component license covering redistribution rights, sublicensing, open-source obligations, and copyleft scope.',
)
@SectionId('CLER')
class ComponentLicensingEntryRights {
  @Form([
    Field('redistributionRights', String, 'Redistribution Rights',
        hint:
            'Can the component be redistributed to end users or partners?'),
    Field('sublicensingAllowed', String, 'Sublicensing',
        hint:
            'Whether sublicensing to third parties is permitted'),
    Field('openSourceObligations', String, 'Open-Source Obligations',
        hint: 'Copyleft, attribution, source disclosure requirements'),
    Field('copyleftScope', String, 'Copyleft Scope',
        hint:
            'FileLevel / LibraryLevel / ProjectWide — copyleft impact'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance restrictions.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme',
  ],
  'Captures compliance restrictions for a component license covering vendor audit rights, geographic restrictions, and export control classification.',
)
@SectionId('COLIENCO')
class ComponentLicensingEntryCompliance {
  @Form([
    Field('auditRights', String, 'Vendor Audit Rights',
        hint:
            'Can vendor audit our usage? Frequency and notice period'),
    Field('geographicRestrictions', String, 'Geographic Restrictions',
        hint:
            'Countries or regions where use is prohibited or restricted'),
    Field('exportControlClassification', String, 'Export Control',
        hint: 'ECCN classification or export restriction category'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Metering and capacity rules.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme',
  ],
  'Captures metering and capacity rules for a component license covering the usage metric tracked, licensed capacity, and overage policy.',
)
@SectionId('COLIENCA')
class ComponentLicensingEntryCapacity {
  @Form([
    Field('usageMetricTracked', String, 'Usage Metric',
        hint:
            'What is metered — API calls, users, data volume, CPU hours'),
    Field('licensedCapacity', String, 'Licensed Capacity',
        hint: 'Maximum allowed under current license'),
    Field('overagePolicy', String, 'Overage Policy',
        hint:
            'What happens when capacity is exceeded — throttle, surcharge, block'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Contract termination terms.
@StandardReferences(
  [
    'ISO/IEC 5230:2020 — the OpenChain standard specifies the key requirements of a quality open-source license compliance programme',
  ],
  'Captures contract termination terms for a component license covering early termination penalties and data export rights.',
)
@SectionId('COMLICENTCON')
class ComponentLicensingEntryContract {
  @Form([
    Field('terminationClause', String, 'Termination Terms',
        hint: 'Early termination penalties and data export rights'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Component responsibilities sub-entry (form).
///
/// Who owns and maintains this component: primary/backup owners, SLA targets,
/// patch response time, security vulnerability handling, budget allocation.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model frames compatibility and maintainability characteristics relevant to component integration',
  ],
  'Captures component responsibilities covering primary and backup ownership, escalation path, vendor support, SLA targets, security operations, and governance.',
)
@SectionId('COREEN')
class ComponentResponsibilitiesEntry {
  @Form([
    Field('primaryOwner', String, 'Primary Owner',
        hint: 'Team or person primarily responsible'),
    Field('backupOwner', String, 'Backup Owner',
        hint: 'Secondary contact when primary is unavailable'),
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'Ordered escalation chain with roles and timeframes'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Vendor support details.
  @SerializationOrder(1)
  ComponentResponsibilitiesEntrySupport support =
      ComponentResponsibilitiesEntrySupport();

  /// SLA commitments.
  @SerializationOrder(2)
  ComponentResponsibilitiesEntrySla sla = ComponentResponsibilitiesEntrySla();

  /// Security and update operations.
  @SerializationOrder(3)
  ComponentResponsibilitiesEntryOperations operations =
      ComponentResponsibilitiesEntryOperations();

  /// Governance and planning.
  @SerializationOrder(4)
  ComponentResponsibilitiesEntryGovernance governance =
      ComponentResponsibilitiesEntryGovernance();
}

/// Vendor support details.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing component identity, versions, and licenses',
  ],
  'Captures vendor support details for a component covering the support contact and support hours.',
)
@SectionId('CRES')
class ComponentResponsibilitiesEntrySupport {
  @Form([
    Field('vendorSupportContact', String, 'Vendor Support Contact',
        hint: 'How to reach vendor support — portal, email, phone'),
    Field('vendorSupportHours', String, 'Vendor Support Hours',
        hint:
            'Availability window, e.g. 24/7 or Mon-Fri 9-17 CET'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// SLA commitments.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model frames compatibility and maintainability characteristics relevant to component integration',
  ],
  'Captures SLA commitments for a component covering uptime target, critical issue response time, and critical issue resolution time.',
)
@SectionId('COREENSL')
class ComponentResponsibilitiesEntrySla {
  @Form([
    Field('slaUptimeTarget', String, 'Uptime SLA Target',
        hint: 'Internal uptime commitment, e.g. 99.9%'),
    Field('slaResponseCritical', String, 'Critical Issue Response Time',
        hint: 'Max time to acknowledge a P1/critical incident'),
    Field('slaResolutionCritical', String, 'Critical Issue Resolution Time',
        hint: 'Max time to resolve or workaround a P1 incident'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security and update operations.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model frames compatibility and maintainability characteristics relevant to component integration',
  ],
  'Captures security and update operations for a component covering patch cadence, vulnerability handling, scan frequency, update strategy, change approval, and monitoring ownership.',
)
@SectionId('CREO')
class ComponentResponsibilitiesEntryOperations {
  @Form([
    Field('patchCadence', String, 'Patch Application Cadence',
        hint:
            'How quickly patches are applied, e.g. Critical: 24h, Normal: 14d'),
    Field('securityVulnProcess', String, 'Security Vulnerability Process',
        hint: 'Steps from CVE disclosure to remediation'),
    Field('securityScanFrequency', String, 'Security Scan Frequency',
        hint: 'How often dependency/vulnerability scans run'),
    Field('updateStrategy', String, 'Update Strategy',
        hint:
            'BlueGreen / Rolling / Canary / MaintenanceWindow'),
    Field('changeApprovalProcess', String, 'Change Approval Process',
        hint: 'Who approves upgrades and configuration changes'),
    Field('monitoringOwner', String, 'Monitoring Owner',
        hint: 'Who maintains dashboards and alerts'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance and planning.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model frames compatibility and maintainability characteristics relevant to component integration',
  ],
  'Captures governance and planning for a component covering knowledge base location, annual budget, review frequency, and capacity planning ownership.',
)
@SectionId('CREG')
class ComponentResponsibilitiesEntryGovernance {
  @Form([
    Field('knowledgeBaseLocation', String, 'Knowledge Base',
        hint: 'Where runbooks, FAQs, and tribal knowledge are stored'),
    Field('budgetAllocationAnnual', String, 'Annual Budget',
        hint:
            'Budget allocated for this component — license + ops + training'),
    Field('reviewFrequency', String, 'Review Frequency',
        hint:
            'How often the component is formally reviewed — quarterly, annually'),
    Field('capacityPlanningOwner', String, 'Capacity Planning Owner',
        hint: 'Who monitors usage and plans for growth'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 12.4. Runtime Dependencies
// ---------------------------------------------------------------------------

/// 12.4. Runtime Dependencies.
///
/// Runtime dependencies between components: required services, startup order,
/// health-check dependencies, failover behavior, and version constraints.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how system elements and their dependency relationships are documented',
  ],
  'Captures the runtime dependency graph governing required services, startup order, health checks, failover behavior, and version constraints.',
)
@SectionId('RUDE')
class RuntimeDependencies {
  @ContentHelp('''
## Runtime Dependencies (12.4)

Runtime dependencies between components.

### Dependency Properties
- **Startup order** — Boot sequence priority
- **Health checks** — Verification method and interval
- **Failover behavior** — Graceful degradation, circuit breaker
- **Version constraints** — Required versions or ranges
- **Criticality** — Impact if unavailable

### Dependency Types
- **Critical** — System cannot function without
- **Optional** — Enhances functionality but not required
- **Conditional** — Required only in specific configurations

### Documentation
For each dependency, document latency tolerance, caching
strategy, and fallback alternatives.
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Runtime Dependency.
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
    ],
    'Holds the list of runtime dependency entries governing startup order, health checks, and failover.',
  )
  @SectionId('RNDEP-ITEM-LST')
  @SectionIdPattern('RNDEP-ITEM-xxx')
  @ContentHelp('Add one entry per runtime dependency.')
  @SerializationOrder(1)
  List<RuntimeDependencyEntry> items = [];
}

/// 12.5. Maintenance Dependencies.
///
/// Maintenance dependencies: version compatibility matrix, coordinated
/// update sequences, and breaking-change handling.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics such as modularity, modifiability, and testability',
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing components, versions, and provenance',
  ],
  'Captures the maintenance dependency graph governing the version compatibility matrix, coordinated update sequences, and breaking-change handling.',
)
@SectionId('MADE')
class MaintenanceDependencies {
  @ContentHelp('''
## Maintenance Dependencies (12.5)

Maintenance relationships and update coordination.

### Compatibility Matrix
- Version compatibility between components
- Breaking change impact analysis
- Required coordinated updates

### Update Sequences
- Dependent component update order
- Rollback procedures
- Compatibility windows

### Lifecycle Management
- End-of-life monitoring
- Migration planning
- Deprecation handling
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Maintenance Dependency.
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics such as modularity, modifiability, and testability',
    ],
    'Holds the list of maintenance dependency entries governing version compatibility and coordinated updates.',
  )
  @SectionId('MNDEP-ITEM-LST')
  @SectionIdPattern('MNDEP-ITEM-xxx')
  @ContentHelp('Add one entry per maintenance dependency.')
  @SerializationOrder(1)
  List<MaintenanceDependencyEntry> items = [];
}

/// A runtime dependency entry (form).
///
/// Documents one runtime dependency: startup order, health checks,
/// failover, data flow, latency tolerance, and caching strategy.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
    'ISO/IEC/IEEE 42010:2022 — the architecture description standard frames how system elements and their dependency relationships are documented',
  ],
  'Documents one runtime dependency covering startup order, health checks, failover, data flow, latency tolerance, and caching strategy.',
)
@SectionId('RNDEP')
class RuntimeDependencyEntry {
  @Form([
    Field('dependencyId', String, 'Dependency ID',
        hint: 'Unique identifier, e.g. DEP-R-001'),
    Field('name', String, 'Dependency Name',
        hint: 'Component or service depended upon', required: true),
    Field('version', String, 'Required Version',
        hint: 'Version or version range required'),
    Field('dependencyType', String, 'Dependency Type',
        hint: 'Runtime / Optional / Peer / Conditional'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Versioning and business criticality.
  @SerializationOrder(1)
  RuntimeDependencyEntryClassification classification =
      RuntimeDependencyEntryClassification();

  /// Startup and health behavior.
  @SerializationOrder(2)
  RuntimeDependencyEntryStartup startup = RuntimeDependencyEntryStartup();

  /// Resilience behavior.
  @SerializationOrder(3)
  RuntimeDependencyEntryResilience resilience =
      RuntimeDependencyEntryResilience();

  /// Data flow and network characteristics.
  @SerializationOrder(4)
  RuntimeDependencyEntryIntegration integration =
      RuntimeDependencyEntryIntegration();

  /// Compatibility and transitive risk notes.
  @SerializationOrder(5)
  RuntimeDependencyEntryRisk risk = RuntimeDependencyEntryRisk();
}

/// Versioning and business criticality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
  ],
  'Captures the version constraint, criticality, and purpose that classify one runtime dependency.',
)
@SectionId('RDEC')
class RuntimeDependencyEntryClassification {
  @Form([
    Field('versionConstraint', String, 'Version Constraint',
        hint: 'Pinned / Range / Minimum, e.g. >=3.2 <4.0'),
    Field('criticality', String, 'Criticality',
        hint:
            'Critical / High / Medium / Low — impact if unavailable'),
    Field('purpose', String, 'Purpose',
        hint: 'Why this dependency exists'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Startup and health behavior.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
  ],
  'Captures startup order, startup timeout, and health-check method and interval for one runtime dependency.',
)
@SectionId('RDES')
class RuntimeDependencyEntryStartup {
  @Form([
    Field('startupOrder', int, 'Startup Order',
        hint: 'Boot sequence priority (1 = first)'),
    Field('startupTimeout', String, 'Startup Timeout',
        hint: 'Max wait time before declaring startup failure'),
    Field('healthCheckMethod', String, 'Health Check',
        hint:
            'How to verify this dependency is healthy — endpoint, ping, query'),
    Field('healthCheckInterval', String, 'Health Check Interval',
        hint: 'How often health is verified, e.g. 30s'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Resilience behavior.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
  ],
  'Captures failover behavior, fallback alternatives, and caching strategy for one runtime dependency.',
)
@SectionId('RDER')
class RuntimeDependencyEntryResilience {
  @Form([
    Field('failoverBehavior', String, 'Failover Behavior',
        hint:
            'GracefulDegradation / CircuitBreaker / Retry / FailFast'),
    Field('fallbackComponent', String, 'Fallback / Alternative',
        hint:
            'What to use if this dependency fails or is unavailable'),
    Field('cacheStrategy', String, 'Caching Strategy',
        hint:
            'How responses/data from this dependency are cached'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data flow and network characteristics.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
  ],
  'Captures the data flow direction, network requirement, and latency tolerance for one runtime dependency.',
)
@SectionId('RDEI')
class RuntimeDependencyEntryIntegration {
  @Form([
    Field('dataFlowDirection', String, 'Data Flow',
        hint:
            'ReadOnly / WriteOnly / Bidirectional / EventDriven'),
    Field('networkRequired', String, 'Network Requirement',
        hint:
            'Local / LAN / Internet — and impact of network partition'),
    Field('latencyTolerance', String, 'Latency Tolerance',
        hint: 'Max acceptable latency to this dependency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compatibility and transitive risk notes.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines reliability sub-characteristics such as availability, fault tolerance, and recoverability',
  ],
  'Captures transitive dependency risk and compatibility notes for one runtime dependency.',
)
@SectionId('RUDEENRI')
class RuntimeDependencyEntryRisk {
  @Form([
    Field('transitiveRisk', String, 'Transitive Dependency Risk',
        hint:
            'Key risks from this dependency\'s own dependencies'),
    Field('compatibilityMatrix', String, 'Compatibility Notes',
        hint:
            'Known incompatibilities with other components in our stack'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A maintenance dependency entry (form).
///
/// Documents one maintenance dependency: coordinated update sequences,
/// version compatibility, and breaking-change handling.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics such as modularity, modifiability, and testability',
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing components, versions, and provenance',
  ],
  'Documents one maintenance dependency covering coordinated update sequences, version compatibility, and breaking-change handling.',
)
@SectionId('MNDEP')
class MaintenanceDependencyEntry {
  @Form([
    Field('dependencyId', String, 'Dependency ID',
        hint: 'Unique identifier, e.g. DEP-M-001'),
    Field('name', String, 'Dependency Name',
        hint: 'Component or service with maintenance dependency',
        required: true),
    Field('version', String, 'Current Version',
        hint: 'Version currently in use'),
    Field('versionConstraint', String, 'Version Constraint',
        hint: 'Acceptable version range, e.g. >=3.2 <4.0'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Classification and purpose.
  @SerializationOrder(1)
  MaintenanceDependencyEntryClassification classification =
      MaintenanceDependencyEntryClassification();

  /// Update coordination.
  @SerializationOrder(2)
  MaintenanceDependencyEntryUpdate update = MaintenanceDependencyEntryUpdate();

  /// Risk and fallback planning.
  @SerializationOrder(3)
  MaintenanceDependencyEntryRisk risk = MaintenanceDependencyEntryRisk();
}

/// Classification and purpose.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics such as modularity, modifiability, and testability',
  ],
  'Captures the dependency type, criticality, and purpose that classify one maintenance dependency.',
)
@SectionId('MDEC')
class MaintenanceDependencyEntryClassification {
  @Form([
    Field('dependencyType', String, 'Dependency Type',
        hint: 'BuildTime / TestOnly / DevOnly / Tooling'),
    Field('criticality', String, 'Criticality',
        hint:
            'Critical / High / Medium / Low — impact if update breaks'),
    Field('purpose', String, 'Purpose',
        hint: 'Why this maintenance dependency exists'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Update coordination.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the product quality model defines maintainability sub-characteristics such as modularity, modifiability, and testability',
  ],
  'Captures update strategy, frequency, coordinated update sequence, and breaking-change policy for one maintenance dependency.',
)
@SectionId('MDEU')
class MaintenanceDependencyEntryUpdate {
  @Form([
    Field('updateStrategy', String, 'Update Strategy',
        hint:
            'How dependency updates are adopted — auto, manual review, staged'),
    Field('updateFrequency', String, 'Update Frequency',
        hint:
            'How often we update this dependency — weekly, monthly, quarterly'),
    Field('coordinatedUpdateSequence', String, 'Coordinated Update Sequence',
        hint:
            'Order in which related components must be updated together'),
    Field('breakingChangePolicy', String, 'Breaking Change Policy',
        hint:
            'How breaking changes are handled — pin version, adapt, delay'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Risk and fallback planning.
@StandardReferences(
  [
    'ISO/IEC 5962:2021 — the SPDX specification defines a standard software bill of materials format capturing components, versions, and provenance',
  ],
  'Captures compatibility notes, alternatives, transitive dependency risk, and security patch SLA for one maintenance dependency.',
)
@SectionId('MDER')
class MaintenanceDependencyEntryRisk {
  @Form([
    Field('compatibilityMatrix', String, 'Compatibility Notes',
        hint:
            'Known incompatibilities with other components in our stack'),
    Field('alternative', String, 'Alternative',
        hint: 'Replacement if this dependency is abandoned or EOL'),
    Field('transitiveRisk', String, 'Transitive Dependency Risk',
        hint:
            'Key risks from this dependency\'s own dependencies'),
    Field('securityPatchSla', String, 'Security Patch SLA',
        hint:
            'How quickly security patches must be applied, e.g. Critical: 24h'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 12.6. Risk Assessment
// ---------------------------------------------------------------------------

/// 12.6. Risk Assessment.
///
/// Component risk assessment: identified risks with probability/impact,
/// monitoring, mitigation strategies, and contingency plans.
@StandardReferences(
  [
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Captures the component-level risk assessment governing risk identification, monitoring, mitigation, and contingency planning.',
)
@SectionId('CORIAS')
class ComponentRiskAssessment {
  @ContentHelp('''
## Risk Assessment (12.6)

Component risk assessment and contingency planning.

### Risk Categories
- **Vendor risks** — Abandonment, acquisition, pricing changes
- **Technical risks** — Security vulnerabilities, performance
- **Licensing risks** — License changes, compliance issues
- **Operational risks** — Support quality, documentation gaps

### Risk Analysis
Each risk includes:
- Probability and impact
- Current mitigation status
- Monitoring approach
- Escalation triggers

### Subsections
- **12.6.1 Component Risks** — Individual risk entries
- **12.6.2 Contingency Plans** — Response plans for critical risks
''')
  @SerializationOrder(0)
  String? content;

  /// 12.6.1. Component Risks — contains 0+× Risk.
  @StandardReferences(
    [
      'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
    ],
    'Lists the individual component risk entries identified for the component.',
  )
  @SectionId('CMRS-RISK-LST')
  @SectionIdPattern('CMRS-RISK-xxx')
  @ContentHelp('Add one entry per component risk.')
  @SerializationOrder(1)
  List<ComponentRiskEntry> risks = [];

  /// 12.6.2. Contingency Plans.
  @SerializationOrder(2)
  ContingencyPlans contingencyPlans = ContingencyPlans();
}

/// 12.6.2. Contingency Plans.
///
/// Container for contingency plans addressing critical component risks.
@StandardReferences(
  [
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Contains the contingency plans that respond to critical component risk events.',
)
@SectionId('CONPLA')
class ContingencyPlans {
  @ContentHelp('''
## Contingency Plans (12.6.2)

Plans for responding to component risk events.

### Plan Components
- **Trigger conditions** — What activates the plan
- **Immediate actions** — Containment steps
- **Recovery actions** — Full restoration
- **RTO/RPO** — Recovery time/point objectives
- **Communication** — Internal and external messaging

### Testing
- Tabletop exercises
- Simulated failures
- Post-test improvements

### Dependencies
Document tools, access, and backups required to execute.
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× ContingencyPlan.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
    ],
    'Lists the contingency plan entries defined for critical component risks.',
  )
  @SectionId('COPL-ITEM-LST')
  @SectionIdPattern('COPL-ITEM-xxx')
  @ContentHelp('Add one entry per contingency plan.')
  @SerializationOrder(1)
  List<ContingencyPlanEntry> items = [];
}

/// A contingency plan entry (form).
///
/// Describes one contingency plan for a component risk: trigger conditions,
/// immediate/recovery actions, RTO/RPO, communication, testing frequency.
@StandardReferences(
  [
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
  ],
  'Describes a single contingency plan entry for a component risk, spanning references, actions, responsibility, communication, and testing.',
)
@SectionId('COPL')
class ContingencyPlanEntry {
  @Form([
    Field('contingencyId', String, 'Contingency Plan ID',
        hint: 'Unique identifier, e.g. CP-001'),
    Field('planTitle', String, 'Plan Title',
        hint: 'Short name for this contingency plan', required: true),
    Field('triggerCondition', String, 'Trigger Condition',
        hint: 'Specific event or threshold that activates this plan'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Reference links to risk and component.
  @SerializationOrder(1)
  ContingencyPlanEntryReferences references = ContingencyPlanEntryReferences();

  /// Action steps: trigger detection, immediate, and recovery.
  @SerializationOrder(2)
  ContingencyPlanEntryActions actions = ContingencyPlanEntryActions();

  /// Responsibility and recovery targets.
  @SerializationOrder(3)
  ContingencyPlanEntryResponsibility responsibility =
      ContingencyPlanEntryResponsibility();

  /// Communication plans.
  @SerializationOrder(4)
  ContingencyPlanEntryCommunication communication =
      ContingencyPlanEntryCommunication();

  /// Testing and resources.
  @SerializationOrder(5)
  ContingencyPlanEntryTesting testing = ContingencyPlanEntryTesting();
}

/// Reference links for contingency plan.
@StandardReferences(
  [
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Holds the reference links tying a contingency plan to its associated risk and component.',
)
@SectionId('CPER')
class ContingencyPlanEntryReferences {
  @Form([
    Field('riskRef', String, 'Associated Risk',
        hint: 'Risk ID this plan addresses'),
    Field('componentRef', String, 'Component',
        hint: 'Component ID this plan covers'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Action steps for contingency plan.
@StandardReferences(
  [
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Defines the action steps for a contingency plan, covering trigger detection, immediate containment actions, and recovery actions.',
)
@SectionId('CPEA')
class ContingencyPlanEntryActions {
  @Form([
    Field('triggerDetection', String, 'Trigger Detection',
        hint: 'How the trigger is detected — alert, manual report, monitoring'),
    Field('immediateActions', String, 'Immediate Actions',
        hint: 'First steps within minutes of trigger (containment)'),
    Field('recoveryActions', String, 'Recovery Actions',
        hint: 'Steps to restore full operation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Responsibility and recovery targets for contingency plan.
@StandardReferences(
  [
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Records responsibility assignments and recovery targets for a contingency plan, including the responsible party, support teams, RTO, and RPO.',
)
@SectionId('COPLENRE')
class ContingencyPlanEntryResponsibility {
  @Form([
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Primary person/team who executes this plan'),
    Field('supportTeams', String, 'Support Teams',
        hint: 'Additional teams involved in execution'),
    Field('targetRecoveryTime', String, 'Target Recovery Time (RTO)',
        hint: 'Maximum acceptable downtime'),
    Field('targetRecoveryPoint', String, 'Target Recovery Point (RPO)',
        hint: 'Maximum acceptable data loss window'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication plans for contingency.
@StandardReferences(
  [
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Holds the communication plans for a contingency, covering internal notification order and external customer messaging.',
)
@SectionId('CPEC')
class ContingencyPlanEntryCommunication {
  @Form([
    Field('communicationPlan', String, 'Communication Plan',
        hint: 'Who is notified, how, and in what order'),
    Field('customerCommunication', String, 'Customer Communication',
        hint: 'External messaging template or process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and resources for contingency plan.
@StandardReferences(
  [
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Captures testing cadence and execution resources for a contingency plan, including test frequency, last test result, dependencies, and fallback plan.',
)
@SectionId('CPET')
class ContingencyPlanEntryTesting {
  @Form([
    Field('testingFrequency', String, 'Testing Frequency',
        hint: 'How often this plan is tested — quarterly, annually'),
    Field('lastTestedDate', String, 'Last Tested Date',
        hint: 'When this plan was last exercised'),
    Field('lastTestResult', String, 'Last Test Result',
        hint: 'Pass / Fail and key findings from last test'),
    Field('dependencies', String, 'Plan Dependencies',
        hint: 'What this plan requires to execute — tools, access, backups'),
    Field('estimatedCost', String, 'Execution Cost',
        hint: 'Estimated cost of executing this contingency'),
    Field('priority', String, 'Priority',
        hint: 'Relative priority if multiple plans compete for resources'),
    Field('fallbackPlan', String, 'Fallback Plan',
        hint: 'What to do if this contingency plan itself fails'),
    Field('documentLocation', String, 'Runbook Location',
        hint: 'Where the detailed step-by-step runbook is stored'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A component risk entry (form).
///
/// Documents one component risk: category, probability, impact, detection
/// methods, mitigation strategy and status, residual risk, and ownership.
@StandardReferences(
  [
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Documents a single component risk entry spanning description, assessment, detection, mitigation, and governance.',
)
@SectionId('CMRS')
class ComponentRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID',
        hint: 'Unique identifier, e.g. CR-001', required: true),
    Field('componentRef', String, 'Component',
        hint: 'Component ID this risk applies to'),
    Field('riskTitle', String, 'Risk Title',
        hint: 'Short descriptive name'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Risk description and categorization.
  @SerializationOrder(1)
  ComponentRiskEntryDescription description = ComponentRiskEntryDescription();

  /// Risk assessment.
  @SerializationOrder(2)
  ComponentRiskEntryAssessment assessment = ComponentRiskEntryAssessment();

  /// Detection and monitoring.
  @SerializationOrder(3)
  ComponentRiskEntryDetection detection = ComponentRiskEntryDetection();

  /// Mitigation strategy.
  @SerializationOrder(4)
  ComponentRiskEntryMitigation mitigation = ComponentRiskEntryMitigation();

  /// Governance and ownership.
  @SerializationOrder(5)
  ComponentRiskEntryGovernance governance = ComponentRiskEntryGovernance();
}

/// Risk description and categorization.
@StandardReferences(
  [
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
  ],
  'Provides the description and categorization of a component risk, including the risk scenario and its risk category.',
)
@SectionId('CRED')
class ComponentRiskEntryDescription {
  @Form([
    Field('riskDescription', String, 'Risk Description',
        hint: 'Detailed explanation of the risk scenario'),
    Field('riskCategory', String, 'Risk Category',
        hint: 'Technical / Vendor / Security / Compliance / Operational / Financial'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Risk assessment for component risk.
@StandardReferences(
  [
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
  ],
  'Records the assessment of a component risk, including probability, business impact, risk score, and risk trend.',
)
@SectionId('CREA')
class ComponentRiskEntryAssessment {
  @Form([
    Field('probability', String, 'Probability',
        hint: 'VeryLow / Low / Medium / High / VeryHigh'),
    Field('impact', String, 'Business Impact',
        hint: 'Negligible / Minor / Moderate / Major / Critical'),
    Field('riskScore', int, 'Risk Score',
        hint: 'Calculated score (probability × impact)'),
    Field('riskTrend', String, 'Risk Trend',
        hint: 'Increasing / Stable / Decreasing — direction since last review'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Detection and monitoring for component risk.
@StandardReferences(
  [
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
  ],
  'Describes how a component risk is detected and monitored, covering detection methods, early warning indicators, and monitoring mechanisms.',
)
@SectionId('CORIENDE')
class ComponentRiskEntryDetection {
  @Form([
    Field('detectionMethod', String, 'Detection Method',
        hint: 'How we would know this risk is materializing'),
    Field('earlyWarningIndicators', String, 'Early Warning Indicators',
        hint: 'Metrics or signals that precede this risk event'),
    Field('monitoringMechanism', String, 'Monitoring',
        hint: 'Dashboards, alerts, or scans that track this risk'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mitigation strategy for component risk.
@StandardReferences(
  [
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
    'ISO/IEC/IEEE 16085:2021 — the risk management process for systems and software engineering defines risk treatment, contingency, and monitoring activities',
  ],
  'Holds the mitigation strategy for a component risk, including status, cost, residual risk level, and the contingency trigger.',
)
@SectionId('CREM')
class ComponentRiskEntryMitigation {
  @Form([
    Field('mitigationStrategy', String, 'Mitigation Strategy',
        hint: 'Actions to reduce probability or impact'),
    Field('mitigationStatus', String, 'Mitigation Status',
        hint: 'NotStarted / InProgress / Implemented / Verified'),
    Field('mitigationCost', String, 'Mitigation Cost',
        hint: 'Budget required to implement mitigation'),
    Field('residualRisk', String, 'Residual Risk Level',
        hint: 'Risk level remaining after mitigation — Low / Medium / High'),
    Field('contingencyTrigger', String, 'Contingency Trigger',
        hint: 'Condition activating the contingency plan, e.g. No release for 12 months'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance and ownership for component risk.
@StandardReferences(
  [
    'ISO 31000:2018 — the risk management guidelines define principles and a process for identifying, assessing, and treating risk',
  ],
  'Captures governance and ownership assignments for a component risk, including the risk owner, review frequency, and acceptance criteria.',
)
@SectionId('CORIENGO')
class ComponentRiskEntryGovernance {
  @Form([
    Field('riskOwner', String, 'Risk Owner',
        hint: 'Person accountable for managing this risk'),
    Field('reviewFrequency', String, 'Review Frequency',
        hint: 'How often this risk is reassessed'),
    Field('relatedRisks', String, 'Related Risks',
        hint: 'Other risk IDs that correlate or cascade'),
    Field('acceptanceCriteria', String, 'Risk Acceptance Criteria',
        hint: 'Under what conditions is this risk formally accepted'),
  ])
  @SerializationOrder(0)
  String? content;
}
