/// Server-side CodeSpecs part markers (`Cs*`).
///
/// Each annotation marks a CodeSpec class (or member) as realising a
/// *server-side* CodeSpecs part from the 21-part catalogue
/// (`codespecs_mapping.md` §4.1). Like the client markers, these are pure
/// markers on a class **built on** an existing `tom_core`-family class — there is
/// no `Cs*` base class to extend.
///
/// This file covers the seven server-side part markers. Client/UI markers live
/// in `element_annotations.dart`; shared markers in `contract_annotations.dart`.
library;

/// CE-EP — a server endpoint (an addressable server operation).
class CsEndpoint {
  /// Optional part-specific note.
  final String? note;

  const CsEndpoint({this.note});
}

/// CE-SU — a service unit (a cohesive server-side service).
class CsServiceUnit {
  /// Optional part-specific note.
  final String? note;

  const CsServiceUnit({this.note});
}

/// CE-TB — a persistent table (a stored entity type).
class CsTable {
  /// Optional part-specific note.
  final String? note;

  const CsTable({this.note});
}

/// CE-CO — a table column (a stored field of a [CsTable]).
class CsColumn {
  /// Optional part-specific note.
  final String? note;

  const CsColumn({this.note});
}

/// CE-RE — a repository (data-access surface over one or more tables).
class CsRepository {
  /// Optional part-specific note.
  final String? note;

  const CsRepository({this.note});
}

/// CE-AZ — an authorization rule (server-side access control).
class CsAuthorize {
  /// Optional part-specific note.
  final String? note;

  const CsAuthorize({this.note});
}

/// CE-CF — server configuration (per-server settings).
///
/// Note: CE-CF is narrowed to *server* configuration under the 2026-07-19
/// revision (`codespecs_mapping.md` §0). Client configuration, user settings,
/// the client element itself, and authentication are separate parts introduced
/// by csm2r5 (CE-CC / CE-UP / CE-CL / CE-AU) and are not part of this file.
class CsServerConfig {
  /// Optional part-specific note.
  final String? note;

  const CsServerConfig({this.note});
}
