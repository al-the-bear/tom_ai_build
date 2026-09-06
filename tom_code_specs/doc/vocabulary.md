# TomSpecs CodeSpecs — The Closed Catalogues

Twenty-four of the forty `Cs*` markers take arguments, and most of those
arguments select from a **closed catalogue** — an enum declared in
`vocabulary.dart`. This guide covers the sixteen catalogues, why they are enums
rather than strings, why they are declared here rather than imported, and the
per-kind slot rule that a `const` expression cannot enforce. What each value
*means* for a specification is
[`codespecs_mapping.md`](../../tom_specs_model/doc/codespecs_mapping.md); what
code it produces is
[`codespecs_derivation_contract.md`](../../tom_specs_model/doc/codespecs_derivation_contract.md)
§5.3. This guide states the API and cites those.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The sixteen catalogues](#the-sixteen-catalogues)
  - [Why enums, and why declared here](#why-enums-and-why-declared-here)
- [Per-kind slots and the exclusivity rule](#per-kind-slots-and-the-exclusivity-rule)
- [The three settings-scope catalogues](#the-three-settings-scope-catalogues)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

A catalogue is *closed*: adding a value is an edit to a taxonomy, reviewed as
such, not a free-form attribute a specification can invent in passing. Making
each one an enum moves that discipline out of convention and into the type
system — the same reason cross-part references are typed consts rather than id
strings.

Like `DocRef` and the `Cs*Ref` family, the catalogues are **not annotations**.
They are annotation *parameter* vocabulary, which is why every one of them is
usable in a `const` expression.

Every catalogue carries the `Cs` prefix without exception. The package's public
surface *is* a naming convention, so a member opting out of it would cost a
reader the rule.

## Quick Start

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  const element = CsElement(kind: CsElementKind.dateInput);
  const text = CsText(
    baseCopy: 'Order date',
    role: CsTextRole.generic,
    category: CsTextCategory.uiCopy,
  );

  print(element.kind.name);
  print('${text.baseCopy} [${text.role.name}/${text.category.name}]');
  print(CsElementKind.values.length);
}
```

Output:

```
dateInput
Order date [generic/uiCopy]
11
```

`CsText`'s `role` and `category` both have defaults, so the common case —
ordinary UI copy — needs neither argument.

## Core Components

### The sixteen catalogues

| Catalogue | Values | Selected by | Answers |
|-----------|--------|-------------|---------|
| `CsElementKind` | 11 | `@CsElement(kind:)` | What kind of screen element this is |
| `CsTextRole` | 5 | `@CsText(role:)` | What the copy is *for* |
| `CsTextCategory` | 2 | `@CsText(category:)` | Which catalogue half the key belongs to |
| `CsTriggerKind` | 5 | `@CsTrigger(kind:)` | How an action is invoked |
| `CsGesture` | 3 | `@CsTrigger(gesture:)` | The gesture arm of a `userGesture` trigger |
| `CsFormEvent` | 4 | `@CsTrigger(formEvent:)` | The form-event arm of an `inFormEvent` trigger |
| `CsLifecyclePhase` | 4 | `@CsTrigger(phase:)` | The phase arm of a `lifecycle` trigger |
| `CsLifecycleScope` | 3 | `@CsTrigger(scope:)`, `@CsViewModel(scope:)` | How long a scoped thing lives |
| `CsErrorSeverity` | 4 | `@CsError(severity:)` | How severe an error code is |
| `CsAuthRequirement` | 10 | `@CsAuthorize(requirement:)` | What a caller must satisfy |
| `CsSensitivityLevel` | 6 | `@CsColumn(sensitivityLevel:)` | How sensitive a stored value is |
| `CsMigrationKind` | 3 | `@CsMigration(kind:)` | Which migration artifact kind this is |
| `CsJobTrigger` | 3 | `@CsJob(trigger:)` | What starts a background job |
| `CsClientKind` | 3 | `@CsClient(kind:)` | Which kind of client application this is |
| `CsIdentityAttributePlacement` | 2 | `@CsIdentityAttribute(placement:)` | Where the attribute rides in the token payload |
| `CsOverridableBy` | 4 | `@CsServerConfig`, `@CsClientConfig`, `@CsUserSetting` `(overridableBy:)` | Which narrower scope may shadow a setting |

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  print('CsElementKind:   ${CsElementKind.values.map((v) => v.name).join(', ')}');
  print('CsAuthRequirement: ${CsAuthRequirement.values.length} values');
  print('CsMigrationKind: ${CsMigrationKind.values.map((v) => v.name).join(', ')}');
  print('CsOverridableBy: ${CsOverridableBy.values.map((v) => v.name).join(', ')}');
}
```

Output:

```
CsElementKind:   textInput, number, toggle, dateInput, choice, multiChoice, fileInput, label, button, menuEntry, formHost
CsAuthRequirement: 10 values
CsMigrationKind: initialDdl, baseData, iteration
CsOverridableBy: none, client, user, device
```

### Why enums, and why declared here

`tom_code_specs` is annotations-only and deliberately does **not** depend on
`tom_core`. Every catalogue that has a `tom_core` counterpart is therefore
declared *locally*, mirroring it one-for-one, and a named validator check
asserts each mirror is complete: a `tom_core` catalogue that grows without its
mirror growing is a build failure rather than a silent divergence.

At present no catalogue here has such a counterpart — every one mirrors a
*document section* instead — so the check's pair table is empty and it stands
ready rather than firing. Worth knowing before adding a catalogue: if the new
one does mirror a `tom_core` enum, it acquires that obligation.

## Per-kind slots and the exclusivity rule

Three markers have a **head** argument that selects a kind, followed by
per-kind slots. Dart annotations have no sum types, so each kind's payload is a
separate optional argument:

| Marker | Head | Slots, by head value |
|--------|------|----------------------|
| `@CsTrigger` | `kind` | `userGesture` → `gesture`, `element`; `inFormEvent` → `form`, `formEvent`, `formField`; `lifecycle` → `scope`, `phase`; `serverEvent` → `channel`, `eventType`; `condition` → *(none)* |
| `@CsAuthorize` | `requirement` | `role` → `roles`; `group` → `groups`; `entitlement` → `entitlements`; `resourceKey` → `resourceKey`; `custom` → `handler`, `resourceId`; `graded` → `graded`; `none` · `public` · `authenticated` · `guest` → *(none)* |
| `@CsJob` | `trigger` | `cron` → `cron`; `calendar` → `calendar`; `event` → `event` |

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  const gesture = CsTrigger(
    kind: CsTriggerKind.userGesture,
    action: CsActionRef('submitOrder'),
    gesture: CsGesture.tap,
    element: CsElementRef('submitButton', form: 'orderForm'),
  );

  const lifecycle = CsTrigger(
    kind: CsTriggerKind.lifecycle,
    action: CsActionRef('loadOrders'),
    scope: CsLifecycleScope.screen,
    phase: CsLifecyclePhase.enter,
  );

  print('${gesture.kind.name}: ${gesture.gesture!.name} on '
      '${gesture.element!.path}');
  print('${lifecycle.kind.name}: ${lifecycle.scope!.name}/'
      '${lifecycle.phase!.name}');
  print('lifecycle trigger fills no gesture slot: ${lifecycle.gesture == null}');
}
```

Output:

```
userGesture: tap on orderForm.submitButton
lifecycle: screen/enter
lifecycle trigger fills no gesture slot: true
```

**The exclusivity rule is not enforced by the type system, and cannot be.** A
`const assert` would not help: Dart does not const-evaluate an annotation. So a
`@CsTrigger(kind: CsTriggerKind.lifecycle, gesture: CsGesture.tap)` compiles
cleanly and is rejected later, by the generation-time validator. If a
combination that "should" be impossible slips through the compiler, that is why.

`@CsAuthorize.requirement` is **required and has no default**, deliberately:
defaulting an authorization requirement is exactly the failure the fail-safe
rule exists to prevent.

## The three settings-scope catalogues

`CsOverridableBy` appears on three different markers, and reading it correctly
means knowing which scope the marker itself is in:

| Marker | Owner scope | `overridableBy` says |
|--------|-------------|----------------------|
| `@CsServerConfig` | Server / system | Which narrower scope may shadow this server setting |
| `@CsClientConfig` | (client app, machine) | Which narrower scope may shadow this per-install setting |
| `@CsUserSetting` | (user) | Which narrower scope may shadow this account-wide preference |

```dart
import 'package:tom_code_specs/tom_code_specs.dart';

void main() {
  const serverSetting = CsServerConfig(
    'orders.retentionDays',
    overridableBy: CsOverridableBy.none,
    envAlias: 'ORDERS_RETENTION_DAYS',
  );

  const userSetting = CsUserSetting(
    'user.preferredLanguage',
    overridableBy: CsOverridableBy.device,
  );

  print('${serverSetting.key} <- ${serverSetting.envAlias} '
      '(${serverSetting.overridableBy.name})');
  print('${userSetting.key} (${userSetting.overridableBy.name})');
  print('secret by default: ${serverSetting.secret}');
}
```

Output:

```
orders.retentionDays <- ORDERS_RETENTION_DAYS (none)
user.preferredLanguage (device)
secret by default: false
```

`@CsDeviceSetting` is the one settings marker with **no** `overridableBy`: the
device scope is already the narrowest, so there is nothing below it to shadow.

## Error Handling

No enum here throws — a Dart enum cannot. Every diagnostic involving a catalogue
comes from one of two places:

| Mistake | Caught by | When |
|---------|-----------|------|
| A value that is not a member of the catalogue | The **Dart compiler** | Compile time |
| A per-kind slot filled that the head value does not permit | `validate_codespecs.dart` | Generation time |
| A required head argument omitted (`@CsAuthorize.requirement`) | The **Dart compiler** | Compile time |
| A `tom_core` catalogue grown without its local mirror | The validator's mirror check | Generation time |

The split is the practical consequence of Dart annotations having no sum types:
*which* values exist is a compile-time question, *which combinations* are legal
is not.

## Best Practices

- **Never work around a closed catalogue with a free string.** If a value is
  genuinely missing, the answer is a reviewed taxonomy edit — that is what
  "closed" buys.
- **Fill exactly the slots the head value permits.** The compiler will not stop
  you, and a stray slot is rejected at generation with less context.
- **State `@CsAuthorize.requirement` explicitly.** It has no default on purpose.
- **Leave `role` and `category` off `@CsText` for ordinary UI copy.** The
  defaults are the common case; stating them adds noise, not information.
- **Check the owner scope before reading `overridableBy`.** The same enum means
  three different things on three markers.
- **Prefix any new catalogue with `Cs`.** The convention is the package's public
  surface; an exception costs every reader the rule.

---

Back to the [documentation index](index.md).
