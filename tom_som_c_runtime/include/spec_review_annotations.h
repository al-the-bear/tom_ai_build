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

/* ---- text level: one value ---------------------------------------------- */

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
