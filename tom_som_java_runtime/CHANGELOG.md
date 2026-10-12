# Changelog

## Unreleased

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
