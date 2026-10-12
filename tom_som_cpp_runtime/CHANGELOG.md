# Changelog

## Unreleased

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
