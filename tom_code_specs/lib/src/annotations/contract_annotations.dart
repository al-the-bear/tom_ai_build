/// Shared (client + server) CodeSpecs part markers (`Cs*`).
///
/// These markers realise parts from the authoritative parts catalogue
/// (`codespecs_mapping.md` §4.1) that live in the *shared* project of the
/// three-project output trio — visible to both client and server. Like the
/// other markers they annotate a class **built on** an existing
/// `tom_core`-family class; there is no `Cs*` base class to extend.
///
/// This file covers the shared part marker `@CsError` and the member marker
/// `@CsEnum`. Client/UI markers live in `element_annotations.dart`;
/// server-side markers in `service_annotations.dart`. The closed catalogues
/// these markers select from live in `vocabulary.dart`.
library;

import 'vocabulary.dart';

/// CE-ER — a processing error (a shared error type crossing the wire).
///
/// Carried twice: plain on the error-code **catalogue holder**, and once per
/// `CsErrorCode` member with that code's [severity].
class CsError {
  /// How severe the code is.
  ///
  /// Defaults to [CsErrorSeverity.error] — the arm that names an ordinary
  /// actionable failure, which is what an error code is unless it says
  /// otherwise.
  final CsErrorSeverity severity;

  /// Optional part-specific note.
  ///
  /// The **code itself** is not an argument — it is already the `CsErrorCode`
  /// const's string. Nor is a message key: `codespecs_mapping.md` §5.21 keys
  /// error copy *by the error code*, so the key is derived, not authored.
  final String? note;

  const CsError({this.severity = CsErrorSeverity.error, this.note});
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
