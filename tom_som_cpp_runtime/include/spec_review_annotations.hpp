/* spec_review_annotations — review annotations in content values (SOM §11.9):
 * comment blocks, question blocks and CriticMarkup inline marks. An
 * idiomatic-C++ port of the Dart `spec_review_annotations.dart`.
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
 */
#ifndef SPEC_REVIEW_ANNOTATIONS_HPP
#define SPEC_REVIEW_ANNOTATIONS_HPP

#include <cstddef>
#include <exception>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "spec_document.hpp"
#include "spec_validator.hpp"

namespace som {

/* The three kinds of annotation (SOM §11.9). */
enum class SpecReviewAnnotationKind {
  Comment,   // a reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`
  Question,  // one question of a question block, `> **❓ BQ-81 — topic:** …`
  Mark,      // a CriticMarkup inline mark
};

/* The kind's wire name: `"comment"`, `"question"`, `"mark"`. */
const char* specReviewAnnotationKindName(SpecReviewAnnotationKind kind);

/* The five CriticMarkup inline marks (SOM §11.9.3). */
enum class SpecMarkKind {
  Comment,       // `{>> comment <<}`
  Highlight,     // `{== text ==}`, optionally followed by `{>> comment <<}`
  Insertion,     // `{++ added ++}`
  Deletion,      // `{-- removed --}`
  Substitution,  // `{~~ old ~> new ~~}`
};

/* The mark kind's wire name: `"comment"`, `"highlight"`, `"insertion"`,
 * `"deletion"`, `"substitution"`. */
const char* specMarkKindName(SpecMarkKind kind);

/* One annotation, located by the value that holds it. `std::nullopt` stands
 * for the Dart `null`. */
struct SpecReviewAnnotation {
  SpecReviewAnnotationKind kind = SpecReviewAnnotationKind::Comment;
  /* The document path of the value: a content path, or a form path when
   * `field` is set. */
  std::string path;
  /* The form field whose value holds the annotation; nullopt for content. */
  std::optional<std::string> field;
  /* The 0-based line within the value where the annotation starts (a
   * question: its header line). */
  std::size_t line = 0;
  /* The comment id (`C-12`) or question id (`BQ-81`); nullopt for a comment
   * without an id and for a mark. */
  std::optional<std::string> id;
  /* A comment's id with the document qualifier in front (`SBP C-12`), when the
   * listing was given a qualifier and the comment has an id. */
  std::optional<std::string> qualifiedId;
  /* A comment's author; nullopt when none is written. */
  std::optional<std::string> author;
  /* A comment's text, a question's text (options included), or a mark's text
   * (a substitution's old text; empty for a comment mark). */
  std::string text;
  /* A comment's context: the paragraph before the block, verbatim (empty at
   * the start of the value). */
  std::string context;
  /* A question's topic (in a combined block: the field it asks about). */
  std::optional<std::string> topic;
  /* Whether a question carries `★` before its topic. */
  bool starred = false;
  /* Whether a question is part of a combined block. */
  bool combined = false;
  /* A question's answer, trimmed; empty when open. */
  std::string answer;
  /* A mark's kind. */
  std::optional<SpecMarkKind> markKind;
  /* A substitution's new text. */
  std::optional<std::string> newText;
  /* The comment of a comment mark, or of a highlight followed by one. */
  std::optional<std::string> comment;

  /* Whether a question is still open (no answer written). */
  bool open() const {
    return kind == SpecReviewAnnotationKind::Question && answer.empty();
  }

  /* The canonical JSON form the conformance corpus pins (every key written,
   * `null` explicitly). */
  std::string toJson() const;
};

/* The counts a report needs (SOM §11.9). */
struct SpecReviewAnnotationCounts {
  std::size_t questions = 0;          // every question
  std::size_t openQuestions = 0;      // questions without an answer
  std::size_t answeredQuestions = 0;  // questions with an answer
  std::size_t comments = 0;           // comment blocks
  std::size_t marks = 0;              // inline marks

  /* `{questions, openQuestions, answeredQuestions, comments, marks}`. */
  std::string toJson() const;
};

/* A question to insert (SOM §11.9.2). */
struct SpecQuestionDraft {
  std::string id;     // the question id (`BQ-90`)
  std::string topic;  // the topic
  std::string text;   // the question text; may span lines
  /* Option lines, written as `- <option>` (e.g. `(a) lower only`). */
  std::vector<std::string> options;
  std::string recommendation;  // empty for none
  std::string assumption;      // empty for none
  bool starred = false;        // whether the question carries `★`
};

/* Thrown when an operation names an annotation, value or paragraph that does
 * not exist. Nothing has changed when it is thrown. */
class SpecReviewAnnotationError : public std::exception {
 public:
  explicit SpecReviewAnnotationError(std::string message)
      : message_(std::move(message)) {}
  const std::string& message() const { return message_; }
  const char* what() const noexcept override { return message_.c_str(); }

 private:
  std::string message_;
};

/* ---- text level: one value ---------------------------------------------- */

/* The lines of a comment block (`author` nullopt or empty for none). */
std::vector<std::string> formatCommentBlock(
    const std::string& id, const std::string& text,
    const std::optional<std::string>& author = std::nullopt);

/* The lines of a question block. */
std::vector<std::string> formatQuestionBlock(const SpecQuestionDraft& q);

/* `value` without any comment block, question block or inline mark (every
 * mark accepted). Plain quotes and code stay. */
std::string stripAnnotationsText(const std::string& value);

/* The instance-tier findings on annotations (SOM §11.9.5) of `doc`, ordered by
 * path: `annotationMalformed`, `annotationMisplaced`, `duplicateAnnotationId`.
 * The group `validateDocument` reports last. */
std::vector<SpecValidationError> validateReviewAnnotations(
    const SpecDocument& doc);

/* ---- document level ----------------------------------------------------- */

/* The annotations of a document, and the operations that edit them. Borrows
 * the document, which must outlive it. */
class SpecReviewAnnotations {
 public:
  /* Wraps `doc`. `qualifier` is the document's id or name, written in front
   * of a comment id cited outside the document (`SBP` → `SBP C-12`). */
  explicit SpecReviewAnnotations(
      SpecDocument& doc, std::optional<std::string> qualifier = std::nullopt)
      : doc_(&doc), qualifier_(std::move(qualifier)) {}

  SpecDocument& doc() const { return *doc_; }
  const std::optional<std::string>& qualifier() const { return qualifier_; }

  /* Every annotation, in document order. */
  std::vector<SpecReviewAnnotation> list() const;

  /* The counts a report needs. */
  SpecReviewAnnotationCounts counts() const;

  /* The id the next comment gets: `C-<n>`, n = the highest number in the
   * document (or `floor`, when higher) plus one. Writes nothing. */
  std::string nextCommentId(long long floor = 0) const;

  /* Gives every comment without an id the next one, in document order, and
   * returns the ids assigned. Nothing else changes. */
  std::vector<std::string> assignCommentIds(long long floor = 0);

  /* Inserts a comment block after paragraph `afterParagraph` (0-based; -1: at
   * the start) of the value at `path` / `field`, and returns its id — `id`
   * when given, else the next free one. */
  std::string insertComment(const std::string& path,
                            const std::optional<std::string>& field,
                            long long afterParagraph, const std::string& text,
                            const std::optional<std::string>& author = std::nullopt,
                            const std::optional<std::string>& id = std::nullopt);

  /* Inserts a question block after paragraph `afterParagraph` (0-based; -1:
   * at the start) of the value at `path` / `field`. */
  void insertQuestion(const std::string& path,
                      const std::optional<std::string>& field,
                      long long afterParagraph,
                      const SpecQuestionDraft& question);

  /* Inserts a question block directly after the comment `commentId`. */
  void insertQuestionAfterComment(const std::string& commentId,
                                  const SpecQuestionDraft& question);

  /* Writes `answer` after the question's `**Answer:**` (empty: reopens it). */
  void setAnswer(const std::string& questionId, const std::string& answer);

  /* Replaces a comment's text; its marker, id and author stay as written. */
  void editComment(const std::string& commentId, const std::string& text);

  /* Removes one comment or question by id (a qualified comment id,
   * `SBP C-12`, is accepted). A question of a combined block takes only its
   * own lines; the block goes when its last question does. */
  void resolve(const std::string& id);

  /* Accepts (`accept`) or rejects the inline mark `index` (0-based among the
   * marks of the value at `path` / `field`). */
  void applyMark(const std::string& path,
                 const std::optional<std::string>& field, long long index,
                 bool accept = true);

  /* A copy of the document without any annotation, for reading. The document
   * itself is unchanged. */
  SpecDocument stripped() const;

  /* The instance-tier findings on annotations (SOM §11.9.5), ordered by path
   * (= `validateReviewAnnotations(doc())`). */
  std::vector<SpecValidationError> validate() const;

 private:
  SpecDocument* doc_;
  std::optional<std::string> qualifier_;
};

}  // namespace som

#endif  // SPEC_REVIEW_ANNOTATIONS_HPP
