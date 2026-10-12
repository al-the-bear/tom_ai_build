# Changelog

## Unreleased

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
