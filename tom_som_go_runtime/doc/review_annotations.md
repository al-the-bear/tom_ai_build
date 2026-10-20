# Review annotations — `tom_som_go_runtime`

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
within the value. In Go a `field` argument of `""` means the content value at
the path.

## Quick Start

```go
package main

import (
	"fmt"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func main() {
	doc := som.NewSpecDocument()
	doc.LoadJSON(&som.DocumentJson{Content: map[string]string{
		"DEMO/SUM": "Sessions expire after 30 minutes.\n\n" +
			"> ⬆️ (Alexis): Too long for kiosks.",
	}})
	review := som.NewSpecReviewAnnotations(doc, "DEMO")
	fmt.Println(review.AssignCommentIDs(0))
	fmt.Println(*review.List()[0].QualifiedID)
	if err := review.InsertQuestionAfterComment("C-1", som.SpecQuestionDraft{
		ID: "BQ-1", Topic: "C-1 kiosks", Text: "Kiosks only?",
	}); err != nil {
		panic(err)
	}
	if err := review.SetAnswer("BQ-1", "yes"); err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", review.Counts())
}
```

Output:

```text
[C-1]
DEMO C-1
{Questions:1 OpenQuestions:0 AnsweredQuestions:1 Comments:1 Marks:0}
```

The same program runs as `ExampleSpecReviewAnnotations` in
`tests/review_annotations_example_test.go`, so this output is checked.

## Core Components

| Type | Role |
|------|------|
| `SpecReviewAnnotations` | The operations, over one `*SpecDocument`; `NewSpecReviewAnnotations(doc, qualifier)` — `qualifier` is the document id written in front of a comment id cited outside it (`SBP C-12`), `""` for bare ids |
| `SpecReviewAnnotation` | One listed annotation: `Kind`, `Path`, `Field`, `Line`, `ID`, `QualifiedID`, `Author`, `Text`, `Context`, `Topic`, `Starred`, `Combined`, `Answer`, `MarkKind`, `NewText`, `Comment`; a nil pointer is absent. `Open()` reports an unanswered question; `ToJSON()` is the form the conformance corpus pins |
| `SpecReviewAnnotationKind` | `SpecReviewAnnotationKindComment`, `…Question`, `…Mark` (all in `SpecReviewAnnotationKinds`) |
| `SpecMarkKind` | `SpecMarkKindComment`, `…Highlight`, `…Insertion`, `…Deletion`, `…Substitution` (all in `SpecMarkKinds`) |
| `SpecQuestionDraft` | A question to insert: `ID`, `Topic`, `Text`, `Options`, `Recommendation`, `Assumption`, `Starred` |
| `SpecReviewAnnotationCounts` | `Questions`, `OpenQuestions`, `AnsweredQuestions`, `Comments`, `Marks` |
| `*SpecReviewAnnotationError` | An operation named something that is not there |
| `StripAnnotationsText` | One value without its annotations |
| `FormatCommentBlock` / `FormatQuestionBlock` | The lines of a block as the operations write it |

## Operations

| Operation | Does |
|-----------|------|
| `List()` | Every annotation, in document order. A question of a combined block carries `Combined: true` and the field it asks about as its topic; a comment carries the paragraph before it as `Context` |
| `Counts()` | The counts a report needs |
| `NextCommentID(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `AssignCommentIDs(floor)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `InsertComment(path, field, afterParagraph, text, author, id)` | A comment block after paragraph `afterParagraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one when `id` is `""`) |
| `InsertQuestion(path, field, afterParagraph, question)` | A question block after a paragraph |
| `InsertQuestionAfterComment(commentID, question)` | A question block directly after a comment block |
| `SetAnswer(questionID, answer)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `EditComment(commentID, text)` | New text; the marker, id and author stay as written |
| `Resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `ApplyMark(path, field, index, accept)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `Stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

Record each applied comment or answer in the project's log **before**
`Resolve` removes it (`tom_specs_project_flow.md` PF-ITR-REV).

## Validation

`ValidateDocument` reports annotation findings as its last group, ordered by
path (`SpecReviewAnnotations.Validate()` returns that group alone):

| Code | When |
|------|------|
| `SpecValidationCodeAnnotationMisplaced` (`annotationMisplaced`) | A comment or question block inside a form field's value |
| `SpecValidationCodeAnnotationMalformed` (`annotationMalformed`) | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer inside a comment block |
| `SpecValidationCodeDuplicateAnnotationID` (`duplicateAnnotationId`) | A comment or question id used twice in one document |

They are findings, never parse rejections: the document still loads.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there returns a `*SpecReviewAnnotationError` and changes nothing; test for
it with `errors.As`. `List`, `Counts`, `NextCommentID`, `AssignCommentIDs` and
`Stripped` return no error.

## Best Practices

- Call `AssignCommentIDs` when a reviewed document comes back, so every comment
  can be cited and logged by id.
- Pass the comment log's highest number as `floor`, so a number freed by a
  resolved comment is not handed out again.
- Never write `Stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
