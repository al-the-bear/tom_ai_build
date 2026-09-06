# tom_som_conformance — documentation

The package documentation for `tom_som_conformance`: how to **run** the harness
and read its output. What the corpus proves, how far the parity claim reaches,
and what a SOM runtime must satisfy are the **subject-matter tier**, owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md)
§19 and catalogued by
[`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md). Documents
here cite it rather than restating it
(`tom_specs_documentation_standard.md` §1.2).

## Guides

| Document | Covers |
|----------|--------|
| [running_the_harness.md](running_the_harness.md) | The two claims and the drivers that prove them, the corpus layout, **reading a golden mismatch**, reading a suite failure, why a skip is not a pass, and proving a corpus table is load-bearing |

## API reference

**Not applicable.** This package ships no library: it is a corpus, a set of
shared samples, and the drivers that replay them. Its `tool/` scripts are
documented in the guide above; there is no importable public API to summarise
(`tom_specs_documentation_standard.md` §8 asks that a line which does not apply
be noted rather than silently skipped).

## Where to start

- **Verifying a change to a SOM runtime?** Run the suites first, then the golden
  proof — see
  [running_the_harness.md § Quick Start](running_the_harness.md#quick-start).
- **Got a `MISMATCH`?**
  [running_the_harness.md § Reading a golden mismatch](running_the_harness.md#reading-a-golden-mismatch).
  Read the byte counts before the diff: equal sizes mean a value differs,
  different sizes mean structure does.
- **A suite skipped and you expected it to run?**
  [running_the_harness.md § Skips are not passes](running_the_harness.md#skips-are-not-passes).
  On a `cargo` skip, the driver already prepends `~/.cargo/bin`.
- **Adding a corpus table?** Prove every runner reads it —
  [running_the_harness.md § Proving a corpus table is load-bearing](running_the_harness.md#proving-a-corpus-table-is-load-bearing).

## Generated output

`generated-doc/` holds generator output and is **never hand-edited**; `golden/`
holds the per-language logs the golden generators write and is not committed.
Both come back by re-running their producer.

## Beyond this package

| Where | What it decides |
|-------|-----------------|
| [`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the formats, and the conformance corpus this package is |
| [`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md) | The per-language build and verify toolchains the drivers invoke |
| [`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md) | The catalogue of the whole subject-matter tier, and the `§` citation convention |
