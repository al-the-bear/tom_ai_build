# Changelog

## 1.6.13

- `missingRequiredField`: every form the document holds must fill its
  `required` fields — class-level forms and forms declared on a section
  member, in list items or not. The schema tier checked class-level forms of
  the rendition only. Conformance: `requiredFieldsFilled`,
  `missingRequiredFieldInListItemForms`, `missingRequiredFieldInMemberForm`
  (the corpus model gains `RequiredEntry`).

## 1.6.8

- Version aligned with the TomSpecs model (1.6.8); no library change.
- Conformance: `decisionStateOpenValues`, `decisionStateRejectsBool`,
  `enumValueIsCaseSensitive` — an enum field accepts its open states like any
  other value and rejects a bool or a token in the wrong case
  (`enumValueUnknown`). The corpus model's `RegistryEntry` form gains the
  `decided` field for them.

## 1.6.7

- Derived values are checked (`derivedValueMismatch`): a `productOf` field
  holds the product of its operands — numbers, or an enum's 1-based position,
  in the same form or a sibling form — to the precision it is written in, and
  a `rankOf` field ranks the instances of its form by their score, 1 to n,
  highest first.
- `countOf` targets written `./…` count only the entries beneath the section
  holding the form.
- `FormFieldSpec.productOf` / `FormFieldSpec.rankOf` read from the meta.

## 1.6.6

- Version aligned with the TomSpecs model (1.6.6); no library change.
- Conformance: `referenceAcrossRegistries` / `referenceAcrossRegistriesDangling`
  hold a reference field that names registries of two different classes — an
  id either declares resolves, one neither declares is a `danglingReference`.
  The corpus model's `RegistryLink` form gains the `crossRefs` field for it.

## 1.6.3

- The markdown codec round-trips exactly: `parse(toMarkdown(doc))` stages every
  content value, form field, list and headline at its own path (SOM §11.6,
  §11.7). For the tom_uam Solution Blueprint that was 86 form values, 703
  content values and 20 headlines read back elsewhere or merged.
  - **Slot markers.** Where the parser could not tell an owner's id-less body
    slots apart, the emitter writes `<!-- slot: <rel> -->` before the slot: text
    after anything else in the region, a form preamble that is not the default
    target, a form whose labels another form shares. The parser routes the
    following text to that slot and ends any open field. A body that reads back
    without markers gets none, so most documents render unchanged.
  - In a region with forms, label-shaped lines of a content slot carry the
    escape space too, and parse strips it.
  - A line break in a stored headline is written as `<br>` and read back.
  - Blank lines inside a value are kept, in the markdown and the YAML codec
    alike (SOM §11.3, §12.4); `SpecDocumentYaml.dedupEmptyLines` stays as a
    helper but the codec no longer applies it.
- Pinned by the regenerated corpus: a `Demo.mixed` (`MIX`) section with an
  id-less form and preamble, two id-less content slots, a second form sharing
  a label, a two-line headline and a value with two blank lines; and a
  `markdown_import_cases.json` case for a marker, an unknown marker and `<br>`.

## 1.6.2

- `SpecDocument.hasValuesUnder` answers from a prefix index (every stored key
  plus each prefix ending before a `/` or `-`), built on the first question and
  dropped by every mutator, instead of scanning every stored key per call. The
  markdown emitter, the validator and the query engine ask it once per model
  node, so rendering a large document was quadratic: the tom_uam Solution
  Blueprint (about 10,000 values) took 299 s to render and `validate_spec` 6 min
  41 s; they now take about 2 s and 10 s, with a byte-identical rendition.
  Guarded by `spec_document_values_index_test.dart` (VI-1: agreement with a full
  scan after every mutator; VI-2: 20,000 values and 20,000 queries under 2 s).

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
- `CodeSpecsExtractor` refuses a root that is a generation projection (D13, `CGP`) with a `CodeSpecsExtractError` naming the root, instead of answering every area with an empty extract (`codespecs_prompt.md` §5). Keyed on `SpecModel.isGenerationInput`, the root class's `@CodeSpecsProjection` marker, never on a type name. Pinned by two new `codespecs_extract_cases.json` root cases.
- DocSpecs schema findings on a SOM document name the document path to fix:
  `SpecDocument.toMarkdownWithMap` / `SpecDocumentMarkdown.exportRootWithMap`
  return the rendition with its heading-line → path map
  (`SpecMarkdownRendition.pathAtLine`), and `validateSpecDocument` renders,
  validates and fills `DocSpecsViolation.path` (SOM §14). Pinned by
  `docspecs_path_cases.json`.
- A typed field (`int`, `double`, `num`, `bool`) holding text its type cannot
  read is no longer read as unset. `validateDocument` reports it with the new
  code `valueTypeMismatch`; `SpecEditor.value` / `formValue` throw a
  `FormatException` on it; `setValue` / `setFormValue` refuse such a string
  (SOM §9). Enum fields keep their forgiving read and `enumValueUnknown`.
  Pinned by `validation_cases.json` and `editor_cases.json`.
- An empty document encodes as `document:` with its root key and an empty
  mapping (`  SBP D00SolutionBlueprint: {}`) instead of `document: {}`, so the
  file still records which document root it is (SOM §12.3 rule 4). Decode still
  accepts `document: {}`. Pinned by a new `yaml_review_cases.json` case.
- A list item is known by its own section id in `SpecQueryEngine`: the
  `sectionIdExact` / `sectionIdPrefix` filters and the projection's `sectionId`
  use the item's stored id, else its positional id — the id its markdown heading
  carries — instead of the list field's id (llm_and_d4rt_tools.md §6). A list's
  own id now matches the list, not its items. Pinned by four new
  `query_cases.json` cases and the regenerated `projection_cases.json`.
- **Breaking:** `SpecYamlContents.review` is `null` when the file has no
  `review:` key and a map — possibly empty — when it has one, so decode → encode
  no longer adds `review: {}` to a document that never had a review pass
  (SOM §12.1). Pinned by a new `yaml_review_cases.json` case.
- Markdown import binds the prose of a section whose only body member is a form
  — the class-level `@Form` on `content` — as that form's preamble, where the
  YAML codec keeps it, instead of on the section's own path (SOM §11.6). A
  SOM-rendered Solution Blueprint now imports back clean on all three tiers.
  Pinned by a new `markdown_import_cases.json` case.
- The review pass follows one scalar rule in every port (SOM §12.5): plain
  scalars typed by the YAML 1.2 core schema on decode, and
  `SpecDocumentYaml.reviewScalar` writing a float that reads back as itself —
  `.inf`, `-.inf` and `.nan` for the non-finite values, which were written as
  `Infinity` and `NaN` and read back as strings. Pinned by two new
  `yaml_review_cases.json` cases.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- `SpecDocument.moveListItem(model, itemPath, toIndex, {toList})` reorders a
  list item, or moves it to another list of the same element class; the
  section id is the identity and the path the position (SOM §9). Values travel
  with the item, an anonymous item keeps its old id, and a cross-list stored id
  must fit the destination pattern. `SpecDocumentYaml.rekeyReview` re-keys the
  review pass with the move's path map. Pinned by `list_move_cases.json` in all
  nine runtimes.

- `validateDocument` reports `countMismatch` when a `countOf` form field
  (`FormFieldSpec.countOf`) states a number that is not a whole number or not
  the number of entries the document holds (SOM §9, phase 6). Pinned by the
  `countMatches` / `countMismatch` validation cases in all nine runtimes.

- `SpecDocument.assemble(fragments)` (`spec_document_assembly.dart`) builds one
  document from fragments of the same root, merging their stores field by
  field and refusing any place two fragments both write
  (`SpecAssemblyOverlap`). Pinned by `assembly_cases.json` in all nine
  runtimes (SOM §12.9).

- `CodeSpecsGate` runs Stage A of `codespecs_prompt.md` §4 — A1 to A5 — as one
  gate over (model, document, catalogue, schema), reporting each check's
  findings and never stopping at the first; a check that could not run is
  reported as not run, and the gate does not pass. A4 (required marker
  arguments have populated sources) and A5 (structured carriers still offered)
  are new; their tables come from the catalogue's new `gate` block
  (`CodeSpecsRequiredArgument`, `CodeSpecsCarrier`, `CodeSpecsFieldRef`).
  Pinned by `codespecs_gate_cases.json` in all nine runtimes.

- Reading Phase-4 files back (`spec_codespecs_records.dart`):
  `CodeSpecsExtract.fromYaml` (the inverse of `toYaml`, byte-stable;
  refuses an unknown `formatVersion` and a disagreeing `entryCount`);
  `CodeSpecsGateRecord` reads and writes `gate.verdicts.yaml` in a checked
  shape, with `withVerdict` and `checkAgainst(catalog)`; and
  `CodeSpecsExtractSet.fromFiles` / `fromDirectory` read a run's extracts
  scoped by its gate record. Errors are `CodeSpecsRecordError`. Pinned by
  `codespecs_record_cases.json` in all nine runtimes.

- `CodeSpecsAreaCatalog.steps` carries the `codespecs_mapping.md` §4.4.6
  authoring-step table as `CodeSpecsStep` rows (`number`, `title`, `slice`,
  `placedBy`, `areaCodes`), with `stepNumbered` and `stepsFor(area)`. A
  catalogue without `steps` still loads, with none. Pinned by
  `codespecs_extract_cases.json`'s `stepCases` in all nine runtimes.

- `DocSpecsDocument.replaceSectionBody(text, sectionId, body)` replaces one
  DocSpecs section's own body by id and keeps every other byte (SOM §14). It
  refuses an unknown or duplicated id and a body that would add a heading or
  leave a fence open. `DocSpecsDocument.allSections` walks the section tree.
  Pinned by `docspecs_replace_cases.json`.
- `SpecDocumentYaml.encode(..., review:)` writes the `review:` pass back, so a
  runtime load followed by a save keeps a reviewed document's review state
  (before, the pass was decoded and silently dropped on save). The writer
  (`writeReviewPass`) is a canonical pass-through: entries by path, fields by
  name, decode followed by encode byte-identical. `staleReviewPaths(model,
  document, review)` reports review entries whose path no longer resolves.
  The TomSpecs editor's own review writer is replaced by it. Pinned by
  `yaml_review_cases.json`.
- `SpecDocument.applyMarkdownResult(result, {allowRejections})` applies a parsed
  Markdown import as a full overwrite of the roots it covers (SOM §11.7): purge,
  then write content, forms, lists, headlines and codeSpecs through the
  installed path normalizer. A result with rejections is refused unless
  allowed. `SpecDocument.fromMarkdown(text, model)` loads a fresh document and
  returns it with the parse report (`SpecMarkdownImport`). Pinned by the
  `markdown_apply_cases.json` corpus table. Every consumer that loads a spec
  from Markdown used to carry its own copy of this step.
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

- Version follows the TomSpecs model to 1.3.3, which the generated
  `tom_som_dart_v0` facade pins.
- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.3.2

- Version realigned to TomSpecs model 1.3.2 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself: 1.3.2 carries a test-only fix in
  `tom_specs_model`, whose shipped tests read a workspace sibling and crashed in
  a hosted install.

## 1.3.1

- Version realigned to TomSpecs model 1.3.1 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself; 1.3.1 corrects dependency
  constraints across the release set so the published chain resolves to a set
  that actually compiles together.

## 1.3.0

- Version realigned to TomSpecs model 1.3 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself: the model-side work in this
  release (`ImportanceBand`, and the three-band risk entries moved onto the
  five-band matrix) reaches consumers through the regenerated facade and
  metadata, both of which this runtime reads generically.

## 1.2.0

- Version realigned to TomSpecs model 1.2 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself: the model-side work in this
  release (the four value enums bound to 20 form fields) reaches consumers
  through the regenerated facade and metadata, both of which this runtime reads
  generically.

## 1.1.0

- The CodeSpecs extractor (`spec_codespecs_extract`) emits extract format 3:
  entries additionally carry the enclosing section instance's `headline`
  (format 2) and the nearest enclosing list-item instance's stored
  `instanceId` (format 3). Both fields are copy-only and additive.
- Version realigned to TomSpecs model 1.1 (lockstep with `tom_som_dart_v0`).

## 1.0.0

- First packaged release of the generic Dart SOM runtime.
- Version tracks the TomSpecs model version; the typed `tom_som_dart_v0` facade
  pins the same version.
