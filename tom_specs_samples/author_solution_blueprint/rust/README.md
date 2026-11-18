# Sample — author a Solution Blueprint (Rust)

**Teaches:** the same as [the Dart sample](../README.md) — authoring a TomSpecs
specification end to end through the typed facade: write, serialise both
renditions, round-trip, validate, and read a real diagnostic.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** Rust, on `tom_som_rust_v0` and `tom_som_rust_runtime`.

A port of `../bin/author_solution_blueprint.dart`, step for step.

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

Exactly what the Dart sample prints: its [`expected_output.txt`](../expected_output.txt),
which the samples driver compares this port against too. The two renditions are
written to `build/`, byte for byte the ones the Dart sample writes.

The facade crate ships the model as a file, not as an accessor: the port reads
`tom_som_rust_v0/meta/spec_model.meta.json` from the checkout, found from
`CARGO_MANIFEST_DIR`, so it runs from any working directory.
