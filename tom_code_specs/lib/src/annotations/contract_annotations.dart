/// Shared (client + server) CodeSpecs part markers (`Cs*`).
///
/// These markers realise parts from the 21-part catalogue
/// (`codespecs_mapping.md` §4.1) that live in the *shared* project of the
/// three-project output trio — visible to both client and server. Like the
/// other markers they annotate a class **built on** an existing
/// `tom_core`-family class; there is no `Cs*` base class to extend.
///
/// This file covers the shared part marker `@CsError` and the member marker
/// `@CsEnum`. Client/UI markers live in `element_annotations.dart`;
/// server-side markers in `service_annotations.dart`.
library;

/// CE-ER — a processing error (a shared error type crossing the wire).
class CsError {
  /// Optional part-specific note.
  final String? note;

  const CsError({this.note});
}

/// A domain enum — a **member marker**, not a part marker
/// (`codespecs_mapping.md` §4.1): annotates a plain Dart `enum` declaration
/// authored within its owning part (a data-access entity, a
/// configuration/settings holder, a view model, or an API contract type). It
/// keeps the `@DocSpec` back-trace to the enum's SOM `DMENE` entry and keeps
/// the enum discoverable as an `@OneOf` discriminator source. Placement: the
/// shared project iff a shared contract type references the enum, else the
/// owning part's project.
class CsEnum {
  /// Optional note.
  final String? note;

  const CsEnum({this.note});
}
