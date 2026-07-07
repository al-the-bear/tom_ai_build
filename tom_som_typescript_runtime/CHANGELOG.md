# Changelog

## 1.0.0

- Generic TomSpecs object-model runtime for TypeScript (Node.js): section-path
  grammar, meta-data model loader, reflection/resolution, sparse document,
  validator, and the YAML/Markdown codecs.
- Zero external runtime dependencies (Node built-ins only; `typescript` and
  `@types/node` are dev-only); validated against the shared language-agnostic
  conformance corpus.
- Ships compiled `dist/` (CommonJS `*.js` plus `*.d.ts` declarations); `prepack`
  rebuilds it from source.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its version is realigned by `tom_specs_clitool/bin/generate_som.dart`.
