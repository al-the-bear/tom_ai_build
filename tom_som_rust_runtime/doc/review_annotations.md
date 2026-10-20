# Review annotations — `tom_som_rust_runtime`

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
within the value; this port works in UTF-8 byte offsets internally and never
exports them.

## Quick Start

```rust
use tom_som_rust_runtime::{SpecDocument, SpecQuestionDraft, SpecReviewAnnotations};

fn main() {
    let mut doc = SpecDocument::new();
    doc.set_content(
        "DEMO/SUM",
        "Sessions expire after 30 minutes.\n\n> ⬆️ (Alexis): Too long for kiosks.",
    );
    let mut review = SpecReviewAnnotations::with_qualifier(&mut doc, Some("DEMO"));
    println!("{:?}", review.assign_comment_ids(0));
    println!("{}", review.list()[0].qualified_id.as_deref().unwrap_or(""));
    review
        .insert_question_after_comment(
            "C-1",
            &SpecQuestionDraft::new("BQ-1", "C-1 kiosks", "Kiosks only?"),
        )
        .unwrap();
    review.set_answer("BQ-1", "yes").unwrap();
    println!("{:?}", review.counts());
}
```

Output:

```text
["C-1"]
DEMO C-1
SpecReviewAnnotationCounts { questions: 1, open_questions: 0, answered_questions: 1, comments: 1, marks: 0 }
```

`tests/review_annotations.rs` runs this example and asserts the output.

## Core Components

All are re-exported at the crate root.

| Type | Role |
|------|------|
| `SpecReviewAnnotations<'a>` | The operations, over one `&mut SpecDocument`. `new(doc)` lists bare ids; `with_qualifier(doc, Some("SBP"))` writes the document id in front of a comment id cited outside it (`SBP C-12`) |
| `SpecReviewAnnotation` | One listed annotation: `kind`, `path`, `field`, `line`, `id`, `qualified_id`, `author`, `text`, `context`, `topic`, `starred`, `combined`, `answer`, `mark_kind`, `new_text`, `comment`; `is_open()`. `to_json()` is the form the conformance corpus pins |
| `SpecReviewAnnotationKind` | `Comment`, `Question`, `Mark` (`name()` gives the wire name) |
| `SpecMarkKind` | `Comment`, `Highlight`, `Insertion`, `Deletion`, `Substitution` |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options`, `recommendation`, `assumption`, `starred`; `SpecQuestionDraft::new(id, topic, text)` fills the rest empty |
| `SpecReviewAnnotationCounts` | `questions`, `open_questions`, `answered_questions`, `comments`, `marks` |
| `SpecReviewAnnotationError` | An operation named something that is not there |
| `strip_annotations_text` | One value without its annotations |
| `format_comment_block` / `format_question_block` | The lines an insert writes |
| `validate_review_annotations` | The validation findings of a `&SpecDocument`, without a mutable borrow |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question of a combined block carries `combined: true` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `next_comment_id(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assign_comment_ids(floor)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `insert_comment(path, field, after_paragraph, text, author, id)` | A comment block after paragraph `after_paragraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless given) |
| `insert_question(path, field, after_paragraph, &question)` | A question block after a paragraph |
| `insert_question_after_comment(comment_id, &question)` | A question block directly after a comment block |
| `set_answer(question_id, answer)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `edit_comment(comment_id, text)` | New text; the marker, id and author stay as written |
| `resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `apply_mark(path, field, index, accept)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

`field` is `None` for a content value and `Some("owner")` for a form field.

Record each applied comment or answer in the project's log **before**
`resolve` removes it (`tom_specs_project_flow.md` PF-ITR-REV).

## Validation

`validate_document` reports annotation findings as its last group, ordered by
path:

| Code | Constant | When |
|------|----------|------|
| `annotationMisplaced` | `SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED` | A comment or question block inside a form field's value |
| `annotationMalformed` | `SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED` | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer inside a comment block |
| `duplicateAnnotationId` | `SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID` | A comment or question id used twice in one document |

They are findings, never parse rejections: the document still loads.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there returns `Err(SpecReviewAnnotationError)` and changes nothing. `list`,
`counts`, `next_comment_id`, `assign_comment_ids` and `stripped` cannot fail
and return their values directly.

## Best Practices

- Call `assign_comment_ids` when a reviewed document comes back, so every
  comment can be cited and logged by id.
- Pass the comment log's highest number as `floor`, so a number freed by a
  resolved comment is not handed out again.
- Never write `stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
