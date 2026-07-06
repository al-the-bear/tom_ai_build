# Shared SOM sample documents

Language-agnostic sample specification documents in the native
`*.docspecs.yaml` wire format. Every `tom_som_<lang>_v0` example suite loads
these same files, so a fix or extension to a sample benefits all nine languages
at once.

| File | Root | Description |
| ---- | ---- | ----------- |
| `meridian_order_management.docspecs.yaml` | `D00SolutionBlueprint` (SBP) | A broad Solution Blueprint for a fictional "Meridian Order Management" programme — content across all fifteen top-level SBP sections, one nested section (goals), and a four-element operational-metrics list. Intended to exercise most of the blueprint's breadth for access examples. |
| `meridian_order_management.md` | — | Human-readable markdown rendition of the same document (generated alongside the YAML). |

## Regenerating

The sample is authored through the Dart typed facade (guaranteeing a valid wire
format) and re-emitted by:

```bash
cd ../../tom_som_dart_v0
dart run tool/build_shared_sample.dart
```

The generated YAML stamps `modelVersion: "0.0"` to match the current
`tom_som_dart_v0` facade version (see
`tom_specs_clitool/doc/som_convenience_feature_suggestions.md` §3 for why this
is `0.0` rather than the model meta-data's `1.0`).
