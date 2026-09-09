# Changelog

## 0.3.0

36 files, +4235/-2093 since 0.2.0. The schema model and the validator both
moved.

- **Generate and read agree.** Several constructs the schema generator emitted
  were read back differently — or not at all — by the validator; each is fixed
  in the model that both sides share (`doc_spec_schema.dart`,
  `document_structure.dart`, `section_type_def.dart`, `form_type_def.dart`)
  rather than in one side's parser.
- **Skeleton shape is checked**, so a schema that is structurally impossible
  fails when it is written rather than when a document is validated against it.
- The validator suite was rewritten around the corrected model — the bulk of
  the diff — and the `docspecs` CLI moved with it.
- **Publish it with `tom_doc_scanner`.** This release depends on that package's
  0.2.0 section-id and schema-header fixes; the two can no longer be published
  independently without thought.

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
