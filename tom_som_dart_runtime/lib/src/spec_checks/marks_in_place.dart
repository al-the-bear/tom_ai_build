// Accepts the inline change marks of a `*.docspecs.yaml` in place: every `|2-`
// block scalar is rewritten with `applyInlineMarksText(accept: true)` and every
// other byte stays; a quoted one-line substitution (`"{~~old~>new~~}"`) takes
// its new text. A file whose layout is not the encoder's keeps its layout,
// which a decode → decide → encode would rewrite.
//
// The result is checked value for value against what
// `SpecReviewAnnotations.acceptAllMarks` gives on the decoded document before a
// caller writes it. With [under] (section ids of the YAML keys, `INSC/SYBO`)
// only the marks inside that section are accepted; every value then has to
// equal either its old text or the runtime's accepted text.
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The outcome of [acceptMarksInPlace].
class MarksInPlaceResult {
  /// Binds the rewritten [text] and the figures of the run.
  const MarksInPlaceResult({
    required this.text,
    required this.applied,
    required this.malformed,
    required this.changedValues,
    required this.differences,
    required this.differenceCount,
    required this.marksLeft,
    this.sectionLines,
  });

  /// The YAML with the marks accepted.
  final String text;

  /// How many marks the runtime's `acceptAllMarks` applied on the decoded
  /// document (the reference the rewrite is checked against).
  final int applied;

  /// How many marks the runtime reported malformed.
  final int malformed;

  /// How many values the in-place rewrite changed.
  final int changedValues;

  /// The values where the rewrite and the reference disagree, each a line
  /// naming the value and the two texts (at most ten listed; [differenceCount]
  /// counts all).
  final List<String> differences;

  /// The counts of the review annotations the rewritten document still holds.
  final Map<String, Object?> marksLeft;

  /// With `under`: the 1-based line range of the section, `from-to`.
  final String? sectionLines;

  /// How many values the rewrite and the reference disagree on.
  final int differenceCount;

  /// Whether the rewrite may be written: every value agrees.
  bool get verified => differenceCount == 0;
}

/// An `--under` section path that names no section, as [acceptMarksInPlace]
/// reports it.
class MarksSectionNotFound implements Exception {
  /// Binds the section id not found and the line it was searched under.
  const MarksSectionNotFound(this.sectionId, this.under);

  /// The section id that was not found.
  final String sectionId;

  /// The line of the section the search ran inside.
  final String under;

  @override
  String toString() => 'section $sectionId not found under $under';
}

Map<String, String> _snapshot(SpecDocument d) => {
  for (final p in d.contentPaths) 'C|$p': d.content(p) ?? '',
  for (final p in d.formPaths)
    for (final f in d.formFieldNames(p)) 'F|$p|$f': d.formField(p, f) ?? '',
};

/// Accepts the inline change marks of [yamlText] (decoded against [tree]) in
/// place, only inside the section [under] when given (`/`-separated section
/// ids); see the file comment.
///
/// Throws [MarksSectionNotFound] when [under] names no section.
MarksInPlaceResult acceptMarksInPlace(
  String yamlText,
  SomMetaTree tree, {
  String? under,
}) {
  final orig = _snapshot(SpecDocumentYaml.decode(yamlText, tree).document);
  final expected = SpecDocumentYaml.decode(yamlText, tree).document;
  final report = SpecReviewAnnotations(expected).acceptAllMarks();
  final lines = yamlText.split('\n');
  var from = 0, to = lines.length;
  String? sectionLines;
  if (under != null) {
    for (final id in under.split('/')) {
      final re = RegExp('^( *)${RegExp.escape(id)}( [A-Za-z0-9]+)?:');
      var k = from;
      while (k < to && re.firstMatch(lines[k]) == null) {
        k++;
      }
      if (k >= to) throw MarksSectionNotFound(id, lines[from]);
      final ind = re.firstMatch(lines[k])!.group(1)!.length;
      var e = k + 1;
      while (e < to &&
          (lines[e].isEmpty ||
              lines[e].length - lines[e].trimLeft().length > ind)) {
        e++;
      }
      from = k;
      to = e;
    }
    sectionLines = '${from + 1}-$to';
  }
  final out = <String>[];
  var changed = 0;
  var i = 0;
  while (i < lines.length) {
    final l = lines[i];
    if (i < from || i >= to) {
      out.add(l);
      i++;
      continue;
    }
    final q = RegExp(
      r'^(\s*[A-Za-z][A-Za-z0-9]*: )"(\{~~[^"~]*~>([^"~]*)~~\})"\s*$',
    ).firstMatch(l);
    if (q != null) {
      out.add('${q.group(1)}"${q.group(3)}"');
      changed++;
      i++;
      continue;
    }
    out.add(l);
    i++;
    if (!l.endsWith(': |2-')) continue;
    final col =
        l.length -
        l.trimLeft().length +
        (l.trimLeft().startsWith('- ') ? 2 : 0);
    final ind = ' ' * (col + 2);
    var j = i;
    var lastBody = i - 1;
    while (j < lines.length && (lines[j].isEmpty || lines[j].startsWith(ind))) {
      if (lines[j].isNotEmpty) lastBody = j;
      j++;
    }
    final body = lines.sublist(i, lastBody + 1);
    final value = body
        .map((s) => s.isEmpty ? '' : s.substring(ind.length))
        .join('\n');
    final nv = applyInlineMarksText(value, accept: true);
    if (nv != value) {
      changed++;
      if (nv.isNotEmpty) {
        out.addAll(nv.split('\n').map((s) => s.isEmpty ? '' : '$ind$s'));
      }
    } else {
      out.addAll(body);
    }
    i = lastBody + 1;
  }
  final result = out.join('\n');
  final got = SpecDocumentYaml.decode(result, tree).document;
  final a = _snapshot(expected), b = _snapshot(got);
  final differences = <String>[];
  var count = 0;
  String clip(String? v) =>
      v == null ? 'null' : v.substring(0, v.length.clamp(0, 200));
  for (final k in {...a.keys, ...b.keys}) {
    String n(String? v) => v ?? '';
    if (n(a[k]) != n(b[k]) && (under == null || n(orig[k]) != n(b[k]))) {
      if (count++ < 10) {
        differences.add(
          'DIFF $k\n  runtime: ${clip(a[k])}\n  file:    ${clip(b[k])}',
        );
      }
    }
  }
  return MarksInPlaceResult(
    text: result,
    applied: report.applied.length,
    malformed: report.malformed.length,
    changedValues: changed,
    differences: differences,
    differenceCount: count,
    marksLeft: SpecReviewAnnotations(got).counts().toJson(),
    sectionLines: sectionLines,
  );
}
