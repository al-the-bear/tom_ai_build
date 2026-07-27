# `tom_som_c_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (`som_multiplatform_spec_model.md` §6). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
the header/source pair (`include/`, `src/`), `meta/`, `schemas/` and the
`Makefile`).

Each sample is a single `.c` file. C has no module system, so every sample
reaches the generic runtime purely through the include path
(`-I$(RUNTIME_DIR)/include`), wired by the Makefile's relative `RUNTIME_DIR`, so
the samples are portable across checkouts.

## Build & run

From the project root, the runner builds both static libraries and then
compiles + runs the behavioural test and all three samples:

```bash
./run_tests.sh
```

To compile a single sample directly (after `make` and `make -C ../tom_som_c_runtime`):

```bash
cc -std=c11 -Iinclude -I../tom_som_c_runtime/include \
   examples/a_typed_access.c \
   build/libtom_som_c_v0.a ../tom_som_c_runtime/build/libtom_som_c_runtime.a \
   -o build/a_typed_access
./build/a_typed_access
```

Sample (c) reads `meta/spec_model.meta.json` relative to the current directory,
so run it from the project root (or pass an explicit path as its first
argument).

| Sample | File | Access path |
| ------ | ---- | ----------- |
| **(a)** Typed object-model | [`a_typed_access.c`](a_typed_access.c) | The generated typed facade — named accessor functions, nested-section navigation, the path-based `SomList` collection. |
| **(b)** Generic document | [`b_generic_document.c`](b_generic_document.c) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.c`](c_reflection_metadata.c) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. |

All three describe the **same** document shape, and produce output equivalent to
their Dart/Python/Java/JavaScript/TypeScript/Go/Rust counterparts in
`tom_som_dart_v0/example/`, `tom_som_python_v0/examples/`,
`tom_som_java_v0/examples/`, `tom_som_javascript_v0/examples/`,
`tom_som_typescript_v0/examples/`, `tom_som_go_v0/examples/` and
`tom_som_rust_v0/examples/` — illustrating that the typed facade (a) is a thin
editing surface over the exact generic store (b), whose schema is described by
the reflection model (c).

## Ownership notes (C-specific)

- The `SpecDocument` is a **stack** struct: `spec_document_init(&doc)` /
  `spec_document_free(&doc)`. It is **borrowed** by every facade bound to it and
  must outlive them.
- Typed getters return **owned** `char *` results — the caller frees them.
- `som_list_add` returns an **owned** item path; element facades are constructed
  from it (`<elem>_init(&item, &doc, path)`) and released with `<elem>_free`.
- The serialization helpers (`spec_document_to_json` →
  `document_json_to_canonical_json`, `encode_yaml`) return owned buffers the
  caller frees.
