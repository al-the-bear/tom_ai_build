# TomSpecs CLI Tool API Reference: Index

The public API of `tom_specs_clitool`, one summary per module. Everything is
exported from the single barrel
`package:tom_specs_clitool/tom_specs_clitool.dart`, which the package's own
entry points and tests import.

| Module | Summary | Covers |
|--------|---------|--------|
| Model reading | [api_summary_model_reading.md](api_summary_model_reading.md) | The analyzer-backed reader, the outline writer, the JSON exporter, the static validator, the version stamps and the freshness fingerprint |
| Generation | [api_summary_generation.md](api_summary_generation.md) | The config block, the metadata tree, the schema and ops generators, and the per-language packaging renderers |
| Gates | [api_summary_gates.md](api_summary_gates.md) | The three citation gates and the release-set closure walker |
| CodeSpecs | [api_summary_codespecs.md](api_summary_codespecs.md) | The Phase-4 trio reader, the resolved model, the thirty-seven checks and the area catalogue |

**The nine per-language emitter triples are not summarised individually.** Each
language contributes a `Som<Lang>Generator` / `Som<Lang>Emitter` /
`Som<Lang>MetaEmitter`, all with the same three-method shape and all driven from
the metadata tree — so nine near-identical summaries would say one thing nine
times. Their common contract is in the Generation summary; what each emits is
[`som_multiplatform_spec_model.md`](../../../tom_specs_model/doc/som_multiplatform_spec_model.md)
§5.2.

For task-oriented guides rather than reference tables, see the
[documentation index](../index.md).
