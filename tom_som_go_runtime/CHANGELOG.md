# Changelog

## Unreleased

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
