/* spec_text_pattern — the **portable text-pattern subset** the `text` dimension
 * of a spec query matches with (`som_multiplatform_spec_model.md` §9), an
 * idiomatic-C++ port of the Dart `spec_text_pattern` library.
 *
 * ## Why this exists rather than std::regex
 *
 * The query surface reports `matchSpans` — offsets into the matched string — and
 * those spans are part of the nine-language contract. Delegating to each
 * language's regex engine would make that contract unkeepable twice over:
 *
 *   - **Two runtimes have no regex to delegate to.** `tom_som_rust_runtime` is
 *     std-only by charter and `tom_som_c_runtime` is dependency-free; both would
 *     need a hand-rolled matcher regardless. Native-regex-elsewhere therefore
 *     does not remove the work, it only makes there be *two* implementations of
 *     the same semantics instead of one.
 *   - **The engines disagree where it matters.** Go's `regexp` is RE2
 *     (leftmost-longest for alternation), Dart/JS/Java/Python backtrack
 *     (leftmost-first); case folding is Unicode-aware in some and not others.
 *     A corpus could pin only the intersection, leaving every port's behaviour
 *     *outside* the corpus silently divergent.
 *
 * So the matcher is one algorithm, transcribed into all nine runtimes. Equal
 * spans follow from equal code rather than from a hope about two libraries.
 *
 * ## The grammar
 *
 *     pattern   := term*
 *     term      := atom quantifier?
 *     quantifier:= '*' | '+' | '?'          (greedy; no lazy forms)
 *     atom      := '.'                       any character
 *                | '^'                       start-of-text anchor
 *                | '$'                       end-of-text anchor
 *                | '[' '^'? item* ']'        character class
 *                | '\' PUNCT                 the literal PUNCT (non-alphanumeric)
 *                | CHAR                      itself
 *     item      := CHAR | CHAR '-' CHAR      a member or an inclusive range
 *
 * Deliberately **absent**: alternation, groups, backreferences, lazy
 * quantifiers, and the `\d`/`\w`/`\s` shorthands. Each is either a source of
 * cross-engine disagreement or needs machinery (capture state, Unicode class
 * tables) that nine hand-written ports should not each be carrying.
 *
 * Absent constructs are handled two different ways, and the line between them is
 * whether a literal reading is plausible:
 *
 *   - `(`, `)`, `|`, `{`, `}` are **ordinary literals**. Text genuinely contains
 *     parentheses, so a pattern matching them must stay writable.
 *   - `\` + an ASCII letter or digit is **a compile error**. That is precisely
 *     where `\d` `\w` `\s` `\b` `\n` `\1` live, and none has a literal reading
 *     anyone wants — treating `slip\w+` as "slip then one or more `w`" would
 *     match nothing while reporting no error.
 *
 * Anchors bind to the whole text, never to a line: the values being searched are
 * section values, and a multiline mode would be a second dialect to agree on.
 *
 * ## Matching semantics
 *
 * Greedy backtracking, leftmost match wins. allMatches scans start offsets left
 * to right; a match of length `L > 0` resumes the scan at its end, an empty match
 * advances one character — the same non-overlapping rule Dart's
 * `RegExp.allMatches` uses, stated here so the other eight do not have to infer
 * it.
 *
 * Case-insensitive matching folds **ASCII only** (`A`–`Z` <-> `a`–`z`). Full
 * Unicode case folding differs between the nine languages' standard libraries and
 * would reintroduce exactly the divergence this module removes.
 *
 * ## Offsets are UTF-16 code units, not bytes
 *
 * The normative Dart matches over `String.codeUnits`, so every committed span in
 * the shared corpus is a UTF-16 offset. A C++ port that indexed the UTF-8
 * `std::string` would report different spans for any value holding a non-ASCII
 * character (the fixture holds `spec §1.2`). Every entry point therefore decodes
 * its input with somUtf16Units and matches over that.
 */
#ifndef SPEC_TEXT_PATTERN_HPP
#define SPEC_TEXT_PATTERN_HPP

#include <exception>
#include <string>
#include <vector>

namespace som {

/* Decodes UTF-8 `text` into the UTF-16 code-unit sequence the span contract is
 * defined over (Dart's `String.codeUnits`). Astral characters become a surrogate
 * pair; malformed or truncated byte sequences become U+FFFD, one per offending
 * byte, so the decode never fails and never loses position. */
std::u16string somUtf16Units(const std::string& text);

/* A `[start, end)` half-open span within a matched string — the UTF-16 offsets a
 * pattern hit, surfaced on SpecQueryMatch::matchSpans. */
struct SpecMatchSpan {
  long long start = 0;  // inclusive start offset into the matched string
  long long end = 0;    // exclusive end offset into the matched string

  SpecMatchSpan() = default;
  SpecMatchSpan(long long s, long long e) : start(s), end(e) {}

  bool operator==(const SpecMatchSpan& other) const {
    return start == other.start && end == other.end;
  }
  bool operator!=(const SpecMatchSpan& other) const { return !(*this == other); }

  /* Renders as `SpecMatchSpan(start, end)`. */
  std::string display() const;
};

/* A pattern that is not in the SomTextPattern grammar.
 *
 * Thrown at *compile* time rather than silently matching nothing, so a caller
 * that mistyped a pattern learns that instead of reading an empty result as
 * "no hits". */
class SomPatternError : public std::exception {
 public:
  SomPatternError(std::string pattern, std::string message);

  /* The offending pattern source. */
  const std::string& pattern() const { return pattern_; }
  /* What is wrong with it. */
  const std::string& message() const { return message_; }
  /* Renders as `SomPatternError("pattern"): message`. */
  const char* what() const noexcept override { return rendered_.c_str(); }

 private:
  std::string pattern_;
  std::string message_;
  std::string rendered_;
};

/* A compiled pattern over the portable subset described above. Compile once with
 * SomTextPattern::compile (or SomTextPattern::literal for a plain substring) and
 * match with allMatches. Copyable and movable — a query cursor keeps one by
 * value for its whole lifetime. */
class SomTextPattern {
 public:
  /* A pattern matching `text` as a plain, uninterpreted substring — every
   * character is a literal, including `.` `*` `[` and the rest. */
  static SomTextPattern literal(const std::string& text,
                                bool caseInsensitive = false);

  /* Compiles `source` against the subset grammar.
   *
   * Throws SomPatternError when `source` is not in the grammar: an unterminated
   * or reversed character class, a trailing `\`, an escape of an ASCII
   * letter/digit, or a quantifier with nothing to quantify. */
  static SomTextPattern compile(const std::string& source,
                                bool caseInsensitive = false);

  /* Every non-overlapping match in `text`, left to right, as UTF-16 spans. */
  std::vector<SpecMatchSpan> allMatches(const std::string& text) const;

  /* Whether `text` contains at least one match. */
  bool hasMatch(const std::string& text) const;

  /* Whether this pattern folds case (ASCII only). */
  bool caseInsensitive() const { return caseInsensitive_; }

 private:
  /* What a single term matches. */
  enum class AtomKind { Literal, Any, StartAnchor, EndAnchor, CharClass };
  /* How many times a term's atom may repeat. */
  enum class Repeat { One, ZeroOrOne, ZeroOrMore, OneOrMore };

  /* One inclusive `[lo, hi]` code-unit range inside a character class. */
  struct Range {
    char16_t lo = 0;
    char16_t hi = 0;
  };

  /* One compiled atom plus its quantifier. */
  struct Term {
    AtomKind kind = AtomKind::Literal;
    char16_t literal = 0;        // the code unit for AtomKind::Literal
    std::vector<Range> ranges;   // the ranges for AtomKind::CharClass
    bool negated = false;        // whether a CharClass is negated (`[^…]`)
    Repeat repeat = Repeat::One;

    /* Whether an anchor can carry a quantifier — it cannot; `^*` is meaningless
     * and is far more likely to be a typo than an intent. */
    bool isAnchor() const {
      return kind == AtomKind::StartAnchor || kind == AtomKind::EndAnchor;
    }
  };

  SomTextPattern(std::vector<Term> terms, bool caseInsensitive)
      : terms_(std::move(terms)), caseInsensitive_(caseInsensitive) {}

  /* Matches terms_ from `termIndex` against `units` starting at `at`, returning
   * the end offset of the match or `-1`. Greedy with backtracking: a repeated
   * atom consumes as much as it can, then gives back one character at a time
   * until the remainder of the pattern fits. */
  long long matchAt(const std::u16string& units, std::size_t termIndex,
                    long long at) const;
  bool accepts(const Term& term, char16_t unit) const;
  /* Whether `unit` falls in `r`, honouring ASCII-only case folding. */
  bool inRange(const Range& r, char16_t unit) const;
  char16_t fold(char16_t unit) const;

  std::vector<Term> terms_;
  bool caseInsensitive_ = false;
};

}  // namespace som

#endif  // SPEC_TEXT_PATTERN_HPP
