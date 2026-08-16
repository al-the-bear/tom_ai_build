/// SBP.11 — Solution Architecture & Technology.
///
/// Consolidates the technical solution framing. Split
/// (`codespecs_mapping.md` §8.3) into two concerns:
///
///  * [TechnicalFrameworkConcept] (`technicalFramework`) — the technology
///    framework and platform concept. This is the CodeSpecs-relevant subtree:
///    it carries the **CE-CF configuration** facets (platform/runtime settings,
///    client/server/system configuration, feature flags, background jobs)
///    that CodeSpecs consumes, tagged in place with `@CodeSpecKind` where they
///    sit within the architecture narrative that contextualises them.
///  * [SolutionArchitectureFollowUp] (`architectureFollowUp`) — the DOC
///    follow-up subtree: the component-reuse rationale (component catalogue and
///    third-party/dependency strategy) that is descriptive architecture, not
///    generated code.
///
/// Seeds the Architecture & Technology Specification (ATS) document.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'architecture_and_technology.dart';
import 'components_and_dependencies.dart';

/// SBP.11 Solution Architecture & Technology.
@StandardReferences(
  ['ISO/IEC/IEEE 42010:2011 — architecture description'],
  'The technical solution framing: the CE-CF configuration-bearing technical '
  'framework (CodeSpecs subtree) plus the component-reuse rationale (DOC '
  'follow-up subtree).',
)
@SectionId('SOAT')
@NoArtifact(
  NoArtifactReason.container,
  note:
      'chapter node over the technical framework concept and its follow-up',
)
class SolutionArchitectureAndTechnology extends DocSpecsSection {
  @Unused()
  @override
  @SerializationOrder(0)
  String? content;

  /// Technical framework and platform concept — the CodeSpecs-relevant
  /// (CE-CF configuration-bearing) subtree.
  @SerializationOrder(1)
  TechnicalFrameworkConcept technicalFramework = TechnicalFrameworkConcept();

  /// Architecture / component-reuse DOC follow-up subtree.
  @SerializationOrder(2)
  SolutionArchitectureFollowUp architectureFollowUp =
      SolutionArchitectureFollowUp();
}

/// SBP.11 Solution Architecture & Technology — DOC follow-up subtree.
///
/// Groups the descriptive-architecture concern that is **not** CodeSpecs-
/// generated: the component-reuse rationale (component catalogue, third-party
/// and dependency strategy). The root carries no `@CodeSpecKind`, so it is not
/// a generation projection root and nothing under it is reachable from
/// `D13CodeSpecsProjection` (`codespecs_mapping.md` §8.3) — and here no section
/// inside it carries one either, keeping the sibling
/// [TechnicalFrameworkConcept] as the CE-CF configuration-bearing CodeSpecs
/// subtree.
@StandardReferences(
  ['ISO/IEC/IEEE 42010:2011 — architecture description'],
  'The descriptive-architecture follow-up: component-reuse rationale (component '
  'catalogue and dependency strategy) consumed as documentation, not generated.',
)
@FollowUpKind([FollowUpProcess.doc])
@SectionId('SATF')
class SolutionArchitectureFollowUp extends DocSpecsSection {
  @ContentType('description', 'Summarize the descriptive-architecture follow-up: '
      'the component-reuse rationale and dependency strategy.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Components, libraries, and services to reuse.
  @SerializationOrder(1)
  ComponentsAndDependencies componentsToUse = ComponentsAndDependencies();
}
