# tom_som_c_runtime — documentation

The package documentation for `tom_som_c_runtime`: how to use this package's code. It is
the **generic, reflective** access path — the document as a sparse path-keyed store.

The object model, the file formats, the schema generation and the validator
contract are the **subject-matter tier**, catalogued by
[`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md). Documents
here cite it rather than restating it
(`tom_specs_documentation_standard.md` §1.2).

## Guides

| Document | Covers |
|----------|--------|
| [generic_access.md](generic_access.md) | Driving a document by path, the model as data, and when to prefer this over the typed facade |

## API reference

`doc/api/reference/` holds the generated reference, rendered with `doxygen`.
It is **not committed** — it is output, it is large, and it regenerates:

```bash
cd ../tom_specs_clitool
./tool/regenerate_api_references.sh c_runtime
```

The reasoning, and the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## The other half of this language plane

Each SOM language is a **pair**. This package is the **generic, reflective** access path — the document as a sparse path-keyed store; its counterpart is
[`tom_som_c_v0`](../../tom_som_c_v0), documented in
[`tom_som_c_v0/doc/tutorial.md`](../../tom_som_c_v0/doc/tutorial.md). A consumer
normally installs the facade, which depends on the runtime.

## Beyond this package

| Where | What it decides |
|-------|-----------------|
| [`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md) | The object model, the two access paths, the `*.md` and `*.docspecs.yaml` formats, the validator, and the conformance corpus |
| [`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md) | This language plane's build, test and documentation toolchains |
| [`tom_specs_model_meta_schema.md`](../../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json` |
| [`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md) | The catalogue of the whole subject-matter tier, and the `§` citation convention |
