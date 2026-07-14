/* docspecs_validator — implementation. See docspecs_validator.hpp; a faithful
 * idiomatic-C++ port of the C `docspecs_validator.c` (itself a 1:1 port of the
 * Go `docspecs_validator.go`, DR7/DR29). */
#include "docspecs_validator.hpp"

#include <cstddef>
#include <string>
#include <vector>

#include "spec_document_markdown.hpp"

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

/* mdHeadlineCommentRE = `^<!--\[([^\]]+)\]-->\s*(.*)$`. Writes group 1 (id) to
 * `id` and group 2 (rest-title) to `rest`, returns true. */
bool matchHeadlineComment(const std::string& s, std::string* id,
                          std::string* rest) {
  if (s.compare(0, 5, "<!--[") != 0) {
    return false;
  }
  std::size_t p = 5;
  std::size_t close = s.find(']', p);
  if (close == std::string::npos || close == p) {
    return false;
  }
  if (s.compare(close, 4, "]-->") != 0) {
    return false;
  }
  *id = s.substr(p, close - p);
  std::size_t after = close + 4;
  while (after < s.size() && isAsciiWs(s[after])) {
    after++;
  }
  *rest = s.substr(after);
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

void loadDocument(DocSpecsSchema& s, const YamlRef& node) {
  if (node == nullptr || node->type != YamlType::Map) {
    return;
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
        }
        s.documentSections.push_back(std::move(ds));
      }
    } else if (k != "name" && k != "description") {
      s.warnings.push_back("unsupported document key \"" + k + "\" ignored");
    }
  }
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

DocSpecsDocument docspecsParseDocument(const std::string& text) {
  DocSpecsDocument doc;
  doc.declaredSchema = "";

  SpecMarkdownFenceTracker fence;
  std::vector<DocSpecsSection*> stack;  // borrowed; owned by tree

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
      if (!handled) {
        int level = 0;
        std::string rest;
        if (matchHeadingLine(line, &level, &rest)) {
          auto section = std::make_unique<DocSpecsSection>();
          std::string cid;
          std::string ctitle;
          if (matchHeadlineComment(rest, &cid, &ctitle)) {
            std::string title = ctitle.empty() ? rest : ctitle;
            section->id = cid;
            section->title = title;
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

/* ---- schema -------------------------------------------------------------- */

bool DocSpecsPatternCheck::matches(const std::string& value) const {
  Rx rx = rxCompile(pattern);
  return rxSearch(rx, value);
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
      loadDocument(schema, v);
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

/* resolveChild: resolves a child section's type; on no-match pushes an
 * unknownSection violation. Returns the type (may be nullptr). */
const DocSpecsSectionType* resolveChild(const DocSpecsSchema& schema,
                                        const DocSpecsSection& section,
                                        std::vector<DocSpecsViolation>& v) {
  if (section.id.empty()) {
    return nullptr;  // already reported malformedHeading by the parse
  }
  const DocSpecsSectionType* t = schema.resolveSectionType(section.id);
  if (t == nullptr) {
    dvPush(v, kDocSpecsRuleUnknownSection, section.line,
           "section id \"" + section.id +
               "\" resolves to no section-type of the schema",
           section.id, "");
  }
  return t;
}

void validateText(const DocSpecsSchema& schema, const DocSpecsSection& section,
                  const DocSpecsSectionType& t,
                  std::vector<DocSpecsViolation>& v) {
  if (!t.format.empty()) {
    if (schema.formType(t.format) != nullptr) {
      return;  // form sections carry fields, not body text
    }
  }
  std::string text = section.text();
  if (t.textRequired && text.empty()) {
    dvPush(v, kDocSpecsRuleTextRequired, section.line,
           "section requires body text but has none", section.id, "");
    return;
  }
  std::size_t length = runeCount(text);
  bool hasMin = t.hasMinTextLength;
  bool hasMax = t.hasMaxTextLength;
  if ((hasMin && length < static_cast<std::size_t>(t.minTextLength)) ||
      (hasMax && length > static_cast<std::size_t>(t.maxTextLength))) {
    std::string minStr = hasMin ? itoa(t.minTextLength) : "0";
    std::string maxStr = hasMax ? itoa(t.maxTextLength) : "\xe2\x88\x9e";
    dvPush(v, kDocSpecsRuleTextLengthOut, section.line,
           "body text length " + itoa(static_cast<long long>(length)) +
               " is outside [" + minStr + ", " + maxStr + "]",
           section.id, "");
  }
}

void validateForm(const DocSpecsSection& section, const DocSpecsFormType& form,
                  std::vector<DocSpecsViolation>& v) {
  std::size_t nf = form.fields.size();
  std::vector<std::string> values(nf);
  std::vector<bool> haveValue(nf, false);
  std::vector<int> fieldLine(nf, 0);

  SpecMarkdownFenceTracker fence;
  int current = -1;  // index into fields
  const std::vector<std::string>& body = section.bodyLines;
  for (std::size_t i = 0; i < body.size(); i++) {
    const std::string& raw = body[i];
    if (!fence.inFence()) {
      std::string label;
      std::string value;
      if (matchFieldLabel(raw, &label, &value)) {
        std::string labelLower = lowerAscii(label);
        int idx = -1;
        for (std::size_t fi = 0; fi < nf; fi++) {
          if (lowerAscii(form.fields[fi].name) == labelLower) {
            idx = static_cast<int>(fi);
            break;
          }
        }
        if (idx >= 0) {
          current = idx;
          values[idx] = value;  // reset to just group 2
          haveValue[idx] = true;
          fieldLine[idx] =
              section.bodyStartLine() + static_cast<int>(i);
          fence.feed(raw);
          continue;
        }
      }
    }
    if (current >= 0) {
      values[current] += '\n';
      values[current] += raw;
    }
    fence.feed(raw);
  }

  for (std::size_t fi = 0; fi < nf; fi++) {
    const DocSpecsFormField& field = form.fields[fi];
    std::string value = haveValue[fi] ? trimSpace(values[fi]) : std::string();
    if (field.required && value.empty()) {
      dvPush(v, kDocSpecsRuleMissingRequiredField, section.line,
             "required form field \"" + field.name + "\" of \"" + form.name +
                 "\" is missing",
             section.id, "");
      continue;
    }
    if (field.patternCheck.has_value() && !value.empty() &&
        !field.patternCheck->matches(value)) {
      int line = haveValue[fi] ? fieldLine[fi] : section.line;
      std::string message;
      if (!field.patternCheck->errorMessage.empty()) {
        message = field.patternCheck->errorMessage;
      } else {
        message = "form field \"" + field.name +
                  "\" does not match pattern \"" + field.patternCheck->pattern +
                  "\"";
      }
      dvPush(v, kDocSpecsRuleFieldPatternMismatch, line, message, section.id,
             "");
    }
  }
}

void validateFormat(const DocSpecsSchema& schema, const DocSpecsSection& section,
                    const DocSpecsSectionType& t,
                    std::vector<DocSpecsViolation>& v) {
  const std::string& format = t.format;
  if (format.empty()) {
    return;
  }
  const DocSpecsFormType* form = schema.formType(format);
  if (form != nullptr) {
    validateForm(section, *form, v);
    return;
  }
  SpecMarkdownFenceTracker fence;
  bool sawFence = false;
  for (const std::string& l : section.bodyLines) {
    fence.feed(l);
    if (fence.inFence()) {
      sawFence = true;
    }
  }
  if (!sawFence) {
    dvPush(v, kDocSpecsRuleFormatMismatch, section.line,
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

void validateSection(const DocSpecsSchema& schema, const DocSpecsSection& section,
                     const DocSpecsSectionType& t,
                     std::vector<DocSpecsViolation>& v) {
  if (t.patternCheck.has_value() && !section.id.empty() &&
      !t.patternCheck->matches(section.id)) {
    std::string message;
    if (!t.patternCheck->errorMessage.empty()) {
      message = t.patternCheck->errorMessage;
    } else {
      message = "section id \"" + section.id +
                "\" does not match pattern \"" + t.patternCheck->pattern + "\"";
    }
    dvPush(v, kDocSpecsRuleIdPatternMismatch, section.line, message, section.id,
           "");
  }
  validateText(schema, section, t, v);
  validateFormat(schema, section, t, v);

  CountMap counts;
  for (const auto& childPtr : section.children) {
    const DocSpecsSection& child = *childPtr;
    const DocSpecsSectionType* childType = resolveChild(schema, child, v);
    if (childType == nullptr) {
      continue;
    }
    if (t.subsection(childType->name) == nullptr) {
      dvPush(v, kDocSpecsRuleUnknownSection, child.line,
             "section-type \"" + childType->name +
                 "\" is not an allowed subsection of \"" + t.name + "\"",
             child.id, "");
      continue;
    }
    counts.inc(childType->name);
    validateSection(schema, child, *childType, v);
  }
  for (const auto& rule : t.subsectionTypes) {
    const std::string& subKey = rule.name;
    int count = counts.get(subKey);
    if (count < rule.minCount) {
      if (count == 0) {
        dvPush(v, kDocSpecsRuleMissingRequiredSection, section.line,
               "required subsection \"" + subKey + "\" of \"" + t.name +
                   "\" is missing",
               subKey, "");
      } else {
        dvPush(v, kDocSpecsRuleTooFewItems, section.line,
               "subsection \"" + subKey + "\" occurs " + itoa(count) +
                   " time(s), minimum is " + itoa(rule.minCount),
               subKey, "");
      }
    }
    if (rule.hasMax && count > rule.maxCount) {
      dvPush(v, kDocSpecsRuleTooManyItems, section.line,
             "subsection \"" + subKey + "\" occurs " + itoa(count) +
                 " time(s), maximum is " + itoa(rule.maxCount),
             subKey, "");
    }
  }
}

void validateDocumentSections(const DocSpecsSchema& schema,
                              const DocSpecsSection& root,
                              std::vector<DocSpecsViolation>& v) {
  CountMap counts;
  for (const auto& childPtr : root.children) {
    const DocSpecsSection& child = *childPtr;
    const DocSpecsSectionType* t = resolveChild(schema, child, v);
    if (t == nullptr) {
      continue;
    }
    bool isSlot = false;
    for (const auto& ds : schema.documentSections) {
      if (ds.sectionType == t->name) {
        isSlot = true;
        break;
      }
    }
    if (!isSlot) {
      dvPush(v, kDocSpecsRuleUnknownSection, child.line,
             "section-type \"" + t->name +
                 "\" is not a top-level document section",
             child.id, "");
      continue;
    }
    counts.inc(t->name);
    validateSection(schema, child, *t, v);
  }
  for (const auto& slot : schema.documentSections) {
    if (!slot.optional && counts.get(slot.sectionType) == 0) {
      dvPush(v, kDocSpecsRuleMissingRequiredSection, root.line,
             "required document section \"" + slot.key + "\" (type \"" +
                 slot.sectionType + "\") is missing",
             slot.key, "");
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
  validateDocumentSections(*schema_, root, out);
}

/* ---- bind ---------------------------------------------------------------- */

SpecMarkdownResult docspecsBindMarkdown(const SpecModel& model,
                                        const std::string& text) {
  return markdownParse(model, text);
}

}  // namespace som
