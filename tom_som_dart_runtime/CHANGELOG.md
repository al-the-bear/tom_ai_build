# Changelog

## Unreleased

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
