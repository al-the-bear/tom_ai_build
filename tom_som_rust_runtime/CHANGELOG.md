# Changelog

## Unreleased

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
