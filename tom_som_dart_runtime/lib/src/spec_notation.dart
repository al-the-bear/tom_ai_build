/// The reading notation's scanner: one call per text value, returning the
/// value's fenced divs, bracketed spans and citation shapes with their kind,
/// attributes, source ranges and nesting, and the findings the DocSpecs
/// specification lists for the notation.
///
/// The grammar is the DocSpecs specification's *Reading Notation* section
/// (`_ai/quests/doc_specs/doc_specs_specification.md`, RN-1 … RN-13):
///
/// - a **fenced div** is a line of at least three colons, indented up to three
///   spaces, then attribute braces (`::: {.provenance}`) or a bare kind word
///   (`::: aside`); it closes at a line of at least three colons and nothing
///   else, and a closing fence closes the innermost open div (RN-1, RN-7);
/// - a **bracketed span** is `[text]` followed immediately by attribute braces
///   (`[an aside]{.aside}`), inside one paragraph (RN-2);
/// - a **citation shape** is `(-> ids)` (kind `trace`), `(<- source)` or
///   `(<~ source)` (kind `provenance`): the opening parenthesis, the arrow, one
///   space, a non-empty content with balanced parentheses, the closing
///   parenthesis (RN-3);
/// - fenced code and code spans are literal, and so are `\:::` and `]\{.`,
///   which are backslash escapes and characters of the value (RN-8, RN-9).
///
/// The kinds are an open set with a registered core ([registeredNotationKinds]);
/// an unknown kind passes through as an element like any other (RN-5).
///
/// The scanner works on the characters of the value and never changes them.
/// Offsets are UTF-16 code units, as in the TypeScript port.
library;

/// The kinds the notation registers (RN-5); any other kind passes through.
const Set<String> registeredNotationKinds = {
  'provenance',
  'trace',
  'editorial',
  'aside',
  'linked',
  'refs',
  'records',
  'rejected',
};

/// What an element of the notation is.
enum NotationElementType {
  /// A fenced div: a block (RN-1).
  div,

  /// A bracketed span: inline (RN-2).
  span,

  /// A citation shape: `(-> …)`, `(<- …)` or `(<~ …)` (RN-3).
  citation,
}

/// How serious a [NotationFinding] is.
enum NotationSeverity {
  /// The text breaks the notation.
  error,

  /// The text is valid but asks for a look (an unknown kind).
  warning,
}

/// The notation's findings (RN-10); each name is the rule's name in the
/// validator output.
enum NotationFindingCode {
  /// An opening fence has no closing fence in the value.
  unclosedDiv,

  /// A closing fence has no open div.
  strayClosingFence,

  /// A span's attribute braces open after `]` and do not close on the
  /// paragraph.
  unclosedSpan,

  /// A div's attributes hold no class (TomSpecs renditions only).
  divWithoutKind,

  /// A div's or span's kind is not registered (TomSpecs renditions only; a
  /// warning).
  unknownKind,

  /// An inline review mark opens inside a span or citation and closes outside
  /// it, or the reverse (RN-12).
  markAcrossNotation,

  /// A comment or question block stands inside a div (RN-12).
  annotationInsideDiv,

  /// A div stands inside a comment or question block (RN-12).
  divInsideAnnotation,

  /// A `rejected` div is present (RN-11).
  rejectedBlock;

  /// The severity: [unknownKind] is a warning, every other code an error.
  NotationSeverity get severity => this == NotationFindingCode.unknownKind
      ? NotationSeverity.warning
      : NotationSeverity.error;
}

/// One element of the notation: a div, a span or a citation.
class NotationElement {
  /// An element of [type] over `[start, end)` of the scanned text.
  NotationElement({
    required this.type,
    required this.kind,
    required this.classes,
    required this.id,
    required this.attributes,
    required this.shape,
    required this.start,
    required this.end,
    required this.contentStart,
    required this.contentEnd,
    required this.line,
    required this.endLine,
    required this.closed,
  });

  /// Div, span or citation.
  final NotationElementType type;

  /// The kind: the first class, `trace` / `provenance` for a citation; null
  /// for a div or span without a class.
  final String? kind;

  /// Every class of the attributes, the kind first.
  final List<String> classes;

  /// The `#id` of the attributes, when given; it is not a section id (RN-6).
  final String? id;

  /// The `key="value"` pairs of the attributes, in their order.
  final Map<String, String> attributes;

  /// A citation's arrow: `->`, `<-` or `<~`; null for a div or span.
  final String? shape;

  /// The offset of the element's first character (a div: its opening fence
  /// line, indentation included).
  final int start;

  /// The offset after the element's last character (a div: the end of its
  /// closing fence line; an unclosed div: the end of the text).
  final int end;

  /// The offset of the content: a div's first line after the opening fence, a
  /// span's text after `[`, a citation's content after the arrow and space.
  final int contentStart;

  /// The offset after the content: a div's closing fence line start, a span's
  /// `]`, a citation's closing `)`.
  final int contentEnd;

  /// The 1-based line of [start].
  final int line;

  /// The 1-based line of the element's last character.
  final int endLine;

  /// False for a div without a closing fence (an [NotationFindingCode.unclosedDiv]);
  /// spans and citations are only elements when they close.
  final bool closed;

  /// The elements nested in this one, in source order.
  final List<NotationElement> children = [];

  /// Whether [kind] is one of [registeredNotationKinds].
  bool get isRegistered =>
      kind != null && registeredNotationKinds.contains(kind);

  /// The element as the conformance corpus writes it, with its [text] slices.
  Map<String, Object?> toJson(String text) => {
    'type': type.name,
    'kind': kind,
    'classes': classes,
    'id': id,
    'attributes': attributes,
    'shape': shape,
    'start': start,
    'end': end,
    'line': line,
    'endLine': endLine,
    'closed': closed,
    'source': text.substring(start, end),
    'content': text.substring(contentStart, contentEnd),
    'children': [for (final c in children) c.toJson(text)],
  };
}

/// One finding of the scan.
class NotationFinding {
  /// A finding [code] at [offset] (1-based [line]) with a [message].
  const NotationFinding({
    required this.code,
    required this.offset,
    required this.line,
    required this.message,
  });

  /// Which rule the text breaks.
  final NotationFindingCode code;

  /// The offset the finding points at.
  final int offset;

  /// The 1-based line of [offset].
  final int line;

  /// A human-readable explanation; display text only.
  final String message;

  /// The severity of [code].
  NotationSeverity get severity => code.severity;

  /// The finding as the conformance corpus writes it.
  Map<String, Object?> toJson() => {
    'code': code.name,
    'severity': severity.name,
    'line': line,
  };

  @override
  String toString() => 'line $line: ${code.name} — $message';
}

/// The result of [scanNotation]: the top-level [elements] (each holding its
/// nested ones) and the [findings] in source order.
class NotationScan {
  /// The scan of [text].
  const NotationScan(this.text, this.elements, this.findings);

  /// The scanned text.
  final String text;

  /// The elements not nested in another, in source order.
  final List<NotationElement> elements;

  /// The findings, by offset.
  final List<NotationFinding> findings;

  /// Every element, depth-first in source order.
  Iterable<NotationElement> get all sync* {
    Iterable<NotationElement> walk(List<NotationElement> list) sync* {
      for (final e in list) {
        yield e;
        yield* walk(e.children);
      }
    }

    yield* walk(elements);
  }

  /// Whether a finding of severity error is present.
  bool get hasErrors =>
      findings.any((f) => f.severity == NotationSeverity.error);
}

final RegExp _divOpen = RegExp(
  r'^ {0,3}:{3,}[ \t]*(?:\{(.*)\}|([A-Za-z][A-Za-z0-9_-]*))[ \t]*$',
);
final RegExp _divClose = RegExp(r'^ {0,3}:{3,}[ \t]*$');
final RegExp _codeFenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
final RegExp _quoteLine = RegExp(r'^ {0,3}>');
final RegExp _annotationStart = RegExp(r'^ {0,3}> ?(?:⬆|\*\*❓|⚖)');
final RegExp _quotedDivOpen = RegExp(
  r'^ {0,3}>[ \t]?( {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*)$',
);
final RegExp _attributeToken = RegExp(
  r'''\.([^\s.#}="']+)|#([^\s.#}="']+)|([A-Za-z_][A-Za-z0-9_:.-]*)=("[^"]*"|'[^']*'|[^\s}]+)''',
);
const String _asciiPunctuation = r'''!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~''';
const List<String> _markOpeners = ['{++', '{--', '{~~', '{==', '{>>'];
const Map<String, String> _markClosers = {
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
  '{==': '==}',
  '{>>': '<<}',
};
const Map<String, String> _citationKinds = {
  '->': 'trace',
  '<-': 'provenance',
  '<~': 'provenance',
};

/// Scans one text value for the reading notation.
///
/// [tomSpecs] says the value belongs to a TomSpecs rendition: only then are a
/// div without a class (`divWithoutKind`) and an unregistered kind
/// (`unknownKind`, a warning) reported (RN-10). Every other finding is
/// reported in every document.
NotationScan scanNotation(String text, {bool tomSpecs = false}) =>
    _NotationScanner(text, tomSpecs).scan();

class _OpenDiv {
  _OpenDiv(this.start, this.contentStart, this.line, this.attributes);
  final int start;
  final int contentStart;
  final int line;
  final _Attributes attributes;
}

class _Attributes {
  _Attributes(this.classes, this.id, this.pairs);
  final List<String> classes;
  final String? id;
  final Map<String, String> pairs;
}

_Attributes _parseAttributes(String inner) {
  final classes = <String>[];
  String? id;
  final pairs = <String, String>{};
  for (final m in _attributeToken.allMatches(inner)) {
    if (m.group(1) != null) {
      classes.add(m.group(1)!);
    } else if (m.group(2) != null) {
      id ??= m.group(2);
    } else {
      var value = m.group(4)!;
      if (value.length >= 2 &&
          (value.startsWith('"') && value.endsWith('"') ||
              value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      pairs[m.group(3)!] = value;
    }
  }
  return _Attributes(classes, id, pairs);
}

class _NotationScanner {
  _NotationScanner(this.text, this.tomSpecs) {
    var offset = 0;
    for (final line in text.split('\n')) {
      _lineStarts.add(offset);
      _lines.add(line);
      offset += line.length + 1;
    }
  }

  final String text;
  final bool tomSpecs;
  final List<int> _lineStarts = [];
  final List<String> _lines = [];
  final List<NotationElement> _elements = [];
  final List<NotationFinding> _findings = [];

  /// The 1-based line of [offset].
  int _lineOf(int offset) {
    var lo = 0, hi = _lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  void _find(NotationFindingCode code, int offset, String message) =>
      _findings.add(
        NotationFinding(
          code: code,
          offset: offset,
          line: _lineOf(offset),
          message: message,
        ),
      );

  NotationScan scan() {
    _blocks();
    _kindFindings();
    _elements.sort((a, b) {
      final c = a.start.compareTo(b.start);
      if (c != 0) return c;
      final d = b.end.compareTo(a.end);
      if (d != 0) return d;
      return a.type.index.compareTo(b.type.index);
    });
    final roots = <NotationElement>[];
    final stack = <NotationElement>[];
    for (final e in _elements) {
      while (stack.isNotEmpty &&
          !(e.start >= stack.last.start && e.end <= stack.last.end)) {
        stack.removeLast();
      }
      (stack.isEmpty ? roots : stack.last.children).add(e);
      stack.add(e);
    }
    _findings.sort((a, b) {
      final c = a.offset.compareTo(b.offset);
      return c != 0 ? c : a.code.index.compareTo(b.code.index);
    });
    return NotationScan(text, roots, List.unmodifiable(_findings));
  }

  // --- Blocks -------------------------------------------------------------

  void _blocks() {
    final open = <_OpenDiv>[];
    String? codeFence; // the fence characters of an open fenced code block
    var inAnnotation = false;
    int? regionStart;
    var regionEnd = 0;

    void endRegion() {
      final s = regionStart;
      if (s != null) _inline(s, regionEnd);
      regionStart = null;
    }

    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final start = _lineStarts[i];
      final lineEnd = start + line.length;
      final next = i + 1 < _lines.length ? _lineStarts[i + 1] : text.length;

      final fence = codeFence;
      if (fence != null) {
        final t = line.trimLeft();
        if (line.length - t.length <= 3 &&
            t.startsWith(fence) &&
            t.substring(fence.length).replaceAll(fence[0], '').trim().isEmpty) {
          codeFence = null;
        }
        continue;
      }

      // Comment and question blocks (RN-12).
      if (_annotationStart.hasMatch(line)) {
        if (!inAnnotation && open.isNotEmpty) {
          _find(
            NotationFindingCode.annotationInsideDiv,
            start,
            'a comment or question block stands inside a div',
          );
        }
        inAnnotation = true;
      } else if (!_quoteLine.hasMatch(line)) {
        inAnnotation = false;
      }
      if (inAnnotation) {
        if (_quotedDivOpen.hasMatch(line)) {
          _find(
            NotationFindingCode.divInsideAnnotation,
            start,
            'a div stands inside a comment or question block',
          );
        }
        regionStart ??= start;
        regionEnd = lineEnd;
        continue;
      }

      final code = _codeFenceOpen.firstMatch(line);
      if (code != null &&
          !(code.group(1)!.startsWith('`') && code.group(2)!.contains('`'))) {
        endRegion();
        codeFence = code.group(1);
        continue;
      }

      final divOpen = _divOpen.firstMatch(line);
      if (divOpen != null) {
        endRegion();
        final attributes = divOpen.group(1) != null
            ? _parseAttributes(divOpen.group(1)!)
            : _Attributes([divOpen.group(2)!], null, {});
        open.add(_OpenDiv(start, next, i + 1, attributes));
        continue;
      }

      if (_divClose.hasMatch(line)) {
        endRegion();
        if (open.isEmpty) {
          _find(
            NotationFindingCode.strayClosingFence,
            start,
            'a closing fence has no open div',
          );
        } else {
          final d = open.removeLast();
          _addDiv(d, end: lineEnd, contentEnd: start, closed: true);
        }
        continue;
      }

      if (line.trim().isEmpty) {
        endRegion();
        continue;
      }
      regionStart ??= start;
      regionEnd = lineEnd;
    }
    endRegion();
    while (open.isNotEmpty) {
      final d = open.removeLast();
      _find(
        NotationFindingCode.unclosedDiv,
        d.start,
        'an opening fence has no closing fence',
      );
      _addDiv(d, end: text.length, contentEnd: text.length, closed: false);
    }
  }

  void _addDiv(
    _OpenDiv d, {
    required int end,
    required int contentEnd,
    required bool closed,
  }) {
    final a = d.attributes;
    final contentStart = d.contentStart > contentEnd
        ? contentEnd
        : d.contentStart;
    _elements.add(
      NotationElement(
        type: NotationElementType.div,
        kind: a.classes.isEmpty ? null : a.classes.first,
        classes: a.classes,
        id: a.id,
        attributes: a.pairs,
        shape: null,
        start: d.start,
        end: end,
        contentStart: contentStart,
        contentEnd: contentEnd,
        line: d.line,
        endLine: _lineOf(end > d.start ? end - 1 : d.start),
        closed: closed,
      ),
    );
  }

  // --- Inline -------------------------------------------------------------

  /// Scans the paragraph `[start, end)` for spans, citations and marks.
  void _inline(int start, int end) {
    final literal = <int, int>{}; // code span start -> end
    final escaped = <int>{};
    for (var i = start; i < end; i++) {
      final c = text[i];
      if (c == r'\' && i + 1 < end && _asciiPunctuation.contains(text[i + 1])) {
        escaped.add(i + 1);
        i++;
        continue;
      }
      if (c == '`') {
        var n = 0;
        while (i + n < end && text[i + n] == '`') {
          n++;
        }
        final close = _closingBackticks(i + n, end, n);
        if (close >= 0) {
          literal[i] = close + n;
          i = close + n - 1;
        } else {
          i += n - 1;
        }
      }
    }

    final spans = <NotationElement>[];
    final marks = <(int, int)>[];
    final brackets = <int>[];
    var i = start;
    while (i < end) {
      final skip = literal[i];
      if (skip != null) {
        i = skip;
        continue;
      }
      final c = text[i];
      if (escaped.contains(i) || c == r'\' && escaped.contains(i + 1)) {
        i++;
        continue;
      }
      if (c == '{') {
        final opener = _markOpeners.where((o) => text.startsWith(o, i));
        if (opener.isNotEmpty) {
          final closer = _markClosers[opener.first]!;
          final close = text.indexOf(closer, i + 3);
          if (close >= 0 && close + closer.length <= end) {
            marks.add((i, close + closer.length));
          }
          i += 3;
          continue;
        }
      }
      if (c == '[') {
        brackets.add(i);
      } else if (c == ']' && brackets.isNotEmpty) {
        final open = brackets.removeLast();
        if (i + 1 < end &&
            text[i + 1] == '{' &&
            !escaped.contains(i + 1) &&
            !_markOpeners.any((o) => text.startsWith(o, i + 1))) {
          final close = _closingBrace(i + 2, end);
          if (close < 0) {
            _find(
              NotationFindingCode.unclosedSpan,
              i + 1,
              "a span's attribute braces do not close on the paragraph",
            );
          } else {
            final a = _parseAttributes(text.substring(i + 2, close));
            final span = NotationElement(
              type: NotationElementType.span,
              kind: a.classes.isEmpty ? null : a.classes.first,
              classes: a.classes,
              id: a.id,
              attributes: a.pairs,
              shape: null,
              start: open,
              end: close + 1,
              contentStart: open + 1,
              contentEnd: i,
              line: _lineOf(open),
              endLine: _lineOf(close),
              closed: true,
            );
            spans.add(span);
            _elements.add(span);
            i = close + 1;
            continue;
          }
        }
      } else if (c == '(' && i + 3 < end && text[i + 3] == ' ') {
        final arrow = text.substring(i + 1, i + 3);
        final kind = _citationKinds[arrow];
        if (kind != null) {
          final close = _closingParenthesis(i + 4, end, literal);
          if (close > i + 4 && text.substring(i + 4, close).trim().isNotEmpty) {
            final citation = NotationElement(
              type: NotationElementType.citation,
              kind: kind,
              classes: [kind],
              id: null,
              attributes: const {},
              shape: arrow,
              start: i,
              end: close + 1,
              contentStart: i + 4,
              contentEnd: close,
              line: _lineOf(i),
              endLine: _lineOf(close),
              closed: true,
            );
            spans.add(citation);
            _elements.add(citation);
            i += 4;
            continue;
          }
        }
      }
      i++;
    }

    for (final (ms, me) in marks) {
      for (final e in spans) {
        final crosses =
            ms < e.start && e.start < me && me < e.end ||
            e.start < ms && ms < e.end && e.end < me;
        if (crosses) {
          _find(
            NotationFindingCode.markAcrossNotation,
            ms,
            'an inline review mark crosses the boundary of a '
            '${e.type.name}',
          );
          break;
        }
      }
    }
  }

  /// The offset of a run of exactly [n] backticks in `[from, end)`, or -1.
  int _closingBackticks(int from, int end, int n) {
    var i = from;
    while (i < end) {
      if (text[i] == '`') {
        var m = 0;
        while (i + m < end && text[i + m] == '`') {
          m++;
        }
        if (m == n) return i;
        i += m;
      } else {
        i++;
      }
    }
    return -1;
  }

  /// The offset of the `}` closing attribute braces opened before [from], or
  /// -1; a quoted value may hold a `}`.
  int _closingBrace(int from, int end) {
    String? quote;
    for (var i = from; i < end; i++) {
      final c = text[i];
      if (quote != null) {
        if (c == quote) quote = null;
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if (c == '}') {
        return i;
      } else if (c == '{') {
        return -1;
      }
    }
    return -1;
  }

  /// The offset of the `)` balancing a citation opened before [from], or -1.
  int _closingParenthesis(int from, int end, Map<int, int> literal) {
    var depth = 0;
    var i = from;
    while (i < end) {
      final skip = literal[i];
      if (skip != null) {
        i = skip;
        continue;
      }
      final c = text[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        if (depth == 0) return i;
        depth--;
      }
      i++;
    }
    return -1;
  }

  // --- Kinds --------------------------------------------------------------

  void _kindFindings() {
    for (final e in _elements) {
      if (e.type == NotationElementType.citation) continue;
      if (e.type == NotationElementType.div && e.kind == 'rejected') {
        _find(
          NotationFindingCode.rejectedBlock,
          e.start,
          'a rejected block waits for its resolution',
        );
      }
      if (!tomSpecs) continue;
      if (e.kind == null) {
        if (e.type == NotationElementType.div) {
          _find(
            NotationFindingCode.divWithoutKind,
            e.start,
            "a div's attributes hold no class",
          );
        }
      } else if (!e.isRegistered) {
        _find(
          NotationFindingCode.unknownKind,
          e.start,
          'the kind "${e.kind}" is not registered',
        );
      }
    }
  }
}
