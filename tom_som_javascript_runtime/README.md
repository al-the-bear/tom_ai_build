# tom_som_javascript_runtime — generic JavaScript SOM runtime

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

JavaScript port of the generic TomSpecs object-model runtime (paths, model,
reflection, document, validator, YAML/Markdown codecs). Zero external
dependencies (Node built-ins only).

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this package) holding everything that is the same
everywhere, and a generated `tom_som_javascript_v0` facade holding the typed
classes for one model version. Without the split, every regeneration would
rewrite the document store, the codecs and the validator; with it, the generator
emits only what actually changes when the model changes.

This package is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime), and of the Python and Java
ports — it invents nothing, and "faithful" is a measured claim rather than an
intention: every port is validated against the same goldens, byte for byte
(`SOM §19`). Reach for it directly when you drive the generic API by section
path; otherwise install the typed facade, which pulls this in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the package is a layer over it
— the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated classes, the byte-stable YAML and Markdown codecs,
the editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages. The
public API is re-exported from `tom_som_runtime/index.js`.

## Installation

```bash
npm install tom_som_javascript_runtime
```

The version tracks the TomSpecs **model version**, and `tom_som_javascript_v0`
pins the same one — upgrade both together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for every dependency route
and how to pin.

## Features

### Modules

| Module | Responsibility |
| ------ | -------------- |
| `spec_paths.js` | The section-path grammar (root / child / list-item segments). |
| `spec_model.js` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.js` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, `SpecNodeKind`). |
| `spec_document.js` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values.js` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.js` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.js` | Validates a document's values against the model. |
| `spec_text_pattern.js` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (`RegExp` is the ECMAScript grammar, which accepts far more than the subset and would let a pattern that only works here into the corpus). |
| `spec_query.js` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.js` | The constrained node-creation gate (`checkAddNode`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.js` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — per area, every value `@CodeSpecKind` routes there, verbatim and with provenance. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_document_yaml.js` | Byte-stable `*.docspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.js` | DocSpecs-conform Markdown import/export codec (`SOM §11`). |
| `docspecs_validator.js` | Schema-free DocSpecs parse, schema loader, and never-fail-fast validator (`SOM §14`). |
| `som_facade.js` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList`) for the generated `tom_som_javascript_v0`. |

## Quick start

```javascript
const { SpecDocument } = require('tom_som_javascript_runtime');

// A sparse document keyed by section path.
const doc = new SpecDocument();
doc.setContent('SBP/content', 'A unifying order platform.');
console.log(doc.content('SBP/content'));
// A unifying order platform.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
classes involved:

```javascript
const {
  SpecModel,
  SpecReflection,
  validateDocument,
} = require('tom_som_javascript_runtime');

const model = SpecModel.fromJson(JSON.parse(metaJson));
const reflection = new SpecReflection(model);

console.log(reflection.resolve('SBP/content') !== null);
// true
console.log(validateDocument(model, doc).length === 0);
// true
```

Typically you drive the runtime through the generated typed facade rather than
by raw section paths.

### Zero external dependencies

The build host carries only Node.js — no npm packages (no js-yaml). JSON parsing
uses the native `JSON.parse`/`JSON.stringify`; YAML uses a **hand-rolled,
dependency-free** parser (`yaml.js`, the constrained docspecs subset, ported from
the Java runtime's `Yaml.java`).

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```bash
node tests/conformance_runner.js   # → "OK: N checks passed"
./run_conformance.sh               # the same, via the wrapper
node --test                        # the thin node:test wrapper
./run_tests.sh                     # conformance + the per-module suites
```

The runner asserts byte-for-byte equality of the YAML and Markdown encodings, the
document round-trips, the Markdown→memory landing, and the reflection /
validation / operations behaviour (exit 0 on success). The conformance suite is a
plain-Node `main()` (`tests/conformance_runner.js`), with a thin `node --test`
wrapper (`tests/conformance.test.js`).

## Architecture

```
        typed path                          generic path
  tom_som_javascript_v0     ─────▶   SomNode / SomScalar / SomList
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml.js
  SpecQueryEngine      validateDocument    spec_document_markdown.js
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
| `SomNode` / `SomScalar` / `SomList` | The editing-facade base types the generated `tom_som_javascript_v0` classes extend. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──generate_som──▶ tom_som_javascript_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ depends on
                                                                  ▼
                                                  tom_som_javascript_runtime  ← this package
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
| [tom_som_javascript_v0](../tom_som_javascript_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.1.0**, tracking the TomSpecs model version. Requires Node.js ≥ 18
(verified with Node 22.x). Covered by 10 test files; the conformance runner
reports **OK: 896 checks passed** and `./run_tests.sh` is green.
