/// Review annotations in content values (SOM §11.9): comment blocks, question
/// blocks and CriticMarkup inline marks.
///
/// An annotation is text inside a content value or a form-field value. This
/// library reads it out of that text and edits it in place, and every edit is
/// byte-stable outside the annotation it touches. The notation itself is
/// `som_multiplatform_spec_model.md` §11.9.
///
/// Positions are **0-based line numbers within the value**, never character
/// offsets: the nine runtimes count characters in different units, and a line
/// number is the same in all of them.
library;

import 'dart:convert';

import 'spec_document.dart';
import 'spec_validator.dart';

/// The three kinds of annotation (SOM §11.9).
enum SpecReviewAnnotationKind {
  /// A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`.
  comment,

  /// One question of a question block, `> **❓ BQ-81 — topic:** …`.
  question,

  /// A CriticMarkup inline mark.
  mark,
}

/// The five CriticMarkup inline marks (SOM §11.9.3).
enum SpecMarkKind {
  /// `{>> comment <<}`.
  comment,

  /// `{== text ==}`, optionally followed by `{>> comment <<}`.
  highlight,

  /// `{++ added ++}`.
  insertion,

  /// `{-- removed --}`.
  deletion,

  /// `{~~ old ~> new ~~}`.
  substitution,
}

/// One annotation, located by the value that holds it.
class SpecReviewAnnotation {
  /// The kind.
  final SpecReviewAnnotationKind kind;

  /// The document path of the value: a content path, or a form path when
  /// [field] is set.
  final String path;

  /// The form field whose value holds the annotation; null for content.
  final String? field;

  /// The 0-based line within the value where the annotation starts (a
  /// question: its header line).
  final int line;

  /// The comment id (`C-12`) or question id (`BQ-81`); null for a comment
  /// without an id and for a mark.
  final String? id;

  /// A comment's id with the document qualifier in front (`SBP C-12`), when
  /// the listing was given a qualifier and the comment has an id.
  final String? qualifiedId;

  /// A comment's author; null when none is written.
  final String? author;

  /// A comment's text, a question's text (options included), or a mark's
  /// text (the added, removed or highlighted text; a substitution's old text;
  /// empty for a comment mark).
  final String text;

  /// A comment's context: the paragraph before the block, verbatim (empty at
  /// the start of the value).
  final String context;

  /// A question's topic (in a combined block: the field it asks about).
  final String? topic;

  /// Whether a question carries `★` before its topic.
  final bool starred;

  /// Whether a question is part of a combined block
  /// (`**❓ Open questions on these fields**`).
  final bool combined;

  /// A question's answer, trimmed; empty when open.
  final String answer;

  /// A mark's kind.
  final SpecMarkKind? markKind;

  /// A substitution's new text.
  final String? newText;

  /// The comment of a comment mark, or of a highlight followed by one.
  final String? comment;

  /// Creates an annotation.
  const SpecReviewAnnotation({
    required this.kind,
    required this.path,
    this.field,
    required this.line,
    this.id,
    this.qualifiedId,
    this.author,
    this.text = '',
    this.context = '',
    this.topic,
    this.starred = false,
    this.combined = false,
    this.answer = '',
    this.markKind,
    this.newText,
    this.comment,
  });

  /// Whether a question is still open (no answer written).
  bool get open => kind == SpecReviewAnnotationKind.question && answer.isEmpty;

  /// The canonical JSON form the conformance corpus pins.
  Map<String, Object?> toJson() => switch (kind) {
    SpecReviewAnnotationKind.comment => {
      'kind': 'comment',
      'path': path,
      'field': field,
      'line': line,
      'id': id,
      'qualifiedId': qualifiedId,
      'author': author,
      'text': text,
      'context': context,
    },
    SpecReviewAnnotationKind.question => {
      'kind': 'question',
      'path': path,
      'field': field,
      'line': line,
      'id': id,
      'topic': topic,
      'starred': starred,
      'combined': combined,
      'text': text,
      'answer': answer,
      'open': open,
    },
    SpecReviewAnnotationKind.mark => {
      'kind': 'mark',
      'path': path,
      'field': field,
      'line': line,
      'markKind': markKind!.name,
      'text': text,
      'newText': newText,
      'comment': comment,
    },
  };
}

/// The counts a report needs (SOM §11.9).
class SpecReviewAnnotationCounts {
  /// Every question.
  final int questions;

  /// Questions without an answer.
  final int openQuestions;

  /// Questions with an answer.
  final int answeredQuestions;

  /// Comment blocks.
  final int comments;

  /// Inline marks.
  final int marks;

  /// Creates counts.
  const SpecReviewAnnotationCounts({
    this.questions = 0,
    this.openQuestions = 0,
    this.answeredQuestions = 0,
    this.comments = 0,
    this.marks = 0,
  });

  /// The canonical JSON form.
  Map<String, int> toJson() => {
    'questions': questions,
    'openQuestions': openQuestions,
    'answeredQuestions': answeredQuestions,
    'comments': comments,
    'marks': marks,
  };
}

/// A question to insert (SOM §11.9.2).
class SpecQuestionDraft {
  /// The question id (`BQ-90`).
  final String id;

  /// The topic.
  final String topic;

  /// The question text; may span lines.
  final String text;

  /// Option lines, written as `- <option>` (e.g. `(a) lower only`).
  final List<String> options;

  /// The recommendation, or empty.
  final String recommendation;

  /// The working assumption, or empty.
  final String assumption;

  /// Whether the question carries `★`.
  final bool starred;

  /// Creates a draft.
  const SpecQuestionDraft({
    required this.id,
    required this.topic,
    required this.text,
    this.options = const [],
    this.recommendation = '',
    this.assumption = '',
    this.starred = false,
  });

  /// Reads a draft from its corpus JSON form.
  factory SpecQuestionDraft.fromJson(Map<String, dynamic> j) =>
      SpecQuestionDraft(
        id: j['id'] as String,
        topic: j['topic'] as String,
        text: j['text'] as String,
        options: [for (final o in (j['options'] as List? ?? const [])) '$o'],
        recommendation: j['recommendation'] as String? ?? '',
        assumption: j['assumption'] as String? ?? '',
        starred: j['starred'] as bool? ?? false,
      );
}

/// What to do with one inline mark (SOM §11.9.3).
enum SpecMarkDecision {
  /// Take the change: an insertion's text, nothing for a deletion, a
  /// substitution's new text.
  accept,

  /// Undo the change: nothing for an insertion, a deletion's text, a
  /// substitution's old text.
  reject,

  /// Keep the mark as written.
  leave,
}

/// One inline mark as `listMarks` reports it.
class SpecMarkEntry {
  /// `M-<n>`: the mark's 1-based position among all marks of the document, in
  /// document order. Stable for one [SpecReviewAnnotations.revision].
  final String id;

  /// The value's path.
  final String path;

  /// The form field, or null for content.
  final String? field;

  /// The 0-based line within the value where the mark opens.
  final int line;

  /// The mark's kind.
  final SpecMarkKind markKind;

  /// The text after rejecting the mark.
  final String oldText;

  /// The text after accepting the mark.
  final String newText;

  /// A comment mark's or a commented highlight's comment.
  final String? comment;

  /// The mark as written.
  final String markup;

  /// The paragraph holding the mark, verbatim — for display.
  final String context;

  /// Creates an entry.
  const SpecMarkEntry({
    required this.id,
    required this.path,
    this.field,
    required this.line,
    required this.markKind,
    required this.oldText,
    required this.newText,
    this.comment,
    required this.markup,
    required this.context,
  });

  /// The canonical JSON form the conformance corpus pins.
  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'field': field,
    'line': line,
    'markKind': markKind.name,
    'oldText': oldText,
    'newText': newText,
    'comment': comment,
    'markup': markup,
    'context': context,
  };
}

/// What was done to one mark.
class SpecMarkOutcome {
  /// The mark's id at the revision the operation ran on.
  final String id;

  /// The value's path.
  final String path;

  /// The form field, or null for content.
  final String? field;

  /// The 0-based line within the value where the mark opened.
  final int line;

  /// The mark's kind.
  final SpecMarkKind markKind;

  /// Accepted or rejected.
  final SpecMarkDecision decision;

  /// The mark as written.
  final String markup;

  /// The text that replaced it.
  final String result;

  /// Creates an outcome.
  const SpecMarkOutcome({
    required this.id,
    required this.path,
    this.field,
    required this.line,
    required this.markKind,
    required this.decision,
    required this.markup,
    required this.result,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'field': field,
    'line': line,
    'markKind': markKind.name,
    'decision': decision.name,
    'markup': markup,
    'result': result,
  };
}

/// A mark the scanner could not read; it is left as written.
class SpecMarkIssue {
  /// The value's path.
  final String path;

  /// The form field, or null for content.
  final String? field;

  /// The 0-based line within the value.
  final int line;

  /// `unclosed`, `nested` or `noArrow`.
  final String issue;

  /// Creates an issue.
  const SpecMarkIssue({
    required this.path,
    this.field,
    required this.line,
    required this.issue,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'path': path,
    'field': field,
    'line': line,
    'issue': issue,
  };
}

/// The report of a mark operation, for the decision log.
class SpecMarkReport {
  /// What was done, in document order.
  final List<SpecMarkOutcome> applied;

  /// Malformed marks in scope, left as written.
  final List<SpecMarkIssue> malformed;

  /// Creates a report.
  const SpecMarkReport({this.applied = const [], this.malformed = const []});

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'applied': [for (final a in applied) a.toJson()],
    'malformed': [for (final m in malformed) m.toJson()],
  };
}

/// Thrown when an operation names an annotation, value or paragraph that does
/// not exist.
class SpecReviewAnnotationError implements Exception {
  /// What went wrong.
  final String message;

  /// Creates the error.
  SpecReviewAnnotationError(this.message);

  @override
  String toString() => 'SpecReviewAnnotationError: $message';
}

// ---------------------------------------------------------------------------
// Text level: one value.
// ---------------------------------------------------------------------------

const _arrow = '⬆';
const _vs16 = '️';
const _questionOpen = '**❓';
const _combinedOpener = '**❓ Open questions on these fields**';
const _answerLabel = '**Answer:**';
const _emDashSep = ' — ';
const _star = '★';

/// One parsed block of a value (lines [start, end] inclusive).
class _Block {
  final int start;
  final int end;
  final SpecReviewAnnotationKind kind;
  _Block(this.start, this.end, this.kind);
}

/// One question region inside a question block.
class _Question {
  final int header; // value line of the header
  final int regionEnd; // last value line of the region (inclusive)
  final int? answerLine; // value line of `**Answer:**`, or null
  final String id;
  final String topic;
  final bool starred;
  final String text;
  final String answer;
  _Question(
    this.header,
    this.regionEnd,
    this.answerLine,
    this.id,
    this.topic,
    this.starred,
    this.text,
    this.answer,
  );
}

/// One parsed comment block.
class _Comment {
  final _Block block;
  final String? id;
  final String? author;
  final String text;
  final String context;

  /// The first line up to where the text starts (kept by an edit).
  final String headerPrefix;

  /// Where an id is inserted into the first line, and how.
  final int markerEnd;
  _Comment(
    this.block,
    this.id,
    this.author,
    this.text,
    this.context,
    this.headerPrefix,
    this.markerEnd,
  );
}

/// One parsed mark; [start]/[end] are offsets into the value (this runtime's
/// own string units — never exported).
class _Mark {
  final int start;
  final int end;
  final int line;
  final SpecMarkKind kind;
  final String text;
  final String? newText;
  final String? comment;
  _Mark(
    this.start,
    this.end,
    this.line,
    this.kind,
    this.text,
    this.newText,
    this.comment,
  );
}

/// Everything one value holds.
class _Parsed {
  final List<String> lines;
  final List<bool> code; // per line: inside a fenced block (fence lines too)
  final List<_Block> blocks = [];
  final List<_Comment> comments = [];
  final Map<_Block, List<_Question>> questions = {};
  final Map<_Block, bool> combined = {};
  final List<_Mark> marks = [];
  final List<String> malformed = [];

  /// Malformed inline marks as (value line, issue code): `unclosed`,
  /// `nested`, `noArrow`.
  final List<(int, String)> markIssues = [];
  _Parsed(this.lines, this.code);
}

String _lstrip(String s) {
  var i = 0;
  while (i < s.length && (s[i] == ' ' || s[i] == '\t')) {
    i++;
  }
  return s.substring(i);
}

bool _isBlank(String s) => s.trim().isEmpty;

/// The fenced-code flag of every line.
List<bool> _codeLines(List<String> lines) {
  final code = List<bool>.filled(lines.length, false);
  String? fenceChar;
  var fenceLen = 0;
  for (var i = 0; i < lines.length; i++) {
    final t = _lstrip(lines[i]);
    if (fenceChar == null) {
      final c = t.isNotEmpty ? t[0] : '';
      if (c == '`' || c == '~') {
        var n = 0;
        while (n < t.length && t[n] == c) {
          n++;
        }
        if (n >= 3) {
          fenceChar = c;
          fenceLen = n;
          code[i] = true;
        }
      }
    } else {
      code[i] = true;
      var n = 0;
      while (n < t.length && t[n] == fenceChar) {
        n++;
      }
      if (n >= fenceLen && t.substring(n).trim().isEmpty) {
        fenceChar = null;
      }
    }
  }
  return code;
}

bool _isQuoteLine(String line) => _lstrip(line).startsWith('>');

/// The line inside the quote: after `>` and one following space.
String _inner(String line) {
  final t = _lstrip(line);
  var s = t.substring(1);
  if (s.startsWith(' ')) s = s.substring(1);
  return s;
}

_Parsed _parse(String value) {
  final lines = value.split('\n');
  final code = _codeLines(lines);
  final p = _Parsed(lines, code);

  // Blocks.
  var i = 0;
  while (i < lines.length) {
    if (code[i] || !_isQuoteLine(lines[i])) {
      i++;
      continue;
    }
    final s = i;
    while (i + 1 < lines.length && !code[i + 1] && _isQuoteLine(lines[i + 1])) {
      i++;
    }
    final e = i;
    final first = _inner(lines[s]);
    if (first.startsWith(_arrow)) {
      final b = _Block(s, e, SpecReviewAnnotationKind.comment);
      p.blocks.add(b);
      p.comments.add(_parseComment(p, b));
    } else if (first.startsWith(_questionOpen)) {
      final b = _Block(s, e, SpecReviewAnnotationKind.question);
      p.blocks.add(b);
      _parseQuestions(p, b);
    }
    i = e + 1;
  }

  _parseMarks(p);
  return p;
}

String _context(_Parsed p, int blockStart) {
  var k = blockStart - 1;
  while (k >= 0 && (_isBlank(p.lines[k]) || _isQuoteLine(p.lines[k]))) {
    k--;
  }
  if (k < 0) return '';
  final end = k;
  while (k - 1 >= 0 &&
      !_isBlank(p.lines[k - 1]) &&
      !_isQuoteLine(p.lines[k - 1])) {
    k--;
  }
  return p.lines.sublist(k, end + 1).join('\n');
}

_Comment _parseComment(_Parsed p, _Block b) {
  final raw0 = p.lines[b.start];
  var rest = _inner(raw0).substring(_arrow.length);
  if (rest.startsWith(_vs16)) rest = rest.substring(_vs16.length);
  final markerEnd = raw0.length - rest.length;
  rest = _lstrip(rest);
  String? id;
  if (rest.startsWith('**C-')) {
    final close = rest.indexOf('**', 4);
    if (close >= 0) {
      final n = rest.substring(4, close);
      if (RegExp(r'^[1-9][0-9]*$').hasMatch(n)) {
        id = 'C-$n';
      } else {
        p.malformed.add(
          'line ${b.start}: comment id "C-$n" is not C-<number> '
          '(SOM §11.9.1)',
        );
      }
      rest = _lstrip(rest.substring(close + 2));
    }
  }
  String? author;
  if (rest.startsWith('(')) {
    final close = rest.indexOf(')');
    if (close > 0) {
      author = rest.substring(1, close);
      rest = rest.substring(close + 1);
      if (rest.startsWith(':')) rest = rest.substring(1);
      rest = _lstrip(rest);
    }
  } else if (rest.startsWith(':')) {
    rest = _lstrip(rest.substring(1));
  }
  final headerPrefix = raw0.substring(0, raw0.length - rest.length);
  final textLines = [rest];
  for (var k = b.start + 1; k <= b.end; k++) {
    final inner = _inner(p.lines[k]);
    final t = _lstrip(inner);
    if (t.startsWith(_questionOpen) || t.startsWith(_answerLabel)) {
      p.malformed.add(
        'line $k: a comment block holds a question or an answer; the '
        'question goes into its own block after the comment (SOM §11.9.1)',
      );
    }
    textLines.add(inner);
  }
  return _Comment(
    b,
    id,
    author,
    textLines.join('\n').trim(),
    _context(p, b.start),
    headerPrefix,
    markerEnd,
  );
}

/// Parses a question header's remainder after `**❓ `; null when malformed.
({String id, String topic, bool starred, String rest})? _parseHeader(
  String inner,
) {
  final h = inner.substring(_questionOpen.length + 1);
  final sep = h.indexOf(_emDashSep);
  if (sep <= 0) return null;
  final id = h.substring(0, sep);
  if (!RegExp(r'^[A-Z][A-Z0-9]*-[0-9]+$').hasMatch(id)) return null;
  var t = h.substring(sep + _emDashSep.length);
  var starred = false;
  if (t.startsWith('$_star ')) {
    starred = true;
    t = t.substring(_star.length + 1);
  }
  final close = t.indexOf(':**');
  if (close < 0) return null;
  final topic = t.substring(0, close);
  var rest = t.substring(close + 3);
  if (rest.startsWith(' ')) rest = rest.substring(1);
  return (id: id, topic: topic, starred: starred, rest: rest);
}

void _parseQuestions(_Parsed p, _Block b) {
  final inner = [for (var k = b.start; k <= b.end; k++) _inner(p.lines[k])];
  final combined = inner.first.startsWith(_combinedOpener);
  p.combined[b] = combined;
  final headers =
      <int, ({String id, String topic, bool starred, String rest})>{};
  for (var k = 0; k < inner.length; k++) {
    if (!inner[k].startsWith('$_questionOpen ')) continue;
    if (inner[k].startsWith(_combinedOpener)) continue;
    final h = _parseHeader(inner[k]);
    if (h == null) {
      p.malformed.add(
        'line ${b.start + k}: question header is not '
        '"**❓ <ID> — <topic>:**" (SOM §11.9.2)',
      );
      continue;
    }
    headers[k] = h;
  }
  final keys = headers.keys.toList();
  final list = <_Question>[];
  for (var q = 0; q < keys.length; q++) {
    final k = keys[q];
    final h = headers[k]!;
    final regionEnd = q + 1 < keys.length ? keys[q + 1] - 1 : inner.length - 1;
    int? answer;
    for (var m = k + 1; m <= regionEnd; m++) {
      if (inner[m].startsWith(_answerLabel)) {
        answer = m;
        break;
      }
    }
    final textEnd = answer == null ? regionEnd : answer - 1;
    final text = [
      h.rest,
      ...inner.sublist(k + 1, textEnd + 1),
    ].join('\n').trim();
    var answerText = '';
    if (answer != null) {
      answerText = [
        inner[answer].substring(_answerLabel.length),
        ...inner.sublist(answer + 1, regionEnd + 1),
      ].join('\n').trim();
    }
    list.add(
      _Question(
        b.start + k,
        b.start + regionEnd,
        answer == null ? null : b.start + answer,
        h.id,
        h.topic,
        h.starred,
        text,
        answerText,
      ),
    );
  }
  p.questions[b] = list;
}

const _openers = ['{>>', '{==', '{++', '{--', '{~~'];
const _closers = {
  '{>>': '<<}',
  '{==': '==}',
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
};

/// The offset of the first blank line's start after [from] (the paragraph
/// end), or the text length.
int _paragraphEnd(String text, int from) {
  var i = text.indexOf('\n', from);
  while (i >= 0) {
    final next = text.indexOf('\n', i + 1);
    final line = text.substring(i + 1, next < 0 ? text.length : next);
    if (line.trim().isEmpty) return i;
    i = next;
  }
  return text.length;
}

void _parseMarks(_Parsed p) {
  // Offsets of each line's start in the value.
  final lineStart = <int>[];
  var off = 0;
  for (final l in p.lines) {
    lineStart.add(off);
    off += l.length + 1;
  }
  final value = p.lines.join('\n');
  int lineOf(int offset) {
    var lo = 0;
    for (var k = 0; k < lineStart.length; k++) {
      if (lineStart[k] <= offset) lo = k;
    }
    return lo;
  }

  var k = 0;
  while (k < p.lines.length) {
    if (p.code[k]) {
      k++;
      continue;
    }
    // A run of non-code lines is scanned as one segment.
    final segStartLine = k;
    while (k < p.lines.length && !p.code[k]) {
      k++;
    }
    final segStart = lineStart[segStartLine];
    final segEnd = lineStart[k - 1] + p.lines[k - 1].length;
    final seg = value.substring(segStart, segEnd);
    _scanSegment(p, seg, segStart, lineOf);
  }
}

void _scanSegment(_Parsed p, String seg, int base, int Function(int) lineOf) {
  var i = 0;
  while (i < seg.length) {
    final c = seg[i];
    if (c == '`') {
      var n = 0;
      while (i + n < seg.length && seg[i + n] == '`') {
        n++;
      }
      // Find the next run of exactly n backticks.
      var j = i + n;
      var closeAt = -1;
      while (j < seg.length) {
        if (seg[j] == '`') {
          var m = 0;
          while (j + m < seg.length && seg[j + m] == '`') {
            m++;
          }
          if (m == n) {
            closeAt = j;
            break;
          }
          j += m;
        } else {
          j++;
        }
      }
      i = closeAt < 0 ? i + n : closeAt + n;
      continue;
    }
    if (c != '{' || i + 3 > seg.length) {
      i++;
      continue;
    }
    final opener = seg.substring(i, i + 3);
    if (!_openers.contains(opener)) {
      i++;
      continue;
    }
    final closer = _closers[opener]!;
    final close = seg.indexOf(closer, i + 3);
    final pend = _paragraphEnd(seg, i);
    final line = lineOf(base + i);
    if (close < 0 || close > pend) {
      p.malformed.add(
        'line $line: inline mark "$opener" is not closed in its paragraph '
        '(SOM §11.9.3)',
      );
      p.markIssues.add((line, 'unclosed'));
      i += 3;
      continue;
    }
    final inner = seg.substring(i + 3, close);
    if (_openers.any(inner.contains)) {
      p.malformed.add('line $line: inline marks do not nest (SOM §11.9.3)');
      p.markIssues.add((line, 'nested'));
      i = close + 3;
      continue;
    }
    var end = close + 3;
    switch (opener) {
      case '{>>':
        p.marks.add(
          _Mark(
            base + i,
            base + end,
            line,
            SpecMarkKind.comment,
            '',
            null,
            inner.trim(),
          ),
        );
      case '{==':
        String? comment;
        if (seg.startsWith('{>>', end)) {
          final c2 = seg.indexOf('<<}', end + 3);
          if (c2 >= 0 && c2 <= _paragraphEnd(seg, end)) {
            final ci = seg.substring(end + 3, c2);
            if (!_openers.any(ci.contains)) {
              comment = ci.trim();
              end = c2 + 3;
            }
          }
        }
        p.marks.add(
          _Mark(
            base + i,
            base + end,
            line,
            SpecMarkKind.highlight,
            inner.trim(),
            null,
            comment,
          ),
        );
      case '{++':
        p.marks.add(
          _Mark(
            base + i,
            base + end,
            line,
            SpecMarkKind.insertion,
            inner.trim(),
            null,
            null,
          ),
        );
      case '{--':
        p.marks.add(
          _Mark(
            base + i,
            base + end,
            line,
            SpecMarkKind.deletion,
            inner.trim(),
            null,
            null,
          ),
        );
      case '{~~':
        final arrow = inner.indexOf('~>');
        if (arrow < 0) {
          p.malformed.add(
            'line $line: a substitution has no "~>" (SOM §11.9.3)',
          );
          p.markIssues.add((line, 'noArrow'));
          i = end;
          continue;
        }
        p.marks.add(
          _Mark(
            base + i,
            base + end,
            line,
            SpecMarkKind.substitution,
            inner.substring(0, arrow).trim(),
            inner.substring(arrow + 2).trim(),
            null,
          ),
        );
    }
    i = end;
  }
}

/// The annotations of one value, in order: by line, blocks before marks, marks
/// in scan order.
List<SpecReviewAnnotation> _annotationsOf(
  _Parsed p,
  String path,
  String? field,
  String? qualifier,
) {
  final out = <(int, int, int, SpecReviewAnnotation)>[];
  var seq = 0;
  for (final b in p.blocks) {
    if (b.kind == SpecReviewAnnotationKind.comment) {
      final c = p.comments.firstWhere((c) => c.block == b);
      out.add((
        b.start,
        0,
        seq++,
        SpecReviewAnnotation(
          kind: SpecReviewAnnotationKind.comment,
          path: path,
          field: field,
          line: b.start,
          id: c.id,
          qualifiedId: qualifier != null && c.id != null
              ? '$qualifier ${c.id}'
              : null,
          author: c.author,
          text: c.text,
          context: c.context,
        ),
      ));
    } else {
      for (final q in p.questions[b]!) {
        out.add((
          q.header,
          0,
          seq++,
          SpecReviewAnnotation(
            kind: SpecReviewAnnotationKind.question,
            path: path,
            field: field,
            line: q.header,
            id: q.id,
            topic: q.topic,
            starred: q.starred,
            combined: p.combined[b]!,
            text: q.text,
            answer: q.answer,
          ),
        ));
      }
    }
  }
  for (final m in p.marks) {
    out.add((
      m.line,
      1,
      seq++,
      SpecReviewAnnotation(
        kind: SpecReviewAnnotationKind.mark,
        path: path,
        field: field,
        line: m.line,
        markKind: m.kind,
        text: m.text,
        newText: m.newText,
        comment: m.comment,
      ),
    ));
  }
  out.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
    return a.$3.compareTo(b.$3);
  });
  return [for (final e in out) e.$4];
}

/// The paragraphs of a value as (first line, last line), blank-separated and
/// fence-aware (a blank line inside a fenced block does not split).
List<(int, int)> _paragraphs(List<String> lines, List<bool> code) {
  final out = <(int, int)>[];
  var k = 0;
  while (k < lines.length) {
    if (_isBlank(lines[k]) && !code[k]) {
      k++;
      continue;
    }
    final s = k;
    while (k + 1 < lines.length && !(_isBlank(lines[k + 1]) && !code[k + 1])) {
      k++;
    }
    out.add((s, k));
    k++;
  }
  return out;
}

/// Inserts [block] after value line [end] (-1: at the start), one blank line
/// on each side.
String _insertAfterLine(String value, int end, List<String> block) {
  if (value.isEmpty) return block.join('\n');
  final lines = value.split('\n');
  final before = lines.sublist(0, end + 1);
  final rest = lines.sublist(end + 1);
  final out = <String>[...before];
  if (before.isNotEmpty) out.add('');
  out.addAll(block);
  if (rest.isNotEmpty) {
    if (!_isBlank(rest.first)) out.add('');
    out.addAll(rest);
  } else if (before.isEmpty) {
    // nothing
  }
  return out.join('\n');
}

/// Removes value lines [s, e] and one adjacent blank line.
String _removeLines(String value, int s, int e) {
  final lines = value.split('\n');
  var from = s;
  var to = e;
  if (to + 1 < lines.length && _isBlank(lines[to + 1])) {
    to++;
  } else if (from - 1 >= 0 && _isBlank(lines[from - 1])) {
    from--;
  }
  lines.removeRange(from, to + 1);
  final out = lines.join('\n');
  return out.trim().isEmpty ? '' : out;
}

List<String> _quoted(List<String> lines) => [
  for (final l in lines) l.isEmpty ? '>' : '> $l',
];

/// The lines of a comment block.
List<String> formatCommentBlock({
  required String id,
  required String text,
  String? author,
}) {
  final t = text.split('\n');
  final head = StringBuffer('> $_arrow$_vs16 **$id**');
  if (author != null && author.isNotEmpty) head.write(' ($author):');
  if (t.first.isNotEmpty) head.write(' ${t.first}');
  return [head.toString(), ..._quoted(t.sublist(1))];
}

/// The lines of a question block.
List<String> formatQuestionBlock(SpecQuestionDraft q) {
  final t = q.text.split('\n');
  final lines = <String>[
    '> $_questionOpen ${q.id}$_emDashSep${q.starred ? '$_star ' : ''}'
        '${q.topic}:** ${t.first}',
    ..._quoted(t.sublist(1)),
    for (final o in q.options) '> - $o',
  ];
  if (q.recommendation.isNotEmpty || q.assumption.isNotEmpty) {
    lines.add('>');
    if (q.recommendation.isNotEmpty) {
      lines.add('> *Recommendation:* ${q.recommendation}');
    }
    if (q.assumption.isNotEmpty) {
      lines.add('> *Working assumption until answered:* ${q.assumption}');
    }
  }
  lines
    ..add('>')
    ..add('> $_answerLabel');
  return lines;
}

/// Applies a mark's replacement with the whitespace rules of SOM §11.9.3:
/// never join two words, never leave a double space or a space before
/// punctuation, and a mark that was a whole line leaves no blank line.
String _replaceMark(String value, _Mark m, String replacement0) {
  var replacement = replacement0;
  var before = value.substring(0, m.start);
  var after = value.substring(m.end);
  bool isSpace(String c) => c == ' ' || c == '\t';
  String trimEndSpaces(String s) {
    var k = s.length;
    while (k > 0 && isSpace(s[k - 1])) {
      k--;
    }
    return s.substring(0, k);
  }

  String trimStartSpaces(String s) {
    var k = 0;
    while (k < s.length && isSpace(s[k])) {
      k++;
    }
    return s.substring(k);
  }

  if (replacement.isEmpty) {
    final lineStart =
        trimEndSpaces(before).isEmpty || trimEndSpaces(before).endsWith('\n');
    final lineEnd =
        trimStartSpaces(after).isEmpty ||
        trimStartSpaces(after).startsWith('\n');
    if (lineStart && lineEnd) {
      // The mark was the whole line: the line goes, and with it one of the
      // newlines around it; a blank line left doubled is merged.
      before = trimEndSpaces(before);
      after = trimStartSpaces(after);
      if (after.startsWith('\n')) {
        after = after.substring(1);
      } else if (before.endsWith('\n')) {
        before = before.substring(0, before.length - 1);
      }
      if ((before.isEmpty || before.endsWith('\n\n')) &&
          after.startsWith('\n')) {
        after = after.substring(1);
      }
      if (after.isEmpty) {
        while (before.endsWith('\n')) {
          before = before.substring(0, before.length - 1);
        }
      }
      return '$before$after';
    }
    if (before.isNotEmpty && isSpace(before[before.length - 1])) {
      if (after.isNotEmpty && isSpace(after[0])) {
        after = trimStartSpaces(after);
      } else if (after.isEmpty ||
          after.startsWith('\n') ||
          '.,;:!?)]}'.contains(after[0])) {
        before = trimEndSpaces(before);
      }
    } else if ((before.isEmpty || before.endsWith('\n')) &&
        after.isNotEmpty &&
        isSpace(after[0])) {
      after = trimStartSpaces(after);
    }
    return '$before$after';
  }
  // Never join two words: a mark written flush against a word keeps a space
  // on that side.
  if (_wordChar(before) && _wordCharAt(replacement, 0)) {
    replacement = ' $replacement';
  }
  if (_wordCharAt(replacement, replacement.length - 1) &&
      after.isNotEmpty &&
      _wordCharAt(after, 0)) {
    replacement = '$replacement ';
  }
  return '$before$replacement$after';
}

bool _wordChar(String s) => s.isNotEmpty && _wordCharAt(s, s.length - 1);

/// Letters and digits (any script); punctuation and spaces are not.
bool _wordCharAt(String s, int i) {
  if (i < 0 || i >= s.length) return false;
  final c = s[i];
  return c.toLowerCase() != c.toUpperCase() ||
      (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39);
}

String _markReplacement(_Mark m, bool accept) => switch (m.kind) {
  SpecMarkKind.insertion => accept ? m.text : '',
  SpecMarkKind.deletion => accept ? '' : m.text,
  SpecMarkKind.substitution => accept ? m.newText! : m.text,
  SpecMarkKind.highlight => m.text,
  SpecMarkKind.comment => '',
};

/// [value] with every inline mark accepted ([accept]) or rejected, and every
/// highlight and comment mark removed, by the rules of SOM §11.9.3. Marks in
/// code and malformed marks stay as written.
String applyInlineMarksText(String value, {required bool accept}) {
  var v = value;
  final marks = _parse(v).marks;
  for (final m in marks.reversed) {
    v = _replaceMark(v, m, _markReplacement(m, accept));
  }
  return v;
}

/// [value] without any comment block, question block or inline mark (every
/// mark accepted). Plain quotes and code stay.
String stripAnnotationsText(String value) {
  var v = value;
  // Blocks, from the last up, so earlier line numbers stay valid.
  while (true) {
    final p = _parse(v);
    if (p.blocks.isEmpty) break;
    final b = p.blocks.last;
    v = _removeLines(v, b.start, b.end);
  }
  while (true) {
    final p = _parse(v);
    if (p.marks.isEmpty) break;
    final m = p.marks.last;
    v = _replaceMark(v, m, _markReplacement(m, true));
  }
  return v;
}

// ---------------------------------------------------------------------------
// Document level.
// ---------------------------------------------------------------------------

/// The annotations of a document, and the operations that edit them
/// (SOM §11.9). Values are visited in a fixed order — content paths sorted,
/// then form paths sorted with their field names sorted — so "document order"
/// is the same in every runtime.
class SpecReviewAnnotations {
  /// The document.
  final SpecDocument doc;

  /// The document's id or name, written in front of a comment id cited
  /// outside the document (`SBP` → `SBP C-12`); null for bare ids.
  final String? qualifier;

  /// Wraps [doc].
  SpecReviewAnnotations(this.doc, {this.qualifier});

  /// Every value as (path, field or null, text), in document order.
  List<(String, String?, String)> _values() {
    final out = <(String, String?, String)>[];
    for (final path in doc.contentPaths.toList()..sort()) {
      out.add((path, null, doc.content(path) ?? ''));
    }
    for (final path in doc.formPaths.toList()..sort()) {
      for (final f in doc.formFieldNames(path).toList()..sort()) {
        out.add((path, f, doc.formField(path, f) ?? ''));
      }
    }
    return out;
  }

  String _get(String path, String? field) =>
      (field == null ? doc.content(path) : doc.formField(path, field)) ?? '';

  void _set(String path, String? field, String value) {
    if (field == null) {
      doc.setContent(path, value);
    } else {
      doc.setFormField(path, field, value);
    }
  }

  /// Every annotation, in document order.
  List<SpecReviewAnnotation> list() => [
    for (final (path, field, text) in _values())
      ..._annotationsOf(_parse(text), path, field, qualifier),
  ];

  /// The counts a report needs.
  SpecReviewAnnotationCounts counts() {
    var q = 0, open = 0, c = 0, m = 0;
    for (final a in list()) {
      switch (a.kind) {
        case SpecReviewAnnotationKind.question:
          q++;
          if (a.open) open++;
        case SpecReviewAnnotationKind.comment:
          c++;
        case SpecReviewAnnotationKind.mark:
          m++;
      }
    }
    return SpecReviewAnnotationCounts(
      questions: q,
      openQuestions: open,
      answeredQuestions: q - open,
      comments: c,
      marks: m,
    );
  }

  int _highestCommentNumber() {
    var high = 0;
    for (final a in list()) {
      if (a.kind == SpecReviewAnnotationKind.comment && a.id != null) {
        final n = int.parse(a.id!.substring(2));
        if (n > high) high = n;
      }
    }
    return high;
  }

  /// The id the next comment gets: `C-<n>`, n = the highest number in the
  /// document (or [floor], when higher) plus one. Writes nothing.
  String nextCommentId({int floor = 0}) {
    final high = _highestCommentNumber();
    return 'C-${(high > floor ? high : floor) + 1}';
  }

  /// Gives every comment without an id the next one, in document order, and
  /// returns the ids assigned. Nothing else changes.
  List<String> assignCommentIds({int floor = 0}) {
    final high = _highestCommentNumber();
    var next = (high > floor ? high : floor) + 1;
    final assigned = <String>[];
    for (final (path, field, text) in _values()) {
      final p = _parse(text);
      final bare = [
        for (final c in p.comments)
          if (c.id == null) c,
      ];
      if (bare.isEmpty) continue;
      final lines = text.split('\n');
      for (final c in bare) {
        final id = 'C-${next++}';
        assigned.add(id);
        final raw = lines[c.block.start];
        final at = c.markerEnd;
        if (at < raw.length && raw[at] == ' ') {
          lines[c.block.start] =
              '${raw.substring(0, at + 1)}**$id** ${raw.substring(at + 1)}';
        } else if (at >= raw.length) {
          lines[c.block.start] = '$raw **$id**';
        } else {
          lines[c.block.start] =
              '${raw.substring(0, at)} **$id** ${raw.substring(at)}';
        }
      }
      _set(path, field, lines.join('\n'));
    }
    return assigned;
  }

  /// Inserts a comment block after paragraph [afterParagraph] (0-based; -1:
  /// at the start) of the value at [path] / [field], and returns its id —
  /// [id] when given, else the next free one.
  String insertComment({
    required String path,
    String? field,
    required int afterParagraph,
    required String text,
    String? author,
    String? id,
  }) {
    final cid = id ?? nextCommentId();
    final value = _get(path, field);
    final end = _paragraphLastLine(value, afterParagraph);
    _set(
      path,
      field,
      _insertAfterLine(
        value,
        end,
        formatCommentBlock(id: cid, text: text, author: author),
      ),
    );
    return cid;
  }

  /// Inserts a question block after paragraph [afterParagraph] (0-based; -1:
  /// at the start) of the value at [path] / [field].
  void insertQuestion({
    required String path,
    String? field,
    required int afterParagraph,
    required SpecQuestionDraft question,
  }) {
    final value = _get(path, field);
    final end = _paragraphLastLine(value, afterParagraph);
    _set(
      path,
      field,
      _insertAfterLine(value, end, formatQuestionBlock(question)),
    );
  }

  /// Inserts a question block directly after the comment [commentId].
  void insertQuestionAfterComment(
    String commentId,
    SpecQuestionDraft question,
  ) {
    final (path, field, text, c) = _findComment(commentId);
    _set(
      path,
      field,
      _insertAfterLine(text, c.block.end, formatQuestionBlock(question)),
    );
  }

  /// Writes [answer] after the question's `**Answer:**` (empty: reopens it).
  void setAnswer(String questionId, String answer) {
    final (path, field, text, b, q) = _findQuestion(questionId);
    final lines = text.split('\n');
    final a = answer.split('\n');
    final written = [
      answer.isEmpty ? '> $_answerLabel' : '> $_answerLabel ${a.first}',
      if (answer.isNotEmpty) ..._quoted(a.sublist(1)),
    ];
    // The answer runs to the region's last non-empty line.
    var last = q.regionEnd;
    while (last > q.header && _inner(lines[last]).trim().isEmpty) {
      last--;
    }
    if (q.answerLine != null) {
      final from = q.answerLine!;
      final to = last < from ? from : last;
      lines.replaceRange(from, to + 1, written);
    } else {
      lines.insertAll(last + 1, ['>', ...written]);
    }
    _set(path, field, lines.join('\n'));
  }

  /// Replaces a comment's text; its marker, id and author stay as written.
  void editComment(String commentId, String text) {
    final (path, field, value, c) = _findComment(commentId);
    final lines = value.split('\n');
    final t = text.split('\n');
    final block = [
      '${c.headerPrefix}${t.first}'.trimRight(),
      ..._quoted(t.sublist(1)),
    ];
    lines.replaceRange(c.block.start, c.block.end + 1, block);
    _set(path, field, lines.join('\n'));
  }

  /// Removes one comment or question by id (a qualified comment id, `SBP C-12`,
  /// is accepted). A question of a combined block takes only its own lines;
  /// the block goes when its last question does.
  void resolve(String id) {
    final bare = id.contains(' ') ? id.split(' ').last : id;
    if (bare.startsWith('C-')) {
      final (path, field, value, c) = _findComment(bare);
      _set(path, field, _removeLines(value, c.block.start, c.block.end));
      return;
    }
    final (path, field, value, b, q) = _findQuestion(bare);
    final p = _parse(value);
    final qs = p.questions.entries
        .firstWhere((e) => e.key.start == b.start)
        .value;
    if (qs.length == 1) {
      _set(path, field, _removeLines(value, b.start, b.end));
      return;
    }
    final lines = value.split('\n');
    lines.removeRange(q.header, q.regionEnd + 1);
    // A last question leaves the separator `>` lines of the one before it.
    var end = b.end - (q.regionEnd - q.header + 1);
    while (end > b.start && _inner(lines[end]).trim().isEmpty) {
      lines.removeAt(end);
      end--;
    }
    _set(path, field, lines.join('\n'));
  }

  /// Accepts ([accept]) or rejects the inline mark [index] (0-based among the
  /// marks of the value at [path] / [field]).
  void applyMark({
    required String path,
    String? field,
    required int index,
    bool accept = true,
  }) {
    final value = _get(path, field);
    final marks = _parse(value).marks;
    if (index < 0 || index >= marks.length) {
      throw SpecReviewAnnotationError(
        'no inline mark $index at $path${field == null ? '' : ' / $field'}',
      );
    }
    final m = marks[index];
    _set(path, field, _replaceMark(value, m, _markReplacement(m, accept)));
  }

  /// The revision the mark ids are stable for: FNV-1a 64-bit over the UTF-8
  /// of every value in document order (path, NUL, field or empty, NUL, text,
  /// NUL), as 16 lower-case hex digits. Any change to a value changes it.
  String revision() {
    var h = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = (BigInt.one << 64) - BigInt.one;
    void add(String s) {
      for (final b in utf8.encode(s)) {
        h = ((h ^ BigInt.from(b)) * prime) & mask;
      }
      h = ((h ^ BigInt.zero) * prime) & mask;
    }

    for (final (path, field, text) in _values()) {
      add(path);
      add(field ?? '');
      add(text);
    }
    return h.toRadixString(16).padLeft(16, '0');
  }

  static bool _under(String path, String? under) =>
      under == null || path == under || path.startsWith('$under/');

  /// Every inline mark of the document, or of the subtree at [path], in
  /// document order.
  List<SpecMarkEntry> listMarks({String? path}) {
    final out = <SpecMarkEntry>[];
    var n = 0;
    for (final (vpath, field, text) in _values()) {
      final p = _parse(text);
      final paras = _paragraphs(p.lines, p.code);
      for (final m in p.marks) {
        final id = 'M-${++n}';
        if (!_under(vpath, path)) continue;
        final para = paras.firstWhere(
          (r) => r.$1 <= m.line && m.line <= r.$2,
          orElse: () => (m.line, m.line),
        );
        out.add(
          SpecMarkEntry(
            id: id,
            path: vpath,
            field: field,
            line: m.line,
            markKind: m.kind,
            oldText: _markReplacement(m, false),
            newText: _markReplacement(m, true),
            comment: m.comment,
            markup: text.substring(m.start, m.end),
            context: p.lines.sublist(para.$1, para.$2 + 1).join('\n'),
          ),
        );
      }
    }
    return out;
  }

  /// Applies [decide] to every mark in the subtree [under] (null: the whole
  /// document), one write per value.
  SpecMarkReport _applyMarks(
    SpecMarkDecision? Function(String id) decide, {
    String? under,
  }) {
    final applied = <SpecMarkOutcome>[];
    final issues = <SpecMarkIssue>[];
    var n = 0;
    for (final (path, field, text) in _values()) {
      final p = _parse(text);
      final ids = [for (final _ in p.marks) 'M-${++n}'];
      if (!_under(path, under)) continue;
      for (final (line, code) in p.markIssues) {
        issues.add(
          SpecMarkIssue(path: path, field: field, line: line, issue: code),
        );
      }
      var v = text;
      final outcomes = <SpecMarkOutcome>[];
      for (var k = p.marks.length - 1; k >= 0; k--) {
        final d = decide(ids[k]);
        if (d == null || d == SpecMarkDecision.leave) continue;
        final m = p.marks[k];
        final repl = _markReplacement(m, d == SpecMarkDecision.accept);
        outcomes.insert(
          0,
          SpecMarkOutcome(
            id: ids[k],
            path: path,
            field: field,
            line: m.line,
            markKind: m.kind,
            decision: d,
            markup: text.substring(m.start, m.end),
            result: repl,
          ),
        );
        v = _replaceMark(v, m, repl);
      }
      if (v != text) _set(path, field, v);
      applied.addAll(outcomes);
    }
    return SpecMarkReport(applied: applied, malformed: issues);
  }

  /// Applies one decision per named mark in one write. Refused — nothing
  /// changes — when the document is no longer at [revision], or when a
  /// decision names a mark that does not exist. Marks not named, and marks
  /// decided `leave`, stay.
  SpecMarkReport decideMarks(
    Map<String, SpecMarkDecision> decisions, {
    required String revision,
  }) {
    final current = this.revision();
    if (revision != current) {
      throw SpecReviewAnnotationError(
        'the document changed since revision $revision (now $current); '
        'list the marks again',
      );
    }
    final known = {for (final m in listMarks()) m.id};
    for (final id in decisions.keys) {
      if (!known.contains(id)) {
        throw SpecReviewAnnotationError('no inline mark $id in the document');
      }
    }
    return _applyMarks((id) => decisions[id]);
  }

  /// Accepts every inline mark under [path] (null: the whole document).
  SpecMarkReport acceptAllMarks({String? path}) =>
      _applyMarks((_) => SpecMarkDecision.accept, under: path);

  /// Rejects every inline mark under [path] (null: the whole document).
  SpecMarkReport rejectAllMarks({String? path}) =>
      _applyMarks((_) => SpecMarkDecision.reject, under: path);

  /// Removes every annotation and writes the result back: every inline mark
  /// accepted, every comment and question block removed. Malformed marks
  /// stay and are reported.
  SpecMarkReport removeAllAnnotations() {
    final report = acceptAllMarks();
    for (final (path, field, text) in _values()) {
      var v = text;
      while (true) {
        final p = _parse(v);
        if (p.blocks.isEmpty) break;
        final b = p.blocks.last;
        v = _removeLines(v, b.start, b.end);
      }
      if (v != text) _set(path, field, v);
    }
    return report;
  }

  /// Writes [text] at [path] / [field] as a marked change against the value
  /// there now (SOM §11.9.3). A value that already holds change marks is
  /// compared from its original — every mark rejected — so a second edit of
  /// the same passage updates its mark instead of nesting one.
  SpecMarkedChange setMarked({
    required String path,
    String? field,
    required String text,
  }) {
    final current = _get(path, field);
    final base = applyInlineMarksText(current, accept: false);
    final result = markChangeText(base, text);
    _set(path, field, result.text);
    return result;
  }

  /// Marks the value at [path] / [field] as a change against [earlier], an
  /// earlier version of it.
  SpecMarkedChange markAgainst({
    required String path,
    String? field,
    required String earlier,
  }) {
    final result = markChangeText(earlier, _get(path, field));
    _set(path, field, result.text);
    return result;
  }

  /// A copy of the document without any annotation, for reading. The
  /// document itself is unchanged.
  SpecDocument stripped() {
    final copy = SpecDocument()..loadJson(doc.toJson());
    for (final (path, field, text) in _values()) {
      final clean = stripAnnotationsText(text);
      if (clean == text) continue;
      if (field == null) {
        copy.setContent(path, clean);
      } else {
        copy.setFormField(path, field, clean);
      }
    }
    return copy;
  }

  int _paragraphLastLine(String value, int afterParagraph) {
    if (afterParagraph < 0) return -1;
    final lines = value.split('\n');
    final paras = _paragraphs(lines, _codeLines(lines));
    if (value.isEmpty || afterParagraph >= paras.length) {
      throw SpecReviewAnnotationError(
        'the value has ${value.isEmpty ? 0 : paras.length} paragraph(s); '
        'there is no paragraph $afterParagraph',
      );
    }
    return paras[afterParagraph].$2;
  }

  (String, String?, String, _Comment) _findComment(String id) {
    for (final (path, field, text) in _values()) {
      for (final c in _parse(text).comments) {
        if (c.id == id) return (path, field, text, c);
      }
    }
    throw SpecReviewAnnotationError('no comment $id in the document');
  }

  (String, String?, String, _Block, _Question) _findQuestion(String id) {
    for (final (path, field, text) in _values()) {
      final p = _parse(text);
      for (final b in p.blocks) {
        for (final q in p.questions[b] ?? const <_Question>[]) {
          if (q.id == id) return (path, field, text, b, q);
        }
      }
    }
    throw SpecReviewAnnotationError('no question $id in the document');
  }

  /// The instance-tier findings on annotations (SOM §11.9.5), ordered by path.
  List<SpecValidationError> validate() {
    final errors = <SpecValidationError>[];
    final seen = <String>{};
    for (final (path, field, text) in _values()) {
      final p = _parse(text);
      final where = field == null ? path : '$path / $field';
      for (final m in p.malformed) {
        errors.add(
          SpecValidationError(
            path: path,
            code: SpecValidationCode.annotationMalformed,
            message: '$where, $m',
          ),
        );
      }
      if (field != null) {
        for (final b in p.blocks) {
          errors.add(
            SpecValidationError(
              path: path,
              code: SpecValidationCode.annotationMisplaced,
              message:
                  '$where, line ${b.start}: a ${b.kind.name} block sits in a '
                  'form field value; it belongs in the form\'s preamble, '
                  'above the first field (SOM §11.9.4)',
            ),
          );
        }
      }
      final ids = [
        for (final c in p.comments)
          if (c.id != null) c.id!,
        for (final qs in p.questions.values)
          for (final q in qs) q.id,
      ];
      for (final id in ids) {
        if (!seen.add(id)) {
          errors.add(
            SpecValidationError(
              path: path,
              code: SpecValidationCode.duplicateAnnotationId,
              message: '$where: $id is used more than once in the document',
            ),
          );
        }
      }
    }
    final indexed = [for (var i = 0; i < errors.length; i++) (i, errors[i])];
    indexed.sort((a, b) {
      final c = a.$2.path.compareTo(b.$2.path);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}

// ---------------------------------------------------------------------------
// Writing changes as inline marks (SOM §11.9.3, annot5).
// ---------------------------------------------------------------------------

/// A value written as a marked change.
class SpecMarkedChange {
  /// The value with every difference marked.
  final String text;

  /// Whether accepting the marks gives exactly the new value and rejecting
  /// them exactly the old one. False when a difference cannot be marked — a
  /// change inside fenced code, or text that holds mark delimiters — and the
  /// new value was written unmarked instead.
  final bool exact;

  /// Creates a result.
  const SpecMarkedChange(this.text, {required this.exact});

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {'text': text, 'exact': exact};
}

/// One token of a value: a run of whitespace, a word (a run of non-whitespace
/// with inline code spans kept whole) or a fenced code block (its lines).
class _Tok {
  final String text;
  final bool space;
  _Tok(this.text, this.space);
}

bool _isWs(String c) => c == ' ' || c == '\t' || c == '\n';

List<_Tok> _tokens(String value) {
  final out = <_Tok>[];
  void add(String t, bool space) {
    if (t.isEmpty) return;
    if (space && out.isNotEmpty && out.last.space) {
      out[out.length - 1] = _Tok(out.last.text + t, true);
    } else {
      out.add(_Tok(t, space));
    }
  }

  void words(String s) {
    var i = 0;
    while (i < s.length) {
      if (_isWs(s[i])) {
        final st = i;
        while (i < s.length && _isWs(s[i])) {
          i++;
        }
        add(s.substring(st, i), true);
        continue;
      }
      final st = i;
      while (i < s.length && !_isWs(s[i])) {
        if (s[i] == '`') {
          var n = 0;
          while (i + n < s.length && s[i + n] == '`') {
            n++;
          }
          // The matching run of exactly n backticks ends the span.
          var j = i + n;
          var close = -1;
          while (j < s.length) {
            if (s[j] == '`') {
              var m = 0;
              while (j + m < s.length && s[j + m] == '`') {
                m++;
              }
              if (m == n) {
                close = j;
                break;
              }
              j += m;
            } else {
              j++;
            }
          }
          i = close < 0 ? i + n : close + n;
          continue;
        }
        i++;
      }
      add(s.substring(st, i), false);
    }
  }

  final lines = value.split('\n');
  final code = _codeLines(lines);
  var k = 0;
  while (k < lines.length) {
    if (k > 0) add('\n', true);
    final st = k;
    final isCode = code[k];
    while (k + 1 < lines.length && code[k + 1] == isCode) {
      k++;
    }
    final run = lines.sublist(st, k + 1).join('\n');
    if (isCode) {
      add(run, false);
    } else {
      words(run);
    }
    k++;
  }
  return out;
}

/// The diff of two token lists as ops: 0 keep, 1 delete (old), 2 insert
/// (new), with their tokens. LCS over token text; ties prefer the deletion.
List<(int, _Tok)> _diff(List<_Tok> a, List<_Tok> b) {
  final n = a.length, m = b.length;
  final l = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      l[i][j] = a[i].text == b[j].text
          ? l[i + 1][j + 1] + 1
          : (l[i + 1][j] >= l[i][j + 1] ? l[i + 1][j] : l[i][j + 1]);
    }
  }
  final ops = <(int, _Tok)>[];
  var i = 0, j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && a[i].text == b[j].text) {
      ops.add((0, a[i]));
      i++;
      j++;
    } else if (j >= m || (i < n && l[i + 1][j] >= l[i][j + 1])) {
      ops.add((1, a[i]));
      i++;
    } else {
      ops.add((2, b[j]));
      j++;
    }
  }
  return ops;
}

/// [s] with its leading and trailing whitespace removed (spaces, tabs,
/// newlines).
String _trimWs(String s) {
  var a = 0, b = s.length;
  while (a < b && _isWs(s[a])) {
    a++;
  }
  while (b > a && _isWs(s[b - 1])) {
    b--;
  }
  return s.substring(a, b);
}

/// The markup for one region whose old text is [o] and new text is [n] (both
/// trimmed, not both empty).
String _markup(String o, String n) {
  if (o.isEmpty) return '{++ $n ++}';
  if (n.isEmpty) return '{-- $o --}';
  return '{~~ $o ~> $n ~~}';
}

/// The marked emission for the region [r0, r1) of [ops], with the old and the
/// new text around it, or null when no mark round-trips there.
String? _emitRegion(
  List<(int, _Tok)> ops,
  int r0,
  int r1,
  String oldBefore,
  String newBefore,
  String oldAfter,
  String newAfter,
) {
  final o = StringBuffer(), n = StringBuffer();
  for (var k = r0; k < r1; k++) {
    final (kind, t) = ops[k];
    if (kind != 2) o.write(t.text);
    if (kind != 1) n.write(t.text);
  }
  final os = o.toString(), ns = n.toString();
  // Whitespace the two sides share at the edges stays outside the mark.
  var lead = 0;
  while (lead < os.length &&
      lead < ns.length &&
      os[lead] == ns[lead] &&
      _isWs(os[lead])) {
    lead++;
  }
  var trail = 0;
  while (trail < os.length - lead &&
      trail < ns.length - lead &&
      os[os.length - 1 - trail] == ns[ns.length - 1 - trail] &&
      _isWs(os[os.length - 1 - trail])) {
    trail++;
  }
  final oi = os.substring(lead, os.length - trail);
  final ni = ns.substring(lead, ns.length - trail);
  // The mark's content is trimmed when read, so it must already be trimmed;
  // the whitespace still differing is placed outside, on the side whose text
  // keeps it, and the tidy rules then have to restore the other side.
  final ot = _trimWs(oi), nt = _trimWs(ni);
  if (ot.isEmpty && nt.isEmpty) return null;
  final pre = os.substring(0, lead);
  final post = os.substring(os.length - trail);
  String leadWs(String x) => x.substring(0, x.length - x.trimLeft().length);
  String trailWs(String x) => x.substring(x.trimRight().length);
  final candidates = [
    (leadWs(ni), trailWs(ni)),
    (leadWs(oi), trailWs(oi)),
    ('', ''),
    (leadWs(ni), ''),
    ('', trailWs(ni)),
  ];
  for (final (wl, wr) in candidates) {
    final emission = '$pre$wl${_markup(ot, nt)}$wr$post';
    final acc = applyInlineMarksText(
      '$newBefore$emission$newAfter',
      accept: true,
    );
    final rej = applyInlineMarksText(
      '$oldBefore$emission$oldAfter',
      accept: false,
    );
    if (acc == '$newBefore$ns$newAfter' && rej == '$oldBefore$os$oldAfter') {
      return emission;
    }
  }
  return null;
}

/// Marks the token-level differences of [o] → [n], where the text before
/// them is [ob] (old) / [nb] (new) and after them [oa] / [na]. Null when the
/// marks do not round-trip.
String? _markTokens(
  String o,
  String n,
  String ob,
  String nb,
  String oa,
  String na,
) {
  final ops = _diff(_tokens(o), _tokens(n));
  var runs = <(int, int)>[];
  var k = 0;
  while (k < ops.length) {
    if (ops[k].$1 == 0) {
      k++;
      continue;
    }
    final s = k;
    while (k < ops.length && ops[k].$1 != 0) {
      k++;
    }
    runs.add((s, k));
  }
  // Changes separated by at most two unchanged words are one mark.
  final merged = <(int, int)>[];
  for (final r in runs) {
    if (merged.isNotEmpty) {
      var words = 0;
      for (var q = merged.last.$2; q < r.$1; q++) {
        if (!ops[q].$2.space) words++;
      }
      if (words <= 2) {
        merged[merged.length - 1] = (merged.last.$1, r.$2);
        continue;
      }
    }
    merged.add(r);
  }
  runs = merged;

  String side(int from, int to, int skip) {
    final b = StringBuffer();
    for (var q = from; q < to; q++) {
      if (ops[q].$1 != skip) b.write(ops[q].$2.text);
    }
    return b.toString();
  }

  // Left to right; a region that does not round-trip grows by one token on
  // each side and is tried again.
  final out = StringBuffer();
  var pos = 0;
  for (var ri = 0; ri < runs.length; ri++) {
    var (r0, r1) = runs[ri];
    if (r0 < pos) r0 = pos;
    String? emission;
    while (true) {
      emission = _emitRegion(
        ops,
        r0,
        r1,
        '$ob${side(0, r0, 2)}',
        '$nb${side(0, r0, 1)}',
        '${side(r1, ops.length, 2)}$oa',
        '${side(r1, ops.length, 1)}$na',
      );
      if (emission != null || (r0 <= pos && r1 >= ops.length)) break;
      if (r0 > pos) r0--;
      if (r1 < ops.length) r1++;
    }
    if (emission == null) return null;
    out
      ..write(side(pos, r0, 1))
      ..write(emission);
    pos = r1;
    while (ri + 1 < runs.length && runs[ri + 1].$2 <= pos) {
      ri++;
    }
  }
  out.write(side(pos, ops.length, 1));
  final text = out.toString();
  if (applyInlineMarksText('$nb$text$na', accept: true) != '$nb$n$na' ||
      applyInlineMarksText('$ob$text$oa', accept: false) != '$ob$o$oa') {
    return null;
  }
  return text;
}

/// A whole line marked as inserted (`++`) or deleted (`--`): its indentation
/// stays outside the mark; a blank line stays blank.
String _lineMark(String line, String d) {
  final body = line.trimLeft();
  if (body.trim().isEmpty) return line;
  final indent = line.substring(0, line.length - body.length);
  return '$indent{$d ${body.trimRight()} $d}';
}

/// [newValue] with its differences from [oldValue] marked, so that accepting
/// every mark gives exactly [newValue] and rejecting every mark exactly
/// [oldValue] (SOM §11.9.3). The diff runs by line, then by word inside a
/// changed run of lines; words are never split, changes separated by at most
/// two unchanged words are one mark, and nothing inside code is marked.
SpecMarkedChange markChangeText(String oldValue, String newValue) {
  if (oldValue == newValue) {
    return SpecMarkedChange(newValue, exact: true);
  }
  final ol = oldValue.split('\n'), nl = newValue.split('\n');
  final oc = _codeLines(ol), nc = _codeLines(nl);
  final lops = _diff(
    [for (final l in ol) _Tok(l, false)],
    [for (final l in nl) _Tok(l, false)],
  );
  final out = <String>[];
  var exact = true;
  var oi = 0, ni = 0, k = 0;
  String join(List<String> ls) => ls.join('\n');
  while (k < lops.length) {
    if (lops[k].$1 == 0) {
      out.add(nl[ni]);
      oi++;
      ni++;
      k++;
      continue;
    }
    final d0 = oi, n0 = ni;
    while (k < lops.length && lops[k].$1 != 0) {
      if (lops[k].$1 == 1) {
        oi++;
      } else {
        ni++;
      }
      k++;
    }
    final del = ol.sublist(d0, oi), ins = nl.sublist(n0, ni);
    final ob = ol.sublist(0, d0), oa = ol.sublist(oi);
    final nb = nl.sublist(0, n0), na = nl.sublist(ni);
    bool roundTrips(List<String> e) =>
        applyInlineMarksText(join([...nb, ...e, ...na]), accept: true) ==
            newValue &&
        applyInlineMarksText(join([...ob, ...e, ...oa]), accept: false) ==
            oldValue;
    List<String>? emitted;
    final inCode = [
      for (var q = d0; q < oi; q++) oc[q],
      for (var q = n0; q < ni; q++) nc[q],
    ].any((c) => c);
    if (!inCode) {
      final candidates = <List<String>>[];
      if (del.isNotEmpty && ins.isNotEmpty) {
        final t = _markTokens(
          join(del),
          join(ins),
          ob.isEmpty ? '' : '${join(ob)}\n',
          nb.isEmpty ? '' : '${join(nb)}\n',
          oa.isEmpty ? '' : '\n${join(oa)}',
          na.isEmpty ? '' : '\n${join(na)}',
        );
        if (t != null) candidates.add(t.split('\n'));
      }
      final dm = [for (final l in del) _lineMark(l, '--')];
      final im = [for (final l in ins) _lineMark(l, '++')];
      bool blank(String l) => l.trim().isEmpty;
      candidates
        ..add([...dm, ...im])
        ..add([...dm.where((l) => !blank(l)), ...im])
        ..add([...dm, ...im.where((l) => !blank(l))])
        ..add([...dm.where((l) => !blank(l)), ...im.where((l) => !blank(l))]);
      for (final e in candidates) {
        if (roundTrips(e)) {
          emitted = e;
          break;
        }
      }
    }
    if (emitted == null) {
      exact = false;
      out.addAll(ins);
    } else {
      out.addAll(emitted);
    }
  }
  final text = join(out);
  if (exact &&
      (applyInlineMarksText(text, accept: true) != newValue ||
          applyInlineMarksText(text, accept: false) != oldValue)) {
    return SpecMarkedChange(newValue, exact: false);
  }
  return SpecMarkedChange(text, exact: exact);
}
