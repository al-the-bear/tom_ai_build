/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 1. Current State Analysis [PD00-CUR].
class CurrentStateAnalysis {
  String? content;

  /// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
  ExistingSystemsLandscape existingSystemsLandscape = ExistingSystemsLandscape();

  /// 1.2. Current Business Processes [PD00-CUR-PRO] — contains 1+× Business Process.
  List<CurrentBusinessProcess> currentBusinessProcesses = [];

  /// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
  PainPointsAndGaps painPointsAndGaps = PainPointsAndGaps();

  /// 1.4. Current Data Landscape [PD00-CUR-DAT].
  CurrentDataLandscape currentDataLandscape = CurrentDataLandscape();
}

// ---------------------------------------------------------------------------
// 1.1 Existing Systems Landscape
// ---------------------------------------------------------------------------

/// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
class ExistingSystemsLandscape {
  String? content;

  /// 1.1.1. System Inventory [PD00-CUR-SYS-INV] — contains 1+× Existing System.
  List<ExistingSystemEntry> systems = [];

  /// Current Architecture.
  TextSection currentArchitecture = TextSection();

  /// 1.1.3. Dependencies and Integrations [PD00-CUR-SYS-DEP].
  DependenciesAndIntegrations dependenciesAndIntegrations = DependenciesAndIntegrations();
}

/// An existing system entry [PD00-CUR-SYS-INV-nn] (form).
class ExistingSystemEntry {
  @Form([
    Field('systemName', String, 'System Name', required: true),
    Field('technology', String, 'Technology'),
    Field('purpose', String, 'Purpose'),
    Field('activeUsers', String, 'Active Users'),
    Field('dataVolume', String, 'Data Volume'),
    Field('operationalSince', String, 'Operational Since'),
    Field('supportStatus', String, 'Support Status'),
  ])
  String? content;
  /// Contains 0+× Limitation.
  List<LimitationEntry> knownLimitations = [];
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
class DependenciesAndIntegrations {
  String? content;

  /// 1.1.3.1. Dependencies [PD00-CUR-SYS-DEP-DEP].
  Dependencies dependencies = Dependencies();

  /// 1.1.3.2. Integrations [PD00-CUR-SYS-DEP-INT].
  Integrations integrations = Integrations();
}

/// 1.1.3.1. Dependencies [PD00-CUR-SYS-DEP-DEP].
class Dependencies {
  String? content;
  /// Contains 0+× SystemDependency.
  List<SystemDependencyEntry> items = [];
}

/// 1.1.3.2. Integrations [PD00-CUR-SYS-DEP-INT].
class Integrations {
  String? content;
  /// Contains 0+× SystemIntegration.
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

/// A current business process [PD00-CUR-PRO-nn].
class CurrentBusinessProcess {
  @Form([
    Field('processName', String, 'Process Name', required: true),
  ])
  String? content;

  /// 1.2.nn.1. Workflow Descriptions [PD00-CUR-PRO-WOR] — contains 1+× Workflow.
  List<CurrentWorkflowEntry> workflows = [];

  /// 1.2.nn.2. Process Metrics [PD00-CUR-PRO-MET].
  ProcessMetrics processMetrics = ProcessMetrics();
}

/// A current workflow entry [PD00-CUR-PRO-WOR-nn] (form).
class CurrentWorkflowEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('trigger', String, 'Trigger'),
    Field('output', String, 'Output'),
    Field('cycleTime', String, 'Cycle Time'),
  ])
  String? content;
  /// Contains 0+× WorkflowStep.
  List<WorkflowStepEntry> steps = [];
  /// Contains 0+× WorkflowActor.
  List<WorkflowActorEntry> actors = [];
  /// Contains 0+× WorkflowStep.
  List<WorkflowStepEntry> manualSteps = [];
  /// Contains 0+× WorkflowStep.
  List<WorkflowStepEntry> errorProneSteps = [];
}

/// A workflow step entry (form) [PD00-CUR-PRO-nn-WOR-nn-STP-nn].
class WorkflowStepEntry {
  @Form([
    Field('stepName', String, 'Step Name', required: true),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// A workflow actor entry (form) [PD00-CUR-PRO-nn-WOR-nn-ACT-nn].
class WorkflowActorEntry {
  @Form([
    Field('actorName', String, 'Actor Name', required: true),
    Field('role', String, 'Role'),
  ])
  String? content;
}

/// 1.2.2. Process Metrics [PD00-CUR-PRO-MET].
class ProcessMetrics {
  String? content;
  /// Contains 0+× ProcessMetric.
  List<ProcessMetricEntry> items = [];
}

/// A process metric entry (form) [PD00-CUR-PRO-nn-MET-nn].
class ProcessMetricEntry {
  @Form([
    Field('metricName', String, 'Metric Name', required: true),
    Field('currentValue', String, 'Current Value'),
    Field('unit', String, 'Unit'),
    Field('measurementMethod', String, 'Measurement Method'),
    Field('frequency', String, 'Frequency'),
  ])
  String? content;
  @Reference('Process Reference')
  CurrentBusinessProcess? processReference;
}

// ---------------------------------------------------------------------------
// 1.3 Pain Points and Gaps
// ---------------------------------------------------------------------------

/// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
class PainPointsAndGaps {
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
class OperationalPainPoints {
  String? content;
  /// Contains 0+× PainPoint.
  List<PainPointEntry> items = [];
}

/// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
class BusinessPainPoints {
  String? content;
  /// Contains 0+× PainPoint.
  List<PainPointEntry> items = [];
}

/// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
class TechnicalPainPoints {
  String? content;
  /// Contains 0+× PainPoint.
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
class Gaps {
  String? content;
  /// Contains 0+× Gap.
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
class CurrentDataLandscape {
  String? content;

  /// 1.4.1. Data Source Inventory [PD00-CUR-DAT-SRC] — contains 0+× DataSource.
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
