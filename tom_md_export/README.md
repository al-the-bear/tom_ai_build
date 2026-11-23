# tom_md_export

Exports Markdown that carries the **reading notation** — fenced divs, bracketed
spans and the citation shapes of the DocSpecs specification's *Reading
Notation* — to **PDF through Typst**. It is general Markdown: anything written
in CommonMark with GFM tables exports, and the notation is styled where it
appears. In TomSpecs its input is a readable rendition written by
`tomspecs :spec-readable`; the export never strips anything itself, so what a
reader gets is decided by the switches the rendition was made with
(`-drop:all --heading-divs` for stakeholders, every kind kept for authors).

The package is owned by the tom_specs quest and is not a member of the
TomSpecs release set (`publish_to: none`).

## What it renders

| Markdown | In the PDF |
| --- | --- |
| Headings `#` … `######` and the styled heading divs of a readable rendition (`<div class="heading7">…</div>`, any depth) | Typst headings of that depth; the heading's anchor `<a id="ID">` becomes its label |
| Paragraphs, *emphasis*, **strong**, `code`, hard breaks | as written; every character Typst would read as syntax is escaped |
| Links | `#ID`, and `<document>#ID` where the document is this one (its own name, or the `of=` of its readable header as `.tomspecs.md` / `.readable.md`), jump to the label when the document defines it once; other links are URL links |
| `<a id="ID"></a>` in text and table cells | a link target |
| Bullet and ordered lists, nested; block quotes; fenced code (Mermaid included, shown as code); thematic breaks | lists, quotes, code blocks, a rule |
| GFM tables — form, record and section tables | Typst tables; short columns take their width, long ones share the rest, cells wrap and hyphenate, the header repeats across pages |
| Citation shapes `(-> ids)`, `(<- source)`, `(<~ source)` | small and muted, as the MD Browser shows them |
| Divs and spans of the kinds `provenance`, `trace`, `editorial`, `aside` | smaller, muted, a block marked with its kind |
| `refs`, `records`, `rejected` | compact links, the record table, a framed block |
| A kind it does not know | its content, plainly (RN-5) |
| Review annotations, when the rendition keeps them | their blocks as quotes, their marks as text |

The PDF opens with an outline of three heading levels.

## Usage

```text
dart run tom_md_export:md_export <in.md> [-o <out.pdf>]
    [--kind-styles=<file>] [--no-kind-styles] [--no-outline]
    [--typst <path>] [--typ-only] [--keep-typ]
```

- `-o` names the PDF (default: the input with `.pdf`).
- `--kind-styles=<file>` replaces the built-in kind styles with a Typst file
  defining the three functions the emitter calls:
  `tm-block(kind, body)` for a div, `tm-span(kind, body)` for a span and
  `tm-cite(kind, arrow, body)` for a citation shape (`kind` is `trace` or
  `provenance`, `arrow` `->`, `<-` or `<~`). The page and text setup stays.
- `--no-kind-styles` reads the notation as text: fences, spans and citations
  are written as they stand.
- `--typ-only` writes the Typst source (`<out>.typ`) and compiles nothing;
  `--keep-typ` keeps it beside the PDF. When Typst fails, the source is kept
  and Typst's message reported.

Exit codes: `0` written, `1` Typst failed or was not found, `2` a usage error.

The stakeholder export of a TomSpecs document is two commands:

```text
tomspecs :spec-readable <doc>.tomspecs.yaml <spec-root>/exports/<doc>.readable.md -drop:all --heading-divs
dart run tom_md_export:md_export <spec-root>/exports/<doc>.readable.md
```

From Dart, `markdownToTypst(markdown)` returns the Typst source and
`exportMarkdownFile(input, output: …)` writes the PDF; `MarkdownReader` and
`TypstEmitter` are exported for callers holding a tree of their own.

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

Tested with Typst 0.15.1. The tests that compile a PDF are skipped on a host
without `typst`; the rest run everywhere.

## Licence

BSD 3-Clause; see [LICENSE](LICENSE).
