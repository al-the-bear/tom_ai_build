# Changelog

## Unreleased

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
