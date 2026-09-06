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

  /// Marks the annotated declaration as a CE-ER error code of the given
  /// [severity].
  ///
  /// [severity] draws from [CsErrorSeverity] — the four-arm catalogue in
  /// `vocabulary.dart` (`codespecs_derivation_contract.md` §5.3) — and defaults
  /// to [CsErrorSeverity.error], the arm naming an ordinary actionable failure,
  /// which is what an error code is unless the specification says otherwise.
  /// State an arm explicitly only where the code is *not* that:
  /// [CsErrorSeverity.info] or [CsErrorSeverity.warning] where the operation
  /// still succeeded, and [CsErrorSeverity.fatal] where the caller cannot act
  /// on it at all.
  ///
  /// The value reaches the caller in `codespecs_mapping.md` §7's result
  /// envelope, so the classification is behaviour and not annotation: a genuine
  /// failure written as [CsErrorSeverity.info] is reported to the client as a
  /// success carrying a remark.
  ///
  /// Neither the **code** nor a message key is an argument. The code is already
  /// the `CsErrorCode` const the annotated member holds, and
  /// `codespecs_mapping.md` §5.21 keys error copy *by* that code, so the key is
  /// derived rather than authored.
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
///
/// **Note-only, and the enum stays plain.** There is no holder class in
/// `tom_core_codespecs` and no enhanced-enum member, because a domain enum has
/// no authored attribute of its own to carry: the value token is the constant's
/// own identifier, the value label is CE-TX copy in the message-key registry
/// (`codespecs_mapping.md` §5.21, §1.2 consequence 1), the description is the
/// generated doc comment, and a default value belongs to the enum-typed member
/// rather than to the enum (`codespecs_mapping.md` §4.1,
/// `codespecs_derivation_contract.md` §3.1.1).
class CsEnum {
  /// Optional note.
  final String? note;

  /// Marks the annotated plain Dart `enum` as a domain enum — a member marker,
  /// not a part marker.
  ///
  /// Note-only, and with `@CsCollaborator` one of only two markers in the
  /// contract with **no substrate at all** (`codespecs_derivation_contract.md`
  /// §5.2): there is nothing on either side of the test to carry an attribute.
  /// Everything a domain enum might have held is already somewhere else — the
  /// value token is the constant's own identifier, the value label is CE-TX
  /// copy in the message-key registry (`codespecs_mapping.md` §5.21), the
  /// description is the generated doc comment, and a default value belongs to
  /// the enum-typed *member* rather than to the enum
  /// (`codespecs_derivation_contract.md` §3.1.1).
  ///
  /// So the declaration stays a bare `enum`, and [note] is not a place to put
  /// label text: copy written here is a second, untranslated copy that no
  /// `TomTextResourceProvider` lookup will ever reach.
  const CsEnum({this.note});
}
