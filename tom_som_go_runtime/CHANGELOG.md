# Changelog

## Unreleased

- Question options (SOM §11.9.2): a listed question carries its `Options`
  (`SpecQuestionOption`: `Letter`, `Text` with continuation lines joined,
  `Bold`), its `Recommended` letter (the bold option, else the option that
  says "recommended", else the letter of a `*Recommendation:*` line) and
  `AnswerLetter()` (`(b)` or `**(b)**` at the start of the answer), all in
  `ToJSON()`. `SpecQuestionDraft.Recommended` makes `FormatQuestionBlock`
  write that option bold.

- Extracting answers for a step folder (SOM §11.9.7):
  `ExtractAnswers(model, doc, label, path)` collects a document's questions
  (answered and open), comments and inline marks, each with its section-id
  chain and its line in the Markdown rendition, as a `SpecAnswerExtract` of
  `SpecAnswerEntry`s (`SpecAnswerKind`, `SpecAnswerCounts`).
  `RenderAnswers(extracts, options)` writes them as the step folder's
  `answers.md`; `SpecAnswerRenderOptions` (`DefaultSpecAnswerRenderOptions`)
  adds the open questions and the inline marks and sets the title. The
  conformance runner replays `answer_cases.json`.

- Writing changes as inline marks (SOM §11.9.3): `MarkChangeText(old, new)`
  diffs by line, then by word, merging changes at most two words apart, so
  accepting all marks gives `new` and rejecting all gives `old`. Words are
  never split and code is never marked. It returns a `SpecMarkedChange`
  (`Text`, `Exact`). `SpecReviewAnnotations.SetMarked` (a second edit updates
  its mark) and `MarkAgainst` (against an earlier version) apply it to a
  value. The conformance runner replays `change_mark_cases.json`.

- Reviewing inline marks (SOM §11.9.3): `SpecReviewAnnotations` gains
  `Revision`, `ListMarks(path)`, `DecideMarks(decisions, revision)` (accept /
  reject / leave in one write, refused with a `*SpecReviewAnnotationError` on
  a stale revision or an unknown id), `AcceptAllMarks(path)` /
  `RejectAllMarks(path)` and `RemoveAllAnnotations`, plus the function
  `ApplyInlineMarksText(text, accept)`. Each operation returns a
  `SpecMarkReport` (`SpecMarkOutcome`s and `SpecMarkIssue`s) for the decision
  log; marks are listed as `SpecMarkEntry` and decided with
  `SpecMarkDecision` (`SpecMarkDecisionAccept`, `…Reject`, `…Leave`, all in
  `SpecMarkDecisions`). Accepting and rejecting follow the SOM §11.9.3
  whitespace rules (words never join, no double space or space before
  punctuation, a whole-line mark leaves no blank line), and `ApplyMark` and
  `StripAnnotationsText` now follow them too. Malformed marks are left as
  written and reported. The conformance runner replays
  `inline_mark_cases.json`.

- Review annotations (SOM §11.9): `SpecReviewAnnotations`
  (`NewSpecReviewAnnotations(doc, qualifier)`) lists and edits comment blocks,
  question blocks and CriticMarkup inline marks in content and form-field
  values — `List`, `Counts`, `NextCommentID`, `AssignCommentIDs`,
  `InsertComment`, `InsertQuestion`, `InsertQuestionAfterComment`,
  `SetAnswer`, `EditComment`, `Resolve`, `ApplyMark`, `Stripped`, `Validate` —
  with `SpecReviewAnnotation`, `SpecReviewAnnotationKind`, `SpecMarkKind`,
  `SpecQuestionDraft`, `SpecReviewAnnotationCounts`,
  `SpecReviewAnnotationError`, `StripAnnotationsText`, `FormatCommentBlock`
  and `FormatQuestionBlock`. Positions are 0-based line numbers within a
  value. `ValidateDocument` gains a last group (ordered by path) with three
  new codes: `SpecValidationCodeAnnotationMisplaced` (`annotationMisplaced`),
  `SpecValidationCodeAnnotationMalformed` (`annotationMalformed`) and
  `SpecValidationCodeDuplicateAnnotationID` (`duplicateAnnotationId`). The
  conformance runner replays `annotation_cases.json`; the guide is
  `doc/review_annotations.md`.

- Single-reference fields (uamtc17): `FormFieldSpec.Multiple` (meta
  `formFields[].multiple`, absent → false). `ValidateDocument` reports the new
  `SpecValidationCodeMultipleReferences` (`multipleReferences`) in the reference phase: a reference field
  without `multiple` whose value splits on `,` into more than one non-empty
  id gets one error at the form path, checked before the registry-scope test;
  every id is still resolved, so dangling ones also report
  `danglingReference`. The corpus cases `multipleReferencesInSingleField` and
  `everyDanglingIdOfAList` pin it.

- Required form fields (uamtc16): `ValidateDocument` reports the new
  `SpecValidationCodeMissingRequiredField` (`missingRequiredField`) in the
  form-section step — for every form path the document holds that resolves to
  a form, each declared form field with `Required` set (meta
  `formFields[].required`) whose value is absent or blank after trimming, in
  declared order. The corpus cases `requiredFieldsFilled`,
  `missingRequiredFieldInListItemForms` and `missingRequiredFieldInMemberForm`
  pin it; the corpus model holds 15 classes.
- Derived values (uamtc10): `FormFieldSpec.ProductOf` (meta
  `formFields[].productOf`, absent → empty slice) and `FormFieldSpec.RankOf`
  (meta `formFields[].rankOf`, absent → empty string). `ValidateDocument`
  gains an instance-tier step right after the count check (one group ordered
  by form path), reporting the new
  `SpecValidationCodeDerivedValueMismatch` (`derivedValueMismatch`): a
  `ProductOf` field must hold a number equal to the product of its operands
  (`f` of the same form, `F.f` of the sibling form `F`; an enum operand
  counts as its 1-based position) to the precision it is written in; a
  `RankOf` field must rank the instances of its form 1 to n, each once, with
  no instance ranked below one with a lower score. Undecidable operands skip
  the check; a stated value that is no number is always reported. Such fields
  are no longer reported as `valueTypeMismatch`. A `countOf` target written
  `./X` now counts only the entries beneath the section holding the form.
  The corpus cases `derivedValuesMatch`, `productMismatch`, `rankOutOfOrder`,
  `rankDuplicate` and `scopedCountMismatch` pin it.
- `SpecDocument.HasValuesUnder` answers from a lazily built prefix index
  (every stored key plus each of its prefixes ending before a `/` or `-`),
  dropped by every mutator, instead of scanning every stored key per call.
  Rendering a large document is no longer quadratic; results are unchanged.
- Exact markdown round trip (SOM §11.3, §11.6, §11.7, §12.4): a heading body
  that holds several slots precedes a slot with a slot marker
  (`<!-- slot: <rel> -->`) wherever the parser would otherwise bind its text
  elsewhere — text after anything already written, a text slot that is not
  the region's default target, a form preamble that is not the default
  target, and a form whose labels another form of the region shares. The
  import routes the text after a marker to the named slot (`.` for the owner
  itself) and ends any open field; a marker naming no slot stays text. A
  headline's line breaks are written as `<br>` and read back as `\n`. Blank
  lines inside a value are kept on both the markdown and the YAML side (the
  `\n{3,}` collapse is gone; `DedupEmptyLines` remains as a helper). In a
  region with any form, every label-shaped text line — content, preamble or
  continuation — carries one escape space, stripped again on import.

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec.Code`, `SomFormFieldMeta.Code`) is written as an inline code
  span when its value is on one line — delimited by one backtick more than the
  longest run inside it, padded with a space when the value begins or ends with
  a backtick or a space — and the markdown import unwraps the span again. A
  value written without a span is kept as written; a multi-line value keeps the
  plain rendering. Pinned by the regenerated corpus (`expected.md`, the new
  `Demo.details.pattern` and `Card.content.selector` fields, and two new
  `markdown_import_cases.json` cases).

## 1.5.0

- Released in lockstep with `tom_specs_model` 1.5.0. Two changes break a caller: the YAML decode's `review` is null when the file has no `review:` key (check for null where it was read as a map), and the model renames two section ids (see `tom_specs_model` 1.5.0).

- The CodeSpecs gate record carries Stage B's gap lines: an `insufficient` entry may hold `gaps:`, each a `CodeSpecsGateGap` with `sectionId`, `required` and `carrier` (`<section-id>.<field>`) and its `codespecs_prompt.md` §6.3 `line`. The reader refuses gaps on any other verdict, an unknown key in a gap, an empty field and a malformed carrier; the writer puts `gaps:` after `resolution`. Additive, so `formatVersion` stays 1. Pinned by new `codespecs_record_cases.json` cases.
- Markdown import stores a pattern-list item's heading id even when it equals the positional pattern default (`UCE-USER-1`), so the id survives a later move or insert and a document's `.md` imports to the same memory as its `.yaml` (SOM §11.5). A pattern-less list's `<member>-<n>` id stays positional. Pinned by the regenerated corpus (`state.json`, `expected.docspecs.yaml`) and each v0 package's Meridian import test.
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `(*SpecModel).IsGenerationInput` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings carry their document path (SOM §14): `SpecDocumentMarkdown.ExportRootWithMap` / `SpecDocument.ToMarkdownWithMap` return a `SpecMarkdownRendition` (the `ExportRoot` text plus a 1-based heading line → document path map, with `PathAtLine`), and the new `ValidateSpecDocument(model, document, schema, rootType)` renders, runs the DocSpecs validator and sets each finding's `Path`; pinned by the new `docspecs_path_cases.json`.
- Typed text (SOM §9, `valueTypeMismatch`): an `int`/`double`/`num`/`bool` field holding non-empty text its parser cannot read is refused by `SetValue`/`SetFormValue` (error), makes `Value`/`FormValue` return an error instead of `nil`, and is reported by `ValidateDocument` as the new `SpecValidationCodeValueTypeMismatch` (scalar leaves; form fields without enum values or `CountOf`); new helpers `SomScalarBase`, `SomTypedTextReadable`. Pinned by the new `validation_cases.json` case and the `setRawFormField`/`valueUnreadable`/`formValueUnreadable` editor ops.
- YAML empty document (SOM §12.3 rule 4): the encoder writes an empty document as `document:` then `  <root key>: {}` instead of `document: {}`, keeping the root key that records which document root the file is; decode still accepts `document: {}`. Pinned by the new `yaml_review_cases.json` roundTrip case.
- Query section ids (llm_and_d4rt_tools.md §6): a list item is known by its own effective id — stored, else the list's `@SectionIdPattern` with its 1-based position, else `<member>-<position>` — in the `sectionIdExact`/`sectionIdPrefix` filters and the projection's `SectionID`, so a list's own id matches only the list; pinned by four new `query_cases.json` cases and `projection_cases.json`.
- YAML review pass presence (SOM §12.1): `DecodeYaml` returns `Review == nil` when the file has no `review:` key and a non-nil (possibly empty) map when it has one, so a file without a review pass round-trips without gaining `review: {}`; pinned by the new `yaml_review_cases.json` case.
- Markdown import (SOM §11.6): prose in a section whose owner has no content slot but has form slots (a class-level `@Form` on `content`) is that form's preamble — `finalizeBodySlots` binds it to `<owner>/content` (else the first form slot) and strips the escape space of a label-shaped preamble line, instead of storing it on the owner's path (kindMismatch); pinned by the new last `markdown_import_cases.json` case.
- CodeSpecs catalogue: `CodeSpecsAreaCatalogFromJSON` rejects a malformed slice, step or area row with an error naming the row (`title "Shared types" is missing a numeric "number"`) instead of reading 0 or ""; pinned by the new `catalogErrorCases` table of `codespecs_extract_cases.json`.
- Review-pass scalars keep their YAML 1.2 type (SOM §12.5): `YamlParseTyped` reads `0o`/`0x` integers, `.inf`/`.nan` and an empty value (null), keeps ints and floats distinct (an integer beyond 64 bits reads as a float), and `WriteReviewPass` writes floats so they read back as floats (`3.0`, `1e+300`, `-.inf`). Pinned by two new `yaml_review_cases.json` cases.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item (vsctsa44): `SpecDocument.MoveListItem(model, itemPath,
  toIndex, toList)` moves an item to position `toIndex` of its list (`toList`
  `""`), or of `toList`, another list of the same element class, and returns a
  `*SpecListItemMove` (`Path`, `Renamed` old → new item paths, `PinnedIDs` new
  path → id). A path is a position, the section id is the identity: every
  affected list is renumbered to `<list>-1..n` (seq = n, an emptied list is
  dropped), every store key at or under an old item path is re-keyed, and an
  anonymous item whose positional id changes has its old id stored. Refusals
  change nothing: `*SpecListMoveArgumentError` (not a live list item, not a
  model list, another element class, a stored id not fitting the destination
  `@SectionIdPattern`), `*SpecSectionIDCollision` (the stored id is taken in
  the destination), `*SpecListMoveRangeError` (`toIndex` out of range).
  `RekeyReview(review, renamed)` returns the `review:` pass re-keyed the same
  way; since a Go map has no order, it tries the old paths in ascending order.
  The `list_move_cases.json` corpus table pins both.
- Stated counts (vsctsa43): `FormFieldSpec.CountOf` reads the meta's
  `formFields[].countOf` (absent → empty slice), and `ValidateDocument` gains a
  sixth, instance-tier step after the reference check. A form field with
  `CountOf` must hold a whole number equal to the entries the document holds:
  a target `X` counts every list item whose element class carries
  `@SectionId(X)`, `X.f=v` only those whose own form holds `v` in `f`, summed
  over the targets. A blank value, or a target outside the document's registry
  scope, is skipped; anything else that does not match is reported under the
  new `SpecValidationCodeCountMismatch` (`countMismatch`). The corpus cases
  `countMatches` and `countMismatch` pin it.
- Document assembly (`spec_document_assembly.go`) merges fragments written in
  parallel into one document. `AssembleSpecDocuments(fragments)` (also
  `SpecDocumentAssemble`, the Go spelling of `SpecDocument.assemble`) takes an
  ordered `[]SpecAssemblyFragment` (`Name`, `Document`) and merges the
  plain-data stores of `ToJSON()`: content, headlines and code-spec locations
  one value per path, forms field by field, lists whole. The merge is
  refusing — a place two fragments both write is a `SpecAssemblyOverlap`
  (`Store`, `Path`, `Field`, `Fragments`, `Message()`) and the
  `SpecDocumentAssembly` then carries no `Document` (`Ok()` is false).
  Overlaps are reported in store order, then path order (UTF-16 code-unit
  order, as the reference sorts). The `assembly_cases.json` corpus table pins
  it.
- CodeSpecs gate (`spec_codespecs_gate.go`) runs Stage A of
  `codespecs_prompt.md` §4 as one `NewCodeSpecsGate(model, document, catalog,
  schema, rootType).Run()`, returning a `CodeSpecsGateReport` with one
  `CodeSpecsGateCheckResult` per check A1–A5 (`Ran`, `NotRunReason`,
  `Findings`, `Passed()`), the extraction run's `Extracts` when A3 passed, and
  `Result(check)` lookup. A1 validates the rendered Markdown against the
  DocSpecs schema (nil schema: not run), A2 runs `ValidateDocument`, A3
  reports every unrouted section of the non-strict walk (or the
  root-resolution error), A4 holds each required marker argument of a used
  area to a populated source (with the `When` filter and `ResolvesTo` check),
  A5 checks every carrier still exists in the model. A check that cannot run
  is reported not run, with its reason, and fails the gate. `Run` returns an
  error only where the reference throws (A1's Markdown render failing).
  `CodeSpecsAreaCatalogFromJSON` reads the optional `gate` key into
  `RequiredArguments` (`CodeSpecsRequiredArgument`), `Carriers`
  (`CodeSpecsCarrier`) and `HasGateTables`; field references are
  `CodeSpecsFieldRef`, and a gate row missing a required key is an error. The
  `codespecs_gate_cases.json` corpus table pins it.
- CodeSpecs records (`spec_codespecs_records.go`) read back what a Phase-4 run
  wrote. `CodeSpecsExtractFromYaml(text, source)` (also
  `ParseCodeSpecsExtractYaml`) is the inverse of `ToYaml` — byte-stable for
  every extract the extractor writes; it requires `formatVersion` 3 and a
  non-empty `area.code`, reads every other absent key as empty, refuses a
  present key of the wrong type and a `document.entryCount` that disagrees
  with the entries. `CodeSpecsGateRecord` reads, checks and writes the Stage-B
  gate record `gate.verdicts.yaml` (`CodeSpecsGateRecordFromYaml`,
  `NewCodeSpecsGateRecord`, `ToYaml`, `VerdictFor`, `CheckAgainst(catalog)`,
  `WithVerdict`), with the `CodeSpecsGate*` verdict words and
  `CodeSpecsGateEntry`. `CodeSpecsExtractSetFromFiles([]CodeSpecsFile)` — an
  ordered slice, since Go maps are unordered — and
  `CodeSpecsExtractSetFromDirectory(path)` read a tree of extracts scoped by
  its gate record (`Extracts`, `Sources`, `Excluded`, `Gate`, `ByArea`,
  `EntriesForSection`, `EntriesAtPath`). Errors are `*CodeSpecsRecordError`.
  A gate entry's absent resolution/note is `""`, so `note: ""` reads as no
  note. The `codespecs_record_cases.json` corpus table pins it.
- CodeSpecs catalogue: `CodeSpecsAreaCatalog.Steps` carries the
  `codespecs_mapping.md` §4.4.6 authoring-step table as `CodeSpecsStep` rows
  (`Number`, `Title`, `Slice`, `PlacedBy`, `AreaCodes`); a catalogue without a
  `steps` key loads with none. `StepNumbered(n)` finds one step and
  `StepsFor(area)` returns the steps of `area.AuthoringSteps` in that order,
  skipping numbers the catalogue does not carry. The `stepCases` table of
  `codespecs_extract_cases.json` pins it.
- DocSpecs section-body replacement: `DocSpecsReplaceSectionBody(text,
  sectionID, body)` returns the document with one section's own body (the lines
  between its heading and the next heading of any level) replaced, every other
  byte kept; the region is found by the fence-aware `ParseDocSpecsDocument`.
  The body is trimmed of leading/trailing blank lines and framed by one blank
  line on each side (an empty body leaves a single blank line). It errors when
  the id names no section or several (listing their lines), and when the body
  holds a heading outside a fence or leaves a fence open.
  `DocSpecsDocument.AllSections()` lists every section depth-first. Pinned by
  the shared corpus table `docspecs_replace_cases.json`.
- YAML review pass: `EncodeYamlWithReview(document, tree, modelVersion,
  review)` writes the opaque `review:` pass back after the document pass
  (`EncodeYaml` is unchanged and writes none), through the exported
  `WriteReviewPass`: entries sorted by path with JSON-quoted keys, fields sorted
  by name, booleans/numbers/identifier-like strings plain, other strings as
  self-verified block scalars, lists as JSON flow, an empty map as
  `review: {}`. `DecodeYaml` now reads the review pass with the new
  `YamlParseTyped` (YAML 1.2 core-schema booleans, null and numbers), so a
  decode followed by an encode is byte-identical. `StaleReviewPaths(model,
  document, review)` lists the review paths that no longer resolve — unknown to
  the model, or running through a removed list item. Pinned by the shared
  corpus table `yaml_review_cases.json`.
- Markdown load/apply: `SpecDocumentFromMarkdown(text, model)` loads a DocSpecs
  Markdown document into a fresh document in one call and returns a
  `SpecMarkdownImport` (`Document`, `Result`, `Rejections()`); rejected blocks
  are reported, not loaded. `SpecDocument.ApplyMarkdownResult(result,
  allowRejections)` applies a parse result as a full overwrite of the roots it
  covers (SOM §11.7), keeping every other root, and refuses a result with
  rejections — changing nothing — unless they are allowed. Both are pinned by
  the shared corpus table `markdown_apply_cases.json`.
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

- Generic TomSpecs object-model runtime for Go: section-path grammar, meta-data
  model loader, reflection/resolution, sparse document, validator, and the
  YAML/Markdown codecs.
- Zero external dependencies (Go standard library only); validated against the
  shared language-agnostic conformance corpus.
- Published under the domain-qualified module path
  `github.com/al-the-bear/tom_ai_build/tom_som_go_runtime`; the version is a VCS
  tag (`vMAJOR.MINOR.PATCH`) mirrored in the in-source `Version` constant
  (`doc.go`).
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its version is realigned by `tom_specs_clitool/bin/generate_som.dart`.
