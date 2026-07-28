# tom_code_specs

The **CodeSpecs framework** for TomSpecs **Phase 4** — the code home for the
`Cs*` **annotation family** and the code-side DocSpecs↔CodeSpecs link annotations.

CodeSpecs turns the Phase 3 specification documents (the DocSpecs, typed by the
**SOM** — `tom_specs_model`) into a **skeletal, compilable Dart application**
whose every element carries traceability annotations back to its source spec.

> **This is a code framework, not a document model** — and (2026-07-19 revision)
> it carries **annotations only, no base classes**. All CodeSpecs annotations use
> the `Cs*` prefix (`@CsForm`, `@CsTable`, `@CsEndpoint`, …); there is **no `Ca*`
> prefix and no `Cs*` base class**. A CodeSpec is built on an existing
> `tom_core`-family class marked by `Cs*` annotations; the concrete classes
> `tom_core` lacks live in `tom_core_codespecs`. The framework is owned by the
> **`tom_specs` quest** (the former `code_spec` quest is retired — see
> `../tom_specs_model/doc/codespecs_mapping.md` §0/§12).

## What lives here

| Symbol | Role | Reference |
|--------|------|-----------|
| `@CodeSpec(id, {source, requirements})` | Identity + forward doc → code trace (CE-TR) on a CodeSpec class | `codespecs_mapping.md` §9 |
| `@DocSpec([DocRef(sectionId, description), …])` | Code → doc back-trace on a CodeSpec class/member | §9.3 |
| `DocRef(sectionId, description)` | One back-trace entry | §9.3 |
| `Cs*` annotation family (no base classes) — 30 markers | The catalogue's part markers, in four files — see the table below | §4.1 |

### The `Cs*` family

One marker file per concern. A part's `CE-*` code is its **stable registry
key**, so several markers may share one code (CE-EL, CE-AC, CE-NV and CE-DB each
have more than one).

| File | Markers | Parts |
|------|---------|-------|
| `element_annotations.dart` | `@CsElement`, `@CsWidget`, `@CsForm`, `@CsLayout`, `@CsText`, `@CsValidation`, `@CsAction`, `@CsTrigger` *(with `TriggerKind`)*, `@CsServerCall`, `@CsViewModel`, `@CsRoute`, `@CsScreenFlow` | Client / UI — CE-EL, CE-FM, CE-LO, CE-TX, CE-VA, CE-AC, CE-SC, CE-ST, CE-NV |
| `service_annotations.dart` | `@CsEndpoint`, `@CsServiceUnit`, `@CsTable`, `@CsColumn`, `@CsRepository`, `@CsAuthorize`, `@CsServerConfig`, `@CsMigration`, `@CsJob` | Server — CE-API, CE-SU, CE-DB, CE-AZ, CE-CF, CE-MG, CE-JB |
| `contract_annotations.dart` | `@CsError`, `@CsEnum` | Shared — CE-ER, plus the `domainEnum` **member** kind |
| `client_settings_annotations.dart` | `@CsClient`, `@CsClientConfig`, `@CsDeviceSetting`, `@CsUserSetting`, `@CsIdentity`, `@CsIdentityAttribute` *(with `IdentityAttributePlacement`)*, `@CsAuth` | Client app, the four owner-keyed config/settings scopes, identity and auth — CE-CL, CE-CC, CE-DS, CE-UP, CE-ID, CE-AU |

The §4.3 **deferred** candidates (CE-RP, CE-WF, CE-NT, CE-LG) deliberately have
**no marker**: a deferred part is mapping-only — its `CodeSpecPart` value is
reserved so a SOM section can already carry `@CodeSpecKind`, but there is no
annotation, no built-on `tom_core` class and no generated code until it is
promoted into §4.1.

## What lives in `tom_specs_core` instead

The **forward**, model-side half of the link annotates the SOM, so it lives with
the other SOM annotations in `tom_specs_core` (which `tom_specs_model` already
depends on — keeping the model → core dependency direction):

- `@CodeSpecKind(List<CodeSpecPart> kinds, {String? note})` — the type-level "this
  section type realises these CodeSpecs kind(s)" link; **list-valued** since a
  section/field may map to several kinds (§9.1).
- `CodeSpecPart` — the enum of the catalogue's kind vocabulary (§4.1): the 23
  active parts, the `domainEnum` member kind and the 4 deferred candidates.

Both are re-exported from `package:tom_code_specs/tom_code_specs.dart` so a
CodeSpecs author has a single import.

## The concrete instance-level link

The concrete forward link — the `codeSpec` `List<String>` member on
`DocSpecsSection`, serialized comma-separated inside the `sectionId` HTML comment
(§9.2) — is a **model member**, not an annotation, so it lives in
`tom_specs_model` / `tom_specs_core`. It is wired separately.

## Status

`@CodeSpec`, `@DocSpec`/`DocRef` and the **30-marker `Cs*` family** are
declared — one marker (or marker group) for every active part in the §4.1
catalogue, with no marker for a deferred one. `@CodeSpecKind` is list-valued.

The markers are still **pure markers**: apart from the required `placement` on
`@CsIdentityAttribute` and the required `kind` on `@CsTrigger`, each carries only
an optional `note`. `@CsUserSetting` lost its `persistence` argument in csra3 —
§11 makes each of the four configuration/settings parts single-moded, so a scope
decision is expressed by *which marker you use*, never by a mode on one of them.

The per-part attribute surfaces (§5) and the typed `Cs*Ref` cross-part reference
consts (§5.23) are separate work, as is the per-annotation derivation contract
that says exactly which generated Dart each annotation produces.
