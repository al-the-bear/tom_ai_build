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
#include <functional>
#include <map>
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

/* One paragraph of a value (SOM §11.9.1, "Paragraphs"): a run of non-blank
 * lines, where a blank line inside fenced code does not end the run. Its
 * `index` is what `afterParagraph` of the inserts takes. */
struct SpecParagraph {
  std::size_t index = 0;      // the 0-based position among the value's paragraphs
  std::size_t startLine = 0;  // the 0-based first line within the value
  std::size_t endLine = 0;    // the 0-based last line within the value (inclusive)
  std::string text;           // the paragraph's lines, verbatim, joined with `\n`
  /* `comment` or `question` when the paragraph opens with an annotation block
   * of that kind, else nullopt. */
  std::optional<std::string> annotation;

  /* The canonical JSON form the conformance corpus pins. */
  std::string toJson() const;
};

/* One option of a question (SOM §11.9.2): `- (a) text`, or `- **(b)** text`
 * for the recommended one. */
struct SpecQuestionOption {
  std::string letter;  // the lowercase letter
  std::string text;    // the option's text, continuation lines joined with one space
  bool bold = false;   // whether the option is written bold — the recommended one

  /* `{letter, text, bold}`. */
  std::string toJson() const;
};

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
  /* A question's options, in order (empty when it states none). */
  std::vector<SpecQuestionOption> options;
  /* A question's recommended letter: the bold option, else the option that
   * says "recommended", else the letter of a `*Recommendation:*` line. */
  std::optional<std::string> recommended;
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

  /* The letter an answer starts with (`(b)` or `**(b)**`); nullopt for none
   * and for the other kinds. */
  std::optional<std::string> answerLetter() const;

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
  /* The recommended option's letter; that option is written bold. */
  std::optional<std::string> recommended;
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

/* ---- inline-mark review (SOM §11.9.3) ------------------------------------ */

/* What to do with one inline mark. */
enum class SpecMarkDecision {
  Accept,  // take the change: an insertion's text, nothing for a deletion,
           // a substitution's new text
  Reject,  // undo the change: nothing for an insertion, a deletion's text,
           // a substitution's old text
  Leave,   // keep the mark as written
};

/* The decision's wire name: `"accept"`, `"reject"`, `"leave"`. */
const char* specMarkDecisionName(SpecMarkDecision d);

/* The decision named `name`; nullopt when unknown. */
std::optional<SpecMarkDecision> specMarkDecisionFromName(const std::string& name);

/* One inline mark as `listMarks` reports it. */
struct SpecMarkEntry {
  /* `M-<n>`: the mark's 1-based position among all marks of the document, in
   * document order. Stable for one `SpecReviewAnnotations::revision()`. */
  std::string id;
  std::string path;
  std::optional<std::string> field;  // nullopt for content
  std::size_t line = 0;  // 0-based line within the value where it opens
  SpecMarkKind markKind = SpecMarkKind::Comment;
  std::string oldText;  // the text after rejecting the mark
  std::string newText;  // the text after accepting the mark
  std::optional<std::string> comment;  // a comment mark's comment
  std::string markup;   // the mark as written
  std::string context;  // the paragraph holding the mark, verbatim

  /* The canonical JSON form the conformance corpus pins. */
  std::string toJson() const;
};

/* What was done to one mark. */
struct SpecMarkOutcome {
  std::string id;  // the mark's id at the revision the operation ran on
  std::string path;
  std::optional<std::string> field;
  std::size_t line = 0;
  SpecMarkKind markKind = SpecMarkKind::Comment;
  SpecMarkDecision decision = SpecMarkDecision::Accept;  // accept or reject
  std::string markup;  // the mark as written
  std::string result;  // the text that replaced it

  std::string toJson() const;
};

/* A mark the scanner could not read; it is left as written. */
struct SpecMarkIssue {
  std::string path;
  std::optional<std::string> field;
  std::size_t line = 0;
  std::string issue;  // `unclosed`, `nested` or `noArrow`

  std::string toJson() const;
};

/* The report of a mark operation, for the decision log. */
struct SpecMarkReport {
  std::vector<SpecMarkOutcome> applied;  // what was done, in document order
  std::vector<SpecMarkIssue> malformed;  // malformed marks in scope

  /* `{applied: [...], malformed: [...]}`. */
  std::string toJson() const;
};

/* ---- text level: one value ---------------------------------------------- */

/* `value` with every inline mark accepted (`accept`) or rejected, and every
 * highlight and comment mark removed. Marks in code and malformed marks stay
 * as written. */
std::string applyInlineMarksText(const std::string& value, bool accept);

/* ---- writing changes as inline marks (SOM §11.9.3) ---------------------- */

/* A value written as a marked change. */
struct SpecMarkedChange {
  /* The value with every difference marked. */
  std::string text;
  /* Whether accepting the marks gives exactly the new value and rejecting
   * them exactly the old one. False when a difference cannot be marked — a
   * change inside fenced code, or text that holds mark delimiters — and the
   * new value was written unmarked instead. */
  bool exact = true;

  /* `{text, exact}`. */
  std::string toJson() const;
};

/* `newValue` with its differences from `oldValue` marked, so that accepting
 * every mark gives exactly `newValue` and rejecting every mark exactly
 * `oldValue`. The diff runs by line, then by word inside a changed run of
 * lines; words are never split, changes separated by at most two unchanged
 * words are one mark, and nothing inside code is marked. */
SpecMarkedChange markChangeText(const std::string& oldValue,
                                const std::string& newValue);

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

  /* The paragraphs of the value at `path` / `field`, in order — the units
   * `afterParagraph` of `insertComment` and `insertQuestion` counts. Throws
   * `SpecReviewAnnotationError` when the document holds no such value. */
  std::vector<SpecParagraph> paragraphs(
      const std::string& path,
      const std::optional<std::string>& field = std::nullopt) const;

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

  /* The revision the mark ids are stable for: FNV-1a 64-bit over the UTF-8
   * of every value in document order (path, NUL, field or empty, NUL, text,
   * NUL), as 16 lower-case hex digits. */
  std::string revision() const;

  /* Every inline mark of the document, or of the subtree at `path`, in
   * document order. */
  std::vector<SpecMarkEntry> listMarks(
      const std::optional<std::string>& path = std::nullopt) const;

  /* Applies one decision per named mark in one write. Throws
   * `SpecReviewAnnotationError` — nothing changes — when the document is no
   * longer at `revision`, or when a decision names a mark that does not
   * exist. Marks not named, and marks decided `Leave`, stay. */
  SpecMarkReport decideMarks(
      const std::map<std::string, SpecMarkDecision>& decisions,
      const std::string& revision);

  /* Accepts every inline mark under `path` (nullopt: the whole document). */
  SpecMarkReport acceptAllMarks(
      const std::optional<std::string>& path = std::nullopt);

  /* Rejects every inline mark under `path` (nullopt: the whole document). */
  SpecMarkReport rejectAllMarks(
      const std::optional<std::string>& path = std::nullopt);

  /* Removes every annotation and writes the result back: every inline mark
   * accepted, every comment and question block removed. Malformed marks stay
   * and are reported. Returns the accept report. */
  SpecMarkReport removeAllAnnotations();

  /* Writes `text` at `path` / `field` as a marked change against the value
   * there now. A value that already holds change marks is compared from its
   * original — every mark rejected — so a second edit of the same passage
   * updates its mark instead of nesting one. */
  SpecMarkedChange setMarked(const std::string& path,
                             const std::optional<std::string>& field,
                             const std::string& text);

  /* Marks the value at `path` / `field` as a change against `earlier`, an
   * earlier version of it, and writes the result. */
  SpecMarkedChange markAgainst(const std::string& path,
                               const std::optional<std::string>& field,
                               const std::string& earlier);

  /* A copy of the document without any annotation, for reading. The document
   * itself is unchanged. */
  SpecDocument stripped() const;

  /* The instance-tier findings on annotations (SOM §11.9.5), ordered by path
   * (= `validateReviewAnnotations(doc())`). */
  std::vector<SpecValidationError> validate() const;

 private:
  SpecMarkReport applyMarks(
      const std::function<std::optional<SpecMarkDecision>(const std::string&)>&
          decide,
      const std::optional<std::string>& under);

  SpecDocument* doc_;
  std::optional<std::string> qualifier_;
};

}  // namespace som

#endif  // SPEC_REVIEW_ANNOTATIONS_HPP
