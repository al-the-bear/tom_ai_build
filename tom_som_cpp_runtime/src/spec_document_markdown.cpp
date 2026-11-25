/* spec_document_markdown — implementation. See spec_document_markdown.hpp; a
 * faithful port of the C `spec_document_markdown.c` (the DocSpecs markdown
 * codec). The Go regexps are reproduced as hand-rolled scanners so the runtime
 * stays dependency-free.
 *
 * Every `List<T>` field maps to a two-level md hierarchy: a `<!--[FOO-LST]-->`
 * container heading (SOM §11.2/§11.5) at the owner's child level, holding the
 * numbered item headings one level deeper, with item-element children one level
 * deeper again. The container carries no body of its own; item identity is
 * purely positional. */
#include "spec_document_markdown.hpp"

#include <algorithm>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include "som_util.hpp"
#include "spec_meta.hpp"
#include "spec_meta_bridge.hpp"
#include "spec_model.hpp"
#include "spec_paths.hpp"
#include "spec_section_id.hpp"

namespace som {
namespace {

/* ---- small char helpers -------------------------------------------------- */

bool isUpper(char c) { return c >= 'A' && c <= 'Z'; }
bool isLower(char c) { return c >= 'a' && c <= 'z'; }
bool isDigit(char c) { return c >= '0' && c <= '9'; }
bool isAlpha(char c) { return isUpper(c) || isLower(c); }
char toLowerC(char c) { return isUpper(c) ? (char)(c - 'A' + 'a') : c; }
char toUpperC(char c) { return isLower(c) ? (char)(c - 'a' + 'A') : c; }

/* Go's unicode.IsSpace for the ASCII bytes the regexps `\s` matches. */
bool isWs(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' ||
         c == '\f';
}

std::string lowerDup(const std::string& s) {
  std::string out(s.size(), '\0');
  for (std::size_t i = 0; i < s.size(); i++) {
    out[i] = toLowerC(s[i]);
  }
  return out;
}

/* strings.TrimSpace on ASCII whitespace. */
std::string trimSpace(const std::string& s) {
  std::size_t start = 0, n = s.size();
  while (start < n && isWs(s[start])) {
    start++;
  }
  while (n > start && isWs(s[n - 1])) {
    n--;
  }
  return s.substr(start, n - start);
}

/* strings.Split(text, "\n") into line copies. */
std::vector<std::string> splitLines(const std::string& text) {
  std::vector<std::string> out;
  std::size_t start = 0;
  for (std::size_t p = 0;; p++) {
    if (p == text.size() || text[p] == '\n') {
      out.push_back(text.substr(start, p - start));
      if (p == text.size()) {
        break;
      }
      start = p + 1;
    }
  }
  return out;
}

/* ---- regex-equivalent scanners ------------------------------------------- */

/* mdTrailingWSRE = `\s+$` — strip trailing ASCII whitespace. */
std::string stripTrailingWs(const std::string& s) {
  std::size_t n = s.size();
  while (n > 0 && isWs(s[n - 1])) {
    n--;
  }
  return s.substr(0, n);
}

/* mdDocspecCommentRE = `^<!--\s*docspec:.*-->\s*$`. */
bool isDocspecComment(const std::string& s) {
  if (s.compare(0, 4, "<!--") != 0) {
    return false;
  }
  std::size_t p = 4;
  while (p < s.size() && isWs(s[p])) {
    p++;
  }
  if (s.compare(p, 8, "docspec:") != 0) {
    return false;
  }
  /* `.*-->` — find the last "-->" then require only trailing whitespace. */
  std::size_t last = std::string::npos;
  for (std::size_t q = p; q + 2 < s.size(); q++) {
    if (s[q] == '-' && s[q + 1] == '-' && s[q + 2] == '>') {
      last = q;
    }
  }
  if (last == std::string::npos) {
    return false;
  }
  for (std::size_t tail = last + 3; tail < s.size(); tail++) {
    if (!isWs(s[tail])) {
      return false;
    }
  }
  return true;
}

/* mdHeadingLineRE = `^(#+)\s+(.*)$`. On match writes hash count + rest. */
bool matchHeadingLine(const std::string& s, int* level, std::string* rest) {
  std::size_t hashes = 0;
  while (hashes < s.size() && s[hashes] == '#') {
    hashes++;
  }
  if (hashes == 0) {
    return false;
  }
  std::size_t p = hashes;
  if (p >= s.size() || !isWs(s[p])) {
    return false;
  }
  while (p < s.size() && isWs(s[p])) {
    p++;
  }
  *level = (int)hashes;
  *rest = s.substr(p);
  return true;
}

/* mdHeadlineCommentRE = `^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$`. Three-group
 * (codespecs_mapping.md §9.2): group 1 = the section id, group 2 = the raw
 * key=value region between the id bracket and the closing `-->` (possibly
 * empty), group 3 = the heading title. The middle region is `[^>]*` — safe
 * because its only values are quoted
 * code locations. `s` should already be TrimSpace'd. */
bool matchHeadlineComment(const std::string& s, std::string* id,
                          std::string* region, std::string* title) {
  if (s.compare(0, 5, "<!--[") != 0) {
    return false;
  }
  std::size_t p = 5;
  std::size_t close = s.find(']', p);
  if (close == std::string::npos || close == p) {
    return false;  // [^\]]+ requires at least one char
  }
  // `([^>]*)-->` — the region runs from after `]` up to a `-->` that contains
  // no `>` before it.
  std::size_t r = close + 1;
  std::size_t end = s.find("-->", r);
  if (end == std::string::npos) {
    return false;
  }
  // The `[^>]*` region must not contain a `>` before the closing `-->`.
  if (s.find('>', r) != end + 2) {
    return false;
  }
  *id = s.substr(p, close - p);
  if (region != nullptr) {
    *region = s.substr(r, end - r);
  }
  if (title != nullptr) {
    // `\s*(.*)$` — skip leading whitespace after `-->`, then TrimSpace.
    std::size_t t = end + 3;
    while (t < s.size() && isWs(s[t])) {
      t++;
    }
    *title = trimSpace(s.substr(t));
  }
  return true;
}

/* The value of `key` in a heading-comment key=value region, read as the
 * pattern `key(?:"([^"]*)"|'([^']*)'|([^,\s>]+))` reads it: double-quoted,
 * single-quoted or bare, trimmed. A quote that is never closed is no quoted
 * value, so the bare alternative takes it as part of its run; an occurrence
 * whose value matches none of the three forms is passed over and the search
 * goes on, as a regular expression's first match would. With `atBoundary` the
 * key must start the region or follow whitespace. "" when nothing matches. */
std::string keyValueOf(const std::string& region, const std::string& key,
                       bool atBoundary) {
  for (std::size_t pos = region.find(key); pos != std::string::npos;
       pos = region.find(key, pos + 1)) {
    if (atBoundary && pos > 0 && !isWs(region[pos - 1])) {
      continue;
    }
    std::size_t v = pos + key.size();
    if (v < region.size() && (region[v] == '"' || region[v] == '\'')) {
      std::size_t close = region.find(region[v], v + 1);
      if (close != std::string::npos) {
        return trimSpace(region.substr(v + 1, close - (v + 1)));
      }
    }
    std::size_t e = v;
    while (e < region.size() && region[e] != ',' && !isWs(region[e]) &&
           region[e] != '>') {
      e++;
    }
    if (e > v) {
      return trimSpace(region.substr(v, e - v));
    }
  }
  return "";
}

/* mdFenceOpenRE = "^ {0,3}(`{3,}|~{3,})". */
bool matchFenceOpen(const std::string& s, char* ch, std::size_t* run) {
  std::size_t i = 0;
  while (i < 3 && i < s.size() && s[i] == ' ') {
    i++;
  }
  if (i >= s.size()) {
    return false;
  }
  char c = s[i];
  if (c != '`' && c != '~') {
    return false;
  }
  std::size_t n = 0;
  while (i + n < s.size() && s[i + n] == c) {
    n++;
  }
  if (n < 3) {
    return false;
  }
  *ch = c;
  *run = n;
  return true;
}

/* mdEscapableRE = `^\\*#` — optional run of backslashes then `#` at col 0. */
bool matchEscapable(const std::string& s) {
  std::size_t i = 0;
  while (i < s.size() && s[i] == '\\') {
    i++;
  }
  return i < s.size() && s[i] == '#';
}

/* mdEscapedHeadingRE = `^\\+#` — one-or-more backslashes then `#`. */
bool matchEscapedHeading(const std::string& s) {
  if (s.empty() || s[0] != '\\') {
    return false;
  }
  std::size_t i = 0;
  while (i < s.size() && s[i] == '\\') {
    i++;
  }
  return i < s.size() && s[i] == '#';
}

/* mdLabelShapedRE = `^ *[A-Za-z][A-Za-z0-9_]*:`. */
bool matchLabelShaped(const std::string& s) {
  std::size_t i = 0;
  while (i < s.size() && s[i] == ' ') {
    i++;
  }
  if (i >= s.size() || !isAlpha(s[i])) {
    return false;
  }
  i++;
  while (i < s.size() && (isAlpha(s[i]) || isDigit(s[i]) || s[i] == '_')) {
    i++;
  }
  return i < s.size() && s[i] == ':';
}

/* mdContinuationLabelRE = `^ +[A-Za-z][A-Za-z0-9_]*:` — needs 1+ leading
 * space. */
bool matchContinuationLabel(const std::string& s) {
  if (s.empty() || s[0] != ' ') {
    return false;
  }
  return matchLabelShaped(s);
}

/* mdFieldLabelRE = `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$`. */
bool matchFieldLabel(const std::string& s, std::string* label,
                     std::string* value) {
  if (s.empty() || !isAlpha(s[0])) {
    return false;
  }
  std::size_t i = 1;
  while (i < s.size() && (isAlpha(s[i]) || isDigit(s[i]) || s[i] == '_')) {
    i++;
  }
  if (i >= s.size() || s[i] != ':') {
    return false;
  }
  std::size_t nameEnd = i;
  i++;  // past ':'
  if (i < s.size() && s[i] == ' ') {
    i++;  // optional single space
  }
  *label = s.substr(0, nameEnd);
  *value = s.substr(i);
  return true;
}

/* ---- reading-view layout lines (SOM §11.4, §11.5) ------------------------ */

/* Whether `s` holds `word` at `*p`, any ASCII case; advances `*p` past it. */
bool matchWordCi(const std::string& s, std::size_t* p, const char* word) {
  std::size_t i = *p;
  for (const char* w = word; *w != '\0'; w++, i++) {
    if (i >= s.size() || toLowerC(s[i]) != toLowerC(*w)) {
      return false;
    }
  }
  *p = i;
  return true;
}

void skipWs(const std::string& s, std::size_t* p) {
  while (*p < s.size() && isWs(s[*p])) {
    (*p)++;
  }
}

/* The rest of a layout header after its first `|` at `p`:
 * `\s*(?:(Section)\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$`, any case.
 * Sets `*isSection` for a section-table header. */
bool matchLayoutHeaderRest(const std::string& s, std::size_t p,
                           bool* isSection) {
  skipWs(s, &p);
  bool section = false;
  std::size_t q = p;
  if (matchWordCi(s, &q, "Section")) {
    skipWs(s, &q);
    if (q < s.size() && s[q] == '|') {
      q++;
      skipWs(s, &q);
      section = true;
      p = q;
    }
  }
  if (!matchWordCi(s, &p, "TomSpecField")) {
    return false;
  }
  skipWs(s, &p);
  if (p >= s.size() || s[p] != '|') {
    return false;
  }
  p++;
  skipWs(s, &p);
  if (!matchWordCi(s, &p, "Value")) {
    return false;
  }
  skipWs(s, &p);
  if (p < s.size() && s[p] == '|') {
    p++;
  }
  skipWs(s, &p);
  if (p != s.size()) {
    return false;
  }
  if (isSection != nullptr) {
    *isSection = section;
  }
  return true;
}

/* A line that reads as the header of a form table or a section table:
 * `| TomSpecField | Value |` or `| Section | TomSpecField | Value |` at
 * column 0, any case. The header alone makes a table layout. */
bool matchLayoutTableHeader(const std::string& s, bool* isSection) {
  return !s.empty() && s[0] == '|' && matchLayoutHeaderRest(s, 1, isSection);
}

/* A value line shaped like a layout header after `minSpaces` or more spaces
 * (0: the emitter escapes it with one space; 1: the parse removes it). */
bool matchHeaderShaped(const std::string& s, std::size_t minSpaces) {
  std::size_t i = 0;
  while (i < s.size() && s[i] == ' ') {
    i++;
  }
  return i >= minSpaces && i < s.size() && s[i] == '|' &&
         matchLayoutHeaderRest(s, i + 1, nullptr);
}

/* `^ {0,3}\|`: a line that starts a table row. */
bool matchTableLine(const std::string& s) {
  std::size_t i = 0;
  while (i < 3 && i < s.size() && s[i] == ' ') {
    i++;
  }
  return i < s.size() && s[i] == '|';
}

/* `^:?-+:?$`: a cell of a table's delimiter row. */
bool matchDelimiterCell(const std::string& c) {
  std::size_t i = 0;
  std::size_t n = c.size();
  if (i < n && c[i] == ':') {
    i++;
  }
  if (n > i && c[n - 1] == ':') {
    n--;
  }
  if (i >= n) {
    return false;
  }
  for (std::size_t k = i; k < n; k++) {
    if (c[k] != '-') {
      return false;
    }
  }
  return true;
}

/* One `\[([^\]]+)\]\([^)]*\)` at `p`: its text, and `*end` after it. */
bool matchLinkAt(const std::string& s, std::size_t p, std::string* text,
                 std::size_t* end) {
  if (p >= s.size() || s[p] != '[') {
    return false;
  }
  std::size_t close = s.find(']', p + 1);
  if (close == std::string::npos || close == p + 1) {
    return false;
  }
  if (close + 1 >= s.size() || s[close + 1] != '(') {
    return false;
  }
  std::size_t paren = s.find(')', close + 2);
  if (paren == std::string::npos) {
    return false;
  }
  if (text != nullptr) {
    *text = s.substr(p + 1, close - p - 1);
  }
  *end = paren + 1;
  return true;
}

/* `^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$`: a cell of links only; their
 * texts in `*texts`. */
bool matchLinkCell(const std::string& s, std::vector<std::string>* texts) {
  std::size_t p = 0;
  std::vector<std::string> out;
  for (;;) {
    std::string text;
    std::size_t end = 0;
    if (!matchLinkAt(s, p, &text, &end)) {
      return false;
    }
    out.push_back(text);
    if (end == s.size()) {
      break;
    }
    if (s.compare(end, 2, ", ") != 0) {
      return false;
    }
    p = end + 2;
  }
  *texts = std::move(out);
  return true;
}

/* The first `\[([^\]]+)\]\([^)]*\)` anywhere in `s`: its text, or "" with
 * false. */
bool findLinkText(const std::string& s, std::string* text) {
  for (std::size_t p = s.find('['); p != std::string::npos;
       p = s.find('[', p + 1)) {
    std::size_t end = 0;
    if (matchLinkAt(s, p, text, &end)) {
      return true;
    }
  }
  return false;
}

/* `^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$`: the opening fence
 * of a list body's div; its kind in `*kind`. */
bool matchListDivOpen(const std::string& s, std::string* kind) {
  std::size_t p = 0;
  while (p < s.size() && s[p] == ':') {
    p++;
  }
  if (p < 3) {
    return false;
  }
  skipWs(s, &p);
  bool braces = p < s.size() && s[p] == '{';
  if (braces) {
    if (s.compare(p, 2, "{.") != 0) {
      return false;
    }
    p += 2;
  }
  std::string k;
  if (s.compare(p, 4, "refs") == 0) {
    k = "refs";
  } else if (s.compare(p, 7, "records") == 0) {
    k = "records";
  } else {
    return false;
  }
  p += k.size();
  if (braces) {
    if (p >= s.size() || s[p] != '}') {
      return false;
    }
    p++;
  }
  skipWs(s, &p);
  if (p != s.size()) {
    return false;
  }
  *kind = k;
  return true;
}

/* `^:{3,}\s*$`: a closing fence. */
bool matchDivCloseLine(const std::string& s) {
  std::size_t p = 0;
  while (p < s.size() && s[p] == ':') {
    p++;
  }
  if (p < 3) {
    return false;
  }
  skipWs(s, &p);
  return p == s.size();
}

/* Strip leading + trailing newlines (SOM §11.3). Blank lines inside the value
 * are kept as written, so a value round-trips exactly. */
std::string trimNewlines(const std::string& value) {
  std::size_t start = 0, n = value.size();
  while (start < n && value[start] == '\n') {
    start++;
  }
  while (n > start && value[n - 1] == '\n') {
    n--;
  }
  return value.substr(start, n - start);
}

/* Replaces every occurrence of `from` in `s` with `to`. */
std::string replaceAllStr(const std::string& s, const std::string& from,
                          const std::string& to) {
  std::string out;
  std::size_t pos = 0;
  for (;;) {
    std::size_t hit = s.find(from, pos);
    if (hit == std::string::npos) {
      out.append(s, pos, std::string::npos);
      return out;
    }
    out.append(s, pos, hit - pos);
    out += to;
    pos = hit + from.size();
  }
}

/* mdLeadingBlankLnRE `^([ \t]*\n)+` and mdTrailingBlankLnRE `(\n[ \t]*)+$`. */
std::string stripBlankLines(const std::string& joined) {
  std::size_t n = joined.size();
  std::size_t start = 0;
  for (;;) {
    std::size_t j = start;
    while (j < n && (joined[j] == ' ' || joined[j] == '\t')) {
      j++;
    }
    if (j < n && joined[j] == '\n') {
      start = j + 1;
    } else {
      break;
    }
  }
  std::size_t end = n;
  for (;;) {
    std::size_t j = end;
    while (j > start && (joined[j - 1] == ' ' || joined[j - 1] == '\t')) {
      j--;
    }
    if (j > start && joined[j - 1] == '\n') {
      end = j - 1;
    } else {
      break;
    }
  }
  if (end < start) {
    end = start;
  }
  return joined.substr(start, end - start);
}

}  // namespace

/* mdCodeSpecPattern = `codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))`: the
 * `codeSpec` value of a heading-comment key=value region
 * (codespecs_mapping.md §9.2), mirroring the tom_doc_scanner key=value
 * grammar. */
std::string markdownCodeSpecOf(const std::string& region) {
  return keyValueOf(region, "codeSpec=", false);
}

/* mdUnitsPattern = `(?:^|\s)units=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))`: the
 * `units` value of a heading-comment key=value region (SOM §11.2). The key
 * must start the region or follow whitespace, so a `units=` inside a quoted
 * codeSpec value is not read as the key. */
std::string markdownUnitsOf(const std::string& region) {
  return keyValueOf(region, "units=", true);
}

/* ======================================================================== */
/* Fence tracker (public API)                                                */
/* ======================================================================== */

void SpecMarkdownFenceTracker::feed(const std::string& line) {
  char ch;
  std::size_t run;
  if (!matchFenceOpen(line, &ch, &run)) {
    return;
  }
  if (ch_ == 0) {
    ch_ = ch;
    size_ = run;
    return;
  }
  std::string trimmed = trimSpace(line);
  bool allSame = !trimmed.empty();
  for (char t : trimmed) {
    if (t != ch_) {
      allSame = false;
      break;
    }
  }
  if (ch == ch_ && run >= size_ && allSame) {
    ch_ = 0;
    size_ = 0;
  }
}

/* ======================================================================== */
/* Naming helpers (SOM §11.2 / §11.5)                                          */
/* ======================================================================== */

std::string titleCase(const std::string& name) {
  std::string out;
  std::size_t i = 0;
  bool firstWord = true;
  while (i < name.size()) {
    std::size_t start = i;
    i++;
    while (i < name.size() && !isUpper(name[i])) {
      i++;
    }
    if (!firstWord) {
      out.push_back(' ');
    }
    firstWord = false;
    out.push_back(toUpperC(name[start]));
    out.append(name, start + 1, i - start - 1);
  }
  return out;
}

std::string kebabCase(const std::string& title) {
  std::string trimmed = trimSpace(title);
  std::string spaced;
  std::size_t i = 0;
  while (i < trimmed.size()) {
    if (isWs(trimmed[i]) || trimmed[i] == '_') {
      while (i < trimmed.size() && (isWs(trimmed[i]) || trimmed[i] == '_')) {
        i++;
      }
      spaced.push_back('-');
    } else {
      spaced.push_back(trimmed[i]);
      i++;
    }
  }
  std::string out;
  for (char c : spaced) {
    if (isAlpha(c) || isDigit(c) || c == '-') {
      out.push_back(toLowerC(c));
    }
  }
  return out;
}

std::string itemTitleStem(const std::string& elementClassName) {
  std::string stem = elementClassName;
  std::size_t n = elementClassName.size();
  if (n > 5 && elementClassName.compare(n - 5, 5, "Entry") == 0) {
    stem = elementClassName.substr(0, n - 5);
  }
  return titleCase(stem);
}

std::string formLabel(const std::string& fieldName) {
  if (fieldName.empty()) {
    return "";
  }
  std::string out;
  out.push_back(toUpperC(fieldName[0]));
  out.append(fieldName, 1, std::string::npos);
  return out;
}

/* ======================================================================== */
/* Codec object                                                              */
/* ======================================================================== */

namespace {

/* One tree per root type, built lazily and cached. */
class MdCodec {
 public:
  MdCodec(const SpecModel& model, const SpecDocument* document)
      : model_(model), document_(document) {}

  const SpecModel& model() const { return model_; }
  const SpecDocument* document() const { return document_; }

  /* Returns the cached / newly-built tree for `rootType`, or nullptr writing
   * `*err`. Ownership stays with the codec. */
  SomMetaTree* treeFor(const std::string& rootType, std::string* err) {
    auto it = trees_.find(rootType);
    if (it != trees_.end()) {
      return it->second.get();
    }
    std::unique_ptr<SomMetaTree> tree = somBuildMetaTree(model_, rootType, err);
    if (tree == nullptr) {
      return nullptr;
    }
    SomMetaTree* raw = tree.get();
    trees_.emplace(rootType, std::move(tree));
    return raw;
  }

  const SpecClass* classNamed(const std::string& name) const {
    return model_.classNamed(name);
  }

  /* When non-null, every heading written appends the document path it renders,
   * in emission order (markdownExportRootWithMap). Borrowed. */
  std::vector<std::string>* headingPaths = nullptr;

 private:
  const SpecModel& model_;
  const SpecDocument* document_;
  std::map<std::string, std::unique_ptr<SomMetaTree>> trees_;
};

/* ---- transparency + heading id ------------------------------------------ */

bool kindEq(const char* kind, const char* other) {
  return std::string(kind) == other;
}

/* headingIdOf: field-level id, else target-class id for section/complex, else
 * the segment. */
std::string headingIdOf(MdCodec& c, const SomMetaNode& node) {
  if (!node.sectionId.empty()) {
    return node.sectionId;
  }
  // The class id is the node's classSectionId, as the YAML key uses — never
  // classNamed(node.className): a wrapper section (TextSection, ...) carries
  // its OWNER's class name, and that lookup returned the owner's id.
  (void)c;
  if (kindEq(node.kind, kSomMetaKindSection) ||
      kindEq(node.kind, kSomMetaKindComplex)) {
    if (!node.classSectionId.empty()) {
      return node.classSectionId;
    }
  }
  return node.segment();
}

bool isTransparentSection(MdCodec& c, const SomMetaNode& n) {
  if (!kindEq(n.kind, kSomMetaKindSection) &&
      !kindEq(n.kind, kSomMetaKindComplex)) {
    return false;
  }
  if (!n.sectionId.empty()) {
    return false;
  }
  // classSectionId, not classNamed(n.className): see headingIdOf. A wrapper
  // section (TextSection, ...) has neither id, so it is transparent (SOM §11.6).
  (void)c;
  return n.classSectionId.empty();
}

bool isTransparentValue(const SomMetaNode& n) {
  return n.sectionId.empty() &&
         (kindEq(n.kind, kSomMetaKindContent) ||
          kindEq(n.kind, kSomMetaKindScalar) ||
          kindEq(n.kind, kSomMetaKindEnumValue) ||
          kindEq(n.kind, kSomMetaKindForm));
}

bool isValueLeaf(const char* kind) {
  return kindEq(kind, kSomMetaKindContent) ||
         kindEq(kind, kSomMetaKindScalar) ||
         kindEq(kind, kSomMetaKindEnumValue);
}

/* mdNodeRel: node + relative path. */
struct NodeRel {
  const SomMetaNode* node;
  std::string rel;
};

void bodySlotsCollect(MdCodec& c, const SomMetaNode& n, const std::string& prefix,
                      std::vector<NodeRel>& out) {
  for (const auto& childPtr : n.children) {
    const SomMetaNode* child = childPtr.get();
    if (child->recursive) {
      continue;
    }
    std::string seg = child->segment();
    std::string rel = !prefix.empty() ? specPathJoin(prefix, seg) : seg;
    if (isTransparentValue(*child)) {
      out.push_back({child, rel});
    } else if (isTransparentSection(c, *child)) {
      out.push_back({child, rel});
      bodySlotsCollect(c, *child, rel, out);
    }
  }
}

std::vector<NodeRel> bodySlots(MdCodec& c, const SomMetaNode& node) {
  std::vector<NodeRel> out;
  bodySlotsCollect(c, node, "", out);
  return out;
}

/* The body slot unmarked body text binds to on import (SOM §11.6): the first
 * non-form slot; with none, the form on the `content` member, else the first
 * form; with no slot at all the owner itself (`.`). */
std::string defaultBodyRel(const std::vector<NodeRel>& slots) {
  for (const auto& s : slots) {
    if (!kindEq(s.node->kind, kSomMetaKindForm)) {
      return s.rel;
    }
  }
  for (const auto& s : slots) {
    if (s.rel == "content") {
      return s.rel;
    }
  }
  return slots.empty() ? std::string(".") : slots.front().rel;
}

void effectiveChildrenCollect(MdCodec& c, const SomMetaNode& n,
                              const std::string& prefix,
                              std::vector<NodeRel>& out) {
  for (const auto& childPtr : n.children) {
    const SomMetaNode* child = childPtr.get();
    if (child->recursive) {
      continue;
    }
    std::string seg = child->segment();
    std::string rel = !prefix.empty() ? specPathJoin(prefix, seg) : seg;
    if (isTransparentValue(*child)) {
      continue;
    }
    if (isTransparentSection(c, *child)) {
      effectiveChildrenCollect(c, *child, rel, out);
    } else {
      out.push_back({child, rel});
    }
  }
}

std::vector<NodeRel> effectiveChildren(MdCodec& c, const SomMetaNode& node) {
  std::vector<NodeRel> out;
  effectiveChildrenCollect(c, node, "", out);
  return out;
}

/* ======================================================================== */
/* Export                                                                    */
/* ======================================================================== */

/* The effective DEFAULT title of `node` (YRD4): the `@Headline` default when
 * authored, else the name derivation. The stored headline (checked by callers
 * first) always wins over this. */
std::string mdTitleOf(const SomMetaNode& node) {
  if (!node.headline.empty()) {
    return node.headline;
  }
  const std::string& name =
      !node.memberName.empty() ? node.memberName : node.className;
  return titleCase(name);
}

/* The effective default item-title stem of list `node` (YRD4): the element
 * class's `@Headline` default when authored, else the SOM §11.5 derivation
 * (element class name with `Entry` dropped; member name for scalar lists). */
std::string mdItemStemOf(const SomMetaNode& node) {
  const SomMetaNode* element = node.elementNode.get();
  if (element != nullptr) {
    return !element->headline.empty() ? element->headline
                                      : itemTitleStem(element->className);
  }
  return titleCase(!node.memberName.empty() ? node.memberName
                                            : node.segment());
}

/* headingTitle resolves the heading title for a node at `path`: the document's
 * STORED headline when present, else the derived title (YRD3). */
std::string headingTitle(MdCodec& c, const std::string& path,
                         const SomMetaNode& node) {
  std::string h = c.document()->headline(path);
  if (!h.empty()) {
    return h;
  }
  return mdTitleOf(node);
}

/* Emits `#… <!--[ID]--> Title`, recording `path` (the document path the
 * heading renders) when the codec keeps a heading map. When `codeSpec` is non-empty it is emitted as a
 * `codeSpec="…"` key inside the same headline comment (codespecs_mapping.md
 * §9.2): `## <!--[ID] codeSpec="A,B"--> Title`. Byte-identical to the id-only
 * form when
 * `codeSpec` is empty. When `units` is non-empty it follows as a second key,
 * `units="…"`, after `codeSpec` (SOM §11.2). */
void mdWriteHeading(MdCodec& c, std::string& b, int depth,
                    const std::string& id, const std::string& title,
                    const std::string& path,
                    const std::string& codeSpec = "",
                    const std::string& units = "") {
  if (c.headingPaths != nullptr) {
    c.headingPaths->push_back(path);
  }
  for (int i = 0; i < depth; i++) {
    b.push_back('#');
  }
  b += " <!--[";
  b += id;
  b.push_back(']');
  if (!codeSpec.empty()) {
    b += " codeSpec=\"";
    b += codeSpec;
    b.push_back('"');
  }
  // SOM §11.2: non-empty units follow as a second key, after `codeSpec`.
  if (!units.empty()) {
    b += " units=\"";
    b += units;
    b.push_back('"');
  }
  b += "--> ";
  // A heading is one line: a stored headline's line breaks travel as `<br>`.
  b += replaceAllStr(title, "\n", "<br>");
  b.push_back('\n');
  b.push_back('\n');
}

std::string pathFenceErr(const std::string& path) {
  return "content at \"" + path +
         "\" contains an unterminated fenced code block; it cannot be "
         "represented in the DocSpecs markdown format";
}

/* Whether a code field's `value` is written as an inline code span (SOM §11.4
 * rule 8): it is non-empty and on one line. A multi-line value keeps the prose
 * rendering — a code span cannot cross a line break without markdown joining
 * the lines. */
bool isInlineCode(const std::string& value) {
  return !value.empty() && value.find('\n') == std::string::npos;
}

/* `value` as a CommonMark inline code span: delimited by one backtick more
 * than the longest backtick run inside it, and padded with one space on each
 * side when it begins or ends with a backtick or a space — the padding
 * CommonMark strips again, so the span's content is exactly `value`. */
std::string encodeCodeSpan(const std::string& value) {
  std::size_t longest = 0;
  std::size_t run = 0;
  for (char c : value) {
    if (c == '`') {
      run++;
      if (run > longest) {
        longest = run;
      }
    } else {
      run = 0;
    }
  }
  std::string fence(longest + 1, '`');
  auto padChar = [](char c) { return c == '`' || c == ' '; };
  bool pad = !value.empty() && (padChar(value.front()) || padChar(value.back()));
  std::string p = pad ? " " : "";
  return fence + p + value + p + fence;
}

/* prepareValue: trim leading/trailing blank lines (inner blank lines are kept),
 * escape heading-like lines outside fences.
 * Throws std::invalid_argument on an unterminated fence. */
std::string prepareValue(const std::string& value, const std::string& path) {
  std::string collapsed = trimNewlines(value);
  std::vector<std::string> lines = splitLines(collapsed);
  SpecMarkdownFenceTracker fence;
  std::string b;
  for (std::size_t i = 0; i < lines.size(); i++) {
    const std::string& line = lines[i];
    if (i > 0) {
      b.push_back('\n');
    }
    if (fence.inFence()) {
      b += line;
    } else if (matchEscapable(line)) {
      b.push_back('\\');
      b += line;
    } else if (matchHeaderShaped(line, 0)) {
      b.push_back(' ');  // DI-2: a value line is never a layout table.
      b += line;
    } else {
      b += line;
    }
    fence.feed(line);
  }
  if (fence.inFence()) {
    throw std::invalid_argument(pathFenceErr(path));
  }
  return b;
}

std::string contentOf(const SpecDocument& doc, const std::string& path,
                      bool* present) {
  const std::string* v = doc.contentOpt(path);
  *present = v != nullptr;
  return v != nullptr ? *v : std::string();
}

/* writeBody: prepared value + blank line, no-op when blank. */
void writeBody(std::string& b, const std::string& value,
               const std::string& path) {
  std::string prepared = prepareValue(value, path);
  if (prepared.empty()) {
    return;
  }
  b += prepared;
  b.push_back('\n');
  b.push_back('\n');
}

/* The stored field names at form `path` that `node` does not declare, sorted
 * (SOM §9, "Form-field order").
 *
 * The emit walk is meta-driven — it iterates the model's declared fields — so a
 * stored field the model does not know is invisible to it and cannot be dropped
 * *loudly*. Seeing it at all needs this deliberate reverse check: store keys
 * minus meta keys, which is the check the yaml codec already has (SOM §12.8). */
std::vector<std::string> undeclaredFormFields(const SpecDocument& doc,
                                              const SomMetaNode& node,
                                              const std::string& path) {
  std::set<std::string> declared;
  if (node.form.has_value()) {
    for (const auto& f : node.form->fields) {
      declared.insert(f.name);
    }
  }
  std::vector<std::string> out;
  for (const auto& name : doc.formFieldNames(path)) {
    if (declared.find(name) == declared.end()) {
      out.push_back(name);
    }
  }
  std::sort(out.begin(), out.end());
  return out;
}

/* Throws when the form at `path` holds a field the model does not declare
 * (SOM §9, "Form-field order" — md refuses, matching yaml).
 *
 * Emitting it is impossible: the DocSpecs markdown grammar has no spelling for a
 * field outside the model, and omitting it would lose a stored value in a file
 * that looks complete. On import a partial document is normal and the codec
 * reports-and-skips (SOM §11.7); on export the document is complete and a lossy
 * rendering is a trap, so the codec refuses instead. */
void checkFormDeclared(const SpecDocument& doc, const SomMetaNode& node,
                       const std::string& path) {
  std::vector<std::string> undeclared = undeclaredFormFields(doc, node, path);
  if (undeclared.empty()) {
    return;
  }
  throw std::invalid_argument("form at \"" + path + "\" holds a field \"" +
                              undeclared.front() +
                              "\" unknown to the model; it cannot be "
                              "represented in the DocSpecs markdown format");
}

/* Whether the `@Form` node at `path` has anything to emit: its preamble content
 * (SOM §11.4 rule 7 — the DocSpecs `${text[]}` region), or any populated field.
 *
 * An undeclared stored field counts too — not because it can be emitted, but so
 * the section is still *visited* and `writeForm` refuses. Without it a form
 * holding nothing but undeclared fields would vanish unseen, which is the silent
 * drop this check exists to prevent. */
bool formHasValues(const SpecDocument& doc, const SomMetaNode& node,
                   const std::string& path) {
  if (doc.hasContent(path)) {
    return true;
  }
  if (node.form.has_value()) {
    for (const auto& f : node.form->fields) {
      if (doc.formFieldOpt(path, f.name) != nullptr) {
        return true;
      }
    }
  }
  return !undeclaredFormFields(doc, node, path).empty();
}

/* Writes a `@Form` section body: the preamble content (when set) followed by one
 * `FieldName: value` group per populated field (SOM §11.4), consecutive groups
 * separated by one blank line. Throws
 * std::invalid_argument when the form holds a field the model does not
 * declare. */
void writeForm(std::string& b, const SpecDocument& doc, const SomMetaNode& node,
               const std::string& path) {
  checkFormDeclared(doc, node, path);
  std::string fields;
  if (node.form.has_value()) {
    for (const auto& f : node.form->fields) {
      const std::string* value = doc.formFieldOpt(path, f.name);
      if (value == nullptr) {
        continue;
      }
      /* SOM §11.4 rule 2: one blank line between consecutive field groups, so
       * a markdown viewer renders each field as its own paragraph (and a list
       * ending a value cannot swallow the next label as a lazy continuation).
       * Parse trims each value's trailing blank lines, so it is lossless. */
      if (!fields.empty()) {
        fields.push_back('\n');
      }
      /* SOM §11.4 rule 8: a single-line code value is written as an inline
       * code span, so markdown leaves it literal (`](` is not a link). */
      std::vector<std::string> plines =
          f.code && isInlineCode(*value)
              ? std::vector<std::string>{encodeCodeSpan(*value)}
              : splitLines(prepareValue(*value, path));
      fields += formLabel(f.name);
      fields += ": ";
      fields += !plines.empty() ? plines[0] : "";
      fields.push_back('\n');
      for (std::size_t li = 1; li < plines.size(); li++) {
        const std::string& line = plines[li];
        if (matchLabelShaped(line)) {
          fields.push_back(' ');
          fields += line;
        } else {
          fields += line;
        }
        fields.push_back('\n');
      }
    }
  }

  const std::string* preamble = doc.contentOpt(path);
  if (preamble != nullptr) {
    std::string prepared = prepareValue(*preamble, path);
    if (!prepared.empty()) {
      /* Every preamble line gets the same label-shaped escape a continuation
       * line gets: the parser reaches a field label before it knows which text
       * is preamble, so a `Word:` line at column 0 would mis-split. */
      for (const auto& line : splitLines(prepared)) {
        if (matchLabelShaped(line)) {
          b.push_back(' ');
        }
        b += line;
        b.push_back('\n');
      }
      if (!fields.empty()) {
        b.push_back('\n');
      }
    }
  }
  b += fields;
  b.push_back('\n');
}

void writeChildren(MdCodec& c, std::string& b, const SomMetaNode& node,
                   const std::string& basePath, int depth);

/* Writes the body region of a section heading: the section path's own content
 * value plus every transparent body slot (id-less content text and form
 * blocks, hoisted through transparent sections) in model order.
 *
 * A slot whose text the parser would otherwise bind elsewhere is preceded by a
 * slot marker (SOM §11.6): text after anything already written, a form
 * preamble that is not the region's default target, and a form whose labels
 * another form of the region shares. A body the parser reads correctly
 * without markers gets none, so such documents render as before. */
void writeSectionBody(MdCodec& c, std::string& b, const SomMetaNode& node,
                      const std::string& path) {
  const SpecDocument& doc = *c.document();
  std::vector<NodeRel> slots = bodySlots(c, node);
  if (slots.empty()) {
    bool present = false;
    std::string value = contentOf(doc, path, &present);
    if (present) {
      writeBody(b, value, path);
    }
    return;
  }
  std::vector<NodeRel> formSlots;
  for (const auto& s : slots) {
    if (kindEq(s.node->kind, kSomMetaKindForm)) {
      formSlots.push_back(s);
    }
  }
  const bool hasForms = !formSlots.empty();
  const std::string defRel = defaultBodyRel(slots);
  bool written = false;

  auto marker = [&b](const std::string& rel) {
    b += "<!-- slot: ";
    b += rel;
    b += " -->\n\n";
  };
  auto text = [&](const std::string& rel, const std::string& valuePath) {
    const std::string* value = doc.contentOpt(valuePath);
    if (value == nullptr) {
      return;
    }
    std::string prepared = prepareValue(*value, valuePath);
    if (prepared.empty()) {
      return;
    }
    if (written || rel != defRel) {
      marker(rel);
    }
    for (const auto& line : splitLines(prepared)) {
      if (hasForms && matchLabelShaped(line)) {
        b.push_back(' ');
      }
      b += line;
      b.push_back('\n');
    }
    b.push_back('\n');
    written = true;
  };

  text(".", path);
  for (const auto& slot : slots) {
    std::string slotPath = specPathJoin(path, slot.rel);
    const SomMetaNode* sn = slot.node;
    if (!kindEq(sn->kind, kSomMetaKindForm)) {
      text(slot.rel, slotPath);
      continue;
    }
    if (!formHasValues(doc, *sn, slotPath)) {
      continue;
    }
    const std::string* preamble = doc.contentOpt(slotPath);
    const bool hasPreamble =
        preamble != nullptr && !prepareValue(*preamble, slotPath).empty();
    std::set<std::string> labels;
    if (sn->form.has_value()) {
      for (const auto& f : sn->form->fields) {
        labels.insert(lowerDup(f.name));
      }
    }
    bool collides = false;
    for (const auto& o : formSlots) {
      if (o.rel == slot.rel || !o.node->form.has_value()) {
        continue;
      }
      for (const auto& f : o.node->form->fields) {
        if (labels.count(lowerDup(f.name)) != 0) {
          collides = true;
          break;
        }
      }
      if (collides) {
        break;
      }
    }
    const bool needsMarker =
        hasPreamble ? (written || slot.rel != defRel)
                    : (collides && (written || formSlots.front().rel != slot.rel));
    if (needsMarker) {
      marker(slot.rel);
    }
    writeForm(b, doc, *sn, slotPath);
    written = true;
  }
}

// Emits list `node` as its `-LST` container heading (SOM §11.2/§11.5) at `depth`,
// wrapping the numbered item headings one level deeper and their item-element
// children one level deeper again. The container is a real section — the id the
// generated schema keys its container type by — but carries no content of its own
// (schema content min/max-text-length 0). Item identity is purely positional.
void writeListItems(MdCodec& c, std::string& b, const SomMetaNode& node,
                    const std::string& listPath, int depth) {
  const SpecDocument& doc = *c.document();
  const std::vector<std::string>* items = doc.listItemsPtr(listPath);
  std::size_t n = items != nullptr ? items->size() : 0;
  if (n == 0) {
    return;
  }
  // The container heading: its id is the list's `-LST` @SectionId (else the
  // member segment for a pattern-less list); its title is the member name.
  mdWriteHeading(c, b, depth, headingIdOf(c, node),
                 headingTitle(c, listPath, node), listPath,
                 doc.codeSpec(listPath), doc.units(listPath));
  // Item heading stem. Complex lists derive it from the element class name
  // (SOM §11.5, `Entry` dropped). A scalar list (shape 6) has no element class —
  // its element typeName is literally `String`, which would render "String 1",
  // "String 2". Derive the stem from the list FIELD instead (its member name,
  // Title-Cased like the container heading) so a populated scalar list gets
  // meaningful per-item headings (YRC5). An element-class @Headline default
  // wins over both derivations (YRD4).
  const SomMetaNode* element = node.elementNode.get();
  std::string stem = mdItemStemOf(node);
  std::string pattern = node.sectionIdPattern;
  if (pattern.empty() && element != nullptr) {
    pattern = element->sectionIdPattern;
  }
  const std::string memberStem =
      !node.memberName.empty() ? node.memberName : node.segment();
  for (std::size_t i = 0; i < n; i++) {
    const std::string& itemPath = (*items)[i];
    long long pos = (long long)i + 1;
    // YRD3: an item's STORED section id IS its md heading
    // id — stored ids round-trip through Markdown too. Only anonymous items
    // fall back to the positional derivation: the `@SectionIdPattern`
    // resolved with the 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`),
    // else `<member>-<pos>` for a pattern-less list. Shared with the
    // instance-tier reference check, which must resolve `@sectionId`
    // references against exactly this id.
    std::string itemId = effectiveListItemSectionId(
        doc.itemSectionIdOpt(itemPath), pattern, pos, memberStem);
    // Items sit one level below the container. A stored headline overrides
    // the derived `<stem> <pos>` title (YRD3).
    std::string title = doc.headline(itemPath);
    if (title.empty()) {
      title = stem + " " + formatI64(pos);
    }
    mdWriteHeading(c, b, depth + 1, itemId, title, itemPath,
                   doc.codeSpec(itemPath), doc.units(itemPath));
    if (element == nullptr) {
      bool present = false;
      std::string v = contentOf(doc, itemPath, &present);
      writeBody(b, present ? v : std::string(), itemPath);
    } else {
      writeSectionBody(c, b, *element, itemPath);
      if (!element->recursive) {
        // Item-element children go one level deeper again.
        writeChildren(c, b, *element, itemPath, depth + 2);
      }
    }
  }
}

void writeChildren(MdCodec& c, std::string& b, const SomMetaNode& node,
                   const std::string& basePath, int depth) {
  const SpecDocument& doc = *c.document();
  std::vector<NodeRel> eff = effectiveChildren(c, node);
  for (const auto& nr : eff) {
    const SomMetaNode* child = nr.node;
    std::string path = specPathJoin(basePath, nr.rel);
    if (!doc.hasValuesUnder(path)) {
      continue;
    }
    const char* kind = child->kind;
    if (kindEq(kind, kSomMetaKindContent) || kindEq(kind, kSomMetaKindScalar) ||
        kindEq(kind, kSomMetaKindEnumValue)) {
      bool present = false;
      std::string value = contentOf(doc, path, &present);
      if (!present) {
        continue;
      }
      mdWriteHeading(c, b, depth, headingIdOf(c, *child),
                     headingTitle(c, path, *child), path, doc.codeSpec(path),
                     doc.units(path));
      writeBody(b, value, path);
    } else if (kindEq(kind, kSomMetaKindForm)) {
      if (!formHasValues(doc, *child, path)) {
        continue;
      }
      mdWriteHeading(c, b, depth, headingIdOf(c, *child),
                     headingTitle(c, path, *child), path, doc.codeSpec(path),
                     doc.units(path));
      writeForm(b, doc, *child, path);
    } else if (kindEq(kind, kSomMetaKindSection) ||
               kindEq(kind, kSomMetaKindComplex)) {
      mdWriteHeading(c, b, depth, headingIdOf(c, *child),
                     headingTitle(c, path, *child), path, doc.codeSpec(path),
                     doc.units(path));
      writeSectionBody(c, b, *child, path);
      writeChildren(c, b, *child, path, depth + 1);
    } else if (kindEq(kind, kSomMetaKindList)) {
      writeListItems(c, b, *child, path, depth);
    }
  }
}

std::string exportRootImpl(MdCodec& c, const SpecRoot& root) {
  std::string err;
  SomMetaTree* tree = c.treeFor(root.type, &err);
  if (tree == nullptr) {
    throw std::invalid_argument(err.empty() ? "failed to build metadata tree"
                                            : err);
  }
  const SomMetaNode* node = tree->root();
  std::string b;
  std::string kebab = kebabCase(root.title);
  std::string version =
      somModelVersionString(c.model().modelVersion, c.model().modelVersionLabel);
  b += "<!-- docspec: ";
  b += kebab;
  b.push_back('/');
  b += version;
  b += " -->\n";
  std::string rootSeg = node->segment();
  // YRD3: a stored headline overrides the derived title at every heading; the
  // root class's @Headline default (YRD4) sits between it and the root title.
  std::string rootTitle = c.document()->headline(rootSeg);
  if (rootTitle.empty()) {
    rootTitle = !node->headline.empty() ? node->headline : root.title;
  }
  mdWriteHeading(c, b, 1, rootSeg, rootTitle, rootSeg,
                 c.document()->codeSpec(rootSeg),
                 c.document()->units(rootSeg));
  writeSectionBody(c, b, *node, rootSeg);
  writeChildren(c, b, *node, rootSeg, 2);
  return b;
}

}  // namespace

std::string markdownExportRoot(const SpecModel& model,
                               const SpecDocument& document,
                               const SpecRoot& root) {
  MdCodec c(model, &document);
  return exportRootImpl(c, root);
}

namespace {

/* A heading line as mdWriteHeading writes it: `^#+ <!--\[`. Body text never
 * matches outside a fence — heading-like body lines are escaped (SOM §11.3). */
bool isEmittedHeading(const std::string& line) {
  std::size_t i = 0;
  while (i < line.size() && line[i] == '#') {
    i++;
  }
  return i > 0 && line.compare(i, 6, " <!--[") == 0;
}

}  // namespace

SpecMarkdownRendition markdownExportRootWithMap(const SpecModel& model,
                                                const SpecDocument& document,
                                                const SpecRoot& root) {
  std::vector<std::string> paths;
  MdCodec c(model, &document);
  c.headingPaths = &paths;
  SpecMarkdownRendition r;
  r.markdown = exportRootImpl(c, root);
  // Pair the recorded paths, in order, with the heading lines of the finished
  // text — fenced lines are body, never a heading.
  SpecMarkdownFenceTracker fence;
  std::size_t next = 0;
  int lineNo = 1;
  std::size_t pos = 0;
  const std::string& md = r.markdown;
  while (pos <= md.size() && next < paths.size()) {
    std::size_t nl = md.find('\n', pos);
    std::string line =
        md.substr(pos, nl == std::string::npos ? std::string::npos : nl - pos);
    if (!fence.inFence() && isEmittedHeading(line)) {
      r.headingPaths[lineNo] = std::move(paths[next++]);
    }
    fence.feed(line);
    if (nl == std::string::npos) {
      break;
    }
    pos = nl + 1;
    lineNo++;
  }
  return r;
}

const std::string* SpecMarkdownRendition::pathAtLine(int line) const {
  auto it = headingPaths.upper_bound(line);
  if (it == headingPaths.begin()) {
    return nullptr;
  }
  --it;
  return &it->second;
}

/* ======================================================================== */
/* Result accessors                                                          */
/* ======================================================================== */

std::size_t SpecMarkdownResult::appliedCount() const {
  std::size_t n = staged.content.size();
  for (const auto& kv : staged.forms) {
    n += kv.second.size();
  }
  return n;
}

std::string SpecMarkdownRejection::display() const {
  std::string b = "line " + formatI64((long long)line) + ": " + reason;
  if (!anchor.empty()) {
    b += " (";
    b += anchor;
    b.push_back(')');
  }
  b += " \xE2\x80\x94 ";  // U+2014 em-dash
  b += message;
  return b;
}

/* ======================================================================== */
/* Import (parse)                                                            */
/* ======================================================================== */

namespace {

/* mdListState: per-list bookkeeping while parsing. */
struct MdListState {
  std::string listPath;
  std::vector<std::string> items;                        // insertion order
  std::vector<std::pair<std::string, std::string>> ids;  // item path → stored id
  long long maxN = 0;
};

/* mdFrame: one open section. */
struct MdFrame {
  int level = 0;
  const SomMetaNode* node = nullptr;  // nullptr for ignored / unresolvable
  std::string path;                   // "" when ignored
  std::size_t line = 0;
  bool ignored = false;
  std::vector<std::string> body;
  // The scope this heading's descendants' anchors are qualified with, and the
  // id of the nearest heading at or above it that is no list container (SOM
  // §11.2, qualifyAnchor).
  std::optional<std::vector<std::string>> anchorScope;
  std::optional<std::string> anchorSection;
};

/* The qualified anchor of a heading `id` (SOM §11.2) and the scope its
 * descendants' anchors are qualified with: below a list item, or in a
 * `@SameAs` copy, an anchor is the ids from the scope's start joined by `/`;
 * elsewhere it is the id itself. `section` is the id of the nearest heading
 * above that is no list container. */
enum class AnchorKind { kPlain, kContainer, kItem, kCopy };

std::pair<std::string, std::optional<std::vector<std::string>>> qualifyAnchor(
    const std::optional<std::vector<std::string>>& scope,
    const std::optional<std::string>& section, const std::string& id,
    AnchorKind kind) {
  auto join = [](const std::vector<std::string>& parts) {
    std::string out;
    for (std::size_t i = 0; i < parts.size(); i++) {
      if (i > 0) out += "/";
      out += parts[i];
    }
    return out;
  };
  auto withId = [&id](std::vector<std::string> parts) {
    parts.push_back(id);
    return parts;
  };
  const std::string joined = scope.has_value() ? join(withId(*scope)) : id;
  switch (kind) {
    case AnchorKind::kContainer:
      return {joined, scope};
    case AnchorKind::kItem:
      return {joined, withId(scope.value_or(std::vector<std::string>{}))};
    case AnchorKind::kCopy: {
      std::vector<std::string> sc =
          scope.has_value()
              ? *scope
              : (section.has_value() ? std::vector<std::string>{*section}
                                     : std::vector<std::string>{});
      sc.push_back(id);
      return {join(sc), sc};
    }
    case AnchorKind::kPlain:
      break;
  }
  if (!scope.has_value()) return {joined, std::nullopt};
  return {joined, withId(*scope)};
}

/* The title with the renderer's anchor removed (DI-3): `<a id="X"></a>` at its
 * start, X the section id or its qualified anchor, then `<br>` as line
 * breaks (SOM §11.2). */
std::string titleWithoutAnchor(const std::string& raw, const std::string& id,
                               const std::string& anchor) {
  std::string t = raw;
  for (const std::string* a : {&id, &anchor}) {
    const std::string tag = "<a id=\"" + *a + "\"></a>";
    if (t.compare(0, tag.size(), tag) == 0) {
      std::size_t p = tag.size();
      while (p < t.size() && isWs(t[p])) {
        p++;
      }
      t = t.substr(p);
      break;
    }
  }
  return replaceAllStr(t, "<br>", "\n");
}

/* One table read off body lines: its header cells, the body rows with their
 * line indexes, and the index after it. */
struct MdTable {
  std::vector<std::string> header;
  std::vector<std::pair<std::size_t, std::vector<std::string>>> rows;
  std::size_t end = 0;
};

class MdParser {
 public:
  explicit MdParser(MdCodec& codec) : codec_(codec) {}

  void run(const std::string& text, SpecMarkdownResult& out);

 private:
  MdCodec& codec_;
  DocumentJson staged_;
  std::vector<SpecMarkdownRejection> rejections_;
  std::set<std::string> rootPrefixes_;
  std::vector<MdListState> lists_;  // first-seen order
  std::vector<MdFrame> stack_;
  int currentFormIdx_ = 0;
  // The fields given so far per form path, for the given-twice rule.
  std::map<std::string, std::set<std::string>> given_;

  const MdListState* findListState(const std::string& listPath) const {
    for (const auto& s : lists_) {
      if (s.listPath == listPath) {
        return &s;
      }
    }
    return nullptr;
  }

  /* The 1-based source line of `frame`'s body line `i`. */
  static std::size_t bodyLine(const MdFrame& frame, std::size_t i) {
    return frame.line + 1 + i;
  }

  MdTable readTable(const std::vector<std::string>& lines, std::size_t start,
                    const std::function<std::size_t(std::size_t)>& lineOf,
                    const std::string& anchor);
  bool givenTwice(const std::string& formPath, const std::string& field,
                  std::size_t line);
  void stageRow(const std::string& formPath,
                const std::vector<SomFormFieldMeta>& fields,
                const std::string& label, const std::string& cell,
                std::size_t line);
  void extractSectionTables(MdFrame& frame, const SomMetaNode& node);
  bool sectionTableTarget(const MdFrame& frame, const SomMetaNode& node,
                          const std::string& section, std::string* formPath,
                          std::vector<SomFormFieldMeta>* fields);
  void finalizeListBody(MdFrame& frame, const SomMetaNode& listNode);
  void stageReferenceLine(const MdFrame& frame, const SomMetaNode& listNode,
                          const std::vector<std::string>& inner,
                          std::size_t at);
  void stageRecordTable(const MdFrame& frame, const SomMetaNode& listNode,
                        const std::vector<std::string>& inner, std::size_t at);
  void itemIdentity(const SomMetaNode& listNode, const std::string& id,
                    long long* n, std::string* storedId, bool* hasN) const;
  bool isCopyNode(const SomMetaNode& n) const;

  void pushRejection(std::size_t line, const std::string& reason,
                     const std::string& message, const std::string& anchor) {
    SpecMarkdownRejection r;
    r.line = line;
    r.reason = reason;
    r.message = message;
    r.anchor = anchor;
    rejections_.push_back(std::move(r));
  }

  MdListState& listState(const std::string& listPath) {
    for (auto& s : lists_) {
      if (s.listPath == listPath) {
        return s;
      }
    }
    lists_.push_back(MdListState{});
    MdListState& s = lists_.back();
    s.listPath = listPath;
    return s;
  }

  void stagedSetContent(const std::string& path, const std::string& value) {
    staged_.content[path] = value;
  }
  void stagedSetForm(const std::string& formPath, const std::string& field,
                     const std::string& value) {
    staged_.forms[formPath][field] = value;
  }

  void pushIgnoredFrame(int level, std::size_t line) {
    MdFrame f;
    f.level = level;
    f.line = line;
    f.ignored = true;
    stack_.push_back(std::move(f));
  }

  void finalizeForm(MdFrame& frame, const SomMetaNode& node,
                    const std::string& path);
  void finalizeBodySlots(MdFrame& frame, const std::vector<NodeRel>& slots);
  void finalizeFrame(MdFrame& frame);
  void finalizeTop();
  void closeTo(int level);
  std::string openItem(int level, const std::string& listPath,
                       const SomMetaNode& listNode, long long n,
                       const std::string& storedId, bool hasN,
                       const std::string& title, const std::string& codeSpec,
                       const std::string& units, std::size_t line,
                       bool push = true);
  void openItemHeading(int level, const std::string& listPath,
                       const SomMetaNode& listNode, const std::string& id,
                       const std::string& title, const std::string& codeSpec,
                       const std::string& units, std::size_t line);
  void openHeading(int level, const std::string& rest, std::size_t line);
  void openRoot(int level, const std::string& id, const std::string& title,
                const std::string& codeSpec, const std::string& units,
                std::size_t line);
  void emitLists();
};

/* ---- restore value (parse-side) ----------------------------------------- */

std::string restoreValue(const std::vector<std::string>& body) {
  SpecMarkdownFenceTracker fence;
  std::string b;
  for (std::size_t i = 0; i < body.size(); i++) {
    const std::string& line = body[i];
    if (i > 0) {
      b.push_back('\n');
    }
    if (!fence.inFence() && matchEscapedHeading(line)) {
      b.append(line, 1, std::string::npos);
    } else if (!fence.inFence() && matchHeaderShaped(line, 1)) {
      b.append(line, 1, std::string::npos);  // DI-2: the emitter's escape space
    } else {
      b += line;
    }
    fence.feed(line);
  }
  return stripBlankLines(b);
}

/* ---- layout tables (SOM §11.4, §11.5) ------------------------------------ */

/* The cells of a table row: split on every `|` not preceded by a backslash,
 * the outer pipes dropped, each cell trimmed; `\|` stays in the cell. */
std::vector<std::string> rowCells(const std::string& line) {
  std::string t = trimSpace(line);
  if (!t.empty() && t[0] == '|') {
    t = t.substr(1);
  }
  if (!t.empty() && t.back() == '|' &&
      !(t.size() >= 2 && t[t.size() - 2] == '\\')) {
    t.pop_back();
  }
  std::vector<std::string> cells;
  std::string b;
  for (std::size_t i = 0; i < t.size(); i++) {
    char c = t[i];
    if (c == '\\' && i + 1 < t.size() && t[i + 1] == '|') {
      b += "\\|";
      i++;
    } else if (c == '|') {
      cells.push_back(trimSpace(b));
      b.clear();
    } else {
      b.push_back(c);
    }
  }
  cells.push_back(trimSpace(b));
  return cells;
}

std::string decodeCodeSpan(const std::string& value);

/* A cell's value for field `f`: `\|` unescaped, a reference field's links read
 * as their link texts, a `code` field's code span decoded. */
std::string cellValue(const std::string& cell, const SomFormFieldMeta& f) {
  std::string text = replaceAllStr(cell, "\\|", "|");
  std::vector<std::string> texts;
  if (!f.refersTo.empty() && !f.code && matchLinkCell(text, &texts)) {
    std::string out;
    for (std::size_t i = 0; i < texts.size(); i++) {
      if (i > 0) out += ", ";
      out += texts[i];
    }
    return out;
  }
  return f.code ? decodeCodeSpan(text) : text;
}

/* A cell's id with the renderer's anchor (`<a id="X"></a>X`) removed, and a
 * link the cell is read as its text (`[X](<file>#X)`, SOM §11.5). */
std::string cellId(const std::string& cell) {
  std::string id = cell;
  if (id.compare(0, 7, "<a id=\"") == 0) {
    std::size_t q = id.find('"', 7);
    if (q != std::string::npos && id.compare(q + 1, 5, "></a>") == 0) {
      std::size_t p = q + 6;
      while (p < id.size() && isWs(id[p])) {
        p++;
      }
      id = id.substr(p);
    }
  }
  // `^\[([^\]]+)\]\([^)\s]*\)$`
  if (!id.empty() && id[0] == '[') {
    std::size_t close = id.find(']');
    if (close != std::string::npos && close > 1 && close + 1 < id.size() &&
        id[close + 1] == '(' && id.back() == ')') {
      bool clean = true;
      for (std::size_t k = close + 2; k + 1 < id.size(); k++) {
        if (id[k] == ')' || isWs(id[k])) {
          clean = false;
          break;
        }
      }
      if (clean) return id.substr(1, close - 1);
    }
  }
  return id;
}

/* The inverse of the emitter's code span (SOM §11.4 rule 8): a single-line
 * `value` delimited by equal backtick runs loses them, and one padding space
 * on each side when both are present. Anything else — a value written by hand
 * without a span — is kept as written. */
std::string decodeCodeSpan(const std::string& value) {
  if (value.find('\n') != std::string::npos || value.empty()) {
    return value;
  }
  std::size_t lead = 0;
  while (lead < value.size() && value[lead] == '`') {
    lead++;
  }
  if (lead == 0 || lead == value.size()) {
    return value;
  }
  std::size_t trail = 0;
  while (trail < value.size() && value[value.size() - 1 - trail] == '`') {
    trail++;
  }
  // `^(`+)(.*[^`])(`+)$` with both runs taken greedily: the inner part is
  // what lies between the full leading and full trailing backtick runs.
  if (lead != trail) {
    return value;
  }
  std::string inner = value.substr(lead, value.size() - lead - trail);
  if (inner.size() >= 2 && inner.front() == ' ' && inner.back() == ' ' &&
      inner.find_first_not_of(' ') != std::string::npos) {
    return inner.substr(1, inner.size() - 2);
  }
  return inner;
}

/* Returns the model form field matching `label` (case-insensitive), or
 * nullptr. */
const SomFormFieldMeta* formFieldCi(const SomMetaNode& node,
                                    const std::string& label) {
  if (!node.form.has_value()) {
    return nullptr;
  }
  std::string lower = lowerDup(label);
  for (const auto& f : node.form->fields) {
    if (lowerDup(f.name) == lower) {
      return &f;
    }
  }
  return nullptr;
}

/* Parses an id-bearing `@Form` section's body: `FieldName:` paragraphs and
 * form-table rows bind to the named fields wherever they stand (SOM §11.4);
 * the text that belongs to no field — before the first field, or after a
 * table — is the form's preamble, its own content (rule 7). */
void MdParser::finalizeForm(MdFrame& frame, const SomMetaNode& node,
                            const std::string& path) {
  static const std::vector<SomFormFieldMeta> kNone;
  const std::vector<SomFormFieldMeta>& declared =
      node.form.has_value() ? node.form->fields : kNone;
  SpecMarkdownFenceTracker fence;
  const SomFormFieldMeta* currentField = nullptr;
  bool discard = false;
  std::vector<std::string> current;
  // The preamble's parts: the text before the first field, and text a table
  // interrupts; joined by one blank line.
  std::vector<std::vector<std::string>> preambleParts(1);

  auto flush = [&]() {
    if (currentField != nullptr && !discard) {
      std::string value = restoreValue(current);
      if (currentField->code) {
        value = decodeCodeSpan(value);
      }
      if (!value.empty()) {
        stagedSetForm(path, currentField->name, value);
      }
    }
    current.clear();
    discard = false;
  };

  for (std::size_t i = 0; i < frame.body.size(); i++) {
    const std::string& line = frame.body[i];
    if (!fence.inFence()) {
      bool isSection = false;
      if (matchLayoutTableHeader(line, &isSection) && !isSection) {
        flush();
        currentField = nullptr;
        preambleParts.emplace_back();
        MdTable table = readTable(
            frame.body, i,
            [&frame](std::size_t k) { return bodyLine(frame, k); }, path);
        for (const auto& row : table.rows) {
          stageRow(path, declared, row.second[0], row.second[1],
                   bodyLine(frame, row.first));
        }
        i = table.end - 1;
        continue;
      }
      std::string label, value;
      if (matchFieldLabel(line, &label, &value)) {
        const SomFormFieldMeta* field = formFieldCi(node, label);
        if (field != nullptr) {
          flush();
          currentField = field;
          discard = givenTwice(path, field->name, bodyLine(frame, i));
          current.push_back(value);
          fence.feed(line);
          continue;
        }
      }
    }
    // Continuation: strip the one escape space of a label-shaped line.
    std::vector<std::string>& target =
        currentField == nullptr ? preambleParts.back() : current;
    if (!fence.inFence() && matchContinuationLabel(line)) {
      target.push_back(line.substr(1));
    } else {
      target.push_back(line);
    }
    fence.feed(line);
  }
  flush();
  std::string preamble;
  for (const auto& part : preambleParts) {
    std::string v = restoreValue(part);
    if (v.empty()) continue;
    if (!preamble.empty()) preamble += "\n\n";
    preamble += v;
  }
  if (!preamble.empty()) {
    stagedSetContent(path, preamble);
  }
}

/* A slot marker line (SOM §11.6): exactly `<!-- slot: <rel> -->`, `<rel>` a
 * non-empty run of non-whitespace — a body slot's path relative to its owner,
 * or `.` for the owner itself. */
bool matchSlotMarker(const std::string& line, std::string* rel) {
  static const std::string open = "<!-- slot: ";
  static const std::string close = " -->";
  if (line.size() <= open.size() + close.size() ||
      line.compare(0, open.size(), open) != 0 ||
      line.compare(line.size() - close.size(), close.size(), close) != 0) {
    return false;
  }
  std::string r =
      line.substr(open.size(), line.size() - open.size() - close.size());
  for (char ch : r) {
    if (isWs(ch)) {
      return false;
    }
  }
  *rel = r;
  return true;
}

// Binds a heading's body region against the owner's transparent body slots
// (SOM §11.6): `FieldName:` lines matching a transparent form's fields route to
// that form (nearest form in slot order, wrapping); a slot marker
// (`<!-- slot: <rel> -->`) sends the text after it to the named slot — a
// content slot, a form's preamble, or the owner itself (`.`) — and ends any
// open field. Unmarked text binds to the first content slot; with no content
// slot it is a form's preamble (SOM §11.4 rule 7) — the class-level `@Form` on
// the `content` member, else the first form — and only an owner with no slot
// at all takes it on its own path. In a region with forms, every label-shaped
// text line has its one escape space stripped.
void MdParser::finalizeBodySlots(MdFrame& frame,
                                 const std::vector<NodeRel>& slots) {
  std::vector<NodeRel> forms;
  for (const auto& s : slots) {
    if (kindEq(s.node->kind, kSomMetaKindForm)) {
      forms.push_back(s);
    }
  }
  const std::string defRel = defaultBodyRel(slots);
  auto pathOf = [&frame](const std::string& rel) {
    return rel == "." ? frame.path : specPathJoin(frame.path, rel);
  };

  // Unlabelled text per target path, in the order the targets were opened; a
  // target opened twice gets its parts joined by a blank line.
  std::vector<std::pair<std::string, std::vector<std::vector<std::string>>>>
      textParts;
  auto openTarget = [&textParts](const std::string& target) {
    for (auto& e : textParts) {
      if (e.first == target) {
        e.second.emplace_back();
        return std::make_pair(&e - textParts.data(), e.second.size() - 1);
      }
    }
    textParts.push_back({target, {std::vector<std::string>()}});
    return std::make_pair(static_cast<std::ptrdiff_t>(textParts.size() - 1),
                          static_cast<std::size_t>(0));
  };
  auto cur = openTarget(pathOf(defRel));

  SpecMarkdownFenceTracker fence;
  const std::string* currentField = nullptr;
  bool currentCode = false;
  std::string currentFormPath;
  bool haveField = false;
  bool discard = false;
  std::vector<std::string> current;
  currentFormIdx_ = 0;

  auto flush = [&]() {
    if (haveField && !discard) {
      std::string v = restoreValue(current);
      if (currentCode) {
        v = decodeCodeSpan(v);
      }
      if (!v.empty()) {
        stagedSetForm(currentFormPath, *currentField, v);
      }
    }
    current.clear();
    discard = false;
  };

  // The nearest form at or after the last hit (wrapping) declaring `label`.
  auto findField = [&](const std::string& label, int* idx) {
    const SomFormFieldMeta* found = nullptr;
    std::string lower = lowerDup(label);
    for (std::size_t k = 0; k < forms.size() && found == nullptr; k++) {
      std::size_t at = ((std::size_t)currentFormIdx_ + k) % forms.size();
      const SomMetaNode* fn = forms[at].node;
      if (!fn->form.has_value()) {
        continue;
      }
      for (const auto& f : fn->form->fields) {
        if (lowerDup(f.name) == lower) {
          *idx = (int)at;
          found = &f;
          break;
        }
      }
    }
    return found;
  };

  for (std::size_t i = 0; i < frame.body.size(); i++) {
    const std::string& line = frame.body[i];
    if (!fence.inFence()) {
      std::string rel;
      if (matchSlotMarker(line, &rel)) {
        const NodeRel* slot = nullptr;
        if (rel != ".") {
          for (const auto& s : slots) {
            if (s.rel == rel) {
              slot = &s;
              break;
            }
          }
        }
        if (rel == "." || slot != nullptr) {
          flush();
          haveField = false;
          currentField = nullptr;
          currentFormPath.clear();
          if (slot != nullptr && kindEq(slot->node->kind, kSomMetaKindForm)) {
            for (std::size_t k = 0; k < forms.size(); k++) {
              if (forms[k].rel == slot->rel) {
                currentFormIdx_ = (int)k;
                break;
              }
            }
          }
          cur = openTarget(pathOf(rel));
          continue;
        }
      }
      bool isSection = false;
      if (!forms.empty() && matchLayoutTableHeader(line, &isSection) &&
          !isSection) {
        // A form table ends the open field (SOM §11.4); its rows bind like
        // `Field:` labels, each to the nearest form declaring it.
        flush();
        haveField = false;
        currentField = nullptr;
        currentFormPath.clear();
        MdTable table = readTable(
            frame.body, i,
            [&frame](std::size_t k) { return bodyLine(frame, k); }, frame.path);
        for (const auto& row : table.rows) {
          int idx = -1;
          const SomFormFieldMeta* hit = findField(row.second[0], &idx);
          if (hit == nullptr) {
            pushRejection(bodyLine(frame, row.first),
                          kSpecMarkdownRejectUnknownField,
                          "row \"" + row.second[0] +
                              "\" names no field of this form",
                          frame.path);
            continue;
          }
          currentFormIdx_ = idx;
          stageRow(specPathJoin(frame.path, forms[idx].rel), {*hit},
                   row.second[0], row.second[1], bodyLine(frame, row.first));
        }
        i = table.end - 1;
        continue;
      }
      std::string label, value;
      if (!forms.empty() && matchFieldLabel(line, &label, &value)) {
        int foundIdx = -1;
        const SomFormFieldMeta* found = findField(label, &foundIdx);
        if (found != nullptr) {
          flush();
          currentFormIdx_ = foundIdx;
          haveField = true;
          currentField = &found->name;
          currentCode = found->code;
          currentFormPath = specPathJoin(frame.path, forms[foundIdx].rel);
          discard = givenTwice(currentFormPath, *currentField,
                               bodyLine(frame, i));
          current.push_back(value);
          fence.feed(line);
          continue;
        }
      }
    }
    // In a region with forms every label-shaped text line carries the one
    // escape space the emitter adds (SOM §11.4 rule 3); strip it.
    std::string text = line;
    if (!fence.inFence() && !forms.empty() && matchContinuationLabel(line)) {
      text = line.substr(1);
    }
    if (haveField) {
      current.push_back(text);
    } else {
      textParts[cur.first].second[cur.second].push_back(text);
    }
    fence.feed(line);
  }
  flush();
  for (const auto& e : textParts) {
    std::string value;
    for (const auto& part : e.second) {
      std::string v = restoreValue(part);
      if (v.empty()) {
        continue;
      }
      if (!value.empty()) {
        value += "\n\n";
      }
      value += v;
    }
    if (!value.empty()) {
      stagedSetContent(e.first, value);
    }
  }
}

/* ---- layout tables (SOM §11.4, §11.5) ------------------------------------ */

/* Reads the table whose header is `lines[start]`; a broken delimiter row or a
 * row of another cell count is a malformedBlock. */
MdTable MdParser::readTable(
    const std::vector<std::string>& lines, std::size_t start,
    const std::function<std::size_t(std::size_t)>& lineOf,
    const std::string& anchor) {
  MdTable t;
  t.end = start + 1;
  while (t.end < lines.size() && matchTableLine(lines[t.end])) {
    t.end++;
  }
  t.header = rowCells(lines[start]);
  bool isDelimiter = false;
  std::vector<std::string> delimiter;
  if (start + 1 < t.end) {
    delimiter = rowCells(lines[start + 1]);
    isDelimiter = true;
    for (const auto& c : delimiter) {
      if (!matchDelimiterCell(c)) {
        isDelimiter = false;
        break;
      }
    }
  }
  if (!isDelimiter || delimiter.size() != t.header.size()) {
    pushRejection(lineOf(start), kSpecMarkdownRejectMalformedBlock,
                  !isDelimiter
                      ? "table without its delimiter row"
                      : "table whose delimiter row does not match its header",
                  anchor);
    return t;
  }
  for (std::size_t i = start + 2; i < t.end; i++) {
    std::vector<std::string> cells = rowCells(lines[i]);
    if (cells.size() != t.header.size()) {
      pushRejection(lineOf(i), kSpecMarkdownRejectMalformedBlock,
                    "table row with " + formatI64((long long)cells.size()) +
                        " cells, the header has " +
                        formatI64((long long)t.header.size()),
                    anchor);
      continue;
    }
    t.rows.emplace_back(i, std::move(cells));
  }
  return t;
}

/* Whether `field` of the form at `formPath` was given before; reports the
 * repeat (malformedBlock, the first occurrence kept) when it was. */
bool MdParser::givenTwice(const std::string& formPath, const std::string& field,
                          std::size_t line) {
  std::set<std::string>& given = given_[formPath];
  if (given.insert(field).second) {
    return false;
  }
  pushRejection(line, kSpecMarkdownRejectMalformedBlock,
                "field \"" + field + "\" given twice", formPath);
  return true;
}

/* Stages one row of a form table (or a section table). */
void MdParser::stageRow(const std::string& formPath,
                        const std::vector<SomFormFieldMeta>& fields,
                        const std::string& label, const std::string& cell,
                        std::size_t line) {
  const std::string lower = lowerDup(label);
  const SomFormFieldMeta* f = nullptr;
  for (const auto& x : fields) {
    if (lowerDup(x.name) == lower) {
      f = &x;
      break;
    }
  }
  if (f == nullptr) {
    pushRejection(line, kSpecMarkdownRejectUnknownField,
                  "row \"" + label + "\" names no field of this form",
                  formPath);
    return;
  }
  std::string value = cellValue(cell, *f);
  if (value.empty()) return;
  if (givenTwice(formPath, f->name, line)) return;
  stagedSetForm(formPath, f->name, value);
}

/* Reads and removes every section table of `frame`'s body (SOM §11.5). */
void MdParser::extractSectionTables(MdFrame& frame, const SomMetaNode& node) {
  std::vector<std::string>& body = frame.body;
  SpecMarkdownFenceTracker fence;
  for (std::size_t i = 0; i < body.size(); i++) {
    const std::string line = body[i];
    bool isSection = false;
    if (fence.inFence() || !matchLayoutTableHeader(line, &isSection) ||
        !isSection) {
      fence.feed(line);
      continue;
    }
    MdTable table = readTable(
        body, i, [&frame](std::size_t k) { return bodyLine(frame, k); },
        frame.path);
    std::string formPath;
    bool haveTarget = false;
    std::vector<SomFormFieldMeta> fields;
    bool skip = false;
    for (const auto& row : table.rows) {
      const std::vector<std::string>& cells = row.second;
      const std::size_t lineNo = bodyLine(frame, row.first);
      const std::string section = cellId(cells[0]);
      if (section.empty() && skip) continue;
      if (!section.empty()) {
        haveTarget =
            sectionTableTarget(frame, node, section, &formPath, &fields);
        skip = !haveTarget;
        if (!haveTarget) {
          pushRejection(lineNo, kSpecMarkdownRejectUnknownSection,
                        "section-table row names no child section of \"" +
                            frame.path + "\"",
                        section);
          continue;
        }
      } else if (!haveTarget) {
        pushRejection(lineNo, kSpecMarkdownRejectUnknownSection,
                      "section-table row names no section", frame.path);
        continue;
      }
      if (skip) continue;
      stageRow(formPath, fields, cells[1], cells[2], lineNo);
    }
    for (std::size_t k = i; k < table.end; k++) {
      body[k].clear();
    }
    i = table.end - 1;
  }
}

/* The item class's own form (its class-level `@Form`, a transparent body
 * slot), or nullptr when the class carries none or more than one. */
const NodeRel* itemForm(MdCodec& c, const SomMetaNode& element,
                        std::vector<NodeRel>* slots) {
  *slots = bodySlots(c, element);
  const NodeRel* form = nullptr;
  for (const auto& s : *slots) {
    if (kindEq(s.node->kind, kSomMetaKindForm)) {
      if (form != nullptr) return nullptr;
      form = &s;
    }
  }
  return form;
}

/* The form a section-table `Section` cell names under `node`. */
bool MdParser::sectionTableTarget(const MdFrame& frame, const SomMetaNode& node,
                                  const std::string& section,
                                  std::string* formPath,
                                  std::vector<SomFormFieldMeta>* fields) {
  // `section.split(/\s*\/\s*/)`
  std::vector<std::string> parts;
  {
    std::string b;
    for (char ch : section) {
      if (ch == '/') {
        parts.push_back(trimSpace(b));
        b.clear();
      } else {
        b.push_back(ch);
      }
    }
    parts.push_back(trimSpace(b));
  }
  for (const auto& nr : effectiveChildren(codec_, node)) {
    const SomMetaNode& child = *nr.node;
    const std::string childId = headingIdOf(codec_, child);
    if (parts.size() == 1 && kindEq(child.kind, kSomMetaKindForm) &&
        childId == section) {
      *formPath = specPathJoin(frame.path, nr.rel);
      *fields = child.form.has_value() ? child.form->fields
                                       : std::vector<SomFormFieldMeta>{};
      return true;
    }
    if (parts.size() == 2 && kindEq(child.kind, kSomMetaKindList) &&
        childId == parts[0]) {
      const SomMetaNode* element = child.elementNode.get();
      std::vector<NodeRel> slots;
      const NodeRel* form =
          element != nullptr ? itemForm(codec_, *element, &slots) : nullptr;
      if (form == nullptr) return false;
      long long n = 0;
      std::string storedId;
      bool hasN = false;
      itemIdentity(child, parts[1], &n, &storedId, &hasN);
      const std::string listPath = specPathJoin(frame.path, nr.rel);
      std::string itemPath;
      if (const MdListState* state = findListState(listPath)) {
        for (const auto& p : state->items) {
          std::string key = p.substr(listPath.size() + 1);
          for (const auto& kv : state->ids) {
            if (kv.first == p) {
              key = kv.second;
              break;
            }
          }
          if (key == parts[1]) {
            itemPath = p;
            break;
          }
        }
      }
      if (itemPath.empty()) {
        itemPath = openItem(0, listPath, child, n, storedId, hasN, "", "", "",
                            frame.line, false);
      }
      *formPath = specPathJoin(itemPath, form->rel);
      *fields = form->node->form.has_value() ? form->node->form->fields
                                             : std::vector<SomFormFieldMeta>{};
      return true;
    }
  }
  return false;
}

/* ---- list bodies: `refs` and `records` (SOM §11.5) ----------------------- */

/* A list container's body: one `refs` or `records` div stands for its
 * items. */
void MdParser::finalizeListBody(MdFrame& frame, const SomMetaNode& listNode) {
  std::vector<std::string>& body = frame.body;
  SpecMarkdownFenceTracker fence;
  for (std::size_t i = 0; i < body.size(); i++) {
    const std::string line = body[i];
    std::string kind;
    if (fence.inFence() || !matchListDivOpen(line, &kind)) {
      fence.feed(line);
      continue;
    }
    std::size_t close = std::string::npos;
    for (std::size_t k = i + 1; k < body.size(); k++) {
      if (matchDivCloseLine(body[k])) {
        close = k;
        break;
      }
    }
    if (close == std::string::npos) {
      // The fence's lines read as text.
      pushRejection(bodyLine(frame, i), kSpecMarkdownRejectMalformedBlock,
                    "unclosed " + kind + " fence", frame.path);
      return;
    }
    bool besideText = false;
    for (std::size_t k = 0; k < body.size(); k++) {
      if ((k < i || k > close) && !trimSpace(body[k]).empty()) {
        besideText = true;
      }
    }
    const MdListState* state = findListState(frame.path);
    const bool hasItems = state != nullptr && !state->items.empty();
    if (besideText || hasItems) {
      pushRejection(bodyLine(frame, i), kSpecMarkdownRejectMalformedBlock,
                    "a " + kind + " div beside " +
                        (hasItems ? "item headings" : "other text") +
                        " in a list container",
                    frame.path);
      for (std::size_t k = i; k <= close; k++) body[k].clear();
      return;
    }
    std::vector<std::string> inner(body.begin() + i + 1, body.begin() + close);
    if (kind == "refs") {
      stageReferenceLine(frame, listNode, inner, i);
    } else {
      stageRecordTable(frame, listNode, inner, i);
    }
    for (std::size_t k = i; k <= close; k++) body[k].clear();
    return;
  }
}

/* The reference field of `element`'s items, with the rel of its form. */
bool referenceField(MdCodec& c, const SomMetaNode& element, std::string* rel,
                    const SomFormFieldMeta** field) {
  auto isRef = [](const SomMetaNode& n) {
    if (!kindEq(n.kind, kSomMetaKindForm) || !n.form.has_value() ||
        n.form->fields.size() != 1 || n.form->fields[0].refersTo.empty()) {
      return false;
    }
    for (const auto& e : n.extra) {
      if (e.annotation == "Reference") return true;
    }
    return false;
  };
  for (const auto& s : bodySlots(c, element)) {
    if (isRef(*s.node)) {
      *rel = s.rel;
      *field = &s.node->form->fields[0];
      return true;
    }
  }
  for (const auto& s : effectiveChildren(c, element)) {
    if (isRef(*s.node)) {
      *rel = s.rel;
      *field = &s.node->form->fields[0];
      return true;
    }
  }
  return false;
}

/* A `refs` div: ids split on commas and whitespace, links read as their
 * texts. */
void MdParser::stageReferenceLine(const MdFrame& frame,
                                  const SomMetaNode& listNode,
                                  const std::vector<std::string>& inner,
                                  std::size_t at) {
  const SomMetaNode* element = listNode.elementNode.get();
  std::string rel;
  const SomFormFieldMeta* field = nullptr;
  if (element == nullptr || !referenceField(codec_, *element, &rel, &field)) {
    pushRejection(bodyLine(frame, at), kSpecMarkdownRejectMalformedBlock,
                  "a refs div in a list whose items are not references",
                  frame.path);
    return;
  }
  std::vector<std::string> ids;
  {
    std::string joined;
    for (std::size_t k = 0; k < inner.size(); k++) {
      if (k > 0) joined.push_back(' ');
      joined += inner[k];
    }
    std::string b;
    auto take = [&]() {
      if (b.empty()) return;
      std::string text;
      ids.push_back(findLinkText(b, &text) ? text : b);
      b.clear();
    };
    for (char ch : joined) {
      if (ch == ',' || isWs(ch)) {
        take();
      } else {
        b.push_back(ch);
      }
    }
    take();
  }
  if (ids.empty()) {
    pushRejection(bodyLine(frame, at), kSpecMarkdownRejectMissingValue,
                  "an empty refs div", frame.path);
    return;
  }
  std::string pattern = listNode.sectionIdPattern;
  if (pattern.empty() && element != nullptr) {
    pattern = element->sectionIdPattern;
  }
  const std::string member =
      !listNode.memberName.empty() ? listNode.memberName : listNode.segment();
  for (std::size_t n = 1; n <= ids.size(); n++) {
    const std::string positional =
        effectiveListItemSectionId(nullptr, pattern, (long long)n, member);
    long long number = 0;
    std::string storedId;
    bool hasN = false;
    itemIdentity(listNode, positional, &number, &storedId, &hasN);
    const std::string itemPath = openItem(0, frame.path, listNode, number,
                                          storedId, hasN, "", "", "",
                                          frame.line, false);
    const std::string formPath =
        rel == "." ? itemPath : specPathJoin(itemPath, rel);
    stagedSetForm(formPath, field->name, ids[n - 1]);
  }
}

/* A `records` div: one table, `Id` first, `Title` optionally second. */
void MdParser::stageRecordTable(const MdFrame& frame,
                                const SomMetaNode& listNode,
                                const std::vector<std::string>& inner,
                                std::size_t at) {
  auto lineOf = [&frame, at](std::size_t k) {
    return bodyLine(frame, at + 1 + k);
  };
  auto reject = [&](const std::string& message) {
    pushRejection(bodyLine(frame, at), kSpecMarkdownRejectMalformedBlock,
                  message, frame.path);
  };
  std::size_t start = 0;
  while (start < inner.size() && trimSpace(inner[start]).empty()) {
    start++;
  }
  if (start >= inner.size() || !matchTableLine(inner[start])) {
    reject("a records div holding no table");
    return;
  }
  const std::vector<std::string> header = rowCells(inner[start]);
  if (header[0] != "Id") {
    reject("a records table whose first column is not Id");
    return;
  }
  const SomMetaNode* element = listNode.elementNode.get();
  std::vector<NodeRel> slots;
  const NodeRel* form =
      element != nullptr ? itemForm(codec_, *element, &slots) : nullptr;
  if (form == nullptr) {
    reject("a records div in a list whose items have no single form");
    return;
  }
  static const std::vector<SomFormFieldMeta> kNone;
  const std::vector<SomFormFieldMeta>& fields =
      form->node->form.has_value() ? form->node->form->fields : kNone;
  const bool withTitle = header.size() > 1 && header[1] == "Title";
  std::vector<const SomFormFieldMeta*> columns;
  for (std::size_t h = withTitle ? 2 : 1; h < header.size(); h++) {
    const std::string lower = lowerDup(header[h]);
    const SomFormFieldMeta* f = nullptr;
    for (const auto& x : fields) {
      if (lowerDup(x.name) == lower) {
        f = &x;
        break;
      }
    }
    if (f == nullptr) {
      // The table is skipped whole.
      pushRejection(lineOf(start), kSpecMarkdownRejectUnknownField,
                    "records column \"" + header[h] +
                        "\" names no field of the items",
                    frame.path);
      return;
    }
    columns.push_back(f);
  }
  MdTable table = readTable(inner, start, lineOf, frame.path);
  for (const auto& row : table.rows) {
    const std::vector<std::string>& cells = row.second;
    long long n = 0;
    std::string storedId;
    bool hasN = false;
    itemIdentity(listNode, cellId(cells[0]), &n, &storedId, &hasN);
    const std::string title =
        withTitle ? replaceAllStr(replaceAllStr(cells[1], "\\|", "|"), "<br>",
                                  "\n")
                  : std::string();
    // openItem stages a title that differs from the `<stem> <n>` default.
    const std::string itemPath = openItem(0, frame.path, listNode, n, storedId,
                                          hasN, title, "", "",
                                          lineOf(row.first), false);
    const std::string formPath = specPathJoin(itemPath, form->rel);
    for (std::size_t c = 0; c < columns.size(); c++) {
      std::string value =
          cellValue(cells[(withTitle ? 2 : 1) + c], *columns[c]);
      if (value.empty()) continue;
      stagedSetForm(formPath, columns[c]->name, value);
    }
  }
}

void MdParser::finalizeFrame(MdFrame& frame) {
  if (frame.ignored) {
    return;
  }
  const SomMetaNode* node = frame.node;
  if (node != nullptr && kindEq(node->kind, kSomMetaKindForm)) {
    finalizeForm(frame, *node, frame.path);
    return;
  }
  if (node != nullptr && kindEq(node->kind, kSomMetaKindList)) {
    finalizeListBody(frame, *node);
  } else if (node != nullptr && (kindEq(node->kind, kSomMetaKindSection) ||
                                 kindEq(node->kind, kSomMetaKindComplex))) {
    extractSectionTables(frame, *node);
  }
  std::vector<NodeRel> slots;
  if (node != nullptr) {
    slots = bodySlots(codec_, *node);
  }
  if (slots.empty()) {
    std::string value = restoreValue(frame.body);
    if (!value.empty()) {
      stagedSetContent(frame.path, value);
    } else if (node != nullptr && isValueLeaf(node->kind)) {
      pushRejection(frame.line, kSpecMarkdownRejectMissingValue,
                    "no value text under this section heading", frame.path);
    }
    return;
  }
  finalizeBodySlots(frame, slots);
}

void MdParser::finalizeTop() {
  finalizeFrame(stack_.back());
  stack_.pop_back();
}

void MdParser::closeTo(int level) {
  while (!stack_.empty() && stack_.back().level >= level) {
    finalizeTop();
  }
}

std::string MdParser::openItem(int level, const std::string& listPath,
                               const SomMetaNode& listNode, long long n,
                               const std::string& storedId, bool hasN,
                               const std::string& title,
                               const std::string& codeSpec,
                               const std::string& units, std::size_t line,
                               bool push) {
  MdListState& state = listState(listPath);
  long long number = n;
  if (!hasN) {
    number = state.maxN + 1;
  }
  if (number > state.maxN) {
    state.maxN = number;
  }
  std::string itemPath = listPath + "-" + formatI64(number);
  state.items.push_back(itemPath);
  // A stored id is staged for an anonymous next item and for a numbered
  // `@SectionIdPattern` id; the `<member>-<n>` fallback passes "" and stores
  // nothing.
  if (!hasN || !storedId.empty()) {
    state.ids.push_back({itemPath, storedId});
  }
  // SOM §11.7: stage a non-default item heading text against the effective
  // `<stem> <pos>` default (YRD4: element-class @Headline wins in the stem).
  std::string stem = mdItemStemOf(listNode);
  if (!title.empty() && title != stem + " " + formatI64(number)) {
    staged_.headlines[itemPath] = title;
  }
  // codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever present
  // (no default).
  if (!codeSpec.empty()) {
    staged_.codeSpecs[itemPath] = codeSpec;
  }
  // SOM §11.2: `units` is staged exactly like codeSpec.
  if (!units.empty()) {
    staged_.units[itemPath] = units;
  }
  if (push) {
    MdFrame f;
    f.level = level;
    f.node = listNode.elementNode.get();
    f.path = itemPath;
    f.line = line;
    f.ignored = false;
    stack_.push_back(std::move(f));
  }
  return itemPath;
}

/* Anonymous member id: `^<member>-([0-9]+)$`. */
bool anonMemberMatch(const std::string& member, const std::string& id,
                     long long* num) {
  std::size_t ml = member.size();
  if (id.size() <= ml || id.compare(0, ml, member) != 0 || id[ml] != '-') {
    return false;
  }
  std::string tail = id.substr(ml + 1);
  if (!isAllDigits(tail)) {
    return false;
  }
  auto v = parseI64(tail);
  if (!v.has_value()) {
    return false;
  }
  *num = *v;
  return true;
}

/* Numbered pattern id: parts[0] <digits> parts[1] → item n. */
bool numberedPatternMatch(const std::string& pattern, const std::string& id,
                          long long* num) {
  std::size_t xxx = pattern.find("xxx");
  if (xxx == std::string::npos) {
    return false;
  }
  if (pattern.find("xxx", xxx + 3) != std::string::npos) {
    return false;  // require exactly one "xxx"
  }
  std::size_t preLen = xxx;
  std::string post = pattern.substr(xxx + 3);
  std::size_t postLen = post.size();
  if (id.size() < preLen || id.compare(0, preLen, pattern, 0, preLen) != 0) {
    return false;
  }
  if (id.size() < preLen + postLen) {
    return false;
  }
  if (id.compare(id.size() - postLen, postLen, post) != 0) {
    return false;
  }
  std::size_t digitsLen = id.size() - preLen - postLen;
  if (digitsLen == 0) {
    return false;
  }
  std::string digits = id.substr(preLen, digitsLen);
  for (char c : digits) {
    if (!isDigit(c)) {
      return false;
    }
  }
  auto v = parseI64(digits);
  if (!v.has_value()) {
    return false;
  }
  *num = *v;
  return true;
}

// Opens a list-item frame under a `-LST` container frame (SOM §11.2). The
// heading [id] is matched positionally against the container's list: the
// `<member>-<n>` fallback id (positional, nothing stored), the
// `@SectionIdPattern` resolved with a number (`GOAL-ITEM-3`, parses back as
// item <n> carrying that id), a pattern-shaped stored id, or — for any other
// id — an anonymous next item carrying the stored id.
void MdParser::openItemHeading(int level, const std::string& listPath,
                               const SomMetaNode& listNode,
                               const std::string& id, const std::string& title,
                               const std::string& codeSpec,
                               const std::string& units, std::size_t line) {
  long long n = 0;
  std::string storedId;
  bool hasN = false;
  itemIdentity(listNode, id, &n, &storedId, &hasN);
  openItem(level, listPath, listNode, n, storedId, hasN, title, codeSpec, units,
           line);
}

// How an item `id` of `listNode` is read, as a heading's, a records row's or a
// section-table row's: the item number it names (`*hasN`; else the next free
// one) and the id it stores ("" for none). The `<member>-<n>` fallback id is
// positional and stores nothing; the `@SectionIdPattern` resolved with a
// number names item <n> and is stored, the section id being the item's
// identity and the path only its position (SOM §11.6); any other id is the
// next item, carrying it (YRD3).
void MdParser::itemIdentity(const SomMetaNode& listNode, const std::string& id,
                            long long* n, std::string* storedId,
                            bool* hasN) const {
  std::string member =
      !listNode.memberName.empty() ? listNode.memberName : listNode.segment();
  *n = 0;
  storedId->clear();
  *hasN = false;
  if (anonMemberMatch(member, id, n)) {
    *hasN = true;
    return;
  }
  const SomMetaNode* element = listNode.elementNode.get();
  std::string pattern = listNode.sectionIdPattern;
  if (pattern.empty() && element != nullptr) {
    pattern = element->sectionIdPattern;
  }
  long long num = 0;
  if (!pattern.empty() && numberedPatternMatch(pattern, id, &num)) {
    *n = num;
    *storedId = id;
    *hasN = true;
    return;
  }
  *storedId = id;
}

/* Whether `n` is a `@SameAs` copy (SOM §11.2): its anchor and its
 * descendants' are qualified with the section above it. */
bool MdParser::isCopyNode(const SomMetaNode& n) const {
  if (n.memberName.empty() || n.parent == nullptr) {
    return false;
  }
  const SpecClass* cls = codec_.model().classNamed(n.parent->className);
  const SpecField* f = cls != nullptr ? cls->fieldNamed(n.memberName) : nullptr;
  if (f == nullptr) {
    return false;
  }
  for (const auto& a : f->annotations) {
    if (a.name == "SameAs") {
      return true;
    }
  }
  return false;
}

void MdParser::openHeading(int level, const std::string& rest,
                           std::size_t line) {
  std::string trimmed = trimSpace(rest);
  std::string id;
  std::string region;
  std::string title;
  if (!matchHeadlineComment(trimmed, &id, &region, &title)) {
    pushRejection(line, kSpecMarkdownRejectMalformedHeading,
                  "heading carries no <!--[SECTION-ID]--> headline comment",
                  trimmed);
    pushIgnoredFrame(level, line);
    return;
  }
  // Reading view (DI-3): an anchor equal to the section id after the id
  // comment, or to its qualified form (SOM §11.2), is the renderer's, not part
  // of the title; a `<br>` in a heading title is a stored line break.
  const std::string rawTitle = title;
  title = titleWithoutAnchor(rawTitle, id, id);
  // codespecs_mapping.md §9.2: the codeSpec mapping parsed from the heading
  // comment's key=value region, "" when the heading carries no `codeSpec` key.
  std::string codeSpec = markdownCodeSpecOf(region);
  // SOM §11.2: the generation units, "" when the heading carries no `units`.
  std::string units = markdownUnitsOf(region);

  if (stack_.empty()) {
    openRoot(level, id, title, codeSpec, units, line);
    return;
  }

  if (stack_.back().ignored) {
    pushRejection(line, kSpecMarkdownRejectUnknownSection,
                  "section nested under an unresolvable parent", id);
    pushIgnoredFrame(level, line);
    return;
  }
  const SomMetaNode* pNode = stack_.back().node;
  if (pNode == nullptr || isValueLeaf(pNode->kind)) {
    pushRejection(line, kSpecMarkdownRejectKindMismatch,
                  "child heading under a value-leaf or form section", id);
    pushIgnoredFrame(level, line);
    return;
  }

  std::string parentPath = stack_.back().path;  // stable across pushes

  // 1. Under a `-LST` container frame (SOM §11.2), every child heading is one of
  //    that list's items — resolved positionally, not by the schema tree.
  if (kindEq(pNode->kind, kSomMetaKindList)) {
    auto q = qualifyAnchor(stack_.back().anchorScope,
                           stack_.back().anchorSection, id, AnchorKind::kItem);
    openItemHeading(level, parentPath, *pNode, id,
                    titleWithoutAnchor(rawTitle, id, q.first), codeSpec, units,
                    line);
    stack_.back().anchorScope = q.second;
    stack_.back().anchorSection = id;
    return;
  }

  // 2. A regular (non-list) or list-**container** effective child whose heading
  //    id matches. A list heads its `-LST` container here; its items are
  //    resolved above once the container frame is open.
  std::vector<NodeRel> eff = effectiveChildren(codec_, *pNode);
  bool handled = false;
  for (const auto& nr : eff) {
    const SomMetaNode* en = nr.node;
    if (headingIdOf(codec_, *en) == id) {
      std::string path = specPathJoin(parentPath, nr.rel);
      const bool container = kindEq(en->kind, kSomMetaKindList);
      auto q = qualifyAnchor(
          stack_.back().anchorScope, stack_.back().anchorSection, id,
          container ? AnchorKind::kContainer
                    : (isCopyNode(*en) ? AnchorKind::kCopy : AnchorKind::kPlain));
      std::optional<std::string> parentSection = stack_.back().anchorSection;
      const std::string title = titleWithoutAnchor(rawTitle, id, q.first);
      // SOM §11.7: stage the heading text as a stored headline ONLY when it
      // differs from the derived default (byte-stability).
      if (!title.empty() && title != mdTitleOf(*en)) {
        staged_.headlines[path] = title;
      }
      // codespecs_mapping.md §9.2: stage the codeSpec mapping whenever present
      // (no default).
      if (!codeSpec.empty()) {
        staged_.codeSpecs[path] = codeSpec;
      }
      // SOM §11.2: `units` is staged exactly like codeSpec.
      if (!units.empty()) {
        staged_.units[path] = units;
      }
      MdFrame f;
      f.level = level;
      f.node = en;
      f.path = path;
      f.line = line;
      f.ignored = false;
      f.anchorScope = q.second;
      f.anchorSection = container ? parentSection : std::optional<std::string>(id);
      stack_.push_back(std::move(f));
      handled = true;
      break;
    }
  }
  if (handled) {
    return;
  }

  if (!handled) {
    std::string msg =
        "section id does not resolve against the schema tree at this position "
        "(under \"" +
        parentPath + "\")";
    pushRejection(line, kSpecMarkdownRejectUnknownSection, msg, id);
    pushIgnoredFrame(level, line);
  }
}

void MdParser::openRoot(int level, const std::string& id,
                        const std::string& title, const std::string& codeSpec,
                        const std::string& units, std::size_t line) {
  const SpecModel& model = codec_.model();
  for (const auto& root : model.roots) {
    std::string seg = !root.sectionId.empty() ? root.sectionId : root.type;
    if (seg == id) {
      std::string err;
      SomMetaTree* tree = codec_.treeFor(root.type, &err);
      if (tree == nullptr) {
        break;
      }
      // SOM §11.7: stage a non-default root heading text — "non-default"
      // relative to the effective default (YRD4: `@Headline` default, else
      // the `@Document` title).
      const std::string& rootDefault = !tree->root()->headline.empty()
                                           ? tree->root()->headline
                                           : root.title;
      if (!title.empty() && title != rootDefault) {
        staged_.headlines[seg] = title;
      }
      // codespecs_mapping.md §9.2: stage the root codeSpec mapping whenever
      // present (no default).
      if (!codeSpec.empty()) {
        staged_.codeSpecs[seg] = codeSpec;
      }
      // SOM §11.2: `units` is staged exactly like codeSpec.
      if (!units.empty()) {
        staged_.units[seg] = units;
      }
      rootPrefixes_.insert(seg);
      MdFrame f;
      f.level = level;
      f.node = tree->root();
      f.path = seg;
      f.line = line;
      f.ignored = false;
      f.anchorSection = seg;
      stack_.push_back(std::move(f));
      return;
    }
  }
  std::string known;
  for (std::size_t i = 0; i < model.roots.size(); i++) {
    const SpecRoot& r = model.roots[i];
    std::string seg = !r.sectionId.empty() ? r.sectionId : r.type;
    if (i > 0) {
      known += ", ";
    }
    known += seg;
  }
  std::string msg =
      "no document root with this section id (known: " + known + ")";
  pushRejection(line, kSpecMarkdownRejectUnknownSection, msg, id);
  pushIgnoredFrame(level, line);
}

void MdParser::emitLists() {
  for (const auto& s : lists_) {
    DocListEntry& e = staged_.lists[s.listPath];
    e.seq = s.maxN;
    e.items = s.items;
    for (const auto& kv : s.ids) {
      e.ids[kv.first] = kv.second;
    }
  }
}

void MdParser::run(const std::string& text, SpecMarkdownResult& out) {
  SpecMarkdownFenceTracker fence;
  std::vector<std::string> lines = splitLines(text);

  for (std::size_t i = 0; i < lines.size(); i++) {
    const std::string& raw = lines[i];
    std::size_t lineNo = i + 1;
    std::string trimmed = stripTrailingWs(raw);

    if (!fence.inFence()) {
      if (stack_.empty() && isDocspecComment(trimmed)) {
        continue;  // SOM §11.1 header
      }
      int level = 0;
      std::string rest;
      if (matchHeadingLine(trimmed, &level, &rest)) {
        closeTo(level);
        openHeading(level, rest, lineNo);
        continue;
      }
    }
    if (!stack_.empty()) {
      stack_.back().body.push_back(raw);
    } else if (!trimmed.empty()) {
      pushRejection(lineNo, kSpecMarkdownRejectOrphanContent,
                    "text before the document root heading", "");
    }
    fence.feed(raw);
  }
  closeTo(1);
  if (!stack_.empty()) {
    finalizeTop();
  }

  emitLists();

  out.staged = std::move(staged_);
  out.rejections = std::move(rejections_);
  out.rootPrefixes = std::move(rootPrefixes_);
}

}  // namespace

SpecMarkdownResult markdownParse(const SpecModel& model,
                                 const std::string& text) {
  MdCodec codec(model, nullptr);
  MdParser parser(codec);
  SpecMarkdownResult out;
  parser.run(text, out);
  return out;
}

/* ======================================================================== */
/* SpecDocument.ToMarkdown (one-line export, SOM §21)                        */
/* ======================================================================== */

namespace {

const SpecRoot* singlePopulatedRoot(const SpecModel& model,
                                    const SpecDocument& document,
                                    std::string* errMsg) {
  const SpecRoot* found = nullptr;
  std::size_t count = 0;
  for (const auto& r : model.roots) {
    std::string seg = !r.sectionId.empty() ? r.sectionId : r.type;
    if (document.hasValuesUnder(seg)) {
      count++;
      if (found == nullptr) {
        found = &r;
      }
    }
  }
  if (count == 1) {
    return found;
  }
  if (count == 0) {
    *errMsg =
        "document has no populated root to export; pass root_type to choose "
        "one";
  } else {
    std::string b = "document has " + formatI64((long long)count) +
                    " populated roots (";
    bool first = true;
    for (const auto& r : model.roots) {
      std::string seg = !r.sectionId.empty() ? r.sectionId : r.type;
      if (document.hasValuesUnder(seg)) {
        if (!first) {
          b += ", ";
        }
        b += r.type;
        first = false;
      }
    }
    b += "); pass root_type to choose one";
    *errMsg = b;
  }
  return nullptr;
}

}  // namespace

std::string documentToMarkdown(const SpecDocument& document,
                               const SpecModel& model,
                               const std::string& rootType) {
  if (!rootType.empty()) {
    const SpecRoot& root = model.rootByType(rootType);
    return markdownExportRoot(model, document, root);
  }
  std::string errMsg;
  const SpecRoot* root = singlePopulatedRoot(model, document, &errMsg);
  if (root == nullptr) {
    throw std::runtime_error(errMsg);
  }
  return markdownExportRoot(model, document, *root);
}

SpecMarkdownRendition documentToMarkdownWithMap(const SpecDocument& document,
                                                const SpecModel& model,
                                                const std::string& rootType) {
  if (!rootType.empty()) {
    return markdownExportRootWithMap(model, document,
                                     model.rootByType(rootType));
  }
  std::string errMsg;
  const SpecRoot* root = singlePopulatedRoot(model, document, &errMsg);
  if (root == nullptr) {
    throw std::runtime_error(errMsg);
  }
  return markdownExportRootWithMap(model, document, *root);
}

/* ---- reading-view layout lines (public) ---------------------------------- */

bool markdownLayoutTableHeader(const std::string& line, bool* isSection) {
  return matchLayoutTableHeader(line, isSection);
}
bool markdownTableLine(const std::string& line) { return matchTableLine(line); }
bool markdownDelimiterCell(const std::string& cell) {
  return matchDelimiterCell(cell);
}
std::vector<std::string> markdownTableRowCells(const std::string& line) {
  return rowCells(line);
}
bool markdownLinkCell(const std::string& text, std::vector<std::string>* texts) {
  return matchLinkCell(text, texts);
}
bool markdownFirstLinkText(const std::string& s, std::string* text) {
  return findLinkText(s, text);
}
bool markdownListDivOpen(const std::string& line, std::string* kind) {
  return matchListDivOpen(line, kind);
}
bool markdownDivCloseLine(const std::string& line) {
  return matchDivCloseLine(line);
}

}  // namespace som
