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
- [Reviewing inline marks](#reviewing-inline-marks)
- [Comments on changes](#comments-on-changes)
- [Extracting answers for a step folder](#extracting-answers-for-a-step-folder)
- [Team reviews](#team-reviews)
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
SpecReviewAnnotationCounts { questions: 1, open_questions: 0, answered_questions: 1, comments: 1, marks: 0, unresolved_questions: 0, conflicts: 0, open_conflicts: 0 }
```

`tests/review_annotations.rs` runs this example and asserts the output.

## Core Components

All are re-exported at the crate root.

| Type | Role |
|------|------|
| `SpecReviewAnnotations<'a>` | The operations, over one `&mut SpecDocument`. `new(doc)` lists bare ids; `with_qualifier(doc, Some("SBP"))` writes the document id in front of a comment id cited outside it (`SBP C-12`) |
| `SpecReviewAnnotation` | One listed annotation: `kind`, `path`, `field`, `line`, `id`, `qualified_id`, `author`, `text`, `context`, `topic`, `starred`, `combined`, `answer`, `mark_kind`, `new_text`, `comment`; `is_open()`. `to_json()` is the form the conformance corpus pins |
| `SpecReviewAnnotationKind` | `Comment`, `Question`, `Mark`, `Conflict` (`name()` gives the wire name) |
| `SpecMarkKind` | `Comment`, `Highlight`, `Insertion`, `Deletion`, `Substitution` |
| `SpecQuestionDraft` | A question to insert: `id`, `topic`, `text`, `options`, `recommendation`, `assumption`, `starred`, and `recommended`, the letter whose option is written bold; `SpecQuestionDraft::new(id, topic, text)` fills the rest empty |
| `SpecQuestionOption` | One option of a question: `letter`, `text` (continuation lines joined), `bold` |
| `SpecReviewAnnotationCounts` | `questions`, `open_questions`, `answered_questions`, `comments`, `marks`, and the team counts `unresolved_questions`, `conflicts`, `open_conflicts` |
| `SpecReviewAnnotationError` | An operation named something that is not there |
| `strip_annotations_text` | One value without its annotations |
| `format_comment_block` / `format_question_block` | The lines an insert writes |
| `validate_review_annotations` | The validation findings of a `&SpecDocument`, without a mutable borrow |
| `SpecMarkDecision`, `SpecMarkEntry`, `SpecMarkOutcome`, `SpecMarkIssue`, `SpecMarkReport` | The inline-mark review: decisions, listed marks, what was done, malformed marks |

## Operations

| Operation | Does |
|-----------|------|
| `list()` | Every annotation, in document order. A question carries its `options`, its `recommended` letter (the bold option, else the option that says "recommended", else the letter of a `*Recommendation:*` line) and its `answer_letter()` (`(b)` or `**(b)**` at the start of the answer). A question of a combined block carries `combined: true` and the field it asks about as its topic; a comment carries the paragraph before it as `context` |
| `counts()` | The counts a report needs |
| `next_comment_id(floor)` | The id the next comment gets: the highest `C-<n>` in the document (or `floor`, when higher) plus one. Writes nothing |
| `assign_comment_ids(floor)` | Writes `**C-<n>**` after the marker of every comment without an id, in document order; returns the ids |
| `paragraphs(path, field)` | The value's paragraphs (`SpecParagraph`), each with its `index` (what `after_paragraph` takes), `start_line` / `end_line` within the value, its `text` and `annotation` (`comment` / `question` for an annotation block). The rule is SOM §11.9.1 "Paragraphs": blank-line separated, a blank line inside fenced code does not end one. A value the document does not hold is an error |
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

## Reviewing inline marks

| Operation | Does |
|-----------|------|
| `revision()` | The revision the mark ids are stable for (16 hex digits); any change to a value changes it |
| `list_marks(path)` | Every inline mark of the document (`None`) or of a subtree: `M-<n>` id, kind, path, old and new text, markup, the paragraph holding it |
| `decide_marks(&decisions, revision)` | One write: a `HashMap<String, SpecMarkDecision>` of `Accept` / `Reject` / `Leave`. `Err(SpecReviewAnnotationError)` when the document is no longer at `revision`, or when an id is unknown |
| `accept_all_marks(path)`, `reject_all_marks(path)` | Every mark under a path, or in the whole document (`None`), except change comments, which stay |
| `remove_all_annotations()` | Every mark accepted (change comments removed too), every conflict's decision applied, and every comment, question and conflict block removed, written back. `Err` while a conflict cannot be applied (see [Team reviews](#team-reviews)) |
| `decide_all_marks_text(text, accept)` | One value as accept all / reject all write it (a free function) |
| `apply_inline_marks_text(text, accept)` | One value with every mark accepted or rejected and every comment removed (a free function) |

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

```rust
use std::collections::HashMap;
use tom_som_rust_runtime::{SpecMarkDecision, SpecReviewAnnotations};

let mut review = SpecReviewAnnotations::new(&mut doc);
let rev = review.revision();
let marks = review.list_marks(None);
let decisions = HashMap::from([(marks[0].id.clone(), SpecMarkDecision::Accept)]);
let report = review.decide_marks(&decisions, &rev)?;
```

### Writing changes as marks

| Operation | Does |
|-----------|------|
| `mark_change_text(old, new)` | `new` with every difference from `old` marked. Accepting all marks gives `new`, rejecting all gives `old`. Returns a `SpecMarkedChange` (`text`, `exact`); a free function |
| `set_marked(path, field, text)` | Writes `text` as a marked change against the value there (`field` `None` for content). A value that already holds marks is compared from its original, so a second edit updates its mark |
| `mark_against(path, field, earlier)` | Marks the value already written against an earlier version |

`exact` is false only when a difference could not be marked, i.e. a change
inside fenced code. The new text is then written unmarked.

```rust
use tom_som_rust_runtime::mark_change_text;

let r = mark_change_text(
    "Sessions expire after 30 minutes.",
    "Sessions expire after 15 minutes.",
);
println!("{}", r.text); // Sessions expire after {~~ 30 ~> 15 ~~} minutes.
```

## Comments on changes

A change comment is a comment mark that starts with a quote of the change it
is about, written directly after that change:
`{~~ 30 ~> 15 ~~}{>> [~~ 30 ~> 15 ~~] why shorter? <<}`. The quote keeps the
comment readable once the change is decided. The notation is SOM §11.9.3.

| Operation | Does |
|-----------|------|
| `list_marks(path)` | A change comment's entry carries `quoted_change` (`kind`, `oldText`, `newText`, `outcome`) and `change_id`, its `comment` being the text after the quote. Its change's entry carries `comment_id` |
| `decide_marks`, `apply_mark`, `accept_all_marks`, `reject_all_marks` | Deciding a change leaves its attached comment, the quote recording ` \| accepted` or ` \| rejected`. Deciding the comment itself removes it |
| `comment_change(mark_id, text, author, revision)` | Writes a change comment after the change `mark_id`, its quote taken from the mark; returns the comment's id. `author` and `revision` are `Option<&str>` |
| `edit_mark_comment(mark_id, text, revision)` | Replaces the comment of a comment mark, change comment or commented highlight. A change comment keeps its quote |
| `set_marked(...)` | Keeps the value's change comments; a comment on a change marked again follows the new mark, detached, with its old quote |

`comment_change` and `edit_mark_comment` return
`Err(SpecReviewAnnotationError)` and change nothing for an unknown id, a
stale revision, a mark they cannot comment, or a text that is empty or holds
a mark delimiter or a blank line. A quote opened and never closed makes the
comment a plain one, and `validate()` reports it as `annotationMalformed`.

```rust
use std::collections::HashMap;
use tom_som_rust_runtime::{SpecMarkDecision, SpecReviewAnnotations};

let mut review = SpecReviewAnnotations::new(&mut doc);
let rev = review.revision();
let change = review.list_marks(None).remove(0); // {~~ 30 ~> 15 ~~}
let comment_id = review.comment_change(&change.id, "why shorter?", Some("alice"), Some(&rev))?;
let decisions = HashMap::from([(change.id.clone(), SpecMarkDecision::Accept)]);
review.decide_marks(&decisions, &review.revision())?;
// after 15{>> [~~ 30 ~> 15 ~~ | accepted] why shorter? <<}{@alice} minutes
```

`comment_id` is the new comment's `M-<n>`, valid for the revision after the
write.

## Extracting answers for a step folder

A step of the TomSpecs process opens by collecting the reviewer's answers and
comments into its step folder's `answers.md`. The annotations stay in the
document, and the extraction never writes.

| Operation | Does |
|-----------|------|
| `extract_answers(model, doc, label, path)` | A `SpecAnswerExtract`: every question (answered or open), comment and inline mark of the document or of a subtree (`path` `None` for the whole document), with its section-id chain and its line in the document's Markdown rendition, in rendition order. `Err` is the rendition's |
| `render_answers(extracts, options)` | The `answers.md` text. Deterministic: the documents in the order given, then their entries. `SpecAnswerRenderOptions` adds the open questions (`include_open`) and the inline marks (`include_marks`), and sets the `title`; its `Default` titles it `Answers` |
| `SpecAnswerExtract::counts()` | answered, open, comments, marks (`SpecAnswerCounts`): what a step's closing item reports |

Each entry is a `SpecAnswerEntry` whose `kind` is a `SpecAnswerKind`
(`Answered`, `Open`, `Comment`, `Mark`, all in `SpecAnswerKind::ALL`). A
comment is cited with the document root's id in front (`SBP C-12`). A comment
without an id is listed by its line; `assign_comment_ids` gives it one, when
asked.

```rust
use tom_som_rust_runtime::{extract_answers, render_answers, SpecAnswerRenderOptions};

let x = extract_answers(&model, &doc, "tom_uam.sbp", None)?;
let options = SpecAnswerRenderOptions {
    include_open: true,
    ..SpecAnswerRenderOptions::default()
};
std::fs::write("answers.md", render_answers(&[x.clone()], &options))?;
println!("{:?}", x.counts()); // SpecAnswerCounts { answered: 75, open: 269, comments: 0, marks: 0 }
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
| Attribution token | Part of its mark: in the `markup`, removed with the mark by every decision. `SpecReviewAnnotation` and `SpecMarkEntry` carry `authors` (member ids) and `votes` (`SpecMarkVote`: `member`, `accept`; `vote_name()` is `accept` / `reject`), both empty without a token |
| Individual answers | `SpecReviewAnnotation::answers`: `SpecIndividualAnswer` (`members`, `answer`, `answer_letter`), in the order written. The question's `text` ends before the first of them; `answer` stays the team's |
| Conflict block | Kind `SpecReviewAnnotationKind::Conflict` (`conflict`): `id`, `qualified_id`, `topic`, `text`, `base`, `alternatives` (`SpecConflictAlternative`: `letter`, `members`, `text`), the decision as `answer` (`decision` in JSON), `decision_letter()` (`a`…, `base` or `None`), `is_open()`, `is_unresolved()`. `paragraphs()` marks the block `Conflict` |
| `open:` | `is_unresolved()` true and `is_open()` false on the question or conflict; a question's `answer_letter()` is then `None` |

`counts()` adds `unresolved_questions` (also counted as answered), `conflicts`
and `open_conflicts`. Every JSON form has a `to_json_with(options)` beside
`to_json()`: `SpecReviewJsonOptions::TEAM` gives the members
`team_annotation_cases.json` pins; `to_json()` stays the form of the older case
files.

**Writing.** `set_answer_by(question_id, answer, Some("alice"))` writes that
member's individual answer instead of the team's, grouped by SOM §11.9.8: a
plain letter answer joins the line with the same answer, a commented one gets
its own line, an empty one only takes the member out. An author that is not a
member id (`is_review_member_id`) is refused with `SpecReviewAnnotationError`;
`set_answer_by(id, answer, None)` is `set_answer`. `remove_all_annotations()`
applies every conflict's decision and lists it in the report's `conflicts`
(`SpecConflictOutcome`: `id`, `path`, `field`, `line`, `decision`, `result`);
it returns `Err`, changing nothing, while a conflict is open, unresolved or
malformed, or its decision names a letter it has no alternative for. A
structural conflict (`Item removed`, `Item moved`, `Headline changed`) only
loses its block: its decision is the caller's to apply. `stripped()` keeps a
conflict's base text and drops the block. `format_conflict_block(id, topic,
text, base, &alternatives)` gives the lines of a block.

**Merging.** The module `spec_review_merge` merges the returned copies into a
new document and returns a `SpecReviewMergeResult` (`merged`, `report`);
neither the base nor a copy is changed.

| Function | Merges |
|----------|--------|
| `merge_reviews(&model, &base, &copies, &options)` | A `SpecDocument`, by model path, list items matched by section id; added items, structural conflicts and the draft revision entry included |
| `merge_reviews_markdown(&base, &copies, &options)` | A plain annotated Markdown `&str`, by heading path |

`copies` are `SpecReviewedCopy<D>` in round order: `member`
(`SpecReviewMember`: `member_id`, `display_name`, `role`) and `document` (a
`SpecDocument`, or a `String` for Markdown). `SpecReviewMergeOptions` holds
`team` (the members the round started with), `date` (ISO 8601: the revision
entry's date and every generated list-item id's), `author` and
`question_prefix` (`None`: `RQ`).

A copy whose structure does not fit the base (a path the model does not
resolve; other headings in Markdown) returns `Err(SpecReviewMergeError)` and
nothing is merged. The report, `SpecReviewMergeReport`, lists in merged
document order `reviewers` (with `guest`), `conflicts` (`id`, `path`, `field`,
`paragraph`, `members`), `votes`, `unanimous`, `answers`, `comments`,
`additions`, `guest_questions` and the `revision` entry (`None` without a
revision history); `to_json()` is the form `review_merge_cases.json` pins.

```rust
use tom_som_rust_runtime::{
    merge_reviews, SpecDocument, SpecReviewMember, SpecReviewMergeOptions, SpecReviewedCopy,
};

let doc = |text: &str| {
    let mut d = SpecDocument::new();
    d.set_content("DEMO/SUM", text);
    d
};
let member = |id: &str, name: &str, role: &str| SpecReviewMember {
    member_id: id.to_string(),
    display_name: name.to_string(),
    role: role.to_string(),
};
let team = vec![
    member("alice", "Alice Owner", "Product owner"),
    member("bob", "Bob Dev", "Developer"),
];
let copies: Vec<SpecReviewedCopy<SpecDocument>> = team
    .iter()
    .map(|m| SpecReviewedCopy {
        member: m.clone(),
        document: doc("Sessions expire after 15 minutes."),
    })
    .collect();
let options = SpecReviewMergeOptions {
    team: team.clone(),
    date: "2026-11-05".to_string(),
    author: "Alice Owner".to_string(),
    question_prefix: None,
};
let r = merge_reviews(&model, &doc("Sessions expire after 30 minutes."), &copies, &options)?;
println!("{}", r.merged.content_or("DEMO/SUM"));
println!("{}", r.report.conflicts.len());
```

Output:

```text
Sessions expire after {~~ 30 ~> 15 ~~}{@alice,bob} minutes.
0
```

`tests/review_annotations.rs` runs this example against the corpus DEMO model
and asserts the output.

A unit whose copy no longer holds more than 16 of the base's marks as written
is read as an edit (step 4 of SOM §11.9.9): the decision combinations would
grow past 65536.

## Validation

`validate_document` reports annotation findings as its last group, ordered by
path:

| Code | Constant | When |
|------|----------|------|
| `annotationMisplaced` | `SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED` | A comment, question or conflict block inside a form field's value |
| `annotationMalformed` | `SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED` | An unclosed or nested mark, a substitution without `~>`, a comment id that is not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, a question or answer (individual answers included) inside a comment block; an attribution token that is empty, names an id not of the member-id form, names a member twice or as author and voter, votes on a highlight or comment mark, or follows no mark directly; an individual answer by a member who already answered the question; a conflict header that is not `⚖️ **X-<n> — <topic>:**`, a conflict without its `(base)` line or without a lettered alternative |
| `duplicateAnnotationId` | `SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID` | A comment, question or conflict id used twice in one document |

They are findings, never parse rejections: the document still loads.

## Error Handling

Every operation that names a comment, a question, a paragraph or a mark that is
not there returns `Err(SpecReviewAnnotationError)` and changes nothing. `list`,
`counts`, `next_comment_id`, `assign_comment_ids`, `stripped`, `revision`,
`list_marks`, `accept_all_marks` and `reject_all_marks` cannot fail and return
their values directly. `remove_all_annotations` returns `Err` while a conflict
block cannot be applied, and `set_answer_by` while its author is not a member
id. The merge functions return `Err(SpecReviewMergeError)` for a copy that
does not fit the base.

## Best Practices

- Call `assign_comment_ids` when a reviewed document comes back, so every
  comment can be cited and logged by id.
- Pass the comment log's highest number as `floor`, so a number freed by a
  resolved comment is not handed out again.
- Never write `stripped()` back: annotations are removed one at a time, after
  their item is applied and logged.
