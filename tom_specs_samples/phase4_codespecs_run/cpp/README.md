# Sample — a Phase 4 CodeSpecs run (C++)

**Teaches:** the first two stages of [the Dart sample](../README.md) — the
starting prompt's quality gate (passing and rejecting) and the extract
generator — on the same specification.
**Phase:** 4 (CodeSpecs) of `tom_specs_project_flow.md`.
**Language:** C++, on `tom_som_cpp_v0` and `tom_som_cpp_runtime`.

The C++ runtime carries the gate (`som::CodeSpecsGate`, checks A1–A5) and the
extract generator, as all nine runtimes do. Stages 3 and 4 are not here: the
authoring agent writes the IR, and the Dart tools map and validate it
(`tomspecs :ir-map`, `tomspecs :codespecs-validate`). The Dart sample shows them.
This port says so where they would be, rather than printing what it did not run.

## Prerequisites

* a C++17 compiler (`c++`; clang++ or g++) and `make`, as `som_toolchains.md` specifies for the C++ plane.
* A checkout of `tom_ai/ai_build`. The C++ runtime and facade, `tom_som_cpp_runtime` and `tom_som_cpp_v0`,
  **ship as source only** — there is no package registry for them, by decision —
  so this sample builds them itself from the checkout: a **vendored-source
  build**. The shared [`../../tool/cpp_sample.mk`](../../tool/cpp_sample.mk) compiles every
  runtime and facade source file with the toolchain's flags; the objects go to
  `tom_specs_samples/target/cpp`, shared by every C++ port, so the generated
  facade (one large source file) compiles once.

## Run it

```bash
make -j4
./build/sample
```

The model, the Solution Blueprint schema and the area catalogue are read from
the checkout, whose path is compiled in as `TOMSPECS_CHECKOUT`:
`tom_som_cpp_v0/meta/spec_model.meta.json`,
`tom_som_cpp_v0/schemas/solution-blueprint/` and
`tom_specs_model/generated-doc/codespecs/codespecs_areas.json` (the Dart package
`tom_specs_model` ships the catalogue with an accessor; the C++ runtime has none).

## What you should see

Variant A passing the gate and producing 27 extracts (3 populated), variant B
rejected with six findings. The text is in this port's own
[`expected_output.txt`](expected_output.txt): the other ports' text with the
runtime named — stages 1 and 2 and variant B are the Dart sample's lines, and
stages 3 and 4 are replaced by the note above. The 54 extract files in
`build/codespecs_extracts/` are byte for byte the ones the Dart sample writes.

## Memory

Ownership is RAII: nothing is freed by hand. A `som::CodeSpecsGate` **borrows**
its model, document, area catalogue and schema, which must outlive it; the
`som::CodeSpecsGateReport` that `run()` returns is a value that **owns** its
findings and its extracts, each extract holding its own copy of its area. The
model is a `std::unique_ptr`; the schema, catalogue and extracts are values. The
one rule to keep is the facade's: a typed root, section or `SomList`
**borrows** the `som::SpecDocument` it was built over, so the document must
**outlive every facade** bound to it. The rules are the runtime headers' own
(`spec_codespecs_gate.hpp`, `spec_codespecs_extract.hpp`, `som_facade.hpp`,
`spec_document.hpp`).

[`tool/validate.sh`](tool/validate.sh) holds the sample to it. It runs
[`../../tool/native_memcheck.sh`](../../tool/native_memcheck.sh), which builds the
sample with AddressSanitizer and UndefinedBehaviorSanitizer and requires a run
with no report and the same output, then runs the plain build under a leak
checker: `leaks --atExit` on macOS (Apple clang's AddressSanitizer has no leak
detection), else valgrind, else LeakSanitizer. The samples driver runs it after
the output comparison; a missing tool is a skip with the reason stated.
