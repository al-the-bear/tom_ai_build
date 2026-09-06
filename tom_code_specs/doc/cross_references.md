# TomSpecs CodeSpecs — Cross-References and Back-Links

A CodeSpecs project is a graph: a call site cites an operation, a trigger cites
an element, a job cites a report. This guide covers how those edges are written
— the thirteen typed `Cs*Ref` const types — and how a piece of code traces back
to the specification section that shaped it, through `@DocSpec` and `DocRef`.
The rule that a cross-part edge must be a const rather than a string is
[`codespecs_mapping.md`](../../tom_specs_model/doc/codespecs_mapping.md) §5.23;
the naming rules the ids follow are
[`codespecs_derivation_contract.md`](../../tom_specs_model/doc/codespecs_derivation_contract.md)
§2.1. Both are cited here rather than restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The thirteen ref types](#the-thirteen-ref-types)
  - [Declaring an identity once](#declaring-an-identity-once)
- [The qualifiable ref](#the-qualifiable-ref)
- [What is deliberately not a ref](#what-is-deliberately-not-a-ref)
- [Back-links: @DocSpec and DocRef](#back-links-docspec-and-docref)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

Every cross-part reference inside CodeSpecs code is a **Dart const or a `Type`
literal — never a string literal**. The part that owns a referenceable element
declares its identity exactly once, as a `static const` on that part's catalogue
class; every citing site holds *that const*, not a copy of its string.

The consequence is the point: a dangling or renamed reference becomes a
**compile error**, so the Dart compiler is the cross-part integrity checker. No
separate id-resolution pass is needed for the edges the type system can hold.

The string id still exists — authored once, *inside* the const. It is what
serialization and specification tracing carry, and what the lowered runtime
forms hold. Specification-level code never repeats it.

## Quick Start

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

/// The owning part's catalogue class: each identity declared exactly once.
abstract final class Operations {
  static const login = CsOperationRef('login');
  static const saveCustomer = CsOperationRef('customer.save');
}

/// A citing site holds the const, never a copy of its string.
class LoginCall {
  static const operation = Operations.login;
}

void main() {
  print(LoginCall.operation.id);
  print(Operations.saveCustomer.id);
  print(identical(LoginCall.operation, Operations.login));
}
```

Output:

```
login
customer.save
true
```

Rename `Operations.login` and every citing site fails to compile. Change only
the string inside it and nothing breaks, because the string is authored in one
place.

## Core Components

### The thirteen ref types

Each names one resolvable identity. They are **distinct types with no shared
supertype**, so passing a route ref where an operation ref is expected is itself
a compile error — a common base would accept every kind, which is precisely what
the typed family exists to prevent.

| Locus | Ref types | Cited from |
|-------|-----------|------------|
| Shared | `CsOperationRef`, `CsMessageKey`, `CsErrorCode`, `CsRoleRef`, `CsResourceKeyRef` | Either side |
| Client | `CsCallRef`, `CsActionRef`, `CsRouteRef`, `CsElementRef`, `CsFormRef` | Client only |
| Server | `CsServiceUnitRef`, `CsReportRef`, `CsJobRef` | Server only |

Eleven are named `Cs*Ref`. The other two — `CsMessageKey` and `CsErrorCode` —
name a **text key** and an **error code** rather than a declaration, which is
why `Cs*Ref` is the family's shorthand and not a naming rule.

The locus column is the dependency arrow, not a convention: a client-owned
referent cannot be cited from server code because the server project does not
depend on the client project.

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  const shared = [
    CsOperationRef('customer.save'),
    CsMessageKey('customer.form.title'),
    CsErrorCode('CUSTOMER_NOT_FOUND'),
    CsRoleRef('salesManager'),
    CsResourceKeyRef('customer'),
  ];

  for (final ref in shared) {
    print('${ref.runtimeType}: ${(ref as dynamic).id}');
  }
}
```

Output:

```
CsOperationRef: customer.save
CsMessageKey: customer.form.title
CsErrorCode: CUSTOMER_NOT_FOUND
CsRoleRef: salesManager
CsResourceKeyRef: customer
```

The `as dynamic` in that loop is the price of having no shared supertype, and it
is worth paying: real code cites one kind at a time, statically typed, and never
needs the loop.

### Declaring an identity once

The id string inside a ref follows one of two rules:

- **The camelCase declaration name of the target** — the default.
- **The authored key, verbatim** — where the target is identified by a key the
  specification wrote: message keys, error codes, operation names, route ids.

The distinction matters when reading a ref: `CsOperationRef('customer.save')`
holds an authored key that must match the specification character for
character, while `CsRoleRef('salesManager')` holds a name derived from a
declaration.

## The qualifiable ref

`CsElementRef` is the one ref that takes a qualifier. A UI element may be
standalone — a class-level target needing no qualifier — or a member of a form,
in which case the owning form disambiguates it. Its `path` getter joins them:

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  const standalone = CsElementRef('searchBox');
  const formMember = CsElementRef('email', form: 'customerForm');

  print('${standalone.id} -> ${standalone.path}');
  print('${formMember.id} in ${formMember.form} -> ${formMember.path}');
  print(standalone.form == null);
}
```

Output:

```
searchBox -> searchBox
email in customerForm -> customerForm.email
true
```

`CsFormRef` needs no qualifier because a form is always a class-level target.

## What is deliberately not a ref

Three absences are decisions, not gaps.

**Entities and DTOs** have no ref type because they are already Dart types —
cited by `Type` literal (`rootAggregate: Customer`), which the compiler checks
directly.

**Four reference kinds stay strings**, because their referent is not a Dart
declaration, so integrity comes from the generation-time validator rather than
the compiler: setting keys and their env/cmdline aliases, deployment-environment
names, migration artifact filenames, and doc-side `codeSpec` locations and
`@DocSpec` section ids.

**Intra-part edges are out of scope.** The family is *cross*-part. An edge whose
target lies inside the same part declaration is a **local coordinate**, not a
reference; typing it would widen the family from "how parts cite each other" to
"how any id is written". Two such coordinates exist, both id strings guarded by
a validator check: a layout delta's node id, and a notification channel's
fallback, which names a *sibling* channel. That is why there is no
`CsChannelRef` — an absence by design.

## Back-links: `@DocSpec` and `DocRef`

Where the ref family answers *"what else does this code point at?"*, `@DocSpec`
answers *"which specification sections shaped this code, and how?"*. It holds a
list of `DocRef` tuples, each naming a section by its SOM `@SectionId` and
saying what the code takes from it.

`@DocSpec` and `@CodeSpec` are placed differently, and the asymmetry is the
whole design: `@CodeSpec` sits on the top-level declaration and accounts for the
whole emission unit; `@DocSpec` sits on **every** declaration that consumed a
section, member or not.

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

@CsTable('orders')
@CodeSpec('DB-ORDER', source: ['IMO-014', 'RSP-042'])
@DocSpec([DocRef('IMO-014', 'Order entity fields and constraints')])
class Order {
  @CsColumn(column: 'total_amount')
  @DocSpec([DocRef('RSP-042', 'total must be non-negative')])
  double total = 0;
}

void main() {
  const classTrace = DocSpec([
    DocRef('IMO-014', 'Order entity fields and constraints'),
  ]);
  const memberTrace = DocSpec([
    DocRef('RSP-042', 'total must be non-negative'),
  ]);

  for (final ref in [...classTrace.refs, ...memberTrace.refs]) {
    print('${ref.sectionId}: ${ref.description}');
  }
  print(Order().total);
}
```

Output:

```
IMO-014: Order entity fields and constraints
RSP-042: total must be non-negative
0.0
```

Note that `RSP-042` appears in *both* the member's `@DocSpec` and the class's
`@CodeSpec.source`. That is required, not redundant: the member records *how*
the section shaped it, and the class records *that* the unit realised it.

`@DocSpec` lives in this package rather than in `tom_specs_core` because it
annotates CodeSpecs **code**. Its forward counterparts — the type-level
`@CodeSpecKind` and the instance-level `codeSpec` member — annotate the model and
live there. The shared join key is the SOM `@SectionId`.

## Error Handling

| Mistake | Caught by | When |
|---------|-----------|------|
| A ref to a renamed or deleted declaration | The **Dart compiler** | Compile time |
| A route ref passed where an operation ref is expected | The **Dart compiler** | Compile time |
| A ref string that resolves to no declaration | `validate_codespecs.dart` | Generation time |
| A `@DocSpec` section id that no SOM section carries | The same validator | Generation time |
| A section realised by a member but absent from the class's `@CodeSpec.source` | The gap analysis | Generation time |
| A notification channel fallback naming a non-sibling channel | The validator | Generation time |

The ref types themselves throw nothing. `CsElementRef.path` is a pure getter
over two fields and cannot fail.

## Best Practices

- **Declare each identity exactly once**, as a `static const` on the owning
  part's catalogue class. Every other site holds that const.
- **Never write a reference id as a string** where a `Cs*Ref` exists. The string
  form defeats the compile-time check the family exists to provide.
- **Copy an authored key character for character.** Operation names, message
  keys, error codes and route ids come from the specification; re-deriving one
  breaks the join silently.
- **Use `CsElementRef.form` for a form member**, not a pre-joined
  `'customerForm.email'` id. The `path` getter builds the dotted form; writing
  it by hand puts the convention in two places.
- **Put a real sentence in every `DocRef.description`.** "Order fields" is a
  restatement of the section id; "total must be non-negative" is what the reader
  cannot recover from the code.
- **Trace at the level that consumed the section.** A member that realised a
  section carries its own `@DocSpec`; the class's `@CodeSpec.source` still lists
  it.

---

Back to the [documentation index](index.md).
