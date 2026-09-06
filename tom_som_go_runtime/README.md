# tom_som_go_runtime — generic Go SOM runtime

> **Cross-references.**
> [`tom_specs_model/doc/som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
> is the SOM authority: `SOM §9` decides what a runtime must contain, `SOM §6`
> decides the split between the generic and the typed access path, `SOM §11` and
> `SOM §12` decide the `*.md` and `*.docspecs.yaml` formats, and `SOM §19`
> decides the conformance corpus this port is measured against.
> [`tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md)
> decides this language plane's build and verify toolchain. This README says how
> to **use this package's code**; those documents own the model, the formats and
> the rules, and nothing here restates them.

Go port of the generic TomSpecs object-model runtime (paths, model, reflection,
document, validator, YAML/Markdown codecs). Zero external dependencies
(standard library only).

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this module) holding everything that is the same
everywhere, and a generated `tom_som_go_v0` facade holding the typed structs for
one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator; with it, the generator emits only
what actually changes when the model changes.

This module is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime), and of the Python, Java,
JavaScript and TypeScript ports — it invents nothing, and "faithful" is a
measured claim rather than an intention: every port is validated against the same
goldens, byte for byte (`SOM §19`). Reach for it directly when you drive the
generic API by section path; otherwise depend on the typed facade, which
`require`s this module.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the module is a layer over it —
the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated structs, the byte-stable YAML and Markdown codecs, the
editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
structs** — those belong to the per-language `tom_som_<lang>_v0` packages. The
module is `github.com/al-the-bear/tom_ai_build/tom_som_go_runtime`; the Go
package is `somruntime`.

## Installation

```bash
go get github.com/al-the-bear/tom_ai_build/tom_som_go_runtime@v1.1.0
```

Go has no central package registry — a version is a **VCS tag**
(`vMAJOR.MINOR.PATCH`) on this module, mirrored in the in-source `Version`
constant (`doc.go`). The version tracks the TomSpecs **model version**, and
`tom_som_go_v0` pins the same one — upgrade both together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for the `go get` / version
tag / path-`replace` routes and how to pin.

## Features

### Modules

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.go` | The section-path grammar (root / child / list-item segments). |
| `spec_model.go` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.go` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, `SpecNodeKind*`). |
| `spec_document.go` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values.go` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.go` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.go` | Validates a document's values against the model. |
| `spec_text_pattern.go` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (Go's RE2-based `regexp` is leftmost-longest and would not). |
| `spec_query.go` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.go` | The constrained node-creation gate (`CheckAddNode`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.go` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — per-area, verbatim, with provenance. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_document_yaml.go` | Byte-stable `*.docspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.go` | Meta-data-driven Markdown import/export codec (`SOM §11`). |
| `som_facade.go` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList[T]`) for the generated `tom_som_go_v0`. |

## Quick start

```go
import som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"

doc := som.NewSpecDocument()
doc.SetContent("SBP/content", "A unifying order platform.")
fmt.Println(doc.Content("SBP/content"))
// A unifying order platform.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
structs involved:

```go
model, err := som.SpecModelFromJSON(metaBytes)
if err != nil {
    log.Fatal(err)
}
reflection := som.NewSpecReflection(model)

fmt.Println(reflection.Resolve("SBP/content") != nil)
// true
fmt.Println(len(som.ValidateDocument(model, doc)) == 0)
// true
```

### Zero external dependencies

The module depends only on the Go standard library — no third-party packages.
JSON parsing uses `encoding/json`; YAML uses a **hand-rolled, dependency-free**
parser (`yaml.go`, the constrained docspecs subset, ported from the Java
runtime's `Yaml.java`). Byte-stable `*.docspecs.yaml` output requires a custom
`jsJSONString` that matches JavaScript's `JSON.stringify` exactly — Go's
`encoding/json` HTML-escapes `<`, `>`, `&` and U+2028/U+2029, so it is **not**
used for the on-disk YAML scalars.

### Go-specific surface

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

### Consumed by `tom_som_go_v0`

The generated typed model imports the facade and runtime types from this module
(`import som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"`). The
generator wires resolution with a
`require github.com/al-the-bear/tom_ai_build/tom_som_go_runtime v0.0.0` + a
relative `replace … => ../tom_som_go_runtime` in the `v0` module's `go.mod` (the
Go analogue of the TS relative `file:` dependency), so the module builds both
standalone (external `go get`, resolved via VCS) and in-repo, while keeping the
generated source path-free and golden-stable.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```bash
go build ./...                                  # compile the runtime
go vet ./...                                    # static checks
go test ./tests/ -run Conformance -count=1 -v   # → "OK: N checks passed"
./run_conformance.sh                            # the same, via the wrapper
./run_tests.sh                                  # conformance + the per-module suites
```

The runner reproduces every golden byte-for-byte and exercises the same cases as
the Dart/Python/Java/JavaScript/TypeScript runners: model meta-data load,
`state.json` round-trip, YAML encode/decode, Markdown export/round-trip, the
**Markdown→memory landing** check (the `md.land.*` shared contract — parsing
`expected.md` lands the same memory as the YAML route), reflection resolution,
validation, the imperative operations script, and the Phase-4 CodeSpecs extract
tier (routing verdicts, the per-area YAML/Markdown goldens, the verbatim-copy
guard and the `ROUTE-TOTAL` error cases).

## Architecture

```
        typed path                          generic path
    tom_som_go_v0         ─────▶   SomNode / SomScalar / SomList[T]
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml.go
  SpecQueryEngine      ValidateDocument    spec_document_markdown.go
        │
        ▼
     SpecModel  ◀── meta/spec_model.meta.json
```

| Type | Responsibility |
| ---- | -------------- |
| `SpecDocument` | The sparse, path-keyed store of a document's content, form and list values. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated structs. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `ValidateDocument` | The instance tier: a filled document's values checked against the model. |
| `SpecDocumentYaml` | Byte-stable `*.docspecs.yaml` encode/decode. |
| `SpecDocumentMarkdown` | DocSpecs-conform Markdown export, parse and round-trip. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SomNode` / `SomScalar` / `SomList[T]` | The editing-facade base types the generated `tom_som_go_v0` structs embed. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──generate_som──▶ tom_som_go_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ requires
                                                                  ▼
                                                      tom_som_go_runtime  ← this module
                                                                  │ validated against
                                                                  ▼
                                                         tom_som_conformance
                                                          (shared corpus)
```

## Further documentation

**TomSpecs subject matter** — the authorities this module implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs subject-matter document, and the `§` citation convention. |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.md` and `*.docspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the reference host. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |

**This module** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_go_v0](../tom_som_go_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.1.0**, tracking the TomSpecs model version. Requires Go ≥ 1.21.
Covered by 10 test files; the conformance runner reports
**OK: 971 checks passed** and `./run_tests.sh` is green.
