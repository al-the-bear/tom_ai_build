# TomSpecs CodeSpecs API Reference: Cross-Part References Module

The thirteen typed cross-part reference consts. Every cross-part edge inside
CodeSpecs code is one of these or a `Type` literal — never a string literal —
so a renamed or deleted target is a **compile error**.

For task-oriented guidance see [cross_references.md](../cross_references.md).
For the rule itself, see
[`codespecs_mapping.md`](../../../tom_specs_model/doc/codespecs_mapping.md) §5.23.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [CsOperationRef](#csoperationref)
  - [CsCallRef](#cscallref)
  - [CsActionRef](#csactionref)
  - [CsRouteRef](#csrouteref)
  - [CsMessageKey](#csmessagekey)
  - [CsErrorCode](#cserrorcode)
  - [CsRoleRef](#csroleref)
  - [CsResourceKeyRef](#csresourcekeyref)
  - [CsServiceUnitRef](#csserviceunitref)
  - [CsReportRef](#csreportref)
  - [CsJobRef](#csjobref)
  - [CsElementRef](#cselementref)
  - [CsFormRef](#csformref)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **13 const value classes**. They are *not*
annotations — they are annotation *parameter* vocabulary, which is why every
one is `const`-constructible.

Eleven are named `Cs*Ref`. The other two — `CsMessageKey` and `CsErrorCode` —
name a text key and an error code rather than a declaration, so `Cs*Ref` is the
family's shorthand, not a naming rule.

| Locus | Ref types | Citable from |
|-------|-----------|--------------|
| Shared | `CsOperationRef`, `CsMessageKey`, `CsErrorCode`, `CsRoleRef`, `CsResourceKeyRef` | either side |
| Client | `CsCallRef`, `CsActionRef`, `CsRouteRef`, `CsElementRef`, `CsFormRef` | client code only |
| Server | `CsServiceUnitRef`, `CsReportRef`, `CsJobRef` | server code only |

## Class Hierarchy

```
Object
├── CsOperationRef   (Shared)
├── CsCallRef   (Client)
├── CsActionRef   (Client)
├── CsRouteRef   (Client)
├── CsMessageKey   (Shared)
├── CsErrorCode   (Shared)
├── CsRoleRef   (Shared)
├── CsResourceKeyRef   (Shared)
├── CsServiceUnitRef   (Server)
├── CsReportRef   (Server)
├── CsJobRef   (Server)
├── CsElementRef   (Client)
└── CsFormRef   (Client)
```

**There is deliberately no shared supertype.** A parameter typed as a common
base would accept every kind, which is exactly the generic reference the typed
family exists to rule out.

## Classes

#### CsOperationRef

A reference to a **CE-API operation** (shared locus).

**Locus:** Shared

##### Constructors
```dart
const CsOperationRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The operation name, verbatim from the specification. |

#### CsCallRef

A reference to a **CE-SC server call** (client locus).

**Locus:** Client

##### Constructors
```dart
const CsCallRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the `@CsServerCall` (N9). |

#### CsActionRef

A reference to a **CE-AC action** (client locus).

**Locus:** Client

##### Constructors
```dart
const CsActionRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the `@CsAction` (N9). |

#### CsRouteRef

A reference to a **CE-NV route** (client locus).

**Locus:** Client

##### Constructors
```dart
const CsRouteRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The route id, verbatim from the specification. |

#### CsMessageKey

A reference to a **CE-TX message key** (shared locus).

**Locus:** Shared

##### Constructors
```dart
const CsMessageKey(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The message key, verbatim from the specification (e.g. |

#### CsErrorCode

A reference to a **CE-ER error code** (shared locus).

**Locus:** Shared

##### Constructors
```dart
const CsErrorCode(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The error code, verbatim from the specification. |

#### CsRoleRef

A reference to a **CE-AZ role** (shared locus).

**Locus:** Shared

##### Constructors
```dart
const CsRoleRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the role in the CE-AZ role catalogue. |

#### CsResourceKeyRef

A reference to a **CE-AZ resource key** (shared locus).

**Locus:** Shared

##### Constructors
```dart
const CsResourceKeyRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The resource key, verbatim from the specification. |

#### CsServiceUnitRef

A reference to a **CE-SU service unit** (server locus).

**Locus:** Server

##### Constructors
```dart
const CsServiceUnitRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the `@CsServiceUnit` (N9). |

#### CsReportRef

A reference to a **CE-RP report definition** (server locus).

**Locus:** Server

##### Constructors
```dart
const CsReportRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the `@CsReport` (N9). |

#### CsJobRef

A reference to a **CE-JB background job** (server locus).

**Locus:** Server

##### Constructors
```dart
const CsJobRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the `@CsJob` (N9). |

#### CsElementRef

A reference to a **CE-EL screen element** (client locus).

**Locus:** Client

##### Constructors
```dart
const CsElementRef(this.id, {this.form});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the element (N9). |
| `form` | `String?` | The camelCase declaration name of the owning `@CsForm`, when the element is a form member. |
| `path` | `String get` | The N9 const-string form: `<form>.<element>` for a form member, the bare [id] for a standalone element. |

#### CsFormRef

A reference to a **CE-FM form** (client locus).

**Locus:** Client

##### Constructors
```dart
const CsFormRef(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The camelCase declaration name of the `@CsForm` (N9). |

## Global Functions and Constants

The module declares none.
