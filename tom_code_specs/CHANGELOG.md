# Changelog

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
