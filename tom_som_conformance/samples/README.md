# Shared SOM sample documents

Language-agnostic sample specification documents in the native
`*.docspecs.yaml` wire format. Every `tom_som_<lang>_v0` example suite loads
these same files, so a fix or extension to a sample benefits all nine languages
at once.

| File | Root | Description |
| ---- | ---- | ----------- |
| `meridian_order_management.docspecs.yaml` | `D00SolutionBlueprint` (SBP) | A genuinely implementable Solution Blueprint for a fictional "Meridian Order Management" programme (~255 populated leaf paths) — 14 typed requirements across four list types (functional / technical / security / organizational), three Cockburn-style use cases with full flows and exception extensions, four actors, a key end-to-end scenario, a coherent four-entity / three-relationship data model, and two fully-detailed screens, plus multi-line markdown content across all fifteen top-level SBP sections. Broad enough to exercise the blueprint for access examples and the cross-language golden harness. |
| `meridian_order_management.md` | — | DocSpecs markdown rendition of the same document (generated alongside the YAML). |

## Formats

- **`*.docspecs.yaml`** — the **hierarchical v2** wire format (DR5): a single
  document-root key (`SBP D00SolutionBlueprint`) holding the nested section
  tree; `version: 2`, `modelVersion: "1.0"`. Loaded with the one-call loaders
  (`D00SolutionBlueprint.loadFile(path)` typed, or
  `SpecDocument.fromFile(path, tree)` generic).
- **`*.md`** — the **DocSpecs markdown** format (DR6): every populated section
  is a heading carrying its section id as a headline comment
  (`## <!--[INSC]--> …`); narrative content is real multi-line markdown,
  `@Form` sections are `FieldName: value` blocks, list items are numbered
  sub-headings (`FRE-REQU-1`, …).

The build tool validates the emitted markdown against the DR3-generated schema
(`tom_som_dart_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml`)
via the embedded DR7 validator API and fails on any violation, so the committed
sample always validates cleanly.

## Regenerating

The sample is authored through the Dart typed facade (guaranteeing a valid wire
format) and re-emitted by:

```bash
cd ../../tom_som_dart_v0
dart run tool/build_shared_sample.dart
```

List-item section ids are normalized to the deterministic anonymous 1-based
form (`FRE-REQU-1`, …) rather than the date-derived generated ids, so
regeneration is byte-stable regardless of the build date and the ids satisfy
the schema's `pattern-check-id` rules.

The generated YAML stamps `modelVersion: "1.0"` — the real `tom_som_dart_v0`
facade version. The facade derives it from the model's own version stamp rather
than from the `_vN` project-naming suffix, so the sample carries the version it
will actually be read back at. See "Convenience and correctness features" in
`tom_specs_model/doc/som_multiplatform_spec_model.md`.
