/* spec_review_annotations — review annotations in content values (SOM §11.9):
 * comment blocks, question blocks and CriticMarkup inline marks. A faithful
 * port of the Dart `spec_review_annotations.dart`.
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
 * Ownership: `SpecReviewAnnotations` borrows its document and qualifier; both
 * must outlive it, and it owns nothing. Every listed annotation, list, id and
 * string returned is owned by the caller and released as documented below.
 */
#ifndef SPEC_REVIEW_ANNOTATIONS_H
#define SPEC_REVIEW_ANNOTATIONS_H

#include <stddef.h>

#include "som_util.h"
#include "spec_document.h"
#include "spec_validator.h"

/* The three kinds of annotation (SOM §11.9). */
typedef enum {
  /* A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`. */
  SPEC_REVIEW_ANNOTATION_COMMENT = 0,
  /* One question of a question block, `> **❓ BQ-81 — topic:** …`. */
  SPEC_REVIEW_ANNOTATION_QUESTION = 1,
  /* A CriticMarkup inline mark. */
  SPEC_REVIEW_ANNOTATION_MARK = 2,
} SpecReviewAnnotationKind;

/* The kind's wire name (`"comment"`, `"question"`, `"mark"`); static. */
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
  /* The comment id (`C-12`) or question id (`BQ-81`); NULL for a comment
   * without an id and for a mark. */
  char *id;
  /* A comment's id with the document qualifier in front (`SBP C-12`), when the
   * listing was given a qualifier and the comment has an id; else NULL. */
  char *qualified_id;
  /* A comment's author; NULL when none is written. */
  char *author;
  /* A comment's text, a question's text (options included), or a mark's text
   * (a substitution's old text; empty for a comment mark). Never NULL. */
  char *text;
  /* A comment's context: the paragraph before the block, verbatim (empty at
   * the start of the value). Never NULL. */
  char *context;
  /* A question's topic (in a combined block: the field it asks about); NULL
   * for the other kinds. */
  char *topic;
  /* Whether a question carries `★` before its topic. */
  int starred;
  /* Whether a question is part of a combined block. */
  int combined;
  /* A question's answer, trimmed; empty when open. Never NULL. */
  char *answer;
  /* A mark's kind (meaningful for SPEC_REVIEW_ANNOTATION_MARK only). */
  SpecMarkKind mark_kind;
  /* A substitution's new text; else NULL. */
  char *new_text;
  /* The comment of a comment mark, or of a highlight followed by one; else
   * NULL. */
  char *comment;
} SpecReviewAnnotation;

void spec_review_annotation_free(SpecReviewAnnotation *a);

/* Whether a question is still open (no answer written). */
int spec_review_annotation_is_open(const SpecReviewAnnotation *a);

/* The canonical JSON form the conformance corpus pins (every key written,
 * `null` explicitly). Owned result. */
char *spec_review_annotation_to_json(const SpecReviewAnnotation *a);

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
} SpecReviewAnnotationCounts;

/* `{questions, openQuestions, answeredQuestions, comments, marks}`. Owned. */
char *spec_review_annotation_counts_to_json(const SpecReviewAnnotationCounts *c);

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
} SpecQuestionDraft;

/* Raised by an operation that names an annotation, value or paragraph that
 * does not exist. Initialise with `spec_review_annotation_error_init`, release
 * with `spec_review_annotation_error_free`. */
typedef struct {
  char *message; /* owned; NULL while no error was raised */
} SpecReviewAnnotationError;

void spec_review_annotation_error_init(SpecReviewAnnotationError *err);
void spec_review_annotation_error_free(SpecReviewAnnotationError *err);

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

/* One inline mark as `spec_review_annotations_list_marks` reports it. Every
 * string is owned; `field` and `comment` may be NULL. */
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
  char *markup;         /* the mark as written */
  char *context;        /* the paragraph holding the mark, verbatim */
} SpecMarkEntry;

void spec_mark_entry_free(SpecMarkEntry *e);
/* The canonical JSON form the conformance corpus pins. Owned. */
char *spec_mark_entry_to_json(const SpecMarkEntry *e);

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

/* The report of a mark operation, for the decision log. Initialise with
 * `spec_mark_report_init`, release with `spec_mark_report_free`. */
typedef struct {
  SpecMarkOutcome *applied; /* what was done, in document order */
  size_t applied_len, applied_cap;
  SpecMarkIssue *malformed; /* malformed marks in scope, left as written */
  size_t malformed_len, malformed_cap;
} SpecMarkReport;

void spec_mark_report_init(SpecMarkReport *r);
void spec_mark_report_free(SpecMarkReport *r);
/* `{applied: [...], malformed: [...]}`. Owned. */
char *spec_mark_report_to_json(const SpecMarkReport *r);

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

/* The lines of a comment block (`author` NULL or "" for none), written into
 * `out` (initialised by the callee). */
void spec_format_comment_block(const char *id, const char *text,
                               const char *author, SomStrList *out);

/* The lines of a question block, written into `out` (initialised by the
 * callee). */
void spec_format_question_block(const SpecQuestionDraft *q, SomStrList *out);

/* `value` without any comment block, question block or inline mark (every
 * mark accepted). Plain quotes and code stay. Owned result. */
char *spec_strip_annotations_text(const char *value);

/* ---- document level ----------------------------------------------------- */

/* The annotations of a document, and the operations that edit them. */
typedef struct {
  SpecDocument *doc; /* borrowed */
  /* The document's id or name, written in front of a comment id cited
   * outside the document (`SBP` → `SBP C-12`); NULL for bare ids. Borrowed. */
  const char *qualifier;
} SpecReviewAnnotations;

/* Wraps `doc`. */
SpecReviewAnnotations spec_review_annotations_make(SpecDocument *doc,
                                                   const char *qualifier);

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

/* Inserts a comment block after paragraph `after_paragraph` (0-based; -1: at
 * the start) of the value at `path` / `field` (NULL: content), and returns its
 * id (owned) — `id` when non-NULL, else the next free one. `author` may be
 * NULL. Returns NULL (filling `*err`) when the paragraph does not exist. */
char *spec_review_annotations_insert_comment(const SpecReviewAnnotations *r,
                                             const char *path,
                                             const char *field,
                                             long long after_paragraph,
                                             const char *text,
                                             const char *author,
                                             const char *id,
                                             SpecReviewAnnotationError *err);

/* Inserts a question block after paragraph `after_paragraph` (0-based; -1: at
 * the start) of the value at `path` / `field`. Returns 1, or 0 (filling
 * `*err`) when the paragraph does not exist. */
int spec_review_annotations_insert_question(const SpecReviewAnnotations *r,
                                            const char *path,
                                            const char *field,
                                            long long after_paragraph,
                                            const SpecQuestionDraft *question,
                                            SpecReviewAnnotationError *err);

/* Inserts a question block directly after the comment `comment_id`. */
int spec_review_annotations_insert_question_after_comment(
    const SpecReviewAnnotations *r, const char *comment_id,
    const SpecQuestionDraft *question, SpecReviewAnnotationError *err);

/* Writes `answer` after the question's `**Answer:**` (empty: reopens it). */
int spec_review_annotations_set_answer(const SpecReviewAnnotations *r,
                                       const char *question_id,
                                       const char *answer,
                                       SpecReviewAnnotationError *err);

/* Replaces a comment's text; its marker, id and author stay as written. */
int spec_review_annotations_edit_comment(const SpecReviewAnnotations *r,
                                         const char *comment_id,
                                         const char *text,
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

/* Accepts every inline mark under `path` (NULL: the whole document). */
void spec_review_annotations_accept_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out);

/* Rejects every inline mark under `path` (NULL: the whole document). */
void spec_review_annotations_reject_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out);

/* Removes every annotation and writes the result back: every inline mark
 * accepted, every comment and question block removed. Malformed marks stay
 * and are reported. `out` holds the accept report. */
void spec_review_annotations_remove_all_annotations(
    const SpecReviewAnnotations *r, SpecMarkReport *out);

/* Writes `text` at `path` / `field` (NULL: content) as a marked change
 * against the value there now. A value that already holds change marks is
 * compared from its original — every mark rejected — so a second edit of the
 * same passage updates its mark instead of nesting one. */
SpecMarkedChange spec_review_annotations_set_marked(
    const SpecReviewAnnotations *r, const char *path, const char *field,
    const char *text);

/* Marks the value at `path` / `field` as a change against `earlier`, an
 * earlier version of it, and writes the result. */
SpecMarkedChange spec_review_annotations_mark_against(
    const SpecReviewAnnotations *r, const char *path, const char *field,
    const char *earlier);

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

#endif /* SPEC_REVIEW_ANNOTATIONS_H */
