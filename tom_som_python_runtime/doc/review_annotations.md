# Review annotations — `tom_som_python_runtime`

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

```python
from tom_som_runtime import SpecDocument, SpecQuestionDraft, SpecReviewAnnotations

doc = SpecDocument()
doc.load_json({
    "content": {
        "DEMO/SUM": "Sessions expire after 30 minutes.\n\n"
        "> ⬆️ (Alexis): Too long for kiosks.",
    },
})
review = SpecReviewAnnotations(doc, qualifier="DEMO")
print(review.assign_comment_ids())
print(review.list()[0].qualified_id)
review.insert_question_after_comment(
    "C-1",
    SpecQuestionDraft(id="BQ-1", topic="C-1 kiosks", text="Kiosks only?"),
)
review.set_answer("BQ-1", "yes")
print(review.counts().to_json())
```

Output:

```text
['C-1']
DEMO C-1
{'questions': 1, 'openQuestions': 0, 'answeredQuestions': 1, 'comments': 1, 'marks': 0}
```

## Core Components

All are exported from `tom_som_runtime`.

| Type | Role |
|------|------|
| `SpecReviewAnnotations` | The operations, over one `SpecDocument`; `qualifier` is the document id written in front of a comment id cited outside it (`SBP C-12`) |
| `SpecReviewAnnotation` | One listed annotation: `kind`, `path`, `field`, `line`, `id`, `qualified_id`, `author`, `text`, `context`, `topic`, `starred`, `combined`, `answer`, `open`, `mark_kind`, `new_text`, `comment`. `to_json()` is the form the conformance corpus pins |
| `SpecReviewAnnotationKind` | `COMMENT`, `QUESTION`, `MARK` (values `comment`, `question`, `mark`) |
| `SpecMarkKind` | `COMMENT`, `HIGHLIGHT`, `INSERTION`, `DELETION`, `SUBSTITUTION` (values in lower case) |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options`, `recommendation`, `assumption`, `starred`, and `recommended`, the letter whose option is written bold; `from_json` reads the corpus form |
| `SpecParagraph` | One paragraph of a value: `index`, `start_line`, `end_line` (0-based, inclusive), `text`, `annotation`; `to_json()` |
| `SpecQuestionOption` | One option of a question: `letter`, `text` (continuation lines joined), `bold` |
| `SpecReviewAnnotationCounts` | `questions`, `open_questions`, `answered_questions`, `comments`, `marks`; `to_json()` |
| `SpecReviewAnnotationError` | An operation named something that is not there |
| `strip_annotations_text` | One value without its annotations |
| `format_comment_block` / `format_question_block` | The lines of a block, as the insert operations write them |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question carries its `options`, its `recommended` letter (the bold option, else the option that says "recommended", else the letter of a `*Recommendation:*` line) and its `answer_letter` (`(b)` or `**(b)**` at the start of the answer). A question of a combined block carries `combined=True` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `next_comment_id(floor=0)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assign_comment_ids(floor=0)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `paragraphs(path, field=None)` | The value's paragraphs (`SpecParagraph`), each with its `index` (what `after_paragraph` takes), `start_line` / `end_line` within the value, its `text` and `annotation` (`comment` / `question` for an annotation block, else None). The rule is SOM §11.9.1 "Paragraphs": blank-line separated, a blank line inside fenced code does not end one. A value the document does not hold raises |
| `insert_comment(path, after_paragraph, text, field=None, author=None, id=None)` | A comment block after paragraph `after_paragraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless given) |
| `insert_question(path, after_paragraph, question, field=None)` | A question block after a paragraph |
| `insert_question_after_comment(comment_id, question)` | A question block directly after a comment block |
| `set_answer(question_id, answer)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `edit_comment(comment_id, text)` | New text; the marker, id and author stay as written |
| `resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `apply_mark(path, index, field=None, accept=True)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

Record each applied comment or answer in the project's log **before**
`resolve` removes it (`tom_specs_project_flow.md` PF-ITR-REV).

## Reviewing inline marks

| Operation | Does |
|-----------|------|
| `revision()` | The revision the mark ids are stable for (16 hex digits); any change to a value changes it |
| `list_marks(path=None)` | Every inline mark of the document or of a subtree: `M-<n>` id, kind, path, old and new text, markup, the paragraph holding it |
| `decide_marks(decisions, revision)` | One write: `{id: SpecMarkDecision.ACCEPT / REJECT / LEAVE}`. Refused when the document is no longer at `revision`, or when an id is unknown |
| `accept_all_marks(path=None)`, `reject_all_marks(path=None)` | Every mark under a path, or in the whole document, except change comments, which stay |
| `remove_all_annotations()` | Every mark accepted (change comments removed too) and every comment and question block removed, written back |
| `decide_all_marks_text(text, accept)` | One value as accept all / reject all write it |
| `apply_inline_marks_text(text, accept)` | One value with every mark accepted or rejected and every comment removed |

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

The whitespace rules (words never join, an edge space written inside a change
mark is kept after punctuation — `sentence.{++ Next sentence.++}` accepts to
`sentence. Next sentence.` —, no double space and no space before punctuation,
a whole-line mark leaves no blank line) are SOM §11.9.3.

```python
review = SpecReviewAnnotations(doc)
rev = review.revision()
marks = review.list_marks()
report = review.decide_marks({marks[0].id: SpecMarkDecision.ACCEPT}, revision=rev)
```

### Writing changes as marks

| Operation | Does |
|-----------|------|
| `mark_change_text(old, new)` | `new` with every difference from `old` marked. Accepting all marks gives `new`, rejecting all gives `old`. Returns a `SpecMarkedChange` (`text`, `exact`) |
| `set_marked(path, text, field=None)` | Writes `text` as a marked change against the value there. A value that already holds marks is compared from its original, so a second edit updates its mark |
| `mark_against(path, earlier, field=None)` | Marks the value already written against an earlier version |

`exact` is false only when a difference could not be marked, i.e. a change
inside fenced code. The new text is then written unmarked.

```python
r = mark_change_text(
    "Sessions expire after 30 minutes.",
    "Sessions expire after 15 minutes.",
)
print(r.text)  # Sessions expire after {~~ 30 ~> 15 ~~} minutes.
```

## Comments on changes

A change comment is a comment mark that starts with a quote of the change it
is about, written directly after that change:
`{~~ 30 ~> 15 ~~}{>> [~~ 30 ~> 15 ~~] why shorter? <<}`. The quote keeps the
comment readable once the change is decided. The notation is SOM §11.9.3.

| Operation | Does |
|-----------|------|
| `list_marks()` | A change comment's entry carries `quoted_change` (`kind`, `oldText`, `newText`, `outcome`) and `change_id`, its `comment` being the text after the quote. Its change's entry carries `comment_id` |
| `decide_marks`, `apply_mark`, `accept_all_marks`, `reject_all_marks` | Deciding a change leaves its attached comment, the quote recording ` \| accepted` or ` \| rejected`. Deciding the comment itself removes it |
| `comment_change(mark_id, text, author=None, revision=None)` | Writes a change comment after the change `mark_id`, its quote taken from the mark; returns the comment's id |
| `edit_mark_comment(mark_id, text, revision=None)` | Replaces the comment of a comment mark, change comment or commented highlight. A change comment keeps its quote |
| `set_marked(...)` | Keeps the value's change comments; a comment on a change marked again follows the new mark, detached, with its old quote |

A quote opened and never closed makes the comment a plain one, and
`validate()` reports it as `annotationMalformed`.

```python
review = SpecReviewAnnotations(doc)
rev = review.revision()
change = review.list_marks()[0]  # {~~ 30 ~> 15 ~~}
comment_id = review.comment_change(
    change.id, "why shorter?", author="alice", revision=rev
)
review.decide_marks(
    {change.id: SpecMarkDecision.ACCEPT}, revision=review.revision()
)
# after 15{>> [~~ 30 ~> 15 ~~ | accepted] why shorter? <<}{@alice} minutes
```

`comment_id` is the new comment's `M-<n>`, valid for the revision after the
write.

## Extracting answers for a step folder

A step of the TomSpecs process opens by collecting the reviewer's answers and
comments into its step folder's `answers.md`. The annotations stay in the
document, and the extraction never writes.

| Operation | Does |
|-----------|------|
| `extract_answers(model, doc, label, path=None)` | A `SpecAnswerExtract`: every question (answered or open), comment and inline mark of the document or of a subtree, with its section-id chain and its line in the document's Markdown rendition, in rendition order |
| `render_answers(extracts, options=SpecAnswerRenderOptions())` | The `answers.md` text. Deterministic: the documents in the order given, then their entries. `SpecAnswerRenderOptions` adds the open questions (`include_open`) and the inline marks (`include_marks`), and sets the `title` |
| `SpecAnswerExtract.counts` | A `SpecAnswerCounts`: answered, open, comments, marks — what a step's closing item reports |

Each entry is a `SpecAnswerEntry` whose `kind` is a `SpecAnswerKind`
(`ANSWERED`, `OPEN`, `COMMENT`, `MARK`). A comment is cited with the document
root's id in front (`SBP C-12`). A comment without an id is listed by its
line; `assign_comment_ids` gives it one, when asked.

```python
x = extract_answers(model, doc, label="tom_uam.sbp")
with open("answers.md", "w", encoding="utf-8") as fh:
    fh.write(render_answers([x], SpecAnswerRenderOptions(include_open=True)))
print(x.counts.to_json())  # {'answered': 75, 'open': 269, 'comments': 0, 'marks': 0}
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
| Attribution token | Part of its mark: in the `markup`, removed with the mark by every decision. `SpecReviewAnnotation` and `SpecMarkEntry` carry `authors` (member ids) and `votes` (`SpecMarkVote`: `member`, `vote` = `SpecVote.ACCEPT` / `SpecVote.REJECT`), both empty without a token |
| Individual answers | `SpecReviewAnnotation.answers`: `SpecIndividualAnswer` (`members`, `answer`, `answer_letter`), in the order written. The question's `text` ends before the first of them; `answer` stays the team's |
| Conflict block | Kind `SpecReviewAnnotationKind.CONFLICT` (`"conflict"`): `id`, `qualified_id`, `topic`, `text`, `base`, `alternatives` (`SpecConflictAlternative`: `letter`, `members`, `text`), the decision as `answer` (`decision` in JSON), `decision_letter` (`a`…, `base` or `None`), `open`, `unresolved`. `paragraphs()` marks the block `conflict` |
| `open:` | `unresolved` is true and `open` false on the question or conflict; a question's `answer_letter` is then `None` |

`counts()` adds `unresolved_questions` (also counted as answered), `conflicts`
and `open_conflicts`. The `to_json` methods take `team=True` for the members
`team_annotation_cases.json` pins; without it they are the forms of the older
case files.

**Writing.** `set_answer(question_id, answer, author=member_id)` writes that
member's individual answer instead of the team's, grouped by SOM §11.9.8: a
plain letter answer joins the line with the same answer, a commented one gets
its own line, an empty one only takes the member out. An author that is not a
member id (`is_review_member_id`) raises `SpecReviewAnnotationError`.
`remove_all_annotations()` applies every conflict's decision and lists it in
the report's `conflicts` (`SpecConflictOutcome`: `id`, `path`, `field`, `line`,
`decision`, `result`); it raises, changing nothing, while a conflict is open,
unresolved or malformed. A structural conflict (`Item removed`, `Item moved`,
`Headline changed`) only loses its block: its decision is the caller's to
apply. `stripped()` keeps a conflict's base text and drops the block.

**Merging.** `merge_reviews(base, copies, options)` merges the returned copies
into a new document and returns a `SpecReviewMergeResult` (`merged`,
`report`); neither the base nor a copy is changed.

| Argument | Is |
|----------|----|
| `base` | A `SpecDocument` (merged by model path, list items matched by section id) or a Markdown `str` (merged by heading path) |
| `copies` | A list of `SpecReviewedCopy` in round order: `member_id`, `display_name`, `role`, `document` (of the base's type) |
| `options` | `SpecReviewMergeOptions`: `team` (`SpecReviewMember`s, the members the round started with), `date` (ISO 8601: the revision entry's date and every generated list-item id's), `author`, `question_prefix` (default `RQ`), and `model`, required for a `SpecDocument` |

A copy whose structure does not fit the base (a path the model does not
resolve; other headings in Markdown) raises `SpecReviewMergeError` and nothing
is merged. The report, `SpecReviewMergeReport`, lists in merged document
order `reviewers` (with `guest`), `conflicts` (`id`, `path`, `field`,
`paragraph`, `members`), `votes`, `unanimous`, `answers`, `comments`,
`additions`, `guest_questions` and the `revision` entry (`None` without a
revision history); `to_json()` is the form `review_merge_cases.json` pins.

```python
from tom_som_runtime import (
    SpecReviewedCopy,
    SpecReviewMember,
    SpecReviewMergeOptions,
    merge_reviews,
)

team = (
    SpecReviewMember("alice", "Alice Owner", "Product owner"),
    SpecReviewMember("bob", "Bob Dev", "Developer"),
)
base = "# Sessions\n\nSessions expire after 30 minutes.\n"
changed = "# Sessions\n\nSessions expire after 15 minutes.\n"
result = merge_reviews(
    base,
    [SpecReviewedCopy(m.member_id, m.display_name, m.role, changed) for m in team],
    SpecReviewMergeOptions(team=team, date="2026-11-05", author="Alice Owner"),
)
print(result.merged)
print(len(result.report.conflicts))
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
| Question | in parentheses after the id, `**❓ BQ-1 (2026-11-07T14:05+01:00) — Timeout:**` |
| Team answer | in the label's parentheses, `**Answer (2026-11-07T14:05+01:00):**` (a time alone marks the team's answer) |

The writes record it, each with an optional `at=` (ISO 8601 with an offset or
`Z`; seconds are cut, any other shape raises `SpecReviewAnnotationError`):
`insert_comment`, `edit_comment` (the author stays), `comment_change`,
`edit_mark_comment` (authors and votes stay), `set_marked` and `mark_against`
(both take an optional `author=`; a mark written again unchanged keeps its
token), `insert_question` and `insert_question_after_comment` (the header),
and `set_answer` (an individual answer with an `author=`, else the team
answer; reopening writes `**Answer:**` without a time). Without `at` the time comes from the
`clock` the `SpecReviewAnnotations` was made with, else from the system clock.
Deciding, voting, answering and merging keep the times; removing an annotation
takes its time with it. `normalize_review_time`, `is_review_time` and
`system_review_time` are the helpers.

Reading reports `changed_at` on `SpecReviewAnnotation` (comments, marks and
questions — a question's is its header time), `SpecMarkEntry` and
`SpecIndividualAnswer`, and `answer_changed_at` (the team answer's time) on a
question; `to_json` writes each (as `changedAt` / `answerChangedAt`) only when
there is one. `review_team_answer_times` lists the team answers' times by
question id; merging copies carries a copy's team-answer time into the
member's individual answer.

```python
review = SpecReviewAnnotations(doc, clock=lambda: "2026-11-07T14:05+01:00")
review.insert_comment(path="DEMO/SUM", after_paragraph=0, text="Why 15?", author="alexis")
# > ⬆️ **C-1** (alexis, 2026-11-07T14:05+01:00): Why 15?
review.edit_comment("C-1", "Why 15 and not 20?", at="2026-11-08T09:00Z")
# > ⬆️ **C-1** (alexis, 2026-11-08T09:00Z): Why 15 and not 20?
```

## Validation

`validate_document` reports annotation findings as its last group, ordered by
path:

| Code | When |
|------|------|
| `SpecValidationCode.ANNOTATION_MISPLACED` (`annotationMisplaced`) | A comment, question or conflict block inside a form field's value |
| `SpecValidationCode.ANNOTATION_MALFORMED` (`annotationMalformed`) | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer (individual answers too) inside a comment block; an attribution token that is empty, unclosed, names a non-member id or a member twice, votes on a highlight or comment mark, or follows no mark directly; a member answering one question twice; a conflict header that is not `⚖️ **X-<n> — <topic>:**`, a conflict without `(base)` or without a lettered alternative |
| `SpecValidationCode.DUPLICATE_ANNOTATION_ID` (`duplicateAnnotationId`) | A comment, question or conflict id used twice in one document |

They are findings, never parse rejections: the document still loads.
`SpecReviewAnnotations(doc).validate()` returns the same group on its own.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there raises `SpecReviewAnnotationError` and changes nothing. `list`,
`counts`, `next_comment_id` and `stripped` never raise.

## Best Practices

- Call `assign_comment_ids` when a reviewed document comes back, so every
  comment can be cited and logged by id.
- Pass the comment log's highest number as `floor`, so a number freed by a
  resolved comment is not handed out again.
- Never write `stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
