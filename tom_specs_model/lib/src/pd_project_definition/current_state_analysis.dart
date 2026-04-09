/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;



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

  /// 1.1.2. Current Architecture [PD00-CUR-SYS-ARC].
  String? currentArchitecture;

  /// 1.1.3. Dependencies and Integrations [PD00-CUR-SYS-DEP].
  DependenciesAndIntegrations dependenciesAndIntegrations = DependenciesAndIntegrations();
}

/// An existing system entry [PD00-CUR-SYS-INV-nn] (form).
class ExistingSystemEntry {
  String? content;
  String? systemName;
  String? technology;
  String? purpose;
  String? activeUsers;
  String? dataVolume;
  String? operationalSince;
  String? supportStatus;
  List<LimitationEntry> knownLimitations = [];
}

/// A known limitation of an existing system (form).
class LimitationEntry {
  String? content;
  String? limitation;
  String? impact;
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
  List<SystemDependencyEntry> items = [];
}

/// 1.1.3.2. Integrations [PD00-CUR-SYS-DEP-INT].
class Integrations {
  String? content;
  List<SystemIntegrationEntry> items = [];
}

/// A system dependency entry (form).
class SystemDependencyEntry {
  String? content;
  String? sourceSystem;
  String? targetSystem;
  String? dependencyType;
  String? criticality;
}

/// A system integration entry (form).
class SystemIntegrationEntry {
  String? content;
  String? sourceSystem;
  String? targetSystem;
  String? protocol;
  String? dataExchanged;
  String? direction;
  String? frequency;
}

// ---------------------------------------------------------------------------
// 1.2 Current Business Processes
// ---------------------------------------------------------------------------

/// A current business process [PD00-CUR-PRO-nn].
class CurrentBusinessProcess {
  String? content;

  /// Process name.
  String? processName;

  /// 1.2.nn.1. Workflow Descriptions [PD00-CUR-PRO-WOR] — contains 1+× Workflow.
  List<CurrentWorkflowEntry> workflows = [];

  /// 1.2.nn.2. Process Metrics [PD00-CUR-PRO-MET].
  ProcessMetrics processMetrics = ProcessMetrics();
}

/// A current workflow entry [PD00-CUR-PRO-WOR-nn] (form).
class CurrentWorkflowEntry {
  String? content;
  String? processName;
  String? trigger;
  List<WorkflowStepEntry> steps = [];
  List<WorkflowActorEntry> actors = [];
  String? output;
  String? cycleTime;
  List<WorkflowStepEntry> manualSteps = [];
  List<WorkflowStepEntry> errorProneSteps = [];
}

/// A workflow step entry (form).
class WorkflowStepEntry {
  String? content;
  String? stepName;
  String? description;
}

/// A workflow actor entry (form).
class WorkflowActorEntry {
  String? content;
  String? actorName;
  String? role;
}

/// 1.2.2. Process Metrics [PD00-CUR-PRO-MET].
class ProcessMetrics {
  String? content;
  List<ProcessMetricEntry> items = [];
}

/// A process metric entry (form).
class ProcessMetricEntry {
  String? content;
  String? metricName;
  String? processReference;
  String? currentValue;
  String? unit;
  String? measurementMethod;
  String? frequency;
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
  List<PainPointEntry> items = [];
}

/// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
class BusinessPainPoints {
  String? content;
  List<PainPointEntry> items = [];
}

/// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
class TechnicalPainPoints {
  String? content;
  List<PainPointEntry> items = [];
}

/// A pain point entry (form).
class PainPointEntry {
  String? content;
  String? painPoint;
  String? description;
  String? impact;
  String? affectedProcess;
  String? severity;
  String? workaround;
}

/// 1.3.4. Gaps [PD00-CUR-PAI-GAP].
class Gaps {
  String? content;
  List<GapEntry> items = [];
}

/// A gap entry (form) — a missing capability or feature.
class GapEntry {
  String? content;
  String? gapName;
  String? description;
  String? businessImpact;
  String? affectedProcess;
  String? priority;
  String? proposedResolution;
}

// ---------------------------------------------------------------------------
// 1.4 Current Data Landscape
// ---------------------------------------------------------------------------

/// 1.4. Current Data Landscape [PD00-CUR-DAT].
class CurrentDataLandscape {
  String? content;

  /// 1.4.1. Data Source Inventory [PD00-CUR-DAT-SRC].
  List<DataSourceEntry> dataSources = [];

  /// 1.4.2. Data Quality Assessment [PD00-CUR-DAT-QUA].
  String? dataQualityAssessment;
}

/// A data source entry combining store, format, volume, and quality (form).
class DataSourceEntry {
  String? content;
  String? dataStoreName;
  String? storeType;
  String? technology;
  String? dataFormat;
  String? estimatedVolume;
  String? growthRate;
  String? qualityLevel;
  String? owner;
  String? retentionPolicy;
}
