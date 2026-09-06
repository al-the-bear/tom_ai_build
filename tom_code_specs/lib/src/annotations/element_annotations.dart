/// Client / UI CodeSpecs part markers (`Cs*`).
///
/// Each annotation in this file marks a CodeSpec class (or member) as realising
/// a particular *client-side* CodeSpecs part from the authoritative parts
/// catalogue (`codespecs_mapping.md` §4.1). They are pure markers: a CodeSpec
/// is an ordinary class **built on** an existing `tom_core`-family class and
/// *enriched* by one of these markers — there is no `Cs*` base class to extend.
/// Every marker carries an optional `note` — [CsElement.note] is
/// representative — recording part-specific intent inline.
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

  /// Marks the annotated declaration as a **standalone** CE-EL element of
  /// semantic type [kind].
  ///
  /// [kind] draws from [CsElementKind] (`vocabulary.dart`), the closed
  /// catalogue mirroring `codespecs_mapping.md` §5.18. It is required with no
  /// default because it selects two things at once — the per-kind attribute
  /// set, and the default widget the CE-EL two-step (`codespecs_mapping.md`
  /// §5.7.1) resolves to. No arm is a safe fallback: an element that is a
  /// [CsElementKind.textInput] because nothing said otherwise renders a
  /// free-text box for a date.
  ///
  /// Only the class-level arms belong here: [CsElementKind.button],
  /// [CsElementKind.menuEntry], [CsElementKind.label] and
  /// [CsElementKind.formHost]. The value-carrying arms are declared as
  /// **members of a [CsForm]** instead, which emits them itself
  /// (`codespecs_mapping.md` §5.7.2) because the form owns its field list;
  /// writing one of them on a standalone declaration produces an element no
  /// form will render.
  ///
  /// Every per-kind extra — `maxLength`, `keyboardType`, `maxLines`,
  /// `obscureText`, `variant`, `icon` — is a named property of a
  /// `tom_flutter_ui` widget and is carried by the [CsWidget] instantiation,
  /// never duplicated here. The element's value type is the declaration's own
  /// generic.
  const CsElement({required this.kind, this.note});
}

/// CE-EL — the concrete `tom_flutter_ui` widget realising a [CsElement]'s
/// semantic type (`codespecs_mapping.md` §5.7.1, §5.18).
class CsWidget {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated declaration as the concrete `tom_flutter_ui` widget
  /// realising a [CsElement]'s semantic kind.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): the widget's
  /// configuration *is* the instantiation. Every per-kind property [CsElement]
  /// deliberately withheld lands on the widget's own constructor, so there is
  /// nothing left for an argument to hold.
  ///
  /// This is the implementation half of the CE-EL two-step
  /// (`codespecs_mapping.md` §5.7.1): [CsElement] states the semantics, this
  /// marker states what draws them. Keeping the two apart is what lets a
  /// specification stay at the semantic level while the generated code stays
  /// typed — collapse them and a spec author is choosing widgets.
  const CsWidget({this.note});
}

/// CE-FM — a form: the grouping of elements into forms and subforms.
class CsForm {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated class as a CE-FM form.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2). A form's whole
  /// content is its members: each value-carrying element is a **member of this
  /// class** rather than a separate [CsElement], because the form owns its
  /// field list (`codespecs_mapping.md` §5.7.2). Nesting is structural in the
  /// same way — a subform is a member typed as another `@CsForm` class — so
  /// neither the field list nor the grouping is an argument.
  ///
  /// Constraints are authored beside the members, not here: per-field rules as
  /// a [CsValidation] declaration string on the member, cross-field invariants
  /// as [CsFormRule] methods on this class.
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

  /// Declares the annotated declaration as the CE-LO layout node [nodeId].
  ///
  /// [nodeId] is the sole positional argument and the only thing this marker
  /// carries, because it is the only thing the ACL substrate genuinely lacks:
  /// `codespecs_mapping.md` §4.1 records the layout *node model* as a gap and
  /// the `Acl*` classes carry no id of their own. The whole
  /// `codespecs_mapping.md` §5.22 override-delta grammar addresses nodes by
  /// this id, so renaming a node silently orphans every delta aimed at it — the
  /// layout still builds, it just stops being overridden.
  ///
  /// Addressing nodes by id string is not a `codespecs_mapping.md` §5.23
  /// violation: a delta targets a node *within the same layout declaration*, so
  /// the id is a local coordinate rather than a cross-part reference.
  ///
  /// The container **kind** is not an argument — it is which `Acl*` class the
  /// declaration instantiates — and slot hints are `AclComponent` properties.
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

  /// Declares the annotated catalogue member as CE-TX copy reading [baseCopy],
  /// filling the [role] slot of the [category] half of the message-key
  /// catalogue.
  ///
  /// The **key** is not an argument: it is the `CsMessageKey` const the
  /// annotated member holds.
  ///
  /// [baseCopy] is required and is the base-language string verbatim from the
  /// specification — a message key with no copy is a key with no message. Its
  /// **parameters are derived**, never authored: `codespecs_mapping.md` §5.21
  /// reads them out of this string's placeholders, so a second parameter list
  /// would be a source that could disagree with the copy it describes.
  ///
  /// [role] draws from [CsTextRole] and [category] from [CsTextCategory], both
  /// in `vocabulary.dart` (`codespecs_derivation_contract.md` §5.3). They
  /// default to [CsTextRole.generic] and [CsTextCategory.uiCopy] — ordinary
  /// interface copy — so only specialised copy states them. The two are **not
  /// independent**: `codespecs_derivation_contract.md` §6 check 10 asserts that
  /// `role == error` implies `category == errorCopy`, because error copy is
  /// keyed by its CE-ER error code and resolved through a different lookup from
  /// the dotted-key half. Getting the pair wrong files the copy in a half
  /// nothing will look in.
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

  /// Marks the annotated field as CE-VA validated, constrained by [rules].
  ///
  /// [rules] is written in `codespecs_mapping.md` §5.19's declaration grammar:
  /// comma-separated `<name>` / `<name>:<arg>` / `<name>:<arg1>:<arg2>` terms,
  /// for example `'required, minLength:8, pattern:^[A-Z]'`. The names are the
  /// nine declarable tokens `tom_flutter_ui`'s `Validators` carries —
  /// `required`, `email`, `minLength`, `maxLength`, `pattern`, `min`, `max`,
  /// `minItems`, `maxItems` — and argument values are verbatim from the SOM
  /// constraint. `compose` is deliberately **not** declarable, and emitting it
  /// fails `codespecs_derivation_contract.md` §6 check 14.
  ///
  /// It defaults to the empty string, which is the shared rule-library holder's
  /// case: the marker names the part without constraining any field.
  ///
  /// This is the one place in the package where a declaration string beats
  /// typed arguments — the rule set is a composition of variable arity, which a
  /// fixed parameter list cannot express, and the grammar is specified and
  /// parsed rather than free-form.
  ///
  /// [rules] is **named, not positional**, departing from
  /// `codespecs_derivation_contract.md` §2.3's first-positional-identifier rule
  /// for a mechanical reason recorded in `codespecs_derivation_contract.md` §5.1: this marker has no
  /// identifier —
  /// it rides an existing field — and Dart forbids one signature carrying both
  /// optional-positional and named parameters, so keeping [note] named forces
  /// this to be named too.
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

  /// Marks the annotated single-field rule as CE-VA, failing with the copy at
  /// [errorKey].
  ///
  /// [errorKey] is a required [CsMessageKey] const, never a string: the copy
  /// lives in the CE-TX catalogue and is cited from there. A rule that can fail
  /// without saying why is not authored, it is unfinished — which is why there
  /// is no default.
  ///
  /// The rule's **kind and its arguments are not arguments here**: the function
  /// signature and body are the rule. Whether it is asynchronous is read off
  /// the declared `Future` return type rather than declared a second time.
  ///
  /// Reach for this marker only for a *project-specific* rule, which is real
  /// Dart code and would otherwise be indistinguishable from a form rule. The
  /// nine standard rules are authored as a [CsValidation] declaration string on
  /// the field and need no marker at all.
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

  /// Marks the annotated form-level method as a CE-VA **cross-field** rule,
  /// failing with the copy at [errorKey].
  ///
  /// [errorKey] is a required [CsMessageKey] const, for the same reason as
  /// [CsFieldRule.errorKey].
  ///
  /// The **involved fields are not an argument**: the method reads them, so the
  /// declaration already names them, and per-field error keys are derived from
  /// `FormValidationError.fieldErrorKeys` at implementation time.
  ///
  /// This marker is what *says* the rule is cross-field. The per-field
  /// declaration grammar cannot name a second field (`codespecs_mapping.md`
  /// §5.19), so the split is annotated rather than inferred, and a cross-field
  /// invariant written as a [CsValidation] term has nowhere to put the sibling
  /// it needs to read.
  const CsFormRule({required this.errorKey, this.note});
}

/// CE-AC — a user action (a command the user can invoke).
class CsAction {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated declaration as a CE-AC user action.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): CE-AC is full reuse
  /// of `tom_flutter_ui`'s action classes (`codespecs_mapping.md` §5.10), whose
  /// own surface holds everything an action configures.
  ///
  /// What *fires* the action is not here either — that is a separate
  /// [CsTrigger], one per invocation path, and a single action may carry
  /// several of different kinds. The server call an action issues is a
  /// [CsServerCall] citing the operation, the middle hop of
  /// `codespecs_mapping.md` §5.3's `@CsAction ──triggers──▶ @CsServerCall
  /// ──operation──▶ @CsEndpoint` chain.
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

  /// Declares the annotated trigger as firing [action] by way of [kind],
  /// filling the slots that kind admits.
  ///
  /// [kind] draws from [CsTriggerKind] (`vocabulary.dart`), the closed five-arm
  /// taxonomy of `codespecs_mapping.md` §5.20, and is required with no default:
  /// it selects which slot set applies and cannot be inferred from the
  /// annotated declaration. [action] is a required [CsActionRef] — a trigger
  /// with no target is not a trigger.
  ///
  /// **Fill only the slots [kind] admits.** Dart annotations have no sum types,
  /// so each kind's payload is a separate optional argument:
  ///
  /// - [CsTriggerKind.userGesture] → [element], [gesture]
  /// - [CsTriggerKind.inFormEvent] → [form], [formEvent], [formField]
  /// - [CsTriggerKind.lifecycle] → [scope], [phase]
  /// - [CsTriggerKind.serverEvent] → [channel], [eventType]
  /// - [CsTriggerKind.condition] → *no slot*; its predicate over CE-ST state is
  ///   real Dart — a closure the `TomActionTrigger` constructor takes, as is
  ///   the optional guard available to every kind.
  ///
  /// A slot belonging to another kind is not ignored, it is a violation:
  /// `codespecs_derivation_contract.md` §6 check 8 asserts only the declared
  /// kind's slots are non-null. That check runs at **generation time** by
  /// necessity — Dart does not const-evaluate an annotation, so a
  /// const-constructor `assert` here would let `@CsTrigger(kind: userGesture,
  /// form: …)` through `dart analyze` untouched while reading as though it
  /// guarded something.
  ///
  /// [element], [form] and [formField] are typed consts, so a rename is a
  /// compile break; [channel] and [eventType] are plain strings because a push
  /// channel is an open, deployment-declared name with no Dart declaration to
  /// resolve against (`codespecs_mapping.md` §5.23).
  ///
  /// Together with its per-kind source slot, this constructor is the **single
  /// authoring home** of the element→action edge (`codespecs_mapping.md`
  /// §5.10); the element's own edge is derived from it rather than authored
  /// twice.
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

  /// Declares the annotated declaration as the CE-SC call that invokes
  /// [operation].
  ///
  /// [operation] is the sole positional argument: a required [CsOperationRef]
  /// const cited from the shared operation catalogue, never a fresh
  /// `CsOperationRef('…')` written at the call site, which would put the string
  /// back into client code and take the rename break away.
  ///
  /// It is the one edge the code cannot carry for itself — the call site is
  /// client, the operation is shared, and nothing in the Dart declaration names
  /// the link — which makes it the middle hop of `codespecs_mapping.md` §5.3's
  /// `@CsAction ──triggers──▶ @CsServerCall ──operation──▶ @CsEndpoint` chain.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves the string it
  /// wraps.
  ///
  /// Call options are `TomServerCallSpecs`'s own surface; request assembly,
  /// response handling and error handling are the declaration's methods.
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

  /// Marks the annotated class as a CE-ST view model whose presentation state
  /// lives for [scope].
  ///
  /// [scope] draws from [CsLifecycleScope] (`vocabulary.dart`) and defaults to
  /// [CsLifecycleScope.screen], the narrowest arm — so widening a view model's
  /// lifetime to [CsLifecycleScope.route] or [CsLifecycleScope.app] is a
  /// deliberate authored act rather than a value that drifted. The cost of
  /// overstating it is state that outlives the screen it belonged to and is
  /// found already populated on the next visit; the cost of understating it is
  /// state discarded between two screens that were meant to share it.
  ///
  /// The fields, their types and their binding are the declaration itself;
  /// binding a widget to them is `TomObservingWidget`'s own surface, not an
  /// argument here.
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

  /// Marks the annotated declaration as a CE-NV route — one navigable screen.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): the route is built on
  /// `TomPageRoute`, and the route-id registry the substrate lacks is a
  /// `tom_core_codespecs` gap class, so the marker holds neither the id nor the
  /// destination.
  ///
  /// Routes are the one sanctioned several-declarations-per-file case: all of a
  /// document's routes land together in the navigation catalogue
  /// (`codespecs_derivation_contract.md` §2.1 N7), which is also where the
  /// [CsRouteRef] consts citing them are declared. The edges *between* routes
  /// are [CsScreenFlow], never this marker.
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

  /// Marks the annotated declaration as the CE-NV screen-flow model.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): the edge model is a
  /// `tom_core_codespecs` gap class whose own constructor carries the edges,
  /// and the authoring surface is the SOM screen-flow section.
  ///
  /// What belongs here rather than on [CsRoute] is everything *between* screens
  /// — which [CsForm] a screen presents and whether it replaces the current
  /// screen or overlays it as a popup, and the conditional targets an
  /// action-fired edge resolves to: success to a confirmation screen or back to
  /// the previous one, an error or validation failure to an error display.
  /// Client locus (`codespecs_mapping.md` §4.2).
  const CsScreenFlow({this.note});
}
