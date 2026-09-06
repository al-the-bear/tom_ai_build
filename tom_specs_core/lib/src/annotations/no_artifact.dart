/// The third routing verdict: this section feeds **no** downstream artifact
/// (`codespecs_mapping.md` §8.3).
///
/// `@CodeSpecKind` routes a section to CodeSpecs part types; `@FollowUpKind`
/// routes a subtree to downstream follow-up processes. Between them they are
/// meant to cover the whole specification — but some sections legitimately
/// produce nothing: a chapter node that only groups its children, an overview
/// that restates material specified normatively elsewhere, a diagram or
/// traceability matrix that is a view onto other sections.
///
/// Without a third marker those sections are indistinguishable from sections
/// nobody has got round to routing yet. `@NoArtifact` closes that gap: it makes
/// "produces nothing" a **recorded decision** rather than an omission, which is
/// what lets the `tom_specs_model_rules.md` §10.2 invariant `ROUTE-TOTAL`
/// demand that every `@SectionId`-carrying class reachable from a specification
/// root carry exactly one of the three verdicts.
///
/// Mutually exclusive with both `@CodeSpecKind` and `@FollowUpKind` — a section
/// that feeds something is not a section that feeds nothing.
///
/// Unlike its two siblings the reason is **single-valued**: a section feeds
/// several parts or several processes at once, but it is unrouted for one
/// reason.
///
/// Example:
/// ```dart
/// @NoArtifact(NoArtifactReason.container)
/// class SolutionArchitectureAndTechnology { ... }
///
/// @NoArtifact(NoArtifactReason.overview,
///     note: 'introduces the actor entries below; every actor fact is in ACEN')
/// class ActorOverview { ... }
/// ```
class NoArtifact {
  /// Why the section produces no artifact.
  final NoArtifactReason reason;

  /// Optional explanation — for [NoArtifactReason.overview] and
  /// [NoArtifactReason.view], where the material *is* specified, a pointer to
  /// where it is specified normatively.
  final String? note;

  /// Declares that the annotated section produces no downstream artifact,
  /// for [reason].
  const NoArtifact(this.reason, {this.note});
}

/// Why a section is deliberately routed to neither CodeSpecs nor a follow-up
/// process (`codespecs_mapping.md` §8.3).
///
/// A closed vocabulary of three: the section groups, it restates, or it
/// re-presents. Anything else that produces nothing is one of these three in
/// disguise; anything that does not fit is a section that should have been
/// routed.
enum NoArtifactReason {
  /// A structural grouping node. Its own content is a headline plus at most an
  /// introductory sentence; every routable fact lives in its children, which
  /// carry their own verdicts. Chapter and sub-chapter nodes are the common
  /// case.
  container,

  /// Narrative that introduces or summarises a sibling set. Every fact it
  /// states is stated normatively by a routed section, so generating from it
  /// would duplicate — or contradict — that section. Use [NoArtifact.note] to
  /// name where the material is specified.
  overview,

  /// A re-presentation of material specified elsewhere in another form: a
  /// diagram of relationships already declared, a traceability matrix over
  /// existing ids, a cross-reference index. Distinguished from [overview] in
  /// that it is derived rather than prose — a generator could in principle
  /// *produce* it, never consume it.
  view,
}
