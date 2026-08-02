# Changelog

## 0.11.0

- `@CsJob` gains `targetReports` (`List<CsReportRef>`, default `const []`) —
  the CE-RP half of `codespecs_mapping.md` §5.29 scope part 3, derived from
  `SCJOB-WORK.targetReports`. Empty is the common case: most jobs produce no
  report.
- The reports land **here rather than on `TomJobDeclaration`** because §5.23
  makes the `Cs*Ref` family the annotation *parameter* vocabulary — which is
  where this annotation's `failureAlert` `CsMessageKey` already sits. A ref
  const on a `tom_core`-family class would be the outlier: those hold plain ids
  (`TomReportDefinition.reportId` is the string a `CsReportRef` wraps), and
  taking one would cost `tom_core_codespecs` its dependency-freedom.
- The CE-DB half of the same scope part stays on the declaration, as `Type`
  literals — see `tom_core_codespecs` 0.10.0.

## 0.10.0

- csrb9: close the configuration/settings **declaration** loop. The SOM now
  authors a repeating setting-declaration list per scope (`SCSET` / `CCSET` /
  `DSSET` / `USSET`, `codespecs_mapping.md` §5.16), and this release gives the
  four config markers the arguments needed to consume them — until now the SOM
  could author an overridability opt-in and a secret mark that no `Cs*` marker
  could carry.
- Add `CsOverridableBy {none, client, user, device}` — the 15th closed
  catalogue. It encodes §5.16's **opt-in** cross-scope lattice
  `CE-DS ▸ CE-UP ▸ CE-CC ▸ CE-CF`: a key is scope-pinned unless its declaration
  at the wider scope explicitly opens it.
- `@CsServerConfig` gains `overridableBy` (**required**) and `secret`
  (default `false`); `@CsClientConfig` and `@CsUserSetting` gain
  `overridableBy` (**required**). `@CsDeviceSetting` deliberately gains
  nothing: CE-DS is the narrowest scope, so the lattice bottoms out there and
  "shadowable by something narrower" is unsayable rather than merely wrong.
- The two defaults are **asymmetric on purpose**. `secret` defaults to `false`
  because that is the safe arm — a setting wrongly marked secret is merely
  stripped, one wrongly left unmarked ships its value. `overridableBy` gets no
  default for the mirror-image reason: there is no safe arm to fall back to
  that is not also a silent decision about the value's blast radius, which is
  precisely what §5.16's fail-safe rule exists to prevent.
- Making `overridableBy` required is a **breaking** change to three markers;
  it is deliberate, and the compiler enumerating every call site is the point.

## 0.9.0

- csrb4: give the `Cs*` family its **attribute surfaces**. It was complete as a
  marker set and empty as an attribute surface — `codespecs_mapping.md` §5
  specifies a spec-authorable surface per part and none of it was expressible in
  code. **24 of the 39 markers now take arguments**, shaped by
  `codespecs_derivation_contract.md` §5.1; the remaining **15 stay note-only**,
  which is a decision (their part's attributes are carried by the annotated
  declaration or a `tom_core` substrate constructor, §2.3 tests **a**/**b**) and
  not an omission.
- Add `vocabulary.dart` — the **14 closed catalogues** the arguments select from
  (`CsElementKind`, `CsTextRole`, `CsTextCategory`, `TriggerKind`, `CsGesture`,
  `CsFormEvent`, `CsLifecycleScope`, `CsLifecyclePhase`, `CsErrorSeverity`,
  `CsAuthRequirement`, `CsMigrationKind`, `CsJobTrigger`, `CsClientKind`,
  `IdentityAttributePlacement`). Enums, not strings: a catalogue grows by a
  reviewed taxonomy edit, never by a specification inventing a value in passing.
  Each is declared **locally**, mirroring its `tom_core` counterpart, because
  `tom_code_specs` deliberately does not depend on `tom_core`
  (`codespecs_mapping.md` §9.5).
- The `Cs*Ref` family is now **wired**: `csra6` deliberately shipped the ref
  types without annotation parameters, and this change adds every ref-typed
  parameter in one pass, so there is no compatibility shim between the two
  states.
- Add the two **facet value classes** an argument needs: `CsFileReference` (the
  CE-DB file-backed column facet) and `CsGradedAccess` (§5.15's graded arm is a
  requirement *tree*, not a scalar).
- Per-kind attributes are rendered as **optional slots on one constructor**
  (`@CsTrigger`, `@CsAuthorize`, `@CsJob`) because Dart annotations have no sum
  types; a generation-time check asserts only the declared kind's slots are
  non-null — the annotation-level form of `codespecs_mapping.md` §8.2's
  `@OneOf`/`@Case`.
- `@CsValidation` takes `rules` **named** with a `''` default rather than the
  optional-positional shape `codespecs_derivation_contract.md` §5.1 first
  specified: Dart forbids mixing optional-positional and named parameters, and
  `note` is named family-wide.
- Tests const-construct every attribute-bearing marker with its **full** surface
  on a declaration of the shape the part actually marks — grouped by the
  `codespecs_mapping.md` §4.2 shared/client/server locus split — so placement is
  asserted by the declarations compiling, not by a bare stub class.

## 0.8.0

- csra8: add the four markers for CE-RP, promoted out of `codespecs_mapping.md`
  §4.3 — `@CsReport` (the grouped projection), `@CsReportColumn` (one projected
  output column), `@CsReportChart` (a chart over those columns) and
  `@CsReportParameter` (a runtime input). CE-RP is a part and **not** a
  composition of `@CsEndpoint` + `@CsTable` + `@CsForm`: none of those can hold
  a dimension or a measure, a report column is an *output projection* rather
  than an input field, and a chart has no home anywhere else.
- Four markers rather than one because the four are authored at different
  levels and referenced independently — the same reason CE-DB carries three and
  CE-NT two.
- Charts are **declared here, rendered by whoever can**: the declaration is
  authored input (chart type, series, axes), rendering is implementation-owned,
  and an export format that cannot express a chart omits it rather than failing.
- The deferred set is down to **CE-WF alone**, and it is deferred permanently:
  its SOM section is a single free-text field plus a diagram, so it fails the
  `codespecs_mapping.md` §8.1 authored-input test by construction.
  `CodeSpecPart` is unchanged at 28 values: promotion never moves a reserved
  kind out of its declared position.

## 0.7.0

- csra7: add the three markers for the two parts promoted out of
  `codespecs_mapping.md` §4.3 — `@CsAudited` (CE-LG) and `@CsNotification` +
  `@CsNotificationChannel` (CE-NT). Both parts pass the `codespecs_mapping.md`
  §8.1 authored-input test: their SOM sections are structured `@Form` blocks and
  entry lists, not free text, so a generator has something to read. CE-WF, whose
  section is a single free-text field plus a diagram, is deferred
  **permanently** for the same reason (`codespecs_mapping.md` §4.3.2).
- `@CsAudited` is deliberately thin: like `@CsServiceUnit` over `@tomService`,
  it marks the framework's own `@TomAudited` declaration rather than
  re-modelling it. Retention, log format and compliance reporting are **not**
  CE-LG — they are CE-CF settings on the sink.
- The deferred set is down to CE-RP (waiting on one substrate blocker) and
  CE-WF (decided). `CodeSpecPart` is unchanged at 28 values: promotion never
  moves a reserved kind out of its declared position.

## 0.6.0

- csra3: drop the `SettingsPersistence` enum and the `persistence` argument on
  `@CsUserSetting`. `codespecs_mapping.md` §11 makes each of the four
  configuration/settings parts single-moded — the scope key alone decides where
  a value lives — so the choice is *which marker you use*, never a mode on one
  of them. The `local` arm the enum offered is CE-DS `@CsDeviceSetting` (keyed
  by user *and* device); `@CsClientConfig` covers the no-user-in-the-key case.
  Keeping a mode argument on `@CsUserSetting` gave every scope decision two
  spellings, one of which contradicted `codespecs_mapping.md` §11.
- `@CsUserSetting`'s doc-comment now states the `codespecs_mapping.md` §4.2
  locus (client shape + server persistence) and the `codespecs_mapping.md` §5.16
  authorable surface (key · type · default) rather than a roaming/local choice.

**Breaking:** `SettingsPersistence` is gone and `@CsUserSetting(persistence: …)`
no longer compiles. `@CsUserSetting()` and `@CsUserSetting(note: …)` are
unchanged.

## 0.5.0

- csra2: add `TriggerKind` and make it a **required** argument on `@CsTrigger`
  (`codespecs_mapping.md` §5.20). The closed five — `userGesture`,
  `inFormEvent`, `lifecycle`, `serverEvent`, `condition` — select which per-kind
  attribute set a trigger carries, so no arm can be a default (the csra1
  `IdentityAttributePlacement` precedent).
- The taxonomy lands **here, on the annotation**, not in `tom_core_codespecs`:
  `codespecs_mapping.md` §4.1/§5.10/§5.20 record CE-AC as "no gap — full action
  implementation reused", so the trigger classification is documented over the
  reused `tom_flutter_ui` action classes rather than given a class of its own.

**Breaking:** `const CsTrigger()` no longer compiles — pass a `kind`.

## 0.4.0

- csra1: complete the `Cs*` family against the `codespecs_mapping.md` §4.1
  catalogue — the six parts that had a catalogue row but no marker now have one,
  bringing the family to 30 markers:
  - `@CsScreenFlow` (CE-NV) — the screen-flow edges beside `@CsRoute`:
    form→screen assignment, replace-vs-popup presentation, action-triggered
    conditional targets (`codespecs_mapping.md` §5.11).
  - `@CsDeviceSetting` (CE-DS) — the (user, device) settings scope, distinct
    from `@CsClientConfig` (no user in the key) and `@CsUserSetting` (follows
    the user) (`codespecs_mapping.md` §5.16, §11).
  - `@CsIdentity` + `@CsIdentityAttribute` (CE-ID) — the app's
    identity-extension holder and its members. `placement` is a **required**
    `IdentityAttributePlacement` (`public` | `encrypted`), so neither token
    payload arm is ever chosen by default (`codespecs_mapping.md` §5.24).
  - `@CsMigration` (CE-MG) — the SQL schema-migration artifact set
    (`codespecs_mapping.md` §5.27).
  - `@CsJob` (CE-JB) — background-job definitions (`codespecs_mapping.md`
    §5.29).
- Correct ten `Cs*` doc comments that named CE codes absent from the
  `codespecs_mapping.md` §4.1 registry
  (`CE-WI`/`FO`/`LA`/`TG`/`VM`/`RO`/`EP`/`TB`/`CO`/`RE`). The `CE-*` code is a
  stable registry key; where a part has several markers they now all name the
  one key it owns.
- No marker is added for the `codespecs_mapping.md` §4.3 deferred candidates
  (CE-RP, CE-WF, CE-NT, CE-LG) — a deferred part stays mapping-only until
  promoted.

## 0.3.0

- csm2r5: add the four new-part markers `@CsClient` (CE-CL), `@CsClientConfig`
  (CE-CC), `@CsUserSetting` (CE-UP, with a `SettingsPersistence` `local`/
  `roaming` discriminator per `codespecs_mapping.md` §11), and `@CsAuth`
  (CE-AU) — bringing the `Cs*` family to 24 markers. Grouped in
  `client_settings_annotations.dart`.
- `@CsServerConfig` (CE-CF) is the narrowed **server-only** configuration
  marker; user and client-machine settings are now the separate CE-UP / CE-CC
  parts.
- Paired with `tom_specs_core`: `CodeSpecPart` gains `client`,
  `clientConfiguration`, `userSettings`, `authentication` and renames
  `configuration` → `serverConfiguration` (20 active kind values).

## 0.2.0

- csm2r1: reshape the framework to **annotations only — no base classes, no
  `Ca*` prefix** (`codespecs_mapping.md` §0). A CodeSpec is now an ordinary
  class *built on* an existing `tom_core`-family class and *marked* by `Cs*`
  annotations.
- Adds the `Cs*` annotation family (20 markers): client/UI (`@CsElement`,
  `@CsWidget`, `@CsForm`, `@CsLayout`, `@CsText`, `@CsValidation`, `@CsAction`,
  `@CsTrigger`, `@CsServerCall`, `@CsViewModel`, `@CsRoute`), server
  (`@CsEndpoint`, `@CsServiceUnit`, `@CsTable`, `@CsColumn`, `@CsRepository`,
  `@CsAuthorize`, `@CsServerConfig`), shared (`@CsError`, `@CsEnum`).
- Adds the identity/forward-trace annotation `@CodeSpec(id, {source,
  requirements})` (CE-TR).
- The 4 new-part annotations (`@CsClientConfig` / `@CsUserSetting` /
  `@CsClient` / `@CsAuth`) and list-valued `@CodeSpecKind` land in csm2r5 /
  csm2r2.

## 0.1.0

- Initial scaffold (csm3). CodeSpecs framework home for TomSpecs Phase 4.
- Adds the code-side back-trace annotations `@DocSpec` and `DocRef`
  (`codespecs_mapping.md` §9.3).
