# Changelog

## Unreleased

- Listing a value's paragraphs (SOM §11.9.1, annot8), a port of the Dart
  reference: `spec_review_annotations_paragraphs(r, path, field, out, err)`
  fills a `SpecParagraphList` of `SpecParagraph` (`index`, `start_line`,
  `end_line`, `text`, and the `annotation` kind when the paragraph opens an
  annotation block; `spec_paragraph_to_json`, `spec_paragraph_list_free`).
  The index is exactly what `after_paragraph` of the inserts takes; a value
  the document does not hold is refused. Conformance: the `paragraphs` op of
  `annotation_cases.json`.

- Question options (SOM §11.9.2, annot7), in `spec_review_annotations`, a
  port of the Dart reference: a listed question carries its options
  (`SpecQuestionOption`: `letter`, `text` with continuation lines joined,
  `bold`; `spec_question_option_to_json`) and its `recommended` letter (the
  bold option, else the option that says "recommended", else the letter of a
  `*Recommendation:*` line); `spec_review_annotation_answer_letter` reads the
  `(b)` / `**(b)**` an answer starts with. The question JSON gains `options`,
  `recommended` and `answerLetter`. `SpecQuestionDraft.recommended` makes
  `spec_format_question_block` write that option bold, `- **(b)** …`.

- Extracting answers for a step folder (SOM §11.9.7, annot6), a new module
  `spec_answers` ported from the Dart reference: `spec_extract_answers(model,
  doc, label, path, ...)` fills a `SpecAnswerExtract` (`label`, `qualifier`,
  `SpecAnswerEntry` entries with kind, id, section-id chain and rendition line,
  in rendition order; `spec_answer_extract_counts`,
  `spec_answer_extract_to_json`, `spec_answer_extract_free`), and
  `spec_render_answers(extracts, len, options)` writes the `answers.md` text
  (`SpecAnswerRenderOptions`: `include_open`, `include_marks`, `title`). The
  conformance harness runs `answer_cases.json`. Guide:
  `doc/review_annotations.md`, "Extracting answers for a step folder".

- Writing changes as inline marks (SOM §11.9.3, annot5), in
  `spec_review_annotations`, a port of the Dart reference:
  `spec_mark_change_text(old, new)` diffs by line, then by word, merging
  changes at most two words apart, so accepting all marks gives `new` and
  rejecting all gives `old`; words are never split and code is never marked.
  It returns a `SpecMarkedChange` (`text`, `exact`;
  `spec_marked_change_free`, `spec_marked_change_to_json`).
  `spec_review_annotations_set_marked` (a second edit updates its mark) and
  `spec_review_annotations_mark_against` (against an earlier version) apply it
  to a value. The conformance harness runs `change_mark_cases.json`. Guide:
  `doc/review_annotations.md`, "Writing changes as marks".

- Inline-mark review (SOM §11.9.3, annot4), in `spec_review_annotations`, a
  port of the Dart reference: `spec_review_annotations_revision` (FNV-1a
  64-bit, 16 hex digits), `spec_review_annotations_list_marks`
  (`SpecMarkEntryList` of `SpecMarkEntry`, ids `M-<n>`,
  `spec_mark_entry_to_json`), `spec_review_annotations_decide_marks`
  (`SpecMarkDecisionItem` array, refused on a stale revision or an unknown
  id), `spec_review_annotations_accept_all_marks` / `_reject_all_marks`
  (optional path), `spec_review_annotations_remove_all_annotations`, and the
  text-level `spec_apply_inline_marks_text`. New enum `SpecMarkDecision`
  (`spec_mark_decision_name`, `spec_mark_decision_parse`); every operation
  fills a `SpecMarkReport` of `SpecMarkOutcome`s and `SpecMarkIssue`s
  (`unclosed`, `nested`, `noArrow`; `spec_mark_report_to_json`,
  `spec_mark_report_free`). Accepting or rejecting a mark (also
  `spec_review_annotations_apply_mark`) now follows the full whitespace rules:
  tabs count as spaces, `]` and `}` join the punctuation set, and a mark that
  was a whole line takes its line with it. The conformance harness runs
  `inline_mark_cases.json`. Guide: `doc/review_annotations.md`, "Reviewing
  inline marks".

- Review annotations (SOM §11.9, annot2). New module `spec_review_annotations`
  (`include/spec_review_annotations.h`, in the umbrella header), a port of the
  Dart `spec_review_annotations.dart`: `SpecReviewAnnotations`
  (`spec_review_annotations_make`) lists comment blocks, question blocks and
  CriticMarkup inline marks in document order
  (`spec_review_annotations_list` → `SpecReviewAnnotationList` of
  `SpecReviewAnnotation`, `spec_review_annotation_to_json`), counts them
  (`SpecReviewAnnotationCounts`), hands out comment ids
  (`next_comment_id`, `assign_comment_ids`), inserts comments and questions
  (`insert_comment`, `insert_question`, `insert_question_after_comment`, with
  `SpecQuestionDraft`), answers and edits them (`set_answer`, `edit_comment`),
  removes them (`resolve`), accepts or rejects marks (`apply_mark`) and strips
  a copy (`stripped`, `spec_strip_annotations_text`). Enums
  `SpecReviewAnnotationKind` and `SpecMarkKind`; a missing comment, question,
  paragraph or mark fills a `SpecReviewAnnotationError` and changes nothing.
  Positions are 0-based line numbers within a value. Three new validation
  codes after `multipleReferences`: `SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED`
  (`"annotationMisplaced"`), `SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED`
  (`"annotationMalformed"`) and `SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID`
  (`"duplicateAnnotationId"`), reported by `validate_document` as its last
  group (`spec_review_annotations_validate`), stable-sorted by path. The
  conformance harness runs `annotation_cases.json`; the four new validation
  cases pin the codes. Guide: `doc/review_annotations.md`.

- Single-reference check (uamtc17). `FormFieldSpec` gains `multiple` (int, read from the meta's `formFields[].multiple`, absent = 0). New validation code
  `SPEC_VALIDATION_CODE_MULTIPLE_REFERENCES` (`"multipleReferences"`), after `missingRequiredField`. In the
  reference phase of `validate_document`, a `refersTo` field not marked
  `multiple` whose value splits (on `,`, trimmed, empty parts dropped) into
  more than one id reports one `multipleReferences` at the form path, before
  the registry-scope test; every id is still resolved, so dangling ones still
  report `danglingReference`. Pinned by the `multipleReferencesInSingleField`
  and `everyDanglingIdOfAList` validation cases.

- Required form fields (uamtc16). New validation code `SPEC_VALIDATION_CODE_MISSING_REQUIRED_FIELD`
  (`"missingRequiredField"`), after `derivedValueMismatch`. In the form phase
  of `validate_document`, every form path that resolves to a form reports, in
  declared order, each model field marked `required` whose stored value is
  absent or empty after trimming, at the form path. It runs on every form the
  document holds (class-level `content` forms and member forms, in list items
  or not). Pinned by the `requiredFieldsFilled`,
  `missingRequiredFieldInListItemForms` and `missingRequiredFieldInMemberForm`
  validation cases and the extended `unknownFormField` case; the conformance
  model's class count is now 15 (`RequiredEntry`).

- Derived values (uamtc10). `FormFieldSpec` gains `product_of` (a
  `SomStrList`, read from the meta's `formFields[].productOf`) and `rank_of`
  (owned string or NULL, from `rankOf`), both freed with the model.
  `validate_document` gains phase 7, after the count check: a `productOf`
  field must hold the product of its operands (`name` of the same form or
  `FORMSID.name` of the sibling form; an enum operand counts as its 1-based
  position), held to the precision the value is written in; a `rankOf` field
  must rank the instances of its form 1 to n, each once, highest score first.
  Either is reported as `SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH`
  (`"derivedValueMismatch"`) at the form path; the phase's findings are
  stable-sorted by path. Such fields are no longer reported as
  `valueTypeMismatch`. A `countOf` target written `./X` (or `./X.f=v`) now
  counts only the entries beneath the section holding the form. Pinned by the
  `derivedValuesMatch`, `productMismatch`, `rankOutOfOrder`, `rankDuplicate`
  and `scopedCountMismatch` validation cases.

- Exact markdown round trip (SOM §11.2, §11.3, §11.6, §11.7, §12.4). In a
  heading's body region the emitter writes a slot marker
  `<!-- slot: <rel> -->` (rel relative to the owner, `.` for the owner itself)
  before text that would otherwise bind elsewhere — text after anything
  already written, text or a form preamble that is not the region's default
  target (first content slot; else the `content` form; else the first form),
  and a form whose labels another form of the region shares — and the parser
  (`finalize_body_slots`) routes the text after a marker to that slot, joining
  repeated targets with a blank line; a marker naming no slot stays text. In a
  region with any form every label-shaped text line carries one escape space,
  which import strips. A headline's line breaks are written as `<br>` in the
  heading and read back as `\n`. Blank lines inside a value are no longer
  collapsed: neither `prepare_value` nor the YAML encoder applies the
  `\n{3,}`→`\n\n` normalisation (`spec_yaml_dedup_empty_lines` stays as a
  helper). Pinned by the regenerated corpus (the new `Mixed` class at
  `Demo.mixed`, the new marker import case) and `rt.emptyLineDedup`, which
  now asserts the blank lines are kept.

- `spec_document_has_values_under` answers from a lazily built prefix index —
  every key of the content, form, list, headline and codeSpec stores plus
  every prefix of one that ends right before a `/` or a `-` — instead of
  scanning every stored key per call. The index is built on the first query,
  dropped by every mutator and freed by `spec_document_free`; answers are
  unchanged. The markdown emitter, the validator and the query engine ask once
  per model node, so rendering a large document is no longer quadratic.
  `SpecDocument` gains an opaque `value_index` member. Pinned by the new
  `tests/value_index_test.c` (VI-1 agreement with a full scan after every
  mutator, VI-2 complexity guard).

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec.code`, `SomFormFieldMeta.code`, set by the bridge and by the
  generated C facade meta) is written as an inline code span when its value is
  on one line — delimited by one backtick more than the longest run inside it,
  padded with a space when the value begins or ends with a backtick or a
  space — and the markdown import unwraps the span again, on both the
  id-bearing form path (`finalize_form`) and the transparent form-slot path
  (`finalize_body_slots`). A value written without a span is kept as written;
  a multi-line value keeps the plain rendering. Pinned by the regenerated
  corpus (`expected.md`, the new `Demo.details.pattern` and
  `Card.content.selector` fields, and the new `markdown_import_cases.json`
  cases).

## 1.5.0

- Released in lockstep with `tom_specs_model` 1.5.0. Two changes break a caller: the YAML decode's `review` is null when the file has no `review:` key (check for null where it was read as a map), and the model renames two section ids (see `tom_specs_model` 1.5.0).

- The CodeSpecs gate record carries Stage B's gap lines: an `insufficient` entry may hold `gaps:`, each a `CodeSpecsGateGap` with `sectionId`, `required` and `carrier` (`<section-id>.<field>`) and its `codespecs_prompt.md` §6.3 `line`. The reader refuses gaps on any other verdict, an unknown key in a gap, an empty field and a malformed carrier; the writer puts `gaps:` after `resolution`. Additive, so `formatVersion` stays 1. Pinned by new `codespecs_record_cases.json` cases.
- Markdown import stores a pattern-list item's heading id even when it equals the positional pattern default (`UCE-USER-1`), so the id survives a later move or insert and a document's `.md` imports to the same memory as its `.yaml` (SOM §11.5). A pattern-less list's `<member>-<n>` id stays positional. Pinned by the regenerated corpus (`state.json`, `expected.docspecs.yaml`) and each v0 package's Meridian import test.
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `spec_model_is_generation_input` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings carry their document path (SOM §14): `spec_markdown_export_root_with_map` / `spec_document_to_markdown_with_map` return a `SpecMarkdownRendition` (markdown identical to the plain export, plus a 1-based heading line → document path map; `spec_markdown_rendition_path_at_line`, `spec_markdown_rendition_free`), and the new `validate_spec_document` (`spec_schema_validation.h`) renders, validates and fills each violation's `path`; conformance replays `docspecs_path_cases.json`.
- A typed field (`int` / `double` / `num` / `bool`, nullable too) holding non-empty text its type cannot read (SOM §9): `spec_editor_set_value` / `spec_editor_set_form_value` refuse such a string (return 0 with `*err`), `spec_editor_value` / `spec_editor_form_value` now return 0 with `*err` on such stored text instead of answering SOM_VALUE_NONE, and `validate_document` reports the new `valueTypeMismatch` (`SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH`) for a scalar leaf and for a non-enum, non-`countOf` form field; new helpers `som_scalar_base` / `som_typed_text_readable`.
- `encode_yaml`: a document with no values encodes as `document:` + `  <root key>: {}`, keeping the root key (the file's only record of its document root), never `document: {}`; decode still accepts `document: {}` (SOM §12.3 rule 4).
- Query engine (`section_id_of`): a list item (`listItemComplex` / `listItemScalar`) is known by its own effective section id — stored id, else the list's `@SectionIdPattern` with its 1-based position, else `<member>-<position>` — for `sectionIdExact` / `sectionIdPrefix` and the projected `sectionId`; other nodes keep the model `@SectionId` (llm_and_d4rt_tools.md §6).
- `decode_yaml`: `SpecYamlContents.review` is NULL when the file has no `review:` key and an (owned, possibly empty) YAML_MAP when it has one (a bare `review:` included), so a document without a review pass round-trips without gaining `review: {}` (SOM §12.1).
- Markdown import (`finalize_body_slots`): prose under a heading whose owner has no content slot but has form slots (a class-level `@Form` on `content`) is that form's preamble (SOM §11.6) — bound to the `content` form slot, else the first, with a label-shaped line's escape space stripped — instead of landing on the owner's own path (kindMismatch).
- `spec_codespecs_area_catalog_from_json` now returns `int` and takes a `char **err`: a slice/step row without a numeric `number`/`slice` or an area without a non-empty `code`/`part` fails with a message naming the row (as Dart does) instead of reading 0 / empty.
- Review-pass scalars are typed by the YAML 1.2 core schema (SOM §12.5):
  `0o` / `0x` ints, `.inf` / `-.inf` / `.nan`, an empty value as null, and a
  decimal integer beyond 64 bits as a float rather than saturated; floats are
  written in canonical form (`3.0`, `1e+300`, `.nan`), a whole float at or
  above 2^53 with its shortest digits.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item (vsctsa44). `spec_document_move_list_item` moves the
  item at a path to an index of its own list or, given `to_list`, of another
  list of the same element class. A path is a position, the section id is the
  identity: every affected list is renumbered to `<list>-1..n` (seq = n, an
  emptied list dropped), every store key at or under an old item path —
  content, forms, headlines, codeSpecs, item ids, list keys and items, seq
  keys — is re-keyed to the new path, and an anonymous item whose positional
  id changes stores its old one (the moved item is not pinned when it crosses
  lists). Refusals leave the document unchanged and fill a
  `SpecListMoveError` — `SPEC_LIST_MOVE_ARGUMENT` (not a live item, not a
  model list, another element class, a stored id not fitting the
  destination's `@SectionIdPattern`), `SPEC_LIST_MOVE_COLLISION` (the stored
  id is taken in the destination) or `SPEC_LIST_MOVE_RANGE`. The result,
  `SpecListItemMove` (`path`, `renamed_from`/`renamed_to`,
  `pinned_paths`/`pinned_ids`, released with `spec_list_item_move_free`),
  feeds `spec_yaml_rekey_review`, which returns a review map re-keyed the
  same way, and `spec_rekey_path`. The conformance runner checks every case
  of `list_move_cases.json` (`listMove[...]`).

- Stated counts (vsctsa43). `FormFieldSpec.count_of` (a `SomStrList`, read
  from the meta's `formFields[].countOf`; empty when absent, freed with the
  model) names the entries a form field's value counts — `X` for every list
  item whose element class carries `@SectionId(X)`, `X.f=v` for those whose
  own form holds `v` in form field `f`. `validate_document` gains phase 6,
  after the reference check: a non-empty value that is not a whole number, or
  not the summed count, is reported as `SPEC_VALIDATION_CODE_COUNT_MISMATCH`
  (`"countMismatch"`) at the form path, with the Dart reference's messages;
  a field with any target outside the document's registry scope is skipped.
  The conformance runner checks the `countMatches` / `countMismatch`
  validation cases.

- Assembling one document from fragments written in parallel
  (`spec_document_assembly.h`). `spec_document_assemble` takes an ordered
  array of `SpecAssemblyFragment` (borrowed `name` + `document`) and fills a
  `SpecDocumentAssembly` — the assembled `document` (owned) or, when any place
  is written by two or more fragments, no document and every
  `SpecAssemblyOverlap` (`store`, `path`, `field` for forms, `fragments` in the
  given order; `spec_assembly_overlap_message` renders the Dart reference's
  message). Content, headlines and codeSpecs overlap per path, forms per
  (path, field) — two fragments may fill different fields of one form — and
  lists per list path. Overlaps come in store order content, forms, lists,
  headlines, codeSpecs, then path order. Released with
  `spec_document_assembly_free`. The conformance runner checks every case of
  `assembly_cases.json` (`assembly[...]`).

- CodeSpecs: the Stage-A gate (`codespecs_prompt.md` §4, A1–A5) as one
  `CodeSpecsGate` (`spec_codespecs_gate.h`). `spec_codespecs_gate_make`
  borrows a model, document, catalogue, optional DocSpecs schema and optional
  root type; `spec_codespecs_gate_run` fills a `CodeSpecsGateReport` — one
  `CodeSpecsGateCheckResult` per check (`ran`, `not_run_reason`, the
  `CodeSpecsGateFinding`s with `code` / `location` / `message`), the
  extraction run's `extracts` when A3 passed, `passed`, findings in check
  order — released with `spec_codespecs_gate_report_free`. Every check runs;
  a check that cannot run (no schema, no gate tables, no extraction run) is
  reported not run, with the Dart reference's reason, and fails the gate. A1
  renders the document to Markdown and validates it with the DocSpecs
  validator; A2 is `validate_document`; A3 collects every unrouted class of the
  routing walk (or the root-resolution error) before extracting; A4 checks the
  catalogue's required marker arguments against the extracts; A5 checks its
  carriers against the model. The area catalogue reads the optional `gate`
  block: `CodeSpecsFieldRef` (`spec_codespecs_field_ref_source`),
  `CodeSpecsRequiredArgument` (with optional `resolves_to` / `when` +
  `when_equals`), `CodeSpecsCarrier`, and `CodeSpecsAreaCatalog`'s
  `required_arguments`, `carriers` and `has_gate_tables`, all released by
  `spec_codespecs_area_catalog_free`. The conformance runner checks every case
  of `codespecs_gate_cases.json` (`codespecsGate[...]`).

- CodeSpecs: reading Phase-4 output back (`spec_codespecs_records.h`).
  `spec_codespecs_extract_from_yaml` parses a `<CE-CODE>.extract.yaml` — the
  inverse of `spec_codespecs_extract_to_yaml`, byte-identical on the round
  trip — refusing an unknown `formatVersion`, a missing `area` / `area.code`,
  a wrongly typed key and a `document.entryCount` that disagrees with the
  entries; the read extract owns its area (new `CodeSpecsExtract.owned_area`,
  released by `spec_codespecs_extract_free`; `spec_codespecs_area_free` frees a
  standalone area). The Stage-B gate record: `CodeSpecsGateVerdict` (word /
  parse), `CodeSpecsGateEntry`, and `CodeSpecsGateRecord` built
  (`spec_codespecs_gate_record_make`) or read
  (`spec_codespecs_gate_record_from_yaml`) only in the checked shape, with
  `verdict_for`, `check_against` (a catalogue's active areas), `with_verdict`
  and the byte-stable `to_yaml`. `CodeSpecsExtractSet` reads an ordered list of
  `CodeSpecsRecordFile` name/text pairs
  (`spec_codespecs_extract_set_from_files`) or a directory
  (`spec_codespecs_extract_set_from_directory`) and scopes it by the gate
  record — in scope iff `sufficient`, excluded areas kept visible as
  `CodeSpecsExcludedArea` — with `by_area`, `entries_for_section` and
  `entries_at_path`. Failures fill a `CodeSpecsRecordError` whose message is
  the Dart reference's. `spec_codespecs_yaml_string` exposes the extract's
  string escaper. The conformance runner checks every case of
  `codespecs_record_cases.json` (`codespecsRecords.*`).
- CodeSpecs: the area catalogue carries the `codespecs_mapping.md` §4.4.6
  authoring-step table. `CodeSpecsStep` (`number`, `title`, `slice`,
  `placed_by`, `area_codes`) and `CodeSpecsAreaCatalog.steps` / `steps_len`,
  read from the catalogue's `steps` array — absent in an older catalogue,
  which loads with no steps — and released by
  `spec_codespecs_area_catalog_free`. `spec_codespecs_catalog_step_numbered`
  returns the step with a number or NULL; `spec_codespecs_catalog_steps_for`
  returns an area's steps in its `authoring_steps` order as an owned array of
  borrowed pointers, skipping numbers the catalogue does not carry. The
  conformance runner recomputes `stepCases` from `codespecs_extract_cases.json`
  (including the legacy catalogue with `steps` removed) and compares it with
  the committed table (`codespecs.stepCases`).
- DocSpecs: `docspecs_replace_section_body` replaces the own body of the one
  section (any level) whose id is given and keeps every other byte; it
  refuses an id naming no section or several (listing their lines), a body
  with a heading outside a fence, and a body that leaves a fence open. The
  conformance runner checks the shared `docspecs_replace_cases.json` table
  (`docspecsReplace[...]`).
- YAML codec: the `review:` pass is written back. `encode_yaml_with_review`
  encodes with a review value (NULL: no pass, exactly `encode_yaml`) and
  appends it through `spec_yaml_write_review_pass` — entries sorted by path
  (JSON-quoted keys), fields sorted by name, `review: {}` when empty; null,
  booleans, numbers and identifier-like strings plain, any other string as a
  self-verified block scalar, lists as JSON flow. `decode_yaml` now types the
  review pass's plain scalars as a YAML core-schema reader does (new
  `YAML_BOOL` / `YAML_NULL` / `YAML_FLOAT` kinds, a `plain` flag on
  `YamlValue`), so decode followed by encode is byte-identical;
  `yaml_value_from_json` builds a review in code. `spec_yaml_stale_review_paths`
  lists the review paths that no longer resolve (unknown to the model, or
  through a removed list item). The conformance runner checks the shared
  `yaml_review_cases.json` table (`yamlReview[...]`).
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
- Markdown import: `spec_document_apply_markdown_result` applies a parse result
  as a full overwrite of the roots it covers (SOM §11.7) — values under each
  root prefix are removed, then the parsed content, forms, lists (seq, items
  and stored ids), headlines and codeSpecs are written; other roots are kept.
  A result with rejections is refused, leaving the document unchanged, unless
  rejections are allowed. `spec_document_from_markdown` does parse + apply in
  one call and returns the document with the parse report
  (`SpecMarkdownImport`, freed with `spec_markdown_import_free`). The
  conformance runner checks the shared `markdown_apply_cases.json` table
  (`mdApply[...]`), and `md.land.memory` now lands through the one-call import.

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- Generic TomSpecs object-model runtime for C: section-path grammar, meta-data
  model loader, reflection/resolution, sparse document, validator, the typed
  store boundary (`spec_typed_values`), the generic meta-driven editing API
  (`spec_editor`), and the YAML/Markdown codecs, plus a hand-rolled JSON
  reader/encoder and a small C utility module (growable buffer / list /
  byte-sorted map).
- Zero external dependencies (C standard library only); validated against the
  shared language-agnostic conformance corpus.
- Packaged with a `Makefile` that builds a static (`.a`) and a shared (`.so`)
  library, emits a `pkg-config` file (`tom_som_c_runtime.pc`) whose `Version`
  tracks the model version, and provides `make install` and `make dist`
  (source tarball) targets.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its `Makefile` `VERSION` is realigned by
  `tom_specs_clitool/bin/generate_som.dart`.
