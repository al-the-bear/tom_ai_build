# CodeSpecs Mapping

**Quest:** tom_specs · **Status:** grounding doc

## 1. Purpose

CodeSpecs is **Phase 4** of TomSpecs: it turns the Phase 3 specification
documents (the DocSpecs, typed by the **SOM** — the `tom_specs_model` object
model) into a **skeletal, compilable Dart application** whose every element
carries traceability annotations back to its source spec.

**CodeSpecs is code only.** It is the `Cs*` annotation family (in
`tom_code_specs`) applied to `tom_core`-family classes, plus the generated
skeletal Dart — there is **no separate "CodeSpecs document" model**. The link
between a DocSpecs section and its CodeSpec code is carried by annotations and
section metadata, not by a parallel document type — see §9.

This document is the **grounding reference** for the CodeSpecs derivation. It:

1. states what CodeSpecs means,
2. canonicalises the target element taxonomy (23 active parts, §4),
3. defines the three-project output structure (§4.2),
4. compares the taxonomy against existing coverage and flags gaps (§5–§6),
5. records the server-contract and configuration/settings decisions (§7, §11),
6. sketches the **SOM → CodeSpecs** derivation map (§8),
7. defines the **bidirectional DocSpecs ↔ CodeSpecs link** (§9), and
8. records the `code_spec` architecture principles (§12).

### 1.1 General approach (four pillars)

Four pillars frame the CodeSpecs implementation. They are recorded here and in
`overview.tom_specs.md` (§ "Relationship to CodeSpecs") so both documents share
one frame.

**(a) `tom_code_specs` holds the CodeSpecs *annotations* — nothing else.**
`tom_code_specs` (in the `tom_ai/ai_build` repo) owns the `Cs*` annotation family
and the §9 link annotations (`@DocSpec`/`DocRef`), plus any helper code/tools. It
carries **no base classes** — CodeSpecs has no `Cs*`/abstract scaffolding. All
annotations use the **`Cs*` prefix**. The general
type-level link annotation `@CodeSpecKind` and its `CodeSpecPart` enum live one
layer lower, in `tom_specs_core` (§9.5), because they annotate SOM *model*
classes. The framework is owned by the **`tom_specs` quest** (§12).

**(b) Every class a CodeSpec builds on is a `tom_core`-family class.** The
concrete types a CodeSpec is built from (data models, endpoints, repositories,
widgets, forms, …) come from the `tom_core` family under `tom_ai/core/` — **five**
packages: `tom_core_kernel` / `tom_core_flutter` / `tom_core_server` /
`tom_core_d4rt` **and `tom_flutter_ui`**. `tom_flutter_ui` is the
code basis for the entire client-side UI substrate — forms
(CE-FM), actions (CE-AC), the ScreenElementsProvider / input-element / widget
family (CE-EL), layout (CE-LO), text/i18n (CE-TX), validation (CE-VA), navigation
(CE-NV), view-state (CE-ST) — via `TomForm` / `TomField` / `TomAction` /
`Validators` / `TomPageRoute` / the `Acl*` layout family / `TomText` /
`TomObservable`. **Reuse an existing `tom_core` class directly wherever possible.**
Only the concrete structures `tom_core` genuinely lacks go into the new
**`tom_core_codespecs`** project — and those are **concrete classes, not abstract
`Cs*` bases**. `tom_core` stays clean of CodeSpecs-only concerns.

Two consequences of the survey that grounded this pillar are worth stating once:
`tom_core_flutter` carries only observing / resources / runtime / security — the
real form, field, action, validation, layout and navigation classes live in
`tom_flutter_ui`, which depends **directly** on `tom_core_kernel` and not through
`tom_core_flutter`. And **`tom_core_d4rt` contributes no substrate at all**: it is
a bridge aggregator re-exposing the other packages to the interpreter, so no part
maps to it and later waves need not re-survey it.

**Where a gap class lands** follows from *who else could use it*: a structure
`tom_core` is simply missing and that is **generally useful** goes into the
relevant `tom_core_*` package (the §7 `Result`/`ErrorResult` envelope is the
worked example — it belongs in `tom_core_kernel`, not in CodeSpecs). A structure
that is a **CodeSpecs-only framing** of already-present behaviour goes into
`tom_core_codespecs`. Domain enums need no gap structure at all — a plain Dart
`enum` marked `@CsEnum`, authored as a member of its owning part.

**(c) DocSpecs stays technology-neutral; the mapping names CodeSpecs part
*types*.** Each SOM section type carries `@CodeSpecKind` (the general type-level
link of §9.1) naming the **kind(s)** of CodeSpecs part it must become — never a
concrete class or member. DocSpecs keeps abstract, technology-neutral vocabulary
(Field, Form, Validation rule, Server interaction, Client, User setting, …). The
CodeSpecs-specific detail is a **deeper level within** each mapped section. A
section may name **several** kinds (§9.1).

**(d) Wave-based execution model.** CodeSpecs work runs in waves; every wave that
emits further todos ends with a "restructure new todos" closer that produces the
next wave's execution list. The execution list is the `csra*` todo set in
`todos.tom_specs.todo.yaml` (indexed in §10); the active wave and progress live
in `progress.tom_specs.md`.

### 1.2 Neutral vocabulary and the attribute-surface convention

Pillar (c) is only enforceable if the neutral vocabulary is a **closed set**. The
per-part attribute surfaces in §5 draw their author-facing terms from this
glossary, and nothing else:

> **Data entity · Data attribute · Identity attribute · Scope rule ·
> Query/Filter · Sort · Domain enum · Enum value · Operation · Operation name ·
> Request shape · Response shape · Service unit · Authorization requirement ·
> Error result · Error code · Field-level error · Field · Field kind · Form ·
> Subform · Layout node · Copy/Text · Message key · Validation rule (Field rule /
> Form rule) · Action · Trigger · Server interaction · View state · Navigation
> target · Configuration setting · Traceability link.**

Every term maps onto a `tom_specs_model` section (§8). Adding a term is a
deliberate act: a new neutral term means a new author-facing concept, so it must
be justified against the existing set before it is introduced — most candidates
turn out to be a *deeper level within* an existing term rather than a peer of it.

**How a part's attribute surface is stated.** Each part in §5 lists the
**complete set of attributes a DocSpecs specification must carry** so the
corresponding CodeSpecs code can be generated with *nothing left to guess at
generation time*, in four columns:

| Column | Meaning |
|--------|---------|
| **Attribute** | The spec-authorable attribute, named neutrally. |
| **`tom_core` source** | The concrete constructor parameter / field / annotation member it maps to, with the class it comes from. |
| **Req?** | **Y** = a spec MUST supply it · **N** = optional · **D** = derived (computed by the generator, never authored). |
| **Neutral DocSpecs term** | The glossary term above that the DocSpecs author works in. Never a Dart type. |

**Spec-authorable vs framework-internal.** The `tom_core` classes carry many
members that are *runtime wiring*, not specification input — `focusNode`,
`uiStateController`, `authorizer`, `clientFactory`, middleware handlers,
reflection handles (`InstanceMirror`/`MethodMirror`), `Completer`/abort triggers,
listenables. These are **excluded by rule**: the generator supplies them, a spec
never authors them. Across every part the spec-authorable surface is a small
fraction of the class's members — which is what makes pillar (c) hold: DocSpecs
stays neutral *and* thin.

**Cross-cutting consequences of the vocabulary.** Three follow from the glossary
being closed, and they constrain the whole design:

1. **Copy is shared, not duplicated.** Field and action labels, domain-enum value
   labels, error messages and free copy all resolve through the *same*
   message-key mechanism. **Message key** is the single join; a spec authors copy
   once and references it (§5.21).
2. **Error codes are the CE-VA ↔ CE-ER ↔ CE-TX spine.** A validation failure, an
   application error and its user-facing copy share **one** error-code
   vocabulary, sourced from a single registry: an entry authored once, emitted by
   CE-VA, copied by CE-TX, carried by CE-ER (§5.19, §5.21, §7).
3. **Authorization is an attribute, not a leaf.** Every authorization requirement
   is a small attribute set attached to an operation, a screen element or a data
   column — never a standalone element (§5.15).

## 2. Sources analyzed

| Source | What it contributes |
|--------|--------------------|
| `tom_specs_project_flow.md` §PF-PHA-P4 | The Phase 4 CodeSpec **components**, the traceability requirement, the fixed Tom Architecture (Flutter/CLI client → server interface → Dart server → SQL), the Phase 3→CodeSpec requirement-mapping table, and the Phase 4 exit criteria (compiles, throws `UnimplementedError`). |
| **`code_spec` architecture principles** (§12) | The multi-project separation (shared spec / client impl / server impl), the three-layer UI split (semantic / widget-behaviour / layout), analyzer-driven validation beyond the compiler, `//$` production stripping, test-generation-from-specs, and the auth-server/stateless-API/SQL target architecture. |
| `tom_ai/ai_build/tom_specs_model/` | The **SOM**: 12 Phase 3 document roots `D01…D12` under the `D00SolutionBlueprint` master, plus the `D13CodeSpecsProjection` generation projection. The derivation *inputs*. |
| `tom_core_kernel` / `_server` / `_flutter` / `_d4rt` / `tom_flutter_ui` | Direct source survey of the five core-family packages — the exact constructor/field/annotation signatures behind every §5 attribute-surface row. |

**This document is self-contained.** It is the single CodeSpecs document: the
per-part code basis, attribute surfaces, section→part coverage, closed-choice
inventory, follow-up split and review decisions are all sections of this file.
Remaining work is tracked as `csra*` quest todos (§10), not in prose.

## 3. CodeSpecs in one paragraph

A CodeSpec is annotated Dart built on `tom_core`. A screen element, form, layout,
action, server call, endpoint, service unit, table, repository, view-model, route,
enum, error result, configuration, client, or user setting is declared as a class
that **extends or instantiates the appropriate existing `tom_core`-family class**
(e.g. `TomForm`, `TomField`, `TomServerEndpoint`, the Tom persistence model,
`TomObservable`) and is decorated with **`Cs*` annotations** (`@CsForm`,
`@CsTable`, `@CsColumn`, `@CsEndpoint`, `@CsWidget`, …) plus a `@CodeSpec(id,
source, requirements)` traceability link. Where `tom_core` has no suitable class,
a **concrete** class from `tom_core_codespecs` fills the gap. Method bodies throw
`UnimplementedError`. A validator enforces required annotations and
cross-references (FKs resolve, widget refs exist, routes unique) beyond what the
compiler alone checks. Before production, a cleanup tool comments spec-only code
with `//$`.

**CodeSpecs is not required to be purely declarative.** A CodeSpec may carry a
**first level of implementation** — real Dart method bodies expressing the intended
behaviour as *compilable pseudo-code* — even though the skeleton as a whole does not
yet run. Such a body typically calls an **abstract collaborator** (an injected
service laid out as an abstract class whose methods carry detailed doc-comments
stating what each is to do); the collaborator is implemented in Phase 6. This lets a
part be specified as annotated + partially-implemented code rather than annotations
alone — validation methods on a `TomForm` subclass (CE-VA, §5.9), a background job's
work body over an abstract service (CE-JB, §5.29), and any action/handler whose logic
is clearer as code than as a declaration all use this latitude. The Phase-4 exit
criterion (compiles; unfinished bodies throw `UnimplementedError`) is unchanged — a
first-level body either compiles against its abstract collaborator or throws.

## 4. Target element taxonomy

The taxonomy has **23 active parts** spanning client, shared contract, server,
and database. The Note column states
how each part is planned to be realised: which `tom_core`-family classes it is
built on, whether it is a pure annotation over existing classes, and where a
concrete class is still missing in `tom_core` — such a gap lands in
`tom_core_codespecs` and is still to be specified and implemented.
Beyond these, **four deferred candidate parts** are reserved for *mapping only*
— see §4.3.

| Code | Element | Locus | Note |
|------|---------|-------|------|
| **CE-EL** | Standalone screen elements — what remains after input elements are grouped into forms (static display, action-trigger elements, form-hosting containers); semantic type, then concrete implementation | client | **Pure reuse — no new class.** Built on `TomScreenElementsProvider` + the `Tom*` `tom_flutter_ui` element/widget family; forms already have their semantic classes. The semantic element kinds are the existing `Tom*` widget types — a documented catalogue over reused classes, not a new `tom_core_codespecs` class (§5.7.1, §5.18). |
| **CE-FM** | Form / subform tree **including its member input elements** — forms are part of the screen-element description | client | Reuses `TomForm<T>` / `TomFormChildContainer` / `TomField<T>` (`tom_flutter_ui`) directly; no new classes (§5.7.2). |
| **CE-LO** | Screen layout (Flutter layout) | client | Containers/slots reuse the ACL substrate (`AclRow`/`AclContainer`/`AclComponent`, `tom_flutter_ui`); the override-separable two-layer node model is a new class in `tom_core_codespecs` (§5.2, §5.12, §5.22). |
| **CE-TX** | Texts **other than** screen-element texts — server/error copy, notification/email bodies, report copy, and any message not owned by an element. (A screen element's own placeholder/label/help/error copy is **not** catalogued here: it is derived from the element's `basePath` — see below.) | client + shared | i18n keys shared with server error codes. Reuses `TomText`/`TomLabelBase` (`tom_flutter_ui`) + `TomTextResourceProvider` (`tom_core_kernel`); the message/i18n-key catalogue for these *other* texts is a new class in `tom_core_codespecs` (§5.8, §5.21). |
| **CE-VA** | Validation — per-field + cross-field (form) rules | client + shared | **No new class.** Provided as **Dart code** — standalone validator classes with validation methods, or validation methods on the `TomForm` subclass (the first-level-implementation latitude, §3). Reuses `Validators`/`TomValidatorRegistry`/`ValidationResult`/`FormValidationError` (`tom_flutter_ui`); the field-vs-form distinction is a code convention, not a `tom_core_codespecs` class (§5.9, §5.19). |
| **CE-AC** | Actions and their triggers | client | **Pure reuse — no new class.** Actions have a full implementation in `tom_flutter_ui`: `TomAction`/`TomActionController`/`TomActionTrigger`. The trigger taxonomy is documented over these existing classes (§5.10, §5.20). |
| **CE-SC** | Server call — the client call-site binding of a CE-API operation (cites the operation's typed `CsOperationRef` const, §5.23; N call sites : 1 operation) | client | Pure annotation over the existing kernel transport — `TomServerEndpoint`/`TomServerCallSpecs`/`TomServerChannel` (`tom_core_kernel`); no new classes (§5.3). |
| **CE-API** | Server API — request/response types + operation name + error contract | shared (contract) + server (handler) | Reuses `TomApi`/`TomApiEndpoint` (`tom_core_kernel`) + the `TomEndpoint` pipeline (`tom_core_server`), narrowed by annotation to the §7 contract; no new classes (§5.6.1, §5.14). |
| **CE-SU** | Server-side logical units — clustering the server API into functional groups, each ideally a **closure**: an independently useful service with no dependency on other units | server | **No new class.** Modelled as ordinary **(abstract) classes** carrying the `tom_core_server` server-API mapping annotations (`@tomService`/`TomApiImplementation`); the unit is the class grouping its operations. Boundary = §5.1 (owned-aggregate primary + closure/independence) (§5.6.2, §5.17). |
| **CE-DB** | Database access object model | server | Reuses the `tom_core_server` persistence model (entities, columns, repositories) directly; no new classes (§5.13). |
| **CE-ST** | View-model / UI state | client | Reuses `TomObservable`/`TomObject`/`TomClass`/`TomList`/`TomMap` (`tom_core_kernel`) + `TomObservingWidget` (`tom_core_flutter`); no new classes (§5.4). |
| **CE-NV** | Navigation / routing **+ screen-flow** — the screen map that results from combining the interaction scenarios into interactions with **screens** (Flutter routes): which form is assigned to which screen and whether it **replaces** the current screen or **overlays** it as a popup; navigation is triggered by CE-AC actions and its target is **conditional** (success → confirmation or back to the previous screen; error / validation error → error display) | client | Reuses `TomPageRoute` + the `tom_navigation` destinations (`tom_flutter_ui`); the stable route-id registry **and the screen-flow model** (screen↔form assignment, replace-vs-popup, action-conditional transitions) are a new class in `tom_core_codespecs`. Authored from the SOM screen route map (§5.11). |
| **CE-AZ** | Authorization per operation | server | Modifier on CE-API. Reuses the kernel `TomAccessControl` family + the `tom_core_server` graded-authorization runtime; no new classes (§5.6.3, §5.15). |
| **CE-ER** | Structured error-result contract | shared | One envelope for all operations. Reuses `TomResult<T>`/`TomErrorResult` + `TomFieldError`/`TomErrorSeverity` (`tom_core_kernel`) directly; no new classes (§7). |
| **CE-CF** | Server / system configuration | server | Reuses `TomBaseServerConfiguration`/`TomServerConfigResourceProvider` (`tom_core_server`) directly; no new classes (§5.5, §5.16). |
| **CE-CC** | Client configuration — per-machine settings of a client app | client | Reuses `TomBaseClientConfiguration`/`TomSetting<T>`/`TomClientConfigurationStore` (`tom_core_flutter`, `tomclient/configuration/`) directly; no new classes (§5.16, §11). |
| **CE-DS** | Device settings — user-specific settings of a user-owned device, device-persisted | client | **Reuse — no new class.** Modelled with existing `tom_core` property/settings classes that can be directly reused; the (user, device) scope is expressed on those (§11, §5.16). |
| **CE-UP** | User settings — user-scoped, server-persisted, follow the user | client + server | Reuses the round-trip carrier (`TomGetSettingsMessage`/`TomGetSettingsResult`, `tom_core_kernel`) for the server → client bootstrap; the typed holder `TomUserSettings` and the per-user persistence seam `TomUserSettingsStore` are `tom_core_codespecs` gap classes (§11, §5.16). |
| **CE-CL** | Client application — which clients exist (Flutter app, CLI, other server) | client | **No `tom_core` basis yet** — the client-application descriptor is a new pure-Dart class (annotation-marked) in `tom_core_codespecs`; gap to specify. |
| **CE-AU** | Authentication / session — credential flow, token, session (distinct from CE-AZ) | shared + client + server | Pure reuse of the `tom_core` auth stack (no gap class): `TomAuthenticationServer` + the app's `TomAuthenticationService` implementation (server), `TomBearerAuthentication`/`TomClientJwtToken`/wire types (kernel, shared), login endpoint triple + token store (client). Mechanics framework-fixed; the spec surface is binding/methods/flows/policies (§5.25). |
| **CE-ID** | Identity — the principal model plus app-declared identity-attribute extensions in the public and encrypted token payloads (distinct from CE-AU authentication and CE-AZ authorization) | shared + server | **Reuse — no new class.** Built on `TomUser` + `TomPrincipal` (`tom_core_kernel`); the profile extension is modelled as an **ordinary class**, directly reusable and carried as **JSON via reflection** in the user profile (§5.24). |
| **CE-MG** | Schema migration — database schema versioning / migration artifacts derived from the data model's evolution (initial DDL, base/seed data, iteration scripts) | database | Pure reuse of the `tom_core_server` migration engine — `TomDbMigrations`/`TomDbMigrator`/`TomMigrationFileName`/`TomDbMigrationAdaptor` + `MariadbMigrationAdaptor`; the artifacts are numbered SQL files in the migrations directory tree, not Dart classes (§5.27). |
| **CE-JB** | BackgroundJob — scheduled / background / queued jobs (cron, calendar, event triggers) distinct from request-driven CE-API: trigger + work definition + target refs + retry/backoff/timeout/alerting | server | A **job base class** in `tom_core_codespecs` that lets the job's execution be plugged into any scheduling system. The job body is written as compilable **pseudo-code** calling a later-injected **abstract service class** (methods laid out with detailed doc-comments describing intended behaviour, §3). Built on `tom_core_kernel`'s `scheduling` module — `TomJobDefinition`, the `TomSchedule` family, `TomScheduler`, `TomJobStore`, `TomLeaseLock` and `TomJobDispatcher` — over the `TomCommand`/`TomExecutor`/`TomWorker` isolate-pooling substrate, so the scheduler runtime, durable job queue and multi-node single-fire locking are all reused rather than specified (§5.29). |

**Member kind — domain enums.** Domain enums are not a part in this table:
`domainEnum` is a **member kind**. A domain enum is authored within its owning
part — a CE-DB entity, a CE-CF/CE-CC/CE-DS/CE-UP setting, a CE-ST view model, or a
CE-API contract member — and marked `@CsEnum`; see the §4.1 rule for the
placement rule.

### 4.1 Authoritative parts catalogue

This is the **authoritative, stable catalogue**. Each part has **one canonical
id** (a PascalCase noun) that drives its surfaces (there is no base-class
surface — pillar (a)/(b)):

1. **`@CodeSpecKind` value** — `CodeSpecPart.<camelCase(id)>`. The enum value a SOM
   section type carries (in a **list**, §9.1) to say "realise me as this kind".
   The enum is named `CodeSpecPart`; `@CodeSpecKind` is the annotation class.
2. **`Cs*` annotation(s)** — the `@Cs<id>` family (all `Cs*`-prefixed), plus
   finer-grained members.
3. **Reused `tom_core` class** — the concrete existing class the CodeSpec is built
   on. A **`gap`** marker means the concrete class is added in `tom_core_codespecs`
   (never an abstract `Cs*` base).

| CE | Canonical id | `@CodeSpecKind` value | `Cs*` annotation(s) | Built on (`tom_core` class / `gap`) |
|----|--------------|-----------------------|---------------------|--------------------------------------|
| CE-EL | ScreenElement | `screenElement` | `@CsElement`, `@CsWidget` | `TomScreenElementsProvider` + the `Tom*` element/widget family (`tom_flutter_ui`); **reuse, no gap** — the element kinds are the existing `Tom*` widgets (§5.7.1, §5.18) |
| CE-FM | Form | `form` | `@CsForm` | `TomForm`, `TomFormChildContainer` (`tom_flutter_ui`) |
| CE-LO | Layout | `layout` | `@CsLayout` | `AclContainer` / `AclRow` / `AclComponent` (`tom_flutter_ui`); node model → **gap** (§5.2, §5.12) |
| CE-TX | Text | `text` | `@CsText` | `TomText` (`tom_flutter_ui`) + `TomTextResourceProvider` (`tom_core_kernel`); message/i18n-key model → **gap** (§5.8, §5.21) |
| CE-VA | Validation | `validation` | `@CsValidation` | `Validators` (`tom_flutter_ui`); **no gap** — provided as **Dart validation methods** (standalone validator classes or methods on the `TomForm` subclass), the §3 first-level-implementation latitude (§5.9, §5.19) |
| CE-AC | Action | `action` | `@CsAction`, `@CsTrigger` *(required `TriggerKind`)* | `TomAction` / `TomActionController` / `TomActionTrigger` (`tom_flutter_ui`); **no gap** — full action implementation reused (§5.10, §5.20). The closed 5-kind trigger taxonomy rides `@CsTrigger` as a documented classification, not a class |
| CE-SC | ServerCall | `serverCall` | `@CsServerCall` | `TomServerEndpoint<T,R>` + `TomServerCall` / `TomServerCallSpecs` / `TomServerChannel` (`tom_core_kernel`, §5.3) |
| CE-API | ServerApi | `serverApi` | `@CsEndpoint` | `TomApi` / `TomApiEndpoint<R,Q>` / `TomRemoteApis` (`tom_core_kernel`) + `TomEndpoint` / `TomEndpointHandler` / `TomEndpointRouting` / `TomServer` (`tom_core_server`) (§5.6.1) |
| CE-SU | ServiceUnit | `serviceUnit` | `@CsServiceUnit` | **no gap** — ordinary **(abstract) classes** clustering the server API into functional-group *closures*, carrying the `tom_core_server` server-API mapping annotations (`@tomService` / `TomApiImplementation`) (§5.1, §5.6.2) |
| CE-DB | DataAccess | `dataAccess` | `@CsTable`, `@CsColumn`, `@CsRepository` | Tom persistence model + repository (`tom_core_server`) |
| CE-ST | ViewState | `viewState` | `@CsViewModel` | `TomObservable` / `TomObject` (`tom_core_kernel`) |
| CE-NV | Navigation | `navigation` | `@CsRoute`, `@CsScreenFlow` | `TomPageRoute` (`tom_flutter_ui`); route-id + **screen-flow** model (screen↔form assignment as *replace* / *popup overlay*; action-triggered, conditional targets) → **gap** (§5.11) |
| CE-AZ | Authorization | `authorization` | `@CsAuthorize` | `TomAccessControl*` hierarchy + `TomPrincipal` (`tom_core_kernel`); enforcement `checkAccess` / graded auth (`tom_core_server`) (§5.6.3, §5.15) |
| CE-ER | ErrorResult | `errorResult` | `@CsError` | `TomResult<T>` / `TomErrorResult` (`tom_core_kernel`) (§7) |
| CE-CF | ServerConfiguration | `serverConfiguration` | `@CsServerConfig` | `TomBaseServerConfiguration` + `TomServerConfigResourceProvider` (`tom_core_server`) (§5.5, §5.16) |
| CE-CC | ClientConfiguration | `clientConfiguration` | `@CsClientConfig` | `TomBaseClientConfiguration` + `TomSetting<T>` + `TomClientConfigurationStore` (`tom_core_flutter`); baseline layer `TomConfigResourceProvider` (`tom_core_kernel`) (§5.16) |
| CE-UP | UserSettings | `userSettings` | `@CsUserSetting` | `TomUserSettings` + `TomUserSettingsStore` (`tom_core_codespecs`); round-trip substrate `TomGetSettings*` (`tom_core_kernel`) (§5.16) |
| CE-DS | DeviceSettings | `deviceSettings` | `@CsDeviceSetting` | **reuse — no new class**; modelled with existing `tom_core` property/settings classes, directly reusable (§5.16, §11) |
| CE-CL | Client | `client` | `@CsClient` | client-application descriptor → **gap** |
| CE-AU | Authentication | `authentication` | `@CsAuth` | `TomAuthenticationServer` + `TomAuthenticationService` (`tom_core_server`); `TomBearerAuthentication` / `TomClientJwtToken` / wire types (`tom_core_kernel`); login endpoint triple client-side |
| CE-ID | Identity | `identity` | `@CsIdentity`, `@CsIdentityAttribute` *(with `placement: public\|encrypted`)* | `TomUser` / `TomPrincipal` (`tom_core_kernel`); **reuse — no new class** — the profile extension is an **ordinary class**, directly reusable and carried as **JSON via reflection** in the user profile (§5.24) |
| CE-MG | SchemaMigration | `schemaMigration` | `@CsMigration` | `TomDbMigrations` / `TomDbMigrator` / `TomMigrationFileName` / `TomDbMigrationAdaptor` / `MariadbMigrationAdaptor` (`tom_core_server`) (§5.27) |
| CE-JB | BackgroundJob | `backgroundJob` | `@CsJob` | `TomCommand` / `TomExecutor` / `TomWorker` isolate-pooling substrate (`tom_core_kernel`); a **job base class** → **gap** (`tom_core_codespecs`) that plugs into any scheduling system, its work body written as compilable **pseudo-code** over a later-injected **abstract service class** (§3, §5.29) |

**Rules that make the catalogue authoritative:**

- **CE is the stable key; the canonical id is the identifier.** The `CE-*` code is
  the permanent registry key (never reused, never renamed). `@CodeSpecKind` values
  are the camelCased canonical ids — **the `CodeSpecPart` enum is generated from
  this table**, so kind values and ids never drift.
- **Collision-free.** All 23 active canonical ids are distinct nouns; all 23
  active kind values are distinct; all `Cs*`
  annotation names are distinct. The **4 deferred candidate ids and kind values**
  of §4.3 and the member kind `domainEnum` are drawn from the same namespace and
  are collision-free against these 23 — giving **28 distinct kind values** in
  the `CodeSpecPart` enum (the `reporting` value stays reserved as a deferred
  part; it is not removed from the enum, only reclassified).
- **Deferred parts are mapping-only (§4.3).** A deferred part gets a **reserved
  `CodeSpecPart` value** so its SOM section can already carry `@CodeSpecKind`, but has
  **no `Cs*` annotation, no "Built on" `tom_core` class and no generated code**
  until it is promoted into this table. Promotion adds the missing surfaces; the
  reserved kind value is stable and never changes.
- **No base classes.** The catalogue has **no `Cs*` base-class column** — a
  CodeSpec is built on the "Built on" `tom_core` class, marked by its `Cs*`
  annotation(s). A `gap` there is a **concrete** `tom_core_codespecs` class.
- **Traceability is not in the catalogue.** Traceability rides on *every*
  element via `@CodeSpec`/`@DocSpec` — its sole home is **§9**; no SOM section
  type maps to it. The **`CE-TR`** token remains the stable registry key naming
  that cross-cutting mechanism (registry keys are never reused or renamed).
- **Domain enums are member kinds, not parts.** A domain enum is a **member
  declaration of the part that introduces it** — a CE-DB entity column, a
  CE-CF/CE-CC/CE-DS/CE-UP setting, a CE-ST view-model field, or a CE-API
  request/response member. The enum declaration is authored **once**, marked
  `@CsEnum` (which keeps the `@DocSpec` back-trace to its SOM `DMENE` entry and
  keeps it discoverable as an `@OneOf` discriminator source), and realised as a
  plain Dart `enum` — no `tom_core_codespecs` class. **Placement:** the shared
  project iff a shared contract type (a CE-API request/response type or CE-ER)
  references it; otherwise the owning part's project. `CodeSpecPart.domainEnum`
  is the corresponding **member kind** — SOM sections (`DMENE`, `OBST`) carry
  it like any other `@CodeSpecKind` value; the SOM `DomainEnumRegistry` (DOMEN)
  stays the single document-model authoring home for closed value sets, while
  the owning part determines where the generated enum lives.
- **CE-AZ is a modifier**, applied as a `@CsAuthorize` attribute on the owning
  `@CsEndpoint`.
- **Settings parts are owner-keyed and single-moded.** Each configuration/
  settings part is pinned to exactly one scope key — CE-CF (server/system),
  CE-CC (client app + machine, no user), CE-DS (user + device,
  device-persisted), CE-UP (user, server-persisted — follows the user). No
  part carries a persistence discriminator; the scope key alone decides where
  a value lives (§11).
- **Two internal-modeling decisions.** The CE-SU service-unit boundary
  criterion is defined in **§5.1**; the CE-LO layout-node representation in
  **§5.2**.

#### 4.1.1 Part readiness — mapping, examples and gap analysis

This table details, per part — **including the §4.3 deferred parts** — how the
part is actually coded in CodeSpecs: the `tom_core`-family classes it builds on,
the `Cs*` annotations that carry specification detail beyond what plain Dart
code can express, and the two gap dimensions.

**The coding-form spectrum.** "Built on a `tom_core` class" is relative — a
CodeSpec takes one of four coding forms:

1. **Framework subclass/instantiation** — extends or instantiates a
   `tom_core`-family class (`TomForm`, `TomAction`, `TomApiEndpoint`,
   `TomServerEndpoint`, …).
2. **Plain annotated model class** — a totally new, ordinary Dart data/object
   class whose spec detail rides entirely on `Cs*` annotations and doc comments:
   API request/response objects, config/settings holders, identity extensions,
   the client descriptor, message-key and error-code catalogues.
3. **Compilable pseudo-code** — algorithmic CodeSpecs written as real Dart
   calling **abstract API classes**; in the CodeSpecs phase a body may be
   `throw UnsupportedError('<free-text explication>')` — it compiles, names its
   collaborators and inputs/outputs, and defers the algorithm to Phase 6.
4. **Annotation-only modifier** — no class of its own; an attribute on another
   part's element (CE-AZ as `@CsAuthorize` on `@CsEndpoint`).

**Gap definitions.** A ***`tom_core` gap*** means new base classes, abstraction
classes or annotations are needed in the core family (concrete gap classes land
in `tom_core_codespecs`, §1.1). A ***`tom_code_specs` gap*** means the CodeSpecs
code needs **additional annotations** so the code carries the specification
details *completely* — beyond what simple code can express (element kinds,
maximum lengths, format restrictions, placement, schedules, grades, …).

**Annotation authoring state.** 30 annotations exist in `tom_code_specs` today —
one per part, plus the several markers a part may own (CE-EL, CE-AC, CE-NV,
CE-DB). The §4.3 deferred candidates deliberately have **no** annotation: a
deferred part's `CodeSpecPart` value is reserved so a SOM section can already
carry `@CodeSpecKind`, but the marker is authored only on promotion. The
finer-grained validation members `@CsFieldRule` / `@CsFormRule` are catalogued
but **not yet authored**, and the entire §5.23 `Cs*Ref` typed-reference family is
designed but unimplemented (`csra6`, §10). The gap columns
cite the owning open-work todos: `csra*` in `todos.tom_specs.todo.yaml` (§10)
and `csex*` in `_ai/quests/tom_core/todos.tom_core.todo.yaml` — the `tom_core`
quest's framework-readiness series, which owns the core-side roadmap items.

| Part ID | Part Description | Mapping to CodeSpecs | Gap analysis `tom_core` | Gap analysis `tom_code_specs` |
|---------|------------------|----------------------|-------------------------|-------------------------------|
| **CE-EL** ScreenElement | A single visible/interactive element of a screen. Closed **10-kind catalogue** (§5.18): form-member kinds *TextInput, Number, Toggle, DateInput, Choice, MultiChoice*; standalone kinds *Label, Button, MenuEntry, FormHost*. | **Built on:** `TomScreenElementsProvider` + the `Tom*` widget family (`tom_flutter_ui`) — TextInput → `TomFormStringField`, Number → `TomFormIntField`/`TomFormDoubleField`, Toggle → `TomFormBoolField` (`TomFormNullableBoolField` when `tristate`), DateInput → `TomFormDateField`/`TomFormTimeField`, Label → `TomText`/`TomLabelBase`, FormHost → the CE-FM `TomForm` host. Form-member elements are coded as CE-FM field members; standalone elements as provider-created widgets.<br>**Annotations:** `@CsElement(kind: …)` on the field/member; `@CsWidget` on a standalone widget CodeSpec.<br>**Example:** `@CsElement(kind: 'TextInput') late final TomString email;` inside the `@CsForm` class — kind, label key and grade ride on the annotation. | None — the closed catalogue maps 1:1 onto shipped `tom_flutter_ui` widgets and needs no new base class, and every per-kind attribute has a carrier: `csexb1` added the `TomFormNullableBoolField` family for `tristate` and the `minItems`/`maxItems` field rules the MultiChoice selection bounds desugar to (§4.1.2). | `@CsElement` must carry what code cannot: the element **kind** (the declared Dart type does not fix *TextInput* vs *Choice*), label/hint **message keys** (`CsMessageKey`, §5.23 — not yet authored) and display/read-only **grade** defaults. |
| **CE-FM** Form | A user-facing form: typed field collection, lifecycle (load/edit/submit), per-field grades. | **Built on:** subclass of `TomForm<T extends TomClass>` (`tom_flutter_ui/lib/src/forms/tom_form.dart`); fields as `TomField<T>` members; nesting via `TomFormChildContainer`.<br>**Annotations:** `@CsForm(id)` on the class; fields carry `@CsElement` + `@CsValidation`.<br>**Example:** `@CsForm('customer_edit') class CustomerEditForm extends TomForm<Customer> { … }` | None — full reuse. | `@CsForm` needs form-level spec detail code omits: the bound view-model type link, the submit target as a typed `CsCallRef`/`CsActionRef` (§5.23, not yet authored), form-level authorization-grade defaults. |
| **CE-LO** Layout | Two-layer **id-addressed** layout: container tree (rows/containers) + component placement; delta overrides via the closed **5-op grammar** (§5.22): *reparent, set-container-prop, set-slot-hint, insert-container, remove-container*. | **Built on:** `AclRow` / `AclContainer` / `AclComponent` (`tom_flutter_ui/src/advanced_container_layout/acl_container.dart`), rendered via `TomObservingWidget`. The layout CodeSpec itself is a **plain annotated model class** describing the node tree.<br>**Annotations:** `@CsLayout` on the node-model class.<br>**Example:** a layout class whose members declare container nodes with stable ids and component slots, each slot naming its CE-EL element. | **Gap** — the id-addressed **node model** (stable node ids over the `Acl*` tree + the 5-op delta grammar) has no `tom_core` class; the concrete node-model class lands in `tom_core_codespecs` (§5.2, §5.12; `csra2`). The runtime `Acl*` classes themselves are ready. | `@CsLayout` needs attributes for node **ids**, **slot hints** and per-node **override deltas** — the delta grammar is a pure specification concern that cannot ride in plain widget code. |
| **CE-TX** Text | User-visible text: message/i18n **keys** (shared), per-client **copy**. | **Built on:** `TomTextResourceProvider` (`tom_core_kernel`, `tombase/resources/tom_resource_provider.dart`) resolves keys; copy is basePath-derived client-side.<br>**Annotations:** `@CsText` on a plain constants class in the shared project; keys as §5.23 `CsMessageKey` consts.<br>**Example:** `@CsText class Messages { static const custNameLabel = CsMessageKey('customer.name.label'); }` | **Gap** — the typed **message-key registry** model (the catalogue of keys, SOM home MSGKR) has no core class; the concrete registry class lands in `tom_core_codespecs` (§5.8, §5.21). | `CsMessageKey` (§5.23) not yet authored; `@CsText` needs attributes for key namespace/basePath and **placeholder arity/format** of message parameters — pure spec detail. |
| **CE-VA** Validation | Field + form validation; closed **10-rule catalogue**: *required, email, minLength, maxLength, pattern, min, max, minItems, maxItems, compose*. | **Built on:** `Validators` static catalogue + `TomValidatorRegistry` declaration strings (`'required, minLength:8, pattern:^[A-Z]'`) + the sealed `ValidationResult` family and `FormValidationError` (`tom_flutter_ui/lib/src/forms/validation/`). Coded as **Dart validation methods** on the form or standalone validator classes (the §3 first-level-implementation latitude); cross-field form rules as **compilable pseudo-code** methods.<br>**Annotations:** `@CsValidation` on the method/field.<br>**Example:** `@CsValidation('required, maxLength:80') late final TomString name;` | None — the 10-rule catalogue is shipped 1:1 in `Validators`. | `@CsFieldRule` / `@CsFormRule` are catalogued but **not yet authored** (`qr3`, §10) — needed to state rule kind + parameters (max length, format regex, numeric ranges) *declaratively*, so the constraint is not only inside a method body; error texts keyed via `CsMessageKey`. |
| **CE-AC** Action | A user-triggerable action with undo/transaction support; closed **5-kind trigger taxonomy**: *user-gesture, in-form event, lifecycle, server-event, condition*. | **Built on:** subclass of `TomAction<TContext, TUndo>`, registered on `TomActionController`, wired by `TomActionTrigger` (the single authoring home of the element→action edge), with `TomActionTransaction` / `TomActionContext` (`tom_flutter_ui/lib/src/actions/`). CodeSpecs-phase bodies are **pseudo-code**.<br>**Annotations:** `@CsAction` on the class; `@CsTrigger(kind: …)` on the trigger declaration.<br>**Example:** `@CsAction('save_customer') class SaveCustomerAction extends TomAction<…> { @override perform(ctx) => throw UnsupportedError('persist via CustomerService.save'); }` | None — the full action implementation is reused. | `@CsTrigger` must carry the trigger **kind**, source element and guard-condition text; `@CsAction` the undo contract and its server-call target as a `CsCallRef` — the two-hop CE-AC → CE-SC → CE-API edge is spec detail beyond code. |
| **CE-SC** ServerCall | The client-side declaration of a call to a server operation. | **Built on:** `TomServerEndpoint<T, R>` + `TomServerCall` / `TomServerCallSpecs` / `TomServerChannel` (`tom_core_kernel`, `tombase/http_connection/server_connection.dart`); declared as typed endpoint fields in a client calls class (§7: all POST, the operation name carries the intent).<br>**Annotations:** `@CsServerCall(operation)`.<br>**Example:** `@CsServerCall('customer.save') final saveCustomer = TomServerEndpoint<CustomerSaveRequest, CustomerDto>(…);` | None. | Needs `CsOperationRef` (§5.23, not yet authored) so the call ties to its `@CsEndpoint` by **typed reference**, not by string; retry/timeout expectations as attributes where the spec states them. |
| **CE-API** ServerApi | A server-side operation endpoint under the §7 contract: POST-only, `TomResult`/`TomErrorResult` envelope, 5xx = transport only. | **Built on:** `TomApi` / `TomApiEndpoint<ReturnType, RequestType>` / `TomRemoteApis` (`tom_core_kernel`) + `TomEndpointHandler` / `TomEndpointRouting` / `TomApiEndpointImplementation` / `TomServer` (`tom_core_server`). Request/response types are **plain annotated model classes** in the shared project.<br>**Annotations:** `@CsEndpoint(operation)` + the `@CsAuthorize` modifier (CE-AZ).<br>**Example:** `@CsEndpoint('customer.save') @CsAuthorize(kind: role, key: 'sales')` on the operation; its `CustomerSaveRequest` members carrying field-constraint annotations. | None. | The request/response **members** need field-level constraint annotations — maximum length, format restriction, required-ness — the classic beyond-code detail; plus `CsErrorCode` refs (§5.23) enumerating which CE-ER codes the operation can return. |
| **CE-SU** ServiceUnit | A functional-group *closure* of the server API (§5.1 boundary: owned-aggregate primary, process cohesion, bounded context); id `<RootAggregate>Service`; membership **derived, not listed**. | **Built on:** ordinary **(abstract) classes** carrying the `tom_core_server` mapping annotations (`@tomService` / `TomApiImplementation`, discovered via `scanClasses` / `TomComponentReference`); methods are the operations, CodeSpecs-phase bodies **pseudo-code** / `UnsupportedError`.<br>**Annotations:** `@CsServiceUnit('CustomerService')`.<br>**Example:** `@CsServiceUnit('CustomerService') abstract class CustomerService { Future<CustomerDto> save(CustomerSaveRequest r); }` | None. | `@CsServiceUnit` needs a **boundary-rationale attribute** (which §5.1 criterion binds the unit) and a `CsServiceUnitRef` (§5.23, not yet authored) for cross-unit references. |
| **CE-DB** DataAccess | Persistence: entities/tables, columns, repositories, queries (server-only placement; §5.13 three-level attribute surface). | **Built on:** the `tom_core_server` persistence model — CRUD/MariaDB repositories, query builder, persistence annotations. Entities are **plain annotated model classes**; query intents are **pseudo-code** repository methods in the CodeSpecs phase.<br>**Annotations:** `@CsTable('customer')` on the entity, `@CsColumn(…)` per attribute, `@CsRepository` on the repository class.<br>**Example:** `@CsTable('customer') class Customer { @CsColumn(length: 80) late String name; }` | None — the aggregation grammar is carried by `tom_core_server`'s `object_persistence/grouped_query.dart`: `TomAggregateFunction` (`count` / `sum` / `avg` / `min` / `max`, `distinct`-capable), `groupBy` key columns and a `having` group predicate, compiled through the query builder and sentence compiler and surfaced on the CRUD repository. Aggregate query specs are realisable over the query model, for **active CE-DB** as well as for deferred CE-RP. | `@CsColumn` must express what Dart types cannot: **max length, precision/scale, format restriction, uniqueness, db-nullability** vs Dart-nullability, and the column-level access grade (**authKey**, §5.13); `@CsRepository` the derived-query intent. |
| **CE-ST** ViewState | Observable client view-model state. | **Built on:** `TomObservable` / `TomObject<T>` / `TomString` / `TomInt` / `TomBool` / `TomClass` / `TomList` / `TomMap` (`tom_core_kernel` observable) + `TomObservingWidget` / `ValueListenableObserver` (`tom_core_flutter`). The view-model is a `TomClass` subclass with observable members.<br>**Annotations:** `@CsViewModel`.<br>**Example:** `@CsViewModel class CustomerListState extends TomClass { final customers = TomList<…>(…); }` | None. | Minor — `@CsViewModel` attributes linking state fields to their **source** server call / entity (derivation provenance) where the spec states it. |
| **CE-NV** Navigation | Routes + **screen flow**: screen↔form assignment as *replace* / *popup overlay*; action-triggered, conditional targets. | **Built on:** `TomPageRoute<T>` + `TomNavigationDestination`/Rail/Bar/Drawer (`tom_flutter_ui`) for shell chrome. The route registry is a **plain annotated constants class**.<br>**Annotations:** `@CsRoute('customer/edit')` per route; `@CsScreenFlow` on flow declarations.<br>**Example:** `@CsRoute('customer/edit') static const customerEdit = CsRouteRef('customer/edit');` | **Gap filled in `tom_core_codespecs`** — `tom_core` has no route-id registry or screen-flow model, so `route_flow.dart` carries `TomRouteRegistry` / `TomRouteDefinition` / `TomFormScreenAssignment` / `TomScreenFlowEdge` over `TomScreenPresentation` + `TomFlowOutcome` (§5.11); the SOM authoring home is the **screen route map** (`SCRTMP`) under D09 XDS `ScreenFlowStructure`. | `@CsScreenFlow` must carry the **transition kind** (*replace* vs *popup overlay*), the trigger (`CsActionRef`) and conditional-target expressions; `CsRouteRef` typed refs (§5.23) not yet authored. |
| **CE-AZ** Authorization | Access control on operations/resources; presets (`TomNoAccess` / `TomPublicAccess` / `TomAuthenticatedAccess` / `TomGuestAccess`) + **six configurable kinds**. | **Built on:** the `TomAccessControl` family (`tom_core_kernel`, `tombase/security/access_controls.dart`) — `TomRoleAccess`, `TomGroupAccess`, `TomEntitlementAccess`, `TomResourceKeyAccess`, `TomCustomAccess`, `TomGradedAccess` — evaluated via `checkAccessibility(TomPrincipal?)` + `resolveAuthState` against `TomPrincipal`.<br>**Annotations:** applied as the `@CsAuthorize` **modifier** on the owning `@CsEndpoint` (annotation-only form — no class of its own).<br>**Example:** `@CsEndpoint('customer.save') @CsAuthorize(kind: role, key: 'sales')` | None — `TomServerPrincipal` holds the ambient server principal and both evaluation entry points apply the `min(user, server)` meet (§5.26). | `@CsAuthorize` needs `CsRoleRef` / `CsResourceKeyRef` typed refs (§5.23, not yet authored) instead of raw strings; per-field **graded-access levels** (CE-EL / CE-DB grades) are annotation-only detail. |
| **CE-ER** ErrorResult | The shared error/result envelope + the error-code catalogue. | **Built on:** `TomResult<T>` / `TomErrorResult` / `TomFieldError` / `TomErrorSeverity` (`tom_core_kernel`, `tombase/result/result.dart`). The error catalogue is a **plain annotated constants class** in the shared project; texts keyed via CE-TX.<br>**Annotations:** `@CsError` per code.<br>**Example:** `@CsError(severity: error) static const custNotFound = CsErrorCode('CUST-404');` | None. | `CsErrorCode` (§5.23) not yet authored; `@CsError` attributes for **severity**, **message key**, and which operations raise the code. |
| **CE-CF** ServerConfiguration | Server/system-scope configuration; precedence config-tree → env → `.env` → cmdline; secret marking. | **Built on:** subclass of `TomBaseServerConfiguration` + `TomServerConfigResourceProvider` (`tom_core_server`). A **plain typed config class**; config keys stay strings (§5.23 exemption).<br>**Annotations:** `@CsServerConfig` on the class; per-field attributes.<br>**Example:** `@CsServerConfig class AppServerConfig extends TomBaseServerConfiguration { @CsSecret late String smtpPassword; }` *(secret-marking attribute shape per §5.16)* | None. | Per-field annotations for **secret marking**, **default value**, **format restriction** and **allowed range** — spec detail beyond a Dart field declaration. The SMTP settings (`smtpHost`, `smtpPort`, `smtpSecurity`, `smtpUsername`, `smtpPassword`, `smtpFrom*`, `smtpClientName`) are the live exemplar: declared on `TomBaseServerConfiguration`, with `smtpPassword` secret-bearing — its *declaration* authored, its *value* supplied only through the precedence chain. |
| **CE-CC** ClientConfiguration | Client-app + machine scope (no user); single-moded per §11. | **Built on:** subclass of `TomBaseClientConfiguration` (`tom_core_flutter`, `tomclient/configuration/client_configuration.dart`) — settings declared in `declareSettings()` as `TomSetting<T>` under dotted keys, baselines resolved from `TomConfigResourceProvider` (`tom_core_kernel`), overrides persisted through a `TomClientConfigurationStore` (memory / JSON-file variants).<br>**Annotations:** `@CsClientConfig` on the holder class; per-field constraint attributes.<br>**Example:** `@CsClientConfig class AppClientConfig extends TomBaseClientConfiguration { late final TomSetting<String> serverUrl; @override void declareSettings() { serverUrl = stringSetting('client.server.url', 'https://…'); } }` | None — the holder was built by `csex12` (decision (b)): typed access, defaults, load-at-startup, persistence of **overrides only**, and observation both per field and holder-wide. | Same per-field constraint attributes as CE-CF (defaults, formats, ranges) — annotation-borne, not holder behaviour. |
| **CE-UP** UserSettings | User-scope, **server-persisted** settings — follows the user (§11). Single-moded: there is no persistence argument, because the scope key alone decides where a value lives. | **Built on:** the round-trip substrate `TomGetSettingsMessage` / `TomGetSettingsResult` (`tom_core_kernel`, `tombase/settings/settings_client_authorization.dart`), reused as-is for the server → client bootstrap, plus `TomUserSettings` + `TomUserSettingsStore` (`tom_core_codespecs`).<br>**Annotations:** `@CsUserSetting` per field.<br>**Example:** `@CsUserSetting(defaultValue: 'de') late String preferredLanguage;` | None — both halves of the gap are closed: `TomUserSettings` is the typed holder (with `effectiveValue` applying the persisted-value → default order), and `TomUserSettingsStore` is the server-side per-user persistence seam. The kernel carrier is read-only, so the write-back path had no home before it. | Per-field **default / format / visibility** attributes (incl. which settings surface in a settings form — the CE-FM link). |
| **CE-DS** DeviceSettings | (user, device) scope, device-persisted (§11). | **Built on:** reuse — existing `tom_core` property/settings classes, directly reusable; no new class (§5.16).<br>**Annotations:** `@CsDeviceSetting` per field. | None. | Same constraint-attribute surface as CE-UP. |
| **CE-CL** Client | A client application of the system: which screens/forms/flows it comprises, its platform targets, its entry route. | **No `tom_core` basis by design** — the client descriptor is a **pure plain annotated Dart class** (coding form 2).<br>**Annotations:** `@CsClient` on the descriptor.<br>**Example:** `@CsClient(platforms: […]) class BackofficeClient { … }` referencing routes (`CsRouteRef`) and forms. | **Gap** — the **client-application descriptor** class (a simple concrete data class) lands in `tom_core_codespecs`. | `@CsClient` attributes: **platform targets**, **entry route**, included flows — none expressible in plain code. |
| **CE-AU** Authentication | Login, token issuance/refresh; optional 2FA. | **Built on:** `TomAuthenticationServer` + the app's `TomAuthenticationService` (`tom_core_server`); wire/token types `TomBearerAuthentication` / `TomClientJwtToken` / `TomAuthenticationMessage` / `TomAuthenticationResult` / `TomServerJwtToken` (`tom_core_kernel` / `tom_core_server`). Pure reuse; the login endpoint triple is client-side.<br>**Annotations:** `@CsAuth` marks the app's auth service + client flow. | None — the two-pass flow is complete (`tom_core_server`, `authentication_server.dart`): pass 1 issues a `Tom2FAChallenge` interim token carrying the access-control payload it already resolved, `authenticatePass2` verifies it statelessly through the `Tom2FARegistry` adaptor for the challenge's mechanism, and the challenge's own `validity` plus its attempt allowance bound the chain. A 2FA spec is realisable. | `@CsAuth` attributes for **flow kind** (password / 2FA), token-lifetime expectations, refresh policy. |
| **CE-ID** Identity | User identity + the app-specific profile extension; per-attribute **public vs encrypted** placement. | **Built on:** `TomUser` / `TomPrincipal` (`tom_core_kernel`, `tombase/security/user_principal_aci.dart`). The profile extension is an **ordinary class carried as JSON via reflection** — public carrier `TomUser.attributes`, encrypted carrier `TomPrincipal.currentContext` via `convertPrincipalToTokenPayload` (§5.24).<br>**Annotations:** `@CsIdentity` on the extension class; `@CsIdentityAttribute(placement: public\|encrypted)` per field — `placement` is a **required** named argument of the closed `IdentityAttributePlacement` enum, never defaulted, because §5.16's fail-safe rule forbids choosing a token-payload arm by omission.<br>**Example:** `@CsIdentity class EmployeeProfile { @CsIdentityAttribute(placement: encrypted) late String costCenter; }` | None — reuse; both carriers exist. | Per-field **placement** + format/length constraints — identity attributes are the prime example of annotation-borne restrictions the code alone cannot state. |
| **CE-MG** SchemaMigration | The SQL migration chain; filename grammar `[<version>]-<description>[@<env>].<ext>`. | **Built on:** `TomDbMigrations` / `TomDbMigrator` / `TomMigrationFileName` / `@TomDbMigrationAdaptor` / `MariadbMigrationAdaptor` (`tom_core_server`, `tomserver/db_migration/`). Migration files are SQL assets; the CodeSpec is the registration class.<br>**Annotations:** `@CsMigration` on the migrations class. Migration **filenames stay strings** (§5.23 exemption). | None — execution substrate is pure reuse, and the **schema-diff engine** proving cumulative migration DDL ≡ the `@CsTable`/`@CsColumn` entity model (the §5.27 named validator check) ships alongside it as `schema_model.dart` / `schema_ddl_reader.dart` / `schema_convergence.dart`. That check is the **only integrity guard** available over the string-exempt migration filenames, so it is the one every CE-MG spec relies on. | `@CsMigration` needs attributes tying a migration to the **entity-model version** it converges to. |
| **CE-JB** BackgroundJob | Scheduled / queued background work. | **Built on:** `tom_core_kernel`'s `tombase/scheduling/` module — `TomJobDefinition`, the `TomSchedule` family, `TomScheduler`, `TomJobStore`, `TomLeaseLock`, `TomJobDispatcher` — over the `TomCommand` / `TomExecutor` / `TomWorker` isolate-pooling substrate. A job pairs a `TomJobDeclaration` (the gap: deployment/ownership envelope) with its own `TomJobDefinition`, whose work body is **compilable pseudo-code** over a later-injected abstract service (§3, §5.29).<br>**Annotations:** `@CsJob`.<br>**Example:** `@CsJob() class NightlyCleanupJob { final declaration = TomJobDeclaration(jobId: 'nightly_cleanup', serviceUnitId: 'sessions'); ... }` | None — the runtime is reused wholesale from `tom_core_kernel`'s `scheduling` module (scheduler, durable job store, multi-node lease), and the deployment/ownership envelope `tom_core` has no place for is carried by `tom_core_codespecs`'s `TomJobDeclaration` (`jobId` / `displayName` / `enabled` / `environments` / `serviceUnitId` / `targetRefs`, with `runsIn(environment)`). Gating is **opt-out** and an empty `environments` list means *every* environment, so a spec states only the exceptions. | **Schedule expression**, **concurrency/single-fire policy** and **retry policy** are spec detail authored onto the reused `TomSchedule` / `TomRetryPolicy` surface. |
| **CE-RP** Reporting *(deferred, §4.3)* | Tabular / aggregated reporting with export channels (screen, `fileExport` CSV/PDF/XLSX); SOM home REPENT (D09). | Mapping-only: the reserved `CodeSpecPart.reporting` kind — **no `Cs*` annotation, no built-on class, no generated code** until promoted. On promotion it would build on CE-DB queries + a **tabular result envelope**. | **One gap:** the **tabular result envelope** — a tom_specs-owned `tom_core_codespecs` gap still to design. Everything else promotion needs is in place: the `tom_core_server` `export` module renders CSV/XLSX/PDF through one streaming abstraction over both the `apiResponse` and `fileExport` channels (`doc/export.md`), the `file_storage` module backs the store seam via `TomBlobExportStore`, and the CE-DB aggregation grammar (`grouped_query.dart`) supplies the grouped results a report projects. The envelope is **adapted onto** the renderers' minimal tabular shape rather than replacing it; its one inherited constraint is that rows stay streamable. Charts stay unrendered by design. | Future `@CsReport` + the reserved `CsReportRef` (§5.23). |
| **CE-WF** Workflow *(deferred, §4.3 — deferral recommended on the merits)* | Long-running multi-step business process; SOM home DEPRWO (D02). | Mapping-only — reserved kind value; no surfaces. Would require a state-machine / process runtime. | **No substrate, and none recommended** — the survey in **§4.3.1** (owner `csex13`) found DEPRWO is free text with no machine-readable step graph, no driving system needing a durable wait or compensation, and the realistic cases already served by CE-JB jobs + CE-AC actions + CE-DB state. The one real gap — a one-shot timer schedule — is a small `TomSchedule` subclass (`csexb6`), not an engine. `csra7` decides with that input. | Future annotation family undefined; §4.3.1 fixes the **at-least-once, idempotent step body** guarantee any future surface must carry. |
| **CE-NT** Notification *(deferred, §4.3)* | Outbound user notifications, email first; SOM home NM (D06, ATS). | Mapping-only — reserved kind value; no surfaces. | **Transport substrate exists** — `tom_core_server` `messaging`: `TomMessage` (channel-neutral), `TomMessageTransport` / `TomMessageRouter`, `TomSmtpTransport` with secret-marked CE-CF credentials, and `TomMessageOutbox` (durable queue on the CE-JB scheduler). Stand-in transports make a spec naming `email` runnable without a mail server. **Remaining gap for promotion:** the notification *model* — notification type ⇄ channel ⇄ user preference — which `tom_core` does not have. | Future `@CsNotification`; message templates keyed via CE-TX (`CsMessageKey`). |
| **CE-LG** AuditLog *(deferred, §4.3 — promotion criterion met)* | Business-relevant audit trail — **distinct from diagnostic logging**; SOM home SAS (D08). | Mapping-only — reserved kind value; no `Cs*` surfaces yet. Kernel logging is diagnostic, not audit. | **Audit-hook gap CLOSED (`csex9`)** — `tom_core_server`'s `audit` module (`TomAuditTrail` / `TomAuditRecord` / `TomAudited` / `TomAuditSink`; `doc/audit.md`) writes at both chokepoints: the CE-API pipeline (`TomEndpointHandler` — denials automatic, declared invocations via `@TomAudited`) and the CE-DB write path (`TomSqlDatasourceRepository` — every mutation automatic). A concrete built-on class now exists, so `csra7` can decide CE-LG **on the merits**. | Future `@CsAudited` modifier on `@CsEndpoint` / repository writes — a spec-level alias over the existing `@TomAudited` (`enabled` / `includeReads` / `redact`). |

**Readiness classification** (derived from the gap columns):

- **READY — pure reuse, no core gap:** CE-EL, CE-FM, CE-VA, CE-AC, CE-SC,
  CE-API, CE-SU, CE-ST, CE-ER, CE-CF, CE-CC, CE-DS, CE-ID, CE-AZ, **CE-DB**
  (aggregation grammar shipped), **CE-AU** (two-pass 2FA complete), **CE-MG**
  (schema-diff convergence shipped). No active part is waiting on a `tom_core`
  capability — the NEEDS-EXTENSION class is empty.
- **READY VIA `tom_core_codespecs` — the part reuses `tom_core` plus one
  concrete gap class:** CE-LO (`layout_node.dart`), CE-TX (`message_key.dart`),
  CE-NV (`route_flow.dart`), CE-UP (`user_settings.dart`), CE-CL
  (`client_application.dart`), CE-JB (`job_declaration.dart`). The gap classes
  carry only what `tom_core` has no place for; everything below them is reuse.
  One item is still open inside this class: CE-LO's container-kind
  reconciliation against the ACL substrate (`csexb2`).
- **Deferred:** CE-RP — one blocker left, the tabular result envelope. **CE-WF, CE-LG and
  CE-NT are deferred-but-decidable.** CE-WF's substrate survey is recorded in
  **§4.3.1** and **recommends permanent deferral** — no built-on class is
  proposed, deliberately, because DEPRWO authors no executable process and no
  driving system needs one; the survey is the input `csra7` was missing. For the
  other two, the blocking substrate gaps are closed —
  `csex9` gave CE-LG the `tom_core_server` `audit` module, `csex10` gave CE-NT
  the `messaging` module (transport, SMTP, durable outbox) — so the §4.3
  promotion criterion is satisfied for both and `csra7` decides them on the
  merits rather than on availability. CE-NT's *remaining* gap is the
  notification model above the transport, not the transport itself.
- **Naming discrepancies:** resolved and tabulated in **§4.1.2**; all are
  document defects, none needed a framework change, and all are now corrected
  at their cited locations.

These classifications are sequenced along the **generation slices** of §4.4,
which fixes the slice order, the per-slice readiness gate and the blocking mode
(emission / runtime / verification) of each gap.

#### 4.1.2 Built-on resolution + closed-catalogue verification

Every `tom_core`-family symbol this document names is **resolved against the real
sources** of the five built-on packages (`tom_core_kernel`, `tom_core_flutter`,
`tom_core_server`, `tom_core_d4rt`, `tom_flutter_ui`) — the pillar-(b) claim that
every class a CodeSpec instantiates is a shipped framework class is only worth
what its symbols actually resolve to. The sweep collects every `class` / `enum` /
`mixin` / `extension` / `typedef` declaration in those packages' `lib/` trees and
matches it against the backticked type names in this document.

**Resolution result — 127 named types:**

| Outcome | Count | Meaning |
|---------|-------|---------|
| Declared in one of the five built-on packages | 120 | Direct — the built-on claim holds verbatim |
| Declared in `tom_basics` / `tom_crypto`, **re-exported** by the kernel barrel | 3 | `TomRuntime`, `TomClientJwtToken`, `TomServerJwtToken` — see the re-export ruling below |
| Declared in `tom_core_codespecs` | 1 | `TomUserSettings` — correct: the CE-UP gap class's own home (§1.1) |
| Not declared anywhere — **document drift** | 3 | `AdvancedContainerLike`, `MariadbDatabaseMigrator`, `TomButton` — corrected below |

**Re-export ruling.** `tom_core_kernel.dart` re-exports `package:tom_basics` and
`package:tom_crypto` wholesale (barrel lines 6–7). A CodeSpec that names
`TomRuntime` or `TomClientJwtToken` therefore imports **only**
`tom_core_kernel` — the symbol arrives through the kernel's public surface. So
pillar (b)'s legitimate built-on surface is **the five packages *plus* whatever
they re-export**, and these three names are conformant, not drift. What they are
*not* is kernel-declared: any change to them is a change to `tom_basics` /
`tom_crypto` and must be scoped there.

**Naming discrepancies — document name → real API.** Each is a documentation
defect (the shipped API is correct); none requires a framework change. All rows
are **already corrected at the cited locations** — this table is the audit
record of what the name used to be, kept so a reader of older generated output
can trace it.

| Document location | Document name | Real API | Note |
|-------------------|---------------|----------|------|
| §1 (l. 53), §4 part table, §4.1.1 CE-LO | `AdvancedContainerLike` | `AclContainer` / `AclRow` / `AclComponent` (`tom_flutter_ui/src/advanced_container_layout/acl_container.dart`) | No such Dart class — the name is the layout *concept*, not a type. Cite the `Acl*` family. |
| §4 part table, §4.1.1 CE-MG, §5.27 | `MariadbDatabaseMigrator` | `MariadbMigrationAdaptor` (`tom_core_server/src/tomserver/db_migration/mariadb_migration_adapter.dart:36`, `implements TomDbMigrator`) | Plain rename. |
| §5.18 catalogue, §5.7.1 widget table | `TomButton` | `TomButtonBase` (`widget_base/tom_family_base.dart:35`) + the concrete variants (`TomElevatedButton`, `TomFilledButton`, `TomTextButton`, `TomOutlinedButton`, `TomIconButton`, …) and the `variant` tokens in `TomButtonVariants` (`theme/tom_style_variants.dart:17`) | There is no single `TomButton`; Button's `variant` per-kind attribute selects the concrete class. |
| §5.18 field-base table | `TomField.initialValue` | Constructor-positional `_initialValue` (`forms/tom_form.dart:596`) — **no public getter** | The attribute is authorable, but the framework exposes no read-back. |
| §5.18 TextInput per-kind row | `obscured` | `TomTextField.obscureText` (`widgets/inputs/tom_inputs.dart:29`) | Plain rename. |
| §5.26 | `checkAccess` | `TomAccessControl.checkAccessibility(TomPrincipal?)` + `resolveAuthState` | The name is **not** drift everywhere it appears: `TomEndpointHandler.checkAccess` (`tom_core_server`, `endpoint_pipeline.dart`) is a genuine, distinct pipeline method, and §5.6.3 / §5.15 refer to it correctly. §5.26 alone used it for the kernel evaluation. |

**Closed-catalogue verification.** The four closed catalogues are checked
entry-by-entry against the real member surface — a closed catalogue is
enforceable only if every entry has a carrier.

- **§5.19 CE-VA — 10 rules: fully carried.** `required`, `email`, `minLength`,
  `maxLength`, `pattern`, `min`, `max`, `minItems`, `maxItems`, `compose` all
  exist on `Validators` (`forms/validation/validators.dart`), and all four
  registry entry points (`resolve`, `resolveOrThrow`, `resolveSpec`,
  `resolveDeclaration`) plus `parseSpec` exist on `TomValidatorRegistry`.
  **Clarification:** `compose` is **not a declarable token** —
  `_registerBuiltins()` registers nine names, and composition is the implicit
  semantics of the comma list (`'required, minLength:8'` *is* a compose). Specs
  must not write `compose:…` in a declaration string.
- **§5.15 CE-AZ — 6 requirement kinds: fully carried.** `TomRoleAccess`,
  `TomGroupAccess`, `TomEntitlementAccess`, `TomResourceKeyAccess`,
  `TomCustomAccess`, `TomGradedAccess` all exist in
  `tombase/security/access_controls.dart` at the line numbers §5.15 already
  cites, as do the four presets. No drift remains.
- **§5.22 CE-LO — id addressing carried, container kinds not.** The 5-op delta
  grammar needs stable node ids, and the ACL substrate has **native string
  id-addressing**: `AclComponent.id` (l. 174), `AclRow.id` (l. 290),
  `AclContainer.aclId` + `parentIdPath` + `idScope`; every slot hint the grammar
  sets (`preferredSize`/`minimumSize`/`maximumSize`, `alignXToKey`/`alignYToKey`
  + axis points and gaps, `group`) is a public final. The delta grammar is
  therefore realisable over the shipped substrate. **However** §5.22's closed
  container-kind set {row, column, wrap, stack, flex, grid, padding, align,
  sizedBox} exceeds what ACL can express: an `AclContainer` is an ordered list
  of `AclRow`s (so *row* = `AclRow`, *column* = the row list) and
  `AclContainer.direction` is `AclDirection.ltr`/`rtl` — **text** direction, not
  a main-axis switch. *padding* / *align* / *sizedBox* are expressible as
  container/slot properties rather than node kinds; *wrap*, *stack*, *flex* and
  *grid* have no ACL node kind at all. See `csexb2`.
- **§5.18 CE-EL — 10 kinds and all per-kind attributes carried.** Every kind
  resolves to a shipped widget/field and every base attribute has a carrier
  (`tomId`, `validators`, `authorizer`, `autoValidate`, `form`). The three
  attributes that once had none were carried by `csexb1`: **`tristate`** by the
  nullable field family `TomFormNullableBoolField` (`TomField<bool?>`, where
  `null` *is* the third state) with the Material `TomFormNullableBoolCheckbox`
  and Cupertino `TomCupertinoFormNullableBoolToggle` concretes reachable through
  `FormFieldFamily.nullableBoolToggle`; and **`minSelections` / `maxSelections`**
  by the `Validators.minItems` / `Validators.maxItems` field rules registered in
  `TomValidatorRegistry` (the §5.18 desugaring boundary — a selection bound is a
  CE-VA rule, not a widget-level cap).

**Consequence for §4.1.1.** CE-EL is **READY**: the catalogue maps 1:1 onto
shipped widgets and every declared per-kind attribute is realisable, so no spec
detail is dropped in rendering. CE-VA and CE-AZ keep their classifications —
CE-VA's catalogue grew from eight rules to ten to absorb the selection bounds.
CE-LO stays MISSING with a second, substrate-level item (`csexb2`) alongside the
node-model gap class.

### 4.2 CodeSpecs output structure — three generated projects + implementation

The generated/derived CodeSpecs code is **split by deployment locus** into three
projects, per the multi-project architecture principle (§12):

| Generated project | Holds | Parts |
|-------------------|-------|-------|
| **`<app>_codespec_shared`** | The contract both sides depend on | CE-API request/response types **and the operation-ref catalogue**, CE-ER error result **+ error-code catalogue**, domain enums referenced by shared contract types, CE-TX message keys, shared CE-VA rules, **CE-AZ role + resource-key catalogues** (§5.23 — cited from both sides), CE-AU reused kernel wire/token types, CE-ID identity-extension declarations |
| **`<app>_codespec_client`** | Client-only CodeSpecs | CE-EL, CE-FM, CE-LO, CE-TX (copy), CE-AC, CE-SC, CE-ST, CE-NV (routes + screen-flow), CE-CL, CE-CC, CE-DS, CE-UP (client shape), CE-AU (client flow) |
| **`<app>_codespec_server`** | Server-only CodeSpecs | CE-SU, CE-DB, CE-API (handlers), CE-AZ, CE-CF, CE-UP (persistence), CE-AU (server flow), CE-ID attribute population (in the CE-AU flow), CE-MG (the migrations directory tree + numbered SQL skeleton artifacts — file assets shipped with the server project, not Dart classes, §5.27), CE-JB job definitions + work-body skeletons (§5.29) |

The **Phase-5/6 implementation** fills the skeletons in parallel projects that
depend on the generated ones:

| Implementation project | Depends on | Created in |
|------------------------|-----------|-----------|
| **`<app>_shared`** | `<app>_codespec_shared` | Phase 5 (potentially) |
| **`<app>_client`** | `<app>_codespec_client` + `<app>_shared` | Phase 6 |
| **`<app>_server`** | `<app>_codespec_server` + `<app>_shared` | Phase 6 |

The generation-projection `@Document` (`D13CodeSpecsProjection`) targets this
three-way split — each SOM section's parts route to the shared / client / server
project by the **Locus** column of §4.

### 4.3 Deferred element candidates (mapping-only)

Four further elements are **candidates** beyond the 23 active parts.
They are real system concerns a CodeSpec will eventually cover, but the first
CodeSpecs implementation stays grounded in the 23 active parts and the five
`tom_core`-family packages. Each is **reserved for mapping only**: it gets a
stable `CE-*` key and a reserved `CodeSpecPart` value so its SOM section can carry
`@CodeSpecKind` **immediately**, and its likely SOM home is recorded so the section is
authored (or added) in the right place. It has **no `Cs*` annotation, no built-on
`tom_core` class and no generated code** until promoted into §4.1.

| CE | Canonical id | `@CodeSpecKind` value | SOM home section (`@SectionId`) — file | What it will model |
|----|--------------|-----------------------|-----------------|--------------------|
| **CE-RP** | Reporting | `reporting` | `ReportEntry` (`REPENT`) — `experience_and_interface_design.dart` (D09 XDS) | **Reporting — deferred, worked out in a separate specification** (§5.28). A report is *"just another part of the UI specified differently"*: it is authored as part of DocSpecs and maps to a **UI to display and interact** with the result + a **server API** to fetch it + **graphs/charts**. Genuinely complex (query, projection, tabular + chart output, filters/parameters, delivery, scheduling), so it is deferred to its own spec rather than forced into the first CodeSpecs pass. |
| **CE-WF** | Workflow | `workflow` | `DetailedProcessWorkflow` (`DEPRWO`, in `TargetBusinessProcessModel`) + `BusinessProcessEntry` — `business_process_model.dart` (D02 TOM) | Multi-step process / **workflow-engine** orchestration (state machines, long-running processes). **Recommended for permanent deferral** — the substrate survey is recorded in §4.3.1: DEPRWO is free text (an activity narrative plus a BPMN-style diagram), no driving system needs a durable wait or compensation, and what a process does need is already served by CE-JB jobs, CE-AC actions and CE-DB state. Basic workflows remain covered by CE-NV (the screen-flow). |
| **CE-NT** | Notification | `notification` | `NotificationModel` (`NM`, with `NotificationChannelEntry` / `NotificationTypeEntry` / `UserNotificationPreferences`) — `introduction_and_scope.dart`; the infrastructure choice additionally appears as `services.notificationService` in the `CSIS` managed-services catalog — `architecture_and_technology.dart` (D06 ATS) | Outbound communications (email / push / SMS / webhooks) as a first-class effect. Part of the user-interaction, background-job, auditing and operations specs; **not mapped to CodeSpecs** except as **doc-comments on the abstract service methods** that emit them — postponed to the implementation phase. |
| **CE-LG** | AuditLog | `auditLog` | `AuditAndLogging` (`13234`) + `SecurityEventLoggingPolicy` + `AuditLogFormat` — `security_and_access_model.dart` (D08 SAS) | Logging & audit trail — who did what, when. **Must be in the spec**, woven into the functionality descriptions rather than declared standalone (it is not doable purely declaratively); some aspects overlap with CE-RP reporting. **The `tom_core` audit-logging hooks now exist** — `tom_core_server`'s `audit` module records at the endpoint and repository chokepoints, with the declared-versus-automatic split documented in its `doc/audit.md`. What the spec still owns is the *declared* half: which endpoint invocations and which reads are auditable, and which fields are redacted. |

**Homes are wired.** Each home section above already carries a **class-level**
`@CodeSpecKind([CodeSpecPart.<kind>])` — mapping-only, with no CodeSpecs
counterpart. Where a candidate's concern shows up in more than one place, the
annotation attaches to the section that best represents the *element* itself, not
to every section that mentions it: for CE-NT that is `NotificationModel` (the
domain/UX modelling), **not** the `CSIS` managed-services catalog entry (which
names only the infrastructure choice).

**Promotion criterion.** A deferred candidate becomes an active §4.1 part when a
concrete `tom_core`-family built-on class (or a decided `tom_core_codespecs` gap)
and a `Cs*` annotation are chosen for it. Until then its only surface is the
reserved kind value and the SOM `@CodeSpecKind`.

#### 4.3.1 CE-WF — workflow substrate survey and recommendation

CE-WF is the deferred candidate with the largest distance from the framework:
it is the only one whose promotion would require a runtime `tom_core` does not
have in any form. This subsection records the substrate survey and its outcome
so `csra7` can decide CE-WF **on the merits** rather than on availability — the
same standing CE-LG and CE-NT reached once their substrate gaps closed.

**Recommendation: permanently defer.** No process/workflow runtime should be
built, and **no built-on class is proposed** — so the §4.3 promotion criterion is
deliberately left unmet. The reasoning is below; the conditions that would
reverse it are at the end.

**1 — What the SOM actually asks for.** CE-WF's home is
`DetailedProcessWorkflow` (`DEPRWO`) in `business_process_model.dart` (D02 TOM).
It is a **single free-text `String? content` section**. Its `@ContentHelp` asks
for an activity list with inputs/outputs, decision points with branch conditions,
handoffs, per-step timing and SLAs, exception branches — and *"a BPMN-style
diagram per process"*. `ProcessExceptionHandling` (`PREXHA`) is likewise one free
text field. The structured sections around them (`ProcessCharacteristics`,
`ProcessExceptions`) are `@Form` blocks of **descriptive `String` fields**:
`automationLevel`, `straightThroughRate`, `exceptionRate`,
`exceptionPhilosophy`, `exceptionRouting`, `resolutionSla`, `escalationPath`.

Nothing in D02 carries a step identity, a transition guard, a machine-readable
wait condition or a compensation binding. There is **no authored artefact a
generator could read**. A promoted CE-WF would have to invent its own input,
which inverts the direction CodeSpecs works in (§8.1: the CodeSpecs surface is
bounded by what the SOM authors). D02 describes processes *for humans to
implement*; it does not declare them for a machine to execute.

**2 — What the driving systems ask for.** The requirement was taken from the
systems that would consume CE-WF, not from a workflow-engine feature catalogue.
`tom_sqm`'s longest-lived concern — payment failure — is specified as a
*configurable retry schedule*, which is a CE-JB job. `tom_provisioning`
delegates dependency ordering and rollback to the cloud provider's own engine
(Terraform / CloudFormation) rather than orchestrating them itself.
`tom_worktracker` advances a status column through direct service calls.
`tom_assistant`'s procedure engine is synchronous and in-memory. Across those
quests, **no document names a durable wait, a human-approval resume, a
compensating transaction or a timer-driven continuation**.

**3 — What the existing substrate already covers.** The parts a long-running
process is usually decomposed into are active and shipped:

| Need | Covered by |
|------|-----------|
| Deferred / recurring step execution | CE-JB — `TomJobDefinition` + `TomScheduler` over `TomJobStore` (`tom_core_kernel`, `tombase/scheduling/`) |
| Durable step state across a restart | `TomJobRun` (`id` stable across restarts, `scheduledFor` as the idempotence key, a JSON-round-trippable `payload`) and CE-DB columns for business state |
| Retry / backoff / permanent failure | `TomRetryPolicy` + the `TomPermanentFailure` mixin |
| Single-fire across a cluster | the `TomLeaseLock` family (fencing tokens) |
| Step-level effects and hand-offs | CE-AC actions, CE-EP operations, `TomMessageOutbox` (`tom_core_server` `messaging`) |
| Who-did-what across a process | CE-LG — the `audit` module's endpoint + repository chokepoints |

`TomMessageOutbox` is the existence proof: durable, retried, multi-attempt
outbound work carried entirely on `TomJobStore` + `TomRetryPolicy`, with no
process engine anywhere. A process expressed as CE-AC actions and CE-EP
operations, whose deferred continuations are CE-JB jobs and whose state lives in
CE-DB columns, is served by parts that are **already active**.

**4 — The one genuine gap, and its size.** The `TomSchedule` family ships cron,
calendar, interval and event triggers but no **one-shot absolute deadline**
("fire once at a given instant, then never") — so a timer wait is the single
workflow primitive with no direct expression today. It is not an architectural
hole: `TomSchedule` is a pure `DateTime? nextFireAfter(DateTime from)` in which
`null` already means *"never again"*, so a one-shot schedule is a small subclass
**inside the existing contract**. That the missing piece is this small is itself
an argument against the engine — the capability a workflow runtime is usually
reached for is, here, one class. It is tracked separately as tom_core `csexb6`
because it belongs to CE-JB's schedule family, not to CE-WF.

**5 — The build being declined, costed honestly.** For the record, promotion
would need a gap-class family no existing `tom_core` class can stand in for: a
**process definition** (named steps, guarded transitions), a **durable process
instance** (current step, variables, history) surviving restart on CE-DB, three
**wait kinds** (event / timer / human task) with resume, **per-step failure
semantics** (retry / compensate / halt) and therefore compensation registration,
and an **operations surface** (in-flight instances, stuck instances, manual
intervention). Estimate: on the order of **3–4 focused weeks** for runtime,
persistence, adapters and tests in `tom_core_server`. The larger cost is
permanent, not one-off: **versioning process definitions against in-flight
instances** — a deployed change must decide, for every instance mid-flight,
whether it continues on the old definition or migrates — is a maintenance
surface that never closes. `TomTransactionManager` does not reduce it; it is
in-process two-phase and does **not** resume after a restart. Set against zero
driving requirements, that is the wrong trade.

**6 — Execution guarantee, recorded now so it is not re-litigated.** Were CE-WF
ever built, its step dispatch would ride the CE-JB scheduler and therefore
inherit its guarantee: **at-least-once dispatch, with idempotent step bodies as
the default contract**. A step body must be safe to run twice — after a crash
between "step ran" and "step recorded", the step runs again. Exactly-once is not
offered and must not be implied by a process notation that looks sequential.
Any future CE-WF annotation surface has to make that visible at the step, not
bury it.

**7 — What would reopen the decision.** Promote CE-WF only when **all three**
hold:

1. a driving system specifies a process with a **durable wait** — human approval
   or timer — whose state must survive a server restart;
2. DEPRWO (or a successor section) is given a **machine-readable step/transition
   shape**, so a generator has an authored input instead of prose and a diagram;
3. that process needs **compensation across steps** that the CE-DB transaction
   boundary cannot cover.

Until then CE-WF stays mapping-only: the reserved `CodeSpecPart.workflow` value
and the SOM `@CodeSpecKind` on `DetailedProcessWorkflow`.

### 4.4 Generation slices — the per-slice `tom_core` capability contract

A **generation slice** is a set of parts emitted together into the §4.2 projects.
This section fixes **which slices exist, in which order, and what each one needs
from `tom_core` before it can be emitted**. It answers only that question: *what
must already exist for the emitted code to compile*. It does **not** say what
code comes out of a given SOM section — the per-annotation SOM→Dart derivation
contract is a separate, tom_specs-owned concern.

#### 4.4.1 The authored reference graph

Slice order is derived from the **authored** cross-part reference edges — the
§5.23 `Cs*Ref` const citations, the `Type`-literal citations, and the
containment/binding edges the §5.x sections fix. **Derived** back-references
(§5.10/§5.18 element→action hooks; §5.17 CE-SU owned-entity/operation sets) are
computed by the generator from the authored edge and impose no ordering of their
own beyond the authored direction.

| Referrer | Referent | Edge | Source |
|----------|----------|------|--------|
| CE-DB column `authKey` | CE-AZ resource-key catalogue | `CsResourceKeyRef` | §5.13, §5.15 |
| CE-DB, CE-API DTO, CE-ST, CE-CF/CC/DS/UP members | domain enums | Dart `enum` type | §4.1 |
| CE-API operation | CE-ER envelope · CE-AZ · CE-TX description | `Result<T>` · `@CsAuthorize` · `CsMessageKey` | §5.14, §5.6.3 |
| CE-ER code | CE-TX message key | `CsMessageKey` on `@CsError` | §4.1.1 CE-ER |
| CE-TX error-copy entry | CE-ER code | `CsErrorCode` | §5.21, §5.23 |
| CE-VA rule failure | CE-TX · CE-ER | `CsMessageKey` / `CsErrorCode` | §5.9, §5.19 |
| CE-SU | CE-DB entities/repos · CE-API operations | `Type` literals · `CsOperationRef` | §5.17 |
| CE-SC | CE-API operation | `CsOperationRef` (hop 2) | §5.3, §5.14 |
| CE-SC | CE-ST · CE-FM (request assembly) | field-source mapping | §5.3 attr 2 |
| CE-SC | CE-ST · CE-NV (response handling) | view-model update · `CsRouteRef` | §5.3 attr 3 |
| CE-AC | CE-SC | `CsCallRef` (hop 1) | §5.3, §5.23 |
| CE-AC | CE-NV | `CsRouteRef` (navigation outcome) | §5.11, §5.23 |
| `@CsTrigger` (CE-AC) | CE-EL | source-element ref (the join's other endpoint) | §5.10 |
| CE-NV `@CsScreenFlow` | CE-AC · CE-FM | `CsActionRef` · form→screen assignment | §5.11 |
| CE-FM | CE-ST · CE-SC/CE-AC · CE-VA · CE-EL | view-model link · submit target `CsCallRef`/`CsActionRef` · `@CsValidation` · field members | §4.1.1 CE-FM, §5.7.2 |
| CE-EL kind *FormHost* | CE-FM | hosted-form ref | §4.1.1 CE-EL, §5.18 |
| CE-ST | CE-EL · CE-FM | binding target (reference-by-id) | §5.4 attr 3 |
| CE-LO slot node | CE-EL · CE-FM | reference-by-id | §5.2, §5.12 |
| CE-CL | CE-NV · CE-FM | `CsRouteRef` · included forms | §4.1.1 CE-CL |
| CE-UP | CE-FM | settings-form link | §4.1.1 CE-UP |
| CE-AU | CE-ID · CE-CF | consumes the extension declaration · key material | §5.24, §5.25 |
| CE-JB | CE-DB · CE-SU (· CE-RP) | `Type` literals · ownership (· `CsReportRef`) | §5.29 |
| CE-MG | CE-DB | schema-convergence check (validator, not a citation) | §5.27 |

**Three genuine cycles.** The graph is **not** a DAG at part granularity:

1. **CE-ER ↔ CE-TX** — an error code carries its message key; the message-key
   registry's error-copy entries carry the error code. Both shared.
2. **CE-AC → CE-SC → CE-NV → CE-AC** — an action names the call it issues, the
   call names the route its response navigates to, the screen flow names the
   action that triggers the transition. All client.
3. **CE-ST ↔ CE-FM and CE-EL ↔ CE-FM** — the view-model binds to form fields
   while the form links its bound view-model type; a *FormHost* element names
   the form it hosts while the form's members are elements. All client.

Because CE-AC, CE-SC and CE-NV already share cycle 2, and CE-FM reaches CE-SC
and CE-AC (submit target) while CE-NV reaches CE-FM (screen assignment), cycles
2 and 3 merge. The **strongly connected components** of the authored graph are
therefore:

- **SCC-A = {CE-ER, CE-TX message keys}** — shared;
- **SCC-B = {CE-ST, CE-EL, CE-FM, CE-AC, CE-SC, CE-NV}** — client;
- every other part is its own singleton component.

**Validated property: no SCC spans two §4.2 projects.** This matters, because the
two constraints have different force. Dart permits **circular imports between
libraries of the same package**, so an SCC co-emitted into one project compiles;
Dart forbids **circular dependencies between packages**, so a cycle crossing the
shared/client/server boundary would be unresolvable. The §4.2 split is
reference-cycle-safe, and the *shared → {client, server}* arrow is an absolute
constraint no slice order may bend.

#### 4.4.2 The forward-reference rule

**Decision: strict ordering, with slice boundaries cut at SCC boundaries.**
Declared-but-unimplemented stubs are **rejected**.

- **Why not stubs.** A stub would author the same referenceable identity twice —
  once as a placeholder in the earlier slice, once for real in its owning part —
  which breaks the "declare once, cite everywhere" invariant that §5.23 and §5.3
  make load-bearing. Worse, a stub `CsRouteRef` is type-identical to a real one,
  so the **compiler — the designated §4.2 cross-part integrity checker (§5.23) —
  could no longer distinguish a satisfied reference from an unsatisfied one**.
  Stubs would disable the exact mechanism the typed-ref family exists to provide.
- **Why strict ordering alone is not enough.** At part granularity the graph has
  the three cycles above, so no linear order over the 23 parts exists. Ordering
  parts is impossible; ordering *components* is not.
- **The rule.** The slice **is** the strongly connected component (or a union of
  components at the same topological rank, grouped for readability). Slice order
  is a topological order of the graph's condensation. **Within** a slice, mutual
  reference is legal and expected. **Across** slices the rule is absolute: *no
  slice may reference a symbol a later slice emits* — achievable by construction,
  because every backward edge has been absorbed into a component.

**Slice order is a hard constraint, not a preference.** Two independent
mechanisms enforce it: within a project, a cross-slice backward reference is a
Dart compile error at the citing const (§5.23); across projects, it is an
unresolvable package cycle. Neither is recoverable by generation order, so a
slice order that violates the rule cannot be made to work by emitting more
carefully — it must be re-cut.

**Corollary — a part may be split across slices, an SCC may not.** Where §4.2
already splits a part by locus (CE-API contract vs handlers, CE-TX keys vs copy,
CE-AZ catalogue vs modifier applications, CE-AU shared/client/server, CE-UP
client shape vs server persistence, CE-ID declaration vs population), the halves
are separate emission units and sit in different slices. This is what keeps
SCC-A and SCC-B single-project.

**Generation order is not runtime bootstrap order.** This section orders
*symbol availability at compile time*. The runtime start-up order (CE-CF resolved
before the server boots, CE-MG applied before the first repository call, CE-AU
establishing a principal before any CE-AZ evaluation) is a different sequence and
is not constrained here.

#### 4.4.3 The ordered slices

Seven slices. "Built on" names the `tom_core`-family classes the slice's parts
instantiate or extend (§4.1); "Gate" is §4.4.4.

| # | Slice | Parts emitted | Project (§4.2) | Built on (`tom_core`-family) |
|---|-------|---------------|----------------|------------------------------|
| **1** | **Shared const catalogues** | domain enums (`@CsEnum`); CE-AZ role + resource-key catalogues; **SCC-A** = CE-ER error codes + CE-TX message keys | `<app>_codespec_shared` | `TomResult<T>` / `TomErrorResult` / `TomFieldError` / `TomErrorSeverity`, `TomTextResourceProvider` (`tom_core_kernel`); plain Dart `enum`s. The role/resource-key catalogues are plain const holders over `TomRoleAccess.roles` / `TomResourceKeyAccess.key` string spaces. |
| **2** | **Shared contract** | CE-API operation catalogue + request/response DTOs; shared CE-VA rules; CE-ID identity-extension declaration; CE-AU shared wire/token types | `<app>_codespec_shared` | `TomApi` / `TomApiEndpoint<R,Q>` / `TomRemoteApis` (`tom_core_kernel`); `Validator<T>` / `ValidationResult` / `Validators` / `FormValidationError` (`tom_flutter_ui`); `TomUser` / `TomPrincipal`, `TomBearerAuthentication` / `TomClientJwtToken` / `TomAuthenticationMessage` / `TomAuthenticationResult` (`tom_core_kernel`) |
| **3** | **Server persistence & configuration** | CE-DB entities/columns/repositories; CE-MG migration artifact tree; CE-CF | `<app>_codespec_server` | Tom persistence model + CRUD/MariaDB repositories + `TomQueryBuilder` (`tom_core_server`); `TomDbMigrations` / `TomDbMigrator` / `TomMigrationFileName` / `@TomDbMigrationAdaptor` / `MariadbMigrationAdaptor` (`tom_core_server`); `TomBaseServerConfiguration` + `TomServerConfigResourceProvider` (`tom_core_server`) |
| **4** | **Server behaviour** | CE-SU units **co-emitting** the CE-API handler methods; operation-level CE-AZ; CE-AU server flow + CE-ID attribute population | `<app>_codespec_server` | `@tomService` / `TomApiImplementation` / `TomEndpointHandler` / `TomEndpointRouting` / `TomServer` / `TomComponentReference` (`tom_core_server`); `TomAccessControl` family + `TomGradedAccess` + `TomPrincipal` (`tom_core_kernel`), `TomResourceGrant` / graded authorization (`tom_core_server`); `TomAuthenticationServer` + the app's `TomAuthenticationService`, `TomServerJwtToken` (`tom_core_server`) |
| **5** | **Client interaction core** | **SCC-B** = CE-ST + CE-EL + CE-FM + CE-AC + CE-SC + CE-NV; field-level CE-AZ (`authorizer`); CE-TX copy; CE-AU client login flow | `<app>_codespec_client` | `TomObservable` / `TomObject<T>` / `TomClass` / `TomList` / `TomMap` (`tom_core_kernel`) + `TomObservingWidget` / `ValueListenableObserver` (`tom_core_flutter`); `TomScreenElementsProvider` + the `Tom*` element/widget family, `TomForm<T>` / `TomFormChildContainer` / `TomField<T>`, `TomAction` / `TomActionController` / `TomActionTrigger` / `TomActionTransaction` / `TomActionContext`, `TomPageRoute<T>` / `TomNavigationDestination`, `TomText` / `TomLabelBase`, `TomGradedAccess` (`tom_flutter_ui`); `TomServerEndpoint<T,R>` / `TomServerCallSpecs` / `TomServerChannel` (`tom_core_kernel`) |
| **6** | **Client presentation & shell** | CE-LO; CE-CL; CE-CC; CE-DS; CE-UP client shape | `<app>_codespec_client` | `AclContainer` / `AclRow` / `AclComponent` (`tom_flutter_ui`) rendered via `TomObservingWidget` (`tom_core_flutter`); `TomBaseClientConfiguration` / `TomSetting<T>` / `TomClientConfigurationStore` + the `TomProperty<T>` family (`tom_core_flutter`) over `TomConfigResourceProvider` (`tom_core_kernel`); `TomGetSettingsMessage` / `TomGetSettingsResult` (`tom_core_kernel`). CE-CL has **no** `tom_core` basis by design (§4.1.1). |
| **7** | **Server operational** | CE-UP server-side persistence; CE-JB job definitions + work-body skeletons | `<app>_codespec_server` | `TomCommand` / `TomExecutor` / `TomWorker` isolate-pooling substrate (`tom_core_kernel`); the CE-DB repositories of slice 3 for the settings store |

**Why this order (the across-slice edges it satisfies).** 1 has no outbound part
edges at all — every `Cs*Ref` catalogue bottoms out here. 2 cites only 1. 3 cites
1 (enums, `CsResourceKeyRef`). 4 cites 1, 2, 3. 5 cites 1 and 2 **and never 3 or
4** — the client project depends on shared only. 6 cites 5 (and 1). 7 cites 3 and
4. Slices 5–6 and 3–4–7 are two independent chains hanging off 1–2; they may be
generated in either interleaving, but never before 2 completes.

#### 4.4.4 The slice readiness gate

**Gate (as stated).** A slice is generatable **iff every part it emits is READY**
in the §4.1.1 matrix. A slice containing a NEEDS-EXTENSION or MISSING part is
blocked and names the todo that unblocks it.

**Refinement — three blocking modes.** Applied literally the gate is too coarse
to act on, because the §4.1.1 gaps do not all block the same thing. Each gap is
therefore classified:

- **E — emission-blocking.** The skeleton cannot be written at all (no class to
  extend, no annotation to apply). The slice is hard-blocked.
- **E(lossy) — emission is possible but drops declared detail.** The slice
  generates; a spec using the uncarried attribute renders without it.
- **R — runtime-blocking.** The skeleton emits and compiles (often as `§3`
  pseudo-code / `UnsupportedError`); the capability is missing at execution time.
  The slice is generatable; the *application* is not yet runnable.
- **V — verification-blocking.** Emission and runtime are fine; a named validator
  check cannot run.

| # | Slice | Non-READY parts | Mode | Unblocked by |
|---|-------|-----------------|------|--------------|
| **1** | Shared const catalogues | CE-ER, CE-TX; CE-AZ catalogues | **E** | `csra6` (`CsErrorCode` / `CsMessageKey` / `CsRoleRef` / `CsResourceKeyRef` unimplemented) |
| **2** | Shared contract | CE-API, CE-VA, CE-ID | **E** | `csra6` (`CsOperationRef`) · `qr3` (`@CsFieldRule` / `@CsFormRule` unauthored) |
| **3** | Server persistence & configuration | — (CE-DB and CE-MG are READY: the aggregation grammar and the schema-diff engine both ship) | — | — |
| **4** | Server behaviour | CE-SU (`CsServiceUnitRef`) — CE-AU is READY, the two-pass 2FA flow is complete | **E** | `csra6` |
| **5** | Client interaction core | CE-SC/CE-AC/CE-FM ref types (CE-EL is READY — `csexb1` carried its last three per-kind attributes) | **E** | `csra6` (`CsRouteRef` / `CsCallRef` / `CsActionRef`) |
| **6** | Client presentation & shell | CE-LO (ACL container-kind reconciliation) · CE-CC (two holders standing) | **E** | `csexb2` (ACL substrate) · `csrb2` (retire or justify `TomClientConfiguration`) |
| **7** | Server operational | CE-JB (todo reconciliation only — the declaration envelope, scheduler runtime, job queue and multi-node lease have all **landed**) | — | `csrb1` (reconcile `csex7` / `csex8` against the landed scheduling module) |

**Critical-path consequence.** The `Cs*` annotation family and the
`tom_core_codespecs` gap classes have both landed, and **no slice is
runtime- or verification-blocked any more** — slice 3 is clear outright and
slice 4 keeps only an emission item. What remains is concentrated in **one**
tom_specs-owned item: `csra6`, the §5.23 `Cs*Ref` typed-reference family, which
alone gates slices 1, 2, 4 and 5. The only `tom_core`-side blocker left anywhere
is `csexb2` at slice 6, and it too is **E**. The implied sequence: typed refs
first (`csra6`), then the two standing ownership questions (`csrb1`, `csrb2`)
and the ACL substrate (`csexb2`).

#### 4.4.5 What the reference directions corrected

The slice spine was **not** adopted as proposed; four of its cuts do not survive
the authored edges.

| Proposed | Correction | Evidence |
|----------|-----------|----------|
| CE-DB in the **first** slice, with domain enums | CE-DB moves to slice **3** | A CE-DB column's `authKey` is a `CsResourceKeyRef` from the CE-AZ catalogue (§5.13, §5.15) — a backward reference. CE-DB is also server-locus, and a slice may not span shared + server (§4.2 arrows). |
| Three ordered client slices: *state and calls* → *UI* → *navigation and shell* | The six parts collapse into **one** slice (SCC-B) | Cycle 2 (CE-AC→CE-SC→CE-NV→CE-AC) and cycle 3 (CE-ST↔CE-FM, CE-EL↔CE-FM) admit no linear order. The proposed cut has CE-SC citing `CsRouteRef` two slices later (§5.3 attr 3) and CE-ST citing its CE-EL/CE-FM binding target one slice later (§5.4 attr 3). |
| **Auth/identity** (CE-AU, CE-ID) as a **late** slice, after the client | CE-ID and CE-AU's shared types move to slice **2**; CE-AU's server flow to **4**; its client login flow into **5** | CE-ID's locus is shared + server (§5.24) and CE-AU's shared wire/token types are shared (§4.2). A shared part emitted after a client slice inverts the §4.2 dependency arrow. Neither part cites anything client-side. |
| **Operational** (CE-MG, CE-JB) as one final slice | CE-MG moves to slice **3** beside CE-DB; only CE-JB (with CE-UP persistence) stays last | CE-MG's only relationship is the CE-DB schema-convergence check (§5.27); separating them by four slices defers the check for no reason. CE-JB genuinely depends on CE-DB and CE-SU (§5.29) and stays last. |

The spine's **broad direction** — shared vocabulary → shared contract → server →
client → shell → operational — is confirmed by the edges. What it got wrong is
the granularity: it assumed the client tier decomposes, and it placed two
shared-locus parts (CE-ID, CE-AU) and one server-locus part (CE-DB) by topic
rather than by locus.

## 5. Gap analysis — taxonomy vs existing coverage

Per part: the existing `tom_core`-family coverage and the design that covers the
part (detailed in the referenced §5.x subsections).

| Code | Existing coverage | Gap & design |
|------|-------------------|--------------|
| CE-EL | UI Elements; semantic + widget-behaviour layers | **Reuse — no new class.** Two-step **"semantic type → concrete widget"**: `@CsElement` (semantic, over `TomField<T>`) + `@CsWidget` (concrete widget binding, over the `TomButtonBase` variants / `TomText` / inputs) in the client project; covered by `TomScreenElementsProvider` + the existing `Tom*` `tom_flutter_ui` element/widget family + the form semantic classes — a documented catalogue over reused classes, **not** a `tom_core_codespecs` class (§5.7.1). Attribute surface + closed catalogue contents: **§5.18** (field base + 10-kind catalogue + semantic→widget two-step). |
| CE-FM | `TomForm`; annotated fields | **Subforms** (nested/repeated) mirror the SOM `@Form` field-group structure: `@CsForm` (reuse, no gap class) over `TomForm<T>` + `TomFormChildContainer` (nested/repeated subform fan-out) + `TomField<T>`; SOM `@Form` field-group → nested `TomForm` / repeated `TomFormChildContainer`; client project (§5.7.2). |
| CE-LO | Layout, separated for manual override | A **Flutter-faithful, override-separable layout-node** model: the §5.2 two-layer id-addressed node model grounded on the `tom_flutter_ui` ACL substrate — container node ← `AclRow`/`AclContainer`, slot node ← `AclComponent` (native `id`/`referenceKey`/alignment-by-key + per-slot hints), reactive rebind via `TomObservingWidget` (`tom_core_flutter`); the override-separable node model lands in `tom_core_codespecs`; client project (§5.12). Attribute surface + override-delta grammar: **§5.22** (closed container-kind + slot attribute sets + closed 5-op id-addressed override deltas). |
| CE-TX | Texts implied in UI/RC | Placeholder/help derived **directly from SOM content** (`@ContentHelp`, `@Form` hint, doc-comments); error texts keyed by CE-ER codes. `@CsText` (reuse) over `TomText`/`TomLabelBase` (field `labelText`/`hintText`/`descriptionText`, `resolveErrorMessage`) bound to `TomTextResourceProvider`/`TomConfigResourceProvider` (kernel i18n backend, dot-notation keys); the CodeSpecs-only **message / i18n-key model** lands in `tom_core_codespecs`; spans shared (message keys) + client (copy) projects (§5.8). Attribute surface + error-copy keying: **§5.21** (message-key attribute set + locale model + error copy keyed by CE-ER codes). |
| CE-VA | Rules-from-RC | **No new class — provided as Dart code** (§3 first-level-implementation latitude). **Field rules vs form (cross-field) rules**, each traceable to a requirement: `@CsValidation` umbrella + `@CsFieldRule` (single-field, over `Validator<T>`/`ValidationResult`) + `@CsFormRule` (cross-field, over `FormValidationError`); realised as **standalone validator classes with validation methods, or validation methods on the `TomForm` subclass**, reusing `Validators`/`TomValidatorRegistry` (`tom_flutter_ui`); `ValidationError.errorKey` ties error copy to CE-TX/CE-ER; spans client + shared projects (§5.9). Attribute surface + declaration language: **§5.19** (closed 10-rule field catalogue + `TomValidatorRegistry` declaration grammar + form-rule scope/reference/error-key). |
| CE-AC | UI Actions | **Reuse — no new class.** Actions have a full implementation in `tom_flutter_ui`. **Trigger taxonomy** — one action, several triggers: `@CsAction` (reuse) over `TomAction<Ctx,Undo>` + `TomActionContext`/`TomActionController`/`TomActionTransaction`; `@CsTrigger` names one invocation, with `TomActionTrigger` the widget-gesture realization; a triggered action drives the §5.3 CE-AC→CE-SC edge; client project (§5.10). Attribute surface: **§5.20** (action set + closed 5-kind trigger attribute surface: user-gesture / in-form event / lifecycle / server-event / condition). |
| CE-SC | Kernel transport (`TomServerEndpoint` client side) | Explicit **action → endpoint** edge; client request assembly / response handling: two-hop typed-reference chain CE-AC→CE-SC→CE-API (§5.23); `@CsServerCall` over `TomServerEndpoint<T,R>`/`TomServerCallSpecs`/`TomServerChannel` (client) (§5.3). Attribute surface: **§5.14**. |
| CE-API | Server Interface | Narrowed to the §7 contract (POST-only, operation-named, 50x-only, structured error); first-class operation name + typed request/response: `@CsEndpoint` (reuse+narrow) over `TomApi`/`TomApiEndpoint`/`TomRemoteApis` (kernel) + `TomEndpoint`/`TomEndpointHandler`/`TomEndpointRouting`/`TomServer` (server), narrowed to POST + operation-name + typed `T`/`R` + CE-ER Result envelope; server project (§5.6.1). Attribute surface: **§5.14**. |
| CE-SU | `@tomService` class marker (`tom_core_server`) | **No new class.** **Logical grouping of operations within one server** = a named cohesive set of operations + owned entities/repositories, ideally an independent **closure**: modelled as ordinary **(abstract) classes** carrying the `@tomService` / `TomApiImplementation` server-API mapping annotations (`@CsServiceUnit` first-class marker over the `@tomService`/`TomApiImplementation`/`TomComponentReference`/`scanClasses` grouping); boundary = §5.1 (owned-aggregate primary), id `<RootAggregate>Service`; server project (§5.6.2). Attribute surface: **§5.17** (authored id/root-aggregate/process-adjust/context vs derived entities/repos/operations). |
| CE-DB | Rich SOM `DataModel`/entities/attributes | The **access object model** (repositories/DAOs + query/filter/transaction per service unit): `@CsTable`/`@CsColumn`/`@CsRepository` over the `tom_core_server` persistence model; attribute surface in §5.13. **Placement: server-only** — the persisted entity lives only in `<app>_codespec_server`; the client sees CE-API request/response shapes (shared, the DTO role) + the CE-ST view-model (§5.4), never a DB entity (§5.13). |
| CE-ST | UI Data Model | Typed view-model state distinct from the DB model: `@CsViewModel` (reuse, no gap class) over `TomObservable`/`TomObject<T>`/`TomClass`/`TomList`/`TomMap` (`tom_core_kernel`) bound via `TomObservingWidget`/`ValueListenableObserver` (`tom_core_flutter`), client project; CE-ST↔CE-DB separation drawn (§5.4). |
| CE-NV | `TomPageRoute` + destinations; route uniqueness assumed by the substrate | Route identifiers + a **screen-flow model**: `@CsRoute` (reuse) over `TomPageRoute<T>` + the `tom_navigation` destination widgets (`TomNavigationDestination`, `tomId`/`authorizer`) for the route ids; `@CsScreenFlow` combines the interaction scenarios into **screens** — which **form** is assigned to which screen, whether it **replaces** the current screen or **overlays** it as a **popup**, and which CE-AC action triggers navigation with a **conditional** target (success → confirmation or back to the previous screen; error / validation-error → error display). The stable route-id + screen-flow model is a CodeSpecs-only class in `tom_core_codespecs`, authored from the SOM screen route map (`SCRTMP`, D09 XDS); client project (§5.11). |
| CE-AZ | Auth/authz spec type | Role/permission per operation from SOM `SecurityAccessSpecification`: `@CsAuthorize` (reuse, no gap class) — a **modifier** on `@CsEndpoint` carrying a `TomAccessControl` (role/group/entitlement/resource-key/custom/graded four-state), enforced by the pipeline's `checkAccess`; server project (§5.6.3). Attribute surface: **§5.15** (six `@OneOf`/`@Case` requirement kinds + attribute-less presets + graded four-state levels + field-level authKey). |
| CE-ER | `TomResult<T>` / `TomErrorResult` (`tom_core_kernel` `tombase/result/result.dart`, kernel 1.1.16) | The one canonical **success-or-error envelope** (§7): `@CsError` (reuse, no gap class) over `TomResult<T>` (success/failure arms, explicit `success` wire discriminator) + `TomErrorResult` (`code` — the CE-TX↔CE-ER join key — plus `message`, `fieldErrors`, `retryable`, `severity`) + `TomFieldError` + `TomErrorSeverity`; every CE-API operation returns it; shared project. |
| CE-CF | `TomBaseServerConfiguration` (`tom_core_server`) | **Server/system config only** — client-machine, device and user settings are CE-CC/CE-DS/CE-UP. `@CsServerConfig` (reuse, no gap class) over `TomBaseServerConfiguration`/`TomServerConfigResourceProvider` (`tom_core_server`), server project; one config-value concept realised as four owner-keyed parts (CE-CF/CE-CC/CE-DS/CE-UP) (§5.5). Attribute surface + precedence: **§5.16** (per-scope spec-authorable split + opt-in most-specific-owner-wins cross-scope precedence). |
| CE-CC | `TomBaseClientConfiguration` + `TomSetting<T>` (`tom_core_flutter`) | Model **per-machine client configuration** — settings scoped to the machine a client app runs on (endpoints, feature toggles, device options) (§5.16, §11). |
| CE-UP | `TomGetSettingsMessage`/`TomGetSettingsResult` round-trip (`tom_core_kernel`) | Model **user settings** — user-scoped, server-persisted preferences that follow the user (§11); the typed holder and the server-side per-user persistence are a `tom_core_codespecs` gap to specify. |
| CE-DS | `TomProperty<T>` family + settings holders (`tom_core`) | **Reuse — no new class.** Model **device settings** — user-specific settings of a user-owned device, persisted on the device and keyed by the signed-in user (§11); modelled with existing `tom_core` property/settings classes that are directly reusable. |
| CE-CL | — | Enumerate the **client applications** (Flutter app, CLI, other server) — each owns its CE-CC and hosts CE-DS/CE-UP; the descriptor class is a `tom_core_codespecs` gap to specify. |
| CE-AU | `TomAuthenticationServer` + `TomAuthenticationService` contract (`tom_core_server`); `TomBearerAuthentication`, `TomClientJwtToken`, `TomAuthenticationMessage`/`TomAuthenticationResult` (`tom_core_kernel`) | **Pure reuse — no gap class.** The mechanics (two-token JWT model, login orchestration, stateless Bearer verification, wire attachment, token store) are framework-fixed; the spec-authorable surface is the service binding, enabled methods/flows, per-client login flow, and session/token/credential policies. The app's `TomAuthenticationService` implementation **is** the `@CsAuth` CodeSpec (§5.25). |
| CE-ID | `TomUser` + `TomPrincipal` (`tom_core_kernel`); both token-payload extension carriers exist in the substrate (public `attributes`, encrypted context) | **Reuse — no new class.** **App-declared identity-attribute extensions** over the fixed principal core: `@CsIdentity` (declaration holder) + `@CsIdentityAttribute(placement: public\|encrypted)` per extension; the profile extension is modelled as an **ordinary class**, directly reusable and carried as **JSON via reflection** in the user profile; shared (declaration) + server (population in the CE-AU flow) (§5.24). |
| CE-MG | `TomDbMigrations` orchestrator + `TomDbMigrator` contract + `TomMigrationFileName` grammar + `@TomDbMigrationAdaptor` discovery + `MariadbMigrationAdaptor` (`tom_core_server`) | **Pure reuse — no gap class.** The engine (directory walk, filename grammar, numeric ordering, env filtering, applied-version verification) is framework-fixed; the spec-authorable surface is the SQL artifact set — initial DDL, base/seed data, iteration scripts — in the `<databaseMigrationsDirectory>/<datasource>/<schema>/` tree, `@CsMigration`-marked; the schema-convergence check against the CE-DB entity model is a named validator check (§5.27). |
| CE-RP | `TomQueryBuilder` typed `TomOperator` expression trees + `TomQuerySentenceCompiler` (find/count/delete sentences → `TomSelect`/`TomCount`) + the crud repositories + the SQL dialect layer (`tom_core_server`); delivery via ordinary CE-API endpoints | **Deferred (§4.3) — worked out in a separate specification.** A report is *"just another part of the UI specified differently"*: authored as part of DocSpecs, it maps to a **UI to display and interact** with the result + a **server API** to fetch it + **graphs/charts** (query/projection over the CE-DB substrate + output shape + filters/parameters + delivery + optional schedule). Too complex to force into the first CodeSpecs pass, so it carries only a reserved `CodeSpecPart.reporting` value until its own spec is written (§5.28). |
| CE-JB | `TomCommand` / `TomExecutor` / `TomWorker` isolate-pooling substrate (`tom_core_kernel`) — the work-body engine that runs a unit of work off the request thread | **Job definitions over the operational model**: `@CsJob` names a trigger (`cron \| calendar \| event`) + a work definition + target refs (CE-DB entities / CE-RP reports the job acts on) + retry/backoff/timeout/failure-alerting, distinct from request-driven CE-API. A **job base class** (`tom_core_codespecs` gap) makes job execution pluggable into any scheduling system; the **work body is compilable pseudo-code** (§3) calling a later-injected **abstract service class** whose methods carry detailed doc-comments; server project. The scheduler runtime, job queue and multi-node locking are reused from `tom_core_kernel`'s `scheduling` module — `tom_process_monitor` is reference only, not a `tom_core`-family class (§5.29). |

### 5.1 CE-SU service-unit boundary criterion

**Decision.** A service unit's boundary is **owned-aggregate primary, process-cohesion
secondary, bounded-context as the outer bound** — a three-level *precedence*, not
three competing options.

1. **Primary — owned aggregate (D03 IMO).** A `@CsServiceUnit` owns exactly one
   *aggregate*: a root entity plus the entities that have no independent lifecycle
   outside it. It owns every CE-DB table and repository over those entities and
   every CE-API operation whose **primary written entity** is in the aggregate.
2. **Secondary — process cohesion (D02 TOM).** Where two aggregates are always
   mutated inside one business transaction/process they may be **merged** into one
   unit; where one aggregate's operations divide into clearly independent processes
   the unit may be **split**. Process cohesion only *adjusts* the primary grouping.
3. **Outer bound — bounded context (D06 ATS).** A service unit never spans two
   architecture modules / bounded contexts. The context is the coarse container that
   caps any merge.

**Identification.** A unit's stable id is its root-aggregate name + `Service` (e.g.
`OrderService`, PascalCase). That id is the `@CsServiceUnit` identity and the
`<app>_codespec_server` grouping key (§4.2).

**Ownership & cross-unit access.** A unit owns {its aggregate entities (CE-DB),
their repositories (CE-DB), the operations that write them (CE-API + CE-AZ)}. A
read spanning units is assigned to the unit owning its **primary** entity; a unit
**never** reaches another unit's repository directly — cross-unit data flows through
the owning unit's CE-API. This keeps each unit's persistence private and makes the
boundary enforceable at generation time.

**SOM feed.** owned aggregate ← D03 IMO entity/aggregate structure · merges/splits
← D02 TOM process cohesion · module cap ← D06 ATS · operation inventory ← D07 IFS.
Join key is the SOM `@SectionId` (§8).

### 5.2 CE-LO layout-node representation

**Decision.** `@CsLayout` is a **two-layer, id-addressed tree**: a *generated base
layout* deterministically derived from the SOM, plus a separate *override layer* of
id-keyed deltas that survives regeneration.

**Node model.** The layout is a tree of `LayoutNode`s of two kinds:

- **Container node** — a Flutter-faithful layout primitive (`row`, `column`,
  `wrap`, `stack`, `flex`, `grid`, `padding`, `align`, `sizedBox`) carrying only
  *layout* properties (direction, main/cross-axis alignment, spacing, flex weights,
  padding, constraints) and an ordered list of children. It carries **no** semantics.
- **Slot node (leaf)** — a **reference by stable id** to the semantic element it
  positions: a CE-EL element id or a CE-FM (sub)form id. The slot holds only
  per-slot layout hints (flex, alignment). The element's definition and behaviour
  stay in CE-EL/CE-FM — the layout tree never embeds them. This is the clean
  semantics ↔ layout separation.

**Node identity.** Every node carries a **stable node id**: a slot id derives from
its referenced element/form id; container ids are stable synthetic ids preserved
across regeneration by structural matching.

**Override survival.** Two layers, never one hand-edited
tree:

1. **Generated base** — rebuilt from the SOM every build (default: a single
   `column` of the form's fields in SOM order). Never hand-edited.
2. **Override layer** — a separate, human-authored patch expressed as
   **id-addressed deltas** (reparent a slot, change a container's direction, set a
   flex, insert/remove a container), *not* a replacement tree. On regeneration the
   base is rebuilt and the deltas are re-applied by id. A **new** SOM element appears
   in the base and flows to its default slot until an override moves it; a delta
   whose target id **no longer exists** is surfaced as a reconcile warning, never
   silently dropped. Manual layout thus survives model changes non-destructively.

**SOM feed.** base structure ← D09 XDS screen/form layout (+ D05 ISC screen naming);
the override layer is authored, not derived. Join key = `@SectionId` (§8).

### 5.3 CE-SC server-call model + action→endpoint edge

**Decision.** CE-SC is the **client-side server call** an action issues. It is a
*reuse* part (no gap class): `@CsServerCall` is a thin annotation over the surveyed
kernel transport classes, and the action→endpoint coupling is an
**explicit two-hop reference edge**: CE-AC action → CE-SC server call → CE-API
operation. `@CsServerCall` lives in the **client** project (`<app>_codespec_client`,
§4.2); the operation contract it targets lives in the **shared** project (CE-API).

**Built on (client-side kernel transport).** `@CsServerCall` wraps the surveyed
`tom_core_kernel` classes (`server_connection.dart`) — the client half of the §7
contract:

| Surveyed class | Role for `@CsServerCall` |
|----------------|--------------------------|
| `TomServerEndpoint<T extends Object, R extends Object>` | The typed call itself: request type `T`, response type `R`, `send(T) → Future<(R, TomServerCallError?)>`. `T`/`R` are the CE-API operation's request/response DTOs (shared). |
| `TomServerCallSpecs` | The wire spec: `method` (**POST** per §7), `url` (the operation route), `headers`, `includeBearerAuthentication` (CE-AU token). One per call. |
| `TomServerChannel` | The transport channel (`prepareCall(specs)`), shared across calls to one server. |
| `TomServerCall` | The single prepared/in-flight call `channel.prepareCall(specs)` produces; not modelled directly — an implementation detail of `TomServerEndpoint.send`. |

The **transport identity** of a `@CsServerCall` is fully determined by
*(operation name → `TomServerCallSpecs` url + POST) + (request DTO `T`, response
DTO `R`) + (error → CE-ER)* — it adds **no** new transport type. The **call-site
surface** (request assembly, response handling, error surfacing, the trigger
edge, call options — attributes 2–5 below) is genuinely client-authored content
with no home in CE-API.

**Boundary (non-overlap rule).** **CE-API is the operation** — the contract
(operation name, typed request/response DTOs in the shared project, the CE-ER
envelope) plus the server handler; authored **once per operation** (shared +
server, §4.2). **CE-SC is a client call-site binding of an operation** —
authored **once per call site**; N call sites : 1 operation (client, §4.2). A
`@CsServerCall` may **never author or re-declare a contract member**
(operation-name semantics, `T`/`R` shapes, error codes) — it only *cites* them.
Anything both sides need is CE-API/shared; anything call-site-contextual is
CE-SC/client.

**Attribute surface (`@CsServerCall`).**

1. **`operation`** — the CE-API operation it targets (**the outbound edge**;
   §7 operation-name-carries-intent, all POST). A typed **`CsOperationRef`**
   const (§5.23) — the CE-API operation catalogue declares each operation's ref
   once (§5.14); CE-SC cites the const, so a dangling or renamed operation is a
   compile error.
2. **request assembly** — how the typed request `T` is built from client state: the
   CE-ST view-model / CE-FM form fields that populate each request field. Declared as
   a mapping (request field ← view-state/form source), not imperative code.
3. **response handling** — where the typed response `R` goes on success: the CE-ST
   view-model it updates and/or the CE-NV navigation it triggers (cited by its
   `CsRouteRef`, §5.23).
4. **error handling** — the structured error path: a `TomServerCallError` maps to the
   canonical CE-ER `Result`/`ErrorResult` envelope (§7.3); error **codes** resolve to
   copy through the CE-TX message-key registry (MSGKR, §5.21) — client copy and server
   error codes share one source (§7.4). 5xx are transport failures, never application
   outcomes (§7.2).
5. **call options** — the `TomServerCallSpecs` knobs that are spec-authorable:
   `includeBearerAuthentication` (CE-AU), extra headers, timeout/redirect policy.
   Channel selection is deployment config (CE-CC), not per-call.

**The action→endpoint reference edge (the core deliverable).** The edge is a
**two-hop, typed-reference chain**, each hop a typed const reference (§5.23 —
the stable id lives inside the const; never a string, never an embedded
definition), mirroring the CE-LO slot→element separation (§5.2):

```
CE-AC @CsAction ──triggers──▶ CE-SC @CsServerCall ──operation──▶ CE-API @CsEndpoint
     (client)                       (client)                           (shared)
```

- **Hop 1 — action → server call.** A CE-AC action (button / in-form event /
  condition trigger, §5.10) that "does something server-side" references the
  `@CsServerCall` it issues by its typed `CsCallRef` const (§5.23). An action may issue zero or one
  server call (pure-navigation / pure-UI actions issue none); a server call is issued
  by one or more actions. The action owns *when* (trigger); the server call owns
  *what* (operation + request/response). This keeps the CE-AC trigger taxonomy (§5.10)
  independent of transport.
- **Hop 2 — server call → API operation.** `@CsServerCall.operation` holds the CE-API
  operation's `CsOperationRef` (§5.6.1, §5.23). For an **internal** operation the
  compiler-checked contract (§4.2, shared project) guarantees the referenced operation
  exists and fixes `T`/`R`; a rename of the operation surfaces as a compile error at
  the CE-SC reference, not a silent runtime 404.
- **Outbound case.** An **outbound integration call** (the SOM IOE/INTEG direction
  mapping: outbound/consumed → `serverCall`) targets an **external** operation whose
  contract is externally defined — there is no own CE-API for it; the external
  operation's DTOs are **mirrored in the shared project** and the CE-SC call site is
  authored exactly like the internal case.

**Directionality & why by-reference.** References point client→shared (§1.1b:
dependency arrows point at the shared contract). The client `@CsServerCall` depends on
the shared CE-API operation; CE-API never depends back on any client. Modelling both
hops as typed const references (§5.23, not containment) means an action, its server call, and the
operation each have exactly one authoring home and can be reused (several actions → one
call; several calls → one operation) without duplication — the "author once, reference
everywhere" invariant CE-TX/CE-ER and domain enums already follow.

**SOM feed.** CE-SC is derived from **D05 ISC** (scenario steps whose
`systemResponse` is a server interaction) + **D02 TOM** (process steps that cross the
client/server boundary), per §8. The SOM models UI actions
(`ScreenActionEntry` SCRAC, `ScreenElementAction` SCELAC, `ComponentActionEntry` CMAC)
and scenario steps (`MainScenarioStepEntry.systemResponse`, `ScenarioStepEntry`) but
carries **no** server-call section and **no** explicit action→operation reference yet —
a planned D05 ISC / D02 TOM SOM extension adds the action / serverCall / navigation
sections that carry the reference-by-id fields, applying
`@CodeSpecKind([CodeSpecPart.serverCall])` on the server-call section and
`CodeSpecPart.action` on the action section (both enum values exist, currently
unused — SOM-completeness open question §10.3).

### 5.4 CE-ST view-model model over TomObservable/TomObject

**Decision.** CE-ST is the **typed view-model state** a client screen observes and
binds to — distinct from the persisted entity model (CE-DB). It is a *reuse* part
(no gap class): `@CsViewModel` is a thin annotation over the surveyed kernel
observable classes plus their tom_core_flutter binding adaptors. `@CsViewModel`
lives in the **client** project (`<app>_codespec_client`, §4.2); it is a purely
client-side concern with **no** `tom_flutter_ui` dependency — its substrate
is `tom_core_kernel` (the observable model) + `tom_core_flutter` (the widget/
`ValueListenable` bridge).

**Built on (kernel observable model + tom_core_flutter bridge).** `@CsViewModel`
wraps the surveyed classes; every one is a `tom_core`-family class per §1.1:

| Surveyed class | Package | Role for `@CsViewModel` |
|----------------|---------|--------------------------|
| `TomObservable` | `tom_core_kernel` (`tom_observable.dart`) | The observer-pattern base: `addObserver`/`removeObserver` (weak-ref), `notifyObservers`, `mute`/`unmute` batch. Every view-model *is-a* `TomObservable`. |
| `TomObject<T>` | `tom_core_kernel` (`tom_observable_objects.dart`) | A single typed observable cell (`get`/`set(T)`, `~obj`/`obj \| v` operators) that notifies on change. The leaf field of a view-model. |
| `TomString`/`TomInt`/`TomDouble`/`TomBool` | `tom_core_kernel` | Scalar-typed `TomObject<T>` subclasses — the primitive view-model fields. |
| `TomClass` (`TomObject<Map<String,TomObject>>`) | `tom_core_kernel` | The **composite** view-model: a named bag of observable fields; the natural `@CsViewModel` root for a screen. |
| `TomList<E>` / `TomMap<K,V>` | `tom_core_kernel` | Observable collection fields (repeated / keyed sub-state) inside a view-model. |
| `TomObservingWidget<T>` | `tom_core_flutter` | The UI binding: a `StatefulWidget` that observes `subState` and rebuilds its `child` on every notification (lifecycle-correct: register/migrate/deregister). |
| `ValueListenableObserver<T>` | `tom_core_flutter` | Adapts a `TomObservable` to Flutter's `ValueListenable` for `ValueListenableBuilder`/`AnimatedBuilder` consumers. |

So a `@CsViewModel` is fully determined by *(a `TomClass`/`TomObject` field tree of
typed observable cells) + (the tom_core_flutter binding adaptor each field is bound
through)*. It adds **no** new observable type; it names an existing observable state
shape and the client-side bindings around it.

**Attribute surface (`@CsViewModel`).**

1. **fields** — the typed observable cells of the view-model: each a
   `(name, T, kind)` where `kind` is scalar (`TomString`/`TomInt`/…), composite
   (`TomClass`), or collection (`TomList`/`TomMap`). Declared as a field tree, not
   imperative code. Initial values are authorable per field.
2. **derivation** — read-only fields computed from other fields (declared as a
   dependency + expression), realising the `notifyObservers` fan-out without
   hand-wiring observers.
3. **binding** — how each field reaches the UI: the CE-EL element / CE-FM form field
   it drives, via `TomObservingWidget`/`ValueListenableObserver`. Reference-by-id to
   the CE-EL/CE-FM target, not containment — an element authored once (§5.18) is
   cited here.
4. **lifecycle scope** — where the view-model lives (screen-scoped vs shared/app
   session-scoped). Screen-scoped is the default; shared view-models are named so
   several screens can reference the same instance.

**CE-ST relationships (boundaries).**

- **CE-ST ↔ CE-DB (the core distinction).** The view-model is *typed view state*,
  **not** the persisted entity. A screen editing a `Customer` DB entity (CE-DB) holds
  a `@CsViewModel` mirror of the fields being edited plus UI-only state (validation
  flashes, "dirty" flags, expansion toggles) that never persists. Load copies
  DB→view-model; save copies view-model→DB (CE-SC request assembly, §5.3 attr 2).
  The two never collapse into one type — the gap-row wording ("typed view-model state
  distinct from the DB model") is exactly this separation.
- **CE-ST ↔ CE-EL / CE-FM (binding).** View-model fields are the *source* that CE-EL
  elements and CE-FM form fields bind to; the binding edge is owned here (attr 3) as a
  reference to the element/field, keeping CE-EL/CE-FM free of view-model wiring.
- **CE-ST ↔ CE-SC (server round-trip).** A `@CsServerCall` response updates the
  view-model (§5.3 attr 3 "response handling"), and its request is assembled from
  view-model fields (§5.3 attr 2). CE-ST is the client state the server call reads
  from and writes to.

**SOM feed.** CE-ST is derived from **D03 IMO** (the information model —
which entity fields a screen exposes) crossed with **D06 XDS / screen definitions**
(which fields a screen holds as editable/derived view state), per §8. The SOM
carries a `CodeSpecPart.viewState` marker at one site
(`information_and_data_model.dart:3696`) but **no** dedicated view-model section with
a typed-field tree yet — a planned D03/D06 SOM extension adds the view-model section
(typed field tree + binding references), applying
`@CodeSpecKind([CodeSpecPart.viewState])` on that section (the enum value exists).

### 5.5 CE-CF server-configuration model + system-vs-user config scoping

**Decision.** CE-CF is the **server/system configuration** — deployment-time
settings that describe the running server as a whole. It is a *reuse* part (no gap
class): `@CsServerConfig` is a thin annotation over the surveyed `tom_core_server`
configuration classes. `@CsServerConfig` lives in the **server** project
(`<app>_codespec_server`, §4.2). System-vs-user configuration is **unified by
scoping, not by merging** — see the scoping design below.

**Built on (server configuration substrate).** `@CsServerConfig` wraps the
surveyed `tom_core_server` classes (`base_server_configuration.dart`); both are
`tom_core`-family classes per §1.1:

| Surveyed class | Package | Role for `@CsServerConfig` |
|----------------|---------|-----------------------------|
| `TomBaseServerConfiguration` | `tom_core_server` | The reflected config base: subclasses declare **typed fields** (port, TLS material, headers, JWT keys, handlers, logging). The reflection layer fills them by merging sources with a fixed precedence — config resources, then OS environment, then `.env`, then **command-line args (which win)**. A `@CsServerConfig` *is-a* `TomBaseServerConfiguration` subclass. |
| `TomServerConfigResourceProvider` | `tom_core_server` | The process-wide resolved configuration **tree**: a (possibly nested) map answering dotted-path lookups (`get`/`exists`), installed once at startup. It is the resource source `TomBaseServerConfiguration` merges from. |

So a `@CsServerConfig` is fully determined by *(a typed field set) + (per-field
source precedence: config-tree → env → `.env` → cmdline) + (a dotted-path key into
the `TomServerConfigResourceProvider` tree)*. It adds **no** new configuration
type; it names an existing `TomBaseServerConfiguration` field set and the
deployment-source resolution around it.

**Attribute surface (`@CsServerConfig`).**

1. **settings** — the typed configuration fields of the server: each a
   `(name, T, default?)`. Declared as a field set, not imperative code — the
   reflected `TomBaseServerConfiguration` subclass. Secret-bearing fields (TLS
   private key, JWT signing keys) are marked so production stripping (§12) and
   deployment tooling can treat them specially.
2. **source key** — the dotted `TomServerConfigResourceProvider` path a field
   resolves from (defaulting to the field name), plus the env-var / cmdline-flag
   alias. Reference-by-name (a `String`) — **exempt** from the §5.23
   typed-reference rule: the referent is a runtime resource-provider path into a
   deployment-supplied tree, not a Dart declaration; integrity is
   validator-checked (§12).
3. **precedence** — whether a field accepts the standard override chain
   (config-tree → env → `.env` → cmdline) or is fixed at one source; the base
   default is the standard chain (cmdline wins).
4. **feature flags (server scope)** — deployment-level boolean/enum toggles that
   gate server behaviour. A feature flag is an ordinary CE-CF **config value** —
   a flag field carries `@CodeSpecKind([serverConfiguration])` only. Distinct
   from feature *grants*: capabilities derived from authorization are
   server-level entitlements, not config values (§5.26).

**The system-vs-user config scoping (the core design).** One over-broad
"Configuration" concept is split into four owner-keyed scoped parts sharing one
conceptual model, not collapsed into one type (§11). The unification is
*conceptual* (one config-value model — typed key, default, source) realised as
**four owner-keyed, single-moded annotations**:

```
                     one "configuration value" concept
                        (typed key · default · source)
                                    │
        ┌──────────────────┬────────┴─────────┬───────────────────┐
   @CsServerConfig   @CsClientConfig   @CsDeviceSetting     @CsUserSetting
     (CE-CF)            (CE-CC)            (CE-DS)              (CE-UP)
   server/system     client app on a    a user's settings    a user's prefs,
   as a whole        specific machine   on one device        follow the user
   server project    client project     client project       client + server
```

The **discriminating axis** is the *scope key* — server/system (no user, no
machine) / (client app, machine) / (user, device) / (user) — and each part is
single-moded: the scope key alone decides where a value lives:

- **CE-CF ↔ CE-CC.** CE-CF is the server/system as a whole (DB connection, worker
  counts, TLS, JWT keys, server feature flags); CE-CC is a **client app on a
  specific machine** (API base URL, device options, per-install toggles), keyed by
  the (client app, machine) pair. A value about *how the server runs* is CE-CF; a
  value about *how one client install talks to it* is CE-CC. CE-CC's substrate is
  the `tom_core_flutter` `TomBaseClientConfiguration` holder (per §4.1); its
  attribute surface is §5.16.
- **CE-CC ↔ CE-DS.** The discriminator is **user identity in the key**: a value
  that is the same for every user of an install is CE-CC; a value that differs
  per signed-in user on the same install is CE-DS. CE-DS persists on the device
  and never leaves it; device binding is implicit-by-storage (the store lives on
  the device, keyed by the signed-in user) — no wire-level device identity exists.
- **CE-DS ↔ CE-UP.** Both are user-scoped; the discriminator is whether the value
  **follows the user**. Device-bound values (window layout, last-opened,
  machine-local cache preferences) are CE-DS; values restored on any device the
  user signs into (server-persisted, re-materialised via the
  `TomGetSettingsMessage`/`TomGetSettingsResult` round-trip, `tom_core_kernel`)
  are CE-UP. A value that is the same for every user of a server is CE-CF; a
  value that differs per user is CE-DS or CE-UP. Attribute surfaces are §5.16.
- **CE-CF ↔ CE-AZ / CE-AU.** CE-CF may hold the JWT signing keys and TLS material
  the server uses, but *who may call an operation* is CE-AZ and *credential/session
  exchange* is CE-AU — config supplies the keys, it does not model the policy.

There is **one** configuration-value concept, deliberately realised as **four**
owner-keyed parts; CE-CF is the server-only realisation. System, client, device
and user configuration are not unified into one type because they have different
owners, lifetimes, and persistence loci; they are unified at the *concept* level
and kept separate at the *realisation* level.

**SOM feed.** CE-CF is derived from **D06 ATS** (architecture / deployment
topology — what the server needs configured) + **D08 SAS** (security — which
config carries keys/secrets), per §8. The cross-scope source **precedence** —
which source wins when the same logical key is expressible at more than one
scope — is §5.16. A planned D06 ATS SOM extension isolates the CE-CF
configuration section, applying `@CodeSpecKind([CodeSpecPart.serverConfiguration])`
on that section (the enum value exists).

### 5.6 CE-API / CE-SU / CE-AZ server API, service-unit & authorization model

**Decision.** Three **server-side** parts
form one operation together: `@CsEndpoint` (CE-API, the operation), `@CsServiceUnit`
(CE-SU, the grouping the operation lives in), and `@CsAuthorize` (CE-AZ, the access
modifier on the operation). All three are authored **server**-side
(`<app>_codespec_server`, §4.2) — the handler, the unit and the operation-level
access modifier. Their **citable identities** are shared: the request/response DTOs
and the `CsOperationRef` operation catalogue, and the `CsRoleRef` /
`CsResourceKeyRef` catalogues `@CsAuthorize` cites, all live in the **shared**
project (§4.2, §5.23), because the client cites them too. The CE-SU boundary
criterion is **§5.1** (owned-aggregate primary, process-cohesion secondary,
bounded-context outer bound).

#### 5.6.1 CE-API — `@CsEndpoint` (reuse + extend for the §7 contract)

**Built on (kernel API model + server endpoint pipeline).** `@CsEndpoint` wraps the
surveyed classes; every one is a `tom_core`-family class per §1.1:

| Surveyed class | Package | Role for `@CsEndpoint` |
|----------------|---------|------------------------|
| `TomApi` / `TomApiEndpoint<ReturnType, RequestType>` | `tom_core_kernel` (`endpoints_apis.dart`) | The registry-side API description: an endpoint's `uri`, `methods`/`method`, `consumes`/`produces`, `formFields`, `urlParameterMapping`, typed `ReturnType`/`RequestType`. The typed request/response the §7 contract needs already exists here. |
| `TomRemoteApis` | `tom_core_kernel` | The API registry (`tomRemoteApis[apiId][endpointId]`) — the operation catalogue key space CE-SC (§5.3) references by name. |
| `TomEndpoint<requestType, resultType>` | `tom_core_server` (`endpoint_annotation.dart`) | The method-level inline endpoint annotation: `methods`, `uri`, mime types, per-endpoint error handler, headers, CORS, `urlParameterMapping`. The concrete route the pipeline mounts. |
| `TomApiEndpointImplementation` | `tom_core_server` | Binds a service method to a registry endpoint (`apiId`+`endpointId`) with impl-side overrides; `convertToTomEndpoint` merges registry + overrides. |
| `TomEndpointHandler` / `TomEndpointRouting` / `TomServer` | `tom_core_server` (`endpoint_pipeline.dart`, `server.dart`) | The pipeline: scans annotated methods, materialises parameters, runs `checkAccess` (→ CE-AZ), routes and serves. |

**Extension for the §7 contract (the CE-API-specific work).** The pipeline substrate
is verb-general (defaults to `GET`, arbitrary URIs, exceptions → 500). `@CsEndpoint`
**narrows** it to the §7 contract without changing the runtime:

1. **operation name, not verb+path.** Every `@CsEndpoint` is **POST** (§7.1); its
   identity is a first-class **operation name** (the intent carrier), not the HTTP
   verb or a REST-shaped path. The name is the stable id CE-SC references (§5.3
   hop 2) and the CE-SU grouping key.
2. **typed request/response.** Each operation names a request DTO `T` and response
   DTO `R` (the `TomApiEndpoint<R,T>` type args), both authored in the **shared**
   project so client (CE-SC) and server (CE-API handler) compile against one type.
3. **structured result, transport-clean.** The success payload is `R` inside the
   CE-ER `Result` envelope (§7.3); application errors are `ErrorResult` in a **2xx**
   transport response; only 5xx is a transport failure (§7.2). Error **codes**
   resolve to copy via the CE-TX message-key registry (§5.21), so no `@CsEndpoint`
   embeds error text.

`@CsEndpoint` therefore adds **no** new transport type — it constrains
`TomEndpoint`/`TomApiEndpoint` to (POST + operation-name + typed `T`/`R` + Result
envelope). The full operation/request/response **attribute set** is §5.14.

#### 5.6.2 CE-SU — `@CsServiceUnit` (reuse; ordinary abstract classes, no new class)

**Built on (server service grouping) + the §5.1 boundary.** `@CsServiceUnit` is the
**first-class name** for a cohesive set of operations + owned entities, over the
surveyed grouping substrate:

| Surveyed class | Package | Role for `@CsServiceUnit` |
|----------------|---------|----------------------------|
| `TomService` (`@tomService`) | `tom_core_server` (`endpoint_annotation.dart`) | The existing "scan my endpoint methods" class marker. A `@CsServiceUnit` class *is-a* `@tomService`. |
| `TomApiImplementation` (`extends TomService`) | `tom_core_server` | The registry-API-bound service variant (`apiId` + API-wide error/log defaults). |
| `TomComponentReference` | `tom_core_server` | Resolves a service's implementation bean by name or type — the unit's implementation binding. |
| `TomEndpointRouting.scanClasses` | `tom_core_server` (`endpoint_pipeline.dart`) | Discovers the annotated services/endpoints — the mechanism a unit's operations are gathered by. |

`@tomService` marks *a class to scan*; it does **not** express a **unit boundary**
(which operations + which owned entities/repositories form one cohesive service).
That boundary is supplied by the **`@CsServiceUnit` annotation** on an ordinary
**(abstract) class** that clusters the server API into a functional-group *closure*
— **no new `tom_core_codespecs` class** (decision (h)): the unit is a normal class
carrying the existing `@tomService` / `TomApiImplementation` server-API mapping
annotations, and `@CsServiceUnit` (a `Cs*` annotation, not a base class) names its
boundary. This respects the §4.1 no-base-classes rule.

**Boundary criterion (§5.1).** A `@CsServiceUnit` owns exactly
one **aggregate** (root entity + lifecycle-dependent entities), every CE-DB table/
repository over that aggregate, and every CE-API operation whose primary written
entity is in it (§5.1 rule 1); process cohesion may merge/split (rule 2); a bounded
context caps any merge (rule 3). Its stable id is `<RootAggregate>Service`
(PascalCase, §5.1) — that id is both the `@CsServiceUnit` identity and the
`<app>_codespec_server` grouping key (§4.2). A unit **never** reaches another unit's
repository directly; cross-unit data flows through the owning unit's CE-API (§5.1
ownership rule). The CE-SU **attribute set** (owned entities, operations, repository
list) is §5.17.

#### 5.6.3 CE-AZ — `@CsAuthorize` (reuse; a modifier on `@CsEndpoint`)

**Built on (kernel access-control model + server graded auth).** `@CsAuthorize`
wraps the surveyed authorization classes; every one is a `tom_core`-family class:

| Surveyed class | Package | Role for `@CsAuthorize` |
|----------------|---------|--------------------------|
| `TomAccessControl` (abstract) | `tom_core_kernel` (`access_controls.dart`) | The access-check contract: `checkAccessibility(principal)` (binary) + `resolveAuthState(principal)` (four-state). The value a `@CsAuthorize` carries. |
| `TomRoleAccess`/`TomGroupAccess`/`TomEntitlementAccess`/`TomResourceKeyAccess`/`TomCustomAccess` | `tom_core_kernel` | The concrete binary controls (role / group / entitlement / resource-key / custom). |
| `TomGradedAccess` | `tom_core_kernel` | Composes binary controls into the four `TomAuthState` levels (full / read / disabled / none) — the field-level graded authorization. |
| `TomPrincipal` / `TomAccessControlInformation` / `TomAuthState` | `tom_core_kernel` (`user_principal_aci.dart`) | The caller identity, its ACI, and the four-state auth outcome. |
| `TomResourceGrant` / `TomGradedAccessControlInformation` / principal delegation | `tom_core_server` (`graded_authorization.dart`, `principal_*.dart`) | Server-side graded grants + delegation. |
| `TomEndpointHandler.checkAccess` (handler-side `TomAccessControl` annotation, C-12/G-API-3) | `tom_core_server` (`endpoint_pipeline.dart`) | The runtime check the pipeline already runs per endpoint — the exact hook `@CsAuthorize` feeds. |

**CE-AZ is a modifier, not a standalone part (§4.1 rule).** `@CsAuthorize` is applied
**as an attribute on the owning `@CsEndpoint`** (and, for field-level graded access,
on a CE-EL/CE-FM element via `TomGradedAccess`). It names the `TomAccessControl` the
pipeline's `checkAccess` enforces for that operation. Reuse only — no gap class; the
runtime already supports both binary and four-state graded checks. The **six
requirement kinds + graded levels + field-level authKey** attribute surface is
§5.15; the SOM `SecurityAccessSpecification` (D08 SAS) is the source (§8).

**SOM feed.** CE-API/CE-SU are derived from **D07 IFS** (operations +
request/response) + **D06 ATS** (module/context grouping) + **D05 ISC** (which
scenarios exercise which operations); CE-AZ from **D08 SAS** (roles/permissions per
operation), per §8. The attribute surfaces: CE-API operation/request/response —
§5.14; CE-AZ requirement kinds + graded levels + field-level authKey — §5.15;
CE-SU service-unit attribute set — §5.17.

### 5.7 CE-EL / CE-FM screen-element & form model over tom_flutter_ui

**Decision.** The two **client-side** UI-structure
parts: `@CsElement` + `@CsWidget` (CE-EL, the semantic element and its concrete
widget binding) and `@CsForm` (CE-FM, the field group / form). Both are *reuse*
parts whose substrate is **`tom_flutter_ui`** (§1.1b).
Both live in the **client** project (`<app>_codespec_client`, §4.2). **No new
class:** CE-EL introduces no `tom_core_codespecs` type — it is fully covered by
`TomScreenElementsProvider` + the existing `Tom*` `tom_flutter_ui` element/widget
family + the form semantic classes. The "formal element-type catalogue" (§5.18)
is therefore a **documented catalogue over reused classes**, not a new class.

**Boundary (authoring homes).** Forms and subforms are part of the screen-element
description: **CE-FM owns the form/subform tree *and its member input elements*** —
an input element is authored **within its owning form**. **CE-EL proper is the
standalone (non-form) screen elements**: static display, action-trigger elements
(buttons, menu entries), form-hosting containers. The CE-EL catalogue (§5.18)
stays the **single kind vocabulary** (kinds + per-kind attributes) for form
members too — one vocabulary, two authoring homes. The substrate mapping is
unchanged: `TomField<T>` remains the input-element base, `TomForm.fields` holds
them, `TomFormChildContainer` carries subforms (§5.7.2).

#### 5.7.1 CE-EL — `@CsElement` + `@CsWidget` (reuse + a catalogue extension)

**Built on (tom_flutter_ui element substrate).** The two-step "semantic type →
concrete widget" (§5 gap row) maps onto the surveyed classes:

| Surveyed class | Package | Role for CE-EL |
|----------------|---------|----------------|
| `TomField<T>` (`extends TomObject<T> implements TomAuthorizable`) | `tom_flutter_ui` (`forms/tom_form.dart`) | The **semantic element** base: an observable typed value (`TomObject<T>`, §5.4 CE-ST substrate) with a `tomId`, scope/`basePath`, validators, `authorizer` (→ CE-AZ field-level graded access), obscure/auto-validate. `@CsElement` is *is-a* `TomField<T>` element. |
| Concrete field/widget types — `TomTextField`, the `TomButtonBase` variants (`TomElevatedButton`, `TomFilledButton`, …), `TomText`, inputs / selects / toggles | `tom_flutter_ui` | The **concrete widgets** a semantic element binds to. `@CsWidget` names one. |
| `TomScreenElementsProvider` / `TomScreenElementsProviderBase` | `tom_flutter_ui` (`widget_base/tom_screen_elements_provider.dart`) | The **declarative screen = typed-fields catalogue**: a `@tomReflect` class whose `late final` `TomField`/widget members are reflection-discovered, scoped for resource/authorization lookups. The CE-EL container a screen's elements live in. |

**The two-step separation (the CE-EL-specific work).** `@CsElement` carries the
**semantic** type (what the field *means*: a text input, a choice, a toggle, a
button — plus its value type `T`, label/help text → CE-TX, validators → CE-VA,
authorizer → CE-AZ). `@CsWidget` carries the **concrete widget binding** (which
`tom_flutter_ui` widget renders it). One semantic element → one widget by default,
overridable — mirroring the CE-LO slot→element and CE-SC action→operation
reference separations (§5.2/§5.3): the *meaning* is authored once, the *rendering*
is a separable binding.

**Element-type catalogue (the exit deliverable).** A **formal
element-type catalogue** — the closed set of semantic element kinds and, per kind,
the default `tom_flutter_ui` widget + the extra attributes that kind needs — is a
**CodeSpecs-only documentation** framing of behaviour already present in
`TomScreenElementsProvider` (which discovers *instances*, not a *type catalogue*)
and the `Tom*` widget family. It is authored as a **documented catalogue over the
reused classes — no new `tom_core_codespecs` class** (decision (d)); the kinds
*are* the existing `Tom*` widgets. The catalogue's concrete **contents** (the
per-kind attribute set + the semantic→widget bindings) are in **§5.18** — this
section fixes the catalogue's *reuse basis and two-step shape*.

#### 5.7.2 CE-FM — `@CsForm` (reuse; mirrors the SOM `@Form` field-group)

**Built on (tom_flutter_ui form substrate).** `@CsForm` wraps the surveyed classes:

| Surveyed class | Package | Role for `@CsForm` |
|----------------|---------|--------------------|
| `TomForm<T extends TomClass>` (`extends TomClass implements TomScreenElementsProvider, TomActionController, TomFormEventSource`) | `tom_flutter_ui` (`forms/tom_form.dart`) | The form base: a `fields` map of `TomField`s, a bound data object `T` (`bind`/`unbind`/`save`/`discard`/`validate`/`isDirty`/`isValid`), form-tree parent/child wiring, event source. `@CsForm` *is-a* `TomForm<T>`. |
| `TomFormChildContainer` | `tom_flutter_ui` (`forms/tom_form_child_container.dart`) | The **nested/repeated-subform** marker: a non-`TomForm` child (e.g. `TomListForm`) whose `validate`/`save`/`discard`/`unbind`/`isDirty`/`isValid` the parent form fans out into. The substrate for CE-FM subforms. |
| `TomField<T>` | `tom_flutter_ui` | The form's leaf fields (= CE-EL elements, §5.7.1). |

**Subforms — substrate-backed.** Subforms (nested/repeated) mirror the SOM `@Form`
field-group structure: the SOM `@Form` field-group maps directly onto `TomForm` +
`TomFormChildContainer`: a SOM `@Form` with a nested form-typed field → a nested
`TomForm` (reflectively discovered, `nestedForms`); a SOM `@Form` with a repeated
form-typed field → a `TomFormChildContainer` (list form). `@CsForm` therefore
carries the **field group + subform tree** shape from the SOM `@Form` with **no**
new form type — the nested/repeated lifecycle fan-out already exists. The concrete
`@CsForm` **attribute set** (per-field wiring, subform cardinality, form-level
CE-VA cross-field rules) rides the form model; CE-VA form rules are §5.19.

**SOM feed.** CE-EL/CE-FM are derived from **D09 XDS** (screens /
elements / forms / layout) + **D05 ISC** (scenarios name the screens), per §8. The
SOM carries the `@Form` field-group structure (the driver of the CE-FM
subform tree) and `@ContentHelp`/`@Form` hints (→ CE-TX). The CE-EL field base +
per-kind extras + semantic→widget catalogue contents are §5.18; the CE-VA field vs
form (cross-field) rules the forms carry are §5.19.

### 5.8 CE-TX text / message-key / i18n model over tom_flutter_ui + kernel

**Decision.** `@CsText` (CE-TX) is a **reuse** part
over the surveyed `tom_flutter_ui` label substrate and the `tom_core_kernel`
resource-provider backend. **CE-TX is *not* the id catalogue for screen-element
texts** (decision (e)): a screen element's own placeholder / label / help / error
copy is **derived**, not catalogued — from the element's `tomId` + its **route
scope** (`TomScope.withScope(...)`) + its **form scope** (form nesting) →
**`basePath`** → resource keys (with the per-role suffixes), and **those same
resource keys are also the CE-AZ authorization resource keys** (§5.15). CE-TX
instead catalogues **all *other* texts** — server / error copy, notification and
email bodies, report copy, and any text not owned by a screen element. The one
CodeSpecs-only addition — a **message / i18n-key model** (the closed catalogue of
those message keys and their per-locale copy resolution) — lands in
**`tom_core_codespecs`** (a concrete model class, **not** an abstract `Cs*` base;
§4.1 no-base-classes rule). CE-TX is the one part that **spans two projects**
(§4.2): the **message keys** live in `<app>_codespec_shared` (the same keys the
server uses for error copy), while the **copy** (the resolved per-locale strings)
is a **client** concern (`<app>_codespec_client`).

**Built on (label substrate + i18n backend).** The two roles — the *carrier* of a
text on a UI element and the *resolver* of a key to localized copy — map onto the
surveyed classes:

| Surveyed class | Package | Role for CE-TX |
|----------------|---------|----------------|
| `TomText` (`extends TomLabelBase`) | `tom_flutter_ui` (`widgets/labels/tom_labels.dart`) | The **text carrier** on a UI element: fields `labelText` / `hintText` / `descriptionText` are the placeholder / label / help texts a CE-EL element (§5.7.1) exposes. Each falls back to a **resource key** when the literal is absent (`_resolvedLabel = labelText ?? TomCtr.textOrFail(basePath, 'label')`) — the built-in literal-or-key duality `@CsText` formalises. |
| `resolveErrorMessage` (label/field error hook) | `tom_flutter_ui` | The **error-copy hook**: an element's error text. `@CsText` routes this through the CE-ER error code (below), not a free literal. |
| `TomTextResourceProvider` | `tom_core_kernel` (`tombase/resources/tom_resource_provider.dart`) | The **i18n backend**: a singleton text-resource provider — localized strings, UI labels, messages — with **hierarchical dot-notation key access** (`getText('app.title')`), initialised from JSON maps or loader functions, resolving keys tree-walk-first then flat-key. The store a message key resolves against. |
| `TomConfigResourceProvider` | `tom_core_kernel` (same file) | The sibling **config** provider (same dot-notation resolution). CE-TX reads copy from the text provider; CE-CF (§5.5) reads config from this one — the split keeps copy and config in distinct resource trees. |

**Two text sources — derived (element) vs catalogued (other).**

1. **Screen-element texts — derived from `basePath`, not catalogued.** A screen
   element's placeholder / label / help / error copy is resolved from its
   **`basePath`** — computed from the element's `tomId` + route scope
   (`TomScope.withScope(...)`) + form scope (nesting) — plus a per-role **suffix**
   (`label` / `hint` / `description` / error). `TomText`'s built-in literal-or-key
   duality (`_resolvedLabel = labelText ?? TomCtr.textOrFail(basePath, 'label')`)
   already does this; the SOM `@ContentHelp` / `@Form` hint / doc-comment content
   (§8) seeds the literals. **These `basePath`-derived keys are also the CE-AZ
   authorization resource keys** (§5.15), so text and access share one key space.
   No CE-TX catalogue entry is authored for them.
2. **Other texts — the CE-TX message / i18n-key model.** Every text **not** owned
   by a screen element (server / error copy, notification & email bodies, report
   copy) is a **message key** (`'app.error.amount.tooLarge'`) resolved at runtime
   by `TomTextResourceProvider`. The closed set of these keys + their per-locale
   copy is the **message / i18n-key model**, a `tom_core_codespecs` catalogue.
   Keys are **shared** (server error copy resolves the *same* keys, §7), copy is
   **client**.

**Error texts keyed by CE-ER codes (the cross-part relationship).** Error copy is
**not** a free literal: an element's `resolveErrorMessage` / a form's validation
failure resolves to copy via the **CE-TX message-key registry (MSGKR)**,
keyed by the structured **CE-ER error code** (§7). Client copy and server error
codes share one source (the CE-ER error-code registry ↔ the CE-TX MSGKR), so a
code authored once yields both the server's structured error and the client's
localized message.

**SOM feed.** CE-TX is derived from **D09 XDS** (screens / elements
/ forms) + SOM `@ContentHelp` / `@Form` hints / doc-comments, per §8 — the texts
are already in the SOM; error texts arrive via CE-ER codes. The message-key /
i18n attribute surface (per-key attribute set + locale model + error copy keyed
by CE-ER codes) is §5.21.

### 5.9 CE-VA validation — field-rule vs form-rule split over tom_flutter_ui

**Decision.** The CE-VA validation parts are a
**reuse** family: a `@CsValidation` umbrella plus the two-way
**field-rule vs form-rule** split — `@CsFieldRule` (single-field) and `@CsFormRule`
(cross-field / form-level). The substrate is **`tom_flutter_ui`** (§1.1b). **No new
class:** CE-VA is **provided as Dart code** — standalone validator classes with
validation methods, or validation methods on the `TomForm` subclass — exercising
the §3 first-level-implementation latitude (a CodeSpec need not be purely
declarative). CE-VA spans **client + shared** (§4.2): field/form rules the
client enforces are also part of the shared contract the server re-checks.

**Built on (tom_flutter_ui validation substrate).** The single-field and
cross-field roles map onto the surveyed classes:

| Surveyed class | Package | Role for CE-VA |
|----------------|---------|----------------|
| `Validator<T> = FutureOr<ValidationResult> Function(T)` | `tom_flutter_ui` (`forms/validation/validation_result.dart`) | The **single-field rule** signature (async-capable): a typed value → a `ValidationResult`. `@CsFieldRule` *is-a* `Validator<T>`. |
| `ValidationResult` (sealed: `ValidationPristine` / `ValidationSuccess` / `ValidationError(errorKey, {params})` / `ValidationPending`) | `tom_flutter_ui` (same file) | The **rule outcome**. `ValidationError.errorKey` is a **message key** — the CE-VA↔CE-TX/CE-ER tie (below). The `Pending` variant carries the async/`SlowValidator` case. |
| `Validators` | `tom_flutter_ui` (`forms/validation/validators.dart`) | The **built-in field-rule catalogue** (`required`/`email`/`minLength`/`maxLength`/`pattern`/`min`/`max`/`compose`). The reuse basis for the standard `@CsFieldRule` kinds. |
| `TomValidatorRegistry` (`resolve`/`resolveSpec`/`resolveDeclaration`/`parseSpec`) | `tom_flutter_ui` (`forms/validation/validator_registry.dart`) | The **validator declaration language**: name+args → `Validator`. The substrate for authoring rules declaratively — the declaration language is §5.19. |
| `FormValidationError` (`fields`, `tomIds`) | `tom_flutter_ui` (`forms/validation/form_validation_error.dart`) | The **cross-field / form-level** error carrying the offending fields. `@CsFormRule` *is-a* form-level rule producing this. |

**The field-vs-form split (Dart methods, no new class).** `@CsFieldRule` validates
one field in isolation (`Validator<T>` → `ValidationResult`); `@CsFormRule`
validates across fields (a cross-field invariant → `FormValidationError` over
several `tomIds`). The split is expressed **as Dart code** — a `@CsFieldRule` as a
standalone `Validator<T>` method or a registered `Validators` entry, a `@CsFormRule`
as a **validation method on the `TomForm` subclass** — so it needs **no
`tom_core_codespecs` class** (decision (f); the two validation scopes already exist
separately in `tom_flutter_ui`). `@CsValidation` is the umbrella that groups a
field's / form's rules; each rule is **traceable to a requirement** (the gap-row's
"each traceable to a requirement" clause) via the SOM feed below.

**Error copy — the CE-VA↔CE-TX/CE-ER tie.** A rule failure is **not** a free
literal: `ValidationError.errorKey` is a **message key** resolved through the CE-TX
message-key registry (MSGKR, §5.8), keyed where appropriate by a CE-ER error
code (§7). At spec level the key is a typed `CsMessageKey` / `CsErrorCode` const
(§5.23); the runtime `errorKey` string is the generated **lowered** form. So a
validation rule authored once yields a structured failure *and* its
localized message — the same author-copy-once discipline CE-TX/CE-ER share.

**SOM feed.** CE-VA is derived from **D04 RSP** (requirements) +
**D03 IMO** constraints, per §8 — **field rules** from attribute constraints,
**form rules** from cross-field requirements, each rule tracing back to the
requirement that mandates it. The field-rule vs form-rule attribute surface +
validator declaration language (over `TomValidatorRegistry`) is §5.19; the rule
keys resolve against the CE-VA/CE-ER/CE-TX error-code spine (§5.8, §7).

### 5.10 CE-AC action + trigger taxonomy over tom_flutter_ui

**Decision.** `@CsAction` (CE-AC) is a **reuse** part over the surveyed
`tom_flutter_ui` action substrate, plus a `@CsTrigger` marker and the CodeSpecs-only
**trigger taxonomy** (how an action is invoked). The substrate is
**`tom_flutter_ui`** (§1.1b). CE-AC lives in the **client** project (§4.2). **No new
class:** Actions have a **full implementation in `tom_flutter_ui`**
(`TomAction` / `TomActionController` / `TomActionTrigger`, decision (g)); the formal
**trigger taxonomy** is a **documented classification over those reused classes**,
not a `tom_core_codespecs` type.

**Built on (tom_flutter_ui action substrate).** The action and its invocation map
onto the surveyed classes:

| Surveyed class | Package | Role for CE-AC |
|----------------|---------|----------------|
| `TomAction<TContext, TUndo>` (`implements TomAuthorizable`) | `tom_flutter_ui` (`actions/tom_action.dart`) | The **action base**: a stateless, typed, authorized, optionally-undoable behaviour with an `actionId`, `canonicalPath` (`<controllerId>.<actionId>`), `canExecute`/`execute`/`undo`, and an `authorizer` (→ CE-AZ). `@CsAction` *is-a* `TomAction`. |
| `TomActionContext` | `tom_flutter_ui` (`actions/tom_action_context.dart`) | The **typed context requirement** an action declares via `TContext` (the domain data + `scope` an action needs to run). |
| `TomActionController` | `tom_flutter_ui` (`actions/tom_action_controller.dart`) | The **action registry / owner**: groups related actions, supplies the first canonical-path segment. The CE-AC container. |
| `TomActionTransaction` | `tom_flutter_ui` (`actions/tom_action_transaction.dart`) | The **atomic-undo unit** grouping sub-actions of one gesture — the undo/redo substrate. |
| `TomActionTrigger<TContext, TUndo>` | `tom_flutter_ui` (`actions/tom_action_trigger.dart`) | The **widget-gesture trigger** realization: binds an action to a widget callback (`onPressed`/`onTap`), does `canExecute`-gating, transaction creation, undo recording. The concrete *button/gesture* member of the trigger taxonomy. |

**The trigger taxonomy (the CodeSpecs-only work).** `@CsAction` names *what* the
behaviour is (over `TomAction`); `@CsTrigger` names *how* it is invoked. One action
may have **several triggers** — the gap-row's "one action, several triggers". The
taxonomy is the closed set of invocation kinds:

- **user-gesture** — a button press / tap / in-form widget event (`TomActionTrigger`
  is this kind's realization).
- **in-form event** — a form lifecycle event (field change / submit / validation).
- **lifecycle** — a screen/route enter/leave or app lifecycle hook.
- **server-event** — an inbound server push / notification.
- **condition** — a reactive predicate over observable (CE-ST) state.

**The trigger is the single authoring home of the element→action edge.** A
`@CsTrigger` *is* the (element/event → action) **join entity**: it carries **both
endpoints** — the source (element ref + gesture, or event) and the target action
ref — plus the guard. Element-side action hooks (a Button's or MenuEntry's
action, a field's inline action-icon) are **derived back-references**, never
authored (§5.18). One element may trigger different actions on different events
and one action may be triggered from several elements — N:M with the trigger as
the join, mirroring the CE-SC middle node of the CE-AC→CE-SC→CE-API chain (§5.3).

This is a **CodeSpecs-only** framing of invocation paths `tom_flutter_ui`
realises only partially (`TomActionTrigger` = the user-gesture case); it is
authored as a **documented classification over the reused action classes — no new
`tom_core_codespecs` class** (decision (g)), keeping `tom_flutter_ui` the single
implementation home.

**Action → server-call tie (§5.3).** A triggered CE-AC action frequently drives a
CE-SC server call — the **explicit two-hop CE-AC→CE-SC→CE-API reference edge** of
§5.3. `@CsAction` carries the *what* (the behaviour + its trigger); the
`@CsServerCall` it references carries the *how* (operation + request/response).

**SOM feed.** CE-AC is derived from **D05 ISC** (scenarios / processes
name the actions + their triggers + transitions) + **D02 TOM**, per §8. The
per-trigger attribute surface over `TomAction` is §5.20; the CE-AC→CE-SC→CE-API
edge a triggered action drives is §5.3.

### 5.11 CE-NV navigation — route-id + screen-flow model over tom_flutter_ui

**Decision.** `@CsRoute` (CE-NV) is a **reuse** part over the `tom_flutter_ui`
routing substrate, plus the CodeSpecs-only **route-id model** (stable route
identifiers) and a **screen-flow model** (`@CsScreenFlow`). The substrate is
**`tom_flutter_ui`** (a CodeSpecs code basis, §1.1b). CE-NV lives in the **client**
project (§4.2). The CodeSpecs-only additions — the **route-id model** and the
**screen-flow model** — land in **`tom_core_codespecs`** (concrete classes,
**not** abstract `Cs*` bases; §4.1 no-base-classes rule).

**The screen-flow model (decision (c)).** Beyond bare route ids, CE-NV models the
**screen flow** that results from combining the D05 ISC interaction scenarios into
**interactions with screens** (Flutter routes):

- **Form → screen assignment.** Each form (CE-FM) is assigned to a screen (route),
  either **replacing** the current screen (a normal route push/replace) or
  **overlaying** it as a **popup** (a dialog / modal over the current screen).
- **Action-triggered, conditional navigation.** Navigation is triggered by a
  CE-AC action (§5.10) and its **target is conditional on the action outcome**:
  on **success** → a confirmation screen or back to the previous screen; on
  **error / validation error** → an error display. `@CsScreenFlow` records the
  (source screen, triggering action, outcome → target screen, presentation mode)
  edges.

**The SOM authoring home.** The edges are authored in the **screen route map**
(`SCRTMP`), the third subsection of D09 XDS `ScreenFlowStructure` (10.3.3),
beside the navigation model and the screen-flow diagram. It carries three
registries, each mapping one-to-one onto the `tom_core_codespecs` model:

| SOM section | Authors | Code counterpart |
|-------------|---------|------------------|
| `SCRTEN` route entries | Stable **route id**, path, title, rendered screen, route parameters | `TomRouteDefinition` |
| `FMSCAS` form placement | form id → route id + presentation mode | `TomFormScreenAssignment` |
| `SCTREN` transitions | (source route, action, outcome) → target route + presentation mode | `TomScreenFlowEdge` |

Two closed vocabularies back them: `ScreenPresentationMode` (`replace` /
`popupOverlay` — the spec-side name for `TomScreenPresentation.popup`) and
`ScreenFlowOutcome` (`success` / `error` / `validationError`). The transition's
`outcomeReference` joins the outcome to the existing catalogues — the CE-ER
system error code (`SYERCOEN`) for `error`, the CE-VA validation message
template (`VMT`) for `validationError` — so no error vocabulary is duplicated.

Routes are referenced **by id, never by path**: the path is presentation and
changes, the id is the stable handle that form placement, transitions, screen
classification (`SCECL.routePattern`) and action outcomes (`SAEB.navigateTo`)
all point at.

**Built on (tom_flutter_ui navigation substrate).** The route and its navigable
targets map onto the surveyed classes:

| Surveyed class | Package | Role for CE-NV |
|----------------|---------|----------------|
| `TomPageRoute<T>` (`extends MaterialPageRoute<T>`) | `tom_flutter_ui` (`widgets/navigation/tom_page_route.dart`) | The **route base**: a scope-propagating page route (captures `TomScope.current` at push, re-enters it around `builder`) with a typed result `T`. `@CsRoute` *is-a* `TomPageRoute<T>` — a navigable screen with a typed return. |
| `TomNavigationDestination` (+ `TomNavigationRail`/`Bar`/`Drawer`) | `tom_flutter_ui` (`widgets/navigation/tom_navigation.dart`) | The **navigable target** widgets: a destination carries a `tomId`, `scope`, `authorizer` (→ CE-AZ) and resolves its label/tooltip from resources (→ CE-TX). The screen-to-screen transition endpoints. |

**The route-id model (the CodeSpecs-only work).** The substrate identifies a
destination by `tomId` but assumes **route uniqueness** without a formal registry
(the gap-row's "Route uniqueness assumed"). `@CsRoute` adds a **route-id model**: a
closed set of **stable route identifiers** (one per navigable screen). The
**screen-to-screen transition** edges between them (which route reaches which,
under what action + outcome, and in which presentation mode) live in the
**screen-flow model** above. Both are a **CodeSpecs-only** framing — they land as **concrete classes in
`tom_core_codespecs`**, keeping `tom_flutter_ui` free of the CodeSpecs-only registry.
Transitions are driven by CE-AC actions (§5.10): a triggered action's outcome may be
a navigation — the route it targets is cited by its typed `CsRouteRef` const
(§5.23); the stable route-id string lives inside the const.

**SOM feed.** CE-NV derives from **D05 ISC** (scenarios / processes define the
screens and their transitions) + **D02 TOM**, per §8 — grouped with CE-AC/CE-SC as
the "scenarios/processes define actions, triggers, transitions" feed. The
screen-flow edges (form→screen assignment, presentation mode, action-outcome
targets) are authored in the **screen route map** (`SCRTMP`, D09 XDS). The route-id a
CE-AC transition targets is the §5.10 action outcome; a route's destination
`authorizer` is CE-AZ; its label/tooltip is CE-TX.

### 5.12 CE-LO layout — CsLayout node model grounded on the ACL substrate

**Decision.** The **§5.2 two-layer, id-addressed `@CsLayout` node model** is
grounded on the concrete `tom_flutter_ui` **Advanced Container Layout (ACL)**
substrate + the `tom_core_flutter` observation binding. §5.2 fixes the design
(generated base + override delta layer; container node + slot node; stable node
ids; non-destructive override survival); this section fixes *which surveyed classes
realise each node kind* and where the CodeSpecs-only structure lives (the
`tom_flutter_ui` basis per §1.1b). The override-separable node model lands in
**`tom_core_codespecs`** (a concrete class, **not** an abstract `Cs*` base; §4.1
no-base-classes rule). CE-LO lives in the **client** project (§4.2).

**Built on (ACL layout substrate + observation binding).** The §5.2 node kinds map
onto the surveyed classes:

| §5.2 node kind | Surveyed class | Package | Role |
|----------------|----------------|---------|------|
| **Container node** (row/column/wrap/…; layout-only props + ordered children) | `AclRow` / `AclContainer` / `Acl`/`AclLayout` | `tom_flutter_ui` (`advanced_container_layout/acl_container.dart`) | The fluent row/column container: `AclRow.components` (ordered children) + `alignment`; `AclFlags` carries the AWT-mirrored **layout-only** constraint flags. Realises the §5.2 container node's direction/alignment/spacing + children. |
| **Slot node (leaf)** (reference-by-id to a CE-EL/CE-FM element + per-slot hints) | `AclComponent` | `tom_flutter_ui` (same file) | A layout component wrapping a `child` widget (= the CE-EL element it positions), already carrying a stable **`id`**, `referenceKey` / `alignXToKey` / `alignYToKey` (**id-addressed alignment**), `flags`, `gapBefore`, and preferred/min/max sizes — the per-slot layout hints. The substrate's native id-addressing is exactly what the §5.2 override layer keys against. |
| **Reactive rebind** (layout responds to CE-ST observable state) | `TomObservingWidget<T extends TomObservable>` | **`tom_core_flutter`** (`tomclient/observing/tom_observing_widget.dart`) | Bridges the kernel observation model to Flutter — rebuilds on every notification. Wires responsive/visibility layout to CE-ST state. |

**Why the substrate fits §5.2 cleanly.** `AclComponent` **already** separates the
*positioning* concern (id, alignment-by-key, flex/gap/sizes) from the *content* it
holds (`child`) — the exact semantics↔layout split §5.2 mandates, so the slot node is
a near-direct reuse. The `id` + `referenceKey` addressing means the §5.2 override
deltas (reparent a slot, change a container's direction, set a flex) can be expressed
as **id-keyed patches over `AclComponent`/`AclRow`** with no new addressing scheme.

**The override-separable node model (the CodeSpecs-only work).** ACL is a *rendering*
API — it draws a layout but has no notion of a *generated base + surviving override
layer*. That two-layer, regeneration-safe structure (§5.2) is the **CodeSpecs-only**
addition; it lands as a **concrete
override-separable-node-model class in `tom_core_codespecs`**, keeping `tom_flutter_ui`
free of the CodeSpecs-only build-time structure. It emits an ACL tree at render time.

> **Substrate location note.** `TomObservingWidget` lives in
> **`tom_core_flutter`**, not `tom_flutter_ui`; the CE-LO code basis groups it
> with the ACL classes under the "tom_flutter_ui" substrate heading. This is a precision on
> the survey — both are tom_core-family packages (§1.1b).

**SOM feed.** CE-LO base structure ← **D09 XDS** screen/form layout (+ **D05 ISC**
screen naming); the override layer is authored, not derived; join key `@SectionId`
(§5.2, §8). The concrete per-node attribute set and the override-delta grammar are
§5.22.

### 5.13 CE-DB entity/column/repository-query surface + entity-model placement

**Decision.** The CE-DB attribute inventory and the **entity-model placement**
(client DTO vs server-side entity). This section records both the placement
decision and the full CE-DB attribute surface. The `@CsTable`/`@CsColumn`/`@CsRepository`
code basis is the `tom_core_server` persistence model.

**Attribute surface (final).** The complete entity / column / repository-query
attribute set for CE-DB:

- **Entity level** — entity name, storage table, datasource, schema, identity
  attribute + identity column, row-scope rule.
- **Attribute level** (per persistent field) — attribute name, storage column,
  value type, column (storage) type, read-only, not-loaded, json-encoded,
  **column-access key** (field-level authorization, → CE-AZ), value converters.
- **Access-object (repository)** — entity type + key type, named query, query
  predicate (`eq`/`like`/`between`/`isIn`/`and`/`or`/…), sort, row cap, distinct,
  transaction scope (unit of work).

Framework-internal plumbing (SQL dialect, prepared-statement placeholders,
`TomTransactionParticipant` lifecycle, `TomColumnInformation`, …) is **not** spec
input, per that inventory.

**Placement — server-only.** CE-DB is
**server-only** (`<app>_codespec_server`, §4.2): the persisted entity and its
`@CsTable`/`@CsColumn`/`@CsRepository` live **only** on the server. The two roles the
"client DTO" alternative conflated are instead served by two *other* parts:

- **Across-the-wire shape** → the **CE-API request/response types** in
  `<app>_codespec_shared` (§4.2) — the DTOs both sides depend on. What crosses the
  wire is a CE-API shape, never a DB entity.
- **In-screen data** → the **CE-ST view-model** (§5.4, client) — typed view state
  hydrated from a CE-API response, distinct from the persisted entity (the CE-ST↔CE-DB
  separation, §5.4).

**Why server-only wins.** Keeping columns / datasource / SQL / row-scope /
transactions off the client (a) preserves the CE-ST↔CE-DB separation §5.4 already
mandates, (b) keeps the shared contract to only what crosses the wire (CE-API
shapes), and (c) matches the service-unit ownership model §5.1 — a service unit owns
its aggregate entities *and their repositories* server-side, exposing them only
through CE-API operations. A client "DB entity" would leak persistence structure past
the API boundary and duplicate the view-model's job.

**SOM feed.** CE-DB is derived from **D03 IMO** rich classes (tables, columns, DAOs),
per §8.

**CE-DB ↔ CE-MG.** The entity model and the migration artifacts describe the
same schema from two sides: `@CsTable`/`@CsColumn` declare the *target* shape,
the CE-MG migration chain (§5.27) produces it *cumulatively*. Their convergence
— cumulative DDL ≡ declared entity model — is the named CE-MG schema-convergence
validator check (§5.27); neither side is generated from the other.

### 5.14 CE-API + CE-SC operation/request/response attribute surface under §7

**Decision.** The **CE-API** (server operation surface) and **CE-SC** (client call
assembly + action edge) attribute inventories, aligned to the **§7 server contract**
. The code bases are **`@CsEndpoint`**
(§5.6.1) and **`@CsServerCall`** + the two-hop CE-AC→CE-SC→CE-API edge (§5.3); this
section fixes the *attribute surface* both carry. **Non-overlap rule:** a
`@CsServerCall` never authors or re-declares a contract member — operation name,
`T`/`R` shapes and error codes are CE-API-owned; CE-SC only cites them (§5.3).

**CE-API operation surface (final, §7-aligned).** Per the §7 contract:

- **Method is fixed POST** — dropped as a spec input. The **operation name** (not
  verb+path) carries intent and is the one required operation identifier.
- **Typed request shape** + **typed response shape**, where the response type **is**
  the CE-ER `Result<T>` envelope (success payload *or* structured error).
- **Error-response types narrow to 5xx transport errors only**
  (`statusCodeResponseTypes` = infrastructure failure); every **2xx** response is the
  `Result<T>` envelope, so an application error is never a status code.
- Description → CE-TX; authorization requirement → CE-AZ; base path / consumes /
  produces are transport defaults (JSON). Framework transport members
  (encoding, redirects, headers, CORS, bearer-auth plumbing) are **not** spec input.
- **Placement:** the CE-API server surface is **server** (`<app>_codespec_server`);
  the request/response **types** are **shared** (`<app>_codespec_shared`, §4.2) — the
  DTOs both sides depend on (the §5.13 "what crosses the wire" role).

**CE-SC client-call surface (final, §7-aligned).** The client-side consumption of a
CE-API operation:

- **Target operation** — a typed `CsOperationRef` const to a CE-API operation
  (§5.23; the §5.3 hop-2 edge).
- **Request payload** — assembled from the **CE-ST view-model** (§5.4): save copies
  view-model → request shape.
- **Response handling** — `R` **is** the CE-ER `Result<T>` envelope (success updates
  the view-model, structured error resolves to CE-TX copy by CE-ER code);
  `TomServerCallError` captures **5xx transport failure only**.
- **Triggering action** — the CE-AC edge (the §5.3/§5.10 two-hop chain; typed
  const references per §5.23).
- **Local-vs-server** classification.
- **Placement:** **client** (`<app>_codespec_client`, §4.2). `TomServerCall` /
  `TomServerChannel` / `TomServerCallSpecs` transport plumbing stays
  framework-internal.

**SOM feed.** CE-API/CE-SC derive from **D07 IFS** + **D06 ATS** + **D05 ISC** (§8) —
operations + request/response from the interface spec; the client call + action edge
from the scenarios.

### 5.15 CE-AZ authorization-requirement attribute surface

§5.6.3 fixes the `@CsAuthorize` **base** (a reuse modifier on `@CsEndpoint` carrying
a `TomAccessControl`); this section fixes the requirement **attribute surface**.

**Built on (grounded against source).** The kernel access-control model is a sealed
family: `TomAccessControl` (abstract, `access_controls.dart:185`) with
`checkAccessibility(principal)` (binary) + `resolveAuthState(principal)` (four-state,
default `full`/`none`). A spec expresses an authorization **requirement**; the concrete
subclass *is the shape* of that requirement. The requirement kind is therefore a
**closed discriminated choice** — exactly the `@OneOf`/`@Case` closed-choice
mechanism (§8.2): one
`@OneOf` requirement, one `@Case` per kind, each case with its own attribute set.

**The six attribute-bearing requirement kinds** (each a distinct `@Case` payload):

| # | Requirement kind | `@Case` payload attribute(s) | `tom_core` source |
|---|------------------|------------------------------|-------------------|
| 1 | **Role** | `roles: List<CsRoleRef>` — typed consts from the shared role catalogue (§5.23), lowered to `TomRoleAccess.roles` strings at generation | `TomRoleAccess.roles` (`:529`) |
| 2 | **Group** | `groups: List<String>` | `TomGroupAccess.groups` (`:562`) |
| 3 | **Entitlement** | `patterns: List<String>` (entitlement match patterns) | `TomEntitlementAccess.patterns` (`:461`) |
| 4 | **Resource-key** | `key: CsResourceKeyRef` — a typed const from the shared resource-key catalogue (§5.23), lowered to `TomResourceKeyAccess.key` at generation | `TomResourceKeyAccess.key` (`:589`) |
| 5 | **Custom** | `handler: String` + `resourceId: String` (registered handler ref + resource) | `TomCustomAccess.handler`/`resourceId` (`:414`/`:417`) |
| 6 | **Graded** | a **three-slot nested tree** `full` / `read` / `disabled`, each itself a requirement (recursion into kinds 1–5 or a preset) | `TomGradedAccess.full`/`read`/`disabled: TomAccessControl` (`:243`–`:250`) |

Role and resource-key requirements cite **Dart-declared catalogues** and are
therefore typed refs (§5.23). Group names, entitlement match patterns and the
custom handler/resource ids reference **runtime principal data and runtime
handler registrations**, not Dart declarations — they stay strings under the
§5.23 exemption logic, validator-checked (§12).

**Attribute-less presets** (a kind selector with *no* payload — still valid `@Case`
values so the choice is exhaustive): `TomNoAccess` (deny), `TomPublicAccess` (allow),
`TomAuthenticatedAccess` (any signed-in user), `TomGuestAccess`. These carry no
spec-authorable attributes — the kind *is* the whole requirement.

**Graded levels** (the outcome dimension). Binary kinds (1–5, presets) resolve to the
two-state `full`/`none` via the `resolveAuthState` default; **Graded** (kind 6) is the
only kind that reaches all four `TomAuthState` values — `none < disabled < read < full`
(`tom_authorization.dart:29`), with monotonic defaults **`read` ⇐ `full`** and
**`disabled` ⇐ `read`** so the common case authors only `full`. The four states carry
fixed UI semantics (`none` hidden · `disabled` visible-but-locked · `read` value-shown ·
`full` interactive), so the level→render mapping is framework-fixed, **not** a spec
attribute. `showsContent` = read|full is the accessibility predicate.

**Field-level authKey** (the cross-part attribute). A **resource-key requirement**
(kind 4) attached to a *field* rather than an operation — the same
`CsResourceKeyRef` consts (§5.23): `TomDbColumn.authKey` on a
CE-DB column (§5.13) and the `authorizer`
(→ `TomGradedAccess`) on a CE-EL/CE-FM `TomField` / CE-AC `TomAction` / CE-NV
destination. `@CsAuthorize` at field level therefore rides on those parts, not on an
endpoint. The `TomResourceKeyProtection` global-setting toggles
(`useAutomaticEndpointProtection`, `…FormFieldProtection`, `…DatabaseProtection`, …,
`access_controls.dart:77`) are **deployment configuration → CE-CF**, not per-requirement
spec input — they switch *whether* the automatic field/endpoint/db protection layer is
active, not *what* any single requirement demands.

**Framework-internal (not spec input).** `TomPrincipal` (~20 runtime identity fields),
`TomAccessControlInformation` collections, `TomResourceRoleRegistry` /
`TomPrincipalResourceGrant` persistence, `TomResourceGrant` /
`TomGradedAccessControlInformation` server-side grants + delegation, the
`TomAccessControl.checkAccessibility` / `resolveAuthState` evaluation entry
points and the `TomEndpointHandler.checkAccess` pipeline hook that calls them
(three distinct methods — the first two are the kernel's, the third the
server's) — these are the runtime that *evaluates* a requirement, never
authored per operation.

**Boundaries drawn.**
- **CE-AZ ↔ CE-AU.** CE-AZ is *what a caller must satisfy* (a requirement over the
  principal's roles/groups/keys); **CE-AU** is *how the principal is established*
  (credential exchange, token/claims, session). CE-AZ consumes the authenticated
  `TomPrincipal`; it does not model login.
- **CE-AZ ↔ CE-CF.** Per-requirement demands (roles/keys/graded tree) are CE-AZ; the
  global `TomResourceKeyProtection` on/off switches and the JWT/key material the check
  needs are **CE-CF** deployment config (already drawn in §5.5).
- **CE-AZ ↔ server-level grants.** A per-requirement demand (this operation needs
  role/key/entitlement X) is CE-AZ; which features the **server deployment
  itself** is granted is a server-level entitlement set carried by the server's
  own principal (§5.26). At CE-AZ evaluation the two meet: effective
  authorization = `min(user, server)` over the four-state levels, binary AND
  otherwise (§5.26).
- **CE-AZ is a modifier, not a standalone part** (§4.1 rule). It is authored **as an
  attribute** on the owning `@CsEndpoint` (operation-level) or on a CE-EL/CE-FM/CE-AC/
  CE-NV/CE-DB element (field-level graded/resource-key). Reuse only — no gap class.

**Placement.** Operation-level `@CsAuthorize` lives in `<app>_codespec_server` (on the
endpoint). Field-level graded/resource-key requirements ride their host part —
client for the CE-EL/CE-FM/CE-AC/CE-NV `authorizer`, server for the CE-DB column
`authKey`. The `TomAccessControl` requirement *type* itself is kernel, visible to both.

**SOM feed.** CE-AZ derives from **D08 SAS** (roles/permissions per operation and
per resource), per §8.

### 5.16 CE-CF / CE-CC / CE-DS / CE-UP config attribute surface + cross-scope source precedence

§5.5 fixes the CE-CF **model** and the four-scope split (CE-CF server / CE-CC
client-install / CE-DS user+device / CE-UP user); this section fixes the config
**attribute surface** (spec-authorable vs framework-internal, per scope) and the
**source precedence** — which source wins when the same logical key is
expressible at more than one scope.

**Config-surface split — what is spec-authorable, per scope.** A config *declaration*
(key · type · default · source) is spec-authorable; a config *value* (the deployed
secret, the user's chosen preference) is supplied at deploy/run time, never authored.

| Scope | Part | Spec-authorable (the declaration) | Value origin (not authored) | Framework-internal |
|-------|------|-----------------------------------|-----------------------------|--------------------|
| **Server / system** | CE-CF `@CsServerConfig` | typed setting fields (`appId`, `host`/`port`, `isolateCount`, `logLevel(s)`, `databaseMigrationsDirectory`, server feature flags); secret-bearing fields (`certificateChain`/`privateKey`, `jwtRsaPubKey`/`jwtRsaPrivKey`/`jwtSharedSecretKey`) declared **and marked secret**; per-field source key + precedence | deployment (config-tree/env/`.env`/cmdline) | middleware/handlers, `loggingMiddleware`, provider singletons, self-signed cert literals |
| **Client install** | CE-CC `@CsClientConfig` | setting `key` (dotted) · value type (`String`/`int`/`double`/`bool`) · declared default | client app config resources (`TomConfigResourceProvider`) **and** this install's persisted overrides (`TomClientConfigurationStore`) | `TomBaseClientConfiguration`'s declaration/baseline machinery, the coercion of loosely-typed external values, the store's write-then-rename |
| **User + device** | CE-DS `@CsDeviceSetting` | setting `key` · type · default | the user's persisted choice on this device (the device store) | the device-local, user-scoped store |
| **User** | CE-UP `@CsUserSetting` | setting `key` · type · default | the user's persisted choice (re-materialised via `TomGetSettings*`) | the `TomGetSettingsMessage`/`TomGetSettingsResult` round-trip, the server-side per-user persistence store |

The secret fields (TLS private key, JWT keys) are the exception to "declaration is
authored": their *presence and shape* are declared in CE-CF, but their **values are
never authored** — they are marked secret so §12 production-stripping and deployment
tooling supply them out-of-band.

**Source precedence — two orthogonal dimensions.**

1. **Intra-scope** (within one part, already fixed by the substrate):
   - CE-CF: `TomBaseServerConfiguration` merges **config-tree → OS env → `.env` →
     cmdline**, *cmdline wins* (§5.5). A field may opt to be pinned to one source.
   - CE-CC: `TomBaseClientConfiguration` resolves **this install's persisted
     override → the config-resources value → the declared default**. The lower
     two form the setting's *baseline*; a setting is *overridden* exactly when
     it differs from that baseline, and only overrides are persisted — so a
     default shipped in an app update still reaches installs that never touched
     the key.
   - CE-DS: **persisted device value → default**.
   - CE-UP: **persisted user value → default**.

2. **Cross-scope** (when *the same logical key* is declared at more than one scope):
   **most-specific-owner-wins**, but only for keys
   explicitly declared **overridable** at the narrower scope. Effective value =

   ```
   CE-DS (user+device, if declared device-overridable and set on this device)
     ▸ else CE-UP (user, if declared user-overridable and set)
       ▸ else CE-CC (client-install, if declared client-overridable and present)
         ▸ else CE-CF (server default)
   ```

   The precedence is **opt-in, not automatic**: a key is *scope-pinned* by default
   (visible only at its declaring scope, no cross-scope contest). A CE-CF key must
   explicitly declare itself client-overridable to be shadowable by CE-CC,
   user-overridable to be shadowable by CE-UP, and device-overridable to be
   shadowable by CE-DS. **Security / infrastructure config
   (TLS, JWT, DB migrations, worker counts, host/port) is CE-CF-only and declared
   non-overridable** — it can never be shadowed by a client install or a user, so no
   cross-scope contest arises for it. This makes the model **fail-safe**: broadening a
   value's blast radius is a deliberate authored act, never a default.

**Boundaries drawn.**
- **CE-CF ↔ CE-CC ↔ CE-DS ↔ CE-UP** are the same config-value concept at four
  owner-keyed scopes (§5.5); this section adds only the *precedence lattice*
  between them, it does not merge them.
- **CE-CF ↔ CE-AZ / CE-AU** (unchanged from §5.5): config supplies keys/material, not
  the access policy or the credential flow.
- The deeper CE-CC (`TomBaseClientConfiguration` + its store), CE-DS (device store) and CE-UP
  (server-side persistence) per-attribute surfaces are separate (§5.5); this
  section fixes the spec-authorable classification and the cross-scope precedence
  they operate within. The realisation annotations are `@CsServerConfig` /
  `@CsClientConfig` / `@CsDeviceSetting` / `@CsUserSetting` — one per scope.

**SOM feed.** CE-CF/CE-CC/CE-DS/CE-UP derive from **D06 ATS** (deployment
topology) + **D08 SAS** (which config carries secrets), per §8; the
user-facing settings scopes (CE-DS/CE-UP) additionally from **D09 XDS**
(preferences surfaced in UI).

### 5.17 CE-SU service-unit attribute surface under the §5.1 boundary

**Decision.** The **CE-SU** service-unit attribute inventory under the §5.1 boundary
criterion. The code basis
(`@CsServiceUnit` first-class marker on ordinary **(abstract) classes** that cluster
the server API into functional-group closures, carrying the `tom_core_server`
server-API mapping annotations `@tomService` / `TomApiImplementation` — **no new
class**, decision (h)) and the boundary rule are §5.6.2; §5.1 fixes the three-level
precedence. This section fixes *which attributes the spec author writes* versus
*which the ownership rule derives* — the distinction the boundary criterion makes
possible.

**Authored vs derived (the boundary's key consequence).** The §5.1 rule "a unit owns
exactly one aggregate, and thereby every CE-DB table/repository over it and every
CE-API operation whose primary written entity is in it" means membership is
**derived, not independently listed**. So the CE-SU attribute surface splits:

- **Authored (the spec input):** the *unit identity* and the *aggregate root* the
  author picks, plus the explicit *process-cohesion adjustments* and the *bounded
  context* that cap it. Everything the boundary needs and nothing more.
- **Derived (computed by the ownership rule at generation time):** the owned entity
  set, the owned repositories, and the owned operations — all follow from the root
  aggregate + the CE-DB placement (§5.13) + the CE-API primary-written-entity rule
  (§5.14). Listing them by hand would let the spec contradict the boundary; deriving
  them makes the boundary enforceable. The derived sets are materialised as **typed
  references** — entity/repository `Type` literals and CE-API `CsOperationRef`
  consts (§5.23) — never name strings; the unit itself is citable server-side by
  its `CsServiceUnitRef` const.

**CE-SU attribute surface (final, §5.1-grounded).**

| Attribute | Authored / Derived | Req? | Source rule | Neutral DocSpecs term |
|-----------|--------------------|------|-------------|-----------------------|
| **Unit id** (`<RootAggregate>Service`, PascalCase) | Authored | Y | §5.1 identification | Service unit (identity) |
| **Root aggregate** (root entity + lifecycle-dependent entities) | Authored | Y | §5.1 rule 1 · D03 IMO | Data entity (aggregate root) |
| **Process-cohesion adjustment** (merge two aggregates in one transaction / split one into independent processes) | Authored | D | §5.1 rule 2 · D02 TOM | Business process (grouping adjust) |
| **Bounded context** (outer cap — the architecture module the unit sits in) | Authored | Y | §5.1 rule 3 · D06 ATS | Architecture module (outer bound) |
| **Owned entities** (aggregate members) | Derived | — | §5.1 rule 1 | Data entity (ownership) |
| **Owned repositories** (CE-DB repos over the aggregate, §5.13) | Derived | — | §5.1 rule 1 | Query/Filter (ownership) |
| **Owned operations** (CE-API ops whose primary written entity ∈ aggregate, §5.14) | Derived | — | §5.1 rule 1 | Operation (membership) |
| **Component reference** (implementation binding) | Framework-internal | — | `TomComponentReference` | (not spec input) |

The `TomComponentReference(componentName/referencedType)` bean-wiring that the §2
inventory tentatively listed as a "D" attribute is **framework-internal** — how the
runtime resolves a service's implementation, not a boundary the author declares. It
drops from the spec surface (consistent with §5.14 dropping transport plumbing and
§5.16 dropping framework-internal config members).

**Cross-unit access (no new attribute).** A read spanning units is assigned to the
unit owning its **primary** entity, and a unit never reaches another unit's repository
directly — cross-unit data flows through the owning unit's CE-API (§5.1 ownership
rule). This is a *derivation constraint*, already fixed by §5.1; it adds no authored
attribute here.

**Boundaries drawn.**
- **CE-SU ↔ CE-DB** (§5.13): the unit *owns* the entities/repositories; CE-DB defines
  their shape. Ownership is by-aggregate (derived), not a duplicate entity list on the
  unit.
- **CE-SU ↔ CE-API** (§5.14): the unit *groups* operations; CE-API defines each
  operation's request/response. Membership is by primary-written-entity (derived).
- **CE-SU ↔ CE-AZ** (§5.15): authorization is a per-operation modifier (`@CsAuthorize`
  on `@CsEndpoint`), never a unit-level attribute — a unit is a grouping, not an
  access boundary.
- **Placement:** **server-only** (`<app>_codespec_server`, §4.2). The unit id is the
  server project's grouping key; clients see only the CE-API contract + CE-ST
  view-model, never the service-unit grouping.

**SOM feed.** CE-SU derives from **D07 IFS** (operations to group) + **D03 IMO**
(the aggregate that anchors the boundary) + **D02 TOM** (process cohesion) +
**D06 ATS** (the bounded-context cap), per §8.

### 5.18 CE-EL field-base + per-kind extras + the closed semantic→widget catalogue

**Decision.** The **CE-EL** screen-element attribute surface — the catalogue
*contents* over the two-step shape and `tom_core_codespecs` placement of §5.7.1
(on the `tom_flutter_ui` code basis, §1.1b). Three things are fixed: the **field-base** spec-authorable set, the **closed
semantic-kind catalogue** (each kind's default widget + per-kind extras), and the
**semantic→widget** two-step contents.

**Field-base attribute set (spec-authorable, every CE-EL element).** Over
`TomField<T>` (`tom_flutter_ui/forms/tom_form.dart`):

| Attribute | `tom_flutter_ui` source | Req? | Neutral DocSpecs term |
|-----------|-------------------------|------|-----------------------|
| **Element id** | `TomField.tomId` | Y | Field (identity) |
| **Semantic kind** | (catalogue key, below) | Y | Field kind |
| **Value type `T`** | `TomField<T>` | Y | Field (data type) |
| **Initial value** | `TomField` constructor argument (positional `_initialValue`, `tom_form.dart:596`; no public getter) | N | Field |
| **Label / hint / description** | copy overrides → **CE-TX** | N | Copy (→ text) |
| **Validators** | `TomField.validators` → **CE-VA** | N | Validation rule (attached) |
| **Authorization** | `TomField.authorizer` → **CE-AZ** field-level graded | N | Authorization requirement |
| **Auto-validate** | `TomField.autoValidate` | N | Field |
| **Owning form** | `TomField.form` → **CE-FM** membership | D | Form (membership) |

Framework-internal (never spec input): `uiStateController`, `focusNode`, `autofocus`,
`clipBehavior`, prefix/suffix icon widgets, styling (`ButtonStyle`/`TextStyle`/
`StrutStyle`), `scope`/`basePath` resolution, listenables, the `widget` getter.

**Derived back-references (never authored).** The field's inline action hook
(`actionIcon`/`actionIconTooltip`/`onActionIconPressed`) and a Button's or
MenuEntry's action edge are **derived** from the §5.20 triggers that cite the
element — the trigger, whose endpoints are typed references (§5.20, §5.23), is
the **single authoring home** of the element→action edge (§5.10); the element
side only *renders* it.

**Closed semantic-kind catalogue.** The element-type catalogue
(a **documented catalogue over the reused `Tom*` widgets — no new class**, §5.7.1)
has this **closed** entry set. A spec
names the *semantic* kind; the catalogue supplies the default widget; the per-kind
column is the extra spec-authorable attributes that kind adds to the base:

| Semantic kind | Authoring home | Value `T` | Default `tom_flutter_ui` widget | Per-kind spec attributes | Neutral term |
|---------------|----------------|-----------|--------------------------------|--------------------------|--------------|
| **TextInput** | form-member | `String` | `TomTextField` | `maxLength`, `keyboardType`, `maxLines`, `obscureText` | Field kind (text) |
| **Number** | form-member | `int`/`double` | numeric `TomTextField` | `minValue`, `maxValue`, `decimals` (double only) | Field kind (numeric) + Validation rule |
| **Toggle** | form-member | `bool` (`bool?` when `tristate`) | switch/checkbox | `tristate` | Field kind (boolean) |
| **DateInput** | form-member | `DateTime` | date picker | `firstDate`, `lastDate` (bounds) | Field kind (date) + Validation rule |
| **Choice** | form-member | `enum`/object | dropdown/select | `source` (option provider, required) | Field kind (single choice source) |
| **MultiChoice** | form-member | `List<…>` | multi-select | `source` (required), `minSelections`/`maxSelections` (→ CE-VA `minItems`/`maxItems`) | Field kind (multi choice source) |
| **Label** | standalone | — (read-only) | `TomText` | `text` (→ CE-TX) | Copy display |
| **Button** | standalone (also in-form, e.g. submit) | — (interactive) | a `TomButtonBase` variant (`TomElevatedButton` / `TomFilledButton` / `TomTextButton` / `TomOutlinedButton` / `TomIconButton`) | `variant` (primary/secondary/… — selects the concrete class; tokens in `TomButtonVariants`), `icon` | Action element |
| **MenuEntry** | standalone | — (interactive) | menu-entry widget | owning menu/surface ref, `position` | Action element (menu) |
| **FormHost** | standalone | — (container) | form-hosting container | **CE-FM** form reference | Form placement |

The **six input kinds** (TextInput, Number, Toggle, DateInput, Choice,
MultiChoice) are **form-member kinds** — authored inside their owning CE-FM form
(§5.7); Label, Button, MenuEntry and FormHost are **standalone** kinds. A
Button's or MenuEntry's action edge is not a per-kind attribute — it rides the
§5.20 trigger (derived back-reference, above). A **purely navigational** menu
entry stays CE-NV (`TomNavigationDestination`, §5.11) — MenuEntry covers
**action-triggering** entries. **FormHost** mirrors the CE-LO slot→element
separation (§5.2): the layout slot references the FormHost element; the FormHost
references the CE-FM form it places on the screen.

**`tristate` widens the Toggle's value type.** A two-state `Toggle` is a
`TomFormBoolField` over `bool`; a tristate one is a `TomFormNullableBoolField`
over `bool?`, where `null` is the indeterminate state
(`TomFormNullableBoolCheckbox` / `TomCupertinoFormNullableBoolToggle`,
`FormFieldFamily.nullableBoolToggle`). The attribute therefore selects the
field class rather than merely configuring one — the only per-kind attribute
in this catalogue that does.

Object/nested and repeated form-typed fields are **not** element kinds — they are
CE-FM subforms (§5.7.2). The catalogue is closed: a new semantic kind is a catalogue
edit, not a free-form spec attribute, which keeps every spec's element vocabulary
finite and enforceable.

**Semantic→widget two-step (contents).** The default-widget column above is the
*default* binding; `@CsWidget` may override it per element (a `Choice` rendered as a
radio group instead of a dropdown, etc.). The **meaning** (semantic kind + `T` +
copy + validators + authorization) is authored on `@CsElement` once; the **rendering**
is the separable `@CsWidget` binding — mirroring CE-LO slot→element and CE-SC
action→operation (§5.2/§5.3).

**Boundaries drawn.**
- **CE-EL ↔ CE-VA** (§5.9): validators are *attached* to the field; the rule shapes
  live in CE-VA. Per-kind numeric/date bounds (`minValue`/`firstDate`) and the
  MultiChoice selection counts (`minSelections`/`maxSelections` → `minItems`/
  `maxItems`) are convenience field attributes that *desugar* to CE-VA field
  rules — one authoring surface, no duplication.
- **CE-EL ↔ CE-TX** (§5.8): label/hint/description/`Label.text` are copy references,
  authored once in CE-TX.
- **CE-EL ↔ CE-AZ** (§5.15): `authorizer` is a field-level graded-access modifier, not
  an element attribute of its own.
- **CE-EL ↔ CE-AC** (§5.10, §5.20): the element→action edge is authored **once on
  the trigger**, which carries both endpoints; the element side (Button, MenuEntry,
  inline action-icon) is a derived back-reference, never authored.
- **CE-EL ↔ CE-ST** (§5.4): a field's value binds to the view-model; that binding is
  the CE-ST concern.
- **Placement:** **client** (`<app>_codespec_client`, §4.2); no new class — the
  catalogue is documented over the reused `TomScreenElementsProvider` + `Tom*`
  widgets (§5.7.1).

**SOM feed.** CE-EL derives from **D09 XDS** (screens / elements / forms) +
**D05 ISC** (scenarios naming screens), per §8.

### 5.19 CE-VA field-rule / form-rule attribute surface + validator declaration language

**Decision.** The **CE-VA** validation attribute surface — the field-rule /
form-rule attribute sets and the **validator declaration language** — over the
`tom_flutter_ui` substrate mapped in §5.9. §5.9 fixes the bases
(`@CsValidation`/`@CsFieldRule`/`@CsFormRule`), the field-vs-form split, and the
CE-TX/CE-ER error-key tie; this section fixes *which attributes each rule carries*
and *how a rule is declared*.

**Field-rule attribute surface (final).** A `@CsFieldRule` validates one field in
isolation (`Validator<T> → ValidationResult`, §5.9):

| Attribute | `tom_flutter_ui` source | Req? | Neutral DocSpecs term |
|-----------|-------------------------|------|-----------------------|
| **Rule kind** | one of the closed built-in catalogue (below) or a registered custom name | Y | Validation rule (field rule kind) |
| **Rule arguments** | the factory args of the kind (e.g. `minLength(int)`, `pattern(RegExp)`, `min(num)`) | Y (per kind) | Validation rule (args) |
| **Error key on fail** | spec-level a typed `CsMessageKey`/`CsErrorCode` const (§5.23); the runtime `ValidationError.errorKey` string (+ `params`) is the generated lowered form → **CE-TX/CE-ER** | Y | Error code (→ text) |
| **Async / slow** | `SlowValidator<T>` → `ValidationPending` | N | Validation rule (async) |

**Closed built-in field-rule catalogue** (over `Validators`, §5.9): `required`,
`email`, `minLength`, `maxLength`, `pattern`, `min`, `max`, `minItems`,
`maxItems`, `compose`. This is the closed standard set; a project-specific rule
is a **registered custom name** (a `Validator<T>` added to
`TomValidatorRegistry`), not a free-form attribute — same
closed-catalogue-plus-registration discipline as the §5.18 element catalogue.
All ten are carried by `Validators` (verified, §4.1.2), but **`compose` is not
a declarable token**: `TomValidatorRegistry._registerBuiltins()` registers the
other nine, and composition is the implicit semantics of the comma list below —
a declaration never writes `compose:…`.

`minItems`/`maxItems` bound a collection's **size** rather than a value; they
are typed over `Iterable<Object?>` so, by function contravariance, one rule
serves `TomField<List<String>>`, `TomField<List<int>>` and any other
collection-valued field. They are the desugaring target of the §5.18
MultiChoice `minSelections`/`maxSelections` attributes.

**Validator declaration language (final).** Over
`TomValidatorRegistry` (`resolve`/`resolveSpec`/`resolveDeclaration`/`parseSpec`), a
field's rule set is authored as a **declaration string**:

- **Grammar:** a comma-separated list of rule tokens; each token is `<name>` or
  `<name>:<arg>` or `<name>:<arg1>:<arg2>…`. Whitespace around separators is
  insignificant. Example: `required, minLength:8, pattern:^[A-Z]`.
- **Resolution:** each `<name>` resolves through `TomValidatorRegistry` to a
  `Validator<T>`; args are parsed by the registered spec parser (int / string / regex
  literal per the rule kind). An unresolved name is a spec error at generation time —
  the registry is the closed vocabulary the declaration draws from.
- **Composition:** multiple tokens compose (all must pass, `Validators.compose`
  semantics); order is authoring order. The declaration string is the **field rule**
  authoring surface; it does not express cross-field rules.

**Form-rule attribute surface (final).** A `@CsFormRule` validates across fields (a
cross-field invariant → `FormValidationError`, §5.9):

| Attribute | `tom_flutter_ui` source | Req? | Neutral DocSpecs term |
|-----------|-------------------------|------|-----------------------|
| **Involved fields** | `FormValidationError.fields` / `tomIds` — the CE-EL element ids the rule spans | Y | Validation rule (form rule scope) |
| **Rule reference** | a named cross-field predicate (registered like a field rule, but over the form's field set) | Y | Validation rule (form rule kind) |
| **Cross-field error key** | spec-level a typed `CsMessageKey`/`CsErrorCode` const (§5.23); the runtime `FormValidationError.errorKey` string is the generated lowered form → **CE-TX/CE-ER** | Y | Error code (→ text) |
| **Per-field error keys** | `FormValidationError.fieldErrorKeys` (which field each cross-field failure marks) | N | Field-level error |

A form rule is **not** part of the per-field declaration string — it is authored on
the `@CsForm` (§5.7.2) as {involved field ids + rule reference + error key}, because it
spans fields the string grammar cannot name.

**Boundaries drawn.**
- **CE-VA ↔ CE-TX / CE-ER** (§5.8, §5.9): every error key is a message key resolved
  through the CE-TX registry, keyed where appropriate by a CE-ER code — author-copy-once.
  CE-VA never carries a literal message.
- **CE-VA ↔ CE-EL** (§5.18): field rules attach to a CE-EL element; the §5.18 per-kind
  numeric/date bounds (`minValue`/`firstDate`) **desugar** to `min`/`max` field rules,
  and the MultiChoice selection counts (`minSelections`/`maxSelections`) to
  `minItems`/`maxItems` — one authoring surface, no duplication.
- **CE-VA ↔ CE-FM** (§5.7.2): form rules live on the form; the subform tree fans out
  validation (already substrate-backed).
- **Placement:** **client + shared** (§4.2) — the rules the client enforces are part of
  the shared contract the server re-checks; **no new class** — the field/form rules are
  Dart validation methods (standalone validators or methods on the `TomForm` subclass,
  §5.9).

**SOM feed.** CE-VA derives from **D04 RSP** (requirements) + **D03 IMO** (attribute
constraints), per §8 — field rules from attribute constraints, form rules from
cross-field requirements, each rule tracing back to the requirement that mandates it.

### 5.20 CE-AC action + trigger-taxonomy attribute surface over TomAction

**Decision.** The **CE-AC** attribute surface — the `@CsAction` attribute set and
the per-kind **trigger** attributes — over the `tom_flutter_ui` action substrate
mapped in §5.10. §5.10 fixes the
bases (`@CsAction` + `@CsTrigger`) and the closed **5-kind** trigger taxonomy as a
**documented classification over the reused action classes — no new class**; this
section fixes *which attributes the action and each trigger kind carries* — the
trigger taxonomy is a **documented framing** (`TomAction` has no trigger concept),
so this surface is authored, not read off a framework field.

**`@CsAction` attribute surface (final).** Over `TomAction<TContext, TUndo>` (§5.10):

| Attribute | `tom_flutter_ui` source | Req? | Neutral DocSpecs term |
|-----------|-------------------------|------|-----------------------|
| **Action id** | `TomAction.actionId` | Y | Action (identity) |
| **Owning controller** | `TomAction.controller` → canonical path `<controllerId>.<actionId>` | Y | Action (membership) |
| **Context requirement** | `TContext extends TomActionContext` (domain data + scope the action needs) | Y | Action (input) |
| **Undoable + undo state** | `isUndoable` / `TUndo` / `undo()` | N | Action (reversibility) |
| **Transaction grouping** | `TomActionTransaction` (atomic-undo unit) | N | Action (atomic group) |
| **Authorization** | `authorizer` → **CE-AZ** | N | Authorization requirement |
| **Copy** | label / tooltip / icon → **CE-TX** | N | Copy (→ text) |
| **Server-bound edge** | a typed `CsCallRef` const to a `@CsServerCall` → **CE-SC** (§5.3 two-hop, §5.23) | N | Server interaction |

Framework-internal (never spec input): `scope`/`tomGroup`, `authState`/
`effectiveAuthState`, `TomActionController._actions`, event plumbing. The
`canExecute(context)` guard is not an authored *action* attribute — it surfaces as the
**condition** trigger kind (below).

**Trigger attribute surface (designed gap).** A
`@CsTrigger` names *how* an action is invoked; one `@CsAction` may carry **several**
triggers (§5.10 "one action, several triggers"). The trigger is the **single
authoring home** of the element→action edge (§5.10): it carries a **common**
head — {target action ref; trigger kind (one of the closed 5); an optional guard
predicate over CE-ST state} — plus the **per-kind** attributes:

| Trigger kind | Per-kind spec attributes | `tom_flutter_ui` realization | Neutral term |
|--------------|--------------------------|------------------------------|--------------|
| **user-gesture** | source **CE-EL** element ref (Button / MenuEntry / inline action-icon, §5.18) + gesture (tap / press / long-press) | `TomActionTrigger` (`onPressed`/`onTap`) | Trigger (user gesture) |
| **in-form event** | owning **CE-FM** form ref + form-event {field-change / submit / validation-pass / validation-fail} + optional field ref | `TomForm` event source | Trigger (form event) |
| **lifecycle** | scope {screen / route / app} + phase {enter / leave / init / dispose} | route / app lifecycle hook | Trigger (lifecycle) |
| **server-event** | inbound event / channel ref + event type | server push / notification | Trigger (server event) |
| **condition** | reactive predicate over **CE-ST** observable state (the `canExecute` case) + re-evaluation source | `canExecute` over observable state | Trigger (condition) |

The taxonomy is **closed**: a new invocation path is an edit to the documented
trigger classification (over the reused `tom_flutter_ui` action classes), not a
free-form attribute — the same closed-catalogue discipline as §5.18 (elements) and
§5.19 (validation rules).

**Typed endpoints (compiler-checked).** A trigger's endpoints are **typed
references to the generated declarations** (the §5.23 typed-reference model —
this edge is its canonical instance): the generated `@CsTrigger` cites the
source element's generated class/member and the target action's `CsActionRef` /
`TomAction` subclass (const/type reference), never an id String. Phase-4 output
is compilable Dart, so endpoint existence and `TContext` type compatibility are
**compiler-enforced** — a rename is a compile break, not a silently dangling id.

**Boundaries drawn.**
- **CE-AC ↔ CE-SC** (§5.3): a triggered action drives a server call through the
  explicit two-hop CE-AC→CE-SC→CE-API edge. `@CsAction` carries the *what* + trigger;
  `@CsServerCall` carries the *how* (operation + request/response).
- **CE-AC ↔ CE-EL** (§5.18): the trigger carries **both endpoints** (source
  element + gesture, target action); the element's action edge is **derived**,
  never authored — single authoring home, no duplication.
- **CE-AC ↔ CE-FM** (§5.7.2): in-form-event triggers ride the form event source.
- **CE-AC ↔ CE-ST** (§5.4): the condition trigger and the common guard are predicates
  over observable view-model state.
- **CE-AC ↔ CE-AZ / CE-TX** (§5.15, §5.8): authorization and copy are the action's
  modifiers, authored once in their own parts.
- **Placement:** **client** (`<app>_codespec_client`, §4.2); no new class — the
  trigger classification is documented over the reused `tom_flutter_ui` action
  classes (§5.10).

**SOM feed.** CE-AC derives from **D05 ISC** (scenarios / processes name the actions
+ their triggers + transitions) + **D02 TOM**, per §8.

### 5.21 CE-TX message-key / i18n attribute surface + error copy keyed by CE-ER codes

**Decision.** The **CE-TX** attribute surface — the per-message-key attribute set,
the locale model, and the error-copy keying — over the substrate mapped in §5.8
(with the CE-ER error-code source of §5.14 and the `tom_flutter_ui` basis). §5.8 fixes the `@CsText` reuse basis, the
**derived-vs-catalogued** two-source model, the `tom_core_codespecs` message/i18n-key
catalogue placement, and the shared(keys)+client(copy) split; this section fixes
*which attributes a catalogued message key carries* and *how error copy binds to
CE-ER codes*.

**Two-source recap (§5.8).** A text is either **derived** (a *screen element*'s
placeholder / label / help / error copy, resolved from the element's `basePath` —
`tomId` + route scope + form scope — plus a per-role suffix, per decision (e); the
`basePath` keys are also the CE-AZ authorization keys, §5.15) or **catalogued** (a
message key in the CE-TX message/i18n-key registry, resolved by
`TomTextResourceProvider`). This attribute surface applies to the **catalogued**
shape — the **all-*other*-texts** namespace (server / error copy, notification &
email bodies, report copy). Derived element texts carry **no** CE-TX catalogue
entry: their `basePath` + suffix *is* the key, and the SOM content is the copy.

**Message-key attribute surface (final).** Over `TomTextResourceProvider` +
`TomText`/`TomLabelBase` (§5.8):

| Attribute | source | Req? | Neutral DocSpecs term |
|-----------|--------|------|-----------------------|
| **Message key** | dotted key (`app.form.amount.label`), resolved tree-walk-first then flat | Y | Message key (identity) |
| **Base copy** | the base-locale string (`texts` map / MSGKR default) | Y | Copy (base) |
| **Role** | one of {error, notification, email, report, generic} — the catalogued copy's kind (element-slot copy is `basePath`-derived, §5.8, not catalogued here) | Y | Copy (by role) |
| **Category** | **UI copy** vs **error copy** (the latter is CE-ER-keyed, below) | Y | Message key (category) |
| **Parameters** | named placeholders (`ValidationError.params` / `ErrorResult` field details) interpolated into the copy | N | Copy (params) |

Framework-internal (never spec input): provider singletons, the dotted-path resolution
algorithm, style objects, loader wiring.

**Declaration vs citation (§5.23).** The MSGKR declares each **catalogued** key
**once** as a `CsMessageKey` const (error copy: the `CsErrorCode` const) carrying the
dotted string; citing parts — CE-AC copy (§5.20), CE-VA error keys (§5.19) — hold the
const. The dotted string form exists only inside the declaration and in the generated
runtime lookup. (Derived element copy, §5.18, cites no MSGKR const — its `basePath` +
role suffix resolves directly against `TomTextResourceProvider`.)

**Locale model (final).** The i18n surface over `TomTextResourceProvider`:

- **Per-locale copy map** — for each message key, a base-locale string plus optional
  per-locale overrides (the provider's `texts` map keyed by locale).
- **Base / fallback locale** — one base locale is required (the authored default); a
  missing per-locale entry **falls back** to the base, never to the raw key.
- **Resolution** — tree-walk-first then flat-key (the provider's existing algorithm);
  an unresolved key is a **generation-time spec error** (the MSGKR is the closed key
  vocabulary), not a silent raw-key render.

**Error copy keyed by CE-ER codes (the cross-part tie).** Error copy is
**not** a free literal and **not** an ad-hoc UI key — it is keyed by the structured
**CE-ER error code** (§2 CE-ER, §7):

- Each CE-ER code has **exactly one** copy entry in the CE-TX message-key registry
  (MSGKR, §5.8) — the error-copy namespace *is* the CE-ER code namespace. Authoring
  the code (server) and its copy (client) is author-copy-once across both sides (§5.8).
- A CE-EL element's `resolveErrorMessage` and a CE-VA rule's `ValidationError.errorKey`
  (§5.19) both resolve through the **same** CE-ER-keyed MSGKR entry; the
  `ErrorResult` field-level details supply the copy **parameters**.
- The error-copy **keys are shared** (`<app>_codespec_shared` — the server emits the
  code, the client resolves it), the **copy strings are client** (`<app>_codespec_client`).

**Boundaries drawn.**
- **CE-TX ↔ CE-ER** (§7): error copy keys = CE-ER codes; CE-TX owns the copy,
  CE-ER owns the code + structured details. One source.
- **CE-TX ↔ CE-EL** (§5.18): a screen element's labels/hints/descriptions/error copy
  are **`basePath`-derived, not catalogued** (decision (e)) — CE-TX owns no key for
  them; the element's `basePath` + role suffix *is* the key (also the CE-AZ key, §5.15).
- **CE-TX ↔ CE-AC** (§5.20): action copy that is not element-owned is a catalogued
  message-key *reference*; CE-TX owns the key + copy.
- **CE-TX ↔ CE-VA** (§5.19): validation error keys route through the CE-ER-keyed MSGKR.
- **CE-TX ↔ CE-CF** (§5.5): copy lives in `TomTextResourceProvider`, config in
  `TomConfigResourceProvider` — distinct resource trees, no overlap.
- **Placement:** **keys shared** + **copy client** (§4.2) — the one part that spans two
  projects; the message/i18n-key catalogue class lives in `tom_core_codespecs` (§5.8).

**SOM feed.** CE-TX derives from **D09 XDS** (screens / elements / forms) + SOM
`@ContentHelp`/`@Form` hints / doc-comments (literal copy) + **CE-ER codes** (error
copy), per §8.

### 5.22 CE-LO layout-node attribute surface + override-delta grammar

**Decision.** The **CE-LO** attribute surface — the per-node attribute set
(container + slot) and the **manual-override delta grammar** — over the two-layer,
id-addressed model of §5.2, grounded on the ACL substrate in §5.12. §5.12 fixes the node kinds' substrate; this
section fixes *which attributes each node kind carries* and *the closed set of
override deltas*.

**Container-node attribute surface (final, layout-only).** Over `AclRow`/`AclContainer`
(§5.12):

| Attribute | ACL source | Req? | Neutral DocSpecs term |
|-----------|-----------|------|-----------------------|
| **Container kind** | closed set {row, column, wrap, stack, flex, grid, padding, align, sizedBox} | Y | Layout node (container kind) |
| **Ordered children** | `AclRow.components` / `AclContainer.rows` | Y | Layout node (children) |
| **Main / cross alignment** | `AclRow.alignment` + cross-alignment | N | Layout node (alignment) |
| **Spacing / gaps** | `gapBefore` / `defaultAppendGap` / `isGapRow` | N | Layout node (spacing) |
| **Padding / constraints** | `padding` + `AclFlags` (expandX/Y, sizing) | N | Layout node (box) |
| **Presentation** | `scrollableX/Y`, `borderStyle`, `backgroundColor` | N | Layout node (presentation) |

A container carries **only** layout properties — no semantics (§5.2). The kind set is
**closed** (Flutter-faithful primitives): a new primitive is a node-model edit, not a
free-form attribute — same discipline as §5.18/§5.19/§5.20.

**Substrate reconciliation pending (`csexb2`, §4.1.2).** The kind set is the only
row of this table with no ACL source, and it is **not yet renderable in full**:
an `AclContainer` is an ordered list of `AclRow`s (*row* = `AclRow`, *column* =
the row list) and `AclContainer.direction` is `AclDirection.ltr`/`rtl` — text
direction, not a main-axis switch. *padding* / *align* / *sizedBox* are
container/slot **properties** rather than node kinds; *wrap*, *stack*, *flex*
and *grid* have no ACL counterpart. `csexb2` decides between narrowing the set
to ACL-renderable kinds and extending the ACL substrate.

**Slot-node attribute surface (final, reference + hints).** Over `AclComponent`
(§5.12) — the leaf that *references* a semantic element and holds only per-slot hints:

| Attribute | ACL source | Req? | Neutral DocSpecs term |
|-----------|-----------|------|-----------------------|
| **Referenced element** | `AclComponent.child` → **CE-EL** element id / **CE-FM** (sub)form id | Y | Layout node (references field/form) |
| **Flex / sizing** | `preferredSize` / `minimumSize` / `maximumSize` + expand flags | N | Layout node (per-slot sizing) |
| **Alignment anchors** | `alignXToKey` / `alignYToKey` + axis points (id-addressed) | N | Layout node (anchored alignment) |
| **Gap** | `gapBefore` | N | Layout node (spacing) |

The slot holds a **reference by stable id**, never the element definition — the CE-EL/
CE-FM part owns the content and behaviour (§5.2 semantics↔layout split).

**Node identity + responsive (final).** Every node carries a **stable node id** — a
slot id derives from its referenced element/form id; a container id is a stable
synthetic id preserved across regeneration by structural matching (§5.2). Responsive
variants (`variants`/`breakpoints`) are a node attribute; the layout rebinds to CE-ST
state via `TomObservingWidget` (§5.12) — responsive/visibility is a CE-ST-driven
rebind, not a static attribute.

**Override-delta grammar (manual-override separation).**
The two layers are never one hand-edited tree (§5.2): a **generated base** (rebuilt
from the SOM every build, never hand-edited) plus a separate **authored override
layer** of id-addressed deltas. The override layer is a **closed set of delta
operations**, each targeting a **node id**:

| Delta op | Effect | Target |
|----------|--------|--------|
| **reparent** | move a slot/container under a different container | node id |
| **set-container-prop** | change a container's kind / direction / alignment / spacing / padding | container id |
| **set-slot-hint** | change a slot's flex / sizing / alignment anchor / gap | slot id |
| **insert-container** | add a new container node | parent id + position |
| **remove-container** | drop a container (children reflow to parent) | container id |

- A delta is a **patch**, not a replacement tree; on regeneration the base is rebuilt
  and the deltas are re-applied by id (§5.2).
- A **new** SOM element appears in the base and flows to its **default slot** (default
  base = a single `column` of the form's fields in SOM order) until an override moves it.
- A delta whose target id **no longer exists** is surfaced as a **reconcile warning**,
  never silently dropped — manual layout survives model changes non-destructively.

**Boundaries drawn.**
- **CE-LO ↔ CE-EL / CE-FM** (§5.18, §5.7.2): a slot *references* an element/form by id;
  the layout tree never embeds the definition.
- **CE-LO ↔ CE-ST** (§5.4, §5.12): responsive/visibility rebind is CE-ST-driven; the
  layout carries the variant breakpoints, CE-ST carries the state.
- **CE-LO ↔ SOM** (§8): the base structure is derived from D09 XDS; the override layer
  is **authored, not derived** (join key `@SectionId`).
- **Placement:** **client** (`<app>_codespec_client`, §4.2); the override-separable
  node-model class lives in `tom_core_codespecs` (§5.12), emitting an ACL tree at
  render time.

**SOM feed.** CE-LO base structure derives from **D09 XDS** (screen/form layout) +
**D05 ISC** (screen naming), per §8; the override layer is authored.

### 5.23 Typed cross-part references — the `Cs*Ref` const family

**Decision.** Every cross-part reference edge **inside CodeSpecs code** is a
**Dart const reference or `Type` literal — never a string literal**. The part
that owns a referenceable element declares its identity **exactly once** as a
`static const` on that part's generated catalogue class; every citing annotation
holds the typed const. A dangling or renamed reference is a **compile error** —
the Dart compiler is the §4.2 cross-part integrity checker. This *strengthens*
(does not replace) the "reference, never containment" semantics of §5.2/§5.3:
the **stable string id still exists**, authored once **inside** the const — it
is what §9.2/§9.3 serialization and SOM `codeSpec` tracing carry — but
citations hold the const, never a copy of the string.

**The ref family.** A small **closed** set of const value types in
`tom_code_specs`, beside `DocRef` (annotation-parameter vocabulary — Dart
annotations may hold const objects, so the family respects the
annotations-only rule, §4.1):

| Ref type | Owner part | Locus (§4.2) | Cited by |
|----------|-----------|--------------|----------|
| `CsOperationRef` | CE-API | shared | CE-SC `operation` (§5.3/§5.14); CE-SU derived operation sets (§5.17) |
| `CsCallRef` | CE-SC | client | CE-AC server-bound edge (§5.3 hop 1, §5.20) |
| `CsActionRef` | CE-AC | client | `@CsTrigger` target (§5.20); CE-EL derived back-references (§5.18) |
| `CsRouteRef` | CE-NV | client | CE-AC navigation outcomes (§5.11); CE-SC response handling (§5.3) |
| `CsMessageKey` | CE-TX | shared | CE-EL/CE-AC copy references (§5.18/§5.20); CE-VA error keys (§5.19) |
| `CsErrorCode` | CE-ER | shared | CE-TX error-copy entries (§5.21); CE-VA rule failures (§5.19) |
| `CsRoleRef` / `CsResourceKeyRef` | CE-AZ (role / resource-key catalogues) | shared | `@CsAuthorize` role and resource-key requirements, field-level `authKey` (§5.15) |
| `CsServiceUnitRef` | CE-SU | server | server-side grouping references (§5.17) |
| `CsReportRef` | CE-RP | server (definition holder) | CE-JB scheduled work references (§5.28) |
| `CsJobRef` | CE-JB | server | job citations (§5.29) |
| — (entities / DTOs) | CE-DB / CE-API | per §4.2 | **`Type` literals** — entities and request/response DTOs are already Dart types; no ref const is needed |

Every part's definition holder is **typed from the start** — there is no
string-reference interim form for any part.

**Distinct types, not one generic `CsRef`.** Passing a route ref where an
operation ref is expected must itself be a compile error — cross-*kind* misuse
is type-checked, not convention-checked.

**Locus follows the §4.2 dependency arrows.** Shared-owned referents
(operations, error codes, message keys, roles/resource keys) are citable from
both sides; client-owned referents (routes, actions, calls) only client-side;
server-owned referents (service units, report/job definitions) only
server-side. The parts stay cleanly separated with **reference-only coupling**.

**Declaration vs citation.** The owning part's generated **catalogue class**
declares each referenceable identity once (e.g.
`static const login = CsOperationRef('login');`). The stable string id lives
inside the const and surfaces only in §9.2/§9.3 serialization, SOM `codeSpec`
tracing, and generated **lowered** runtime forms (`ValidationError.errorKey`,
`TomServerCallSpecs.url`, `TomRoleAccess.roles`, the dotted
`TomTextResourceProvider` keys). Spec-level code never repeats the string.

**Exemptions (normative — these stay strings, validator-checked per §12).** A
reference is exempt exactly when the referent is **not a Dart declaration**;
integrity then comes from the analyzer/validator instead of the compiler:

1. **CE-CF / CE-CC / CE-DS / CE-UP setting keys** — the dotted resource-provider paths —
   and their env-var / cmdline-flag aliases (§5.5, §5.16): runtime resource
   paths into deployment-supplied trees.
2. **Deployment-environment names** — the environment-tag vocabulary config
   values and migration artifacts are filtered by (§5.16): deployment
   vocabulary, not code.
3. **CE-MG migration artifact filenames**: SQL artifacts, not Dart; the named
   schema-convergence validator check is the integrity mechanism.
4. **Doc-side `codeSpec` locations and `@DocSpec` SOM section ids**
   (§9.2/§9.3): documents are not compiled; already validator-checked.

### 5.24 CE-ID identity-attribute extensions over the fixed principal core

**Decision.** CE-ID models the **app-declared identity-attribute extensions**
riding on the framework-fixed principal: `@CsIdentity` marks the app's one
identity-extension declaration holder; `@CsIdentityAttribute(placement:
public|encrypted)` marks each declared extension attribute (the same
member-marker pattern as `@CsColumn`). Locus **shared + server**: the extension
declaration is contract — both sides read attributes from the token — while
population happens in the CE-AU server flow. Kind value: `identity`.

**Built-on survey — the public/encrypted split already exists in `tom_core`.**

1. **The principal core is framework-fixed.** `TomUser` (fixed identity fields:
   username, names, email, phone, address, timeZone) wrapped by `TomPrincipal`
   (authenticated session: user + ACI + CLI + tenant coordinates + 2FA +
   locale), both `tom_core_kernel` (`user_principal_aci.dart`). The ~20 runtime
   fields are **not spec input** — consistent with the §5.15
   framework-internal ruling.
2. **Public extension carrier: `TomUser.attributes`**
   (`user_principal_aci.dart:713`, `Map<String, Object?>`). It rides in the
   **public** token payload under `"attributes"`, guarded field-level by
   `tomProtect(…, "tom.user.attributes")` resource keys
   (`bearer_authentication.dart:454–458`).
3. **Encrypted extension carrier: `TomPrincipal.currentContext`.** The token
   projection `TomBearerAuthentication.convertPrincipalToTokenPayload`
   (`bearer_authentication.dart:381`) returns `(publicInfo, privateInfo)`;
   `privateInfo` = `{context, groups, roles, entitlements, resourceKeys,
   resourceRoles}` and rides **encrypted** in the authorization JWT
   (`TomServerJwtToken(publicInfo, encryptedData: privateInfo)`,
   `authentication_server.dart:302`).
4. **No new class — an ordinary class carried as JSON via reflection**
   (decision (i)). Both carriers are untyped `Map<String, Object?>`; the app
   models its profile extension as a **normal class** (naming each extension
   attribute, its type, its placement public|encrypted and its access guard),
   **directly reusable** and serialized **as JSON via reflection** into the
   user-profile carrier. No `tom_core_codespecs` gap class is introduced — the
   typing comes from an app-authored ordinary class, not a framework type.

**Spec-authorable surface.** Per declared extension attribute: **name · type ·
placement (public | encrypted) · access guard** (resource key for public
attributes — the `tomProtect` mechanism; encrypted attributes are readable
only by the token-decrypting layers) **· source** (system of record) **·
required**. The ACI *content* (which roles/groups exist per deployment) stays
admin/deployment data, not spec input (the §5.15 boundary). The SOM's
descriptive identity sections (user categories, lifecycle, service accounts)
remain authored documentation mapped to `identity`; they generate no code
beyond the extension surface.

**Boundaries.**

- **CE-ID ↔ CE-AU.** CE-ID declares *what the identity carries*; CE-AU is *how
  the principal is established* and performs the public/encrypted token
  projection. CE-AU consumes CE-ID. User-**profile** data is CE-ID identity
  attributes (mostly `placement: public`), surfaced through CE-AU.
- **CE-ID ↔ CE-AZ.** CE-AZ requirements evaluate against the principal's ACI,
  which stays framework-internal; CE-ID does not open ACI to spec authoring.
- **CE-ID ↔ CE-UP.** Identity attributes describe *who the user is* and travel
  in the token; user settings are *changeable preferences* and live in the
  settings store (CE-UP). Token-vs-settings-store transport is the practical
  discriminator.
- **CE-ID ↔ CE-DB.** Server-side persistence of user records is the identity
  provider's own CE-DB concern (tom_uam is the reference implementation), not
  CE-ID spec surface.

**SOM feed.** D08 SAS, the user-management family — the per-attribute
authoring form is `UserAttributeEntry` (USATE), which carries
name/dataType/placement/accessGuard/source/required, covering the full
spec-authorable surface. Join key is the SOM `@SectionId` (§8).

### 5.25 CE-AU authentication — framework-fixed mechanics, spec-authorable policy surface

CE-AU is **pure reuse of the `tom_core` authentication stack — no gap class**.
The authentication *mechanics* are framework-fixed; what a CodeSpec authors is
the *policy surface*: which service backs authentication, which methods and
flows are enabled, and which session/token/credential policies apply. The
single marker is `@CsAuth`; methods, flows, and policies are its attributes,
not separate parts.

**Framework-fixed mechanics** (not spec-authorable; the framework owns them):

1. **Two-token JWT model.** `TomAuthenticationServer` projects the
   authenticated principal via `convertPrincipalToTokenPayload` into a
   `TomServerJwtToken` with a public part (`publicInfo`) and an encrypted part
   (`encryptedData: privateInfo`) readable only by the token-decrypting layers.
2. **Login orchestration.** The guest/pass1/pass2 flow
   (`authenticateGuest` / `authenticatePass1` / `authenticatePass2`) with the
   fixed wire types `TomAuthenticationMessage` / `TomAuthenticationResult`.
3. **Stateless Bearer verification.** Every server call reconstructs the
   principal from the token (`convertTokenPayloadToPrincipal`, backed by
   `TomAuthorizationCache`) — no server-side session record.
4. **Client wire attachment.** `TomServerCallSpecs.includeBearerAuthentication`
   attaches the Bearer token to outgoing calls.
5. **Client token store.** `TomBearerAuthentication` holds the tokens
   (`setTokens` / `getPrincipal` / `clientJwtToken`) and reconstructs the
   client-side principal view.
6. **Extension-point shapes.** The `TomAuthenticationService` contract and the
   `Tom2FAAdaptor` shape are framework-defined. The two-pass 2FA flow is
   implemented: pass 1 issues a `Tom2FAChallenge` interim token carrying the
   access-control payload it already resolved, and `authenticatePass2` verifies
   the presented token statelessly through the mechanism's adaptor in
   `Tom2FARegistry`. A deployment supplies the *adaptor*; a spec names the
   *mechanism*.

**Spec-authorable surface** (what `@CsAuth` declares):

1. **Service binding.** The app's `TomAuthenticationService` implementation
   **is** the `@CsAuth` CodeSpec — an ordinary class on the framework
   contract, marked with the annotation.
2. **Enabled methods & flows.** Which authentication methods (guest,
   password, …) and which flows the deployment enables.
3. **Per-client login flow.** Each client's login sequence and its
   `TomServerEndpoint<TomAuthenticationMessage, TomAuthenticationResult>`
   endpoint triple (guest / pass1 / pass2).
4. **Session/token/credential policies.** Token lifetimes, refresh rules,
   credential requirements — realised as CE-CF configuration values plus
   obligations on the bound service implementation.
5. **User-profile attribute set.** Absorbed into CE-ID: profile data is
   CE-ID identity attributes (§5.24), populated by the CE-AU service.

**Built on** (per project of the §4.2 trio):

| Locus | Reused `tom_core` classes |
|-------|---------------------------|
| shared | `TomBearerAuthentication`, `TomClientJwtToken`, `TomAuthenticationMessage` / `TomAuthenticationResult`, the `TomPrincipal` projection (`tom_core_kernel`) |
| server | `TomAuthenticationServer` + the app's `TomAuthenticationService` implementation, `TomServerJwtToken` (`tom_core_server`) |
| client | Login `TomServerEndpoint` triple, `TomBearerAuthentication` token store, `TomServerCallSpecs.includeBearerAuthentication` |

**Boundaries.**

- **CE-AU ↔ CE-CF.** CE-CF supplies the key material and token-policy
  configuration values; CE-AU consumes them.
- **CE-AU ↔ CE-AZ.** CE-AU establishes the principal; CE-AZ evaluates
  requirements against it. The handoff is the reconstructed principal.
- **CE-AU ↔ CE-ID.** CE-ID declares what the identity carries; CE-AU
  establishes it and performs the public/encrypted token projection (§5.24).

### 5.26 Server authentication & feature grants

A deployed server is itself a **principal**. Which *features* a deployment may
exercise is not configuration (§5.5 item 4 — CE-CF flags are operator-set
toggles) but **authorization**: server-level entitlements granted to the
server's own identity and met against the user's grants at evaluation time.

**Server-as-principal (CE-AU flow).** The server authenticates against the
auth server with a **service credential**, exactly like any other client —
as a client application it is the CE-CL "other server" kind (§4.1). The §12
architecture applies unchanged: login yields a token, the token reconstructs
a `TomPrincipal` for the server itself (the *ambient server principal*).

**The grant carrier.** The server principal's access-control information
carries its feature grants as **entitlements** — dotted match patterns
(`TomEntitlementAccess.patterns`, the §5.15 requirement kind 3). A feature is
"granted to this deployment" iff the server principal's entitlement set
matches the feature's pattern. No new part and no new class shape: the grant
carrier is the existing entitlement mechanism applied to a server principal.

**Effective authorization = the meet.** When a CE-AZ requirement is evaluated
on an operation, the effective result is the **meet** of the user's and the
server's grant: `min(user, server)` over the graded four-state levels
(`none < disabled < read < full`), plain binary AND for two-state kinds. A
user's `full` on a feature the deployment is not entitled to evaluates to
`none` — the server's grants cap every user's grants.

**Wiring (CE-CF).** The server-auth wiring — auth-server URI and the
service-credential reference — is a pair of CE-CF values, secret-marked per
§5.16. The credential itself never appears in a spec.

**Grant issuance.** Issuing and revoking server-level entitlements is the
auth server ↔ `tom_sqm` (subscription/quota) boundary — named here as the
owning system pair; its contract is out of CodeSpecs scope.

**Framework locus (shipped).** Server self-login, the ambient server principal
and the meet are `tom_core` runtime work and are **implemented**:
`TomServerSelfLogin` / `TomServiceCredential` (`tom_core_server`,
`tomserver/authentication/server_self_login.dart`) log the deployment in
before `TomServer` binds its socket; `TomServerPrincipal` (`tom_core_kernel`,
`tombase/security/access_controls.dart`) is the ambient holder; and the meet
runs inside `TomAccessControl.checkAccessibility` / `resolveAuthState`, which
are `@nonVirtual` entry points delegating to the `resolvePrincipalAuthState` /
`resolveServerAuthState` hooks — so a subclass cannot bypass the cap. None of
this is a CodeSpecs gap: nothing here is spec-authored beyond the two CE-CF
wiring values and the ordinary CE-AZ requirements that the meet applies to.

**Degradation.** A deployment that configures no service credential installs
no server principal, and evaluation returns the user's grant untouched —
existing deployments are behaviourally unchanged. Note the asymmetry: *no*
server principal means *no cap*, whereas a server principal with an **empty**
entitlement set is entitled to nothing and denies everything.

### 5.27 CE-MG schema-migration artifacts over the `tom_core_server` migration engine

**Decision.** CE-MG models the **SQL migration artifact set** of an application
— `@CsMigration`-marked file assets in the server project (§4.2), driven by the
existing `tom_core_server` migration engine as **pure reuse, no gap class**:
`TomDbMigrations` (orchestrator), `TomDbMigrator` (per-database contract),
`TomMigrationFileName` (filename grammar), `@TomDbMigrationAdaptor` (reflection
discovery of migrators by data-source type), `MariadbMigrationAdaptor` (the
MariaDB implementation). Kind value: `schemaMigration`; SOM home: D03
IMO/`SCHMG`; locus **database** (artifacts ship with the server project).

**Scope — three artifact kinds.** A CodeSpec authors:

1. **Initial DDL** — the baseline schema (tables, indexes, constraints) as the
   first migration(s) of each schema.
2. **Base/seed data** — the initial *reference* data of the **new** system
   (lookup tables, defaults, built-in roles). Explicitly **not**
   business-data migration from legacy systems — old→new data mapping and
   cutover stay in the SOM `MIGME` migration sections and are outside
   CodeSpecs.
3. **Iteration scripts** — the append-only schema evolution steps as the data
   model changes.

**Filename grammar + environment tagging.** Every artifact basename must match
`[<numeric version>]-<description>[@<env>[,<env>…]].<ext>` in full
(`TomMigrationFileName`; description = letters/underscores, malformed names
throw). Artifacts apply in **ascending numeric version order** (`[2]` before
`[10]`). The optional `@<env>` tag (C-16) restricts an artifact to the named
environments; an **untagged** artifact applies everywhere. The active
environment resolves via `TomRuntime`, falling back to the **production-safe
default** when none is initialized — only untagged artifacts apply, so a
`@dev`/`@test` seed artifact can never leak into production. Skipping is pure
omission: applied-version bookkeeping is untouched, re-runs stay idempotent.

**Directory tree — multi-DB by construction.** Artifacts live under
`<databaseMigrationsDirectory>/<datasourceName>/<schemaName>/` — the datasource
level matches a registered `TomDataSourceInfo` name, the schema level one
schema within it. Several databases (and database *types*, via
`@TomDbMigrationAdaptor`) coexist without any extra spec surface.

**Immutability — applied migrations are append-only.** The migrator records
each applied version and, on re-encounter, **verifies** (description/checksum)
and skips it; an applied artifact is never edited — schema change is always a
*new* numbered artifact. The migration chain is the schema's history; only the
chain's tip moves.

**CE-DB convergence — a named validator check.** The cumulative DDL of a
schema's chain must produce exactly the shape the `@CsTable`/`@CsColumn`
entity model declares (§5.13). This is a **named CodeSpecs validator check**
(it is also the §5.23 integrity mechanism for the string-exempt artifact
filenames). The schema-diff engine that mechanically proves it ships in
`tom_core_server`'s `db_migration` module — `schema_model.dart` (the compared
shape), `schema_ddl_reader.dart` (the shape the chain's cumulative DDL yields)
and `schema_convergence.dart` (the comparison).

**Wiring (CE-CF).** The tree root is the `databaseMigrationsDirectory` server
configuration value (§5.5, §5.16); `TomDbMigrations.migrateDatabases` runs from
it at server start. No further CE-MG-specific configuration exists.

### 5.28 CE-RP report definitions over the domain model

> **Status: DEFERRED (§4.3) — worked out in a separate specification**
> (decision (j)). Reporting is genuinely complex and is *"just another part of
> the UI specified differently"*: authored as part of DocSpecs, a report maps to
> a **UI to display and interact** with the result + a **server API** to fetch it
> + **graphs/charts**. It is **not** part of the first CodeSpecs pass — CE-RP
> carries only a reserved `CodeSpecPart.reporting` value (§4.3) until its own
> specification is written. The material below is retained as the **seed for that
> separate spec**, not as an active §4.1 part; there are **no `@CsReport`
> annotation, no built-on class and no generated code** until CE-RP is promoted.

**Design seed (for the separate reporting spec).** CE-RP would model **report
definitions** as first-class spec elements — `@CsReport`-marked, server
(definition + execution) + shared (result shapes) per §4.2. A report definition
goes beyond a DTO or a CE-ST view-model: it may aggregate, precalculate and
format. Kind value: `reporting`; likely SOM home: **D09 XDS** (the
report/print/export definition family) with **D03 IMO** as the source-data
reference.

**Scope — what one report definition names.** A CE-RP definition =

1. **Query/projection** over the domain model — CE-DB entities, expressed on
   the CE-DB query substrate (`TomQueryBuilder` typed `TomOperator` expression
   trees, `TomQuerySentenceCompiler`, the crud repositories,
   `tom_core_server`).
2. **Output shape** — tabular sections with typed columns, plus charts (series
   + axes).
3. **Filters / parameters** — the runtime inputs a caller supplies, typed and
   bounded.
4. **Delivery channel, named abstractly** — `apiResponse | email | fileExport`
   (CSV/PDF/…). The definition names the channel only. All three transports now
   exist: `apiResponse` and `fileExport` in the `tom_core_server` `export`
   module, `email` in its `messaging` module (below).
5. **Optional schedule** — a precalculated / periodically distributed report
   names its schedule; execution wiring is the CE-JB relationship (below).

**Gap (tom_core_codespecs concrete classes).** Two classes `tom_core` lacks:

- the typed **report-definition holder** (parameters, projection reference,
  output shape, delivery-channel naming, schedule naming) — server project;
- the **tabular report-result envelope** (sections/columns/rows) — the shared
  wire shape a CE-API report operation returns, beside the report-parameter
  DTOs, so clients can render/download.

Everything else is reuse: the query substrate and the CE-API delivery path are
framework-fixed. The report-definition identity is declared once as a
`CsReportRef` const on the CE-RP catalogue class (§5.23) — citations
(e.g. CE-JB scheduled work) hold the typed const, never a string.

**Relationships.**

| Part | Relationship |
|------|--------------|
| CE-API | Delivery — a report is returned by an ordinary endpoint (§7 contract); no special transport. |
| CE-DB | Source — entities/repositories; the projection is built on the CE-DB query substrate. |
| CE-JB | Scheduled precalculation — the definition *names* its schedule (SOM `ReportScheduleEntry`); the execution wiring is the CE-JB job that realises it (§5.29). |
| CE-NT (§4.3, deferred) | Email delivery — the definition names the channel abstractly; the transport exists (`tom_core_server` `messaging`), so a scheduled report can be delivered by mail today. What remains deferred is the notification *model* above it. |

**Framework substrate.** Nothing CE-RP needs from `tom_core` is outstanding; the
one remaining gap is the result envelope this section owns.

Aggregation/grouping is available: `tom_core_server`'s
`object_persistence/grouped_query.dart` carries `TomAggregateFunction`
(`count` / `sum` / `avg` / `min` / `max`, `distinct`-capable), `groupBy` key
columns and a `having` group predicate, compiled through the query builder and
sentence compiler — so a report's measures and dimensions map onto the CE-DB
query substrate directly rather than onto pseudo-code.

Rendering is likewise available: `tom_core_server` has an `export`
module (`TomTabularRenderer` over `TomCsvRenderer` / `TomXlsxRenderer` /
`TomPdfRenderer`, guide at `tom_ai/core/tom_core_server/doc/export.md`) that
renders a tabular result to all three formats through one abstraction, streaming
throughout. Both non-email delivery channels are wired: `TomExportService`
`respondWith` is `apiResponse` and `storeAs` is `fileExport`, the latter over a
narrow `TomExportStore` seam that `TomBlobExportStore` now backs with the
`file_storage` module's blob stores (database / directory / S3 / memory, chosen
in configuration; guide at
`tom_ai/core/tom_core_server/doc/file_storage.md`). The renderers
consume `TomTabularResult` — deliberately the *minimal* tabular shape, not this
section's envelope, so that when the envelope class is authored it is adapted
onto that shape rather than the renderers being rebuilt. **Charts (item 2) are
not rendered**: two of the three formats cannot express one at all, so a chart
model belongs beside the envelope rather than inside it.

Email delivery is **no longer a roadmap item**: `tom_core_server` has a
`messaging` module (`TomMessage` / `TomMessageRouter` / `TomSmtpTransport` /
`TomMessageOutbox`, guide at `tom_ai/core/tom_core_server/doc/messaging.md`), so
a report definition naming the `email` channel is wired rather than merely
named. Delivery is queued on the CE-JB job scheduler; SMTP credentials are
secret-marked CE-CF fields per §5.16.

### 5.29 CE-JB background-job definitions over the operational model

**Decision.** CE-JB models **background-job definitions** as first-class spec
elements — `@CsJob`-marked, **server-only** per §4.2. A job is work that runs
*off* the request thread: on a schedule, on a calendar date, or on an event,
distinct from the request-driven CE-API. Kind value: `backgroundJob`; SOM home:
**D06 ATS** (the architecture's operational model, `BatchJobManagement`
BAJOMA).

**Scope — what one job definition names.** A CE-JB definition =

1. **Trigger** — `cron | calendar | event`: a cron/recurrence expression, a
   calendar date/time (with time-zone handling), or a named system event. This
   is the axis that separates CE-JB from request-driven CE-API.
2. **Work definition** — the unit of work, written as compilable **pseudo-code**
   (the §3 first-level-implementation latitude): the job's work body is real Dart
   that calls a **later-injected abstract service class** whose methods carry
   detailed doc-comments describing the intended behaviour. It runs off the
   request thread on the `tom_core_kernel` isolate-pooling substrate
   (`TomCommand` dispatched through `TomExecutor` / `TomWorker`).
3. **Target references** — the CE-DB entities and/or CE-RP reports the job acts
   on, held as typed const refs (§5.23 — `CsReportRef` for a scheduled report),
   never strings.
4. **Retry / backoff / timeout / failure-alerting** — the operational policy
   for a failed or long-running run.

**Gap (tom_core_codespecs concrete class) — narrow.** `tom_core_kernel`'s
`tombase/scheduling/` module carries the **whole runtime half** of a job:
`TomJobDefinition` (schedule, work body, retry policy, timeout, missed-window
policy, overlap rule), the `TomSchedule` family (cron / calendar / interval /
event), `TomScheduler`, the `TomJobStore` implementations, the `TomLeaseLock`
family, and `TomJobDispatcher` — which is exactly the "pluggable into any
scheduling system" seam. All of it is **reused directly** per §1.1 pillar (b);
re-declaring any of it in `tom_core_codespecs` is the duplication that pillar
forbids.

What the substrate has no home for is the **deployment-and-ownership envelope** a
specification authors *around* a job — `TomJobDefinition` is a runtime object, so
by the time it exists the decision to deploy has already been made. That envelope
is the gap class `TomJobDeclaration`: `enabled` (deployment gating is **opt-out** —
a specified job is meant to run), `environments` (**empty means every
environment**, keeping environment lists out of specs that do not need them),
`serviceUnitId` (owning unit), and `targetRefs` (the entities the job touches,
declared because `TomJobDefinition.body` is an opaque closure and reveals
nothing). A concrete job carries a `@CsJob`-marked `TomJobDeclaration` and
supplies its own `TomJobDefinition`, whose work body is compilable **pseudo-code**
(decision (k), §3) over a later-injected **abstract service class** with
doc-commented methods — so the skeleton compiles now and the real service binds at
implementation time. The job identity is declared once as a `CsJobRef` const on
the CE-JB catalogue class (§5.23) — citations hold the typed const, never a
string.

**Relationships.**

| Part | Relationship |
|------|--------------|
| CE-SU | Ownership — a job belongs to the service unit that owns its target aggregate (§5.1); it runs under that unit's boundary. |
| CE-DB | Targets — the entities/repositories a job reads or mutates, on the CE-DB access model. |
| CE-RP | Scheduled reports — a CE-RP definition that *names* a schedule (§5.28) is **realised as** a CE-JB job whose work body runs the report projection and hands off to the report's delivery channel. |
| CE-AZ / CE-AU | Execution principal — a job runs under the server principal, not an interactive session; authorization on any CE-API it calls is checked against that principal (§5.6.3, §5.25). |

**Framework substrate (existing `tom_core` mechanics, NOT CodeSpecs gaps).** All
three items this section once listed as roadmap have landed in
`tom_core_kernel/lib/src/tombase/scheduling/` and are reused as-is:

- **Scheduler runtime** — `TomScheduler` over the `TomSchedule` family
  (`TomCronSchedule`, `TomCalendarSchedule`, `TomIntervalSchedule`,
  `TomEventSchedule`), so a trigger is a wired schedule rather than a name. The
  family has **no one-shot absolute-deadline schedule** ("fire once at an
  instant, then never"); it is expressible inside the existing pure
  `nextFireAfter` contract, and is tracked as tom_core `csexb6`.
- **Job queue** — `TomJobStore` with `TomMemoryJobStore` / `TomFileJobStore` for
  durable enqueue/dequeue of `TomJobRun`s.
- **Multi-node locking** — the `TomLeaseLock` family (`TomMemoryLeaseLock`,
  `TomFileLeaseLock`) for single-fire coordination across a server cluster.
  `tom_process_monitor` remains **reference only** (an existing process
  supervisor) — not a `tom_core`-family class the CodeSpec builds on.

## 6. Completion elements (recap)

CE-ST, CE-NV, CE-AZ and CE-ER complete the client→server→DB core
parts; CE-CC, CE-DS, CE-UP, CE-CL and CE-AU are their peers. **CE-CF is
server-only** — user settings are CE-UP; device settings are CE-DS;
client-machine settings are CE-CC (§11).

## 7. Server-contract decisions

Design constraints to encode in the CE-API / CE-ER derivation:

1. **All operations are POST.** The operation name (not HTTP verb + path) carries
   intent. CodeSpec models an **operation name** per endpoint.
2. **Only 5xx HTTP codes are transport errors** (infrastructure failure), never
   application outcomes.
3. **All application-level errors are a structured error result** in a normal
   (2xx-transport) response. CE-ER defines one canonical `Result`/`ErrorResult`
   envelope: success payload **or** structured error (code, message, field-level
   details).
4. **Error texts are keyed by the structured error codes** (CE-TX ↔ CE-ER), so
   client copy and server error codes share one source.

## 8. SOM → CodeSpecs derivation map (sketch)

| CodeSpec element | Primary SOM source document(s) | Notes |
|------------------|-------------------------------|-------|
| CE-EL, CE-FM, CE-LO | **D09 XDS**; **D05 ISC** | Screens/elements/forms/layout from experience design; scenarios name the screens. |
| CE-TX | **D09 XDS** + SOM `@ContentHelp`/`@Form` hints/doc-comments | Texts already in the SOM; error texts via CE-ER codes. |
| CE-VA | **D04 RSP**; **D03 IMO** constraints | Field rules from attribute constraints; form rules from requirements. |
| CE-AC, CE-SC, CE-NV | **D05 ISC**; **D02 TOM** | Scenarios/processes define actions, triggers, transitions; the CE-NV **screen-flow** (form→screen assignment, replace/popup, action-outcome targets) is authored in the **screen route map** (`SCRTMP`) under **D09 XDS**. |
| CE-API, CE-ER, CE-SU | **D07 IFS**; **D06 ATS**; **D05 ISC** | Operations + request/response; service-unit grouping from architecture + process cohesion. |
| CE-AZ, CE-AU, CE-ID | **D08 SAS** | Roles/permissions per operation (CE-AZ); auth/credential/session flow (CE-AU); identity-attribute extensions from the USMGT family (CE-ID). |
| CE-DB, CE-ST | **D03 IMO** rich classes | Tables, columns, view-models, DAOs; domain enums are generated as member declarations of their owning part from DOMEN/DMENE + OBST (§4.1 member-kind rule). |
| CE-CF | **D06 ATS**; **D08 SAS** | **Server/system** configuration only. |
| CE-CC, CE-DS, CE-UP, CE-CL | **D06 ATS** (deployment/clients); **D09 XDS** (preferences surfaced in UI); **D02 TOM** (roles → whose settings) | Client apps + per-machine client config + device settings + user settings. |
| CE-RP *(deferred, §4.3)* | **D09 XDS** (report/print/export definition family); **D03 IMO** (source data) | **Deferred** — worked out in a separate reporting specification; mapping-only (reserved `reporting` kind) until promoted (§4.3, §5.28). |
| CE-JB | **D06 ATS** (`BatchJobManagement` BAJOMA) | Background/scheduled jobs from the architecture's operational model; targets cite IMO entities and CE-RP reports (§5.29). |
| **Deferred (§4.3)** | per the §4.3 "SOM home section" column | **Mapping-only**: the SOM section carries `@CodeSpecKind` with the reserved kind; no CodeSpecs code until promoted. |

**Derivation principle:** the SOM's stable `@SectionId` is the join key — each
generated element's `@CodeSpec(source: [...])` cites the SOM section IDs it came
from, making gap analysis a set-difference over section IDs.

### 8.1 The CodeSpecs surface is bounded

The SOM has **~1240 classes across 14 roots**, and the CodeSpecs surface is
concentrated in a **minority** of them. The rest is business-facing descriptive
content that Phase 4 does **not** generate code from — it feeds the *other*
follow-up processes instead (§8.3).

| Root(s) / file | ≈classes | CodeSpecs-relevant? | Parts in play |
|----------------|---------:|---------------------|---------------|
| **D03 InformationModel** (`information_and_data_model.dart`) | 40 | **Yes — core** | dataAccess, viewState, validation, domainEnum, action, serviceUnit, authorization, serverApi, serverCall, errorResult, text, schemaMigration |
| **D09 ExperienceDesignSpecification** (`experience_and_interface_design.dart`) | 122 | **Yes — core** | screenElement, form, layout, text, viewState, navigation, validation, action, errorResult, configuration, reporting |
| **D08 SecurityAccessSpecification** (`security_and_access_model.dart`) | 151 | **Yes** | authorization, authentication, identity, serverConfiguration, auditLog, validation |
| **D06 ArchitectureTechnologySpecification** (`architecture_and_technology.dart`) | 249 | **Partly** | configuration, serverApi, serviceUnit, client, clientConfiguration, backgroundJob |
| **D07 IntegrationInterfaceSpecification** (aggregates XDS+ATS) | 27 | **Yes** | serverApi, serverCall, errorResult, serviceUnit |
| **D05 InteractionScenarios** + **D02 TargetOperatingModel** | 64 | **Partly** | action, serverCall, navigation, authorization, validation |
| **D04 RequirementsSpecification** (functional-requirement slice) | 8 | **Partly** | validation, dataAccess, form, action, serverCall, navigation — the L10N/IFU/training and technical/security NFRs are non-codespecs |
| `current_landscape.dart` (D01 CLA) | 83 | No | as-is analysis |
| `delivery_roadmap.dart` (D11) | 45 | No | staging plan |
| D10 QAP (`quality_model.dart`, `quality_and_acceptance_model.dart`, `delivery_scope_and_acceptance.dart`) | 66 | No | quality goals, UAT |
| `target_organization.dart`, `governance_administration.dart` | 115 | No | org/governance narrative |
| D12 TRP (`transition_and_rollout_plan.dart`, `delivery_transition_and_rollout.dart`) | 11 | No | rollout narrative |
| `components_and_dependencies.dart`, `solution_architecture_and_technology.dart` | 19 | No | build-vs-buy narrative |

**~410 classes across 8 documents are non-codespecs descriptive content.** That
is not a gap — it *bounds* the CodeSpecs surface, and it is the raw material for
the follow-up split (§8.3).

### 8.2 Closed-choice sections — the `@OneOf` / `@Case` discriminated group

**The problem.** A descriptive section often must resolve to **exactly one of a
closed set of typed alternatives**, each carrying only that kind's attributes.
Modelled naively, such a section carries a free-text kind discriminator plus the
**union** of every kind's attributes as always-optional members — a Date field
still carrying `decimalPlaces`, a Number field still carrying `optionsSource`,
`inputMask` sitting next to `minValue`/`maxValue`. Nothing forces a spec to a
single kind's attributes; nothing forbids two kinds at once.

**Why not subtype polymorphism.** The obvious OO answer — an abstract base with
`TextInputElement` / `DateInputElement` / … subclasses — **fights the SOM**. The
reader and validator resolve each `List<T>` to a *single* `listElementTypeName`
and require every class to reach `DocSpecsSection` by **field composition**, not
by polymorphic element lists. A polymorphic list has no single element type and
breaks section-id resolution. Subtyping is rejected.

**The mechanism.** Stay inside the existing `DocSpecsSection` / `@Form` /
complex-subsection shapes; add two annotations (declared in `tom_specs_core`,
exported losslessly like `@CodeSpecKind`) and one validator invariant:

1. **`@OneOf(discriminator: '<formFieldName>')`** on the container section —
   declares that a named group of complex-subsection fields is a *closed choice*
   and names the discriminator `@Form` field. **The discriminator must be a model
   enum**, which is why the domain-enum registry is a hard prerequisite.
2. **`@Case(<EnumConstant>)`** (repeatable) on each alternative
   complex-subsection field — binds that subsection to one or more discriminator
   values. A subsection with **no** `@Case` is *common*: it applies to every case
   (e.g. `resources` / `layout` / `visibility`).
3. **Modeling rule** — promote each kind to its **own** typed subsection carrying
   only that kind's attributes (Date → `firstDate`/`lastDate`; Number →
   `minValue`/`maxValue`/`decimalPlaces`; Select →
   `optionsSource`/`selectMode`/`displayMode`). This converts a
   union-of-`@Form`-fields into a discriminated subsection group — one mechanism
   at both granularities.

**Enforcement is two-tier**, because the SOM validator is *static* (it analyzes
the class graph, not documents):

- **Static** (`tom_specs_clitool/lib/src/validator.dart`, the "§8.6 one-of"
  invariant): (i) the `@OneOf` discriminator resolves to a `@Form` field whose
  type is a model enum; (ii) every `@Case` value is a constant of that enum;
  (iii) the `@Case` values across the group **cover** the enum — an uncovered
  case is a *warning*, not an error (a kind with no attributes yet is legal);
  (iv) the group's alternative fields are all complex subsections of the same
  container.
- **Instance** (DocSpecs document validator + editor strict mode): a concrete
  section instance carries **only** the subsections whose `@Case` matches the
  chosen discriminator value (plus the un-`@Case`d common ones), and **at most
  one** per case.

**The complete closed-choice inventory.** A whole-model structural scan
(discriminator + ≥2 complex members) surfaces ~311 sections. The qualifying test
is **(a)** a discriminator `@Form` field **and (b)** a union of ≥2
mutually-exclusive per-kind attribute groups. Two shapes are explicitly ruled
out: **enumerable scalars** (a `*Type`/`priority`/`severity` field whose values
are closed but which gates no divergent sibling attributes — that is a domain-enum
concern) and **composition discriminators** (a `*Type`/`*Strategy` field
alongside complex subsections that are *all* present, e.g. `ScreenActionEntry` →
`visual`/`conditions`/`behavior`; `ServerRoleEntry`; `ComponentEntry` — no mutual
exclusivity, so no one-of). Applying the test collapses ~311 candidates to **two
families**:

**Family 1 — element/field kind (CE-EL / CE-FM). Converted.**

| # | Section (member) | Discriminator enum | Cases |
|---|------------------|--------------------|-------|
| 1 | `ScreenElementEntry` (D09 XDS) | `ScreenElementKind` | action / input / display facet subsections, plus common `resources`/`layout`/`visibility` |
| 2 | `ScreenElementFieldSpec` (D09 XDS) | `ScreenElementFieldKind` | numeric / date / text / select case subsections |

The "display-vs-input-vs-action facet split" is **not** a separate locus — it is
the `@Case` grouping *within* site #1.

**Family 2 — typed-value data-type unions (CE-FM / CE-DB). Converted.** Each
site's free-text `dataType`/`fieldType` discriminator was **enum-promoted first**
(per the "discriminator must be a model enum" rule), then its single jumbled
`@Form` was split into per-kind `@Case` subsections, leaving only the
type-independent attributes in the common subsection:

| # | Section (member) | Doc | Discriminator enum | Case subsections |
|---|------------------|-----|--------------------|------------------|
| 3 | `DataAttributeEntry.dataTypeSpec` | D03 IMO | `DataAttributeKind` | `textTypeOptions` / `numericTypeOptions` / `temporalTypeOptions` / `binaryTypeOptions` |
| 4 | `ReportColumnEntry.formatting` | D09 XDS | `ReportColumnKind` | `numericFormat` / `currencyFormat` / `dateFormat` / `booleanFormat` / `textFormat` |
| 5 | `ExportFieldMappingEntry.formatting` | D09 XDS | `ExportFieldKind` | `numericOutput` / `temporalOutput` / `booleanOutput` / `enumerationOutput` / `textOutput` |
| 6 | `ReportFilterEntry.input` | D09 XDS | `ReportFilterValueKind` | `textFilterOptions` / `numericFilterOptions` / `dateFilterOptions` / `booleanFilterOptions` / `selectFilterOptions` / `entityFilterOptions` — each carrying its own kind-appropriate `inputType` |
| 7 | `ScreenFieldEntry` | D04 RSP (`introduction_and_scope.dart`) | `ScreenFieldKind` | `textConstraints` / `numericConstraints` / `temporalConstraints` / `choiceOptions` |

Site 3 is also the case that proves the discriminator need not sit on `content`:
`DataAttributeEntry` has no `content` member, so `dataType` lives in the `@Form`
of the `dataTypeSpec` subsection. Both the static validator (`_allFormFields`)
and the instance-tier check resolve a discriminator in either position.

A kind that carries no extra attributes binds no case; the static validator
reports the uncovered constants as a **warning**, which is the expected steady
state for e.g. `DataAttributeKind.boolean`/`uuid`/`json`/`enumeration` (an
enumerated attribute's value set is modelled by its `constraints` list, not by a
type-specific options form) and `ScreenFieldKind.boolean`/`file`.

**Ruled out after inspection:** `ObjectStateEntry.stateType` (`ObjectLifecycleKind`,
D03 IMO) — its discriminator gates **common** attributes (entry/exit conditions,
allowed/restricted operations, SLA — all apply to every lifecycle role), so it is
a domain-enum value set, not a subsection union.

### 8.3 The CodeSpecs / follow-up split and the generation projection

§8.1 bounds the surface by *document*; the structural question is sharper: can a
**whole subtree** be handed to generation end-to-end? A subtree that mixes
generated and non-generated content cannot, so every mixed boundary is a **split
point**. The model is therefore divided as high up as possible into

- **purely-CodeSpecs subtrees** — every reachable section maps to a
  `@CodeSpecKind` part and is realised as `Cs*`-annotated code; and
- **purely-follow-up subtrees** — every reachable section is delivered by a
  non-generation process.

**Top-level verdict.** `D00SolutionBlueprint` has 15 top-level sections
(SBP.1–SBP.9, SBP.11–SBP.15; SBP.10 is unused). **Eight split cleanly at the top**
as whole follow-up subtrees: `documentControl`, `introductionAndScope`,
`glossaryAndAbbreviations`, `stakeholdersAndGovernance`, `currentLandscape`,
`assumptionsConstraintsDependencies`, `qualityAndAcceptanceModel`,
`deliveryTransitionAndRollout`. **None of the 15 is purely CodeSpecs at the top** —
the generation surface is always a subtree *inside* a mixed section. The six
mixed sections are exactly the CodeSpecs-bearing documents of §8.1: SBP.7 TOM,
SBP.8 IFM, SBP.9 RSP, SBP.11 ATS, SBP.12 SAS, SBP.13 XDS. QAP (SBP.14) is
*entirely* follow-up because acceptance-test derivation is a **separate TomSpecs
phase** (Phase 5), not Phase-4 code generation.

**Follow-up taxonomy.** Every follow-up subtree is tagged with the process that
delivers it, via `@FollowUpKind(List<FollowUpProcess>)` (`tom_specs_core`) —
list-valued and applied to subtree roots, mirroring `@CodeSpecKind`. Eight codes
cover the surface today; the enum is **extensible**:

| Code | Follow-up process | Typical content |
|------|-------------------|-----------------|
| **DOC** | Documentation authoring | scope, glossary, user docs, assessment writeups |
| **TRN** | Training / enablement | training deliverables, enablement plans |
| **ORG** | Organizational change | roles, org structure, governance, stakeholders |
| **OPS** | Operational routines | audit/logging ops, key management, monitoring, backups |
| **CAP** | Capacity / infra planning | volume metrics, technical characteristics |
| **CMP** | Compliance & regulatory | compliance framework, data-classification obligations |
| **MIG** | Migration & transition | data-migration mapping, rollout, cutover |
| **L10N** | Localization / translation | message translation, locale content authoring |

These are **process tags, not new model types**. Each follow-up subtree carries
one so the downstream process can select its slice.

**Split points per mixed section.** In each case the CodeSpecs-bearing children
are grouped into one subtree and the rest hoisted into tagged follow-up subtrees:

| Section | CodeSpecs subtree | Hoisted to follow-up |
|---------|-------------------|----------------------|
| SBP.7 TOM | `processStepsAndActorInteractions` (PSAAI, `@MapsTo` D05) | `organizationAndProcessConcept` (OAPC) grouping `organizationalFramework` + `businessProcessDescriptions` → ORG/OPS |
| SBP.8 IFM | `DataModel` (entity/attribute core) | per-entity facets: Volume→CAP, Compliance→CMP, Technical→CAP, Migration→MIG, erDiagram→DOC |
| SBP.9 RSP | functional requirements + the CE-VA/CE-ER-bearing NFRs (consumed as a *seed*) | L10N/DOC/TRN NFR sub-areas |
| SBP.11 ATS | `TechnicalFrameworkConcept` (CE-CF configuration facets) | architecture/component narrative → DOC |
| SBP.12 SAS | `AccessControlModel` (userMgmt / auth / resourceProtection / authorization / roleMatrix) | encryption + audit → OPS, compliance → CMP |
| SBP.13 XDS | `ExperienceCodeSpecs` (screens / screenFlow / errorHandling / responsive / uiComponents / dataStructureAlignment) | design, doc and L10N children |

**Constraints any further re-homing must honour:**

- **Pure-projection invariant** — the D01–D12 projections reach only their SBP
  counterparts. Moving a section within SBP changes what each projection reaches,
  so every move cascades to the projection roots and must keep the outliner and
  the validator green from **all 14 roots**.
- **Section-id stability** — ids resolve root-independently; moves must preserve
  `@SectionId` global uniqueness and coverage (no orphaned `@SectionIdPattern`
  subtrees).
- **Downstream cascade** — each move cascades to the SOM meta, both committed
  `spec_model.json` assets (`tom_specs_reviewer/assets/` and
  `tom_forge/tom_specs_editor/assets/`, byte-identical modulo `generatedAt`) and
  the language facades. Make one discrete move at a time.
- **Traceability follows the section** — re-home `@MapsTo` / `@DetailedIn` with
  the sections they annotate; a hoisted follow-up subtree keeps its own `@MapsTo`
  targets.

**The generation projection.** Once the CodeSpecs subtrees are isolated, the
concrete input the Phase-4 generator consumes end-to-end is
**`D13CodeSpecsProjection`** (`@SectionId('CGP')`, in
`tom_specs_model/lib/src/codespecs_projection/codespecs_projection.dart`) — a
flat `@Document(basedOn: [D00SolutionBlueprint])` referencing the **nine isolated
subtree roots directly**, with no container classes, grouped into
shared → server → client locus bands by `@Comment('locus: …')`:

| Locus | Roots |
|-------|-------|
| shared | `DomainEnumRegistry`, `ErrorCodeRegistry`, `ResultEnvelope`, `MessageKeyRegistry` |
| server | `DataModel`, `TechnicalFrameworkConcept`, `AccessControlModel` |
| server + client | `ProcessStepsAndActorInteractions` |
| client | `ExperienceCodeSpecs` |

It is `@CodeSpecKind`-driven rather than `@DetailedIn`-driven, so it carries the
`@CodeSpecsProjection()` marker (`tom_specs_core`), which exempts it from the
§8.6 **detail-count** check only — it still satisfies the pure-projection
invariant. The RSP `Requirements` seed is **deliberately excluded**: requirements
are *consumed* by generation, not generated from.

### 8.4 `@CodeSpecKind` in the cross-language meta

`@CodeSpecKind` is **not** a slotted annotation in the per-language SOM meta
emitters. All nine emitters (`dart`/`typescript`/`javascript`/`python`/`java`/
`go`/`rust`/`c`/`cpp`) share one 13-entry slot set — `SectionId`,
`SectionIdPattern`, `SerializationOrder`, `Min`, `Unused`, `ContentType`,
`ContentHelp`, `Headline`, `Comment`, `Form`, `Document`, `MapsTo`, `DetailedIn`
— and route every non-slotted annotation into the generic `extra` catch-all. So
`@CodeSpecKind` **already rides in `extra` losslessly in all nine languages**,
with both `kinds` (list) and `note` intact.

It gets **no dedicated slot**, deliberately. A slot is warranted only when a
cross-language meta *consumer* navigates the annotation structurally —
`mapsTo`/`detailedIn` are followed as cross-phase *references* by tooling and
editors. Nothing navigates `@CodeSpecKind`: CodeSpecs generation is Dart-only,
and the value is a self-describing `CodeSpecPart.*` list already legible in
`extra`. Promoting it would touch all nine emitters, the shared `SomMetaNode`
runtime shape, the meta schema and the conformance goldens for zero consumer
benefit. The `extra` treatment is exactly the intended design for annotations
"carried for completeness but not structurally consumed."

## 9. Bidirectional DocSpecs ↔ CodeSpecs linking

The link between a Phase-3 DocSpecs section (typed by the SOM) and the Phase-4
CodeSpec code is **bidirectional**, at two resolutions plus a code-side back-trace.

### 9.1 General mapping — section *type* → CodeSpec *kind(s)* (SOM annotation)

`@CodeSpecKind` on a SOM section class states which **kind(s)** of CodeSpec that
section type must be realised as.

- **Canonical signature: `@CodeSpecKind(List<CodeSpecPart> kinds, {String? note})`.**
  The value is a **list** — a section or form field may map to **more than one
  kind** (e.g. a field that is both a `screenElement` and a `dataAccess` column, or
  a setting that is both `clientConfiguration` and `userSettings`). Each value is a
  `CodeSpecPart` from §4.1; `note` explains the influence. ("CodeSpecsMapping" is
  the descriptive alias for this concept; the annotation type is `@CodeSpecKind`.)
- This is the **general half of the forward link**: every section of a mapped type
  must produce each named CodeSpec kind.

### 9.2 Concrete forward mapping — section *instance* → code *location(s)*

A **`codeSpec` member on `DocSpecsSection`** records the actual CodeSpec code
location(s) a concrete section maps to.

- **Type:** `List<String>` — the `codeSpec` member of `DocSpecsSection`.
- **Serialization:** the section id lives in **square brackets inside the headline
  HTML comment**, `<!--[id]-->` (`som_multiplatform_spec_model.md` §11.2). The `codeSpec` list rides in
  that **same comment as one comma-separated, quoted `key=value` field** alongside
  the bracketed id (the tom_doc_scanner parser already extracts the bracketed id
  into `explicitId` and remaining `key=value` pairs into a generic `fields` map —
  no grammar change needed). Example:

  ```md
  ### <!--[IMO-014] codeSpec="CsOrder,CsOrder.total,CsOrderRepository"--> Order entity
  ```

- This is the **concrete half of the forward link**.

### 9.3 Concrete backward mapping — code → section(s) (DocSpec annotation)

A **`@DocSpec` annotation on the CodeSpecs code** traces each code element back to
the DocSpecs document. It holds a **list of `(sectionId, description)` tuples**.

- **`@DocSpec([DocRef(sectionId, description), …])`** on a CodeSpec class or member.
  `sectionId` is the SOM `@SectionId`; `description` explains what the code takes
  from that section and how.
- This is the **reverse link**.

### 9.4 Why both directions

`@CodeSpecKind` (type) + the `codeSpec` field (instance) give **doc → code**;
`@DocSpec` gives **code → doc**. With `@SectionId` as the shared join key,
traceability and gap analysis become set operations in both directions.

### 9.5 Annotation placement

| Symbol | Package | Why |
|--------|---------|-----|
| `@CodeSpecKind(List<CodeSpecPart>, {note})` (§9.1) | **`tom_specs_core`** | Annotates SOM *model* classes; sits with `@MapsTo`/`@DetailedIn`. The model never depends on the CodeSpecs framework. |
| `CodeSpecPart` enum (§4.1) | **`tom_specs_core`** | The shared kind vocabulary; zero-dependency. |
| `codeSpec` `List<String>` member (§9.2) | **`tom_specs_model`** | A member on `DocSpecsSection`; mutating the SOM triggers the 9-runtime regeneration cascade. |
| `@DocSpec([DocRef…])` / `DocRef` (§9.3) | **`tom_code_specs`** | Annotates CodeSpecs *code*. |
| `Cs*` annotation family (§4.1) | **`tom_code_specs`** | The framework — **annotations only, no base classes**. |
| Concrete gap classes (`gap` in §4.1) | **`tom_core_codespecs`** | The concrete classes `tom_core` lacks — never abstract `Cs*` bases. |

`tom_code_specs` depends on `tom_specs_core` and re-exports `CodeSpecKind` +
`CodeSpecPart`, so a CodeSpecs author has a single import.

## 10. Open work

Everything still outstanding against this document is tracked as a **quest todo
with the `csra` prefix** — plus `csrb` for follow-ups raised while executing a
`csra` todo, and `qr` for findings raised by a quest-refresh pass — in
`_ai/quests/tom_specs/todos.tom_specs.todo.yaml`. Each todo is self-contained —
it carries the full context needed to execute it — so this list is an index, not
a specification.

| Todo | Open work |
|------|-----------|
| `csra6` | Implement the `Cs*Ref` typed cross-part reference const family designed in §5.23 — currently designed, zero implementation. |
| `csra7` | Promote or **permanently defer** CE-WF, CE-NT and CE-LG (§4.3), recording the rationale either way. Their SOM homes and `@CodeSpecKind` tags already exist; what is missing is a built-on class + `Cs*` annotation. All three inputs are now in hand: the `audit` module for CE-LG, the `messaging` module for CE-NT, and the **§4.3.1 workflow-substrate survey recommending permanent deferral** for CE-WF. |
| `csra8` | Write the separate **CE-RP reporting specification** (§5.28) — the prerequisite to any promotion decision. |
| `csra9` | Staleness sweep: mark `reporting` as deferred in the `CodeSpecPart` enum doc-comments; fix the retired-`CE-EN` locus comment in the projection; re-verify the **23 active / 4 deferred / 28 kind values** counts across every surface. |
| `csra10` | CE-DB **file-reference column kind** — a `@CsColumn` extension for a column holding a *storage key*, with the framework resolving upload/download. **Unblocked**: `tom_core_server`'s `file_storage` module ships the capability — `TomFileReference` is the server-side column annotation (key prefix, target store, cascade), `TomBlobStore` the streaming four-method contract with database / directory / S3 / memory backends selected from configuration, and the repository resolves `saveFile` / `openFile` / `describeFile` / `clearFile` plus cascade-on-delete under the same C-4 column grade as any other column. What remains here is the `@CsColumn` extension that derives it. See `tom_core_server/doc/file_storage.md`. |
| `csra11` | Re-run the SOM coverage cross-check for all 23 active parts — every part must have a SOM home that can actually express its attribute surface. |
| `csra12` | Produce the full **per-`Cs*`-annotation derivation contract** (SOM class/field → generated annotated Dart) — the last piece before Phase-4 generation can be implemented. |
| `csrb1` | Reconcile `csex7` / `csex8` against the **landed** `tom_core_kernel` scheduling module — `TomScheduler`, `TomJobStore` and `TomLeaseLock` now cover what §5.29 once listed as framework roadmap, so those todos need an accurate status and the CE-JB reuse verdict needs an end-to-end confirmation. |
| `csrb2` | Retire or justify `TomClientConfiguration` (`tom_core_codespecs`) — §4.1/§5.16 now record CE-CC as a **reuse** verdict over the landed `TomBaseClientConfiguration`, so the part currently has two holders. Exactly one must be authoritative. |
| `qr3` | Author `@CsFieldRule` / `@CsFormRule`, or record why CE-VA does not need them. They are the only catalogued annotations still unauthored: the family bring-up added the six part-level markers but deliberately left these two finer-grained members, and `@CsValidation` may already carry their surface. Whichever way it resolves, §4.1 CE-VA must stop describing them as pending. |

## 11. Configuration & settings — the four-scope owner-key split

Configuration and settings are four parts — one part per scope key, each
single-moded (no persistence discriminator anywhere; the scope key alone decides
where a value lives):

| Part | Scope key | Persisted where | Example |
|------|-----------|-----------------|---------|
| **CE-CF** ServerConfiguration | server/system — no user, no machine | Server (deployment) | DB connection, worker counts, feature flags (config toggles) |
| **CE-CC** ClientConfiguration | (client app, machine) — no user | Client machine | API base URL, device options, per-install toggles |
| **CE-DS** DeviceSettings | (user, device) | The device, per signed-in user | window layout, last-opened, machine-local cache preferences |
| **CE-UP** UserSettings | (user) | Server (per user) | theme, language, notification prefs — restored on any device |

- **CE-CF is server configuration only** — it never carries user or client-machine
  settings.
- **CE-CC** is keyed by the (client app, machine) pair; two installs of the same
  client on two machines have independent CE-CC. No user identity in the key.
- **CE-DS** is keyed by **(user, device)**: user-specific settings of a
  user-owned device, persisted on the device and never leaving it. The
  discriminator against CE-CC is **user identity in the key** — a value that is
  the same for every user of an install is CE-CC; a value that differs per
  signed-in user on the same install is CE-DS. Device binding is
  implicit-by-storage (the store lives on the device, keyed by the signed-in
  user); no wire-level device identity exists. Server-side enumeration of
  "user-owned devices" is not modeled.
- **CE-UP** is keyed by the **user**: server-persisted preferences that follow
  the user, re-materialised on any device the user signs into via the
  `TomGetSettingsMessage`/`TomGetSettingsResult` round-trip. A CE-UP setting
  therefore has a client-side shape (CE-UP in `<app>_codespec_client`) and a
  server-side persistence (in `<app>_codespec_server`).

## 12. The `code_spec` architecture principles

CodeSpecs is part of the `tom_specs` quest; the following architecture principles
are integral to it:

- **Target architecture.** Auth server (credentials) + stateless API server
  (POST-only, §7) + relational SQL database + clients (Flutter / CLI / other
  server). Simpler variants (Flutter-only, server-only, CLI-only) are supported.
  NoSQL is a future consideration.
- **Multi-project separation** (§4.2): a shared contract, plus client and server
  implementation projects that depend on it. The compiler enforces that
  implementations satisfy the contract; a spec field-type change surfaces as
  compile errors at every implementation site that must update.
- **Three-layer UI** (CE-EL/CE-FM/CE-LO): business/semantic structure, widget
  behaviour (`@CsWidget` → concrete `tom_flutter_ui` widget), and layout are kept
  separate so layout can be manually overridden non-destructively.
- **Validation beyond the compiler.** In-code cross-part references are
  compiler-checked (§5.23), so analyzer-driven validators narrow to what the
  compiler cannot see: required annotations, valid parameters, the §5.23-exempt
  string surfaces (config source keys + env-var/cmdline aliases,
  deployment-environment names, migration artifact filenames, doc-side
  `codeSpec` locations + `@DocSpec` section ids), route uniqueness, and
  well-known-class usage.
- **Production stripping.** A cleanup tool comments spec-only code with the `//$`
  marker (reversible) before a production build, leaving implementation code intact.
- **Test generation from specs** (Phase 5 test derivation): contract / schema /
  repository / DTO / authorization / widget-contract tests are derivable from the
  CodeSpecs — they verify *implementation matches specification*, not that the
  specification matches requirements.
- **Reference implementations.** TomApi (`tom_uam_shared/endpoints.dart`) and the
  UAM persistence model (`tom_uam_server`) demonstrate the endpoint and
  entity/repository patterns CE-API and CE-DB generalise. **Legacy `Cs*`/`Ca*`
  code in these or elsewhere is not part of the framework and is removed**; useful
  annotations are salvaged by renaming to the `Cs*` prefix and moving them into
  `tom_code_specs`.

> The full per-`Cs*`-annotation derivation contract (SOM class/field →
> generated annotated Dart) is the planned follow-up to this grounding doc —
> tracked as quest todo `csra12` (§10).
