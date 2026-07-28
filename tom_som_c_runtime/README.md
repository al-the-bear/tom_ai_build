# tom_som_c_runtime

C port of the **generic TomSpecs object-model runtime** — the value-free,
generated-code-free half of the multi-platform spec model (`tom_som`). It is a
faithful transcription of the Dart reference, `tom_som_dart_runtime`, and the
Python/Java/JavaScript/TypeScript/Go/Rust ports.

## What it is

The static library `libtom_som_c_runtime.a` mirrors the portable runtime
modules, plus the hand-rolled JSON/YAML readers and a small C utility module
(growable buffer / list / byte-sorted map) that the C standard library does not
provide:

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.c` | The section-path grammar (root / child / list-item segments). |
| `spec_model.c` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.c` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, node-kind constants). |
| `spec_document.c` | A sparse in-memory document — values keyed by section path. |
| `spec_validator.c` | Validates a document's values against the model. |
| `spec_document_yaml.c` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown.c` | Meta-data-driven Markdown import/export codec. |
| `som_facade.c` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList`) for the generated `tom_som_c_v0`. |
| `yaml.c` | Hand-rolled, dependency-free reader for the constrained docspecs YAML subset. |
| `som_json.c` | Hand-rolled, dependency-free JSON reader/encoder (C ships none). |
| `som_util.c` | C-only support: `SomBuf` (string builder), `SomStrList`, `SomMap` (byte-sorted), small numeric/string helpers. |

It holds **no document values of its own** and contains **no generated typed
structs** — those belong to the per-language `tom_som_<lang>_v0` projects.

`include/tom_som_c_runtime.h` is the umbrella header; the per-module headers may
also be included directly.

## Zero external dependencies

The library depends only on the C standard library. JSON parsing uses the
hand-rolled `som_json` module; YAML uses the hand-rolled `yaml` module (the
constrained docspecs subset). Byte-stable `*.docspecs.yaml` output requires a
`js_json_string` that matches JavaScript's `JSON.stringify` exactly — it
delegates to `som_json_encode_str`, which emits the short escapes for
`" \ \b \f \n \r \t`, control characters below `0x20` as lowercase `\u00xx`, and
every other char (including `< > & /` and all non-ASCII) verbatim. The
regex-driven Markdown anchors of the reference are replaced by hand-rolled
scanners (`heading_path`, `field_anchor`, `fence_open`, `item_seg`).

## C-specific surface

C has no objects, generics, `Result`, or exceptions, so the runtime is an
accessor-function API over the generic structs. The notable deviations the
emitter mirrors:

- **Manual ownership / lifetime.** There is no `Rc<RefCell<…>>`: the one
  document is shared by **borrowed `SpecDocument *`**. Every facade node holds a
  borrowed document pointer plus the globally-unique section path it lives at
  (owned). The document must outlive every facade and resolution bound to it.
- **`SpecResolution` holds borrowed pointers** into the model (`root` / `field`
  / `target_class`); only `path` is owned. Free it with `spec_resolution_free`.
- **`SomList` is path-based, not generic.** It yields stable item paths; the
  generated typed accessors construct their element facades from those paths.
- **Sorted maps are byte-sorted dynamic arrays** (`SomMap`) with binary search,
  matching the Rust `BTreeMap` byte-order iteration the byte-stable codecs rely
  on. `list_seq` is stored as a `SomMap` with decimal-string values.
- **The YAML decoder drops the `review:` pass** — the runtime is review-agnostic
  and nothing in the conformance contract reads it.

## Building & testing

```sh
make                 # builds the static + shared library + pkg-config file
make test            # builds + runs the conformance harness against the corpus
make unit            # builds + runs the standalone unit tests
./run_conformance.sh # same as `make test`, via the wrapper script
```

`make` produces `build/libtom_som_c_runtime.a` (static),
`build/libtom_som_c_runtime.so` (shared), and `build/tom_som_c_runtime.pc`
(pkg-config metadata whose `Version` tracks the TomSpecs model version).

The conformance harness (`tests/conformance.c`) loads the language-agnostic
corpus (`../tom_som_conformance/corpus`) and reproduces the same checks as every
other port — model meta, `state.json` round-trip, YAML encode/decode, Markdown
export/parse/landing, reflection, validation, and the imperative operations
script. Exit 0 == all green; it prints `OK: N checks passed`.

The corpus directory can be overridden:

```sh
make test CORPUS=/path/to/corpus
./run_conformance.sh /path/to/corpus
```

## Packaging & install

C has no package registry, so the library is distributed as a library + headers
+ pkg-config file, or as a source tarball:

```sh
make install PREFIX=/usr/local   # headers, static/shared libs, and the .pc file
make dist                        # build/tom_som_c_runtime-<version>.tar.gz
```

`make install` honours `DESTDIR` for staged / packaged installs and lays down
the versioned `.so` soname symlinks. See **readme_howtointegrate.md** for the
full integration guide (pkg-config, vendored tarball, in-tree monorepo).
