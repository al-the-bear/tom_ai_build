# Sample — author a Solution Blueprint (JavaScript)

**Teaches:** the same as [the Dart sample](../README.md) — authoring a TomSpecs
specification end to end through the typed facade: write, serialise both
renditions, round-trip, validate, and read a real diagnostic.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** JavaScript (Node), on `tom_som_javascript_v0` and `tom_som_javascript_runtime`.

A port of `../bin/author_solution_blueprint.dart`, step for step.

## Prerequisites

* Node 18 or later and npm (`node --version`).
* A checkout of `tom_ai/ai_build`. The JavaScript packages,
  `tom_som_javascript_runtime` and `tom_som_javascript_v0`, are **not on npm**
  (the non-Dart runtimes are not published to registries), so `package.json`
  takes both as `file:` dependencies on the checkout. `npm install` links them
  into `node_modules/` and fetches nothing; the runtime has no dependencies of
  its own.

## Run it

```bash
npm install
node index.js
```

## What you should see

Exactly what the Dart sample prints: its [`expected_output.txt`](../expected_output.txt),
which the samples driver compares this port against too. The two renditions are
written to `build/`, byte for byte the ones the Dart sample writes.

The model comes from the facade's `tom_som_javascript_v0/meta` export (the
shipped `spec_model.meta.json`), read with `SpecModel.fromJson`.
