# Changelog

## Unreleased

- CodeSpecs: reading a Phase-4 run back (new module `spec_codespecs_records`,
  re-exported from the crate root). `CodeSpecsExtract::from_yaml(text,
  source)` / `parse_code_specs_extract_yaml` are the inverse of `to_yaml`
  (byte-identical round trip for every extract the extractor writes): they
  require `formatVersion` 3 and a non-empty `area.code`, read every other
  absent key as empty, strip a leading `CodeSpecPart.` from `area.part`, and
  refuse a wrong-typed key or a `document.entryCount` that disagrees with the
  entries. New `CodeSpecsGateRecord` (`gate.verdicts.yaml`, format 1):
  `new` checks the shape (CE-* areas named once, `resolution: descoped` only
  on an insufficient area), `from_yaml` also refuses unknown keys and other
  format versions, `to_yaml` is byte-stable, plus `verdict_for`,
  `check_against(catalog)` and `with_verdict`. New `CodeSpecsGateVerdict`,
  `CodeSpecsGateEntry`, `CodeSpecsExcludedArea`, and
  `CodeSpecsExtractSet::from_files` (an ordered sequence of `(name, text)`
  pairs) / `from_directory`, which scope the extracts by their gate record and
  expose `by_area`, `entries_for_section` and `entries_at_path`. Every reader
  returns `Result<_, CodeSpecsRecordError>`. The YAML reader gains
  `yaml_parse_raw_scalars`, which keeps scalars as source text so the record
  reader can tell `null` from `"null"`. Verified against the corpus table
  `codespecs_record_cases.json`.
- CodeSpecs: the area catalogue carries the `codespecs_mapping.md` §4.4.6
  authoring-step table. New `CodeSpecsStep` (`number`, `title`, `slice`,
  `placed_by`, `area_codes`), re-exported from the crate root, and
  `CodeSpecsAreaCatalog::steps`, read from the optional `steps` key — a
  catalogue without it loads with no steps. `step_numbered(n)` returns
  `Option<&CodeSpecsStep>`; `steps_for(area)` returns the steps for
  `area.authoring_steps` in that order, skipping numbers the catalogue does not
  carry. Verified against `stepCases` in `codespecs_extract_cases.json`.
- `DocSpecsDocument::replace_section_body` replaces one section's own body
  (the lines between its heading and the next heading of any level) and keeps
  every other byte; the body is trimmed of leading/trailing blank lines and
  framed by one blank line on each side. It returns `Err` when the id names no
  section or several, or when the body carries a heading outside a fence or
  leaves a fence open. `DocSpecsDocument::all_sections` walks the tree
  depth-first. Verified against the corpus table
  `docspecs_replace_cases.json`.
- YAML codec: the `review:` pass is written back. `encode_yaml_with_review`
  takes an optional review map (typically the one `decode_yaml` returned) and
  appends it after the document pass via `write_review_pass`: entries sorted by
  path with JSON-quoted keys, each entry's fields sorted by name, booleans,
  numbers and identifier-like strings plain, any other string as a
  self-verified block scalar, lists as JSON flow; an empty map writes
  `review: {}`. `stale_review_paths` reports the review paths that no longer
  resolve against a document (unknown paths, removed list items), sorted.
  Verified against the corpus table `yaml_review_cases.json`.
- Applying a Markdown import is a runtime operation (SOM §11.7).
  `SpecDocument::apply_markdown_result` overwrites the roots a parsed import
  covers and keeps every other root; a result with rejections is refused with
  `Err` and leaves the document unchanged unless `allow_rejections` is true.
  `SpecDocument::from_markdown` parses and loads a fresh document in one call
  and returns a `SpecMarkdownImport` (the document plus the parse report, with
  a `rejections()` accessor). Verified against the corpus table
  `markdown_apply_cases.json`.
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

- Generic TomSpecs object-model runtime for Rust: section-path grammar, meta-data
  model loader, reflection/resolution, sparse document, validator, and the
  YAML/Markdown codecs, plus a hand-rolled JSON reader/encoder.
- Zero external dependencies (Rust standard library only — no `serde` /
  `serde_yaml` / `regex`); validated against the shared language-agnostic
  conformance corpus.
- Packaged as a Cargo crate `tom_som_rust_runtime` with `publish = false`
  (proprietary); `cargo package --no-verify` is the packaging check.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its `Cargo.toml` version is realigned by
  `tom_specs_clitool/bin/generate_som.dart`.
