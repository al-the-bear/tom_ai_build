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
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options`, `recommendation`, `assumption`, `starred`; `from_json` reads the corpus form |
| `SpecReviewAnnotationCounts` | `questions`, `open_questions`, `answered_questions`, `comments`, `marks`; `to_json()` |
| `SpecReviewAnnotationError` | An operation named something that is not there |
| `strip_annotations_text` | One value without its annotations |
| `format_comment_block` / `format_question_block` | The lines of a block, as the insert operations write them |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question of a combined block carries `combined=True` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `next_comment_id(floor=0)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assign_comment_ids(floor=0)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
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
| `accept_all_marks(path=None)`, `reject_all_marks(path=None)` | Every mark under a path, or in the whole document |
| `remove_all_annotations()` | Every mark accepted and every comment and question block removed, written back |
| `apply_inline_marks_text(text, accept)` | One value with every mark accepted or rejected |

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

## Validation

`validate_document` reports annotation findings as its last group, ordered by
path:

| Code | When |
|------|------|
| `SpecValidationCode.ANNOTATION_MISPLACED` (`annotationMisplaced`) | A comment or question block inside a form field's value |
| `SpecValidationCode.ANNOTATION_MALFORMED` (`annotationMalformed`) | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer inside a comment block |
| `SpecValidationCode.DUPLICATE_ANNOTATION_ID` (`duplicateAnnotationId`) | A comment or question id used twice in one document |

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
