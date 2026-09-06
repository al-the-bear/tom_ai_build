# TomSpecs Model API Reference: Index

The public API of `tom_specs_model`, one summary per module. Everything is
exported from the single barrel `package:tom_specs_model/tom_specs_model.dart`.

| Module | Summary | Covers |
|--------|---------|--------|
| Document roots | [api_summary_document_roots.md](api_summary_document_roots.md) | `DocSpecsProject` and the fourteen `@Document` entry points |
| `common` | [api_summary_common.md](api_summary_common.md) | `DocumentHeader`, the authorization-requirement model, and the shared enums |
| `snapshot` | [api_summary_snapshot.md](api_summary_snapshot.md) | `SpecNode`, `SpecClassOps`, `SpecRegistry`, `SpecSlot`, `SpecSnapshotter` |
| `serialization` | [api_summary_serialization.md](api_summary_serialization.md) | `SpecProjection`, `SpecYaml`, `connectProjection` |

**The ~3000 per-section classes are deliberately not summarised here.** They are
catalogued by the generated outlines under
[`generated-doc/outlines/`](../../generated-doc/outlines), one per document
root, regenerated from the model by
`tom_specs_clitool/tool/regenerate_outlines.sh`. A second hand-kept catalogue
would be a second thing to keep current, and it would be the one that drifts.

For task-oriented guides rather than reference tables, see the
[package documentation index](../package/index.md).
