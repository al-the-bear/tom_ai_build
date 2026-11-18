# Sample — build a specification tool (C++)

**Teaches:** the same as [the Dart sample](../README.md) — reflective access to
the model, generic access to a document, the generated schema, the validation
tiers, and a completeness report built on all of it.
**Phase:** any — tooling.
**Language:** C++, on `tom_som_cpp_v0` and `tom_som_cpp_runtime`.

A port of `../bin/build_a_specification_tool.dart`, step for step.

## Prerequisites

* a C++17 compiler (`c++`; clang++ or g++) and `make`, as `som_toolchains.md` specifies for the C++ plane.
* A checkout of `tom_ai/ai_build`. The C++ runtime and facade, `tom_som_cpp_runtime` and `tom_som_cpp_v0`,
  **ship as source only** — there is no package registry for them, by decision —
  so this sample builds them itself from the checkout: a **vendored-source
  build**, which is the intended way to integrate the C++ runtime into a
  program. The shared [`../../tool/cpp_sample.mk`](../../tool/cpp_sample.mk) compiles every
  runtime and facade source file with the toolchain's flags; the objects go to
  `tom_specs_samples/target/cpp`, shared by every C++ port, so the generated
  facade (one large source file) compiles once.

## Run it

```bash
make -j4
./build/sample
```

The program reads the files it needs (the model, and for some samples the
schema) from the checkout; the path is compiled in as `TOMSPECS_CHECKOUT`.

## What you should see

Five numbered sections; every number is the Dart sample's. The text is in this
port's own [`expected_output.txt`](expected_output.txt), because it differs from
the Dart sample's:

* where the Dart text names a Dart-only surface, as in the other ports: the
  annotation display semantics (`kRenderedAnnotations`) are the Dart runtime's,
  and the Dart text points at a Dart example;
* where it names an API, the C++ name stands (`checkStamp`, `validateDocument`, `tree.byId`, `tree.byPath`, the
  navigation functions);
* C++ has no enum for the two closed verdict sets: they are the runtime's
  lists of string constants, `kSpecValidationAllCodes` and `kDocSpecsAllRules`.

`generatedAt` is printed as the snapshot writes it (the model holds epoch
seconds). The stamp check takes its age threshold as an argument; the port
passes 30 days, the other runtimes' default.

## Memory

Ownership is RAII: the runtime returns values (`std::string`, `std::vector`,
`std::optional`) and the model as a `std::unique_ptr`, so nothing is freed by
hand. The one rule to keep is the facade's: a typed root, section or `SomList`
**borrows** the `som::SpecDocument` it was built over, and `loadFile` fills a
document the caller owns — so the document must **outlive every facade** bound
to it. Reflection lookups return pointers and references that borrow from the
model and live as long as it. The rules are the runtime headers' own
(`som_facade.hpp`, `spec_document.hpp`, `spec_reflection.hpp`).

[`tool/validate.sh`](tool/validate.sh) holds the sample to it. It runs
[`../../tool/native_memcheck.sh`](../../tool/native_memcheck.sh), which builds the
sample with AddressSanitizer and UndefinedBehaviorSanitizer and requires a run
with no report and the same output, then runs the plain build under a leak
checker: `leaks --atExit` on macOS (Apple clang's AddressSanitizer has no leak
detection), else valgrind, else LeakSanitizer. The samples driver runs it after
the output comparison; a missing tool is a skip with the reason stated.
