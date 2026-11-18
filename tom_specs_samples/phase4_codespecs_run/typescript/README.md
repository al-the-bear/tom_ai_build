# Sample — a Phase 4 CodeSpecs run (TypeScript)

**Teaches:** the first two stages of [the Dart sample](../README.md) — the
starting prompt's quality gate (passing and rejecting) and the extract
generator — on the same specification.
**Phase:** 4 (CodeSpecs) of `tom_specs_project_flow.md`.
**Language:** TypeScript (Node), on `tom_som_typescript_v0` and `tom_som_typescript_runtime`.

The TypeScript runtime carries the gate (`CodeSpecsGate`, checks A1–A5) and the
extract generator, as all nine runtimes do. Stages 3 and 4 are not here: the
authoring agent writes the IR, and the Dart tools map and validate it
(`tomspecs :ir-map`, `tomspecs :codespecs-validate`). The Dart sample shows them.
This port says so where they would be, rather than printing what it did not run.

## Prerequisites

* Node 18 or later and npm (`node --version`).
* A checkout of `tom_ai/ai_build`. The TypeScript packages,
  `tom_som_typescript_runtime` and `tom_som_typescript_v0`, are **not on npm**
  (the non-Dart runtimes are not published to registries), so `package.json`
  takes both as `file:` dependencies on the checkout. Their compiled `dist/` is
  not committed, so `npm run build` builds both packages first
  (`build:packages`) and then compiles this port with `tsc` (the one
  `typescript` devDependency, which `npm install` fetches).

## Run it

```bash
npm install
npm run build
npm start
```

`npm start` runs the compiled `dist/index.js`; the source is `src/index.ts`.

The area catalogue the extractor walks is `tom_specs_model/generated-doc/codespecs/codespecs_areas.json`
in the checkout: the Dart package `tom_specs_model` ships it with an accessor,
and the TypeScript runtime has none.

## What you should see

Variant A passing the gate and producing 27 extracts (3 populated), variant B
rejected with six findings. The text is in this port's own
[`expected_output.txt`](expected_output.txt): stages 1 and 2 and variant B are
the Dart sample's lines, and stages 3 and 4 are replaced by the note above.
The 54 extract files in `build/codespecs_extracts/` are byte for byte the ones
the Dart sample writes.
