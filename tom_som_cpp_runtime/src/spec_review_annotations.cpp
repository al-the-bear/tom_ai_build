/* spec_review_annotations — review annotations (SOM §11.9), an idiomatic-C++
 * port of the Dart `spec_review_annotations.dart`. See the header for the
 * contract.
 *
 * Offsets inside a value are UTF-8 byte offsets here (the Dart reference uses
 * UTF-16 code units); they never leave this file. Every delimiter is either
 * ASCII or matched as a whole UTF-8 sequence, so the two agree on every
 * decision. */
#include "spec_review_annotations.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <set>
#include <utility>

#include "som_json.hpp"

namespace som {
namespace {

const std::string kArrow = "\xE2\xAC\x86";  // U+2B06
const std::string kVs16 = "\xEF\xB8\x8F";   // U+FE0F
const std::string kQuestionOpen = "**\xE2\x9D\x93";  // `**❓`
const std::string kCombinedOpener =
    kQuestionOpen + " Open questions on these fields**";
const std::string kAnswerLabel = "**Answer:**";
const std::string kEmDashSep = " \xE2\x80\x94 ";  // ` — `
const std::string kStar = "\xE2\x98\x85";        // U+2605
const std::string kScales = "\xE2\x9A\x96";      // U+2696, a conflict block
const std::string kDecisionLabel = "**Decision:**";
const std::string kUnresolvedPrefix = "open:";

const char* const kOpeners[5] = {"{>>", "{==", "{++", "{--", "{~~"};
const char* const kClosers[5] = {"<<}", "==}", "++}", "--}", "~~}"};

bool startsWith(const std::string& s, const std::string& p,
                std::size_t at = 0) {
  return at <= s.size() && s.compare(at, p.size(), p) == 0 &&
         s.size() - at >= p.size();
}

/* Strips spaces and tabs from the left. */
std::string lstrip(const std::string& s) {
  std::size_t i = 0;
  while (i < s.size() && (s[i] == ' ' || s[i] == '\t')) i++;
  return s.substr(i);
}

/* Decodes one UTF-8 code point at `i`, advancing it. Malformed bytes decode
 * to themselves, one byte at a time. */
unsigned long nextCp(const std::string& s, std::size_t& i, std::size_t end) {
  unsigned char c0 = static_cast<unsigned char>(s[i]);
  unsigned long c = c0;
  std::size_t n = 1;
  std::size_t left = end - i;
  auto b = [&](std::size_t k) {
    return static_cast<unsigned long>(static_cast<unsigned char>(s[i + k]) & 0x3F);
  };
  if (c0 >= 0xF0 && left >= 4) {
    c = ((c & 0x07UL) << 18) | (b(1) << 12) | (b(2) << 6) | b(3);
    n = 4;
  } else if (c0 >= 0xE0 && c0 < 0xF0 && left >= 3) {
    c = ((c & 0x0FUL) << 12) | (b(1) << 6) | b(2);
    n = 3;
  } else if (c0 >= 0xC0 && c0 < 0xE0 && left >= 2) {
    c = ((c & 0x1FUL) << 6) | b(1);
    n = 2;
  }
  i += n;
  return c;
}

/* The whitespace Dart's `String.trim` removes. */
bool dartIsSpace(unsigned long c) {
  return (c >= 0x09 && c <= 0x0D) || c == 0x20 || c == 0x85 || c == 0xA0 ||
         c == 0x1680 || (c >= 0x2000 && c <= 0x200A) || c == 0x2028 ||
         c == 0x2029 || c == 0x202F || c == 0x205F || c == 0x3000 ||
         c == 0xFEFF;
}

/* The bounds of `s` trimmed the way Dart's `trim` trims. */
std::pair<std::size_t, std::size_t> trimBounds(const std::string& s) {
  std::size_t i = 0, first = 0, last = 0;
  bool any = false;
  while (i < s.size()) {
    std::size_t st = i;
    unsigned long c = nextCp(s, i, s.size());
    if (!dartIsSpace(c)) {
      if (!any) {
        first = st;
        any = true;
      }
      last = i;
    }
  }
  return any ? std::make_pair(first, last) : std::make_pair<std::size_t, std::size_t>(0, 0);
}

std::string trim(const std::string& s) {
  auto [b, e] = trimBounds(s);
  return s.substr(b, e - b);
}

std::string trimRight(const std::string& s) { return s.substr(0, trimBounds(s).second); }

bool isBlank(const std::string& s) {
  auto [b, e] = trimBounds(s);
  return b == e;
}

/* Whether a code point is a cased letter: one whose lower case differs from
 * its upper case, as Dart's `toLowerCase() != toUpperCase()` decides on a
 * UTF-16 code unit. Covers ASCII and the cased letters of the common BMP
 * scripts (Latin, Greek, Cyrillic, Armenian, Georgian, Cherokee, Glagolitic,
 * Coptic, fullwidth Latin, circled letters, Roman numerals); a code point
 * outside the BMP is a surrogate pair in Dart and never cased there. */
bool isCased(unsigned long c) {
  if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) return true;
  if (c < 0x80) return false;
  if (c == 0xB5) return true;
  if (c >= 0xC0 && c <= 0xFF) return c != 0xD7 && c != 0xF7;
  if (c >= 0x100 && c <= 0x24F) {
    return !(c == 0x138 || c == 0x18D || c == 0x1AA || c == 0x1AB ||
             c == 0x1BA || c == 0x1BB || c == 0x1BE ||
             (c >= 0x1C0 && c <= 0x1C3) || c == 0x221 ||
             (c >= 0x234 && c <= 0x239));
  }
  if ((c >= 0x370 && c <= 0x373) || c == 0x376 || c == 0x377 ||
      (c >= 0x37B && c <= 0x37D) || c == 0x37F || c == 0x386)
    return true;
  if (c >= 0x388 && c <= 0x3FF) {
    return !(c == 0x38B || c == 0x38D || c == 0x3A2 || c == 0x3F6);
  }
  if ((c >= 0x400 && c <= 0x481) || (c >= 0x48A && c <= 0x52F)) return true;
  if ((c >= 0x531 && c <= 0x556) || (c >= 0x561 && c <= 0x587)) return true;
  if ((c >= 0x10A0 && c <= 0x10C5) || (c >= 0x10D0 && c <= 0x10FA)) return true;
  if ((c >= 0x13A0 && c <= 0x13F5) || (c >= 0x13F8 && c <= 0x13FD)) return true;
  if (c >= 0x1E00 && c <= 0x1FFC) return true;
  if (c >= 0x2160 && c <= 0x217F) return true;
  if (c >= 0x24B6 && c <= 0x24E9) return true;
  if (c >= 0x2C00 && c <= 0x2CF3) return true;
  if ((c >= 0xA640 && c <= 0xA69B) || (c >= 0xA722 && c <= 0xA7FF)) return true;
  if ((c >= 0xFF21 && c <= 0xFF3A) || (c >= 0xFF41 && c <= 0xFF5A)) return true;
  return false;
}

bool isWordCp(unsigned long c, std::size_t bytes) {
  if (c >= '0' && c <= '9') return true;
  if (bytes == 4) return false;
  return isCased(c);
}

/* Whether the first character of `s` is a word character. */
bool wordCharFirst(const std::string& s) {
  if (s.empty()) return false;
  std::size_t i = 0;
  unsigned long c = nextCp(s, i, s.size());
  return isWordCp(c, i);
}

/* Whether the last character of `s` is a word character. */
bool wordCharLast(const std::string& s) {
  if (s.empty()) return false;
  std::size_t len = s.size();
  std::size_t i = len - 1;
  while (i > 0 && (static_cast<unsigned char>(s[i]) & 0xC0) == 0x80 &&
         len - i < 4)
    i--;
  std::size_t q = i;
  unsigned long c = nextCp(s, q, len);
  if (q != len) {
    unsigned char b = static_cast<unsigned char>(s[len - 1]);
    return b < 0x80 && isWordCp(b, 1);
  }
  return isWordCp(c, len - i);
}

/* Splits on `\n` only (Dart `split('\n')`; "" is one empty line). */
std::vector<std::string> splitLines(const std::string& v) {
  std::vector<std::string> out;
  std::size_t s = 0;
  while (true) {
    std::size_t nl = v.find('\n', s);
    if (nl == std::string::npos) {
      out.push_back(v.substr(s));
      return out;
    }
    out.push_back(v.substr(s, nl - s));
    s = nl + 1;
  }
}

std::string joinLines(const std::vector<std::string>& lines) {
  std::string out;
  for (std::size_t k = 0; k < lines.size(); k++) {
    if (k > 0) out += '\n';
    out += lines[k];
  }
  return out;
}

/* `head` then `pieces[from, to]` (inclusive; none when to < from), joined
 * with `\n`. */
std::string joinFrom(const std::string& head,
                     const std::vector<std::string>& pieces, long long from,
                     long long to) {
  std::string out = head;
  for (long long k = from; k <= to; k++) {
    out += '\n';
    out += pieces[static_cast<std::size_t>(k)];
  }
  return out;
}

/* ---- the parse of one value ---------------------------------------------- */

struct Block {
  std::size_t start = 0;
  std::size_t end = 0;
  SpecReviewAnnotationKind kind = SpecReviewAnnotationKind::Comment;
  std::size_t comment = 0;  // index into comments, for a comment block
  std::size_t qFirst = 0;   // questions of a question block
  std::size_t qLen = 0;
  bool combined = false;
  std::size_t conflict = 0;  // index into conflicts, for a conflict block
};

/* One `**Answer (<ids>):**` entry of a question (SOM §11.9.8). */
struct IndividualAnswer {
  std::size_t line = 0;  // value line of the `**Answer (…):**` line
  std::size_t end = 0;   // last value line of the entry with text (inclusive)
  std::vector<std::string> members;
  std::string answer;
  std::optional<std::string> changedAt;  // its change time (SOM §11.9.10)
};

struct Question {
  std::size_t header = 0;     // value line of the header
  std::size_t regionEnd = 0;  // last value line of the region (inclusive)
  std::optional<std::size_t> answerLine;  // value line of `**Answer:**`
  std::string id;
  std::string topic;
  bool starred = false;
  std::string text;
  std::string answer;
  std::vector<SpecQuestionOption> options;
  std::optional<std::string> recommended;
  std::vector<IndividualAnswer> answers;
};

/* One parsed conflict block (SOM §11.9.8). */
struct Conflict {
  std::size_t block = 0;
  /* nullopt when the header is malformed: the block is then not listed. */
  std::optional<std::string> id;
  std::string topic;
  std::string text;
  /* The `(base)` text, or nullopt when the block has none. */
  std::optional<std::string> base;
  std::vector<SpecConflictAlternative> alternatives;
  std::string decision;
};

struct Comment {
  std::size_t block = 0;
  std::optional<std::string> id;
  std::optional<std::string> author;
  std::string text;
  std::string context;
  std::string headerPrefix;  // the first line up to where the text starts
  std::size_t markerEnd = 0;  // where an id is inserted into the first line
  /* The first line up to where the author's parentheses (or the text)
   * start. */
  std::string beforeAuthor;
  std::optional<std::string> changedAt;  // its change time (SOM §11.9.10)
};

/* One parsed mark; start/end are byte offsets into the value (never
 * exported). `end` lies after the attribution token when the mark has one,
 * `bodyEnd` always right after the mark itself, so the token can be rewritten
 * in place. */
struct Mark {
  std::size_t start = 0;
  std::size_t end = 0;
  std::size_t bodyEnd = 0;
  std::size_t line = 0;
  SpecMarkKind kind = SpecMarkKind::Comment;
  std::string text;
  std::optional<std::string> newText;
  std::optional<std::string> comment;
  std::vector<std::string> authors;
  std::vector<SpecMarkVote> votes;
  /* A comment mark's quote of a change (SOM §11.9.3): index into
   * `Parsed::quotes`, or nullopt. */
  std::optional<std::size_t> quote;
  /* The index (among the value's marks) of the change this change comment is
   * attached to, or nullopt. */
  std::optional<std::size_t> changeIndex;
  /* The index of this change's attached comment, or nullopt. */
  std::optional<std::size_t> commentIndex;
  /* The time in the mark's attribution token (SOM §11.9.10), or nullopt. */
  std::optional<std::string> changedAt;
};

/* The quote a change comment opens with (SOM §11.9.3); offsets are byte
 * offsets into the value. */
struct Quote {
  SpecMarkKind kind = SpecMarkKind::Insertion;
  std::string oldText;
  std::string newText;
  std::optional<std::string> outcome;  // `accepted`, `rejected`, or open
  std::size_t delimEnd = 0;  // right after the quote's closing delimiter
  std::size_t end = 0;       // right after the quote's `]`
  std::string comment;       // the text after the quote, trimmed
};

struct Parsed {
  std::vector<std::string> lines;
  std::vector<bool> code;  // per line: inside a fenced block (fence lines too)
  std::vector<Block> blocks;
  std::vector<Comment> comments;
  std::vector<Question> questions;
  std::vector<Conflict> conflicts;
  std::vector<Mark> marks;
  std::vector<Quote> quotes;  // the change comments' quotes (Mark::quote)
  std::vector<std::string> malformed;
  /* Malformed inline marks as (value line, issue code): `unclosed`,
   * `nested`, `noArrow`. */
  std::vector<std::pair<std::size_t, std::string>> markIssues;
};

/* The fenced-code flag of every line. */
std::vector<bool> codeLines(const std::vector<std::string>& lines) {
  std::vector<bool> code(lines.size(), false);
  char fence = 0;
  std::size_t fenceLen = 0;
  for (std::size_t i = 0; i < lines.size(); i++) {
    const std::string t = lstrip(lines[i]);
    if (fence == 0) {
      char c = t.empty() ? '\0' : t[0];
      if (c == '`' || c == '~') {
        std::size_t n = 0;
        while (n < t.size() && t[n] == c) n++;
        if (n >= 3) {
          fence = c;
          fenceLen = n;
          code[i] = true;
        }
      }
    } else {
      code[i] = true;
      std::size_t n = 0;
      while (n < t.size() && t[n] == fence) n++;
      if (n >= fenceLen && isBlank(t.substr(n))) fence = 0;
    }
  }
  return code;
}

bool isQuoteLine(const std::string& line) {
  const std::string t = lstrip(line);
  return !t.empty() && t[0] == '>';
}

/* The line inside the quote: after `>` and one following space. */
std::string innerOf(const std::string& line) {
  const std::string t = lstrip(line);
  std::string s = t.empty() ? t : t.substr(1);
  if (!s.empty() && s[0] == ' ') s = s.substr(1);
  return s;
}

std::string contextOf(const Parsed& p, std::size_t blockStart) {
  long long k = static_cast<long long>(blockStart) - 1;
  while (k >= 0 && (isBlank(p.lines[k]) || isQuoteLine(p.lines[k]))) k--;
  if (k < 0) return "";
  long long end = k;
  while (k - 1 >= 0 && !isBlank(p.lines[k - 1]) && !isQuoteLine(p.lines[k - 1]))
    k--;
  return joinFrom(p.lines[k], p.lines, k + 1, end);
}

bool isCommentNumber(const std::string& n) {
  if (n.empty() || n[0] < '1' || n[0] > '9') return false;
  for (char c : n) {
    if (c < '0' || c > '9') return false;
  }
  return true;
}

/* The start of an individual answer line, `**Answer (alice, bob):**`: the
 * text between the brackets and the length of the label; nullopt for any
 * other line. */
std::optional<std::pair<std::string, std::size_t>> individualAnswerLabel(
    const std::string& line) {
  const std::string open = "**Answer (";
  if (!startsWith(line, open)) return std::nullopt;
  const std::size_t close = line.find(')', open.size());
  if (close == std::string::npos || line.compare(close, 4, "):**") != 0) {
    return std::nullopt;
  }
  return std::make_pair(line.substr(open.size(), close - open.size()),
                        close + 4);
}

/* `s` split on `sep`, each piece trimmed (empty pieces kept). */
std::vector<std::string> splitTrimmed(const std::string& s, char sep) {
  std::vector<std::string> out;
  std::size_t from = 0;
  while (true) {
    const std::size_t at = s.find(sep, from);
    out.push_back(trim(s.substr(
        from, at == std::string::npos ? std::string::npos : at - from)));
    if (at == std::string::npos) return out;
    from = at + 1;
  }
}

/* `s` split on `sep`, the pieces as written (empty pieces kept). */
std::vector<std::string> splitOn(const std::string& s, char sep) {
  std::vector<std::string> out;
  std::size_t from = 0;
  while (true) {
    const std::size_t at = s.find(sep, from);
    out.push_back(
        s.substr(from, at == std::string::npos ? std::string::npos : at - from));
    if (at == std::string::npos) return out;
    from = at + 1;
  }
}

/* `parts` (a header's or an answer's comma-separated parts) without a
 * trailing change time, which goes into `time` (SOM §11.9.10). */
std::vector<std::string> splitTime(std::vector<std::string> parts,
                                   std::optional<std::string>& time) {
  time.reset();
  if (!parts.empty() && isReviewTime(trim(parts.back()))) {
    time = trim(parts.back());
    parts.pop_back();
  }
  return parts;
}

void parseComment(Parsed& p, std::size_t bi) {
  const Block b = p.blocks[bi];
  const std::string& raw0 = p.lines[b.start];
  std::string rest = innerOf(raw0).substr(kArrow.size());
  if (startsWith(rest, kVs16)) rest = rest.substr(kVs16.size());
  const std::size_t markerEnd = raw0.size() - rest.size();
  rest = lstrip(rest);
  std::optional<std::string> id;
  if (startsWith(rest, "**C-")) {
    std::size_t close = rest.find("**", 4);
    if (close != std::string::npos) {
      std::string n = rest.substr(4, close - 4);
      if (isCommentNumber(n)) {
        id = "C-" + n;
      } else {
        p.malformed.push_back("line " + std::to_string(b.start) +
                              ": comment id \"C-" + n +
                              "\" is not C-<number> (SOM \xC2\xA7"
                              "11.9.1)");
      }
      rest = lstrip(rest.substr(close + 2));
    }
  }
  std::optional<std::string> author;
  std::optional<std::string> changedAt;
  const std::string beforeAuthor = raw0.substr(0, raw0.size() - rest.size());
  if (startsWith(rest, "(")) {
    std::size_t close = rest.find(')');
    if (close != std::string::npos && close > 0) {
      const std::string inside = rest.substr(1, close - 1);
      const std::vector<std::string> parts =
          splitTime(splitOn(inside, ','), changedAt);
      if (!changedAt) {
        author = inside;
      } else {
        std::string a;
        for (std::size_t i = 0; i < parts.size(); i++) {
          if (i > 0) a += ',';
          a += parts[i];
        }
        a = trim(a);
        if (!a.empty()) author = a;
      }
      rest = rest.substr(close + 1);
      if (startsWith(rest, ":")) rest = rest.substr(1);
      rest = lstrip(rest);
    }
  } else if (startsWith(rest, ":")) {
    rest = lstrip(rest.substr(1));
  }
  Comment c;
  c.block = bi;
  c.headerPrefix = raw0.substr(0, raw0.size() - rest.size());
  std::string text = rest;
  for (std::size_t k = b.start + 1; k <= b.end; k++) {
    const std::string inner = innerOf(p.lines[k]);
    const std::string t = lstrip(inner);
    if (startsWith(t, kQuestionOpen) || startsWith(t, kAnswerLabel) ||
        individualAnswerLabel(t)) {
      p.malformed.push_back(
          "line " + std::to_string(k) +
          ": a comment block holds a question or an answer; the question "
          "goes into its own block after the comment (SOM \xC2\xA7"
          "11.9.1)");
    }
    text += '\n';
    text += inner;
  }
  c.id = std::move(id);
  c.author = std::move(author);
  c.text = trim(text);
  c.context = contextOf(p, b.start);
  c.markerEnd = markerEnd;
  c.beforeAuthor = beforeAuthor;
  c.changedAt = std::move(changedAt);
  p.comments.push_back(std::move(c));
}

bool isQuestionId(const std::string& s) {
  std::size_t i = 0;
  if (i >= s.size() || !(s[i] >= 'A' && s[i] <= 'Z')) return false;
  i++;
  while (i < s.size() &&
         ((s[i] >= 'A' && s[i] <= 'Z') || (s[i] >= '0' && s[i] <= '9')))
    i++;
  if (i >= s.size() || s[i] != '-') return false;
  i++;
  if (i >= s.size() || !(s[i] >= '0' && s[i] <= '9')) return false;
  while (i < s.size() && s[i] >= '0' && s[i] <= '9') i++;
  return i == s.size();
}

struct Header {
  std::size_t k = 0;
  std::string id;
  std::string topic;
  bool starred = false;
  std::string rest;
};

/* Parses a question header's remainder after `**❓ `; nullopt when
 * malformed. */
std::optional<Header> parseHeader(const std::string& inner) {
  const std::string h = inner.substr(kQuestionOpen.size() + 1);
  std::size_t sep = h.find(kEmDashSep);
  if (sep == std::string::npos || sep == 0) return std::nullopt;
  Header out;
  out.id = h.substr(0, sep);
  if (!isQuestionId(out.id)) return std::nullopt;
  std::string t = h.substr(sep + kEmDashSep.size());
  if (startsWith(t, kStar + " ")) {
    out.starred = true;
    t = t.substr(kStar.size() + 1);
  }
  std::size_t close = t.find(":**");
  if (close == std::string::npos) return std::nullopt;
  out.topic = t.substr(0, close);
  std::string rest = t.substr(close + 3);
  if (startsWith(rest, " ")) rest = rest.substr(1);
  out.rest = rest;
  return out;
}

bool isLetter(char c) { return c >= 'a' && c <= 'z'; }

/* The letter of a leading `(x)` or `**(x)**` in `s` (spaces skipped). */
std::optional<std::string> leadingLetter(const std::string& s) {
  std::size_t i = 0;
  while (i < s.size()) {
    std::size_t st = i;
    if (!dartIsSpace(nextCp(s, i, s.size()))) {
      i = st;
      break;
    }
  }
  std::string t = s.substr(i);
  if (startsWith(t, "**")) t = t.substr(2);
  if (t.size() >= 3 && t[0] == '(' && isLetter(t[1]) && t[2] == ')') {
    return t.substr(1, 1);
  }
  return std::nullopt;
}

bool isUnresolvedAnswer(const std::string& answer) {
  return startsWith(answer, kUnresolvedPrefix);
}

/* `s` without its leading whitespace (Dart's `trimLeft`). */
std::string trimLeft(const std::string& s) {
  auto [b, e] = trimBounds(s);
  return b == e ? std::string() : s.substr(b);
}

/* A conflict decision's letter: `a`…, `base`, or nullopt (rewritten text or
 * none). */
std::optional<std::string> decisionLetterOf(const std::string& decision) {
  const std::string t = trimLeft(decision);
  if (startsWith(t, "(base)") || startsWith(t, "**(base)**")) return "base";
  return isUnresolvedAnswer(t) ? std::nullopt : leadingLetter(t);
}

/* Whether `s`, lower-cased, contains `recommended`. */
bool saysRecommended(const std::string& s) {
  std::string l = s;
  for (char& c : l) {
    if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
  }
  return l.find("recommended") != std::string::npos;
}

/* The options of a question and its recommended letter (SOM §11.9.2), read
 * from `in[from..to]` (inclusive): one option per line, `- (a) …`, the
 * recommended one bold, `- **(b)** …`. The recommended letter is the first
 * bold option's; else the first option's whose text says "recommended"; else
 * the letter a `*Recommendation:*` line names; else none. */
std::pair<std::vector<SpecQuestionOption>, std::optional<std::string>>
parseOptions(const std::vector<std::string>& in, long long from, long long to) {
  std::vector<SpecQuestionOption> options;
  std::optional<std::string> letter;
  std::string text;
  bool bold = false;
  auto close = [&]() {
    if (letter) options.push_back({*letter, trim(text), bold});
    letter.reset();
  };
  for (long long k = from; k <= to; k++) {
    const std::string& l = in[static_cast<std::size_t>(k)];
    if (startsWith(l, "- ")) {
      const std::string r = l.substr(2);
      if (r.size() >= 7 && startsWith(r, "**(") && isLetter(r[3]) &&
          r.compare(4, 3, ")**") == 0) {
        close();
        letter = r.substr(3, 1);
        text = r.substr(7);
        bold = true;
        continue;
      }
      if (r.size() >= 3 && r[0] == '(' && isLetter(r[1]) && r[2] == ')') {
        close();
        letter = r.substr(1, 1);
        text = r.substr(3);
        bold = false;
        continue;
      }
    }
    if (letter && startsWith(l, " ") && !isBlank(l)) {
      text = trim(text) + " " + trim(l);
      continue;
    }
    close();
  }
  close();
  for (const SpecQuestionOption& o : options) {
    if (o.bold) return {options, o.letter};
  }
  for (const SpecQuestionOption& o : options) {
    if (saysRecommended(o.text)) return {options, o.letter};
  }
  const std::string label = "*Recommendation:*";
  for (long long k = from; k <= to; k++) {
    const std::string& l = in[static_cast<std::size_t>(k)];
    const std::size_t i = l.find(label);
    if (i == std::string::npos) continue;
    std::optional<std::string> x = leadingLetter(l.substr(i + label.size()));
    if (x) return {options, x};
  }
  return {options, std::nullopt};
}

void parseQuestions(Parsed& p, std::size_t bi) {
  Block& b = p.blocks[bi];
  std::vector<std::string> in;
  for (std::size_t k = b.start; k <= b.end; k++) in.push_back(innerOf(p.lines[k]));
  b.combined = startsWith(in[0], kCombinedOpener);
  std::vector<Header> headers;
  for (std::size_t k = 0; k < in.size(); k++) {
    if (!startsWith(in[k], kQuestionOpen + " ")) continue;
    if (startsWith(in[k], kCombinedOpener)) continue;
    std::optional<Header> h = parseHeader(in[k]);
    if (!h) {
      p.malformed.push_back("line " + std::to_string(b.start + k) +
                            ": question header is not \"**\xE2\x9D\x93 <ID> "
                            "\xE2\x80\x94 <topic>:**\" (SOM \xC2\xA7"
                            "11.9.2)");
      continue;
    }
    h->k = k;
    headers.push_back(std::move(*h));
  }
  b.qFirst = p.questions.size();
  b.qLen = headers.size();
  for (std::size_t q = 0; q < headers.size(); q++) {
    const Header& h = headers[q];
    std::size_t k = h.k;
    std::size_t regionEnd =
        q + 1 < headers.size() ? headers[q + 1].k - 1 : in.size() - 1;
    // Every `**Answer` line of the region: the individual ones and the team's.
    std::vector<std::size_t> answerLines;
    for (std::size_t m = k + 1; m <= regionEnd; m++) {
      if (startsWith(in[m], kAnswerLabel) || individualAnswerLabel(in[m])) {
        answerLines.push_back(m);
      }
    }
    // An answer runs to the next `**Answer` line or the end of the region.
    auto answerEnd = [&](std::size_t m) {
      for (std::size_t x : answerLines) {
        if (x > m) return x - 1;
      }
      return regionEnd;
    };
    auto answerText = [&](std::size_t m, std::size_t label) {
      return trim(joinFrom(in[m].substr(label), in,
                           static_cast<long long>(m) + 1,
                           static_cast<long long>(answerEnd(m))));
    };
    // The question's text ends before its first answer line of either kind.
    long long textEnd = answerLines.empty()
                            ? static_cast<long long>(regionEnd)
                            : static_cast<long long>(answerLines[0]) - 1;
    Question qq;
    auto [options, recommended] =
        parseOptions(in, static_cast<long long>(k) + 1, textEnd);
    qq.options = std::move(options);
    qq.recommended = std::move(recommended);
    qq.text = trim(joinFrom(h.rest, in, static_cast<long long>(k) + 1, textEnd));
    std::optional<std::size_t> answer;
    std::set<std::string> answered;
    for (std::size_t m : answerLines) {
      if (startsWith(in[m], kAnswerLabel)) {
        if (!answer) answer = m;
        continue;
      }
      const auto label = individualAnswerLabel(in[m]);
      IndividualAnswer entry;
      entry.members = splitTime(splitTrimmed(label->first, ','),
                                entry.changedAt);
      for (const std::string& member : entry.members) {
        if (!answered.insert(member).second) {
          p.malformed.push_back("line " + std::to_string(b.start + m) + ": " +
                                member + " already answered " + h.id +
                                "; a member answers a question at most once "
                                "(SOM \xC2\xA7"
                                "11.9.8)");
        }
      }
      std::size_t end = answerEnd(m);
      while (end > m && isBlank(in[end])) end--;
      entry.line = b.start + m;
      entry.end = b.start + end;
      entry.answer = answerText(m, label->second);
      qq.answers.push_back(std::move(entry));
    }
    if (answer) qq.answer = answerText(*answer, kAnswerLabel.size());
    qq.header = b.start + k;
    qq.regionEnd = b.start + regionEnd;
    if (answer) qq.answerLine = b.start + *answer;
    qq.id = h.id;
    qq.topic = h.topic;
    qq.starred = h.starred;
    p.questions.push_back(std::move(qq));
  }
}

/* `- (base) …`: the base line of a conflict block; its text, or nullopt for
 * any other line. */
std::optional<std::string> conflictBaseLine(const std::string& l) {
  const std::string head = "- (base)";
  if (!startsWith(l, head)) return std::nullopt;
  if (l.size() == head.size()) return std::string();
  if (l[head.size()] != ' ') return std::nullopt;
  return l.substr(head.size() + 1);
}

/* `- (a) **alice, bob:** …`: a lettered alternative of a conflict block. */
struct AlternativeLine {
  std::string letter;
  std::string members;  // the text between `**` and `:**`, empty without one
  std::string text;
};

std::optional<AlternativeLine> conflictAlternativeLine(const std::string& l) {
  if (l.size() < 5 || !startsWith(l, "- (") || !isLetter(l[3]) || l[4] != ')') {
    return std::nullopt;
  }
  AlternativeLine out;
  out.letter = l.substr(3, 1);
  const std::string r = l.substr(5);
  // ` **<members>:**`: the members hold no `*`, so the label ends at the
  // first `*` after the opening `**`.
  if (startsWith(r, " **")) {
    const std::size_t star = r.find('*', 3);
    if (star != std::string::npos && star > 3 && r[star - 1] == ':' &&
        star + 1 < r.size() && r[star + 1] == '*') {
      const std::string after = r.substr(star + 2);
      if (after.empty() || after[0] == ' ') {
        out.members = r.substr(3, star - 4);
        out.text = after.empty() ? after : after.substr(1);
        return out;
      }
    }
  }
  if (!r.empty() && r[0] != ' ') return std::nullopt;
  out.text = r.empty() ? r : r.substr(1);
  return out;
}

/* The header after the marker, `**X-<n> — <topic>:** <text>`: id, topic and
 * text; nullopt when malformed. The topic is the shortest that a `:**` ends
 * at the end of the line or before a space. */
std::optional<std::array<std::string, 3>> conflictHeader(const std::string& h) {
  if (!startsWith(h, "**X-")) return std::nullopt;
  std::size_t i = 4;
  if (i >= h.size() || h[i] < '1' || h[i] > '9') return std::nullopt;
  while (i < h.size() && h[i] >= '0' && h[i] <= '9') i++;
  if (!startsWith(h, kEmDashSep, i)) return std::nullopt;
  const std::string id = h.substr(2, i - 2);
  const std::size_t topicStart = i + kEmDashSep.size();
  for (std::size_t q = topicStart + 1; q + 3 <= h.size(); q++) {
    if (h.compare(q, 3, ":**") != 0) continue;
    const std::string after = h.substr(q + 3);
    if (!after.empty() && after[0] != ' ') continue;
    return std::array<std::string, 3>{
        id, h.substr(topicStart, q - topicStart),
        trim(after.empty() ? after : after.substr(1))};
  }
  return std::nullopt;
}

/* A conflict block (SOM §11.9.8): the header, the `(base)` line and the
 * lettered alternatives — each continuing on lines indented under it, its line
 * breaks kept — then `**Decision:**`. A malformed header leaves the block
 * unlisted; a missing base line or alternative is a finding. */
void parseConflict(Parsed& p, std::size_t bi) {
  const Block b = p.blocks[bi];
  std::vector<std::string> in;
  for (std::size_t k = b.start; k <= b.end; k++)
    in.push_back(innerOf(p.lines[k]));
  std::string rest = in[0].substr(kScales.size());
  if (startsWith(rest, kVs16)) rest = rest.substr(kVs16.size());
  const auto header = conflictHeader(trimLeft(rest));
  Conflict c;
  c.block = bi;
  if (header) {
    c.id = (*header)[0];
    c.topic = (*header)[1];
    c.text = (*header)[2];
  } else {
    p.malformed.push_back("line " + std::to_string(b.start) +
                          ": conflict header is not \"\xE2\x9A\x96\xEF\xB8\x8F "
                          "**X-<n> \xE2\x80\x94 <topic>:**\" (SOM \xC2\xA7"
                          "11.9.8)");
  }
  std::size_t decisionLine = in.size();
  for (std::size_t k = 1; k < in.size(); k++) {
    if (startsWith(in[k], kDecisionLabel)) {
      decisionLine = k;
      break;
    }
  }
  // The open entry: the base (no letter) or an alternative.
  bool open = false;
  std::optional<std::string> letter;
  std::vector<std::string> members;
  std::vector<std::string> lines;
  auto close = [&]() {
    if (!open) return;
    const std::string text = trim(joinLines(lines));
    if (!letter) {
      c.base = text;
    } else {
      c.alternatives.push_back({*letter, members, text});
    }
    open = false;
  };
  for (std::size_t k = 1; k < decisionLine; k++) {
    const std::string& l = in[k];
    if (const auto base = conflictBaseLine(l)) {
      close();
      open = true;
      letter.reset();
      members.clear();
      lines = {*base};
    } else if (const auto alt = conflictAlternativeLine(l)) {
      close();
      open = true;
      letter = alt->letter;
      members.clear();
      for (const std::string& m : splitTrimmed(alt->members, ',')) {
        if (!m.empty()) members.push_back(m);
      }
      lines = {alt->text};
    } else if (open && startsWith(l, " ")) {
      lines.push_back(startsWith(l, "  ") ? l.substr(2) : lstrip(l));
    } else {
      close();
    }
  }
  close();
  if (decisionLine < in.size()) {
    c.decision = trim(joinFrom(in[decisionLine].substr(kDecisionLabel.size()),
                               in, static_cast<long long>(decisionLine) + 1,
                               static_cast<long long>(in.size()) - 1));
  }
  if (header && !c.base) {
    p.malformed.push_back("line " + std::to_string(b.start) + ": conflict " +
                          *c.id +
                          " has no \"(base)\" line (SOM \xC2\xA7"
                          "11.9.8)");
  }
  if (header && c.alternatives.empty()) {
    p.malformed.push_back("line " + std::to_string(b.start) + ": conflict " +
                          *c.id +
                          " has no lettered alternative (SOM \xC2\xA7"
                          "11.9.8)");
  }
  p.blocks[bi].conflict = p.conflicts.size();
  p.conflicts.push_back(std::move(c));
}

bool containsOpener(const std::string& s) {
  for (const char* o : kOpeners) {
    if (s.find(o) != std::string::npos) return true;
  }
  return false;
}

/* The offset of the first blank line's start after `from` (the paragraph
 * end), or the text length. */
std::size_t paragraphEnd(const std::string& text, std::size_t from) {
  std::size_t i = text.find('\n', from);
  while (i != std::string::npos) {
    std::size_t next = text.find('\n', i + 1);
    std::size_t le = next == std::string::npos ? text.size() : next;
    if (isBlank(text.substr(i + 1, le - i - 1))) return i;
    i = next;
  }
  return text.size();
}

/* Whether a code point is whitespace as JavaScript's `\s` reads it. */
bool isJsSpace(unsigned long c) { return c != 0x85 && dartIsSpace(c); }

/* `s` split into its runs of non-whitespace. */
std::vector<std::string> splitWords(const std::string& s) {
  std::vector<std::string> out;
  std::string word;
  std::size_t i = 0;
  while (i < s.size()) {
    const std::size_t st = i;
    const unsigned long c = nextCp(s, i, s.size());
    if (isJsSpace(c)) {
      if (!word.empty()) out.push_back(word);
      word.clear();
    } else {
      word += s.substr(st, i - st);
    }
  }
  if (!word.empty()) out.push_back(word);
  return out;
}

/* Whether a mark kind is a change, which alone takes votes (SOM §11.9.8). */
bool isChangeMark(SpecMarkKind kind) {
  return kind == SpecMarkKind::Insertion || kind == SpecMarkKind::Deletion ||
         kind == SpecMarkKind::Substitution;
}

/* The members of a token's inside, `<authors>[ <votes>][ <time>]`, into `m`;
 * or the reason it breaks the grammar of SOM §11.9.8 (then `m`'s authors and
 * votes are left alone; its change time is still read). */
std::optional<std::string> readToken(const std::string& inside, Mark& m) {
  // A space after a comma is allowed: `,` and the whitespace after it is one
  // separator.
  std::string joined;
  for (std::size_t i = 0; i < inside.size();) {
    joined += inside[i];
    if (inside[i++] != ',') continue;
    std::size_t j = i;
    bool any = false;
    while (j < inside.size()) {
      std::size_t q = j;
      if (!isJsSpace(nextCp(inside, q, inside.size()))) break;
      j = q;
      any = true;
    }
    if (any) i = j;
  }
  std::vector<std::string> words = splitWords(joined);
  if (words.empty()) return std::string("is empty");
  // A trailing change time (SOM §11.9.10) is read off first; the rest are
  // the authors and votes, and a time-only token is valid.
  if (isReviewTime(words.back())) {
    m.changedAt = words.back();
    words.pop_back();
  }
  if (words.empty()) {
    m.authors.clear();
    m.votes.clear();
    return std::nullopt;
  }
  std::vector<std::string> authors;
  std::vector<SpecMarkVote> votes;
  std::size_t k = 0;
  if (words[0][0] != '+' && words[0][0] != '-') {
    std::size_t from = 0;
    while (true) {
      const std::size_t at = words[0].find(',', from);
      authors.push_back(words[0].substr(
          from, at == std::string::npos ? std::string::npos : at - from));
      if (at == std::string::npos) break;
      from = at + 1;
    }
    k = 1;
  }
  for (; k < words.size(); k++) {
    const std::string& w = words[k];
    if (w[0] != '+' && w[0] != '-')
      return "has \"" + w + "\" where a vote belongs";
    votes.push_back({w.substr(1), w[0] == '+'});
  }
  std::set<std::string> seen;
  std::vector<std::string> ids = authors;
  for (const SpecMarkVote& v : votes) ids.push_back(v.member);
  for (const std::string& id : ids) {
    if (!isReviewMemberId(id))
      return "names \"" + id + "\", which is not a member id";
    if (!seen.insert(id).second)
      return "names " + id + " twice, or as author and voter";
  }
  if (!votes.empty() && !isChangeMark(m.kind)) {
    return std::string("carries votes on a ") + specMarkKindName(m.kind) +
           " mark, which takes authors only";
  }
  m.authors = std::move(authors);
  m.votes = std::move(votes);
  return std::nullopt;
}

/* Reads the attribution token `{@…}` at `at` (SOM §11.9.8) into `m`, which it
 * directly follows, and returns the segment offset after it. The token is part
 * of the mark — its markup, its decision — so `m.end` moves past it. A token
 * that breaks the grammar is still part of the mark (it goes with the mark on
 * a decision) and is a finding; its members are then not listed. */
std::size_t attachToken(Parsed& p, const std::string& seg, std::size_t at,
                        std::size_t base, Mark& m) {
  const std::size_t lineEnd = seg.find('\n', at);
  const std::size_t close = seg.find('}', at + 2);
  if (close == std::string::npos ||
      (lineEnd != std::string::npos && close > lineEnd)) {
    p.malformed.push_back(
        "line " + std::to_string(m.line) +
        ": attribution token \"{@\" is not closed (SOM \xC2\xA7"
        "11.9.8)");
    return at;
  }
  if (const auto why = readToken(seg.substr(at + 2, close - at - 2), m)) {
    p.malformed.push_back("line " + std::to_string(m.line) +
                          ": attribution token " + *why +
                          " (SOM \xC2\xA7"
                          "11.9.8)");
  }
  m.end = base + close + 1;
  return close + 1;
}

bool isBlankChar(char c) { return c == ' ' || c == '\t'; }

/* How reading a change comment's quote ended. */
enum class QuoteRead { None, Quote, Unclosed, NoArrow };

/* Reads the quote at the start of a comment mark's inner text `s`, whose
 * first byte is at value offset `at`, into `q`: `Quote`, `None` when `s`
 * opens no quote, or the issue (`Unclosed`, `NoArrow`) of one that is
 * malformed (SOM §11.9.3). */
QuoteRead readQuote(const std::string& s, std::size_t at, Quote& q) {
  std::size_t a = 0;
  while (a < s.size() && std::string(" \t\r\n").find(s[a]) != std::string::npos)
    a++;
  if (a + 3 > s.size() || s[a] != '[') return QuoteRead::None;
  const std::string d = s.substr(a + 1, 2);
  SpecMarkKind kind;
  if (d == "++") {
    kind = SpecMarkKind::Insertion;
  } else if (d == "--") {
    kind = SpecMarkKind::Deletion;
  } else if (d == "~~") {
    kind = SpecMarkKind::Substitution;
  } else {
    return QuoteRead::None;
  }
  std::size_t j = s.find(d, a + 3);
  while (j != std::string::npos) {
    std::size_t t = j + 2;
    while (t < s.size() && isBlankChar(s[t])) t++;
    std::optional<std::string> outcome;
    std::size_t close = std::string::npos;
    if (t < s.size() && s[t] == ']') {
      close = t;
    } else if (t < s.size() && s[t] == '|') {
      t++;
      while (t < s.size() && isBlankChar(s[t])) t++;
      for (const char* w : {"accepted", "rejected"}) {
        if (!startsWith(s, w, t)) continue;
        std::size_t u = t + std::string(w).size();
        while (u < s.size() && isBlankChar(s[u])) u++;
        if (u < s.size() && s[u] == ']') {
          outcome = w;
          close = u;
        }
        break;
      }
    }
    if (close != std::string::npos) {
      const std::string body = s.substr(a + 3, j - a - 3);
      q = Quote();
      q.kind = kind;
      switch (kind) {
        case SpecMarkKind::Insertion:
          q.newText = trim(body);
          break;
        case SpecMarkKind::Deletion:
          q.oldText = trim(body);
          break;
        default: {
          const std::size_t arrow = body.find("~>");
          if (arrow == std::string::npos) return QuoteRead::NoArrow;
          q.oldText = trim(body.substr(0, arrow));
          q.newText = trim(body.substr(arrow + 2));
        }
      }
      q.outcome = outcome;
      q.delimEnd = at + j + 2;
      q.end = at + close + 1;
      q.comment = trim(s.substr(close + 1));
      return QuoteRead::Quote;
    }
    j = s.find(d, j + 1);
  }
  return QuoteRead::Unclosed;
}

std::string markReplacement(const Mark& m, bool accept);

/* Links each change comment to the change written directly before it whose
 * kind and texts it quotes (SOM §11.9.3). */
void attachChangeComments(Parsed& p) {
  for (std::size_t k = 1; k < p.marks.size(); k++) {
    if (!p.marks[k].quote) continue;
    const Quote& q = p.quotes[*p.marks[k].quote];
    Mark& c = p.marks[k - 1];
    if (q.outcome || !isChangeMark(c.kind)) continue;
    if (c.end != p.marks[k].start || c.kind != q.kind) continue;
    if (markReplacement(c, false) != q.oldText ||
        markReplacement(c, true) != q.newText) {
      continue;
    }
    p.marks[k].changeIndex = k - 1;
    c.commentIndex = k;
  }
}

void scanSegment(Parsed& p, const std::string& seg, std::size_t base,
                 const std::vector<std::size_t>& lineStart) {
  auto lineOf = [&](std::size_t offset) {
    std::size_t lo = 0;
    for (std::size_t k = 0; k < lineStart.size(); k++) {
      if (lineStart[k] <= offset) lo = k;
    }
    return lo;
  };
  std::size_t i = 0;
  while (i < seg.size()) {
    char c = seg[i];
    if (c == '`') {
      std::size_t n = 0;
      while (i + n < seg.size() && seg[i + n] == '`') n++;
      // Find the next run of exactly n backticks.
      std::size_t j = i + n;
      std::optional<std::size_t> closeAt;
      while (j < seg.size()) {
        if (seg[j] == '`') {
          std::size_t m = 0;
          while (j + m < seg.size() && seg[j + m] == '`') m++;
          if (m == n) {
            closeAt = j;
            break;
          }
          j += m;
        } else {
          j++;
        }
      }
      i = closeAt ? *closeAt + n : i + n;
      continue;
    }
    if (c == '{' && startsWith(seg, "{@", i)) {
      // A token that no mark precedes directly (a mark's own token is read
      // with the mark, below).
      p.malformed.push_back("line " + std::to_string(lineOf(base + i)) +
                            ": an attribution token \"{@\" does not follow a "
                            "mark directly (SOM \xC2\xA7"
                            "11.9.8)");
      const std::size_t close = seg.find('}', i + 2);
      i = close == std::string::npos ? i + 2 : close + 1;
      continue;
    }
    if (c != '{' || i + 3 > seg.size()) {
      i++;
      continue;
    }
    int oi = -1;
    for (int o = 0; o < 5; o++) {
      if (seg.compare(i, 3, kOpeners[o]) == 0) {
        oi = o;
        break;
      }
    }
    if (oi < 0) {
      i++;
      continue;
    }
    const std::size_t close = seg.find(kClosers[oi], i + 3);
    const std::size_t pend = paragraphEnd(seg, i);
    const std::size_t line = lineOf(base + i);
    if (close == std::string::npos || close > pend) {
      p.malformed.push_back("line " + std::to_string(line) +
                            ": inline mark \"" + kOpeners[oi] +
                            "\" is not closed in its paragraph (SOM \xC2\xA7"
                            "11.9.3)");
      p.markIssues.emplace_back(line, "unclosed");
      i += 3;
      continue;
    }
    const std::string inner = seg.substr(i + 3, close - i - 3);
    if (containsOpener(inner)) {
      p.malformed.push_back("line " + std::to_string(line) +
                            ": inline marks do not nest (SOM \xC2\xA7"
                            "11.9.3)");
      p.markIssues.emplace_back(line, "nested");
      i = close + 3;
      continue;
    }
    std::size_t end = close + 3;
    Mark m;
    m.start = base + i;
    m.line = line;
    switch (oi) {
      case 0: {
        m.kind = SpecMarkKind::Comment;
        m.comment = trim(inner);
        Quote q;
        switch (readQuote(inner, base + i + 3, q)) {
          case QuoteRead::Quote:
            m.quote = p.quotes.size();
            p.quotes.push_back(std::move(q));
            break;
          case QuoteRead::Unclosed:
            p.malformed.push_back(
                "line " + std::to_string(line) +
                ": the quote of a change comment is not closed; it is read "
                "as a plain comment (SOM \xC2\xA7"
                "11.9.3)");
            break;
          case QuoteRead::NoArrow:
            p.malformed.push_back(
                "line " + std::to_string(line) +
                ": the quote of a change comment has no \"~>\"; it is read "
                "as a plain comment (SOM \xC2\xA7"
                "11.9.3)");
            break;
          case QuoteRead::None:
            break;
        }
        break;
      }
      case 1:
        m.kind = SpecMarkKind::Highlight;
        m.text = trim(inner);
        if (startsWith(seg, "{>>", end)) {
          std::size_t c2 = seg.find("<<}", end + 3);
          if (c2 != std::string::npos && c2 <= paragraphEnd(seg, end)) {
            const std::string ci = seg.substr(end + 3, c2 - end - 3);
            if (!containsOpener(ci)) {
              m.comment = trim(ci);
              end = c2 + 3;
            }
          }
        }
        break;
      case 2:
        m.kind = SpecMarkKind::Insertion;
        m.text = trim(inner);
        break;
      case 3:
        m.kind = SpecMarkKind::Deletion;
        m.text = trim(inner);
        break;
      default: {
        std::size_t arrow = inner.find("~>");
        if (arrow == std::string::npos) {
          p.malformed.push_back("line " + std::to_string(line) +
                                ": a substitution has no \"~>\" (SOM \xC2\xA7"
                                "11.9.3)");
          p.markIssues.emplace_back(line, "noArrow");
          i = end;
          continue;
        }
        m.kind = SpecMarkKind::Substitution;
        m.text = trim(inner.substr(0, arrow));
        m.newText = trim(inner.substr(arrow + 2));
        break;
      }
    }
    m.end = base + end;
    m.bodyEnd = m.end;
    if (startsWith(seg, "{@", end)) end = attachToken(p, seg, end, base, m);
    p.marks.push_back(std::move(m));
    i = end;
  }
}

void parseMarks(Parsed& p) {
  std::vector<std::size_t> lineStart;
  std::size_t off = 0;
  for (const std::string& l : p.lines) {
    lineStart.push_back(off);
    off += l.size() + 1;
  }
  const std::string value = joinLines(p.lines);
  std::size_t k = 0;
  while (k < p.lines.size()) {
    if (p.code[k]) {
      k++;
      continue;
    }
    // A run of non-code lines is scanned as one segment.
    std::size_t segStartLine = k;
    while (k < p.lines.size() && !p.code[k]) k++;
    std::size_t segStart = lineStart[segStartLine];
    std::size_t segEnd = lineStart[k - 1] + p.lines[k - 1].size();
    scanSegment(p, value.substr(segStart, segEnd - segStart), segStart,
                lineStart);
  }
  attachChangeComments(p);
}

Parsed parse(const std::string& value) {
  Parsed p;
  p.lines = splitLines(value);
  p.code = codeLines(p.lines);
  std::size_t i = 0;
  const std::size_t n = p.lines.size();
  while (i < n) {
    if (p.code[i] || !isQuoteLine(p.lines[i])) {
      i++;
      continue;
    }
    std::size_t s = i;
    while (i + 1 < n && !p.code[i + 1] && isQuoteLine(p.lines[i + 1])) i++;
    std::size_t e = i;
    const std::string first = innerOf(p.lines[s]);
    if (startsWith(first, kArrow)) {
      Block b;
      b.start = s;
      b.end = e;
      b.kind = SpecReviewAnnotationKind::Comment;
      b.comment = p.comments.size();
      p.blocks.push_back(b);
      parseComment(p, p.blocks.size() - 1);
    } else if (startsWith(first, kQuestionOpen)) {
      Block b;
      b.start = s;
      b.end = e;
      b.kind = SpecReviewAnnotationKind::Question;
      p.blocks.push_back(b);
      parseQuestions(p, p.blocks.size() - 1);
    } else if (startsWith(first, kScales)) {
      Block b;
      b.start = s;
      b.end = e;
      b.kind = SpecReviewAnnotationKind::Conflict;
      p.blocks.push_back(b);
      parseConflict(p, p.blocks.size() - 1);
    }
    i = e + 1;
  }
  parseMarks(p);
  return p;
}

/* The annotations of one value, in order: by line, blocks before marks, marks
 * in scan order. */
void annotationsOf(const Parsed& p, const std::string& path,
                   const std::optional<std::string>& field,
                   const std::optional<std::string>& qualifier,
                   std::vector<SpecReviewAnnotation>& out) {
  struct Ordered {
    std::size_t line;
    int rank;
    std::size_t seq;
    SpecReviewAnnotation a;
  };
  std::vector<Ordered> o;
  std::size_t seq = 0;
  auto base = [&](SpecReviewAnnotationKind kind, std::size_t line) {
    SpecReviewAnnotation a;
    a.kind = kind;
    a.path = path;
    a.field = field;
    a.line = line;
    return a;
  };
  for (const Block& b : p.blocks) {
    if (b.kind == SpecReviewAnnotationKind::Comment) {
      const Comment& c = p.comments[b.comment];
      SpecReviewAnnotation a = base(SpecReviewAnnotationKind::Comment, b.start);
      a.id = c.id;
      if (qualifier && c.id) a.qualifiedId = *qualifier + " " + *c.id;
      a.author = c.author;
      a.text = c.text;
      a.context = c.context;
      a.changedAt = c.changedAt;
      o.push_back({b.start, 0, seq++, std::move(a)});
    } else if (b.kind == SpecReviewAnnotationKind::Conflict) {
      const Conflict& c = p.conflicts[b.conflict];
      if (!c.id) continue;
      SpecReviewAnnotation a =
          base(SpecReviewAnnotationKind::Conflict, b.start);
      a.id = c.id;
      if (qualifier) a.qualifiedId = *qualifier + " " + *c.id;
      a.topic = c.topic;
      a.text = c.text;
      a.base = c.base.value_or("");
      a.alternatives = c.alternatives;
      a.answer = c.decision;
      o.push_back({b.start, 0, seq++, std::move(a)});
    } else {
      for (std::size_t qi = 0; qi < b.qLen; qi++) {
        const Question& q = p.questions[b.qFirst + qi];
        SpecReviewAnnotation a =
            base(SpecReviewAnnotationKind::Question, q.header);
        a.id = q.id;
        a.topic = q.topic;
        a.starred = q.starred;
        a.combined = b.combined;
        a.text = q.text;
        a.answer = q.answer;
        a.options = q.options;
        a.recommended = q.recommended;
        for (const IndividualAnswer& ia : q.answers) {
          a.answers.push_back({ia.members, ia.answer, ia.changedAt});
        }
        o.push_back({q.header, 0, seq++, std::move(a)});
      }
    }
  }
  for (const Mark& m : p.marks) {
    SpecReviewAnnotation a = base(SpecReviewAnnotationKind::Mark, m.line);
    a.markKind = m.kind;
    a.text = m.text;
    a.newText = m.newText;
    a.comment = m.comment;
    a.authors = m.authors;
    a.votes = m.votes;
    a.changedAt = m.changedAt;
    o.push_back({m.line, 1, seq++, std::move(a)});
  }
  std::sort(o.begin(), o.end(), [](const Ordered& x, const Ordered& y) {
    if (x.line != y.line) return x.line < y.line;
    if (x.rank != y.rank) return x.rank < y.rank;
    return x.seq < y.seq;
  });
  for (Ordered& e : o) out.push_back(std::move(e.a));
}

/* The last line of every paragraph of a value, blank-separated and
 * fence-aware (a blank line inside a fenced block does not split). */
std::vector<std::pair<std::size_t, std::size_t>> paragraphRanges(
    const std::vector<std::string>& lines, const std::vector<bool>& code) {
  std::vector<std::pair<std::size_t, std::size_t>> out;
  std::size_t k = 0;
  while (k < lines.size()) {
    if (isBlank(lines[k]) && !code[k]) {
      k++;
      continue;
    }
    const std::size_t s = k;
    while (k + 1 < lines.size() && !(isBlank(lines[k + 1]) && !code[k + 1])) k++;
    out.emplace_back(s, k);
    k++;
  }
  return out;
}

std::vector<std::size_t> paragraphEnds(const std::vector<std::string>& lines,
                                       const std::vector<bool>& code) {
  std::vector<std::size_t> out;
  for (const auto& r : paragraphRanges(lines, code)) out.push_back(r.second);
  return out;
}

/* Inserts `block` after value line `end` (-1: at the start), one blank line
 * on each side. */
std::string insertAfterLine(const std::string& value, long long end,
                            const std::vector<std::string>& block) {
  if (value.empty()) return joinLines(block);
  const std::vector<std::string> lines = splitLines(value);
  const std::size_t rest = static_cast<std::size_t>(end + 1);
  std::vector<std::string> out(lines.begin(), lines.begin() + rest);
  if (rest > 0) out.push_back("");
  out.insert(out.end(), block.begin(), block.end());
  if (rest < lines.size()) {
    if (!isBlank(lines[rest])) out.push_back("");
    out.insert(out.end(), lines.begin() + rest, lines.end());
  }
  return joinLines(out);
}

/* Removes value lines [s, e] and one adjacent blank line. */
std::string removeLines(const std::string& value, std::size_t s, std::size_t e) {
  std::vector<std::string> lines = splitLines(value);
  std::size_t from = s, to = e;
  if (to + 1 < lines.size() && isBlank(lines[to + 1])) {
    to++;
  } else if (from >= 1 && isBlank(lines[from - 1])) {
    from--;
  }
  lines.erase(lines.begin() + from, lines.begin() + to + 1);
  const std::string out = joinLines(lines);
  return isBlank(out) ? "" : out;
}

/* `t[from..]` quoted: `>` for an empty line, else `> line`. */
std::vector<std::string> quoted(const std::vector<std::string>& t,
                                std::size_t from) {
  std::vector<std::string> out;
  for (std::size_t k = from; k < t.size(); k++) {
    out.push_back(t[k].empty() ? ">" : "> " + t[k]);
  }
  return out;
}

bool isSp(char c) { return c == ' ' || c == '\t'; }

std::string trimEndSpaces(const std::string& s) {
  std::size_t k = s.size();
  while (k > 0 && isSp(s[k - 1])) k--;
  return s.substr(0, k);
}

std::string trimStartSpaces(const std::string& s) {
  std::size_t k = 0;
  while (k < s.size() && isSp(s[k])) k++;
  return s.substr(k);
}

/* Applies a mark's replacement with the whitespace rules of SOM §11.9.3:
 * never join two words, never leave a double space or a space before
 * punctuation, and a mark that was a whole line leaves no blank line. */
std::string replaceMark(const std::string& value, const Mark& m,
                        std::string replacement) {
  std::string before = value.substr(0, m.start);
  std::string after = value.substr(m.end);
  if (replacement.empty()) {
    const std::string tb = trimEndSpaces(before);
    const std::string ta = trimStartSpaces(after);
    const bool lineStart = tb.empty() || tb.back() == '\n';
    const bool lineEnd = ta.empty() || ta[0] == '\n';
    if (lineStart && lineEnd) {
      // The mark was the whole line: the line goes, and with it one of the
      // newlines around it; a blank line left doubled is merged.
      before = tb;
      after = ta;
      if (!after.empty() && after[0] == '\n') {
        after = after.substr(1);
      } else if (!before.empty() && before.back() == '\n') {
        before.pop_back();
      }
      const bool endsBlank = before.size() >= 2 &&
                             before[before.size() - 1] == '\n' &&
                             before[before.size() - 2] == '\n';
      if ((before.empty() || endsBlank) && !after.empty() && after[0] == '\n') {
        after = after.substr(1);
      }
      if (after.empty()) {
        while (!before.empty() && before.back() == '\n') before.pop_back();
      }
      return before + after;
    }
    if (!before.empty() && isSp(before.back())) {
      if (!after.empty() && isSp(after[0])) {
        after = trimStartSpaces(after);
      } else if (after.empty() || after[0] == '\n' ||
                 std::string(".,;:!?)]}").find(after[0]) != std::string::npos) {
        before = trimEndSpaces(before);
      }
    } else if ((before.empty() || before.back() == '\n') && !after.empty() &&
               isSp(after[0])) {
      after = trimStartSpaces(after);
    }
    return before + after;
  }
  // Never join two words: a mark written flush against a word keeps a space
  // on that side.
  if (wordCharLast(before) && wordCharFirst(replacement)) {
    replacement = " " + replacement;
  }
  if (wordCharLast(replacement) && !after.empty() && wordCharFirst(after)) {
    replacement += " ";
  }
  return before + replacement + after;
}

std::string markReplacement(const Mark& m, bool accept) {
  switch (m.kind) {
    case SpecMarkKind::Insertion:
      return accept ? m.text : "";
    case SpecMarkKind::Deletion:
      return accept ? "" : m.text;
    case SpecMarkKind::Substitution:
      return accept ? *m.newText : m.text;
    case SpecMarkKind::Highlight:
      return m.text;
    case SpecMarkKind::Comment:
      return "";
  }
  return "";
}

/* One value of a document: (path, field or nullopt, text). */
struct Value {
  std::string path;
  std::optional<std::string> field;
  std::string text;
};

/* Every value, in document order. */
std::vector<Value> valuesOf(const SpecDocument& doc) {
  std::vector<Value> out;
  std::vector<std::string> paths = doc.contentPaths();
  std::sort(paths.begin(), paths.end());
  for (const std::string& path : paths) {
    out.push_back({path, std::nullopt, doc.content(path)});
  }
  paths = doc.formPaths();
  std::sort(paths.begin(), paths.end());
  for (const std::string& path : paths) {
    std::vector<std::string> fields = doc.formFieldNames(path);
    std::sort(fields.begin(), fields.end());
    for (const std::string& f : fields) {
      out.push_back({path, f, doc.formField(path, f)});
    }
  }
  return out;
}

std::string getValue(const SpecDocument& doc, const std::string& path,
                     const std::optional<std::string>& field) {
  return field ? doc.formField(path, *field) : doc.content(path);
}

void setValue(SpecDocument& doc, const std::string& path,
              const std::optional<std::string>& field,
              const std::string& value) {
  if (field) {
    doc.setFormField(path, *field, value);
  } else {
    doc.setContent(path, value);
  }
}

std::string jsonStrOrNull(const std::optional<std::string>& v) {
  return v ? jsonEncodeStr(*v) : "null";
}

/* A located comment or question: its value and the parse of it. */
struct Found {
  Value value;
  Parsed parsed;
  std::size_t index = 0;  // comment or question index in `parsed`
  std::size_t block = 0;
};

Found findComment(const SpecDocument& doc, const std::string& id) {
  for (Value& v : valuesOf(doc)) {
    Parsed p = parse(v.text);
    for (std::size_t ci = 0; ci < p.comments.size(); ci++) {
      if (p.comments[ci].id && *p.comments[ci].id == id) {
        std::size_t block = p.comments[ci].block;
        return Found{std::move(v), std::move(p), ci, block};
      }
    }
  }
  throw SpecReviewAnnotationError("no comment " + id + " in the document");
}

Found findQuestion(const SpecDocument& doc, const std::string& id) {
  for (Value& v : valuesOf(doc)) {
    Parsed p = parse(v.text);
    for (std::size_t bi = 0; bi < p.blocks.size(); bi++) {
      const Block& b = p.blocks[bi];
      if (b.kind != SpecReviewAnnotationKind::Question) continue;
      for (std::size_t qi = 0; qi < b.qLen; qi++) {
        if (p.questions[b.qFirst + qi].id == id) {
          std::size_t index = b.qFirst + qi;
          return Found{std::move(v), std::move(p), index, bi};
        }
      }
    }
  }
  throw SpecReviewAnnotationError("no question " + id + " in the document");
}

/* The last line of paragraph `afterParagraph` (-1 for -1). */
long long paragraphLastLine(const std::string& value, long long afterParagraph) {
  if (afterParagraph < 0) return -1;
  const std::vector<std::string> lines = splitLines(value);
  const std::vector<std::size_t> ends = paragraphEnds(lines, codeLines(lines));
  if (value.empty() ||
      static_cast<unsigned long long>(afterParagraph) >= ends.size()) {
    throw SpecReviewAnnotationError(
        "the value has " + std::to_string(value.empty() ? 0 : ends.size()) +
        " paragraph(s); there is no paragraph " + std::to_string(afterParagraph));
  }
  return static_cast<long long>(ends[static_cast<std::size_t>(afterParagraph)]);
}

/* ---- team reviews (SOM §11.9.8): individual answers, applying conflicts -- */

/* `s` with `count` bytes from `from` on, clamped like JavaScript's
 * `substring`. */
std::string clampedSub(const std::string& s, std::size_t from,
                       std::size_t count = std::string::npos) {
  return from >= s.size() ? std::string() : s.substr(from, count);
}

/* Whether an answer carries anything beyond an option letter (SOM §11.9.8):
 * `(a)` or `**(a)**`, optionally followed by exactly that option's text, is
 * not; an answer that starts with no letter is. */
bool isCommentedAnswer(const std::string& answer,
                       const std::vector<SpecQuestionOption>& options) {
  const std::optional<std::string> letter = leadingLetter(answer);
  if (!letter) return true;
  const std::string t = trimLeft(answer);
  const bool bold = startsWith(t, "**(") && clampedSub(t, 4, 3) == ")**";
  const std::string rest = trim(clampedSub(t, bold                  ? 7
                                              : startsWith(t, "**") ? 5
                                                                    : 3));
  if (rest.empty()) return false;
  for (const SpecQuestionOption& o : options) {
    if (o.letter == *letter) return rest != o.text;
  }
  return true;
}

/* The lines of one individual-answer entry. */
std::vector<std::string> individualAnswerLines(
    const std::vector<std::string>& members, const std::string& answer,
    const std::optional<std::string>& changedAt = std::nullopt) {
  const std::vector<std::string> a = splitLines(answer);
  std::string names;
  for (std::size_t i = 0; i < members.size(); i++) {
    if (i > 0) names += ", ";
    names += members[i];
  }
  if (changedAt) names += (members.empty() ? "" : ", ") + *changedAt;
  std::vector<std::string> out{
      trimRight("> **Answer (" + names + "):** " + a[0])};
  for (std::string& l : quoted(a, 1)) out.push_back(std::move(l));
  return out;
}

/* `value` with member `member`'s individual answer to question `q` set to
 * `answer` (SOM §11.9.8): the member leaves the line it was on (a line left
 * empty goes); a non-empty answer that is not commented joins the line whose
 * answer is identical and not commented, at its end, and otherwise gets a new
 * line after the last individual answer. The first individual answer opens
 * the run before the team's `**Answer:**`, with a `>` line between run and
 * team answer, and a run left empty takes that line with it. Entries left
 * alone keep their bytes. */
std::string setIndividualAnswer(
    const std::string& value, const Question& q, const std::string& member,
    const std::string& answer,
    const std::optional<std::string>& changedAt = std::nullopt) {
  std::vector<std::string> lines = splitLines(value);
  struct Entry {
    std::vector<std::string> members;
    std::string answer;
    std::optional<std::vector<std::string>> lines;  // nullopt: rewrite it
    std::optional<std::string> changedAt;
  };
  std::vector<Entry> kept;
  for (const IndividualAnswer& a : q.answers) {
    Entry e{a.members, a.answer,
            std::vector<std::string>(lines.begin() + a.line,
                                     lines.begin() + a.end + 1),
            a.changedAt};
    const auto at = std::find(e.members.begin(), e.members.end(), member);
    if (at != e.members.end()) {
      e.members.erase(at);
      e.lines.reset();
    }
    if (!e.members.empty()) kept.push_back(std::move(e));
  }
  const std::string text = trim(answer);
  if (!text.empty()) {
    Entry* join = nullptr;
    if (!isCommentedAnswer(text, q.options)) {
      for (Entry& e : kept) {
        if (e.answer == text && e.changedAt == changedAt &&
            !isCommentedAnswer(e.answer, q.options)) {
          join = &e;
          break;
        }
      }
    }
    if (join != nullptr) {
      join->members.push_back(member);
      join->lines.reset();
    } else {
      kept.push_back({{member}, text, std::nullopt, changedAt});
    }
  }
  std::vector<std::string> run;
  for (const Entry& e : kept) {
    const std::vector<std::string> l =
        e.lines ? *e.lines
                : individualAnswerLines(e.members, e.answer, e.changedAt);
    run.insert(run.end(), l.begin(), l.end());
  }
  if (!q.answers.empty()) {
    const std::size_t from = q.answers.front().line;
    std::size_t to = q.answers.back().end;
    // A run left empty takes its separating `>` line with it.
    if (run.empty() && to + 1 < lines.size() &&
        isBlank(innerOf(lines[to + 1]))) {
      to++;
    }
    lines.erase(lines.begin() + from, lines.begin() + to + 1);
    lines.insert(lines.begin() + from, run.begin(), run.end());
  } else if (!run.empty()) {
    if (q.answerLine) {
      run.push_back(">");
      lines.insert(lines.begin() + *q.answerLine, run.begin(), run.end());
    } else {
      std::size_t last = q.regionEnd;
      while (last > q.header && isBlank(innerOf(lines[last]))) last--;
      run.insert(run.begin(), ">");
      lines.insert(lines.begin() + last + 1, run.begin(), run.end());
    }
  }
  return joinLines(lines);
}

/* Whether a conflict's topic names a structural conflict the merge writes
 * (SOM §11.9.9): its decision is not a text. */
bool isStructuralTopic(const std::string& topic) {
  return topic == "Item removed" || topic == "Item moved" ||
         topic == "Headline changed";
}

/* The text a conflict's decision chooses: the base, an alternative, or the
 * rewritten text. */
std::string chosenText(const Conflict& c) {
  const std::optional<std::string> letter = decisionLetterOf(c.decision);
  if (letter && *letter == "base") return c.base.value_or("");
  if (letter) {
    for (const SpecConflictAlternative& a : c.alternatives) {
      if (a.letter == *letter) return a.text;
    }
  }
  return c.decision;
}

/* Whether a paragraph starting at `start` opens an annotation block. */
bool opensBlock(const Parsed& p, std::size_t start) {
  for (const Block& b : p.blocks) {
    if (b.start == start) return true;
  }
  return false;
}

/* `value` with the lines `[s, e]` replaced by `text`. */
std::string replaceLines(const std::string& value, std::size_t s, std::size_t e,
                         const std::string& text) {
  std::vector<std::string> lines = splitLines(value);
  const std::vector<std::string> t = splitLines(text);
  lines.erase(lines.begin() + s, lines.begin() + e + 1);
  lines.insert(lines.begin() + s, t.begin(), t.end());
  return joinLines(lines);
}

/* `value` with the text paragraph directly before the block at `blockStart`
 * (annotation blocks between them skipped) replaced by `text`; with none,
 * `text` goes before the block. */
std::string replaceParagraphBefore(const std::string& value,
                                   std::size_t blockStart,
                                   const std::string& text) {
  const Parsed p = parse(value);
  std::optional<std::pair<std::size_t, std::size_t>> last;
  for (const auto& r : paragraphRanges(p.lines, p.code)) {
    if (r.second < blockStart && !opensBlock(p, r.first)) last = r;
  }
  if (!last) {
    return insertAfterLine(value, static_cast<long long>(blockStart) - 1,
                           splitLines(text));
  }
  return replaceLines(value, last->first, last->second, text);
}

/* `value` with the run of text paragraphs directly before the block at
 * `blockStart` — a whole-value unit (SOM §11.9.9) — replaced by `text`. */
std::string replaceTextRun(const std::string& value, std::size_t blockStart,
                           const std::string& text) {
  const Parsed p = parse(value);
  std::vector<std::pair<std::size_t, std::size_t>> paras;
  for (const auto& r : paragraphRanges(p.lines, p.code)) {
    if (r.second < blockStart) paras.push_back(r);
  }
  std::size_t k = paras.size();
  while (k > 0 && !opensBlock(p, paras[k - 1].first)) k--;
  if (k == paras.size()) {
    return insertAfterLine(value, static_cast<long long>(blockStart) - 1,
                           splitLines(text));
  }
  return replaceLines(value, paras[k].first, paras.back().second, text);
}

/* Whether `s` is two runs of non-whitespace separated by one space,
 * `<path> <field>`; the two runs into `a` and `b`. */
bool splitPathField(const std::string& s, std::string& a, std::string& b) {
  const std::vector<std::string> words = splitWords(s);
  if (words.size() != 2 || s != words[0] + " " + words[1]) return false;
  a = words[0];
  b = words[1];
  return true;
}

/* Whether `s` reads as a document path: no whitespace, no comma, and a `/`
 * with text on both sides. */
bool looksLikePath(const std::string& s) {
  if (s.find(',') != std::string::npos || splitWords(s).size() != 1 ||
      splitWords(s)[0] != s) {
    return false;
  }
  const std::size_t slash = s.find('/', 1);
  return slash != std::string::npos && slash + 1 < s.size();
}

}  // namespace

/* ---- names, JSON ---------------------------------------------------------- */

const char* specReviewAnnotationKindName(SpecReviewAnnotationKind kind) {
  switch (kind) {
    case SpecReviewAnnotationKind::Comment:
      return "comment";
    case SpecReviewAnnotationKind::Question:
      return "question";
    case SpecReviewAnnotationKind::Mark:
      return "mark";
    case SpecReviewAnnotationKind::Conflict:
      return "conflict";
  }
  return "";
}

bool isReviewMemberId(const std::string& s) {
  if (s.empty()) return false;
  for (char c : s) {
    if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_')) {
      return false;
    }
  }
  return true;
}

namespace {

bool isDigit(char c) { return c >= '0' && c <= '9'; }

/* Whether `s` holds `YYYY-MM-DDTHH:MM` at `at`. */
bool isMinutesAt(const std::string& s, std::size_t at) {
  static const char kShape[] = "dddd-dd-ddTdd:dd";
  if (s.size() < at + 16) return false;
  for (std::size_t i = 0; i < 16; i++) {
    const char c = s[at + i];
    if (kShape[i] == 'd' ? !isDigit(c) : c != kShape[i]) return false;
  }
  return true;
}

/* Whether `s` from `at` to its end is `Z` or `±HH:MM`. */
bool isOffsetAt(const std::string& s, std::size_t at) {
  if (s.size() == at + 1) return s[at] == 'Z';
  return s.size() == at + 6 && (s[at] == '+' || s[at] == '-') &&
         isDigit(s[at + 1]) && isDigit(s[at + 2]) && s[at + 3] == ':' &&
         isDigit(s[at + 4]) && isDigit(s[at + 5]);
}

}  // namespace

bool isReviewTime(const std::string& s) {
  return isMinutesAt(s, 0) && isOffsetAt(s, 16);
}

std::string normalizeReviewTime(const std::string& at) {
  const std::string t = trim(at);
  if (isMinutesAt(t, 0)) {
    std::size_t i = 16;
    // Optional seconds, and after them an optional fraction.
    if (i + 3 <= t.size() && t[i] == ':' && isDigit(t[i + 1]) &&
        isDigit(t[i + 2])) {
      i += 3;
      if (i + 1 < t.size() && t[i] == '.' && isDigit(t[i + 1])) {
        i++;
        while (i < t.size() && isDigit(t[i])) i++;
      }
    }
    if (isOffsetAt(t, i)) return t.substr(0, 16) + t.substr(i);
  }
  throw SpecReviewAnnotationError(
      "\"" + at +
      "\" is not an ISO 8601 time with an offset or Z "
      "(e.g. 2026-11-07T14:05+01:00)");
}

std::string systemReviewTime() {
  const std::time_t now = std::time(nullptr);
  std::tm local{};
  std::tm utc{};
#if defined(_WIN32)
  localtime_s(&local, &now);
  gmtime_s(&utc, &now);
#else
  localtime_r(&now, &local);
  gmtime_r(&now, &utc);
#endif
  // The offset is the local broken-down time minus the UTC one of the same
  // instant; the two are at most a day apart.
  long days = local.tm_yday - utc.tm_yday;
  if (local.tm_year != utc.tm_year) days = local.tm_year > utc.tm_year ? 1 : -1;
  const long offset =
      (days * 24 + (local.tm_hour - utc.tm_hour)) * 60 +
      (local.tm_min - utc.tm_min);
  char stamp[32];
  const std::size_t n = std::strftime(stamp, sizeof stamp, "%Y-%m-%dT%H:%M",
                                      &local);
  const long mins = offset < 0 ? -offset : offset;
  char zone[16];
  std::snprintf(zone, sizeof zone, "%c%02ld:%02ld", offset < 0 ? '-' : '+',
                mins / 60, mins % 60);
  return std::string(stamp, n) + zone;
}

namespace {

std::string jsonStrList(const std::vector<std::string>& v) {
  std::string b = "[";
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) b += ",";
    b += jsonEncodeStr(v[i]);
  }
  return b + "]";
}

template <class T>
std::string jsonList(const std::vector<T>& v) {
  std::string b = "[";
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) b += ",";
    b += v[i].toJson();
  }
  return b + "]";
}

}  // namespace

std::string SpecMarkVote::toJson() const {
  return "{\"member\":" + jsonEncodeStr(member) +
         ",\"vote\":" + jsonEncodeStr(accept ? "accept" : "reject") + "}";
}

std::optional<std::string> SpecIndividualAnswer::answerLetter() const {
  return leadingLetter(answer);
}

std::string SpecIndividualAnswer::toJson() const {
  return "{\"members\":" + jsonStrList(members) +
         ",\"answer\":" + jsonEncodeStr(answer) +
         ",\"answerLetter\":" + jsonStrOrNull(answerLetter()) +
         (changedAt ? ",\"changedAt\":" + jsonEncodeStr(*changedAt)
                    : std::string()) +
         "}";
}

std::string SpecConflictAlternative::toJson() const {
  return "{\"letter\":" + jsonEncodeStr(letter) +
         ",\"members\":" + jsonStrList(members) +
         ",\"text\":" + jsonEncodeStr(text) + "}";
}

const char* specMarkKindName(SpecMarkKind kind) {
  switch (kind) {
    case SpecMarkKind::Comment:
      return "comment";
    case SpecMarkKind::Highlight:
      return "highlight";
    case SpecMarkKind::Insertion:
      return "insertion";
    case SpecMarkKind::Deletion:
      return "deletion";
    case SpecMarkKind::Substitution:
      return "substitution";
  }
  return "";
}

std::string SpecQuestionOption::toJson() const {
  return "{\"letter\":" + jsonEncodeStr(letter) +
         ",\"text\":" + jsonEncodeStr(text) +
         ",\"bold\":" + (bold ? "true" : "false") + "}";
}

bool SpecReviewAnnotation::unresolved() const {
  return isUnresolvedAnswer(answer);
}

std::optional<std::string> SpecReviewAnnotation::answerLetter() const {
  if (kind != SpecReviewAnnotationKind::Question || unresolved()) {
    return std::nullopt;
  }
  return leadingLetter(answer);
}

std::optional<std::string> SpecReviewAnnotation::decisionLetter() const {
  if (kind != SpecReviewAnnotationKind::Conflict) return std::nullopt;
  return decisionLetterOf(answer);
}

std::string SpecReviewAnnotation::toJson(bool team) const {
  std::string b = "{\"kind\":" + jsonEncodeStr(specReviewAnnotationKindName(kind)) +
                  ",\"path\":" + jsonEncodeStr(path) +
                  ",\"field\":" + jsonStrOrNull(field) +
                  ",\"line\":" + std::to_string(line);
  switch (kind) {
    case SpecReviewAnnotationKind::Comment:
      b += ",\"id\":" + jsonStrOrNull(id) +
           ",\"qualifiedId\":" + jsonStrOrNull(qualifiedId) +
           ",\"author\":" + jsonStrOrNull(author) +
           ",\"text\":" + jsonEncodeStr(text) +
           ",\"context\":" + jsonEncodeStr(context);
      if (changedAt) b += ",\"changedAt\":" + jsonEncodeStr(*changedAt);
      break;
    case SpecReviewAnnotationKind::Question:
      b += ",\"id\":" + jsonStrOrNull(id) +
           ",\"topic\":" + jsonStrOrNull(topic) +
           ",\"starred\":" + (starred ? "true" : "false") +
           ",\"combined\":" + (combined ? "true" : "false") +
           ",\"text\":" + jsonEncodeStr(text) +
           ",\"answer\":" + jsonEncodeStr(answer) +
           ",\"open\":" + (open() ? "true" : "false");
      if (team)
        b +=
            std::string(",\"unresolved\":") + (unresolved() ? "true" : "false");
      b += ",\"options\":" + jsonList(options) +
           ",\"recommended\":" + jsonStrOrNull(recommended) +
           ",\"answerLetter\":" + jsonStrOrNull(answerLetter());
      if (team) b += ",\"answers\":" + jsonList(answers);
      break;
    case SpecReviewAnnotationKind::Conflict:
      b += ",\"id\":" + jsonStrOrNull(id) +
           ",\"qualifiedId\":" + jsonStrOrNull(qualifiedId) +
           ",\"topic\":" + jsonStrOrNull(topic) +
           ",\"text\":" + jsonEncodeStr(text) +
           ",\"base\":" + jsonEncodeStr(base) +
           ",\"alternatives\":" + jsonList(alternatives) +
           ",\"decision\":" + jsonEncodeStr(answer) +
           ",\"decisionLetter\":" + jsonStrOrNull(decisionLetter()) +
           ",\"open\":" + (open() ? "true" : "false") +
           ",\"unresolved\":" + (unresolved() ? "true" : "false");
      break;
    case SpecReviewAnnotationKind::Mark:
      b += std::string(",\"markKind\":") +
           (markKind ? jsonEncodeStr(specMarkKindName(*markKind)) : "null") +
           ",\"text\":" + jsonEncodeStr(text) +
           ",\"newText\":" + jsonStrOrNull(newText) +
           ",\"comment\":" + jsonStrOrNull(comment);
      if (changedAt) b += ",\"changedAt\":" + jsonEncodeStr(*changedAt);
      if (team) {
        b += ",\"authors\":" + jsonStrList(authors) +
             ",\"votes\":" + jsonList(votes);
      }
      break;
  }
  return b + "}";
}

std::string SpecReviewAnnotationCounts::toJson(bool team) const {
  std::string b =
      "{\"questions\":" + std::to_string(questions) +
      ",\"openQuestions\":" + std::to_string(openQuestions) +
      ",\"answeredQuestions\":" + std::to_string(answeredQuestions) +
      ",\"comments\":" + std::to_string(comments) +
      ",\"marks\":" + std::to_string(marks);
  if (team) {
    b += ",\"unresolvedQuestions\":" + std::to_string(unresolvedQuestions) +
         ",\"conflicts\":" + std::to_string(conflicts) +
         ",\"openConflicts\":" + std::to_string(openConflicts);
  }
  return b + "}";
}

/* ---- text level ----------------------------------------------------------- */

namespace {

/* A comment header's parentheses: the author and the change time, either
 * alone, or nullopt when there is neither (SOM §11.9.10). */
std::optional<std::string> authorAndTime(
    const std::optional<std::string>& author,
    const std::optional<std::string>& changedAt) {
  if (!author || author->empty()) return changedAt;
  return changedAt ? *author + ", " + *changedAt : *author;
}

}  // namespace

std::vector<std::string> formatCommentBlock(
    const std::string& id, const std::string& text,
    const std::optional<std::string>& author,
    const std::optional<std::string>& changedAt) {
  const std::vector<std::string> t = splitLines(text);
  std::string head = "> " + kArrow + kVs16 + " **" + id + "**";
  if (const auto who = authorAndTime(author, changedAt)) {
    head += " (" + *who + "):";
  }
  if (!t[0].empty()) head += " " + t[0];
  std::vector<std::string> out{head};
  for (std::string& l : quoted(t, 1)) out.push_back(std::move(l));
  return out;
}

std::vector<std::string> formatQuestionBlock(const SpecQuestionDraft& q) {
  const std::vector<std::string> t = splitLines(q.text);
  std::vector<std::string> lines{"> " + kQuestionOpen + " " + q.id + kEmDashSep +
                                 (q.starred ? kStar + " " : "") + q.topic +
                                 ":** " + t[0]};
  for (std::string& l : quoted(t, 1)) lines.push_back(std::move(l));
  for (const std::string& o : q.options) {
    if (q.recommended && o.size() >= 3 &&
        startsWith(o, "(" + *q.recommended + ")")) {
      lines.push_back("> - **(" + *q.recommended + ")**" + o.substr(3));
    } else {
      lines.push_back("> - " + o);
    }
  }
  if (!q.recommendation.empty() || !q.assumption.empty()) {
    lines.push_back(">");
    if (!q.recommendation.empty()) {
      lines.push_back("> *Recommendation:* " + q.recommendation);
    }
    if (!q.assumption.empty()) {
      lines.push_back("> *Working assumption until answered:* " + q.assumption);
    }
  }
  lines.push_back(">");
  lines.push_back("> " + kAnswerLabel);
  return lines;
}

std::string stripAnnotationsText(const std::string& value) {
  std::string v = value;
  // Blocks, from the last up, so earlier line numbers stay valid.
  while (true) {
    const Parsed p = parse(v);
    if (p.blocks.empty()) break;
    const Block& b = p.blocks.back();
    v = removeLines(v, b.start, b.end);
  }
  while (true) {
    const Parsed p = parse(v);
    if (p.marks.empty()) break;
    const Mark& m = p.marks.back();
    v = replaceMark(v, m, markReplacement(m, true));
  }
  return v;
}

std::string applyInlineMarksText(const std::string& value, bool accept) {
  std::string v = value;
  const Parsed p = parse(value);
  for (auto it = p.marks.rbegin(); it != p.marks.rend(); ++it) {
    v = replaceMark(v, *it, markReplacement(*it, accept));
  }
  return v;
}

namespace {

/* `value` with the outcome written into the quote `q`: everything from its
 * closing delimiter to its `]` becomes ` | accepted]` or ` | rejected]`. */
std::string recordOutcome(const std::string& value, const Quote& q,
                          bool accept) {
  return value.substr(0, q.delimEnd) +
         (accept ? " | accepted]" : " | rejected]") + value.substr(q.end);
}

/* `value` with the mark `k` of `p` decided; a change's attached comment
 * records the outcome (SOM §11.9.3). */
std::string decideMark(const std::string& value, const Parsed& p,
                       std::size_t k, bool accept) {
  const Mark& m = p.marks[k];
  std::string v = value;
  if (m.commentIndex) {
    v = recordOutcome(v, p.quotes[*p.marks[*m.commentIndex].quote], accept);
  }
  return replaceMark(v, m, markReplacement(m, accept));
}

/* Whether `t` holds a blank line: a newline, then only spaces, tabs and
 * carriage returns, then a newline. */
bool holdsBlankLine(const std::string& t) {
  for (std::size_t i = t.find('\n'); i != std::string::npos;
       i = t.find('\n', i + 1)) {
    std::size_t j = i + 1;
    while (j < t.size() && (t[j] == ' ' || t[j] == '\t' || t[j] == '\r')) j++;
    if (j < t.size() && t[j] == '\n') return true;
  }
  return false;
}

/* The trimmed `text` of an inline comment, refused when it is empty or holds
 * a mark delimiter or a blank line. */
std::string checkInlineComment(const std::string& text) {
  const std::string t = trim(text);
  if (t.empty()) throw SpecReviewAnnotationError("a comment needs text");
  if (containsOpener(t) || t.find("<<}") != std::string::npos ||
      holdsBlankLine(t)) {
    throw SpecReviewAnnotationError(
        "a comment cannot hold a mark delimiter or a blank line");
  }
  return t;
}

/* The whitespace of the change-comment anchors (SOM §11.9.3). */
bool isAnchorSpace(char c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

/* A UTF-8 continuation byte: anchors count characters, never bytes inside
 * one, so a comment is never written back into the middle of a character. */
bool isContinuation(char c) {
  return (static_cast<unsigned char>(c) & 0xC0) == 0x80;
}

std::size_t nonSpaceCount(const std::string& s) {
  std::size_t n = 0;
  for (char c : s) {
    if (!isAnchorSpace(c) && !isContinuation(c)) n++;
  }
  return n;
}

/* `setMarked` with the value's change comments kept (SOM §11.9.3): taken out
 * of the original, then written back where their anchor falls. */
SpecMarkedChange markKeepingChangeComments(const std::string& current,
                                           const std::string& text) {
  // 1. The original: every mark rejected except the change comments.
  std::string original = current;
  {
    const Parsed p = parse(current);
    for (std::size_t k = p.marks.size(); k-- > 0;) {
      if (p.marks[k].quote) continue;
      original =
          replaceMark(original, p.marks[k], markReplacement(p.marks[k], false));
    }
  }
  // 2. Each change comment's markup, anchor and leading space.
  const Parsed op = parse(original);
  std::vector<const Mark*> kept;
  for (const Mark& m : op.marks) {
    if (m.quote) kept.push_back(&m);
  }
  struct Anchor {
    std::string markup;
    std::size_t count;
    bool space;
  };
  std::vector<Anchor> anchors;
  std::size_t counted = 0;
  std::size_t from = 0;
  for (const Mark* m : kept) {
    counted += nonSpaceCount(original.substr(from, m->start - from));
    from = m->end;
    anchors.push_back({original.substr(m->start, m->end - m->start), counted,
                       m->start > 0 && isBlankChar(original[m->start - 1])});
  }
  // 3. Removed, compared.
  std::string base = original;
  for (auto it = kept.rbegin(); it != kept.rend(); ++it) {
    base = replaceMark(base, **it, "");
  }
  SpecMarkedChange result = markChangeText(base, text);
  if (anchors.empty()) return result;
  // 4. Written back where k non-whitespace characters have passed.
  const std::string& r = result.text;
  const Parsed rp = parse(r);
  auto place = [&](std::size_t k) -> std::size_t {
    if (k == 0) return 0;
    std::size_t n = 0;
    std::size_t i = 0;
    std::size_t mi = 0;
    while (i < r.size()) {
      if (mi < rp.marks.size() && rp.marks[mi].start == i) {
        const Mark& m = rp.marks[mi++];
        n += m.kind == SpecMarkKind::Insertion ? 0 : nonSpaceCount(m.text);
        i = m.end;
        if (n >= k) return i;
        continue;
      }
      if (!isAnchorSpace(r[i])) n++;
      i++;
      while (i < r.size() && isContinuation(r[i])) i++;
      if (n >= k) return i;
    }
    return r.size();
  };
  std::vector<std::size_t> at;
  for (const Anchor& a : anchors) at.push_back(place(a.count));
  std::string out = r;
  for (std::size_t j = anchors.size(); j-- > 0;) {
    out = out.substr(0, at[j]) + (anchors[j].space ? " " : "") +
          anchors[j].markup + out.substr(at[j]);
  }
  return {out, result.exact};
}

}  // namespace

std::string decideAllMarksText(const std::string& value, bool accept) {
  const Parsed p = parse(value);
  std::string v = value;
  for (std::size_t k = p.marks.size(); k-- > 0;) {
    if (p.marks[k].quote) continue;
    v = decideMark(v, p, k, accept);
  }
  return v;
}

std::vector<SpecValidationError> validateReviewAnnotations(
    const SpecDocument& doc) {
  std::vector<SpecValidationError> errors;
  std::set<std::string> seen;
  for (const Value& v : valuesOf(doc)) {
    const Parsed p = parse(v.text);
    const std::string where = v.field ? v.path + " / " + *v.field : v.path;
    for (const std::string& m : p.malformed) {
      errors.push_back({v.path, kSpecValidationCodeAnnotationMalformed,
                        where + ", " + m});
    }
    if (v.field) {
      for (const Block& b : p.blocks) {
        errors.push_back(
            {v.path, kSpecValidationCodeAnnotationMisplaced,
             where + ", line " + std::to_string(b.start) + ": a " +
                 specReviewAnnotationKindName(b.kind) +
                 " block sits in a form field value; it belongs in the "
                 "form's preamble, above the first field (SOM \xC2\xA7"
                 "11.9.4)"});
      }
    }
    std::vector<std::string> ids;
    for (const Comment& c : p.comments) {
      if (c.id) ids.push_back(*c.id);
    }
    for (const Block& b : p.blocks) {
      if (b.kind == SpecReviewAnnotationKind::Conflict) {
        if (p.conflicts[b.conflict].id)
          ids.push_back(*p.conflicts[b.conflict].id);
        continue;
      }
      if (b.kind != SpecReviewAnnotationKind::Question) continue;
      for (std::size_t qi = 0; qi < b.qLen; qi++) {
        ids.push_back(p.questions[b.qFirst + qi].id);
      }
    }
    for (const std::string& id : ids) {
      if (!seen.insert(id).second) {
        errors.push_back({v.path, kSpecValidationCodeDuplicateAnnotationId,
                          where + ": " + id +
                              " is used more than once in the document"});
      }
    }
  }
  std::stable_sort(errors.begin(), errors.end(),
                   [](const SpecValidationError& a,
                      const SpecValidationError& b) { return a.path < b.path; });
  return errors;
}

/* ---- document level ------------------------------------------------------- */

std::vector<SpecReviewAnnotation> SpecReviewAnnotations::list() const {
  std::vector<SpecReviewAnnotation> out;
  for (const Value& v : valuesOf(*doc_)) {
    annotationsOf(parse(v.text), v.path, v.field, qualifier_, out);
  }
  return out;
}

SpecReviewAnnotationCounts SpecReviewAnnotations::counts() const {
  SpecReviewAnnotationCounts c;
  for (const SpecReviewAnnotation& a : list()) {
    switch (a.kind) {
      case SpecReviewAnnotationKind::Question:
        c.questions++;
        if (a.open()) c.openQuestions++;
        if (a.unresolved()) c.unresolvedQuestions++;
        break;
      case SpecReviewAnnotationKind::Conflict:
        c.conflicts++;
        if (a.open()) c.openConflicts++;
        break;
      case SpecReviewAnnotationKind::Comment:
        c.comments++;
        break;
      case SpecReviewAnnotationKind::Mark:
        c.marks++;
        break;
    }
  }
  c.answeredQuestions = c.questions - c.openQuestions;
  return c;
}

namespace {

long long highestCommentNumber(const SpecReviewAnnotations& r) {
  long long high = 0;
  for (const SpecReviewAnnotation& a : r.list()) {
    if (a.kind == SpecReviewAnnotationKind::Comment && a.id) {
      long long n = std::strtoll(a.id->c_str() + 2, nullptr, 10);
      if (n > high) high = n;
    }
  }
  return high;
}

}  // namespace

std::string SpecReviewAnnotations::nextCommentId(long long floor) const {
  const long long high = highestCommentNumber(*this);
  return "C-" + std::to_string((high > floor ? high : floor) + 1);
}

std::vector<std::string> SpecReviewAnnotations::assignCommentIds(long long floor) {
  const long long high = highestCommentNumber(*this);
  long long next = (high > floor ? high : floor) + 1;
  std::vector<std::string> assigned;
  for (const Value& v : valuesOf(*doc_)) {
    const Parsed p = parse(v.text);
    bool any = false;
    std::vector<std::string> lines = splitLines(v.text);
    for (const Comment& c : p.comments) {
      if (c.id) continue;
      any = true;
      const std::string id = "C-" + std::to_string(next++);
      assigned.push_back(id);
      const std::size_t line = p.blocks[c.block].start;
      const std::string raw = lines[line];
      const std::size_t at = c.markerEnd;
      if (at < raw.size() && raw[at] == ' ') {
        lines[line] = raw.substr(0, at + 1) + "**" + id + "** " + raw.substr(at + 1);
      } else if (at >= raw.size()) {
        lines[line] = raw + " **" + id + "**";
      } else {
        lines[line] = raw.substr(0, at) + " **" + id + "** " + raw.substr(at);
      }
    }
    if (any) setValue(*doc_, v.path, v.field, joinLines(lines));
  }
  return assigned;
}

std::string SpecParagraph::toJson() const {
  return "{\"index\":" + std::to_string(index) +
         ",\"startLine\":" + std::to_string(startLine) +
         ",\"endLine\":" + std::to_string(endLine) +
         ",\"text\":" + jsonEncodeStr(text) +
         ",\"annotation\":" + jsonStrOrNull(annotation) + "}";
}

std::vector<SpecParagraph> SpecReviewAnnotations::paragraphs(
    const std::string& path, const std::optional<std::string>& field) const {
  const std::string* value =
      field ? doc_->formFieldOpt(path, *field) : doc_->contentOpt(path);
  if (value == nullptr) {
    throw SpecReviewAnnotationError("no value at " + path +
                                    (field ? " / " + *field : std::string()));
  }
  const Parsed p = parse(*value);
  const auto ranges = paragraphRanges(p.lines, p.code);
  std::vector<SpecParagraph> out;
  for (std::size_t i = 0; i < ranges.size(); i++) {
    SpecParagraph para;
    para.index = i;
    para.startLine = ranges[i].first;
    para.endLine = ranges[i].second;
    for (std::size_t k = ranges[i].first; k <= ranges[i].second; k++) {
      if (k > ranges[i].first) para.text += '\n';
      para.text += p.lines[k];
    }
    for (const Block& b : p.blocks) {
      if (b.start == ranges[i].first) {
        para.annotation = specReviewAnnotationKindName(b.kind);
        break;
      }
    }
    out.push_back(std::move(para));
  }
  return out;
}

std::string SpecReviewAnnotations::changeTime(
    const std::optional<std::string>& at) const {
  if (at) return normalizeReviewTime(*at);
  return clock_ ? clock_() : systemReviewTime();
}

std::string SpecReviewAnnotations::insertComment(
    const std::string& path, const std::optional<std::string>& field,
    long long afterParagraph, const std::string& text,
    const std::optional<std::string>& author,
    const std::optional<std::string>& id,
    const std::optional<std::string>& at) {
  const std::string time = changeTime(at);
  const std::string cid = id ? *id : nextCommentId();
  const std::string value = getValue(*doc_, path, field);
  const long long end = paragraphLastLine(value, afterParagraph);
  setValue(*doc_, path, field,
           insertAfterLine(value, end,
                           formatCommentBlock(cid, text, author, time)));
  return cid;
}

void SpecReviewAnnotations::insertQuestion(
    const std::string& path, const std::optional<std::string>& field,
    long long afterParagraph, const SpecQuestionDraft& question) {
  const std::string value = getValue(*doc_, path, field);
  const long long end = paragraphLastLine(value, afterParagraph);
  setValue(*doc_, path, field,
           insertAfterLine(value, end, formatQuestionBlock(question)));
}

void SpecReviewAnnotations::insertQuestionAfterComment(
    const std::string& commentId, const SpecQuestionDraft& question) {
  const Found f = findComment(*doc_, commentId);
  setValue(*doc_, f.value.path, f.value.field,
           insertAfterLine(f.value.text,
                           static_cast<long long>(f.parsed.blocks[f.block].end),
                           formatQuestionBlock(question)));
}

void SpecReviewAnnotations::setAnswer(
    const std::string& questionId, const std::string& answer,
    const std::optional<std::string>& author,
    const std::optional<std::string>& at) {
  if (author && !isReviewMemberId(*author)) {
    throw SpecReviewAnnotationError(
        "\"" + *author +
        "\" is not a member id (lowercase letters, digits and _)");
  }
  const Found f = findQuestion(*doc_, questionId);
  const Question& q = f.parsed.questions[f.index];
  if (author) {
    const std::optional<std::string> time =
        trim(answer).empty() ? std::nullopt
                             : std::optional<std::string>(changeTime(at));
    setValue(*doc_, f.value.path, f.value.field,
             setIndividualAnswer(f.value.text, q, *author, answer, time));
    return;
  }
  std::vector<std::string> lines = splitLines(f.value.text);
  const std::vector<std::string> a = splitLines(answer);
  std::vector<std::string> written{
      answer.empty() ? "> " + kAnswerLabel : "> " + kAnswerLabel + " " + a[0]};
  if (!answer.empty()) {
    for (std::string& l : quoted(a, 1)) written.push_back(std::move(l));
  }
  // The answer runs to the region's last non-empty line.
  std::size_t last = q.regionEnd;
  while (last > q.header && isBlank(innerOf(lines[last]))) last--;
  if (q.answerLine) {
    const std::size_t from = *q.answerLine;
    const std::size_t to = last < from ? from : last;
    lines.erase(lines.begin() + from, lines.begin() + to + 1);
    lines.insert(lines.begin() + from, written.begin(), written.end());
  } else {
    written.insert(written.begin(), ">");
    lines.insert(lines.begin() + last + 1, written.begin(), written.end());
  }
  setValue(*doc_, f.value.path, f.value.field, joinLines(lines));
}

void SpecReviewAnnotations::editComment(const std::string& commentId,
                                        const std::string& text,
                                        const std::optional<std::string>& at) {
  const std::string time = changeTime(at);
  const Found f = findComment(*doc_, commentId);
  const Comment& c = f.parsed.comments[f.index];
  const Block& b = f.parsed.blocks[f.block];
  std::vector<std::string> lines = splitLines(f.value.text);
  const std::vector<std::string> t = splitLines(text);
  const std::string who = *authorAndTime(c.author, time);
  std::vector<std::string> block{
      trimRight(trimRight(c.beforeAuthor) + " (" + who + "): " + t[0])};
  for (std::string& l : quoted(t, 1)) block.push_back(std::move(l));
  lines.erase(lines.begin() + b.start, lines.begin() + b.end + 1);
  lines.insert(lines.begin() + b.start, block.begin(), block.end());
  setValue(*doc_, f.value.path, f.value.field, joinLines(lines));
}

void SpecReviewAnnotations::resolve(const std::string& id) {
  const std::size_t space = id.rfind(' ');
  const std::string bare = space == std::string::npos ? id : id.substr(space + 1);
  if (startsWith(bare, "C-")) {
    const Found f = findComment(*doc_, bare);
    const Block& b = f.parsed.blocks[f.block];
    setValue(*doc_, f.value.path, f.value.field,
             removeLines(f.value.text, b.start, b.end));
    return;
  }
  const Found f = findQuestion(*doc_, bare);
  const Block& b = f.parsed.blocks[f.block];
  const Question& q = f.parsed.questions[f.index];
  if (b.qLen == 1) {
    setValue(*doc_, f.value.path, f.value.field,
             removeLines(f.value.text, b.start, b.end));
    return;
  }
  std::vector<std::string> lines = splitLines(f.value.text);
  lines.erase(lines.begin() + q.header, lines.begin() + q.regionEnd + 1);
  // A last question leaves the separator `>` lines of the one before it.
  std::size_t end = b.end - (q.regionEnd - q.header + 1);
  while (end > b.start && isBlank(innerOf(lines[end]))) {
    lines.erase(lines.begin() + end);
    end--;
  }
  setValue(*doc_, f.value.path, f.value.field, joinLines(lines));
}

void SpecReviewAnnotations::applyMark(const std::string& path,
                                      const std::optional<std::string>& field,
                                      long long index, bool accept) {
  const std::string value = getValue(*doc_, path, field);
  const Parsed p = parse(value);
  if (index < 0 || static_cast<unsigned long long>(index) >= p.marks.size()) {
    throw SpecReviewAnnotationError("no inline mark " + std::to_string(index) +
                                    " at " + path +
                                    (field ? " / " + *field : ""));
  }
  setValue(*doc_, path, field,
           decideMark(value, p, static_cast<std::size_t>(index), accept));
}

SpecDocument SpecReviewAnnotations::stripped() const {
  SpecDocument copy;
  copy.loadJson(doc_->toJson());
  for (const Value& v : valuesOf(*doc_)) {
    const std::string clean = stripAnnotationsText(v.text);
    if (clean == v.text) continue;
    setValue(copy, v.path, v.field, clean);
  }
  return copy;
}

std::vector<SpecValidationError> SpecReviewAnnotations::validate() const {
  return validateReviewAnnotations(*doc_);
}

/* ---- inline-mark review (SOM §11.9.3) ------------------------------------ */

const char* specMarkDecisionName(SpecMarkDecision d) {
  switch (d) {
    case SpecMarkDecision::Accept:
      return "accept";
    case SpecMarkDecision::Reject:
      return "reject";
    case SpecMarkDecision::Leave:
      return "leave";
  }
  return "";
}

std::optional<SpecMarkDecision> specMarkDecisionFromName(const std::string& name) {
  if (name == "accept") return SpecMarkDecision::Accept;
  if (name == "reject") return SpecMarkDecision::Reject;
  if (name == "leave") return SpecMarkDecision::Leave;
  return std::nullopt;
}

std::string SpecQuotedChange::toJson() const {
  return "{\"kind\":" + jsonEncodeStr(specMarkKindName(kind)) +
         ",\"oldText\":" + jsonEncodeStr(oldText) +
         ",\"newText\":" + jsonEncodeStr(newText) +
         ",\"outcome\":" + jsonStrOrNull(outcome) + "}";
}

std::string SpecMarkEntry::toJson(bool team) const {
  return "{\"id\":" + jsonEncodeStr(id) + ",\"path\":" + jsonEncodeStr(path) +
         ",\"field\":" + jsonStrOrNull(field) +
         ",\"line\":" + std::to_string(line) +
         ",\"markKind\":" + jsonEncodeStr(specMarkKindName(markKind)) +
         ",\"oldText\":" + jsonEncodeStr(oldText) +
         ",\"newText\":" + jsonEncodeStr(newText) +
         ",\"comment\":" + jsonStrOrNull(comment) +
         ",\"markup\":" + jsonEncodeStr(markup) +
         ",\"context\":" + jsonEncodeStr(context) +
         (quotedChange ? ",\"quotedChange\":" + quotedChange->toJson()
                       : std::string()) +
         (commentId ? ",\"commentId\":" + jsonEncodeStr(*commentId)
                    : std::string()) +
         (changeId ? ",\"changeId\":" + jsonEncodeStr(*changeId)
                   : std::string()) +
         (changedAt ? ",\"changedAt\":" + jsonEncodeStr(*changedAt)
                    : std::string()) +
         (team ? ",\"authors\":" + jsonStrList(authors) +
                     ",\"votes\":" + jsonList(votes)
               : std::string()) +
         "}";
}

std::string SpecMarkOutcome::toJson() const {
  return "{\"id\":" + jsonEncodeStr(id) + ",\"path\":" + jsonEncodeStr(path) +
         ",\"field\":" + jsonStrOrNull(field) +
         ",\"line\":" + std::to_string(line) +
         ",\"markKind\":" + jsonEncodeStr(specMarkKindName(markKind)) +
         ",\"decision\":" + jsonEncodeStr(specMarkDecisionName(decision)) +
         ",\"markup\":" + jsonEncodeStr(markup) +
         ",\"result\":" + jsonEncodeStr(result) + "}";
}

std::string SpecMarkIssue::toJson() const {
  return "{\"path\":" + jsonEncodeStr(path) +
         ",\"field\":" + jsonStrOrNull(field) +
         ",\"line\":" + std::to_string(line) +
         ",\"issue\":" + jsonEncodeStr(issue) + "}";
}

std::string SpecConflictOutcome::toJson() const {
  return "{\"id\":" + jsonEncodeStr(id) + ",\"path\":" + jsonEncodeStr(path) +
         ",\"field\":" + jsonStrOrNull(field) +
         ",\"line\":" + std::to_string(line) +
         ",\"decision\":" + jsonEncodeStr(decision) +
         ",\"result\":" + jsonEncodeStr(result) + "}";
}

std::string SpecMarkReport::toJson(bool team) const {
  std::string out = "{\"applied\":" + jsonList(applied) +
                    ",\"malformed\":" + jsonList(malformed);
  if (team && conflicts) out += ",\"conflicts\":" + jsonList(*conflicts);
  return out + "}";
}

namespace {

bool pathUnder(const std::string& path, const std::optional<std::string>& under) {
  return !under || path == *under || startsWith(path, *under + "/");
}

}  // namespace

std::string SpecReviewAnnotations::revision() const {
  std::uint64_t h = 0xcbf29ce484222325ULL;
  const std::uint64_t prime = 0x100000001b3ULL;
  auto add = [&](const std::string& s) {
    for (unsigned char b : s) h = (h ^ b) * prime;
    h = (h ^ 0U) * prime;
  };
  for (const Value& v : valuesOf(*doc_)) {
    add(v.path);
    add(v.field ? *v.field : "");
    add(v.text);
  }
  char buf[17];
  std::snprintf(buf, sizeof(buf), "%016llx", static_cast<unsigned long long>(h));
  return buf;
}

std::vector<SpecMarkEntry> SpecReviewAnnotations::listMarks(
    const std::optional<std::string>& path) const {
  std::vector<SpecMarkEntry> out;
  std::size_t n = 0;
  for (const Value& v : valuesOf(*doc_)) {
    const Parsed p = parse(v.text);
    const std::size_t first = n + 1;
    for (const Mark& m : p.marks) {
      const std::string id = "M-" + std::to_string(++n);
      if (!pathUnder(v.path, path)) continue;
      // The paragraph holding the mark's line, blank-separated and
      // fence-aware.
      std::size_t from = m.line, to = m.line;
      std::size_t k = 0;
      while (k < p.lines.size()) {
        if (isBlank(p.lines[k]) && !p.code[k]) {
          k++;
          continue;
        }
        const std::size_t s0 = k;
        while (k + 1 < p.lines.size() &&
               !(isBlank(p.lines[k + 1]) && !p.code[k + 1]))
          k++;
        if (s0 <= m.line && m.line <= k) {
          from = s0;
          to = k;
          break;
        }
        k++;
      }
      SpecMarkEntry e;
      e.id = id;
      e.path = v.path;
      e.field = v.field;
      e.line = m.line;
      e.markKind = m.kind;
      e.oldText = markReplacement(m, false);
      e.newText = markReplacement(m, true);
      e.comment = m.quote
                      ? std::optional<std::string>(p.quotes[*m.quote].comment)
                      : m.comment;
      e.markup = v.text.substr(m.start, m.end - m.start);
      std::vector<std::string> para(p.lines.begin() + from,
                                    p.lines.begin() + to + 1);
      e.context = joinLines(para);
      e.authors = m.authors;
      e.votes = m.votes;
      if (m.quote) {
        const Quote& q = p.quotes[*m.quote];
        e.quotedChange = SpecQuotedChange{q.kind, q.oldText, q.newText,
                                          q.outcome};
      }
      if (m.commentIndex) {
        e.commentId = "M-" + std::to_string(first + *m.commentIndex);
      }
      if (m.changeIndex) {
        e.changeId = "M-" + std::to_string(first + *m.changeIndex);
      }
      e.changedAt = m.changedAt;
      out.push_back(std::move(e));
    }
  }
  return out;
}

SpecMarkReport SpecReviewAnnotations::applyMarks(
    const std::function<std::optional<SpecMarkDecision>(const std::string&,
                                                        bool)>& decide,
    const std::optional<std::string>& under) {
  SpecMarkReport report;
  std::size_t n = 0;
  for (const Value& v : valuesOf(*doc_)) {
    const Parsed p = parse(v.text);
    std::vector<std::string> ids;
    for (std::size_t k = 0; k < p.marks.size(); k++) {
      ids.push_back("M-" + std::to_string(++n));
    }
    if (!pathUnder(v.path, under)) continue;
    for (const auto& [line, code] : p.markIssues) {
      report.malformed.push_back({v.path, v.field, line, code});
    }
    std::string text = v.text;
    std::vector<SpecMarkOutcome> outcomes;
    std::vector<std::optional<SpecMarkDecision>> decided;
    for (std::size_t k = 0; k < p.marks.size(); k++) {
      decided.push_back(decide(ids[k], p.marks[k].quote.has_value()));
    }
    auto isDecided = [&](std::size_t k) {
      return decided[k] && *decided[k] != SpecMarkDecision::Leave;
    };
    for (std::size_t k = p.marks.size(); k-- > 0;) {
      if (!isDecided(k)) continue;
      const SpecMarkDecision d = *decided[k];
      const Mark& m = p.marks[k];
      const std::string repl =
          markReplacement(m, d == SpecMarkDecision::Accept);
      if (m.commentIndex && !isDecided(*m.commentIndex)) {
        text = recordOutcome(text, p.quotes[*p.marks[*m.commentIndex].quote],
                             d == SpecMarkDecision::Accept);
      }
      SpecMarkOutcome o;
      o.id = ids[k];
      o.path = v.path;
      o.field = v.field;
      o.line = m.line;
      o.markKind = m.kind;
      o.decision = d;
      o.markup = v.text.substr(m.start, m.end - m.start);
      o.result = repl;
      outcomes.insert(outcomes.begin(), std::move(o));
      text = replaceMark(text, m, repl);
    }
    if (text != v.text) setValue(*doc_, v.path, v.field, text);
    for (SpecMarkOutcome& o : outcomes) report.applied.push_back(std::move(o));
  }
  return report;
}

SpecMarkReport SpecReviewAnnotations::decideMarks(
    const std::map<std::string, SpecMarkDecision>& decisions,
    const std::string& revision) {
  const std::string current = this->revision();
  if (revision != current) {
    throw SpecReviewAnnotationError("the document changed since revision " +
                                    revision + " (now " + current +
                                    "); list the marks again");
  }
  std::set<std::string> known;
  for (const SpecMarkEntry& m : listMarks()) known.insert(m.id);
  for (const auto& [id, d] : decisions) {
    (void)d;
    if (known.count(id) == 0) {
      throw SpecReviewAnnotationError("no inline mark " + id +
                                      " in the document");
    }
  }
  return applyMarks(
      [&](const std::string& id, bool) -> std::optional<SpecMarkDecision> {
        const auto it = decisions.find(id);
        if (it == decisions.end()) return std::nullopt;
        return it->second;
      },
      std::nullopt);
}

SpecMarkReport SpecReviewAnnotations::acceptAllMarks(
    const std::optional<std::string>& path) {
  return applyMarks(
      [](const std::string&, bool quoted) -> std::optional<SpecMarkDecision> {
        if (quoted) return std::nullopt;
        return SpecMarkDecision::Accept;
      },
      path);
}

SpecMarkReport SpecReviewAnnotations::rejectAllMarks(
    const std::optional<std::string>& path) {
  return applyMarks(
      [](const std::string&, bool quoted) -> std::optional<SpecMarkDecision> {
        if (quoted) return std::nullopt;
        return SpecMarkDecision::Reject;
      },
      path);
}

namespace {

/* Where `findMark` found a mark: its value and its position there. */
struct FoundMark {
  std::string path;
  std::optional<std::string> field;
  std::string value;
  Parsed parsed;
  std::size_t index = 0;
};

/* The mark `M-<n>` `markId` with its value, refused when the document is no
 * longer at `revision` (when given) or holds no such mark. */
FoundMark findMark(const SpecReviewAnnotations& api, const SpecDocument& doc,
                   const std::string& markId,
                   const std::optional<std::string>& revision) {
  if (revision) {
    const std::string current = api.revision();
    if (*revision != current) {
      throw SpecReviewAnnotationError("the document changed since revision " +
                                      *revision + " (now " + current +
                                      "); list the marks again");
    }
  }
  std::size_t n = 0;
  for (const Value& v : valuesOf(doc)) {
    Parsed p = parse(v.text);
    for (std::size_t k = 0; k < p.marks.size(); k++) {
      if ("M-" + std::to_string(++n) == markId) {
        return {v.path, v.field, v.text, std::move(p), k};
      }
    }
  }
  throw SpecReviewAnnotationError("no inline mark " + markId +
                                  " in the document");
}

}  // namespace

std::string SpecReviewAnnotations::commentChange(
    const std::string& markId, const std::string& text,
    const std::optional<std::string>& author,
    const std::optional<std::string>& revision,
    const std::optional<std::string>& at) {
  const std::string time = changeTime(at);
  const FoundMark f = findMark(*this, *doc_, markId, revision);
  const Mark& m = f.parsed.marks[f.index];
  if (!isChangeMark(m.kind)) {
    throw SpecReviewAnnotationError(markId + " is a " +
                                    specMarkKindName(m.kind) +
                                    " mark, not a change");
  }
  if (m.commentIndex) {
    throw SpecReviewAnnotationError(markId +
                                    " already has a comment; edit it instead");
  }
  const std::string comment = checkInlineComment(text);
  if (author && !isReviewMemberId(*author)) {
    throw SpecReviewAnnotationError("\"" + *author + "\" is not a member id");
  }
  const std::string d = m.kind == SpecMarkKind::Insertion  ? "++"
                        : m.kind == SpecMarkKind::Deletion ? "--"
                                                           : "~~";
  const std::string body = m.kind == SpecMarkKind::Substitution
                               ? m.text + " ~> " + *m.newText
                               : m.text;
  if (body.find(d + "]") != std::string::npos ||
      body.find("<<}") != std::string::npos) {
    throw SpecReviewAnnotationError(markId + " holds \"" + d +
                                    "]\" or \"<<}\", which its quote cannot "
                                    "hold");
  }
  std::vector<std::string> authors;
  if (author) authors.push_back(*author);
  const std::string markup =
      "{>> [" + d + " " + body + " " + d + "] " + comment + " <<}" +
      review_internal::formatAttributionToken(authors, {}, time);
  setValue(*doc_, f.path, f.field,
           f.value.substr(0, m.end) + markup + f.value.substr(m.end));
  return "M-" + std::to_string(std::stoll(markId.substr(2)) + 1);
}

void SpecReviewAnnotations::editMarkComment(
    const std::string& markId, const std::string& text,
    const std::optional<std::string>& revision,
    const std::optional<std::string>& at) {
  const std::string time = changeTime(at);
  const FoundMark f = findMark(*this, *doc_, markId, revision);
  const Mark& m = f.parsed.marks[f.index];
  const std::string comment = checkInlineComment(text);
  std::string markup;
  if (m.kind == SpecMarkKind::Comment) {
    if (!m.quote) {
      markup = "{>> " + comment + " <<}";
    } else {
      const std::size_t open = m.start + 3;
      const Quote& q = f.parsed.quotes[*m.quote];
      markup = "{>> " + trimLeft(f.value.substr(open, q.end - open)) + " " +
               comment + " <<}";
    }
  } else if (m.kind == SpecMarkKind::Highlight && m.comment) {
    markup = "{== " + m.text + " ==}{>> " + comment + " <<}";
  } else {
    throw SpecReviewAnnotationError(markId + " holds no comment");
  }
  const std::string token =
      review_internal::formatAttributionToken(m.authors, m.votes, time);
  setValue(*doc_, f.path, f.field,
           f.value.substr(0, m.start) + markup + token + f.value.substr(m.end));
}

/* A decided conflict, as `removeAllAnnotations` found it before any change. */
struct SpecReviewAnnotations::DecidedConflict {
  std::string path;
  std::optional<std::string> field;
  std::size_t index =
      0;  // the block's position among the value's conflict blocks
  std::string id;
  std::size_t line = 0;
  std::string decision;
};

/* Every conflict block of the document with the line it opens on, in document
 * order — or the refusal of `removeAllAnnotations` when one of them cannot be
 * applied. */
std::vector<SpecReviewAnnotations::DecidedConflict>
SpecReviewAnnotations::decidedConflicts() const {
  std::vector<DecidedConflict> out;
  for (const Value& v : valuesOf(*doc_)) {
    const Parsed p = parse(v.text);
    std::size_t index = 0;
    for (const Block& b : p.blocks) {
      if (b.kind != SpecReviewAnnotationKind::Conflict) continue;
      const Conflict& c = p.conflicts[b.conflict];
      const std::string where = v.path + (v.field ? " / " + *v.field : "") +
                                ", line " + std::to_string(b.start);
      if (!c.id || !c.base || c.alternatives.empty()) {
        throw SpecReviewAnnotationError(
            where + ": a malformed conflict block cannot be applied");
      }
      if (c.decision.empty() || isUnresolvedAnswer(c.decision)) {
        throw SpecReviewAnnotationError(
            where + ": conflict " + *c.id + " is " +
            (c.decision.empty() ? "open" : "unresolved") +
            "; decide it before removing the annotations");
      }
      const std::optional<std::string> letter = decisionLetterOf(c.decision);
      if (letter && *letter != "base") {
        bool known = false;
        for (const SpecConflictAlternative& a : c.alternatives) {
          known = known || a.letter == *letter;
        }
        if (!known) {
          throw SpecReviewAnnotationError(where + ": conflict " + *c.id +
                                          " has no alternative (" + *letter +
                                          ")");
        }
      }
      out.push_back({v.path, v.field, index++, *c.id, b.start, c.decision});
    }
  }
  return out;
}

/* Applies the decided conflicts of one value (marks already accepted), from
 * the last block up so earlier line numbers stay valid, and records each.
 * Where the chosen text goes follows the conflict's text (SOM §11.9.8,
 * "Applying"): a form field, another value, this value's text paragraphs, or
 * — the default — the text paragraph directly before the block. */
std::string SpecReviewAnnotations::applyConflicts(
    const std::string& path, const std::optional<std::string>& field,
    const std::string& value, const std::vector<DecidedConflict>& decided,
    std::vector<SpecConflictOutcome>& outcomes) {
  std::string v = value;
  const Parsed p = parse(v);
  std::vector<SpecConflictOutcome> recorded;
  for (std::size_t k = p.conflicts.size(); k-- > 0;) {
    const DecidedConflict* d = nullptr;
    for (const DecidedConflict& x : decided) {
      if (x.index == k) d = &x;
    }
    const Conflict& c = p.conflicts[k];
    const std::size_t blockStart = p.blocks[c.block].start;
    const std::string result = chosenText(c);
    recorded.insert(
        recorded.begin(),
        SpecConflictOutcome{d->id, path, field, d->line, d->decision, result});
    if (isStructuralTopic(c.topic)) continue;
    std::string targetPath, targetField;
    if (splitPathField(c.text, targetPath, targetField) &&
        doc_->formFieldOpt(targetPath, targetField) != nullptr) {
      doc_->setFormField(targetPath, targetField, result);
    } else if (!field && c.text == path) {
      v = replaceTextRun(v, blockStart, result);
    } else if (looksLikePath(c.text) && c.text != path) {
      doc_->setContent(c.text, result);
    } else {
      v = replaceParagraphBefore(v, blockStart, result);
    }
  }
  for (SpecConflictOutcome& o : recorded) outcomes.push_back(std::move(o));
  return v;
}

SpecMarkReport SpecReviewAnnotations::removeAllAnnotations() {
  const std::vector<DecidedConflict> decided = decidedConflicts();
  SpecMarkReport report = applyMarks(
      [](const std::string&, bool) -> std::optional<SpecMarkDecision> {
        return SpecMarkDecision::Accept;
      },
      std::nullopt);
  std::vector<SpecConflictOutcome> outcomes;
  for (const Value& v : valuesOf(*doc_)) {
    std::string text = v.text;
    std::vector<DecidedConflict> here;
    for (const DecidedConflict& d : decided) {
      if (d.path == v.path && d.field == v.field) here.push_back(d);
    }
    if (!here.empty())
      text = applyConflicts(v.path, v.field, text, here, outcomes);
    while (true) {
      const Parsed p = parse(text);
      if (p.blocks.empty()) break;
      const Block& b = p.blocks.back();
      text = removeLines(text, b.start, b.end);
    }
    if (text != v.text) setValue(*doc_, v.path, v.field, text);
  }
  report.conflicts = std::move(outcomes);
  return report;
}

// ---------------------------------------------------------------------------
// Writing changes as inline marks (SOM §11.9.3, annot5).
// ---------------------------------------------------------------------------

std::string SpecMarkedChange::toJson() const {
  return "{\"text\":" + jsonEncodeStr(text) +
         ",\"exact\":" + (exact ? "true" : "false") + "}";
}

namespace {

/* One token of a value: a run of whitespace, a word (a run of non-whitespace
 * with inline code spans kept whole) or a fenced code block (its lines). */
struct Tok {
  std::string text;
  bool space = false;
};

bool isMarkWs(char c) { return c == ' ' || c == '\t' || c == '\n'; }

std::vector<Tok> tokensOf(const std::string& value) {
  std::vector<Tok> out;
  auto add = [&](const std::string& t, bool space) {
    if (t.empty()) return;
    if (space && !out.empty() && out.back().space) {
      out.back().text += t;
    } else {
      out.push_back({t, space});
    }
  };
  auto words = [&](const std::string& s) {
    std::size_t i = 0;
    while (i < s.size()) {
      if (isMarkWs(s[i])) {
        const std::size_t st = i;
        while (i < s.size() && isMarkWs(s[i])) i++;
        add(s.substr(st, i - st), true);
        continue;
      }
      const std::size_t st = i;
      while (i < s.size() && !isMarkWs(s[i])) {
        if (s[i] == '`') {
          std::size_t n = 0;
          while (i + n < s.size() && s[i + n] == '`') n++;
          // The matching run of exactly n backticks ends the span.
          std::size_t j = i + n;
          std::optional<std::size_t> close;
          while (j < s.size()) {
            if (s[j] == '`') {
              std::size_t m = 0;
              while (j + m < s.size() && s[j + m] == '`') m++;
              if (m == n) {
                close = j;
                break;
              }
              j += m;
            } else {
              j++;
            }
          }
          i = close ? *close + n : i + n;
          continue;
        }
        i++;
      }
      add(s.substr(st, i - st), false);
    }
  };

  const std::vector<std::string> lines = splitLines(value);
  const std::vector<bool> code = codeLines(lines);
  std::size_t k = 0;
  while (k < lines.size()) {
    if (k > 0) add("\n", true);
    const std::size_t st = k;
    const bool isCode = code[k];
    while (k + 1 < lines.size() && code[k + 1] == isCode) k++;
    std::string run;
    for (std::size_t q = st; q <= k; q++) {
      if (q > st) run += '\n';
      run += lines[q];
    }
    if (isCode) {
      add(run, false);
    } else {
      words(run);
    }
    k++;
  }
  return out;
}

/* One diff op: 0 keep, 1 delete (old), 2 insert (new), with its token. */
struct DiffOp {
  int kind;
  Tok tok;
};

/* The diff of two token lists. LCS over token text; ties prefer the
 * deletion. */
std::vector<DiffOp> diffTokens(const std::vector<Tok>& a,
                               const std::vector<Tok>& b) {
  const std::size_t n = a.size(), m = b.size();
  std::vector<std::vector<std::size_t>> l(n + 1,
                                          std::vector<std::size_t>(m + 1, 0));
  for (std::size_t i = n; i-- > 0;) {
    for (std::size_t j = m; j-- > 0;) {
      l[i][j] = a[i].text == b[j].text ? l[i + 1][j + 1] + 1
                                       : std::max(l[i + 1][j], l[i][j + 1]);
    }
  }
  std::vector<DiffOp> ops;
  std::size_t i = 0, j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && a[i].text == b[j].text) {
      ops.push_back({0, a[i]});
      i++;
      j++;
    } else if (j >= m || (i < n && l[i + 1][j] >= l[i][j + 1])) {
      ops.push_back({1, a[i]});
      i++;
    } else {
      ops.push_back({2, b[j]});
      j++;
    }
  }
  return ops;
}

/* `s` with its leading and trailing whitespace removed (spaces, tabs,
 * newlines). */
std::string trimWs(const std::string& s) {
  std::size_t a = 0, b = s.size();
  while (a < b && isMarkWs(s[a])) a++;
  while (b > a && isMarkWs(s[b - 1])) b--;
  return s.substr(a, b - a);
}

/* The markup for one region whose old text is `o` and new text is `n` (both
 * trimmed, not both empty). */
std::string markup(const std::string& o, const std::string& n) {
  if (o.empty()) return "{++ " + n + " ++}";
  if (n.empty()) return "{-- " + o + " --}";
  return "{~~ " + o + " ~> " + n + " ~~}";
}

/* Leading / trailing whitespace by Dart's `trimLeft` / `trimRight`. */
std::string leadWs(const std::string& x) {
  auto [b, e] = trimBounds(x);
  return b == e ? x : x.substr(0, b);
}

std::string trailWs(const std::string& x) {
  auto [b, e] = trimBounds(x);
  return b == e ? x : x.substr(e);
}

/* The marked emission for the region [r0, r1) of `ops`, with the old and the
 * new text around it, or nullopt when no mark round-trips there. */
std::optional<std::string> emitRegion(const std::vector<DiffOp>& ops,
                                      std::size_t r0, std::size_t r1,
                                      const std::string& oldBefore,
                                      const std::string& newBefore,
                                      const std::string& oldAfter,
                                      const std::string& newAfter) {
  std::string os, ns;
  for (std::size_t k = r0; k < r1; k++) {
    if (ops[k].kind != 2) os += ops[k].tok.text;
    if (ops[k].kind != 1) ns += ops[k].tok.text;
  }
  // Whitespace the two sides share at the edges stays outside the mark.
  std::size_t lead = 0;
  while (lead < os.size() && lead < ns.size() && os[lead] == ns[lead] &&
         isMarkWs(os[lead])) {
    lead++;
  }
  std::size_t trail = 0;
  while (trail < os.size() - lead && trail < ns.size() - lead &&
         os[os.size() - 1 - trail] == ns[ns.size() - 1 - trail] &&
         isMarkWs(os[os.size() - 1 - trail])) {
    trail++;
  }
  const std::string oi = os.substr(lead, os.size() - lead - trail);
  const std::string ni = ns.substr(lead, ns.size() - lead - trail);
  // The mark's content is trimmed when read, so it must already be trimmed;
  // the whitespace still differing is placed outside, on the side whose text
  // keeps it, and the tidy rules then have to restore the other side.
  const std::string ot = trimWs(oi), nt = trimWs(ni);
  if (ot.empty() && nt.empty()) return std::nullopt;
  const std::string pre = os.substr(0, lead);
  const std::string post = os.substr(os.size() - trail);
  const std::string mark = markup(ot, nt);
  const std::pair<std::string, std::string> candidates[] = {
      {leadWs(ni), trailWs(ni)}, {leadWs(oi), trailWs(oi)}, {"", ""},
      {leadWs(ni), ""},          {"", trailWs(ni)},
  };
  for (const auto& [wl, wr] : candidates) {
    const std::string emission = pre + wl + mark + wr + post;
    const std::string acc =
        applyInlineMarksText(newBefore + emission + newAfter, true);
    const std::string rej =
        applyInlineMarksText(oldBefore + emission + oldAfter, false);
    if (acc == newBefore + ns + newAfter && rej == oldBefore + os + oldAfter) {
      return emission;
    }
  }
  return std::nullopt;
}

/* Marks the token-level differences of `o` → `n`, where the text before them
 * is `ob` (old) / `nb` (new) and after them `oa` / `na`. nullopt when the
 * marks do not round-trip. */
std::optional<std::string> markTokens(const std::string& o,
                                      const std::string& n,
                                      const std::string& ob,
                                      const std::string& nb,
                                      const std::string& oa,
                                      const std::string& na) {
  const std::vector<DiffOp> ops = diffTokens(tokensOf(o), tokensOf(n));
  std::vector<std::pair<std::size_t, std::size_t>> runs;
  std::size_t k = 0;
  while (k < ops.size()) {
    if (ops[k].kind == 0) {
      k++;
      continue;
    }
    const std::size_t s = k;
    while (k < ops.size() && ops[k].kind != 0) k++;
    runs.emplace_back(s, k);
  }
  // Changes separated by at most two unchanged words are one mark.
  std::vector<std::pair<std::size_t, std::size_t>> merged;
  for (const auto& r : runs) {
    if (!merged.empty()) {
      std::size_t words = 0;
      for (std::size_t q = merged.back().second; q < r.first; q++) {
        if (!ops[q].tok.space) words++;
      }
      if (words <= 2) {
        merged.back().second = r.second;
        continue;
      }
    }
    merged.push_back(r);
  }
  runs = merged;

  auto side = [&](std::size_t from, std::size_t to, int skip) {
    std::string b;
    for (std::size_t q = from; q < to; q++) {
      if (ops[q].kind != skip) b += ops[q].tok.text;
    }
    return b;
  };

  // Left to right; a region that does not round-trip grows by one token on
  // each side and is tried again.
  const std::size_t end = ops.size();
  std::string out;
  std::size_t pos = 0;
  for (std::size_t ri = 0; ri < runs.size(); ri++) {
    auto [r0, r1] = runs[ri];
    if (r0 < pos) r0 = pos;
    std::optional<std::string> emission;
    while (true) {
      emission = emitRegion(ops, r0, r1, ob + side(0, r0, 2),
                            nb + side(0, r0, 1), side(r1, end, 2) + oa,
                            side(r1, end, 1) + na);
      if (emission || (r0 <= pos && r1 >= end)) break;
      if (r0 > pos) r0--;
      if (r1 < end) r1++;
    }
    if (!emission) return std::nullopt;
    out += side(pos, r0, 1);
    out += *emission;
    pos = r1;
    while (ri + 1 < runs.size() && runs[ri + 1].second <= pos) ri++;
  }
  out += side(pos, end, 1);
  if (applyInlineMarksText(nb + out + na, true) != nb + n + na ||
      applyInlineMarksText(ob + out + oa, false) != ob + o + oa) {
    return std::nullopt;
  }
  return out;
}

/* A whole line marked as inserted (`++`) or deleted (`--`): its indentation
 * stays outside the mark; a blank line stays blank. */
std::string lineMark(const std::string& line, const std::string& d) {
  auto [b, e] = trimBounds(line);
  if (b == e) return line;
  return line.substr(0, b) + "{" + d + " " + line.substr(b, e - b) + " " + d +
         "}";
}

std::vector<std::string> slice(const std::vector<std::string>& v,
                               std::size_t from, std::size_t to) {
  return std::vector<std::string>(v.begin() + static_cast<long>(from),
                                  v.begin() + static_cast<long>(to));
}

std::vector<std::string> concat(std::vector<std::string> a,
                                const std::vector<std::string>& b) {
  a.insert(a.end(), b.begin(), b.end());
  return a;
}

std::vector<std::string> withoutBlank(const std::vector<std::string>& v) {
  std::vector<std::string> out;
  for (const auto& l : v) {
    if (!isBlank(l)) out.push_back(l);
  }
  return out;
}

}  // namespace

SpecMarkedChange markChangeText(const std::string& oldValue,
                                const std::string& newValue) {
  if (oldValue == newValue) return {newValue, true};
  const std::vector<std::string> ol = splitLines(oldValue);
  const std::vector<std::string> nl = splitLines(newValue);
  const std::vector<bool> oc = codeLines(ol), nc = codeLines(nl);
  std::vector<Tok> olt, nlt;
  for (const auto& l : ol) olt.push_back({l, false});
  for (const auto& l : nl) nlt.push_back({l, false});
  const std::vector<DiffOp> lops = diffTokens(olt, nlt);
  std::vector<std::string> out;
  bool exact = true;
  std::size_t oi = 0, ni = 0, k = 0;
  while (k < lops.size()) {
    if (lops[k].kind == 0) {
      out.push_back(nl[ni]);
      oi++;
      ni++;
      k++;
      continue;
    }
    const std::size_t d0 = oi, n0 = ni;
    while (k < lops.size() && lops[k].kind != 0) {
      if (lops[k].kind == 1) {
        oi++;
      } else {
        ni++;
      }
      k++;
    }
    const auto del = slice(ol, d0, oi), ins = slice(nl, n0, ni);
    const auto ob = slice(ol, 0, d0), oa = slice(ol, oi, ol.size());
    const auto nb = slice(nl, 0, n0), na = slice(nl, ni, nl.size());
    auto roundTrips = [&](const std::vector<std::string>& e) {
      return applyInlineMarksText(joinLines(concat(concat(nb, e), na)), true) ==
                 newValue &&
             applyInlineMarksText(joinLines(concat(concat(ob, e), oa)),
                                  false) == oldValue;
    };
    std::optional<std::vector<std::string>> emitted;
    bool inCode = false;
    for (std::size_t q = d0; q < oi; q++) inCode = inCode || oc[q];
    for (std::size_t q = n0; q < ni; q++) inCode = inCode || nc[q];
    if (!inCode) {
      std::vector<std::vector<std::string>> candidates;
      if (!del.empty() && !ins.empty()) {
        const auto t = markTokens(
            joinLines(del), joinLines(ins),
            ob.empty() ? "" : joinLines(ob) + "\n",
            nb.empty() ? "" : joinLines(nb) + "\n",
            oa.empty() ? "" : "\n" + joinLines(oa),
            na.empty() ? "" : "\n" + joinLines(na));
        if (t) candidates.push_back(splitLines(*t));
      }
      std::vector<std::string> dm, im;
      for (const auto& l : del) dm.push_back(lineMark(l, "--"));
      for (const auto& l : ins) im.push_back(lineMark(l, "++"));
      candidates.push_back(concat(dm, im));
      candidates.push_back(concat(withoutBlank(dm), im));
      candidates.push_back(concat(dm, withoutBlank(im)));
      candidates.push_back(concat(withoutBlank(dm), withoutBlank(im)));
      for (const auto& e : candidates) {
        if (roundTrips(e)) {
          emitted = e;
          break;
        }
      }
    }
    if (!emitted) {
      exact = false;
      out.insert(out.end(), ins.begin(), ins.end());
    } else {
      out.insert(out.end(), emitted->begin(), emitted->end());
    }
  }
  const std::string text = joinLines(out);
  if (exact && (applyInlineMarksText(text, true) != newValue ||
                applyInlineMarksText(text, false) != oldValue)) {
    return {newValue, false};
  }
  return {text, exact};
}

namespace {

/* `after` (a value just written as marks) with an attribution token on every
 * change mark it lacks one on (SOM §11.9.10): the token of the same change in
 * `before` (same kind, old and new text; each used once, in order) when
 * `before` held it, else a new one with `author` and `time`. */
std::string stampMarks(const std::string& before, const std::string& after,
                       const std::optional<std::string>& author,
                       const std::string& time) {
  auto key = [](const Mark& m) {
    return std::string(specMarkKindName(m.kind)) + '\0' +
           markReplacement(m, false) + '\0' + markReplacement(m, true);
  };
  std::vector<std::pair<std::string, std::string>> old;
  for (const Mark& m : parse(before).marks) {
    if (isChangeMark(m.kind)) {
      old.emplace_back(key(m), before.substr(m.bodyEnd, m.end - m.bodyEnd));
    }
  }
  std::vector<bool> used(old.size(), false);
  std::vector<std::string> authors;
  if (author) authors.push_back(*author);
  const std::string fresh =
      review_internal::formatAttributionToken(authors, {}, time);
  std::vector<std::pair<std::size_t, std::string>> inserts;
  for (const Mark& m : parse(after).marks) {
    if (!isChangeMark(m.kind) || m.end > m.bodyEnd) continue;
    const std::string k = key(m);
    std::string token = fresh;
    for (std::size_t i = 0; i < old.size(); i++) {
      if (!used[i] && old[i].first == k) {
        used[i] = true;
        token = old[i].second;
        break;
      }
    }
    if (!token.empty()) inserts.emplace_back(m.bodyEnd, token);
  }
  std::string v = after;
  for (auto it = inserts.rbegin(); it != inserts.rend(); ++it) {
    v = v.substr(0, it->first) + it->second + v.substr(it->first);
  }
  return v;
}

/* Refuses an `author` that is not a member id. */
void checkAuthor(const std::optional<std::string>& author) {
  if (author && !isReviewMemberId(*author)) {
    throw SpecReviewAnnotationError(
        "\"" + *author +
        "\" is not a member id (lowercase letters, digits and _)");
  }
}

}  // namespace

SpecMarkedChange SpecReviewAnnotations::setMarked(
    const std::string& path, const std::optional<std::string>& field,
    const std::string& text, const std::optional<std::string>& author,
    const std::optional<std::string>& at) {
  checkAuthor(author);
  const std::string time = changeTime(at);
  const std::string current = getValue(*doc_, path, field);
  const SpecMarkedChange result = markKeepingChangeComments(current, text);
  SpecMarkedChange stamped{stampMarks(current, result.text, author, time),
                           result.exact};
  setValue(*doc_, path, field, stamped.text);
  return stamped;
}

SpecMarkedChange SpecReviewAnnotations::markAgainst(
    const std::string& path, const std::optional<std::string>& field,
    const std::string& earlier, const std::optional<std::string>& author,
    const std::optional<std::string>& at) {
  checkAuthor(author);
  const std::string time = changeTime(at);
  const std::string current = getValue(*doc_, path, field);
  const SpecMarkedChange result = markChangeText(earlier, current);
  SpecMarkedChange stamped{stampMarks(current, result.text, author, time),
                           result.exact};
  setValue(*doc_, path, field, stamped.text);
  return stamped;
}

// ---------------------------------------------------------------------------
// Text-level building blocks of the merge (SOM §11.9.9).
// ---------------------------------------------------------------------------

namespace review_internal {

std::vector<ReviewPiece> reviewPieces(const std::string& value) {
  std::vector<ReviewPiece> out;
  if (value.empty()) return out;
  const Parsed p = parse(value);
  for (const auto& [s0, e0] : paragraphRanges(p.lines, p.code)) {
    ReviewPiece piece;
    piece.text = joinLines(std::vector<std::string>(p.lines.begin() + s0,
                                                    p.lines.begin() + e0 + 1));
    for (const Block& b : p.blocks) {
      if (b.start != s0) continue;
      piece.kind = b.kind;
      if (b.kind == SpecReviewAnnotationKind::Comment) {
        const Comment& c = p.comments[b.comment];
        piece.id = c.id;
        piece.author = c.author;
        piece.commentText = c.text;
        piece.changedAt = c.changedAt;
      } else if (b.kind == SpecReviewAnnotationKind::Conflict) {
        piece.id = p.conflicts[b.conflict].id;
      } else {
        for (std::size_t qi = 0; qi < b.qLen; qi++) {
          piece.questionIds.push_back(p.questions[b.qFirst + qi].id);
        }
      }
      break;
    }
    out.push_back(std::move(piece));
  }
  return out;
}

std::vector<ReviewMark> reviewMarks(const std::string& value) {
  std::vector<ReviewMark> out;
  for (const Mark& m : parse(value).marks) {
    ReviewMark r;
    r.start = m.start;
    r.end = m.end;
    r.bodyEnd = m.bodyEnd;
    r.kind = m.kind;
    r.markup = value.substr(m.start, m.end - m.start);
    r.authors = m.authors;
    r.votes = m.votes;
    r.changedAt = m.changedAt;
    r.accepted = markReplacement(m, true);
    r.rejected = markReplacement(m, false);
    out.push_back(std::move(r));
  }
  return out;
}

std::string decideReviewMarks(const std::string& value,
                              const std::map<std::size_t, bool>& decisions) {
  const std::vector<Mark> marks = parse(value).marks;
  std::string v = value;
  for (std::size_t k = marks.size(); k-- > 0;) {
    const auto it = decisions.find(k);
    if (it == decisions.end()) continue;
    v = replaceMark(v, marks[k], markReplacement(marks[k], it->second));
  }
  return v;
}

std::string formatAttributionToken(
    const std::vector<std::string>& authors,
    const std::vector<SpecMarkVote>& votes,
    const std::optional<std::string>& changedAt) {
  std::vector<std::string> parts;
  if (!authors.empty()) {
    std::string a;
    for (std::size_t i = 0; i < authors.size(); i++) {
      if (i > 0) a += ",";
      a += authors[i];
    }
    parts.push_back(std::move(a));
  }
  for (const SpecMarkVote& v : votes) {
    parts.push_back((v.accept ? "+" : "-") + v.member);
  }
  if (changedAt) parts.push_back(*changedAt);
  if (parts.empty()) return "";
  std::string out = "{@";
  for (std::size_t i = 0; i < parts.size(); i++) {
    if (i > 0) out += " ";
    out += parts[i];
  }
  return out + "}";
}

std::string withAttribution(const std::string& value, const ReviewMark& m,
                            const std::vector<std::string>& authors,
                            const std::vector<SpecMarkVote>& votes) {
  return value.substr(0, m.bodyEnd) +
         formatAttributionToken(authors, votes, m.changedAt) +
         value.substr(m.end);
}

std::vector<std::pair<std::string, std::string>> reviewTeamAnswers(
    const std::string& value) {
  std::vector<std::pair<std::string, std::string>> out;
  for (const Question& q : parse(value).questions) {
    bool seen = false;
    for (const auto& e : out) seen = seen || e.first == q.id;
    if (!seen) out.emplace_back(q.id, q.answer);
  }
  return out;
}

std::optional<std::string> setIndividualAnswerText(
    const std::string& value, const std::string& questionId,
    const std::string& member, const std::string& answer,
    const std::optional<std::string>& changedAt) {
  for (const Question& q : parse(value).questions) {
    if (q.id == questionId)
      return setIndividualAnswer(value, q, member, answer, changedAt);
  }
  return std::nullopt;
}

namespace {

/* The b-token range an x-token range `[x0, x1)` lands on, or nullopt when it
 * is not one.
 *
 * A replaced range lands where its tokens are in b, which must be contiguous
 * there; its neighbours are not consulted, because the token diff may align a
 * neighbouring space with another space of b (beside a decided mark) without
 * the range touching that mark. A pure insertion (`x0 == x1`) has no tokens of
 * its own, so both neighbours must sit next to each other in b. */
std::optional<std::pair<long long, long long>> landing(
    const std::vector<long long>& toB, std::size_t x0, std::size_t x1,
    std::size_t bLength) {
  for (std::size_t k = x0; k < x1; k++) {
    if (toB[k] < 0 || (k > x0 && toB[k] != toB[k - 1] + 1)) return std::nullopt;
  }
  if (x1 > x0) return std::make_pair(toB[x0], toB[x1 - 1] + 1);
  const long long left = x0 == 0 ? -1 : toB[x0 - 1];
  const long long right =
      x1 == toB.size() ? static_cast<long long>(bLength) : toB[x1];
  if ((x0 > 0 && left < 0) || (x1 < toB.size() && right < 0))
    return std::nullopt;
  if (right != left + 1) return std::nullopt;
  return std::make_pair(left + 1, left + 1);
}

}  // namespace

std::optional<std::string> transplantEdits(const std::string& x,
                                           const std::string& y,
                                           const std::string& b) {
  const std::vector<Tok> xt = tokensOf(x);
  const std::vector<Tok> bt = tokensOf(b);
  // Where each token of x is in b (-1: x and b differ there).
  std::vector<long long> toB(xt.size(), -1);
  std::size_t i = 0;
  long long j = 0;
  for (const DiffOp& op : diffTokens(xt, bt)) {
    if (op.kind == 0) {
      toB[i++] = j++;
    } else if (op.kind == 1) {
      i++;
    } else {
      j++;
    }
  }
  // The edits x → y as (first x token, end x token, inserted text).
  struct Hunk {
    std::size_t x0, x1;
    std::string inserted;
  };
  std::vector<Hunk> hunks;
  std::optional<Hunk> open;
  i = 0;
  for (const DiffOp& op : diffTokens(xt, tokensOf(y))) {
    if (op.kind == 0) {
      if (open) hunks.push_back(*open);
      open.reset();
      i++;
      continue;
    }
    if (!open) open = Hunk{i, i, ""};
    if (op.kind == 1) {
      open->x1 = ++i;
    } else {
      open->inserted += op.tok.text;
    }
  }
  if (open) hunks.push_back(*open);
  std::vector<std::string> out;
  for (const Tok& t : bt) out.push_back(t.text);
  for (std::size_t h = hunks.size(); h-- > 0;) {
    const auto at = landing(toB, hunks[h].x0, hunks[h].x1, bt.size());
    if (!at) return std::nullopt;
    out.erase(out.begin() + at->first, out.begin() + at->second);
    out.insert(out.begin() + at->first, hunks[h].inserted);
  }
  std::string joined;
  for (const std::string& t : out) joined += t;
  return joined;
}

}  // namespace review_internal

namespace {

/* The lines of a conflict's text: the first after its prefix, the rest
 * indented under it. */
std::vector<std::string> alternativeLines(const std::string& prefix,
                                          const std::string& text) {
  const std::vector<std::string> t = splitLines(text);
  std::vector<std::string> out{trimRight("> - " + prefix + " " + t[0])};
  for (std::size_t k = 1; k < t.size(); k++) out.push_back(">   " + t[k]);
  return out;
}

}  // namespace

std::vector<std::string> formatConflictBlock(
    const std::string& id, const std::string& topic, const std::string& text,
    const std::string& base,
    const std::vector<SpecConflictAlternative>& alternatives) {
  std::vector<std::string> out{trimRight("> " + kScales + kVs16 + " **" + id +
                                         kEmDashSep + topic + ":** " + text)};
  for (std::string& l : alternativeLines("(base)", base))
    out.push_back(std::move(l));
  for (const SpecConflictAlternative& a : alternatives) {
    std::string names;
    for (std::size_t i = 0; i < a.members.size(); i++) {
      if (i > 0) names += ", ";
      names += a.members[i];
    }
    for (std::string& l :
         alternativeLines("(" + a.letter + ") **" + names + ":**", a.text)) {
      out.push_back(std::move(l));
    }
  }
  out.push_back(">");
  out.push_back("> " + kDecisionLabel);
  return out;
}

}  // namespace som
