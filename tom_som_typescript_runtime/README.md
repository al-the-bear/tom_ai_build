# tom_som_typescript_runtime

TypeScript (Node.js) port of the **generic TomSpecs object-model runtime** — the
value-free, generated-code-free half of the multi-platform spec model
(`tom_som`). It is a faithful transcription of the Dart reference,
`tom_som_dart_runtime`, and the Python/Java/JavaScript ports.

## How to use

```bash
npm install tom_som_typescript_runtime
```

```typescript
import { SpecDocument } from 'tom_som_typescript_runtime';

const doc = new SpecDocument();
doc.setContent('SBP/content', 'A unifying order platform.');
console.log(doc.content('SBP/content'));
```

Most projects depend on the **typed facade** `tom_som_typescript_v0` (which pulls
in this runtime) rather than on the runtime directly — reach for the runtime
alone only when you drive the generic API by section path. Both packages ship
compiled `dist/` (`*.js` + `*.d.ts`). For the full set of dependency routes
(npm / git / path-link), version pinning, and building from source, see
[readme_howtointegrate.md](readme_howtointegrate.md).

## What it is

The package `tom_som_typescript_runtime` mirrors the eight portable runtime
modules under `src/`:

| Module | Responsibility |
| ------ | -------------- |
| `spec_paths.ts` | The section-path grammar (root / child / list-item segments). |
| `spec_model.ts` | The meta-data loader — the exported class graph (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, …). |
| `spec_reflection.ts` | Value-free enumeration + path resolution (`SpecReflection`, `SpecResolution`, `SpecNodeKind`). |
| `spec_document.ts` | A sparse in-memory document — values keyed by section path. |
| `spec_typed_values.ts` | Parse/format at the store boundary — the one place the text form of an `int` / `double` / `num` / `bool` / enum-name is decided. |
| `spec_editor.ts` | The generic meta-model-driven modification API (`SpecEditor`, YRD7) — typed edits over any path, without a generated facade. |
| `spec_validator.ts` | Validates a document's values against the model. |
| `spec_text_pattern.ts` | The portable pattern subset (`SomTextPattern`) — a hand-written leftmost-first backtracker over UTF-16 code units, so match spans agree with every other runtime (`RegExp` is the ECMAScript grammar, which accepts far more than the subset and would let a pattern that only works here into the corpus). |
| `spec_query.ts` | The lexical/structural query surface (`SpecQueryEngine`, `SpecQuery`, `SpecQueryCursor`) plus the flat tier-1 node projection (`SpecNodeProjection`). |
| `spec_node_creation.ts` | The constrained node-creation gate (`checkAddNode`, `SpecNodeCreator`) — a document may only grow in ways the model permits. |
| `spec_codespecs_extract.ts` | The Phase-4 CodeSpecs specification extract generator (`CodeSpecsExtractor`, `CodeSpecsAreaCatalog`) — per CodeSpecs area, every value `@CodeSpecKind` routes there, verbatim and with provenance. Walks one `@Document` root, resolved at construction from an optional root-type argument (`codespecs_prompt.md` §5). |
| `spec_document_yaml.ts` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown.ts` | Meta-data-driven Markdown import/export codec. |
| `som_facade.ts` | Editing-facade base types (`SomNode`, `SomScalar`, `SomList<T>`) for the generated `tom_som_typescript_v0`. |

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages. The
public API is re-exported from `src/index.ts` (compiled to `dist/src/index.js`
with declarations at `dist/src/index.d.ts`).

## Zero external runtime dependencies

The compiled JavaScript depends only on Node built-ins — no npm packages (no
js-yaml). JSON parsing uses the native `JSON.parse`/`JSON.stringify`; YAML uses a
**hand-rolled, dependency-free** parser (`yaml.ts`, the constrained docspecs
subset, ported from the Java runtime's `Yaml.java`). The only dev dependencies
are the compiler itself (`typescript`, pinned `6.0.3`) and `@types/node`.

## Build + conformance

Correctness is defined by the shared, language-agnostic conformance corpus in
`../tom_som_conformance/corpus`, generated from the Dart reference. The
TypeScript port is validated against the exact same goldens every other port
uses:

```bash
npm install          # brings the pinned tsc + @types/node
npm run build        # tsc → dist/
npm run conformance  # node dist/tests/conformance_runner.js  → "OK: N checks passed"
# or, all-in-one:
npm test             # build + conformance
./run_conformance.sh # install (if needed) + build + conformance
```

The runner reproduces every golden byte-for-byte and exercises the same cases as
the Dart/Python/Java/JavaScript runners: model meta-data load, `state.json`
round-trip, YAML encode/decode, Markdown export/round-trip, the
**Markdown→memory landing** check (the `md.land.*` shared contract — parsing
`expected.md` lands the same memory as the YAML route), reflection resolution,
validation, the imperative operations script, and the **Phase-4 CodeSpecs
extract** tier (routing verdicts, the per-area extracts with their YAML and
Markdown goldens, and the `ROUTE-TOTAL` error cases).

## Consumed by `tom_som_typescript_v0`

The generated typed model imports the facade and runtime types from this package
by its bare name (`import { SomList, SomNode, … } from 'tom_som_typescript_runtime'`).
The generator wires resolution by declaring a relative `file:` dependency on this
package, so both `tsc` (via `dist/src/index.d.ts`) and `node` (via
`dist/src/index.js`) resolve it through `node_modules` — keeping the generated
source path-free and golden-stable. Build this package (`npm run build`) before
compiling the `v0` project.
