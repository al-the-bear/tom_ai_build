# Changelog

## Unreleased

- DocSpecs: `DocSpecsDocument.replace_section_body(text, section_id, body)`
  returns the markdown with one section's own body region replaced and every
  other byte kept; it raises `ValueError` when the id names no section or
  several, or when the body holds a heading outside a fence or leaves a fence
  open. `DocSpecsDocument.all_sections` lists every section depth-first. The
  `docspecs_replace_cases.json` corpus table pins it.
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
- Markdown import: `SpecDocument.apply_markdown_result(result,
  allow_rejections=False)` applies a parsed import as a full overwrite of the
  roots it covers, keeping every other root; a result with rejections raises
  `RuntimeError` and changes nothing unless `allow_rejections` is set.
  `SpecDocument.from_markdown(text, model)` parses and applies in one call and
  returns a `SpecMarkdownImport` (document, result, rejections). Pinned by the
  corpus table `markdown_apply_cases.json`.
- YAML codec: `encode(..., review=...)` writes the `review:` pass back after
  the document pass (`write_review_pass`): entries sorted by path with
  JSON-quoted keys, fields sorted by name, identifier-like strings, booleans
  and numbers plain, other strings as self-verified block scalars, lists as
  JSON flow, an empty map as `review: {}`; a decoded reviewed file now
  round-trips byte for byte. `stale_review_paths(model, document, review)`
  lists (sorted) the review entries that no longer resolve — unknown paths and
  paths through a removed list item. Pinned by the corpus table
  `yaml_review_cases.json`.

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- First packaged release of the generic Python SOM runtime.
- Version tracks the TomSpecs model version; the typed `tom_som_python_v0` facade
  pins the same version.
