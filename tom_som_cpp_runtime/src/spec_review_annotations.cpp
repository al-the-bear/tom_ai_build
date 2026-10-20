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
#include <cstdint>
#include <cstdio>
#include <cstdlib>
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
};

struct Comment {
  std::size_t block = 0;
  std::optional<std::string> id;
  std::optional<std::string> author;
  std::string text;
  std::string context;
  std::string headerPrefix;  // the first line up to where the text starts
  std::size_t markerEnd = 0;  // where an id is inserted into the first line
};

struct Mark {
  std::size_t start = 0;  // byte offsets into the value; never exported
  std::size_t end = 0;
  std::size_t line = 0;
  SpecMarkKind kind = SpecMarkKind::Comment;
  std::string text;
  std::optional<std::string> newText;
  std::optional<std::string> comment;
};

struct Parsed {
  std::vector<std::string> lines;
  std::vector<bool> code;  // per line: inside a fenced block (fence lines too)
  std::vector<Block> blocks;
  std::vector<Comment> comments;
  std::vector<Question> questions;
  std::vector<Mark> marks;
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
  std::string s = lstrip(line).substr(1);
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
  if (startsWith(rest, "(")) {
    std::size_t close = rest.find(')');
    if (close != std::string::npos && close > 0) {
      author = rest.substr(1, close - 1);
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
    if (startsWith(t, kQuestionOpen) || startsWith(t, kAnswerLabel)) {
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
    std::optional<std::size_t> answer;
    for (std::size_t m = k + 1; m <= regionEnd; m++) {
      if (startsWith(in[m], kAnswerLabel)) {
        answer = m;
        break;
      }
    }
    long long textEnd = answer ? static_cast<long long>(*answer) - 1
                               : static_cast<long long>(regionEnd);
    Question qq;
    auto [options, recommended] =
        parseOptions(in, static_cast<long long>(k) + 1, textEnd);
    qq.options = std::move(options);
    qq.recommended = std::move(recommended);
    qq.text = trim(joinFrom(h.rest, in, static_cast<long long>(k) + 1, textEnd));
    if (answer) {
      qq.answer = trim(joinFrom(in[*answer].substr(kAnswerLabel.size()), in,
                                static_cast<long long>(*answer) + 1,
                                static_cast<long long>(regionEnd)));
    }
    qq.header = b.start + k;
    qq.regionEnd = b.start + regionEnd;
    if (answer) qq.answerLine = b.start + *answer;
    qq.id = h.id;
    qq.topic = h.topic;
    qq.starred = h.starred;
    p.questions.push_back(std::move(qq));
  }
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
      case 0:
        m.kind = SpecMarkKind::Comment;
        m.comment = trim(inner);
        break;
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
  }
  return "";
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

std::optional<std::string> SpecReviewAnnotation::answerLetter() const {
  if (kind != SpecReviewAnnotationKind::Question) return std::nullopt;
  return leadingLetter(answer);
}

std::string SpecReviewAnnotation::toJson() const {
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
      break;
    case SpecReviewAnnotationKind::Question:
      b += ",\"id\":" + jsonStrOrNull(id) +
           ",\"topic\":" + jsonStrOrNull(topic) +
           ",\"starred\":" + (starred ? "true" : "false") +
           ",\"combined\":" + (combined ? "true" : "false") +
           ",\"text\":" + jsonEncodeStr(text) +
           ",\"answer\":" + jsonEncodeStr(answer) +
           ",\"open\":" + (open() ? "true" : "false");
      b += ",\"options\":[";
      for (std::size_t i = 0; i < options.size(); i++) {
        if (i) b += ",";
        b += options[i].toJson();
      }
      b += "],\"recommended\":" + jsonStrOrNull(recommended) +
           ",\"answerLetter\":" + jsonStrOrNull(answerLetter());
      break;
    case SpecReviewAnnotationKind::Mark:
      b += std::string(",\"markKind\":") +
           (markKind ? jsonEncodeStr(specMarkKindName(*markKind)) : "null") +
           ",\"text\":" + jsonEncodeStr(text) +
           ",\"newText\":" + jsonStrOrNull(newText) +
           ",\"comment\":" + jsonStrOrNull(comment);
      break;
  }
  return b + "}";
}

std::string SpecReviewAnnotationCounts::toJson() const {
  return "{\"questions\":" + std::to_string(questions) +
         ",\"openQuestions\":" + std::to_string(openQuestions) +
         ",\"answeredQuestions\":" + std::to_string(answeredQuestions) +
         ",\"comments\":" + std::to_string(comments) +
         ",\"marks\":" + std::to_string(marks) + "}";
}

/* ---- text level ----------------------------------------------------------- */

std::vector<std::string> formatCommentBlock(
    const std::string& id, const std::string& text,
    const std::optional<std::string>& author) {
  const std::vector<std::string> t = splitLines(text);
  std::string head = "> " + kArrow + kVs16 + " **" + id + "**";
  if (author && !author->empty()) head += " (" + *author + "):";
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

std::string SpecReviewAnnotations::insertComment(
    const std::string& path, const std::optional<std::string>& field,
    long long afterParagraph, const std::string& text,
    const std::optional<std::string>& author,
    const std::optional<std::string>& id) {
  const std::string cid = id ? *id : nextCommentId();
  const std::string value = getValue(*doc_, path, field);
  const long long end = paragraphLastLine(value, afterParagraph);
  setValue(*doc_, path, field,
           insertAfterLine(value, end, formatCommentBlock(cid, text, author)));
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

void SpecReviewAnnotations::setAnswer(const std::string& questionId,
                                      const std::string& answer) {
  const Found f = findQuestion(*doc_, questionId);
  const Question& q = f.parsed.questions[f.index];
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
                                        const std::string& text) {
  const Found f = findComment(*doc_, commentId);
  const Comment& c = f.parsed.comments[f.index];
  const Block& b = f.parsed.blocks[f.block];
  std::vector<std::string> lines = splitLines(f.value.text);
  const std::vector<std::string> t = splitLines(text);
  std::vector<std::string> block{trimRight(c.headerPrefix + t[0])};
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
  const Mark& m = p.marks[static_cast<std::size_t>(index)];
  setValue(*doc_, path, field, replaceMark(value, m, markReplacement(m, accept)));
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

std::string SpecMarkEntry::toJson() const {
  return "{\"id\":" + jsonEncodeStr(id) + ",\"path\":" + jsonEncodeStr(path) +
         ",\"field\":" + jsonStrOrNull(field) +
         ",\"line\":" + std::to_string(line) +
         ",\"markKind\":" + jsonEncodeStr(specMarkKindName(markKind)) +
         ",\"oldText\":" + jsonEncodeStr(oldText) +
         ",\"newText\":" + jsonEncodeStr(newText) +
         ",\"comment\":" + jsonStrOrNull(comment) +
         ",\"markup\":" + jsonEncodeStr(markup) +
         ",\"context\":" + jsonEncodeStr(context) + "}";
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

std::string SpecMarkReport::toJson() const {
  std::string out = "{\"applied\":[";
  for (std::size_t i = 0; i < applied.size(); i++) {
    if (i > 0) out += ",";
    out += applied[i].toJson();
  }
  out += "],\"malformed\":[";
  for (std::size_t i = 0; i < malformed.size(); i++) {
    if (i > 0) out += ",";
    out += malformed[i].toJson();
  }
  return out + "]}";
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
      e.comment = m.comment;
      e.markup = v.text.substr(m.start, m.end - m.start);
      std::vector<std::string> para(p.lines.begin() + from,
                                    p.lines.begin() + to + 1);
      e.context = joinLines(para);
      out.push_back(std::move(e));
    }
  }
  return out;
}

SpecMarkReport SpecReviewAnnotations::applyMarks(
    const std::function<std::optional<SpecMarkDecision>(const std::string&)>&
        decide,
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
    for (std::size_t k = p.marks.size(); k-- > 0;) {
      const std::optional<SpecMarkDecision> d = decide(ids[k]);
      if (!d || *d == SpecMarkDecision::Leave) continue;
      const Mark& m = p.marks[k];
      const std::string repl = markReplacement(m, *d == SpecMarkDecision::Accept);
      SpecMarkOutcome o;
      o.id = ids[k];
      o.path = v.path;
      o.field = v.field;
      o.line = m.line;
      o.markKind = m.kind;
      o.decision = *d;
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
      [&](const std::string& id) -> std::optional<SpecMarkDecision> {
        const auto it = decisions.find(id);
        if (it == decisions.end()) return std::nullopt;
        return it->second;
      },
      std::nullopt);
}

SpecMarkReport SpecReviewAnnotations::acceptAllMarks(
    const std::optional<std::string>& path) {
  return applyMarks(
      [](const std::string&) -> std::optional<SpecMarkDecision> {
        return SpecMarkDecision::Accept;
      },
      path);
}

SpecMarkReport SpecReviewAnnotations::rejectAllMarks(
    const std::optional<std::string>& path) {
  return applyMarks(
      [](const std::string&) -> std::optional<SpecMarkDecision> {
        return SpecMarkDecision::Reject;
      },
      path);
}

SpecMarkReport SpecReviewAnnotations::removeAllAnnotations() {
  SpecMarkReport report = acceptAllMarks();
  for (const Value& v : valuesOf(*doc_)) {
    std::string text = v.text;
    while (true) {
      const Parsed p = parse(text);
      if (p.blocks.empty()) break;
      const Block& b = p.blocks.back();
      text = removeLines(text, b.start, b.end);
    }
    if (text != v.text) setValue(*doc_, v.path, v.field, text);
  }
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

SpecMarkedChange SpecReviewAnnotations::setMarked(
    const std::string& path, const std::optional<std::string>& field,
    const std::string& text) {
  const std::string base =
      applyInlineMarksText(getValue(*doc_, path, field), false);
  SpecMarkedChange result = markChangeText(base, text);
  setValue(*doc_, path, field, result.text);
  return result;
}

SpecMarkedChange SpecReviewAnnotations::markAgainst(
    const std::string& path, const std::optional<std::string>& field,
    const std::string& earlier) {
  SpecMarkedChange result =
      markChangeText(earlier, getValue(*doc_, path, field));
  setValue(*doc_, path, field, result.text);
  return result;
}

}  // namespace som
