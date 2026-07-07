# tom_som_typescript_v0

Generated typed TomSpecs object model (v0) for TypeScript. This is an editing
facade over the generic `tom_som_typescript_runtime`; regenerate it with
`tom_specs_clitool/bin/generate_som.dart`.

## Building

```bash
npm install   # once, to link the file: runtime dependency into node_modules
npm run build # typechecks + emits dist/
```

### Why `npm run build` also builds the runtime first

The facade imports `SpecDocument` (and friends) from the runtime by its bare
package name:

```ts
import { SpecDocument } from 'tom_som_typescript_runtime';
```

That bare import resolves through the runtime `package.json` `types` field to
`tom_som_typescript_runtime/dist/src/index.d.ts`. The runtime's `dist/` is
**git-ignored**, so on a clean checkout it does not exist yet and a direct
`tsc` on this facade would fail against a missing (or stale) runtime `dist/`.
The committed source is always correct — this is purely build-artifact
staleness (CS4-D6).

To make the dependency explicit and impossible to trip over, this package has a
`prebuild` script that builds the runtime `dist/` first:

```json
"scripts": {
  "prebuild": "npm --prefix ../tom_som_typescript_runtime run build",
  "build": "tsc"
}
```

`prebuild` runs automatically before `build` (npm lifecycle), so
`npm run build` on a fresh checkout builds the runtime, then the facade — no
manual pre-step. If you invoke `tsc` directly instead of `npm run build`, build
the runtime first: `npm --prefix ../tom_som_typescript_runtime run build`.
