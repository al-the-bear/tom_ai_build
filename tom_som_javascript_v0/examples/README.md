# `tom_som_javascript_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (`som_multiplatform_spec_model.md` §6). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
the module, `meta/`, `schemas/` and `package.json`).

Each sample locates the generic runtime through the `tomSom.runtimePath`
recorded in `package.json`, so it runs against stock `node` (≥ 18) with no
install. Run each from this package directory (`tom_som_javascript_v0`):

| Sample | File | Access path | Run |
| ------ | ---- | ----------- | --- |
| **(a)** Typed object-model | [`a_typed_access.js`](a_typed_access.js) | The generated typed facade — named accessors, nested-section navigation, the typed `SomList` collection. | `node examples/a_typed_access.js` |
| **(b)** Generic document | [`b_generic_document.js`](b_generic_document.js) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. | `node examples/b_generic_document.js` |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.js`](c_reflection_metadata.js) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. | `node examples/c_reflection_metadata.js` |

All three describe the **same** document shape, and produce output equivalent
to their Dart/Python counterparts in `tom_som_dart_v0/example/` and
`tom_som_python_v0/examples/` — illustrating that the typed facade (a) is a
thin, type-safe surface over the exact generic store (b), whose schema is
described by the reflection model (c).
