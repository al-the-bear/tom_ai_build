# Changelog

## 0.2.0

14 files, +574/-201 since 0.1.0. Two defects fixed at their source, both found
by `tom_doc_specs` disagreeing with what this package produced.

- **Section ids and schema headers are read the way the format defines them**,
  not the way the parser happened to. A document whose id or `<!-- docspec: -->`
  header was written in a legal-but-unexercised form parsed into a tree that
  validated differently from the same document written the other way.
- The markdown parser, the section model and the document/folder models moved
  with it, and the test suite grew to hold the corrected behaviour.
- The package is documented, and its README is the parser's own reference.

## 0.1.0

- Initial development release (pub.dev 0.x channel, BSD-3-Clause): markdown →
  structured document tree parser with section extraction, the `doc_scanner`
  CLI, and the JSON export consumed by `tom_doc_specs`.
