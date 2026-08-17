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
/// The closed catalogues these markers select from live in `vocabulary.dart`,
/// and the typed cross-part references they cite in `cross_part_refs.dart`.
library;

import 'cross_part_refs.dart';
import 'vocabulary.dart';

/// CE-EL — a UI element by semantic type (the generic element part,
/// `codespecs_mapping.md` §5.18).
///
/// Covers **standalone** elements. An element that is a *member of a form* is
/// emitted by CE-FM instead (`codespecs_mapping.md` §5.7.2), because the form
/// owns its field list.
class CsElement {
  /// The element's semantic type, from the closed ten-kind catalogue.
  ///
  /// **Required**: it selects both the per-kind attribute set and the default
  /// widget, and no kind is a sensible default.
  ///
  /// Every per-kind extra — `maxLength`, `keyboardType`, `maxLines`,
  /// `obscureText`, `variant`, `icon` — maps onto a named `tom_flutter_ui`
  /// widget property and is therefore carried by the [CsWidget] instantiation,
  /// never duplicated here. The element's value type is the declaration's
  /// generic.
  final CsElementKind kind;

  /// Optional part-specific note.
  final String? note;

  const CsElement({required this.kind, this.note});
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
  /// The layout node's id.
  ///
  /// **Required, first positional, verbatim.** It is the one thing the ACL
  /// substrate genuinely lacks: `codespecs_mapping.md` §4.1 records the layout
  /// *node model* as a gap, the `Acl*` classes carry no id of their own, and the
  /// whole `codespecs_mapping.md` §5.22 override-delta grammar addresses nodes
  /// by id.
  ///
  /// Container kind is **not** an argument — it is which `Acl*` class is
  /// instantiated; slot hints are `AclComponent` properties.
  ///
  /// Deltas addressing nodes by id string is not a `codespecs_mapping.md` §5.23
  /// violation: a delta targets a node *within the same layout declaration*, so
  /// the id is a local coordinate, not a cross-part reference.
  final String nodeId;

  /// Optional part-specific note.
  final String? note;

  const CsLayout(this.nodeId, {this.note});
}

/// CE-TX — a text element (labels, copy, messages).
///
/// Marks a member of a document's message-key catalogue. The **key** is not an
/// argument: it is the `CsMessageKey` const the member holds.
class CsText {
  /// The base-language copy, verbatim from the specification.
  ///
  /// **Required** — a message key with no copy is a key with no message.
  ///
  /// Its **parameters are derived**, not authored: `codespecs_mapping.md` §5.21
  /// reads them out of this string's placeholders, so a second parameter list
  /// would be a source that could disagree with the copy it describes.
  final String baseCopy;

  /// What this copy is *for*, which selects its resolution path.
  final CsTextRole role;

  /// Which catalogue half the key belongs to.
  ///
  /// A validator asserts `role == error ⇒ category == errorCopy`
  /// (`codespecs_derivation_contract.md` §6 check 10): error copy is keyed by
  /// the CE-ER error code, so the two cannot disagree.
  final CsTextCategory category;

  /// Optional part-specific note.
  final String? note;

  const CsText({
    required this.baseCopy,
    this.role = CsTextRole.generic,
    this.category = CsTextCategory.uiCopy,
    this.note,
  });
}

/// CE-VA — a client-side validation rule.
///
/// The part marker. Where the spec distinguishes *which shape* of rule a code
/// element is, [CsFieldRule] and [CsFormRule] mark it — see their doc comments
/// for why the split is annotated rather than inferred.
class CsValidation {
  /// The standard rules constraining the field this marker rides, in the
  /// `codespecs_mapping.md` §5.19 declaration grammar.
  ///
  /// Comma-separated `<name>` / `<name>:<arg>` / `<name>:<arg1>:<arg2>` terms,
  /// e.g. `'required, minLength:8, pattern:^[A-Z]'`. The names are the nine
  /// declarable tokens carried by `tom_flutter_ui`'s `Validators`; argument
  /// values are verbatim from the SOM constraint.
  ///
  /// **This is the one place a declaration string beats typed arguments.** The
  /// rule set is a composition of variable arity — a field carries any subset in
  /// any order — which a fixed parameter list cannot express, and the grammar is
  /// specified and parsed rather than free-form. `compose` is deliberately
  /// **not** declarable (`codespecs_derivation_contract.md` §6 check 14).
  ///
  /// Empty on a shared rule-library holder, which marks the part without
  /// constraining a field.
  ///
  /// **Named, not positional.** `codespecs_derivation_contract.md` §2.3 makes
  /// the authored identifier the first *positional* argument, but this marker
  /// has no identifier — it rides an existing field — and Dart forbids a
  /// signature carrying both optional-positional and named parameters. Keeping
  /// [note] named, as it is on all 38 other markers, therefore requires this to
  /// be named too.
  final String rules;

  /// Optional part-specific note.
  final String? note;

  const CsValidation({this.rules = '', this.note});
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
  /// The message key of the copy shown when the rule fails.
  ///
  /// **Required** — a rule that can fail without saying why is not authored, it
  /// is unfinished.
  ///
  /// The rule's *kind* and its arguments are not arguments here: the function
  /// signature and body are the rule. "Async/slow" is read off the declared
  /// `Future` return type, not declared twice.
  final CsMessageKey errorKey;

  /// Optional part-specific note.
  final String? note;

  const CsFieldRule({required this.errorKey, this.note});
}

/// CE-VA — a **cross-field** validation rule (`codespecs_mapping.md` §5.19).
///
/// Marks a form-level invariant: a method on the `TomForm` subclass that reads
/// several fields and yields a `FormValidationError` naming the offending ones.
/// A form rule is deliberately **not** expressible in the per-field declaration
/// string — the grammar cannot name a second field — so it is authored on the
/// form, and this marker is what says so.
class CsFormRule {
  /// The message key of the cross-field failure copy.
  ///
  /// **Required**, for the same reason as [CsFieldRule.errorKey].
  ///
  /// The **involved fields** are not an argument: the method reads them, so the
  /// declaration already carries them. Per-field error keys are derived from
  /// `FormValidationError.fieldErrorKeys` at implementation time.
  final CsMessageKey errorKey;

  /// Optional part-specific note.
  final String? note;

  const CsFormRule({required this.errorKey, this.note});
}

/// CE-AC — a user action (a command the user can invoke).
class CsAction {
  /// Optional part-specific note.
  final String? note;

  const CsAction({this.note});
}

/// CE-AC — a trigger: the event that fires a [CsAction] (`codespecs_mapping.md`
/// §5.10, §5.20).
///
/// One [CsAction] may carry several triggers of different kinds. Endpoints are
/// typed references to the generated declarations (`codespecs_mapping.md`
/// §5.23), never id strings, so a rename is a compile break.
///
/// **The common head is [kind] + [action]; everything after it is a per-kind
/// slot.** Dart annotations have no sum types, so each kind's attributes are
/// separate optional arguments and a validator asserts only the declared kind's
/// are non-null (`codespecs_derivation_contract.md` §6 check 8) — the
/// annotation-level rendering of `codespecs_mapping.md` §8.2's `@OneOf`/`@Case`
/// closed-choice design.
///
/// | [kind] | Slots it may fill |
/// |--------|-------------------|
/// | `userGesture` | [element], [gesture] |
/// | `inFormEvent` | [form], [formEvent], [formField] |
/// | `lifecycle` | [scope], [phase] |
/// | `serverEvent` | [channel], [eventType] |
/// | `condition` | *none* |
///
/// `condition` carries no slot because its predicate over CE-ST state is real
/// Dart — a closure the `TomActionTrigger` constructor takes, as is the optional
/// guard available to every kind.
class CsTrigger {
  /// Which of the five closed invocation paths fires the action.
  ///
  /// **Required**: it selects which per-kind slot set applies, so it cannot be
  /// inferred from the annotated declaration and no arm is a sensible default.
  final CsTriggerKind kind;

  /// The action this trigger fires.
  ///
  /// **Required** — a trigger with no target is not a trigger. Together with the
  /// per-kind source slot this is the **single authoring home** of the
  /// element→action edge (`codespecs_mapping.md` §5.10); the element's own
  /// action edge is derived from it rather than authored twice.
  final CsActionRef action;

  /// `userGesture`: the element the gesture acts on.
  final CsElementRef? element;

  /// `userGesture`: which gesture.
  final CsGesture? gesture;

  /// `inFormEvent`: the form the event comes from.
  final CsFormRef? form;

  /// `inFormEvent`: which form event.
  final CsFormEvent? formEvent;

  /// `inFormEvent`: for a `fieldChange` event, which field changed.
  final CsElementRef? formField;

  /// `lifecycle`: whose lifecycle — screen, route or app.
  final CsLifecycleScope? scope;

  /// `lifecycle`: which phase of that scope.
  final CsLifecyclePhase? phase;

  /// `serverEvent`: the push channel the event arrives on.
  ///
  /// A string, not a ref: channel names are open, deployment-declared values
  /// (`codespecs_mapping.md` §5.23), so there is no Dart declaration to resolve
  /// against.
  final String? channel;

  /// `serverEvent`: the event type within that channel.
  final String? eventType;

  /// Optional part-specific note.
  final String? note;

  const CsTrigger({
    required this.kind,
    required this.action,
    this.element,
    this.gesture,
    this.form,
    this.formEvent,
    this.formField,
    this.scope,
    this.phase,
    this.channel,
    this.eventType,
    this.note,
  });
}

/// CE-SC — a server call made from the client.
///
/// The middle hop of `codespecs_mapping.md` §5.3's chain:
/// `@CsAction ──triggers──▶ @CsServerCall ──operation──▶ @CsEndpoint`.
class CsServerCall {
  /// The shared CE-API operation this call invokes.
  ///
  /// **Required, first positional.** It is the one edge the code cannot carry
  /// itself: the call site is client, the operation is shared, and nothing in
  /// the Dart declaration names the link.
  ///
  /// Call options are `TomServerCallSpecs`'s own surface; request assembly,
  /// response handling and error handling are the declaration's methods.
  final CsOperationRef operation;

  /// Optional part-specific note.
  final String? note;

  const CsServerCall(this.operation, {this.note});
}

/// CE-ST — a view model: client-side presentation state.
class CsViewModel {
  /// How long the view state lives.
  ///
  /// Defaults to [CsLifecycleScope.screen], the narrowest arm — so widening a
  /// view model's lifetime is a deliberate authored act.
  ///
  /// The fields, their types and their binding are the declaration; binding to a
  /// widget is `TomObservingWidget`'s own surface.
  final CsLifecycleScope scope;

  /// Optional part-specific note.
  final String? note;

  const CsViewModel({this.scope = CsLifecycleScope.screen, this.note});
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
