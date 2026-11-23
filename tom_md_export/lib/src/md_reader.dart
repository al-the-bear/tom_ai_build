/// Reads Markdown with the reading notation into the tree of `md_nodes.dart`.
///
/// It covers what specifications are written in: ATX headings and the styled
/// heading divs of a readable rendition, paragraphs, bullet and ordered lists
/// (nested by indentation), block quotes, fenced code, GFM tables, thematic
/// breaks; inline emphasis, code spans, links, HTML anchors and hard breaks;
/// and the reading notation — fenced divs, bracketed spans and the citation
/// shapes (DocSpecs *Reading Notation*, RN-1 … RN-3). HTML comments are
/// dropped. Review annotations need nothing of their own: their blocks are
/// quotes and their marks text.
library;

import 'md_nodes.dart';

/// Reads Markdown into [MdBlock]s.
class MarkdownReader {
  /// A reader; with [notation] false the reading notation is not recognised
  /// and its fences, spans and citations stay text.
  const MarkdownReader({this.notation = true});

  /// Whether fenced divs, bracketed spans and citation shapes are read.
  final bool notation;

  /// The blocks of [markdown].
  List<MdBlock> parse(String markdown) =>
      _blocks(markdown.replaceAll('\r\n', '\n').split('\n'));

  // --------------------------------------------------------------------------
  // Blocks
  // --------------------------------------------------------------------------

  static final _atx = RegExp(r'^ {0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*$');
  static final _headingDiv = RegExp(
    r'^ {0,3}<div class="heading(\d+)"[^>]*>(.*)</div>\s*$',
  );
  static final _fence = RegExp(r'^( {0,3})(`{3,}|~{3,})\s*([^`\s]*)[^`]*$');
  static final _divOpen = RegExp(
    r'^ {0,3}(:{3,})\s*(\{[^}]*\}|[A-Za-z][\w-]*)\s*$',
  );
  static final _divClose = RegExp(r'^ {0,3}:{3,}\s*$');
  static final _rule = RegExp(r'^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$');
  static final _quote = RegExp(r'^ {0,3}> ?');
  static final _item = RegExp(r'^( {0,3})([-*+]|\d{1,9}[.)])([ \t]+|$)');
  static final _delimiterRow = RegExp(
    r'^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$',
  );
  static final _comment = RegExp(r'^\s*<!--.*-->\s*$');

  List<MdBlock> _blocks(List<String> lines) {
    final out = <MdBlock>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        i++;
        continue;
      }
      // HTML comments (the docspec and readable headers among them).
      if (_comment.hasMatch(line)) {
        i++;
        continue;
      }
      if (line.trimLeft().startsWith('<!--')) {
        while (i < lines.length && !lines[i].contains('-->')) {
          i++;
        }
        i++;
        continue;
      }
      final fence = _fence.firstMatch(line);
      if (fence != null) {
        i = _code(lines, i, fence, out);
        continue;
      }
      if (notation) {
        final div = _divOpen.firstMatch(line);
        if (div != null) {
          i = _div(lines, i, div, out);
          continue;
        }
      }
      final atx = _atx.firstMatch(line);
      if (atx != null) {
        out.add(
          _heading(
            atx.group(1)!.length,
            _trimClosingHashes(atx.group(2) ?? ''),
          ),
        );
        i++;
        continue;
      }
      final hdiv = _headingDiv.firstMatch(line);
      if (hdiv != null) {
        out.add(_heading(int.parse(hdiv.group(1)!), hdiv.group(2)!));
        i++;
        continue;
      }
      if (_rule.hasMatch(line)) {
        out.add(const MdRule());
        i++;
        continue;
      }
      if (_isTableStart(lines, i)) {
        i = _table(lines, i, out);
        continue;
      }
      if (_quote.hasMatch(line)) {
        final body = <String>[];
        while (i < lines.length && _quote.hasMatch(lines[i])) {
          body.add(lines[i].replaceFirst(_quote, ''));
          i++;
        }
        out.add(MdQuote(_blocks(body)));
        continue;
      }
      final item = _item.firstMatch(line);
      if (item != null) {
        i = _list(lines, i, out);
        continue;
      }
      i = _paragraph(lines, i, out);
    }
    return out;
  }

  static String _trimClosingHashes(String text) =>
      text.replaceFirst(RegExp(r'[ \t]+#+[ \t]*$'), '').trim();

  MdHeading _heading(int level, String raw) {
    final inlines = _inlines(raw.trim());
    final anchors = <String>[];
    final text = <MdInline>[];
    for (final x in inlines) {
      if (x is MdAnchor) {
        anchors.add(x.id);
      } else {
        text.add(x);
      }
    }
    // The space the anchor and the id comment leave in front of the title.
    while (text.isNotEmpty && text.first is MdText) {
      final t = (text.first as MdText).text.trimLeft();
      if (t.isEmpty) {
        text.removeAt(0);
      } else {
        text[0] = MdText(t);
        break;
      }
    }
    return MdHeading(level, text, anchors: anchors);
  }

  int _code(List<String> lines, int start, RegExpMatch m, List<MdBlock> out) {
    final indent = m.group(1)!.length;
    final marker = m.group(2)!;
    final body = <String>[];
    var i = start + 1;
    while (i < lines.length) {
      final l = lines[i];
      final t = l.trimLeft();
      if (t.startsWith(marker[0] * marker.length) &&
          t.replaceAll(marker[0], '').trim().isEmpty) {
        i++;
        break;
      }
      body.add(_dedent(l, indent));
      i++;
    }
    out.add(MdCode(body.join('\n'), language: m.group(3) ?? ''));
    return i;
  }

  static String _dedent(String line, int n) {
    var k = 0;
    while (k < n && k < line.length && line[k] == ' ') {
      k++;
    }
    return line.substring(k);
  }

  int _div(List<String> lines, int start, RegExpMatch m, List<MdBlock> out) {
    final (kind, attributes) = _attributes(m.group(2)!);
    final body = <String>[];
    var depth = 1;
    var i = start + 1;
    String? inFence;
    while (i < lines.length) {
      final l = lines[i];
      final f = _fence.firstMatch(l);
      if (inFence != null) {
        if (l.trimLeft().startsWith(inFence)) inFence = null;
      } else if (f != null) {
        inFence = f.group(2)!;
      } else if (_divOpen.hasMatch(l)) {
        depth++;
      } else if (_divClose.hasMatch(l)) {
        depth--;
        if (depth == 0) {
          i++;
          break;
        }
      } else if (depth == 1 && _atx.hasMatch(l)) {
        // An unclosed div closes at the next heading (RN-10).
        break;
      }
      body.add(l);
      i++;
    }
    out.add(MdDiv(kind, _blocks(body), attributes: attributes));
    return i;
  }

  /// The kind and the `key="value"` attributes of an attribute set: braces
  /// (`{.provenance label="x"}`) or a bare kind word (`provenance`).
  static (String?, Map<String, String>) _attributes(String raw) {
    if (!raw.startsWith('{')) return (raw, const {});
    final inner = raw.substring(1, raw.length - 1);
    String? kind;
    final attrs = <String, String>{};
    for (final m in RegExp(
      r'''\.([\w-]+)|#([\w-]+)|([\w-]+)="([^"]*)"''',
    ).allMatches(inner)) {
      if (m.group(1) != null) {
        kind ??= m.group(1);
      } else if (m.group(3) != null) {
        attrs[m.group(3)!] = m.group(4)!;
      }
    }
    return (kind, attrs);
  }

  bool _isTableStart(List<String> lines, int i) =>
      i + 1 < lines.length &&
      lines[i].contains('|') &&
      _delimiterRow.hasMatch(lines[i + 1]) &&
      lines[i + 1].contains('-');

  int _table(List<String> lines, int start, List<MdBlock> out) {
    final header = _cells(lines[start]);
    final aligns = [
      for (final c in _cells(lines[start + 1]))
        switch ((c.startsWith(':'), c.endsWith(':'))) {
          (true, true) => MdAlign.center,
          (true, false) => MdAlign.left,
          (false, true) => MdAlign.right,
          _ => MdAlign.none,
        },
    ];
    final width = header.length;
    while (aligns.length < width) {
      aligns.add(MdAlign.none);
    }
    final rows = <List<List<MdInline>>>[];
    var i = start + 2;
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        lines[i].contains('|')) {
      final cells = _cells(lines[i]);
      rows.add([
        for (var c = 0; c < width; c++)
          _inlines(c < cells.length ? cells[c] : ''),
      ]);
      i++;
    }
    out.add(
      MdTable(
        [for (final h in header) _inlines(h)],
        rows,
        aligns.take(width).toList(),
      ),
    );
    return i;
  }

  /// The cells of a table row: split at `|` outside code spans and not
  /// escaped (`\|` stays in the cell as `|`), the outer pipes dropped.
  static List<String> _cells(String row) {
    var s = row.trim();
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|') && !s.endsWith(r'\|')) {
      s = s.substring(0, s.length - 1);
    }
    final cells = <String>[];
    final b = StringBuffer();
    var inCode = 0;
    for (var k = 0; k < s.length; k++) {
      final ch = s[k];
      if (ch == r'\' && k + 1 < s.length && s[k + 1] == '|') {
        b.write('|');
        k++;
        continue;
      }
      if (ch == '`') {
        var run = 0;
        while (k + run < s.length && s[k + run] == '`') {
          run++;
        }
        inCode = inCode == 0 ? run : (inCode == run ? 0 : inCode);
        b.write('`' * run);
        k += run - 1;
        continue;
      }
      if (ch == '|' && inCode == 0) {
        cells.add(b.toString().trim());
        b.clear();
        continue;
      }
      b.write(ch);
    }
    cells.add(b.toString().trim());
    return cells;
  }

  int _list(List<String> lines, int start, List<MdBlock> out) {
    final first = _item.firstMatch(lines[start])!;
    final ordered = !RegExp(r'^[-*+]$').hasMatch(first.group(2)!);
    final startNumber = ordered
        ? int.parse(first.group(2)!.substring(0, first.group(2)!.length - 1))
        : 1;
    final items = <List<MdBlock>>[];
    var i = start;
    while (i < lines.length) {
      final m = _item.firstMatch(lines[i]);
      if (m == null) break;
      final isOrdered = !RegExp(r'^[-*+]$').hasMatch(m.group(2)!);
      if (isOrdered != ordered) break;
      final contentIndent =
          m.group(1)!.length +
          m.group(2)!.length +
          (m.group(3)!.isEmpty ? 1 : m.group(3)!.length);
      final body = <String>[lines[i].substring(m.end)];
      i++;
      var lastBlank = false;
      while (i < lines.length) {
        final l = lines[i];
        if (l.trim().isEmpty) {
          lastBlank = true;
          body.add('');
          i++;
          continue;
        }
        final indent = l.length - l.trimLeft().length;
        if (indent >= contentIndent) {
          body.add(_dedent(l, contentIndent));
          lastBlank = false;
          i++;
          continue;
        }
        // A lazy continuation line of the item's paragraph.
        if (!lastBlank && !_startsBlock(lines, i)) {
          body.add(l.trimLeft());
          i++;
          continue;
        }
        break;
      }
      while (body.isNotEmpty && body.last.trim().isEmpty) {
        body.removeLast();
      }
      items.add(_blocks(body));
      // A blank line followed by something that is no item ends the list.
      if (i < lines.length && _item.firstMatch(lines[i]) == null) break;
    }
    out.add(MdList(items, ordered: ordered, start: startNumber));
    return i;
  }

  bool _startsBlock(List<String> lines, int i) {
    final l = lines[i];
    return _atx.hasMatch(l) ||
        _headingDiv.hasMatch(l) ||
        _fence.hasMatch(l) ||
        (notation && (_divOpen.hasMatch(l) || _divClose.hasMatch(l))) ||
        _quote.hasMatch(l) ||
        _item.hasMatch(l) ||
        _rule.hasMatch(l) ||
        _isTableStart(lines, i);
  }

  int _paragraph(List<String> lines, int start, List<MdBlock> out) {
    final body = <String>[lines[start]];
    var i = start + 1;
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        !_startsBlock(lines, i)) {
      body.add(lines[i]);
      i++;
    }
    out.add(MdParagraph(_inlines(body.join('\n'))));
    return i;
  }

  // --------------------------------------------------------------------------
  // Inlines
  // --------------------------------------------------------------------------

  static const _punctuation = r'''!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~''';
  static final _anchor = RegExp(
    r'''^<a\s+(?:id|name)\s*=\s*"([^"]*)"\s*(?:/>|>\s*</a>)''',
  );
  static final _autolink = RegExp(r'^<((?:https?|mailto):[^>\s]+)>');

  /// The inlines of [text] (lines joined by `\n`).
  List<MdInline> _inlines(String text) {
    final out = <MdInline>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isEmpty) return;
      out.add(MdText(buf.toString()));
      buf.clear();
    }

    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      // Line ends: a hard break after two spaces or a backslash, else a space.
      if (ch == '\n') {
        final s = buf.toString();
        if (s.endsWith('  ')) {
          buf
            ..clear()
            ..write(s.trimRight());
          flush();
          out.add(const MdLineBreak());
        } else {
          buf.write(' ');
        }
        i++;
        continue;
      }
      if (ch == r'\' && i + 1 < text.length) {
        final next = text[i + 1];
        if (next == '\n') {
          flush();
          out.add(const MdLineBreak());
          i += 2;
          continue;
        }
        if (_punctuation.contains(next)) {
          buf.write(next);
          i += 2;
          continue;
        }
      }
      if (ch == '`') {
        final end = _codeSpanEnd(text, i);
        if (end != null) {
          flush();
          out.add(MdCodeSpan(end.$1));
          i = end.$2;
          continue;
        }
        var run = 0;
        while (i + run < text.length && text[i + run] == '`') {
          run++;
        }
        buf.write('`' * run);
        i += run;
        continue;
      }
      if (ch == '<') {
        final rest = text.substring(i);
        if (rest.startsWith('<!--')) {
          final close = text.indexOf('-->', i + 4);
          if (close >= 0) {
            i = close + 3;
            continue;
          }
        }
        final a = _anchor.firstMatch(rest);
        if (a != null) {
          flush();
          out.add(MdAnchor(a.group(1)!));
          i += a.end;
          continue;
        }
        final auto = _autolink.firstMatch(rest);
        if (auto != null) {
          flush();
          out.add(MdLink(auto.group(1)!, [MdText(auto.group(1)!)]));
          i += auto.end;
          continue;
        }
      }
      if (notation && ch == '(' && i + 3 < text.length) {
        final citation = _citation(text, i);
        if (citation != null) {
          flush();
          out.add(citation.$1);
          i = citation.$2;
          continue;
        }
      }
      if (ch == '[') {
        final bracket = _bracket(text, i);
        if (bracket != null) {
          flush();
          out.add(bracket.$1);
          i = bracket.$2;
          continue;
        }
      }
      if (ch == '*' || ch == '_') {
        final emph = _emphasis(text, i);
        if (emph != null) {
          flush();
          out.add(emph.$1);
          i = emph.$2;
          continue;
        }
        var run = 0;
        while (i + run < text.length && text[i + run] == ch) {
          run++;
        }
        buf.write(ch * run);
        i += run;
        continue;
      }
      buf.write(ch);
      i++;
    }
    flush();
    return out;
  }

  /// A code span opening at [i]: its code and the index after it, or null
  /// when the backtick run does not close.
  static (String, int)? _codeSpanEnd(String text, int i) {
    var run = 0;
    while (i + run < text.length && text[i + run] == '`') {
      run++;
    }
    var k = i + run;
    while (k < text.length) {
      if (text[k] == '`') {
        var close = 0;
        while (k + close < text.length && text[k + close] == '`') {
          close++;
        }
        if (close == run) {
          var code = text.substring(i + run, k).replaceAll('\n', ' ');
          if (code.length > 2 &&
              code.startsWith(' ') &&
              code.endsWith(' ') &&
              code.trim().isNotEmpty) {
            code = code.substring(1, code.length - 1);
          }
          return (code, k + close);
        }
        k += close;
      } else {
        k++;
      }
    }
    return null;
  }

  /// The index of the bracket closing the one opening at [open] (`[`/`(`),
  /// skipping code spans and escapes, or -1.
  static int _matching(String text, int open, String o, String c) {
    var depth = 0;
    var k = open;
    while (k < text.length) {
      final ch = text[k];
      if (ch == r'\') {
        k += 2;
        continue;
      }
      if (ch == '`') {
        final end = _codeSpanEnd(text, k);
        if (end != null) {
          k = end.$2;
          continue;
        }
      }
      if (ch == o) depth++;
      if (ch == c) {
        depth--;
        if (depth == 0) return k;
      }
      k++;
    }
    return -1;
  }

  /// A citation shape opening at [i] (RN-3): `(` directly followed by `->`,
  /// `<-` or `<~` and one space, content with balanced parentheses.
  (MdCitation, int)? _citation(String text, int i) {
    final head = text.substring(i + 1, (i + 4).clamp(0, text.length));
    final shape = switch (head) {
      '-> ' => MdCitationShape.backedBy,
      '<- ' => MdCitationShape.takenFrom,
      '<~ ' => MdCitationShape.extrapolatedFrom,
      _ => null,
    };
    if (shape == null) return null;
    final close = _matching(text, i, '(', ')');
    if (close < 0) return null;
    final content = text.substring(i + 4, close).replaceAll('\n', ' ').trim();
    if (content.isEmpty) return null;
    return (MdCitation(shape, content), close + 1);
  }

  /// A link `[text](url)` or (with the notation) a span `[text]{.kind}`
  /// opening at [i].
  (MdInline, int)? _bracket(String text, int i) {
    final close = _matching(text, i, '[', ']');
    if (close < 0 || close + 1 >= text.length) return null;
    final inner = text.substring(i + 1, close);
    final next = text[close + 1];
    if (next == '(') {
      final end = _matching(text, close + 1, '(', ')');
      if (end < 0) return null;
      var url = text.substring(close + 2, end).trim();
      // A title after the destination is dropped.
      final title = RegExp(r'''^(\S+)\s+["'(].*$''').firstMatch(url);
      if (title != null) url = title.group(1)!;
      if (url.startsWith('<') && url.endsWith('>')) {
        url = url.substring(1, url.length - 1);
      }
      return (MdLink(url, _inlines(inner)), end + 1);
    }
    if (notation && next == '{') {
      final end = text.indexOf('}', close + 1);
      if (end < 0) return null;
      final (kind, attrs) = _attributes(text.substring(close + 1, end + 1));
      return (MdSpan(kind, _inlines(inner), attributes: attrs), end + 1);
    }
    return null;
  }

  /// Emphasis or strong emphasis opening at [i], when it closes.
  (MdInline, int)? _emphasis(String text, int i) {
    final ch = text[i];
    var run = 0;
    while (i + run < text.length && text[i + run] == ch) {
      run++;
    }
    if (run > 2) return null;
    final after = i + run;
    if (after >= text.length || text[after].trim().isEmpty) return null;
    bool alnum(String c) => RegExp(r'[A-Za-z0-9]').hasMatch(c);
    if (ch == '_' && i > 0 && alnum(text[i - 1])) return null;
    final delim = ch * run;
    var k = after;
    while (k < text.length) {
      final c = text[k];
      if (c == r'\') {
        k += 2;
        continue;
      }
      if (c == '`') {
        final end = _codeSpanEnd(text, k);
        if (end != null) {
          k = end.$2;
          continue;
        }
      }
      if (c == '[') {
        final m = _matching(text, k, '[', ']');
        if (m > 0) {
          k = m + 1;
          continue;
        }
      }
      if (text.startsWith(delim, k) &&
          text[k - 1].trim().isNotEmpty &&
          !(k + run < text.length && text[k + run] == ch) &&
          !(ch == '_' && k + run < text.length && alnum(text[k + run]))) {
        final inner = _inlines(text.substring(after, k));
        final node = run == 2 ? MdStrong(inner) : MdEmphasis(inner);
        return (node, k + run);
      }
      k++;
    }
    return null;
  }
}
