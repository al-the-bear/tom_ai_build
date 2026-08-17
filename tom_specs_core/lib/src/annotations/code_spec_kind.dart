/// The general, type-level half of the DocSpecs ↔ CodeSpecs link
/// (`codespecs_mapping.md` §9.1).
///
/// `@CodeSpecKind` is applied to a SOM section class in `tom_specs_model` to
/// declare which **kind** of CodeSpec element every section of that type must be
/// realised as during Phase 4. It is the *type-level* forward link: "a section
/// of this type maps to a CodeSpec of that kind" (e.g. an information-model
/// entity → `dataAccess`; a form section → `form`; an interface operation →
/// `serverApi`).
///
/// It lives in `tom_specs_core` — not the `tom_code_specs` framework — because it
/// annotates the *model* (SOM) classes, and `tom_specs_model` already depends on
/// `tom_specs_core`. Keeping it here preserves the model → core dependency
/// direction (the model never depends on the CodeSpecs framework) and puts it
/// alongside the other cross-phase link annotations (`@MapsTo`, `@DetailedIn`).
///
/// The concrete, instance-level forward link (`codeSpec` on `DocSpecsSection`,
/// `codespecs_mapping.md` §9.2) and the code-side back-trace
/// (`@DocSpec`/`DocRef`, `codespecs_mapping.md` §9.3) are separate. The
/// `@DocSpec`/`DocRef` annotations annotate CodeSpecs *code* and therefore live
/// in the `tom_code_specs` framework package.
///
/// "CodeSpecsMapping" (used in the csm todo descriptions) is the descriptive
/// alias for this general type-level mapping concept; the annotation type itself
/// is `@CodeSpecKind` (the one canonical symbol — csm1).
///
/// A section type — or a form field — may realise **more than one** CodeSpecs
/// kind (e.g. a field that is both a `screenElement` and a `dataAccess` column;
/// a setting that is both `clientConfiguration` and `userSettings`), so
/// [kinds] is a **list** (csm2r2, `codespecs_mapping.md` §9.1). A single-kind
/// mapping is the one-element list form.
///
/// Example:
/// ```dart
/// @CodeSpecKind([CodeSpecPart.form])
/// class OrderForm { ... }
///
/// // A section type may realise several kinds — in one annotation:
/// @CodeSpecKind([CodeSpecPart.serverApi, CodeSpecPart.authorization],
///     note: 'roles gate the operation')
/// class OrderSubmitOperation { ... }
/// ```
class CodeSpecKind {
  /// The CodeSpecs part(s) this section type (or form field) must be realised
  /// as. At least one; a single-kind mapping uses a one-element list.
  final List<CodeSpecPart> kinds;

  /// Optional explanation of the general influence (why/how this section type
  /// shapes the named CodeSpecs part(s)).
  final String? note;

  const CodeSpecKind(this.kinds, {this.note});
}

/// The finalized catalogue of CodeSpecs "parts" (`codespecs_mapping.md` §4.1).
///
/// Each value is the camelCase form of a part's **canonical id**. The enum is
/// the single source of the kind vocabulary shared by:
///
/// 1. `@CodeSpecKind([CodeSpecPart.x])` — the type-level mapping declared here;
/// 2. the `@Cs<Id>` annotation that marks a CodeSpec class as realising the
///    part (in `tom_code_specs`) — the framework carries **annotations only, no
///    base classes** (`codespecs_mapping.md` §1.1 pillar (a)). A CodeSpec is an
///    ordinary class built on an existing `tom_core`-family class and enriched
///    by that marker.
///
/// The cross-cutting **CE-TR (Traceability)** part is intentionally **absent**:
/// traceability is not a mappable kind — it rides on every element via
/// `@CodeSpec`/`@DocSpec`, so no section type ever maps *to* it.
///
/// The enum holds **28 values**: the **26 active parts**
/// (`codespecs_mapping.md` §4.1), the **member kind [domainEnum]**, and the **1
/// deferred candidate** (`codespecs_mapping.md` §4.3). A deferred value is
/// *mapping-only* — a SOM section may carry
/// `@CodeSpecKind([CodeSpecPart.<deferred>])` now, but the part has no `Cs*`
/// annotation, no built-on `tom_core` class and no generated code until
/// promoted into `codespecs_mapping.md` §4.1.
enum CodeSpecPart {
  /// CE-EL — screen element by semantic type, then concrete implementation.
  screenElement,

  /// CE-FM — grouping of elements into forms and subforms.
  form,

  /// CE-LO — screen layout (Flutter layout primitives).
  layout,

  /// CE-TX — texts per element (placeholder, help, error copy).
  text,

  /// CE-VA — validation (per-field and cross-field/form rules).
  validation,

  /// CE-AC — actions and their triggers.
  action,

  /// CE-SC — server call: the client call-site binding of a CE-API operation
  /// (references the operation by name, never authors contract members; owns
  /// request assembly, response handling, error surfacing, the trigger edge).
  serverCall,

  /// CE-API — server API (operation name + request/response + error contract).
  serverApi,

  /// CE-SU — server-side logical units (cohesive operation grouping).
  serviceUnit,

  /// CE-DB — database access object model (tables, columns, repositories).
  dataAccess,

  /// CE-ST — view-model / UI state.
  viewState,

  /// CE-NV — navigation / routing.
  navigation,

  /// CE-AZ — authorization per operation (realised as a modifier on an endpoint).
  authorization,

  /// CE-ER — the single canonical structured error-result envelope.
  errorResult,

  /// Domain enums / value types — a **member kind**, not a part
  /// (`codespecs_mapping.md` §4.1): a domain enum is a member declaration of
  /// the part that introduces it (a `dataAccess` entity column, a
  /// `serverConfiguration`/`clientConfiguration`/`deviceSettings`/`userSettings`
  /// setting, a `viewState` field, or a `serverApi` contract member), authored
  /// once as a plain Dart `enum` marked `@CsEnum`. Placed in the shared project
  /// iff a shared contract type references it, else in the owning part's
  /// project. SOM sections (`DMENE`, `OBST`) carry this kind like any other
  /// value.
  domainEnum,

  /// CE-CF — **server / system** configuration; carries no user or
  /// client-machine settings — those are [clientConfiguration],
  /// [deviceSettings] and [userSettings]. (csm2r5)
  serverConfiguration,

  /// CE-CC — client configuration: per-machine settings of a client app
  /// (API base URL, device options, per-install toggles), keyed by
  /// (client app, machine) — no user identity in the key (values that differ
  /// per signed-in user are [deviceSettings]). (csm2r5)
  clientConfiguration,

  /// CE-UP — user settings: user-scoped, server-persisted preferences that
  /// follow the user, restored on any device via the `TomGetSettings*`
  /// round-trip. Device-bound user settings are [deviceSettings]. (csm2r5)
  userSettings,

  /// CE-DS — device settings: user-specific settings of a user-owned device,
  /// keyed by (user, device) and persisted on the device (window layout,
  /// last-opened, machine-local cache preferences). Distinct from
  /// [clientConfiguration] (no user in the key) and [userSettings]
  /// (follows the user).
  deviceSettings,

  /// CE-CL — client application: which clients exist (Flutter app, CLI,
  /// other server). (csm2r5)
  client,

  /// CE-AU — authentication / session: credential exchange, token, session —
  /// distinct from [authorization]; spans shared + client + server. The
  /// mechanics (two-token JWT model, login orchestration, stateless Bearer
  /// verification, token store) are framework-fixed pure reuse of the
  /// `tom_core` auth stack; the spec-authorable surface is the service
  /// binding, enabled methods/flows, and session/token/credential policies —
  /// the app's `TomAuthenticationService` implementation is the `@CsAuth`
  /// CodeSpec. (csm2r5)
  authentication,

  /// CE-ID — identity: app-declared **identity-attribute extensions** over the
  /// fixed principal core (`TomUser` + `TomPrincipal`, `tom_core_kernel`) —
  /// `@CsIdentity` declares the extension holder, `@CsIdentityAttribute`
  /// marks each attribute with a `placement` discriminator (`public` — rides
  /// the public token payload — vs `encrypted` — rides the encrypted context).
  /// Distinct from [authentication] (establishment / token projection) and
  /// [authorization] (access decisions). Spans shared (declaration) + server
  /// (population).
  identity,

  /// CE-MG — database schema versioning / migration artifacts derived from the
  /// data model's evolution: `@CsMigration`-marked SQL artifacts (initial DDL,
  /// base/seed data, iteration scripts) in the
  /// `<databaseMigrationsDirectory>/<datasource>/<schema>/` tree, driven by the
  /// `tom_core_server` migration engine (`TomDbMigrations` / `TomDbMigrator` /
  /// `TomMigrationFileName`) — pure reuse (`codespecs_mapping.md` §5.27).
  schemaMigration,

  // ---------------------------------------------------------------------------
  // Deferred candidates — MAPPING-ONLY (`codespecs_mapping.md` §4.3, csm2r8).
  //
  // One value here — [workflow] — is RESERVED so a SOM section can carry
  // `@CodeSpecKind` now, but it is NOT an active part: it has NO `@Cs<Id>`
  // annotation, NO built-on `tom_core` class and NO generated code until
  // promoted into `codespecs_mapping.md` §4.1 (the promotion criterion: a
  // concrete `tom_core`-family built-on class — or a decided
  // `tom_core_codespecs` gap — plus a `Cs*` annotation are chosen). It is
  // distinct and collision-free against the 26 active values, keeping the enum
  // at 28 kind values.
  //
  // [workflow] is deferred **permanently**, not pending — the substrate survey
  // in `codespecs_mapping.md` §4.3.1 recommends against ever building a process
  // runtime, and `codespecs_mapping.md` §4.3.1 point 7 fixes the three
  // conditions that would reopen it.
  //
  // [notification], [backgroundJob], [auditLog] and [reporting] below are
  // ALREADY PROMOTED (active `codespecs_mapping.md` §4.1) but physically stay
  // in their original enum position — kind values keep their enum position for
  // enum-order stability (never reordered on promotion). Their doc comments
  // carry the active mapping.
  // ---------------------------------------------------------------------------

  /// CE-WF — multi-step process / workflow orchestration (state machines,
  /// long-running processes). Deferred **permanently** (`codespecs_mapping.md`
  /// §4.3, §4.3.1).
  workflow,

  /// CE-NT — notifications: outbound communications as a first-class effect —
  /// `@CsNotification` names a type (category, urgency, default and mandatory
  /// channels, trigger event, a [text] template key) and `@CsNotificationChannel`
  /// a delivery route (fallback, quiet hours, urgency ceiling), built on
  /// `TomNotificationType` / `TomNotificationChannelDeclaration`
  /// (`tom_core_codespecs`) over the `tom_core_server` `messaging` transport
  /// (`TomMessage` / `TomMessageRouter` / `TomMessageOutbox`). Shared
  /// (declarations, so the preference UI and the dispatcher read one catalogue)
  /// + server (delivery) (`codespecs_mapping.md` §4.3).
  notification,

  /// CE-JB — background jobs: scheduled / background / queued work over the
  /// operational model — `@CsJob` names a trigger (cron | calendar | event), a
  /// work definition (the `TomCommand` body on the `tom_core_kernel`
  /// isolate-pooling substrate: `TomExecutor` / `TomWorker`), target refs
  /// (CE-DB entities / CE-RP reports) and retry/backoff/timeout/alerting,
  /// distinct from request-driven [serverApi]. Server-only; the typed
  /// job-definition holder is a `tom_core_codespecs` gap; scheduler runtime /
  /// job queue / multi-node locking are framework roadmap
  /// (`codespecs_mapping.md` §5.29).
  backgroundJob,

  /// CE-LG — audit trail: who did what, when — `@CsAudited` marks the entity or
  /// endpoint whose access is recorded, built on `tom_core_server`'s `audit`
  /// module (`TomAuditTrail` + the `TomAudited` declaration it carries). Pure
  /// reuse, no gap: the trail records automatically at the endpoint and
  /// repository chokepoints, so the spec authors only the *declared* half —
  /// which invocations are auditable, whether reads count, which fields are
  /// redacted. Retention and log format are [serverConfiguration], not CE-LG.
  /// Server-only (`codespecs_mapping.md` §4.3).
  auditLog,

  /// CE-RP — reporting: a **grouped projection over the domain model,
  /// delivered as a rendered artifact** — `@CsReport` names the projection
  /// (dimensions and measures), `@CsReportColumn` one projected output column,
  /// `@CsReportChart` a chart over those columns and `@CsReportParameter` a
  /// per-execution input, built on `TomReportDefinition` / `TomReportResult`
  /// (`tom_core_codespecs`) over the `tom_core_server` query and rendering
  /// substrate (`TomGroupedSelect` / `TomAggregate`, `TomTabularResult` and its
  /// CSV / XLSX / PDF renderers). Server (definition + execution) + shared
  /// (result envelope, parameter shapes) (`codespecs_mapping.md` §5.28).
  ///
  /// Not a composition of [serverApi] + [dataAccess] + [form]: none of those
  /// can hold a dimension or a measure, and a report column is an *output
  /// projection* carrying an aggregate and a format, not an input field.
  /// Rendering engine, pagination and export file generation are
  /// implementation-owned; the environment-wide print and export settings are
  /// [serverConfiguration].
  reporting,
}

/// The [CodeSpecPart] values that are **deferred**: reserved so a SOM section
/// can carry `@CodeSpecKind` today, but with no `@Cs*` annotation, no built-on
/// `tom_core` class and no generated code (`codespecs_mapping.md` §4.3).
///
/// Machine-readable rather than prose-only, because the generation-routing
/// invariant (`tom_specs_model_rules.md` §10.2, invariant `PART-ROUTED`)
/// needs it: every
/// **active** part named by a `@CodeSpecKind` must have a bearer reachable from
/// the CodeSpecs generation projection, or the part is a routing gap. A
/// deferred part has no generated surface at all, so it has no bearer to reach
/// and is exempt by construction — an exemption the validator reads from here
/// instead of restating.
const Set<CodeSpecPart> deferredCodeSpecParts = {CodeSpecPart.workflow};
