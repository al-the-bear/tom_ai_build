// Imports the answers typed into a document's markdown
// rendition back into its YAML.
//
// The YAML is the document of record; the rendition is regenerated from it.
// An answer typed into the rendition is found with the SOM markdown codec
// (`SpecDocumentMarkdown.parse`, SOM § 11) and written into the YAML in place:
//
//   1. Refusal check — the edited markdown, with every answer region
//      neutralised, must equal the rendition of the current YAML neutralised
//      the same way. Anything else means the markdown is stale or carries
//      other edits. `allowOtherEdits` skips this check.
//   2. Changed values — the codec parses both the regenerated rendition and
//      the edited markdown; the values whose staged text differs are the
//      edits. Parsing both sides (rather than comparing the edited parse with
//      the document) cancels out the places where the codec does not
//      round-trip a document exactly. Changes to form
//      fields, lists, headlines or codeSpecs are refused in every mode.
//   3. Answers — a changed value that differs only in its answers yields one
//      answer per changed question. Each is written into the YAML value that
//      holds the question's block, found by its question id — `BQ-nn` or
//      `PR-nn`, unique in the document — with the runtime's `setAnswer`, which
//      replaces exactly the answer.
//   4. Other edits (only with `allowOtherEdits`) — a changed narrative value
//      replaces the YAML value it was parsed from, provided the codec staged
//      it at that value's own path with that value's own text.
//   5. Write-back and verification — only the body lines of the changed
//      `|2-` block scalars are replaced. The new text is decoded again and
//      must yield the old document with exactly the planned values changed.
//
// What a question block and its answer are is read by the runtime's
// review-annotation API (`sbp_answers.dart`), not parsed here.
import 'dart:convert';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'sbp_answers.dart';
import 'sbp_validation.dart';
import 'sbp_yaml_locator.dart';
import 'sbp_yaml_writer.dart';

/// One answer taken from the markdown.
class ImportedAnswer {
  /// Records the answer to [questionId] written into the value at [location].
  const ImportedAnswer({
    required this.questionId,
    required this.location,
    required this.answer,
  });

  /// The question's id (`BQ-125`).
  final String questionId;

  /// The YAML value that holds the question block.
  final ValueLocation location;

  /// The new answer, trimmed; empty when the answer was cleared.
  final String answer;

  /// The report line: `BQ-nn  <section id path>  "<answer first line>"`.
  String get reportLine {
    final first = answer.isEmpty ? '(cleared)' : '"${firstLineOf(answer)}"';
    return '$questionId  ${location.idPath}  $first';
  }
}

/// A narrative value replaced as a whole (only with `allowOtherEdits`).
class ImportedValue {
  /// Records that the value at [location] is replaced.
  const ImportedValue(this.location);

  /// The replaced value's location.
  final ValueLocation location;

  /// The report line: `VALUE  <section id path>`.
  String get reportLine => 'VALUE  ${location.idPath}';
}

/// Thrown when the rewritten YAML does not decode to the planned document.
class ImportVerificationException implements Exception {
  /// Reports the verification failure [message].
  ImportVerificationException(this.message);

  /// What differs.
  final String message;

  @override
  String toString() => 'verification failed: $message';
}

/// The outcome of planning an import.
class ImportPlan {
  ImportPlan._({
    required this.refusals,
    required this.rejections,
    this.answers = const [],
    this.values = const [],
    this.newYaml,
    this.newDocument,
  });

  /// Why the import is refused; empty when it may proceed.
  final List<String> refusals;

  /// The codec's rejections of the edited markdown.
  final List<SpecMarkdownRejection> rejections;

  /// The answers to import, in document order.
  final List<ImportedAnswer> answers;

  /// The narrative values replaced as a whole.
  final List<ImportedValue> values;

  /// The rewritten YAML text, or `null` when nothing changes or the import is
  /// refused.
  final String? newYaml;

  /// The rewritten YAML, decoded and verified.
  final SpecDocument? newDocument;

  /// Whether the import is refused.
  bool get isRefused => refusals.isNotEmpty;

  /// Whether there is anything to write.
  bool get hasChanges => newYaml != null;
}

/// Plans the import of a markdown rendition's answers into a Blueprint YAML.
class AnswerImporter {
  /// Binds the importer to the current [yamlText], its decoded [document] and
  /// the [rendition] of that document.
  AnswerImporter({
    required this.type,
    required this.yamlText,
    required this.document,
    required this.rendition,
    this.allowOtherEdits = false,
  });

  /// Decodes [yamlText] and renders it, then binds an importer to both.
  factory AnswerImporter.forYaml(
    SpecRootDefinition type,
    String yamlText, {
    bool allowOtherEdits = false,
  }) {
    final doc = type.decode(yamlText);
    return AnswerImporter(
      type: type,
      yamlText: yamlText,
      document: doc,
      rendition: type.render(doc),
      allowOtherEdits: allowOtherEdits,
    );
  }

  /// The document's model, root, metadata tree and schema.
  final SpecRootDefinition type;

  /// The current YAML text.
  final String yamlText;

  /// The current YAML, decoded.
  final SpecDocument document;

  /// The rendition of [document].
  final String rendition;

  /// Whether narrative edits other than answers are imported too.
  final bool allowOtherEdits;

  /// How many differing lines a refusal shows per side.
  static const int diffContext = 6;

  /// Plans the import of [editedMarkdown].
  ///
  /// Throws [ImportVerificationException] when the rewritten YAML does not
  /// decode to the planned document.
  ImportPlan plan(String editedMarkdown) {
    final textRefusals = allowOtherEdits
        ? const <String>[]
        : compareNeutralised(rendition, editedMarkdown);
    final codec = SpecDocumentMarkdown(type.model, document);
    final edited = codec.parse(editedMarkdown);
    if (textRefusals.isNotEmpty) {
      return ImportPlan._(
        refusals: textRefusals,
        rejections: edited.rejections,
      );
    }
    return _Planner(this, codec.parse(rendition), edited).run();
  }
}

/// The refusal lines for [edited] against [generated], both neutralised;
/// empty when they are equal.
List<String> compareNeutralised(String generated, String edited) {
  final a = neutralise(generated);
  final b = neutralise(edited);
  var start = 0;
  while (start < a.length &&
      start < b.length &&
      a[start].text == b[start].text) {
    start++;
  }
  if (start == a.length && start == b.length) return const [];
  var suffix = 0;
  while (suffix < a.length - start &&
      suffix < b.length - start &&
      a[a.length - 1 - suffix].text == b[b.length - 1 - suffix].text) {
    suffix++;
  }
  return [
    'the markdown differs from the rendition of the current YAML in more '
        'than its answers (answers neutralised on both sides):',
    ..._diffSide('rendition', a.sublist(start, a.length - suffix)),
    ..._diffSide('markdown ', b.sublist(start, b.length - suffix)),
  ];
}

List<String> _diffSide(String label, List<NeutralLine> lines) => [
  if (lines.isEmpty) '  $label: (no lines)',
  for (final l in lines.take(AnswerImporter.diffContext))
    '  $label line ${l.lineNo}: ${l.text}',
  if (lines.length > AnswerImporter.diffContext)
    '  $label ... ${lines.length - AnswerImporter.diffContext} more line(s)',
];

/// One answer that changed between the two parses.
class _AnswerChange {
  const _AnswerChange(this.questionId, this.before, this.after, this.at);

  final String questionId;

  /// The answer in the rendition and in the edited markdown, trimmed.
  final String before;
  final String after;

  /// The change time the edited markdown's label carries, or null.
  final String? at;
}

class _Planner {
  _Planner(this.importer, this.base, this.edited);

  final AnswerImporter importer;
  final SpecMarkdownResult base;
  final SpecMarkdownResult edited;

  final List<String> refusals = [];
  final List<_AnswerChange> answerChanges = [];
  final Map<String, String> wholeValues = {};
  late final Map<String, ValueLocation> locations = locateValues(
    importer.yamlText,
    importer.type.tree,
  );

  ImportPlan run() {
    _checkRejections();
    _checkStructure();
    _collectContentChanges();
    if (refusals.isNotEmpty) return _refused();
    final newValues = <String, String>{};
    final answers = _applyAnswers(newValues);
    final values = _applyWholeValues(newValues);
    if (refusals.isNotEmpty) return _refused();
    if (newValues.isEmpty) {
      return ImportPlan._(refusals: const [], rejections: edited.rejections);
    }
    final newYaml = _rewrite(newValues);
    return ImportPlan._(
      refusals: const [],
      rejections: edited.rejections,
      answers: answers,
      values: values,
      newYaml: newYaml,
      newDocument: _verify(newYaml, newValues),
    );
  }

  ImportPlan _refused() =>
      ImportPlan._(refusals: refusals, rejections: edited.rejections);

  // ---------------------------------------------------------------------------
  // Finding the changes
  // ---------------------------------------------------------------------------

  void _checkRejections() {
    if (edited.rejections.length > base.rejections.length) {
      refusals.add(
        'the codec rejected ${edited.rejections.length} block(s) of the '
        'markdown (listed above); fix them before importing',
      );
    }
  }

  void _checkStructure() {
    _compareStore('form field', base.forms, edited.forms);
    _compareStore('list', base.lists, edited.lists);
    _compareStore('headline', base.headlines, edited.headlines);
    _compareStore('codeSpec', base.codeSpecs, edited.codeSpecs);
    for (final key in edited.content.keys) {
      if (!base.content.containsKey(key)) {
        refusals.add(
          'new value at `$key` (only existing values can be edited)',
        );
      }
    }
    for (final key in base.content.keys) {
      if (!edited.content.containsKey(key)) {
        refusals.add('value removed at `$key`');
      }
    }
  }

  void _compareStore(
    String what,
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) {
    final keys = {...before.keys, ...after.keys};
    for (final key in keys) {
      if (jsonEncode(before[key]) != jsonEncode(after[key])) {
        refusals.add(
          '$what changed at `$key` (only narrative text is imported)',
        );
      }
    }
  }

  void _collectContentChanges() {
    for (final entry in edited.content.entries) {
      final before = base.content[entry.key];
      if (before == null || before == entry.value) continue;
      if (_isAnswerOnly(before, entry.value)) {
        _collectAnswers(before, entry.value);
      } else if (importer.allowOtherEdits) {
        _collectWholeValue(entry.key, before, entry.value);
      } else {
        refusals.add('`${entry.key}` changed outside its answers');
      }
    }
  }

  bool _isAnswerOnly(String before, String after) =>
      questionsIn(before).isNotEmpty &&
      neutralisedText(before) == neutralisedText(after);

  /// The answers that differ between [before] and [after]. Both neutralise to
  /// the same text, so they hold the same questions in the same order.
  void _collectAnswers(String before, String after) {
    final old = questionsIn(before);
    final now = questionsIn(after);
    for (var i = 0; i < old.length; i++) {
      if (old[i].answer == now[i].answer) continue;
      answerChanges.add(
        _AnswerChange(
          old[i].id!,
          old[i].answer,
          now[i].answer,
          now[i].answerChangedAt,
        ),
      );
    }
  }

  void _collectWholeValue(String path, String before, String after) {
    final location = _sourceOf(path, before);
    if (location == null) {
      refusals.add(
        '`$path` changed, but the codec merges it from several YAML values; '
        'edit it in the YAML',
      );
    } else if (location.role != ValueRole.narrative) {
      refusals.add('`${location.idPath}` is not narrative text');
    } else {
      wholeValues[location.path] = after;
    }
  }

  /// The YAML value the codec parsed [path] from: the value at that path, or
  /// — for a form preamble the codec stages at the form's owner — at
  /// `<path>/content`; `null` when neither holds exactly [parsed].
  ValueLocation? _sourceOf(String path, String parsed) {
    for (final candidate in [path, '$path/content']) {
      final loc = locations[candidate];
      if (loc != null && loc.value == parsed) return loc;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Applying the changes
  // ---------------------------------------------------------------------------

  List<ImportedAnswer> _applyAnswers(Map<String, String> newValues) {
    final owners = _questionOwners();
    final answers = <ImportedAnswer>[];
    for (final change in answerChanges) {
      final owner = owners[change.questionId];
      if (owner == null) {
        refusals.add(
          '${change.questionId}: no single narrative value in the '
          'YAML holds this question',
        );
        continue;
      }
      final current = newValues[owner.path] ?? owner.value;
      final held = [
        for (final q in questionsIn(current))
          if (q.id == change.questionId) q,
      ];
      if (held.length != 1 || held.single.answer != change.before) {
        refusals.add(
          '${change.questionId}: its answer in the YAML differs '
          'from the rendition',
        );
        continue;
      }
      newValues[owner.path] = withAnswer(
        current,
        change.questionId,
        change.after,
        at: change.at,
      );
      answers.add(
        ImportedAnswer(
          questionId: change.questionId,
          location: owner,
          answer: change.after,
        ),
      );
    }
    answers.sort((a, b) => a.location.keyLine.compareTo(b.location.keyLine));
    return answers;
  }

  /// Question id → the narrative value holding its block; questions found in
  /// more than one value are left out.
  Map<String, ValueLocation> _questionOwners() {
    final narrative = {
      for (final loc in locations.values)
        if (loc.role == ValueRole.narrative) loc.path: loc.value,
    };
    final owners = <String, ValueLocation>{};
    final duplicated = <String>{};
    for (final q in questionsInValues(narrative)) {
      final id = q.id!;
      if (owners.containsKey(id) && owners[id]!.path != q.path) {
        duplicated.add(id);
      }
      owners[id] = locations[q.path]!;
    }
    duplicated.forEach(owners.remove);
    return owners;
  }

  List<ImportedValue> _applyWholeValues(Map<String, String> newValues) {
    final values = <ImportedValue>[];
    for (final entry in wholeValues.entries) {
      if (newValues.containsKey(entry.key)) {
        refusals.add(
          '`${entry.key}` is changed both as an answer and as a '
          'whole value',
        );
        continue;
      }
      newValues[entry.key] = entry.value;
      values.add(ImportedValue(locations[entry.key]!));
    }
    return values;
  }

  // ---------------------------------------------------------------------------
  // Write-back and verification
  // ---------------------------------------------------------------------------

  String _rewrite(Map<String, String> newValues) => rewriteValues(
    importer.yamlText,
    [for (final e in newValues.entries) ValueEdit(locations[e.key]!, e.value)],
  );

  SpecDocument _verify(String newYaml, Map<String, String> newValues) {
    final SpecDocument decoded;
    try {
      decoded = importer.type.decode(newYaml);
    } on SpecYamlFormatException catch (e) {
      throw ImportVerificationException(
        'the rewritten YAML does not decode: $e',
      );
    }
    final expected = SpecDocument()
      ..loadJson(importer.document.toJson())
      ..modelVersion = importer.document.modelVersion;
    newValues.forEach(expected.setContent);
    final want = expected.toJson();
    final got = decoded.toJson();
    if (jsonEncode(want) != jsonEncode(got)) {
      throw ImportVerificationException(_firstDifference(want, got));
    }
    return decoded;
  }

  static String _firstDifference(
    Map<String, Object?> want,
    Map<String, Object?> got,
  ) {
    for (final store in {...want.keys, ...got.keys}) {
      final a = (want[store] as Map<Object?, Object?>?) ?? const {};
      final b = (got[store] as Map<Object?, Object?>?) ?? const {};
      for (final key in {...a.keys, ...b.keys}) {
        if (jsonEncode(a[key]) != jsonEncode(b[key])) {
          return 'the rewritten YAML decodes to a different $store value at '
              '`$key`';
        }
      }
    }
    return 'the rewritten YAML decodes to a different document';
  }
}
