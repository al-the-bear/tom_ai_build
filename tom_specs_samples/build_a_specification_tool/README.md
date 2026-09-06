# Sample — building a tool on a specification

For the reader who is **not authoring specifications but writing programs that
read them**: an editor, a linter, a report, an importer, a migration.

```bash
dart pub get
dart run
```

Two dependencies — `tom_som_dart_runtime` and `tom_som_dart_v0` — and nothing
else. The recorded output is `expected_output.txt`;
`../tool/run_all_samples.sh` diffs the two, so this sample is a gate and not a
demo.

## Read this before you write any code

**There are three validation tiers. They ask different questions, and a tool
that wants one and calls another gets nothing useful — not an error, just an
empty list that reads like a pass.** This is the single distinction tooling
authors miss, so it comes before anything else here.

| Tier | Checks | Where it lives | When it runs |
|------|--------|----------------|--------------|
| **Static** | the **model's own annotations** — field-type rules, `@ContentType` compatibility, cycles, the `tom_specs_model_rules.md` §10.2 structural invariants | `tom_specs_clitool/lib/src/validator.dart` | **once, at generation time** |
| **Instance** | a **document's values** against the model | each runtime's `validateDocument` (SOM §9) | whenever you ask |
| **Document** | a **markdown rendition** against the generated schema | `DocSpecsValidator` (SOM §14) | whenever you ask |

The static tier is **deliberately not part of the nine-language runtime
surface**, and it is not reachable from this sample. That is the point: by the
time a document exists, that tier has already run — it validated the model the
document is written against. A tool asking "is this model well-formed?" at
runtime is asking a question that was settled before it started.

The two runtime tiers are both available, and **neither implies the other**:

- `validateDocument` is **not** a completeness check. A required field that was
  never written holds no value, so there is nothing invalid to report.
- The schema validator does not follow a reference it sees filled — a
  populated field pointing into an empty registry passes it.

The sample shows this concretely rather than asserting it: its fixture is clean
on the instance tier and carries one violation on the document tier, and a
deliberately broken copy of the same document does the reverse.

## What the run covers

| § | | |
|---|---|---|
| 0 | | The document being inspected |
| 1 | **Reflection** | What the model *can* hold: the two version stamps, the snapshot check, roots and fields, a form's slots, the annotations the meta carries into all nine languages, path resolution |
| 2 | **Generic access** | What a document *does* hold, with no compile-time knowledge of its shape — and where paths come from, since a tool must never hard-code one |
| 3 | **The schema** | Where the generated schema comes from, and what it is |
| 4 | **Validation** | The tiers above, run for real |
| 5 | **A tool** | A completeness report built on all four |

### The two version stamps

`spec_model.meta.json` carries both, and they answer different questions:

- `metaSchemaVersion` — the **file format** the snapshot itself is written in.
  A tool reads this to decide whether it can parse the file at all.
- `modelVersion` — **which model** the snapshot describes. A tool reads this to
  decide whether the documents it holds are the ones this model describes.

`modelVersionLabel` (e.g. `1.1.0+5.a15517b3`) is a build label for humans.
Never branch on it.

`SpecModel.checkStamp()` adds the third question: is this snapshot still
current? It compares the class and root counts the exporter **declared**
against what actually **survived to the reader** — not redundant, because a
truncated file is exactly where the two part — and ages the snapshot out after
a fortnight.

### The tool, and why it is not redundant

Step 5 builds a **completeness report**: per top-level section, how many content
positions the model offers and how many the document has written.

Neither validator can report this. The schema names what is **required and
missing**; an optional section left blank is perfectly valid and no validator
will ever mention it. But *"which parts of this specification has nobody
written yet?"* is the question a specification author actually has. In this
sample the two numbers are **1** required-and-missing field against **5 411**
unwritten positions, and that gap is the tool's reason to exist.

Two decisions in it worth copying:

- **A list counts as one position, not as its items.** An empty list offers
  exactly one thing to write — the first item — and a list with forty items has
  not made the document forty times more complete. Counting items would build a
  report that rewards padding.
- **The walk names no class and no field.** It is driven entirely by
  `SpecReflection`, so it runs unchanged against any of the fourteen document
  roots and survives a model change that adds sections.

## The facade's own examples

The individual APIs are demonstrated one at a time in `tom_som_dart_v0`'s
`example/`, and this sample links them rather than restating them:

| Example | Shows | Runs from a hosted install? |
|---------|-------|------------------------------|
| `b_generic_document.dart` | generic read/write over string paths | yes |
| `c_reflection_metadata.dart` | the reflection surface | yes |
| `d_`, `e_`, `f_sample_*.dart` | typed / generic / hybrid access to a real document | **no** |

The last three load `meridian_order_management.docspecs.yaml` from
`tom_som_conformance`, which is **not published** — so from a hosted install
their input does not exist. `f_sample_hybrid_access.dart` is still worth
*reading* for its header, which states the two safe ways to obtain a path
better than step 2 of this sample does. Tracked as
`tsdocb14_aiga-shipped-tool-scripts-resolve-into-an-unpublished-package`.

That is also why this sample **authors its own fixture** in
`_authorFixture`, deliberately small and deliberately incomplete: incompleteness
is step 5's whole subject, and small means every number the run prints can be
checked by reading one function.

## Files

| Path | |
|------|--|
| `bin/build_a_specification_tool.dart` | The run, and `specificationCoverage` — the tool itself |
| `expected_output.txt` | What `dart run` prints; the samples driver diffs it |

## Reading on

| Document | For |
|----------|-----|
| `tom_specs_model/doc/som_multiplatform_spec_model.md` | The SOM authority: the metadata tree, the runtime classes, serialization, schema generation, the embedded validator |
| `tom_specs_model/doc/tom_specs_model_meta_schema.md` | The on-disk schema of `spec_model.meta.json`, its two version stamps, and the `validateSpecModelMeta` contract |
| `tom_specs_model/doc/tom_specs_model_rules.md` | The model-authoring authority — including `tom_specs_model_rules.md` §10.2's structural invariants, which are what the static tier checks |
| `_ai/quests/doc_specs/doc_specs_specification.md` | The DocSpecs format the document tier validates against |
