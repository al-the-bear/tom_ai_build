# Changelog

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec.code`, `SomFormFieldMeta.code`) is written as an inline code
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
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `SpecModel.isGenerationInput` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings name their document path: `SpecDocumentMarkdown.exportRootWithMap` / `SpecDocument.toMarkdownWithMap` return a `SpecMarkdownRendition` (the `toMarkdown` text plus a 1-based heading line → document path map, `pathAtLine`), and the new `validateSpecDocument(model, document, schema, rootType?)` renders, validates and sets each `DocSpecsViolation.path` from that map (SOM §14).
- Typed fields (`int`/`double`/`num`/`bool`, nullable too): new `somScalarBase` / `somTypedTextReadable`; `setValue`/`setFormValue` refuse a string the type cannot read, `value`/`formValue` throw an `Error` on such stored text instead of answering null, and `validateDocument` reports it as the new code `valueTypeMismatch` (scalar leaves and non-enum, non-`countOf` form fields; SOM §9).
- YAML encode: a document with no values writes `document:` + `  <root key>: {}` instead of `document: {}`, keeping the root key that records which document root the file is (SOM §12.3 rule 4); decode still accepts `document: {}`.
- Query engine: a list item's section id (the `sectionIdExact` / `sectionIdPrefix` filters and the projection's `sectionId`) is the item's own effective id — stored id, else the list's `@SectionIdPattern` with its 1-based position, else `<list>-<position>` — so a list's own id matches only the list (llm_and_d4rt_tools.md §6).
- Markdown import: a section whose owner has only form slots (e.g. a class-level `@Form` on `content`) binds its prose as that form's preamble — the `content` form slot, else the first — with label-shaped lines unescaped, instead of storing it on the owner's path (SOM §11.6).
- `CodeSpecsAreaCatalog.fromJson` rejects a slice, step or area row missing a numeric `number`/`slice` or a non-empty `code`/`part` with an error naming the row, instead of reading `NaN`.
- The `review:` pass types its plain scalars by the YAML 1.2 core schema and writes them back canonically (SOM §12.5): integers stay exact to 64 bits (`bigint` beyond `Number.isSafeInteger`), whole floats decode as the new exported `YamlFloat` and write as `3.0`, non-finite floats as `.inf`/`-.inf`/`.nan` (new export `reviewScalar`).
- YAML decode: `SpecYamlContents.review` is `null` when the file has no `review:` key and a map (empty for `review: {}` or a bare `review:`) when it has one, so decode → encode no longer adds `review: {}` to a file without a review pass (SOM §12.1).

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
  worded as the Dart reference. Constants `K_CODE_SPECS_GATE_RECORD_FILE`,
  `K_CODE_SPECS_GATE_RECORD_FORMAT`, `K_CODE_SPECS_EXTRACT_FILE_SUFFIX`,
  `K_CODE_SPECS_GATE_DESCOPED`.
  Conformance: `codespecs_record_cases.json` (`codespecs.record.*`).
- CodeSpecs: the area catalogue carries the `codespecs_mapping.md` §4.4.6
  authoring-step table. New `CodeSpecsStep` (`number`, `title`, `slice`,
  `placedBy`, `areaCodes`), `CodeSpecsAreaCatalog.steps` (read from the
  catalogue's optional `steps` key; absent means empty), and
  `CodeSpecsAreaCatalog.stepNumbered(number)` / `stepsFor(area)` — the steps
  that author an area, in authoring order, skipping numbers the catalogue does
  not carry. Conformance: `codespecs_extract_cases.json` `stepCases`
  (`codespecs.stepCases`), including a catalogue without `steps`.
- `DocSpecsDocument.replaceSectionBody(text, sectionId, body)` returns `text`
  with the own body of the section `sectionId` replaced — the lines after its
  heading up to the next heading of any level — and every other byte kept.
  The new region is a blank line, `body` trimmed of leading and trailing blank
  lines, and a blank line. It throws when the id names no section or several,
  and when `body` holds a heading outside a fence or leaves a fence open.
  `DocSpecsDocument.allSections` lists every section depth-first. Pinned by the
  corpus table `docspecs_replace_cases.json`.
- YAML codec: `encode(document, tree, modelVersion, review)` takes the
  optional `review:` pass and writes it back after the document pass
  (`writeReviewPass`): entries sorted by path with JSON-quoted keys, each
  entry's fields sorted by name; booleans, numbers, null and identifier-like
  strings plain, lists as JSON flow, any other string as a self-verified block
  scalar, an empty map as `review: {}`. So a load followed by a save keeps a
  reviewed document's review state, byte-identical to the Dart runtime.
  `decode` reads the review pass with YAML 1.2 core typing (`yaml.parse(text,
  true)`), so its booleans and numbers keep their types.
  `staleReviewPaths(model, document, review)` lists the review paths that no
  longer resolve — unknown to the model, or running through a list item the
  document no longer holds. Pinned by the corpus table
  `yaml_review_cases.json`.
- `SpecDocument.applyMarkdownResult(result, allowRejections)` applies a parsed
  Markdown import as a full overwrite of the roots it covers (SOM §11.7): every
  value under each root prefix is removed, then the parsed content, forms,
  lists, headlines and codeSpecs are written; other roots are kept. A result
  with rejections is refused with an `Error`, the document unchanged, unless
  `allowRejections` is true. `SpecDocument.fromMarkdown(text, model)` parses
  and applies into a fresh document in one call and returns a
  `SpecMarkdownImport` (`document`, `result`, `rejections`). Both are pinned by
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

- Generic TomSpecs object-model runtime for TypeScript (Node.js): section-path
  grammar, meta-data model loader, reflection/resolution, sparse document,
  validator, and the YAML/Markdown codecs.
- Zero external runtime dependencies (Node built-ins only; `typescript` and
  `@types/node` are dev-only); validated against the shared language-agnostic
  conformance corpus.
- Ships compiled `dist/` (CommonJS `*.js` plus `*.d.ts` declarations); `prepack`
  rebuilds it from source.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its version is realigned by `tom_specs_clitool/bin/generate_som.dart`.
