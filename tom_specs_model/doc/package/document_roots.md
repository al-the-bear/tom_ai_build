# TomSpecs Model — The Container Root and the Fourteen Documents

A specification is **one document with fourteen entry points**. This guide
covers the container that gives them a single true root, the difference between
the Solution Blueprint master and the thirteen projections over it, and the
connect pass that makes a per-root save reflect current content. Which sections
each document carries, and the traceability rules behind the projections, are
[`tom_specs_model_rules.md`](../tom_specs_model_rules.md); the phases they are
produced in are
[`tom_specs_project_flow.md`](../tom_specs_project_flow.md). Both are cited
here, not restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [DocSpecsProject — the container root](#docspecsproject--the-container-root)
  - [The fourteen entry points](#the-fourteen-entry-points)
- [The master and its projections](#the-master-and-its-projections)
- [The two save paths](#the-two-save-paths)
- [The connect pass](#the-connect-pass)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

`DocSpecsProject` is the canonical root of the whole object model. Without it
there would be fourteen disconnected trees, and an editor would have to load,
snapshot, serialize and undo each separately. With it, every operation runs on
one object.

The container is deliberately **not a document**. It carries no `@SectionId` and
no `@Document`, because it is the tree root the tooling walks, not a fifteenth
sibling. Tooling treats it as the canonical root and exempts it from the
section-id coverage and uniqueness checks.

## Quick Start

```dart
import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final project = DocSpecsProject();

  project.solutionBlueprint.documentControl.header.content =
      'SBP — Meridian Order Platform v0.1 (Draft)';

  print(project.solutionBlueprint.documentControl.header.content);
  print(project.solutionBlueprint.runtimeType);
  print(project.informationModel.runtimeType);
  print(project.codeSpecsProjection.runtimeType);
}
```

Output:

```
SBP — Meridian Order Platform v0.1 (Draft)
D00SolutionBlueprint
D03InformationModel
D13CodeSpecsProjection
```

Constructing a `DocSpecsProject` also registers the generated snapshot and
serialization ops, idempotently, so the snapshot engine and the save paths work
immediately — see [snapshot_and_serialization.md](snapshot_and_serialization.md).

## Core Components

### `DocSpecsProject` — the container root

| Member | Type | Role |
|--------|------|------|
| `solutionBlueprint` | `D00SolutionBlueprint` | The master and source of truth |
| `currentLandscapeAssessment` … `transitionRolloutPlan` | The twelve `D01`–`D12` roots | Phase 3 projections |
| `codeSpecsProjection` | `D13CodeSpecsProjection` | The Phase 4 generation projection |
| `toYaml({tree, modelVersion})` | `String` | The global save — the master alone |
| `toYamlForRoot(root, {tree, modelVersion})` | `String` | The per-root save, connect pass first |

The member order is not the document number order: the fields are stamped in
source-declaration order, and the navigator lists the Solution Blueprint first,
then the twelve Phase 3 roots, then the CodeSpecs projection.

### The fourteen entry points

| # | Section id | Member | Document |
|---|-----------|--------|----------|
| D00 | `SBP` | `solutionBlueprint` | Solution Blueprint — **the master** |
| D01 | `CLA` | `currentLandscapeAssessment` | Current Landscape Assessment |
| D02 | `TOM` | `targetOperatingModel` | Target Operating Model |
| D03 | `IFM` | `informationModel` | Information Model |
| D04 | `RSP` | `requirementsSpecification` | Requirements Specification |
| D05 | `ISC` | `interactionScenarios` | Interaction Scenarios |
| D06 | `ATS` | `architectureTechnologySpecification` | Architecture & Technology Specification |
| D07 | `IIS` | `integrationInterfaceSpecification` | Integration & Interface Specification |
| D08 | `SAS` | `securityAccessSpecification` | Security & Access Specification |
| D09 | `XDS` | `experienceDesignSpecification` | Experience Design Specification |
| D10 | `QAP` | `qualityAcceptancePlan` | Quality & Acceptance Plan |
| D11 | `DRM` | `deliveryRoadmap` | Delivery Roadmap |
| D12 | `TRP` | `transitionRolloutPlan` | Transition & Rollout Plan |
| D13 | `CGP` | `codeSpecsProjection` | CodeSpecs Generation Projection |

```dart
import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final project = DocSpecsProject();

  // Every root is default-constructed and reachable from the container.
  final roots = <Object>[
    project.solutionBlueprint,
    project.currentLandscapeAssessment,
    project.targetOperatingModel,
    project.informationModel,
    project.requirementsSpecification,
    project.interactionScenarios,
    project.architectureTechnologySpecification,
    project.integrationInterfaceSpecification,
    project.securityAccessSpecification,
    project.experienceDesignSpecification,
    project.qualityAcceptancePlan,
    project.deliveryRoadmap,
    project.transitionRolloutPlan,
    project.codeSpecsProjection,
  ];

  print(roots.length);
  print(roots.map((r) => r.runtimeType.toString().substring(0, 3)).join(' '));
}
```

Output:

```
14
D00 D01 D02 D03 D04 D05 D06 D07 D08 D09 D10 D11 D12 D13
```

## The master and its projections

**The Solution Blueprint owns every section.** The other thirteen roots are
`@Document(basedOn: [D00SolutionBlueprint])` *projections*: they reference the
same sections through their traceability links, and they do not own copies.

The consequence is the one to internalise: **editing through any projection
edits the shared underlying Solution Blueprint section.** There is one tree, and
the projections are views onto it.

The thirteen split into two kinds:

- **The twelve Phase 3 projections** are `@MapsTo` / `@DetailedIn`-driven — each
  section names the document it flows into and the level it enters at.
- **The CodeSpecs projection (D13)** is `@CodeSpecKind`-driven instead: it
  reaches only the CodeSpecs subtrees Phase 4 consumes, grouped by
  shared / client / server locus. It carries `@CodeSpecsProjection()`, which
  exempts it from the detail-count check *only* — it must still be a pure
  projection, reaching no type the Solution Blueprint tree does not contain.

## The two save paths

| Path | Serializes | `tree` must be |
|------|-----------|----------------|
| `toYaml(tree:)` | The Solution Blueprint master alone | The metadata tree of `D00SolutionBlueprint` |
| `toYamlForRoot(root, tree:)` | One root, connect pass first | The metadata tree of **that root** |

`toYaml` is the global save. Because the projections are views over the same
sections, the Solution Blueprint tree contains every section exactly once, so
the output never duplicates a subtree — which is why the global save is the
master alone rather than a concatenation of fourteen files.

`toYamlForRoot` is the per-root write. Passing `solutionBlueprint` to it is
exactly `toYaml`; passing any other root runs the connect pass first.

The `tree` argument is the trap. It must be the metadata tree of the root being
written, not of the Solution Blueprint, because it is that root's own file being
produced.

## The connect pass

A projection root holds *references*, and between writes a reference may be
stale or unset. The connect pass re-points every one of them onto the live
Solution Blueprint sections immediately before serialization, so a per-root
write always reflects current content.

All thirteen projection roots carry a generated connect binding —
one hundred and fifty bindings in all, derived from the model's own structure
rather than from the traceability annotations. That derivation matters: it is
what makes a projection re-point onto the live master instead of serializing
default-constructed sections.

The one child a binding deliberately leaves alone is the **document header**.
Each of the fourteen entry points is a document in its own right, with its own
id, version and author, so the header is not shared. Note where it sits: the
master reaches its header through `documentControl`, while each projection root
carries a `header` member directly.

```dart
import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final project = DocSpecsProject();

  // The master's header lives under its document-control section…
  project.solutionBlueprint.documentControl.header.content = 'SBP v0.1';

  // …and each projection root carries a `header` of its own, directly.
  project.informationModel.header.content = 'IFM v0.1';

  print(project.solutionBlueprint.documentControl.header.content);
  print(project.informationModel.header.content);
  print(identical(project.solutionBlueprint.documentControl.header,
      project.informationModel.header));
}
```

Output:

```
SBP v0.1
IFM v0.1
false
```

## Error Handling

| Situation | Result |
|-----------|--------|
| `toYamlForRoot` with the wrong root's `tree` | `SpecYamlFormatException` — the object tree and the metadata tree disagree |
| An object whose members the metadata tree does not describe | `SpecYamlFormatException`, naming the path |
| Form field values on a section the metadata tree does not declare as a form | `SpecYamlFormatException` |
| A projection root with no generated connect binding | Serializes its own (default-constructed) sections silently |
| Editing a section through a projection | Edits the shared master section — by design, not an error |

`SpecYamlFormatException` is loud on purpose: the alternative to failing here is
a file that silently lost data. If a save throws, read the path in the message —
it names the node where the object tree and the metadata tree parted company.

## Best Practices

- **Construct one `DocSpecsProject` and work through it.** It is what makes
  load, save, snapshot and undo single operations.
- **Pass the right `tree`.** For `toYamlForRoot`, it is the metadata tree of the
  root being written, never the Solution Blueprint's.
- **Remember there is one tree.** An edit through a projection is an edit to the
  master; if you wanted a separate value, you wanted a different section.
- **Do not construct a projection root standalone and serialize it.** Without
  the connect pass it holds unbound references and writes default-constructed
  sections. Go through `toYamlForRoot`.
- **Treat the document header as per-entry-point.** It is the one thing the
  connect pass leaves alone, deliberately.

---

Back to the [package documentation index](index.md).
