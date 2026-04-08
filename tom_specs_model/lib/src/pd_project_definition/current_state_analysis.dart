/// Section 1: Current State Analysis [PD00-CUR].
///
/// Analysis of existing systems, processes, and pain points that motivate
/// this project.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 1. Current State Analysis [PD00-CUR].
@tomReflector
class CurrentStateAnalysis {
  final String? content;

  /// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
  final ExistingSystemsLandscape existingSystemsLandscape;

  /// 1.2. Current Business Processes [PD00-CUR-PRO].
  final CurrentBusinessProcesses currentBusinessProcesses;

  /// 1.3. Pain Points and Gaps [PD00-CUR-PAI].
  final PainPointsAndGaps painPointsAndGaps;

  /// 1.4. Current Data Landscape [PD00-CUR-DAT].
  final CurrentDataLandscape currentDataLandscape;

  const CurrentStateAnalysis({
    this.content,
    this.existingSystemsLandscape = const ExistingSystemsLandscape(),
    this.currentBusinessProcesses = const CurrentBusinessProcesses(),
    this.painPointsAndGaps = const PainPointsAndGaps(),
    this.currentDataLandscape = const CurrentDataLandscape(),
  });
}

// ---------------------------------------------------------------------------
// 1.1 Existing Systems Landscape
// ---------------------------------------------------------------------------

/// 1.1. Existing Systems Landscape [PD00-CUR-SYS].
@tomReflector
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
@tomReflector
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
@tomReflector
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
@tomReflector
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
@tomReflector
class PainPointsAndGaps {
  final String? content;

  /// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
  final OperationalPainPoints operationalPainPoints;

  /// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
  final BusinessPainPoints businessPainPoints;

  /// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
  final TechnicalPainPoints technicalPainPoints;

  const PainPointsAndGaps({
    this.content,
    this.operationalPainPoints = const OperationalPainPoints(),
    this.businessPainPoints = const BusinessPainPoints(),
    this.technicalPainPoints = const TechnicalPainPoints(),
  });
}

/// 1.3.1. Operational Pain Points [PD00-CUR-PAI-OPE].
@tomReflector
class OperationalPainPoints {
  final String? content;
  final List<PainPointEntry> items;

  const OperationalPainPoints({this.content, this.items = const []});
}

/// 1.3.2. Business Pain Points [PD00-CUR-PAI-BUS].
@tomReflector
class BusinessPainPoints {
  final String? content;
  final List<PainPointEntry> items;

  const BusinessPainPoints({this.content, this.items = const []});
}

/// 1.3.3. Technical Pain Points [PD00-CUR-PAI-TEC].
@tomReflector
class TechnicalPainPoints {
  final String? content;
  final List<PainPointEntry> items;

  const TechnicalPainPoints({this.content, this.items = const []});
}

/// A pain point entry (form).
@tomReflector
class PainPointEntry {
  final String? content;
  final String? painPoint;
  final String? description;
  final String? impact;
  final String? affectedProcess;
  final String? severity;
  final String? workaround;

  const PainPointEntry({
    this.content,
    this.painPoint,
    this.description,
    this.impact,
    this.affectedProcess,
    this.severity,
    this.workaround,
  });
}

// ---------------------------------------------------------------------------
// 1.4 Current Data Landscape
// ---------------------------------------------------------------------------

/// 1.4. Current Data Landscape [PD00-CUR-DAT].
@tomReflector
class CurrentDataLandscape {
  final String? content;

  /// 1.4.1. Data Stores [PD00-CUR-DAT-STO].
  final String? dataStores;

  /// 1.4.2. Data Formats [PD00-CUR-DAT-FOR].
  final String? dataFormats;

  /// 1.4.3. Data Volumes [PD00-CUR-DAT-VOL].
  final String? dataVolumes;

  /// 1.4.4. Data Quality [PD00-CUR-DAT-QUA].
  final String? dataQuality;

  const CurrentDataLandscape({
    this.content,
    this.dataStores,
    this.dataFormats,
    this.dataVolumes,
    this.dataQuality,
  });
}
