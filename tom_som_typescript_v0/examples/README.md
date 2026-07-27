# `tom_som_typescript_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (`som_multiplatform_spec_model.md` §6). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
the module, `meta/`, `schemas/`, `package.json` and `tsconfig.json`).

Unlike the JavaScript samples (which locate the runtime at run time through a
recorded path), TypeScript is statically compiled, so each sample imports the
generic runtime through the fixed bare specifier `tom_som_typescript_runtime`.
That specifier is wired by the relative **`file:` dependency** on the runtime in
this package's `package.json`, so the samples are portable across checkouts.

## Build & run

The samples are part of this package's `tsconfig.json` (`include` covers
`examples/**/*.ts`), so they build together with the module and tests:

```bash
npm install      # links the runtime via the file: dependency
npm run build    # tsc → dist/
node dist/examples/a_typed_access.js
node dist/examples/b_generic_document.js
node dist/examples/c_reflection_metadata.js
```

| Sample | File | Access path |
| ------ | ---- | ----------- |
| **(a)** Typed object-model | [`a_typed_access.ts`](a_typed_access.ts) | The generated typed facade — named accessors, nested-section navigation, the typed `SomList` collection. |
| **(b)** Generic document | [`b_generic_document.ts`](b_generic_document.ts) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.ts`](c_reflection_metadata.ts) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. |

All three describe the **same** document shape, and produce output equivalent to
their Dart/Python/JavaScript counterparts in `tom_som_dart_v0/example/`,
`tom_som_python_v0/examples/` and `tom_som_javascript_v0/examples/` —
illustrating that the typed facade (a) is a thin, type-safe surface over the
exact generic store (b), whose schema is described by the reflection model (c).
