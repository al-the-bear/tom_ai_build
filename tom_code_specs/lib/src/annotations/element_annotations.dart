/// Client / UI CodeSpecs part markers (`Cs*`).
///
/// Each annotation in this file marks a CodeSpec class (or member) as realising
/// a particular *client-side* CodeSpecs part from the 21-part catalogue
/// (`codespecs_mapping.md` §4.1). They are pure markers: a CodeSpec is an
/// ordinary class **built on** an existing `tom_core`-family class and *enriched*
/// by one of these markers — there is no `Cs*` base class to extend. The
/// optional [note] on each marker records part-specific intent inline.
///
/// This file covers the eleven client/UI part markers. Server-side markers live
/// in `service_annotations.dart`; shared markers in `contract_annotations.dart`.
library;

/// CE-EL — a UI element (the generic element part).
class CsElement {
  /// Optional part-specific note.
  final String? note;

  const CsElement({this.note});
}

/// CE-WI — a widget (composed, reusable UI unit).
class CsWidget {
  /// Optional part-specific note.
  final String? note;

  const CsWidget({this.note});
}

/// CE-FO — a form (a data-entry surface with fields and validation).
class CsForm {
  /// Optional part-specific note.
  final String? note;

  const CsForm({this.note});
}

/// CE-LA — a layout (structural arrangement of elements).
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

/// CE-TG — a trigger (an event that starts a client interaction).
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

/// CE-VM — a view model (client-side presentation state).
class CsViewModel {
  /// Optional part-specific note.
  final String? note;

  const CsViewModel({this.note});
}

/// CE-RO — a route (client navigation target).
class CsRoute {
  /// Optional part-specific note.
  final String? note;

  const CsRoute({this.note});
}
