# tom_som_cpp_runtime

Idiomatic-C++ (C++17, RAII) port of the **generic TomSpecs object-model
runtime** — the value-free, generated-code-free half of the multi-platform spec
model (`tom_som`). It is a faithful transcription of the C reference
(`tom_som_c_runtime`), which itself ports the Dart reference and the
Python/Java/JavaScript/TypeScript/Go/Rust ports.

## What it is

The static library `libtom_som_cpp_runtime.a` mirrors the portable runtime
modules, plus the hand-rolled JSON/YAML readers. Where the C port shipped its
own growable buffer / list / byte-sorted map, this port uses `std::string`,
`std::vector`, and `std::map<std::string, …>` (which iterates in byte order for
`std::string` keys, matching the C `SomMap`'s `strcmp` ordering — the byte-stable
codecs rely on it).

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.cpp` | The section-path grammar (root / child / list-item segments). |
| `spec_model.cpp` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.cpp` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, node-kind constants). |
| `spec_document.cpp` | A sparse in-memory document — values keyed by section path. |
| `spec_validator.cpp` | Validates a document's values against the model. |
| `spec_document_yaml.cpp` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown.cpp` | Meta-data-driven Markdown import/export codec (§4.1 DocScanner route). |
| `som_facade.cpp` | Editing-facade base types (`SomNode`, `SomList`, `joinPath`, `checkSomModelVersion`) for the generated `tom_som_cpp_v0`. |
| `yaml.cpp` | Hand-rolled, dependency-free reader for the constrained docspecs YAML subset. |
| `som_json.cpp` | Hand-rolled, dependency-free JSON reader/encoder. |
| `som_util.cpp` | Small numeric/string helpers. |

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` projects.

`include/tom_som_cpp_runtime.hpp` is the umbrella header; the per-module headers
may also be included directly.

## Zero external dependencies

The library depends only on the C++ standard library. JSON parsing uses the
hand-rolled `som_json` module; YAML uses the hand-rolled `yaml` module (the
constrained docspecs subset). Byte-stable `*.docspecs.yaml` output requires a
quoting helper that matches JavaScript's `JSON.stringify` exactly — it delegates
to `jsonEncodeStr`.

## Idiomatic-C++ surface

The C port was an accessor-function API over plain structs with manual
ownership; this port is RAII classes and value semantics:

- **`SpecDocument`** owns its three sparse byte-sorted stores; accessors return
  `std::string` / `const std::string*` (the latter distinguishes unset from
  empty, replacing the C `NULL`-returning accessors).
- **`SpecResolution`** is a value struct holding borrowed `const` pointers into
  the model (`root` / `field` / `targetClass`); `resolve()` returns
  `std::optional<SpecResolution>`.
- **`SomNode`** holds a borrowed `SpecDocument&` plus an owned path; the document
  must outlive every facade bound to it. **`SomList`** is a path-based view over
  a list field. **`checkSomModelVersion`** throws `SomVersionError` on rejection.
- **`validateDocument`** returns `std::vector<SpecValidationError>`;
  **`markdownParse`** returns a `SpecMarkdownResult` value.
- **The YAML decoder drops the `review:` pass** — the runtime is review-agnostic
  and nothing in the conformance contract reads it.

## Building & testing

```sh
make                 # builds build/libtom_som_cpp_runtime.a
make test            # builds + runs the conformance harness against the corpus
./run_conformance.sh # same, via the wrapper script
```

The conformance harness (`tests/conformance.cpp`) loads the language-agnostic
corpus (`../tom_som_conformance/corpus`) and reproduces the same checks as every
other port — model meta, `state.json` round-trip, YAML encode/decode, Markdown
export/parse/landing, reflection, validation, and the imperative operations
script. Exit 0 == all green; it prints `OK: 95 checks passed`.

The corpus directory can be overridden:

```sh
make test CORPUS=/path/to/corpus
./run_conformance.sh /path/to/corpus
```
