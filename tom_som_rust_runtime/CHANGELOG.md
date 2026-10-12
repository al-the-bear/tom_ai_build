# Changelog

## 1.3.3

- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.0.0

- Generic TomSpecs object-model runtime for Rust: section-path grammar, meta-data
  model loader, reflection/resolution, sparse document, validator, and the
  YAML/Markdown codecs, plus a hand-rolled JSON reader/encoder.
- Zero external dependencies (Rust standard library only — no `serde` /
  `serde_yaml` / `regex`); validated against the shared language-agnostic
  conformance corpus.
- Packaged as a Cargo crate `tom_som_rust_runtime` with `publish = false`
  (proprietary); `cargo package --no-verify` is the packaging check.
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its `Cargo.toml` version is realigned by
  `tom_specs_clitool/bin/generate_som.dart`.
