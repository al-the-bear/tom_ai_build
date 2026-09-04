# Integrating tom_som_javascript_runtime

`tom_som_javascript_runtime` is the generic, value-free TomSpecs object-model
runtime for JavaScript (Node.js). It has **zero external dependencies** and is
versioned to the TomSpecs **model version** — the same version the typed facade
`tom_som_javascript_v0` reports. Pin both to that version so your document reads
and writes match the model the facade was generated from.

Most projects depend on the typed facade `tom_som_javascript_v0` (which pulls in
this runtime) rather than on the runtime directly. Depend on the runtime alone
only when you drive the generic API by section path.

## Quick start

```bash
npm install tom_som_javascript_runtime
```

```javascript
const { SpecDocument } = require('tom_som_javascript_runtime');

const doc = new SpecDocument();
doc.setContent('SBP/content', 'A unifying order platform.');
console.log(doc.content('SBP/content'));
```

## Dependency routes

### From npm

Add the runtime as a dependency:

```bash
npm install tom_som_javascript_runtime
```

or pin it in your `package.json`:

```json
"dependencies": {
  "tom_som_javascript_runtime": "^1.0.0"
}
```

### Git dependency

npm cannot install a sub-directory of a git repository directly, and the
runtime lives in a sub-directory of the mono-repo — so clone first, then
install by path:

```bash
git clone https://github.com/al-the-bear/tom_ai_build.git
npm install ./tom_ai_build/tom_som_javascript_runtime
```

### Path / link (monorepo / vendored)

When the SOM projects sit alongside your code, link the runtime directly:

```bash
npm install ../tom_som_javascript_runtime
```

## Pinning the version

`tom_som_javascript_runtime` and `tom_som_javascript_v0` both carry the TomSpecs
model version. When you upgrade the model, regenerate the facade and move both to
the new matching version so the runtime, the facade, and your stored documents
stay in step. The runtime is hand-authored (never regenerated); only its version
is realigned to the model version by `generate_som.dart`.

## Building from source

The runtime is plain CommonJS with no build step. Verify it and dry-run the
package from the project directory:

```bash
node tests/conformance_runner.js   # or: ./run_conformance.sh, or: node --test
npm pack --dry-run
```

`npm pack --dry-run` lists exactly what a published tarball would contain (the
`tom_som_runtime/` module plus the docs and license).
