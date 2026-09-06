# TomSpecs CodeSpecs API Reference: Annotations Module

The `Cs*` marker family, the identity and trace annotations, and the two
facet value classes. Everything here is a `const` class with no run-time
behaviour: the readers are the Phase-4 authoring agent, the generation-time
validator in `tom_specs_clitool`, and the Dart compiler.

For task-oriented guidance see [marking_code.md](../marking_code.md). For the
code each marker produces, see
[`codespecs_derivation_contract.md`](../../../tom_specs_model/doc/codespecs_derivation_contract.md).

The cross-part reference types are documented separately in
[api_summary_cross_part_refs.md](api_summary_cross_part_refs.md); the closed
catalogues in [api_summary_vocabulary.md](api_summary_vocabulary.md).

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [Client / UI markers](#client--ui-markers)
    - [CsElement](#cselement)
    - [CsWidget](#cswidget)
    - [CsForm](#csform)
    - [CsLayout](#cslayout)
    - [CsText](#cstext)
    - [CsValidation](#csvalidation)
    - [CsFieldRule](#csfieldrule)
    - [CsFormRule](#csformrule)
    - [CsAction](#csaction)
    - [CsTrigger](#cstrigger)
    - [CsServerCall](#csservercall)
    - [CsViewModel](#csviewmodel)
    - [CsRoute](#csroute)
    - [CsScreenFlow](#csscreenflow)
  - [Server markers](#server-markers)
    - [CsEndpoint](#csendpoint)
    - [CsServiceUnit](#csserviceunit)
    - [CsTable](#cstable)
    - [CsFileReference](#csfilereference)
    - [CsColumn](#cscolumn)
    - [CsRepository](#csrepository)
    - [CsGradedAccess](#csgradedaccess)
    - [CsAuthorize](#csauthorize)
    - [CsServerConfig](#csserverconfig)
    - [CsMigration](#csmigration)
    - [CsJob](#csjob)
    - [CsAudited](#csaudited)
    - [CsNotification](#csnotification)
    - [CsNotificationChannel](#csnotificationchannel)
    - [CsReport](#csreport)
    - [CsReportColumn](#csreportcolumn)
    - [CsReportChart](#csreportchart)
    - [CsReportParameter](#csreportparameter)
  - [Shared-contract markers](#shared-contract-markers)
    - [CsError](#cserror)
    - [CsEnum](#csenum)
  - [Client, settings, identity and auth markers](#client-settings-identity-and-auth-markers)
    - [CsClient](#csclient)
    - [CsClientConfig](#csclientconfig)
    - [CsDeviceSetting](#csdevicesetting)
    - [CsUserSetting](#csusersetting)
    - [CsIdentity](#csidentity)
    - [CsIdentityAttribute](#csidentityattribute)
    - [CsAuth](#csauth)
  - [The collaborator marker](#the-collaborator-marker)
    - [CsCollaborator](#cscollaborator)
  - [Identity and forward trace](#identity-and-forward-trace)
    - [CodeSpec](#codespec)
  - [Back-trace](#back-trace)
    - [DocSpec](#docspec)
    - [DocRef](#docref)

## Overview

The module declares **45 classes** across seven source files:
**40 `Cs*` markers** (39 parts plus `@CsCollaborator`), the
**2 facet value classes**, and the **3 identity /
trace declarations.

| Source file | Holds |
|-------------|-------|
| `element_annotations.dart` | Client / UI markers — 14 classes |
| `service_annotations.dart` | Server markers — 18 classes |
| `contract_annotations.dart` | Shared-contract markers — 2 classes |
| `client_settings_annotations.dart` | Client, settings, identity and auth markers — 7 classes |
| `cs_collaborator.dart` | The collaborator marker — 1 classes |
| `code_spec.dart` | Identity and forward trace — 1 classes |
| `doc_spec.dart` | Back-trace — 2 classes |

Of the forty markers, **sixteen carry a single optional `note`** and
**twenty-four take arguments** — see
[marking_code.md](../marking_code.md#note-only-versus-argument-carrying).

## Class Hierarchy

```
Object
├── Client / UI markers
│   ├── CsElement
│   ├── CsWidget
│   ├── CsForm
│   ├── CsLayout
│   ├── CsText
│   ├── CsValidation
│   ├── CsFieldRule
│   ├── CsFormRule
│   ├── CsAction
│   ├── CsTrigger
│   ├── CsServerCall
│   ├── CsViewModel
│   ├── CsRoute
│   └── CsScreenFlow
├── Server markers
│   ├── CsEndpoint
│   ├── CsServiceUnit
│   ├── CsTable
│   ├── CsFileReference  (facet value class, not a marker)
│   ├── CsColumn
│   ├── CsRepository
│   ├── CsGradedAccess  (facet value class, not a marker)
│   ├── CsAuthorize
│   ├── CsServerConfig
│   ├── CsMigration
│   ├── CsJob
│   ├── CsAudited
│   ├── CsNotification
│   ├── CsNotificationChannel
│   ├── CsReport
│   ├── CsReportColumn
│   ├── CsReportChart
│   └── CsReportParameter
├── Shared-contract markers
│   ├── CsError
│   └── CsEnum
├── Client, settings, identity and auth markers
│   ├── CsClient
│   ├── CsClientConfig
│   ├── CsDeviceSetting
│   ├── CsUserSetting
│   ├── CsIdentity
│   ├── CsIdentityAttribute
│   └── CsAuth
├── The collaborator marker
│   └── CsCollaborator
├── Identity and forward trace
│   └── CodeSpec  (identity / trace, not a part marker)
└── Back-trace
    ├── DocSpec  (identity / trace, not a part marker)
    └── DocRef  (identity / trace, not a part marker)
```

No class here extends another. A marker inheriting from a marker would let a
reader match the wrong one by subtype.

## Classes

### Client / UI markers

#### CsElement

CE-EL — a UI element by semantic type (the generic element part, `codespecs_mapping.md` §5.18).

##### Constructors
```dart
const CsElement({required this.kind, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `kind` | `CsElementKind` | The element's semantic type, from the closed ten-kind catalogue. |
| `note` | `String?` | Optional part-specific note. |

#### CsWidget

CE-EL — the concrete `tom_flutter_ui` widget realising a [CsElement]'s semantic type (`codespecs_mapping.md` §5.7.1, §5.18).

##### Constructors
```dart
const CsWidget({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsForm

CE-FM — a form: the grouping of elements into forms and subforms.

##### Constructors
```dart
const CsForm({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsLayout

CE-LO — a screen layout (structural arrangement of elements, `codespecs_mapping.md` §5.2, §5.12).

##### Constructors
```dart
const CsLayout(this.nodeId, {this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `nodeId` | `String` | The layout node's id. |
| `note` | `String?` | Optional part-specific note. |

#### CsText

CE-TX — a text element (labels, copy, messages).

##### Constructors
```dart
const CsText({
  required this.baseCopy,
  this.role = CsTextRole.generic,
  this.category = CsTextCategory.uiCopy,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `baseCopy` | `String` | The base-language copy, verbatim from the specification. |
| `role` | `CsTextRole` | What this copy is *for*, which selects its resolution path. |
| `category` | `CsTextCategory` | Which catalogue half the key belongs to. |
| `note` | `String?` | Optional part-specific note. |

#### CsValidation

CE-VA — a client-side validation rule.

##### Constructors
```dart
const CsValidation({this.rules = '', this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `rules` | `String` | The standard rules constraining the field this marker rides, in the `codespecs_mapping.md` §5.19 declaration grammar. |
| `note` | `String?` | Optional part-specific note. |

#### CsFieldRule

CE-VA — a **single-field** validation rule (`codespecs_mapping.md` §5.19).

##### Constructors
```dart
const CsFieldRule({required this.errorKey, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `errorKey` | `CsMessageKey` | The message key of the copy shown when the rule fails. |
| `note` | `String?` | Optional part-specific note. |

#### CsFormRule

CE-VA — a **cross-field** validation rule (`codespecs_mapping.md` §5.19).

##### Constructors
```dart
const CsFormRule({required this.errorKey, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `errorKey` | `CsMessageKey` | The message key of the cross-field failure copy. |
| `note` | `String?` | Optional part-specific note. |

#### CsAction

CE-AC — a user action (a command the user can invoke).

##### Constructors
```dart
const CsAction({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsTrigger

CE-AC — a trigger: the event that fires a [CsAction] (`codespecs_mapping.md` §5.10, §5.20).

##### Constructors
```dart
const CsTrigger({
  required this.kind,
  required this.action,
  this.element,
  this.gesture,
  this.form,
  this.formEvent,
  this.formField,
  this.scope,
  this.phase,
  this.channel,
  this.eventType,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `kind` | `CsTriggerKind` | Which of the five closed invocation paths fires the action. |
| `action` | `CsActionRef` | The action this trigger fires. |
| `element` | `CsElementRef?` | `userGesture`: the element the gesture acts on. |
| `gesture` | `CsGesture?` | `userGesture`: which gesture. |
| `form` | `CsFormRef?` | `inFormEvent`: the form the event comes from. |
| `formEvent` | `CsFormEvent?` | `inFormEvent`: which form event. |
| `formField` | `CsElementRef?` | `inFormEvent`: for a `fieldChange` event, which field changed. |
| `scope` | `CsLifecycleScope?` | `lifecycle`: whose lifecycle — screen, route or app. |
| `phase` | `CsLifecyclePhase?` | `lifecycle`: which phase of that scope. |
| `channel` | `String?` | `serverEvent`: the push channel the event arrives on. |
| `eventType` | `String?` | `serverEvent`: the event type within that channel. |
| `note` | `String?` | Optional part-specific note. |

#### CsServerCall

CE-SC — a server call made from the client.

##### Constructors
```dart
const CsServerCall(this.operation, {this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `operation` | `CsOperationRef` | The shared CE-API operation this call invokes. |
| `note` | `String?` | Optional part-specific note. |

#### CsViewModel

CE-ST — a view model: client-side presentation state.

##### Constructors
```dart
const CsViewModel({this.scope = CsLifecycleScope.screen, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `scope` | `CsLifecycleScope` | How long the view state lives. |
| `note` | `String?` | Optional part-specific note. |

#### CsRoute

CE-NV — a route: one navigable screen, identified by a stable route id (`codespecs_mapping.md` §5.11).

##### Constructors
```dart
const CsRoute({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsScreenFlow

CE-NV — the screen-flow model: how screens are reached from one another (`codespecs_mapping.md` §5.11).

##### Constructors
```dart
const CsScreenFlow({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

### Server markers

#### CsEndpoint

CE-API — a server endpoint: an operation name plus its request/response and error contract (`codespecs_mapping.md` §5.6.1).

##### Constructors
```dart
const CsEndpoint(this.operation, {this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `operation` | `String` | The operation name, verbatim from the specification. |
| `note` | `String?` | Optional part-specific note. |

#### CsServiceUnit

CE-SU — a service unit (a cohesive server-side service).

##### Constructors
```dart
const CsServiceUnit({
  required this.rootAggregate,
  required this.boundedContext,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `rootAggregate` | `Type` | The aggregate root the unit owns. |
| `boundedContext` | `String` | The outer bound the unit sits inside, verbatim. |
| `note` | `String?` | Optional part-specific note. |

#### CsTable

CE-DB — a persistent table (a stored entity type, `codespecs_mapping.md` §5.13).

##### Constructors
```dart
const CsTable(this.table, {this.datasource, this.schema, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `table` | `String` | The physical table name, verbatim. |
| `datasource` | `String?` | The configured datasource the table lives in. |
| `schema` | `String?` | The schema within [datasource]. |
| `note` | `String?` | Optional part-specific note. |

#### CsFileReference

CE-DB — a **file-reference** column facet (`codespecs_mapping.md` §5.13).

**Not a marker** — a facet value class passed as a marker argument.

##### Constructors
```dart
const CsFileReference({
  required this.keyPrefix,
  this.store,
  this.cascadeDelete = true,
  this.defaultMediaType,
  this.acceptedMediaTypes = const [],
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `keyPrefix` | `String` | The retention partition the generated key is filed under. |
| `store` | `String?` | Name of the configured blob store holding the file. |
| `cascadeDelete` | `bool` | Whether deleting the row also deletes the stored file. |
| `defaultMediaType` | `String?` | Media type recorded when the upload supplies none. |
| `acceptedMediaTypes` | `List<String>` | The content kinds a specification permits for this column. |
| `note` | `String?` | Optional facet-specific note. |

#### CsColumn

CE-DB — a table column: a stored field of a [CsTable] (`codespecs_mapping.md` §5.13).

##### Constructors
```dart
const CsColumn({
  this.column,
  this.columnType,
  this.length,
  this.accessKey,
  this.fileReference,
  this.sensitivityLevel,
  this.isPii,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `column` | `String?` | The physical column name, verbatim. |
| `columnType` | `String?` | The physical column type, verbatim. |
| `length` | `int?` | The maximum stored length. |
| `accessKey` | `CsResourceKeyRef?` | The resource key gating field-level access to this column. |
| `fileReference` | `CsFileReference?` | Present when the column stores a file reference rather than a value. |
| `sensitivityLevel` | `CsSensitivityLevel?` | The sensitivity classification of the stored value (`codespecs_mapping.md` §5.13). |
| `isPii` | `bool?` | Whether the stored value is personal data (PII). |
| `note` | `String?` | Optional part-specific note. |

#### CsRepository

CE-DB — a repository: the data-access surface over one or more [CsTable]s.

##### Constructors
```dart
const CsRepository({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsGradedAccess

CE-AZ — the **graded** requirement facet: a three-slot requirement tree (`codespecs_mapping.md` §5.15).

**Not a marker** — a facet value class passed as a marker argument.

##### Constructors
```dart
const CsGradedAccess({this.full, this.read, this.disabled});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `full` | `CsAuthorize?` | What a principal must satisfy for interactive access. |
| `read` | `CsAuthorize?` | What a principal must satisfy to see the value without changing it. |
| `disabled` | `CsAuthorize?` | What a principal must satisfy to see the element locked. |

#### CsAuthorize

CE-AZ — an authorization rule: a **modifier** applied to the [CsEndpoint] it gates (`codespecs_mapping.md` §5.6.3, §5.15).

##### Constructors
```dart
const CsAuthorize({
  required this.requirement,
  this.roles = const [],
  this.groups = const [],
  this.entitlements = const [],
  this.resourceKey,
  this.handler,
  this.resourceId,
  this.graded,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `requirement` | `CsAuthRequirement` | What a caller must satisfy. |
| `roles` | `List<CsRoleRef>` | `role`: any one of these roles admits the caller. |
| `groups` | `List<String>` | `group`: any one of these group names admits the caller. |
| `entitlements` | `List<String>` | `entitlement`: entitlement match patterns. |
| `resourceKey` | `CsResourceKeyRef?` | `resourceKey`: the key the caller must hold a grant on. |
| `handler` | `String?` | `custom`: the registered handler that decides. |
| `resourceId` | `String?` | `custom`: the resource the [handler] decides about. |
| `graded` | `CsGradedAccess?` | `graded`: the three-slot requirement tree. |
| `note` | `String?` | Optional part-specific note. |

#### CsServerConfig

CE-CF — server configuration (per-server settings).

##### Constructors
```dart
const CsServerConfig(
  this.key, {
  required this.overridableBy,
  this.envAlias,
  this.cmdlineAlias,
  this.secret = false,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | The setting key, verbatim. |
| `envAlias` | `String?` | The environment variable this setting may also be read from, verbatim. |
| `cmdlineAlias` | `String?` | The command-line option this setting may also be read from, verbatim. |
| `secret` | `bool` | Whether the value is a secret — a certificate, private key or shared secret. |
| `overridableBy` | `CsOverridableBy` | Which narrower scope, if any, may shadow this key. |
| `note` | `String?` | Optional part-specific note. |

#### CsMigration

CE-MG — a schema-migration artifact set (`codespecs_mapping.md` §5.27).

##### Constructors
```dart
const CsMigration({
  required this.datasource,
  required this.schema,
  required this.kind,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `datasource` | `String` | The datasource whose schema the artifacts migrate. |
| `schema` | `String` | The schema within [datasource]. |
| `kind` | `CsMigrationKind` | Which of the three artifact kinds this declaration ships. |
| `note` | `String?` | Optional part-specific note. |

#### CsJob

CE-JB — a background-job definition (`codespecs_mapping.md` §5.29).

##### Constructors
```dart
const CsJob({
  required this.trigger,
  this.cron,
  this.calendar,
  this.event,
  this.maxRetries = 0,
  this.backoff,
  this.timeout,
  this.failureAlert,
  this.targetReports = const <CsReportRef>[],
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `trigger` | `CsJobTrigger` | What starts the job. |
| `cron` | `String?` | `cron`: the cron expression, verbatim. |
| `calendar` | `String?` | `calendar`: the calendar date/time rule, verbatim. |
| `event` | `String?` | `event`: the system event name, verbatim. |
| `maxRetries` | `int` | How many times a failed run is retried. |
| `backoff` | `Duration?` | The delay before the first retry. |
| `timeout` | `Duration?` | How long a single run may take before it is abandoned. |
| `failureAlert` | `CsMessageKey?` | The message raised to the deployment's alert sink when the job fails. |
| `targetReports` | `List<CsReportRef>` | The CE-RP reports this job produces, where the work is a report run. |
| `note` | `String?` | Optional part-specific note. |

#### CsAudited

CE-LG — an audited element: an entity or endpoint whose access is recorded in the audit trail (`codespecs_mapping.md` §4.3).

##### Constructors
```dart
const CsAudited({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsNotification

CE-NT — a notification type: an outbound communication a system event emits (`codespecs_mapping.md` §4.3).

##### Constructors
```dart
const CsNotification({required this.body, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `body` | `CsMessageKey` | The body copy, as a CE-TX message key. |
| `note` | `String?` | Optional part-specific note. |

#### CsNotificationChannel

CE-NT — a notification channel: a declared delivery route (`codespecs_mapping.md` §4.3).

##### Constructors
```dart
const CsNotificationChannel({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsReport

CE-RP — a report: a grouped projection over the domain model, delivered as a rendered artifact (`codespecs_mapping.md` §5.28).

##### Constructors
```dart
const CsReport({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsReportColumn

CE-RP — one projected output column of a [CsReport] (`codespecs_mapping.md` §5.28).

##### Constructors
```dart
const CsReportColumn({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsReportChart

CE-RP — a chart declared over a [CsReport]'s projected columns (`codespecs_mapping.md` §5.28).

##### Constructors
```dart
const CsReportChart({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsReportParameter

CE-RP — a runtime input a [CsReport] takes when it is run (`codespecs_mapping.md` §5.28).

##### Constructors
```dart
const CsReportParameter({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

### Shared-contract markers

#### CsError

CE-ER — a processing error (a shared error type crossing the wire).

##### Constructors
```dart
const CsError({this.severity = CsErrorSeverity.error, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `severity` | `CsErrorSeverity` | How severe the code is. |
| `note` | `String?` | Optional part-specific note. |

#### CsEnum

A domain enum — a **member marker**, not a part marker (`codespecs_mapping.md` §4.1): annotates a plain Dart `enum` declaration authored within its owning part (a data-access entity, a configuration/settings holder, a view model, or an API contract type).

##### Constructors
```dart
const CsEnum({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional note. |

### Client, settings, identity and auth markers

#### CsClient

CE-CL — a client application (which clients exist: Flutter app, CLI, other server).

##### Constructors
```dart
const CsClient(this.clientId, {required this.kind, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `clientId` | `String` | The client's id, verbatim. |
| `kind` | `CsClientKind` | Which kind of application this is. |
| `note` | `String?` | Optional part-specific note. |

#### CsClientConfig

CE-CC — client configuration: per-machine settings of a client app (API base URL, device options, per-install toggles), keyed by (client app, machine).

##### Constructors
```dart
const CsClientConfig(
  this.key, {
  required this.overridableBy,
  this.envAlias,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | The setting key, verbatim. |
| `envAlias` | `String?` | The environment variable this setting may also be read from, verbatim. |
| `overridableBy` | `CsOverridableBy` | Which narrower scope, if any, may shadow this key — a per-user setting (CE-UP) or a per-user-per-device one (CE-DS). |
| `note` | `String?` | Optional part-specific note. |

#### CsDeviceSetting

CE-DS — a device setting: a *user-specific* setting of a user-owned device, keyed by (user, device) and persisted on the device (window layout, last-opened, machine-local cache preferences).

##### Constructors
```dart
const CsDeviceSetting(this.key, {this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | The setting key, verbatim. |
| `note` | `String?` | Optional part-specific note. |

#### CsUserSetting

CE-UP — a user setting / profile value, keyed by the **user** and persisted **server-side**, so it follows the user onto any device they sign into (theme, language, notification prefs).

##### Constructors
```dart
const CsUserSetting(this.key, {required this.overridableBy, this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | The setting key, verbatim. |
| `overridableBy` | `CsOverridableBy` | Whether a per-user-per-device setting (CE-DS) may shadow this key. |
| `note` | `String?` | Optional part-specific note. |

#### CsIdentity

CE-ID — the app's identity-extension declaration holder (`codespecs_mapping.md` §5.24).

##### Constructors
```dart
const CsIdentity({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

#### CsIdentityAttribute

CE-ID — one declared identity-extension attribute; a **member marker** on a [CsIdentity] holder, the same pattern as `@CsColumn` (`codespecs_mapping.md` §5.24).

##### Constructors
```dart
const CsIdentityAttribute({
  required this.placement,
  this.accessKey,
  this.systemOfRecord,
  this.required = false,
  this.note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `placement` | `CsIdentityAttributePlacement` | Which token payload this attribute rides in. |
| `accessKey` | `CsResourceKeyRef?` | The resource key gating field-level access to this attribute. |
| `systemOfRecord` | `String?` | The system the attribute's value is sourced from, verbatim. |
| `required` | `bool` | Whether a principal without this attribute is incomplete. |
| `note` | `String?` | Optional part-specific note. |

#### CsAuth

CE-AU — authentication / session: credential exchange, token, session.

##### Constructors
```dart
const CsAuth({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional part-specific note. |

### The collaborator marker

#### CsCollaborator

The abstract collaborator a form-3b body calls (`codespecs_derivation_contract.md` §3.0.1).

##### Constructors
```dart
const CsCollaborator({this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `note` | `String?` | Optional note. |

### Identity and forward trace

#### CodeSpec

The CodeSpecs identity + forward-trace annotation (CE-TR).

**Not a part marker** — identity / traceability.

##### Constructors
```dart
const CodeSpec(
  this.id, {
  this.source = const [],
  this.requirements = const [],
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Stable identifier for this CodeSpec element. |
| `source` | `List<String>` | SOM `@SectionId`s of the DocSpecs sections this code realises. |
| `requirements` | `List<String>` | Requirement ids (RSP / RC) this code satisfies. |

### Back-trace

#### DocSpec

The code-side back-trace half of the DocSpecs ↔ CodeSpecs link (`codespecs_mapping.md` §9.3).

**Not a part marker** — identity / traceability.

##### Constructors
```dart
const DocSpec(this.refs);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `refs` | `List<DocRef>` | The sections this code element realises, each with a description of the influence. |

#### DocRef

A single (sectionId, description) back-trace entry held by [DocSpec].

**Not a part marker** — identity / traceability.

##### Constructors
```dart
const DocRef(this.sectionId, this.description);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sectionId` | `String` | The SOM `@SectionId` of the originating section. |
| `description` | `String` | What the code takes from the section, and how it is influenced. |

## Global Functions and Constants

The module declares none.
