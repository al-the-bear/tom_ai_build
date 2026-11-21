# Changelog

## 0.3.0

The heading structure of the DocSpecs specification's reading forms.

- **Styled-div headings.** A line `<div class="heading<N>" …><!--[ID]--> Title</div>`
  with N >= 7 is a heading of level N; its text has `&amp;`, `&lt;`, `&gt;`
  decoded. A `heading6` div, a div whose first attribute is not `class` and a
  div over several lines are text.
- **Section anchors.** A heading's own anchor (`<a id="ID"></a>` naming the
  heading's id) is removed from its title.
- **Fenced code.** No line inside a fenced code block is a heading any more.
- **Nesting.** A headline's parent is the nearest shallower headline before it.
  A skipped level (`####` under `##`) used to vanish from the tree and its text
  ran into the section above; it now nests where it stands. A section's text
  is its own body up to the next headline of any level.
- **`Section.textLineNumber`**: the file line of the first line of the trimmed
  `Section.text` (also on `Document`, in `toJson` / `fromJson`).
- **Breaking:** `DocScannerFactory.createSection` and `createDocument` take
  `int? textLineNumber`; an override has to accept and pass it on.
- `FenceTracker` is exported: feed it lines to know which are fenced code.

## 0.2.1

- Tests: review annotations (SOM §11.9) start no section and are handed to
  the caller verbatim as section text (`review_annotations_test.dart`).

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
