# Changelog

## 0.10.0

- `generate_registry_tests`: generates the registry part of an application's
  test suite from its specification — operations by role, custom handler,
  error code and control, screens by role with refused actions hidden — as
  committed, formatted Dart test files over an application-owned
  `RegistryTestHarness`; cross-checks the registries in both directions;
  `--check` reports a removed case or a stale suite.

## 0.9.0

- Requires `tom_specs_core` 0.4.0. The model reader and meta export carry
  `Field.multiple`; the static tier rejects `multiple` without `refersTo`.

## 0.8.2

- `validate_codespecs` check 8 knows `@CsJob`'s `interval` arm: `interval`
  and `intervalAnchor` are its slots and no other arm's.

## 0.8.1

- The static tier rejects a form that declares one field name twice; the
  generated accessors of every runtime would otherwise collide.

## 0.8.0

- Requires `tom_specs_core` 0.3.0 and the 1.6.7 model chain.
- The model reader and meta export carry `Field.productOf` / `Field.rankOf`;
  the static tier (invariant `REFERS-TO`) checks that every operand and rank
  key is a numeric or enum field of its form or a sibling form, and accepts
  `./`-scoped `countOf` targets.

## 0.7.0

- Requires the 1.6.1 model chain (`tom_som_dart_runtime`, `tom_som_dart_v0`)
  and `tom_specs_core` 0.2.3.
- `validate_codespecs` checks 38–41: protocol bindings resolve
  (`@CsOperationBinding`), and framework protocol-feature hooks are complete and
  never re-declared as endpoints (`csFeatureHooks` / `csFeatureReservedPaths`,
  read from `--cs-vocabulary`).
- `Field.code` flows into the exported meta (`code: true` on a `formFields[]`
  entry, omitted when false) and into every language's generated form-field
  meta, so each runtime's markdown codec can write the value as a code span
  (SOM §11.4 rule 8). Requires `tom_specs_core` 0.2.3 and the 1.6.1 Dart chain.

## 0.6.0

- Requires the 1.5.0 model chain (`tom_som_dart_runtime`, `tom_som_dart_v0`).
- The exported spec-model meta carries `modelHash`, the sha256 of its canonical
  content without the build keys (`specModelContentHash`), so a consumer can
  tell a changed model under an unchanged version. `validateSpecModelMeta`
  refuses a `modelHash` that does not match the content. A canonical
  `generate_som` run records hash and version in `tool/model_surface.stamp.json`
  and warns when the hash moved but the `tom_specs_model` version did not
  (`modelChangeWithoutVersionBump`).
- `validate_spec` reports a schema finding's document path and section id.
- `tool/verify_published_tests.sh --preflight` runs every release member's own
  suite on the local tree before a publish; the README carries the release
  procedure.
- The schema generator lets a `@Reference` list's container admit the item
  types its element class is owned under elsewhere.
- The default suite gained the archive-ignore gate
  (`lib/src/pub_archive_ignores.dart`): every release member is dry-run
  published, and no tracked file may be dropped from its archive.
- The README records the package as the exception to the `tom_build_base` CLI
  rule.

## 0.5.0

- The model reader and JSON export carry `Field.countOf` into the meta, and the
  static validator checks its targets under invariant `REFERS-TO` (a
  list-element class; a filter field the class declares, an enum value it
  has).

- `validate_spec` takes several fragments of one document: each is decoded,
  they are assembled (`SpecDocument.assemble`; an overlap is a decode-tier
  finding and stops the other tiers), and the schema and instance tiers judge
  the assembly, so cross-fragment references are no longer reported dangling.
  `--assembled-out` writes the assembled document.

- `validate_spec` validates any project's TomSpecs document — a
  `*.docspecs.yaml` or a SOM-rendered `*.md`, any of the fourteen roots,
  detected or named with `--root` — on three tiers that all run: decode, the
  DocSpecs schema over the rendition, and `validateDocument`. `--markdown-out`
  writes the rendition; `--json` gives the report in `validate_codespecs`'
  shape. Depends on `tom_som_dart_v0` for the embedded model and schemas.
  Documented in `doc/validating_a_document.md`.

- `validate_codespecs --json` writes one versioned JSON report (format
  `codespecs-validation`): inputs, unrun checks, excluded areas, and per
  violation its check, title, defining section, severity, file, line, token,
  area and message. `CodeSpecsViolation` gains `token` and `area`, set by checks
  34–36. The text report is unchanged.
- `validate_codespecs --backlinks` writes the trio's back-link index (format
  `codespecs-backlinks`): every declaration with its `@CodeSpec` id and source
  tokens, its `@DocSpec` tokens, locus, file and line.
- The command moved into `lib` (`runValidateCodespecs`) and compiles with
  `dart compile exe` into a standalone binary; a test compiles it and runs it
  with no SDK on `PATH`.

- `bin/codespecs_areas.dart` also transcribes the Stage-A gate tables of
  `codespecs_prompt.md` §4.4.2 (A4's required arguments, with their
  *Resolves to* and *Applies when* columns) and §4.5 (A5's carriers) into the
  catalogue's `gate` block (`--prompt` names the document). A test holds every
  row to the generated model.

- `validate_codespecs` reads extracts and the gate record through the SOM
  runtime's `CodeSpecsExtractSet` instead of a reader of its own. The
  gate-record entry may carry a `note:`; an unknown key in it is now an error.

- `bin/codespecs_areas.dart` transcribes the `codespecs_mapping.md` §4.4.6
  step table into the catalogue's `steps` array, cells verbatim, and checks
  the step ↔ area relation in both directions; `--check` covers it.

- **The TypeScript and JavaScript facades carry a DocSpecs schema accessor**
  (`SomScriptSchemasEmitter`): `somDocSpecsSchema(id)` in
  `<package>_schemas.ts` / `.js`, embedded like Dart's, exported as
  `<package>/schemas`, with `<package>/schemas/*` opening the shipped files.
- **The TypeScript facade takes its runtime as a peer dependency**, linked for
  its own build by a `file:` devDependency. A `file:` dependency travelled into
  the `npm pack` tarball and left a symlink in a consumer's installed tree;
  the two tarballs now install side by side with none.
- **The model JSON export honours a class-level `@Form`.** A class's `content`
  member is exported as a form carrying the class's form fields, as
  `tom_specs_model_rules.md` §5.3 states and the DocSpecs schema generator
  already did. All 73 such classes reached the nine runtimes as plain text, so
  a document could satisfy the schema tier or the instance tier, never both.
- **`@ContentType('description', …)` is prose.** The schema generator gives
  `text` and `description` no `format` (`proseContentTypes`); `description`
  used to become a format, which made the validator demand a fenced code
  block around a sentence.

## 0.4.0

- **`bin/check_som_parity.dart`** — asks whether a capability reached all nine
  SOM planes, not only whether the planes agree, with deliberate asymmetries
  recorded in `tool/som_parity_exceptions.yaml`.
- **Documentation-generator provisioning**: `tool/provision_doc_generators.sh`
  reports (and on `--install` performs) the toolchains the eight API-reference
  generators need, sharing its PATH rules with the reference driver through
  `tool/lib/doc_toolchain_path.sh`. pdoc is required on Python >= 3.13.
- `check_release_drift.dart` honours `.pubignore`: a path that never reaches
  pub.dev is not unpublished change. It also reads a `published_from:` record
  (version + commit) and measures from the commit a version was actually
  published from, so a change that landed between the bump and the publish is
  not reported as unpublished for the life of the version.
- `tool/release_set.yaml` is no longer shipped: it records this workspace's
  releases, and shipping it made every recorded acknowledgement drift the
  package that holds it.
- Section-citation, doc-coverage and invariant-correspondence gates refined;
  `tool/doccov.py`, the documentation campaign's Python counter, is retired.

## 0.3.2

- **`tool/verify_published_tests.sh` — run every release member's shipped tests
  from its pub.dev archive**, against hosted dependencies, in a directory with
  no workspace siblings. It downloads the archive rather than rebuilding one
  from `git ls-files` minus `.pubignore`: a reconstruction re-implements pub's
  packaging rules and would hide the case that motivated it — fixtures
  untracked in git, so absent from the archive while present in the workspace.
- A **release step**, not a standing gate, and it refuses to start while
  `check_release_drift.dart` is red. The archive's tests are only meaningful
  against the archive's dependencies; a local tree run against published
  siblings reports stale-publish drift as a test failure, which teaches a reader
  to ignore the check.
- Its first run found `tom_specs_model` shipping three test groups that read a
  workspace sibling and crashed for a consumer.

## 0.3.1

- `bin/check_release_drift.dart` gains the option surface every entrypoint in
  this package carries (`--manifest`, `--container-root`, `--verbose`,
  `--help`), and the README row documents it. Caught by this package's own
  `entrypoint_options_test`, which requires every entrypoint to declare
  `--help` and every README row to cite only options the entrypoint really
  has — 0.3.0 shipped the tool with no `ArgParser` at all.
- The first thing the new gate reported was this package: 0.3.0 was published
  and then two files changed. That is the loop it exists to close.

## 0.3.0

240 files, +34,604 lines since 0.2.0 — the largest drift in the release set,
and it is mostly gates and generators rather than new surface.

- **Two new generated accessors** (SOM §10.3): `SomDartSchemasEmitter` writes
  the fourteen embedded DocSpecs schemas as `somDocSpecsSchema(id)`, and
  `bin/codespecs_areas.dart` now writes a Dart accessor beside the area
  catalogue JSON. Both close the same defect the whole-model accessor closed:
  a package-relative read returns nothing in an AOT binary and does not say so.
- **The model's value enums are bound**, and the generators carry them through:
  `enums:` and `modelLabel:` reach `DocSpecsSchemaGenerator` from all nine
  language generators, Go emits a defined type over string and Rust a real
  `enum` with `as_str`/`from_token`.
- **`somReachableEnums` and `somEmittedSurface`** consolidate rules that had
  been written out once per emitter — nine byte-identical copies of the
  reachability walk, eighteen of the root filter — and eight of the nine enum
  copies were collecting a field kind the model never declares, so eight
  facades emitted no enum at all.
- **New standing gates**, all in the default `dart test` run: three citation
  gates plus the scan-set coverage check that keeps their subject closed, the
  formatting gate, the release-closure walk, the release-**drift** report added
  in this release, the model-freshness stamp, invariant correspondence, the
  doc-coverage ratchet, the `spec_ops` coverage checks, the spec-tree
  duplication ratchet and the shipped-script path gate.
- **`spec_ops.g.dart`** gains the `connect:` binding for all thirteen
  projection roots, so a projection re-points onto the live document instead of
  serializing default-constructed sections.
- The package is documented, formatted under the tall style, and its README is
  the CLI reference.

## 0.2.0

- SOM generators emit the format-3 CodeSpecs extractor across all nine
  runtimes (headlines + instance ids); the areas catalogue gains CE-EN, the
  `domainEnum` member kind's extract home (27 areas).
- CodeSpecs validator: extract-reading checks extended (`cs_extract`,
  `cs_checks`); packaging updates for the Python, Go, Java and Rust targets.
- Depends on `tom_som_dart_runtime` ^1.1.0.

## 0.1.0

- Initial development release (pub.dev 0.x channel, BSD-3-Clause).
