# Review annotations — `tom_som_cpp_runtime`

Reviewers comment on a TomSpecs document inside its text, the agent asks its
questions there, and suggestions are written as inline marks.
`som::SpecReviewAnnotations` reads those annotations out of a document's
content and form-field values and edits them in place. Every edit leaves the
rest of the value byte for byte as it was.

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
tier); this guide covers only the API, declared in
`include/spec_review_annotations.hpp` and included by `tom_som_cpp_runtime.hpp`.
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

```cpp
#include <iostream>

#include "tom_som_cpp_runtime.hpp"

int main() {
  som::SpecDocument doc;
  doc.setContent("DEMO/SUM",
                 "Sessions expire after 30 minutes.\n\n"
                 "> ⬆️ (Alexis): Too long for kiosks.");
  som::SpecReviewAnnotations review(doc, "DEMO");
  std::cout << review.assignCommentIds().front() << "\n";
  std::cout << *review.list().front().qualifiedId << "\n";
  som::SpecQuestionDraft question;
  question.id = "BQ-1";
  question.topic = "C-1 kiosks";
  question.text = "Kiosks only?";
  review.insertQuestionAfterComment("C-1", question);
  review.setAnswer("BQ-1", "yes");
  std::cout << review.counts().toJson() << "\n";
}
```

Output:

```text
C-1
DEMO C-1
{"questions":1,"openQuestions":0,"answeredQuestions":1,"comments":1,"marks":0}
```

## Core Components

All in namespace `som`.

| Type / function | Role |
|-----------------|------|
| `SpecReviewAnnotations` | The operations, over one borrowed `SpecDocument`; `qualifier` is the document id written in front of a comment id cited outside it (`SBP C-12`) |
| `SpecReviewAnnotation` | One listed annotation: `kind`, `path`, `field`, `line`, `id`, `qualifiedId`, `author`, `text`, `context`, `topic`, `starred`, `combined`, `answer`, `markKind`, `newText`, `comment` (`std::nullopt` for the Dart `null`). `toJson()` is the form the conformance corpus pins; `open()` says whether a question is open |
| `SpecReviewAnnotationKind` | `Comment`, `Question`, `Mark` (`specReviewAnnotationKindName`) |
| `SpecMarkKind` | `Comment`, `Highlight`, `Insertion`, `Deletion`, `Substitution` (`specMarkKindName`) |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options`, `recommendation`, `assumption`, `starred` |
| `SpecReviewAnnotationCounts` | `questions`, `openQuestions`, `answeredQuestions`, `comments`, `marks`; `toJson()` |
| `SpecReviewAnnotationError` | An operation named something that is not there (a `std::exception`) |
| `stripAnnotationsText` | One value without its annotations |
| `formatCommentBlock`, `formatQuestionBlock` | The lines a comment or question block is written as |
| `validateReviewAnnotations` | The annotation findings of a `const SpecDocument&` |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question of a combined block carries `combined` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `nextCommentId(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assignCommentIds(floor)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `insertComment(path, field, afterParagraph, text, author, id)` | A comment block after paragraph `afterParagraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless `id` is given) |
| `insertQuestion(path, field, afterParagraph, question)` | A question block after a paragraph |
| `insertQuestionAfterComment(commentId, question)` | A question block directly after a comment block |
| `setAnswer(questionId, answer)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `editComment(commentId, text)` | New text; the marker, id and author stay as written |
| `resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `applyMark(path, field, index, accept)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

`field` is `std::nullopt` for a content value. Record each applied comment or
answer in the project's log **before** `resolve` removes it
(`tom_specs_project_flow.md` PF-ITR-REV).

## Validation

`validateDocument` reports annotation findings as its last group, ordered by
path (`validate()` / `validateReviewAnnotations` give the group alone):

| Code | When |
|------|------|
| `kSpecValidationCodeAnnotationMisplaced` (`annotationMisplaced`) | A comment or question block inside a form field's value |
| `kSpecValidationCodeAnnotationMalformed` (`annotationMalformed`) | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer inside a comment block |
| `kSpecValidationCodeDuplicateAnnotationId` (`duplicateAnnotationId`) | A comment or question id used twice in one document |

They are findings, never parse rejections: the document still loads.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there throws `SpecReviewAnnotationError` and changes nothing. `list`,
`counts`, `nextCommentId` and `stripped` never throw.

## Best Practices

- Call `assignCommentIds` when a reviewed document comes back, so every
  comment can be cited and logged by id.
- Pass the comment log's highest number as `floor`, so a number freed by a
  resolved comment is not handed out again.
- Never write `stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
