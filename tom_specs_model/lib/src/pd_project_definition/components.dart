/// Section 12: Components to Use [PD00-COM]. Seeds → TR.
///
/// External and standard components planned for use in the system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 12. Components to Use [PD00-COM]. Seeds → TR.
///
/// External and standard components planned for use in the system. All
/// subsections seed the TR document, where component choices are expanded
/// into detailed dependency analysis, version requirements, licensing,
/// and integration patterns.
@SectionId('PD00-COM')
@Comment('Seeds → TR')
@MapsTo(TechnicalRequirementsSpec)
@DetailedIn(TechnicalRequirementsSpec)
@SecondLevelSectionId(TechnicalRequirementsSpec, 'TR-COM')
class ComponentsToUse {
    @ContentHelp('''
## Components to Use (Chapter 12)

External and standard components planned for the system.

### Subsections
- **12.1 Component Strategy** — Build vs buy, governance, evaluation cadence
- **12.2 Component Catalog** — Individual component specifications
- **12.3 Component Role in System** — Mapping to architecture
- **12.4 Runtime Dependencies** — Startup order, health checks, failover
- **12.5 Maintenance Dependencies** — Version matrix, update sequences
- **12.6 Risk Assessment** — Component risks and contingency plans

### Seeds
All subsections seed the **TR (Technical Requirements)** document.

### Specification Depth
Each component should specify:
- Identity (name, version, vendor)
- Licensing and costs
- Integration interfaces
- Security baseline
- Support model
- Risk profile
''')
    String? content;

    /// 12.1. Component Strategy [PD00-COM-STR].
    ComponentStrategy strategy = ComponentStrategy();

    /// 12.2. Component Catalog [PD00-COM-COM] — contains 0+× Component.
    @SectionIdPattern('PD00-COM-COM-xx')
    List<ComponentEntry> componentCatalog = [];

    /// 12.3. Component Role In System [PD00-COM-ROL].
    @SectionId('PD00-COM-ROL')
    TextSection componentRoleInSystem = TextSection();

    /// 12.4. Runtime Dependencies [PD00-COM-RUN].
    RuntimeDependencies runtimeDependencies = RuntimeDependencies();

    /// 12.5. Maintenance Dependencies [PD00-COM-MAI].
    MaintenanceDependencies maintenanceDependencies = MaintenanceDependencies();

    /// 12.6. Risk Assessment [PD00-COM-RIS].
    ComponentRiskAssessment riskAssessment = ComponentRiskAssessment();
}

// ---------------------------------------------------------------------------
// 12.1. Component Strategy
// ---------------------------------------------------------------------------

/// 12.1. Component Strategy [PD00-COM-STR].
///
/// Overall component strategy: build-vs-buy philosophy, preferred vendors,
/// technology stack alignment, governance, evaluation cadence, and portfolio
/// management.
@SectionId('PD00-COM-STR')
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
    String? content;

    /// Vendor preferences and exceptions.
    ComponentStrategyVendors vendors = ComponentStrategyVendors();

    /// Governance and evaluation process.
    ComponentStrategyGovernance governance = ComponentStrategyGovernance();

    /// Portfolio management settings.
    ComponentStrategyPortfolio portfolio = ComponentStrategyPortfolio();

    /// Policy and baseline requirements.
    ComponentStrategyPolicies policies = ComponentStrategyPolicies();

    /// Budget and pilot planning.
    ComponentStrategyPlanning planning = ComponentStrategyPlanning();

    /// 12.1.1. Reuse Goals [PD00-COM-STR-GOA] — contains 0+× ReuseGoal.
    @SectionIdPattern('PD00-COM-STR-GOA-xx')
    List<ReuseGoalEntry> reuseGoals = [];

    /// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
    EvaluationCriteria evaluationCriteria = EvaluationCriteria();
}

/// Vendor preferences and exceptions.
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
    String? content;
}

/// Governance and evaluation process.
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
    String? content;
}

/// Portfolio management settings.
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
    String? content;
}

/// Policy and baseline requirements.
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
    String? content;
}

/// Budget and pilot planning.
class ComponentStrategyPlanning {
    @Form([
        Field('pilotProcessDescription', String, 'Pilot Process',
                hint:
                        'How new components are piloted before full adoption'),
        Field('totalPortfolioBudget', String, 'Total Component Budget',
                hint:
                        'Annual budget ceiling for all component costs'),
    ])
    String? content;
}

/// A reuse goal entry (form) [PD00-COM-STR-GOA-nn].
///
/// Defines a specific reuse target: what to reuse, why, at what percentage,
/// how to measure, and who owns the goal.
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
  String? content;

  /// Measurement and scope.
  ReuseGoalEntryMeasurement measurement = ReuseGoalEntryMeasurement();

  /// Governance and ownership.
  ReuseGoalEntryGovernance governance = ReuseGoalEntryGovernance();

  /// Delivery support and assets.
  ReuseGoalEntryEnablement enablement = ReuseGoalEntryEnablement();
}

/// Measurement and scope.
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
  String? content;
}

/// Governance and ownership.
class ReuseGoalEntryGovernance {
  @Form([
    Field('priority', String, 'Priority',
        hint: 'Critical / High / Medium / Low'),
    Field('targetDate', String, 'Target Date',
        hint: 'When this goal should be achieved'),
    Field('owner', String, 'Goal Owner',
        hint: 'Person or team responsible for driving this goal'),
  ])
  String? content;
}

/// Delivery support and assets.
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
  String? content;
}

/// 12.1.2. Evaluation Criteria [PD00-COM-STR-EVA].
///
/// Container for component evaluation criteria used when assessing
/// candidate components for adoption.
@SectionId('PD00-COM-STR-EVA')
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
  String? content;

  /// Contains 0+× EvaluationCriterion.
  @SectionIdPattern('PD00-COM-STR-EVA-xx')
  List<EvaluationCriterionEntry> items = [];
}

/// An evaluation criterion entry (form) [PD00-COM-STR-EVA-nn].
///
/// Defines one criterion for evaluating candidate components: scoring scale,
/// threshold, evidence requirements, and evaluation method.
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
  String? content;

  /// Scoring settings.
  EvaluationCriterionEntryScoring scoring = EvaluationCriterionEntryScoring();

  /// Evaluation process.
  EvaluationCriterionEntryProcess process = EvaluationCriterionEntryProcess();

  /// Scoring guidelines and scope.
  EvaluationCriterionEntryGuidelines guidelines =
      EvaluationCriterionEntryGuidelines();
}

/// Scoring settings.
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
  String? content;
}

/// Evaluation process.
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
  String? content;
}

/// Scoring guidelines and scope.
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
  String? content;
}

// ---------------------------------------------------------------------------
// 12.2. Component Catalog
// ---------------------------------------------------------------------------

/// A component entry [PD00-COM-COM-nn] (form) with sub-entries.
///
/// Describes a single external or standard component planned for use:
/// vendor assessment, maturity, security, cost, deployment model, licensing,
/// interfaces, and responsibilities.
class ComponentEntry {
  @Form([
    Field('componentId', String, 'Component ID',
        hint: 'Unique identifier, e.g. CMP-DB-001'),
    Field('componentName', String, 'Component Name',
        hint: 'Official product/library name', required: true),
    Field('category', String, 'Category',
        hint: 'Database / Framework / Library / Service / Middleware'),
  ])
  String? content;

  /// Vendor information.
  final ComponentVendor vendor = ComponentVendor();

  /// Maturity and community.
  final ComponentMaturity maturity = ComponentMaturity();

  /// Support.
  final ComponentSupport support = ComponentSupport();

  /// Security and performance.
  final ComponentPerformance performance = ComponentPerformance();

  /// Deployment.
  final ComponentDeployment deployment = ComponentDeployment();

  /// Cost.
  final ComponentCost cost = ComponentCost();

  /// Compliance and training.
  final ComponentCompliance compliance = ComponentCompliance();

  /// Risk assessment.
  final ComponentRisk risk = ComponentRisk();

  /// Documentation.
  final ComponentDocs docs = ComponentDocs();

  /// Interfaces [PD00-COM-COM-nn-INT] — contains 0+× ComponentInterface.
  @SectionIdPattern('PD00-COM-COM-xx-INT-xx')
  List<ComponentInterfaceEntry> interfaces = [];

  /// Licensing [PD00-COM-COM-nn-LIC] (form).
  ComponentLicensingEntry? licensing;

  /// Usage Rights [PD00-COM-COM-nn-USE].
  TextSection usageRights = TextSection();

  /// Responsibilities [PD00-COM-COM-nn-RES] (form).
  ComponentResponsibilitiesEntry? responsibilities;
}

/// Vendor for component.
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
  String? content;
}

/// Maturity for component.
class ComponentMaturity {
  @Form([
    Field('maturityLevel', String, 'Maturity Level',
        hint: 'Emerging / Growing / Mature / Declining / EndOfLife'),
    Field('communitySize', String, 'Community Health',
        hint: 'GitHub stars, contributors, forum activity'),
    Field('releaseFrequency', String, 'Release Cadence',
        hint: 'How often new versions are published'),
  ])
  String? content;
}

/// Support for component.
class ComponentSupport {
  @Form([
    Field('supportModel', String, 'Support Model',
        hint: 'CommunityOnly / VendorPaid / Hybrid / ManagedService'),
    Field('supportTier', String, 'Support Tier',
        hint: 'Contracted support level, e.g. Enterprise Gold 24/7'),
    Field('securityTrackingUrl', String, 'Security Advisory URL',
        hint: 'CVE feed or security bulletin URL'),
  ])
  String? content;
}

/// Performance for component.
class ComponentPerformance {
  @Form([
    Field('performanceBenchmark', String, 'Performance Characteristics',
        hint: 'Key throughput/latency figures'),
    Field('scalabilityLimit', String, 'Scalability Ceiling',
        hint: 'Known upper limits'),
  ])
  String? content;
}

/// Deployment for component.
class ComponentDeployment {
  @Form([
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'OnPremise / SaaS / PaaS / Hybrid / Container / Serverless'),
    Field('resourceFootprint', String, 'Resource Requirements',
        hint: 'CPU, memory, disk, network baseline requirements'),
  ])
  String? content;
}

/// Cost for component.
class ComponentCost {
  @Form([
    Field('totalCostFirstYear', String, 'First-Year TCO',
        hint: 'Total cost including license, infra, integration, training'),
    Field('totalCostOngoing', String, 'Annual Ongoing TCO',
        hint: 'Recurring annual cost after first year'),
  ])
  String? content;
}

/// Compliance for component.
class ComponentCompliance {
  @Form([
    Field('complianceCertifications', String, 'Compliance Certifications',
        hint: 'SOC2, ISO 27001, HIPAA, FedRAMP, PCI-DSS, etc.'),
    Field('trainingRequirement', String, 'Training Requirement',
        hint: 'Estimated ramp-up effort'),
  ])
  String? content;
}

/// Risk for component.
class ComponentRisk {
  @Form([
    Field('replacementDifficulty', String, 'Replacement Difficulty',
        hint: 'Low / Medium / High / Extreme — with justification'),
    Field('lockInFactors', String, 'Lock-In Factors',
        hint: 'Proprietary formats, data migration cost'),
    Field('integrationComplexity', String, 'Integration Complexity',
        hint: 'Effort to integrate — Low / Medium / High'),
  ])
  String? content;
}

/// Docs for component.
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
  String? content;
}

/// A component interface entry (form) [PD00-COM-COM-nn-INT-nn].
///
/// Describes one interface exposed or consumed by a component: protocol,
/// authentication, data format, rate limits, versioning, SLA, monitoring.
class ComponentInterfaceEntry {
  @Form([
    Field('interfaceName', String, 'Interface Name',
        hint: 'Human-readable name, e.g. Order Service REST API'),
    Field('interfaceType', String, 'Interface Type',
        hint: 'REST / GraphQL / gRPC / WebSocket / MessageQueue / SDK / CLI / File'),
    Field('protocol', String, 'Protocol',
        hint: 'HTTP/1.1 / HTTP/2 / AMQP / MQTT / TCP / UDP'),
  ])
  String? content;

  /// Network configuration.
  ComponentInterfaceEntryNetwork network = ComponentInterfaceEntryNetwork();

  /// Security settings.
  ComponentInterfaceEntrySecurity security = ComponentInterfaceEntrySecurity();

  /// Data format configuration.
  ComponentInterfaceEntryData data = ComponentInterfaceEntryData();

  /// SLA and monitoring.
  ComponentInterfaceEntrySla sla = ComponentInterfaceEntrySla();

  /// Operations and documentation.
  ComponentInterfaceEntryOperations operations =
      ComponentInterfaceEntryOperations();
}

/// Network configuration for component interface.
class ComponentInterfaceEntryNetwork {
  @Form([
    Field('port', int, 'Default Port',
        hint: 'Default network port, e.g. 443, 5432, 6379'),
    Field('basePath', String, 'Base Path / Endpoint',
        hint: 'Root URL or queue name, e.g. /api/v2, orders.events'),
    Field('rateLimitRequests', int, 'Rate Limit (req/min)',
        hint: 'Maximum requests per minute allowed'),
  ])
  String? content;
}

/// Security settings for component interface.
class ComponentInterfaceEntrySecurity {
  @Form([
    Field('authenticationMethod', String, 'Authentication',
        hint: 'OAuth2 / APIKey / mTLS / SAML / BasicAuth / None'),
    Field('authorizationModel', String, 'Authorization Model',
        hint: 'RBAC / ABAC / ScopeBased / ACL — how permissions are enforced'),
    Field('tlsRequired', String, 'TLS Requirement',
        hint: 'Required / Optional / NotSupported, minimum TLS version'),
  ])
  String? content;
}

/// Data format configuration for component interface.
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
  String? content;
}

/// SLA and monitoring for component interface.
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
  String? content;
}

/// Operations and documentation for component interface.
class ComponentInterfaceEntryOperations {
  @Form([
    Field('retryPolicy', String, 'Recommended Retry Policy',
        hint: 'Exponential backoff params, max retries, idempotency'),
    Field('documentationUrl', String, 'API Documentation URL',
        hint: 'Link to OpenAPI spec, SDK docs, or integration guide'),
    Field('description', String, 'Description',
        hint: 'Purpose and usage context for this interface'),
  ])
  String? content;
}

/// Component licensing sub-entry [PD00-COM-COM-nn-LIC] (form).
///
/// Detailed licensing information: model, cost, compliance, open-source
/// obligations, audit requirements, geographic restrictions, usage metrics.
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
  String? content;

  /// Cost and renewal details.
  ComponentLicensingEntryCosts costs = ComponentLicensingEntryCosts();

  /// Usage rights and obligations.
  ComponentLicensingEntryRights rights = ComponentLicensingEntryRights();

  /// Compliance restrictions.
  ComponentLicensingEntryCompliance compliance =
      ComponentLicensingEntryCompliance();

  /// Metering and capacity rules.
  ComponentLicensingEntryCapacity capacity = ComponentLicensingEntryCapacity();

  /// Contract termination terms.
  ComponentLicensingEntryContract contract = ComponentLicensingEntryContract();
}

/// Cost and renewal details.
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
  String? content;
}

/// Usage rights and obligations.
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
  String? content;
}

/// Compliance restrictions.
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
  String? content;
}

/// Metering and capacity rules.
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
  String? content;
}

/// Contract termination terms.
class ComponentLicensingEntryContract {
  @Form([
    Field('terminationClause', String, 'Termination Terms',
        hint: 'Early termination penalties and data export rights'),
  ])
  String? content;
}

/// Component responsibilities sub-entry [PD00-COM-COM-nn-RES] (form).
///
/// Who owns and maintains this component: primary/backup owners, SLA targets,
/// patch response time, security vulnerability handling, budget allocation.
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
  String? content;

  /// Vendor support details.
  ComponentResponsibilitiesEntrySupport support =
      ComponentResponsibilitiesEntrySupport();

  /// SLA commitments.
  ComponentResponsibilitiesEntrySla sla = ComponentResponsibilitiesEntrySla();

  /// Security and update operations.
  ComponentResponsibilitiesEntryOperations operations =
      ComponentResponsibilitiesEntryOperations();

  /// Governance and planning.
  ComponentResponsibilitiesEntryGovernance governance =
      ComponentResponsibilitiesEntryGovernance();
}

/// Vendor support details.
class ComponentResponsibilitiesEntrySupport {
  @Form([
    Field('vendorSupportContact', String, 'Vendor Support Contact',
        hint: 'How to reach vendor support — portal, email, phone'),
    Field('vendorSupportHours', String, 'Vendor Support Hours',
        hint:
            'Availability window, e.g. 24/7 or Mon-Fri 9-17 CET'),
  ])
  String? content;
}

/// SLA commitments.
class ComponentResponsibilitiesEntrySla {
  @Form([
    Field('slaUptimeTarget', String, 'Uptime SLA Target',
        hint: 'Internal uptime commitment, e.g. 99.9%'),
    Field('slaResponseCritical', String, 'Critical Issue Response Time',
        hint: 'Max time to acknowledge a P1/critical incident'),
    Field('slaResolutionCritical', String, 'Critical Issue Resolution Time',
        hint: 'Max time to resolve or workaround a P1 incident'),
  ])
  String? content;
}

/// Security and update operations.
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
  String? content;
}

/// Governance and planning.
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
  String? content;
}

// ---------------------------------------------------------------------------
// 12.4. Runtime Dependencies
// ---------------------------------------------------------------------------

/// 12.4. Runtime Dependencies [PD00-COM-RUN].
///
/// Runtime dependencies between components: required services, startup order,
/// health-check dependencies, failover behavior, and version constraints.
@SectionId('PD00-COM-RUN')
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
  String? content;

  /// Contains 0+× Runtime Dependency.
  @SectionIdPattern('PD00-COM-RUN-xx')
  List<RuntimeDependencyEntry> items = [];
}

/// 12.5. Maintenance Dependencies [PD00-COM-MAI].
///
/// Maintenance dependencies: version compatibility matrix, coordinated
/// update sequences, and breaking-change handling.
@SectionId('PD00-COM-MAI')
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
  String? content;

  /// Contains 0+× Maintenance Dependency.
  @SectionIdPattern('PD00-COM-MAI-xx')
  List<MaintenanceDependencyEntry> items = [];
}

/// A runtime dependency entry (form) [PD00-COM-RUN-nn].
///
/// Documents one runtime dependency: startup order, health checks,
/// failover, data flow, latency tolerance, and caching strategy.
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
  String? content;

  /// Versioning and business criticality.
  RuntimeDependencyEntryClassification classification =
      RuntimeDependencyEntryClassification();

  /// Startup and health behavior.
  RuntimeDependencyEntryStartup startup = RuntimeDependencyEntryStartup();

  /// Resilience behavior.
  RuntimeDependencyEntryResilience resilience =
      RuntimeDependencyEntryResilience();

  /// Data flow and network characteristics.
  RuntimeDependencyEntryIntegration integration =
      RuntimeDependencyEntryIntegration();

  /// Compatibility and transitive risk notes.
  RuntimeDependencyEntryRisk risk = RuntimeDependencyEntryRisk();
}

/// Versioning and business criticality.
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
  String? content;
}

/// Startup and health behavior.
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
  String? content;
}

/// Resilience behavior.
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
  String? content;
}

/// Data flow and network characteristics.
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
  String? content;
}

/// Compatibility and transitive risk notes.
class RuntimeDependencyEntryRisk {
  @Form([
    Field('transitiveRisk', String, 'Transitive Dependency Risk',
        hint:
            'Key risks from this dependency\'s own dependencies'),
    Field('compatibilityMatrix', String, 'Compatibility Notes',
        hint:
            'Known incompatibilities with other components in our stack'),
  ])
  String? content;
}

/// A maintenance dependency entry (form) [PD00-COM-MAI-nn].
///
/// Documents one maintenance dependency: coordinated update sequences,
/// version compatibility, and breaking-change handling.
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
  String? content;

  /// Classification and purpose.
  MaintenanceDependencyEntryClassification classification =
      MaintenanceDependencyEntryClassification();

  /// Update coordination.
  MaintenanceDependencyEntryUpdate update = MaintenanceDependencyEntryUpdate();

  /// Risk and fallback planning.
  MaintenanceDependencyEntryRisk risk = MaintenanceDependencyEntryRisk();
}

/// Classification and purpose.
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
  String? content;
}

/// Update coordination.
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
  String? content;
}

/// Risk and fallback planning.
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
  String? content;
}

// ---------------------------------------------------------------------------
// 12.6. Risk Assessment
// ---------------------------------------------------------------------------

/// 12.6. Risk Assessment [PD00-COM-RIS].
///
/// Component risk assessment: identified risks with probability/impact,
/// monitoring, mitigation strategies, and contingency plans.
@SectionId('PD00-COM-RIS')
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
  String? content;

  /// 12.6.1. Component Risks [PD00-COM-RIS-RIS] — contains 0+× Risk.
  @SectionIdPattern('PD00-COM-RIS-RIS-xx')
  List<ComponentRiskEntry> risks = [];

  /// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
  ContingencyPlans contingencyPlans = ContingencyPlans();
}

/// 12.6.2. Contingency Plans [PD00-COM-RIS-CON].
///
/// Container for contingency plans addressing critical component risks.
@SectionId('PD00-COM-RIS-CON')
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
  String? content;

  /// Contains 0+× ContingencyPlan.
  @SectionIdPattern('PD00-COM-RIS-CON-xx')
  List<ContingencyPlanEntry> items = [];
}

/// A contingency plan entry (form) [PD00-COM-RIS-CON-nn].
///
/// Describes one contingency plan for a component risk: trigger conditions,
/// immediate/recovery actions, RTO/RPO, communication, testing frequency.
class ContingencyPlanEntry {
  @Form([
    Field('contingencyId', String, 'Contingency Plan ID',
        hint: 'Unique identifier, e.g. CP-001'),
    Field('planTitle', String, 'Plan Title',
        hint: 'Short name for this contingency plan', required: true),
    Field('triggerCondition', String, 'Trigger Condition',
        hint: 'Specific event or threshold that activates this plan'),
  ])
  String? content;

  /// Reference links to risk and component.
  ContingencyPlanEntryReferences references = ContingencyPlanEntryReferences();

  /// Action steps: trigger detection, immediate, and recovery.
  ContingencyPlanEntryActions actions = ContingencyPlanEntryActions();

  /// Responsibility and recovery targets.
  ContingencyPlanEntryResponsibility responsibility =
      ContingencyPlanEntryResponsibility();

  /// Communication plans.
  ContingencyPlanEntryCommunication communication =
      ContingencyPlanEntryCommunication();

  /// Testing and resources.
  ContingencyPlanEntryTesting testing = ContingencyPlanEntryTesting();
}

/// Reference links for contingency plan.
class ContingencyPlanEntryReferences {
  @Form([
    Field('riskRef', String, 'Associated Risk',
        hint: 'Risk ID this plan addresses'),
    Field('componentRef', String, 'Component',
        hint: 'Component ID this plan covers'),
  ])
  String? content;
}

/// Action steps for contingency plan.
class ContingencyPlanEntryActions {
  @Form([
    Field('triggerDetection', String, 'Trigger Detection',
        hint: 'How the trigger is detected — alert, manual report, monitoring'),
    Field('immediateActions', String, 'Immediate Actions',
        hint: 'First steps within minutes of trigger (containment)'),
    Field('recoveryActions', String, 'Recovery Actions',
        hint: 'Steps to restore full operation'),
  ])
  String? content;
}

/// Responsibility and recovery targets for contingency plan.
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
  String? content;
}

/// Communication plans for contingency.
class ContingencyPlanEntryCommunication {
  @Form([
    Field('communicationPlan', String, 'Communication Plan',
        hint: 'Who is notified, how, and in what order'),
    Field('customerCommunication', String, 'Customer Communication',
        hint: 'External messaging template or process'),
  ])
  String? content;
}

/// Testing and resources for contingency plan.
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
  String? content;
}

/// A component risk entry [PD00-COM-RIS-RIS-nn] (form).
///
/// Documents one component risk: category, probability, impact, detection
/// methods, mitigation strategy and status, residual risk, and ownership.
class ComponentRiskEntry {
  @Form([
    Field('riskId', String, 'Risk ID',
        hint: 'Unique identifier, e.g. CR-001', required: true),
    Field('componentRef', String, 'Component',
        hint: 'Component ID this risk applies to'),
    Field('riskTitle', String, 'Risk Title',
        hint: 'Short descriptive name'),
  ])
  String? content;

  /// Risk description and categorization.
  ComponentRiskEntryDescription description = ComponentRiskEntryDescription();

  /// Risk assessment.
  ComponentRiskEntryAssessment assessment = ComponentRiskEntryAssessment();

  /// Detection and monitoring.
  ComponentRiskEntryDetection detection = ComponentRiskEntryDetection();

  /// Mitigation strategy.
  ComponentRiskEntryMitigation mitigation = ComponentRiskEntryMitigation();

  /// Governance and ownership.
  ComponentRiskEntryGovernance governance = ComponentRiskEntryGovernance();
}

/// Risk description and categorization.
class ComponentRiskEntryDescription {
  @Form([
    Field('riskDescription', String, 'Risk Description',
        hint: 'Detailed explanation of the risk scenario'),
    Field('riskCategory', String, 'Risk Category',
        hint: 'Technical / Vendor / Security / Compliance / Operational / Financial'),
  ])
  String? content;
}

/// Risk assessment for component risk.
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
  String? content;
}

/// Detection and monitoring for component risk.
class ComponentRiskEntryDetection {
  @Form([
    Field('detectionMethod', String, 'Detection Method',
        hint: 'How we would know this risk is materializing'),
    Field('earlyWarningIndicators', String, 'Early Warning Indicators',
        hint: 'Metrics or signals that precede this risk event'),
    Field('monitoringMechanism', String, 'Monitoring',
        hint: 'Dashboards, alerts, or scans that track this risk'),
  ])
  String? content;
}

/// Mitigation strategy for component risk.
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
  String? content;
}

/// Governance and ownership for component risk.
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
  String? content;
}
