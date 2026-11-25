/* docspecs_validator — implementation. See docspecs_validator.hpp; a faithful
 * idiomatic-C++ port of the C `docspecs_validator.c` (itself a 1:1 port of the
 * Go `docspecs_validator.go`, SOM §14). */
#include "docspecs_validator.hpp"

#include <cstddef>
#include <optional>
#include <tuple>
#include <regex>
#include <map>
#include <functional>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>

#include "spec_document_markdown.hpp"
#include "spec_notation.hpp"

namespace som {

namespace {

/* ---- small helpers ------------------------------------------------------- */

bool isAsciiWs(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

char toUpperAscii(char c) {
  return (c >= 'a' && c <= 'z') ? static_cast<char>(c - 'a' + 'A') : c;
}

char toLowerAscii(char c) {
  return (c >= 'A' && c <= 'Z') ? static_cast<char>(c - 'A' + 'a') : c;
}

/* strings.TrimSpace over ASCII whitespace. */
std::string trimSpace(const std::string& s) {
  std::size_t start = 0;
  std::size_t end = s.size();
  while (start < end && isAsciiWs(s[start])) {
    start++;
  }
  while (end > start && isAsciiWs(s[end - 1])) {
    end--;
  }
  return s.substr(start, end - start);
}

std::string upperAscii(const std::string& s) {
  std::string out = s;
  for (char& c : out) {
    c = toUpperAscii(c);
  }
  return out;
}

std::string lowerAscii(const std::string& s) {
  std::string out = s;
  for (char& c : out) {
    c = toLowerAscii(c);
  }
  return out;
}

/* utf8 rune count (for text-length checks — Go uses len([]rune(text))). */
std::size_t runeCount(const std::string& s) {
  std::size_t count = 0;
  for (unsigned char c : s) {
    if ((c & 0xC0) != 0x80) {
      count++;
    }
  }
  return count;
}

std::string itoa(long long v) { return std::to_string(v); }

/* ---- mini regex (hand-rolled, DocSpecs pattern subset) ------------------- */

/* A backtracking matcher for the DocSpecs `pattern-check-id` subset the Go
 * `regexp` package handles here: `^` / `$` anchors, literals, `.`, character
 * classes `[...]` (with ranges and a leading `^` negation), and the `*` / `+`
 * / `?` quantifiers. Semantics mirror Go's `MatchString` (an *unanchored*
 * search unless the pattern is `^`-anchored). Compilation never fails for a
 * well-formed subset pattern; a malformed pattern (unterminated class) makes
 * `matches` return false — the Go code returns false when `Compile` errors. */

enum class RxKind { Literal, Any, Class, Start, End };

struct RxAtom {
  RxKind kind = RxKind::Literal;
  char literal = 0;       // Literal
  std::size_t clsPos = 0; // Class: index into pattern at '['
  std::size_t clsLen = 0; // bytes from '[' to ']' inclusive
  char quant = 0;         // 0, '*', '+', '?'
};

struct Rx {
  std::vector<RxAtom> atoms;
  bool ok = true;
  std::string pattern;  // retained so class atoms can index into it
};

/* Reports whether char `c` is in class token `[...]` (spans '['..']'). */
bool rxClassMatch(const std::string& pat, std::size_t pos, std::size_t clsLen,
                  char c) {
  // pat[pos] == '[', pat[pos + clsLen - 1] == ']'
  std::size_t i = pos + 1;
  std::size_t end = pos + clsLen - 1;
  bool negate = false;
  if (i < end && pat[i] == '^') {
    negate = true;
    i++;
  }
  bool found = false;
  while (i < end) {
    if (i + 2 < end && pat[i + 1] == '-' && pat[i + 2] != ']') {
      char lo = pat[i];
      char hi = pat[i + 2];
      if (static_cast<unsigned char>(c) >= static_cast<unsigned char>(lo) &&
          static_cast<unsigned char>(c) <= static_cast<unsigned char>(hi)) {
        found = true;
      }
      i += 3;
    } else {
      if (pat[i] == c) {
        found = true;
      }
      i++;
    }
  }
  return negate ? !found : found;
}

/* Compiles the subset pattern into `rx`. */
Rx rxCompile(const std::string& pattern) {
  Rx rx;
  rx.pattern = pattern;
  std::size_t n = pattern.size();
  for (std::size_t i = 0; i < n;) {
    RxAtom atom;
    char c = pattern[i];
    if (c == '^') {
      atom.kind = RxKind::Start;
      i++;
    } else if (c == '$') {
      atom.kind = RxKind::End;
      i++;
    } else if (c == '.') {
      atom.kind = RxKind::Any;
      i++;
    } else if (c == '[') {
      std::size_t j = i + 1;
      if (j < n && pattern[j] == '^') {
        j++;
      }
      if (j < n && pattern[j] == ']') {
        j++;  // a literal ']' as first class member
      }
      while (j < n && pattern[j] != ']') {
        j++;
      }
      if (j >= n) {
        rx.ok = false;  // unterminated class → compile error
        rx.atoms.clear();
        return rx;
      }
      atom.kind = RxKind::Class;
      atom.clsPos = i;
      atom.clsLen = (j - i) + 1;  // include ']'
      i = j + 1;
    } else if (c == '\\' && i + 1 < n) {
      atom.kind = RxKind::Literal;
      atom.literal = pattern[i + 1];
      i += 2;
    } else {
      atom.kind = RxKind::Literal;
      atom.literal = c;
      i++;
    }
    // quantifier (anchors take none)
    if (atom.kind != RxKind::Start && atom.kind != RxKind::End && i < n &&
        (pattern[i] == '*' || pattern[i] == '+' || pattern[i] == '?')) {
      atom.quant = pattern[i];
      i++;
    }
    rx.atoms.push_back(atom);
  }
  return rx;
}

/* Reports whether a single non-quantified atom matches text[pos] (never called
 * for anchors). */
bool rxAtomCharMatch(const Rx& rx, const RxAtom& a, const std::string& text,
                     std::size_t pos) {
  if (pos >= text.size()) {
    return false;
  }
  char c = text[pos];
  switch (a.kind) {
    case RxKind::Literal:
      return c == a.literal;
    case RxKind::Any:
      return c != '\n';
    case RxKind::Class:
      return rxClassMatch(rx.pattern, a.clsPos, a.clsLen, c);
    default:
      return false;
  }
}

/* Backtracking match of atoms[ai..] against text[pos..]. */
bool rxMatchHere(const Rx& rx, std::size_t ai, const std::string& text,
                 std::size_t pos) {
  if (ai == rx.atoms.size()) {
    return true;
  }
  const RxAtom& a = rx.atoms[ai];
  std::size_t tlen = text.size();
  if (a.kind == RxKind::Start) {
    return pos == 0 ? rxMatchHere(rx, ai + 1, text, pos) : false;
  }
  if (a.kind == RxKind::End) {
    return pos == tlen ? rxMatchHere(rx, ai + 1, text, pos) : false;
  }
  if (a.quant == '*' || a.quant == '+') {
    // greedy: consume as many as possible, then backtrack.
    std::size_t count = 0;
    while (rxAtomCharMatch(rx, a, text, pos + count)) {
      count++;
    }
    std::size_t min = (a.quant == '+') ? 1 : 0;
    for (std::size_t k = count + 1; k-- > min;) {
      if (rxMatchHere(rx, ai + 1, text, pos + k)) {
        return true;
      }
      if (k == 0) {
        break;
      }
    }
    return false;
  }
  if (a.quant == '?') {
    if (rxAtomCharMatch(rx, a, text, pos) &&
        rxMatchHere(rx, ai + 1, text, pos + 1)) {
      return true;
    }
    return rxMatchHere(rx, ai + 1, text, pos);
  }
  if (!rxAtomCharMatch(rx, a, text, pos)) {
    return false;
  }
  return rxMatchHere(rx, ai + 1, text, pos + 1);
}

/* Go MatchString: an unanchored search. */
bool rxSearch(const Rx& rx, const std::string& text) {
  if (!rx.ok) {
    return false;
  }
  std::size_t tlen = text.size();
  for (std::size_t start = 0;; start++) {
    if (rxMatchHere(rx, 0, text, start)) {
      return true;
    }
    if (start >= tlen) {
      break;
    }
  }
  return false;
}

/* ---- markdown scanners (mirror the codec's regex-equivalents) ------------ */

/* mdTrailingWSRE = `\s+$` — strip trailing ASCII whitespace. */
std::string stripTrailingWs(const std::string& s) {
  std::size_t n = s.size();
  while (n > 0 && isAsciiWs(s[n - 1])) {
    n--;
  }
  return s.substr(0, n);
}

/* docspecHeaderRE = `^<!--\s*docspec:\s*(\S+)\s*-->\s*$`. On match writes group
 * 1 to `schema` and returns true. */
bool matchDocspecHeader(const std::string& s, std::string* schema) {
  if (s.compare(0, 4, "<!--") != 0) {
    return false;
  }
  std::size_t p = 4;
  std::size_t n = s.size();
  while (p < n && isAsciiWs(s[p])) {
    p++;
  }
  if (s.compare(p, 8, "docspec:") != 0) {
    return false;
  }
  p += 8;
  while (p < n && isAsciiWs(s[p])) {
    p++;
  }
  std::size_t idStart = p;
  while (p < n && !isAsciiWs(s[p])) {
    p++;
  }
  if (p == idStart) {
    return false;  // \S+ requires at least one
  }
  std::size_t idEnd = p;
  while (p < n && isAsciiWs(s[p])) {
    p++;
  }
  if (s.compare(p, 3, "-->") != 0) {
    return false;
  }
  p += 3;
  while (p < n) {
    if (!isAsciiWs(s[p])) {
      return false;
    }
    p++;
  }
  *schema = s.substr(idStart, idEnd - idStart);
  return true;
}

/* mdHeadingLineRE = `^(#+)\s+(.*)$`. Writes hash count to `level`, rest (group
 * 2) to `rest`, returns true. */
bool matchHeadingLine(const std::string& s, int* level, std::string* rest) {
  std::size_t hashes = 0;
  while (hashes < s.size() && s[hashes] == '#') {
    hashes++;
  }
  if (hashes == 0) {
    return false;
  }
  std::size_t p = hashes;
  if (p >= s.size() || !isAsciiWs(s[p])) {
    return false;
  }
  std::size_t ws = 0;
  while (p + ws < s.size() && isAsciiWs(s[p + ws])) {
    ws++;
  }
  *level = static_cast<int>(hashes);
  *rest = s.substr(p + ws);
  return true;
}

/* mdHeadlineCommentRE = `^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$`. Three-group
 * (codespecs_mapping.md §9.2): group 1 = the section id, group 2 = the optional
 * key=value region (`codeSpec`), group 3 = the heading title. Writes group 1 to
 * `id` and group 3
 * (the title) to `title`; the middle region is skipped. Returns true. */
bool matchHeadlineComment(const std::string& s, std::string* id,
                          std::string* title) {
  if (s.compare(0, 5, "<!--[") != 0) {
    return false;
  }
  std::size_t p = 5;
  std::size_t close = s.find(']', p);
  if (close == std::string::npos || close == p) {
    return false;
  }
  // `([^>]*)-->` — the region runs from after `]` up to a `-->` with no `>`
  // before it.
  std::size_t r = close + 1;
  std::size_t end = s.find("-->", r);
  if (end == std::string::npos) {
    return false;
  }
  if (s.find('>', r) != end + 2) {
    return false;
  }
  *id = s.substr(p, close - p);
  std::size_t after = end + 3;
  while (after < s.size() && isAsciiWs(s[after])) {
    after++;
  }
  *title = s.substr(after);
  return true;
}

/* mdFieldLabelRE = `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$`. Writes group 1 (label)
 * and group 2 (value); returns true. */
bool matchFieldLabel(const std::string& s, std::string* label,
                     std::string* value) {
  if (s.empty()) {
    return false;
  }
  char c0 = s[0];
  if (!((c0 >= 'A' && c0 <= 'Z') || (c0 >= 'a' && c0 <= 'z'))) {
    return false;
  }
  std::size_t i = 1;
  std::size_t n = s.size();
  while (i < n && ((s[i] >= 'A' && s[i] <= 'Z') || (s[i] >= 'a' && s[i] <= 'z') ||
                   (s[i] >= '0' && s[i] <= '9') || s[i] == '_')) {
    i++;
  }
  if (i >= n || s[i] != ':') {
    return false;
  }
  std::size_t nameEnd = i;
  i++;
  if (i < n && s[i] == ' ') {
    i++;
  }
  *label = s.substr(0, nameEnd);
  *value = s.substr(i);
  return true;
}

/* ---- schema loading helpers ---------------------------------------------- */

std::optional<DocSpecsPatternCheck> patternCheckFromNode(const YamlRef& node) {
  if (node == nullptr) {
    return std::nullopt;
  }
  DocSpecsPatternCheck pc;
  if (node->type == YamlType::Map) {
    pc.pattern = yamlScalarString(yamlGet(node, "pattern"));
    pc.errorMessage = yamlScalarString(yamlGet(node, "error-message"));
  } else {
    pc.pattern = yamlScalarString(node);
    pc.errorMessage = "";
  }
  return pc;
}

/* dvIsTrue: a plain-scalar "true" string. */
bool dvIsTrue(const YamlRef& v) {
  const std::string* s = yamlAsStr(v);
  return s != nullptr && *s == "true";
}

/* dvInt: reads the value as an int when it is one. */
bool dvInt(const YamlRef& v, int* out) {
  if (v == nullptr) {
    return false;
  }
  std::optional<long long> n = yamlAsInt(v);
  if (n.has_value()) {
    *out = static_cast<int>(*n);
    return true;
  }
  return false;
}

bool isSupportedSectionTypeKey(const std::string& k) {
  return k == "prefix" || k == "pattern-check-id" || k == "subsection-types" ||
         k == "format" || k == "text-required" || k == "min-text-length" ||
         k == "max-text-length" || k == "description" ||
         k == "validation-prompt";
}

void loadSectionTypes(DocSpecsSchema& s, const YamlRef& node) {
  if (node == nullptr || node->type != YamlType::Map) {
    return;
  }
  for (const auto& kv : node->map) {
    const std::string& name = kv.first;
    const YamlPtr& raw = kv.second;
    if (raw == nullptr || raw->type != YamlType::Map) {
      continue;
    }
    YamlRef rawRef = raw;
    DocSpecsSectionType t;
    t.name = name;

    // subsection-types
    YamlRef subNode = yamlGet(rawRef, "subsection-types");
    if (subNode != nullptr && subNode->type == YamlType::Map) {
      for (const auto& skv : subNode->map) {
        const std::string& subName = skv.first;
        YamlRef subRaw = skv.second;
        DocSpecsSubsectionRule rule;
        rule.name = subName;
        if (subRaw != nullptr && subRaw->type == YamlType::Map) {
          int nval;
          if (dvInt(yamlGet(subRaw, "min-count"), &nval)) {
            rule.minCount = nval;
          }
          if (dvInt(yamlGet(subRaw, "max-count"), &nval)) {
            rule.hasMax = true;
            rule.maxCount = nval;
          }
        }
        t.subsectionTypes.push_back(std::move(rule));
      }
    }
    // warn on unsupported keys
    for (const auto& rk : raw->map) {
      if (!isSupportedSectionTypeKey(rk.first)) {
        s.warnings.push_back("unsupported key \"" + rk.first +
                             "\" on section-type \"" + name + "\" ignored");
      }
    }
    // prefix
    if (yamlGet(rawRef, "prefix") != nullptr) {
      t.prefix = yamlScalarString(yamlGet(rawRef, "prefix"));
    } else {
      t.prefix = docspecsIdTransform(upperAscii(name));
    }
    int nval;
    if (dvInt(yamlGet(rawRef, "min-text-length"), &nval)) {
      t.hasMinTextLength = true;
      t.minTextLength = nval;
    }
    if (dvInt(yamlGet(rawRef, "max-text-length"), &nval)) {
      t.hasMaxTextLength = true;
      t.maxTextLength = nval;
    }
    t.patternCheck = patternCheckFromNode(yamlGet(rawRef, "pattern-check-id"));
    t.format = yamlScalarString(yamlGet(rawRef, "format"));
    t.textRequired = dvIsTrue(yamlGet(rawRef, "text-required"));
    t.description = yamlScalarString(yamlGet(rawRef, "description"));
    t.validationPrompt = yamlScalarString(yamlGet(rawRef, "validation-prompt"));
    s.sectionTypes.push_back(std::move(t));
  }
}

void loadFormTypes(DocSpecsSchema& s, const YamlRef& node) {
  if (node == nullptr || node->type != YamlType::Map) {
    return;
  }
  for (const auto& kv : node->map) {
    const std::string& name = kv.first;
    const YamlPtr& raw = kv.second;
    if (raw == nullptr || raw->type != YamlType::Map) {
      continue;
    }
    YamlRef rawRef = raw;
    for (const auto& rk : raw->map) {
      if (rk.first != "fields") {
        s.warnings.push_back("unsupported key \"" + rk.first +
                             "\" on form-type \"" + name + "\" ignored");
      }
    }
    DocSpecsFormType ft;
    ft.name = name;
    YamlRef fieldsNode = yamlGet(rawRef, "fields");
    if (fieldsNode != nullptr && fieldsNode->type == YamlType::Seq) {
      for (const auto& fmPtr : fieldsNode->seq) {
        if (fmPtr == nullptr || fmPtr->type != YamlType::Map) {
          continue;
        }
        YamlRef fm = fmPtr;
        DocSpecsFormField f;
        f.name = yamlScalarString(yamlGet(fm, "fieldname"));
        f.required = dvIsTrue(yamlGet(fm, "required"));
        f.description = yamlScalarString(yamlGet(fm, "description"));
        f.patternCheck = patternCheckFromNode(yamlGet(fm, "pattern-check"));
        ft.fields.push_back(std::move(f));
      }
    }
    s.formTypes.push_back(std::move(ft));
  }
}

/* Loads `document:`. Answers false (with `*err`) for a malformed schema: a
 * document section whose `position` is not one of kDocSpecsPositions. */
bool loadDocument(DocSpecsSchema& s, const YamlRef& node, std::string* err) {
  if (node == nullptr || node->type != YamlType::Map) {
    return true;
  }
  for (const auto& kv : node->map) {
    const std::string& k = kv.first;
    YamlRef v = kv.second;
    if (k == "sections") {
      if (v == nullptr || v->type != YamlType::Map) {
        continue;
      }
      for (const auto& skv : v->map) {
        const std::string& sKey = skv.first;
        YamlRef sRaw = skv.second;
        DocSpecsDocumentSection ds;
        ds.key = sKey;
        ds.sectionType = sKey;
        if (sRaw != nullptr && sRaw->type == YamlType::Map) {
          if (yamlGet(sRaw, "section-type") != nullptr) {
            ds.sectionType = yamlScalarString(yamlGet(sRaw, "section-type"));
          }
          ds.optional = dvIsTrue(yamlGet(sRaw, "optional"));
          if (yamlGet(sRaw, "position") != nullptr) {
            ds.position = yamlScalarString(yamlGet(sRaw, "position"));
            bool known = false;
            for (const char* p : kDocSpecsPositions) {
              if (ds.position == p) {
                known = true;
                break;
              }
            }
            if (!known) {
              if (err != nullptr) {
                *err = "document section \"" + sKey + "\": position \"" +
                       ds.position + "\" is not one of relative, any";
              }
              return false;
            }
          }
        }
        s.documentSections.push_back(std::move(ds));
      }
    } else if (k != "name" && k != "description") {
      s.warnings.push_back("unsupported document key \"" + k + "\" ignored");
    }
  }
  return true;
}

/* ---- validator internals ------------------------------------------------- */

void dvPush(std::vector<DocSpecsViolation>& out, const std::string& rule,
            int line, const std::string& message, const std::string& sectionId,
            const std::string& path) {
  DocSpecsViolation v;
  v.rule = rule;
  v.line = line;
  v.message = message;
  v.sectionId = sectionId;
  v.path = path;
  out.push_back(std::move(v));
}

}  // namespace

/* ---- violation ----------------------------------------------------------- */

std::string DocSpecsViolation::display() const {
  std::string out = "line " + itoa(line) + ": " + rule;
  if (!sectionId.empty()) {
    out += " [" + sectionId + "]";
  }
  if (!path.empty()) {
    out += " (" + path + ")";
  }
  out += " \xe2\x80\x94 " + message;  // U+2014 em-dash
  return out;
}

/* ---- section ------------------------------------------------------------- */

std::string DocSpecsSection::text() const {
  std::size_t start = 0;
  std::size_t end = bodyLines.size();
  while (start < end && trimSpace(bodyLines[start]).empty()) {
    start++;
  }
  while (end > start && trimSpace(bodyLines[end - 1]).empty()) {
    end--;
  }
  std::string out;
  for (std::size_t i = start; i < end; i++) {
    if (i > start) {
      out += '\n';
    }
    out += bodyLines[i];
  }
  return out;
}

/* ---- id transform -------------------------------------------------------- */

std::string docspecsIdTransform(const std::string& id) {
  std::string out;
  std::size_t i = 0;
  std::size_t n = id.size();
  auto alnumUs = [](char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') || c == '_';
  };
  while (i < n) {
    char c = id[i];
    if (alnumUs(c)) {
      out += c;
      i++;
    } else {
      out += '_';
      i++;
      while (i < n && !alnumUs(id[i])) {
        i++;
      }
    }
  }
  return out;
}

/* ---- document parse ------------------------------------------------------ */

namespace {

/* A styled-div heading (the DocSpecs specification's *Styled-div headings*):
 * a whole line `<div class="heading<N>" ...>...</div>` at column 0 with N >= 7
 * reads as a heading of level N whose text is the div's inner text with
 * `&amp;`, `&lt;`, `&gt;` decoded and trimmed. A `heading<N>` div with N <= 6
 * is content. */
bool matchStyledDivHeading(const std::string& line, int* level,
                           std::string* rest) {
  static const std::string open = "<div class=\"heading";
  static const std::string close = "</div>";
  if (line.compare(0, open.size(), open) != 0) return false;
  std::size_t p = open.size();
  std::size_t digits = p;
  while (p < line.size() && line[p] >= '0' && line[p] <= '9') p++;
  if (p == digits || p >= line.size() || line[p] != '"') return false;
  std::size_t gt = line.find('>', p + 1);
  if (gt == std::string::npos || line.size() < close.size() ||
      line.compare(line.size() - close.size(), close.size(), close) != 0 ||
      gt + 1 > line.size() - close.size()) {
    return false;
  }
  long long n = std::stoll(line.substr(digits, p - digits).substr(0, 9));
  if (n < 7) return false;
  std::string text = line.substr(gt + 1, line.size() - close.size() - gt - 1);
  auto replaceAll = [](std::string s, const std::string& from,
                       const std::string& to) {
    std::string out;
    std::size_t pos = 0;
    for (std::size_t at = s.find(from); at != std::string::npos;
         at = s.find(from, pos)) {
      out += s.substr(pos, at - pos) + to;
      pos = at + from.size();
    }
    return out + s.substr(pos);
  };
  text = replaceAll(text, "&lt;", "<");
  text = replaceAll(text, "&gt;", ">");
  text = replaceAll(text, "&amp;", "&");
  *level = static_cast<int>(n);
  *rest = trimSpace(text);
  return true;
}

/* `text` with a leading `<a id="X"></a>` removed when X is the section's own
 * anchor: `id`, or `<A>/.../<id>` with no empty segment (Section Anchors). */
std::string stripOwnAnchorText(const std::string& text,
                               const std::string& id);

}  // namespace

std::string docspecsStripOwnAnchor(const std::string& title,
                                   const std::string& id) {
  return stripOwnAnchorText(title, id);
}

namespace {

std::string stripOwnAnchorText(const std::string& text, const std::string& id) {
  if (text.compare(0, 7, "<a id=\"") != 0) return text;
  std::size_t q = text.find('"', 7);
  if (q == std::string::npos || text.compare(q + 1, 5, "></a>") != 0) {
    return text;
  }
  const std::string anchor = text.substr(7, q - 7);
  bool own = anchor == id;
  const std::string tail = "/" + id;
  if (!own && anchor.size() > tail.size() &&
      anchor.compare(anchor.size() - tail.size(), tail.size(), tail) == 0) {
    own = anchor.front() != '/' && anchor.find("//") == std::string::npos;
  }
  if (!own) return text;
  std::size_t e = q + 6;
  while (e < text.size() && isAsciiWs(text[e])) e++;
  return text.substr(e);
}

}  // namespace

DocSpecsDocument docspecsParseDocument(const std::string& text) {
  DocSpecsDocument doc;
  doc.declaredSchema = "";

  SpecMarkdownFenceTracker fence;
  std::vector<DocSpecsSection*> stack;  // borrowed; owned by tree
  bool readable = false;

  std::size_t idx = 0;
  std::size_t cursor = 0;
  std::size_t textLen = text.size();
  for (;;) {
    std::size_t nl = text.find('\n', cursor);
    std::size_t rawLen =
        (nl != std::string::npos) ? (nl - cursor) : (textLen - cursor);
    std::string raw = text.substr(cursor, rawLen);
    int lineNo = static_cast<int>(idx + 1);
    std::string line = stripTrailingWs(raw);

    bool handled = false;
    if (!fence.inFence()) {
      if (stack.empty() && doc.declaredSchema.empty()) {
        std::string sch;
        if (matchDocspecHeader(line, &sch)) {
          doc.declaredSchema = sch;
          fence.feed(raw);
          handled = true;
        }
      }
      // A stripped rendition (SOM §11.1): its readable header stands before
      // the root heading, and its appendix after the marker is not part of
      // the document.
      if (!handled && stack.empty() && markdownIsReadableComment(line)) {
        readable = true;
        fence.feed(raw);
        handled = true;
      }
      if (!handled && readable && line == kSpecMarkdownAppendixMarker) {
        break;
      }
      if (!handled) {
        int level = 0;
        std::string rest;
        if (matchHeadingLine(line, &level, &rest) ||
            matchStyledDivHeading(line, &level, &rest)) {
          auto section = std::make_unique<DocSpecsSection>();
          std::string cid;
          std::string ctitle;
          if (matchHeadlineComment(rest, &cid, &ctitle)) {
            // codespecs_mapping.md §9.2: the title is group 3 (the region
            // between `]…-->` is the optional codeSpec key=value, not part of
            // the title).
            section->id = cid;
            // The title without the section's own anchor (Section Anchors).
            section->title = stripOwnAnchorText(ctitle, cid);
            section->level = level;
            section->line = lineNo;
          } else {
            dvPush(doc.violations, kDocSpecsRuleMalformedHeading, lineNo,
                   "heading \"" + rest +
                       "\" carries no <!--[SECTION-ID]--> headline comment",
                   "", "");
            section->id = "";
            section->title = rest;
            section->level = level;
            section->line = lineNo;
          }
          while (!stack.empty() && stack.back()->level >= level) {
            stack.pop_back();
          }
          DocSpecsSection* rawPtr = section.get();
          if (!stack.empty()) {
            stack.back()->children.push_back(std::move(section));
          } else {
            doc.sections.push_back(std::move(section));
          }
          stack.push_back(rawPtr);
          fence.feed(raw);
          handled = true;
        }
      }
    }
    if (!handled) {
      if (!stack.empty()) {
        stack.back()->bodyLines.push_back(raw);
      }
      fence.feed(raw);
    }

    idx++;
    if (nl == std::string::npos) {
      break;
    }
    cursor = nl + 1;
  }
  return doc;
}

/* ---- section body replacement -------------------------------------------- */

namespace {

/* Appends `s` and its descendants, depth-first, to `out`. */
void collectSections(const DocSpecsSection& s,
                     std::vector<const DocSpecsSection*>& out) {
  out.push_back(&s);
  for (const auto& child : s.children) {
    collectSections(*child, out);
  }
}

/* Splits `text` on '\n' — a trailing '\n' yields a final empty element, as
 * Dart's String.split does. */
std::vector<std::string> splitLines(const std::string& text) {
  std::vector<std::string> out;
  std::size_t cursor = 0;
  for (;;) {
    std::size_t nl = text.find('\n', cursor);
    if (nl == std::string::npos) {
      out.push_back(text.substr(cursor));
      return out;
    }
    out.push_back(text.substr(cursor, nl - cursor));
    cursor = nl + 1;
  }
}

/* Reports whether `s` is empty or whitespace only (Dart's trim().isEmpty). */
bool isBlankLine(const std::string& s) { return stripTrailingWs(s).empty(); }

}  // namespace

std::vector<const DocSpecsSection*> DocSpecsDocument::allSections() const {
  std::vector<const DocSpecsSection*> out;
  for (const auto& s : sections) {
    collectSections(*s, out);
  }
  return out;
}

std::string DocSpecsDocument::replaceSectionBody(const std::string& text,
                                                 const std::string& sectionId,
                                                 const std::string& body) {
  DocSpecsDocument doc = docspecsParseDocument(text);
  std::vector<const DocSpecsSection*> matches;
  for (const DocSpecsSection* s : doc.allSections()) {
    if (s->id == sectionId) {
      matches.push_back(s);
    }
  }
  if (matches.empty()) {
    throw std::invalid_argument("sectionId \"" + sectionId +
                                "\" names no section");
  }
  if (matches.size() > 1) {
    std::string lines;
    for (std::size_t i = 0; i < matches.size(); i++) {
      if (i > 0) lines += ", ";
      lines += std::to_string(matches[i]->line);
    }
    throw std::invalid_argument("sectionId \"" + sectionId + "\" names " +
                                std::to_string(matches.size()) +
                                " sections (lines " + lines + ")");
  }

  // the body, without its leading and trailing blank lines
  std::vector<std::string> all = splitLines(body);
  std::size_t first = 0;
  std::size_t last = all.size();
  while (first < last && isBlankLine(all[first])) first++;
  while (last > first && isBlankLine(all[last - 1])) last--;
  std::vector<std::string> bodyLines(all.begin() + static_cast<long>(first),
                                     all.begin() + static_cast<long>(last));

  // the body must not change the document's structure
  SpecMarkdownFenceTracker fence;
  for (const std::string& line : bodyLines) {
    int level = 0;
    std::string rest;
    if (!fence.inFence() &&
        matchHeadingLine(stripTrailingWs(line), &level, &rest)) {
      throw std::invalid_argument(
          "body contains a heading outside a fenced block: \"" + line + "\"");
    }
    fence.feed(line);
  }
  if (fence.inFence()) {
    throw std::invalid_argument("body leaves a fenced block open");
  }

  const DocSpecsSection& section = *matches.front();
  std::vector<std::string> lines = splitLines(text);
  // the 1-based heading line is the 0-based index of the first body line
  std::size_t start = static_cast<std::size_t>(section.line);
  std::size_t end = start + section.bodyLines.size();

  std::vector<std::string> out(lines.begin(),
                               lines.begin() + static_cast<long>(start));
  out.emplace_back();
  if (!bodyLines.empty()) {
    out.insert(out.end(), bodyLines.begin(), bodyLines.end());
    out.emplace_back();
  }
  out.insert(out.end(), lines.begin() + static_cast<long>(end), lines.end());

  std::string result;
  for (std::size_t i = 0; i < out.size(); i++) {
    if (i > 0) result.push_back('\n');
    result += out[i];
  }
  return result;
}

/* ---- schema -------------------------------------------------------------- */

bool DocSpecsPatternCheck::matches(const std::string& value) const {
  // `new RegExp(pattern).test(value)`, as Dart and TypeScript test it: an
  // ECMAScript expression searched anywhere in the value (groups, `|`,
  // `{n,m}` included). A pattern std::regex refuses falls back to the
  // subset matcher.
  try {
    return std::regex_search(value, std::regex(pattern, std::regex::ECMAScript));
  } catch (const std::regex_error&) {
    Rx rx = rxCompile(pattern);
    return rxSearch(rx, value);
  }
}

const DocSpecsSubsectionRule* DocSpecsSectionType::subsection(
    const std::string& name) const {
  for (const auto& r : subsectionTypes) {
    if (r.name == name) {
      return &r;
    }
  }
  return nullptr;
}

const DocSpecsSectionType* DocSpecsSchema::sectionTypeByName(
    const std::string& name) const {
  for (const auto& t : sectionTypes) {
    if (t.name == name) {
      return &t;
    }
  }
  return nullptr;
}

const DocSpecsFormType* DocSpecsSchema::formType(const std::string& name) const {
  for (const auto& f : formTypes) {
    if (f.name == name) {
      return &f;
    }
  }
  return nullptr;
}

const DocSpecsDocumentSection* DocSpecsSchema::documentSection(
    const std::string& key) const {
  for (const auto& d : documentSections) {
    if (d.key == key) {
      return &d;
    }
  }
  return nullptr;
}

std::string DocSpecsSchema::rootSectionId() const {
  if (titleFormat.empty()) {
    return "";
  }
  /* docspecsRootIDRE = `<!--\[([^\]]+)\]-->` (search). */
  std::size_t p = 0;
  while ((p = titleFormat.find("<!--[", p)) != std::string::npos) {
    std::size_t inner = p + 5;
    std::size_t close = titleFormat.find(']', inner);
    if (close != std::string::npos && close != inner &&
        titleFormat.compare(close, 4, "]-->") == 0) {
      return titleFormat.substr(inner, close - inner);
    }
    p += 5;
  }
  return "";
}

const DocSpecsSectionType* DocSpecsSchema::resolveSectionType(
    const std::string& id) const {
  std::string transformed = docspecsIdTransform(id);
  for (const auto& t : sectionTypes) {
    const std::string& prefix = t.prefix;
    if (transformed.compare(0, prefix.size(), prefix) == 0) {
      return &t;
    }
  }
  return nullptr;
}

std::optional<DocSpecsSchema> docspecsSchemaFromYamlText(const std::string& text,
                                                         std::string* err) {
  YamlPtr data = yamlParse(text);
  bool isMap = data != nullptr && data->type == YamlType::Map;
  /* mirror the Go guard: a non-map root, or an empty parse of a non-blank text
   * that carries no `:` at all, is "not a YAML map". */
  std::string trimmed = trimSpace(text);
  bool hasColon = text.find(':') != std::string::npos;
  bool emptyMap = isMap && data->map.empty();
  if (!isMap || (emptyMap && !trimmed.empty() && !hasColon)) {
    if (err != nullptr) {
      *err = "docspecs schema must be a YAML map";
    }
    return std::nullopt;
  }

  DocSpecsSchema schema;
  schema.titleFormat = "";

  for (const auto& kv : data->map) {
    const std::string& k = kv.first;
    YamlRef v = kv.second;
    if (k == "title-format") {
      schema.titleFormat = yamlScalarString(v);
    } else if (k == "section-types") {
      loadSectionTypes(schema, v);
    } else if (k == "form-types") {
      loadFormTypes(schema, v);
    } else if (k == "document") {
      if (!loadDocument(schema, v, err)) {
        return std::nullopt;
      }
    } else if (k == "schema" || k == "version" || k == "name" ||
               k == "description") {
      // informational keys — accepted, unused
    } else {
      schema.warnings.push_back("unsupported top-level schema key \"" + k +
                                "\" ignored");
    }
  }
  return schema;
}

/* ---- validator ----------------------------------------------------------- */

namespace {

/* A section as the validator walks it: a parsed DocSpecsSection, or a
 * virtual one rebuilt from a list body or a section table (the DocSpecs
 * specification's *List Bodies*). The body is a copy, so blanking a table or
 * div never touches the parsed document. */
struct VNode {
  std::string id;
  int line = 0;  // the heading's line, or the row's / div's of a virtual one
  std::vector<std::string> body;  // own lines; a list body or table read is blank
  const DocSpecsSectionType* type = nullptr;  // a virtual list item's type
  std::vector<std::unique_ptr<VNode>> children;
  // Form values given by a table row or a list body: label, value, line.
  std::vector<std::tuple<std::string, std::string, int>> values;

  int bodyStartLine() const { return line + 1; }

  /* The walk's view of a parsed section and its subtree. */
  static std::unique_ptr<VNode> of(const DocSpecsSection& s) {
    auto n = std::make_unique<VNode>();
    n->id = s.id;
    n->line = s.line;
    n->body = s.bodyLines;
    for (const auto& c : s.children) n->children.push_back(of(*c));
    return n;
  }

  /* A virtual section at `line`, with no body. */
  static std::unique_ptr<VNode> virtualAt(const std::string& id, int line,
                                          const DocSpecsSectionType* type) {
    auto n = std::make_unique<VNode>();
    n->id = id;
    n->line = line;
    n->type = type;
    return n;
  }

  /* The trimmed body text after the virtual body lines of `values` — the
   * text the same section has in the fields layout. */
  std::string text() const {
    std::vector<std::string> lines;
    for (const auto& v : values) {
      const std::string& label = std::get<0>(v);
      lines.push_back(label.empty() ? std::get<1>(v)
                                    : label + ": " + std::get<1>(v));
    }
    lines.insert(lines.end(), body.begin(), body.end());
    std::size_t a = 0, b = lines.size();
    while (a < b && trimSpace(lines[a]).empty()) a++;
    while (b > a && trimSpace(lines[b - 1]).empty()) b--;
    std::string out;
    for (std::size_t i = a; i < b; i++) {
      if (i > a) out += '\n';
      out += lines[i];
    }
    return out;
  }
};

/* Whether `anchor` is the own anchor of a section with `id`: `id` itself, or a
 * qualified form `<A>/.../<id>` whose segments are all non-empty (Section
 * Anchors). */
bool isOwnAnchor(const std::string& anchor, const std::string& id) {
  if (anchor == id) return true;
  const std::string tail = "/" + id;
  if (anchor.size() < tail.size() ||
      anchor.compare(anchor.size() - tail.size(), tail.size(), tail) != 0) {
    return false;
  }
  std::size_t from = 0;
  for (;;) {
    std::size_t slash = anchor.find('/', from);
    std::size_t to = slash == std::string::npos ? anchor.size() : slash;
    if (to == from) return false;
    if (slash == std::string::npos) return true;
    from = slash + 1;
  }
}

/* `<a id="X"></a>` at `at` followed by whitespace: X and the end. */
bool matchAnchorAt(const std::string& s, std::size_t at, std::string* id,
                   std::size_t* end) {
  if (s.compare(at, 7, "<a id=\"") != 0) return false;
  std::size_t q = s.find('"', at + 7);
  if (q == std::string::npos || s.compare(q + 1, 5, "></a>") != 0) return false;
  std::size_t e = q + 6;
  while (e < s.size() && isAsciiWs(s[e])) e++;
  *id = s.substr(at + 7, q - at - 7);
  *end = e;
  return true;
}

/* `s.split(/\s*\/\s*\/)`: the parts of a `<LIST> / <ITEM>` cell. */
std::vector<std::string> cellParts(const std::string& s) {
  std::vector<std::string> parts;
  std::size_t from = 0;
  for (;;) {
    std::size_t slash = s.find('/', from);
    std::string part =
        s.substr(from, slash == std::string::npos ? std::string::npos
                                                  : slash - from);
    if (slash != std::string::npos) {
      // `\s*` before the slash and after it belong to the separator.
      while (!part.empty() && isAsciiWs(part.back())) part.pop_back();
    }
    if (from > 0) {
      std::size_t k = 0;
      while (k < part.size() && isAsciiWs(part[k])) k++;
      part = part.substr(k);
    }
    parts.push_back(part);
    if (slash == std::string::npos) break;
    from = slash + 1;
  }
  return parts;
}

/* A value cell's value: `\|` unescaped, a cell of links read as their texts. */
std::string cellValue(const std::string& cell) {
  std::string text;
  for (std::size_t i = 0; i < cell.size(); i++) {
    if (cell[i] == '\\' && i + 1 < cell.size() && cell[i + 1] == '|') {
      text += '|';
      i++;
    } else {
      text += cell[i];
    }
  }
  std::vector<std::string> texts;
  if (markdownLinkCell(text, &texts)) {
    std::string out;
    for (std::size_t i = 0; i < texts.size(); i++) {
      if (i > 0) out += ", ";
      out += texts[i];
    }
    return out;
  }
  return text;
}

/* An `Id` or `Section` cell with its own anchors removed (Section Anchors):
 * in a `<LIST> / <ITEM>` cell each part's anchor, and one before the whole
 * cell naming its item; any other anchor stays. A link is read as its text
 * (SOM §11.5). */
std::string cellId(const std::string& raw) {
  // `\[([^\]]+)\]\([^)\s]*\)` replaced by its text, everywhere.
  std::string cell;
  for (std::size_t i = 0; i < raw.size();) {
    if (raw[i] == '[') {
      std::size_t close = raw.find(']', i + 1);
      if (close != std::string::npos && close > i + 1 &&
          close + 1 < raw.size() && raw[close + 1] == '(') {
        std::size_t k = close + 2;
        while (k < raw.size() && raw[k] != ')' && !isAsciiWs(raw[k])) k++;
        if (k < raw.size() && raw[k] == ')') {
          cell += raw.substr(i + 1, close - i - 1);
          i = k + 1;
          continue;
        }
      }
    }
    cell += raw[i];
    i++;
  }
  std::string out;
  std::size_t pos = 0;
  for (std::size_t at = cell.find("<a id=\""); at != std::string::npos;
       at = cell.find("<a id=\"", at + 1)) {
    if (at < pos) continue;
    std::string id;
    std::size_t end = 0;
    if (!matchAnchorAt(cell, at, &id, &end)) continue;
    out += cell.substr(pos, at - pos);
    std::vector<std::string> rest = cellParts(cell.substr(end));
    bool own = isOwnAnchor(id, trimSpace(rest.front())) ||
               (at == 0 && isOwnAnchor(id, trimSpace(rest.back())));
    if (!own) out += cell.substr(at, end - at);
    pos = end;
  }
  return out + cell.substr(pos);
}

/* Skips the generated lead of a section's lines: a paragraph that is one
 * `linked` span (SOM §11.11), then a `derived` block (SOM §11.12), with the
 * blank lines around them (DocSpecs RN-5, *Not text*). Answers the index of
 * the first line after it. */
std::size_t generatedLead(const std::vector<std::string>& lines) {
  auto skipBlank = [&lines](std::size_t i) {
    while (i < lines.size() && trimSpace(lines[i]).empty()) i++;
    return i;
  };
  std::size_t i = skipBlank(0);
  std::size_t end = i;
  while (end < lines.size() && !trimSpace(lines[end]).empty()) end++;
  std::string para;
  for (std::size_t k = i; k < end; k++) {
    if (k > i) para += ' ';
    para += lines[k];
  }
  para = trimSpace(para);
  // `^\[.*\]\{\.linked\}$`
  static const std::string kLinked = "]{.linked}";
  if (end > i && para.size() > kLinked.size() && para[0] == '[' &&
      para.compare(para.size() - kLinked.size(), kLinked.size(), kLinked) == 0) {
    i = skipBlank(end);
  }
  if (i < lines.size()) {
    // `^ {0,3}(:{3,})[ \t]*\{\.derived(?=[\s}])`
    const std::string& l = lines[i];
    std::size_t p = 0;
    while (p < 3 && p < l.size() && l[p] == ' ') p++;
    std::size_t colons = p;
    while (p < l.size() && l[p] == ':') p++;
    std::size_t run = p - colons;
    while (p < l.size() && (l[p] == ' ' || l[p] == '\t')) p++;
    if (run >= 3 && l.compare(p, 9, "{.derived") == 0 && p + 9 < l.size() &&
        (isAsciiWs(l[p + 9]) || l[p + 9] == '}')) {
      std::size_t k = i + 1;
      for (; k < lines.size(); k++) {
        // `^ {0,3}:{run,}[ \t]*$`
        const std::string& c = lines[k];
        std::size_t q = 0;
        while (q < 3 && q < c.size() && c[q] == ' ') q++;
        std::size_t cs = q;
        while (q < c.size() && c[q] == ':') q++;
        if (q - cs < run) continue;
        while (q < c.size() && (c[q] == ' ' || c[q] == '\t')) q++;
        if (q == c.size()) break;
      }
      if (k < lines.size()) i = skipBlank(k + 1);
    }
  }
  return i;
}

/* `text` without its generated lead: what the text rules read. */
std::string withoutGeneratedText(const std::string& text) {
  std::vector<std::string> lines;
  std::size_t from = 0;
  for (;;) {
    std::size_t nl = text.find('\n', from);
    lines.push_back(text.substr(from, nl == std::string::npos
                                          ? std::string::npos
                                          : nl - from));
    if (nl == std::string::npos) break;
    from = nl + 1;
  }
  std::string out;
  for (std::size_t i = generatedLead(lines); i < lines.size(); i++) {
    if (!out.empty() || i > generatedLead(lines)) out += '\n';
    out += lines[i];
  }
  return trimSpace(out);
}

/* One table read off body lines. */
struct VTable {
  std::vector<std::string> header;
  std::vector<std::pair<std::size_t, std::vector<std::string>>> rows;
  std::size_t end = 0;
};

/* The walk over a document: virtual sections, tables, list bodies. */
class Walk {
 public:
  Walk(const DocSpecsSchema& schema, std::vector<DocSpecsViolation>& v)
      : schema_(schema), v_(v) {}

  void documentSections(VNode& root);

 private:
  const DocSpecsSchema& schema_;
  std::vector<DocSpecsViolation>& v_;

  const DocSpecsSectionType* resolveChild(const VNode& section);
  void validateSection(VNode& section, const DocSpecsSectionType& t);
  void validateText(const VNode& section, const DocSpecsSectionType& t);
  void validateFormat(const VNode& section, const DocSpecsSectionType& t);
  void validateForm(const VNode& section, const DocSpecsFormType& form);
  int checkOrder(const VNode& child, const std::string& typeName,
                 const std::vector<std::optional<std::string>>& order,
                 int lastIndex);
  VTable readTable(const std::vector<std::string>& lines, std::size_t start,
                   const std::function<int(std::size_t)>& lineOf,
                   const std::string& sectionId);
  void expandSectionTables(
      VNode& node, const std::function<bool(const DocSpecsSectionType&)>& ok);
  VNode* sectionTableTarget(
      VNode& node, const std::string& cell,
      const std::function<bool(const DocSpecsSectionType&)>& allowed, int line);
  void expandListBody(VNode& node, const DocSpecsSectionType& type);
  bool itemForm(const DocSpecsSectionType& itemType, bool oneField,
                const DocSpecsFormType** form,
                const DocSpecsSectionType** childType) const;
  VNode* addItem(VNode& list, const DocSpecsSectionType& itemType,
                 const DocSpecsSectionType* childType, const std::string& id,
                 int line);
  void refsItems(VNode& node, const DocSpecsSectionType& itemType,
                 const std::vector<std::string>& inner, int at);
  void recordItems(VNode& node, const DocSpecsSectionType& itemType,
                   const std::vector<std::string>& inner, int at);
};

/* Resolves a child's type; a virtual list item carries the schema's. On no
 * match pushes unknownSection. */
const DocSpecsSectionType* Walk::resolveChild(const VNode& section) {
  if (section.type != nullptr) {
    return section.type;
  }
  if (section.id.empty()) {
    return nullptr;  // already reported malformedHeading by the parse
  }
  const DocSpecsSectionType* t = schema_.resolveSectionType(section.id);
  if (t == nullptr) {
    dvPush(v_, kDocSpecsRuleUnknownSection, section.line,
           "section id \"" + section.id +
               "\" resolves to no section-type of the schema",
           section.id, "");
  }
  return t;
}

void Walk::validateText(const VNode& section, const DocSpecsSectionType& t) {
  if (!t.format.empty() && schema_.formType(t.format) != nullptr) {
    return;  // form sections carry fields, not body text
  }
  // A list body or section table already read is blanked in the body, so a
  // container written with one counts as empty (`max-text-length: 0`); the
  // rendition's marker and generated block are no text either.
  std::string text = withoutGeneratedText(section.text());
  if (t.textRequired && text.empty()) {
    dvPush(v_, kDocSpecsRuleTextRequired, section.line,
           "section requires body text but has none", section.id, "");
    return;
  }
  if (text.empty()) return;
  std::size_t length = runeCount(text);
  bool hasMin = t.hasMinTextLength;
  bool hasMax = t.hasMaxTextLength;
  if ((hasMin && length < static_cast<std::size_t>(t.minTextLength)) ||
      (hasMax && length > static_cast<std::size_t>(t.maxTextLength))) {
    std::string minStr = hasMin ? itoa(t.minTextLength) : "0";
    std::string maxStr = hasMax ? itoa(t.maxTextLength) : "\xe2\x88\x9e";
    dvPush(v_, kDocSpecsRuleTextLengthOut, section.line,
           "body text length " + itoa(static_cast<long long>(length)) +
               " is outside [" + minStr + ", " + maxStr + "]",
           section.id, "");
  }
}

/* Parses the body in the plain-text form format (`FieldName: value`,
 * case-insensitive labels, continuation lines) and its form tables, takes the
 * values a section table or list body gave the section, and checks required
 * fields and pattern checks. A field given twice keeps its first occurrence
 * and reports the second (malformedBlock): a `Field:` label counts as given
 * even with an empty value, a row only with a value. A row naming no field is
 * unknownField. */
void Walk::validateForm(const VNode& section, const DocSpecsFormType& form) {
  struct Occ {
    std::string label;
    std::string value;
    int line;
    bool fromLabel;
  };
  auto fieldOf = [&form](const std::string& label) -> const DocSpecsFormField* {
    const std::string lower = lowerAscii(label);
    for (const auto& f : form.fields) {
      if (lowerAscii(f.name) == lower) return &f;
    }
    return nullptr;
  };
  std::vector<Occ> occurrences;
  SpecMarkdownFenceTracker fence;
  const std::vector<std::string>& body = section.body;
  const DocSpecsFormField* current = nullptr;
  int currentLine = 0;
  std::string currentText;
  auto flush = [&]() {
    if (current == nullptr) return;
    occurrences.push_back({current->name, trimSpace(currentText), currentLine,
                           true});
    current = nullptr;
    currentText.clear();
  };
  for (std::size_t i = 0; i < body.size(); i++) {
    const std::string& raw = body[i];
    if (!fence.inFence()) {
      bool isSection = false;
      if (markdownLayoutTableHeader(raw, &isSection) && !isSection) {
        // A form table ends the open field; its rows are fields.
        flush();
        VTable table = readTable(
            body, i,
            [&section](std::size_t k) {
              return section.bodyStartLine() + static_cast<int>(k);
            },
            section.id);
        for (const auto& row : table.rows) {
          occurrences.push_back({row.second[0], cellValue(row.second[1]),
                                 section.bodyStartLine() +
                                     static_cast<int>(row.first),
                                 false});
        }
        i = table.end - 1;
        continue;
      }
      std::string label;
      std::string value;
      if (matchFieldLabel(raw, &label, &value)) {
        const DocSpecsFormField* f = fieldOf(label);
        if (f != nullptr) {
          flush();
          current = f;
          currentLine = section.bodyStartLine() + static_cast<int>(i);
          currentText = value;
          fence.feed(raw);
          continue;
        }
      }
    }
    if (current != nullptr) {
      currentText += '\n';
      currentText += raw;
    }
    fence.feed(raw);
  }
  flush();
  for (const auto& v : section.values) {
    occurrences.push_back({std::get<0>(v), std::get<1>(v), std::get<2>(v),
                           false});
  }
  // Source order decides which occurrence is the first; values from a
  // parent's section table stand above the section's own body.
  std::stable_sort(occurrences.begin(), occurrences.end(),
                   [](const Occ& a, const Occ& b) { return a.line < b.line; });

  std::map<std::string, std::string> values;
  std::map<std::string, int> fieldLines;
  std::set<std::string> given;
  for (const Occ& o : occurrences) {
    const DocSpecsFormField* field = fieldOf(o.label);
    if (field == nullptr) {
      dvPush(v_, kDocSpecsRuleUnknownField, o.line,
             "row \"" + o.label + "\" names no field of \"" + form.name + "\"",
             section.id, "");
      continue;
    }
    if (!o.fromLabel && o.value.empty()) continue;
    if (given.count(field->name) != 0) {
      dvPush(v_, kDocSpecsRuleMalformedBlock, o.line,
             "field \"" + field->name + "\" given twice", section.id, "");
      continue;
    }
    given.insert(field->name);
    fieldLines[field->name] = o.line;
    if (!o.value.empty()) values[field->name] = o.value;
  }
  for (const auto& field : form.fields) {
    auto it = values.find(field.name);
    const std::string value = it != values.end() ? it->second : std::string();
    if (field.required && value.empty()) {
      dvPush(v_, kDocSpecsRuleMissingRequiredField, section.line,
             "required form field \"" + field.name + "\" of \"" + form.name +
                 "\" is missing",
             section.id, "");
      continue;
    }
    if (field.patternCheck.has_value() && !value.empty() &&
        !field.patternCheck->matches(value)) {
      auto ln = fieldLines.find(field.name);
      int line = ln != fieldLines.end() ? ln->second : section.line;
      std::string message =
          !field.patternCheck->errorMessage.empty()
              ? field.patternCheck->errorMessage
              : "form field \"" + field.name + "\" does not match pattern \"" +
                    field.patternCheck->pattern + "\"";
      dvPush(v_, kDocSpecsRuleFieldPatternMismatch, line, message, section.id,
             "");
    }
  }
}

void Walk::validateFormat(const VNode& section, const DocSpecsSectionType& t) {
  // Values a section table or list body gave a section the schema declares no
  // form for are virtual body lines, counted in its text (VNode::text).
  const std::string& format = t.format;
  if (format.empty()) {
    return;
  }
  const DocSpecsFormType* form = schema_.formType(format);
  if (form != nullptr) {
    validateForm(section, *form);
    return;
  }
  SpecMarkdownFenceTracker fence;
  bool sawFence = false;
  for (const std::string& l : section.body) {
    fence.feed(l);
    if (fence.inFence()) {
      sawFence = true;
    }
  }
  if (!sawFence) {
    dvPush(v_, kDocSpecsRuleFormatMismatch, section.line,
           "section format \"" + format +
               "\" demands a fenced code block, but the body contains none",
           section.id, "");
  }
}

/* A small name→count association for occurrence tallies. */
struct CountMap {
  std::vector<std::string> names;
  std::vector<int> counts;

  void inc(const std::string& name) {
    for (std::size_t i = 0; i < names.size(); i++) {
      if (names[i] == name) {
        counts[i]++;
        return;
      }
    }
    names.push_back(name);
    counts.push_back(1);
  }
  int get(const std::string& name) const {
    for (std::size_t i = 0; i < names.size(); i++) {
      if (names[i] == name) {
        return counts[i];
      }
    }
    return 0;
  }
};

void Walk::validateSection(VNode& section, const DocSpecsSectionType& t) {
  if (t.patternCheck.has_value() && !section.id.empty() &&
      !t.patternCheck->matches(section.id)) {
    std::string message;
    if (!t.patternCheck->errorMessage.empty()) {
      message = t.patternCheck->errorMessage;
    } else {
      message = "section id \"" + section.id +
                "\" does not match pattern \"" + t.patternCheck->pattern + "\"";
    }
    dvPush(v_, kDocSpecsRuleIdPatternMismatch, section.line, message,
           section.id, "");
  }
  // List bodies and section tables become virtual sections before anything is
  // counted or checked (DocSpecs specification, List Bodies).
  expandSectionTables(section, [&t](const DocSpecsSectionType& c) {
    return t.subsection(c.name) != nullptr;
  });
  expandListBody(section, t);
  validateText(section, t);
  validateFormat(section, t);

  CountMap counts;
  for (const auto& childPtr : section.children) {
    VNode& child = *childPtr;
    const DocSpecsSectionType* childType = resolveChild(child);
    if (childType == nullptr) {
      continue;
    }
    if (t.subsection(childType->name) == nullptr) {
      dvPush(v_, kDocSpecsRuleUnknownSection, child.line,
             "section-type \"" + childType->name +
                 "\" is not an allowed subsection of \"" + t.name + "\"",
             child.id, "");
      continue;
    }
    counts.inc(childType->name);
    validateSection(child, *childType);
  }
  // The offending section is the CONTAINER, not the absent child: a cardinality
  // breach has no child occurrence to point at, and `subKey` is a schema type
  // name, not a section id. Dart is the golden reference here.
  for (const auto& rule : t.subsectionTypes) {
    const std::string& subKey = rule.name;
    int count = counts.get(subKey);
    if (count < rule.minCount) {
      if (count == 0) {
        dvPush(v_, kDocSpecsRuleMissingRequiredSection, section.line,
               "required subsection \"" + subKey + "\" of \"" + t.name +
                   "\" is missing",
               section.id, "");
      } else {
        dvPush(v_, kDocSpecsRuleTooFewItems, section.line,
               "subsection \"" + subKey + "\" occurs " + itoa(count) +
                   " time(s), minimum is " + itoa(rule.minCount),
               section.id, "");
      }
    }
    if (rule.hasMax && count > rule.maxCount) {
      dvPush(v_, kDocSpecsRuleTooManyItems, section.line,
             "subsection \"" + subKey + "\" occurs " + itoa(count) +
                 " time(s), maximum is " + itoa(rule.maxCount),
             section.id, "");
    }
  }
}

/* The order check of one root child: its slot is the first of its type at or
 * after the last slot taken, else the first of its type anywhere; a slot
 * before the last one taken is sectionOutOfOrder. Answers the last slot taken
 * afterwards. `order` holds the slot types in slot order, std::nullopt for a
 * `position: any` slot. */
int Walk::checkOrder(const VNode& child, const std::string& typeName,
                     const std::vector<std::optional<std::string>>& order,
                     int lastIndex) {
  int n = static_cast<int>(order.size());
  int index = -1;
  for (int i = lastIndex > 0 ? lastIndex : 0; i < n; i++) {
    if (order[i] == typeName) {
      index = i;
      break;
    }
  }
  if (index == -1) {
    for (int i = 0; i < n; i++) {
      if (order[i] == typeName) {
        index = i;
        break;
      }
    }
  }
  if (index == -1) {
    return lastIndex;
  }
  if (index < lastIndex) {
    dvPush(v_, kDocSpecsRuleSectionOutOfOrder, child.line,
           "section \"" + child.id + "\" (type \"" + typeName +
               "\") stands out of the order of the document sections",
           child.id, "");
    return lastIndex;
  }
  return index;
}

/* ---- tables and list bodies (DocSpecs specification, List Bodies) -------- */

/* Reads the table whose header is `lines[start]`. A missing or mismatched
 * delimiter row is a malformedBlock at the header and the table yields no
 * rows; a row of another cell count is a malformedBlock at that row and is
 * left out. */
VTable Walk::readTable(const std::vector<std::string>& lines, std::size_t start,
                       const std::function<int(std::size_t)>& lineOf,
                       const std::string& sectionId) {
  VTable t;
  t.end = start + 1;
  while (t.end < lines.size() && markdownTableLine(lines[t.end])) t.end++;
  t.header = markdownTableRowCells(lines[start]);
  bool delimiterOk = false;
  std::vector<std::string> delimiter;
  if (start + 1 < t.end) {
    delimiter = markdownTableRowCells(lines[start + 1]);
    delimiterOk = true;
    for (const auto& c : delimiter) {
      if (!markdownDelimiterCell(c)) {
        delimiterOk = false;
        break;
      }
    }
  }
  if (!delimiterOk || delimiter.size() != t.header.size()) {
    dvPush(v_, kDocSpecsRuleMalformedBlock, lineOf(start),
           delimiterOk ? "table whose delimiter row does not match its header"
                       : "table without its delimiter row",
           sectionId, "");
    return t;
  }
  for (std::size_t i = start + 2; i < t.end; i++) {
    std::vector<std::string> cells = markdownTableRowCells(lines[i]);
    if (cells.size() != t.header.size()) {
      dvPush(v_, kDocSpecsRuleMalformedBlock, lineOf(i),
             "table row with " + itoa(static_cast<long long>(cells.size())) +
                 " cells, the header has " +
                 itoa(static_cast<long long>(t.header.size())),
             sectionId, "");
      continue;
    }
    t.rows.emplace_back(i, std::move(cells));
  }
  return t;
}

/* Reads every section table of `node`'s body: each row's `Section` cell names
 * a child — by its id, a list item as `<LIST> / <ITEM>`, an empty cell the
 * row above's — and its `TomSpecField` / `Value` cells become that child's
 * form values. A child without a heading becomes a virtual section; one whose
 * id resolves to no type allowed under `node` is unknownSection at the row,
 * and its rows are skipped. The table's lines are blanked. */
void Walk::expandSectionTables(
    VNode& node, const std::function<bool(const DocSpecsSectionType&)>& ok) {
  std::vector<std::string>& body = node.body;
  SpecMarkdownFenceTracker fence;
  auto lineOf = [&node](std::size_t k) {
    return node.bodyStartLine() + static_cast<int>(k);
  };
  for (std::size_t i = 0; i < body.size(); i++) {
    const std::string line = body[i];
    bool isSection = false;
    if (fence.inFence() || !markdownLayoutTableHeader(line, &isSection) ||
        !isSection) {
      fence.feed(line);
      continue;
    }
    VTable table = readTable(body, i, lineOf, node.id);
    VNode* target = nullptr;
    bool skip = false;
    for (const auto& row : table.rows) {
      const std::vector<std::string>& cells = row.second;
      const int at = lineOf(row.first);
      const std::string cell = cellId(cells[0]);
      if (!cell.empty()) {
        target = sectionTableTarget(node, cell, ok, at);
        skip = target == nullptr;
        if (target == nullptr) {
          dvPush(v_, kDocSpecsRuleUnknownSection, at,
                 "section-table row names no child section of \"" + node.id +
                     "\"",
                 cell, "");
          continue;
        }
      } else if (skip) {
        continue;  // the rejected child's further rows
      } else if (target == nullptr) {
        dvPush(v_, kDocSpecsRuleUnknownSection, at,
               "section-table row names no section", node.id, "");
        continue;
      }
      target->values.emplace_back(cells[1], cellValue(cells[2]), at);
    }
    for (std::size_t k = i; k < table.end; k++) body[k].clear();
    i = table.end - 1;
  }
}

/* The child a section-table `Section` cell names under `node`: a child by its
 * id, or `<LIST> / <ITEM>` — an item of a child list. A child or item without
 * a heading is created as a virtual section when its id resolves to a type
 * allowed where it stands; nullptr otherwise. */
VNode* Walk::sectionTableTarget(
    VNode& node, const std::string& cell,
    const std::function<bool(const DocSpecsSectionType&)>& allowed, int line) {
  std::vector<std::string> parts = cellParts(cell);
  if (parts.size() > 2) return nullptr;
  auto child = [this, line](
                   VNode& parent, const std::string& id,
                   const std::function<bool(const DocSpecsSectionType&)>& ok)
      -> VNode* {
    for (auto& c : parent.children) {
      if (c->id == id) return c.get();
    }
    const DocSpecsSectionType* t = schema_.resolveSectionType(id);
    if (t == nullptr || !ok(*t)) return nullptr;
    parent.children.push_back(VNode::virtualAt(id, line, nullptr));
    return parent.children.back().get();
  };
  VNode* first = child(node, parts[0], allowed);
  if (parts.size() == 1 || first == nullptr) return first;
  const DocSpecsSectionType* listType =
      first->type != nullptr ? first->type
                             : schema_.resolveSectionType(parts[0]);
  if (listType == nullptr) return nullptr;
  return child(*first, parts[1], [listType](const DocSpecsSectionType& t) {
    return listType->subsection(t.name) != nullptr;
  });
}

/* A list container's body: one `refs` div (a reference line) or one `records`
 * div (a record table) stands for its items when the container has no item
 * heading; the items become virtual sections of the container's one
 * subsection type, and the div's lines are blanked. */
void Walk::expandListBody(VNode& node, const DocSpecsSectionType& type) {
  std::vector<std::string>& body = node.body;
  SpecMarkdownFenceTracker fence;
  for (std::size_t i = 0; i < body.size(); i++) {
    const std::string line = body[i];
    std::string kind;
    if (fence.inFence() || !markdownListDivOpen(line, &kind)) {
      fence.feed(line);
      continue;
    }
    const int at = node.bodyStartLine() + static_cast<int>(i);
    auto reject = [this, at, &node](const std::string& message) {
      dvPush(v_, kDocSpecsRuleMalformedBlock, at, message, node.id, "");
    };
    std::size_t close = std::string::npos;
    for (std::size_t k = i + 1; k < body.size(); k++) {
      if (markdownDivCloseLine(body[k])) {
        close = k;
        break;
      }
    }
    if (close == std::string::npos) {
      reject("unclosed " + kind + " fence");  // its lines stay text
      return;
    }
    const std::size_t lead = generatedLead(body);
    bool besideText = false;
    for (std::size_t k = 0; k < body.size(); k++) {
      if (k >= lead && (k < i || k > close) && !trimSpace(body[k]).empty()) {
        besideText = true;
      }
    }
    const bool hasItems = !node.children.empty();
    std::vector<std::string> inner(body.begin() + i + 1, body.begin() + close);
    for (std::size_t k = i; k <= close; k++) body[k].clear();
    if (besideText || hasItems) {
      reject("a " + kind + " div beside " +
             (hasItems ? "item headings" : "other text") +
             " in a list container");
      return;
    }
    const DocSpecsSectionType* itemType =
        type.subsectionTypes.size() == 1
            ? schema_.sectionTypeByName(type.subsectionTypes[0].name)
            : nullptr;
    if (itemType == nullptr) {
      reject("a " + kind + " div in a section that is not a list container");
      return;
    }
    if (kind == "refs") {
      refsItems(node, *itemType, inner, at);
    } else {
      recordItems(node, *itemType, inner, at);
    }
    return;
  }
}

/* The form a `refs` item of `itemType` holds its reference in: the type's own
 * form, else the form of its one subsection type that has one (the item's
 * virtual child then carries the value). With `oneField`, only forms of
 * exactly one field count. */
bool Walk::itemForm(const DocSpecsSectionType& itemType, bool oneField,
                    const DocSpecsFormType** form,
                    const DocSpecsSectionType** childType) const {
  auto formOf = [this](const DocSpecsSectionType* t) -> const DocSpecsFormType* {
    return t != nullptr && !t->format.empty() ? schema_.formType(t->format)
                                              : nullptr;
  };
  auto fits = [oneField](const DocSpecsFormType* f) {
    return f != nullptr && (!oneField || f->fields.size() == 1);
  };
  const DocSpecsFormType* own = formOf(&itemType);
  if (fits(own)) {
    *form = own;
    *childType = nullptr;
    return true;
  }
  int found = 0;
  for (const auto& rule : itemType.subsectionTypes) {
    const DocSpecsSectionType* sub = schema_.sectionTypeByName(rule.name);
    const DocSpecsFormType* f = formOf(sub);
    if (fits(f)) {
      found++;
      *form = f;
      *childType = sub;
    }
  }
  return found == 1;
}

/* A virtual item of `itemType` with id `id` at `line`, added to `list`;
 * returns the section its form values go to — the item itself, or its virtual
 * child of `childType` (id: the child type's name upper-cased). */
VNode* Walk::addItem(VNode& list, const DocSpecsSectionType& itemType,
                     const DocSpecsSectionType* childType,
                     const std::string& id, int line) {
  list.children.push_back(VNode::virtualAt(id, line, &itemType));
  VNode* item = list.children.back().get();
  if (childType == nullptr) return item;
  item->children.push_back(
      VNode::virtualAt(upperAscii(childType->name), line, childType));
  return item->children.back().get();
}

/* A `refs` div: its text split on commas and whitespace into ids, a link
 * counting as its link text; item <n> gets the positional id (the container's
 * id with `-LST` replaced by `-<n>`, else `<id>-<n>`) and the virtual body
 * line `<Label>: <id>`. */
void Walk::refsItems(VNode& node, const DocSpecsSectionType& itemType,
                     const std::vector<std::string>& inner, int at) {
  // Without a one-field form in the schema the reference is the item's
  // virtual body line; nothing in the schema checks it further.
  const DocSpecsFormType* form = nullptr;
  const DocSpecsSectionType* childType = nullptr;
  const bool target = itemForm(itemType, true, &form, &childType);
  std::vector<std::string> ids;
  std::string joined;
  for (std::size_t k = 0; k < inner.size(); k++) {
    if (k > 0) joined += ' ';
    joined += inner[k];
  }
  std::string b;
  auto take = [&]() {
    if (b.empty()) return;
    std::string text;
    ids.push_back(markdownFirstLinkText(b, &text) ? text : b);
    b.clear();
  };
  for (char ch : joined) {
    if (ch == ',' || isAsciiWs(ch)) {
      take();
    } else {
      b += ch;
    }
  }
  take();
  const std::string& container = node.id;
  const std::string stem =
      container.size() >= 4 &&
              container.compare(container.size() - 4, 4, "-LST") == 0
          ? container.substr(0, container.size() - 4)
          : container;
  for (std::size_t n = 1; n <= ids.size(); n++) {
    VNode* holder = addItem(node, itemType, target ? childType : nullptr,
                            stem + "-" + itoa(static_cast<long long>(n)), at);
    holder->values.emplace_back(target ? form->fields[0].name : std::string(),
                                ids[n - 1], at);
  }
}

/* A `records` div: one table, `Id` first, `Title` optionally second, then
 * field names of the item's form; each row one virtual item in row order. A
 * record's cells are the item's own body lines: the item type's own form
 * decides the columns, never a child's. */
void Walk::recordItems(VNode& node, const DocSpecsSectionType& itemType,
                       const std::vector<std::string>& inner, int at) {
  auto lineOf = [at](std::size_t k) { return at + 1 + static_cast<int>(k); };
  auto reject = [this, at, &node](const std::string& message) {
    dvPush(v_, kDocSpecsRuleMalformedBlock, at, message, node.id, "");
  };
  std::size_t start = 0;
  while (start < inner.size() && trimSpace(inner[start]).empty()) start++;
  if (start >= inner.size() || !markdownTableLine(inner[start])) {
    reject("a records div holding no table");
    return;
  }
  const std::vector<std::string> header = markdownTableRowCells(inner[start]);
  if (header[0] != "Id") {
    reject("a records table whose first column is not Id");
    return;
  }
  // An item type the schema gives no form of its own takes its columns as
  // virtual body lines, unchecked.
  const DocSpecsFormType* own =
      !itemType.format.empty() ? schema_.formType(itemType.format) : nullptr;
  const bool withTitle = header.size() > 1 && header[1] == "Title";
  std::vector<std::string> columns;
  for (std::size_t h = withTitle ? 2 : 1; h < header.size(); h++) {
    const std::string& label = header[h];
    std::string name;
    if (own == nullptr) {
      name = label;
    } else {
      const std::string lower = lowerAscii(label);
      for (const auto& f : own->fields) {
        if (lowerAscii(f.name) == lower) {
          name = f.name;
          break;
        }
      }
      if (name.empty()) {
        dvPush(v_, kDocSpecsRuleUnknownField, lineOf(start),
               "records column \"" + label + "\" names no field of the items",
               node.id, "");
        return;
      }
    }
    columns.push_back(name);
  }
  VTable table = readTable(inner, start, lineOf, node.id);
  for (const auto& row : table.rows) {
    const std::vector<std::string>& cells = row.second;
    VNode* holder =
        addItem(node, itemType, nullptr, cellId(cells[0]), lineOf(row.first));
    for (std::size_t c = 0; c < columns.size(); c++) {
      std::string value = cellValue(cells[(withTitle ? 2 : 1) + c]);
      if (value.empty()) continue;
      holder->values.emplace_back(columns[c], value, lineOf(row.first));
    }
  }
}

/* Root children must occupy `document: sections:` slots, in their order (a
 * `position: any` slot's type stands anywhere); required slots must be
 * present. A section table in the root's body rebuilds root children as
 * virtual sections first. */
void Walk::documentSections(VNode& root) {
  std::set<std::string> slotTypes;
  std::set<std::string> anywhere;
  std::vector<std::optional<std::string>> order;
  for (const auto& slot : schema_.documentSections) {
    slotTypes.insert(slot.sectionType);
    if (slot.anyPosition()) {
      anywhere.insert(slot.sectionType);
      order.push_back(std::nullopt);
    } else {
      order.push_back(slot.sectionType);
    }
  }
  expandSectionTables(root, [&slotTypes](const DocSpecsSectionType& t) {
    return slotTypes.count(t.name) != 0;
  });
  int lastIndex = -1;
  CountMap counts;
  for (const auto& childPtr : root.children) {
    VNode& child = *childPtr;
    const DocSpecsSectionType* t = resolveChild(child);
    if (t == nullptr) {
      continue;
    }
    if (slotTypes.count(t->name) == 0) {
      dvPush(v_, kDocSpecsRuleUnknownSection, child.line,
             "section-type \"" + t->name +
                 "\" is not a top-level document section",
             child.id, "");
      continue;
    }
    if (anywhere.count(t->name) == 0) {
      lastIndex = checkOrder(child, t->name, order, lastIndex);
    }
    counts.inc(t->name);
    validateSection(child, *t);
  }
  for (const auto& slot : schema_.documentSections) {
    if (!slot.optional && counts.get(slot.sectionType) == 0) {
      dvPush(v_, kDocSpecsRuleMissingRequiredSection, root.line,
             "required document section \"" + slot.key + "\" (type \"" +
                 slot.sectionType + "\") is missing",
             slot.key, "");
    }
  }
}

/* Every section's id path (the ids from the root down to it) is unique: a
 * section whose id repeats an earlier sibling's is a duplicateIdPath. Its
 * descendants repeat paths only through it and are not reported again.
 * Sections without an id are skipped (already malformedHeading), their
 * children walked. Depth-first, source order. */
void validateIdPaths(
    const std::vector<std::unique_ptr<DocSpecsSection>>& sections,
    std::vector<DocSpecsViolation>& v) {
  std::set<std::string> seen;
  for (const auto& sPtr : sections) {
    const DocSpecsSection& s = *sPtr;
    if (!s.id.empty()) {
      if (seen.count(s.id) != 0) {
        dvPush(v, kDocSpecsRuleDuplicateIdPath, s.line,
               "section id \"" + s.id +
                   "\" repeats a sibling's id, so its id path is not unique",
               s.id, "");
        continue;
      }
      seen.insert(s.id);
    }
    validateIdPaths(s.children, v);
  }
}

/* `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$`: the label of a `Field:` line, or "". */
std::string fieldLabelOf(const std::string& line) {
  auto letter = [](char c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
  };
  if (line.empty() || !letter(line[0])) return "";
  std::size_t i = 1;
  while (i < line.size() &&
         (letter(line[i]) || (line[i] >= '0' && line[i] <= '9') ||
          line[i] == '_')) {
    i++;
  }
  if (i >= line.size() || line[i] != ':') return "";
  // `(.*)$`: the rest holds no line terminator (\r, U+2028, U+2029).
  for (std::size_t k = i + 1; k < line.size(); k++) {
    if (line[k] == '\r') return "";
    if (static_cast<unsigned char>(line[k]) == 0xE2 && k + 2 < line.size() &&
        static_cast<unsigned char>(line[k + 1]) == 0x80 &&
        (static_cast<unsigned char>(line[k + 2]) == 0xA8 ||
         static_cast<unsigned char>(line[k + 2]) == 0xA9)) {
      return "";
    }
  }
  return line.substr(0, i);
}

/* The values of a section's own body as (index of the first line, lines): the
 * whole body, or in a TomSpecs rendition one value per form field of a
 * form-formatted section (its preamble included). */
std::vector<std::pair<std::size_t, std::vector<std::string>>> notationValues(
    const DocSpecsSchema& schema, bool tomSpecs, const DocSpecsSection& s) {
  const std::vector<std::string>& body = s.bodyLines;
  const DocSpecsSectionType* type =
      tomSpecs && !s.id.empty() ? schema.resolveSectionType(s.id) : nullptr;
  const DocSpecsFormType* form =
      type != nullptr && !type->format.empty() ? schema.formType(type->format)
                                               : nullptr;
  if (form == nullptr) return {{0, body}};
  std::set<std::string> labels;
  for (const DocSpecsFormField& f : form->fields) {
    labels.insert(lowerAscii(f.name));
  }
  std::vector<std::pair<std::size_t, std::vector<std::string>>> values;
  SpecMarkdownFenceTracker fence;
  std::size_t first = 0;
  for (std::size_t i = 0; i < body.size(); i++) {
    if (!fence.inFence() && i > first) {
      std::string label = fieldLabelOf(body[i]);
      if (!label.empty() && labels.count(lowerAscii(label)) != 0) {
        values.emplace_back(first, std::vector<std::string>(
                                       body.begin() + first, body.begin() + i));
        first = i;
      }
    }
    fence.feed(body[i]);
  }
  values.emplace_back(
      first, std::vector<std::string>(body.begin() + first, body.end()));
  return values;
}

/* The reading notation of every section's own body: one value per section,
 * and in a TomSpecs rendition one per form field of a form-formatted section
 * (its preamble included). */
void validateNotation(const DocSpecsSchema& schema, bool tomSpecs,
                      const DocSpecsDocument& doc,
                      std::vector<DocSpecsViolation>& v) {
  for (const DocSpecsSection* s : doc.allSections()) {
    for (const auto& value : notationValues(schema, tomSpecs, *s)) {
      std::string text;
      for (std::size_t i = 0; i < value.second.size(); i++) {
        if (i > 0) text += "\n";
        text += value.second[i];
      }
      NotationScan scan = scanNotation(text, tomSpecs);
      for (const NotationFinding& f : scan.findings) {
        dvPush(v, f.code,
               s->bodyStartLine() + static_cast<int>(value.first) + f.line - 1,
               f.message, s->id, "");
      }
    }
  }
}

}  // namespace

void DocSpecsValidator::validateMarkdown(
    const std::string& markdown, std::vector<DocSpecsViolation>& out) const {
  DocSpecsDocument doc = docspecsParseDocument(markdown);
  validate(doc, out);
}

void DocSpecsValidator::validate(const DocSpecsDocument& doc,
                                 std::vector<DocSpecsViolation>& out) const {
  // copy the parse-time violations first
  for (const auto& src : doc.violations) {
    out.push_back(src);
  }
  if (doc.sections.empty()) {
    dvPush(out, kDocSpecsRuleFormatMismatch, 1, "document has no root heading",
           "", "");
    return;
  }
  const DocSpecsSection& root = *doc.sections[0];
  std::string rootId = schema_->rootSectionId();
  if (!rootId.empty() && root.id != rootId) {
    dvPush(out, kDocSpecsRuleFormatMismatch, root.line,
           "root heading id \"" + root.id +
               "\" does not match the schema title-format id \"" + rootId + "\"",
           root.id, "");
  }
  for (std::size_t i = 1; i < doc.sections.size(); i++) {
    const DocSpecsSection& extra = *doc.sections[i];
    dvPush(out, kDocSpecsRuleUnknownSection, extra.line,
           "unexpected additional top-level section", extra.id, "");
  }
  std::unique_ptr<VNode> walkRoot = VNode::of(root);
  Walk(*schema_, out).documentSections(*walkRoot);
  validateNotation(*schema_, tomSpecs_, doc, out);
  validateIdPaths(doc.sections, out);
}

/* ---- bind ---------------------------------------------------------------- */

SpecMarkdownResult docspecsBindMarkdown(const SpecModel& model,
                                        const std::string& text) {
  return markdownParse(model, text);
}

}  // namespace som
