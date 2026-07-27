# `tom_som_go_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (`som_multiplatform_spec_model.md` §6). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
the module, `meta/`, `schemas/` and `go.mod`).

Each sample is its own `package main` in its own subdirectory (Go allows only
one `main` per directory). Every sample reaches the generic runtime through the
fixed import path `tom_som_go_runtime`, wired by the relative **`replace`**
directive on the runtime in this module's `go.mod`, so the samples are portable
across checkouts.

## Build & run

From the module root:

```bash
go run ./examples/a_typed_access
go run ./examples/b_generic_document
go run ./examples/c_reflection_metadata
```

The samples build, vet and test together with the module:

```bash
go build ./...
go vet ./...
go test ./...
```

| Sample | File | Access path |
| ------ | ---- | ----------- |
| **(a)** Typed object-model | [`a_typed_access/a_typed_access.go`](a_typed_access/a_typed_access.go) | The generated typed facade — named accessors, nested-section navigation, the typed `SomList` collection. |
| **(b)** Generic document | [`b_generic_document/b_generic_document.go`](b_generic_document/b_generic_document.go) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. |
| **(c)** Reflection / meta-data | [`c_reflection_metadata/c_reflection_metadata.go`](c_reflection_metadata/c_reflection_metadata.go) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. |

All three describe the **same** document shape, and produce output equivalent to
their Dart/Python/JavaScript/TypeScript counterparts in `tom_som_dart_v0/example/`,
`tom_som_python_v0/examples/`, `tom_som_javascript_v0/examples/` and
`tom_som_typescript_v0/examples/` — illustrating that the typed facade (a) is a
thin, type-safe surface over the exact generic store (b), whose schema is
described by the reflection model (c).
