/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;


/// 1. Current State Analysis [PD00-CUR].
class CurrentStateAnalysis {
  final String? content;

  /// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
  final ExistingSystemsLandscape existingSystemsLandscape;

  /// 1.2. Current Business Processes [PD00-CUR-PRO].
  final CurrentBusinessProcesses currentBusinessProcesses;

  /// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
  final PainPointsAndGaps painPointsAndGaps;

  /// 1.4. Current Data Landscape [PD00-CUR-DAT].
  final String? currentDataLandscape;

  const CurrentStateAnalysis({
    this.content,
    this.existingSystemsLandscape = const ExistingSystemsLandscape(),
    this.currentBusinessProcesses = const CurrentBusinessProcesses(),
    this.painPointsAndGaps = const PainPointsAndGaps(),
    this.currentDataLandscape,
  });
}

// ---------------------------------------------------------------------------
// 1.1 Existing Systems Landscape
// ---------------------------------------------------------------------------

/// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
class ExistingSystemsLandscape {
  final String? content;

  /// 1.1.1. System Inventory [PD00-CUR-SYS-INV] — contains 1+× Existing System.
  final List<ExistingSystemEntry> systems;

  /// 1.1.2. Current Architecture [PD00-CUR-SYS-ARC].
  final String? currentArchitecture;

  /// 1.1.3. Dependencies and Integrations [PD00-CUR-SYS-DEP].
  final String? dependenciesAndIntegrations;

  const ExistingSystemsLandscape({
    this.content,
    this.systems = const [],
    this.currentArchitecture,
    this.dependenciesAndIntegrations,
  });
}

/// An existing system entry [PD00-CUR-SYS-INV-nn] (form).
class ExistingSystemEntry {
  final String? content;
  final String? systemName;
  final String? technology;
  final String? purpose;
  final String? activeUsers;
  final String? dataVolume;
  final String? operationalSince;
  final String? supportStatus;
  final String? knownLimitations;

  const ExistingSystemEntry({
    this.content,
    this.systemName,
    this.technology,
    this.purpose,
    this.activeUsers,
    this.dataVolume,
    this.operationalSince,
    this.supportStatus,
    this.knownLimitations,
  });
}

// ---------------------------------------------------------------------------
// 1.2 Current Business Processes
// ---------------------------------------------------------------------------

/// 1.2. Current Business Processes [PD00-CUR-PRO].
class CurrentBusinessProcesses {
  final String? content;

  /// 1.2.1. Workflow Descriptions [PD00-CUR-PRO-WOR] — contains 1+× Workflow.
  final List<CurrentWorkflowEntry> workflows;

  /// 1.2.2. Process Metrics [PD00-CUR-PRO-MET].
  final String? processMetrics;

  const CurrentBusinessProcesses({
    this.content,
    this.workflows = const [],
    this.processMetrics,
  });
}

/// A current workflow entry [PD00-CUR-PRO-WOR-nn] (form).
class CurrentWorkflowEntry {
  final String? content;
  final String? processName;
  final String? trigger;
  final String? steps;
  final String? actors;
  final String? output;
  final String? cycleTime;
  final String? manualSteps;
  final String? errorProneSteps;

  const CurrentWorkflowEntry({
    this.content,
    this.processName,
    this.trigger,
    this.steps,
    this.actors,
    this.output,
    this.cycleTime,
    this.manualSteps,
    this.errorProneSteps,
  });
}

// ---------------------------------------------------------------------------
// 1.3 Pain Points and Gaps
// ---------------------------------------------------------------------------

/// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
class PainPointsAndGaps {
  final String? content;

  /// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
  final String? operationalPainPoints;

  /// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
  final String? businessPainPoints;

  /// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
  final String? technicalPainPoints;

  const PainPointsAndGaps({
    this.content,
    this.operationalPainPoints,
    this.businessPainPoints,
    this.technicalPainPoints,
  });
}
