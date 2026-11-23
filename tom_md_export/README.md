# tom_md_export

Exports Markdown that carries the **reading notation** — fenced divs, bracketed
spans and the citation shapes of the DocSpecs specification's *Reading
Notation* — to **PDF through Typst** and to **HTML through the MD Browser's own
renderer**. It is general Markdown: anything written in CommonMark with GFM
tables exports, and the notation is styled where it appears. In TomSpecs its
input is a readable rendition written by `tomspecs :spec-readable`; the export
reads it as it stands and adds nothing, so what a reader gets is decided by the
switches the rendition was made with (`-drop:all --heading-divs` for
stakeholders, every kind kept for authors).

The package is owned by the tom_specs quest and is not a member of the
TomSpecs release set (`publish_to: none`).

## The export of a TomSpecs document

Two commands — the readable rendition, then its export:

```text
tomspecs :spec-readable <doc>.tomspecs.yaml <spec-root>/exports/<doc>.readable.md -drop:all --heading-divs
dart run tom_md_export:md_export <spec-root>/exports/<doc>.readable.md -o <spec-root>/exports/<doc>.pdf
dart run tom_md_export:md_export <spec-root>/exports/<doc>.readable.md -o <spec-root>/exports/<doc>.html
```

An export is written where the caller names it. The documented place is
`<spec-root>/exports/`, which the project gitignores: an export is rebuilt from
the document of record whenever it is needed (the readable header names the
source and its commit), and the user decides which exports to archive. The
same sequence is in `tom_specs_clitool/doc/process_checks.md`.

**How long it takes** (mbp, 2026-11-23): Tom UAM's Information Model, about
146,000 lines readable, 22 seconds to PDF and 14 seconds to HTML; its
Requirements Specification, about 32,000 lines, 6 seconds and 1 second. The
long-document test holds them to about four times that.

## What it renders

| Markdown | In the PDF | In the HTML |
| --- | --- | --- |
| Headings `#` … `######` and the styled heading divs of a readable rendition (`<div class="heading7">…</div>`, any depth) | Typst headings of that depth; the heading's anchor `<a id="ID">` becomes its label | headings; the heading divs as they stand |
| Paragraphs, *emphasis*, **strong**, `code`, hard breaks | as written; every character Typst would read as syntax is escaped | as written |
| Links | `#ID`, and `<document>#ID` where the document is this one (its own name, or the `of=` of its readable header as `.tomspecs.md` / `.readable.md`), jump to the label when the document defines it once; other links are URL links | links to the document itself become `#ID`; others stay |
| `<a id="ID"></a>` in text and table cells | a link target | an anchor |
| Bullet and ordered lists, nested; block quotes; thematic breaks | lists, quotes, a rule | the same |
| Fenced code, Mermaid included | a code block | a code block (`language-mermaid`), not a diagram |
| GFM tables — form, record and section tables | Typst tables: short columns take their width, long ones share the rest, cells wrap and hyphenate, the header repeats across pages; 9pt, a wide table (5 columns or more) 7.5pt | tables scrolling sideways when too wide; a wide table (5 columns or more) in a smaller font |
| Citation shapes `(-> ids)`, `(<- source)`, `(<~ source)` | small and muted | small and muted, the relation on hover, a source path linked |
| Divs of the kinds `provenance`, `trace`, `editorial`, `aside`, `rejected` | smaller, muted, marked with the kind (`rejected` framed) | a collapsed `<details>` naming the kind with a preview |
| Spans of those kinds | smaller and muted | smaller and muted |
| `refs`, `records` | compact links, the record table | the same, never collapsed |
| A kind it does not know | its content, plainly (RN-5) | its content, plainly |
| Review annotations, when the rendition keeps them | their blocks as quotes, their marks as text | the same |

The PDF opens with an outline of three heading levels. The HTML page is
standalone: one file, its stylesheet inside, no script — a collapsed kind opens
with the browser's own `<details>`.

## Usage

```text
dart run tom_md_export:md_export <in.md> [-o <out.pdf|out.html>] [--format pdf|html]
    [--kind-styles=<file>] [--kind-css=<file>] [--no-kind-styles] [--no-outline]
    [--typst <path>] [--typ-only] [--keep-typ] [--node <path>] [--md-browser <dir>]
```

- `-o` names the output (default: the input with `.pdf`); an `.html` output,
  or `--format html`, selects the HTML export.
- `--kind-styles=<file>` replaces the PDF's built-in kind styles with a Typst
  file defining the three functions the emitter calls: `tm-block(kind, body)`
  for a div, `tm-span(kind, body)` for a span and `tm-cite(kind, arrow, body)`
  for a citation shape (`kind` is `trace` or `provenance`, `arrow` `->`, `<-`
  or `<~`). The page and text setup stays.
- `--kind-css=<file>` replaces the HTML's built-in kinds stylesheet (the
  classes `tm-kind`, `tm-kind-name`, `tm-preview`, `tm-body`, `tm-source`,
  `tm-span`, `tm-cite`, each with `data-kind`).
- `--no-kind-styles` reads the notation as text in either output: fences, spans
  and citations are written as they stand.
- `--typ-only` writes the Typst source (`<out>.typ`) and compiles nothing;
  `--keep-typ` keeps it beside the PDF. When Typst fails, the source is kept
  and Typst's message reported.

Exit codes: `0` written, `1` Typst, Node or the MD Browser failed or was not
found, `2` a usage error.

From Dart, `markdownToTypst(markdown)` returns the Typst source,
`exportMarkdownFile(input, output: …)` writes the PDF and
`exportMarkdownFileToHtml(input, exporter: …)` the HTML page;
`MarkdownReader`, `TypstEmitter` and `HtmlExporter` are exported for callers
of their own.

## The HTML export: the MD Browser's renderer, in place

The VS Code extension's MD Browser renders Markdown with
[marked](https://github.com/markedjs/marked) (MIT) and the notation's
extensions, whose scanning — fences, spans, citation shapes and the kind table
— is `media/markdownBrowser/blocks.js`. The HTML export runs that file and the
extension's own `marked` in Node, **loaded from the extension's checkout, never
copied**, so a stakeholder's page is tokenised exactly as the reviewer's view.
Only the HTML of the kinds is the export's: a collapsed kind is a `<details>`
element, a compact kind its content.

It needs:

- **Node** — `--node <path>`, else `node` on `PATH`, `$NVM_BIN/node`, the
  newest `~/.nvm/versions/node/*/bin/node`, or Homebrew's;
- **the extension's checkout** with its `node_modules` installed (`npm install`
  in `tom_ai/vscode/tom_vscode_extension`) — `--md-browser <dir>`, else
  `$TOM_VSCODE_EXTENSION`, else `tom_ai/vscode/tom_vscode_extension` found from
  this package or from the working directory upwards.

## Typst: the tool, its licence, getting the binary

[Typst](https://github.com/typst/typst) is a typesetting language and its
compiler, written in Rust and licensed **Apache-2.0** — a permissive licence,
so using and modifying it leaves this package's own licence untouched. It is
one binary, and the export only calls it (`typst compile`); nothing of it is
linked or vendored.

`md_export` looks for it, in this order:

1. `--typst <path>`;
2. the binaries layer: `$TOM_BINARY_PATH/<platform>/typst` (`darwin-arm64`,
   `linux-x64`, `win32-x64`, …);
3. `typst` on `PATH`.

To get it:

- macOS or Linux with Homebrew: `brew install typst`;
- any platform: a release archive from
  [github.com/typst/typst/releases](https://github.com/typst/typst/releases),
  its `typst` binary put on `PATH` (or passed with `--typst`);
- with Rust: `cargo install --locked typst-cli`.

Tested with Typst 0.15.1.

## Tests

`dart test` covers each construct in both outputs, the edge cases of a long
document, wide record tables, kept and unknown kinds, kept review annotations
and Mermaid blocks. The cases that compile a PDF need Typst, the HTML cases
Node and the extension's checkout, and the long-document test Tom UAM's
checkout beside the workspace and `tom_specs_clitool`; each is skipped where
its tool is missing.

## Licence

BSD 3-Clause; see [LICENSE](LICENSE).
