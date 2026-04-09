/// Section 6: Target Business Process Model [PD00-TAR].
///
/// Target business processes the system will support. Splits into process
/// descriptions (seeds → BP) and actor interactions (seeds → UC).
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 6. Target Business Process Model [PD00-TAR].
@tomReflector
class TargetBusinessProcessModel {
  String? content;

  /// 6.1. Business Process Descriptions [PD00-TAR-PRO]. Seeds → BP.
  BusinessProcessDescriptions processDescriptions = BusinessProcessDescriptions();

  /// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
  ProcessStepsAndActorInteractions processSteps = ProcessStepsAndActorInteractions();
}

// ---------------------------------------------------------------------------
// 6.1 Business Process Descriptions (seeds → BP)
// ---------------------------------------------------------------------------

/// 6.1. Business Process Descriptions [PD00-TAR-PRO]. Seeds → BP.
@tomReflector
class BusinessProcessDescriptions {
  String? content;

  /// 6.1.1. Process Vision [PD00-TAR-PRO-VIS].
  String? processVision;

  /// 6.1.2. Design Principles [PD00-TAR-PRO-PRI].
  DesignPrinciples designPrinciples = DesignPrinciples();

  /// 6.1.3. Process Catalog [PD00-TAR-PRO-CAT] — contains 1+× Business Process.
  List<BusinessProcessEntry> processCatalog = [];

  /// 6.1.4. Process Overview Diagram [PD00-TAR-PRO-FLO] (mermaid).
  String? processOverviewDiagram;

  /// 6.1.5. Improvement Summary [PD00-TAR-PRO-IMP].
  String? improvementSummary;
}

/// 6.1.2. Design Principles [PD00-TAR-PRO-PRI].
@tomReflector
class DesignPrinciples {
  String? content;
  List<DesignPrincipleEntry> items = [];
}

/// A design principle entry (form).
@tomReflector
class DesignPrincipleEntry {
  String? content;
  String? principle;
  String? description;
  String? rationale;
}

/// A business process entry [PD00-TAR-PRO-CAT-nn] (form).
@tomReflector
class BusinessProcessEntry {
  String? content;
  String? processId;
  String? processName;
  String? trigger;
  String? primaryActor;
  String? description;
  String? expectedOutcome;
  String? estimatedFrequency;
  String? estimatedDuration;
}

// ---------------------------------------------------------------------------
// 6.2 Process Steps and Actor Interactions (seeds → UC)
// ---------------------------------------------------------------------------

/// 6.2. Process Steps and Actor Interactions [PD00-TAR-STP]. Seeds → UC.
@tomReflector
class ProcessStepsAndActorInteractions {
  String? content;

  /// 6.2.1. Actor Overview [PD00-TAR-STP-ACT] — contains 1+× Actor.
  List<ActorEntry> actors = [];

  /// 6.2.2. Interaction Catalog [PD00-TAR-STP-INT] — contains 1+× Interaction.
  List<InteractionEntry> interactions = [];

  /// 6.2.3. Key Scenarios [PD00-TAR-STP-SCE] — contains 1+× Scenario.
  List<ScenarioEntry> scenarios = [];
}

/// An actor entry [PD00-TAR-STP-ACT-nn] (form).
@tomReflector
class ActorEntry {
  String? content;
  String? actorName;
  String? actorType;
  String? description;

  /// Primary interactions — contains 1+× interaction reference.
  PrimaryInteractions primaryInteractions = PrimaryInteractions();

  String? accessChannel;
}

/// Primary interactions for an actor.
@tomReflector
class PrimaryInteractions {
  String? content;
  List<PrimaryInteractionEntry> items = [];
}

/// A primary interaction entry (form).
@tomReflector
class PrimaryInteractionEntry {
  String? content;
  String? useCaseReference;
  String? description;
  String? frequency;
  String? criticality;
}

/// An interaction entry [PD00-TAR-STP-INT-nn] (form).
@tomReflector
class InteractionEntry {
  String? content;
  String? interactionId;
  String? processReference;
  String? actor;
  String? action;
  String? systemResponse;
  String? expectedOutcome;
  String? precondition;
  String? postcondition;
  String? relatedUseCase;
}

/// A scenario entry [PD00-TAR-STP-SCE-nn] (description).
@tomReflector
class ScenarioEntry {
  String? content;
  String? scenarioName;
  String? description;
  List<ScenarioStepEntry> steps = [];
  String? successCondition;

  /// Alternative flows for this scenario.
  List<AlternativeFlowEntry> alternativeFlows = [];
}

/// A scenario step entry (form).
@tomReflector
class ScenarioStepEntry {
  String? content;
  String? stepNumber;
  String? description;
  String? expectedResult;
}

/// An alternative flow entry (form).
@tomReflector
class AlternativeFlowEntry {
  String? content;
  String? flowName;
  String? triggerCondition;
  List<ScenarioStepEntry> steps = [];
  String? outcome;
  String? returnPoint;
}
