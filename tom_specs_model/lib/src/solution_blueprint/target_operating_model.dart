/// SBP.7 — Target Operating Model (concept).
///
/// Consolidates the future-state operating concept as two cleanly separated
/// subtrees (csm-8-1 split):
///
/// - [OrganizationAndProcessConcept] — the **ORG/OPS follow-up** subtree: the
///   target organizational structure (from [OrganizationalFramework]) and the
///   business-process narrative / descriptions (from
///   [BusinessProcessDescriptions]). Delivered by organizational-change and
///   operational-routine follow-up processes, not code generation.
/// - [ProcessStepsAndActorInteractions] — the **CodeSpecs** subtree: the
///   process steps and actor interactions that map to service units and server
///   calls (CE-SU / CE-SC).
///
/// Seeds the Target Operating Model (TOM) and Interaction Scenarios (ISC)
/// documents.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'target_organization.dart';
import 'business_process_model.dart';

/// SBP.7 Target Operating Model concept.
///
/// Split into a follow-up subtree ([OrganizationAndProcessConcept], ORG/OPS)
/// and a CodeSpecs subtree ([ProcessStepsAndActorInteractions], CE-SU/CE-SC)
/// so each whole branch is owned by a single downstream process.
@StandardReferences(
  ['BABOK v3 — future-state analysis'],
  'The future-state operating concept: how the organization and its business '
  'processes will work once the solution is in place.',
)
@SectionId('TOMC')
class TargetOperatingModel extends DocSpecsSection {
  @Unused()
  @override
  @SerializationOrder(0)
  String? content;

  /// ORG/OPS follow-up subtree: target organization + process narrative.
  @SerializationOrder(1)
  OrganizationAndProcessConcept organizationAndProcess =
      OrganizationAndProcessConcept();

  /// CodeSpecs subtree: process steps and actor interactions (CE-SU / CE-SC).
  @Comment('Seeds → ISC')
  @SerializationOrder(2)
  ProcessStepsAndActorInteractions processStepsAndActorInteractions =
      ProcessStepsAndActorInteractions();
}

/// SBP.7.1 Organization & Process Concept — ORG/OPS follow-up subtree.
///
/// Groups the two purely-follow-up facets of the Target Operating Model into a
/// single branch that is routed to organizational-change (ORG) and
/// operational-routine (OPS) follow-up processes rather than to code
/// generation: the target organizational structure/roles
/// ([OrganizationalFramework]) and the business-process narrative
/// ([BusinessProcessDescriptions], which seeds the TOM document).
@StandardReferences(
  ['BABOK v3 — future-state analysis'],
  'The organizational and process-narrative facets of the future-state '
  'operating model — organization structure, roles, and process descriptions.',
)
@SectionId('OAPC')
@Comment('Seeds → TOM')
class OrganizationAndProcessConcept extends DocSpecsSection {
  @Unused()
  @override
  @SerializationOrder(0)
  String? content;

  /// Target organizational structure and roles.
  @SerializationOrder(1)
  OrganizationalFramework organizationalFramework = OrganizationalFramework();

  /// Business-process descriptions and narrative. Seeds → TOM.
  @Comment('Seeds → TOM')
  @SerializationOrder(2)
  BusinessProcessDescriptions businessProcessDescriptions =
      BusinessProcessDescriptions();
}
