# `tom_som_python_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (`som_multiplatform_spec_model.md` §6). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
the module, `meta/`, `schemas/` and `pyproject.toml`).

Each sample bootstraps `sys.path` from the `runtime-path` recorded in
`pyproject.toml`, so it runs against the stock interpreter with no install.
Run each from this package directory (`tom_som_python_v0`):

| Sample | File | Access path | Run |
| ------ | ---- | ----------- | --- |
| **(a)** Typed object-model | [`a_typed_access.py`](a_typed_access.py) | The generated typed facade — named properties, nested-section navigation, the typed `SomList` collection. | `python3 examples/a_typed_access.py` |
| **(b)** Generic document | [`b_generic_document.py`](b_generic_document.py) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. | `python3 examples/b_generic_document.py` |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.py`](c_reflection_metadata.py) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. | `python3 examples/c_reflection_metadata.py` |

All three describe the **same** document shape, and produce output identical to
their Dart counterparts in `tom_som_dart_v0/example/` — illustrating that the
typed facade (a) is a thin, type-safe surface over the exact generic store (b),
whose schema is described by the reflection model (c).
