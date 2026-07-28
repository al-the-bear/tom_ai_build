/// Client / UI CodeSpecs part markers (`Cs*`).
///
/// Each annotation in this file marks a CodeSpec class (or member) as realising
/// a particular *client-side* CodeSpecs part from the authoritative parts
/// catalogue (`codespecs_mapping.md` §4.1). They are pure markers: a CodeSpec
/// is an ordinary class **built on** an existing `tom_core`-family class and
/// *enriched* by one of these markers — there is no `Cs*` base class to extend.
/// The optional [note] on each marker records part-specific intent inline.
///
/// The `CE-*` code named by each doc comment is the part's **stable registry
/// key** (`codespecs_mapping.md` §4.1: never reused, never renamed) — several
/// markers share one key, because a part may be carried by more than one
/// annotation (CE-EL by [CsElement] + [CsWidget], CE-AC by [CsAction] +
/// [CsTrigger], CE-NV by [CsRoute] + [CsScreenFlow]).
///
/// This file covers the fourteen client/UI part markers. Server-side markers live
/// in `service_annotations.dart`; shared markers in `contract_annotations.dart`.
library;

/// CE-EL — a UI element by semantic type (the generic element part,
/// `codespecs_mapping.md` §5.18).
class CsElement {
  /// Optional part-specific note.
  final String? note;

  const CsElement({this.note});
}

/// CE-EL — the concrete `tom_flutter_ui` widget realising a [CsElement]'s
/// semantic type (`codespecs_mapping.md` §5.7.1, §5.18).
class CsWidget {
  /// Optional part-specific note.
  final String? note;

  const CsWidget({this.note});
}

/// CE-FM — a form: the grouping of elements into forms and subforms.
class CsForm {
  /// Optional part-specific note.
  final String? note;

  const CsForm({this.note});
}

/// CE-LO — a screen layout (structural arrangement of elements,
/// `codespecs_mapping.md` §5.2, §5.12).
class CsLayout {
  /// Optional part-specific note.
  final String? note;

  const CsLayout({this.note});
}

/// CE-TX — a text element (labels, copy, messages).
class CsText {
  /// Optional part-specific note.
  final String? note;

  const CsText({this.note});
}

/// CE-VA — a client-side validation rule.
///
/// The part marker. Where the spec distinguishes *which shape* of rule a code
/// element is, [CsFieldRule] and [CsFormRule] mark it — see their doc comments
/// for why the split is annotated rather than inferred.
class CsValidation {
  /// Optional part-specific note.
  final String? note;

  const CsValidation({this.note});
}

/// CE-VA — a **single-field** validation rule (`codespecs_mapping.md` §5.19).
///
/// Marks a standalone `Validator<T>` — a typed value in, a `ValidationResult`
/// out — or a registered custom entry in `TomValidatorRegistry`. The standard
/// rules (`required`, `email`, `minLength`, `maxLength`, `pattern`, `min`,
/// `max`, `minItems`, `maxItems`) are carried by `tom_flutter_ui`'s `Validators`
/// and are authored as a declaration string on the field, so they need no
/// marker; this annotation exists for the **project-specific** rule, which is
/// real Dart code and would otherwise be indistinguishable from a form rule.
///
/// Split from [CsFormRule] because the two have different *signatures*, not
/// merely different scopes: a field rule cannot see its siblings, which is
/// precisely what makes it composable into the declaration string.
class CsFieldRule {
  /// Optional part-specific note.
  final String? note;

  const CsFieldRule({this.note});
}

/// CE-VA — a **cross-field** validation rule (`codespecs_mapping.md` §5.19).
///
/// Marks a form-level invariant: a method on the `TomForm` subclass that reads
/// several fields and yields a `FormValidationError` naming the offending ones.
/// A form rule is deliberately **not** expressible in the per-field declaration
/// string — the grammar cannot name a second field — so it is authored on the
/// form, and this marker is what says so.
class CsFormRule {
  /// Optional part-specific note.
  final String? note;

  const CsFormRule({this.note});
}

/// CE-AC — a user action (a command the user can invoke).
class CsAction {
  /// Optional part-specific note.
  final String? note;

  const CsAction({this.note});
}

/// How an action is invoked (`codespecs_mapping.md` §5.20).
///
/// The taxonomy is **closed**: a new invocation path is an edit to this
/// classification, not a free-form attribute — the same closed-catalogue
/// discipline as `codespecs_mapping.md` §5.18 (elements) and
/// `codespecs_mapping.md` §5.19 (validation rules). The kinds are a *documented
/// framing* over the reused `tom_flutter_ui` action classes (`TomAction` has no
/// trigger concept of its own), which is why the vocabulary lives on the
/// annotation rather than in a new class: `codespecs_mapping.md` §5.10/§5.20
/// record CE-AC as "no gap — full action implementation reused".
enum TriggerKind {
  /// Fired by a user acting on a CE-EL element (tap / press / long-press).
  userGesture,

  /// Fired by a CE-FM form event (field change, submit, validation pass/fail).
  inFormEvent,

  /// Fired by a screen, route or app lifecycle phase.
  lifecycle,

  /// Fired by an inbound server push or notification.
  serverEvent,

  /// Fired by a reactive predicate over CE-ST observable state — the
  /// `canExecute` case.
  condition,
}

/// CE-AC — a trigger: the event that fires a [CsAction] (`codespecs_mapping.md`
/// §5.10, §5.20).
///
/// [kind] is **required**: it selects which per-kind attribute set the trigger
/// carries (`codespecs_mapping.md` §5.20's five-row table), so it cannot be
/// inferred from the annotated declaration and no arm is a sensible default.
/// One [CsAction] may carry several triggers of different kinds.
///
/// The trigger is the **single authoring home** of the element→action edge
/// (`codespecs_mapping.md` §5.10): it names both endpoints, and the element's
/// action edge is derived from it rather than authored twice. Endpoints are
/// typed references to the generated declarations (`codespecs_mapping.md`
/// §5.23), never id strings, so a rename is a compile break.
class CsTrigger {
  /// Which of the five closed invocation paths fires the action.
  final TriggerKind kind;

  /// Optional part-specific note.
  final String? note;

  const CsTrigger({required this.kind, this.note});
}

/// CE-SC — a server call made from the client.
class CsServerCall {
  /// Optional part-specific note.
  final String? note;

  const CsServerCall({this.note});
}

/// CE-ST — a view model: client-side presentation state.
class CsViewModel {
  /// Optional part-specific note.
  final String? note;

  const CsViewModel({this.note});
}

/// CE-NV — a route: one navigable screen, identified by a stable route id
/// (`codespecs_mapping.md` §5.11).
///
/// Built on `TomPageRoute` (`tom_flutter_ui`). The route-id registry the
/// substrate lacks is a `tom_core_codespecs` gap class; the edges *between*
/// routes are [CsScreenFlow].
class CsRoute {
  /// Optional part-specific note.
  final String? note;

  const CsRoute({this.note});
}

/// CE-NV — the screen-flow model: how screens are reached from one another
/// (`codespecs_mapping.md` §5.11).
///
/// The second CE-NV marker beside [CsRoute]. Where [CsRoute] names *a* screen,
/// `@CsScreenFlow` records the edges that combine the D05 ISC interaction
/// scenarios into interactions with screens:
///
/// - **Form → screen assignment** — which form ([CsForm]) a screen presents, and
///   whether it *replaces* the current screen or *overlays* it as a popup.
/// - **Action-triggered, conditional targets** — an edge is fired by a
///   [CsAction] and its target depends on the outcome: success reaches a
///   confirmation screen or returns to the previous one; an error or validation
///   error reaches an error display.
///
/// Lives in the client project (`codespecs_mapping.md` §4.2). The edge model
/// itself is a `tom_core_codespecs` gap class; the authoring surface is the SOM
/// screen-flow section.
class CsScreenFlow {
  /// Optional part-specific note.
  final String? note;

  const CsScreenFlow({this.note});
}
