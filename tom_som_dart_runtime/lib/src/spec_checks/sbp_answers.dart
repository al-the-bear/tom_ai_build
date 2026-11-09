// The answers of the Blueprint's question blocks, read and written through
// the runtime's review-annotation API (`SpecReviewAnnotations`, SOM §11.9.2).
//
// A question block is opened by `> **❓ BQ-nn — topic:**` and carries a
// `> **Answer:**` line; the product owner writes the answer after it, on that
// line and on further lines of the same blockquote. What a question block is,
// where its answer starts and where it ends is the runtime's definition, not
// this file's: a change of the annotation format lands in the runtime alone.
//
// The functions below take plain text — a value of the document, or the whole
// markdown rendition — and hand it to the runtime as the one value of a
// scratch `SpecDocument`, so line numbers are the text's own.
//
// Neutralising a text clears every answer (`setAnswer(id, '')`), so two texts
// that differ only in their answers neutralise to the same text.
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The path of the one value of a scratch document.
const String _value = 'text';

/// The annotations of [text], read as the one value of a scratch document.
SpecReviewAnnotations _annotationsOf(String text) =>
    SpecReviewAnnotations(SpecDocument()..setContent(_value, text));

/// The question blocks of [text], in line order. Each carries its id, its
/// 0-based header [SpecReviewAnnotation.line] and its trimmed
/// [SpecReviewAnnotation.answer].
List<SpecReviewAnnotation> questionsIn(String text) => [
  for (final a in _annotationsOf(text).list())
    if (a.kind == SpecReviewAnnotationKind.question) a,
];

/// The questions of every value of [values] (document path → text), each
/// with the path of the value holding it.
List<SpecReviewAnnotation> questionsInValues(Map<String, String> values) {
  final doc = SpecDocument();
  values.forEach(doc.setContent);
  return [
    for (final a in SpecReviewAnnotations(doc).list())
      if (a.kind == SpecReviewAnnotationKind.question) a,
  ];
}

/// [text] with the answer of question [questionId] set to [answer] (`''`
/// clears it), its label carrying the change time [at] (SOM §11.9.10) or, with
/// none, written untimed as `**Answer:**` — an import writes what its source
/// held, and a time it would add would be its own, not the answer's.
///
/// Throws [SpecReviewAnnotationError] when [text] has no such question, or
/// when [at] is not a time.
String withAnswer(String text, String questionId, String answer, {String? at}) {
  final annotations = _annotationsOf(text)
    ..setAnswer(questionId, answer, at: at ?? _untimed);
  final out = annotations.doc.content(_value) ?? '';
  return at == null ? out.replaceFirst(_untimedLabel, '**Answer:**') : out;
}

/// The placeholder time [withAnswer] writes and then removes when the answer
/// carries none: the runtime always stamps a written team answer.
const String _untimed = '0000-01-01T00:00Z';
const String _untimedLabel = '**Answer ($_untimed):**';

/// The first line of an [answer], as a report shows it.
String firstLineOf(String answer) => answer.split('\n').first.trim();

/// One line of a neutralised text, with the 1-based line number it came from.
class NeutralLine {
  /// Pairs [text] with its source [lineNo].
  const NeutralLine(this.lineNo, this.text);

  /// 1-based line number in the original text.
  final int lineNo;

  /// The (neutralised) line text.
  final String text;
}

/// [text] with every answer cleared, keeping each remaining line's original
/// line number.
///
/// Each question is cleared in the window from its header to the next
/// question's header, so the runtime reads one question at a time and the
/// cost stays linear in the length of [text]. Clearing replaces the answer's
/// lines by a bare answer line; a question without an answer line is left as
/// it is.
List<NeutralLine> neutralise(String text) {
  final lines = text.split('\n');
  final questions = questionsIn(text);
  final out = <NeutralLine>[];
  var next = 0;
  for (var q = 0; q < questions.length; q++) {
    final start = questions[q].line;
    if (start < next) continue;
    final end = q + 1 < questions.length ? questions[q + 1].line : lines.length;
    for (; next < start; next++) {
      out.add(NeutralLine(next + 1, lines[next]));
    }
    final window = lines.sublist(start, end);
    out.addAll(_clearedWindow(window, start, questions[q].id!));
    next = end;
  }
  for (; next < lines.length; next++) {
    out.add(NeutralLine(next + 1, lines[next]));
  }
  return out;
}

/// The lines of [window] (starting at 0-based line [start] of its text) with
/// the answer of [questionId] cleared, numbered by the lines they came from.
List<NeutralLine> _clearedWindow(
  List<String> window,
  int start,
  String questionId,
) {
  final cleared = withAnswer(window.join('\n'), questionId, '').split('\n');
  // setAnswer replaces one run of lines by one line; a longer result means it
  // inserted an answer line the question did not have.
  final removed = window.length - cleared.length;
  if (removed < 0) {
    return [
      for (var k = 0; k < window.length; k++)
        NeutralLine(start + k + 1, window[k]),
    ];
  }
  var changed = 0;
  while (changed < cleared.length && cleared[changed] == window[changed]) {
    changed++;
  }
  return [
    for (var k = 0; k < cleared.length; k++)
      NeutralLine(start + (k <= changed ? k : k + removed) + 1, cleared[k]),
  ];
}

/// [text] neutralised and joined back into one string.
String neutralisedText(String text) =>
    neutralise(text).map((l) => l.text).join('\n');
