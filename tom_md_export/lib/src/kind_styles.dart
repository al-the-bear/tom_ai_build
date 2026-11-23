/// The Typst styles of the export: the document's page and text setup, and
/// the kind styles — the three functions the emitter calls for the reading
/// notation, which `--kind-styles=<file>` replaces.
library;

/// The kinds the export styles. Every other kind is plain content (RN-5: an
/// unknown kind passes through and is shown as its content).
const Set<String> knownKinds = {
  'provenance',
  'trace',
  'editorial',
  'aside',
  'refs',
  'records',
  'rejected',
};

/// A table with this many columns or more is wide: set in a smaller font in
/// the PDF, and marked `tm-wide` (a smaller font) in the HTML.
const int wideTableColumns = 5;

/// The secondary kinds: their text is set smaller and muted.
const Set<String> secondaryKinds = {
  'provenance',
  'trace',
  'editorial',
  'aside',
};

/// The document setup written before the content: the page, the text, the
/// headings, links, tables, code and quotes. A table's font size is the
/// emitter's: 9pt, and 7.5pt for a wide table ([wideTableColumns] columns or
/// more), which wraps rather than running off the page.
const String documentSetup = r'''
#set page(paper: "a4", margin: (x: 2cm, y: 2.2cm), numbering: "1")
#set text(size: 10pt, lang: "en")
#set par(justify: false, leading: 0.6em, spacing: 1em)
#set heading(numbering: none)
#show heading: set block(above: 1.4em, below: 0.7em)
#show heading.where(level: 1): set text(size: 18pt)
#show heading.where(level: 2): set text(size: 14pt)
#show heading.where(level: 3): set text(size: 12pt)
#show heading: it => if it.level > 3 { block(above: 1.2em, below: 0.6em, text(size: 10.5pt, weight: "bold", it.body)) } else { it }
#show link: set text(fill: rgb("#1a5fb4"))
#set table(stroke: 0.5pt + luma(180), inset: (x: 5pt, y: 4pt))
#show table: set text(hyphenate: true)
#show table.cell.where(y: 0): set text(weight: "bold")
#show raw.where(block: true): block.with(fill: luma(246), inset: 7pt, radius: 3pt, width: 100%)
#show raw: set text(size: 8.5pt)
#show quote.where(block: true): block.with(stroke: (left: 2pt + luma(200)), inset: (left: 9pt, y: 3pt))
''';

/// The built-in kind styles: `tm-block(kind, body)` for a fenced div,
/// `tm-span(kind, body)` for a bracketed span and `tm-cite(kind, arrow,
/// body)` for a citation shape. Secondary text is smaller and muted, as the
/// MD Browser shows it; `refs` is compact; `records` is its table; `rejected`
/// is framed. A replacement file defines the same three functions.
const String builtInKindStyles = r'''
#let tm-muted = luma(110)
#let tm-secondary = ("provenance", "trace", "editorial", "aside")
#let tm-block(kind, body) = {
  if kind in tm-secondary {
    block(
      width: 100%,
      inset: (left: 8pt, y: 2pt),
      stroke: (left: 1.5pt + luma(210)),
      text(size: 8.5pt, fill: tm-muted)[#text(weight: "bold", size: 7.5pt, upper(kind)) #h(0.4em) #body],
    )
  } else if kind == "refs" {
    block(width: 100%, text(size: 9pt, body))
  } else if kind == "records" {
    block(width: 100%, body)
  } else if kind == "rejected" {
    block(width: 100%, inset: 6pt, stroke: 0.75pt + rgb("#c01c28"), radius: 3pt, [#text(size: 7.5pt, fill: rgb("#c01c28"), weight: "bold", "REJECTED") #linebreak() #body])
  } else {
    body
  }
}
#let tm-span(kind, body) = {
  if kind in tm-secondary { text(size: 0.85em, fill: tm-muted, body) } else { body }
}
#let tm-cite(kind, arrow, body) = text(size: 0.8em, fill: tm-muted)[(#arrow #body)]
''';

/// The kind functions when the notation is read as text
/// (`--no-kind-styles`): the emitter calls none of them, so they are empty.
const String noKindStyles = '';
