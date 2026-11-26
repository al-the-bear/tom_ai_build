# tom_som_rust_runtime — generic Rust SOM runtime

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

Generic TomSpecs object-model runtime (Rust port). Paths, model, reflection,
document, validator, YAML/Markdown codecs; zero external dependencies (standard
library only).

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this crate) holding everything that is the same
everywhere, and a generated `tom_som_rust_v0` facade holding the typed structs
for one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator; with it, the generator emits only
what actually changes when the model changes.

This crate is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime), and of the Python, Java,
JavaScript, TypeScript and Go ports — it invents nothing, and "faithful" is a
measured claim rather than an intention: every port is validated against the same
goldens, byte for byte (`SOM §19`). Reach for it directly when you drive the
generic API by section path; otherwise depend on the typed facade, which pulls
this in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the crate is a layer over it —
the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated structs, the byte-stable YAML and Markdown codecs, the
editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
structs** — those belong to the per-language `tom_som_<lang>_v0` crates.

## Installation

```toml
[dependencies]
tom_som_rust_runtime = { path = "../tom_som_rust_runtime", version = "1.1.0" }
```

The crate is `publish = false` (proprietary). The version tracks the TomSpecs
**model version**, and `tom_som_rust_v0` pins the same one — upgrade both
together (`SOM §4.2`). See
[readme_howtointegrate.md](readme_howtointegrate.md) for the crates.io / git /
path routes, version pinning, and `cargo package` from source.

## Features

### Modules

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.rs` | The section-path grammar (root / child / list-item segments). |
| `spec_model.rs` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_model_links.rs` | The typed link readers (`tom_specs_model_rules.md` §9.7): `SpecSync` (`SpecListRelation`), `SpecSummaryOf`, `SpecDerivation`, `SpecInverseOf`, `SpecExtractsLinks`, `SpecSameAs`, read through `synced_with`, `summary_of`, `derived_from`, `extracts_links`, `same_as` on classes and fields and the form-field qualifiers `derived_from` / `inverse_of` / `summary_of`; a string → string argument keeps the meta's order. |
| `spec_place.rs` | The place and filter grammar of the link vocabulary: `SpecPlace` and `SpecPlaceFilter` (`|` alternatives) resolved under an anchor without reading a value (`SpecPlaceResolution`, `SpecPlaceError` with its `SPEC_PLACE_PROBLEM_*`), `spec_same_as_bindings`, `spec_section_positions`. |
| `spec_links_validator.rs` | `validate_links` — the link checks of one document: derived values against their sources, summaries against their detail lists, each end of a link against the other, ids named in a text against the link rows, `@SameAs` copies against their holders, pending changes read with every mark rejected; `SpecLinkValidator` collects beside each finding the fix `deriveFields` writes (`SpecLinkFix`). |
| `spec_document_set.rs` | A project's specification documents read side by side, one per root (`SpecDocumentSet`, built from documents, fragments or files), and their validation: `sync_report` compares the places each Phase 3 document shares with the Solution Blueprint, pair by pair, and checks the links across two documents (`SpecSyncReport`, `SpecSyncFinding`); `rename_id` renames a section id in every document at once. |
| `spec_derive_fields.rs` | `derive_fields` — the derived places of one document written, plain or as inline marks: link ends and generated rows, derived values and lists, summary repeats, `@SameAs` copies, counts, products and ranks (`SpecDeriveResult`, `SpecDeriveChange`). |
| `spec_backfill.rs` | `backfill` — the accepted end state of the Phase 3 documents carried into the Blueprint as plain values, with a revision entry (`SpecBackfillResult`, `SpecBackfillLeft`); refused while a document holds review marks. |
| `spec_prefill.rs` | `prefill` — a Phase 3 document started from the Blueprint: the pairs holding nothing yet filled once, the derived places derived (`SpecPrefillResult`). |
| `spec_reflection.rs` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, node-kind constants). |
| `spec_document.rs` | A sparse in-memory document — values keyed by section path. `SpecDocument::move_list_item` moves a list item to another position of its list, or into another list of the same element class: the affected lists are renumbered, every value under each item travels with it, and an anonymous item whose position changed keeps its old id (`SpecListItemMove`; refusals are `SpecListMoveError`). `rekey_review` (`spec_document_yaml.rs`) re-keys a `review:` pass with the move's `renamed` pairs. |
| `spec_document_assembly.rs` | Assembling one document from fragments written in parallel (`SpecDocument::assemble`, `assemble_spec_documents`): a refusing merge of the plain-data stores — a content path, form field, list, headline or code-spec location two fragments both write is a `SpecAssemblyOverlap`, and an assembly with any overlap has no document. |
| `spec_typed_values.rs` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.rs` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.rs` | Validates a document's values against the model; a typed value or reference holding inline marks is read as its old value (SOM §11.9.3), a `countOf` target as a `SpecPlaceFilter`. `spec_derived_numbers` gives the value every `countOf`, `productOf` and `rankOf` field calls for. |
| `spec_text_pattern.rs` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (std ships no regex, and the `regex` crate would be both a dependency this crate does not take and a different grammar). |
| `spec_query.rs` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.rs` | The constrained node-creation gate (`check_add_node`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.rs` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — one verbatim, provenance-carrying extract per CodeSpecs area. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_generation_units.rs` | The generation-unit register of a document (SOM §11.2): `spec_generation_units` reads each unit (`SpecGenerationUnit`: id, kind, mappings per area, the standard emitters it ships), recognised by `@NoArtifact(generation)` as validation phase 8 recognises it; `spec_default_units` is the default destination of an area — the extract fills an entry's `units` from it when no section stores units. `SPEC_STANDARD_EMITTERS` lists the standard emitters (`openapi`, `jsonschema`, `icu`, `asyncapi`, `markdown`); phase 8 reports any other as `unitEmitterUnknown`. |
| `spec_impact_walk.rs` | The impact walk of the `tom_specs` change mode: `spec_impact_walk` lists every section of every document root of the model for a specification (a root without a document over an empty one) — section-id chain, class, fill state, value count, CodeSpecs routing — and an empty list of sections as a template `<list>/*`; `spec_impact_level` records how far the project has come from a listing of its spec root; `spec_impact_document_files` finds the current documents in that listing; `spec_impact_walk_markdown` writes the table. Pure (no IO). |
| `spec_codespecs_gate.rs` | The Stage-A gate (`codespecs_prompt.md` §4, A1–A5): `CodeSpecsGate::new(model, document, catalog, schema, root_type).run()` returns a `CodeSpecsGateReport` — every check runs, a check that cannot run is reported not run, and the report carries the extracts when A3 passed. A4/A5 read the catalogue's optional `gate` tables (`CodeSpecsRequiredArgument`, `CodeSpecsCarrier`). |
| `spec_codespecs_records.rs` | Reading a Phase-4 run back: `CodeSpecsExtract::from_yaml` (the inverse of `to_yaml`, refusing an unknown `formatVersion`), the Stage-B gate record `gate.verdicts.yaml` (`CodeSpecsGateRecord`: read, checked, edited with `with_verdict`, written byte-stable) and `CodeSpecsExtractSet` (`from_files`, `from_directory`) — the extracts scoped by that record, with the excluded areas kept visible. Every reader returns `Result<_, CodeSpecsRecordError>`. |
| `spec_document_yaml.rs` | Byte-stable `*.tomspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.rs` | Meta-data-driven Markdown import/export codec (`SOM §11`): the emitter writes the reading view's form tables, record tables, reference lines and section tables with an anchor in every heading, a value no table cell holds as a `Field:` paragraph (SOM §11.2, §11.4, §11.5), and with `SpecMarkdownExportOptions` styled-div headings below level six and a readable header (SOM §11.1, §11.2); the parser reads them, styled-div headings and the older `Field:` layout, skips a readable header and stops at the appendix marker; an import accepting rejections keeps each rejected block as a `rejected` div for review (SOM §11.7). |
| `som_facade.rs` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList<T>`) for the generated `tom_som_rust_v0`. |
| `yaml.rs` | Hand-rolled, dependency-free reader for the constrained docspecs YAML subset. |
| `json.rs` | Hand-rolled, dependency-free JSON reader/encoder (Rust std ships no JSON). |
| `spec_review_annotations.rs` | Review annotations (SOM §11.9): comments, questions and their answers (team and individual), inline marks, conflict blocks, change times and attribution (`SpecReviewAnnotations`). |
| `spec_review_merge.rs` | Team review (SOM §11.9.8): `merge_reviews` / `merge_reviews_markdown` merge the returned copies of a round into one document with votes, individual answers and conflict blocks. |
| `spec_answers.rs` | A review round's answers (SOM §11.9.7): `extract_answers` and `render_answers` (`answers.md`). |
| `spec_meta.rs` | The metadata tree types (`SomMetaTree`, `SomMetaNode`, …) the YAML codec and the facade navigate by. |
| `spec_meta_bridge.rs` | `build_som_meta_tree` — the metadata tree of a model, for one root or all. |
| `spec_meta_diff.rs` | `som_meta_node_diff` — the first difference between two metadata trees, or `None` (form fields compared with their `code` and `multi_paragraph` flags); `som_meta_node_diff_at` names the starting position. |
| `spec_document_strip.rs` | Stripped renditions (SOM §11.10). The strip of one value: `strip_notation_text(value, &options)` drops, unmarks or moves to the appendix the secondary prose of the named kinds (`provenance`, `trace`, `editorial`, `aside`, `linked`, `derived`, `comments`) and returns a `SpecStripTextResult` — the text, the counts per kind, `marks_dropped`, the appendix entries (`SpecAppendixEntry`) and the pieces it removed (`SpecStripPiece`, UTF-16 offsets); a value with a notation error is refused unchanged. `SpecStripOptions::from_names` reads the kind names a user gives (`all`, comma-joined lists) and refuses a misuse with `SpecStripUsageError`. The strip of a document: `SpecDocumentStrip::strip` strips every value into a copy with the emptying rule and writes its readable rendition, the readable header (`SpecReadableHeader`, `SpecReadableSource`) and the appendix *Notes* included (`SpecStripResult`). |
| `spec_document_merge.rs` | The merge back of an edited stripped rendition (SOM §11.10): `merge_stripped_value` puts one value's removed pieces back into its edited text (`SpecStripValueMerge`, `SpecStripMergePlaced`, `SpecStripMergeConflict`); `SpecStripMerge::merge` merges an edited readable rendition onto its document — the switches from the readable header, a stale original merged three ways from a base (`SpecStripMergeOptions`, `SpecStripMerge::git_show_file`), structural edits refused (`SpecStripMergeRefusal`), the result checked (`SpecStripMergeResult` with `merged`, `report()`, `exit_code()`; `SpecStripMergedValue`, `spec_strip_merge_label`). |
| `spec_notation.rs` | The reading notation's scanner (DocSpecs Reading Notation): `scan_notation` returns a value's divs, spans and citations (`NotationElement`, UTF-16 ranges) and the notation's findings (`NotationFinding`, `NotationFindingCode`, `notation_severity`), which the DocSpecs validator reports as rules. |
| `spec_section_id.rs` | List-item section ids (AA1): `generate_list_item_section_id`, `encode_two_letter_date`, `effective_list_item_section_id`, `K_SECTION_ID_SLOT`. |
| `spec_serialization_order.rs` | `SpecSerializationOrder` — the model's member order, which every codec writes in. |
| `docspecs_validator.rs` | DocSpecs Markdown documents: the schema-free parse (`parse_docspecs_document`, `DocSpecsDocument`) and the schema check (`DocSpecsValidator`), with the nine reading-notation rules (`DocSpecsValidator::with_tom_specs(schema, true)`: scanned per form-field value, unknown kinds and classless divs reported); it reads the reading view's form tables, list bodies (`refs`, `records`), section tables and styled-div headings. |
| `spec_schema_validation.rs` | `validate_spec_document` — the DocSpecs schema tier over a document's Markdown rendition. |

## Quick start

```rust
use tom_som_rust_runtime as som;

let mut doc = som::SpecDocument::new();
doc.set_content("SBP/content", "A unifying order platform.");
println!("{}", doc.content_or("SBP/content"));
// A unifying order platform.
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
structs involved:

```rust
let model = som::SpecModel::from_json_str(&meta_json).unwrap();
let reflection = som::SpecReflection::new(&model);

println!("{}", reflection.resolve("SBP/content").is_some());
// true
println!("{}", som::validate_document(&model, &doc).is_empty());
// true
```

### Zero external dependencies

The crate depends only on the Rust standard library — no `serde`, `serde_json`,
`serde_yaml`, or `regex`. JSON parsing uses the hand-rolled `json` module; YAML
uses the hand-rolled `yaml` module (the constrained docspecs subset). Byte-stable
`*.tomspecs.yaml` output requires a `js_json_string` that matches JavaScript's
`JSON.stringify` exactly — it delegates to `json::encode_str`, which emits the
short escapes for `" \ \b \f \n \r \t`, control characters below `0x20` as
lowercase `\u00xx`, and every other char (including `< > & /` and all non-ASCII)
verbatim. The regex-driven Markdown anchors of the reference are replaced by
hand-rolled scanners (`heading_path`, `field_anchor`, `fence_open`, `item_seg`).

### Rust-specific surface

Rust has ownership, `Result`, and reserved keywords, so the facade differs from
the other ports in idiomatic ways the emitter mirrors:

- **Shared document via `Rc<RefCell<SpecDocument>>`** — aliased as `DocRef`. A
  child facade clones the `Rc` (a cheap reference-count bump) and every read or
  write borrows the cell, so a mutation through the typed surface is immediately
  visible through the generic path and vice-versa.
- **No `doc`/`path` name guard** — generated accessors reference the bound
  document explicitly through the embedded `SomNode` (`self.node`), so a method
  named `doc` or `path` cannot shadow anything. This is a deviation from the
  Go/TypeScript ports, which need a reserved-name guard.
- **`Result` instead of exceptions** — the version check returns
  `Result<(), SomVersionError>`; `SomVersionError` implements `std::error::Error`.
- **Reserved-keyword collisions** are resolved by the emitter with a trailing
  underscore (`type_`, `match_`, `self_`, `move_`, …).

### Consumed by `tom_som_rust_v0`

The generated typed model depends on this crate via a relative path dependency in
the `v0` crate's `Cargo.toml`
(`tom_som_rust_runtime = { path = "../tom_som_rust_runtime" }`), keeping the
generated source path-free and golden-stable.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```bash
cargo build                                 # compile the runtime
cargo test                                  # the whole suite
cargo test --test conformance -- --nocapture # → "OK: N checks passed"
./run_tests.sh                              # conformance + the per-module suites
```

The conformance test reproduces every golden byte-for-byte and exercises the same
cases as the Dart/Python/Java/JavaScript/TypeScript/Go runners: model meta-data
load, `state.json` round-trip, YAML encode/decode, Markdown export/round-trip,
the **Markdown→memory landing** check (the `md.land.*` shared contract — parsing
`expected.tomspecs.md` lands the same memory as the YAML route), reflection resolution,
validation, the imperative operations script, and the **Phase-4 CodeSpecs tier**
(the routing diagnostic, the per-area extracts with their YAML/Markdown goldens,
the "copied, never composed" guard and the `ROUTE-TOTAL` error cases), and the
reading back of extracts and the gate record (`codespecs_record_cases.json`).

The section-automation tables run in `tests/conformance_links/mod.rs` — the
link readers and the place / filter grammar (`link_reader_cases.json`),
`validate_links` (`link_validation_cases.json`) and the typed inline marks
(`typedCases`) — and in `tests/conformance_document_set/mod.rs` — the document
set, its report and the global rename (`document_set_cases.json`),
`derive_fields` (`derive_cases.json`), `prefill` and `backfill`
(`prefill_cases.json`, `backfill_cases.json`) — over the fixture model
`corpus/links.meta.json` and, for the cases naming it, the real model of
`tom_som_dart_v0/meta/`.

## Architecture

```
        typed path                          generic path
   tom_som_rust_v0        ─────▶   SomNode / SomScalar / SomList<T>
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml.rs
  SpecQueryEngine      validate_document   spec_document_markdown.rs
        │
        ▼
     SpecModel  ◀── meta/spec_model.meta.json
```

| Type | Responsibility |
| ---- | -------------- |
| `SpecDocument` | The sparse, path-keyed store of a document's content, form and list values. |
| `SpecDocument::assemble` | One document from fragments written in parallel — refusing any place two fragments both write. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated structs. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `validate_document` | The instance tier: a filled document's values checked against the model. |
| `validate_links` | The link checks of one document (`tom_specs_model_rules.md` §9.7), with the fixes `deriveFields` writes collected by `SpecLinkValidator`. |
| `SpecPlace` / `SpecPlaceFilter` | The place and filter grammar of the link annotations, resolved under an anchor without reading a value. |
| `SpecDocumentSet` / `sync_report` | A project's documents read side by side, and the places the Phase 3 documents share with the Solution Blueprint compared (`tom_specs_model_rules.md` §9.7). |
| `derive_fields` / `backfill` / `prefill` | The writes of the section automation: a document's derived places, the Phase 3 end state into the Blueprint, a Phase 3 document started from the Blueprint. |
| `spec_document_yaml` | Byte-stable `*.tomspecs.yaml` encode/decode. |
| `spec_document_markdown` | DocSpecs-conform Markdown export (the reading view's tables), parse (the tables and the older `Field:` lines, rejected blocks kept for review) and round-trip. |
| `strip_notation_text` | The strip of one value (SOM §11.10): secondary prose dropped, unmarked or moved to an appendix, with the pieces that went. |
| `SpecDocumentStrip` | The strip of a whole document (SOM §11.10): the stripped copy, the emptying rule, the appendix and the readable rendition with its readable header, checked to read back and validate. |
| `SpecStripMerge` | The merge back (SOM §11.10): an edited readable rendition merged onto its document, every piece the strip removed put back (`merge_stripped_value` for one value), conflicts, placed pieces and refused edits reported. |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SpecGenerationUnit` | One generation unit of a document's register, with its mapping per area and its standard emitters (`spec_generation_units`). |
| `CodeSpecsExtractSet` | The extracts of one run read back and scoped by their gate record. |
| `CodeSpecsGate` | The Stage-A gate — A1–A5 over model, document, catalogue and schema, all run, none failing fast. |
| `SomNode` / `SomScalar` / `SomList<T>` | The editing-facade base types the generated `tom_som_rust_v0` structs embed. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──tomspecs :som-generate──▶ tom_som_rust_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ depends on
                                                                  ▼
                                                     tom_som_rust_runtime  ← this crate
                                                                  │ validated against
                                                                  ▼
                                                         tom_som_conformance
                                                          (shared corpus)
```

## Further documentation

**TomSpecs subject matter** — the authorities this crate implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs subject-matter document, and the `§` citation convention. |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.tomspecs.md` and `*.tomspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the reference host. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |

**This crate** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_rust_v0](../tom_som_rust_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.13.0**, tracking the TomSpecs model version. Covered by 18 test files;
the conformance runner reports **OK: 5643 checks passed** and `./run_tests.sh` is
green.
