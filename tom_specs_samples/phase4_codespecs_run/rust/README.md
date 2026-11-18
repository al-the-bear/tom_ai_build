# Sample — a Phase 4 CodeSpecs run (Rust)

**Teaches:** the first two stages of [the Dart sample](../README.md) — the
starting prompt's quality gate (passing and rejecting) and the extract
generator — on the same specification.
**Phase:** 4 (CodeSpecs) of `tom_specs_project_flow.md`.
**Language:** Rust, on `tom_som_rust_v0` and `tom_som_rust_runtime`.

The Rust runtime carries the gate (`CodeSpecsGate`, checks A1–A5) and the
extract generator, as all nine runtimes do. Stages 3 and 4 are not here: the
authoring agent writes the IR, and the Dart tools map and validate it
(`tomspecs :ir-map`, `tomspecs :codespecs-validate`). The Dart sample shows them.
This port says so where they would be, rather than printing what it did not run.

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

The model, the Solution Blueprint schema and the area catalogue are read from
the checkout, found from `CARGO_MANIFEST_DIR`:
`tom_som_rust_v0/meta/spec_model.meta.json`,
`tom_som_rust_v0/schemas/solution-blueprint/` and
`tom_specs_model/generated-doc/codespecs/codespecs_areas.json` (the Dart package
`tom_specs_model` ships the catalogue with an accessor; the Rust runtime has none).

## What you should see

Variant A passing the gate and producing 27 extracts (3 populated), variant B
rejected with six findings. The text is in this port's own
[`expected_output.txt`](expected_output.txt): stages 1 and 2 and variant B are
the Dart sample's lines, and stages 3 and 4 are replaced by the note above.
The 54 extract files in `build/codespecs_extracts/` are byte for byte the ones
the Dart sample writes.
