# Sample — build a specification tool (Rust)

**Teaches:** the same as [the Dart sample](../README.md) — reflective access to
the model, generic access to a document, the generated schema, the validation
tiers, and a completeness report built on all of it.
**Phase:** any — tooling.
**Language:** Rust, on `tom_som_rust_v0` and `tom_som_rust_runtime`.

A port of `../bin/build_a_specification_tool.dart`, over the same fixture.

## Prerequisites

* Rust 1.70 or later with Cargo (`cargo --version`).
* A checkout of `tom_ai/ai_build`. The Rust crates, `tom_som_rust_runtime` and
  `tom_som_rust_v0`, are **not on crates.io** (the non-Dart runtimes are not
  published; both crates keep `publish = false`), so `Cargo.toml` takes both as
  `path` dependencies on the checkout (`../../../tom_som_rust_runtime`,
  `../../../tom_som_rust_v0`). Neither has dependencies of its own, so nothing
  is downloaded.

## Run it

```bash
cargo run
```

The first build compiles the generated facade crate, about 22 MB of source:
roughly a minute and 4–5 GB of memory. Every Rust port of the samples shares one
target directory, `tom_specs_samples/target/rust` (set in `.cargo/config.toml`),
so that happens once, not once per port.

## What you should see

Five numbered sections; every number is the Dart sample's. The text is in this
port's own [`expected_output.txt`](expected_output.txt), because it differs from
the Dart sample's:

* where the Dart text names a Dart-only surface, as in the other ports: the
  fixture function is `authorFixture`, the annotation display semantics
  (`kRenderedAnnotations`) are the Dart runtime's, and the Dart text points at a
  Dart example;
* where it names an API, the Rust name stands (`check_stamp`,
  `validate_document`, `d00_solution_blueprint_meta(&tree)…path()`, `by_id`,
  `by_path`);
* Rust has no enum for the two closed verdict sets: they are the runtime's lists
  of string constants, `SPEC_VALIDATION_ALL_CODES` and `DOCSPECS_ALL_RULES`.

`generatedAt` is printed as the snapshot writes it (`SpecModel::generated_at`
holds epoch seconds; std has no date type). `check_stamp` takes its age
threshold as an argument; the port passes 30 days, the other runtimes' default.
The facade crate ships the model as a file, not as an accessor: the port reads
`tom_som_rust_v0/meta/spec_model.meta.json` from the checkout, found from
`CARGO_MANIFEST_DIR`, so it runs from any working directory. The schema is read
the same way, from `tom_som_rust_v0/schemas/solution-blueprint/`.
