# Changelog

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
