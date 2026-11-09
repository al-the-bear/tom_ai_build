/* spec_review_annotations — review annotations in content values (SOM §11.9):
 * comment blocks, question blocks and CriticMarkup inline marks, and the
 * team-review notation on top of them (§11.9.8: attribution tokens,
 * individual answers, conflict blocks, `open:`). A faithful port of the Dart
 * `spec_review_annotations.dart`; the team notation follows the TypeScript
 * reference, which has it first.
 *
 * An annotation is text inside a content value or a form-field value. This
 * module reads it out of that text and edits it in place, and every edit is
 * byte-stable outside the annotation it touches. The notation itself is
 * `som_multiplatform_spec_model.md` §11.9.
 *
 * Positions are **0-based line numbers within the value**, never character
 * offsets: the nine runtimes count characters in different units, and a line
 * number is the same in all of them. This runtime works on UTF-8 bytes
 * internally and never exports a byte offset.
 *
 * Values are visited in one fixed order — content paths sorted, then form
 * paths sorted with their field names sorted — and that is "document order"
 * for every operation.
 *
 * Error idiom: every operation that names a comment, a question, a paragraph
 * or a mark that is not there returns 0 (or NULL), changes nothing, and fills
 * `*err` (a `SpecReviewAnnotationError`, when non-NULL) with an owned message.
 *
 * Ownership: `SpecReviewAnnotations` borrows its document, qualifier and
 * clock context; they must outlive it, and it owns nothing. Every listed annotation, list, id and
 * string returned is owned by the caller and released as documented below.
 */
#ifndef SPEC_REVIEW_ANNOTATIONS_H
#define SPEC_REVIEW_ANNOTATIONS_H

#include <stddef.h>

#include "som_util.h"
#include "spec_document.h"
#include "spec_validator.h"

/* The kinds of annotation (SOM §11.9): the three of §11.9.1–11.9.3 and the
 * conflict block a team review adds (§11.9.8). */
typedef enum {
  /* A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`. */
  SPEC_REVIEW_ANNOTATION_COMMENT = 0,
  /* One question of a question block, `> **❓ BQ-81 — topic:** …`. */
  SPEC_REVIEW_ANNOTATION_QUESTION = 1,
  /* A CriticMarkup inline mark. */
  SPEC_REVIEW_ANNOTATION_MARK = 2,
  /* A conflict block, `> ⚖️ **X-3 — Conflicting changes:** …` (§11.9.8). */
  SPEC_REVIEW_ANNOTATION_CONFLICT = 3,
} SpecReviewAnnotationKind;

/* The kind's wire name (`"comment"`, `"question"`, `"mark"`, `"conflict"`);
 * static. */
const char *spec_review_annotation_kind_name(SpecReviewAnnotationKind kind);

/* The five CriticMarkup inline marks (SOM §11.9.3). */
typedef enum {
  SPEC_MARK_COMMENT = 0,      /* `{>> comment <<}` */
  SPEC_MARK_HIGHLIGHT = 1,    /* `{== text ==}`, optionally `{>> comment <<}` */
  SPEC_MARK_INSERTION = 2,    /* `{++ added ++}` */
  SPEC_MARK_DELETION = 3,     /* `{-- removed --}` */
  SPEC_MARK_SUBSTITUTION = 4, /* `{~~ old ~> new ~~}` */
} SpecMarkKind;

/* The mark kind's wire name (`"comment"`, `"highlight"`, `"insertion"`,
 * `"deletion"`, `"substitution"`); static. */
const char *spec_mark_kind_name(SpecMarkKind kind);

/* One option of a question (SOM §11.9.2): `- (a) text`, or `- **(b)** text`
 * for the recommended one. Strings owned. */
typedef struct {
  /* The lowercase letter, a one-character string. */
  char *letter;
  /* The option's text, its continuation lines joined with one space. */
  char *text;
  /* Whether the option is written bold — the recommended one. */
  int bold;
} SpecQuestionOption;

/* `{letter, text, bold}`. Owned. */
char *spec_question_option_to_json(const SpecQuestionOption *o);

/* ---- team reviews (SOM §11.9.8) -------------------------------------------
 *
 * The `*_to_team_json` forms below give the extended form
 * `team_annotation_cases.json` pins: marks with `authors` and `votes`,
 * questions with `unresolved` and `answers`, the counts with the team counts,
 * a removal report with its `conflicts`. The plain `*_to_json` forms stay the
 * ones of §11.9.1–11.9.7, which the older case files pin byte for byte. */

/* One reviewer's vote on a mark someone else proposed: `+id` accepts, `-id`
 * rejects. `member` owned. */
typedef struct {
  char *member; /* the voter's member id */
  int accept;   /* `+id` (1) or `-id` (0) */
} SpecMarkVote;

/* One line of individual answers, `**Answer (alice, bob):** (a)`. Owned. */
typedef struct {
  SomStrList members; /* who gave this answer, in the order written */
  char *answer;       /* the answer, trimmed */
  /* When the answer was last written (SOM §11.9.10), the last part of the
   * member list; NULL without one. */
  char *changed_at;
} SpecIndividualAnswer;

/* One lettered alternative of a conflict block, `- (a) **alice:** text`.
 * Owned. */
typedef struct {
  char *letter;       /* the lowercase letter, a one-character string */
  SomStrList members; /* who made this change */
  char *text;         /* the text; its continuation lines kept as lines */
} SpecConflictAlternative;

/* Whether `s` is a member id (SOM §11.9.8): lowercase letters, digits and
 * `_`. */
int spec_review_is_member_id(const char *s);

/* One annotation, located by the value that holds it. Every string is owned;
 * NULL stands for the Dart `null`. Release with `spec_review_annotation_free`
 * (a list releases its items). */
typedef struct {
  SpecReviewAnnotationKind kind;
  /* The document path of the value: a content path, or a form path when
   * `field` is set. */
  char *path;
  /* The form field whose value holds the annotation; NULL for content. */
  char *field;
  /* The 0-based line within the value where the annotation starts (a
   * question: its header line). */
  size_t line;
  /* The comment id (`C-12`), question id (`BQ-81`) or conflict id (`X-3`);
   * NULL for a comment without an id and for a mark. */
  char *id;
  /* A comment's or conflict's id with the document qualifier in front
   * (`SBP C-12`), when the listing was given a qualifier and it has an id;
   * else NULL. */
  char *qualified_id;
  /* A comment's author; NULL when none is written. */
  char *author;
  /* A comment's text, a question's text (options included; it ends before the
   * first individual answer), a conflict's text (what it concerns), or a
   * mark's text (a substitution's old text; empty for a comment mark). Never
   * NULL. */
  char *text;
  /* A comment's context: the paragraph before the block, verbatim (empty at
   * the start of the value). Never NULL. */
  char *context;
  /* A question's or conflict's topic (in a combined block: the field it asks
   * about); NULL for the other kinds. */
  char *topic;
  /* Whether a question carries `★` before its topic. */
  int starred;
  /* Whether a question is part of a combined block. */
  int combined;
  /* A question's team answer, or a conflict's decision, trimmed; empty when
   * open. Never NULL. */
  char *answer;
  /* A question's options, in order (none when it states none). Owned. */
  SpecQuestionOption *options;
  size_t options_len;
  /* A question's recommended letter: the bold option, else the option that
   * says "recommended", else the letter of a `*Recommendation:*` line; NULL
   * for none. */
  char *recommended;
  /* A mark's kind (meaningful for SPEC_REVIEW_ANNOTATION_MARK only). */
  SpecMarkKind mark_kind;
  /* A substitution's new text; else NULL. */
  char *new_text;
  /* The comment of a comment mark, or of a highlight followed by one; else
   * NULL. */
  char *comment;
  /* A mark's authors from its attribution token; empty without one. */
  SomStrList authors;
  /* A mark's votes from its attribution token; none without one. */
  SpecMarkVote *votes;
  size_t votes_len;
  /* A question's individual answers, in the order written. */
  SpecIndividualAnswer *answers;
  size_t answers_len;
  /* A conflict's `(base)` text; NULL for the other kinds. */
  char *base;
  /* A conflict's lettered alternatives. */
  SpecConflictAlternative *alternatives;
  size_t alternatives_len;
  /* When a comment, mark or question was last changed (SOM §11.9.10); NULL
   * without a change time and for the other kinds. A question's is the time
   * in its header. */
  char *changed_at;
  /* When a question's team answer was last changed (SOM §11.9.10): the time
   * in `**Answer (<time>):**`; NULL without one and for the other kinds. */
  char *answer_changed_at;
} SpecReviewAnnotation;

void spec_review_annotation_free(SpecReviewAnnotation *a);

/* Whether a question is still open (no team answer written), or a conflict
 * (no decision written). */
int spec_review_annotation_is_open(const SpecReviewAnnotation *a);

/* Whether a question's team answer or a conflict's decision begins with
 * `open:` — answered for a gate, but handed back (SOM §11.9.8). */
int spec_review_annotation_is_unresolved(const SpecReviewAnnotation *a);

/* The letter a question's team answer starts with (`(b)` or `**(b)**`), as an
 * owned one-character string; NULL for none, for an unresolved answer and for
 * the other kinds. */
char *spec_review_annotation_answer_letter(const SpecReviewAnnotation *a);

/* A conflict's decision letter (`a`…, `base`), owned; NULL for rewritten
 * text, for none and for the other kinds. */
char *spec_review_annotation_decision_letter(const SpecReviewAnnotation *a);

/* The canonical JSON form the conformance corpus pins (every key written,
 * `null` explicitly, except `changedAt`, written only when set: after a
 * comment's `context`, after a mark's `comment`, and after an individual
 * answer's `answerLetter`). Owned result. */
char *spec_review_annotation_to_json(const SpecReviewAnnotation *a);
/* The same with the team members of SOM §11.9.8. Owned. */
char *spec_review_annotation_to_team_json(const SpecReviewAnnotation *a);

typedef struct {
  SpecReviewAnnotation *items;
  size_t len;
  size_t cap;
} SpecReviewAnnotationList;

void spec_review_annotation_list_init(SpecReviewAnnotationList *l);
void spec_review_annotation_list_free(SpecReviewAnnotationList *l);

/* The counts a report needs (SOM §11.9). */
typedef struct {
  size_t questions;          /* every question */
  size_t open_questions;     /* questions without an answer */
  size_t answered_questions; /* questions with an answer */
  size_t comments;           /* comment blocks */
  size_t marks;              /* inline marks */
  /* Questions whose team answer begins `open:` (also counted as answered). */
  size_t unresolved_questions;
  size_t conflicts;      /* conflict blocks */
  size_t open_conflicts; /* conflict blocks without a decision */
} SpecReviewAnnotationCounts;

/* `{questions, openQuestions, answeredQuestions, comments, marks}`. Owned. */
char *spec_review_annotation_counts_to_json(const SpecReviewAnnotationCounts *c);
/* The same with `unresolvedQuestions`, `conflicts` and `openConflicts`. */
char *spec_review_annotation_counts_to_team_json(
    const SpecReviewAnnotationCounts *c);

/* A question to insert (SOM §11.9.2). Every pointer is borrowed. */
typedef struct {
  const char *id;    /* the question id (`BQ-90`) */
  const char *topic; /* the topic */
  const char *text;  /* the question text; may span lines */
  /* Option lines, written as `- <option>` (e.g. `(a) lower only`). */
  const char *const *options;
  size_t options_len;
  const char *recommendation; /* NULL or "" for none */
  const char *assumption;     /* NULL or "" for none */
  int starred;                /* whether the question carries `★` */
  /* The recommended option's letter (`"b"`); that option is written bold.
   * NULL for none. */
  const char *recommended;
} SpecQuestionDraft;

/* Raised by an operation that names an annotation, value or paragraph that
 * does not exist. Initialise with `spec_review_annotation_error_init`, release
 * with `spec_review_annotation_error_free`. */
typedef struct {
  char *message; /* owned; NULL while no error was raised */
} SpecReviewAnnotationError;

void spec_review_annotation_error_init(SpecReviewAnnotationError *err);
void spec_review_annotation_error_free(SpecReviewAnnotationError *err);

/* ---- change times (SOM §11.9.10) ------------------------------------------
 *
 * Every annotation records when it was last changed, next to its author: the
 * last word of a mark's attribution token (`{@alice 2026-11-07T14:05+01:00}`,
 * `{@2026-11-07T14:05+01:00}`), the last part of a comment header's
 * parentheses (`(Alexis, 2026-11-07T14:05+01:00):`) and of an individual
 * answer's member list. A change time is minutes with the writer's UTC
 * offset, `2026-11-07T14:05+01:00` or `2026-11-07T13:05Z`. */

/* Whether `s` is a change time of the form SOM §11.9.10 fixes:
 * `YYYY-MM-DDTHH:MM` followed by `Z` or `+HH:MM` / `-HH:MM`. */
int spec_review_is_time(const char *s);

/* `at` — an ISO 8601 time with minutes, optional seconds and fraction, and an
 * offset or `Z` (`YYYY-MM-DDTHH:MM[:SS[.fff]](Z|±HH:MM)`, surrounding
 * whitespace ignored) — as a change time: seconds and fraction cut, the offset
 * kept as given. Owned; NULL (filling `*err`, when non-NULL) for any other
 * shape. */
char *spec_review_normalize_time(const char *at,
                                 SpecReviewAnnotationError *err);

/* The system clock's current local time as a change time, in its local UTC
 * offset (`2026-11-07T14:05+01:00`). Owned. */
char *spec_review_system_time(void);

/* ---- inline-mark review (SOM §11.9.3) ------------------------------------ */

/* What to do with one inline mark. */
typedef enum {
  /* Take the change: an insertion's text, nothing for a deletion, a
   * substitution's new text. */
  SPEC_MARK_DECISION_ACCEPT = 0,
  /* Undo the change: nothing for an insertion, a deletion's text, a
   * substitution's old text. */
  SPEC_MARK_DECISION_REJECT = 1,
  /* Keep the mark as written. */
  SPEC_MARK_DECISION_LEAVE = 2,
} SpecMarkDecision;

/* The decision's wire name (`"accept"`, `"reject"`, `"leave"`); static. */
const char *spec_mark_decision_name(SpecMarkDecision d);

/* Parses a wire name into `*out`; 0 when unknown. */
int spec_mark_decision_parse(const char *name, SpecMarkDecision *out);

/* A change comment's quote of a change (SOM §11.9.3): `{>> [-- old --] why?
 * <<}`. Every string is owned. */
typedef struct {
  SpecMarkKind kind; /* insertion, deletion or substitution */
  char *old_text;    /* the quoted old text; "" for an insertion */
  char *new_text;    /* the quoted new text; "" for a deletion */
  char *outcome;     /* "accepted", "rejected", or NULL while open */
} SpecQuotedChange;

/* One inline mark as `spec_review_annotations_list_marks` reports it. Every
 * string is owned; `field`, `comment`, `quoted_change`, `comment_id` and
 * `change_id` may be NULL. */
typedef struct {
  /* `M-<n>`: the mark's 1-based position among all marks of the document, in
   * document order. Stable for one `spec_review_annotations_revision`. */
  char *id;
  char *path;
  char *field;          /* NULL for content */
  size_t line;          /* 0-based line within the value where it opens */
  SpecMarkKind mark_kind;
  char *old_text;       /* the text after rejecting the mark */
  char *new_text;       /* the text after accepting the mark */
  char *comment;        /* a comment mark's / commented highlight's comment */
  char *markup; /* the mark as written, its attribution token included */
  char *context;        /* the paragraph holding the mark, verbatim */
  /* The authors its attribution token names (SOM §11.9.8); empty without. */
  SomStrList authors;
  /* The votes its attribution token records; none without one. */
  SpecMarkVote *votes;
  size_t votes_len;
  /* A change comment's quote (SOM §11.9.3); NULL for any other mark. Its
   * `comment` is then the text after the quote. Owned. */
  SpecQuotedChange *quoted_change;
  /* A change's attached comment, by id; NULL without one. */
  char *comment_id;
  /* The change an attached change comment is about, by id; NULL otherwise. */
  char *change_id;
  /* When the mark was last changed (SOM §11.9.10), from its attribution
   * token; NULL without one. */
  char *changed_at;
} SpecMarkEntry;

void spec_mark_entry_free(SpecMarkEntry *e);
/* The canonical JSON form the conformance corpus pins; `quotedChange`,
 * `commentId`, `changeId` and `changedAt` appear only on the marks they
 * describe. Owned. */
char *spec_mark_entry_to_json(const SpecMarkEntry *e);
/* The same with `authors` and `votes`. Owned. */
char *spec_mark_entry_to_team_json(const SpecMarkEntry *e);

typedef struct {
  SpecMarkEntry *items;
  size_t len;
  size_t cap;
} SpecMarkEntryList;

void spec_mark_entry_list_init(SpecMarkEntryList *l);
void spec_mark_entry_list_free(SpecMarkEntryList *l);

/* What was done to one mark. Strings owned; `field` may be NULL. */
typedef struct {
  char *id; /* the mark's id at the revision the operation ran on */
  char *path;
  char *field;
  size_t line;
  SpecMarkKind mark_kind;
  SpecMarkDecision decision; /* accept or reject */
  char *markup;              /* the mark as written */
  char *result;              /* the text that replaced it */
} SpecMarkOutcome;

/* A mark the scanner could not read; it is left as written. */
typedef struct {
  char *path;
  char *field;
  size_t line;
  char *issue; /* `unclosed`, `nested` or `noArrow` */
} SpecMarkIssue;

/* What `spec_review_annotations_remove_all_annotations` did with one conflict
 * block (SOM §11.9.8). Strings owned; `field` may be NULL. */
typedef struct {
  char *id; /* the conflict id, `X-<n>` */
  char *path;
  char *field;
  size_t line;    /* the 0-based line within the value where the block opened */
  char *decision; /* the decision as written */
  char *result;   /* the text the decision chose */
} SpecConflictOutcome;

/* The report of a mark operation, for the decision log. Initialise with
 * `spec_mark_report_init`, release with `spec_mark_report_free`. */
typedef struct {
  SpecMarkOutcome *applied; /* what was done, in document order */
  size_t applied_len, applied_cap;
  SpecMarkIssue *malformed; /* malformed marks in scope, left as written */
  size_t malformed_len, malformed_cap;
  /* The conflicts `remove_all_annotations` applied, in document order; set
   * (`has_conflicts`) by that operation only — the mark operations do not
   * touch conflicts. */
  int has_conflicts;
  SpecConflictOutcome *conflicts;
  size_t conflicts_len, conflicts_cap;
} SpecMarkReport;

void spec_mark_report_init(SpecMarkReport *r);
void spec_mark_report_free(SpecMarkReport *r);
/* `{applied: [...], malformed: [...]}`. Owned. */
char *spec_mark_report_to_json(const SpecMarkReport *r);
/* The same with `conflicts` when `has_conflicts`. Owned. */
char *spec_mark_report_to_team_json(const SpecMarkReport *r);

/* One decision of `spec_review_annotations_decide_marks`. Borrowed. */
typedef struct {
  const char *id;
  SpecMarkDecision decision;
} SpecMarkDecisionItem;

/* ---- text level: one value ---------------------------------------------- */

/* `value` with every inline mark accepted (`accept` non-zero) or rejected,
 * and every highlight and comment mark removed. Marks in code and malformed
 * marks stay as written. Owned result. */
char *spec_apply_inline_marks_text(const char *value, int accept);

/* `value` with every inline mark accepted (`accept` non-zero) or rejected, as
 * accept all / reject all write it (SOM §11.9.3): change comments stay, an
 * attached one records the outcome; every other highlight and comment mark is
 * removed. Marks in code and malformed marks stay as written. Owned result. */
char *spec_decide_all_marks_text(const char *value, int accept);

/* ---- writing changes as inline marks (SOM §11.9.3) ---------------------- */

/* A value written as a marked change. Release with `spec_marked_change_free`. */
typedef struct {
  /* The value with every difference marked. Owned. */
  char *text;
  /* Whether accepting the marks gives exactly the new value and rejecting
   * them exactly the old one. 0 when a difference cannot be marked — a change
   * inside fenced code, or text that holds mark delimiters — and the new value
   * was written unmarked instead. */
  int exact;
} SpecMarkedChange;

void spec_marked_change_free(SpecMarkedChange *c);
/* `{text, exact}`. Owned. */
char *spec_marked_change_to_json(const SpecMarkedChange *c);

/* `new_value` with its differences from `old_value` marked, so that accepting
 * every mark gives exactly `new_value` and rejecting every mark exactly
 * `old_value`. The diff runs by line, then by word inside a changed run of
 * lines; words are never split, changes separated by at most two unchanged
 * words are one mark, and nothing inside code is marked. */
SpecMarkedChange spec_mark_change_text(const char *old_value,
                                       const char *new_value);

/* The lines of a comment block (`author` NULL or "" for none; `changed_at`,
 * a change time, NULL for none), written into `out` (initialised by the
 * callee). The header's parentheses hold the author and the change time,
 * `(Alexis, 2026-11-07T14:05+01:00):`, or either alone (SOM §11.9.10). */
void spec_format_comment_block(const char *id, const char *text,
                               const char *author, const char *changed_at,
                               SomStrList *out);

/* The attribution token for `authors`, `votes` and `changed_at` (each may be
 * empty / NULL), `{@agent +alice -bob 2026-11-07T14:05+01:00}` (SOM §11.9.8,
 * §11.9.10): the authors joined with `,`, then the votes, then the time,
 * separated by spaces. "" when there is nothing to write. Owned. */
char *spec_review_format_attribution_token(const SomStrList *authors,
                                           const SpecMarkVote *votes,
                                           size_t votes_len,
                                           const char *changed_at);

/* The lines of a question block, written into `out` (initialised by the
 * callee); `changed_at` (NULL: none) is written after the id (SOM §11.9.10). */
void spec_format_question_block(const SpecQuestionDraft *q,
                                const char *changed_at, SomStrList *out);

/* The lines of a conflict block (SOM §11.9.8) into `out` (initialised by the
 * callee): the header, the `(base)` line, one lettered alternative per entry
 * naming its members, and an empty `**Decision:**`. A text's further lines are
 * indented under it, so a reader gets them back with their line breaks. */
void spec_review_format_conflict_block(
    const char *id, const char *topic, const char *text, const char *base,
    const SpecConflictAlternative *alternatives, size_t alternatives_len,
    SomStrList *out);

/* `value` without any comment block, question block or inline mark (every
 * mark accepted). Plain quotes and code stay. Owned result. */
char *spec_strip_annotations_text(const char *value);

/* ---- document level ----------------------------------------------------- */

/* One paragraph of a value (SOM §11.9.1, "Paragraphs"): a run of non-blank
 * lines, where a blank line inside fenced code does not end the run. Its
 * `index` is what `after_paragraph` of the inserts takes. Strings owned. */
typedef struct {
  size_t index;      /* the 0-based position among the value's paragraphs */
  size_t start_line; /* the 0-based first line within the value */
  size_t end_line;   /* the 0-based last line within the value (inclusive) */
  char *text;        /* the paragraph's lines, verbatim, joined with `\n` */
  /* `comment`, `question` or `conflict` (static) when the paragraph opens
   * with an annotation block of that kind, else NULL. */
  const char *annotation;
} SpecParagraph;

/* The canonical JSON form the conformance corpus pins. Owned. */
char *spec_paragraph_to_json(const SpecParagraph *p);

typedef struct {
  SpecParagraph *items;
  size_t len;
  size_t cap;
} SpecParagraphList;

void spec_paragraph_list_init(SpecParagraphList *l);
void spec_paragraph_list_free(SpecParagraphList *l);

/* A clock the writes take their change time from (SOM §11.9.10) when no `at`
 * is passed: called with the `clock_context` it was registered with, it
 * returns the change time to record as a heap string (`malloc`) the runtime
 * frees. NULL from the clock falls back to the system clock. */
typedef char *(*SpecReviewClock)(void *context);

/* The annotations of a document, and the operations that edit them. */
typedef struct {
  SpecDocument *doc; /* borrowed */
  /* The document's id or name, written in front of a comment id cited
   * outside the document (`SBP` → `SBP C-12`); NULL for bare ids. Borrowed. */
  const char *qualifier;
  /* The clock the writes take a change time from when no `at` is passed;
   * NULL: the system clock in the writer's offset
   * (`spec_review_system_time`). */
  SpecReviewClock clock;
  /* Passed to `clock`; borrowed. */
  void *clock_context;
} SpecReviewAnnotations;

/* Wraps `doc`, with the system clock. */
SpecReviewAnnotations spec_review_annotations_make(SpecDocument *doc,
                                                   const char *qualifier);

/* Wraps `doc`; `clock` (with `clock_context`) fixes the change time the
 * writes record (the conformance driver passes a fixed one). */
SpecReviewAnnotations spec_review_annotations_make_with_clock(
    SpecDocument *doc, const char *qualifier, SpecReviewClock clock,
    void *clock_context);

/* Every annotation, in document order, written into `out` (initialised by the
 * callee; release with `spec_review_annotation_list_free`). */
void spec_review_annotations_list(const SpecReviewAnnotations *r,
                                  SpecReviewAnnotationList *out);

/* The counts a report needs. */
SpecReviewAnnotationCounts
spec_review_annotations_counts(const SpecReviewAnnotations *r);

/* The id the next comment gets: `C-<n>`, n = the highest number in the
 * document (or `floor`, when higher) plus one. Writes nothing. Owned. */
char *spec_review_annotations_next_comment_id(const SpecReviewAnnotations *r,
                                              long long floor);

/* Gives every comment without an id the next one, in document order, and
 * writes the ids assigned into `out` (initialised by the callee). Nothing else
 * changes. */
void spec_review_annotations_assign_comment_ids(const SpecReviewAnnotations *r,
                                                long long floor,
                                                SomStrList *out);

/* The paragraphs of the value at `path` / `field` (NULL: content), in
 * order — the units `after_paragraph` of the inserts counts — written into
 * `out` (initialised by the callee in every case). Returns 0, filling `*err`,
 * when the document holds no such value; an empty value has no paragraphs. */
int spec_review_annotations_paragraphs(const SpecReviewAnnotations *r,
                                       const char *path, const char *field,
                                       SpecParagraphList *out,
                                       SpecReviewAnnotationError *err);

/* Inserts a comment block after paragraph `after_paragraph` (0-based; -1: at
 * the start) of the value at `path` / `field` (NULL: content), and returns its
 * id (owned) — `id` when non-NULL, else the next free one. `author` may be
 * NULL. The header records the change time (SOM §11.9.10): `at` normalized
 * (`spec_review_normalize_time`) when non-NULL, else the clock's. Returns
 * NULL (filling `*err`) when the paragraph does not exist or `at` is not a
 * time; nothing changes then. */
char *spec_review_annotations_insert_comment(const SpecReviewAnnotations *r,
                                             const char *path,
                                             const char *field,
                                             long long after_paragraph,
                                             const char *text,
                                             const char *author,
                                             const char *id, const char *at,
                                             SpecReviewAnnotationError *err);

/* Inserts a question block after paragraph `after_paragraph` (0-based; -1: at
 * the start) of the value at `path` / `field`; its header carries the change
 * time (SOM §11.9.10): `at` normalized when non-NULL, else the clock's.
 * Returns 1, or 0 (filling `*err`, nothing changes) when the paragraph does
 * not exist or `at` is not a time. */
int spec_review_annotations_insert_question(const SpecReviewAnnotations *r,
                                            const char *path,
                                            const char *field,
                                            long long after_paragraph,
                                            const SpecQuestionDraft *question,
                                            const char *at,
                                            SpecReviewAnnotationError *err);

/* Inserts a question block directly after the comment `comment_id`; its
 * header carries the change time as `spec_review_annotations_insert_question`
 * writes it. */
int spec_review_annotations_insert_question_after_comment(
    const SpecReviewAnnotations *r, const char *comment_id,
    const SpecQuestionDraft *question, const char *at,
    SpecReviewAnnotationError *err);

/* Writes `answer` as the question's team answer, `**Answer (<time>):**` with
 * the change time (SOM §11.9.10): `at` normalized when non-NULL, else the
 * clock's. Empty reopens it as `**Answer:**` (`at` is then not read).
 * Refused — 0, `*err` filled, nothing changes — when the question does not
 * exist or `at` is not a time. */
int spec_review_annotations_set_answer(const SpecReviewAnnotations *r,
                                       const char *question_id,
                                       const char *answer, const char *at,
                                       SpecReviewAnnotationError *err);

/* Writes member `author`'s individual answer to the question instead of the
 * team's, grouped and placed by the rules of SOM §11.9.8: the member leaves
 * the line it was on; a non-empty answer is written with its change time
 * (SOM §11.9.10; `at` normalized when non-NULL, else the clock's) and, when
 * it is not commented, joins the line with the identical uncommented answer
 * and the same time, else gets a line of its own (empty: only takes the
 * member out; `at` is then not read). Refused — 0, `*err` filled, nothing
 * changes — when `author` is not a member id, the question does not exist or
 * `at` is not a time. */
int spec_review_annotations_set_member_answer(const SpecReviewAnnotations *r,
                                              const char *question_id,
                                              const char *author,
                                              const char *answer,
                                              const char *at,
                                              SpecReviewAnnotationError *err);

/* Replaces a comment's text; its marker, id and author stay as written, and
 * the header records the change time (SOM §11.9.10): `at` normalized when
 * non-NULL, else the clock's. Refused — 0, `*err` filled, nothing changes —
 * for an unknown id and an `at` that is not a time. */
int spec_review_annotations_edit_comment(const SpecReviewAnnotations *r,
                                         const char *comment_id,
                                         const char *text, const char *at,
                                         SpecReviewAnnotationError *err);

/* Removes one comment or question by id (a qualified comment id, `SBP C-12`,
 * is accepted). A question of a combined block takes only its own lines; the
 * block goes when its last question does. */
int spec_review_annotations_resolve(const SpecReviewAnnotations *r,
                                    const char *id,
                                    SpecReviewAnnotationError *err);

/* Accepts (`accept` non-zero) or rejects the inline mark `index` (0-based
 * among the marks of the value at `path` / `field`). */
int spec_review_annotations_apply_mark(const SpecReviewAnnotations *r,
                                       const char *path, const char *field,
                                       long long index, int accept,
                                       SpecReviewAnnotationError *err);

/* The revision the mark ids are stable for: FNV-1a 64-bit over the UTF-8 of
 * every value in document order (path, NUL, field or empty, NUL, text, NUL),
 * as 16 lower-case hex digits. Owned. */
char *spec_review_annotations_revision(const SpecReviewAnnotations *r);

/* Every inline mark of the document, or of the subtree at `path` (NULL: the
 * whole document), in document order, written into `out` (initialised by the
 * callee; release with `spec_mark_entry_list_free`). */
void spec_review_annotations_list_marks(const SpecReviewAnnotations *r,
                                        const char *path,
                                        SpecMarkEntryList *out);

/* Applies one decision per named mark in one write. Refused — returns 0,
 * fills `*err`, changes nothing — when the document is no longer at
 * `revision`, or when a decision names a mark that does not exist (a later
 * duplicate id overrides an earlier one). Marks not named, and marks decided
 * `leave`, stay. `out` is initialised by the callee in every case. */
int spec_review_annotations_decide_marks(const SpecReviewAnnotations *r,
                                         const SpecMarkDecisionItem *decisions,
                                         size_t decisions_len,
                                         const char *revision,
                                         SpecMarkReport *out,
                                         SpecReviewAnnotationError *err);

/* Accepts every inline mark under `path` (NULL: the whole document), except
 * change comments, which stay (SOM §11.9.3). */
void spec_review_annotations_accept_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out);

/* Rejects every inline mark under `path` (NULL: the whole document), except
 * change comments, which stay (SOM §11.9.3). */
void spec_review_annotations_reject_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out);

/* Writes a change comment (SOM §11.9.3) directly after the change mark
 * `mark_id` (`M-<n>`), its quote written from the mark and `text` after it,
 * with an attribution token holding `author` (when non-NULL) and the change
 * time (SOM §11.9.10; `at` normalized when non-NULL, else the clock's),
 * `{@author 2026-11-07T14:05+01:00}`, and returns the new comment's id
 * (owned). Refused — NULL, `*err` filled, nothing changes — for an unknown
 * id, a stale `revision` (when non-NULL), a mark that is not a change or
 * already has an attached comment, a change its quote cannot hold, a `text`
 * that is empty or holds a mark delimiter or a blank line, an `author` that is
 * not a member id, and an `at` that is not a time. */
char *spec_review_annotations_comment_change(const SpecReviewAnnotations *r,
                                             const char *mark_id,
                                             const char *text,
                                             const char *author,
                                             const char *revision,
                                             const char *at,
                                             SpecReviewAnnotationError *err);

/* Replaces the comment of the comment mark, change comment or commented
 * highlight `mark_id` with `text` (SOM §11.9.3). A change comment keeps its
 * quote as written; the attribution token keeps its authors and votes and
 * records the change time (SOM §11.9.10; `at` normalized when non-NULL, else
 * the clock's). Refused — 0, `*err` filled, nothing changes — for an unknown
 * id, a stale `revision` (when non-NULL), a mark that holds no comment, a
 * `text` that is empty or holds a mark delimiter or a blank line, and an `at`
 * that is not a time. */
int spec_review_annotations_edit_mark_comment(const SpecReviewAnnotations *r,
                                              const char *mark_id,
                                              const char *text,
                                              const char *revision,
                                              const char *at,
                                              SpecReviewAnnotationError *err);

/* Removes every annotation and writes the result back: every inline mark
 * accepted, every conflict's decision applied (SOM §11.9.8), every comment,
 * question and conflict block removed. Malformed marks stay and are reported.
 * `out` (initialised by the callee in every case) holds the accept report and
 * the applied conflicts. Refused — returns 0, fills `*err`, changes nothing —
 * while a conflict is open, unresolved (`open:`), malformed, or decided for a
 * letter it has no alternative for. */
int spec_review_annotations_remove_all_annotations(
    const SpecReviewAnnotations *r, SpecMarkReport *out,
    SpecReviewAnnotationError *err);

/* Writes `text` at `path` / `field` (NULL: content) as a marked change
 * against the value there now, into `*out` (initialised by the callee in
 * every case; release with `spec_marked_change_free`). A value that already
 * holds change marks is compared from its original — every mark rejected — so
 * a second edit of the same passage updates its mark instead of nesting one.
 * Change comments are kept: taken out of the original, then written back
 * where as many non-whitespace characters have passed as before them (SOM
 * §11.9.3). Every change mark written gets an attribution token (SOM
 * §11.9.10): the token of the same change in the value before (same kind, old
 * and new text; each used once, in order) when it held it, else
 * `{@author <time>}` (`author` NULL: `{@<time>}`), the time `at` normalized
 * when non-NULL, else the clock's. Refused — 0, `*err` filled, nothing
 * changes — for an `author` that is not a member id and an `at` that is not a
 * time. */
int spec_review_annotations_set_marked(const SpecReviewAnnotations *r,
                                       const char *path, const char *field,
                                       const char *text, const char *author,
                                       const char *at, SpecMarkedChange *out,
                                       SpecReviewAnnotationError *err);

/* Marks the value at `path` / `field` as a change against `earlier`, an
 * earlier version of it, and writes the result into `*out` (initialised by
 * the callee in every case); its change marks get attribution tokens as
 * `spec_review_annotations_set_marked` writes them. Refused — 0, `*err`
 * filled, nothing changes — for an `author` that is not a member id and an
 * `at` that is not a time. */
int spec_review_annotations_mark_against(const SpecReviewAnnotations *r,
                                         const char *path, const char *field,
                                         const char *earlier,
                                         const char *author, const char *at,
                                         SpecMarkedChange *out,
                                         SpecReviewAnnotationError *err);

/* A copy of the document without any annotation, for reading. The document
 * itself is unchanged. Owned heap document: release with
 * `spec_document_free` + `free`. */
SpecDocument *spec_review_annotations_stripped(const SpecReviewAnnotations *r);

/* The instance-tier findings on annotations (SOM §11.9.5), stable-sorted by
 * path, written into `out` (initialised by the callee; release with
 * `spec_validation_errors_free`): `annotationMalformed`,
 * `annotationMisplaced` and `duplicateAnnotationId`. Writes nothing. */
void spec_review_annotations_validate(const SpecReviewAnnotations *r,
                                      SpecValidationErrors *out);

/* ---- text-level building blocks of the merge (SOM §11.9.9) ---------------
 *
 * Internal: `spec_review_merge` is built on them. They live here because they
 * read a value with this module's parser; they are not part of the annotation
 * API. Every result is owned by the caller. */

/* One paragraph of a value as the merge sees it: text, or an annotation
 * block. */
typedef struct {
  int is_text; /* 1: a text paragraph; 0: an annotation block of `kind` */
  SpecReviewAnnotationKind kind;
  char *text;         /* the paragraph's lines, verbatim */
  char *id;           /* a comment's id, a conflict's id; NULL without one */
  char *author;       /* a comment's author; NULL without one */
  char *comment_text; /* a comment's text; "" for the others */
  SomStrList question_ids; /* a question block's question ids */
  char *changed_at; /* a comment's change time (SOM §11.9.10); NULL without */
} SpecReviewPiece;

typedef struct {
  SpecReviewPiece *items;
  size_t len, cap;
} SpecReviewPieces;

/* The paragraphs of `value` (SOM §11.9.1), each classified. */
void spec_review_pieces(const char *value, SpecReviewPieces *out);
void spec_review_pieces_free(SpecReviewPieces *p);

/* One inline mark of a value, with what its decisions leave. Offsets are byte
 * offsets into the value. */
typedef struct {
  size_t start;
  size_t end;      /* after the attribution token when there is one */
  size_t body_end; /* right after the mark itself */
  SpecMarkKind kind;
  char *markup; /* the mark as written, its token included */
  SomStrList authors;
  SpecMarkVote *votes;
  size_t votes_len;
  char *accepted; /* the text accepting it leaves */
  char *rejected; /* the text rejecting it leaves */
  char *changed_at; /* its token's change time (SOM §11.9.10); NULL without */
} SpecReviewMark;

typedef struct {
  SpecReviewMark *items;
  size_t len, cap;
} SpecReviewMarks;

/* The inline marks of `value`, in order (marks in code are not marks). */
void spec_review_marks(const char *value, SpecReviewMarks *out);
void spec_review_marks_free(SpecReviewMarks *m);

/* `value` with the marks `decisions` names accepted or rejected, by the
 * whitespace rules of SOM §11.9.3: `decisions[k]` is 1 (accept), 0 (reject)
 * or -1 (leave) for mark `k` of `spec_review_marks`, `len` entries. */
char *spec_review_decide_marks_text(const char *value, const int *decisions,
                                    size_t len);

/* `value` with mark `m`'s token replaced by one for `authors`, `votes` and the
 * mark's own change time, `{@agent +alice -bob 2026-11-07T14:05+01:00}`; the
 * token is left out when there is nothing to write. */
char *spec_review_with_attribution(const char *value, const SpecReviewMark *m,
                                   const SomStrList *authors,
                                   const SpecMarkVote *votes, size_t votes_len);

/* The team answer of every question of `value`, in order: `ids[k]` answered
 * `answers[k]` (the first of a repeated id wins). Both lists initialised by
 * the callee. */
void spec_review_team_answers(const char *value, SomStrList *ids,
                              SomStrList *answers);

/* The time of every question's team answer in `value` (SOM §11.9.10), in
 * order: `ids[k]`'s team answer was written at `times[k]`, NULL for an answer
 * written without one (the first of a repeated id wins). `ids` is initialised
 * by the callee; `*times` (length `ids->len`) and its strings are owned by
 * the caller — free with `spec_review_team_answer_times_free`. */
void spec_review_team_answer_times(const char *value, SomStrList *ids,
                                   char ***times);

/* Frees the `times` of `spec_review_team_answer_times` (`n` entries). */
void spec_review_team_answer_times_free(char **times, size_t n);

/* `value` with `member`'s individual answer to question `question_id` set, as
 * `spec_review_annotations_set_member_answer` does, with the change time
 * `changed_at` (NULL: none); NULL when the value holds no such question. */
char *spec_review_set_individual_answer_text(const char *value,
                                             const char *question_id,
                                             const char *member,
                                             const char *answer,
                                             const char *changed_at);

/* Carries the edits `x` → `y` over to `b`, a text equal to `x` except where
 * marks of `b` were decided in `x` (SOM §11.9.9, step 3): every edit lands in
 * `b` at the place `x` and `b` agree on. NULL when an edit touches or borders
 * a place where they differ — the edit overlaps a decided mark. Both diffs are
 * the token diffs of `spec_mark_change_text`. */
char *spec_review_transplant_edits(const char *x, const char *y, const char *b);

#endif /* SPEC_REVIEW_ANNOTATIONS_H */
