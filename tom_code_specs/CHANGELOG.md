# Changelog

## 0.8.0

- csra8: add the four markers for CE-RP, promoted out of §4.3 — `@CsReport`
  (the grouped projection), `@CsReportColumn` (one projected output column),
  `@CsReportChart` (a chart over those columns) and `@CsReportParameter` (a
  runtime input). CE-RP is a part and **not** a composition of `@CsEndpoint` +
  `@CsTable` + `@CsForm`: none of those can hold a dimension or a measure, a
  report column is an *output projection* rather than an input field, and a
  chart has no home anywhere else.
- Four markers rather than one because the four are authored at different
  levels and referenced independently — the same reason CE-DB carries three and
  CE-NT two.
- Charts are **declared here, rendered by whoever can**: the declaration is
  authored input (chart type, series, axes), rendering is implementation-owned,
  and an export format that cannot express a chart omits it rather than failing.
- The deferred set is down to **CE-WF alone**, and it is deferred permanently:
  its SOM section is a single free-text field plus a diagram, so it fails the
  §8.1 authored-input test by construction. `CodeSpecPart` is unchanged at 28
  values: promotion never moves a reserved kind out of its declared position.

## 0.7.0

- csra7: add the three markers for the two parts promoted out of §4.3 —
  `@CsAudited` (CE-LG) and `@CsNotification` + `@CsNotificationChannel`
  (CE-NT). Both parts pass the §8.1 authored-input test: their SOM sections are
  structured `@Form` blocks and entry lists, not free text, so a generator has
  something to read. CE-WF, whose section is a single free-text field plus a
  diagram, is deferred **permanently** for the same reason (§4.3.2).
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
  spellings, one of which contradicted §11.
- `@CsUserSetting`'s doc-comment now states the §4.2 locus (client shape +
  server persistence) and the §5.16 authorable surface (key · type · default)
  rather than a roaming/local choice.

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
  §4.1/§5.10/§5.20 record CE-AC as "no gap — full action implementation reused",
  so the trigger classification is documented over the reused `tom_flutter_ui`
  action classes rather than given a class of its own.

**Breaking:** `const CsTrigger()` no longer compiles — pass a `kind`.

## 0.4.0

- csra1: complete the `Cs*` family against the §4.1 catalogue — the six parts
  that had a catalogue row but no marker now have one, bringing the family to
  30 markers:
  - `@CsScreenFlow` (CE-NV) — the screen-flow edges beside `@CsRoute`:
    form→screen assignment, replace-vs-popup presentation, action-triggered
    conditional targets (§5.11).
  - `@CsDeviceSetting` (CE-DS) — the (user, device) settings scope, distinct
    from `@CsClientConfig` (no user in the key) and `@CsUserSetting` (follows
    the user) (§5.16, §11).
  - `@CsIdentity` + `@CsIdentityAttribute` (CE-ID) — the app's
    identity-extension holder and its members. `placement` is a **required**
    `IdentityAttributePlacement` (`public` | `encrypted`), so neither token
    payload arm is ever chosen by default (§5.24).
  - `@CsMigration` (CE-MG) — the SQL schema-migration artifact set (§5.27).
  - `@CsJob` (CE-JB) — background-job definitions (§5.29).
- Correct ten `Cs*` doc comments that named CE codes absent from the §4.1
  registry (`CE-WI`/`FO`/`LA`/`TG`/`VM`/`RO`/`EP`/`TB`/`CO`/`RE`). The `CE-*`
  code is a stable registry key; where a part has several markers they now all
  name the one key it owns.
- No marker is added for the §4.3 deferred candidates (CE-RP, CE-WF, CE-NT,
  CE-LG) — a deferred part stays mapping-only until promoted.

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
