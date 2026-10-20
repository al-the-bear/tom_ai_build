# Changelog

## Unreleased

- `SpecReviewAnnotations.paragraphs(path, field=None)` lists a value's
  paragraphs (`SpecParagraph`: index, start and end line, text, and the
  annotation kind when the paragraph is an annotation block). The index is
  exactly what `after_paragraph` of the inserts takes, by the one rule of SOM
  §11.9.1 "Paragraphs". New export: `SpecParagraph`. Conformance: the
  `paragraphs` op of `annotation_cases.json`.

- Question options (SOM §11.9.2): `SpecReviewAnnotations.list()` reads a
  question's options (`- (a) …`, the recommended one bold, `- **(b)** …`,
  continuation lines joined) into `options`, its `recommended` letter (the
  bold option, else the option that says "recommended", else the letter of a
  `*Recommendation:*` line) and `answer_letter` (a leading `(b)` or `**(b)**`
  of the answer); the JSON form carries `options`, `recommended` and
  `answerLetter`. `SpecQuestionDraft.recommended` makes `format_question_block`
  write that option bold. New export: `SpecQuestionOption` (`letter`, `text`,
  `bold`).

- Extracting answers for a step folder (SOM §11.9.7): the new module
  `spec_answers` ports the Dart reference. `extract_answers(model, doc, label,
  path=None)` lists every question (answered or open), comment and inline
  mark of a document or subtree with its section-id chain and its line in the
  Markdown rendition, in rendition order; `render_answers(extracts, options)`
  writes the step folder's `answers.md`. New exports: `SpecAnswerKind`,
  `SpecAnswerEntry`, `SpecAnswerCounts`, `SpecAnswerExtract`,
  `SpecAnswerRenderOptions`, `extract_answers`, `render_answers`. The
  conformance runner runs `answer_cases.json`.

- Writing changes as inline marks (SOM §11.9.3): `mark_change_text(old, new)`
  diffs by line, then by word, merging changes at most two words apart, so
  accepting all marks gives `new` and rejecting all gives `old`. Words are
  never split and code is never marked. `SpecReviewAnnotations.set_marked`
  (a second edit updates its mark) and `mark_against` (against an earlier
  version) apply it to a value. New exports: `SpecMarkedChange` (`text`,
  `exact`), `mark_change_text`. The conformance runner runs
  `change_mark_cases.json`.

- Reviewing inline marks (SOM §11.9.3): `SpecReviewAnnotations` gains
  `revision`, `list_marks`, `decide_marks` (accept / reject / leave in one
  write, refused on a stale revision or an unknown id), `accept_all_marks` /
  `reject_all_marks` under a path and `remove_all_annotations`; the module
  gains `apply_inline_marks_text`. Each operation returns a `SpecMarkReport`
  for the decision log. New exports: `SpecMarkDecision`, `SpecMarkEntry`,
  `SpecMarkOutcome`, `SpecMarkIssue`, `SpecMarkReport`,
  `apply_inline_marks_text`. Accepting and rejecting (also `apply_mark`)
  follow the whitespace rules: words never join, no double space or space
  before punctuation, and a whole-line mark leaves no blank line. Malformed
  marks are left as written and reported. The conformance runner runs
  `inline_mark_cases.json`.

- Review annotations (SOM §11.9): the new module `spec_review_annotations`
  ports the Dart reference. `SpecReviewAnnotations` lists the comment blocks,
  question blocks and CriticMarkup inline marks of a document's content and
  form-field values in document order (`list`, `counts`) and edits them in
  place, byte-stable outside the annotation it touches (`next_comment_id`,
  `assign_comment_ids`, `insert_comment`, `insert_question`,
  `insert_question_after_comment`, `set_answer`, `edit_comment`, `resolve`,
  `apply_mark`, `stripped`). Positions are 0-based lines within the value. New
  exports: `SpecReviewAnnotation`, `SpecReviewAnnotationKind`, `SpecMarkKind`,
  `SpecQuestionDraft`, `SpecReviewAnnotationCounts`,
  `SpecReviewAnnotationError`, `strip_annotations_text`,
  `format_comment_block`, `format_question_block`. `validate_document` gains a
  last group, ordered by path, with three new codes:
  `SpecValidationCode.ANNOTATION_MISPLACED` (`annotationMisplaced`),
  `ANNOTATION_MALFORMED` (`annotationMalformed`) and `DUPLICATE_ANNOTATION_ID`
  (`duplicateAnnotationId`). The conformance runner runs
  `annotation_cases.json`; the guide is `doc/review_annotations.md`.

- Single-reference fields (uamtc17): `FormFieldSpec.multiple` reads the meta's
  `formFields[].multiple` (absent → false). In the reference phase of
  `validate_document`, a `refersTo` field that is not `multiple` and holds more than
  one comma-separated id gives the new `SpecValidationCode.MULTIPLE_REFERENCES`
  (`multipleReferences`) at the form path, checked before the registry-scope
  test; every id is still resolved, so dangling ones are also
  `danglingReference`. Verified by the `multipleReferencesInSingleField` and
  `everyDanglingIdOfAList` validation cases.

- Required form fields (uamtc16): `validateDocument` reports the new
  `SpecValidationCode.MISSING_REQUIRED_FIELD` (`missingRequiredField`) in its
  form-section step: for every form path the document holds that resolves to
  a form, each field the model declares `required` (in declared order) whose
  value is absent or empty after trimming gives one error at that form path.
  Verified by the `requiredFieldsFilled`,
  `missingRequiredFieldInListItemForms`, `missingRequiredFieldInMemberForm`
  and `unknownFormField` validation cases; the conformance model now has 15
  classes.

- Derived values (uamtc10): `FormFieldSpec.product_of` and `rank_of` read the
  meta's `formFields[].productOf` / `rankOf` (absent → empty / `None`), and
  `validate_document` gains a seventh, instance-tier step after the count
  check. A `product_of` field must hold the product of its operands (a field
  of the same form, or `FORMSID.field` of the sibling form at
  `<owner>/FORMSID`; an enum operand counts as its 1-based position), to the
  precision the stated number is written in; a stated value that is no number
  is reported even when an operand is empty. A `rank_of` field ranks the
  instances of its form by the named score, highest first: over the instances
  with both filled the ranks are 1 to n, each once, and no instance ranks
  below one with a lower score. Both report the new
  `SpecValidationCode.DERIVED_VALUE_MISMATCH` (`derivedValueMismatch`),
  ordered by form path, and such fields are no longer reported as `valueTypeMismatch`. A `count_of`
  target written `./X` now counts only the entries beneath the section holding
  the form. The corpus cases `derivedValuesMatch`, `productMismatch`,
  `rankOutOfOrder`, `rankDuplicate` and `scopedCountMismatch` pin it.
- `SpecDocument.has_values_under` answers from a lazily built prefix index
  (every stored key plus each of its prefixes ending before a `/` or `-`),
  built on the first query and dropped by every mutator; rendering a large
  document is no longer quadratic. Results are identical to the former scan.
- Exact markdown round trip (SOM §11.3, §11.6, §11.7, §12.4). A heading's body
  region writes a slot marker `<!-- slot: <rel> -->` before any text the
  parser would otherwise bind elsewhere: text after something already written,
  text or a form preamble that is not the region's default target (first
  content slot, else the `content` form, else the first form), and a form
  whose field labels another form of the region shares. The import honours a
  marker naming `.` or a body slot of the owner (it ends any open field and
  sends the following text there; parts for one target join with a blank
  line); a marker naming no slot stays text. In a region with any form slot,
  every label-shaped text line gains one escape space on emit and loses it on
  import. A headline's line breaks are written as `<br>` in the heading and
  read back as `\n`. Blank lines inside a value are kept: neither the markdown
  emitter nor the YAML encoder collapses runs of empty lines any more
  (`dedup_empty_lines` stays as a helper the codec no longer calls).

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec.code`, `SomFormFieldMeta.code`) is written as an inline code
  span when its value is on one line — delimited by one backtick more than the
  longest run inside it, padded with a space when the value begins or ends with
  a backtick or a space — and the markdown import unwraps the span again, on
  both the id-bearing form section and the transparent form-slot path. A value
  written without a span is kept as written; a multi-line value keeps the plain
  rendering. Pinned by the regenerated corpus (`expected.md`, the new
  `Demo.details.pattern` and `Card.content.selector` fields, and two new
  `markdown_import_cases.json` cases).

## 1.5.0

- Released in lockstep with `tom_specs_model` 1.5.0. Two changes break a caller: the YAML decode's `review` is null when the file has no `review:` key (check for null where it was read as a map), and the model renames two section ids (see `tom_specs_model` 1.5.0).

- The CodeSpecs gate record carries Stage B's gap lines: an `insufficient` entry may hold `gaps:`, each a `CodeSpecsGateGap` with `sectionId`, `required` and `carrier` (`<section-id>.<field>`) and its `codespecs_prompt.md` §6.3 `line`. The reader refuses gaps on any other verdict, an unknown key in a gap, an empty field and a malformed carrier; the writer puts `gaps:` after `resolution`. Additive, so `formatVersion` stays 1. Pinned by new `codespecs_record_cases.json` cases.
- Markdown import stores a pattern-list item's heading id even when it equals the positional pattern default (`UCE-USER-1`), so the id survives a later move or insert and a document's `.md` imports to the same memory as its `.yaml` (SOM §11.5). A pattern-less list's `<member>-<n>` id stays positional. Pinned by the regenerated corpus (`state.json`, `expected.docspecs.yaml`) and each v0 package's Meridian import test.
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `SpecModel.is_generation_input` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings carry their document path (SOM §14): the Markdown renderer records the path behind every heading — `SpecDocumentMarkdown.export_root_with_map` / `SpecDocument.to_markdown_with_map` return a `SpecMarkdownRendition` (the markdown plus a 1-based heading line → path map, with `path_at_line`) — and the new `validate_spec_document(model, document, schema, root_type)` renders, validates and sets each violation's `path` from it. Pinned by the new `docspecs_path_cases.json`.
- A typed field (`int`, `double`, `num`, `bool`, nullable too) holding non-empty text its type cannot read is never read as unset (SOM §9): the new `somScalarBase` / `somTypedTextReadable` helpers (`som_scalar_base` / `som_typed_text_readable`) decide it, the editor's typed setters refuse such a string with an `ValueError`, the typed `value` / `formValue` reads throw naming the path, text and type, and `validateDocument` reports it as the new `valueTypeMismatch` code (scalar leaves; form fields without enum values or `countOf`). Pinned by the new `validation_cases.json` case and the `setRawFormField` / `valueUnreadable` / `formValueUnreadable` ops of `editor_cases.json`.
- The YAML codec encodes a document with no values as `document:` followed by `  <root key>: {}` — the same root key a non-empty document writes — instead of `document: {}`, because the root key is the file's only record of which document root it is (SOM §12.3 rule 4); decode still accepts `document: {}`. Pinned by the new `yaml_review_cases.json` round-trip case.
- Query engine: a list item (`listItemComplex` / `listItemScalar`) is known by its own effective section id — its stored id, else the list's `@SectionIdPattern` with the 1-based position, else `<list field>-<position>` — for the `sectionIdExact` / `sectionIdPrefix` filters and the projection's `sectionId`; a list's own id now matches only the list (llm_and_d4rt_tools.md §6). Pinned by the new `query_cases.json` cases and `projection_cases.json`.
- The YAML codec's decode returns the `review:` pass as `None` when the file has no `review:` key (an explicit `review: {}` or a bare `review:` still gives an empty map), so decode-then-encode no longer adds `review: {}` to a file without a review pass (SOM §12.1). Pinned by the new `yaml_review_cases.json` round-trip case.
- Markdown import: prose in a section whose owner has only form slots (a class-level `@Form` on the `content` member) is that form's preamble (SOM §11.6) — it binds to the `content` form slot, else the first form slot, with a label-shaped line's escape space stripped — instead of the owner's own path, which the model rejected. Pinned by the last `markdown_import_cases.json` case.
- A malformed CodeSpecs area catalogue row (a slice or step without a numeric `number`/`slice`, a string where a number belongs, an area without a non-empty `code`/`part`) now raises a `ValueError` that names the row, as the Dart reference does, instead of a bare `KeyError` or a coerced value. Pinned by the six `catalogErrorCases` of `codespecs_extract_cases.json`.
- Review-pass scalars keep their YAML 1.2 type (SOM §12.5): the `review:` pass is re-read with a core-schema PyYAML loader (`0o`/`0x` ints, `1e+300`, `.inf`/`.nan`, `TRUE`, `~`; `yes`/`on` stay strings; an integer beyond 64 bits reads as a float), and the new `review_scalar` writes floats so they read back as floats (`3.0`, `1e+300`, `1e-7`, `-.inf`). Pinned by two new `yaml_review_cases.json` cases.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item (vsctsa44): `SpecDocument.move_list_item(model,
  item_path, to_index, to_list=None)` moves an item to position `to_index` of
  its list, or of `to_list`, another list of the same element class, and
  returns a `SpecListItemMove` (`path`, `renamed` old → new item paths,
  `pinned_ids` new path → id). A path is a position, the section id is the
  identity: every affected list is renumbered to `<list>-1..n` (seq = n, an
  emptied list is dropped), every store key at or under an old item path is
  re-keyed, and an anonymous item whose positional id changes has its old id
  stored. Refusals change nothing: `ValueError` (not a live list item, not a
  model list, another element class, a stored id not fitting the destination
  `@SectionIdPattern`), `SpecSectionIdCollision` (the stored id is taken in
  the destination), `IndexError` (`to_index` out of range).
  `rekey_review(review, renamed)` (in `spec_document_yaml`) returns the
  `review:` pass re-keyed the same way. The `list_move_cases.json` corpus table
  pins both.
- Stated counts (vsctsa43): `FormFieldSpec.count_of` reads the meta's
  `formFields[].countOf` (absent → empty), and `validate_document` gains a
  sixth, instance-tier step after the reference check. A form field with
  `count_of` must hold a whole number equal to the entries the document holds:
  a target `X` counts every list item whose element class carries
  `@SectionId(X)`, `X.f=v` only those whose own form holds `v` in `f`, summed
  over the targets. A blank value, or a target outside the document's registry
  scope, is skipped; anything else that does not match is reported under the
  new `SpecValidationCode.COUNT_MISMATCH` (`countMismatch`). The corpus cases
  `countMatches` and `countMismatch` pin it.
- Document assembly: a new module `spec_document_assembly` merges fragments
  written in parallel into one document. `SpecDocument.assemble(fragments)`
  (also `assemble_spec_documents`) takes an ordered sequence of
  `(name, SpecDocument)` pairs (or a mapping) and merges the plain-data stores
  of `to_json()`: content, headlines and code-spec locations one value per
  path, forms field by field, lists whole. The merge is refusing — a place two
  fragments both write is a `SpecAssemblyOverlap` (`store`, `path`, `field`,
  `fragments`, `message`) and the `SpecDocumentAssembly` then carries no
  `document` (`ok` is false). Overlaps are reported in store order, then path
  order. The `assembly_cases.json` corpus table pins it.
- CodeSpecs gate: a new module `spec_codespecs_gate` runs Stage A of
  `codespecs_prompt.md` §4 as one `CodeSpecsGate(model, document, catalog,
  schema=None, root_type=None).run()`, returning a `CodeSpecsGateReport` with
  one `CodeSpecsGateCheckResult` per check A1–A5 (`ran`, `not_run_reason`,
  `findings`, `passed`), the extraction run's `extracts` when A3 passed, and
  `report[check]` lookup. A1 validates the rendered Markdown against the
  DocSpecs schema, A2 runs `validate_document`, A3 reports every unrouted
  section of the non-strict walk (or the root-resolution error), A4 holds each
  required marker argument of a used area to a populated source (with the
  `when` filter and `resolves_to` check), A5 checks every carrier still exists
  in the model. A check that cannot run is reported not run, with its reason,
  and fails the gate. `CodeSpecsAreaCatalog.from_json` reads the optional
  `gate` key into `required_arguments` (`CodeSpecsRequiredArgument`),
  `carriers` (`CodeSpecsCarrier`) and `has_gate_tables`; field references are
  `CodeSpecsFieldRef`. The `codespecs_gate_cases.json` corpus table pins it.
- CodeSpecs records: a new module `spec_codespecs_records` reads back what a
  Phase-4 run wrote. `CodeSpecsExtract.from_yaml(text, source)` (also
  `parse_code_specs_extract_yaml`) is the inverse of `to_yaml` — byte-stable
  for every extract the extractor writes; it requires `formatVersion` 3 and a
  non-empty `area.code`, reads every other absent key as empty, refuses a
  present key of the wrong type and a `document.entryCount` that disagrees
  with the entries. `CodeSpecsGateRecord` reads, checks and writes the Stage-B
  gate record `gate.verdicts.yaml` (`from_yaml`, `to_yaml`, `verdict_for`,
  `check_against(catalog)`, `with_verdict`), with `CodeSpecsGateVerdict` and
  `CodeSpecsGateEntry`. `CodeSpecsExtractSet.from_files(pairs)` /
  `from_directory(path)` read a tree of extracts scoped by its gate record
  (`extracts`, `sources`, `excluded`, `gate`, `by_area`,
  `entries_for_section`, `entries_at_path`). Errors are
  `CodeSpecsRecordError`. The YAML is read through a PyYAML loader narrowed to
  YAML 1.2 booleans, without implicit timestamps and refusing duplicate keys,
  so it reads what `package:yaml` reads. The `codespecs_record_cases.json`
  corpus table pins it.
- CodeSpecs catalogue: `CodeSpecsAreaCatalog.steps` carries the
  `codespecs_mapping.md` §4.4.6 authoring-step table as `CodeSpecsStep` rows
  (`number`, `title`, `slice`, `placed_by`, `area_codes`); a catalogue without
  a `steps` key loads with none. `step_numbered(n)` finds one step and
  `steps_for(area)` returns the steps of `area.authoring_steps` in that order,
  skipping numbers the catalogue does not carry. `CodeSpecsStep` is exported
  from `tom_som_runtime`. The `stepCases` table of
  `codespecs_extract_cases.json` pins it.
- DocSpecs: `DocSpecsDocument.replace_section_body(text, section_id, body)`
  returns the markdown with one section's own body region replaced and every
  other byte kept; it raises `ValueError` when the id names no section or
  several, or when the body holds a heading outside a fence or leaves a fence
  open. `DocSpecsDocument.all_sections` lists every section depth-first. The
  `docspecs_replace_cases.json` corpus table pins it.
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
- Markdown import: `SpecDocument.apply_markdown_result(result,
  allow_rejections=False)` applies a parsed import as a full overwrite of the
  roots it covers, keeping every other root; a result with rejections raises
  `RuntimeError` and changes nothing unless `allow_rejections` is set.
  `SpecDocument.from_markdown(text, model)` parses and applies in one call and
  returns a `SpecMarkdownImport` (document, result, rejections). Pinned by the
  corpus table `markdown_apply_cases.json`.
- YAML codec: `encode(..., review=...)` writes the `review:` pass back after
  the document pass (`write_review_pass`): entries sorted by path with
  JSON-quoted keys, fields sorted by name, identifier-like strings, booleans
  and numbers plain, other strings as self-verified block scalars, lists as
  JSON flow, an empty map as `review: {}`; a decoded reviewed file now
  round-trips byte for byte. `stale_review_paths(model, document, review)`
  lists (sorted) the review entries that no longer resolve — unknown paths and
  paths through a removed list item. Pinned by the corpus table
  `yaml_review_cases.json`.

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- First packaged release of the generic Python SOM runtime.
- Version tracks the TomSpecs model version; the typed `tom_som_python_v0` facade
  pins the same version.
