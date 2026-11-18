# Sample — author a Solution Blueprint (TypeScript)

**Teaches:** the same as [the Dart sample](../README.md) — authoring a TomSpecs
specification end to end through the typed facade: write, serialise both
renditions, round-trip, validate, and read a real diagnostic — plus what the
static types add: a mis-typed section assignment does not compile.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** TypeScript (Node), on `tom_som_typescript_v0` and `tom_som_typescript_runtime`.

A port of `../bin/author_solution_blueprint.dart`, step for step.

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

## What you should see

Exactly what the Dart sample prints: its [`expected_output.txt`](../expected_output.txt),
which the samples driver compares this port against too. The two renditions are
written to `build/`, byte for byte the ones the Dart sample writes.

The model comes from the facade's `tom_som_typescript_v0/meta` export (the
shipped `spec_model.meta.json`), read with `SpecModel.fromJson`.

## A mis-typed section does not compile

[`type-errors/miswritten_section.ts`](type-errors/miswritten_section.ts) makes
three mistakes the JavaScript and Python ports would run without complaint:

1. passes `sbp.introductionAndScope` to a function that takes a
   `CurrentLandscape` — the wrong section (TS2345);
2. assigns to `sbp.currentLandscape` — a section accessor has no setter (TS2540);
3. writes the number `4.2` into a content leaf, which holds text (TS2322).

The file is outside the build (`tsconfig.json` takes `src/` only) and has its
own `tsconfig.type-errors.json`. To see the errors:

```bash
npx tsc -p tsconfig.type-errors.json --pretty false
```

[`tool/validate.sh`](tool/validate.sh) makes this a gate: it passes only while
`tsc` rejects the file with exactly the errors recorded in
[`type-errors/expected_tsc_output.txt`](type-errors/expected_tsc_output.txt),
and fails when the file compiles or the errors change (`--record` rewrites the
record after a deliberate change). The samples driver runs it after the output
comparison; it needs `npm run build` first and skips, saying why, when `tsc`
or the built facade is missing (`--strict` makes that a failure).
