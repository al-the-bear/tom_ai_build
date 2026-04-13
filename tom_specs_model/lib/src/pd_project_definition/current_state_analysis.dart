/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 1. Current State Analysis [PD00-CUR].
@SectionId('PD00-CUR')
class CurrentStateAnalysis {
  @Unused()
  String? content;

  /// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
  ExistingSystemsLandscape existingSystemsLandscape = ExistingSystemsLandscape();

  /// 1.2. Current Business Processes [PD00-CUR-PRO].
  CurrentBusinessProcesses currentBusinessProcesses = CurrentBusinessProcesses();

  /// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// 1.4. Current Data Landscape [PD00-CUR-DAT].
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();
}

// ---------------------------------------------------------------------------
// 1.1 Existing Systems Landscape
// ---------------------------------------------------------------------------

/// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
///
/// Overview of the current systems in use, their roles, technology stacks,
/// and limitations. Provides the foundation for understanding the AS-IS state.
@SectionId('PD00-CUR-SYS')
class ExistingSystemsLandscape {
  @ContentType('description', 'High-level overview of the existing systems '
      'landscape. Include a context diagram showing how systems interact.')
  String? content;

  /// 1.1.1. System Inventory [PD00-CUR-SYS-INV].
  SystemInventory systemInventory = SystemInventory();

  /// 1.1.2. Current Architecture [PD00-CUR-SYS-ARC].
  CurrentArchitecture currentArchitecture = CurrentArchitecture();

  /// 1.1.3. Dependencies and Integrations [PD00-CUR-SYS-DEP].
  DependenciesAndIntegrations dependenciesAndIntegrations =
      DependenciesAndIntegrations();
}

/// 1.1.1. System Inventory [PD00-CUR-SYS-INV].
///
/// Container for individual system descriptions. Add one entry per existing
/// system relevant to the project scope.
@SectionId('PD00-CUR-SYS-INV')
class SystemInventory {
  @ContentType('description', 'Introduction to the system inventory. '
      'Describe the criteria for including systems and the overall landscape.')
  String? content;

  /// Contains 1+× Existing System [PD00-CUR-SYS-INV-nn].
  @SectionIdPattern('PD00-CUR-SYS-INV-xx')
  @Min(1)
  @ContentHelp('Add one entry per existing system that is relevant to the '
      'project scope. Include all systems that will be replaced, integrated '
      'with, or affected by the new system.')
  List<ExistingSystemEntry> systems = [];
}

/// 1.1.2. Current Architecture [PD00-CUR-SYS-ARC].
///
/// Description of the current system architecture including deployment
/// topology, integration patterns, shared services, and data stores.
@SectionId('PD00-CUR-SYS-ARC')
class CurrentArchitecture {
  @ContentType('description', 'Narrative description of the current '
      'architecture including deployment topology, integration patterns, '
      'shared services, and data stores.')
  @ContentHelp('Describe the current system architecture. Include deployment '
      'topology, integration patterns, shared services, data stores. '
      'Reference an architecture overview diagram.')
  String? content;

  /// Architecture overview diagram [PD00-CUR-SYS-ARC-DIA].
  @SectionId('PD00-CUR-SYS-ARC-DIA')
  @ContentType('mermaid-flowchart', 'Architecture overview diagram showing '
      'systems, their connections, and data flows')
  @ContentHelp('Provide a Mermaid flowchart showing the current architecture. '
      'Include all major systems, their connections, and data flow directions.')
  String? architectureDiagram;

  /// Deployment topology description [PD00-CUR-SYS-ARC-DEP].
  @ContentType('description', 'Description of how systems are deployed '
      'across infrastructure')
  String? deploymentTopology;

  /// Integration patterns used [PD00-CUR-SYS-ARC-INT].
  @ContentType('description', 'Description of integration patterns '
      '(API, file transfer, message queue, etc.)')
  String? integrationPatterns;

  /// Shared services inventory [PD00-CUR-SYS-ARC-SHR].
  @ContentType('description', 'List and description of shared services '
      'used across systems')
  String? sharedServices;
}

/// An existing system entry [PD00-CUR-SYS-INV-nn] (form).
///
/// Captures comprehensive information about an existing system including
/// identity, technology, business context, usage metrics, lifecycle, and risks.
class ExistingSystemEntry {
  // -------------------------------------------------------------------------
  // System Identity
  // -------------------------------------------------------------------------

  @Form([
    Field('systemName', String, 'System Name', required: true),
    Field('systemId', String, 'System ID/Code (internal identifier)'),
    Field('systemVersion', String, 'Current Version'),
    Field('systemType', String, 'System Type '
        '(ERP, CRM, Custom Development, COTS, SaaS, etc.)'),
    Field('vendor', String, 'Vendor (if commercial software)'),
    Field('licenseType', String, 'License Type '
        '(Enterprise, Per-User, Subscription, Open Source, etc.)'),
  ])
  String? content;

  // -------------------------------------------------------------------------
  // Technology Stack
  // -------------------------------------------------------------------------

  /// Technology stack details [PD00-CUR-SYS-INV-nn-TEC].
  @Comment('Technology stack')
  ExistingSystemTechnology? technology;

  // -------------------------------------------------------------------------
  // Business Context
  // -------------------------------------------------------------------------

  /// Business context [PD00-CUR-SYS-INV-nn-BUS].
  @Comment('Business context')
  ExistingSystemBusinessContext? businessContext;

  // -------------------------------------------------------------------------
  // Usage Metrics
  // -------------------------------------------------------------------------

  /// Usage metrics [PD00-CUR-SYS-INV-nn-USE].
  @Comment('Usage metrics')
  ExistingSystemUsage? usage;

  // -------------------------------------------------------------------------
  // Lifecycle Information
  // -------------------------------------------------------------------------

  /// Lifecycle information [PD00-CUR-SYS-INV-nn-LIF].
  @Comment('Lifecycle information')
  ExistingSystemLifecycle? lifecycle;

  // -------------------------------------------------------------------------
  // Integration Profile
  // -------------------------------------------------------------------------

  /// Integration profile [PD00-CUR-SYS-INV-nn-INT].
  @Comment('Integration profile')
  ExistingSystemIntegration? integrationProfile;

  // -------------------------------------------------------------------------
  // Infrastructure
  // -------------------------------------------------------------------------

  /// Infrastructure details [PD00-CUR-SYS-INV-nn-INF].
  @Comment('Infrastructure')
  ExistingSystemInfrastructure? infrastructure;

  // -------------------------------------------------------------------------
  // Quality & Risk
  // -------------------------------------------------------------------------

  /// Contains 0+× Limitation [PD00-CUR-SYS-INV-nn-LIM-nn].
  @SectionIdPattern('PD00-CUR-SYS-INV-xx-LIM-xx')
  @ContentHelp('Document each known limitation with its impact on current '
      'operations and any workarounds in place.')
  List<LimitationEntry> knownLimitations = [];

  /// Quality and risk assessment [PD00-CUR-SYS-INV-nn-QUA].
  @Comment('Quality and risk')
  ExistingSystemQuality? quality;
}

/// Technology stack details for an existing system.
class ExistingSystemTechnology {
  @Form([
    Field('primaryPlatform', String, 'Primary Technology Platform'),
    Field('programmingLanguages', String, 'Programming Languages (comma-separated)'),
    Field('databaseTechnology', String, 'Database Technology'),
    Field('operatingSystem', String, 'Operating System'),
    Field('frameworksMiddleware', String, 'Frameworks/Middleware'),
    Field('frontendTechnology', String, 'Frontend Technology (if applicable)'),
  ])
  String? content;
}

/// Business context for an existing system.
class ExistingSystemBusinessContext {
  @Form([
    Field('purpose', String, 'Purpose/Description', required: true),
    Field('businessDomain', String, 'Business Domain '
        '(Finance, Sales, Operations, HR, etc.)'),
    Field('owningDepartment', String, 'Owning Business Unit/Department'),
    Field('businessCriticality', String, 'Business Criticality '
        '(Mission Critical, Business Critical, Standard, Low)'),
    Field('businessOwner', String, 'Business Owner (name/role)'),
    Field('technicalOwner', String, 'Technical Owner (name/role)'),
  ])
  String? content;
}

/// Usage metrics for an existing system.
class ExistingSystemUsage {
  @Form([
    Field('activeUsers', int, 'Active Users (total registered)'),
    Field('dailyActiveUsers', int, 'Daily Active Users'),
    Field('peakConcurrentUsers', int, 'Peak Concurrent Users'),
    Field('transactionVolumeDaily', String, 'Transaction Volume (daily average)'),
    Field('dataVolumeCurrent', String, 'Current Data Volume'),
    Field('dataGrowthRate', String, 'Data Growth Rate (monthly/yearly)'),
    Field('availabilityRequirement', String, 'Availability Requirement '
        '(e.g., 99.9%, 24x7, business hours)'),
  ])
  String? content;
}

/// Lifecycle information for an existing system.
class ExistingSystemLifecycle {
  @Form([
    Field('goLiveDate', String, 'Go-Live Date (operational since)'),
    Field('lastMajorUpgrade', String, 'Last Major Upgrade Date'),
    Field('currentVersion', String, 'Current Version'),
    Field('supportStatus', String, 'Support Status '
        '(Active, Limited, Extended, End-of-Life)'),
    Field('supportExpiryDate', String, 'Support Expiry Date'),
    Field('plannedRetirementDate', String, 'Planned Retirement Date (if any)'),
    Field('migrationUrgency', String, 'Migration Urgency '
        '(Immediate, Within 1 year, Within 3 years, No deadline)'),
  ])
  String? content;
}

/// Integration profile for an existing system.
class ExistingSystemIntegration {
  @Form([
    Field('apiTypesAvailable', String, 'API Types Available '
        '(REST, SOAP, GraphQL, gRPC, none)'),
    Field('integrationMethods', String, 'Integration Methods '
        '(API, File Transfer, Database Link, Message Queue, manual)'),
    Field('dataFormats', String, 'Data Formats (JSON, XML, CSV, EDI, etc.)'),
    Field('realTimeCapable', bool, 'Real-Time Integration Capable'),
    Field('batchProcessingWindows', String, 'Batch Processing Windows'),
    Field('externalInterfaceCount', int, 'Number of External Interfaces'),
    Field('internalInterfaceCount', int, 'Number of Internal Interfaces'),
  ])
  String? content;
}

/// Infrastructure details for an existing system.
class ExistingSystemInfrastructure {
  @Form([
    Field('hostingModel', String, 'Hosting Model '
        '(On-Premise, Private Cloud, Public Cloud, Hybrid, SaaS)'),
    Field('cloudProvider', String, 'Cloud Provider (if applicable)'),
    Field('environmentCount', int, 'Number of Environments '
        '(Dev, Test, Staging, Prod, etc.)'),
    Field('geographicDeployment', String, 'Geographic Deployment '
        '(Single region, Multi-region, Global)'),
    Field('disasterRecovery', String, 'Disaster Recovery Capability '
        '(Hot standby, Warm standby, Cold backup, None)'),
    Field('backupFrequency', String, 'Backup Frequency'),
  ])
  String? content;
}

/// Quality and risk assessment for an existing system.
class ExistingSystemQuality {
  @Form([
    Field('technicalDebtLevel', String, 'Technical Debt Level '
        '(Low, Medium, High, Critical)'),
    Field('codeQuality', String, 'Code Quality Assessment '
        '(Good, Acceptable, Poor, Unknown)'),
    Field('documentationStatus', String, 'Documentation Status '
        '(Current, Outdated, Minimal, None)'),
    Field('availabilitySla', String, 'Availability SLA (actual achieved)'),
    Field('securityComplianceStatus', String, 'Security Compliance Status'),
    Field('lastSecurityAudit', String, 'Last Security Audit Date'),
    Field('lastPenetrationTest', String, 'Last Penetration Test Date'),
    Field('accessibilityCompliance', String, 'Accessibility Compliance '
        '(WCAG level, Section 508, etc.)'),
  ])
  String? content;
}

/// A known limitation of an existing system (form) [PD00-CUR-SYS-INV-nn-LIM-nn].
class LimitationEntry {
  @Form([
    Field('limitation', String, 'Limitation', required: true),
    Field('impact', String, 'Impact assessment'),
  ])
  String? content;
}

/// 1.1.3. Dependencies and Integrations [PD00-CUR-SYS-DEP].
///
/// Documents how current systems depend on each other, on external services,
/// and on shared infrastructure. Identifies fragile integration points that
/// pose risk to operations or to the new system implementation.
@SectionId('PD00-CUR-SYS-DEP')
class DependenciesAndIntegrations {
  @ContentType('description', 'Overview of the dependency and integration '
      'landscape including systemic risks and fragile points.')
  @ContentHelp('Provide an executive summary of dependencies and integrations. '
      'Highlight critical dependencies, fragile integration points, and '
      'areas requiring attention during the project.')
  String? content;

  /// Dependency matrix diagram [PD00-CUR-SYS-DEP-DIA].
  @SectionId('PD00-CUR-SYS-DEP-DIA')
  @ContentType('mermaid-flowchart', 'Visual representation of system '
      'dependencies showing data flows and coupling strength')
  @ContentHelp('Create a Mermaid flowchart showing dependencies between '
      'systems. Use line styles to indicate coupling strength: solid for '
      'tight coupling, dashed for loose coupling. Add labels for data types.')
  String? dependencyDiagram;

  /// 1.1.3.1. Internal Dependencies [PD00-CUR-SYS-DEP-INT].
  @Comment('Dependencies between internal systems')
  InternalDependencies internalDependencies = InternalDependencies();

  /// 1.1.3.2. External Service Dependencies [PD00-CUR-SYS-DEP-EXT].
  @Comment('Dependencies on external/third-party services')
  ExternalServiceDependencies externalServiceDependencies =
      ExternalServiceDependencies();

  /// 1.1.3.3. Shared Infrastructure Dependencies [PD00-CUR-SYS-DEP-SHR].
  @Comment('Dependencies on shared infrastructure components')
  SharedInfrastructureDependencies sharedInfrastructureDependencies =
      SharedInfrastructureDependencies();

  /// 1.1.3.4. System Integrations [PD00-CUR-SYS-DEP-SYS].
  @Comment('Active integrations between systems')
  Integrations integrations = Integrations();

  /// 1.1.3.5. Integration Health Summary [PD00-CUR-SYS-DEP-HEA].
  @Comment('Overall assessment of integration landscape health')
  IntegrationHealthSummary? healthSummary;
}

/// 1.1.3.1. Internal Dependencies [PD00-CUR-SYS-DEP-INT].
///
/// Dependencies between systems owned and operated internally.
@SectionId('PD00-CUR-SYS-DEP-INT')
class InternalDependencies {
  @ContentType('description', 'Overview of internal system dependencies.')
  @ContentHelp('Describe the overall pattern of internal dependencies. '
      'Identify clusters of tightly coupled systems and potential cascading '
      'failure risks.')
  String? content;

  /// Contains 0+× Internal System Dependency.
  @SectionIdPattern('PD00-CUR-SYS-DEP-INT-xx')
  List<SystemDependencyEntry> items = [];
}

/// 1.1.3.2. External Service Dependencies [PD00-CUR-SYS-DEP-EXT].
///
/// Dependencies on external services, third-party APIs, SaaS platforms,
/// and cloud services not under direct organizational control.
@SectionId('PD00-CUR-SYS-DEP-EXT')
class ExternalServiceDependencies {
  @ContentType('description', 'Overview of external service dependencies '
      'and vendor relationships.')
  @ContentHelp('Describe reliance on external services. Include vendor risk '
      'assessment, contract status, and contingency planning.')
  String? content;

  /// Contains 0+× External Service Dependency.
  @SectionIdPattern('PD00-CUR-SYS-DEP-EXT-xx')
  List<ExternalServiceDependencyEntry> items = [];
}

/// An external service dependency entry (form) [PD00-CUR-SYS-DEP-EXT-nn].
///
/// Documents a dependency on an external service or third-party provider
/// including vendor details, SLA, risk assessment, and fallback options.
class ExternalServiceDependencyEntry {
  @Form([
    Field('serviceName', String, 'External Service Name', required: true),
    Field('serviceProvider', String, 'Service Provider/Vendor'),
    Field('serviceType', String, 'Service Type',
        hint: 'SaaS / PaaS / IaaS / API Service / Data Feed / Payment Gateway / etc.'),
    Field('dependentSystems', String, 'Dependent Internal Systems',
        hint: 'List of internal systems that use this external service'),
    Field('criticality', String, 'Criticality',
        hint: 'Critical / High / Medium / Low'),
    Field('contractStatus', String, 'Contract Status',
        hint: 'Active / Renewal Due / Negotiating / Month-to-Month'),
    Field('contractExpiry', String, 'Contract Expiry Date'),
    Field('slaGuarantee', String, 'SLA Guarantee',
        hint: 'Vendor-provided availability guarantee, e.g., 99.9%'),
    Field('actualAvailability', String, 'Actual Availability',
        hint: 'Measured availability over past period'),
    Field('dataExchanged', String, 'Data Exchanged',
        hint: 'Types of data sent to/received from service'),
    Field('dataResidency', String, 'Data Residency',
        hint: 'Where vendor stores/processes data - relevant for compliance'),
    Field('securityCertifications', String, 'Vendor Security Certifications',
        hint: 'SOC2, ISO 27001, HIPAA, etc.'),
    Field('vendorLockIn', String, 'Vendor Lock-In Risk',
        hint: 'None / Low / Moderate / High / Severe'),
    Field('switchingCost', String, 'Switching Cost',
        hint: 'Estimated effort to migrate to alternative'),
    Field('alternativeProviders', String, 'Alternative Providers',
        hint: 'Known alternatives if migration needed'),
    Field('fallbackProcedure', String, 'Fallback Procedure',
        hint: 'Manual workaround or degraded operation mode'),
    Field('lastOutage', String, 'Last Significant Outage',
        hint: 'Date and impact of last vendor outage'),
    Field('communicationChannel', String, 'Support Communication Channel',
        hint: 'How incidents are reported and tracked'),
  ])
  String? content;

  @Reference('Primary Dependent System')
  ExistingSystemEntry? primaryDependentSystem;
}

/// 1.1.3.3. Shared Infrastructure Dependencies [PD00-CUR-SYS-DEP-SHR].
///
/// Dependencies on shared infrastructure components used by multiple systems.
@SectionId('PD00-CUR-SYS-DEP-SHR')
class SharedInfrastructureDependencies {
  @ContentType('description', 'Overview of shared infrastructure and '
      'cross-cutting dependencies.')
  @ContentHelp('Describe shared infrastructure components (networks, '
      'databases, messaging systems, identity providers) that multiple '
      'systems depend on. Identify single points of failure.')
  String? content;

  /// Contains 0+× Shared Infrastructure Component.
  @SectionIdPattern('PD00-CUR-SYS-DEP-SHR-xx')
  List<SharedInfrastructureEntry> items = [];
}

/// A shared infrastructure entry (form) [PD00-CUR-SYS-DEP-SHR-nn].
///
/// Documents a shared infrastructure component that multiple systems depend on.
class SharedInfrastructureEntry {
  @Form([
    Field('componentName', String, 'Infrastructure Component Name', required: true),
    Field('componentType', String, 'Component Type',
        hint: 'Database Cluster / Message Broker / Load Balancer / '
            'Identity Provider / DNS / Certificate Authority / '
            'Logging Platform / Monitoring System / Network Segment'),
    Field('dependentSystemCount', int, 'Number of Dependent Systems'),
    Field('dependentSystemList', String, 'List of Dependent Systems'),
    Field('criticality', String, 'Criticality',
        hint: 'Critical / High / Medium / Low'),
    Field('singlePointOfFailure', bool, 'Is Single Point of Failure'),
    Field('redundancyLevel', String, 'Redundancy Level',
        hint: 'None / Active-Passive / Active-Active / Multi-Region'),
    Field('failoverTime', String, 'Failover Time (RTO)',
        hint: 'Time to recover if component fails'),
    Field('lastFailure', String, 'Last Failure Incident',
        hint: 'Date and summary of last significant failure'),
    Field('capacityHeadroom', String, 'Capacity Headroom',
        hint: 'Current utilization vs capacity, e.g., 60% of max'),
    Field('scalingLimitations', String, 'Scaling Limitations',
        hint: 'Constraints on horizontal or vertical scaling'),
    Field('managedBy', String, 'Managed By',
        hint: 'Team or vendor responsible for this component'),
    Field('maintenanceWindow', String, 'Maintenance Window',
        hint: 'Regular maintenance schedule'),
    Field('documentationStatus', String, 'Documentation Status',
        hint: 'Current / Outdated / Minimal / None'),
  ])
  String? content;
}

/// 1.1.3.5. Integration Health Summary [PD00-CUR-SYS-DEP-HEA].
///
/// Executive summary of overall integration landscape health and risk areas.
@SectionId('PD00-CUR-SYS-DEP-HEA')
class IntegrationHealthSummary {
  @Form([
    Field('overallHealthRating', String, 'Overall Health Rating',
        hint: 'Healthy / Acceptable / Concerning / Critical'),
    Field('totalDependencies', int, 'Total Dependencies Documented'),
    Field('criticalDependencies', int, 'Critical Dependencies'),
    Field('highRiskDependencies', int, 'High-Risk Dependencies'),
    Field('singlePointsOfFailure', int, 'Identified Single Points of Failure'),
    Field('undocumentedIntegrations', int, 'Known Undocumented Integrations'),
    Field('technicalDebtSummary', String, 'Technical Debt Summary',
        hint: 'Overview of integration-related technical debt'),
    Field('priorityRemediationAreas', String, 'Priority Remediation Areas',
        hint: 'Top 3-5 areas requiring immediate attention'),
    Field('impactOnProject', String, 'Impact on This Project',
        hint: 'How current integration state affects project planning'),
  ])
  String? content;

  /// Fragile integration points requiring attention [PD00-CUR-SYS-DEP-HEA-FRA].
  @ContentType('description', 'Detailed list of fragile integration points '
      'that pose risk to operations or project implementation.')
  @ContentHelp('Document specific integration points that are fragile, '
      'brittle, or at risk of failure. Include rationale and recommendations.')
  String? fragilePoints;
}

/// 1.1.3.4. System Integrations [PD00-CUR-SYS-DEP-SYS].
///
/// Active integrations between systems including protocols, data formats,
/// error handling, and monitoring.
@SectionId('PD00-CUR-SYS-DEP-SYS')
class Integrations {
  @ContentType('description', 'Overview of system integrations and '
      'data exchange patterns.')
  @ContentHelp('Describe the integration patterns in use. Identify '
      'standards vs custom integrations, and areas of complexity.')
  String? content;

  /// Contains 0+× SystemIntegration.
  @SectionIdPattern('PD00-CUR-SYS-DEP-SYS-xx')
  List<SystemIntegrationEntry> items = [];
}

/// A system dependency entry (form) [PD00-CUR-SYS-DEP-INT-nn].
///
/// Documents one dependency between systems in the current landscape:
/// mechanism, coupling strength, data flow, failure impact, SLA,
/// monitoring, and technical debt assessment.
class SystemDependencyEntry {
  @Form([
    Field('dependencyName', String, 'Dependency Name',
        hint: 'Descriptive name, e.g. CRM → ERP order sync',
        required: true),
    Field('dependencyType', String, 'Dependency Type',
        hint: 'Data / Functional / Operational / Temporal / Transactional'),
    Field('direction', String, 'Direction',
        hint: 'Upstream / Downstream / Bidirectional'),
    Field('mechanism', String, 'Dependency Mechanism',
        hint:
            'API / DatabaseLink / FileTransfer / MessageQueue / SharedStorage / Manual / ETL'),
    Field('couplingStrength', String, 'Coupling Strength',
        hint:
            'Tight / Moderate / Loose — degree of coupling between systems'),
    Field('criticality', String, 'Criticality',
        hint: 'Critical / High / Medium / Low'),
    Field('dataExchanged', String, 'Data Exchanged',
        hint:
            'Key data entities or types flowing through this dependency'),
    Field('dataVolume', String, 'Data Volume',
        hint:
            'Typical volume, e.g. ~5k records/day, 200 MB/hour'),
    Field('dataFreshness', String, 'Data Freshness Requirements',
        hint:
            'RealTime / NearRealTime / Hourly / Daily / OnDemand'),
    Field('failureImpact', String, 'Failure Impact',
        hint:
            'What happens when this dependency fails — business consequences'),
    Field('cascadeRisk', String, 'Failure Cascade Risk',
        hint:
            'None / Contained / ModerateCascade / SevereCascade — propagation to other systems'),
    Field('latencyRequirement', String, 'Latency Requirement',
        hint:
            'Maximum acceptable latency, e.g. <500ms, within same business day'),
    Field('availabilityRequirement', String, 'Availability Requirement',
        hint:
            'Required uptime, e.g. 99.9%, business hours only'),
    Field('sla', String, 'SLA',
        hint:
            'Formal SLA reference or key terms, e.g. 4h response, 24h resolution'),
    Field('monitoringStatus', String, 'Monitoring Status',
        hint:
            'Monitored / PartiallyMonitored / Unmonitored'),
    Field('documentationStatus', String, 'Documentation Status',
        hint:
            'Documented / PartiallyDocumented / Undocumented'),
    Field('dependencyOwner', String, 'Dependency Owner',
        hint:
            'Team or role responsible for maintaining this dependency'),
    Field('technicalDebt', String, 'Technical Debt Assessment',
        hint:
            'None / Low / Moderate / High — accumulated technical debt'),
    Field('technicalDebtDetails', String, 'Technical Debt Details',
        hint:
            'Description of known issues, outdated protocols, or maintenance burden'),
    Field('plannedChanges', String, 'Planned Changes',
        hint:
            'Any known upcoming changes to this dependency'),
    Field('fallbackProcedure', String, 'Fallback Procedure',
        hint:
            'Manual or automated fallback when this dependency is unavailable'),
  ])
  String? content;

  @Reference('Source System')
  ExistingSystemEntry? sourceSystem;

  @Reference('Target System')
  ExistingSystemEntry? targetSystem;
}

/// A system integration entry (form) [PD00-CUR-SYS-DEP-INT-nn].
///
/// Documents one integration between systems: type, pattern, protocol,
/// data format, throughput, error handling, monitoring, security,
/// and technical debt.
class SystemIntegrationEntry {
  @Form([
    Field('integrationName', String, 'Integration Name',
        hint: 'Descriptive name, e.g. Real-time inventory sync',
        required: true),
    Field('integrationType', String, 'Integration Type',
        hint:
            'RealTime / Batch / EventDriven / RequestResponse / Manual'),
    Field('integrationPattern', String, 'Integration Pattern',
        hint:
            'PointToPoint / HubSpoke / PubSub / ESB / ApiGateway / EtlPipeline'),
    Field('protocol', String, 'Protocol',
        hint: 'REST / SOAP / gRPC / SFTP / JDBC / AMQP / Kafka / Custom'),
    Field('direction', String, 'Direction',
        hint: 'Inbound / Outbound / Bidirectional'),
    Field('frequency', String, 'Frequency',
        hint:
            'Continuous / Hourly / Daily / Weekly / OnDemand / EventTriggered'),
    Field('middlewareUsed', String, 'Middleware / Platform',
        hint:
            'Integration platform or middleware, e.g. MuleSoft, Azure Service Bus, none'),
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'OAuth2 / APIKey / mTLS / BasicAuth / SAML / None'),
    Field('dataExchanged', String, 'Data Exchanged',
        hint: 'Key data entities or payloads exchanged'),
    Field('messageFormat', String, 'Message Format',
        hint: 'JSON / XML / CSV / Avro / Protobuf / EDI / Custom'),
    Field('schemaVersion', String, 'Schema Version',
        hint:
            'Current schema or API version, e.g. v2.3, 2024-01 schema'),
    Field('transformationRequired', String, 'Transformation Required',
        hint: 'Yes / No — whether data mapping or transformation occurs'),
    Field('dataMappingComplexity', String, 'Data Mapping Complexity',
        hint:
            'Simple / Moderate / Complex — degree of data transformation needed'),
    Field('errorHandling', String, 'Error Handling',
        hint:
            'Retry / DeadLetter / Alert / ManualIntervention — how errors are handled'),
    Field('retryPolicy', String, 'Retry Policy',
        hint:
            'Retry mechanism and limits, e.g. 3 retries with exponential backoff'),
    Field('throughputCapacity', String, 'Throughput Capacity',
        hint:
            'Maximum supported throughput, e.g. 10k msg/sec, 500 records/batch'),
    Field('currentUtilization', String, 'Current Utilization',
        hint: 'Typical load vs capacity, e.g. ~60% of capacity'),
    Field('peakLoadHandling', String, 'Peak Load Handling',
        hint:
            'Scales / Queues / Throttles / Degrades — behavior under peak load'),
    Field('monitoringAlerting', String, 'Monitoring & Alerting',
        hint: 'Monitoring tools and alert thresholds in place'),
    Field('failoverBehavior', String, 'Failover Behavior',
        hint:
            'AutomaticFailover / ManualFailover / NoFailover'),
    Field('integrationAge', String, 'Integration Age',
        hint:
            'When this integration was established, e.g. 2019, 7 years'),
    Field('documentationQuality', String, 'Documentation Quality',
        hint:
            'Comprehensive / Adequate / Minimal / Undocumented'),
    Field('maintenanceOwner', String, 'Maintenance Owner',
        hint: 'Team or role responsible for this integration'),
    Field('securityClassification', String, 'Security Classification',
        hint: 'Public / Internal / Confidential / Restricted'),
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint:
            'Applicable regulations, e.g. PCI-DSS, GDPR data transfer'),
    Field('technicalDebt', String, 'Technical Debt',
        hint:
            'None / Low / Moderate / High — maintenance burden and known issues'),
  ])
  String? content;

  @Reference('Source System')
  ExistingSystemEntry? sourceSystem;

  @Reference('Target System')
  ExistingSystemEntry? targetSystem;
}

// ---------------------------------------------------------------------------
// 1.2 Current Business Processes
// ---------------------------------------------------------------------------

/// 1.2. Current Business Processes [PD00-CUR-PRO].
///
/// Documents the current business processes that the project will impact,
/// replace, or enhance. Understanding existing workflows is critical for
/// gap analysis, migration planning, and ensuring the new system meets
/// operational needs.
@SectionId('PD00-CUR-PRO')
class CurrentBusinessProcesses {
  @ContentType('description', 'Overview of the business process landscape, '
      'including process categories, ownership, and interdependencies.')
  @ContentHelp('Describe the overall process landscape being analyzed. '
      'Focus on workflow bottlenecks, manual steps, and replication of effort. '
      'Include a process map or hierarchy showing how processes relate. '
      'Identify which processes are in scope for this project.')
  String? content;

  /// Process landscape diagram [PD00-CUR-PRO-DIA].
  @SectionId('PD00-CUR-PRO-DIA')
  @ContentType('mermaid-flowchart', 'Visual map of business processes showing '
      'hierarchy, relationships, and data flows between processes')
  @ContentHelp('Create a Mermaid flowchart showing the process landscape. '
      'Group processes by category (Core, Support, Management). '
      'Show handoffs and data flows between processes.')
  String? processLandscapeDiagram;

  /// Process scope summary [PD00-CUR-PRO-SCO].
  @SectionId('PD00-CUR-PRO-SCO')
  @Comment('Defines which processes are in/out of scope')
  ProcessScopeSummary? scopeSummary;

  /// Process interdependency matrix [PD00-CUR-PRO-INT].
  @SectionId('PD00-CUR-PRO-INT')
  @Comment('How processes depend on and interact with each other')
  ProcessInterdependencyMatrix? interdependencyMatrix;

  /// Process performance summary [PD00-CUR-PRO-SUM].
  @SectionId('PD00-CUR-PRO-SUM')
  @Comment('High-level summary of process performance')
  ProcessPerformanceSummary? performanceSummary;

  /// 1.2.nn. Business Processes [PD00-CUR-PRO-nn] — contains 1+× Business Process.
  @SectionIdPattern('PD00-CUR-PRO-xx')
  @Min(1)
  List<CurrentBusinessProcess> processes = [];
}

/// Process scope summary defining in-scope and out-of-scope processes.
class ProcessScopeSummary {
  @Form([
    Field('totalProcessesIdentified', int, 'Total Processes Identified'),
    Field('processesInScope', int, 'Processes In Scope'),
    Field('processesOutOfScope', int, 'Processes Out of Scope'),
    Field('scopeRationale', String, 'Scope Selection Rationale',
        hint: 'Why these processes were selected for analysis'),
    Field('deferredProcesses', String, 'Deferred Processes',
        hint: 'Processes to be addressed in future phases'),
  ])
  String? content;

  /// Processes in scope.
  List<ProcessScopeEntry> inScopeProcesses = [];

  /// Processes explicitly out of scope.
  List<ProcessScopeEntry> outOfScopeProcesses = [];
}

/// A process scope entry indicating in/out of scope status.
class ProcessScopeEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('scopeStatus', String, 'Scope Status',
        hint: 'In-Scope / Out-of-Scope / Deferred / Partial'),
    Field('rationale', String, 'Rationale - why this scope decision'),
    Field('impactIfExcluded', String, 'Impact If Excluded'),
    Field('phase', String, 'Target Phase if deferred'),
  ])
  String? content;
}

/// Process interdependency matrix showing how processes interact.
class ProcessInterdependencyMatrix {
  @ContentType('description', 'Overview of how processes depend on each other.')
  @ContentHelp('Describe the overall pattern of process interdependencies. '
      'Identify critical handoff points and areas of high coupling.')
  String? content;

  /// Interdependency diagram [PD00-CUR-PRO-INT-DIA].
  @SectionId('PD00-CUR-PRO-INT-DIA')
  @ContentType('mermaid-flowchart', 'Visual matrix of process dependencies')
  @ContentHelp('Create a Mermaid flowchart showing process dependencies. '
      'Use edge labels to describe the data/artifact exchanged.')
  String? dependencyDiagram;

  /// Individual process dependencies.
  List<ProcessDependencyEntry> dependencies = [];
}

/// A single process dependency entry.
class ProcessDependencyEntry {
  @Form([
    Field('sourceProcess', String, 'Source Process', required: true),
    Field('targetProcess', String, 'Target Process', required: true),
    Field('dependencyType', String, 'Dependency Type',
        hint: 'Data / Control / Timing / Resource'),
    Field('artifactExchanged', String, 'Artifact/Data Exchanged',
        hint: 'What is passed from source to target'),
    Field('couplingStrength', String, 'Coupling Strength',
        hint: 'Tight / Moderate / Loose'),
    Field('frequency', String, 'Interaction Frequency',
        hint: 'Per transaction / Daily / Weekly / On-demand'),
    Field('timing', String, 'Timing Requirement',
        hint: 'Synchronous / Asynchronous / Batch'),
    Field('failureImpact', String, 'Impact if Dependency Fails'),
  ])
  String? content;
}

/// Process performance summary with high-level metrics.
class ProcessPerformanceSummary {
  @Form([
    Field('overallMaturity', String, 'Overall Process Maturity',
        hint: 'Ad-hoc / Defined / Managed / Optimized'),
    Field('automationLevel', String, 'Automation Level',
        hint: 'Manual / Partially Automated / Highly Automated / Fully Automated'),
    Field('manualStepsCount', int, 'Total Manual Steps Across Processes'),
    Field('errorProneStepsCount', int, 'Error-Prone Steps Identified'),
    Field('bottleneckCount', int, 'Bottlenecks Identified'),
    Field('duplicatedEffortAreas', String, 'Areas of Duplicated Effort',
        hint: 'Processes or steps where work is duplicated'),
    Field('complianceGaps', int, 'Compliance Gaps Identified'),
    Field('estimatedAnnualWaste', String, 'Estimated Annual Waste',
        hint: 'Cost of inefficiencies in time or money'),
  ])
  String? content;

  /// Key metrics summary.
  List<ProcessMetricEntry> keyMetrics = [];
}

/// A current business process [PD00-CUR-PRO-nn].
///
/// Detailed documentation of a single business process including its
/// workflows, actors, metrics, and pain points.
@ContentHelp('Document each business process that the project will impact. '
    'Include process maps (BPMN recommended), actor descriptions, and '
    'quantitative metrics. Identify manual steps and error-prone areas.')
class CurrentBusinessProcess {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('processOwner', String, 'Process Owner'),
    Field('processCategory', String, 'Category (e.g., Core, Support, Management)'),
    Field('processScope', String, 'Scope - organizational units involved'),
    Field('processMaturity', String, 'Maturity Level (e.g., Ad-hoc, Defined, Managed, Optimized)'),
  ])
  String? content;

  /// Process context and purpose.
  ProcessContext processContext = ProcessContext();

  /// 1.2.nn.1. Workflow Descriptions [PD00-CUR-PRO-WOR] — contains 1+× Workflow.
  WorkflowDescriptions workflowDescriptions = WorkflowDescriptions();

  /// 1.2.nn.2. Process Metrics [PD00-CUR-PRO-MET].
  ProcessMetrics processMetrics = ProcessMetrics();

  /// Process pain points and improvement opportunities.
  ProcessPainPoints processPainPoints = ProcessPainPoints();
}

/// Context and purpose of a business process.
@ContentHelp('Describe why this process exists, what business value it delivers, '
    'and how it fits into the overall organizational workflow.')
class ProcessContext {
  @Form([
    Field('businessPurpose', String, 'Business Purpose - why this process exists'),
    Field('businessValue', String, 'Business Value Delivered'),
    Field('regulatoryRequirements', String, 'Regulatory Requirements (compliance drivers)'),
    Field('slaRequirements', String, 'SLA Requirements'),
    Field('upstreamDependencies', String, 'Upstream Dependencies (processes that feed into this one)'),
    Field('downstreamConsumers', String, 'Downstream Consumers (processes that depend on this output)'),
  ])
  String? content;
}

/// Process-specific pain points and improvement opportunities.
class ProcessPainPoints {
  @ContentType('description', 'Known issues, inefficiencies, and improvement '
      'opportunities specific to this process.')
  String? content;

  /// Process improvement opportunities.
  List<ProcessImprovementEntry> improvements = [];
}

/// A process improvement opportunity.
class ProcessImprovementEntry {
  @Form([
    Field('improvementArea', String, 'Improvement Area', required: true),
    Field('currentState', String, 'Current State'),
    Field('desiredState', String, 'Desired State'),
    Field('estimatedBenefit', String, 'Estimated Benefit'),
    Field('implementationEffort', String, 'Implementation Effort (Low/Medium/High)'),
    Field('priority', String, 'Priority (Must-have/Should-have/Nice-to-have)'),
  ])
  String? content;
}

/// 1.2.nn.1. Workflow Descriptions [PD00-CUR-PRO-WOR].
///
/// Container for workflow entries within a business process.
@SectionIdPattern('PD00-CUR-PRO-xx-WOR')
/// 1.2.nn.1. Workflow Descriptions [PD00-CUR-PRO-WOR].
///
/// Container for workflow entries within a business process. Add one
/// subsection per current workflow relevant to the project.
@SectionIdPattern('PD00-CUR-PRO-xx-WOR')
class WorkflowDescriptions {
  @ContentType('description', 'Overview of workflows within this process.')
  @ContentHelp('Describe how the workflows within this process relate to each '
      'other. Identify the primary workflow sequence and exception paths. '
      'Include a workflow diagram showing the sequence and decision points.')
  String? content;

  /// Workflow overview diagram [PD00-CUR-PRO-xx-WOR-DIA].
  @ContentType('mermaid-flowchart', 'Visual overview of all workflows in this '
      'process showing relationships and handoffs')
  @ContentHelp('Create a Mermaid flowchart showing how workflows within this '
      'process interact. Show the primary happy-path and exception branches. '
      'Include decision points and actor swim-lanes if helpful.')
  String? workflowOverviewDiagram;

  /// Workflow summary table [PD00-CUR-PRO-xx-WOR-SUM].
  @Comment('Quick reference summary of all workflows')
  WorkflowSummaryTable? summaryTable;

  /// Individual workflow entries.
  @SectionIdPattern('PD00-CUR-PRO-xx-WOR-xx')
  @Min(1)
  List<CurrentWorkflowEntry> workflows = [];
}

/// Summary table of all workflows for quick reference.
class WorkflowSummaryTable {
  @Form([
    Field('totalWorkflows', int, 'Total Workflows in Process'),
    Field('primaryWorkflows', int, 'Primary/Happy-Path Workflows'),
    Field('exceptionWorkflows', int, 'Exception/Error Handling Workflows'),
    Field('averageCycleTime', String, 'Average Cycle Time Across Workflows'),
    Field('automationPotential', String, 'Overall Automation Potential',
        hint: 'Low / Medium / High / Full'),
  ])
  String? content;

  /// Summary entries per workflow.
  List<WorkflowSummaryEntry> entries = [];
}

/// Summary entry for a single workflow.
class WorkflowSummaryEntry {
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
  String? content;
}

/// A current workflow entry [PD00-CUR-PRO-WOR-nn] (form).
///
/// Detailed documentation of a single workflow within a business process.
/// Includes triggers, steps, actors, inputs, outputs, and timing.
@ContentHelp('Document each workflow with enough detail to understand the '
    'current state and identify improvement opportunities. Include swim-lane '
    'diagrams for complex workflows with multiple actors.')
class CurrentWorkflowEntry {
  @Form([
    Field('workflowName', String, 'Workflow Name', required: true),
    Field('workflowId', String, 'Workflow ID (internal identifier)'),
    Field('workflowType', String, 'Type (e.g., Operational, Approval, Exception)'),
    Field('frequency', String, 'Execution Frequency'),
    Field('averageVolume', String, 'Average Volume per period'),
    Field('criticality', String, 'Business Criticality'),
  ])
  String? content;

  /// Workflow diagram [PD00-CUR-PRO-xx-WOR-xx-DIA].
  @ContentType('mermaid-flowchart', 'Visual representation of this workflow '
      'showing steps, decisions, and actors in a BPMN-style diagram')
  @ContentHelp('Create a Mermaid flowchart or sequence diagram showing the '
      'workflow steps in order. Include decision points with branch conditions. '
      'For multi-actor workflows, use swim-lanes (subgraphs) per actor.')
  String? workflowDiagram;

  /// Workflow triggers and initiation.
  WorkflowTriggers triggers = WorkflowTriggers();

  /// Workflow steps in sequence.
  @SectionIdPattern('PD00-CUR-PRO-xx-WOR-xx-STP-xx')
  List<WorkflowStepEntry> steps = [];

  /// Workflow actors and responsibilities.
  @SectionIdPattern('PD00-CUR-PRO-xx-WOR-xx-ACT-xx')
  List<WorkflowActorEntry> actors = [];

  /// Workflow inputs.
  List<WorkflowInputEntry> inputs = [];

  /// Workflow outputs.
  List<WorkflowOutputEntry> outputs = [];

  /// Decision points within the workflow.
  List<WorkflowDecisionPoint> decisionPoints = [];

  /// Business rules governing the workflow.
  List<WorkflowBusinessRule> businessRules = [];

  /// Manual steps requiring human intervention.
  @ContentHelp('Identify steps that cannot be automated or require human judgment.')
  List<WorkflowStepEntry> manualSteps = [];

  /// Error-prone steps with high failure rates.
  @ContentHelp('Identify steps with known issues, high error rates, or workarounds.')
  List<WorkflowStepEntry> errorProneSteps = [];

  /// Workflow timing and performance.
  WorkflowTiming timing = WorkflowTiming();

  /// Workflow exceptions and error handling.
  WorkflowExceptions exceptions = WorkflowExceptions();
}

/// Workflow triggers and initiation conditions.
class WorkflowTriggers {
  @ContentType('description', 'Conditions that initiate this workflow.')
  String? content;

  /// Trigger entries.
  List<WorkflowTriggerEntry> triggers = [];
}

/// A single workflow trigger.
class WorkflowTriggerEntry {
  @Form([
    Field('triggerName', String, 'Trigger Name', required: true),
    Field('triggerType', String, 'Type (e.g., Event, Schedule, Manual, System)'),
    Field('triggerSource', String, 'Source - origin of the trigger'),
    Field('triggerCondition', String, 'Condition - conditions that must be met'),
    Field('frequency', String, 'Frequency'),
  ])
  String? content;
}

/// A workflow step entry (form) [PD00-CUR-PRO-nn-WOR-nn-STP-nn].
///
/// Detailed documentation of a single step within a workflow.
@ContentHelp('Document each step with enough detail for process analysis and '
    'system design. Include responsible actors, inputs, outputs, and timing.')
class WorkflowStepEntry {
  @Form([
    Field('stepName', String, 'Step Name', required: true),
    Field('stepNumber', int, 'Step Number (sequence order)'),
    Field('description', String, 'Description'),
    Field('responsibleActor', String, 'Responsible Actor'),
    Field('stepType', String, 'Step Type (e.g., Task, Decision, Wait, Subprocess)'),
    Field('isManual', bool, 'Is Manual (requires human intervention)'),
    Field('isAutomatable', bool, 'Is Automatable'),
    Field('averageDuration', String, 'Average Duration'),
  ])
  String? content;

  /// Systems used in this step.
  List<String> systemsUsed = [];

  /// Step inputs.
  List<WorkflowInputEntry> inputs = [];

  /// Step outputs.
  List<WorkflowOutputEntry> outputs = [];

  /// Step-specific business rules.
  List<WorkflowBusinessRule> businessRules = [];

  /// Known issues with this step.
  List<WorkflowStepIssue> knownIssues = [];
}

/// Known issue with a workflow step.
class WorkflowStepIssue {
  @Form([
    Field('issueName', String, 'Issue Name', required: true),
    Field('issueDescription', String, 'Description'),
    Field('frequency', String, 'Frequency of occurrence'),
    Field('impact', String, 'Business Impact'),
    Field('currentWorkaround', String, 'Current Workaround'),
  ])
  String? content;
}

/// A workflow actor entry (form) [PD00-CUR-PRO-nn-WOR-nn-ACT-nn].
///
/// Documentation of a participant in the workflow.
@ContentHelp('Document all actors including their roles, responsibilities, '
    'authorization levels, and involvement pattern.')
class WorkflowActorEntry {
  @Form([
    Field('actorName', String, 'Actor Name', required: true),
    Field('actorType', String, 'Actor Type (e.g., Role, System, Department, External)'),
    Field('role', String, 'Role in this workflow'),
    Field('responsibilities', String, 'Responsibilities'),
    Field('authorizationLevel', String, 'Authorization Level'),
    Field('availabilityRequirements', String, 'Availability Requirements'),
    Field('skillRequirements', String, 'Skill Requirements'),
    Field('headcount', int, 'Headcount (number of people in this role)'),
  ])
  String? content;

  /// Steps this actor participates in.
  @Reference('Participating Steps')
  List<WorkflowStepEntry> participatingSteps = [];
}

/// A workflow input.
class WorkflowInputEntry {
  @Form([
    Field('inputName', String, 'Input Name', required: true),
    Field('inputType', String, 'Type (data type or document type)'),
    Field('source', String, 'Source'),
    Field('format', String, 'Format (e.g., PDF, XML, Manual Entry)'),
    Field('isRequired', bool, 'Is Required'),
    Field('validationRules', String, 'Validation Rules'),
  ])
  String? content;
}

/// A workflow output.
class WorkflowOutputEntry {
  @Form([
    Field('outputName', String, 'Output Name', required: true),
    Field('outputType', String, 'Type (data type or document type)'),
    Field('destination', String, 'Destination'),
    Field('format', String, 'Format'),
    Field('retentionRequirements', String, 'Retention Requirements'),
  ])
  String? content;
}

/// A decision point within a workflow.
class WorkflowDecisionPoint {
  @Form([
    Field('decisionName', String, 'Decision Name', required: true),
    Field('decisionCriteria', String, 'Decision Criteria'),
    Field('decisionMaker', String, 'Decision Maker'),
    Field('outcomes', String, 'Possible Outcomes (comma-separated)'),
    Field('escalationPath', String, 'Escalation Path'),
    Field('slaForDecision', String, 'SLA for Decision'),
  ])
  String? content;
}

/// A business rule governing workflow behavior.
class WorkflowBusinessRule {
  @Form([
    Field('ruleName', String, 'Rule Name', required: true),
    Field('ruleDescription', String, 'Description'),
    Field('ruleLogic', String, 'Rule Logic (business logic in plain language)'),
    Field('ruleSource', String, 'Source (e.g., Policy, Regulation, SOP)'),
    Field('exceptions', String, 'Exceptions - when this rule does not apply'),
  ])
  String? content;
}

/// Workflow timing and performance characteristics.
class WorkflowTiming {
  @Form([
    Field('startToEndTime', String, 'Start-to-End Time (total elapsed)'),
    Field('processingTime', String, 'Processing Time (active work time)'),
    Field('waitTime', String, 'Wait Time'),
    Field('slaTarget', String, 'SLA Target'),
    Field('slaMet', String, 'SLA Compliance Rate'),
    Field('peakPeriods', String, 'Peak Periods (times of highest volume)'),
    Field('bottlenecks', String, 'Bottlenecks (steps causing delays)'),
  ])
  String? content;
}

/// Workflow exception handling.
class WorkflowExceptions {
  @ContentType('description', 'How exceptions are handled in this workflow.')
  String? content;

  /// Exception entries.
  List<WorkflowExceptionEntry> exceptions = [];
}

/// A workflow exception type.
class WorkflowExceptionEntry {
  @Form([
    Field('exceptionName', String, 'Exception Name', required: true),
    Field('exceptionType', String, 'Type (e.g., Validation, System, Business)'),
    Field('frequency', String, 'Frequency'),
    Field('handlingProcedure', String, 'Handling Procedure'),
    Field('escalationPath', String, 'Escalation Path'),
    Field('recoveryTime', String, 'Recovery Time'),
  ])
  String? content;
}

/// 1.2.2. Process Metrics [PD00-CUR-PRO-MET].
///
/// Quantitative metrics for measuring process performance.
@SectionIdPattern('PD00-CUR-PRO-xx-MET')
@ContentHelp('Define measurable metrics that capture current process performance. '
    'These metrics will serve as the baseline for measuring improvement.')
class ProcessMetrics {
  @ContentType('description', 'Overview of process metrics and measurement approach.')
  String? content;

  /// Efficiency metrics.
  ProcessMetricCategory efficiencyMetrics = ProcessMetricCategory();

  /// Quality metrics.
  ProcessMetricCategory qualityMetrics = ProcessMetricCategory();

  /// Volume metrics.
  ProcessMetricCategory volumeMetrics = ProcessMetricCategory();

  /// Cost metrics.
  ProcessMetricCategory costMetrics = ProcessMetricCategory();

  /// Individual metric entries.
  @SectionIdPattern('PD00-CUR-PRO-xx-MET-xx')
  List<ProcessMetricEntry> items = [];
}

/// A category of process metrics.
class ProcessMetricCategory {
  @ContentType('description', 'Category-level summary of metrics.')
  String? content;

  /// Metrics in this category.
  List<ProcessMetricEntry> metrics = [];
}

/// A process metric entry (form) [PD00-CUR-PRO-nn-MET-nn].
///
/// A single measurable metric with current value and measurement details.
@ContentHelp('Define each metric clearly with current baseline values, '
    'measurement methodology, and target values if known.')
class ProcessMetricEntry {
  @Form([
    Field('metricName', String, 'Metric Name', required: true),
    Field('metricId', String, 'Metric ID'),
    Field('metricCategory', String, 'Category (e.g., Efficiency, Quality, Volume, Cost)'),
    Field('currentValue', String, 'Current Value'),
    Field('unit', String, 'Unit'),
    Field('targetValue', String, 'Target Value'),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('dataSource', String, 'Data Source'),
    Field('frequency', String, 'Measurement Frequency'),
    Field('trend', String, 'Trend (Improving, Stable, Declining)'),
    Field('benchmark', String, 'Industry Benchmark'),
  ])
  String? content;

  @Reference('Process Reference')
  CurrentBusinessProcess? processReference;
}

// ---------------------------------------------------------------------------
// 1.3 Pain Points and Gaps
// ---------------------------------------------------------------------------

/// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
@SectionId('PD00-CUR-PAI')
class PainPointsAndGaps {
  @Unused()
  String? content;

  /// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
  OperationalPainPoints operationalPainPoints = OperationalPainPoints();

  /// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
  BusinessPainPoints businessPainPoints = BusinessPainPoints();

  /// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
  TechnicalPainPoints technicalPainPoints = TechnicalPainPoints();

  /// 1.3.4. Gaps [PD00-CUR-PAI-GAP].
  Gaps gaps = Gaps();
}

/// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
@SectionId('PD00-CUR-PAI-OPE')
class OperationalPainPoints {
  @Unused()
  String? content;

  /// Contains 0+× PainPoint.
  @SectionIdPattern('PD00-CUR-PAI-OPE-xx')
  List<PainPointEntry> items = [];
}

/// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
@SectionId('PD00-CUR-PAI-BUS')
class BusinessPainPoints {
  @Unused()
  String? content;

  /// Contains 0+× PainPoint.
  @SectionIdPattern('PD00-CUR-PAI-BUS-xx')
  List<PainPointEntry> items = [];
}

/// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
@SectionId('PD00-CUR-PAI-TEC')
class TechnicalPainPoints {
  @Unused()
  String? content;

  /// Contains 0+× PainPoint.
  @SectionIdPattern('PD00-CUR-PAI-TEC-xx')
  List<PainPointEntry> items = [];
}

/// A pain point entry (form) [PD00-CUR-PAI-nn].
class PainPointEntry {
  @Form([
    Field('painPoint', String, 'Pain Point', required: true),
    Field('description', String, 'Short description'),
    Field('impact', String, 'Impact assessment'),
    Field('affectedProcess', String, 'Affected Process'),
    Field('severity', String, 'Severity level'),
    Field('workaround', String, 'Current workaround'),
  ])
  String? content;
}

/// 1.3.4. Gaps [PD00-CUR-PAI-GAP].
@SectionId('PD00-CUR-PAI-GAP')
class Gaps {
  @Unused()
  String? content;

  /// Contains 0+× Gap.
  @SectionIdPattern('PD00-CUR-PAI-GAP-xx')
  List<GapEntry> items = [];
}

/// A gap entry (form) — a missing capability or feature [PD00-CUR-PAI-GAP-nn].
///
/// Documents a specific gap between current capabilities and business needs:
/// category, severity, quantified cost, stakeholders, compliance drivers,
/// workarounds, resolution approach, and success criteria.
class GapEntry {
  @Form([
    Field('gapName', String, 'Gap Name',
        hint: 'Concise name for the identified gap', required: true),
    Field('description', String, 'Description',
        hint: 'Detailed description of what is missing or inadequate'),
    Field('gapCategory', String, 'Gap Category',
        hint:
            'Functional / Process / Data / Integration / Compliance / Security / Performance / Usability'),
    Field('severity', String, 'Severity',
        hint: 'Critical / High / Medium / Low'),
    Field('priority', String, 'Priority',
        hint: 'MustAddress / ShouldAddress / NiceToHave'),
    Field('businessImpact', String, 'Business Impact',
        hint:
            'How this gap affects business outcomes, revenue, or operations'),
    Field('quantifiedCost', String, 'Quantified Cost of Gap',
        hint:
            'Estimated annual cost or productivity loss, e.g. ~€120k/year in manual processing'),
    Field('affectedProcess', String, 'Affected Process',
        hint: 'Primary business process impacted by this gap'),
    Field('affectedStakeholders', String, 'Affected Stakeholders',
        hint:
            'Roles, departments, or external parties impacted'),
    Field('complianceDriver', String, 'Regulatory/Compliance Driver',
        hint:
            'Regulation or standard making this gap critical, e.g. GDPR Art. 17, SOX Section 404'),
    Field('discoveryMethod', String, 'Discovery Method',
        hint:
            'Audit / UserFeedback / Incident / ProcessReview / Benchmarking / RegulatoryChange'),
    Field('gapAge', String, 'Gap Age',
        hint:
            'How long this gap has been known, e.g. Since 2023-Q2, 18 months'),
    Field('validationStatus', String, 'Validation Status',
        hint: 'Identified / Confirmed / Quantified / Accepted'),
    Field('relatedPainPoints', String, 'Related Pain Points',
        hint:
            'References to pain point entries that stem from this gap'),
    Field('interimWorkaround', String, 'Interim Workaround',
        hint: 'Current workaround in place and its limitations'),
    Field('workaroundCost', String, 'Workaround Cost',
        hint:
            'Cost or effort of maintaining the workaround, e.g. 2 FTE hours/week'),
    Field('riskIfNotAddressed', String, 'Risk if Not Addressed',
        hint:
            'Consequences and risk level if gap remains unresolved'),
    Field('proposedResolution', String, 'Proposed Resolution',
        hint: 'High-level approach to closing the gap'),
    Field('expectedTimeline', String, 'Expected Resolution Timeline',
        hint:
            'Target timeframe, e.g. Phase 1 — Q3 2026, 6-9 months'),
    Field('successCriteria', String, 'Success Criteria',
        hint:
            'Measurable criteria that confirm the gap is closed'),
    Field('dependsOnGaps', String, 'Depends on Other Gaps',
        hint:
            'Other gaps that must be resolved first, by name or ID'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 1.4 Current Data Landscape
// ---------------------------------------------------------------------------

/// 1.4. Current Data Landscape [PD00-CUR-DAT].
@SectionId('PD00-CUR-DAT')
class CurrentDataLandscape {
  @Unused()
  String? content;

  /// 1.4.1. Data Source Inventory [PD00-CUR-DAT-SRC] — contains 0+× DataSource.
  @SectionIdPattern('PD00-CUR-DAT-SRC-xx')
  List<DataSourceEntry> dataSources = [];

  /// Data Quality Assessment.
  TextSection dataQualityAssessment = TextSection();
}

/// A data source entry combining store, format, volume, and quality (form) [PD00-CUR-DAT-SRC-nn].
class DataSourceEntry {
  @Form([
    Field('dataStoreName', String, 'Data Store Name', required: true),
    Field('storeType', String, 'Store Type'),
    Field('technology', String, 'Technology'),
    Field('dataFormat', String, 'Data Format'),
    Field('estimatedVolume', String, 'Estimated Volume'),
    Field('growthRate', String, 'Growth Rate'),
    Field('qualityLevel', String, 'Quality Level'),
    Field('owner', String, 'Owner'),
  ])
  String? content;

  /// Retention Policy.
  TextSection retentionPolicy = TextSection();
}
