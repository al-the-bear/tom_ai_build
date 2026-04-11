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
@SectionId('PD00-CUR-SYS-DEP')
class DependenciesAndIntegrations {
  @Unused()
  String? content;

  /// 1.1.3.1. Dependencies [PD00-CUR-SYS-DEP-DEP].
  Dependencies dependencies = Dependencies();

  /// 1.1.3.2. Integrations [PD00-CUR-SYS-DEP-INT].
  Integrations integrations = Integrations();
}

/// 1.1.3.1. Dependencies [PD00-CUR-SYS-DEP-DEP].
@SectionId('PD00-CUR-SYS-DEP-DEP')
class Dependencies {
  @Unused()
  String? content;

  /// Contains 0+× SystemDependency.
  @SectionIdPattern('PD00-CUR-SYS-DEP-DEP-xx')
  List<SystemDependencyEntry> items = [];
}

/// 1.1.3.2. Integrations [PD00-CUR-SYS-DEP-INT].
@SectionId('PD00-CUR-SYS-DEP-INT')
class Integrations {
  @Unused()
  String? content;

  /// Contains 0+× SystemIntegration.
  @SectionIdPattern('PD00-CUR-SYS-DEP-INT-xx')
  List<SystemIntegrationEntry> items = [];
}

/// A system dependency entry (form) [PD00-CUR-SYS-DEP-DEP-nn].
class SystemDependencyEntry {
  @Form([
    Field('dependencyType', String, 'Dependency Type'),
    Field('criticality', String, 'Criticality'),
  ])
  String? content;

  @Reference('Source System')
  ExistingSystemEntry? sourceSystem;

  @Reference('Target System')
  ExistingSystemEntry? targetSystem;
}

/// A system integration entry (form) [PD00-CUR-SYS-DEP-INT-nn].
class SystemIntegrationEntry {
  @Form([
    Field('protocol', String, 'Protocol'),
    Field('dataExchanged', String, 'Data Exchanged'),
    Field('direction', String, 'Direction'),
    Field('frequency', String, 'Frequency'),
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
      'Include a process map or hierarchy showing how processes relate. '
      'Identify which processes are in scope for this project.')
  String? content;

  /// 1.2.1. Workflow Descriptions [PD00-CUR-PRO-WOR] — contains 1+× Business Process.
  @SectionIdPattern('PD00-CUR-PRO-xx')
  @Min(1)
  List<CurrentBusinessProcess> processes = [];
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
class WorkflowDescriptions {
  @ContentType('description', 'Overview of workflows within this process.')
  @ContentHelp('Describe how the workflows within this process relate to each '
      'other. Include a workflow diagram showing the sequence and decision points.')
  String? content;

  /// Individual workflow entries.
  @SectionIdPattern('PD00-CUR-PRO-xx-WOR-xx')
  @Min(1)
  List<CurrentWorkflowEntry> workflows = [];
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
class GapEntry {
  @Form([
    Field('gapName', String, 'Gap Name', required: true),
    Field('description', String, 'Short description'),
    Field('businessImpact', String, 'Business Impact'),
    Field('affectedProcess', String, 'Affected Process'),
    Field('priority', String, 'Priority level'),
    Field('proposedResolution', String, 'Proposed Resolution'),
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
