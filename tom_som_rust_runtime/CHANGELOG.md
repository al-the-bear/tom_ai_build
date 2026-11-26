# Changelog

## Unreleased

- **Section automation, second part** (`tom_specs_model_rules.md` §9.7),
  ported from the Go and Java runtimes (the Dart reference behind them).
  - The document set (the new module `spec_document_set`):
    `SpecDocumentSet` (`new`, `from_fragments`, `load` of YAML and SOM
    Markdown files, fragments of one root assembled; `blueprint`, `document`,
    `name_of`, `names`, `roots`, `missing_roots`, `pairs`, `put`, `get`,
    `root_of`) owning one document per root, refused with a
    `SpecDocumentSetError` (`SpecDocumentSetRefusal`: `sameRoot`, `noRoot`,
    `twoRoots`, `projection`, `overlap`, `unpairable`); the anchor pairs
    (`SpecSyncPair`) the Blueprint root's `basedOn` and the `@SyncedWith` /
    `@DetailedIn` classes give — 132 on the real model, with
    `D00SolutionBlueprint` as the Blueprint root.
  - `sync_report` (`SpecSyncReport`: `SpecSyncFinding` with its
    `SpecSyncCode`, `SpecSyncResolution`, `SpecSyncHolder` and two
    `SpecSyncPlace` sides, each document's own findings, the roots and pairs
    not started, `counts_by_code` / `counts_by_resolution`, `clean`): the
    shared places of every pair compared element by element and value by
    value (`equal` / `subset` / `superset` with `where`, `heldHere`,
    `detailOnly`, typed sameness), the summaries and inverses across two
    documents, the values pending review and the changes `derive_fields`
    could not mark. `rename_id` renames a section id in every document at
    once, refused with a `SpecRenameError` when the new id is taken. The
    comparison internals (`SpecSetCheck`, `SpecSetSide`, `SpecSetValue`,
    `SpecSetFound`) are public for `backfill` and `prefill`.
  - `derive_fields` (the new module `spec_derive_fields`): the derived places
    of one document in three steps, written plain or as inline marks
    (`SpecDeriveOptions`: `marked`, `author`, `at`, `dry_run`;
    `derive_fields_dry_run` works on a copy of a borrowed document), applying
    each `SpecLinkFix` in its recorded write order; `SpecDeriveResult` with
    its `SpecDeriveChange`s (`SpecDeriveChangeKind`: `value`, `rowAdded`,
    `rowRemoved`) and the changes it left (`unmarkable`,
    `derivedLookupMiss`). `SpecLinkValidator::rebind` / `adopt` let it read
    the document as it writes it, with the caches the run collected.
  - `backfill` (the new module `spec_backfill`): the accepted Phase 3 end
    state carried into the Blueprint, with a revision entry and the
    Blueprint's derived places rewritten (`SpecBackfillOptions`,
    `SpecBackfillResult` with its `SpecBackfillChange`s and the findings
    `SpecBackfillLeft` with their `SpecBackfillLeftReason`); a set holding
    marks or blocks, or no Blueprint, is refused with a `SpecBackfillError`
    (`setHasMarks`, `noBlueprint`). `spec_backfill_bump` gives the next
    version.
  - `prefill` (the new module `spec_prefill`): a Phase 3 document started
    from the Blueprint, the pairs holding nothing yet filled once and the
    document's derived places derived (`SpecPrefillOptions`,
    `SpecPrefillResult` with its filled and skipped pairs); refused with a
    `SpecPrefillError` (`noBlueprint`, `unknownRoot`).
  - `DocumentJson::to_json` gives the stores as their canonical JSON value;
    `FormFieldSpec` implements `Default`.
  - The conformance suite replays `document_set_cases.json`,
    `derive_cases.json`, `prefill_cases.json` and `backfill_cases.json`
    (`tests/conformance_document_set/mod.rs`; 5924 -> 6160 checks);
    `tests/spec_document_set.rs`, `tests/spec_derive_fields.rs` and
    `tests/spec_prefill_backfill.rs` are new.

- **Section automation, first part** (`tom_specs_model_rules.md` §9.7),
  ported from the Go and Java runtimes (the Dart reference behind them).
  - The typed link readers (the new module `spec_model_links`): `SpecSync`
    with `SpecListRelation`, `SpecSummaryOf`, `SpecDerivation`,
    `SpecInverseOf`, `SpecExtractsLinks`, `SpecSameAs`; `synced_with`,
    `summary_of`, `derived_from`, `extracts_links`, `same_as` and
    `annotations_named` on `SpecClass` and `SpecField`; the form-field
    qualifiers `FormFieldSpec::derived_from` / `inverse_of` / `summary_of`;
    `SpecClass::is_code_specs_projection`. A string → string argument
    (`repeats`, `map`, `set`) keeps the meta's order (`Vec<SpecStringPair>`,
    `spec_string_pair_value`).
  - The place and filter grammar (the new module `spec_place`): `SpecPlace`,
    `SpecPlaceResolution`, `SpecPlaceFilter` with `|` alternatives,
    `SPEC_PLACE_KIND_*`, `SPEC_PLACE_PROBLEM_*`, `SpecPlaceError`,
    `spec_same_as_bindings` (`SpecSameAsBinding`), `spec_section_positions`
    (`SpecSectionPosition`). `countOf` reads its targets as filters, `|`
    included; a target that is no filter makes the count undecidable.
  - `validate_links` (the new module `spec_links_validator`): derived copies,
    rows, lookups and lists, inverses named back, ids named in a text with
    their rows, summaries against their details, `@SameAs` copies against
    their holders, pending changes read with every mark rejected; eleven new
    `SPEC_VALIDATION_CODE_*` constants (`unmarkable` included, for
    `deriveFields`) and `spec_validation_code_index`; `SpecLinkValidator` with
    the fixes `deriveFields` will read (`SpecLinkFix`, the write order of a
    row's values and a list's tuples recorded in `value_keys` /
    `tuple_keys`) and its value readers; `spec_expand_pattern`,
    `spec_resolve_place_at`, `spec_resolve_link_place`, `spec_link_ids`,
    `spec_link_field_of`. `spec_derived_numbers` (`SpecDerivedNumber`) gives
    the values `countOf`, `productOf` and `rankOf` call for. Findings,
    messages, fixes and derived numbers agree with the Go runtime on every
    link-validation case, in both readings.
  - Typed values and references holding inline marks read as their old value
    until decided (`som_typed_reading`, `som_is_typed_field`; the parsers,
    the instance tier and the `@OneOf` discriminator, SOM §11.9.3). A
    headline takes inline marks under the reserved field
    `K_SPEC_HEADLINE_FIELD`, never a comment or question block.
  - The conformance suite replays `link_reader_cases.json`,
    `link_validation_cases.json` and the `typedCases` of
    `inline_mark_cases.json` / `change_mark_cases.json`
    (`tests/conformance_links/mod.rs`; 5643 -> 5924 checks);
    `tests/spec_place.rs` and `tests/spec_links_validator.rs` are new. The
    document set, `deriveFields`, `backfill`, `prefill` and the rendition's
    navigation follow.

- **The merge back of a stripped rendition** (SOM §11.10, the new module
  `spec_document_merge`): `merge_stripped_value(original, stripped, edited,
  &pieces)` puts the pieces one value's strip removed back into its edited
  text — between unchanged neighbours where they were, after an edited run as
  a placed piece (`SpecStripMergePlaced`), else a conflict
  (`SpecStripMergeConflict`: `crossesBoundary`, `sentenceRemoved`,
  `stripTextEdited`, `unplaceable`, `notation`, `annotations`) — and returns
  a `SpecStripValueMerge`; offsets count UTF-16 code units, as the strip's.
  `SpecStripMerge::merge(&original, edited, &SpecStripMergeOptions)` merges an
  edited readable rendition onto its document: the switches from the readable
  header (or given beside it, and then agreeing with it; neither is a
  `SpecStripUsageError`), a stale original (another `current_revision`, or a
  `base` given) merged three ways from the base given or loaded for the
  header's commit (`load_base`, a `SpecStripBaseLoader`, e.g. through
  `SpecStripMerge::git_show_file`, which runs `git show <commit>:./<name>` in
  the file's folder and refuses a commit starting with `-`), structural edits
  refused (`SpecStripMergeRefusal`: sections added, removed or moved, list
  items, `codeSpec`, `units`, rejected blocks, a stale original without a
  base, a base that does not strip), a wrapped paragraph read back on one
  line no edit (SOM §11.4 rule 13), and the result checked to change only the
  merged values, to strip back to the edited text and to add no finding.
  `SpecStripMergeResult` carries the merged document, the merged values
  (`SpecStripMergedValue`), `exit_code()` and `report()`;
  `spec_strip_merge_label` names a value in it. `annotation_issues_text`
  lists the malformed review annotations of one value. The strip's UTF-16
  helpers, edit scripts, mark finder, value references and tier findings are
  `pub(crate)` so the merge shares them. The conformance runner reads the
  `valueCases` (23) and `documentCases` (20) of `strip_merge_cases.json`
  (5598 -> 5643 checks); `tests/spec_document_merge.rs` covers the merge over
  the strip corpus, text beyond ASCII, the report lines and `git_show_file`
  in a scratch repository of its own.
- **The strip of a document** (SOM §11.10, stripped renditions):
  `SpecDocumentStrip::strip(&document, &options, &extra)` strips every
  content value, form field and stored headline into a copy and returns a
  `SpecStripResult`: the stripped document, the changed values
  (`SpecStrippedValue`), the counts per kind, the appendix (each entry's
  `value` a `SpecStripValueRef`), the readable header and, given a model in
  `SpecDocumentStripOptions`, the readable rendition and its findings
  (`SpecStripFinding`: `notation`, `instance`, `schema`, `parse`; `ok()`).
  With a model the emptying rule applies: a value whose strip would add an
  instance or schema finding is stripped with the keeping options instead
  (`SpecStripKept`), or keeps its original; list items left with nothing go
  (`removed_items`); the appendix is numbered in rendition order and written
  after its marker as *Notes* under the section titles; the rendition must
  read back as the stripped document and add no finding. `report()` lists
  what went per kind. `SpecAppendixEntry::value` is now a typed
  `SpecStripValueRef` (`{path, field?, headline?}` in JSON).
- **The readable header and styled-div headings** (SOM §11.1, §11.2):
  `SpecReadableHeader::format` / `parse` (with `SpecReadableSource`) write and
  read `<!-- readable: … -->`; `SpecMarkdownExportOptions` (through
  `SpecDocumentMarkdown::with_export_options` or
  `export_root_with_options`) writes it after the `docspec` line and writes
  sections deeper than level six as `<div class="heading<N>" …>` lines, a
  value line shaped like one escaped. The parser reads the div headings
  back, skips the readable header (`SpecMarkdownResult::readable_header`)
  and stops at the appendix marker (`SPEC_MARKDOWN_APPENDIX_MARKER`) after
  one; so does `parse_docspecs_document`. `SpecDocument::root_to_export`
  names the root `to_markdown` exports. `SpecReviewAnnotations::stripped()`
  is now the strip with `drop: [comments]`, so stored headlines lose their
  annotations too. The conformance runner reads the `headerCases` and
  `documentCases` of `strip_cases.json` and runs the last three
  `readingView` import cases, so no `readingView` case is skipped any more
  (5531 -> 5598 checks); `tests/spec_document_strip.rs` covers the div
  writer, the readable header, the appendix, the checks and `stripped()`.
- **The strip of one value** (SOM §11.10, stripped renditions): the new
  module `spec_document_strip` with `strip_notation_text(value, &options)`,
  which drops, unmarks or moves to the appendix the secondary prose of the
  named kinds — the notation kinds `provenance`, `trace`, `editorial` and
  `aside`, `linked` and `derived` (removed by drop and unmark alike) and
  `comments` (the review annotations, stripped first) — then the whitespace
  the removals leave, and returns a `SpecStripTextResult`: the text, the
  counts per kind (`dropped`, `unmarked`, `appended`), `marks_dropped` (review
  marks that went inside a dropped element), the appendix entries
  (`SpecAppendixEntry`, numbered from 1, optionally linked from the text by
  `appendix_references`) and the pieces it removed (`SpecStripPiece`: anchor
  and origin in UTF-16 code units, removed and inserted text, labels). A
  value whose notation has an error finding is refused unchanged.
  `SpecStripOptions` holds the drop, unmark and appendix sets,
  `appendix_references` and `heading_divs`; `from_names` reads the names a
  user gives (comma-joined, `all`) and refuses a misuse with
  `SpecStripUsageError`; `keeping`, `in_entry`, `ordered`, `to_json`,
  `writes_no_linked_markers` and `writes_no_generated_parts` complete it.
  `count_annotations_text` counts what `strip_annotations_text` removes. The
  conformance runner reads the `cases` and `usageCases` of `strip_cases.json`,
  each case's pieces putting the original back (5447 -> 5531 checks);
  `tests/spec_document_strip.rs` covers supplementary characters, a refused
  value and the options.
- **Rejected blocks kept for review** (SOM §11.7, DocSpecs RN-11): the parse
  result carries `kept_content`, and an apply that accepts rejections
  (`apply_markdown_result(&result, true)`, which `SpecDocument::from_markdown`
  uses) keeps each rejected block as a
  `::: {.rejected reason=… line=… label=…}` div in the text of the section it
  stood in, else its parent, at its place: an unknown section (nested unknown
  sections in order), a row naming no field (with `field` when it is one edit
  from a declared field), a field given twice (with `field` and `kept`, the
  form holding the kept value), a table without its delimiter row, a records
  div or row that does not read, an unclosed records fence (escaped), text
  before the root heading, a child heading under a value leaf. The DocSpecs
  validator reports each kept block as `rejectedBlock`. The conformance runner
  runs the 15 `readingView` cases of `markdown_apply_cases.json` with their
  `rejectedBlocks`; `tests/spec_document_markdown_rejected_kept.rs` covers the
  re-import of a kept document.
- **The Markdown emitter writes the reading view's tables** (SOM §11.4,
  §11.5), as Dart and TypeScript do: form tables `| TomSpecField | Value |`
  between `Field:` paragraphs, record tables in a `::: {.records}` div,
  reference lines in a `::: {.refs}` div (reference ids as links to their
  section), section tables `| Section | TomSpecField | Value |`, and an HTML
  anchor in every heading (`<a id="ID"></a>`, qualified below a list item and
  in a `@SameAs` copy, SOM §11.2). A value that cannot be one table cell (a
  `multi_paragraph` field, several paragraphs, a block, a line shaped like a
  layout header) stays a `Field:` paragraph; a wrapped one-paragraph value is
  one cell (`SpecDocumentMarkdown::wrapped_paragraph_joined`, SOM §11.4 rule
  13). The parser still reads both layouts. The conformance runner's emitted
  layout is `tables`: the export is held to `expected.tables.md` and
  `answer_cases.json` / `codespecs_gate_cases.json` are read from their
  `expectTables` results.
- **The DocSpecs validator reads the reading view** (DocSpecs specification,
  List Bodies): form tables give a section's fields (a field missing from table
  and paragraphs is `missingRequiredField`, a pattern mismatch points at its
  row, a field given twice keeps the first), `refs` lines and `records` tables
  become a list's virtual items (counted towards `min-count`, the container
  passes `max-text-length 0`; a record table reads the item type's own form
  only), section tables give children's fields at their rows (`unknownSection`
  for a row naming no child), styled-div headings `<div class="heading7">`
  count at their level and a `heading6` div is content; a heading's own anchor
  is stripped from its title (`DocSpecsDocument::strip_own_anchor`). Two new
  rules: `DOCSPECS_RULE_MALFORMED_BLOCK` (`malformedBlock`) and
  `DOCSPECS_RULE_UNKNOWN_FIELD` (`unknownField`), in `DOCSPECS_ALL_RULES`. A
  leading `linked` marker and `derived` block of a body are not read as text,
  and an empty body passes the text-length bounds (only `text-required` asks
  for text). The Markdown codec's layout-line helpers are shared with the
  validator. The conformance runner runs all 25 `readingView` cases of
  `docspecs_cases.json`.
- **The Markdown parser reads the reading view's table layout** (SOM §11.4,
  §11.5): form tables `| TomSpecField | Value |` (a code span holding `\|`,
  reference links read as their link texts, the prose before and after a
  table as the form's preamble, a slot marker before a form table), record
  tables in a `::: {.records}` div (an `Id` column, a `Title` column or none,
  `<br>` titles), reference lines in a `::: {.refs}` div, section tables
  `| Section | TomSpecField | Value |`, and heading anchors `<a id="ID">`
  equal to the id or its qualified form removed from the title. Two new
  rejection reasons, `SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD` (`unknownField`: a
  row or a records column naming no field) and
  `SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK` (`malformedBlock`: a table without
  its delimiter row, a row of another cell count, a field given twice — the
  first is kept —, the malformed `refs` and `records` divs); the older
  `Field:` layout reads as before. `SpecDocumentMarkdown::layout_table_header`
  tells a layout table's header line. The emitter escapes a value line shaped
  like a layout table header with one space, which the parser removes. The
  conformance runner reads the 28 `readingView` cases of
  `markdown_import_cases.json` that are not the readable header's or the
  styled-div headings', and lands `expected.tables.md` in the document the
  `Field:` golden lands (`md.land.tables.*`).
- **The reading notation's scanner** (DocSpecs specification, Reading
  Notation RN-1 … RN-13): `spec_notation.rs` with `scan_notation(text,
  tom_specs)` returning a `NotationScan` — the value's fenced divs, bracketed
  spans and citation shapes as `NotationElement`s (kind, classes, id,
  attributes, UTF-16 ranges, lines, nesting) and its `NotationFinding`s
  (`NotationFindingCode`, `notation_severity`), with
  `registered_notation_kinds` (`REGISTERED_NOTATION_KINDS`). Offsets are
  UTF-16 code units as in every other runtime, although Rust strings are
  UTF-8; whitespace, `trim` and `.` follow JavaScript. The embedded DocSpecs
  validator reports its nine notation rules (`unclosedDiv`, `unclosedSpan`,
  `strayClosingFence`, `divWithoutKind`, `unknownKind`, `annotationInsideDiv`,
  `divInsideAnnotation`, `markAcrossNotation`, `rejectedBlock`; the
  `DOCSPECS_RULE_*` constants, in `DOCSPECS_ALL_RULES`) per value: a section's
  own body, and with `DocSpecsValidator::with_tom_specs(schema, true)` (which
  `validate_spec_document` uses) each form field's value apart; a div without
  a class and an unregistered kind are reported only then. The conformance
  runner reads both tables of `notation_cases.json`, and the DocSpecs case
  `readingView: rejected block` runs.
- **The form-field meta's `multi_paragraph` flag** (`Field.multiParagraph`, a
  value of paragraphs or blocks): read from `spec_model.meta.json` into
  `FormFieldSpec` and `SomFormFieldMeta` beside `code`, carried by the bridge,
  written into the generated `_v0` meta tree, and compared — with `code`,
  which it did not compare before — by `som_meta_node_diff`.

- **Section order and unique id paths in the DocSpecs validator** (SOM §14,
  the DocSpecs specification's Validation Rules 3 and 5): two new rules,
  `sectionOutOfOrder` (the root's children follow `document: sections:`; a
  slot declared `position: any`, new on the schema's document sections, stands
  anywhere, and any other `position` is refused at load) and `duplicateIdPath`
  (a section whose id repeats an earlier sibling's; the same id under two
  parents is valid). The conformance corpus covers both.

- SOM documents are named `*.tomspecs.yaml` / `*.tomspecs.md`: the YAML encoder's
  header line names `*.tomspecs.yaml`, and the impact walk discovers
  `*.tomspecs.yaml` documents in a spec root's `phase*` folders.
- `spec_impact_walk.rs`: the impact walk of the `tom_specs` change mode —
  `spec_impact_walk`, `spec_impact_level`, `spec_impact_document_files`,
  `spec_impact_walk_markdown` (`impact_walk_cases.json`). The routing verdict
  is shared with the extractor as `code_specs_class_routing` /
  `code_specs_field_routing`, re-exported from the crate root.

- `SPEC_VALIDATION_ALL_CODES`: every `SPEC_VALIDATION_CODE_*` constant, in
  declaration order — the enumerable vocabulary Dart has from its enum, as
  `DOCSPECS_ALL_RULES` is for the §14 rules. A test reads the constants and
  fails when a code is missing from the list.
- `som_format_double` writes a finite double in the one layout of every
  runtime (`1e-7`, `1e+21`, `1.5e-300`; it wrote them in full fixed notation)
  (`typed_value_cases.json`).
- `markdown` is a standard emitter (`SPEC_STANDARD_EMITTERS`: `openapi`, `jsonschema`,
  `icu`, `asyncapi`, `markdown`): a generation unit may name it, and the
  validator no longer reports it as unknown. It is the IR's Markdown rendering
  (`tomspecs :ir-emit --standard markdown`, DocSpecs `irspecs-md/1.0`).
- Public and re-exported from the crate root, as TS exports them: `yaml_key`,
  `write_scalar` and `write_header` (both appending to a `String`, like
  `write_review_pass`), `review_scalar`, `format_yaml_float` (was
  `review_float`), `SpecDocumentMarkdown::code_spec_of` / `units_of`, and
  `code_specs_yaml_string` (was the crate-private `yaml_string`).
- Re-exported from the crate root: `SPEC_PATH_SEPARATOR`, the
  `SPEC_NODE_KIND_*` and `SPEC_FIELD_KIND_*` constants, `K_SECTION_ID_SLOT`,
  `effective_list_item_section_id`, and all 21 `SPEC_VALIDATION_CODE_*`
  values (9 were).
- Breaking: `som_meta_node_diff` returns `Option<String>`, `None` when the
  trees agree (TS `null`; it returned `""`). `som_meta_node_diff_at(a, b, at)`
  starts the position at `at` instead of `<root>`.
- Tests: `tests/exports.rs` (the surface above) and
  `tests/codespecs_extract_directory.rs` (`CodeSpecsExtractSet::from_directory`
  against `from_files` over the corpus scope cases).

- Typed values follow the canonical (TypeScript) reading: `som_parse_int` /
  `som_parse_double` / `som_parse_num` trim the text and refuse NaN, Infinity,
  hexadecimal and digit separators (shared corpus `typed_value_cases.json`).
- `SomList::add_with_id` and `add_content_with_id` on a list without a
  `@SectionIdPattern` ignore the id and append plainly, as TS and Dart do; they
  used to store it.

## 1.12.0

- `merge_reviews`: the question proposing a guest reviewer offers three answers —
  (a) yes, from now on (recommended), (b) yes, the next round only, (c) no
  (SOM §11.9.9), as in the eight other runtimes and the review-merge corpus.
- Moves in lockstep with `tom_specs_model` 1.12.0 (an entity's datasource,
  schema and tenancy in `DAENT-IDEN`; `TDIP` routed to dataAccess as well).

## 1.11.0

- The generation units carry the standard emitters they ship
  (`SpecGenerationUnit::emitters`, `SPEC_STANDARD_EMITTERS`), and validation
  phase 8 reports `unitEmitterUnknown` for an emitter that is none of
  `openapi`, `jsonschema`, `icu`, `asyncapi`, as in `tom_som_dart_runtime`
  1.11.0.

## 1.10.0

- The generation-unit register reader and the CodeSpecs extract's default
  units, as in `tom_som_dart_runtime` 1.10.0: an entry with no stored `units`
  carries every unit whose mappings hold its area.
- Moves with `tom_specs_model` 1.10.0 (no model change). Additive.

## 1.9.0

- Moves with `tom_specs_model` 1.9.0 (the generation-unit register and
  `RevisionEntry.changeId`).
- The `units` member of every section (SOM §11.2), beside `codeSpec`: the
  generation units that take the section where that differs from its area's
  default. `units(path)`, `set_units(path, value)` (empty clears),
  `units_paths()`; `SomNode::units()` / `set_units()`. The heading comment
  carries it after `codeSpec` (`units="a,b"`), the YAML node a `units:` key
  after `codeSpec:`, the snapshot a `units` key after `codeSpecs`; Markdown
  apply, list moves, prefix purge, assembly and review merge carry it as they
  carry `codeSpec`.
- Validation phase 8 (generation units): `unknownUnit`, `unitsUnrouted`,
  `duplicateUnitId`, `unitBuildsNothing`, `unitAreaMalformed`. The register is
  recognised by `@NoArtifact(generation)` with the form field `unitId` (a
  mapping by `area`), never by class name.
- CodeSpecs extract entries carry `units`, the nearest stored units at the
  entry's section or above: `units: [..]` after `routingNote` in the YAML, a
  `- units:` line after the routed-by line in the Markdown, each only when
  set; the reader reads it back. `formatVersion` stays 3.
- The `codeSpec` heading key is read as its pattern reads it: a quote that is
  never closed is a bare value (it used to give no value).

## 1.8.1

- No change of structure: the chain moves with `tom_som_dart_runtime` 1.8.1
  (the Dart-only process-check library `spec_checks.dart`). This runtime is
  unchanged.

## 1.8.0

- Plain YAML scalars (SOM §12.5): whether a non-text value (int, double,
  bool, enum member name, scalar list item) is written plain is decided by an
  explicit rule, the new public `is_plain_yaml_scalar`, and no longer by
  re-reading the scalar with the runtime's own YAML reader, which let through
  values a standard YAML parser rejects (`a: b`, `x #y`, a leading backtick). The rule
  also keeps out indicators, the YAML 1.1-only boolean words and sexagesimal
  numbers, and core-schema values (null, bool, number) that are not in their
  canonical print, so every runtime writes the same bytes.
- Question and team-answer times (SOM §11.9.2, §11.9.10): a question header
  may carry its time after the id, `**❓ BQ-1 (2026-11-07T14:05+01:00) —
  topic:**`, and the team answer in its label, `**Answer
  (2026-11-07T14:05+01:00):**` (a parenthesis holding only a time is the team
  answer). `insert_question` and `insert_question_after_comment` take a new
  `at: Option<&str>` and write the header time; `set_answer` /
  `set_answer_by` without an author write the team answer with a time
  (reopening writes `**Answer:**`); `format_question_block` takes the time to
  write after the id. A question lists `changed_at` (header) and the new
  `answer_changed_at`, and `merge_reviews` gives a copy's team answer its time
  when it writes it as an individual answer. A header parenthesis holding no
  time is malformed.

## 1.7.4

- Change times (SOM §11.9.10): comment headers, attribution tokens and
  individual answers carry the time of their last change next to the author
  (`(Alexis, 2026-11-07T14:05+01:00)`, `{@alice 2026-11-07T14:05+01:00}`,
  `**Answer (alice, 2026-11-07T14:05+01:00):**`). `insert_comment`,
  `edit_comment`, `comment_change`, `edit_mark_comment`, `set_marked`,
  `mark_against` and `set_answer_by` (with an author) write it, from their new
  `at` argument or the clock of `SpecReviewAnnotations::with_clock`;
  `set_marked` keeps the token of a mark it writes again unchanged, and
  `set_marked` / `mark_against` take an `author` and return a `Result`.
  `format_comment_block` takes a `changed_at`. `changed_at` on
  `SpecReviewAnnotation`, `SpecMarkEntry` and `SpecIndividualAnswer`;
  `merge_reviews` carries a copy's times over. New: `normalize_review_time`,
  `is_review_time`, `system_review_time`.
- Edge spaces after punctuation (SOM §11.9.3): whitespace written inside a
  change mark beside the text a decision keeps is kept as one space after
  `.,;:!?)]}` and before a word or `(` / `[`, so accepting
  `sentence.{++ Next sentence.++}` gives `sentence. Next sentence.` rather than
  `sentence.Next sentence.`. A mark written without it stays joined.

## 1.7.3

- No change. The chain moves with `tom_specs_model` 1.7.3, whose shipped
  tests are corrected.

## 1.7.2

- Comments on changes (SOM §11.9.3): a comment mark that starts with a quote
  of the change before it (`{~~ 30 ~> 15 ~~}{>> [~~ 30 ~> 15 ~~] why? <<}`)
  is that change's comment. `list_marks()` reports `quoted_change`,
  `comment_id` and `change_id`; deciding the change leaves the comment with
  the outcome in its quote; accept all / reject all leave change comments and
  remove all removes them; `set_marked` keeps them. New: `comment_change`,
  `edit_mark_comment`, `decide_all_marks_text`. A malformed quote is an
  `annotationMalformed` finding.

## 1.6.2 – 1.7.1

- Team reviews (SOM §11.9.8): `SpecReviewAnnotations` reads attribution
  tokens after marks (`authors` and `votes`, `SpecMarkVote`, in `list()` and
  `list_marks()`; the token goes with its mark on every decision),
  individual answers (`answers`, `SpecIndividualAnswer`; the question's text
  ends before them), conflict blocks (kind `Conflict`,
  `SpecConflictAlternative`, `decision_letter()`; `paragraphs()` marks them)
  and `open:` answers and decisions (`is_unresolved()`). `counts()` adds
  `unresolved_questions`, `conflicts` and `open_conflicts`.
  `set_answer_by(id, answer, author)` writes a member's individual answer by
  the grouping rules. `remove_all_annotations()` applies every decided
  conflict (`conflicts` in its report, `SpecConflictOutcome`) and now returns
  `Result`: it refuses while a conflict is open, unresolved or malformed.
  `validate_document` reports the team findings. The JSON forms gain
  `to_json_with(SpecReviewJsonOptions)` for the members the team cases pin.
  New exports: `format_conflict_block`, `is_review_member_id`,
  `SpecReviewJsonOptions`, `SpecConflictOutcome`. Conformance:
  `team_annotation_cases.json`.

- Merging reviewed copies (SOM §11.9.9), new module `spec_review_merge`:
  `merge_reviews(model, base, copies, options)` merges a `SpecDocument` (by
  model path, list items by section id; added items, structural conflicts and
  the draft revision entry included) and `merge_reviews_markdown(base,
  copies, options)` a plain annotated Markdown text (by heading path); both
  return `SpecReviewMergeResult` (`merged`, `report`:
  `SpecReviewMergeReport`). A copy that does not fit the base is refused with
  `SpecReviewMergeError`. Conformance: `review_merge_cases.json`.

- `SpecReviewAnnotations::paragraphs(path, field)` lists a value's
  paragraphs (`SpecParagraph`: `index`, `start_line`, `end_line`, `text`, and
  the `annotation` kind when the paragraph is an annotation block). The index
  is exactly what `after_paragraph` of the inserts takes, by the one rule of
  SOM §11.9.1 "Paragraphs". Conformance: a new `annotation_cases.json` case.

- Question options (SOM §11.9.2): a listed question carries its `options`
  (`SpecQuestionOption`: `letter`, `text` with continuation lines joined,
  `bold`), its `recommended` letter (the bold option, else the option that
  says "recommended", else the letter of a `*Recommendation:*` line) and
  `answer_letter()` (`(b)` or `**(b)**` at the start of the answer), all in
  `to_json()`. `SpecQuestionDraft::recommended` makes `format_question_block`
  write that option bold. `SpecQuestionOption` is re-exported at the crate
  root.

- Extracting answers for a step folder (SOM §11.9.7): the free function
  `extract_answers(model, doc, label, path)` collects a document's questions
  (answered and open), comments and inline marks, each with its section-id
  chain and its line in the Markdown rendition, as a `SpecAnswerExtract` of
  `SpecAnswerEntry`s (`SpecAnswerKind`, `SpecAnswerCounts`).
  `render_answers(extracts, options)` writes them as the step folder's
  `answers.md`; `SpecAnswerRenderOptions` adds the open questions and the
  inline marks and sets the title. The new module is `spec_answers`, its
  names re-exported from the crate root. The conformance runner replays
  `answer_cases.json`.

- Writing changes as inline marks (SOM §11.9.3): the free function
  `mark_change_text(old, new)` diffs by line, then by word, merging changes
  at most two words apart, so accepting all marks gives `new` and rejecting
  all gives `old`. Words are never split and code is never marked. It returns
  a `SpecMarkedChange` (`text`, `exact`). `SpecReviewAnnotations::set_marked`
  (a second edit updates its mark) and `mark_against` (against an earlier
  version) apply it to a value. Both new names are re-exported at the crate
  root. The conformance suite replays `change_mark_cases.json`.

- Reviewing inline marks (SOM §11.9.3): `SpecReviewAnnotations` gains
  `revision`, `list_marks`, `decide_marks` (accept / reject / leave in one
  write, `Err(SpecReviewAnnotationError)` on a stale revision or an unknown
  id), `accept_all_marks` / `reject_all_marks` under a path and
  `remove_all_annotations`, plus the free function `apply_inline_marks_text`.
  Each operation returns a `SpecMarkReport` (`SpecMarkOutcome`s and
  `SpecMarkIssue`s) for the decision log; marks are listed as `SpecMarkEntry`
  and decided with `SpecMarkDecision` (`Accept`, `Reject`, `Leave`). All are
  re-exported at the crate root. Accepting and rejecting follow the SOM
  §11.9.3 whitespace rules (words never join, no double space or space before
  punctuation, a whole-line mark leaves no blank line), and `apply_mark` and
  `strip_annotations_text` now follow them too. Malformed marks are left as
  written and reported. The conformance suite replays
  `inline_mark_cases.json`.

- Review annotations (SOM §11.9), ported from the Dart reference: the new
  module `spec_review_annotations` with `SpecReviewAnnotations` (`list`,
  `counts`, `next_comment_id`, `assign_comment_ids`, `insert_comment`,
  `insert_question`, `insert_question_after_comment`, `set_answer`,
  `edit_comment`, `resolve`, `apply_mark`, `stripped`, `validate`),
  `SpecReviewAnnotation`, `SpecReviewAnnotationKind`, `SpecMarkKind`,
  `SpecQuestionDraft`, `SpecReviewAnnotationCounts`,
  `SpecReviewAnnotationError`, `strip_annotations_text`,
  `format_comment_block`, `format_question_block` and
  `validate_review_annotations`, all re-exported at the crate root. Positions
  are 0-based line numbers within a value. `validate_document` reports the new
  `SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED` (`annotationMisplaced`),
  `SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED` (`annotationMalformed`) and
  `SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID` (`duplicateAnnotationId`) as
  its last group, after the derived values, ordered by path. The conformance
  suite runs every case of `annotation_cases.json`; the validation cases
  `annotationsWellFormed`, `annotationMisplaced`, `annotationMalformed` and
  `duplicateAnnotationId` pin the codes. Guide: `doc/review_annotations.md`.

- Single-reference fields (uamtc17): `FormFieldSpec::multiple` (meta
  `formFields[].multiple`, absent → false). `validate_document` reports the new
  `SPEC_VALIDATION_CODE_MULTIPLE_REFERENCES` (`multipleReferences`) in the reference phase: a reference field
  without `multiple` whose value splits on `,` into more than one non-empty
  id gets one error at the form path, checked before the registry-scope test;
  every id is still resolved, so dangling ones also report
  `danglingReference`. The corpus cases `multipleReferencesInSingleField` and
  `everyDanglingIdOfAList` pin it.

- Required form fields (uamtc16): `validate_document` reports the new
  `SPEC_VALIDATION_CODE_MISSING_REQUIRED_FIELD` (`missingRequiredField`) in
  the form-section step — for every form path the document holds that
  resolves to a form, each declared form field with `required` set (meta
  `formFields[].required`) whose value is absent or blank after trimming, in
  declared order. The corpus cases `requiredFieldsFilled`,
  `missingRequiredFieldInListItemForms` and `missingRequiredFieldInMemberForm`
  pin it; the corpus model holds 15 classes.
- Derived values (uamtc10): `FormFieldSpec::product_of` (meta
  `formFields[].productOf`, empty when absent) and `FormFieldSpec::rank_of`
  (meta `formFields[].rankOf`, `None` when absent). `validate_document`
  reports the new `SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH`
  (`derivedValueMismatch`) right after the count check, as one group ordered
  by form path: a `product_of` field must hold a number equal to the product
  of its operands (`f` of the same form, `F.f` of the sibling form `F`; an
  enum operand counts as its 1-based position) to the precision it is written
  in; a `rank_of` field must rank the instances of its form 1 to n, each
  once, with no instance ranked below one with a lower score. Undecidable
  operands skip the check; a stated value that is no number is always
  reported. Such fields are no longer reported as `valueTypeMismatch`. A
  `countOf` target written `./X` now counts only the entries beneath the
  section holding the form. Verified by the `derivedValuesMatch`,
  `productMismatch`, `rankOutOfOrder`, `rankDuplicate` and
  `scopedCountMismatch` validation cases.

- `SpecDocument::has_values_under` answers from a lazily built prefix index
  (every stored key of the five stores plus each prefix ending right before a
  `/` or `-`), built on the first query and dropped by every mutator, instead
  of scanning every stored key per call. Results are unchanged; rendering,
  validating or querying a large document is no longer quadratic.
- Exact markdown round trip (SOM §11.2, §11.3, §11.6, §11.7, §12.4): a heading
  body region whose text the parser would otherwise bind to another slot gets
  a slot marker line `<!-- slot: <rel> -->` (`.` for the owner's own content)
  — text after anything already written, text of a slot that is not the
  region's default target, a form preamble off the default target, and a form
  whose field labels another form of the region shares; the parser routes the
  text after a marker to the named slot and ends any open field (a marker
  naming no slot stays text). A stored headline's line breaks are written as
  `<br>` in the heading and read back as `\n`. Blank-line runs inside a value
  are no longer collapsed by the markdown emitter or the YAML encoder
  (`dedup_empty_lines` stays as a public helper). In a region with any form
  slot, every label-shaped text line (owner content, content slot, preamble)
  carries one escape space that the parser strips. Pinned by the regenerated
  corpus (the new `Mixed` class, `Demo.mixed`).

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec::code`, `SomFormFieldMeta::code`) is written as an inline
  code span when its value is on one line — delimited by one backtick more than
  the longest run inside it, padded with a space when the value begins or ends
  with a backtick or a space — and the markdown import unwraps the span again,
  on both the id-bearing form path and the transparent form-slot path. A value
  written without a span is kept as written; a multi-line value keeps the plain
  rendering. Pinned by the regenerated corpus (`expected.md`, the new
  `Demo.details.pattern` and `Card.content.selector` fields, and the new
  `markdown_import_cases.json` cases).

## 1.5.0

- Released in lockstep with `tom_specs_model` 1.5.0. Two changes break a caller: the YAML decode's `review` is null when the file has no `review:` key (check for null where it was read as a map), and the model renames two section ids (see `tom_specs_model` 1.5.0).

- The CodeSpecs gate record carries Stage B's gap lines: an `insufficient` entry may hold `gaps:`, each a `CodeSpecsGateGap` with `sectionId`, `required` and `carrier` (`<section-id>.<field>`) and its `codespecs_prompt.md` §6.3 `line`. The reader refuses gaps on any other verdict, an unknown key in a gap, an empty field and a malformed carrier; the writer puts `gaps:` after `resolution`. Additive, so `formatVersion` stays 1. Pinned by new `codespecs_record_cases.json` cases.
- Markdown import stores a pattern-list item's heading id even when it equals the positional pattern default (`UCE-USER-1`), so the id survives a later move or insert and a document's `.md` imports to the same memory as its `.yaml` (SOM §11.5). A pattern-less list's `<member>-<n>` id stays positional. Pinned by the regenerated corpus (`state.json`, `expected.docspecs.yaml`) and each v0 package's Meridian import test.
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `SpecModel::is_generation_input` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings carry their document path (SOM §14): `SpecDocumentMarkdown::export_root_with_map` / `SpecDocument::to_markdown_with_map` return a `SpecMarkdownRendition` (the `export_root` text plus a 1-based heading line → document path map, with `path_at_line`), and the new `validate_spec_document(model, document, schema, root_type)` renders, runs the DocSpecs validator and sets each finding's `path`; pinned by the new `docspecs_path_cases.json`.
- Typed text (SOM §9, `valueTypeMismatch`): an `int`/`double`/`num`/`bool` field holding non-empty text its parser cannot read is refused by `set_value`/`set_form_value` (`Err`), makes `value`/`form_value` return `Err` instead of `Ok(None)`, and is reported by `validate_document` as the new `SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH` (scalar leaves; form fields without enum values or `count_of`); new helpers `som_scalar_base`, `som_typed_text_readable`. Pinned by the new `validation_cases.json` case and the `setRawFormField`/`valueUnreadable`/`formValueUnreadable` editor ops.
- YAML empty document (SOM §12.3 rule 4): the encoder writes an empty document as `document:` then `  <root key>: {}` instead of `document: {}`, keeping the root key that records which document root the file is; decode still accepts `document: {}`. Pinned by the new `yaml_review_cases.json` roundTrip case.
- Query section ids (llm_and_d4rt_tools.md §6): a list item is known by its own effective id — stored, else the list's `@SectionIdPattern` with its 1-based position, else `<member>-<position>` — in the `sectionIdExact`/`sectionIdPrefix` filters and the projection's `section_id`, so a list's own id matches only the list; pinned by four new `query_cases.json` cases and `projection_cases.json`.
- YAML review pass presence (SOM §12.1): `SpecYamlContents::review` is now `Option<YamlMap>` — `None` when the file has no `review:` key, `Some` (possibly empty) when it has one — so a file without a review pass round-trips without gaining `review: {}`; pinned by the new `yaml_review_cases.json` case.
- Markdown import (SOM §11.6): prose in a section whose owner has no content slot but has form slots (a class-level `@Form` on `content`) is that form's preamble — `finalize_body_slots` binds it to `<owner>/content` (else the first form slot) and strips the escape space of a label-shaped preamble line, instead of storing it on the owner's path (kindMismatch); pinned by the new last `markdown_import_cases.json` case.
- CodeSpecs catalogue: `CodeSpecsSlice`, `CodeSpecsStep` and `CodeSpecsArea` gain `try_from_json` (Result, error naming the row); `from_json` delegates and panics with the same message; `CodeSpecsAreaCatalog::from_json` propagates the row error instead of reading 0 or ""; pinned by the new `catalogErrorCases` table of `codespecs_extract_cases.json`.
- Review-pass scalars keep their YAML 1.2 type (SOM §12.5): `YamlValue` gains `Null`/`Bool`/`Float`, the new `yaml_parse_typed` reads the `review:` pass by the core schema (ints and floats distinct, an integer beyond 64 bits as a float), and `write_review_pass` writes the typed values back (`3.0`, `1e+300`, `-.inf`) instead of guessing types from string text. Pinned by two new `yaml_review_cases.json` cases.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item: `SpecDocument::move_list_item(model, item_path,
  to_index, to_list)` reorders a list item, or moves it into another list of
  the same element class; the section id is the identity and the path the
  position. Every affected list is renumbered to `<list>-1..n`, every value
  under each item (content, forms, headlines, code specs, nested lists, stored
  ids) is re-keyed with it, and an anonymous item whose positional id changes
  has its old id stored. The result is a `SpecListItemMove` (`path`, and the
  ordered `(old, new)` / `(new path, id)` pairs `renamed` / `pinned_ids`).
  A refusal changes nothing and is a `SpecListMoveError`: `NotLiveItem`,
  `NotAList`, `ElementClassMismatch` and `PatternMismatch` (the conformance
  word `argument`), `Collision` (`collision`) and `IndexOutOfRange`
  (`range`). `spec_document_yaml::rekey_review(review, renamed)` re-keys a
  `review:` pass with the move's `renamed` pairs. Verified against
  `list_move_cases.json`.

- Stated counts: `FormFieldSpec::count_of` (read from the meta's
  `formFields[].countOf`, empty when absent) names the entries a form field's
  value counts — `X` (every list item whose element class carries
  `@SectionId(X)`) or `X.f=v` (those entries one of whose own forms holds `v`
  in form field `f`), summed over the targets. `validate_document` reports the
  new `SPEC_VALIDATION_CODE_COUNT_MISMATCH` (`countMismatch`) after the
  reference check when a non-empty stated value is not a whole number or not
  the number of entries the document holds; a target outside the document's
  registry scope skips the field. Verified by the `countMatches` /
  `countMismatch` validation cases.

- Assembling one document from fragments written in parallel, new module
  `spec_document_assembly` re-exported from the crate root:
  `SpecDocument::assemble(&[(name, &document), ...])` (also
  `assemble_spec_documents`) merges the fragments' `to_json` stores, in the
  order given. The merge is refusing: a content path, headline or code-spec
  location two fragments both write, a form field two fragments both fill (two
  fragments may fill different fields of one form), or a list two fragments
  both hold is a `SpecAssemblyOverlap` (`store`, `path`, `field`,
  `fragments`, `message()`), and a `SpecDocumentAssembly` with any overlap has
  `document: None` (`ok()` is false). Overlaps are reported in store order
  content, forms, lists, headlines, codeSpecs, then by path (UTF-16 order).
  A fragment name given twice panics. Verified against `assembly_cases.json`.
- CodeSpecs: the Stage-A gate (`codespecs_prompt.md` §4, A1–A5), new module
  `spec_codespecs_gate` re-exported from the crate root:
  `CodeSpecsGate::new(model, document, catalog, schema, root_type).run()`
  returns a `CodeSpecsGateReport` (`results` A1..A5 in order, `extracts` when
  A3 passed, `passed()`, `findings()`, `get(check)`) — never a `Result`: every
  check runs, and one that cannot run is reported not run, with its reason,
  and never passes. A1 renders with `SpecDocument::to_markdown` and validates
  with `DocSpecsValidator` (a render `Err`, which Dart throws, is reported as
  A1 not run); A2 is `validate_document`; A3 collects every unrouted class
  from the non-strict `routings()` walk (or the root-resolution error) and
  only then runs `extract_all()`; A4 checks each required marker argument's
  source (with `when` and `resolves_to`); A5 checks each carrier against the
  model. New `CodeSpecsGateCheck` (`label()` = `A1`..`A5`),
  `CodeSpecsGateCheckResult`, `CodeSpecsGateFinding`. The area catalogue reads
  the optional `gate` block: new `CodeSpecsFieldRef`,
  `CodeSpecsRequiredArgument`, `CodeSpecsCarrier` (each `from_json` returns
  `Result<_, String>`), and `CodeSpecsAreaCatalog::required_arguments` /
  `carriers` / `has_gate_tables`. **Breaking:** `CodeSpecsAreaCatalog::from_json`
  now returns `Result<CodeSpecsAreaCatalog, String>`, failing on a gate row
  missing a required cell. Verified against `codespecs_gate_cases.json`.
- CodeSpecs: reading a Phase-4 run back (new module `spec_codespecs_records`,
  re-exported from the crate root). `CodeSpecsExtract::from_yaml(text,
  source)` / `parse_code_specs_extract_yaml` are the inverse of `to_yaml`
  (byte-identical round trip for every extract the extractor writes): they
  require `formatVersion` 3 and a non-empty `area.code`, read every other
  absent key as empty, strip a leading `CodeSpecPart.` from `area.part`, and
  refuse a wrong-typed key or a `document.entryCount` that disagrees with the
  entries. New `CodeSpecsGateRecord` (`gate.verdicts.yaml`, format 1):
  `new` checks the shape (CE-* areas named once, `resolution: descoped` only
  on an insufficient area), `from_yaml` also refuses unknown keys and other
  format versions, `to_yaml` is byte-stable, plus `verdict_for`,
  `check_against(catalog)` and `with_verdict`. New `CodeSpecsGateVerdict`,
  `CodeSpecsGateEntry`, `CodeSpecsExcludedArea`, and
  `CodeSpecsExtractSet::from_files` (an ordered sequence of `(name, text)`
  pairs) / `from_directory`, which scope the extracts by their gate record and
  expose `by_area`, `entries_for_section` and `entries_at_path`. Every reader
  returns `Result<_, CodeSpecsRecordError>`. The YAML reader gains
  `yaml_parse_raw_scalars`, which keeps scalars as source text so the record
  reader can tell `null` from `"null"`. Verified against the corpus table
  `codespecs_record_cases.json`.
- CodeSpecs: the area catalogue carries the `codespecs_mapping.md` §4.4.6
  authoring-step table. New `CodeSpecsStep` (`number`, `title`, `slice`,
  `placed_by`, `area_codes`), re-exported from the crate root, and
  `CodeSpecsAreaCatalog::steps`, read from the optional `steps` key — a
  catalogue without it loads with no steps. `step_numbered(n)` returns
  `Option<&CodeSpecsStep>`; `steps_for(area)` returns the steps for
  `area.authoring_steps` in that order, skipping numbers the catalogue does not
  carry. Verified against `stepCases` in `codespecs_extract_cases.json`.
- `DocSpecsDocument::replace_section_body` replaces one section's own body
  (the lines between its heading and the next heading of any level) and keeps
  every other byte; the body is trimmed of leading/trailing blank lines and
  framed by one blank line on each side. It returns `Err` when the id names no
  section or several, or when the body carries a heading outside a fence or
  leaves a fence open. `DocSpecsDocument::all_sections` walks the tree
  depth-first. Verified against the corpus table
  `docspecs_replace_cases.json`.
- YAML codec: the `review:` pass is written back. `encode_yaml_with_review`
  takes an optional review map (typically the one `decode_yaml` returned) and
  appends it after the document pass via `write_review_pass`: entries sorted by
  path with JSON-quoted keys, each entry's fields sorted by name, booleans,
  numbers and identifier-like strings plain, any other string as a
  self-verified block scalar, lists as JSON flow; an empty map writes
  `review: {}`. `stale_review_paths` reports the review paths that no longer
  resolve against a document (unknown paths, removed list items), sorted.
  Verified against the corpus table `yaml_review_cases.json`.
- Applying a Markdown import is a runtime operation (SOM §11.7).
  `SpecDocument::apply_markdown_result` overwrites the roots a parsed import
  covers and keeps every other root; a result with rejections is refused with
  `Err` and leaves the document unchanged unless `allow_rejections` is true.
  `SpecDocument::from_markdown` parses and loads a fresh document in one call
  and returns a `SpecMarkdownImport` (the document plus the parse report, with
  a `rejections()` accessor). Verified against the corpus table
  `markdown_apply_cases.json`.
- Markdown codec: a member's heading id and its transparency are read from its
  meta node (`sectionId`, then `classSectionId`), no longer by looking up the
  node's class name. A wrapper section (`TextSection`, …) carries its owner's
  class name, so the lookup returned the owner's id: the text rendered under a
  heading the DocSpecs schema rejects (the owner nested in itself). It is now
  transparent (SOM §11.6) and its text goes into the owner's body.
- Validator: content stored on a wrapper section (a `section` member that
  resolves to no class) is accepted, as the YAML codec writes it there; it was
  reported as `kindMismatch`.
- Both were found authoring a real Solution Blueprint, where such sections
  could not be written in any form that passed every tier. A new corpus case
  (`Notes.remarks`) pins them in all nine runtimes.

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- Generic TomSpecs object-model runtime for Rust: section-path grammar, meta-data
  model loader, reflection/resolution, sparse document, validator, and the
  YAML/Markdown codecs, plus a hand-rolled JSON reader/encoder.
- Zero external dependencies (Rust standard library only — no `serde` /
  `serde_yaml` / `regex`); validated against the shared language-agnostic
  conformance corpus.
- Packaged as a Cargo crate `tom_som_rust_runtime` with `publish = false`
  (proprietary); `cargo package --no-verify` is the packaging check.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its `Cargo.toml` version is realigned by
  `tom_specs_clitool/bin/generate_som.dart`.
