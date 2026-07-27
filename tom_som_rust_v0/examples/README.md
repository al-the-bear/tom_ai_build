# `tom_som_rust_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (`som_multiplatform_spec_model.md` §6). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
the crate root `src/lib.rs`, `meta/`, `schemas/` and `Cargo.toml`).

Each sample is a single-file Cargo example under `examples/`. Every sample
reaches the generic runtime through the fixed crate name `tom_som_rust_runtime`,
wired by the relative **`path`** dependency on the runtime in this crate's
`Cargo.toml`, so the samples are portable across checkouts.

## Build & run

From the crate root:

```bash
cargo run --example a_typed_access
cargo run --example b_generic_document
cargo run --example c_reflection_metadata
```

The samples build and test together with the crate:

```bash
cargo build --examples
cargo test
```

| Sample | File | Access path |
| ------ | ---- | ----------- |
| **(a)** Typed object-model | [`a_typed_access.rs`](a_typed_access.rs) | The generated typed facade — named accessors, nested-section navigation, the typed `SomList` collection. |
| **(b)** Generic document | [`b_generic_document.rs`](b_generic_document.rs) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.rs`](c_reflection_metadata.rs) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. |

All three describe the **same** document shape, and produce output equivalent to
their Dart/Python/JavaScript/TypeScript/Go counterparts in
`tom_som_dart_v0/example/`, `tom_som_python_v0/examples/`,
`tom_som_javascript_v0/examples/`, `tom_som_typescript_v0/examples/` and
`tom_som_go_v0/examples/` — illustrating that the typed facade (a) is a thin,
type-safe surface over the exact generic store (b), whose schema is described by
the reflection model (c).
