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
/// ([CsTable], [CsColumn], [CsRepository]), CE-NT by two ([CsNotification],
/// [CsNotificationChannel]) and CE-RP by four ([CsReport], [CsReportColumn],
/// [CsReportChart], [CsReportParameter]).
///
/// This file covers the sixteen server-side part markers. Client/UI markers
/// live in `element_annotations.dart`; shared markers in
/// `contract_annotations.dart`.
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

/// CE-LG — an audited element: an entity or endpoint whose access is recorded
/// in the audit trail (`codespecs_mapping.md` §4.3).
///
/// Pure reuse of `tom_core_server`'s `audit` module — no gap class. The trail
/// records **automatically** at two chokepoints no handler can opt out of
/// (`TomEndpointHandler.handleMethodCall` and `TomSqlDatasourceRepository`'s
/// write path), so what a specification authors is the *declared* half only:
/// which endpoint invocations are auditable, whether reads count, and which
/// fields must never appear in a record. Those three decisions are exactly
/// `@TomAudited(enabled:, includeReads:, redact:)`, which the CodeSpec carries
/// alongside this marker — the same shape CE-SU uses, where the CodeSpec is an
/// ordinary class carrying the framework's own `@tomService` and [CsServiceUnit]
/// marks it as the part.
///
/// Retention, log format and the compliance report are **not** CE-LG: they are
/// deployment settings on the sink, and belong to [CsServerConfig].
class CsAudited {
  /// Optional part-specific note.
  final String? note;

  const CsAudited({this.note});
}

/// CE-NT — a notification type: an outbound communication a system event emits
/// (`codespecs_mapping.md` §4.3).
///
/// Built on `TomNotificationType` (`tom_core_codespecs`) for the declaration and
/// `TomMessage` / `TomMessageRouter` / `TomMessageOutbox` (`tom_core_server`
/// `messaging`) for delivery. The transport is pure reuse; the gap it leaves —
/// which types exist, which channels each goes out on, and how a user's
/// preferences narrow that set — is what this marker names.
///
/// The declaration is **shared** (the client renders the preference UI against
/// the same catalogue the server dispatches from); delivery is server-only.
/// The body copy is a `CsText` message key, never inline text.
class CsNotification {
  /// Optional part-specific note.
  final String? note;

  const CsNotification({this.note});
}

/// CE-NT — a notification channel: a declared delivery route
/// (`codespecs_mapping.md` §4.3).
///
/// Built on `TomNotificationChannelDeclaration` (`tom_core_codespecs`), whose
/// `channelId` is the name of a `TomMessageChannel` — an **open** named value,
/// so a deployment can declare a channel the framework never anticipated.
///
/// Separate from [CsNotification] because the two are authored independently:
/// the channel catalogue is a property of the deployment, the type catalogue a
/// property of the domain, and a type references channels by id rather than
/// containing them.
class CsNotificationChannel {
  /// Optional part-specific note.
  final String? note;

  const CsNotificationChannel({this.note});
}

/// CE-RP — a report: a grouped projection over the domain model, delivered as
/// a rendered artifact (`codespecs_mapping.md` §5.28).
///
/// Built on `TomReportDefinition` (`tom_core_codespecs`) for the definition and
/// `TomReportResult` for the **shared** result envelope. Query execution
/// (`TomGroupedSelect`, `TomAggregate`) and rendering (`TomTabularResult` and
/// its CSV / XLSX / PDF renderers) are pure `tom_core_server` reuse; the gap
/// they leave — the **grouped projection** a specification authors, dimension
/// by dimension and measure by measure — is what this marker names.
///
/// CE-RP is a part and not a composition of [CsEndpoint] + [CsTable] +
/// `CsForm`: none of those can hold a dimension or a measure, and a report
/// column is an *output projection* carrying an aggregate and a format, not an
/// input field.
///
/// The definition is **server-only** (that is where the report runs); the
/// result envelope and the parameter shape are **shared**. Every label is a
/// `CsText` message key, never inline text.
class CsReport {
  /// Optional part-specific note.
  final String? note;

  const CsReport({this.note});
}

/// CE-RP — one projected output column of a [CsReport] (§5.28).
///
/// Built on `TomReportColumn`. A column **displays** a declared dimension or
/// measure — it never introduces data of its own, which is why it names a
/// source key rather than an entity column: the grouped projection decides what
/// exists, the column decides how it appears.
///
/// Separate from [CsColumn] (CE-DB), which is a stored attribute of an entity.
/// The two are authored at different levels: a persisted column is part of the
/// data model, a report column part of one report's output.
class CsReportColumn {
  /// Optional part-specific note.
  final String? note;

  const CsReportColumn({this.note});
}

/// CE-RP — a chart declared over a [CsReport]'s projected columns (§5.28).
///
/// Built on `TomReportChart`. **Declared here, rendered by whoever can:** the
/// declaration is authored input (the SOM carries chart type, series and axes
/// as structured fields), while rendering is implementation-owned — a client
/// draws charts natively, and an export format that cannot express one omits it
/// rather than failing.
///
/// A chart plots columns the report already projects, so it adds a view over
/// the projection and never a second query.
class CsReportChart {
  /// Optional part-specific note.
  final String? note;

  const CsReportChart({this.note});
}

/// CE-RP — a runtime input a [CsReport] takes when it is run (§5.28).
///
/// Built on `TomReportParameter`. Distinct from a CE-DB row filter authored
/// into the query: a parameter is **supplied per execution**, so it is part of
/// the report's request shape and carries a type, a bound and a presentation.
///
/// Distinct from a `CsForm` field (CE-FM) for the same reason a report column
/// is: a form field belongs to a form the user submits, a report parameter to
/// the report's own request contract.
class CsReportParameter {
  /// Optional part-specific note.
  final String? note;

  const CsReportParameter({this.note});
}
