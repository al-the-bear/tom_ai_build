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
| `spec_typed_values.cpp` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.cpp` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.cpp` | Validates a document's values against the model. |
| `spec_text_pattern.cpp` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (`std::regex` is a different grammar with locale-sensitive folding). |
| `spec_query.cpp` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.cpp` | The constrained node-creation gate (`checkAddNode`, `SpecNodeCreator::add`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.cpp` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`, `CodeSpecsExtract`) — routes annotated nodes to areas and emits the byte-stable per-area YAML/Markdown extracts. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_document_yaml.cpp` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown.cpp` | Meta-data-driven Markdown import/export codec (SOM §8 DocScanner route). |
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
make                 # builds the static + shared library + pkg-config file
make test            # builds + runs the conformance harness against the corpus
make unittest        # builds + runs the standalone unit tests
./run_conformance.sh # same as `make test`, via the wrapper script
```

`make` produces `build/libtom_som_cpp_runtime.a` (static),
`build/libtom_som_cpp_runtime.so` (shared), and `build/tom_som_cpp_runtime.pc`
(pkg-config metadata whose `Version` tracks the TomSpecs model version).

The conformance harness (`tests/conformance.cpp`) loads the language-agnostic
corpus (`../tom_som_conformance/corpus`) and reproduces the same checks as every
other port — model meta, `state.json` round-trip, YAML encode/decode, Markdown
export/parse/landing, reflection, validation, the imperative operations script,
and the Phase-4 CodeSpecs extract tier (routing verdicts, the per-area extracts
and their YAML/Markdown goldens, ROUTE-TOTAL refusals). Exit 0 == all green; it
prints `OK: N checks passed`.

The corpus directory can be overridden:

```sh
make test CORPUS=/path/to/corpus
./run_conformance.sh /path/to/corpus
```

## Packaging & install

C++ has no universal package registry, so the library is distributed as a
library + headers + pkg-config file, or as a source tarball:

```sh
make install PREFIX=/usr/local   # headers, static/shared libs, and the .pc file
make dist                        # build/tom_som_cpp_runtime-<version>.tar.gz
```

`make install` honours `DESTDIR` for staged / packaged installs and lays down
the versioned `.so` soname symlinks. See **readme_howtointegrate.md** for the
full integration guide (pkg-config, vendored tarball, in-tree monorepo).
