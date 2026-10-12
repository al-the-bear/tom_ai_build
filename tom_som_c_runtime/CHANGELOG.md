# Changelog

## Unreleased

- Stated counts (vsctsa43). `FormFieldSpec.count_of` (a `SomStrList`, read
  from the meta's `formFields[].countOf`; empty when absent, freed with the
  model) names the entries a form field's value counts — `X` for every list
  item whose element class carries `@SectionId(X)`, `X.f=v` for those whose
  own form holds `v` in form field `f`. `validate_document` gains phase 6,
  after the reference check: a non-empty value that is not a whole number, or
  not the summed count, is reported as `SPEC_VALIDATION_CODE_COUNT_MISMATCH`
  (`"countMismatch"`) at the form path, with the Dart reference's messages;
  a field with any target outside the document's registry scope is skipped.
  The conformance runner checks the `countMatches` / `countMismatch`
  validation cases.

- Assembling one document from fragments written in parallel
  (`spec_document_assembly.h`). `spec_document_assemble` takes an ordered
  array of `SpecAssemblyFragment` (borrowed `name` + `document`) and fills a
  `SpecDocumentAssembly` — the assembled `document` (owned) or, when any place
  is written by two or more fragments, no document and every
  `SpecAssemblyOverlap` (`store`, `path`, `field` for forms, `fragments` in the
  given order; `spec_assembly_overlap_message` renders the Dart reference's
  message). Content, headlines and codeSpecs overlap per path, forms per
  (path, field) — two fragments may fill different fields of one form — and
  lists per list path. Overlaps come in store order content, forms, lists,
  headlines, codeSpecs, then path order. Released with
  `spec_document_assembly_free`. The conformance runner checks every case of
  `assembly_cases.json` (`assembly[...]`).

- CodeSpecs: the Stage-A gate (`codespecs_prompt.md` §4, A1–A5) as one
  `CodeSpecsGate` (`spec_codespecs_gate.h`). `spec_codespecs_gate_make`
  borrows a model, document, catalogue, optional DocSpecs schema and optional
  root type; `spec_codespecs_gate_run` fills a `CodeSpecsGateReport` — one
  `CodeSpecsGateCheckResult` per check (`ran`, `not_run_reason`, the
  `CodeSpecsGateFinding`s with `code` / `location` / `message`), the
  extraction run's `extracts` when A3 passed, `passed`, findings in check
  order — released with `spec_codespecs_gate_report_free`. Every check runs;
  a check that cannot run (no schema, no gate tables, no extraction run) is
  reported not run, with the Dart reference's reason, and fails the gate. A1
  renders the document to Markdown and validates it with the DocSpecs
  validator; A2 is `validate_document`; A3 collects every unrouted class of the
  routing walk (or the root-resolution error) before extracting; A4 checks the
  catalogue's required marker arguments against the extracts; A5 checks its
  carriers against the model. The area catalogue reads the optional `gate`
  block: `CodeSpecsFieldRef` (`spec_codespecs_field_ref_source`),
  `CodeSpecsRequiredArgument` (with optional `resolves_to` / `when` +
  `when_equals`), `CodeSpecsCarrier`, and `CodeSpecsAreaCatalog`'s
  `required_arguments`, `carriers` and `has_gate_tables`, all released by
  `spec_codespecs_area_catalog_free`. The conformance runner checks every case
  of `codespecs_gate_cases.json` (`codespecsGate[...]`).

- CodeSpecs: reading Phase-4 output back (`spec_codespecs_records.h`).
  `spec_codespecs_extract_from_yaml` parses a `<CE-CODE>.extract.yaml` — the
  inverse of `spec_codespecs_extract_to_yaml`, byte-identical on the round
  trip — refusing an unknown `formatVersion`, a missing `area` / `area.code`,
  a wrongly typed key and a `document.entryCount` that disagrees with the
  entries; the read extract owns its area (new `CodeSpecsExtract.owned_area`,
  released by `spec_codespecs_extract_free`; `spec_codespecs_area_free` frees a
  standalone area). The Stage-B gate record: `CodeSpecsGateVerdict` (word /
  parse), `CodeSpecsGateEntry`, and `CodeSpecsGateRecord` built
  (`spec_codespecs_gate_record_make`) or read
  (`spec_codespecs_gate_record_from_yaml`) only in the checked shape, with
  `verdict_for`, `check_against` (a catalogue's active areas), `with_verdict`
  and the byte-stable `to_yaml`. `CodeSpecsExtractSet` reads an ordered list of
  `CodeSpecsRecordFile` name/text pairs
  (`spec_codespecs_extract_set_from_files`) or a directory
  (`spec_codespecs_extract_set_from_directory`) and scopes it by the gate
  record — in scope iff `sufficient`, excluded areas kept visible as
  `CodeSpecsExcludedArea` — with `by_area`, `entries_for_section` and
  `entries_at_path`. Failures fill a `CodeSpecsRecordError` whose message is
  the Dart reference's. `spec_codespecs_yaml_string` exposes the extract's
  string escaper. The conformance runner checks every case of
  `codespecs_record_cases.json` (`codespecsRecords.*`).
- CodeSpecs: the area catalogue carries the `codespecs_mapping.md` §4.4.6
  authoring-step table. `CodeSpecsStep` (`number`, `title`, `slice`,
  `placed_by`, `area_codes`) and `CodeSpecsAreaCatalog.steps` / `steps_len`,
  read from the catalogue's `steps` array — absent in an older catalogue,
  which loads with no steps — and released by
  `spec_codespecs_area_catalog_free`. `spec_codespecs_catalog_step_numbered`
  returns the step with a number or NULL; `spec_codespecs_catalog_steps_for`
  returns an area's steps in its `authoring_steps` order as an owned array of
  borrowed pointers, skipping numbers the catalogue does not carry. The
  conformance runner recomputes `stepCases` from `codespecs_extract_cases.json`
  (including the legacy catalogue with `steps` removed) and compares it with
  the committed table (`codespecs.stepCases`).
- DocSpecs: `docspecs_replace_section_body` replaces the own body of the one
  section (any level) whose id is given and keeps every other byte; it
  refuses an id naming no section or several (listing their lines), a body
  with a heading outside a fence, and a body that leaves a fence open. The
  conformance runner checks the shared `docspecs_replace_cases.json` table
  (`docspecsReplace[...]`).
- YAML codec: the `review:` pass is written back. `encode_yaml_with_review`
  encodes with a review value (NULL: no pass, exactly `encode_yaml`) and
  appends it through `spec_yaml_write_review_pass` — entries sorted by path
  (JSON-quoted keys), fields sorted by name, `review: {}` when empty; null,
  booleans, numbers and identifier-like strings plain, any other string as a
  self-verified block scalar, lists as JSON flow. `decode_yaml` now types the
  review pass's plain scalars as a YAML core-schema reader does (new
  `YAML_BOOL` / `YAML_NULL` / `YAML_FLOAT` kinds, a `plain` flag on
  `YamlValue`), so decode followed by encode is byte-identical;
  `yaml_value_from_json` builds a review in code. `spec_yaml_stale_review_paths`
  lists the review paths that no longer resolve (unknown to the model, or
  through a removed list item). The conformance runner checks the shared
  `yaml_review_cases.json` table (`yamlReview[...]`).
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
- Markdown import: `spec_document_apply_markdown_result` applies a parse result
  as a full overwrite of the roots it covers (SOM §11.7) — values under each
  root prefix are removed, then the parsed content, forms, lists (seq, items
  and stored ids), headlines and codeSpecs are written; other roots are kept.
  A result with rejections is refused, leaving the document unchanged, unless
  rejections are allowed. `spec_document_from_markdown` does parse + apply in
  one call and returns the document with the parse report
  (`SpecMarkdownImport`, freed with `spec_markdown_import_free`). The
  conformance runner checks the shared `markdown_apply_cases.json` table
  (`mdApply[...]`), and `md.land.memory` now lands through the one-call import.

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- Generic TomSpecs object-model runtime for C: section-path grammar, meta-data
  model loader, reflection/resolution, sparse document, validator, the typed
  store boundary (`spec_typed_values`), the generic meta-driven editing API
  (`spec_editor`), and the YAML/Markdown codecs, plus a hand-rolled JSON
  reader/encoder and a small C utility module (growable buffer / list /
  byte-sorted map).
- Zero external dependencies (C standard library only); validated against the
  shared language-agnostic conformance corpus.
- Packaged with a `Makefile` that builds a static (`.a`) and a shared (`.so`)
  library, emits a `pkg-config` file (`tom_som_c_runtime.pc`) whose `Version`
  tracks the model version, and provides `make install` and `make dist`
  (source tarball) targets.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its `Makefile` `VERSION` is realigned by
  `tom_specs_clitool/bin/generate_som.dart`.
