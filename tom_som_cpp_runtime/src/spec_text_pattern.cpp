/* Idiomatic-C++ port of the Dart `spec_text_pattern` library. The matcher is a
 * literal transcription of the normative Dart algorithm — same greedy
 * give-back, same empty-match advance, same ASCII-only folding, same compile
 * rejections — so that spans agree code unit for code unit. */
#include "spec_text_pattern.hpp"

#include "som_util.hpp"

namespace som {
namespace {

/* The pattern metacharacters, named so the parser reads like the grammar. */
constexpr char16_t kDot = 0x2E;           // .
constexpr char16_t kCaret = 0x5E;         // ^
constexpr char16_t kDollar = 0x24;        // $
constexpr char16_t kBackslash = 0x5C;     // backslash
constexpr char16_t kOpenBracket = 0x5B;   // [
constexpr char16_t kCloseBracket = 0x5D;  // ]
constexpr char16_t kStar = 0x2A;          // *
constexpr char16_t kPlus = 0x2B;          // +
constexpr char16_t kQuestion = 0x3F;      // ?
constexpr char16_t kDash = 0x2D;          // -
constexpr char16_t kUpperA = 0x41;
constexpr char16_t kUpperZ = 0x5A;
constexpr char16_t kLowerA = 0x61;
constexpr char16_t kLowerZ = 0x7A;
constexpr char16_t kZero = 0x30;
constexpr char16_t kNine = 0x39;

/* A single code unit rendered for an error message. Only ASCII appears in the
 * corpus' rejected patterns, but a non-ASCII unit still has to render as
 * *something*, so it goes back out as UTF-8. */
std::string charText(char16_t unit) {
  std::string out;
  unsigned int cp = static_cast<unsigned int>(unit);
  if (cp < 0x80) {
    out.push_back(static_cast<char>(cp));
  } else if (cp < 0x800) {
    out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
    out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
  } else {
    out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
    out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
    out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
  }
  return out;
}

char16_t toLowerAscii(char16_t unit) {
  return (unit >= kUpperA && unit <= kUpperZ)
             ? static_cast<char16_t>(unit + 0x20)
             : unit;
}

char16_t swapCase(char16_t unit) {
  if (unit >= kUpperA && unit <= kUpperZ) {
    return static_cast<char16_t>(unit + 0x20);
  }
  if (unit >= kLowerA && unit <= kLowerZ) {
    return static_cast<char16_t>(unit - 0x20);
  }
  return unit;
}

}  // namespace

std::u16string somUtf16Units(const std::string& text) {
  std::u16string out;
  const unsigned char* p =
      reinterpret_cast<const unsigned char*>(text.data());
  const std::size_t n = text.size();
  std::size_t i = 0;
  while (i < n) {
    const unsigned char b0 = p[i];
    unsigned int cp = 0;
    std::size_t len = 0;
    if (b0 < 0x80) {
      cp = b0;
      len = 1;
    } else if ((b0 & 0xE0) == 0xC0) {
      cp = b0 & 0x1Fu;
      len = 2;
    } else if ((b0 & 0xF0) == 0xE0) {
      cp = b0 & 0x0Fu;
      len = 3;
    } else if ((b0 & 0xF8) == 0xF0) {
      cp = b0 & 0x07u;
      len = 4;
    } else {
      out.push_back(0xFFFD);
      i++;
      continue;
    }
    if (i + len > n) {
      out.push_back(0xFFFD);
      i++;
      continue;
    }
    bool ok = true;
    for (std::size_t k = 1; k < len; ++k) {
      const unsigned char bk = p[i + k];
      if ((bk & 0xC0) != 0x80) {
        ok = false;
        break;
      }
      cp = (cp << 6) | (bk & 0x3Fu);
    }
    /* Overlongs, surrogate code points and out-of-range values are all
     * malformed; rejecting them here keeps the unit sequence well-formed. */
    if (!ok || (len == 2 && cp < 0x80) || (len == 3 && cp < 0x800) ||
        (len == 4 && cp < 0x10000) || cp > 0x10FFFF ||
        (cp >= 0xD800 && cp <= 0xDFFF)) {
      out.push_back(0xFFFD);
      i++;
      continue;
    }
    if (cp < 0x10000) {
      out.push_back(static_cast<char16_t>(cp));
    } else {
      cp -= 0x10000;
      out.push_back(static_cast<char16_t>(0xD800 + (cp >> 10)));
      out.push_back(static_cast<char16_t>(0xDC00 + (cp & 0x3FF)));
    }
    i += len;
  }
  return out;
}

std::string SpecMatchSpan::display() const {
  return "SpecMatchSpan(" + formatI64(start) + ", " + formatI64(end) + ")";
}

SomPatternError::SomPatternError(std::string pattern, std::string message)
    : pattern_(std::move(pattern)),
      message_(std::move(message)),
      rendered_("SomPatternError(\"" + pattern_ + "\"): " + message_) {}

namespace {

/* Throws the grammar rejection, mirroring Dart's local `bad`. */
[[noreturn]] void bad(const std::string& source, const std::string& why) {
  throw SomPatternError(source, why);
}

/* Rejects `\` followed by an ASCII letter or digit.
 *
 * Every character class shorthand other dialects define — `\d` `\w` `\s` `\b`
 * `\n` `\1` — lives in exactly this space, and none of them has a literal
 * reading anyone intends: nobody writes `\w` meaning the letter `w`. Accepting
 * them as literals would make `slip\w+` quietly mean "slip, then one or more
 * `w`", which matches nothing and reports no error. Escapes of
 * *non*-alphanumerics stay legal, so `\.` `\[` `\(` still write those
 * characters literally. */
void rejectClassEscape(const std::string& source, char16_t escaped) {
  const bool isAlpha = (escaped >= kUpperA && escaped <= kUpperZ) ||
                       (escaped >= kLowerA && escaped <= kLowerZ);
  const bool isDigit = escaped >= kZero && escaped <= kNine;
  if (!isAlpha && !isDigit) {
    return;
  }
  bad(source, "escape \"\\" + charText(escaped) +
                  "\" is outside the portable subset — it has no "
                  "character-class shorthands, and reading it as a literal \"" +
                  charText(escaped) + "\" would not be what was meant");
}

}  // namespace

SomTextPattern SomTextPattern::literal(const std::string& text,
                                       bool caseInsensitive) {
  std::vector<Term> terms;
  for (char16_t unit : somUtf16Units(text)) {
    Term t;
    t.kind = AtomKind::Literal;
    t.literal = unit;
    terms.push_back(t);
  }
  return SomTextPattern(std::move(terms), caseInsensitive);
}

SomTextPattern SomTextPattern::compile(const std::string& source,
                                       bool caseInsensitive) {
  const std::u16string units = somUtf16Units(source);
  std::vector<Term> terms;

  std::size_t i = 0;
  while (i < units.size()) {
    const char16_t ch = units[i];
    Term term;
    if (ch == kDot) {
      term.kind = AtomKind::Any;
      i++;
    } else if (ch == kCaret) {
      term.kind = AtomKind::StartAnchor;
      i++;
    } else if (ch == kDollar) {
      term.kind = AtomKind::EndAnchor;
      i++;
    } else if (ch == kBackslash) {
      if (i + 1 >= units.size()) {
        bad(source, "pattern ends with a dangling escape");
      }
      rejectClassEscape(source, units[i + 1]);
      term.kind = AtomKind::Literal;
      term.literal = units[i + 1];
      i += 2;
    } else if (ch == kOpenBracket) {
      /* Parses the character class starting at `units[i]` (which is `[`). */
      std::size_t j = i + 1;
      bool negated = false;
      if (j < units.size() && units[j] == kCaret) {
        negated = true;
        j++;
      }
      std::vector<Range> ranges;
      /* A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule
       * — adopted because the alternative is an empty class, which can never
       * match and is therefore never what was meant. */
      bool first = true;
      while (j < units.size() && (units[j] != kCloseBracket || first)) {
        first = false;
        char16_t lo = units[j];
        if (lo == kBackslash) {
          if (j + 1 >= units.size()) {
            bad(source, "dangling escape inside a character class");
          }
          rejectClassEscape(source, units[j + 1]);
          lo = units[j + 1];
          j += 2;
        } else {
          j++;
        }
        /* `-` is a range only between two members; trailing `-` is a
         * literal. */
        if (j + 1 < units.size() && units[j] == kDash &&
            units[j + 1] != kCloseBracket) {
          char16_t hi = units[j + 1];
          std::size_t step = 2;
          if (hi == kBackslash) {
            if (j + 2 >= units.size()) {
              bad(source, "dangling escape inside a character class");
            }
            rejectClassEscape(source, units[j + 2]);
            hi = units[j + 2];
            step = 3;
          }
          if (hi < lo) {
            bad(source, "character class range \"" + charText(lo) + "-" +
                            charText(hi) + "\" runs backwards");
          }
          Range r;
          r.lo = lo;
          r.hi = hi;
          ranges.push_back(r);
          j += step;
        } else {
          Range r;
          r.lo = lo;
          r.hi = lo;
          ranges.push_back(r);
        }
      }
      if (j >= units.size()) {
        bad(source, "character class opened at " +
                        formatI64(static_cast<long long>(i)) +
                        " is never closed");
      }
      term.kind = AtomKind::CharClass;
      term.ranges = std::move(ranges);
      term.negated = negated;
      i = j + 1;
    } else if (ch == kStar || ch == kPlus || ch == kQuestion) {
      bad(source, "quantifier \"" + charText(ch) + "\" at offset " +
                      formatI64(static_cast<long long>(i)) +
                      " has nothing to repeat");
    } else {
      term.kind = AtomKind::Literal;
      term.literal = ch;
      i++;
    }

    if (i < units.size()) {
      Repeat repeat = Repeat::One;
      if (units[i] == kStar) {
        repeat = Repeat::ZeroOrMore;
      } else if (units[i] == kPlus) {
        repeat = Repeat::OneOrMore;
      } else if (units[i] == kQuestion) {
        repeat = Repeat::ZeroOrOne;
      }
      if (repeat != Repeat::One) {
        if (term.isAnchor()) {
          bad(source, "anchor \"" + charText(ch) + "\" at offset " +
                          formatI64(static_cast<long long>(i)) +
                          " cannot carry a quantifier");
        }
        term.repeat = repeat;
        i++;
      }
    }
    terms.push_back(std::move(term));
  }
  return SomTextPattern(std::move(terms), caseInsensitive);
}

std::vector<SpecMatchSpan> SomTextPattern::allMatches(
    const std::string& text) const {
  const std::u16string units = somUtf16Units(text);
  std::vector<SpecMatchSpan> spans;
  long long start = 0;
  const long long length = static_cast<long long>(units.size());
  while (start <= length) {
    const long long end = matchAt(units, 0, start);
    if (end < 0) {
      start++;
      continue;
    }
    spans.push_back(SpecMatchSpan(start, end));
    // Non-overlapping: resume past the match, but never stand still.
    start = end > start ? end : start + 1;
  }
  return spans;
}

bool SomTextPattern::hasMatch(const std::string& text) const {
  return !allMatches(text).empty();
}

long long SomTextPattern::matchAt(const std::u16string& units,
                                  std::size_t termIndex, long long at) const {
  if (termIndex == terms_.size()) {
    return at;
  }
  const Term& term = terms_[termIndex];
  const long long length = static_cast<long long>(units.size());

  switch (term.kind) {
    case AtomKind::StartAnchor:
      return at == 0 ? matchAt(units, termIndex + 1, at) : -1;
    case AtomKind::EndAnchor:
      return at == length ? matchAt(units, termIndex + 1, at) : -1;
    case AtomKind::Literal:
    case AtomKind::Any:
    case AtomKind::CharClass:
      break;
  }

  switch (term.repeat) {
    case Repeat::One:
      if (at < length && accepts(term, units[static_cast<std::size_t>(at)])) {
        return matchAt(units, termIndex + 1, at + 1);
      }
      return -1;
    case Repeat::ZeroOrOne: {
      if (at < length && accepts(term, units[static_cast<std::size_t>(at)])) {
        const long long withOne = matchAt(units, termIndex + 1, at + 1);
        if (withOne >= 0) {
          return withOne;
        }
      }
      return matchAt(units, termIndex + 1, at);
    }
    case Repeat::ZeroOrMore:
    case Repeat::OneOrMore: {
      const long long minimum = term.repeat == Repeat::OneOrMore ? 1 : 0;
      long long consumed = at;
      while (consumed < length &&
             accepts(term, units[static_cast<std::size_t>(consumed)])) {
        consumed++;
      }
      while (consumed - at >= minimum) {
        const long long rest = matchAt(units, termIndex + 1, consumed);
        if (rest >= 0) {
          return rest;
        }
        if (consumed == at) {
          break;
        }
        consumed--;
      }
      return -1;
    }
  }
  return -1;
}

bool SomTextPattern::accepts(const Term& term, char16_t unit) const {
  switch (term.kind) {
    case AtomKind::Any:
      return true;
    case AtomKind::Literal:
      return fold(unit) == fold(term.literal);
    case AtomKind::CharClass: {
      bool inside = false;
      for (const Range& r : term.ranges) {
        if (inRange(r, unit)) {
          inside = true;
          break;
        }
      }
      return term.negated ? !inside : inside;
    }
    case AtomKind::StartAnchor:
    case AtomKind::EndAnchor:
      return false;
  }
  return false;
}

/* Honours ASCII-only case folding: an insensitive `[a-z]` must also admit `Q`,
 * which a single folded comparison of the code unit cannot express (folding `Q`
 * to `q` would also make `[A-Z]` admit `q`, which is the same answer — but
 * folding the *bounds* would break `[A-z]`). So both cases of the unit are
 * tried against the raw range. */
bool SomTextPattern::inRange(const Range& r, char16_t unit) const {
  if (unit >= r.lo && unit <= r.hi) {
    return true;
  }
  if (!caseInsensitive_) {
    return false;
  }
  const char16_t swapped = swapCase(unit);
  return swapped != unit && swapped >= r.lo && swapped <= r.hi;
}

char16_t SomTextPattern::fold(char16_t unit) const {
  return caseInsensitive_ ? toLowerAscii(unit) : unit;
}

}  // namespace som
