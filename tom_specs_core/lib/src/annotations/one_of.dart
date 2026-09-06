/// Declares a **discriminated subsection group** (closed choice) on a
/// container section class (`codespecs_mapping.md` §8.2, csm-7-4/csmb6).
///
/// A section that must resolve to **exactly one of a closed set of typed
/// alternatives** carries `@OneOf` naming the `@Form` field whose value picks
/// the alternative. The alternatives are the container's complex-subsection
/// fields, each bound to one or more discriminator values by [Case]; a
/// subsection with no `@Case` is *common* (present for every case, e.g.
/// `resources` / `layout`).
///
/// The [discriminator] **must be a model enum** `@Form` field (per
/// `codespecs_mapping.md` §8.2 item 1 / the domain-enum registry, and YRD7
/// which already requires form-field enum types
/// to be model enums). Keeping the discriminator an enum is what lets the
/// static validator check case coverage and lets the instance validator pick
/// the single active alternative.
///
/// It lives in `tom_specs_core` — like `@CodeSpecKind`, `@MapsTo`, `@DetailedIn`
/// — because it annotates the *model* (SOM) classes, and is carried losslessly
/// into the exported model and the SOM meta tree's generic `extra` list (no
/// dedicated meta slot), so both enforcement tiers can read it without an
/// analyzer.
///
/// Two enforcement tiers act on it (`codespecs_mapping.md` §8.2):
///
///  * **Static** (`tom_specs_clitool/lib/src/validator.dart`): the discriminator
///    resolves to a model-enum `@Form` field; every `@Case` value is a constant
///    of that enum; the cases *cover* the enum, except for the constants
///    declared in [noCase]; every `@Case`-bound field is a complex subsection of
///    the same container.
///  * **Instance** (the runtime DocSpecs document validator + editor strict
///    mode): a concrete section carries **only** the subsections whose `@Case`
///    matches the chosen discriminator value (plus the common, un-`@Case`d
///    ones) and **at most one** per case.
///
/// Example:
/// ```dart
/// @OneOf(
///   discriminator: 'elementType',
///   noCase: [
///     ScreenElementKind.divider,
///     ScreenElementKind.spacer,
///     ScreenElementKind.tabBar,
///   ],
/// )
/// class ScreenElementEntry extends DocSpecsSection {
///   @Form([Field('elementType', ScreenElementKind, 'Element Type')])
///   @override
///   String? content;
///
///   @Case(ScreenElementKind.actionButton)
///   @Case(ScreenElementKind.link)
///   ScreenElementAction? elementAction;
///   // resources / layout carry no @Case → common to every case.
/// }
/// ```
class OneOf {
  /// The name of the `@Form` field (a model enum) whose value selects the
  /// active alternative.
  final String discriminator;

  /// The discriminator constants that **deliberately bind no case** — kinds
  /// whose whole surface is the common subsections, so there is no per-kind
  /// payload to promote.
  ///
  /// Without this, an attribute-free kind and a kind whose case was simply
  /// forgotten are indistinguishable, and the static validator's coverage check
  /// has to warn about both. Listing the constant turns the decision from prose
  /// beside the enum into something the validator reads: an uncovered constant
  /// that is *not* listed here still warns, and a constant listed here that a
  /// `@Case` does cover is an error, so the list cannot quietly go stale.
  ///
  /// Declared as `List<Object>` for the same reason [Case.value] is `Object` —
  /// one annotation type must accept whichever model enum the container
  /// discriminates on. Each entry is carried losslessly as its qualified
  /// `EnumType.constant` token.
  final List<Object> noCase;

  /// Optional explanation of the closed choice this group models.
  final String? note;

  /// Declares the annotated container as a closed choice discriminated by
  /// [discriminator].
  ///
  /// [discriminator] is required because the group has no meaning without the
  /// field that picks between its alternatives; [noCase] defaults to empty, so
  /// a group in which every constant carries a case is the one-argument form.
  const OneOf({required this.discriminator, this.noCase = const [], this.note});
}
