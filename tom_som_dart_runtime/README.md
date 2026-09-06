# tom_som_dart_runtime — generic Dart SOM runtime

> **Cross-references.**
> [`tom_specs_model/doc/som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
> is the SOM authority: `SOM §9` decides what a runtime must contain, `SOM §6`
> decides the split between the generic and the typed access path, `SOM §11` and
> `SOM §12` decide the `*.md` and `*.docspecs.yaml` formats, and `SOM §19`
> decides the conformance corpus this port is measured against.
> [`tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md)
> decides this language plane's build and verify toolchain. This README says how
> to **use this package's code**; those documents own the model, the formats and
> the rules, and nothing here restates them.

TomSpecs Specification Object Model — generic Dart runtime. The
language-independent, hand-written runtime shared by every generated typed
`tom_som_dart_v0` facade and the TomSpecs editor: the path-keyed in-memory
document representation, the meta-model ("reflection") classes that load the
exported spec-model meta-data, and the document validator. Pure Dart, no Flutter
dependency.

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this package) holding everything that is the same
everywhere, and a generated `tom_som_<lang>_v0` facade holding the typed classes
for one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator, and nine independent
reimplementations would drift; with it, the generator emits only what actually
changes when the model changes.

This package is additionally the **reference** for the other eight runtimes:
everything they mirror, they mirror from here (`SOM §9`), and the shared
conformance corpus in [`tom_som_conformance`](../tom_som_conformance) is computed
from this runtime rather than hand-written. It is also the shared layer beneath
both TomSpecs Flutter apps — the editor (`tom_specs_editor`) and the model
reviewer (`tom_specs_reviewer`) — so **a reader for the spec model belongs here
rather than in either app**: an accessor added here is inherited by both, whereas
one added in an app has to be duplicated to reach the other.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the package is a layer over it:

- **the meta-model** — `SpecModel` loads the exported class graph
  (`meta/spec_model.meta.json`), and `SpecReflection` resolves a path against it
  without touching values, which is what makes generic navigation possible;
- **the codecs** — byte-stable `*.docspecs.yaml` and DocSpecs-conform Markdown,
  both driven by the meta-model so a new model version needs no codec change;
- **the editing and validation tiers** — `SpecEditor` for typed edits over any
  path, `SpecNodeCreator` to keep growth inside what the model permits, and
  `validateDocument` for the instance-tier check;
- **the scripting and Phase-4 tiers** — `SpecQueryEngine` over the portable
  `SomTextPattern` subset, and `CodeSpecsExtractor`, the machine half of Phase 4.

Most callers depend on the typed facade `tom_som_dart_v0`, which re-exports this
runtime. Reach for the runtime directly when you need the **generic**, untyped
document API or the meta-model.

## Installation

```yaml
dependencies:
  tom_som_dart_runtime: ^1.1.0
```

```bash
dart pub add tom_som_dart_runtime
```

The version tracks the TomSpecs **model version**, and `tom_som_dart_v0` pins the
same one — upgrade both together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for every dependency route
and how to pin.

## Features

### Modules

| Module | Responsibility |
| ------ | -------------- |
| `spec_paths.dart` | The section-path grammar (root / child / list-item segments). |
| `spec_model.dart` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_meta.dart`, `spec_meta_bridge.dart`, `spec_meta_diff.dart` | The metadata tree (`SomMetaNode`, `SomMetaTree`, `buildSomMetaTree`) and its comparison (`SOM §7`). |
| `spec_reflection.dart` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, `SpecNodeKind`). |
| `spec_document.dart` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values.dart` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.dart` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.dart` | Validates a document's values against the model (`validateDocument`). |
| `spec_text_pattern.dart` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime. |
| `spec_query.dart` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection. |
| `spec_node_creation.dart` | The constrained node-creation gate (`checkAddNode`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.dart` | The Phase-4 CodeSpecs specification-extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — one bounded, cited extract per CodeSpecs area, copied verbatim with provenance, never summarised. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_document_yaml.dart` | Byte-stable `*.docspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.dart` | Meta-data-driven Markdown import/export codec (`SOM §11`). |
| `docspecs_validator.dart` | Schema-free DocSpecs parse, schema loader, and never-fail-fast validator (`SOM §14`). |
| `som_facade.dart` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList`, `checkSomModelVersion`, `somEditabilityFor`) for the generated `tom_som_dart_v0`. |
| `spec_section_id.dart`, `spec_serialization_order.dart` | Section-id and serialization-order helpers shared by the codecs. |
| `spec_annotation_display.dart` | The annotations' display semantics (`SpecChip`, `SpecRowExtras`, `kRenderedAnnotations`), shared by both TomSpecs Flutter apps. |

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages.

## Quick start

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  // The generic, path-keyed document store underneath every typed facade.
  final doc = SpecDocument();
  doc.setContent('SBP/content', 'A platform that unifies our order systems.');

  print(doc.content('SBP/content'));
  // A platform that unifies our order systems.
}
```

## Usage

### The generic path

Load the exported class graph, then resolve and enumerate by path — no generated
classes involved:

```dart
final model = SpecModel.fromJson(jsonDecode(metaJson) as Map<String, dynamic>);
final reflection = SpecReflection(model);

print(reflection.resolve('SBP/content') != null);
// true
```

### Editing and validation

`SpecEditor` applies typed edits over any path — converting at the store
boundary and refusing a path the model does not permit; `validateDocument`
checks the whole instance against the model:

```dart
final editor = SpecEditor.forModel(doc, model);
editor.setValue('SBP/content', 'A unifying order platform.');

print(validateDocument(model, doc).isEmpty);
// true
```

### Serializing

Both codecs are byte-stable and driven by the metadata tree, so any runtime
reproduces any other runtime's bytes:

```dart
final tree = buildSomMetaTree(model);
final yaml = SpecDocumentYaml.encode(document: doc, tree: tree);
final round = SpecDocumentYaml.decode(yaml, tree);

print(round.document.content('SBP/content') == doc.content('SBP/content'));
// true
```

### Changing the public surface

This package's public surface is the source for the generated D4rt bridges in
`tom_spec_engine` (`lib/src/bridges/som_runtime_bridges.b.dart`), which are
generated **there**, not here. Adding, removing or re-signing anything reachable
from the barrel makes those bridges stale, so follow the edit with:

```bash
cd ../tom_spec_engine && dart run tool/regenerate_bridges.dart
```

The engine's test suite fails until this is done — see
`tom_spec_engine/_copilot_guidelines/bridge_regeneration.md` § "How staleness is
caught" — but it fails only for whoever next runs *that* suite, which is why the
regen belongs here, at the point of editing.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), which is generated from
this runtime and which every other port is validated against byte-for-byte
(`SOM §19`):

```bash
dart pub get
dart analyze
./run_tests.sh        # or: dart test
```

## Architecture

```
        typed path                          generic path
  tom_som_dart_v0 facade   ─────▶   SomNode / SomScalar / SomList
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor       SpecDocumentYaml
  SpecQueryEngine      validateDocument SpecDocumentMarkdown
        │
        ▼
     SpecModel  ◀── meta/spec_model.meta.json
```

| Type | Responsibility |
| ---- | -------------- |
| `SpecDocument` | The sparse, path-keyed store of a document's content, form and list values. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated classes. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `validateDocument` | The instance tier: a filled document's values checked against the model. |
| `SpecDocumentYaml` | Byte-stable `*.docspecs.yaml` encode/decode. |
| `SpecDocumentMarkdown` | DocSpecs-conform Markdown export, parse and round-trip. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SomNode` / `SomScalar` / `SomList` | The editing-facade base types the generated `tom_som_dart_v0` classes extend. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──generate_som──▶ tom_som_dart_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ depends on
                                                                  ▼
                                                        tom_som_dart_runtime  ← this package
                                                                  │ validated against
                                                                  ▼
                                                         tom_som_conformance
                                                          (shared corpus)
```

## Further documentation

**TomSpecs subject matter** — the authorities this package implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs subject-matter document, and the `§` citation convention. |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.md` and `*.docspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the reference host. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |
| [tom_specs_model_rules.md](../tom_specs_model/doc/tom_specs_model_rules.md) | The model-authoring rules the class graph obeys — field shapes, section ids, annotations, invariants. |

**Runnable samples** — a whole task carried end to end across several
packages, as opposed to this package's own `example/`:
[`tom_specs_samples/`](../tom_specs_samples/README.md)
(`tom_specs_documentation_standard.md` §7).

**This package** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_dart_v0](../tom_som_dart_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |
| [tom_specs_clitool](../tom_specs_clitool) | The generator (`generate_som.dart`) and the model-inspection tools. |
| [tom_spec_engine](../tom_spec_engine) | The scripting plane, where this package's D4rt bridges are generated. |

## Status

Version **1.1.0**, tracking the TomSpecs model version. Covered by 22 test files
carrying **562 tests**, conformance suite included; `./run_tests.sh` is green.
