# tom_som_c_runtime — generic C SOM runtime

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

Generic TomSpecs object-model runtime (C). Paths, model, reflection, document,
validator, YAML/Markdown codecs; zero external dependencies (C standard library
only).

## Where this fits

TomSpecs specifications are documents with a *typed shape*: a spec model
describes which sections exist, what each may contain and how it serializes. The
SOM makes that model usable from nine languages, and each language is a **pair**
— a hand-written runtime (this library) holding everything that is the same
everywhere, and a generated `tom_som_c_v0` facade holding the typed accessors for
one model version. Without the split, every regeneration would rewrite the
document store, the codecs and the validator; with it, the generator emits only
what actually changes when the model changes.

This library is a faithful transcription of the Dart reference,
[`tom_som_dart_runtime`](../tom_som_dart_runtime), and of the Python, Java,
JavaScript, TypeScript, Go and Rust ports — it invents nothing, and "faithful" is
a measured claim rather than an intention: every port is validated against the
same goldens, byte for byte (`SOM §19`). Reach for it directly when you drive the
generic API by section path; otherwise link the typed facade, which links this
in.

## Overview

A SOM document is **sparse and path-keyed**: values live in three stores
(content, form fields, list sequences) under the globally-unique section-ID path
they belong to, and an absent key means "no value" rather than an empty one.
`SpecDocument` is that store. Everything else in the library is a layer over it —
the meta-model (`SpecModel`, `SpecReflection`) that makes generic navigation
possible without generated structs, the byte-stable YAML and Markdown codecs, the
editing and validation tiers, and the Phase-4 CodeSpecs extractor.

It holds **no document values of its own** and contains **no generated typed
structs** — those belong to the per-language `tom_som_<lang>_v0` projects.
`include/tom_som_c_runtime.h` is the umbrella header; the per-module headers may
also be included directly.

## Installation

C has no package registry, so the library is distributed as a library + headers +
pkg-config file, or as a source tarball:

```sh
make install PREFIX=/usr/local   # headers, static/shared libs, and the .pc file
make dist                        # build/tom_som_c_runtime-<version>.tar.gz
```

`make install` honours `DESTDIR` for staged / packaged installs and lays down the
versioned `.so` soname symlinks. The pkg-config `Version` tracks the TomSpecs
**model version**, and `tom_som_c_v0` pins the same one — upgrade both together
(`SOM §4.2`). See [readme_howtointegrate.md](readme_howtointegrate.md) for the
pkg-config / vendored-tarball / in-tree-monorepo routes and how to pin.

## Features

### Modules

| File | Responsibility |
| ---- | -------------- |
| `spec_paths.c` | The section-path grammar (root / child / list-item segments). |
| `spec_model.c` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_model_links.c` | The typed link readers (`tom_specs_model_rules.md` §9.7): `SpecSync` (`SpecListRelation`), `SpecSummaryOf`, `SpecDerivation`, `SpecInverseOf`, `SpecExtractsLinks`, `SpecSameAs`, read through `spec_annotations_synced_with`, `_summary_of`, `_derived_from`, `_extracts_links`, `_same_as` over a class's or a field's annotations and the form-field qualifiers `derived_from` / `inverse_of` / `summary_of`; a string → string argument keeps the meta's order (`SpecStringPairs`). |
| `spec_place.c` | The place and filter grammar of the link vocabulary: `SpecPlace` and `SpecPlaceFilter` (`\|` alternatives) resolved under an anchor without reading a value (`SpecPlaceResolution`, `SpecPlaceError` with its `SPEC_PLACE_PROBLEM_*`), `spec_same_as_bindings`, `spec_section_positions`. |
| `spec_links_validator.c` | `spec_validate_links` — the link checks of one document: derived values against their sources, summaries against their detail lists, each end of a link against the other, ids named in a text against the link rows, `@SameAs` copies against their holders, pending changes read with every mark rejected; `SpecLinkValidator` collects beside each finding the fix `deriveFields` writes (`SpecLinkFix`, an `addRow`'s values and a derived list's tuple places in their write order). |
| `spec_document_set.c`, `spec_document_set_check.c` | The document set (`tom_specs_model_rules.md` §9.7): a project's documents read side by side, one per root (`SpecDocumentSet`, from documents, fragments or files; its anchor pairs `SpecSyncPair`); `spec_sync_report` — the shared places of each pair compared element by element and value by value, the summaries and inverses across two documents checked, pending and unmarkable values listed (`SpecSyncReport`, `SpecSyncFinding`); `spec_rename_id` — an id renamed in every document at once. |
| `spec_derive_fields.c` | `spec_derive_fields` — the derived places of one document written in three steps from the link fixes `SpecLinkValidator` collects, in their write order: plain or as inline marks under review, in place or as a dry run. |
| `spec_backfill.c` | `spec_backfill` — the accepted Phase 3 end state carried into the Blueprint as plain values, with a revision entry; what it leaves is listed with the reason. |
| `spec_prefill.c` | `spec_prefill` — a Phase 3 document started from the Blueprint: the pairs that hold nothing yet filled once, then derived. |
| `spec_reflection.c` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, node-kind constants). |
| `spec_document.c` | A sparse in-memory document — values keyed by section path. |
| `spec_document_assembly.c` | Assembling one document from fragments written in parallel (`spec_document_assemble`) — a refusing merge of the plain-data stores: any place two fragments both write is a `SpecAssemblyOverlap`, and an assembly with an overlap yields no document. |
| `spec_typed_values.c` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided; also the tagged `SomValue` typed positions travel as. |
| `spec_editor.c` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.c` | Validates a document's values against the model; a typed value or reference holding inline marks is read as its old value (SOM §11.9.3), a `countOf` target as a `SpecPlaceFilter`. `spec_derived_numbers` gives the value every `countOf`, `productOf` and `rankOf` field calls for. |
| `spec_text_pattern.c` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (standard C has no regex at all, and POSIX `regex.h` would be both a dependency and a different grammar). |
| `spec_query.c` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.c` | The constrained node-creation gate (`spec_check_add_node`, `spec_node_creator_add`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.c` | The Phase-4 CodeSpecs specification-extract generator (`CodeSpecsExtractor`) — routes every section by `@CodeSpecKind` / `@FollowUpKind` / `@NoArtifact` and emits one verbatim, provenance-carrying extract per CodeSpecs area. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_generation_units.c` | The generation-unit register of a document (SOM §11.2): `spec_generation_units` reads each unit (`SpecGenerationUnit`: id, kind, mappings per area, standard emitters — `SPEC_STANDARD_EMITTERS`), recognised by `@NoArtifact(generation)` as validation phase 8 recognises it; `spec_default_units` is the default destination of an area — the extract fills an entry's `units` from it when no section stores units. |
| `spec_impact_walk.c` | The impact walk of the `tom_specs` change mode: `spec_impact_walk` lists every section of every document root of the model for a specification (a root without a document over an empty one) — section-id chain, class, fill state, value count, CodeSpecs routing (`spec_codespecs_class_routing` / `spec_codespecs_field_routing`, shared with the extractor) — and an empty list of sections as a template `<list>/*`; `spec_impact_level` records how far the project has come from a listing of its spec root; `spec_impact_document_files` finds the current documents in that listing; `spec_impact_walk_markdown` writes the table. Pure (no IO); every result has its `*_free`. |
| `spec_codespecs_records.c` | Reads Phase-4 output back: `spec_codespecs_extract_from_yaml` (the inverse of `spec_codespecs_extract_to_yaml`), the Stage-B gate record `gate.verdicts.yaml` (`CodeSpecsGateRecord` — read, checked, written byte-stable), and `CodeSpecsExtractSet`, a set of extract files scoped by its gate record. Failures fill a `CodeSpecsRecordError`. |
| `spec_codespecs_gate.c` | The Stage-A gate (`CodeSpecsGate`, `codespecs_prompt.md` §4): runs A1 (DocSpecs completeness of the rendered Markdown), A2 (`validate_document`), A3 (every section routed, then the extraction), A4 (required marker arguments populated, from the catalogue's `gate` tables) and A5 (carriers still in the model) as one, reporting a not-run check as not run. |
| `spec_document_yaml.c` | Byte-stable `*.tomspecs.yaml` codec (`SOM §12`). |
| `spec_document_markdown.c` | Meta-data-driven Markdown import/export codec (`SOM §11`): the emitter writes the reading view's form, records and section tables and reference lines, with an anchor in every heading (SOM §11.4, §11.5), and with `spec_markdown_export_root_with_options` styled-div headings below level six and a readable header (SOM §11.1, §11.2), the file stem and document files of links to another document root, and the navigation and generated parts on or off; the parser reads them, the older `Field:` layout, removes the `linked` marker and the generated blocks, and skips a readable header and a stripped rendition's appendix. |
| `spec_document_markdown_linked.c` | The rendition's navigation, internal to the codec: qualified anchors, the `linked` marker's entries `Also in`, `Summary of`, `Summarised in`, `Derived from`, `Extracted from`, `Copy of`, `Copied to` (SOM §11.11), the summary rows' `Id` links. |
| `spec_document_markdown_generated.c` | The rendition's generated parts, internal to the codec: the requirement views' tables in `derived` blocks (SOM §11.12). |
| `som_facade.c` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList`) for the generated `tom_som_c_v0`. |
| `yaml.c` | Hand-rolled, dependency-free reader for the constrained docspecs YAML subset. |
| `som_json.c` | Hand-rolled, dependency-free JSON reader/encoder (C ships none). |
| `som_util.c` | C-only support: `SomBuf` (string builder), `SomStrList`, `SomMap` (byte-sorted), small numeric/string helpers. |
| `spec_review_annotations.c` | Review annotations (SOM §11.9): comments, questions and their answers (team and individual), inline marks, conflict blocks, change times and attribution (`spec_review_annotations_make`, `spec_review_annotations_list`, …). |
| `spec_review_merge.c` | Team review (SOM §11.9.8): `spec_review_merge_documents` / `spec_review_merge_markdown` merge the returned copies of a round into one document with votes, individual answers and conflict blocks. |
| `spec_answers.c` | A review round's answers (SOM §11.9.7): `spec_extract_answers` and `spec_render_answers` (`answers.md`). |
| `spec_meta.c` | The metadata tree types (`SomMetaTree`, `SomMetaNode`, …) the YAML codec and the facade navigate by. |
| `spec_meta_bridge.c` | `som_build_meta_tree` — the metadata tree of a model, for one root or all. |
| `spec_meta_diff.c` | `som_meta_node_diff` — the first difference between two metadata trees, or NULL. |
| `spec_section_id.c` | List-item section ids (AA1): `spec_generate_list_item_section_id`, `spec_effective_list_item_section_id`, `spec_section_id_pattern_prefix`. |
| `spec_serialization_order.c` | The model's member order, which every codec writes in (`spec_serialization_order_paths`, `spec_serialization_order_order_key`, `spec_serialization_order_form_fields`). |
| `docspecs_validator.c` | DocSpecs Markdown documents: the schema-free parse (`docspecs_parse_document`, `docspecs_document_all_sections`) and the schema check (`docspecs_validator_new`, `docspecs_validator_new_with` for a TomSpecs rendition, `docspecs_validator_validate_markdown`), the reading notation's nine rules included; it reads both form layouts, `refs` / `records` list bodies, section tables and styled-div headings (SOM §14), and the rendition's `linked` marker and generated blocks as no text. |
| `spec_document_merge.c` | The merge back (SOM §11.10): `spec_merge_stripped_value` puts the pieces of one value's strip back into its edited text, `spec_strip_merge` merges an edited readable rendition onto its document (three ways from the original at the export when it moved, structural edits refused, the result checked to strip back), `spec_strip_merge_git_show_file` reads that original from git. |
| `spec_document_strip.c` | Stripped renditions (SOM §11.10): `spec_strip_notation_text` drops, unmarks or moves secondary prose and review annotations of one value per `SpecStripOptions` (`spec_strip_options_from_names`), returning the stripped text, its pieces and appendix entries; `spec_document_strip` strips a whole document with the emptying rule and writes its readable rendition, the readable header (`spec_readable_header_format` / `_parse`) first and the appendix *Notes* last. |
| `spec_notation.c` | The reading notation's scanner (DocSpecs Reading Notation RN-1 to RN-13): `spec_scan_notation` returns a value's fenced divs, bracketed spans and citation shapes, nested, with byte and UTF-16 offsets, and its findings. |
| `spec_schema_validation.c` | `validate_spec_document` — the DocSpecs schema tier over a document's Markdown rendition. |

## Quick start

```c
#include "tom_som_c_runtime.h"

SpecDocument doc;
spec_document_init(&doc);
spec_document_set_content(&doc, "SBP/content", "A unifying order platform.");
printf("%s\n", spec_document_content(&doc, "SBP/content"));
// A unifying order platform.
spec_document_free(&doc);
```

## Usage

### The generic path

Load the exported class graph, then resolve paths against it — no generated
structs involved:

```c
char *err = NULL;
SpecModel *model = spec_model_from_json_str(meta_json, &err);
SpecReflection reflection = spec_reflection_make(model);

SpecResolution res;
printf("%d\n", spec_reflection_resolve(&reflection, "SBP/content", &res));
// 1
spec_resolution_free(&res);

SpecValidationErrors errs;
validate_document(model, &doc, &errs);
printf("%zu\n", errs.len);
// 0
spec_validation_errors_free(&errs);
```

### Zero external dependencies

The library depends only on the C standard library. JSON parsing uses the
hand-rolled `som_json` module; YAML uses the hand-rolled `yaml` module (the
constrained docspecs subset). Byte-stable `*.tomspecs.yaml` output requires a
`js_json_string` that matches JavaScript's `JSON.stringify` exactly — it
delegates to `som_json_encode_str`, which emits the short escapes for
`" \ \b \f \n \r \t`, control characters below `0x20` as lowercase `\u00xx`, and
every other char (including `< > & /` and all non-ASCII) verbatim. The
regex-driven Markdown anchors of the reference are replaced by hand-rolled
scanners (`heading_path`, `field_anchor`, `fence_open`, `item_seg`).

### C-specific surface

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
- **The YAML codec carries the `review:` pass** — decode returns it (plain
  scalars typed the way the Dart reference's YAML reader types them), encode
  writes it back with the canonical writer, and a stale-paths function reports
  review entries whose path no longer resolves (`SOM §12.1`). The runtime does
  not interpret the entries.

### Building and running the tests

Correctness is defined by the shared, language-agnostic conformance corpus in
[`tom_som_conformance/corpus`](../tom_som_conformance), generated from the Dart
reference. This port is validated against the exact same goldens every other port
uses (`SOM §19`):

```sh
make                 # builds the static + shared library + pkg-config file
make test            # builds + runs the conformance harness → "OK: N checks passed"
make unit            # builds + runs the standalone unit tests
./run_conformance.sh # same as `make test`, via the wrapper script
./run_tests.sh       # conformance + the per-module suites
```

`make` produces `build/libtom_som_c_runtime.a` (static),
`build/libtom_som_c_runtime.so` (shared), and `build/tom_som_c_runtime.pc`
(pkg-config metadata whose `Version` tracks the TomSpecs model version).

The conformance harness (`tests/conformance.c`) reproduces the same checks as
every other port — model meta, `state.json` round-trip, YAML encode/decode,
Markdown export/parse/landing, reflection, validation, the imperative operations
script, the generic editing script (`SpecEditor`), and the Phase-4 CodeSpecs
extract generator and reading its extracts and gate record back. Exit 0 == all green.

The section-automation tables of this port so far run in
`tests/conformance_links.h` (included by the harness): the link readers and the
place / filter grammar (`link_reader_cases.json`), `spec_validate_links`
(`link_validation_cases.json`) and the typed inline marks (the `typedCases` of
`inline_mark_cases.json` / `change_mark_cases.json`); and in
`tests/conformance_document_set.h`: the document set, its report and the global
rename (`document_set_cases.json`), `spec_derive_fields` (`derive_cases.json`),
`spec_prefill` and `spec_backfill` (`prefill_cases.json`,
`backfill_cases.json`); and in `tests/conformance_rendition.h`: the
rendition's navigation and generated parts (`link_rendition_cases.json`, and
the schema tier over the real model's renditions with and without them,
`uam_requirements_cut.json`) — over the fixture model
`corpus/links.meta.json` and, for the cases naming it, the real model of
`tom_som_dart_v0/meta/`. `tests/spec_document_markdown_linked_test.c` and
`tests/spec_document_markdown_generated_test.c` hold the C surface around the
rendition.

The corpus directory can be overridden:

```sh
make test CORPUS=/path/to/corpus
./run_conformance.sh /path/to/corpus
```

## Architecture

```
        typed path                          generic path
     tom_som_c_v0         ─────▶   SomNode / SomScalar / SomList
            │                                   │
            └───────────────┬───────────────────┘
                            ▼
                      SpecDocument         sparse, path-keyed value stores
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
  SpecReflection       SpecEditor          spec_document_yaml.c
  SpecQueryEngine      validate_document   spec_document_markdown.c
        │
        ▼
     SpecModel  ◀── meta/spec_model.meta.json
```

| Type | Responsibility |
| ---- | -------------- |
| `SpecDocument` | The sparse, path-keyed store of a document's content, form and list values. |
| `spec_document_assemble` | One document from ordered name/document fragments; `SpecDocumentAssembly` carries the document or every overlap. |
| `spec_document_move_list_item` | Moves a list item within its list or to another list of its element class, renumbering the affected lists and carrying every value under each item; `SpecListItemMove` names the renames and pinned ids, and `spec_yaml_rekey_review` re-keys a `review:` pass by them. |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations. |
| `SpecReflection` | Resolves and enumerates paths against the model without reading values. |
| `SpecEditor` | Typed edits over any path, driven by the meta-model rather than by generated structs. |
| `SpecNodeCreator` | The creation gate — a document may only grow in ways the model permits. |
| `validate_document` | The instance tier: a filled document's values checked against the model. |
| `spec_validate_links` | The link checks of one document (`tom_specs_model_rules.md` §9.7), with the fixes `deriveFields` writes collected by `SpecLinkValidator`. |
| `SpecPlace` / `SpecPlaceFilter` | The place and filter grammar of the link annotations, resolved under an anchor without reading a value. |
| `SpecDocumentSet` / `spec_sync_report` | The documents of a project read side by side and their agreement checked, pair by pair and across two documents; `spec_rename_id` renames an id everywhere at once. |
| `spec_derive_fields` | Writes a document's derived places (link ends and rows, derived values, `@SameAs` copies, counts, products, ranks), plain or as marks. |
| `spec_prefill` / `spec_backfill` | A Phase 3 document started from the Blueprint; the accepted Phase 3 end state carried back into it. |
| `spec_document_yaml` | Byte-stable `*.tomspecs.yaml` encode/decode. |
| `spec_document_markdown` | DocSpecs-conform Markdown export, parse and round-trip; the rendition's navigation (`linked` marker, qualified anchors) and generated parts (SOM §11.11, §11.12). |
| `SpecQueryEngine` | Lexical/structural search over a document, matching with `SomTextPattern`. |
| `CodeSpecsExtractor` | The Phase-4 extract generator — one verbatim, cited extract per CodeSpecs area. |
| `SpecGenerationUnit` | One generation unit of a document's register, with its mapping per area and the standard emitters it ships (`spec_generation_units`). |
| `SpecImpactWalk` / `SpecImpactLevel` | The impact walk of a specification (one `SpecImpactRootWalk` of `SpecImpactRow`s per document root) and the project's level beside it (`spec_impact_walk`). |
| `CodeSpecsGateRecord` / `CodeSpecsExtractSet` | The Stage-B gate record, and the extract files of one run read back and scoped by it. |
| `CodeSpecsGate` | The Stage-A gate — A1–A5 over model, document, catalogue and schema, one report. |
| `SomNode` / `SomScalar` / `SomList` | The editing-facade base types the generated `tom_som_c_v0` accessors build on. |

## Ecosystem

```
  tom_specs_model ──▶ tom_specs_clitool ──tomspecs :som-generate──▶ tom_som_c_v0
   (the model)          (the generator)                     (typed facade)
                                                                  │ links
                                                                  ▼
                                                        tom_som_c_runtime  ← this library
                                                                  │ validated against
                                                                  ▼
                                                         tom_som_conformance
                                                          (shared corpus)
```

## Further documentation

**TomSpecs subject matter** — the authorities this library implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs subject-matter document, and the `§` citation convention. |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | What a SOM runtime must contain, the two access paths, the `*.tomspecs.md` and `*.tomspecs.yaml` formats, the validator, and the conformance corpus. |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | This language plane's build and verify toolchain, and the reference host. |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk schema of `meta/spec_model.meta.json`, which `SpecModel` loads. |

**This library** — its own guides:

| Guide | Covers |
|-------|--------|
| [readme_howtointegrate.md](readme_howtointegrate.md) | Every dependency route and how to pin the version. |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_c_v0](../tom_som_c_v0) | The generated typed facade over this runtime — the normal path. |
| [tom_som_cpp_runtime](../tom_som_cpp_runtime) | The idiomatic-C++ port transcribed from this one. |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The Dart reference this port transcribes. |
| [tom_som_conformance](../tom_som_conformance) | The shared corpus and the cross-language drivers that run every port against it. |

## Status

Version **1.13.0**, tracking the TomSpecs model version. Covered by 24 test
files; the conformance runner reports **OK: 4689 checks passed** and
`./run_tests.sh` is green.
