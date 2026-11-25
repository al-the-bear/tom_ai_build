/* The reading notation's scanner — the C++ port of `spec_notation.dart` /
 * `spec_notation.ts` (see spec_notation.hpp).
 *
 * The scan runs over the text's UTF-16 code units, so every offset, every
 * "one character" step and every regular expression of the TypeScript source
 * means the same here. The expressions are written out as small matchers: each
 * notes the TypeScript expression it stands for, and JavaScript's `\s`, `.`
 * and `trim()` are kept exactly (`isJsSpace`, `isJsLineTerminator`). */
#include "spec_notation.hpp"

#include <algorithm>
#include <iterator>
#include <map>
#include <set>

#include "som_json.hpp"
#include "spec_text_pattern.hpp"

namespace som {

namespace {

using U16 = std::u16string;

/* JavaScript's `\s` / the whitespace `trim()` removes. */
bool isJsSpace(char16_t c) {
  switch (c) {
    case 0x09: case 0x0A: case 0x0B: case 0x0C: case 0x0D: case 0x20:
    case 0xA0: case 0x1680: case 0x2028: case 0x2029: case 0x202F:
    case 0x205F: case 0x3000: case 0xFEFF:
      return true;
    default:
      return c >= 0x2000 && c <= 0x200A;
  }
}

/* What JavaScript's `.` does not match (the text is split at '\n'). */
bool isJsLineTerminator(char16_t c) {
  return c == 0x0A || c == 0x0D || c == 0x2028 || c == 0x2029;
}

bool isSpaceOrTab(char16_t c) { return c == u' ' || c == u'\t'; }

bool isAsciiLetter(char16_t c) {
  return (c >= u'A' && c <= u'Z') || (c >= u'a' && c <= u'z');
}

bool isAsciiDigit(char16_t c) { return c >= u'0' && c <= u'9'; }

/* `s.trim() === ''` over [from, to). */
bool blankRange(const U16& s, std::size_t from, std::size_t to) {
  for (std::size_t i = from; i < to; i++) {
    if (!isJsSpace(s[i])) return false;
  }
  return true;
}

/* Whether [from, to) holds no JavaScript line terminator (a `.*` run). */
bool dotRun(const U16& s, std::size_t from, std::size_t to) {
  for (std::size_t i = from; i < to; i++) {
    if (isJsLineTerminator(s[i])) return false;
  }
  return true;
}

bool startsWithAt(const U16& s, std::size_t at, const U16& prefix) {
  return at <= s.size() && s.compare(at, prefix.size(), prefix) == 0 &&
         s.size() - at >= prefix.size();
}

std::string toUtf8(const U16& s, std::size_t from, std::size_t to) {
  std::string out;
  for (std::size_t i = from; i < to; i++) {
    unsigned int cp = s[i];
    if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < to && s[i + 1] >= 0xDC00 &&
        s[i + 1] <= 0xDFFF) {
      cp = 0x10000 + ((cp - 0xD800) << 10) + (s[i + 1] - 0xDC00);
      i++;
    } else if (cp >= 0xD800 && cp <= 0xDFFF) {
      cp = 0xFFFD;
    }
    if (cp < 0x80) {
      out.push_back(static_cast<char>(cp));
    } else if (cp < 0x800) {
      out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else if (cp < 0x10000) {
      out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else {
      out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    }
  }
  return out;
}

std::string toUtf8(const U16& s) { return toUtf8(s, 0, s.size()); }

/* The leading spaces of `line` from `at`, or npos when more than `max`
 * (` {0,max}` followed by a non-space). */
std::size_t indentEnd(const U16& line, std::size_t at, std::size_t max) {
  std::size_t i = at;
  while (i < line.size() && line[i] == u' ') i++;
  return i - at <= max ? i : U16::npos;
}

/* A div opening from `at`: ` {0,maxIndent}:{3,}[ \t]*(?:\{(.*)\}|
 * ([A-Za-z][A-Za-z0-9_-]*))[ \t]*$`. Sets `*braces` (the inner text) or
 * `*word`. */
bool matchDivOpenAt(const U16& line, std::size_t at, std::size_t maxIndent,
                    std::optional<U16>* braces, std::optional<U16>* word) {
  std::size_t i = indentEnd(line, at, maxIndent);
  if (i == U16::npos) return false;
  std::size_t colons = i;
  while (i < line.size() && line[i] == u':') i++;
  if (i - colons < 3) return false;
  while (i < line.size() && isSpaceOrTab(line[i])) i++;
  if (i >= line.size()) return false;
  if (line[i] == u'{') {
    std::size_t end = line.size();
    while (end > i + 1 && isSpaceOrTab(line[end - 1])) end--;
    if (end <= i + 1 || line[end - 1] != u'}') return false;
    if (!dotRun(line, i + 1, end - 1)) return false;
    if (braces != nullptr) *braces = line.substr(i + 1, end - 1 - (i + 1));
    return true;
  }
  if (!isAsciiLetter(line[i])) return false;
  std::size_t w = i;
  i++;
  while (i < line.size() && (isAsciiLetter(line[i]) || isAsciiDigit(line[i]) ||
                             line[i] == u'_' || line[i] == u'-')) {
    i++;
  }
  std::size_t wordEnd = i;
  while (i < line.size() && isSpaceOrTab(line[i])) i++;
  if (i != line.size()) return false;
  if (word != nullptr) *word = line.substr(w, wordEnd - w);
  return true;
}

/* `^ {0,3}:{3,}[ \t]*$` */
bool matchDivClose(const U16& line) {
  std::size_t i = indentEnd(line, 0, 3);
  if (i == U16::npos) return false;
  std::size_t colons = i;
  while (i < line.size() && line[i] == u':') i++;
  if (i - colons < 3) return false;
  while (i < line.size() && isSpaceOrTab(line[i])) i++;
  return i == line.size();
}

/* `^ {0,3}(`{3,}|~{3,})(.*)$`: the fence run and the rest. */
bool matchCodeFenceOpen(const U16& line, U16* fence, U16* rest) {
  std::size_t i = indentEnd(line, 0, 3);
  if (i == U16::npos || i >= line.size()) return false;
  char16_t c = line[i];
  if (c != u'`' && c != u'~') return false;
  std::size_t run = i;
  while (i < line.size() && line[i] == c) i++;
  if (i - run < 3) return false;
  if (!dotRun(line, i, line.size())) return false;
  *fence = line.substr(run, i - run);
  *rest = line.substr(i);
  return true;
}

/* `^ {0,3}>`: the offset after the `>`, or npos. */
std::size_t matchQuoteLine(const U16& line) {
  std::size_t i = indentEnd(line, 0, 3);
  if (i == U16::npos || i >= line.size() || line[i] != u'>') return U16::npos;
  return i + 1;
}

/* `^ {0,3}> ?(?:⬆|\*\*❓|⚖)` */
bool matchAnnotationStart(const U16& line) {
  std::size_t i = matchQuoteLine(line);
  if (i == U16::npos) return false;
  static const U16 kQuestion = u"**❓";
  for (std::size_t at : {i + (i < line.size() && line[i] == u' ' ? 1 : 0), i}) {
    if (at < line.size() && (line[at] == 0x2B06 || line[at] == 0x2696)) {
      return true;
    }
    if (startsWithAt(line, at, kQuestion)) return true;
  }
  return false;
}

/* `^ {0,3}>[ \t]?( {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*)$` */
bool matchQuotedDivOpen(const U16& line) {
  std::size_t i = matchQuoteLine(line);
  if (i == U16::npos) return false;
  if (matchDivOpenAt(line, i, 3, nullptr, nullptr)) return true;
  return i < line.size() && isSpaceOrTab(line[i]) &&
         matchDivOpenAt(line, i + 1, 3, nullptr, nullptr);
}

/* `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$` is the validator's; here only the
 * notation's own expressions. */

struct Attributes {
  std::vector<std::string> classes;
  std::optional<std::string> id;
  std::vector<std::pair<std::string, std::string>> pairs;
};

/* `[^\s.#}="']` */
bool isAttrNameChar(char16_t c) {
  return !isJsSpace(c) && c != u'.' && c != u'#' && c != u'}' && c != u'=' &&
         c != u'"' && c != u'\'';
}

bool isKeyStart(char16_t c) { return isAsciiLetter(c) || c == u'_'; }

bool isKeyChar(char16_t c) {
  return isAsciiLetter(c) || isAsciiDigit(c) || c == u'_' || c == u':' ||
         c == u'.' || c == u'-';
}

void setPair(Attributes& a, const std::string& key, const std::string& value) {
  for (auto& p : a.pairs) {
    if (p.first == key) {
      p.second = value;
      return;
    }
  }
  a.pairs.emplace_back(key, value);
}

/* The attribute tokens of `inner`, as the global expression
 * `\.([^\s.#}="']+)|#([^\s.#}="']+)|([A-Za-z_][A-Za-z0-9_:.-]*)=
 * ("[^"]*"|'[^']*'|[^\s}]+)` finds them. */
Attributes parseAttributes(const U16& inner) {
  Attributes a;
  std::size_t i = 0;
  const std::size_t n = inner.size();
  while (i < n) {
    char16_t c = inner[i];
    if ((c == u'.' || c == u'#') && i + 1 < n && isAttrNameChar(inner[i + 1])) {
      std::size_t j = i + 1;
      while (j < n && isAttrNameChar(inner[j])) j++;
      std::string name = toUtf8(inner, i + 1, j);
      if (c == u'.') {
        a.classes.push_back(name);
      } else if (!a.id.has_value()) {
        a.id = name;
      }
      i = j;
      continue;
    }
    if (isKeyStart(c)) {
      std::size_t j = i + 1;
      while (j < n && isKeyChar(inner[j])) j++;
      if (j < n && inner[j] == u'=') {
        std::size_t v = j + 1;
        std::size_t valueEnd = U16::npos;
        if (v < n && (inner[v] == u'"' || inner[v] == u'\'')) {
          std::size_t close = inner.find(inner[v], v + 1);
          if (close != U16::npos) valueEnd = close + 1;
        }
        if (valueEnd == U16::npos) {
          std::size_t k = v;
          while (k < n && !isJsSpace(inner[k]) && inner[k] != u'}') k++;
          if (k > v) valueEnd = k;
        }
        if (valueEnd != U16::npos) {
          U16 value = inner.substr(v, valueEnd - v);
          if (value.size() >= 2 &&
              ((value.front() == u'"' && value.back() == u'"') ||
               (value.front() == u'\'' && value.back() == u'\''))) {
            value = value.substr(1, value.size() - 2);
          }
          setPair(a, toUtf8(inner, i, j), toUtf8(value));
          i = valueEnd;
          continue;
        }
      }
    }
    i++;
  }
  return a;
}

const U16 kAsciiPunctuation = u"!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";
const U16 kMarkOpeners[] = {u"{++", u"{--", u"{~~", u"{==", u"{>>"};
const U16 kMarkClosers[] = {u"++}", u"--}", u"~~}", u"==}", u"<<}"};

int codeIndex(const std::string& code) {
  for (std::size_t i = 0; i < std::size(kNotationFindingCodes); i++) {
    if (code == kNotationFindingCodes[i]) return static_cast<int>(i);
  }
  return -1;
}

int typeIndex(const std::string& type) {
  if (type == "div") return 0;
  if (type == "span") return 1;
  return 2;
}

struct OpenDiv {
  long long start;
  long long contentStart;
  int line;
  Attributes attributes;
};

class Scanner {
 public:
  Scanner(const std::string& utf8, bool tomSpecs)
      : utf8_(utf8), text_(somUtf16Units(utf8)), tomSpecs_(tomSpecs) {
    std::size_t start = 0;
    while (true) {
      std::size_t nl = text_.find(u'\n', start);
      lineStarts_.push_back(static_cast<long long>(start));
      if (nl == U16::npos) {
        lines_.push_back(text_.substr(start));
        break;
      }
      lines_.push_back(text_.substr(start, nl - start));
      start = nl + 1;
    }
  }

  NotationScan scan() {
    blocks();
    kindFindings();
    std::vector<std::size_t> order(elements_.size());
    for (std::size_t i = 0; i < order.size(); i++) order[i] = i;
    std::stable_sort(order.begin(), order.end(),
                     [this](std::size_t x, std::size_t y) {
                       const NotationElement& a = elements_[x];
                       const NotationElement& b = elements_[y];
                       if (a.start != b.start) return a.start < b.start;
                       if (a.end != b.end) return a.end > b.end;
                       return typeIndex(a.type) < typeIndex(b.type);
                     });
    // Parent of each element in `order` (an index into `order`, or -1).
    std::vector<long long> parent(order.size(), -1);
    std::vector<std::size_t> stack;
    for (std::size_t k = 0; k < order.size(); k++) {
      const NotationElement& e = elements_[order[k]];
      while (!stack.empty()) {
        const NotationElement& top = elements_[order[stack.back()]];
        if (e.start >= top.start && e.end <= top.end) break;
        stack.pop_back();
      }
      parent[k] = stack.empty() ? -1 : static_cast<long long>(stack.back());
      stack.push_back(k);
    }
    NotationScan out;
    out.text = utf8_;
    out.elements = build(order, parent, -1);
    std::vector<NotationFinding> findings = findings_;
    std::stable_sort(findings.begin(), findings.end(),
                     [](const NotationFinding& a, const NotationFinding& b) {
                       if (a.offset != b.offset) return a.offset < b.offset;
                       return codeIndex(a.code) < codeIndex(b.code);
                     });
    out.findings = std::move(findings);
    return out;
  }

 private:
  const std::string& utf8_;
  U16 text_;
  bool tomSpecs_;
  std::vector<long long> lineStarts_;
  std::vector<U16> lines_;
  std::vector<NotationElement> elements_;
  std::vector<NotationFinding> findings_;

  std::vector<NotationElement> build(const std::vector<std::size_t>& order,
                                     const std::vector<long long>& parent,
                                     long long of) const {
    std::vector<NotationElement> out;
    for (std::size_t k = 0; k < order.size(); k++) {
      if (parent[k] != of) continue;
      NotationElement e = elements_[order[k]];
      e.children = build(order, parent, static_cast<long long>(k));
      out.push_back(std::move(e));
    }
    return out;
  }

  int lineOf(long long offset) const {
    std::size_t lo = 0;
    std::size_t hi = lineStarts_.size() - 1;
    while (lo < hi) {
      std::size_t mid = (lo + hi + 1) / 2;
      if (lineStarts_[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return static_cast<int>(lo) + 1;
  }

  void find(const char* code, long long offset, const std::string& message) {
    findings_.push_back(NotationFinding{code, offset, lineOf(offset), message});
  }

  // --- Blocks -------------------------------------------------------------

  void blocks() {
    std::vector<OpenDiv> open;
    std::optional<U16> codeFence;
    bool inAnnotation = false;
    std::optional<long long> regionStart;
    long long regionEnd = 0;
    const long long textLen = static_cast<long long>(text_.size());

    auto endRegion = [&]() {
      if (regionStart.has_value()) inlineScan(*regionStart, regionEnd);
      regionStart.reset();
    };

    for (std::size_t i = 0; i < lines_.size(); i++) {
      const U16& line = lines_[i];
      const long long start = lineStarts_[i];
      const long long lineEnd = start + static_cast<long long>(line.size());
      const long long next = i + 1 < lines_.size() ? lineStarts_[i + 1] : textLen;

      if (codeFence.has_value()) {
        std::size_t lead = 0;
        while (lead < line.size() && isJsSpace(line[lead])) lead++;
        if (lead <= 3 && startsWithAt(line, lead, *codeFence)) {
          bool onlyFence = true;
          for (std::size_t k = lead + codeFence->size(); k < line.size(); k++) {
            if (line[k] != (*codeFence)[0] && !isJsSpace(line[k])) {
              onlyFence = false;
              break;
            }
          }
          if (onlyFence) codeFence.reset();
        }
        continue;
      }

      if (matchAnnotationStart(line)) {
        if (!inAnnotation && !open.empty()) {
          find(NotationFindingCode::kAnnotationInsideDiv, start,
               "a comment or question block stands inside a div");
        }
        inAnnotation = true;
      } else if (matchQuoteLine(line) == U16::npos) {
        inAnnotation = false;
      }
      if (inAnnotation) {
        if (matchQuotedDivOpen(line)) {
          find(NotationFindingCode::kDivInsideAnnotation, start,
               "a div stands inside a comment or question block");
        }
        if (!regionStart.has_value()) regionStart = start;
        regionEnd = lineEnd;
        continue;
      }

      U16 fence, rest;
      if (matchCodeFenceOpen(line, &fence, &rest) &&
          !(fence[0] == u'`' && rest.find(u'`') != U16::npos)) {
        endRegion();
        codeFence = fence;
        continue;
      }

      std::optional<U16> braces, word;
      if (matchDivOpenAt(line, 0, 3, &braces, &word)) {
        endRegion();
        Attributes attributes;
        if (braces.has_value()) {
          attributes = parseAttributes(*braces);
        } else {
          attributes.classes.push_back(toUtf8(*word));
        }
        open.push_back(OpenDiv{start, next, static_cast<int>(i) + 1,
                               std::move(attributes)});
        continue;
      }

      if (matchDivClose(line)) {
        endRegion();
        if (open.empty()) {
          find(NotationFindingCode::kStrayClosingFence, start,
               "a closing fence has no open div");
        } else {
          OpenDiv d = std::move(open.back());
          open.pop_back();
          addDiv(d, lineEnd, start, true);
        }
        continue;
      }

      if (blankRange(line, 0, line.size())) {
        endRegion();
        continue;
      }
      if (!regionStart.has_value()) regionStart = start;
      regionEnd = lineEnd;
    }
    endRegion();
    while (!open.empty()) {
      OpenDiv d = std::move(open.back());
      open.pop_back();
      find(NotationFindingCode::kUnclosedDiv, d.start,
           "an opening fence has no closing fence");
      addDiv(d, textLen, textLen, false);
    }
  }

  void addDiv(const OpenDiv& d, long long end, long long contentEnd,
              bool closed) {
    const Attributes& a = d.attributes;
    NotationElement e;
    e.type = "div";
    if (!a.classes.empty()) e.kind = a.classes[0];
    e.classes = a.classes;
    e.id = a.id;
    e.attributes = a.pairs;
    e.start = d.start;
    e.end = end;
    e.contentStart = d.contentStart > contentEnd ? contentEnd : d.contentStart;
    e.contentEnd = contentEnd;
    e.line = d.line;
    e.endLine = lineOf(end > d.start ? end - 1 : d.start);
    e.closed = closed;
    elements_.push_back(std::move(e));
  }

  // --- Inline -------------------------------------------------------------

  bool startsWithMarkOpener(long long at, int* which) const {
    for (int k = 0; k < 5; k++) {
      if (startsWithAt(text_, static_cast<std::size_t>(at), kMarkOpeners[k])) {
        if (which != nullptr) *which = k;
        return true;
      }
    }
    return false;
  }

  void inlineScan(long long start, long long end) {
    const U16& text = text_;
    std::map<long long, long long> literal;
    std::set<long long> escaped;
    for (long long i = start; i < end; i++) {
      char16_t c = text[i];
      if (c == u'\\' && i + 1 < end &&
          kAsciiPunctuation.find(text[i + 1]) != U16::npos) {
        escaped.insert(i + 1);
        i++;
        continue;
      }
      if (c == u'`') {
        long long n = 0;
        while (i + n < end && text[i + n] == u'`') n++;
        long long close = closingBackticks(i + n, end, n);
        if (close >= 0) {
          literal[i] = close + n;
          i = close + n - 1;
        } else {
          i += n - 1;
        }
      }
    }

    std::vector<std::pair<long long, long long>> spans;  // start, end
    std::vector<std::string> spanTypes;
    std::vector<std::pair<long long, long long>> marks;
    std::vector<long long> brackets;
    long long i = start;
    while (i < end) {
      auto skip = literal.find(i);
      if (skip != literal.end()) {
        i = skip->second;
        continue;
      }
      char16_t c = text[i];
      if (escaped.count(i) != 0 || (c == u'\\' && escaped.count(i + 1) != 0)) {
        i++;
        continue;
      }
      if (c == u'{') {
        int which = -1;
        if (startsWithMarkOpener(i, &which)) {
          const U16& closer = kMarkClosers[which];
          std::size_t close = text.find(closer, static_cast<std::size_t>(i + 3));
          if (close != U16::npos &&
              static_cast<long long>(close + closer.size()) <= end) {
            marks.emplace_back(i,
                               static_cast<long long>(close + closer.size()));
          }
          i += 3;
          continue;
        }
      }
      if (c == u'[') {
        brackets.push_back(i);
      } else if (c == u']' && !brackets.empty()) {
        long long openAt = brackets.back();
        brackets.pop_back();
        if (i + 1 < end && text[i + 1] == u'{' && escaped.count(i + 1) == 0 &&
            !startsWithMarkOpener(i + 1, nullptr)) {
          long long close = closingBrace(i + 2, end);
          if (close < 0) {
            find(NotationFindingCode::kUnclosedSpan, i + 1,
                 "a span's attribute braces do not close on the paragraph");
          } else {
            Attributes a = parseAttributes(text.substr(
                static_cast<std::size_t>(i + 2),
                static_cast<std::size_t>(close - (i + 2))));
            NotationElement span;
            span.type = "span";
            if (!a.classes.empty()) span.kind = a.classes[0];
            span.classes = a.classes;
            span.id = a.id;
            span.attributes = a.pairs;
            span.start = openAt;
            span.end = close + 1;
            span.contentStart = openAt + 1;
            span.contentEnd = i;
            span.line = lineOf(openAt);
            span.endLine = lineOf(close);
            span.closed = true;
            spans.emplace_back(span.start, span.end);
            spanTypes.push_back("span");
            elements_.push_back(std::move(span));
            i = close + 1;
            continue;
          }
        }
      } else if (c == u'(' && i + 3 < end && text[i + 3] == u' ') {
        char16_t a0 = text[i + 1];
        char16_t a1 = text[i + 2];
        const char* kind = nullptr;
        const char* arrow = nullptr;
        if (a0 == u'-' && a1 == u'>') {
          kind = "trace";
          arrow = "->";
        } else if (a0 == u'<' && a1 == u'-') {
          kind = "provenance";
          arrow = "<-";
        } else if (a0 == u'<' && a1 == u'~') {
          kind = "provenance";
          arrow = "<~";
        }
        if (kind != nullptr) {
          long long close = closingParenthesis(i + 4, end, literal);
          if (close > i + 4 &&
              !blankRange(text, static_cast<std::size_t>(i + 4),
                          static_cast<std::size_t>(close))) {
            NotationElement citation;
            citation.type = "citation";
            citation.kind = kind;
            citation.classes = {kind};
            citation.shape = arrow;
            citation.start = i;
            citation.end = close + 1;
            citation.contentStart = i + 4;
            citation.contentEnd = close;
            citation.line = lineOf(i);
            citation.endLine = lineOf(close);
            citation.closed = true;
            spans.emplace_back(citation.start, citation.end);
            spanTypes.push_back("citation");
            elements_.push_back(std::move(citation));
            i += 4;
            continue;
          }
        }
      }
      i++;
    }

    for (const auto& [ms, me] : marks) {
      for (std::size_t k = 0; k < spans.size(); k++) {
        long long es = spans[k].first;
        long long ee = spans[k].second;
        bool crosses = (ms < es && es < me && me < ee) ||
                       (es < ms && ms < ee && ee < me);
        if (crosses) {
          find(NotationFindingCode::kMarkAcrossNotation, ms,
               "an inline review mark crosses the boundary of a " +
                   spanTypes[k]);
          break;
        }
      }
    }
  }

  long long closingBackticks(long long from, long long end, long long n) const {
    long long i = from;
    while (i < end) {
      if (text_[i] == u'`') {
        long long m = 0;
        while (i + m < end && text_[i + m] == u'`') m++;
        if (m == n) return i;
        i += m;
      } else {
        i++;
      }
    }
    return -1;
  }

  long long closingBrace(long long from, long long end) const {
    char16_t quote = 0;
    for (long long i = from; i < end; i++) {
      char16_t c = text_[i];
      if (quote != 0) {
        if (c == quote) quote = 0;
      } else if (c == u'"' || c == u'\'') {
        quote = c;
      } else if (c == u'}') {
        return i;
      } else if (c == u'{') {
        return -1;
      }
    }
    return -1;
  }

  long long closingParenthesis(long long from, long long end,
                               const std::map<long long, long long>& literal)
      const {
    int depth = 0;
    long long i = from;
    while (i < end) {
      auto skip = literal.find(i);
      if (skip != literal.end()) {
        i = skip->second;
        continue;
      }
      char16_t c = text_[i];
      if (c == u'(') {
        depth++;
      } else if (c == u')') {
        if (depth == 0) return i;
        depth--;
      }
      i++;
    }
    return -1;
  }

  // --- Kinds --------------------------------------------------------------

  void kindFindings() {
    // `find` appends to findings_, never to elements_, so the loop is safe.
    for (const NotationElement& e : elements_) {
      if (e.type == "citation") continue;
      if (e.type == "div" && e.kind.has_value() && *e.kind == "rejected") {
        find(NotationFindingCode::kRejectedBlock, e.start,
             "a rejected block waits for its resolution");
      }
      if (!tomSpecs_) continue;
      if (!e.kind.has_value()) {
        if (e.type == "div") {
          find(NotationFindingCode::kDivWithoutKind, e.start,
               "a div's attributes hold no class");
        }
      } else if (!e.isRegistered()) {
        find(NotationFindingCode::kUnknownKind, e.start,
             "the kind \"" + *e.kind + "\" is not registered");
      }
    }
  }
};

std::string optJson(const std::optional<std::string>& v) {
  return v.has_value() ? jsonEncodeStr(*v) : std::string("null");
}

}  // namespace

bool isRegisteredNotationKind(const std::string& kind) {
  for (const char* k : registeredNotationKinds) {
    if (kind == k) return true;
  }
  return false;
}

std::string notationSeverity(const std::string& code) {
  return code == NotationFindingCode::kUnknownKind ? "warning" : "error";
}

bool NotationElement::isRegistered() const {
  return kind.has_value() && isRegisteredNotationKind(*kind);
}

std::string NotationFinding::toString() const {
  return "line " + std::to_string(line) + ": " + code + " — " + message;
}

std::vector<const NotationElement*> NotationScan::all() const {
  std::vector<const NotationElement*> out;
  std::vector<const NotationElement*> stack;
  for (auto it = elements.rbegin(); it != elements.rend(); ++it) {
    stack.push_back(&*it);
  }
  while (!stack.empty()) {
    const NotationElement* e = stack.back();
    stack.pop_back();
    out.push_back(e);
    for (auto it = e->children.rbegin(); it != e->children.rend(); ++it) {
      stack.push_back(&*it);
    }
  }
  return out;
}

bool NotationScan::hasErrors() const {
  for (const NotationFinding& f : findings) {
    if (f.severity() == "error") return true;
  }
  return false;
}

std::string NotationScan::elementJson(const NotationElement& e) const {
  const U16 units = somUtf16Units(text);
  auto slice = [&units](long long from, long long to) {
    return toUtf8(units, static_cast<std::size_t>(from),
                  static_cast<std::size_t>(to));
  };
  std::string out = "{\"type\":" + jsonEncodeStr(e.type) +
                    ",\"kind\":" + optJson(e.kind) + ",\"classes\":[";
  for (std::size_t i = 0; i < e.classes.size(); i++) {
    if (i > 0) out += ",";
    out += jsonEncodeStr(e.classes[i]);
  }
  out += "],\"id\":" + optJson(e.id) + ",\"attributes\":{";
  for (std::size_t i = 0; i < e.attributes.size(); i++) {
    if (i > 0) out += ",";
    out += jsonEncodeStr(e.attributes[i].first) + ":" +
           jsonEncodeStr(e.attributes[i].second);
  }
  out += "},\"shape\":" + optJson(e.shape) +
         ",\"start\":" + std::to_string(e.start) +
         ",\"end\":" + std::to_string(e.end) +
         ",\"line\":" + std::to_string(e.line) +
         ",\"endLine\":" + std::to_string(e.endLine) +
         ",\"closed\":" + (e.closed ? "true" : "false") +
         ",\"source\":" + jsonEncodeStr(slice(e.start, e.end)) +
         ",\"content\":" + jsonEncodeStr(slice(e.contentStart, e.contentEnd)) +
         ",\"children\":[";
  for (std::size_t i = 0; i < e.children.size(); i++) {
    if (i > 0) out += ",";
    out += elementJson(e.children[i]);
  }
  out += "]}";
  return out;
}

std::string NotationScan::elementsJson() const {
  std::string out = "[";
  for (std::size_t i = 0; i < elements.size(); i++) {
    if (i > 0) out += ",";
    out += elementJson(elements[i]);
  }
  return out + "]";
}

std::string NotationScan::findingsJson() const {
  std::string out = "[";
  for (std::size_t i = 0; i < findings.size(); i++) {
    if (i > 0) out += ",";
    out += "{\"code\":" + jsonEncodeStr(findings[i].code) +
           ",\"severity\":" + jsonEncodeStr(findings[i].severity()) +
           ",\"line\":" + std::to_string(findings[i].line) + "}";
  }
  return out + "]";
}

NotationScan scanNotation(const std::string& text, bool tomSpecs) {
  return Scanner(text, tomSpecs).scan();
}

}  // namespace som
