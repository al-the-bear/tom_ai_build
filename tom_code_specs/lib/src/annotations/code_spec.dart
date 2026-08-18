/// The CodeSpecs identity + forward-trace annotation (CE-TR).
///
/// `@CodeSpec` marks an ordinary Dart class as a *CodeSpec*: a class built on an
/// existing `tom_core`-family class (`tom_core_kernel` / `_flutter` / `_server`
/// / `_d4rt` / `tom_flutter_ui`) that realises one or more DocSpecs sections in
/// skeletal, compilable code (`codespecs_mapping.md` §9). It carries no
/// implementation of its own — a CodeSpec is *composed* from a `tom_core` base
/// plus the `Cs*` part markers ([CsForm], [CsTable], …) and this identity
/// annotation.
///
/// The three fields form the forward (doc → code) half of the traceability
/// link:
/// - [id] — a stable identifier for this CodeSpec element (e.g. `UI-ORDER-LIST`).
/// - [source] — the SOM `@SectionId`s of the DocSpecs sections this code
///   realises.
/// - [requirements] — the requirement ids (RSP / RC) this code satisfies.
///
/// The code → doc back-trace is carried by the companion `@DocSpec` annotation.
/// The two are **not** placed alike, and `codespecs_derivation_contract.md`
/// §2.5 is where that asymmetry is stated: `@CodeSpec` sits on the top-level
/// declaration — the *emission unit* — and never on a member, while `@DocSpec`
/// sits on every declaration that consumed a section, member or not. So
/// [source] accounts for the **whole** unit: a section only a member cites
/// still belongs in the class's [source], because the gap analysis reads
/// [source] and never looks inside a class.
///
/// Example:
/// ```dart
/// @CsForm()
/// @CodeSpec('UI-ORDER-LIST', source: ['UP-ORDER-LIST'],
///     requirements: ['RC-ORD-010', 'RC-ORD-011'])
/// class OrderListForm { ... }
/// ```
class CodeSpec {
  /// Stable identifier for this CodeSpec element.
  final String id;

  /// SOM `@SectionId`s of the DocSpecs sections this code realises.
  final List<String> source;

  /// Requirement ids (RSP / RC) this code satisfies.
  final List<String> requirements;

  const CodeSpec(
    this.id, {
    this.source = const [],
    this.requirements = const [],
  });
}
