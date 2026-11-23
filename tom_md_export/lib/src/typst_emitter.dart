/// Writes the Markdown tree as Typst markup.
///
/// Text is written in markup with every character Typst gives a meaning
/// escaped, so nothing in a specification turns into Typst syntax; every
/// construct is an embedded function call ended by `;`, so the text that
/// follows can never continue it. Headings and anchors become labels, and a
/// link to an anchor of the same document jumps there. The reading notation
/// calls the three kind functions (`tm-block`, `tm-span`, `tm-cite`) the kind
/// styles define.
library;

import 'kind_styles.dart';
import 'md_nodes.dart';

/// What the emitter writes besides the content.
class TypstOptions {
  /// Options; see the fields.
  const TypstOptions({
    this.kindStyles = builtInKindStyles,
    this.notation = true,
    this.outline = true,
    this.documentNames = const {},
  });

  /// The Typst source defining `tm-block`, `tm-span` and `tm-cite`.
  final String kindStyles;

  /// Whether the notation's divs, spans and citations are styled; false
  /// writes them as their content (the reader was then told not to read
  /// them, so they arrive as text).
  final bool notation;

  /// Whether an outline (table of contents, three levels) opens the PDF.
  final bool outline;

  /// The file names under which this document is linked to (its own name,
  /// its `.tomspecs.md` name): a link `<name>#ID` with one of them jumps to
  /// the label `ID` like `#ID`.
  final Set<String> documentNames;
}

/// Writes [MdBlock]s as a Typst document.
class TypstEmitter {
  /// An emitter with [options].
  TypstEmitter([this.options = const TypstOptions()]);

  /// What is written besides the content.
  final TypstOptions options;

  /// The labels defined exactly once: only these are linked and labelled,
  /// because Typst refuses a link to a label that is missing or doubled.
  Set<String> _labels = const {};

  static final _labelShape = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_\-:.]*$');

  /// The Typst document for [blocks].
  String emit(List<MdBlock> blocks) {
    _labels = _uniqueLabels(blocks);
    final b = StringBuffer()
      ..writeln('// Written by tom_md_export.')
      ..write(documentSetup)
      ..writeln(options.kindStyles);
    if (options.outline) {
      b.writeln('#outline(depth: 3);');
      b.writeln('#pagebreak(weak: true);');
    }
    b.writeln();
    _blocks(blocks, b);
    return b.toString();
  }

  // --------------------------------------------------------------------------
  // Labels
  // --------------------------------------------------------------------------

  Set<String> _uniqueLabels(List<MdBlock> blocks) {
    final counts = <String, int>{};
    void count(String id) => counts[id] = (counts[id] ?? 0) + 1;
    void inlines(List<MdInline> xs) {
      for (final x in xs) {
        switch (x) {
          case MdAnchor(:final id):
            count(id);
          case MdEmphasis(:final children) ||
              MdStrong(:final children) ||
              MdLink(:final children) ||
              MdSpan(:final children):
            inlines(children);
          default:
            break;
        }
      }
    }

    void walk(List<MdBlock> bs) {
      for (final bl in bs) {
        switch (bl) {
          case MdHeading(:final anchors, :final text):
            anchors.forEach(count);
            inlines(text);
          case MdParagraph(:final text):
            inlines(text);
          case MdList(:final items):
            items.forEach(walk);
          case MdQuote(:final blocks) || MdDiv(:final blocks):
            walk(blocks);
          case MdTable(:final header, :final rows):
            header.forEach(inlines);
            for (final r in rows) {
              r.forEach(inlines);
            }
          case MdCode() || MdRule():
            break;
        }
      }
    }

    walk(blocks);
    return {
      for (final e in counts.entries)
        if (e.value == 1 && _labelShape.hasMatch(e.key)) e.key,
    };
  }

  // --------------------------------------------------------------------------
  // Blocks
  // --------------------------------------------------------------------------

  void _blocks(List<MdBlock> blocks, StringBuffer b) {
    for (final block in blocks) {
      _block(block, b);
      b.writeln();
    }
  }

  void _block(MdBlock block, StringBuffer b) {
    switch (block) {
      case MdHeading(:final level, :final text, :final anchors):
        b.write('${'=' * level} ');
        b.write(_inlines(text));
        final labelled = anchors.where(_labels.contains).toList();
        if (labelled.isNotEmpty) b.write(' <${labelled.first}>');
        b.writeln();
        for (final extra in labelled.skip(1)) {
          b.writeln('#metadata(none) <$extra>');
        }
      case MdParagraph(:final text):
        b.writeln(_inlines(text));
      case MdList(:final items, :final ordered, :final start):
        b.write(ordered ? '#enum(start: $start, ' : '#list(');
        b.write('tight: ${_tight(items)}');
        for (final item in items) {
          b.write(', [');
          final inner = StringBuffer();
          _blocks(item, inner);
          b.write(inner.toString().trimRight());
          b.write(']');
        }
        b.writeln(');');
      case MdQuote(:final blocks):
        b.write('#quote(block: true)[');
        final inner = StringBuffer();
        _blocks(blocks, inner);
        b.write(inner.toString().trimRight());
        b.writeln('];');
      case MdCode(:final text, :final language):
        b.write('#raw(block: true, ');
        if (language.isNotEmpty) b.write('lang: ${_string(language)}, ');
        b.writeln('${_string(text)});');
      case MdTable():
        _table(block, b);
      case MdDiv(:final kind, :final blocks):
        final inner = StringBuffer();
        _blocks(blocks, inner);
        if (options.notation && kind != null && knownKinds.contains(kind)) {
          b.write('#tm-block(${_string(kind)}, [');
          b.write(inner.toString().trimRight());
          b.writeln(']);');
        } else {
          b.write(inner.toString());
        }
      case MdRule():
        b.writeln('#line(length: 100%, stroke: 0.5pt + luma(180));');
    }
  }

  /// A list is tight when every item is a single paragraph or less.
  static bool _tight(List<List<MdBlock>> items) =>
      items.every((i) => i.length <= 1 || (i.length == 2 && i[1] is MdList));

  void _table(MdTable t, StringBuffer b) {
    final n = t.header.length;
    final lengths = List<int>.filled(n, 0);
    final totals = List<int>.filled(n, 0);
    for (final row in [t.header, ...t.rows]) {
      for (var c = 0; c < n; c++) {
        final l = mdPlainText(row[c]).length;
        if (l > lengths[c]) lengths[c] = l;
        totals[c] += l;
      }
    }
    final rows = t.rows.length + 1;
    // Short columns take their width, long ones share the rest by their
    // average length, so a wide record table wraps instead of running off
    // the page.
    final columns = [
      for (var c = 0; c < n; c++)
        lengths[c] <= 24
            ? 'auto'
            : '${(totals[c] / rows / 12).clamp(1, 8).round()}fr',
    ];
    if (!columns.any((c) => c.endsWith('fr')) && n > 0) {
      columns[n - 1] = '1fr';
    }
    final aligns = [
      for (final a in t.aligns)
        switch (a) {
          MdAlign.center => 'center',
          MdAlign.right => 'right',
          _ => 'left',
        },
    ];
    final size = n >= wideTableColumns ? '7.5pt' : '9pt';
    b.writeln('#[#set text(size: $size);');
    b.writeln('#table(');
    b.writeln('  columns: (${columns.join(', ')}${n == 1 ? ',' : ''}),');
    b.writeln('  align: (${aligns.join(', ')}${n == 1 ? ',' : ''}),');
    b.writeln(
      '  table.header(${[for (final h in t.header) '[${_inlines(h)}]'].join(', ')}),',
    );
    for (final row in t.rows) {
      b.writeln('  ${[for (final c in row) '[${_inlines(c)}]'].join(', ')},');
    }
    b.writeln(')];');
  }

  // --------------------------------------------------------------------------
  // Inlines
  // --------------------------------------------------------------------------

  String _inlines(List<MdInline> inlines) {
    final b = StringBuffer();
    for (final x in inlines) {
      switch (x) {
        case MdText(:final text):
          b.write(escapeMarkup(text));
        case MdCodeSpan(:final code):
          b.write('#raw(${_string(code)});');
        case MdEmphasis(:final children):
          b.write('#emph[${_inlines(children)}];');
        case MdStrong(:final children):
          b.write('#strong[${_inlines(children)}];');
        case MdLink(:final url, :final children):
          b.write('#link(${_target(url)})[${_inlines(children)}];');
        case MdSpan(:final kind, :final children):
          final body = _inlines(children);
          if (options.notation && kind != null && knownKinds.contains(kind)) {
            b.write('#tm-span(${_string(kind)}, [$body]);');
          } else {
            b.write(body);
          }
        case MdCitation(:final shape, :final content):
          final body = escapeMarkup(content);
          if (options.notation) {
            b.write(
              '#tm-cite(${_string(shape.kind)}, ${_string(shape.arrow)}, [$body]);',
            );
          } else {
            b.write(
              escapeMarkup('(${shape.arrow} ') + body + escapeMarkup(')'),
            );
          }
        case MdAnchor(:final id):
          if (_labels.contains(id)) b.write('#metadata(none) <$id>');
        case MdLineBreak():
          b.write('#linebreak();');
      }
    }
    return b.toString();
  }

  /// The link target: a label of this document when the URL's fragment names
  /// one and its file part is empty or one of the document's names, else the
  /// URL as written.
  String _target(String url) {
    final hash = url.indexOf('#');
    if (hash >= 0) {
      final file = url.substring(0, hash);
      final id = url.substring(hash + 1);
      final self =
          file.isEmpty ||
          options.documentNames.contains(file) ||
          options.documentNames.contains(file.split('/').last);
      if (self && _labels.contains(id)) return '<$id>';
    }
    return _string(url);
  }

  /// [s] as a Typst string literal.
  static String _string(String s) {
    final b = StringBuffer('"');
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      switch (ch) {
        case r'\':
          b.write(r'\\');
        case '"':
          b.write(r'\"');
        case '\n':
          b.write(r'\n');
        case '\r':
          b.write(r'\r');
        case '\t':
          b.write(r'\t');
        default:
          b.write(ch);
      }
    }
    b.write('"');
    return b.toString();
  }
}

/// The characters Typst markup gives a meaning, escaped with a backslash.
const String _markupSpecials =
    r'\*_`$#[]<>@~/=-+.:"'
    "'";

/// [text] as Typst markup that shows exactly these characters: every
/// character markup gives a meaning — emphasis, code, math, embedded code,
/// labels and references, non-breaking spaces, comments, headings, lists,
/// dashes, the ellipsis, smart quotes and the `term:` of a term list — is
/// escaped.
String escapeMarkup(String text) {
  final b = StringBuffer();
  for (final r in text.runes) {
    final ch = String.fromCharCode(r);
    if (_markupSpecials.contains(ch)) b.write(r'\');
    b.write(ch);
  }
  return b.toString();
}
