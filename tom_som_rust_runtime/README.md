# tom_som_rust_runtime

Rust port of the **generic TomSpecs object-model runtime** — the value-free,
generated-code-free half of the multi-platform spec model (`tom_som`). It is a
faithful transcription of the Dart reference, `tom_som_dart_runtime`, and the
Python/Java/JavaScript/TypeScript/Go ports.

## How to use

```toml
[dependencies]
tom_som_rust_runtime = { path = "../tom_som_rust_runtime", version = "1.0.0" }
```

```rust
use tom_som_rust_runtime as som;

let mut doc = som::SpecDocument::new();
doc.set_content("SBP/content", "A unifying order platform.");
println!("{}", doc.content_or("SBP/content"));
```

The crate is `publish = false` (proprietary), versioned to the TomSpecs **model
version** — the same version the typed facade `tom_som_rust_v0` reports. Most
projects depend on the **typed facade** `tom_som_rust_v0` (which depends on this
runtime by a relative `path`) rather than on the runtime directly — reach for the
runtime alone only when you drive the generic API by section path. For the full
set of dependency routes (crates.io / git / path), version pinning, and
`cargo package` from source, see
[readme_howtointegrate.md](readme_howtointegrate.md).

## What it is

The crate `tom_som_rust_runtime` mirrors the eight portable runtime modules,
plus a hand-rolled JSON reader that the Rust standard library does not provide:

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
| `spec_document_yaml.rs` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown.rs` | Meta-data-driven Markdown import/export codec. |
| `som_facade.rs` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList<T>`) for the generated `tom_som_rust_v0`. |
| `yaml.rs` | Hand-rolled, dependency-free reader for the constrained docspecs YAML subset. |
| `json.rs` | Hand-rolled, dependency-free JSON reader/encoder (Rust std ships no JSON). |

It holds **no document values of its own** and contains **no generated typed
structs** — those belong to the per-language `tom_som_<lang>_v0` crates.

## Zero external dependencies

The crate depends only on the Rust standard library — no `serde`, `serde_json`,
`serde_yaml`, or `regex`. JSON parsing uses the hand-rolled `json` module; YAML
uses the hand-rolled `yaml` module (the constrained docspecs subset). Byte-stable
`*.docspecs.yaml` output requires a `js_json_string` that matches JavaScript's
`JSON.stringify` exactly — it delegates to `json::encode_str`, which emits the
short escapes for `" \ \b \f \n \r \t`, control characters below `0x20` as
lowercase `\u00xx`, and every other char (including `< > & /` and all non-ASCII)
verbatim. The regex-driven Markdown anchors of the reference are replaced by
hand-rolled scanners (`heading_path`, `field_anchor`, `fence_open`, `item_seg`).

## Rust-specific surface

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

## Build + conformance

Correctness is defined by the shared, language-agnostic conformance corpus in
`../tom_som_conformance/corpus`, generated from the Dart reference. The Rust port
is validated against the exact same goldens every other port uses:

```bash
cargo build           # compile the runtime
cargo test            # → "OK: N checks passed"
```

The conformance test reproduces every golden byte-for-byte and exercises the same
cases as the Dart/Python/Java/JavaScript/TypeScript/Go runners: model meta-data
load, `state.json` round-trip, YAML encode/decode, Markdown export/round-trip,
the **Markdown→memory landing** check (the `md.land.*` shared contract — parsing
`expected.md` lands the same memory as the YAML route), reflection resolution,
validation, and the imperative operations script.

## Consumed by `tom_som_rust_v0`

The generated typed model depends on this crate via a relative path dependency in
the `v0` crate's `Cargo.toml`
(`tom_som_rust_runtime = { path = "../tom_som_rust_runtime" }`), keeping the
generated source path-free and golden-stable.
