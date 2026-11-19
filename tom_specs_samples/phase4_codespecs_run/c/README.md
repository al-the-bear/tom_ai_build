# Sample — a Phase 4 CodeSpecs run (C)

**Teaches:** the first two stages of [the Dart sample](../README.md) — the
starting prompt's quality gate (passing and rejecting) and the extract
generator — on the same specification.
**Phase:** 4 (CodeSpecs) of `tom_specs_project_flow.md`.
**Language:** C, on `tom_som_c_v0` and `tom_som_c_runtime`.

The C runtime carries the gate (`spec_codespecs_gate_run`, checks A1–A5) and the
extract generator, as all nine runtimes do. Stages 3 and 4 are not here: the
authoring agent writes the IR, and the Dart tools map and validate it
(`tomspecs :ir-map`, `tomspecs :codespecs-validate`). The Dart sample shows them.
This port says so where they would be, rather than printing what it did not run.

## Prerequisites

* a C11 compiler (`cc`; clang or gcc) and `make`, as `som_toolchains.md` specifies for the C plane.
* A checkout of `tom_ai/ai_build`. The C runtime and facade, `tom_som_c_runtime` and `tom_som_c_v0`,
  **ship as source only** — there is no package registry for them, by decision —
  so this sample builds them itself from the checkout: a **vendored-source
  build**. The shared [`../../tool/c_sample.mk`](../../tool/c_sample.mk) compiles every
  runtime and facade source file with the toolchain's flags; the objects go to
  `tom_specs_samples/target/c`, shared by every C port, so the generated
  facade (one large source file) compiles once.

## Run it

```bash
make -j4
./build/sample
```

The model, the Solution Blueprint schema and the area catalogue are read from
the checkout, whose path is compiled in as `TOMSPECS_CHECKOUT`:
`tom_som_c_v0/meta/spec_model.meta.json`,
`tom_som_c_v0/schemas/solution-blueprint/` and
`tom_specs_model/generated-doc/codespecs/codespecs_areas.json` (the Dart package
`tom_specs_model` ships the catalogue with an accessor; the C runtime has none).

## What you should see

Variant A passing the gate and producing 27 extracts (3 populated), variant B
rejected with six findings. The text is in this port's own
[`expected_output.txt`](expected_output.txt): the other ports' text with the
runtime named — stages 1 and 2 and variant B are the Dart sample's lines, and
stages 3 and 4 are replaced by the note above. The 54 extract files in
`build/codespecs_extracts/` are byte for byte the ones the Dart sample writes.

## Memory

A `CodeSpecsGate` (`spec_codespecs_gate_make`) **borrows** its model, document,
area catalogue and schema; they must outlive it. The `CodeSpecsGateReport` that
`spec_codespecs_gate_run` fills **owns** its findings and its extracts and is
released with `spec_codespecs_gate_report_free`; the extracts **borrow** their
areas from the catalogue, so the catalogue (`spec_codespecs_area_catalog_from_json`
→ `spec_codespecs_area_catalog_free`) must outlive the report. Every `char *` the
runtime returns — `spec_codespecs_extract_file_stem`, `_to_yaml`, `_to_markdown`,
and every `char **err` — is **owned by the caller** and freed with `free`. A
`SpecDocument` belongs to whoever initialised it (`spec_document_init` →
`spec_document_free`) and must outlive every facade bound to it; facade values
and `SomList` views own their paths (`*_free`, `som_list_free`), as do the paths
`som_list_add_on` returns. The model is released with `spec_model_free`, the
schema with `docspecs_schema_free`, the parsed catalogue JSON with
`som_json_free`. These rules are the runtime headers' own
(`spec_codespecs_gate.h`, `spec_codespecs_extract.h`, `som_facade.h`,
`spec_document.h`), and `main.c` states them at the top.

[`tool/validate.sh`](tool/validate.sh) holds the sample to it. It runs
[`../../tool/native_memcheck.sh`](../../tool/native_memcheck.sh), which builds the
sample with AddressSanitizer and UndefinedBehaviorSanitizer and requires a run
with no report and the same output, then runs the plain build under a leak
checker: `leaks --atExit` on macOS (Apple clang's AddressSanitizer has no leak
detection), else valgrind, else LeakSanitizer. The samples driver runs it after
the output comparison; a missing tool is a skip with the reason stated.
