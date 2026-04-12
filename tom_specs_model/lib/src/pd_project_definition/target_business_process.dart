/// Section 6: Target Business Process Model [PD00-TAR].
///
/// Target business processes the system will support. Splits into process
/// descriptions (seeds → BP) and actor interactions (seeds → UC).
/// Follows BPM best practices (BPMN 2.0, APQC PCF, BPM CBOK).
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// 6. Target Business Process Model [PD00-TAR].
@SectionId('PD00-TAR')
@Comment('Seeds → BP, UC')
class TargetBusinessProcessModel {
  @Unused()
  String? content;

  /// 6.1. Business Process Descriptions [PD00-TAR-PRO]. Seeds → BP.
  @Comment('Seeds → BP')
  BusinessProcessDescriptions businessProcessDescriptions =
      BusinessProcessDescriptions();

  /// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
  @Comment('Seeds → UC')
  ProcessStepsAndActorInteractions processStepsAndActorInteractions =
      ProcessStepsAndActorInteractions();
}

// ---------------------------------------------------------------------------
// 6.1 Business Process Descriptions [PD00-TAR-PRO]
// ---------------------------------------------------------------------------

/// 6.1. Business Process Descriptions [PD00-TAR-PRO].
///
/// Target business processes at a high level. Each process will be expanded
/// with detailed workflows, triggers, decision points, and exception handling
/// in the BP (Business Processes) document.
@SectionId('PD00-TAR-PRO')
@Comment('Seeds → BP')
class BusinessProcessDescriptions {
  @Unused()
  String? content;

  /// 6.1.1. Process Vision [PD00-TAR-PRO-VIS].
  ProcessVision processVision = ProcessVision();

  /// 6.1.2. Design Principles [PD00-TAR-PRO-PRI].
  ProcessDesignPrinciples designPrinciples = ProcessDesignPrinciples();

  /// 6.1.3. Process Catalog [PD00-TAR-PRO-CAT] — contains 1+× Business Process.
  ProcessCatalog processCatalog = ProcessCatalog();

  /// 6.1.4. Process Overview Diagram [PD00-TAR-PRO-FLO].
  ProcessOverviewDiagram processOverviewDiagram = ProcessOverviewDiagram();

  /// 6.1.5. Improvement Summary [PD00-TAR-PRO-IMP].
  ProcessImprovementSummary improvementSummary = ProcessImprovementSummary();

  /// Process relationships and dependencies.
  ProcessRelationships processRelationships = ProcessRelationships();
}

/// 6.1.1. Process Vision [PD00-TAR-PRO-VIS].
///
/// The overall vision for how business processes will work with the new system.
@SectionId('PD00-TAR-PRO-VIS')
class ProcessVision {
  /// Process vision overview.
  ProcessVisionOverview overview = ProcessVisionOverview();

  /// Vision narrative describing the target state.
  TextSection visionNarrative = TextSection();

  /// Expected improvements over current state.
  ExpectedImprovements expectedImprovements = ExpectedImprovements();

  /// Success criteria for process transformation.
  ProcessSuccessCriteria successCriteria = ProcessSuccessCriteria();
}

/// Process vision overview.
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
  String? content;
}

/// Expected improvements from process transformation.
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
  String? content;
}

/// Success criteria for process transformation.
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
  String? content;
}

/// 6.1.2. Design Principles [PD00-TAR-PRO-PRI].
///
/// Principles that guide process design decisions.
@SectionId('PD00-TAR-PRO-PRI')
class ProcessDesignPrinciples {
  /// Design principles overview.
  DesignPrinciplesOverview overview = DesignPrinciplesOverview();

  /// Contains 0+× Design Principle.
  @SectionIdPattern('PD00-TAR-PRO-PRI-xx')
  List<ProcessDesignPrincipleEntry> principles = [];
}

/// Design principles overview.
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
  String? content;
}

/// A process design principle entry (form) [PD00-TAR-PRO-PRI-nn].
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
  String? content;
}

/// 6.1.3. Process Catalog [PD00-TAR-PRO-CAT].
///
/// Container for business process definitions.
@SectionId('PD00-TAR-PRO-CAT')
class ProcessCatalog {
  /// Process catalog overview.
  ProcessCatalogOverview overview = ProcessCatalogOverview();

  /// Process classification scheme.
  ProcessClassification classification = ProcessClassification();

  /// Contains 1+× Business Process.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx')
  @Min(1)
  List<BusinessProcessEntry> processes = [];
}

/// Process catalog overview.
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
  String? content;
}

/// Process classification scheme.
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
  String? content;
}

/// A business process entry [PD00-TAR-PRO-CAT-nn].
///
/// Comprehensive business process definition following BPMN 2.0 concepts.
class BusinessProcessEntry {
  /// Process identification.
  ProcessIdentification identification = ProcessIdentification();

  /// Process characteristics.
  ProcessCharacteristics characteristics = ProcessCharacteristics();

  /// Process triggers and events.
  ProcessTriggers triggers = ProcessTriggers();

  /// Process inputs and outputs.
  ProcessInputsOutputs inputsOutputs = ProcessInputsOutputs();

  /// Roles and responsibilities.
  ProcessRoles roles = ProcessRoles();

  /// Process performance.
  ProcessPerformance performance = ProcessPerformance();

  /// Process controls and compliance.
  ProcessControls controls = ProcessControls();

  /// Technology support.
  ProcessTechnology technology = ProcessTechnology();

  /// Process exceptions.
  ProcessExceptions exceptions = ProcessExceptions();

  /// Process flow preview (high-level).
  FlowDiagramSection processFlowPreview = FlowDiagramSection();
}

/// Process identification.
class ProcessIdentification {
  @Form([
    Field('processId', String, 'Process ID (e.g., BP-001)', required: true),
    Field('processName', String, 'Process Name', required: true),
    Field('processLevel', String,
        'Process Level — L1 (category), L2 (group), L3 (process), L4 (activity)'),
    Field('parentProcess', String,
        'Parent Process — higher-level process this belongs to'),
    Field('processCategory', String,
        'Process Category — operating, management, support'),
    Field('processType', String, 'Process Type — core, enabling, strategic'),
    Field('description', String, 'Description — what the process does'),
    Field('purpose', String, 'Purpose — why the process exists'),
    Field('scope', String, 'Scope — boundaries of the process'),
    Field('processOwner', String, 'Process Owner — accountable role/person'),
    Field('processManager', String,
        'Process Manager — day-to-day responsibility'),
    Field('effectiveDate', String, 'Effective Date — when process is active'),
    Field('version', String, 'Version — process version'),
    Field('status', String, 'Status — draft, approved, active, retired'),
  ])
  String? content;
}

/// Process characteristics.
class ProcessCharacteristics {
  @Form([
    Field('complexity', String, 'Complexity — low, medium, high, very high'),
    Field('frequency', String, 'Frequency — how often the process runs'),
    Field('averageDuration', String,
        'Average Duration — typical end-to-end time'),
    Field('variability', String,
        'Variability — how much process varies by case'),
    Field('criticality', String, 'Criticality — business criticality level'),
    Field('automationLevel', String,
        'Automation Level — percentage automated'),
    Field('straightThroughRate', String,
        'Straight-Through Rate — percentage without human intervention'),
    Field('exceptionRate', String,
        'Exception Rate — percentage requiring manual handling'),
    Field('volumeEstimate', String, 'Volume Estimate — cases per period'),
    Field('seasonality', String, 'Seasonality — peaks and troughs'),
    Field('valueAdded', String, 'Value Added — value contributed'),
    Field('costDriver', String, 'Cost Driver — main cost factors'),
  ])
  String? content;
}

/// Process triggers and events.
class ProcessTriggers {
  /// Main trigger overview.
  TriggerOverview overview = TriggerOverview();

  /// Contains 0+× process trigger.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-TRG-xx')
  List<ProcessTriggerEntry> triggers = [];

  /// Process end events (outcomes).
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-END-xx')
  List<ProcessEndEventEntry> endEvents = [];
}

/// Trigger overview.
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
  String? content;
}

/// A process trigger entry [PD00-TAR-PRO-CAT-nn-TRG-nn].
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
  String? content;
}

/// A process end event entry [PD00-TAR-PRO-CAT-nn-END-nn].
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
  String? content;
}

/// Process inputs and outputs.
class ProcessInputsOutputs {
  /// Inputs overview.
  InputsOutputsOverview overview = InputsOutputsOverview();

  /// Contains 0+× process input.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-INP-xx')
  List<ProcessInputEntry> inputs = [];

  /// Contains 0+× process output.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-OUT-xx')
  List<ProcessOutputEntry> outputs = [];
}

/// Inputs/outputs overview.
class InputsOutputsOverview {
  @Form([
    Field('inputSummary', String, 'Input Summary — overview of required inputs'),
    Field('outputSummary', String,
        'Output Summary — overview of produced outputs'),
    Field('dataFlowSummary', String,
        'Data Flow Summary — how data moves through process'),
  ])
  String? content;
}

/// A process input entry [PD00-TAR-PRO-CAT-nn-INP-nn].
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
  String? content;
}

/// A process output entry [PD00-TAR-PRO-CAT-nn-OUT-nn].
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
  String? content;
}

/// Process roles and responsibilities.
class ProcessRoles {
  /// Roles overview.
  ProcessRolesOverview overview = ProcessRolesOverview();

  /// Contains 0+× process role.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-ROL-xx')
  List<ProcessRoleEntry> roles = [];
}

/// Process roles overview.
class ProcessRolesOverview {
  @Form([
    Field('primaryActor', String, 'Primary Actor — main role executing'),
    Field('processOwner', String, 'Process Owner — accountable for outcomes'),
    Field('supportRoles', String, 'Support Roles — assisting roles'),
    Field('escalationPath', String, 'Escalation Path — who handles issues'),
    Field('raciSummary', String,
        'RACI Summary — responsibility assignment overview'),
  ])
  String? content;
}

/// A process role entry [PD00-TAR-PRO-CAT-nn-ROL-nn].
class ProcessRoleEntry {
  @Form([
    Field('roleId', String, 'Role ID', required: true),
    Field('roleName', String, 'Role Name', required: true),
    Field('raciType', String,
        'RACI Type — Responsible, Accountable, Consulted, Informed'),
    Field('responsibilities', String, 'Responsibilities — what this role does'),
    Field('stepsInvolved', String, 'Steps Involved — which process steps'),
    Field('decisionAuthority', String,
        'Decision Authority — what decisions can be made'),
    Field('skillsRequired', String, 'Skills Required — competencies needed'),
    Field('systemAccess', String, 'System Access — required system permissions'),
    Field('availability', String, 'Availability — when role must be available'),
    Field('backupRole', String, 'Backup Role — who covers absence'),
    Field('handoffTo', String, 'Handoff To — roles this passes work to'),
    Field('handoffFrom', String, 'Handoff From — roles this receives work from'),
  ])
  String? content;
}

/// Process performance metrics.
class ProcessPerformance {
  /// Performance overview.
  ProcessPerformanceOverview overview = ProcessPerformanceOverview();

  /// Contains 0+× performance metric.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-KPI-xx')
  List<ProcessKpiEntry> kpis = [];

  /// Service Level Agreements.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-SLA-xx')
  List<ProcessSlaEntry> slas = [];
}

/// Process performance overview.
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
  String? content;
}

/// A process KPI entry [PD00-TAR-PRO-CAT-nn-KPI-nn].
class ProcessKpiEntry {
  @Form([
    Field('kpiId', String, 'KPI ID', required: true),
    Field('kpiName', String, 'KPI Name', required: true),
    Field('category', String,
        'Category — time, quality, cost, volume, satisfaction'),
    Field('definition', String, 'Definition — how KPI is calculated'),
    Field('unit', String, 'Unit — measurement unit'),
    Field('targetValue', String, 'Target Value — target'),
    Field('thresholds', String, 'Thresholds — green/yellow/red boundaries'),
    Field('dataSource', String, 'Data Source — where data comes from'),
    Field('calculationFrequency', String,
        'Calculation Frequency — how often measured'),
    Field('reportingFrequency', String,
        'Reporting Frequency — how often reported'),
    Field('owner', String, 'Owner — who is accountable'),
    Field('improvementLever', String,
        'Improvement Lever — how to improve this KPI'),
  ])
  String? content;
}

/// A process SLA entry [PD00-TAR-PRO-CAT-nn-SLA-nn].
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
  String? content;
}

/// Process controls and compliance.
class ProcessControls {
  /// Controls overview.
  ProcessControlsOverview overview = ProcessControlsOverview();

  /// Contains 0+× process control.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-CTL-xx')
  List<ProcessControlEntry> controls = [];
}

/// Process controls overview.
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
  String? content;
}

/// A process control entry [PD00-TAR-PRO-CAT-nn-CTL-nn].
class ProcessControlEntry {
  @Form([
    Field('controlId', String, 'Control ID', required: true),
    Field('controlName', String, 'Control Name', required: true),
    Field('controlType', String,
        'Control Type — preventive, detective, corrective'),
    Field('controlCategory', String,
        'Control Category — authorization, validation, reconciliation'),
    Field('controlDescription', String,
        'Control Description — what the control does'),
    Field('riskAddressed', String, 'Risk Addressed — what risk is mitigated'),
    Field('controlOwner', String, 'Control Owner — who is responsible'),
    Field('frequency', String, 'Frequency — how often control operates'),
    Field('automation', String,
        'Automation — manual, semi-automated, fully automated'),
    Field('evidenceProduced', String,
        'Evidence Produced — what documentation is created'),
    Field('testingApproach', String, 'Testing Approach — how control is tested'),
    Field('failureAction', String,
        'Failure Action — what happens if control fails'),
  ])
  String? content;
}

/// Process technology support.
class ProcessTechnology {
  @Form([
    Field('primarySystem', String,
        'Primary System — main system supporting process'),
    Field('supportingSystems', String,
        'Supporting Systems — other systems involved'),
    Field('integrations', String, 'Integrations — system integrations required'),
    Field('automationTools', String,
        'Automation Tools — RPA, workflow, rules engines'),
    Field('dataRepositories', String,
        'Data Repositories — databases, data stores'),
    Field('reportingTools', String, 'Reporting Tools — BI, dashboards'),
    Field('communicationTools', String,
        'Communication Tools — email, notifications'),
    Field('documentManagement', String,
        'Document Management — document storage'),
    Field('mobileCapability', String, 'Mobile Capability — mobile access needs'),
    Field('offlineCapability', String,
        'Offline Capability — offline operation needs'),
    Field('analyticsCapability', String,
        'Analytics Capability — process mining, analytics'),
  ])
  String? content;
}

/// Process exceptions and error handling.
class ProcessExceptions {
  /// Exceptions overview.
  ProcessExceptionsOverview overview = ProcessExceptionsOverview();

  /// Contains 0+× exception scenario.
  @SectionIdPattern('PD00-TAR-PRO-CAT-xx-EXC-xx')
  List<ProcessExceptionEntry> exceptions = [];
}

/// Process exceptions overview.
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
  String? content;
}

/// A process exception entry [PD00-TAR-PRO-CAT-nn-EXC-nn].
class ProcessExceptionEntry {
  @Form([
    Field('exceptionId', String, 'Exception ID', required: true),
    Field('exceptionName', String, 'Exception Name', required: true),
    Field('exceptionType', String,
        'Exception Type — data error, system error, business rule, timeout'),
    Field('triggerCondition', String,
        'Trigger Condition — what causes this exception'),
    Field('probability', String, 'Probability — how often this occurs'),
    Field('impact', String, 'Impact — effect on process/business'),
    Field('detectionMethod', String,
        'Detection Method — how exception is detected'),
    Field('resolutionSteps', String, 'Resolution Steps — how to resolve'),
    Field('resolutionOwner', String, 'Resolution Owner — who resolves'),
    Field('resolutionSla', String, 'Resolution SLA — time to resolve'),
    Field('preventionStrategy', String, 'Prevention Strategy — how to prevent'),
    Field('workArounds', String, 'Workarounds — temporary solutions'),
  ])
  String? content;
}

/// 6.1.4. Process Overview Diagram [PD00-TAR-PRO-FLO].
///
/// High-level process flow diagram showing main processes and relationships.
@SectionId('PD00-TAR-PRO-FLO')
class ProcessOverviewDiagram {
  /// Diagram overview.
  ProcessDiagramOverview overview = ProcessDiagramOverview();

  /// Main process landscape diagram.
  FlowDiagramSection landscapeDiagram = FlowDiagramSection();

  /// Process hierarchy diagram.
  FlowDiagramSection hierarchyDiagram = FlowDiagramSection();

  /// Value chain diagram.
  FlowDiagramSection valueChainDiagram = FlowDiagramSection();
}

/// Process diagram overview.
class ProcessDiagramOverview {
  @Form([
    Field('diagramPurpose', String, 'Diagram Purpose — what the diagram shows'),
    Field('diagramScope', String, 'Diagram Scope — what is included/excluded'),
    Field('notation', String, 'Notation — BPMN, flowchart, swimlane'),
    Field('readingGuide', String,
        'Reading Guide — how to interpret the diagram'),
    Field('legend', String, 'Legend — symbol meanings'),
  ])
  String? content;
}

/// 6.1.5. Improvement Summary [PD00-TAR-PRO-IMP].
///
/// Summary of expected improvements over current processes.
@SectionId('PD00-TAR-PRO-IMP')
class ProcessImprovementSummary {
  /// Improvement overview.
  ImprovementOverview overview = ImprovementOverview();

  /// Contains 0+× improvement item.
  @SectionIdPattern('PD00-TAR-PRO-IMP-xx')
  List<ProcessImprovementEntry> improvements = [];

  /// Business case summary.
  ImprovementBusinessCase businessCase = ImprovementBusinessCase();
}

/// Improvement overview.
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
  String? content;
}

/// A process improvement entry [PD00-TAR-PRO-IMP-nn].
class ProcessImprovementEntry {
  @Form([
    Field('improvementId', String, 'Improvement ID', required: true),
    Field('improvementName', String, 'Improvement Name', required: true),
    Field('category', String,
        'Category — efficiency, quality, cost, experience'),
    Field('currentState', String, 'Current State — baseline measurement'),
    Field('targetState', String, 'Target State — target measurement'),
    Field('improvementPercent', String,
        'Improvement Percent — expected improvement'),
    Field('monetaryBenefit', String, 'Monetary Benefit — financial value'),
    Field('beneficiaries', String, 'Beneficiaries — who benefits'),
    Field('enablers', String, 'Enablers — what makes this possible'),
    Field('dependencies', String, 'Dependencies — what must happen first'),
    Field('risks', String, 'Risks — what could go wrong'),
    Field('measurementMethod', String,
        'Measurement Method — how improvement is verified'),
  ])
  String? content;
}

/// Improvement business case.
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
  String? content;
}

/// Process relationships and dependencies (supplementary section).
@SectionId('PD00-TAR-PRO-REL')
class ProcessRelationships {
  @Unused()
  String? content;

  /// Contains 0+× process relationship.
  @SectionIdPattern('PD00-TAR-PRO-REL-xx')
  List<ProcessRelationshipEntry> relationships = [];
}

/// A process relationship entry [PD00-TAR-PRO-REL-nn].
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
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2 Process Steps and Actor Interactions [PD00-TAR-STP]
// ---------------------------------------------------------------------------

/// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
///
/// Key process steps with their actor interactions. Each interaction will be
/// expanded into a full use case with alternate paths, preconditions, and
/// postconditions in the UC document.
@SectionId('PD00-TAR-STP')
@Comment('Seeds → UC')
class ProcessStepsAndActorInteractions {
  @Unused()
  String? content;

  /// 6.2.1. Actor Overview [PD00-TAR-STP-ACT] — contains 1+× Actor.
  ActorOverview actorOverview = ActorOverview();

  /// 6.2.2. Interaction Catalog [PD00-TAR-STP-INT] — contains 1+× Interaction.
  InteractionCatalog interactionCatalog = InteractionCatalog();

  /// 6.2.3. Key Scenarios [PD00-TAR-STP-SCE] — contains 1+× Scenario.
  KeyScenarios keyScenarios = KeyScenarios();
}

/// 6.2.1. Actor Overview [PD00-TAR-STP-ACT].
@SectionId('PD00-TAR-STP-ACT')
class ActorOverview {
  @Unused()
  String? content;

  /// Contains 1+× Actor.
  @SectionIdPattern('PD00-TAR-STP-ACT-xx')
  @Min(1)
  List<ActorEntry> actors = [];
}

/// An actor entry (form) [PD00-TAR-STP-ACT-nn].
class ActorEntry {
  @Form([
    Field('actorName', String, 'Actor Name', required: true),
    Field('actorType', String, 'Actor Type — human user, system, external'),
    Field('description', String, 'Description'),
    Field('primaryInteractions', String,
        'Primary Interactions — main activities'),
    Field('accessChannel', String,
        'Access Channel — web, mobile, API, desktop'),
  ])
  String? content;
}

/// 6.2.2. Interaction Catalog [PD00-TAR-STP-INT].
@SectionId('PD00-TAR-STP-INT')
class InteractionCatalog {
  @Unused()
  String? content;

  /// Contains 1+× Interaction.
  @SectionIdPattern('PD00-TAR-STP-INT-xx')
  @Min(1)
  List<InteractionEntry> interactions = [];
}

/// An interaction entry (form) [PD00-TAR-STP-INT-nn].
class InteractionEntry {
  @Form([
    Field('interactionId', String, 'Interaction ID', required: true),
    Field('processReference', String, 'Process Reference — BP-xxx'),
    Field('actor', String, 'Actor'),
    Field('action', String, 'Action — what the actor does'),
    Field('systemResponse', String, 'System Response — what system does'),
    Field('expectedOutcome', String, 'Expected Outcome'),
    Field('precondition', String, 'Precondition'),
    Field('postcondition', String, 'Postcondition'),
    Field('relatedUseCase', String, 'Related Use Case — UC reference'),
  ])
  String? content;
}

/// 6.2.3. Key Scenarios [PD00-TAR-STP-SCE].
@SectionId('PD00-TAR-STP-SCE')
class KeyScenarios {
  @Unused()
  String? content;

  /// Contains 1+× Scenario.
  @SectionIdPattern('PD00-TAR-STP-SCE-xx')
  @Min(1)
  List<ScenarioEntry> scenarios = [];
}

/// A scenario entry (description) [PD00-TAR-STP-SCE-nn].
class ScenarioEntry {
  @Form([
    Field('scenarioName', String, 'Scenario Name', required: true),
    Field('description', String, 'Description'),
    Field('successCondition', String, 'Success Condition'),
  ])
  String? content;

  /// Contains 0+× Scenario Step.
  @SectionIdPattern('PD00-TAR-STP-SCE-xx-SST-xx')
  List<ScenarioStepEntry> steps = [];

  /// Alternative flows — contains 0+× Alternative Flow.
  @SectionIdPattern('PD00-TAR-STP-SCE-xx-AFL-xx')
  List<AlternativeFlowEntry> alternativeFlows = [];
}

/// A scenario step entry (form) [PD00-TAR-STP-SCE-nn-SST-nn].
class ScenarioStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number'),
    Field('description', String, 'Description'),
    Field('expectedResult', String, 'Expected Result'),
  ])
  String? content;
}

/// An alternative flow entry (form) [PD00-TAR-STP-SCE-nn-AFL-nn].
class AlternativeFlowEntry {
  @Form([
    Field('flowName', String, 'Flow Name', required: true),
    Field('triggerCondition', String, 'Trigger Condition'),
    Field('outcome', String, 'Outcome'),
    Field('returnPoint', String, 'Return Point'),
  ])
  String? content;

  /// Contains 0+× Scenario Step.
  List<ScenarioStepEntry> steps = [];
}
