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
- [Extracting answers for a step folder](#extracting-answers-for-a-step-folder)
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
| `SpecReviewAnnotationKind` | `SPEC_REVIEW_ANNOTATION_COMMENT`, `_QUESTION`, `_MARK` (`spec_review_annotation_kind_name`) |
| `SpecMarkKind` | `SPEC_MARK_COMMENT`, `_HIGHLIGHT`, `_INSERTION`, `_DELETION`, `_SUBSTITUTION` (`spec_mark_kind_name`) |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options` / `options_len`, `recommendation`, `assumption`, `starred` (all borrowed) |
| `SpecReviewAnnotationCounts` | `questions`, `open_questions`, `answered_questions`, `comments`, `marks` |
| `SpecReviewAnnotationError` | An operation named something that is not there |
| `spec_strip_annotations_text` | One value without its annotations |
| `spec_format_comment_block`, `spec_format_question_block` | The lines a comment or question block is written as |

## Operations

Every operation is `spec_review_annotations_<name>(&review, …)`.

| Operation | Does |
|-----------|------|
| `list(out)` | Every annotation, in document order. A question of a combined block carries `combined` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `next_comment_id(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assign_comment_ids(floor, out)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `insert_comment(path, field, after_paragraph, text, author, id, err)` | A comment block after paragraph `after_paragraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless `id` is given) |
| `insert_question(path, field, after_paragraph, question, err)` | A question block after a paragraph |
| `insert_question_after_comment(comment_id, question, err)` | A question block directly after a comment block |
| `set_answer(question_id, answer, err)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `edit_comment(comment_id, text, err)` | New text; the marker, id and author stay as written |
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
| `accept_all_marks(path, out)`, `reject_all_marks(path, out)` | Every mark under a path, or in the whole document (`NULL`) |
| `remove_all_annotations(out)` | Every mark accepted and every comment and question block removed, written back |
| `spec_apply_inline_marks_text(text, accept)` | One value with every mark accepted or rejected (owned) |

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

The whitespace rules (words never join, no double space and no space before
punctuation, a whole-line mark leaves no blank line) are SOM §11.9.3.

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
| `spec_review_annotations_set_marked(&review, path, field, text)` | Writes `text` as a marked change against the value there. A value that already holds marks is compared from its original, so a second edit updates its mark |
| `spec_review_annotations_mark_against(&review, path, field, earlier)` | Marks the value already written against an earlier version |

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

`SpecReviewAnnotations` borrows its document and qualifier and owns nothing.
Everything an operation returns is the caller's:

| Returned | Release with |
|----------|--------------|
| `SpecReviewAnnotationList` | `spec_review_annotation_list_free` |
| `SpecMarkEntryList` | `spec_mark_entry_list_free` |
| `SpecMarkReport` | `spec_mark_report_free` |
| `SpecAnswerExtract` | `spec_answer_extract_free` |
| `spec_render_answers`, `spec_answer_*_to_json` | `free` |
| revision, `spec_apply_inline_marks_text` | `free` |
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
