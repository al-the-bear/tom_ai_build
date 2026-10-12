# Changelog

## Unreleased

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
