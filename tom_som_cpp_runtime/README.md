# tom_som_cpp_runtime — generic C++ SOM runtime

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

Generic TomSpecs object-model runtime (C++). Paths, model, reflection, document,
validator, YAML/Markdown codecs, in idiomatic C++17 with RAII; zero external
dependencies (C++ standard library only).

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this library) holding everything that is the same
everywhere, and a generated `tom_som_cpp_v0` facade holding the typed classes for
one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator; with it, the generator emits only
what actually changes when the model changes.

This library is a faithful transcription of the **C** reference,
[`tom_som_c_runtime`](../tom_som_c_runtime), which itself ports the Dart
reference and the Python/Java/JavaScript/TypeScript/Go/Rust ports — it invents
nothing, and "faithful" is a measured claim rather than an intention: every port
is validated against the same goldens, byte for byte (`SOM §19`). Reach for it
directly when you drive the generic API by section path; otherwise link the typed
facade, which links this in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the library is a layer over it —
the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated classes, the byte-stable YAML and Markdown codecs, the
editing and validation tiers, and the Phase-4 CodeSpecs extractor.

Where the C port shipped its own growable buffer / list / byte-sorted map, this
port uses `std::string`, `std::vector`, and `std::map<std::string, …>` (which
iterates in byte order for `std::string` keys, matching the C `SomMap`'s `strcmp`
ordering — the byte-stable codecs rely on it).

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` projects.
`include/tom_som_cpp_runtime.hpp` is the umbrella header; the per-module headers
may also be included directly.

## Installation

C++ has no universal package registry, so the library is distributed as a
library + headers + pkg-config file, or as a source tarball:

```sh
make install PREFIX=/usr/local   # headers, static/shared libs, and the .pc file
make dist                        # build/tom_som_cpp_runtime-<version>.tar.gz
```

`make install` honours `DESTDIR` for staged / packaged installs and lays down the
versioned `.so` soname symlinks. The pkg-config `Version` tracks the TomSpecs
**model version**, and `tom_som_cpp_v0` pins the same one — upgrade both together
(`SOM §4.2`). See [readme_howtointegrate.md](readme_howtointegrate.md) for the
pkg-config / vendored-tarball / in-tree-monorepo routes and how to pin.

## Features

### Modules

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.cpp` | The section-path grammar (root / child / list-item segments). |
| `spec_model.cpp` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.cpp` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, node-kind constants). |
| `spec_document.cpp` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values.cpp` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.cpp` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.cpp` | Validates a document's values against the model. |
| `spec_text_pattern.cpp` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (`std::regex` is a different grammar with locale-sensitive folding). |
| `spec_query.cpp` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.cpp` | The constrained node-creation gate (`checkAddNode`, `SpecNodeCreator::add`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.cpp` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`, `CodeSpecsExtract`) — routes annotated nodes to areas and emits the byte-stable per-area YAML/Markdown extracts. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_document_yaml.cpp` | Byte-stable `*.docspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.cpp` | Meta-data-driven Markdown import/export codec (`SOM §11`). |
| `som_facade.cpp` | Editing-facade base types (`SomNode`, `SomList`, `joinPath`, `checkSomModelVersion`) for the generated `tom_som_cpp_v0`. |
| `yaml.cpp` | Hand-rolled, dependency-free reader for the constrained docspecs YAML subset. |
| `som_json.cpp` | Hand-rolled, dependency-free JSON reader/encoder. |
| `som_util.cpp` | Small numeric/string helpers. |

## Quick start

```cpp
#include "tom_som_cpp_runtime.hpp"

SpecDocument doc;
doc.setContent("SBP/content", "A unifying order platform.");
std::cout << doc.content("SBP/content") << '\n';
// A unifying order platform.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
classes involved:

```cpp
std::string err;
auto model = SpecModel::fromJsonStr(metaJson, err);
SpecReflection reflection(*model);

std::cout << reflection.resolve("SBP/content").has_value() << '\n';
// 1
std::cout << validateDocument(*model, doc).empty() << '\n';
// 1
```

### Zero external dependencies

The library depends only on the C++ standard library. JSON parsing uses the
hand-rolled `som_json` module; YAML uses the hand-rolled `yaml` module (the
constrained docspecs subset). Byte-stable `*.docspecs.yaml` output requires a
quoting helper that matches JavaScript's `JSON.stringify` exactly — it delegates
to `jsonEncodeStr`.

### Idiomatic-C++ surface

The C port was an accessor-function API over plain structs with manual
ownership; this port is RAII classes and value semantics:

- **`SpecDocument`** owns its three sparse byte-sorted stores; accessors return
  `std::string` / `const std::string*` (the latter distinguishes unset from
  empty, replacing the C `NULL`-returning accessors).
- **`SpecResolution`** is a value struct holding borrowed `const` pointers into
  the model (`root` / `field` / `targetClass`); `resolve()` returns
  `std::optional<SpecResolution>`.
- **`SomNode`** holds a borrowed `SpecDocument&` plus an owned path; the document
  must outlive every facade bound to it. **`SomList`** is a path-based view over
  a list field. **`checkSomModelVersion`** throws `SomVersionError` on rejection.
- **`validateDocument`** returns `std::vector<SpecValidationError>`;
  **`markdownParse`** returns a `SpecMarkdownResult` value.
- **The YAML decoder drops the `review:` pass** — the runtime is review-agnostic
  and nothing in the conformance contract reads it.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```sh
make                 # builds the static + shared library + pkg-config file
make test            # builds + runs the conformance harness → "OK: N checks passed"
make unittest        # builds + runs the standalone unit tests
./run_conformance.sh # same as `make test`, via the wrapper script
./run_tests.sh       # conformance + the per-module suites
```

`make` produces `build/libtom_som_cpp_runtime.a` (static),
`build/libtom_som_cpp_runtime.so` (shared), and `build/tom_som_cpp_runtime.pc`
(pkg-config metadata whose `Version` tracks the TomSpecs model version).

The conformance harness (`tests/conformance.cpp`) reproduces the same checks as
every other port — model meta, `state.json` round-trip, YAML encode/decode,
Markdown export/parse/landing, reflection, validation, the imperative operations
script, and the Phase-4 CodeSpecs extract tier (routing verdicts, the per-area
extracts and their YAML/Markdown goldens, `ROUTE-TOTAL` refusals). Exit 0 == all
green. The corpus directory can be overridden:

```sh
make test CORPUS=/path/to/corpus
./run_conformance.sh /path/to/corpus
```

## Architecture

```
        typed path                          generic path
    tom_som_cpp_v0        ─────▶   SomNode / SomScalar / SomList
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml.cpp
  SpecQueryEngine      validateDocument    spec_document_markdown.cpp
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
| `SomNode` / `SomList` | The editing-facade base types the generated `tom_som_cpp_v0` classes extend. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──generate_som──▶ tom_som_cpp_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ links
                                                                  ▼
                                                      tom_som_cpp_runtime  ← this library
                                                                  │ validated against
                                                                  ▼
                                                         tom_som_conformance
                                                          (shared corpus)
```

## Further documentation

**TomSpecs subject matter** — the authorities this library implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs subject-matter document, and the `§` citation convention. |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.md` and `*.docspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the reference host. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |

**This library** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_cpp_v0](../tom_som_cpp_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_c_runtime](../tom_som_c_runtime) | The C reference this port transcribes. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference the whole plane transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.1.0**, tracking the TomSpecs model version. Requires a C++17
compiler. Covered by 10 test files; the conformance runner reports
**OK: 1924 checks passed** and `./run_tests.sh` is green.
