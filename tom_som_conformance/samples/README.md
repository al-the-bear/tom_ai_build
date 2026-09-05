# Shared SOM sample documents

Language-agnostic sample specification documents in the native
`*.docspecs.yaml` wire format. Every `tom_som_<lang>_v0` example suite loads
these same files, so a fix or extension to a sample benefits all nine languages
at once.

| File | Root | Description |
| ---- | ---- | ----------- |
| `meridian_order_management.docspecs.yaml` | `D00SolutionBlueprint` (SBP) | A genuinely implementable Solution Blueprint for a fictional "Meridian Order Management" programme (~261 populated leaf paths) — 14 typed requirements across four list types (functional / technical / security / organizational), three Cockburn-style use cases with full flows and exception extensions, four actors, a key end-to-end scenario, the server calls made by the two step kinds that reach across the client/server boundary (all three `ServerCallRole` values on one use-case step, a single role on one scenario step), a coherent four-entity / three-relationship data model, two fully-detailed screens, and the registries those screens refer into (11 message keys, 2 roles over 3 entitlements, 3 bounded contexts, 2 routes), plus multi-line markdown content across all fifteen top-level SBP sections. Broad enough to exercise the blueprint for access examples and the cross-language golden harness. |
| `meridian_order_management.md` | — | DocSpecs markdown rendition of the same document (generated alongside the YAML). |
| `uam_access_hub.docspecs.yaml` | `D00SolutionBlueprint` (SBP) | Hand-authored Solution Blueprint for **"Tom Access Hub" (TAH)**, a multi-tenant, multi-application authorization application managing organizations and applications within a tenant. Grounded in the `tom_uam` DDL (`um_clients` / `um_users` / `um_organizations` / `um_applications` / `um_roles` / `um_role_resource_grants` / `tom_principal_delegation`) and deliberately more complex than what that DDL covers today: graded resource grants with overlay semantics, delegation with approval workflow and validity windows, and periodic access-review campaigns. Instantiates model regions the Meridian sample does not reach (security/organizational requirement details, entity constraints and keys, relationships, domain enums, error-code registry, result envelope, service operations with authorization requirements, screen states/actions/transitions, accessibility statement, quality characteristics). |
| `exercise_full_model.docspecs.yaml` | `D00SolutionBlueprint` (SBP) | **Generated exercise specification — placeholder prose by design.** Emitted by `../tool/build_exercise_sample.dart`; its sole purpose is to instantiate *every* model structure reachable from the SBP root (every list structure and every section id), driving `../tool/sample_coverage_manifest.yaml` to empty. Decodes through the typed loader, but is not a narrative document and is deliberately outside the golden harness. Regenerate after model changes and commit the diff. |
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

## Gates over the samples

Two gates hold every `*.docspecs.yaml` file here, and both run first in
`../tool/run_all_suites.sh`:

- **decode** (`tom_som_dart_v0/tool/verify_samples.dart`) — every sample must
  decode through the typed one-call loader against the SBP metadata tree
  (SOM §12), so a sample that only *looks* structurally plausible fails with
  the offending key and path named;
- **instantiation coverage** (`../tool/check_sample_coverage.dart`, SOM §19) —
  the samples together must instantiate every reachable list structure and
  section id not recorded in `../tool/sample_coverage_manifest.yaml`. The
  manifest is empty: the samples cover the full model, and coverage only
  ratchets forward.

New samples count toward coverage the moment they land (the gate globs
`samples/*.docspecs.yaml`); joining the nine-language golden harness is a
separate, optional step per sample — only the Meridian pair is referenced by
the golden generators.

The build tool additionally gates the **Meridian** sample on **both** validation
tiers and fails on any violation from either, so that committed sample always
validates cleanly:

- the emitted **markdown** against the generated schema
  (`tom_som_dart_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml`)
  via the embedded DocSpecs validator API (SOM §14) — *completeness*;
- the **document** through `validateDocument` (SOM §9) — *values*: field kinds,
  form keys, list minima, and `refersTo` resolution.

The two tiers ask disjoint questions, so neither result implies the other. A
document whose every required field is filled can still name a message key, a
role or a route that nothing declares, and a document that resolves every
reference it makes can still be missing a required field outright. Gating on one
alone leaves the other class of defect in a sample that nine languages read as
their worked example.

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

The Meridian sample is authored through the Dart typed facade (guaranteeing a
valid wire format) and re-emitted by:

```bash
cd ../../tom_som_dart_v0
dart run tool/build_shared_sample.dart
```

The exercise sample is regenerated (after model changes) by:

```bash
cd ..            # tom_som_conformance
dart tool/build_exercise_sample.dart
```

The UAM access-hub sample is hand-authored — extend it by hand and let the
decode gate verify the result.

List-item section ids are normalized to the deterministic anonymous 1-based
form (`FRE-REQU-1`, …) rather than the date-derived generated ids, so
regeneration is byte-stable regardless of the build date and the ids satisfy
the schema's `pattern-check-id` rules.

The generated YAML stamps `modelVersion: "1.0"` — the real `tom_som_dart_v0`
facade version. The facade derives it from the model's own version stamp rather
than from the `_vN` project-naming suffix, so the sample carries the version it
will actually be read back at. See "Convenience and correctness features" in
`tom_specs_model/doc/som_multiplatform_spec_model.md`.
