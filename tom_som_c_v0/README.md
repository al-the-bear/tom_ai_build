# tom_som_c_v0

C port of the **generated typed editing facade** for the TomSpecs Spec Object
Model (`tom_som`) — the per-language `*_v0` half that sits on top of the generic,
value-free `tom_som_c_runtime`. It is the C counterpart of `tom_som_dart_v0`,
`tom_som_python_v0`, `tom_som_java_v0`, `tom_som_javascript_v0`,
`tom_som_typescript_v0`, `tom_som_go_v0` and `tom_som_rust_v0`.

## What it is

C has no object system, generics, `Result` or exceptions, so the "typed facade"
is an **accessor-function API** over the generic runtime structs rather than a
set of language objects. For every model class the generator emits:

- a typedef `typedef struct { SomNode node; } <Class>;` — a thin handle that
  borrows a `SpecDocument` and owns its section `path`;
- named accessor functions (`<class>_<field>` getters, `<class>_set_<field>`
  setters for content/scalar/enum leaves, `<class>_<field>` navigators that
  return a nested facade or a path-based `SomList`);
- for the document roots, a constructor
  `int <root>_new(<Root> *self, SpecDocument *doc, const char *document_version, char **err)`
  that also runs the §2.2 instantiation-time version check, plus a
  `#define <ROOT>_MODEL_VERSION "<v>"` and a `<root>_object_model_version`
  accessor;
- enum tokens as `#define <ENUM>_<VALUE> "<wire>"` plus a `parse_<enum>`
  validator.

Because C has a single flat function namespace, **every** emitted function name
is globally unique (deduped with a `_<n>` suffix where collisions would occur).

| Path | Contents |
| ---- | -------- |
| `include/tom_som_c_v0.h` | **Generated** umbrella header — typedefs, enum/version `#define`s, function declarations. |
| `src/tom_som_c_v0.c` | **Generated** implementation. |
| `meta/spec_model.meta.json` | **Generated** lossless class graph (consumed by the reflection sample). |
| `schemas/` | **Generated** per-root `*.docspecs.schema.json`. |
| `Makefile` | **Generated** — builds `build/libtom_som_c_v0.a` against the runtime. |
| `tests/generated_test.c` | **Hand-authored** behavioural test (typed ↔ generic parity, version check). |
| `examples/` | **Hand-authored** runnable samples — see `examples/README.md`. |
| `run_tests.sh` | **Hand-authored** runner: builds the libs, then compiles + runs the test and all samples. |

The header/source pair, `meta/`, `schemas/` and the `Makefile` are rewritten on
every `generate_som` run; everything else is preserved.

## Build & run

The library and the hand-authored test/samples reach the generic runtime purely
through the include path (`-I$(RUNTIME_DIR)/include`), wired by the Makefile's
relative `RUNTIME_DIR` (default `../tom_som_c_runtime`).

```bash
make            # builds build/libtom_som_c_v0.a
./run_tests.sh  # builds both libs, then runs the behavioural test + 3 samples
```

`run_tests.sh` exits 0 when everything is green; the behavioural test prints
`OK: N checks passed`. Override the runtime location with
`RUNTIME_DIR=/path/to/tom_som_c_runtime ./run_tests.sh`.

## Regeneration

This tree is produced by `tom_specs_clitool`:

```bash
dart run bin/generate_som.dart --languages=c
```

The generator only rewrites the generated artifacts listed above; the
hand-authored test, samples and this README survive regeneration.
