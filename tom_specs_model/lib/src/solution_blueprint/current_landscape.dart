/// Section 1: Current Landscape.
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 1. Current Landscape. Seeds → CLA.
///
/// Seeds the CLA (Current Landscape Assessment) Phase 3 DocSpec. Its subtree
/// flows to CLA together with the systems-to-replace inventory.
@StandardReferences(
  ['BABOK v3 §10 — Define the Current State (current-state analysis)'],
  'The AS-IS analysis that motivates the project — existing systems, current '
  'processes, pain points, data, operational metrics and current-state risks — '
  'and the seed for the Current Landscape Assessment (CLA).',
)
@FollowUpKind([FollowUpProcess.doc])
@SectionId('CULA')
@MapsTo(D01CurrentLandscapeAssessment)
class CurrentLandscape extends DocSpecsSection {
  @ContentHelp('''
Executive summary of the current state: existing systems landscape, business
processes today, known pain points, current data landscape, operational
metrics, and risks tied to the current state or to replacement. Seeds the CS
document alongside the systems-to-replace inventory.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 1.1. Existing Systems Landscape.
  @SerializationOrder(1)
  ExistingSystemsLandscape existingSystemsLandscape =
      ExistingSystemsLandscape();

  /// 1.2. Current Business Processes.
  @SerializationOrder(2)
  CurrentBusinessProcesses currentBusinessProcesses =
      CurrentBusinessProcesses();

  /// 1.3. Pain Points and Gaps.
  @SerializationOrder(3)
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// 1.4. Current Data Landscape.
  @SerializationOrder(4)
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();

  /// 1.5. Operational Metrics.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (operational baseline metrics)'],
    'The collection of current operational baseline metrics — one entry per '
    'measured characteristic — that sizes the target system and seeds its '
    'non-functional requirements.',
  )
  @SectionId('CUOPME-OPER-LST')
  @SectionIdPattern('CUOPME-OPER-xxx')
  @ContentHelp(
    'Add one entry per operational metric of the current landscape: '
    'transaction volumes, user counts, response-time baselines, uptime, '
    'error rates, and storage growth. These figures drive target sizing and '
    'non-functional requirements.',
  )
  @SerializationOrder(5)
  List<CurrentOperationalMetric> operationalMetrics = [];

  /// 1.6. Current State Risks.
  @SerializationOrder(6)
  CurrentStateRiskAssessment currentStateRisks = CurrentStateRiskAssessment();
}

// ---------------------------------------------------------------------------
// 1.1 Existing Systems Landscape
// ---------------------------------------------------------------------------

/// 1.1. Existing Systems Landscape.
///
/// Overview of the current systems in use, their roles, technology stacks,
/// and limitations. Provides the foundation for understanding the AS-IS state.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (systems & capability inventory)'],
  'The AS-IS catalogue of systems in use today — their inventory, architecture '
  'and inter-system dependencies — establishing the technical baseline the new '
  'system must replace, integrate with, or coexist alongside.',
)
@ContentHelp(
  'Describe the existing systems landscape: inventory every relevant '
  'system, sketch the current architecture, and map dependencies and '
  'integrations. Include a context diagram showing how the systems interact.',
)
@SectionId('ESLAN')
@DetailedIn(D01CurrentLandscapeAssessment)
class ExistingSystemsLandscape extends DocSpecsSection {
  @ContentType(
    'description',
    'High-level overview of the existing systems '
        'landscape. Include a context diagram showing how systems interact.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// 1.1.1. System Inventory.
  @SerializationOrder(1)
  SystemInventory systemInventory = SystemInventory();

  /// 1.1.2. Current Architecture.
  @SerializationOrder(2)
  CurrentArchitecture currentArchitecture = CurrentArchitecture();

  /// 1.1.3. Dependencies and Integrations.
  @SerializationOrder(3)
  DependenciesAndIntegrations dependenciesAndIntegrations =
      DependenciesAndIntegrations();
}

/// 1.1.1. System Inventory.
///
/// Container for individual system descriptions. Add one entry per existing
/// system relevant to the project scope.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (system inventory)'],
  'The catalogue of individual systems in use today, one entry per system '
  'relevant to the project scope.',
)
@ContentHelp(
  'Inventory every system relevant to the project: those that will '
  'be replaced, integrated with, or affected by the new system. State the '
  'inclusion criteria so the boundary of the AS-IS landscape is clear.',
)
@SectionId('SYINV')
class SystemInventory extends DocSpecsSection {
  @ContentType(
    'description',
    'Introduction to the system inventory. '
        'Describe the criteria for including systems and the overall landscape.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 1+× Existing System.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (system inventory)',
  ], 'The set of existing systems catalogued in the AS-IS landscape.')
  @SectionId('ESENT-SYST-LST')
  @SectionIdPattern('ESENT-SYST-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per existing system that is relevant to the '
    'project scope. Include all systems that will be replaced, integrated '
    'with, or affected by the new system.',
  )
  @SerializationOrder(1)
  List<ExistingSystemEntry> systems = [];
}

/// 1.1.2. Current Architecture.
///
/// Description of the current system architecture including deployment
/// topology, integration patterns, shared services, and data stores.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (architecture baseline)',
    'TOGAF ADM Phase B/C — baseline architecture (current state)',
  ],
  'The AS-IS architecture baseline: deployment topology, integration patterns, '
  'and shared services that describe how today\'s systems fit together.',
)
@SectionId('CARCH')
class CurrentArchitecture extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Architecture overview diagram.
  @SectionId('CARCH-ARCH')
  @ContentType(
    'mermaid-flowchart',
    'Architecture overview diagram showing '
        'systems, their connections, and data flows',
  )
  @ContentHelp(
    'Provide a Mermaid flowchart showing the current architecture. '
    'Include all major systems, their connections, and data flow directions.',
  )
  @SerializationOrder(1)
  DocSpecsSection? architectureDiagram;

  /// Deployment topology description.
  @SectionId('CARCH-DEPL')
  @ContentType(
    'description',
    'Description of how systems are deployed '
        'across infrastructure',
  )
  @SerializationOrder(2)
  DocSpecsSection? deploymentTopology;

  /// Integration patterns used.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration patterns)'],
    'The set of integration patterns the current architecture relies on to '
    'connect its systems.',
  )
  @SectionId('CARCH-INTE-LST')
  @SectionIdPattern('CARCH-INTE-xxx')
  @ContentHelp(
    'Add one entry per integration pattern in use (e.g. point-to-'
    'point, hub-and-spoke, pub/sub, ESB, API gateway). Note where each '
    'pattern is applied and why.',
  )
  @SerializationOrder(3)
  List<DocSpecsSection> integrationPatterns = [];

  /// Shared services inventory.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (shared services)'],
    'The set of shared services the current architecture provides across '
    'multiple systems.',
  )
  @SectionId('CARCH-SHAR-LST')
  @SectionIdPattern('CARCH-SHAR-xxx')
  @ContentHelp(
    'Add one entry per shared service used by more than one system '
    '(e.g. authentication, logging, notifications). Capture which systems '
    'consume it.',
  )
  @SerializationOrder(4)
  List<DocSpecsSection> sharedServices = [];
}

/// An existing system entry (form).
///
/// Captures comprehensive information about an existing system including
/// identity, technology, business context, usage metrics, lifecycle, and risks.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (system profile)'],
  'A complete AS-IS profile of one existing system — its identity, technology, '
  'business context, usage, lifecycle, integration, infrastructure, '
  'limitations, and quality/risk posture.',
)
@SectionId('ESENT')
class ExistingSystemEntry extends DocSpecsSection {
  // -------------------------------------------------------------------------
  // System Identity
  // -------------------------------------------------------------------------

  @Form([
    Field(
      'systemName',
      String,
      'System Name',
      required: true,
      hint: 'Common name of the system, e.g. "SAP ERP", "Salesforce CRM".',
    ),
    Field(
      'systemId',
      String,
      'System ID/Code (internal identifier)',
      hint: 'Internal catalogue code or CMDB identifier, if any.',
    ),
    Field(
      'systemVersion',
      String,
      'Current Version',
      hint: 'Release or version currently in production, e.g. "ECC 6.0".',
    ),
    Field(
      'systemType',
      String,
      'System Type '
          '(ERP, CRM, Custom Development, COTS, SaaS, etc.)',
      hint: 'Classify the system: ERP, CRM, Custom Development, COTS, SaaS.',
    ),
    Field(
      'vendor',
      String,
      'Vendor (if commercial software)',
      hint: 'Software publisher, e.g. "SAP", "Salesforce" — blank if in-house.',
    ),
    Field(
      'licenseType',
      String,
      'License Type '
          '(Enterprise, Per-User, Subscription, Open Source, etc.)',
      hint: 'Licensing model: Enterprise, Per-User, Subscription, Open Source.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  // -------------------------------------------------------------------------
  // Technology Stack
  // -------------------------------------------------------------------------

  /// Technology stack details.
  @SectionId('ESTEC')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (technology stack)'],
    'The technology stack of one existing system: its platform, languages, '
    'database, OS, frameworks, and frontend.',
  )
  @Form([
    Field(
      'primaryPlatform',
      String,
      'Primary Technology Platform',
      hint: 'Dominant platform, e.g. ".NET", "Java EE", "SAP NetWeaver".',
    ),
    Field(
      'programmingLanguages',
      String,
      'Programming Languages (comma-separated)',
      hint: 'Languages in use, comma-separated, e.g. "Java, JavaScript, SQL".',
    ),
    Field(
      'databaseTechnology',
      String,
      'Database Technology',
      hint: 'Database engine, e.g. "Oracle 19c", "PostgreSQL", "MS SQL".',
    ),
    Field(
      'operatingSystem',
      String,
      'Operating System',
      hint: 'Host OS, e.g. "RHEL 8", "Windows Server 2019".',
    ),
    Field(
      'frameworksMiddleware',
      String,
      'Frameworks/Middleware',
      hint: 'Key frameworks/middleware, e.g. "Spring Boot, WebLogic".',
    ),
    Field(
      'frontendTechnology',
      String,
      'Frontend Technology (if applicable)',
      hint: 'Frontend stack, e.g. "Angular", "JSP", "SAP GUI" — blank if none.',
    ),
  ])
  @Comment('Technology stack')
  @SerializationOrder(1)
  DocSpecsSection? technology;

  // -------------------------------------------------------------------------
  // Business Context
  // -------------------------------------------------------------------------

  /// Business context.
  @SectionId('ESBCT')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (business context)'],
    'The business context of one existing system: its purpose, domain, '
    'ownership, and criticality to the organization.',
  )
  @Form([
    Field(
      'purpose',
      String,
      'Purpose/Description',
      required: true,
      hint: 'What the system does for the business, in one or two sentences.',
    ),
    Field(
      'businessDomain',
      String,
      'Business Domain '
          '(Finance, Sales, Operations, HR, etc.)',
      hint: 'Primary domain served, e.g. Finance, Sales, Operations, HR.',
    ),
    Field(
      'owningDepartment',
      String,
      'Owning Business Unit/Department',
      hint: 'Business unit accountable for the system.',
    ),
    Field(
      'businessCriticality',
      String,
      'Business Criticality '
          '(Mission Critical, Business Critical, Standard, Low)',
      hint:
          'How critical to operations: Mission Critical, Business Critical, '
          'Standard, or Low.',
    ),
    Field(
      'businessOwner',
      String,
      'Business Owner (name/role)',
      hint:
          'Person or role owning the business outcomes, e.g. "Head of Sales".',
    ),
    Field(
      'technicalOwner',
      String,
      'Technical Owner (name/role)',
      hint: 'Person or role owning the technical operation of the system.',
    ),
  ])
  @Comment('Business context')
  @SerializationOrder(2)
  DocSpecsSection? businessContext;

  // -------------------------------------------------------------------------
  // Usage Metrics
  // -------------------------------------------------------------------------

  /// Usage metrics.
  @SectionId('ESUSG')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (usage metrics)'],
    'The measured usage of one existing system: user counts, transaction and '
    'data volumes, growth, and availability needs.',
  )
  @Form([
    Field(
      'activeUsers',
      int,
      'Active Users (total registered)',
      hint: 'Total registered/licensed users, e.g. 1200.',
    ),
    Field(
      'dailyActiveUsers',
      int,
      'Daily Active Users',
      hint: 'Typical number of users active on a normal day.',
    ),
    Field(
      'peakConcurrentUsers',
      int,
      'Peak Concurrent Users',
      hint: 'Highest number of simultaneous users observed.',
    ),
    Field(
      'transactionVolumeDaily',
      String,
      'Transaction Volume (daily average)',
      hint: 'Average daily transactions, e.g. "~50k orders/day".',
    ),
    Field(
      'dataVolumeCurrent',
      String,
      'Current Data Volume',
      hint: 'Size of the data set today, e.g. "2.5 TB".',
    ),
    Field(
      'dataGrowthRate',
      String,
      'Data Growth Rate (monthly/yearly)',
      hint: 'How fast data grows, e.g. "~50 GB/month".',
    ),
    Field(
      'availabilityRequirement',
      String,
      'Availability Requirement '
          '(e.g., 99.9%, 24x7, business hours)',
      hint: 'Required uptime, e.g. "99.9%", "24x7", "business hours".',
    ),
  ])
  @Comment('Usage metrics')
  @SerializationOrder(3)
  DocSpecsSection? usage;

  // -------------------------------------------------------------------------
  // Lifecycle Information
  // -------------------------------------------------------------------------

  /// Lifecycle information.
  @SectionId('ESLCY')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (system lifecycle)'],
    'The lifecycle status of one existing system: when it went live, its support '
    'horizon, and how urgently it must be migrated or retired.',
  )
  @Form([
    Field(
      'goLiveDate',
      String,
      'Go-Live Date (operational since)',
      hint: 'When the system first went into production (ISO 8601).',
    ),
    Field(
      'lastMajorUpgrade',
      String,
      'Last Major Upgrade Date',
      hint: 'Date of the most recent major upgrade (ISO 8601).',
    ),
    Field(
      'currentVersion',
      String,
      'Current Version',
      hint: 'Version currently running in production.',
    ),
    Field(
      'supportStatus',
      String,
      'Support Status '
          '(Active, Limited, Extended, End-of-Life)',
      hint: 'Vendor support state: Active, Limited, Extended, or End-of-Life.',
    ),
    Field(
      'supportExpiryDate',
      String,
      'Support Expiry Date',
      hint: 'Date vendor support ends (ISO 8601), if known.',
    ),
    Field(
      'plannedRetirementDate',
      String,
      'Planned Retirement Date (if any)',
      hint: 'Target decommission date, if one is planned.',
    ),
    Field(
      'migrationUrgency',
      String,
      'Migration Urgency '
          '(Immediate, Within 1 year, Within 3 years, No deadline)',
      hint: 'How soon migration is needed: Immediate, Within 1 year, etc.',
    ),
  ])
  @Comment('Lifecycle information')
  @SerializationOrder(4)
  DocSpecsSection? lifecycle;

  // -------------------------------------------------------------------------
  // Integration Profile
  // -------------------------------------------------------------------------

  /// Integration profile.
  @SectionId('ESINT')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration profile)'],
    'The integration profile of one existing system: the APIs it exposes, the '
    'methods and formats it exchanges by, and its interface counts.',
  )
  @Form([
    Field(
      'apiTypesAvailable',
      String,
      'API Types Available '
          '(REST, SOAP, GraphQL, gRPC, none)',
      hint: 'APIs the system exposes: REST, SOAP, GraphQL, gRPC, or none.',
    ),
    Field(
      'integrationMethods',
      String,
      'Integration Methods '
          '(API, File Transfer, Database Link, Message Queue, manual)',
      hint: 'How it integrates: API, File Transfer, Database Link, MQ, manual.',
    ),
    Field(
      'dataFormats',
      String,
      'Data Formats (JSON, XML, CSV, EDI, etc.)',
      hint: 'Formats exchanged: JSON, XML, CSV, EDI, etc.',
    ),
    Field(
      'realTimeCapable',
      bool,
      'Real-Time Integration Capable',
      hint: 'True if the system supports real-time integration.',
    ),
    Field(
      'batchProcessingWindows',
      String,
      'Batch Processing Windows',
      hint: 'Scheduled batch windows, e.g. "nightly 01:00–03:00".',
    ),
    Field(
      'externalInterfaceCount',
      int,
      'Number of External Interfaces',
      hint: 'Count of interfaces to systems outside the organization.',
    ),
    Field(
      'internalInterfaceCount',
      int,
      'Number of Internal Interfaces',
      hint: 'Count of interfaces to other internal systems.',
    ),
  ])
  @Comment('Integration profile')
  @SerializationOrder(5)
  DocSpecsSection? integrationProfile;

  // -------------------------------------------------------------------------
  // Infrastructure
  // -------------------------------------------------------------------------

  /// Infrastructure details.
  @SectionId('ESINF')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (infrastructure)'],
    'The infrastructure footprint of one existing system: its hosting model, '
    'environments, geographic spread, and resilience posture.',
  )
  @Form([
    Field(
      'hostingModel',
      String,
      'Hosting Model '
          '(On-Premise, Private Cloud, Public Cloud, Hybrid, SaaS)',
      hint:
          'Where it runs: On-Premise, Private Cloud, Public Cloud, Hybrid, SaaS.',
    ),
    Field(
      'cloudProvider',
      String,
      'Cloud Provider (if applicable)',
      hint: 'Cloud provider, e.g. "AWS", "Azure", "GCP" — blank if on-prem.',
    ),
    Field(
      'environmentCount',
      int,
      'Number of Environments '
          '(Dev, Test, Staging, Prod, etc.)',
      hint: 'How many environments exist (Dev, Test, Staging, Prod, ...).',
    ),
    Field(
      'geographicDeployment',
      String,
      'Geographic Deployment '
          '(Single region, Multi-region, Global)',
      hint: 'Deployment reach: Single region, Multi-region, or Global.',
    ),
    Field(
      'disasterRecovery',
      String,
      'Disaster Recovery Capability '
          '(Hot standby, Warm standby, Cold backup, None)',
      hint: 'DR posture: Hot standby, Warm standby, Cold backup, or None.',
    ),
    Field(
      'backupFrequency',
      String,
      'Backup Frequency',
      hint: 'How often backups run, e.g. "hourly", "nightly".',
    ),
  ])
  @Comment('Infrastructure')
  @SerializationOrder(6)
  DocSpecsSection? infrastructure;

  // -------------------------------------------------------------------------
  // Quality & Risk
  // -------------------------------------------------------------------------

  /// Contains 0+× Limitation.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (known limitations)'],
    'The set of known limitations of this system that constrain current '
    'operations.',
  )
  @SectionId('LIMET-KNOW-LST')
  @SectionIdPattern('LIMET-KNOW-xxx')
  @ContentHelp(
    'Document each known limitation with its impact on current '
    'operations and any workarounds in place.',
  )
  @SerializationOrder(7)
  List<LimitationEntry> knownLimitations = [];

  /// Quality and risk assessment.
  @SectionId('ESQUA')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (quality & risk)',
      'ISO/IEC 25010 — product quality model (maintainability, security)',
    ],
    'The quality and risk posture of one existing system: technical debt, code '
    'and documentation quality, achieved SLAs, and security/accessibility '
    'compliance.',
  )
  @Form([
    Field(
      'technicalDebtLevel',
      String,
      'Technical Debt Level '
          '(Low, Medium, High, Critical)',
      hint: 'Accumulated technical debt: Low, Medium, High, or Critical.',
    ),
    Field(
      'codeQuality',
      String,
      'Code Quality Assessment '
          '(Good, Acceptable, Poor, Unknown)',
      hint: 'Code quality judgement: Good, Acceptable, Poor, or Unknown.',
    ),
    Field(
      'documentationStatus',
      String,
      'Documentation Status '
          '(Current, Outdated, Minimal, None)',
      hint: 'State of docs: Current, Outdated, Minimal, or None.',
    ),
    Field(
      'availabilitySla',
      String,
      'Availability SLA (actual achieved)',
      hint: 'Actual availability achieved, e.g. "99.5%" — not the target.',
    ),
    Field(
      'securityComplianceStatus',
      String,
      'Security Compliance Status',
      hint: 'Compliance standing, e.g. "PCI-DSS compliant", "gaps open".',
    ),
    Field(
      'lastSecurityAudit',
      String,
      'Last Security Audit Date',
      hint: 'Date of the most recent security audit (ISO 8601).',
    ),
    Field(
      'lastPenetrationTest',
      String,
      'Last Penetration Test Date',
      hint: 'Date of the most recent penetration test (ISO 8601).',
    ),
    Field(
      'accessibilityCompliance',
      String,
      'Accessibility Compliance '
          '(WCAG level, Section 508, etc.)',
      hint: 'Accessibility standing, e.g. "WCAG 2.1 AA", "Section 508".',
    ),
  ])
  @Comment('Quality and risk')
  @SerializationOrder(8)
  DocSpecsSection? quality;
}

/// A known limitation of an existing system (form).
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (known limitations)'],
  'A single known limitation of an existing system and its impact on current '
  'operations.',
)
@SectionId('LIMET')
class LimitationEntry extends DocSpecsSection {
  @Form([
    Field(
      'limitation',
      String,
      'Limitation',
      required: true,
      hint: 'The limitation itself, e.g. "No multi-currency support".',
    ),
    Field(
      'impact',
      String,
      'Impact assessment',
      hint: 'Effect on operations and any workaround in place.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 1.1.3. Dependencies and Integrations.
///
/// Documents how current systems depend on each other, on external services,
/// and on shared infrastructure. Identifies fragile integration points that
/// pose risk to operations or to the new system implementation.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (dependencies & integrations)'],
  'The web of dependencies and integrations across the AS-IS landscape — '
  'internal, external-service, and shared-infrastructure couplings plus the '
  'active integrations and their overall health.',
)
@SectionId('DEPNT')
class DependenciesAndIntegrations extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Dependency matrix diagram.
  @SectionId('DEPNT-DEPE')
  @ContentType(
    'mermaid-flowchart',
    'Visual representation of system '
        'dependencies showing data flows and coupling strength',
  )
  @ContentHelp(
    'Create a Mermaid flowchart showing dependencies between '
    'systems. Use line styles to indicate coupling strength: solid for '
    'tight coupling, dashed for loose coupling. Add labels for data types.',
  )
  @SerializationOrder(1)
  DocSpecsSection? dependencyDiagram;

  /// 1.1.3.1. Internal Dependencies.
  @Comment('Dependencies between internal systems')
  @SerializationOrder(2)
  InternalDependencies internalDependencies = InternalDependencies();

  /// 1.1.3.2. External Service Dependencies.
  @Comment('Dependencies on external/third-party services')
  @SerializationOrder(3)
  ExternalServiceDependencies externalServiceDependencies =
      ExternalServiceDependencies();

  /// 1.1.3.3. Shared Infrastructure Dependencies.
  @Comment('Dependencies on shared infrastructure components')
  @SerializationOrder(4)
  SharedInfrastructureDependencies sharedInfrastructureDependencies =
      SharedInfrastructureDependencies();

  /// 1.1.3.4. System Integrations.
  @Comment('Active integrations between systems')
  @SerializationOrder(5)
  Integrations integrations = Integrations();

  /// 1.1.3.5. Integration Health Summary.
  @Comment('Overall assessment of integration landscape health')
  @SerializationOrder(6)
  IntegrationHealthSummary? healthSummary;
}

/// 1.1.3.1. Internal Dependencies.
///
/// Dependencies between systems owned and operated internally.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (internal dependencies)'],
  'The dependencies between systems the organization owns and operates '
  'internally.',
)
@SectionId('INTDP')
class InternalDependencies extends DocSpecsSection {
  @ContentType('description', 'Overview of internal system dependencies.')
  @ContentHelp(
    'Describe the overall pattern of internal dependencies. '
    'Identify clusters of tightly coupled systems and potential cascading '
    'failure risks.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Internal System Dependency.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (internal dependencies)',
  ], 'The set of documented dependencies between internal systems.')
  @SectionId('SYDE-ITEM-LST')
  @SectionIdPattern('SYDE-ITEM-xxx')
  @ContentHelp(
    'Add one entry per dependency between internal systems. Capture '
    'the mechanism, coupling strength, data flow, and failure impact of each.',
  )
  @SerializationOrder(1)
  List<SystemDependencyEntry> items = [];
}

/// 1.1.3.2. External Service Dependencies.
///
/// Dependencies on external services, third-party APIs, SaaS platforms,
/// and cloud services not under direct organizational control.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (external dependencies)'],
  'The dependencies on external services, third-party APIs, SaaS platforms, '
  'and cloud services outside direct organizational control.',
)
@SectionId('EXTDP')
class ExternalServiceDependencies extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of external service dependencies '
        'and vendor relationships.',
  )
  @ContentHelp(
    'Describe reliance on external services. Include vendor risk '
    'assessment, contract status, and contingency planning.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× External Service Dependency.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (external dependencies)'],
    'The set of documented dependencies on external services and third-party '
    'providers.',
  )
  @SectionId('EXSDE-ITEM-LST')
  @SectionIdPattern('EXSDE-ITEM-xxx')
  @ContentHelp(
    'Add one entry per external service or third-party provider the '
    'current systems rely on. Capture vendor, SLA, risk, and fallback for each.',
  )
  @SerializationOrder(1)
  List<ExternalServiceDependencyEntry> items = [];
}

/// An external service dependency entry (form).
///
/// Documents a dependency on an external service or third-party provider
/// including vendor details, SLA, risk assessment, and fallback options.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (external dependency profile)'],
  'A complete profile of one external-service dependency: the service, its '
  'provider, relationship, operations, risk, and fallback.',
)
@SectionId('EXSDE')
class ExternalServiceDependencyEntry extends DocSpecsSection {
  @Form([
    Field(
      'serviceName',
      String,
      'External Service Name',
      required: true,
      hint: 'Name of the external service, e.g. "Stripe Payments".',
    ),
    Field(
      'serviceProvider',
      String,
      'Service Provider/Vendor',
      hint: 'Company providing the service, e.g. "Stripe, Inc.".',
    ),
    Field(
      'serviceType',
      String,
      'Service Type',
      hint:
          'SaaS / PaaS / IaaS / API Service / Data Feed / Payment Gateway / etc.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Internal dependency and contract details.
  @SectionId('EXSRL')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (external dependency relationship)',
    ],
    'The relationship and contract facts for one external-service dependency: '
    'which systems depend on it, its criticality, and contract status.',
  )
  @Form([
    Field(
      'dependentSystems',
      String,
      'Dependent Internal Systems',
      hint: 'List of internal systems that use this external service',
    ),
    Field(
      'criticality',
      String,
      'Criticality',
      hint: 'Critical / High / Medium / Low',
    ),
    Field(
      'contractStatus',
      String,
      'Contract Status',
      hint: 'Active / Renewal Due / Negotiating / Month-to-Month',
    ),
    Field(
      'contractExpiry',
      String,
      'Contract Expiry Date',
      hint: 'Date the current contract expires (ISO 8601).',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? relationship;

  /// Availability and data handling details.
  @SectionId('EXSOP')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (external dependency operations)'],
    'The operational facts for one external-service dependency: its SLA, actual '
    'availability, data handling, residency, and vendor certifications.',
  )
  @Form([
    Field(
      'slaGuarantee',
      String,
      'SLA Guarantee',
      hint: 'Vendor-provided availability guarantee, e.g., 99.9%',
    ),
    Field(
      'actualAvailability',
      String,
      'Actual Availability',
      hint: 'Measured availability over past period',
    ),
    Field(
      'dataExchanged',
      String,
      'Data Exchanged',
      hint: 'Types of data sent to/received from service',
    ),
    Field(
      'dataResidency',
      String,
      'Data Residency',
      hint: 'Where vendor stores/processes data - relevant for compliance',
    ),
    Field(
      'securityCertifications',
      String,
      'Vendor Security Certifications',
      hint: 'SOC2, ISO 27001, HIPAA, etc.',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;

  /// Risk and fallback considerations.
  @SectionId('EXSRK')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (external dependency risk)'],
    'The risk and fallback facts for one external-service dependency: lock-in, '
    'switching cost, alternatives, fallback procedure, and outage history.',
  )
  @Form([
    Field(
      'vendorLockIn',
      String,
      'Vendor Lock-In Risk',
      hint: 'None / Low / Moderate / High / Severe',
    ),
    Field(
      'switchingCost',
      String,
      'Switching Cost',
      hint: 'Estimated effort to migrate to alternative',
    ),
    Field(
      'alternativeProviders',
      String,
      'Alternative Providers',
      hint: 'Known alternatives if migration needed',
    ),
    Field(
      'fallbackProcedure',
      String,
      'Fallback Procedure',
      hint: 'Manual workaround or degraded operation mode',
    ),
    Field(
      'lastOutage',
      String,
      'Last Significant Outage',
      hint: 'Date and impact of last vendor outage',
    ),
    Field(
      'communicationChannel',
      String,
      'Support Communication Channel',
      hint: 'How incidents are reported and tracked',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? risk;

  @SectionId('EXSDE-PRIM-REF')
  @Reference('Primary Dependent System')
  @SerializationOrder(4)
  ExistingSystemEntry? primaryDependentSystem;
}

/// 1.1.3.3. Shared Infrastructure Dependencies.
///
/// Dependencies on shared infrastructure components used by multiple systems.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (shared infrastructure)'],
  'The dependencies on shared infrastructure components that multiple systems '
  'rely on — the cross-cutting single points of failure in the AS-IS estate.',
)
@SectionId('SHDEP')
class SharedInfrastructureDependencies extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of shared infrastructure and '
        'cross-cutting dependencies.',
  )
  @ContentHelp(
    'Describe shared infrastructure components (networks, '
    'databases, messaging systems, identity providers) that multiple '
    'systems depend on. Identify single points of failure.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Shared Infrastructure Component.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (shared infrastructure)'],
    'The set of documented shared infrastructure components that multiple '
    'systems depend on.',
  )
  @SectionId('SHIEN-ITEM-LST')
  @SectionIdPattern('SHIEN-ITEM-xxx')
  @ContentHelp(
    'Add one entry per shared infrastructure component (e.g. a '
    'database cluster, message broker, identity provider). Capture its '
    'criticality, resilience, and the systems that depend on it.',
  )
  @SerializationOrder(1)
  List<SharedInfrastructureEntry> items = [];
}

/// A shared infrastructure entry (form).
///
/// Documents a shared infrastructure component that multiple systems depend on.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (shared infrastructure component)'],
  'A complete profile of one shared infrastructure component: its identity, '
  'resilience, capacity, and ownership.',
)
@SectionId('SHIEN')
class SharedInfrastructureEntry extends DocSpecsSection {
  @Form([
    Field(
      'componentName',
      String,
      'Infrastructure Component Name',
      required: true,
      hint: 'Name of the component, e.g. "Prod Oracle RAC cluster".',
    ),
    Field(
      'componentType',
      String,
      'Component Type',
      hint:
          'Database Cluster / Message Broker / Load Balancer / '
          'Identity Provider / DNS / Certificate Authority / '
          'Logging Platform / Monitoring System / Network Segment',
    ),
    Field(
      'dependentSystemCount',
      int,
      'Number of Dependent Systems',
      hint: 'How many systems depend on this component.',
    ),
    Field(
      'dependentSystemList',
      String,
      'List of Dependent Systems',
      hint: 'Names of the systems that depend on this component.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Criticality and resilience.
  @SectionId('SIER')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (infrastructure resilience)'],
    'The criticality and resilience facts for one shared infrastructure '
    'component: whether it is a single point of failure and its redundancy.',
  )
  @Form([
    Field(
      'criticality',
      String,
      'Criticality',
      hint: 'Critical / High / Medium / Low',
    ),
    Field('singlePointOfFailure', bool, 'Is Single Point of Failure'),
    Field(
      'redundancyLevel',
      String,
      'Redundancy Level',
      hint: 'None / Active-Passive / Active-Active / Multi-Region',
    ),
    Field(
      'failoverTime',
      String,
      'Failover Time (RTO)',
      hint: 'Time to recover if component fails',
    ),
    Field(
      'lastFailure',
      String,
      'Last Failure Incident',
      hint: 'Date and summary of last significant failure',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? resilience;

  /// Capacity constraints.
  @SectionId('SIEC')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (infrastructure capacity)'],
    'The capacity facts for one shared infrastructure component: its headroom '
    'and scaling limitations.',
  )
  @Form([
    Field(
      'capacityHeadroom',
      String,
      'Capacity Headroom',
      hint: 'Current utilization vs capacity, e.g., 60% of max',
    ),
    Field(
      'scalingLimitations',
      String,
      'Scaling Limitations',
      hint: 'Constraints on horizontal or vertical scaling',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? capacity;

  /// Ownership and maintenance.
  @SectionId('SIEO')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (infrastructure ownership)'],
    'The ownership and maintenance facts for one shared infrastructure '
    'component: who manages it, its maintenance window, and documentation state.',
  )
  @Form([
    Field(
      'managedBy',
      String,
      'Managed By',
      hint: 'Team or vendor responsible for this component',
    ),
    Field(
      'maintenanceWindow',
      String,
      'Maintenance Window',
      hint: 'Regular maintenance schedule',
    ),
    Field(
      'documentationStatus',
      String,
      'Documentation Status',
      hint: 'Current / Outdated / Minimal / None',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? operations;
}

/// 1.1.3.5. Integration Health Summary.
///
/// Executive summary of overall integration landscape health and risk areas.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (integration health)'],
  'The executive summary of overall integration-landscape health: aggregate '
  'counts, risk areas, technical debt, and impact on this project.',
)
@SectionId('INHESU')
class IntegrationHealthSummary extends DocSpecsSection {
  @Form([
    Field(
      'overallHealthRating',
      String,
      'Overall Health Rating',
      hint: 'Healthy / Acceptable / Concerning / Critical',
    ),
    Field('totalDependencies', int, 'Total Dependencies Documented'),
    Field('criticalDependencies', int, 'Critical Dependencies'),
    Field('highRiskDependencies', int, 'High-Risk Dependencies'),
    Field('singlePointsOfFailure', int, 'Identified Single Points of Failure'),
    Field('undocumentedIntegrations', int, 'Known Undocumented Integrations'),
    Field(
      'technicalDebtSummary',
      String,
      'Technical Debt Summary',
      hint: 'Overview of integration-related technical debt',
    ),
    Field(
      'priorityRemediationAreas',
      String,
      'Priority Remediation Areas',
      hint: 'Top 3-5 areas requiring immediate attention',
    ),
    Field(
      'impactOnProject',
      String,
      'Impact on This Project',
      hint: 'How current integration state affects project planning',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Fragile integration points requiring attention.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (fragile integration points)'],
    'The set of fragile integration points in the AS-IS landscape that pose '
    'risk and require attention.',
  )
  @SectionId('INHESU-FRAG-LST')
  @SectionIdPattern('INHESU-FRAG-xxx')
  @ContentHelp(
    'Add one entry per fragile or high-risk integration point — '
    'brittle interfaces, undocumented links, or single points of failure '
    'that threaten operations or the new system implementation.',
  )
  @SerializationOrder(1)
  List<DocSpecsSection> fragilePoints = [];
}

/// 1.1.3.4. System Integrations.
///
/// Active integrations between systems including protocols, data formats,
/// error handling, and monitoring.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (system integrations)'],
  'The active integrations between systems in the AS-IS landscape — their '
  'protocols, data exchange, error handling, and monitoring.',
)
@SectionId('INTEGR')
class Integrations extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of system integrations and '
        'data exchange patterns.',
  )
  @ContentHelp(
    'Describe the integration patterns in use. Identify '
    'standards vs custom integrations, and areas of complexity.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× SystemIntegration.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (system integrations)',
  ], 'The set of documented active integrations between systems.')
  @SectionId('SYIN-ITEM-LST')
  @SectionIdPattern('SYIN-ITEM-xxx')
  @ContentHelp(
    'Add one entry per active integration between systems. Capture '
    'its type, pattern, protocol, data format, throughput, and monitoring.',
  )
  @SerializationOrder(1)
  List<SystemIntegrationEntry> items = [];
}

/// A system dependency entry (form).
///
/// Documents one dependency between systems in the current landscape:
/// mechanism, coupling strength, data flow, failure impact, SLA,
/// monitoring, and technical debt assessment.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (system dependency profile)'],
  'A complete profile of one inter-system dependency: its mechanism, coupling, '
  'data exchange, reliability, and operational ownership.',
)
@SectionId('SYDE')
class SystemDependencyEntry extends DocSpecsSection {
  @Form([
    Field(
      'dependencyName',
      String,
      'Dependency Name',
      hint: 'Descriptive name, e.g. CRM → ERP order sync',
      required: true,
    ),
    Field(
      'dependencyType',
      String,
      'Dependency Type',
      hint: 'Data / Functional / Operational / Temporal / Transactional',
    ),
    Field(
      'direction',
      String,
      'Direction',
      hint: 'Upstream / Downstream / Bidirectional',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Mechanism and coupling.
  @SectionId('SDEM')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (dependency mechanism)'],
    'The mechanism and coupling facts for one inter-system dependency: how the '
    'systems are linked and how tightly they are coupled.',
  )
  @Form([
    Field(
      'mechanism',
      String,
      'Dependency Mechanism',
      hint:
          'API / DatabaseLink / FileTransfer / MessageQueue / SharedStorage / Manual / ETL',
    ),
    Field(
      'couplingStrength',
      String,
      'Coupling Strength',
      hint: 'Tight / Moderate / Loose — degree of coupling between systems',
    ),
    Field(
      'criticality',
      String,
      'Criticality',
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? mechanism;

  /// Data exchange characteristics.
  @SectionId('SDEDE')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (dependency data exchange)'],
    'The data-exchange characteristics of one inter-system dependency: what data '
    'flows, in what volume, and how fresh it must be.',
  )
  @Form([
    Field(
      'dataExchanged',
      String,
      'Data Exchanged',
      hint: 'Key data entities or types flowing through this dependency',
    ),
    Field(
      'dataVolume',
      String,
      'Data Volume',
      hint: 'Typical volume, e.g. ~5k records/day, 200 MB/hour',
    ),
    Field(
      'dataFreshness',
      String,
      'Data Freshness Requirements',
      hint: 'RealTime / NearRealTime / Hourly / Daily / OnDemand',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dataExchange;

  /// Reliability and SLA.
  @SectionId('SDER')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (dependency reliability)'],
    'The reliability and SLA facts for one inter-system dependency: failure '
    'impact, cascade risk, latency/availability needs, and fallback.',
  )
  @Form([
    Field(
      'failureImpact',
      String,
      'Failure Impact',
      hint: 'What happens when this dependency fails — business consequences',
    ),
    Field(
      'cascadeRisk',
      String,
      'Failure Cascade Risk',
      hint:
          'None / Contained / ModerateCascade / SevereCascade — propagation to other systems',
    ),
    Field(
      'latencyRequirement',
      String,
      'Latency Requirement',
      hint: 'Maximum acceptable latency, e.g. <500ms, within same business day',
    ),
    Field(
      'availabilityRequirement',
      String,
      'Availability Requirement',
      hint: 'Required uptime, e.g. 99.9%, business hours only',
    ),
    Field(
      'sla',
      String,
      'SLA',
      hint:
          'Formal SLA reference or key terms, e.g. 4h response, 24h resolution',
    ),
    Field(
      'fallbackProcedure',
      String,
      'Fallback Procedure',
      hint: 'Manual or automated fallback when this dependency is unavailable',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? reliability;

  /// Operations and documentation.
  @SectionId('SDEO')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (dependency operations)'],
    'The operational facts for one inter-system dependency: its monitoring, '
    'documentation, ownership, and technical-debt assessment.',
  )
  @Form([
    Field(
      'monitoringStatus',
      String,
      'Monitoring Status',
      hint: 'Monitored / PartiallyMonitored / Unmonitored',
    ),
    Field(
      'documentationStatus',
      String,
      'Documentation Status',
      hint: 'Documented / PartiallyDocumented / Undocumented',
    ),
    Field(
      'dependencyOwner',
      String,
      'Dependency Owner',
      hint: 'Team or role responsible for maintaining this dependency',
    ),
    Field(
      'technicalDebt',
      String,
      'Technical Debt Assessment',
      hint: 'None / Low / Moderate / High — accumulated technical debt',
    ),
    Field(
      'technicalDebtDetails',
      String,
      'Technical Debt Details',
      hint:
          'Description of known issues, outdated protocols, or maintenance burden',
    ),
    Field(
      'plannedChanges',
      String,
      'Planned Changes',
      hint: 'Any known upcoming changes to this dependency',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;

  @SectionId('SYDE-SOUR-REF')
  @Reference('Source System')
  @SerializationOrder(5)
  ExistingSystemEntry? sourceSystem;

  @SectionId('SYDE-TARG-REF')
  @Reference('Target System')
  @SerializationOrder(6)
  ExistingSystemEntry? targetSystem;
}

/// A system integration entry (form).
///
/// Documents one integration between systems: type, pattern, protocol,
/// data format, throughput, error handling, monitoring, security,
/// and technical debt.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (system integration profile)'],
  'A complete profile of one active integration between systems: its type, '
  'pattern, protocol, data exchange, error handling, throughput, monitoring, '
  'and ownership.',
)
@SectionId('SYIN')
class SystemIntegrationEntry extends DocSpecsSection {
  @Form([
    Field(
      'integrationName',
      String,
      'Integration Name',
      hint: 'Descriptive name, e.g. Real-time inventory sync',
      required: true,
    ),
    Field(
      'integrationType',
      String,
      'Integration Type',
      hint: 'RealTime / Batch / EventDriven / RequestResponse / Manual',
    ),
    Field(
      'integrationPattern',
      String,
      'Integration Pattern',
      hint: 'PointToPoint / HubSpoke / PubSub / ESB / ApiGateway',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Protocol and transport details.
  @SectionId('SYINPR')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration protocol)'],
    'The protocol and transport facts for one integration: protocol, direction, '
    'frequency, middleware, and authentication.',
  )
  @Form([
    Field(
      'protocol',
      String,
      'Protocol',
      hint: 'REST / SOAP / gRPC / SFTP / JDBC / AMQP / Kafka / Custom',
    ),
    Field(
      'direction',
      String,
      'Direction',
      hint: 'Inbound / Outbound / Bidirectional',
    ),
    Field(
      'frequency',
      String,
      'Frequency',
      hint: 'Continuous / Hourly / Daily / Weekly / OnDemand',
    ),
    Field(
      'middlewareUsed',
      String,
      'Middleware / Platform',
      hint: 'MuleSoft, Azure Service Bus, none',
    ),
    Field(
      'authenticationMethod',
      String,
      'Authentication Method',
      hint: 'OAuth2 / APIKey / mTLS / BasicAuth / SAML / None',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? protocol;

  /// Data exchange configuration.
  @SectionId('SIDE')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration data exchange)'],
    'The data-exchange configuration of one integration: payloads, message '
    'format, schema version, and transformation complexity.',
  )
  @Form([
    Field(
      'dataExchanged',
      String,
      'Data Exchanged',
      hint: 'Key data entities or payloads exchanged',
    ),
    Field(
      'messageFormat',
      String,
      'Message Format',
      hint: 'JSON / XML / CSV / Avro / Protobuf / EDI / Custom',
    ),
    Field(
      'schemaVersion',
      String,
      'Schema Version',
      hint: 'Current schema or API version',
    ),
    Field(
      'transformationRequired',
      String,
      'Transformation Required',
      hint: 'Yes / No',
    ),
    Field(
      'dataMappingComplexity',
      String,
      'Data Mapping Complexity',
      hint: 'Simple / Moderate / Complex',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dataExchange;

  /// Error handling and retry.
  @SectionId('SIEH')
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (integration error handling)',
  ], 'The error-handling and retry behaviour of one integration.')
  @Form([
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'Retry / DeadLetter / Alert / ManualIntervention',
    ),
    Field(
      'retryPolicy',
      String,
      'Retry Policy',
      hint: '3 retries with exponential backoff',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? errorHandling;

  /// Throughput and capacity.
  @SectionId('SYINTH')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration throughput)'],
    'The throughput and capacity facts for one integration: its capacity, '
    'current utilization, and peak-load behaviour.',
  )
  @Form([
    Field(
      'throughputCapacity',
      String,
      'Throughput Capacity',
      hint: '10k msg/sec, 500 records/batch',
    ),
    Field(
      'currentUtilization',
      String,
      'Current Utilization',
      hint: 'Typical load vs capacity',
    ),
    Field(
      'peakLoadHandling',
      String,
      'Peak Load Handling',
      hint: 'Scales / Queues / Throttles / Degrades',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? throughput;

  /// Monitoring and failover.
  @SectionId('SYINMO')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration monitoring)'],
    'The monitoring and failover facts for one integration: how it is observed '
    'and how it behaves on failure.',
  )
  @Form([
    Field(
      'monitoringAlerting',
      String,
      'Monitoring & Alerting',
      hint: 'Monitoring tools and alert thresholds',
    ),
    Field(
      'failoverBehavior',
      String,
      'Failover Behavior',
      hint: 'AutomaticFailover / ManualFailover / NoFailover',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? monitoring;

  /// Ownership and documentation.
  @SectionId('SYINOW')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration ownership)'],
    'The ownership and documentation facts for one integration: its age, '
    'documentation quality, maintenance owner, and compliance posture.',
  )
  @Form([
    Field(
      'integrationAge',
      String,
      'Integration Age',
      hint: 'When established, e.g. 2019, 7 years',
    ),
    Field(
      'documentationQuality',
      String,
      'Documentation Quality',
      hint: 'Comprehensive / Adequate / Minimal / Undocumented',
    ),
    Field(
      'maintenanceOwner',
      String,
      'Maintenance Owner',
      hint: 'Team or role responsible',
    ),
    Field(
      'securityClassification',
      String,
      'Security Classification',
      hint: 'Public / Internal / Confidential / Restricted',
    ),
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements',
      hint: 'PCI-DSS, GDPR data transfer',
    ),
    Field(
      'technicalDebt',
      String,
      'Technical Debt',
      hint: 'None / Low / Moderate / High',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? ownership;

  @SectionId('SYIN-SOUR-REF')
  @Reference('Source System')
  @SerializationOrder(7)
  ExistingSystemEntry? sourceSystem;

  @SectionId('SYIN-TARG-REF')
  @Reference('Target System')
  @SerializationOrder(8)
  ExistingSystemEntry? targetSystem;
}

// ---------------------------------------------------------------------------
// 1.2 Current Business Processes
// ---------------------------------------------------------------------------

/// 1.2. Current Business Processes.
///
/// Documents the current business processes that the project will impact,
/// replace, or enhance. Understanding existing workflows is critical for
/// gap analysis, migration planning, and ensuring the new system meets
/// operational needs.
@StandardReferences(
  ['BABOK v3 §10 — Define the Current State (as-is business process model)'],
  'The catalogue of business processes operating today that the project will '
  'impact, replace, or enhance — the AS-IS process picture.',
)
@SectionId('CUBUPR')
@DetailedIn(D01CurrentLandscapeAssessment)
class CurrentBusinessProcesses extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Process landscape diagram.
  @SectionId('CUBUPR-PROC')
  @ContentType(
    'mermaid-flowchart',
    'Visual map of business processes showing '
        'hierarchy, relationships, and data flows between processes',
  )
  @ContentHelp(
    'Create a Mermaid flowchart showing the process landscape. '
    'Group processes by category (Core, Support, Management). '
    'Show handoffs and data flows between processes.',
  )
  @SerializationOrder(1)
  DocSpecsSection? processLandscapeDiagram;

  /// Process scope summary.
  @Comment('Defines which processes are in/out of scope')
  @SerializationOrder(2)
  ProcessScopeSummary? scopeSummary;

  /// Process interdependency matrix.
  @Comment('How processes depend on and interact with each other')
  @SerializationOrder(3)
  ProcessInterdependencyMatrix? interdependencyMatrix;

  /// Process performance summary.
  @Comment('High-level summary of process performance')
  @SerializationOrder(4)
  ProcessPerformanceSummary? performanceSummary;

  /// 1.2.nn. Business Processes — contains 1+× Business Process.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (as-is process inventory)'],
    'The ordered set of individual business processes documented for the '
    'current state.',
  )
  @SectionId('CUBIPR-PROC-LST')
  @SectionIdPattern('CUBIPR-PROC-xxx')
  @ContentHelp(
    'Add one entry per business process in scope. Document each '
    'process in full — its workflows, actors, metrics, and pain points.',
  )
  @Min(1)
  @SerializationOrder(5)
  List<CurrentBusinessProcess> processes = [];
}

/// Process scope summary defining in-scope and out-of-scope processes.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (analysis scope)'],
  'The boundary statement for the current-state analysis: which processes are '
  'in scope, which are excluded, and why.',
)
@ContentHelp(
  'Summarize how many processes were identified and which were '
  'selected for analysis. Record the rationale for scope decisions and any '
  'processes deferred to later phases.',
)
@SectionId('PRSCSU')
class ProcessScopeSummary extends DocSpecsSection {
  @Form([
    Field('totalProcessesIdentified', int, 'Total Processes Identified'),
    Field('processesInScope', int, 'Processes In Scope'),
    Field('processesOutOfScope', int, 'Processes Out of Scope'),
    Field(
      'scopeRationale',
      String,
      'Scope Selection Rationale',
      hint: 'Why these processes were selected for analysis',
    ),
    Field(
      'deferredProcesses',
      String,
      'Deferred Processes',
      hint: 'Processes to be addressed in future phases',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Processes in scope.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (in-scope processes)',
  ], 'The processes explicitly included in the current-state analysis.')
  @SectionId('PRSCEN-INSC-LST')
  @SectionIdPattern('PRSCEN-INSC-xxx')
  @ContentHelp(
    'Add one entry per process that is in scope for analysis, with '
    'the rationale for its inclusion.',
  )
  @SerializationOrder(1)
  List<ProcessScopeEntry> inScopeProcesses = [];

  /// Processes explicitly out of scope.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (out-of-scope processes)',
  ], 'The processes deliberately excluded from the current-state analysis.')
  @SectionId('PRSCEN-OUTO-LST')
  @SectionIdPattern('PRSCEN-OUTO-xxx')
  @ContentHelp(
    'Add one entry per process excluded from analysis, noting why '
    'and the impact of leaving it out.',
  )
  @SerializationOrder(2)
  List<ProcessScopeEntry> outOfScopeProcesses = [];
}

/// A process scope entry indicating in/out of scope status.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (scope decision)'],
  'A single scope decision for one process: whether it is in or out of scope '
  'and the reasoning behind that decision.',
)
@SectionId('PRSCEN')
class ProcessScopeEntry extends DocSpecsSection {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field(
      'rationale',
      String,
      'Rationale - why this scope decision',
      hint: 'Why the process is in or out of scope, and to what extent — '
          'record here if it is only partially included',
    ),
    Field('impactIfExcluded', String, 'Impact If Excluded'),
    Field('phase', String, 'Target Phase if deferred'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Process interdependency matrix showing how processes interact.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (process interdependencies)'],
  'The map of how the current processes depend on and interact with each '
  'other, including the artifacts exchanged between them.',
)
@ContentHelp(
  'Document how processes interact: which feed which, what is '
  'exchanged, and how tightly coupled they are. Use the diagram for the '
  'overall picture and the entries for each pairwise dependency.',
)
@SectionId('PRINMA')
class ProcessInterdependencyMatrix extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Interdependency diagram.
  @SectionId('PRINMA-DEPE')
  @ContentType('mermaid-flowchart', 'Visual matrix of process dependencies')
  @ContentHelp(
    'Create a Mermaid flowchart showing process dependencies. '
    'Use edge labels to describe the data/artifact exchanged.',
  )
  @SerializationOrder(1)
  DocSpecsSection? dependencyDiagram;

  /// Individual process dependencies.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (process dependency)',
  ], 'The set of individual dependencies between processes.')
  @SectionId('PRDEEN-DEPE-LST')
  @SectionIdPattern('PRDEEN-DEPE-xxx')
  @ContentHelp(
    'Add one entry per source→target process dependency, capturing '
    'the artifact exchanged, coupling, timing, and failure impact.',
  )
  @SerializationOrder(2)
  List<ProcessDependencyEntry> dependencies = [];
}

/// A single process dependency entry.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (process dependency)'],
  'A single directed dependency between two processes: what flows between '
  'them, how tightly they are coupled, and the impact if it fails.',
)
@SectionId('PRDEEN')
class ProcessDependencyEntry extends DocSpecsSection {
  @Form([
    Field('sourceProcess', String, 'Source Process', required: true),
    Field('targetProcess', String, 'Target Process', required: true),
    Field(
      'dependencyType',
      String,
      'Dependency Type',
      hint: 'Data / Control / Timing / Resource',
    ),
    Field(
      'artifactExchanged',
      String,
      'Artifact/Data Exchanged',
      hint: 'What is passed from source to target',
    ),
    Field(
      'couplingStrength',
      String,
      'Coupling Strength',
      hint: 'Tight / Moderate / Loose',
    ),
    Field(
      'frequency',
      String,
      'Interaction Frequency',
      hint: 'Per transaction / Daily / Weekly / On-demand',
    ),
    Field(
      'timing',
      String,
      'Timing Requirement',
      hint: 'Synchronous / Asynchronous / Batch',
    ),
    Field('failureImpact', String, 'Impact if Dependency Fails'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Process performance summary with high-level metrics.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (process performance baseline)'],
  'A high-level view of how the current processes perform overall: maturity, '
  'automation, manual and error-prone effort, and estimated waste.',
)
@ContentHelp(
  'Summarize the overall health of the current processes — maturity, '
  'automation level, manual and error-prone steps, bottlenecks, and the '
  'estimated cost of inefficiency.',
)
@SectionId('PRPESU')
class ProcessPerformanceSummary extends DocSpecsSection {
  @Form([
    Field(
      'overallMaturity',
      String,
      'Overall Process Maturity',
      hint: 'Ad-hoc / Defined / Managed / Optimized',
    ),
    Field(
      'automationLevel',
      String,
      'Automation Level',
      hint: 'Manual / Partially Automated / Highly Automated / Fully Automated',
    ),
    Field('manualStepsCount', int, 'Total Manual Steps Across Processes'),
    Field('errorProneStepsCount', int, 'Error-Prone Steps Identified'),
    Field('bottleneckCount', int, 'Bottlenecks Identified'),
    Field(
      'duplicatedEffortAreas',
      String,
      'Areas of Duplicated Effort',
      hint: 'Processes or steps where work is duplicated',
    ),
    Field('complianceGaps', int, 'Compliance Gaps Identified'),
    Field(
      'estimatedAnnualWaste',
      String,
      'Estimated Annual Waste',
      hint: 'Cost of inefficiencies in time or money',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Key metrics summary.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (key performance metrics)',
  ], 'The headline metrics chosen to summarize current process performance.')
  @SectionId('PME-KEYM-LST')
  @SectionIdPattern('PME-KEYM-xxx')
  @ContentHelp(
    'Add the most important metrics that characterize overall '
    'process performance at a glance.',
  )
  @SerializationOrder(1)
  List<ProcessMetricEntry> keyMetrics = [];
}

/// A current business process.
///
/// Detailed documentation of a single business process including its
/// workflows, actors, metrics, and pain points.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (as-is process model)',
    'BPMN 2.0 — business process modelling notation',
  ],
  'The complete AS-IS picture of one business process: its context, workflows, '
  'metrics, and pain points as they operate today.',
)
@ContentHelp(
  'Document each business process that the project will impact. '
  'Include process maps (BPMN recommended), actor descriptions, and '
  'quantitative metrics. Identify manual steps and error-prone areas.',
)
@SectionId('CUBIPR')
class CurrentBusinessProcess extends DocSpecsSection {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('processOwner', String, 'Process Owner'),
    Field(
      'processCategory',
      String,
      'Category (e.g., Core, Support, Management)',
    ),
    Field('processScope', String, 'Scope - organizational units involved'),
    Field(
      'processMaturity',
      String,
      'Maturity Level (e.g., Ad-hoc, Defined, Managed, Optimized)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Process context and purpose.
  @SectionId('PC')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (process context and drivers)'],
    'The reason a process exists and how it fits the organization: its purpose, '
    'value, regulatory drivers, SLAs, and up/downstream relationships.',
  )
  @ContentHelp(
    'Describe why this process exists, what business value it delivers, '
    'and how it fits into the overall organizational workflow.',
  )
  @Form([
    Field(
      'businessPurpose',
      String,
      'Business Purpose - why this process exists',
    ),
    Field('businessValue', String, 'Business Value Delivered'),
    Field(
      'regulatoryRequirements',
      String,
      'Regulatory Requirements (compliance drivers)',
    ),
    Field('slaRequirements', String, 'SLA Requirements'),
    Field(
      'upstreamDependencies',
      String,
      'Upstream Dependencies (processes that feed into this one)',
    ),
    Field(
      'downstreamConsumers',
      String,
      'Downstream Consumers (processes that depend on this output)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? processContext;

  /// 1.2.nn.1. Workflow Descriptions — contains 1+× Workflow.
  @SerializationOrder(2)
  WorkflowDescriptions workflowDescriptions = WorkflowDescriptions();

  /// 1.2.nn.2. Process Metrics.
  @SerializationOrder(3)
  ProcessMetrics processMetrics = ProcessMetrics();

  /// Process pain points and improvement opportunities.
  @SerializationOrder(4)
  ProcessPainPoints processPainPoints = ProcessPainPoints();
}

/// Process-specific pain points and improvement opportunities.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (process problems and opportunities)',
  ],
  'The known issues, inefficiencies, and improvement opportunities specific to '
  'one process in its current state.',
)
@ContentHelp(
  'Capture the problems and improvement opportunities specific to '
  'this process — what works poorly today and where it could be better.',
)
@SectionId('PRPAPO')
class ProcessPainPoints extends DocSpecsSection {
  @ContentType(
    'description',
    'Known issues, inefficiencies, and improvement '
        'opportunities specific to this process.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Process improvement opportunities.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (improvement opportunity)',
  ], 'The set of improvement opportunities identified for this process.')
  @SectionId('CPIE-IMPR-LST')
  @SectionIdPattern('CPIE-IMPR-xxx')
  @ContentHelp(
    'Add one entry per improvement opportunity, contrasting the '
    'current and desired state with its benefit, effort, and priority.',
  )
  @SerializationOrder(1)
  List<CurrentProcessImprovementEntry> improvements = [];
}

/// A process improvement opportunity.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (improvement opportunity)'],
  'A single improvement opportunity for the process: the gap between its '
  'current and desired state and the value of closing it.',
)
@SectionId('CPIE')
class CurrentProcessImprovementEntry extends DocSpecsSection {
  @Form([
    Field('improvementArea', String, 'Improvement Area', required: true),
    Field('currentState', String, 'Current State'),
    Field('desiredState', String, 'Desired State'),
    Field('estimatedBenefit', String, 'Estimated Benefit'),
    Field(
      'implementationEffort',
      String,
      'Implementation Effort (Low/Medium/High)',
    ),
    Field('priority', String, 'Priority (Must-have/Should-have/Nice-to-have)'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 1.2.nn.1. Workflow Descriptions.
///
/// Container for workflow entries within a business process.
/// 1.2.nn.1. Workflow Descriptions.
///
/// Container for workflow entries within a business process. Add one
/// subsection per current workflow relevant to the project.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (workflow / process flow)',
    'BPMN 2.0 — business process modelling notation',
  ],
  'The collection of workflows that make up a business process, with their '
  'overview map and per-workflow detail.',
)
@ContentHelp(
  'Describe the workflows that make up this process. Use the '
  'overview diagram for how they fit together and add one entry per '
  'individual workflow below.',
)
@SectionId('WODE')
class WorkflowDescriptions extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Workflow overview diagram.
  @SectionId('WODE-WORK')
  @ContentType(
    'mermaid-flowchart',
    'Visual overview of all workflows in this '
        'process showing relationships and handoffs',
  )
  @ContentHelp(
    'Create a Mermaid flowchart showing how workflows within this '
    'process interact. Show the primary happy-path and exception branches. '
    'Include decision points and actor swim-lanes if helpful.',
  )
  @SerializationOrder(1)
  DocSpecsSection? workflowOverviewDiagram;

  /// Workflow summary table.
  @Comment('Quick reference summary of all workflows')
  @SerializationOrder(2)
  WorkflowSummaryTable? summaryTable;

  /// Individual workflow entries.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow inventory)',
  ], 'The ordered set of individual workflows documented for this process.')
  @SectionId('CUWF-WORK-LST')
  @SectionIdPattern('CUWF-WORK-xxx')
  @ContentHelp(
    'Add one entry per workflow within this process, documenting '
    'its triggers, steps, actors, inputs, outputs, and timing.',
  )
  @Min(1)
  @SerializationOrder(3)
  List<CurrentWorkflowEntry> workflows = [];
}

/// Summary table of all workflows for quick reference.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (workflow summary)'],
  'A quick-reference roll-up of all workflows in the process: counts, cycle '
  'times, and automation potential at a glance.',
)
@ContentHelp(
  'Summarize the workflows for this process — totals, average cycle '
  'time, and automation potential — then add one summary row per workflow.',
)
@SectionId('WOSUTA')
class WorkflowSummaryTable extends DocSpecsSection {
  @Form([
    Field('totalWorkflows', int, 'Total Workflows in Process'),
    Field('primaryWorkflows', int, 'Primary/Happy-Path Workflows'),
    Field('exceptionWorkflows', int, 'Exception/Error Handling Workflows'),
    Field('averageCycleTime', String, 'Average Cycle Time Across Workflows'),
    Field(
      'automationPotential',
      String,
      'Overall Automation Potential',
      hint: 'Low / Medium / High / Full',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Summary entries per workflow.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow summary entry)',
  ], 'The per-workflow rows of the summary table.')
  @SectionId('WOSUEN-ENTR-LST')
  @SectionIdPattern('WOSUEN-ENTR-xxx')
  @ContentHelp(
    'Add one summary row per workflow capturing its type, '
    'frequency, cycle time, step counts, actors, and automation potential.',
  )
  @SerializationOrder(1)
  List<WorkflowSummaryEntry> entries = [];
}

/// Summary entry for a single workflow.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (workflow summary entry)'],
  'A one-line summary of a single workflow: its type, frequency, cycle time, '
  'step and actor counts, and automation potential.',
)
@SectionId('WOSUEN')
class WorkflowSummaryEntry extends DocSpecsSection {
  @Form([
    Field('workflowName', String, 'Workflow Name', required: true),
    Field('workflowType', String, 'Type'),
    Field('frequency', String, 'Frequency'),
    Field('averageCycleTime', String, 'Average Cycle Time'),
    Field('stepCount', int, 'Number of Steps'),
    Field('manualStepCount', int, 'Manual Steps'),
    Field('errorProneStepCount', int, 'Error-Prone Steps'),
    Field('primaryActors', String, 'Primary Actors'),
    Field('automationPotential', String, 'Automation Potential'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A current workflow entry (form).
///
/// Detailed documentation of a single workflow within a business process.
/// Includes triggers, steps, actors, inputs, outputs, and timing.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (as-is workflow model)',
    'BPMN 2.0 — business process modelling notation',
  ],
  'The full AS-IS model of one workflow: how it is triggered, the steps and '
  'actors involved, its inputs/outputs, rules, timing, and exceptions.',
)
@ContentHelp(
  'Document each workflow with enough detail to understand the '
  'current state and identify improvement opportunities. Include swim-lane '
  'diagrams for complex workflows with multiple actors.',
)
@SectionId('CUWF')
class CurrentWorkflowEntry extends DocSpecsSection {
  @Form([
    Field('workflowName', String, 'Workflow Name', required: true),
    Field('workflowId', String, 'Workflow ID (internal identifier)'),
    Field(
      'workflowType',
      String,
      'Type (e.g., Operational, Approval, Exception)',
    ),
    Field('frequency', String, 'Execution Frequency'),
    Field('averageVolume', String, 'Average Volume per period'),
    Field('criticality', String, 'Business Criticality'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Workflow diagram.
  @SectionId('CUWF-WORK')
  @ContentType(
    'mermaid-flowchart',
    'Visual representation of this workflow '
        'showing steps, decisions, and actors in a BPMN-style diagram',
  )
  @ContentHelp(
    'Create a Mermaid flowchart or sequence diagram showing the '
    'workflow steps in order. Include decision points with branch conditions. '
    'For multi-actor workflows, use swim-lanes (subgraphs) per actor.',
  )
  @SerializationOrder(1)
  DocSpecsSection? workflowDiagram;

  /// Workflow triggers and initiation.
  @SerializationOrder(2)
  WorkflowTriggers triggers = WorkflowTriggers();

  /// Workflow steps in sequence.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow steps / activities)',
  ], 'The ordered sequence of steps that make up the workflow.')
  @SectionId('WSE-STEP-LST')
  @SectionIdPattern('WSE-STEP-xxx')
  @ContentHelp(
    'Add the workflow steps in execution order, capturing the '
    'responsible actor, inputs/outputs, and whether each is manual, '
    'automatable and error-prone. Steps are listed here once: mark a step '
    'that needs human judgment or that fails often with the corresponding '
    'flag rather than repeating it in a second list.',
  )
  @SerializationOrder(3)
  List<WorkflowStepEntry> steps = [];

  /// Workflow actors and responsibilities.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow participants / roles)',
  ], 'The actors who participate in the workflow and their responsibilities.')
  @SectionId('WAE-ACTO-LST')
  @SectionIdPattern('WAE-ACTO-xxx')
  @ContentHelp(
    'Add one entry per actor (role, system, department, external) '
    'taking part in this workflow, with their responsibilities and '
    'authorization level.',
  )
  @SerializationOrder(4)
  List<WorkflowActorEntry> actors = [];

  /// Workflow inputs.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow inputs)',
  ], 'The data and documents consumed by the workflow.')
  @SectionId('WOINEN-INPU-LST')
  @SectionIdPattern('WOINEN-INPU-xxx')
  @ContentHelp(
    'Add one entry per input the workflow consumes, with its '
    'source, format, and validation rules.',
  )
  @SerializationOrder(5)
  List<WorkflowInputEntry> inputs = [];

  /// Workflow outputs.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow outputs)',
  ], 'The data and documents produced by the workflow.')
  @SectionId('WOOUEN-OUTP-LST')
  @SectionIdPattern('WOOUEN-OUTP-xxx')
  @ContentHelp(
    'Add one entry per output the workflow produces, with its '
    'destination, format, and retention requirements.',
  )
  @SerializationOrder(6)
  List<WorkflowOutputEntry> outputs = [];

  /// Decision points within the workflow.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (decision points)',
    'BPMN 2.0 — gateways (decision points)',
  ], 'The points in the workflow where a decision branches the flow.')
  @SectionId('WODEPO-DECI-LST')
  @SectionIdPattern('WODEPO-DECI-xxx')
  @ContentHelp(
    'Add one entry per decision point, with its criteria, decision '
    'maker, possible outcomes, and escalation path.',
  )
  @SerializationOrder(7)
  List<WorkflowDecisionPoint> decisionPoints = [];

  /// Business rules governing the workflow.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (business rules)',
  ], 'The business rules that govern how the workflow behaves.')
  @SectionId('WOBURU-BUSI-LST')
  @SectionIdPattern('WOBURU-BUSI-xxx')
  @ContentHelp(
    'Add one entry per business rule constraining this workflow, '
    'with its logic, source, and exceptions.',
  )
  @SerializationOrder(8)
  List<WorkflowBusinessRule> businessRules = [];

  /// Workflow timing and performance.
  @SectionId('WOTI')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (workflow timing and performance)'],
    'The timing profile of the workflow: elapsed, processing and wait times, SLA '
    'performance, peak periods, and bottlenecks.',
  )
  @Form([
    Field('startToEndTime', String, 'Start-to-End Time (total elapsed)'),
    Field('processingTime', String, 'Processing Time (active work time)'),
    Field('waitTime', String, 'Wait Time'),
    Field('slaTarget', String, 'SLA Target'),
    Field('slaMet', String, 'SLA Compliance Rate'),
    Field('peakPeriods', String, 'Peak Periods (times of highest volume)'),
    Field('bottlenecks', String, 'Bottlenecks (steps causing delays)'),
  ])
  @SerializationOrder(9)
  DocSpecsSection? timing;

  /// Workflow exceptions and error handling.
  @SerializationOrder(10)
  WorkflowExceptions exceptions = WorkflowExceptions();
}

/// Workflow triggers and initiation conditions.
@StandardReferences([
  'BABOK v3 §10 — current-state analysis (workflow triggers / events)',
], 'The conditions and events that cause this workflow to start.')
@ContentHelp(
  'Describe what initiates this workflow and list each distinct '
  'trigger with its type, source, and conditions.',
)
@SectionId('WOTR')
class WorkflowTriggers extends DocSpecsSection {
  @ContentType('description', 'Conditions that initiate this workflow.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Trigger entries.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow trigger)',
  ], 'The set of distinct triggers that can start this workflow.')
  @SectionId('WOTREN-TRIG-LST')
  @SectionIdPattern('WOTREN-TRIG-xxx')
  @ContentHelp(
    'Add one entry per trigger, with its type (event, schedule, '
    'manual, system), source, condition, and frequency.',
  )
  @SerializationOrder(1)
  List<WorkflowTriggerEntry> triggers = [];
}

/// A single workflow trigger.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (workflow trigger)'],
  'A single initiating condition for the workflow: its type, source, '
  'condition, and frequency.',
)
@SectionId('WOTREN')
class WorkflowTriggerEntry extends DocSpecsSection {
  @Form([
    Field('triggerName', String, 'Trigger Name', required: true),
    Field(
      'triggerType',
      String,
      'Type (e.g., Event, Schedule, Manual, System)',
    ),
    Field('triggerSource', String, 'Source - origin of the trigger'),
    Field(
      'triggerCondition',
      String,
      'Condition - conditions that must be met',
    ),
    Field('frequency', String, 'Frequency'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A system used in a workflow step.
@StandardReferences([
  'BABOK v3 §10 — current-state analysis (system used in workflow step)',
], 'A single system that a workflow step relies on to do its work.')
@SectionId('WOSTSY')
class WorkflowStepSystem extends DocSpecsSection {
  @SectionId('WOSTSY-NAME')
  @ContentHelp('Name of the system used in this workflow step.')
  @SerializationOrder(0)
  DocSpecsSection? name;
}

/// A workflow step entry (form).
///
/// Detailed documentation of a single step within a workflow.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (workflow step / activity)',
    'BPMN 2.0 — tasks and activities',
  ],
  'The full detail of one workflow step: what it does, who performs it, the '
  'systems and data it uses, whether it is manual, and its known issues.',
)
@ContentHelp(
  'Document each step with enough detail for process analysis and '
  'system design. Include responsible actors, inputs, outputs, and timing.',
)
@SectionId('WSE')
class WorkflowStepEntry extends DocSpecsSection {
  @Form([
    Field('stepName', String, 'Step Name', required: true),
    Field('stepNumber', int, 'Step Number (sequence order)'),
    Field('description', String, 'Description'),
    Field('responsibleActor', String, 'Responsible Actor'),
    Field(
      'stepType',
      String,
      'Step Type (e.g., Task, Decision, Wait, Subprocess)',
    ),
    Field(
      'isManual',
      bool,
      'Is Manual (requires human intervention)',
      hint: 'Whether carrying the step out needs a person; an automated step '
          'runs without human intervention',
    ),
    Field('isAutomatable', bool, 'Is Automatable'),
    Field(
      'isErrorProne',
      bool,
      'Is Error-Prone (high error or failure rate)',
      hint: 'Whether the step fails or is got wrong often enough to matter; '
          'the known issues below record which failures and how often',
    ),
    Field('averageDuration', String, 'Average Duration'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Systems used in this step.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (systems used in step)',
  ], 'The systems this step relies on to perform its work.')
  @SectionId('WOSTSY-SYST-LST')
  @SectionIdPattern('WOSTSY-SYST-xxx')
  @ContentHelp('Add one entry per system the step uses.')
  @SerializationOrder(1)
  List<WorkflowStepSystem> systemsUsed = [];

  /// Step inputs.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (step inputs)',
  ], 'The data and documents this step consumes.')
  @SectionId('WOINEN-INPU-LST')
  @SectionIdPattern('WOINEN-INPU-xxx')
  @ContentHelp(
    'Add one entry per input this step consumes, with its source, '
    'format, and validation rules.',
  )
  @SerializationOrder(2)
  List<WorkflowInputEntry> inputs = [];

  /// Step outputs.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (step outputs)',
  ], 'The data and documents this step produces.')
  @SectionId('WOOUEN-OUTP-LST')
  @SectionIdPattern('WOOUEN-OUTP-xxx')
  @ContentHelp(
    'Add one entry per output this step produces, with its '
    'destination and format.',
  )
  @SerializationOrder(3)
  List<WorkflowOutputEntry> outputs = [];

  /// Step-specific business rules.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (step business rules)',
  ], 'The business rules that govern how this step behaves.')
  @SectionId('WOBURU-BUSI-LST')
  @SectionIdPattern('WOBURU-BUSI-xxx')
  @ContentHelp(
    'Add one entry per business rule constraining this step, with '
    'its logic, source, and exceptions.',
  )
  @SerializationOrder(4)
  List<WorkflowBusinessRule> businessRules = [];

  /// Known issues with this step.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (step known issues)',
  ], 'The known problems and recurring failures associated with this step.')
  @SectionId('WOSTIS-KNOW-LST')
  @SectionIdPattern('WOSTIS-KNOW-xxx')
  @ContentHelp(
    'Add one entry per known issue with this step, noting its '
    'frequency, impact, and any current workaround.',
  )
  @SerializationOrder(5)
  List<WorkflowStepIssue> knownIssues = [];
}

/// Known issue with a workflow step.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (step known issue)'],
  'A single known problem with a workflow step: how often it occurs, its '
  'business impact, and any workaround in use.',
)
@SectionId('WOSTIS')
class WorkflowStepIssue extends DocSpecsSection {
  @Form([
    Field('issueName', String, 'Issue Name', required: true),
    Field('issueDescription', String, 'Description'),
    Field('frequency', String, 'Frequency of occurrence'),
    Field('impact', String, 'Business Impact'),
    Field('currentWorkaround', String, 'Current Workaround'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A workflow actor entry (form).
///
/// Documentation of a participant in the workflow.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (workflow participant / role)'],
  'A single participant in the workflow: its role, responsibilities, '
  'authorization, skills, and headcount.',
)
@ContentHelp(
  'Document all actors including their roles, responsibilities, '
  'authorization levels, and involvement pattern.',
)
@SectionId('WAE')
class WorkflowActorEntry extends DocSpecsSection {
  @Form([
    Field('actorName', String, 'Actor Name', required: true),
    Field(
      'actorType',
      String,
      'Actor Type (e.g., Role, System, Department, External)',
    ),
    Field('role', String, 'Role in this workflow'),
    Field('responsibilities', String, 'Responsibilities'),
    Field('authorizationLevel', String, 'Authorization Level'),
    Field('availabilityRequirements', String, 'Availability Requirements'),
    Field('skillRequirements', String, 'Skill Requirements'),
    Field('headcount', int, 'Headcount (number of people in this role)'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Steps this actor participates in.
  @SectionId('WAE-PART-REF')
  @Reference('Participating Steps')
  @SerializationOrder(1)
  List<WorkflowStepEntry> participatingSteps = [];
}

/// A workflow input.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (workflow input)'],
  'A single input consumed by a workflow or step: its type, source, format, '
  'and validation rules.',
)
@SectionId('WOINEN')
class WorkflowInputEntry extends DocSpecsSection {
  @Form([
    Field('inputName', String, 'Input Name', required: true),
    Field('inputType', String, 'Type (data type or document type)'),
    Field('source', String, 'Source'),
    Field('format', String, 'Format (e.g., PDF, XML, Manual Entry)'),
    Field('isRequired', bool, 'Is Required'),
    Field('validationRules', String, 'Validation Rules'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A workflow output.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (workflow output)'],
  'A single output produced by a workflow or step: its type, destination, '
  'format, and retention requirements.',
)
@SectionId('WOOUEN')
class WorkflowOutputEntry extends DocSpecsSection {
  @Form([
    Field('outputName', String, 'Output Name', required: true),
    Field('outputType', String, 'Type (data type or document type)'),
    Field('destination', String, 'Destination'),
    Field('format', String, 'Format'),
    Field('retentionRequirements', String, 'Retention Requirements'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A decision point within a workflow.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (decision point)',
    'BPMN 2.0 — gateways (decision points)',
  ],
  'A single branching decision in the workflow: its criteria, who decides, the '
  'possible outcomes, and the escalation path.',
)
@SectionId('WODEPO')
class WorkflowDecisionPoint extends DocSpecsSection {
  @Form([
    Field('decisionName', String, 'Decision Name', required: true),
    Field('decisionCriteria', String, 'Decision Criteria'),
    Field('decisionMaker', String, 'Decision Maker'),
    Field('outcomes', String, 'Possible Outcomes (comma-separated)'),
    Field('escalationPath', String, 'Escalation Path'),
    Field('slaForDecision', String, 'SLA for Decision'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A business rule governing workflow behavior.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (business rule)'],
  'A single business rule constraining the workflow: its logic, governing '
  'source, and the cases where it does not apply.',
)
@SectionId('WOBURU')
class WorkflowBusinessRule extends DocSpecsSection {
  @Form([
    Field('ruleName', String, 'Rule Name', required: true),
    Field('ruleDescription', String, 'Description'),
    Field('ruleLogic', String, 'Rule Logic (business logic in plain language)'),
    Field('ruleSource', String, 'Source (e.g., Policy, Regulation, SOP)'),
    Field('exceptions', String, 'Exceptions - when this rule does not apply'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Workflow exception handling.
@StandardReferences([
  'BABOK v3 §10 — current-state analysis (exception handling)',
], 'How the workflow deals with exceptions and error conditions today.')
@ContentHelp(
  'Describe how exceptions are handled in this workflow and list '
  'each distinct exception type with its handling and escalation.',
)
@SectionId('WOEX')
class WorkflowExceptions extends DocSpecsSection {
  @ContentType('description', 'How exceptions are handled in this workflow.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Exception entries.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (workflow exception)',
  ], 'The set of exception types the workflow must handle.')
  @SectionId('WOEXEN-EXCE-LST')
  @SectionIdPattern('WOEXEN-EXCE-xxx')
  @ContentHelp(
    'Add one entry per exception type, with its frequency, handling '
    'procedure, escalation path, and recovery time.',
  )
  @SerializationOrder(1)
  List<WorkflowExceptionEntry> exceptions = [];
}

/// A workflow exception type.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (workflow exception)'],
  'A single exception type the workflow handles: how often it occurs, the '
  'handling procedure, escalation path, and recovery time.',
)
@SectionId('WOEXEN')
class WorkflowExceptionEntry extends DocSpecsSection {
  @Form([
    Field('exceptionName', String, 'Exception Name', required: true),
    Field('exceptionType', String, 'Type (e.g., Validation, System, Business)'),
    Field('frequency', String, 'Frequency'),
    Field('handlingProcedure', String, 'Handling Procedure'),
    Field('escalationPath', String, 'Escalation Path'),
    Field('recoveryTime', String, 'Recovery Time'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 1.2.2. Process Metrics.
///
/// Quantitative metrics for measuring process performance. These metrics
/// form the baseline against which improvements will be measured.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (performance measures / baseline)'],
  'The quantitative performance baseline of a process: its efficiency, '
  'quality, volume, cost, and manual-intervention metrics as measured today.',
)
@ContentHelp(
  'Document current process performance including throughput, '
  'cycle times, error rates, and manual intervention frequency. '
  'These become the baseline against which improvements are measured.',
)
@SectionId('PM')
class ProcessMetrics extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of process metrics and measurement approach.',
  )
  @ContentHelp(
    'Describe the overall approach to measuring process performance. '
    'Include data collection methods, measurement periods, and data quality notes.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Metrics dashboard summary.
  @Comment('Executive summary of key metrics')
  @SerializationOrder(1)
  MetricsDashboardSummary? dashboardSummary;

  /// Efficiency metrics.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (efficiency measures)'],
    'The efficiency metrics for the process: throughput, cycle times, and '
    'resource utilization.',
  )
  @SectionId('PRMECA-EFFI-LST')
  @SectionIdPattern('PRMECA-EFFI-xxx')
  @ContentHelp('Add efficiency metrics — throughput, cycle times, utilization.')
  @Comment('Throughput, cycle times, utilization')
  @SerializationOrder(2)
  List<ProcessMetricCategory> efficiencyMetrics = [];

  /// Quality metrics.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (quality measures)',
  ], 'The quality metrics for the process: error, defect, and rework rates.')
  @SectionId('PRMECA-QUAL-LST')
  @SectionIdPattern('PRMECA-QUAL-xxx')
  @ContentHelp('Add quality metrics — error rates, defect rates, rework rates.')
  @Comment('Error rates, defect rates, rework rates')
  @SerializationOrder(3)
  List<ProcessMetricCategory> qualityMetrics = [];

  /// Volume metrics.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (volume measures)'],
    'The volume metrics for the process: transaction counts and throughput '
    'volumes.',
  )
  @SectionId('PRMECA-VOLU-LST')
  @SectionIdPattern('PRMECA-VOLU-xxx')
  @ContentHelp('Add volume metrics — transaction counts, throughput volumes.')
  @Comment('Transaction counts, throughput volumes')
  @SerializationOrder(4)
  List<ProcessMetricCategory> volumeMetrics = [];

  /// Cost metrics.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (cost measures)'],
    'The cost metrics for the process: cost per transaction and resource '
    'costs.',
  )
  @SectionId('PRMECA-COST-LST')
  @SectionIdPattern('PRMECA-COST-xxx')
  @ContentHelp('Add cost metrics — cost per transaction, resource costs.')
  @Comment('Cost per transaction, resource costs')
  @SerializationOrder(5)
  List<ProcessMetricCategory> costMetrics = [];

  /// Manual intervention metrics.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (manual-intervention measures)',
  ], 'The metrics describing how much manual effort the process requires.')
  @SectionId('PRMECA-MANU-LST')
  @SectionIdPattern('PRMECA-MANU-xxx')
  @ContentHelp(
    'Add manual-intervention metrics — manual steps, human '
    'intervention frequency.',
  )
  @Comment('Manual steps, human intervention frequency')
  @SerializationOrder(6)
  List<ProcessMetricCategory> manualInterventionMetrics = [];

  /// Individual metric entries.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (individual metrics)',
  ], 'The flat list of individual metric entries not grouped by category.')
  @SectionId('PME-ITEM-LST')
  @SectionIdPattern('PME-ITEM-xxx')
  @ContentHelp(
    'Add any individual metrics that do not fit a specific '
    'category above.',
  )
  @SerializationOrder(7)
  List<ProcessMetricEntry> items = [];

  /// Baseline comparison table.
  @Comment('Summary table for baseline tracking')
  @SerializationOrder(8)
  MetricsBaselineTable? baselineTable;
}

/// Metrics dashboard summary for executive overview.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (performance dashboard)'],
  'An executive roll-up of the headline process metrics: throughput, cycle '
  'time, error and manual-intervention rates, utilization, and overall trend.',
)
@ContentHelp(
  'Summarize the key process metrics for an executive audience — '
  'measurement period, data quality, and the headline performance figures.',
)
@SectionId('MEDASU')
class MetricsDashboardSummary extends DocSpecsSection {
  @Form([
    Field(
      'measurementPeriod',
      String,
      'Measurement Period',
      hint: 'Time period covered by these metrics, e.g., Q1 2024',
    ),
    Field(
      'dataQuality',
      String,
      'Data Quality Assessment',
      hint: 'High / Medium / Low - confidence in metric accuracy',
    ),
    Field(
      'keyThroughput',
      String,
      'Key Throughput Metric',
      hint: 'Primary volume metric, e.g., 5000 orders/day',
    ),
    Field(
      'averageCycleTime',
      String,
      'Average Cycle Time',
      hint: 'End-to-end processing time, e.g., 4.2 hours',
    ),
    Field(
      'overallErrorRate',
      String,
      'Overall Error Rate',
      hint: 'Combined error rate, e.g., 3.2%',
    ),
    Field(
      'manualInterventionRate',
      String,
      'Manual Intervention Rate',
      hint: 'Percentage of cases requiring manual handling',
    ),
    Field(
      'processEfficiency',
      String,
      'Process Efficiency',
      hint: 'Value-add time vs total time ratio',
    ),
    Field(
      'capacityUtilization',
      String,
      'Capacity Utilization',
      hint: 'Current volume vs maximum capacity',
    ),
    Field(
      'complianceRate',
      String,
      'SLA/Compliance Rate',
      hint: 'Percentage meeting SLA targets',
    ),
    Field(
      'trendSummary',
      String,
      'Overall Trend',
      hint: 'Improving / Stable / Declining',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Baseline table for tracking metrics over time.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (baseline for improvement tracking)'],
  'The set of baselined metrics against which future improvement will be '
  'measured, with their current and target values.',
)
@SectionId('MEBATA')
class MetricsBaselineTable extends DocSpecsSection {
  @ContentType(
    'description',
    'Baseline tracking approach and comparison periods.',
  )
  @ContentHelp(
    'Document how baseline metrics will be used to measure improvement. '
    'Include comparison periods and target improvement percentages.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Baseline entries.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (baseline entry)',
  ], 'The individual baselined metrics tracked for improvement.')
  @SectionId('MEBAEN-ENTR-LST')
  @SectionIdPattern('MEBAEN-ENTR-xxx')
  @ContentHelp(
    'Add one entry per metric to be tracked, with its baseline '
    'value, target value, and improvement target.',
  )
  @SerializationOrder(1)
  List<MetricsBaselineEntry> entries = [];
}

/// A baseline entry for tracking metric changes.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (baseline entry)'],
  'A single baselined metric: its current value, target value, dates, and the '
  'improvement expected.',
)
@SectionId('MEBAEN')
class MetricsBaselineEntry extends DocSpecsSection {
  @Form([
    Field('metricName', String, 'Metric Name', required: true),
    Field('baselineValue', String, 'Baseline Value (current state)'),
    Field('baselineDate', String, 'Baseline Date'),
    Field('targetValue', String, 'Target Value'),
    Field('targetDate', String, 'Target Date'),
    Field(
      'improvementTarget',
      String,
      'Improvement Target',
      hint: 'Percentage or absolute improvement expected',
    ),
    Field(
      'trackingFrequency',
      String,
      'Tracking Frequency',
      hint: 'How often this metric will be re-measured',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A category of process metrics.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (metric category)'],
  'A grouping of related process metrics under one category (e.g. efficiency, '
  'quality, volume, cost).',
)
@ContentHelp(
  'Group related metrics under this category and add one entry per '
  'metric it contains.',
)
@SectionId('PRMECA')
class ProcessMetricCategory extends DocSpecsSection {
  @ContentType('description', 'Category-level summary of metrics.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Metrics in this category.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (metrics in category)',
  ], 'The individual metrics belonging to this category.')
  @SectionId('PME-METR-LST')
  @SectionIdPattern('PME-METR-xxx')
  @ContentHelp(
    'Add one entry per metric in this category, with its current '
    'value, unit, and measurement details.',
  )
  @SerializationOrder(1)
  List<ProcessMetricEntry> metrics = [];
}

/// A process metric entry (form).
///
/// A single measurable metric with current value and measurement details.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (performance metric)'],
  'A single measurable process metric: its current value and unit, how it is '
  'measured, and its target/benchmark context.',
)
@ContentHelp(
  'Define each metric clearly with current baseline values, '
  'measurement methodology, and target values if known.',
)
@SectionId('PME')
class ProcessMetricEntry extends DocSpecsSection {
  @Form([
    Field('metricName', String, 'Metric Name', required: true),
    Field('metricId', String, 'Metric ID'),
    Field(
      'metricCategory',
      String,
      'Category (e.g., Efficiency, Quality, Volume, Cost)',
      hint: 'Only for metrics listed on their own — a metric listed inside a '
          'metric category takes that category and leaves this empty',
    ),
    Field('currentValue', String, 'Current Value'),
    Field('unit', String, 'Unit'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Measurement collection details.
  @SectionId('PMEM')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (metric measurement method)'],
    'How a metric is collected: its measurement method, data source, and '
    'measurement frequency.',
  )
  @ContentHelp(
    'Record how this metric is measured — the method, data source, '
    'and how often it is collected.',
  )
  @Form([
    Field('measurementMethod', String, 'Measurement Method'),
    Field('dataSource', String, 'Data Source'),
    Field('frequency', String, 'Measurement Frequency'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? measurement;

  /// Target setting and benchmarking context.
  @SectionId('PMET')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (metric target and benchmark)'],
    'The target and benchmarking context for a metric: its target value, trend, '
    'and industry benchmark.',
  )
  @ContentHelp(
    'Record the target value for this metric, its current trend, and '
    'any industry benchmark for comparison.',
  )
  @Form([
    Field('targetValue', String, 'Target Value'),
    Field('trend', String, 'Trend (Improving, Stable, Declining)'),
    Field('benchmark', String, 'Industry Benchmark'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? targets;

  @SectionId('PME-PROC-REF')
  @Reference('Process Reference')
  @SerializationOrder(3)
  CurrentBusinessProcess? processReference;
}

// ---------------------------------------------------------------------------
// 1.3 Pain Points and Gaps
// ---------------------------------------------------------------------------

/// 1.3. Pain Points and Gaps.
///
/// Comprehensive documentation of specific problems, inefficiencies,
/// compliance gaps, and user frustrations in the current state.
/// Each pain point includes business impact quantification and root cause.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (problem & opportunity identification)',
  ],
  'The catalogue of AS-IS problems, inefficiencies, and capability gaps that '
  'justify change — the pain the future solution must relieve.',
)
@SectionId('PPAG')
@DetailedIn(D01CurrentLandscapeAssessment)
class PainPointsAndGaps extends DocSpecsSection {
  @ContentHelp('''
Executive overview of pain points and gaps in the current state.
Summarize the most critical issues affecting operations, business outcomes,
and technical capabilities. Highlight interdependencies between pain points.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual mapping of pain points and their relationships.
  @SectionId('PPAG-PAIN')
  @ContentType(
    'mermaid-flowchart',
    'Diagram showing pain point categories, '
        'relationships, and impact flow between operational, business, '
        'and technical pain points',
  )
  @SerializationOrder(1)
  DocSpecsSection? painPointsOverviewDiagram;

  /// Pain points priority matrix (urgency vs impact).
  @SectionId('PPAG-PAINP')
  @ContentType(
    'mermaid',
    'Quadrant chart mapping pain points by urgency and '
        'impact dimensions to guide prioritization decisions',
  )
  @SerializationOrder(2)
  DocSpecsSection? painPointsPriorityMatrix;

  /// Summary statistics for all pain points.
  @SectionId('PAPOSU')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (measurement of current performance)',
    ],
    'Aggregate roll-up of all documented pain points — counts, severity mix, and '
    'total cost — giving a single quantified view of the AS-IS problem space.',
  )
  @ContentHelp(
    'Summarize the documented pain points as a whole: totals by '
    'severity, aggregate cost and productivity loss, and the most affected '
    'process and stakeholder group. Derive these from the individual entries.',
  )
  @Form([
    Field(
      'totalPainPoints',
      int,
      'Total Pain Points',
      hint: 'Total number of documented pain points across all categories',
    ),
    Field(
      'criticalCount',
      int,
      'Critical Count',
      hint: 'Number of pain points rated as critical severity',
    ),
    Field(
      'highCount',
      int,
      'High Severity Count',
      hint: 'Number of pain points rated as high severity',
    ),
    Field(
      'mediumCount',
      int,
      'Medium Severity Count',
      hint: 'Number of pain points rated as medium severity',
    ),
    Field(
      'lowCount',
      int,
      'Low Severity Count',
      hint: 'Number of pain points rated as low severity',
    ),
    Field(
      'totalEstimatedAnnualCost',
      String,
      'Total Estimated Annual Cost',
      hint:
          'Aggregate annual cost of all documented pain points, e.g. €850k/year',
    ),
    Field(
      'totalProductivityLoss',
      String,
      'Total Productivity Loss',
      hint: 'Aggregate productivity loss, e.g. 120 FTE hours/month',
    ),
    Field(
      'mostAffectedProcess',
      String,
      'Most Affected Process',
      hint: 'Business process with the highest concentration of pain points',
    ),
    Field(
      'mostAffectedStakeholder',
      String,
      'Most Affected Stakeholder Group',
      hint: 'User role or department most impacted by pain points',
    ),
    Field(
      'averageResolutionComplexity',
      String,
      'Average Resolution Complexity',
      hint: 'Low / Medium / High / Very High',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? painPointsSummary;

  /// 1.3.1. Operational Pain Points.
  @SerializationOrder(4)
  OperationalPainPoints operationalPainPoints = OperationalPainPoints();

  /// 1.3.2. Business Pain Points.
  @SerializationOrder(5)
  BusinessPainPoints businessPainPoints = BusinessPainPoints();

  /// 1.3.3. Technical Pain Points.
  @SerializationOrder(6)
  TechnicalPainPoints technicalPainPoints = TechnicalPainPoints();

  /// 1.3.4. Gaps.
  @StandardReferences([
    'BABOK v3 §6 — gap analysis (capability gap identification)',
  ], 'The list of individual capability gaps documented in detail.')
  @SectionId('GAPE-ITEM-LST')
  @SectionIdPattern('GAPE-ITEM-xxx')
  @ContentHelp(
    'Add one entry per identified gap between current capabilities '
    'and business needs, each with its category, severity, cost, drivers, '
    'and proposed resolution.',
  )
  @SerializationOrder(7)
  List<GapEntry> gaps = [];

  /// Cross-reference between pain points and gaps.
  @SerializationOrder(8)
  PainPointGapCorrelation painPointGapCorrelation = PainPointGapCorrelation();
}

/// 1.3.1. Operational Pain Points.
///
/// Problems that affect day-to-day operations: downtime, slow response,
/// data inconsistencies, manual workarounds, and process interruptions.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (operational performance shortfalls)',
  ],
  'Day-to-day operational problems in the current state — downtime, manual '
  'workarounds, and data inconsistencies that disrupt routine work.',
)
@SectionId('OPPAPO')
class OperationalPainPoints extends DocSpecsSection {
  @ContentHelp('''
Overview of operational pain points affecting day-to-day activities.
Include patterns of recurring issues, seasonal variations, and dependencies
on specific systems or personnel.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Category-level summary for operational pain points.
  @SectionId('OPPS')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (operational measures)'],
    'Category roll-up quantifying the operational pain points — downtime, '
    'workaround count, and staff overhead in the current state.',
  )
  @ContentHelp(
    'Aggregate the operational pain points into category metrics: '
    'average downtime, number of manual workarounds, data-inconsistency '
    'frequency, and staff overhead spent on workarounds.',
  )
  @Form([
    Field(
      'averageDowntimePerMonth',
      String,
      'Average Downtime per Month',
      hint: 'Total system/process downtime, e.g. 4.5 hours/month',
    ),
    Field(
      'manualWorkaroundsCount',
      int,
      'Number of Manual Workarounds',
      hint: 'Count of documented manual workarounds in use',
    ),
    Field(
      'dataInconsistencyFrequency',
      String,
      'Data Inconsistency Frequency',
      hint:
          'How often data inconsistencies occur, e.g. Daily / Weekly / Monthly',
    ),
    Field(
      'criticalProcessesAffected',
      int,
      'Critical Processes Affected',
      hint: 'Number of critical business processes impacted',
    ),
    Field(
      'staffOverhead',
      String,
      'Staff Overhead for Workarounds',
      hint: 'FTE hours spent on operational workarounds, e.g. 40 hours/week',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? categorySummary;

  /// Contains 0+× PainPoint.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (problem identification)',
  ], 'The list of individual operational pain points documented in detail.')
  @SectionId('PAPE-ITEM-LST')
  @SectionIdPattern('PAPE-ITEM-xxx')
  @ContentHelp(
    'Add one entry per distinct operational problem, each with its '
    'own root cause, impact, and workaround. Keep entries scoped to '
    'day-to-day operations rather than business or technical concerns.',
  )
  @SerializationOrder(2)
  List<PainPointEntry> items = [];
}

/// 1.3.2. Business Pain Points.
///
/// Problems that affect business outcomes: lost revenue, compliance risk,
/// customer dissatisfaction, inability to scale, and missed opportunities.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (business performance shortfalls)'],
  'Problems in the current state that erode business outcomes — lost revenue, '
  'compliance exposure, customer dissatisfaction, and missed opportunities.',
)
@SectionId('BUPAPO')
class BusinessPainPoints extends DocSpecsSection {
  @ContentHelp('''
Overview of business pain points affecting strategic outcomes and growth.
Include revenue impact, compliance exposure, customer retention effects,
and competitive positioning concerns.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Category-level summary for business pain points.
  @SectionId('BPPS')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (business measures)'],
    'Category roll-up quantifying the business pain points — revenue loss, '
    'compliance exposure, and customer-satisfaction impact in the current state.',
  )
  @ContentHelp(
    'Aggregate the business pain points into category metrics: '
    'estimated revenue loss, compliance risk exposure, customer-satisfaction '
    'impact, and scalability constraints.',
  )
  @Form([
    Field(
      'estimatedRevenueLoss',
      String,
      'Estimated Annual Revenue Loss',
      hint: 'Revenue lost due to business pain points, e.g. €250k/year',
    ),
    Field(
      'complianceRiskExposure',
      String,
      'Compliance Risk Exposure',
      hint: 'Potential regulatory penalties or fines, e.g. up to €500k',
    ),
    Field(
      'customerSatisfactionImpact',
      String,
      'Customer Satisfaction Impact',
      hint: 'NPS or CSAT impact, e.g. -15 NPS points',
    ),
    Field(
      'marketShareImpact',
      String,
      'Market Share Impact',
      hint: 'Estimated market share loss, e.g. 2-3% market share',
    ),
    Field(
      'missedOpportunitiesCost',
      String,
      'Missed Opportunities Cost',
      hint: 'Revenue from opportunities not pursued, e.g. €400k/year',
    ),
    Field(
      'scalabilityConstraints',
      String,
      'Scalability Constraints',
      hint: 'Growth limitations, e.g. Cannot support >10k concurrent users',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? categorySummary;

  /// Contains 0+× PainPoint.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (problem identification)',
  ], 'The list of individual business pain points documented in detail.')
  @SectionId('PAPE-ITEM-LST')
  @SectionIdPattern('PAPE-ITEM-xxx')
  @ContentHelp(
    'Add one entry per distinct business problem, each with its own '
    'root cause, quantified impact, and resolution outlook. Scope entries to '
    'strategic and financial outcomes rather than operational or technical '
    'detail.',
  )
  @SerializationOrder(2)
  List<PainPointEntry> items = [];
}

/// 1.3.3. Technical Pain Points.
///
/// Problems that affect development and maintenance: outdated technology,
/// security vulnerabilities, lack of documentation, vendor lock-in,
/// and technical debt.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (technology & infrastructure constraints)',
  ],
  'Problems in the current state that hinder development and maintenance — '
  'aging technology, security vulnerabilities, technical debt, and lock-in.',
)
@SectionId('TEPAPO')
class TechnicalPainPoints extends DocSpecsSection {
  @ContentHelp('''
Overview of technical pain points affecting system development, maintenance,
and evolution. Include technology obsolescence risks, security posture,
integration complexity, and team capability constraints.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Category-level summary for technical pain points.
  @SectionId('TPPS')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (technical measures)'],
    'Category roll-up quantifying the technical pain points — technical debt, '
    'security vulnerabilities, and end-of-life systems in the current state.',
  )
  @ContentHelp(
    'Aggregate the technical pain points into category metrics: '
    'technical-debt estimate, security-vulnerability counts, systems at '
    'end of life, vendor lock-in risk, and integration complexity.',
  )
  @Form([
    Field(
      'technicalDebtEstimate',
      String,
      'Technical Debt Estimate',
      hint: 'Estimated cost to address technical debt, e.g. €1.2M or 18 months',
    ),
    Field(
      'securityVulnerabilityCount',
      int,
      'Known Security Vulnerabilities',
      hint: 'Number of documented security vulnerabilities',
    ),
    Field(
      'criticalSecurityIssues',
      int,
      'Critical Security Issues',
      hint: 'Number of critical/high severity security vulnerabilities',
    ),
    Field(
      'systemsAtEndOfLife',
      int,
      'Systems at End of Life',
      hint: 'Number of systems using unsupported or EOL technology',
    ),
    Field(
      'undocumentedSystems',
      int,
      'Undocumented Systems',
      hint: 'Number of systems with inadequate documentation',
    ),
    Field(
      'vendorLockInRisk',
      String,
      'Vendor Lock-in Risk Level',
      hint: 'Low / Medium / High — based on proprietary dependencies',
    ),
    Field(
      'integrationComplexityScore',
      String,
      'Integration Complexity Score',
      hint:
          'Overall integration complexity, e.g. High (47 point-to-point integrations)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? categorySummary;

  /// Contains 0+× PainPoint.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (problem identification)',
  ], 'The list of individual technical pain points documented in detail.')
  @SectionId('PAPE-ITEM-LST')
  @SectionIdPattern('PAPE-ITEM-xxx')
  @ContentHelp(
    'Add one entry per distinct technical problem, each with its own '
    'root cause, impact, and resolution outlook. Scope entries to technology, '
    'architecture, security, and maintainability concerns.',
  )
  @SerializationOrder(2)
  List<PainPointEntry> items = [];
}

/// A pain point entry (form).
///
/// Documents a specific problem in the current state with comprehensive details:
/// root cause analysis, impact quantification, affected stakeholders,
/// current workarounds, and proposed resolution approach.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (single problem statement)'],
  'One fully documented pain point — its classification, root cause, impact, '
  'evidence, workaround, and proposed resolution.',
)
@SectionId('PAPE')
class PainPointEntry extends DocSpecsSection {
  @Form([
    Field(
      'painPointId',
      String,
      'Pain Point ID',
      hint: 'Unique identifier, e.g. PP-OPE-001',
      required: true,
    ),
    Field(
      'painPoint',
      String,
      'Pain Point Name',
      hint: 'Concise name for the pain point',
      required: true,
    ),
    Field(
      'severity',
      String,
      'Severity',
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Classification.
  @SectionId('PAPOCL')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (problem categorisation & prioritisation)',
    ],
    'How this pain point is categorised and prioritised — its description, '
    'category, urgency, and resolution priority.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed description of the problem',
    ),
    Field(
      'category',
      String,
      'Category',
      hint: 'Operational / Business / Technical',
    ),
    Field(
      'subCategory',
      String,
      'Sub-Category',
      hint: 'E.g. Performance / DataQuality / Usability',
    ),
    Field(
      'urgency',
      String,
      'Urgency',
      hint: 'Immediate / ShortTerm / MediumTerm / LongTerm',
    ),
    Field(
      'priority',
      String,
      'Resolution Priority',
      hint: 'P1-Critical / P2-High / P3-Medium / P4-Low',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Root cause analysis.
  @SectionId('PPRC')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (root cause analysis)'],
    'The underlying cause of this pain point and the factors that exacerbate it, '
    'distinguishing the true root cause from its symptoms.',
  )
  @Form([
    Field(
      'rootCause',
      String,
      'Root Cause',
      hint: 'Underlying cause of the pain point',
    ),
    Field(
      'rootCauseCategory',
      String,
      'Root Cause Category',
      hint: 'Process / Technology / People / Data / Integration / External',
    ),
    Field(
      'contributingFactors',
      String,
      'Contributing Factors',
      hint: 'Additional factors that exacerbate the problem',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? rootCause;

  /// Impact assessment.
  @SectionId('PAPOIM')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (impact assessment & quantification)',
    ],
    'The reach and cost of this pain point — affected processes, systems, '
    'stakeholders, frequency, and quantified business impact.',
  )
  @Form([
    Field(
      'affectedProcess',
      String,
      'Affected Process',
      hint: 'Primary business process impacted',
    ),
    Field(
      'affectedSystems',
      String,
      'Affected Systems',
      hint: 'Systems involved or causing the pain point',
    ),
    Field(
      'affectedStakeholders',
      String,
      'Affected Stakeholders',
      hint: 'User roles, departments, or external parties impacted',
    ),
    Field(
      'userCount',
      int,
      'Number of Users Affected',
      hint: 'Approximate count of users experiencing this issue',
    ),
    Field(
      'frequency',
      String,
      'Frequency of Occurrence',
      hint: 'Continuous / Daily / Weekly / Monthly / Sporadic',
    ),
    Field(
      'businessImpact',
      String,
      'Business Impact',
      hint: 'Description of impact on business outcomes',
    ),
    Field(
      'quantifiedCost',
      String,
      'Quantified Annual Cost',
      hint: 'Estimated annual cost, e.g. €75k/year',
    ),
    Field(
      'productivityLoss',
      String,
      'Productivity Loss',
      hint: 'Time lost per occurrence, e.g. 30 min/occurrence',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? impact;

  /// Evidence and validation.
  @SectionId('PAPOEV')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (evidence & validation of problems)',
    ],
    'How this pain point was discovered and validated — discovery method, '
    'validation status, and the data sources that substantiate it.',
  )
  @Form([
    Field(
      'discoveryMethod',
      String,
      'Discovery Method',
      hint: 'UserFeedback / Incident / Audit / ProcessReview',
    ),
    Field(
      'dateIdentified',
      String,
      'Date Identified',
      hint: 'When the pain point was first documented',
    ),
    Field(
      'validationStatus',
      String,
      'Validation Status',
      hint: 'Identified / Confirmed / Quantified / RootCauseAnalyzed',
    ),
    Field(
      'evidenceSources',
      String,
      'Evidence Sources',
      hint: 'Data sources supporting this pain point',
    ),
    Field(
      'incidentReferences',
      String,
      'Related Incidents',
      hint: 'References to specific incidents',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? evidence;

  /// Current state and workarounds.
  @SectionId('PAPOWO')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (current workarounds & coping mechanisms)',
    ],
    'How the organisation currently copes with this pain point — the interim '
    'workaround, its effectiveness and cost, and the risk if left unaddressed.',
  )
  @Form([
    Field(
      'currentWorkaround',
      String,
      'Current Workaround',
      hint: 'How users currently work around this issue',
    ),
    Field(
      'workaroundEffectiveness',
      String,
      'Workaround Effectiveness',
      hint: 'None / Poor / Partial / Adequate',
    ),
    Field(
      'workaroundCost',
      String,
      'Workaround Cost',
      hint: 'Cost of maintaining the workaround',
    ),
    Field(
      'riskIfNotAddressed',
      String,
      'Risk if Not Addressed',
      hint: 'Consequences of leaving the pain point unresolved',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? workaround;

  /// Resolution planning.
  @SectionId('PAPORE')
  @StandardReferences(
    ['BABOK v3 §6 — gap analysis (current vs. desired state)'],
    'The proposed path from this pain point to a resolved state — approach, '
    'complexity, effort, expected benefit, and success criteria.',
  )
  @Form([
    Field(
      'proposedResolution',
      String,
      'Proposed Resolution',
      hint: 'High-level approach to resolve the pain point',
    ),
    Field(
      'resolutionComplexity',
      String,
      'Resolution Complexity',
      hint: 'Low / Medium / High / VeryHigh',
    ),
    Field(
      'estimatedResolutionEffort',
      String,
      'Estimated Resolution Effort',
      hint: 'Time or cost to resolve',
    ),
    Field(
      'expectedBenefit',
      String,
      'Expected Benefit',
      hint: 'Quantified benefit after resolution',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'How to measure that the pain point is resolved',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? resolution;

  /// Relationships.
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (relationships among problems)'],
    'The set of links from this pain point to related pain points, gaps, and '
    'dependencies.',
  )
  @SectionId('PAPOR1-RELA-LST')
  @SectionIdPattern('PAPOR1-RELA-xxx')
  @ContentHelp(
    'Add one entry per relationship this pain point has — related '
    'pain points, originating gaps, or other pain points it depends on.',
  )
  @SerializationOrder(7)
  List<PainPointRelationships> relationships = [];
}

/// Relationships for pain point.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (relationships among problems)'],
  'A single link from this pain point to another pain point, a gap, or a '
  'dependency that must be resolved first.',
)
@SectionId('PAPOR1')
class PainPointRelationships extends DocSpecsSection {
  @Form([
    Field(
      'relatedPainPoints',
      String,
      'Related Pain Points',
      hint: 'IDs of related pain points',
      refersTo: ['PAPE.painPointId'],
    ),
    Field(
      'relatedGaps',
      String,
      'Related Gaps',
      hint: 'Gap entries that this pain point stems from',
    ),
    Field(
      'dependsOn',
      String,
      'Depends On',
      hint: 'Other pain points that must be resolved first',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Cross-reference analysis between pain points and gaps.
@StandardReferences(
  ['BABOK v3 §6 — gap analysis (linking problems to capability gaps)'],
  'The mapping that ties documented pain points to capability gaps — showing '
  'which gaps cause which pains and where unstated gaps may lurk.',
)
@SectionId('PPGC')
class PainPointGapCorrelation extends DocSpecsSection {
  @ContentHelp('''
Analysis of relationships between documented pain points and capability gaps.
Shows which gaps cause which pain points, and which pain points indicate
underlying gaps that may not be explicitly documented.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual correlation between pain points and gaps.
  @SectionId('PPGC-CORR')
  @ContentType(
    'mermaid',
    'Diagram showing cause-effect relationships '
        'between capability gaps and resulting pain points',
  )
  @SerializationOrder(1)
  DocSpecsSection? correlationDiagram;

  /// Tabular correlation data.
  @StandardReferences([
    'BABOK v3 §6 — gap analysis (pain-point to gap traceability)',
  ], 'The list of individual pain-point-to-gap correlation entries.')
  @Min(1)
  @SectionId('PPGCE-CORR-LST')
  @SectionIdPattern('PPGCE-CORR-xxx')
  @ContentHelp(
    'Add one entry per pain-point-to-gap relationship, naming both '
    'IDs and describing how they are linked (cause, contribution, or '
    'indication) and how strong the link is.',
  )
  @SerializationOrder(2)
  List<PainPointGapCorrelationEntry> correlationEntries = [];
}

/// Individual pain point to gap correlation entry.
@StandardReferences(
  ['BABOK v3 §6 — gap analysis (single pain-point/gap correlation)'],
  'One link between a specific pain point and a specific gap, with its '
  'correlation type and strength.',
)
@SectionId('PPGCE')
class PainPointGapCorrelationEntry extends DocSpecsSection {
  @Form([
    Field(
      'painPointId',
      String,
      'Pain Point ID',
      hint: 'Reference to pain point, e.g. PP-OPE-001',
      required: true,
      refersTo: ['PAPE.painPointId'],
    ),
    Field(
      'gapId',
      String,
      'Gap ID',
      hint: 'Reference to gap entry, e.g. GAP-001',
      required: true,
    ),
    Field(
      'correlationType',
      String,
      'Correlation Type',
      hint: 'CausedBy / ContributesTo / IndicatesGap / Exacerbates',
    ),
    Field(
      'correlationStrength',
      String,
      'Correlation Strength',
      hint: 'Direct / Strong / Moderate / Weak',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional context on the relationship',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A gap entry (form) — a missing capability or feature.
///
/// Documents a specific gap between current capabilities and business needs:
/// category, severity, quantified cost, stakeholders, compliance drivers,
/// workarounds, resolution approach, and success criteria.
@StandardReferences(
  ['BABOK v3 §6 — gap analysis (single capability gap)'],
  'One fully documented capability gap — its category, severity, impact, '
  'discovery, workaround, and proposed resolution.',
)
@SectionId('GAPE')
class GapEntry extends DocSpecsSection {
  @Form([
    Field(
      'gapName',
      String,
      'Gap Name',
      hint: 'Concise name for the identified gap',
      required: true,
    ),
    Field(
      'gapCategory',
      String,
      'Gap Category',
      hint:
          'Functional / Process / Data / Integration / Compliance / Security / Performance / Usability',
    ),
    Field(
      'severity',
      String,
      'Severity',
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Gap description and business impact.
  @SectionId('GAENDE')
  @StandardReferences(
    ['BABOK v3 §6 — gap analysis (gap definition & business impact)'],
    'What is missing or inadequate and why it matters — the gap description, '
    'priority, quantified cost, and affected processes and stakeholders.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed description of what is missing or inadequate',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'MustAddress / ShouldAddress / NiceToHave',
    ),
    Field(
      'businessImpact',
      String,
      'Business Impact',
      hint: 'How this gap affects business outcomes, revenue, or operations',
    ),
    Field(
      'quantifiedCost',
      String,
      'Quantified Cost of Gap',
      hint:
          'Estimated annual cost or productivity loss, e.g. ~€120k/year in manual processing',
    ),
    Field(
      'affectedProcess',
      String,
      'Affected Process',
      hint: 'Primary business process impacted by this gap',
    ),
    Field(
      'affectedStakeholders',
      String,
      'Affected Stakeholders',
      hint: 'Roles, departments, or external parties impacted',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// Discovery and validation.
  @SectionId('GAENDI')
  @StandardReferences(
    ['BABOK v3 §6 — gap analysis (gap discovery, drivers & validation)'],
    'How this gap was found and confirmed — its compliance driver, discovery '
    'method, age, validation status, and links to related pain points.',
  )
  @Form([
    Field(
      'complianceDriver',
      String,
      'Regulatory/Compliance Driver',
      hint:
          'Regulation or standard making this gap critical, e.g. GDPR Art. 17, SOX Section 404',
    ),
    Field(
      'discoveryMethod',
      String,
      'Discovery Method',
      hint:
          'Audit / UserFeedback / Incident / ProcessReview / Benchmarking / RegulatoryChange',
    ),
    Field(
      'gapAge',
      String,
      'Gap Age',
      hint: 'How long this gap has been known, e.g. Since 2023-Q2, 18 months',
    ),
    Field(
      'validationStatus',
      String,
      'Validation Status',
      hint: 'Identified / Confirmed / Quantified / Accepted',
    ),
    Field(
      'relatedPainPoints',
      String,
      'Related Pain Points',
      hint: 'References to pain point entries that stem from this gap',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? discovery;

  /// Current workarounds.
  @SectionId('GAENWO')
  @StandardReferences(
    ['BABOK v3 §6 — gap analysis (current coping with the gap)'],
    'How the organisation copes with this gap today — the interim workaround, '
    'its cost, and the risk if the gap remains unclosed.',
  )
  @Form([
    Field(
      'interimWorkaround',
      String,
      'Interim Workaround',
      hint: 'Current workaround in place and its limitations',
    ),
    Field(
      'workaroundCost',
      String,
      'Workaround Cost',
      hint:
          'Cost or effort of maintaining the workaround, e.g. 2 FTE hours/week',
    ),
    Field(
      'riskIfNotAddressed',
      String,
      'Risk if Not Addressed',
      hint: 'Consequences and risk level if gap remains unresolved',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? workaround;

  /// Resolution planning.
  @SectionId('GAENRE')
  @StandardReferences(
    ['BABOK v3 §6 — gap analysis (closing the gap toward the desired state)'],
    'The proposed path from this gap to the desired state — approach, timeline, '
    'success criteria, and dependencies on other gaps.',
  )
  @Form([
    Field(
      'proposedResolution',
      String,
      'Proposed Resolution',
      hint: 'High-level approach to closing the gap',
    ),
    Field(
      'expectedTimeline',
      String,
      'Expected Resolution Timeline',
      hint: 'Target timeframe, e.g. Phase 1 — Q3 2026, 6-9 months',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'Measurable criteria that confirm the gap is closed',
    ),
    Field(
      'dependsOnGaps',
      String,
      'Depends on Other Gaps',
      hint: 'Other gaps that must be resolved first, by name or ID',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? resolution;
}

// ---------------------------------------------------------------------------
// 1.4 Current Data Landscape
// ---------------------------------------------------------------------------

/// 1.4. Current Data Landscape.
///
/// Comprehensive documentation of the current data situation including where
/// data lives, data quality issues, duplication, ownership, volumes, growth
/// trends, retention policies, and governance structures.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data architecture)',
    'DAMA-DMBOK2 — data management body of knowledge',
  ],
  'The AS-IS picture of the organization\'s data — where it lives, its quality '
  'and duplication, ownership, volumes and growth, retention, governance, '
  'classification, integration, and master data.',
)
@SectionId('CUDALA')
@DetailedIn(D01CurrentLandscapeAssessment)
class CurrentDataLandscape extends DocSpecsSection {
  @ContentHelp('''
Executive overview of the current data landscape. Summarize the overall data
situation, key data assets, major challenges, and strategic importance of data
to the organization. Highlight critical data dependencies and risks.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual representation of the data landscape.
  @SectionId('CUDALA-DATAL')
  @ContentType(
    'mermaid-flowchart',
    'High-level diagram showing data domains, '
        'major data stores, data flows, and integration points',
  )
  @SerializationOrder(1)
  DocSpecsSection? dataLandscapeOverviewDiagram;

  /// Data architecture summary diagram.
  @SectionId('CUDALA-DATA')
  @ContentType(
    'mermaid',
    'ER-style or architectural diagram showing '
        'relationships between major data entities and systems',
  )
  @SerializationOrder(2)
  DocSpecsSection? dataArchitectureDiagram;

  /// Summary statistics and health indicators.
  @SectionId('DALASU')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data landscape baseline)'],
    'Top-level baseline indicators of the data landscape: source counts, volume, '
    'quality, governance maturity, duplication, compliance, and security risk.',
  )
  @Form([
    Field(
      'totalDataSources',
      int,
      'Total Data Sources',
      hint: 'Number of distinct data sources/stores',
    ),
    Field(
      'totalDataVolume',
      String,
      'Total Data Volume',
      hint: 'Aggregate data volume across all sources, e.g. 15 TB',
    ),
    Field(
      'overallDataQualityScore',
      String,
      'Overall Data Quality Score',
      hint: 'Aggregate quality score, e.g. 72% or B+',
    ),
    Field(
      'criticalDataAssets',
      int,
      'Critical Data Assets',
      hint: 'Number of data assets classified as business-critical',
    ),
    Field(
      'dataGovernanceMaturity',
      String,
      'Data Governance Maturity Level',
      hint: 'Level 1-5 or Initial/Managed/Defined/Measured/Optimized',
    ),
    Field(
      'knownDuplicationRate',
      String,
      'Known Duplication Rate',
      hint: 'Estimated percentage of duplicated data, e.g. 15%',
    ),
    Field(
      'complianceStatus',
      String,
      'Regulatory Compliance Status',
      hint: 'Compliant / PartiallyCompliant / NonCompliant / Unknown',
    ),
    Field(
      'dataSecurityRiskLevel',
      String,
      'Data Security Risk Level',
      hint: 'Low / Medium / High / Critical',
    ),
    Field(
      'averageDataAge',
      String,
      'Average Data Age',
      hint: 'Average age of data across sources, e.g. 18 months',
    ),
    Field(
      'dataDocumentationCoverage',
      String,
      'Documentation Coverage',
      hint: 'Percentage of data assets with adequate documentation',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dataLandscapeSummary;

  /// 1.4.1. Data Source Inventory.
  @SerializationOrder(4)
  DataSourceInventory dataSourceInventory = DataSourceInventory();

  /// 1.4.2. Data Quality Assessment.
  @SerializationOrder(5)
  DataQualityAssessment dataQualityAssessment = DataQualityAssessment();

  /// 1.4.3. Data Duplication Analysis.
  @SerializationOrder(6)
  DataDuplicationAnalysis dataDuplicationAnalysis = DataDuplicationAnalysis();

  /// 1.4.4. Data Ownership and Stewardship.
  @SerializationOrder(7)
  DataOwnership dataOwnership = DataOwnership();

  /// 1.4.5. Data Volumes and Growth.
  @SerializationOrder(8)
  DataVolumesAndGrowth dataVolumesAndGrowth = DataVolumesAndGrowth();

  /// 1.4.6. Retention Policies.
  @SerializationOrder(9)
  DataRetentionPolicies retentionPolicies = DataRetentionPolicies();

  /// 1.4.7. Data Governance.
  @SerializationOrder(10)
  DataGovernance dataGovernance = DataGovernance();

  /// 1.4.8. Data Classification.
  @SerializationOrder(11)
  CurrentDataClassification dataClassification = CurrentDataClassification();

  /// 1.4.9. Data Integration Points.
  @SerializationOrder(12)
  DataIntegrationPoints dataIntegrationPoints = DataIntegrationPoints();

  /// 1.4.10. Master Data Management.
  @SerializationOrder(13)
  MasterDataManagement masterDataManagement = MasterDataManagement();
}

/// 1.4.1. Data Source Inventory.
///
/// Comprehensive inventory of all data sources, stores, and repositories
/// in the current environment.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data source inventory)',
    'DAMA-DMBOK2 — data storage and operations',
  ],
  'The catalogue of every data source, store, and repository in the current '
  'environment, with its technology, volume, quality, ownership, and access.',
)
@SectionId('DASOIN')
class DataSourceInventory extends DocSpecsSection {
  @ContentHelp('''
Overview of the data source inventory. Describe the methodology used to
catalog data sources, coverage of the inventory, and any known gaps.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual map of data sources by domain/category.
  @SectionId('DASOIN-DATA')
  @ContentType(
    'mermaid',
    'Diagram showing data sources grouped by '
        'business domain or technical category',
  )
  @SerializationOrder(1)
  DocSpecsSection? dataSourceMapDiagram;

  /// Contains 0+× DataSource.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data source inventory)',
  ], 'The list of catalogued data sources, one entry per store or repository.')
  @SectionId('DASR-DATA-LST')
  @SectionIdPattern('DASR-DATA-xxx')
  @ContentHelp(
    'Add one entry per data source/store in the environment '
    '(databases, warehouses, lakes, file systems, SaaS, APIs). Capture each '
    'source\'s technology, volume, quality, ownership, and key entities.',
  )
  @SerializationOrder(2)
  List<DataSourceEntry> dataSources = [];
}

/// A data source entry (form).
///
/// Documents a specific data source/store with comprehensive details about
/// technology, format, volume, quality, ownership, and access patterns.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data source inventory)'],
  'A single catalogued data source: its identity, classification, technology, '
  'volume, quality, ownership, integration, lifecycle, and key entities.',
)
@SectionId('DASR')
class DataSourceEntry extends DocSpecsSection {
  @Form([
    Field(
      'dataSourceId',
      String,
      'Data Source ID',
      hint: 'Unique identifier, e.g. DS-001',
      required: true,
    ),
    Field(
      'dataStoreName',
      String,
      'Data Store Name',
      hint: 'Name of the data store or source',
      required: true,
    ),
    Field(
      'criticality',
      String,
      'Business Criticality',
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Classification.
  @SectionId('DASOCL')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data source classification)'],
    'How this source is categorized: what it contains, its source category, and '
    'the business domain it serves.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Brief description of what data this source contains',
    ),
    Field(
      'sourceCategory',
      String,
      'Source Category',
      hint: 'Transactional / Analytical / Master / Reference / Archive',
    ),
    Field(
      'businessDomain',
      String,
      'Business Domain',
      hint: 'E.g. Sales, Finance, HR, Operations, Customer',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Technical details.
  @SectionId('DASOTE')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data architecture)'],
    'The technical realization of this source: store type, technology, version, '
    'hosting location, and data format.',
  )
  @Form([
    Field(
      'storeType',
      String,
      'Store Type',
      hint: 'Database / DataWarehouse / DataLake / FileSystem / API',
    ),
    Field(
      'technology',
      String,
      'Technology/Platform',
      hint: 'E.g. PostgreSQL, Oracle, MongoDB, S3, Salesforce',
    ),
    Field('version', String, 'Version', hint: 'Software/platform version'),
    Field(
      'hostingLocation',
      String,
      'Hosting Location',
      hint: 'OnPremise / CloudAWS / CloudAzure / CloudGCP / SaaS',
    ),
    Field(
      'dataFormat',
      String,
      'Data Format',
      hint: 'Relational / Document / Key-Value / CSV / JSON / XML',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? technical;

  /// Volume and performance.
  @SectionId('DASOVO')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data volume baseline)'],
    'The size and access profile of this source: estimated volume, record count, '
    'growth rate, access frequency, and peak load periods.',
  )
  @Form([
    Field(
      'estimatedVolume',
      String,
      'Estimated Volume',
      hint: 'E.g. 500 GB, 2 TB, 50 million records',
    ),
    Field(
      'estimatedRecordCount',
      String,
      'Estimated Record Count',
      hint: 'Number of records/rows/documents',
    ),
    Field(
      'growthRate',
      String,
      'Growth Rate',
      hint: 'E.g. 5% per month, 100 GB per quarter',
    ),
    Field(
      'accessFrequency',
      String,
      'Access Frequency',
      hint: 'Realtime / Hourly / Daily / Weekly / Monthly',
    ),
    Field(
      'peakLoadPeriods',
      String,
      'Peak Load Periods',
      hint: 'When the source experiences highest load',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? volume;

  /// Quality and reliability.
  @SectionId('DASOQU')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data quality assessment)',
      'ISO/IEC 25012 — data quality model',
    ],
    'The quality and reliability profile of this source: its quality score, '
    'known issues, freshness, and reliability.',
  )
  @Form([
    Field(
      'dataQualityScore',
      String,
      'Data Quality Score',
      hint: 'Quality rating, e.g. 85%, A, High',
    ),
    Field(
      'knownQualityIssues',
      String,
      'Known Quality Issues',
      hint: 'Summary of quality problems',
    ),
    Field(
      'dataFreshness',
      String,
      'Data Freshness',
      hint: 'How current the data is, e.g. RealTime / Daily',
    ),
    Field(
      'reliabilityScore',
      String,
      'Reliability Score',
      hint: 'Uptime/reliability, e.g. 99.5%',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? quality;

  /// Ownership and governance.
  @SectionId('DASOOW')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data ownership & governance)',
      'DAMA-DMBOK2 — data governance',
    ],
    'Who owns and governs this source: business and technical owners, steward, '
    'access-control model, and sensitivity level.',
  )
  @Form([
    Field(
      'businessOwner',
      String,
      'Business Owner',
      hint: 'Department or role responsible for data',
    ),
    Field(
      'technicalOwner',
      String,
      'Technical Owner',
      hint: 'Team or role responsible for technical management',
    ),
    Field(
      'dataSteward',
      String,
      'Data Steward',
      hint: 'Person responsible for data quality',
    ),
    Field(
      'accessControlModel',
      String,
      'Access Control Model',
      hint: 'RBAC / ABAC / ACL / Open',
    ),
    Field(
      'sensitivityLevel',
      String,
      'Data Sensitivity Level',
      hint: 'Public / Internal / Confidential / Restricted',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? ownership;

  /// Integration.
  @SectionId('DASOI1')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data flows & integration)'],
    'How this source connects to the rest of the landscape: integrated systems, '
    'upstream feeds, and downstream consumers.',
  )
  @Form([
    Field(
      'integratedSystems',
      String,
      'Integrated Systems',
      hint: 'Systems that read from or write to this source',
    ),
    Field(
      'upstreamSources',
      String,
      'Upstream Sources',
      hint: 'Data sources that feed into this one',
    ),
    Field(
      'downstreamConsumers',
      String,
      'Downstream Consumers',
      hint: 'Systems that consume data from this source',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? integration;

  /// Lifecycle.
  @SectionId('DASOLI')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data lifecycle)'],
    'The lifecycle state of this source: creation, last major update, planned '
    'decommission, and documentation status.',
  )
  @Form([
    Field(
      'creationDate',
      String,
      'Creation Date',
      hint: 'When the data source was established',
    ),
    Field(
      'lastMajorUpdate',
      String,
      'Last Major Update',
      hint: 'When the source was last significantly modified',
    ),
    Field(
      'plannedDecommission',
      String,
      'Planned Decommission',
      hint: 'If scheduled for retirement, target date',
    ),
    Field(
      'documentationStatus',
      String,
      'Documentation Status',
      hint: 'Complete / Partial / Minimal / None',
    ),
    Field(
      'schemaDocumentationLink',
      String,
      'Schema Documentation Link',
      hint: 'Link to detailed schema documentation',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? lifecycle;

  /// Retention Policy for this data source.
  @SectionId('DSRP')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data retention & lifecycle)',
      'DAMA-DMBOK2 — data management body of knowledge',
    ],
    'The retention rules governing this source: retention period, archival and '
    'deletion policy, legal basis, and compliance notes.',
  )
  @Form([
    Field(
      'retentionPeriod',
      String,
      'Retention Period',
      hint: 'How long data is kept, e.g. 7 years, indefinite',
    ),
    Field(
      'archivalPolicy',
      String,
      'Archival Policy',
      hint: 'How data is archived after active use',
    ),
    Field(
      'deletionPolicy',
      String,
      'Deletion Policy',
      hint: 'How data is deleted/purged',
    ),
    Field(
      'legalBasis',
      String,
      'Legal Basis',
      hint: 'Regulatory or legal requirement driving retention',
    ),
    Field(
      'complianceNotes',
      String,
      'Compliance Notes',
      hint: 'Additional compliance considerations',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? retentionPolicy;

  /// Key data entities in this source.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data entity inventory)',
  ], 'The principal data entities (tables/collections) held in this source.')
  @Min(1)
  @SectionId('DSEE-KEYE-LST')
  @SectionIdPattern('DSEE-KEYE-xxx')
  @ContentHelp(
    'Add one entry per key entity in this source. Capture its name, '
    'what it represents, record count, primary key, relationships, and any '
    'sensitive fields.',
  )
  @SerializationOrder(9)
  List<DataSourceEntityEntry> keyEntities = [];
}

/// Key data entity within a data source.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data entity inventory)'],
  'A single key entity in a source: its name, meaning, record count, primary '
  'key, relationships, and sensitive fields.',
)
@SectionId('DSEE')
class DataSourceEntityEntry extends DocSpecsSection {
  @Form([
    Field(
      'entityName',
      String,
      'Entity Name',
      hint: 'Name of the entity/table/collection',
      required: true,
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this entity represents',
    ),
    Field(
      'recordCount',
      String,
      'Record Count',
      hint: 'Approximate number of records',
    ),
    Field(
      'primaryKey',
      String,
      'Primary Key',
      hint: 'Key field(s) identifying unique records',
    ),
    Field(
      'relationships',
      String,
      'Key Relationships',
      hint: 'Important relationships to other entities',
    ),
    Field(
      'sensitiveFields',
      String,
      'Sensitive Fields',
      hint: 'Fields containing sensitive data',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 1.4.2. Data Quality Assessment.
///
/// Comprehensive assessment of data quality across the organization,
/// covering accuracy, completeness, consistency, timeliness, and validity.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data quality assessment)',
    'ISO/IEC 25012 — data quality model',
  ],
  'The organization-wide assessment of data quality across standard dimensions, '
  'the inventory of quality issues, and improvement initiatives under way.',
)
@SectionId('DAQUAS')
class DataQualityAssessment extends DocSpecsSection {
  @ContentHelp('''
Overview of data quality across the organization. Describe the assessment
methodology, scope, key findings, and overall data quality posture.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Data quality dimensions summary.
  @SectionId('DQDS')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data quality assessment)',
      'ISO/IEC 25012 — data quality model',
    ],
    'The quality scorecard across standard dimensions — accuracy, completeness, '
    'consistency, timeliness, validity, uniqueness, and integrity — with the '
    'assessment\'s date, scope, and methodology.',
  )
  @Form([
    Field(
      'accuracyScore',
      String,
      'Accuracy Score',
      hint: 'Overall accuracy of data, e.g. 92%',
    ),
    Field(
      'completenessScore',
      String,
      'Completeness Score',
      hint: 'Percentage of required data present, e.g. 88%',
    ),
    Field(
      'consistencyScore',
      String,
      'Consistency Score',
      hint: 'Data consistency across sources, e.g. 79%',
    ),
    Field(
      'timelinessScore',
      String,
      'Timeliness Score',
      hint: 'How current data is, e.g. 95%',
    ),
    Field(
      'validityScore',
      String,
      'Validity Score',
      hint: 'Conformance to business rules, e.g. 85%',
    ),
    Field(
      'uniquenessScore',
      String,
      'Uniqueness Score',
      hint: 'Absence of duplicate records, e.g. 91%',
    ),
    Field(
      'integrityScore',
      String,
      'Referential Integrity Score',
      hint: 'Integrity of relationships, e.g. 88%',
    ),
    Field(
      'assessmentDate',
      String,
      'Assessment Date',
      hint: 'When this assessment was performed',
    ),
    Field(
      'assessmentScope',
      String,
      'Assessment Scope',
      hint: 'What was included in the assessment',
    ),
    Field(
      'assessmentMethodology',
      String,
      'Assessment Methodology',
      hint: 'How the assessment was conducted',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dimensionsSummary;

  /// Quality issues by severity.
  @SectionId('DAQUAS-QUAL')
  @ContentType(
    'mermaid',
    'Chart showing distribution of quality issues '
        'by severity level',
  )
  @SerializationOrder(2)
  DocSpecsSection? qualityIssuesSeverityChart;

  /// Data quality issues inventory.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data quality assessment)',
    'ISO/IEC 25012 — data quality model',
  ], 'The inventory of identified data quality issues, one entry per issue.')
  @SectionId('DAQLIS-QUAL-LST')
  @SectionIdPattern('DAQLIS-QUAL-xxx')
  @ContentHelp(
    'Add one entry per known data quality issue. Capture its '
    'severity, affected sources/entities, business impact, root cause, and '
    'proposed resolution.',
  )
  @Min(1)
  @SerializationOrder(3)
  List<DataQualityIssueEntry> qualityIssues = [];

  /// Quality improvement initiatives in progress.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data quality improvement)',
    'DAMA-DMBOK2 — data quality management',
  ], 'The set of in-progress initiatives aimed at improving data quality.')
  @SectionId('DQIE-IMPR-LST')
  @SectionIdPattern('DQIE-IMPR-xxx')
  @ContentHelp(
    'Add one entry per active or planned data-quality improvement '
    'initiative. Capture the issues it targets, its status, expected '
    'completion, and the improvement it should deliver.',
  )
  @SerializationOrder(4)
  List<DataQualityInitiativeEntry> improvementInitiatives = [];
}

/// A data quality issue entry (form).
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data quality assessment)',
    'ISO/IEC 25012 — data quality model',
  ],
  'A single identified data quality issue: its identity, affected source, '
  'classification and severity, business impact, and resolution plan.',
)
@SectionId('DAQLIS')
class DataQualityIssueEntry extends DocSpecsSection {
  @Form([
    Field(
      'issueId',
      String,
      'Issue ID',
      hint: 'Unique identifier, e.g. DQ-001',
      required: true,
    ),
    Field(
      'issueTitle',
      String,
      'Issue Title',
      hint: 'Brief description of the quality issue',
      required: true,
    ),
    Field(
      'description',
      String,
      'Detailed Description',
      hint: 'Full description of the issue and its manifestation',
    ),
    Field(
      'affectedDataSource',
      String,
      'Affected Data Source',
      hint: 'Which data source(s) are impacted',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Classification and severity.
  @SectionId('DQIEC')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data quality assessment)',
      'ISO/IEC 25012 — data quality model',
    ],
    'How this quality issue is categorized: affected entities, the quality '
    'dimension it violates, and its severity.',
  )
  @Form([
    Field(
      'affectedEntities',
      String,
      'Affected Entities',
      hint: 'Which data entities/tables are impacted',
    ),
    Field(
      'qualityDimension',
      String,
      'Quality Dimension',
      hint: 'Accuracy / Completeness / Consistency / Timeliness / Validity',
    ),
    Field(
      'severity',
      String,
      'Severity',
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Business impact and diagnostics.
  @SectionId('DQIEI')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data quality impact)'],
    'The business consequence and diagnostics of this quality issue: its impact, '
    'quantified cost, root cause, affected record count, and discovery date.',
  )
  @Form([
    Field(
      'impactDescription',
      String,
      'Business Impact',
      hint: 'How this quality issue affects business operations',
    ),
    Field(
      'quantifiedImpact',
      String,
      'Quantified Impact',
      hint: 'Measurable impact, e.g. EUR50k/year, 10% error rate',
    ),
    Field(
      'rootCause',
      String,
      'Root Cause',
      hint: 'Underlying cause of the quality issue',
    ),
    Field(
      'affectedRecordCount',
      String,
      'Affected Record Count',
      hint: 'Number or percentage of records affected',
    ),
    Field(
      'dateIdentified',
      String,
      'Date Identified',
      hint: 'When the issue was discovered',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? impact;

  /// Resolution planning.
  @SectionId('DQIER')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data quality remediation)'],
    'How this quality issue is being handled: the current workaround, the '
    'proposed resolution, and its priority.',
  )
  @Form([
    Field(
      'currentWorkaround',
      String,
      'Current Workaround',
      hint: 'How users currently cope with this issue',
    ),
    Field(
      'proposedResolution',
      String,
      'Proposed Resolution',
      hint: 'Recommended approach to fix the issue',
    ),
    Field(
      'resolutionPriority',
      String,
      'Resolution Priority',
      hint: 'P1 / P2 / P3 / P4',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? resolution;
}

/// Data quality improvement initiative entry.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data quality improvement)',
    'DAMA-DMBOK2 — data quality management',
  ],
  'A single initiative to improve data quality: what it targets, its status, '
  'expected completion, and the improvement it aims to deliver.',
)
@SectionId('DQIE')
class DataQualityInitiativeEntry extends DocSpecsSection {
  @Form([
    Field('initiativeId', String, 'Initiative ID', hint: 'Unique identifier'),
    Field(
      'initiativeName',
      String,
      'Initiative Name',
      hint: 'Name of the improvement initiative',
      required: true,
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What the initiative aims to achieve',
    ),
    Field(
      'targetIssues',
      String,
      'Target Issues',
      hint: 'Quality issues this initiative addresses',
    ),
    Field(
      'status',
      String,
      'Status',
      hint: 'Planned / InProgress / Completed / OnHold',
    ),
    Field(
      'expectedCompletion',
      String,
      'Expected Completion',
      hint: 'Target completion date',
    ),
    Field(
      'expectedImprovement',
      String,
      'Expected Improvement',
      hint: 'Quantified improvement target',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 1.4.3. Data Duplication Analysis.
///
/// Analysis of data duplication across systems, including redundant data
/// stores, duplicated records, and synchronization challenges.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data redundancy)',
    'DAMA-DMBOK2 — data management body of knowledge',
  ],
  'The analysis of redundant data across systems — the overall duplication '
  'picture and each individual duplication instance with its sync challenges.',
)
@SectionId('DADUAN')
class DataDuplicationAnalysis extends DocSpecsSection {
  @ContentHelp('''
Overview of data duplication across the organization. Describe the extent
of duplication, its causes, impacts, and any ongoing deduplication efforts.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Duplication analysis summary.
  @SectionId('DADUSU')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data redundancy)'],
    'The aggregate duplication picture: overall rate, duplicate volume, instance '
    'count, storage waste, sync challenges, and consolidation opportunities.',
  )
  @Form([
    Field(
      'overallDuplicationRate',
      String,
      'Overall Duplication Rate',
      hint: 'Estimated percentage of duplicated data, e.g. 23%',
    ),
    Field(
      'duplicateDataVolume',
      String,
      'Duplicate Data Volume',
      hint: 'Volume of duplicated data, e.g. 2.3 TB',
    ),
    Field(
      'numberOfDuplicationInstances',
      int,
      'Number of Known Duplications',
      hint: 'Count of documented duplication cases',
    ),
    Field(
      'storageWasteEstimate',
      String,
      'Storage Waste Estimate',
      hint: 'Cost of storing duplicate data, e.g. €15k/year',
    ),
    Field(
      'synchronizationChallenges',
      int,
      'Synchronization Challenges',
      hint: 'Number of sync issues caused by duplication',
    ),
    Field(
      'dataInconsistencyRisk',
      String,
      'Data Inconsistency Risk',
      hint: 'Low / Medium / High / Critical',
    ),
    Field(
      'consolidationOpportunities',
      int,
      'Consolidation Opportunities',
      hint: 'Number of identified consolidation opportunities',
    ),
    Field(
      'deduplicationPriority',
      String,
      'Deduplication Priority',
      hint: 'Organizational priority for deduplication efforts',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? duplicationSummary;

  /// Visual representation of data redundancy.
  @SectionId('DADUAN-DUPL')
  @ContentType(
    'mermaid',
    'Diagram showing overlapping data stores and '
        'duplicate data flows',
  )
  @SerializationOrder(2)
  DocSpecsSection? duplicationDiagram;

  /// Individual duplication instances.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data redundancy)',
  ], 'The list of documented duplication cases, one entry per instance.')
  @SectionId('DADU-DUPL-LST')
  @SectionIdPattern('DADU-DUPL-xxx')
  @ContentHelp(
    'Add one entry per documented duplication case. Capture the data '
    'element, its primary and duplicate sources, how copies are synchronized, '
    'the business reason, and the recommended action.',
  )
  @SerializationOrder(3)
  List<DataDuplicationEntry> duplicationInstances = [];
}

/// A data duplication instance entry.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data redundancy)'],
  'A single duplication case: the data element duplicated, its sources, the '
  'synchronization arrangement, and its business impact and resolution.',
)
@SectionId('DADU')
class DataDuplicationEntry extends DocSpecsSection {
  @Form([
    Field(
      'duplicationId',
      String,
      'Duplication ID',
      hint: 'Unique identifier',
      required: true,
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Description of the duplication scenario',
    ),
    Field(
      'dataElement',
      String,
      'Data Element',
      hint: 'What data is duplicated',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Sources and duplication shape.
  @SectionId('DDES')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data redundancy)'],
    'Where this duplicated data lives: its authoritative primary source, the '
    'duplicate locations, and the kind of duplication.',
  )
  @Form([
    Field(
      'primarySource',
      String,
      'Primary Source',
      hint: 'Authoritative source for this data',
    ),
    Field(
      'duplicateSources',
      String,
      'Duplicate Sources',
      hint: 'Other locations where this data exists',
    ),
    Field(
      'duplicationType',
      String,
      'Duplication Type',
      hint: 'FullCopy / PartialCopy / Denormalized / CachedCopy',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? sources;

  /// Synchronization and consistency details.
  @SectionId('DADUENSY')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data consistency)'],
    'How the duplicate copies are kept aligned: synchronization method and '
    'frequency, and any known inconsistencies between copies.',
  )
  @Form([
    Field(
      'synchronizationMethod',
      String,
      'Synchronization Method',
      hint: 'How duplicates are kept in sync, if at all',
    ),
    Field(
      'syncFrequency',
      String,
      'Sync Frequency',
      hint: 'RealTime / Hourly / Daily / Manual / None',
    ),
    Field(
      'knownInconsistencies',
      String,
      'Known Inconsistencies',
      hint: 'Documented cases of data drift between copies',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? synchronization;

  /// Business impact and resolution guidance.
  @SectionId('DDEG')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data redundancy)'],
    'Why this duplication exists and what to do about it: business reason, '
    'consolidation feasibility, impact, and recommended action.',
  )
  @Form([
    Field(
      'businessReason',
      String,
      'Business Reason',
      hint: 'Why this duplication exists',
    ),
    Field(
      'consolidationFeasibility',
      String,
      'Consolidation Feasibility',
      hint: 'Easy / Moderate / Difficult / NotFeasible',
    ),
    Field(
      'impactOfDuplication',
      String,
      'Impact of Duplication',
      hint: 'Negative effects of this duplication',
    ),
    Field(
      'recommendedAction',
      String,
      'Recommended Action',
      hint: 'Proposed resolution',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

/// 1.4.4. Data Ownership and Stewardship.
///
/// Documentation of data ownership structures, stewardship roles,
/// and accountability for data assets.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data ownership & stewardship)',
    'DAMA-DMBOK2 — data governance',
  ],
  'The AS-IS ownership and stewardship model for data assets — the ownership '
  'approach, accountable roles per domain, and gaps in accountability.',
)
@SectionId('DAOW')
class DataOwnership extends DocSpecsSection {
  @ContentHelp('''
Overview of data ownership and stewardship across the organization. Describe
the ownership model, roles and responsibilities, and any gaps in accountability.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Ownership model summary.
  @SectionId('DAOWSU')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data ownership & stewardship)',
      'DAMA-DMBOK2 — data governance',
    ],
    'The aggregate ownership posture: ownership model, domain count, assigned '
    'ownership rate, active stewards, gaps, and stewardship maturity.',
  )
  @Form([
    Field(
      'ownershipModel',
      String,
      'Ownership Model',
      hint: 'Centralized / Federated / Hybrid',
    ),
    Field(
      'totalDataDomains',
      int,
      'Total Data Domains',
      hint: 'Number of defined data domains',
    ),
    Field(
      'assignedOwnershipPercentage',
      String,
      'Assigned Ownership',
      hint: 'Percentage of data with clear ownership, e.g. 78%',
    ),
    Field(
      'activeStewards',
      int,
      'Active Data Stewards',
      hint: 'Number of active data stewards',
    ),
    Field(
      'ownershipGaps',
      int,
      'Ownership Gaps',
      hint: 'Number of data assets without clear ownership',
    ),
    Field(
      'stewardshipMaturity',
      String,
      'Stewardship Maturity',
      hint: 'Initial / Developing / Established / Optimizing',
    ),
    Field(
      'governanceCouncilExists',
      String,
      'Governance Council',
      hint: 'Yes / No — whether a data governance council exists',
    ),
    Field(
      'escalationProcess',
      String,
      'Escalation Process',
      hint: 'Whether clear escalation paths exist',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? ownershipSummary;

  /// Data ownership matrix visualization.
  @SectionId('DAOW-OWNE')
  @ContentType(
    'mermaid',
    'Matrix or diagram showing data domains and '
        'their owners/stewards',
  )
  @SerializationOrder(2)
  DocSpecsSection? ownershipMatrixDiagram;

  /// Data ownership assignments by domain.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data ownership & stewardship)',
  ], 'The ownership assignments, one entry per data domain or asset.')
  @Min(1)
  @SectionId('DAOWEN-OWNE-LST')
  @SectionIdPattern('DAOWEN-OWNE-xxx')
  @ContentHelp(
    'Add one entry per data domain or asset. Capture its business '
    'owner, data steward and technical custodian, who approves access, and '
    'the current ownership coverage status.',
  )
  @SerializationOrder(3)
  List<DataOwnershipEntry> ownershipAssignments = [];
}

/// Data ownership assignment for a domain or asset.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data ownership & stewardship)'],
  'A single ownership assignment: the data domain and its assets, the business '
  'owner, and the stewardship and access-governance arrangements.',
)
@SectionId('DAOWEN')
class DataOwnershipEntry extends DocSpecsSection {
  @Form([
    Field(
      'dataDomain',
      String,
      'Data Domain',
      hint: 'Business area or data domain',
      required: true,
    ),
    Field(
      'dataAssets',
      String,
      'Data Assets',
      hint: 'Specific data assets in this domain',
    ),
    Field(
      'businessOwner',
      String,
      'Business Owner',
      hint: 'Executive accountable for the data',
    ),
    Field(
      'businessOwnerRole',
      String,
      'Owner Role',
      hint: 'Job title/role of the business owner',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Stewardship and custodianship assignments.
  @SectionId('DAOWENST')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data stewardship)',
      'DAMA-DMBOK2 — data governance',
    ],
    'Day-to-day responsibility for this data: the data steward, technical '
    'custodian, and who is accountable for quality.',
  )
  @Form([
    Field(
      'dataSteward',
      String,
      'Data Steward',
      hint: 'Person responsible for day-to-day data management',
    ),
    Field(
      'stewardRole',
      String,
      'Steward Role',
      hint: 'Job title/role of the data steward',
    ),
    Field(
      'technicalCustodian',
      String,
      'Technical Custodian',
      hint: 'IT person/team responsible for technical data management',
    ),
    Field(
      'qualityAccountable',
      String,
      'Quality Accountable',
      hint: 'Who is accountable for data quality',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? stewardship;

  /// Access and coverage governance.
  @SectionId('DOEG')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data access governance)',
      'DAMA-DMBOK2 — data governance',
    ],
    'Governance of access to this domain: who approves access, the ownership '
    'coverage status, and when ownership was last reviewed.',
  )
  @Form([
    Field(
      'accessApprover',
      String,
      'Access Approver',
      hint: 'Who approves access to this data',
    ),
    Field(
      'coverageStatus',
      String,
      'Coverage Status',
      hint: 'Full / Partial / Minimal ownership coverage',
    ),
    Field(
      'lastReviewDate',
      String,
      'Last Review Date',
      hint: 'When ownership was last reviewed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;
}

/// 1.4.5. Data Volumes and Growth.
///
/// Analysis of current data volumes, historical growth trends,
/// and projections for future capacity needs.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data volume & growth baseline)'],
  'The AS-IS sizing of data — current volumes, historical growth trends, and '
  'forward projections that drive future capacity planning.',
)
@SectionId('DVAG')
class DataVolumesAndGrowth extends DocSpecsSection {
  @ContentHelp('''
Overview of data volumes and growth patterns across the organization.
Describe current total volumes, growth trends, capacity constraints,
and forecasting methodology.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Volume and growth summary.
  @SerializationOrder(1)
  DataVolumeSummary volumeSummary = DataVolumeSummary();

  /// Growth trend visualization.
  @SectionId('DVAG-GROW')
  @ContentType(
    'mermaid',
    'Chart showing historical data growth and '
        'projected future volumes',
  )
  @SerializationOrder(2)
  DocSpecsSection? growthTrendChart;

  /// Volume details by data source.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data volume baseline)',
  ], 'Per-source volume figures, one entry per data source.')
  @Min(1)
  @SectionId('DAVOEN-VOLU-LST')
  @SectionIdPattern('DAVOEN-VOLU-xxx')
  @ContentHelp(
    'Add one entry per data source. Capture its current volume, '
    'record count, average record size, historical and projected growth, '
    'growth drivers, and archival/purge rates.',
  )
  @SerializationOrder(3)
  List<DataVolumeEntry> volumeBySource = [];
}

/// Summary of data volumes and growth trends.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data volume baseline)'],
  'The aggregate volume picture: total, structured and unstructured volumes, '
  'with growth, projection, and capacity sub-sections.',
)
@SectionId('DAVOSU')
class DataVolumeSummary extends DocSpecsSection {
  @Form([
    Field(
      'totalCurrentVolume',
      String,
      'Total Current Volume',
      hint: 'Total data volume, e.g. 45 TB',
    ),
    Field(
      'structuredDataVolume',
      String,
      'Structured Data Volume',
      hint: 'Volume of structured data',
    ),
    Field(
      'unstructuredDataVolume',
      String,
      'Unstructured Data Volume',
      hint: 'Volume of unstructured data',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Historical growth behavior.
  @SectionId('DVSG')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data growth baseline)'],
    'How data has grown historically: annual and monthly growth rates and the '
    'periods of peak growth.',
  )
  @Form([
    Field(
      'annualGrowthRate',
      String,
      'Annual Growth Rate',
      hint: 'Year-over-year growth percentage, e.g. 25%',
    ),
    Field(
      'monthlyGrowthRate',
      String,
      'Monthly Growth Rate',
      hint: 'Month-over-month growth, e.g. 2%',
    ),
    Field(
      'peakGrowthPeriods',
      String,
      'Peak Growth Periods',
      hint: 'When data grows fastest, e.g. Q4, month-end',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? growth;

  /// Forward-looking forecasts and utilization.
  @SectionId('DVSP')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (capacity projection)'],
    'Forward-looking volume forecasts and current capacity utilization that '
    'inform future capacity needs.',
  )
  @Form([
    Field(
      'projectedVolumeOneYear',
      String,
      'Projected Volume (1 Year)',
      hint: 'Expected volume in 12 months',
    ),
    Field(
      'projectedVolumeThreeYears',
      String,
      'Projected Volume (3 Years)',
      hint: 'Expected volume in 36 months',
    ),
    Field(
      'capacityUtilization',
      String,
      'Current Capacity Utilization',
      hint: 'Percentage of storage capacity used, e.g. 72%',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? projection;

  /// Capacity pressure and cost impact.
  @SectionId('DVSC')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (capacity & cost baseline)'],
    'Storage capacity pressure and its cost: current constraints, total storage '
    'cost, and projected cost growth.',
  )
  @Form([
    Field(
      'capacityConstraints',
      String,
      'Capacity Constraints',
      hint: 'Any current or anticipated capacity issues',
    ),
    Field(
      'storageCost',
      String,
      'Total Storage Cost',
      hint: 'Annual cost of data storage, e.g. €250k/year',
    ),
    Field(
      'costGrowthProjection',
      String,
      'Cost Growth Projection',
      hint: 'Expected storage cost growth',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? capacity;
}

/// Volume details for a specific data source.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data volume baseline)'],
  'The volume and growth profile of one source: current volume, record count, '
  'average size, historical and projected growth, drivers, and archival/purge.',
)
@SectionId('DAVOEN')
class DataVolumeEntry extends DocSpecsSection {
  @Form([
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Name of the data source',
      required: true,
    ),
    Field(
      'currentVolume',
      String,
      'Current Volume',
      hint: 'Current data volume',
    ),
    Field(
      'recordCount',
      String,
      'Record Count',
      hint: 'Number of records/documents',
    ),
    Field(
      'averageRecordSize',
      String,
      'Average Record Size',
      hint: 'Average size per record',
    ),
    Field(
      'historicalGrowth',
      String,
      'Historical Growth',
      hint: 'Growth over past 12 months',
    ),
    Field(
      'projectedGrowth',
      String,
      'Projected Growth',
      hint: 'Expected growth over next 12 months',
    ),
    Field(
      'growthDrivers',
      String,
      'Growth Drivers',
      hint: 'What drives data growth in this source',
    ),
    Field(
      'archivalRate',
      String,
      'Archival Rate',
      hint: 'How much data is archived periodically',
    ),
    Field(
      'purgeRate',
      String,
      'Purge Rate',
      hint: 'How much data is deleted periodically',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 1.4.6. Retention Policies.
///
/// Documentation of data retention policies, legal requirements,
/// archival strategies, and data lifecycle management.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data retention & lifecycle)',
    'DAMA-DMBOK2 — data management body of knowledge',
  ],
  'The AS-IS retention and lifecycle regime — the policy framework, regulatory '
  'drivers, archival and deletion practices, and per-category retention rules.',
)
@SectionId('DAREPO')
class DataRetentionPolicies extends DocSpecsSection {
  @ContentHelp('''
Overview of data retention policies and lifecycle management. Describe the
policy framework, regulatory drivers, implementation status, and any gaps.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Retention policy summary.
  @SectionId('REPOSU')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data retention & lifecycle)'],
    'The aggregate retention posture: whether a framework exists, primary '
    'regulations, default period, compliance rate, archival/purging automation, '
    'and known gaps.',
  )
  @Form([
    Field(
      'policyFrameworkExists',
      String,
      'Policy Framework Exists',
      hint: 'Yes / Partial / No',
    ),
    Field(
      'primaryRegulations',
      String,
      'Primary Regulations',
      hint: 'Key regulations driving retention, e.g. GDPR, SOX, HIPAA',
    ),
    Field(
      'defaultRetentionPeriod',
      String,
      'Default Retention Period',
      hint: 'Default retention if not specified, e.g. 7 years',
    ),
    Field(
      'policyComplianceRate',
      String,
      'Policy Compliance Rate',
      hint: 'Percentage of data following retention policies',
    ),
    Field(
      'archivalSystemExists',
      String,
      'Archival System',
      hint: 'Yes / No — whether systematic archival exists',
    ),
    Field(
      'automatedPurging',
      String,
      'Automated Purging',
      hint: 'Yes / Partial / Manual — purging automation level',
    ),
    Field(
      'legalHoldProcess',
      String,
      'Legal Hold Process',
      hint: 'Whether legal hold process is defined',
    ),
    Field(
      'retentionGaps',
      String,
      'Retention Gaps',
      hint: 'Number of data areas without retention policies',
    ),
    Field(
      'lastPolicyReview',
      String,
      'Last Policy Review',
      hint: 'When retention policies were last reviewed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? policySummary;

  /// Retention policies by data category.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data retention & lifecycle)',
  ], 'The retention policies, one entry per data category.')
  @SectionId('REPOL-RETE-LST')
  @SectionIdPattern('REPOL-RETE-xxx')
  @ContentHelp(
    'Add one entry per data category with a retention policy. '
    'Capture its retention period and trigger, legal basis, archival and '
    'deletion methods, and compliance/implementation status.',
  )
  @Min(1)
  @SerializationOrder(2)
  List<RetentionPolicyEntry> retentionPolicies = [];
}

/// Retention policy for a specific data category.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data retention & lifecycle)'],
  'A single retention policy: the data category it covers, its timing and legal '
  'basis, archival and deletion lifecycle, and compliance status.',
)
@SectionId('REPOL')
class RetentionPolicyEntry extends DocSpecsSection {
  @Form([
    Field(
      'policyId',
      String,
      'Policy ID',
      hint: 'Unique identifier',
      required: true,
    ),
    Field(
      'dataCategory',
      String,
      'Data Category',
      hint: 'Category of data this policy applies to',
      required: true,
    ),
    Field(
      'appliesTo',
      String,
      'Applies To',
      hint: 'Specific data sources or entities',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Retention timing and legal basis.
  @SectionId('RPER')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data retention requirements)'],
    'The timing rules of this policy: how long data is retained, what starts the '
    'retention clock, and the legal basis requiring it.',
  )
  @Form([
    Field(
      'retentionPeriod',
      String,
      'Retention Period',
      hint: 'How long data is retained, e.g. 7 years',
    ),
    Field(
      'retentionTrigger',
      String,
      'Retention Trigger',
      hint: 'What starts the retention clock, e.g. creation date, last access',
    ),
    Field(
      'legalBasis',
      String,
      'Legal Basis',
      hint: 'Regulation or law requiring this retention',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? requirements;

  /// Archival and deletion lifecycle handling.
  @SectionId('RPEL')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data lifecycle handling)'],
    'How data under this policy is archived and deleted, and how exceptions to '
    'the policy are handled.',
  )
  @Form([
    Field(
      'archivalMethod',
      String,
      'Archival Method',
      hint: 'How data is archived, e.g. cold storage, tape, cloud archive',
    ),
    Field(
      'deletionMethod',
      String,
      'Deletion Method',
      hint:
          'How data is deleted, e.g. logical delete, physical purge, secure wipe',
    ),
    Field(
      'exceptionProcess',
      String,
      'Exception Process',
      hint: 'How exceptions to the policy are handled',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? lifecycle;

  /// Compliance and accountability status.
  @SectionId('RPEG')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data retention compliance)'],
    'The compliance and accountability state of this policy: its compliance and '
    'implementation status, and who is responsible for enforcing it.',
  )
  @Form([
    Field(
      'complianceStatus',
      String,
      'Compliance Status',
      hint: 'Compliant / PartiallyCompliant / NonCompliant',
    ),
    Field(
      'implementationStatus',
      String,
      'Implementation Status',
      hint: 'Implemented / InProgress / Planned / NotImplemented',
    ),
    Field(
      'responsibleParty',
      String,
      'Responsible Party',
      hint: 'Who is responsible for enforcing this policy',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

/// 1.4.7. Data Governance.
///
/// Current data governance structure, policies, processes, and maturity level.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data governance)',
    'DAMA-DMBOK2 — data governance',
  ],
  'The AS-IS data governance regime — its maturity, organizational structure, '
  'and the catalogue of governance policies in force.',
)
@SectionId('DAGO')
class DataGovernance extends DocSpecsSection {
  @ContentHelp('''
Overview of data governance in the organization. Describe the governance
framework, organizational structure, policies, and current maturity level.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Governance maturity assessment.
  @SectionId('DAGOMA')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data governance maturity)',
      'DAMA-DMBOK2 — data governance',
    ],
    'The maturity scorecard for data governance across strategy, organization, '
    'policy, process, technology, and culture, with target level and key gaps.',
  )
  @Form([
    Field(
      'overallMaturityLevel',
      String,
      'Overall Maturity Level',
      hint: 'Level 1-5 or Initial/Managed/Defined/Measured/Optimized',
    ),
    Field(
      'strategyMaturity',
      String,
      'Strategy Maturity',
      hint: 'Maturity of data governance strategy',
    ),
    Field(
      'organizationMaturity',
      String,
      'Organization Maturity',
      hint: 'Maturity of governance organizational structure',
    ),
    Field(
      'policyMaturity',
      String,
      'Policy Maturity',
      hint: 'Maturity of governance policies',
    ),
    Field(
      'processMaturity',
      String,
      'Process Maturity',
      hint: 'Maturity of governance processes',
    ),
    Field(
      'technologyMaturity',
      String,
      'Technology Maturity',
      hint: 'Maturity of supporting technology/tools',
    ),
    Field(
      'cultureMaturity',
      String,
      'Culture Maturity',
      hint: 'Data-aware culture maturity',
    ),
    Field(
      'assessmentDate',
      String,
      'Assessment Date',
      hint: 'When maturity was last assessed',
    ),
    Field(
      'targetMaturityLevel',
      String,
      'Target Maturity Level',
      hint: 'Desired maturity level',
    ),
    Field(
      'maturityGaps',
      String,
      'Key Maturity Gaps',
      hint: 'Areas needing most improvement',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governanceMaturity;

  /// Governance organization structure.
  @SectionId('DAGO-GOVE')
  @ContentType(
    'mermaid',
    'Organizational chart showing data governance '
        'roles and reporting structure',
  )
  @SerializationOrder(2)
  DocSpecsSection? governanceOrgChart;

  /// Data governance policies.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data governance)',
    'DAMA-DMBOK2 — data governance',
  ], 'The governance policies in force, one entry per policy.')
  @Min(1)
  @SectionId('DGPE-GOVE-LST')
  @SectionIdPattern('DGPE-GOVE-xxx')
  @ContentHelp(
    'Add one entry per data governance policy (quality, security, '
    'privacy, access, MDM). Capture its area, scope, status, owner, '
    'enforcement mechanism, and current compliance level.',
  )
  @SerializationOrder(3)
  List<DataGovernancePolicyEntry> governancePolicies = [];
}

/// Data governance policy entry.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data governance)',
    'DAMA-DMBOK2 — data governance',
  ],
  'A single data governance policy: its identity and area, its lifecycle and '
  'applicability, and its ownership, enforcement, and compliance status.',
)
@SectionId('DGPE')
class DataGovernancePolicyEntry extends DocSpecsSection {
  @Form([
    Field('policyId', String, 'Policy ID', hint: 'Unique identifier'),
    Field(
      'policyName',
      String,
      'Policy Name',
      hint: 'Name of the governance policy',
      required: true,
    ),
    Field(
      'policyArea',
      String,
      'Policy Area',
      hint: 'DataQuality / DataSecurity / DataPrivacy / DataAccess / MDM',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Brief description of the policy',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Policy lifecycle and applicability.
  @SectionId('DGPEL')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data governance)'],
    'The lifecycle and reach of this policy: its scope, status, effective date, '
    'and review frequency.',
  )
  @Form([
    Field('scope', String, 'Scope', hint: 'What the policy applies to'),
    Field(
      'status',
      String,
      'Status',
      hint: 'Draft / Approved / InForce / UnderReview / Retired',
    ),
    Field(
      'effectiveDate',
      String,
      'Effective Date',
      hint: 'When the policy became effective',
    ),
    Field(
      'reviewFrequency',
      String,
      'Review Frequency',
      hint: 'How often the policy is reviewed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? lifecycle;

  /// Ownership, enforcement, and compliance status.
  @SectionId('DGPEG')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data governance)',
      'DAMA-DMBOK2 — data governance',
    ],
    'Who owns and enforces this policy and how well it is followed: policy owner, '
    'enforcement mechanism, and compliance level.',
  )
  @Form([
    Field('policyOwner', String, 'Policy Owner', hint: 'Who owns the policy'),
    Field(
      'enforcementMechanism',
      String,
      'Enforcement Mechanism',
      hint: 'How the policy is enforced',
    ),
    Field(
      'complianceLevel',
      String,
      'Compliance Level',
      hint: 'Current compliance with this policy',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;
}

/// 1.4.8. Data Classification.
///
/// Data classification framework, sensitivity levels, and current
/// classification status of data assets.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data classification)',
    'ISO/IEC 27001 — information classification',
  ],
  'The AS-IS data classification regime — the framework and sensitivity levels '
  'defined, and how far data assets have actually been classified.',
)
@SectionId('CUDACL')
class CurrentDataClassification extends DocSpecsSection {
  @ContentHelp('''
Overview of data classification in the organization. Describe the classification
framework, sensitivity levels, handling requirements, and current classification
coverage.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Classification framework summary.
  @SectionId('DACLSU')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (data classification)',
      'ISO/IEC 27001 — information classification',
    ],
    'The aggregate classification posture: whether a framework exists, its name '
    'and number of levels, coverage, auto-classification, labeling, and training.',
  )
  @Form([
    Field(
      'classificationFrameworkExists',
      String,
      'Framework Exists',
      hint: 'Yes / Partial / No',
    ),
    Field(
      'frameworkName',
      String,
      'Framework Name',
      hint: 'Name of classification framework if standardized',
    ),
    Field(
      'numberOfLevels',
      int,
      'Number of Levels',
      hint: 'How many classification levels are defined',
    ),
    Field(
      'classificationCoverage',
      String,
      'Classification Coverage',
      hint: 'Percentage of data that is classified',
    ),
    Field(
      'autoClassificationExists',
      String,
      'Auto-Classification',
      hint: 'Yes / Partial / No — automated classification tools',
    ),
    Field(
      'labelingImplemented',
      String,
      'Labeling Implemented',
      hint: 'Whether data is actively labeled',
    ),
    Field(
      'handlingProceduresDocumented',
      String,
      'Handling Procedures',
      hint: 'Whether handling procedures per level are documented',
    ),
    Field(
      'trainingProvided',
      String,
      'Training Provided',
      hint: 'Whether classification training is provided',
    ),
    Field(
      'lastFrameworkReview',
      String,
      'Last Framework Review',
      hint: 'When the framework was last reviewed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classificationSummary;

  /// Classification levels defined.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data classification)',
    'ISO/IEC 27001 — information classification',
  ], 'The sensitivity levels defined by the framework, one entry per level.')
  @Min(1)
  @SectionId('DCLE-CLAS-LST')
  @SectionIdPattern('DCLE-CLAS-xxx')
  @ContentHelp(
    'Add one entry per classification level (e.g. Public, Internal, '
    'Confidential, Restricted). Capture its order, meaning, examples, and the '
    'handling, access, storage, transmission, and disposal requirements.',
  )
  @SerializationOrder(2)
  List<DataClassificationLevelEntry> classificationLevels = [];

  /// Classification status by data domain.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data classification coverage)',
  ], 'How far classification has been applied, one entry per data domain.')
  @SectionId('DCSE-CLAS-LST')
  @SectionIdPattern('DCSE-CLAS-xxx')
  @ContentHelp(
    'Add one entry per data domain. Capture its classification '
    'status, percentage classified, highest sensitivity level present, the '
    'classification owner, and when it was last reviewed.',
  )
  @SerializationOrder(3)
  List<DataClassificationStatusEntry> classificationStatus = [];
}

/// A data classification level definition.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data classification)',
    'ISO/IEC 27001 — information classification',
  ],
  'One sensitivity level: its name and order, meaning and examples, and the '
  'handling, access, storage, transmission, disposal, and incident rules.',
)
@SectionId('DCLE')
class DataClassificationLevelEntry extends DocSpecsSection {
  @Form([
    Field(
      'levelName',
      String,
      'Level Name',
      hint: 'E.g. Public, Internal, Confidential, Restricted',
      required: true,
    ),
    Field(
      'levelOrder',
      int,
      'Level Order',
      hint: 'Numeric order, 1=lowest sensitivity',
    ),
    Field('description', String, 'Description', hint: 'What this level means'),
    Field(
      'dataExamples',
      String,
      'Data Examples',
      hint: 'Examples of data at this level',
    ),
    Field(
      'handlingRequirements',
      String,
      'Handling Requirements',
      hint: 'How data at this level must be handled',
    ),
    Field(
      'accessRestrictions',
      String,
      'Access Restrictions',
      hint: 'Who can access data at this level',
    ),
    Field(
      'storageRequirements',
      String,
      'Storage Requirements',
      hint: 'How data at this level must be stored',
    ),
    Field(
      'transmissionRequirements',
      String,
      'Transmission Requirements',
      hint: 'How data at this level can be transmitted',
    ),
    Field(
      'disposalRequirements',
      String,
      'Disposal Requirements',
      hint: 'How data at this level must be disposed',
    ),
    Field(
      'incidentResponseLevel',
      String,
      'Incident Response',
      hint: 'Response level if breached',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Classification status for a data domain.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data classification coverage)'],
  'How far one data domain has been classified: its status, percentage done, '
  'highest sensitivity present, owner, and last review.',
)
@SectionId('DCSE')
class DataClassificationStatusEntry extends DocSpecsSection {
  @Form([
    Field(
      'dataDomain',
      String,
      'Data Domain',
      hint: 'Business area or data domain',
      required: true,
    ),
    Field(
      'classificationStatus',
      String,
      'Classification Status',
      hint: 'Complete / InProgress / NotStarted',
    ),
    Field(
      'percentageClassified',
      String,
      'Percentage Classified',
      hint: 'How much of this domain is classified',
    ),
    Field(
      'highestSensitivityLevel',
      String,
      'Highest Sensitivity',
      hint: 'Highest classification level in this domain',
    ),
    Field(
      'classificationOwner',
      String,
      'Classification Owner',
      hint: 'Who is responsible for classification',
    ),
    Field(
      'lastReview',
      String,
      'Last Review',
      hint: 'When classification was last reviewed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 1.4.9. Data Integration Points.
///
/// Documentation of data integration points, ETL processes, APIs,
/// and data exchange mechanisms.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (data flows & integration)',
    'DAMA-DMBOK2 — data integration and interoperability',
  ],
  'The AS-IS data integration landscape — the integration architecture, major '
  'data flows, and the inventory of integration points between systems.',
)
@SectionId('DAINPO')
class DataIntegrationPoints extends DocSpecsSection {
  @ContentHelp('''
Overview of data integration across the organization. Describe the integration
architecture, major data flows, technologies used, and integration challenges.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Integration summary.
  @SectionId('DAINSU')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data flows & integration)'],
    'The aggregate integration picture: total points, architecture style, primary '
    'tool, real-time/batch/API split, reliability, latency, and known bottlenecks.',
  )
  @Form([
    Field(
      'totalIntegrationPoints',
      int,
      'Total Integration Points',
      hint: 'Number of distinct data integration points',
    ),
    Field(
      'integrationArchitecture',
      String,
      'Integration Architecture',
      hint: 'PointToPoint / Hub / ESB / EventDriven / Hybrid',
    ),
    Field(
      'primaryIntegrationTool',
      String,
      'Primary Integration Tool',
      hint: 'Main ETL/integration platform',
    ),
    Field(
      'realtimeIntegrations',
      int,
      'Real-time Integrations',
      hint: 'Number of real-time integrations',
    ),
    Field(
      'batchIntegrations',
      int,
      'Batch Integrations',
      hint: 'Number of batch/scheduled integrations',
    ),
    Field(
      'apiIntegrations',
      int,
      'API Integrations',
      hint: 'Number of API-based integrations',
    ),
    Field(
      'integrationReliability',
      String,
      'Overall Reliability',
      hint: 'Success rate of integrations, e.g. 98.5%',
    ),
    Field(
      'averageLatency',
      String,
      'Average Latency',
      hint: 'Typical integration latency',
    ),
    Field(
      'knownBottlenecks',
      int,
      'Known Bottlenecks',
      hint: 'Number of integration bottlenecks',
    ),
    Field(
      'integrationDebt',
      String,
      'Integration Debt',
      hint: 'Technical debt in integration layer',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? integrationSummary;

  /// Data flow diagram.
  @SectionId('DAINPO-DATA')
  @ContentType(
    'mermaid-flowchart',
    'Diagram showing major data flows '
        'and integration points between systems',
  )
  @SerializationOrder(2)
  DocSpecsSection? dataFlowDiagram;

  /// Data integration points inventory.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (data flows & integration)',
  ], 'The catalogued integration points, one entry per data exchange.')
  @SectionId('DAIN-INTE-LST')
  @SectionIdPattern('DAIN-INTE-xxx')
  @ContentHelp(
    'Add one entry per data integration point. Capture its source '
    'and target systems, integration type, volume and transport, reliability '
    'and monitoring, and its owners.',
  )
  @Min(1)
  @SerializationOrder(3)
  List<DataIntegrationEntry> integrationPoints = [];
}

/// A data integration point entry.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (data flows & integration)'],
  'A single integration point: what it exchanges, its endpoints and type, '
  'volume and transport, reliability and monitoring, and ownership.',
)
@SectionId('DAIN')
class DataIntegrationEntry extends DocSpecsSection {
  @Form([
    Field(
      'integrationId',
      String,
      'Integration ID',
      hint: 'Unique identifier',
      required: true,
    ),
    Field(
      'integrationName',
      String,
      'Integration Name',
      hint: 'Name of the integration',
      required: true,
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What data is exchanged and why',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Endpoints and type.
  @SectionId('DIEE')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data flows & integration)'],
    'The endpoints of this integration: the source and target systems and the '
    'kind of integration between them.',
  )
  @Form([
    Field(
      'sourceSystem',
      String,
      'Source System',
      hint: 'System providing the data',
    ),
    Field(
      'targetSystem',
      String,
      'Target System',
      hint: 'System receiving the data',
    ),
    Field(
      'integrationType',
      String,
      'Integration Type',
      hint: 'ETL / ELT / API / FileTransfer / EventStream / CDC',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? endpoints;

  /// Volume and transport.
  @SectionId('DIET')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data flows & integration)'],
    'How data moves across this integration: volume, frequency, technology, '
    'protocol, and transformation.',
  )
  @Form([
    Field(
      'dataVolume',
      String,
      'Data Volume',
      hint: 'Typical volume per execution',
    ),
    Field(
      'frequency',
      String,
      'Frequency',
      hint: 'RealTime / NearRealTime / Hourly / Daily / Weekly / OnDemand',
    ),
    Field(
      'technology',
      String,
      'Technology',
      hint: 'Integration technology used',
    ),
    Field(
      'protocol',
      String,
      'Protocol',
      hint: 'Communication protocol, e.g. REST, SOAP, SFTP, Kafka',
    ),
    Field(
      'dataTransformation',
      String,
      'Data Transformation',
      hint: 'Type/complexity of transformation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? transport;

  /// Reliability and monitoring.
  @SectionId('DIER')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (integration reliability)'],
    'How dependable this integration is: error handling, monitoring, reliability, '
    'latency, and any SLA.',
  )
  @Form([
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'How errors are handled',
    ),
    Field(
      'monitoringStatus',
      String,
      'Monitoring Status',
      hint: 'None / Basic / Comprehensive',
    ),
    Field(
      'reliability',
      String,
      'Reliability',
      hint: 'Success rate, e.g. 99.2%',
    ),
    Field(
      'latency',
      String,
      'Latency',
      hint: 'Typical latency, e.g. 5 seconds, 2 hours',
    ),
    Field('sla', String, 'SLA', hint: 'Service level agreement if defined'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? reliabilityInfo;

  /// Ownership and issues.
  @SectionId('DIEO')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (data flows & integration)'],
    'Who owns this integration and how critical it is: business and technical '
    'owners, criticality, and known issues.',
  )
  @Form([
    Field(
      'businessOwner',
      String,
      'Business Owner',
      hint: 'Who owns this integration',
    ),
    Field(
      'technicalOwner',
      String,
      'Technical Owner',
      hint: 'Who maintains this integration',
    ),
    Field(
      'criticality',
      String,
      'Business Criticality',
      hint: 'Critical / High / Medium / Low',
    ),
    Field(
      'knownIssues',
      String,
      'Known Issues',
      hint: 'Current problems with this integration',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ownership;
}

/// 1.4.10. Master Data Management.
///
/// Master data management practices, golden records, and data
/// synchronization across systems.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (master data management)',
    'DAMA-DMBOK2 — master and reference data management',
  ],
  'The AS-IS master data management regime — MDM strategy and maturity, the '
  'master data domains, their golden-record sources, and synchronization.',
)
@SectionId('MADAMA')
class MasterDataManagement extends DocSpecsSection {
  @ContentHelp('''
Overview of master data management in the organization. Describe the MDM
strategy, master data domains, golden record sources, and synchronization
approach.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// MDM maturity and status summary.
  @SectionId('MDSU')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (master data management)',
      'DAMA-DMBOK2 — master and reference data management',
    ],
    'The aggregate MDM posture: maturity, strategy and platform, domain count, '
    'golden-record coverage, matching capability, and key gaps.',
  )
  @Form([
    Field(
      'mdmMaturityLevel',
      String,
      'MDM Maturity Level',
      hint: 'Level 1-5 or Initial/Managed/Defined/Measured/Optimized',
    ),
    Field(
      'mdmStrategy',
      String,
      'MDM Strategy',
      hint: 'Centralized / RegionalHubs / Federated / NoStrategy',
    ),
    Field(
      'mdmPlatform',
      String,
      'MDM Platform',
      hint: 'Technology used for MDM if any',
    ),
    Field(
      'totalMasterDataDomains',
      int,
      'Total Master Data Domains',
      hint: 'Number of defined master data domains',
    ),
    Field(
      'goldenRecordCoverage',
      String,
      'Golden Record Coverage',
      hint: 'Percentage of master data with golden records',
    ),
    Field(
      'dataQualityInMaster',
      String,
      'Master Data Quality',
      hint: 'Quality level of master data',
    ),
    Field(
      'synchronizationApproach',
      String,
      'Synchronization Approach',
      hint: 'How master data is synchronized across systems',
    ),
    Field(
      'dataMatchingCapability',
      String,
      'Data Matching Capability',
      hint: 'Level of deduplication/matching capability',
    ),
    Field(
      'hierarchyManagement',
      String,
      'Hierarchy Management',
      hint: 'How organizational/product hierarchies are managed',
    ),
    Field(
      'mdmGaps',
      String,
      'Key MDM Gaps',
      hint: 'Primary gaps in master data management',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? mdmSummary;

  /// Master data domains.
  @StandardReferences([
    'BABOK v3 §10 — current-state analysis (master data management)',
    'DAMA-DMBOK2 — master and reference data management',
  ], 'The master data domains, one entry per domain.')
  @SectionId('MSDDO-MAST-LST')
  @SectionIdPattern('MSDDO-MAST-xxx')
  @ContentHelp(
    'Add one entry per master data domain (e.g. Customer, Product, '
    'Vendor). Capture its golden-record source, quality and volume, consuming '
    'systems and cadence, and ownership and improvement plans.',
  )
  @Min(1)
  @SerializationOrder(2)
  List<MasterDataDomainEntry> masterDataDomains = [];
}

/// Master data domain entry.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (master data management)',
    'DAMA-DMBOK2 — master and reference data management',
  ],
  'A single master data domain: its golden-record source, quality and volume, '
  'downstream usage and cadence, and ownership and improvement planning.',
)
@SectionId('MSDDO')
class MasterDataDomainEntry extends DocSpecsSection {
  @Form([
    Field(
      'domainName',
      String,
      'Domain Name',
      hint: 'E.g. Customer, Product, Vendor, Employee, Location',
      required: true,
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this master data domain covers',
    ),
    Field(
      'goldenRecordSource',
      String,
      'Golden Record Source',
      hint: 'Authoritative system for this master data',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Volume and quality indicators.
  @SectionId('MDDEQ')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (master data quality)',
      'ISO/IEC 25012 — data quality model',
    ],
    'The size and quality of this master data domain: record count, quality '
    'score, and duplicate rate.',
  )
  @Form([
    Field(
      'recordCount',
      String,
      'Record Count',
      hint: 'Number of master records',
    ),
    Field(
      'qualityScore',
      String,
      'Quality Score',
      hint: 'Quality of master data in this domain',
    ),
    Field(
      'duplicateRate',
      String,
      'Duplicate Rate',
      hint: 'Estimated duplication, e.g. 3%',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? quality;

  /// Downstream usage and cadence.
  @SectionId('MDDEU')
  @StandardReferences(
    ['BABOK v3 §10 — current-state analysis (master data management)'],
    'How this master data domain is consumed: the systems that use it, its update '
    'frequency, and its level of governance.',
  )
  @Form([
    Field(
      'consumingSystems',
      String,
      'Consuming Systems',
      hint: 'Systems that use this master data',
    ),
    Field(
      'updateFrequency',
      String,
      'Update Frequency',
      hint: 'How often master data is updated',
    ),
    Field(
      'governanceLevel',
      String,
      'Governance Level',
      hint: 'Level of governance for this domain',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? usage;

  /// Ownership and improvement planning.
  @SectionId('MDDEG')
  @StandardReferences(
    [
      'BABOK v3 §10 — current-state analysis (master data governance)',
      'DAMA-DMBOK2 — master and reference data management',
    ],
    'Who owns this master data domain and how it will improve: domain owner, '
    'data steward, known issues, and improvement plan.',
  )
  @Form([
    Field(
      'domainOwner',
      String,
      'Domain Owner',
      hint: 'Who owns this master data domain',
    ),
    Field(
      'dataSteward',
      String,
      'Data Steward',
      hint: 'Steward responsible for data quality',
    ),
    Field(
      'knownIssues',
      String,
      'Known Issues',
      hint: 'Current issues with this master data',
    ),
    Field(
      'improvementPlan',
      String,
      'Improvement Plan',
      hint: 'Plans to improve this domain',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

// ---------------------------------------------------------------------------
// 1.5 Operational Metrics
// ---------------------------------------------------------------------------

/// 1.5. Operational Metrics.
///
/// Baseline metrics of the current systems: throughput, volume, uptime,
/// response times, user counts. Used to size the target system and to
/// derive non-functional requirements.
@StandardReferences(
  ['BABOK v3 §10 — current-state analysis (operational baseline metric)'],
  'One measurable operational characteristic of the current systems — a '
  'baseline figure used to size the target system and derive its '
  'non-functional requirements.',
)
@SectionId('CUOPME')
@DetailedIn(D01CurrentLandscapeAssessment)
class CurrentOperationalMetric extends DocSpecsSection {
  @ContentHelp('''
Captures measurable operational characteristics of the current systems
landscape. Feeds requirement derivation (target throughput, peak-load
handling, availability targets) and risk assessment (what degrades if the
replacement underperforms the baseline).

**What to capture:**
- Transaction volumes (per day/week/month) and peak factors
- User counts (active / concurrent / peak)
- Response-time baselines for key operations
- Availability / uptime historicals
- Error rates and incident frequency
- Storage growth rates and retention sizing
- Integration volumes (messages, API calls per interval)
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 1.6 Current State Risks
// ---------------------------------------------------------------------------

/// 1.6. Current State Risks.
///
/// Risks tied to the current state and to its replacement. Distinct from
/// the target-side risks section which covers replacement risks.
@StandardReferences(
  [
    'BABOK v3 §10 — current-state analysis (current-state risks)',
    'ISO 31000:2018 — risk management (risk identification & assessment)',
  ],
  'The assessment of risks arising from the current systems landscape and from '
  'the act of replacing it — distinct from the target-state replacement risks.',
)
@SectionId('CUSTRI')
@DetailedIn(D01CurrentLandscapeAssessment)
class CurrentStateRiskAssessment extends DocSpecsSection {
  @ContentHelp('''
Risks that originate from the current systems landscape or from the act of
replacing them. Not to be confused with target-state risks.

**What to capture:**
- Stability / reliability risks of the current systems
- Vendor / contract risks (EOL, licensing, support)
- Knowledge risks (key-person dependencies on legacy systems)
- Data-integrity risks during transition
- Operational-continuity risks (cutover windows, parallel-run exposure)
- Compliance risks of keeping legacy systems in operation
- Replacement-specific risks (scope creep, timeline, migration failures)
''')
  @override
  @SerializationOrder(0)
  String? content;
}
