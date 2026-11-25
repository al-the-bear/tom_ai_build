## 0.2.0

- The typst binary is looked for through `tom_basics`' `TomNativeBinaries`
  (the running application's bundle, then `$TOM_BINARY_PATH/<platform>/`),
  then on PATH; `TypstCompiler.platformFolder` is its `platformFolder()`.
- **HTML output** through the MD Browser's renderer: the extension's `marked`
  and `media/markdownBrowser/blocks.js` run in Node from the extension's
  checkout (not copied); a collapsed kind is a `<details>`, a compact kind its
  content, an unknown kind plain; a standalone page with the base style and the
  kinds stylesheet (`--kind-css=<file>` replaces it). `--format pdf|html` (an
  `.html` output selects HTML), `--node`, `--md-browser`.
- **Wide tables** (5 columns or more) are set smaller: 7.5pt in the PDF, the
  class `tm-wide` in the HTML; every PDF table sets its own size.
- **Long documents:** Tom UAM's Information Model (about 146,000 lines readable)
  exports in about 22 seconds to PDF and 14 to HTML; a test holds both
  documents to a stated budget. Links to the document itself are rewritten in a
  link renderer, since marked's `walkTokens` is quadratic on a document that
  long.
- The edge cases of the clean export as tests: wide record tables, kept and
  unknown kinds, kept review annotations, Mermaid blocks.
- The two-command sequence (`tomspecs :spec-readable`, then `md_export`)
  documented here and in `tom_specs_clitool/doc/process_checks.md`.

## 0.1.0

- Markdown with the reading notation to PDF through Typst: `md_export`, a
  `tom_build_base` tool, and `markdownToTypst` / `exportMarkdownFile`.
- Headings at any depth (the readable rendition's heading divs included) with
  their anchors as labels; paragraphs, emphasis, code, links within the
  document as label links; lists, quotes, fenced code, thematic breaks; GFM
  tables; the citation shapes and the kinds' divs and spans styled per kind;
  unknown kinds as content; review annotations as text.
- `--kind-styles=<file>`, `--no-kind-styles`, `--no-outline`, `--typst`,
  `--typ-only`, `--keep-typ`.
