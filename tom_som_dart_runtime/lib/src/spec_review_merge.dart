/// Merging the reviewed copies of a team review (SOM §11.9.9) into one
/// document in the team notation of SOM §11.9.8: who proposed, voted for and
/// answered what, and where two members changed the same passage differently.
///
/// [mergeReviews] merges a SOM document ([SpecDocument], by model path, list
/// items matched by section id) or a plain annotated Markdown file (a
/// [String], by heading path). Both share one engine that works value by
/// value; only the way values are found, and the SOM-only structure and
/// revision entry, differ.
///
/// The engine is built on the review-annotation building blocks: the
/// paragraph split and the mark decisions of [SpecReviewAnnotations],
/// [markChangeText] for edits written as plain text, the individual-answer
/// rules of `setAnswer`, and the list-item id generation of
/// [generateListItemSectionId].
library;

import 'dart:convert';
import 'dart:math' as math;

import 'spec_document.dart';
import 'spec_document_markdown.dart';
import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';
import 'spec_review_annotations.dart';
import 'spec_section_id.dart';

// ---------------------------------------------------------------------------
// Inputs, report and result.
// ---------------------------------------------------------------------------

/// A member of a review team (SOM §11.9.8).
class SpecReviewMember {
  /// The member id: lowercase letters, digits and `_`.
  final String memberId;

  /// The name a tool shows for the member.
  final String displayName;

  /// The member's role in the team; may be empty.
  final String role;

  /// Creates a member.
  const SpecReviewMember({
    required this.memberId,
    required this.displayName,
    required this.role,
  });

  /// Reads a member from its corpus JSON form.
  factory SpecReviewMember.fromJson(Map<String, dynamic> j) => SpecReviewMember(
    memberId: j['memberId'] as String,
    displayName: j['displayName'] as String? ?? '',
    role: j['role'] as String? ?? '',
  );
}

/// One returned copy: its reviewer and the copy's document — a
/// [SpecDocument] or a Markdown [String].
class SpecReviewedCopy<D> extends SpecReviewMember {
  /// The reviewed copy.
  final D document;

  /// Creates a copy.
  const SpecReviewedCopy({
    required super.memberId,
    required super.displayName,
    required super.role,
    required this.document,
  });
}

/// The options of [mergeReviews].
class SpecReviewMergeOptions {
  /// The members the round started with, in team order; a copy of anybody
  /// else is a guest's.
  final List<SpecReviewMember> team;

  /// The round's date (ISO 8601): the revision entry's date, and the date of
  /// every generated list-item id.
  final String date;

  /// The revision entry's author.
  final String author;

  /// The id prefix of the questions the merge writes.
  final String questionPrefix;

  /// The model of a SOM document; required when merging [SpecDocument]s.
  final SpecModel? model;

  /// Creates the options.
  const SpecReviewMergeOptions({
    required this.team,
    required this.date,
    required this.author,
    this.questionPrefix = 'RQ',
    this.model,
  });
}

/// Thrown when a copy's structure does not fit the base; nothing is merged.
class SpecReviewMergeError implements Exception {
  /// What does not fit.
  final String message;

  /// Creates the error.
  SpecReviewMergeError(this.message);

  @override
  String toString() => 'SpecReviewMergeError: $message';
}

/// A reviewer as the report lists it.
class SpecMergeReviewer extends SpecReviewMember {
  /// Whether the reviewer was not in the team the round started with.
  final bool guest;

  /// Creates a reviewer entry.
  const SpecMergeReviewer({
    required super.memberId,
    required super.displayName,
    required super.role,
    required this.guest,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'memberId': memberId,
    'displayName': displayName,
    'role': role,
    'guest': guest,
  };
}

/// A conflict block the merge wrote.
class SpecMergeConflict {
  /// The conflict id, `X-<n>`.
  final String id;

  /// The value's path (a structural conflict: the item's).
  final String path;

  /// The form field, or null.
  final String? field;

  /// The unit's index among the value's text paragraphs; null for a whole
  /// value or a structural conflict.
  final int? paragraph;

  /// Every member named in the block's alternatives.
  final List<String> members;

  /// Creates an entry.
  const SpecMergeConflict({
    required this.id,
    required this.path,
    this.field,
    this.paragraph,
    required this.members,
  });

  SpecMergeConflict _withId(String id) => SpecMergeConflict(
    id: id,
    path: path,
    field: field,
    paragraph: paragraph,
    members: members,
  );

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'field': field,
    'paragraph': paragraph,
    'members': members,
  };
}

/// A base mark left with votes.
class SpecMergeVotes {
  /// The value's path.
  final String path;

  /// The form field, or null.
  final String? field;

  /// The mark as merged, its token carrying the votes.
  final String markup;

  /// The votes, in round order after any the base already held.
  final List<SpecMarkVote> votes;

  /// Creates an entry.
  const SpecMergeVotes({
    required this.path,
    this.field,
    required this.markup,
    required this.votes,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'path': path,
    'field': field,
    'markup': markup,
    'votes': [for (final v in votes) v.toJson()],
  };
}

/// A base mark every copy decided the same way, applied or dropped.
class SpecMergeUnanimous {
  /// The value's path.
  final String path;

  /// The form field, or null.
  final String? field;

  /// The mark as the base wrote it.
  final String markup;

  /// How every copy decided it.
  final SpecVote decision;

  /// The text the decision left.
  final String result;

  /// Creates an entry.
  const SpecMergeUnanimous({
    required this.path,
    this.field,
    required this.markup,
    required this.decision,
    required this.result,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'path': path,
    'field': field,
    'markup': markup,
    'decision': decision.name,
    'result': result,
  };
}

/// A base question the copies answered.
class SpecMergeAnswers {
  /// The question id.
  final String questionId;

  /// The members whose answers were written, in round order.
  final List<String> members;

  /// Creates an entry.
  const SpecMergeAnswers({required this.questionId, required this.members});

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'members': members,
  };
}

/// A new comment.
class SpecMergeComment {
  /// The comment's merged id, `C-<n>`.
  final String id;

  /// Its author: as written, else the member whose copy held it.
  final String author;

  /// The value's path.
  final String path;

  /// The form field, or null.
  final String? field;

  /// Creates an entry.
  const SpecMergeComment({
    required this.id,
    required this.author,
    required this.path,
    this.field,
  });

  SpecMergeComment _withId(String id) =>
      SpecMergeComment(id: id, author: author, path: path, field: field);

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'author': author,
    'path': path,
    'field': field,
  };
}

/// An item a copy added.
class SpecMergeAddition {
  /// The item's path in the merged document.
  final String path;

  /// The members who added it alike.
  final List<String> members;

  /// Creates an entry.
  const SpecMergeAddition({required this.path, required this.members});

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {'path': path, 'members': members};
}

/// The question proposing a guest for the next round's team.
class SpecMergeGuestQuestion {
  /// The question id.
  final String id;

  /// The guest's member id.
  final String memberId;

  /// Where it was written; null when the document has no place for it.
  final String? path;

  /// Creates an entry.
  const SpecMergeGuestQuestion({
    required this.id,
    required this.memberId,
    this.path,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'memberId': memberId,
    'path': path,
  };
}

/// The draft revision entry the merge appended.
class SpecMergeRevision {
  /// The entry's item path.
  final String path;

  /// The draft version, the next minor of the header's.
  final String version;

  /// Creates an entry.
  const SpecMergeRevision({required this.path, required this.version});

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {'path': path, 'version': version};
}

/// The merge report (SOM §11.9.9), every list in merged document order.
class SpecReviewMergeReport {
  /// Every copy's reviewer, in round order.
  final List<SpecMergeReviewer> reviewers = [];

  /// The conflict blocks written.
  final List<SpecMergeConflict> conflicts = [];

  /// Base marks left with votes.
  final List<SpecMergeVotes> votes = [];

  /// Base marks applied or dropped because every copy decided them alike.
  final List<SpecMergeUnanimous> unanimous = [];

  /// Base questions the copies answered.
  final List<SpecMergeAnswers> answers = [];

  /// The new comments.
  final List<SpecMergeComment> comments = [];

  /// Items the copies added.
  final List<SpecMergeAddition> additions = [];

  /// One question per guest.
  final List<SpecMergeGuestQuestion> guestQuestions = [];

  /// The draft revision entry, or null.
  SpecMergeRevision? revision;

  /// The canonical JSON form the conformance corpus pins.
  Map<String, Object?> toJson() => {
    'reviewers': [for (final r in reviewers) r.toJson()],
    'conflicts': [for (final c in conflicts) c.toJson()],
    'votes': [for (final v in votes) v.toJson()],
    'unanimous': [for (final u in unanimous) u.toJson()],
    'answers': [for (final a in answers) a.toJson()],
    'comments': [for (final c in comments) c.toJson()],
    'additions': [for (final a in additions) a.toJson()],
    'guestQuestions': [for (final g in guestQuestions) g.toJson()],
    'revision': revision?.toJson(),
  };
}

/// The merged document and its report.
class SpecReviewMergeResult<D> {
  /// The merged document, of the base's type.
  final D merged;

  /// What the merge did.
  final SpecReviewMergeReport report;

  /// Creates a result.
  const SpecReviewMergeResult(this.merged, this.report);
}

/// Merges the reviewed [copies] of [base] (SOM §11.9.9). [base] is a
/// [SpecDocument] (merged by model path; needs [SpecReviewMergeOptions.model])
/// or a Markdown [String] (merged by heading path). Neither the base nor a
/// copy is written. A copy whose structure does not fit the base is refused
/// with [SpecReviewMergeError].
SpecReviewMergeResult<D> mergeReviews<D>(
  D base,
  List<SpecReviewedCopy<D>> copies,
  SpecReviewMergeOptions options,
) {
  if (base is String) {
    return _mergeMarkdown(base, [
          for (final c in copies) c as SpecReviewedCopy<String>,
        ], options)
        as SpecReviewMergeResult<D>;
  }
  if (base is SpecDocument) {
    final model = options.model;
    if (model == null) {
      throw SpecReviewMergeError('merging a SOM document needs options.model');
    }
    return _mergeSom(
          base,
          [for (final c in copies) c as SpecReviewedCopy<SpecDocument>],
          options,
          model,
        )
        as SpecReviewMergeResult<D>;
  }
  throw ArgumentError.value(
    base,
    'base',
    'is neither a SpecDocument nor a Markdown string',
  );
}

// ---------------------------------------------------------------------------
// The engine: one value at a time.
// ---------------------------------------------------------------------------

/// Ids the merge writes before it can number them: renumbered in merged
/// document order at the end.
final _placeholder = RegExp('\u0001([CX])([0-9]+)\u0001');

/// One value to merge, located in the merged document.
class _MergeValue {
  final String path;
  final String? field;
  final String base;

  /// Per copy, in round order; null when the copy holds no such value (it
  /// removed the item).
  final List<String?> copies;

  /// A typed leaf (number, bool, enum, code): never marked, any change is a
  /// conflict.
  final bool typed;

  /// Where a conflict about a form field or a typed leaf goes; null for a
  /// content value.
  final String? conflictHome;

  _MergeValue({
    required this.path,
    required this.field,
    required this.base,
    required this.copies,
    required this.typed,
    required this.conflictHome,
  });
}

/// What one copy did to one unit (SOM §11.9.9, steps 1–4).
class _UnitReading {
  final bool changed;

  /// The reviewer's text.
  final String t;

  /// The change as it is written into the merged document.
  final String written;

  /// The copy's votes, by the index of the base unit's mark (true: accept).
  final Map<int, bool> votes;

  _UnitReading(this.changed, this.t, this.written, this.votes);

  /// A copy that did not change the unit, with its votes.
  _UnitReading.unchanged(String b, [Map<int, bool>? votes])
    : this(false, b, b, votes ?? const {});
}

/// The readings that made one change: the same text `t`, in order of first
/// appearance.
class _ChangeGroup {
  final String text;
  final List<String> members;
  final _UnitReading first;
  _ChangeGroup(this.text, this.members, this.first);

  SpecConflictAlternative alternative(int k) =>
      SpecConflictAlternative(String.fromCharCode(0x61 + k), members, text);
}

/// The state one merge carries from value to value.
class _MergeContext {
  final report = SpecReviewMergeReport();

  /// Blocks to append to the end of a content value, by its key (insertion
  /// order is the order they are appended in).
  final appends = <String, List<String>>{};
  final List<String> members;
  final Set<String> baseCommentIds;
  final Set<String> baseQuestionIds;
  var _nextPlaceholder = 0;

  /// Placeholder → report entry, filled in when the ids are numbered.
  final pendingConflicts = <String, SpecMergeConflict>{};
  final pendingComments = <String, SpecMergeComment>{};

  _MergeContext(
    List<SpecReviewMember> copies,
    this.baseCommentIds,
    this.baseQuestionIds,
  ) : members = [for (final c in copies) c.memberId];

  String placeholder(String kind) => '\u0001$kind${++_nextPlaceholder}\u0001';

  void append(String key, String block) =>
      appends.putIfAbsent(key, () => []).add(block);

  /// Writes a conflict block with a placeholder id and records it for the
  /// report.
  String conflict({
    required String topic,
    required String text,
    required String base,
    required List<_ChangeGroup> groups,
    required String path,
    required String? field,
    required int? paragraph,
  }) {
    final id = placeholder('X');
    pendingConflicts[id] = SpecMergeConflict(
      id: id,
      path: path,
      field: field,
      paragraph: paragraph,
      members: [for (final g in groups) ...g.members],
    );
    return formatConflictBlock(
      id: id,
      topic: topic,
      text: text,
      base: base,
      alternatives: [
        for (var k = 0; k < groups.length; k++) groups[k].alternative(k),
      ],
    ).join('\n');
  }
}

/// Groups the changed readings by their text `t`, in order of first
/// appearance.
List<_ChangeGroup> _changeGroups(
  List<_UnitReading?> readings,
  List<String> members,
) {
  final groups = <_ChangeGroup>[];
  for (var k = 0; k < readings.length; k++) {
    final r = readings[k];
    if (r == null || !r.changed) continue;
    final g = groups.where((x) => x.text == r.t).firstOrNull;
    if (g == null) {
      groups.add(_ChangeGroup(r.t, [members[k]], r));
    } else {
      g.members.add(members[k]);
    }
  }
  return groups;
}

/// The longest-common-subsequence pairing of two lists under [same]: index
/// in [a] → index in [b]. Ties skip in [a] first, as every runtime does.
Map<int, int> _lcsPairs<T>(List<T> a, List<T> b, bool Function(T, T) same) {
  final n = a.length, m = b.length;
  final l = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      l[i][j] = same(a[i], b[j])
          ? l[i + 1][j + 1] + 1
          : (l[i + 1][j] >= l[i][j + 1] ? l[i + 1][j] : l[i][j + 1]);
    }
  }
  final out = <int, int>{};
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (same(a[i], b[j])) {
      out[i++] = j++;
    } else if (l[i + 1][j] >= l[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return out;
}

/// Aligns two mark lists by their markup (longest common subsequence): index
/// in [a] → index in [b].
Map<int, int> _alignMarks(List<ReviewMark> a, List<ReviewMark> b) =>
    _lcsPairs(a, b, (x, y) => x.markup == y.markup);

/// The most base marks a unit may have that a copy no longer holds as
/// written: the combinations of step 2 grow as 2^n. Beyond it the copy's unit
/// is read as an edit (step 4), so every runtime gives up at the same point.
const _maxDecidedMarks = 16;

/// The first combination of decisions on [b]'s marks (step 2) whose result
/// is [target], or null. Each mark takes leave, accept, reject in that order,
/// the first mark varying slowest. A mark the copy still holds as written can
/// only have been left, and a mark it no longer holds cannot have been, so
/// only the others vary — the same first combination, found without trying
/// the rest.
Map<int, bool>? _findVotes(
  String b,
  List<ReviewMark> marks,
  Set<int> left,
  String target,
) {
  final free = [
    for (var i = 0; i < marks.length; i++)
      if (!left.contains(i)) i,
  ];
  if (free.length > _maxDecidedMarks) return null;
  for (var combo = 0; combo < 1 << free.length; combo++) {
    // Bit set: reject; the first mark is the most significant bit.
    final decisions = {
      for (var k = 0; k < free.length; k++)
        free[k]: ((combo >> (free.length - 1 - k)) & 1) == 0,
    };
    if (decideReviewMarks(b, decisions) == target) return decisions;
  }
  return null;
}

/// Step 4: the copy edited text that holds base marks; it casts no votes.
_UnitReading _readAsEdit(String b, String c) {
  final t = applyInlineMarksText(c, accept: true);
  return _UnitReading(
    t != b,
    t,
    markChangeText(applyInlineMarksText(b, accept: false), t).text,
    const {},
  );
}

/// What copy unit [c] did to base unit [b] (SOM §11.9.9, steps 1–4).
_UnitReading _readUnit(String b, String c) {
  if (c == b) return _UnitReading.unchanged(b);
  final baseMarks = reviewMarks(b);
  final copyMarks = reviewMarks(c);
  final kept = _alignMarks(copyMarks, baseMarks);
  // 1. Own marks: the copy's marks that are not the base's.
  final own = [
    for (var i = 0; i < copyMarks.length; i++)
      if (!kept.containsKey(i)) i,
  ];
  // 2. Votes: the decisions on the base marks that give c with its own marks
  // rejected.
  final cPrime = decideReviewMarks(c, {for (final i in own) i: false});
  final votes = _findVotes(b, baseMarks, kept.values.toSet(), cPrime);
  if (votes == null) return _readAsEdit(b, c);
  if (own.isEmpty) return _UnitReading.unchanged(b, votes);
  // 3. Change: the own marks, carried over to the base text where marks were
  // voted on.
  final ownAccepted = decideReviewMarks(c, {for (final i in own) i: true});
  final written = votes.isEmpty ? c : transplantEdits(cPrime, c, b);
  final t = votes.isEmpty
      ? ownAccepted
      : transplantEdits(cPrime, ownAccepted, b);
  if (written == null || t == null) return _readAsEdit(b, c);
  return _UnitReading(t != b, t, written, votes);
}

/// [written] with every mark that is not one of the base's attributed to
/// [members].
String _attribute(
  String written,
  List<ReviewMark> baseMarks,
  List<String> members,
) {
  final marks = reviewMarks(written);
  final base = _alignMarks(marks, baseMarks);
  var out = written;
  for (var k = marks.length - 1; k >= 0; k--) {
    if (!base.containsKey(k)) {
      out = withAttribution(out, marks[k], members, marks[k].votes);
    }
  }
  return out;
}

/// Whether a mark is a change, which alone takes votes.
bool _isChange(ReviewMark m) =>
    m.kind == SpecMarkKind.insertion ||
    m.kind == SpecMarkKind.deletion ||
    m.kind == SpecMarkKind.substitution;

SpecVote _vote(bool accept) => accept ? SpecVote.accept : SpecVote.reject;

/// [text] with the copies' votes on the base marks it holds: a base mark
/// every copy decided the same way is applied (accept) or dropped (reject);
/// any other voted change mark gets the votes in its token, `agent` as author
/// when it had no token. A highlight or comment mark takes no votes and stays.
String _applyVotes(
  String text,
  List<ReviewMark> baseMarks,
  List<_UnitReading?> readings,
  _MergeValue v,
  _MergeContext ctx,
) {
  final marks = reviewMarks(text);
  final base = _alignMarks(marks, baseMarks);
  final taking = readings.where((r) => r != null).length;
  final votes = <SpecMergeVotes>[];
  final unanimous = <SpecMergeUnanimous>[];
  var out = text;
  for (var k = marks.length - 1; k >= 0; k--) {
    final b = base[k];
    if (b == null) continue;
    final cast = <SpecMarkVote>[];
    for (var i = 0; i < readings.length; i++) {
      final d = readings[i]?.votes[b];
      if (d != null) cast.add(SpecMarkVote(ctx.members[i], _vote(d)));
    }
    if (cast.isEmpty) continue;
    final m = marks[k];
    if (cast.length == taking && cast.every((x) => x.vote == cast.first.vote)) {
      final accept = cast.first.vote == SpecVote.accept;
      out = decideReviewMarks(out, {k: accept});
      unanimous.insert(
        0,
        SpecMergeUnanimous(
          path: v.path,
          field: v.field,
          markup: baseMarks[b].markup,
          decision: cast.first.vote,
          result: accept ? baseMarks[b].accepted : baseMarks[b].rejected,
        ),
      );
      continue;
    }
    if (!_isChange(m)) continue;
    final authors = m.hasToken ? m.authors : const ['agent'];
    final merged = [
      for (final x in m.votes)
        if (!cast.any((y) => y.member == x.member)) x,
      ...cast,
    ];
    out = withAttribution(out, m, authors, merged);
    votes.insert(
      0,
      SpecMergeVotes(
        path: v.path,
        field: v.field,
        markup: reviewMarks(out)[k].markup,
        votes: merged,
      ),
    );
  }
  ctx.report.votes.addAll(votes);
  ctx.report.unanimous.addAll(unanimous);
  return out;
}

/// One unit merged: the base text with votes when no copy changed it, the
/// one change attributed to every member who made it, or the base text and a
/// conflict block when the copies changed it differently.
({String text, String? conflict}) _mergeUnit(
  String b,
  List<String?> units,
  int? paragraph,
  _MergeValue v,
  _MergeContext ctx,
) {
  final readings = [for (final c in units) c == null ? null : _readUnit(b, c)];
  final groups = _changeGroups(readings, ctx.members);
  final baseMarks = reviewMarks(b);
  var text = b;
  if (groups.length == 1) {
    text = _attribute(
      groups.first.first.written,
      baseMarks,
      groups.first.members,
    );
  }
  text = _applyVotes(text, baseMarks, readings, v, ctx);
  if (groups.length < 2) return (text: text, conflict: null);
  final where = '${v.path}${v.field == null ? '' : ' ${v.field}'}';
  final conflict = ctx.conflict(
    topic: 'Conflicting changes',
    text: paragraph == null ? where : '$where, paragraph $paragraph',
    base: b,
    groups: groups,
    path: v.path,
    field: v.field,
    paragraph: paragraph,
  );
  return (text: text, conflict: conflict);
}

/// A typed leaf: it cannot hold a mark, so a change by any copy is a `Value
/// changed` conflict at the leaf's home, the base value kept.
String _mergeTyped(_MergeValue v, _MergeContext ctx) {
  final readings = [
    for (final c in v.copies)
      c == null ? null : _UnitReading(c != v.base, c, c, const {}),
  ];
  final groups = _changeGroups(readings, ctx.members);
  final home = v.conflictHome;
  if (groups.isNotEmpty && home != null) {
    ctx.append(
      home,
      ctx.conflict(
        topic: 'Value changed',
        text: '${v.path}${v.field == null ? '' : ' ${v.field}'}',
        base: v.base,
        groups: groups,
        path: v.path,
        field: v.field,
        paragraph: null,
      ),
    );
  }
  return v.base;
}

/// A form-field value: always one unit; its conflict goes to the end of the
/// form's preamble.
String _mergeField(_MergeValue v, _MergeContext ctx) {
  final r = _mergeUnit(v.base, v.copies, null, v, ctx);
  final home = v.conflictHome;
  if (r.conflict != null && home != null) ctx.append(home, r.conflict!);
  return r.text;
}

/// Whether a copy's block is new: a comment whose id the base lacks, a
/// question block with no base question.
bool _isNewBlock(ReviewPiece piece, _MergeContext ctx) {
  if (piece.kind == SpecReviewAnnotationKind.comment) {
    return piece.id == null || !ctx.baseCommentIds.contains(piece.id);
  }
  if (piece.kind == SpecReviewAnnotationKind.question) {
    return piece.questionIds.isNotEmpty &&
        piece.questionIds.every((id) => !ctx.baseQuestionIds.contains(id));
  }
  return false;
}

/// The anchor of each block of a value: the index of the text paragraph it
/// follows (-1: before every one). In whole-value mode every block that
/// follows text follows the one unit.
List<int> _anchors(List<ReviewPiece> pieces, bool whole) {
  var texts = -1;
  return [
    for (final p in pieces)
      if (p.isText) ++texts else (whole ? math.min(texts, 0) : texts),
  ];
}

List<String> _textsOf(List<ReviewPiece> pieces) => [
  for (final p in pieces)
    if (p.isText) p.text,
];

/// A content value: split into text paragraphs and annotation blocks, merged
/// unit by unit, the copies' new comments and questions placed after the
/// unit they followed. A copy whose text-paragraph count differs from the
/// base's makes the whole text one unit, for every copy.
String _mergeContent(_MergeValue v, _MergeContext ctx) {
  final basePieces = reviewPieces(v.base);
  final copyPieces = [
    for (final c in v.copies) c == null ? null : reviewPieces(c),
  ];
  final baseTexts = _textsOf(basePieces);
  final whole = copyPieces.any(
    (ps) => ps != null && _textsOf(ps).length != baseTexts.length,
  );
  List<String> unitsOf(List<ReviewPiece> ps) =>
      whole ? [_textsOf(ps).join('\n\n')] : _textsOf(ps);
  final baseUnits = unitsOf(basePieces);
  final copyUnits = [
    for (final ps in copyPieces) ps == null ? null : unitsOf(ps),
  ];

  // Blocks by anchor: the base's first, then each copy's new ones in round
  // order.
  final after = <int, List<String>>{};
  void place(int anchor, String block) =>
      after.putIfAbsent(anchor, () => []).add(block);
  final baseAnchors = _anchors(basePieces, whole);
  for (var k = 0; k < basePieces.length; k++) {
    if (!basePieces[k].isText) place(baseAnchors[k], basePieces[k].text);
  }
  for (var i = 0; i < copyPieces.length; i++) {
    final ps = copyPieces[i];
    if (ps == null) continue;
    final anchors = _anchors(ps, false);
    for (var k = 0; k < ps.length; k++) {
      if (ps[k].isText || !_isNewBlock(ps[k], ctx)) continue;
      place(
        whole ? baseUnits.length - 1 : anchors[k],
        _newBlock(ps[k], ctx.members[i], v, ctx),
      );
    }
  }

  final out = <String>[...?after[-1]];
  for (var u = 0; u < baseUnits.length; u++) {
    final units = [for (final cs in copyUnits) cs?[u]];
    final r = _mergeUnit(baseUnits[u], units, whole ? null : u, v, ctx);
    if (r.text.isNotEmpty) out.add(r.text);
    if (r.conflict != null) out.add(r.conflict!);
    out.addAll(after[u] ?? const []);
  }
  return out.join('\n\n');
}

/// A copy's new block as merged: a comment renumbered and attributed, a
/// question as written.
String _newBlock(
  ReviewPiece p,
  String member,
  _MergeValue v,
  _MergeContext ctx,
) {
  if (p.kind != SpecReviewAnnotationKind.comment) return p.text;
  final id = ctx.placeholder('C');
  final author = p.author ?? member;
  ctx.pendingComments[id] = SpecMergeComment(
    id: id,
    author: author,
    path: v.path,
    field: v.field,
  );
  return formatCommentBlock(
    id: id,
    text: p.commentText,
    author: author,
    changedAt: p.changedAt,
  ).join('\n');
}

/// One value merged; the base text when no copy differs from it.
String _mergeValue(_MergeValue v, _MergeContext ctx) {
  if (v.copies.every((c) => c == null || c == v.base)) return v.base;
  if (v.typed) return _mergeTyped(v, ctx);
  if (v.field != null) return _mergeField(v, ctx);
  return _mergeContent(v, ctx);
}

// ---------------------------------------------------------------------------
// Shared phases over the merged texts.
// ---------------------------------------------------------------------------

/// The merged document's values, by key, in merged document order.
abstract class _Texts {
  List<String> keys();
  String get(String key);
  void set(String key, String value);
}

/// Appends [block] to the end of [value], one blank line between them.
String _appendBlock(String value, String block) =>
    value.isEmpty ? block : '$value\n\n$block';

/// Appends the collected blocks (field and structural conflicts) to the end
/// of their values.
void _applyAppends(_Texts texts, _MergeContext ctx) {
  for (final MapEntry(:key, value: blocks) in ctx.appends.entries) {
    final value = texts.get(key);
    texts.set(key, [if (value.isNotEmpty) value, ...blocks].join('\n\n'));
  }
}

/// The highest `<prefix>-<n>` of the texts' annotations of the given kinds.
int _highestId(
  List<String> texts,
  String prefix,
  Set<SpecReviewAnnotationKind> kinds,
) {
  var high = 0;
  for (final t in texts) {
    for (final p in reviewPieces(t)) {
      if (!kinds.contains(p.kind)) continue;
      final ids = p.kind == SpecReviewAnnotationKind.question
          ? p.questionIds
          : [?p.id];
      for (final id in ids) {
        if (!id.startsWith('$prefix-')) continue;
        final n = _leadingInt(id.substring(prefix.length + 1));
        if (n != null && n > high) high = n;
      }
    }
  }
  return high;
}

/// The number a string starts with (`parseInt` semantics), or null.
int? _leadingInt(String s) {
  final m = RegExp('^[0-9]+').firstMatch(s);
  return m == null ? null : int.parse(m.group(0)!);
}

/// Numbers the new comments and conflicts in merged document order, above
/// the base's highest `C-<n>` and `X-<n>`, and fills their report entries in.
void _numberIds(_Texts texts, List<String> baseTexts, _MergeContext ctx) {
  final next = {
    'C': _highestId(baseTexts, 'C', {SpecReviewAnnotationKind.comment}),
    'X': _highestId(baseTexts, 'X', {SpecReviewAnnotationKind.conflict}),
  };
  for (final key in texts.keys()) {
    final value = texts.get(key);
    if (!value.contains('\u0001')) continue;
    texts.set(
      key,
      value.replaceAllMapped(_placeholder, (m) {
        final kind = m.group(1)!;
        final id = '$kind-${next[kind] = next[kind]! + 1}';
        final placeholder = m.group(0)!;
        if (kind == 'C') {
          ctx.report.comments.add(
            ctx.pendingComments[placeholder]!._withId(id),
          );
        } else {
          ctx.report.conflicts.add(
            ctx.pendingConflicts[placeholder]!._withId(id),
          );
        }
        return id;
      }),
    );
  }
}

/// The team answers of every question of [texts], by id (the first, when an
/// id repeats).
Map<String, String> _teamAnswers(List<String> texts) {
  final out = <String, String>{};
  for (final t in texts) {
    for (final MapEntry(:key, :value) in reviewTeamAnswers(t).entries) {
      out.putIfAbsent(key, () => value);
    }
  }
  return out;
}

/// Writes each copy's team answer to a base question, where it differs from
/// the base's, as that member's individual answer (copies in round order).
void _mergeAnswers(
  _Texts texts,
  List<String> baseTexts,
  List<List<String>> copyTexts,
  _MergeContext ctx,
) {
  final copyAnswers = [for (final ts in copyTexts) _teamAnswers(ts)];
  for (final MapEntry(key: id, value: baseAnswer) in _teamAnswers(
    baseTexts,
  ).entries) {
    final members = <String>[];
    for (var i = 0; i < copyAnswers.length; i++) {
      final a = copyAnswers[i][id];
      if (a == null || a == baseAnswer || a.isEmpty) continue;
      for (final key in texts.keys()) {
        final written = setIndividualAnswerText(
          texts.get(key),
          id,
          ctx.members[i],
          a,
        );
        if (written == null) continue;
        texts.set(key, written);
        members.add(ctx.members[i]);
        break;
      }
    }
    if (members.isNotEmpty) {
      ctx.report.answers.add(
        SpecMergeAnswers(questionId: id, members: members),
      );
    }
  }
}

/// The question proposing guest [g] for the next round's team.
String _guestQuestion(String id, SpecReviewMember g) {
  final who = g.role.isNotEmpty ? '${g.displayName}, ${g.role}' : g.displayName;
  return formatQuestionBlock(
    SpecQuestionDraft(
      id: id,
      topic: 'Guest ${g.memberId}',
      text: 'add ${g.memberId} ($who) to the review team?',
      options: const [
        '(a) yes, from the next round on',
        '(b) no, this round only',
      ],
      recommended: 'a',
    ),
  ).join('\n');
}

/// Lists the reviewers and writes one question per guest to the end of the
/// value at [home] (null: the report only), numbered above the base's highest
/// question id with the prefix.
void _addGuests(
  _Texts texts,
  List<String> baseTexts,
  List<SpecReviewMember> copies,
  SpecReviewMergeOptions options,
  ({String key, String path})? home,
  _MergeContext ctx,
) {
  final team = {for (final m in options.team) m.memberId};
  final prefix = options.questionPrefix;
  var n = _highestId(baseTexts, prefix, {SpecReviewAnnotationKind.question});
  for (final c in copies) {
    final guest = !team.contains(c.memberId);
    ctx.report.reviewers.add(
      SpecMergeReviewer(
        memberId: c.memberId,
        displayName: c.displayName,
        role: c.role,
        guest: guest,
      ),
    );
    if (!guest) continue;
    final id = '$prefix-${++n}';
    ctx.report.guestQuestions.add(
      SpecMergeGuestQuestion(id: id, memberId: c.memberId, path: home?.path),
    );
    if (home == null) continue;
    texts.set(
      home.key,
      _appendBlock(texts.get(home.key), _guestQuestion(id, c)),
    );
  }
}

/// The ids of the comments and questions of [texts].
({Set<String> comments, Set<String> questions}) _blockIds(List<String> texts) {
  final comments = <String>{};
  final questions = <String>{};
  for (final t in texts) {
    for (final p in reviewPieces(t)) {
      if (p.kind == SpecReviewAnnotationKind.comment && p.id != null) {
        comments.add(p.id!);
      }
      questions.addAll(p.questionIds);
    }
  }
  return (comments: comments, questions: questions);
}

/// The phases after the structure, shared by both formats.
void _mergeTexts(
  List<_MergeValue> values,
  String Function(_MergeValue v) keyOf,
  _Texts texts,
  List<String> baseTexts,
  List<List<String>> copyTexts,
  List<SpecReviewMember> copies,
  SpecReviewMergeOptions options,
  ({String key, String path})? home,
  _MergeContext ctx,
) {
  for (final v in values) {
    final merged = _mergeValue(v, ctx);
    if (merged != v.base) texts.set(keyOf(v), merged);
  }
  _applyAppends(texts, ctx);
  _numberIds(texts, baseTexts, ctx);
  _mergeAnswers(texts, baseTexts, copyTexts, ctx);
  _addGuests(texts, baseTexts, copies, options, home, ctx);
}

// ---------------------------------------------------------------------------
// Plain Markdown: values by heading path.
// ---------------------------------------------------------------------------

/// A Markdown file cut at its headings: body `i` follows heading `i - 1`
/// (body 0 precedes them all).
class _MarkdownSplit {
  final headings = <String>[];

  /// The heading path of each body, its heading texts joined by ` > ` (body
  /// 0: empty).
  final paths = <String>[''];
  final bodies = <List<String>>[[]];
}

final _heading = RegExp(r'^(#{1,6})(?:[ \t]+(.*?))?[ \t]*$');

_MarkdownSplit _splitMarkdown(String text) {
  final out = _MarkdownSplit();
  final fence = MarkdownFenceTracker();
  final stack = <(int, String)>[];
  for (final line in text.split('\n')) {
    final wasFenced = fence.inFence;
    fence.feed(line);
    final h = wasFenced || fence.inFence ? null : _heading.firstMatch(line);
    if (h == null) {
      out.bodies.last.add(line);
      continue;
    }
    final level = h.group(1)!.length;
    while (stack.isNotEmpty && stack.last.$1 >= level) {
      stack.removeLast();
    }
    stack.add((level, h.group(2) ?? ''));
    out.headings.add(line);
    out.paths.add([for (final s in stack) s.$2].join(' > '));
    out.bodies.add([]);
  }
  return out;
}

/// A body's blank lines before and after its value, and the value.
({int lead, int trail, String value}) _bodyParts(List<String> lines) {
  var lead = 0;
  while (lead < lines.length && lines[lead].trim().isEmpty) {
    lead++;
  }
  if (lead == lines.length) return (lead: lead, trail: 0, value: '');
  var trail = 0;
  while (lines[lines.length - 1 - trail].trim().isEmpty) {
    trail++;
  }
  return (
    lead: lead,
    trail: trail,
    value: lines.sublist(lead, lines.length - trail).join('\n'),
  );
}

/// The body lines for a new value, keeping the body's blank lines around it.
List<String> _bodyLines(List<String> lines, String value, bool afterHeading) {
  final parts = _bodyParts(lines);
  if (value == parts.value) return lines;
  if (value.isEmpty) return lines.sublist(0, parts.lead);
  if (parts.value.isEmpty) {
    return [
      if (afterHeading) '',
      ...value.split('\n'),
      if (lines.isNotEmpty) '',
    ];
  }
  return [
    ...lines.sublist(0, parts.lead),
    ...value.split('\n'),
    ...lines.sublist(lines.length - parts.trail),
  ];
}

/// The Markdown bodies as [_Texts], keyed by their index.
class _MarkdownTexts implements _Texts {
  final List<String> merged;
  _MarkdownTexts(this.merged);

  @override
  List<String> keys() => [for (var k = 0; k < merged.length; k++) '$k'];

  @override
  String get(String key) => merged[int.parse(key)];

  @override
  void set(String key, String value) => merged[int.parse(key)] = value;
}

SpecReviewMergeResult<String> _mergeMarkdown(
  String base,
  List<SpecReviewedCopy<String>> copies,
  SpecReviewMergeOptions options,
) {
  final b = _splitMarkdown(base);
  final cs = [for (final c in copies) _splitMarkdown(c.document)];
  for (var i = 0; i < cs.length; i++) {
    final h = cs[i].headings;
    var same = h.length == b.headings.length;
    for (var k = 0; same && k < h.length; k++) {
      same = h[k].trim() == b.headings[k].trim();
    }
    if (!same) {
      throw SpecReviewMergeError(
        'the copy of ${copies[i].memberId} has other headings than the base',
      );
    }
  }
  final baseTexts = [for (final lines in b.bodies) _bodyParts(lines).value];
  final copyTexts = [
    for (final c in cs) [for (final lines in c.bodies) _bodyParts(lines).value],
  ];
  final texts = _MarkdownTexts(List.of(baseTexts));
  final ids = _blockIds(baseTexts);
  final ctx = _MergeContext(copies, ids.comments, ids.questions);
  final values = [
    for (var k = 0; k < baseTexts.length; k++)
      _MergeValue(
        path: b.paths[k],
        field: null,
        base: baseTexts[k],
        copies: [for (final ct in copyTexts) ct[k]],
        typed: false,
        conflictHome: null,
      ),
  ];
  final first = b.headings.isNotEmpty ? 1 : 0;
  _mergeTexts(
    values,
    (v) => '${values.indexOf(v)}',
    texts,
    baseTexts,
    copyTexts,
    copies,
    options,
    (key: '$first', path: b.paths[first]),
    ctx,
  );
  final lines = <String>[];
  for (var k = 0; k < b.bodies.length; k++) {
    if (k > 0) lines.add(b.headings[k - 1]);
    lines.addAll(_bodyLines(b.bodies[k], texts.merged[k], k > 0));
  }
  return SpecReviewMergeResult(lines.join('\n'), ctx.report);
}

// ---------------------------------------------------------------------------
// SOM documents: values by model path, list items by section id.
// ---------------------------------------------------------------------------

/// A document's paths with every list item named by its section id instead
/// of its position (`DEMO/CARD-LST#CARD-BETA/content`), so the same item has
/// the same name in the base, in every copy and in the merged document.
class _CanonicalPaths {
  final SpecDocument doc;
  final _listOf = <String, String>{};
  final _ids = <String, String>{};
  final _byCanonical = <String, String>{};
  final _memo = <String, String>{};

  _CanonicalPaths(this.doc, SpecReflection refl) {
    for (final list in doc.listPaths) {
      final field = refl.resolve(list)?.field;
      final items = doc.listItems(list);
      for (var k = 0; k < items.length; k++) {
        _listOf[items[k]] = list;
        _ids[items[k]] = effectiveListItemSectionId(
          storedId: doc.itemSectionId(items[k]),
          pattern: field?.sectionIdPattern,
          position: k + 1,
          fallbackStem: field?.name ?? list,
        );
      }
    }
    for (final item in _listOf.keys) {
      _byCanonical[of(item)] = item;
    }
  }

  /// The item paths of the list at [list], in order.
  List<String> items(String list) => doc.listItems(list);

  /// The section id an item is matched by.
  String idOf(String item) => _ids[item]!;

  /// The canonical form of [path].
  String of(String path) {
    final memo = _memo[path];
    if (memo != null) return memo;
    final segs = path.split('/');
    var out = path;
    for (var k = segs.length; k > 0; k--) {
      final prefix = segs.sublist(0, k).join('/');
      final list = _listOf[prefix];
      if (list == null) continue;
      final rest = segs.sublist(k).join('/');
      out = '${of(list)}#${idOf(prefix)}${rest.isNotEmpty ? '/$rest' : ''}';
      break;
    }
    return _memo[path] = out;
  }

  /// The document's path for a canonical path, or null when the document
  /// lacks one of its items.
  String? pathOf(String canonical) {
    final segs = canonical.split('/');
    for (var k = segs.length; k > 0; k--) {
      final item = _byCanonical[segs.sublist(0, k).join('/')];
      if (item == null) continue;
      final rest = segs.sublist(k).join('/');
      return '$item${rest.isNotEmpty ? '/$rest' : ''}';
    }
    return canonical.contains('#') ? null : canonical;
  }
}

/// Whether canonical [path] is [item] or lies under it.
bool _under(String path, String item) =>
    path == item || path.startsWith('$item/');

/// Whether [path] lies at or under any of [items].
bool _underAny(String path, Iterable<String> items) =>
    items.any((a) => _under(path, a));

/// A copy whose paths the model does not resolve does not fit the base.
void _checkStructure(SpecDocument doc, String what, SpecReflection refl) {
  final paths = [
    ...doc.contentPaths,
    ...doc.formPaths,
    ...doc.headlinePaths,
    ...doc.codeSpecPaths,
    for (final list in doc.listPaths) ...[list, ...doc.listItems(list)],
  ];
  for (final p in paths) {
    if (refl.resolve(p) == null) {
      throw SpecReviewMergeError(
        '$what holds $p, a path the base model does not resolve',
      );
    }
  }
}

SpecDocument _copyDocument(SpecDocument doc) =>
    SpecDocument()..loadJson(jsonDecode(jsonEncode(doc.toJson())) as Map);

/// The form field [field] of the form at [path], or null.
FormFieldSpec? _formField(SpecReflection refl, String path, String field) =>
    refl
        .resolve(path)
        ?.field
        ?.formFields
        .where((x) => x.name == field)
        .firstOrNull;

/// Whether the value at [path] / [field] is text, which can hold marks: a
/// content value (a form's preamble included) or a String form field that is
/// not code. Scalar and enum leaves, and typed or code fields, are not.
bool _isText(SpecReflection refl, String path, String? field) {
  if (field != null) {
    final spec = _formField(refl, path, field);
    return spec == null || (spec.type == 'String' && !spec.code);
  }
  final res = refl.resolve(path);
  if (res == null) return true;
  if (res.kind == SpecNodeKind.scalar || res.kind == SpecNodeKind.enumValue) {
    return false;
  }
  return res.kind != SpecNodeKind.listItemScalar ||
      res.field?.elementType == 'String';
}

/// The first node at or below [path] that holds content (a content leaf or a
/// form's preamble), in model order.
String? _firstContentSlot(SpecReflection refl, String path, bool deep) {
  final res = refl.resolve(path);
  if (res == null) return null;
  if (res.kind == SpecNodeKind.content || res.kind == SpecNodeKind.form) {
    return path;
  }
  final cls = res.targetClass;
  if (cls == null) return null;
  for (final f in cls.fields) {
    final child = '$path/${refl.fieldSegment(f)}';
    if (f.kind == SpecFieldKind.content || f.kind == SpecFieldKind.form) {
      return child;
    }
    if (deep &&
        (f.kind == SpecFieldKind.complex || f.kind == SpecFieldKind.section)) {
      final found = _firstContentSlot(refl, child, true);
      if (found != null) return found;
    }
  }
  return null;
}

/// Where a block about the node at [path] goes (SOM §11.9.9, "Structure"):
/// the first content value at or below it in document order; else the first
/// node at or below it that can hold content; else its nearest ancestor's
/// own.
String? _blockHome(
  SpecDocument doc,
  SpecReflection refl,
  String path,
  bool ownFirst,
) {
  if (ownFirst) {
    final existing = [
      for (final p in doc.contentPaths)
        if (_under(p, path)) p,
    ]..sort();
    if (existing.isNotEmpty) return existing.first;
    final slot = _firstContentSlot(refl, path, true);
    if (slot != null) return slot;
  }
  for (var a = specParentPath(path); a.isNotEmpty;) {
    if (doc.content(a) != null) return a;
    final slot = _firstContentSlot(refl, a, false);
    if (slot != null) return slot;
    final parent = specParentPath(a);
    if (parent == a) break;
    a = parent;
  }
  return null;
}

/// One structural change the copies disagree with the base on.
class _Structural {
  /// The canonical path of the item (or section) concerned.
  final String node;

  /// `Item removed`, `Item moved` or `Headline changed`.
  final String topic;
  final String base;
  final groups = <_ChangeGroup>[];
  _Structural(this.node, this.topic, this.base);
}

void _addStructural(
  List<_Structural> all,
  String node,
  String topic,
  String base,
  String text,
  String member,
) {
  var s = all.where((x) => x.node == node && x.topic == topic).firstOrNull;
  if (s == null) {
    s = _Structural(node, topic, base);
    all.add(s);
  }
  final g = s.groups.where((x) => x.text == text).firstOrNull;
  if (g == null) {
    s.groups.add(
      _ChangeGroup(text, [member], _UnitReading(true, text, text, const {})),
    );
  } else {
    g.members.add(member);
  }
}

/// The ids of [ids] that are not in their longest common subsequence with
/// [order].
Set<String> _moved(List<String> order, List<String> ids) {
  final stay = _lcsPairs(order, ids, (a, b) => a == b);
  final kept = {for (final i in stay.keys) order[i]};
  return {
    for (final id in ids)
      if (!kept.contains(id)) id,
  };
}

final _fenceOpen = RegExp(r'^\s*(```|~~~)');

/// [value] written as attributed insertions, one per text paragraph (an added
/// item's text).
String _asInsertion(String value, List<String> members) {
  final token = '{@${members.join(',')}}';
  return [
    for (final p in reviewPieces(value))
      !p.isText || _fenceOpen.hasMatch(p.text)
          ? p.text
          : '{++ ${p.text.trim()} ++}$token',
  ].join('\n\n');
}

/// Copies item [from] of [src], with everything under it, to item [to] of
/// [dst].
void _copyItem(
  SpecDocument src,
  String from,
  SpecDocument dst,
  String to,
  List<String> members,
  SpecReflection refl,
) {
  final moved = <String, String>{from: to};
  String remap(String p) {
    final segs = p.split('/');
    for (var k = segs.length; k > 0; k--) {
      final target = moved[segs.sublist(0, k).join('/')];
      if (target != null) return [target, ...segs.sublist(k)].join('/');
    }
    return p;
  }

  final lists = [
    for (final l in src.listPaths)
      if (_under(l, from)) l,
  ]..sort((a, b) => a.split('/').length.compareTo(b.split('/').length));
  final canonical = _CanonicalPaths(src, refl);
  for (final list in lists) {
    for (final item in src.listItems(list)) {
      moved[item] = dst.addListItem(
        remap(list),
        sectionId: canonical.idOf(item),
      );
    }
  }
  for (final p in [
    for (final x in src.contentPaths)
      if (_under(x, from)) x,
  ]) {
    final value = src.content(p)!;
    dst.setContent(
      remap(p),
      _isText(refl, p, null) ? _asInsertion(value, members) : value,
    );
  }
  for (final p in [
    for (final x in src.formPaths)
      if (_under(x, from)) x,
  ]) {
    for (final f in src.formFieldNames(p)) {
      final value = src.formField(p, f)!;
      dst.setFormField(
        remap(p),
        f,
        _isText(refl, p, f) ? _asInsertion(value, members) : value,
      );
    }
  }
  for (final p in [
    for (final x in src.headlinePaths)
      if (_under(x, from)) x,
  ]) {
    dst.setHeadline(remap(p), src.headline(p)!);
  }
  for (final p in [
    for (final x in src.codeSpecPaths)
      if (_under(x, from)) x,
  ]) {
    dst.setCodeSpec(remap(p), src.codeSpec(p)!);
  }
}

/// Everything under an item, as one comparable value: copies adding the same
/// item alike add it once. Paths are taken relative to the item, because the
/// item's own path is a position.
String _itemSignature(SpecDocument doc, String item) {
  final json = doc.toJson();
  List<List<Object?>> pick(Object? o) => [
    if (o is Map)
      for (final MapEntry(:key, :value) in o.entries)
        if (_under(key as String, item)) [key.substring(item.length), value],
  ];
  // Nested item paths start with the item's own path, which is a position:
  // cut it.
  final own = jsonEncode(item);
  return jsonEncode([
    pick(json['content']),
    pick(json['forms']),
    pick(json['headlines']),
    pick(json['lists']),
  ]).split(own.substring(0, own.length - 1)).join('"');
}

/// The structure phase: items the copies added are added (attributed to
/// every copy that added them alike); items removed or moved, and changed
/// headlines, become structural conflicts. Returns the canonical paths of the
/// added items.
Set<String> _mergeStructure(
  SpecDocument merged,
  SpecDocument base,
  List<SpecReviewedCopy<SpecDocument>> copies,
  SpecReflection refl,
  SpecModel model,
  _MergeContext ctx,
) {
  final baseCanon = _CanonicalPaths(base, refl);
  final copyCanon = [for (final c in copies) _CanonicalPaths(c.document, refl)];
  final added = <String>{};
  final structural = <_Structural>[];
  final additions = <({String node, List<String> members})>[];
  final lists = {
    for (final l in base.listPaths) baseCanon.of(l),
    for (var i = 0; i < copies.length; i++)
      for (final l in copies[i].document.listPaths) copyCanon[i].of(l),
  };
  final ordered = lists.toList()
    ..sort((a, b) {
      final c = a.split('#').length.compareTo(b.split('#').length);
      return c != 0 ? c : a.compareTo(b);
    });
  for (final list in ordered) {
    if (_underAny(list, added)) continue;
    final basePath = baseCanon.pathOf(list);
    if (basePath == null) continue;
    final baseIds = [
      for (final p in baseCanon.items(basePath)) baseCanon.idOf(p),
    ];
    final groups =
        <
          String,
          ({int copy, String? anchor, List<String> members, String signature})
        >{};
    for (var i = 0; i < copies.length; i++) {
      final copyPath = copyCanon[i].pathOf(list);
      if (copyPath == null) continue;
      final items = copyCanon[i].items(copyPath);
      final ids = [for (final p in items) copyCanon[i].idOf(p)];
      final member = copies[i].memberId;
      for (var k = 0; k < ids.length; k++) {
        final id = ids[k];
        if (baseIds.contains(id)) continue;
        final signature = _itemSignature(copies[i].document, items[k]);
        final g = groups[id];
        if (g == null) {
          final anchor = ids
              .sublist(0, k)
              .reversed
              .where(baseIds.contains)
              .firstOrNull;
          groups[id] = (
            copy: i,
            anchor: anchor,
            members: [member],
            signature: signature,
          );
        } else if (g.signature == signature) {
          g.members.add(member);
        }
      }
      for (final id in baseIds.where((x) => !ids.contains(x))) {
        _addStructural(
          structural,
          '$list#$id',
          'Item removed',
          'kept',
          'removed',
          member,
        );
      }
      final keptOrder = baseIds.where(ids.contains).toList();
      final keptIds = ids.where(baseIds.contains).toList();
      for (final id in _moved(keptOrder, keptIds)) {
        _addStructural(
          structural,
          '$list#$id',
          'Item moved',
          'position ${baseIds.indexOf(id) + 1}',
          'moved to position ${ids.indexOf(id) + 1}',
          member,
        );
      }
    }
    for (final MapEntry(key: id, value: g) in groups.entries) {
      final mergedCanon = _CanonicalPaths(merged, refl);
      final listPath = mergedCanon.pathOf(list)!;
      final mergedIds = [
        for (final p in mergedCanon.items(listPath)) mergedCanon.idOf(p),
      ];
      var at = g.anchor == null ? 0 : mergedIds.indexOf(g.anchor!) + 1;
      while (at < mergedIds.length && !baseIds.contains(mergedIds[at])) {
        at++;
      }
      var item = merged.addListItem(listPath, sectionId: id);
      if (at < mergedIds.length) {
        item = merged.moveListItem(model, item, at).path;
      }
      _copyItem(
        copies[g.copy].document,
        copyCanon[g.copy].pathOf('$list#$id')!,
        merged,
        item,
        g.members,
        refl,
      );
      added.add('$list#$id');
      additions.add((node: '$list#$id', members: g.members));
    }
  }
  _headlineChanges(base, baseCanon, copies, copyCanon, added, structural);
  final mergedCanon = _CanonicalPaths(merged, refl);
  for (final a in additions) {
    ctx.report.additions.add(
      SpecMergeAddition(path: mergedCanon.pathOf(a.node)!, members: a.members),
    );
  }
  for (final s in structural) {
    final node = mergedCanon.pathOf(s.node)!;
    final home = _blockHome(merged, refl, node, true);
    final block = ctx.conflict(
      topic: s.topic,
      text: node,
      base: s.base,
      groups: s.groups,
      path: node,
      field: null,
      paragraph: null,
    );
    if (home != null) ctx.append(_contentKey(home), block);
  }
  return added;
}

/// Every headline a copy changed (items it added aside) is a structural
/// conflict.
void _headlineChanges(
  SpecDocument base,
  _CanonicalPaths baseCanon,
  List<SpecReviewedCopy<SpecDocument>> copies,
  List<_CanonicalPaths> copyCanon,
  Set<String> added,
  List<_Structural> structural,
) {
  final nodes = {
    for (final p in base.headlinePaths) baseCanon.of(p),
    for (var i = 0; i < copies.length; i++)
      for (final p in copies[i].document.headlinePaths) copyCanon[i].of(p),
  }.toList()..sort();
  for (final node in nodes) {
    if (_underAny(node, added)) continue;
    final basePath = baseCanon.pathOf(node);
    if (basePath == null) continue;
    final was = base.headline(basePath) ?? '';
    for (var i = 0; i < copies.length; i++) {
      final path = copyCanon[i].pathOf(node);
      if (path == null) continue;
      final now = copies[i].document.headline(path) ?? '';
      if (now != was) {
        _addStructural(
          structural,
          node,
          'Headline changed',
          was,
          now,
          copies[i].memberId,
        );
      }
    }
  }
}

/// The keys of the SOM texts: `c\0<path>` for content, `f\0<path>\0<field>`
/// for a form field.
String _contentKey(String path) => 'c\u0000$path';

String _fieldKey(String path, String field) => 'f\u0000$path\u0000$field';

/// The SOM document's values as [_Texts], in document order (content sorted,
/// then forms and fields sorted).
class _SomTexts implements _Texts {
  final SpecDocument doc;
  _SomTexts(this.doc);

  @override
  List<String> keys() => [
    for (final p in doc.contentPaths.toList()..sort()) _contentKey(p),
    for (final p in doc.formPaths.toList()..sort())
      for (final f in doc.formFieldNames(p).toList()..sort()) _fieldKey(p, f),
  ];

  @override
  String get(String key) {
    final k = key.split('\u0000');
    return (k[0] == 'c' ? doc.content(k[1]) : doc.formField(k[1], k[2])) ?? '';
  }

  @override
  void set(String key, String value) {
    final k = key.split('\u0000');
    if (k[0] == 'c') {
      doc.setContent(k[1], value);
    } else {
      doc.setFormField(k[1], k[2], value);
    }
  }

  /// Every value, in document order.
  List<String> values() => [for (final k in keys()) get(k)];
}

/// The values to merge: every value of the base and of the copies, items the
/// copies added aside, located in the merged document; in its document
/// order.
List<_MergeValue> _somValues(
  SpecDocument merged,
  SpecDocument base,
  List<SpecReviewedCopy<SpecDocument>> copies,
  Set<String> added,
  SpecReflection refl,
) {
  final baseCanon = _CanonicalPaths(base, refl);
  final copyCanon = [for (final c in copies) _CanonicalPaths(c.document, refl)];
  final mergedCanon = _CanonicalPaths(merged, refl);
  final keys = <String, (String, String?)>{};
  void collect(SpecDocument doc, _CanonicalPaths canon) {
    for (final p in doc.contentPaths) {
      keys[_contentKey(canon.of(p))] = (canon.of(p), null);
    }
    for (final p in doc.formPaths) {
      for (final f in doc.formFieldNames(p)) {
        keys[_fieldKey(canon.of(p), f)] = (canon.of(p), f);
      }
    }
  }

  collect(base, baseCanon);
  for (var i = 0; i < copies.length; i++) {
    collect(copies[i].document, copyCanon[i]);
  }
  String read(SpecDocument doc, String path, String? field) =>
      (field == null ? doc.content(path) : doc.formField(path, field)) ?? '';
  final values = <_MergeValue>[];
  for (final (node, field) in keys.values) {
    if (_underAny(node, added)) continue;
    final basePath = baseCanon.pathOf(node);
    if (basePath == null) continue;
    final path = mergedCanon.pathOf(node)!;
    final text = _isText(refl, path, field);
    String? home;
    if (field != null) {
      home = _contentKey(path);
    } else if (!text) {
      final h = _blockHome(merged, refl, path, false);
      home = h == null ? null : _contentKey(h);
    }
    values.add(
      _MergeValue(
        path: path,
        field: field,
        base: read(base, basePath, field),
        copies: [
          for (var i = 0; i < copies.length; i++)
            switch (copyCanon[i].pathOf(node)) {
              final p? => read(copies[i].document, p, field),
              null => null,
            },
        ],
        typed: !text,
        conflictHome: home,
      ),
    );
  }
  String order(_MergeValue v) =>
      '${v.field == null ? 0 : 1}\u0000${v.path}\u0000${v.field ?? ''}';
  return values..sort((a, b) => order(a).compareTo(order(b)));
}

/// The class field of [cls] named [name] with kind [kind], or null.
SpecField? _classField(SpecClass? cls, String name, SpecFieldKind kind) {
  final f = cls?.fieldNamed(name);
  return f != null && f.kind == kind ? f : null;
}

/// The model classes the revision entry is written with (`tom_specs_model`'s
/// document front matter).
const _revisionEntry = 'RevisionEntry';
const _documentHeader = 'DocumentHeader';

/// The next minor of a `major.minor[.patch]` version; `0.1.0` for anything
/// else.
String _nextMinor(String? version) {
  final m = RegExp(
    r'^([0-9]+)\.([0-9]+)(\.[0-9]+)?$',
  ).firstMatch((version ?? '').trim());
  if (m == null) return '0.1.0';
  final minor = '${m.group(1)}.${int.parse(m.group(2)!) + 1}';
  return m.group(3) == null ? minor : '$minor.0';
}

/// The date of an ISO 8601 date string; only its month and day name a
/// generated list-item id.
DateTime _isoDate(String date) {
  final m = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})').firstMatch(date);
  if (m == null) {
    throw SpecReviewMergeError('options.date "$date" is not an ISO 8601 date');
  }
  return DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

/// Adds an item with a generated id to the list [field] at [list], and
/// returns its path.
String _addGeneratedItem(
  SpecDocument doc,
  String list,
  SpecField field,
  DateTime date,
) {
  final id = generateListItemSectionId(
    field.sectionIdPattern ?? '${field.name}-xxx',
    date,
    doc.listItemSectionIds(list),
  );
  return doc.addListItem(list, sectionId: id);
}

/// Writes one reviewer record into the list [field] at [list].
void _addReviewerRecord(
  SpecDocument doc,
  SpecReflection refl,
  String list,
  SpecField field,
  SpecReviewMember member,
  bool guest,
  DateTime date,
) {
  final item = _addGeneratedItem(doc, list, field, date);
  final form = _classField(
    refl.classNamed(field.elementType),
    'content',
    SpecFieldKind.form,
  );
  if (form == null) return;
  final path = '$item/${refl.fieldSegment(form)}';
  doc
    ..setFormField(path, 'memberId', member.memberId)
    ..setFormField(path, 'displayName', member.displayName)
    ..setFormField(path, 'role', member.role);
  if (guest) doc.setFormField(path, 'guest', 'true');
}

/// Appends the draft revision entry when the root has a revision history:
/// the next minor version, the date and author, the team the round started
/// with and every reviewer who returned a copy, guests marked.
void _addRevisionEntry(
  SpecDocument merged,
  String root,
  List<SpecReviewMember> copies,
  SpecReviewMergeOptions options,
  SpecReflection refl,
  _MergeContext ctx,
) {
  final rootClass = refl.classNamed(refl.rootForSegment(root)?.type);
  final history = rootClass?.fields
      .where(
        (f) => f.kind == SpecFieldKind.list && f.elementType == _revisionEntry,
      )
      .firstOrNull;
  if (history == null || rootClass == null) return;
  final date = _isoDate(options.date);
  final header = rootClass.fields
      .where((f) => f.type == _documentHeader)
      .firstOrNull;
  final headerForm = header == null
      ? null
      : _classField(
          refl.classNamed(_documentHeader),
          'content',
          SpecFieldKind.form,
        );
  final current = header != null && headerForm != null
      ? merged.formField(
          '$root/${refl.fieldSegment(header)}/${refl.fieldSegment(headerForm)}',
          'version',
        )
      : null;
  final version = _nextMinor(current);
  final item = _addGeneratedItem(
    merged,
    '$root/${refl.fieldSegment(history)}',
    history,
    date,
  );
  final entry = refl.classNamed(_revisionEntry);
  final form = _classField(entry, 'content', SpecFieldKind.form);
  if (form != null) {
    final path = '$item/${refl.fieldSegment(form)}';
    merged
      ..setFormField(path, 'version', version)
      ..setFormField(path, 'date', options.date)
      ..setFormField(path, 'author', options.author);
  }
  final team = {for (final m in options.team) m.memberId};
  final records = <(String, List<SpecReviewMember>, bool Function(String))>[
    ('reviewTeam', options.team, (_) => false),
    ('reviewers', copies, (id) => !team.contains(id)),
  ];
  for (final (name, members, guest) in records) {
    final list = _classField(entry, name, SpecFieldKind.list);
    if (list == null) continue;
    for (final m in members) {
      _addReviewerRecord(
        merged,
        refl,
        '$item/${refl.fieldSegment(list)}',
        list,
        m,
        guest(m.memberId),
        date,
      );
    }
  }
  ctx.report.revision = SpecMergeRevision(path: item, version: version);
}

/// The root segment of a document: the first segment of its paths.
String? _rootOf(SpecDocument doc, SpecReflection refl) {
  final json = doc.toJson();
  for (final key in ['content', 'forms', 'lists', 'headlines']) {
    final m = json[key];
    if (m is Map && m.isNotEmpty) {
      return (m.keys.first as String).split('/').first;
    }
  }
  return refl.roots.isNotEmpty ? refl.rootSegment(refl.roots.first) : null;
}

SpecReviewMergeResult<SpecDocument> _mergeSom(
  SpecDocument base,
  List<SpecReviewedCopy<SpecDocument>> copies,
  SpecReviewMergeOptions options,
  SpecModel model,
) {
  final refl = SpecReflection(model);
  _checkStructure(base, 'the base', refl);
  for (final c in copies) {
    _checkStructure(c.document, 'the copy of ${c.memberId}', refl);
  }
  final baseValues = _SomTexts(base).values();
  final copyValues = [for (final c in copies) _SomTexts(c.document).values()];
  final ids = _blockIds(baseValues);
  final ctx = _MergeContext(copies, ids.comments, ids.questions);
  final merged = _copyDocument(base);
  final added = _mergeStructure(merged, base, copies, refl, model, ctx);
  final values = _somValues(merged, base, copies, added, refl);
  final root = _rootOf(base, refl);
  final rootClass = root == null
      ? null
      : refl.classNamed(refl.rootForSegment(root)?.type);
  final rootContent = _classField(rootClass, 'content', SpecFieldKind.content);
  final homePath = root != null && rootContent != null
      ? '$root/${refl.fieldSegment(rootContent)}'
      : null;
  _mergeTexts(
    values,
    (v) => v.field == null ? _contentKey(v.path) : _fieldKey(v.path, v.field!),
    _SomTexts(merged),
    baseValues,
    copyValues,
    copies,
    options,
    homePath == null ? null : (key: _contentKey(homePath), path: homePath),
    ctx,
  );
  if (root != null) {
    _addRevisionEntry(merged, root, copies, options, refl, ctx);
  }
  return SpecReviewMergeResult(merged, ctx.report);
}
