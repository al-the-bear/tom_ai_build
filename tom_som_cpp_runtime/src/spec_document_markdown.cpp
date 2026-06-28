/* Idiomatic-C++ port of the C `spec_document_markdown` module. */
#include "spec_document_markdown.hpp"

#include "som_util.hpp"
#include "spec_paths.hpp"
#include "spec_reflection.hpp"

namespace som {

/* ======================================================================== */
/* small string helpers                                                      */
/* ======================================================================== */

static bool isMdWs(char c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\f' ||
         c == '\v';
}

static std::string trimEnd(const std::string& s) {
  std::size_t n = s.size();
  while (n > 0 && isMdWs(s[n - 1])) {
    n--;
  }
  return s.substr(0, n);
}

static std::string trimMd(const std::string& s) {
  std::size_t n = s.size();
  std::size_t start = 0;
  while (start < n && isMdWs(s[start])) {
    start++;
  }
  while (n > start && isMdWs(s[n - 1])) {
    n--;
  }
  return s.substr(start, n - start);
}

/* First whitespace-delimited token of `s`, or empty (with found=false). */
static bool firstToken(const std::string& s, std::string* out) {
  std::size_t i = 0;
  while (i < s.size() && isMdWs(s[i])) {
    i++;
  }
  if (i == s.size()) {
    return false;
  }
  std::size_t start = i;
  while (i < s.size() && !isMdWs(s[i])) {
    i++;
  }
  *out = s.substr(start, i - start);
  return true;
}

static std::size_t tokenCount(const std::string& s) {
  std::size_t count = 0, i = 0;
  while (i < s.size()) {
    while (i < s.size() && isMdWs(s[i])) {
      i++;
    }
    if (i == s.size()) {
      break;
    }
    count++;
    while (i < s.size() && !isMdWs(s[i])) {
      i++;
    }
  }
  return count;
}

static std::string toLower(const std::string& s) {
  std::string out = s;
  for (char& c : out) {
    if (c >= 'A' && c <= 'Z') {
      c = static_cast<char>(c - 'A' + 'a');
    }
  }
  return out;
}

/* ======================================================================== */
/* line-pattern helpers (heading / field anchor / fence / item segment)      */
/* ======================================================================== */

/* Section path of a heading line (`#{1,6} <path> …`), or empty (found=false). */
static bool headingPath(const std::string& line, std::string* out) {
  std::size_t hashes = 0;
  while (hashes < line.size() && line[hashes] == '#') {
    hashes++;
  }
  if (hashes == 0 || hashes > 6) {
    return false;
  }
  std::string rest = line.substr(hashes);
  if (rest.empty() || !isMdWs(rest[0])) {
    return false;
  }
  return firstToken(rest, out);
}

/* Field name of a `<!-- field: name -->` anchor line, or empty (found=false). */
static bool fieldAnchor(const std::string& line, std::string* out) {
  std::string t = trimMd(line);
  std::size_t tn = t.size();
  if (tn >= 7 && t.compare(0, 4, "<!--") == 0 && t.compare(tn - 3, 3, "-->") == 0) {
    std::string inner = t.substr(4, tn - 4 - 3);
    std::string innerT = trimMd(inner);
    if (innerT.compare(0, 6, "field:") == 0) {
      std::string rest = trimMd(innerT.substr(6));
      if (tokenCount(rest) == 1) {
        std::string tok;
        if (firstToken(rest, &tok) && !tok.empty()) {
          *out = tok;
          return true;
        }
      }
    }
  }
  return false;
}

/* Fence length of a fence-opener line (3+ backticks), or 0. */
static std::size_t fenceOpen(const std::string& line) {
  std::size_t n = 0;
  while (n < line.size() && line[n] == '`') {
    n++;
  }
  return n >= 3 ? n : 0;
}

/* Splits a list-item segment `<base>-<digits>` into base + number. */
static bool itemSeg(const std::string& seg, std::string* base, long long* num) {
  std::size_t n = seg.size();
  long dash = -1;
  for (std::size_t i = n; i > 0; i--) {
    if (seg[i - 1] == '-') {
      dash = static_cast<long>(i - 1);
      break;
    }
  }
  if (dash <= 0 || static_cast<std::size_t>(dash) == n - 1) {
    return false;
  }
  std::string tail = seg.substr(static_cast<std::size_t>(dash) + 1);
  if (!isAllDigits(tail)) {
    return false;
  }
  auto v = parseI64(tail);
  if (!v.has_value()) {
    return false;
  }
  *base = seg.substr(0, static_cast<std::size_t>(dash));
  *num = *v;
  return true;
}

/* ======================================================================== */
/* fenced block rendering                                                    */
/* ======================================================================== */

/* Renders a fenced code block holding `value` verbatim (no trailing newline). */
static std::string fence(const std::string& value, const std::string& info) {
  std::size_t maxRun = 0, run = 0;
  for (char c : value) {
    if (c == '`') {
      run++;
      if (run > maxRun) {
        maxRun = run;
      }
    } else {
      run = 0;
    }
  }
  std::size_t n = maxRun + 1;
  if (n < 3) {
    n = 3;
  }
  std::string b;
  b.append(n, '`');
  b += info;
  b.push_back('\n');
  // value.split('\n') each on its own line
  std::size_t start = 0;
  std::size_t vlen = value.size();
  for (std::size_t i = 0;; i++) {
    if (i == vlen || value[i] == '\n') {
      b += value.substr(start, i - start);
      b.push_back('\n');
      if (i == vlen) {
        break;
      }
      start = i + 1;
    }
  }
  b.append(n, '`');
  return b;
}

static void writeln(std::string& b, const std::string& text) {
  b += text;
  b.push_back('\n');
}

static void mdHeading(std::string& b, std::size_t depth, const std::string& path,
                      const std::string& name) {
  std::size_t d = depth < 6 ? depth : 6;
  b.append(d, '#');
  b.push_back(' ');
  b += path;
  b += " \xE2\x80\x94 ";  // U+2014 em-dash
  b += name;
  b.push_back('\n');
}

/* ======================================================================== */
/* export                                                                    */
/* ======================================================================== */

static void exportClass(std::string& b, const SpecModel& model,
                        const SpecDocument& doc, const SpecClass& cls,
                        const std::string& basePath, std::size_t depth,
                        const std::set<std::string>& seenTypes);

std::string markdownExportRoot(const SpecModel& model,
                               const SpecDocument& document,
                               const SpecRoot& root) {
  std::string b;
  std::string seg = SpecReflection::rootSegment(root);
  b += "<!-- docspec: ";
  b += toLower(seg);
  b += "/1 -->\n";
  b += "# ";
  b += seg;
  b += " \xE2\x80\x94 ";
  b += root.title;
  b.push_back('\n');
  std::string desc = trimMd(root.description);
  if (!desc.empty()) {
    writeln(b, "");
    writeln(b, desc);
  }
  const SpecClass* cls = model.classNamed(root.type);
  if (cls != nullptr) {
    std::set<std::string> seen;
    seen.insert(root.type);
    exportClass(b, model, document, *cls, seg, 2, seen);
  }
  return b;
}

static void exportClass(std::string& b, const SpecModel& model,
                        const SpecDocument& doc, const SpecClass& cls,
                        const std::string& basePath, std::size_t depth,
                        const std::set<std::string>& seenTypes) {
  for (const SpecField& field : cls.fields) {
    std::string path = specPathJoin(basePath, SpecReflection::fieldSegment(field));
    if (!doc.hasValuesUnder(path)) {
      continue;
    }
    const std::string& kind = field.kind;
    if (kind == kSpecFieldKindContent || kind == kSpecFieldKindScalar ||
        kind == kSpecFieldKindEnum) {
      const std::string* value = doc.contentOpt(path);
      if (value != nullptr) {
        mdHeading(b, depth, path, field.name);
        writeln(b, fence(*value, field.contentType));
        writeln(b, "");
      }
    } else if (kind == kSpecFieldKindForm) {
      mdHeading(b, depth, path, field.name);
      for (const FormFieldSpec& ff : field.formFields) {
        const std::string* value = doc.formFieldOpt(path, ff.name);
        if (value == nullptr) {
          continue;
        }
        b += "<!-- field: ";
        b += ff.name;
        b += " -->\n";
        writeln(b, fence(*value, ""));
        writeln(b, "");
      }
    } else if (kind == kSpecFieldKindList) {
      const SpecClass* elem = model.classNamed(field.elementType);
      bool recursive = !field.elementType.empty() &&
                       seenTypes.count(field.elementType) > 0;
      mdHeading(b, depth, path, field.name);
      writeln(b, "");
      if (elem != nullptr && !recursive) {
        std::set<std::string> nextSeen = seenTypes;
        nextSeen.insert(field.elementType);
        const std::vector<std::string>* items = doc.listItemsPtr(path);
        if (items != nullptr) {
          for (const std::string& itemPath : *items) {
            const std::string& label =
                !field.elementType.empty() ? field.elementType : "item";
            mdHeading(b, depth + 1, itemPath, label);
            writeln(b, "");
            exportClass(b, model, doc, *elem, itemPath, depth + 2, nextSeen);
          }
        }
      }
    } else if (kind == kSpecFieldKindComplex || kind == kSpecFieldKindSection) {
      const SpecClass* nested = model.classNamed(field.type);
      bool recursive = !field.type.empty() && seenTypes.count(field.type) > 0;
      if (nested != nullptr && !recursive) {
        mdHeading(b, depth, path, field.name);
        writeln(b, "");
        std::set<std::string> nextSeen = seenTypes;
        nextSeen.insert(field.type);
        exportClass(b, model, doc, *nested, path, depth + 1, nextSeen);
      }
    }
  }
}

/* ======================================================================== */
/* import                                                                    */
/* ======================================================================== */

std::string SpecMarkdownRejection::display() const {
  std::string b = "line ";
  b += formatI64(static_cast<long long>(line));
  b += ": ";
  b += reason;
  if (!anchor.empty()) {
    b += " (";
    b += anchor;
    b.push_back(')');
  }
  b += " \xE2\x80\x94 ";
  b += message;
  return b;
}

namespace {

/* A pending value target between an anchor and its fenced block. */
struct Pending {
  bool active = false;
  std::size_t line = 0;
  std::string path;
  std::string field;
  bool hasFld = false;
  bool filled = false;

  void clear() {
    active = false;
    line = 0;
    path.clear();
    field.clear();
    hasFld = false;
    filled = false;
  }

  std::string anchor() const {
    if (hasFld) {
      return path + " :: " + field;
    }
    return path;
  }
};

void pushRejection(SpecMarkdownResult& r, std::size_t line,
                   const std::string& reason, const std::string& message,
                   const std::string& anchor) {
  SpecMarkdownRejection rej;
  rej.line = line;
  rej.reason = reason;
  rej.message = message;
  rej.anchor = anchor;
  r.rejections.push_back(std::move(rej));
}

void flushMissing(Pending& pend, SpecMarkdownResult& result) {
  if (pend.active) {
    if (!pend.filled) {
      pushRejection(result, pend.line, kSpecMarkdownRejectMissingValue,
                    "no fenced value followed this anchor", pend.anchor());
    }
    pend.clear();
  }
}

void reconstructLists(const SpecModel& model, SpecMarkdownResult& result);

}  // namespace

SpecMarkdownResult markdownParse(const SpecModel& model,
                                 const std::string& text) {
  SpecMarkdownResult out;
  SpecReflection refl(model);

  // split into lines
  std::vector<std::string> lines;
  {
    std::size_t start = 0;
    for (std::size_t p = 0;; p++) {
      if (p == text.size() || text[p] == '\n') {
        lines.push_back(text.substr(start, p - start));
        if (p == text.size()) {
          break;
        }
        start = p + 1;
      }
    }
  }

  Pending pend;
  std::string currentKind;
  std::string currentPath;

  std::size_t i = 0;
  while (i < lines.size()) {
    const std::string& raw = lines[i];
    std::size_t lineNo = i + 1;
    std::string trimmed = trimEnd(raw);

    // Heading.
    std::string hpath;
    if (headingPath(trimmed, &hpath)) {
      flushMissing(pend, out);
      auto res = refl.resolve(hpath);
      if (!res.has_value()) {
        pushRejection(out, lineNo, kSpecMarkdownRejectUnknownSection,
                      "section path does not resolve against the model", hpath);
        currentKind.clear();
        currentPath.clear();
      } else {
        currentKind = res->kind;
        currentPath = hpath;
        // first '/'-delimited segment -> root prefix set
        std::size_t slash = hpath.find('/');
        std::string prefix =
            slash != std::string::npos ? hpath.substr(0, slash) : hpath;
        out.rootPrefixes.insert(prefix);
        if (res->isValueLeaf()) {
          pend.active = true;
          pend.line = lineNo;
          pend.path = hpath;
          pend.field.clear();
          pend.hasFld = false;
          pend.filled = false;
        }
      }
      i++;
      continue;
    }

    // Form-field anchor.
    std::string fname;
    if (fieldAnchor(trimmed, &fname)) {
      flushMissing(pend, out);
      if (currentPath.empty() || currentKind != kSpecNodeKindForm) {
        pushRejection(out, lineNo, kSpecMarkdownRejectKindMismatch,
                      "form-field anchor outside a `@Form` section", fname);
      } else {
        pend.active = true;
        pend.line = lineNo;
        pend.path = currentPath;
        pend.field = fname;
        pend.hasFld = true;
        pend.filled = false;
      }
      i++;
      continue;
    }

    // Fence opener.
    std::size_t fenceLen = fenceOpen(trimmed);
    if (fenceLen > 0) {
      std::string body;
      std::size_t j = i + 1;
      bool bodyFirst = true;
      while (j < lines.size()) {
        std::string cl = trimEnd(lines[j]);
        bool isCloser = true;
        if (cl.size() != fenceLen) {
          isCloser = false;
        } else {
          for (std::size_t k = 0; k < fenceLen; k++) {
            if (cl[k] != '`') {
              isCloser = false;
              break;
            }
          }
        }
        if (isCloser) {
          break;
        }
        if (!bodyFirst) {
          body.push_back('\n');
        }
        bodyFirst = false;
        body += lines[j];
        j++;
      }
      if (!pend.active) {
        pushRejection(out, lineNo, kSpecMarkdownRejectOrphanBlock,
                      "fenced value with no owning section or field", "");
      } else {
        if (pend.hasFld) {
          out.staged.forms[pend.path][pend.field] = body;
        } else {
          out.staged.content[pend.path] = body;
        }
        pend.filled = true;
        pend.clear();
      }
      i = (j < lines.size()) ? j + 1 : j;
      continue;
    }

    i++;
  }
  flushMissing(pend, out);

  reconstructLists(model, out);
  return out;
}

namespace {

void reconstructLists(const SpecModel& model, SpecMarkdownResult& result) {
  SpecReflection refl(model);

  // Gather the keys to scan: content paths then form paths (byte-sorted maps).
  std::vector<std::string> keys;
  for (const auto& kv : result.staged.content) {
    keys.push_back(kv.first);
  }
  for (const auto& kv : result.staged.forms) {
    keys.push_back(kv.first);
  }

  for (const std::string& path : keys) {
    std::vector<std::string> segs = specPathSegments(path);
    if (segs.empty()) {
      continue;
    }
    std::string prefix = segs[0];
    for (std::size_t si = 1; si < segs.size(); si++) {
      const std::string& seg = segs[si];
      std::string base;
      long long n = 0;
      if (itemSeg(seg, &base, &n)) {
        std::string listPath = specPathJoin(prefix, base);
        std::string itemPath = specPathJoin(prefix, seg);
        auto res = refl.resolve(listPath);
        if (res.has_value() && res->kind == kSpecNodeKindList) {
          DocListEntry& e = result.staged.lists[listPath];
          bool present = false;
          for (const std::string& it : e.items) {
            if (it == itemPath) {
              present = true;
              break;
            }
          }
          if (!present) {
            e.items.push_back(itemPath);
          }
          if (n > e.seq) {
            e.seq = n;
          }
        }
      }
      prefix = specPathJoin(prefix, seg);
    }
  }
}

}  // namespace

}  // namespace som
