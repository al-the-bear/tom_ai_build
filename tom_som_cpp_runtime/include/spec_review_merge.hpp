/* spec_review_merge — merging the reviewed copies of a team review (SOM
 * §11.9.9) into one document in the team notation of §11.9.8: who proposed,
 * voted for and answered what, and where two members changed the same passage
 * differently. An idiomatic-C++ port of the TypeScript `spec_review_merge.ts`.
 *
 * `mergeReviews` merges a SOM document (`SpecDocument`, by model path, list
 * items matched by section id) or a plain annotated Markdown file (by heading
 * path). Both share one engine that works value by value; only the way values
 * are found, and the SOM-only structure and revision entry, differ.
 *
 * The engine is built on the review-annotation building blocks: the paragraph
 * split and the mark decisions of `spec_review_annotations`, `markChangeText`
 * for edits written as plain text, the individual-answer rules of `setAnswer`,
 * and the list-item id generation of `specGenerateListItemSectionId`.
 */
#ifndef SPEC_REVIEW_MERGE_HPP
#define SPEC_REVIEW_MERGE_HPP

#include <exception>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"
#include "spec_review_annotations.hpp"

namespace som {

/* A member of a review team (SOM §11.9.8). */
struct SpecReviewMember {
  std::string memberId;  // lowercase letters, digits and `_`
  std::string displayName;
  std::string role;
};

/* One returned copy of a SOM document: its reviewer and the copy. */
struct SpecReviewedDocument {
  SpecReviewMember member;
  SpecDocument document;
};

/* One returned copy of a plain Markdown file: its reviewer and the copy. */
struct SpecReviewedMarkdown {
  SpecReviewMember member;
  std::string document;
};

/* The options of `mergeReviews`. */
struct SpecReviewMergeOptions {
  /* The members the round started with, in team order; a copy of anybody
   * else is a guest's. */
  std::vector<SpecReviewMember> team;
  /* The round's date (ISO 8601): the revision entry's date, and the date of
   * every generated list-item id. */
  std::string date;
  /* The revision entry's author. */
  std::string author;
  /* The id prefix of the questions the merge writes. */
  std::string questionPrefix = "RQ";
};

/* Thrown when a copy's structure does not fit the base; nothing is merged. */
class SpecReviewMergeError : public std::exception {
 public:
  explicit SpecReviewMergeError(std::string message)
      : message_(std::move(message)) {}
  const std::string& message() const { return message_; }
  const char* what() const noexcept override { return message_.c_str(); }

 private:
  std::string message_;
};

/* A reviewer as the report lists it. */
struct SpecMergeReviewer {
  SpecReviewMember member;
  bool guest = false;
};

/* A conflict block the merge wrote. */
struct SpecMergeConflict {
  std::string id;
  std::string path;
  std::optional<std::string> field;
  /* The unit's index among the value's text paragraphs; nullopt for a whole
   * value or a structural conflict. */
  std::optional<std::size_t> paragraph;
  std::vector<std::string> members;
};

/* A base mark left with votes. */
struct SpecMergeVotes {
  std::string path;
  std::optional<std::string> field;
  std::string markup;  // the mark as merged, its token carrying the votes
  std::vector<SpecMarkVote> votes;
};

/* A base mark every copy decided the same way, applied or dropped. */
struct SpecMergeUnanimous {
  std::string path;
  std::optional<std::string> field;
  std::string markup;  // the mark as the base wrote it
  bool accept = true;  // the decision: accept, or reject
  std::string result;
};

/* A base question the copies answered. */
struct SpecMergeAnswers {
  std::string questionId;
  std::vector<std::string> members;
};

/* A new comment. */
struct SpecMergeComment {
  std::string id;
  std::string author;
  std::string path;
  std::optional<std::string> field;
};

/* An item a copy added. */
struct SpecMergeAddition {
  std::string path;
  std::vector<std::string> members;
};

/* The question proposing a guest for the next round's team. */
struct SpecMergeGuestQuestion {
  std::string id;
  std::string memberId;
  /* Where it was written; nullopt when the document has no place for it. */
  std::optional<std::string> path;
};

/* The draft revision entry the merge appended. */
struct SpecMergeRevision {
  std::string path;
  std::string version;
};

/* The merge report (SOM §11.9.9), every list in merged document order. */
struct SpecReviewMergeReport {
  std::vector<SpecMergeReviewer> reviewers;
  std::vector<SpecMergeConflict> conflicts;
  std::vector<SpecMergeVotes> votes;
  std::vector<SpecMergeUnanimous> unanimous;
  std::vector<SpecMergeAnswers> answers;
  std::vector<SpecMergeComment> comments;
  std::vector<SpecMergeAddition> additions;
  std::vector<SpecMergeGuestQuestion> guestQuestions;
  std::optional<SpecMergeRevision> revision;

  /* The canonical JSON form the conformance corpus pins. */
  std::string toJson() const;
};

/* The merged document and its report. */
template <class D>
struct SpecReviewMergeResult {
  D merged;
  SpecReviewMergeReport report;
};

/* Merges the reviewed `copies` of the SOM document `base` (SOM §11.9.9) by
 * the paths of `model`. Neither the base nor a copy is written. A copy whose
 * structure does not fit the base — a path `model` does not resolve — is
 * refused with SpecReviewMergeError. */
SpecReviewMergeResult<SpecDocument> mergeReviews(
    const SpecModel& model, const SpecDocument& base,
    const std::vector<SpecReviewedDocument>& copies,
    const SpecReviewMergeOptions& options);

/* Merges the reviewed `copies` of the plain annotated Markdown file `base` by
 * heading path. A copy whose heading sequence differs from the base's is
 * refused with SpecReviewMergeError. */
SpecReviewMergeResult<std::string> mergeReviews(
    const std::string& base, const std::vector<SpecReviewedMarkdown>& copies,
    const SpecReviewMergeOptions& options);

}  // namespace som

#endif  // SPEC_REVIEW_MERGE_HPP
