# Changelog

## Unreleased

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
