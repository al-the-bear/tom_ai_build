# Shared SOM sample documents

Language-agnostic sample specification documents in the native
`*.docspecs.yaml` wire format. Every `tom_som_<lang>_v0` example suite loads
these same files, so a fix or extension to a sample benefits all nine languages
at once.

| File | Root | Description |
| ---- | ---- | ----------- |
| `meridian_order_management.docspecs.yaml` | `D00SolutionBlueprint` (SBP) | A genuinely implementable Solution Blueprint for a fictional "Meridian Order Management" programme (~255 populated leaf paths) — 14 typed requirements across four list types (functional / technical / security / organizational), three Cockburn-style use cases with full flows and exception extensions, four actors, a key end-to-end scenario, a coherent four-entity / three-relationship data model, and two fully-detailed screens, plus content across all fifteen top-level SBP sections. Broad enough to exercise the blueprint for access examples and the cross-language golden harness. |
| `meridian_order_management.md` | — | Human-readable markdown rendition of the same document (generated alongside the YAML). |

## Regenerating

The sample is authored through the Dart typed facade (guaranteeing a valid wire
format) and re-emitted by:

```bash
cd ../../tom_som_dart_v0
dart run tool/build_shared_sample.dart
```

The generated YAML stamps `modelVersion: "1.0"` — the real `tom_som_dart_v0`
facade version, derived from the `tom_specs_model` project version (see
`_ai/quests/tom_specs/som_convenience_feature_suggestions.md`, roadmap item 2,
which fixed the earlier placeholder `0.0`).
