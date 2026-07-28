# tom_code_specs

The **CodeSpecs framework** for TomSpecs **Phase 4** — the code home for the
`Cs*` **annotation family** and the code-side DocSpecs↔CodeSpecs link annotations.

CodeSpecs turns the Phase 3 specification documents (the DocSpecs, typed by the
**SOM** — `tom_specs_model`) into a **skeletal, compilable Dart application**
whose every element carries traceability annotations back to its source spec.

> **This is a code framework, not a document model** — and (2026-07-19 revision)
> it carries **annotations only, no base classes**. All CodeSpecs annotations
> use the `Cs*` prefix (`@CsForm`, `@CsTable`, `@CsEndpoint`, …); there is **no
> `Ca*` prefix and no `Cs*` base class**. A CodeSpec is built on an existing
> `tom_core`-family class marked by `Cs*` annotations; the concrete classes
> `tom_core` lacks live in `tom_core_codespecs`. The framework is owned by the
> **`tom_specs` quest** (the former `code_spec` quest is retired — see
> `../tom_specs_model/doc/codespecs_mapping.md` §1.1/§12).

## What lives here

| Symbol | Role | Reference |
|--------|------|-----------|
| `@CodeSpec(id, {source, requirements})` | Identity + forward doc → code trace (CE-TR) on a CodeSpec class | `codespecs_mapping.md` §9 |
| `@DocSpec([DocRef(sectionId, description), …])` | Code → doc back-trace on a CodeSpec class/member | `codespecs_mapping.md` §9.3 |
| `DocRef(sectionId, description)` | One back-trace entry | `codespecs_mapping.md` §9.3 |
| `Cs*` annotation family (no base classes) — 39 markers | The catalogue's part markers, in four files — see the table below | `codespecs_mapping.md` §4.1 |
| `Cs*Ref` typed cross-part references — 13 consts | Annotation *parameter* vocabulary: one const type per referenceable part | `codespecs_mapping.md` §5.23 |

### The `Cs*` family

One marker file per concern. A part's `CE-*` code is its **stable registry
key**, so several markers may share one code (CE-EL, CE-AC, CE-NV, CE-DB, CE-NT
and CE-RP each have more than one).

| File | Markers | Parts |
|------|---------|-------|
| `element_annotations.dart` | `@CsElement`, `@CsWidget`, `@CsForm`, `@CsLayout`, `@CsText`, `@CsValidation`, `@CsFieldRule`, `@CsFormRule`, `@CsAction`, `@CsTrigger` *(with `TriggerKind`)*, `@CsServerCall`, `@CsViewModel`, `@CsRoute`, `@CsScreenFlow` | Client / UI — CE-EL, CE-FM, CE-LO, CE-TX, CE-VA, CE-AC, CE-SC, CE-ST, CE-NV |
| `service_annotations.dart` | `@CsEndpoint`, `@CsServiceUnit`, `@CsTable`, `@CsColumn`, `@CsRepository`, `@CsAuthorize`, `@CsServerConfig`, `@CsMigration`, `@CsJob`, `@CsAudited`, `@CsNotification`, `@CsNotificationChannel`, `@CsReport`, `@CsReportColumn`, `@CsReportChart`, `@CsReportParameter` | Server — CE-API, CE-SU, CE-DB, CE-AZ, CE-CF, CE-MG, CE-JB, CE-LG; CE-NT (declarations shared, delivery server); CE-RP (definition server, result envelope + parameters shared) |
| `contract_annotations.dart` | `@CsError`, `@CsEnum` | Shared — CE-ER, plus the `domainEnum` **member** kind |
| `client_settings_annotations.dart` | `@CsClient`, `@CsClientConfig`, `@CsDeviceSetting`, `@CsUserSetting`, `@CsIdentity`, `@CsIdentityAttribute` *(with `IdentityAttributePlacement`)*, `@CsAuth` | Client app, the four owner-keyed config/settings scopes, identity and auth — CE-CL, CE-CC, CE-DS, CE-UP, CE-ID, CE-AU |

The `codespecs_mapping.md` §4.3 **deferred** candidate — **CE-WF alone** —
deliberately has **no marker**: a deferred part is mapping-only, so its
`CodeSpecPart` value is reserved and a SOM section can already carry
`@CodeSpecKind`, but there is no annotation, no built-on `tom_core` class and no
generated code until it is promoted into `codespecs_mapping.md` §4.1. CE-WF is
deferred **permanently**: its SOM section is a single free-text field plus a
diagram, so there is no machine-readable input a generator could read
(`codespecs_mapping.md` §4.3.2).

### The `Cs*Ref` family

`cross_part_refs.dart` holds the thirteen typed cross-part reference consts. A
reference from one part to another is a **Dart const, never a string literal**:
the owning part declares each identity once on its catalogue class, and every
citing site holds that const, so a rename is a compile error rather than a
dangling id.

| Locus | Ref types |
|-------|-----------|
| Shared | `CsOperationRef`, `CsMessageKey`, `CsErrorCode`, `CsRoleRef`, `CsResourceKeyRef` |
| Client | `CsCallRef`, `CsActionRef`, `CsRouteRef`, `CsElementRef`, `CsFormRef` |
| Server | `CsServiceUnitRef`, `CsReportRef`, `CsJobRef` |

```dart
// declared once, on the owning part's catalogue class
static const login = CsOperationRef('login');

// cited elsewhere — the const, never a copy of its string
static const operation = Operations.login;
```

They are **distinct types with no shared supertype**: passing a route ref where
an operation ref is expected must itself be a compile error, and a common base
would accept every kind. `CsElementRef` is the one qualifiable ref — a form-member
element carries the owning form (`CsElementRef('email', form: 'customerForm')`,
whose `path` is `customerForm.email`), because `@CsTrigger` takes a `CsElementRef`
in both its element and its form-field slot.

Entities and DTOs are **absent by design** — they are already Dart types, so
they are cited by `Type` literal. Four further reference kinds stay strings per
`codespecs_mapping.md` §5.23: setting keys and their env/cmdline aliases,
deployment-environment names, CE-MG migration filenames, and doc-side `codeSpec`
locations / `@DocSpec` section ids.

## What lives in `tom_specs_core` instead

The **forward**, model-side half of the link annotates the SOM, so it lives with
the other SOM annotations in `tom_specs_core` (which `tom_specs_model` already
depends on — keeping the model → core dependency direction):

- `@CodeSpecKind(List<CodeSpecPart> kinds, {String? note})` — the type-level
  "this section type realises these CodeSpecs kind(s)" link; **list-valued**
  since a section/field may map to several kinds (`codespecs_mapping.md` §9.1).
- `CodeSpecPart` — the enum of the catalogue's kind vocabulary
  (`codespecs_mapping.md` §4.1): the 26 active parts, the `domainEnum` member
  kind and the 1 deferred candidate. Promotion never moves a value — a reserved
  kind keeps its declared position, so the enum stays at 28 whichever readiness
  class a part is in.

Both are re-exported from `package:tom_code_specs/tom_code_specs.dart` so a
CodeSpecs author has a single import.

## The concrete instance-level link

The concrete forward link — the `codeSpec` `List<String>` member on
`DocSpecsSection`, serialized comma-separated inside the `sectionId` HTML
comment (`codespecs_mapping.md` §9.2) — is a **model member**, not an
annotation, so it lives in `tom_specs_model` / `tom_specs_core`. It is wired
separately.

## Status

`@CodeSpec`, `@DocSpec`/`DocRef`, the **39-marker `Cs*` family** and the
**13-const `Cs*Ref` family** are declared — one marker (or marker group) for
every active part in the `codespecs_mapping.md` §4.1 catalogue, with no marker
for a deferred one. `@CodeSpecKind` is list-valued.

The markers are still **pure markers**: apart from the required `placement` on
`@CsIdentityAttribute` and the required `kind` on `@CsTrigger`, each carries
only an optional `note` — so the ref consts exist but no marker yet takes one as
a parameter. `@CsUserSetting` has no `persistence` argument:
`codespecs_mapping.md` §11 makes each of the four configuration/settings parts
single-moded, so a scope decision is expressed by *which marker you use*, never
by a mode on one of them.

Outstanding is the per-part attribute surface (`codespecs_mapping.md` §5) — the
constructor arguments, including the ref parameters, that
`../tom_specs_model/doc/codespecs_derivation_contract.md` §5 already specifies
marker by marker.
