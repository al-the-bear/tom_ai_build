/// The follow-up taxonomy tag for a SOM follow-up subtree
/// (`codespecs_followup_split.md` §3 + §5).
///
/// The CodeSpecs split (`codespecs_followup_split.md` §3) partitions each SBP
/// section into a **purely-CodeSpecs subtree** (which Phase 4 realises as
/// generated code) and one-or-more **purely follow-up subtrees** — the
/// non-CodeSpecs work that a system-creation process still owns (documentation,
/// training, org design, operations, capacity, compliance, migration,
/// localization, acceptance). `@FollowUpKind` is applied to the **root** of each
/// follow-up subtree to declare which downstream process(es) that subtree feeds,
/// so each process can select exactly its slice of the blueprint.
///
/// It lives in `tom_specs_core` — not the `tom_code_specs` framework — because it
/// annotates the *model* (SOM) classes, and `tom_specs_model` already depends on
/// `tom_specs_core`. This mirrors `@CodeSpecKind` and keeps it alongside the
/// other cross-phase link annotations (`@MapsTo`, `@DetailedIn`,
/// `@CodeSpecKind`).
///
/// A follow-up subtree may feed **more than one** process (e.g. the
/// delivery/transition subtree drives migration, operations, org and
/// localization at once; the data-model follow-up drives documentation,
/// capacity, compliance and migration), so [processes] is a **list**. A
/// single-process subtree uses the one-element list form.
///
/// Example:
/// ```dart
/// @FollowUpKind([FollowUpProcess.doc])
/// class DocumentControl { ... }
///
/// @FollowUpKind([FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org,
///     FollowUpProcess.l10n], note: 'staged rollout across environments')
/// class DeliveryTransitionAndRollout { ... }
/// ```
class FollowUpKind {
  /// The downstream follow-up process(es) this subtree feeds. At least one; a
  /// single-process subtree uses a one-element list.
  final List<FollowUpProcess> processes;

  /// Optional explanation of what the subtree contributes to the named
  /// process(es).
  final String? note;

  const FollowUpKind(this.processes, {this.note});
}

/// The follow-up-taxonomy vocabulary (`codespecs_followup_split.md` §3).
///
/// The taxonomy is explicitly **extensible**: §3 lists the original eight codes
/// (DOC/TRN/ORG/OPS/CAP/CMP/MIG/L10N); [acc] is an admissible extension for the
/// distinct Phase-5 quality/acceptance process (the Quality & Acceptance Model
/// subtree is neither CodeSpecs nor any of the eight original codes).
enum FollowUpProcess {
  /// DOC — documentation: user guides, reference docs, glossaries, control
  /// records, and other written artefacts.
  doc,

  /// TRN — training & enablement: onboarding material, courses, enablement
  /// programmes for users and operators.
  trn,

  /// ORG — organisation & governance: roles, responsibilities, stakeholder and
  /// governance structures, org/process design.
  org,

  /// OPS — operations: run-time operational procedures, security operations,
  /// monitoring, support processes.
  ops,

  /// CAP — capacity & performance: volume metrics, sizing, technical
  /// characteristics, non-functional capacity planning.
  cap,

  /// CMP — compliance: regulatory/compliance requirements and their evidence.
  cmp,

  /// MIG — migration: data and system migration mappings, cutover and staging
  /// plans.
  mig,

  /// L10N — localization & translation: multi-language support, locale rollout,
  /// translation processes.
  l10n,

  /// ACC — acceptance & quality (extension, §3 "extensible"): the Phase-5
  /// quality/acceptance process (Quality & Acceptance Model). Distinct from the
  /// eight original codes and from any CodeSpecs part.
  acc,
}
