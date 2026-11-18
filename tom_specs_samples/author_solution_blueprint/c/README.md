# Sample — author a Solution Blueprint (C)

**Teaches:** the same as [the Dart sample](../README.md) — authoring a TomSpecs
specification end to end through the typed facade: write, serialise both
renditions, round-trip, validate, and read a real diagnostic.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** C, on `tom_som_c_v0` and `tom_som_c_runtime`.

A port of `../bin/author_solution_blueprint.dart`, step for step.

## Prerequisites

* a C11 compiler (`cc`; clang or gcc) and `make`, as `som_toolchains.md` specifies for the C plane.
* A checkout of `tom_ai/ai_build`. The C runtime and facade, `tom_som_c_runtime` and `tom_som_c_v0`,
  **ship as source only** — there is no package registry for them, by decision —
  so this sample builds them itself from the checkout: a **vendored-source
  build**, which is the intended way to integrate the C runtime into a
  program. The shared [`../../tool/c_sample.mk`](../../tool/c_sample.mk) compiles every
  runtime and facade source file with the toolchain's flags; the objects go to
  `tom_specs_samples/target/c`, shared by every C port, so the generated
  facade (one large source file) compiles once.

## Run it

```bash
make -j4
./build/sample
```

The program reads the files it needs (the model, and for some samples the
schema) from the checkout; the path is compiled in as `TOMSPECS_CHECKOUT`.

## What you should see

Exactly what the Dart sample prints: its [`expected_output.txt`](../expected_output.txt),
which the samples driver compares this port against too. The two renditions are
written to `build/`, byte for byte the ones the Dart sample writes.

## Memory

Every `char *` the runtime returns is **owned by the caller** and freed with
`free`; every `const char *` is **borrowed** — `som_node_path` while its node
lives, `spec_document_content` and `som_list_item_path_at` until the document is
next mutated. A `SpecDocument` belongs to whoever initialised it
(`spec_document_init` → `spec_document_free`; one from `spec_document_from_yaml`
or a `*_load_file` is heap-allocated and also needs `free`), and it must
**outlive every facade** bound to it: facades and `SomList` views borrow it.
Facade values and lists own their paths (`*_free`, `som_list_free`); a model is
released with `spec_model_free`, a schema with `docspecs_schema_free`, string
lists with `som_strlist_free`, and the error and violation lists with their own
`*_free`. The reflection lookups borrow from the model and live as long as it.
These rules are the runtime headers' own (`som_facade.h`, `spec_document.h`,
`spec_validator.h`, `spec_reflection.h`), and `main.c` states the ones it uses
at the top.

[`tool/validate.sh`](tool/validate.sh) holds the sample to it. It runs
[`../../tool/native_memcheck.sh`](../../tool/native_memcheck.sh), which builds the
sample with AddressSanitizer and UndefinedBehaviorSanitizer and requires a run
with no report and the same output, then runs the plain build under a leak
checker: `leaks --atExit` on macOS (Apple clang's AddressSanitizer has no leak
detection), else valgrind, else LeakSanitizer. The samples driver runs it after
the output comparison; a missing tool is a skip with the reason stated.
