# tom_som_typescript_runtime — generic TypeScript SOM runtime

> **Cross-references.**
> [`tom_specs_model/doc/som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
> is the SOM authority: `SOM §9` decides what a runtime must contain, `SOM §6`
> decides the split between the generic and the typed access path, `SOM §11` and
> `SOM §12` decide the `*.tomspecs.md` and `*.tomspecs.yaml` formats, and `SOM §19`
> decides the conformance corpus this port is measured against.
> [`tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md)
> decides this language plane's build and verify toolchain, including the pinned
> project-local compiler. This README says how to **use this package's code**;
> those documents own the model, the formats and the rules, and nothing here
> restates them.

TypeScript port of the generic TomSpecs object-model runtime (paths, model,
reflection, document, validator, YAML/Markdown codecs). Zero external runtime
dependencies (Node built-ins only); typescript is a dev dependency.

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this package) holding everything that is the same
everywhere, and a generated `tom_som_typescript_v0` facade holding the typed
classes for one model version. Without the split, every regeneration would
rewrite the document store, the codecs and the validator; with it, the generator
emits only what actually changes when the model changes.

This package is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime), and of the Python, Java and
JavaScript ports — it invents nothing, and "faithful" is a measured claim rather
than an intention: every port is validated against the same goldens, byte for
byte (`SOM §19`). Reach for it directly when you drive the generic API by
section path; otherwise install the typed facade, which pulls this in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the package is a layer over it
— the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated classes, the byte-stable YAML and Markdown codecs,
the editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages. The
public API is re-exported from `src/index.ts` (compiled to `dist/src/index.js`
with declarations at `dist/src/index.d.ts`).

## Installation

```bash
npm install tom_som_typescript_runtime
```

Both this package and the facade ship compiled `dist/` (`*.js` + `*.d.ts`). The
version tracks the TomSpecs **model version**, and `tom_som_typescript_v0` pins
the same one — upgrade both together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for the npm / git /
path-link routes, version pinning, and building from source.

## Features

### Modules

| Module | Responsibility |
| ------ | -------------- |
| `spec_paths.ts` | The section-path grammar (root / child / list-item segments). |
| `spec_model.ts` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.ts` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, `SpecNodeKind`). |
| `spec_document.ts` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values.ts` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.ts` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.ts` | Validates a document's values against the model. |
| `spec_text_pattern.ts` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (`RegExp` is the ECMAScript grammar, which accepts far more than the subset and would let a pattern that only works here into the corpus). |
| `spec_query.ts` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.ts` | The constrained node-creation gate (`checkAddNode`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.ts` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — per CodeSpecs area, every value `@CodeSpecKind` routes there, verbatim and with provenance. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). Also reads the artifacts back: `CodeSpecsExtract.fromYaml`, the gate record `CodeSpecsGateRecord` and the scoped `CodeSpecsExtractSet`. |
| `spec_impact_walk.ts` | The impact walk of the `tom_specs` change mode: `specImpactWalk` lists every section of every document root of the model for a specification (a root without a document over an empty one) — section-id chain, class, fill state, value count, CodeSpecs routing — and an empty list of sections as a template `<list>/*`; `specImpactLevel` records how far the project has come from a listing of its spec root; `specImpactDocumentFiles` finds the current documents in that listing; `specImpactWalkMarkdown` writes the table. Pure (no IO); the extension's `tomAi_specImpactWalk` runs it in-process. |
| `spec_generation_units.ts` | The generation-unit register of a document (SOM §11.2): `specGenerationUnits` reads each unit (`SpecGenerationUnit`: id, kind, mappings per area, the standard emitters it ships — `K_SPEC_STANDARD_EMITTERS`), recognised by `@NoArtifact(generation)` as validation phase 8 recognises it; `specDefaultUnits` is the default destination of an area — the extract fills an entry's `units` from it when no section stores units. |
| `spec_codespecs_gate.ts` | The Phase-4 Stage-A gate (`CodeSpecsGate`) — checks A1–A5 of `codespecs_prompt.md` §4 run as one over model, document, catalogue and DocSpecs schema; a check that could not run is reported not run, never passed. |
| `spec_document_yaml.ts` | Byte-stable `*.tomspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.ts` | Meta-data-driven Markdown import/export codec (`SOM §11`). |
| `som_facade.ts` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList<T>`) for the generated `tom_som_typescript_v0`. |
| `spec_review_annotations.ts` | Review annotations (SOM §11.9): comments, questions and their answers (team and individual), inline marks (`SpecReviewAnnotations`: insert, answer, decide, comment on a change, assign comment ids, strip, validate), conflict blocks, change times and attribution; `formatCommentBlock` / `formatQuestionBlock` / `formatConflictBlock`. |
| `spec_review_merge.ts` | Team review (SOM §11.9.8): `mergeReviews` merges the returned copies of a round into one document with votes, individual answers and conflict blocks (`SpecReviewMergeResult`, `SpecReviewMergeReport`). |
| `spec_answers.ts` | A review round's answers (SOM §11.9.7): `extractAnswers` collects the answered questions and comments with their section-id chain and line, `renderAnswers` writes `answers.md`. |
| `spec_place.ts` | The place and filter grammar of the links between places (`tom_specs_model_rules.md` §9.7): `SpecPlace` (parsed, resolved under an anchor to the path its value is stored at), `SpecPlaceFilter` (`<SECTIONID>.<field>=<value>`, `\|` alternatives, read by `countOf` too), the `@SameAs` bindings and section positions. The typed link readers themselves (`SpecSync`, `SpecSummaryOf`, `SpecDerivation`, `SpecInverseOf`, `SpecExtractsLinks`, `SpecSameAs`) are in `spec_model.ts`. |
| `spec_links_validator.ts` | `validateLinks` — the link checks of one document: derived copies, rows, lookups and lists in step, inverses named back, ids named in a text with their rows, summaries against their details, `@SameAs` copies against their holders, pending changes. |
| `spec_document_set.ts` | The documents of one specification as a set (`SpecDocumentSet`, from documents or fragments), `syncReport` (every shared fact compared across the documents that hold it, `SpecSyncReport`) and `renameId` (an id renamed in every document). |
| `spec_derive_fields.ts` | `deriveFields` — the derived places of one document written in three steps, plain or as marked changes. |
| `spec_backfill.ts` | `backfill` — the Phase 3 documents' accepted end state carried into the Blueprint, plain, with what it leaves and why. |
| `spec_prefill.ts` | `prefill` — a Phase 3 document started from the Blueprint's shared sections. |
| `spec_document_markdown_linked.ts` | The rendition's navigation: qualified anchors below a list item (SOM §11.2) and the `linked` marker of each link (SOM §11.11), removed on parse. |
| `spec_document_markdown_generated.ts` | The rendition's generated parts (SOM §11.12): the requirement views' tables in `derived` blocks, read back as nothing. |
| `spec_document_assembly.ts` | Fragments of one document assembled into one (`assembleSpecDocuments`, `SpecDocumentAssembly`), refusing overlapping values (`SpecAssemblyOverlap`). |
| `spec_meta.ts` | The metadata tree types (`SomMetaTree`, `SomMetaNode`, `SomMetaKind`, …) the YAML codec and the facade navigate by. |
| `spec_meta_bridge.ts` | `buildSomMetaTree` — the metadata tree of a model, for one root or all. |
| `spec_meta_diff.ts` | `somMetaNodeDiff` — the first difference between two metadata trees, or `null`. |
| `spec_section_id.ts` | List-item section ids (AA1): `generateListItemSectionId`, `encodeTwoLetterDate`, `effectiveListItemSectionId`, `K_SECTION_ID_SLOT`, `SpecSectionIdCollision`. |
| `spec_serialization_order.ts` | `SpecSerializationOrder` — the model's member order (`orderKey`, `orderPaths`), which every codec writes in. |
| `docspecs_validator.ts` | DocSpecs Markdown documents: the schema-free parse (`DocSpecsDocument`, its sections and `allSections`) and the schema check (`DocSpecsValidator`, `DocSpecsViolation`). |
| `spec_schema_validation.ts` | `validateSpecDocument` — the DocSpecs schema tier over a document's Markdown rendition. |
| `yaml.ts` | The YAML reader the codec uses (`parse`, `parseMap`; `parse(text, true)` types the review pass, SOM §12.5) and `YamlFloat` / `formatYamlFloat`, the review pass's float form. |

## Quick start

```typescript
import { SpecDocument } from 'tom_som_typescript_runtime';

const doc = new SpecDocument();
doc.setContent('SBP/content', 'A unifying order platform.');
console.log(doc.content('SBP/content'));
// A unifying order platform.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
classes involved:

```typescript
import {
  SpecModel,
  SpecReflection,
  validateDocument,
} from 'tom_som_typescript_runtime';

const model = SpecModel.fromJson(JSON.parse(metaJson));
const reflection = new SpecReflection(model);

console.log(reflection.resolve('SBP/content') !== null);
// true
console.log(validateDocument(model, doc).length === 0);
// true
```

Most projects reach for the runtime alone only when driving the generic API by
section path.

### Zero external runtime dependencies

The compiled JavaScript depends only on Node built-ins — no npm packages (no
js-yaml). JSON parsing uses the native `JSON.parse`/`JSON.stringify`; YAML uses a
**hand-rolled, dependency-free** parser (`yaml.ts`, the constrained docspecs
subset, ported from the Java runtime's `Yaml.java`). The only dev dependencies
are the compiler itself (`typescript`, pinned `6.0.3`) and `@types/node`.

### Consumed by `tom_som_typescript_v0`

The generated typed model imports the facade and runtime types from this package
by its bare name (`import { SomList, SomNode, … } from 'tom_som_typescript_runtime'`).
The generator wires resolution by declaring a relative `file:` dependency on this
package, so both `tsc` (via `dist/src/index.d.ts`) and `node` (via
`dist/src/index.js`) resolve it through `node_modules` — keeping the generated
source path-free and golden-stable. Build this package (`npm run build`) before
compiling the `v0` project.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```bash
npm install          # brings the pinned tsc + @types/node
npm run build        # tsc → dist/
npm run conformance  # node dist/tests/conformance_runner.js  → "OK: N checks passed"
npm test             # build + conformance
./run_conformance.sh # install (if needed) + build + conformance
./run_tests.sh       # conformance + the per-module suites
```

The runner reproduces every golden byte-for-byte and exercises the same cases as
the Dart/Python/Java/JavaScript runners: model meta-data load, `state.json`
round-trip, YAML encode/decode, Markdown export/round-trip, the
**Markdown→memory landing** check (the `md.land.*` shared contract — parsing
`expected.tables.md`, the table layout this runtime emits, or
`expected.tomspecs.md`, the older `Field:` lines, lands the same memory as the
YAML route), reflection resolution,
validation, the imperative operations script, and the **Phase-4 CodeSpecs
extract** tier (routing verdicts, the per-area extracts with their YAML and
Markdown goldens, and the `ROUTE-TOTAL` error cases).

It also replays the section-automation tables: the link readers, `validateLinks`,
the document set (`syncReport`, `renameId`), `deriveFields`, `backfill`,
`prefill`, the rendition's navigation and generated parts, and the typed inline
marks (`typedCases`) — over the fixture model `corpus/links.meta.json` and, for
the cases naming it, the real model of `tom_som_dart_v0/meta/`.

## Architecture

```
        typed path                          generic path
  tom_som_typescript_v0     ─────▶   SomNode / SomScalar / SomList
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml.ts
  SpecQueryEngine      validateDocument    spec_document_markdown.ts
        │
        ▼
     SpecModel  ◀── meta/spec_model.meta.json
```

| Type | Responsibility |
| ---- | -------------- |
| `SpecDocument` | The sparse, path-keyed store of a document's content, form and list values. |
| `SpecDocument.assemble` | Merges fragment documents written in parallel into one, refusing every place two fragments both write (`SpecDocumentAssembly`, `SpecAssemblyOverlap`). |
| `SpecDocument.moveListItem` | Moves a list item within its list or to another list of the same element class, renumbering paths and pinning anonymous ids (`SpecListItemMove`); `SpecDocumentYaml.rekeyReview` re-keys the `review:` pass to match. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated classes. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `validateDocument` | The instance tier: a filled document's values checked against the model. |
| `SpecDocumentYaml` | Byte-stable `*.tomspecs.yaml` encode/decode. |
| `SpecDocumentMarkdown` | DocSpecs-conform Markdown export, parse and round-trip. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SpecGenerationUnit` | One generation unit of a document's register, with its mapping per area (`specGenerationUnits`). |
| `CodeSpecsExtractSet` | Reads extracts back (`CodeSpecsExtract.fromYaml`) and scopes them by the Stage-B gate record (`CodeSpecsGateRecord`, `gate.verdicts.yaml`). |
| `CodeSpecsGate` | The Phase-4 Stage-A gate — A1 (DocSpecs completeness), A2 (values), A3 (routing), A4 (required marker arguments), A5 (carriers) in one `CodeSpecsGateReport`. |
| `SomNode` / `SomScalar` / `SomList<T>` | The editing-facade base types the generated `tom_som_typescript_v0` classes extend. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──tomspecs :som-generate──▶ tom_som_typescript_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ depends on
                                                                  ▼
                                                  tom_som_typescript_runtime  ← this package
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
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.tomspecs.md` and `*.tomspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the pinned project-local compiler. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |

**This package** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route, version pinning, and building from source. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_typescript_v0](../tom_som_typescript_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.10.0**, tracking the TomSpecs model version. Requires Node.js ≥ 18.
Covered by 10 test files; the conformance runner reports
**OK: 877 checks passed** and `./run_tests.sh` is green.
