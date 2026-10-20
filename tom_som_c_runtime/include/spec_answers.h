/* spec_answers — the answers of a review round, extracted for a step folder
 * (SOM §11.9.7). A faithful port of the Dart `spec_answers.dart`.
 *
 * A step of the TomSpecs process starts by collecting what the reviewer wrote
 * into the document — answers to the agent's questions, comments, and
 * optionally the questions still open and the inline marks — into the step
 * folder's `answers.md`. The annotations stay in the document; this reads them
 * through `spec_review_annotations_list` and never writes.
 *
 * Ownership: every string of an entry and of an extract is owned by it;
 * release an extract with `spec_answer_extract_free`. Results returned as
 * `char *` are owned by the caller (`free`).
 */
#ifndef SPEC_ANSWERS_H
#define SPEC_ANSWERS_H

#include <stddef.h>

#include "spec_document.h"
#include "spec_model.h"
#include "spec_review_annotations.h"

/* What an extracted entry is. */
typedef enum {
  SPEC_ANSWER_ANSWERED = 0, /* a question with an answer */
  SPEC_ANSWER_OPEN = 1,     /* a question without an answer */
  SPEC_ANSWER_COMMENT = 2,  /* a comment block */
  SPEC_ANSWER_MARK = 3,     /* an inline mark */
} SpecAnswerKind;

/* The kind's wire name (`"answered"`, `"open"`, `"comment"`, `"mark"`);
 * static. */
const char *spec_answer_kind_name(SpecAnswerKind kind);

/* One extracted entry. Every string is owned; NULL stands for the Dart
 * `null`. */
typedef struct {
  SpecAnswerKind kind;
  /* The question or comment id (`BQ-81`, `C-12`), or `M-<n>` for a mark;
   * NULL for a comment without an id. */
  char *id;
  /* The section-id chain of the rendition heading the entry sits under
   * (`SBP > INSC > SYSUM`). Never NULL. */
  char *section;
  /* The 1-based line in the document's Markdown rendition. */
  size_t line;
  /* The document path of the value holding the entry. Never NULL. */
  char *path;
  /* The form field holding it; NULL for content. */
  char *field;
  /* A question's topic; else NULL. */
  char *topic;
  /* Whether a question is part of a combined form block. */
  int combined;
  /* A question's text, a comment's text, or a mark's markup. Never NULL. */
  char *text;
  /* A question's answer (empty when open). Never NULL. */
  char *answer;
  /* A comment's author; else NULL. */
  char *author;
  /* Whether `mark_kind` is set (a mark only). */
  int has_mark_kind;
  /* A mark's kind. */
  SpecMarkKind mark_kind;
  /* A mark's text when rejected / accepted; else NULL. */
  char *old_text;
  char *new_text;
  /* A mark's comment; else NULL. */
  char *comment;
} SpecAnswerEntry;

/* The canonical JSON form (every key written, `null` explicitly). Owned. */
char *spec_answer_entry_to_json(const SpecAnswerEntry *e);

/* The counts a step's closing item reports. */
typedef struct {
  size_t answered; /* questions with an answer */
  size_t open;     /* questions without one */
  size_t comments; /* comment blocks */
  size_t marks;    /* inline marks */
} SpecAnswerCounts;

/* `{answered, open, comments, marks}`. Owned. */
char *spec_answer_counts_to_json(const SpecAnswerCounts *c);

/* The extraction of one document. */
typedef struct {
  /* The document's label in `answers.md` (e.g. `tom_uam.sbp`). Owned. */
  char *label;
  /* The document root's section id (or type), written in front of a comment
   * id (`SBP C-12`). Owned. */
  char *qualifier;
  /* Every entry, in rendition order. */
  SpecAnswerEntry *entries;
  size_t entries_len;
} SpecAnswerExtract;

/* Releases an extract (leaves it empty). */
void spec_answer_extract_free(SpecAnswerExtract *x);

/* The counts over the extract's entries. */
SpecAnswerCounts spec_answer_extract_counts(const SpecAnswerExtract *x);

/* `{label, qualifier, entries, counts}`. Owned. */
char *spec_answer_extract_to_json(const SpecAnswerExtract *x);

/* Extracts the annotations of `doc` (or of the subtree at `path`; NULL: the
 * whole document) with their place in the document's Markdown rendition under
 * `model`, in rendition order (by line; entries on one line keep their
 * order). The root is the first model root the document holds values under,
 * else the first root. Returns 1 writing `*out`; on the rendition's failure
 * conditions returns 0 with `*out` empty and `*err` written when non-NULL. */
int spec_extract_answers(const SpecModel *model, SpecDocument *doc,
                         const char *label, const char *path,
                         SpecAnswerExtract *out, char **err);

/* What `answers.md` includes besides the answered questions and comments. */
typedef struct {
  int include_open;  /* list the questions still open */
  int include_marks; /* list the inline marks */
  const char *title; /* the file's title (borrowed); NULL: `Answers` */
} SpecAnswerRenderOptions;

/* The defaults: no open questions, no marks, title `Answers`. */
SpecAnswerRenderOptions spec_answer_render_options_default(void);

/* Renders `extracts` as a step folder's `answers.md`: deterministic, grouped
 * per document in the order given, entries in document order. `options` NULL
 * means the defaults. Owned result, ending in a single `\n`. */
char *spec_render_answers(const SpecAnswerExtract *extracts, size_t len,
                          const SpecAnswerRenderOptions *options);

#endif /* SPEC_ANSWERS_H */
