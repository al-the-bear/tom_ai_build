# Review annotations — `tom_som_c_runtime`

Reviewers comment on a TomSpecs document inside its text, the agent asks its
questions there, and suggestions are written as inline marks.
`SpecReviewAnnotations` reads those annotations out of a document's content and
form-field values and edits them in place. Every edit leaves the rest of the
value byte for byte as it was.

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
- [Memory and Ownership](#memory-and-ownership)
- [Best Practices](#best-practices)

## Overview

The notation is `som_multiplatform_spec_model.md` §11.9 (the subject-matter
tier); this guide covers only the API, declared in
`include/spec_review_annotations.h` and included by `tom_som_c_runtime.h`.
There are three kinds of annotation:

| Kind | Written as |
|------|------------|
| Comment block | `> ⬆️ **C-12** (Alexis): text` — id and author optional |
| Question block | `> **❓ BQ-81 — topic:** question` … `> **Answer:**`, or the combined `> **❓ Open questions on these fields**` form |
| Inline mark | `{>> … <<}`, `{== … ==}{>> … <<}`, `{++ … ++}`, `{-- … --}`, `{~~ old ~> new ~~}` |

Nothing inside fenced code or an inline code span is an annotation.

The values are visited in one fixed order in all nine runtimes, and that order
is "document order" for every operation: content paths sorted, then form paths
sorted, each with its field names sorted. A position is the 0-based line
within the value; this runtime works on UTF-8 bytes internally and never
exports a byte offset.

## Quick Start

```c
#include <stdio.h>
#include <stdlib.h>

#include "tom_som_c_runtime.h"

int main(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "DEMO/SUM",
                            "Sessions expire after 30 minutes.\n\n"
                            "> ⬆️ (Alexis): Too long for kiosks.");
  SpecReviewAnnotations review = spec_review_annotations_make(&doc, "DEMO");

  SomStrList ids;
  spec_review_annotations_assign_comment_ids(&review, 0, &ids);
  printf("%s\n", ids.items[0]);
  som_strlist_free(&ids);

  SpecReviewAnnotationList list;
  spec_review_annotations_list(&review, &list);
  printf("%s\n", list.items[0].qualified_id);
  spec_review_annotation_list_free(&list);

  SpecQuestionDraft q = {.id = "BQ-1", .topic = "C-1 kiosks",
                         .text = "Kiosks only?"};
  SpecReviewAnnotationError err;
  spec_review_annotation_error_init(&err);
  if (!spec_review_annotations_insert_question_after_comment(&review, "C-1",
                                                             &q, &err) ||
      !spec_review_annotations_set_answer(&review, "BQ-1", "yes", &err)) {
    fprintf(stderr, "%s\n", err.message);
  }
  spec_review_annotation_error_free(&err);

  SpecReviewAnnotationCounts counts = spec_review_annotations_counts(&review);
  char *json = spec_review_annotation_counts_to_json(&counts);
  printf("%s\n", json);
  free(json);
  spec_document_free(&doc);
  return 0;
}
```

Output:

```text
C-1
DEMO C-1
{"questions":1,"openQuestions":0,"answeredQuestions":1,"comments":1,"marks":0}
```

## Core Components

| Type / function | Role |
|-----------------|------|
| `SpecReviewAnnotations` | The operations, over one borrowed `SpecDocument`; `qualifier` is the document id written in front of a comment id cited outside it (`SBP C-12`). Built with `spec_review_annotations_make` |
| `SpecReviewAnnotation` | One listed annotation: `kind`, `path`, `field`, `line`, `id`, `qualified_id`, `author`, `text`, `context`, `topic`, `starred`, `combined`, `answer`, `mark_kind`, `new_text`, `comment`. `spec_review_annotation_to_json` is the form the conformance corpus pins; `spec_review_annotation_is_open` says whether a question is open |
| `SpecReviewAnnotationList` | The owned list `spec_review_annotations_list` fills |
| `SpecReviewAnnotationKind` | `SPEC_REVIEW_ANNOTATION_COMMENT`, `_QUESTION`, `_MARK`, and `_CONFLICT` for a team review's conflict block (`spec_review_annotation_kind_name`) |
| `SpecMarkKind` | `SPEC_MARK_COMMENT`, `_HIGHLIGHT`, `_INSERTION`, `_DELETION`, `_SUBSTITUTION` (`spec_mark_kind_name`) |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options` / `options_len`, `recommendation`, `assumption`, `starred`, and `recommended`, the letter whose option is written bold (NULL for none) (all borrowed) |
| `SpecQuestionOption` | One option of a question: `letter`, `text` (continuation lines joined), `bold` (`spec_question_option_to_json`) |
| `SpecReviewAnnotationCounts` | `questions`, `open_questions`, `answered_questions`, `comments`, `marks` |
| `SpecReviewAnnotationError` | An operation named something that is not there |
| `spec_strip_annotations_text` | One value without its annotations |
| `spec_format_comment_block`, `spec_format_question_block` | The lines a comment or question block is written as |

## Operations

Every operation is `spec_review_annotations_<name>(&review, …)`.

| Operation | Does |
|-----------|------|
| `list(out)` | Every annotation, in document order. A question carries its `options` / `options_len`, its `recommended` letter (the bold option, else the option that says "recommended", else the letter of a `*Recommendation:*` line) and its answer letter (`spec_review_annotation_answer_letter`: `(b)` or `**(b)**` at the start of the answer). A question of a combined block carries `combined` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `next_comment_id(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assign_comment_ids(floor, out)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `paragraphs(path, field, out, err)` | The value's paragraphs as a `SpecParagraphList` of `SpecParagraph`, each with its `index` (what `after_paragraph` takes), `start_line` / `end_line` within the value, its `text` and `annotation` (`comment` / `question` for an annotation block, else `NULL`; `spec_paragraph_to_json`). The rule is SOM §11.9.1 "Paragraphs": blank-line separated, a blank line inside fenced code does not end one. A value the document does not hold is refused (returns 0) |
| `insert_comment(path, field, after_paragraph, text, author, id, at, err)` | A comment block after paragraph `after_paragraph` (0-based; -1 is the start), one blank line on each side, its header holding the change time ([Change times](#change-times)); returns its id (the next free one unless `id` is given) |
| `insert_question(path, field, after_paragraph, question, err)` | A question block after a paragraph |
| `insert_question_after_comment(comment_id, question, err)` | A question block directly after a comment block |
| `set_answer(question_id, answer, err)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing. `set_member_answer(question_id, author, answer, at, err)` writes a member's individual answer instead ([Team reviews](#team-reviews)) |
| `edit_comment(comment_id, text, at, err)` | New text; the marker, id and author stay as written, the change time is written anew |
| `resolve(id, err)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `apply_mark(path, field, index, accept, err)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

`field` is `NULL` for a content value. Record each applied comment or answer in
the project's log **before** `resolve` removes it (`tom_specs_project_flow.md`
PF-ITR-REV).

## Reviewing inline marks

Every operation is `spec_review_annotations_<name>(&review, …)` unless it says
otherwise.

| Operation | Does |
|-----------|------|
| `revision()` | The revision the mark ids are stable for (16 hex digits, owned); any change to a value changes it |
| `list_marks(path, out)` | Every inline mark of the document (`path` `NULL`) or of a subtree, as `SpecMarkEntry`: `M-<n>` id, `mark_kind`, `path`, `field`, `old_text` and `new_text`, `markup`, the paragraph holding it as `context` |
| `decide_marks(decisions, decisions_len, revision, out, err)` | One write: an array of `SpecMarkDecisionItem` `{id, SPEC_MARK_DECISION_ACCEPT / _REJECT / _LEAVE}`. Refused (returns 0, nothing changes) when the document is no longer at `revision`, or when an id is unknown |
| `accept_all_marks(path, out)`, `reject_all_marks(path, out)` | Every mark under a path, or in the whole document (`NULL`), except change comments, which stay |
| `remove_all_annotations(out, err)` | Every mark accepted (change comments removed too), every conflict's decision applied, and every comment, question and conflict block removed, written back; refused while a conflict is undecided ([Team reviews](#team-reviews)) |
| `spec_decide_all_marks_text(text, accept)` | One value as accept all / reject all write it (owned) |
| `spec_apply_inline_marks_text(text, accept)` | One value with every mark accepted or rejected and every comment removed (owned) |

Each fills a `SpecMarkReport` (`spec_mark_report_to_json`,
`spec_mark_report_free`). `applied` holds one `SpecMarkOutcome` per mark: id,
kind, path, decision, markup and result. `malformed` holds the
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

```c
char *rev = spec_review_annotations_revision(&review);
SpecMarkEntryList marks;
spec_review_annotations_list_marks(&review, NULL, &marks);
SpecMarkDecisionItem d = {marks.items[0].id, SPEC_MARK_DECISION_ACCEPT};
SpecMarkReport report;
SpecReviewAnnotationError err;
spec_review_annotation_error_init(&err);
if (!spec_review_annotations_decide_marks(&review, &d, 1, rev, &report, &err)) {
  fprintf(stderr, "%s\n", err.message);
}
spec_mark_report_free(&report);
spec_review_annotation_error_free(&err);
spec_mark_entry_list_free(&marks);
free(rev);
```

### Writing changes as marks

| Operation | Does |
|-----------|------|
| `spec_mark_change_text(old, new)` | `new` with every difference from `old` marked. Accepting all marks gives `new`, rejecting all gives `old`. Returns a `SpecMarkedChange` (`text`, owned; `exact`) |
| `spec_review_annotations_set_marked(&review, path, field, text, author, at, out, err)` | Writes `text` as a marked change against the value there, into `*out`. A value that already holds marks is compared from its original, so a second edit updates its mark. Every change mark gets an attribution token with its change time ([Change times](#change-times)) |
| `spec_review_annotations_mark_against(&review, path, field, earlier, author, at, out, err)` | Marks the value already written against an earlier version, into `*out` |

`exact` is 0 only when a difference could not be marked, i.e. a change inside
fenced code. The new text is then written unmarked. Release a result with
`spec_marked_change_free`; `spec_marked_change_to_json` gives
`{text, exact}`.

```c
SpecMarkedChange r = spec_mark_change_text(
    "Sessions expire after 30 minutes.", "Sessions expire after 15 minutes.");
printf("%s\n", r.text); /* Sessions expire after {~~ 30 ~> 15 ~~} minutes. */
spec_marked_change_free(&r);
```

## Comments on changes

A change comment is a comment mark that starts with a quote of the change it
is about, written directly after that change:
`{~~ 30 ~> 15 ~~}{>> [~~ 30 ~> 15 ~~] why shorter? <<}`. The quote keeps the
comment readable once the change is decided. The notation is SOM §11.9.3.

| Operation | Does |
|-----------|------|
| `list_marks(path, out)` | A change comment's `SpecMarkEntry` carries `quoted_change` (a `SpecQuotedChange`: `kind`, `old_text`, `new_text`, `outcome`) and `change_id`, its `comment` being the text after the quote. Its change's entry carries `comment_id`. All three are `NULL` on the other marks |
| `decide_marks`, `apply_mark`, `accept_all_marks`, `reject_all_marks` | Deciding a change leaves its attached comment, the quote recording ` \| accepted` or ` \| rejected`. Deciding the comment itself removes it |
| `comment_change(mark_id, text, author, revision, at, err)` | Writes a change comment after the change `mark_id`, its quote taken from the mark; returns the comment's id (owned), or `NULL` when refused |
| `edit_mark_comment(mark_id, text, revision, at, err)` | Replaces the comment of a comment mark, change comment or commented highlight. A change comment keeps its quote |
| `set_marked(path, field, text, author, at, out, err)` | Keeps the value's change comments; a comment on a change marked again follows the new mark, detached, with its old quote |

`author`, `revision` and `at` may be `NULL`. A refusal returns `NULL` (or 0),
fills `err` and changes nothing: an unknown id, a stale `revision`, a mark that
is not a change (or holds no comment), a change that already has a comment, a
`text` that is empty or holds a mark delimiter or a blank line, an `author`
that is not a member id, an `at` that is not a time.

A quote opened and never closed makes the comment a plain one, and
`validate()` reports it as `annotationMalformed`.

```c
char *rev = spec_review_annotations_revision(&review);
SpecMarkEntryList marks;
spec_review_annotations_list_marks(&review, NULL, &marks); /* {~~ 30 ~> 15 ~~} */
SpecReviewAnnotationError err;
spec_review_annotation_error_init(&err);
char *comment_id = spec_review_annotations_comment_change(
    &review, marks.items[0].id, "why shorter?", "alice", rev, NULL, &err);
if (comment_id == NULL) fprintf(stderr, "%s\n", err.message);
char *rev2 = spec_review_annotations_revision(&review);
SpecMarkDecisionItem d = {marks.items[0].id, SPEC_MARK_DECISION_ACCEPT};
SpecMarkReport report;
spec_review_annotations_decide_marks(&review, &d, 1, rev2, &report, &err);
/* after 15{>> [~~ 30 ~> 15 ~~ | accepted] why shorter? <<}{@alice <time>} minutes */
spec_mark_report_free(&report);
spec_review_annotation_error_free(&err);
spec_mark_entry_list_free(&marks);
free(comment_id);
free(rev2);
free(rev);
```

`comment_id` is the new comment's `M-<n>`, valid for the revision after the
write.

## Extracting answers for a step folder

A step of the TomSpecs process opens by collecting the reviewer's answers and
comments into its step folder's `answers.md`. The annotations stay in the
document, and the extraction never writes. The module is `spec_answers.h`.

| Operation | Does |
|-----------|------|
| `spec_extract_answers(model, doc, label, path, &out, &err)` | Fills a `SpecAnswerExtract`: every question (answered or open), comment and inline mark of the document or of the subtree at `path` (`NULL`: all), with its section-id chain and its line in the document's Markdown rendition, in rendition order. Returns 0 (writing `err`) when the rendition fails |
| `spec_render_answers(extracts, len, &options)` | The `answers.md` text (owned). Deterministic: the documents in the order given, then their entries. `SpecAnswerRenderOptions` adds the open questions (`include_open`) and the inline marks (`include_marks`), and sets the `title`; `spec_answer_render_options_default()` gives the defaults |
| `spec_answer_extract_counts(&x)` | A `SpecAnswerCounts`: answered, open, comments, marks — what a step's closing item reports |
| `spec_answer_extract_to_json(&x)` | `{label, qualifier, entries, counts}` (owned) |

An entry (`SpecAnswerEntry`) has a `kind` (`SPEC_ANSWER_ANSWERED`,
`SPEC_ANSWER_OPEN`, `SPEC_ANSWER_COMMENT`, `SPEC_ANSWER_MARK`). A comment is
cited with the document root's id in front (`SBP C-12`). A comment without an
id is listed by its line; `spec_review_annotations_assign_comment_ids` gives it
one, when asked. The command line is `tom_specs_clitool`'s `extract_answers`.

```c
SpecAnswerExtract x;
char *err = NULL;
if (spec_extract_answers(model, doc, "tom_uam.sbp", NULL, &x, &err)) {
  SpecAnswerRenderOptions o = spec_answer_render_options_default();
  o.include_open = 1;
  char *md = spec_render_answers(&x, 1, &o); /* write to answers.md */
  SpecAnswerCounts n = spec_answer_extract_counts(&x);
  printf("%zu answered, %zu open\n", n.answered, n.open);
  free(md);
  spec_answer_extract_free(&x);
} else {
  free(err);
}
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

**Reading.** `spec_review_annotations_list` and `_list_marks` list the
notation with the operations above:

| Notation | Listed as |
|----------|-----------|
| Attribution token | Part of its mark: in the `markup`, removed with the mark by every decision. `SpecReviewAnnotation` and `SpecMarkEntry` carry `authors` (a `SomStrList` of member ids) and `votes` / `votes_len` (`SpecMarkVote`: `member`, `accept`), both empty without a token |
| Individual answers | `SpecReviewAnnotation.answers` / `answers_len`: `SpecIndividualAnswer` (`members`, `answer`), in the order written. The question's `text` ends before the first of them; `answer` stays the team's |
| Conflict block | Kind `SPEC_REVIEW_ANNOTATION_CONFLICT` (`"conflict"`): `id`, `qualified_id`, `topic`, `text`, `base`, `alternatives` / `alternatives_len` (`SpecConflictAlternative`: `letter`, `members`, `text`), the decision as `answer` (`decision` in JSON), `spec_review_annotation_decision_letter` (`a`…, `base` or `NULL`), `spec_review_annotation_is_open`, `spec_review_annotation_is_unresolved`. `paragraphs` marks the block `conflict` |
| `open:` | `is_unresolved` 1 and `is_open` 0 on the question or conflict; a question's `answer_letter` is then `NULL` |

`counts` adds `unresolved_questions` (also counted as answered), `conflicts`
and `open_conflicts`. `spec_review_annotation_to_team_json`,
`spec_mark_entry_to_team_json`, `spec_review_annotation_counts_to_team_json`
and `spec_mark_report_to_team_json` give the members
`team_annotation_cases.json` pins; the plain `*_to_json` forms are those of the
older case files.

**Writing.** `set_member_answer(question_id, author, answer, at, err)` writes that
member's individual answer instead of the team's, grouped by SOM §11.9.8: a
plain letter answer joins the line with the same answer, a commented one gets
its own line, an empty one only takes the member out. An author that is not a
member id (`spec_review_is_member_id`) is refused (returns 0, `*err` filled).
`remove_all_annotations(out, err)` applies every conflict's decision and lists
it in the report's `conflicts` (`has_conflicts` set; `SpecConflictOutcome`:
`id`, `path`, `field`, `line`, `decision`, `result`); it is refused, changing
nothing, while a conflict is open, unresolved or malformed. A structural
conflict (`Item removed`, `Item moved`, `Headline changed`) only loses its
block: its decision is the caller's to apply. `stripped` keeps a conflict's base
text and drops the block. `spec_review_format_conflict_block(id, topic, text,
base, alternatives, alternatives_len, out)` gives the lines of a block.

**Merging.** `spec_review_merge.h` merges the returned copies into a new
document and a `SpecReviewMergeReport`; neither the base nor a copy is changed.

| Function | Merges |
|----------|--------|
| `spec_review_merge_documents(model, base, copies, copies_len, options, merged, report, err)` | A `SpecDocument` by the paths of `model`, list items matched by section id; `copies` are `SpecReviewedDocument`s (`member`, `document`). Returns 1; `*merged` and `*report` are the caller's to free |
| `spec_review_merge_markdown(base, copies, copies_len, options, report, err)` | A Markdown string by heading path; `copies` are `SpecReviewedMarkdown`s (`member`, `document`). Returns the merged text (owned) |

`copies` are in round order, each `member` a `SpecReviewMember` (`member_id`,
`display_name`, `role`, borrowed). `SpecReviewMergeOptions` holds `team` /
`team_len` (the members the round started with), `date` (ISO 8601: the
revision entry's date and every generated list-item id's), `author` and
`question_prefix` (`NULL` for `RQ`).

A copy whose structure does not fit the base (a path the model does not
resolve; other headings in Markdown) is refused: 0 or `NULL`, nothing merged,
`*err` (`SpecReviewMergeError`) filled. The report lists in merged document
order `reviewers` (with `guest`), `conflicts` (`id`, `path`, `field`,
`paragraph`, -1 for none, `members`), `votes`, `unanimous`, `answers`,
`comments`, `additions`, `guest_questions` and the revision entry
(`revision_path` `NULL` without a revision history);
`spec_review_merge_report_to_json` is the form `review_merge_cases.json` pins.
Release it with `spec_review_merge_report_free`.

```c
#include "tom_som_c_runtime.h"

SpecDocument base, alice_copy, bob_copy;
spec_document_init(&base);
spec_document_init(&alice_copy);
spec_document_init(&bob_copy);
spec_document_set_content(&base, "DEMO/SUM", "Sessions expire after 30 minutes.");
spec_document_set_content(&alice_copy, "DEMO/SUM", "Sessions expire after 15 minutes.");
spec_document_set_content(&bob_copy, "DEMO/SUM", "Sessions expire after 15 minutes.");

const SpecReviewMember team[2] = {
    {"alice", "Alice Owner", "Product owner"},
    {"bob", "Bob Dev", "Developer"},
};
const SpecReviewedDocument copies[2] = {{team[0], &alice_copy},
                                        {team[1], &bob_copy}};
SpecReviewMergeOptions options = {team, 2, "2026-11-05", "Alice Owner", NULL};

SpecDocument merged;
SpecReviewMergeReport report;
SpecReviewMergeError err;
spec_review_merge_error_init(&err);
if (spec_review_merge_documents(model, &base, copies, 2, &options, &merged,
                                &report, &err)) {
  printf("%s\n", spec_document_content(&merged, "DEMO/SUM"));
  printf("%zu\n", report.conflicts_len);
}
spec_review_merge_report_free(&report);
spec_document_free(&merged);
spec_review_merge_error_free(&err);
```

Output:

```text
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

The writes record it, each with an `at` argument (`NULL`, or ISO 8601 with an
offset or `Z`; seconds are cut, any other shape is refused: 0 or `NULL`,
`*err` filled, nothing changed): `insert_comment`, `edit_comment` (the author
stays), `comment_change`, `edit_mark_comment` (authors and votes stay),
`set_marked` and `mark_against` (both take an `author`, `NULL` for none; a mark
written again unchanged keeps its token) and `set_member_answer`. Without `at`
the time comes from the clock the `SpecReviewAnnotations` was made with
(`spec_review_annotations_make_with_clock(doc, qualifier, clock, context)`; a
`SpecReviewClock` returns a `malloc`ed string the runtime frees), else from the
system clock. Deciding, voting, answering and merging keep the times; removing
an annotation takes its time with it. `spec_review_normalize_time` (owned, or
`NULL` with `*err` filled), `spec_review_is_time`, `spec_review_system_time`
(owned) and `spec_review_format_attribution_token` are the helpers.

Reading reports `changed_at` (owned, `NULL` without one) on
`SpecReviewAnnotation` (comments and marks), `SpecMarkEntry` and
`SpecIndividualAnswer`; the JSON forms write `changedAt` only when there is one.

```c
static char *fixed_clock(void *context) {
  return som_strdup((const char *)context);
}

SpecReviewAnnotations review = spec_review_annotations_make_with_clock(
    &doc, "SBP", fixed_clock, (void *)"2026-11-07T14:05+01:00");
SpecReviewAnnotationError err;
spec_review_annotation_error_init(&err);
char *id = spec_review_annotations_insert_comment(
    &review, "SBP/INSC", NULL, 0, "Why 15?", "alexis", NULL, NULL, &err);
/* > ⬆️ **C-1** (alexis, 2026-11-07T14:05+01:00): Why 15? */
spec_review_annotations_edit_comment(&review, id, "Why 15 and not 20?",
                                     "2026-11-08T09:00Z", &err);
/* > ⬆️ **C-1** (alexis, 2026-11-08T09:00Z): Why 15 and not 20? */
free(id);
spec_review_annotation_error_free(&err);
```

## Validation

`validate_document` reports annotation findings as its last group, ordered by
path (`spec_review_annotations_validate` gives the group alone):

| Code | When |
|------|------|
| `SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED` (`annotationMisplaced`) | A comment or question block inside a form field's value |
| `SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED` (`annotationMalformed`) | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer inside a comment block |
| `SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID` (`duplicateAnnotationId`) | A comment or question id used twice in one document |

They are findings, never parse rejections: the document still loads.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there returns 0 (`insert_comment`: `NULL`), changes nothing, and writes an
owned message into the `SpecReviewAnnotationError` passed (which may be
`NULL`). `list`, `counts`, `next_comment_id` and `stripped` never fail.

## Memory and Ownership

`SpecReviewAnnotations` borrows its document, qualifier and clock context and
owns nothing.
Everything an operation returns is the caller's:

| Returned | Release with |
|----------|--------------|
| `SpecReviewAnnotationList` | `spec_review_annotation_list_free` |
| `SpecMarkEntryList` | `spec_mark_entry_list_free` |
| `SpecMarkReport` | `spec_mark_report_free` |
| `SpecAnswerExtract` | `spec_answer_extract_free` |
| `spec_render_answers`, `spec_answer_*_to_json` | `free` |
| revision, `spec_apply_inline_marks_text`, `spec_decide_all_marks_text` | `free` |
| `comment_change` id | `free` |
| `SpecMarkedChange` of `set_marked` / `mark_against` | `spec_marked_change_free` |
| `spec_review_normalize_time`, `spec_review_system_time`, `spec_review_format_attribution_token` | `free` |
| ids, JSON text, `spec_strip_annotations_text` | `free` |
| `SomStrList` (assigned ids, block lines) | `som_strlist_free` |
| `stripped()` document | `spec_document_free` + `free` |
| `SpecReviewAnnotationError` | `spec_review_annotation_error_free` |
| `spec_review_annotations_validate` errors | `spec_validation_errors_free` |

## Best Practices

- Call `assign_comment_ids` when a reviewed document comes back, so every
  comment can be cited and logged by id.
- Pass the comment log's highest number as `floor`, so a number freed by a
  resolved comment is not handed out again.
- Never write `stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
