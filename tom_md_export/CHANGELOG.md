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
