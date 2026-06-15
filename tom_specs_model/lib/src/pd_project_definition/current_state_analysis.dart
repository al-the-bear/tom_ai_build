/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 1. Current State Analysis [PD00-CUR]. Seeds → CS.
///
/// Seeds the CS (Current Situation) Phase 3 DocSpec. Previously listed as
/// PD-only; its subtree now flows to CS together with PD00-SYO-SYR.
@SectionId('CUSA')
@MapsTo(CurrentSituation)
class CurrentStateAnalysis {
  @ContentHelp('''
Executive summary of the current state: existing systems landscape, business
processes today, known pain points, current data landscape, operational
metrics, and risks tied to the current state or to replacement. Seeds the CS
document alongside the PD00-SYO-SYR replacement inventory.
''')
  String? content;

  /// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
  ExistingSystemsLandscape existingSystemsLandscape = ExistingSystemsLandscape();

  /// 1.2. Current Business Processes [PD00-CUR-PRO].
  CurrentBusinessProcesses currentBusinessProcesses = CurrentBusinessProcesses();

  /// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// 1.4. Current Data Landscape [PD00-CUR-DAT].
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();

  /// 1.5. Operational Metrics [PD00-CUR-MET].
  @SectionId('CUOPME-OPER-LST')
  @SectionIdPattern('CUOPME-OPER-xxx')
  List<CurrentOperationalMetrics> operationalMetrics = [];

  /// 1.6. Current State Risks [PD00-CUR-RIS].
  CurrentStateRiskAssessment currentStateRisks = CurrentStateRiskAssessment();
}

// ---------------------------------------------------------------------------
// 1.1 Existing Systems Landscape
// ---------------------------------------------------------------------------

/// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
///
/// Overview of the current systems in use, their roles, technology stacks,
/// and limitations. Provides the foundation for understanding the AS-IS state.
@SectionId('ESLAN')
@DetailedIn(CurrentSituation)
@SecondLevelSectionId(CurrentSituation, 'CS-SYS')
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
@SectionId('SYINV')
class SystemInventory {
  @ContentType('description', 'Introduction to the system inventory. '
      'Describe the criteria for including systems and the overall landscape.')
  String? content;

  /// Contains 1+× Existing System [PD00-CUR-SYS-INV-nn].
  @SectionId('ESENT-SYST-LST')
  @SectionIdPattern('ESENT-SYST-xxx')
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
@SectionId('CARCH')
class CurrentArchitecture {
  String? content;

  /// Architecture overview diagram [PD00-CUR-SYS-ARC-DIA].
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
  @SectionId('INTEG1-INTE-LST')
  @SectionIdPattern('INTEG1-INTE-xxx')
  List<IntegrationPatternEntry> integrationPatterns = [];

  /// Shared services inventory [PD00-CUR-SYS-ARC-SHR].
  @SectionId('SHARE-SHAR-LST')
  @SectionIdPattern('SHARE-SHAR-xxx')
  List<SharedServiceEntry> sharedServices = [];
}

/// An existing system entry [PD00-CUR-SYS-INV-nn] (form).
///
/// Captures comprehensive information about an existing system including
/// identity, technology, business context, usage metrics, lifecycle, and risks.
@SectionId('ESENT')
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
  @SectionId('LIMET-KNOW-LST')
  @SectionIdPattern('LIMET-KNOW-xxx')
  @ContentHelp('Document each known limitation with its impact on current '
      'operations and any workarounds in place.')
  List<LimitationEntry> knownLimitations = [];

  /// Quality and risk assessment [PD00-CUR-SYS-INV-nn-QUA].
  @Comment('Quality and risk')
  ExistingSystemQuality? quality;
}

/// Technology stack details for an existing system.
@SectionId('ESTEC')
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
@SectionId('ESBCT')
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
@SectionId('ESUSG')
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
@SectionId('ESLCY')
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
@SectionId('ESINT')
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
@SectionId('ESINF')
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
@SectionId('ESQUA')
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
@SectionId('LIMET')
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
@SectionId('DEPNT')
class DependenciesAndIntegrations {
  String? content;

  /// Dependency matrix diagram [PD00-CUR-SYS-DEP-DIA].
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
@SectionId('INTDP')
class InternalDependencies {
  @ContentType('description', 'Overview of internal system dependencies.')
  @ContentHelp('Describe the overall pattern of internal dependencies. '
      'Identify clusters of tightly coupled systems and potential cascading '
      'failure risks.')
  String? content;

  /// Contains 0+× Internal System Dependency.
  @SectionId('SYDE-ITEM-LST')
  @SectionIdPattern('SYDE-ITEM-xxx')
  List<SystemDependencyEntry> items = [];
}

/// 1.1.3.2. External Service Dependencies [PD00-CUR-SYS-DEP-EXT].
///
/// Dependencies on external services, third-party APIs, SaaS platforms,
/// and cloud services not under direct organizational control.
@SectionId('EXTDP')
class ExternalServiceDependencies {
  @ContentType('description', 'Overview of external service dependencies '
      'and vendor relationships.')
  @ContentHelp('Describe reliance on external services. Include vendor risk '
      'assessment, contract status, and contingency planning.')
  String? content;

  /// Contains 0+× External Service Dependency.
  @SectionId('EXSDE-ITEM-LST')
  @SectionIdPattern('EXSDE-ITEM-xxx')
  List<ExternalServiceDependencyEntry> items = [];
}

/// An external service dependency entry (form) [PD00-CUR-SYS-DEP-EXT-nn].
///
/// Documents a dependency on an external service or third-party provider
/// including vendor details, SLA, risk assessment, and fallback options.
@SectionId('EXSDE')
class ExternalServiceDependencyEntry {
  @Form([
    Field('serviceName', String, 'External Service Name', required: true),
    Field('serviceProvider', String, 'Service Provider/Vendor'),
    Field('serviceType', String, 'Service Type',
        hint: 'SaaS / PaaS / IaaS / API Service / Data Feed / Payment Gateway / etc.'),
  ])
  String? content;

  /// Internal dependency and contract details.
  ExternalServiceDependencyEntryRelationship relationship =
      ExternalServiceDependencyEntryRelationship();

  /// Availability and data handling details.
  ExternalServiceDependencyEntryOperations operations =
      ExternalServiceDependencyEntryOperations();

  /// Risk and fallback considerations.
  ExternalServiceDependencyEntryRisk risk =
      ExternalServiceDependencyEntryRisk();

  @Reference('Primary Dependent System')
  ExistingSystemEntry? primaryDependentSystem;
}

/// Internal dependency and contract details.
@SectionId('EXSRL')
class ExternalServiceDependencyEntryRelationship {
  @Form([
    Field('dependentSystems', String, 'Dependent Internal Systems',
        hint: 'List of internal systems that use this external service'),
    Field('criticality', String, 'Criticality',
        hint: 'Critical / High / Medium / Low'),
    Field('contractStatus', String, 'Contract Status',
        hint: 'Active / Renewal Due / Negotiating / Month-to-Month'),
    Field('contractExpiry', String, 'Contract Expiry Date'),
  ])
  String? content;
}

/// Availability and data handling details.
@SectionId('EXSOP')
class ExternalServiceDependencyEntryOperations {
  @Form([
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
  ])
  String? content;
}

/// Risk and fallback considerations.
@SectionId('EXSRK')
class ExternalServiceDependencyEntryRisk {
  @Form([
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
}

/// 1.1.3.3. Shared Infrastructure Dependencies [PD00-CUR-SYS-DEP-SHR].
///
/// Dependencies on shared infrastructure components used by multiple systems.
@SectionId('SHDEP')
class SharedInfrastructureDependencies {
  @ContentType('description', 'Overview of shared infrastructure and '
      'cross-cutting dependencies.')
  @ContentHelp('Describe shared infrastructure components (networks, '
      'databases, messaging systems, identity providers) that multiple '
      'systems depend on. Identify single points of failure.')
  String? content;

  /// Contains 0+× Shared Infrastructure Component.
  @SectionId('SHIEN-ITEM-LST')
  @SectionIdPattern('SHIEN-ITEM-xxx')
  List<SharedInfrastructureEntry> items = [];
}

/// A shared infrastructure entry (form) [PD00-CUR-SYS-DEP-SHR-nn].
///
/// Documents a shared infrastructure component that multiple systems depend on.
@SectionId('SHIEN')
class SharedInfrastructureEntry {
  @Form([
    Field('componentName', String, 'Infrastructure Component Name', required: true),
    Field('componentType', String, 'Component Type',
        hint: 'Database Cluster / Message Broker / Load Balancer / '
            'Identity Provider / DNS / Certificate Authority / '
            'Logging Platform / Monitoring System / Network Segment'),
    Field('dependentSystemCount', int, 'Number of Dependent Systems'),
    Field('dependentSystemList', String, 'List of Dependent Systems'),
  ])
  String? content;

  /// Criticality and resilience.
  SharedInfrastructureEntryResilience resilience =
      SharedInfrastructureEntryResilience();

  /// Capacity constraints.
  SharedInfrastructureEntryCapacity capacity =
      SharedInfrastructureEntryCapacity();

  /// Ownership and maintenance.
  SharedInfrastructureEntryOperations operations =
      SharedInfrastructureEntryOperations();
}

/// Criticality and resilience.
@SectionId('SIER')
class SharedInfrastructureEntryResilience {
  @Form([
    Field('criticality', String, 'Criticality',
        hint: 'Critical / High / Medium / Low'),
    Field('singlePointOfFailure', bool, 'Is Single Point of Failure'),
    Field('redundancyLevel', String, 'Redundancy Level',
        hint: 'None / Active-Passive / Active-Active / Multi-Region'),
    Field('failoverTime', String, 'Failover Time (RTO)',
        hint: 'Time to recover if component fails'),
    Field('lastFailure', String, 'Last Failure Incident',
        hint: 'Date and summary of last significant failure'),
  ])
  String? content;
}

/// Capacity constraints.
@SectionId('SIEC')
class SharedInfrastructureEntryCapacity {
  @Form([
    Field('capacityHeadroom', String, 'Capacity Headroom',
        hint: 'Current utilization vs capacity, e.g., 60% of max'),
    Field('scalingLimitations', String, 'Scaling Limitations',
        hint: 'Constraints on horizontal or vertical scaling'),
  ])
  String? content;
}

/// Ownership and maintenance.
@SectionId('SIEO')
class SharedInfrastructureEntryOperations {
  @Form([
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
@SectionId('INHESU')
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
  @SectionId('FRAGI-FRAG-LST')
  @SectionIdPattern('FRAGI-FRAG-xxx')
  List<FragilePointEntry> fragilePoints = [];
}

/// 1.1.3.4. System Integrations [PD00-CUR-SYS-DEP-SYS].
///
/// Active integrations between systems including protocols, data formats,
/// error handling, and monitoring.
@SectionId('INTEGR')
class Integrations {
  @ContentType('description', 'Overview of system integrations and '
      'data exchange patterns.')
  @ContentHelp('Describe the integration patterns in use. Identify '
      'standards vs custom integrations, and areas of complexity.')
  String? content;

  /// Contains 0+× SystemIntegration.
  @SectionId('SYIN-ITEM-LST')
  @SectionIdPattern('SYIN-ITEM-xxx')
  List<SystemIntegrationEntry> items = [];
}

/// A system dependency entry (form) [PD00-CUR-SYS-DEP-INT-nn].
///
/// Documents one dependency between systems in the current landscape:
/// mechanism, coupling strength, data flow, failure impact, SLA,
/// monitoring, and technical debt assessment.
@SectionId('SYDE')
class SystemDependencyEntry {
  @Form([
    Field('dependencyName', String, 'Dependency Name',
        hint: 'Descriptive name, e.g. CRM → ERP order sync',
        required: true),
    Field('dependencyType', String, 'Dependency Type',
        hint: 'Data / Functional / Operational / Temporal / Transactional'),
    Field('direction', String, 'Direction',
        hint: 'Upstream / Downstream / Bidirectional'),
  ])
  String? content;

  /// Mechanism and coupling.
  SystemDependencyEntryMechanism mechanism = SystemDependencyEntryMechanism();

  /// Data exchange characteristics.
  SystemDependencyEntryDataExchange dataExchange =
      SystemDependencyEntryDataExchange();

  /// Reliability and SLA.
  SystemDependencyEntryReliability reliability =
      SystemDependencyEntryReliability();

  /// Operations and documentation.
  SystemDependencyEntryOperations operations =
      SystemDependencyEntryOperations();

  @Reference('Source System')
  ExistingSystemEntry? sourceSystem;

  @Reference('Target System')
  ExistingSystemEntry? targetSystem;
}

/// Mechanism and coupling for system dependency.
@SectionId('SDEM')
class SystemDependencyEntryMechanism {
  @Form([
    Field('mechanism', String, 'Dependency Mechanism',
        hint: 'API / DatabaseLink / FileTransfer / MessageQueue / SharedStorage / Manual / ETL'),
    Field('couplingStrength', String, 'Coupling Strength',
        hint: 'Tight / Moderate / Loose — degree of coupling between systems'),
    Field('criticality', String, 'Criticality',
        hint: 'Critical / High / Medium / Low'),
  ])
  String? content;
}

/// Data exchange characteristics for system dependency.
@SectionId('SDEDE')
class SystemDependencyEntryDataExchange {
  @Form([
    Field('dataExchanged', String, 'Data Exchanged',
        hint: 'Key data entities or types flowing through this dependency'),
    Field('dataVolume', String, 'Data Volume',
        hint: 'Typical volume, e.g. ~5k records/day, 200 MB/hour'),
    Field('dataFreshness', String, 'Data Freshness Requirements',
        hint: 'RealTime / NearRealTime / Hourly / Daily / OnDemand'),
  ])
  String? content;
}

/// Reliability and SLA for system dependency.
@SectionId('SDER')
class SystemDependencyEntryReliability {
  @Form([
    Field('failureImpact', String, 'Failure Impact',
        hint: 'What happens when this dependency fails — business consequences'),
    Field('cascadeRisk', String, 'Failure Cascade Risk',
        hint: 'None / Contained / ModerateCascade / SevereCascade — propagation to other systems'),
    Field('latencyRequirement', String, 'Latency Requirement',
        hint: 'Maximum acceptable latency, e.g. <500ms, within same business day'),
    Field('availabilityRequirement', String, 'Availability Requirement',
        hint: 'Required uptime, e.g. 99.9%, business hours only'),
    Field('sla', String, 'SLA',
        hint: 'Formal SLA reference or key terms, e.g. 4h response, 24h resolution'),
    Field('fallbackProcedure', String, 'Fallback Procedure',
        hint: 'Manual or automated fallback when this dependency is unavailable'),
  ])
  String? content;
}

/// Operations and documentation for system dependency.
@SectionId('SDEO')
class SystemDependencyEntryOperations {
  @Form([
    Field('monitoringStatus', String, 'Monitoring Status',
        hint: 'Monitored / PartiallyMonitored / Unmonitored'),
    Field('documentationStatus', String, 'Documentation Status',
        hint: 'Documented / PartiallyDocumented / Undocumented'),
    Field('dependencyOwner', String, 'Dependency Owner',
        hint: 'Team or role responsible for maintaining this dependency'),
    Field('technicalDebt', String, 'Technical Debt Assessment',
        hint: 'None / Low / Moderate / High — accumulated technical debt'),
    Field('technicalDebtDetails', String, 'Technical Debt Details',
        hint: 'Description of known issues, outdated protocols, or maintenance burden'),
    Field('plannedChanges', String, 'Planned Changes',
        hint: 'Any known upcoming changes to this dependency'),
  ])
  String? content;
}

/// A system integration entry (form) [PD00-CUR-SYS-DEP-INT-nn].
///
/// Documents one integration between systems: type, pattern, protocol,
/// data format, throughput, error handling, monitoring, security,
/// and technical debt.
@SectionId('SYIN')
class SystemIntegrationEntry {
  @Form([
    Field('integrationName', String, 'Integration Name',
        hint: 'Descriptive name, e.g. Real-time inventory sync',
        required: true),
    Field('integrationType', String, 'Integration Type',
        hint: 'RealTime / Batch / EventDriven / RequestResponse / Manual'),
    Field('integrationPattern', String, 'Integration Pattern',
        hint: 'PointToPoint / HubSpoke / PubSub / ESB / ApiGateway'),
  ])
  String? content;

  /// Protocol and transport details.
  final SystemIntegrationProtocol protocol = SystemIntegrationProtocol();

  /// Data exchange configuration.
  final SystemIntegrationDataExchange dataExchange =
      SystemIntegrationDataExchange();

  /// Error handling and retry.
  final SystemIntegrationErrorHandling errorHandling =
      SystemIntegrationErrorHandling();

  /// Throughput and capacity.
  final SystemIntegrationThroughput throughput = SystemIntegrationThroughput();

  /// Monitoring and failover.
  final SystemIntegrationMonitoring monitoring =
      SystemIntegrationMonitoring();

  /// Ownership and documentation.
  final SystemIntegrationOwnership ownership = SystemIntegrationOwnership();

  @Reference('Source System')
  ExistingSystemEntry? sourceSystem;

  @Reference('Target System')
  ExistingSystemEntry? targetSystem;
}

/// Protocol and transport details.
@SectionId('SYINPR')
class SystemIntegrationProtocol {
  @Form([
    Field('protocol', String, 'Protocol',
        hint: 'REST / SOAP / gRPC / SFTP / JDBC / AMQP / Kafka / Custom'),
    Field('direction', String, 'Direction',
        hint: 'Inbound / Outbound / Bidirectional'),
    Field('frequency', String, 'Frequency',
        hint: 'Continuous / Hourly / Daily / Weekly / OnDemand'),
    Field('middlewareUsed', String, 'Middleware / Platform',
        hint: 'MuleSoft, Azure Service Bus, none'),
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'OAuth2 / APIKey / mTLS / BasicAuth / SAML / None'),
  ])
  String? content;
}

/// Data exchange configuration.
@SectionId('SIDE')
class SystemIntegrationDataExchange {
  @Form([
    Field('dataExchanged', String, 'Data Exchanged',
        hint: 'Key data entities or payloads exchanged'),
    Field('messageFormat', String, 'Message Format',
        hint: 'JSON / XML / CSV / Avro / Protobuf / EDI / Custom'),
    Field('schemaVersion', String, 'Schema Version',
        hint: 'Current schema or API version'),
    Field('transformationRequired', String, 'Transformation Required',
        hint: 'Yes / No'),
    Field('dataMappingComplexity', String, 'Data Mapping Complexity',
        hint: 'Simple / Moderate / Complex'),
  ])
  String? content;
}

/// Error handling and retry.
@SectionId('SIEH')
class SystemIntegrationErrorHandling {
  @Form([
    Field('errorHandling', String, 'Error Handling',
        hint: 'Retry / DeadLetter / Alert / ManualIntervention'),
    Field('retryPolicy', String, 'Retry Policy',
        hint: '3 retries with exponential backoff'),
  ])
  String? content;
}

/// Throughput and capacity.
@SectionId('SYINTH')
class SystemIntegrationThroughput {
  @Form([
    Field('throughputCapacity', String, 'Throughput Capacity',
        hint: '10k msg/sec, 500 records/batch'),
    Field('currentUtilization', String, 'Current Utilization',
        hint: 'Typical load vs capacity'),
    Field('peakLoadHandling', String, 'Peak Load Handling',
        hint: 'Scales / Queues / Throttles / Degrades'),
  ])
  String? content;
}

/// Monitoring and failover.
@SectionId('SYINMO')
class SystemIntegrationMonitoring {
  @Form([
    Field('monitoringAlerting', String, 'Monitoring & Alerting',
        hint: 'Monitoring tools and alert thresholds'),
    Field('failoverBehavior', String, 'Failover Behavior',
        hint: 'AutomaticFailover / ManualFailover / NoFailover'),
  ])
  String? content;
}

/// Ownership and documentation.
@SectionId('SYINOW')
class SystemIntegrationOwnership {
  @Form([
    Field('integrationAge', String, 'Integration Age',
        hint: 'When established, e.g. 2019, 7 years'),
    Field('documentationQuality', String, 'Documentation Quality',
        hint: 'Comprehensive / Adequate / Minimal / Undocumented'),
    Field('maintenanceOwner', String, 'Maintenance Owner',
        hint: 'Team or role responsible'),
    Field('securityClassification', String, 'Security Classification',
        hint: 'Public / Internal / Confidential / Restricted'),
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint: 'PCI-DSS, GDPR data transfer'),
    Field('technicalDebt', String, 'Technical Debt',
        hint: 'None / Low / Moderate / High'),
  ])
  String? content;
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
@SectionId('CUBUPR')
@DetailedIn(CurrentSituation)
@SecondLevelSectionId(CurrentSituation, 'CS-PRO')
class CurrentBusinessProcesses {
  String? content;

  /// Process landscape diagram [PD00-CUR-PRO-DIA].
  @ContentType('mermaid-flowchart', 'Visual map of business processes showing '
      'hierarchy, relationships, and data flows between processes')
  @ContentHelp('Create a Mermaid flowchart showing the process landscape. '
      'Group processes by category (Core, Support, Management). '
      'Show handoffs and data flows between processes.')
  String? processLandscapeDiagram;

  /// Process scope summary [PD00-CUR-PRO-SCO].
  @Comment('Defines which processes are in/out of scope')
  ProcessScopeSummary? scopeSummary;

  /// Process interdependency matrix [PD00-CUR-PRO-INT].
  @Comment('How processes depend on and interact with each other')
  ProcessInterdependencyMatrix? interdependencyMatrix;

  /// Process performance summary [PD00-CUR-PRO-SUM].
  @Comment('High-level summary of process performance')
  ProcessPerformanceSummary? performanceSummary;

  /// 1.2.nn. Business Processes [PD00-CUR-PRO-nn] — contains 1+× Business Process.
  @SectionId('CUBIPR-PROC-LST')
  @SectionIdPattern('CUBIPR-PROC-xxx')
  @Min(1)
  List<CurrentBusinessProcess> processes = [];
}

/// Process scope summary defining in-scope and out-of-scope processes.
@SectionId('PRSCSU')
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
  @SectionId('PRSCEN-INSC-LST')
  @SectionIdPattern('PRSCEN-INSC-xxx')
  List<ProcessScopeEntry> inScopeProcesses = [];

  /// Processes explicitly out of scope.
  @SectionId('PRSCEN-OUTO-LST')
  @SectionIdPattern('PRSCEN-OUTO-xxx')
  List<ProcessScopeEntry> outOfScopeProcesses = [];
}

/// A process scope entry indicating in/out of scope status.
@SectionId('PRSCEN')
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
@SectionId('PRINMA')
class ProcessInterdependencyMatrix {
  String? content;

  /// Interdependency diagram [PD00-CUR-PRO-INT-DIA].
  @ContentType('mermaid-flowchart', 'Visual matrix of process dependencies')
  @ContentHelp('Create a Mermaid flowchart showing process dependencies. '
      'Use edge labels to describe the data/artifact exchanged.')
  String? dependencyDiagram;

  /// Individual process dependencies.
  @SectionId('PRDEEN-DEPE-LST')
  @SectionIdPattern('PRDEEN-DEPE-xxx')
  List<ProcessDependencyEntry> dependencies = [];
}

/// A single process dependency entry.
@SectionId('PRDEEN')
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
@SectionId('PRPESU')
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
  @SectionId('PME-KEYM-LST')
  @SectionIdPattern('PME-KEYM-xxx')
  List<ProcessMetricEntry> keyMetrics = [];
}

/// A current business process [PD00-CUR-PRO-nn].
///
/// Detailed documentation of a single business process including its
/// workflows, actors, metrics, and pain points.
@ContentHelp('Document each business process that the project will impact. '
    'Include process maps (BPMN recommended), actor descriptions, and '
    'quantitative metrics. Identify manual steps and error-prone areas.')
@SectionId('CUBIPR')
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
@SectionId('PC')
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
@SectionId('PRPAPO')
class ProcessPainPoints {
  @ContentType('description', 'Known issues, inefficiencies, and improvement '
      'opportunities specific to this process.')
  String? content;

  /// Process improvement opportunities.
  @SectionId('CPIE-IMPR-LST')
  @SectionIdPattern('CPIE-IMPR-xxx')
    List<CurrentProcessImprovementEntry> improvements = [];
}

/// A process improvement opportunity.
@SectionId('CPIE')
class CurrentProcessImprovementEntry {
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
/// 1.2.nn.1. Workflow Descriptions [PD00-CUR-PRO-WOR].
///
/// Container for workflow entries within a business process. Add one
/// subsection per current workflow relevant to the project.
@SectionId('WODE')
class WorkflowDescriptions {
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
  @SectionId('CUWF-WORK-LST')
  @SectionIdPattern('CUWF-WORK-xxx')
  @Min(1)
  List<CurrentWorkflowEntry> workflows = [];
}

/// Summary table of all workflows for quick reference.
@SectionId('WOSUTA')
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
  @SectionId('WOSUEN-ENTR-LST')
  @SectionIdPattern('WOSUEN-ENTR-xxx')
  List<WorkflowSummaryEntry> entries = [];
}

/// Summary entry for a single workflow.
@SectionId('WOSUEN')
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
@SectionId('CUWF')
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
  @SectionId('WSE-STEP-LST')
  @SectionIdPattern('WSE-STEP-xxx')
  List<WorkflowStepEntry> steps = [];

  /// Workflow actors and responsibilities.
  @SectionId('WFAC-ACTO-LST')
  @SectionIdPattern('WFAC-ACTO-xxx')
  List<WorkflowActorEntry> actors = [];

  /// Workflow inputs.
  @SectionId('WOINEN-INPU-LST')
  @SectionIdPattern('WOINEN-INPU-xxx')
  List<WorkflowInputEntry> inputs = [];

  /// Workflow outputs.
  @SectionId('WOOUEN-OUTP-LST')
  @SectionIdPattern('WOOUEN-OUTP-xxx')
  List<WorkflowOutputEntry> outputs = [];

  /// Decision points within the workflow.
  @SectionId('WODEPO-DECI-LST')
  @SectionIdPattern('WODEPO-DECI-xxx')
  List<WorkflowDecisionPoint> decisionPoints = [];

  /// Business rules governing the workflow.
  @SectionId('WOBURU-BUSI-LST')
  @SectionIdPattern('WOBURU-BUSI-xxx')
  List<WorkflowBusinessRule> businessRules = [];

  /// Manual steps requiring human intervention.
  @SectionId('WSE-MANU-LST')
  @SectionIdPattern('WSE-MANU-xxx')
  @ContentHelp('Identify steps that cannot be automated or require human judgment.')
  List<WorkflowStepEntry> manualSteps = [];

  /// Error-prone steps with high failure rates.
  @SectionId('WSE-ERRO-LST')
  @SectionIdPattern('WSE-ERRO-xxx')
  @ContentHelp('Identify steps with known issues, high error rates, or workarounds.')
  List<WorkflowStepEntry> errorProneSteps = [];

  /// Workflow timing and performance.
  WorkflowTiming timing = WorkflowTiming();

  /// Workflow exceptions and error handling.
  WorkflowExceptions exceptions = WorkflowExceptions();
}

/// Workflow triggers and initiation conditions.
@SectionId('WOTR')
class WorkflowTriggers {
  @ContentType('description', 'Conditions that initiate this workflow.')
  String? content;

  /// Trigger entries.
  @SectionId('WOTREN-TRIG-LST')
  @SectionIdPattern('WOTREN-TRIG-xxx')
  List<WorkflowTriggerEntry> triggers = [];
}

/// A single workflow trigger.
@SectionId('WOTREN')
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

/// A system used in a workflow step.
@SectionId('WOSTSY')
class WorkflowStepSystem {
  @ContentHelp('Name of the system used in this workflow step.')
  String? name;
}

/// A workflow step entry (form) [PD00-CUR-PRO-nn-WOR-nn-STP-nn].
///
/// Detailed documentation of a single step within a workflow.
@ContentHelp('Document each step with enough detail for process analysis and '
    'system design. Include responsible actors, inputs, outputs, and timing.')
@SectionId('WSE')
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
  @SectionId('WOSTSY-SYST-LST')
  @SectionIdPattern('WOSTSY-SYST-xxx')
  List<WorkflowStepSystem> systemsUsed = [];

  /// Step inputs.
  @SectionId('WOINEN-INPU-LST')
  @SectionIdPattern('WOINEN-INPU-xxx')
  List<WorkflowInputEntry> inputs = [];

  /// Step outputs.
  @SectionId('WOOUEN-OUTP-LST')
  @SectionIdPattern('WOOUEN-OUTP-xxx')
  List<WorkflowOutputEntry> outputs = [];

  /// Step-specific business rules.
  @SectionId('WOBURU-BUSI-LST')
  @SectionIdPattern('WOBURU-BUSI-xxx')
  List<WorkflowBusinessRule> businessRules = [];

  /// Known issues with this step.
  @SectionId('WOSTIS-KNOW-LST')
  @SectionIdPattern('WOSTIS-KNOW-xxx')
  List<WorkflowStepIssue> knownIssues = [];
}

/// Known issue with a workflow step.
@SectionId('WOSTIS')
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
@SectionId('WAE')
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
@SectionId('WOINEN')
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
@SectionId('WOOUEN')
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
@SectionId('WODEPO')
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
@SectionId('WOBURU')
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
@SectionId('WOTI')
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
@SectionId('WOEX')
class WorkflowExceptions {
  @ContentType('description', 'How exceptions are handled in this workflow.')
  String? content;

  /// Exception entries.
  @SectionId('WOEXEN-EXCE-LST')
  @SectionIdPattern('WOEXEN-EXCE-xxx')
  List<WorkflowExceptionEntry> exceptions = [];
}

/// A workflow exception type.
@SectionId('WOEXEN')
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
/// Quantitative metrics for measuring process performance. These metrics
/// form the baseline against which improvements will be measured.
@ContentHelp('Document current process performance including throughput, '
    'cycle times, error rates, and manual intervention frequency. '
    'These become the baseline against which improvements are measured.')
@SectionId('PM')
class ProcessMetrics {
  @ContentType('description', 'Overview of process metrics and measurement approach.')
  @ContentHelp('Describe the overall approach to measuring process performance. '
      'Include data collection methods, measurement periods, and data quality notes.')
  String? content;

  /// Metrics dashboard summary [PD00-CUR-PRO-xx-MET-SUM].
  @Comment('Executive summary of key metrics')
  MetricsDashboardSummary? dashboardSummary;

  /// Efficiency metrics [PD00-CUR-PRO-xx-MET-EFF].
  @SectionId('PRMECA-EFFI-LST')
  @SectionIdPattern('PRMECA-EFFI-xxx')
  @Comment('Throughput, cycle times, utilization')
  List<ProcessMetricCategory> efficiencyMetrics = [];

  /// Quality metrics [PD00-CUR-PRO-xx-MET-QUA].
  @SectionId('PRMECA-QUAL-LST')
  @SectionIdPattern('PRMECA-QUAL-xxx')
  @Comment('Error rates, defect rates, rework rates')
  List<ProcessMetricCategory> qualityMetrics = [];

  /// Volume metrics [PD00-CUR-PRO-xx-MET-VOL].
  @SectionId('PRMECA-VOLU-LST')
  @SectionIdPattern('PRMECA-VOLU-xxx')
  @Comment('Transaction counts, throughput volumes')
  List<ProcessMetricCategory> volumeMetrics = [];

  /// Cost metrics [PD00-CUR-PRO-xx-MET-COS].
  @SectionId('PRMECA-COST-LST')
  @SectionIdPattern('PRMECA-COST-xxx')
  @Comment('Cost per transaction, resource costs')
  List<ProcessMetricCategory> costMetrics = [];

  /// Manual intervention metrics [PD00-CUR-PRO-xx-MET-MAN].
  @SectionId('PRMECA-MANU-LST')
  @SectionIdPattern('PRMECA-MANU-xxx')
  @Comment('Manual steps, human intervention frequency')
  List<ProcessMetricCategory> manualInterventionMetrics = [];

  /// Individual metric entries.
  @SectionId('PME-ITEM-LST')
  @SectionIdPattern('PME-ITEM-xxx')
  List<ProcessMetricEntry> items = [];

  /// Baseline comparison table [PD00-CUR-PRO-xx-MET-BAS].
  @Comment('Summary table for baseline tracking')
  MetricsBaselineTable? baselineTable;
}

/// Metrics dashboard summary for executive overview.
@SectionId('MEDASU')
class MetricsDashboardSummary {
  @Form([
    Field('measurementPeriod', String, 'Measurement Period',
        hint: 'Time period covered by these metrics, e.g., Q1 2024'),
    Field('dataQuality', String, 'Data Quality Assessment',
        hint: 'High / Medium / Low - confidence in metric accuracy'),
    Field('keyThroughput', String, 'Key Throughput Metric',
        hint: 'Primary volume metric, e.g., 5000 orders/day'),
    Field('averageCycleTime', String, 'Average Cycle Time',
        hint: 'End-to-end processing time, e.g., 4.2 hours'),
    Field('overallErrorRate', String, 'Overall Error Rate',
        hint: 'Combined error rate, e.g., 3.2%'),
    Field('manualInterventionRate', String, 'Manual Intervention Rate',
        hint: 'Percentage of cases requiring manual handling'),
    Field('processEfficiency', String, 'Process Efficiency',
        hint: 'Value-add time vs total time ratio'),
    Field('capacityUtilization', String, 'Capacity Utilization',
        hint: 'Current volume vs maximum capacity'),
    Field('complianceRate', String, 'SLA/Compliance Rate',
        hint: 'Percentage meeting SLA targets'),
    Field('trendSummary', String, 'Overall Trend',
        hint: 'Improving / Stable / Declining'),
  ])
  String? content;
}

/// Baseline table for tracking metrics over time.
@SectionId('MEBATA')
class MetricsBaselineTable {
  @ContentType('description', 'Baseline tracking approach and comparison periods.')
  @ContentHelp('Document how baseline metrics will be used to measure improvement. '
      'Include comparison periods and target improvement percentages.')
  String? content;

  /// Baseline entries.
  @SectionId('MEBAEN-ENTR-LST')
  @SectionIdPattern('MEBAEN-ENTR-xxx')
  List<MetricsBaselineEntry> entries = [];
}

/// A baseline entry for tracking metric changes.
@SectionId('MEBAEN')
class MetricsBaselineEntry {
  @Form([
    Field('metricName', String, 'Metric Name', required: true),
    Field('baselineValue', String, 'Baseline Value (current state)'),
    Field('baselineDate', String, 'Baseline Date'),
    Field('targetValue', String, 'Target Value'),
    Field('targetDate', String, 'Target Date'),
    Field('improvementTarget', String, 'Improvement Target',
        hint: 'Percentage or absolute improvement expected'),
    Field('trackingFrequency', String, 'Tracking Frequency',
        hint: 'How often this metric will be re-measured'),
  ])
  String? content;
}

/// A category of process metrics.
@SectionId('PRMECA')
class ProcessMetricCategory {
  @ContentType('description', 'Category-level summary of metrics.')
  String? content;

  /// Metrics in this category.
  @SectionId('PME-METR-LST')
  @SectionIdPattern('PME-METR-xxx')
  List<ProcessMetricEntry> metrics = [];
}

/// A process metric entry (form) [PD00-CUR-PRO-nn-MET-nn].
///
/// A single measurable metric with current value and measurement details.
@ContentHelp('Define each metric clearly with current baseline values, '
    'measurement methodology, and target values if known.')
@SectionId('PME')
class ProcessMetricEntry {
  @Form([
    Field('metricName', String, 'Metric Name', required: true),
    Field('metricId', String, 'Metric ID'),
    Field('metricCategory', String, 'Category (e.g., Efficiency, Quality, Volume, Cost)'),
    Field('currentValue', String, 'Current Value'),
    Field('unit', String, 'Unit'),
  ])
  String? content;

    /// Measurement collection details.
    ProcessMetricEntryMeasurement measurement = ProcessMetricEntryMeasurement();

    /// Target setting and benchmarking context.
    ProcessMetricEntryTargets targets = ProcessMetricEntryTargets();

  @Reference('Process Reference')
  CurrentBusinessProcess? processReference;
}

/// Measurement collection details.
@SectionId('PMEM')
class ProcessMetricEntryMeasurement {
    @Form([
        Field('measurementMethod', String, 'Measurement Method'),
        Field('dataSource', String, 'Data Source'),
        Field('frequency', String, 'Measurement Frequency'),
    ])
    String? content;
}

/// Target setting and benchmarking context.
@SectionId('PMET')
class ProcessMetricEntryTargets {
    @Form([
        Field('targetValue', String, 'Target Value'),
        Field('trend', String, 'Trend (Improving, Stable, Declining)'),
        Field('benchmark', String, 'Industry Benchmark'),
    ])
    String? content;
}

// ---------------------------------------------------------------------------
// 1.3 Pain Points and Gaps
// ---------------------------------------------------------------------------

/// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
///
/// Comprehensive documentation of specific problems, inefficiencies,
/// compliance gaps, and user frustrations in the current state.
/// Each pain point includes business impact quantification and root cause.
@SectionId('PPAG')
@DetailedIn(CurrentSituation)
@SecondLevelSectionId(CurrentSituation, 'CS-PAI')
class PainPointsAndGaps {
  @ContentHelp('''
Executive overview of pain points and gaps in the current state.
Summarize the most critical issues affecting operations, business outcomes,
and technical capabilities. Highlight interdependencies between pain points.
''')
  String? content;

  /// Visual mapping of pain points and their relationships.
  @ContentType('mermaid-flowchart', 'Diagram showing pain point categories, '
      'relationships, and impact flow between operational, business, '
      'and technical pain points')
  String? painPointsOverviewDiagram;

  /// Pain points priority matrix (urgency vs impact).
  @ContentType('mermaid', 'Quadrant chart mapping pain points by urgency and '
      'impact dimensions to guide prioritization decisions')
  String? painPointsPriorityMatrix;

  /// Summary statistics for all pain points.
  PainPointsSummary painPointsSummary = PainPointsSummary();

  /// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
  OperationalPainPoints operationalPainPoints = OperationalPainPoints();

  /// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
  BusinessPainPoints businessPainPoints = BusinessPainPoints();

  /// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
  TechnicalPainPoints technicalPainPoints = TechnicalPainPoints();

  /// 1.3.4. Gaps [PD00-CUR-PAI-GAP].
  Gaps gaps = Gaps();

  /// Cross-reference between pain points and gaps.
  PainPointGapCorrelation painPointGapCorrelation = PainPointGapCorrelation();
}

/// Summary statistics and metrics for all pain points.
@SectionId('PAPOSU')
class PainPointsSummary {
  @Form([
    Field('totalPainPoints', int, 'Total Pain Points',
        hint: 'Total number of documented pain points across all categories'),
    Field('criticalCount', int, 'Critical Count',
        hint: 'Number of pain points rated as critical severity'),
    Field('highCount', int, 'High Severity Count',
        hint: 'Number of pain points rated as high severity'),
    Field('mediumCount', int, 'Medium Severity Count',
        hint: 'Number of pain points rated as medium severity'),
    Field('lowCount', int, 'Low Severity Count',
        hint: 'Number of pain points rated as low severity'),
    Field('totalEstimatedAnnualCost', String, 'Total Estimated Annual Cost',
        hint: 'Aggregate annual cost of all documented pain points, e.g. €850k/year'),
    Field('totalProductivityLoss', String, 'Total Productivity Loss',
        hint: 'Aggregate productivity loss, e.g. 120 FTE hours/month'),
    Field('mostAffectedProcess', String, 'Most Affected Process',
        hint: 'Business process with the highest concentration of pain points'),
    Field('mostAffectedStakeholder', String, 'Most Affected Stakeholder Group',
        hint: 'User role or department most impacted by pain points'),
    Field('averageResolutionComplexity', String, 'Average Resolution Complexity',
        hint: 'Low / Medium / High / Very High'),
  ])
  String? content;
}

/// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
///
/// Problems that affect day-to-day operations: downtime, slow response,
/// data inconsistencies, manual workarounds, and process interruptions.
@SectionId('OPPAPO')
class OperationalPainPoints {
  @ContentHelp('''
Overview of operational pain points affecting day-to-day activities.
Include patterns of recurring issues, seasonal variations, and dependencies
on specific systems or personnel.
''')
  String? content;

  /// Category-level summary for operational pain points.
  OperationalPainPointsSummary categorySummary = OperationalPainPointsSummary();

  /// Contains 0+× PainPoint.
  @SectionId('PAPE-ITEM-LST')
  @SectionIdPattern('PAPE-ITEM-xxx')
  List<PainPointEntry> items = [];
}

/// Summary specific to operational pain points.
@SectionId('OPPS')
class OperationalPainPointsSummary {
  @Form([
    Field('averageDowntimePerMonth', String, 'Average Downtime per Month',
        hint: 'Total system/process downtime, e.g. 4.5 hours/month'),
    Field('manualWorkaroundsCount', int, 'Number of Manual Workarounds',
        hint: 'Count of documented manual workarounds in use'),
    Field('dataInconsistencyFrequency', String, 'Data Inconsistency Frequency',
        hint: 'How often data inconsistencies occur, e.g. Daily / Weekly / Monthly'),
    Field('criticalProcessesAffected', int, 'Critical Processes Affected',
        hint: 'Number of critical business processes impacted'),
    Field('staffOverhead', String, 'Staff Overhead for Workarounds',
        hint: 'FTE hours spent on operational workarounds, e.g. 40 hours/week'),
  ])
  String? content;
}

/// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
///
/// Problems that affect business outcomes: lost revenue, compliance risk,
/// customer dissatisfaction, inability to scale, and missed opportunities.
@SectionId('BUPAPO')
class BusinessPainPoints {
  @ContentHelp('''
Overview of business pain points affecting strategic outcomes and growth.
Include revenue impact, compliance exposure, customer retention effects,
and competitive positioning concerns.
''')
  String? content;

  /// Category-level summary for business pain points.
  BusinessPainPointsSummary categorySummary = BusinessPainPointsSummary();

  /// Contains 0+× PainPoint.
  @SectionId('PAPE-ITEM-LST')
  @SectionIdPattern('PAPE-ITEM-xxx')
  List<PainPointEntry> items = [];
}

/// Summary specific to business pain points.
@SectionId('BPPS')
class BusinessPainPointsSummary {
  @Form([
    Field('estimatedRevenueLoss', String, 'Estimated Annual Revenue Loss',
        hint: 'Revenue lost due to business pain points, e.g. €250k/year'),
    Field('complianceRiskExposure', String, 'Compliance Risk Exposure',
        hint: 'Potential regulatory penalties or fines, e.g. up to €500k'),
    Field('customerSatisfactionImpact', String, 'Customer Satisfaction Impact',
        hint: 'NPS or CSAT impact, e.g. -15 NPS points'),
    Field('marketShareImpact', String, 'Market Share Impact',
        hint: 'Estimated market share loss, e.g. 2-3% market share'),
    Field('missedOpportunitiesCost', String, 'Missed Opportunities Cost',
        hint: 'Revenue from opportunities not pursued, e.g. €400k/year'),
    Field('scalabilityConstraints', String, 'Scalability Constraints',
        hint: 'Growth limitations, e.g. Cannot support >10k concurrent users'),
  ])
  String? content;
}

/// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
///
/// Problems that affect development and maintenance: outdated technology,
/// security vulnerabilities, lack of documentation, vendor lock-in,
/// and technical debt.
@SectionId('TEPAPO')
class TechnicalPainPoints {
  @ContentHelp('''
Overview of technical pain points affecting system development, maintenance,
and evolution. Include technology obsolescence risks, security posture,
integration complexity, and team capability constraints.
''')
  String? content;

  /// Category-level summary for technical pain points.
  TechnicalPainPointsSummary categorySummary = TechnicalPainPointsSummary();

  /// Contains 0+× PainPoint.
  @SectionId('PAPE-ITEM-LST')
  @SectionIdPattern('PAPE-ITEM-xxx')
  List<PainPointEntry> items = [];
}

/// Summary specific to technical pain points.
@SectionId('TPPS')
class TechnicalPainPointsSummary {
  @Form([
    Field('technicalDebtEstimate', String, 'Technical Debt Estimate',
        hint: 'Estimated cost to address technical debt, e.g. €1.2M or 18 months'),
    Field('securityVulnerabilityCount', int, 'Known Security Vulnerabilities',
        hint: 'Number of documented security vulnerabilities'),
    Field('criticalSecurityIssues', int, 'Critical Security Issues',
        hint: 'Number of critical/high severity security vulnerabilities'),
    Field('systemsAtEndOfLife', int, 'Systems at End of Life',
        hint: 'Number of systems using unsupported or EOL technology'),
    Field('undocumentedSystems', int, 'Undocumented Systems',
        hint: 'Number of systems with inadequate documentation'),
    Field('vendorLockInRisk', String, 'Vendor Lock-in Risk Level',
        hint: 'Low / Medium / High — based on proprietary dependencies'),
    Field('integrationComplexityScore', String, 'Integration Complexity Score',
        hint: 'Overall integration complexity, e.g. High (47 point-to-point integrations)'),
  ])
  String? content;
}

/// A pain point entry (form) [PD00-CUR-PAI-nn].
///
/// Documents a specific problem in the current state with comprehensive details:
/// root cause analysis, impact quantification, affected stakeholders,
/// current workarounds, and proposed resolution approach.
@SectionId('PAPE')
class PainPointEntry {
  @Form([
    Field('painPointId', String, 'Pain Point ID',
        hint: 'Unique identifier, e.g. PP-OPE-001', required: true),
    Field('painPoint', String, 'Pain Point Name',
        hint: 'Concise name for the pain point', required: true),
    Field('severity', String, 'Severity',
        hint: 'Critical / High / Medium / Low'),
  ])
  String? content;

  /// Classification.
  final PainPointClassification classification = PainPointClassification();

  /// Root cause analysis.
  final PainPointRootCause rootCause = PainPointRootCause();

  /// Impact assessment.
  final PainPointImpact impact = PainPointImpact();

  /// Evidence and validation.
  final PainPointEvidence evidence = PainPointEvidence();

  /// Current state and workarounds.
  final PainPointWorkaround workaround = PainPointWorkaround();

  /// Resolution planning.
  final PainPointResolution resolution = PainPointResolution();

  /// Relationships.
  @SectionId('PAPOR1-RELA-LST')
  @SectionIdPattern('PAPOR1-RELA-xxx')
  List<PainPointRelationships> relationships = [];
}

/// Classification for pain point.
@SectionId('PAPOCL')
class PainPointClassification {
  @Form([
    Field('description', String, 'Description',
        hint: 'Detailed description of the problem'),
    Field('category', String, 'Category',
        hint: 'Operational / Business / Technical'),
    Field('subCategory', String, 'Sub-Category',
        hint: 'E.g. Performance / DataQuality / Usability'),
    Field('urgency', String, 'Urgency',
        hint: 'Immediate / ShortTerm / MediumTerm / LongTerm'),
    Field('priority', String, 'Resolution Priority',
        hint: 'P1-Critical / P2-High / P3-Medium / P4-Low'),
  ])
  String? content;
}

/// Root cause for pain point.
@SectionId('PPRC')
class PainPointRootCause {
  @Form([
    Field('rootCause', String, 'Root Cause',
        hint: 'Underlying cause of the pain point'),
    Field('rootCauseCategory', String, 'Root Cause Category',
        hint: 'Process / Technology / People / Data / Integration / External'),
    Field('contributingFactors', String, 'Contributing Factors',
        hint: 'Additional factors that exacerbate the problem'),
  ])
  String? content;
}

/// Impact assessment for pain point.
@SectionId('PAPOIM')
class PainPointImpact {
  @Form([
    Field('affectedProcess', String, 'Affected Process',
        hint: 'Primary business process impacted'),
    Field('affectedSystems', String, 'Affected Systems',
        hint: 'Systems involved or causing the pain point'),
    Field('affectedStakeholders', String, 'Affected Stakeholders',
        hint: 'User roles, departments, or external parties impacted'),
    Field('userCount', int, 'Number of Users Affected',
        hint: 'Approximate count of users experiencing this issue'),
    Field('frequency', String, 'Frequency of Occurrence',
        hint: 'Continuous / Daily / Weekly / Monthly / Sporadic'),
    Field('businessImpact', String, 'Business Impact',
        hint: 'Description of impact on business outcomes'),
    Field('quantifiedCost', String, 'Quantified Annual Cost',
        hint: 'Estimated annual cost, e.g. €75k/year'),
    Field('productivityLoss', String, 'Productivity Loss',
        hint: 'Time lost per occurrence, e.g. 30 min/occurrence'),
  ])
  String? content;
}

/// Evidence for pain point.
@SectionId('PAPOEV')
class PainPointEvidence {
  @Form([
    Field('discoveryMethod', String, 'Discovery Method',
        hint: 'UserFeedback / Incident / Audit / ProcessReview'),
    Field('dateIdentified', String, 'Date Identified',
        hint: 'When the pain point was first documented'),
    Field('validationStatus', String, 'Validation Status',
        hint: 'Identified / Confirmed / Quantified / RootCauseAnalyzed'),
    Field('evidenceSources', String, 'Evidence Sources',
        hint: 'Data sources supporting this pain point'),
    Field('incidentReferences', String, 'Related Incidents',
        hint: 'References to specific incidents'),
  ])
  String? content;
}

/// Workaround for pain point.
@SectionId('PAPOWO')
class PainPointWorkaround {
  @Form([
    Field('currentWorkaround', String, 'Current Workaround',
        hint: 'How users currently work around this issue'),
    Field('workaroundEffectiveness', String, 'Workaround Effectiveness',
        hint: 'None / Poor / Partial / Adequate'),
    Field('workaroundCost', String, 'Workaround Cost',
        hint: 'Cost of maintaining the workaround'),
    Field('riskIfNotAddressed', String, 'Risk if Not Addressed',
        hint: 'Consequences of leaving the pain point unresolved'),
  ])
  String? content;
}

/// Resolution for pain point.
@SectionId('PAPORE')
class PainPointResolution {
  @Form([
    Field('proposedResolution', String, 'Proposed Resolution',
        hint: 'High-level approach to resolve the pain point'),
    Field('resolutionComplexity', String, 'Resolution Complexity',
        hint: 'Low / Medium / High / VeryHigh'),
    Field('estimatedResolutionEffort', String, 'Estimated Resolution Effort',
        hint: 'Time or cost to resolve'),
    Field('expectedBenefit', String, 'Expected Benefit',
        hint: 'Quantified benefit after resolution'),
    Field('successCriteria', String, 'Success Criteria',
        hint: 'How to measure that the pain point is resolved'),
  ])
  String? content;
}

/// Relationships for pain point.
@SectionId('PAPOR1')
class PainPointRelationships {
  @Form([
    Field('relatedPainPoints', String, 'Related Pain Points',
        hint: 'IDs of related pain points'),
    Field('relatedGaps', String, 'Related Gaps',
        hint: 'Gap entries that this pain point stems from'),
    Field('dependsOn', String, 'Depends On',
        hint: 'Other pain points that must be resolved first'),
  ])
  String? content;
}

/// Cross-reference analysis between pain points and gaps.
@SectionId('PPGC')
class PainPointGapCorrelation {
  @ContentHelp('''
Analysis of relationships between documented pain points and capability gaps.
Shows which gaps cause which pain points, and which pain points indicate
underlying gaps that may not be explicitly documented.
''')
  String? content;

  /// Visual correlation between pain points and gaps.
  @ContentType('mermaid', 'Diagram showing cause-effect relationships '
      'between capability gaps and resulting pain points')
  String? correlationDiagram;

  /// Tabular correlation data.
  @Min(1)
  @SectionId('PPGCE-CORR-LST')
  @SectionIdPattern('PPGCE-CORR-xxx')
  List<PainPointGapCorrelationEntry> correlationEntries = [];
}

/// Individual pain point to gap correlation entry.
@SectionId('PPGCE')
class PainPointGapCorrelationEntry {
  @Form([
    Field('painPointId', String, 'Pain Point ID',
        hint: 'Reference to pain point, e.g. PP-OPE-001', required: true),
    Field('gapId', String, 'Gap ID',
        hint: 'Reference to gap entry, e.g. GAP-001', required: true),
    Field('correlationType', String, 'Correlation Type',
        hint: 'CausedBy / ContributesTo / IndicatesGap / Exacerbates'),
    Field('correlationStrength', String, 'Correlation Strength',
        hint: 'Direct / Strong / Moderate / Weak'),
    Field('notes', String, 'Notes',
        hint: 'Additional context on the relationship'),
  ])
  String? content;
}

/// 1.3.4. Gaps [PD00-CUR-PAI-GAP].
@SectionId('GAPS')
class Gaps {
  @Unused()
  String? content;

  /// Contains 0+× Gap.
  @SectionId('GAPE-ITEM-LST')
  @SectionIdPattern('GAPE-ITEM-xxx')
  List<GapEntry> items = [];
}

/// A gap entry (form) — a missing capability or feature [PD00-CUR-PAI-GAP-nn].
///
/// Documents a specific gap between current capabilities and business needs:
/// category, severity, quantified cost, stakeholders, compliance drivers,
/// workarounds, resolution approach, and success criteria.
@SectionId('GAPE')
class GapEntry {
  @Form([
    Field('gapName', String, 'Gap Name',
        hint: 'Concise name for the identified gap', required: true),
    Field('gapCategory', String, 'Gap Category',
        hint: 'Functional / Process / Data / Integration / Compliance / Security / Performance / Usability'),
    Field('severity', String, 'Severity',
        hint: 'Critical / High / Medium / Low'),
  ])
  String? content;

  /// Gap description and business impact.
  GapEntryDescription description = GapEntryDescription();

  /// Discovery and validation.
  GapEntryDiscovery discovery = GapEntryDiscovery();

  /// Current workarounds.
  GapEntryWorkaround workaround = GapEntryWorkaround();

  /// Resolution planning.
  GapEntryResolution resolution = GapEntryResolution();
}

/// Gap description and business impact.
@SectionId('GAENDE')
class GapEntryDescription {
  @Form([
    Field('description', String, 'Description',
        hint: 'Detailed description of what is missing or inadequate'),
    Field('priority', String, 'Priority',
        hint: 'MustAddress / ShouldAddress / NiceToHave'),
    Field('businessImpact', String, 'Business Impact',
        hint: 'How this gap affects business outcomes, revenue, or operations'),
    Field('quantifiedCost', String, 'Quantified Cost of Gap',
        hint: 'Estimated annual cost or productivity loss, e.g. ~€120k/year in manual processing'),
    Field('affectedProcess', String, 'Affected Process',
        hint: 'Primary business process impacted by this gap'),
    Field('affectedStakeholders', String, 'Affected Stakeholders',
        hint: 'Roles, departments, or external parties impacted'),
  ])
  String? content;
}

/// Discovery and validation for gap.
@SectionId('GAENDI')
class GapEntryDiscovery {
  @Form([
    Field('complianceDriver', String, 'Regulatory/Compliance Driver',
        hint: 'Regulation or standard making this gap critical, e.g. GDPR Art. 17, SOX Section 404'),
    Field('discoveryMethod', String, 'Discovery Method',
        hint: 'Audit / UserFeedback / Incident / ProcessReview / Benchmarking / RegulatoryChange'),
    Field('gapAge', String, 'Gap Age',
        hint: 'How long this gap has been known, e.g. Since 2023-Q2, 18 months'),
    Field('validationStatus', String, 'Validation Status',
        hint: 'Identified / Confirmed / Quantified / Accepted'),
    Field('relatedPainPoints', String, 'Related Pain Points',
        hint: 'References to pain point entries that stem from this gap'),
  ])
  String? content;
}

/// Current workarounds for gap.
@SectionId('GAENWO')
class GapEntryWorkaround {
  @Form([
    Field('interimWorkaround', String, 'Interim Workaround',
        hint: 'Current workaround in place and its limitations'),
    Field('workaroundCost', String, 'Workaround Cost',
        hint: 'Cost or effort of maintaining the workaround, e.g. 2 FTE hours/week'),
    Field('riskIfNotAddressed', String, 'Risk if Not Addressed',
        hint: 'Consequences and risk level if gap remains unresolved'),
  ])
  String? content;
}

/// Resolution planning for gap.
@SectionId('GAENRE')
class GapEntryResolution {
  @Form([
    Field('proposedResolution', String, 'Proposed Resolution',
        hint: 'High-level approach to closing the gap'),
    Field('expectedTimeline', String, 'Expected Resolution Timeline',
        hint: 'Target timeframe, e.g. Phase 1 — Q3 2026, 6-9 months'),
    Field('successCriteria', String, 'Success Criteria',
        hint: 'Measurable criteria that confirm the gap is closed'),
    Field('dependsOnGaps', String, 'Depends on Other Gaps',
        hint: 'Other gaps that must be resolved first, by name or ID'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 1.4 Current Data Landscape
// ---------------------------------------------------------------------------

/// 1.4. Current Data Landscape [PD00-CUR-DAT].
///
/// Comprehensive documentation of the current data situation including where
/// data lives, data quality issues, duplication, ownership, volumes, growth
/// trends, retention policies, and governance structures.
@SectionId('CUDALA')
@DetailedIn(CurrentSituation)
@SecondLevelSectionId(CurrentSituation, 'CS-DAT')
class CurrentDataLandscape {
  @ContentHelp('''
Executive overview of the current data landscape. Summarize the overall data
situation, key data assets, major challenges, and strategic importance of data
to the organization. Highlight critical data dependencies and risks.
''')
  String? content;

  /// Visual representation of the data landscape.
  @ContentType('mermaid-flowchart', 'High-level diagram showing data domains, '
      'major data stores, data flows, and integration points')
  String? dataLandscapeOverviewDiagram;

  /// Data architecture summary diagram.
  @ContentType('mermaid', 'ER-style or architectural diagram showing '
      'relationships between major data entities and systems')
  String? dataArchitectureDiagram;

  /// Summary statistics and health indicators.
  DataLandscapeSummary dataLandscapeSummary = DataLandscapeSummary();

  /// 1.4.1. Data Source Inventory [PD00-CUR-DAT-SRC].
  DataSourceInventory dataSourceInventory = DataSourceInventory();

  /// 1.4.2. Data Quality Assessment [PD00-CUR-DAT-QUA].
  DataQualityAssessment dataQualityAssessment = DataQualityAssessment();

  /// 1.4.3. Data Duplication Analysis [PD00-CUR-DAT-DUP].
  DataDuplicationAnalysis dataDuplicationAnalysis = DataDuplicationAnalysis();

  /// 1.4.4. Data Ownership and Stewardship [PD00-CUR-DAT-OWN].
  DataOwnership dataOwnership = DataOwnership();

  /// 1.4.5. Data Volumes and Growth [PD00-CUR-DAT-VOL].
  DataVolumesAndGrowth dataVolumesAndGrowth = DataVolumesAndGrowth();

  /// 1.4.6. Retention Policies [PD00-CUR-DAT-RET].
  DataRetentionPolicies retentionPolicies = DataRetentionPolicies();

  /// 1.4.7. Data Governance [PD00-CUR-DAT-GOV].
  DataGovernance dataGovernance = DataGovernance();

  /// 1.4.8. Data Classification [PD00-CUR-DAT-CLA].
    CurrentDataClassification dataClassification = CurrentDataClassification();

  /// 1.4.9. Data Integration Points [PD00-CUR-DAT-INT].
  DataIntegrationPoints dataIntegrationPoints = DataIntegrationPoints();

  /// 1.4.10. Master Data Management [PD00-CUR-DAT-MDM].
  MasterDataManagement masterDataManagement = MasterDataManagement();
}

/// Summary statistics and health indicators for data landscape.
@SectionId('DALASU')
class DataLandscapeSummary {
  @Form([
    Field('totalDataSources', int, 'Total Data Sources',
        hint: 'Number of distinct data sources/stores'),
    Field('totalDataVolume', String, 'Total Data Volume',
        hint: 'Aggregate data volume across all sources, e.g. 15 TB'),
    Field('overallDataQualityScore', String, 'Overall Data Quality Score',
        hint: 'Aggregate quality score, e.g. 72% or B+'),
    Field('criticalDataAssets', int, 'Critical Data Assets',
        hint: 'Number of data assets classified as business-critical'),
    Field('dataGovernanceMaturity', String, 'Data Governance Maturity Level',
        hint: 'Level 1-5 or Initial/Managed/Defined/Measured/Optimized'),
    Field('knownDuplicationRate', String, 'Known Duplication Rate',
        hint: 'Estimated percentage of duplicated data, e.g. 15%'),
    Field('complianceStatus', String, 'Regulatory Compliance Status',
        hint: 'Compliant / PartiallyCompliant / NonCompliant / Unknown'),
    Field('dataSecurityRiskLevel', String, 'Data Security Risk Level',
        hint: 'Low / Medium / High / Critical'),
    Field('averageDataAge', String, 'Average Data Age',
        hint: 'Average age of data across sources, e.g. 18 months'),
    Field('dataDocumentationCoverage', String, 'Documentation Coverage',
        hint: 'Percentage of data assets with adequate documentation'),
  ])
  String? content;
}

/// 1.4.1. Data Source Inventory [PD00-CUR-DAT-SRC].
///
/// Comprehensive inventory of all data sources, stores, and repositories
/// in the current environment.
@SectionId('DASOIN')
class DataSourceInventory {
  @ContentHelp('''
Overview of the data source inventory. Describe the methodology used to
catalog data sources, coverage of the inventory, and any known gaps.
''')
  String? content;

  /// Visual map of data sources by domain/category.
  @ContentType('mermaid', 'Diagram showing data sources grouped by '
      'business domain or technical category')
  String? dataSourceMapDiagram;

  /// Contains 0+× DataSource.
  @SectionId('DASR-DATA-LST')
  @SectionIdPattern('DASR-DATA-xxx')
  List<DataSourceEntry> dataSources = [];
}

/// A data source entry (form) [PD00-CUR-DAT-SRC-nn].
///
/// Documents a specific data source/store with comprehensive details about
/// technology, format, volume, quality, ownership, and access patterns.
@SectionId('DASR')
class DataSourceEntry {
  @Form([
    Field('dataSourceId', String, 'Data Source ID',
        hint: 'Unique identifier, e.g. DS-001', required: true),
    Field('dataStoreName', String, 'Data Store Name',
        hint: 'Name of the data store or source', required: true),
    Field('criticality', String, 'Business Criticality',
        hint: 'Critical / High / Medium / Low'),
  ])
  String? content;

  /// Classification.
  final DataSourceClassification classification = DataSourceClassification();

  /// Technical details.
  final DataSourceTechnical technical = DataSourceTechnical();

  /// Volume and performance.
  final DataSourceVolume volume = DataSourceVolume();

  /// Quality and reliability.
  final DataSourceQuality quality = DataSourceQuality();

  /// Ownership and governance.
  final DataSourceOwnership ownership = DataSourceOwnership();

  /// Integration.
  final DataSourceIntegration integration = DataSourceIntegration();

  /// Lifecycle.
  final DataSourceLifecycle lifecycle = DataSourceLifecycle();

  /// Retention Policy for this data source.
  DataSourceRetentionPolicy retentionPolicy = DataSourceRetentionPolicy();

  /// Key data entities in this source.
  @Min(1)
  @SectionId('DSEE-KEYE-LST')
  @SectionIdPattern('DSEE-KEYE-xxx')
    List<DataSourceEntityEntry> keyEntities = [];
}

/// Classification for data source.
@SectionId('DASOCL')
class DataSourceClassification {
  @Form([
    Field('description', String, 'Description',
        hint: 'Brief description of what data this source contains'),
    Field('sourceCategory', String, 'Source Category',
        hint: 'Transactional / Analytical / Master / Reference / Archive'),
    Field('businessDomain', String, 'Business Domain',
        hint: 'E.g. Sales, Finance, HR, Operations, Customer'),
  ])
  String? content;
}

/// Technical details for data source.
@SectionId('DASOTE')
class DataSourceTechnical {
  @Form([
    Field('storeType', String, 'Store Type',
        hint: 'Database / DataWarehouse / DataLake / FileSystem / API'),
    Field('technology', String, 'Technology/Platform',
        hint: 'E.g. PostgreSQL, Oracle, MongoDB, S3, Salesforce'),
    Field('version', String, 'Version',
        hint: 'Software/platform version'),
    Field('hostingLocation', String, 'Hosting Location',
        hint: 'OnPremise / CloudAWS / CloudAzure / CloudGCP / SaaS'),
    Field('dataFormat', String, 'Data Format',
        hint: 'Relational / Document / Key-Value / CSV / JSON / XML'),
  ])
  String? content;
}

/// Volume and performance for data source.
@SectionId('DASOVO')
class DataSourceVolume {
  @Form([
    Field('estimatedVolume', String, 'Estimated Volume',
        hint: 'E.g. 500 GB, 2 TB, 50 million records'),
    Field('estimatedRecordCount', String, 'Estimated Record Count',
        hint: 'Number of records/rows/documents'),
    Field('growthRate', String, 'Growth Rate',
        hint: 'E.g. 5% per month, 100 GB per quarter'),
    Field('accessFrequency', String, 'Access Frequency',
        hint: 'Realtime / Hourly / Daily / Weekly / Monthly'),
    Field('peakLoadPeriods', String, 'Peak Load Periods',
        hint: 'When the source experiences highest load'),
  ])
  String? content;
}

/// Quality and reliability for data source.
@SectionId('DASOQU')
class DataSourceQuality {
  @Form([
    Field('dataQualityScore', String, 'Data Quality Score',
        hint: 'Quality rating, e.g. 85%, A, High'),
    Field('knownQualityIssues', String, 'Known Quality Issues',
        hint: 'Summary of quality problems'),
    Field('dataFreshness', String, 'Data Freshness',
        hint: 'How current the data is, e.g. RealTime / Daily'),
    Field('reliabilityScore', String, 'Reliability Score',
        hint: 'Uptime/reliability, e.g. 99.5%'),
  ])
  String? content;
}

/// Ownership and governance for data source.
@SectionId('DASOOW')
class DataSourceOwnership {
  @Form([
    Field('businessOwner', String, 'Business Owner',
        hint: 'Department or role responsible for data'),
    Field('technicalOwner', String, 'Technical Owner',
        hint: 'Team or role responsible for technical management'),
    Field('dataSteward', String, 'Data Steward',
        hint: 'Person responsible for data quality'),
    Field('accessControlModel', String, 'Access Control Model',
        hint: 'RBAC / ABAC / ACL / Open'),
    Field('sensitivityLevel', String, 'Data Sensitivity Level',
        hint: 'Public / Internal / Confidential / Restricted'),
  ])
  String? content;
}

/// Integration for data source.
@SectionId('DASOI1')
class DataSourceIntegration {
  @Form([
    Field('integratedSystems', String, 'Integrated Systems',
        hint: 'Systems that read from or write to this source'),
    Field('upstreamSources', String, 'Upstream Sources',
        hint: 'Data sources that feed into this one'),
    Field('downstreamConsumers', String, 'Downstream Consumers',
        hint: 'Systems that consume data from this source'),
  ])
  String? content;
}

/// Lifecycle for data source.
@SectionId('DASOLI')
class DataSourceLifecycle {
  @Form([
    Field('creationDate', String, 'Creation Date',
        hint: 'When the data source was established'),
    Field('lastMajorUpdate', String, 'Last Major Update',
        hint: 'When the source was last significantly modified'),
    Field('plannedDecommission', String, 'Planned Decommission',
        hint: 'If scheduled for retirement, target date'),
    Field('documentationStatus', String, 'Documentation Status',
        hint: 'Complete / Partial / Minimal / None'),
    Field('schemaDocumentationLink', String, 'Schema Documentation Link',
        hint: 'Link to detailed schema documentation'),
  ])
  String? content;
}

/// Retention policy specific to a data source.
@SectionId('DSRP')
class DataSourceRetentionPolicy {
  @Form([
    Field('retentionPeriod', String, 'Retention Period',
        hint: 'How long data is kept, e.g. 7 years, indefinite'),
    Field('archivalPolicy', String, 'Archival Policy',
        hint: 'How data is archived after active use'),
    Field('deletionPolicy', String, 'Deletion Policy',
        hint: 'How data is deleted/purged'),
    Field('legalBasis', String, 'Legal Basis',
        hint: 'Regulatory or legal requirement driving retention'),
    Field('complianceNotes', String, 'Compliance Notes',
        hint: 'Additional compliance considerations'),
  ])
  String? content;
}

/// Key data entity within a data source.
@SectionId('DSEE')
class DataSourceEntityEntry {
  @Form([
    Field('entityName', String, 'Entity Name',
        hint: 'Name of the entity/table/collection', required: true),
    Field('description', String, 'Description',
        hint: 'What this entity represents'),
    Field('recordCount', String, 'Record Count',
        hint: 'Approximate number of records'),
    Field('primaryKey', String, 'Primary Key',
        hint: 'Key field(s) identifying unique records'),
    Field('relationships', String, 'Key Relationships',
        hint: 'Important relationships to other entities'),
    Field('sensitiveFields', String, 'Sensitive Fields',
        hint: 'Fields containing sensitive data'),
  ])
  String? content;
}

/// 1.4.2. Data Quality Assessment [PD00-CUR-DAT-QUA].
///
/// Comprehensive assessment of data quality across the organization,
/// covering accuracy, completeness, consistency, timeliness, and validity.
@SectionId('DAQUAS')
class DataQualityAssessment {
  @ContentHelp('''
Overview of data quality across the organization. Describe the assessment
methodology, scope, key findings, and overall data quality posture.
''')
  String? content;

  /// Data quality dimensions summary.
  DataQualityDimensionsSummary dimensionsSummary =
      DataQualityDimensionsSummary();

  /// Quality issues by severity.
  @ContentType('mermaid', 'Chart showing distribution of quality issues '
      'by severity level')
  String? qualityIssuesSeverityChart;

  /// Data quality issues inventory.
  @SectionId('DAQLIS-QUAL-LST')
  @SectionIdPattern('DAQLIS-QUAL-xxx')
  @Min(1)
  List<DataQualityIssueEntry> qualityIssues = [];

  /// Quality improvement initiatives in progress.
  @SectionId('DQIE-IMPR-LST')
  @SectionIdPattern('DQIE-IMPR-xxx')
  List<DataQualityInitiativeEntry> improvementInitiatives = [];
}

/// Summary of data quality across standard dimensions.
@SectionId('DQDS')
class DataQualityDimensionsSummary {
  @Form([
    Field('accuracyScore', String, 'Accuracy Score',
        hint: 'Overall accuracy of data, e.g. 92%'),
    Field('completenessScore', String, 'Completeness Score',
        hint: 'Percentage of required data present, e.g. 88%'),
    Field('consistencyScore', String, 'Consistency Score',
        hint: 'Data consistency across sources, e.g. 79%'),
    Field('timelinessScore', String, 'Timeliness Score',
        hint: 'How current data is, e.g. 95%'),
    Field('validityScore', String, 'Validity Score',
        hint: 'Conformance to business rules, e.g. 85%'),
    Field('uniquenessScore', String, 'Uniqueness Score',
        hint: 'Absence of duplicate records, e.g. 91%'),
    Field('integrityScore', String, 'Referential Integrity Score',
        hint: 'Integrity of relationships, e.g. 88%'),
    Field('assessmentDate', String, 'Assessment Date',
        hint: 'When this assessment was performed'),
    Field('assessmentScope', String, 'Assessment Scope',
        hint: 'What was included in the assessment'),
    Field('assessmentMethodology', String, 'Assessment Methodology',
        hint: 'How the assessment was conducted'),
  ])
  String? content;
}

/// A data quality issue entry (form).
@SectionId('DAQLIS')
class DataQualityIssueEntry {
  @Form([
    Field('issueId', String, 'Issue ID',
        hint: 'Unique identifier, e.g. DQ-001', required: true),
    Field('issueTitle', String, 'Issue Title',
        hint: 'Brief description of the quality issue', required: true),
    Field('description', String, 'Detailed Description',
        hint: 'Full description of the issue and its manifestation'),
    Field('affectedDataSource', String, 'Affected Data Source',
        hint: 'Which data source(s) are impacted'),
  ])
  String? content;

  /// Classification and severity.
  DataQualityIssueEntryClassification classification =
      DataQualityIssueEntryClassification();

  /// Business impact and diagnostics.
  DataQualityIssueEntryImpact impact = DataQualityIssueEntryImpact();

  /// Resolution planning.
  DataQualityIssueEntryResolution resolution =
      DataQualityIssueEntryResolution();
}

/// Classification and severity.
@SectionId('DQIEC')
class DataQualityIssueEntryClassification {
  @Form([
    Field('affectedEntities', String, 'Affected Entities',
        hint: 'Which data entities/tables are impacted'),
    Field('qualityDimension', String, 'Quality Dimension',
        hint: 'Accuracy / Completeness / Consistency / Timeliness / Validity'),
    Field('severity', String, 'Severity',
        hint: 'Critical / High / Medium / Low'),
  ])
  String? content;
}

/// Business impact and diagnostics.
@SectionId('DQIEI')
class DataQualityIssueEntryImpact {
  @Form([
    Field('impactDescription', String, 'Business Impact',
        hint: 'How this quality issue affects business operations'),
    Field('quantifiedImpact', String, 'Quantified Impact',
        hint: 'Measurable impact, e.g. EUR50k/year, 10% error rate'),
    Field('rootCause', String, 'Root Cause',
        hint: 'Underlying cause of the quality issue'),
    Field('affectedRecordCount', String, 'Affected Record Count',
        hint: 'Number or percentage of records affected'),
    Field('dateIdentified', String, 'Date Identified',
        hint: 'When the issue was discovered'),
  ])
  String? content;
}

/// Resolution planning.
@SectionId('DQIER')
class DataQualityIssueEntryResolution {
  @Form([
    Field('currentWorkaround', String, 'Current Workaround',
        hint: 'How users currently cope with this issue'),
    Field('proposedResolution', String, 'Proposed Resolution',
        hint: 'Recommended approach to fix the issue'),
    Field('resolutionPriority', String, 'Resolution Priority',
        hint: 'P1 / P2 / P3 / P4'),
  ])
  String? content;
}

/// Data quality improvement initiative entry.
@SectionId('DQIE')
class DataQualityInitiativeEntry {
  @Form([
    Field('initiativeId', String, 'Initiative ID',
        hint: 'Unique identifier'),
    Field('initiativeName', String, 'Initiative Name',
        hint: 'Name of the improvement initiative', required: true),
    Field('description', String, 'Description',
        hint: 'What the initiative aims to achieve'),
    Field('targetIssues', String, 'Target Issues',
        hint: 'Quality issues this initiative addresses'),
    Field('status', String, 'Status',
        hint: 'Planned / InProgress / Completed / OnHold'),
    Field('expectedCompletion', String, 'Expected Completion',
        hint: 'Target completion date'),
    Field('expectedImprovement', String, 'Expected Improvement',
        hint: 'Quantified improvement target'),
  ])
  String? content;
}

/// 1.4.3. Data Duplication Analysis [PD00-CUR-DAT-DUP].
///
/// Analysis of data duplication across systems, including redundant data
/// stores, duplicated records, and synchronization challenges.
@SectionId('DADUAN')
class DataDuplicationAnalysis {
  @ContentHelp('''
Overview of data duplication across the organization. Describe the extent
of duplication, its causes, impacts, and any ongoing deduplication efforts.
''')
  String? content;

  /// Duplication analysis summary.
  DataDuplicationSummary duplicationSummary = DataDuplicationSummary();

  /// Visual representation of data redundancy.
  @ContentType('mermaid', 'Diagram showing overlapping data stores and '
      'duplicate data flows')
  String? duplicationDiagram;

  /// Individual duplication instances.
  @SectionId('DADU-DUPL-LST')
  @SectionIdPattern('DADU-DUPL-xxx')
  List<DataDuplicationEntry> duplicationInstances = [];
}

/// Summary of data duplication findings.
@SectionId('DADUSU')
class DataDuplicationSummary {
  @Form([
    Field('overallDuplicationRate', String, 'Overall Duplication Rate',
        hint: 'Estimated percentage of duplicated data, e.g. 23%'),
    Field('duplicateDataVolume', String, 'Duplicate Data Volume',
        hint: 'Volume of duplicated data, e.g. 2.3 TB'),
    Field('numberOfDuplicationInstances', int, 'Number of Known Duplications',
        hint: 'Count of documented duplication cases'),
    Field('storageWasteEstimate', String, 'Storage Waste Estimate',
        hint: 'Cost of storing duplicate data, e.g. €15k/year'),
    Field('synchronizationChallenges', int, 'Synchronization Challenges',
        hint: 'Number of sync issues caused by duplication'),
    Field('dataInconsistencyRisk', String, 'Data Inconsistency Risk',
        hint: 'Low / Medium / High / Critical'),
    Field('consolidationOpportunities', int, 'Consolidation Opportunities',
        hint: 'Number of identified consolidation opportunities'),
    Field('deduplicationPriority', String, 'Deduplication Priority',
        hint: 'Organizational priority for deduplication efforts'),
  ])
  String? content;
}

/// A data duplication instance entry.
@SectionId('DADU')
class DataDuplicationEntry {
  @Form([
    Field('duplicationId', String, 'Duplication ID',
        hint: 'Unique identifier', required: true),
    Field('description', String, 'Description',
        hint: 'Description of the duplication scenario'),
    Field('dataElement', String, 'Data Element',
        hint: 'What data is duplicated'),
  ])
  String? content;

  /// Sources and duplication shape.
  DataDuplicationEntrySources sources = DataDuplicationEntrySources();

  /// Synchronization and consistency details.
  DataDuplicationEntrySynchronization synchronization =
      DataDuplicationEntrySynchronization();

  /// Business impact and resolution guidance.
  DataDuplicationEntryGovernance governance =
      DataDuplicationEntryGovernance();
}

/// Sources and duplication shape.
@SectionId('DDES')
class DataDuplicationEntrySources {
  @Form([
    Field('primarySource', String, 'Primary Source',
        hint: 'Authoritative source for this data'),
    Field('duplicateSources', String, 'Duplicate Sources',
        hint: 'Other locations where this data exists'),
    Field('duplicationType', String, 'Duplication Type',
        hint: 'FullCopy / PartialCopy / Denormalized / CachedCopy'),
  ])
  String? content;
}

/// Synchronization and consistency details.
@SectionId('DDES1')
class DataDuplicationEntrySynchronization {
  @Form([
    Field('synchronizationMethod', String, 'Synchronization Method',
        hint: 'How duplicates are kept in sync, if at all'),
    Field('syncFrequency', String, 'Sync Frequency',
        hint: 'RealTime / Hourly / Daily / Manual / None'),
    Field('knownInconsistencies', String, 'Known Inconsistencies',
        hint: 'Documented cases of data drift between copies'),
  ])
  String? content;
}

/// Business impact and resolution guidance.
@SectionId('DDEG')
class DataDuplicationEntryGovernance {
  @Form([
    Field('businessReason', String, 'Business Reason',
        hint: 'Why this duplication exists'),
    Field('consolidationFeasibility', String, 'Consolidation Feasibility',
        hint: 'Easy / Moderate / Difficult / NotFeasible'),
    Field('impactOfDuplication', String, 'Impact of Duplication',
        hint: 'Negative effects of this duplication'),
    Field('recommendedAction', String, 'Recommended Action',
        hint: 'Proposed resolution'),
  ])
  String? content;
}

/// 1.4.4. Data Ownership and Stewardship [PD00-CUR-DAT-OWN].
///
/// Documentation of data ownership structures, stewardship roles,
/// and accountability for data assets.
@SectionId('DAOW')
class DataOwnership {
  @ContentHelp('''
Overview of data ownership and stewardship across the organization. Describe
the ownership model, roles and responsibilities, and any gaps in accountability.
''')
  String? content;

  /// Ownership model summary.
  DataOwnershipSummary ownershipSummary = DataOwnershipSummary();

  /// Data ownership matrix visualization.
  @ContentType('mermaid', 'Matrix or diagram showing data domains and '
      'their owners/stewards')
  String? ownershipMatrixDiagram;

  /// Data ownership assignments by domain.
  @Min(1)
  @SectionId('DAOWEN-OWNE-LST')
  @SectionIdPattern('DAOWEN-OWNE-xxx')
  List<DataOwnershipEntry> ownershipAssignments = [];
}

/// Summary of data ownership model.
@SectionId('DAOWSU')
class DataOwnershipSummary {
  @Form([
    Field('ownershipModel', String, 'Ownership Model',
        hint: 'Centralized / Federated / Hybrid'),
    Field('totalDataDomains', int, 'Total Data Domains',
        hint: 'Number of defined data domains'),
    Field('assignedOwnershipPercentage', String, 'Assigned Ownership',
        hint: 'Percentage of data with clear ownership, e.g. 78%'),
    Field('activeStewards', int, 'Active Data Stewards',
        hint: 'Number of active data stewards'),
    Field('ownershipGaps', int, 'Ownership Gaps',
        hint: 'Number of data assets without clear ownership'),
    Field('stewardshipMaturity', String, 'Stewardship Maturity',
        hint: 'Initial / Developing / Established / Optimizing'),
    Field('governanceCouncilExists', String, 'Governance Council',
        hint: 'Yes / No — whether a data governance council exists'),
    Field('escalationProcess', String, 'Escalation Process',
        hint: 'Whether clear escalation paths exist'),
  ])
  String? content;
}

/// Data ownership assignment for a domain or asset.
@SectionId('DAOWEN')
class DataOwnershipEntry {
  @Form([
    Field('dataDomain', String, 'Data Domain',
        hint: 'Business area or data domain', required: true),
    Field('dataAssets', String, 'Data Assets',
        hint: 'Specific data assets in this domain'),
    Field('businessOwner', String, 'Business Owner',
        hint: 'Executive accountable for the data'),
    Field('businessOwnerRole', String, 'Owner Role',
        hint: 'Job title/role of the business owner'),
  ])
  String? content;

  /// Stewardship and custodianship assignments.
  DataOwnershipEntryStewardship stewardship = DataOwnershipEntryStewardship();

  /// Access and coverage governance.
  DataOwnershipEntryGovernance governance = DataOwnershipEntryGovernance();
}

/// Stewardship and custodianship assignments.
@SectionId('DOES1')
class DataOwnershipEntryStewardship {
  @Form([
    Field('dataSteward', String, 'Data Steward',
        hint: 'Person responsible for day-to-day data management'),
    Field('stewardRole', String, 'Steward Role',
        hint: 'Job title/role of the data steward'),
    Field('technicalCustodian', String, 'Technical Custodian',
        hint: 'IT person/team responsible for technical data management'),
    Field('qualityAccountable', String, 'Quality Accountable',
        hint: 'Who is accountable for data quality'),
  ])
  String? content;
}

/// Access and coverage governance.
@SectionId('DOEG')
class DataOwnershipEntryGovernance {
  @Form([
    Field('accessApprover', String, 'Access Approver',
        hint: 'Who approves access to this data'),
    Field('coverageStatus', String, 'Coverage Status',
        hint: 'Full / Partial / Minimal ownership coverage'),
    Field('lastReviewDate', String, 'Last Review Date',
        hint: 'When ownership was last reviewed'),
  ])
  String? content;
}

/// 1.4.5. Data Volumes and Growth [PD00-CUR-DAT-VOL].
///
/// Analysis of current data volumes, historical growth trends,
/// and projections for future capacity needs.
@SectionId('DVAG')
class DataVolumesAndGrowth {
  @ContentHelp('''
Overview of data volumes and growth patterns across the organization.
Describe current total volumes, growth trends, capacity constraints,
and forecasting methodology.
''')
  String? content;

  /// Volume and growth summary.
  DataVolumeSummary volumeSummary = DataVolumeSummary();

  /// Growth trend visualization.
  @ContentType('mermaid', 'Chart showing historical data growth and '
      'projected future volumes')
  String? growthTrendChart;

  /// Volume details by data source.
  @Min(1)
  @SectionId('DAVOEN-VOLU-LST')
  @SectionIdPattern('DAVOEN-VOLU-xxx')
  List<DataVolumeEntry> volumeBySource = [];
}

/// Summary of data volumes and growth trends.
@SectionId('DAVOSU')
class DataVolumeSummary {
  @Form([
    Field('totalCurrentVolume', String, 'Total Current Volume',
        hint: 'Total data volume, e.g. 45 TB'),
    Field('structuredDataVolume', String, 'Structured Data Volume',
        hint: 'Volume of structured data'),
    Field('unstructuredDataVolume', String, 'Unstructured Data Volume',
        hint: 'Volume of unstructured data'),
  ])
  String? content;

  /// Historical growth behavior.
  DataVolumeSummaryGrowth growth = DataVolumeSummaryGrowth();

  /// Forward-looking forecasts and utilization.
  DataVolumeSummaryProjection projection = DataVolumeSummaryProjection();

  /// Capacity pressure and cost impact.
  DataVolumeSummaryCapacity capacity = DataVolumeSummaryCapacity();
}

/// Historical growth behavior.
@SectionId('DVSG')
class DataVolumeSummaryGrowth {
  @Form([
    Field('annualGrowthRate', String, 'Annual Growth Rate',
        hint: 'Year-over-year growth percentage, e.g. 25%'),
    Field('monthlyGrowthRate', String, 'Monthly Growth Rate',
        hint: 'Month-over-month growth, e.g. 2%'),
    Field('peakGrowthPeriods', String, 'Peak Growth Periods',
        hint: 'When data grows fastest, e.g. Q4, month-end'),
  ])
  String? content;
}

/// Forward-looking forecasts and utilization.
@SectionId('DVSP')
class DataVolumeSummaryProjection {
  @Form([
    Field('projectedVolumeOneYear', String, 'Projected Volume (1 Year)',
        hint: 'Expected volume in 12 months'),
    Field('projectedVolumeThreeYears', String, 'Projected Volume (3 Years)',
        hint: 'Expected volume in 36 months'),
    Field('capacityUtilization', String, 'Current Capacity Utilization',
        hint: 'Percentage of storage capacity used, e.g. 72%'),
  ])
  String? content;
}

/// Capacity pressure and cost impact.
@SectionId('DVSC')
class DataVolumeSummaryCapacity {
  @Form([
    Field('capacityConstraints', String, 'Capacity Constraints',
        hint: 'Any current or anticipated capacity issues'),
    Field('storageCost', String, 'Total Storage Cost',
        hint: 'Annual cost of data storage, e.g. €250k/year'),
    Field('costGrowthProjection', String, 'Cost Growth Projection',
        hint: 'Expected storage cost growth'),
  ])
  String? content;
}

/// Volume details for a specific data source.
@SectionId('DAVOEN')
class DataVolumeEntry {
  @Form([
    Field('dataSource', String, 'Data Source',
        hint: 'Name of the data source', required: true),
    Field('currentVolume', String, 'Current Volume',
        hint: 'Current data volume'),
    Field('recordCount', String, 'Record Count',
        hint: 'Number of records/documents'),
    Field('averageRecordSize', String, 'Average Record Size',
        hint: 'Average size per record'),
    Field('historicalGrowth', String, 'Historical Growth',
        hint: 'Growth over past 12 months'),
    Field('projectedGrowth', String, 'Projected Growth',
        hint: 'Expected growth over next 12 months'),
    Field('growthDrivers', String, 'Growth Drivers',
        hint: 'What drives data growth in this source'),
    Field('archivalRate', String, 'Archival Rate',
        hint: 'How much data is archived periodically'),
    Field('purgeRate', String, 'Purge Rate',
        hint: 'How much data is deleted periodically'),
  ])
  String? content;
}

/// 1.4.6. Retention Policies [PD00-CUR-DAT-RET].
///
/// Documentation of data retention policies, legal requirements,
/// archival strategies, and data lifecycle management.
@SectionId('DAREPO')
class DataRetentionPolicies {
  @ContentHelp('''
Overview of data retention policies and lifecycle management. Describe the
policy framework, regulatory drivers, implementation status, and any gaps.
''')
  String? content;

  /// Retention policy summary.
  RetentionPolicySummary policySummary = RetentionPolicySummary();

  /// Retention policies by data category.
  @SectionId('REPOL-RETE-LST')
  @SectionIdPattern('REPOL-RETE-xxx')
  @Min(1)
  List<RetentionPolicyEntry> retentionPolicies = [];
}

/// Summary of retention policy framework.
@SectionId('REPOSU')
class RetentionPolicySummary {
  @Form([
    Field('policyFrameworkExists', String, 'Policy Framework Exists',
        hint: 'Yes / Partial / No'),
    Field('primaryRegulations', String, 'Primary Regulations',
        hint: 'Key regulations driving retention, e.g. GDPR, SOX, HIPAA'),
    Field('defaultRetentionPeriod', String, 'Default Retention Period',
        hint: 'Default retention if not specified, e.g. 7 years'),
    Field('policyComplianceRate', String, 'Policy Compliance Rate',
        hint: 'Percentage of data following retention policies'),
    Field('archivalSystemExists', String, 'Archival System',
        hint: 'Yes / No — whether systematic archival exists'),
    Field('automatedPurging', String, 'Automated Purging',
        hint: 'Yes / Partial / Manual — purging automation level'),
    Field('legalHoldProcess', String, 'Legal Hold Process',
        hint: 'Whether legal hold process is defined'),
    Field('retentionGaps', String, 'Retention Gaps',
        hint: 'Number of data areas without retention policies'),
    Field('lastPolicyReview', String, 'Last Policy Review',
        hint: 'When retention policies were last reviewed'),
  ])
  String? content;
}

/// Retention policy for a specific data category.
@SectionId('REPOL')
class RetentionPolicyEntry {
  @Form([
    Field('policyId', String, 'Policy ID',
        hint: 'Unique identifier', required: true),
    Field('dataCategory', String, 'Data Category',
        hint: 'Category of data this policy applies to', required: true),
    Field('appliesTo', String, 'Applies To',
        hint: 'Specific data sources or entities'),
  ])
  String? content;

  /// Retention timing and legal basis.
  RetentionPolicyEntryRequirements requirements =
      RetentionPolicyEntryRequirements();

  /// Archival and deletion lifecycle handling.
  RetentionPolicyEntryLifecycle lifecycle = RetentionPolicyEntryLifecycle();

  /// Compliance and accountability status.
  RetentionPolicyEntryGovernance governance = RetentionPolicyEntryGovernance();
}

/// Retention timing and legal basis.
@SectionId('RPER')
class RetentionPolicyEntryRequirements {
  @Form([
    Field('retentionPeriod', String, 'Retention Period',
        hint: 'How long data is retained, e.g. 7 years'),
    Field('retentionTrigger', String, 'Retention Trigger',
        hint: 'What starts the retention clock, e.g. creation date, last access'),
    Field('legalBasis', String, 'Legal Basis',
        hint: 'Regulation or law requiring this retention'),
  ])
  String? content;
}

/// Archival and deletion lifecycle handling.
@SectionId('RPEL')
class RetentionPolicyEntryLifecycle {
  @Form([
    Field('archivalMethod', String, 'Archival Method',
        hint: 'How data is archived, e.g. cold storage, tape, cloud archive'),
    Field('deletionMethod', String, 'Deletion Method',
        hint: 'How data is deleted, e.g. logical delete, physical purge, secure wipe'),
    Field('exceptionProcess', String, 'Exception Process',
        hint: 'How exceptions to the policy are handled'),
  ])
  String? content;
}

/// Compliance and accountability status.
@SectionId('RPEG')
class RetentionPolicyEntryGovernance {
  @Form([
    Field('complianceStatus', String, 'Compliance Status',
        hint: 'Compliant / PartiallyCompliant / NonCompliant'),
    Field('implementationStatus', String, 'Implementation Status',
        hint: 'Implemented / InProgress / Planned / NotImplemented'),
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Who is responsible for enforcing this policy'),
  ])
  String? content;
}

/// 1.4.7. Data Governance [PD00-CUR-DAT-GOV].
///
/// Current data governance structure, policies, processes, and maturity level.
@SectionId('DAGO')
class DataGovernance {
  @ContentHelp('''
Overview of data governance in the organization. Describe the governance
framework, organizational structure, policies, and current maturity level.
''')
  String? content;

  /// Governance maturity assessment.
  DataGovernanceMaturity governanceMaturity = DataGovernanceMaturity();

  /// Governance organization structure.
  @ContentType('mermaid', 'Organizational chart showing data governance '
      'roles and reporting structure')
  String? governanceOrgChart;

  /// Data governance policies.
  @Min(1)
  @SectionId('DGPE-GOVE-LST')
  @SectionIdPattern('DGPE-GOVE-xxx')
  List<DataGovernancePolicyEntry> governancePolicies = [];
}

/// Data governance maturity assessment.
@SectionId('DAGOMA')
class DataGovernanceMaturity {
  @Form([
    Field('overallMaturityLevel', String, 'Overall Maturity Level',
        hint: 'Level 1-5 or Initial/Managed/Defined/Measured/Optimized'),
    Field('strategyMaturity', String, 'Strategy Maturity',
        hint: 'Maturity of data governance strategy'),
    Field('organizationMaturity', String, 'Organization Maturity',
        hint: 'Maturity of governance organizational structure'),
    Field('policyMaturity', String, 'Policy Maturity',
        hint: 'Maturity of governance policies'),
    Field('processMaturity', String, 'Process Maturity',
        hint: 'Maturity of governance processes'),
    Field('technologyMaturity', String, 'Technology Maturity',
        hint: 'Maturity of supporting technology/tools'),
    Field('cultureMaturity', String, 'Culture Maturity',
        hint: 'Data-aware culture maturity'),
    Field('assessmentDate', String, 'Assessment Date',
        hint: 'When maturity was last assessed'),
    Field('targetMaturityLevel', String, 'Target Maturity Level',
        hint: 'Desired maturity level'),
    Field('maturityGaps', String, 'Key Maturity Gaps',
        hint: 'Areas needing most improvement'),
  ])
  String? content;
}

/// Data governance policy entry.
@SectionId('DGPE')
class DataGovernancePolicyEntry {
  @Form([
    Field('policyId', String, 'Policy ID',
        hint: 'Unique identifier'),
    Field('policyName', String, 'Policy Name',
        hint: 'Name of the governance policy', required: true),
    Field('policyArea', String, 'Policy Area',
        hint: 'DataQuality / DataSecurity / DataPrivacy / DataAccess / MDM'),
    Field('description', String, 'Description',
        hint: 'Brief description of the policy'),
  ])
  String? content;

  /// Policy lifecycle and applicability.
  DataGovernancePolicyEntryLifecycle lifecycle =
      DataGovernancePolicyEntryLifecycle();

  /// Ownership, enforcement, and compliance status.
  DataGovernancePolicyEntryGovernance governance =
      DataGovernancePolicyEntryGovernance();
}

/// Policy lifecycle and applicability.
@SectionId('DGPEL')
class DataGovernancePolicyEntryLifecycle {
  @Form([
    Field('scope', String, 'Scope',
        hint: 'What the policy applies to'),
    Field('status', String, 'Status',
        hint: 'Draft / Approved / InForce / UnderReview / Retired'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When the policy became effective'),
    Field('reviewFrequency', String, 'Review Frequency',
        hint: 'How often the policy is reviewed'),
  ])
  String? content;
}

/// Ownership, enforcement, and compliance status.
@SectionId('DGPEG')
class DataGovernancePolicyEntryGovernance {
  @Form([
    Field('policyOwner', String, 'Policy Owner',
        hint: 'Who owns the policy'),
    Field('enforcementMechanism', String, 'Enforcement Mechanism',
        hint: 'How the policy is enforced'),
    Field('complianceLevel', String, 'Compliance Level',
        hint: 'Current compliance with this policy'),
  ])
  String? content;
}

/// 1.4.8. Data Classification [PD00-CUR-DAT-CLA].
///
/// Data classification framework, sensitivity levels, and current
/// classification status of data assets.
@SectionId('CUDACL')
class CurrentDataClassification {
  @ContentHelp('''
Overview of data classification in the organization. Describe the classification
framework, sensitivity levels, handling requirements, and current classification
coverage.
''')
  String? content;

  /// Classification framework summary.
  DataClassificationSummary classificationSummary =
      DataClassificationSummary();

  /// Classification levels defined.
  @Min(1)
  @SectionId('DCLE-CLAS-LST')
  @SectionIdPattern('DCLE-CLAS-xxx')
  List<DataClassificationLevelEntry> classificationLevels = [];

  /// Classification status by data domain.
  @SectionId('DCSE-CLAS-LST')
  @SectionIdPattern('DCSE-CLAS-xxx')
  List<DataClassificationStatusEntry> classificationStatus = [];
}

/// Summary of data classification framework.
@SectionId('DACLSU')
class DataClassificationSummary {
  @Form([
    Field('classificationFrameworkExists', String, 'Framework Exists',
        hint: 'Yes / Partial / No'),
    Field('frameworkName', String, 'Framework Name',
        hint: 'Name of classification framework if standardized'),
    Field('numberOfLevels', int, 'Number of Levels',
        hint: 'How many classification levels are defined'),
    Field('classificationCoverage', String, 'Classification Coverage',
        hint: 'Percentage of data that is classified'),
    Field('autoClassificationExists', String, 'Auto-Classification',
        hint: 'Yes / Partial / No — automated classification tools'),
    Field('labelingImplemented', String, 'Labeling Implemented',
        hint: 'Whether data is actively labeled'),
    Field('handlingProceduresDocumented', String, 'Handling Procedures',
        hint: 'Whether handling procedures per level are documented'),
    Field('trainingProvided', String, 'Training Provided',
        hint: 'Whether classification training is provided'),
    Field('lastFrameworkReview', String, 'Last Framework Review',
        hint: 'When the framework was last reviewed'),
  ])
  String? content;
}

/// A data classification level definition.
@SectionId('DCLE')
class DataClassificationLevelEntry {
  @Form([
    Field('levelName', String, 'Level Name',
        hint: 'E.g. Public, Internal, Confidential, Restricted', required: true),
    Field('levelOrder', int, 'Level Order',
        hint: 'Numeric order, 1=lowest sensitivity'),
    Field('description', String, 'Description',
        hint: 'What this level means'),
    Field('dataExamples', String, 'Data Examples',
        hint: 'Examples of data at this level'),
    Field('handlingRequirements', String, 'Handling Requirements',
        hint: 'How data at this level must be handled'),
    Field('accessRestrictions', String, 'Access Restrictions',
        hint: 'Who can access data at this level'),
    Field('storageRequirements', String, 'Storage Requirements',
        hint: 'How data at this level must be stored'),
    Field('transmissionRequirements', String, 'Transmission Requirements',
        hint: 'How data at this level can be transmitted'),
    Field('disposalRequirements', String, 'Disposal Requirements',
        hint: 'How data at this level must be disposed'),
    Field('incidentResponseLevel', String, 'Incident Response',
        hint: 'Response level if breached'),
  ])
  String? content;
}

/// Classification status for a data domain.
@SectionId('DCSE')
class DataClassificationStatusEntry {
  @Form([
    Field('dataDomain', String, 'Data Domain',
        hint: 'Business area or data domain', required: true),
    Field('classificationStatus', String, 'Classification Status',
        hint: 'Complete / InProgress / NotStarted'),
    Field('percentageClassified', String, 'Percentage Classified',
        hint: 'How much of this domain is classified'),
    Field('highestSensitivityLevel', String, 'Highest Sensitivity',
        hint: 'Highest classification level in this domain'),
    Field('classificationOwner', String, 'Classification Owner',
        hint: 'Who is responsible for classification'),
    Field('lastReview', String, 'Last Review',
        hint: 'When classification was last reviewed'),
  ])
  String? content;
}

/// 1.4.9. Data Integration Points [PD00-CUR-DAT-INT].
///
/// Documentation of data integration points, ETL processes, APIs,
/// and data exchange mechanisms.
@SectionId('DAINPO')
class DataIntegrationPoints {
  @ContentHelp('''
Overview of data integration across the organization. Describe the integration
architecture, major data flows, technologies used, and integration challenges.
''')
  String? content;

  /// Integration summary.
  DataIntegrationSummary integrationSummary = DataIntegrationSummary();

  /// Data flow diagram.
  @ContentType('mermaid-flowchart', 'Diagram showing major data flows '
      'and integration points between systems')
  String? dataFlowDiagram;

  /// Data integration points inventory.
  @SectionId('DAIN-INTE-LST')
  @SectionIdPattern('DAIN-INTE-xxx')
  @Min(1)
  List<DataIntegrationEntry> integrationPoints = [];
}

/// Summary of data integration landscape.
@SectionId('DAINSU')
class DataIntegrationSummary {
  @Form([
    Field('totalIntegrationPoints', int, 'Total Integration Points',
        hint: 'Number of distinct data integration points'),
    Field('integrationArchitecture', String, 'Integration Architecture',
        hint: 'PointToPoint / Hub / ESB / EventDriven / Hybrid'),
    Field('primaryIntegrationTool', String, 'Primary Integration Tool',
        hint: 'Main ETL/integration platform'),
    Field('realtimeIntegrations', int, 'Real-time Integrations',
        hint: 'Number of real-time integrations'),
    Field('batchIntegrations', int, 'Batch Integrations',
        hint: 'Number of batch/scheduled integrations'),
    Field('apiIntegrations', int, 'API Integrations',
        hint: 'Number of API-based integrations'),
    Field('integrationReliability', String, 'Overall Reliability',
        hint: 'Success rate of integrations, e.g. 98.5%'),
    Field('averageLatency', String, 'Average Latency',
        hint: 'Typical integration latency'),
    Field('knownBottlenecks', int, 'Known Bottlenecks',
        hint: 'Number of integration bottlenecks'),
    Field('integrationDebt', String, 'Integration Debt',
        hint: 'Technical debt in integration layer'),
  ])
  String? content;
}

/// A data integration point entry.
@SectionId('DAIN')
class DataIntegrationEntry {
  @Form([
    Field('integrationId', String, 'Integration ID',
        hint: 'Unique identifier', required: true),
    Field('integrationName', String, 'Integration Name',
        hint: 'Name of the integration', required: true),
    Field('description', String, 'Description',
        hint: 'What data is exchanged and why'),
  ])
  String? content;

  /// Endpoints and type.
  DataIntegrationEntryEndpoints endpoints = DataIntegrationEntryEndpoints();

  /// Volume and transport.
  DataIntegrationEntryTransport transport = DataIntegrationEntryTransport();

  /// Reliability and monitoring.
  DataIntegrationEntryReliability reliabilityInfo =
      DataIntegrationEntryReliability();

  /// Ownership and issues.
  DataIntegrationEntryOwnership ownership = DataIntegrationEntryOwnership();
}

/// Endpoints and type for data integration.
@SectionId('DIEE')
class DataIntegrationEntryEndpoints {
  @Form([
    Field('sourceSystem', String, 'Source System',
        hint: 'System providing the data'),
    Field('targetSystem', String, 'Target System',
        hint: 'System receiving the data'),
    Field('integrationType', String, 'Integration Type',
        hint: 'ETL / ELT / API / FileTransfer / EventStream / CDC'),
  ])
  String? content;
}

/// Volume and transport for data integration.
@SectionId('DIET')
class DataIntegrationEntryTransport {
  @Form([
    Field('dataVolume', String, 'Data Volume',
        hint: 'Typical volume per execution'),
    Field('frequency', String, 'Frequency',
        hint: 'RealTime / NearRealTime / Hourly / Daily / Weekly / OnDemand'),
    Field('technology', String, 'Technology',
        hint: 'Integration technology used'),
    Field('protocol', String, 'Protocol',
        hint: 'Communication protocol, e.g. REST, SOAP, SFTP, Kafka'),
    Field('dataTransformation', String, 'Data Transformation',
        hint: 'Type/complexity of transformation'),
  ])
  String? content;
}

/// Reliability and monitoring for data integration.
@SectionId('DIER')
class DataIntegrationEntryReliability {
  @Form([
    Field('errorHandling', String, 'Error Handling',
        hint: 'How errors are handled'),
    Field('monitoringStatus', String, 'Monitoring Status',
        hint: 'None / Basic / Comprehensive'),
    Field('reliability', String, 'Reliability',
        hint: 'Success rate, e.g. 99.2%'),
    Field('latency', String, 'Latency',
        hint: 'Typical latency, e.g. 5 seconds, 2 hours'),
    Field('sla', String, 'SLA',
        hint: 'Service level agreement if defined'),
  ])
  String? content;
}

/// Ownership and issues for data integration.
@SectionId('DIEO')
class DataIntegrationEntryOwnership {
  @Form([
    Field('businessOwner', String, 'Business Owner',
        hint: 'Who owns this integration'),
    Field('technicalOwner', String, 'Technical Owner',
        hint: 'Who maintains this integration'),
    Field('criticality', String, 'Business Criticality',
        hint: 'Critical / High / Medium / Low'),
    Field('knownIssues', String, 'Known Issues',
        hint: 'Current problems with this integration'),
  ])
  String? content;
}

/// 1.4.10. Master Data Management [PD00-CUR-DAT-MDM].
///
/// Master data management practices, golden records, and data
/// synchronization across systems.
@SectionId('MADAMA')
class MasterDataManagement {
  @ContentHelp('''
Overview of master data management in the organization. Describe the MDM
strategy, master data domains, golden record sources, and synchronization
approach.
''')
  String? content;

  /// MDM maturity and status summary.
  MdmSummary mdmSummary = MdmSummary();

  /// Master data domains.
  @SectionId('MSDDO-MAST-LST')
  @SectionIdPattern('MSDDO-MAST-xxx')
  @Min(1)
  List<MasterDataDomainEntry> masterDataDomains = [];
}

/// Summary of MDM status and maturity.
@SectionId('MDSU')
class MdmSummary {
  @Form([
    Field('mdmMaturityLevel', String, 'MDM Maturity Level',
        hint: 'Level 1-5 or Initial/Managed/Defined/Measured/Optimized'),
    Field('mdmStrategy', String, 'MDM Strategy',
        hint: 'Centralized / RegionalHubs / Federated / NoStrategy'),
    Field('mdmPlatform', String, 'MDM Platform',
        hint: 'Technology used for MDM if any'),
    Field('totalMasterDataDomains', int, 'Total Master Data Domains',
        hint: 'Number of defined master data domains'),
    Field('goldenRecordCoverage', String, 'Golden Record Coverage',
        hint: 'Percentage of master data with golden records'),
    Field('dataQualityInMaster', String, 'Master Data Quality',
        hint: 'Quality level of master data'),
    Field('synchronizationApproach', String, 'Synchronization Approach',
        hint: 'How master data is synchronized across systems'),
    Field('dataMatchingCapability', String, 'Data Matching Capability',
        hint: 'Level of deduplication/matching capability'),
    Field('hierarchyManagement', String, 'Hierarchy Management',
        hint: 'How organizational/product hierarchies are managed'),
    Field('mdmGaps', String, 'Key MDM Gaps',
        hint: 'Primary gaps in master data management'),
  ])
  String? content;
}

/// Master data domain entry.
@SectionId('MSDDO')
class MasterDataDomainEntry {
  @Form([
    Field('domainName', String, 'Domain Name',
        hint: 'E.g. Customer, Product, Vendor, Employee, Location', required: true),
    Field('description', String, 'Description',
        hint: 'What this master data domain covers'),
    Field('goldenRecordSource', String, 'Golden Record Source',
        hint: 'Authoritative system for this master data'),
  ])
  String? content;

  /// Volume and quality indicators.
  MasterDataDomainEntryQuality quality = MasterDataDomainEntryQuality();

  /// Downstream usage and cadence.
  MasterDataDomainEntryUsage usage = MasterDataDomainEntryUsage();

  /// Ownership and improvement planning.
  MasterDataDomainEntryGovernance governance =
      MasterDataDomainEntryGovernance();
}

/// Volume and quality indicators for a master data domain.
@SectionId('MDDEQ')
class MasterDataDomainEntryQuality {
  @Form([
    Field('recordCount', String, 'Record Count',
        hint: 'Number of master records'),
    Field('qualityScore', String, 'Quality Score',
        hint: 'Quality of master data in this domain'),
    Field('duplicateRate', String, 'Duplicate Rate',
        hint: 'Estimated duplication, e.g. 3%'),
  ])
  String? content;
}

/// Downstream usage and cadence for a master data domain.
@SectionId('MDDEU')
class MasterDataDomainEntryUsage {
  @Form([
    Field('consumingSystems', String, 'Consuming Systems',
        hint: 'Systems that use this master data'),
    Field('updateFrequency', String, 'Update Frequency',
        hint: 'How often master data is updated'),
    Field('governanceLevel', String, 'Governance Level',
        hint: 'Level of governance for this domain'),
  ])
  String? content;
}

/// Ownership and improvement planning for a master data domain.
@SectionId('MDDEG')
class MasterDataDomainEntryGovernance {
  @Form([
    Field('domainOwner', String, 'Domain Owner',
        hint: 'Who owns this master data domain'),
    Field('dataSteward', String, 'Data Steward',
        hint: 'Steward responsible for data quality'),
    Field('knownIssues', String, 'Known Issues',
        hint: 'Current issues with this master data'),
    Field('improvementPlan', String, 'Improvement Plan',
        hint: 'Plans to improve this domain'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 1.5 Operational Metrics [PD00-CUR-MET]
// ---------------------------------------------------------------------------

/// 1.5. Operational Metrics [PD00-CUR-MET].
///
/// Baseline metrics of the current systems: throughput, volume, uptime,
/// response times, user counts. Used to size the target system and to
/// derive non-functional requirements.
@SectionId('CUOPME')
@DetailedIn(CurrentSituation)
@SecondLevelSectionId(CurrentSituation, 'CS-MET')
class CurrentOperationalMetrics {
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
  String? content;
}

// ---------------------------------------------------------------------------
// 1.6 Current State Risks [PD00-CUR-RIS]
// ---------------------------------------------------------------------------

/// 1.6. Current State Risks [PD00-CUR-RIS].
///
/// Risks tied to the current state and to its replacement. Distinct from
/// PD00-SYO-RIS which covers target-side risks.
@SectionId('CSRA1')
@DetailedIn(CurrentSituation)
@SecondLevelSectionId(CurrentSituation, 'CS-RIS')
class CurrentStateRiskAssessment {
  @ContentHelp('''
Risks that originate from the current systems landscape or from the act of
replacing them. Not to be confused with target-state risks (PD00-SYO-RIS).

**What to capture:**
- Stability / reliability risks of the current systems
- Vendor / contract risks (EOL, licensing, support)
- Knowledge risks (key-person dependencies on legacy systems)
- Data-integrity risks during transition
- Operational-continuity risks (cutover windows, parallel-run exposure)
- Compliance risks of keeping legacy systems in operation
- Replacement-specific risks (scope creep, timeline, migration failures)
''')
  String? content;
}


/// A single integration pattern entry.
@SectionId('INTEG1')
class IntegrationPatternEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}

/// A single shared service entry.
@SectionId('SHARE')
class SharedServiceEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}

/// A single fragile point entry.
@SectionId('FRAGI')
class FragilePointEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}
