/// The record of an **authored completion**: `@CsCompletion`.
///
/// A CodeSpecs trio states what the specification states. Where the code needs
/// a fact the specification is silent on, and the derivation contract's
/// register of authored completions (`codespecs_derivation_contract.md` §2.10)
/// has a rule for it, the authoring agent writes the rule's value — and records
/// that it did, with one `@CsCompletion` beside the code the value shaped. A
/// reader in any language then sees which values were specified and which
/// were completed, and the run's completions are reviewed together.
///
/// Like `@CsCollaborator` it is **not a part**: no `CE-*` code, no
/// `CodeSpecPart` value, no row in the parts catalogue. It sits in a file of
/// its own for the same reason — it belongs to whichever declaration it
/// annotates, in any locus and slice.
library;

/// One authored completion on the annotated declaration
/// (`codespecs_derivation_contract.md` §2.10).
///
/// Repeatable: a declaration carries one per completed fact, in the register's
/// order. Example — an entity whose specification names no datasource:
///
/// ```dart
/// @CsTable('mom_order', datasource: 'main')
/// @CsCompletion('AC-1', fact: 'datasource', value: 'main')
/// class Order { … }
/// ```
///
/// The value is the **rule's**, not the agent's choice: two runs over one
/// specification write the same completions, and a validator check
/// (`codespecs_derivation_contract.md` §6 check 47) holds each to its rule.
class CsCompletion {
  /// The rule of the register, `AC-<n>`.
  ///
  /// **Required, first positional**: a completion without a rule is an
  /// invented value, which the contract does not admit.
  final String rule;

  /// The fact the rule completes, as the register names it (`datasource`).
  final String fact;

  /// The completed value, as the code carries it.
  final String value;

  /// Optional note.
  final String? note;

  /// Records that [rule] completed [fact] with [value] on the annotated
  /// declaration.
  const CsCompletion(
    this.rule, {
    required this.fact,
    required this.value,
    this.note,
  });
}
