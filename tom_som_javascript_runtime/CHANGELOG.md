# Changelog

## Unreleased

- Writing changes as inline marks (SOM §11.9.3): `markChangeText(old, new)`
  diffs by line, then by word, merging changes at most two words apart, so
  accepting all marks gives `new` and rejecting all gives `old`. Words are
  never split and code is never marked. Returns a `SpecMarkedChange`
  (`text`, `exact`). `SpecReviewAnnotations.setMarked` (a second edit updates
  its mark) and `markAgainst` (against an earlier version) apply it to a
  value. Conformance: `change_mark_cases.json`.

- Reviewing inline marks (SOM §11.9.3): `SpecReviewAnnotations.revision`,
  `listMarks`, `decideMarks` (accept / reject / leave in one write, refused on
  a stale revision or an unknown id), `acceptAllMarks` / `rejectAllMarks`
  under a path, `removeAllAnnotations`, and `applyInlineMarksText`, with
  `SpecMarkDecision`, `SpecMarkEntry`, `SpecMarkOutcome`, `SpecMarkIssue` and
  `SpecMarkReport`. Each operation returns a `SpecMarkReport` for the
  decision log. Accepting and rejecting follow whitespace rules — words never
  join, no double space or space before punctuation, a whole-line mark leaves
  no blank line — which `applyMark` now follows too. Malformed marks are left
  as written and reported. Conformance: `inline_mark_cases.json`.

- Review annotations (SOM §11.9): `SpecReviewAnnotations` (`spec_review_annotations.js`)
  lists and edits comment blocks, question blocks and CriticMarkup inline
  marks in content and form-field values — `list`, `counts`,
  `nextCommentId`, `assignCommentIds`, `insertComment`, `insertQuestion`,
  `insertQuestionAfterComment`, `setAnswer`, `editComment`, `resolve`,
  `applyMark`, `stripped`, `validate` — with `SpecReviewAnnotation`,
  `SpecReviewAnnotationKind`, `SpecMarkKind`, `SpecQuestionDraft`,
  `SpecReviewAnnotationCounts`, `SpecReviewAnnotationError`,
  `stripAnnotationsText`, `formatCommentBlock` and `formatQuestionBlock`.
  Positions are 0-based line numbers within a value; every edit is
  byte-stable outside the annotation it touches. `validateDocument` reports
  three new codes, listed after `multipleReferences`, as its last group
  (after the derived-value group, ordered by path):
  `SpecValidationCode.ANNOTATION_MISPLACED` (`annotationMisplaced`),
  `ANNOTATION_MALFORMED` (`annotationMalformed`) and
  `DUPLICATE_ANNOTATION_ID` (`duplicateAnnotationId`). Guide:
  `doc/review_annotations.md`. Conformance: `annotation_cases.json` and the
  `annotationsWellFormed` / `annotationMisplaced` / `annotationMalformed` /
  `duplicateAnnotationId` validation cases.
- Single references (uamtc17): `FormFieldSpec.multiple` (meta
  `formFields[].multiple`, absent → `false`), and `validateDocument` reports
  `SpecValidationCode.MULTIPLE_REFERENCES` (`multipleReferences`, listed after
  `missingRequiredField`) in the reference phase: a reference field that is
  not `multiple` and holds more than one non-empty comma-separated id is one
  error at its form path, checked before the registry-scope test; every id is
  still resolved, so dangling ones also report `danglingReference`.
  Conformance: the `multipleReferencesInSingleField` /
  `everyDanglingIdOfAList` validation cases.
- Required form fields (uamtc16): `validateDocument` reports
  `SpecValidationCode.MISSING_REQUIRED_FIELD` (`missingRequiredField`, listed
  after `derivedValueMismatch`) in the form-section phase: for every form path
  the document holds that resolves to a form, each declared field whose
  `required` flag (meta `formFields[].required`, default false) is set and
  whose value is absent or blank after trimming is one error at that form
  path, in declared order — class-level `content` forms and member forms, in
  list items or not. Conformance: the `requiredFieldsFilled` /
  `missingRequiredFieldInListItemForms` / `missingRequiredFieldInMemberForm`
  validation cases; the corpus model now has 15 classes (`RequiredEntry`).
- Derived values (uamtc10): `FormFieldSpec.productOf` (meta
  `formFields[].productOf`, absent → empty) and `FormFieldSpec.rankOf` (meta
  `formFields[].rankOf`, absent → `null`), and `validateDocument` reports
  `SpecValidationCode.DERIVED_VALUE_MISMATCH` (`derivedValueMismatch`, run
  right after the count check). A `productOf` field must state a number equal,
  to the precision it is written in, to the product of its operands — a field
  of the same form or `FORMSID.field` of a sibling form; an enum operand
  contributes its 1-based position; an empty or unreadable operand makes the
  product undecidable. A `rankOf` field must rank the instances of its form
  with a filled rank and score 1 to n, each once, highest score first.
  `countOf` targets written `./X` count only the entries beneath the section
  holding the form. Fields with `countOf`, `productOf` or `rankOf` are no
  longer reported as `valueTypeMismatch`. Conformance: the `derivedValuesMatch`
  / `productMismatch` / `rankOutOfOrder` / `rankDuplicate` /
  `scopedCountMismatch` validation cases.
- `SpecDocument.hasValuesUnder` answers from a lazily built prefix index (every
  stored key plus each prefix ending right before a `/` or a `-`), built on the
  first question and dropped by every mutator, instead of scanning every stored
  key per call. Results are unchanged; rendering, validating or querying a
  large document is no longer quadratic.
- Exact markdown round trip (SOM §11.2, §11.3, §11.6, §11.7, §12.4): a body
  region's text the parser would otherwise bind elsewhere is preceded by a slot
  marker `<!-- slot: <rel> -->` (text after anything already written, a form
  preamble that is not the region's default target, a form whose labels another
  form of the region shares), and the import routes the text after a marker to
  the named slot — the owner (`.`), a content slot or a form's preamble — and
  ends any open field; a marker naming no slot stays text. A headline's line
  breaks are written as `<br>` and read back as `\n`. Blank lines inside a
  value are kept as written by both the markdown emitter and the YAML encoder
  (no more collapse of 2+ blank lines; `dedupEmptyLines` stays as a helper). In
  a region with any form, every label-shaped text line carries one escape space
  on emit and loses it on import. Documents that need no marker render as
  before.

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec.code`, `SomFormFieldMeta.code`) is written as an inline code
  span when its value is on one line — delimited by one backtick more than the
  longest run inside it, padded with a space when the value begins or ends with
  a backtick or a space — and the markdown import unwraps the span again, on
  both the id-bearing form path and the transparent form-slot path. A value
  written without a span is kept as written; a multi-line value keeps the plain
  rendering. Pinned by the regenerated corpus (`expected.md`, the new
  `Demo.details.pattern` and `Card.content.selector` fields, and two new
  `markdown_import_cases.json` cases).

## 1.5.0

- Released in lockstep with `tom_specs_model` 1.5.0. Two changes break a caller: the YAML decode's `review` is null when the file has no `review:` key (check for null where it was read as a map), and the model renames two section ids (see `tom_specs_model` 1.5.0).

- The CodeSpecs gate record carries Stage B's gap lines: an `insufficient` entry may hold `gaps:`, each a `CodeSpecsGateGap` with `sectionId`, `required` and `carrier` (`<section-id>.<field>`) and its `codespecs_prompt.md` §6.3 `line`. The reader refuses gaps on any other verdict, an unknown key in a gap, an empty field and a malformed carrier; the writer puts `gaps:` after `resolution`. Additive, so `formatVersion` stays 1. Pinned by new `codespecs_record_cases.json` cases.
- Markdown import stores a pattern-list item's heading id even when it equals the positional pattern default (`UCE-USER-1`), so the id survives a later move or insert and a document's `.md` imports to the same memory as its `.yaml` (SOM §11.5). A pattern-less list's `<member>-<n>` id stays positional. Pinned by the regenerated corpus (`state.json`, `expected.docspecs.yaml`) and each v0 package's Meridian import test.
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `SpecModel#isGenerationInput` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings carry their document path (SOM §14): the Markdown renderer records the path behind every heading — `SpecDocumentMarkdown#exportRootWithMap` / `SpecDocument#toMarkdownWithMap` return a `SpecMarkdownRendition` (the markdown plus a 1-based heading line → path map, with `pathAtLine`) — and the new `validateSpecDocument(model, document, schema, rootType)` renders, validates and sets each violation's `path` from it. Pinned by the new `docspecs_path_cases.json`.
- A typed field (`int`, `double`, `num`, `bool`, nullable too) holding non-empty text its type cannot read is never read as unset (SOM §9): the new `somScalarBase` / `somTypedTextReadable` helpers decide it, the editor's typed setters refuse such a string with an `Error`, the typed `value` / `formValue` reads throw naming the path, text and type, and `validateDocument` reports it as the new `valueTypeMismatch` code (scalar leaves; form fields without enum values or `countOf`). Pinned by the new `validation_cases.json` case and the `setRawFormField` / `valueUnreadable` / `formValueUnreadable` ops of `editor_cases.json`.
- The YAML codec encodes a document with no values as `document:` followed by `  <root key>: {}` — the same root key a non-empty document writes — instead of `document: {}`, because the root key is the file's only record of which document root it is (SOM §12.3 rule 4); decode still accepts `document: {}`. Pinned by the new `yaml_review_cases.json` round-trip case.
- Query engine: a list item (`listItemComplex` / `listItemScalar`) is known by its own effective section id — its stored id, else the list's `@SectionIdPattern` with the 1-based position, else `<list field>-<position>` — for the `sectionIdExact` / `sectionIdPrefix` filters and the projection's `sectionId`; a list's own id now matches only the list (llm_and_d4rt_tools.md §6). Pinned by the new `query_cases.json` cases and `projection_cases.json`.
- The YAML codec's decode returns the `review:` pass as `null` when the file has no `review:` key (an explicit `review: {}` or a bare `review:` still gives an empty map), so decode-then-encode no longer adds `review: {}` to a file without a review pass (SOM §12.1). Pinned by the new `yaml_review_cases.json` round-trip case.
- Markdown import: prose in a section whose owner has only form slots (a class-level `@Form` on the `content` member) is that form's preamble (SOM §11.6) — it binds to the `content` form slot, else the first form slot, with a label-shaped line's escape space stripped — instead of the owner's own path, which the model rejected. Pinned by the last `markdown_import_cases.json` case.
- A malformed CodeSpecs area catalogue row (a slice or step without a numeric `number`/`slice`, a string where a number belongs, an area without a non-empty `code`/`part`) now throws an `Error` that names the row, as the Dart reference does, instead of loading `NaN` or `undefined`. Pinned by the six `catalogErrorCases` of `codespecs_extract_cases.json`.
- The catalogue's int lists (`cites`, `slices`, `authoringSteps`) reject a non-numeric entry naming the row, and the records reader's `_intList` checks integers again: two functions of that name had shadowed each other, so both read their lists unchecked.
- Review-pass scalars keep their YAML 1.2 type (SOM §12.5): the typed reader resolves `0o`/`0x` ints and `.inf`/`.nan`, returns an int beyond `Number.isSafeInteger` as a `BigInt` (beyond 64 bits as a float) and a whole float as the new `YamlFloat` wrapper, and the new `reviewScalar` writes floats so they read back as floats (`3.0`, `1e+300`, `-.inf`). Pinned by two new `yaml_review_cases.json` cases.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item: `SpecDocument.moveListItem(model, itemPath, toIndex,
  toList?)` moves an item to a 0-based position of its own list or of another
  list of the same element class, returning a `SpecListItemMove` (`path`,
  `renamed` old → new item paths, `pinnedIds` new path → id, both `Map`s). A
  path is a position, the section id is the identity: every affected list is
  renumbered to `<list>-1..n` (seq = n, an emptied list is dropped), every
  value under a moved item travels with it, and an anonymous item whose
  positional id changes stores its old id. Refused with nothing changed: not a
  live list item, `toList` not a model list, a list of another element class,
  a stored id that does not fit the destination `@SectionIdPattern` (`Error`),
  a stored id already used there (`SpecSectionIdCollision`), `toIndex` out of
  range (`RangeError`). `SpecDocumentYaml.rekeyReview(review, renamed)` (also
  the module function `rekeyReview`) re-keys a `review:` pass by the move's
  `renamed` map. Conformance: `list_move_cases.json` (`listMove[*]`).
- Stated counts: `FormFieldSpec.countOf` (read from the meta's
  `formFields[].countOf`, absent → empty), and `validateDocument` reports
  `SpecValidationCode.COUNT_MISMATCH` (`countMismatch`) when a `countOf` form
  field states a value that is not a whole number or not the number of entries
  the document holds (SOM §9, phase 6, run after the reference check). A target
  `X` counts every list item whose element class carries `@SectionId(X)`;
  `X.f=v` counts those whose own form holds `v` in field `f`; the targets sum.
  Empty values and targets outside the document's registry scope are skipped.
  Messages as in Dart. Conformance: the `countMatches` / `countMismatch`
  validation cases.
- Assembling one document from fragments written in parallel:
  `SpecDocument.assemble(fragments)` (also `assembleSpecDocuments`) takes the
  fragments as name → document, in order (a `Map` or an iterable of
  `[name, document]` pairs), and merges their `toJson()` stores. Content,
  headlines and codeSpecs hold one value per path; forms merge field by field,
  so two fragments may fill different fields of one form; a list comes whole
  from one fragment. The merge is refusing: every place two fragments both
  write is a `SpecAssemblyOverlap` (`store`, `path`, `field` for forms,
  `fragments` in given order, `message` as in Dart), reported in store order
  content, forms, lists, headlines, codeSpecs and then by path, and the
  `SpecDocumentAssembly` (`ok`, `document`, `overlaps`) then carries no
  document. A fragment name given twice is an error. Conformance:
  `assembly_cases.json` (`assembly[*]`).
- CodeSpecs: the Stage-A gate (`codespecs_prompt.md` §4, A1–A5) as one
  `CodeSpecsGate` (`{model, document, catalog, schema?, rootType?}`). `run()`
  returns a `CodeSpecsGateReport` — `results` A1..A5 in order, `extracts` when
  A3 passed, `passed`, `findings`, `resultFor(check)` — of
  `CodeSpecsGateCheckResult` (`check`, `ran`, `notRunReason`, `findings`,
  `passed`) and `CodeSpecsGateFinding` (`check`, `code`, `location`,
  `message`); `CodeSpecsGateCheck` `a1`..`a5` with `label` `A1`..`A5`. Every
  check runs; one that could not (no schema, A3 left no extracts, no gate
  tables) is reported not run, with the Dart reason, and the gate fails. A1
  validates the rendered Markdown against the DocSpecs schema, A2 is
  `validateDocument`, A3 reports every unrouted class (or the root-resolution
  error) before running `extractAll()`, A4 checks the required marker
  arguments over the extracts, A5 the carriers against the model. The area
  catalogue reads the optional `gate` key: `CodeSpecsFieldRef`,
  `CodeSpecsRequiredArgument`, `CodeSpecsCarrier`, and
  `CodeSpecsAreaCatalog.requiredArguments` / `carriers` / `hasGateTables`.
  Conformance: `codespecs_gate_cases.json` (`codespecs.gate[*]`).
- CodeSpecs: reading back what a Phase-4 run wrote.
  `CodeSpecsExtract.fromYaml(text, source)` (also `parseCodeSpecsExtractYaml`)
  is the inverse of `toYaml` — byte-identical for every extract the extractor
  writes. It requires the `extract.area` mapping, a non-empty `area.code` and
  `formatVersion` 3; every other absent key reads as empty, a present key of the
  wrong type is an error, and a `document.entryCount` that disagrees with the
  entries is refused. The Stage-B gate record `gate.verdicts.yaml`:
  `CodeSpecsGateVerdict` (`sufficient` / `notApplicable` / `insufficient`, with
  `word` and `parse(word)`), `CodeSpecsGateEntry` (`area`, `verdict`,
  `resolution`, `note`, `descoped`) and `CodeSpecsGateRecord` — checked on
  construction (`CE-*` areas named once, `resolution: descoped` only on an
  insufficient area), `fromYaml` (unknown keys and `formatVersion` other than 1
  refused), byte-stable `toYaml`, `verdictFor`, `checkAgainst(catalog)` and
  `withVerdict(entry)`. `CodeSpecsExtractSet.fromFiles(files)` reads an ordered
  `Map` or list of `[name, text]` pairs, scoped by the gate record among them
  (in scope iff `sufficient`; the record must be total, a `not applicable` area
  with routed entries and an undescoped `insufficient` area are errors), with
  the excluded areas kept visible as `CodeSpecsExcludedArea`; `fromDirectory`
  reads `*.extract.yaml` + `gate.verdicts.yaml` in name order. Lookups `byArea`,
  `entriesForSection`, `entriesAtPath`. Errors are `CodeSpecsRecordError`,
  worded as the Dart reference. Constants `K_CODESPECS_GATE_RECORD_FILE`,
  `K_CODESPECS_GATE_RECORD_FORMAT`, `K_CODESPECS_EXTRACT_FILE_SUFFIX`,
  `K_CODESPECS_GATE_DESCOPED`.
  Conformance: `codespecs_record_cases.json` (`codespecs.record.*`).
- CodeSpecs: `CodeSpecsStep` (`number`, `title`, `slice`, `placedBy`,
  `areaCodes`) — one row of the `codespecs_mapping.md` §4.4.6 authoring-step
  table — and `CodeSpecsAreaCatalog.steps`, read from the catalogue's optional
  `steps` key (absent means empty). `stepNumbered(number)` finds a step;
  `stepsFor(area)` returns the steps that author an area in authoring order,
  skipping numbers the catalogue does not carry. Conformance:
  `codespecs_extract_cases.json` `stepCases` (`codespecs.stepCases`),
  including a catalogue without `steps`.
- DocSpecs: `DocSpecsDocument.allSections` (every section, depth-first) and
  static `DocSpecsDocument.replaceSectionBody(text, sectionId, body)`, which
  replaces one section's own body (up to its first child heading) and keeps
  every other byte. It throws when the id names no section or several, and
  when the body holds a heading outside a fenced block or leaves a fence
  open. Conformance: `docspecs_replace_cases.json` (`docspecsReplace[…]`).
- YAML codec: `encode(document, tree, modelVersion, review)` writes the
  `review:` pass back when `review` is given (`review: {}` when empty), via the
  new `writeReviewPass` — entries sorted by path, fields sorted by name,
  identifier-like strings plain and other strings as self-verified block
  scalars — so a decode followed by an encode keeps a reviewed document
  byte-identical. `decode` returns the review pass with typed values (booleans,
  `null`, numbers, JSON flow lists; `yaml.parse(text, {typed: true})`). New
  `staleReviewPaths(model, document, review)` reports the sorted review paths
  that no longer resolve or run through a removed list item. Conformance:
  `yaml_review_cases.json` (`yamlReview[…]`).
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
- `SpecDocument.applyMarkdownResult(result, allowRejections = false)` applies a
  parsed Markdown import as a full overwrite of the roots it covers (SOM
  §11.7), keeping every other root; a result with rejections is refused with
  an `Error`, the document unchanged, unless `allowRejections` is true.
  `SpecDocument.fromMarkdown(text, model)` parses and applies into a fresh
  document in one call and returns a `SpecMarkdownImport`
  `{document, result, rejections}`. Pinned by `markdown_apply_cases.json`.

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- Generic TomSpecs object-model runtime for JavaScript (Node.js): section-path
  grammar, meta-data model loader, reflection/resolution, sparse document,
  validator, and the YAML/Markdown codecs.
- Zero external dependencies (Node built-ins only); validated against the shared
  language-agnostic conformance corpus.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its version is realigned by `tom_specs_clitool/bin/generate_som.dart`.
