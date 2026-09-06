# tom_specs_core — documentation

The package documentation for `tom_specs_core`: how to use this package's code.
The TomSpecs methodology, the object-model rules and the file formats are the
**subject-matter tier**, catalogued by
[`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md); documents
here cite it rather than restating it
([`tom_specs_documentation_standard.md`](../../tom_specs_model/doc/tom_specs_documentation_standard.md)
§1.2).

## Guides

| Document | Covers |
|----------|--------|
| [annotations.md](annotations.md) | The annotation vocabulary, organised by authoring task: giving a section an identity, declaring what it holds, constraining a value, discriminated subsection groups, traceability, artifact routing, and serialization order |
| [sections.md](sections.md) | `DocSpecsSection` and the ten content-typed leaves: the content/form split, choosing a leaf type, and the CodeSpecs back-links |

## API reference

| Document | Covers |
|----------|--------|
| [api/api_summary_index.md](api/api_summary_index.md) | The index of the per-module API summaries |
| [api/api_summary_annotations.md](api/api_summary_annotations.md) | Every annotation class, its constructor, its properties and its target |
| [api/api_summary_sections.md](api/api_summary_sections.md) | Every section class, its hierarchy and its properties |

## Where to start

- **Authoring a model class?** Start with [annotations.md](annotations.md), then
  [sections.md](sections.md) for the member types.
- **Reading a generated document?** The section types are what a parsed document
  lands in — [sections.md](sections.md).
- **Adding an annotation to this package?** Read
  [annotations.md § Error Handling](annotations.md#error-handling) first: an
  annotation with no declared destination in `tom_specs_clitool` fails a test.

## Beyond this package

| Where | What it decides |
|-------|-----------------|
| [`tom_specs_model_rules.md`](../../tom_specs_model/doc/tom_specs_model_rules.md) | When a member must carry which annotation, and the structural invariants the validator enforces |
| [`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md) | How an annotated model becomes nine language runtimes, and how every construct serializes |
| [`codespecs_mapping.md`](../../tom_specs_model/doc/codespecs_mapping.md) | The parts catalogue behind `CodeSpecPart`, and the three routing verdicts |
| [`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md) | The catalogue of the whole subject-matter tier, and the `§` citation convention |
