# tom_som_go_runtime

Go port of the **generic TomSpecs object-model runtime** — the value-free,
generated-code-free half of the multi-platform spec model (`tom_som`). It is a
faithful transcription of the Dart reference, `tom_som_dart_runtime`, and the
Python/Java/JavaScript/TypeScript ports.

## What it is

The module `tom_som_go_runtime` (package `somruntime`) mirrors the eight portable
runtime modules:

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.go` | The section-path grammar (root / child / list-item segments). |
| `spec_model.go` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.go` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, `SpecNodeKind*`). |
| `spec_document.go` | A sparse in-memory document — values keyed by section path. |
| `spec_validator.go` | Validates a document's values against the model. |
| `spec_document_yaml.go` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown.go` | Meta-data-driven Markdown import/export codec. |
| `som_facade.go` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList[T]`) for the generated `tom_som_go_v0`. |

It holds **no document values of its own** and contains **no generated typed
structs** — those belong to the per-language `tom_som_<lang>_v0` packages.

## Zero external dependencies

The module depends only on the Go standard library — no third-party packages.
JSON parsing uses `encoding/json`; YAML uses a **hand-rolled, dependency-free**
parser (`yaml.go`, the constrained docspecs subset, ported from the Java
runtime's `Yaml.java`). Byte-stable `*.docspecs.yaml` output requires a custom
`jsJSONString` that matches JavaScript's `JSON.stringify` exactly — Go's
`encoding/json` HTML-escapes `<`, `>`, `&` and U+2028/U+2029, so it is **not**
used for the on-disk YAML scalars.

## Go-specific surface

Go has no classes, exceptions, or enums, so the facade differs from the other
ports in idiomatic ways the emitter mirrors:

- **Exported (Capitalized) accessors** — model field `vision` becomes method
  `Vision()` / `SetVision(string)`. Capitalizing the first letter also makes Go
  keyword collisions impossible (Go keywords are all lowercase).
- **`SomNode` exposes the bound document/path through exported methods `Doc()` /
  `Path()`** over unexported fields, with `NewSomNode` as constructor. A generated
  facade method named `Doc` or `Path` would *shadow* these promoted methods and
  self-recurse, so the Go emitter reserves those two Pascal-cased names — the Go
  analogue of the TypeScript `doc`/`path` guard.
- **Errors instead of exceptions** — the version check returns
  `*SomVersionError`; root constructors return `(*T, error)`.

## Build + conformance

Correctness is defined by the shared, language-agnostic conformance corpus in
`../tom_som_conformance/corpus`, generated from the Dart reference. The Go port
is validated against the exact same goldens every other port uses:

```bash
go build ./...                       # compile the runtime
go vet ./...                         # static checks
go test ./tests/ -run Conformance    # → "OK: N checks passed"
# or, all-in-one:
./run_conformance.sh
```

The runner reproduces every golden byte-for-byte and exercises the same cases as
the Dart/Python/Java/JavaScript/TypeScript runners: model meta-data load,
`state.json` round-trip, YAML encode/decode, Markdown export/round-trip, the
**Markdown→memory landing** check (the `md.land.*` shared contract — parsing
`expected.md` lands the same memory as the YAML route), reflection resolution,
validation, and the imperative operations script.

## Consumed by `tom_som_go_v0`

The generated typed model imports the facade and runtime types from this module
(`import som "tom_som_go_runtime"`). The generator wires resolution with a
`require tom_som_go_runtime v0.0.0` + a relative `replace tom_som_go_runtime =>
../tom_som_go_runtime` in the `v0` module's `go.mod` (the Go analogue of the TS
relative `file:` dependency), keeping the generated source path-free and
golden-stable.
