# `tom_som_cpp_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (plan item #14, spec §3.1). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
the header/source pair (`include/`, `src/`), `meta/`, `schemas/` and the
`Makefile`).

Each sample is a single `.cpp` file. Every sample reaches the generic runtime
purely through the include path (`-I$(RUNTIME_DIR)/include`), wired by the
Makefile's relative `RUNTIME_DIR`, so the samples are portable across checkouts.

## Build & run

From the project root, the runner builds both static libraries and then
compiles + runs the behavioural test and all three samples:

```bash
./run_tests.sh
```

To compile a single sample directly (after `make` and `make -C ../tom_som_cpp_runtime`):

```bash
g++ -std=c++17 -Iinclude -I../tom_som_cpp_runtime/include \
   examples/a_typed_access.cpp \
   build/libtom_som_cpp_v0.a ../tom_som_cpp_runtime/build/libtom_som_cpp_runtime.a \
   -o build/a_typed_access
./build/a_typed_access
```

Sample (c) reads `meta/spec_model.meta.json` relative to the current directory,
so run it from the project root (or pass an explicit path as its first
argument).

| Sample | File | Access path |
| ------ | ---- | ----------- |
| **(a)** Typed object-model | [`a_typed_access.cpp`](a_typed_access.cpp) | The generated typed facade — named accessor member functions, nested-section navigation, the path-based `som::SomList` collection. |
| **(b)** Generic document | [`b_generic_document.cpp`](b_generic_document.cpp) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.cpp`](c_reflection_metadata.cpp) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `som::SpecModel`, enumerate roots/fields, resolve paths to model nodes. |

All three describe the **same** document shape, and produce output equivalent to
their Dart/Python/Java/JavaScript/TypeScript/Go/Rust/C counterparts in
`tom_som_dart_v0/example/`, `tom_som_python_v0/examples/`,
`tom_som_java_v0/examples/`, `tom_som_javascript_v0/examples/`,
`tom_som_typescript_v0/examples/`, `tom_som_go_v0/examples/`,
`tom_som_rust_v0/examples/` and `tom_som_c_v0/examples/` — illustrating that the
typed facade (a) is a thin editing surface over the exact generic store (b),
whose schema is described by the reflection model (c).

## Ownership notes (C++-specific, RAII)

- The `som::SpecDocument` is a **value** (`som::SpecDocument doc;`). It is
  **borrowed** by every facade bound to it (each holds a `SpecDocument&`) and
  must outlive them — declare it before, and in an outer scope to, its facades.
- Facade nodes are **values**: copy/move them freely; there is nothing to free.
- Typed getters return `std::string` **by value**.
- `som::SomList::add()` returns the new item's path; element facades are
  constructed from it (`Elem item(doc, path)`).
- The serialization helpers (`SpecDocument::toJson()` →
  `som::documentJsonToCanonicalJson`, `som::encodeYaml`) return owned values.
- `som::SpecModel::fromJsonStr` returns a `std::unique_ptr<SpecModel>`;
  reflection results borrow from the model, so keep the model alive.
