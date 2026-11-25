/// The line grammar of the DocSpecs specification's reading forms: form and
/// section tables (*Form Types*, *List Bodies*), the `refs` / `records` divs
/// and the findings of the reading notation every document has (RN-10).
///
/// Only what the forms share lives here; `SpecSection` reads form tables and
/// `BodyReader` the list bodies and section tables with it.
library;

import 'package:tom_doc_scanner/tom_doc_scanner.dart';

import '../validation/validation_error.dart';

/// A table read from body lines: its header cells, the body rows with their
/// line indexes, and the index after the table.
typedef ReadTable = ({
  List<String> header,
  List<(int, List<String>)> rows,
  int end,
});

/// The grammar shared by the reading forms.
abstract final class ReadingGrammar {
  /// A form-table or section-table header at column 0: `TomSpecField | Value`
  /// or `DocSpecsField | Value` (any case), group 1 holding the `Section`
  /// column of a section table.
  static final RegExp layoutTableHeader = RegExp(
    r'^\|\s*(?:(Section)\s*\|\s*)?(?:TomSpecField|DocSpecsField)\s*\|\s*Value\s*\|?\s*$',
    caseSensitive: false,
  );

  /// A content line shaped like a layout header, written with one escape
  /// space before its first `|` (Form Tables rule 5).
  static final RegExp escapedLayoutTableHeader = RegExp(
    r'^ \|\s*(?:Section\s*\|\s*)?(?:TomSpecField|DocSpecsField)\s*\|\s*Value\s*\|?\s*$',
    caseSensitive: false,
  );

  /// A line that starts a table row: `|` after up to three spaces.
  static final RegExp tableLine = RegExp(r'^ {0,3}\|');

  static final RegExp _delimiterCell = RegExp(r'^:?-+:?$');

  /// The opening fence of a `refs` or `records` div, at column 0.
  static final RegExp listDivOpen = RegExp(
    r'^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$',
  );

  /// A closing div fence at column 0.
  static final RegExp listDivClose = RegExp(r'^:{3,}\s*$');

  /// Any opening div fence (RN-1): up to three spaces, three or more colons,
  /// then attribute braces or a bare kind word.
  static final RegExp _divOpen = RegExp(
    r'^ {0,3}:{3,}\s*(\{[^}]*\}|[A-Za-z][\w-]*)\s*:*\s*$',
  );

  /// Any closing div fence (RN-1): up to three spaces, colons, nothing else.
  static final RegExp _divClose = RegExp(r'^ {0,3}:{3,}\s*$');

  static final RegExp _rejectedClass = RegExp(
    r'(?:^|[\s{])\.rejected(?=[\s}]|$)',
  );

  static final RegExp _linkCell = RegExp(
    r'^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$',
  );

  /// A Markdown link; group 1 its text.
  static final RegExp linkText = RegExp(r'\[([^\]]+)\]\([^)]*\)');

  static final RegExp _cellAnchor = RegExp(r'<a id="([^"]*)"></a>\s*');

  /// Whether [anchor] is the own anchor of a section with [id] (*Section
  /// Anchors*): [id] itself, or the qualified form `<A>/…/<id>` a TomSpecs
  /// rendition writes below a list item, every segment non-empty.
  static bool _isOwnAnchor(String anchor, String id) {
    if (anchor == id) return true;
    if (!anchor.endsWith('/$id')) return false;
    return !anchor.split('/').any((s) => s.isEmpty);
  }

  static final RegExp _cellPartSeparator = RegExp(r'\s*/\s*');

  /// The number of leading lines of a section's [lines] that the rendition
  /// writes from the document and that hold no value: a paragraph that is one
  /// `linked` span (SOM §11.11), then a `derived` block (SOM §11.12), with
  /// the blank lines around them (DocSpecs RN-5, *Not text*).
  static int generatedLead(List<String> lines) {
    int skipBlank(int i) {
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
      return i;
    }

    var i = skipBlank(0);
    var end = i;
    while (end < lines.length && lines[end].trim().isNotEmpty) {
      end++;
    }
    final para = lines.sublist(i, end).join(' ').trim();
    if (end > i && RegExp(r'^\[.*\]\{\.linked\}$').hasMatch(para)) {
      i = skipBlank(end);
    }
    final open = i < lines.length
        ? RegExp(
            r'^ {0,3}(:{3,})[ \t]*\{\.derived(?=[\s}])',
          ).firstMatch(lines[i])
        : null;
    if (open != null) {
      final n = open.group(1)!.length;
      var k = i + 1;
      while (k < lines.length &&
          !RegExp('^ {0,3}:{$n,}[ \\t]*\$').hasMatch(lines[k])) {
        k++;
      }
      if (k < lines.length) i = skipBlank(k + 1);
    }
    return i;
  }

  /// The cells of a table row: split on every `|` not preceded by a
  /// backslash, the outer pipes dropped, each cell trimmed; `\|` stays in the
  /// cell (unescaped by [cellValue]).
  static List<String> rowCells(String line) {
    var t = line.trim();
    if (t.startsWith('|')) t = t.substring(1);
    if (t.endsWith('|') && !t.endsWith(r'\|')) {
      t = t.substring(0, t.length - 1);
    }
    final cells = <String>[];
    final b = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      final c = t[i];
      if (c == r'\' && i + 1 < t.length && t[i + 1] == '|') {
        b.write(r'\|');
        i++;
      } else if (c == '|') {
        cells.add(b.toString().trim());
        b.clear();
      } else {
        b.write(c);
      }
    }
    cells.add(b.toString().trim());
    return cells;
  }

  /// A value cell's value: `\|` unescaped, a cell of links read as their
  /// link texts; an empty cell is no value.
  static String cellValue(String cell) {
    final text = cell.replaceAll(r'\|', '|');
    if (_linkCell.hasMatch(text)) {
      return [
        for (final m in linkText.allMatches(text)) m.group(1)!,
      ].join(', ');
    }
    return text;
  }

  /// An `Id` or `Section` cell with its own anchors (`<a id="X"></a>X`)
  /// removed (*Section Anchors*): in a `<LIST> / <ITEM>` cell each part's
  /// anchor, and one before the whole cell naming its item. Any other anchor
  /// stays and makes the cell name no section.
  static String cellId(String cell) {
    final out = StringBuffer();
    var pos = 0;
    for (final m in _cellAnchor.allMatches(cell)) {
      out.write(cell.substring(pos, m.start));
      final id = m.group(1)!;
      final rest = cell.substring(m.end).split(_cellPartSeparator);
      final own =
          _isOwnAnchor(id, rest.first.trim()) ||
          (m.start == 0 && _isOwnAnchor(id, rest.last.trim()));
      if (!own) out.write(m.group(0));
      pos = m.end;
    }
    out.write(cell.substring(pos));
    return out.toString();
  }

  /// Reads the table whose header is [lines] line [start]. A missing or
  /// mismatched delimiter row is a `malformedBlock` at the header and the
  /// table yields no rows; a row of another cell count is a `malformedBlock`
  /// at that row and is left out. [lineOf] maps a line index to its line in
  /// the file.
  static ReadTable readTable(
    List<String> lines,
    int start,
    int Function(int) lineOf,
    String? sectionId,
    List<ValidationError> findings,
  ) {
    var end = start + 1;
    while (end < lines.length && tableLine.hasMatch(lines[end])) {
      end++;
    }
    final header = rowCells(lines[start]);
    final delimiter = start + 1 < end ? rowCells(lines[start + 1]) : null;
    final delimiterOk =
        delimiter != null && delimiter.every(_delimiterCell.hasMatch);
    if (!delimiterOk || delimiter.length != header.length) {
      findings.add(
        malformedBlock(
          sectionId,
          lineOf(start),
          delimiterOk
              ? 'table whose delimiter row does not match its header'
              : 'table without its delimiter row',
        ),
      );
      return (header: header, rows: const [], end: end);
    }
    final rows = <(int, List<String>)>[];
    for (var i = start + 2; i < end; i++) {
      final cells = rowCells(lines[i]);
      if (cells.length != header.length) {
        findings.add(
          malformedBlock(
            sectionId,
            lineOf(i),
            'table row with ${cells.length} cells, the header has '
            '${header.length}',
          ),
        );
        continue;
      }
      rows.add((i, cells));
    }
    return (header: header, rows: rows, end: end);
  }

  /// A `malformedBlock` finding.
  static ValidationError malformedBlock(
    String? sectionId,
    int? line,
    String message,
  ) => ValidationError(
    message: message,
    lineNumber: line,
    sectionId: sectionId,
    category: ValidationErrorCategory.format,
    code: 'malformedBlock',
  );

  /// A blockquote line that starts a review annotation (SOM §11.9): a
  /// comment block (`> ⬆️ …`, the marker with or without U+FE0F) or a
  /// question block (`> **❓ …`).
  static bool isAnnotationStart(String line) {
    final t = line.trimLeft();
    if (!t.startsWith('>')) return false;
    var inner = t.substring(1);
    if (inner.startsWith(' ')) inner = inner.substring(1);
    return inner.startsWith('⬆') || inner.startsWith('**❓');
  }

  static final RegExp _quotePrefix = RegExp(r'^ {0,3}>');
  static final RegExp _quoteMarkers = RegExp(r'^(?: {0,3}> ?)+');

  /// The reading-notation findings of a section's own body [text] that hold
  /// for every document (RN-10):
  ///
  /// - `unclosedDiv` — an opening fence with no closing fence before the
  ///   next heading; `strayClosingFence` — a closing fence with no open div;
  ///   `rejectedBlock` — a `rejected` div;
  /// - `annotationInsideDiv` — a comment or question block inside a div;
  ///   `divInsideAnnotation` — a div fence inside such a block (RN-12);
  /// - `unclosedSpan` — span braces opened after `]` that do not close in
  ///   the paragraph; `markAcrossNotation` — an inline review mark crossing
  ///   the boundary of a span or citation shape (RN-12).
  ///
  /// Fenced code and code spans are literal (RN-8); backslash escapes
  /// (`\:::`, `]\{.`, RN-9) are text. [firstLine] is the file line of the
  /// text's first line. The block findings come first, in line order, then
  /// the inline ones, in line order.
  static List<ValidationError> notationFindings(
    String text,
    int? firstLine,
    String? sectionId,
  ) {
    if (text.isEmpty || firstLine == null) return const [];
    final findings = <ValidationError>[];
    ValidationError finding(String code, int k, String message) =>
        ValidationError(
          message: message,
          lineNumber: firstLine + k,
          sectionId: sectionId,
          category: ValidationErrorCategory.notation,
          code: code,
        );

    final lines = text.split('\n');
    final fence = FenceTracker();
    final open = <int>[];
    // The paragraphs the inline checks read, as (first line index, lines).
    final paragraphs = <(int, List<String>)>[];
    int? paragraphStart;
    var paragraphLines = <String>[];
    void endParagraph() {
      if (paragraphStart != null) {
        paragraphs.add((paragraphStart!, paragraphLines));
      }
      paragraphStart = null;
      paragraphLines = <String>[];
    }

    void addToParagraph(int k, String line) {
      paragraphStart ??= k;
      paragraphLines.add(line);
    }

    var inQuote = false; // inside any blockquote
    var inAnnotation = false; // inside a comment or question block
    for (var k = 0; k < lines.length; k++) {
      final line = lines[k];
      final wasInFence = fence.inFence;
      fence.feed(line);
      if (wasInFence || fence.inFence) {
        endParagraph();
        continue;
      }
      if (_quotePrefix.hasMatch(line)) {
        final startsAnnotation = isAnnotationStart(line);
        if (!inQuote || startsAnnotation) endParagraph();
        inQuote = true;
        if (startsAnnotation) {
          inAnnotation = true;
          if (open.isNotEmpty) {
            findings.add(
              finding(
                'annotationInsideDiv',
                k,
                'a review annotation block stands inside a div; place it '
                    'before or after the div',
              ),
            );
          }
        }
        final inner = line.replaceFirst(_quoteMarkers, '');
        final opensDiv = _divOpen.hasMatch(inner);
        if (opensDiv || _divClose.hasMatch(inner)) {
          endParagraph();
          if (opensDiv && inAnnotation) {
            findings.add(
              finding(
                'divInsideAnnotation',
                k,
                'a div stands inside a review annotation block; place it '
                    'outside the block',
              ),
            );
          }
        } else if (inner.trim().isEmpty) {
          endParagraph();
        } else {
          addToParagraph(k, inner);
        }
        continue;
      }
      if (inQuote) endParagraph();
      inQuote = inAnnotation = false;
      if (line.trim().isEmpty) {
        endParagraph();
        continue;
      }
      if (_divClose.hasMatch(line)) {
        endParagraph();
        if (open.isEmpty) {
          findings.add(
            finding('strayClosingFence', k, 'a closing fence has no open div'),
          );
        } else {
          open.removeLast();
        }
        continue;
      }
      final m = _divOpen.firstMatch(line);
      if (m != null) {
        endParagraph();
        open.add(k);
        final attributes = m.group(1)!;
        final rejected = attributes.startsWith('{')
            ? _rejectedClass.hasMatch(attributes)
            : attributes == 'rejected';
        if (rejected) {
          findings.add(
            finding(
              'rejectedBlock',
              k,
              'a rejected block is present; resolve it and remove the div',
            ),
          );
        }
        continue;
      }
      // A table row is one line: a cell holds spans only (RN-7).
      if (tableLine.hasMatch(line)) {
        endParagraph();
        paragraphs.add((k, [line]));
        continue;
      }
      addToParagraph(k, line);
    }
    endParagraph();
    for (final k in open) {
      findings.add(
        finding(
          'unclosedDiv',
          k,
          'an opening fence has no closing fence before the next heading',
        ),
      );
    }
    for (final (first, paragraph) in paragraphs) {
      for (final (offset, code, message) in _inlineFindings(paragraph)) {
        findings.add(finding(code, first + offset, message));
      }
    }
    return findings;
  }

  /// The inline review marks (SOM §11.9.3): opener and closer.
  static const _marks = [
    ('{++', '++}'),
    ('{--', '--}'),
    ('{~~', '~~}'),
    ('{==', '==}'),
    ('{>>', '<<}'),
  ];

  /// The citation shapes (RN-3): `(` with the arrow and one space.
  static const _citationOpeners = ['(-> ', '(<- ', '(<~ '];

  /// The characters a CommonMark backslash escapes.
  static const _asciiPunctuation = '!"#\$%&\'()*+,-./:;<=>?@[\\]^_`{|}~';

  /// The `unclosedSpan` and `markAcrossNotation` findings of one paragraph,
  /// each as (line offset in the paragraph, code, message).
  static List<(int, String, String)> _inlineFindings(List<String> lines) {
    final text = lines.join('\n');
    final n = text.length;
    int lineAt(int pos) => '\n'.allMatches(text.substring(0, pos)).length;

    // Literal characters: code spans (RN-8) and backslash escapes (RN-9).
    final literal = List<bool>.filled(n, false);
    for (var i = 0; i < n; i++) {
      final c = text[i];
      if (c == r'\' && i + 1 < n && _asciiPunctuation.contains(text[i + 1])) {
        literal[i] = literal[i + 1] = true;
        i++;
        continue;
      }
      if (c != '`') continue;
      var run = 1;
      while (i + run < n && text[i + run] == '`') {
        run++;
      }
      final close = _backtickRun(text, i + run, run);
      if (close == -1) {
        i += run - 1; // unmatched backticks are text
        continue;
      }
      for (var j = i; j < close + run; j++) {
        literal[j] = true;
      }
      i = close + run - 1;
    }
    bool at(int i, String token) {
      if (!text.startsWith(token, i)) return false;
      for (var j = i; j < i + token.length; j++) {
        if (literal[j]) return false;
      }
      return true;
    }

    int find(String token, int from) {
      for (var i = from; i + token.length <= n; i++) {
        if (at(i, token)) return i;
      }
      return -1;
    }

    final out = <(int, String, String)>[];

    // The inline marks, as [start, end) ranges.
    final marks = <(int, int)>[];
    for (var i = 0; i < n; i++) {
      for (final (opener, closer) in _marks) {
        if (!at(i, opener)) continue;
        final close = find(closer, i + opener.length);
        if (close != -1) {
          marks.add((i, close + closer.length));
          i = close + closer.length - 1;
        }
        break;
      }
    }
    bool isMarkOpener(int i) => _marks.any((m) => at(i, m.$1));

    // The spans and citation shapes, as [start, end) ranges.
    final notation = <(int, int)>[];
    final brackets = <int>[];
    for (var i = 0; i < n; i++) {
      if (literal[i]) continue;
      final c = text[i];
      if (c == '[') {
        brackets.add(i);
      } else if (c == ']' && brackets.isNotEmpty) {
        final start = brackets.removeLast();
        if (at(i + 1, '{') && !isMarkOpener(i + 1)) {
          final close = _braceClose(text, literal, i + 2);
          if (close == -1) {
            out.add((
              lineAt(i + 1),
              'unclosedSpan',
              "a span's attribute braces do not close in the paragraph",
            ));
          } else {
            notation.add((start, close + 1));
          }
        }
      } else if (_citationOpeners.any((o) => at(i, o))) {
        var depth = 0;
        for (var j = i; j < n; j++) {
          if (literal[j]) continue;
          if (text[j] == '(') depth++;
          if (text[j] == ')' && --depth == 0) {
            notation.add((i, j + 1));
            break;
          }
        }
      }
    }

    for (final (ms, me) in marks) {
      final crosses = notation.any(
        (r) =>
            (ms > r.$1 && ms < r.$2 && me > r.$2) ||
            (ms < r.$1 && me > r.$1 && me < r.$2),
      );
      if (crosses) {
        out.add((
          lineAt(ms),
          'markAcrossNotation',
          'an inline review mark opens inside a span or citation and closes '
              'outside it, or the reverse',
        ));
      }
    }
    out.sort((a, b) => a.$1.compareTo(b.$1));
    return out;
  }

  /// The start of the next run of exactly [length] backticks from [from];
  /// -1 when there is none.
  static int _backtickRun(String text, int from, int length) {
    var i = from;
    while (i < text.length) {
      if (text[i] != '`') {
        i++;
        continue;
      }
      var end = i;
      while (end < text.length && text[end] == '`') {
        end++;
      }
      if (end - i == length) return i;
      i = end;
    }
    return -1;
  }

  /// The index of the `}` closing span braces whose content starts at
  /// [from]; a `}` inside a quoted attribute value does not close them. -1
  /// when they do not close.
  static int _braceClose(String text, List<bool> literal, int from) {
    String? quote;
    for (var i = from; i < text.length; i++) {
      if (literal[i]) continue;
      final c = text[i];
      if (quote != null) {
        if (c == quote) quote = null;
      } else if (c == '"') {
        quote = c;
      } else if (c == '}') {
        return i;
      }
    }
    return -1;
  }
}
