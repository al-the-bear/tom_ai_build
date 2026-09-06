# tom_specs_clitool — documentation

The package documentation for `tom_specs_clitool`: how to **run** its command
surface. The subjects those commands serve — the object model, the generator
config, the metadata schema, the per-language toolchains, the outliner's
rendering rules — are the **subject-matter tier**, catalogued by
[`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md). Documents
here cite it rather than restating it
(`tom_specs_documentation_standard.md` §1.2).

## Guides

| Document | Covers |
|----------|--------|
| [generating.md](generating.md) | The canonical `generate_som.dart` run and its five phases, reading its output, stamping serialization order (and the two numbers that do not mean what they look like), the ad-hoc entry points, and the freshness stamp |
| [inspecting_the_model.md](inspecting_the_model.md) | The outliner, the JSON exporter and the summary builder: running them, **reading an outline's notation**, and refreshing the two committed assets |
| [gates.md](gates.md) | The three citation gates, the release-closure walker and the CodeSpecs validator: running each, **reading a citation failure**, and why the scan sets are closed |

## API reference

| Document | Covers |
|----------|--------|
| [api/api_summary_index.md](api/api_summary_index.md) | The index of the per-module API summaries |
| [api/api_summary_model_reading.md](api/api_summary_model_reading.md) | The reader, the outline writer, the exporter, the validator, the stamps |
| [api/api_summary_generation.md](api/api_summary_generation.md) | The config, the metadata tree, the schema and ops generators, the packaging |
| [api/api_summary_gates.md](api/api_summary_gates.md) | The citation gates and the release-closure walker |
| [api/api_summary_codespecs.md](api/api_summary_codespecs.md) | The Phase-4 reader, model, checks and area catalogue |

## Where to start

- **Edited the model?**
  [generating.md § Quick Start](generating.md#quick-start) — stamp, regenerate,
  re-outline, and commit the stamp with the packages.
- **A test says the model surface is stale?**
  [generating.md § The freshness stamp](generating.md#the-freshness-stamp). The
  fingerprint covers the model *source*, so the fix is to regenerate.
- **A citation gate went red?**
  [gates.md § Reading a citation failure](gates.md#reading-a-citation-failure).
  Nearly always a cross-document `§` that lost its document name.
- **Documented a new package and want it gated?**
  [gates.md § Scan sets are closed](gates.md#scan-sets-are-closed). Until it is
  in the default set, run it through with `--extra` — and check the file count.

## Development documentation

`_copilot_guidelines/` holds this package's **development** documentation and is
not part of the tier above:

| Document | Covers |
|----------|--------|
| [`_copilot_guidelines/index.md`](../_copilot_guidelines/index.md) | The catalogue of this package's development guidelines |
| [`_copilot_guidelines/som_regeneration.md`](../_copilot_guidelines/som_regeneration.md) | The regeneration discipline the freshness stamp enforces, and why it is mechanical rather than remembered |

## Beyond this package

| Where | What it decides |
|-------|-----------------|
| [`som_generator_config.md`](../../tom_specs_model/doc/som_generator_config.md) | The `tom-spec-object-model` config block this tool reads |
| [`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md) | What the generator must emit, per language |
| [`tom_specs_model_rules.md`](../../tom_specs_model/doc/tom_specs_model_rules.md) | The model-authoring rules the validator enforces, and — in `tom_specs_model_rules.md` §11 — the outliner's rendering rules |
| [`tom_specs_model_meta_schema.md`](../../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of the exported class graph |
| [`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md) | The per-language build and verify toolchains, and regenerating after an SDK change |
| [`codespecs_derivation_contract.md`](../../tom_specs_model/doc/codespecs_derivation_contract.md) | The thirty-seven checks `validate_codespecs.dart` runs |
| [`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md) | The catalogue of the whole subject-matter tier, and the `§` citation convention |
