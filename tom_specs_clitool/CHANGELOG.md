# Changelog

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
