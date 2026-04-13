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
  @ContentHelp('''
Target business processes at a high level. Each process will be expanded with
detailed workflows, triggers, decision points, and exception handling in the
BP (Business Processes) document.

**Subsections:**
- Process Vision — overall transformation vision and success criteria
- Design Principles — guiding principles for process design
- Process Catalog — comprehensive process definitions (1+ required)
- Process Overview Diagram — landscape and value chain views
- Improvement Summary — expected benefits and business case

**Seeds:** BP (Business Processes) document
''')
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
/// postconditions in the UC document. Follows Cockburn-style use case modeling.
@SectionId('PD00-TAR-STP')
@Comment('Seeds → UC')
class ProcessStepsAndActorInteractions {
  @ContentHelp('''
Key process steps with their actor interactions. Each interaction will be
expanded into a full use case with alternate paths, preconditions, and
postconditions in the UC (Use Cases) document.

**Subsections:**
- Actor Overview — comprehensive actor definitions with goals and permissions
- Interaction Catalog — use case seeds following Cockburn patterns (1+ required)
- Key Scenarios — end-to-end user journey descriptions (1+ required)

**Best Practices:**
- Follow Cockburn goal levels: +summary, !user, -subfunction
- Use active verb phrases for interaction names ("Submit Registration")
- Include MoSCoW prioritization (must/should/could/won't)
- Map interactions to processes (BP-xxx) and requirements (REQ-xxx)

**Seeds:** UC (Use Cases) document
''')
  String? content;

  /// Section overview.
  ProcessStepsOverview overview = ProcessStepsOverview();

  /// 6.2.1. Actor Overview [PD00-TAR-STP-ACT] — contains 1+× Actor.
  ActorOverview actorOverview = ActorOverview();

  /// 6.2.2. Interaction Catalog [PD00-TAR-STP-INT] — contains 1+× Interaction.
  InteractionCatalog interactionCatalog = InteractionCatalog();

  /// 6.2.3. Key Scenarios [PD00-TAR-STP-SCE] — contains 1+× Scenario.
  KeyScenarios keyScenarios = KeyScenarios();

  /// Actor relationship diagram.
  ActorRelationshipDiagram actorRelationshipDiagram =
      ActorRelationshipDiagram();
}

/// Process steps overview.
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
        'Use Case Naming Convention — UC-xxx pattern'),
    Field('traceabilityApproach', String,
        'Traceability Approach — link to BP, UC documents'),
    Field('detailLevel', String,
        'Detail Level — brief, casual, fully dressed'),
    Field('notationStandard', String,
        'Notation Standard — Cockburn, Fowler, RUP'),
  ])
  String? content;
}

/// Actor relationship diagram.
class ActorRelationshipDiagram {
  /// Diagram overview.
  ActorDiagramOverview overview = ActorDiagramOverview();

  /// Actor hierarchy diagram (generalization relationships).
  FlowDiagramSection actorHierarchy = FlowDiagramSection();

  /// Actor-system interaction overview diagram.
  FlowDiagramSection actorSystemDiagram = FlowDiagramSection();
}

/// Actor diagram overview.
class ActorDiagramOverview {
  @Form([
    Field('diagramPurpose', String,
        'Diagram Purpose — show actor relationships'),
    Field('actorCategories', String,
        'Actor Categories — primary, secondary, supporting'),
    Field('systemBoundary', String, 'System Boundary — what is inside/outside'),
    Field('notation', String, 'Notation — UML use case, custom'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.1 Actor Overview [PD00-TAR-STP-ACT]
// ---------------------------------------------------------------------------

/// 6.2.1. Actor Overview [PD00-TAR-STP-ACT].
///
/// Actors represent roles that interact with the system. Follows UML actor
/// modeling conventions with Cockburn-style goal and scope annotations.
@SectionId('PD00-TAR-STP-ACT')
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
  String? content;

  /// Actor overview narrative.
  ActorOverviewNarrative overview = ActorOverviewNarrative();

  /// Contains 1+× Actor.
  @SectionIdPattern('PD00-TAR-STP-ACT-xx')
  @Min(1)
  List<ActorEntry> actors = [];

  /// Actor categorization summary.
  ActorCategorizationSummary categorization = ActorCategorizationSummary();
}

/// Actor overview narrative.
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
  String? content;
}

/// Actor categorization summary.
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
  String? content;
}

/// An actor entry [PD00-TAR-STP-ACT-nn].
///
/// Comprehensive actor definition following UML and Cockburn conventions.
class ActorEntry {
  /// Actor identification.
  ActorIdentification identification = ActorIdentification();

  /// Actor characteristics.
  ActorCharacteristics characteristics = ActorCharacteristics();

  /// Actor goals (Cockburn style).
  ActorGoals goals = ActorGoals();

  /// Actor permissions and access.
  ActorPermissions permissions = ActorPermissions();

  /// Actor technology profile.
  ActorTechnologyProfile technology = ActorTechnologyProfile();

  /// Actor interactions summary.
  ActorInteractionsSummary interactions = ActorInteractionsSummary();
}

/// Actor identification.
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
  String? content;
}

/// Actor characteristics.
class ActorCharacteristics {
  @Form([
    Field('domainKnowledge', String,
        'Domain Knowledge — expertise level required'),
    Field('technicalSkills', String, 'Technical Skills — IT proficiency'),
    Field('trainingRequired', String, 'Training Required — onboarding needs'),
    Field('usageFrequency', String,
        'Usage Frequency — daily, weekly, monthly, occasional'),
    Field('usageDuration', String,
        'Usage Duration — typical session length'),
    Field('peakUsageTimes', String, 'Peak Usage Times — when most active'),
    Field('taskComplexity', String,
        'Task Complexity — simple, moderate, expert'),
    Field('decisionAuthority', String,
        'Decision Authority — what decisions can be made'),
    Field('supervisionLevel', String,
        'Supervision Level — how closely monitored'),
    Field('communicationPreference', String,
        'Communication Preference — how to reach this actor'),
    Field('languageRequirements', String,
        'Language Requirements — languages needed'),
    Field('accessibilityNeeds', String,
        'Accessibility Needs — special accommodations'),
  ])
  String? content;
}

/// Actor goals (Cockburn-style goal hierarchy).
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
  String? content;
}

/// Actor permissions and access levels.
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
  String? content;
}

/// Actor technology profile.
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
  String? content;
}

/// Actor interactions summary.
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
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.2 Interaction Catalog [PD00-TAR-STP-INT]
// ---------------------------------------------------------------------------

/// 6.2.2. Interaction Catalog [PD00-TAR-STP-INT].
///
/// Container for key interaction descriptions. Each interaction seeds a use
/// case following Cockburn's fully dressed use case template.
@SectionId('PD00-TAR-STP-INT')
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
  String? content;

  /// Interaction catalog overview.
  InteractionCatalogOverview overview = InteractionCatalogOverview();

  /// Contains 1+× Interaction.
  @SectionIdPattern('PD00-TAR-STP-INT-xx')
  @Min(1)
  List<InteractionEntry> interactions = [];

  /// Interaction prioritization matrix.
  InteractionPrioritization prioritization = InteractionPrioritization();
}

/// Interaction catalog overview.
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
  String? content;
}

/// Interaction prioritization matrix.
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
  String? content;
}

/// An interaction entry [PD00-TAR-STP-INT-nn].
///
/// Comprehensive interaction definition following Cockburn's fully dressed
/// use case template. Seeds the UC (Use Case) document.
class InteractionEntry {
  /// Interaction identification (use case header).
  InteractionIdentification identification = InteractionIdentification();

  /// Use case scope and context (Cockburn style).
  UseCaseScopeContext scopeContext = UseCaseScopeContext();

  /// Stakeholders and interests.
  StakeholdersAndInterests stakeholders = StakeholdersAndInterests();

  /// Preconditions and triggers.
  PreconditionsAndTriggers preconditions = PreconditionsAndTriggers();

  /// Postconditions and guarantees.
  PostconditionsAndGuarantees postconditions = PostconditionsAndGuarantees();

  /// Main success scenario (basic flow).
  MainSuccessScenario mainScenario = MainSuccessScenario();

  /// Extensions (alternative and exception flows).
  UseCaseExtensions extensions = UseCaseExtensions();

  /// Technology and data variations.
  TechnologyDataVariations variations = TechnologyDataVariations();

  /// UI requirements preview.
  UIRequirementsPreview uiPreview = UIRequirementsPreview();

  /// Performance and frequency.
  InteractionPerformance performance = InteractionPerformance();

  /// Security and authorization.
  InteractionSecurity security = InteractionSecurity();

  /// Business rules triggered.
  InteractionBusinessRules businessRules = InteractionBusinessRules();

  /// Related elements and traceability.
  InteractionTraceability traceability = InteractionTraceability();
}

/// Interaction identification (use case header).
class InteractionIdentification {
  @Form([
    Field('interactionId', String, 'Interaction ID (e.g., INT-001)',
        required: true),
    Field('useCaseName', String, 'Use Case Name — active verb goal phrase',
        required: true),
    Field('processReference', String, 'Process Reference — BP-xxx'),
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
  String? content;
}

/// Use case scope and context (Cockburn style).
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
  String? content;
}

/// Stakeholders and interests.
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
  String? content;
}

/// Preconditions and triggers.
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
  String? content;
}

/// Postconditions and guarantees.
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
  String? content;
}

/// Main success scenario (basic flow).
class MainSuccessScenario {
  @Form([
    Field('scenarioSummary', String, 'Scenario Summary — overview'),
    Field('estimatedDuration', String,
        'Estimated Duration — typical completion time'),
    Field('stepCount', int, 'Step Count — number of steps'),
  ])
  String? content;

  /// Main scenario steps — contains 1+× Scenario Step.
  @SectionIdPattern('PD00-TAR-STP-INT-xx-MSS-xx')
  @Min(1)
  List<MainScenarioStepEntry> steps = [];
}

/// A main scenario step entry [PD00-TAR-STP-INT-nn-MSS-nn].
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
  String? content;
}

/// Use case extensions (alternative and exception flows).
class UseCaseExtensions {
  @Form([
    Field('extensionSummary', String,
        'Extension Summary — overview of variations'),
    Field('extensionCount', int, 'Extension Count — number of extensions'),
  ])
  String? content;

  /// Extension entries — contains 0+× Extension.
  @SectionIdPattern('PD00-TAR-STP-INT-xx-EXT-xx')
  List<ExtensionEntry> extensions = [];
}

/// An extension entry [PD00-TAR-STP-INT-nn-EXT-nn].
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
  String? content;

  /// Extension steps — contains 0+× Scenario Step.
  @SectionIdPattern('PD00-TAR-STP-INT-xx-EXT-xx-EST-xx')
  List<ExtensionStepEntry> steps = [];
}

/// An extension step entry [PD00-TAR-STP-INT-nn-EXT-nn-EST-nn].
class ExtensionStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number (e.g., 3a1)'),
    Field('action', String, 'Action'),
    Field('response', String, 'Response'),
  ])
  String? content;
}

/// Technology and data variations.
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
  String? content;
}

/// UI requirements preview for this interaction.
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
  String? content;

  /// UI mockup/wireframe reference.
  FlowDiagramSection screenMockup = FlowDiagramSection();
}

/// Interaction performance requirements.
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
  String? content;
}

/// Interaction security requirements.
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
  String? content;
}

/// Business rules triggered by this interaction.
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
  String? content;
}

/// Interaction traceability to other elements.
class InteractionTraceability {
  @Form([
    Field('relatedProcess', String, 'Related Process — BP-xxx'),
    Field('relatedRequirements', String, 'Related Requirements — REQ-xxx'),
    Field('relatedUseCase', String, 'Related Use Case — UC-xxx in UC document'),
    Field('relatedDataEntities', String, 'Related Data Entities — entity names'),
    Field('relatedBusinessObjects', String,
        'Related Business Objects — BO-xxx'),
    Field('relatedBusinessRules', String, 'Related Business Rules — BR-xxx'),
    Field('relatedIntegrations', String, 'Related Integrations — INT-xxx'),
    Field('relatedTestCases', String, 'Related Test Cases — TC-xxx'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.3 Key Scenarios [PD00-TAR-STP-SCE]
// ---------------------------------------------------------------------------

/// 6.2.3. Key Scenarios [PD00-TAR-STP-SCE].
///
/// End-to-end scenario descriptions showing how users achieve business goals
/// through sequences of interactions.
@SectionId('PD00-TAR-STP-SCE')
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
  String? content;

  /// Scenario overview.
  ScenarioOverview overview = ScenarioOverview();

  /// Contains 1+× Scenario.
  @SectionIdPattern('PD00-TAR-STP-SCE-xx')
  @Min(1)
  List<ScenarioEntry> scenarios = [];
}

/// Scenario overview.
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
  String? content;
}

/// A scenario entry [PD00-TAR-STP-SCE-nn].
///
/// Comprehensive scenario definition for end-to-end user journey.
class ScenarioEntry {
  /// Scenario identification.
  ScenarioIdentification identification = ScenarioIdentification();

  /// Scenario context.
  ScenarioContext context = ScenarioContext();

  /// Contains 1+× Scenario Step.
  @SectionIdPattern('PD00-TAR-STP-SCE-xx-SST-xx')
  @Min(1)
  List<ScenarioStepEntry> steps = [];

  /// Alternative flows — contains 0+× Alternative Flow.
  @SectionIdPattern('PD00-TAR-STP-SCE-xx-AFL-xx')
  List<AlternativeFlowEntry> alternativeFlows = [];

  /// Scenario data.
  ScenarioData scenarioData = ScenarioData();

  /// Scenario timing.
  ScenarioTiming timing = ScenarioTiming();

  /// Scenario validation.
  ScenarioValidation validation = ScenarioValidation();
}

/// Scenario identification.
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
  String? content;
}

/// Scenario context.
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
  String? content;
}

/// A scenario step entry [PD00-TAR-STP-SCE-nn-SST-nn].
class ScenarioStepEntry {
  @Form([
    Field('stepNumber', int, 'Step Number', required: true),
    Field('actor', String, 'Actor — who performs this step'),
    Field('action', String, 'Action — what actor does'),
    Field('systemResponse', String, 'System Response — what system does'),
    Field('expectedResult', String, 'Expected Result — observable outcome'),
    Field('interactionReference', String,
        'Interaction Reference — INT-xxx if detailed'),
    Field('dataInvolved', String, 'Data Involved — input/output data'),
    Field('uiElement', String, 'UI Element — screen/component used'),
    Field('decisionPoint', String,
        'Decision Point — if branching occurs here'),
    Field('timing', String, 'Timing — expected duration'),
    Field('notes', String, 'Notes — clarifications'),
  ])
  String? content;
}

/// An alternative flow entry [PD00-TAR-STP-SCE-nn-AFL-nn].
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
  String? content;

  /// Contains 0+× Scenario Step.
  @SectionIdPattern('PD00-TAR-STP-SCE-xx-AFL-xx-AST-xx')
  List<AlternativeStepEntry> steps = [];
}

/// An alternative step entry [PD00-TAR-STP-SCE-nn-AFL-nn-AST-nn].
class AlternativeStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number'),
    Field('action', String, 'Action'),
    Field('response', String, 'Response'),
    Field('expectedResult', String, 'Expected Result'),
  ])
  String? content;
}

/// Scenario data requirements.
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
  String? content;
}

/// Scenario timing expectations.
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
  String? content;
}

/// Scenario validation criteria.
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
  String? content;
}
