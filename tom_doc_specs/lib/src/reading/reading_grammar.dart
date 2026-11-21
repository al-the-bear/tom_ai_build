/// The line grammar of the DocSpecs specification's reading forms: form and
/// section tables (*Form Types*, *List Bodies*), the `refs` / `records` divs
/// and the fenced-div findings of the reading notation (RN-1, RN-10).
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
  static final RegExp _cellPartSeparator = RegExp(r'\s*/\s*');

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
          rest.first.trim() == id || (m.start == 0 && rest.last.trim() == id);
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

  /// The fenced-div findings of a section's own body [text] (RN-10, the
  /// codes of every document that concern divs): `unclosedDiv` for an
  /// opening fence with no closing fence before the next heading,
  /// `strayClosingFence` for a closing fence with no open div,
  /// `rejectedBlock` for a `rejected` div. Fenced code is skipped.
  /// [firstLine] is the file line of the text's first line.
  static List<ValidationError> divFindings(
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
    for (var k = 0; k < lines.length; k++) {
      final line = lines[k];
      final wasInFence = fence.inFence;
      fence.feed(line);
      if (wasInFence || fence.inFence) continue;
      if (_divClose.hasMatch(line)) {
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
      if (m == null) continue;
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
    }
    for (final k in open) {
      findings.add(
        finding(
          'unclosedDiv',
          k,
          'an opening fence has no closing fence before the next heading',
        ),
      );
    }
    return findings;
  }
}
