/// Section 6: Target Business Process Model [PD00-TAR].
///
/// Target business processes the system will support. Splits into process
/// descriptions (seeds → BP) and actor interactions (seeds → UC).
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 6. Target Business Process Model [PD00-TAR].
class TargetBusinessProcessModel {
  String? content;

  /// 6.1. Process Vision [PD00-TAR-VIS].
  String? processVision;

  /// 6.2. Design Principles [PD00-TAR-PRI].
  DesignPrinciples designPrinciples = DesignPrinciples();

  /// 6.3. Process Overview Diagram [PD00-TAR-FLO] (mermaid).
  FlowDiagramSection processOverviewDiagram = FlowDiagramSection();

  /// 6.4. Relationships Between Processes [PD00-TAR-REL].
  ProcessRelationships relationshipsBetweenProcesses = ProcessRelationships();

  /// 6.5. Improvement Summary [PD00-TAR-IMP].
  String? improvementSummary;

  /// 6.6. Process Catalog [PD00-TAR-CAT] — contains 1+× Target Business Process.
  List<TargetBusinessProcess> processCatalog = [];
}

/// 6.2. Design Principles [PD00-TAR-PRI].
class DesignPrinciples {
  String? content;
  /// Contains 0+× DesignPrinciple.
  List<DesignPrincipleEntry> items = [];
}

/// A design principle entry (form) [PD00-TAR-PRI-nn].
class DesignPrincipleEntry {
  String? content;
  String? principle;
  String? description;
  String? rationale;
}

/// 6.4. Relationships Between Processes [PD00-TAR-REL].
class ProcessRelationships {
  String? content;
  /// Contains 0+× ProcessRelationship.
  List<ProcessRelationshipEntry> items = [];
}

/// A process relationship entry (form) [PD00-TAR-REL-nn].
class ProcessRelationshipEntry {
  String? content;
  String? sourceProcess;
  String? targetProcess;
  String? relationshipType;
  String? description;
}

// ---------------------------------------------------------------------------
// Target Business Process (catalog entry)
// ---------------------------------------------------------------------------

/// A target business process [PD00-TAR-CAT-nn].
///
/// Combines a single business process description with its process steps
/// and actor interactions.
class TargetBusinessProcess {
  String? content;

  /// Process Description [PD00-TAR-CAT-nn-DES].
  BusinessProcessDescription processDescription = BusinessProcessDescription();

  /// Process Steps and Actor Interactions [PD00-TAR-CAT-nn-STP]. Seeds → UC.
  ProcessStepsAndActorInteractions processSteps = ProcessStepsAndActorInteractions();
}

/// A business process description [PD00-TAR-CAT-nn-DES] (form).
class BusinessProcessDescription {
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
// Process Steps and Actor Interactions (seeds → UC)
// ---------------------------------------------------------------------------

/// Process Steps and Actor Interactions [PD00-TAR-CAT-nn-STP]. Seeds → UC.
class ProcessStepsAndActorInteractions {
  String? content;

  /// Actor Overview — contains 1+× Actor.
  List<ActorEntry> actors = [];

  /// Interaction Catalog — contains 1+× Interaction.
  List<InteractionEntry> interactions = [];

  /// Key Scenarios — contains 1+× Scenario.
  List<ScenarioEntry> scenarios = [];
}

/// An actor entry (form) [PD00-TAR-CAT-nn-ACT-nn].
class ActorEntry {
  String? content;
  String? actorName;
  String? actorType;
  String? description;

  /// Primary interactions — contains 1+× interaction reference.
  PrimaryInteractions primaryInteractions = PrimaryInteractions();

  String? accessChannel;
}

/// Primary interactions for an actor [PD00-TAR-CAT-nn-ACT-nn-PRI].
class PrimaryInteractions {
  String? content;
  /// Contains 0+× PrimaryInteraction.
  List<PrimaryInteractionEntry> items = [];
}

/// A primary interaction entry (form) [PD00-TAR-CAT-nn-ACT-nn-PRI-nn].
class PrimaryInteractionEntry {
  String? content;
  String? useCaseReference;
  String? description;
  String? frequency;
  String? criticality;
}

/// An interaction entry (form) [PD00-TAR-CAT-nn-INT-nn].
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

/// A scenario entry (description) [PD00-TAR-CAT-nn-SCE-nn].
class ScenarioEntry {
  String? content;
  String? scenarioName;
  String? description;
  /// Contains 0+× ScenarioStep.
  List<ScenarioStepEntry> steps = [];
  String? successCondition;

  /// Alternative flows for this scenario — contains 0+× AlternativeFlow.
  List<AlternativeFlowEntry> alternativeFlows = [];
}

/// A scenario step entry (form) [PD00-TAR-CAT-nn-SCE-nn-SST-nn].
class ScenarioStepEntry {
  String? content;
  String? stepNumber;
  String? description;
  String? expectedResult;
}

/// An alternative flow entry (form) [PD00-TAR-CAT-nn-SCE-nn-AFL-nn].
class AlternativeFlowEntry {
  String? content;
  String? flowName;
  String? triggerCondition;
  /// Contains 0+× ScenarioStep.
  List<ScenarioStepEntry> steps = [];
  String? outcome;
  String? returnPoint;
}
