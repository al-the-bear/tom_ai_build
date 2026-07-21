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
/// §9.2) and the code-side back-trace (`@DocSpec`/`DocRef`, §9.3) are separate.
/// The `@DocSpec`/`DocRef` annotations annotate CodeSpecs *code* and therefore
/// live in the `tom_code_specs` framework package.
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
/// 2. the `@Cs<Id>` annotation that marks a CodeSpec class as realising the part
///    (in `tom_code_specs`) — the framework carries **annotations only, no base
///    classes** (`codespecs_mapping.md` §0). A CodeSpec is an ordinary class
///    built on an existing `tom_core`-family class and enriched by that marker.
///
/// The cross-cutting **CE-TR (Traceability)** part is intentionally **absent**:
/// traceability is not a mappable kind — it rides on every element via
/// `@CodeSpec`/`@DocSpec`, so no section type ever maps *to* it.
///
/// Two parts still have open *modeling* questions (their ids are final):
/// `serviceUnit` (boundary criterion — csm-2-1) and `layout` (node model —
/// csm-2-2). Those do not affect this enum's values.
///
/// The enum holds **29 values**: the **21 active parts** (§4.1), the **member
/// kind [domainEnum]**, and the **7 deferred candidates** (§4.3). A
/// deferred value is *mapping-only* — a SOM section may carry
/// `@CodeSpecKind([CodeSpecPart.<deferred>])` now, but the part has no `Cs*`
/// annotation, no built-on `tom_core` class and no generated code until
/// promoted into §4.1.
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
  /// setting, a
  /// `viewState` field, or a `serverApi` contract member), authored once as a
  /// plain Dart `enum` marked `@CsEnum`. Placed in the shared project iff a
  /// shared contract type references it, else in the owning part's project.
  /// SOM sections (`DMENE`, `OBST`) carry this kind like any other value.
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

  // ---------------------------------------------------------------------------
  // Deferred candidates — MAPPING-ONLY (§4.3, csm2r8).
  //
  // These seven values are RESERVED so a SOM section can carry `@CodeSpecKind`
  // now, but they are NOT active parts: each has NO `@Cs<Id>` annotation, NO
  // built-on `tom_core` class and NO generated code until promoted into §4.1
  // (the promotion criterion: a concrete `tom_core`-family built-on class — or a
  // decided `tom_core_codespecs` gap — plus a `Cs*` annotation are chosen). They
  // are distinct and collision-free against the 21 active values above, bringing
  // the enum to 29 kind values.
  // ---------------------------------------------------------------------------

  /// CE-MG — database schema versioning / migration steps derived from the data
  /// model's evolution. Deferred (§4.3).
  schemaMigration,

  /// CE-WF — multi-step process / workflow orchestration (state machines,
  /// long-running processes). Deferred (§4.3).
  workflow,

  /// CE-NT — outbound communications (email / push / SMS / webhooks) as a
  /// first-class effect. Deferred (§4.3).
  notification,

  /// CE-JB — scheduled / background / queued jobs (cron, workers), distinct from
  /// request-driven [serverApi]. Deferred (§4.3).
  backgroundJob,

  /// CE-LG — logging & audit trail: who did what, when (a cross-cutting effect on
  /// operations). Deferred (§4.3).
  auditLog,

  /// CE-FS — file / blob storage abstraction (upload/download, references from
  /// the data model). Deferred (§4.3).
  fileStorage,

  /// CE-RP — reporting / read-models / analytics projections over the domain
  /// model. Deferred (§4.3).
  reporting,
}
