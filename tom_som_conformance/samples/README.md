# Shared SOM sample documents

Language-agnostic sample specification documents in the native
`*.docspecs.yaml` wire format. Every `tom_som_<lang>_v0` example suite loads
these same files, so a fix or extension to a sample benefits all nine languages
at once.

| File | Root | Description |
| ---- | ---- | ----------- |
| `meridian_order_management.docspecs.yaml` | `D00SolutionBlueprint` (SBP) | A genuinely implementable Solution Blueprint for a fictional "Meridian Order Management" programme (~255 populated leaf paths) — 14 typed requirements across four list types (functional / technical / security / organizational), three Cockburn-style use cases with full flows and exception extensions, four actors, a key end-to-end scenario, a coherent four-entity / three-relationship data model, and two fully-detailed screens, plus multi-line markdown content across all fifteen top-level SBP sections. Broad enough to exercise the blueprint for access examples and the cross-language golden harness. |
| `meridian_order_management.md` | — | DocSpecs markdown rendition of the same document (generated alongside the YAML). |
| `invalid_demo_document.md` | — | **Invalid on purpose — do not repair.** A small hand-authored document written against `../corpus/docspecs_schema.yaml` (the demo schema, not the generated SBP one) that breaks each of the eleven `DocSpecsViolationRule` spellings exactly once. |

## Formats

- **`*.docspecs.yaml`** — the **hierarchical v2** wire format (SOM §12): a single
  document-root key (`SBP D00SolutionBlueprint`) holding the nested section
  tree; `version: 2`, `modelVersion: "1.0"`. Loaded with the one-call loaders
  (`D00SolutionBlueprint.loadFile(path)` typed, or
  `SpecDocument.fromFile(path, tree)` generic).
- **`*.md`** — the **DocSpecs markdown** format (SOM §11): every populated section
  is a heading carrying its section id as a headline comment
  (`## <!--[INSC]--> …`); narrative content is real multi-line markdown,
  `@Form` sections are `FieldName: value` blocks, list items are numbered
  sub-headings (`FRE-REQU-1`, …).

The build tool validates the emitted markdown against the generated schema
(`tom_som_dart_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml`)
via the embedded validator API (SOM §14) and fails on any violation, so the committed
sample always validates cleanly.

## The invalid companion fixture

Validating cleanly is exactly what makes the Meridian sample unable to check the
validator's *output*: it can only ever report zero violations, so the golden
harness's per-violation `DV` line never executed and a per-language defect in it
was invisible. `invalid_demo_document.md` is the counterweight — a hand-authored
document that violates each of the eleven rules once, so the nine golden logs
carry a non-empty violation list whose rule spellings are byte-compared.

- **It is invalid on purpose. Do not "fix" it.** Repairing a section removes a
  rule from cross-language comparison.
- It is **not** produced by `build_shared_sample.dart`, which generates and gates
  only the two Meridian files — so the clean-validation gate above does not apply
  to it.
- It validates against **`../corpus/docspecs_schema.yaml`**, the hand-authored
  demo schema, not the generated SBP schema. That is forced, not preference: the
  SBP schema declares no `pattern-check:` and no `text-required:`, so
  `fieldPatternMismatch` and `textRequired` are unreachable against it whatever
  the document says.
- Each of the nine golden generators **asserts** that the fixture reaches every
  spelling in its rule vocabulary and aborts otherwise, so a rule added later
  without a matching fixture section fails loudly rather than going unexercised.
  Adding a rule therefore means adding a section here in the same change.

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
