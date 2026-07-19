/// Shared (client + server) CodeSpecs part markers (`Cs*`).
///
/// These markers realise parts from the 21-part catalogue
/// (`codespecs_mapping.md` §4.1) that live in the *shared* project of the
/// three-project output trio — visible to both client and server. Like the
/// other markers they annotate a class **built on** an existing
/// `tom_core`-family class; there is no `Cs*` base class to extend.
///
/// This file covers the two shared part markers. Client/UI markers live in
/// `element_annotations.dart`; server-side markers in `service_annotations.dart`.
library;

/// CE-ER — a processing error (a shared error type crossing the wire).
class CsError {
  /// Optional part-specific note.
  final String? note;

  const CsError({this.note});
}

/// CE-EN — an enumeration (a shared closed value set).
class CsEnum {
  /// Optional part-specific note.
  final String? note;

  const CsEnum({this.note});
}
