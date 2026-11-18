# Sample — build a specification tool (TypeScript)

**Teaches:** the same as [the Dart sample](../README.md) — reflective access to
the model, generic access to a document, the generated schema, the validation
tiers, and a completeness report built on all of it.
**Phase:** any — tooling.
**Language:** TypeScript (Node), on `tom_som_typescript_v0` and `tom_som_typescript_runtime`.

A port of `../bin/build_a_specification_tool.dart`, over the same fixture.

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

Five numbered sections; every number is the Dart sample's. The text is in this
port's own [`expected_output.txt`](expected_output.txt) — the JavaScript port's
text — because it differs from the Dart sample's in three places, each where the
Dart text names a Dart-only surface:

* the fixture function is `authorFixture` (no leading underscore);
* the annotation display semantics (`kRenderedAnnotations`) are in the Dart
  runtime only — they are what the two Flutter apps share — so this port says
  that instead of counting them;
* the Dart text points at a Dart example (`example/f_sample_hybrid_access.dart`).

`generatedAt` is printed as the snapshot writes it: a JavaScript `Date` holds
milliseconds, and the stamp carries microseconds. The schema comes from
`somDocSpecsSchema('solution-blueprint')` (`tom_som_typescript_v0/schemas`,
which is why `tsconfig.json` resolves modules as `node16`: the subpath is a
package export).
