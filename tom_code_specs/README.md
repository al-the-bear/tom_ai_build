# tom_code_specs — the CodeSpecs annotation framework

> **Cross-references.**
> [`tom_specs_model/doc/codespecs_mapping.md`](../tom_specs_model/doc/codespecs_mapping.md)
> owns the **parts catalogue** (`codespecs_mapping.md` §4.1), the per-part
> **spec-authorable attribute surfaces** (`codespecs_mapping.md` §5) and the
> **DocSpecs↔CodeSpecs link** (`codespecs_mapping.md` §9).
> [`tom_specs_model/doc/codespecs_derivation_contract.md`](../tom_specs_model/doc/codespecs_derivation_contract.md)
> owns **what code each marker produces** — its inputs, the exact Dart emitted,
> its `tom_core`-family superclass, the naming rules and the validator checks.
> This README is the catalogue of *what each annotation is and how to write
> it*; those documents own *which specification section it comes from* and
> *what the generator must emit for it*.

CodeSpecs framework — the Cs* annotation family (no base classes) and the
code-side DocSpecs↔CodeSpecs link annotations for TomSpecs Phase 4.

## Where this fits

**TomSpecs** builds software from structured specification documents in
phases. **Phase 4 — CodeSpecs** is the step that turns the Phase-3
specification documents into a **skeletal, compilable Dart application**: every
form, table, endpoint, route and error the specification describes appears as a
real declaration that compiles but does not yet execute. `tom_code_specs` is
the vocabulary that skeleton is written in — the `Cs*` annotations that say
*what each declaration is*, plus the annotations that trace it back to the
specification section it came from.

It exists so the skeleton is machine-checkable rather than merely plausible. A
generated declaration with no marker is a declaration nobody can validate,
count, or trace; with a marker, a generation-time validator can ask whether
every routed specification section produced a declaration and whether every
declaration cites a section. Phase 5 (test derivation) and Phase 6
(implementation) then read the code rather than reopening the Phase-3
documents.

So it sits between the model and the generated application: it depends only on
[`tom_specs_core`](../tom_specs_core) for the shared kind vocabulary, and the
concrete classes a CodeSpec is *built on* come from the `tom_core` family —
with the gaps `tom_core` genuinely lacks supplied by
[`tom_core_codespecs`](../../core/tom_core_codespecs).

## Overview

> **This is a code framework, not a document model**, and it carries
> **annotations only, no base classes**. All CodeSpecs annotations
> use the `Cs*` prefix (`@CsForm`, `@CsTable`, `@CsEndpoint`, …); there is **no
> `Ca*` prefix and no `Cs*` base class**. A CodeSpec is built on an existing
> `tom_core`-family class marked by `Cs*` annotations; the concrete classes
> `tom_core` lacks live in [`tom_core_codespecs`](../../core/tom_core_codespecs).
> The framework is owned by the **`tom_specs` quest** (the former `code_spec`
> quest is retired — see
> [codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) §1.1/§12).

A CodeSpec declaration is therefore an ordinary Dart class or member with three
layers of information on it:

1. **What part it is** — one `Cs*` marker, from the catalogue below.
2. **Its authored attributes** — the marker's arguments, drawn from closed
   catalogues and typed cross-part references rather than free strings.
3. **Where it came from** — `@CodeSpec` forward and `@DocSpec`/`DocRef`
   backward, so a reader of the code can find the section that specified it and
   a reader of the specification can find the code it produced.

## Installation

```yaml
dependencies:
  tom_code_specs: ^0.13.0
```

or

```bash
dart pub add tom_code_specs
```

```dart
import 'package:tom_code_specs/tom_code_specs.dart';
```

The barrel also re-exports `@CodeSpecKind` and `CodeSpecPart` from
[`tom_specs_core`](../tom_specs_core), so a CodeSpecs author has a single
import.

## Features

### What lives here

| Symbol | Role | Reference |
|--------|------|-----------|
| `@CodeSpec(id, {source, requirements})` | Identity + forward doc → code trace (CE-TR) on a CodeSpec class | `codespecs_mapping.md` §9 |
| `@DocSpec([DocRef(sectionId, description), …])` | Code → doc back-trace on a CodeSpec class/member | `codespecs_mapping.md` §9.3 |
| `DocRef(sectionId, description)` | One back-trace entry | `codespecs_mapping.md` §9.3 |
| `Cs*` annotation family (no base classes) — 39 markers | The catalogue's part markers, in four files — see the table below | `codespecs_mapping.md` §4.1 |
| `@CsCollaborator()` | The one marker that is **not** a part: the abstract collaborator a form-3b body calls | `codespecs_derivation_contract.md` §3.0.1 |
| `Cs*Ref` typed cross-part references — 13 consts | Annotation *parameter* vocabulary: one const type per referenceable part | `codespecs_mapping.md` §5.23 |
| The closed catalogues — 16 enums in `vocabulary.dart` | Annotation *parameter* vocabulary: the arms a marker's argument selects from | `codespecs_derivation_contract.md` §5.3 |

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
convention because
[`codespecs_derivation_contract.md`](../tom_specs_model/doc/codespecs_derivation_contract.md)
§2.7 point 4 requires one
on every generated top-level declaration and because the
`codespecs_derivation_contract.md` §6 checks have to find collaborators.

The [`codespecs_mapping.md`](../tom_specs_model/doc/codespecs_mapping.md) §4.3
**deferred** candidate — **CE-WF alone** —
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

`vocabulary.dart` holds the sixteen enums a marker's arguments select from
([`codespecs_derivation_contract.md`](../tom_specs_model/doc/codespecs_derivation_contract.md)
§5.3). They are enums rather than strings for
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
| `CsSensitivityLevel` | `@CsColumn(sensitivityLevel:)` |

Each is **declared here, not imported**: `tom_code_specs` deliberately does not
depend on `tom_core` (`codespecs_mapping.md` §9.5), so every catalogue with a
`tom_core` counterpart is a local mirror, and a named generation-time validator
check asserts the mirror stays complete.

## Quick start

A generated CodeSpecs declaration marks what it is, declares its identities as
consts, and traces itself back to the specification section that produced it.

```dart
// dart run example.dart
import 'package:tom_code_specs/tom_code_specs.dart';

/// The operations this application's client may invoke.
class Operations {
  static const registerCustomer = CsOperationRef('customer.register');
}

/// The customer registration form (CE-FM), as Phase 4 emits it.
@CodeSpec('customerForm')
@DocSpec([DocRef('XDS-FRM-001', 'Customer registration form')])
@CsForm()
class CustomerForm {
  @CsElement(kind: CsElementKind.textInput)
  String email = '';

  static const submits = Operations.registerCustomer;
}

void main() {
  print(CustomerForm.submits.id); // customer.register
  print(CodeSpecPart.values.length); // 28
}
```

## Usage

### Marking a part

Every generated top-level declaration carries exactly one part marker. Which
marker a specification section produces is decided by its `@CodeSpecKind` in
the model, not chosen here.

```dart
@CsTable()
class Customer {
  @CsColumn(sensitivityLevel: CsSensitivityLevel.personal)
  String email = '';
}
```

### Referring to another part

Cross-part edges are typed consts, so a rename fails to compile instead of
leaving a dangling id.

```dart
class Routes {
  static const customerDetail = CsRouteRef('customer.detail');
}

@CsAction()
class OpenCustomerDetail {
  static const target = Routes.customerDetail;
}
```

An edge that lands *inside* the part that authors it is a local coordinate and
stays a plain id string — that is why there is no `CsChannelRef`.

### Tracing back to the specification

`@DocSpec` carries one `DocRef` per section that shaped the declaration, so
Phases 5 and 6 read the code rather than reopening the Phase-3 documents. That
self-sufficiency rule is
[`codespecs_mapping.md`](../tom_specs_model/doc/codespecs_mapping.md) §9.6, and
two of the validator's checks exist to enforce it in both directions.

```dart
@CodeSpec('customerRepository', source: ['IFM-ENT-014'])
@DocSpec([
  DocRef('IFM-ENT-014', 'Customer entity'),
  DocRef('SAS-ACC-003', 'Customer data access rules'),
])
@CsRepository()
class CustomerRepository {}
```

## Architecture

```
tom_code_specs                       (depends only on tom_specs_core)
└── lib/src/annotations/
    ├── code_spec.dart               @CodeSpec — identity + forward trace
    ├── doc_spec.dart                @DocSpec / DocRef — back-trace
    ├── element_annotations.dart     14 client / UI markers
    ├── service_annotations.dart     16 server markers
    ├── contract_annotations.dart     2 shared markers
    ├── client_settings_annotations.dart  7 client-app / config / identity markers
    ├── cs_collaborator.dart         @CsCollaborator — the one non-part marker
    ├── cross_part_refs.dart         13 typed cross-part reference consts
    └── vocabulary.dart              16 closed catalogues + 2 facet value classes

  Phase 3 documents ──@CodeSpecKind──▶ routing ──▶ per-area extract
                                                        │
                                                        ▼
                                              authoring agent writes Dart
                                                        │
                                              marked with tom_code_specs
                                                        │
                                                        ▼
                                    shared / client / server project trio
                                                        │
                                                        ▼
                                      validator checks (derivation contract §6)
```

| Type | Responsibility |
| --- | --- |
| `CodeSpec` | Identity of a CodeSpec class plus its forward trace to source sections and requirements. |
| `DocSpec` / `DocRef` | The code → document back-trace: one entry per section that shaped the declaration. |
| The 39 `Cs*` part markers | Say which catalogue part a declaration is, and carry that part's authored attributes. |
| `CsCollaborator` | Marks the abstract collaborator a stub body calls — one per emitting top-level declaration; not a part. |
| The 13 `Cs*Ref` consts | Typed cross-part references; distinct types with no shared supertype, so a wrong kind is a compile error. |
| The 16 `vocabulary.dart` enums | The closed arms a marker's argument selects from — a value cannot be invented in passing. |
| `CsFileReference`, `CsGradedAccess` | The two facet value classes, for arguments that are structures rather than scalars. |

### What lives in `tom_specs_core` instead

The **forward**, model-side half of the link annotates the SOM, so it lives with
the other SOM annotations in [`tom_specs_core`](../tom_specs_core) (which
[`tom_specs_model`](../tom_specs_model) already
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

### The concrete instance-level link

The concrete forward link — the `codeSpec` `List<String>` member on
`DocSpecsSection`, serialized comma-separated inside the `sectionId` HTML
comment (`codespecs_mapping.md` §9.2) — is a **model member**, not an
annotation, so it lives in [`tom_specs_model`](../tom_specs_model) /
[`tom_specs_core`](../tom_specs_core). It is wired separately.

## Ecosystem

```
              tom_specs_core            @CodeSpecKind + CodeSpecPart
                     │
                     ▼
              tom_code_specs            ← this package: the Cs* markers
                     │
     marks ┌─────────┴──────────┐ built on
           ▼                    ▼
  generated CodeSpecs     tom_core family (kernel / flutter / server / d4rt,
  project trio            tom_flutter_ui) + tom_core_codespecs for the gaps
           │
           ▼
  tom_specs_clitool  bin/validate_codespecs.dart — the derivation-contract checks
```

## Further documentation

**TomSpecs subject matter** — the authorities this package implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of the whole TomSpecs document set, and the `§` citation convention |
| [codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) | Which SOM section feeds which part — the catalogue, the attribute surfaces, the generation slices, the DocSpecs↔CodeSpecs link |
| [codespecs_derivation_contract.md](../tom_specs_model/doc/codespecs_derivation_contract.md) | What code comes out per marker — inputs, emitted Dart, superclass, naming rules, stub bodies, constructor shapes, validator checks |
| [codespecs_prompt.md](../tom_specs_model/doc/codespecs_prompt.md) | When a Phase-4 run may begin at all — the mechanical gate and the per-area judgment |
| [tom_specs_project_flow.md](../tom_specs_model/doc/tom_specs_project_flow.md) | The phase model Phase 4 sits in, and the quality gate it must pass |
| [tom_specs_model_rules.md](../tom_specs_model/doc/tom_specs_model_rules.md) | The model-authoring rules behind the `@CodeSpecKind` routing this family consumes |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_specs_core](../tom_specs_core) | The SOM annotation vocabulary, and the home of `@CodeSpecKind` / `CodeSpecPart` |
| [tom_core_codespecs](../../core/tom_core_codespecs) | The concrete `tom_core`-family gap classes a CodeSpec is built on |
| [tom_specs_model](../tom_specs_model) | The SOM source model whose sections route into these parts |
| [tom_specs_clitool](../tom_specs_clitool) | The CodeSpecs validator and the area-catalogue generator |

## Status

Version **0.13.0**, published on pub.dev. Test suite: **87 tests, all passing**
(`dart test`).

`@CodeSpec`, `@DocSpec`/`DocRef`, the **39-marker `Cs*` family** plus
`@CsCollaborator`, the **13-const `Cs*Ref` family** and the **16 closed
catalogues** are declared — one marker (or marker group) for every active part in
the `codespecs_mapping.md` §4.1 catalogue, with no marker for a deferred one.
`@CodeSpecKind` is list-valued.

The family is a marker set **and** an attribute surface. **24 of the 40 markers
take arguments**, wired to `codespecs_mapping.md` §5's per-part spec-authorable
surface; the other **16 carry a single optional `note`** — a design decision, not
an omission, because everything their part authors is already carried by the
annotated declaration itself or by a `tom_core` substrate constructor. Which
attributes become constructor parameters is decided by
[`codespecs_derivation_contract.md`](../tom_specs_model/doc/codespecs_derivation_contract.md)
§2.3's three tests, and
`codespecs_derivation_contract.md` §5.1–§5.3 give the resulting shape of every
marker.

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
