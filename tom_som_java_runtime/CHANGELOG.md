# Changelog

## Unreleased

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
