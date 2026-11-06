/* spec_review_merge — merging the reviewed copies of a team review (SOM
 * §11.9.9) into one document in the team notation of §11.9.8: who proposed,
 * voted for and answered what, and where two members changed the same passage
 * differently. A port of the TypeScript `spec_review_merge.ts`.
 *
 * `spec_review_merge_documents` merges a SOM document (by model path, list
 * items matched by section id), `spec_review_merge_markdown` a plain annotated
 * Markdown file (by heading path). Both share one engine that works value by
 * value; only the way values are found, and the SOM-only structure and
 * revision entry, differ.
 *
 * The engine is built on the review-annotation building blocks: the paragraph
 * split and the mark decisions of `spec_review_annotations`,
 * `spec_mark_change_text` for edits written as plain text, the
 * individual-answer rules of `spec_review_annotations_set_member_answer`, and
 * the list-item id generation of `spec_generate_list_item_section_id`.
 *
 * Error idiom: a copy that does not fit the base returns 0 (or NULL), writes
 * nothing, and fills `*err` (when non-NULL) with an owned message.
 *
 * Ownership: every input is borrowed; neither the base nor a copy is written.
 * The merged document and the report are owned by the caller and released as
 * documented below.
 */
#ifndef SPEC_REVIEW_MERGE_H
#define SPEC_REVIEW_MERGE_H

#include <stddef.h>

#include "som_util.h"
#include "spec_document.h"
#include "spec_model.h"
#include "spec_review_annotations.h"

/* A member of a review team (SOM §11.9.8). Borrowed strings. */
typedef struct {
  const char *member_id; /* lowercase letters, digits and `_` */
  const char *display_name;
  const char *role;
} SpecReviewMember;

/* One returned copy of a SOM document: its reviewer and the copy. */
typedef struct {
  SpecReviewMember member;
  const SpecDocument *document; /* borrowed */
} SpecReviewedDocument;

/* One returned copy of a plain Markdown file: its reviewer and the copy. */
typedef struct {
  SpecReviewMember member;
  const char *document; /* borrowed */
} SpecReviewedMarkdown;

/* The options of a merge. Borrowed. */
typedef struct {
  /* The members the round started with, in team order; a copy of anybody else
   * is a guest's. */
  const SpecReviewMember *team;
  size_t team_len;
  /* The round's date (ISO 8601): the revision entry's date, and the date of
   * every generated list-item id. */
  const char *date;
  /* The revision entry's author. */
  const char *author;
  /* The id prefix of the questions the merge writes; NULL for `RQ`. */
  const char *question_prefix;
} SpecReviewMergeOptions;

/* Raised when a copy's structure does not fit the base; nothing is merged.
 * Initialise with `spec_review_merge_error_init`, release with
 * `spec_review_merge_error_free`. */
typedef struct {
  char *message; /* owned; NULL while no error was raised */
} SpecReviewMergeError;

void spec_review_merge_error_init(SpecReviewMergeError *err);
void spec_review_merge_error_free(SpecReviewMergeError *err);

/* ---- the report ----------------------------------------------------------
 * Every string is owned; a `field` is NULL for content. */

/* A reviewer as the report lists it. */
typedef struct {
  char *member_id;
  char *display_name;
  char *role;
  int guest;
} SpecMergeReviewer;

/* A conflict block the merge wrote. */
typedef struct {
  char *id;
  char *path;
  char *field;
  /* The unit's index among the value's text paragraphs; -1 for a whole value
   * or a structural conflict. */
  long long paragraph;
  SomStrList members;
} SpecMergeConflict;

/* A base mark left with votes. */
typedef struct {
  char *path;
  char *field;
  char *markup; /* the mark as merged, its token carrying the votes */
  SpecMarkVote *votes;
  size_t votes_len;
} SpecMergeVotes;

/* A base mark every copy decided the same way, applied or dropped. */
typedef struct {
  char *path;
  char *field;
  char *markup; /* the mark as the base wrote it */
  int accept;   /* the decision: accept (1) or reject (0) */
  char *result;
} SpecMergeUnanimous;

/* A base question the copies answered. */
typedef struct {
  char *question_id;
  SomStrList members;
} SpecMergeAnswers;

/* A new comment. */
typedef struct {
  char *id;
  char *author;
  char *path;
  char *field;
} SpecMergeComment;

/* An item a copy added. */
typedef struct {
  char *path;
  SomStrList members;
} SpecMergeAddition;

/* The question proposing a guest for the next round's team. */
typedef struct {
  char *id;
  char *member_id;
  char *path; /* where it was written; NULL when the document has no place */
} SpecMergeGuestQuestion;

/* The merge report (SOM §11.9.9), every list in merged document order.
 * Initialise with `spec_review_merge_report_init`, release with
 * `spec_review_merge_report_free`. */
typedef struct {
  SpecMergeReviewer *reviewers;
  size_t reviewers_len, reviewers_cap;
  SpecMergeConflict *conflicts;
  size_t conflicts_len, conflicts_cap;
  SpecMergeVotes *votes;
  size_t votes_len, votes_cap;
  SpecMergeUnanimous *unanimous;
  size_t unanimous_len, unanimous_cap;
  SpecMergeAnswers *answers;
  size_t answers_len, answers_cap;
  SpecMergeComment *comments;
  size_t comments_len, comments_cap;
  SpecMergeAddition *additions;
  size_t additions_len, additions_cap;
  SpecMergeGuestQuestion *guest_questions;
  size_t guest_questions_len, guest_questions_cap;
  /* The draft revision entry the merge appended (`revision_path` NULL when
   * none). */
  char *revision_path;
  char *revision_version;
} SpecReviewMergeReport;

void spec_review_merge_report_init(SpecReviewMergeReport *r);
void spec_review_merge_report_free(SpecReviewMergeReport *r);
/* The canonical JSON form the conformance corpus pins. Owned. */
char *spec_review_merge_report_to_json(const SpecReviewMergeReport *r);

/* ---- merging --------------------------------------------------------------
 */

/* Merges the reviewed `copies` of the SOM document `base` (SOM §11.9.9) by the
 * paths of `model` into `*merged` (initialised by the callee in every case;
 * release with `spec_document_free`) and `*report` (likewise; release with
 * `spec_review_merge_report_free`). Returns 1, or 0 (filling `*err`, both
 * outputs left empty) when a copy's structure does not fit the base — a path
 * `model` does not resolve. */
int spec_review_merge_documents(
    const SpecModel *model, const SpecDocument *base,
    const SpecReviewedDocument *copies, size_t copies_len,
    const SpecReviewMergeOptions *options, SpecDocument *merged,
    SpecReviewMergeReport *report, SpecReviewMergeError *err);

/* Merges the reviewed `copies` of the plain annotated Markdown file `base` by
 * heading path. Returns the merged text (owned) and fills `*report`
 * (initialised by the callee in every case); NULL (filling `*err`) when a
 * copy's heading sequence differs from the base's. */
char *spec_review_merge_markdown(const char *base,
                                 const SpecReviewedMarkdown *copies,
                                 size_t copies_len,
                                 const SpecReviewMergeOptions *options,
                                 SpecReviewMergeReport *report,
                                 SpecReviewMergeError *err);

#endif /* SPEC_REVIEW_MERGE_H */
