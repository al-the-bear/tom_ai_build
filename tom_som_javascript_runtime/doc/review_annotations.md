# Review annotations — `tom_som_javascript_runtime`

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

```js
const {
  SpecDocument,
  SpecQuestionDraft,
  SpecReviewAnnotations,
} = require('tom_som_javascript_runtime');

const doc = new SpecDocument();
doc.loadJson({
  content: {
    'DEMO/SUM': 'Sessions expire after 30 minutes.\n\n' +
      '> ⬆️ (Alexis): Too long for kiosks.',
  },
});
const review = new SpecReviewAnnotations(doc, { qualifier: 'DEMO' });
console.log(review.assignCommentIds());
console.log(review.list()[0].qualifiedId);
review.insertQuestionAfterComment(
  'C-1',
  new SpecQuestionDraft({ id: 'BQ-1', topic: 'C-1 kiosks', text: 'Kiosks only?' }),
);
review.setAnswer('BQ-1', 'yes');
console.log(JSON.stringify(review.counts().toJson()));
```

Output:

```text
[ 'C-1' ]
DEMO C-1
{"questions":1,"openQuestions":0,"answeredQuestions":1,"comments":1,"marks":0}
```

## Core Components

| Export | Role |
|--------|------|
| `SpecReviewAnnotations` | The operations, over one `SpecDocument`; `new SpecReviewAnnotations(doc, { qualifier })`, where `qualifier` is the document id written in front of a comment id cited outside it (`SBP C-12`) |
| `SpecReviewAnnotation` | One listed annotation: `kind`, `path`, `field`, `line`, `id`, `qualifiedId`, `author`, `text`, `context`, `topic`, `starred`, `combined`, `answer`, `open`, `markKind`, `newText`, `comment`. `toJson()` is the form the conformance corpus pins |
| `SpecReviewAnnotationKind` | `COMMENT`, `QUESTION`, `MARK` (values `'comment'`, `'question'`, `'mark'`) |
| `SpecMarkKind` | `COMMENT`, `HIGHLIGHT`, `INSERTION`, `DELETION`, `SUBSTITUTION` (values in lower camel case) |
| `SpecQuestionDraft` | A question to insert: `new SpecQuestionDraft({ id, topic, text, options, recommendation, assumption, starred })`; `SpecQuestionDraft.fromJson(j)` reads the corpus form |
| `SpecReviewAnnotationCounts` | `questions`, `openQuestions`, `answeredQuestions`, `comments`, `marks` |
| `SpecReviewAnnotationError` | An operation named something that is not there (an `Error` subclass) |
| `stripAnnotationsText(value)` | One value without its annotations |
| `formatCommentBlock({ id, text, author })`, `formatQuestionBlock(draft)` | The lines a comment or question block is written as |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question of a combined block carries `combined: true` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `nextCommentId({ floor })` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assignCommentIds({ floor })` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `insertComment({ path, field, afterParagraph, text, author, id })` | A comment block after paragraph `afterParagraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless given) |
| `insertQuestion({ path, field, afterParagraph, question })` | A question block after a paragraph |
| `insertQuestionAfterComment(commentId, question)` | A question block directly after a comment block |
| `setAnswer(questionId, answer)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing |
| `editComment(commentId, text)` | New text; the marker, id and author stay as written |
| `resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `applyMark({ path, field, index, accept })` | Accepts or rejects inline mark `index` of one value (`accept` defaults to `true`). Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |
| `validate()` | The annotation findings alone, ordered by path |

`field` is omitted (or `null`) for a content value. Record each applied comment
or answer in the project's log **before** `resolve` removes it
(`tom_specs_project_flow.md` PF-ITR-REV).

## Reviewing inline marks

| Operation | Does |
|-----------|------|
| `revision()` | The revision the mark ids are stable for (16 hex digits); any change to a value changes it |
| `listMarks({ path })` | Every inline mark of the document or of a subtree, as `SpecMarkEntry`: `M-<n>` id, kind, path, old and new text, markup, the paragraph holding it |
| `decideMarks(decisions, { revision })` | One write: `{ id: SpecMarkDecision.ACCEPT / REJECT / LEAVE }` (an object or a `Map`). Refused when the document is no longer at `revision`, or when an id is unknown |
| `acceptAllMarks({ path })`, `rejectAllMarks({ path })` | Every mark under a path, or in the whole document |
| `removeAllAnnotations()` | Every mark accepted and every comment and question block removed, written back |
| `applyInlineMarksText(text, { accept })` | One value with every mark accepted or rejected |

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

```javascript
const review = new SpecReviewAnnotations(doc);
const rev = review.revision();
const marks = review.listMarks();
const report = review.decideMarks(
  { [marks[0].id]: SpecMarkDecision.ACCEPT },
  { revision: rev },
);
```

### Writing changes as marks

| Operation | Does |
|-----------|------|
| `markChangeText(old, new)` | `new` with every difference from `old` marked. Accepting all marks gives `new`, rejecting all gives `old`. Returns a `SpecMarkedChange` (`text`, `exact`) |
| `setMarked({ path, field, text })` | Writes `text` as a marked change against the value there. A value that already holds marks is compared from its original, so a second edit updates its mark |
| `markAgainst({ path, field, earlier })` | Marks the value already written against an earlier version |

`exact` is false only when a difference could not be marked, i.e. a change
inside fenced code. The new text is then written unmarked.

```javascript
const { markChangeText } = require('tom_som_javascript_runtime');

const r = markChangeText(
  'Sessions expire after 30 minutes.',
  'Sessions expire after 15 minutes.',
);
console.log(r.text); // Sessions expire after {~~ 30 ~> 15 ~~} minutes.
```

## Extracting answers for a step folder

A step of the TomSpecs process opens by collecting the reviewer's answers and
comments into its step folder's `answers.md`. The annotations stay in the
document, and the extraction never writes.

| Operation | Does |
|-----------|------|
| `extractAnswers(model, doc, { label, path })` | A `SpecAnswerExtract`: every question (answered or open), comment and inline mark of the document or of a subtree, with its section-id chain and its line in the document's Markdown rendition, in rendition order |
| `renderAnswers(extracts, options)` | The `answers.md` text. Deterministic: the documents in the order given, then their entries. `SpecAnswerRenderOptions` adds the open questions (`includeOpen`) and the inline marks (`includeMarks`), and sets the title |
| `SpecAnswerExtract.counts` | answered, open, comments, marks: what a step's closing item reports |

Each entry is a `SpecAnswerEntry` whose `kind` is a `SpecAnswerKind`
(`ANSWERED`, `OPEN`, `COMMENT`, `MARK`); `toJson()` gives the canonical form
the conformance corpus pins. A comment is cited with the document root's id in
front (`SBP C-12`). A comment without an id is listed by its line;
`assignCommentIds` gives it one, when asked. The command line is
`tom_specs_clitool`'s `extract_answers`.

```javascript
const fs = require('fs');
const {
  SpecAnswerRenderOptions,
  extractAnswers,
  renderAnswers,
} = require('tom_som_javascript_runtime');

const x = extractAnswers(model, doc, { label: 'tom_uam.sbp' });
fs.writeFileSync(
  'answers.md',
  renderAnswers([x], new SpecAnswerRenderOptions({ includeOpen: true })),
);
console.log(x.counts.toJson()); // { answered: 75, open: 269, comments: 0, marks: 0 }
```

## Validation

`validateDocument` reports annotation findings as its last group, after the
derived-value group, ordered by path (`SpecValidationCode.ANNOTATION_MISPLACED`,
`ANNOTATION_MALFORMED`, `DUPLICATE_ANNOTATION_ID`):

| Code | When |
|------|------|
| `annotationMisplaced` | A comment or question block inside a form field's value |
| `annotationMalformed` | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer inside a comment block |
| `duplicateAnnotationId` | A comment or question id used twice in one document |

They are findings, never parse rejections: the document still loads.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there throws `SpecReviewAnnotationError` and changes nothing. `list`,
`counts`, `nextCommentId`, `stripped` and `validate` never throw.

## Best Practices

- Call `assignCommentIds()` when a reviewed document comes back, so every comment
  can be cited and logged by id.
- Pass the comment log's highest number as `{ floor }`, so a number freed by a
  resolved comment is not handed out again.
- Never write `stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
