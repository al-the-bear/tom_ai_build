# tom_som_python_runtime — generic Python SOM runtime

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

Python port of the generic TomSpecs object-model runtime (paths, model,
reflection, document, validator, YAML/Markdown codecs).

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this package) holding everything that is the same
everywhere, and a generated `tom_som_python_v0` facade holding the typed classes
for one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator; with it, the generator emits only
what actually changes when the model changes.

This package is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime) — it invents nothing, and
"faithful" is a measured claim rather than an intention: every port is validated
against the same goldens, byte for byte (`SOM §19`). Reach for it directly when
you drive the generic API by section path; otherwise install the typed facade,
which pulls this in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the package is a layer over it
— the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated classes, the byte-stable YAML and Markdown codecs,
the editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages.

## Installation

```bash
pip install tom_som_python_runtime
```

The distribution is `tom_som_python_runtime`; the importable package is
`tom_som_runtime`. The version tracks the TomSpecs **model version**, and
`tom_som_python_v0` pins the same one — upgrade both together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for the PyPI / git /
editable routes and how to pin.

## Features

### Modules

| Module | Responsibility |
| ------ | -------------- |
| `spec_paths` | The section-path grammar (root / child / list-item segments). |
| `spec_model` | The meta-data loader — the exported class graph (`SpecModel`). |
| `spec_reflection` | Value-free enumeration + path resolution (`SpecReflection`). |
| `spec_document` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator` | Validates a document's values against the model. |
| `spec_text_pattern` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime. `re` is not used, and this module converts to code units explicitly (`utf16_units`) rather than iterating characters: a Python string is a sequence of *code points*, which agrees with code units throughout the BMP and diverges above it. |
| `spec_query` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation` | The constrained node-creation gate (`check_add_node`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_document_yaml` | Byte-stable `*.docspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown` | Meta-data-driven Markdown import/export codec (`SOM §11`). |
| `spec_codespecs_extract` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — one extract per CodeSpecs area, collecting every value `@CodeSpecKind` routes there **verbatim and with provenance**. It copies and indexes; it never summarises or composes. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |

## Quick start

```python
from tom_som_runtime import SpecDocument

doc = SpecDocument()
doc.set_content("SBP/content", "A platform that unifies our order systems.")
print(doc.content("SBP/content"))
# A platform that unifies our order systems.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
classes involved:

```python
import json
from tom_som_runtime import SpecModel, SpecReflection, validate_document

model = SpecModel.from_json(json.loads(meta_json))
reflection = SpecReflection(model)

print(reflection.resolve("SBP/content") is not None)
# True
print(validate_document(model, doc) == [])
# True
```

### Requirements

* Python ≥ 3.9
* PyYAML ≥ 6.0 (the YAML decoder + the encoder's self-verification, mirroring
  Dart's `package:yaml`).

This is the one SOM runtime with an external dependency; the other eight ship
hand-rolled, dependency-free readers.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other
port uses (`SOM §19`):

```bash
python3 tests/conformance_runner.py   # → "OK: N checks passed"
./run_tests.sh                        # conformance + the per-module suites
```

The runner asserts byte-for-byte equality of the YAML and Markdown encodings, the
document round-trips, and the reflection / validation / operations behaviour.

## Architecture

```
        typed path                          generic path
  tom_som_python_v0 facade  ─────▶   SomNode / SomScalar / SomList
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml
  SpecQueryEngine      validate_document   spec_document_markdown
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
| `validate_document` | The instance tier: a filled document's values checked against the model. |
| `spec_document_yaml` | Byte-stable `*.docspecs.yaml` encode/decode. |
| `spec_document_markdown` | DocSpecs-conform Markdown export, parse and round-trip. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SomNode` / `SomScalar` / `SomList` | The editing-facade base types the generated `tom_som_python_v0` classes extend. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──generate_som──▶ tom_som_python_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ depends on
                                                                  ▼
                                                      tom_som_python_runtime  ← this package
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

**This package** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_python_v0](../tom_som_python_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.1.0**, tracking the TomSpecs model version. Covered by 10 test files;
the conformance runner reports **OK: 874 checks passed** and `./run_tests.sh` is
green.
