/// Section 6: Target Business Process Model [PD00-TAR].
///
/// Target business processes the system will support. Splits into process
/// descriptions (seeds → BP) and actor interactions (seeds → UC).
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 6. Target Business Process Model [PD00-TAR].
@SectionId('PD00-TAR')
@Comment('Seeds → BP, UC')
class TargetBusinessProcessModel {
  @Unused()
  String? content;

  /// Process Vision.
  TextSection processVision = TextSection();

  /// 6.2. Design Principles [PD00-TAR-PRI].
  DesignPrinciples designPrinciples = DesignPrinciples();

  /// 6.3. Process Overview Diagram [PD00-TAR-FLO] (mermaid).
  FlowDiagramSection processOverviewDiagram = FlowDiagramSection();

  /// 6.4. Relationships Between Processes [PD00-TAR-REL].
  ProcessRelationships relationshipsBetweenProcesses = ProcessRelationships();

  /// Improvement Summary.
  TextSection improvementSummary = TextSection();

  /// 6.6. Process Catalog [PD00-TAR-CAT] — contains 1+× Target Business Process.
  @SectionIdPattern('PD00-TAR-CAT-xx')
  @Min(1)
  List<TargetBusinessProcess> processCatalog = [];
}

/// 6.2. Design Principles [PD00-TAR-PRI].
@SectionId('PD00-TAR-PRI')
class DesignPrinciples {
  @Unused()
  String? content;

  /// Contains 0+× DesignPrinciple.
  @SectionIdPattern('PD00-TAR-PRI-xx')
  List<DesignPrincipleEntry> items = [];
}

/// A design principle entry (form) [PD00-TAR-PRI-nn].
class DesignPrincipleEntry {
  @Form([
    Field('principle', String, 'Principle', required: true),
    Field('description', String, 'Short description'),
    Field('rationale', String, 'Rationale'),
  ])
  String? content;
}

/// 6.4. Relationships Between Processes [PD00-TAR-REL].
@SectionId('PD00-TAR-REL')
class ProcessRelationships {
  @Unused()
  String? content;

  /// Contains 0+× ProcessRelationship.
  @SectionIdPattern('PD00-TAR-REL-xx')
  List<ProcessRelationshipEntry> items = [];
}

/// A process relationship entry (form) [PD00-TAR-REL-nn].
class ProcessRelationshipEntry {
  @Form([
    Field('relationshipType', String, 'Relationship Type'),
    Field('description', String, 'Short description'),
  ])
  String? content;

  @Reference('Source Process')
  BusinessProcessDescription? sourceProcess;

  @Reference('Target Process')
  BusinessProcessDescription? targetProcess;
}

// ---------------------------------------------------------------------------
// Target Business Process (catalog entry)
// ---------------------------------------------------------------------------

/// A target business process [PD00-TAR-CAT-nn].
///
/// Combines a single business process description with its process steps
/// and actor interactions.
class TargetBusinessProcess {
  @Unused()
  String? content;

  /// Process Description [PD00-TAR-CAT-nn-DES].
  BusinessProcessDescription processDescription = BusinessProcessDescription();

  /// Process Steps and Actor Interactions [PD00-TAR-CAT-nn-STP]. Seeds → UC.
  @Comment('Seeds → UC')
  ProcessStepsAndActorInteractions processSteps = ProcessStepsAndActorInteractions();
}

/// A business process description [PD00-TAR-CAT-nn-DES] (form).
@SectionId('PD00-TAR-CAT-DES')
class BusinessProcessDescription {
  @Form([
    Field('processId', String, 'Process Id', required: true),
    Field('processName', String, 'Process Name', required: true),
    Field('trigger', String, 'Trigger'),
    Field('primaryActor', String, 'Primary Actor'),
    Field('description', String, 'Short description'),
    Field('expectedOutcome', String, 'Expected Outcome'),
    Field('estimatedFrequency', String, 'Estimated Frequency'),
    Field('estimatedDuration', String, 'Estimated Duration'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// Process Steps and Actor Interactions (seeds → UC)
// ---------------------------------------------------------------------------

/// Process Steps and Actor Interactions [PD00-TAR-CAT-nn-STP]. Seeds → UC.
@SectionId('PD00-TAR-CAT-STP')
@Comment('Seeds → UC')
class ProcessStepsAndActorInteractions {
  @Unused()
  String? content;

  /// Actor Overview — contains 1+× Actor.
  @SectionIdPattern('PD00-TAR-CAT-xx-ACT-xx')
  @Min(1)
  List<ActorEntry> actors = [];

  /// Interaction Catalog — contains 1+× Interaction.
  @SectionIdPattern('PD00-TAR-CAT-xx-INT-xx')
  @Min(1)
  List<InteractionEntry> interactions = [];

  /// Key Scenarios — contains 1+× Scenario.
  @SectionIdPattern('PD00-TAR-CAT-xx-SCE-xx')
  @Min(1)
  List<ScenarioEntry> scenarios = [];
}

/// An actor entry (form) [PD00-TAR-CAT-nn-ACT-nn].
class ActorEntry {
  @Form([
    Field('actorName', String, 'Actor Name', required: true),
    Field('actorType', String, 'Actor Type'),
    Field('description', String, 'Short description'),
    Field('accessChannel', String, 'Access Channel'),
  ])
  String? content;

  /// Primary interactions — contains 1+× interaction reference.
  PrimaryInteractions primaryInteractions = PrimaryInteractions();
}

/// Primary interactions for an actor [PD00-TAR-CAT-nn-ACT-nn-PRI].
@SectionId('PD00-TAR-CAT-ACT-PRI')
class PrimaryInteractions {
  @Unused()
  String? content;

  /// Contains 0+× PrimaryInteraction.
  @SectionIdPattern('PD00-TAR-CAT-xx-ACT-xx-PRI-xx')
  List<PrimaryInteractionEntry> items = [];
}

/// A primary interaction entry (form) [PD00-TAR-CAT-nn-ACT-nn-PRI-nn].
class PrimaryInteractionEntry {
  @Form([
    Field('description', String, 'Short description'),
    Field('frequency', String, 'Frequency'),
    Field('criticality', String, 'Criticality'),
    Field('useCaseReference', String, 'Use Case Reference'),
  ])
  String? content;
}

/// An interaction entry (form) [PD00-TAR-CAT-nn-INT-nn].
class InteractionEntry {
  @Form([
    Field('interactionId', String, 'Interaction Id', required: true),
    Field('actor', String, 'Actor'),
    Field('action', String, 'Action'),
    Field('systemResponse', String, 'System Response'),
    Field('expectedOutcome', String, 'Expected Outcome'),
    Field('precondition', String, 'Precondition'),
    Field('postcondition', String, 'Postcondition'),
    Field('relatedUseCase', String, 'Related Use Case'),
  ])
  String? content;

  @Reference('Process Reference')
  BusinessProcessDescription? processReference;
}

/// A scenario entry (description) [PD00-TAR-CAT-nn-SCE-nn].
class ScenarioEntry {
  @Form([
    Field('scenarioName', String, 'Scenario Name', required: true),
    Field('description', String, 'Short description'),
    Field('successCondition', String, 'Success Condition'),
  ])
  String? content;

  /// Contains 0+× ScenarioStep.
  @SectionIdPattern('PD00-TAR-CAT-xx-SCE-xx-SST-xx')
  List<ScenarioStepEntry> steps = [];

  /// Alternative flows for this scenario — contains 0+× AlternativeFlow.
  @SectionIdPattern('PD00-TAR-CAT-xx-SCE-xx-AFL-xx')
  List<AlternativeFlowEntry> alternativeFlows = [];
}

/// A scenario step entry (form) [PD00-TAR-CAT-nn-SCE-nn-SST-nn].
class ScenarioStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number'),
    Field('description', String, 'Short description'),
    Field('expectedResult', String, 'Expected Result'),
  ])
  String? content;
}

/// An alternative flow entry (form) [PD00-TAR-CAT-nn-SCE-nn-AFL-nn].
class AlternativeFlowEntry {
  @Form([
    Field('flowName', String, 'Flow Name', required: true),
    Field('triggerCondition', String, 'Trigger Condition'),
    Field('outcome', String, 'Outcome'),
    Field('returnPoint', String, 'Return Point'),
  ])
  String? content;

  /// Contains 0+× ScenarioStep.
  List<ScenarioStepEntry> steps = [];
}
