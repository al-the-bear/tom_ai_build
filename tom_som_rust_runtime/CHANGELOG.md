# Changelog

## Unreleased

- Query section ids (llm_and_d4rt_tools.md §6): a list item is known by its own effective id — stored, else the list's `@SectionIdPattern` with its 1-based position, else `<member>-<position>` — in the `sectionIdExact`/`sectionIdPrefix` filters and the projection's `section_id`, so a list's own id matches only the list; pinned by four new `query_cases.json` cases and `projection_cases.json`.
- YAML review pass presence (SOM §12.1): `SpecYamlContents::review` is now `Option<YamlMap>` — `None` when the file has no `review:` key, `Some` (possibly empty) when it has one — so a file without a review pass round-trips without gaining `review: {}`; pinned by the new `yaml_review_cases.json` case.
- Markdown import (SOM §11.6): prose in a section whose owner has no content slot but has form slots (a class-level `@Form` on `content`) is that form's preamble — `finalize_body_slots` binds it to `<owner>/content` (else the first form slot) and strips the escape space of a label-shaped preamble line, instead of storing it on the owner's path (kindMismatch); pinned by the new last `markdown_import_cases.json` case.
- CodeSpecs catalogue: `CodeSpecsSlice`, `CodeSpecsStep` and `CodeSpecsArea` gain `try_from_json` (Result, error naming the row); `from_json` delegates and panics with the same message; `CodeSpecsAreaCatalog::from_json` propagates the row error instead of reading 0 or ""; pinned by the new `catalogErrorCases` table of `codespecs_extract_cases.json`.
- Review-pass scalars keep their YAML 1.2 type (SOM §12.5): `YamlValue` gains `Null`/`Bool`/`Float`, the new `yaml_parse_typed` reads the `review:` pass by the core schema (ints and floats distinct, an integer beyond 64 bits as a float), and `write_review_pass` writes the typed values back (`3.0`, `1e+300`, `-.inf`) instead of guessing types from string text. Pinned by two new `yaml_review_cases.json` cases.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item: `SpecDocument::move_list_item(model, item_path,
  to_index, to_list)` reorders a list item, or moves it into another list of
  the same element class; the section id is the identity and the path the
  position. Every affected list is renumbered to `<list>-1..n`, every value
  under each item (content, forms, headlines, code specs, nested lists, stored
  ids) is re-keyed with it, and an anonymous item whose positional id changes
  has its old id stored. The result is a `SpecListItemMove` (`path`, and the
  ordered `(old, new)` / `(new path, id)` pairs `renamed` / `pinned_ids`).
  A refusal changes nothing and is a `SpecListMoveError`: `NotLiveItem`,
  `NotAList`, `ElementClassMismatch` and `PatternMismatch` (the conformance
  word `argument`), `Collision` (`collision`) and `IndexOutOfRange`
  (`range`). `spec_document_yaml::rekey_review(review, renamed)` re-keys a
  `review:` pass with the move's `renamed` pairs. Verified against
  `list_move_cases.json`.

- Stated counts: `FormFieldSpec::count_of` (read from the meta's
  `formFields[].countOf`, empty when absent) names the entries a form field's
  value counts — `X` (every list item whose element class carries
  `@SectionId(X)`) or `X.f=v` (those entries one of whose own forms holds `v`
  in form field `f`), summed over the targets. `validate_document` reports the
  new `SPEC_VALIDATION_CODE_COUNT_MISMATCH` (`countMismatch`) after the
  reference check when a non-empty stated value is not a whole number or not
  the number of entries the document holds; a target outside the document's
  registry scope skips the field. Verified by the `countMatches` /
  `countMismatch` validation cases.

- Assembling one document from fragments written in parallel, new module
  `spec_document_assembly` re-exported from the crate root:
  `SpecDocument::assemble(&[(name, &document), ...])` (also
  `assemble_spec_documents`) merges the fragments' `to_json` stores, in the
  order given. The merge is refusing: a content path, headline or code-spec
  location two fragments both write, a form field two fragments both fill (two
  fragments may fill different fields of one form), or a list two fragments
  both hold is a `SpecAssemblyOverlap` (`store`, `path`, `field`,
  `fragments`, `message()`), and a `SpecDocumentAssembly` with any overlap has
  `document: None` (`ok()` is false). Overlaps are reported in store order
  content, forms, lists, headlines, codeSpecs, then by path (UTF-16 order).
  A fragment name given twice panics. Verified against `assembly_cases.json`.
- CodeSpecs: the Stage-A gate (`codespecs_prompt.md` §4, A1–A5), new module
  `spec_codespecs_gate` re-exported from the crate root:
  `CodeSpecsGate::new(model, document, catalog, schema, root_type).run()`
  returns a `CodeSpecsGateReport` (`results` A1..A5 in order, `extracts` when
  A3 passed, `passed()`, `findings()`, `get(check)`) — never a `Result`: every
  check runs, and one that cannot run is reported not run, with its reason,
  and never passes. A1 renders with `SpecDocument::to_markdown` and validates
  with `DocSpecsValidator` (a render `Err`, which Dart throws, is reported as
  A1 not run); A2 is `validate_document`; A3 collects every unrouted class
  from the non-strict `routings()` walk (or the root-resolution error) and
  only then runs `extract_all()`; A4 checks each required marker argument's
  source (with `when` and `resolves_to`); A5 checks each carrier against the
  model. New `CodeSpecsGateCheck` (`label()` = `A1`..`A5`),
  `CodeSpecsGateCheckResult`, `CodeSpecsGateFinding`. The area catalogue reads
  the optional `gate` block: new `CodeSpecsFieldRef`,
  `CodeSpecsRequiredArgument`, `CodeSpecsCarrier` (each `from_json` returns
  `Result<_, String>`), and `CodeSpecsAreaCatalog::required_arguments` /
  `carriers` / `has_gate_tables`. **Breaking:** `CodeSpecsAreaCatalog::from_json`
  now returns `Result<CodeSpecsAreaCatalog, String>`, failing on a gate row
  missing a required cell. Verified against `codespecs_gate_cases.json`.
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
