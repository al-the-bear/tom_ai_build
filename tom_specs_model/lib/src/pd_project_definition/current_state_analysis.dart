/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project. Provides the baseline for all subsequent sections.
class CurrentStateAnalysis {
  /// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
  final String? systemsLandscape;

  /// 1.1.1. System Inventory [PD00-CUR-SYS-INV] — contains 1+× ExistingSystem.
  final List<ExistingSystem> systemInventory;

  /// 1.1.2. Current Architecture [PD00-CUR-SYS-ARC].
  final String? currentArchitecture;

  /// 1.1.3. Dependencies and Integrations [PD00-CUR-SYS-DEP].
  final String? dependenciesAndIntegrations;

  /// 1.2. Current Business Processes [PD00-CUR-PRO].
  final String? currentBusinessProcesses;

  /// 1.2.1. Workflow Descriptions [PD00-CUR-PRO-WOR] — contains 1+× CurrentWorkflow.
  final List<CurrentWorkflow> workflowDescriptions;

  /// 1.2.2. Process Metrics [PD00-CUR-PRO-MET].
  final String? processMetrics;

  /// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
  final String? painPointsOverview;

  /// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
  final String? operationalPainPoints;

  /// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
  final String? businessPainPoints;

  /// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
  final String? technicalPainPoints;

  /// 1.4. Current Data Landscape [PD00-CUR-DAT].
  final String? currentDataLandscape;

  const CurrentStateAnalysis({
    this.systemsLandscape,
    this.systemInventory = const [],
    this.currentArchitecture,
    this.dependenciesAndIntegrations,
    this.currentBusinessProcesses,
    this.workflowDescriptions = const [],
    this.processMetrics,
    this.painPointsOverview,
    this.operationalPainPoints,
    this.businessPainPoints,
    this.technicalPainPoints,
    this.currentDataLandscape,
  });
}

/// An existing system in the current landscape [PD00-CUR-SYS-INV-nn].
class ExistingSystem {
  final String systemName;
  final String technology;
  final String purpose;
  final int? activeUsers;
  final String? dataVolume;
  final String? operationalSince;
  final String? supportStatus;
  final String? knownLimitations;

  const ExistingSystem({
    required this.systemName,
    required this.technology,
    required this.purpose,
    this.activeUsers,
    this.dataVolume,
    this.operationalSince,
    this.supportStatus,
    this.knownLimitations,
  });
}

/// A current business workflow [PD00-CUR-PRO-WOR-nn].
class CurrentWorkflow {
  final String processName;
  final String trigger;
  final String steps;
  final String actors;
  final String output;
  final String? cycleTime;
  final String? manualSteps;
  final String? errorProneSteps;

  const CurrentWorkflow({
    required this.processName,
    required this.trigger,
    required this.steps,
    required this.actors,
    required this.output,
    this.cycleTime,
    this.manualSteps,
    this.errorProneSteps,
  });
}
