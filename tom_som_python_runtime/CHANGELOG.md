# Changelog

## Unreleased

- The YAML codec's decode returns the `review:` pass as `None` when the file has no `review:` key (an explicit `review: {}` or a bare `review:` still gives an empty map), so decode-then-encode no longer adds `review: {}` to a file without a review pass (SOM §12.1). Pinned by the new `yaml_review_cases.json` round-trip case.
- Markdown import: prose in a section whose owner has only form slots (a class-level `@Form` on the `content` member) is that form's preamble (SOM §11.6) — it binds to the `content` form slot, else the first form slot, with a label-shaped line's escape space stripped — instead of the owner's own path, which the model rejected. Pinned by the last `markdown_import_cases.json` case.
- A malformed CodeSpecs area catalogue row (a slice or step without a numeric `number`/`slice`, a string where a number belongs, an area without a non-empty `code`/`part`) now raises a `ValueError` that names the row, as the Dart reference does, instead of a bare `KeyError` or a coerced value. Pinned by the six `catalogErrorCases` of `codespecs_extract_cases.json`.
- Review-pass scalars keep their YAML 1.2 type (SOM §12.5): the `review:` pass is re-read with a core-schema PyYAML loader (`0o`/`0x` ints, `1e+300`, `.inf`/`.nan`, `TRUE`, `~`; `yes`/`on` stay strings; an integer beyond 64 bits reads as a float), and the new `review_scalar` writes floats so they read back as floats (`3.0`, `1e+300`, `1e-7`, `-.inf`). Pinned by two new `yaml_review_cases.json` cases.

## 1.4.1

- No change of its own: released in lockstep with `tom_specs_model` 1.4.1.

## 1.4.0

- Moving a list item (vsctsa44): `SpecDocument.move_list_item(model,
  item_path, to_index, to_list=None)` moves an item to position `to_index` of
  its list, or of `to_list`, another list of the same element class, and
  returns a `SpecListItemMove` (`path`, `renamed` old → new item paths,
  `pinned_ids` new path → id). A path is a position, the section id is the
  identity: every affected list is renumbered to `<list>-1..n` (seq = n, an
  emptied list is dropped), every store key at or under an old item path is
  re-keyed, and an anonymous item whose positional id changes has its old id
  stored. Refusals change nothing: `ValueError` (not a live list item, not a
  model list, another element class, a stored id not fitting the destination
  `@SectionIdPattern`), `SpecSectionIdCollision` (the stored id is taken in
  the destination), `IndexError` (`to_index` out of range).
  `rekey_review(review, renamed)` (in `spec_document_yaml`) returns the
  `review:` pass re-keyed the same way. The `list_move_cases.json` corpus table
  pins both.
- Stated counts (vsctsa43): `FormFieldSpec.count_of` reads the meta's
  `formFields[].countOf` (absent → empty), and `validate_document` gains a
  sixth, instance-tier step after the reference check. A form field with
  `count_of` must hold a whole number equal to the entries the document holds:
  a target `X` counts every list item whose element class carries
  `@SectionId(X)`, `X.f=v` only those whose own form holds `v` in `f`, summed
  over the targets. A blank value, or a target outside the document's registry
  scope, is skipped; anything else that does not match is reported under the
  new `SpecValidationCode.COUNT_MISMATCH` (`countMismatch`). The corpus cases
  `countMatches` and `countMismatch` pin it.
- Document assembly: a new module `spec_document_assembly` merges fragments
  written in parallel into one document. `SpecDocument.assemble(fragments)`
  (also `assemble_spec_documents`) takes an ordered sequence of
  `(name, SpecDocument)` pairs (or a mapping) and merges the plain-data stores
  of `to_json()`: content, headlines and code-spec locations one value per
  path, forms field by field, lists whole. The merge is refusing — a place two
  fragments both write is a `SpecAssemblyOverlap` (`store`, `path`, `field`,
  `fragments`, `message`) and the `SpecDocumentAssembly` then carries no
  `document` (`ok` is false). Overlaps are reported in store order, then path
  order. The `assembly_cases.json` corpus table pins it.
- CodeSpecs gate: a new module `spec_codespecs_gate` runs Stage A of
  `codespecs_prompt.md` §4 as one `CodeSpecsGate(model, document, catalog,
  schema=None, root_type=None).run()`, returning a `CodeSpecsGateReport` with
  one `CodeSpecsGateCheckResult` per check A1–A5 (`ran`, `not_run_reason`,
  `findings`, `passed`), the extraction run's `extracts` when A3 passed, and
  `report[check]` lookup. A1 validates the rendered Markdown against the
  DocSpecs schema, A2 runs `validate_document`, A3 reports every unrouted
  section of the non-strict walk (or the root-resolution error), A4 holds each
  required marker argument of a used area to a populated source (with the
  `when` filter and `resolves_to` check), A5 checks every carrier still exists
  in the model. A check that cannot run is reported not run, with its reason,
  and fails the gate. `CodeSpecsAreaCatalog.from_json` reads the optional
  `gate` key into `required_arguments` (`CodeSpecsRequiredArgument`),
  `carriers` (`CodeSpecsCarrier`) and `has_gate_tables`; field references are
  `CodeSpecsFieldRef`. The `codespecs_gate_cases.json` corpus table pins it.
- CodeSpecs records: a new module `spec_codespecs_records` reads back what a
  Phase-4 run wrote. `CodeSpecsExtract.from_yaml(text, source)` (also
  `parse_code_specs_extract_yaml`) is the inverse of `to_yaml` — byte-stable
  for every extract the extractor writes; it requires `formatVersion` 3 and a
  non-empty `area.code`, reads every other absent key as empty, refuses a
  present key of the wrong type and a `document.entryCount` that disagrees
  with the entries. `CodeSpecsGateRecord` reads, checks and writes the Stage-B
  gate record `gate.verdicts.yaml` (`from_yaml`, `to_yaml`, `verdict_for`,
  `check_against(catalog)`, `with_verdict`), with `CodeSpecsGateVerdict` and
  `CodeSpecsGateEntry`. `CodeSpecsExtractSet.from_files(pairs)` /
  `from_directory(path)` read a tree of extracts scoped by its gate record
  (`extracts`, `sources`, `excluded`, `gate`, `by_area`,
  `entries_for_section`, `entries_at_path`). Errors are
  `CodeSpecsRecordError`. The YAML is read through a PyYAML loader narrowed to
  YAML 1.2 booleans, without implicit timestamps and refusing duplicate keys,
  so it reads what `package:yaml` reads. The `codespecs_record_cases.json`
  corpus table pins it.
- CodeSpecs catalogue: `CodeSpecsAreaCatalog.steps` carries the
  `codespecs_mapping.md` §4.4.6 authoring-step table as `CodeSpecsStep` rows
  (`number`, `title`, `slice`, `placed_by`, `area_codes`); a catalogue without
  a `steps` key loads with none. `step_numbered(n)` finds one step and
  `steps_for(area)` returns the steps of `area.authoring_steps` in that order,
  skipping numbers the catalogue does not carry. `CodeSpecsStep` is exported
  from `tom_som_runtime`. The `stepCases` table of
  `codespecs_extract_cases.json` pins it.
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
