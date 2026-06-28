# tom_som_javascript_runtime

JavaScript (Node.js) port of the **generic TomSpecs object-model runtime** — the
value-free, generated-code-free half of the multi-platform spec model
(`tom_som`). It is a faithful transcription of the Dart reference,
`tom_som_dart_runtime`, and the Python/Java ports.

## What it is

The package `tom_som_runtime` mirrors the eight portable runtime modules:

| Module | Responsibility |
| ------ | -------------- |
| `spec_paths.js` | The section-path grammar (root / child / list-item segments). |
| `spec_model.js` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.js` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, `SpecNodeKind`). |
| `spec_document.js` | A sparse in-memory document — values keyed by section path. |
| `spec_validator.js` | Validates a document's values against the model. |
| `spec_document_yaml.js` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown.js` | Meta-data-driven Markdown import/export codec. |
| `som_facade.js` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList`) for the generated `tom_som_javascript_v0`. |

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages. The
public API is re-exported from `tom_som_runtime/index.js`.

## Zero external dependencies

The build host carries only Node.js — no npm packages (no js-yaml). JSON parsing
uses the native `JSON.parse`/`JSON.stringify`; YAML uses a **hand-rolled,
dependency-free** parser (`yaml.js`, the constrained docspecs subset, ported from
the Java runtime's `Yaml.java`). The conformance suite is a plain-Node `main()`
(`tests/conformance_runner.js`), with a thin `node --test` wrapper
(`tests/conformance.test.js`).

## Conformance

Correctness is defined by the shared, language-agnostic conformance corpus in
`../tom_som_conformance/corpus`, generated from the Dart reference. The JavaScript
port is validated against the exact same goldens every other port uses:

```bash
node tests/conformance_runner.js   # or: ./run_conformance.sh, or: node --test
```

This asserts byte-for-byte equality of the YAML and Markdown encodings, the
document round-trips, the Markdown→memory landing, and the reflection /
validation / operations behaviour (95 checks, exit 0 on success).

## Requirements

* Node.js ≥ 18 (verified with Node 22.x).
