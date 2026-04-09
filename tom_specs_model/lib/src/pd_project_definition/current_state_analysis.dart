/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 1. Current State Analysis [PD00-CUR].
@tomReflector
class CurrentStateAnalysis {
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
@tomReflector
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
@tomReflector
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
@tomReflector
class LimitationEntry {
  String? content;
  String? limitation;
  String? impact;
}

/// 1.1.3. Dependencies and Integrations [PD00-CUR-SYS-DEP].
@tomReflector
class DependenciesAndIntegrations {
  String? content;
  List<SystemDependencyEntry> items = [];
}

/// A system dependency or integration entry (form).
@tomReflector
class SystemDependencyEntry {
  String? content;
  String? sourceSystem;
  String? targetSystem;
  String? dependencyType;
  String? protocol;
  String? dataExchanged;
  String? criticality;
}

// ---------------------------------------------------------------------------
// 1.2 Current Business Processes
// ---------------------------------------------------------------------------

/// 1.2. Current Business Processes [PD00-CUR-PRO].
@tomReflector
class CurrentBusinessProcesses {
  String? content;

  /// 1.2.1. Workflow Descriptions [PD00-CUR-PRO-WOR] — contains 1+× Workflow.
  List<CurrentWorkflowEntry> workflows = [];

  /// 1.2.2. Process Metrics [PD00-CUR-PRO-MET].
  ProcessMetrics processMetrics = ProcessMetrics();
}

/// A current workflow entry [PD00-CUR-PRO-WOR-nn] (form).
@tomReflector
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
@tomReflector
class WorkflowStepEntry {
  String? content;
  String? stepName;
  String? description;
}

/// A workflow actor entry (form).
@tomReflector
class WorkflowActorEntry {
  String? content;
  String? actorName;
  String? role;
}

/// 1.2.2. Process Metrics [PD00-CUR-PRO-MET].
@tomReflector
class ProcessMetrics {
  String? content;
  List<ProcessMetricEntry> items = [];
}

/// A process metric entry (form).
@tomReflector
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
@tomReflector
class PainPointsAndGaps {
  String? content;

  /// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
  OperationalPainPoints operationalPainPoints = OperationalPainPoints();

  /// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
  BusinessPainPoints businessPainPoints = BusinessPainPoints();

  /// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
  TechnicalPainPoints technicalPainPoints = TechnicalPainPoints();
}

/// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
@tomReflector
class OperationalPainPoints {
  String? content;
  List<PainPointEntry> items = [];
}

/// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
@tomReflector
class BusinessPainPoints {
  String? content;
  List<PainPointEntry> items = [];
}

/// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
@tomReflector
class TechnicalPainPoints {
  String? content;
  List<PainPointEntry> items = [];
}

/// A pain point entry (form).
@tomReflector
class PainPointEntry {
  String? content;
  String? painPoint;
  String? description;
  String? impact;
  String? affectedProcess;
  String? severity;
  String? workaround;
}

// ---------------------------------------------------------------------------
// 1.4 Current Data Landscape
// ---------------------------------------------------------------------------

/// 1.4. Current Data Landscape [PD00-CUR-DAT].
@tomReflector
class CurrentDataLandscape {
  String? content;

  /// 1.4.1. Data Source Inventory [PD00-CUR-DAT-SRC].
  List<DataSourceEntry> dataSources = [];

  /// 1.4.2. Data Quality Assessment [PD00-CUR-DAT-QUA].
  String? dataQualityAssessment;
}

/// A data source entry combining store, format, volume, and quality (form).
@tomReflector
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
