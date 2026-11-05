# TomSpecs Model API Reference: Common Module

The types shared across more than one TomSpecs document: the document header
every entry point carries, the review teams and the reviewers of a revision,
the authorization-requirement model the security sections use, and the shared
enums.

For the rules that place these members, see
[`tom_specs_model_rules.md`](../tom_specs_model_rules.md).

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [DocumentHeader](#documentheader)
  - [ReviewTeam](#reviewteam)
  - [ReviewTeamMember](#reviewteammember)
  - [DocumentReviewTeamEntry](#documentreviewteamentry)
  - [ReviewerRecord](#reviewerrecord)
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
  - [SpecDocumentType](#specdocumenttype)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **7 classes** across four files; the enums below are the
ones this page documents.

| File | Holds |
|------|-------|
| `document_header.dart` | The document header — `DocumentHeader` |
| `review_team.dart` | Review teams and the reviewers of a revision — `ReviewTeam`, `ReviewTeamMember`, `DocumentReviewTeamEntry`, `ReviewerRecord` |
| `authorization_requirement.dart` | Authorization requirements — `AuthorizationRequirementSpec`, `GradedAuthorizationRequirement`, `GradedAccessLevelEntry`, `AuthorizationRequirementKind`, `GradedAccessLevel`, `BasicAuthorizationRequirementKind` |
| `enums.dart` | Shared enums — among them `SectionType`, `Priority`, `Status`, `Probability`, `Impact`, `Iso25010Characteristic`, `SpecDocumentType` |

## Class Hierarchy

```
DocSpecsSection                          (tom_specs_core)
├── DocumentHeader   with SpecNode
├── ReviewTeam
├── ReviewTeamMember
├── DocumentReviewTeamEntry
├── ReviewerRecord
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

### ReviewTeam

Who reviews a document (`RVTEAM`). Three levels name a team, and the most
specific one with members replaces the others entirely: a document's own
`reviewTeam`, the Solution Blueprint's `DocumentReviewTeamEntry` for its
document type, the Solution Blueprint's default `reviewTeam`
(`StakeholdersAndGovernance`). A team without members names no team.

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |
| `members` | `List<ReviewTeamMember>` | The members (`RVMEM-MEMB-LST`). |

### ReviewTeamMember

One member of a review team (`RVMEM`), a form: `memberId` (required; lowercase
letters, digits and `_`, the id the team-review notation of SOM §11.9.8 uses),
`displayName` and `role` (required), `stakeholder` (refers to a stakeholder
register entry), `email` (stored only) and `owner` (`true` for the
specification owner).

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |

### DocumentReviewTeamEntry

The Solution Blueprint's review team for one document type (`DCRVTM`): a form
with the required `documentType` (`SpecDocumentType`), and the members.

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |
| `members` | `List<ReviewTeamMember>` | The members (`RVMEM-MEMB-LST`). |

### ReviewerRecord

A reviewer of one revision (`RVWER`), written out in full so a guest reads
without a team list: a form with `memberId` and `displayName` (required),
`role` and `guest`. `RevisionEntry` holds two lists of them: `reviewTeam`, the
team the round started with, and `reviewers`, who returned a copy.

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | The section body. On a form section this is the preamble; the field values live in `form`. |

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

### SpecDocumentType

The type of a Phase 3 document, by which the Solution Blueprint names a
per-document review team. Each constant is the root class name with a lowercase
first letter; the Solution Blueprint and the CodeSpecs projection are not
listed.

| Value |
|-------|
| `d01CurrentLandscapeAssessment` |
| `d02TargetOperatingModel` |
| `d03InformationModel` |
| `d04RequirementsSpecification` |
| `d05InteractionScenarios` |
| `d06ArchitectureTechnologySpecification` |
| `d07IntegrationInterfaceSpecification` |
| `d08SecurityAccessSpecification` |
| `d09ExperienceDesignSpecification` |
| `d10QualityAcceptancePlan` |
| `d11DeliveryRoadmap` |
| `d12TransitionRolloutPlan` |

## Global Functions and Constants

The module declares none.
