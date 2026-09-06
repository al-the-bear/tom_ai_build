# TomSpecs CodeSpecs API Reference: Vocabulary Module

The sixteen closed catalogues the `Cs*` marker arguments select from. A
catalogue is *closed*: adding a value is a reviewed taxonomy edit, not a
free-form attribute a specification can invent in passing.

These are **not annotations** — they are annotation *parameter* vocabulary, the
same role `DocRef` and the `Cs*Ref` family play.

For task-oriented guidance see [vocabulary.md](../vocabulary.md). For what each
value means for a specification, see
[`codespecs_mapping.md`](../../../tom_specs_model/doc/codespecs_mapping.md).

## Table of Contents

- [Overview](#overview)
- [Enums](#enums)
  - [CsErrorSeverity](#cserrorseverity)
  - [CsTextRole](#cstextrole)
  - [CsTextCategory](#cstextcategory)
  - [CsElementKind](#cselementkind)
  - [CsSensitivityLevel](#cssensitivitylevel)
  - [CsGesture](#csgesture)
  - [CsFormEvent](#csformevent)
  - [CsLifecycleScope](#cslifecyclescope)
  - [CsLifecyclePhase](#cslifecyclephase)
  - [CsAuthRequirement](#csauthrequirement)
  - [CsClientKind](#csclientkind)
  - [CsMigrationKind](#csmigrationkind)
  - [CsJobTrigger](#csjobtrigger)
  - [CsTriggerKind](#cstriggerkind)
  - [CsIdentityAttributePlacement](#csidentityattributeplacement)
  - [CsOverridableBy](#csoverridableby)
- [Classes](#classes)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **16 enums** and no classes. Every catalogue
carries the `Cs` prefix without exception.

| Catalogue | Values | Selected by |
|-----------|--------|-------------|
| `CsErrorSeverity` | 4 | `@CsError(severity:)` |
| `CsTextRole` | 5 | `@CsText(role:)` |
| `CsTextCategory` | 2 | `@CsText(category:)` |
| `CsElementKind` | 11 | `@CsElement(kind:)` |
| `CsSensitivityLevel` | 6 | `@CsColumn(sensitivityLevel:)` |
| `CsGesture` | 3 | `@CsTrigger(gesture:)` |
| `CsFormEvent` | 4 | `@CsTrigger(formEvent:)` |
| `CsLifecycleScope` | 3 | `@CsTrigger(scope:)`, `@CsViewModel(scope:)` |
| `CsLifecyclePhase` | 4 | `@CsTrigger(phase:)` |
| `CsAuthRequirement` | 10 | `@CsAuthorize(requirement:)` |
| `CsClientKind` | 3 | `@CsClient(kind:)` |
| `CsMigrationKind` | 3 | `@CsMigration(kind:)` |
| `CsJobTrigger` | 3 | `@CsJob(trigger:)` |
| `CsTriggerKind` | 5 | `@CsTrigger(kind:)` |
| `CsIdentityAttributePlacement` | 2 | `@CsIdentityAttribute(placement:)` |
| `CsOverridableBy` | 4 | `@CsServerConfig`, `@CsClientConfig`, `@CsUserSetting` `(overridableBy:)` |

**Declared here, not imported.** `tom_code_specs` deliberately does not depend
on `tom_core`, so a catalogue with a `tom_core` counterpart is a local mirror,
and a validator check asserts the mirror is complete. No catalogue currently
has such a counterpart, so that check stands ready rather than firing.

## Enums

### CsErrorSeverity

How severe a CE-ER error code is (`codespecs_derivation_contract.md` §3.1.2).

**Selected by:** `@CsError(severity:)`

| Value | Meaning |
|-------|---------|
| `info` | Informational — the operation succeeded and is reporting something. |
| `warning` | The operation succeeded but the result is degraded or suspect. |
| `error` | The operation failed and the caller can act on it. |
| `fatal` | The operation failed unrecoverably. |

### CsTextRole

What a CE-TX message key is copy *for* (`codespecs_mapping.md` §5.21).

**Selected by:** `@CsText(role:)`

| Value | Meaning |
|-------|---------|
| `error` | Copy shown when an error code or a validation rule fails. |
| `notification` | Copy carried by a CE-NT notification. |
| `email` | Copy carried by an outbound email. |
| `report` | A CE-RP report label. |
| `generic` | Ordinary interface copy with no specialised role. |

### CsTextCategory

Which catalogue half a CE-TX message key belongs to (`codespecs_mapping.md` §5.21).

**Selected by:** `@CsText(category:)`

| Value | Meaning |
|-------|---------|
| `uiCopy` | Interface copy, keyed by its own dotted message key. |
| `errorCopy` | Error copy, keyed by the CE-ER error code it explains. |

### CsElementKind

The closed CE-EL semantic element catalogue (`codespecs_mapping.md` §5.18).

**Selected by:** `@CsElement(kind:)`

| Value | Meaning |
|-------|---------|
| `textInput` | A free-text value. |
| `number` | A numeric value. |
| `toggle` | A boolean value. |
| `dateInput` | A date or date-time value. |
| `choice` | One value chosen from a closed set. |
| `multiChoice` | Several values chosen from a closed set. |
| `fileInput` | A reference to a file — what a user puts a file into, and what shows the file that is already there. |
| `label` | Static copy with no value of its own. |
| `button` | An action affordance. |
| `menuEntry` | An action affordance inside a menu. |
| `formHost` | A container element hosting a form. |

### CsSensitivityLevel

How sensitive a CE-DB column's stored value is (`codespecs_mapping.md` §5.13).

**Selected by:** `@CsColumn(sensitivityLevel:)`

| Value | Meaning |
|-------|---------|
| `public` | Freely disclosable. |
| `internal` | Internal to the operating organisation. |
| `confidential` | Restricted to a need-to-know audience. |
| `restricted` | The narrowest non-personal classification. |
| `pii` | Personally identifiable information. |
| `phi` | Protected health information. |

### CsGesture

The gesture arm of a `userGesture` trigger (`codespecs_mapping.md` §5.20).

**Selected by:** `@CsTrigger(gesture:)`

| Value | Meaning |
|-------|---------|
| `tap` | A short activation. |
| `press` | A press-and-hold that fires on press. |
| `longPress` | A press-and-hold that fires after the long-press threshold. |

### CsFormEvent

The form-event arm of an `inFormEvent` trigger (`codespecs_mapping.md` §5.20).

**Selected by:** `@CsTrigger(formEvent:)`

| Value | Meaning |
|-------|---------|
| `fieldChange` | A named field's value changed. |
| `submit` | The form was submitted. |
| `validationPass` | Form validation completed with no errors. |
| `validationFail` | Form validation completed with at least one error. |

### CsLifecycleScope

How long a scoped thing lives (`codespecs_mapping.md` §5.4, §5.20).

**Selected by:** `@CsTrigger(scope:)`, `@CsViewModel(scope:)`

| Value | Meaning |
|-------|---------|
| `screen` | Lives as long as the screen that owns it. |
| `route` | Lives as long as the route, across the screens it contains. |
| `app` | Lives as long as the application session. |

### CsLifecyclePhase

The phase arm of a `lifecycle` trigger (`codespecs_mapping.md` §5.20).

**Selected by:** `@CsTrigger(phase:)`

| Value | Meaning |
|-------|---------|
| `enter` | The scope became visible. |
| `leave` | The scope stopped being visible. |
| `init` | The scope was created. |
| `dispose` | The scope was destroyed. |

### CsAuthRequirement

What a CE-AZ authorization requirement demands (`codespecs_mapping.md` §5.15).

**Selected by:** `@CsAuthorize(requirement:)`

| Value | Meaning |
|-------|---------|
| `role` | The principal must hold one of a named set of roles. |
| `group` | The principal must belong to one of a named set of groups. |
| `entitlement` | The principal's entitlements must match one of a set of patterns. |
| `resourceKey` | The principal must hold a grant on a named resource key. |
| `custom` | A registered handler decides, against a named resource id. |
| `graded` | A graded requirement tree resolving to one of the four access states. |
| `none` | Deny unconditionally. |
| `public` | Allow unconditionally, signed in or not. |
| `authenticated` | Allow any signed-in principal. |
| `guest` | Allow the guest principal. |

### CsClientKind

Which kind of client application a CE-CL descriptor declares (`codespecs_mapping.md` §4.1).

**Selected by:** `@CsClient(kind:)`

| Value | Meaning |
|-------|---------|
| `flutterApp` | A Flutter application. |
| `cli` | A command-line application. |
| `server` | Another server calling this one as a client. |

### CsMigrationKind

The three CE-MG artifact kinds (`codespecs_mapping.md` §5.27).

**Selected by:** `@CsMigration(kind:)`

| Value | Meaning |
|-------|---------|
| `initialDdl` | The schema-creating DDL for a new deployment. |
| `baseData` | The new system's base / seed reference data. |
| `iteration` | An append-only change applied on top of an existing schema. |

### CsJobTrigger

What starts a CE-JB background job (`codespecs_mapping.md` §5.29).

**Selected by:** `@CsJob(trigger:)`

| Value | Meaning |
|-------|---------|
| `cron` | A cron expression. |
| `calendar` | A calendar date/time rule. |
| `event` | A named system event. |

### CsTriggerKind

How a CE-AC action is invoked (`codespecs_mapping.md` §5.20).

**Selected by:** `@CsTrigger(kind:)`

| Value | Meaning |
|-------|---------|
| `userGesture` | Fired by a user acting on a CE-EL element (tap / press / long-press). |
| `inFormEvent` | Fired by a CE-FM form event (field change, submit, validation pass/fail). |
| `lifecycle` | Fired by a screen, route or app lifecycle phase. |
| `serverEvent` | Fired by an inbound server push or notification. |
| `condition` | Fired by a reactive predicate over CE-ST observable state — the `canExecute` case. |

### CsIdentityAttributePlacement

Where a CE-ID identity attribute rides in the token payload (`codespecs_mapping.md` §5.24).

**Selected by:** `@CsIdentityAttribute(placement:)`

| Value | Meaning |
|-------|---------|
| `public` | Rides the **public** token payload, in `TomUser.attributes`. |
| `encrypted` | Rides the **encrypted** context of the authorization JWT, in `TomPrincipal.currentContext`. |

### CsOverridableBy

Which narrower configuration scope may shadow a setting (`codespecs_mapping.md` §5.16, §11).

**Selected by:** `@CsServerConfig`, `@CsClientConfig`, `@CsUserSetting` `(overridableBy:)`

| Value | Meaning |
|-------|---------|
| `none` | Scope-pinned: no narrower scope may shadow this key. |
| `client` | A per-install client configuration value may shadow this key — CE-CF only, the sole scope wider than CE-CC. |
| `user` | A per-user setting may shadow this key; so, transitively, may a device setting. |
| `device` | A per-user-per-device setting may shadow this key. |

## Classes

The module declares none. The two facet value classes a marker argument can
take — `CsFileReference` and `CsGradedAccess` — live in
`service_annotations.dart` and are documented in
[api_summary_annotations.md](api_summary_annotations.md).

## Global Functions and Constants

The module declares none.
