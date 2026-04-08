/// Section 6: Target Business Process Model [PD00-TAR].
///
/// Target business processes the system will support. Splits into process
/// descriptions (seeds → BP) and actor interactions (seeds → UC).
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 6. Target Business Process Model [PD00-TAR].
@tomReflector
class TargetBusinessProcessModel {
  final String? content;

  /// 6.1. Business Process Descriptions [PD00-TAR-PRO]. Seeds → BP.
  final BusinessProcessDescriptions processDescriptions;

  /// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
  final ProcessStepsAndActorInteractions processSteps;

  const TargetBusinessProcessModel({
    this.content,
    this.processDescriptions = const BusinessProcessDescriptions(),
    this.processSteps = const ProcessStepsAndActorInteractions(),
  });
}

// ---------------------------------------------------------------------------
// 6.1 Business Process Descriptions (seeds → BP)
// ---------------------------------------------------------------------------

/// 6.1. Business Process Descriptions [PD00-TAR-PRO]. Seeds → BP.
@tomReflector
class BusinessProcessDescriptions {
  final String? content;

  /// 6.1.1. Process Vision [PD00-TAR-PRO-VIS].
  final String? processVision;

  /// 6.1.2. Design Principles [PD00-TAR-PRO-PRI].
  final DesignPrinciples designPrinciples;

  /// 6.1.3. Process Catalog [PD00-TAR-PRO-CAT] — contains 1+× Business Process.
  final List<BusinessProcessEntry> processCatalog;

  /// 6.1.4. Process Overview Diagram [PD00-TAR-PRO-FLO] (mermaid).
  final String? processOverviewDiagram;

  /// 6.1.5. Improvement Summary [PD00-TAR-PRO-IMP].
  final String? improvementSummary;

  const BusinessProcessDescriptions({
    this.content,
    this.processVision,
    this.designPrinciples = const DesignPrinciples(),
    this.processCatalog = const [],
    this.processOverviewDiagram,
    this.improvementSummary,
  });
}

/// 6.1.2. Design Principles [PD00-TAR-PRO-PRI].
@tomReflector
class DesignPrinciples {
  final String? content;
  final List<DesignPrincipleEntry> items;

  const DesignPrinciples({this.content, this.items = const []});
}

/// A design principle entry (form).
@tomReflector
class DesignPrincipleEntry {
  final String? content;
  final String? principle;
  final String? description;
  final String? rationale;

  const DesignPrincipleEntry({
    this.content,
    this.principle,
    this.description,
    this.rationale,
  });
}

/// A business process entry [PD00-TAR-PRO-CAT-nn] (form).
@tomReflector
class BusinessProcessEntry {
  final String? content;
  final String? processId;
  final String? processName;
  final String? trigger;
  final String? primaryActor;
  final String? description;
  final String? expectedOutcome;
  final String? estimatedFrequency;
  final String? estimatedDuration;

  const BusinessProcessEntry({
    this.content,
    this.processId,
    this.processName,
    this.trigger,
    this.primaryActor,
    this.description,
    this.expectedOutcome,
    this.estimatedFrequency,
    this.estimatedDuration,
  });
}

// ---------------------------------------------------------------------------
// 6.2 Process Steps and Actor Interactions (seeds → UC)
// ---------------------------------------------------------------------------

/// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
@tomReflector
class ProcessStepsAndActorInteractions {
  final String? content;

  /// 6.2.1. Actor Overview [PD00-TAR-STP-ACT] — contains 1+× Actor.
  final List<ActorEntry> actors;

  /// 6.2.2. Interaction Catalog [PD00-TAR-STP-INT] — contains 1+× Interaction.
  final List<InteractionEntry> interactions;

  /// 6.2.3. Key Scenarios [PD00-TAR-STP-SCE] — contains 1+× Scenario.
  final List<ScenarioEntry> scenarios;

  const ProcessStepsAndActorInteractions({
    this.content,
    this.actors = const [],
    this.interactions = const [],
    this.scenarios = const [],
  });
}

/// An actor entry [PD00-TAR-STP-ACT-nn] (form).
@tomReflector
class ActorEntry {
  final String? content;
  final String? actorName;
  final String? actorType;
  final String? description;

  /// Primary interactions — contains 1+× interaction reference.
  final PrimaryInteractions primaryInteractions;

  final String? accessChannel;

  const ActorEntry({
    this.content,
    this.actorName,
    this.actorType,
    this.description,
    this.primaryInteractions = const PrimaryInteractions(),
    this.accessChannel,
  });
}

/// Primary interactions for an actor.
@tomReflector
class PrimaryInteractions {
  final String? content;
  final List<PrimaryInteractionEntry> items;

  const PrimaryInteractions({this.content, this.items = const []});
}

/// A primary interaction entry (form).
@tomReflector
class PrimaryInteractionEntry {
  final String? content;
  final String? useCaseReference;
  final String? description;
  final String? frequency;
  final String? criticality;

  const PrimaryInteractionEntry({
    this.content,
    this.useCaseReference,
    this.description,
    this.frequency,
    this.criticality,
  });
}

/// An interaction entry [PD00-TAR-STP-INT-nn] (form).
@tomReflector
class InteractionEntry {
  final String? content;
  final String? interactionId;
  final String? processReference;
  final String? actor;
  final String? action;
  final String? systemResponse;
  final String? expectedOutcome;
  final String? precondition;
  final String? postcondition;
  final String? relatedUseCase;

  const InteractionEntry({
    this.content,
    this.interactionId,
    this.processReference,
    this.actor,
    this.action,
    this.systemResponse,
    this.expectedOutcome,
    this.precondition,
    this.postcondition,
    this.relatedUseCase,
  });
}

/// A scenario entry [PD00-TAR-STP-SCE-nn] (description).
@tomReflector
class ScenarioEntry {
  final String? content;
  final String? scenarioName;
  final String? description;
  final List<String> steps;
  final String? successCondition;

  /// Alternative flows for this scenario.
  final List<AlternativeFlowEntry> alternativeFlows;

  const ScenarioEntry({
    this.content,
    this.scenarioName,
    this.description,
    this.steps = const [],
    this.successCondition,
    this.alternativeFlows = const [],
  });
}

/// An alternative flow entry (form).
@tomReflector
class AlternativeFlowEntry {
  final String? content;
  final String? flowName;
  final String? triggerCondition;
  final List<String> steps;
  final String? outcome;
  final String? returnPoint;

  const AlternativeFlowEntry({
    this.content,
    this.flowName,
    this.triggerCondition,
    this.steps = const [],
    this.outcome,
    this.returnPoint,
  });
}
