# Changelog

## Unreleased

- Listing a value's paragraphs (SOM §11.9.1, annot8), a port of the Dart
  reference: `SpecReviewAnnotations::paragraphs(path, field)` returns
  `SpecParagraph`s (`index`, `startLine`, `endLine`, `text`, and the
  `annotation` kind when the paragraph opens an annotation block;
  `toJson`). The index is exactly what `afterParagraph` of the inserts
  takes; a value the document does not hold throws
  `SpecReviewAnnotationError`. Conformance: the `paragraphs` op of
  `annotation_cases.json`.

- Question options (SOM §11.9.2, annot7), in `spec_review_annotations`, a
  port of the Dart reference: a listed question carries its `options`
  (`SpecQuestionOption`: `letter`, `text` with continuation lines joined,
  `bold`) and its `recommended` letter (the bold option, else the option that
  says "recommended", else the letter of a `*Recommendation:*` line);
  `SpecReviewAnnotation::answerLetter()` reads the `(b)` / `**(b)**` an answer
  starts with. The question JSON gains `options`, `recommended` and
  `answerLetter`. `SpecQuestionDraft::recommended` makes
  `formatQuestionBlock` write that option bold, `- **(b)** …`.

- Extracting answers for a step folder (SOM §11.9.7, annot6), a new module
  `spec_answers` ported from the Dart reference: `som::extractAnswers(model,
  doc, label, path)` returns a `SpecAnswerExtract` (`label`, `qualifier`,
  `SpecAnswerEntry` entries with kind, id, section-id chain and rendition line,
  in rendition order; `counts()` gives a `SpecAnswerCounts`), and
  `som::renderAnswers(extracts, options)` writes the `answers.md` text
  (`SpecAnswerRenderOptions`: `includeOpen`, `includeMarks`, `title`). The
  conformance harness runs `answer_cases.json`. Guide:
  `doc/review_annotations.md`, "Extracting answers for a step folder".

- Writing changes as inline marks (SOM §11.9.3, annot5), in
  `spec_review_annotations`, a port of the Dart reference:
  `som::markChangeText(old, new)` diffs by line, then by word, merging changes
  at most two words apart, so accepting all marks gives `new` and rejecting
  all gives `old`; words are never split and code is never marked. It returns
  a `SpecMarkedChange` (`text`, `exact`, `toJson()`).
  `SpecReviewAnnotations::setMarked` (a second edit updates its mark) and
  `markAgainst` (against an earlier version) apply it to a value. The
  conformance harness runs `change_mark_cases.json`. Guide:
  `doc/review_annotations.md`, "Writing changes as marks".

- Inline-mark review (SOM §11.9.3, annot4), in `spec_review_annotations`, a
  port of the Dart reference. `SpecReviewAnnotations` gains `revision()`
  (FNV-1a 64-bit, 16 hex digits), `listMarks(path)` (`SpecMarkEntry`, ids
  `M-<n>`), `decideMarks(decisions, revision)` (throws
  `SpecReviewAnnotationError` on a stale revision or an unknown id),
  `acceptAllMarks(path)`, `rejectAllMarks(path)` and `removeAllAnnotations()`;
  the free function `applyInlineMarksText(text, accept)` works on one value.
  New `enum class SpecMarkDecision` (`specMarkDecisionName`,
  `specMarkDecisionFromName`); every operation returns a `SpecMarkReport` of
  `SpecMarkOutcome`s and `SpecMarkIssue`s (`unclosed`, `nested`, `noArrow`),
  each with `toJson()`. Accepting or rejecting a mark (also `applyMark`) now
  follows the full whitespace rules: tabs count as spaces, `]` and `}` join
  the punctuation set, and a mark that was a whole line takes its line with
  it. The conformance harness runs `inline_mark_cases.json`. Guide:
  `doc/review_annotations.md`, "Reviewing inline marks".

- Review annotations (SOM §11.9, annot2). New module `spec_review_annotations`
  (`include/spec_review_annotations.hpp`, in the umbrella header), a port of
  the Dart `spec_review_annotations.dart`: `som::SpecReviewAnnotations` lists
  comment blocks, question blocks and CriticMarkup inline marks in document
  order (`list()` → `SpecReviewAnnotation`, `toJson()`), counts them
  (`SpecReviewAnnotationCounts`), hands out comment ids (`nextCommentId`,
  `assignCommentIds`), inserts comments and questions (`insertComment`,
  `insertQuestion`, `insertQuestionAfterComment`, with `SpecQuestionDraft`),
  answers and edits them (`setAnswer`, `editComment`), removes them
  (`resolve`), accepts or rejects marks (`applyMark`) and strips a copy
  (`stripped`, `stripAnnotationsText`). Enums `SpecReviewAnnotationKind` and
  `SpecMarkKind`; a missing comment, question, paragraph or mark throws
  `SpecReviewAnnotationError` and changes nothing. Positions are 0-based line
  numbers within a value. Three new validation codes after
  `multipleReferences`: `kSpecValidationCodeAnnotationMisplaced`
  (`"annotationMisplaced"`), `kSpecValidationCodeAnnotationMalformed`
  (`"annotationMalformed"`) and `kSpecValidationCodeDuplicateAnnotationId`
  (`"duplicateAnnotationId"`), reported by `validateDocument` as its last
  group (`validateReviewAnnotations`), stable-sorted by path. The conformance
  harness runs `annotation_cases.json`; the four new validation cases pin the
  codes. Guide: `doc/review_annotations.md`.

- Single-reference check (uamtc17). `FormFieldSpec` gains `multiple` (bool, read from the meta's `formFields[].multiple`, absent = false). New validation code
  `kSpecValidationCodeMultipleReferences` (`"multipleReferences"`), after `missingRequiredField`. In the
  reference phase of `validate_document`, a `refersTo` field not marked
  `multiple` whose value splits (on `,`, trimmed, empty parts dropped) into
  more than one id reports one `multipleReferences` at the form path, before
  the registry-scope test; every id is still resolved, so dangling ones still
  report `danglingReference`. Pinned by the `multipleReferencesInSingleField`
  and `everyDanglingIdOfAList` validation cases.

- Required form fields (uamtc16). New validation code `kSpecValidationCodeMissingRequiredField`
  (`"missingRequiredField"`), after `derivedValueMismatch`. In the form phase
  of `validate_document`, every form path that resolves to a form reports, in
  declared order, each model field marked `required` whose stored value is
  absent or empty after trimming, at the form path. It runs on every form the
  document holds (class-level `content` forms and member forms, in list items
  or not). Pinned by the `requiredFieldsFilled`,
  `missingRequiredFieldInListItemForms` and `missingRequiredFieldInMemberForm`
  validation cases and the extended `unknownFormField` case; the conformance
  model's class count is now 15 (`RequiredEntry`).

- Derived values (uamtc10). `FormFieldSpec` gains `productOf` (read from the
  meta's `formFields[].productOf`; empty when absent) and `rankOf`
  (`std::optional<std::string>`, from `rankOf`). `validateDocument` gains
  phase 7, after the count check: a `productOf` field must hold the product of
  its operands (`name` of the same form or `FORMSID.name` of the sibling form;
  an enum operand counts as its 1-based position), held to the precision the
  value is written in; a `rankOf` field must rank the instances of its form 1
  to n, each once, highest score first. Either is reported as
  `kSpecValidationCodeDerivedValueMismatch` (`"derivedValueMismatch"`) at the
  form path; the phase's findings are stable-sorted by path. Such fields are
  no longer reported as `valueTypeMismatch`. A `countOf` target written `./X`
  (or `./X.f=v`) now counts only the entries beneath the section holding the
  form. Pinned by the `derivedValuesMatch`, `productMismatch`,
  `rankOutOfOrder`, `rankDuplicate` and `scopedCountMismatch` validation cases.

- Exact markdown round trip (SOM §11.3, §11.6, §11.7, §12.4): a section's body
  region writes a slot marker `<!-- slot: <rel> -->` before text the parser
  would otherwise bind elsewhere — text after anything already written, text
  of a slot that is not the region's default target, a form preamble that is
  not the default target, and a form whose labels another form of the region
  shares — and the parser sends the text after a marker to the named slot (a
  content slot, a form preamble, or `.` for the owner), ending any open field;
  a marker naming no slot is plain text. In a region with any form slot every
  label-shaped text line is written with one leading escape space and read
  back without it. A stored headline's line breaks are written as `<br>` in
  the heading title and read back as `\n`. Blank lines inside a value are no
  longer collapsed, neither by the markdown emitter nor by the YAML encoder
  (`specYamlDedupEmptyLines` stays as a helper); the YAML round-trip test now
  asserts preservation (`rt.emptyLinesKept`).
- `SpecDocument::hasValuesUnder` answers from a lazily built prefix index (every
  stored key plus each of its prefixes ending before a `/` or a `-`) instead of
  scanning every key of the five stores per call; every mutator drops the
  index, and a copied or moved document never carries one along. Results are
  unchanged; rendering, validating or querying a large document is no longer
  quadratic. Pinned by `tests/has_values_under_index_test.cpp`.

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec::code`, `SomFormFieldMeta::code`) is written as an inline
  code span when its value is on one line — delimited by one backtick more than
  the longest run inside it, padded with a space when the value begins or ends
  with a backtick or a space — and the markdown import unwraps the span again,
  on both the id-bearing form path and the transparent form-slot path. A value
  written without a span is kept as written; a multi-line value keeps the plain
  rendering. The generated facade meta passes the flag as the trailing
  `SomFormFieldMeta` member. Pinned by the regenerated corpus (`expected.md`,
  the new `Demo.details.pattern` and `Card.content.selector` fields, and two new
  `markdown_import_cases.json` cases).

## 1.5.0

- Released in lockstep with `tom_specs_model` 1.5.0. Two changes break a caller: the YAML decode's `review` is null when the file has no `review:` key (check for null where it was read as a map), and the model renames two section ids (see `tom_specs_model` 1.5.0).

- The CodeSpecs gate record carries Stage B's gap lines: an `insufficient` entry may hold `gaps:`, each a `CodeSpecsGateGap` with `sectionId`, `required` and `carrier` (`<section-id>.<field>`) and its `codespecs_prompt.md` §6.3 `line`. The reader refuses gaps on any other verdict, an unknown key in a gap, an empty field and a malformed carrier; the writer puts `gaps:` after `resolution`. Additive, so `formatVersion` stays 1. Pinned by new `codespecs_record_cases.json` cases.
- Markdown import stores a pattern-list item's heading id even when it equals the positional pattern default (`UCE-USER-1`), so the id survives a later move or insert and a document's `.md` imports to the same memory as its `.yaml` (SOM §11.5). A pattern-less list's `<member>-<n>` id stays positional. Pinned by the regenerated corpus (`state.json`, `expected.docspecs.yaml`) and each v0 package's Meridian import test.
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `SpecModel::isGenerationInput` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings carry their document path (SOM §14): `markdownExportRootWithMap` / `documentToMarkdownWithMap` / `SpecDocument::toMarkdownWithMap` return a `SpecMarkdownRendition` (markdown identical to the plain export, plus a 1-based heading line → document path map with `pathAtLine`), and the new `validateSpecDocument` (`spec_schema_validation.hpp`) renders, validates and fills each violation's `path`; conformance replays `docspecs_path_cases.json`.
- A typed field (`int` / `double` / `num` / `bool`, nullable too) holding non-empty text its type cannot read (SOM §9): `SpecEditor::setValue` / `setFormValue` refuse such a string (`std::invalid_argument`), `SpecEditor::value` / `formValue` now throw `std::invalid_argument` on such stored text instead of returning null, and `validateDocument` reports the new `valueTypeMismatch` (`kSpecValidationCodeValueTypeMismatch`) for a scalar leaf and for a non-enum, non-`countOf` form field; new helpers `somScalarBase` / `somTypedTextReadable`.
- `encodeYaml`: a document with no values encodes as `document:` + `  <root key>: {}`, keeping the root key (the file's only record of its document root), never `document: {}`; decode still accepts `document: {}` (SOM §12.3 rule 4).
- Query engine (`SpecQueryEngine::sectionIdOf`): a list item (`listItemComplex` / `listItemScalar`) is known by its own effective section id — stored id, else the list's `@SectionIdPattern` with its 1-based position, else `<member>-<position>` — for `sectionIdExact` / `sectionIdPrefix` and the projected `sectionId`; other nodes keep the model `@SectionId` (llm_and_d4rt_tools.md §6).
- `decodeYaml`: `SpecYamlContents::review` is `nullptr` when the file has no `review:` key and a (possibly empty) YAML_MAP when it has one (a bare `review:` included), so a document without a review pass round-trips without gaining `review: {}` (SOM §12.1).
- Markdown import (`MdParser::finalizeBodySlots`): prose under a heading whose owner has no content slot but has form slots (a class-level `@Form` on `content`) is that form's preamble (SOM §11.6) — bound to the `content` form slot, else the first, with a label-shaped line's escape space stripped — instead of landing on the owner's own path (kindMismatch).
- `CodeSpecsAreaCatalog::fromJson` (via `CodeSpecsSlice`/`CodeSpecsStep`/`CodeSpecsArea::fromJson`) throws `std::invalid_argument` naming the row when a slice/step lacks a numeric `number`/`slice` or an area a non-empty `code`/`part`, as Dart does, instead of reading 0 / empty.
- Review-pass scalars are typed by the YAML 1.2 core schema (SOM §12.5): an
  integer beyond 64 bits (decimal, `0o`, `0x`) is a float rather than
  saturated, a float must match the core-schema spelling, an empty value is
  null, and non-finite floats are written `.nan` / `.inf` / `-.inf`.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item (vsctsa44). `SpecDocument::moveListItem(model,
  itemPath, toIndex, toList)` moves the item to an index of its own list or,
  given `toList`, of another list of the same element class. A path is a
  position, the section id is the identity: every affected list is renumbered
  to `<list>-1..n` (seq = n, an emptied list dropped), every store key at or
  under an old item path — content, forms, headlines, codeSpecs, item ids,
  list keys and items, seq keys — is re-keyed to the new path, and an
  anonymous item whose positional id changes stores its old one (the moved
  item is not pinned when it crosses lists). Refusals change nothing:
  `std::invalid_argument` (not a live item, not a model list, another element
  class, a stored id not fitting the destination's `@SectionIdPattern`),
  `SomSectionIdError` (collision: the stored id is taken in the destination)
  or `std::out_of_range`. The result, `SpecListItemMove` (`path`, `renamed`,
  `pinnedIds` as ordered `SpecPathPairs`), feeds `specYamlRekeyReview`, which
  returns a review map re-keyed the same way, and `specRekeyPath`. The
  conformance runner checks every case of `list_move_cases.json`
  (`listMove[...]`).

- Stated counts (vsctsa43). `FormFieldSpec::countOf` (read from the meta's
  `formFields[].countOf`; empty when absent) names the entries a form field's
  value counts — `X` for every list item whose element class carries
  `@SectionId(X)`, `X.f=v` for those whose own form holds `v` in form field
  `f`. `validateDocument` gains phase 6, after the reference check: a
  non-empty value that is not a whole number, or not the summed count, is
  reported as `kSpecValidationCodeCountMismatch` (`"countMismatch"`) at the
  form path, with the Dart reference's messages; a field with any target
  outside the document's registry scope is skipped. The conformance runner
  checks the `countMatches` / `countMismatch` validation cases.

- Assembling one document from fragments written in parallel
  (`spec_document_assembly.hpp`). `SpecDocument::assemble` (and the free
  `assembleSpecDocuments`) takes `SpecAssemblyFragments`, an ordered
  `std::vector` of name/document pairs, and returns a `SpecDocumentAssembly` —
  the assembled `document` or, when any place is written by two or more
  fragments, `std::nullopt` and every `SpecAssemblyOverlap` (`store`, `path`,
  `field` for forms, `fragments` in the given order, `message()`). Content,
  headlines and codeSpecs overlap per path, forms per (path, field) — two
  fragments may fill different fields of one form — and lists per list path.
  Overlaps come in store order content, forms, lists, headlines, codeSpecs,
  then path order; `ok()` is true when there are none. The conformance runner
  checks every case of `assembly_cases.json` (`assembly[...]`).

- CodeSpecs: the Stage-A gate (`codespecs_prompt.md` §4, A1–A5) as one
  `CodeSpecsGate` (`spec_codespecs_gate.hpp`). It borrows a model, document,
  catalogue, optional DocSpecs schema and optional root type; `run()` returns
  a `CodeSpecsGateReport` — one `CodeSpecsGateCheckResult` per check (`ran`,
  `notRunReason`, the `CodeSpecsGateFinding`s with `code` / `location` /
  `message`), the extraction run's `extracts` when A3 passed, `passed()`,
  `findings()` and lookup by `CodeSpecsGateCheck`. Every check runs; a check
  that cannot run (no schema, no gate tables, no extraction run) is reported
  not run, with the Dart reference's reason, and fails the gate. A1 renders
  the document to Markdown and validates it with the DocSpecs validator; A2 is
  `validateDocument`; A3 collects every unrouted class of the routing walk (or
  the root-resolution error) before extracting; A4 checks the catalogue's
  required marker arguments against the extracts; A5 checks its carriers
  against the model. `CodeSpecsAreaCatalog::fromJson` reads the optional
  `gate` block: `CodeSpecsFieldRef` (`source()`), `CodeSpecsRequiredArgument`
  (optional `resolvesTo` / `when` + `whenEquals`), `CodeSpecsCarrier`, and the
  catalogue's `requiredArguments`, `carriers` and `hasGateTables`. The
  conformance runner checks every case of `codespecs_gate_cases.json`
  (`codespecsGate[...]`).
- Fix: `specYamlNodeKey` compared a node's `kind` with the kind constants by
  pointer. Two translation units need not share one copy of a string literal,
  and under AddressSanitizer they do not, so a section or complex node lost its
  class section id from its YAML key (`control:` for `CTRL control:`). Kinds
  are compared by content now.

- CodeSpecs: reading Phase-4 output back (`spec_codespecs_records.hpp`).
  `CodeSpecsExtract::fromYaml` / `parseCodeSpecsExtractYaml` parse a
  `<CE-CODE>.extract.yaml` — the inverse of `toYaml`, byte-identical on the
  round trip — refusing an unknown `formatVersion`, a missing `area` /
  `area.code`, a wrongly typed key and a `document.entryCount` that disagrees
  with the entries. The Stage-B gate record: `CodeSpecsGateVerdict`
  (`codeSpecsGateVerdictWord` / `parseCodeSpecsGateVerdict`),
  `CodeSpecsGateEntry`, and `CodeSpecsGateRecord`, whose constructor and
  `fromYaml` admit only the checked shape, with `verdictFor`, `checkAgainst` (a
  catalogue's active areas), `withVerdict` and the byte-stable `toYaml`.
  `CodeSpecsExtractSet::fromFiles` (an ordered vector of name/text pairs) and
  `fromDirectory` scope a run's extracts by its gate record — in scope iff
  `sufficient`, excluded areas kept visible as `CodeSpecsExcludedArea` — with
  `byArea`, `entriesForSection` and `entriesAtPath`. Failures throw
  `CodeSpecsRecordError` carrying the Dart reference's message.
  `codeSpecsYamlString` exposes the extract's string escaper. The conformance
  runner checks every case of `codespecs_record_cases.json`
  (`codespecsRecords.*`).

- CodeSpecs: the area catalogue carries the `codespecs_mapping.md` §4.4.6
  authoring-step table. `CodeSpecsStep` (`number`, `title`, `slice`,
  `placedBy`, `areaCodes`) and `CodeSpecsAreaCatalog::steps`, read from the
  catalogue's `steps` array — absent in an older catalogue, which loads with
  no steps. `CodeSpecsAreaCatalog::stepNumbered(number)` returns the step or
  null; `stepsFor(area)` returns the area's steps in its `authoringSteps`
  order, skipping numbers the catalogue does not carry. The conformance runner
  recomputes `stepCases` from `codespecs_extract_cases.json` (including the
  legacy catalogue with `steps` removed) and compares it with the committed
  table (`codeSpecsExtract.stepCases`).

- DocSpecs: `DocSpecsDocument::replaceSectionBody(text, sectionId, body)`
  returns `text` with the own body of the section whose id is `sectionId`
  replaced: a blank line, `body` without its leading and trailing blank lines,
  a blank line (a single blank line for an empty body); the heading, the
  subsections and every other byte are kept. The region is found by the
  fence-aware parse. Throws `std::invalid_argument` when the id names no
  section or more than one (listing their lines), and when the body holds a
  heading outside a fenced block or leaves a fence open.
  `DocSpecsDocument::allSections()` lists every section depth-first. The
  conformance runner checks it against `docspecs_replace_cases.json`
  (`docspecsReplace[...]`).

- YAML codec: the `review:` pass is written back. `encodeYaml` takes an optional
  `review` (`const YamlValue*`, typically `SpecYamlContents::review.get()`);
  when given, `specYamlWriteReviewPass` appends it after the document pass:
  `review: {}` when empty, else entries sorted by path with JSON-quoted keys,
  each entry's fields sorted by name; null, booleans, numbers and
  identifier-like strings plain, lists as JSON flow, any other string as a
  self-verified block scalar. A decoded plain scalar now carries
  `YamlValue::plain`, so `true`, `null` and numbers keep their YAML type on the
  way back. `specYamlStaleReviewPaths(model, document, review)` lists, sorted,
  the review paths the model no longer resolves or that run through a list item
  the document no longer holds. The conformance runner checks both against
  `yaml_review_cases.json` (`yamlReview[...]`).

- Markdown import: `SpecDocument::applyMarkdownResult(result,
  allowRejections)` applies a parsed import as a full overwrite of the roots
  it covers (SOM §11.7): every value under each root prefix is removed, then
  the parsed content, forms, lists (seq, items, ids), headlines and codeSpecs
  are written; other roots are kept. A result with rejections is refused with
  `std::runtime_error` and nothing changes, unless `allowRejections` is true.
  `SpecDocument::fromMarkdown(text, model)` parses and applies in one call and
  returns a `SpecMarkdownImport` (`document`, `result`, `rejections()`). The
  conformance runner checks both against `markdown_apply_cases.json`, and the
  Markdown-to-memory landing check now goes through `fromMarkdown`.
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

- Generic TomSpecs object-model runtime for idiomatic C++ (C++17, RAII):
  section-path grammar, meta-data model loader, reflection/resolution, sparse
  document, validator, and the YAML/Markdown codecs, plus a hand-rolled JSON
  reader/encoder — built on `std::string` / `std::vector` /
  `std::map<std::string, …>` (byte-ordered, matching the C `SomMap`).
- Zero external dependencies (C++ standard library only); validated against the
  shared language-agnostic conformance corpus.
- Packaged with a `Makefile` that builds a static (`.a`) and a shared (`.so`)
  library, emits a `pkg-config` file (`tom_som_cpp_runtime.pc`) whose `Version`
  tracks the model version, and provides `make install` and `make dist`
  (source tarball) targets.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its `Makefile` `VERSION` is realigned by
  `tom_specs_clitool/bin/generate_som.dart`.
