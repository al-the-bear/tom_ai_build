/// Server-side CodeSpecs part markers (`Cs*`).
///
/// Each annotation marks a CodeSpec class (or member) as realising a
/// *server-side* CodeSpecs part from the authoritative parts catalogue
/// (`codespecs_mapping.md` §4.1). Like the client markers, these are pure
/// markers on a class **built on** an existing `tom_core`-family class — there is
/// no `Cs*` base class to extend.
///
/// The `CE-*` code named by each doc comment is the part's **stable registry
/// key** (§4.1: never reused, never renamed); CE-DB is carried by three markers
/// ([CsTable], [CsColumn], [CsRepository]).
///
/// This file covers the nine server-side part markers. Client/UI markers live
/// in `element_annotations.dart`; shared markers in `contract_annotations.dart`.
library;

/// CE-API — a server endpoint: an operation name plus its request/response and
/// error contract (§5.6.1). All operations are POST (§7).
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

/// CE-DB — a persistent table (a stored entity type, §5.13).
class CsTable {
  /// Optional part-specific note.
  final String? note;

  const CsTable({this.note});
}

/// CE-DB — a table column: a stored field of a [CsTable] (§5.13).
class CsColumn {
  /// Optional part-specific note.
  final String? note;

  const CsColumn({this.note});
}

/// CE-DB — a repository: the data-access surface over one or more [CsTable]s.
class CsRepository {
  /// Optional part-specific note.
  final String? note;

  const CsRepository({this.note});
}

/// CE-AZ — an authorization rule: a **modifier** applied to the [CsEndpoint] it
/// gates (§5.6.3, §5.15).
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

/// CE-MG — a schema-migration artifact set (`codespecs_mapping.md` §5.27).
///
/// Marks the *spec-side* declaration of an application's migration artifacts.
/// The artifacts themselves are numbered **SQL files**, not Dart classes: they
/// live under `<databaseMigrationsDirectory>/<datasource>/<schema>/`, are named
/// `[<version>]-<description>[@<env>…].<ext>`, and apply in ascending version
/// order. A CodeSpec authors three artifact kinds — the initial DDL, the new
/// system's base/seed reference data, and the append-only iteration scripts.
/// Business-data migration from a legacy system is explicitly *not* CE-MG.
///
/// Pure reuse of the `tom_core_server` migration engine (`TomDbMigrations` /
/// `TomDbMigrator` / `TomMigrationFileName` / `@TomDbMigrationAdaptor` /
/// `MariadbMigrationAdaptor`) — no gap class. Applied artifacts are immutable;
/// schema change is always a new numbered artifact. The cumulative DDL must
/// converge on the shape the [CsTable] / [CsColumn] entity model declares — a
/// named CodeSpecs validator check, since artifact filenames are one of the
/// §5.23 string-reference exemptions.
class CsMigration {
  /// Optional part-specific note.
  final String? note;

  const CsMigration({this.note});
}

/// CE-JB — a background-job definition (`codespecs_mapping.md` §5.29).
///
/// Work that runs *off* the request thread — the axis that separates CE-JB from
/// the request-driven [CsEndpoint]. Server-only (§4.2). One definition names:
///
/// 1. a **trigger** — cron, calendar date/time, or a named system event;
/// 2. a **work definition** — compilable pseudo-code over a later-injected
///    abstract service class (the §3 first-level-implementation latitude), run on
///    the `tom_core_kernel` isolate-pooling substrate (`TomCommand` dispatched
///    through `TomExecutor` / `TomWorker`);
/// 3. **target references** — the entities and reports the job acts on, held as
///    typed const refs, never strings;
/// 4. **retry / backoff / timeout / failure-alerting** policy.
///
/// The job base class the substrate lacks — one that makes execution pluggable
/// into any scheduling system — is a `tom_core_codespecs` gap class. Scheduler
/// runtime, job queue and multi-node locking are `tom_core` framework roadmap,
/// not CodeSpecs gaps: until one lands, a trigger is a named-but-unwired
/// schedule.
class CsJob {
  /// Optional part-specific note.
  final String? note;

  const CsJob({this.note});
}
