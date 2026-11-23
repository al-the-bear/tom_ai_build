/// The document tree the Markdown reader builds and the Typst emitter writes:
/// CommonMark's blocks and inlines as far as specifications use them, GFM
/// tables, and the reading notation (DocSpecs *Reading Notation*): fenced divs,
/// bracketed spans and the citation shapes.
library;

/// A block of the document.
sealed class MdBlock {
  const MdBlock();
}

/// An ATX heading (`#` … `######`) or a styled heading div
/// (`<div class="heading7">…</div>`, any depth).
class MdHeading extends MdBlock {
  /// A heading of [level] with [text]; [anchors] are the ids of the
  /// `<a id="…">` anchors it carries, the first being the heading's label.
  const MdHeading(this.level, this.text, {this.anchors = const []});

  /// The depth, 1 for `#`.
  final int level;

  /// The heading's text, its anchors removed.
  final List<MdInline> text;

  /// The ids of the anchors in the heading, in order.
  final List<String> anchors;
}

/// A paragraph.
class MdParagraph extends MdBlock {
  /// A paragraph holding [text].
  const MdParagraph(this.text);

  /// The paragraph's inline content.
  final List<MdInline> text;
}

/// A bullet or ordered list.
class MdList extends MdBlock {
  /// A list of [items]; ordered lists start at [start].
  const MdList(this.items, {this.ordered = false, this.start = 1});

  /// Its items, each a sequence of blocks.
  final List<List<MdBlock>> items;

  /// Whether the list is numbered.
  final bool ordered;

  /// The first number of an ordered list.
  final int start;
}

/// A block quote; a review annotation block (`> **❓ …`) is one too.
class MdQuote extends MdBlock {
  /// A quote holding [blocks].
  const MdQuote(this.blocks);

  /// The quoted blocks.
  final List<MdBlock> blocks;
}

/// A fenced code block.
class MdCode extends MdBlock {
  /// Code [text] in language [language] (empty when the fence names none).
  const MdCode(this.text, {this.language = ''});

  /// The code, its lines joined by `\n`, without the trailing newline.
  final String text;

  /// The info string's first word (`dart`, `mermaid`, …).
  final String language;
}

/// How a table column aligns its cells.
enum MdAlign {
  /// No alignment given.
  none,

  /// `:--`.
  left,

  /// `:-:`.
  center,

  /// `--:`.
  right,
}

/// A GFM table — a form, record or section table of a TomSpecs rendition,
/// or any table written in content.
class MdTable extends MdBlock {
  /// A table with [header] cells, [rows] and per-column [aligns].
  const MdTable(this.header, this.rows, this.aligns);

  /// The header cells.
  final List<List<MdInline>> header;

  /// The body rows, each padded or cut to the header's width.
  final List<List<List<MdInline>>> rows;

  /// One alignment per column.
  final List<MdAlign> aligns;
}

/// A fenced div of the reading notation (`::: {.kind …}` … `:::`).
class MdDiv extends MdBlock {
  /// A div of [kind] (its first class, null when it has none) around
  /// [blocks]; [attributes] are its other attributes as written.
  const MdDiv(this.kind, this.blocks, {this.attributes = const {}});

  /// The kind: the first class of the attribute braces.
  final String? kind;

  /// The div's content.
  final List<MdBlock> blocks;

  /// The `key="value"` attributes (`label`, `source`, …).
  final Map<String, String> attributes;
}

/// A thematic break (`---`).
class MdRule extends MdBlock {
  /// A thematic break.
  const MdRule();
}

/// An inline element.
sealed class MdInline {
  const MdInline();
}

/// Plain text.
class MdText extends MdInline {
  /// The literal [text].
  const MdText(this.text);

  /// The characters, escapes already resolved.
  final String text;
}

/// An inline code span.
class MdCodeSpan extends MdInline {
  /// A code span holding [code].
  const MdCodeSpan(this.code);

  /// The code, literal.
  final String code;
}

/// Emphasis (`*…*`, `_…_`).
class MdEmphasis extends MdInline {
  /// Emphasised [children].
  const MdEmphasis(this.children);

  /// The emphasised content.
  final List<MdInline> children;
}

/// Strong emphasis (`**…**`, `__…__`).
class MdStrong extends MdInline {
  /// Strongly emphasised [children].
  const MdStrong(this.children);

  /// The emphasised content.
  final List<MdInline> children;
}

/// A link `[text](url)`.
class MdLink extends MdInline {
  /// A link to [url] showing [children].
  const MdLink(this.url, this.children);

  /// The destination as written.
  final String url;

  /// The link text.
  final List<MdInline> children;
}

/// A bracketed span of the reading notation, `[text]{.kind}`.
class MdSpan extends MdInline {
  /// A span of [kind] (null without a class) around [children].
  const MdSpan(this.kind, this.children, {this.attributes = const {}});

  /// The span's first class.
  final String? kind;

  /// The span's content.
  final List<MdInline> children;

  /// The `key="value"` attributes.
  final Map<String, String> attributes;
}

/// The three citation shapes of the reading notation.
enum MdCitationShape {
  /// `(-> ids)`, backed by: kind `trace`.
  backedBy('->', 'trace'),

  /// `(<- source)`, taken from: kind `provenance`.
  takenFrom('<-', 'provenance'),

  /// `(<~ source)`, extrapolated from: kind `provenance`.
  extrapolatedFrom('<~', 'provenance');

  const MdCitationShape(this.arrow, this.kind);

  /// The arrow as written.
  final String arrow;

  /// The kind the shape belongs to.
  final String kind;
}

/// A citation shape, `(-> C2.1)`, `(<- notes.md)`, `(<~ notes.md)`.
class MdCitation extends MdInline {
  /// A citation of [shape] holding [content].
  const MdCitation(this.shape, this.content);

  /// Which of the three shapes.
  final MdCitationShape shape;

  /// The ids or the source, as written.
  final String content;
}

/// An HTML anchor, `<a id="X"></a>` — a link target.
class MdAnchor extends MdInline {
  /// The anchor with [id].
  const MdAnchor(this.id);

  /// The anchor's id.
  final String id;
}

/// A hard line break.
class MdLineBreak extends MdInline {
  /// A hard line break.
  const MdLineBreak();
}

/// The plain text of [inlines], for measuring and for labels.
String mdPlainText(List<MdInline> inlines) {
  final b = StringBuffer();
  void walk(List<MdInline> xs) {
    for (final x in xs) {
      switch (x) {
        case MdText(:final text):
          b.write(text);
        case MdCodeSpan(:final code):
          b.write(code);
        case MdEmphasis(:final children) ||
            MdStrong(:final children) ||
            MdLink(:final children) ||
            MdSpan(:final children):
          walk(children);
        case MdCitation(:final shape, :final content):
          b.write('(${shape.arrow} $content)');
        case MdAnchor():
          break;
        case MdLineBreak():
          b.write(' ');
      }
    }
  }

  walk(inlines);
  return b.toString();
}
