# tom_specs_model

The **TomSpecs Specification Object Model — the Dart source model**. This
package is the single source of truth from which the SOM is generated into
nine languages (Dart, Python, Java, JavaScript, TypeScript, Go, Rust, C, C++):
typed classes for the Solution Blueprint (D00) and the twelve Phase-3 detail
documents (D01–D12), plus the flat CodeSpecs generation projection (D13),
annotated with the `tom_specs_core` vocabulary.

It also carries, under `doc/`, the **thirteen TomSpecs authority documents** —
the process definition, the SOM specification, the model-authoring rules and
the CodeSpecs documents — catalogued by `doc/index.md`.

## What this package is (and is not)

- It **is** the model the generator reads: every class tree, section id,
  headline, form decomposition, traceability link and DocSpecs constraint that
  the nine generated runtimes and typed facades carry originates here.
- It is **not** the package most consumers depend on. To author, read,
  validate, or extract from a specification document in Dart, depend on
  **`tom_som_dart_v0`** (the generated typed facade) and its runtime
  `tom_som_dart_runtime`. Depend on `tom_specs_model` when you need the model
  source itself — for example to run the generator or the model-level tooling
  in `tom_specs_clitool`.

## Structure

- `lib/src/common/` — shared types: enums, `Requirement`, `Risk`,
  `DocumentHeader`, section metadata.
- `lib/src/solution_blueprint/` — the D00 Solution Blueprint model.
- `lib/src/<document>/` — one folder per Phase-3 detail document
  (requirements, information model, architecture, security, quality plan, …).
- `lib/src/codespecs_projection/` — D13, the flat CodeSpecs generation
  projection.
- `lib/src/generated/spec_ops.g.dart` — the generated `SpecClassOps`
  registry (snapshot/serialization contract per concrete class).
- `doc/` — the thirteen authority documents, starting at `doc/index.md`.
- `generated-doc/` — generator output (class-tree outlines, the CodeSpecs
  areas catalogue); never hand-edited.

## Getting started

Read `doc/index.md` for the documentation map. The model-authoring rules —
layout, field shapes, annotations, structural invariants — are in
`doc/tom_specs_model_rules.md`; the nine-language generation is specified in
`doc/som_multiplatform_spec_model.md`.

The generator and validator live in `tom_specs_clitool`; the conformance
harness that proves the nine generated runtimes agree is `tom_som_conformance`
in the same repository.

## Additional information

Part of **TomSpecs Release 1** — see the repository's `README.md` and
`RELEASE_NOTES.md` (https://github.com/al-the-bear/tom_ai_build). Licensed
under BSD 3-Clause.
