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
- [Reviewing inline marks](#reviewing-inline-marks)
- [Extracting answers for a step folder](#extracting-answers-for-a-step-folder)
- [Team reviews](#team-reviews)
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
| `SpecReviewAnnotationKind` | `Comment`, `Question`, `Mark`, and `Conflict` for a team review's conflict block (`specReviewAnnotationKindName`) |
| `SpecMarkKind` | `Comment`, `Highlight`, `Insertion`, `Deletion`, `Substitution` (`specMarkKindName`) |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options`, `recommendation`, `assumption`, `starred`, and `recommended`, the letter whose option is written bold |
| `SpecQuestionOption` | One option of a question: `letter`, `text` (continuation lines joined), `bold` |
| `SpecReviewAnnotationCounts` | `questions`, `openQuestions`, `answeredQuestions`, `comments`, `marks`; `toJson()` |
| `SpecReviewAnnotationError` | An operation named something that is not there (a `std::exception`) |
| `stripAnnotationsText` | One value without its annotations |
| `formatCommentBlock`, `formatQuestionBlock` | The lines a comment or question block is written as |
| `validateReviewAnnotations` | The annotation findings of a `const SpecDocument&` |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question carries its `options`, its `recommended` letter (the bold option, else the option that says "recommended", else the letter of a `*Recommendation:*` line) and its `answerLetter()` (`(b)` or `**(b)**` at the start of the answer). A question of a combined block carries `combined` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `nextCommentId(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assignCommentIds(floor)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `paragraphs(path, field)` | The value's paragraphs as `SpecParagraph`, each with its `index` (what `afterParagraph` takes), `startLine` / `endLine` within the value, its `text` and `annotation` (`comment` / `question` for an annotation block). The rule is SOM §11.9.1 "Paragraphs": blank-line separated, a blank line inside fenced code does not end one. A value the document does not hold throws `SpecReviewAnnotationError` |
| `insertComment(path, field, afterParagraph, text, author, id)` | A comment block after paragraph `afterParagraph` (0-based; -1 is the start), one blank line on each side; returns its id (the next free one unless `id` is given) |
| `insertQuestion(path, field, afterParagraph, question)` | A question block after a paragraph |
| `insertQuestionAfterComment(commentId, question)` | A question block directly after a comment block |
| `setAnswer(questionId, answer, author)` | Writes the answer after `**Answer:**`; an empty answer reopens the question; adds the line when it is missing. With `author`, writes that member's individual answer instead ([Team reviews](#team-reviews)) |
| `editComment(commentId, text)` | New text; the marker, id and author stay as written |
| `resolve(id)` | Removes one comment or question (a qualified comment id is accepted) and one adjacent blank line. A question of a combined block takes only its own lines; the block goes with its last question |
| `applyMark(path, field, index, accept)` | Accepts or rejects inline mark `index` of one value. Accept takes the insertion, the deletion or the new text; reject keeps the old. A highlight or comment mark is removed either way, its text staying |
| `stripped()` | A copy of the document without any annotation, every mark accepted, for reading. The document is unchanged |

`field` is `std::nullopt` for a content value. Record each applied comment or
answer in the project's log **before** `resolve` removes it
(`tom_specs_project_flow.md` PF-ITR-REV).

## Reviewing inline marks

| Operation | Does |
|-----------|------|
| `revision()` | The revision the mark ids are stable for (16 hex digits); any change to a value changes it |
| `listMarks(path)` | Every inline mark of the document (`path` omitted) or of a subtree, as `SpecMarkEntry`: `M-<n>` id, `markKind`, `path`, `field`, `oldText` and `newText`, `markup`, the paragraph holding it as `context` |
| `decideMarks(decisions, revision)` | One write: a `std::map<std::string, SpecMarkDecision>` `{id → Accept / Reject / Leave}`. Throws `SpecReviewAnnotationError` (nothing changes) when the document is no longer at `revision`, or when an id is unknown |
| `acceptAllMarks(path)`, `rejectAllMarks(path)` | Every mark under a path, or in the whole document |
| `removeAllAnnotations()` | Every mark accepted, every conflict's decision applied, and every comment, question and conflict block removed, written back ([Team reviews](#team-reviews)) |
| `som::applyInlineMarksText(text, accept)` | One value with every mark accepted or rejected |

Each returns a `SpecMarkReport`. `applied` holds one `SpecMarkOutcome` per
mark: id, kind, path, decision, markup and result. `malformed` holds the
`SpecMarkIssue`s in scope (`unclosed`, `nested`, `noArrow`); those marks are
left as written. Every type has a `toJson()`.

| Mark | Accept | Reject |
|------|--------|--------|
| `{++ added ++}` | `added` | nothing |
| `{-- removed --}` | nothing | `removed` |
| `{~~ old ~> new ~~}` | `new` | `old` |
| `{== text ==}{>> c <<}`, `{== text ==}` | `text` | `text` |
| `{>> c <<}` | nothing | nothing |

The whitespace rules (words never join, no double space and no space before
punctuation, a whole-line mark leaves no blank line) are SOM §11.9.3.

```cpp
som::SpecReviewAnnotations review(doc);
const std::string rev = review.revision();
const auto marks = review.listMarks();
const som::SpecMarkReport report = review.decideMarks(
    {{marks.front().id, som::SpecMarkDecision::Accept}}, rev);
```

### Writing changes as marks

| Operation | Does |
|-----------|------|
| `som::markChangeText(old, new)` | `new` with every difference from `old` marked. Accepting all marks gives `new`, rejecting all gives `old`. Returns a `SpecMarkedChange` (`text`, `exact`) |
| `setMarked(path, field, text)` | Writes `text` as a marked change against the value there. A value that already holds marks is compared from its original, so a second edit updates its mark |
| `markAgainst(path, field, earlier)` | Marks the value already written against an earlier version |

`exact` is false only when a difference could not be marked, i.e. a change
inside fenced code. The new text is then written unmarked.

```cpp
const som::SpecMarkedChange r = som::markChangeText(
    "Sessions expire after 30 minutes.", "Sessions expire after 15 minutes.");
std::cout << r.text << "\n";  // Sessions expire after {~~ 30 ~> 15 ~~} minutes.
```

## Extracting answers for a step folder

A step of the TomSpecs process opens by collecting the reviewer's answers and
comments into its step folder's `answers.md`. The annotations stay in the
document, and the extraction never writes. The API is declared in
`include/spec_answers.hpp`.

| Operation | Does |
|-----------|------|
| `som::extractAnswers(model, doc, label, path)` | A `SpecAnswerExtract`: every question (answered or open), comment and inline mark of the document or of a subtree (`path`, default `std::nullopt`), with its section-id chain and its line in the document's Markdown rendition, in rendition order. Throws as `markdownExportRootWithMap` does |
| `som::renderAnswers(extracts, options)` | The `answers.md` text. Deterministic: the documents in the order given, then their entries. `SpecAnswerRenderOptions` adds the open questions (`includeOpen`) and the inline marks (`includeMarks`), and sets the `title` |
| `SpecAnswerExtract::counts()` | answered, open, comments, marks: what a step's closing item reports |

An entry (`SpecAnswerEntry`) has a `kind` (`SpecAnswerKind::Answered`, `Open`,
`Comment`, `Mark`). A comment is cited with the document root's id in front
(`SBP C-12`). A comment without an id is listed by its line;
`assignCommentIds` gives it one, when asked. The command line is
`tom_specs_clitool`'s `extract_answers`.

```cpp
som::SpecAnswerExtract x = som::extractAnswers(model, doc, "tom_uam.sbp");
som::SpecAnswerRenderOptions options;
options.includeOpen = true;
std::ofstream("answers.md") << som::renderAnswers({x}, options);
std::cout << x.counts().toJson() << "\n";
// {"answered":75,"open":269,"comments":0,"marks":0}
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
| Attribution token | Part of its mark: in the `markup`, removed with the mark by every decision. `SpecReviewAnnotation` and `SpecMarkEntry` carry `authors` (member ids) and `votes` (`SpecMarkVote`: `member`, `accept`), both empty without a token |
| Individual answers | `SpecReviewAnnotation::answers`: `SpecIndividualAnswer` (`members`, `answer`, `answerLetter()`), in the order written. The question's `text` ends before the first of them; `answer` stays the team's |
| Conflict block | Kind `SpecReviewAnnotationKind::Conflict` (`"conflict"`): `id`, `qualifiedId`, `topic`, `text`, `base`, `alternatives` (`SpecConflictAlternative`: `letter`, `members`, `text`), the decision as `answer` (`decision` in JSON), `decisionLetter()` (`a`…, `base` or nullopt), `open()`, `unresolved()`. `paragraphs()` marks the block `conflict` |
| `open:` | `unresolved()` true and `open()` false on the question or conflict; a question's `answerLetter()` is then nullopt |

`counts()` adds `unresolvedQuestions` (also counted as answered), `conflicts`
and `openConflicts`. The `toJson(bool team = false)` of the listing types,
`SpecReviewAnnotationCounts` and `SpecMarkReport` gives with `team` the members
`team_annotation_cases.json` pins; without it they are the forms of the older
case files.

**Writing.** `setAnswer(questionId, answer, author)` writes that member's
individual answer instead of the team's, grouped by SOM §11.9.8: a plain
letter answer joins the line with the same answer, a commented one gets its own
line, an empty one only takes the member out. An author that is not a member id
(`som::isReviewMemberId`) throws `SpecReviewAnnotationError`.
`removeAllAnnotations()` applies every conflict's decision and lists it in the
report's `conflicts` (`SpecConflictOutcome`: `id`, `path`, `field`, `line`,
`decision`, `result`); it throws `SpecReviewAnnotationError`, changing nothing,
while a conflict is open, unresolved or malformed. A structural conflict
(`Item removed`, `Item moved`, `Headline changed`) only loses its block: its
decision is the caller's to apply. `stripped()` keeps a conflict's base text and
drops the block. `som::formatConflictBlock(id, topic, text, base,
alternatives)` gives the lines of a block.

**Merging.** `som::mergeReviews` (`spec_review_merge.hpp`) merges the returned
copies into a new document and returns a `SpecReviewMergeResult<D>` (`merged`,
`report`); neither the base nor a copy is changed.

| Overload | Merges |
|----------|--------|
| `mergeReviews(model, base, copies, options)` | A `SpecDocument` by the paths of `model`, list items matched by section id; `copies` are `SpecReviewedDocument`s (`member`, `document`) |
| `mergeReviews(base, copies, options)` | A Markdown string by heading path; `copies` are `SpecReviewedMarkdown`s (`member`, `document`) |

`copies` are in round order, each `member` a `SpecReviewMember` (`memberId`,
`displayName`, `role`). `SpecReviewMergeOptions` holds `team` (the members the
round started with), `date` (ISO 8601: the revision entry's date and every
generated list-item id's), `author` and `questionPrefix` (default `RQ`).

A copy whose structure does not fit the base (a path the model does not
resolve; other headings in Markdown) throws `SpecReviewMergeError` and nothing
is merged. The report, `SpecReviewMergeReport`, lists in merged document
order `reviewers` (with `guest`), `conflicts` (`id`, `path`, `field`,
`paragraph`, `members`), `votes`, `unanimous`, `answers`, `comments`,
`additions`, `guestQuestions` and the `revision` entry (nullopt without a
revision history); `toJson()` is the form `review_merge_cases.json` pins.

```cpp
#include "tom_som_cpp_runtime.hpp"

auto doc = [](const std::string& text) {
  som::SpecDocument d;
  d.setContent("DEMO/SUM", text);
  return d;
};
const std::vector<som::SpecReviewMember> team{
    {"alice", "Alice Owner", "Product owner"},
    {"bob", "Bob Dev", "Developer"},
};
som::SpecReviewMergeOptions options;
options.team = team;
options.date = "2026-11-05";
options.author = "Alice Owner";
const auto result = som::mergeReviews(
    model, doc("Sessions expire after 30 minutes."),
    {{team[0], doc("Sessions expire after 15 minutes.")},
     {team[1], doc("Sessions expire after 15 minutes.")}},
    options);
std::cout << result.merged.content("DEMO/SUM") << "\n";
std::cout << result.report.conflicts.size() << "\n";
```

Output:

```text
Sessions expire after {~~ 30 ~> 15 ~~}{@alice,bob} minutes.
0
```

A unit whose copy no longer holds more than 16 of the base's marks as written
is read as an edit (step 4 of SOM §11.9.9): the decision combinations would
grow past 65536.

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
