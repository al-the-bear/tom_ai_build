# `tom_som_dart_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (plan item #14, spec §3.1). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
`lib/`, `meta/`, `schemas/` and `pubspec.yaml`).

Run each from this package directory (`tom_som_dart_v0`):

| Sample | File | Access path | Run |
| ------ | ---- | ----------- | --- |
| **(a)** Typed object-model | [`a_typed_access.dart`](a_typed_access.dart) | The generated typed facade — named getters/setters, nested-section navigation, the typed `SomList` collection. | `dart run example/a_typed_access.dart` |
| **(b)** Generic document | [`b_generic_document.dart`](b_generic_document.dart) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. | `dart run example/b_generic_document.dart` |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.dart`](c_reflection_metadata.dart) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. | `dart run example/c_reflection_metadata.dart` |

All three describe the **same** document shape, illustrating that the typed
facade (a) is a thin, type-safe surface over the exact generic store (b), whose
schema is described by the reflection model (c).
