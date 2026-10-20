# Review annotations — `tom_som_java_runtime`

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
- [Extracting answers for a step folder](#extracting-answers-for-a-step-folder)
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

```java
import java.util.Map;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecQuestionDraft;
import tom_som_runtime.SpecReviewAnnotations;

public class QuickStart {
  public static void main(String[] args) {
    SpecDocument doc = new SpecDocument();
    doc.loadJson(Map.of("content", Map.of("DEMO/SUM",
        "Sessions expire after 30 minutes.\n\n> ⬆️ (Alexis): Too long for kiosks.")));
    SpecReviewAnnotations review = new SpecReviewAnnotations(doc, "DEMO");
    System.out.println(review.assignCommentIds());
    System.out.println(review.list().get(0).qualifiedId);
    review.insertQuestionAfterComment(
        "C-1", new SpecQuestionDraft("BQ-1", "C-1 kiosks", "Kiosks only?"));
    review.setAnswer("BQ-1", "yes");
    System.out.println(review.counts().toJson());
  }
}
```

Output:

```text
[C-1]
DEMO C-1
{questions=1, openQuestions=0, answeredQuestions=1, comments=1, marks=0}
```

## Core Components

All are public classes of the `tom_som_runtime` package.

| Type | Role |
|------|------|
| `SpecReviewAnnotations` | The operations, over one `SpecDocument`; `qualifier` (constructor argument, may be null) is the document id written in front of a comment id cited outside it (`SBP C-12`) |
| `SpecReviewAnnotation` | One listed annotation, as public final fields: `kind`, `path`, `field`, `line`, `id`, `qualifiedId`, `author`, `text`, `context`, `topic`, `starred`, `combined`, `answer`, `markKind`, `newText`, `comment`; `open()`. `toJson()` is the form the conformance corpus pins |
| `SpecReviewAnnotationKind` | `COMMENT`, `QUESTION`, `MARK` (`value`: `comment`, `question`, `mark`) |
| `SpecMarkKind` | `COMMENT`, `HIGHLIGHT`, `INSERTION`, `DELETION`, `SUBSTITUTION` (`value` in lower case) |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options`, `recommendation`, `assumption`, `starred`; `fromJson` reads the corpus form |
| `SpecReviewAnnotationCounts` | `questions`, `openQuestions`, `answeredQuestions`, `comments`, `marks`; `toJson()` |
| `SpecReviewAnnotationError` | An operation named something that is not there (unchecked) |
| `SpecReviewAnnotations.stripAnnotationsText` | One value without its annotations (static) |
| `SpecReviewAnnotations.formatCommentBlock` / `formatQuestionBlock` | The lines of a block, as the insert operations write them (static) |

## Operations

A `field` argument is null for a content value.

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question of a combined block carries `combined == true` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `nextCommentId()` / `nextCommentId(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assignCommentIds()` / `assignCommentIds(floor)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `insertComment(path, field, afterParagraph, text, author, id)` | A comment block after paragraph `afterParagraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless given; `author` and `id` may be null) |
| `insertQuestion(path, field, afterParagraph, question)` | A question block after a paragraph |
| `insertQuestionAfterComment(commentId, question)` | A question block directly after a comment block |
| `setAnswer(questionId, answer)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `editComment(commentId, text)` | New text; the marker, id and author stay as written |
| `resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `applyMark(path, field, index, accept)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

Record each applied comment or answer in the project's log **before**
`resolve` removes it (`tom_specs_project_flow.md` PF-ITR-REV).

## Reviewing inline marks

A `path` argument may be null for the whole document; each operation also has
an overload without it.

| Operation | Does |
|-----------|------|
| `revision()` | The revision the mark ids are stable for (16 hex digits); any change to a value changes it |
| `listMarks(path)` | Every inline mark of the document or of a subtree: `M-<n>` id, kind, path, old and new text, markup, the paragraph holding it |
| `decideMarks(decisions, revision)` | One write: `{id → SpecMarkDecision.ACCEPT / REJECT / LEAVE}`. Refused when the document is no longer at `revision`, or when an id is unknown |
| `acceptAllMarks(path)`, `rejectAllMarks(path)` | Every mark under a path, or in the whole document |
| `removeAllAnnotations()` | Every mark accepted and every comment and question block removed, written back |
| `SpecReviewAnnotations.applyInlineMarksText(text, accept)` | One value with every mark accepted or rejected |

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

```java
SpecReviewAnnotations review = new SpecReviewAnnotations(doc);
String rev = review.revision();
List<SpecMarkEntry> marks = review.listMarks();
SpecMarkReport report =
    review.decideMarks(Map.of(marks.get(0).id, SpecMarkDecision.ACCEPT), rev);
```

### Writing changes as marks

| Operation | Does |
|-----------|------|
| `SpecReviewAnnotations.markChangeText(old, new)` (static) | `new` with every difference from `old` marked. Accepting all marks gives `new`, rejecting all gives `old`. Returns a `SpecMarkedChange` (`text`, `exact`) |
| `setMarked(path, field, text)` | Writes `text` as a marked change against the value there (`field` null for content). A value that already holds marks is compared from its original, so a second edit updates its mark |
| `markAgainst(path, field, earlier)` | Marks the value already written against an earlier version |

`exact` is false only when a difference could not be marked, i.e. a change
inside fenced code. The new text is then written unmarked.

```java
SpecMarkedChange r =
    SpecReviewAnnotations.markChangeText(
        "Sessions expire after 30 minutes.", "Sessions expire after 15 minutes.");
System.out.println(r.text); // Sessions expire after {~~ 30 ~> 15 ~~} minutes.
```

## Extracting answers for a step folder

A step of the TomSpecs process opens by collecting the reviewer's answers and
comments into its step folder's `answers.md`. The annotations stay in the
document, and the extraction never writes.

| Operation | Does |
|-----------|------|
| `SpecAnswers.extractAnswers(model, doc, label, path)` | A `SpecAnswerExtract`: every question (answered or open), comment and inline mark of the document or of a subtree (`path` may be null, or left out), with its section-id chain and its line in the document's Markdown rendition, in rendition order |
| `SpecAnswers.renderAnswers(extracts, options)` | The `answers.md` text. Deterministic: the documents in the order given, then their entries. `SpecAnswerRenderOptions(includeOpen, includeMarks, title)` adds the open questions and the inline marks, and sets the title |
| `SpecAnswerExtract.counts()` | A `SpecAnswerCounts`: answered, open, comments, marks — what a step's closing item reports |

Each entry is a `SpecAnswerEntry` whose `kind` is a `SpecAnswerKind`
(`ANSWERED`, `OPEN`, `COMMENT`, `MARK`). A comment is cited with the document
root's id in front (`SBP C-12`). A comment without an id is listed by its
line; `assignCommentIds` gives it one, when asked.

```java
SpecAnswerExtract x = SpecAnswers.extractAnswers(model, doc, "tom_uam.sbp");
Files.writeString(
    Path.of("answers.md"),
    SpecAnswers.renderAnswers(List.of(x), new SpecAnswerRenderOptions(true, false, "Answers")));
System.out.println(x.counts().toJson()); // {answered=75, open=269, comments=0, marks=0}
```

## Validation

`SpecValidator.validateDocument` reports annotation findings as its last group,
ordered by path:

| Code | When |
|------|------|
| `SpecValidationCode.ANNOTATION_MISPLACED` (`annotationMisplaced`) | A comment or question block inside a form field's value |
| `SpecValidationCode.ANNOTATION_MALFORMED` (`annotationMalformed`) | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer inside a comment block |
| `SpecValidationCode.DUPLICATE_ANNOTATION_ID` (`duplicateAnnotationId`) | A comment or question id used twice in one document |

They are findings, never parse rejections: the document still loads.
`new SpecReviewAnnotations(doc).validate()` returns the same group on its own.

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
