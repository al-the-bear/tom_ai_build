# TomSpecs Model API Reference: Common Module

The types shared across more than one TomSpecs document: the document header
every entry point carries, the authorization-requirement model the security
sections use, and the quality-characteristic enum.

For the rules that place these members, see
[`tom_specs_model_rules.md`](../tom_specs_model_rules.md).

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [DocumentHeader](#documentheader)
  - [AuthorizationRequirementSpec](#authorizationrequirementspec)
  - [GradedAuthorizationRequirement](#gradedauthorizationrequirement)
  - [GradedAccessLevelEntry](#gradedaccesslevelentry)
- [Enums](#enums)
  - [AuthorizationRequirementKind](#authorizationrequirementkind)
  - [GradedAccessLevel](#gradedaccesslevel)
  - [BasicAuthorizationRequirementKind](#basicauthorizationrequirementkind)
  - [SectionType](#sectiontype)
  - [Priority](#priority)
  - [Status](#status)
  - [Probability](#probability)
  - [Impact](#impact)
  - [Iso25010Characteristic](#iso25010characteristic)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **3 classes** and **9 enums** across three files.

| File | Holds |
|------|-------|
| `document_header.dart` | The document header — `DocumentHeader` |
| `authorization_requirement.dart` | Authorization requirements — `AuthorizationRequirementSpec`, `GradedAuthorizationRequirement`, `GradedAccessLevelEntry`, `AuthorizationRequirementKind`, `GradedAccessLevel`, `BasicAuthorizationRequirementKind` |
| `enums.dart` | Shared enums — `SectionType`, `Priority`, `Status`, `Probability`, `Impact`, `Iso25010Characteristic` |

## Class Hierarchy

```
DocSpecsSection                          (tom_specs_core)
├── DocumentHeader   with SpecNode
├── AuthorizationRequirementSpec
├── GradedAuthorizationRequirement
├── GradedAccessLevelEntry
```

`DocumentHeader` is the one hand-written model class that mixes in `SpecNode`
directly rather than adopting the snapshot contract through the generated
registry — see
[api_summary_snapshot.md](api_summary_snapshot.md#specnode).

## Classes

### DocumentHeader

Standard document header present at the top of every TomSpecs document.

**Extends:** `DocSpecsSection with SpecNode`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `cloneShallow()` | `DocumentHeader` | A shallow copy: same scalars, the same child references. Part of the `SpecNode` contract. |
| `yamlScalar()` | `String?` | This node's own scalar payload — its `content`. Part of the `SpecNode` contract. |

### AuthorizationRequirementSpec

What a caller must satisfy to reach the thing this section modifies (`codespecs_mapping.md` §5.15).

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |
| `roleRequirement` | `DocSpecsSection?` | Role requirement payload — a promoted `@OneOf` case. |
| `groupRequirement` | `DocSpecsSection?` | Group requirement payload — a promoted `@OneOf` case. |
| `entitlementRequirement` | `DocSpecsSection?` | Entitlement requirement payload — a promoted `@OneOf` case. |
| `resourceKeyRequirement` | `DocSpecsSection?` | Resource-key requirement payload — a promoted `@OneOf` case. |
| `customRequirement` | `DocSpecsSection?` | Custom requirement payload — a promoted `@OneOf` case. |
| `gradedRequirement` | `GradedAuthorizationRequirement?` | Graded requirement payload — a promoted `@OneOf` case. |

### GradedAuthorizationRequirement

A graded requirement: what a caller must satisfy for each access state (`codespecs_mapping.md` §5.15).

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |
| `accessLevels` | `List<GradedAccessLevelEntry>` | The authored rungs of the ladder — contains 1..3× Graded Access Level. |

### GradedAccessLevelEntry

One rung of a graded access ladder: an access state and the non-graded requirement that earns it (`codespecs_mapping.md` §5.15).

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |
| `roleRequirement` | `DocSpecsSection?` | Role requirement payload — a promoted `@OneOf` case. |
| `groupRequirement` | `DocSpecsSection?` | Group requirement payload — a promoted `@OneOf` case. |
| `entitlementRequirement` | `DocSpecsSection?` | Entitlement requirement payload — a promoted `@OneOf` case. |
| `resourceKeyRequirement` | `DocSpecsSection?` | Resource-key requirement payload — a promoted `@OneOf` case. |
| `customRequirement` | `DocSpecsSection?` | Custom requirement payload — a promoted `@OneOf` case. |

## Enums

### AuthorizationRequirementKind

The ten authorization-requirement kinds a security section may declare. Mirrors
`CsAuthRequirement` in `tom_code_specs` arm for arm, with one deliberate rename:
the deny preset is `denied` here where the code side calls it `none`. On the
code side `none` sits among typed slots and cannot be misread; in an authored
document "None" reads as *no authorization needed* — the exact fail-open
misreading the requirement model guards against.

| Value | Meaning |
|-------|---------|
| `role` | The caller must hold one of a named set of roles. |
| `group` | The caller must belong to one of a named set of groups. |
| `entitlement` | The caller's entitlements must match one of a set of patterns. |
| `resourceKey` | The caller must hold a grant on a named resource key. |
| `custom` | A registered handler decides, against a named resource id. |
| `graded` | A graded requirement resolving to one of the access states. |
| `denied` | Deny unconditionally. |
| `public` | Allow unconditionally, signed in or not. |
| `authenticated` | Allow any signed-in caller. |
| `guest` | Allow the guest caller. |

### BasicAuthorizationRequirementKind

`AuthorizationRequirementKind` minus `graded` — the bound that keeps the graded
arm from recursing.

| Value | Meaning |
|-------|---------|
| `role` | The caller must hold one of a named set of roles. |
| `group` | The caller must belong to one of a named set of groups. |
| `entitlement` | The caller's entitlements must match one of a set of patterns. |
| `resourceKey` | The caller must hold a grant on a named resource key. |
| `custom` | A registered handler decides, against a named resource id. |
| `denied` | Deny unconditionally. |
| `public` | Allow unconditionally, signed in or not. |
| `authenticated` | Allow any signed-in caller. |
| `guest` | Allow the guest caller. |

### GradedAccessLevel

The access states a graded requirement resolves to. **Only three are
authorable**: a caller who meets none of the levels gets no access, so "no
access" is the absence of a match rather than a level someone writes down.

What each state renders as is framework-fixed and deliberately not a
specification attribute: no access hides the thing, `disabled` shows it locked,
`read` shows its value, `full` makes it interactive.

| Value | Meaning |
|-------|---------|
| `full` | Full, interactive access. |
| `read` | The value is shown but cannot be changed. |
| `disabled` | The thing is visible but locked. |

### Iso25010Characteristic

The eight ISO/IEC 25010:2023 product-quality characteristics — the closed
vocabulary for the quality cross-map. The 2023 edition renamed *usability* to
interaction capability, folded *portability* into the new *flexibility*
characteristic, and split *compatibility* out as first-class; this enum carries
that 2023 spine.

| Value |
|-------|
| `functionalSuitability` |
| `performanceEfficiency` |
| `compatibility` |
| `interactionCapability` |
| `reliability` |
| `security` |
| `maintainability` |
| `flexibility` |

### Priority

Priority level for requirements (MoSCoW).

| Value |
|-------|
| `must` |
| `should` |
| `could` |
| `wontThisTime` |

### Status

Status of a requirement or deliverable.

| Value |
|-------|
| `draft` |
| `proposed` |
| `approved` |
| `implemented` |
| `verified` |
| `deferred` |
| `rejected` |

### Probability

Probability level for risks.

| Value |
|-------|
| `veryLow` |
| `low` |
| `medium` |
| `high` |
| `veryHigh` |

### Impact

Impact level for risks.

| Value |
|-------|
| `negligible` |
| `minor` |
| `moderate` |
| `major` |
| `critical` |

### SectionType

Section type in DocSpecs annotations.

| Value |
|-------|
| `description` |
| `form` |
| `code` |

## Global Functions and Constants

The module declares none.
