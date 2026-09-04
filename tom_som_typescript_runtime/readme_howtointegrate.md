# Integrating tom_som_typescript_runtime

`tom_som_typescript_runtime` is the generic, value-free TomSpecs object-model
runtime for TypeScript (Node.js). It has **zero external runtime dependencies**
(`typescript` and `@types/node` are dev-only) and is versioned to the TomSpecs
**model version** — the same version the typed facade `tom_som_typescript_v0`
reports. Pin both to that version so your document reads and writes match the
model the facade was generated from.

Most projects depend on the typed facade `tom_som_typescript_v0` (which pulls in
this runtime) rather than on the runtime directly. Depend on the runtime alone
only when you drive the generic API by section path.

Both packages ship compiled `dist/` — `*.js` (CommonJS) plus `*.d.ts`
declarations — so consumers get JavaScript to run and TypeScript types to check
against without compiling the SOM sources themselves.

## Quick start

```bash
npm install tom_som_typescript_runtime
```

```typescript
import { SpecDocument } from 'tom_som_typescript_runtime';

const doc = new SpecDocument();
doc.setContent('SBP/content', 'A unifying order platform.');
console.log(doc.content('SBP/content'));
```

## Dependency routes

### From npm

Add the runtime as a dependency:

```bash
npm install tom_som_typescript_runtime
```

or pin it in your `package.json`:

```json
"dependencies": {
  "tom_som_typescript_runtime": "^1.0.0"
}
```

### Git dependency

npm cannot install a sub-directory of a git repository directly, and the
runtime lives in a sub-directory of the mono-repo — so clone first, then
install by path:

```bash
git clone https://github.com/al-the-bear/tom_ai_build.git
npm install ./tom_ai_build/tom_som_typescript_runtime
```

A path install of an in-tree package runs `prepare`/`prepack` (`npm run
build`), so the compiled `dist/` is produced from source on install.

### Path / link (monorepo / vendored)

When the SOM projects sit alongside your code, link the runtime directly:

```bash
npm install ../tom_som_typescript_runtime
```

This is exactly how `tom_som_typescript_v0` consumes the runtime — via a
`file:../tom_som_typescript_runtime` dependency that resolves through
`node_modules`, keeping the generated facade source path-free and golden-stable.

## Pinning the version

`tom_som_typescript_runtime` and `tom_som_typescript_v0` both carry the TomSpecs
model version. When you upgrade the model, regenerate the facade and move both to
the new matching version so the runtime, the facade, and your stored documents
stay in step. The runtime is hand-authored (never regenerated); only its version
is realigned to the model version by `generate_som.dart`.

## Building from source

The runtime compiles with `tsc` (the pinned dev dependency). Build it, run the
conformance corpus, and dry-run the package from the project directory:

```bash
npm install          # brings the pinned tsc + @types/node
npm run build        # tsc → dist/ (compiled *.js + *.d.ts)
npm run conformance  # node dist/tests/conformance_runner.js → "OK: N checks passed"
npm pack --dry-run   # runs prepack (build) and lists the tarball payload
```

`npm pack` triggers `prepack` (`npm run build`) so the shipped `dist/` is always
freshly compiled. `npm pack --dry-run` lists exactly what a published tarball
would contain (the compiled `dist/src/` plus the docs and license).
