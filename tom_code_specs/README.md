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
| `@CsCollaborator()` | The one marker that is **not** a part: the abstract collaborator a form-3b body calls | `codespecs_derivation_contract.md` §3.0.1 |
| `Cs*Ref` typed cross-part references — 13 consts | Annotation *parameter* vocabulary: one const type per referenceable part | `codespecs_mapping.md` §5.23 |
| The closed catalogues — 15 enums in `vocabulary.dart` | Annotation *parameter* vocabulary: the arms a marker's argument selects from | `codespecs_derivation_contract.md` §5.3 |

### The `Cs*` family

One marker file per concern. A part's `CE-*` code is its **stable registry
key**, so several markers may share one code (CE-EL, CE-AC, CE-NV, CE-DB, CE-NT
and CE-RP each have more than one).

| File | Markers | Parts |
|------|---------|-------|
| `element_annotations.dart` | `@CsElement`, `@CsWidget`, `@CsForm`, `@CsLayout`, `@CsText`, `@CsValidation`, `@CsFieldRule`, `@CsFormRule`, `@CsAction`, `@CsTrigger`, `@CsServerCall`, `@CsViewModel`, `@CsRoute`, `@CsScreenFlow` | Client / UI — CE-EL, CE-FM, CE-LO, CE-TX, CE-VA, CE-AC, CE-SC, CE-ST, CE-NV |
| `service_annotations.dart` | `@CsEndpoint`, `@CsServiceUnit`, `@CsTable`, `@CsColumn` *(with the `CsFileReference` facet)*, `@CsRepository`, `@CsAuthorize` *(with the `CsGradedAccess` facet)*, `@CsServerConfig`, `@CsMigration`, `@CsJob`, `@CsAudited`, `@CsNotification`, `@CsNotificationChannel`, `@CsReport`, `@CsReportColumn`, `@CsReportChart`, `@CsReportParameter` | Server — CE-API, CE-SU, CE-DB, CE-AZ, CE-CF, CE-MG, CE-JB, CE-LG; CE-NT (declarations shared, delivery server); CE-RP (definition server, result envelope + parameters shared) |
| `contract_annotations.dart` | `@CsError`, `@CsEnum` | Shared — CE-ER, plus the `domainEnum` **member** kind |
| `client_settings_annotations.dart` | `@CsClient`, `@CsClientConfig`, `@CsDeviceSetting`, `@CsUserSetting`, `@CsIdentity`, `@CsIdentityAttribute`, `@CsAuth` | Client app, the four owner-keyed config/settings scopes, identity and auth — CE-CL, CE-CC, CE-DS, CE-UP, CE-ID, CE-AU |

`cs_collaborator.dart` sits beside those four and holds `@CsCollaborator`, which
belongs to **no** part, locus or slice. It marks the abstract class a form-3b
body calls: one per emitting declaration, holding one abstract method per
contributing step and nothing else, reached through the declaration's single
`late final … collaborator;` field. It is a marker rather than a naming
convention because `codespecs_derivation_contract.md` §2.7 point 4 requires one
on every generated top-level declaration and because the §6 checks have to find
collaborators.

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

The family is **cross**-part. An edge landing inside the part that authors it is
a *local coordinate*, not a reference, and stays an id string guarded by a
generation-time validator check: a CE-LO delta's node id, and a CE-NT channel's
fallback — which names a **sibling channel**. That is why the family has no
`CsChannelRef`.

### The closed catalogues

`vocabulary.dart` holds the fifteen enums a marker's arguments select from
(`codespecs_derivation_contract.md` §5.3). They are enums rather than strings for
the same reason the refs are consts: a catalogue grows by a reviewed taxonomy
edit, not by a specification inventing a value in passing.

| Enum | Selected by |
|------|-------------|
| `CsElementKind` | `@CsElement(kind:)` |
| `CsTextRole`, `CsTextCategory` | `@CsText(role:, category:)` |
| `CsTriggerKind`, `CsGesture`, `CsFormEvent`, `CsLifecycleScope`, `CsLifecyclePhase` | `@CsTrigger`'s kind and its per-kind slots |
| `CsLifecycleScope` | also `@CsViewModel(scope:)` |
| `CsErrorSeverity` | `@CsError(severity:)` |
| `CsAuthRequirement` | `@CsAuthorize(requirement:)` |
| `CsMigrationKind` | `@CsMigration(kind:)` |
| `CsJobTrigger` | `@CsJob(trigger:)` |
| `CsClientKind` | `@CsClient(kind:)` |
| `CsIdentityAttributePlacement` | `@CsIdentityAttribute(placement:)` |
| `CsOverridableBy` | `@CsServerConfig` / `@CsClientConfig` / `@CsUserSetting` `(overridableBy:)` |

Each is **declared here, not imported**: `tom_code_specs` deliberately does not
depend on `tom_core` (`codespecs_mapping.md` §9.5), so every catalogue with a
`tom_core` counterpart is a local mirror, and a named generation-time validator
check asserts the mirror stays complete.

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

`@CodeSpec`, `@DocSpec`/`DocRef`, the **39-marker `Cs*` family** plus
`@CsCollaborator`, the **13-const `Cs*Ref` family** and the **15 closed
catalogues** are declared — one marker (or marker group) for every active part in
the `codespecs_mapping.md` §4.1 catalogue, with no marker for a deferred one.
`@CodeSpecKind` is list-valued.

The family is a marker set **and** an attribute surface. **24 of the 40 markers
take arguments**, wired to `codespecs_mapping.md` §5's per-part spec-authorable
surface; the other **16 carry a single optional `note`** — a design decision, not
an omission, because everything their part authors is already carried by the
annotated declaration itself or by a `tom_core` substrate constructor. Which
attributes become constructor parameters is decided by
`../tom_specs_model/doc/codespecs_derivation_contract.md` §2.3's three tests, and
its §5.1–§5.3 give the resulting shape of every marker.

Two shaping rules run through the whole family. An argument is **required** iff
no *fail-safe* default exists (`codespecs_mapping.md` §5.16: broadening a value's
blast radius must be a deliberate authored act) — which is why `@CsAuthorize`'s
`requirement` and `@CsIdentityAttribute`'s `placement` have no default. And where
a part's attributes differ per kind, Dart's lack of annotation sum types is
rendered as **per-kind optional slots** on one constructor (`@CsTrigger`,
`@CsAuthorize`, `@CsJob`), with a generation-time check asserting only the
declared kind's slots are non-null — the annotation-level form of
`codespecs_mapping.md` §8.2's `@OneOf`/`@Case`.

`@CsUserSetting` has no `persistence` argument: `codespecs_mapping.md` §11 makes
each of the four configuration/settings parts single-moded, so a scope decision
is expressed by *which marker you use*, never by a mode on one of them.
