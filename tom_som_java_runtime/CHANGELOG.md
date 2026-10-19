# Changelog

## Unreleased

- Exact markdown round trip (SOM §11.3, §11.6, §11.7, §12.4). A body region
  whose units the parser would otherwise bind elsewhere carries slot markers
  (`<!-- slot: <rel> -->`, `.` for the owner): text written after anything
  else or not aimed at the region's default slot, a form preamble that is not
  the default target, and a form sharing a field label with another form of
  the region. The parser sends the text after a marker to the named slot (a
  marker naming no slot stays text) and joins repeated parts with a blank
  line. In a region with any form, every label-shaped text line is escaped by
  one leading space and unescaped on import. A headline's line breaks are
  written as `<br>` in the heading and read back as `\n`. Blank-line runs
  inside a value are kept: neither the markdown emitter nor the YAML encoder
  collapses them any more (`SpecDocumentYaml.dedupEmptyLines` stays as a
  helper). Bodies that parsed correctly without markers render as before.
  Pinned by the regenerated corpus (the new `Mixed` class).
- `SpecDocument.hasValuesUnder` answers from a lazily built prefix index
  instead of scanning every stored key per call; rendering a large document is
  no longer quadratic. Every mutator drops the index; results are unchanged.

## 1.6.1

- Code fields (SOM §11.4 rule 8): a form field whose meta carries `code: true`
  (`FormFieldSpec.code`, `SomFormFieldMeta.code`, new overloaded constructors
  carrying the flag; the existing ones default it to `false`) is written as an
  inline code span when its value is on one line — delimited by one backtick
  more than the longest run inside it, padded with a space when the value
  begins or ends with a backtick or a space — and the markdown import unwraps
  the span again. A value written without a span is kept as written; a
  multi-line value keeps the plain rendering. Pinned by the regenerated corpus
  (`expected.md`, the new `Demo.details.pattern` and `Card.content.selector`
  fields, and the new `markdown_import_cases.json` cases).

## 1.5.0

- Released in lockstep with `tom_specs_model` 1.5.0. Two changes break a caller: the YAML decode's `review` is null when the file has no `review:` key (check for null where it was read as a map), and the model renames two section ids (see `tom_specs_model` 1.5.0).

- The CodeSpecs gate record carries Stage B's gap lines: an `insufficient` entry may hold `gaps:`, each a `CodeSpecsGateGap` with `sectionId`, `required` and `carrier` (`<section-id>.<field>`) and its `codespecs_prompt.md` §6.3 `line`. The reader refuses gaps on any other verdict, an unknown key in a gap, an empty field and a malformed carrier; the writer puts `gaps:` after `resolution`. Additive, so `formatVersion` stays 1. Pinned by new `codespecs_record_cases.json` cases.
- Markdown import stores a pattern-list item's heading id even when it equals the positional pattern default (`UCE-USER-1`), so the id survives a later move or insert and a document's `.md` imports to the same memory as its `.yaml` (SOM §11.5). A pattern-less list's `<member>-<n>` id stays positional. Pinned by the regenerated corpus (`state.json`, `expected.docspecs.yaml`) and each v0 package's Meridian import test.
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). New `SpecModel.isGenerationInput` answers that from the root class's `@CodeSpecsProjection` marker, never from a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs findings name their document path: `SpecDocumentMarkdown.exportRootWithMap` / `SpecDocument.toMarkdownWithMap` return a `SpecMarkdownRendition` (the `toMarkdown` text plus a 1-based heading line → document path map, `pathAtLine`), and the new `SpecSchemaValidation.validateSpecDocument(model, document, schema, rootType)` renders, validates and sets each `DocSpecsViolation.path` from that map (SOM §14).
- Typed fields (`int`/`double`/`num`/`bool`, nullable too): new `somScalarBase` / `somTypedTextReadable`; `setValue`/`setFormValue` refuse a string the type cannot read, `value`/`formValue` throw an `IllegalStateException` on such stored text instead of answering null, and `validateDocument` reports it as the new code `valueTypeMismatch` (scalar leaves and non-enum, non-`countOf` form fields; SOM §9).
- YAML encode: a document with no values writes `document:` + `  <root key>: {}` instead of `document: {}`, keeping the root key that records which document root the file is (SOM §12.3 rule 4); decode still accepts `document: {}`.
- Query engine: a list item's section id (the `sectionIdExact` / `sectionIdPrefix` filters and the projection's `sectionId`) is the item's own effective id — stored id, else the list's `@SectionIdPattern` with its 1-based position, else `<list>-<position>` — so a list's own id matches only the list (llm_and_d4rt_tools.md §6).
- Markdown import: a section whose owner has only form slots (e.g. a class-level `@Form` on `content`) binds its prose as that form's preamble — the `content` form slot, else the first — with label-shaped lines unescaped, instead of storing it on the owner's path (SOM §11.6).
- `CodeSpecsAreaCatalog.fromJson` rejects a slice, step or area row missing a numeric `number`/`slice` or a non-empty `code`/`part` with an `IllegalArgumentException` naming the row (slices no longer read 0); the row helpers are shared by every catalogue table.
- The `review:` pass types its plain scalars by the YAML 1.2 core schema and writes them back canonically (SOM §12.5): ints up to 64 bits (`Long` beyond `int`, a `Double` beyond 64 bits — previously a `NumberFormatException`), hex/octal ints, `.inf`/`-.inf`/`.nan`, and floats in the shortest round-tripping digits laid out like JavaScript (`3.0`, `1e+300`) via the new `SpecDocumentYaml.reviewScalar` / `formatFloat`.
- YAML decode: `SpecYamlContents.review` is `null` when the file has no `review:` key and a map (empty for `review: {}` or a bare `review:`) when it has one, so decode → encode no longer adds `review: {}` to a file without a review pass (SOM §12.1).

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item: `SpecDocument.moveListItem(model, itemPath, toIndex[,
  toList])` reorders a list item, or moves it into another list of the same
  element class; the section id is the identity and the path the position.
  Every affected list is renumbered to `<list>-1..n`, every value under each
  item (content, forms, headlines, codeSpecs, nested lists, stored ids) is
  re-keyed with it, and an anonymous item whose positional id changes has its
  old id stored. The result is a `SpecListItemMove` (`path`, `renamed`,
  `pinnedIds`). Refusals change nothing: not a live list item, a `toList` that
  is no model list, a different element class, or a stored id that does not
  fit the destination `@SectionIdPattern` throw `IllegalArgumentException`; a
  stored id already used in the destination throws `SpecSectionIdCollision`;
  a `toIndex` out of range throws `IndexOutOfBoundsException`.
  `SpecDocumentYaml.rekeyReview(review, renamed)` re-keys a `review:` pass with
  the move's `renamed` map. Verified against `list_move_cases.json`.

- Stated counts: `FormFieldSpec.countOf` (read from the meta's
  `formFields[].countOf`, empty when absent) names the entries a form field's
  value counts — `X` (every list item whose element class carries
  `@SectionId(X)`) or `X.f=v` (those entries one of whose own forms holds `v`
  in form field `f`), summed over the targets. `validateDocument` reports the
  new `SpecValidationCode.COUNT_MISMATCH` (`countMismatch`) after the reference
  check when a non-empty stated value is not a whole number or not the number
  of entries the document holds; a target outside the document's registry
  scope skips the field. Verified by the `countMatches` / `countMismatch`
  validation cases.

- Assembling one document from fragments written in parallel:
  `SpecDocument.assemble(fragments)` (also `SpecDocumentAssembly.assemble`)
  takes an ordered `List` of (name, document) `Map.Entry` pairs — or a
  name → document `Map`, in its iteration order — and merges the fragments'
  `toJson` stores. The merge is refusing: a content path, headline or
  code-spec location two fragments both write, a form field two fragments both
  fill (two fragments may fill different fields of one form), or a list two
  fragments both hold is a `SpecAssemblyOverlap` (`store`, `path`, `field`,
  `fragments`, `message()`), and a `SpecDocumentAssembly` with any overlap has
  a null `document` (`ok()` is false). Overlaps are reported in store order
  content, forms, lists, headlines, codeSpecs, then by path. A fragment name
  given twice throws `IllegalArgumentException`. Verified against
  `assembly_cases.json`.
- CodeSpecs: the Stage-A gate (`codespecs_prompt.md` §4, A1–A5) as one
  `CodeSpecsGate(model, document, catalog, schema[, rootType]).run()`
  returning a `CodeSpecsGateReport` (`results` A1..A5 in order, `extracts`
  when A3 passed, `passed()`, `findings()`, `get(check)`). Every check runs;
  one that cannot run is reported not run, with its reason, and never passes.
  A1 renders the document with `toMarkdown` and validates it with
  `DocSpecsValidator`; A2 is `validateDocument`; A3 collects every unrouted
  class from the non-strict `routings()` walk (or the root-resolution error)
  and only then runs `extractAll()`; A4 checks each required marker argument's
  source (with `when` and `resolvesTo`); A5 checks each carrier against the
  model. New `CodeSpecsGateCheck` (`label()` = `A1`..`A5`),
  `CodeSpecsGateCheckResult`, `CodeSpecsGateFinding`. The area catalogue reads
  the optional `gate` block: new `CodeSpecsFieldRef`,
  `CodeSpecsRequiredArgument`, `CodeSpecsCarrier`, and
  `CodeSpecsAreaCatalog.requiredArguments` / `carriers` / `hasGateTables`; a
  gate row missing a required cell throws an `IllegalArgumentException` naming
  the row. Pinned by the corpus table `codespecs_gate_cases.json`.
- CodeSpecs: reading a Phase-4 run back. `CodeSpecsExtract.fromYaml(text[,
  source])` is the inverse of `toYaml` (byte-identical round trip for every
  extract the extractor writes): it requires `formatVersion` 3 and a non-empty
  `area.code`, reads every other absent key as empty, strips a leading
  `CodeSpecPart.` from `area.part`, and refuses a wrong-typed key or a
  `document.entryCount` that disagrees with the entries. New
  `CodeSpecsGateRecord` (`gate.verdicts.yaml`, format 1): the constructor
  checks the shape (CE-* areas named once, `resolution: descoped` only on an
  insufficient area), `fromYaml` also refuses unknown keys and other format
  versions, `toYaml` is byte-stable, plus `verdictFor`, `checkAgainst(catalog)`
  and `withVerdict`. New `CodeSpecsGateVerdict`, `CodeSpecsGateEntry`,
  `CodeSpecsExcludedArea`, and `CodeSpecsExtractSet.fromFiles` /
  `fromDirectory`, which scope an ordered set of extracts by its gate record
  (in scope iff `sufficient`; the record must be total; `not applicable` with
  routed entries and an undescoped `insufficient` are errors) and expose
  `byArea`, `entriesForSection` and `entriesAtPath`. Every reader throws the
  new unchecked `CodeSpecsRecordError`. Pinned by the corpus table
  `codespecs_record_cases.json`.
- CodeSpecs: the area catalogue carries the `codespecs_mapping.md` §4.4.6
  authoring-step table. New `CodeSpecsStep` (`number`, `title`, `slice`,
  `placedBy`, `areaCodes`; `number` and `slice` are required and throw an
  `IllegalArgumentException` naming the row) and `CodeSpecsAreaCatalog.steps`,
  read from the optional `steps` key — a catalogue without it loads with no
  steps. `stepNumbered(n)` returns a step or `null`; `stepsFor(area)` returns
  the steps for `area.authoringSteps` in that order, skipping numbers the
  catalogue does not carry. Pinned by `stepCases` in
  `codespecs_extract_cases.json`.
- DocSpecs: `DocSpecsDocument.replaceSectionBody(text, sectionId, body)`
  returns the text with one section's own body (up to its first child heading)
  replaced and every other byte kept; the region is found by the fence-aware
  `parse`, and the new region is the body without leading/trailing blank lines
  between two blank lines (one blank line for an empty body). Throws
  `IllegalArgumentException` for an id naming no section or several, a body
  heading outside a fence, or a body that leaves a fence open. New
  `allSections()` lists every section depth-first. Pinned by the corpus table
  `docspecs_replace_cases.json`.
- YAML codec: the `review:` pass is written back. `SpecDocumentYaml.encode`
  takes an optional `review` map (written after the document pass by the new
  public `writeReviewPass`: entries sorted by path, fields sorted by name,
  identifier-like strings, booleans and numbers plain, other strings as
  self-verified block scalars, an empty map as `review: {}`), so decode
  followed by encode keeps a reviewed document byte for byte. The new static
  `staleReviewPaths(model, document, review)` lists the review paths that no
  longer resolve — unknown paths and paths through a removed list item.
  `decode` reads the review pass with typed scalars (`Yaml.parse(text, true)`:
  booleans, nulls, floats, JSON flow lists); the document pass stays untyped.
  Pinned by the corpus table `yaml_review_cases.json`.
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
- Markdown import: `SpecDocument.applyMarkdownResult(result[, allowRejections])`
  applies a parsed import as a full overwrite of the roots it covers (SOM
  §11.7) — every value under each root prefix is removed, then the parsed
  content, forms, lists, headlines and codeSpecs are written; other roots are
  kept. A result with rejections is refused with an `IllegalStateException`,
  leaving the document unchanged, unless `allowRejections` is true. The static
  `SpecDocument.fromMarkdown(text, model)` parses and applies into a fresh
  document in one call and returns a `SpecMarkdownImport` (`document`,
  `result`, `rejections()`). Pinned by the `markdown_apply_cases.json` corpus.

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- First packaged release of the generic Java SOM runtime.
- Version tracks the TomSpecs model version; the typed `tom_som_java_v0` facade
  pins the same version.
