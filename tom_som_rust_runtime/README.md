# tom_som_rust_runtime — generic Rust SOM runtime

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

Generic TomSpecs object-model runtime (Rust port). Paths, model, reflection,
document, validator, YAML/Markdown codecs; zero external dependencies (standard
library only).

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this crate) holding everything that is the same
everywhere, and a generated `tom_som_rust_v0` facade holding the typed structs
for one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator; with it, the generator emits only
what actually changes when the model changes.

This crate is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime), and of the Python, Java,
JavaScript, TypeScript and Go ports — it invents nothing, and "faithful" is a
measured claim rather than an intention: every port is validated against the same
goldens, byte for byte (`SOM §19`). Reach for it directly when you drive the
generic API by section path; otherwise depend on the typed facade, which pulls
this in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the crate is a layer over it —
the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated structs, the byte-stable YAML and Markdown codecs, the
editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
structs** — those belong to the per-language `tom_som_<lang>_v0` crates.

## Installation

```toml
[dependencies]
tom_som_rust_runtime = { path = "../tom_som_rust_runtime", version = "1.1.0" }
```

The crate is `publish = false` (proprietary). The version tracks the TomSpecs
**model version**, and `tom_som_rust_v0` pins the same one — upgrade both
together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for the crates.io / git /
path routes, version pinning, and `cargo package` from source.

## Features

### Modules

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.rs` | The section-path grammar (root / child / list-item segments). |
| `spec_model.rs` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.rs` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, node-kind constants). |
| `spec_document.rs` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values.rs` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.rs` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.rs` | Validates a document's values against the model. |
| `spec_text_pattern.rs` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (std ships no regex, and the `regex` crate would be both a dependency this crate does not take and a different grammar). |
| `spec_query.rs` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.rs` | The constrained node-creation gate (`check_add_node`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.rs` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — one verbatim, provenance-carrying extract per CodeSpecs area. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_document_yaml.rs` | Byte-stable `*.docspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.rs` | Meta-data-driven Markdown import/export codec (`SOM §11`). |
| `som_facade.rs` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList<T>`) for the generated `tom_som_rust_v0`. |
| `yaml.rs` | Hand-rolled, dependency-free reader for the constrained docspecs YAML subset. |
| `json.rs` | Hand-rolled, dependency-free JSON reader/encoder (Rust std ships no JSON). |

## Quick start

```rust
use tom_som_rust_runtime as som;

let mut doc = som::SpecDocument::new();
doc.set_content("SBP/content", "A unifying order platform.");
println!("{}", doc.content_or("SBP/content"));
// A unifying order platform.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
structs involved:

```rust
let model = som::SpecModel::from_json_str(&meta_json).unwrap();
let reflection = som::SpecReflection::new(&model);

println!("{}", reflection.resolve("SBP/content").is_some());
// true
println!("{}", som::validate_document(&model, &doc).is_empty());
// true
```

### Zero external dependencies

The crate depends only on the Rust standard library — no `serde`, `serde_json`,
`serde_yaml`, or `regex`. JSON parsing uses the hand-rolled `json` module; YAML
uses the hand-rolled `yaml` module (the constrained docspecs subset). Byte-stable
`*.docspecs.yaml` output requires a `js_json_string` that matches JavaScript's
`JSON.stringify` exactly — it delegates to `json::encode_str`, which emits the
short escapes for `" \ \b \f \n \r \t`, control characters below `0x20` as
lowercase `\u00xx`, and every other char (including `< > & /` and all non-ASCII)
verbatim. The regex-driven Markdown anchors of the reference are replaced by
hand-rolled scanners (`heading_path`, `field_anchor`, `fence_open`, `item_seg`).

### Rust-specific surface

Rust has ownership, `Result`, and reserved keywords, so the facade differs from
the other ports in idiomatic ways the emitter mirrors:

- **Shared document via `Rc<RefCell<SpecDocument>>`** — aliased as `DocRef`. A
  child facade clones the `Rc` (a cheap reference-count bump) and every read or
  write borrows the cell, so a mutation through the typed surface is immediately
  visible through the generic path and vice-versa.
- **No `doc`/`path` name guard** — generated accessors reference the bound
  document explicitly through the embedded `SomNode` (`self.node`), so a method
  named `doc` or `path` cannot shadow anything. This is a deviation from the
  Go/TypeScript ports, which need a reserved-name guard.
- **`Result` instead of exceptions** — the version check returns
  `Result<(), SomVersionError>`; `SomVersionError` implements `std::error::Error`.
- **Reserved-keyword collisions** are resolved by the emitter with a trailing
  underscore (`type_`, `match_`, `self_`, `move_`, …).

### Consumed by `tom_som_rust_v0`

The generated typed model depends on this crate via a relative path dependency in
the `v0` crate's `Cargo.toml`
(`tom_som_rust_runtime = { path = "../tom_som_rust_runtime" }`), keeping the
generated source path-free and golden-stable.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```bash
cargo build                                 # compile the runtime
cargo test                                  # the whole suite
cargo test --test conformance -- --nocapture # → "OK: N checks passed"
./run_tests.sh                              # conformance + the per-module suites
```

The conformance test reproduces every golden byte-for-byte and exercises the same
cases as the Dart/Python/Java/JavaScript/TypeScript/Go runners: model meta-data
load, `state.json` round-trip, YAML encode/decode, Markdown export/round-trip,
the **Markdown→memory landing** check (the `md.land.*` shared contract — parsing
`expected.md` lands the same memory as the YAML route), reflection resolution,
validation, the imperative operations script, and the **Phase-4 CodeSpecs tier**
(the routing diagnostic, the per-area extracts with their YAML/Markdown goldens,
the "copied, never composed" guard and the `ROUTE-TOTAL` error cases).

## Architecture

```
        typed path                          generic path
   tom_som_rust_v0        ─────▶   SomNode / SomScalar / SomList<T>
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml.rs
  SpecQueryEngine      validate_document   spec_document_markdown.rs
        │
        ▼
     SpecModel  ◀── meta/spec_model.meta.json
```

| Type | Responsibility |
| ---- | -------------- |
| `SpecDocument` | The sparse, path-keyed store of a document's content, form and list values. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated structs. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `validate_document` | The instance tier: a filled document's values checked against the model. |
| `spec_document_yaml` | Byte-stable `*.docspecs.yaml` encode/decode. |
| `spec_document_markdown` | DocSpecs-conform Markdown export, parse and round-trip. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SomNode` / `SomScalar` / `SomList<T>` | The editing-facade base types the generated `tom_som_rust_v0` structs embed. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──generate_som──▶ tom_som_rust_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ depends on
                                                                  ▼
                                                     tom_som_rust_runtime  ← this crate
                                                                  │ validated against
                                                                  ▼
                                                         tom_som_conformance
                                                          (shared corpus)
```

## Further documentation

**TomSpecs subject matter** — the authorities this crate implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs subject-matter document, and the `§` citation convention. |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.md` and `*.docspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the reference host. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |

**This crate** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_rust_v0](../tom_som_rust_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.1.0**, tracking the TomSpecs model version. Covered by 8 test files;
the conformance runner reports **OK: 3150 checks passed** and `./run_tests.sh` is
green.
