# tom_specs_model — the TomSpecs Specification Object Model

> **Cross-references.**
> [`doc/index.md`](doc/index.md) is the catalogue of the fourteen TomSpecs
> authority documents this package carries, and it owns the `§` citation
> convention used across all of them.
> [`doc/tom_specs_model_rules.md`](doc/tom_specs_model_rules.md) owns the
> **model-authoring rules** — field shapes, form decomposition, section ids,
> annotations, structural invariants — and
> [`doc/som_multiplatform_spec_model.md`](doc/som_multiplatform_spec_model.md)
> owns the **nine-language generation** and every serialization format. This
> README is the guide to *this package's code*: what it holds, how it is laid
> out, and how to depend on it; those documents own *what the model must be*
> and *what the generator makes of it*.

Typed Dart data model for all TomSpecs specification documents — the source of
truth the SOM generator derives the nine language runtimes from.

## Where this fits

**TomSpecs** is a method for building software from structured specification
documents: a project is written up as a set of typed documents, and the code
skeleton is generated from them. `tom_specs_model` is the Dart source model
that defines what those documents *are* — one class tree per document, carrying
every section id, headline, form field, constraint and traceability link.

It exists so the definition has exactly one home. Nine languages ship a runtime
for reading and writing TomSpecs documents, and a schema, a markdown
serializer, a validator and an editor all have to agree on the same structure.
Written nine times, they would agree on the day they were written and never
again. Written once here, everything downstream is *generated* — the nine
`tom_som_<lang>_v0` facades, their runtimes, the DocSpecs schemas and the class
outlines all derive from this tree, so they cannot drift from it.

It therefore sits at the top of the generation chain and the bottom of the
dependency graph: it is annotated with [`tom_specs_core`](../tom_specs_core),
read by [`tom_specs_clitool`](../tom_specs_clitool), and everything a consumer
touches is generated out of it. It is also the **version authority** for the
whole lockstep chain — the version in its `pubspec.yaml` is the TomSpecs model
version, stamped by the versioner, read by the generator, and carried by all
nine generated runtime/facade pairs.

## Overview

The package is a data model and nothing else — no I/O, no logic beyond
serialization support. Its content is:

- **Fourteen document roots.** `D00SolutionBlueprint` is the master document;
  `D01`–`D12` are the Phase-3 detail documents derived from it; `D13` is the
  flat CodeSpecs generation projection. Each is a class marked `@Document`.
- **One container.** `DocSpecsProject` holds all fourteen roots, so the whole
  model has a single reachable root for the generator and the tooling to walk.
- **Shared types** in `lib/src/common/` — the enums, `Requirement`, `Risk`,
  `DocumentHeader` and section metadata that more than one document uses.
- **The generated `SpecClassOps` registry** (`lib/src/generated/spec_ops.g.dart`),
  which gives every concrete class its snapshot and serialization contract, and
  wires each projection root onto the live `D00SolutionBlueprint` instance
  rather than onto default-constructed sections.

Every section class extends `DocSpecsSection` from
[`tom_specs_core`](../tom_specs_core), so a `*.md` document parses back into
the model with full headline and id fidelity.

### What this package is (and is not)

- It **is** the model the generator reads: every class tree, section id,
  headline, form decomposition, traceability link and DocSpecs constraint that
  the nine generated runtimes and typed facades carry originates here.
- It is **not** the package most consumers depend on. To author, read,
  validate, or extract from a specification document in Dart, depend on
  **[`tom_som_dart_v0`](../tom_som_dart_v0)** (the generated typed facade) and
  its runtime [`tom_som_dart_runtime`](../tom_som_dart_runtime). Depend on
  `tom_specs_model` when you need the model source itself — to run the
  generator, or the model-level tooling in
  [`tom_specs_clitool`](../tom_specs_clitool).

## Installation

```yaml
dependencies:
  tom_specs_model: ^1.1.0
```

or

```bash
dart pub add tom_specs_model
```

```dart
import 'package:tom_specs_model/tom_specs_model.dart';
```

The single barrel exports all fourteen document roots, the container, the
shared types, and the serialization and snapshot support.

## Features

### The document set

| Root class | Code | Document |
|------------|------|----------|
| `D00SolutionBlueprint` | SBP | Solution Blueprint — the master document every Phase-3 document derives from |
| `D01CurrentLandscapeAssessment` | CLA | Current landscape assessment |
| `D02TargetOperatingModel` | TOM | Target operating model |
| `D03InformationModel` | IFM | Information model |
| `D04RequirementsSpecification` | RSP | Requirements specification |
| `D05InteractionScenarios` | ISC | Interaction scenarios |
| `D06ArchitectureTechnologySpecification` | ATS | Architecture and technology specification |
| `D07IntegrationInterfaceSpecification` | IIS | Integration and interface specification |
| `D08SecurityAccessSpecification` | SAS | Security and access specification |
| `D09ExperienceDesignSpecification` | XDS | Experience design specification |
| `D10QualityAcceptancePlan` | QAP | Quality and acceptance plan |
| `D11DeliveryRoadmap` | DRM | Delivery roadmap |
| `D12TransitionRolloutPlan` | TRP | Transition and rollout plan |
| `D13CodeSpecsProjection` | CGP | The flat CodeSpecs generation projection |

Which phase each document belongs to, and what a project does with it, is
decided by
[`doc/tom_specs_project_flow.md`](doc/tom_specs_project_flow.md).

### What is derived from this model

| Artefact | Produced by | Consumed by |
|----------|-------------|-------------|
| `spec_model.meta.json` — the resolved class graph | `tom_specs_clitool`'s `ModelJsonExporter` | all nine SOM runtimes, the editor, the reviewer |
| Nine `tom_som_<lang>_v0` typed facades + `_runtime` pairs | `tom_specs_clitool/bin/generate_som.dart` | applications reading or writing specifications |
| DocSpecs schemas | `docspecs_schema_generator.dart` | document validation |
| Class-tree outlines (`generated-doc/outlines/`) | `tom_specs_clitool/tool/regenerate_outlines.sh` | review and documentation |
| The CodeSpecs area catalogue (`generated-doc/codespecs/`) | `tom_specs_clitool/bin/codespecs_areas.dart` | Phase-4 extract generation |

Because all of it is generated, **a model edit is not finished until the
generator has been re-run**. That is enforced rather than remembered: the
clitool fingerprints the model source, and a model change that never reached
the nine packages fails its test suite.

## Quick start

```dart
// dart run example/tom_specs_model_example.dart
import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final pd = D00SolutionBlueprint()
    ..documentControl.header.content =
        'SBP — Example Project v0.1 by Author (Draft)';
  print('Document: ${pd.documentControl.header.content}');
  // Document: SBP — Example Project v0.1 by Author (Draft)
}
```

## Examples

| Sample | Demonstrates |
|--------|--------------|
| [example/tom_specs_model_example.dart](example/tom_specs_model_example.dart) | Constructing a Solution Blueprint root and writing its document header |

## Usage

### Working with the whole project

`DocSpecsProject` is the single root over all fourteen documents. Constructing
it registers the generated `SpecClassOps` contracts, so serialization and
snapshotting work without a separate setup call.

```dart
import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final project = DocSpecsProject();
  project.solutionBlueprint.documentControl.header.content =
      'SBP — Example Project v0.1 by Author (Draft)';

  // The Phase-3 roots hang off the same project.
  print(project.requirementsSpecification.runtimeType);
  // D04RequirementsSpecification
}
```

### Authoring a new section

A section is a class extending `DocSpecsSection`, annotated with the
[`tom_specs_core`](../tom_specs_core) vocabulary. What each annotation means,
and which ones a given section must carry, is decided by
[`tom_specs_model_rules.md`](doc/tom_specs_model_rules.md) — in particular its
field-type rules (`tom_specs_model_rules.md` §6.1) and the seventeen structural
invariants the validator enforces (`tom_specs_model_rules.md` §10.2).

Two mechanical steps follow every model edit, in this order:

```bash
cd ../tom_specs_clitool
dart run bin/stamp_serialization_order.dart   # renumber @SerializationOrder
dart run bin/generate_som.dart                # regenerate the nine runtimes
./tool/regenerate_outlines.sh                 # refresh generated-doc/outlines
```

The stamping step is not optional: the generator refuses to run past an
unstamped member, so a member inserted where it belongs in the source gets its
stamp from the tool rather than by hand.

## Architecture

```
tom_specs_model
├── lib/src/common/                 shared enums, Requirement, Risk, header
├── lib/src/solution_blueprint/     D00 — the master document
├── lib/src/<document>/             D01–D12 — one folder per Phase-3 document
├── lib/src/codespecs_projection/   D13 — the flat CodeSpecs projection
├── lib/src/docspecs_project.dart   DocSpecsProject — the container root
├── lib/src/generated/spec_ops.g.dart   the generated SpecClassOps registry
├── doc/                            the fourteen authority documents
└── generated-doc/                  outlines + CodeSpecs areas (never hand-edited)

  tom_specs_core ──annotates──▶ tom_specs_model ──scanned by──▶ tom_specs_clitool
                                                                       │ emits
                                                                       ▼
                                                          spec_model.meta.json
                                                                       │
                                                                       ▼
                                            nine tom_som_<lang>_v0 / _runtime pairs
```

| Type | Responsibility |
| --- | --- |
| `DocSpecsProject` | The container root holding all fourteen document roots; registers the generated `SpecClassOps` on construction. |
| `D00SolutionBlueprint` | The master document; every Phase-3 document's content is traced back to a section of it. |
| `D01`–`D12` roots | The twelve Phase-3 detail documents, each a `@Document` class tree. |
| `D13CodeSpecsProjection` | The flat CodeSpecs generation projection — references the CodeSpecs subtree roots directly, grouped by locus. |
| `Requirement`, `Risk`, `DocumentHeader` | Shared types used by more than one document. |
| `SpecClassOps` (generated) | Per-class snapshot and serialization contract, keyed by section id rather than by Dart field name. |

## Ecosystem

```
              tom_specs_core            the annotation vocabulary
                     │
                     ▼
              tom_specs_model           ← this package (version authority)
                     │
                     ▼
             tom_specs_clitool          generator, validator, gates
                     │
        ┌────────────┴─────────────┐
        ▼                          ▼
  spec_model.meta.json      nine tom_som_<lang>_v0 facades
        │                     + tom_som_<lang>_runtime pairs
        ▼
  tom_specs_editor          the spec authoring app
  tom_specs_reviewer        the model review app
  tom_spec_engine           the scripting / agent plane
```

## Further documentation

**TomSpecs subject matter** — the fourteen authority documents, carried in this
package's own [`doc/`](doc) folder:

| Document | Authority for |
|----------|---------------|
| [doc/index.md](doc/index.md) | The catalogue of the whole set, and the `§` citation convention |
| [doc/tom_specs_model_rules.md](doc/tom_specs_model_rules.md) | Model layout, field shapes, section ids, annotations, the structural invariants, and the outliner |
| [doc/som_multiplatform_spec_model.md](doc/som_multiplatform_spec_model.md) | The nine-language generation, the metadata tree, serialization, schemas, validation and packaging |
| [doc/tom_specs_model_meta_schema.md](doc/tom_specs_model_meta_schema.md) | The on-disk schema of the generated `spec_model.meta.json` |
| [doc/som_generator_config.md](doc/som_generator_config.md) | The `tom-spec-object-model` generator config block |
| [doc/som_toolchains.md](doc/som_toolchains.md) | Per-language build and verify toolchains for the generated runtimes |
| [doc/tom_specs_project_flow.md](doc/tom_specs_project_flow.md) | The creation process — phases, quality gates, iteration rules, roles |
| [doc/codespecs_mapping.md](doc/codespecs_mapping.md) | Which SOM section feeds which CodeSpecs part — the grounding document |
| [doc/codespecs_derivation_contract.md](doc/codespecs_derivation_contract.md) | What code comes out of Phase 4, per marker, and the validator checks |
| [doc/codespecs_prompt.md](doc/codespecs_prompt.md) | When a Phase-4 run may begin at all — the starting prompt and its gate |
| [doc/tom_specs_editor_specification.md](doc/tom_specs_editor_specification.md) | The spec authoring application |
| [doc/tom_specs_reviewer_specification.md](doc/tom_specs_reviewer_specification.md) | The object-model review application |
| [doc/llm_and_d4rt_tools.md](doc/llm_and_d4rt_tools.md) | The `tom_spec_engine` scripting plane — scopes, search, tools, memory |
| [doc/llm_guidelines_specification.md](doc/llm_guidelines_specification.md) | The in-editor agent's context prompt |
| [doc/tom_specs_documentation_standard.md](doc/tom_specs_documentation_standard.md) | What documentation every TomSpecs package carries, and when it is finished |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_specs_core](../tom_specs_core) | The annotation vocabulary this model is written in |
| [tom_specs_clitool](../tom_specs_clitool) | The generator, validator, outliner and citation gates that read this model |
| [tom_som_dart_v0](../tom_som_dart_v0) | The generated Dart facade — what a Dart consumer actually depends on |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The generic Dart runtime behind that facade |
| [tom_som_conformance](../tom_som_conformance) | The harness proving the nine generated runtimes agree |

## Status

Version **1.1.0**, published on pub.dev. This version is the **TomSpecs model
version**: it is stamped by the versioner, read by the SOM generator, and the
nine generated runtime and facade packages are kept in lockstep with it.

Test suite: **43 tests, all passing** (`dart test`).

Part of **TomSpecs Release 1** — see the repository's `README.md` and
`RELEASE_NOTES.md` (https://github.com/al-the-bear/tom_ai_build). Licensed
under BSD 3-Clause.
