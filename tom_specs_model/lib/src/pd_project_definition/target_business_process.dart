import '../common/enums.dart';

/// Section 6: Target Business Process Model [PD00-TAR].
///
/// Target business processes the system will support.
/// Splits into process descriptions (seeds → BP) and
/// actor interactions (seeds → UC).
class TargetBusinessProcessModel {
  /// 6.1. Business Process Descriptions [PD00-TAR-PRO]. Seeds → BP.
  final BusinessProcessDescriptions processDescriptions;

  /// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
  final ProcessStepsAndActorInteractions processSteps;

  const TargetBusinessProcessModel({
    this.processDescriptions = const BusinessProcessDescriptions(),
    this.processSteps = const ProcessStepsAndActorInteractions(),
  });
}

// ---------------------------------------------------------------------------
// 6.1 Business Process Descriptions (seeds → BP)
// ---------------------------------------------------------------------------

/// 6.1. Business Process Descriptions [PD00-TAR-PRO]. Seeds → BP.
class BusinessProcessDescriptions {
  /// 6.1.1. Process Vision [PD00-TAR-PRO-VIS].
  final String? processVision;

  /// 6.1.2. Design Principles [PD00-TAR-PRO-PRI].
  final String? designPrinciples;

  /// 6.1.3. Process Catalog [PD00-TAR-PRO-CAT] — contains 1+× BusinessProcess.
  final List<BusinessProcess> processCatalog;

  /// 6.1.4. Process Overview Diagram [PD00-TAR-PRO-FLO] (mermaid).
  final String? processOverviewDiagram;

  /// 6.1.5. Improvement Summary [PD00-TAR-PRO-IMP].
  final String? improvementSummary;

  const BusinessProcessDescriptions({
    this.processVision,
    this.designPrinciples,
    this.processCatalog = const [],
    this.processOverviewDiagram,
    this.improvementSummary,
  });
}

/// A target business process [PD00-TAR-PRO-CAT-nn].
class BusinessProcess {
  final String processId;
  final String processName;
  final String trigger;
  final String primaryActor;
  final String description;
  final String expectedOutcome;
  final String? estimatedFrequency;
  final String? estimatedDuration;

  const BusinessProcess({
    required this.processId,
    required this.processName,
    required this.trigger,
    required this.primaryActor,
    required this.description,
    required this.expectedOutcome,
    this.estimatedFrequency,
    this.estimatedDuration,
  });
}

// ---------------------------------------------------------------------------
// 6.2 Process Steps and Actor Interactions (seeds → UC)
// ---------------------------------------------------------------------------

/// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
class ProcessStepsAndActorInteractions {
  /// 6.2.1. Actor Overview [PD00-TAR-STP-ACT] — contains 1+× Actor.
  final List<Actor> actors;

  /// 6.2.2. Interaction Catalog [PD00-TAR-STP-INT] — contains 1+× Interaction.
  final List<Interaction> interactions;

  /// 6.2.3. Key Scenarios [PD00-TAR-STP-SCE] — contains 1+× Scenario.
  final List<Scenario> scenarios;

  const ProcessStepsAndActorInteractions({
    this.actors = const [],
    this.interactions = const [],
    this.scenarios = const [],
  });
}

/// An actor in the system [PD00-TAR-STP-ACT-nn].
class Actor {
  final String actorName;
  final ActorType actorType;
  final String description;
  final String? primaryInteractions;
  final AccessChannel? accessChannel;

  const Actor({
    required this.actorName,
    required this.actorType,
    required this.description,
    this.primaryInteractions,
    this.accessChannel,
  });
}

/// An actor–system interaction [PD00-TAR-STP-INT-nn].
class Interaction {
  final String interactionId;
  final String processReference;
  final String actor;
  final String action;
  final String systemResponse;
  final String expectedOutcome;
  final String? precondition;
  final String? postcondition;
  final String? relatedUseCase;

  const Interaction({
    required this.interactionId,
    required this.processReference,
    required this.actor,
    required this.action,
    required this.systemResponse,
    required this.expectedOutcome,
    this.precondition,
    this.postcondition,
    this.relatedUseCase,
  });
}

/// An end-to-end scenario [PD00-TAR-STP-SCE-nn].
class Scenario {
  final String scenarioName;
  final String description;
  final List<String> steps;
  final String successCondition;

  const Scenario({
    required this.scenarioName,
    required this.description,
    this.steps = const [],
    required this.successCondition,
  });
}
