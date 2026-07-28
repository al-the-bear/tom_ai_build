/// Client / UI CodeSpecs part markers (`Cs*`).
///
/// Each annotation in this file marks a CodeSpec class (or member) as realising
/// a particular *client-side* CodeSpecs part from the authoritative parts
/// catalogue (`codespecs_mapping.md` §4.1). They are pure markers: a CodeSpec is
/// an ordinary class **built on** an existing `tom_core`-family class and
/// *enriched* by one of these markers — there is no `Cs*` base class to extend.
/// The optional [note] on each marker records part-specific intent inline.
///
/// The `CE-*` code named by each doc comment is the part's **stable registry
/// key** (§4.1: never reused, never renamed) — several markers share one key,
/// because a part may be carried by more than one annotation (CE-EL by
/// [CsElement] + [CsWidget], CE-AC by [CsAction] + [CsTrigger], CE-NV by
/// [CsRoute] + [CsScreenFlow]).
///
/// This file covers the twelve client/UI part markers. Server-side markers live
/// in `service_annotations.dart`; shared markers in `contract_annotations.dart`.
library;

/// CE-EL — a UI element by semantic type (the generic element part, §5.18).
class CsElement {
  /// Optional part-specific note.
  final String? note;

  const CsElement({this.note});
}

/// CE-EL — the concrete `tom_flutter_ui` widget realising a [CsElement]'s
/// semantic type (§5.7.1, §5.18).
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

/// CE-LO — a screen layout (structural arrangement of elements, §5.2, §5.12).
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
class CsValidation {
  /// Optional part-specific note.
  final String? note;

  const CsValidation({this.note});
}

/// CE-AC — a user action (a command the user can invoke).
class CsAction {
  /// Optional part-specific note.
  final String? note;

  const CsAction({this.note});
}

/// CE-AC — a trigger: the event that fires a [CsAction] (§5.10, §5.20).
class CsTrigger {
  /// Optional part-specific note.
  final String? note;

  const CsTrigger({this.note});
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
/// Lives in the client project (§4.2). The edge model itself is a
/// `tom_core_codespecs` gap class; the authoring surface is the SOM screen-flow
/// section.
class CsScreenFlow {
  /// Optional part-specific note.
  final String? note;

  const CsScreenFlow({this.note});
}
