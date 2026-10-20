/* spec_answers — the answers of a review round, extracted for a step folder
 * (SOM §11.9.7). An idiomatic-C++ port of the Dart `spec_answers.dart`.
 *
 * A step of the TomSpecs process starts by collecting what the reviewer wrote
 * into the document — answers to the agent's questions, comments, and
 * optionally the questions still open and the inline marks — into the step
 * folder's `answers.md`. The annotations stay in the document; this reads them
 * through `SpecReviewAnnotations::list` and never writes.
 */
#ifndef SPEC_ANSWERS_HPP
#define SPEC_ANSWERS_HPP

#include <cstddef>
#include <optional>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"
#include "spec_review_annotations.hpp"

namespace som {

/* What an extracted entry is. */
enum class SpecAnswerKind {
  Answered,  // a question with an answer
  Open,      // a question without an answer
  Comment,   // a comment block
  Mark,      // an inline mark
};

/* The kind's wire name: `"answered"`, `"open"`, `"comment"`, `"mark"`. */
const char* specAnswerKindName(SpecAnswerKind kind);

/* One extracted entry. `std::nullopt` stands for the Dart `null`. */
struct SpecAnswerEntry {
  SpecAnswerKind kind = SpecAnswerKind::Answered;
  /* The question or comment id (`BQ-81`, `C-12`), or `M-<n>` for a mark;
   * nullopt for a comment without an id. */
  std::optional<std::string> id;
  /* The section-id chain of the rendition heading the entry sits under
   * (`SBP > INSC > SYSUM`). */
  std::string section;
  /* The 1-based line in the document's Markdown rendition. */
  std::size_t line = 0;
  /* The document path of the value holding the entry. */
  std::string path;
  /* The form field holding it; nullopt for content. */
  std::optional<std::string> field;
  /* A question's topic. */
  std::optional<std::string> topic;
  /* Whether a question is part of a combined form block. */
  bool combined = false;
  /* A question's text, a comment's text, or a mark's markup. */
  std::string text;
  /* A question's answer (empty when open). */
  std::string answer;
  /* A comment's author. */
  std::optional<std::string> author;
  /* A mark's kind. */
  std::optional<SpecMarkKind> markKind;
  /* A mark's text when rejected / accepted. */
  std::optional<std::string> oldText;
  std::optional<std::string> newText;
  /* A mark's comment. */
  std::optional<std::string> comment;

  /* The canonical JSON form (every key written, `null` explicitly). */
  std::string toJson() const;
};

/* The counts a step's closing item reports. */
struct SpecAnswerCounts {
  std::size_t answered = 0;  // questions with an answer
  std::size_t open = 0;      // questions without one
  std::size_t comments = 0;  // comment blocks
  std::size_t marks = 0;     // inline marks

  /* The sum of two counts. */
  SpecAnswerCounts operator+(const SpecAnswerCounts& o) const;

  /* `{answered, open, comments, marks}`. */
  std::string toJson() const;
};

/* The extraction of one document. */
struct SpecAnswerExtract {
  /* The document's label in `answers.md` (e.g. `tom_uam.sbp`). */
  std::string label;
  /* The document root's section id (or type), written in front of a comment
   * id (`SBP C-12`). */
  std::string qualifier;
  /* Every entry, in rendition order. */
  std::vector<SpecAnswerEntry> entries;

  /* The counts over `entries`. */
  SpecAnswerCounts counts() const;

  /* `{label, qualifier, entries, counts}`. */
  std::string toJson() const;
};

/* Extracts the annotations of `doc` (or of the subtree at `path`) with their
 * place in the document's Markdown rendition under `model`, in rendition order
 * (by line; entries on one line keep their order). The root is the first model
 * root the document holds values under, else the first root. Throws as
 * `markdownExportRootWithMap` does. */
SpecAnswerExtract extractAnswers(
    const SpecModel& model, SpecDocument& doc, const std::string& label,
    const std::optional<std::string>& path = std::nullopt);

/* What `answers.md` includes besides the answered questions and comments. */
struct SpecAnswerRenderOptions {
  bool includeOpen = false;    // list the questions still open
  bool includeMarks = false;   // list the inline marks
  std::string title = "Answers";  // the file's title
};

/* Renders `extracts` as a step folder's `answers.md`: deterministic, grouped
 * per document in the order given, entries in document order. Ends in a
 * single `\n`. */
std::string renderAnswers(
    const std::vector<SpecAnswerExtract>& extracts,
    const SpecAnswerRenderOptions& options = SpecAnswerRenderOptions());

}  // namespace som

#endif  // SPEC_ANSWERS_HPP
