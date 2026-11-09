/* spec_review_annotations — review annotations in content values (SOM §11.9):
 * comment blocks, question blocks and CriticMarkup inline marks, and the
 * team-review notation on top of them (§11.9.8: attribution tokens,
 * individual answers, conflict blocks, `open:`). An idiomatic-C++ port of the
 * Dart `spec_review_annotations.dart`; the team notation follows the
 * TypeScript reference, which has it first.
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

/* The kinds of annotation (SOM §11.9): the three of §11.9.1–11.9.3 and the
 * conflict block a team review adds (§11.9.8). */
enum class SpecReviewAnnotationKind {
  Comment,   // a reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`
  Question,  // one question of a question block, `> **❓ BQ-81 — topic:** …`
  Mark,      // a CriticMarkup inline mark
  Conflict,  // a conflict block, `> ⚖️ **X-3 — Conflicting changes:** …`
};

/* The kind's wire name: `"comment"`, `"question"`, `"mark"`, `"conflict"`. */
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
  /* `comment`, `question` or `conflict` when the paragraph opens with an
   * annotation block of that kind, else nullopt. */
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

/* ---- team reviews (SOM §11.9.8) -------------------------------------------
 *
 * The JSON forms below take a `team` flag. `team == true` gives the extended
 * form `team_annotation_cases.json` pins: marks with `authors` and `votes`,
 * questions with `unresolved` and `answers`, the counts with the team counts,
 * a removal report with its `conflicts`. Without it the form is the one of
 * §11.9.1–11.9.7, which the older case files pin byte for byte. */

/* One reviewer's vote on a mark someone else proposed (SOM §11.9.8): `+id`
 * accepts, `-id` rejects. */
struct SpecMarkVote {
  std::string member;  // the voter's member id
  bool accept = true;  // `+id` (true) or `-id` (false)

  /* `{member, vote}`, `vote` being `accept` or `reject`. */
  std::string toJson() const;
};

/* One line of individual answers, `**Answer (alice, bob):** (a)`. */
struct SpecIndividualAnswer {
  std::vector<std::string>
      members;         // who gave this answer, in the order written
  std::string answer;  // the answer, trimmed
  /* When the answer was last written (SOM §11.9.10), or nullopt. */
  std::optional<std::string> changedAt;

  /* The letter the answer starts with (`(a)` or `**(a)**`), or nullopt. */
  std::optional<std::string> answerLetter() const;

  /* `{members, answer, answerLetter}`, plus `changedAt` when set. */
  std::string toJson() const;
};

/* One lettered alternative of a conflict block, `- (a) **alice:** text`. */
struct SpecConflictAlternative {
  std::string letter;                // the lowercase letter
  std::vector<std::string> members;  // who made this change
  std::string
      text;  // the alternative's text; its continuation lines kept as lines

  /* `{letter, members, text}`. */
  std::string toJson() const;
};

/* Whether `s` is a member id (SOM §11.9.8): lowercase letters, digits and
 * `_`. */
bool isReviewMemberId(const std::string& s);

/* Whether `s` is a change time of the form SOM §11.9.10 fixes: minutes with
 * the writer's UTC offset, `2026-11-07T14:05+01:00` or `2026-11-07T13:05Z`. */
bool isReviewTime(const std::string& s);

/* `at` — an ISO 8601 time with minutes, optional seconds and fraction, and an
 * offset or `Z` — as a change time (SOM §11.9.10): seconds and fractions cut,
 * the offset kept as given. Throws `SpecReviewAnnotationError` for any other
 * shape. */
std::string normalizeReviewTime(const std::string& at);

/* The system clock as a change time in its local offset (SOM §11.9.10),
 * `YYYY-MM-DDTHH:MM±HH:MM`. */
std::string systemReviewTime();

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
  /* The comment id (`C-12`), question id (`BQ-81`) or conflict id (`X-3`);
   * nullopt for a comment without an id and for a mark. */
  std::optional<std::string> id;
  /* A comment's or conflict's id with the document qualifier in front
   * (`SBP C-12`), when the listing was given a qualifier and it has an id. */
  std::optional<std::string> qualifiedId;
  /* A comment's author; nullopt when none is written. */
  std::optional<std::string> author;
  /* A comment's text, a question's text (options included; it ends before the
   * first individual answer), a conflict's text (what it concerns), or a
   * mark's text (a substitution's old text; empty for a comment mark). */
  std::string text;
  /* A comment's context: the paragraph before the block, verbatim (empty at
   * the start of the value). */
  std::string context;
  /* A question's or conflict's topic (in a combined block: the field it asks
   * about). */
  std::optional<std::string> topic;
  /* Whether a question carries `★` before its topic. */
  bool starred = false;
  /* Whether a question is part of a combined block. */
  bool combined = false;
  /* A question's team answer, or a conflict's decision, trimmed; empty when
   * open. */
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
  /* A mark's authors from its attribution token; empty without one. */
  std::vector<std::string> authors;
  /* A mark's votes from its attribution token; empty without one. */
  std::vector<SpecMarkVote> votes;
  /* A question's individual answers, in the order written. */
  std::vector<SpecIndividualAnswer> answers;
  /* A conflict's `(base)` text. */
  std::string base;
  /* A conflict's lettered alternatives. */
  std::vector<SpecConflictAlternative> alternatives;
  /* When a comment, mark or question was last changed (SOM §11.9.10), or
   * nullopt. A question's is the time in its header. */
  std::optional<std::string> changedAt;
  /* When a question's team answer was last changed (SOM §11.9.10): the time
   * in `**Answer (<time>):**`, or nullopt. */
  std::optional<std::string> answerChangedAt;

  /* Whether a question is still open (no team answer written), or a conflict
   * (no decision written). */
  bool open() const {
    return (kind == SpecReviewAnnotationKind::Question ||
            kind == SpecReviewAnnotationKind::Conflict) &&
           answer.empty();
  }

  /* Whether a question's team answer or a conflict's decision begins with
   * `open:` — answered for a gate, but handed back (SOM §11.9.8). */
  bool unresolved() const;

  /* The letter a question's team answer starts with (`(b)` or `**(b)**`);
   * nullopt for none, for an unresolved answer and for the other kinds. */
  std::optional<std::string> answerLetter() const;

  /* A conflict's decision letter: `a`…, `base`, or nullopt for rewritten
   * text, for none and for the other kinds. */
  std::optional<std::string> decisionLetter() const;

  /* The canonical JSON form the conformance corpus pins (every key written,
   * `null` explicitly); `team` adds the members of SOM §11.9.8. */
  std::string toJson(bool team = false) const;
};

/* The counts a report needs (SOM §11.9). */
struct SpecReviewAnnotationCounts {
  std::size_t questions = 0;          // every question
  std::size_t openQuestions = 0;      // questions without an answer
  std::size_t answeredQuestions = 0;  // questions with an answer
  std::size_t comments = 0;           // comment blocks
  std::size_t marks = 0;              // inline marks
  /* Questions whose team answer begins `open:` (also counted as answered). */
  std::size_t unresolvedQuestions = 0;
  std::size_t conflicts = 0;      // conflict blocks
  std::size_t openConflicts = 0;  // conflict blocks without a decision

  /* `{questions, openQuestions, answeredQuestions, comments, marks}`; `team`
   * adds `unresolvedQuestions`, `conflicts` and `openConflicts`. */
  std::string toJson(bool team = false) const;
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

/* The quote a change comment opens with (SOM §11.9.3): the change it is
 * about, as written in the quote. */
struct SpecQuotedChange {
  SpecMarkKind kind = SpecMarkKind::Insertion;  // a change kind
  std::string oldText;  // the text before the change ("" for an insertion)
  std::string newText;  // the text after the change ("" for a deletion)
  /* `accepted`, `rejected`, or nullopt while the change is open. */
  std::optional<std::string> outcome;

  /* `{kind, oldText, newText, outcome}`. */
  std::string toJson() const;
};

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
  std::string markup;   // the mark as written, its attribution token included
  std::string context;  // the paragraph holding the mark, verbatim
  /* The authors its attribution token names (SOM §11.9.8); empty without one.
   */
  std::vector<std::string> authors;
  /* The votes its attribution token records; empty without one. */
  std::vector<SpecMarkVote> votes;
  /* A change comment's quote (SOM §11.9.3); nullopt for any other mark. Its
   * `comment` is then the text after the quote. */
  std::optional<SpecQuotedChange> quotedChange;
  /* A change's attached comment, by id; nullopt without one. */
  std::optional<std::string> commentId;
  /* The change an attached change comment is about, by id; nullopt
   * otherwise. */
  std::optional<std::string> changeId;
  /* When the mark was last changed (SOM §11.9.10), or nullopt. */
  std::optional<std::string> changedAt;

  /* The canonical JSON form the conformance corpus pins; `team` adds
   * `authors` and `votes`. `quotedChange`, `commentId`, `changeId` and
   * `changedAt` appear only on the marks they describe. */
  std::string toJson(bool team = false) const;
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

/* What `removeAllAnnotations` did with one conflict block (SOM §11.9.8). */
struct SpecConflictOutcome {
  std::string id;  // the conflict id, `X-<n>`
  std::string path;
  std::optional<std::string> field;  // nullopt for content
  std::size_t line =
      0;  // the 0-based line within the value where the block opened
  std::string decision;  // the decision as written
  std::string result;    // the text the decision chose

  std::string toJson() const;
};

/* The report of a mark operation, for the decision log. */
struct SpecMarkReport {
  std::vector<SpecMarkOutcome> applied;  // what was done, in document order
  std::vector<SpecMarkIssue> malformed;  // malformed marks in scope
  /* The conflicts `removeAllAnnotations` applied, in document order; nullopt
   * for the mark operations, which do not touch conflicts. */
  std::optional<std::vector<SpecConflictOutcome>> conflicts;

  /* `{applied: [...], malformed: [...]}`; `team` adds `conflicts` when set. */
  std::string toJson(bool team = false) const;
};

/* ---- text level: one value ---------------------------------------------- */

/* `value` with every inline mark accepted (`accept`) or rejected, and every
 * highlight and comment mark removed. Marks in code and malformed marks stay
 * as written. */
std::string applyInlineMarksText(const std::string& value, bool accept);

/* `value` with every inline mark accepted (`accept`) or rejected, as accept
 * all / reject all write it (SOM §11.9.3): change comments stay, an attached
 * one records the outcome; every other highlight and comment mark is
 * removed. Marks in code and malformed marks stay as written. */
std::string decideAllMarksText(const std::string& value, bool accept);

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

/* The lines of a comment block (`author` nullopt or empty for none); the
 * header's parentheses hold the author and `changedAt` (SOM §11.9.10),
 * either alone, or are left out when there is neither. */
std::vector<std::string> formatCommentBlock(
    const std::string& id, const std::string& text,
    const std::optional<std::string>& author = std::nullopt,
    const std::optional<std::string>& changedAt = std::nullopt);

/* The lines of a question block; `changedAt` is written after the id (SOM
 * §11.9.10). */
std::vector<std::string> formatQuestionBlock(
    const SpecQuestionDraft& q,
    const std::optional<std::string>& changedAt = std::nullopt);

/* The lines of a conflict block (SOM §11.9.8): the header, the `(base)` line,
 * one lettered alternative per entry naming its members, and an empty
 * `**Decision:**`. A text's further lines are indented under it, so a reader
 * gets them back with their line breaks. */
std::vector<std::string> formatConflictBlock(
    const std::string& id, const std::string& topic, const std::string& text,
    const std::string& base,
    const std::vector<SpecConflictAlternative>& alternatives);

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
  /* The clock the write operations take a change time from when no `at` is
   * passed (SOM §11.9.10): returns the time as a change time. */
  using Clock = std::function<std::string()>;

  /* Wraps `doc`. `qualifier` is the document's id or name, written in front
   * of a comment id cited outside the document (`SBP` → `SBP C-12`). `clock`
   * fixes the change time the writes record (the conformance driver passes a
   * fixed one); empty: the system clock in the writer's offset. */
  explicit SpecReviewAnnotations(
      SpecDocument& doc, std::optional<std::string> qualifier = std::nullopt,
      Clock clock = nullptr)
      : doc_(&doc), qualifier_(std::move(qualifier)), clock_(std::move(clock)) {}

  SpecDocument& doc() const { return *doc_; }
  const std::optional<std::string>& qualifier() const { return qualifier_; }
  const Clock& clock() const { return clock_; }

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
   * when given, else the next free one. The header records the change time
   * `at` (normalized), else the clock's (SOM §11.9.10); an invalid `at` is
   * refused before anything is written. */
  std::string insertComment(const std::string& path,
                            const std::optional<std::string>& field,
                            long long afterParagraph, const std::string& text,
                            const std::optional<std::string>& author = std::nullopt,
                            const std::optional<std::string>& id = std::nullopt,
                            const std::optional<std::string>& at = std::nullopt);

  /* Inserts a question block after paragraph `afterParagraph` (0-based; -1:
   * at the start) of the value at `path` / `field`; its header carries the
   * time `at`, else the clock's (SOM §11.9.10). */
  void insertQuestion(const std::string& path,
                      const std::optional<std::string>& field,
                      long long afterParagraph,
                      const SpecQuestionDraft& question,
                      const std::optional<std::string>& at = std::nullopt);

  /* Inserts a question block directly after the comment `commentId`; its
   * header carries the time `at`, else the clock's (SOM §11.9.10). */
  void insertQuestionAfterComment(
      const std::string& commentId, const SpecQuestionDraft& question,
      const std::optional<std::string>& at = std::nullopt);

  /* Writes `answer` as the question's team answer, `**Answer (<time>):**`
   * with the time `at`, else the clock's (SOM §11.9.10); empty reopens it as
   * `**Answer:**`. With `author`, writes that member's individual answer instead, grouped and
   * placed by the rules of SOM §11.9.8 (empty: only takes the member out); an
   * author that is not a member id is refused. A non-empty individual answer
   * records the change time `at`, else the clock's (SOM §11.9.10). */
  void setAnswer(const std::string& questionId, const std::string& answer,
                 const std::optional<std::string>& author = std::nullopt,
                 const std::optional<std::string>& at = std::nullopt);

  /* Replaces a comment's text; its marker, id and author stay as written, and
   * the header records the change time `at`, else the clock's (SOM
   * §11.9.10). */
  void editComment(const std::string& commentId, const std::string& text,
                   const std::optional<std::string>& at = std::nullopt);

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

  /* Accepts every inline mark under `path` (nullopt: the whole document),
   * except change comments, which stay (SOM §11.9.3). */
  SpecMarkReport acceptAllMarks(
      const std::optional<std::string>& path = std::nullopt);

  /* Rejects every inline mark under `path` (nullopt: the whole document),
   * except change comments, which stay (SOM §11.9.3). */
  SpecMarkReport rejectAllMarks(
      const std::optional<std::string>& path = std::nullopt);

  /* Writes a change comment (SOM §11.9.3) directly after the change mark
   * `markId`, its quote written from the mark and `text` after it, with an
   * attribution token `{@author T}` (`T` the change time `at`, else the
   * clock's; SOM §11.9.10), and returns the new
   * comment's id. Throws `SpecReviewAnnotationError` — nothing changes — for
   * an unknown id, a stale `revision` (when given), a mark that is not a
   * change or already has an attached comment, a change its quote cannot
   * hold, a `text` that is empty or holds a mark delimiter or a blank line,
   * an `author` that is not a member id, and an invalid `at`. */
  std::string commentChange(
      const std::string& markId, const std::string& text,
      const std::optional<std::string>& author = std::nullopt,
      const std::optional<std::string>& revision = std::nullopt,
      const std::optional<std::string>& at = std::nullopt);

  /* Replaces the comment of the comment mark, change comment or commented
   * highlight `markId` with `text` (SOM §11.9.3). A change comment keeps its
   * quote as written, and the attribution token keeps its authors and votes
   * and records the change time `at`, else the clock's (SOM §11.9.10). Throws
   * `SpecReviewAnnotationError` — nothing changes — for an unknown id, a
   * stale `revision` (when given), a mark that holds no comment, a `text`
   * that is empty or holds a mark delimiter or a blank line, and an invalid
   * `at`. */
  void editMarkComment(
      const std::string& markId, const std::string& text,
      const std::optional<std::string>& revision = std::nullopt,
      const std::optional<std::string>& at = std::nullopt);

  /* Removes every annotation and writes the result back: every inline mark
   * accepted (change comments included, so they go too), every conflict's
   * decision applied (SOM §11.9.8), every comment, question and conflict
   * block removed. Malformed marks stay and are
   * reported. Refused — throws SpecReviewAnnotationError, nothing changes —
   * while a conflict is open, unresolved (`open:`), malformed, or decided for
   * a letter it has no alternative for. Returns the accept report with the
   * applied conflicts. */
  SpecMarkReport removeAllAnnotations();

  /* Writes `text` at `path` / `field` as a marked change against the value
   * there now. A value that already holds change marks is compared from its
   * original — every mark rejected — so a second edit of the same passage
   * updates its mark instead of nesting one. Change comments (SOM §11.9.3)
   * are kept: each is written back after as many non-whitespace characters
   * as preceded it in the original, detached from any change. Every change
   * mark gets an attribution token (SOM §11.9.10): the one the same change
   * had before the write, else `{@author T}` (`T` the change time `at`, else
   * the clock's). An `author` that is not a member id and an invalid `at`
   * are refused — `SpecReviewAnnotationError`, nothing changes. */
  SpecMarkedChange setMarked(const std::string& path,
                             const std::optional<std::string>& field,
                             const std::string& text,
                             const std::optional<std::string>& author = std::nullopt,
                             const std::optional<std::string>& at = std::nullopt);

  /* Marks the value at `path` / `field` as a change against `earlier`, an
   * earlier version of it, and writes the result; its change marks get
   * attribution tokens as `setMarked` writes them. */
  SpecMarkedChange markAgainst(const std::string& path,
                               const std::optional<std::string>& field,
                               const std::string& earlier,
                               const std::optional<std::string>& author = std::nullopt,
                               const std::optional<std::string>& at = std::nullopt);

  /* A copy of the document without any annotation, for reading. The document
   * itself is unchanged. */
  SpecDocument stripped() const;

  /* The instance-tier findings on annotations (SOM §11.9.5), ordered by path
   * (= `validateReviewAnnotations(doc())`). */
  std::vector<SpecValidationError> validate() const;

 private:
  /* Applies `decide(id, quoted)` — `quoted`: the mark is a change comment —
   * to every mark under `under`, one write per value. */
  SpecMarkReport applyMarks(
      const std::function<std::optional<SpecMarkDecision>(const std::string&,
                                                          bool)>& decide,
      const std::optional<std::string>& under);

  /* The change time a write records: `at` normalized, else the clock's,
   * else the system time (SOM §11.9.10). */
  std::string changeTime(const std::optional<std::string>& at) const;

  struct DecidedConflict;
  std::vector<DecidedConflict> decidedConflicts() const;
  std::string applyConflicts(const std::string& path,
                             const std::optional<std::string>& field,
                             const std::string& value,
                             const std::vector<DecidedConflict>& decided,
                             std::vector<SpecConflictOutcome>& outcomes);

  SpecDocument* doc_;
  std::optional<std::string> qualifier_;
  Clock clock_;
};

/* ---- text-level building blocks of the merge (SOM §11.9.9) ---------------
 *
 * Internal: `spec_review_merge` is built on them. They live here because they
 * read a value with this module's parser; they are not part of the
 * annotation API. */
namespace review_internal {

/* One paragraph of a value as the merge sees it: text, or an annotation
 * block. */
struct ReviewPiece {
  /* nullopt for a text paragraph, else the kind of the block it opens with. */
  std::optional<SpecReviewAnnotationKind> kind;
  std::string text;  // the paragraph's lines, verbatim
  /* A comment's id (nullopt without one), a conflict's id (nullopt when
   * malformed). */
  std::optional<std::string> id;
  std::optional<std::string> author;     // a comment's author
  std::string commentText;               // a comment's text
  std::optional<std::string> changedAt;  // a comment's change time (§11.9.10)
  std::vector<std::string> questionIds;  // a question block's question ids
};

/* The paragraphs of `value` (SOM §11.9.1), each classified. */
std::vector<ReviewPiece> reviewPieces(const std::string& value);

/* One inline mark of a value, with what its decisions leave. Offsets are
 * byte offsets into the value. */
struct ReviewMark {
  std::size_t start = 0;
  std::size_t end = 0;      // after the attribution token when there is one
  std::size_t bodyEnd = 0;  // right after the mark itself
  SpecMarkKind kind = SpecMarkKind::Comment;
  std::string markup;  // the mark as written, its token included
  std::vector<std::string> authors;
  std::vector<SpecMarkVote> votes;
  std::optional<std::string> changedAt;  // its token's change time (§11.9.10)
  std::string accepted;  // the text accepting it leaves
  std::string rejected;  // the text rejecting it leaves
};

/* The inline marks of `value`, in order (marks in code are not marks). */
std::vector<ReviewMark> reviewMarks(const std::string& value);

/* `value` with the marks `decisions` names (by index into `reviewMarks`)
 * accepted (true) or rejected, by the whitespace rules of SOM §11.9.3. */
std::string decideReviewMarks(const std::string& value,
                              const std::map<std::size_t, bool>& decisions);

/* The attribution token for `authors`, `votes` and `changedAt`,
 * `{@agent +alice -bob 2026-11-07T14:05+01:00}` (SOM §11.9.8, §11.9.10);
 * empty when there is nothing to write. */
std::string formatAttributionToken(
    const std::vector<std::string>& authors,
    const std::vector<SpecMarkVote>& votes,
    const std::optional<std::string>& changedAt = std::nullopt);

/* `value` with mark `m`'s token replaced by one for `authors` and `votes`;
 * the mark's change time stays. */
std::string withAttribution(const std::string& value, const ReviewMark& m,
                            const std::vector<std::string>& authors,
                            const std::vector<SpecMarkVote>& votes);

/* The team answer of every question of `value`, by id, in order (the first
 * of a repeated id wins). */
std::vector<std::pair<std::string, std::string>> reviewTeamAnswers(
    const std::string& value);

/* The time of every question's team answer in `value` (SOM §11.9.10), by id,
 * in order (the first of a repeated id wins); nullopt for an answer written
 * without one. */
std::vector<std::pair<std::string, std::optional<std::string>>>
reviewTeamAnswerTimes(const std::string& value);

/* `value` with `member`'s individual answer to question `questionId` set, as
 * `setAnswer` with an `author` does; nullopt when the value holds no such
 * question. */
std::optional<std::string> setIndividualAnswerText(
    const std::string& value, const std::string& questionId,
    const std::string& member, const std::string& answer,
    const std::optional<std::string>& changedAt = std::nullopt);

/* Carries the edits `x` → `y` over to `b`, a text equal to `x` except where
 * marks of `b` were decided in `x` (SOM §11.9.9, step 3): every edit lands in
 * `b` at the place `x` and `b` agree on. nullopt when an edit touches or
 * borders a place where they differ — the edit overlaps a decided mark. Both
 * diffs are the token diffs of `markChangeText`. */
std::optional<std::string> transplantEdits(const std::string& x,
                                           const std::string& y,
                                           const std::string& b);

}  // namespace review_internal

}  // namespace som

#endif  // SPEC_REVIEW_ANNOTATIONS_HPP
