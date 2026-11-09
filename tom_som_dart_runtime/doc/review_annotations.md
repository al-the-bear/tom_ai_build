# Review annotations — `tom_som_dart_runtime`

Reviewers comment on a TomSpecs document inside its text, the agent asks its
questions there, and suggestions are written as inline marks. `SpecReviewAnnotations`
reads those annotations out of a document's content and form-field values and
edits them in place. Every edit leaves the rest of the value byte for byte as it
was.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Operations](#operations)
- [Reviewing inline marks](#reviewing-inline-marks)
- [Comments on changes](#comments-on-changes)
- [Extracting answers for a step folder](#extracting-answers-for-a-step-folder)
- [Team reviews](#team-reviews)
- [Change times](#change-times)
- [Validation](#validation)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

The notation is `som_multiplatform_spec_model.md` §11.9 (the subject-matter
tier); this guide covers only the API. There are three kinds of annotation:

| Kind | Written as |
|------|------------|
| Comment block | `> ⬆️ **C-12** (Alexis): text` — id and author optional |
| Question block | `> **❓ BQ-81 — topic:** question` … `> **Answer:**`, or the combined `> **❓ Open questions on these fields**` form |
| Inline mark | `{>> … <<}`, `{== … ==}{>> … <<}`, `{++ … ++}`, `{-- … --}`, `{~~ old ~> new ~~}` |

Nothing inside fenced code or an inline code span is an annotation.

The values are visited in one fixed order in all nine runtimes, and that order
is "document order" for every operation: content paths sorted, then form paths
sorted, each with its field names sorted. A position is the 0-based line
within the value.

## Quick Start

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  final doc = SpecDocument()
    ..loadJson({
      'content': {
        'DEMO/SUM': 'Sessions expire after 30 minutes.\n\n'
            '> ⬆️ (Alexis): Too long for kiosks.',
      },
    });
  final review = SpecReviewAnnotations(doc, qualifier: 'DEMO');
  print(review.assignCommentIds());
  print(review.list().single.qualifiedId);
  review.insertQuestionAfterComment(
    'C-1',
    const SpecQuestionDraft(id: 'BQ-1', topic: 'C-1 kiosks', text: 'Kiosks only?'),
  );
  review.setAnswer('BQ-1', 'yes');
  print(review.counts().toJson());
}
```

Output:

```text
[C-1]
DEMO C-1
{questions: 1, openQuestions: 0, answeredQuestions: 1, comments: 1, marks: 0}
```

## Core Components

| Type | Role |
|------|------|
| `SpecReviewAnnotations` | The operations, over one `SpecDocument`; `qualifier` is the document id written in front of a comment id cited outside it (`SBP C-12`) |
| `SpecReviewAnnotation` | One listed annotation: kind, path, field, line, id, author, text, context, topic, answer, mark kind, new text, comment. `toJson()` is the form the conformance corpus pins |
| `SpecReviewAnnotationKind` | `comment`, `question`, `mark` |
| `SpecMarkKind` | `comment`, `highlight`, `insertion`, `deletion`, `substitution` |
| `SpecQuestionDraft` | A question to insert: id, topic, text, options, recommendation, assumption, starred, and `recommended`, the letter whose option is written bold |
| `SpecQuestionOption` | One option of a question: `letter`, `text` (continuation lines joined), `bold` |
| `SpecReviewAnnotationCounts` | questions, open, answered, comments, marks |
| `SpecReviewAnnotationError` | An operation named something that is not there |
| `stripAnnotationsText` | One value without its annotations |
| `SpecMarkDecision`, `SpecMarkEntry`, `SpecMarkOutcome`, `SpecMarkIssue`, `SpecMarkReport` | The inline-mark review: decisions, listed marks, what was done, malformed marks |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question carries its `options`, its `recommended` letter (the bold option, else the option that says "recommended", else the letter of a `*Recommendation:*` line) and its `answerLetter` (`(b)` or `**(b)**` at the start of the answer). A question of a combined block carries `combined: true` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `nextCommentId({floor})` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assignCommentIds({floor})` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `paragraphs(path:, field:)` | The value's paragraphs, each with its `index` (what `afterParagraph` takes), `startLine` / `endLine` within the value, its `text` and `annotation` (`comment` / `question` for an annotation block). The rule is SOM §11.9.1 "Paragraphs": blank-line separated, a blank line inside fenced code does not end one. A value the document does not hold throws |
| `insertComment(path:, field:, afterParagraph:, text:, author:, id:)` | A comment block after paragraph `afterParagraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless given) |
| `insertQuestion(path:, field:, afterParagraph:, question:)` | A question block after a paragraph |
| `insertQuestionAfterComment(commentId, question)` | A question block directly after a comment block |
| `setAnswer(questionId, answer)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `editComment(commentId, text)` | New text; the marker, id and author stay as written |
| `resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `applyMark(path:, field:, index:, accept:)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

Record each applied comment or answer in the project's log **before**
`resolve` removes it (`tom_specs_project_flow.md` PF-ITR-REV).

## Reviewing inline marks

| Operation | Does |
|-----------|------|
| `revision()` | The revision the mark ids are stable for (16 hex digits); any change to a value changes it |
| `listMarks({path})` | Every inline mark of the document or of a subtree: `M-<n>` id, kind, path, old and new text, markup, the paragraph holding it |
| `decideMarks(decisions, revision:)` | One write: `{id → SpecMarkDecision.accept / reject / leave}`. Refused when the document is no longer at `revision`, or when an id is unknown |
| `acceptAllMarks({path})`, `rejectAllMarks({path})` | Every mark under a path, or in the whole document, except change comments, which stay |
| `removeAllAnnotations()` | Every mark accepted (change comments removed too) and every comment and question block removed, written back |
| `decideAllMarksText(text, accept:)` | One value as accept all / reject all write it |
| `applyInlineMarksText(text, accept:)` | One value with every mark accepted or rejected and every comment removed |

Each returns a `SpecMarkReport`. `applied` holds one `SpecMarkOutcome` per
mark: id, kind, path, decision, markup and result. `malformed` holds the
`SpecMarkIssue`s in scope (`unclosed`, `nested`, `noArrow`); those marks are
left as written.

| Mark | Accept | Reject |
|------|--------|--------|
| `{++ added ++}` | `added` | nothing |
| `{-- removed --}` | nothing | `removed` |
| `{~~ old ~> new ~~}` | `new` | `old` |
| `{== text ==}{>> c <<}`, `{== text ==}` | `text` | `text` |
| `{>> c <<}` | nothing | nothing |

The whitespace rules (words never join, no double space and no space before
punctuation, a whole-line mark leaves no blank line) are SOM §11.9.3.

```dart
final review = SpecReviewAnnotations(doc);
final rev = review.revision();
final marks = review.listMarks();
final report = review.decideMarks({
  marks.first.id: SpecMarkDecision.accept,
}, revision: rev);
```

### Writing changes as marks

| Operation | Does |
|-----------|------|
| `markChangeText(old, new)` | `new` with every difference from `old` marked. Accepting all marks gives `new`, rejecting all gives `old`. Returns a `SpecMarkedChange` (`text`, `exact`) |
| `setMarked(path:, field:, text:)` | Writes `text` as a marked change against the value there. A value that already holds marks is compared from its original, so a second edit updates its mark |
| `markAgainst(path:, field:, earlier:)` | Marks the value already written against an earlier version |

`exact` is false only when a difference could not be marked, i.e. a change
inside fenced code. The new text is then written unmarked.

```dart
final r = markChangeText(
  'Sessions expire after 30 minutes.',
  'Sessions expire after 15 minutes.',
);
print(r.text); // Sessions expire after {~~ 30 ~> 15 ~~} minutes.
```

## Comments on changes

A change comment is a comment mark that starts with a quote of the change it
is about, written directly after that change:
`{~~ 30 ~> 15 ~~}{>> [~~ 30 ~> 15 ~~] why shorter? <<}`. The quote keeps the
comment readable once the change is decided. The notation is SOM §11.9.3.

| Operation | Does |
|-----------|------|
| `listMarks()` | A change comment's entry carries `quotedChange` (`kind`, `oldText`, `newText`, `outcome`) and `changeId`, its `comment` being the text after the quote. Its change's entry carries `commentId` |
| `decideMarks`, `applyMark`, `acceptAllMarks`, `rejectAllMarks` | Deciding a change leaves its attached comment, the quote recording ` \| accepted` or ` \| rejected`. Deciding the comment itself removes it |
| `commentChange(markId, text, author:, revision:)` | Writes a change comment after the change `markId`, its quote taken from the mark; returns the comment's id |
| `editMarkComment(markId, text, revision:)` | Replaces the comment of a comment mark, change comment or commented highlight. A change comment keeps its quote |
| `setMarked(...)` | Keeps the value's change comments; a comment on a change marked again follows the new mark, detached, with its old quote |

A quote opened and never closed makes the comment a plain one, and
`validate()` reports it as `annotationMalformed`.

```dart
final review = SpecReviewAnnotations(doc);
final rev = review.revision();
final change = review.listMarks().first; // {~~ 30 ~> 15 ~~}
final commentId = review.commentChange(
  change.id,
  'why shorter?',
  author: 'alice',
  revision: rev,
);
review.decideMarks({change.id: SpecMarkDecision.accept},
    revision: review.revision());
// after 15{>> [~~ 30 ~> 15 ~~ | accepted] why shorter? <<}{@alice} minutes
```

`commentId` is the new comment's `M-<n>`, valid for the revision after the
write.

## Extracting answers for a step folder

A step of the TomSpecs process opens by collecting the reviewer's answers and
comments into its step folder's `answers.md`. The annotations stay in the
document, and the extraction never writes.

| Operation | Does |
|-----------|------|
| `extractAnswers(model, doc, label:, path:)` | A `SpecAnswerExtract`: every question (answered or open), comment and inline mark of the document or of a subtree, with its section-id chain and its line in the document's Markdown rendition, in rendition order |
| `renderAnswers(extracts, options:)` | The `answers.md` text. Deterministic: the documents in the order given, then their entries. `SpecAnswerRenderOptions` adds the open questions (`includeOpen`) and the inline marks (`includeMarks`), and sets the title |
| `SpecAnswerExtract.counts` | answered, open, comments, marks: what a step's closing item reports |

A comment is cited with the document root's id in front (`SBP C-12`). A
comment without an id is listed by its line; `assignCommentIds` gives it one,
when asked. The command line is `tom_specs_clitool`'s `extract_answers`.

```dart
final x = extractAnswers(model, doc, label: 'tom_uam.sbp');
File('answers.md').writeAsStringSync(
  renderAnswers([x], options: const SpecAnswerRenderOptions(includeOpen: true)),
);
print(x.counts.toJson()); // {answered: 75, open: 269, comments: 0, marks: 0}
```

## Team reviews

A team review adds four notations to a merged document: an attribution token
after a mark (`{++ text ++}{@alice}`, votes as `{@agent +alice -bob}`),
individual answers (`**Answer (alice, bob):**` before the team's
`**Answer:**`), conflict blocks (`> ⚖️ **X-3 — topic:** …` with a
`**Decision:**`) and `open:` answers for items the team leaves unresolved. They
are `som_multiplatform_spec_model.md` §11.9.8, with their cases in
`tom_som_conformance/corpus/team_annotation_cases.json`. The merge of a round's
returned copies into one document in that notation, `mergeReviews`, is SOM §11.9.9,
with its cases in `tom_som_conformance/corpus/review_merge_cases.json`.

The runtime reads and writes all four, and its conformance driver runs both
case files.

**Reading.** `SpecReviewAnnotations` lists the notation with the operations
above:

| Notation | Listed as |
|----------|-----------|
| Attribution token | Part of its mark: in the `markup`, removed with the mark by every decision. `SpecReviewAnnotation` and `SpecMarkEntry` carry `authors` (member ids) and `votes` (`SpecMarkVote`: `member`, `vote` = `SpecVote.accept` / `SpecVote.reject`), both empty without a token |
| Individual answers | `SpecReviewAnnotation.answers`: `SpecIndividualAnswer` (`members`, `answer`, `answerLetter`), in the order written. The question's `text` ends before the first of them; `answer` stays the team's |
| Conflict block | Kind `SpecReviewAnnotationKind.conflict`: `id`, `qualifiedId`, `topic`, `text`, `base`, `alternatives` (`SpecConflictAlternative`: `letter`, `members`, `text`), the decision as `answer` (`decision` in JSON), `decisionLetter` (`a`…, `base` or null), `open`, `unresolved`. `paragraphs()` marks the block `conflict` |
| `open:` | `unresolved: true` and `open: false` on the question or conflict; a question's `answerLetter` is then null |

`counts()` adds `unresolvedQuestions` (also counted as answered), `conflicts`
and `openConflicts`. The `toJson` methods take `team: true` for the members
`team_annotation_cases.json` pins; without it they are the forms of the older
case files.

**Writing.** `setAnswer(questionId, answer, author: memberId)` writes that
member's individual answer instead of the team's, grouped by SOM §11.9.8: a
plain letter answer joins the line with the same answer, a commented one gets
its own line, an empty one only takes the member out. An author that is not a
member id (`isReviewMemberId`) throws `SpecReviewAnnotationError`.
`removeAllAnnotations()` applies every conflict's decision and lists it in the
report's `conflicts` (`SpecConflictOutcome`: `id`, `path`, `field`, `line`,
`decision`, `result`); it throws, changing nothing, while a conflict is open,
unresolved or malformed. A structural conflict (`Item removed`, `Item moved`,
`Headline changed`) only loses its block: its decision is the caller's to
apply. `stripped()` keeps a conflict's base text and drops the block.

**Merging.** `mergeReviews(base, copies, options)` merges the returned copies
into a new document and returns a `SpecReviewMergeResult` (`merged`,
`report`); neither the base nor a copy is changed.

| Argument | Is |
|----------|----|
| `base` | A `SpecDocument` (merged by model path, list items matched by section id) or a Markdown `String` (merged by heading path) |
| `copies` | `List<SpecReviewedCopy<D>>` in round order: `memberId`, `displayName`, `role`, `document` (of the base's type `D`) |
| `options` | `SpecReviewMergeOptions`: `team` (`List<SpecReviewMember>`, the members the round started with), `date` (ISO 8601: the revision entry's date and every generated list-item id's), `author`, `questionPrefix` (default `RQ`), and `model`, required for a `SpecDocument` |

A copy whose structure does not fit the base (a path the model does not
resolve; other headings in Markdown) throws `SpecReviewMergeError` and nothing
is merged. The report, `SpecReviewMergeReport`, lists in merged document
order `reviewers` (with `guest`), `conflicts` (`id`, `path`, `field`,
`paragraph`, `members`), `votes`, `unanimous`, `answers`, `comments`,
`additions`, `guestQuestions` and the `revision` entry (null without a revision
history); `toJson()` is the form `review_merge_cases.json` pins.

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  const team = [
    SpecReviewMember(
      memberId: 'alice',
      displayName: 'Alice Owner',
      role: 'Product owner',
    ),
    SpecReviewMember(memberId: 'bob', displayName: 'Bob Dev', role: 'Developer'),
  ];
  const base = '# Sessions\n\nSessions expire after 30 minutes.\n';
  const changed = '# Sessions\n\nSessions expire after 15 minutes.\n';
  final result = mergeReviews(base, [
    for (final m in team)
      SpecReviewedCopy(
        memberId: m.memberId,
        displayName: m.displayName,
        role: m.role,
        document: changed,
      ),
  ], const SpecReviewMergeOptions(
    team: team,
    date: '2026-11-05',
    author: 'Alice Owner',
  ));
  print(result.merged);
  print(result.report.conflicts.length);
}
```

Output:

```text
# Sessions

Sessions expire after {~~ 30 ~> 15 ~~}{@alice,bob} minutes.

0
```

A unit whose copy no longer holds more than 16 of the base's marks as written
is read as an edit (step 4 of SOM §11.9.9): the decision combinations would
grow past 65536.

## Change times

Every annotation records when it was last changed, next to its author, so a
reviewer sees what is new since the last round (SOM §11.9.10). The time is
minutes with the writer's UTC offset, `2026-11-07T14:05+01:00`:

| Annotation | Written as |
|------------|------------|
| Inline mark | last word of its attribution token, `{@alice 2026-11-07T14:05+01:00}` or `{@2026-11-07T14:05+01:00}` |
| Comment block | last part of the header's parentheses, `(Alexis, 2026-11-07T14:05+01:00):` |
| Individual answer | last part of the member list, `**Answer (alice, 2026-11-07T14:05+01:00):**` |

The writes record it, each with an optional `at:` (ISO 8601 with an offset or
`Z`; seconds are cut, any other shape throws `SpecReviewAnnotationError`):
`insertComment`, `editComment` (the author stays), `commentChange`,
`editMarkComment` (authors and votes stay), `setMarked` and `markAgainst`
(both take an optional `author:`; a mark written again unchanged keeps its
token) and `setAnswer` with an `author:`. Without `at` the time comes from the
`clock` the `SpecReviewAnnotations` was made with, else from the system clock.
Deciding, voting, answering and merging keep the times; removing an annotation
takes its time with it. `normalizeReviewTime`, `isReviewTime` and
`systemReviewTime` are the helpers.

Reading reports `changedAt` on `SpecReviewAnnotation` (comments and marks),
`SpecMarkEntry` and `SpecIndividualAnswer`; `toJson` writes it only when there
is one.

```dart
final review = SpecReviewAnnotations(doc, clock: () => '2026-11-07T14:05+01:00');
review.insertComment(path: 'SBP/INSC', afterParagraph: 0, text: 'Why 15?',
    author: 'alexis');
// > ⬆️ **C-1** (alexis, 2026-11-07T14:05+01:00): Why 15?
review.editComment('C-1', 'Why 15 and not 20?', at: '2026-11-08T09:00Z');
// > ⬆️ **C-1** (alexis, 2026-11-08T09:00Z): Why 15 and not 20?
```

## Validation

`validateDocument` reports annotation findings as its last group, ordered by
path:

| Code | When |
|------|------|
| `annotationMisplaced` | A comment, question or conflict block inside a form field's value |
| `annotationMalformed` | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer (individual answers too) inside a comment block; an attribution token that is empty, unclosed, names a non-member id or a member twice, votes on a highlight or comment mark, or follows no mark directly; a member answering one question twice; a conflict header that is not `⚖️ **X-<n> — <topic>:**`, a conflict without `(base)` or without a lettered alternative |
| `duplicateAnnotationId` | A comment, question or conflict id used twice in one document |

They are findings, never parse rejections: the document still loads.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there throws `SpecReviewAnnotationError` and changes nothing. `list`,
`counts`, `nextCommentId` and `stripped` never throw.

## Best Practices

- Call `assignCommentIds` when a reviewed document comes back, so every comment
  can be cited and logged by id.
- Pass the comment log's highest number as `floor`, so a number freed by a
  resolved comment is not handed out again.
- Never write `stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
