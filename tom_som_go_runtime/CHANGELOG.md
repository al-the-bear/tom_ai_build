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

- Generic TomSpecs object-model runtime for Go: section-path grammar, meta-data
  model loader, reflection/resolution, sparse document, validator, and the
  YAML/Markdown codecs.
- Zero external dependencies (Go standard library only); validated against the
  shared language-agnostic conformance corpus.
- Published under the domain-qualified module path
  `github.com/al-the-bear/tom_ai_build/tom_som_go_runtime`; the version is a VCS
  tag (`vMAJOR.MINOR.PATCH`) mirrored in the in-source `Version` constant
  (`doc.go`).
- The version tracks the TomSpecs model version; the runtime is hand-authored
  and its version is realigned by `tom_specs_clitool/bin/generate_som.dart`.
