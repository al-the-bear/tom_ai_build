# tom_som_java_runtime — generic Java SOM runtime

> **Cross-references.**
> [`tom_specs_model/doc/som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
> is the SOM authority: `SOM §9` decides what a runtime must contain, `SOM §6`
> decides the split between the generic and the typed access path, `SOM §11` and
> `SOM §12` decide the `*.tomspecs.md` and `*.tomspecs.yaml` formats, and `SOM §19`
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
| `SpecSync`, `SpecListRelation`, `SpecSummaryOf`, `SpecDerivation`, `SpecInverseOf`, `SpecExtractsLinks`, `SpecSameAs` | The typed readers of the link annotations (`tom_specs_model_rules.md` §9.7): `syncedWith()`, `summaryOf()`, `derivedFrom()`, `extractsLinks()`, `sameAs()` and `annotationsNamed()` on `SpecClass` and `SpecField`, the form-field qualifiers `FormFieldSpec.derivedFrom` / `inverseOf` / `summaryOf`, `SpecClass.isCodeSpecsProjection()`. A string → string argument (`repeats`, `map`, `set`) keeps the meta's order. |
| `SpecPlace`, `SpecPlaceFilter`, `SpecPlaceResolution`, `SpecPlaceKind`, `SpecPlaceProblem`, `SpecPlaceException`, `SpecSameAsBinding`, `SpecSectionPosition` | The place and filter grammar of the links between places (`tom_specs_model_rules.md` §9.7): a place parsed and resolved under an anchor to the path its value is stored at (list items written `<list>-*`), a filter `<SECTIONID>.<field>=<value>` with `\|` alternatives (read by `countOf` too), the `@SameAs` bindings (`SpecPlace.sameAsBindings`) and the section positions of a root (`SpecPlace.sectionPositions`). |
| `SpecLinkValidator`, `SpecLinkFix` | `SpecValidator.validateLinks` — the link checks of one document: derived copies, rows, lookups and lists in step, inverses named back, ids named in a text with their rows, summaries against their details, `@SameAs` copies against their holders; a value holding pending marks is read with them rejected and listed (`linkValuePending`). `SpecLinkValidator` collects beside every finding the fix `deriveFields` writes (`SpecLinkFix`, the order of an added row's values and of a derived list's places recorded). |
| `SpecDeriveFields`, `SpecDeriveOptions`, `SpecDeriveResult`, `SpecDeriveChange` | `deriveFields` — the derived places of one document written (link ends and rows, derived values and lists, repeats and `@SameAs` copies, then counts, products and ranks), plain or as inline marks in a document under review; a change that cannot be marked exactly is left `unmarkable`; `dryRun` works on a copy. |
| `SpecDocumentSet`, `SpecSyncPair`, `SpecSyncReport`, `SpecSyncFinding`, `SpecSyncPlace`, `SpecSyncCode`, `SpecSyncResolution`, `SpecSyncHolder`, `SpecDocumentFindings`, `SpecDocumentSetError`, `SpecDocumentSetRefusal`, `SpecRenameChange`, `SpecRenameError`, `SpecSetCheck`, `SpecSetSide` | A project's documents read side by side, one per root (`new SpecDocumentSet`, `fromFragments`, `load`), with the anchor pairs of the synced classes; `syncReport` (the shared places of each Phase 3 document against the Blueprint, the links across two documents, pending and unmarkable values, each document's own findings) and `renameId` (an id renamed in every document at once). |
| `SpecPrefill`, `SpecPrefillOptions`, `SpecPrefillResult`, `SpecPrefillError` | `prefill` — a Phase 3 document started from the Blueprint: the pairs that hold nothing yet copied with their elements' ids, then derived. |
| `SpecBackfill`, `SpecBackfillOptions`, `SpecBackfillResult`, `SpecBackfillChange`, `SpecBackfillLeft`, `SpecBackfillError` | `backfill` — the accepted Phase 3 end state carried into the Blueprint as plain values, with one revision entry; refused while a document holds marks or annotation blocks. |
| `SpecReflection`, `SpecResolution`, `SpecNodeKind` | Value-free enumeration + path resolution. |
| `SpecDocument` | A sparse in-memory document — values keyed by section path. |
| `SpecDocumentAssembly`, `SpecAssemblyOverlap` | Assembling one document from fragments written in parallel (`SpecDocument.assemble`): a refusing merge of the plain-data stores — a content path, form field, list, headline or code-spec location two fragments both write is an overlap, and an assembly with any overlap has no document. |
| `SpecListItemMove` | Moving a list item (`SpecDocument.moveListItem`) to another position of its list, or into another list of the same element class: the affected lists are renumbered, every value under each item travels with it, and an anonymous item whose position changed keeps its old id (pinned). `SpecDocumentYaml.rekeyReview` re-keys a `review:` pass with the move's `renamed` map. |
| `SpecTypedValues` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided; a typed value holding inline marks reads as its old value (`somTypedReading`, SOM §11.9.3). |
| `SpecEditor` | The generic meta-model-driven modification API (YRD7) — typed edits over any path, without a generated facade. |
| `SpecValidator`, `SpecDerivedNumber` | Validates a document's values against the model (typed values and references under review read as their old value); `derivedNumbers` gives the values `countOf`, `productOf` and `rankOf` call for. |
| `SomTextPattern`, `SomPatternError` | The portable pattern subset — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (`java.util.regex` is a different grammar, and its case folding is Unicode-wide where the contract stops at ASCII). |
| `SpecQuery`, `SpecQueryEngine`, `SpecQueryCursor`, `SpecQueryMatch` | The lexical/structural query surface plus the flat tier-1 node projection. |
| `SpecNodeCreator`, `SpecCreationError`, `SpecCreationCode` | The constrained node-creation gate (`checkAddNode`, `add`) — a document may only grow in ways the model permits. |
| `SpecDocumentYaml` | Byte-stable `*.tomspecs.yaml` codec (`SOM §12`). |
| `SpecDocumentMarkdown` | Meta-data-driven Markdown import/export codec (`SOM §11`): the emitter writes the reading view's form tables, record tables, reference lines and section tables with an anchor in every heading, a value no table cell holds as a `Field:` paragraph (SOM §11.2, §11.4, §11.5); the parser reads them and the older `Field:` layout; an import accepting rejections keeps each rejected block as a `rejected` div for review (SOM §11.7); a stripped rendition's readable header and styled-div headings below level six are written on request (`headingDivs`, `readableHeader`) and read back, its appendix not read (SOM §11.1, §11.2); the anchors below a list item and in a `@SameAs` copy are qualified, a `linked` marker follows each markable heading and the generated parts open their sections (SOM §11.2, §11.11, §11.12; options `linkedMarkers`, `generatedParts`), all removed on parse. The package-private `SpecDocumentMarkdownLinked` (the navigation: qualified anchors, the marker's entries `Also in`, `Summary of`, `Summarised in`, `Derived from`, `Extracted from`, `Copy of`, `Copied to`, the summary rows' `Id` links) and `SpecDocumentMarkdownGenerated` (the requirement views' tables in `derived` blocks) serve it. |
| `SomNode`, `SomScalar`, `SomList`, `SomFacade` | Editing-facade base types for the generated `tom_som_java_v0`. |
| `SomEditability`, `SomVersionError` | `SOM §4.2` version-check outcome enum (non-throwing `SomFacade.somEditabilityFor`) and its throwing error. |
| `SpecAnnotations`, `KindLink`, `NoArtifactLink` | The annotation lookups shared by `SpecClass` and `SpecField`, including the three routing verdicts of `codespecs_mapping.md` §8.3 (`@CodeSpecKind` / `@FollowUpKind` / `@NoArtifact`). |
| `CodeSpecsExtractor`, `CodeSpecsExtract`, `CodeSpecsAreaCatalog`, `CodeSpecsArea`, `CodeSpecsSlice`, `CodeSpecsStep`, `CodeSpecsRouting`, `CodeSpecsExtractEntry`, `CodeSpecsExtractError` | The Phase-4 CodeSpecs specification-extract generator: per area, every value the document routes there — verbatim, with provenance — plus its YAML and Markdown artifacts. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `SpecGenerationUnits`, `SpecGenerationUnit`, `SpecGenerationUnitMapping` | The generation-unit register of a document (SOM §11.2): `specGenerationUnits` reads each unit (`SpecGenerationUnit`: id, kind, mappings per area, the standard emitters it ships), recognised by `@NoArtifact(generation)` as validation phase 8 recognises it; `specDefaultUnits` is the default destination of an area — the extract fills an entry's `units` from it when no section stores units. `SPEC_STANDARD_EMITTERS` lists the standard emitters (`openapi`, `jsonschema`, `icu`, `asyncapi`, `markdown`); phase 8 reports any other as `unitEmitterUnknown`. |
| `SpecImpactWalk`, `SpecImpactRootWalk`, `SpecImpactRow`, `SpecImpactRowKind`, `SpecImpactLevel`, `SpecImpactLevelDocument`, `SpecImpactFolder` | The impact walk of the `tom_specs` change mode: `specImpactWalk` lists every section of every document root of the model for a specification (a root without a document over an empty one) — section-id chain, class, fill state, value count, CodeSpecs routing — and an empty list of sections as a template `<list>/*`; `specImpactLevel` records how far the project has come from a listing of its spec root; `specImpactDocumentFiles` finds the current documents in that listing; `specImpactWalkMarkdown` writes the table. The routing verdict is shared with the extractor as `CodeSpecsRouting.codeSpecsClassRouting` / `codeSpecsFieldRouting`. Pure (no IO). |
| `CodeSpecsGate`, `CodeSpecsGateReport`, `CodeSpecsGateCheckResult`, `CodeSpecsGateFinding`, `CodeSpecsGateCheck`, `CodeSpecsFieldRef`, `CodeSpecsRequiredArgument`, `CodeSpecsCarrier` | The Stage-A gate (`codespecs_prompt.md` §4, A1–A5) run as one over model, document, catalogue and DocSpecs schema: every check runs, a check that cannot run is reported not run, and the report carries the extracts when A3 passed. A4/A5 read the catalogue's optional `gate` tables. |
| `CodeSpecsExtract.fromYaml`, `CodeSpecsGateRecord`, `CodeSpecsGateEntry`, `CodeSpecsGateVerdict`, `CodeSpecsExtractSet`, `CodeSpecsExcludedArea`, `CodeSpecsRecordError` | Reading a Phase-4 run back: an extract file (the inverse of `toYaml`, refusing an unknown `formatVersion`), the Stage-B gate record `gate.verdicts.yaml` (read, checked, edited with `withVerdict`, written byte-stable) and a set of extracts scoped by that record (`fromFiles`, `fromDirectory`), with the excluded areas kept visible. |
| `SpecReviewAnnotations`, `SpecReviewAnnotation`, `SpecReviewAnnotationKind` | Review annotations (SOM §11.9): comments, questions and their answers (team and individual), inline marks, in headlines too under `K_SPEC_HEADLINE_FIELD`, conflict blocks, change times and attribution. |
| `SpecReviewMerge`, `SpecReviewMergeResult`, `SpecReviewMergeReport`, `SpecReviewMergeOptions` | Team review (SOM §11.9.8): `SpecReviewMerge.mergeReviews` merges the returned copies of a round into one document (or Markdown file) with votes, individual answers and conflict blocks. |
| `SpecAnswers`, `SpecAnswerExtract`, `SpecAnswerEntry` | A review round's answers (SOM §11.9.7): `extractAnswers` and `renderAnswers` (`answers.md`). |
| `SomMetaTree`, `SomMetaNode`, `SomMetaKind`, … | The metadata tree the YAML codec and the facade navigate by. |
| `SomMetaBridge` | `buildSomMetaTree` — the metadata tree of a model, for one root or all. |
| `SpecMetaDiff` | `somMetaNodeDiff` — the first difference between two metadata trees (form fields compared with their `code` and `multiParagraph` flags). |
| `SpecSectionId`, `SpecSectionIdCollision` | List-item section ids (AA1): `generateListItemSectionId`, `effectiveListItemSectionId`. |
| `SpecSerializationOrder` | The model's member order, which every codec writes in. |
| `DocSpecsDocument`, `DocSpecsValidator`, `DocSpecsViolation` | DocSpecs Markdown documents: the schema-free parse (`DocSpecsDocument.parse`) and the schema check, with the nine reading-notation rules (`new DocSpecsValidator(schema, true)`: scanned per form-field value, unknown kinds and classless divs reported); it reads the reading view's form tables, list bodies (`refs`, `records`), section tables and styled-div headings; a stripped rendition's readable header and appendix are skipped. |
| `SpecDocumentStrip`, `SpecStripOptions`, `SpecStripTextResult`, `SpecStripPiece`, `SpecAppendixEntry`, `SpecStripUsageError`, `SpecStripResult`, `SpecStripValueRef`, `SpecStrippedValue`, `SpecStripKept`, `SpecStripFinding`, `SpecReadableHeader`, `SpecReadableSource` | Stripped renditions (SOM §11.10): `SpecDocumentStrip.stripNotationText` drops, unmarks or moves to an appendix the secondary prose of named kinds of one value (`SpecStripOptions.fromNames`), reporting the removed pieces with their UTF-16 offsets; `SpecDocumentStrip.strip` strips a whole document with the emptying rule and writes its readable rendition, the readable header (`SpecReadableHeader`) and the appendix *Notes* included (`SpecStripResult`); dropping or unmarking `linked` / `derived` leaves the markers / generated parts out. |
| `SpecStripMerge`, `SpecStripMergeOptions`, `SpecStripMergeResult`, `SpecStripMergedValue`, `SpecStripMergeRefusal`, `SpecStripValueMerge`, `SpecStripMergePlaced`, `SpecStripMergeConflict` | The merge back (SOM §11.10): `SpecStripMerge.mergeStrippedValue` merges one edited value onto its original, `SpecStripMerge.merge` an edited `.readable.md` onto its document — pieces put back or placed, conflicts and refused edits reported, a stale original merged three ways from the original at the export (`SpecStripMerge.gitShowFile` reads it from git; `SpecStripMergeResult.report()`, `exitCode()`). |
| `SpecNotation`, `NotationScan`, `NotationElement`, `NotationFinding`, `NotationFindingCode` | The reading notation's scanner (DocSpecs Reading Notation): `SpecNotation.scanNotation` returns a value's divs, spans and citations (`NotationElement`, UTF-16 ranges) and the notation's findings (`NotationFinding`, `NotationFindingCode`, `notationSeverity`), which the DocSpecs validator reports as rules; `registeredNotationKinds`. |
| `SpecSchemaValidation` | `validateSpecDocument` — the DocSpecs schema tier over a document's Markdown rendition. |
| `Yaml` | The YAML reader the codec uses (`Yaml.parse`, typed for the review pass, SOM §12.5). |

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

The section-automation tables of this port run in the same runner: the
link readers and the place / filter grammar (`link_reader_cases.json`),
`validateLinks` (`link_validation_cases.json`), the typed inline marks (the
`typedCases` of `inline_mark_cases.json` / `change_mark_cases.json`), the
document set with `syncReport` and `renameId` (`document_set_cases.json`),
`deriveFields` (`derive_cases.json`), `prefill` and `backfill`
(`prefill_cases.json`, `backfill_cases.json`), the rendition's navigation
and generated parts (`link_rendition_cases.json`, and the schema tier over the
real model's renditions with and without them, `uam_requirements_cut.json`) —
over the fixture model `corpus/links.meta.json` and, for the cases naming it,
the real model of `tom_som_dart_v0/meta/`. `SpecPlaceTest`,
`SpecLinkValidatorTest`, `SpecDocumentSetTest`, `SpecDeriveFieldsTest`,
`SpecPrefillBackfillTest`, `SpecDocumentMarkdownLinkedTest` and
`SpecDocumentMarkdownGeneratedTest` hold the Java surface around them.

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
| `SpecDocumentAssembly` | One document from fragments written in parallel (`SpecDocument.assemble`) — refusing any place two fragments both write. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated classes. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `SpecValidator` | The instance tier: a filled document's values checked against the model; `validateLinks`, the link checks of one document (`tom_specs_model_rules.md` §9.7). |
| `SpecPlace`, `SpecPlaceFilter` | The place and filter grammar the link annotations are written in, resolved without reading a value. |
| `SpecDocumentSet`, `SpecDeriveFields`, `SpecPrefill`, `SpecBackfill` | The documents of a project side by side: the shared places compared (`syncReport`), an id renamed everywhere (`renameId`), a document's derived places written (`deriveFields`), the Blueprint into a new Phase 3 document (`prefill`) and the accepted Phase 3 end state back (`backfill`). |
| `SpecDocumentYaml` | Byte-stable `*.tomspecs.yaml` encode/decode. |
| `SpecDocumentMarkdown` | DocSpecs-conform Markdown export, parse and round-trip. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SpecGenerationUnit` | One generation unit of a document's register, with its mapping per area and its standard emitters (`SpecGenerationUnits.specGenerationUnits`). |
| `SpecImpactWalk` | The impact walk of a specification — every section of every document root, with its fill state and CodeSpecs routing, and the project's level. |
| `CodeSpecsExtractSet` | The extracts of one run read back and scoped by their gate record. |
| `CodeSpecsGate` | The Stage-A gate — A1–A5 over model, document, catalogue and schema, all run, none failing fast. |
| `SomNode` / `SomScalar` / `SomList` | The editing-facade base types the generated `tom_som_java_v0` classes extend. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──tomspecs :som-generate──▶ tom_som_java_v0
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
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.tomspecs.md` and `*.tomspecs.yaml` formats, the validator, and the conformance corpus. |
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

Version **1.13.0**, tracking the TomSpecs model version. Requires JDK ≥ 17
(verified with `javac`/`java` 21). Covered by 23 test files; the conformance
runner reports **OK: 2501 checks passed** and `./run_tests.sh` is green.
