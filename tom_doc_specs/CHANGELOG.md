# Changelog

## 0.4.0

Reads the reading forms of the DocSpecs specification (02b_rdv1, 02b_rdv2),
so the renditions TomSpecs writes read back into the same tree as their
`Fieldname:` / heading form. Requires `tom_doc_scanner` 0.3.0 (styled-div
headings, section anchors, fenced code, `textLineNumber`).

- **Form tables.** `| TomSpecField | Value |` or `| DocSpecsField | Value |`
  (any case) at column 0, one row per field, give a form-formatted section its
  fields beside or instead of `Fieldname:` lines. `\|` is a literal pipe, a
  cell of links reads as the link texts, an empty cell is no value, a table in
  fenced code is content, and a layout header written with one leading space is
  content with the space removed. The first occurrence of a field wins; the
  later one is a `malformedBlock`. Two `Fieldname:` lines of one field keep
  the later one, unreported, as before.
- **`refs` and `records` bodies** in a list container and **section tables**
  (`| Section | TomSpecField | Value |`, also in the document's root body)
  become virtual sections of the tree (`SpecSection.isVirtual`, their values in
  `SpecSection.virtualValues`); the div or table is removed from the
  container's text, so `max-text-length: 0` holds.
- **Findings with a code.** `ValidationError.code` names the finding as the
  specification does: `malformedBlock` (broken table, misplaced or unclosed
  list-body div, field given twice), `unknownField` (a row or records column
  naming no field), `unknownSection` (a section-table row naming no child),
  and the fenced-div findings `unclosedDiv`, `strayClosingFence`,
  `rejectedBlock` (category `notation`).
- **Lines.** A form field's pattern finding points at the row or
  `Fieldname:` line that gave the value (`SpecSection.fieldLine`).
- **Prefix matching follows the specification**: the id with every run of
  non-alphanumeric characters replaced by `_` (`D00-OVR` matches prefix
  `D00_OVR`); the raw id still matches, and the match still ignores case
  (`DocSpecSchema.resolveSectionType`, `DocSpecSchema.prefixMatches`).
- **Fix:** a section with no children at all now owes its subsection
  `min-count`s; it used to pass.
- Text checks count the values a section was given as its virtual body lines
  (`SpecSection.contentText`).

## 0.3.1

- **Review annotations stay out of form fields** (SOM §11.9.4). A comment
  block (`> ⬆️ …`) or a question block (`> **❓ …`) between or below a form's
  fields ends the field it follows and is neither read into a value nor moved
  into the preamble. `SpecSection.misplacedAnnotations` lists such blocks, and
  the validator reports each one as a `format` error. Blocks in the preamble
  and inline marks inside a value are unaffected.
- `schema-test-document.json`, a generated test artifact naming one machine's
  paths, is no longer shipped.

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
