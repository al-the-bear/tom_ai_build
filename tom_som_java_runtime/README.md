# tom_som_java_runtime

Java port of the **generic TomSpecs object-model runtime** — the value-free,
generated-code-free half of the multi-platform spec model (`tom_som`). It is a
faithful transcription of the Dart reference, `tom_som_dart_runtime`, and the
Python port, `tom_som_python_runtime`.

## What it is

The package `tom_som_runtime` mirrors the eight portable runtime modules:

| Type(s) | Responsibility |
| ------- | -------------- |
| `SpecPaths` | The section-path grammar (root / child / list-item segments). |
| `SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, … | The meta-data loader — the exported class graph. |
| `SpecReflection`, `SpecResolution`, `SpecNodeKind` | Value-free enumeration + path resolution. |
| `SpecDocument` | A sparse in-memory document — values keyed by section path. |
| `SpecValidator` | Validates a document's values against the model. |
| `SpecDocumentYaml` | Byte-stable `*.docspecs.yaml` codec. |
| `SpecDocumentMarkdown` | Meta-data-driven Markdown import/export codec. |
| `SomNode`, `SomScalar`, `SomList`, `SomFacade` | Editing-facade base types for the generated `tom_som_java_v0`. |
| `SomEditability`, `SomVersionError` | §2.2 version-check outcome enum (non-throwing `SomFacade.somEditabilityFor`) and its throwing error. |

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages.

## Zero external dependencies

The build host carries only the JDK (`javac`/`java`) — no Maven, Gradle, JUnit,
SnakeYAML, or Gson. The runtime therefore ships **hand-rolled, dependency-free**
`Json` and `Yaml` parsers (the constrained docspecs subset), and the conformance
suite is a plain-Java `main()` (`ConformanceRunner`) rather than a JUnit harness.

## Conformance

Correctness is defined by the shared, language-agnostic conformance corpus in
`../tom_som_conformance/corpus`, generated from the Dart reference. The Java port
is validated against the exact same goldens every other port uses:

```bash
./run_conformance.sh
```

This compiles the runtime + runner and asserts byte-for-byte equality of the YAML
and Markdown encodings, the document round-trips, the Markdown→memory landing,
and the reflection / validation / operations behaviour (95 checks, exit 0 on
success).

## Requirements

* JDK ≥ 17 (verified with `javac`/`java` 21).
