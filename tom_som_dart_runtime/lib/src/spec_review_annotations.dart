/// Review annotations in content values (SOM §11.9): comment blocks, question
/// blocks and CriticMarkup inline marks, and the team-review notation built on
/// them (SOM §11.9.8): attribution tokens, individual answers, conflict blocks and
/// `open:` answers.
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

/// The kinds of annotation (SOM §11.9): the three of SOM §11.9.1–11.9.3 and the
/// conflict block a team review adds (SOM §11.9.8).
enum SpecReviewAnnotationKind {
  /// A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`.
  comment,

  /// One question of a question block, `> **❓ BQ-81 — topic:** …`.
  question,

  /// A CriticMarkup inline mark.
  mark,

  /// A conflict block, `> ⚖️ **X-3 — Conflicting changes:** …` (SOM §11.9.8).
  conflict,
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

/// One paragraph of a value (SOM §11.9.1, "Paragraphs"): a run of non-blank
/// lines, where a blank line inside fenced code does not end the run. Its
/// [index] is what `afterParagraph` of the inserts takes.
class SpecParagraph {
  /// The 0-based position among the value's paragraphs.
  final int index;

  /// The 0-based first line within the value.
  final int startLine;

  /// The 0-based last line within the value (inclusive).
  final int endLine;

  /// The paragraph's lines, verbatim, joined with `\n`.
  final String text;

  /// `comment`, `question` or `conflict` when the paragraph opens with an
  /// annotation block of that kind, else null.
  final String? annotation;

  /// Creates a paragraph.
  const SpecParagraph({
    required this.index,
    required this.startLine,
    required this.endLine,
    required this.text,
    this.annotation,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'index': index,
    'startLine': startLine,
    'endLine': endLine,
    'text': text,
    'annotation': annotation,
  };
}

/// One option of a question (SOM §11.9.2): `- (a) text`, or `- **(b)** text`
/// for the recommended one.
class SpecQuestionOption {
  /// The lowercase letter.
  final String letter;

  /// The option's text, its continuation lines joined with one space.
  final String text;

  /// Whether the option is written bold — the recommended one.
  final bool bold;

  /// Creates an option.
  const SpecQuestionOption(this.letter, this.text, {this.bold = false});

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'letter': letter,
    'text': text,
    'bold': bold,
  };
}

/// A reviewer's vote on a mark someone else proposed (SOM §11.9.8): `+id`
/// accepts it, `-id` rejects it.
enum SpecVote {
  /// `+<id>`: the reviewer takes the change.
  accept,

  /// `-<id>`: the reviewer undoes the change.
  reject,
}

/// One reviewer's vote on a mark someone else proposed (SOM §11.9.8).
class SpecMarkVote {
  /// The voter's member id.
  final String member;

  /// `accept` (`+id`) or `reject` (`-id`).
  final SpecVote vote;

  /// Creates a vote.
  const SpecMarkVote(this.member, this.vote);

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {'member': member, 'vote': vote.name};
}

/// One line of individual answers, `**Answer (alice, bob):** (a)`
/// (SOM §11.9.8).
class SpecIndividualAnswer {
  /// The members who gave this answer, in the order written.
  final List<String> members;

  /// The answer, trimmed.
  final String answer;

  /// When the answer was last written (SOM §11.9.10), or null.
  final String? changedAt;

  /// Creates an individual answer.
  const SpecIndividualAnswer(this.members, this.answer, {this.changedAt});

  /// The letter the answer starts with (`(a)` or `**(a)**`), or null.
  String? get answerLetter => _leadingLetter(answer);

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'members': members,
    'answer': answer,
    'answerLetter': answerLetter,
    if (changedAt != null) 'changedAt': changedAt,
  };
}

/// One lettered alternative of a conflict block, `- (a) **alice:** text`
/// (SOM §11.9.8).
class SpecConflictAlternative {
  /// The lowercase letter.
  final String letter;

  /// The members who made this change.
  final List<String> members;

  /// The alternative's text; its continuation lines kept as lines.
  final String text;

  /// Creates an alternative.
  const SpecConflictAlternative(this.letter, this.members, this.text);

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'letter': letter,
    'members': members,
    'text': text,
  };
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

  /// A question's team answer, trimmed; empty when open. For a conflict, its
  /// decision.
  final String answer;

  /// A question's options, in order (empty when it states none).
  final List<SpecQuestionOption> options;

  /// A question's recommended letter: the bold option, else the option that
  /// says "recommended", else the letter of a `*Recommendation:*` line.
  final String? recommended;

  /// The letter a question's team answer starts with (`(b)` or `**(b)**`),
  /// or null; null too for an unresolved answer.
  String? get answerLetter =>
      kind == SpecReviewAnnotationKind.question && !unresolved
      ? _leadingLetter(answer)
      : null;

  /// A conflict's decision letter: `a`…, `base`, or null for rewritten text
  /// or none.
  String? get decisionLetter => kind == SpecReviewAnnotationKind.conflict
      ? _decisionLetter(answer)
      : null;

  /// A mark's kind.
  final SpecMarkKind? markKind;

  /// A substitution's new text.
  final String? newText;

  /// The comment of a comment mark, or of a highlight followed by one.
  final String? comment;

  /// A mark's authors from its attribution token; empty without one.
  final List<String> authors;

  /// A mark's votes from its attribution token; empty without one.
  final List<SpecMarkVote> votes;

  /// A question's individual answers, in the order written.
  final List<SpecIndividualAnswer> answers;

  /// When a comment or mark was last changed (SOM §11.9.10), or null.
  final String? changedAt;

  /// A conflict's `(base)` text.
  final String base;

  /// A conflict's lettered alternatives.
  final List<SpecConflictAlternative> alternatives;

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
    this.options = const [],
    this.recommended,
    this.markKind,
    this.newText,
    this.comment,
    this.authors = const [],
    this.votes = const [],
    this.answers = const [],
    this.base = '',
    this.alternatives = const [],
    this.changedAt,
  });

  /// Whether a question is still open (no team answer written), or a
  /// conflict (no decision written).
  bool get open =>
      (kind == SpecReviewAnnotationKind.question ||
          kind == SpecReviewAnnotationKind.conflict) &&
      answer.isEmpty;

  /// Whether a question's team answer or a conflict's decision begins with
  /// `open:` — answered for a gate, but handed back (SOM §11.9.8).
  bool get unresolved => _isUnresolved(answer);

  /// The canonical JSON form the conformance corpus pins. [team] adds the
  /// members of the team form `team_annotation_cases.json` pins (SOM §11.9.8):
  /// a mark's `authors` and `votes`, a question's `unresolved` and `answers`.
  /// Without it the form is the one of SOM §11.9.1–11.9.7 the older case files
  /// pin.
  Map<String, Object?> toJson({bool team = false}) => switch (kind) {
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
      if (changedAt != null) 'changedAt': changedAt,
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
      if (team) 'unresolved': unresolved,
      'options': [for (final o in options) o.toJson()],
      'recommended': recommended,
      'answerLetter': answerLetter,
      if (team) 'answers': [for (final a in answers) a.toJson()],
    },
    SpecReviewAnnotationKind.conflict => {
      'kind': 'conflict',
      'path': path,
      'field': field,
      'line': line,
      'id': id,
      'qualifiedId': qualifiedId,
      'topic': topic,
      'text': text,
      'base': base,
      'alternatives': [for (final a in alternatives) a.toJson()],
      'decision': answer,
      'decisionLetter': decisionLetter,
      'open': open,
      'unresolved': unresolved,
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
      if (changedAt != null) 'changedAt': changedAt,
      if (team) 'authors': authors,
      if (team) 'votes': [for (final v in votes) v.toJson()],
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

  /// Questions whose team answer begins `open:` (also counted as answered).
  final int unresolvedQuestions;

  /// Conflict blocks.
  final int conflicts;

  /// Conflict blocks without a decision.
  final int openConflicts;

  /// Creates counts.
  const SpecReviewAnnotationCounts({
    this.questions = 0,
    this.openQuestions = 0,
    this.answeredQuestions = 0,
    this.comments = 0,
    this.marks = 0,
    this.unresolvedQuestions = 0,
    this.conflicts = 0,
    this.openConflicts = 0,
  });

  /// The canonical JSON form; [team] adds the three team counts
  /// (SOM §11.9.8).
  Map<String, int> toJson({bool team = false}) => {
    'questions': questions,
    'openQuestions': openQuestions,
    'answeredQuestions': answeredQuestions,
    'comments': comments,
    'marks': marks,
    if (team) 'unresolvedQuestions': unresolvedQuestions,
    if (team) 'conflicts': conflicts,
    if (team) 'openConflicts': openConflicts,
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

  /// The recommended option's letter; that option is written bold.
  final String? recommended;

  /// Creates a draft.
  const SpecQuestionDraft({
    required this.id,
    required this.topic,
    required this.text,
    this.options = const [],
    this.recommendation = '',
    this.assumption = '',
    this.starred = false,
    this.recommended,
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
        recommended: j['recommended'] as String?,
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

  /// The authors its attribution token names (SOM §11.9.8); empty without
  /// one.
  final List<String> authors;

  /// The votes its attribution token records; empty without one.
  final List<SpecMarkVote> votes;

  /// A change comment's quote (SOM §11.9.3): `kind`, `oldText`, `newText`
  /// and `outcome`; null for any other mark. Its [comment] is the text after
  /// the quote.
  final Map<String, Object?>? quotedChange;

  /// A change's attached comment, by id; null without one.
  final String? commentId;

  /// When the mark was last changed (SOM §11.9.10), or null.
  final String? changedAt;

  /// The change an attached change comment is about, by id; null otherwise.
  final String? changeId;

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
    this.authors = const [],
    this.votes = const [],
    this.quotedChange,
    this.commentId,
    this.changeId,
    this.changedAt,
  });

  /// The canonical JSON form the conformance corpus pins; [team] adds the
  /// mark's `authors` and `votes` (SOM §11.9.8). `quotedChange`, `commentId`
  /// and `changeId` appear only on the marks they describe.
  Map<String, Object?> toJson({bool team = false}) => {
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
    if (quotedChange != null) 'quotedChange': quotedChange,
    if (commentId != null) 'commentId': commentId,
    if (changeId != null) 'changeId': changeId,
    if (changedAt != null) 'changedAt': changedAt,
    if (team) 'authors': authors,
    if (team) 'votes': [for (final v in votes) v.toJson()],
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

/// What `removeAllAnnotations` did with one conflict block (SOM §11.9.8).
class SpecConflictOutcome {
  /// The conflict id, `X-<n>`.
  final String id;

  /// The value's path.
  final String path;

  /// The form field, or null for content.
  final String? field;

  /// The 0-based line within the value where the block opened.
  final int line;

  /// The decision as written.
  final String decision;

  /// The text the decision chose.
  final String result;

  /// Creates an outcome.
  const SpecConflictOutcome({
    required this.id,
    required this.path,
    this.field,
    required this.line,
    required this.decision,
    required this.result,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'field': field,
    'line': line,
    'decision': decision,
    'result': result,
  };
}

/// The report of a mark operation, for the decision log.
class SpecMarkReport {
  /// What was done, in document order.
  final List<SpecMarkOutcome> applied;

  /// Malformed marks in scope, left as written.
  final List<SpecMarkIssue> malformed;

  /// The conflicts `removeAllAnnotations` applied, in document order; null
  /// for the mark operations, which do not touch conflicts.
  final List<SpecConflictOutcome>? conflicts;

  /// Creates a report.
  const SpecMarkReport({
    this.applied = const [],
    this.malformed = const [],
    this.conflicts,
  });

  /// The canonical JSON form; [team] adds the applied `conflicts` of a
  /// removal (SOM §11.9.8).
  Map<String, Object?> toJson({bool team = false}) => {
    'applied': [for (final a in applied) a.toJson()],
    'malformed': [for (final m in malformed) m.toJson()],
    if (team && conflicts != null)
      'conflicts': [for (final c in conflicts!) c.toJson()],
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
const _scales = '⚖';
const _decisionLabel = '**Decision:**';
const _unresolvedPrefix = 'open:';

/// The start of an individual answer line, `**Answer (alice, bob):**`.
final _individualAnswer = RegExp(r'^\*\*Answer \(([^)]*)\):\*\*');

/// A member id (SOM §11.9.8): lowercase letters, digits and `_`.
final _memberId = RegExp(r'^[a-z0-9_]+$');

/// Whether [s] is a member id (SOM §11.9.8): lowercase letters, digits and
/// `_`.
bool isReviewMemberId(String s) => _memberId.hasMatch(s);

/// A change time as annotations write it (SOM §11.9.10): minutes with the
/// writer's UTC offset, `2026-11-07T14:05+01:00` or `2026-11-07T13:05Z`.
final _reviewTime = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?:Z|[+-]\d{2}:\d{2})$',
);

/// An ISO 8601 time a caller may pass as `at`: minutes, optional seconds and
/// fraction, and an offset or `Z`.
final _reviewTimeIn = RegExp(
  r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2})(?::\d{2}(?:\.\d+)?)?(Z|[+-]\d{2}:\d{2})$',
);

/// Whether [s] is a change time of the form SOM §11.9.10 fixes.
bool isReviewTime(String s) => _reviewTime.hasMatch(s);

/// [at] as a change time (SOM §11.9.10): seconds and fractions cut, the
/// offset kept as given. Throws [SpecReviewAnnotationError] for any other
/// shape.
String normalizeReviewTime(String at) {
  final m = _reviewTimeIn.firstMatch(at.trim());
  if (m == null) {
    throw SpecReviewAnnotationError(
      '"$at" is not an ISO 8601 time with an offset or Z '
      '(e.g. 2026-11-07T14:05+01:00)',
    );
  }
  return '${m[1]}${m[2]}';
}

/// [now] (default: the system clock) as a change time in its local offset.
String systemReviewTime([DateTime? now]) {
  final t = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final off = t.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final mins = off.inMinutes.abs();
  return '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}'
      'T${two(t.hour)}:${two(t.minute)}$sign${two(mins ~/ 60)}:${two(mins % 60)}';
}

/// [parts] (a header's or an answer's comma-separated parts) split into the
/// parts before a trailing change time and the time (SOM §11.9.10).
(List<String>, String?) _splitTime(List<String> parts) {
  if (parts.isNotEmpty && isReviewTime(parts.last.trim())) {
    return (parts.sublist(0, parts.length - 1), parts.last.trim());
  }
  return (parts, null);
}

bool _isUnresolved(String answer) => answer.startsWith(_unresolvedPrefix);

/// A conflict decision's letter: `a`…, `base`, or null (rewritten text or
/// none).
String? _decisionLetter(String decision) {
  final t = decision.trimLeft();
  if (t.startsWith('(base)') || t.startsWith('**(base)**')) return 'base';
  return _isUnresolved(t) ? null : _leadingLetter(t);
}

/// One `**Answer (<ids>):**` entry of a question (SOM §11.9.8).
class _IndividualAnswer {
  final int line; // value line of the `**Answer (…):**` line
  final int end; // last value line of the entry with text (inclusive)
  final List<String> members;
  final String answer;
  final String? changedAt;
  _IndividualAnswer(
    this.line,
    this.end,
    this.members,
    this.answer,
    this.changedAt,
  );
}

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
  final List<SpecQuestionOption> options;
  final String? recommended;
  final List<_IndividualAnswer> answers;
  _Question(
    this.header,
    this.regionEnd,
    this.answerLine,
    this.id,
    this.topic,
    this.starred,
    this.text,
    this.answer,
    this.options,
    this.recommended,
    this.answers,
  );
}

/// One parsed conflict block (SOM §11.9.8).
class _Conflict {
  final _Block block;

  /// Null when the header is malformed: the block is then not listed.
  final String? id;
  final String topic;
  final String text;

  /// The `(base)` text, or null when the block has none.
  String? base;
  final List<SpecConflictAlternative> alternatives = [];
  String decision = '';
  _Conflict(this.block, this.id, this.topic, this.text);
}

bool _isLetter(String c) =>
    c.length == 1 && c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x7a;

/// The options of a question and its recommended letter (SOM §11.9.2): one
/// option per line, `- (a) …`, the recommended one bold, `- **(b)** …`. The
/// recommended letter is the first bold option's; else the first option's
/// whose text says "recommended"; else the letter a `*Recommendation:*` line
/// names; else none.
(List<SpecQuestionOption>, String?) _parseOptions(List<String> lines) {
  final options = <SpecQuestionOption>[];
  String? letter, text;
  var bold = false;
  void close() {
    if (letter != null) {
      options.add(SpecQuestionOption(letter!, text!.trim(), bold: bold));
    }
    letter = null;
  }

  for (final l in lines) {
    if (l.startsWith('- ')) {
      final r = l.substring(2);
      if (r.length >= 7 &&
          r.startsWith('**(') &&
          _isLetter(r[3]) &&
          r.substring(4, 7) == ')**') {
        close();
        letter = r[3];
        text = r.substring(7);
        bold = true;
        continue;
      }
      if (r.length >= 3 && r[0] == '(' && _isLetter(r[1]) && r[2] == ')') {
        close();
        letter = r[1];
        text = r.substring(3);
        bold = false;
        continue;
      }
    }
    if (letter != null && l.startsWith(' ') && l.trim().isNotEmpty) {
      text = '${text!.trim()} ${l.trim()}';
      continue;
    }
    close();
  }
  close();
  for (final o in options) {
    if (o.bold) return (options, o.letter);
  }
  for (final o in options) {
    if (o.text.toLowerCase().contains('recommended'))
      return (options, o.letter);
  }
  const label = '*Recommendation:*';
  for (final l in lines) {
    final i = l.indexOf(label);
    if (i < 0) continue;
    final x = _leadingLetter(l.substring(i + label.length));
    if (x != null) return (options, x);
  }
  return (options, null);
}

/// The letter of a leading `(x)` or `**(x)**` in [s] (spaces skipped).
String? _leadingLetter(String s) {
  var t = s.trimLeft();
  if (t.startsWith('**')) t = t.substring(2);
  if (t.length >= 3 && t[0] == '(' && _isLetter(t[1]) && t[2] == ')') {
    return t[1];
  }
  return null;
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

  /// The first line up to where the author's parentheses (or the text) start.
  final String beforeAuthor;

  /// When the comment was last changed (SOM §11.9.10), or null.
  final String? changedAt;
  _Comment(
    this.block,
    this.id,
    this.author,
    this.text,
    this.context,
    this.headerPrefix,
    this.markerEnd,
    this.beforeAuthor,
    this.changedAt,
  );
}

/// One parsed mark; [start]/[end] are offsets into the value (this runtime's
/// own string units — never exported). [end] lies after the attribution token
/// when the mark has one, [bodyEnd] always right after the mark itself, so
/// the token can be rewritten in place.
class _Mark {
  final int start;
  int end;
  final int bodyEnd;
  final int line;
  final SpecMarkKind kind;
  final String text;
  final String? newText;
  final String? comment;
  List<String> authors = const [];
  List<SpecMarkVote> votes = const [];

  /// A comment mark's quote of a change (SOM §11.9.3), or null.
  _Quote? quote;

  /// The time in the mark's attribution token (SOM §11.9.10), or null.
  String? changedAt;

  /// The index (among the value's marks) of the change this change comment
  /// is attached to, or null.
  int? changeIndex;

  /// The index of this change's attached comment, or null.
  int? commentIndex;
  _Mark(
    this.start,
    this.end,
    this.line,
    this.kind,
    this.text,
    this.newText,
    this.comment,
  ) : bodyEnd = end;
}

/// The quote a change comment opens with (SOM §11.9.3); offsets are into the
/// value.
class _Quote {
  final SpecMarkKind kind;
  final String oldText;
  final String newText;

  /// `accepted`, `rejected`, or null while the change is open.
  final String? outcome;

  /// Right after the quote's closing delimiter.
  final int delimEnd;

  /// Right after the quote's `]`.
  final int end;

  /// The comment: the text after the quote, trimmed.
  final String comment;
  const _Quote(
    this.kind,
    this.oldText,
    this.newText,
    this.outcome,
    this.delimEnd,
    this.end,
    this.comment,
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'oldText': oldText,
    'newText': newText,
    'outcome': outcome,
  };
}

const _quoteKinds = {
  '++': SpecMarkKind.insertion,
  '--': SpecMarkKind.deletion,
  '~~': SpecMarkKind.substitution,
};

bool _isBlankChar(String c) => c == ' ' || c == '\t';

/// Reads the quote at the start of a comment mark's inner text [s], whose
/// first character is at value offset [at]: the quote, null when [s] opens
/// no quote, or the issue (`unclosed`, `noArrow`) of one that is malformed.
Object? _readQuote(String s, int at) {
  var a = 0;
  while (a < s.length && ' \t\r\n'.contains(s[a])) {
    a++;
  }
  if (a + 3 > s.length || s[a] != '[') return null;
  final d = s.substring(a + 1, a + 3);
  final kind = _quoteKinds[d];
  if (kind == null) return null;
  var j = s.indexOf(d, a + 3);
  while (j >= 0) {
    var t = j + 2;
    while (t < s.length && _isBlankChar(s[t])) {
      t++;
    }
    String? outcome;
    var close = -1;
    if (t < s.length && s[t] == ']') {
      close = t;
    } else if (t < s.length && s[t] == '|') {
      t++;
      while (t < s.length && _isBlankChar(s[t])) {
        t++;
      }
      for (final w in const ['accepted', 'rejected']) {
        if (!s.startsWith(w, t)) continue;
        var u = t + w.length;
        while (u < s.length && _isBlankChar(s[u])) {
          u++;
        }
        if (u < s.length && s[u] == ']') {
          outcome = w;
          close = u;
        }
        break;
      }
    }
    if (close >= 0) {
      final body = s.substring(a + 3, j);
      var oldText = '';
      var newText = '';
      switch (kind) {
        case SpecMarkKind.insertion:
          newText = body.trim();
        case SpecMarkKind.deletion:
          oldText = body.trim();
        default:
          final arrow = body.indexOf('~>');
          if (arrow < 0) return 'noArrow';
          oldText = body.substring(0, arrow).trim();
          newText = body.substring(arrow + 2).trim();
      }
      return _Quote(
        kind,
        oldText,
        newText,
        outcome,
        at + j + 2,
        at + close + 1,
        s.substring(close + 1).trim(),
      );
    }
    j = s.indexOf(d, j + 1);
  }
  return 'unclosed';
}

/// Links each change comment to the change written directly before it whose
/// kind and texts it quotes (SOM §11.9.3).
void _attachChangeComments(List<_Mark> marks) {
  for (var k = 1; k < marks.length; k++) {
    final q = marks[k].quote;
    final c = marks[k - 1];
    if (q == null || q.outcome != null || !_isChangeMark(c.kind)) continue;
    if (c.end != marks[k].start || c.kind != q.kind) continue;
    if (_markReplacement(c, false) != q.oldText ||
        _markReplacement(c, true) != q.newText) {
      continue;
    }
    marks[k].changeIndex = k - 1;
    c.commentIndex = k;
  }
}

/// Everything one value holds.
class _Parsed {
  final List<String> lines;
  final List<bool> code; // per line: inside a fenced block (fence lines too)
  final List<_Block> blocks = [];
  final List<_Comment> comments = [];
  final Map<_Block, List<_Question>> questions = {};
  final Map<_Block, bool> combined = {};
  final Map<_Block, _Conflict> conflicts = {};
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
    } else if (first.startsWith(_scales)) {
      final b = _Block(s, e, SpecReviewAnnotationKind.conflict);
      p.blocks.add(b);
      p.conflicts[b] = _parseConflict(p, b);
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
  String? changedAt;
  final beforeAuthor = raw0.substring(0, raw0.length - rest.length);
  if (rest.startsWith('(')) {
    final close = rest.indexOf(')');
    if (close > 0) {
      final (parts, time) = _splitTime(rest.substring(1, close).split(','));
      changedAt = time;
      final a = parts.join(',').trim();
      author = time == null ? rest.substring(1, close) : (a.isEmpty ? null : a);
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
    if (t.startsWith(_questionOpen) ||
        t.startsWith(_answerLabel) ||
        _individualAnswer.hasMatch(t)) {
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
    beforeAuthor,
    changedAt,
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
    // Every `**Answer` line of the region: the individual ones and the team's.
    final answerLines = [
      for (var m = k + 1; m <= regionEnd; m++)
        if (inner[m].startsWith(_answerLabel) ||
            _individualAnswer.hasMatch(inner[m]))
          m,
    ];
    // An answer runs to the next `**Answer` line or the end of the region.
    int answerEnd(int m) {
      for (final x in answerLines) {
        if (x > m) return x - 1;
      }
      return regionEnd;
    }

    String answerText(int m, int label) => [
      inner[m].substring(label),
      ...inner.sublist(m + 1, answerEnd(m) + 1),
    ].join('\n').trim();
    // The question's text ends before its first answer line of either kind.
    final textEnd = answerLines.isEmpty ? regionEnd : answerLines.first - 1;
    final (options, recommended) = _parseOptions(
      inner.sublist(k + 1, textEnd + 1),
    );
    final text = [
      h.rest,
      ...inner.sublist(k + 1, textEnd + 1),
    ].join('\n').trim();
    int? answer;
    final individual = <_IndividualAnswer>[];
    final answered = <String>{};
    for (final m in answerLines) {
      if (inner[m].startsWith(_answerLabel)) {
        answer ??= m;
        continue;
      }
      final match = _individualAnswer.firstMatch(inner[m])!;
      final (memberParts, answerTime) = _splitTime(match.group(1)!.split(','));
      final members = [for (final x in memberParts) x.trim()];
      for (final member in members) {
        if (!answered.add(member)) {
          p.malformed.add(
            'line ${b.start + m}: $member already answered ${h.id}; a member '
            'answers a question at most once (SOM §11.9.8)',
          );
        }
      }
      var end = answerEnd(m);
      while (end > m && inner[end].trim().isEmpty) {
        end--;
      }
      individual.add(
        _IndividualAnswer(
          b.start + m,
          b.start + end,
          members,
          answerText(m, match.group(0)!.length),
          answerTime,
        ),
      );
    }
    final answerText0 = answer == null
        ? ''
        : answerText(answer, _answerLabel.length);
    list.add(
      _Question(
        b.start + k,
        b.start + regionEnd,
        answer == null ? null : b.start + answer,
        h.id,
        h.topic,
        h.starred,
        text,
        answerText0,
        options,
        recommended,
        individual,
      ),
    );
  }
  p.questions[b] = list;
}

/// `- (base) …`: the base line of a conflict block.
final _conflictBase = RegExp(r'^- \(base\)(?: (.*))?$');

/// `- (a) **alice, bob:** …`: a lettered alternative.
final _conflictAlternative = RegExp(
  r'^- \(([a-z])\)(?: \*\*([^*]*):\*\*)?(?: (.*))?$',
);

/// The header after the marker: `**X-<n> — <topic>:** <text>`.
final _conflictHeader = RegExp(r'^\*\*(X-[1-9][0-9]*) — (.+?):\*\*(?: (.*))?$');

/// A conflict block (SOM §11.9.8): the header, the `(base)` line and the
/// lettered alternatives — each continuing on lines indented under it, its
/// line breaks kept — then `**Decision:**`. A malformed header leaves the
/// block unlisted; a missing base line or alternative is a finding.
_Conflict _parseConflict(_Parsed p, _Block b) {
  final inner = [for (var k = b.start; k <= b.end; k++) _inner(p.lines[k])];
  var rest = inner.first.substring(_scales.length);
  if (rest.startsWith(_vs16)) rest = rest.substring(_vs16.length);
  final header = _conflictHeader.firstMatch(rest.trimLeft());
  final c = _Conflict(
    b,
    header?.group(1),
    header?.group(2) ?? '',
    (header?.group(3) ?? '').trim(),
  );
  if (header == null) {
    p.malformed.add(
      'line ${b.start}: conflict header is not "⚖️ **X-<n> — <topic>:**" '
      '(SOM §11.9.8)',
    );
  }
  var decisionLine = inner.length;
  for (var k = 1; k < inner.length; k++) {
    if (inner[k].startsWith(_decisionLabel)) {
      decisionLine = k;
      break;
    }
  }
  // The open entry: the base (letter null) or an alternative.
  ({String? letter, List<String> members, List<String> lines})? open;
  void close() {
    final o = open;
    if (o == null) return;
    final text = o.lines.join('\n').trim();
    if (o.letter == null) {
      c.base = text;
    } else {
      c.alternatives.add(SpecConflictAlternative(o.letter!, o.members, text));
    }
    open = null;
  }

  for (var k = 1; k < decisionLine; k++) {
    final l = inner[k];
    final base = _conflictBase.firstMatch(l);
    final alt = base == null ? _conflictAlternative.firstMatch(l) : null;
    if (base != null) {
      close();
      open = (letter: null, members: <String>[], lines: [base.group(1) ?? '']);
    } else if (alt != null) {
      close();
      final members = [
        for (final x in (alt.group(2) ?? '').split(','))
          if (x.trim().isNotEmpty) x.trim(),
      ];
      open = (
        letter: alt.group(1),
        members: members,
        lines: [alt.group(3) ?? ''],
      );
    } else if (open != null && l.startsWith(' ')) {
      open!.lines.add(l.startsWith('  ') ? l.substring(2) : _lstrip(l));
    } else {
      close();
    }
  }
  close();
  if (decisionLine < inner.length) {
    c.decision = [
      inner[decisionLine].substring(_decisionLabel.length),
      ...inner.sublist(decisionLine + 1),
    ].join('\n').trim();
  }
  if (header != null && c.base == null) {
    p.malformed.add(
      'line ${b.start}: conflict ${c.id} has no "(base)" line (SOM §11.9.8)',
    );
  }
  if (header != null && c.alternatives.isEmpty) {
    p.malformed.add(
      'line ${b.start}: conflict ${c.id} has no lettered alternative '
      '(SOM §11.9.8)',
    );
  }
  return c;
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
  _attachChangeComments(p.marks);
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
    if (c == '{' && seg.startsWith('{@', i)) {
      // A token that no mark precedes directly (a mark's own token is read
      // with the mark, below).
      p.malformed.add(
        'line ${lineOf(base + i)}: an attribution token "{@" does not follow '
        'a mark directly (SOM §11.9.8)',
      );
      final close = seg.indexOf('}', i + 2);
      i = close < 0 ? i + 2 : close + 1;
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
    final before = p.marks.length;
    switch (opener) {
      case '{>>':
        final m = _Mark(
          base + i,
          base + end,
          line,
          SpecMarkKind.comment,
          '',
          null,
          inner.trim(),
        );
        final q = _readQuote(inner, base + i + 3);
        if (q is _Quote) {
          m.quote = q;
        } else if (q == 'unclosed') {
          p.malformed.add(
            'line $line: the quote of a change comment is not closed; '
            'it is read as a plain comment (SOM §11.9.3)',
          );
        } else if (q == 'noArrow') {
          p.malformed.add(
            'line $line: the quote of a change comment has no "~>"; '
            'it is read as a plain comment (SOM §11.9.3)',
          );
        }
        p.marks.add(m);
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
    if (p.marks.length > before && seg.startsWith('{@', end)) {
      end = _attachToken(p, seg, end, base, p.marks.last);
    }
    i = end;
  }
}

/// Reads the attribution token `{@…}` at [at] (SOM §11.9.8) into [m], which
/// it directly follows, and returns the segment offset after it. The token is
/// part of the mark — its markup, its decision — so `m.end` moves past it. A
/// token that breaks the grammar is still part of the mark (it goes with the
/// mark on a decision) and is a finding; its members are then not listed.
int _attachToken(_Parsed p, String seg, int at, int base, _Mark m) {
  final lineEnd = seg.indexOf('\n', at);
  final close = seg.indexOf('}', at + 2);
  if (close < 0 || (lineEnd >= 0 && close > lineEnd)) {
    p.malformed.add(
      'line ${m.line}: attribution token "{@" is not closed (SOM §11.9.8)',
    );
    return at;
  }
  final read = _readToken(seg.substring(at + 2, close), m.kind);
  m.changedAt = read.$4;
  switch (read) {
    case (String reason, _, _, _):
      p.malformed.add(
        'line ${m.line}: attribution token $reason (SOM §11.9.8)',
      );
    case (null, final authors, final votes, _):
      m.authors = authors;
      m.votes = votes;
  }
  m.end = base + close + 1;
  return close + 1;
}

/// Whether a mark kind is a change, which alone takes votes (SOM §11.9.8).
bool _isChangeMark(SpecMarkKind kind) =>
    kind == SpecMarkKind.insertion ||
    kind == SpecMarkKind.deletion ||
    kind == SpecMarkKind.substitution;

/// The members of a token's inside, `<authors>[ <votes>]`, or (as the first
/// member) the reason it breaks the grammar of SOM §11.9.8.
(String?, List<String>, List<SpecMarkVote>, String?) _readToken(
  String inside,
  SpecMarkKind kind,
) {
  final words = [
    for (final w
        in inside.replaceAll(RegExp(r',\s+'), ',').trim().split(RegExp(r'\s+')))
      if (w.isNotEmpty) w,
  ];
  if (words.isEmpty) return ('is empty', const [], const [], null);
  String? time;
  if (isReviewTime(words.last)) time = words.removeLast();
  final read = _readMembers(words, kind);
  return (read.$1, read.$2, read.$3, time);
}

/// The authors and votes of a token's words (its time taken off), or (as the
/// first member) the reason they break the grammar of SOM §11.9.8.
(String?, List<String>, List<SpecMarkVote>) _readMembers(
  List<String> words,
  SpecMarkKind kind,
) {
  const none = (<String>[], <SpecMarkVote>[]);
  if (words.isEmpty) return (null, none.$1, none.$2);
  final authors = <String>[];
  final votes = <SpecMarkVote>[];
  var k = 0;
  if (!words.first.startsWith('+') && !words.first.startsWith('-')) {
    authors.addAll(words.first.split(','));
    k = 1;
  }
  for (; k < words.length; k++) {
    final w = words[k];
    if (!w.startsWith('+') && !w.startsWith('-')) {
      return ('has "$w" where a vote belongs', none.$1, none.$2);
    }
    votes.add(
      SpecMarkVote(
        w.substring(1),
        w.startsWith('+') ? SpecVote.accept : SpecVote.reject,
      ),
    );
  }
  final seen = <String>{};
  for (final id in [...authors, for (final v in votes) v.member]) {
    if (!_memberId.hasMatch(id)) {
      return ('names "$id", which is not a member id', none.$1, none.$2);
    }
    if (!seen.add(id)) {
      return ('names $id twice, or as author and voter', none.$1, none.$2);
    }
  }
  if (votes.isNotEmpty && !_isChangeMark(kind)) {
    return (
      'carries votes on a ${kind.name} mark, which takes authors only',
      none.$1,
      none.$2,
    );
  }
  return (null, authors, votes);
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
          changedAt: c.changedAt,
        ),
      ));
    } else if (b.kind == SpecReviewAnnotationKind.conflict) {
      final c = p.conflicts[b]!;
      if (c.id == null) continue;
      out.add((
        b.start,
        0,
        seq++,
        SpecReviewAnnotation(
          kind: SpecReviewAnnotationKind.conflict,
          path: path,
          field: field,
          line: b.start,
          id: c.id,
          qualifiedId: qualifier != null ? '$qualifier ${c.id}' : null,
          topic: c.topic,
          text: c.text,
          base: c.base ?? '',
          alternatives: c.alternatives,
          answer: c.decision,
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
            options: q.options,
            recommended: q.recommended,
            answers: [
              for (final a in q.answers)
                SpecIndividualAnswer(
                  a.members,
                  a.answer,
                  changedAt: a.changedAt,
                ),
            ],
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
        authors: m.authors,
        votes: m.votes,
        changedAt: m.changedAt,
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
  String? changedAt,
}) {
  final t = text.split('\n');
  final head = StringBuffer('> $_arrow$_vs16 **$id**');
  final who = _authorAndTime(author, changedAt);
  if (who != null) head.write(' ($who):');
  if (t.first.isNotEmpty) head.write(' ${t.first}');
  return [head.toString(), ..._quoted(t.sublist(1))];
}

/// A comment header's parentheses: the author and the change time, either
/// alone, or null when there is neither (SOM §11.9.10).
String? _authorAndTime(String? author, String? changedAt) {
  final a = author != null && author.isNotEmpty ? author : null;
  if (a == null) return changedAt;
  return changedAt == null ? a : '$a, $changedAt';
}

/// The lines of a question block.
List<String> formatQuestionBlock(SpecQuestionDraft q) {
  final t = q.text.split('\n');
  final lines = <String>[
    '> $_questionOpen ${q.id}$_emDashSep${q.starred ? '$_star ' : ''}'
        '${q.topic}:** ${t.first}',
    ..._quoted(t.sublist(1)),
    for (final o in q.options)
      q.recommended != null && o.startsWith('(${q.recommended})')
          ? '> - **(${q.recommended})**${o.substring(3)}'
          : '> - $o',
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

/// [value] with every inline mark accepted ([accept]) or rejected, as accept
/// all / reject all write it (SOM §11.9.3): change comments stay, an attached
/// one records the outcome; every other highlight and comment mark is
/// removed. Marks in code and malformed marks stay as written.
String decideAllMarksText(String value, {required bool accept}) {
  final marks = _parse(value).marks;
  var v = value;
  for (var k = marks.length - 1; k >= 0; k--) {
    if (marks[k].quote != null) continue;
    v = _decideMark(v, marks, k, accept);
  }
  return v;
}

/// [value] with the mark [k] of [marks] decided; a change's attached comment
/// records the outcome (SOM §11.9.3).
String _decideMark(String value, List<_Mark> marks, int k, bool accept) {
  final m = marks[k];
  var v = value;
  final ci = m.commentIndex;
  if (ci != null) v = _recordOutcome(v, marks[ci].quote!, accept);
  return _replaceMark(v, m, _markReplacement(m, accept));
}

/// [value] with the outcome written into the quote [q]: everything from its
/// closing delimiter to its `]` becomes ` | accepted]` or ` | rejected]`.
String _recordOutcome(String value, _Quote q, bool accept) =>
    '${value.substring(0, q.delimEnd)} | ${accept ? 'accepted' : 'rejected'}]'
    '${value.substring(q.end)}';

/// The trimmed [text] of an inline comment, refused when it is empty or
/// holds a mark delimiter or a blank line.
String _checkInlineComment(String text) {
  final t = text.trim();
  if (t.isEmpty) {
    throw SpecReviewAnnotationError('a comment needs text');
  }
  if ([..._openers, '<<}'].any(t.contains) ||
      RegExp(r'\n[ \t\r]*\n').hasMatch(t)) {
    throw SpecReviewAnnotationError(
      'a comment cannot hold a mark delimiter or a blank line',
    );
  }
  return t;
}

/// The whitespace of the change-comment anchors (SOM §11.9.3).
bool _isAnchorSpace(String c) =>
    c == ' ' || c == '\t' || c == '\r' || c == '\n';

int _nonSpaceCount(String s) {
  var n = 0;
  for (var i = 0; i < s.length; i++) {
    if (!_isAnchorSpace(s[i])) n++;
  }
  return n;
}

/// [after] (a value just written as marks) with an attribution token on every
/// change mark it lacks one on (SOM §11.9.10): the token of the same change
/// in [before] (same kind, old and new text; each used once, in order) when
/// [before] held it, else a new one with [author] and [time].
String _stampMarks(String before, String after, String? author, String time) {
  String key(_Mark m) =>
      '${m.kind.name}\u0000${_markReplacement(m, false)}'
      '\u0000${_markReplacement(m, true)}';
  final old = [
    for (final m in _parse(before).marks)
      if (_isChangeMark(m.kind)) (key(m), before.substring(m.bodyEnd, m.end)),
  ];
  final used = List<bool>.filled(old.length, false);
  final fresh = formatAttributionToken(
    [if (author != null) author],
    const [],
    changedAt: time,
  );
  final inserts = <(int, String)>[];
  for (final m in _parse(after).marks) {
    if (!_isChangeMark(m.kind) || m.end > m.bodyEnd) continue;
    final k = key(m);
    var token = fresh;
    for (var i = 0; i < old.length; i++) {
      if (!used[i] && old[i].$1 == k) {
        used[i] = true;
        token = old[i].$2;
        break;
      }
    }
    if (token.isNotEmpty) inserts.add((m.bodyEnd, token));
  }
  var v = after;
  for (final (at, token) in inserts.reversed) {
    v = '${v.substring(0, at)}$token${v.substring(at)}';
  }
  return v;
}

/// `setMarked` with the value's change comments kept (SOM §11.9.3): taken
/// out of the original, then written back where their anchor falls.
SpecMarkedChange _markKeepingChangeComments(String current, String text) {
  // 1. The original: every mark rejected except the change comments.
  var original = current;
  final marks = _parse(current).marks;
  for (var k = marks.length - 1; k >= 0; k--) {
    if (marks[k].quote != null) continue;
    original = _replaceMark(
      original,
      marks[k],
      _markReplacement(marks[k], false),
    );
  }
  // 2. Each change comment's markup, anchor and leading space.
  final kept = [
    for (final m in _parse(original).marks)
      if (m.quote != null) m,
  ];
  final anchors = <(String, int, bool)>[];
  var counted = 0;
  var from = 0;
  for (final m in kept) {
    counted += _nonSpaceCount(original.substring(from, m.start));
    from = m.end;
    anchors.add((
      original.substring(m.start, m.end),
      counted,
      m.start > 0 && _isBlankChar(original[m.start - 1]),
    ));
  }
  // 3. Removed, compared.
  var base = original;
  for (final m in kept.reversed) {
    base = _replaceMark(base, m, '');
  }
  final result = markChangeText(base, text);
  if (anchors.isEmpty) return result;
  // 4. Written back where k non-whitespace characters have passed.
  final r = result.text;
  final rm = _parse(r).marks;
  int place(int k) {
    if (k == 0) return 0;
    var n = 0;
    var i = 0;
    var mi = 0;
    while (i < r.length) {
      if (mi < rm.length && rm[mi].start == i) {
        final m = rm[mi++];
        n += m.kind == SpecMarkKind.insertion ? 0 : _nonSpaceCount(m.text);
        i = m.end;
        if (n >= k) return i;
        continue;
      }
      if (!_isAnchorSpace(r[i])) n++;
      i++;
      if (n >= k) return i;
    }
    return r.length;
  }

  final at = [for (final a in anchors) place(a.$2)];
  var out = r;
  for (var j = anchors.length - 1; j >= 0; j--) {
    final (markup, _, space) = anchors[j];
    out =
        '${out.substring(0, at[j])}${space ? ' ' : ''}$markup'
        '${out.substring(at[j])}';
  }
  return SpecMarkedChange(out, exact: result.exact);
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
// Team reviews (SOM §11.9.8): individual answers and applying conflicts.
// ---------------------------------------------------------------------------

/// Whether an answer carries anything beyond an option letter (SOM §11.9.8):
/// such a commented answer always gets a line of its own.
bool _isCommentedAnswer(String answer, List<SpecQuestionOption> options) {
  final letter = _leadingLetter(answer);
  if (letter == null) return true;
  final t = answer.trimLeft();
  final bold =
      t.startsWith('**(') && t.length >= 7 && t.substring(4, 7) == ')**';
  final skip = bold ? 7 : (t.startsWith('**') ? 5 : 3);
  final rest = (skip <= t.length ? t.substring(skip) : '').trim();
  if (rest.isEmpty) return false;
  final option = options.where((o) => o.letter == letter).firstOrNull;
  return option == null || rest != option.text;
}

/// The lines of one individual-answer entry.
List<String> _individualAnswerLines(
  List<String> members,
  String answer, [
  String? changedAt,
]) {
  final a = answer.split('\n');
  final who = [...members, if (changedAt != null) changedAt].join(', ');
  return [
    '> **Answer ($who):** ${a.first}'.trimRight(),
    ..._quoted(a.sublist(1)),
  ];
}

/// One individual-answer entry while [_setIndividualAnswer] regroups them;
/// [lines] are its bytes as written, null once it has to be written anew.
class _AnswerEntry {
  final List<String> members;
  final String answer;
  final String? changedAt;
  List<String>? lines;
  _AnswerEntry(this.members, this.answer, this.lines, [this.changedAt]);
}

/// [value] with member [member]'s individual answer to question [q] set to
/// [answer] (SOM §11.9.8): the member leaves the line it was on (a line left
/// empty goes); a non-empty answer that is not commented joins the line whose
/// answer is identical and not commented, at its end, and otherwise gets a
/// new line after the last individual answer. The first individual answer
/// opens the run before the team's `**Answer:**`, with a `>` line between run
/// and team answer, and a run left empty takes that line with it. Entries left
/// alone keep their bytes.
String _setIndividualAnswer(
  String value,
  _Question q,
  String member,
  String answer, [
  String? changedAt,
]) {
  final lines = value.split('\n');
  final entries = [
    for (final a in q.answers)
      _AnswerEntry(
        List.of(a.members),
        a.answer,
        lines.sublist(a.line, a.end + 1),
        a.changedAt,
      ),
  ];
  for (final e in entries) {
    if (e.members.remove(member)) e.lines = null;
  }
  final kept = [
    for (final e in entries)
      if (e.members.isNotEmpty) e,
  ];
  final text = answer.trim();
  if (text.isNotEmpty) {
    final join = _isCommentedAnswer(text, q.options)
        ? null
        : kept
              .where(
                (e) =>
                    e.answer == text &&
                    e.changedAt == changedAt &&
                    !_isCommentedAnswer(e.answer, q.options),
              )
              .firstOrNull;
    if (join != null) {
      join.members.add(member);
      join.lines = null;
    } else {
      kept.add(_AnswerEntry([member], text, null, changedAt));
    }
  }
  final run = [
    for (final e in kept)
      ...e.lines ?? _individualAnswerLines(e.members, e.answer, e.changedAt),
  ];
  if (q.answers.isNotEmpty) {
    final from = q.answers.first.line;
    var to = q.answers.last.end;
    // A run left empty takes its separating `>` line with it.
    if (run.isEmpty &&
        to + 1 < lines.length &&
        _inner(lines[to + 1]).trim().isEmpty) {
      to++;
    }
    lines.replaceRange(from, to + 1, run);
  } else if (run.isNotEmpty) {
    if (q.answerLine != null) {
      lines.insertAll(q.answerLine!, [...run, '>']);
    } else {
      var last = q.regionEnd;
      while (last > q.header && _inner(lines[last]).trim().isEmpty) {
        last--;
      }
      lines.insertAll(last + 1, ['>', ...run]);
    }
  }
  return lines.join('\n');
}

/// Topics of the structural conflicts a merge writes (SOM §11.9.9); their
/// decisions are not text.
const _structuralTopics = {'Item removed', 'Item moved', 'Headline changed'};

/// A decided conflict, as `removeAllAnnotations` found it before any change.
class _DecidedConflict {
  final String path;
  final String? field;

  /// The block's position among the value's conflict blocks.
  final int index;
  final String id;
  final int line;
  final String decision;
  _DecidedConflict(
    this.path,
    this.field,
    this.index,
    this.id,
    this.line,
    this.decision,
  );
}

/// The text a conflict's decision chooses: the base, an alternative, or the
/// rewritten text.
String _chosenText(_Conflict c) {
  final letter = _decisionLetter(c.decision);
  if (letter == 'base') return c.base ?? '';
  if (letter != null) {
    return c.alternatives.firstWhere((a) => a.letter == letter).text;
  }
  return c.decision;
}

/// The text paragraphs (no annotation block) of a parsed value, as
/// (first, last) lines.
List<(int, int)> _textParagraphs(_Parsed p) => [
  for (final r in _paragraphs(p.lines, p.code))
    if (!p.blocks.any((b) => b.start == r.$1)) r,
];

/// [value] with the lines [s, e] replaced by [text].
String _replaceLines(String value, int s, int e, String text) {
  final lines = value.split('\n');
  lines.replaceRange(s, e + 1, text.split('\n'));
  return lines.join('\n');
}

/// [value] with the text paragraph directly before block [b] (annotation
/// blocks between them skipped) replaced by [text]; with none, [text] goes
/// before the block.
String _replaceParagraphBefore(String value, _Block b, String text) {
  final before = [
    for (final r in _textParagraphs(_parse(value)))
      if (r.$2 < b.start) r,
  ];
  if (before.isEmpty) {
    return _insertAfterLine(value, b.start - 1, text.split('\n'));
  }
  final (s, e) = before.last;
  return _replaceLines(value, s, e, text);
}

/// [value] with the run of text paragraphs directly before block [b] — a
/// whole-value unit (SOM §11.9.9) — replaced by [text].
String _replaceTextRun(String value, _Block b, String text) {
  final p = _parse(value);
  final paras = [
    for (final r in _paragraphs(p.lines, p.code))
      if (r.$2 < b.start) r,
  ];
  var k = paras.length;
  while (k > 0 && !p.blocks.any((x) => x.start == paras[k - 1].$1)) {
    k--;
  }
  final run = paras.sublist(k);
  if (run.isEmpty) {
    return _insertAfterLine(value, b.start - 1, text.split('\n'));
  }
  return _replaceLines(value, run.first.$1, run.last.$2, text);
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

  /// The clock the write operations take a change time from when no `at` is
  /// passed (SOM §11.9.10); null: the system clock in the writer's offset.
  final String Function()? clock;

  /// Wraps [doc]. [clock] fixes the change time the writes record (the
  /// conformance drivers pass a fixed one).
  SpecReviewAnnotations(this.doc, {this.qualifier, this.clock});

  /// The change time a write records: [at] normalized, else the clock's.
  String _time(String? at) => at != null
      ? normalizeReviewTime(at)
      : (clock?.call() ?? systemReviewTime());

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
    var q = 0, open = 0, unresolved = 0, c = 0, m = 0, x = 0, openX = 0;
    for (final a in list()) {
      switch (a.kind) {
        case SpecReviewAnnotationKind.question:
          q++;
          if (a.open) open++;
          if (a.unresolved) unresolved++;
        case SpecReviewAnnotationKind.comment:
          c++;
        case SpecReviewAnnotationKind.mark:
          m++;
        case SpecReviewAnnotationKind.conflict:
          x++;
          if (a.open) openX++;
      }
    }
    return SpecReviewAnnotationCounts(
      questions: q,
      openQuestions: open,
      answeredQuestions: q - open,
      comments: c,
      marks: m,
      unresolvedQuestions: unresolved,
      conflicts: x,
      openConflicts: openX,
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
    String? at,
  }) {
    final time = _time(at);
    final cid = id ?? nextCommentId();
    final value = _get(path, field);
    final end = _paragraphLastLine(value, afterParagraph);
    _set(
      path,
      field,
      _insertAfterLine(
        value,
        end,
        formatCommentBlock(
          id: cid,
          text: text,
          author: author,
          changedAt: time,
        ),
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
  /// With [author], writes that member's individual answer instead, grouped
  /// and placed by the rules of SOM §11.9.8 (empty: only takes the member
  /// out); an author that is not a member id is refused.
  void setAnswer(
    String questionId,
    String answer, {
    String? author,
    String? at,
  }) {
    if (author != null && !_memberId.hasMatch(author)) {
      throw SpecReviewAnnotationError(
        '"$author" is not a member id (lowercase letters, digits and _)',
      );
    }
    final (path, field, text, _, q) = _findQuestion(questionId);
    if (author != null) {
      final time = answer.trim().isEmpty ? null : _time(at);
      _set(path, field, _setIndividualAnswer(text, q, author, answer, time));
      return;
    }
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
  void editComment(String commentId, String text, {String? at}) {
    final time = _time(at);
    final (path, field, value, c) = _findComment(commentId);
    final lines = value.split('\n');
    final t = text.split('\n');
    final who = _authorAndTime(c.author, time);
    final block = [
      '${c.beforeAuthor.trimRight()} ($who): ${t.first}'.trimRight(),
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
    _set(path, field, _decideMark(value, marks, index, accept));
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
      final first = n + 1;
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
            comment: m.quote?.comment ?? m.comment,
            markup: text.substring(m.start, m.end),
            context: p.lines.sublist(para.$1, para.$2 + 1).join('\n'),
            authors: m.authors,
            votes: m.votes,
            quotedChange: m.quote?.toJson(),
            commentId: m.commentIndex == null
                ? null
                : 'M-${first + m.commentIndex!}',
            changeId: m.changeIndex == null
                ? null
                : 'M-${first + m.changeIndex!}',
            changedAt: m.changedAt,
          ),
        );
      }
    }
    return out;
  }

  /// Applies [decide] to every mark in the subtree [under] (null: the whole
  /// document), one write per value.
  SpecMarkReport _applyMarks(
    SpecMarkDecision? Function(String id, _Mark mark) decide, {
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
      final decided = [
        for (var k = 0; k < p.marks.length; k++) decide(ids[k], p.marks[k]),
      ];
      bool isDecided(int k) =>
          decided[k] != null && decided[k] != SpecMarkDecision.leave;
      for (var k = p.marks.length - 1; k >= 0; k--) {
        if (!isDecided(k)) continue;
        final d = decided[k]!;
        final m = p.marks[k];
        final repl = _markReplacement(m, d == SpecMarkDecision.accept);
        final ci = m.commentIndex;
        if (ci != null && !isDecided(ci)) {
          v = _recordOutcome(
            v,
            p.marks[ci].quote!,
            d == SpecMarkDecision.accept,
          );
        }
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
    return _applyMarks((id, _) => decisions[id]);
  }

  /// Accepts every inline mark under [path] (null: the whole document),
  /// except change comments, which stay (SOM §11.9.3).
  SpecMarkReport acceptAllMarks({String? path}) => _applyMarks(
    (_, m) => m.quote == null ? SpecMarkDecision.accept : null,
    under: path,
  );

  /// Rejects every inline mark under [path] (null: the whole document),
  /// except change comments, which stay (SOM §11.9.3).
  SpecMarkReport rejectAllMarks({String? path}) => _applyMarks(
    (_, m) => m.quote == null ? SpecMarkDecision.reject : null,
    under: path,
  );

  /// The mark `M-<n>` [markId] with its value, refused when the document is
  /// no longer at [revision] (when given) or holds no such mark.
  (String, String?, String, _Parsed, int) _findMark(
    String markId,
    String? revision,
  ) {
    if (revision != null) {
      final current = this.revision();
      if (revision != current) {
        throw SpecReviewAnnotationError(
          'the document changed since revision $revision (now $current); '
          'list the marks again',
        );
      }
    }
    var n = 0;
    for (final (path, field, text) in _values()) {
      final p = _parse(text);
      for (var k = 0; k < p.marks.length; k++) {
        if ('M-${++n}' == markId) return (path, field, text, p, k);
      }
    }
    throw SpecReviewAnnotationError('no inline mark $markId in the document');
  }

  /// Writes a change comment (SOM §11.9.3) directly after the change mark
  /// [markId], its quote written from the mark and [text] after it, with an
  /// attribution token `{@author}` when [author] is given, and returns the
  /// new comment's id. Refused — nothing changes — for an unknown id, a
  /// stale [revision], a mark that is not a change or already has an
  /// attached comment, a change its quote cannot hold, a [text] that is
  /// empty or holds a mark delimiter or a blank line, and an [author] that
  /// is not a member id.
  String commentChange(
    String markId,
    String text, {
    String? author,
    String? revision,
    String? at,
  }) {
    final time = _time(at);
    final (path, field, value, p, k) = _findMark(markId, revision);
    final m = p.marks[k];
    if (!_isChangeMark(m.kind)) {
      throw SpecReviewAnnotationError(
        '$markId is a ${m.kind.name} mark, not a change',
      );
    }
    if (m.commentIndex != null) {
      throw SpecReviewAnnotationError(
        '$markId already has a comment; edit it instead',
      );
    }
    final comment = _checkInlineComment(text);
    if (author != null && !_memberId.hasMatch(author)) {
      throw SpecReviewAnnotationError('"$author" is not a member id');
    }
    final d = switch (m.kind) {
      SpecMarkKind.insertion => '++',
      SpecMarkKind.deletion => '--',
      _ => '~~',
    };
    final body = m.kind == SpecMarkKind.substitution
        ? '${m.text} ~> ${m.newText}'
        : m.text;
    if (body.contains('$d]') || body.contains('<<}')) {
      throw SpecReviewAnnotationError(
        '$markId holds "$d]" or "<<}", which its quote cannot hold',
      );
    }
    final markup =
        '{>> [$d $body $d] $comment <<}'
        '${formatAttributionToken([if (author != null) author], const [], changedAt: time)}';
    _set(
      path,
      field,
      '${value.substring(0, m.end)}$markup${value.substring(m.end)}',
    );
    return 'M-${int.parse(markId.substring(2)) + 1}';
  }

  /// Replaces the comment of the comment mark, change comment or commented
  /// highlight [markId] with [text] (SOM §11.9.3). A change comment keeps
  /// its quote as written, and the attribution token stays. Refused —
  /// nothing changes — for an unknown id, a stale [revision], a mark that
  /// holds no comment, and a [text] that is empty or holds a mark delimiter
  /// or a blank line.
  void editMarkComment(
    String markId,
    String text, {
    String? revision,
    String? at,
  }) {
    final time = _time(at);
    final (path, field, value, p, k) = _findMark(markId, revision);
    final m = p.marks[k];
    final comment = _checkInlineComment(text);
    final String markup;
    if (m.kind == SpecMarkKind.comment) {
      final q = m.quote;
      final open = m.start + 3;
      markup = q == null
          ? '{>> $comment <<}'
          : '{>> ${value.substring(open, q.end).trimLeft()} $comment <<}';
    } else if (m.kind == SpecMarkKind.highlight && m.comment != null) {
      markup = '{== ${m.text} ==}{>> $comment <<}';
    } else {
      throw SpecReviewAnnotationError('$markId holds no comment');
    }
    final token = formatAttributionToken(m.authors, m.votes, changedAt: time);
    _set(
      path,
      field,
      '${value.substring(0, m.start)}$markup$token${value.substring(m.end)}',
    );
  }

  /// Removes every annotation and writes the result back: every inline mark
  /// accepted, every conflict's decision applied (SOM §11.9.8), every
  /// comment, question and conflict block removed. Malformed marks stay and
  /// are reported. Refused — nothing changes — while a conflict is open,
  /// unresolved (`open:`), malformed, or decided for a letter it has no
  /// alternative for.
  SpecMarkReport removeAllAnnotations() {
    final decided = _decidedConflicts();
    final marks = _applyMarks((_, _) => SpecMarkDecision.accept);
    final outcomes = <SpecConflictOutcome>[];
    for (final (path, field, text) in _values()) {
      var v = text;
      final here = [
        for (final d in decided)
          if (d.path == path && d.field == field) d,
      ];
      if (here.isNotEmpty) v = _applyConflicts(path, field, v, here, outcomes);
      while (true) {
        final p = _parse(v);
        if (p.blocks.isEmpty) break;
        final b = p.blocks.last;
        v = _removeLines(v, b.start, b.end);
      }
      if (v != text) _set(path, field, v);
    }
    return SpecMarkReport(
      applied: marks.applied,
      malformed: marks.malformed,
      conflicts: outcomes,
    );
  }

  /// Every conflict block of the document with the line it opens on, in
  /// document order — or the refusal of [removeAllAnnotations] when one of
  /// them cannot be applied.
  List<_DecidedConflict> _decidedConflicts() {
    final out = <_DecidedConflict>[];
    for (final (path, field, text) in _values()) {
      final p = _parse(text);
      var index = 0;
      for (final b in p.blocks) {
        if (b.kind != SpecReviewAnnotationKind.conflict) continue;
        final c = p.conflicts[b]!;
        final where =
            '$path${field == null ? '' : ' / $field'}, line ${b.start}';
        if (c.id == null || c.base == null || c.alternatives.isEmpty) {
          throw SpecReviewAnnotationError(
            '$where: a malformed conflict block cannot be applied',
          );
        }
        if (c.decision.isEmpty || _isUnresolved(c.decision)) {
          throw SpecReviewAnnotationError(
            '$where: conflict ${c.id} is '
            '${c.decision.isEmpty ? 'open' : 'unresolved'}; decide it before '
            'removing the annotations',
          );
        }
        final letter = _decisionLetter(c.decision);
        if (letter != null &&
            letter != 'base' &&
            !c.alternatives.any((a) => a.letter == letter)) {
          throw SpecReviewAnnotationError(
            '$where: conflict ${c.id} has no alternative ($letter)',
          );
        }
        out.add(
          _DecidedConflict(path, field, index++, c.id!, b.start, c.decision),
        );
      }
    }
    return out;
  }

  /// Applies the decided conflicts of one value (marks already accepted),
  /// from the last block up so earlier line numbers stay valid, and records
  /// each. Where the chosen text goes follows the conflict's text (SOM
  /// §11.9.8, "Applying"): a form field, another value, this value's text
  /// paragraphs, or — the default — the text paragraph directly before the
  /// block.
  String _applyConflicts(
    String path,
    String? field,
    String value,
    List<_DecidedConflict> decided,
    List<SpecConflictOutcome> outcomes,
  ) {
    var v = value;
    final recorded = <SpecConflictOutcome>[];
    final p = _parse(v);
    final conflicts = [
      for (final b in p.blocks)
        if (b.kind == SpecReviewAnnotationKind.conflict) p.conflicts[b]!,
    ];
    for (var k = conflicts.length - 1; k >= 0; k--) {
      final d = decided.firstWhere((x) => x.index == k);
      final c = conflicts[k];
      final result = _chosenText(c);
      recorded.insert(
        0,
        SpecConflictOutcome(
          id: d.id,
          path: path,
          field: field,
          line: d.line,
          decision: d.decision,
          result: result,
        ),
      );
      v = _applyConflict(path, field, v, c, result);
    }
    outcomes.addAll(recorded);
    return v;
  }

  String _applyConflict(
    String path,
    String? field,
    String value,
    _Conflict c,
    String result,
  ) {
    if (_structuralTopics.contains(c.topic)) return value;
    final target = RegExp(r'^(\S+) (\S+)$').firstMatch(c.text);
    if (target != null &&
        doc.formField(target.group(1)!, target.group(2)!) != null) {
      doc.setFormField(target.group(1)!, target.group(2)!, result);
      return value;
    }
    if (field == null && c.text == path) {
      return _replaceTextRun(value, c.block, result);
    }
    if (RegExp(r'^[^\s,]+/[^\s,]+$').hasMatch(c.text) && c.text != path) {
      doc.setContent(c.text, result);
      return value;
    }
    return _replaceParagraphBefore(value, c.block, result);
  }

  /// Writes [text] at [path] / [field] as a marked change against the value
  /// there now (SOM §11.9.3). A value that already holds change marks is
  /// compared from its original — every mark rejected — so a second edit of
  /// the same passage updates its mark instead of nesting one.
  SpecMarkedChange setMarked({
    required String path,
    String? field,
    required String text,
    String? author,
    String? at,
  }) {
    _checkAuthor(author);
    final time = _time(at);
    final current = _get(path, field);
    final result = _markKeepingChangeComments(current, text);
    final stamped = SpecMarkedChange(
      _stampMarks(current, result.text, author, time),
      exact: result.exact,
    );
    _set(path, field, stamped.text);
    return stamped;
  }

  void _checkAuthor(String? author) {
    if (author != null && !_memberId.hasMatch(author)) {
      throw SpecReviewAnnotationError(
        '"$author" is not a member id (lowercase letters, digits and _)',
      );
    }
  }

  /// Marks the value at [path] / [field] as a change against [earlier], an
  /// earlier version of it.
  SpecMarkedChange markAgainst({
    required String path,
    String? field,
    required String earlier,
    String? author,
    String? at,
  }) {
    _checkAuthor(author);
    final time = _time(at);
    final current = _get(path, field);
    final result = markChangeText(earlier, current);
    final stamped = SpecMarkedChange(
      _stampMarks(current, result.text, author, time),
      exact: result.exact,
    );
    _set(path, field, stamped.text);
    return stamped;
  }

  /// The paragraphs of the value at [path] / [field], in order — the units
  /// `afterParagraph` of [insertComment] and [insertQuestion] counts. Throws
  /// [SpecReviewAnnotationError] when the document holds no such value.
  List<SpecParagraph> paragraphs({required String path, String? field}) {
    final value = field == null
        ? doc.content(path)
        : doc.formField(path, field);
    if (value == null) {
      throw SpecReviewAnnotationError(
        'no value at $path${field == null ? '' : ' / $field'}',
      );
    }
    final p = _parse(value);
    final paras = _paragraphs(p.lines, p.code);
    return [
      for (var i = 0; i < paras.length; i++)
        SpecParagraph(
          index: i,
          startLine: paras[i].$1,
          endLine: paras[i].$2,
          text: p.lines.sublist(paras[i].$1, paras[i].$2 + 1).join('\n'),
          annotation: [
            for (final b in p.blocks)
              if (b.start == paras[i].$1) b.kind.name,
          ].firstOrNull,
        ),
    ];
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
        for (final c in p.conflicts.values)
          if (c.id != null) c.id!,
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

// ---------------------------------------------------------------------------
// Text-level building blocks of the merge (SOM §11.9.9). Internal: used by
// `spec_review_merge.dart` only and hidden from the package library.
// ---------------------------------------------------------------------------

/// One paragraph of a value as the merge sees it: text, or an annotation
/// block.
class ReviewPiece {
  /// The annotation kind of the block the paragraph opens with; null for a
  /// text paragraph.
  final SpecReviewAnnotationKind? kind;

  /// The paragraph's lines, verbatim.
  final String text;

  /// A comment's id (null without one), a conflict's id (null when
  /// malformed).
  final String? id;

  /// A comment's author, null without one.
  final String? author;

  /// A comment's text.
  final String commentText;

  /// A comment's change time (SOM §11.9.10), null without one.
  final String? changedAt;

  /// The ids of a question block's questions.
  final List<String> questionIds;

  /// Creates a piece.
  const ReviewPiece({
    required this.kind,
    required this.text,
    this.id,
    this.author,
    this.commentText = '',
    this.questionIds = const [],
    this.changedAt,
  });

  /// Whether the paragraph is text, not an annotation block.
  bool get isText => kind == null;
}

/// The paragraphs of [value] (SOM §11.9.1), each classified.
List<ReviewPiece> reviewPieces(String value) {
  if (value.isEmpty) return const [];
  final p = _parse(value);
  return [
    for (final (s, e) in _paragraphs(p.lines, p.code))
      _piece(p, p.blocks.where((x) => x.start == s).firstOrNull, s, e),
  ];
}

ReviewPiece _piece(_Parsed p, _Block? b, int s, int e) {
  final comment = b == null
      ? null
      : p.comments.where((c) => c.block == b).firstOrNull;
  return ReviewPiece(
    kind: b?.kind,
    text: p.lines.sublist(s, e + 1).join('\n'),
    id: comment?.id ?? (b == null ? null : p.conflicts[b]?.id),
    author: comment?.author,
    commentText: comment?.text ?? '',
    changedAt: comment?.changedAt,
    questionIds: [
      if (b != null)
        for (final q in p.questions[b] ?? const <_Question>[]) q.id,
    ],
  );
}

/// One inline mark of a value, with what its decisions leave.
class ReviewMark {
  /// Where the mark starts in the value.
  final int start;

  /// Where the mark ends, after its attribution token.
  final int end;

  /// Where the mark itself ends, before its attribution token.
  final int bodyEnd;

  /// The mark's kind.
  final SpecMarkKind kind;

  /// The mark as written, its attribution token included.
  final String markup;

  /// Its token's authors.
  final List<String> authors;

  /// Its token's votes.
  final List<SpecMarkVote> votes;

  /// Its token's change time (SOM §11.9.10), or null.
  final String? changedAt;

  /// The text accepting it leaves.
  final String accepted;

  /// The text rejecting it leaves.
  final String rejected;

  /// Creates a mark.
  const ReviewMark({
    required this.start,
    required this.end,
    required this.bodyEnd,
    required this.kind,
    required this.markup,
    required this.authors,
    required this.votes,
    required this.accepted,
    required this.rejected,
    this.changedAt,
  });

  /// Whether the mark carries an attribution token.
  bool get hasToken => end > bodyEnd;
}

/// The inline marks of [value], in order (marks in code are not marks).
List<ReviewMark> reviewMarks(String value) => [
  for (final m in _parse(value).marks)
    ReviewMark(
      start: m.start,
      end: m.end,
      bodyEnd: m.bodyEnd,
      kind: m.kind,
      markup: value.substring(m.start, m.end),
      authors: m.authors,
      votes: m.votes,
      accepted: _markReplacement(m, true),
      rejected: _markReplacement(m, false),
      changedAt: m.changedAt,
    ),
];

/// [value] with the marks [decisions] names (by index into [reviewMarks])
/// accepted (true) or rejected (false), by the whitespace rules of
/// SOM §11.9.3.
String decideReviewMarks(String value, Map<int, bool> decisions) {
  final marks = _parse(value).marks;
  var v = value;
  for (var k = marks.length - 1; k >= 0; k--) {
    final accept = decisions[k];
    if (accept == null) continue;
    v = _replaceMark(v, marks[k], _markReplacement(marks[k], accept));
  }
  return v;
}

/// The attribution token for [authors], [votes] and [changedAt],
/// `{@agent +alice -bob 2026-11-07T14:05+01:00}` (SOM §11.9.8, §11.9.10);
/// empty when there is nothing to write.
String formatAttributionToken(
  List<String> authors,
  List<SpecMarkVote> votes, {
  String? changedAt,
}) {
  final parts = [
    if (authors.isNotEmpty) authors.join(','),
    for (final x in votes)
      '${x.vote == SpecVote.accept ? '+' : '-'}${x.member}',
    if (changedAt != null) changedAt,
  ];
  return parts.isEmpty ? '' : '{@${parts.join(' ')}}';
}

/// [value] with mark [m]'s token replaced by one for [authors] and [votes].
String withAttribution(
  String value,
  ReviewMark m,
  List<String> authors,
  List<SpecMarkVote> votes,
) =>
    value.substring(0, m.bodyEnd) +
    formatAttributionToken(authors, votes, changedAt: m.changedAt) +
    value.substring(m.end);

/// The team answer of every question of [value], by id (the first, when an
/// id repeats).
Map<String, String> reviewTeamAnswers(String value) {
  final out = <String, String>{};
  final p = _parse(value);
  for (final b in p.blocks) {
    for (final q in p.questions[b] ?? const <_Question>[]) {
      out.putIfAbsent(q.id, () => q.answer);
    }
  }
  return out;
}

/// [value] with [member]'s individual answer to question [questionId] set,
/// as [SpecReviewAnnotations.setAnswer] with an `author` does; null when the
/// value holds no such question.
String? setIndividualAnswerText(
  String value,
  String questionId,
  String member,
  String answer, {
  String? changedAt,
}) {
  final p = _parse(value);
  for (final b in p.blocks) {
    for (final q in p.questions[b] ?? const <_Question>[]) {
      if (q.id == questionId) {
        return _setIndividualAnswer(value, q, member, answer, changedAt);
      }
    }
  }
  return null;
}

/// The lines of a conflict's text: the first after its prefix, the rest
/// indented under it.
List<String> _alternativeLines(String prefix, String text) {
  final t = text.split('\n');
  return [
    '> - $prefix ${t.first}'.trimRight(),
    for (final l in t.sublist(1)) '>   $l',
  ];
}

/// The lines of a conflict block (SOM §11.9.8): the header, the `(base)`
/// line, one lettered alternative per entry naming its members, and an empty
/// `**Decision:**`. A text's further lines are indented under it, so a reader
/// gets them back with their line breaks.
List<String> formatConflictBlock({
  required String id,
  required String topic,
  required String text,
  required String base,
  required List<SpecConflictAlternative> alternatives,
}) => [
  '> $_scales$_vs16 **$id$_emDashSep$topic:** $text'.trimRight(),
  ..._alternativeLines('(base)', base),
  for (final a in alternatives)
    ..._alternativeLines('(${a.letter}) **${a.members.join(', ')}:**', a.text),
  '>',
  '> $_decisionLabel',
];

/// Carries the edits [x] → [y] over to [b], a text equal to [x] except where
/// marks of [b] were decided in [x] (SOM §11.9.9, step 3): every edit lands
/// in [b] at the place [x] and [b] agree on. Null when an edit touches or
/// borders a place where they differ — the edit overlaps a decided mark. Both
/// diffs are the token diffs of [markChangeText].
String? transplantEdits(String x, String y, String b) {
  final xt = _tokens(x);
  final bt = _tokens(b);
  // Where each token of x is in b (-1: x and b differ there).
  final toB = List<int>.filled(xt.length, -1);
  var i = 0, j = 0;
  for (final (kind, _) in _diff(xt, bt)) {
    if (kind == 0) {
      toB[i++] = j++;
    } else if (kind == 1) {
      i++;
    } else {
      j++;
    }
  }
  // The edits x → y as (first x token, end x token, inserted text).
  final hunks = <(int, int, String)>[];
  i = 0;
  (int, int, String)? open;
  for (final (kind, t) in _diff(xt, _tokens(y))) {
    if (kind == 0) {
      if (open != null) hunks.add(open);
      open = null;
      i++;
      continue;
    }
    open ??= (i, i, '');
    if (kind == 1) {
      open = (open.$1, ++i, open.$3);
    } else {
      open = (open.$1, open.$2, open.$3 + t.text);
    }
  }
  if (open != null) hunks.add(open);
  final out = [for (final t in bt) t.text];
  for (var h = hunks.length - 1; h >= 0; h--) {
    final (x0, x1, ins) = hunks[h];
    final at = _landing(toB, x0, x1, bt.length);
    if (at == null) return null;
    out.replaceRange(at.$1, at.$2, [ins]);
  }
  return out.join();
}

/// The b-token range an x-token range [x0, x1) lands on, or null when it is
/// not one.
///
/// A replaced range lands where its tokens are in b, which must be contiguous
/// there; its neighbours are not consulted, because the token diff may align
/// a neighbouring space with another space of b (beside a decided mark)
/// without the range touching that mark. A pure insertion (`x0 == x1`) has no
/// tokens of its own, so both neighbours must sit next to each other in b.
(int, int)? _landing(List<int> toB, int x0, int x1, int bLength) {
  for (var k = x0; k < x1; k++) {
    if (toB[k] < 0 || (k > x0 && toB[k] != toB[k - 1] + 1)) return null;
  }
  if (x1 > x0) return (toB[x0], toB[x1 - 1] + 1);
  // The neighbours must sit next to the insertion point in b too.
  final left = x0 == 0 ? -1 : toB[x0 - 1];
  final right = x1 == toB.length ? bLength : toB[x1];
  if ((x0 > 0 && left < 0) || (x1 < toB.length && right < 0)) return null;
  if (left + 1 != right) return null;
  return (left + 1, left + 1);
}
