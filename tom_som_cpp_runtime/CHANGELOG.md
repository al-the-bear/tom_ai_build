# Changelog

## Unreleased

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
