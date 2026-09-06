# tom_som_java_runtime — generic Java SOM runtime

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

Generic TomSpecs object-model runtime for Java: the value-free,
generated-code-free half of the multi-platform spec model. The editing-facade
base for `tom_som_java_v0`.

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this package) holding everything that is the same
everywhere, and a generated `tom_som_java_v0` facade holding the typed classes
for one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator; with it, the generator emits only
what actually changes when the model changes.

This package is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime), and of the Python port — it
invents nothing, and "faithful" is a measured claim rather than an intention:
every port is validated against the same goldens, byte for byte (`SOM §19`).
Reach for it directly when you drive the generic API by section path; otherwise
depend on the typed facade, which pulls this in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the package is a layer over it
— the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated classes, the byte-stable YAML and Markdown codecs, the
editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages. The
Maven artifact is `tom_som_java_runtime` (group `io.github.al-the-bear`); the
Java package is `tom_som_runtime`.

## Installation

```xml
<dependency>
  <groupId>io.github.al-the-bear</groupId>
  <artifactId>tom_som_java_runtime</artifactId>
  <version>1.1.0</version>
</dependency>
```

The version tracks the TomSpecs **model version**, and `tom_som_java_v0` pins the
same one — upgrade both together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for the Maven / local
install / JDK-only `build_jar.sh` routes and how to pin.

## Features

### Types

| Type(s) | Responsibility |
| ------- | -------------- |
| `SpecPaths` | The section-path grammar (root / child / list-item segments). |
| `SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, … | The meta-data loader — the exported class graph. |
| `SpecReflection`, `SpecResolution`, `SpecNodeKind` | Value-free enumeration + path resolution. |
| `SpecDocument` | A sparse in-memory document — values keyed by section path. |
| `SpecTypedValues` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `SpecEditor` | The generic meta-model-driven modification API (YRD7) — typed edits over any path, without a generated facade. |
| `SpecValidator` | Validates a document's values against the model. |
| `SomTextPattern`, `SomPatternError` | The portable pattern subset — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (`java.util.regex` is a different grammar, and its case folding is Unicode-wide where the contract stops at ASCII). |
| `SpecQuery`, `SpecQueryEngine`, `SpecQueryCursor`, `SpecQueryMatch` | The lexical/structural query surface plus the flat tier-1 node projection. |
| `SpecNodeCreator`, `SpecCreationError`, `SpecCreationCode` | The constrained node-creation gate (`checkAddNode`, `add`) — a document may only grow in ways the model permits. |
| `SpecDocumentYaml` | Byte-stable `*.docspecs.yaml` codec (`SOM §12`). |
| `SpecDocumentMarkdown` | Meta-data-driven Markdown import/export codec (`SOM §11`). |
| `SomNode`, `SomScalar`, `SomList`, `SomFacade` | Editing-facade base types for the generated `tom_som_java_v0`. |
| `SomEditability`, `SomVersionError` | `SOM §4.2` version-check outcome enum (non-throwing `SomFacade.somEditabilityFor`) and its throwing error. |
| `SpecAnnotations`, `KindLink`, `NoArtifactLink` | The annotation lookups shared by `SpecClass` and `SpecField`, including the three routing verdicts of `codespecs_mapping.md` §8.3 (`@CodeSpecKind` / `@FollowUpKind` / `@NoArtifact`). |
| `CodeSpecsExtractor`, `CodeSpecsExtract`, `CodeSpecsAreaCatalog`, `CodeSpecsArea`, `CodeSpecsSlice`, `CodeSpecsRouting`, `CodeSpecsExtractEntry`, `CodeSpecsExtractError` | The Phase-4 CodeSpecs specification-extract generator: per area, every value the document routes there — verbatim, with provenance — plus its YAML and Markdown artifacts. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |

## Quick start

```java
import tom_som_runtime.SpecDocument;

SpecDocument doc = new SpecDocument();
doc.setContent("SBP/content", "A platform that unifies our order systems.");
System.out.println(doc.content("SBP/content"));
// A platform that unifies our order systems.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
classes involved:

```java
SpecModel model = SpecModel.fromJson(Json.parseObject(metaJson));
SpecReflection reflection = new SpecReflection(model);

System.out.println(reflection.resolve("SBP/content") != null);
// true
System.out.println(SpecValidator.validateDocument(model, doc).isEmpty());
// true
```

### Zero external dependencies

The build host carries only the JDK (`javac`/`java`) — no Maven, Gradle, JUnit,
SnakeYAML, or Gson. The runtime therefore ships **hand-rolled, dependency-free**
`Json` and `Yaml` parsers (the constrained docspecs subset), and the conformance
suite is a plain-Java `main()` (`ConformanceRunner`) rather than a JUnit harness.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```bash
./build_jar.sh        # JDK-only jar build
./run_conformance.sh  # compile runtime + runner → "OK: N checks passed"
./run_tests.sh        # conformance + the per-module suites
```

The runner asserts byte-for-byte equality of the YAML and Markdown encodings, the
document round-trips, the Markdown→memory landing, the reflection / validation /
operations behaviour, and the Phase-4 CodeSpecs extracts (exit 0 on success).

## Architecture

```
        typed path                          generic path
   tom_som_java_v0        ─────▶   SomNode / SomScalar / SomList
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          SpecDocumentYaml
  SpecQueryEngine      SpecValidator       SpecDocumentMarkdown
        │
        ▼
     SpecModel  ◀── meta/spec_model.meta.json
```

| Type | Responsibility |
| ---- | -------------- |
| `SpecDocument` | The sparse, path-keyed store of a document's content, form and list values. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated classes. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `SpecValidator` | The instance tier: a filled document's values checked against the model. |
| `SpecDocumentYaml` | Byte-stable `*.docspecs.yaml` encode/decode. |
| `SpecDocumentMarkdown` | DocSpecs-conform Markdown export, parse and round-trip. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SomNode` / `SomScalar` / `SomList` | The editing-facade base types the generated `tom_som_java_v0` classes extend. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──generate_som──▶ tom_som_java_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ depends on
                                                                  ▼
                                                     tom_som_java_runtime  ← this package
                                                                  │ validated against
                                                                  ▼
                                                         tom_som_conformance
                                                          (shared corpus)
```

## Further documentation

**TomSpecs subject matter** — the authorities this package implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs subject-matter document, and the `§` citation convention. |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.md` and `*.docspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the reference host. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |

**This package** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_java_v0](../tom_som_java_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.1.0**, tracking the TomSpecs model version. Requires JDK ≥ 17
(verified with `javac`/`java` 21). Covered by 9 test files; the conformance
runner reports **OK: 923 checks passed** and `./run_tests.sh` is green.
