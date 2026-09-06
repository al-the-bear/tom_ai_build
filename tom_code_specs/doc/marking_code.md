# TomSpecs CodeSpecs — Marking Code

A CodeSpec is an ordinary Dart class built on an existing `tom_core`-family
class and *marked* by the annotations in this package. This guide covers how the
markers are applied: the identity annotation every emission unit carries, the
forty `Cs*` part markers, the collaborator marker that is not a part, and the
note-only / argument-carrying split. What code each marker produces is
[`codespecs_derivation_contract.md`](../../tom_specs_model/doc/codespecs_derivation_contract.md);
which specification section feeds which part is
[`codespecs_mapping.md`](../../tom_specs_model/doc/codespecs_mapping.md). Both
are cited here, never restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [@CodeSpec — identity and forward trace](#codespec--identity-and-forward-trace)
  - [The part markers](#the-part-markers)
  - [@CsCollaborator — the one marker that is not a part](#cscollaborator--the-one-marker-that-is-not-a-part)
- [Note-only versus argument-carrying](#note-only-versus-argument-carrying)
- [The facet value classes](#the-facet-value-classes)
- [Placing a marker in the trio](#placing-a-marker-in-the-trio)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

Everything in this package is an annotation or annotation-parameter vocabulary.
There are **no base classes**: a CodeSpec inherits from a `tom_core`-family
class, and the markers say what role that class plays. The package's whole
run-time behaviour is therefore nil — the readers are the Phase-4 authoring
agent, the generation-time validator (`validate_codespecs.dart` in
`tom_specs_clitool`), and the Dart compiler itself, which is what turns a
renamed cross-part reference into a compile error.

The surface divides into five kinds of declaration:

| Kind | Count | Example |
|------|-------|---------|
| Part markers | 39 | `@CsTable`, `@CsEndpoint`, `@CsForm` |
| The collaborator marker | 1 | `@CsCollaborator` |
| Facet value classes | 2 | `CsFileReference`, `CsGradedAccess` |
| Identity and trace annotations | 3 | `@CodeSpec`, `@DocSpec`, `DocRef` |
| Closed catalogues (enums) | 16 | `CsElementKind`, `CsAuthRequirement` |

Cross-part references are a sixth group covered in
[cross_references.md](cross_references.md); the catalogues are covered in
[vocabulary.md](vocabulary.md).

## Quick Start

A marked CodeSpec class carries three things: what it *is* (the part marker),
who it *is* (`@CodeSpec`), and where it *came from* (`@DocSpec`).

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

@CsTable('orders')
@CodeSpec('DB-ORDER', source: ['IMO-014'], requirements: ['RC-ORD-010'])
@DocSpec([
  DocRef('IMO-014', 'Order entity fields and constraints'),
  DocRef('RSP-042', 'total must be non-negative'),
])
class Order {
  @CsColumn(column: 'total_amount')
  double total = 0;
}

void main() {
  const marker = CsTable('orders');
  const identity =
      CodeSpec('DB-ORDER', source: ['IMO-014'], requirements: ['RC-ORD-010']);
  const trace = DocSpec([DocRef('IMO-014', 'Order entity fields')]);

  print(marker.table);
  print('${identity.id} <- ${identity.source} satisfies ${identity.requirements}');
  print('${trace.refs.single.sectionId}: ${trace.refs.single.description}');
}
```

Output:

```
orders
DB-ORDER <- [IMO-014] satisfies [RC-ORD-010]
IMO-014: Order entity fields
```

## Core Components

### `@CodeSpec` — identity and forward trace

`@CodeSpec` sits on the **top-level declaration** — the emission unit — and
never on a member. Its three fields are the forward half of traceability:

| Field | Type | Holds |
|-------|------|-------|
| `id` | `String` | A stable identifier for this CodeSpec element |
| `source` | `List<String>` | The SOM `@SectionId`s this code realises |
| `requirements` | `List<String>` | The requirement ids this code satisfies |

The placement asymmetry with `@DocSpec` is deliberate and load-bearing:
`@CodeSpec` accounts for the **whole unit**, so a section that only a *member*
cites still belongs in the class's `source`. The gap analysis reads `source` and
never looks inside a class, so a section left off the class list reads as
unrealised even though a member realises it.

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  // A class whose member — not the class itself — consumed RSP-042.
  // The section still belongs in the class's `source`.
  const spec = CodeSpec(
    'DB-ORDER',
    source: ['IMO-014', 'RSP-042'],
    requirements: ['RC-ORD-010', 'RC-ORD-011'],
  );

  print(spec.source.length);
  print(spec.source.contains('RSP-042'));
  print(spec.requirements.join(' + '));
}
```

Output:

```
2
true
RC-ORD-010 + RC-ORD-011
```

### The part markers

Thirty-nine markers, grouped into four files by locus and concern. A part's
`CE-*` code is a **registry key**, not a marker name, so several markers can
share one code:

| File | Markers | Concern |
|------|---------|---------|
| `element_annotations.dart` | `@CsElement`, `@CsWidget`, `@CsForm`, `@CsLayout`, `@CsText`, `@CsValidation`, `@CsFieldRule`, `@CsFormRule`, `@CsAction`, `@CsTrigger`, `@CsServerCall`, `@CsViewModel`, `@CsRoute`, `@CsScreenFlow` | Client / UI |
| `service_annotations.dart` | `@CsEndpoint`, `@CsServiceUnit`, `@CsTable`, `@CsColumn`, `@CsRepository`, `@CsAuthorize`, `@CsServerConfig`, `@CsMigration`, `@CsJob`, `@CsAudited`, `@CsNotification`, `@CsNotificationChannel`, `@CsReport`, `@CsReportColumn`, `@CsReportChart`, `@CsReportParameter` | Server |
| `contract_annotations.dart` | `@CsError`, `@CsEnum` | Shared contract |
| `client_settings_annotations.dart` | `@CsClient`, `@CsClientConfig`, `@CsDeviceSetting`, `@CsUserSetting`, `@CsIdentity`, `@CsIdentityAttribute`, `@CsAuth` | Client app, the four settings scopes, identity, auth |

One part in the catalogue deliberately has **no marker**: the deferred CE-WF
candidate. A deferred part is mapping-only — its `CodeSpecPart` value is
reserved and a specification section may already carry `@CodeSpecKind` for it,
but there is no annotation and no generated code until it is promoted.

### `@CsCollaborator` — the one marker that is not a part

`@CsCollaborator` has no `CE-*` code, no `CodeSpecPart` value and no row in the
parts catalogue, and the distinction is precise: **a part is what a
specification section is realised as; a collaborator is what a realisation's
body needs in order to compile.**

It marks the abstract class a pseudo-implementation calls — one per emitting
top-level declaration, holding one abstract method per contributing step and
nothing else: no field, no constructor, no static, no implemented member. The
calling declaration reaches it through a single field:

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  /// Persist the edited customer and return the stored aggregate.
  Future<void> saveCustomer();
}

class CustomerActionController {
  late final CustomerActionControllerCollaborator collaborator;
}

void main() {
  const marker = CsCollaborator();
  print(marker.note);
  print(CustomerActionController().runtimeType);
}
```

Output:

```
null
CustomerActionController
```

It is a marker rather than a naming convention because every generated top-level
declaration must carry a `Cs*` marker, and because the validator has to *find*
collaborators — a name suffix would make convention load-bearing.

## Note-only versus argument-carrying

Of the forty markers, **sixteen carry a single optional `note`** and **twenty-four
take arguments**. The split is a decision, not an accident: a note-only marker's
attributes are already carried by the annotated Dart declaration or by its
`tom_core` substrate, so an argument would give them a second home.

| Marker takes | Because | Examples |
|--------------|---------|----------|
| Only `note` | The declaration or its substrate already carries every attribute | `@CsForm`, `@CsRepository`, `@CsAction`, `@CsReport` |
| Arguments | The attribute has nowhere else to live | `@CsTable('orders')`, `@CsElement(kind:)`, `@CsAuthorize(requirement:)` |

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  // Note-only: the form's fields are the annotated class's members.
  const form = CsForm(note: 'Customer master form.');

  // Argument-carrying: the table name is not derivable from the class name.
  const table = CsTable('orders', schema: 'sales');

  // Argument-carrying with a closed catalogue.
  const element = CsElement(kind: CsElementKind.textInput);

  print(form.note);
  print('${table.table} in ${table.schema}');
  print(element.kind.name);
}
```

Output:

```
Customer master form.
orders in sales
textInput
```

## The facet value classes

Two arguments are structures rather than scalars, so they have value classes of
their own. Neither is a marker — like `DocRef`, they are annotation *parameter*
vocabulary:

| Class | Passed to | Carries |
|-------|-----------|---------|
| `CsFileReference` | `@CsColumn(fileReference:)` | The key prefix, store, cascade-delete behaviour and accepted media types of a file-valued column |
| `CsGradedAccess` | `@CsAuthorize(graded:)` | Three nested `@CsAuthorize` requirements — one each for full, read and disabled access |

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  const attachment = CsFileReference(
    keyPrefix: 'orders/attachments',
    defaultMediaType: 'application/pdf',
    acceptedMediaTypes: ['application/pdf', 'image/png'],
  );

  // Each grade is itself a requirement, not a role list: `read` and
  // `disabled` may be left null, in which case they inherit from the grade
  // above them.
  const graded = CsGradedAccess(
    full: CsAuthorize(
        requirement: CsAuthRequirement.role,
        roles: [CsRoleRef('salesManager')]),
    read: CsAuthorize(
        requirement: CsAuthRequirement.role,
        roles: [CsRoleRef('salesAgent')]),
  );

  print('${attachment.keyPrefix} cascadeDelete=${attachment.cascadeDelete}');
  print(attachment.acceptedMediaTypes.join(', '));
  print('full roles: ${graded.full!.roles.map((r) => r.id).toList()}');
  print('read roles: ${graded.read!.roles.map((r) => r.id).toList()}');
  print('disabled inherits from read: ${graded.disabled == null}');
}
```

Output:

```
orders/attachments cascadeDelete=true
application/pdf, image/png
full roles: [salesManager]
read roles: [salesAgent]
disabled inherits from read: true
```

Note that `roles` is `List<CsRoleRef>`, not `List<String>` — even inside a
nested facet, a cross-part edge is a typed const. Two defaults are also worth
knowing. `CsFileReference.cascadeDelete` is `true` — deleting
the owning row deletes the file unless the specification says otherwise. And
`CsGradedAccess` **inherits downwards**: a null `read` falls back to `full`, and
a null `disabled` falls back to `read`, so only the grades that actually differ
need stating.

## Placing a marker in the trio

Phase 4 emits three projects — shared, client-only and server-only — and a
marker's file tells you which one its declarations land in. The rule is the
dependency arrow: shared code may not reference client or server code, so a
declaration cited from both sides is shared.

| Marker group | Project |
|--------------|---------|
| `contract_annotations.dart` (`@CsError`, `@CsEnum`) | Shared |
| `element_annotations.dart` | Client |
| `service_annotations.dart` | Server |
| `client_settings_annotations.dart` | Client, except the identity attributes the server persists |
| `@CsCollaborator` | Whichever project the declaration it serves lands in |

`@CsCollaborator` has no fixed locus for exactly the reason it has no slice: it
belongs to whichever declaration emitted it. The authoritative placement per
part is `codespecs_mapping.md` §4.2.

## Error Handling

No annotation here throws or validates. Every diagnostic is raised by one of
three readers, and knowing which one saves debugging time:

| Mistake | Caught by | When |
|---------|-----------|------|
| A cross-part reference to a declaration that no longer exists | The **Dart compiler** | At compile time — the ref is a const, not a string |
| A `@CsTrigger` carrying a slot its `kind` does not permit | `validate_codespecs.dart` | At generation time |
| A generated top-level declaration with no `Cs*` marker | The same validator | At generation time |
| A `@CodeSpec.source` missing a section a member realised | The gap analysis | At generation time |
| A collaborator method with no behaviour on its doc comment | The same validator, fatal | At generation time |

Per-kind slot exclusivity — the `@CsTrigger` / `@CsAuthorize` / `@CsJob` rule
that a `kind` permits only certain other arguments — **cannot** be a const
`assert`, because Dart does not const-evaluate an annotation. It therefore
belongs to the generation-time validation pass, and that is why applying a
forbidden combination compiles cleanly and fails later.

## Best Practices

- **Put every realised section id in the class's `@CodeSpec.source`**, including
  ones only a member consumed. The gap analysis never looks inside a class.
- **Prefer the specific marker.** `@CsFieldRule` says more than `@CsValidation`
  about where a rule applies, and the validator can check the more specific one.
- **Do not invent an argument for a note-only marker.** If an attribute seems to
  have nowhere to live, check the substrate class first — that is usually where
  it already is.
- **Give `@CsCollaborator` methods a doc comment stating the behaviour.** An
  absent one is fatal at generation, and it is the only place the step's
  behaviour survives into Phase 6.
- **Let the compiler check cross-part edges.** Never write a reference id as a
  string where a `Cs*Ref` const exists — see
  [cross_references.md](cross_references.md).
- **Reach for a closed catalogue rather than a free string.** A catalogue grows
  by a reviewed taxonomy edit; a string grows by a specification inventing a
  value in passing.

---

Back to the [documentation index](index.md).
