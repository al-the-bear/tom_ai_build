# `tom_som_dart_v0` — runnable samples

Runnable samples covering the access paths to a TomSpecs Spec Object Model
document (plan item #14, spec §3.1). They are **hand-authored** and preserved
across `generate_som` regeneration (the generator only rewrites `lib/`, `meta/`,
`schemas/` and `pubspec.yaml`).

Run each from this package directory (`tom_som_dart_v0`):

## Building-block samples (self-contained)

| Sample | File | Access path | Run |
| ------ | ---- | ----------- | --- |
| **(a)** Typed object-model | [`a_typed_access.dart`](a_typed_access.dart) | The generated typed facade — named getters/setters, nested-section navigation, the typed `SomList` collection. | `dart run example/a_typed_access.dart` |
| **(b)** Generic document | [`b_generic_document.dart`](b_generic_document.dart) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. | `dart run example/b_generic_document.dart` |
| **(c)** Reflection / meta-data | [`c_reflection_metadata.dart`](c_reflection_metadata.dart) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. | `dart run example/c_reflection_metadata.dart` |

All three describe the **same** document shape, illustrating that the typed
facade (a) is a thin, type-safe surface over the exact generic store (b), whose
schema is described by the reflection model (c).

## Shared-sample samples (load a real, broad document)

Samples (d) and (e) both load the **shared, language-agnostic** sample
`../../tom_som_conformance/samples/meridian_order_management.docspecs.yaml` — a
broad Solution Blueprint for a fictional order-management programme, authored by
[`tool/build_shared_sample.dart`](../tool/build_shared_sample.dart) and reused by
every language's SOM examples. They read the same key sections two ways and print
**identical** output.

| Sample | File | Access path | Run |
| ------ | ---- | ----------- | --- |
| **(d)** Sample via typed API | [`d_sample_typed_access.dart`](d_sample_typed_access.dart) | Loads the shared sample and reads key sections through the concrete `D00SolutionBlueprint` facade. | `dart run example/d_sample_typed_access.dart` |
| **(e)** Sample via generic API | [`e_sample_generic_access.dart`](e_sample_generic_access.dart) | Reads the same shared sample through the generic `SpecDocument` string-path API only — no dependency on the generated facade. | `dart run example/e_sample_generic_access.dart` |

An evaluation of how convenient these two access paths are in practice — and
concrete suggestions for closing the friction — lives in
[`tom_specs_clitool/doc/som_convenience_feature_suggestions.md`](../../tom_specs_clitool/doc/som_convenience_feature_suggestions.md).
