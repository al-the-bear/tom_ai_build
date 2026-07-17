/* spec_document_markdown — implementation. See spec_document_markdown.hpp; a
 * faithful port of the C `spec_document_markdown.c` (the DocSpecs markdown
 * codec). The Go regexps are reproduced as hand-rolled scanners so the runtime
 * stays dependency-free.
 *
 * Every `List<T>` field maps to a two-level md hierarchy: a `<!--[FOO-LST]-->`
 * container heading (DR1 §1.2/§1.5) at the owner's child level, holding the
 * numbered item headings one level deeper, with item-element children one level
 * deeper again. The container carries no body of its own; item identity is
 * purely positional. */
#include "spec_document_markdown.hpp"

#include <map>
#include <memory>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include "som_util.hpp"
#include "spec_meta.hpp"
#include "spec_meta_bridge.hpp"
#include "spec_model.hpp"
#include "spec_paths.hpp"

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

/* mdHeadlineCommentRE = `^<!--\[([^\]]+)\]-->\s*(.*)$`. `s` should already be
 * TrimSpace'd. */
bool matchHeadlineComment(const std::string& s, std::string* id,
                          std::string* title) {
  if (s.compare(0, 5, "<!--[") != 0) {
    return false;
  }
  std::size_t p = 5;
  std::size_t close = s.find(']', p);
  if (close == std::string::npos || close == p) {
    return false;  // [^\]]+ requires at least one char
  }
  if (s.compare(close, 4, "]-->") != 0) {
    return false;
  }
  *id = s.substr(p, close - p);
  if (title != nullptr) {
    // `\s*(.*)$` — skip leading whitespace after `]-->`, then TrimSpace.
    std::size_t t = close + 4;
    while (t < s.size() && isWs(s[t])) {
      t++;
    }
    *title = trimSpace(s.substr(t));
  }
  return true;
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

/* mdBlankRunRE `\n{3,}`→`\n\n`, then strip leading + trailing newlines. */
std::string collapseBlankRuns(const std::string& value) {
  std::string b;
  std::size_t i = 0;
  while (i < value.size()) {
    if (value[i] == '\n') {
      std::size_t run = 0;
      while (i + run < value.size() && value[i + run] == '\n') {
        run++;
      }
      std::size_t emit = run >= 3 ? 2 : run;
      for (std::size_t k = 0; k < emit; k++) {
        b.push_back('\n');
      }
      i += run;
    } else {
      b.push_back(value[i]);
      i++;
    }
  }
  std::size_t start = 0, n = b.size();
  while (start < n && b[start] == '\n') {
    start++;
  }
  while (n > start && b[n - 1] == '\n') {
    n--;
  }
  return b.substr(start, n - start);
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
/* Naming helpers (DR1 §1.2 / §1.5)                                          */
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
  if (kindEq(node.kind, kSomMetaKindSection) ||
      kindEq(node.kind, kSomMetaKindComplex)) {
    const SpecClass* cls = c.classNamed(node.className);
    if (cls != nullptr && !cls->sectionId.empty()) {
      return cls->sectionId;
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
  const SpecClass* cls = c.classNamed(n.className);
  return cls == nullptr || cls->sectionId.empty();
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
 * class's `@Headline` default when authored, else the DR1 §1.5 derivation
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

void mdWriteHeading(std::string& b, int depth, const std::string& id,
                    const std::string& title) {
  for (int i = 0; i < depth; i++) {
    b.push_back('#');
  }
  b += " <!--[";
  b += id;
  b += "]--> ";
  b += title;
  b.push_back('\n');
  b.push_back('\n');
}

std::string pathFenceErr(const std::string& path) {
  return "content at \"" + path +
         "\" contains an unterminated fenced code block; it cannot be "
         "represented in the DocSpecs markdown format";
}

/* prepareValue: collapse blank runs, escape heading-like lines outside fences.
 * Throws std::invalid_argument on an unterminated fence. */
std::string prepareValue(const std::string& value, const std::string& path) {
  std::string collapsed = collapseBlankRuns(value);
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

bool formHasValues(const SpecDocument& doc, const SomMetaNode& node,
                   const std::string& path) {
  if (!node.form.has_value()) {
    return false;
  }
  for (const auto& f : node.form->fields) {
    if (doc.formFieldOpt(path, f.name) != nullptr) {
      return true;
    }
  }
  return false;
}

void writeForm(std::string& b, const SpecDocument& doc, const SomMetaNode& node,
               const std::string& path) {
  if (node.form.has_value()) {
    for (const auto& f : node.form->fields) {
      const std::string* value = doc.formFieldOpt(path, f.name);
      if (value == nullptr) {
        continue;
      }
      std::string prepared = prepareValue(*value, path);
      std::vector<std::string> plines = splitLines(prepared);
      b += formLabel(f.name);
      b += ": ";
      b += !plines.empty() ? plines[0] : "";
      b.push_back('\n');
      for (std::size_t li = 1; li < plines.size(); li++) {
        const std::string& line = plines[li];
        if (matchLabelShaped(line)) {
          b.push_back(' ');
          b += line;
        } else {
          b += line;
        }
        b.push_back('\n');
      }
    }
  }
  b.push_back('\n');
}

void writeChildren(MdCodec& c, std::string& b, const SomMetaNode& node,
                   const std::string& basePath, int depth);

void writeSectionBody(MdCodec& c, std::string& b, const SomMetaNode& node,
                      const std::string& path) {
  const SpecDocument& doc = *c.document();
  bool present = false;
  std::string value = contentOf(doc, path, &present);
  if (present) {
    writeBody(b, value, path);
  }
  std::vector<NodeRel> slots = bodySlots(c, node);
  for (const auto& slot : slots) {
    std::string slotPath = specPathJoin(path, slot.rel);
    const SomMetaNode* sn = slot.node;
    if (kindEq(sn->kind, kSomMetaKindForm)) {
      if (formHasValues(doc, *sn, slotPath)) {
        writeForm(b, doc, *sn, slotPath);
      }
    } else {
      bool p2 = false;
      std::string v = contentOf(doc, slotPath, &p2);
      if (p2) {
        writeBody(b, v, slotPath);
      }
    }
  }
}

// Emits list `node` as its `-LST` container heading (DR1 §1.2/§1.5) at `depth`,
// wrapping the numbered item headings one level deeper and their item-element
// children one level deeper again. The container is a real section — the id the
// DR3 schema keys its container type by — but carries no content of its own
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
  mdWriteHeading(b, depth, headingIdOf(c, node),
                 headingTitle(c, listPath, node));
  // Item heading stem. Complex lists derive it from the element class name
  // (DR1 §1.5, `Entry` dropped). A scalar list (shape 6) has no element class —
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
  for (std::size_t i = 0; i < n; i++) {
    const std::string& itemPath = (*items)[i];
    long long pos = (long long)i + 1;
    std::string itemId;
    // YRD3 (supersedes DRC5): an item's STORED section id IS its md heading
    // id — stored ids round-trip through Markdown too. Only anonymous items
    // fall back to the positional derivation: the `@SectionIdPattern`
    // resolved with the 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`),
    // else `<member>-<pos>` for a pattern-less list.
    const std::string* storedId = doc.itemSectionIdOpt(itemPath);
    if (storedId != nullptr) {
      itemId = *storedId;
    } else if (!pattern.empty()) {
      std::string num = formatI64(pos);
      std::size_t p = 0, xxx;
      while ((xxx = pattern.find("xxx", p)) != std::string::npos) {
        itemId.append(pattern, p, xxx - p);
        itemId += num;
        p = xxx + 3;
      }
      itemId.append(pattern, p, std::string::npos);
    } else {
      std::string member =
          !node.memberName.empty() ? node.memberName : node.segment();
      itemId = member + "-" + formatI64(pos);
    }
    // Items sit one level below the container. A stored headline overrides
    // the derived `<stem> <pos>` title (YRD3).
    std::string title = doc.headline(itemPath);
    if (title.empty()) {
      title = stem + " " + formatI64(pos);
    }
    mdWriteHeading(b, depth + 1, itemId, title);
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
      mdWriteHeading(b, depth, headingIdOf(c, *child),
                     headingTitle(c, path, *child));
      writeBody(b, value, path);
    } else if (kindEq(kind, kSomMetaKindForm)) {
      if (!formHasValues(doc, *child, path)) {
        continue;
      }
      mdWriteHeading(b, depth, headingIdOf(c, *child),
                     headingTitle(c, path, *child));
      writeForm(b, doc, *child, path);
    } else if (kindEq(kind, kSomMetaKindSection) ||
               kindEq(kind, kSomMetaKindComplex)) {
      mdWriteHeading(b, depth, headingIdOf(c, *child),
                     headingTitle(c, path, *child));
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
  mdWriteHeading(b, 1, rootSeg, rootTitle);
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
  void openItem(int level, const std::string& listPath,
                const SomMetaNode& listNode, long long n,
                const std::string& storedId, bool hasN,
                const std::string& title, std::size_t line);
  void openItemHeading(int level, const std::string& listPath,
                       const SomMetaNode& listNode, const std::string& id,
                       const std::string& title, std::size_t line);
  void openHeading(int level, const std::string& rest, std::size_t line);
  void openRoot(int level, const std::string& id, const std::string& title,
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
    } else {
      b += line;
    }
    fence.feed(line);
  }
  return stripBlankLines(b);
}

/* Returns the model field name matching `label` (case-insensitive), or
 * nullptr. */
const std::string* formFieldNameCi(const SomMetaNode& node,
                                   const std::string& label) {
  if (!node.form.has_value()) {
    return nullptr;
  }
  std::string lower = lowerDup(label);
  for (const auto& f : node.form->fields) {
    if (lowerDup(f.name) == lower) {
      return &f.name;
    }
  }
  return nullptr;
}

void MdParser::finalizeForm(MdFrame& frame, const SomMetaNode& node,
                            const std::string& path) {
  SpecMarkdownFenceTracker fence;
  const std::string* currentField = nullptr;
  bool haveField = false;
  std::vector<std::string> current;

  auto flush = [&](std::size_t lineNo) {
    if (haveField) {
      std::string value = restoreValue(current);
      if (!value.empty()) {
        stagedSetForm(path, *currentField, value);
      }
    } else {
      for (const auto& l : current) {
        if (!trimSpace(l).empty()) {
          pushRejection(lineNo, kSpecMarkdownRejectOrphanContent,
                        "text in a @Form section before the first field label",
                        path);
          break;
        }
      }
    }
    current.clear();
  };

  for (std::size_t i = 0; i < frame.body.size(); i++) {
    const std::string& line = frame.body[i];
    if (!fence.inFence()) {
      std::string label, value;
      if (matchFieldLabel(line, &label, &value)) {
        const std::string* fieldName = formFieldNameCi(node, label);
        if (fieldName != nullptr) {
          flush(frame.line + i);
          haveField = true;
          currentField = fieldName;
          current.push_back(value);
          fence.feed(line);
          continue;
        }
      }
    }
    if (!fence.inFence() && matchContinuationLabel(line)) {
      current.push_back(line.substr(1));
    } else {
      current.push_back(line);
    }
    fence.feed(line);
  }
  flush(frame.line + frame.body.size());
}

void MdParser::finalizeBodySlots(MdFrame& frame,
                                 const std::vector<NodeRel>& slots) {
  std::vector<NodeRel> forms;
  std::vector<NodeRel> contents;
  for (const auto& s : slots) {
    if (kindEq(s.node->kind, kSomMetaKindForm)) {
      forms.push_back(s);
    } else {
      contents.push_back(s);
    }
  }
  std::string contentPath = !contents.empty()
                                ? specPathJoin(frame.path, contents[0].rel)
                                : frame.path;

  if (forms.empty()) {
    std::string value = restoreValue(frame.body);
    if (!value.empty()) {
      stagedSetContent(contentPath, value);
    }
    return;
  }

  SpecMarkdownFenceTracker fence;
  const std::string* currentField = nullptr;
  std::string currentFormPath;
  bool haveField = false;
  std::vector<std::string> current;
  std::vector<std::string> contentLines;
  currentFormIdx_ = 0;

  for (std::size_t i = 0; i < frame.body.size(); i++) {
    const std::string& line = frame.body[i];
    if (!fence.inFence()) {
      std::string label, value;
      if (matchFieldLabel(line, &label, &value)) {
        int foundIdx = -1;
        const std::string* foundName = nullptr;
        std::string lower = lowerDup(label);
        for (std::size_t k = 0; k < forms.size(); k++) {
          std::size_t idx = ((std::size_t)currentFormIdx_ + k) % forms.size();
          const SomMetaNode* fn = forms[idx].node;
          if (!fn->form.has_value()) {
            continue;
          }
          for (const auto& f : fn->form->fields) {
            if (lowerDup(f.name) == lower) {
              foundIdx = (int)idx;
              foundName = &f.name;
              break;
            }
          }
          if (foundIdx >= 0) {
            break;
          }
        }
        if (foundIdx >= 0) {
          if (haveField) {
            std::string v = restoreValue(current);
            if (!v.empty()) {
              stagedSetForm(currentFormPath, *currentField, v);
            }
          }
          current.clear();
          currentFormIdx_ = foundIdx;
          haveField = true;
          currentField = foundName;
          currentFormPath = specPathJoin(frame.path, forms[foundIdx].rel);
          current.push_back(value);
          fence.feed(line);
          continue;
        }
      }
    }
    std::string text = line;
    if (!fence.inFence() && haveField && matchContinuationLabel(line)) {
      text = line.substr(1);
    }
    if (haveField) {
      current.push_back(text);
    } else {
      contentLines.push_back(text);
    }
    fence.feed(line);
  }
  if (haveField) {
    std::string v = restoreValue(current);
    if (!v.empty()) {
      stagedSetForm(currentFormPath, *currentField, v);
    }
  }
  {
    std::string cv = restoreValue(contentLines);
    if (!cv.empty()) {
      stagedSetContent(contentPath, cv);
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

void MdParser::openItem(int level, const std::string& listPath,
                        const SomMetaNode& listNode, long long n,
                        const std::string& storedId, bool hasN,
                        const std::string& title, std::size_t line) {
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
  if (!hasN) {
    state.ids.push_back({itemPath, storedId});
  }
  // YRD3 §8.7: stage a non-default item heading text against the effective
  // `<stem> <pos>` default (YRD4: element-class @Headline wins in the stem).
  std::string stem = mdItemStemOf(listNode);
  if (!title.empty() && title != stem + " " + formatI64(number)) {
    staged_.headlines[itemPath] = title;
  }
  MdFrame f;
  f.level = level;
  f.node = listNode.elementNode.get();
  f.path = itemPath;
  f.line = line;
  f.ignored = false;
  stack_.push_back(std::move(f));
}

/* mdPatternMatches: pattern with "xxx" wildcard → `.+`. */
bool patternMatches(const std::string& pattern, const std::string& id) {
  std::size_t xxx = pattern.find("xxx");
  if (xxx == std::string::npos) {
    return pattern == id;
  }
  std::size_t pp;   // index into pattern
  std::size_t ip;   // index into id
  std::size_t firstLen = xxx;
  if (id.size() < firstLen || id.compare(0, firstLen, pattern, 0, firstLen) != 0) {
    return false;
  }
  ip = firstLen;
  pp = xxx + 3;
  for (;;) {
    std::size_t next = pattern.find("xxx", pp);
    if (next == std::string::npos) {
      break;
    }
    std::size_t plen = next - pp;
    if (plen == 0) {
      if (ip >= id.size()) {
        return false;
      }
      ip += 1;
      pp = next + 3;
      continue;
    }
    std::size_t hit = std::string::npos;
    for (std::size_t q = ip + 1; q + plen <= id.size(); q++) {
      if (id.compare(q, plen, pattern, pp, plen) == 0) {
        hit = q;
        break;
      }
    }
    if (hit == std::string::npos) {
      return false;
    }
    ip = hit + plen;
    pp = next + 3;
  }
  std::size_t lastLen = pattern.size() - pp;
  std::size_t rem = id.size() - ip;
  if (lastLen == 0) {
    return rem >= 1;  // `.+$`
  }
  if (rem < lastLen + 1) {
    return false;
  }
  return id.compare(id.size() - lastLen, lastLen, pattern, pp, lastLen) == 0;
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

// Opens a list-item frame under a `-LST` container frame (DR1 §1.2). The
// heading [id] is matched positionally against the container's list: the
// `<member>-<n>` fallback id, the `@SectionIdPattern` resolved with a number
// (`GOAL-ITEM-3`, parses back as item <n>), a pattern-shaped stored id, or —
// for any other id — an anonymous next item carrying the stored id.
void MdParser::openItemHeading(int level, const std::string& listPath,
                               const SomMetaNode& listNode,
                               const std::string& id, const std::string& title,
                               std::size_t line) {
  std::string member =
      !listNode.memberName.empty() ? listNode.memberName : listNode.segment();
  long long n = 0;
  if (anonMemberMatch(member, id, &n)) {
    openItem(level, listPath, listNode, n, "", true, title, line);
    return;
  }
  const SomMetaNode* element = listNode.elementNode.get();
  std::string pattern = listNode.sectionIdPattern;
  if (pattern.empty() && element != nullptr) {
    pattern = element->sectionIdPattern;
  }
  if (!pattern.empty()) {
    long long num = 0;
    if (numberedPatternMatch(pattern, id, &num)) {
      openItem(level, listPath, listNode, num, "", true, title, line);
      return;
    }
    if (patternMatches(pattern, id)) {
      openItem(level, listPath, listNode, 0, id, false, title, line);
      return;
    }
  }
  // Any other id under the container is an anonymous next item carrying the
  // stored id — stored ids round-trip through Markdown too (YRD3).
  openItem(level, listPath, listNode, 0, id, false, title, line);
}

void MdParser::openHeading(int level, const std::string& rest,
                           std::size_t line) {
  std::string trimmed = trimSpace(rest);
  std::string id;
  std::string title;
  if (!matchHeadlineComment(trimmed, &id, &title)) {
    pushRejection(line, kSpecMarkdownRejectMalformedHeading,
                  "heading carries no <!--[SECTION-ID]--> headline comment",
                  trimmed);
    pushIgnoredFrame(level, line);
    return;
  }

  if (stack_.empty()) {
    openRoot(level, id, title, line);
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

  // 1. Under a `-LST` container frame (DR1 §1.2), every child heading is one of
  //    that list's items — resolved positionally, not by the schema tree.
  if (kindEq(pNode->kind, kSomMetaKindList)) {
    openItemHeading(level, parentPath, *pNode, id, title, line);
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
      // YRD3 §8.7: stage the heading text as a stored headline ONLY when it
      // differs from the derived default (byte-stability).
      if (!title.empty() && title != mdTitleOf(*en)) {
        staged_.headlines[path] = title;
      }
      MdFrame f;
      f.level = level;
      f.node = en;
      f.path = path;
      f.line = line;
      f.ignored = false;
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
                        const std::string& title, std::size_t line) {
  const SpecModel& model = codec_.model();
  for (const auto& root : model.roots) {
    std::string seg = !root.sectionId.empty() ? root.sectionId : root.type;
    if (seg == id) {
      std::string err;
      SomMetaTree* tree = codec_.treeFor(root.type, &err);
      if (tree == nullptr) {
        break;
      }
      // YRD3 §8.7: stage a non-default root heading text — "non-default"
      // relative to the effective default (YRD4: `@Headline` default, else
      // the `@Document` title).
      const std::string& rootDefault = !tree->root()->headline.empty()
                                           ? tree->root()->headline
                                           : root.title;
      if (!title.empty() && title != rootDefault) {
        staged_.headlines[seg] = title;
      }
      rootPrefixes_.insert(seg);
      MdFrame f;
      f.level = level;
      f.node = tree->root();
      f.path = seg;
      f.line = line;
      f.ignored = false;
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
        continue;  // §1.1 header
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
/* SpecDocument.ToMarkdown (item 12)                                         */
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

}  // namespace som
