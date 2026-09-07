# Changelog

## 0.2.0

- **A document's schema declaration is now read in both documented forms.**
  `DocSpecs.scanDocument` reads the standalone `<!-- docspec: <id>/<version> -->`
  comment — what `DocSpecsSkeletonGenerator` emits and what the workspace
  convention documents — as well as the older `schema=<id>` inside the first
  headline. It looks in the document **preamble**: everything above the second
  heading, so a `<!-- docspec: … -->` quoted inside a section's body is not
  mistaken for the document's own declaration. Whichever form appears first
  wins.

  Previously only the in-headline form was read, so a generated skeleton — and
  every document written to the workspace convention, including this package's
  own fixtures — scanned as schemaless. **That was a silent failure, not a loud
  one**: a schemaless scan records no validation errors, so `isValid` came back
  a vacuous `true` and a non-conforming document passed.

- **`SpecDoc.wasValidated`** (new) says whether a schema was actually resolved
  and the validator actually ran. `isValid` can only report that no error was
  *recorded*, and a document nothing checked records none — so the two states
  used to be indistinguishable. Read `wasValidated && isValid` when you mean
  "known to be correct". Serialized in `toJson` / `fromJson`.

- **The `docspecs validate` CLI reports an unvalidated document as `?`**, never
  `✓`, with its own count in the summary and a line saying plainly that
  "0 invalid" does not mean the documents are correct. Exit status is unchanged:
  an undeclared schema is a gap to report, not a failure.

## 0.1.0

- Initial development release (pub.dev 0.x channel, BSD-3-Clause): DocSpecs
  schema validation for structured markdown — typed sections over
  `tom_doc_scanner` document trees, schema resolution from `.docspec-schemas/`
  folders, and the `docspecs` CLI.
