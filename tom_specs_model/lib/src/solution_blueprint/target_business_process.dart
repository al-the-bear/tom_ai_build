/// Section 6: Target Business Process Model.
///
/// Target business processes the system will support. Splits into process
/// descriptions (seeds → TOM) and actor interactions (seeds → ISC).
/// Follows BPM best practices (BPMN 2.0, APQC PCF, BPM CBOK).
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 6. Target Business Process Model.
@SectionId('TBPM')
@Comment('Seeds → TOM, ISC')
class TargetBusinessProcessModel {
  @ContentHelp('''
Overview of target business processes the system will support. This section
establishes the process vision, documents key processes with their triggers,
actors, inputs/outputs, and performance expectations, and defines actor
interactions that seed use case development.

**Key Activities:**
- Define process vision and design principles
- Create process catalog with comprehensive process definitions
- Identify actors and their goals, permissions, and technology profiles
- Document key interactions following Cockburn use case patterns
- Map end-to-end scenarios showing user journeys

**Best Practices:**
- Follow BPMN 2.0 notation for process diagrams
- Use APQC Process Classification Framework for process categorization
- Apply Cockburn-style goal levels (summary/user/subfunction)
- Define RACI for all process roles
- Include performance KPIs and SLAs for each process
''')
  @SerializationOrder(0)
  String? content;

  /// 6.1. Business Process Descriptions. Seeds → TOM.
  @Comment('Seeds → TOM')
  @SerializationOrder(1)
  BusinessProcessDescriptions businessProcessDescriptions =
      BusinessProcessDescriptions();

  /// 6.2. Process Steps and Actor Interactions. Seeds → ISC.
  @Comment('Seeds → ISC')
  @SerializationOrder(2)
  ProcessStepsAndActorInteractions processStepsAndActorInteractions =
      ProcessStepsAndActorInteractions();
}

// ---------------------------------------------------------------------------
// 6.1 Business Process Descriptions
// ---------------------------------------------------------------------------

/// 6.1. Business Process Descriptions.
///
/// Target business processes at a high level. Each process will be expanded
/// with detailed workflows, triggers, decision points, and exception handling
/// in the TOM (Target Operating Model) document.
@SectionId('BPDSC')
@Comment('Seeds → TOM')
@MapsTo(D02TargetOperatingModel)
class BusinessProcessDescriptions {
  @ContentHelp('''
Target business processes at a high level. Each process will be expanded with
detailed workflows, triggers, decision points, and exception handling in the
TOM (Target Operating Model) document.

**Subsections:**
- Process Vision — overall transformation vision and success criteria
- Design Principles — guiding principles for process design
- Process Catalog — comprehensive process definitions (1+ required)
- Process Overview Diagram — landscape and value chain views
- Improvement Summary — expected benefits and business case

**Seeds:** TOM (Target Operating Model) document
''')
  @SerializationOrder(0)
  String? content;

  /// 6.1.1. Process Vision.
  @SerializationOrder(1)
  ProcessVision processVision = ProcessVision();

  /// 6.1.2. Design Principles.
  @SerializationOrder(2)
  ProcessDesignPrinciples designPrinciples = ProcessDesignPrinciples();

  /// 6.1.3. Process Catalog — contains 1+× Business Process.
  @SerializationOrder(3)
  ProcessCatalog processCatalog = ProcessCatalog();

  /// 6.1.4. Process Overview Diagram.
  @SerializationOrder(4)
  ProcessOverviewDiagram processOverviewDiagram = ProcessOverviewDiagram();

  /// 6.1.5. Improvement Summary.
  @SerializationOrder(5)
  ProcessImprovementSummary improvementSummary = ProcessImprovementSummary();

  /// 6.1.6. Process Relationships.
  @SerializationOrder(6)
  ProcessRelationships processRelationships = ProcessRelationships();

  /// 6.1.7. Detailed Process Workflows.
  @SectionId('DEPRWO-DETA-LST')
  @SectionIdPattern('DEPRWO-DETA-xxx')
  @SerializationOrder(7)
  List<DetailedProcessWorkflow> detailedWorkflows = [];

  /// 6.1.8. Cross-Process Analysis.
  @SerializationOrder(8)
  CrossProcessAnalysis crossProcessAnalysis = CrossProcessAnalysis();

  /// 6.1.9. Process Exception Handling.
  @SerializationOrder(9)
  ProcessExceptionHandling exceptionHandling = ProcessExceptionHandling();

  /// 6.1.10. Process Metrics and KPIs.
  @SectionId('PMAK-PROC-LST')
  @SectionIdPattern('PMAK-PROC-xxx')
  @SerializationOrder(10)
  List<ProcessMetric> processMetricsAndKpis = [];
}

/// 6.1.1. Process Vision.
///
/// The overall vision for how business processes will work with the new system.
@SectionId('PRVIZ')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-VIS')
class ProcessVision {
  /// Process vision overview.
  @SerializationOrder(0)
  ProcessVisionOverview overview = ProcessVisionOverview();

  /// Vision narrative describing the target state.
  @SerializationOrder(1)
  TextSection visionNarrative = TextSection();

  /// Expected improvements over current state.
  @SectionId('EXIPR-EXPE-LST')
  @SectionIdPattern('EXIPR-EXPE-xxx')
  @SerializationOrder(2)
  List<ExpectedImprovements> expectedImprovements = [];

  /// Success criteria for process transformation.
  @SerializationOrder(3)
  ProcessSuccessCriteria successCriteria = ProcessSuccessCriteria();
}

/// Process vision overview.
@SectionId('PVOVW')
class ProcessVisionOverview {
  @Form([
    Field('visionStatement', String,
        'Vision Statement — concise statement of process future state'),
    Field('strategicAlignment', String,
        'Strategic Alignment — how processes support business strategy'),
    Field('transformationTheme', String,
        'Transformation Theme — overall transformation approach'),
    Field('targetMaturityLevel', String,
        'Target Maturity Level — CMMI or similar maturity target'),
    Field('timeHorizon', String, 'Time Horizon — when full vision is realized'),
    Field('keyEnabler', String,
        'Key Enablers — technology, skills, culture changes needed'),
    Field('changeScope', String,
        'Change Scope — breadth and depth of process change'),
    Field('stakeholderImpact', String,
        'Stakeholder Impact — who is affected and how'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Expected improvements from process transformation.
@SectionId('EXIPR')
class ExpectedImprovements {
  @Form([
    Field('efficiencyGains', String,
        'Efficiency Gains — throughput, cycle time improvements'),
    Field('qualityImprovements', String,
        'Quality Improvements — error reduction, consistency'),
    Field('costReduction', String, 'Cost Reduction — operating cost savings'),
    Field('automationRate', String,
        'Automation Rate — percentage of automated steps'),
    Field('customerExperience', String,
        'Customer Experience — CX improvements'),
    Field('employeeExperience', String,
        'Employee Experience — EX improvements'),
    Field('complianceImprovement', String,
        'Compliance Improvement — regulatory/audit benefits'),
    Field('visibilityGains', String,
        'Visibility Gains — monitoring, reporting improvements'),
    Field('flexibilityGains', String,
        'Flexibility Gains — adaptability to change'),
    Field('integrationBenefits', String,
        'Integration Benefits — data flow, system integration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Success criteria for process transformation.
@SectionId('PRSUC')
class ProcessSuccessCriteria {
  @Form([
    Field('kpiTargets', String, 'KPI Targets — measurable success indicators'),
    Field('timeToValue', String, 'Time to Value — when benefits are realized'),
    Field('adoptionTargets', String,
        'Adoption Targets — user adoption expectations'),
    Field('qualityTargets', String, 'Quality Targets — defect/error rates'),
    Field('performanceTargets', String,
        'Performance Targets — response time, throughput'),
    Field('userSatisfaction', String,
        'User Satisfaction — NPS, satisfaction scores'),
    Field('businessOutcomes', String,
        'Business Outcomes — revenue, market share impact'),
    Field('measurementApproach', String,
        'Measurement Approach — how success is measured'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 6.1.2. Design Principles.
///
/// Principles that guide process design decisions.
@SectionId('PDPRI')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-PRI')
class ProcessDesignPrinciples {
  /// Design principles overview.
  @SerializationOrder(0)
  DesignPrinciplesOverview overview = DesignPrinciplesOverview();

  /// Contains 0+× Design Principle.
  @SectionId('PDPEN-PRIN-LST')
  @SectionIdPattern('PDPEN-PRIN-xxx')
  @SerializationOrder(1)
  List<ProcessDesignPrincipleEntry> principles = [];
}

/// Design principles overview.
@SectionId('DPOVW')
class DesignPrinciplesOverview {
  @Form([
    Field('principlePhilosophy', String,
        'Principle Philosophy — overall approach to process design'),
    Field('priorityOrder', String,
        'Priority Order — how to resolve principle conflicts'),
    Field('exceptionHandling', String,
        'Exception Handling — how deviations are managed'),
    Field('continuousImprovement', String,
        'Continuous Improvement — how processes evolve'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process design principle entry (form).
@SectionId('PDPEN')
class ProcessDesignPrincipleEntry {
  @Form([
    Field('principleId', String, 'Principle ID', required: true),
    Field('principleName', String, 'Principle Name', required: true),
    Field('category', String,
        'Category — efficiency, quality, compliance, user experience'),
    Field('statement', String, 'Statement — the principle statement'),
    Field('rationale', String, 'Rationale — why this principle matters'),
    Field('implications', String,
        'Implications — what this means for process design'),
    Field('examples', String, 'Examples — how this principle applies'),
    Field('tradeoffs', String, 'Trade-offs — what is sacrificed'),
    Field('priority', String, 'Priority — high, medium, low'),
    Field('applicability', String,
        'Applicability — all processes or specific types'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 6.1.3. Process Catalog.
///
/// Container for business process definitions.
@SectionId('PRCAT')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-CAT')
class ProcessCatalog {
  /// Process catalog overview.
  @SerializationOrder(0)
  ProcessCatalogOverview overview = ProcessCatalogOverview();

  /// Process classification scheme.
  @SerializationOrder(1)
  ProcessClassification classification = ProcessClassification();

  /// Contains 1+× Business Process.
  @SectionId('BPREN-PROC-LST')
  @SectionIdPattern('BPREN-PROC-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<BusinessProcessEntry> processes = [];
}

/// Process catalog overview.
@SectionId('PCOVW')
class ProcessCatalogOverview {
  @Form([
    Field('totalProcessCount', int, 'Total Process Count'),
    Field('scopeStatement', String,
        'Scope Statement — what processes are in scope'),
    Field('classificationFramework', String,
        'Classification Framework — APQC PCF, custom'),
    Field('namingConvention', String,
        'Naming Convention — process naming standards'),
    Field('idConvention', String, 'ID Convention — process ID standards'),
    Field('processOwnership', String,
        'Process Ownership — how ownership is assigned'),
    Field('governanceModel', String,
        'Governance Model — change control, approval'),
    Field('versioningApproach', String,
        'Versioning Approach — how process versions are managed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process classification scheme.
@SectionId('PRCCL')
class ProcessClassification {
  @Form([
    Field('level1Categories', String,
        'Level 1 Categories — operating, management, support'),
    Field('level2Breakdown', String,
        'Level 2 Breakdown — major process groups'),
    Field('level3Detail', String, 'Level 3 Detail — specific processes'),
    Field('crossFunctional', String,
        'Cross-Functional — which processes span functions'),
    Field('customerFacing', String,
        'Customer-Facing — which processes touch customers'),
    Field('valueDriving', String, 'Value-Driving — which are core value chain'),
    Field('supportProcesses', String, 'Support Processes — enabling processes'),
    Field('managementProcesses', String,
        'Management Processes — governance, strategy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A business process entry.
///
/// Comprehensive business process definition following BPMN 2.0 concepts.
@SectionId('BPREN')
class BusinessProcessEntry {
  /// Process identification.
  @SerializationOrder(0)
  ProcessIdentification identification = ProcessIdentification();

  /// Process characteristics.
  @SerializationOrder(1)
  ProcessCharacteristics characteristics = ProcessCharacteristics();

  /// Process triggers and events.
  @SerializationOrder(2)
  ProcessTriggers triggers = ProcessTriggers();

  /// Process inputs and outputs.
  @SerializationOrder(3)
  ProcessInputsOutputs inputsOutputs = ProcessInputsOutputs();

  /// Roles and responsibilities.
  @SerializationOrder(4)
  ProcessRoles roles = ProcessRoles();

  /// Process performance.
  @SerializationOrder(5)
  ProcessPerformance performance = ProcessPerformance();

  /// Process controls and compliance.
  @SerializationOrder(6)
  ProcessControls controls = ProcessControls();

  /// Technology support.
  @SerializationOrder(7)
  ProcessTechnology technology = ProcessTechnology();

  /// Process exceptions.
  @SerializationOrder(8)
  ProcessExceptions exceptions = ProcessExceptions();

  /// Process flow preview (high-level).
  @SerializationOrder(9)
  FlowDiagramSection processFlowPreview = FlowDiagramSection();
}

/// Process identification.
@SectionId('PRIDN')
class ProcessIdentification {
  @Form([
    Field('processId', String, 'Process ID (e.g., TOM-001)', required: true),
    Field('processName', String, 'Process Name', required: true),
    Field('processLevel', String,
        'Process Level — L1 (category), L2 (group), L3 (process), L4 (activity)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Position in the process hierarchy and taxonomy.
  @SerializationOrder(1)
  ProcessIdentificationClassification classification =
      ProcessIdentificationClassification();

  /// Narrative description, purpose, and scope.
  @SerializationOrder(2)
  ProcessIdentificationDefinition definition =
      ProcessIdentificationDefinition();

  /// Ownership and lifecycle metadata.
  @SerializationOrder(3)
  ProcessIdentificationGovernance governance =
      ProcessIdentificationGovernance();
}

/// Position in the process hierarchy and taxonomy.
@SectionId('PICLS')
class ProcessIdentificationClassification {
  @Form([
    Field('parentProcess', String,
        'Parent Process — higher-level process this belongs to'),
    Field('processCategory', String,
        'Process Category — operating, management, support'),
    Field('processType', String, 'Process Type — core, enabling, strategic'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Narrative description, purpose, and scope.
@SectionId('PIDEF')
class ProcessIdentificationDefinition {
  @Form([
    Field('description', String, 'Description — what the process does'),
    Field('purpose', String, 'Purpose — why the process exists'),
    Field('scope', String, 'Scope — boundaries of the process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership and lifecycle metadata.
@SectionId('PIGOV')
class ProcessIdentificationGovernance {
  @Form([
    Field('processOwner', String, 'Process Owner — accountable role/person'),
    Field('processManager', String,
        'Process Manager — day-to-day responsibility'),
    Field('effectiveDate', String, 'Effective Date — when process is active'),
    Field('version', String, 'Version — process version'),
    Field('status', String, 'Status — draft, approved, active, retired'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process characteristics.
@SectionId('PRCHR')
class ProcessCharacteristics {
  @Form([
    Field('complexity', String, 'Complexity — low, medium, high, very high'),
    Field('frequency', String, 'Frequency — how often the process runs'),
    Field('averageDuration', String,
        'Average Duration — typical end-to-end time'),
    Field('variability', String,
        'Variability — how much process varies by case'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Operational characteristics and automation level.
  @SerializationOrder(1)
  ProcessCharacteristicsOperations operations =
      ProcessCharacteristicsOperations();

  /// Demand and business value profile.
  @SerializationOrder(2)
  ProcessCharacteristicsBusiness business = ProcessCharacteristicsBusiness();
}

/// Operational characteristics and automation level.
@SectionId('PCOPS')
class ProcessCharacteristicsOperations {
  @Form([
    Field('criticality', String, 'Criticality — business criticality level'),
    Field('automationLevel', String,
        'Automation Level — percentage automated'),
    Field('straightThroughRate', String,
        'Straight-Through Rate — percentage without human intervention'),
    Field('exceptionRate', String,
        'Exception Rate — percentage requiring manual handling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Demand and business value profile.
@SectionId('PCBIZ')
class ProcessCharacteristicsBusiness {
  @Form([
    Field('volumeEstimate', String, 'Volume Estimate — cases per period'),
    Field('seasonality', String, 'Seasonality — peaks and troughs'),
    Field('valueAdded', String, 'Value Added — value contributed'),
    Field('costDriver', String, 'Cost Driver — main cost factors'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process triggers and events.
@SectionId('PRTRG')
class ProcessTriggers {
  /// Main trigger overview.
  @SerializationOrder(0)
  TriggerOverview overview = TriggerOverview();

  /// Contains 0+× process trigger.
  @SectionId('PTREN-TRIG-LST')
  @SectionIdPattern('PTREN-TRIG-xxx')
  @SerializationOrder(1)
  List<ProcessTriggerEntry> triggers = [];

  /// Process end events (outcomes).
  @SectionId('PEEVT-ENDE-LST')
  @SectionIdPattern('PEEVT-ENDE-xxx')
  @SerializationOrder(2)
  List<ProcessEndEventEntry> endEvents = [];
}

/// Trigger overview.
@SectionId('TGOVW')
class TriggerOverview {
  @Form([
    Field('primaryTrigger', String, 'Primary Trigger — main way process starts'),
    Field('triggerChannel', String,
        'Trigger Channel — UI, API, event, schedule'),
    Field('triggerFrequency', String, 'Trigger Frequency — how often triggered'),
    Field('peakTriggerTime', String,
        'Peak Trigger Time — when most triggers occur'),
    Field('preTriggerState', String,
        'Pre-Trigger State — system state before trigger'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process trigger entry.
@SectionId('PTREN')
class ProcessTriggerEntry {
  @Form([
    Field('triggerId', String, 'Trigger ID', required: true),
    Field('triggerName', String, 'Trigger Name', required: true),
    Field('triggerType', String,
        'Trigger Type — user action, system event, timer, message, signal'),
    Field('triggerSource', String, 'Trigger Source — where trigger originates'),
    Field('triggerCondition', String, 'Trigger Condition — when trigger fires'),
    Field('triggerData', String, 'Trigger Data — data provided with trigger'),
    Field('priority', String, 'Priority — processing priority'),
    Field('validationRules', String,
        'Validation Rules — checks before process starts'),
    Field('frequency', String, 'Frequency — expected occurrence rate'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process end event entry.
@SectionId('PEEVT')
class ProcessEndEventEntry {
  @Form([
    Field('endEventId', String, 'End Event ID', required: true),
    Field('endEventName', String, 'End Event Name', required: true),
    Field('endEventType', String,
        'End Event Type — success, error, cancellation, timeout'),
    Field('outcome', String, 'Outcome — what this end state means'),
    Field('probability', String, 'Probability — how often this end occurs'),
    Field('postCondition', String,
        'Post-Condition — system state after this end'),
    Field('notificationAction', String,
        'Notification Action — who/what is notified'),
    Field('followOnAction', String, 'Follow-On Action — what happens next'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process inputs and outputs.
@SectionId('PRINOU')
class ProcessInputsOutputs {
  /// Inputs overview.
  @SerializationOrder(0)
  InputsOutputsOverview overview = InputsOutputsOverview();

  /// Contains 0+× process input.
  @SectionId('PCINP-INPU-LST')
  @SectionIdPattern('PCINP-INPU-xxx')
  @SerializationOrder(1)
  List<ProcessInputEntry> inputs = [];

  /// Contains 0+× process output.
  @SectionId('PCOUT-OUTP-LST')
  @SectionIdPattern('PCOUT-OUTP-xxx')
  @SerializationOrder(2)
  List<ProcessOutputEntry> outputs = [];
}

/// Inputs/outputs overview.
@SectionId('INOUOV')
class InputsOutputsOverview {
  @Form([
    Field('inputSummary', String, 'Input Summary — overview of required inputs'),
    Field('outputSummary', String,
        'Output Summary — overview of produced outputs'),
    Field('dataFlowSummary', String,
        'Data Flow Summary — how data moves through process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process input entry.
@SectionId('PCINP')
class ProcessInputEntry {
  @Form([
    Field('inputId', String, 'Input ID', required: true),
    Field('inputName', String, 'Input Name', required: true),
    Field('inputType', String,
        'Input Type — data, document, authorization, resource'),
    Field('source', String, 'Source — where input comes from'),
    Field('format', String, 'Format — data format, file type'),
    Field('required', String, 'Required — mandatory or optional'),
    Field('validationRules', String, 'Validation Rules — input quality checks'),
    Field('defaultValue', String, 'Default Value — if input not provided'),
    Field('exampleValue', String, 'Example Value — sample input'),
    Field('securityClassification', String,
        'Security Classification — sensitivity level'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process output entry.
@SectionId('PCOUT')
class ProcessOutputEntry {
  @Form([
    Field('outputId', String, 'Output ID', required: true),
    Field('outputName', String, 'Output Name', required: true),
    Field('outputType', String,
        'Output Type — data, document, notification, state change'),
    Field('destination', String, 'Destination — where output goes'),
    Field('format', String, 'Format — data format, file type'),
    Field('qualityStandard', String,
        'Quality Standard — output quality requirements'),
    Field('timingRequirement', String,
        'Timing Requirement — when output must be available'),
    Field('retentionPeriod', String,
        'Retention Period — how long output is kept'),
    Field('securityClassification', String,
        'Security Classification — sensitivity level'),
    Field('dependentProcesses', String,
        'Dependent Processes — processes that need this output'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process roles and responsibilities.
@SectionId('PRRO')
class ProcessRoles {
  /// Roles overview.
  @SerializationOrder(0)
  ProcessRolesOverview overview = ProcessRolesOverview();

  /// Contains 0+× process role.
  @SectionId('PCROL-ROLE-LST')
  @SectionIdPattern('PCROL-ROLE-xxx')
  @SerializationOrder(1)
  List<ProcessRoleEntry> roles = [];
}

/// Process roles overview.
@SectionId('PRROOV')
class ProcessRolesOverview {
  @Form([
    Field('primaryActor', String, 'Primary Actor — main role executing'),
    Field('processOwner', String, 'Process Owner — accountable for outcomes'),
    Field('supportRoles', String, 'Support Roles — assisting roles'),
    Field('escalationPath', String, 'Escalation Path — who handles issues'),
    Field('raciSummary', String,
        'RACI Summary — responsibility assignment overview'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process role entry.
@SectionId('PCROL')
class ProcessRoleEntry {
  @Form([
    Field('roleId', String, 'Role ID', required: true),
    Field('roleName', String, 'Role Name', required: true),
    Field('raciType', String,
        'RACI Type — Responsible, Accountable, Consulted, Informed'),
    Field('responsibilities', String, 'Responsibilities — what this role does'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Process participation and authority.
  @SerializationOrder(1)
  ProcessRoleEntryExecution execution = ProcessRoleEntryExecution();

  /// Access, coverage, and handoff expectations.
  @SerializationOrder(2)
  ProcessRoleEntryCoordination coordination =
      ProcessRoleEntryCoordination();
}

/// Process participation and authority.
@SectionId('PREE')
class ProcessRoleEntryExecution {
  @Form([
    Field('stepsInvolved', String, 'Steps Involved — which process steps'),
    Field('decisionAuthority', String,
        'Decision Authority — what decisions can be made'),
    Field('skillsRequired', String, 'Skills Required — competencies needed'),
    Field('systemAccess', String, 'System Access — required system permissions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access, coverage, and handoff expectations.
@SectionId('PREC')
class ProcessRoleEntryCoordination {
  @Form([
    Field('availability', String, 'Availability — when role must be available'),
    Field('backupRole', String, 'Backup Role — who covers absence'),
    Field('handoffTo', String, 'Handoff To — roles this passes work to'),
    Field('handoffFrom', String, 'Handoff From — roles this receives work from'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process performance metrics.
@SectionId('PP')
class ProcessPerformance {
  /// Performance overview.
  @SerializationOrder(0)
  ProcessPerformanceOverview overview = ProcessPerformanceOverview();

  /// Contains 0+× performance metric.
  @SectionId('PCKPI-KPIS-LST')
  @SectionIdPattern('PCKPI-KPIS-xxx')
  @SerializationOrder(1)
  List<ProcessKpiEntry> kpis = [];

  /// Service Level Agreements.
  @SectionId('PCSLA-SLAS-LST')
  @SectionIdPattern('PCSLA-SLAS-xxx')
  @SerializationOrder(2)
  List<ProcessSlaEntry> slas = [];
}

/// Process performance overview.
@SectionId('PRPEOV')
class ProcessPerformanceOverview {
  @Form([
    Field('targetCycleTime', String,
        'Target Cycle Time — expected end-to-end duration'),
    Field('targetThroughput', String,
        'Target Throughput — expected cases per period'),
    Field('targetQuality', String,
        'Target Quality — error rate, first-time-right'),
    Field('targetCost', String, 'Target Cost — cost per transaction'),
    Field('targetCustomerSat', String,
        'Target Customer Satisfaction — CSAT/NPS target'),
    Field('monitoringFrequency', String,
        'Monitoring Frequency — how often metrics reviewed'),
    Field('dashboardLocation', String,
        'Dashboard Location — where metrics are visible'),
    Field('improvementGoals', String, 'Improvement Goals — targets for next period'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process KPI entry.
@SectionId('PCKPI')
class ProcessKpiEntry {
  @Form([
    Field('kpiId', String, 'KPI ID', required: true),
    Field('kpiName', String, 'KPI Name', required: true),
    Field('category', String,
        'Category — time, quality, cost, volume, satisfaction'),
    Field('definition', String, 'Definition — how KPI is calculated'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Measurement targets and thresholds.
  @SerializationOrder(1)
  ProcessKpiEntryMeasurement measurement = ProcessKpiEntryMeasurement();

  /// Reporting ownership and improvement use.
  @SerializationOrder(2)
  ProcessKpiEntryOperations operations = ProcessKpiEntryOperations();
}

/// Measurement targets and thresholds.
@SectionId('PKEM')
class ProcessKpiEntryMeasurement {
  @Form([
    Field('unit', String, 'Unit — measurement unit'),
    Field('targetValue', String, 'Target Value — target'),
    Field('thresholds', String, 'Thresholds — green/yellow/red boundaries'),
    Field('dataSource', String, 'Data Source — where data comes from'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting ownership and improvement use.
@SectionId('PKEO')
class ProcessKpiEntryOperations {
  @Form([
    Field('calculationFrequency', String,
        'Calculation Frequency — how often measured'),
    Field('reportingFrequency', String,
        'Reporting Frequency — how often reported'),
    Field('owner', String, 'Owner — who is accountable'),
    Field('improvementLever', String,
        'Improvement Lever — how to improve this KPI'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process SLA entry.
@SectionId('PCSLA')
class ProcessSlaEntry {
  @Form([
    Field('slaId', String, 'SLA ID', required: true),
    Field('slaName', String, 'SLA Name', required: true),
    Field('serviceDescription', String,
        'Service Description — what is promised'),
    Field('targetLevel', String, 'Target Level — commitment'),
    Field('measurementMethod', String,
        'Measurement Method — how compliance measured'),
    Field('reportingPeriod', String, 'Reporting Period — measurement window'),
    Field('penaltyClause', String, 'Penalty Clause — consequence of breach'),
    Field('escalationProcedure', String,
        'Escalation Procedure — when SLA at risk'),
    Field('exclusions', String, 'Exclusions — what is not covered'),
    Field('reviewFrequency', String, 'Review Frequency — when SLA is reviewed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process controls and compliance.
@SectionId('PRCO')
class ProcessControls {
  /// Controls overview.
  @SerializationOrder(0)
  ProcessControlsOverview overview = ProcessControlsOverview();

  /// Contains 0+× process control.
  @SectionId('PCCTL-CONT-LST')
  @SectionIdPattern('PCCTL-CONT-xxx')
  @SerializationOrder(1)
  List<ProcessControlEntry> controls = [];
}

/// Process controls overview.
@SectionId('PRCOOV')
class ProcessControlsOverview {
  @Form([
    Field('controlFramework', String,
        'Control Framework — COSO, COBIT, custom'),
    Field('riskLevel', String, 'Risk Level — inherent risk'),
    Field('complianceRequirements', String,
        'Compliance Requirements — regulations, standards'),
    Field('auditFrequency', String, 'Audit Frequency — when audited'),
    Field('segregationOfDuties', String,
        'Segregation of Duties — duty separation rules'),
    Field('approvalMatrix', String, 'Approval Matrix — who approves what'),
    Field('documentationRequirements', String,
        'Documentation Requirements — what must be recorded'),
    Field('retentionRequirements', String,
        'Retention Requirements — how long to keep records'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process control entry.
@SectionId('PCCTL')
class ProcessControlEntry {
  @Form([
    Field('controlId', String, 'Control ID', required: true),
    Field('controlName', String, 'Control Name', required: true),
    Field('controlType', String,
        'Control Type — preventive, detective, corrective'),
    Field('controlCategory', String,
        'Control Category — authorization, validation, reconciliation'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Control operation and ownership.
  @SerializationOrder(1)
  ProcessControlEntryOperation operation = ProcessControlEntryOperation();

  /// Evidence, testing, and failure handling.
  @SerializationOrder(2)
  ProcessControlEntryVerification verification =
      ProcessControlEntryVerification();
}

/// Control operation and ownership.
@SectionId('PCEO')
class ProcessControlEntryOperation {
  @Form([
    Field('controlDescription', String,
        'Control Description — what the control does'),
    Field('riskAddressed', String, 'Risk Addressed — what risk is mitigated'),
    Field('controlOwner', String, 'Control Owner — who is responsible'),
    Field('frequency', String, 'Frequency — how often control operates'),
    Field('automation', String,
        'Automation — manual, semi-automated, fully automated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Evidence, testing, and failure handling.
@SectionId('PCEV')
class ProcessControlEntryVerification {
  @Form([
    Field('evidenceProduced', String,
        'Evidence Produced — what documentation is created'),
    Field('testingApproach', String, 'Testing Approach — how control is tested'),
    Field('failureAction', String,
        'Failure Action — what happens if control fails'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process technology support.
@SectionId('PRTE')
class ProcessTechnology {
  @Form([
    Field('primarySystem', String,
        'Primary System — main system supporting process'),
    Field('supportingSystems', String,
        'Supporting Systems — other systems involved'),
    Field('integrations', String, 'Integrations — system integrations required'),
    Field('automationTools', String,
        'Automation Tools — RPA, workflow, rules engines'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data, reporting, and document tooling.
  @SerializationOrder(1)
  ProcessTechnologyInformation information = ProcessTechnologyInformation();

  /// Access channel and analytics capabilities.
  @SerializationOrder(2)
  ProcessTechnologyExperience experience = ProcessTechnologyExperience();
}

/// Data, reporting, and document tooling.
@SectionId('PRTEIN')
class ProcessTechnologyInformation {
  @Form([
  Field('dataRepositories', String,
    'Data Repositories — databases, data stores'),
  Field('reportingTools', String, 'Reporting Tools — BI, dashboards'),
  Field('communicationTools', String,
    'Communication Tools — email, notifications'),
  Field('documentManagement', String,
    'Document Management — document storage'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access channel and analytics capabilities.
@SectionId('PRTEEX')
class ProcessTechnologyExperience {
  @Form([
  Field('mobileCapability', String, 'Mobile Capability — mobile access needs'),
  Field('offlineCapability', String,
    'Offline Capability — offline operation needs'),
  Field('analyticsCapability', String,
    'Analytics Capability — process mining, analytics'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process exceptions and error handling.
@SectionId('PREX')
class ProcessExceptions {
  /// Exceptions overview.
  @SerializationOrder(0)
  ProcessExceptionsOverview overview = ProcessExceptionsOverview();

  /// Contains 0+× exception scenario.
  @SectionId('PCEXC-EXCE-LST')
  @SectionIdPattern('PCEXC-EXCE-xxx')
  @SerializationOrder(1)
  List<ProcessExceptionEntry> exceptions = [];
}

/// Process exceptions overview.
@SectionId('PREXOV')
class ProcessExceptionsOverview {
  @Form([
    Field('exceptionPhilosophy', String,
        'Exception Philosophy — how exceptions are handled'),
    Field('exceptionRate', String, 'Exception Rate — expected percentage'),
    Field('exceptionRouting', String, 'Exception Routing — where exceptions go'),
    Field('resolutionSla', String, 'Resolution SLA — time to resolve exceptions'),
    Field('escalationPath', String, 'Escalation Path — who handles escalations'),
    Field('rootCauseAnalysis', String,
        'Root Cause Analysis — how causes are identified'),
    Field('continuousImprovement', String,
        'Continuous Improvement — how exceptions drive change'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process exception entry.
@SectionId('PCEXC')
class ProcessExceptionEntry {
  @Form([
    Field('exceptionId', String, 'Exception ID', required: true),
    Field('exceptionName', String, 'Exception Name', required: true),
    Field('exceptionType', String,
        'Exception Type — data error, system error, business rule, timeout'),
    Field('triggerCondition', String,
        'Trigger Condition — what causes this exception'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Likelihood, impact, and detection.
  @SerializationOrder(1)
  ProcessExceptionEntryAssessment assessment =
      ProcessExceptionEntryAssessment();

  /// Resolution and prevention approach.
  @SerializationOrder(2)
  ProcessExceptionEntryResponse response = ProcessExceptionEntryResponse();
}

/// Likelihood, impact, and detection.
@SectionId('PEEA')
class ProcessExceptionEntryAssessment {
  @Form([
    Field('probability', String, 'Probability — how often this occurs'),
    Field('impact', String, 'Impact — effect on process/business'),
    Field('detectionMethod', String,
        'Detection Method — how exception is detected'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Resolution and prevention approach.
@SectionId('PEER')
class ProcessExceptionEntryResponse {
  @Form([
    Field('resolutionSteps', String, 'Resolution Steps — how to resolve'),
    Field('resolutionOwner', String, 'Resolution Owner — who resolves'),
    Field('resolutionSla', String, 'Resolution SLA — time to resolve'),
    Field('preventionStrategy', String, 'Prevention Strategy — how to prevent'),
    Field('workArounds', String, 'Workarounds — temporary solutions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 6.1.4. Process Overview Diagram.
///
/// High-level process flow diagram showing main processes and relationships.
@SectionId('PROVDI')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-FLO')
class ProcessOverviewDiagram {
  /// Diagram overview.
  @SerializationOrder(0)
  ProcessDiagramOverview overview = ProcessDiagramOverview();

  /// Main process landscape diagram.
  @SerializationOrder(1)
  FlowDiagramSection landscapeDiagram = FlowDiagramSection();

  /// Process hierarchy diagram.
  @SerializationOrder(2)
  FlowDiagramSection hierarchyDiagram = FlowDiagramSection();

  /// Value chain diagram.
  @SerializationOrder(3)
  FlowDiagramSection valueChainDiagram = FlowDiagramSection();
}

/// Process diagram overview.
@SectionId('PRDIOV')
class ProcessDiagramOverview {
  @Form([
    Field('diagramPurpose', String, 'Diagram Purpose — what the diagram shows'),
    Field('diagramScope', String, 'Diagram Scope — what is included/excluded'),
    Field('notation', String, 'Notation — BPMN, flowchart, swimlane'),
    Field('readingGuide', String,
        'Reading Guide — how to interpret the diagram'),
    Field('legend', String, 'Legend — symbol meanings'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 6.1.5. Improvement Summary.
///
/// Summary of expected improvements over current processes.
@SectionId('PRIMSU')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-IMP')
class ProcessImprovementSummary {
  /// Improvement overview.
  @SerializationOrder(0)
  ImprovementOverview overview = ImprovementOverview();

  /// Contains 0+× improvement item.
  @SectionId('PCIMV-IMPR-LST')
  @SectionIdPattern('PCIMV-IMPR-xxx')
  @SerializationOrder(1)
  List<ProcessImprovementEntry> improvements = [];

  /// Business case summary.
  @SerializationOrder(2)
  ImprovementBusinessCase businessCase = ImprovementBusinessCase();
}

/// Improvement overview.
@SectionId('IMOV')
class ImprovementOverview {
  @Form([
    Field('improvementTheme', String,
        'Improvement Theme — overall improvement approach'),
    Field('baselineDate', String, 'Baseline Date — when current state measured'),
    Field('targetDate', String, 'Target Date — when improvements achieved'),
    Field('benefitRealizationPlan', String,
        'Benefit Realization Plan — how benefits are tracked'),
    Field('changeEnablers', String,
        'Change Enablers — what makes improvement possible'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A process improvement entry.
@SectionId('PCIMV')
class ProcessImprovementEntry {
  @Form([
    Field('improvementId', String, 'Improvement ID', required: true),
    Field('improvementName', String, 'Improvement Name', required: true),
    Field('category', String,
        'Category — efficiency, quality, cost, experience'),
    Field('currentState', String, 'Current State — baseline measurement'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Target outcome and value case.
  @SerializationOrder(1)
  ProcessImprovementEntryBenefits benefits = ProcessImprovementEntryBenefits();

  /// Enablers, dependencies, and verification.
  @SerializationOrder(2)
  ProcessImprovementEntryDelivery delivery = ProcessImprovementEntryDelivery();
}

/// Target outcome and value case.
@SectionId('PIEB')
class ProcessImprovementEntryBenefits {
  @Form([
    Field('targetState', String, 'Target State — target measurement'),
    Field('improvementPercent', String,
        'Improvement Percent — expected improvement'),
    Field('monetaryBenefit', String, 'Monetary Benefit — financial value'),
    Field('beneficiaries', String, 'Beneficiaries — who benefits'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Enablers, dependencies, and verification.
@SectionId('PIED')
class ProcessImprovementEntryDelivery {
  @Form([
    Field('enablers', String, 'Enablers — what makes this possible'),
    Field('dependencies', String, 'Dependencies — what must happen first'),
    Field('risks', String, 'Risks — what could go wrong'),
    Field('measurementMethod', String,
        'Measurement Method — how improvement is verified'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Improvement business case.
@SectionId('IMBUCA')
class ImprovementBusinessCase {
  @Form([
    Field('totalInvestment', String, 'Total Investment — cost of transformation'),
    Field('annualBenefits', String, 'Annual Benefits — yearly value delivered'),
    Field('paybackPeriod', String, 'Payback Period — time to break even'),
    Field('roi', String, 'ROI — return on investment'),
    Field('npv', String, 'NPV — net present value'),
    Field('intangibleBenefits', String,
        'Intangible Benefits — non-financial value'),
    Field('riskAdjustment', String, 'Risk Adjustment — confidence factor'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process relationships and dependencies (supplementary section).
@SectionId('PR')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-REL')
class ProcessRelationships {
  @ContentHelp('''
Process relationships map dependencies, data flows, and sequencing between
processes. Understanding these relationships is critical for integration
design and identifying optimization opportunities.

**Relationship Types:**
- Triggers — one process starts another
- Feeds — output of one becomes input to another
- Depends on — must complete before another starts
- Parallel with — can run concurrently with another

**Best Practices:**
- Map all inter-process data exchanges
- Identify timing dependencies and constraints
- Document API/integration points between processes
- Highlight bottleneck relationships for optimization
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× process relationship.
  @SectionId('PCRLT-RELA-LST')
  @SectionIdPattern('PCRLT-RELA-xxx')
  @SerializationOrder(1)
  List<ProcessRelationshipEntry> relationships = [];
}

/// A process relationship entry.
@SectionId('PCRLT')
class ProcessRelationshipEntry {
  @Form([
    Field('relationshipId', String, 'Relationship ID'),
    Field('sourceProcess', String, 'Source Process'),
    Field('targetProcess', String, 'Target Process'),
    Field('relationshipType', String,
        'Relationship Type — triggers, feeds, depends on, parallel with'),
    Field('dataExchanged', String,
        'Data Exchanged — what flows between processes'),
    Field('timingDependency', String,
        'Timing Dependency — must complete before, can run parallel'),
    Field('frequencyOfInteraction', String,
        'Frequency of Interaction — how often they interact'),
    Field('criticality', String, 'Criticality — how critical is this relationship'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2 Process Steps and Actor Interactions
// ---------------------------------------------------------------------------

/// 6.2. Process Steps and Actor Interactions. Seeds → ISC.
///
/// Key process steps with their actor interactions. Each interaction will be
/// expanded into a full use case with alternate paths, preconditions, and
/// postconditions in the ISC document. Follows Cockburn-style use case modeling.
@SectionId('PSAAI')
@Comment('Seeds → ISC')
@MapsTo(D05InteractionScenarios)
class ProcessStepsAndActorInteractions {
  @ContentHelp('''
Key process steps with their actor interactions. Each interaction will be
expanded into a full use case with alternate paths, preconditions, and
postconditions in the ISC (Interaction Scenarios) document.

**Subsections:**
- Actor Overview — comprehensive actor definitions with goals and permissions
- Interaction Catalog — use case seeds following Cockburn patterns (1+ required)
- Key Scenarios — end-to-end user journey descriptions (1+ required)

**Best Practices:**
- Follow Cockburn goal levels: +summary, !user, -subfunction
- Use active verb phrases for interaction names ("Submit Registration")
- Include MoSCoW prioritization (must/should/could/won't)
- Map interactions to processes (TOM-xxx) and requirements (REQ-xxx)

**Seeds:** ISC (Interaction Scenarios) document
''')
  @SerializationOrder(0)
  String? content;

  /// Section overview.
  @SerializationOrder(1)
  ProcessStepsOverview overview = ProcessStepsOverview();

  /// 6.2.1. Actor Overview — contains 1+× Actor.
  @SerializationOrder(2)
  ActorOverview actorOverview = ActorOverview();

  /// 6.2.2. Interaction Catalog — contains 1+× Interaction.
  @SerializationOrder(3)
  InteractionCatalog interactionCatalog = InteractionCatalog();

  /// 6.2.3. Key Scenarios — contains 1+× Scenario.
  @SerializationOrder(4)
  KeyScenarios keyScenarios = KeyScenarios();

  /// Actor relationship diagram.
  @SerializationOrder(5)
  ActorRelationshipDiagram actorRelationshipDiagram =
      ActorRelationshipDiagram();

  /// 6.2.4. End-to-End Test Scenarios..
  @SectionId('ETETS-ENDT-LST')
  @SectionIdPattern('ETETS-ENDT-xxx')
  @SerializationOrder(6)
  List<EndToEndTestScenario> endToEndTestScenarios = [];

  /// 6.2.5. Use Case Traceability.
  @SerializationOrder(7)
  UseCaseTraceability useCaseTraceability = UseCaseTraceability();
}

/// 6.2. Process Steps Overview.
@SectionId('PRSTOV')
@DetailedIn(D05InteractionScenarios)
@SecondLevelSectionId(D05InteractionScenarios, 'ISC-OVE')
class ProcessStepsOverview {
  @Form([
    Field('useCaseScope', String,
        'Use Case Scope — system, organization, subsystem'),
    Field('primaryActorFocus', String,
        'Primary Actor Focus — main user types'),
    Field('interactionCoverage', String,
        'Interaction Coverage — scope of interactions'),
    Field('scenarioCoverage', String,
        'Scenario Coverage — what scenarios are included'),
    Field('useCaseNamingConvention', String,
        'Use Case Naming Convention — ISC-xxx pattern'),
    Field('traceabilityApproach', String,
        'Traceability Approach — link to TOM, ISC documents'),
    Field('detailLevel', String,
        'Detail Level — brief, casual, fully dressed'),
    Field('notationStandard', String,
        'Notation Standard — Cockburn, Fowler, RUP'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 6.2. Actor Relationship Diagram.
@SectionId('ACREDI')
@DetailedIn(D05InteractionScenarios)
@SecondLevelSectionId(D05InteractionScenarios, 'ISC-DIA')
class ActorRelationshipDiagram {
  /// Diagram overview.
  @SerializationOrder(0)
  ActorDiagramOverview overview = ActorDiagramOverview();

  /// Actor hierarchy diagram (generalization relationships).
  @SerializationOrder(1)
  FlowDiagramSection actorHierarchy = FlowDiagramSection();

  /// Actor-system interaction overview diagram.
  @SerializationOrder(2)
  FlowDiagramSection actorSystemDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 6.1.7 Detailed Process Workflows
// ---------------------------------------------------------------------------

/// 6.1.7. Detailed Process Workflows.
///
/// Per-process workflow detail beyond the catalog overview.
///.
@SectionId('DEPRWO')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-DET')
class DetailedProcessWorkflow {
  @ContentHelp('''
Step-level detail for each process in the catalog: activity sequence,
decision points, handoffs, swim lanes, timing, and system-actor vs human
actor responsibility.

**What to capture:**
- Activity list with inputs / outputs per step
- Decision points with branch conditions
- Handoff points between actors / systems
- Timing expectations and SLAs per step
- Error and exception branches
- BPMN-style diagram per process
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.1.8 Cross-Process Analysis
// ---------------------------------------------------------------------------

/// 6.1.8. Cross-Process Analysis.
///
/// Hand-offs, shared data, and coordination patterns between processes.
///.
@SectionId('CRPRAN')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-CRO')
class CrossProcessAnalysis {
  @ContentHelp('''
Cross-cutting view of how processes interact: shared entities, data
exchanged, synchronization points, and conflicts.

**What to capture:**
- Shared business entities and which processes create / read / update them
- Synchronization points (process A must complete before B)
- Conflict analysis (processes competing for the same resource)
- Event flows between processes
- Matrix view of processes x shared artifacts
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.1.9 Process Exception Handling
// ---------------------------------------------------------------------------

/// 6.1.9. Process Exception Handling.
///
/// Exception flows, escalation paths, and compensation logic. Covers
///
@SectionId('PREXHA')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-EXC')
class ProcessExceptionHandling {
  @ContentHelp('''
Handling of exceptions that interrupt a normal process flow. Distinct
from UI-level error handling — this is about business
process recovery.

**What to capture:**
- Exception catalog (what can go wrong at which step)
- Escalation matrix (who is notified, who decides)
- Compensation / rollback activities
- Retry strategies and timeouts
- Manual-intervention procedures
- Audit requirements for handled exceptions
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.4 End-to-End Test Scenarios
// ---------------------------------------------------------------------------

/// 6.2.4. End-to-End Test Scenarios.
///
/// Test scenarios that exercise complete user journeys across processes
/// and use cases..
@SectionId('ETETS')
@DetailedIn(D05InteractionScenarios)
@SecondLevelSectionId(D05InteractionScenarios, 'ISC-E2E')
class EndToEndTestScenario {
  @ContentHelp('''
End-to-end test scenarios derived from use cases and key user journeys.
Feeds BQP test strategy and the Phase 5 test derivation step.

**What to capture:**
- Scenario catalog (name, user journey, success criteria)
- Actor, data, and system preconditions
- Step-by-step expected behavior
- Variation matrix (happy path + key alternates)
- Exit criteria for each scenario
- Cross-reference to use cases and requirements
''')
  @SerializationOrder(0)
  String? content;
}

/// Actor diagram overview.
@SectionId('ACDIOV')
class ActorDiagramOverview {
  @Form([
    Field('diagramPurpose', String,
        'Diagram Purpose — show actor relationships'),
    Field('actorCategories', String,
        'Actor Categories — primary, secondary, supporting'),
    Field('systemBoundary', String, 'System Boundary — what is inside/outside'),
    Field('notation', String, 'Notation — UML use case, custom'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.1 Actor Overview
// ---------------------------------------------------------------------------

/// 6.2.1. Actor Overview.
///
/// Actors represent roles that interact with the system. Follows UML actor
/// modeling conventions with Cockburn-style goal and scope annotations.
@SectionId('ACOV')
@DetailedIn(D05InteractionScenarios)
@SecondLevelSectionId(D05InteractionScenarios, 'ISC-ACT')
class ActorOverview {
  @ContentHelp('''
Actors represent roles that interact with the system. Following UML actor
modeling conventions with Cockburn-style goal and scope annotations.

**Actor Categories:**
- Primary — actors who initiate interactions to achieve goals
- Secondary — actors who support primary actors
- Offstage — stakeholders with interests but no direct interaction
- System — external systems that interact via APIs/integrations
- Timer/Scheduled — time-triggered automated actors

**For Each Actor Document:**
- Identification (ID, name, type, category, organizational unit)
- Characteristics (skills, usage patterns, accessibility needs)
- Goals (summary/user/subfunction goals, pain points, motivations)
- Permissions (security clearance, RBAC roles, approval limits)
- Technology profile (channels, devices, authentication methods)
''')
  @SerializationOrder(0)
  String? content;

  /// Actor overview narrative.
  @SerializationOrder(1)
  ActorOverviewNarrative overview = ActorOverviewNarrative();

  /// Contains 1+× Actor.
  @SectionId('ACEN-ACTO-LST')
  @SectionIdPattern('ACEN-ACTO-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<ActorEntry> actors = [];

  /// Actor categorization summary.
  @SerializationOrder(3)
  ActorCategorizationSummary categorization = ActorCategorizationSummary();
}

/// Actor overview narrative.
@SectionId('ACOVNA')
class ActorOverviewNarrative {
  @Form([
    Field('totalActorCount', int, 'Total Actor Count'),
    Field('humanActorCount', int, 'Human Actor Count'),
    Field('systemActorCount', int, 'System Actor Count'),
    Field('externalActorCount', int, 'External Actor Count'),
    Field('actorIdentificationApproach', String,
        'Actor Identification Approach — how actors were identified'),
    Field('actorPrioritization', String,
        'Actor Prioritization — which actors are most important'),
    Field('actorGoalAlignment', String,
        'Actor Goal Alignment — how actor goals align with business goals'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Actor categorization summary.
@SectionId('ACCASU')
class ActorCategorizationSummary {
  @Form([
    Field('primaryActors', String,
        'Primary Actors — actors who initiate interactions'),
    Field('secondaryActors', String,
        'Secondary Actors — actors who support primary actors'),
    Field('offstageActors', String,
        'Offstage Actors — stakeholders with interests but no direct interaction'),
    Field('systemActors', String, 'System Actors — external systems'),
    Field('timerActors', String,
        'Timer/Scheduled Actors — time-triggered actions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An actor entry.
///
/// Comprehensive actor definition following UML and Cockburn conventions.
@SectionId('ACEN')
class ActorEntry {
  /// Actor identification.
  @SerializationOrder(0)
  ActorIdentification identification = ActorIdentification();

  /// Actor characteristics.
  @SerializationOrder(1)
  ActorCharacteristics characteristics = ActorCharacteristics();

  /// Actor goals (Cockburn style).
  @SectionId('ACGO-GOAL-LST')
  @SectionIdPattern('ACGO-GOAL-xxx')
  @SerializationOrder(2)
  List<ActorGoals> goals = [];

  /// Actor permissions and access.
  @SectionId('ACPE-PERM-LST')
  @SectionIdPattern('ACPE-PERM-xxx')
  @SerializationOrder(3)
  List<ActorPermissions> permissions = [];

  /// Actor technology profile.
  @SerializationOrder(4)
  ActorTechnologyProfile technology = ActorTechnologyProfile();

  /// Actor interactions summary.
  @SerializationOrder(5)
  ActorInteractionsSummary interactions = ActorInteractionsSummary();
}

/// Actor identification.
@SectionId('ACID')
class ActorIdentification {
  @Form([
    Field('actorId', String, 'Actor ID (e.g., ACT-001)', required: true),
    Field('actorName', String, 'Actor Name', required: true),
    Field('actorType', String,
        'Actor Type — human user, system, external system, scheduled'),
    Field('category', String,
        'Category — primary, secondary, supporting, offstage'),
    Field('description', String, 'Description — role purpose'),
    Field('realWorldExamples', String,
        'Real World Examples — who fills this role'),
    Field('organizationalUnit', String,
        'Organizational Unit — department or team'),
    Field('estimatedCount', String,
        'Estimated Count — how many users in this role'),
    Field('geographicDistribution', String,
        'Geographic Distribution — where actors are located'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Actor characteristics.
@SectionId('ACTCHA')
class ActorCharacteristics {
  @Form([
    Field('domainKnowledge', String,
        'Domain Knowledge — expertise level required'),
    Field('technicalSkills', String, 'Technical Skills — IT proficiency'),
    Field('trainingRequired', String, 'Training Required — onboarding needs'),
    Field('usageFrequency', String,
        'Usage Frequency — daily, weekly, monthly, occasional'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Usage patterns and decision scope.
  @SerializationOrder(1)
  ActorCharacteristicsUsage usage = ActorCharacteristicsUsage();

  /// Communication and accessibility profile.
  @SerializationOrder(2)
  ActorCharacteristicsSupport support = ActorCharacteristicsSupport();
}

/// Usage patterns and decision scope.
@SectionId('ACCHUS')
class ActorCharacteristicsUsage {
  @Form([
  Field('usageDuration', String,
    'Usage Duration — typical session length'),
  Field('peakUsageTimes', String, 'Peak Usage Times — when most active'),
  Field('taskComplexity', String,
    'Task Complexity — simple, moderate, expert'),
  Field('decisionAuthority', String,
    'Decision Authority — what decisions can be made'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication and accessibility profile.
@SectionId('ACCHSU')
class ActorCharacteristicsSupport {
  @Form([
  Field('supervisionLevel', String,
    'Supervision Level — how closely monitored'),
  Field('communicationPreference', String,
    'Communication Preference — how to reach this actor'),
  Field('languageRequirements', String,
    'Language Requirements — languages needed'),
  Field('accessibilityNeeds', String,
    'Accessibility Needs — special accommodations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Actor goals (Cockburn-style goal hierarchy).
@SectionId('ACGO')
class ActorGoals {
  @Form([
    Field('summaryGoals', String,
        'Summary Goals — high-level organizational goals'),
    Field('userGoals', String, 'User Goals — main goals actor wants to achieve'),
    Field('subfunctionGoals', String,
        'Subfunction Goals — supporting goals'),
    Field('successMeasures', String,
        'Success Measures — how actor knows goals are met'),
    Field('failureConcerns', String,
        'Failure Concerns — what actor wants to avoid'),
    Field('motivations', String, 'Motivations — why actor uses the system'),
    Field('painPoints', String, 'Pain Points — current frustrations'),
    Field('desiredImprovements', String,
        'Desired Improvements — what actor wants better'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Actor permissions and access levels.
@SectionId('ACPE')
class ActorPermissions {
  @Form([
    Field('securityClearance', String,
        'Security Clearance — data access level'),
    Field('roleBasedPermissions', String,
        'Role-Based Permissions — RBAC roles'),
    Field('dataAccessScope', String,
        'Data Access Scope — own, team, department, all'),
    Field('functionalPermissions', String,
        'Functional Permissions — what functions can access'),
    Field('approvalLimits', String,
        'Approval Limits — transaction/decision limits'),
    Field('delegationRights', String,
        'Delegation Rights — can delegate to others'),
    Field('temporaryElevation', String,
        'Temporary Elevation — can request higher access'),
    Field('auditRequirements', String,
        'Audit Requirements — what actions are logged'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Actor technology profile.
@SectionId('ACTEPR')
class ActorTechnologyProfile {
  @Form([
    Field('primaryAccessChannel', String,
        'Primary Access Channel — web, mobile app, desktop, API'),
    Field('secondaryAccessChannels', String,
        'Secondary Access Channels — alternative channels'),
    Field('deviceTypes', String,
        'Device Types — desktop, laptop, tablet, smartphone'),
    Field('operatingSystems', String,
        'Operating Systems — Windows, macOS, iOS, Android'),
    Field('browserRequirements', String, 'Browser Requirements — supported browsers'),
    Field('networkConnectivity', String,
        'Network Connectivity — always online, occasionally offline'),
    Field('bandwidthExpectations', String,
        'Bandwidth Expectations — high-speed, limited'),
    Field('integratedTools', String,
        'Integrated Tools — other tools actor uses'),
    Field('authenticationMethod', String,
        'Authentication Method — password, SSO, MFA, biometric'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Actor interactions summary.
@SectionId('ACINSU')
class ActorInteractionsSummary {
  @Form([
    Field('primaryInteractions', String,
        'Primary Interactions — main use cases'),
    Field('secondaryInteractions', String,
        'Secondary Interactions — supporting use cases'),
    Field('interactionFrequency', String,
        'Interaction Frequency — how often each type'),
    Field('criticalInteractions', String,
        'Critical Interactions — most important'),
    Field('complexInteractions', String,
        'Complex Interactions — most challenging'),
    Field('collaborativeInteractions', String,
        'Collaborative Interactions — involves other actors'),
    Field('handoffPoints', String,
        'Handoff Points — where work passes to others'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.2 Interaction Catalog
// ---------------------------------------------------------------------------

/// 6.2.2. Interaction Catalog.
///
/// Container for key interaction descriptions. Each interaction seeds a use
/// case following Cockburn's fully dressed use case template.
@SectionId('INCA')
@DetailedIn(D05InteractionScenarios)
@SecondLevelSectionId(D05InteractionScenarios, 'ISC-INT')
class InteractionCatalog {
  @ContentHelp('''
Container for key interaction descriptions. Each interaction seeds a use case
following Cockburn's fully dressed use case template.

**For Each Interaction Document:**
- Identification (use case name, goal level, design scope)
- Scope & context (system boundary, assumptions, dependencies)
- Stakeholders & interests (who cares and why)
- Preconditions & triggers (what must be true, what starts it)
- Postconditions & guarantees (minimal + success guarantees)
- Main success scenario (numbered steps with actor/system actions)
- Extensions (alternative and exception flows with branch points)
- UI requirements preview (screens, forms, feedback)
- Performance & security (response time, auth, audit)
- Business rules & traceability (BR-xxx, REQ-xxx references)

**Prioritize Using MoSCoW:**
- Must Have — essential for MVP
- Should Have — important but deferrable
- Could Have — nice to have
- Won't Have — explicitly out of scope
''')
  @SerializationOrder(0)
  String? content;

  /// Interaction catalog overview.
  @SerializationOrder(1)
  InteractionCatalogOverview overview = InteractionCatalogOverview();

  /// Contains 1+× Interaction.
  @SectionId('INEN-INTE-LST')
  @SectionIdPattern('INEN-INTE-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<InteractionEntry> interactions = [];

  /// Interaction prioritization matrix.
  @SerializationOrder(3)
  InteractionPrioritization prioritization = InteractionPrioritization();
}

/// Interaction catalog overview.
@SectionId('INCAOV')
class InteractionCatalogOverview {
  @Form([
    Field('totalInteractionCount', int, 'Total Interaction Count'),
    Field('highPriorityCount', int, 'High Priority Count'),
    Field('mediumPriorityCount', int, 'Medium Priority Count'),
    Field('lowPriorityCount', int, 'Low Priority Count'),
    Field('coverageStatement', String,
        'Coverage Statement — what interactions are covered'),
    Field('identificationMethod', String,
        'Identification Method — how interactions were identified'),
    Field('prioritizationCriteria', String,
        'Prioritization Criteria — how priority was determined'),
    Field('traceabilityToProcesses', String,
        'Traceability to Processes — link to BP section'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction prioritization matrix.
@SectionId('INPR')
class InteractionPrioritization {
  @Form([
    Field('mustHaveInteractions', String,
        'Must-Have Interactions — essential for MVP'),
    Field('shouldHaveInteractions', String,
        'Should-Have Interactions — important but deferrable'),
    Field('couldHaveInteractions', String,
        'Could-Have Interactions — nice to have'),
    Field('wontHaveInteractions', String,
        'Wont-Have Interactions — out of scope'),
    Field('phaseOneInteractions', String, 'Phase One Interactions'),
    Field('phaseTwoInteractions', String, 'Phase Two Interactions'),
    Field('futureInteractions', String, 'Future Interactions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An interaction entry.
///
/// Comprehensive interaction definition following Cockburn's fully dressed
/// use case template. Seeds the ISC (Interaction Scenarios) document.
@SectionId('INEN')
class InteractionEntry {
  /// Interaction identification (use case header).
  @SerializationOrder(0)
  InteractionIdentification identification = InteractionIdentification();

  /// Use case scope and context (Cockburn style).
  @SerializationOrder(1)
  UseCaseScopeContext scopeContext = UseCaseScopeContext();

  /// Stakeholders and interests.
  @SectionId('STANIN-STAK-LST')
  @SectionIdPattern('STANIN-STAK-xxx')
  @SerializationOrder(2)
  List<StakeholdersAndInterests> stakeholders = [];

  /// Preconditions and triggers.
  @SectionId('PRANTR-PREC-LST')
  @SectionIdPattern('PRANTR-PREC-xxx')
  @SerializationOrder(3)
  List<PreconditionsAndTriggers> preconditions = [];

  /// Postconditions and guarantees.
  @SectionId('POANGU-POST-LST')
  @SectionIdPattern('POANGU-POST-xxx')
  @SerializationOrder(4)
  List<PostconditionsAndGuarantees> postconditions = [];

  /// Main success scenario (basic flow).
  @SerializationOrder(5)
  MainSuccessScenario mainScenario = MainSuccessScenario();

  /// Extensions (alternative and exception flows).
  @SerializationOrder(6)
  UseCaseExtensions extensions = UseCaseExtensions();

  /// Technology and data variations.
  @SectionId('TEDAVA-VARI-LST')
  @SectionIdPattern('TEDAVA-VARI-xxx')
  @SerializationOrder(7)
  List<TechnologyDataVariations> variations = [];

  /// UI requirements preview.
  @SerializationOrder(8)
  UIRequirementsPreview uiPreview = UIRequirementsPreview();

  /// Performance and frequency.
  @SerializationOrder(9)
  InteractionPerformance performance = InteractionPerformance();

  /// Security and authorization.
  @SerializationOrder(10)
  InteractionSecurity security = InteractionSecurity();

  /// Business rules triggered.
  @SectionId('INBURU-BUSI-LST')
  @SectionIdPattern('INBURU-BUSI-xxx')
  @SerializationOrder(11)
  List<InteractionBusinessRules> businessRules = [];

  /// Related elements and traceability.
  @SerializationOrder(12)
  InteractionTraceability traceability = InteractionTraceability();
}

/// Interaction identification (use case header).
@SectionId('INID')
class InteractionIdentification {
  @Form([
    Field('interactionId', String, 'Interaction ID (e.g., INT-001)',
        required: true),
    Field('useCaseName', String, 'Use Case Name — active verb goal phrase',
        required: true),
    Field('processReference', String, 'Process Reference — TOM-xxx'),
    Field('briefDescription', String, 'Brief Description — one sentence'),
    Field('fullDescription', String,
        'Full Description — complete explanation'),
    Field('primaryActor', String, 'Primary Actor — who initiates'),
    Field('supportingActors', String,
        'Supporting Actors — who else participates'),
    Field('goalLevel', String,
        'Goal Level — summary (+), user goal (!), subfunction (-)'),
    Field('designScope', String,
        'Design Scope — organization, system, subsystem, component'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Use case scope and context (Cockburn style).
@SectionId('UCSC')
class UseCaseScopeContext {
  @Form([
    Field('systemUnderDiscussion', String,
        'System Under Discussion — SuD name'),
    Field('systemBoundary', String,
        'System Boundary — what is inside/outside'),
    Field('level', String, 'Level — sea level/user goal, fish/subfunction'),
    Field('context', String, 'Context — business context'),
    Field('assumption', String, 'Assumptions — what is assumed true'),
    Field('dependency', String, 'Dependencies — what this depends on'),
    Field('constraint', String, 'Constraints — limitations'),
    Field('relatedUseCases', String, 'Related Use Cases — includes, extends'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Stakeholders and interests.
@SectionId('STANIN')
class StakeholdersAndInterests {
  @Form([
    Field('primaryActorInterest', String,
        'Primary Actor Interest — what they want'),
    Field('systemOwnerInterest', String,
        'System Owner Interest — business value'),
    Field('regulatorInterest', String,
        'Regulator Interest — compliance needs'),
    Field('operationsInterest', String,
        'Operations Interest — operational needs'),
    Field('supportStaffInterest', String,
        'Support Staff Interest — support needs'),
    Field('otherStakeholders', String,
        'Other Stakeholders — additional interested parties'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Preconditions and triggers.
@SectionId('PRANTR')
class PreconditionsAndTriggers {
  @Form([
    Field('precondition', String, 'Preconditions — must be true before'),
    Field('trigger', String, 'Trigger — what initiates this use case'),
    Field('triggerType', String,
        'Trigger Type — user action, system event, timer, message'),
    Field('triggerSource', String, 'Trigger Source — where trigger originates'),
    Field('triggerData', String, 'Trigger Data — data available at trigger'),
    Field('frequencyOfTrigger', String,
        'Frequency of Trigger — how often triggered'),
    Field('validationBeforeStart', String,
        'Validation Before Start — checks before proceeding'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Postconditions and guarantees.
@SectionId('POANGU')
class PostconditionsAndGuarantees {
  @Form([
    Field('minimalGuarantees', String,
        'Minimal Guarantees — always true after, even on failure'),
    Field('successGuarantees', String,
        'Success Guarantees — true after successful completion'),
    Field('primaryActorPostcondition', String,
        'Primary Actor Postcondition — actor state after'),
    Field('systemPostcondition', String,
        'System Postcondition — system state after'),
    Field('dataPostcondition', String, 'Data Postcondition — data changes'),
    Field('notificationsGenerated', String,
        'Notifications Generated — who is notified'),
    Field('auditTrail', String, 'Audit Trail — what is logged'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Main success scenario (basic flow).
@SectionId('MASUSC')
class MainSuccessScenario {
  @Form([
    Field('scenarioSummary', String, 'Scenario Summary — overview'),
    Field('estimatedDuration', String,
        'Estimated Duration — typical completion time'),
    Field('stepCount', int, 'Step Count — number of steps'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Main scenario steps — contains 1+× Scenario Step.
  @SectionId('MNSST-STEP-LST')
  @SectionIdPattern('MNSST-STEP-xxx')
  @Min(1)
  @SerializationOrder(1)
  List<MainScenarioStepEntry> steps = [];
}

/// A main scenario step entry.
@SectionId('MNSST')
class MainScenarioStepEntry {
  @Form([
    Field('stepNumber', int, 'Step Number', required: true),
    Field('actorAction', String, 'Actor Action — what actor does'),
    Field('systemResponse', String, 'System Response — what system does'),
    Field('dataInvolved', String, 'Data Involved — data read/written'),
    Field('businessRuleApplied', String,
        'Business Rule Applied — BR-xxx reference'),
    Field('uiElementUsed', String, 'UI Element Used — screen/component'),
    Field('validationPerformed', String,
        'Validation Performed — checks done'),
    Field('expectedDuration', String,
        'Expected Duration — time for this step'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Use case extensions (alternative and exception flows).
@SectionId('USCAEX')
class UseCaseExtensions {
  @Form([
    Field('extensionSummary', String,
        'Extension Summary — overview of variations'),
    Field('extensionCount', int, 'Extension Count — number of extensions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Extension entries — contains 0+× Extension.
  @SectionId('EXTEN-EXTE-LST')
  @SectionIdPattern('EXTEN-EXTE-xxx')
  @SerializationOrder(1)
  List<ExtensionEntry> extensions = [];
}

/// An extension entry.
@SectionId('EXTEN')
class ExtensionEntry {
  @Form([
    Field('extensionId', String, 'Extension ID (e.g., 3a)', required: true),
    Field('branchPoint', String, 'Branch Point — step number'),
    Field('condition', String, 'Condition — when this extension triggers'),
    Field('extensionType', String,
        'Extension Type — alternative, exception, error'),
    Field('description', String, 'Description — what happens'),
    Field('outcome', String, 'Outcome — how it ends'),
    Field('returnPoint', String,
        'Return Point — step to return to, or end'),
    Field('frequency', String, 'Frequency — how often this occurs'),
    Field('severity', String,
        'Severity — impact level (for exceptions)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Extension steps — contains 0+× Scenario Step.
  @SectionId('EXTST-STEP-LST')
  @SectionIdPattern('EXTST-STEP-xxx')
  @SerializationOrder(1)
  List<ExtensionStepEntry> steps = [];
}

/// An extension step entry.
@SectionId('EXTST')
class ExtensionStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number (e.g., 3a1)'),
    Field('action', String, 'Action'),
    Field('response', String, 'Response'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Technology and data variations.
@SectionId('TEDAVA')
class TechnologyDataVariations {
  @Form([
    Field('dataVariations', String,
        'Data Variations — different data formats, sources'),
    Field('technologyVariations', String,
        'Technology Variations — different platforms, devices'),
    Field('channelVariations', String,
        'Channel Variations — web, mobile, API differences'),
    Field('localizationVariations', String,
        'Localization Variations — language, regional'),
    Field('accessibilityVariations', String,
        'Accessibility Variations — screen reader, keyboard'),
    Field('offlineVariations', String,
        'Offline Variations — handling offline state'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// UI requirements preview for this interaction.
@SectionId('UIRP')
class UIRequirementsPreview {
  @Form([
    Field('primaryScreen', String, 'Primary Screen — main UI screen'),
    Field('screenFlow', String, 'Screen Flow — navigation path'),
    Field('keyFormFields', String, 'Key Form Fields — input fields'),
    Field('keyActions', String, 'Key Actions — buttons, links'),
    Field('keyDisplayElements', String,
        'Key Display Elements — data shown'),
    Field('feedbackMechanisms', String,
        'Feedback Mechanisms — success/error messages'),
    Field('layoutConsiderations', String,
        'Layout Considerations — responsive, orientation'),
    Field('interactionPatterns', String,
        'Interaction Patterns — drag-drop, swipe'),
  ])
  @SerializationOrder(0)
  String? content;

  /// UI mockup/wireframe reference.
  @SerializationOrder(1)
  FlowDiagramSection screenMockup = FlowDiagramSection();
}

/// Interaction performance requirements.
@SectionId('INPE')
class InteractionPerformance {
  @Form([
    Field('expectedFrequency', String,
        'Expected Frequency — times per day/week'),
    Field('peakVolume', String, 'Peak Volume — maximum concurrent'),
    Field('responseTimeTarget', String,
        'Response Time Target — max acceptable'),
    Field('throughputTarget', String,
        'Throughput Target — transactions per second'),
    Field('availabilityRequirement', String,
        'Availability Requirement — uptime needed'),
    Field('concurrencyExpectation', String,
        'Concurrency Expectation — simultaneous users'),
    Field('dataVolumeHandled', String,
        'Data Volume Handled — typical data size'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction security requirements.
@SectionId('INSE')
class InteractionSecurity {
  @Form([
    Field('authenticationRequired', String,
        'Authentication Required — auth needed'),
    Field('authorizationRules', String,
        'Authorization Rules — who can do this'),
    Field('dataClassification', String,
        'Data Classification — sensitivity level'),
    Field('encryptionRequirements', String,
        'Encryption Requirements — data protection'),
    Field('auditLogging', String, 'Audit Logging — what is logged'),
    Field('sessionRequirements', String,
        'Session Requirements — timeout, renewal'),
    Field('complianceRequirements', String,
        'Compliance Requirements — GDPR, HIPAA'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Business rules triggered by this interaction.
@SectionId('INBURU')
class InteractionBusinessRules {
  @Form([
    Field('validationRules', String,
        'Validation Rules — BR-xxx for validation'),
    Field('calculationRules', String,
        'Calculation Rules — BR-xxx for calculations'),
    Field('authorizationRules', String,
        'Authorization Rules — BR-xxx for permissions'),
    Field('workflowRules', String, 'Workflow Rules — BR-xxx for flow'),
    Field('notificationRules', String,
        'Notification Rules — BR-xxx for notifications'),
    Field('integrationRules', String,
        'Integration Rules — BR-xxx for integrations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction traceability to other elements.
@SectionId('INTR')
class InteractionTraceability {
  @Form([
    Field('relatedProcess', String, 'Related Process — TOM-xxx'),
    Field('relatedRequirements', String, 'Related Requirements — REQ-xxx'),
    Field('relatedUseCase', String, 'Related Use Case — ISC-xxx in ISC document'),
    Field('relatedDataEntities', String, 'Related Data Entities — entity names'),
    Field('relatedBusinessObjects', String,
        'Related Business Objects — BO-xxx'),
    Field('relatedBusinessRules', String, 'Related Business Rules — BR-xxx'),
    Field('relatedIntegrations', String, 'Related Integrations — INT-xxx'),
    Field('relatedTestCases', String, 'Related Test Cases — TC-xxx'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.3 Key Scenarios
// ---------------------------------------------------------------------------

/// 6.2.3. Key Scenarios.
///
/// End-to-end scenario descriptions showing how users achieve business goals
/// through sequences of interactions.
@SectionId('KESC')
@DetailedIn(D05InteractionScenarios)
@SecondLevelSectionId(D05InteractionScenarios, 'ISC-SCE')
class KeyScenarios {
  @ContentHelp('''
End-to-end scenario descriptions showing how users achieve business goals
through sequences of interactions. Scenarios bridge the gap between individual
interactions and complete user journeys.

**Scenario Types:**
- Happy path — normal successful completion
- Alternative flow — valid variations from main path
- Exception/error — handling of failures and edge cases

**For Each Scenario Document:**
- Identification (ID, name, type, priority, complexity)
- Context (preconditions, trigger, success/failure conditions)
- Steps (numbered with actor, action, system response, UI element)
- Alternative flows (branch points, conditions, outcomes)
- Data requirements (input/output, test data, transformations)
- Timing (total duration, user time, system time, wait time)
- Validation (acceptance criteria, test scenario references)

**Example Format:**
"A new customer discovers the service, registers, completes verification,
and places their first order."
''')
  @SerializationOrder(0)
  String? content;

  /// Scenario overview.
  @SerializationOrder(1)
  ScenarioOverview overview = ScenarioOverview();

  /// Contains 1+× Scenario.
  @SectionId('SCNRY-SCEN-LST')
  @SectionIdPattern('SCNRY-SCEN-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<ScenarioEntry> scenarios = [];
}

/// Scenario overview.
@SectionId('SCOV')
class ScenarioOverview {
  @Form([
    Field('totalScenarioCount', int, 'Total Scenario Count'),
    Field('scenarioCoverage', String,
        'Scenario Coverage — what user journeys are covered'),
    Field('scenarioTypes', String,
        'Scenario Types — happy path, error handling, edge case'),
    Field('scenarioPrioritization', String,
        'Scenario Prioritization — which are most important'),
    Field('scenarioToTestMapping', String,
        'Scenario to Test Mapping — how scenarios map to tests'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A scenario entry.
///
/// Comprehensive scenario definition for end-to-end user journey.
@SectionId('SCNRY')
class ScenarioEntry {
  /// Scenario identification.
  @SerializationOrder(0)
  ScenarioIdentification identification = ScenarioIdentification();

  /// Scenario context.
  @SerializationOrder(1)
  ScenarioContext context = ScenarioContext();

  /// Contains 1+× Scenario Step.
  @SectionId('SCNST-STEP-LST')
  @SectionIdPattern('SCNST-STEP-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<ScenarioStepEntry> steps = [];

  /// Alternative flows — contains 0+× Alternative Flow.
  @SectionId('ALFL-ALTE-LST')
  @SectionIdPattern('ALFL-ALTE-xxx')
  @SerializationOrder(3)
  List<AlternativeFlowEntry> alternativeFlows = [];

  /// Scenario data.
  @SerializationOrder(4)
  ScenarioData scenarioData = ScenarioData();

  /// Scenario timing.
  @SerializationOrder(5)
  ScenarioTiming timing = ScenarioTiming();

  /// Scenario validation.
  @SerializationOrder(6)
  ScenarioValidation validation = ScenarioValidation();
}

/// Scenario identification.
@SectionId('SCID')
class ScenarioIdentification {
  @Form([
    Field('scenarioId', String, 'Scenario ID (e.g., SCE-001)', required: true),
    Field('scenarioName', String, 'Scenario Name', required: true),
    Field('scenarioType', String,
        'Scenario Type — happy path, alternative, exception'),
    Field('description', String, 'Description — narrative summary'),
    Field('businessGoal', String, 'Business Goal — what is achieved'),
    Field('primaryActor', String, 'Primary Actor — who performs scenario'),
    Field('supportingActors', String, 'Supporting Actors — who else'),
    Field('priority', String, 'Priority — critical, high, medium, low'),
    Field('complexity', String, 'Complexity — simple, moderate, complex'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scenario context.
@SectionId('SCCO')
class ScenarioContext {
  @Form([
    Field('preconditions', String, 'Preconditions — required initial state'),
    Field('trigger', String, 'Trigger — what starts the scenario'),
    Field('successCondition', String,
        'Success Condition — how to know it worked'),
    Field('failureCondition', String,
        'Failure Condition — how to know it failed'),
    Field('assumptions', String, 'Assumptions — what is assumed true'),
    Field('outOfScope', String, 'Out of Scope — what is not included'),
    Field('relatedInteractions', String,
        'Related Interactions — INT-xxx references'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A scenario step entry.
@SectionId('SCNST')
class ScenarioStepEntry {
  @Form([
    Field('stepNumber', int, 'Step Number', required: true),
    Field('actor', String, 'Actor — who performs this step'),
    Field('action', String, 'Action — what actor does'),
    Field('systemResponse', String, 'System Response — what system does'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Expected outcome and referenced artifacts.
  @SerializationOrder(1)
  ScenarioStepEntryContext context = ScenarioStepEntryContext();

  /// Branching, timing, and notes.
  @SerializationOrder(2)
  ScenarioStepEntryExecution execution = ScenarioStepEntryExecution();
}

/// Expected outcome and referenced artifacts.
@SectionId('SSEC')
class ScenarioStepEntryContext {
  @Form([
    Field('expectedResult', String, 'Expected Result — observable outcome'),
    Field('interactionReference', String,
        'Interaction Reference — INT-xxx if detailed'),
    Field('dataInvolved', String, 'Data Involved — input/output data'),
    Field('uiElement', String, 'UI Element — screen/component used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Branching, timing, and notes.
@SectionId('SCSTENEX')
class ScenarioStepEntryExecution {
  @Form([
    Field('decisionPoint', String,
        'Decision Point — if branching occurs here'),
    Field('timing', String, 'Timing — expected duration'),
    Field('notes', String, 'Notes — clarifications'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An alternative flow entry.
@SectionId('ALFL')
class AlternativeFlowEntry {
  @Form([
    Field('flowId', String, 'Flow ID (e.g., AFL-001)', required: true),
    Field('flowName', String, 'Flow Name', required: true),
    Field('flowType', String, 'Flow Type — alternative, exception, error'),
    Field('branchPoint', String, 'Branch Point — step where flow branches'),
    Field('triggerCondition', String, 'Trigger Condition — when this occurs'),
    Field('description', String, 'Description — what happens'),
    Field('outcome', String, 'Outcome — how flow ends'),
    Field('returnPoint', String, 'Return Point — step to return to'),
    Field('frequency', String, 'Frequency — how often this occurs'),
    Field('businessImpact', String, 'Business Impact — effect on business'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Scenario Step.
  @SectionId('ALST-STEP-LST')
  @SectionIdPattern('ALST-STEP-xxx')
  @SerializationOrder(1)
  List<AlternativeStepEntry> steps = [];
}

/// An alternative step entry.
@SectionId('ALST')
class AlternativeStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number'),
    Field('action', String, 'Action'),
    Field('response', String, 'Response'),
    Field('expectedResult', String, 'Expected Result'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scenario data requirements.
@SectionId('SCDA')
class ScenarioData {
  @Form([
    Field('inputData', String, 'Input Data — data needed to start'),
    Field('outputData', String, 'Output Data — data produced'),
    Field('testDataRequirements', String,
        'Test Data Requirements — data for testing'),
    Field('dataTransformations', String,
        'Data Transformations — how data changes'),
    Field('dataValidations', String, 'Data Validations — checks performed'),
    Field('sampleDataValues', String,
        'Sample Data Values — example input/output'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scenario timing expectations.
@SectionId('SCTI')
class ScenarioTiming {
  @Form([
    Field('totalDuration', String, 'Total Duration — end-to-end time'),
    Field('userActiveTime', String, 'User Active Time — user effort'),
    Field('systemProcessingTime', String,
        'System Processing Time — system work'),
    Field('waitTime', String,
        'Wait Time — delays for external factors'),
    Field('timeConstraints', String,
        'Time Constraints — deadlines, SLAs'),
    Field('timeoutHandling', String,
        'Timeout Handling — what if too slow'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scenario validation criteria.
@SectionId('SCVA')
class ScenarioValidation {
  @Form([
    Field('acceptanceCriteria', String,
        'Acceptance Criteria — how success is verified'),
    Field('testScenarios', String, 'Test Scenarios — TC-xxx references'),
    Field('verificationMethod', String,
        'Verification Method — manual, automated'),
    Field('validationData', String, 'Validation Data — data to check'),
    Field('expectedMetrics', String, 'Expected Metrics — performance targets'),
    Field('knownIssues', String, 'Known Issues — documented problems'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.1.10 Process Metrics and KPIs
// ---------------------------------------------------------------------------

/// 6.1.10. Process Metrics and KPIs.
///
/// Process-level KPIs, SLAs, and measurement strategy.
@SectionId('PMAK')
@DetailedIn(D02TargetOperatingModel)
@SecondLevelSectionId(D02TargetOperatingModel, 'TOM-MET')
class ProcessMetric {
  @ContentHelp('''
How each business process is measured for success once in production.

**What to capture:**
- KPI catalog per process (name, formula, target, tolerance)
- Leading vs lagging indicators
- Measurement frequency and data source
- Dashboard / report ownership
- Thresholds for corrective action
- Baseline values for comparison
''')
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.5 Use Case Traceability
// ---------------------------------------------------------------------------

/// 6.2.5. Use Case Traceability.
///
/// Use case ↔ requirement ↔ process ↔ test traceability.
@SectionId('USCATR')
@DetailedIn(D05InteractionScenarios)
@SecondLevelSectionId(D05InteractionScenarios, 'ISC-TRC')
class UseCaseTraceability {
  @ContentHelp('''
Traceability matrix linking use cases to requirements, processes, and
tests. Ensures every use case is justified and covered.

**What to capture:**
- UC × RC matrix (which requirements each use case realizes)
- UC × BP matrix (which processes each use case participates in)
- UC × test matrix (which tests cover each use case)
- Orphan detection (UCs without requirements or tests)
- Change-impact helper (navigate from a changed UC to affected artifacts)
''')
  @SerializationOrder(0)
  String? content;
}
